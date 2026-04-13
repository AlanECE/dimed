import logging
import secrets
from pathlib import Path
from uuid import UUID

from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.schemas import SignupRequest
from app.auth.service import hash_password, redis_client
from app.config import settings
from app.models.user import User, UserRole

logger = logging.getLogger(__name__)

TEMPLATE_FOLDER = Path(__file__).parent / "templates"

_mail_config = ConnectionConfig(
    MAIL_USERNAME=settings.smtp_username,
    MAIL_PASSWORD=settings.smtp_password,
    MAIL_FROM=settings.smtp_from,
    MAIL_PORT=settings.smtp_port,
    MAIL_SERVER=settings.smtp_host,
    MAIL_FROM_NAME=settings.smtp_from_name,
    MAIL_STARTTLS=settings.smtp_tls,
    MAIL_SSL_TLS=settings.smtp_ssl,
    USE_CREDENTIALS=bool(settings.smtp_username),
    VALIDATE_CERTS=True,
    TEMPLATE_FOLDER=TEMPLATE_FOLDER,
)

_fast_mail = FastMail(_mail_config)


def _verification_key(token: str) -> str:
    return f"verify_email:{token}"


def create_verification_token(user_id: UUID) -> str:
    token = secrets.token_urlsafe(32)
    ttl = settings.email_verification_ttl_hours * 3600
    redis_client.setex(_verification_key(token), ttl, str(user_id))
    return token


def consume_verification_token(token: str) -> UUID | None:
    key = _verification_key(token)
    pipe = redis_client.pipeline()
    pipe.get(key)
    pipe.delete(key)
    raw_user_id, _ = pipe.execute()
    if not raw_user_id:
        return None
    try:
        return UUID(raw_user_id)
    except ValueError:
        return None


async def email_exists(db: AsyncSession, email: str) -> bool:
    result = await db.execute(select(User.id).where(User.email == email.lower()))
    return result.scalar_one_or_none() is not None


async def create_signup_user(db: AsyncSession, payload: SignupRequest) -> User:
    user = User(
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        role=UserRole(payload.role),
        nom=payload.nom,
        adresse=payload.adresse,
        secteur=payload.secteur,
        telephone=payload.telephone,
        oauth_provider="local",
        is_email_verified=False,
        is_active=False,
    )
    db.add(user)
    db.info["actor_id"] = None
    await db.commit()
    await db.refresh(user)
    return user


async def activate_user(db: AsyncSession, user_id: UUID) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        return None
    user.is_email_verified = True
    user.is_active = True
    db.info["actor_id"] = str(user.id)
    await db.commit()
    await db.refresh(user)
    return user


_TEMPLATE_PATH = TEMPLATE_FOLDER / "verification_email.html"


def _render_verification_html(nom: str, verify_url: str, ttl_hours: int) -> str:
    template = _TEMPLATE_PATH.read_text(encoding="utf-8")
    return (
        template.replace("{{ nom }}", nom)
        .replace("{{ verify_url }}", verify_url)
        .replace("{{ ttl_hours }}", str(ttl_hours))
    )


async def send_verification_email(user: User, token: str) -> None:
    verify_url = f"{settings.frontend_url.rstrip('/')}/verify-email?token={token}"
    body_html = _render_verification_html(
        nom=user.nom,
        verify_url=verify_url,
        ttl_hours=settings.email_verification_ttl_hours,
    )
    message = MessageSchema(
        subject="Activez votre compte DIMED",
        recipients=[user.email],
        body=body_html,
        subtype=MessageType.html,
    )
    try:
        await _fast_mail.send_message(message)
    except Exception as exc:  # noqa: BLE001
        logger.exception("Failed to send verification email to %s: %s", user.email, exc)
        raise
