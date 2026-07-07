"""Stock et arrivages côté pharmacie (officine).

Distinct des arrivages fournisseurs DIMED (app.models.arrivage) : ici le
pharmacien alimente SON stock, soit en scannant une vignette (OCR), soit en
important le contenu d'une commande qui lui a été livrée.
"""

import enum
from datetime import date
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import (
    Date,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuditMixin, Base


class ArrivageSource(enum.StrEnum):
    OCR = "ocr"
    COMMANDE = "commande"


class StockPharmacien(AuditMixin, Base):
    __tablename__ = "stock_pharmacien"
    __table_args__ = (
        UniqueConstraint("pharmacien_id", "designation", name="uq_stock_pharmacien_designation"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    pharmacien_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    medicament_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("medicaments.id", ondelete="SET NULL"), nullable=True
    )
    designation: Mapped[str] = mapped_column(String(255), nullable=False)
    quantite: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    ppa: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)


class ArrivagePharmacien(AuditMixin, Base):
    __tablename__ = "arrivages_pharmacien"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    pharmacien_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    source: Mapped[ArrivageSource] = mapped_column(
        Enum(ArrivageSource, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
    )
    commande_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("commandes.id", ondelete="SET NULL"), nullable=True
    )

    lignes: Mapped[list["ArrivagePharmacienLigne"]] = relationship(
        back_populates="arrivage", cascade="all, delete-orphan"
    )


class ArrivagePharmacienLigne(AuditMixin, Base):
    __tablename__ = "arrivages_pharmacien_lignes"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    arrivage_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("arrivages_pharmacien.id", ondelete="CASCADE"), nullable=False, index=True
    )
    designation: Mapped[str] = mapped_column(String(255), nullable=False)
    quantite: Mapped[int] = mapped_column(Integer, nullable=False)
    ppa: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    n_lot: Mapped[str | None] = mapped_column(String(50), nullable=True)
    exp: Mapped[date | None] = mapped_column(Date, nullable=True)

    arrivage: Mapped["ArrivagePharmacien"] = relationship(back_populates="lignes")
