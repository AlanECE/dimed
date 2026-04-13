from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID, uuid4

from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import load_only, selectinload

from app.commandes.schemas import CreateOrderRequest
from app.models.caddie_pool import CaddiePool
from app.models.commande import Commande, LigneCommande, OrderStatus
from app.models.medicament import Medicament
from app.models.notification import Notification
from app.models.references import next_commande_ref
from app.models.state_machine import validate_transition

NOTIFIABLE_STATUSES = {
    OrderStatus.ACCEPTEE,
    OrderStatus.EN_PREPARATION,
    OrderStatus.EN_ROUTE,
    OrderStatus.LIVREE,
}

STATUS_MESSAGES: dict[OrderStatus, str] = {
    OrderStatus.ACCEPTEE: "acceptée",
    OrderStatus.EN_PREPARATION: "en préparation",
    OrderStatus.EN_ROUTE: "en cours de livraison",
    OrderStatus.LIVREE: "livrée",
}


async def create_order(db: AsyncSession, pharmacien_id: UUID, body: CreateOrderRequest) -> Commande:
    med_ids = [a.medicament_id for a in body.articles]
    result = await db.execute(select(Medicament).where(Medicament.id.in_(med_ids)))
    medicaments = {m.id: m for m in result.scalars().all()}

    missing = [str(mid) for mid in med_ids if mid not in medicaments]
    if missing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Medicaments not found: {', '.join(missing)}",
        )

    out_of_stock: list[str] = []
    for article in body.articles:
        med = medicaments.get(article.medicament_id)
        if med is None:
            continue
        if med.stock_quantity <= 0 or med.stock_quantity < article.qte:
            out_of_stock.append(
                f"{med.designation} (stock={med.stock_quantity}, demande={article.qte})"
            )
    if out_of_stock:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Rupture de stock : " + ", ".join(out_of_stock),
        )

    reference_id = await next_commande_ref(db)

    commande = Commande(
        id=uuid4(),
        reference_id=reference_id,
        pharmacien_id=pharmacien_id,
        statut=OrderStatus.CREEE,
        montant_total=Decimal("0"),
    )

    total = Decimal("0")
    for article in body.articles:
        med = medicaments[article.medicament_id]
        ligne = LigneCommande(
            id=uuid4(),
            commande_id=commande.id,
            medicament_id=article.medicament_id,
            designation=med.designation,
            qte_demandee=article.qte,
            prix_unitaire=med.ppa,
        )
        commande.lignes.append(ligne)
        total += med.ppa * article.qte

    commande.montant_total = total

    db.add(commande)
    await db.flush()
    return commande


async def get_order_with_lines(db: AsyncSession, order_id: UUID) -> Commande | None:
    result = await db.execute(
        select(Commande)
        .where(Commande.id == order_id)
        .options(
            selectinload(Commande.lignes).options(
                load_only(
                    LigneCommande.id,
                    LigneCommande.commande_id,
                    LigneCommande.medicament_id,
                    LigneCommande.designation,
                    LigneCommande.qte_demandee,
                    LigneCommande.qte_prelevee,
                    LigneCommande.prix_unitaire,
                    LigneCommande.remise_pct,
                    LigneCommande.n_lot,
                    LigneCommande.verifie,
                    LigneCommande.ocr_verifie,
                )
            )
        )
    )
    return result.scalar_one_or_none()


async def transition_order(
    db: AsyncSession,
    order_id: UUID,
    target_status: OrderStatus,
    actor_id: UUID | None = None,
) -> Commande:
    commande = await get_order_with_lines(db, order_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    try:
        validate_transition(commande.statut, target_status)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e)) from e

    commande.statut = target_status

    if target_status == OrderStatus.ACCEPTEE and actor_id:
        commande.operatrice_id = actor_id
        commande.date_validation = datetime.now(UTC)

        # Validate stock before generating downstream documents or mutating inventory.
        insufficient_stock: list[str] = []
        medicament_ids = [ln.medicament_id for ln in commande.lignes]
        med_result = await db.execute(select(Medicament).where(Medicament.id.in_(medicament_ids)))
        medicaments = {med.id: med for med in med_result.scalars().all()}
        for ln in commande.lignes:
            med = medicaments.get(ln.medicament_id)
            if not med or med.stock_quantity < ln.qte_demandee:
                insufficient_stock.append(ln.designation)

        if insufficient_stock:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=("Insufficient stock for: " + ", ".join(insufficient_stock)),
            )

        # Auto-generate documents on acceptance
        from app.documents.service import generate_order_documents

        await generate_order_documents(db, commande)

        # Decrement stock for each line
        for ln in commande.lignes:
            med = medicaments.get(ln.medicament_id)
            if med:
                med.stock_quantity -= ln.qte_demandee

    await db.flush()

    # Create notification for pharmacien
    if target_status in NOTIFIABLE_STATUSES:
        notification = Notification(
            id=uuid4(),
            user_id=commande.pharmacien_id,
            commande_id=commande.id,
            type=target_status.value,
            message=f"Commande {commande.reference_id} {STATUS_MESSAGES[target_status]}",
        )
        db.add(notification)
        await db.flush()

    return commande


async def claim_caddie_for_preparation(
    db: AsyncSession,
    commande_id: UUID,
    caddie_pool_id: UUID,
    preparateur_id: UUID,
) -> Commande:
    """Exclusive-lock claim of a pool caddie for a commande.

    Transitions the commande ACCEPTEE → EN_PREPARATION and marks the caddie busy.
    Locks BOTH the commande row and the caddies_pool row with SELECT ... FOR UPDATE
    so two concurrent preparateurs cannot both claim the same order with different
    caddies (which would strand one of the caddies as "occupied by" the same order).
    """
    # Lock the commande first to serialize any concurrent start-preparation on it.
    cmd_lock = await db.execute(
        select(Commande.id, Commande.statut).where(Commande.id == commande_id).with_for_update()
    )
    cmd_row = cmd_lock.first()
    if cmd_row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )
    if cmd_row.statut != OrderStatus.ACCEPTEE:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Cannot start preparation from {cmd_row.statut.value}",
        )

    # Then lock the caddie pool row.
    pool_result = await db.execute(
        select(CaddiePool).where(CaddiePool.id == caddie_pool_id).with_for_update()
    )
    caddie = pool_result.scalar_one_or_none()
    if not caddie:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caddie not found",
        )
    if not caddie.is_available:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Caddie {caddie.numero} indisponible",
        )

    commande = await get_order_with_lines(db, commande_id)
    if commande is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    commande.preparateur_id = preparateur_id
    caddie.is_available = False
    caddie.current_commande_id = commande_id

    commande = await transition_order(db, commande_id, OrderStatus.EN_PREPARATION)
    await db.flush()
    return commande


async def release_caddie_on_finalize(db: AsyncSession, commande_id: UUID) -> None:
    """Free any caddie currently attached to this commande."""
    await db.execute(
        update(CaddiePool)
        .where(CaddiePool.current_commande_id == commande_id)
        .values(is_available=True, current_commande_id=None)
    )
