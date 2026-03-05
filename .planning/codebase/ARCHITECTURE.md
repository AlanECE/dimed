# Architecture

**Analysis Date:** 2026-03-05

## Pattern Overview

**Overall:** Modular Pipeline Architecture (sequential processing stages)

**Key Characteristics:**
- Linear pipeline: Image -> Preprocess -> OCR -> Extract -> Reliability -> Output
- Two public API functions: `extract()` and `match()` in `ocr/src/dimed_ocr/__init__.py`
- Graceful degradation throughout: missing fields become `None` + warnings, never crashes
- Protocol-based abstractions for external dependencies (DB, OCR reader)
- Lazy imports for heavy dependencies (EasyOCR, torch) to minimize startup time

## Layers

**Public API Layer:**
- Purpose: Single entry points for library consumers
- Location: `ocr/src/dimed_ocr/__init__.py`
- Contains: `extract(image_path)` and `match(record, db)` functions
- Depends on: pipeline, matching, models
- Used by: CLI, external consumers

**CLI Layer:**
- Purpose: Batch processing of image directories with multi-format output
- Location: `ocr/src/dimed_ocr/cli.py`
- Contains: `main()` argparse entry, `run_batch()`, `find_images()`
- Depends on: Public API (`extract`), writers, summary
- Used by: End users via `dimed-ocr batch <directory>`

**Pipeline Layer:**
- Purpose: Sequential image processing stages
- Location: `ocr/src/dimed_ocr/pipeline/`
- Contains: preprocessor, cropping, orientation, ocr_engine, extractor, reliability
- Depends on: models, config, OpenCV, EasyOCR
- Used by: Public API `extract()` function

**Matching Layer:**
- Purpose: Fuzzy matching of extracted records against medication databases
- Location: `ocr/src/dimed_ocr/matching/`
- Contains: `MedicationDB` Protocol, `match_record()`, `MockMedicationDB`
- Depends on: models, config, rapidfuzz
- Used by: Public API `match()` function

**Models Layer:**
- Purpose: Domain data structures (Pydantic for domain, dataclasses for transport)
- Location: `ocr/src/dimed_ocr/models/`
- Contains: `MedicationRecord`, `OcrResult`, `ExtractionResult`, `PreprocessResult`
- Depends on: pydantic, numpy (for `PreprocessResult`)
- Used by: All other layers

**Writers Layer:**
- Purpose: Serialize extraction results to persistent formats
- Location: `ocr/src/dimed_ocr/writers/`
- Contains: `write_csv()`, `write_json()`, `write_sqlite()`
- Depends on: models (MedicationRecord)
- Used by: CLI batch processing

**Config Layer:**
- Purpose: Centralized constants for all pipeline parameters
- Location: `ocr/src/dimed_ocr/config.py`
- Contains: Thresholds, OCR settings, preprocessing parameters
- Depends on: Nothing
- Used by: pipeline, matching, summary

## Data Flow

**Main Extraction Pipeline:**

1. `extract(image_path)` in `ocr/src/dimed_ocr/__init__.py` orchestrates the full pipeline
2. `preprocess(path)` in `ocr/src/dimed_ocr/pipeline/preprocessor.py`: loads image -> crops WhatsApp overlay -> crops to label contour -> detects/corrects orientation -> grayscale -> CLAHE contrast -> denoise -> binarize -> returns `PreprocessResult`
3. `run_ocr(binarized_image)` in `ocr/src/dimed_ocr/pipeline/ocr_engine.py`: singleton EasyOCR reader -> returns `list[OcrResult]`
4. `extract_fields(detections)` in `ocr/src/dimed_ocr/pipeline/extractor.py`: filters WhatsApp noise -> regex-based field extraction -> returns `ExtractionResult` with `MedicationRecord`
5. `apply_confidence_checks(record)` in `ocr/src/dimed_ocr/pipeline/reliability.py`: flags low-confidence fields -> sets `needs_review` and `fields_to_review`

**Matching Flow (optional, separate call):**

1. `match(record, db)` in `ocr/src/dimed_ocr/__init__.py`
2. `match_record(record, db)` in `ocr/src/dimed_ocr/matching/matcher.py`: normalize name -> search DB -> fuzzy score candidates -> ambiguity check -> secondary validation (lot, dates, PPA) -> composite score -> returns `MatchResult`

**Batch CLI Flow:**

1. `main()` in `ocr/src/dimed_ocr/cli.py` parses `batch <directory> --output <dir>`
2. `find_images()` scans directory for `.png`, `.jpg`, `.jpeg` files
3. Iterates: calls `extract()` per image, collects `MedicationRecord` list
4. Writes all three formats: CSV (UTF-8 BOM), SQLite, JSON
5. Generates text summary via `ocr/src/dimed_ocr/summary.py`

**State Management:**
- No persistent state between calls. Each `extract()` is stateless.
- EasyOCR reader is a module-level singleton in `ocr/src/dimed_ocr/pipeline/ocr_engine.py` (lazy init, `reset_reader()` for tests)
- A second EasyOCR singleton exists in `ocr/src/dimed_ocr/pipeline/orientation.py` for orientation detection

## Key Abstractions

**MedicationRecord (Pydantic BaseModel):**
- Purpose: Central domain object carrying all extracted medication data
- Location: `ocr/src/dimed_ocr/models/medication.py`
- Pattern: Pydantic model with optional fields, confidence scores, review flags
- Fields: `nom_commercial`, `dci`, `dosage`, `forme`, `numero_lot`, `date_fabrication`, `date_peremption`, `ppa`, `fabricant`, `nom_arabe`

**MedicationDB (Protocol):**
- Purpose: Abstract interface for medication database backends
- Location: `ocr/src/dimed_ocr/matching/protocol.py`
- Pattern: `@runtime_checkable Protocol` with `search()`, `all_candidates()`, `get_by_id()`
- Implementations: `MockMedicationDB` (10 Algerian medications, same file)

**EasyOcrReader (Protocol):**
- Purpose: Abstract OCR engine interface for testability
- Location: `ocr/src/dimed_ocr/pipeline/ocr_engine.py`
- Pattern: Protocol with single `readtext()` method, allows mocking in tests

**PreprocessResult (dataclass):**
- Purpose: Transport object carrying preprocessing outputs and metadata
- Location: `ocr/src/dimed_ocr/models/preprocess.py`
- Pattern: Dataclass with numpy arrays, quality score, transformation log

**ExtractionResult (dataclass):**
- Purpose: Wraps MedicationRecord with raw OCR data and timing info
- Location: `ocr/src/dimed_ocr/models/ocr_result.py`
- Pattern: Dataclass linking processed record to raw detections

## Entry Points

**Library API:**
- Location: `ocr/src/dimed_ocr/__init__.py`
- Functions: `extract(image_path)` -> `ExtractionResult`, `match(record, db)` -> `MatchResult`
- Usage: `from dimed_ocr import extract, match`

**CLI:**
- Location: `ocr/src/dimed_ocr/cli.py`
- Entry: `dimed-ocr batch <directory> [--output <dir>]`
- Registered: `pyproject.toml` `[project.scripts]` -> `dimed_ocr.cli:main`

## Error Handling

**Strategy:** Graceful degradation with warnings. Never crash on bad input.

**Patterns:**
- `extract()` wraps everything in try/except, returns empty `MedicationRecord` with `needs_review=True` on failure
- `run_ocr()` catches all exceptions, returns empty list with warning log
- `preprocess()` catches per-step failures (crop, orientation), adds warnings, continues pipeline
- `extract_fields()` never raises: missing fields stay `None`
- Only hard failure: `FileNotFoundError` when image cannot be loaded in `preprocess()`

## Cross-Cutting Concerns

**Logging:** Python `logging` module. Each module creates `logger = logging.getLogger(__name__)`. NullHandler on root package. Levels: DEBUG for raw OCR text, INFO for quality scores, WARNING for failures/low confidence.

**Validation:** Pydantic `model_validator` on `MedicationRecord` ensures confidence scores in 0.0-1.0 range. No input validation on image files beyond load check.

**Authentication:** Not applicable (local CLI tool, no network auth).

**Configuration:** Module-level constants in `ocr/src/dimed_ocr/config.py`. No env vars, no config files. All settings are importable Python constants.

---

*Architecture analysis: 2026-03-05*
