import logging
from contextlib import asynccontextmanager
from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import select, text

from app.admin.router import router as admin_router
from app.arrivages.router import router as arrivages_router
from app.audit.router import router as audit_router
from app.auth.router import router as auth_router
from app.auth.service import hash_password
from app.camions.router import router as camions_router
from app.commandes.router import router as commandes_router
from app.creances.router import router as creances_router
from app.db.session import async_session, engine
from app.documents.router import router as documents_router
from app.medicaments.router import router as medicaments_router
from app.models.user import User, UserRole
from app.notifications.router import router as notifications_router
from app.reclamations.router import router as reclamations_router

logger = logging.getLogger(__name__)

_SEED_PASSWORD = "dimed"
_SEED_USERS = [
    (UserRole.ADMIN, "admin@dimed.dz", "Admin DIMED"),
    (UserRole.PHARMACIEN, "pharmacien@dimed.dz", "Pharmacien Demo"),
    (UserRole.OPERATRICE, "operatrice@dimed.dz", "Operatrice Demo"),
    (UserRole.PREPARATEUR, "preparateur@dimed.dz", "Preparateur Demo"),
    (UserRole.CONTROLEUR, "controleur@dimed.dz", "Controleur Demo"),
    (UserRole.LIVREUR, "livreur@dimed.dz", "Livreur Demo"),
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.execute(text("SELECT 1"))
    # Seed one user per role if no users exist
    async with async_session() as session:
        result = await session.execute(select(User).limit(1))
        if result.scalar_one_or_none() is None:
            hashed = hash_password(_SEED_PASSWORD)
            for role, email, nom in _SEED_USERS:
                session.add(
                    User(
                        id=uuid4(),
                        email=email,
                        password_hash=hashed,
                        role=role,
                        nom=nom,
                        is_active=True,
                    )
                )
            await session.commit()
            logger.info("Seeded %d users (password: %s)", len(_SEED_USERS), _SEED_PASSWORD)
    yield
    await engine.dispose()


app = FastAPI(
    title="DIMED API",
    version="0.1.0",
    description="Pharmaceutical logistics management",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(admin_router, prefix="/admin", tags=["admin"])
app.include_router(audit_router, prefix="/admin", tags=["audit"])
app.include_router(camions_router, prefix="/camions", tags=["camions"])
app.include_router(commandes_router, prefix="/commandes", tags=["commandes"])
app.include_router(documents_router, prefix="/documents", tags=["documents"])
app.include_router(medicaments_router, prefix="/medicaments", tags=["medicaments"])
app.include_router(creances_router, prefix="/creances", tags=["creances"])
app.include_router(notifications_router, prefix="/notifications", tags=["notifications"])
app.include_router(reclamations_router, prefix="/reclamations", tags=["reclamations"])
app.include_router(arrivages_router, prefix="/arrivages", tags=["arrivages"])


# Serve uploaded images
_storage = Path(__file__).resolve().parents[2] / "storage"
_storage.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=str(_storage)), name="static")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "dimed-api"}
