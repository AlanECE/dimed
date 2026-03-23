---
phase: 70
plan: 1
status: complete
started: 2026-03-23
completed: 2026-03-23
---

# Plan 70-01 Summary: Foundation

## What was built
- shadcn/ui initialized with Tailwind v4, DIMED blue medical color palette (#0284C7)
- Figtree + Noto Sans fonts via next/font/google
- 12 shadcn components installed (table, input, button, badge, select, dialog, alert-dialog, sheet, separator, skeleton, dropdown-menu, card)
- API client (`lib/api.ts`) with credentials: "include", 401 auto-refresh, query param builder
- Auth context (`lib/auth.tsx`) with login/logout/useAuth hook
- Shared API types (`lib/types.ts`)
- Login page (centered card, email/password, error handling)
- Next.js middleware (redirect unauthenticated to /login, authenticated from /login to /catalogue)
- App shell with collapsible sidebar (Catalogue, Mes Commandes, Déconnexion)
- Placeholder pages for catalogue, commandes, commandes/[id]

## Key files created
- `apps/web/lib/api.ts` — API client
- `apps/web/lib/auth.tsx` — Auth context + provider
- `apps/web/lib/types.ts` — Shared TypeScript types
- `apps/web/middleware.ts` — Route protection
- `apps/web/components/sidebar.tsx` — Navigation sidebar
- `apps/web/app/login/page.tsx` — Login page
- `apps/web/app/(authenticated)/layout.tsx` — App shell layout

## Deviations
None — implemented as planned.

## Self-Check: PASSED
- typecheck: OK
- All acceptance criteria met
