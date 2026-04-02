from pathlib import Path
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.db.session import get_db
from app.models.medicament import Medicament

router = APIRouter()

IMAGES_DIR = Path(__file__).resolve().parents[3] / "storage" / "images" / "medicaments"


class MedicamentResponse(BaseModel):
    id: UUID
    code_article: str
    designation: str
    dci: str | None
    dosage: str | None
    forme: str | None
    ppa: float
    fabricant: str | None
    stock_quantity: int
    image_path: str | None
    featured: bool

    model_config = {"from_attributes": True}


@router.get("/")
async def list_medicaments(
    _user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
    search: str | None = Query(None, min_length=2, description="Fuzzy search on designation"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> dict:
    if search:
        query = (
            select(Medicament)
            .where(func.similarity(Medicament.designation, search) > 0.2)
            .order_by(Medicament.designation.op("<->")(search))
            .limit(limit)
            .offset(offset)
        )
        count_query = (
            select(func.count())
            .select_from(Medicament)
            .where(func.similarity(Medicament.designation, search) > 0.2)
        )
    else:
        query = select(Medicament).order_by(Medicament.designation).limit(limit).offset(offset)
        count_query = select(func.count()).select_from(Medicament)

    result = await db.execute(query)
    medicaments = result.scalars().all()

    count_result = await db.execute(count_query)
    total = count_result.scalar()

    return {
        "medicaments": [MedicamentResponse.model_validate(m) for m in medicaments],
        "total": total,
        "limit": limit,
        "offset": offset,
    }


@router.get("/highlights")
async def get_highlights(
    _user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Get out-of-stock and featured products."""
    # Out of stock
    oos_result = await db.execute(
        select(Medicament)
        .where(Medicament.stock_quantity == 0)
        .order_by(Medicament.designation)
        .limit(50)
    )
    out_of_stock = oos_result.scalars().all()

    # Featured: admin-flagged products, fallback to Cytolab
    feat_result = await db.execute(
        select(Medicament)
        .where(
            Medicament.featured.is_(True),
            Medicament.stock_quantity > 0,
        )
        .order_by(Medicament.designation)
        .limit(12)
    )
    featured = feat_result.scalars().all()

    if not featured:
        feat_result = await db.execute(
            select(Medicament)
            .where(
                Medicament.fabricant.ilike("%cytolab%"),
                Medicament.stock_quantity > 0,
            )
            .order_by(Medicament.designation)
            .limit(12)
        )
        featured = feat_result.scalars().all()

    return {
        "out_of_stock": [MedicamentResponse.model_validate(m) for m in out_of_stock],
        "featured": [MedicamentResponse.model_validate(m) for m in featured],
    }


@router.get("/{medicament_id}")
async def get_medicament(
    medicament_id: UUID,
    _user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> MedicamentResponse:
    result = await db.execute(select(Medicament).where(Medicament.id == medicament_id))
    medicament = result.scalar_one_or_none()

    if not medicament:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicament not found",
        )

    return MedicamentResponse.model_validate(medicament)


@router.post("/{medicament_id}/image")
async def upload_image(
    medicament_id: UUID,
    file: UploadFile,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Upload product image."""
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    result = await db.execute(select(Medicament).where(Medicament.id == medicament_id))
    med = result.scalar_one_or_none()
    if not med:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicament not found",
        )

    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only image files are allowed",
        )

    ext = Path(file.filename or "img.jpg").suffix.lower()
    if ext not in (".jpg", ".jpeg", ".png", ".webp"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Allowed: jpg, png, webp",
        )

    # Read and enforce 5 MB size limit
    max_size = 5 * 1024 * 1024
    contents = await file.read()
    if len(contents) > max_size:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image too large ({len(contents)} bytes). Max: {max_size} bytes",
        )

    # Verify real image format via magic bytes
    if not (
        contents[:8] == b"\x89PNG\r\n\x1a\n"
        or contents[:2] == b"\xff\xd8"
        or contents[:4] == b"RIFF"
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match a valid image format",
        )

    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"{medicament_id}{ext}"
    filepath = IMAGES_DIR / filename

    with open(filepath, "wb") as f:
        f.write(contents)

    db.info["actor_id"] = str(current_user.id)
    med.image_path = f"images/medicaments/{filename}"
    await db.commit()

    return {"image_path": med.image_path}


class UpdateStockRequest(BaseModel):
    stock_quantity: int


@router.patch("/{medicament_id}/stock")
async def update_stock(
    medicament_id: UUID,
    body: UpdateStockRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Update stock quantity for a medicament."""
    if current_user.role.value not in ("operatrice", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    result = await db.execute(select(Medicament).where(Medicament.id == medicament_id))
    med = result.scalar_one_or_none()
    if not med:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicament not found",
        )

    db.info["actor_id"] = str(current_user.id)
    med.stock_quantity = body.stock_quantity
    await db.commit()

    return {
        "id": str(med.id),
        "stock_quantity": med.stock_quantity,
    }


@router.patch("/{medicament_id}/toggle-featured")
async def toggle_featured(
    medicament_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    """Toggle featured status (admin only)."""
    if current_user.role.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin only",
        )

    result = await db.execute(select(Medicament).where(Medicament.id == medicament_id))
    med = result.scalar_one_or_none()
    if not med:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicament not found",
        )

    db.info["actor_id"] = str(current_user.id)
    med.featured = not med.featured
    await db.commit()

    return {
        "id": str(med.id),
        "featured": med.featured,
    }
