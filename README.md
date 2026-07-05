# DIMED — Gestion Logistique Pharmaceutique

Plateforme de gestion logistique pour **DIMED**, grossiste-répartiteur pharmaceutique algérien. Elle couvre le cycle de vie complet d'une commande pharmacien : saisie, préparation avec OCR des vignettes, contrôle, colisage QR, expédition par zones, livraison signée, facturation (proforma → facture), créances et réclamations.

## Contexte métier

DIMED distribue des médicaments aux pharmacies via des **lignes de route** (camions) couvrant des secteurs géographiques. Chaque commande traverse une chaîne de métiers distincts — chacun a sa propre interface et ne voit que ce qui le concerne. La traçabilité est au cœur du système : chaque carton (colis) porte un QR code unique scanné à chaque étape (colisage, dépôt en zone d'expédition, chargement camion, livraison), et chaque action est journalisée (audit log + scans).

## Workflow de bout en bout

```
Pharmacien / Opératrice          crée la commande (catalogue, quantités)
        │                                statut: creee
        ▼
Opératrice                       accepte (ou refuse avec motif → retour pharmacien)
        │                        → facture PROFORMA générée
        │                        → ligne de livraison héritée de la fiche client
        │                                statut: acceptee
        ▼
Préparateur                      prend un caddie, prélève les articles
        │                        → scan OCR de la vignette (lot, fab, exp, PPA)
        │                                statut: en_preparation
        ▼
Contrôleur                       recompte à l'aveugle, fixe le nombre de colis
        │                        → colis QR créés (CLS…), étiquettes PDF
        │                        → contenu de chaque colis renseignable
        │                        → la proforma devient FACTURE définitive
        │                                statut: prete
        ▼
Facturier                        notifié → imprime factures + étiquettes QR
        ▼
Magasinier                       scanne tous les cartons d'une commande
        │                        → dépose sur une ZONE D'EXPÉDITION (enregistrée)
        ▼
Livreur (1 par ligne/camion)     scanne chaque carton au chargement
        │                        → dernier carton scanné ⇒ statut: en_route
        ▼
Livraison                        re-scan des colis + signature électronique
                                 pharmacien (+ bon de livraison papier)
                                         statut: livree
```

Les refus/annulations sont possibles à chaque étape avec motif tracé. Les états sont gérés par une machine à états stricte (`apps/api/app/models/state_machine.py`) — **ne jamais la contourner**.

## Tech Stack

| Couche | Technologies |
|--------|-------------|
| **Frontend** | Next.js 15 (App Router), React 19, TypeScript, Tailwind CSS 4, shadcn/ui |
| **Backend** | FastAPI, SQLAlchemy 2.0 (async), Pydantic v2, Alembic |
| **Base de données** | PostgreSQL 16 (+ pg_trgm pour la recherche floue) |
| **Cache / Sessions** | Redis 7 |
| **OCR vignettes** | OpenRouter — modèle vision `baidu/ernie-4.5-vl-424b-a47b` (~0,08 ¢/scan) |
| **QR codes** | jsQR (scan caméra côté client) + qrcode/reportlab (génération PDF) |
| **PDF** | reportlab (factures, BL, étiquettes A6, feuilles de route) |
| **Auth** | JWT httponly cookies (access + refresh), 8 rôles, Google OAuth optionnel |
| **Monorepo** | pnpm 9 + Turborepo |
| **Infra** | Docker Compose (db, redis, api, web, mailhog) |

## Structure du projet

```
dimed/
  apps/
    web/                    # Frontend Next.js
      app/(authenticated)/  # Une page par métier (preparation, verification,
                            #   magasinier, facturier, livraison, dashboard…)
      components/           # UI partagée (qr-scanner, vignette-capture-dialog…)
      hooks/                # Un hook par domaine API (use-orders, use-expedition…)
      lib/types.ts          # Types miroirs des schemas API
    api/                    # Backend FastAPI
      app/
        commandes/          # Cycle de vie commande (router + service + state machine)
        expedition/         # Colis QR, zones d'expédition, scans, répartition
        documents/          # Factures/proforma, BL, feuilles de route, PDF
        ocr/                # Extraction vignettes via OpenRouter (lot/fab/exp/ppa)
        models/             # SQLAlchemy (commande, colis, user, medicament…)
      alembic/versions/     # Migrations numérotées 001..018
      tests/                # pytest (intégration contre API live)
    storage/                # Fichiers générés (PDF, images vignettes)
  docker/                   # docker-compose.yml + Dockerfiles
```

## Prérequis

- **Node.js** ≥ 20, **pnpm** ≥ 9
- **Python** ≥ 3.12 (+ `uv` ou venv)
- **Docker** & Docker Compose

## Installation

```bash
# 1. Cloner le repo
git clone https://github.com/hichembenamara/dimed.git
cd dimed

# 2. Installer les dépendances frontend
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

### Variables d'environnement clés (préfixe `DIMED_`)

| Variable | Rôle |
|----------|------|
| `DIMED_DATABASE_URL` | PostgreSQL (async : `postgresql+asyncpg://…`) |
| `DIMED_REDIS_URL` | Redis |
| `DIMED_OPENROUTER_API_KEY` | **Requis pour l'OCR** des vignettes (clé openrouter.ai) |
| `DIMED_OCR_MODEL` | Modèle vision (défaut : `baidu/ernie-4.5-vl-424b-a47b`) |
| `DIMED_SECRET_KEY` | Signature JWT (obligatoire en production) |

> ⚠️ Avec Docker Compose, le fichier `.env` lu pour la substitution est celui **du dossier `docker/`** (ou passez `--project-directory .`). La clé OCR doit y figurer sinon le scan vignette renverra « DIMED_OPENROUTER_API_KEY is not set ».

## Développement

```bash
# Tout lancer (frontend :3000 + API :8000)
pnpm dev

# Frontend seul
cd apps/web && pnpm dev

# Backend seul
cd apps/api && uvicorn app.main:app --reload

# Avec Docker (tout inclus, hot-reload monté en volume)
docker compose -f docker/docker-compose.yml up
```

Comptes de démo seedés au démarrage (mot de passe `dimed`) : `admin@`, `pharmacien@`, `operatrice@`, `preparateur@`, `controleur@`, `magasinier@`, `facturier@`, `livreur1..8@dimed.dz` (un livreur par ligne de route).

## Rôles utilisateur

| Rôle | Interface | Description |
|------|-----------|-------------|
| `admin` | Tout | Administration, utilisateurs (dont ligne de livraison des fiches clients), rapports, journal |
| `pharmacien` | Catalogue, commandes, statistiques | Client : commande, suit ses factures/créances, consulte ses stats (CA, remises) |
| `operatrice` | Dashboard | Saisie/acceptation/refus des commandes, remises, routes |
| `preparateur` | Préparation | Prélèvement par caddie + **scan OCR des vignettes** |
| `controleur` | Vérification | Recomptage à l'aveugle, nb de colis, **contenu des colis**, étiquettes QR |
| `facturier` | Facturier | Notifié au contrôle : imprime factures + étiquettes QR |
| `magasinier` | Zone d'expédition | Scanne les cartons, dépose par **zone d'expédition** |
| `livreur` | Livraisons | Tournée du jour, scan chargement/livraison, signature |

## Fonctionnalités

- Catalogue médicaments : stock, images, **indicateur TVA / hors TVA par produit**
- Workflow commandes multi-étapes avec machine à états stricte et notifications
- **OCR des vignettes pharmaceutiques** (photo → lot, date fab, date exp, PPA) avec avertissements de divergence — le préparateur garde la main
- **Facture proforma** à l'acceptation, régénérée en **facture définitive** au contrôle ; remise par ligne (R%) + remise totale affichées
- Colis tracés par QR : étiquettes A6, contenu par colis consultable au scan, journal des scans
- **Zones d'expédition** : le magasinier choisit la zone au dépôt, visible par tous
- Ligne de livraison portée par la **fiche client** — héritée automatiquement à l'acceptation (plus de ressaisie)
- Livraison : re-scan des colis + signature électronique du pharmacien
- Créances, réclamations, arrivages fournisseurs, journal d'audit complet
- Dashboards KPI (CA, commandes, panier moyen, taux de livraison, **remises accordées**) avec comparaison M/M-1 — accessibles aussi au pharmacien (données filtrées)

## Tests & Qualité

```bash
# Backend — suite d'intégration (nécessite db+redis+API lancés)
cd apps/api && pytest

# TypeScript
cd apps/web && pnpm typecheck

# Lint / format
cd apps/web && npx biome check --write .
cd apps/api && ruff check .
```

Un hook lefthook (biome + ruff) tourne au pre-commit.

## Best practices — contributions (humains & IA)

Si un agent IA (ou un nouveau contributeur) modifie ce repo, respecter ces règles :

1. **Ne pas toucher `OrderStatus` ni `app/models/state_machine.py`** sans discussion : tout le workflow inter-métiers en dépend. Les états des colis (`ColisStatus`) sont orthogonaux aux états de commande.
2. **Migrations Alembic numérotées** (`018_...py` → la suivante est `019_...py`), `down_revision` chaîné, toujours idempotentes quand possible (`IF NOT EXISTS`). Les valeurs d'enum PostgreSQL ne se suppriment pas en downgrade.
3. **Contrôle des rôles inline dans chaque endpoint** (pattern existant : `if current_user.role.value not in (...)`) — pas de nouveau système d'autorisation.
4. **Toute écriture passe par `db.info["actor_id"]`** avant commit pour alimenter le journal d'audit.
5. **Frontend : un hook par domaine** (`hooks/use-*.ts`) qui encapsule `fetchApi`, types dans `lib/types.ts` en miroir des schemas Pydantic. Pas d'appel `fetch` brut dans les pages.
6. **UI : suivre les patterns shadcn/ui existants** (tables, dialogs, toasts sonner, badges de statut via `StatusBadge`). Tailwind uniquement, pas de CSS ad hoc.
7. **PDF : tout passe par `documents/pdf_generator.py`** (reportlab). Les factures sont régénérées de façon lazy — ne jamais supposer qu'un fichier sur disque est à jour.
8. **Vérifier en réel avant de livrer** : lancer la stack, dérouler le workflow complet (création → livraison) via l'UI ou un script E2E, puis `pytest` + `pnpm typecheck` + lint. Les tests d'intégration tournent contre l'API vivante.
9. **Ne pas committer** : dumps SQL, fichiers de specs (PDF/docx), logs, `.env`.
10. **Commits conventionnels** (`feat(scope): …`, `fix: …`) et PR vers `master` de `hichembenamara/dimed` depuis une branche `feat/…`.

## Limites connues / hors périmètre

- **Lien S4 ↔ S5** (synchronisation bidirectionnelle avec le système de facturation S4) : non développé — S4 communiquera par API ultérieurement.
- Photos produits du catalogue : à fournir (suivi métier).
- L'app mobile (`apps/mobile/`) est un emplacement réservé.
