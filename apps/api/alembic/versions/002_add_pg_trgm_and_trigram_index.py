"""add pg_trgm extension and trigram index on medicaments.designation

Revision ID: 002
Revises: 001
Create Date: 2026-03-23
"""

from collections.abc import Sequence

from alembic import op

revision: str = "002"
down_revision: str | None = "001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.execute(
        "CREATE INDEX idx_medicaments_designation_trgm "
        "ON medicaments USING gin (designation gin_trgm_ops)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS idx_medicaments_designation_trgm")
    op.execute("DROP EXTENSION IF EXISTS pg_trgm")
