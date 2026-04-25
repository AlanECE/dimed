from datetime import date
from uuid import UUID, uuid4

from sqlalchemy import Date, ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuditMixin, Base


class Vignette(AuditMixin, Base):
    __tablename__ = "vignettes"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    commande_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("commandes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    ligne_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("lignes_commande.id", ondelete="SET NULL"), nullable=True, index=True
    )
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    extracted_dlc: Mapped[date | None] = mapped_column(Date, nullable=True)
    extracted_code_article: Mapped[str | None] = mapped_column(String(64), nullable=True)
    extracted_raw: Mapped[str | None] = mapped_column(Text, nullable=True)
    uploaded_by: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    commande: Mapped["Commande"] = relationship(foreign_keys=[commande_id])  # noqa: F821
    ligne: Mapped["LigneCommande | None"] = relationship(foreign_keys=[ligne_id])  # noqa: F821
