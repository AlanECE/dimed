# Phase 50 Context: Orders API

**Phase goal:** Full order management through API — create, validate, reject, list, filter.

**Requirements:** ORD-01, ORD-02, ORD-03, ORD-04, ORD-06

## Decisions

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /commandes | pharmacien | Create order from cart |
| GET | /commandes | pharmacien, operatrice, admin | List orders (filtered) |
| GET | /commandes/{id} | pharmacien (own), operatrice, admin | Order detail with lines |
| PATCH | /commandes/{id}/accept | operatrice, admin | Validate order → Acceptee |
| PATCH | /commandes/{id}/reject | operatrice, admin | Reject order → Annulee |
| PATCH | /commandes/{id}/cancel | pharmacien (own) | Cancel own order → Annulee |

### Create Order (POST /commandes)

**Request payload:**
```json
{
  "articles": [
    {"medicament_id": "uuid", "qte": 10},
    {"medicament_id": "uuid", "qte": 5}
  ]
}
```

**Server-side logic:**
1. Validate all medicament_ids exist in DB (reject 400 if any not found)
2. Generate reference_id via `next_commande_ref(db)` (séquence PG)
3. Fetch PPA from medicaments table for each article
4. Create LigneCommande for each article: designation=medicament.designation, prix_unitaire=medicament.ppa
5. Calculate montant_total = sum(qte * ppa) — no taxes, no remises
6. Set pharmacien_id = current_user.id
7. Set statut = Creee
8. Return order with lines

**No stock check.** Only verify medicament exists.

### Montant Calculation

- **Server calculates everything.** Client never sends prices.
- `montant_total = sum(ligne.qte_demandee * ligne.prix_unitaire)` for all lines
- PPA comes from medicaments table at order creation time (snapshot)
- No taxes, no remises in v1. montant_total = montant brut.

### Accept / Reject

- **Accept (PATCH /commandes/{id}/accept):**
  - Uses `validate_transition(current_status, OrderStatus.ACCEPTEE)`
  - Sets operatrice_id = current_user.id
  - Sets date_validation = now()
  - Triggers document generation in Phase 60 (not in scope here)

- **Reject (PATCH /commandes/{id}/reject):**
  - Uses `validate_transition(current_status, OrderStatus.ANNULEE)`
  - No motif in v1

### Cancel (pharmacien)

- **Cancel (PATCH /commandes/{id}/cancel):**
  - Only own orders (pharmacien_id == current_user.id)
  - Only if status is Creee (before validation)
  - Uses `validate_transition(current_status, OrderStatus.ANNULEE)`

### Filtering & Pagination

**GET /commandes** query params:
- `statut: str | None` — filter by order status
- `date_from: date | None` — orders created after this date
- `date_to: date | None` — orders created before this date
- `pharmacien_id: UUID | None` — filter by pharmacist (operatrice/admin only)
- `limit: int = 20` (max 100)
- `offset: int = 0`

**Default sort:** `created_at DESC` (most recent first)

**Access control:**
- Pharmacien sees only own orders (forced filter on pharmacien_id)
- Operatrice/admin sees all orders

### Response Schemas

**OrderResponse:**
```python
class OrderResponse(BaseModel):
    id: str
    reference_id: str
    statut: str
    montant_total: float
    pharmacien_id: str
    operatrice_id: str | None
    commercial: str | None
    created_at: datetime
    date_validation: datetime | None
```

**OrderDetailResponse (with lines):**
```python
class OrderDetailResponse(OrderResponse):
    lignes: list[LigneResponse]

class LigneResponse(BaseModel):
    id: str
    medicament_id: str
    designation: str
    qte_demandee: int
    prix_unitaire: float
    n_lot: str | None
```

## Code Context

- `app/models/commande.py` — Commande, LigneCommande, OrderStatus
- `app/models/state_machine.py` — validate_transition()
- `app/models/references.py` — next_commande_ref()
- `app/auth/dependencies.py` — CurrentUser, require_roles
- `app/medicaments/router.py` — pattern for router structure

## Deferred Ideas

- Validation partielle (valider certains articles seulement) — v2
- Motif de refus/annulation — v2
- Commercial auto-assigned — à clarifier avec le client

---
*Created: 2026-03-23 after discuss-phase 50*
