# Requirements: DIMED

**Defined:** 2026-03-23
**Core Value:** Assurer la tracabilite complete et fiable de la chaine logistique pharmaceutique, de la commande a la livraison signee, en reduisant les erreurs de preparation par verification OCR automatique.

## v1 Requirements

Requirements for Milestone 1: Module 1 - Commande en ligne.

### Infrastructure

- [ ] **INFRA-01**: Turborepo monorepo with apps/web, apps/api, packages/ structure
- [ ] **INFRA-02**: Docker Compose dev stack (PostgreSQL, Redis, API, Web)
- [ ] **INFRA-03**: Hardened Docker images for production deployment
- [x] **INFRA-04**: Alembic database migrations setup

### Authentication

- [ ] **AUTH-01**: User can log in with email and password
- [ ] **AUTH-02**: JWT access + refresh token mechanism with secure rotation
- [ ] **AUTH-03**: Role-based access control for 5 roles (pharmacien, operatrice, preparateur, controleur, livreur)
- [ ] **AUTH-04**: Admin-only account creation (no open registration)
- [ ] **AUTH-05**: Protected API endpoints with role-based middleware

### Medications

- [ ] **MED-01**: Import medication catalog from Articles.xlsx into PostgreSQL
- [ ] **MED-02**: Pharmacist can browse and search medication catalog
- [ ] **MED-03**: Medication records include: code_article, designation, DCI, dosage, forme, PPA, fabricant

### Orders

- [ ] **ORD-01**: Pharmacist can compose an order by selecting articles from catalog
- [ ] **ORD-02**: Pharmacist can validate cart to create order (status: Creee)
- [ ] **ORD-03**: Operator can view pending orders in dashboard (filterable by date, pharmacist, status)
- [ ] **ORD-04**: Operator can approve order (status: Acceptee) or reject (status: Annulee)
- [ ] **ORD-05**: Order state machine enforced server-side (Creee -> Acceptee -> En_preparation -> ... -> Livree)
- [ ] **ORD-06**: Cancellation only allowed before En_preparation state
- [ ] **ORD-07**: Each order has unique ID (format: C00XXXXXXX), pharmacien_id, montant_total, commercial

### Documents

- [ ] **DOC-01**: Invoice auto-generated on order validation (N.facture, montant HT/TTC, articles)
- [ ] **DOC-02**: Delivery note (BL) auto-generated with unique scannable barcode
- [ ] **DOC-03**: Route sheet generated per truck with client list, order numbers, counters (colis_std, sachets_std, colis_frg, sachets_frg)
- [ ] **DOC-04**: Orders can be associated to a truck, generating/updating the route sheet
- [ ] **DOC-05**: One active route sheet per truck at a time

### Frontend Pharmacist

- [ ] **PHARM-01**: Pharmacist can browse medication catalog with search and filters
- [ ] **PHARM-02**: Pharmacist can add items to cart, modify quantities, validate order
- [ ] **PHARM-03**: Pharmacist can view order history with status filters
- [ ] **PHARM-04**: Pharmacist can view order detail with articles and status

### Frontend Operator

- [ ] **OPER-01**: Operator can view dashboard of pending orders
- [ ] **OPER-02**: Operator can view order detail and approve/reject
- [ ] **OPER-03**: Operator can manage route sheets (assign orders to trucks)
- [ ] **OPER-04**: Operator dashboard supports filtering and sorting

### Notifications

- [ ] **NOTIF-01**: Pharmacist receives notification when order is accepted
- [ ] **NOTIF-02**: Pharmacist receives notification when order is in preparation
- [ ] **NOTIF-03**: Pharmacist receives notification when order is in delivery
- [ ] **NOTIF-04**: Pharmacist receives notification when order is delivered

### Audit & Compliance

- [ ] **AUDIT-01**: Every order status change logged with actor, timestamp, and reason
- [ ] **AUDIT-02**: All database entities have created_at, updated_at, created_by fields
- [ ] **AUDIT-03**: No silent data modification — every change traceable

## v2 Requirements

Deferred to Milestone 2 (Module 2) and Milestone 3 (Module 3).

### Preparation (M2)

- **PREP-01**: Preparer can scan cart barcode to associate with order
- **PREP-02**: Preparer can scan medication labels with camera for OCR extraction
- **PREP-03**: System OCR extracts 10 structured fields from label with confidence scores
- **PREP-04**: System auto-verifies: name, lot, quantity, expiry, price against order
- **PREP-05**: Fields below 85% confidence flagged for manual correction
- **PREP-06**: App blocks until all items scanned and validated
- **PREP-07**: Partial picking tracked (Q.Prl < QTE)
- **PREP-08**: Picking list generated with zones A/B/C/D
- **PREP-09**: Preparer signature per zone
- **PREP-10**: Controller checklist verification
- **PREP-11**: Controller declares package count, generates QR codes
- **PREP-12**: Dual visa required (preparer + controller) before "Prete a livrer"
- **PREP-13**: OCR works offline (CPU-only, no cloud)

### Delivery (M3)

- **DELIV-01**: Driver views daily route sheet on mobile app
- **DELIV-02**: Mandatory QR scan of every package before departure
- **DELIV-03**: Double signature required before departure (expedition + driver)
- **DELIV-04**: Client info and instructions displayed at each stop
- **DELIV-05**: Electronic signature collected from pharmacist
- **DELIV-06**: Delivery confirmation updates order status
- **DELIV-07**: Refusal and absence handling

## Out of Scope

| Feature | Reason |
|---------|--------|
| Stock management | Separate administrative process, not in logistics scope |
| Open registration | Pharma compliance — admin-only account creation |
| Route planning/optimization | Upstream logistics process |
| Fleet management | Maintenance, insurance — separate concern |
| Real-time GPS tracking | Battery drain, connectivity issues in Algeria — deferred v2+ |
| Multi-warehouse | Single DIMED Pharma deployment |
| Payment processing | Invoicing only, payment is offline |
| Arabic language support | Deferred — French obligatory, Arabic optional per CDC |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 10 | Pending |
| INFRA-02 | Phase 10 | Pending |
| INFRA-03 | Phase 10 | Pending |
| INFRA-04 | Phase 10 | Complete |
| AUTH-01 | Phase 20 | Pending |
| AUTH-02 | Phase 20 | Pending |
| AUTH-03 | Phase 20 | Pending |
| AUTH-04 | Phase 20 | Pending |
| AUTH-05 | Phase 20 | Pending |
| MED-01 | Phase 40 | Pending |
| MED-02 | Phase 40 | Pending |
| MED-03 | Phase 40 | Pending |
| ORD-01 | Phase 50 | Pending |
| ORD-02 | Phase 50 | Pending |
| ORD-03 | Phase 50 | Pending |
| ORD-04 | Phase 50 | Pending |
| ORD-05 | Phase 30 | Pending |
| ORD-06 | Phase 50 | Pending |
| ORD-07 | Phase 30 | Pending |
| DOC-01 | Phase 60 | Pending |
| DOC-02 | Phase 60 | Pending |
| DOC-03 | Phase 60 | Pending |
| DOC-04 | Phase 60 | Pending |
| DOC-05 | Phase 60 | Pending |
| PHARM-01 | Phase 70 | Pending |
| PHARM-02 | Phase 70 | Pending |
| PHARM-03 | Phase 70 | Pending |
| PHARM-04 | Phase 70 | Pending |
| OPER-01 | Phase 80 | Pending |
| OPER-02 | Phase 80 | Pending |
| OPER-03 | Phase 80 | Pending |
| OPER-04 | Phase 80 | Pending |
| NOTIF-01 | Phase 90 | Pending |
| NOTIF-02 | Phase 90 | Pending |
| NOTIF-03 | Phase 90 | Pending |
| NOTIF-04 | Phase 90 | Pending |
| AUDIT-01 | Phase 30 | Pending |
| AUDIT-02 | Phase 30 | Pending |
| AUDIT-03 | Phase 30 | Pending |

**Coverage:**
- v1 requirements: 39 total
- Mapped to phases: 39
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-23*
*Last updated: 2026-03-23 after initial definition*
