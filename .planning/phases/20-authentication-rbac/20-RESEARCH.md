# Phase 20 Research: Authentication & RBAC

## FastAPI JWT Auth Pattern (from Context7 + Tavily)

### Token Creation
```python
from jose import jwt
from datetime import datetime, timedelta

def create_access_token(data: dict, expires_delta: timedelta) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + expires_delta
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")
```

### Current User Dependency
```python
from typing import Annotated
from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]) -> User:
    payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
    user_id = payload.get("sub")
    # ... fetch from DB, raise 401 if not found
```

### httpOnly Cookie Pattern
```python
from fastapi import Response

@router.post("/auth/login")
async def login(response: Response):
    # ... validate credentials
    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,
        secure=True,  # HTTPS only in prod
        samesite="lax",
        max_age=60 * 30  # 30 minutes
    )
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=60 * 60 * 24 * 7  # 7 days
        path="/auth/refresh"  # only sent to refresh endpoint
    )
```

### Redis Token Blacklist
```python
import redis

redis_client = redis.Redis.from_url(settings.redis_url)

def blacklist_token(jti: str, ttl: int) -> None:
    redis_client.setex(f"blacklisted:{jti}", ttl, "1")

def is_token_blacklisted(jti: str) -> bool:
    return bool(redis_client.exists(f"blacklisted:{jti}"))
```

### Role-Based Access (Decorator Pattern)
```python
from functools import wraps
from fastapi import HTTPException, status

def require_roles(allowed_roles: list[str]):
    def dependency(current_user: User = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return current_user
    return dependency

# Usage:
@router.get("/admin/users")
async def list_users(user: User = Depends(require_roles(["admin"]))):
    ...
```

## Key Implementation Notes

1. **Cookie extraction**: FastAPI's OAuth2PasswordBearer reads from Authorization header by default. For httpOnly cookies, need a custom dependency that reads from `request.cookies["access_token"]`
2. **Refresh token**: Store as UUID in Redis, NOT as JWT. Map UUID → user_id. On refresh: delete old UUID, create new one.
3. **JTI (JWT ID)**: Include a `jti` claim (UUID) in access tokens for blacklisting on logout
4. **Password hashing**: `passlib.hash.bcrypt.hash(password)` and `bcrypt.verify(password, hash)`
5. **CSRF**: With httpOnly cookies + SameSite=Lax, CSRF risk is low for non-GET mutations. Add X-CSRF-Token header for extra safety if needed.

## File Structure for Auth Module
```
apps/api/app/
├── auth/
│   ├── __init__.py
│   ├── router.py          # /auth/* endpoints
│   ├── service.py         # JWT creation, password hashing, Redis ops
│   ├── dependencies.py    # get_current_user, require_roles
│   └── schemas.py         # LoginRequest, TokenResponse, UserCreate
├── admin/
│   ├── __init__.py
│   ├── router.py          # /admin/users/* endpoints
│   └── schemas.py         # AdminUserCreate, AdminUserUpdate
```

## Validation Architecture

### Tests for Phase 20
1. Login with valid credentials → 200, cookies set
2. Login with invalid password → 401
3. Access protected endpoint with valid token → 200
4. Access protected endpoint without token → 401
5. Access admin endpoint with non-admin role → 403
6. Refresh token → new access token, old refresh blacklisted
7. Logout → tokens blacklisted, cookies cleared
8. Create user via admin → 201, user exists in DB
9. Inactive user cannot login → 401

---
*Research completed: 2026-03-23 for Phase 20*
*Sources: Context7 FastAPI docs, Tavily search (JWT+FastAPI+Redis patterns)*
