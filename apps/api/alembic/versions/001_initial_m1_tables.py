"""initial M1 tables

Revision ID: 001
Revises:
Create Date: 2026-03-23
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # --- Enum types ---
    userrole = postgresql.ENUM(
        "admin",
        "pharmacien",
        "operatrice",
        "preparateur",
        "controleur",
        "livreur",
        name="userrole",
        create_type=False,
    )
    userrole.create(op.get_bind(), checkfirst=True)

    orderstatus = postgresql.ENUM(
        "creee",
        "acceptee",
        "annulee",
        "en_preparation",
        "prelevee_partiellement",
        "en_verification",
        "prete",
        "en_route",
        "livree",
        "refusee",
        "retournee",
        "livree_partiellement",
        name="orderstatus",
        create_type=False,
    )
    orderstatus.create(op.get_bind(), checkfirst=True)

    # --- Tables ---
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", userrole, nullable=False),
        sa.Column("nom", sa.String(255), nullable=False),
        sa.Column("adresse", sa.String(500), nullable=True),
        sa.Column("secteur", sa.String(100), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "medicaments",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("code_article", sa.String(50), nullable=False),
        sa.Column("designation", sa.String(500), nullable=False),
        sa.Column("dci", sa.String(255), nullable=True),
        sa.Column("dosage", sa.String(100), nullable=True),
        sa.Column("forme", sa.String(100), nullable=True),
        sa.Column("ppa", sa.Numeric(10, 2), nullable=False),
        sa.Column("fabricant", sa.String(255), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code_article"),
    )
    op.create_index("ix_medicaments_code_article", "medicaments", ["code_article"])

    op.create_table(
        "commandes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("reference_id", sa.String(20), nullable=False),
        sa.Column("pharmacien_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("operatrice_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("statut", orderstatus, nullable=False, server_default="creee"),
        sa.Column("montant_total", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("commercial", sa.String(255), nullable=True),
        sa.Column("date_validation", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("reference_id"),
    )
    op.create_index("ix_commandes_reference_id", "commandes", ["reference_id"])

    op.create_table(
        "lignes_commande",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("commande_id", sa.Uuid(), sa.ForeignKey("commandes.id"), nullable=False),
        sa.Column("medicament_id", sa.Uuid(), sa.ForeignKey("medicaments.id"), nullable=False),
        sa.Column("designation", sa.String(500), nullable=False),
        sa.Column("qte_demandee", sa.Integer(), nullable=False),
        sa.Column("prix_unitaire", sa.Numeric(10, 2), nullable=False),
        sa.Column("n_lot", sa.String(50), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "factures",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("reference_id", sa.String(20), nullable=False),
        sa.Column("commande_id", sa.Uuid(), sa.ForeignKey("commandes.id"), nullable=False),
        sa.Column("date_emission", sa.DateTime(timezone=True), nullable=False),
        sa.Column("montant_ht", sa.Numeric(12, 2), nullable=False),
        sa.Column("montant_ttc", sa.Numeric(12, 2), nullable=False),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("reference_id"),
    )

    op.create_table(
        "bons_livraison",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("commande_id", sa.Uuid(), sa.ForeignKey("commandes.id"), nullable=False),
        sa.Column("code_barre", sa.String(100), nullable=False),
        sa.Column("date_emission", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code_barre"),
    )

    op.create_table(
        "feuilles_route",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("camion_id", sa.String(50), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("ligne", sa.String(100), nullable=True),
        sa.Column("n_rotation", sa.String(50), nullable=True),
        sa.Column("compteurs", postgresql.JSONB(), nullable=False, server_default="{}"),
        sa.Column("signature_expedition", sa.LargeBinary(), nullable=True),
        sa.Column("signature_chauffeur", sa.LargeBinary(), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "audit_log",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("entity_type", sa.String(50), nullable=False),
        sa.Column("entity_id", sa.Uuid(), nullable=False),
        sa.Column("action", sa.String(50), nullable=False),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column(
            "timestamp", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("old_value", postgresql.JSONB(), nullable=True),
        sa.Column("new_value", postgresql.JSONB(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_audit_log_entity_type", "audit_log", ["entity_type"])
    op.create_index("ix_audit_log_entity_id", "audit_log", ["entity_id"])

    # --- PostgreSQL sequences for reference IDs ---
    op.execute("CREATE SEQUENCE IF NOT EXISTS commande_seq START 1")
    op.execute("CREATE SEQUENCE IF NOT EXISTS facture_seq START 1")
    op.execute("CREATE SEQUENCE IF NOT EXISTS bl_seq START 1")
    op.execute("CREATE SEQUENCE IF NOT EXISTS prelevement_seq START 1")


def downgrade() -> None:
    op.execute("DROP SEQUENCE IF EXISTS prelevement_seq")
    op.execute("DROP SEQUENCE IF EXISTS bl_seq")
    op.execute("DROP SEQUENCE IF EXISTS facture_seq")
    op.execute("DROP SEQUENCE IF EXISTS commande_seq")

    op.drop_table("audit_log")
    op.drop_table("feuilles_route")
    op.drop_table("bons_livraison")
    op.drop_table("factures")
    op.drop_table("lignes_commande")
    op.drop_table("commandes")
    op.drop_table("medicaments")
    op.drop_table("users")

    op.execute("DROP TYPE IF EXISTS orderstatus")
    op.execute("DROP TYPE IF EXISTS userrole")
