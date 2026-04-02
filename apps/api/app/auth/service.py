from datetime import UTC, datetime, timedelta
from uuid import uuid4

import bcrypt as _bcrypt
import redis
from jose import jwt

from app.config import settings

ALGORITHM = "HS256"

redis_client = redis.Redis.from_url(settings.redis_url, decode_responses=True)


def hash_password(password: str) -> str:
    return _bcrypt.hashpw(password.encode(), _bcrypt.gensalt()).decode()


def verify_password(password: str, password_hash: str) -> bool:
    return _bcrypt.checkpw(password.encode(), password_hash.encode())


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
    redis_client.sadd(f"user_tokens:{user_id}", token_id)
    redis_client.expire(f"user_tokens:{user_id}", ttl)
    return token_id


def validate_refresh_token(token_id: str) -> str | None:
    return redis_client.get(f"refresh:{token_id}")


def rotate_refresh_token(old_token_id: str, user_id: str) -> str:
    redis_client.delete(f"refresh:{old_token_id}")
    redis_client.srem(f"user_tokens:{user_id}", old_token_id)
    return create_refresh_token(user_id)


def revoke_all_user_tokens(user_id: str) -> None:
    """Revoke all refresh tokens for a user (e.g. after password change)."""
    token_ids = redis_client.smembers(f"user_tokens:{user_id}")
    if token_ids:
        pipe = redis_client.pipeline()
        for tid in token_ids:
            pipe.delete(f"refresh:{tid}")
        pipe.delete(f"user_tokens:{user_id}")
        pipe.execute()


def decode_access_token(token: str) -> dict:
    return jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])


def blacklist_token(jti: str, ttl_seconds: int) -> None:
    redis_client.setex(f"blacklisted:{jti}", ttl_seconds, "1")


def is_token_blacklisted(jti: str) -> bool:
    return bool(redis_client.exists(f"blacklisted:{jti}"))
