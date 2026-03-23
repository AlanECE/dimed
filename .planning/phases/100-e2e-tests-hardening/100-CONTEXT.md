# Phase 100: E2E Tests & Hardening - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Tests d'intégration E2E couvrant tous les modules M1 (auth, médicaments, commandes, documents, notifications, camions), Dockerfiles prod multi-stage hardened, et sécurisation de l'API (CORS, rate limiting, validation, headers). Pas de tests browser — uniquement tests API avec pytest + httpx.

</domain>

<decisions>
## Implementation Decisions

### Tests E2E — Scope
- **Couverture large** : tous les modules M1 (auth, médicaments, commandes, documents, notifications, camions, feuilles de route)
- **Tests API uniquement** (pytest + httpx AsyncClient) — pas de tests browser/Playwright
- **BDD dédiée test** : Docker Compose lance un PostgreSQL séparé pour les tests, migrations appliquées, BDD vide à chaque suite
- Flow principal testé de bout en bout : login → créer commande → accept → vérifier facture/BL générés → vérifier notification créée

### Tests E2E — Modules à couvrir
1. **Auth** : login/logout, refresh token, accès refusé par rôle, session expirée
2. **Médicaments** : import, search fuzzy, pagination
3. **Commandes** : créer, lister, accept, reject, cancel, state machine (transitions invalides rejetées)
4. **Documents** : facture générée à l'acceptation, BL avec barcode, route sheet
5. **Notifications** : notification créée aux 4 statuts, GET list, mark read, mark all read
6. **Camions** : CRUD complet, assign-camion, feuille de route auto-créée

### Docker prod hardening
- **Multi-stage builds** : stage builder (install deps) + stage runtime (copie seule)
- **Images de base** : python:3.12-slim (API), node:22-slim (Web) — pas Alpine (compat OpenCV pour M2)
- **Non-root user** : créer `appuser` dans le Dockerfile, RUN as appuser
- **Health checks** : `HEALTHCHECK CMD curl -f http://localhost:PORT/health`
- **.dockerignore** : exclure .git, node_modules, __pycache__, .planning, etc.
- **CMD exec form** : `CMD ["uvicorn", "app.main:app"]` pas `CMD uvicorn...`
- **Pas de scan automatisé** en CI (déploiement interne) — scan manuel ponctuel si besoin

### Sécurité API — CORS
- CORS stricte : origines autorisées = `http://localhost:3000` en dev, domaine prod configurable via env var
- Cookies SameSite=Lax déjà en place (Phase 20)
- Methods autorisées : GET, POST, PATCH, DELETE
- Credentials: true (cookies httpOnly)

### Sécurité API — Rate limiting
- Rate limiting sur `/auth/login` : 5 tentatives / minute par IP
- Rate limiting global : 100 requêtes / minute par user authentifié
- Bibliothèque : slowapi (basée sur limits, standard FastAPI)
- Réponse 429 Too Many Requests avec header Retry-After

### Sécurité API — Validation inputs
- Audit des schemas Pydantic : ajouter `max_length` sur les champs string, `ge=0` sur les quantités
- Vérifier qu'aucun champ n'accepte du HTML/SQL brut sans sanitization
- Valider les UUIDs en entrée (déjà fait par Pydantic/FastAPI UUID type)
- Limiter `limit` query param à `le=100` (déjà fait)

### Sécurité API — Headers
- Next.js headers sécurité dans `next.config.js` :
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `X-DNS-Prefetch-Control: off`
- Strict-Transport-Security en prod uniquement (HTTPS)

### Claude's Discretion
- Fixtures et factory patterns pour les tests
- Organisation des fichiers de test (par module ou par flow)
- Exact rate limit numbers (ajustables)
- docker-compose.test.yml structure
- CSP header detail (si applicable)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend existant
- `apps/api/app/main.py` — Point d'entrée FastAPI, tous les routers inclus (ajouter CORS middleware ici)
- `apps/api/app/auth/router.py` — Login endpoint (rate limiting cible)
- `apps/api/app/auth/dependencies.py` — CurrentUser dependency (tester auth refusée)
- `apps/api/app/commandes/router.py` — Endpoints commandes (flow E2E principal)
- `apps/api/app/commandes/service.py` — transition_order + notification hook (vérifier en E2E)
- `apps/api/app/documents/service.py` — Génération facture/BL (vérifier en E2E)
- `apps/api/app/notifications/router.py` — Endpoints notifications (tester CRUD)
- `apps/api/app/camions/router.py` — CRUD camions + assign
- `apps/api/app/models/` — Tous les modèles (pour les fixtures)

### Docker existant
- `apps/api/Dockerfile` — Dockerfile API actuel (à hardener)
- `apps/web/Dockerfile` — Dockerfile Web actuel (à hardener)
- `docker-compose.yml` — Compose dev actuel (ajouter compose test)

### Frontend
- `apps/web/next.config.ts` — Config Next.js (ajouter headers sécurité)

### CDC
- `CDC_Module1_Commande.docx` — Exigences fonctionnelles M1 (référence pour les scénarios de test)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `apps/api/app/cli.py` — CLI existant (create-admin) — pattern pour seed de test data
- `apps/api/app/db/session.py` — async_sessionmaker pattern (à réutiliser dans les fixtures)
- `apps/api/alembic/` — Migrations existantes (appliquer dans le setup test)

### Established Patterns
- Auth par cookies httpOnly — tous les tests doivent manipuler les cookies
- `Annotated[AsyncSession, Depends(get_db)]` — dependency injection pattern
- Toutes les responses utilisent des Pydantic models (validation input gratuite)

### Integration Points
- `apps/api/app/main.py` — Ajouter CORSMiddleware et rate limiter
- `docker-compose.yml` — Ajouter service test DB ou docker-compose.test.yml séparé
- `apps/web/next.config.ts` — Ajouter headers array

</code_context>

<specifics>
## Specific Ideas

- Les tests E2E sont des tests d'intégration API, pas des tests unitaires ni des tests browser
- Chaque test repart d'une BDD propre (ou au minimum d'un state connu)
- Le flow principal (commande → validation → documents → notification) est LE test critique
- Le hardening Docker est pour un déploiement interne — pas besoin d'être au niveau PCI-DSS

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 100-e2e-tests-hardening*
*Context gathered: 2026-03-23*
