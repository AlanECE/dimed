from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from app.admin.router import router as admin_router
from app.auth.router import router as auth_router
from app.commandes.router import router as commandes_router
from app.db.session import engine
from app.medicaments.router import router as medicaments_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.execute(text("SELECT 1"))
    yield
    await engine.dispose()


app = FastAPI(
    title="DIMED API",
    version="0.1.0",
    description="Pharmaceutical logistics management",
    lifespan=lifespan,
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(admin_router, prefix="/admin", tags=["admin"])
app.include_router(commandes_router, prefix="/commandes", tags=["commandes"])
app.include_router(medicaments_router, prefix="/medicaments", tags=["medicaments"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "dimed-api"}
