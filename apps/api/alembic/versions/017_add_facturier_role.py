"""Add facturier role

Revision ID: 017
Revises: 016
"""

from collections.abc import Sequence

from alembic import op

revision: str = "017"
down_revision: str | None = "016"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Nouveau rôle facturier (valeur d'enum PG). Les comptes facturier/livreurs
    # de test sont créés au démarrage de l'API (backfill du lifespan).
    op.execute("ALTER TYPE userrole ADD VALUE IF NOT EXISTS 'facturier'")


def downgrade() -> None:
    # PostgreSQL ne permet pas de retirer une valeur d'enum : on ne fait rien.
    pass
