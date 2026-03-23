# Research Summary: DIMED Pharmaceutical Logistics

## Stack

The chosen stack (FastAPI + Next.js 15 + React Native Expo + PostgreSQL + Turborepo + Docker) is well-validated for this type of system. Key additions:
- **SQLAlchemy 2.0 + Alembic** for ORM and migrations
- **Redis** for task queue (Celery) and caching
- **python-barcode + qrcode + reportlab** for document/code generation
- **WatermelonDB or expo-sqlite** for offline mobile storage
- **react-native-signature-canvas** for e-signature

No cloud dependencies. All self-hostable. OCR stack (EasyOCR + OpenCV + rapidfuzz) already validated.

## Table Stakes Features

- Order lifecycle with state machine (8 main states + 5 complementary)
- Role-based access for 5 actors
- Invoice and delivery note auto-generation with barcodes
- Product catalog with search
- Operator validation dashboard
- QR code generation for packages
- Route sheet display and loading checklist
- Electronic signature for delivery

## Key Differentiators

- **OCR confidence-first**: Flag uncertain fields, never validate silently
- **Offline-first warehouse**: QR scan + data operations work without network
- **Dual visa system**: Preparer + controller must both validate
- **Full audit trail**: Every action logged with actor + timestamp

## Watch Out For (Top 5 Pitfalls)

1. **OCR overconfidence** — test with ALL 30 real photos, make manual correction fast
2. **Offline sync conflicts** — design for conflict-free operations, server-wins strategy
3. **State machine violations** — enforce server-side only, log every transition
4. **Barcode/QR readability** — test in actual warehouse conditions, high-contrast + fallback
5. **Pharmaceutical compliance** — audit columns from day 1, lot traceability mandatory

## Architecture Decisions

- Monolith API (FastAPI modules, not microservices)
- REST with OpenAPI (not GraphQL)
- Server-side OCR with queue (too heavy for mobile)
- Optimistic offline sync with server reconciliation
- Local file storage (no cloud/S3)

## Build Order Implication

Foundation → Auth → Medication DB → Orders API → Document generation → Web frontends → Notifications → Mobile (M2) → Mobile (M3)
