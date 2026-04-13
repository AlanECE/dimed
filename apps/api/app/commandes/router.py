import base64
import logging
from datetime import UTC, date, datetime, timedelta
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import load_only, selectinload

from app.auth.dependencies import CurrentUser
from app.commandes.schemas import (
    AssignCamionRequest,
    BulkClaimRequest,
    CreateOrderRequest,
    OrderDetailResponse,
    OrderResponse,
)
from app.commandes.service import (
    bulk_claim_commandes,
    create_order,
    get_order_with_lines,
    transition_order,
)
from app.db.session import get_db
from app.documents.service import get_or_create_route_sheet, get_route_sheet
from app.models.caddie import Caddie
from app.models.camion import Camion
from app.models.commande import Commande, OrderStatus
from app.models.document import FeuilleDeRoute
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
        "caddies": [
            {
                "id": str(c.id),
                "numero": c.numero,
                "created_at": c.created_at,
            }
            for c in commande.__dict__.get("caddies") or []
        ],
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


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create(
    body: CreateOrderRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value != "pharmacien":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Pharmacien only")

    db.info["actor_id"] = str(current_user.id)
    commande = await create_order(db, current_user.id, body)
    await db.commit()
    await db.refresh(commande, ["lignes"])
    data = _enrich_order(
        commande,
        current_user,
        None,
        viewer_role=current_user.role.value,
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
        .options(selectinload(Commande.caddies))
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
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    if current_user.role.value not in ("preparateur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Preparateur/operatrice/admin only",
        )

    db.info["actor_id"] = str(current_user.id)
    commande = await transition_order(db, commande_id, OrderStatus.EN_PREPARATION)
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
    ocr_verifie: bool | None = None


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
                "verifie": ln.verifie,
                "ocr_verifie": bool(ln.__dict__.get("ocr_verifie", False)),
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
    if body.ocr_verifie is not None:
        ligne.ocr_verifie = body.ocr_verifie
    await db.commit()
    return {"status": "ok"}


class FinalizePreparationRequest(BaseModel):
    nb_colis: int = Field(ge=1)


@router.patch("/{commande_id}/finalize-preparation")
async def finalize_preparation(
    commande_id: UUID,
    body: FinalizePreparationRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    """Finalize preparation: check all lines verified, set colis count."""
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
    commande.nb_colis = body.nb_colis
    commande.visa_preparateur = current_user.nom

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
                "exp": "",
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
# Bulk claim + caddies
# ─────────────────────────────────────────────────────────────────


@router.post("/bulk-claim")
async def bulk_claim(
    body: BulkClaimRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Claim N commandes as a preparateur and attach caddie numeros."""
    role = current_user.role.value
    if role not in ("preparateur", "operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Preparateur/operatrice/admin only",
        )

    if role == "preparateur":
        if body.preparateur_id and body.preparateur_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Preparateur can only claim for themselves",
            )
        target_preparateur_id = current_user.id
    else:
        if not body.preparateur_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="preparateur_id is required for operatrice/admin",
            )
        prep_check = await db.execute(select(User).where(User.id == body.preparateur_id))
        prep_user = prep_check.scalar_one_or_none()
        if not prep_user or prep_user.role.value != "preparateur":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="preparateur_id must reference a user with role preparateur",
            )
        target_preparateur_id = body.preparateur_id

    cover_ids = {a.commande_id for a in body.caddies}
    if cover_ids != set(body.commande_ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="caddies must cover all commande_ids exactly",
        )

    caddies_map: dict[UUID, list[str]] = {a.commande_id: a.numeros for a in body.caddies}

    commandes = await bulk_claim_commandes(
        db=db,
        commande_ids=body.commande_ids,
        caddies_by_commande=caddies_map,
        preparateur_id=target_preparateur_id,
        actor_id=current_user.id,
    )
    await db.commit()

    ids = [c.id for c in commandes]
    reload_result = await db.execute(
        select(Commande)
        .where(Commande.id.in_(ids))
        .options(
            selectinload(Commande.caddies),
            selectinload(Commande.lignes),
        )
    )
    reloaded = list(reload_result.scalars().all())

    pharm_ids = {c.pharmacien_id for c in reloaded}
    users_result = await db.execute(select(User).where(User.id.in_(pharm_ids)))
    users_map = {u.id: u for u in users_result.scalars().all()}

    prep_result = await db.execute(select(User).where(User.id == target_preparateur_id))
    prep_user = prep_result.scalar_one_or_none()

    items = [
        OrderDetailResponse(
            **_enrich_order(
                c,
                users_map.get(c.pharmacien_id),
                None,
                viewer_role=current_user.role.value,
                preparateur=prep_user,
            )
        )
        for c in reloaded
    ]
    return {"items": [i.model_dump(mode="json") for i in items]}


@router.get("/preparateurs")
async def list_preparateurs(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Lightweight list of preparateurs for the operatrice bulk-claim dropdown."""
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    from app.models.user import UserRole

    result = await db.execute(
        select(User)
        .where(User.role == UserRole.PREPARATEUR, User.is_active.is_(True))
        .order_by(User.nom)
    )
    users = result.scalars().all()
    return {
        "preparateurs": [{"id": str(u.id), "nom": u.nom} for u in users],
    }


@router.get("/caddies/suggestions")
async def caddies_suggestions(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    limit: int = 20,
) -> dict:
    """Recent caddie numeros for the current user (autocomplete)."""
    if current_user.role.value not in ("preparateur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    own_q = (
        select(Caddie.numero, func.max(Caddie.created_at).label("last_used"))
        .where(Caddie.created_by == current_user.id)
        .group_by(Caddie.numero)
        .order_by(func.max(Caddie.created_at).desc())
        .limit(min(limit, 100))
    )
    result = await db.execute(own_q)
    own = [r.numero for r in result]

    if not own:
        fb_q = (
            select(Caddie.numero, func.max(Caddie.created_at).label("last_used"))
            .group_by(Caddie.numero)
            .order_by(func.max(Caddie.created_at).desc())
            .limit(min(limit, 100))
        )
        fb_result = await db.execute(fb_q)
        own = [r.numero for r in fb_result]

    return {"suggestions": own}


@router.delete("/caddies/{caddie_id}")
async def delete_caddie(
    caddie_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Remove a caddie assignment (owner preparateur or operatrice/admin)."""
    role = current_user.role.value
    if role not in ("preparateur", "operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    result = await db.execute(select(Caddie).where(Caddie.id == caddie_id))
    caddie = result.scalar_one_or_none()
    if not caddie:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Caddie not found")

    if role == "preparateur" and caddie.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Preparateur can only delete their own caddies",
        )

    db.info["actor_id"] = str(current_user.id)
    await db.delete(caddie)
    await db.commit()
    return {"status": "deleted", "id": str(caddie_id)}
