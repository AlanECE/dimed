"""Add self-service signup fields

Revision ID: 008
Revises: 007
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "008"
down_revision: str | None = "007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("telephone", sa.String(30), nullable=True))
    op.add_column("users", sa.Column("google_id", sa.String(255), nullable=True))
    op.add_column("users", sa.Column("oauth_provider", sa.String(20), nullable=True))
    op.add_column(
        "users",
        sa.Column(
            "is_email_verified",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )
    op.create_unique_constraint("uq_users_google_id", "users", ["google_id"])
    op.create_index("ix_users_google_id", "users", ["google_id"])

    # Existing accounts are trusted: mark verified + local provider
    op.execute(
        "UPDATE users SET is_email_verified = true, oauth_provider = 'local' "
        "WHERE oauth_provider IS NULL"
    )

    # Allow NULL password_hash for pure-Google accounts
    op.alter_column("users", "password_hash", existing_type=sa.String(255), nullable=True)


def downgrade() -> None:
    op.alter_column("users", "password_hash", existing_type=sa.String(255), nullable=False)
    op.drop_index("ix_users_google_id", table_name="users")
    op.drop_constraint("uq_users_google_id", "users", type_="unique")
    op.drop_column("users", "is_email_verified")
    op.drop_column("users", "oauth_provider")
    op.drop_column("users", "google_id")
    op.drop_column("users", "telephone")
