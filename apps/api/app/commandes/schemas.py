from datetime import datetime
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
    n_lot: str | None

    model_config = {"from_attributes": True}


class OrderResponse(BaseModel):
    id: UUID
    reference_id: str
    statut: str
    montant_total: float
    pharmacien_id: UUID
    operatrice_id: UUID | None
    commercial: str | None
    created_at: datetime
    date_validation: datetime | None
    camion_id: UUID | None = None
    camion_nom: str | None = None
    pharmacien_nom: str | None = None
    pharmacien_email: str | None = None

    model_config = {"from_attributes": True}


class OrderDetailResponse(OrderResponse):
    lignes: list[LigneResponse]
