from datetime import date
from pathlib import Path
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.documents.service import create_route_sheet, get_route_sheet
from app.models.commande import Commande
from app.models.document import BonDeLivraison, Facture

STORAGE_ROOT = Path(__file__).resolve().parents[3] / "storage" / "documents"

router = APIRouter()


@router.get("/facture/{commande_id}")
async def download_facture(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> FileResponse:
    result = await db.execute(select(Facture).where(Facture.commande_id == commande_id))
    facture = result.scalar_one_or_none()
    if not facture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Facture not found")

    # Pharmacien can only access own order's facture
    if current_user.role.value == "pharmacien":
        cmd_result = await db.execute(select(Commande).where(Commande.id == commande_id))
        commande = cmd_result.scalar_one_or_none()
        if not commande or commande.pharmacien_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")

    file_path = STORAGE_ROOT / "factures" / f"{facture.reference_id}.pdf"
    if not file_path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="PDF not generated yet")

    return FileResponse(
        path=str(file_path),
        media_type="application/pdf",
        filename=f"facture_{facture.reference_id}.pdf",
    )


@router.get("/bl/{commande_id}")
async def download_bl(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> FileResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    result = await db.execute(
        select(BonDeLivraison).where(BonDeLivraison.commande_id == commande_id)
    )
    bl = result.scalar_one_or_none()
    if not bl:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="BL not found")

    file_path = STORAGE_ROOT / "bls" / f"{bl.code_barre}.pdf"
    if not file_path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="PDF not generated yet")

    return FileResponse(
        path=str(file_path),
        media_type="application/pdf",
        filename=f"bl_{bl.code_barre}.pdf",
    )


class CreateRouteSheetRequest(BaseModel):
    camion_id: str
    date: date


class RouteSheetResponse(BaseModel):
    id: str
    camion_id: str
    date: date
    ligne: str | None
    n_rotation: str | None
    compteurs: dict

    model_config = {"from_attributes": True}


@router.post("/feuilles-route", status_code=status.HTTP_201_CREATED)
async def create_feuille_route(
    body: CreateRouteSheetRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> RouteSheetResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    db.info["actor_id"] = str(current_user.id)
    feuille = await create_route_sheet(db, body.camion_id, body.date)
    await db.commit()
    await db.refresh(feuille)
    return RouteSheetResponse.model_validate(feuille)


@router.get("/feuilles-route/{feuille_id}")
async def get_feuille_route(
    feuille_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> RouteSheetResponse:
    feuille = await get_route_sheet(db, feuille_id)
    if not feuille:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route sheet not found")
    return RouteSheetResponse.model_validate(feuille)
