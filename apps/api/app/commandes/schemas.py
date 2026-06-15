from datetime import date, datetime
from decimal import Decimal
from enum import StrEnum
from uuid import UUID

from pydantic import BaseModel, Field


class ArticleItem(BaseModel):
    medicament_id: UUID
    qte: int = Field(gt=0)


class CreateOrderRequest(BaseModel):
    articles: list[ArticleItem] = Field(min_length=1)
    pharmacien_id: UUID | None = None  # operatrice only — create on behalf of a pharmacien


class AssignCamionRequest(BaseModel):
    camion_id: UUID


class LigneResponse(BaseModel):
    id: UUID
    medicament_id: UUID
    designation: str
    qte_demandee: int
    prix_unitaire: float
    remise_pct: float = 0.0
    n_lot: str | None = None
    fab: date | None = None
    exp: date | None = None
    ppa: Decimal | None = None

    model_config = {"from_attributes": True}


class LineRemise(BaseModel):
    ligne_id: UUID
    remise_pct: Decimal = Field(ge=0, le=100, max_digits=5, decimal_places=2)


class UpdateRemisesRequest(BaseModel):
    lines: list[LineRemise] = Field(min_length=1)


class CaddiePoolResponse(BaseModel):
    id: UUID
    numero: str
    is_available: bool
    current_commande_ref: str | None = None

    model_config = {"from_attributes": True}


class StartPreparationRequest(BaseModel):
    caddie_pool_id: UUID


class OrderResponse(BaseModel):
    id: UUID
    reference_id: str
    statut: str
    montant_total: float
    pharmacien_id: UUID
    operatrice_id: UUID | None
    preparateur_id: UUID | None = None
    preparateur_nom: str | None = None
    commercial: str | None
    created_at: datetime
    date_validation: datetime | None
    camion_id: UUID | None = None
    camion_nom: str | None = None
    pharmacien_nom: str | None = None
    pharmacien_email: str | None = None
    operatrice_comment: str | None = None
    caddie_pool: CaddiePoolResponse | None = None

    model_config = {"from_attributes": True}


class OrderDetailResponse(OrderResponse):
    lignes: list[LigneResponse]


class EditLineRequest(BaseModel):
    qte_demandee: int = Field(ge=1)


class AddLineRequest(BaseModel):
    medicament_id: UUID
    qte_demandee: int = Field(ge=1)


class UpdateCommentRequest(BaseModel):
    comment: str | None = Field(default=None, max_length=500)


class RefuseSaisieRequest(BaseModel):
    motif: str = Field(min_length=1, max_length=500)


# ---- Per-ligne OCR (vignette scan) ----


class VignetteResponse(BaseModel):
    id: UUID
    filename: str
    file_url: str
    extracted_lot: str | None = None
    extracted_fab: date | None = None
    extracted_exp: date | None = None
    extracted_ppa: Decimal | None = None
    extracted_designation: str | None = None

    model_config = {"from_attributes": True}


class LigneUpdatePreparation(BaseModel):
    qte_prelevee: int | None = Field(default=None, ge=0)
    n_lot: str | None = Field(default=None, max_length=50)
    fab: date | None = None
    exp: date | None = None
    ppa: Decimal | None = Field(default=None, max_digits=10, decimal_places=2)
    verifie: bool | None = None


class LignePreparationResponse(BaseModel):
    id: UUID
    medicament_id: UUID
    designation: str
    qte_demandee: int
    qte_prelevee: int | None = None
    prix_unitaire: Decimal
    remise_pct: Decimal = Decimal("0.00")
    n_lot: str | None = None
    fab: date | None = None
    exp: date | None = None
    ppa: Decimal | None = None
    medicament_ppa: Decimal | None = None  # catalogue PPA, used by frontend for divergence pill
    verifie: bool
    vignette: VignetteResponse | None = None


class VignetteWarning(StrEnum):
    PPA_DIVERGENT = "ppa_divergent"
    MISSING_LOT = "missing_lot"
    MISSING_FAB = "missing_fab"
    MISSING_EXP = "missing_exp"
    MISSING_PPA = "missing_ppa"


class LigneOcrResponse(BaseModel):
    ligne: LignePreparationResponse
    vignette: VignetteResponse
    warnings: list[VignetteWarning]
