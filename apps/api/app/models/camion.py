from uuid import UUID, uuid4

from sqlalchemy import String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class Camion(AuditMixin, Base):
    __tablename__ = "camions"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    nom: Mapped[str] = mapped_column(String(100), nullable=False)
    plaque: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
