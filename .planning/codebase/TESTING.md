# Testing Patterns

**Analysis Date:** 2026-03-05

## Test Framework

**Runner:**
- pytest >= 7.0
- Config: `ocr/pyproject.toml` `[tool.pytest.ini_options]`

**Assertion Library:**
- Built-in pytest assertions (`assert`)
- `pytest.approx()` for float comparisons
- `pytest.raises()` for exception testing

**Run Commands:**
```bash
cd ocr
pytest                            # Run all tests (excludes integration)
pytest --cov=src/dimed_ocr       # Tests + coverage
pytest -m integration            # Integration tests only (require EasyOCR model)
pytest -m "not integration"      # Unit tests only (default via addopts)
```

**Markers:**
```python
# Defined in pyproject.toml
markers = [
    "integration: tests requiring real OCR models and full end-to-end scenarios",
    "slow: long-running tests",
]

# Default addopts excludes integration:
addopts = "-m 'not integration'"
```

## Test File Organization

**Location:**
- Tests in separate `ocr/tests/` directory (not co-located with source)
- Test subdirectories mirror source package structure

**Naming:**
- Test files: `test_<module>.py` (e.g., `test_extractor.py`, `test_matcher.py`)
- Test classes: `Test<Feature>` (e.g., `TestFuzzyMatching`, `TestFieldFlagging`)
- Test functions: `test_<behavior>` (e.g., `test_exact_match`, `test_csv_write_basic`)

**Structure:**
```
ocr/tests/
  __init__.py
  conftest.py                        # Shared fixtures
  test_cli.py                        # CLI batch tests
  test_cropping.py                   # Cropping & quality rejection
  test_extract_api.py                # Top-level extract() API
  test_imports.py                    # Public import smoke tests
  test_integration_preprocess.py     # Integration: full pipeline on real images
  test_orientation.py                # Integration: EasyOCR orientation detection
  test_preprocessor.py               # Unit: preprocessing steps
  test_reliability.py                # Unit: confidence checks
  test_summary.py                    # Unit: summary generation
  matching/
    test_matcher.py                  # Unit: fuzzy matching logic
    test_protocol.py                 # Unit: protocol types and mock DB
  models/
    __init__.py
    test_medication.py               # Unit: Pydantic model validation
  pipeline/
    __init__.py
    test_extractor.py                # Unit: field extraction and noise filter
    test_ocr_engine.py               # Unit: OCR engine adapter (mocked)
    test_orientation_logic.py        # Unit: orientation logic (mocked OCR)
  writers/
    __init__.py
    test_csv_writer.py               # Unit: CSV output
    test_json_writer.py              # Unit: JSON output
    test_sqlite_writer.py            # Unit: SQLite output
```

## Test Structure

**Suite Organization:**
```python
# Group related tests in classes named by feature area
class TestFuzzyMatching:
    def test_exact_match(self, db: MockMedicationDB) -> None:
        record = _make_record("ISOLVON", confidence=0.95)
        result = match_record(record, db)
        assert result.matched is True
        assert result.candidate is not None

    def test_typo_match(self, db: MockMedicationDB) -> None:
        record = _make_record("ISOLVN", confidence=0.90)
        result = match_record(record, db)
        assert result.candidate is not None

# Standalone functions for simple, independent tests
def test_grayscale_passthrough() -> None:
    gray_input = np.zeros((100, 100), dtype=np.uint8)
    result = to_grayscale(gray_input)
    assert result is gray_input
```

**Patterns:**
- Classes group tests by logical feature/concern (e.g., `TestThresholdConfiguration`, `TestFieldFlagging`, `TestLogging`)
- Section comments organize test file into logical blocks: `# --- RELY-01: Threshold configuration ---`
- All test functions have return type annotation `-> None`
- Descriptive docstrings on tests that use real images to explain which image and why

**Setup/Teardown:**
```python
# Used in OCR engine tests for singleton cleanup
class TestSingleton:
    def setup_method(self) -> None:
        reset_reader()

    def teardown_method(self) -> None:
        reset_reader()
```

## Fixtures

**Shared fixtures in `ocr/tests/conftest.py`:**

```python
ETIQUETTES_DIR = Path(__file__).resolve().parent.parent / "Etiquettes"

@pytest.fixture
def sample_record() -> MedicationRecord:
    return MedicationRecord(source_file="test.png")

@pytest.fixture
def mock_db() -> MockMedicationDB:
    return MockMedicationDB()

@pytest.fixture
def sample_image_path() -> Path:
    return ETIQUETTES_DIR / "IMG_1265.PNG"

@pytest.fixture
def sample_image(sample_image_path: Path) -> np.ndarray:
    img = cv2.imread(str(sample_image_path))
    assert img is not None, f"Could not load {sample_image_path}"
    return img

@pytest.fixture
def tmp_debug_dir(tmp_path: Path) -> Path:
    d = tmp_path / "debug"
    d.mkdir()
    return d
```

**Per-test-file fixtures:**
```python
# Local fixture in test_matcher.py
@pytest.fixture
def db() -> MockMedicationDB:
    return MockMedicationDB()
```

**Test Data Factories:**
```python
# Pattern used across multiple test files for creating test records
def _make_record(**kwargs: object) -> MedicationRecord:
    defaults: dict[str, object] = {"source_file": "test.png"}
    defaults.update(kwargs)
    return MedicationRecord.model_validate(defaults)

# Specialized factory in test_matcher.py
def _make_record(
    nom: str | None = "ISOLVON",
    confidence: float = 0.95,
    **kwargs: str | None,
) -> MedicationRecord:
    scores = {"nom_commercial": confidence} if nom else {}
    data: dict[str, object] = {
        "source_file": "test.png",
        "nom_commercial": nom,
        "confidence_scores": scores,
    }
    data.update(kwargs)
    return MedicationRecord.model_validate(data)

# OCR detection helper in test_extractor.py
def _det(text: str, conf: float = 0.90) -> OcrResult:
    return OcrResult(text=text, bbox=[[0, 0], [100, 0], [100, 20], [0, 20]], confidence=conf)
```

## Mocking

**Framework:** `unittest.mock` (stdlib)

**Patterns:**

```python
# Pattern 1: Patch module-level dependencies
from unittest.mock import patch, MagicMock

@patch("dimed_ocr.pipeline.ocr_engine.get_reader")
def test_run_ocr_returns_ocr_results(self, mock_get: MagicMock) -> None:
    mock_reader = MagicMock()
    mock_reader.readtext.return_value = [
        ([[0, 0], [100, 0], [100, 20], [0, 20]], "LOT: ABC123", 0.95),
    ]
    mock_get.return_value = mock_reader
    results = run_ocr("test.png")
    assert len(results) == 1

# Pattern 2: Context manager with multiple patches
with (
    patch("dimed_ocr.pipeline.preprocessor.preprocess", return_value=prep) as mock_preprocess,
    patch("dimed_ocr.pipeline.ocr_engine.run_ocr", return_value=detections) as mock_ocr,
    patch("dimed_ocr.pipeline.extractor.extract_fields", return_value=extracted) as mock_extract,
    patch("dimed_ocr.pipeline.reliability.apply_confidence_checks") as mock_reliability,
):
    result = extract("img.png")

# Pattern 3: Patch config values with monkeypatch
def test_threshold_from_config(self, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(config, "CONFIDENCE_THRESHOLD", 0.50)
    record = MedicationRecord(...)
    result = apply_confidence_checks(record)

# Pattern 4: side_effect for conditional behavior
def mock_extract(path: str) -> ExtractionResult:
    if "bad" in path:
        raise RuntimeError("OCR failed")
    return _make_result(Path(path).name)
with patch("dimed_ocr.cli.extract", side_effect=mock_extract):
    main(["batch", str(img_dir), "--output", str(out_dir)])

# Pattern 5: Patch with side_effect list for sequential calls
with patch(
    "dimed_ocr.pipeline.orientation.ocr_confidence_score",
    side_effect=[0.2, 0.9, 0.1, 0.1],
):
    assert detect_base_orientation(img) == 90
```

**What to Mock:**
- EasyOCR reader (heavy dependency, slow initialization)
- Full pipeline steps when testing top-level `extract()` API
- Config module values for threshold testing
- External I/O when testing CLI batch processing

**What NOT to Mock:**
- OpenCV operations (fast, deterministic, pure computation)
- Pydantic model creation and validation
- Data processing logic (regex extraction, fuzzy matching)
- File I/O in writer tests (use `tmp_path` fixture instead)

## Real Image Testing

**Reference dataset:** 31 PNG images in `ocr/Etiquettes/` (pharmaceutical labels)

**Usage pattern:**
```python
ETIQUETTES_DIR = Path(__file__).resolve().parent.parent / "Etiquettes"

# Specific known images for targeted assertions
def test_whatsapp_detection_on_screenshot(self) -> None:
    """IMG_1270 is a known WhatsApp screenshot."""
    img = cv2.imread(str(ETIQUETTES_DIR / "IMG_1270.PNG"))

# Parametrized over all images for crash-safety
ALL_IMAGES = sorted(ETIQUETTES_DIR.glob("*.PNG"))

@pytest.mark.slow
@pytest.mark.parametrize("image_path", ALL_IMAGES, ids=[p.name for p in ALL_IMAGES])
def test_full_pipeline_no_crash(image_path: Path) -> None:
    result = preprocess(image_path)
    assert isinstance(result, PreprocessResult)
```

**Key test images:**
- `IMG_1265.PNG` - Direct photo, normal orientation (default `sample_image` fixture)
- `IMG_1270.PNG` - WhatsApp screenshot with UI overlay
- `IMG_1261.PNG` - Rotated 180 degrees
- `IMG_1288.PNG` - Ventoline with clear label contour

## Coverage

**Requirements:** No enforced minimum threshold

**View Coverage:**
```bash
cd ocr
pytest --cov=src/dimed_ocr
pytest --cov=src/dimed_ocr --cov-report=html  # HTML report
```

**Coverage artifacts:**
- `.coverage` file present in `ocr/` root
- `# pragma: no cover` used on defensive fallback in `__init__.py` `extract()` catch block

## Test Types

**Unit Tests:**
- Majority of the test suite (~150+ tests)
- Run by default (`addopts = "-m 'not integration'"`)
- Mock heavy dependencies (EasyOCR), test logic in isolation
- Cover: models, extraction patterns, noise filtering, reliability checks, writers, CLI, matching logic

**Integration Tests:**
- Marked with `@pytest.mark.integration`
- Require real EasyOCR model loaded (slow, ~10-30s startup)
- Located in: `ocr/tests/test_integration_preprocess.py`, `ocr/tests/test_orientation.py`
- Test: full preprocessing pipeline on real images, orientation detection accuracy, multi-pass OCR
- Run explicitly: `pytest -m integration`

**E2E Tests:**
- Not formalized as separate test type
- `test_openrouter_ocr.py` in root is a standalone script (not pytest), tests LLM-based OCR via OpenRouter API
- Not part of the test suite

## Common Patterns

**Async Testing:**
- Not used (synchronous codebase)

**Error Testing:**
```python
# Pattern 1: pytest.raises for expected exceptions
def test_source_file_required(self) -> None:
    with pytest.raises(Exception):
        MedicationRecord()  # type: ignore[call-arg]

def test_confidence_score_above_1_raises(self) -> None:
    with pytest.raises(ValueError):
        MedicationRecord(source_file="x", confidence_scores={"nom_commercial": 1.5})

# Pattern 2: Test graceful degradation (no exception, returns safe value)
def test_run_ocr_error_returns_empty(self, mock_get: MagicMock) -> None:
    mock_reader = MagicMock()
    mock_reader.readtext.side_effect = RuntimeError("file not found")
    mock_get.return_value = mock_reader
    results = run_ocr("bad_path.png")
    assert results == []

# Pattern 3: Test fallback behavior
def test_extract_returns_safe_fallback_on_failure() -> None:
    with patch("dimed_ocr.pipeline.preprocessor.preprocess", side_effect=RuntimeError("boom")):
        result = extract("img.png")
    assert result.record.needs_review is True
    assert any("Extraction failed" in w for w in result.record.warnings)
```

**Log Testing:**
```python
def test_logging_warning_for_flagged_field(self, caplog: pytest.LogCaptureFixture) -> None:
    record = MedicationRecord(
        source_file="test.png",
        nom_commercial="DOLIPRANE",
        confidence_scores={"nom_commercial": 0.60},
    )
    with caplog.at_level(logging.DEBUG, logger="dimed_ocr.pipeline.reliability"):
        apply_confidence_checks(record)
    assert any("Low confidence on nom_commercial" in msg for msg in caplog.messages)
```

**File Output Testing:**
```python
# Use tmp_path fixture for file-based tests
def test_csv_write_basic(tmp_path: Path) -> None:
    records = [_make_record(source_file="img1.png", nom_commercial="Doliprane")]
    out = tmp_path / "results.csv"
    write_csv(records, out)
    raw = out.read_bytes()
    assert raw[:3] == b"\xef\xbb\xbf", "Missing UTF-8 BOM"
```

**Synthetic Image Testing:**
```python
# Create synthetic images for deterministic behavior (no real image dependency)
def test_quality_rejection_blurry(self) -> None:
    rng = np.random.default_rng(42)
    noisy = rng.integers(100, 160, size=(200, 200), dtype=np.uint8)
    blurred = cv2.GaussianBlur(noisy, (51, 51), 0)
    is_rejected, score = check_quality(blurred)
    assert is_rejected is True

def test_crop_to_label_preserves_on_failure(self) -> None:
    uniform = np.full((200, 200, 3), 128, dtype=np.uint8)
    cropped, was_cropped = crop_to_label(uniform)
    assert was_cropped is False
```

**Mutable Default Safety Testing:**
```python
# Verify Pydantic Field(default_factory=...) works correctly
def test_two_records_dont_share_warnings(self) -> None:
    r1 = MedicationRecord(source_file="a.png")
    r2 = MedicationRecord(source_file="b.png")
    r1.warnings.append("warning")
    assert r2.warnings == []
```

---

*Testing analysis: 2026-03-05*
