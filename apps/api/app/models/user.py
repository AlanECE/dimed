import enum
from uuid import UUID, uuid4

from sqlalchemy import Enum, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class UserRole(enum.StrEnum):
    PHARMACIEN = "pharmacien"
    OPERATRICE = "operatrice"
    PREPARATEUR = "preparateur"
    CONTROLEUR = "controleur"
    LIVREUR = "livreur"


class User(AuditMixin, Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), nullable=False)
    nom: Mapped[str] = mapped_column(String(255), nullable=False)
    adresse: Mapped[str | None] = mapped_column(String(500), nullable=True)
    secteur: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True)
