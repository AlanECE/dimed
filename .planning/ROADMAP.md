# Roadmap: DIMED

## Milestone 1: Module 1 — Commande en ligne

**Goal:** Deliver a fully functional online ordering system where pharmacists can place orders, operators can validate them, and all tracking documents (invoices, delivery notes, route sheets) are generated automatically.

**Phases:** 10 | **Requirements:** 39 | **Strategy:** Incremental by module

### Phase Overview

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|-----------------|
| 10 | 2/3 | In Progress|  | 4 |
| 20 | Authentication & RBAC | JWT auth, 5 roles, protected endpoints | AUTH-01..05 | 5 |
| 30 | Data Model M1 | Order entities, state machine, audit columns | ORD-05, ORD-07, AUDIT-01..03 | 5 |
| 40 | Medication Import | Articles.xlsx import, catalog CRUD | MED-01..03 | 3 |
| 50 | Orders API | Full order CRUD, lifecycle, operator validation | ORD-01..04, ORD-06 | 5 |
| 60 | Documents API | Invoice, BL, route sheet generation | DOC-01..05 | 5 |
| 70 | Pharmacist Frontend | Catalog, cart, order tracking | PHARM-01..04 | 4 |
| 80 | Operator Frontend | Dashboard, validation, route management | OPER-01..04 | 4 |
| 90 | Notifications | Push notifications on status changes | NOTIF-01..04 | 4 |
| 100 | E2E Tests & Hardening | Integration tests, Docker prod, security | Cross-cutting | 3 |

---

### Phase 10: Foundations & Infrastructure

**Goal:** Set up the monorepo structure, Docker development environment, and database so all subsequent phases have a solid foundation.

**Requirements:** INFRA-01, INFRA-02, INFRA-03, INFRA-04

**Success Criteria:**
1. `turbo dev` starts all apps (web + api) from monorepo root
2. `docker compose up` brings up PostgreSQL + Redis + API + Web
3. Alembic migration runs successfully on empty database
4. Hardened Dockerfiles pass `docker scout` with no critical vulnerabilities

---

### Phase 20: Authentication & RBAC

**Goal:** Users can log in and the API enforces role-based access control for all 5 roles.

**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05

**Success Criteria:**
1. User can log in with email/password and receive JWT access + refresh tokens
2. Expired access token is refreshed automatically via refresh token
3. API endpoint returns 403 when user role lacks permission
4. Admin can create user accounts with any of the 5 roles
5. No endpoint is accessible without valid JWT (except login)

---

### Phase 30: Data Model M1

**Goal:** Database schema for all Module 1 entities with proper state machine and audit trail.

**Requirements:** ORD-05, ORD-07, AUDIT-01, AUDIT-02, AUDIT-03

**Success Criteria:**
1. All M1 entities exist in database (User, Commande, LigneCommande, Facture, BonDeLivraison, FeuilleDeRoute, Medicament)
2. Order state machine rejects invalid transitions (e.g., Creee -> Livree)
3. Every entity has created_at, updated_at, created_by audit columns
4. Status change audit log table records every transition with actor + timestamp
5. Alembic migration applies cleanly on fresh database

---

### Phase 40: Medication Import

**Goal:** Medication catalog populated from Articles.xlsx and queryable via API.

**Requirements:** MED-01, MED-02, MED-03

**Success Criteria:**
1. Import script reads Articles.xlsx and inserts medications into PostgreSQL
2. Import rejects invalid rows with clear error messages (data quality validation)
3. API endpoint returns paginated medication list with search by designation/DCI

---

### Phase 50: Orders API

**Goal:** Full order management through API — create, validate, reject, list, filter.

**Requirements:** ORD-01, ORD-02, ORD-03, ORD-04, ORD-06

**Success Criteria:**
1. Pharmacist can create order with articles via POST (status: Creee)
2. Operator can approve (-> Acceptee) or reject (-> Annulee) via PATCH
3. GET orders returns filtered list (by date, pharmacist, status)
4. Cancellation rejected if order is already in En_preparation or beyond
5. Order total calculated correctly from article quantities * PPA

---

### Phase 60: Documents API

**Goal:** Automatic generation of invoices, delivery notes, and route sheets.

**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05

**Success Criteria:**
1. Invoice PDF generated automatically when order is validated (with HT/TTC amounts)
2. BL generated with unique scannable barcode (Code128 format)
3. Route sheet generated per truck with client list and counters
4. Assigning order to truck updates the route sheet
5. System rejects second active route sheet for same truck

---

### Phase 70: Pharmacist Frontend

**Goal:** Pharmacist can browse catalog, place orders, and track their status through a web interface.

**Requirements:** PHARM-01, PHARM-02, PHARM-03, PHARM-04

**Success Criteria:**
1. Catalog page displays medications with search and pagination
2. Cart allows adding items, modifying quantities, and validating order
3. Order history page shows all orders with status filter
4. Order detail page shows articles, amounts, and current status

---

### Phase 80: Operator Frontend

**Goal:** Operator can manage orders through a dashboard — validate, reject, assign to trucks.

**Requirements:** OPER-01, OPER-02, OPER-03, OPER-04

**Success Criteria:**
1. Dashboard shows pending orders with real-time count
2. Operator can open order detail and approve/reject with one click
3. Route sheet management allows assigning orders to trucks
4. Dashboard supports filtering by date, pharmacist, status and sorting

---

### Phase 90: Notifications

**Goal:** Pharmacist receives real-time notifications at each order status change.

**Requirements:** NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04

**Success Criteria:**
1. Notification sent when order accepted (Acceptee)
2. Notification sent when preparation starts (En_preparation)
3. Notification sent when delivery starts (En_route)
4. Notification sent when delivered (Livree)

---

### Phase 100: E2E Tests & Hardening

**Goal:** Full integration test coverage, production-ready Docker images, and security hardening.

**Requirements:** Cross-cutting quality requirements

**Success Criteria:**
1. E2E test covers full flow: create order -> validate -> generate docs
2. Docker prod images pass security scan with no critical/high vulnerabilities
3. All API endpoints have proper input validation (no injection vectors)

---

## Future Milestones

### Milestone 2: Module 2 — Preparation & Verification
- Requirements: PREP-01 to PREP-13
- Mobile app for preparer and controller
- OCR integration with existing Python module
- Picking list generation and QR codes
- Estimated phases: 110-180

### Milestone 3: Module 3 — Delivery
- Requirements: DELIV-01 to DELIV-07
- Mobile app for driver
- Loading checklist with QR scan
- Electronic signature and delivery confirmation
- Estimated phases: 190-240

---
*Roadmap created: 2026-03-23*
*Last updated: 2026-03-23 after initial creation*
