# Technology Stack

**Analysis Date:** 2026-03-05

## Languages

**Primary:**
- Python 3.14.0 - All application code, CLI, tests

**Secondary:**
- None (pure Python project)

## Runtime

**Environment:**
- Python 3.14.0 (CPython)
- CPU-only mode (no GPU required, PyTorch CPU variant installed)

**Package Manager:**
- pip 25.2
- Lockfile: missing (no `requirements.txt` or lock file, dependencies declared in `pyproject.toml` only)

**Virtual Environment:**
- venv at `ocr/.venv/`

## Frameworks

**Core:**
- Pydantic 2.12.5 - Domain models (`MedicationRecord`), validation, serialization
- EasyOCR 1.7.2 - OCR engine for French text extraction from pharmaceutical labels
- OpenCV (opencv-python-headless) 4.13.0 - Image preprocessing (CLAHE, denoising, binarization, contour detection, perspective correction)
- NumPy 2.3.5 - Image array manipulation
- RapidFuzz 3.14.3 - Fuzzy string matching for medication name reconciliation

**Testing:**
- pytest 9.0.2 - Test runner
- pytest-cov 7.0.0 - Coverage reporting

**Build/Dev:**
- setuptools 70.2.0 - Build backend (PEP 517/518)

## Key Dependencies

**Critical (declared in `ocr/pyproject.toml`):**
- `pydantic>=2.0` - Domain model validation, `MedicationRecord` at `ocr/src/dimed_ocr/models/medication.py`
- `opencv-python-headless>=4.8` - Full image preprocessing pipeline at `ocr/src/dimed_ocr/pipeline/preprocessor.py`
- `numpy>=1.24` - Array operations throughout pipeline
- `easyocr>=1.7` - OCR engine singleton at `ocr/src/dimed_ocr/pipeline/ocr_engine.py`
- `rapidfuzz>=3.0` - Fuzzy matching at `ocr/src/dimed_ocr/matching/matcher.py`

**Transitive (installed but not directly declared):**
- `torch 2.10.0+cpu` - EasyOCR dependency (PyTorch CPU-only variant)
- `torchvision 0.25.0+cpu` - EasyOCR dependency
- `scikit-image 0.26.0` - EasyOCR dependency
- `scipy 1.17.1` - EasyOCR dependency
- `transformers 5.2.0` - EasyOCR dependency
- `pillow 12.0.0` - Image format support
- `huggingface_hub 1.5.0` - Model download for EasyOCR

**Dev dependencies (declared in `[project.optional-dependencies] dev`):**
- `pytest>=7.0`
- `pytest-cov>=4.0`

## Configuration

**Application Config:**
- All configuration is hardcoded constants in `ocr/src/dimed_ocr/config.py`
- No environment variables, no `.env` files, no external config files
- Key constants:
  - `CONFIDENCE_THRESHOLD = 0.85` (OCR confidence cutoff)
  - `EASYOCR_GPU = None` (auto-detect, defaults to CPU)
  - `EASYOCR_LANGUAGES = ["fr"]` (French only)
  - `FUZZY_MIN_SCORE = 0.70` (minimum fuzzy match ratio)
  - `FUZZY_AMBIGUITY_GAP = 0.10` (gap between top-2 match candidates)
  - `QUALITY_REJECTION_THRESHOLD = 0.05` (Laplacian variance)

**Build Config:**
- `ocr/pyproject.toml` - Project metadata, dependencies, pytest config, setuptools package discovery
- Build backend: `setuptools.build_meta`
- Package discovery: `where = ["src"]` (src layout)

**Test Config (in `ocr/pyproject.toml`):**
- `testpaths = ["tests"]`
- `addopts = "-m 'not integration'"` (integration tests excluded by default)
- Custom markers: `integration`, `slow`

## CLI

**Entry Point:**
- `dimed-ocr` command registered via `[project.scripts]` in `ocr/pyproject.toml`
- Maps to `dimed_ocr.cli:main`
- Usage: `dimed-ocr batch ./Etiquettes/ --output ./output/`

## Platform Requirements

**Development:**
- Python 3.14+ (uses modern type hint syntax: `str | None`, `tuple[int, int]`)
- ~500MB disk for PyTorch CPU + EasyOCR models
- No GPU required
- Install: `pip install -e ".[dev]"` from `ocr/` directory

**Production:**
- CPU-only (designed for warehouse/entrepot environments without GPU)
- EasyOCR downloads model files on first run via huggingface_hub
- Supports `.png`, `.jpg`, `.jpeg` input images

**No linter configured** - CLAUDE.md notes "ajouter ruff si besoin"

---

*Stack analysis: 2026-03-05*
