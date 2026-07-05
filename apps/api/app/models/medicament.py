from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import Integer, Numeric, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class Medicament(AuditMixin, Base):
    __tablename__ = "medicaments"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    code_article: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        nullable=False,
        index=True,
    )
    designation: Mapped[str] = mapped_column(String(500), nullable=False)
    dci: Mapped[str | None] = mapped_column(String(255), nullable=True)
    dosage: Mapped[str | None] = mapped_column(String(100), nullable=True)
    forme: Mapped[str | None] = mapped_column(String(100), nullable=True)
    ppa: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    # Taux de TVA du produit (0 = hors TVA — la plupart des médicaments ;
    # les compléments alimentaires y sont soumis).
    taux_tva: Mapped[Decimal] = mapped_column(
        Numeric(4, 2), nullable=False, default=Decimal("0.00"), server_default="0"
    )
    fabricant: Mapped[str | None] = mapped_column(String(255), nullable=True)
    stock_quantity: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )
    image_path: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )
    featured: Mapped[bool] = mapped_column(
        "featured",
        default=False,
    )
