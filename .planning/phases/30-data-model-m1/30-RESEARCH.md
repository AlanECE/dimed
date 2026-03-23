# Phase 30 Research: Data Model M1

## State Machine Implementation

Simple dict-based approach — no external library needed:

```python
VALID_TRANSITIONS: dict[OrderStatus, list[OrderStatus]] = {
    OrderStatus.CREEE: [OrderStatus.ACCEPTEE, OrderStatus.ANNULEE],
    OrderStatus.ACCEPTEE: [OrderStatus.EN_PREPARATION],
    OrderStatus.EN_PREPARATION: [OrderStatus.PRELEVEE_PARTIELLEMENT, OrderStatus.EN_VERIFICATION],
    OrderStatus.EN_VERIFICATION: [OrderStatus.PRETE],
    OrderStatus.PRETE: [OrderStatus.EN_ROUTE],
    OrderStatus.EN_ROUTE: [OrderStatus.LIVREE, OrderStatus.REFUSEE, OrderStatus.RETOURNEE, OrderStatus.LIVREE_PARTIELLEMENT],
}

def validate_transition(current: OrderStatus, target: OrderStatus) -> None:
    allowed = VALID_TRANSITIONS.get(current, [])
    if target not in allowed:
        raise ValueError(f"Invalid transition: {current.value} → {target.value}")
```

## PostgreSQL Sequences for Reference IDs

```sql
CREATE SEQUENCE commande_seq START 1;
CREATE SEQUENCE facture_seq START 1;
CREATE SEQUENCE bl_seq START 1;
CREATE SEQUENCE prelevement_seq START 1;
```

In Python with async SQLAlchemy:
```python
from sqlalchemy import text

async def next_reference(db: AsyncSession, prefix: str, seq_name: str, pad: int = 8) -> str:
    result = await db.execute(text(f"SELECT nextval('{seq_name}')"))
    seq_val = result.scalar()
    return f"{prefix}{seq_val:0{pad}d}"
```

## SQLAlchemy Audit Events — CRITICAL ASYNC GOTCHA

**From Tavily research (SQLAlchemy docs + GitHub discussion #11714):**

With async sessions, `before_flush`/`after_flush` events must be attached to the **sync_session class**, NOT the async session. The async session delegates to a sync session internally.

```python
from sqlalchemy import event
from sqlalchemy.orm import Session

@event.listens_for(Session, "after_flush")
def after_flush(session, flush_context):
    # session.new → newly inserted
    # session.dirty → updated
    # session.deleted → deleted
    for obj in session.new:
        # log INSERT
    for obj in session.dirty:
        # log UPDATE with old/new values via inspect(obj).attrs
    for obj in session.deleted:
        # log DELETE
```

**Getting old values:**
```python
from sqlalchemy import inspect

for obj in session.dirty:
    insp = inspect(obj)
    for attr in insp.attrs:
        history = attr.history
        if history.has_changes():
            old = history.deleted[0] if history.deleted else None
            new = history.added[0] if history.added else None
            # log change
```

**actor_id pattern:**
```python
# In auth middleware, before DB operations:
db.info["actor_id"] = str(current_user.id)

# In event listener:
actor_id = session.info.get("actor_id")
```

## Alembic Migration with Sequences

Sequences must be created explicitly in the migration since `autogenerate` doesn't detect them:

```python
def upgrade():
    # Auto-generated tables...
    op.execute("CREATE SEQUENCE IF NOT EXISTS commande_seq START 1")
    op.execute("CREATE SEQUENCE IF NOT EXISTS facture_seq START 1")
    op.execute("CREATE SEQUENCE IF NOT EXISTS bl_seq START 1")
    op.execute("CREATE SEQUENCE IF NOT EXISTS prelevement_seq START 1")

def downgrade():
    op.execute("DROP SEQUENCE IF EXISTS prelevement_seq")
    op.execute("DROP SEQUENCE IF EXISTS bl_seq")
    op.execute("DROP SEQUENCE IF EXISTS facture_seq")
    op.execute("DROP SEQUENCE IF EXISTS commande_seq")
    # Auto-generated drops...
```

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `app/models/state_machine.py` | Create | VALID_TRANSITIONS dict + validate_transition() |
| `app/models/references.py` | Create | next_reference() async helper |
| `app/db/audit_listener.py` | Create | SQLAlchemy after_flush event → AuditLog |
| `app/db/session.py` | Modify | Register audit listener on Session class |
| `alembic/versions/xxx_initial.py` | Create | Migration with tables + sequences |

---
*Research completed: 2026-03-23 for Phase 30*
*Sources: Context7 FastAPI/SQLAlchemy docs, Tavily (SQLAlchemy async events gotcha), SQLAlchemy docs session_events*
