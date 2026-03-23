from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from app.db.session import engine


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


@app.get("/health")
async def health():
    return {"status": "ok", "service": "dimed-api"}
