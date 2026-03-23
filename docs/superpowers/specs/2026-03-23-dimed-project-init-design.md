# DIMED Project Init - Design Document

## Context

DIMED is a pharmaceutical logistics management system for a warehouse in Algeria. It covers the full distribution chain: online ordering by pharmacists, warehouse preparation with OCR label verification, and delivery with electronic signatures. The system has 3 sequential modules used by 5 actors (pharmacist, operator, preparer, controller, driver).

5 CDC (specification) documents define the requirements exhaustively. A GSD PROJECT.md exists but no roadmap. This design establishes the architecture and roadmap for the full project initialization.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Delivery strategy | Incremental by module | M1 first (v1), then M2, M3 (v2). Each module is independently deliverable. |
| Monorepo structure | Turborepo | apps/web, apps/mobile, apps/api, packages/shared. Docker secured. |
| Medication DB source | Import from Articles.xlsx | CSV/Excel import script, compatible with existing OCR MockMedicationDB Protocol. |
| Authentication | Custom JWT + FastAPI | Access + refresh tokens, RBAC with 5 roles. Internal deployment, no cloud dependency. |
| Architecture approach | Module-first with shared foundations | Phase 0 foundations, then M1 complete, then M2, M3. |

## Architecture

```
dimed/
├── apps/
│   ├── web/                    # Next.js 15 (pharmacist + operator)
│   ├── mobile/                 # React Native Expo (preparer, controller, driver)
│   └── api/                    # FastAPI (unified backend)
├── packages/
│   ├── shared-types/           # Shared types/schemas (TS)
│   ├── ui/                     # Shared UI components web/mobile
│   └── ocr/                    # Python OCR module (existing in ocr/)
├── docker/
│   ├── Dockerfile.api          # Hardened Python image
│   ├── Dockerfile.web          # Hardened Node image
│   └── docker-compose.yml      # Dev stack (PostgreSQL, Redis, API, Web)
├── turbo.json
├── package.json                # Workspace root
└── .planning/                  # GSD planning
```

### Stack

- **Backend**: FastAPI + SQLAlchemy 2.0 + Alembic + PostgreSQL
- **Auth**: Custom JWT (access + refresh tokens) + RBAC 5 roles
- **Frontend web**: Next.js 15 + TailwindCSS
- **Mobile**: React Native (Expo)
- **OCR**: Existing Python module (EasyOCR + OpenCV + Pydantic 2.0 + rapidfuzz)
- **Infra**: Docker Compose (dev), hardened images (prod)
- **Medication DB**: Import from `Articles.xlsx` via Python script

## Data Model (Module 1)

### User
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Primary key |
| email | String | Yes | Unique login |
| password_hash | String | Yes | Bcrypt hashed |
| role | Enum | Yes | pharmacien, operatrice, preparateur, controleur, livreur |
| nom | String | Yes | Full name |
| adresse | String | No | Address (for pharmacists) |
| secteur | String | No | Sector code |

### Commande
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | Unique ID (ex: C00046488) |
| pharmacien_id | FK(User) | Yes | Ordering pharmacist |
| operatrice_id | FK(User) | No | Validating operator |
| statut | Enum | Yes | Creee, Acceptee, Annulee, En_preparation, ... |
| montant_total | Decimal | Yes | Total in DA |
| commercial | String | No | Associated commercial (ex: Rania ARAB) |
| date_creation | DateTime | Yes | Creation timestamp |
| date_validation | DateTime | No | Validation timestamp |

### LigneCommande
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Primary key |
| commande_id | FK(Commande) | Yes | Parent order |
| medicament_id | FK(Medicament) | Yes | Referenced medication |
| designation | String | Yes | Full medication name + dosage + form |
| qte_demandee | Int | Yes | Requested quantity |
| prix_unitaire | Decimal | Yes | Unit price (PPA) |
| n_lot | String | No | Lot number (filled during preparation) |

### Facture
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | Unique ID (ex: 9410044388) |
| commande_id | FK(Commande) | Yes | Associated order |
| date_emission | DateTime | Yes | Generation date |
| montant_ht | Decimal | Yes | Amount excl. tax |
| montant_ttc | Decimal | Yes | Amount incl. tax in DA |

### BonDeLivraison
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | Unique ID |
| commande_id | FK(Commande) | Yes | Associated order |
| code_barre | String | Yes | Unique barcode for tracking |
| date_emission | DateTime | Yes | Generation date |

### FeuilleDeRoute
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | Unique ID |
| camion_id | FK(Camion) | Yes | Associated vehicle |
| date | Date | Yes | Delivery date |
| ligne | String | No | Distribution line |
| n_rotation | String | No | Rotation number |
| compteurs | JSON | Yes | {colis_std, sachets_std, colis_frg, sachets_frg} |
| signature_expedition | Bytes | No | Expedition officer signature |
| signature_chauffeur | Bytes | No | Driver signature |

### Medicament
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Primary key |
| code_article | String | Yes | Article code |
| designation | String | Yes | Full name + dosage + form |
| dci | String | No | International common denomination |
| dosage | String | No | Dosage (ex: 500MG) |
| forme | String | No | Galenic form (ex: COMP, CAPS) |
| ppa | Decimal | Yes | Algerian public price in DA |
| fabricant | String | No | Manufacturer |

## Roadmap - Milestone 1: Module 1 Commande en ligne

| Phase | Name | Description | CDC Requirements |
|-------|------|-------------|-----------------|
| 10 | Foundations & infra | Turborepo setup, Docker Compose, PostgreSQL, project structure, basic CI | Cross-cutting |
| 20 | Auth & RBAC | JWT auth, 5 roles, middleware, login/register endpoints | EXG-SEC-01 to 04 |
| 30 | Data model M1 | Commande, Facture, BL, FeuilleDeRoute entities + Alembic migrations | CDC M1 section 3 |
| 40 | Articles import | Import script Articles.xlsx to PostgreSQL, medication CRUD | Q7 (blocking) |
| 50 | Orders API | CRUD orders, lifecycle (Creee->Acceptee), operator validation | EF-1-01 to EF-1-08 |
| 60 | Documents API | Invoice + BL generation (barcode), delivery route sheet | EF-1-05, EF-1-06, EF-1-08 |
| 70 | Pharmacist frontend | Catalog, cart, order tracking, notifications | CDC M1 section 6.1 |
| 80 | Operator frontend | Dashboard, approve/reject, delivery route management | CDC M1 section 6.2 |
| 90 | Notifications | Push notification system (pharmacist), WebSocket or polling | EF-1-09 |
| 100 | E2E tests & hardening | Integration tests, Docker prod, security, basic offline mode | EXG-PERF, EXG-FIAB |

### Future Milestones

**Milestone 2 - Module 2: Preparation & Verification (v2)**
- Mobile app (preparer + controller)
- OCR integration (existing Python module)
- Picking list generation
- QR code generation
- Phases 110-180 (estimated)

**Milestone 3 - Module 3: Delivery (v2)**
- Mobile app (driver)
- Loading checklist with QR scan
- Electronic signature
- Delivery confirmation
- Phases 190-240 (estimated)

## Business Rules (M1)

| ID | Rule | Description |
|----|------|-------------|
| RG-1-01 | Restricted client accounts | Only admin can create pharmacist accounts. No open registration. |
| RG-1-02 | Mandatory operator validation | No order goes to preparation without explicit operator validation. |
| RG-1-03 | Automatic document generation | Invoice and BL are auto-generated at validation, not manually. |
| RG-1-04 | Unique BL barcode | Each delivery note has a unique barcode as tracking key. |
| RG-1-05 | One route sheet per truck | A truck can only have one active route sheet at a time. |
| RG-1-06 | Order-truck association | Multiple orders can be assigned to the same truck. |
| RG-1-07 | Limited cancellation | Orders can only be cancelled before "En preparation" state. |

## Risks & Open Questions

| # | Risk/Question | Severity | Mitigation |
|---|--------------|----------|------------|
| R1 | OCR 100% accuracy unrealistic | Critical | Confidence-first approach + manual fallback (already in OCR module) |
| R2 | Medication DB source undefined | High | Resolved: Articles.xlsx import |
| R5 | Roles/permissions not detailed | Medium | RBAC matrix to be defined in Phase 20 |
| Q1 | Barcode on BL vs QR on packages | Medium | BL barcode for M1 tracking, QR codes for M2 packages |
| Q4 | Controller re-scan by OCR? | Medium | Recommendation: manual checklist in v1, OCR in v2 |
| Q5 | Efficiency vs reliability | Medium | Compromise: checklist + random scan |

## Verification

- PROJECT.md reflects all 5 CDC documents
- Roadmap covers all 3 modules with ordered phases
- Requirements mapped to CDC functional requirements (EF-1-xx, EF-2-xx, EF-3-xx)
- Risks and open questions from CDC are integrated
- Each GSD phase activates its associated superpower (see CLAUDE.md mapping table)
