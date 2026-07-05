import enum
from uuid import UUID, uuid4

from sqlalchemy import Boolean, Enum, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class UserRole(enum.StrEnum):
    ADMIN = "admin"
    PHARMACIEN = "pharmacien"
    OPERATRICE = "operatrice"
    PREPARATEUR = "preparateur"
    CONTROLEUR = "controleur"
    LIVREUR = "livreur"
    MAGASINIER = "magasinier"
    FACTURIER = "facturier"


class User(AuditMixin, Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
    )
    nom: Mapped[str] = mapped_column(String(255), nullable=False)
    adresse: Mapped[str | None] = mapped_column(String(500), nullable=True)
    secteur: Mapped[str | None] = mapped_column(String(100), nullable=True)
    # Ligne de livraison du client (pharmacien) — déterminée à la création de
    # la fiche ; les commandes en héritent automatiquement à l'acceptation.
    camion_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("camions.id", ondelete="SET NULL"), nullable=True
    )
    telephone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    google_id: Mapped[str | None] = mapped_column(
        String(255), unique=True, nullable=True, index=True
    )
    oauth_provider: Mapped[str | None] = mapped_column(String(20), nullable=True)
    is_email_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True)
