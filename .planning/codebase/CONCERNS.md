# Codebase Concerns

**Analysis Date:** 2026-03-05

## Tech Debt

**Duplicate EasyOCR Reader Singletons:**
- Issue: Two independent EasyOCR reader singletons exist — one in `ocr/src/dimed_ocr/pipeline/ocr_engine.py` (configurable, Protocol-based) and one in `ocr/src/dimed_ocr/pipeline/orientation.py` (hardcoded `["fr"]`, `gpu=False`). They do not share the same instance, so two EasyOCR models can be loaded in memory simultaneously.
- Files: `ocr/src/dimed_ocr/pipeline/ocr_engine.py` (lines 18-43), `ocr/src/dimed_ocr/pipeline/orientation.py` (lines 7-15)
- Impact: Doubles memory usage (~500MB+ per reader). The orientation module ignores `config.EASYOCR_GPU` and `config.EASYOCR_LANGUAGES`, creating inconsistency.
- Fix approach: Refactor `orientation.py` to import and use `get_reader()` from `ocr_engine.py` instead of maintaining its own singleton.

**Global Mutable State for Debug Counter:**
- Issue: `_debug_step_counter` is a module-level global integer reset at the start of `run_binarization_pipeline()` but not at the start of `preprocess()`. The `run_binarization_pipeline()` function is also not called by `preprocess()` — they are parallel code paths with duplicated logic.
- Files: `ocr/src/dimed_ocr/pipeline/preprocessor.py` (lines 16, 21, 99-100)
- Impact: Not thread-safe. If batch processing is parallelized, debug images will overwrite each other or have wrong numbering. The counter also leaks state between calls.
- Fix approach: Pass a counter as parameter or use a context object instead of module-level global.

**Duplicated Pipeline Logic:**
- Issue: `run_binarization_pipeline()` and `preprocess()` in `preprocessor.py` contain largely duplicated code — both do WhatsApp crop, label crop, grayscale, quality check, CLAHE, denoise, binarize. `run_binarization_pipeline()` appears to be an older version that is no longer called by the main pipeline.
- Files: `ocr/src/dimed_ocr/pipeline/preprocessor.py` (lines 91-146 vs 149-232)
- Impact: Maintaining two code paths creates divergence risk. Changes to one path may not be applied to the other.
- Fix approach: Remove `run_binarization_pipeline()` if unused, or refactor both to share a common implementation.

**No Linter or Formatter Configured:**
- Issue: No `.eslintrc`, `ruff.toml`, `.flake8`, or `pyproject.toml` linter section exists. The CLAUDE.md notes "Pas de linter configure".
- Files: `ocr/pyproject.toml`
- Impact: No automated code quality enforcement. Inconsistencies can creep in across contributors.
- Fix approach: Add `[tool.ruff]` section to `ocr/pyproject.toml` with basic rules.

**No Type Checking Configuration:**
- Issue: No `mypy.ini`, `pyrightconfig.json`, or `[tool.mypy]` section in pyproject.toml. Type hints are used throughout but never validated.
- Files: `ocr/pyproject.toml`
- Impact: Type errors can go undetected. The `# type: ignore[import-untyped]` suppressions on easyocr imports are reasonable but unverified by CI.
- Fix approach: Add `[tool.mypy]` or `[tool.pyright]` to `ocr/pyproject.toml`.

## Known Bugs

**Orientation Detection Runs OCR Twice Redundantly:**
- Symptoms: `detect_and_correct_orientation()` calls `detect_base_orientation()` (which runs OCR at 4 rotations), then calls `multi_pass_ocr()` (which runs OCR 2 more times). The OCR results from orientation detection are passed back but then discarded — `preprocess()` does not use the OCR results from orientation, and `extract()` runs OCR again on the binarized image via `run_ocr()`.
- Files: `ocr/src/dimed_ocr/pipeline/orientation.py` (lines 80-92), `ocr/src/dimed_ocr/__init__.py` (lines 32-33)
- Trigger: Every single image processed runs OCR at least 7 times (4 for orientation + 2 for multi-pass + 1 for final extraction).
- Workaround: None currently.

**`nom_commercial` Never Extracted:**
- Symptoms: `extract_fields()` in `extractor.py` always sets `nom_commercial=None`. The `FIELD_PATTERNS` dict has no entry for `nom_commercial`. The `match_record()` function in `matcher.py` short-circuits with `if not record.nom_commercial: return MatchResult(record=record)`, meaning DB matching never activates.
- Files: `ocr/src/dimed_ocr/pipeline/extractor.py` (line 126), `ocr/src/dimed_ocr/matching/matcher.py` (lines 48-49)
- Trigger: Every extraction. The matching subsystem is structurally dead code until `nom_commercial` extraction is implemented.
- Workaround: None. This is a known gap per the planning docs (Phase 4 deferred to DB integration).

## Security Considerations

**Hardcoded API Key in Repository:**
- Risk: `ocr/test_openrouter_ocr.py` contains a hardcoded OpenRouter API key on line 10: `API_KEY = "sk-or-v1-..."`. This key is committed to git history.
- Files: `ocr/test_openrouter_ocr.py` (line 10)
- Current mitigation: None.
- Recommendations: Immediately rotate the API key on OpenRouter. Remove the file or move the key to an environment variable. Add `test_openrouter_ocr.py` to `.gitignore` or delete it. Add a `.gitignore` to the project root.

**No `.gitignore` File:**
- Risk: No `.gitignore` exists at the project root or in `ocr/`. All files including `.venv/`, debug images, output databases, and any future `.env` files can be accidentally committed.
- Files: Project root `/home/ak-42/Desktop/dimed/`
- Current mitigation: None.
- Recommendations: Create a `.gitignore` covering at minimum: `.venv/`, `__pycache__/`, `*.pyc`, `output/`, `.env*`, `*.db`, debug directories.

**No Input Validation on Image Paths:**
- Risk: The CLI accepts arbitrary paths via `argparse`. While `cv2.imread` handles non-image files gracefully (returns None), the `find_images()` filter only checks extensions, not file content.
- Files: `ocr/src/dimed_ocr/cli.py` (lines 16-19)
- Current mitigation: Extension whitelist (`.png`, `.jpg`, `.jpeg`).
- Recommendations: Low risk for this use case (internal pharmaceutical tool). Consider adding `.bmp`, `.tiff`, `.webp` support and HEIC handling (project has `.HEIC` test images that would be silently skipped).

## Performance Bottlenecks

**Orientation Detection — 6x OCR Overhead:**
- Problem: Every image triggers 4 OCR passes for orientation detection (0/90/180/270 degrees) plus 2 more for multi-pass OCR in `orientation.py`, all of which are discarded. The final OCR in `__init__.py:extract()` runs a 7th time on the binarized image.
- Files: `ocr/src/dimed_ocr/pipeline/orientation.py` (lines 43-54, 57-77), `ocr/src/dimed_ocr/__init__.py` (line 33)
- Cause: Orientation detection was designed as a standalone phase and never integrated to reuse its OCR results downstream.
- Improvement path: Cache the OCR results from the best orientation and pass them through `PreprocessResult` to avoid re-running OCR. This would reduce per-image OCR calls from 7 to 4 (orientation only) + reuse best result.

**Sequential Batch Processing:**
- Problem: `cli.py:run_batch()` processes images sequentially in a `for` loop. With OCR taking several seconds per image and 31+ test images, batch runs are slow.
- Files: `ocr/src/dimed_ocr/cli.py` (lines 34-42)
- Cause: Simple implementation, no parallelism.
- Improvement path: Use `concurrent.futures.ProcessPoolExecutor` for CPU-bound OCR. The global singleton pattern in `ocr_engine.py` would need per-process initialization.

**EasyOCR Cold Start:**
- Problem: First call to `get_reader()` loads the EasyOCR model (~2-5 seconds, ~500MB memory). With the duplicate reader in `orientation.py`, this happens twice.
- Files: `ocr/src/dimed_ocr/pipeline/ocr_engine.py` (lines 34-43), `ocr/src/dimed_ocr/pipeline/orientation.py` (lines 10-15)
- Cause: Lazy singleton pattern with no preloading option.
- Improvement path: Merge to single reader. Optionally add a `warm_up()` function for CLI to call before batch starts.

## Fragile Areas

**Regex-Based Field Extraction:**
- Files: `ocr/src/dimed_ocr/pipeline/extractor.py` (lines 23-54)
- Why fragile: The regex patterns for `FIELD_PATTERNS` are tightly coupled to specific label formats. Any variation in label layout, language (Arabic text ignored), abbreviation, or OCR misread breaks extraction. For example, `date_peremption` expects `EXP:` or `Peremption:` prefix — labels using `DLC:` or `Date limite:` would be missed.
- Safe modification: Add new patterns to the lists without removing existing ones. Test against the 31 real images in `ocr/Etiquettes/`.
- Test coverage: `tests/pipeline/test_extractor.py` tests synthetic data only (176 lines). No tests against real OCR output from actual label images.

**WhatsApp Overlay Detection:**
- Files: `ocr/src/dimed_ocr/pipeline/cropping.py` (lines 7-44)
- Why fragile: Uses a fixed variance threshold (200.0) to detect UI bars. This value was likely tuned for specific WhatsApp themes. Dark mode, different phone resolutions, or non-WhatsApp messaging apps would produce different variance profiles.
- Safe modification: Make the threshold configurable via `config.py`. Add test images with known overlays.
- Test coverage: `tests/test_cropping.py` (97 lines) uses synthetic images, not real WhatsApp screenshots.

**Label Contour Detection:**
- Files: `ocr/src/dimed_ocr/pipeline/cropping.py` (lines 62-94)
- Why fragile: Requires a clear rectangular contour (exactly 4 points from `approxPolyDP`). Labels that are curved, partially obscured, placed on curved bottles, or have rounded corners will not be detected. The 10% minimum area threshold may also reject small labels on large backgrounds.
- Safe modification: Adjust `epsilon` in `approxPolyDP` or relax the 4-point requirement. Test with real images.
- Test coverage: Limited to synthetic rectangles.

## Scaling Limits

**SQLite Writer Drops Table on Every Write:**
- Current capacity: Works for single-run batch processing.
- Limit: `write_sqlite()` calls `DROP TABLE IF EXISTS medications` on every invocation. Running the CLI twice overwrites all previous results.
- Scaling path: Use `INSERT OR REPLACE` with a unique constraint, or append mode with timestamps.
- Files: `ocr/src/dimed_ocr/writers/sqlite_writer.py` (line 13)

**In-Memory Image Processing:**
- Current capacity: Handles standard pharmaceutical label photos (1-5 MB each).
- Limit: Very high resolution images or batch processing of hundreds of images could exhaust memory, especially with two EasyOCR readers loaded (~1GB combined).
- Scaling path: Process images one at a time (already done), but fix the duplicate reader issue to halve baseline memory.

## Dependencies at Risk

**Python 3.14 Requirement:**
- Risk: `requires-python = ">=3.14"` in `pyproject.toml` pins to a very recent Python version (released Oct 2025). Most production systems, Docker base images, and CI runners may not have Python 3.14 available yet.
- Impact: Cannot deploy on systems with Python 3.12/3.13. Cannot use standard Docker images (`python:3.12-slim`).
- Migration plan: Lower to `>=3.11` or `>=3.12` unless specific 3.14 features are required (none observed in the code — only `X | Y` union syntax which works from 3.10+).
- Files: `ocr/pyproject.toml` (line 8)

**EasyOCR — Untyped, Heavy:**
- Risk: EasyOCR has no type stubs (`# type: ignore[import-untyped]`), pulls in PyTorch (~2GB), and has infrequent releases. GPU auto-detection code in `ocr_engine.py` imports `torch` in a try/except.
- Impact: Large install size, slow CI, no type safety on the OCR boundary.
- Migration plan: Consider PaddleOCR or Tesseract for lighter alternatives if EasyOCR accuracy proves insufficient. The `EasyOcrReader` Protocol in `ocr_engine.py` already abstracts the reader interface.
- Files: `ocr/src/dimed_ocr/pipeline/ocr_engine.py` (lines 14-15, 38)

## Missing Critical Features

**No Real Medication Database:**
- Problem: `MockMedicationDB` with 10 hardcoded entries is the only `MedicationDB` implementation. No adapter for a real pharmacy database (SQLite, CSV import, or API).
- Blocks: The entire matching/reconciliation pipeline is untestable with real data. The `match()` API function exists but cannot be used in production.
- Files: `ocr/src/dimed_ocr/matching/protocol.py` (lines 39-65)

**No `nom_commercial` Extraction:**
- Problem: The medication name is never extracted from OCR text. Without it, DB matching cannot activate. This is the single biggest functional gap.
- Blocks: End-to-end medication identification. All records will have `nom_commercial=None`.
- Files: `ocr/src/dimed_ocr/pipeline/extractor.py` (line 126)

**HEIC Image Support Missing:**
- Problem: `IMAGE_EXTENSIONS` in CLI only includes `.png`, `.jpg`, `.jpeg`. The project contains `.HEIC` test images (`IMG_1251.HEIC`) which are silently skipped. OpenCV does not natively support HEIC.
- Blocks: Processing photos taken directly from iPhone (default format is HEIC).
- Files: `ocr/src/dimed_ocr/cli.py` (line 13)

**No Progress Feedback in Batch Mode:**
- Problem: `run_batch()` prints nothing during processing of each image. For 31+ images with ~10+ seconds each, the user sees no progress for several minutes.
- Blocks: Usability for operators.
- Files: `ocr/src/dimed_ocr/cli.py` (lines 34-42)

## Test Coverage Gaps

**No End-to-End Tests with Real OCR:**
- What's not tested: The full `extract()` pipeline on real pharmaceutical label images with actual EasyOCR output. All tests mock OCR results.
- Files: `ocr/tests/test_extract_api.py`, `ocr/tests/pipeline/test_ocr_engine.py`
- Risk: Regex patterns in `extractor.py` may not match real OCR output (OCR introduces typos, spacing issues, mixed case). The preprocessing pipeline may degrade image quality for certain label types.
- Priority: High — this is the core value proposition of the module.

**No Integration Tests for Writers with Real Data:**
- What's not tested: Writers tested with synthetic `MedicationRecord` objects, not with records produced by actual OCR extraction.
- Files: `ocr/tests/writers/test_csv_writer.py`, `ocr/tests/writers/test_sqlite_writer.py`, `ocr/tests/writers/test_json_writer.py`
- Risk: Low — writers are simple serializers. Edge cases (Unicode in Arabic fields, very long warnings lists) could surface.
- Priority: Low.

**Orientation Detection Not Tested on Real Images:**
- What's not tested: `detect_base_orientation()` and `multi_pass_ocr()` with actual rotated label photos. `tests/test_orientation.py` and `tests/pipeline/test_orientation_logic.py` use synthetic or mocked data.
- Files: `ocr/tests/test_orientation.py` (70 lines), `ocr/tests/pipeline/test_orientation_logic.py` (25 lines)
- Risk: Medium — incorrect orientation doubles down on OCR failures. The 0.05 confidence threshold for keeping original orientation may be too aggressive or too lenient.
- Priority: Medium.

**`test_openrouter_ocr.py` is Not a Proper Test:**
- What's not tested: This file is a standalone script, not a pytest test. It calls an external API with a hardcoded key and is not part of the test suite.
- Files: `ocr/test_openrouter_ocr.py`
- Risk: Confusing — looks like a test but is an ad-hoc experiment. Contains a leaked API key.
- Priority: Medium — delete or move to `scripts/`.

---

*Concerns audit: 2026-03-05*
