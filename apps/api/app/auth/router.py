import logging
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Cookie, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.auth.google_service import upsert_google_user, verify_google_id_token
from app.auth.schemas import (
    ChangePasswordRequest,
    GoogleAuthRequest,
    LoginRequest,
    ResendVerificationRequest,
    SignupRequest,
    SignupResponse,
    UpdateProfileRequest,
    UserResponse,
    VerifyEmailResponse,
)
from app.auth.service import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_password,
    revoke_all_user_tokens,
    rotate_refresh_token,
    validate_refresh_token,
    verify_password,
)
from app.auth.signup_service import (
    activate_user,
    consume_verification_token,
    create_signup_user,
    create_verification_token,
    email_exists,
    send_verification_email,
)
from app.config import settings
from app.db.session import get_db
from app.models.user import User

logger = logging.getLogger(__name__)

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
        path="/auth",
    )


def _clear_auth_cookies(response: Response) -> None:
    response.delete_cookie("access_token")
    response.delete_cookie("refresh_token", path="/auth")


def _issue_session(response: Response, user: User) -> None:
    access_token = create_access_token(str(user.id), user.role.value, user.email)
    refresh_token = create_refresh_token(str(user.id))
    _set_auth_cookies(response, access_token, refresh_token)


@router.post("/login")
async def login(
    body: LoginRequest,
    response: Response,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> UserResponse:
    result = await db.execute(select(User).where(User.email == body.email.lower()))
    user = result.scalar_one_or_none()

    if not user or not user.password_hash or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid_credentials",
        )

    if not user.is_email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="email_not_verified",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="account_disabled",
        )

    _issue_session(response, user)
    return UserResponse.model_validate(user)


@router.post("/signup", response_model=SignupResponse)
async def signup(
    body: SignupRequest,
    background_tasks: BackgroundTasks,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> SignupResponse:
    generic_response = SignupResponse(
        message="Un email de verification vient d'etre envoye si l'adresse est disponible."
    )

    if await email_exists(db, body.email):
        # Do not leak which emails are registered
        return generic_response

    user = await create_signup_user(db, body)
    token = create_verification_token(user.id)

    async def _send() -> None:
        try:
            await send_verification_email(user, token)
        except Exception:  # noqa: BLE001
            logger.exception("Background email send failed for %s", user.email)

    background_tasks.add_task(_send)
    return generic_response


@router.get("/verify-email", response_model=VerifyEmailResponse)
async def verify_email(
    token: str,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> VerifyEmailResponse:
    user_id = consume_verification_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="invalid_or_expired_token",
        )

    user = await activate_user(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="user_not_found",
        )

    return VerifyEmailResponse(message="Compte active avec succes")


@router.post("/resend-verification", response_model=SignupResponse)
async def resend_verification(
    body: ResendVerificationRequest,
    background_tasks: BackgroundTasks,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> SignupResponse:
    generic_response = SignupResponse(
        message="Si un compte non verifie existe, un nouvel email a ete envoye."
    )

    result = await db.execute(select(User).where(User.email == body.email.lower()))
    user = result.scalar_one_or_none()
    if not user or user.is_email_verified:
        return generic_response

    token = create_verification_token(user.id)

    async def _send() -> None:
        try:
            await send_verification_email(user, token)
        except Exception:  # noqa: BLE001
            logger.exception("Background email send failed for %s", user.email)

    background_tasks.add_task(_send)
    return generic_response


@router.post("/google")
async def google_auth(
    body: GoogleAuthRequest,
    response: Response,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> UserResponse:
    info = verify_google_id_token(body.credential)
    user = await upsert_google_user(db, info, body)
    _issue_session(response, user)
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

    user_id: str | None = None

    if access_token:
        try:
            payload = decode_access_token(access_token)
            user_id = payload.get("sub")
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
        if user_id:
            redis_client.srem(f"user_tokens:{user_id}", refresh_token)

    _clear_auth_cookies(response)

    return {"message": "Logged out"}


@router.get("/me")
async def me(current_user: CurrentUser) -> UserResponse:
    return UserResponse.model_validate(current_user)


@router.patch("/me")
async def update_profile(
    body: UpdateProfileRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> UserResponse:
    update_data = body.model_dump(exclude_unset=True)
    if not update_data:
        return UserResponse.model_validate(current_user)

    for field, value in update_data.items():
        setattr(current_user, field, value)

    db.info["actor_id"] = str(current_user.id)
    await db.commit()
    await db.refresh(current_user)
    return UserResponse.model_validate(current_user)


@router.post("/change-password")
async def change_password(
    body: ChangePasswordRequest,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    if not current_user.password_hash or not verify_password(
        body.current_password, current_user.password_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )

    current_user.password_hash = hash_password(body.new_password)
    db.info["actor_id"] = str(current_user.id)
    await db.commit()

    # Revoke all existing refresh tokens so stolen tokens become invalid
    revoke_all_user_tokens(str(current_user.id))

    return {"message": "Password changed successfully"}
