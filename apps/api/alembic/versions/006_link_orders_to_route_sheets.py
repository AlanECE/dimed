"""Link orders to route sheets and enforce route uniqueness

Revision ID: 006
Revises: 005
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "006"
down_revision: str | None = "005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "commandes",
        sa.Column("feuille_route_id", sa.Uuid(), nullable=True),
    )
    op.create_foreign_key(
        "fk_commandes_feuille_route_id",
        "commandes",
        "feuilles_route",
        ["feuille_route_id"],
        ["id"],
    )
    op.create_unique_constraint(
        "uq_feuilles_route_camion_date",
        "feuilles_route",
        ["camion_id", "date"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_feuilles_route_camion_date",
        "feuilles_route",
        type_="unique",
    )
    op.drop_constraint(
        "fk_commandes_feuille_route_id",
        "commandes",
        type_="foreignkey",
    )
    op.drop_column("commandes", "feuille_route_id")
