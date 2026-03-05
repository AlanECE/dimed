# Codebase Structure

**Analysis Date:** 2026-03-05

## Directory Layout

```
dimed/
├── ocr/                              # OCR module (main codebase)
│   ├── src/
│   │   └── dimed_ocr/                # Python package
│   │       ├── __init__.py           # Public API: extract(), match()
│   │       ├── cli.py                # CLI entry point (argparse)
│   │       ├── config.py             # All constants/thresholds
│   │       ├── summary.py            # Text report generator
│   │       ├── models/               # Data structures
│   │       │   ├── __init__.py       # Re-exports all models
│   │       │   ├── medication.py     # MedicationRecord (Pydantic)
│   │       │   ├── ocr_result.py     # OcrResult, ExtractionResult (dataclass)
│   │       │   └── preprocess.py     # PreprocessResult (dataclass)
│   │       ├── pipeline/             # Processing stages
│   │       │   ├── __init__.py       # Re-exports preprocess()
│   │       │   ├── preprocessor.py   # Full preprocessing pipeline
│   │       │   ├── cropping.py       # WhatsApp overlay + label contour crop
│   │       │   ├── orientation.py    # Multi-angle OCR orientation detection
│   │       │   ├── ocr_engine.py     # EasyOCR singleton adapter
│   │       │   ├── extractor.py      # Regex-based field extraction
│   │       │   └── reliability.py    # Confidence threshold checks
│   │       ├── matching/             # DB matching
│   │       │   ├── __init__.py       # Re-exports all matching types
│   │       │   ├── protocol.py       # MedicationDB Protocol, MatchResult, MockDB
│   │       │   └── matcher.py        # Fuzzy matching logic (rapidfuzz)
│   │       └── writers/              # Output formatters
│   │           ├── __init__.py       # Re-exports write_csv/json/sqlite
│   │           ├── csv_writer.py     # CSV with UTF-8 BOM
│   │           ├── json_writer.py    # JSON via Pydantic model_dump
│   │           └── sqlite_writer.py  # SQLite with medications table
│   ├── tests/                        # Test suite (mirrors src structure)
│   │   ├── __init__.py
│   │   ├── conftest.py               # Shared fixtures
│   │   ├── test_imports.py           # Package import smoke tests
│   │   ├── test_cli.py               # CLI integration tests
│   │   ├── test_summary.py           # Summary generation tests
│   │   ├── test_preprocessor.py      # Preprocessing unit tests
│   │   ├── test_cropping.py          # Cropping logic tests
│   │   ├── test_orientation.py       # Orientation detection tests
│   │   ├── test_reliability.py       # Confidence check tests
│   │   ├── test_extract_api.py       # extract() API tests
│   │   ├── test_integration_preprocess.py  # Integration tests (marked)
│   │   ├── pipeline/
│   │   │   ├── __init__.py
│   │   │   ├── test_ocr_engine.py    # OCR engine tests
│   │   │   ├── test_extractor.py     # Field extraction tests
│   │   │   └── test_orientation_logic.py  # Orientation logic tests
│   │   ├── matching/
│   │   │   ├── test_protocol.py      # Protocol + MockDB tests
│   │   │   └── test_matcher.py       # Fuzzy matching tests
│   │   ├── models/
│   │   │   └── test_medication.py    # MedicationRecord model tests
│   │   └── writers/
│   │       ├── test_csv_writer.py    # CSV output tests
│   │       ├── test_json_writer.py   # JSON output tests
│   │       └── test_sqlite_writer.py # SQLite output tests
│   ├── Etiquettes/                   # 31 reference photos (PNG, real labels)
│   ├── output/                       # Generated output (results.csv/db/json, summary.txt)
│   ├── blabla/                       # Meeting notes, reports (non-code)
│   ├── pyproject.toml                # Package config, deps, pytest config
│   ├── test_openrouter_ocr.py        # Standalone experiment script
│   └── .planning/                    # GSD planning docs (phases 01-06)
├── Cahier_des_Charges_DIMED.docx     # CDC document (original)
├── CDC_Global_DIMED.docx             # CDC global
├── CDC_Module1_Commande.docx         # CDC Module 1
├── CDC_Module2_Preparation.docx      # CDC Module 2
├── CDC_Module3_Livraison.docx        # CDC Module 3
├── IMG_1251.HEIC                     # Sample photos
├── IMG_1292.PNG
├── IMG_1293.PNG
├── questions.md                      # Client meeting questions
└── .planning/                        # Top-level GSD planning
    └── codebase/                     # Codebase analysis docs (this file)
```

## Directory Purposes

**`ocr/src/dimed_ocr/`:**
- Purpose: Main Python package for OCR extraction
- Contains: All production source code
- Key files: `__init__.py` (public API), `config.py` (all constants)

**`ocr/src/dimed_ocr/models/`:**
- Purpose: Data structures for the entire pipeline
- Contains: Pydantic models (domain) and dataclasses (transport/intermediate)
- Key files: `medication.py` (central `MedicationRecord`), `ocr_result.py` (`OcrResult`, `ExtractionResult`)

**`ocr/src/dimed_ocr/pipeline/`:**
- Purpose: Sequential image processing stages
- Contains: One module per processing step
- Key files: `preprocessor.py` (orchestrates all preprocessing), `extractor.py` (regex field extraction)

**`ocr/src/dimed_ocr/matching/`:**
- Purpose: Fuzzy matching against medication databases
- Contains: Protocol definition, matcher implementation, mock DB
- Key files: `protocol.py` (interfaces + mock), `matcher.py` (scoring logic)

**`ocr/src/dimed_ocr/writers/`:**
- Purpose: Output serialization (CSV, JSON, SQLite)
- Contains: One writer per format, all share same field list
- Key files: `csv_writer.py` (UTF-8 BOM for Excel compat)

**`ocr/tests/`:**
- Purpose: Test suite mirroring src structure
- Contains: Unit tests, integration tests (marked), shared fixtures
- Key files: `conftest.py` (fixtures: `sample_image`, `mock_db`)

**`ocr/Etiquettes/`:**
- Purpose: Reference dataset of 31 real pharmaceutical label photos
- Contains: PNG images (IMG_1255 through IMG_1290)
- Generated: No (manually captured)
- Committed: Yes

**`ocr/output/`:**
- Purpose: Generated batch processing results
- Contains: `results.csv`, `results.db`, `results.json`, `summary.txt`
- Generated: Yes (by `dimed-ocr batch`)
- Committed: Yes (sample output)

## Key File Locations

**Entry Points:**
- `ocr/src/dimed_ocr/__init__.py`: Library API (`extract()`, `match()`)
- `ocr/src/dimed_ocr/cli.py`: CLI entry (`dimed-ocr` command)
- `ocr/pyproject.toml`: Package definition, script registration

**Configuration:**
- `ocr/src/dimed_ocr/config.py`: All tuneable constants (thresholds, OCR settings, preprocessing params)
- `ocr/pyproject.toml`: Dependencies, Python version, pytest markers

**Core Logic:**
- `ocr/src/dimed_ocr/pipeline/preprocessor.py`: Full image preprocessing pipeline
- `ocr/src/dimed_ocr/pipeline/extractor.py`: Regex patterns for field extraction
- `ocr/src/dimed_ocr/pipeline/ocr_engine.py`: EasyOCR adapter (singleton)
- `ocr/src/dimed_ocr/matching/matcher.py`: Fuzzy matching + composite scoring

**Testing:**
- `ocr/tests/conftest.py`: Shared fixtures
- `ocr/pyproject.toml` `[tool.pytest.ini_options]`: Test config, markers

## Naming Conventions

**Files:**
- `snake_case.py`: All Python modules (e.g., `ocr_engine.py`, `csv_writer.py`)
- `__init__.py`: Present in every package, used for re-exports

**Directories:**
- `snake_case`: All package directories (e.g., `dimed_ocr`, `pipeline`, `matching`)
- Test directories mirror source structure (`tests/pipeline/`, `tests/matching/`)

**Test Files:**
- `test_<module>.py`: Match the module they test (e.g., `test_extractor.py` tests `extractor.py`)
- Some tests at `tests/` root level for cross-cutting concerns (`test_cli.py`, `test_imports.py`)

## Where to Add New Code

**New pipeline stage:**
- Implementation: `ocr/src/dimed_ocr/pipeline/<stage_name>.py`
- Tests: `ocr/tests/pipeline/test_<stage_name>.py`
- Wire it: Add call in `ocr/src/dimed_ocr/__init__.py` `extract()` function
- Export if needed: Add to `ocr/src/dimed_ocr/pipeline/__init__.py`

**New data model:**
- Implementation: `ocr/src/dimed_ocr/models/<model_name>.py`
- Tests: `ocr/tests/models/test_<model_name>.py`
- Re-export: Add to `ocr/src/dimed_ocr/models/__init__.py`

**New output format writer:**
- Implementation: `ocr/src/dimed_ocr/writers/<format>_writer.py`
- Tests: `ocr/tests/writers/test_<format>_writer.py`
- Re-export: Add to `ocr/src/dimed_ocr/writers/__init__.py`
- Wire it: Call from `ocr/src/dimed_ocr/cli.py` `run_batch()`

**New matching strategy:**
- Implementation: New function in `ocr/src/dimed_ocr/matching/matcher.py` or new file
- Must accept `MedicationRecord` + `MedicationDB` Protocol
- Tests: `ocr/tests/matching/test_<strategy>.py`

**New CLI subcommand:**
- Add subparser in `ocr/src/dimed_ocr/cli.py` under `sub.add_parser()`
- Follow pattern of existing `batch` command

**New configuration constant:**
- Add to `ocr/src/dimed_ocr/config.py`
- Import with `from dimed_ocr import config` then `config.MY_CONSTANT`

**Shared test fixtures:**
- Add to `ocr/tests/conftest.py`

## Special Directories

**`ocr/Etiquettes/`:**
- Purpose: Real pharmaceutical label photos for testing/validation
- Generated: No (manually captured)
- Committed: Yes
- Note: Used by integration tests (marked `@pytest.mark.integration`)

**`ocr/output/`:**
- Purpose: Sample batch output (CSV, SQLite, JSON, summary)
- Generated: Yes (by CLI)
- Committed: Yes (for reference)

**`ocr/.planning/`:**
- Purpose: GSD spec-driven development planning docs
- Generated: By GSD commands
- Committed: Yes
- Contains: PROJECT.md, REQUIREMENTS.md, phases 01-06 with plans/summaries

**`ocr/blabla/`:**
- Purpose: Meeting notes, reports, misc documentation
- Generated: No (manual)
- Committed: Yes

---

*Structure analysis: 2026-03-05*
