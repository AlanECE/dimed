"""Colis traçables (QR), pads de tir, scans + role magasinier

Revision ID: 016
Revises: 015
"""

from collections.abc import Sequence
from uuid import uuid4

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "016"
down_revision: str | None = "015"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # --- Nouveau rôle magasinier (valeur d'enum PG non utilisée dans cette migration) ---
    op.execute("ALTER TYPE userrole ADD VALUE IF NOT EXISTS 'magasinier'")

    # --- Enum types ---
    colisstatus = postgresql.ENUM(
        "etiquete",
        "sur_pad",
        "charge",
        "livre",
        name="colisstatus",
        create_type=False,
    )
    colisstatus.create(op.get_bind(), checkfirst=True)

    scantype = postgresql.ENUM(
        "depot_pad",
        "chargement",
        "livraison",
        name="scantype",
        create_type=False,
    )
    scantype.create(op.get_bind(), checkfirst=True)

    # --- Séquence des numéros de colis (CLS00000001) ---
    op.execute("CREATE SEQUENCE IF NOT EXISTS colis_seq START 1")

    # --- pads_tir ---
    pads_tir = op.create_table(
        "pads_tir",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("code", sa.String(length=20), nullable=False, unique=True),
        sa.Column("nom", sa.String(length=100), nullable=False),
        sa.Column("actif", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
    )

    # --- colis ---
    op.create_table(
        "colis",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("numero", sa.String(length=20), nullable=False),
        sa.Column(
            "commande_id",
            sa.Uuid(),
            sa.ForeignKey("commandes.id"),
            nullable=False,
        ),
        sa.Column("index_colis", sa.Integer(), nullable=False),
        sa.Column(
            "statut",
            colisstatus,
            nullable=False,
            server_default="etiquete",
        ),
        sa.Column("pad_tir_id", sa.Uuid(), sa.ForeignKey("pads_tir.id"), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.UniqueConstraint("numero", name="uq_colis_numero"),
        sa.UniqueConstraint("commande_id", "index_colis", name="uq_colis_commande_index"),
    )
    op.create_index("ix_colis_numero", "colis", ["numero"])
    op.create_index("ix_colis_commande_id", "colis", ["commande_id"])

    # --- colis_lignes (répartition optionnelle du contenu) ---
    op.create_table(
        "colis_lignes",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("colis_id", sa.Uuid(), sa.ForeignKey("colis.id"), nullable=False),
        sa.Column(
            "ligne_commande_id",
            sa.Uuid(),
            sa.ForeignKey("lignes_commande.id"),
            nullable=False,
        ),
        sa.Column("quantite", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.UniqueConstraint("colis_id", "ligne_commande_id", name="uq_colis_lignes_colis_ligne"),
    )
    op.create_index("ix_colis_lignes_colis_id", "colis_lignes", ["colis_id"])

    # --- scans_colis (audit des scans) ---
    op.create_table(
        "scans_colis",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("colis_id", sa.Uuid(), sa.ForeignKey("colis.id"), nullable=False),
        sa.Column("type_scan", scantype, nullable=False),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("pad_tir_id", sa.Uuid(), sa.ForeignKey("pads_tir.id"), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("created_by", sa.Uuid(), nullable=True),
    )
    op.create_index("ix_scans_colis_colis_id", "scans_colis", ["colis_id"])

    # --- Seed pads de tir ---
    op.bulk_insert(
        pads_tir,
        [
            {
                "id": uuid4(),
                "code": f"PAD-{i:02d}",
                "nom": f"Pad de tir {i}",
                "actif": True,
                "created_by": None,
            }
            for i in range(1, 7)
        ],
    )


def downgrade() -> None:
    op.drop_index("ix_scans_colis_colis_id", table_name="scans_colis")
    op.drop_table("scans_colis")
    op.drop_index("ix_colis_lignes_colis_id", table_name="colis_lignes")
    op.drop_table("colis_lignes")
    op.drop_index("ix_colis_commande_id", table_name="colis")
    op.drop_index("ix_colis_numero", table_name="colis")
    op.drop_table("colis")
    op.drop_table("pads_tir")
    op.execute("DROP TYPE IF EXISTS scantype")
    op.execute("DROP TYPE IF EXISTS colisstatus")
    op.execute("DROP SEQUENCE IF EXISTS colis_seq")
    # NB : la valeur 'magasinier' de l'enum userrole ne peut pas être retirée proprement
    # (PostgreSQL ne supporte pas ALTER TYPE ... DROP VALUE) — elle reste en place.
