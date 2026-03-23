from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.commandes.schemas import CreateOrderRequest, OrderDetailResponse, OrderResponse
from app.commandes.service import create_order, get_order_with_lines, transition_order
from app.db.session import get_db
from app.models.commande import Commande, OrderStatus

router = APIRouter()


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
    return OrderDetailResponse.model_validate(commande)


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

    # Pharmacien sees only own orders
    if current_user.role.value == "pharmacien":
        query = query.where(Commande.pharmacien_id == current_user.id)
        count_query = count_query.where(Commande.pharmacien_id == current_user.id)
    elif pharmacien_id:
        query = query.where(Commande.pharmacien_id == pharmacien_id)
        count_query = count_query.where(Commande.pharmacien_id == pharmacien_id)

    if statut:
        query = query.where(Commande.statut == statut)
        count_query = count_query.where(Commande.statut == statut)

    if date_from:
        query = query.where(func.date(Commande.created_at) >= date_from)
        count_query = count_query.where(func.date(Commande.created_at) >= date_from)

    if date_to:
        query = query.where(func.date(Commande.created_at) <= date_to)
        count_query = count_query.where(func.date(Commande.created_at) <= date_to)

    query = query.order_by(Commande.created_at.desc()).limit(limit).offset(offset)

    result = await db.execute(query)
    commandes = result.scalars().all()

    count_result = await db.execute(count_query)
    total = count_result.scalar()

    return {
        "commandes": [OrderResponse.model_validate(c) for c in commandes],
        "total": total,
        "limit": limit,
        "offset": offset,
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

    if current_user.role.value == "pharmacien" and commande.pharmacien_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your order")

    return OrderDetailResponse.model_validate(commande)


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
    return OrderDetailResponse.model_validate(commande)


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
    return OrderDetailResponse.model_validate(commande)


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
    return OrderDetailResponse.model_validate(commande)
