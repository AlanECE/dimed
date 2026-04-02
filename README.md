# DIMED -- Gestion Logistique Pharmaceutique

Plateforme de gestion logistique pour la distribution pharmaceutique. Gere le cycle complet : catalogue medicaments, commandes, preparation, controle, livraison, facturation, creances et reclamations.

## Tech Stack

| Couche | Technologies |
|--------|-------------|
| **Frontend** | Next.js 15 (App Router), React 19, TypeScript, Tailwind CSS 4, shadcn/ui |
| **Backend** | FastAPI, SQLAlchemy 2.0 (async), Pydantic v2 |
| **Base de donnees** | PostgreSQL 16 |
| **Cache / Sessions** | Redis 7 |
| **Auth** | JWT httponly cookies (access + refresh), 6 roles |
| **Monorepo** | pnpm 9 + Turborepo |
| **Infra** | Docker Compose |

## Structure du projet

```
dimed/
  apps/
    web/          # Frontend Next.js
    api/          # Backend FastAPI
    storage/      # Fichiers statiques (images, documents)
    mobile/       # App mobile (a venir)
  docker/         # Docker Compose + Dockerfiles
  packages/       # Packages partages
```

## Prerequisites

- **Node.js** >= 20
- **pnpm** >= 9
- **Python** >= 3.12
- **Docker** & Docker Compose

## Installation

```bash
# 1. Cloner le repo
git clone https://github.com/hichembenamara/dimed.git
cd dimed

# 2. Installer les dependances frontend
pnpm install

# 3. Lancer les services (PostgreSQL + Redis)
docker compose -f docker/docker-compose.yml up -d db redis

# 4. Configurer le backend
cd apps/api
cp .env.example .env  # ajuster les variables
uv sync
alembic upgrade head
cd ../..
```

## Developpement

```bash
# Tout lancer (frontend :3000 + API :8000)
pnpm dev

# Frontend seul
cd apps/web && pnpm dev

# Backend seul
cd apps/api && uvicorn app.main:app --reload

# Avec Docker (tout inclus)
docker compose -f docker/docker-compose.yml up
```

## Roles utilisateur

| Role | Description |
|------|------------|
| `admin` | Administration complete, gestion utilisateurs, rapports |
| `pharmacien` | Validation commandes, supervision |
| `operatrice` | Saisie et suivi des commandes |
| `preparateur` | Preparation physique des commandes |
| `controleur` | Verification des preparations |
| `livreur` | Livraison et signature electronique |

## Fonctionnalites

- Catalogue medicaments avec gestion de stock et images
- Workflow commandes multi-etapes (saisie -> preparation -> controle -> livraison)
- Generation de documents PDF (factures, bons de livraison, feuilles de route)
- Suivi des creances et reclamations
- Gestion des arrivages fournisseurs
- Journal d'audit complet
- Dashboard avec KPIs et comparaison M/M-1
- Systeme de notifications temps reel

## Lint / Typecheck

```bash
# TypeScript
cd apps/web && npx tsc --noEmit

# Biome (lint + format)
cd apps/web && npx biome check --write .

# Python
cd apps/api && ruff check .
```
