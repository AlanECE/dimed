# Phase 60 Context: Documents API

**Phase goal:** Automatic generation of invoices, delivery notes, and route sheets.

**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05

## Decisions

### Document Generation

- **Format:** PDF via reportlab
- **Barcode:** python-barcode (Code128) for BL code-barre
- **Storage:** Local filesystem `storage/documents/{type}/{reference_id}.pdf`
- **Trigger:** Auto-generated when order transitions to Acceptee (facture + BL)

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /documents/facture/{commande_id} | operatrice, admin, pharmacien (own) | Download facture PDF |
| GET | /documents/bl/{commande_id} | operatrice, admin | Download BL PDF |
| POST | /feuilles-route | operatrice, admin | Create/update route sheet for a truck |
| GET | /feuilles-route/{id} | operatrice, admin, livreur | Get route sheet details |
| PATCH | /feuilles-route/{id}/assign | operatrice, admin | Assign order(s) to route sheet |

### Facture PDF Content
- Header: SPA DIMED PHARMA, date
- Reference: N. facture (from PG sequence)
- Client: pharmacien name, address
- Table: designation, qte, PPA, total per line
- Footer: montant total (no taxes in v1)

### BL PDF Content
- Reference: BL reference_id (from PG sequence)
- Barcode: Code128 of the BL reference_id (scannable)
- Client info, order reference, article list

### Route Sheet
- One active per truck (RG-1-05)
- Contains ordered list of clients with commandes, factures, compteurs
- Signatures fields (expedition + chauffeur) — captured in M3

### Dependencies to Add
- `reportlab>=4.0`
- `python-barcode>=0.15`

## Code Context
- `app/models/document.py` — Facture, BonDeLivraison, FeuilleDeRoute models
- `app/models/references.py` — next_facture_ref, next_bl_ref
- `app/commandes/service.py` — transition_order (hook doc generation on accept)

---
*Created: 2026-03-23*
