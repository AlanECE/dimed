from datetime import UTC, datetime, timedelta
from uuid import uuid4

import redis
from jose import jwt
from passlib.hash import bcrypt

from app.config import settings

ALGORITHM = "HS256"

redis_client = redis.Redis.from_url(settings.redis_url, decode_responses=True)


def hash_password(password: str) -> str:
    return bcrypt.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.verify(password, password_hash)


def create_access_token(user_id: str, role: str, email: str) -> str:
    jti = str(uuid4())
    payload = {
        "sub": user_id,
        "role": role,
        "email": email,
        "jti": jti,
        "type": "access",
        "exp": datetime.now(UTC) + timedelta(minutes=settings.access_token_expire_minutes),
    }
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def create_refresh_token(user_id: str) -> str:
    token_id = str(uuid4())
    ttl = settings.refresh_token_expire_days * 24 * 60 * 60
    redis_client.setex(f"refresh:{token_id}", ttl, user_id)
    return token_id


def validate_refresh_token(token_id: str) -> str | None:
    return redis_client.get(f"refresh:{token_id}")


def rotate_refresh_token(old_token_id: str, user_id: str) -> str:
    redis_client.delete(f"refresh:{old_token_id}")
    return create_refresh_token(user_id)


def decode_access_token(token: str) -> dict:
    return jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])


def blacklist_token(jti: str, ttl_seconds: int) -> None:
    redis_client.setex(f"blacklisted:{jti}", ttl_seconds, "1")


def is_token_blacklisted(jti: str) -> bool:
    return bool(redis_client.exists(f"blacklisted:{jti}"))
