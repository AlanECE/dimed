from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.medicament import Medicament

router = APIRouter()


class MedicamentResponse(BaseModel):
    id: str
    code_article: str
    designation: str
    dci: str | None
    dosage: str | None
    forme: str | None
    ppa: float
    fabricant: str | None

    model_config = {"from_attributes": True}


@router.get("/")
async def list_medicaments(
    _user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    search: str | None = Query(None, min_length=2, description="Fuzzy search on designation"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> dict:
    if search:
        query = (
            select(Medicament)
            .where(func.similarity(Medicament.designation, search) > 0.2)
            .order_by(Medicament.designation.op("<->")(search))
            .limit(limit)
            .offset(offset)
        )
        count_query = (
            select(func.count())
            .select_from(Medicament)
            .where(func.similarity(Medicament.designation, search) > 0.2)
        )
    else:
        query = select(Medicament).order_by(Medicament.designation).limit(limit).offset(offset)
        count_query = select(func.count()).select_from(Medicament)

    result = await db.execute(query)
    medicaments = result.scalars().all()

    count_result = await db.execute(count_query)
    total = count_result.scalar()

    return {
        "medicaments": [MedicamentResponse.model_validate(m) for m in medicaments],
        "total": total,
        "limit": limit,
        "offset": offset,
    }


@router.get("/{medicament_id}")
async def get_medicament(
    medicament_id: UUID,
    _user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> MedicamentResponse:
    result = await db.execute(select(Medicament).where(Medicament.id == medicament_id))
    medicament = result.scalar_one_or_none()

    if not medicament:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicament not found",
        )

    return MedicamentResponse.model_validate(medicament)
