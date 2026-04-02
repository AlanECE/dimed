from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.commande import Commande
from app.models.reclamation import Reclamation, ReclamationMotif, ReclamationStatut
from app.models.user import User

router = APIRouter()


class CreateReclamationRequest(BaseModel):
    commande_id: UUID
    motif: ReclamationMotif
    description: str = Field(min_length=1, max_length=5000)


class UpdateReclamationRequest(BaseModel):
    statut: ReclamationStatut | None = None
    resolution: str | None = None


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_reclamation(
    body: CreateReclamationRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    if current_user.role.value not in ("pharmacien", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    # Verify commande exists
    cmd = await db.execute(select(Commande).where(Commande.id == body.commande_id))
    commande = cmd.scalar_one_or_none()
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Commande not found")

    # Pharmacien can only create for own orders
    if current_user.role.value == "pharmacien" and commande.pharmacien_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")

    reclamation = Reclamation(
        pharmacien_id=commande.pharmacien_id,
        commande_id=body.commande_id,
        motif=body.motif,
        description=body.description,
    )
    db.add(reclamation)
    db.info["actor_id"] = str(current_user.id)
    await db.commit()
    await db.refresh(reclamation)

    return {"id": str(reclamation.id), "message": "Réclamation créée"}


@router.get("/")
async def list_reclamations(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    statut: str | None = None,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    query = select(Reclamation, Commande).join(Commande, Reclamation.commande_id == Commande.id)

    if current_user.role.value == "pharmacien":
        query = query.where(Reclamation.pharmacien_id == current_user.id)
    elif current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    if statut:
        query = query.where(Reclamation.statut == statut)

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(Reclamation.created_at.desc()).offset(offset).limit(min(limit, 100))
    result = await db.execute(query)
    rows = result.all()

    pharmacien_ids = {r.Reclamation.pharmacien_id for r in rows}
    pharmacien_map: dict = {}
    if pharmacien_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharmacien_ids)))
        pharmacien_map = {u.id: u.nom for u in users_result.scalars().all()}

    items = []
    for row in rows:
        r = row.Reclamation
        c = row.Commande
        items.append(
            {
                "id": str(r.id),
                "pharmacien_nom": pharmacien_map.get(r.pharmacien_id, "—"),
                "commande_id": str(r.commande_id),
                "commande_reference": c.reference_id,
                "motif": r.motif.value if hasattr(r.motif, "value") else r.motif,
                "description": r.description,
                "statut": r.statut.value if hasattr(r.statut, "value") else r.statut,
                "resolution": r.resolution,
                "created_at": r.created_at.isoformat(),
            }
        )

    return {"items": items, "total": total, "limit": limit, "offset": offset}


@router.patch("/{reclamation_id}")
async def update_reclamation(
    reclamation_id: UUID,
    body: UpdateReclamationRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    result = await db.execute(select(Reclamation).where(Reclamation.id == reclamation_id))
    reclamation = result.scalar_one_or_none()
    if not reclamation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Réclamation not found")

    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(reclamation, field, value)

    db.info["actor_id"] = str(current_user.id)
    await db.commit()
    return {"message": "Réclamation mise à jour"}
