# Pitfalls Research: Pharmaceutical Logistics System

## Critical Pitfalls

### P1: OCR Accuracy Overconfidence
**Risk**: Treating OCR as reliable when it's inherently unreliable on pharmaceutical labels (small text, varying fonts, multilingual, poor lighting in warehouse).

**Warning signs**: Tests pass on clean images but fail on real warehouse photos. Users bypass manual correction because it's too slow.

**Prevention**:
- Never auto-validate below 85% confidence threshold
- Always log raw OCR output alongside structured result (audit trail)
- Test with ALL 30 real label photos, not just clean samples
- Make manual correction UI fast and frictionless (not a punishment)
- Track correction rates per field to identify systematic OCR failures

**Phase**: M2 (Preparation) — but OCR module already exists, validate early

### P2: Offline Sync Conflicts
**Risk**: Data corruption when multiple devices modify the same data offline and sync later. Example: preparer marks item scanned, controller also modifies — who wins?

**Warning signs**: Duplicate entries, phantom orders, status rollbacks after sync.

**Prevention**:
- Design for conflict-free operations (each actor modifies different fields)
- Use timestamps + actor ID for every mutation
- Server-wins strategy with conflict log for manual review
- Never delete data — soft delete only
- Test sync with simulated network drops

**Phase**: Foundation phase (database design) + every mobile phase

### P3: State Machine Violations
**Risk**: Orders ending up in impossible states (e.g., "Livree" without passing through "En verification"). Business logic scattered across frontend and backend.

**Warning signs**: Inconsistent order statuses in DB, frontend allowing transitions that backend rejects.

**Prevention**:
- State machine enforced SERVER-SIDE only (never trust client)
- Use a proper state machine library or explicit transition table
- Every state transition logged with actor, timestamp, and reason
- API rejects invalid transitions with clear error messages
- Database constraint: status can only be one of valid enum values

**Phase**: Phase 30 (Data model) and Phase 50 (Orders API)

### P4: Barcode/QR Code Reliability
**Risk**: Generated barcodes unreadable by warehouse scanners. QR codes too small or low contrast for camera scan in warehouse lighting.

**Warning signs**: Scan failures in testing, users resort to manual entry.

**Prevention**:
- Test with ACTUAL warehouse lighting conditions and devices
- Use high-contrast, large enough QR codes (minimum 3cm)
- Include human-readable text alongside every QR/barcode
- Support manual entry as fallback (type the code number)
- Standard formats: Code128 for barcodes, QR with error correction level H

**Phase**: Phase 60 (Document generation)

### P5: Pharmaceutical Compliance Gaps
**Risk**: Missing audit trail, no lot traceability, expiry dates not enforced — leading to regulatory issues.

**Warning signs**: No way to trace which lot was delivered to which pharmacist. Expired products not flagged.

**Prevention**:
- Every entity has created_at, updated_at, created_by, updated_by
- Lot number mandatory on every line item from preparation onward
- Expiry date comparison: system blocks if EXP < current date + safety margin
- PPA (price) validation: flag if OCR price differs from DB price
- Immutable audit log table (append-only, no updates/deletes)

**Phase**: Phase 30 (Data model) — audit columns from day 1

### P6: Mobile Performance in Warehouse
**Risk**: App too slow on budget Android phones (common in Algeria warehouses). Camera startup lag makes scanning painful.

**Warning signs**: Users complain about lag, camera takes 3+ seconds to initialize.

**Prevention**:
- Test on low-end Android devices (not just emulator)
- Camera pre-initialization when app opens
- Minimal UI — no animations, no heavy graphics
- Offline data pre-loaded (don't fetch on every screen)
- Image compression before sending to OCR API

**Phase**: All mobile phases (M2, M3)

### P7: Electronic Signature Legal Validity
**Risk**: E-signature on delivery may not have legal value in Algeria. If disputed, no proof of delivery.

**Warning signs**: Legal challenge to a delivery, no way to prove pharmacist signed.

**Prevention**:
- Research Algerian e-signature law (Loi 15-04 on e-commerce and e-signature)
- Store: signature image + timestamp + device ID + GPS (if available)
- Allow optional delivery photo as additional proof
- Keep paper fallback option in the UI

**Phase**: Phase M3 (Delivery)

## Medium Pitfalls

### P8: Import Data Quality (Articles.xlsx)
**Risk**: Excel file has inconsistent data, duplicates, missing fields. Garbage in = garbage out for the entire medication DB.

**Prevention**: Validation script that rejects bad rows with clear error messages. Run on every import.

**Phase**: Phase 40 (Articles import)

### P9: Notification Fatigue
**Risk**: Pharmacist gets too many notifications, starts ignoring them. Misses important ones.

**Prevention**: Only notify on meaningful state changes (not intermediate states). Allow notification preferences.

**Phase**: Phase 90 (Notifications)

### P10: Document Generation Performance
**Risk**: Invoice/BL PDF generation is slow, blocks the validation flow.

**Prevention**: Generate async (Celery task), notify when ready. Don't block the operator.

**Phase**: Phase 60 (Documents API)
