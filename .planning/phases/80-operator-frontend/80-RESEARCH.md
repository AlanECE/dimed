# Phase 80: Operator Frontend — Research

**Researched:** 2026-03-23

## Backend State Analysis

### Existing models
- `FeuilleDeRoute`: camion_id (string!), date, ligne, n_rotation, compteurs (JSONB), signatures
- `Commande`: no camion_id, no feuille_route_id — no link to trucks yet
- No `Camion` model exists

### Existing endpoints
- `POST /documents/feuilles-route` — create route sheet (camion_id + date)
- `GET /documents/feuilles-route/{id}` — get single route sheet
- Missing: list route sheets, assign commande to camion, list commandes per feuille
- `PATCH /commandes/{id}/accept` — already works (transitions to acceptee)
- `PATCH /commandes/{id}/reject` — already works (transitions to annulee)

### What's needed (backend)
1. **Camion model** — id (UUID), nom, plaque, created_at, updated_at
2. **CRUD /camions** — POST, GET list, GET by id, PATCH, DELETE
3. **Migration** — Add Camion table, change FeuilleDeRoute.camion_id to UUID FK
4. **Assign endpoint** — PATCH /commandes/{id}/assign-camion {camion_id}
   - Links commande to camion
   - Auto-creates feuille de route for today if none exists
   - Adds commande to feuille's compteurs
5. **List feuilles** — GET /documents/feuilles-route (list all active, optionally with commandes)
6. **Commande.camion_id** — Add nullable FK to commandes table
7. **Pharmacien info** — GET /commandes already returns pharmacien_id, need to include name+email (join or expand response)

### Frontend Architecture
- Same patterns as Phase 70 (hooks, table components, shadcn)
- New routes under `/dashboard/` for operator pages
- Sidebar becomes role-based (useAuth → role → nav items)
- Middleware redirects: pharmacien→/catalogue, operatrice→/dashboard

### API Contracts (new)

```typescript
type CamionResponse = {
  id: string
  nom: string
  plaque: string
  created_at: string
}

type FeuilleDeRouteResponse = {
  id: string
  camion_id: string
  camion_nom: string
  date: string
  ligne: string | null
  compteurs: {
    colis_std: number
    sachets_std: number
    colis_frg: number
    sachets_frg: number
  }
  commandes: OrderResponse[]  // populated in list endpoint
}
```

---
*Research completed: 2026-03-23*
