"""TVA par produit, ligne de livraison sur la fiche client, zones d'expédition

- medicaments.taux_tva : taux de TVA du produit (0 = hors TVA ; compléments
  alimentaires ~9-19 %). Affiché sur la fiche article et la facture.
- users.camion_id : ligne de livraison déterminée à la création de la fiche
  client (pharmacien) — supprime la ressaisie manuelle par commande.
- pads_tir.nom : renommés « Zone N » (vocabulaire CR : zone d'expédition).

Revision ID: 018
Revises: 017
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "018"
down_revision: str | None = "017"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "medicaments",
        sa.Column("taux_tva", sa.Numeric(4, 2), nullable=False, server_default="0"),
    )
    op.add_column("users", sa.Column("camion_id", sa.Uuid(), nullable=True))
    op.create_foreign_key(
        "fk_users_camion_id",
        "users",
        "camions",
        ["camion_id"],
        ["id"],
        ondelete="SET NULL",
    )
    # Vocabulaire du CR : les pads de tir sont des zones d'expédition.
    op.execute(
        "UPDATE pads_tir SET nom = 'Zone ' || ltrim(substring(code from 5), '0') "
        "WHERE code LIKE 'PAD-%'"
    )


def downgrade() -> None:
    op.drop_constraint("fk_users_camion_id", "users", type_="foreignkey")
    op.drop_column("users", "camion_id")
    op.drop_column("medicaments", "taux_tva")
