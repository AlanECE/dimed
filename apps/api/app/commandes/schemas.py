from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class ArticleItem(BaseModel):
    medicament_id: UUID
    qte: int = Field(gt=0)


class CreateOrderRequest(BaseModel):
    articles: list[ArticleItem] = Field(min_length=1)


class AssignCamionRequest(BaseModel):
    camion_id: UUID


class LigneResponse(BaseModel):
    id: UUID
    medicament_id: UUID
    designation: str
    qte_demandee: int
    prix_unitaire: float
    remise_pct: float = 0.0
    ocr_verifie: bool = False
    n_lot: str | None

    model_config = {"from_attributes": True}


class LineRemise(BaseModel):
    ligne_id: UUID
    remise_pct: Decimal = Field(ge=0, le=100, max_digits=5, decimal_places=2)


class UpdateRemisesRequest(BaseModel):
    lines: list[LineRemise] = Field(min_length=1)


class CaddieResponse(BaseModel):
    id: UUID
    numero: str
    created_at: datetime

    model_config = {"from_attributes": True}


class CaddieAssignment(BaseModel):
    commande_id: UUID
    numeros: list[str] = Field(min_length=1, max_length=20)


class BulkClaimRequest(BaseModel):
    commande_ids: list[UUID] = Field(min_length=1, max_length=50)
    preparateur_id: UUID | None = None
    caddies: list[CaddieAssignment] = Field(min_length=1)


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
    caddies: list[CaddieResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class OrderDetailResponse(OrderResponse):
    lignes: list[LigneResponse]
