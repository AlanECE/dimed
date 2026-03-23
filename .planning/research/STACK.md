# Stack Research: Pharmaceutical Logistics System

## Recommended Stack

### Backend
| Component | Choice | Version | Confidence | Rationale |
|-----------|--------|---------|------------|-----------|
| Framework | FastAPI | 0.115+ | High | Async, auto OpenAPI docs, Python ecosystem for OCR |
| ORM | SQLAlchemy 2.0 | 2.0+ | High | Mature, async support, Alembic migrations |
| Migrations | Alembic | 1.13+ | High | Standard for SQLAlchemy projects |
| Auth | python-jose + passlib | latest | High | JWT tokens, bcrypt hashing, no cloud dependency |
| Validation | Pydantic 2.0 | 2.x | High | Already used in OCR module, FastAPI native |
| Task queue | Celery + Redis | 5.4+ | Medium | For async doc generation, notifications |
| PDF/Barcode | python-barcode + reportlab | latest | High | Barcode/QR generation for BL, invoices |
| QR codes | qrcode + Pillow | latest | High | QR code generation for packages |

### Frontend Web
| Component | Choice | Version | Confidence | Rationale |
|-----------|--------|---------|------------|-----------|
| Framework | Next.js | 15 | High | SSR, routing, React ecosystem |
| Styling | TailwindCSS | 4.x | High | Utility-first, fast prototyping |
| State | Zustand | 5.x | High | Lightweight, simple API |
| Forms | React Hook Form + Zod | latest | High | Performance, type-safe validation |
| HTTP | Axios | 1.7+ | High | Interceptors for JWT refresh |
| Tables | TanStack Table | 8.x | High | Operator dashboard needs complex tables |

### Mobile
| Component | Choice | Version | Confidence | Rationale |
|-----------|--------|---------|------------|-----------|
| Framework | React Native (Expo) | SDK 52+ | High | Cross-platform, camera access for OCR/QR |
| Camera/Scanner | expo-camera + expo-barcode-scanner | latest | High | QR/barcode scanning native |
| Offline storage | WatermelonDB or expo-sqlite | latest | Medium | Offline-first data persistence |
| Signature | react-native-signature-canvas | latest | High | E-signature capture for delivery |
| Navigation | expo-router | latest | High | File-based routing, consistent with Next.js |

### Database & Infra
| Component | Choice | Version | Confidence | Rationale |
|-----------|--------|---------|------------|-----------|
| Database | PostgreSQL | 16+ | High | Relational, JSONB for flexible fields, robust |
| Cache/Queue | Redis | 7+ | Medium | Session store, task queue broker, notifications |
| Container | Docker + Docker Compose | latest | High | Dev parity, hardened prod images |
| Monorepo | Turborepo | 2.x | High | Build orchestration, caching |

### OCR (Existing)
| Component | Choice | Version | Confidence | Rationale |
|-----------|--------|---------|------------|-----------|
| OCR Engine | EasyOCR | 1.7+ | High | French support, CPU-only, already implemented |
| Image processing | OpenCV headless + NumPy | 4.8+ | High | Already implemented |
| Fuzzy matching | rapidfuzz | latest | High | Medication name matching, already implemented |

## What NOT to Use

| Technology | Reason |
|-----------|--------|
| Supabase | Cloud dependency, deployment constraints in Algeria |
| Prisma | TypeScript ORM, backend is Python |
| Firebase | Cloud dependency, no self-hosting |
| Tesseract alone | EasyOCR already chosen and tested, better for photos |
| MongoDB | Relational data model (orders, invoices) needs SQL |
| GraphQL | REST is simpler for this use case, FastAPI auto-generates OpenAPI |
