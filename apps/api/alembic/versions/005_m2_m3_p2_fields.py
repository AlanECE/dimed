"""Add M2 preparation, M3 livraison, and P2 stock/arrivage fields

Revision ID: 005
Revises: 004
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "005"
down_revision: str | None = "004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # -- FeuilleDeRoute: M3 livraison fields --
    op.add_column(
        "feuilles_route",
        sa.Column(
            "livreur_id",
            sa.Uuid(),
            sa.ForeignKey("users.id"),
            nullable=True,
        ),
    )
    op.add_column(
        "feuilles_route",
        sa.Column(
            "chargement_valide",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )

    # -- Commande: M3 livraison fields --
    op.add_column(
        "commandes",
        sa.Column("signature_pharmacien", sa.LargeBinary(), nullable=True),
    )
    op.add_column(
        "commandes",
        sa.Column("motif_echec", sa.String(500), nullable=True),
    )

    # -- Commande: M2 preparation fields --
    op.add_column(
        "commandes",
        sa.Column("nb_colis", sa.Integer(), nullable=True),
    )
    op.add_column(
        "commandes",
        sa.Column("visa_preparateur", sa.String(255), nullable=True),
    )
    op.add_column(
        "commandes",
        sa.Column("visa_controleur", sa.String(255), nullable=True),
    )

    # -- LigneCommande: M2 preparation fields --
    op.add_column(
        "lignes_commande",
        sa.Column("qte_prelevee", sa.Integer(), nullable=True),
    )
    op.add_column(
        "lignes_commande",
        sa.Column(
            "verifie",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )

    # -- Medicament: P2 stock + image --
    op.add_column(
        "medicaments",
        sa.Column(
            "stock_quantity",
            sa.Integer(),
            server_default=sa.text("0"),
            nullable=False,
        ),
    )
    op.add_column(
        "medicaments",
        sa.Column("image_path", sa.String(500), nullable=True),
    )

    # -- Arrivage: P2 new table --
    op.create_table(
        "arrivages",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "medicament_id",
            sa.Uuid(),
            sa.ForeignKey("medicaments.id"),
            nullable=False,
        ),
        sa.Column("quantite", sa.Integer(), nullable=False),
        sa.Column("n_lot", sa.String(50), nullable=True),
        sa.Column("date_arrivage", sa.Date(), nullable=False),
        sa.Column("date_peremption", sa.Date(), nullable=True),
        sa.Column("fournisseur", sa.String(255), nullable=True),
        sa.Column(
            "created_at_arrivage",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        # AuditMixin columns
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("created_by", sa.String(255), nullable=True),
    )
    op.create_index(
        "ix_arrivages_date",
        "arrivages",
        ["date_arrivage"],
    )


def downgrade() -> None:
    op.drop_index("ix_arrivages_date", table_name="arrivages")
    op.drop_table("arrivages")

    op.drop_column("medicaments", "image_path")
    op.drop_column("medicaments", "stock_quantity")

    op.drop_column("lignes_commande", "verifie")
    op.drop_column("lignes_commande", "qte_prelevee")

    op.drop_column("commandes", "visa_controleur")
    op.drop_column("commandes", "visa_preparateur")
    op.drop_column("commandes", "nb_colis")
    op.drop_column("commandes", "motif_echec")
    op.drop_column("commandes", "signature_pharmacien")

    op.drop_column("feuilles_route", "chargement_valide")
    op.drop_column("feuilles_route", "livreur_id")
