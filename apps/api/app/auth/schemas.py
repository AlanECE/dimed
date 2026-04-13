from typing import Literal
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

from app.models.user import UserRole

SignupRole = Literal[
    "pharmacien",
    "operatrice",
    "preparateur",
    "controleur",
    "livreur",
]


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
    telephone: str | None = None
    is_active: bool
    is_email_verified: bool = False
    oauth_provider: str | None = None

    model_config = {"from_attributes": True}


class UpdateProfileRequest(BaseModel):
    nom: str | None = Field(None, min_length=1, max_length=255)
    adresse: str | None = Field(None, max_length=500)
    secteur: str | None = Field(None, max_length=100)
    telephone: str | None = Field(None, max_length=30)


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


class AdminUserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    role: UserRole
    nom: str
    adresse: str | None = None
    secteur: str | None = None
    telephone: str | None = Field(None, max_length=30)


class AdminUserUpdate(BaseModel):
    role: UserRole | None = None
    is_active: bool | None = None
    nom: str | None = None


class SignupRequest(BaseModel):
    nom: str = Field(min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    role: SignupRole
    adresse: str | None = Field(None, max_length=500)
    secteur: str | None = Field(None, max_length=100)
    telephone: str | None = Field(None, max_length=30)


class SignupResponse(BaseModel):
    message: str


class GoogleAuthRequest(BaseModel):
    credential: str = Field(min_length=10, max_length=4096)
    role: SignupRole | None = None
    adresse: str | None = Field(None, max_length=500)
    secteur: str | None = Field(None, max_length=100)
    telephone: str | None = Field(None, max_length=30)


class ResendVerificationRequest(BaseModel):
    email: EmailStr


class VerifyEmailResponse(BaseModel):
    message: str
