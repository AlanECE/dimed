# Features Research: Pharmaceutical Logistics System

## Table Stakes (must have)

### Order Management
| Feature | Complexity | Dependencies | Notes |
|---------|-----------|--------------|-------|
| Product catalog with search | Low | Medication DB | Pharmacist browses and selects |
| Shopping cart + order placement | Medium | Catalog, Auth | Standard e-commerce flow |
| Order lifecycle (state machine) | Medium | None | Creee -> Acceptee -> ... -> Livree |
| Operator validation dashboard | Medium | Orders API | Filter, sort, approve/reject |
| Invoice auto-generation | Medium | Orders, PDF lib | Triggered on validation |
| Delivery note with barcode | Medium | Orders, barcode lib | Unique tracking key |

### Authentication & Authorization
| Feature | Complexity | Dependencies | Notes |
|---------|-----------|--------------|-------|
| Role-based access (5 roles) | Medium | Auth system | pharmacien, operatrice, preparateur, controleur, livreur |
| Login/logout | Low | JWT | Standard flow |
| Admin account creation | Low | Auth | No open registration (pharma compliance) |

### Warehouse Preparation
| Feature | Complexity | Dependencies | Notes |
|---------|-----------|--------------|-------|
| Barcode scan (cart association) | Medium | Mobile camera | Links cart to order |
| OCR label scanning | High | OCR module, camera | Core differentiator |
| Automatic field verification | High | OCR, medication DB | Name, lot, qty, expiry, price |
| Picking list with zones A/B/C/D | Medium | Orders data | Document generation |
| Controller checklist | Medium | Preparation data | Verification subprocess |
| QR code generation per package | Low | QR lib | N.cmd + N.colis (1/3, 2/3, 3/3) |

### Delivery
| Feature | Complexity | Dependencies | Notes |
|---------|-----------|--------------|-------|
| Route sheet display | Low | Route data | Driver's daily view |
| Loading checklist with QR scan | Medium | QR scanner, route | Mandatory scan each package |
| Electronic signature | Medium | Signature lib | Pharmacist signs on driver's device |
| Delivery confirmation | Low | Signature, orders | Updates order status |

### Notifications
| Feature | Complexity | Dependencies | Notes |
|---------|-----------|--------------|-------|
| Status change notifications | Medium | WebSocket or push | Pharmacist gets updates at each state change |

## Differentiators (competitive advantage)

| Feature | Complexity | Value | Notes |
|---------|-----------|-------|-------|
| OCR confidence-first approach | High | Critical | Flag uncertain fields instead of silent validation |
| Manual correction with audit trail | Medium | High | Every correction logged (who, when, what) |
| Offline-first warehouse operations | High | High | OCR + QR scan work without network |
| Real-time preparation tracking | Medium | Medium | Pharmacist sees order progress |
| Partial order handling | Medium | Medium | Q.Prl < QTE tracking |
| Dual visa (preparer + controller) | Low | High | Pharmaceutical compliance |

## Anti-Features (deliberately NOT building)

| Feature | Reason |
|---------|--------|
| Stock management | Out of scope — separate administrative process |
| Open registration | Pharma compliance — admin-only account creation |
| Route planning/optimization | Upstream logistics process, not in scope |
| Fleet management | Maintenance, insurance etc. — separate concern |
| Real-time GPS tracking | Battery drain, connectivity issues — deferred v2+ |
| Multi-warehouse support | Single DIMED Pharma deployment |
| Payment processing | Invoicing only, payment is offline |
