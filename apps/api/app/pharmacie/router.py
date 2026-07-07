"""Module pharmacie (officine) : arrivages + stock du pharmacien.

Deux façons d'alimenter le stock :
- scan OCR d'une vignette (un seul scan, puis ajustement de la quantité) ;
- import du contenu d'une commande livrée (sans repasser par l'OCR).

Chaque arrivage validé génère un CSV téléchargeable et incrémente le stock.
"""

import csv
import io
import logging
from datetime import date
from decimal import Decimal
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import Response
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.commande import Commande, LigneCommande, OrderStatus
from app.models.medicament import Medicament
from app.models.pharmacie import (
    ArrivagePharmacien,
    ArrivagePharmacienLigne,
    ArrivageSource,
    StockPharmacien,
)

logger = logging.getLogger(__name__)

router = APIRouter()

_MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MiB
_ALLOWED_CONTENT_TYPES = ("image/jpeg", "image/jpg", "image/png", "image/webp")

_DELIVERED_STATUSES = (OrderStatus.LIVREE, OrderStatus.LIVREE_PARTIELLEMENT)


def _require_pharmacien(current_user) -> None:
    if current_user.role.value not in ("pharmacien", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Pharmacien only")


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class ArrivageLigneRequest(BaseModel):
    designation: str = Field(min_length=1, max_length=255)
    quantite: int = Field(ge=1, le=100_000)
    ppa: Decimal | None = Field(default=None, ge=0)
    n_lot: str | None = Field(default=None, max_length=50)
    exp: date | None = None


class CreateArrivageRequest(BaseModel):
    source: ArrivageSource
    commande_id: UUID | None = None
    lignes: list[ArrivageLigneRequest] = Field(min_length=1, max_length=200)


# ---------------------------------------------------------------------------
# OCR scan (aucune persistance : le pharmacien ajuste ensuite la quantité)
# ---------------------------------------------------------------------------


@router.post("/arrivages/scan")
async def scan_etiquette(
    current_user: CurrentUser,
    file: Annotated[UploadFile, File(...)],
) -> dict:
    """Scan OCR d'une étiquette : renvoie les champs extraits, sans rien créer."""
    _require_pharmacien(current_user)

    from app.ocr.service import (
        OcrConfigurationError,
        OcrUpstreamError,
        extract_vignette_fields,
    )

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Empty file")
    if len(image_bytes) > _MAX_IMAGE_BYTES:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "Image exceeds 10 MiB limit")
    content_type = (file.content_type or "").lower()
    if content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            "Unsupported format (JPG/PNG/WEBP only)",
        )

    try:
        extraction = await extract_vignette_fields(image_bytes, content_type)
    except OcrConfigurationError as exc:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, str(exc)) from exc
    except OcrUpstreamError as exc:
        logger.warning("OCR upstream failure (arrivage pharmacien): %s", exc)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"OCR error: {exc}") from exc

    return {
        "designation": extraction.designation,
        "ppa": str(extraction.ppa) if extraction.ppa is not None else None,
        "n_lot": extraction.lot,
        "exp": extraction.exp.isoformat() if extraction.exp else None,
    }


# ---------------------------------------------------------------------------
# Arrivages
# ---------------------------------------------------------------------------


async def _upsert_stock(
    db: AsyncSession,
    pharmacien_id: UUID,
    ligne: ArrivageLigneRequest,
) -> None:
    """Incrémente le stock du pharmacien (création de la ligne si nouvelle)."""
    designation = ligne.designation.strip()

    existing_result = await db.execute(
        select(StockPharmacien).where(
            StockPharmacien.pharmacien_id == pharmacien_id,
            func.lower(StockPharmacien.designation) == designation.lower(),
        )
    )
    stock = existing_result.scalar_one_or_none()

    if stock is not None:
        stock.quantite += ligne.quantite
        if ligne.ppa is not None:
            stock.ppa = ligne.ppa
        return

    # Lien facultatif avec le catalogue DIMED (par désignation exacte)
    med_result = await db.execute(
        select(Medicament.id).where(func.lower(Medicament.designation) == designation.lower())
    )
    medicament_id = med_result.scalar_one_or_none()

    db.add(
        StockPharmacien(
            id=uuid4(),
            pharmacien_id=pharmacien_id,
            medicament_id=medicament_id,
            designation=designation,
            quantite=ligne.quantite,
            ppa=ligne.ppa,
        )
    )


@router.post("/arrivages", status_code=status.HTTP_201_CREATED)
async def create_arrivage(
    body: CreateArrivageRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Valide un arrivage : persiste les lignes et incrémente le stock."""
    _require_pharmacien(current_user)

    if body.source == ArrivageSource.COMMANDE:
        if body.commande_id is None:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                "commande_id requis pour un arrivage depuis une commande",
            )
        cmd_result = await db.execute(select(Commande).where(Commande.id == body.commande_id))
        commande = cmd_result.scalar_one_or_none()
        if not commande:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Commande introuvable")
        if current_user.role.value == "pharmacien" and commande.pharmacien_id != current_user.id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your order")
        if commande.statut not in _DELIVERED_STATUSES:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Seules les commandes livrées peuvent alimenter le stock",
            )
        dup_result = await db.execute(
            select(ArrivagePharmacien.id).where(
                ArrivagePharmacien.commande_id == body.commande_id,
                ArrivagePharmacien.pharmacien_id == current_user.id,
            )
        )
        if dup_result.scalar_one_or_none() is not None:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Cette commande a déjà été importée dans le stock",
            )

    arrivage = ArrivagePharmacien(
        id=uuid4(),
        pharmacien_id=current_user.id,
        source=body.source,
        commande_id=body.commande_id,
    )
    db.add(arrivage)

    for ligne in body.lignes:
        db.add(
            ArrivagePharmacienLigne(
                id=uuid4(),
                arrivage_id=arrivage.id,
                designation=ligne.designation.strip(),
                quantite=ligne.quantite,
                ppa=ligne.ppa,
                n_lot=ligne.n_lot,
                exp=ligne.exp,
            )
        )
        await _upsert_stock(db, current_user.id, ligne)

    db.info["actor_id"] = str(current_user.id)
    await db.commit()

    return {
        "id": str(arrivage.id),
        "source": body.source.value,
        "lignes": len(body.lignes),
        "csv_url": f"/pharmacie/arrivages/{arrivage.id}/csv",
    }


@router.get("/arrivages")
async def list_arrivages(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    _require_pharmacien(current_user)

    base = select(ArrivagePharmacien).where(ArrivagePharmacien.pharmacien_id == current_user.id)
    total = (await db.execute(select(func.count()).select_from(base.subquery()))).scalar() or 0

    result = await db.execute(
        base.order_by(ArrivagePharmacien.created_at.desc()).offset(offset).limit(min(limit, 100))
    )
    arrivages = list(result.scalars().all())

    # Références des commandes importées + nombre de lignes par arrivage
    commande_ids = {a.commande_id for a in arrivages if a.commande_id}
    refs_map: dict = {}
    if commande_ids:
        refs_result = await db.execute(
            select(Commande.id, Commande.reference_id).where(Commande.id.in_(commande_ids))
        )
        refs_map = {row.id: row.reference_id for row in refs_result}

    counts_map: dict = {}
    if arrivages:
        counts_result = await db.execute(
            select(ArrivagePharmacienLigne.arrivage_id, func.count())
            .where(ArrivagePharmacienLigne.arrivage_id.in_([a.id for a in arrivages]))
            .group_by(ArrivagePharmacienLigne.arrivage_id)
        )
        counts_map = dict(counts_result.all())

    return {
        "items": [
            {
                "id": str(a.id),
                "source": a.source.value if hasattr(a.source, "value") else a.source,
                "commande_reference": refs_map.get(a.commande_id),
                "nb_lignes": counts_map.get(a.id, 0),
                "created_at": a.created_at.isoformat(),
            }
            for a in arrivages
        ],
        "total": total,
        "limit": limit,
        "offset": offset,
    }


@router.get("/arrivages/{arrivage_id}/csv")
async def download_arrivage_csv(
    arrivage_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> Response:
    """CSV de l'arrivage (délimiteur ';' pour Excel FR)."""
    _require_pharmacien(current_user)

    result = await db.execute(
        select(ArrivagePharmacien).where(
            ArrivagePharmacien.id == arrivage_id,
            ArrivagePharmacien.pharmacien_id == current_user.id,
        )
    )
    arrivage = result.scalar_one_or_none()
    if not arrivage:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Arrivage introuvable")

    lignes_result = await db.execute(
        select(ArrivagePharmacienLigne)
        .where(ArrivagePharmacienLigne.arrivage_id == arrivage_id)
        .order_by(ArrivagePharmacienLigne.created_at.asc())
    )
    lignes = list(lignes_result.scalars().all())

    buffer = io.StringIO()
    writer = csv.writer(buffer, delimiter=";")
    writer.writerow(["designation", "quantite", "ppa", "lot", "exp"])
    for ligne in lignes:
        writer.writerow(
            [
                ligne.designation,
                ligne.quantite,
                f"{ligne.ppa:.2f}" if ligne.ppa is not None else "",
                ligne.n_lot or "",
                ligne.exp.isoformat() if ligne.exp else "",
            ]
        )

    date_str = arrivage.created_at.strftime("%Y%m%d_%H%M")
    return Response(
        content="﻿" + buffer.getvalue(),  # BOM pour Excel
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": f'attachment; filename="arrivage_{date_str}.csv"',
        },
    )


# ---------------------------------------------------------------------------
# Import depuis une commande livrée
# ---------------------------------------------------------------------------


@router.get("/commandes-livrees")
async def list_commandes_livrees(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    limit: int = 10,
) -> dict:
    """Commandes livrées du pharmacien, avec drapeau « déjà importée »."""
    _require_pharmacien(current_user)

    result = await db.execute(
        select(Commande)
        .where(
            Commande.pharmacien_id == current_user.id,
            Commande.statut.in_(_DELIVERED_STATUSES),
        )
        .order_by(Commande.created_at.desc())
        .limit(min(limit, 50))
    )
    commandes = list(result.scalars().all())

    imported_result = await db.execute(
        select(ArrivagePharmacien.commande_id).where(
            ArrivagePharmacien.pharmacien_id == current_user.id,
            ArrivagePharmacien.commande_id.is_not(None),
        )
    )
    imported_ids = {row[0] for row in imported_result}

    return {
        "items": [
            {
                "id": str(c.id),
                "reference_id": c.reference_id,
                "statut": c.statut.value,
                "montant_total": float(c.montant_total),
                "date": c.created_at.isoformat(),
                "deja_importee": c.id in imported_ids,
            }
            for c in commandes
        ]
    }


@router.get("/commandes/{reference}/lignes")
async def get_commande_lignes_for_import(
    reference: str,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Prévisualisation des lignes d'une commande livrée (par référence)."""
    _require_pharmacien(current_user)

    result = await db.execute(
        select(Commande).where(Commande.reference_id == reference.strip().upper())
    )
    commande = result.scalar_one_or_none()
    if not commande:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Commande introuvable")
    if current_user.role.value == "pharmacien" and commande.pharmacien_id != current_user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your order")
    if commande.statut not in _DELIVERED_STATUSES:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Commande non livrée (statut {commande.statut.value})",
        )

    dup_result = await db.execute(
        select(ArrivagePharmacien.id).where(
            ArrivagePharmacien.commande_id == commande.id,
            ArrivagePharmacien.pharmacien_id == current_user.id,
        )
    )
    deja_importee = dup_result.scalar_one_or_none() is not None

    lignes_result = await db.execute(
        select(LigneCommande)
        .where(LigneCommande.commande_id == commande.id)
        .order_by(LigneCommande.id)
    )
    lignes = list(lignes_result.scalars().all())

    return {
        "commande_id": str(commande.id),
        "reference_id": commande.reference_id,
        "statut": commande.statut.value,
        "deja_importee": deja_importee,
        "lignes": [
            {
                "designation": ligne.designation,
                # Quantité réellement livrée si connue, sinon la quantité commandée.
                "quantite": ligne.qte_prelevee
                if ligne.qte_prelevee is not None
                else ligne.qte_demandee,
                "ppa": str(ligne.ppa if ligne.ppa is not None else ligne.prix_unitaire),
                "n_lot": ligne.n_lot,
                "exp": ligne.exp.isoformat() if ligne.exp else None,
            }
            for ligne in lignes
        ],
    }


# ---------------------------------------------------------------------------
# Stock
# ---------------------------------------------------------------------------


@router.get("/stock")
async def get_stock(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    search: str | None = None,
    limit: int = 50,
    offset: int = 0,
) -> dict:
    _require_pharmacien(current_user)

    base = select(StockPharmacien).where(StockPharmacien.pharmacien_id == current_user.id)
    if search and search.strip():
        base = base.where(StockPharmacien.designation.ilike(f"%{search.strip()}%"))

    total = (await db.execute(select(func.count()).select_from(base.subquery()))).scalar() or 0

    result = await db.execute(
        base.order_by(StockPharmacien.designation.asc()).offset(offset).limit(min(limit, 200))
    )
    stock = list(result.scalars().all())

    return {
        "items": [
            {
                "id": str(s.id),
                "designation": s.designation,
                "quantite": s.quantite,
                "ppa": float(s.ppa) if s.ppa is not None else None,
                "updated_at": s.updated_at.isoformat(),
            }
            for s in stock
        ],
        "total": total,
        "limit": limit,
        "offset": offset,
    }
