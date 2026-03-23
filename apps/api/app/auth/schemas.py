from pydantic import BaseModel

from app.models.user import UserRole


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenPayload(BaseModel):
    sub: str
    role: str
    email: str
    jti: str
    type: str


class UserResponse(BaseModel):
    id: str
    email: str
    role: UserRole
    nom: str
    is_active: bool

    model_config = {"from_attributes": True}


class AdminUserCreate(BaseModel):
    email: str
    password: str
    role: UserRole
    nom: str
    adresse: str | None = None
    secteur: str | None = None


class AdminUserUpdate(BaseModel):
    role: UserRole | None = None
    is_active: bool | None = None
    nom: str | None = None
