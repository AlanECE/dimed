from uuid import UUID, uuid4

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuditMixin, Base


class Caddie(AuditMixin, Base):
    __tablename__ = "caddies"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    commande_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("commandes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    numero: Mapped[str] = mapped_column(String(50), nullable=False, index=True)

    commande: Mapped["Commande"] = relationship(  # noqa: F821
        back_populates="caddies"
    )
