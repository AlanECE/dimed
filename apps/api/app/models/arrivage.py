from datetime import date, datetime
from uuid import UUID, uuid4

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class Arrivage(AuditMixin, Base):
    __tablename__ = "arrivages"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    medicament_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("medicaments.id"),
        nullable=False,
    )
    quantite: Mapped[int] = mapped_column(Integer, nullable=False)
    n_lot: Mapped[str | None] = mapped_column(String(50), nullable=True)
    date_arrivage: Mapped[date] = mapped_column(Date, nullable=False)
    date_peremption: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )
    fournisseur: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )
    created_at_arrivage: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
