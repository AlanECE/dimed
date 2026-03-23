from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select

from app.auth.dependencies import CurrentUser
from app.auth.schemas import AdminUserCreate, AdminUserUpdate, UserResponse
from app.auth.service import hash_password
from app.db.session import async_session
from app.models.user import User

router = APIRouter()


def _check_admin(current_user: CurrentUser) -> User:
    if current_user.role.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return current_user


AdminUser = Depends(_check_admin)


@router.post("/users", status_code=status.HTTP_201_CREATED)
async def create_user(
    body: AdminUserCreate,
    _admin: User = AdminUser,  # noqa: B008
) -> UserResponse:
    async with async_session() as db:
        existing = await db.execute(select(User).where(User.email == body.email))
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )

        user = User(
            id=uuid4(),
            email=body.email,
            password_hash=hash_password(body.password),
            role=body.role,
            nom=body.nom,
            adresse=body.adresse,
            secteur=body.secteur,
            is_active=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

        return UserResponse.model_validate(user)


@router.get("/users")
async def list_users(
    _admin: User = AdminUser,  # noqa: B008
    limit: int = 50,
    offset: int = 0,
) -> dict:
    async with async_session() as db:
        result = await db.execute(select(User).offset(offset).limit(limit))
        users = result.scalars().all()

        count_result = await db.execute(select(func.count()).select_from(User))
        total = count_result.scalar()

        return {
            "users": [UserResponse.model_validate(u) for u in users],
            "total": total,
            "limit": limit,
            "offset": offset,
        }


@router.patch("/users/{user_id}")
async def update_user(
    user_id: UUID,
    body: AdminUserUpdate,
    _admin: User = AdminUser,  # noqa: B008
) -> UserResponse:
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        if body.role is not None:
            user.role = body.role
        if body.is_active is not None:
            user.is_active = body.is_active
        if body.nom is not None:
            user.nom = body.nom

        await db.commit()
        await db.refresh(user)

        return UserResponse.model_validate(user)
