"""Add per-line discount (remise_pct) on lignes_commande

Revision ID: 009
Revises: 008
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "009"
down_revision: str | None = "008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "lignes_commande",
        sa.Column(
            "remise_pct",
            sa.Numeric(5, 2),
            server_default=sa.text("0"),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("lignes_commande", "remise_pct")
