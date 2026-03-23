from typing import Annotated

from fastapi import APIRouter, Cookie, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.auth.schemas import LoginRequest, UserResponse
from app.auth.service import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    rotate_refresh_token,
    validate_refresh_token,
    verify_password,
)
from app.config import settings
from app.db.session import get_db
from app.models.user import User

router = APIRouter()


def _set_auth_cookies(response: Response, access_token: str, refresh_token: str) -> None:
    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,
        secure=settings.cookie_secure,
        samesite="lax",
        max_age=settings.access_token_expire_minutes * 60,
    )
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        secure=settings.cookie_secure,
        samesite="lax",
        max_age=settings.refresh_token_expire_days * 24 * 60 * 60,
        path="/auth/refresh",
    )


def _clear_auth_cookies(response: Response) -> None:
    response.delete_cookie("access_token")
    response.delete_cookie("refresh_token", path="/auth/refresh")


@router.post("/login")
async def login(
    body: LoginRequest,
    response: Response,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> UserResponse:
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account is disabled",
        )

    access_token = create_access_token(str(user.id), user.role.value, user.email)
    refresh_token = create_refresh_token(str(user.id))

    _set_auth_cookies(response, access_token, refresh_token)

    return UserResponse.model_validate(user)


@router.post("/refresh")
async def refresh(
    response: Response,
    refresh_token: Annotated[str | None, Cookie()] = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    if not refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token missing",
        )

    user_id = validate_refresh_token(refresh_token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or disabled",
        )

    new_access = create_access_token(str(user.id), user.role.value, user.email)
    new_refresh = rotate_refresh_token(refresh_token, str(user.id))

    _set_auth_cookies(response, new_access, new_refresh)

    return {"message": "Tokens refreshed"}


@router.post("/logout")
async def logout(
    response: Response,
    access_token: Annotated[str | None, Cookie()] = None,
    refresh_token: Annotated[str | None, Cookie()] = None,
) -> dict:
    from app.auth.service import blacklist_token, redis_client

    if access_token:
        try:
            payload = decode_access_token(access_token)
            jti = payload.get("jti")
            exp = payload.get("exp", 0)
            if jti:
                import time

                ttl = max(int(exp - time.time()), 1)
                blacklist_token(jti, ttl)
        except Exception:  # noqa: BLE001
            pass

    if refresh_token:
        redis_client.delete(f"refresh:{refresh_token}")

    _clear_auth_cookies(response)

    return {"message": "Logged out"}


@router.get("/me")
async def me(current_user: CurrentUser) -> UserResponse:
    return UserResponse.model_validate(current_user)
