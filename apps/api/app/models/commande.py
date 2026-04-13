import enum
from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    LargeBinary,
    Numeric,
    String,
    Uuid,
)
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
        Enum(OrderStatus, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
        default=OrderStatus.CREEE,
    )
    montant_total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    commercial: Mapped[str | None] = mapped_column(String(255), nullable=True)
    date_validation: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    camion_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("camions.id"), nullable=True)
    feuille_route_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("feuilles_route.id"), nullable=True
    )
    signature_pharmacien: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)
    motif_echec: Mapped[str | None] = mapped_column(String(500), nullable=True)
    nb_colis: Mapped[int | None] = mapped_column(Integer, nullable=True)
    visa_preparateur: Mapped[str | None] = mapped_column(String(255), nullable=True)
    visa_controleur: Mapped[str | None] = mapped_column(String(255), nullable=True)
    preparateur_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id"), nullable=True, index=True
    )
    operatrice_comment: Mapped[str | None] = mapped_column(String(500), nullable=True)

    lignes: Mapped[list["LigneCommande"]] = relationship(
        back_populates="commande", cascade="all, delete-orphan"
    )
    caddie_pool: Mapped["CaddiePool | None"] = relationship(  # noqa: F821
        back_populates="commande",
        uselist=False,
        foreign_keys="CaddiePool.current_commande_id",
    )


class LigneCommande(AuditMixin, Base):
    __tablename__ = "lignes_commande"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    commande_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("commandes.id"), nullable=False)
    medicament_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("medicaments.id"), nullable=False)
    designation: Mapped[str] = mapped_column(String(500), nullable=False)
    qte_demandee: Mapped[int] = mapped_column(Integer, nullable=False)
    qte_prelevee: Mapped[int | None] = mapped_column(Integer, nullable=True)
    prix_unitaire: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    remise_pct: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), nullable=False, default=Decimal("0.00"), server_default="0"
    )
    n_lot: Mapped[str | None] = mapped_column(String(50), nullable=True)
    verifie: Mapped[bool] = mapped_column(Boolean, default=False)
    ocr_verifie: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False, server_default="false"
    )

    commande: Mapped["Commande"] = relationship(back_populates="lignes")
