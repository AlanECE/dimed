"""add camion table and FK to commandes/feuilles_route

Revision ID: 003
Revises: 002
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "003"
down_revision: str | None = "002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "camions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("nom", sa.String(100), nullable=False),
        sa.Column("plaque", sa.String(20), nullable=False),
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
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("plaque"),
    )

    op.add_column(
        "commandes",
        sa.Column("camion_id", sa.Uuid(), nullable=True),
    )
    op.create_foreign_key(
        "fk_commandes_camion_id",
        "commandes",
        "camions",
        ["camion_id"],
        ["id"],
    )

    op.drop_column("feuilles_route", "camion_id")
    op.add_column(
        "feuilles_route",
        sa.Column("camion_id", sa.Uuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_feuilles_route_camion_id",
        "feuilles_route",
        "camions",
        ["camion_id"],
        ["id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_feuilles_route_camion_id",
        "feuilles_route",
        type_="foreignkey",
    )
    op.drop_column("feuilles_route", "camion_id")
    op.add_column(
        "feuilles_route",
        sa.Column("camion_id", sa.String(50), nullable=False),
    )

    op.drop_constraint(
        "fk_commandes_camion_id",
        "commandes",
        type_="foreignkey",
    )
    op.drop_column("commandes", "camion_id")

    op.drop_table("camions")
