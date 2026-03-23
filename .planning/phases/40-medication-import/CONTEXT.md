# Phase 40 Context: Medication Import

**Phase goal:** Medication catalog populated from Articles.xlsx and queryable via API.

**Requirements:** MED-01, MED-02, MED-03

## Source File: Articles.xlsx

- Sheet: "Exportation SAPUI5 (2)"
- 200 rows (articles)
- Columns: Numéro d'article, Description d'article, Lot, Date de production, Date péremption/DLC, prix vente, PPA, UG vente, Nom du fournisseur

## Decisions

### Column Mapping

| Excel Column | Model Field | Notes |
|-------------|------------|-------|
| Numéro d'article | code_article | String, unique |
| Description d'article | designation | Full name + dosage + forme |
| PPA | ppa | Decimal (DA) |
| Nom du fournisseur | fabricant | String |
| Lot | — | Ignored (lot info is per-order in M2) |
| Date de production | — | Ignored |
| Date péremption/DLC | — | Ignored |
| prix vente | — | Ignored (PPA is the regulatory price) |
| UG vente | — | Ignored |

- **dci, dosage, forme** : left null for now. Will be enriched later (OCR in M2 or manual).

### Import Script

- CLI command: `python -m app.cli import-articles --file Articles.xlsx`
- Uses openpyxl to read Excel
- Validates: code_article not empty, ppa is numeric and > 0
- Skip rows with invalid data, log warnings
- Upsert: if code_article exists, update designation/ppa/fabricant. If new, insert.
- Report: "Imported X new, updated Y, skipped Z"
- Add openpyxl to pyproject.toml dependencies

### Search API

- **Fuzzy search with pg_trgm** (PostgreSQL trigram extension)
- GET /medicaments?search=paracetamol&limit=20&offset=0
- Enable pg_trgm extension in Alembic migration
- Create GIN trigram index on `designation` column
- Use `similarity()` function for ranking, threshold 0.3
- Fallback to ILIKE if pg_trgm not available
- Pagination: limit/offset with total count

### Endpoint

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /medicaments | Any authenticated | Search/list medications, paginated |
| GET | /medicaments/{id} | Any authenticated | Get single medication by UUID |

## Code Context

- `apps/api/app/models/medicament.py` — Medicament model (exists)
- `apps/api/app/cli.py` — CLI script (exists, add import-articles command)
- `Articles.xlsx` — Source file at repo root

## Deferred Ideas

- Parse DCI/dosage/forme from description via regex — fragile, do when needed
- Lot tracking table — belongs to M2 (preparation module)
- Admin UI for medication CRUD — add if users request it

---
*Created: 2026-03-23 after discuss-phase 40*
