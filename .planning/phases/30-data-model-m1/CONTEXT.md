# Phase 30 Context: Data Model M1

**Phase goal:** Database schema for all Module 1 entities with proper state machine and audit trail.

**Requirements:** ORD-05, ORD-07, AUDIT-01, AUDIT-02, AUDIT-03

## Pre-existing from Phase 10

All SQLAlchemy models already exist in `apps/api/app/models/`:
- User, Medicament, Commande, LigneCommande, Facture, BonDeLivraison, FeuilleDeRoute, AuditLog
- AuditMixin with created_at, updated_at, created_by
- OrderStatus enum (12 values)
- UUID v4 PKs

**Phase 30 adds:** state machine logic, reference ID generation, audit log triggers, and the actual Alembic migration.

## Decisions

### State Machine — Valid Transitions

```
Creee ──→ Acceptee ──→ En_preparation ──→ ...
  │
  └──→ Annulee (by operatrice or pharmacien)
```

| From | To | Actor | Notes |
|------|----|-------|-------|
| Creee | Acceptee | Operatrice | Validation |
| Creee | Annulee | Operatrice / Pharmacien | Before preparation only (RG-1-07) |
| Acceptee | En_preparation | Systeme / Preparateur | Scan code-barre BL |
| En_preparation | Prelevee_partiellement | Preparateur | Q.Prl < QTE (M2) |
| En_preparation | En_verification | Preparateur | All items scanned (M2) |
| En_verification | Prete | Controleur | Verification complete (M2) |
| Prete | En_route | Livreur | All packages scanned (M3) |
| En_route | Livree | Pharmacien | Signature electronique (M3) |
| En_route | Refusee | Pharmacien | Refus livraison (M3) |
| En_route | Retournee | Livreur | Echec livraison (M3) |
| En_route | Livree_partiellement | Livreur | Livraison partielle (M3) |

**Implementation:** Dict `VALID_TRANSITIONS: dict[OrderStatus, list[OrderStatus]]` in a new file `app/models/state_machine.py`. Function `validate_transition(current, target) -> bool` that raises `ValueError` if invalid.

**Motif pour annulation/refus :** Pas en v1. Ajouté plus tard.

### Reference IDs — PostgreSQL Sequences

| Entity | Prefix | Sequence | Format | Example |
|--------|--------|----------|--------|---------|
| Commande | C | commande_seq | C{seq:08d} | C00046488 |
| Facture | F | facture_seq | F{seq:010d} | F9410044388 |
| BonDeLivraison | BL | bl_seq | BL{seq:08d} | BL00001234 |
| Prelevement | P | prelevement_seq | P{seq:08d} | P00044779 |

- Sequences created in the Alembic migration
- `reference_id` generated in Python before insert: `SELECT nextval('commande_seq')`
- Helper function in `app/models/references.py`: `async def next_reference(db, prefix, seq_name) -> str`

### Audit Log — SQLAlchemy Events

- Use `@event.listens_for(Session, "after_flush")` to capture changes
- Log to AuditLog table: entity_type, entity_id, action (insert/update/delete), actor_id, old_value (JSONB), new_value (JSONB)
- **Scope:** All models with AuditMixin (User, Commande, LigneCommande, Facture, BL, FeuilleDeRoute, Medicament)
- **actor_id:** Passed via `session.info["actor_id"]` set by the auth middleware
- File: `app/db/audit_listener.py`

### Alembic Migration

- Generate with `alembic revision --autogenerate -m "initial M1 tables"`
- Must include:
  - All tables
  - PostgreSQL sequences (commande_seq, facture_seq, bl_seq, prelevement_seq)
  - Enum types (orderstatus, userrole)
  - Indexes on reference_id, email, entity_type+entity_id (audit)

## Code Context

- `apps/api/app/models/` — All models exist, need state machine + references logic
- `apps/api/app/db/base.py` — Base + AuditMixin
- `apps/api/alembic/` — Configured, no migrations yet
- `apps/api/app/db/session.py` — async engine + session

## Deferred Ideas

- Motif obligatoire pour annulation/refus — v2
- Soft delete (is_deleted flag) — pas nécessaire en v1
- Database triggers as backup audit — overkill pour déploiement interne

---
*Created: 2026-03-23 after discuss-phase 30*
