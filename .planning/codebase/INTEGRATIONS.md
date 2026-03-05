# External Integrations

**Analysis Date:** 2026-03-05

## APIs & External Services

**OCR Engine (EasyOCR):**
- EasyOCR 1.7.2 - Local OCR, no API calls at runtime
- Models downloaded from HuggingFace Hub on first initialization
- Singleton pattern at `ocr/src/dimed_ocr/pipeline/ocr_engine.py`
- Languages: French (`["fr"]`)
- GPU auto-detection with CPU fallback

**OpenRouter (experimental/prototype only):**
- `ocr/test_openrouter_ocr.py` - Standalone prototype script (NOT part of main package)
- Uses Mistral Small 3.1 vision model via OpenRouter API
- Endpoint: `https://openrouter.ai/api/v1/chat/completions`
- Model: `mistralai/mistral-small-3.1-24b-instruct:free`
- Auth: API key hardcoded in script (security issue - this file should not be committed)
- Not integrated into the main `dimed_ocr` package pipeline

## Data Storage

**Databases:**
- SQLite (stdlib `sqlite3`) - Output writer only, no persistent application database
  - Writer: `ocr/src/dimed_ocr/writers/sqlite_writer.py`
  - Creates `results.db` with `medications` table (DROP + CREATE on each batch run)
  - Schema: 15 columns including `source_file`, medication fields, `confidence_scores` (JSON), `warnings` (JSON)

**File Storage:**
- Local filesystem only
- Input: image files (PNG, JPG, JPEG) from `ocr/Etiquettes/` directory (31 reference photos)
- Output directory: `ocr/output/` (configurable via CLI `--output` flag)
- Output formats:
  - CSV (UTF-8 BOM): `ocr/src/dimed_ocr/writers/csv_writer.py`
  - JSON: `ocr/src/dimed_ocr/writers/json_writer.py`
  - SQLite: `ocr/src/dimed_ocr/writers/sqlite_writer.py`
  - Summary text: `ocr/src/dimed_ocr/summary.py`

**Caching:**
- EasyOCR model cache: default HuggingFace cache directory (`~/.cache/huggingface/`)
- EasyOCR Reader singleton: in-memory singleton at module level (`_reader` global)

## Authentication & Identity

**Auth Provider:**
- None - CLI tool with no authentication
- No user management, no sessions

## Medication Database

**Current Implementation:**
- `MedicationDB` is a `Protocol` (abstract interface) at `ocr/src/dimed_ocr/matching/protocol.py`
- Only implementation: `MockMedicationDB` (same file) - hardcoded list of 10 Algerian medications
- Protocol methods: `search(name)`, `all_candidates()`, `get_by_id(id)`
- Designed for future replacement with real database adapter (not yet implemented)
- No external database connection exists

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry, no error reporting service)

**Logs:**
- Python `logging` module throughout all modules
- `NullHandler` on root logger (`ocr/src/dimed_ocr/__init__.py`)
- Debug-level logs for raw OCR text, extraction records
- Warning-level logs for OCR failures, low quality images
- No structured logging, no log aggregation

## CI/CD & Deployment

**Hosting:**
- Local CLI tool, no deployment target configured
- No Dockerfile, no docker-compose, no cloud config

**CI Pipeline:**
- None configured (no GitHub Actions, no CI files)

## Environment Configuration

**Required env vars:**
- None - all config is hardcoded in `ocr/src/dimed_ocr/config.py`

**Secrets:**
- No secrets required for the main package
- `ocr/test_openrouter_ocr.py` contains a hardcoded OpenRouter API key (security concern, not part of main package)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## HuggingFace Hub (Model Downloads)

**Purpose:** EasyOCR model download on first use
- Package: `huggingface_hub 1.5.0` (transitive dependency)
- Downloads French text recognition model
- Cached locally after first download
- No API key required for public models
- Network access required only on first initialization

## Integration Readiness

**Designed but not yet connected:**
- `MedicationDB` Protocol at `ocr/src/dimed_ocr/matching/protocol.py` - ready for real database adapter
- Writer system supports CSV/JSON/SQLite output - ready for upstream consumption
- No REST API or web interface exists yet

---

*Integration audit: 2026-03-05*
