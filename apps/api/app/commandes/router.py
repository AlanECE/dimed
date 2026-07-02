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
from sqlalchemy.orm import selectinload

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
    RefuseSaisieRequest,
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
from app.models.notification import Notification
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

    camions_result = await db.execute(select(Camion))
    camions_map = {c.id: c.nom for c in camions_result.scalars().all()}

    return {
        "pharmaciens": [
            {
                "id": str(u.id),
                "nom": u.nom,
                "email": u.email,
                "adresse": u.adresse,
                "secteur": u.secteur,
                "telephone": u.telephone,
                "camion_id": str(u.camion_id) if u.camion_id else None,
                "camion_nom": camions_map.get(u.camion_id),
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
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Pharmacien introuvable"
            )
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
    elif role == "facturier":
        # Le facturier voit les commandes dès la préparation (facture déjà émise
        # à l'acceptation) jusqu'à la livraison, pour facturer/coller les QR.
        facturier_statuses = [
            OrderStatus.EN_PREPARATION,
            OrderStatus.PRELEVEE_PARTIELLEMENT,
            OrderStatus.EN_VERIFICATION,
            OrderStatus.PRETE,
            OrderStatus.EN_ROUTE,
            OrderStatus.LIVREE,
        ]
        query = query.where(Commande.statut.in_(facturier_statuses))
        count_query = count_query.where(Commande.statut.in_(facturier_statuses))
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

    # Remise totale accordée sur la période (Σ qte × PU × R%).
    remises_q = (
        select(
            func.coalesce(
                func.sum(
                    LigneCommande.qte_demandee
                    * LigneCommande.prix_unitaire
                    * LigneCommande.remise_pct
                    / 100
                ),
                0,
            )
        )
        .select_from(LigneCommande)
        .join(Commande, LigneCommande.commande_id == Commande.id)
        .where(*base_filter)
    )
    total_remises = float((await db.execute(remises_q)).scalar() or 0)

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
        "total_remises": round(total_remises, 2),
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

    pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = pharm_result.scalar_one_or_none()

    # La ligne de livraison est déterminée à la création de la fiche client :
    # la commande en hérite automatiquement (plus de ressaisie manuelle).
    camion = None
    if pharmacien and pharmacien.camion_id and not commande.camion_id:
        commande.camion_id = pharmacien.camion_id
        feuille = await get_or_create_route_sheet(db, pharmacien.camion_id, date.today())
        commande.feuille_route_id = feuille.id
        camion_result = await db.execute(select(Camion).where(Camion.id == pharmacien.camion_id))
        camion = camion_result.scalar_one_or_none()

    await db.commit()
    await db.refresh(commande, ["lignes"])

    data = _enrich_order(
        commande,
        pharmacien,
        camion,
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


@router.patch("/{commande_id}/refuse")
async def refuse_saisie(
    commande_id: UUID,
    body: RefuseSaisieRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    """Operatrice refuses a pending saisie: the order stays CREEE, the reason is
    recorded in operatrice_comment and the pharmacien is notified so they can
    correct and resubmit (no terminal cancellation)."""
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Operatrice/admin only")

    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if commande.statut != OrderStatus.CREEE:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Seule une saisie en attente de validation peut etre refusee "
                f"(statut {commande.statut.value})."
            ),
        )

    db.info["actor_id"] = str(current_user.id)
    commande.operatrice_comment = body.motif
    db.add(
        Notification(
            id=uuid4(),
            user_id=commande.pharmacien_id,
            commande_id=commande.id,
            type="refusee",
            message=f"Commande {commande.reference_id} refusee : {body.motif}",
        )
    )
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


def _require_line_edit_access(commande: Commande, current_user: User) -> None:
    """Gate line add/edit/delete on an order.

    - operatrice/admin: editable while CREEE or ACCEPTEE (stock adjustment and
      facture regeneration are handled downstream for ACCEPTEE).
    - pharmacien: only the order's owner, and only while it is still CREEE (not yet
      validated by an operatrice). Any attempt after validation is rejected (409).
    """
    role = current_user.role.value
    if role in ("operatrice", "admin"):
        if commande.statut not in _OPERATRICE_EDITABLE_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "Commande non modifiable dans son statut actuel "
                    f"({commande.statut.value}). Edition autorisee en CREEE ou ACCEPTEE uniquement."
                ),
            )
    elif role == "pharmacien":
        if commande.pharmacien_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")
        if commande.statut != OrderStatus.CREEE:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "Commande deja validee : modification impossible "
                    f"(statut {commande.statut.value})."
                ),
            )
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


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
    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    _require_line_edit_access(commande, current_user)

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
    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    _require_line_edit_access(commande, current_user)

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
    commande = await get_order_with_lines(db, commande_id)
    if not commande:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    _require_line_edit_access(commande, current_user)

    if len(commande.lignes) <= 1:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Derniere ligne : annulez la commande au lieu de la supprimer",
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

    # Idempotent : si le scan des cartons a déjà fait passer la commande en
    # livraison, on retourne l'état courant sans rejouer la transition.
    if commande.statut == OrderStatus.EN_ROUTE:
        pharm_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
        pharmacien = pharm_result.scalar_one_or_none()
        camion_result = await db.execute(select(Camion).where(Camion.id == commande.camion_id))
        camion = camion_result.scalar_one_or_none()
        return OrderDetailResponse(
            **_enrich_order(commande, pharmacien, camion, viewer_role=current_user.role.value)
        )

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
    n_lot: str | None = Field(default=None, max_length=50)
    fab: date | None = None
    exp: date | None = None
    ppa: Decimal | None = Field(default=None, max_digits=10, decimal_places=2)


def _ligne_to_dict(ln: LigneCommande, vignette=None) -> dict:
    """Serialize a preparation line to JSON-friendly dict."""
    return {
        "id": str(ln.id),
        "medicament_id": str(ln.medicament_id),
        "designation": ln.designation,
        "qte_demandee": ln.qte_demandee,
        "qte_prelevee": ln.qte_prelevee,
        "prix_unitaire": float(ln.prix_unitaire),
        "remise_pct": float(ln.remise_pct),
        "n_lot": ln.n_lot,
        "fab": ln.fab.isoformat() if ln.fab else None,
        "exp": ln.exp.isoformat() if ln.exp else None,
        "ppa": str(ln.ppa) if ln.ppa is not None else None,
        "verifie": ln.verifie,
        "vignette": _vignette_to_dict(vignette) if vignette is not None else None,
    }


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

    from app.models.vignette import Vignette

    ligne_ids = [ln.id for ln in commande.lignes]
    vignette_by_lid: dict[UUID, Vignette] = {}
    if ligne_ids:
        v_result = await db.execute(select(Vignette).where(Vignette.ligne_id.in_(ligne_ids)))
        for v in v_result.scalars():
            vignette_by_lid[v.ligne_id] = v

    # medicament_ppa for divergence pill
    med_result = await db.execute(
        select(Medicament.id, Medicament.ppa).where(
            Medicament.id.in_([ln.medicament_id for ln in commande.lignes])
        )
    )
    ppa_by_med = {row.id: row.ppa for row in med_result}

    lignes_out = []
    for ln in commande.lignes:
        d = _ligne_to_dict(ln, vignette_by_lid.get(ln.id))
        cat_ppa = ppa_by_med.get(ln.medicament_id)
        d["medicament_ppa"] = str(cat_ppa) if cat_ppa is not None else None
        lignes_out.append(d)

    return {
        "lignes": lignes_out,
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
    """Update a line's picked quantity, verified status, lot/fab/exp/ppa."""
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
    if commande.statut not in (
        OrderStatus.EN_PREPARATION,
        OrderStatus.PRELEVEE_PARTIELLEMENT,
        OrderStatus.EN_VERIFICATION,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Order not in preparation or verification",
        )

    result = await db.execute(
        select(LigneCommande).where(
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
    if body.n_lot is not None:
        ligne.n_lot = body.n_lot
    if body.fab is not None:
        ligne.fab = body.fab
    if body.exp is not None:
        ligne.exp = body.exp
    if body.ppa is not None:
        ligne.ppa = body.ppa
    if body.verifie is not None:
        ligne.verifie = body.verifie
    await db.commit()
    return {"status": "ok"}


# ─── Per-ligne vignette OCR scan ────────────────────────────────────────────

from pathlib import Path as _Path  # noqa: E402

from app.commandes.schemas import VignetteWarning  # noqa: E402

_VIGNETTES_ROOT = _Path(__file__).resolve().parents[3] / "storage" / "images" / "vignettes"
_MAX_VIGNETTE_BYTES = 10 * 1024 * 1024  # 10 MiB
_CONTENT_TYPE_TO_EXT = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}
_PER_LIGNE_ROLES = ("preparateur", "controleur", "operatrice", "admin")


def _vignette_to_dict(v) -> dict | None:
    if v is None:
        return None
    return {
        "id": str(v.id),
        "filename": v.filename,
        "file_url": f"/static/images/vignettes/{v.filename}",
        "extracted_lot": v.extracted_lot,
        "extracted_fab": v.extracted_fab.isoformat() if v.extracted_fab else None,
        "extracted_exp": v.extracted_exp.isoformat() if v.extracted_exp else None,
        "extracted_ppa": str(v.extracted_ppa) if v.extracted_ppa is not None else None,
        "extracted_designation": v.extracted_designation,
    }


def _compute_warnings(extraction, ligne, medicament_ppa) -> list[VignetteWarning]:
    warnings: list[VignetteWarning] = []
    if extraction.lot is None and not ligne.n_lot:
        warnings.append(VignetteWarning.MISSING_LOT)
    if extraction.fab is None and ligne.fab is None:
        warnings.append(VignetteWarning.MISSING_FAB)
    if extraction.exp is None and ligne.exp is None:
        warnings.append(VignetteWarning.MISSING_EXP)
    if extraction.ppa is None and ligne.ppa is None:
        warnings.append(VignetteWarning.MISSING_PPA)
    elif (
        extraction.ppa is not None
        and medicament_ppa is not None
        and extraction.ppa != medicament_ppa
    ):
        warnings.append(VignetteWarning.PPA_DIVERGENT)
    return warnings


@router.post("/{commande_id}/lignes/{ligne_id}/vignette")
async def upload_ligne_vignette(
    commande_id: UUID,
    ligne_id: UUID,
    current_user: CurrentUser,
    file: Annotated[UploadFile, File(...)],
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Upload a photo of a vignette pasted on a medication box; OCR pre-fills
    the line's lot/fab/exp/ppa, auto-checks `verifie` if no warnings.
    """
    from app.models.vignette import Vignette
    from app.ocr.service import (
        OcrConfigurationError,
        OcrUpstreamError,
        extract_vignette_fields,
    )

    if current_user.role.value not in _PER_LIGNE_ROLES:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied")

    ligne_result = await db.execute(
        select(LigneCommande).where(
            LigneCommande.id == ligne_id,
            LigneCommande.commande_id == commande_id,
        )
    )
    ligne = ligne_result.scalar_one_or_none()
    if ligne is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Line not found")

    commande_result = await db.execute(select(Commande).where(Commande.id == commande_id))
    commande = commande_result.scalar_one_or_none()
    if commande is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    if commande.statut in (OrderStatus.LIVREE, OrderStatus.ANNULEE):
        raise HTTPException(status.HTTP_409_CONFLICT, "Order is finalized")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Empty file")
    if len(image_bytes) > _MAX_VIGNETTE_BYTES:
        raise HTTPException(
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            "Image exceeds 10 MiB limit",
        )
    content_type = (file.content_type or "").lower()
    ext = _CONTENT_TYPE_TO_EXT.get(content_type)
    if not ext:
        raise HTTPException(
            status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            "Unsupported format (JPG/PNG/WEBP only)",
        )

    try:
        extraction = await extract_vignette_fields(image_bytes, content_type)
    except OcrConfigurationError as exc:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, str(exc)) from exc
    except OcrUpstreamError as exc:
        logger.warning("OCR upstream failure on ligne=%s: %s", ligne_id, exc)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"OCR error: {exc}") from exc

    # Upsert vignette (1:1 with ligne). Same UUID re-used on re-scan.
    existing_result = await db.execute(select(Vignette).where(Vignette.ligne_id == ligne_id))
    existing = existing_result.scalar_one_or_none()
    vid = existing.id if existing else uuid4()

    _VIGNETTES_ROOT.mkdir(parents=True, exist_ok=True)
    filename = f"{vid}.{ext}"
    target_path = (_VIGNETTES_ROOT / filename).resolve()
    if not target_path.is_relative_to(_VIGNETTES_ROOT.resolve()):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid path")

    if existing:
        old_path = (_VIGNETTES_ROOT / existing.filename).resolve()
        if (
            old_path.is_relative_to(_VIGNETTES_ROOT.resolve())
            and old_path.is_file()
            and old_path != target_path
        ):
            try:
                old_path.unlink()
            except OSError as exc:
                logger.warning("Failed to remove old vignette file %s: %s", old_path, exc)

    target_path.write_bytes(image_bytes)

    db.info["actor_id"] = str(current_user.id)
    if existing:
        existing.filename = filename
        existing.extracted_lot = extraction.lot
        existing.extracted_fab = extraction.fab
        existing.extracted_exp = extraction.exp
        existing.extracted_ppa = extraction.ppa
        existing.extracted_designation = extraction.designation
        existing.extracted_raw = extraction.raw
        existing.uploaded_by = current_user.id
        vignette = existing
    else:
        vignette = Vignette(
            id=vid,
            commande_id=commande_id,
            ligne_id=ligne_id,
            filename=filename,
            extracted_lot=extraction.lot,
            extracted_fab=extraction.fab,
            extracted_exp=extraction.exp,
            extracted_ppa=extraction.ppa,
            extracted_designation=extraction.designation,
            extracted_raw=extraction.raw,
            uploaded_by=current_user.id,
        )
        db.add(vignette)

    # Apply OCR values to the line (only overwrite when OCR returned a value)
    if extraction.lot:
        ligne.n_lot = extraction.lot
    if extraction.fab is not None:
        ligne.fab = extraction.fab
    if extraction.exp is not None:
        ligne.exp = extraction.exp
    if extraction.ppa is not None:
        ligne.ppa = extraction.ppa

    # Catalogue PPA for divergence check
    med_result = await db.execute(
        select(Medicament.ppa).where(Medicament.id == ligne.medicament_id)
    )
    medicament_ppa = med_result.scalar_one_or_none()

    warnings = _compute_warnings(extraction, ligne, medicament_ppa)
    ligne.verifie = len(warnings) == 0

    await db.commit()
    await db.refresh(ligne)
    await db.refresh(vignette)

    ligne_dict = _ligne_to_dict(ligne, vignette)
    ligne_dict["medicament_ppa"] = str(medicament_ppa) if medicament_ppa is not None else None
    return {
        "ligne": ligne_dict,
        "vignette": _vignette_to_dict(vignette),
        "warnings": [w.value for w in warnings],
    }


@router.delete(
    "/{commande_id}/lignes/{ligne_id}/vignette",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def clear_ligne_vignette(
    commande_id: UUID,
    ligne_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> None:
    """Remove the vignette and reset the line's lot/fab/exp/ppa + verifie."""
    from app.models.vignette import Vignette

    if current_user.role.value not in _PER_LIGNE_ROLES:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied")

    ligne_result = await db.execute(
        select(LigneCommande).where(
            LigneCommande.id == ligne_id,
            LigneCommande.commande_id == commande_id,
        )
    )
    ligne = ligne_result.scalar_one_or_none()
    if ligne is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Line not found")

    v_result = await db.execute(select(Vignette).where(Vignette.ligne_id == ligne_id))
    vignette = v_result.scalar_one_or_none()
    if vignette is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vignette not found")

    target_path = (_VIGNETTES_ROOT / vignette.filename).resolve()
    if target_path.is_relative_to(_VIGNETTES_ROOT.resolve()) and target_path.is_file():
        try:
            target_path.unlink()
        except OSError as exc:
            logger.warning("Failed to remove vignette file %s: %s", target_path, exc)

    db.info["actor_id"] = str(current_user.id)
    await db.delete(vignette)
    ligne.n_lot = None
    ligne.fab = None
    ligne.exp = None
    ligne.ppa = None
    ligne.verifie = False
    await db.commit()


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


class ValidateControlRequest(BaseModel):
    nb_colis: int = Field(ge=1, le=500, description="Nombre de colis constitués au contrôle")


@router.patch("/{commande_id}/validate-control")
async def validate_control(
    commande_id: UUID,
    body: ValidateControlRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> OrderDetailResponse:
    """Controller validates order → PRETE, sets nb_colis and creates tracked parcels."""
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
    commande.nb_colis = body.nb_colis

    from app.expedition.service import create_colis_for_commande

    await create_colis_for_commande(db, commande, body.nb_colis)

    # La proforma émise à l'acceptation devient la facture définitive
    # maintenant que la commande est contrôlée.
    facture = await _load_facture_for_commande(db, commande.id)
    if facture is not None:
        await regenerate_facture_pdf(db, facture)

    # Notifie le(s) facturier(s) : commande contrôlée → étiquettes QR à coller.
    from app.models.user import UserRole

    facturiers = await db.execute(select(User).where(User.role == UserRole.FACTURIER))
    for facturier in facturiers.scalars().all():
        db.add(
            Notification(
                id=uuid4(),
                user_id=facturier.id,
                commande_id=commande.id,
                type="commande_controlee",
                message=(
                    f"Commande {commande.reference_id} contrôlée — "
                    f"{body.nb_colis} colis, étiquettes QR à imprimer/coller"
                ),
            )
        )

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
