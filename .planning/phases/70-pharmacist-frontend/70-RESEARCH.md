# Phase 70: Pharmacist Frontend — Research

**Researched:** 2026-03-23
**Sources:** Context7 (Next.js, shadcn/ui), API codebase analysis

## Stack Decisions

### shadcn/ui Setup
- Init: `npx shadcn@latest init -t next --monorepo` (monorepo flag for Turborepo)
- Components needed: table, input, button, badge, select, dialog, alert-dialog, sheet, separator, skeleton, toast (sonner), dropdown-menu, pagination, card
- Data tables: TanStack Table (`@tanstack/react-table`) via shadcn data-table pattern
- Toasts: `sonner` (shadcn's recommended toast lib)
- Confirmations destructives: `AlertDialog` (pas Dialog)

### Next.js 15 Auth Pattern
- `middleware.ts` pour protéger les routes (redirect vers /login si pas de cookie)
- Cookies httpOnly gérés par le backend FastAPI — le frontend ne les lit/écrit pas directement
- API client: `fetch()` avec `credentials: "include"` pour forward les cookies
- Pas de JWT decode côté client — appel `/auth/me` pour récupérer l'utilisateur courant
- Route handlers (`app/api/...`) pas nécessaires — appels directs au backend FastAPI

### API Client Architecture
- Base URL configurable via `NEXT_PUBLIC_API_URL` (default: `http://localhost:8000`)
- Wrapper `fetchApi()` qui ajoute `credentials: "include"` et `Content-Type: application/json`
- Gestion centralisée des erreurs (401 → redirect login, 403, 404, 500)
- Auto-refresh: intercepter 401, appeler `/auth/refresh`, retry original request

### Fonts
- Figtree + Noto Sans via `next/font/google` (automatic optimization)
- Pas besoin de `@import` CSS — Next.js gère le preload

## API Contracts (Backend Ready)

### Auth
| Endpoint | Method | Body | Response | Cookie |
|----------|--------|------|----------|--------|
| `/auth/login` | POST | `{email, password}` | `UserResponse` | Sets access_token + refresh_token |
| `/auth/refresh` | POST | — | `{message}` | Rotates tokens |
| `/auth/logout` | POST | — | `{message}` | Clears cookies |
| `/auth/me` | GET | — | `UserResponse` | Reads access_token |

### Medicaments
| Endpoint | Method | Params | Response |
|----------|--------|--------|----------|
| `/medicaments` | GET | `?search=&limit=&offset=` | `{medicaments[], total, limit, offset}` |
| `/medicaments/{id}` | GET | — | `MedicamentResponse` |

Note: pas de filtres forme/fabricant côté API. Filtrage client-side sur les résultats chargés, ou ajout de query params (scope phase 70 — filtrage client suffisant en v1 avec 20 items/page).

### Commandes
| Endpoint | Method | Body/Params | Response |
|----------|--------|-------------|----------|
| `/commandes` | POST | `{articles: [{medicament_id, qte}]}` | `OrderDetailResponse` |
| `/commandes` | GET | `?statut=&date_from=&date_to=&limit=&offset=` | `{commandes[], total, limit, offset}` |
| `/commandes/{id}` | GET | — | `OrderDetailResponse` |
| `/commandes/{id}/cancel` | PATCH | — | `OrderDetailResponse` |

### Response Types
```typescript
type MedicamentResponse = {
  id: string
  code_article: string
  designation: string
  dci: string | null
  dosage: string | null
  forme: string | null
  ppa: number
  fabricant: string | null
}

type OrderResponse = {
  id: string
  reference_id: string
  statut: string
  montant_total: number
  pharmacien_id: string
  operatrice_id: string | null
  commercial: string | null
  created_at: string
  date_validation: string | null
}

type OrderDetailResponse = OrderResponse & {
  lignes: LigneResponse[]
}

type LigneResponse = {
  id: string
  medicament_id: string
  designation: string
  qte_demandee: number
  prix_unitaire: number
  n_lot: string | null
}

type UserResponse = {
  id: string
  email: string
  nom: string
  prenom: string
  role: string
  is_active: boolean
}
```

## Architecture Frontend

### File Structure (Next.js App Router)
```
apps/web/
├── app/
│   ├── layout.tsx              # Root layout (fonts, providers)
│   ├── login/
│   │   └── page.tsx            # Login page
│   ├── (authenticated)/
│   │   ├── layout.tsx          # App shell (sidebar + main)
│   │   ├── catalogue/
│   │   │   └── page.tsx        # Catalogue + cart sidebar
│   │   └── commandes/
│   │       ├── page.tsx        # Order history
│   │       └── [id]/
│   │           └── page.tsx    # Order detail
│   └── page.tsx                # Redirect to /catalogue
├── components/
│   ├── ui/                     # shadcn components (auto-generated)
│   ├── sidebar.tsx             # Nav sidebar
│   ├── cart-sidebar.tsx        # Cart panel
│   ├── status-badge.tsx        # Order status badge
│   ├── medication-table.tsx    # Catalogue table
│   ├── order-table.tsx         # Orders table
│   └── confirm-order-dialog.tsx
├── lib/
│   ├── api.ts                  # fetchApi wrapper
│   ├── auth.ts                 # Auth context + hook
│   └── cart.ts                 # Cart state (React context)
├── middleware.ts               # Auth redirect
└── hooks/
    ├── use-medications.ts      # Medication list hook
    └── use-orders.ts           # Orders list hook
```

### State Management
- **Auth**: React Context (`AuthProvider`) — stores `UserResponse | null`
- **Cart**: React Context (`CartProvider`) — stores `CartItem[]` (medicament + qte)
- **Server state**: Custom hooks with `fetch` + `useState` + `useEffect` (pas de React Query en v1 — garder simple)
- **URL state**: `useSearchParams()` pour les filtres (statut, dates, search, page)

## Validation Architecture

### Dimension 1: Functional Correctness
- Login/logout flow works with httpOnly cookies
- Catalogue search returns fuzzy results
- Cart persists during navigation (React context)
- Order creation sends correct payload
- Cancel only available for Créée status

### Dimension 2: UI Compliance
- All pages match UI-SPEC layouts
- Status badges use correct colors
- Responsive breakpoints work

### Dimension 3: Accessibility
- Focus management on login error
- Keyboard navigation sidebar → content → cart
- ARIA labels on icon buttons

---
*Research completed: 2026-03-23*
