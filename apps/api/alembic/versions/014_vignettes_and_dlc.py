"""Vignettes table + ligne DLC, drop ocr_verifie

Revision ID: 013
Revises: 012
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "013"
down_revision: str | None = "012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "lignes_commande",
        sa.Column("dlc", sa.Date(), nullable=True),
    )
    op.drop_column("lignes_commande", "ocr_verifie")

    op.create_table(
        "vignettes",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "commande_id",
            sa.Uuid(),
            sa.ForeignKey("commandes.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "ligne_id",
            sa.Uuid(),
            sa.ForeignKey("lignes_commande.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("filename", sa.String(length=255), nullable=False),
        sa.Column("extracted_dlc", sa.Date(), nullable=True),
        sa.Column("extracted_code_article", sa.String(length=64), nullable=True),
        sa.Column("extracted_raw", sa.Text(), nullable=True),
        sa.Column(
            "uploaded_by",
            sa.Uuid(),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
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
    op.create_index("ix_vignettes_commande_id", "vignettes", ["commande_id"])
    op.create_index("ix_vignettes_ligne_id", "vignettes", ["ligne_id"])


def downgrade() -> None:
    op.drop_index("ix_vignettes_ligne_id", table_name="vignettes")
    op.drop_index("ix_vignettes_commande_id", table_name="vignettes")
    op.drop_table("vignettes")

    op.add_column(
        "lignes_commande",
        sa.Column(
            "ocr_verifie",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )
    op.drop_column("lignes_commande", "dlc")
