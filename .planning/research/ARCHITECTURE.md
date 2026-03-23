# Architecture Research: Pharmaceutical Logistics System

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      CLIENTS                                 │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Web App     │  │  Mobile App  │  │  Mobile App  │      │
│  │  (Next.js)   │  │  (Expo)      │  │  (Expo)      │      │
│  │              │  │              │  │              │        │
│  │  Pharmacien  │  │  Preparateur │  │  Livreur     │      │
│  │  Operatrice  │  │  Controleur  │  │              │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │               │
└─────────┼─────────────────┼──────────────────┼───────────────┘
          │                 │                  │
          ▼                 ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                      API GATEWAY                             │
│                      (FastAPI)                               │
│                                                              │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐     │
│  │  Auth   │ │  Orders  │ │  Docs    │ │  Notifs    │     │
│  │  Module │ │  Module  │ │  Module  │ │  Module    │     │
│  └─────────┘ └──────────┘ └──────────┘ └────────────┘     │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐                    │
│  │  OCR    │ │  Prep    │ │  Delivery│                    │
│  │  Module │ │  Module  │ │  Module  │                    │
│  └─────────┘ └──────────┘ └──────────┘                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
   ┌────────────┐ ┌─────────┐ ┌─────────┐
   │ PostgreSQL │ │  Redis  │ │  Files  │
   │ (data)     │ │ (cache/ │ │ (images │
   │            │ │  queue) │ │  PDFs)  │
   └────────────┘ └─────────┘ └─────────┘
```

## Component Boundaries

### API Layer (FastAPI)
- **Auth module**: JWT issuance, RBAC middleware, role checking
- **Orders module**: CRUD, state machine, validation logic
- **Documents module**: Invoice/BL generation (PDF + barcode), picking list
- **OCR module**: Image upload, pipeline orchestration, result storage
- **Preparation module**: Cart association, item verification, visa management
- **Delivery module**: Route sheets, loading checklist, signature collection
- **Notifications module**: WebSocket or push notifications to pharmacist

### Data Flow

1. **Order flow**: Pharmacien → API (create) → Operatrice (validate) → API (generate docs) → Preparateur (scan)
2. **Preparation flow**: Preparateur → Camera → OCR module → API (verify) → Controleur (checklist) → QR generation
3. **Delivery flow**: Livreur → API (route sheet) → QR scan (loading) → Signature → API (confirm)

### Offline Architecture

```
Mobile App
├── Local SQLite/WatermelonDB (offline data)
├── OCR Engine (runs locally on device via API call when online, or queued)
├── QR/Barcode Scanner (fully offline)
├── Sync Queue (pending operations)
└── Sync Manager
    ├── On connectivity → push queue to API
    ├── On reconnect → pull latest state
    └── Conflict resolution: server wins (last-write-wins)
```

Key decisions for offline:
- QR/barcode scanning: fully offline (native)
- OCR: ideally local on device, but EasyOCR is heavy — may need API call with queue
- Data sync: optimistic local writes, sync when online
- Notifications: queued and delivered on reconnect

### Build Order (dependencies)

| Order | Component | Depends On | Reason |
|-------|-----------|------------|--------|
| 1 | Database schema + migrations | Nothing | Foundation for everything |
| 2 | Auth module | Database | All other modules need auth |
| 3 | Medication import (Articles.xlsx) | Database | Catalog needs data |
| 4 | Orders API | Auth, Database | Core business logic |
| 5 | Document generation | Orders | Invoices/BL triggered by orders |
| 6 | Web frontend (pharmacien) | Orders API | Consumes the API |
| 7 | Web frontend (operatrice) | Orders API, Docs | Dashboard for validation |
| 8 | Notifications | Orders (state changes) | Triggered by state transitions |
| 9 | Mobile app (preparateur) | OCR module, Orders | M2 — next milestone |
| 10 | Mobile app (livreur) | Delivery API, Signature | M3 — last milestone |

## Key Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Monolith API (not microservices) | FastAPI single app with modules | Simple deployment, single team, no need for service mesh |
| REST (not GraphQL) | REST with OpenAPI | Simpler, FastAPI auto-generates docs, sufficient for this use case |
| Server-side OCR (not on-device) | API endpoint with queue | EasyOCR too heavy for mobile, queue handles offline |
| Optimistic offline sync | Local writes + server reconciliation | Warehouse can't wait for network |
| File storage (local, not S3) | Local filesystem with backup | Single deployment, Algeria, no cloud dependency |
