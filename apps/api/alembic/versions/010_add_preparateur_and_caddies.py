"""Add preparateur_id on commandes + caddies table

Revision ID: 010
Revises: 009
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "010"
down_revision: str | None = "009"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "commandes",
        sa.Column("preparateur_id", sa.Uuid(), nullable=True),
    )
    op.create_foreign_key(
        "fk_commandes_preparateur_id_users",
        "commandes",
        "users",
        ["preparateur_id"],
        ["id"],
    )
    op.create_index("ix_commandes_preparateur_id", "commandes", ["preparateur_id"])

    op.create_table(
        "caddies",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "commande_id",
            sa.Uuid(),
            sa.ForeignKey("commandes.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("numero", sa.String(50), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("updated_by", sa.Uuid(), nullable=True),
    )
    op.create_index("ix_caddies_commande_id", "caddies", ["commande_id"])
    op.create_index("ix_caddies_numero", "caddies", ["numero"])


def downgrade() -> None:
    op.drop_index("ix_caddies_numero", table_name="caddies")
    op.drop_index("ix_caddies_commande_id", table_name="caddies")
    op.drop_table("caddies")
    op.drop_index("ix_commandes_preparateur_id", table_name="commandes")
    op.drop_constraint("fk_commandes_preparateur_id_users", "commandes", type_="foreignkey")
    op.drop_column("commandes", "preparateur_id")
