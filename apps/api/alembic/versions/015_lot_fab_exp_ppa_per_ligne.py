"""Per-ligne OCR fields: drop dlc, add fab/exp/ppa, vignette 1:1

Revision ID: 015
Revises: 014
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "015"
down_revision: str | None = "014"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # lignes_commande : dlc → fab/exp/ppa (n_lot existe déjà)
    op.drop_column("lignes_commande", "dlc")
    op.add_column("lignes_commande", sa.Column("fab", sa.Date(), nullable=True))
    op.add_column("lignes_commande", sa.Column("exp", sa.Date(), nullable=True))
    op.add_column("lignes_commande", sa.Column("ppa", sa.Numeric(10, 2), nullable=True))

    # vignettes : 1:1 avec ligne, rename + nouveaux champs
    op.execute("DELETE FROM vignettes WHERE ligne_id IS NULL")
    op.alter_column("vignettes", "ligne_id", nullable=False)
    op.create_unique_constraint("uq_vignettes_ligne_id", "vignettes", ["ligne_id"])
    op.alter_column("vignettes", "extracted_dlc", new_column_name="extracted_exp")
    op.add_column("vignettes", sa.Column("extracted_lot", sa.String(length=64), nullable=True))
    op.add_column("vignettes", sa.Column("extracted_fab", sa.Date(), nullable=True))
    op.add_column("vignettes", sa.Column("extracted_ppa", sa.Numeric(10, 2), nullable=True))
    op.add_column(
        "vignettes",
        sa.Column("extracted_designation", sa.String(length=500), nullable=True),
    )
    op.drop_column("vignettes", "extracted_code_article")


def downgrade() -> None:
    op.add_column(
        "vignettes",
        sa.Column("extracted_code_article", sa.String(length=64), nullable=True),
    )
    op.drop_column("vignettes", "extracted_designation")
    op.drop_column("vignettes", "extracted_ppa")
    op.drop_column("vignettes", "extracted_fab")
    op.drop_column("vignettes", "extracted_lot")
    op.alter_column("vignettes", "extracted_exp", new_column_name="extracted_dlc")
    op.drop_constraint("uq_vignettes_ligne_id", "vignettes", type_="unique")
    op.alter_column("vignettes", "ligne_id", nullable=True)

    op.drop_column("lignes_commande", "ppa")
    op.drop_column("lignes_commande", "exp")
    op.drop_column("lignes_commande", "fab")
    op.add_column("lignes_commande", sa.Column("dlc", sa.Date(), nullable=True))
