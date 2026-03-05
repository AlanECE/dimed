# Coding Conventions

**Analysis Date:** 2026-03-05

## Naming Patterns

**Files:**
- Use `snake_case.py` for all Python modules: `csv_writer.py`, `ocr_engine.py`, `ocr_result.py`
- Test files mirror source structure with `test_` prefix: `test_extractor.py`, `test_matcher.py`
- Package directories use `snake_case`: `dimed_ocr/`, `matching/`, `pipeline/`, `writers/`

**Functions:**
- Use `snake_case` for all functions: `extract_fields()`, `run_ocr()`, `match_record()`
- Private/internal functions prefixed with `_`: `_is_noise()`, `_try_extract_field()`, `_normalize()`, `_validate_secondary()`, `_order_points()`, `_resolve_gpu_flag()`
- Factory/helper functions in tests prefixed with `_`: `_make_record()`, `_det()`, `_create_images()`

**Variables:**
- Use `snake_case` for all variables: `raw_text`, `confidence_scores`, `best_candidate`
- Module-level constants in `UPPER_SNAKE_CASE`: `CONFIDENCE_THRESHOLD`, `NOISE_PATTERNS`, `FIELD_PATTERNS`, `EXTRACT_FIELDS`, `IMAGE_EXTENSIONS`
- Module-level singleton state prefixed with `_`: `_reader`, `_debug_step_counter`

**Types/Classes:**
- Use `PascalCase` for classes: `MedicationRecord`, `PreprocessResult`, `OcrResult`, `ExtractionResult`
- Use `PascalCase` for Protocols: `MedicationDB`, `EasyOcrReader`
- No enums used anywhere; string literals for match levels: `"confirmed"`, `"review"`, `"no_match"`

**Domain-specific (French field names):**
- Medication fields use French names: `nom_commercial`, `dci`, `dosage`, `forme`, `numero_lot`, `date_fabrication`, `date_peremption`, `ppa`, `fabricant`, `nom_arabe`
- User-facing strings (CLI, summary) in French: `"Aucune image trouvee"`, `"Champs extraits"`, `"Erreurs"`
- Code comments, docstrings, and log messages in English

## Code Style

**Formatting:**
- No formatter explicitly configured (no `.prettierrc`, `ruff.toml`, or `black` config)
- `.ruff_cache/` directory present suggests ruff was used at some point
- Consistent 4-space indentation throughout

**Linting:**
- No linter configuration file present
- `# noqa: PLW0603` annotations used on global variable assignments (ruff/pylint suppression)
- `# type: ignore[import-untyped]` used for EasyOCR import (untyped library)
- `# pragma: no cover` used on defensive fallback code

**Type Hints:**
- Use `from __future__ import annotations` in most modules for PEP 604 union syntax
- All functions have full type annotations including return types
- Use `str | None` union syntax (not `Optional[str]`)
- Use `list[str]` lowercase generics (not `List[str]`)
- Use `tuple[int, int]` lowercase (not `Tuple[int, int]`)
- Use `dict[str, float]` lowercase (not `Dict[str, float]`)

## Import Organization

**Order:**
1. `from __future__ import annotations` (when present, always first)
2. Standard library imports: `logging`, `re`, `json`, `csv`, `sqlite3`, `time`, `argparse`, `sys`, `unicodedata`
3. Third-party imports: `cv2`, `numpy`, `pydantic`, `rapidfuzz`, `easyocr`, `pytest`
4. Local project imports: `from dimed_ocr.models.medication import MedicationRecord`

**Path Aliases:**
- No path aliases configured
- All imports use full dotted paths: `from dimed_ocr.pipeline.extractor import extract_fields`
- Relative imports NOT used in source code; relative import used once in tests: `from .conftest import ETIQUETTES_DIR`

**Lazy Imports:**
- Heavy dependencies imported inside functions to avoid slow startup: EasyOCR in `ocr_engine.py` and pipeline modules in `__init__.py`
- Pattern: `from dimed_ocr.pipeline.extractor import extract_fields` inside function body

## Error Handling

**Patterns:**
- **Never crash on OCR pipeline failures.** Core design principle applied throughout.
- Top-level `extract()` in `ocr/__init__.py` wraps entire pipeline in try/except, returns safe fallback `ExtractionResult` with `needs_review=True`
- `run_ocr()` catches all exceptions, returns empty list with warning log
- `preprocess()` catches individual step failures (WhatsApp crop, label crop, orientation), adds warning, continues with best-effort result
- `FileNotFoundError` raised only for missing input images (cannot continue without input)

**Exception Strategy:**
```python
# Pattern 1: Catch-all with fallback (top-level API)
try:
    result = do_work()
except Exception as exc:
    logger.exception("Failed for %s: %s", source, exc)
    result = safe_fallback()

# Pattern 2: Per-step resilience (pipeline)
try:
    cropped, was_cropped = crop_whatsapp(img)
except Exception as e:
    warnings.append(f"WhatsApp crop failed: {e}")

# Pattern 3: Never-raise (adapter layer)
try:
    results = reader.readtext(source)
except Exception as e:
    logger.warning("OCR failed for %s: %s", image, e)
    return []
```

**Warnings over Exceptions:**
- Missing fields result in `None` value + warning string, never an exception
- Low confidence adds to `warnings` list and `fields_to_review` list
- Quality rejection sets `is_rejected=True` + warning, does not abort processing

## Logging

**Framework:** Python stdlib `logging`

**Patterns:**
- Each module creates its own logger: `logger = logging.getLogger(__name__)`
- Root package adds `NullHandler()` to prevent "No handlers" warnings: `logger.addHandler(logging.NullHandler())`
- Use `logger.debug()` for raw OCR text, extraction records
- Use `logger.info()` for quality scores, initialization confirmation, reliability summaries
- Use `logger.warning()` for low quality, low confidence, OCR failures, per-image errors
- Use `logger.exception()` only for top-level pipeline crash (includes traceback)
- Log format uses `%s` formatting (not f-strings) for lazy evaluation: `logger.debug("Raw OCR text for %s:\n%s", source, result.raw_ocr_text)`

## Comments

**When to Comment:**
- Docstrings on all public functions describing behavior and return values
- Inline comments for non-obvious logic: `# Sanity: don't crop more than 20% total`
- Section headers for code organization: `# --- WhatsApp / noise patterns ---`, `# --- Field extraction patterns ---`
- Comments explaining "why": `# Normalize: 500 is a "typical sharp document" reference point`

**JSDoc/TSDoc:** Not applicable (Python project)

**Docstring Style:**
- Single-line docstrings for simple functions: `"""Convert BGR image to grayscale. Already-gray images pass through."""`
- Multi-line docstrings with blank line between summary and details:
```python
def check_quality(gray: np.ndarray, threshold: float | None = None) -> tuple[bool, float]:
    """Check if image quality is above rejection threshold.

    Returns (is_rejected, quality_score).
    """
```

## Function Design

**Size:** Functions are small and focused. Most are 5-20 lines. Largest is `preprocess()` at ~80 lines (orchestrator function).

**Parameters:**
- Use `str | Path` for file paths, convert internally with `Path()`
- Use `| None = None` for optional parameters with config-based defaults: `threshold: float | None = None`
- Config defaults resolved inside function body: `if threshold is None: threshold = config.CONFIDENCE_THRESHOLD`

**Return Values:**
- Use tuples for multiple returns: `tuple[np.ndarray, bool]` for `(result, was_modified)` pattern
- Use dataclasses for complex returns: `PreprocessResult`, `ExtractionResult`, `MatchResult`
- Never return bare `None` from pipeline functions; always return a valid object with warning flags

## Module Design

**Exports:**
- Each package has explicit `__all__` in `__init__.py`
- Re-export pattern: submodule classes re-exported from package `__init__.py` for convenience
- Example: `from dimed_ocr.models import MedicationRecord` works via `models/__init__.py`

**Barrel Files:**
- All packages use `__init__.py` as barrel files
- `ocr/src/dimed_ocr/__init__.py` is the public API surface: `extract()`, `match()`, and key types
- `ocr/src/dimed_ocr/writers/__init__.py` re-exports `write_csv`, `write_json`, `write_sqlite`
- `ocr/src/dimed_ocr/matching/__init__.py` re-exports protocol types and `match_record`

## Data Modeling

**Domain models (validated):** Pydantic `BaseModel` for `MedicationRecord` in `ocr/src/dimed_ocr/models/medication.py`
- Pydantic `model_validator` for cross-field validation (confidence score bounds)
- `Field(default_factory=...)` for mutable defaults

**Transport/internal models:** `@dataclass` for `OcrResult`, `ExtractionResult`, `PreprocessResult`, `MedicationCandidate`, `MatchResult`
- Dataclasses used for simple data containers without validation needs

**Protocol pattern:** `typing.Protocol` with `@runtime_checkable` for `MedicationDB` interface in `ocr/src/dimed_ocr/matching/protocol.py`
- Enables structural typing: any class implementing `search()`, `all_candidates()`, `get_by_id()` satisfies the interface
- `MockMedicationDB` implements protocol without explicit inheritance

## Singleton Pattern

Used for heavy resources (EasyOCR reader):
```python
_reader: EasyOcrReader | None = None

def get_reader() -> EasyOcrReader:
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(...)
    return _reader

def reset_reader() -> None:
    global _reader
    _reader = None
```
- Applied in `ocr/src/dimed_ocr/pipeline/ocr_engine.py` and `ocr/src/dimed_ocr/pipeline/orientation.py`
- `reset_reader()` provided explicitly for test teardown

## Configuration

**All config in `ocr/src/dimed_ocr/config.py`:**
- Module-level constants (no class, no env vars)
- Imported via `from dimed_ocr import config` then accessed as `config.CONFIDENCE_THRESHOLD`
- Functions accept optional override parameters: `threshold: float | None = None`
- Tests override config via `monkeypatch.setattr(config, "CONFIDENCE_THRESHOLD", 0.50)`

---

*Convention analysis: 2026-03-05*
