from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.audit import AuditLog
from app.models.user import User

router = APIRouter()

SENSITIVE_FIELDS = {
    "password_hash",
    "password",
    "password_hash_old",
    "password_hash_new",
    "signature_pharmacien",
    "signature_expedition",
    "signature_chauffeur",
}


def _sanitize(val: dict | None) -> dict | None:
    if not val:
        return val
    return {k: "***" if k in SENSITIVE_FIELDS else v for k, v in val.items()}


@router.get("/audit-log")
async def list_audit_log(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    entity_type: str | None = None,
    action: str | None = None,
    limit: int = 30,
    offset: int = 0,
) -> dict:
    if current_user.role.value != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")

    query = select(AuditLog)

    if entity_type:
        query = query.where(AuditLog.entity_type == entity_type)
    if action:
        query = query.where(AuditLog.action == action)

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(AuditLog.timestamp.desc()).offset(offset).limit(min(limit, 100))
    result = await db.execute(query)
    logs = result.scalars().all()

    actor_ids = {log.actor_id for log in logs if log.actor_id}
    actor_map: dict = {}
    if actor_ids:
        users_result = await db.execute(select(User).where(User.id.in_(actor_ids)))
        actor_map = {u.id: u.nom for u in users_result.scalars().all()}

    items = [
        {
            "id": str(log.id),
            "entity_type": log.entity_type,
            "entity_id": str(log.entity_id),
            "action": log.action,
            "actor_id": str(log.actor_id) if log.actor_id else None,
            "actor_nom": actor_map.get(log.actor_id) if log.actor_id else None,
            "timestamp": log.timestamp.isoformat(),
            "old_value": _sanitize(log.old_value),
            "new_value": _sanitize(log.new_value),
        }
        for log in logs
    ]

    return {"items": items, "total": total, "limit": limit, "offset": offset}
