---
phase: 70
plan: 2
status: complete
started: 2026-03-23
completed: 2026-03-23
---

# Plan 70-02 Summary: Catalogue + Cart

## What was built
- Cart context (CartProvider) with add/update/remove/clear and computed total/itemCount
- Medications data hook with debounced live search (300ms)
- Catalogue table with 7 columns, search input, forme/fabricant client-side filters, pagination
- Cart sidebar (w-80, sticky) with +/- buttons, editable quantity input, trash to remove
- Order confirmation AlertDialog with recap table and POST /commandes
- Redirect to order detail after successful creation with toast

## Key files created
- `apps/web/lib/cart.tsx`
- `apps/web/hooks/use-medications.ts`
- `apps/web/components/medication-table.tsx`
- `apps/web/components/cart-sidebar.tsx`
- `apps/web/components/confirm-order-dialog.tsx`

## Deviations
- Select onValueChange needs null coalescing (`v ?? "all"`) for shadcn v4 base-ui types

## Self-Check: PASSED
- typecheck: OK
- build: OK
