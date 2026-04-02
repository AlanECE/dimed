import enum
from datetime import date
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import Date, Enum, ForeignKey, Numeric, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class CreanceStatut(enum.StrEnum):
    EN_ATTENTE = "en_attente"
    PARTIEL = "partiel"
    SOLDEE = "soldee"
    EN_RETARD = "en_retard"


class Creance(AuditMixin, Base):
    __tablename__ = "creances"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    pharmacien_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    facture_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("factures.id"), nullable=False)
    montant_total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    montant_paye: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    statut: Mapped[CreanceStatut] = mapped_column(
        Enum(CreanceStatut, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
        default=CreanceStatut.EN_ATTENTE,
    )
    echeance: Mapped[date] = mapped_column(Date, nullable=False)
