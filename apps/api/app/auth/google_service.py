import logging
from dataclasses import dataclass

from fastapi import HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.schemas import GoogleAuthRequest
from app.config import settings
from app.models.user import User, UserRole

logger = logging.getLogger(__name__)

_request_session = google_requests.Request()


@dataclass(frozen=True)
class GoogleUserInfo:
    sub: str
    email: str
    email_verified: bool
    name: str | None
    picture: str | None


def verify_google_id_token(credential: str) -> GoogleUserInfo:
    if not settings.google_client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="google_oauth_not_configured",
        )
    try:
        info = google_id_token.verify_oauth2_token(
            credential,
            _request_session,
            settings.google_client_id,
        )
    except ValueError as exc:
        logger.warning("Google ID token verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid_google_credential",
        ) from exc

    email = info.get("email")
    sub = info.get("sub")
    if not email or not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid_google_credential",
        )

    return GoogleUserInfo(
        sub=sub,
        email=email.lower(),
        email_verified=bool(info.get("email_verified", False)),
        name=info.get("name"),
        picture=info.get("picture"),
    )


async def upsert_google_user(
    db: AsyncSession,
    info: GoogleUserInfo,
    payload: GoogleAuthRequest,
) -> User:
    # 1. Existing Google user
    result = await db.execute(select(User).where(User.google_id == info.sub))
    user = result.scalar_one_or_none()
    if user:
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="account_disabled",
            )
        return user

    # 2. Existing local account with matching email — link Google
    result = await db.execute(select(User).where(User.email == info.email))
    user = result.scalar_one_or_none()
    if user:
        user.google_id = info.sub
        user.oauth_provider = "both" if user.password_hash else "google"
        user.is_email_verified = True
        if not user.is_active:
            user.is_active = True
        db.info["actor_id"] = str(user.id)
        await db.commit()
        await db.refresh(user)
        return user

    # 3. New account — role required
    if not payload.role:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="role_required",
        )

    user = User(
        email=info.email,
        password_hash=None,
        role=UserRole(payload.role),
        nom=info.name or info.email.split("@")[0],
        adresse=payload.adresse,
        secteur=payload.secteur,
        telephone=payload.telephone,
        google_id=info.sub,
        oauth_provider="google",
        is_email_verified=True,
        is_active=True,
    )
    db.add(user)
    db.info["actor_id"] = None
    await db.commit()
    await db.refresh(user)
    return user
