from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.documents.service import get_route_sheet
from app.expedition.schemas import (
    ChargementStateResponse,
    ColisDetailResponse,
    CreatePadRequest,
    DeposePadRequest,
    PadOccupationResponse,
    PadTirResponse,
    RepartitionRequest,
    ScanChargementResponse,
    ScanLivraisonResponse,
    UpdatePadRequest,
)
from app.expedition.service import (
    chargement_state,
    colis_contenu,
    get_colis_by_numero,
    get_commande_colis,
    log_scan,
    suggest_pad,
    validate_repartition,
)
from app.models.colis import Colis, ColisLigne, ColisStatus, PadTir, ScanType
from app.models.commande import Commande, OrderStatus
from app.models.notification import Notification
from app.models.user import User

router = APIRouter()


def _pad_response(pad: PadTir | None) -> PadTirResponse | None:
    if pad is None:
        return None
    return PadTirResponse(id=str(pad.id), code=pad.code, nom=pad.nom, actif=pad.actif)


async def _get_colis_or_404(db: AsyncSession, numero: str) -> Colis:
    colis = await get_colis_by_numero(db, numero)
    if not colis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Colis {numero} introuvable",
        )
    return colis


async def _require_chargement_access(
    db: AsyncSession, current_user: User, commande: Commande
) -> None:
    """A livreur may only scan parcels of orders on his own route sheet."""
    if current_user.role.value in ("operatrice", "admin"):
        return
    if current_user.role.value == "livreur":
        if not commande.feuille_route_id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Commande sans feuille de route",
            )
        feuille = await get_route_sheet(db, commande.feuille_route_id)
        if feuille and feuille.livreur_id == current_user.id:
            return
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ce colis n'appartient pas à votre tournée",
        )
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


@router.get("/colis/{numero}")
async def lookup_colis(
    numero: str,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> ColisDetailResponse:
    """Full parcel lookup from its QR number (the QR encodes only this number)."""
    if current_user.role.value not in (
        "magasinier",
        "livreur",
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    colis = await _get_colis_or_404(db, numero)
    commande = colis.commande

    nb_result = await db.execute(
        select(func.count()).select_from(Colis).where(Colis.commande_id == commande.id)
    )
    nb_colis = nb_result.scalar() or 0

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    pad_suggere: PadTir | None = None
    pad_impose = False
    if colis.statut in (ColisStatus.ETIQUETE, ColisStatus.SUR_PAD):
        pad_suggere, pad_impose = await suggest_pad(db, colis)

    contenu, contenu_detaille = colis_contenu(colis)

    return ColisDetailResponse(
        id=str(colis.id),
        numero=colis.numero,
        statut=colis.statut.value,
        index_colis=colis.index_colis,
        nb_colis=nb_colis,
        commande_id=str(commande.id),
        commande_ref=commande.reference_id,
        commande_statut=commande.statut.value,
        date_commande=commande.created_at.date().isoformat(),
        pharmacien_nom=pharmacien.nom if pharmacien else "—",
        pharmacien_adresse=pharmacien.adresse if pharmacien else None,
        pharmacien_secteur=pharmacien.secteur if pharmacien else None,
        pad=_pad_response(colis.pad_tir),
        pad_suggere=_pad_response(pad_suggere),
        pad_impose=pad_impose,
        contenu=contenu,
        contenu_detaille=contenu_detaille,
    )


@router.post("/colis/{numero}/depose-pad")
async def depose_pad(
    numero: str,
    body: DeposePadRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Magasinier stages a parcel on a pad de tir."""
    if current_user.role.value not in ("magasinier", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    colis = await _get_colis_or_404(db, numero)
    if colis.statut not in (ColisStatus.ETIQUETE, ColisStatus.SUR_PAD):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Colis déjà {colis.statut.value} — dépôt sur pad impossible",
        )

    pad_result = await db.execute(select(PadTir).where(PadTir.id == body.pad_tir_id))
    pad = pad_result.scalar_one_or_none()
    if not pad:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pad de tir introuvable")
    if not pad.actif:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Pad {pad.code} inactif",
        )

    db.info["actor_id"] = str(current_user.id)
    colis.pad_tir_id = pad.id
    colis.statut = ColisStatus.SUR_PAD
    await log_scan(db, colis, ScanType.DEPOT_PAD, current_user.id, pad_tir_id=pad.id)
    await db.commit()

    return {
        "status": "ok",
        "numero": colis.numero,
        "pad": {"id": str(pad.id), "code": pad.code, "nom": pad.nom},
    }


@router.post("/commandes/{commande_id}/depose-pad")
async def depose_pad_commande(
    commande_id: UUID,
    body: DeposePadRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Magasinier stages ALL parcels of an order onto a single pad at once.

    Used by the batch workflow: the magasinier scans every parcel of an order
    on his cart, then assigns the whole order to one pad de tir.
    """
    if current_user.role.value not in ("magasinier", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    pad_result = await db.execute(select(PadTir).where(PadTir.id == body.pad_tir_id))
    pad = pad_result.scalar_one_or_none()
    if not pad:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pad de tir introuvable")
    if not pad.actif:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Pad {pad.code} inactif",
        )

    colis_list = await get_commande_colis(db, commande_id)
    if not colis_list:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucun colis pour cette commande",
        )

    commande_result = await db.execute(select(Commande).where(Commande.id == commande_id))
    commande = commande_result.scalar_one_or_none()

    db.info["actor_id"] = str(current_user.id)
    deposes: list[str] = []
    ignores: list[str] = []
    for colis in colis_list:
        if colis.statut in (ColisStatus.ETIQUETE, ColisStatus.SUR_PAD):
            colis.pad_tir_id = pad.id
            colis.statut = ColisStatus.SUR_PAD
            await log_scan(db, colis, ScanType.DEPOT_PAD, current_user.id, pad_tir_id=pad.id)
            deposes.append(colis.numero)
        else:
            ignores.append(colis.numero)
    await db.commit()

    return {
        "status": "ok",
        "commande_ref": commande.reference_id if commande else None,
        "pad": {"id": str(pad.id), "code": pad.code, "nom": pad.nom},
        "nb_colis": len(colis_list),
        "deposes": deposes,
        "ignores": ignores,
    }


@router.post("/commandes/{commande_id}/zone-expedition")
async def deposer_zone_expedition(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Magasinier : déplace tous les cartons d'une commande vers la zone d'expédition.

    Pas de choix de pad — le magasinier ne fait que déposer la commande sur la
    zone de chargement. Les colis passent au statut SUR_PAD (prêts à expédier).
    """
    if current_user.role.value not in ("magasinier", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    colis_list = await get_commande_colis(db, commande_id)
    if not colis_list:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucun colis pour cette commande",
        )

    commande_result = await db.execute(select(Commande).where(Commande.id == commande_id))
    commande = commande_result.scalar_one_or_none()

    db.info["actor_id"] = str(current_user.id)
    deposes: list[str] = []
    for colis in colis_list:
        if colis.statut in (ColisStatus.ETIQUETE, ColisStatus.SUR_PAD):
            colis.pad_tir_id = None
            colis.statut = ColisStatus.SUR_PAD
            await log_scan(db, colis, ScanType.DEPOT_PAD, current_user.id)
            deposes.append(colis.numero)
    await db.commit()

    return {
        "status": "ok",
        "commande_ref": commande.reference_id if commande else None,
        "nb_colis": len(colis_list),
        "deposes": deposes,
    }


@router.get("/zone-expedition")
async def list_zone_expedition(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Commandes actuellement en zone d'expédition (colis SUR_PAD), groupées."""
    if current_user.role.value not in (
        "magasinier",
        "livreur",
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    staged_result = await db.execute(
        select(Colis, Commande, PadTir)
        .join(Commande, Colis.commande_id == Commande.id)
        .outerjoin(PadTir, Colis.pad_tir_id == PadTir.id)
        .where(Colis.statut == ColisStatus.SUR_PAD)
    )
    rows = staged_result.all()

    totals_result = await db.execute(
        select(Colis.commande_id, func.count()).group_by(Colis.commande_id)
    )
    totals_map = {row[0]: row[1] for row in totals_result.all()}

    pharm_ids = {row.Commande.pharmacien_id for row in rows}
    users_map: dict[UUID, User] = {}
    if pharm_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharm_ids)))
        users_map = {u.id: u for u in users_result.scalars().all()}

    by_commande: dict[UUID, dict] = {}
    for row in rows:
        commande = row.Commande
        entry = by_commande.setdefault(
            commande.id,
            {
                "commande_id": str(commande.id),
                "commande_ref": commande.reference_id,
                "pharmacien_nom": (
                    users_map[commande.pharmacien_id].nom
                    if commande.pharmacien_id in users_map
                    else "—"
                ),
                "poses": 0,
                "total": totals_map.get(commande.id, 0),
                "zone": None,
            },
        )
        entry["poses"] += 1
        if row.PadTir is not None:
            entry["zone"] = {"code": row.PadTir.code, "nom": row.PadTir.nom}

    items = sorted(by_commande.values(), key=lambda c: c["commande_ref"])
    return {"commandes": items, "total": len(items)}


@router.post("/colis/{numero}/scan-chargement")
async def scan_chargement(
    numero: str,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> ScanChargementResponse:
    """Livreur scans a parcel while loading the truck (real-time progress)."""
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    colis = await _get_colis_or_404(db, numero)
    commande = colis.commande
    await _require_chargement_access(db, current_user, commande)

    # Le livreur contrôle les cartons en les scannant. La commande doit être prête
    # (PRETE) ; on tolère EN_ROUTE pour les re-scans après passage en livraison.
    if commande.statut not in (OrderStatus.PRETE, OrderStatus.EN_ROUTE):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Commande {commande.reference_id} non prête ({commande.statut.value})",
        )

    deja_scanne = colis.statut in (ColisStatus.CHARGE, ColisStatus.LIVRE)
    if not deja_scanne:
        if colis.statut not in (ColisStatus.ETIQUETE, ColisStatus.SUR_PAD):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Colis {colis.numero} est {colis.statut.value} — chargement impossible",
            )
        db.info["actor_id"] = str(current_user.id)
        colis.statut = ColisStatus.CHARGE
        await log_scan(db, colis, ScanType.CHARGEMENT, current_user.id)

    counts = await db.execute(
        select(
            func.count(),
            func.count().filter(Colis.statut.in_([ColisStatus.CHARGE, ColisStatus.LIVRE])),
        )
        .select_from(Colis)
        .where(Colis.commande_id == commande.id)
    )
    total, charges = counts.one()
    commande_complete = total > 0 and charges == total

    if not deja_scanne and commande_complete:
        # Tous les cartons scannés → la commande passe « en livraison ».
        if commande.statut == OrderStatus.PRETE:
            from app.commandes.service import transition_order

            await transition_order(db, commande.id, OrderStatus.EN_ROUTE)
        db.add(
            Notification(
                id=uuid4(),
                user_id=commande.pharmacien_id,
                commande_id=commande.id,
                type="commande_en_livraison",
                message=f"Commande {commande.reference_id} chargée — en cours de livraison",
            )
        )

    if not deja_scanne:
        await db.commit()

    return ScanChargementResponse(
        numero=colis.numero,
        commande_ref=commande.reference_id,
        charges=charges,
        total=total,
        commande_complete=commande_complete,
        deja_scanne=deja_scanne,
    )


@router.post("/colis/{numero}/scan-livraison")
async def scan_livraison(
    numero: str,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> ScanLivraisonResponse:
    """Livreur re-scans a parcel at the pharmacy before the reception signature."""
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    colis = await _get_colis_or_404(db, numero)
    commande = colis.commande
    await _require_chargement_access(db, current_user, commande)

    if commande.statut != OrderStatus.EN_ROUTE:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Commande {commande.reference_id} non en route ({commande.statut.value})",
        )

    deja_scanne = colis.statut == ColisStatus.LIVRE
    if not deja_scanne:
        if colis.statut != ColisStatus.CHARGE:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Colis {colis.numero} est {colis.statut.value} — livraison impossible",
            )
        db.info["actor_id"] = str(current_user.id)
        colis.statut = ColisStatus.LIVRE
        await log_scan(db, colis, ScanType.LIVRAISON, current_user.id)
        await db.commit()

    counts = await db.execute(
        select(
            func.count(),
            func.count().filter(Colis.statut == ColisStatus.LIVRE),
        )
        .select_from(Colis)
        .where(Colis.commande_id == commande.id)
    )
    total, livres = counts.one()

    return ScanLivraisonResponse(
        numero=colis.numero,
        commande_ref=commande.reference_id,
        livres=livres,
        total=total,
        commande_complete=total > 0 and livres == total,
        deja_scanne=deja_scanne,
    )


@router.get("/feuilles-route/{feuille_id}/chargement")
async def get_chargement_state(
    feuille_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> ChargementStateResponse:
    """Real-time truck content for a route sheet (per order, per parcel)."""
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    feuille = await get_route_sheet(db, feuille_id)
    if not feuille:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route sheet not found")
    if current_user.role.value == "livreur" and feuille.livreur_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    state = await chargement_state(db, feuille)
    return ChargementStateResponse(**state)


@router.get("/pads")
async def list_pads(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """List pads de tir with their current occupation (staged parcels per order)."""
    if current_user.role.value not in (
        "magasinier",
        "livreur",
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    pads_result = await db.execute(select(PadTir).order_by(PadTir.code.asc()))
    pads = list(pads_result.scalars().all())

    staged_result = await db.execute(
        select(Colis, Commande)
        .join(Commande, Colis.commande_id == Commande.id)
        .where(Colis.statut == ColisStatus.SUR_PAD, Colis.pad_tir_id.is_not(None))
    )
    rows = staged_result.all()

    totals_result = await db.execute(
        select(Colis.commande_id, func.count()).group_by(Colis.commande_id)
    )
    totals_map = {row[0]: row[1] for row in totals_result.all()}

    pharm_ids = {row.Commande.pharmacien_id for row in rows}
    users_map: dict[UUID, User] = {}
    if pharm_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharm_ids)))
        users_map = {u.id: u for u in users_result.scalars().all()}

    # pad_id -> commande_id -> {ref, pharmacien, poses}
    occupation: dict[UUID, dict[UUID, dict]] = {}
    for row in rows:
        colis, commande = row.Colis, row.Commande
        pad_orders = occupation.setdefault(colis.pad_tir_id, {})
        entry = pad_orders.setdefault(
            commande.id,
            {
                "commande_ref": commande.reference_id,
                "pharmacien_nom": (
                    users_map[commande.pharmacien_id].nom
                    if commande.pharmacien_id in users_map
                    else "—"
                ),
                "poses": 0,
                "total": totals_map.get(commande.id, 0),
            },
        )
        entry["poses"] += 1

    items = []
    for pad in pads:
        pad_orders = occupation.get(pad.id, {})
        items.append(
            PadOccupationResponse(
                id=str(pad.id),
                code=pad.code,
                nom=pad.nom,
                actif=pad.actif,
                nb_colis=sum(o["poses"] for o in pad_orders.values()),
                commandes=sorted(
                    (
                        {
                            "commande_ref": o["commande_ref"],
                            "pharmacien_nom": o["pharmacien_nom"],
                            "poses": o["poses"],
                            "total": o["total"],
                        }
                        for o in pad_orders.values()
                    ),
                    key=lambda o: o["commande_ref"],
                ),
            )
        )

    return {"pads": items, "total": len(items)}


@router.post("/pads", status_code=status.HTTP_201_CREATED)
async def create_pad(
    body: CreatePadRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> PadTirResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    existing = await db.execute(select(PadTir).where(PadTir.code == body.code))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Le pad {body.code} existe déjà",
        )

    db.info["actor_id"] = str(current_user.id)
    pad = PadTir(id=uuid4(), code=body.code, nom=body.nom, actif=True)
    db.add(pad)
    await db.commit()
    await db.refresh(pad)
    return _pad_response(pad)


@router.patch("/pads/{pad_id}")
async def update_pad(
    pad_id: UUID,
    body: UpdatePadRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> PadTirResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    result = await db.execute(select(PadTir).where(PadTir.id == pad_id))
    pad = result.scalar_one_or_none()
    if not pad:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pad de tir introuvable")

    db.info["actor_id"] = str(current_user.id)
    if body.code is not None:
        pad.code = body.code
    if body.nom is not None:
        pad.nom = body.nom
    if body.actif is not None:
        pad.actif = body.actif
    await db.commit()
    await db.refresh(pad)
    return _pad_response(pad)


@router.get("/commandes/{commande_id}/colis")
async def list_commande_colis(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """List the tracked parcels of an order (numero, statut, pad)."""
    if current_user.role.value not in (
        "magasinier",
        "livreur",
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    colis_list = await get_commande_colis(db, commande_id)
    pad_ids = {k.pad_tir_id for k in colis_list if k.pad_tir_id}
    pads_map: dict[UUID, PadTir] = {}
    if pad_ids:
        pads_result = await db.execute(select(PadTir).where(PadTir.id.in_(pad_ids)))
        pads_map = {p.id: p for p in pads_result.scalars().all()}

    return {
        "colis": [
            {
                "id": str(k.id),
                "numero": k.numero,
                "index_colis": k.index_colis,
                "statut": k.statut.value,
                "pad": _pad_response(pads_map.get(k.pad_tir_id)) if k.pad_tir_id else None,
            }
            for k in colis_list
        ],
        "total": len(colis_list),
    }


@router.get("/commandes/{commande_id}/etiquettes")
async def download_etiquettes(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> FileResponse:
    """Parcel labels PDF (one A6 page per parcel, QR = numero only).

    Clean endpoint: S4 (facturier) will call it through the API later.
    """
    if current_user.role.value not in ("controleur", "operatrice", "admin", "facturier"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    from app.commandes.service import get_order_with_lines
    from app.documents.pdf_generator import generate_etiquettes_pdf

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    colis_list = await get_commande_colis(db, commande_id)
    if not colis_list:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucun colis pour cette commande — valider le contrôle d'abord",
        )

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    nb = len(colis_list)
    colis_data = []
    for colis in colis_list:
        colis.commande = commande
        contenu, detaille = colis_contenu(colis)
        colis_data.append(
            {
                "numero": colis.numero,
                "index": colis.index_colis,
                "total": nb,
                "contenu": [f"{c['designation']} × {c['quantite']}" for c in contenu],
                "contenu_detaille": detaille,
            }
        )

    path = generate_etiquettes_pdf(
        commande_ref=commande.reference_id,
        client_nom=pharmacien.nom if pharmacien else "—",
        client_adresse=pharmacien.adresse if pharmacien else None,
        client_secteur=pharmacien.secteur if pharmacien else None,
        date_str=commande.created_at.date().isoformat(),
        colis=colis_data,
        controleur_nom=commande.visa_controleur,
    )

    return FileResponse(
        path=str(path),
        media_type="application/pdf",
        filename=f"etiquettes_{commande.reference_id}.pdf",
    )


class _RepartitionResponse(BaseModel):
    status: str
    nb_colis: int


@router.put("/commandes/{commande_id}/repartition")
async def set_repartition(
    commande_id: UUID,
    body: RepartitionRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> _RepartitionResponse:
    """Optional content split: which order lines go in which parcel."""
    if current_user.role.value not in ("controleur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    from app.commandes.service import get_order_with_lines

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    await validate_repartition(db, commande, body.repartition)

    db.info["actor_id"] = str(current_user.id)

    # Replace the existing split entirely
    colis_list = await get_commande_colis(db, commande_id)
    for colis in colis_list:
        colis.lignes.clear()
    await db.flush()

    colis_by_id = {k.id: k for k in colis_list}
    for item in body.repartition:
        colis = colis_by_id[item.colis_id]
        for ligne_item in item.lignes:
            colis.lignes.append(
                ColisLigne(
                    id=uuid4(),
                    colis_id=colis.id,
                    ligne_commande_id=ligne_item.ligne_id,
                    quantite=ligne_item.quantite,
                )
            )
    await db.commit()

    return _RepartitionResponse(status="ok", nb_colis=len(colis_list))
