"""Add caddies_pool (seed 10) + commandes.operatrice_comment

Revision ID: 012
Revises: 011
"""

from collections.abc import Sequence
from uuid import uuid4

import sqlalchemy as sa

from alembic import op

revision: str = "012"
down_revision: str | None = "011"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "commandes",
        sa.Column("operatrice_comment", sa.String(length=500), nullable=True),
    )

    caddies_pool = op.create_table(
        "caddies_pool",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("numero", sa.String(length=20), nullable=False, unique=True),
        sa.Column(
            "is_available",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "current_commande_id",
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
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("updated_by", sa.Uuid(), nullable=True),
    )
    op.create_index("ix_caddies_pool_is_available", "caddies_pool", ["is_available"])
    op.create_index(
        "ix_caddies_pool_current_commande_id",
        "caddies_pool",
        ["current_commande_id"],
    )

    op.bulk_insert(
        caddies_pool,
        [
            {
                "id": uuid4(),
                "numero": f"C{i:02d}",
                "is_available": True,
                "current_commande_id": None,
                "created_by": None,
                "updated_by": None,
            }
            for i in range(1, 11)
        ],
    )


def downgrade() -> None:
    op.drop_index("ix_caddies_pool_current_commande_id", table_name="caddies_pool")
    op.drop_index("ix_caddies_pool_is_available", table_name="caddies_pool")
    op.drop_table("caddies_pool")
    op.drop_column("commandes", "operatrice_comment")
