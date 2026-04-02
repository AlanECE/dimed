from datetime import UTC, date, datetime
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.arrivage import Arrivage
from app.models.medicament import Medicament

router = APIRouter()


class CreateArrivageRequest(BaseModel):
    medicament_id: UUID
    quantite: int = Field(ge=1)
    n_lot: str | None = None
    date_arrivage: date
    date_peremption: date | None = None
    fournisseur: str | None = None


class ArrivageResponse(BaseModel):
    id: str
    medicament_id: str
    designation: str
    quantite: int
    n_lot: str | None
    date_arrivage: str
    date_peremption: str | None
    fournisseur: str | None
    created_at: str


@router.get("/")
async def list_arrivages(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    date_filter: date | None = Query(None),  # noqa: B008
    limit: int = Query(50, ge=1, le=200),  # noqa: B008
    offset: int = Query(0, ge=0),  # noqa: B008
) -> dict:
    """List arrivages, default today."""
    if current_user.role.value not in (
        "operatrice",
        "admin",
        "pharmacien",
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    target_date = date_filter or date.today()

    query = (
        select(Arrivage, Medicament.designation)
        .join(Medicament, Arrivage.medicament_id == Medicament.id)
        .where(Arrivage.date_arrivage == target_date)
        .order_by(Arrivage.created_at_arrivage.desc())
        .limit(limit)
        .offset(offset)
    )

    count_q = (
        select(func.count()).select_from(Arrivage).where(Arrivage.date_arrivage == target_date)
    )

    result = await db.execute(query)
    rows = result.all()
    total = (await db.execute(count_q)).scalar() or 0

    items = []
    for row in rows:
        arr = row.Arrivage
        items.append(
            ArrivageResponse(
                id=str(arr.id),
                medicament_id=str(arr.medicament_id),
                designation=row.designation,
                quantite=arr.quantite,
                n_lot=arr.n_lot,
                date_arrivage=str(arr.date_arrivage),
                date_peremption=(str(arr.date_peremption) if arr.date_peremption else None),
                fournisseur=arr.fournisseur,
                created_at=arr.created_at_arrivage.isoformat(),
            )
        )

    return {"items": items, "total": total, "date": str(target_date)}


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_arrivage(
    body: CreateArrivageRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> ArrivageResponse:
    """Create a new arrivage and update stock."""
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    # Verify medicament exists
    med_result = await db.execute(
        select(Medicament).where(
            Medicament.id == body.medicament_id,
        )
    )
    med = med_result.scalar_one_or_none()
    if not med:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicament not found",
        )

    db.info["actor_id"] = str(current_user.id)

    arrivage = Arrivage(
        id=uuid4(),
        medicament_id=body.medicament_id,
        quantite=body.quantite,
        n_lot=body.n_lot,
        date_arrivage=body.date_arrivage,
        date_peremption=body.date_peremption,
        fournisseur=body.fournisseur,
        created_at_arrivage=datetime.now(UTC),
    )
    db.add(arrivage)

    # Auto-update stock
    med.stock_quantity += body.quantite

    await db.commit()
    await db.refresh(arrivage)

    return ArrivageResponse(
        id=str(arrivage.id),
        medicament_id=str(arrivage.medicament_id),
        designation=med.designation,
        quantite=arrivage.quantite,
        n_lot=arrivage.n_lot,
        date_arrivage=str(arrivage.date_arrivage),
        date_peremption=(str(arrivage.date_peremption) if arrivage.date_peremption else None),
        fournisseur=arrivage.fournisseur,
        created_at=arrivage.created_at_arrivage.isoformat(),
    )
