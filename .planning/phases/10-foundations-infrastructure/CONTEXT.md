# Phase 10 Context: Foundations & Infrastructure

**Phase goal:** Set up the monorepo structure, Docker development environment, and database so all subsequent phases have a solid foundation.

**Requirements:** INFRA-01, INFRA-02, INFRA-03, INFRA-04

## Decisions

### Monorepo Structure

```
dimed/
├── apps/
│   ├── web/                    # Next.js 15 (pnpm)
│   ├── mobile/                 # React Native Expo (pnpm) — scaffold vide
│   └── api/                    # FastAPI (uv)
├── packages/
│   ├── shared-types/           # Types TS partages (pnpm)
│   ├── ui/                     # Composants UI partages (pnpm) — vide pour l'instant
│   └── ocr/                    # Module OCR Python (uv, pyproject.toml standalone)
├── docker/
│   ├── Dockerfile.api          # python:3.12-slim, multi-stage
│   ├── Dockerfile.web          # node:22-slim, multi-stage
│   └── docker-compose.yml      # PostgreSQL 16 + Redis 7 + API + Web
├── turbo.json                  # Turborepo config
├── package.json                # pnpm workspace root
├── pnpm-workspace.yaml         # Workspace definition
├── biome.json                  # Biome config (lint + format JS/TS)
└── .planning/                  # GSD
```

- **JS/TS package manager:** pnpm (workspace natif, standard Turborepo)
- **Python package manager:** uv (rapide, lockfile natif, workspace support)
- **packages/ocr:** Package Python standalone avec son pyproject.toml. Installe comme dependance editable de apps/api (`uv pip install -e ../packages/ocr`)
- **packages/ui:** Cree vide des maintenant (structure prete pour M2 mobile)

### Docker & Environnement Dev

- **Base images:** `python:3.12-slim` (API) + `node:22-slim` (Web). Pas Alpine (compatibilite OpenCV/EasyOCR).
- **Services Docker Compose:** PostgreSQL 16, Redis 7, API (FastAPI), Web (Next.js)
- **Redis inclus des le depart** pour cache session et futur task queue (Celery)
- **Hot reload:** Docker volumes montant le code source + `uvicorn --reload` (API) + `next dev` (Web)
- **Images prod:** Multi-stage builds, non-root user, security scan

### Schema Initial BDD

- **Toutes les tables M1 dans la migration initiale:** User, Commande, LigneCommande, Facture, BonDeLivraison, FeuilleDeRoute, Medicament, AuditLog
- **IDs:** UUID v4 pour toutes les PK. Les IDs metier (C00046488, P00044779) sont des champs separes (reference_id).
- **Audit:** Colonnes created_at, updated_at, created_by sur toutes les entites + table AuditLog append-only
- **Enum statuts commande:** Defini dans la migration initiale (Creee, Acceptee, Annulee, En_preparation, Prelevee_partiellement, En_verification, Prete, En_route, Livree, Refusee, Retournee, Livree_partiellement)
- **ORM:** SQLAlchemy 2.0 (declarative, async support)
- **Migrations:** Alembic avec autogenerate

### CI/CD & Qualite

- **Linting JS/TS:** Biome (remplace ESLint + Prettier en un outil)
- **Linting Python:** Ruff (remplace flake8 + isort + black)
- **Pre-commit hooks:** Lefthook (ou husky) pour lint + typecheck avant commit
- **Pas de GitHub Actions en v1** — on ajoute la CI quand le repo sera sur GitHub
- **Typecheck:** `tsc --noEmit` (TS) + `mypy` ou `pyright` (Python)

## Code Context

- Pas de code existant (greenfield)
- Le module OCR existe dans `~/Desktop/Projets/dimed/` mais sera copie/adapte dans `packages/ocr/`
- Le notebook `ocr/notebook_vignette_ocr.ipynb` contient le POC OCR a refactorer plus tard (M2)

## Deferred Ideas

- GitHub Actions CI pipeline — a ajouter quand le repo est sur GitHub
- Dependabot / Renovate pour les mises a jour de deps
- Monitoring / logging centralise (a considerer en Phase 100)

---
*Created: 2026-03-23 after discuss-phase 10*
