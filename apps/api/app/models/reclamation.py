import enum
from uuid import UUID, uuid4

from sqlalchemy import Enum, ForeignKey, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AuditMixin, Base


class ReclamationMotif(enum.StrEnum):
    PRODUIT_ENDOMMAGE = "produit_endommage"
    PRODUIT_MANQUANT = "produit_manquant"
    ERREUR_FACTURATION = "erreur_facturation"
    ERREUR_PRODUIT = "erreur_produit"
    AUTRE = "autre"


class ReclamationStatut(enum.StrEnum):
    OUVERTE = "ouverte"
    EN_COURS = "en_cours"
    RESOLUE = "resolue"
    REJETEE = "rejetee"


class Reclamation(AuditMixin, Base):
    __tablename__ = "reclamations"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    pharmacien_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    commande_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("commandes.id"), nullable=False)
    motif: Mapped[ReclamationMotif] = mapped_column(
        Enum(ReclamationMotif, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    statut: Mapped[ReclamationStatut] = mapped_column(
        Enum(ReclamationStatut, values_callable=lambda e: [m.value for m in e]),
        nullable=False,
        default=ReclamationStatut.OUVERTE,
    )
    resolution: Mapped[str | None] = mapped_column(Text, nullable=True)
