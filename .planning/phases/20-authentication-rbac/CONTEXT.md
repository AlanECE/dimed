# Phase 20 Context: Authentication & RBAC

**Phase goal:** Users can log in and the API enforces role-based access control for all roles.

**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05

## Decisions

### Roles & Permissions

- **6 roles** (not 5) : admin, pharmacien, operatrice, preparateur, controleur, livreur
- Add `ADMIN = "admin"` to `UserRole` StrEnum in `app/models/user.py`
- Update `@dimed/shared-types` `UserRole` type to include `"admin"`

**Permission groups :**
| Group | Roles | Access |
|-------|-------|--------|
| admin | admin | Full access : create users, manage system, all endpoints |
| client | pharmacien | Own orders, catalog, notifications |
| backoffice | operatrice | All orders, validation, route sheets, document generation |
| terrain | preparateur, controleur, livreur | Mobile endpoints (M2/M3, not in v1 scope) |

- Middleware checks role group, not individual role per endpoint
- Decorator pattern: `@require_role("admin")`, `@require_roles(["admin", "operatrice"])`
- FastAPI dependency injection: `current_user = Depends(get_current_user)`

### Seed Admin

- CLI script: `python -m app.cli create-admin --email admin@dimed.dz --password <pwd>`
- Creates admin user if not exists, skips if already present
- Run once at deployment, documented in README

### JWT Token Strategy

- **Access token**: 30 min expiry, contains `user_id`, `role`, `email`
- **Refresh token**: 7 days expiry, opaque UUID stored in Redis
- **Storage**: httpOnly cookies (secure, SameSite=Lax)
- **CSRF protection**: Double-submit cookie pattern or custom header
- **Rotation**: Each refresh generates new refresh token, old one blacklisted in Redis
- **Blacklist**: Redis set `blacklisted_tokens:{jti}` with TTL = remaining token lifetime
- **Logout**: Blacklist both access and refresh tokens

### Auth Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/login | None | Email + password → set httpOnly cookies |
| POST | /auth/refresh | Refresh cookie | Rotate refresh token, new access token |
| POST | /auth/logout | Access token | Blacklist tokens, clear cookies |
| GET | /auth/me | Access token | Current user profile |
| POST | /admin/users | Admin only | Create user with role |
| GET | /admin/users | Admin only | List all users (paginated) |
| PATCH | /admin/users/{id} | Admin only | Update user (role, is_active) |

**NOT in v1 scope:** reset-password, change-password, email verification

### Libraries (already installed in Phase 10)

- `python-jose[cryptography]` : JWT encode/decode
- `passlib[bcrypt]` : password hashing
- `redis` : token blacklist storage

## Code Context

- `apps/api/app/models/user.py` : User model with UserRole StrEnum (needs admin added)
- `apps/api/app/config.py` : Settings with secret_key, token expiry durations, redis_url
- `apps/api/app/db/session.py` : async session factory
- `packages/shared-types/src/index.ts` : UserRole type (needs admin added)

## Deferred Ideas

- Change password endpoint — add in a later phase when users request it
- Reset password by email — requires SMTP setup, defer to v2
- OAuth / social login — not needed for internal deployment
- 2FA — nice to have for admin, defer

---
*Created: 2026-03-23 after discuss-phase 20*
