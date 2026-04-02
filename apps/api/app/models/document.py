from datetime import date, datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    LargeBinary,
    Numeric,
    String,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class Facture(AuditMixin, Base):
    __tablename__ = "factures"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    reference_id: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    commande_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("commandes.id"), nullable=False)
    date_emission: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    montant_ht: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    montant_ttc: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)


class BonDeLivraison(AuditMixin, Base):
    __tablename__ = "bons_livraison"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    commande_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("commandes.id"), nullable=False)
    code_barre: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    date_emission: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class FeuilleDeRoute(AuditMixin, Base):
    __tablename__ = "feuilles_route"
    __table_args__ = (UniqueConstraint("camion_id", "date", name="uq_feuilles_route_camion_date"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    camion_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("camions.id"), nullable=False)
    livreur_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("users.id"), nullable=True)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    ligne: Mapped[str | None] = mapped_column(String(100), nullable=True)
    n_rotation: Mapped[str | None] = mapped_column(String(50), nullable=True)
    compteurs: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    chargement_valide: Mapped[bool] = mapped_column(default=False)
    signature_expedition: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)
    signature_chauffeur: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)
