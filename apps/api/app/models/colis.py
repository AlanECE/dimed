import enum
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    Enum,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuditMixin, Base


class ColisStatus(enum.StrEnum):
    ETIQUETE = "etiquete"
    SUR_PAD = "sur_pad"
    CHARGE = "charge"
    LIVRE = "livre"


class ScanType(enum.StrEnum):
    DEPOT_PAD = "depot_pad"
    CHARGEMENT = "chargement"
    LIVRAISON = "livraison"


class PadTir(AuditMixin, Base):
    __tablename__ = "pads_tir"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    nom: Mapped[str] = mapped_column(String(100), nullable=False)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class Colis(AuditMixin, Base):
    __tablename__ = "colis"
    __table_args__ = (
        UniqueConstraint("commande_id", "index_colis", name="uq_colis_commande_index"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    numero: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    commande_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("commandes.id"), nullable=False, index=True
    )
    index_colis: Mapped[int] = mapped_column(Integer, nullable=False)
    statut: Mapped[ColisStatus] = mapped_column(
        Enum(ColisStatus, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
        default=ColisStatus.ETIQUETE,
    )
    pad_tir_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("pads_tir.id"), nullable=True)

    commande: Mapped["Commande"] = relationship()  # noqa: F821
    pad_tir: Mapped["PadTir | None"] = relationship()
    lignes: Mapped[list["ColisLigne"]] = relationship(
        back_populates="colis", cascade="all, delete-orphan"
    )


class ColisLigne(AuditMixin, Base):
    __tablename__ = "colis_lignes"
    __table_args__ = (
        UniqueConstraint("colis_id", "ligne_commande_id", name="uq_colis_lignes_colis_ligne"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    colis_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("colis.id"), nullable=False, index=True)
    ligne_commande_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("lignes_commande.id"), nullable=False
    )
    quantite: Mapped[int] = mapped_column(Integer, nullable=False)

    colis: Mapped["Colis"] = relationship(back_populates="lignes")
    ligne_commande: Mapped["LigneCommande"] = relationship()  # noqa: F821


class ScanColis(AuditMixin, Base):
    __tablename__ = "scans_colis"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    colis_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("colis.id"), nullable=False, index=True)
    type_scan: Mapped[ScanType] = mapped_column(
        Enum(ScanType, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
    )
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    pad_tir_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("pads_tir.id"), nullable=True)
