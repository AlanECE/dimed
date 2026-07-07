import base64
from datetime import date, datetime, time
from decimal import Decimal
from pathlib import Path
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.commandes.schemas import UpdateRemisesRequest
from app.db.session import get_db
from app.documents.service import (
    create_route_sheet,
    get_route_sheet,
    get_route_sheet_orders,
)
from app.models.camion import Camion
from app.models.commande import Commande, LigneCommande, OrderStatus
from app.models.document import BonDeLivraison, Facture, FeuilleDeRoute
from app.models.user import User

STORAGE_ROOT = Path(__file__).resolve().parents[3] / "storage" / "documents"

router = APIRouter()


def _require_route_sheet_access(current_user: User, feuille: FeuilleDeRoute) -> None:
    if current_user.role.value in ("operatrice", "admin"):
        return
    if current_user.role.value == "livreur" and feuille.livreur_id == current_user.id:
        return
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


@router.get("/factures")
async def list_factures(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    date_from: date | None = None,
    date_to: date | None = None,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    if current_user.role.value not in ("pharmacien", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    query = select(Facture, Commande).join(Commande, Facture.commande_id == Commande.id)

    if current_user.role.value == "pharmacien":
        query = query.where(Commande.pharmacien_id == current_user.id)

    if date_from:
        query = query.where(Facture.date_emission >= date_from)
    if date_to:
        query = query.where(Facture.date_emission <= datetime.combine(date_to, time.max))

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(Facture.date_emission.desc()).offset(offset).limit(min(limit, 100))
    result = await db.execute(query)
    rows = result.all()

    # Collect pharmacien names
    pharmacien_ids = {r.Commande.pharmacien_id for r in rows}
    pharmacien_map: dict = {}
    if pharmacien_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharmacien_ids)))
        pharmacien_map = {u.id: u.nom for u in users_result.scalars().all()}

    items = []
    for row in rows:
        f = row.Facture
        c = row.Commande
        items.append(
            {
                "id": str(f.id),
                "reference_id": f.reference_id,
                "commande_id": str(f.commande_id),
                "commande_reference": c.reference_id,
                "pharmacien_nom": pharmacien_map.get(c.pharmacien_id, "—"),
                "date_emission": f.date_emission.isoformat(),
                "montant_ht": float(f.montant_ht),
                "montant_ttc": float(f.montant_ttc),
            }
        )

    return {"items": items, "total": total, "limit": limit, "offset": offset}


@router.get("/bons-livraison")
async def list_bons_livraison(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    if current_user.role.value not in ("pharmacien", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    query = select(BonDeLivraison, Commande).join(
        Commande, BonDeLivraison.commande_id == Commande.id
    )

    if current_user.role.value == "pharmacien":
        query = query.where(Commande.pharmacien_id == current_user.id)

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = (
        query.order_by(BonDeLivraison.date_emission.desc()).offset(offset).limit(min(limit, 100))
    )
    result = await db.execute(query)
    rows = result.all()

    items = []
    for row in rows:
        bl = row.BonDeLivraison
        c = row.Commande
        items.append(
            {
                "id": str(bl.id),
                "code_barre": bl.code_barre,
                "commande_id": str(bl.commande_id),
                "commande_reference": c.reference_id,
                "date_emission": bl.date_emission.isoformat(),
            }
        )

    return {"items": items, "total": total, "limit": limit, "offset": offset}


@router.get("/proformas")
async def list_proformas(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    date_from: date | None = None,
    date_to: date | None = None,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    """List commandes for which a proforma can be issued.

    Contrairement à la facture (émise à la validation opératrice), la
    proforma est disponible pour toute commande non annulée, générée à la
    volée depuis l'état courant des lignes.
    """
    if current_user.role.value not in ("pharmacien", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    query = select(Commande).where(Commande.statut != OrderStatus.ANNULEE)

    if current_user.role.value == "pharmacien":
        query = query.where(Commande.pharmacien_id == current_user.id)

    if date_from:
        query = query.where(Commande.created_at >= date_from)
    if date_to:
        query = query.where(Commande.created_at <= datetime.combine(date_to, time.max))

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(Commande.created_at.desc()).offset(offset).limit(min(limit, 100))
    result = await db.execute(query)
    commandes = list(result.scalars().all())

    pharmacien_ids = {c.pharmacien_id for c in commandes}
    pharmacien_map: dict = {}
    if pharmacien_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharmacien_ids)))
        pharmacien_map = {u.id: u.nom for u in users_result.scalars().all()}

    items = [
        {
            "commande_id": str(c.id),
            "reference_id": f"PRO-{c.reference_id}",
            "commande_reference": c.reference_id,
            "pharmacien_nom": pharmacien_map.get(c.pharmacien_id, "—"),
            "date": c.created_at.isoformat(),
            "montant_total": float(c.montant_total),
            "statut": c.statut.value if hasattr(c.statut, "value") else c.statut,
        }
        for c in commandes
    ]

    return {"items": items, "total": total, "limit": limit, "offset": offset}


@router.get("/proforma/{commande_id}")
async def download_proforma(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> FileResponse:
    """Generate and download the proforma PDF for a commande (any status)."""
    if current_user.role.value not in ("pharmacien", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    cmd_result = await db.execute(select(Commande).where(Commande.id == commande_id))
    commande = cmd_result.scalar_one_or_none()
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Commande not found")

    if current_user.role.value == "pharmacien" and commande.pharmacien_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")

    from app.documents.service import generate_proforma_pdf

    path = await generate_proforma_pdf(db, commande)

    return FileResponse(
        path=str(path),
        media_type="application/pdf",
        filename=f"proforma_{commande.reference_id}.pdf",
    )


@router.get("/facture/{commande_id}")
async def download_facture(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> FileResponse:
    if current_user.role.value not in ("pharmacien", "operatrice", "admin", "facturier"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

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

    file_path = (STORAGE_ROOT / "factures" / f"{facture.reference_id}.pdf").resolve()
    if not file_path.is_relative_to(STORAGE_ROOT.resolve()):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid reference")

    if not file_path.exists():
        from app.documents.service import regenerate_facture_pdf

        await regenerate_facture_pdf(db, facture)
        if not file_path.exists():
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="PDF generation failed",
            )

    return FileResponse(
        path=str(file_path),
        media_type="application/pdf",
        filename=f"facture_{facture.reference_id}.pdf",
    )


@router.patch("/facture/{commande_id}/remises")
async def update_facture_remises(
    commande_id: UUID,
    body: UpdateRemisesRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Update per-line discounts on an existing facture and regenerate PDF.

    Operatrice/admin only — the pharmacien never edits his own discount.
    """
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operatrice/admin only",
        )

    facture_result = await db.execute(select(Facture).where(Facture.commande_id == commande_id))
    facture = facture_result.scalar_one_or_none()
    if not facture:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Facture not found")

    # Validate all ligne_id belong to this commande
    line_ids = [lr.ligne_id for lr in body.lines]
    existing_result = await db.execute(
        select(LigneCommande.id).where(
            LigneCommande.commande_id == commande_id,
            LigneCommande.id.in_(line_ids),
        )
    )
    existing_ids = {row[0] for row in existing_result}
    if set(line_ids) != existing_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or more ligne_id do not belong to this commande",
        )

    remises_map: dict[UUID, Decimal] = {lr.ligne_id: lr.remise_pct for lr in body.lines}

    db.info["actor_id"] = str(current_user.id)

    from app.documents.service import regenerate_facture_pdf

    await regenerate_facture_pdf(db, facture, remises=remises_map)
    await db.commit()
    await db.refresh(facture)

    return {
        "id": str(facture.id),
        "reference_id": facture.reference_id,
        "commande_id": str(facture.commande_id),
        "montant_ht": float(facture.montant_ht),
        "montant_ttc": float(facture.montant_ttc),
    }


@router.get("/bl/{commande_id}")
async def download_bl(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> FileResponse:
    if current_user.role.value not in ("pharmacien", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    result = await db.execute(
        select(BonDeLivraison).where(BonDeLivraison.commande_id == commande_id)
    )
    bl = result.scalar_one_or_none()
    if not bl:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="BL not found")

    # Pharmacien can only access own order's BL
    if current_user.role.value == "pharmacien":
        cmd_result = await db.execute(select(Commande).where(Commande.id == commande_id))
        commande = cmd_result.scalar_one_or_none()
        if not commande or commande.pharmacien_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")

    file_path = (STORAGE_ROOT / "bls" / f"{bl.code_barre}.pdf").resolve()
    if not file_path.is_relative_to(STORAGE_ROOT.resolve()):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid reference")
    if not file_path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="PDF not generated yet")

    return FileResponse(
        path=str(file_path),
        media_type="application/pdf",
        filename=f"bl_{bl.code_barre}.pdf",
    )


class CreateRouteSheetRequest(BaseModel):
    camion_id: UUID
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


@router.get("/feuilles-route")
async def list_feuilles_route(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """List all route sheets with camion info and assigned commandes."""
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    result = await db.execute(select(FeuilleDeRoute).order_by(FeuilleDeRoute.date.desc()))
    feuilles = result.scalars().all()

    # Load camion info
    camion_ids = {f.camion_id for f in feuilles}
    camions_map: dict = {}
    if camion_ids:
        camions_result = await db.execute(select(Camion).where(Camion.id.in_(camion_ids)))
        camions_map = {c.id: c for c in camions_result.scalars().all()}

    sheets = []
    for f in feuilles:
        camion = camions_map.get(f.camion_id)
        commandes = await get_route_sheet_orders(db, f)

        sheets.append(
            {
                "id": str(f.id),
                "camion_id": str(f.camion_id),
                "camion_nom": camion.nom if camion else "Inconnu",
                "camion_plaque": camion.plaque if camion else "",
                "date": str(f.date),
                "ligne": f.ligne,
                "compteurs": f.compteurs,
                "commandes": [
                    {
                        "id": str(c.id),
                        "reference_id": c.reference_id,
                        "montant_total": float(c.montant_total),
                        "pharmacien_id": str(c.pharmacien_id),
                        "statut": c.statut.value if hasattr(c.statut, "value") else c.statut,
                    }
                    for c in commandes
                ],
            }
        )

    return {"feuilles": sheets, "total": len(sheets)}


@router.get("/feuilles-route/today")
async def get_today_route_sheet(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Get the route sheet assigned to this livreur for today (read-only)."""
    if current_user.role.value not in ("livreur", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Livreur/admin only")

    today = date.today()

    result = await db.execute(
        select(FeuilleDeRoute).where(
            FeuilleDeRoute.livreur_id == current_user.id,
            FeuilleDeRoute.date == today,
        )
    )
    feuille = result.scalar_one_or_none()

    if not feuille:
        return {"feuille": None}

    # Load camion info
    camion_result = await db.execute(select(Camion).where(Camion.id == feuille.camion_id))
    camion = camion_result.scalar_one_or_none()

    # Load commandes linked to this route sheet only.
    commandes = await get_route_sheet_orders(
        db,
        feuille,
        statuses=[
            OrderStatus.PRETE,
            OrderStatus.EN_ROUTE,
            OrderStatus.LIVREE,
            OrderStatus.REFUSEE,
            OrderStatus.RETOURNEE,
            OrderStatus.LIVREE_PARTIELLEMENT,
        ],
    )

    # Load pharmacien info
    pharm_ids = {c.pharmacien_id for c in commandes}
    users_map: dict[UUID, User] = {}
    if pharm_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharm_ids)))
        users_map = {u.id: u for u in users_result.scalars().all()}

    # Pads de tir : chaque commande est déposée par le magasinier sur un pad —
    # le livreur doit savoir où récupérer ses colis.
    from app.models.colis import Colis, PadTir

    pads_by_commande: dict[UUID, list[dict]] = {}
    if commandes:
        pads_result = await db.execute(
            select(Colis.commande_id, PadTir.code, PadTir.nom)
            .join(PadTir, Colis.pad_tir_id == PadTir.id)
            .where(Colis.commande_id.in_([c.id for c in commandes]))
            .distinct()
        )
        for commande_id, pad_code, pad_nom in pads_result.all():
            pads_by_commande.setdefault(commande_id, []).append({"code": pad_code, "nom": pad_nom})

    return {
        "feuille": {
            "id": str(feuille.id),
            "camion_id": str(feuille.camion_id),
            "camion_nom": camion.nom if camion else "Inconnu",
            "camion_plaque": camion.plaque if camion else "",
            "date": str(feuille.date),
            "ligne": feuille.ligne,
            "compteurs": feuille.compteurs,
            "chargement_valide": feuille.chargement_valide,
            "signature_expedition": feuille.signature_expedition is not None,
            "signature_chauffeur": feuille.signature_chauffeur is not None,
            "commandes": [
                {
                    "id": str(c.id),
                    "reference_id": c.reference_id,
                    "montant_total": float(c.montant_total),
                    "pharmacien_id": str(c.pharmacien_id),
                    "pharmacien_nom": (
                        users_map[c.pharmacien_id].nom if c.pharmacien_id in users_map else "—"
                    ),
                    "pharmacien_adresse": (
                        users_map[c.pharmacien_id].adresse if c.pharmacien_id in users_map else None
                    ),
                    "pharmacien_secteur": (
                        users_map[c.pharmacien_id].secteur if c.pharmacien_id in users_map else None
                    ),
                    "statut": c.statut.value,
                    "signature_pharmacien": c.signature_pharmacien is not None,
                    "pads_tir": pads_by_commande.get(c.id, []),
                }
                for c in commandes
            ],
        }
    }


@router.post("/feuilles-route/claim-today")
async def claim_today_route_sheet(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Livreur explicitly claims an unassigned route sheet for today."""
    if current_user.role.value not in ("livreur",):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Livreur only")

    today = date.today()

    # Check the livreur doesn't already have a sheet
    existing = await db.execute(
        select(FeuilleDeRoute).where(
            FeuilleDeRoute.livreur_id == current_user.id,
            FeuilleDeRoute.date == today,
        )
    )
    existing_sheet = existing.scalar_one_or_none()
    if existing_sheet:
        return {"status": "ok", "feuille_id": str(existing_sheet.id)}

    # Find unassigned sheets for today that have ready orders
    result = await db.execute(
        select(FeuilleDeRoute).where(
            FeuilleDeRoute.date == today,
            FeuilleDeRoute.livreur_id.is_(None),
        )
    )
    candidate_sheets = result.scalars().all()
    available: list[tuple[FeuilleDeRoute, int]] = []
    for sheet in candidate_sheets:
        orders_result = await db.execute(
            select(func.count())
            .select_from(Commande)
            .where(
                Commande.feuille_route_id == sheet.id,
                Commande.statut == OrderStatus.PRETE,
            )
        )
        ready_count = orders_result.scalar() or 0
        if ready_count > 0:
            available.append((sheet, int(ready_count)))

    if not available:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No unassigned route sheet with ready orders available for today",
        )

    # Auto-pick the busiest available sheet, then the oldest one for a stable claim order.
    available.sort(key=lambda item: (-item[1], item[0].created_at, str(item[0].id)))
    feuille = available[0][0]
    db.info["actor_id"] = str(current_user.id)
    feuille.livreur_id = current_user.id
    await db.commit()
    await db.refresh(feuille)

    return {"status": "ok", "feuille_id": str(feuille.id)}


_MAX_SIGNATURE_B64_LEN = 500_000  # ~375 KB decoded


class SignRouteSheetRequest(BaseModel):
    type: str = Field(pattern=r"^(expedition|chauffeur)$")
    signature: str = Field(
        min_length=10,
        max_length=_MAX_SIGNATURE_B64_LEN,
        description="Base64-encoded PNG signature",
    )


@router.patch("/feuilles-route/{feuille_id}/sign")
async def sign_route_sheet(
    feuille_id: UUID,
    body: SignRouteSheetRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Sign the route sheet (expedition or chauffeur signature)."""
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    feuille = await get_route_sheet(db, feuille_id)
    if not feuille:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route sheet not found")
    _require_route_sheet_access(current_user, feuille)

    db.info["actor_id"] = str(current_user.id)
    try:
        sig_bytes = base64.b64decode(body.signature)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid base64 signature",
        ) from exc

    if body.type == "expedition":
        feuille.signature_expedition = sig_bytes
    else:
        feuille.signature_chauffeur = sig_bytes

    await db.commit()
    return {"status": "ok", "type": body.type}


class ValidateLoadingRequest(BaseModel):
    # Legacy field kept for backward compatibility — loading is now verified
    # against per-parcel scans (colis CHARGE), not a manual checklist.
    colis_checked: list[str] = Field(default_factory=list)


@router.patch("/feuilles-route/{feuille_id}/validate-loading")
async def validate_loading(
    feuille_id: UUID,
    current_user: CurrentUser,
    body: ValidateLoadingRequest | None = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Validate truck loading: every parcel of every ready order must be scanned.

    Returns ok=false with the explicit list of missing parcels instead of
    validating, so the livreur knows exactly which colis to find.
    """
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    feuille = await get_route_sheet(db, feuille_id)
    if not feuille:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route sheet not found")
    _require_route_sheet_access(current_user, feuille)

    commandes = await get_route_sheet_orders(
        db,
        feuille,
        statuses=[OrderStatus.PRETE],
    )

    from app.models.colis import Colis, ColisStatus

    manquants: list[dict] = []
    if commandes:
        colis_result = await db.execute(
            select(Colis)
            .where(Colis.commande_id.in_([c.id for c in commandes]))
            .order_by(Colis.index_colis.asc())
        )
        colis_map: dict[UUID, list[Colis]] = {}
        for colis in colis_result.scalars().all():
            colis_map.setdefault(colis.commande_id, []).append(colis)

        for c in commandes:
            # Orders created before parcel tracking have no colis — skip them.
            missing_colis = [
                k.numero
                for k in colis_map.get(c.id, [])
                if k.statut not in (ColisStatus.CHARGE, ColisStatus.LIVRE)
            ]
            if missing_colis:
                manquants.append(
                    {
                        "commande_ref": c.reference_id,
                        "colis": missing_colis,
                    }
                )

    if manquants:
        return {
            "status": "incomplete",
            "ok": False,
            "chargement_valide": False,
            "manquants": manquants,
        }

    db.info["actor_id"] = str(current_user.id)
    feuille.chargement_valide = True
    await db.commit()
    return {"status": "ok", "ok": True, "chargement_valide": True, "manquants": []}


@router.get("/feuilles-route/{feuille_id}/pdf")
async def download_feuille_route_pdf(
    feuille_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Generate and download feuille de route PDF."""
    from fastapi.responses import FileResponse

    from app.documents.pdf_generator import generate_feuille_route_pdf

    feuille = await get_route_sheet(db, feuille_id)
    if not feuille:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route sheet not found",
        )
    _require_route_sheet_access(current_user, feuille)

    camion_result = await db.execute(select(Camion).where(Camion.id == feuille.camion_id))
    camion = camion_result.scalar_one_or_none()

    commandes = await get_route_sheet_orders(db, feuille)

    pharm_ids = {c.pharmacien_id for c in commandes}
    users_map: dict[UUID, User] = {}
    if pharm_ids:
        u_result = await db.execute(select(User).where(User.id.in_(pharm_ids)))
        users_map = {u.id: u for u in u_result.scalars().all()}

    cmd_data = []
    for c in commandes:
        pharm = users_map.get(c.pharmacien_id)
        cmd_data.append(
            {
                "client": pharm.nom if pharm else "—",
                "commande_ref": c.reference_id,
                "facture_ref": "—",
                "n_prelv": "—",
                "c_std": "",
                "sc_std": "",
                "bl_std_c_frg": "",
                "sac_frg": "",
            }
        )

    path = generate_feuille_route_pdf(
        date_str=str(feuille.date),
        camion_nom=camion.nom if camion else "—",
        camion_plaque=camion.plaque if camion else "—",
        ligne=feuille.ligne,
        commandes=cmd_data,
        compteurs=feuille.compteurs,
    )

    return FileResponse(
        path=str(path),
        media_type="application/pdf",
        filename=f"feuille_route_{feuille.date}.pdf",
    )


@router.get("/feuilles-route/{feuille_id}")
async def get_feuille_route(
    feuille_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> RouteSheetResponse:
    feuille = await get_route_sheet(db, feuille_id)
    if not feuille:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route sheet not found",
        )
    _require_route_sheet_access(current_user, feuille)
    return RouteSheetResponse.model_validate(feuille)
