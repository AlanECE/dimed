from uuid import UUID

from pydantic import BaseModel, Field


class PadTirResponse(BaseModel):
    id: str
    code: str
    nom: str
    actif: bool


class ColisContenuItem(BaseModel):
    designation: str
    quantite: int


class ColisDetailResponse(BaseModel):
    id: str
    numero: str
    statut: str
    index_colis: int
    nb_colis: int
    commande_id: str
    commande_ref: str
    commande_statut: str
    date_commande: str
    pharmacien_nom: str
    pharmacien_adresse: str | None
    pharmacien_secteur: str | None
    pad: PadTirResponse | None
    pad_suggere: PadTirResponse | None
    pad_impose: bool
    contenu: list[ColisContenuItem]
    contenu_detaille: bool


class DeposePadRequest(BaseModel):
    pad_tir_id: UUID


class ScanChargementResponse(BaseModel):
    numero: str
    commande_ref: str
    charges: int
    total: int
    commande_complete: bool
    deja_scanne: bool = False


class ScanLivraisonResponse(BaseModel):
    numero: str
    commande_ref: str
    livres: int
    total: int
    commande_complete: bool
    deja_scanne: bool = False


class ChargementColisItem(BaseModel):
    numero: str
    index_colis: int
    statut: str


class ChargementCommandeState(BaseModel):
    commande_id: str
    commande_ref: str
    pharmacien_nom: str
    statut: str
    total: int
    charges: int
    colis: list[ChargementColisItem]


class ChargementStateResponse(BaseModel):
    feuille_id: str
    total: int
    charges: int
    commandes: list[ChargementCommandeState]


class PadOccupationCommande(BaseModel):
    commande_ref: str
    pharmacien_nom: str
    poses: int
    total: int


class PadOccupationResponse(BaseModel):
    id: str
    code: str
    nom: str
    actif: bool
    nb_colis: int
    commandes: list[PadOccupationCommande]


class CreatePadRequest(BaseModel):
    code: str = Field(min_length=1, max_length=20)
    nom: str = Field(min_length=1, max_length=100)


class UpdatePadRequest(BaseModel):
    code: str | None = Field(default=None, min_length=1, max_length=20)
    nom: str | None = Field(default=None, min_length=1, max_length=100)
    actif: bool | None = None


class RepartitionLigneItem(BaseModel):
    ligne_id: UUID
    quantite: int = Field(ge=1)


class RepartitionColisItem(BaseModel):
    colis_id: UUID
    lignes: list[RepartitionLigneItem]


class RepartitionRequest(BaseModel):
    repartition: list[RepartitionColisItem]
