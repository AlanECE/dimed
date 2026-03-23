---
phase: 70
plan: 3
status: complete
started: 2026-03-23
completed: 2026-03-23
---

# Plan 70-03 Summary: Orders

## What was built
- StatusBadge component with 7 colored statuses matching UI-SPEC
- Orders data hook with statut, dateFrom, dateTo, pagination params
- Order history table with statut dropdown, date range inputs, filters stored in URL search params
- Order detail page with articles table (designation, qty, unit price, total), total amount
- Cancel button visible only for "creee" status with AlertDialog confirmation
- Toast feedback for cancel success/error

## Key files created
- `apps/web/components/status-badge.tsx`
- `apps/web/components/order-table.tsx`
- `apps/web/hooks/use-orders.ts`

## Deviations
- AlertDialogTrigger: base-ui (shadcn v4) doesn't support `asChild` — styled trigger directly instead of wrapping Button
- Orders table shows "—" for article count since OrderResponse doesn't include lignes count

## Self-Check: PASSED
- typecheck: OK
- build: OK
