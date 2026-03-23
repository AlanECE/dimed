import enum
from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuditMixin, Base


class OrderStatus(enum.StrEnum):
    CREEE = "creee"
    ACCEPTEE = "acceptee"
    ANNULEE = "annulee"
    EN_PREPARATION = "en_preparation"
    PRELEVEE_PARTIELLEMENT = "prelevee_partiellement"
    EN_VERIFICATION = "en_verification"
    PRETE = "prete"
    EN_ROUTE = "en_route"
    LIVREE = "livree"
    REFUSEE = "refusee"
    RETOURNEE = "retournee"
    LIVREE_PARTIELLEMENT = "livree_partiellement"


class Commande(AuditMixin, Base):
    __tablename__ = "commandes"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    reference_id: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    pharmacien_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    operatrice_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("users.id"), nullable=True)
    statut: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus), nullable=False, default=OrderStatus.CREEE
    )
    montant_total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    commercial: Mapped[str | None] = mapped_column(String(255), nullable=True)
    date_validation: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    camion_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("camions.id"), nullable=True)

    lignes: Mapped[list["LigneCommande"]] = relationship(
        back_populates="commande", cascade="all, delete-orphan"
    )


class LigneCommande(AuditMixin, Base):
    __tablename__ = "lignes_commande"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    commande_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("commandes.id"), nullable=False)
    medicament_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("medicaments.id"), nullable=False)
    designation: Mapped[str] = mapped_column(String(500), nullable=False)
    qte_demandee: Mapped[int] = mapped_column(Integer, nullable=False)
    prix_unitaire: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    n_lot: Mapped[str | None] = mapped_column(String(50), nullable=True)

    commande: Mapped["Commande"] = relationship(back_populates="lignes")
