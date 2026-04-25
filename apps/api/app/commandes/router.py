import base64
import logging
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from pydantic import BaseModel, Field
from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import load_only, selectinload

from app.arrivages.dlc import format_dlc, resolve_dlc
from app.auth.dependencies import CurrentUser
from app.commandes.schemas import (
    AddLineRequest,
    AssignCamionRequest,
    CaddiePoolResponse,
    CreateOrderRequest,
    EditLineRequest,
    OrderDetailResponse,
    OrderResponse,
    StartPreparationRequest,
    UpdateCommentRequest,
)
from app.commandes.service import (
    claim_caddie_for_preparation,
    create_order,
    get_order_with_lines,
    release_caddie_on_finalize,
    transition_order,
)
from app.db.session import get_db
from app.documents.service import (
    get_or_create_route_sheet,
    get_route_sheet,
    regenerate_facture_pdf,
)
from app.models.caddie_pool import CaddiePool
from app.models.camion import Camion
from app.models.commande import Commande, LigneCommande, OrderStatus
from app.models.document import Facture, FeuilleDeRoute
from app.models.medicament import Medicament
from app.models.user import User

# Statuses visible per workflow role
_PREPARATEUR_STATUSES = [
    OrderStatus.EN_PREPARATION,
    OrderStatus.PRELEVEE_PARTIELLEMENT,
    OrderStatus.EN_VERIFICATION,
]
_CONTROLEUR_STATUSES = [
    OrderStatus.ACCEPTEE,
    OrderStatus.EN_VERIFICATION,
    OrderStatus.PRETE,
]

router = APIRouter()
logger = logging.getLogger(__name__)


def _enrich_order(
    commande: Commande,
    user: User | None,
    camion: Camion | None,
    *,
    viewer_role: str = "",
    preparateur: User | None = None,
) -> dict:
    """Build response dict with pharmacien, camion, preparateur + caddies.

    pharmacien_email is only exposed to operatrice/admin.
    """
    data = {
        "id": str(commande.id),
        "reference_id": commande.reference_id,
        "statut": commande.statut.value if hasattr(commande.statut, "value") else commande.statut,
        "montant_total": float(commande.montant_total),
        "pharmacien_id": str(commande.pharmacien_id),
        "operatrice_id": str(commande.operatrice_id) if commande.operatrice_id else None,
        "preparateur_id": str(commande.preparateur_id) if commande.preparateur_id else None,
        "preparateur_nom": preparateur.nom if preparateur else None,
        "commercial": commande.commercial,
        "created_at": commande.created_at,
        "date_validation": commande.date_validation,
        "camion_id": str(commande.camion_id) if commande.camion_id else None,
        "camion_nom": camion.nom if camion else None,
        "pharmacien_nom": user.nom if user else None,
        "pharmacien_email": (
            user.email if user and viewer_role in ("operatrice", "admin") else None
        ),
        "operatrice_comment": commande.operatrice_comment,
        "caddie_pool": None,
    }
    pool = commande.__dict__.get("caddie_pool")
    if pool is not None:
        data["caddie_pool"] = {
            "id": str(pool.id),
            "numero": pool.numero,
            "is_available": pool.is_available,
            "current_commande_ref": commande.reference_id,
        }
    if "lignes" in commande.__dict__ and commande.__dict__["lignes"]:
        data["lignes"] = [
            {
                "id": str(ligne.id),
                "medicament_id": str(ligne.medicament_id),
                "designation": ligne.designation,
                "qte_demandee": ligne.qte_demandee,
                "prix_unitaire": float(ligne.prix_unitaire),
                "remise_pct": float(ligne.remise_pct),
                "n_lot": ligne.n_lot,
            }
            for ligne in commande.lignes
        ]
    return data


async def _require_delivery_access(
    db: AsyncSession,
    current_user: User,
    commande: Commande,
) -> None:
    if current_user.role.value in ("operatrice", "admin"):
        return

    if current_user.role.value != "livreur":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    if not commande.feuille_route_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Order is not assigned to a route sheet",
        )

    feuille = await get_route_sheet(db, commande.feuille_route_id)
    if not feuille or feuille.livreur_id != current_user.id or feuille.date != date.today():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Order does not belong to your route sheet",
        )


@router.get("/pharmaciens")
async def list_pharmaciens(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Return all active pharmaciens — accessible to operatrice and admin."""
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    from app.models.user import UserRole

    result = await db.execute(
        select(User)
        .where(User.role == UserRole.PHARMACIEN, User.is_active.is_(True))
        .order_by(User.nom)
    )
    pharmaciens = result.scalars().all()
    return {
        "pharmaciens": [
            {
                "id": str(u.id),
                "nom": u.nom,
                "email": u.email,
                "adresse": u.adresse,
                "secteur": u.secteur,
                "telephone": u.telephone,
            }
            for u in pharmaciens
        ]
    }


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create(
    body: CreateOrderRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    role = current_user.role.value

    if role == "operatrice":
        if not body.pharmacien_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="pharmacien_id requis pour une operatrice",
            )
        pharm_result = await db.execute(select(User).where(User.id == body.pharmacien_id))
        pharmacien = pharm_result.scalar_one_or_none()
        if not pharmacien or pharmacien.role.value != "pharmacien":
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pharmacien introuvable")
        owner_id = body.pharmacien_id
    elif role == "pharmacien":
        owner_id = current_user.id
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    db.info["actor_id"] = str(current_user.id)
    commande = await create_order(db, owner_id, body)
    await db.commit()
    await db.refresh(commande, ["lignes"])
    pharm_result = await db.execute(select(User).where(User.id == owner_id))
    pharmacien = pharm_result.scalar_one_or_none()
    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=role,
    )
    return OrderDetailResponse(**data)


@router.get("/")
async def list_orders(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    statut: str | None = Query(None),  # noqa: B008
    date_from: date | None = Query(None),  # noqa: B008
    date_to: date | None = Query(None),  # noqa: B008
    pharmacien_id: UUID | None = Query(None),  # noqa: B008
    limit: int = Query(20, ge=1, le=100),  # noqa: B008
    offset: int = Query(0, ge=0),  # noqa: B008
) -> dict:
    query = select(Commande)
    count_query = select(func.count()).select_from(Commande)

    role = current_user.role.value

    if role == "pharmacien":
        query = query.where(Commande.pharmacien_id == current_user.id)
        count_query = count_query.where(Commande.pharmacien_id == current_user.id)
    elif role in ("operatrice", "admin"):
        if pharmacien_id:
            query = query.where(Commande.pharmacien_id == pharmacien_id)
            count_query = count_query.where(Commande.pharmacien_id == pharmacien_id)
    elif role == "preparateur":
        # Preparateurs see unclaimed ACCEPTEE + their own in-progress + EN_VERIFICATION
        # (en_verification is unclaimed because controleur takes over — keep as-is)
        from sqlalchemy import and_, or_

        prep_filter = or_(
            and_(
                Commande.statut == OrderStatus.ACCEPTEE,
                Commande.preparateur_id.is_(None),
            ),
            and_(
                Commande.statut.in_(
                    [
                        OrderStatus.EN_PREPARATION,
                        OrderStatus.PRELEVEE_PARTIELLEMENT,
                    ]
                ),
                Commande.preparateur_id == current_user.id,
            ),
            Commande.statut == OrderStatus.EN_VERIFICATION,
        )
        query = query.where(prep_filter)
        count_query = count_query.where(prep_filter)
    elif role == "controleur":
        query = query.where(Commande.statut.in_(_CONTROLEUR_STATUSES))
        count_query = count_query.where(Commande.statut.in_(_CONTROLEUR_STATUSES))
    elif role == "livreur":
        today_sheets = select(FeuilleDeRoute.id).where(
            FeuilleDeRoute.livreur_id == current_user.id,
            FeuilleDeRoute.date == date.today(),
        )
        query = query.where(Commande.feuille_route_id.in_(today_sheets))
        count_query = count_query.where(Commande.feuille_route_id.in_(today_sheets))
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    if statut:
        status_enum = OrderStatus(statut)
        query = query.where(Commande.statut == status_enum)
        count_query = count_query.where(Commande.statut == status_enum)

    if date_from:
        query = query.where(func.date(Commande.created_at) >= date_from)
        count_query = count_query.where(func.date(Commande.created_at) >= date_from)

    if date_to:
        query = query.where(func.date(Commande.created_at) <= date_to)
        count_query = count_query.where(func.date(Commande.created_at) <= date_to)

    query = (
        query.order_by(Commande.created_at.desc())
        .limit(limit)
        .offset(offset)
        .options(selectinload(Commande.caddie_pool))
    )

    result = await db.execute(query)
    commandes = result.scalars().all()

    count_result = await db.execute(count_query)
    total = count_result.scalar()

    # Batch-load pharmacien, preparateur and camion info
    pharm_ids = {c.pharmacien_id for c in commandes}
    prep_ids = {c.preparateur_id for c in commandes if c.preparateur_id}
    camion_ids = {c.camion_id for c in commandes if c.camion_id}

    user_ids = pharm_ids | prep_ids
    users_map: dict[UUID, User] = {}
    if user_ids:
        users_result = await db.execute(select(User).where(User.id.in_(user_ids)))
        users_map = {u.id: u for u in users_result.scalars().all()}

    camions_map: dict[UUID, Camion] = {}
    if camion_ids:
        camions_result = await db.execute(select(Camion).where(Camion.id.in_(camion_ids)))
        camions_map = {c.id: c for c in camions_result.scalars().all()}

    enriched = [
        OrderResponse(
            **_enrich_order(
                c,
                users_map.get(c.pharmacien_id),
                camions_map.get(c.camion_id) if c.camion_id else None,
                viewer_role=current_user.role.value,
                preparateur=users_map.get(c.preparateur_id) if c.preparateur_id else None,
            )
        )
        for c in commandes
    ]

    return {
        "commandes": enriched,
        "total": total,
        "limit": limit,
        "offset": offset,
    }


@router.get("/stats")
async def order_stats(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    period: str = "month",
) -> dict:
    if current_user.role.value not in ("operatrice", "admin", "pharmacien"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    now = datetime.now(UTC)
    periods = {"week": 7, "quarter": 90, "year": 365}
    since = now - timedelta(days=periods.get(period, 30))

    base_filter = [Commande.created_at >= since]
    if current_user.role.value == "pharmacien":
        base_filter.append(Commande.pharmacien_id == current_user.id)

    # Aggregations in SQL
    agg_q = select(
        func.count().label("order_count"),
        func.coalesce(func.sum(Commande.montant_total), 0).label("total_revenue"),
        func.sum(case((Commande.statut == OrderStatus.LIVREE, 1), else_=0)).label("delivered"),
    ).where(*base_filter)
    agg = (await db.execute(agg_q)).one()

    order_count = agg.order_count
    total_revenue = float(agg.total_revenue)
    avg_order_value = total_revenue / order_count if order_count > 0 else 0
    delivery_rate = (int(agg.delivered) / order_count * 100) if order_count > 0 else 0

    # Status breakdown in SQL
    breakdown_q = (
        select(Commande.statut, func.count().label("cnt"))
        .where(*base_filter)
        .group_by(Commande.statut)
    )
    breakdown_rows = (await db.execute(breakdown_q)).all()
    status_breakdown = {
        (r.statut.value if hasattr(r.statut, "value") else r.statut): r.cnt for r in breakdown_rows
    }

    # Top products in SQL
    from app.models.commande import LigneCommande

    lines_q = (
        select(
            LigneCommande.designation,
            func.sum(LigneCommande.qte_demandee).label("total_qty"),
            func.sum(LigneCommande.qte_demandee * LigneCommande.prix_unitaire).label(
                "total_amount"
            ),
        )
        .join(Commande, LigneCommande.commande_id == Commande.id)
        .where(*base_filter)
        .group_by(LigneCommande.designation)
        .order_by(func.sum(LigneCommande.qte_demandee).desc())
        .limit(10)
    )
    lines_result = await db.execute(lines_q)
    top_products = [
        {
            "designation": r.designation,
            "total_qty": int(r.total_qty),
            "total_amount": float(r.total_amount),
        }
        for r in lines_result.all()
    ]

    # Previous period comparison (M-1)
    days = periods.get(period, 30)
    prev_end = since
    prev_start = prev_end - timedelta(days=days)

    prev_filter = [
        Commande.created_at >= prev_start,
        Commande.created_at < prev_end,
    ]
    if current_user.role.value == "pharmacien":
        prev_filter.append(
            Commande.pharmacien_id == current_user.id,
        )

    prev_q = select(
        func.count().label("order_count"),
        func.coalesce(
            func.sum(Commande.montant_total),
            0,
        ).label("total_revenue"),
    ).where(*prev_filter)
    prev = (await db.execute(prev_q)).one()
    prev_revenue = float(prev.total_revenue)
    prev_orders = prev.order_count

    def pct_change(current: float, previous: float) -> float | None:
        if previous == 0:
            return None
        return round((current - previous) / previous * 100, 1)

    return {
        "total_revenue": round(total_revenue, 2),
        "order_count": order_count,
        "avg_order_value": round(avg_order_value, 2),
        "delivery_rate": round(delivery_rate, 1),
        "status_breakdown": status_breakdown,
        "top_products": top_products,
        "previous_period": {
            "total_revenue": round(prev_revenue, 2),
            "order_count": prev_orders,
        },
        "evolution": {
            "revenue_pct": pct_change(total_revenue, prev_revenue),
            "orders_pct": pct_change(order_count, prev_orders),
        },
    }


@router.get("/{commande_id}")
async def get_order(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    role = current_user.role.value
    if role == "pharmacien":
        if commande.pharmacien_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")
    elif role in ("operatrice", "admin"):
        pass
    elif role == "preparateur":
        if commande.statut not in _PREPARATEUR_STATUSES:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    elif role == "controleur":
        if commande.statut not in _CONTROLEUR_STATUSES:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    elif role == "livreur":
        if not commande.feuille_route_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
        feuille = await get_route_sheet(db, commande.feuille_route_id)
        if not feuille or feuille.livreur_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    # Load pharmacien and camion
    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    camion = None
    if commande.camion_id:
        camion_result = await db.execute(select(Camion).where(Camion.id == commande.camion_id))
        camion = camion_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        camion,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/accept")
async def accept_order(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.ACCEPTEE, current_user.id)
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/reject")
async def reject_order(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.ANNULEE)
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/cancel")
async def cancel_order(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value != "pharmacien":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Pharmacien only")

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    if commande.pharmacien_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.ANNULEE)
    await db.commit()
    await db.refresh(commande, ["lignes"])
    data = _enrich_order(
        commande,
        current_user,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


_OPERATRICE_EDITABLE_STATUSES = {OrderStatus.CREEE, OrderStatus.ACCEPTEE}


def _require_operatrice_or_admin(current_user: User) -> None:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operatrice/admin only",
        )


def _require_editable(commande: Commande) -> None:
    if commande.statut not in _OPERATRICE_EDITABLE_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Commande non modifiable dans son statut actuel "
                f"({commande.statut.value}). Edition autorisee en CREEE ou ACCEPTEE uniquement."
            ),
        )


async def _load_facture_for_commande(db: AsyncSession, commande_id: UUID) -> Facture | None:
    result = await db.execute(select(Facture).where(Facture.commande_id == commande_id))
    return result.scalar_one_or_none()


async def _finalize_operatrice_edit(
    db: AsyncSession,
    commande: Commande,
    current_user: User,
) -> OrderDetailResponse:
    """Recompute montant_total, regen facture if ACCEPTEE, refresh + enrich."""
    commande.montant_total = sum(
        (ligne.prix_unitaire * ligne.qte_demandee for ligne in commande.lignes),
        start=Decimal("0"),
    )
    await db.flush()

    if commande.statut == OrderStatus.ACCEPTEE:
        facture = await _load_facture_for_commande(db, commande.id)
        if facture is not None:
            await regenerate_facture_pdf(db, facture)

    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/comment")
async def update_operatrice_comment(
    commande_id: UUID,
    body: UpdateCommentRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    _require_operatrice_or_admin(current_user)
    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    db.info["actor_id"] = str(current_user.id)
    commande.operatrice_comment = body.comment
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/lines/{ligne_id}")
async def edit_operatrice_line(
    commande_id: UUID,
    ligne_id: UUID,
    body: EditLineRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    _require_operatrice_or_admin(current_user)

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    _require_editable(commande)

    ligne = next((ln for ln in commande.lignes if ln.id == ligne_id), None)
    if ligne is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Line not found")

    db.info["actor_id"] = str(current_user.id)
    delta = body.qte_demandee - ligne.qte_demandee

    if commande.statut == OrderStatus.ACCEPTEE and delta != 0:
        med_result = await db.execute(
            select(Medicament).where(Medicament.id == ligne.medicament_id)
        )
        med = med_result.scalar_one_or_none()
        if med is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Medicament not found"
            )
        if delta > 0 and med.stock_quantity < delta:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    f"Stock insuffisant pour {med.designation} "
                    f"(stock={med.stock_quantity}, delta demande={delta})"
                ),
            )
        med.stock_quantity -= delta

    ligne.qte_demandee = body.qte_demandee
    return await _finalize_operatrice_edit(db, commande, current_user)


@router.post("/{commande_id}/lines")
async def add_operatrice_line(
    commande_id: UUID,
    body: AddLineRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    _require_operatrice_or_admin(current_user)

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    _require_editable(commande)

    med_result = await db.execute(select(Medicament).where(Medicament.id == body.medicament_id))
    med = med_result.scalar_one_or_none()
    if med is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medicament not found")

    db.info["actor_id"] = str(current_user.id)

    if commande.statut == OrderStatus.ACCEPTEE:
        if med.stock_quantity < body.qte_demandee:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    f"Stock insuffisant pour {med.designation} "
                    f"(stock={med.stock_quantity}, demande={body.qte_demandee})"
                ),
            )
        med.stock_quantity -= body.qte_demandee

    ligne = LigneCommande(
        id=uuid4(),
        commande_id=commande.id,
        medicament_id=body.medicament_id,
        designation=med.designation,
        qte_demandee=body.qte_demandee,
        prix_unitaire=med.ppa,
    )
    commande.lignes.append(ligne)
    return await _finalize_operatrice_edit(db, commande, current_user)


@router.delete("/{commande_id}/lines/{ligne_id}")
async def delete_operatrice_line(
    commande_id: UUID,
    ligne_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    _require_operatrice_or_admin(current_user)

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    _require_editable(commande)

    if len(commande.lignes) <= 1:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Derniere ligne : utilisez /reject pour annuler la commande",
        )

    ligne = next((ln for ln in commande.lignes if ln.id == ligne_id), None)
    if ligne is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Line not found")

    db.info["actor_id"] = str(current_user.id)

    if commande.statut == OrderStatus.ACCEPTEE:
        med_result = await db.execute(
            select(Medicament).where(Medicament.id == ligne.medicament_id)
        )
        med = med_result.scalar_one_or_none()
        if med is not None:
            med.stock_quantity += ligne.qte_demandee

    commande.lignes.remove(ligne)
    await db.delete(ligne)
    return await _finalize_operatrice_edit(db, commande, current_user)


@router.patch("/{commande_id}/assign-camion")
async def assign_camion(
    commande_id: UUID,
    body: AssignCamionRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in (
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    if commande.statut not in (
        OrderStatus.ACCEPTEE,
        OrderStatus.EN_VERIFICATION,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Only accepted orders can be assigned to a truck",
        )

    # Verify camion exists
    camion_result = await db.execute(select(Camion).where(Camion.id == body.camion_id))
    camion = camion_result.scalar_one_or_none()
    if not camion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camion not found")

    db.info["actor_id"] = str(current_user.id)
    today = date.today()
    try:
        commande.camion_id = body.camion_id
        # Ensure the order is linked to today's route sheet for the selected truck.
        feuille = await get_or_create_route_sheet(db, body.camion_id, today)
        commande.feuille_route_id = feuille.id
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception(
            "Failed to assign camion=%s to commande=%s by actor=%s",
            body.camion_id,
            commande_id,
            current_user.id,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to assign order to route sheet",
        ) from exc

    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        camion,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/start-preparation")
async def start_preparation(
    commande_id: UUID,
    body: StartPreparationRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("preparateur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Preparateur/operatrice/admin only",
        )

    db.info["actor_id"] = str(current_user.id)
    commande = await claim_caddie_for_preparation(
        db=db,
        commande_id=commande_id,
        caddie_pool_id=body.caddie_pool_id,
        preparateur_id=current_user.id,
    )
    await db.commit()
    await db.refresh(commande, ["lignes", "caddie_pool"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/mark-verified")
async def mark_verified(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("preparateur", "controleur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Preparateur/controleur/operatrice/admin only",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if commande.statut not in (OrderStatus.EN_PREPARATION, OrderStatus.PRELEVEE_PARTIELLEMENT):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Cannot validate preparation from {commande.statut.value}",
        )
    if commande.nb_colis is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Preparation must be finalized before verification",
        )
    if any(not ligne.verifie for ligne in commande.lignes):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="All lines must be verified before moving to verification",
        )

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.EN_VERIFICATION)
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/mark-ready")
async def mark_ready(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("controleur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Controleur/operatrice/admin only",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if commande.statut != OrderStatus.EN_VERIFICATION:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Cannot validate from {commande.statut.value}",
        )

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.PRETE)
    commande.visa_controleur = current_user.nom
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/start-delivery")
async def start_delivery(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Livreur/operatrice/admin only",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    await _require_delivery_access(db, current_user, commande)
    if not commande.feuille_route_id:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Route sheet missing")

    feuille = await get_route_sheet(db, commande.feuille_route_id)
    if not feuille or not feuille.chargement_valide:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Loading has not been validated",
        )
    if not feuille.signature_expedition or not feuille.signature_chauffeur:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Required route signatures are missing",
        )

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.EN_ROUTE)
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


@router.patch("/{commande_id}/mark-delivered")
async def mark_delivered(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    await _require_delivery_access(db, current_user, commande)

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.LIVREE)
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


class UpdateLigneRequest(BaseModel):
    qte_prelevee: int | None = Field(default=None, ge=0)
    verifie: bool | None = None
    dlc: date | None = None


@router.get("/{commande_id}/lignes")
async def get_lignes(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Get order lines with preparation details."""
    if current_user.role.value not in (
        "preparateur",
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )
    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )
    return {
        "lignes": [
            {
                "id": str(ln.id),
                "medicament_id": str(ln.medicament_id),
                "designation": ln.designation,
                "qte_demandee": ln.qte_demandee,
                "qte_prelevee": ln.qte_prelevee,
                "prix_unitaire": float(ln.prix_unitaire),
                "remise_pct": float(ln.remise_pct),
                "n_lot": ln.n_lot,
                "dlc": ln.dlc.isoformat() if ln.dlc else None,
                "verifie": ln.verifie,
            }
            for ln in commande.lignes
        ],
        "nb_colis": commande.nb_colis,
        "visa_preparateur": commande.visa_preparateur,
        "visa_controleur": commande.visa_controleur,
    }


@router.patch("/{commande_id}/update-ligne/{ligne_id}")
async def update_ligne(
    commande_id: UUID,
    ligne_id: UUID,
    body: UpdateLigneRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Update a line's picked quantity and verified status."""
    if current_user.role.value not in (
        "preparateur",
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    # Verify order is in preparation
    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )
    if commande.statut not in (
        OrderStatus.EN_PREPARATION,
        OrderStatus.PRELEVEE_PARTIELLEMENT,
        OrderStatus.EN_VERIFICATION,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Order not in preparation or verification",
        )

    from app.models.commande import LigneCommande

    result = await db.execute(
        select(LigneCommande)
        .options(
            load_only(
                LigneCommande.id,
                LigneCommande.commande_id,
                LigneCommande.qte_demandee,
                LigneCommande.qte_prelevee,
                LigneCommande.verifie,
                LigneCommande.dlc,
            )
        )
        .where(
            LigneCommande.id == ligne_id,
            LigneCommande.commande_id == commande_id,
        )
    )
    ligne = result.scalar_one_or_none()
    if not ligne:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Line not found",
        )

    if body.qte_prelevee is not None and body.qte_prelevee > ligne.qte_demandee:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="qte_prelevee cannot exceed qte_demandee",
        )

    db.info["actor_id"] = str(current_user.id)
    if body.qte_prelevee is not None:
        ligne.qte_prelevee = body.qte_prelevee
    if body.verifie is not None:
        ligne.verifie = body.verifie
    if body.dlc is not None:
        ligne.dlc = body.dlc
    await db.commit()
    return {"status": "ok"}


# ─── Vignette endpoints (OCR DLC extraction) ────────────────────────────────

from pathlib import Path as _Path  # noqa: E402

_VIGNETTES_ROOT = _Path(__file__).resolve().parents[3] / "storage" / "images" / "vignettes"
_MAX_VIGNETTE_BYTES = 10 * 1024 * 1024  # 10 MiB
_ALLOWED_VIGNETTE_EXT = {".jpg", ".jpeg", ".png", ".webp"}


def _vignette_role_ok(role: str) -> bool:
    return role in ("preparateur", "operatrice", "admin")


def _vignette_status_ok(statut: OrderStatus) -> bool:
    return statut in (OrderStatus.EN_PREPARATION, OrderStatus.PRELEVEE_PARTIELLEMENT)


def _vignette_to_dict(v, designation: str | None = None) -> dict:
    return {
        "id": str(v.id),
        "commande_id": str(v.commande_id),
        "ligne_id": str(v.ligne_id) if v.ligne_id else None,
        "ligne_designation": designation,
        "path": f"images/vignettes/{v.commande_id}/{v.filename}",
        "extracted_dlc": v.extracted_dlc.isoformat() if v.extracted_dlc else None,
        "extracted_code_article": v.extracted_code_article,
        "uploaded_at": v.created_at.isoformat() if v.created_at else None,
    }


@router.post("/{commande_id}/vignettes")
async def upload_vignette(
    commande_id: UUID,
    current_user: CurrentUser,
    file: Annotated[UploadFile, File(...)],
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Upload a single vignette photo, extract DLC, suggest a matching line."""
    from app.models.vignette import Vignette
    from app.ocr.service import (
        OcrConfigurationError,
        OcrUpstreamError,
        extract_vignette_fields,
    )

    if not _vignette_role_ok(current_user.role.value):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Preparateur/operatrice/admin only",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if not _vignette_status_ok(commande.statut):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Vignette upload not allowed from status {commande.statut.value}",
        )

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Empty file")
    if len(image_bytes) > _MAX_VIGNETTE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image exceeds 10 MiB limit",
        )
    content_type = file.content_type or "image/jpeg"
    if not content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported content type: {content_type}",
        )
    ext = _Path(file.filename or "img.jpg").suffix.lower()
    if ext not in _ALLOWED_VIGNETTE_EXT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Allowed: jpg, png, webp",
        )
    if not (
        image_bytes[:8] == b"\x89PNG\r\n\x1a\n"
        or image_bytes[:2] == b"\xff\xd8"
        or image_bytes[:4] == b"RIFF"
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match a valid image format",
        )

    try:
        extraction = await extract_vignette_fields(image_bytes, content_type)
    except OcrConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)
        ) from exc
    except OcrUpstreamError as exc:
        logger.warning("OCR upstream failure on commande=%s: %s", commande_id, exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY, detail=f"OCR service error: {exc}"
        ) from exc

    suggested_ligne_id: UUID | None = None
    if extraction.code_article:
        med_result = await db.execute(
            select(Medicament.id, Medicament.code_article).where(
                Medicament.id.in_([ln.medicament_id for ln in commande.lignes])
            )
        )
        code_by_med: dict[UUID, str] = {row.id: row.code_article for row in med_result}
        target = extraction.code_article.strip().lower()
        for ln in commande.lignes:
            code = code_by_med.get(ln.medicament_id, "")
            if code and code.strip().lower() == target:
                suggested_ligne_id = ln.id
                break

    commande_dir = _VIGNETTES_ROOT / str(commande_id)
    commande_dir.mkdir(parents=True, exist_ok=True)
    vignette_id = uuid4()
    filename = f"{vignette_id}{ext}"
    filepath = commande_dir / filename
    if not filepath.resolve().is_relative_to(_VIGNETTES_ROOT.resolve()):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid path")
    with open(filepath, "wb") as f:
        f.write(image_bytes)

    db.info["actor_id"] = str(current_user.id)
    vignette = Vignette(
        id=vignette_id,
        commande_id=commande_id,
        ligne_id=suggested_ligne_id,
        filename=filename,
        extracted_dlc=extraction.dlc,
        extracted_code_article=extraction.code_article,
        extracted_raw=extraction.raw,
        uploaded_by=current_user.id,
    )
    db.add(vignette)
    await db.commit()
    await db.refresh(vignette)

    designation = None
    if suggested_ligne_id:
        for ln in commande.lignes:
            if ln.id == suggested_ligne_id:
                designation = ln.designation
                break

    result = _vignette_to_dict(vignette, designation)
    result["suggested_ligne_id"] = str(suggested_ligne_id) if suggested_ligne_id else None
    return result


@router.get("/{commande_id}/vignettes")
async def list_vignettes(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    from app.models.vignette import Vignette

    if current_user.role.value not in ("preparateur", "controleur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    result = await db.execute(
        select(Vignette)
        .where(Vignette.commande_id == commande_id)
        .order_by(Vignette.created_at.desc())
    )
    vignettes = result.scalars().all()
    designation_by_lid = {ln.id: ln.designation for ln in commande.lignes}
    return {
        "vignettes": [
            _vignette_to_dict(v, designation_by_lid.get(v.ligne_id) if v.ligne_id else None)
            for v in vignettes
        ]
    }


class UpdateVignetteRequest(BaseModel):
    ligne_id: UUID | None = None
    dlc: date | None = None


@router.patch("/{commande_id}/vignettes/{vignette_id}")
async def assign_vignette(
    commande_id: UUID,
    vignette_id: UUID,
    body: UpdateVignetteRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Assign a vignette to a ligne and copy its DLC to the ligne."""
    from app.models.vignette import Vignette

    if not _vignette_role_ok(current_user.role.value):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if not _vignette_status_ok(commande.statut) and commande.statut != OrderStatus.EN_VERIFICATION:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Cannot edit vignette from status {commande.statut.value}",
        )

    result = await db.execute(
        select(Vignette).where(Vignette.id == vignette_id, Vignette.commande_id == commande_id)
    )
    vignette = result.scalar_one_or_none()
    if not vignette:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vignette not found")

    target_ligne = None
    if body.ligne_id is not None:
        for ln in commande.lignes:
            if ln.id == body.ligne_id:
                target_ligne = ln
                break
        if target_ligne is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="ligne_id does not belong to this commande",
            )

    db.info["actor_id"] = str(current_user.id)
    if body.dlc is not None:
        vignette.extracted_dlc = body.dlc
    vignette.ligne_id = body.ligne_id

    if target_ligne is not None:
        dlc_to_apply = body.dlc if body.dlc is not None else vignette.extracted_dlc
        if dlc_to_apply is not None:
            target_ligne.dlc = dlc_to_apply

    await db.commit()
    await db.refresh(vignette)
    designation = target_ligne.designation if target_ligne else None
    return _vignette_to_dict(vignette, designation)


@router.delete("/{commande_id}/vignettes/{vignette_id}")
async def delete_vignette(
    commande_id: UUID,
    vignette_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    from app.models.vignette import Vignette

    if not _vignette_role_ok(current_user.role.value):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    result = await db.execute(
        select(Vignette).where(Vignette.id == vignette_id, Vignette.commande_id == commande_id)
    )
    vignette = result.scalar_one_or_none()
    if not vignette:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vignette not found")

    filepath = _VIGNETTES_ROOT / str(commande_id) / vignette.filename
    try:
        resolved = filepath.resolve()
        if resolved.is_relative_to(_VIGNETTES_ROOT.resolve()) and resolved.is_file():
            resolved.unlink()
    except OSError as exc:
        logger.warning("Failed to delete vignette file %s: %s", filepath, exc)

    db.info["actor_id"] = str(current_user.id)
    await db.delete(vignette)
    await db.commit()
    return {"status": "ok"}


@router.patch("/{commande_id}/finalize-preparation")
async def finalize_preparation(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    """Finalize preparation: check all lines verified and release the caddie."""
    if current_user.role.value not in (
        "preparateur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    if commande.statut not in (
        OrderStatus.EN_PREPARATION,
        OrderStatus.PRELEVEE_PARTIELLEMENT,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Cannot finalize from {commande.statut.value}",
        )

    # All lines must be verified
    unverified = [ln.designation for ln in commande.lignes if not ln.verifie]
    if unverified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Lignes non vérifiées: {', '.join(unverified)}",
        )

    db.info["actor_id"] = str(current_user.id)
    commande.visa_preparateur = current_user.nom

    await release_caddie_on_finalize(db, commande_id)

    # Check if partial pick
    has_partial = any((ln.qte_prelevee or 0) < ln.qte_demandee for ln in commande.lignes)
    if has_partial:
        commande = await transition_order(
            db,
            commande_id,
            OrderStatus.PRELEVEE_PARTIELLEMENT,
        )

    commande = await transition_order(
        db,
        commande_id,
        OrderStatus.EN_VERIFICATION,
    )
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()
    return OrderDetailResponse(
        **_enrich_order(commande, pharmacien, None, viewer_role=current_user.role.value)
    )


@router.patch("/{commande_id}/validate-control")
async def validate_control(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    """Controller validates order → PRETE."""
    if current_user.role.value not in (
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )
    if commande.statut != OrderStatus.EN_VERIFICATION:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Cannot validate from {commande.statut.value}",
        )
    if not commande.camion_id or not commande.feuille_route_id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Assign a truck before validation",
        )

    feuille = await get_route_sheet(db, commande.feuille_route_id)
    if not feuille:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Route sheet missing",
        )
    if feuille.camion_id != commande.camion_id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Truck assignment is inconsistent with route sheet",
        )
    if feuille.date != date.today():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Route sheet must be created for today",
        )

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(
        db,
        commande_id,
        OrderStatus.PRETE,
    )
    commande.visa_controleur = current_user.nom
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()
    camion_result = await db.execute(select(Camion).where(Camion.id == commande.camion_id))
    camion = camion_result.scalar_one_or_none()
    return OrderDetailResponse(
        **_enrich_order(commande, pharmacien, camion, viewer_role=current_user.role.value)
    )


@router.get("/{commande_id}/liste-prelevement")
async def download_liste_prelevement(
    commande_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Generate and download the picking list PDF."""
    from fastapi.responses import FileResponse

    if current_user.role.value not in (
        "preparateur",
        "controleur",
        "operatrice",
        "admin",
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    from app.documents.pdf_generator import (
        generate_liste_prelevement_pdf,
    )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    preparateur_nom = None
    if commande.preparateur_id:
        prep_result = await db.execute(select(User).where(User.id == commande.preparateur_id))
        prep_user = prep_result.scalar_one_or_none()
        preparateur_nom = prep_user.nom if prep_user else None

    from app.models.document import BonDeLivraison
    from app.models.medicament import Medicament

    bl_result = await db.execute(
        select(BonDeLivraison.code_barre).where(BonDeLivraison.commande_id == commande.id)
    )
    prelevement_ref = bl_result.scalar_one_or_none()

    med_ids = [ln.medicament_id for ln in commande.lignes]
    med_map: dict = {}
    if med_ids:
        med_result = await db.execute(
            select(Medicament.id, Medicament.code_article, Medicament.ppa).where(
                Medicament.id.in_(med_ids)
            )
        )
        med_map = {row.id: {"code": row.code_article, "ppa": float(row.ppa)} for row in med_result}

    dlc_by_key, latest_dlc_by_med = await resolve_dlc(db, med_ids)

    lignes_data = []
    for ln in commande.lignes:
        info = med_map.get(ln.medicament_id, {})
        lignes_data.append(
            {
                "code": info.get("code", ""),
                "designation": ln.designation,
                "qte_demandee": ln.qte_demandee,
                "qte_prelevee": ln.qte_prelevee or 0,
                "n_lot": ln.n_lot or "—",
                "exp": format_dlc(dlc_by_key, latest_dlc_by_med, ln.medicament_id, ln.n_lot),
                "prix_unitaire": float(ln.prix_unitaire),
                "ppa": info.get("ppa", float(ln.prix_unitaire)),
            }
        )

    path = generate_liste_prelevement_pdf(
        commande_ref=commande.reference_id,
        client_nom=pharmacien.nom if pharmacien else "N/A",
        nb_colis=commande.nb_colis or 0,
        lignes=lignes_data,
        visa_preparateur=commande.visa_preparateur,
        visa_controleur=commande.visa_controleur,
        prelevement_ref=prelevement_ref,
        commercial=commande.commercial,
        client_adresse=pharmacien.adresse if pharmacien else None,
        client_secteur=pharmacien.secteur if pharmacien else None,
        preparateur_nom=preparateur_nom,
    )

    return FileResponse(
        path=str(path),
        media_type="application/pdf",
        filename=f"prelevement_{commande.reference_id}.pdf",
    )


_MAX_SIGNATURE_B64_LEN = 500_000  # ~375 KB decoded


class DeliverWithSignatureRequest(BaseModel):
    signature: str = Field(
        min_length=10,
        max_length=_MAX_SIGNATURE_B64_LEN,
        description="Base64-encoded PNG signature",
    )


@router.patch("/{commande_id}/deliver-with-signature")
async def deliver_with_signature(
    commande_id: UUID,
    body: DeliverWithSignatureRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    """Mark order as delivered with pharmacist signature."""
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Livreur/operatrice/admin only",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    await _require_delivery_access(db, current_user, commande)

    try:
        sig_bytes = base64.b64decode(body.signature)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid base64 signature",
        ) from exc

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.LIVREE)
    commande.signature_pharmacien = sig_bytes
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


class MarkFailedRequest(BaseModel):
    motif: str = Field(min_length=1, max_length=500)
    action: str = Field(pattern=r"^(refuse|retourne)$")


@router.patch("/{commande_id}/mark-failed")
async def mark_failed(
    commande_id: UUID,
    body: MarkFailedRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    """Mark order as refused or returned with a reason."""
    if current_user.role.value not in ("livreur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Livreur/operatrice/admin only",
        )

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    await _require_delivery_access(db, current_user, commande)

    target = OrderStatus.REFUSEE if body.action == "refuse" else OrderStatus.RETOURNEE
    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, target)
    commande.motif_echec = body.motif
    await db.commit()
    await db.refresh(commande, ["lignes"])

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    data = _enrich_order(
        commande,
        pharmacien,
        None,
        viewer_role=current_user.role.value,
    )
    return OrderDetailResponse(**data)


# ─────────────────────────────────────────────────────────────────
# Caddies pool (10 physical caddies, exclusive lock on claim)
# ─────────────────────────────────────────────────────────────────


async def _list_caddie_pool(
    db: AsyncSession, *, only_available: bool = False
) -> list[CaddiePoolResponse]:
    query = select(CaddiePool).order_by(CaddiePool.numero)
    if only_available:
        query = query.where(CaddiePool.is_available.is_(True))
    result = await db.execute(query)
    caddies = list(result.scalars().all())

    ref_map: dict[UUID, str] = {}
    active_ids = [c.current_commande_id for c in caddies if c.current_commande_id]
    if active_ids:
        cmd_result = await db.execute(
            select(Commande.id, Commande.reference_id).where(Commande.id.in_(active_ids))
        )
        ref_map = {row.id: row.reference_id for row in cmd_result}

    return [
        CaddiePoolResponse(
            id=c.id,
            numero=c.numero,
            is_available=c.is_available,
            current_commande_ref=(
                ref_map.get(c.current_commande_id) if c.current_commande_id else None
            ),
        )
        for c in caddies
    ]


@router.get("/caddies/pool")
async def list_caddies_pool(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Full caddie pool (10 caddies) with availability + occupant ref."""
    if current_user.role.value not in ("preparateur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    items = await _list_caddie_pool(db)
    return {"items": [i.model_dump(mode="json") for i in items]}


@router.get("/caddies/pool/available")
async def list_caddies_pool_available(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Only currently-free caddies."""
    if current_user.role.value not in ("preparateur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    items = await _list_caddie_pool(db, only_available=True)
    return {"items": [i.model_dump(mode="json") for i in items]}
