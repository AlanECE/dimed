from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID, uuid4

from fastapi import HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import load_only, selectinload

from app.commandes.schemas import CreateOrderRequest
from app.models.caddie import Caddie
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


async def bulk_claim_commandes(
    db: AsyncSession,
    commande_ids: list[UUID],
    caddies_by_commande: dict[UUID, list[str]],
    preparateur_id: UUID,
    actor_id: UUID,
) -> list[Commande]:
    """Claim multiple commandes to a preparateur and replace their caddies.

    - Locks rows with SELECT ... FOR UPDATE to prevent race conditions between
      two simultaneous claims.
    - Only commandes in ACCEPTEE or EN_PREPARATION are accepted.
    - Refuses if a commande is already claimed by a different preparateur.
    - If a commande is ACCEPTEE, transitions it to EN_PREPARATION and emits
      the same notification as the single start-preparation path.
    - Replaces any existing caddies on each commande with the provided numeros.
    """
    allowed_statuses = {OrderStatus.ACCEPTEE, OrderStatus.EN_PREPARATION}

    result = await db.execute(
        select(Commande)
        .where(Commande.id.in_(commande_ids))
        .options(selectinload(Commande.lignes))
        .with_for_update()
    )
    commandes = list(result.scalars().all())

    found_ids = {c.id for c in commandes}
    missing = set(commande_ids) - found_ids
    if missing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Commandes not found: {', '.join(str(m) for m in missing)}",
        )

    for cmd in commandes:
        if cmd.statut not in allowed_statuses:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(f"Commande {cmd.reference_id} is not in ACCEPTEE or EN_PREPARATION status"),
            )
        if cmd.preparateur_id and cmd.preparateur_id != preparateur_id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(f"Commande {cmd.reference_id} is already claimed by another preparateur"),
            )
        if cmd.id not in caddies_by_commande:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"No caddies provided for commande {cmd.reference_id}",
            )
        numeros = [n.strip() for n in caddies_by_commande[cmd.id] if n.strip()]
        if not numeros:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Empty caddie list for commande {cmd.reference_id}",
            )
        caddies_by_commande[cmd.id] = numeros

    db.info["actor_id"] = str(actor_id)

    for cmd in commandes:
        cmd.preparateur_id = preparateur_id
        if cmd.statut == OrderStatus.ACCEPTEE:
            cmd.statut = OrderStatus.EN_PREPARATION
            notification = Notification(
                id=uuid4(),
                user_id=cmd.pharmacien_id,
                commande_id=cmd.id,
                type=OrderStatus.EN_PREPARATION.value,
                message=(
                    f"Commande {cmd.reference_id} {STATUS_MESSAGES[OrderStatus.EN_PREPARATION]}"
                ),
            )
            db.add(notification)

        await db.execute(delete(Caddie).where(Caddie.commande_id == cmd.id))
        for numero in caddies_by_commande[cmd.id]:
            db.add(
                Caddie(
                    id=uuid4(),
                    commande_id=cmd.id,
                    numero=numero,
                )
            )

    await db.flush()
    return commandes
