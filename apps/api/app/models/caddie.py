from uuid import UUID, uuid4

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class Caddie(AuditMixin, Base):
    """Legacy wave-picking caddie rows (kept for historical data only).

    No ORM relationship to Commande — superseded by CaddiePool.
    """

    __tablename__ = "caddies"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    commande_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("commandes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    numero: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
