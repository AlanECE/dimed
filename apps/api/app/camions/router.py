from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.camion import Camion
from app.models.document import FeuilleDeRoute

router = APIRouter()


class CreateCamionRequest(BaseModel):
    nom: str = Field(min_length=1, max_length=100)
    plaque: str = Field(min_length=1, max_length=20)


class UpdateCamionRequest(BaseModel):
    nom: str | None = None
    plaque: str | None = None


class CamionResponse(BaseModel):
    id: UUID
    nom: str
    plaque: str
    created_at: datetime

    model_config = {"from_attributes": True}


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_camion(
    body: CreateCamionRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> CamionResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    # Check unique plaque
    existing = await db.execute(select(Camion).where(Camion.plaque == body.plaque))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Plaque already exists")

    db.info["actor_id"] = str(current_user.id)
    camion = Camion(nom=body.nom, plaque=body.plaque)
    db.add(camion)
    await db.commit()
    await db.refresh(camion)
    return CamionResponse.model_validate(camion)


@router.get("/")
async def list_camions(
    _user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    result = await db.execute(select(Camion).order_by(Camion.nom))
    camions = result.scalars().all()

    count_result = await db.execute(select(func.count()).select_from(Camion))
    total = count_result.scalar()

    return {
        "camions": [CamionResponse.model_validate(c) for c in camions],
        "total": total,
    }


@router.get("/{camion_id}")
async def get_camion(
    camion_id: UUID,
    _user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> CamionResponse:
    result = await db.execute(select(Camion).where(Camion.id == camion_id))
    camion = result.scalar_one_or_none()
    if not camion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camion not found")
    return CamionResponse.model_validate(camion)


@router.patch("/{camion_id}")
async def update_camion(
    camion_id: UUID,
    body: UpdateCamionRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> CamionResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    result = await db.execute(select(Camion).where(Camion.id == camion_id))
    camion = result.scalar_one_or_none()
    if not camion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camion not found")

    db.info["actor_id"] = str(current_user.id)
    if body.nom is not None:
        camion.nom = body.nom
    if body.plaque is not None:
        # Check unique plaque
        existing = await db.execute(
            select(Camion).where(Camion.plaque == body.plaque, Camion.id != camion_id)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Plaque already exists",
            )
        camion.plaque = body.plaque

    await db.commit()
    await db.refresh(camion)
    return CamionResponse.model_validate(camion)


@router.delete("/{camion_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_camion(
    camion_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> None:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    result = await db.execute(select(Camion).where(Camion.id == camion_id))
    camion = result.scalar_one_or_none()
    if not camion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camion not found")

    # Check no active route sheets
    active = await db.execute(select(FeuilleDeRoute).where(FeuilleDeRoute.camion_id == camion_id))
    if active.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot delete truck with active route sheets",
        )

    db.info["actor_id"] = str(current_user.id)
    await db.delete(camion)
    await db.commit()
