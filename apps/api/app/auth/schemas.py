from uuid import UUID

from pydantic import BaseModel, Field

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
    id: UUID
    email: str
    role: UserRole
    nom: str
    adresse: str | None = None
    secteur: str | None = None
    is_active: bool

    model_config = {"from_attributes": True}


class UpdateProfileRequest(BaseModel):
    nom: str | None = Field(None, min_length=1, max_length=255)
    adresse: str | None = Field(None, max_length=500)
    secteur: str | None = Field(None, max_length=100)


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


class AdminUserCreate(BaseModel):
    email: str
    password: str = Field(min_length=8, max_length=128)
    role: UserRole
    nom: str
    adresse: str | None = None
    secteur: str | None = None


class AdminUserUpdate(BaseModel):
    role: UserRole | None = None
    is_active: bool | None = None
    nom: str | None = None
