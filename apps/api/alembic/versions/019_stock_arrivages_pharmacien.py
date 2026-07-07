"""Stock officine + arrivages pharmacien (OCR et import commande)

Revision ID: 019
Revises: 018
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "019"
down_revision: str | None = "018"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    arrivagesource = postgresql.ENUM(
        "ocr",
        "commande",
        name="arrivagesource",
        create_type=False,
    )
    arrivagesource.create(op.get_bind(), checkfirst=True)

    # --- stock_pharmacien : le stock de l'officine, alimenté par les arrivages ---
    op.create_table(
        "stock_pharmacien",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "pharmacien_id",
            sa.Uuid(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "medicament_id",
            sa.Uuid(),
            sa.ForeignKey("medicaments.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("designation", sa.String(length=255), nullable=False),
        sa.Column("quantite", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("ppa", sa.Numeric(10, 2), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.UniqueConstraint("pharmacien_id", "designation", name="uq_stock_pharmacien_designation"),
    )
    op.create_index("ix_stock_pharmacien_pharmacien_id", "stock_pharmacien", ["pharmacien_id"])

    # --- arrivages_pharmacien : un arrivage = un scan OCR validé ou un import commande ---
    op.create_table(
        "arrivages_pharmacien",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "pharmacien_id",
            sa.Uuid(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("source", arrivagesource, nullable=False),
        sa.Column(
            "commande_id",
            sa.Uuid(),
            sa.ForeignKey("commandes.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
    )
    op.create_index(
        "ix_arrivages_pharmacien_pharmacien_id", "arrivages_pharmacien", ["pharmacien_id"]
    )

    op.create_table(
        "arrivages_pharmacien_lignes",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "arrivage_id",
            sa.Uuid(),
            sa.ForeignKey("arrivages_pharmacien.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("designation", sa.String(length=255), nullable=False),
        sa.Column("quantite", sa.Integer(), nullable=False),
        sa.Column("ppa", sa.Numeric(10, 2), nullable=True),
        sa.Column("n_lot", sa.String(length=50), nullable=True),
        sa.Column("exp", sa.Date(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
    )
    op.create_index(
        "ix_arrivages_pharmacien_lignes_arrivage_id",
        "arrivages_pharmacien_lignes",
        ["arrivage_id"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_arrivages_pharmacien_lignes_arrivage_id",
        table_name="arrivages_pharmacien_lignes",
    )
    op.drop_table("arrivages_pharmacien_lignes")
    op.drop_index("ix_arrivages_pharmacien_pharmacien_id", table_name="arrivages_pharmacien")
    op.drop_table("arrivages_pharmacien")
    op.drop_index("ix_stock_pharmacien_pharmacien_id", table_name="stock_pharmacien")
    op.drop_table("stock_pharmacien")
    op.execute("DROP TYPE IF EXISTS arrivagesource")
