from sqlalchemy import LargeBinary, event, inspect
from sqlalchemy.orm import Session

from app.db.base import AuditMixin
from app.models.audit import AuditLog

SENSITIVE_FIELDS = {
    "password_hash",
    "password",
    "password_hash_old",
    "password_hash_new",
    "signature_pharmacien",
    "signature_expedition",
    "signature_chauffeur",
}


def _is_binary_column(mapper, key: str) -> bool:
    """Check if a column is LargeBinary (signatures, blobs)."""
    if key in mapper.columns:
        return isinstance(mapper.columns[key].type, LargeBinary)
    return False


def _serialize_value(key: str, value, mapper) -> str:
    if key in SENSITIVE_FIELDS:
        return "***"
    if _is_binary_column(mapper, key):
        return "<binary omitted>"
    return str(value)


def _serialize_attrs(obj) -> dict:
    mapper = inspect(obj).mapper
    return {
        c.key: _serialize_value(c.key, getattr(obj, c.key), mapper) for c in mapper.column_attrs
    }


def _get_changes(obj) -> tuple[dict | None, dict | None]:
    insp = inspect(obj)
    mapper = insp.mapper
    old_values: dict = {}
    new_values: dict = {}
    for attr in insp.attrs:
        history = attr.history
        if history.has_changes():
            if history.deleted:
                old_values[attr.key] = _serialize_value(attr.key, history.deleted[0], mapper)
            if history.added:
                new_values[attr.key] = _serialize_value(attr.key, history.added[0], mapper)
    return old_values or None, new_values or None


@event.listens_for(Session, "after_flush")
def after_flush_audit(session, flush_context):
    """Automatically log all changes to AuditMixin models into AuditLog."""
    actor_id = session.info.get("actor_id")

    for obj in session.new:
        if isinstance(obj, AuditMixin) and not isinstance(obj, AuditLog):
            session.add(
                AuditLog(
                    entity_type=obj.__tablename__,
                    entity_id=obj.id,
                    action="insert",
                    actor_id=actor_id,
                    new_value=_serialize_attrs(obj),
                )
            )

    for obj in session.dirty:
        if isinstance(obj, AuditMixin) and not isinstance(obj, AuditLog):
            old_values, new_values = _get_changes(obj)
            if new_values:
                session.add(
                    AuditLog(
                        entity_type=obj.__tablename__,
                        entity_id=obj.id,
                        action="update",
                        actor_id=actor_id,
                        old_value=old_values,
                        new_value=new_values,
                    )
                )

    for obj in session.deleted:
        if isinstance(obj, AuditMixin) and not isinstance(obj, AuditLog):
            session.add(
                AuditLog(
                    entity_type=obj.__tablename__,
                    entity_id=obj.id,
                    action="delete",
                    actor_id=actor_id,
                    old_value=_serialize_attrs(obj),
                )
            )
