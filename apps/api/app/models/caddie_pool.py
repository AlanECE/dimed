from uuid import UUID, uuid4

from sqlalchemy import Boolean, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import AuditMixin, Base


class CaddiePool(AuditMixin, Base):
    __tablename__ = "caddies_pool"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    numero: Mapped[str] = mapped_column(String(20), nullable=False, unique=True)
    is_available: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true", index=True
    )
    current_commande_id: Mapped[UUID | None] = mapped_column(
        Uuid,
        ForeignKey("commandes.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    commande: Mapped["Commande | None"] = relationship(  # noqa: F821
        back_populates="caddie_pool",
        foreign_keys=[current_commande_id],
    )
