from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def next_reference(db: AsyncSession, prefix: str, seq_name: str, pad: int = 8) -> str:
    """Generate next reference ID from a PostgreSQL sequence."""
    result = await db.execute(text(f"SELECT nextval('{seq_name}')"))
    seq_val = result.scalar()
    return f"{prefix}{seq_val:0{pad}d}"


async def next_commande_ref(db: AsyncSession) -> str:
    return await next_reference(db, "C", "commande_seq")


async def next_facture_ref(db: AsyncSession) -> str:
    return await next_reference(db, "F", "facture_seq", pad=10)


async def next_bl_ref(db: AsyncSession) -> str:
    return await next_reference(db, "BL", "bl_seq")


async def next_prelevement_ref(db: AsyncSession) -> str:
    return await next_reference(db, "P", "prelevement_seq")


async def next_colis_ref(db: AsyncSession) -> str:
    return await next_reference(db, "CLS", "colis_seq")
