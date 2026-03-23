from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID, uuid4

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.commandes.schemas import CreateOrderRequest
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
        select(Commande).where(Commande.id == order_id).options(selectinload(Commande.lignes))
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

        # Auto-generate documents on acceptance
        from app.documents.service import generate_order_documents

        await generate_order_documents(db, commande)

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
