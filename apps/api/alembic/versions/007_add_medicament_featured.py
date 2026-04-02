"""Add featured flag on medicaments

Revision ID: 007
Revises: 006
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "007"
down_revision: str | None = "006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "medicaments",
        sa.Column(
            "featured",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )
    # Pre-seed: mark Cytolab products as featured
    op.execute("UPDATE medicaments SET featured = true WHERE UPPER(fabricant) LIKE '%CYTOLAB%'")


def downgrade() -> None:
    op.drop_column("medicaments", "featured")
