from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.creance import Creance, CreanceStatut
from app.models.document import Facture
from app.models.user import User

router = APIRouter()


class PaymentRequest(BaseModel):
    montant: Decimal = Field(gt=0, max_digits=12, decimal_places=2)


@router.get("")
async def list_creances(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    statut: str | None = None,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    query = select(Creance, Facture).join(Facture, Creance.facture_id == Facture.id)

    if current_user.role.value == "pharmacien":
        query = query.where(Creance.pharmacien_id == current_user.id)
    elif current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    if statut:
        query = query.where(Creance.statut == statut)

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    # Aggregate totals over the full filtered set (not just current page)
    def _base_filter(q):
        if current_user.role.value == "pharmacien":
            q = q.where(Creance.pharmacien_id == current_user.id)
        if statut:
            q = q.where(Creance.statut == statut)
        return q

    sum_total = (
        await db.execute(_base_filter(select(func.coalesce(func.sum(Creance.montant_total), 0))))
    ).scalar() or 0
    sum_paye = (
        await db.execute(_base_filter(select(func.coalesce(func.sum(Creance.montant_paye), 0))))
    ).scalar() or 0
    sum_retard = (
        await db.execute(
            _base_filter(
                select(
                    func.coalesce(func.sum(Creance.montant_total - Creance.montant_paye), 0)
                ).where(Creance.statut == CreanceStatut.EN_RETARD)
            )
        )
    ).scalar() or 0

    query = query.order_by(Creance.echeance.asc()).offset(offset).limit(min(limit, 100))
    result = await db.execute(query)
    rows = result.all()

    pharmacien_ids = {r.Creance.pharmacien_id for r in rows}
    pharmacien_map: dict = {}
    if pharmacien_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharmacien_ids)))
        pharmacien_map = {u.id: u.nom for u in users_result.scalars().all()}

    items = []
    for row in rows:
        c = row.Creance
        f = row.Facture
        items.append(
            {
                "id": str(c.id),
                "pharmacien_nom": pharmacien_map.get(c.pharmacien_id, "—"),
                "facture_reference": f.reference_id,
                "montant_total": float(c.montant_total),
                "montant_paye": float(c.montant_paye),
                "reste_a_payer": float(c.montant_total - c.montant_paye),
                "statut": c.statut.value if hasattr(c.statut, "value") else c.statut,
                "echeance": str(c.echeance),
                "created_at": c.created_at.isoformat(),
            }
        )

    return {
        "items": items,
        "total": total,
        "limit": limit,
        "offset": offset,
        "summary": {
            "total_montant": float(sum_total),
            "total_paye": float(sum_paye),
            "total_en_retard": float(sum_retard),
        },
    }


@router.patch("/{creance_id}/payment")
async def register_payment(
    creance_id: UUID,
    body: PaymentRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    result = await db.execute(select(Creance).where(Creance.id == creance_id))
    creance = result.scalar_one_or_none()
    if not creance:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Créance not found")

    reste = creance.montant_total - creance.montant_paye
    if body.montant > reste:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Montant exceeds remaining balance ({float(reste):.2f})",
        )

    creance.montant_paye = creance.montant_paye + body.montant
    if creance.montant_paye >= creance.montant_total:
        creance.montant_paye = creance.montant_total
        creance.statut = CreanceStatut.SOLDEE
    else:
        creance.statut = CreanceStatut.PARTIEL

    db.info["actor_id"] = str(current_user.id)
    await db.commit()
    return {"message": "Payment registered"}
