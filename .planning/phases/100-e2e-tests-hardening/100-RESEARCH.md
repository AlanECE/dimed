# Phase 100: E2E Tests & Hardening - Research

**Researched:** 2026-03-23
**Mode:** Ecosystem
**Confidence:** High — standard patterns, well-documented tools

## Standard Stack

| Concern | Solution | New dependency? |
|---------|----------|----------------|
| E2E tests | pytest + httpx AsyncClient + pytest-anyio | Yes: pytest, httpx, pytest-anyio (dev deps) |
| Test DB | docker-compose.test.yml with dedicated PostgreSQL | No (Docker already in project) |
| Rate limiting | slowapi (wraps `limits` library) | Yes: slowapi |
| CORS | FastAPI CORSMiddleware (starlette built-in) | No |
| Security headers | next.config.ts `headers()` | No |
| Docker hardening | Multi-stage Dockerfile (existing base images) | No |

## Architecture Patterns

### Tests E2E : Structure

```
apps/api/tests/
├── conftest.py          # Fixtures: app, client, db, users
├── test_auth.py         # Login, refresh, roles, session
├── test_medicaments.py  # Import, search, pagination
├── test_commandes.py    # Create, accept, reject, cancel, state machine
├── test_documents.py    # Facture + BL auto-generated on accept
├── test_notifications.py # Created on transition, list, mark read
├── test_camions.py      # CRUD, assign-camion, feuille de route
└── test_flow_e2e.py     # Full happy path: login → order → accept → docs → notif
```

### Tests E2E : Fixtures (conftest.py)

```python
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db.base import Base
from app.main import app
from app.db.session import get_db

TEST_DATABASE_URL = "postgresql+asyncpg://test:test@localhost:5433/dimed_test"

@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"

@pytest.fixture(scope="session")
async def engine():
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()

@pytest.fixture
async def db(engine):
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session
        await session.rollback()

@pytest.fixture
async def client(db):
    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
    app.dependency_overrides = {}
```

**Pattern clé :** `app.dependency_overrides[get_db]` pour injecter la session de test. Chaque test rollback sa transaction = isolation parfaite.

### Tests E2E : Helper pour auth

```python
# conftest.py — suite
from app.models.user import User, UserRole
from uuid import uuid4
import bcrypt

async def create_test_user(db: AsyncSession, role: UserRole, email: str = None) -> User:
    email = email or f"{role.value}_{uuid4().hex[:6]}@test.com"
    hashed = bcrypt.hashpw("testpass123".encode(), bcrypt.gensalt()).decode()
    user = User(id=uuid4(), email=email, nom="Test", prenom=role.value,
                role=role, hashed_password=hashed, is_active=True)
    db.add(user)
    await db.flush()
    return user

async def login_as(client: AsyncClient, email: str, password: str = "testpass123") -> dict:
    response = await client.post("/auth/login", json={"email": email, "password": password})
    assert response.status_code == 200
    # Cookies are automatically stored on the client
    return response.json()

@pytest.fixture
async def pharmacien(db):
    return await create_test_user(db, UserRole.PHARMACIEN)

@pytest.fixture
async def operatrice(db):
    return await create_test_user(db, UserRole.OPERATRICE)
```

### Tests E2E : Test pattern

```python
# test_commandes.py
import pytest
from httpx import AsyncClient

@pytest.mark.anyio
async def test_create_order(client: AsyncClient, pharmacien, db):
    await login_as(client, pharmacien.email)

    # Create a medication first
    # ... (or use fixture)

    response = await client.post("/commandes", json={
        "articles": [{"medicament_id": str(med.id), "qte": 5}]
    })
    assert response.status_code == 201
    data = response.json()
    assert data["statut"] == "creee"
    assert data["reference_id"].startswith("C")

@pytest.mark.anyio
async def test_pharmacien_cannot_accept_order(client: AsyncClient, pharmacien, db):
    await login_as(client, pharmacien.email)
    response = await client.patch(f"/commandes/{order_id}/accept")
    assert response.status_code == 403
```

### CORS : Configuration

```python
# apps/api/app/main.py
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,  # ["http://localhost:3000"] en dev
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["*"],
)
```

Config via env var :
```python
# app/config.py
cors_origins: list[str] = ["http://localhost:3000"]  # override via CORS_ORIGINS env
```

**IMPORTANT :** `allow_credentials=True` + `allow_origins=["*"]` est interdit par les browsers. Toujours lister les origines explicitement.

### Rate Limiting : slowapi

```python
# apps/api/app/main.py
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Dans le router auth :
from app.main import limiter

@router.post("/login")
@limiter.limit("5/minute")
async def login(request: Request, body: LoginRequest, ...):
    ...
```

**Note :** slowapi nécessite que `request: Request` soit explicitement dans les args de l'endpoint. C'est déjà le cas pour les endpoints auth mais il faut vérifier.

**Alternative sans dépendance :** Un simple middleware maison avec un dict `{ip: (count, window_start)}` suffit pour le cas DIMED (déploiement interne, peu d'utilisateurs). Mais slowapi est plus robuste.

### Security Headers : Next.js

```typescript
// apps/web/next.config.ts
const nextConfig = {
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-DNS-Prefetch-Control", value: "off" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
        ],
      },
    ];
  },
};
```

**Pas de CSP complexe en v1** — le frontend ne charge que des fonts Google et l'API locale. Un CSP restrictif bloquerait les dev tools. À ajouter en prod si besoin.

### Docker Prod : API (multi-stage)

```dockerfile
# apps/api/Dockerfile.prod
FROM python:3.12-slim AS builder

WORKDIR /build
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev

COPY app ./app

FROM python:3.12-slim AS runtime

RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/.venv /app/.venv
COPY --from=builder /build/app ./app

ENV PATH="/app/.venv/bin:$PATH"
USER appuser

HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8000/health || exit 1
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Prod : Web (multi-stage)

```dockerfile
# apps/web/Dockerfile.prod
FROM node:22-slim AS builder

WORKDIR /build
RUN corepack enable pnpm
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:22-slim AS runtime

RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/.next/standalone ./
COPY --from=builder /build/.next/static ./.next/static
COPY --from=builder /build/public ./public

USER appuser

HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:3000/ || exit 1
EXPOSE 3000
ENV PORT=3000 HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

**Prérequis :** `output: "standalone"` dans next.config.ts pour le standalone build.

### docker-compose.test.yml

```yaml
services:
  test-db:
    image: postgres:16
    environment:
      POSTGRES_DB: dimed_test
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - "5433:5432"
    tmpfs:
      - /var/lib/postgresql/data  # RAM = rapide, pas de persistence
```

`tmpfs` pour la BDD test = pas d'écriture disque, tests plus rapides.

## Don't Hand-Roll

| Problem | Use Instead | Why |
|---------|-------------|-----|
| Test HTTP client | httpx AsyncClient + ASGITransport | Standard FastAPI testing, async native |
| DB test isolation | dependency_overrides[get_db] + rollback | FastAPI documented pattern |
| Rate limiting | slowapi | Wraps `limits`, battle-tested, FastAPI-native |
| CORS | FastAPI CORSMiddleware | Built-in Starlette, well-documented |
| Security headers | next.config.ts `headers()` | Next.js built-in, no middleware needed |
| Docker health checks | HEALTHCHECK CMD curl | Standard, simple, no custom scripts |

## Common Pitfalls

### Tests

1. **AsyncClient sans ASGITransport** — httpx 0.24+ nécessite `ASGITransport(app=app)` explicitement. Sans ça, il essaie de faire de vraies requêtes HTTP.

2. **Lifespan events non déclenchés** — `AsyncClient` ne déclenche PAS les lifespan events (startup/shutdown). Si l'app dépend de `lifespan()`, utiliser `asgi-lifespan.LifespanManager` ou mocker le lifespan.

3. **pg_trgm dans les tests** — L'extension pg_trgm doit être activée dans la BDD de test. Soit via `CREATE EXTENSION IF NOT EXISTS pg_trgm` dans le setup, soit en utilisant les migrations Alembic (recommandé).

4. **Cookie auth dans les tests** — httpx gère les cookies automatiquement si on réutilise le même `AsyncClient`. Pas besoin de manipulation manuelle. Mais attention au scope des fixtures : `client` doit être par test (pas par session) sinon les cookies persistent.

5. **Import order** — Importer `app` avant de configurer `dependency_overrides`. L'app est créée à l'import, les overrides sont appliqués après.

### Rate Limiting

6. **slowapi + async def** — slowapi a eu un bug avec `@limiter.exempt` sur `async def`. Corrigé dans les versions récentes. Utiliser la dernière version.

7. **Request arg obligatoire** — slowapi a besoin de `request: Request` explicitement dans les args de l'endpoint. Si manquant, le rate limiter ne s'accroche pas silencieusement.

### Docker

8. **uv dans Docker** — `uv sync` crée un `.venv` qu'il faut copier dans le stage runtime. Le PATH doit inclure `.venv/bin`.

9. **Next.js standalone** — Nécessite `output: "standalone"` dans next.config.ts. Sans ça, le build ne produit pas `server.js` et le Dockerfile échoue.

10. **HEALTHCHECK + non-root** — `curl` doit être installé dans l'image runtime (slim n'a pas curl par défaut). `apt-get install curl` dans le runtime stage.

### CORS

11. **credentials + wildcard** — `allow_credentials=True` avec `allow_origins=["*"]` est rejeté par les browsers. Toujours lister les origines.

## Verification Checklist

- [ ] `pytest` runs all tests with 0 failures
- [ ] Test covers: auth (login, roles, refresh), médicaments (search), commandes (CRUD + state machine), documents (auto-gen), notifications (create + CRUD), camions (CRUD + assign)
- [ ] Full E2E flow test: login → order → accept → check docs + notification
- [ ] CORS configured with explicit origins
- [ ] Rate limiting on /auth/login (5/min)
- [ ] Security headers present in Next.js responses
- [ ] Dockerfile.prod API: multi-stage, non-root, healthcheck
- [ ] Dockerfile.prod Web: multi-stage, standalone, non-root, healthcheck
- [ ] docker-compose.test.yml works (test DB on port 5433)
- [ ] `docker compose -f docker-compose.test.yml up -d && pytest` passes

---

*Phase: 100-e2e-tests-hardening*
*Researched: 2026-03-23*
