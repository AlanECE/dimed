# Phase 10 Research: Foundations & Infrastructure

## Turborepo + pnpm + uv Monorepo Setup

### Turborepo Configuration
- `turbo.json` defines pipeline tasks: `build`, `dev`, `lint`, `typecheck`
- pnpm workspace via `pnpm-workspace.yaml` listing `apps/*` and `packages/*`
- Python apps (apps/api) are NOT managed by Turborepo — only JS/TS apps
- Turborepo `dev` task runs `next dev` for web, API runs separately via Docker

### pnpm Workspace
```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"
```
- apps/api excluded from pnpm workspace (Python, managed by uv)
- packages/ocr excluded from pnpm workspace (Python, managed by uv)

### uv for Python
- `uv init` in apps/api/ and packages/ocr/
- apps/api depends on packages/ocr via `uv pip install -e ../../packages/ocr`
- uv.lock for reproducible installs
- Python 3.12 (not 3.14 — 3.12 is stable, EasyOCR compatible)

## Docker Compose Architecture

### Services
```yaml
services:
  db:        # PostgreSQL 16, port 5432, volume for persistence
  redis:     # Redis 7, port 6379
  api:       # FastAPI, port 8000, depends_on db+redis
  web:       # Next.js, port 3000, depends_on api
```

### Hot Reload Strategy
- **API**: Mount `./apps/api:/app` and `./packages/ocr:/packages/ocr`, run `uvicorn app.main:app --reload`
- **Web**: Mount `./apps/web:/app`, run `pnpm dev`
- **DB/Redis**: No mount needed, use named volumes for persistence

### Multi-stage Builds (prod)
```dockerfile
# API: python:3.12-slim
FROM python:3.12-slim AS builder
# Install uv, copy deps, install
FROM python:3.12-slim AS runtime
# Copy installed packages, non-root user, HEALTHCHECK
```

### Hardening Checklist
- Non-root USER in all Dockerfiles
- No secrets in image layers
- HEALTHCHECK on all services
- Read-only filesystem where possible
- Minimal base images (slim, not full)

## SQLAlchemy 2.0 + Alembic

### Model Base
```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import DateTime, func
from uuid import uuid4, UUID

class Base(DeclarativeBase):
    pass

class AuditMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    created_by: Mapped[UUID | None] = mapped_column(nullable=True)
```

### Tables for Initial Migration
1. **users** — id (UUID PK), email, password_hash, role (enum), nom, adresse, secteur
2. **medicaments** — id (UUID PK), code_article, designation, dci, dosage, forme, ppa, fabricant
3. **commandes** — id (UUID PK), reference_id (C00...), pharmacien_id (FK), operatrice_id (FK), statut (enum), montant_total, commercial, dates
4. **lignes_commande** — id (UUID PK), commande_id (FK), medicament_id (FK), designation, qte_demandee, prix_unitaire, n_lot
5. **factures** — id (UUID PK), reference_id, commande_id (FK), montant_ht, montant_ttc, date_emission
6. **bons_livraison** — id (UUID PK), commande_id (FK), code_barre, date_emission
7. **feuilles_route** — id (UUID PK), camion_id, date, ligne, n_rotation, compteurs (JSONB), signatures
8. **audit_log** — id (UUID PK), entity_type, entity_id, action, actor_id, timestamp, old_value (JSONB), new_value (JSONB)

### Enum for Order Status
```python
class OrderStatus(str, Enum):
    CREEE = "creee"
    ACCEPTEE = "acceptee"
    ANNULEE = "annulee"
    EN_PREPARATION = "en_preparation"
    PRELEVEE_PARTIELLEMENT = "prelevee_partiellement"
    EN_VERIFICATION = "en_verification"
    PRETE = "prete"
    EN_ROUTE = "en_route"
    LIVREE = "livree"
    REFUSEE = "refusee"
    RETOURNEE = "retournee"
    LIVREE_PARTIELLEMENT = "livree_partiellement"
```

### Alembic Setup
- `alembic init` with async support
- `env.py` configured with SQLAlchemy async engine
- `alembic.ini` points to DATABASE_URL from env var
- First migration: all M1 tables

## Biome + Ruff + Lefthook

### Biome (JS/TS)
- `biome.json` at root — lint + format config
- Replaces ESLint + Prettier
- Run: `pnpm biome check --write .`

### Ruff (Python)
- `ruff.toml` or section in `pyproject.toml` in apps/api/
- Rules: E, F, I (isort), UP (pyupgrade), B (bugbear)
- Format: `ruff format .`

### Lefthook (pre-commit)
```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    biome:
      glob: "*.{js,jsx,ts,tsx,json}"
      run: pnpm biome check --write {staged_files}
    ruff-check:
      glob: "*.py"
      run: cd apps/api && ruff check {staged_files}
    ruff-format:
      glob: "*.py"
      run: cd apps/api && ruff format --check {staged_files}
```

## Validation Architecture

### Test Strategy for Phase 10
1. **Infrastructure tests**: `docker compose up -d` succeeds, all healthchecks pass
2. **Migration tests**: `alembic upgrade head` on fresh DB, `alembic downgrade base` + `upgrade head` roundtrip
3. **Model tests**: SQLAlchemy models can be instantiated, UUID PKs generated, audit columns populated
4. **Lint tests**: `biome check` and `ruff check` pass on all code

### Verification Commands
```bash
# Turborepo
turbo dev --dry-run  # Verify task graph

# Docker
docker compose up -d && docker compose ps  # All services running
docker compose exec api curl -f http://localhost:8000/health  # API healthcheck

# Alembic
docker compose exec api alembic upgrade head  # Migration runs
docker compose exec api alembic downgrade base  # Rollback works

# Linting
pnpm biome check .  # JS/TS
cd apps/api && ruff check .  # Python
```

---
*Research completed: 2026-03-23 for Phase 10*
