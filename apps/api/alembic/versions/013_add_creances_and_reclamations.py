"""Add creances and reclamations tables

Revision ID: 013
Revises: 012
"""

from collections.abc import Sequence

from alembic import op

revision: str = "013"
down_revision: str | None = "012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Enum types may already exist (e.g. from a dump import) — use IF NOT EXISTS
    op.execute(
        "DO $$ BEGIN "
        "  CREATE TYPE creancestatut AS ENUM ('en_attente', 'partiel', 'soldee', 'en_retard'); "
        "EXCEPTION WHEN duplicate_object THEN NULL; "
        "END $$;"
    )
    op.execute(
        "DO $$ BEGIN "
        "  CREATE TYPE reclamationmotif AS ENUM "
        "    ('produit_endommage', 'produit_manquant', 'erreur_facturation', 'erreur_produit', 'autre'); "
        "EXCEPTION WHEN duplicate_object THEN NULL; "
        "END $$;"
    )
    op.execute(
        "DO $$ BEGIN "
        "  CREATE TYPE reclamationstatut AS ENUM ('ouverte', 'en_cours', 'resolue', 'rejetee'); "
        "EXCEPTION WHEN duplicate_object THEN NULL; "
        "END $$;"
    )

    op.execute("""
        CREATE TABLE IF NOT EXISTS creances (
            id          UUID PRIMARY KEY,
            pharmacien_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            facture_id  UUID NOT NULL UNIQUE REFERENCES factures(id) ON DELETE CASCADE,
            montant_total NUMERIC(12,2) NOT NULL,
            montant_paye  NUMERIC(12,2) NOT NULL DEFAULT 0,
            statut      creancestatut NOT NULL DEFAULT 'en_attente',
            echeance    DATE NOT NULL,
            created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_by  UUID REFERENCES users(id) ON DELETE SET NULL
        )
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS reclamations (
            id            UUID PRIMARY KEY,
            pharmacien_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            commande_id   UUID NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
            motif         reclamationmotif NOT NULL,
            description   TEXT NOT NULL,
            statut        reclamationstatut NOT NULL DEFAULT 'ouverte',
            resolution    TEXT,
            created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_by    UUID REFERENCES users(id) ON DELETE SET NULL
        )
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS reclamations")
    op.execute("DROP TABLE IF EXISTS creances")
    op.execute("DROP TYPE IF EXISTS reclamationstatut")
    op.execute("DROP TYPE IF EXISTS reclamationmotif")
    op.execute("DROP TYPE IF EXISTS creancestatut")
