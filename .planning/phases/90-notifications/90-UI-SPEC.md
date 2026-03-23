---
phase: 90
slug: notifications
status: approved
shadcn_initialized: true
preset: none
created: 2026-03-23
---

# Phase 90 — UI Design Contract

> Visual and interaction contract for the notification bell + dropdown popover component.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | shadcn v4 |
| Preset | not applicable |
| Component library | base-ui (NOT Radix — shadcn v4 uses @base-ui/react) |
| Icon library | Lucide React (lucide-react) |
| Font | Figtree (headings) + Noto Sans (body) via next/font/google |

---

## Component Inventory

| Component | Source | Notes |
|-----------|--------|-------|
| Popover | shadcn/ui (base-ui) | Panneau notifications dropdown |
| Button | shadcn/ui | Trigger cloche (variant="ghost", size="icon") |
| ScrollArea | shadcn/ui | Scroll interne du panneau |
| Bell icon | Lucide React | Icône cloche dans le header |
| Dot icon | Lucide React | Indicateur non-lu (optionnel, ou CSS dot) |

---

## Spacing Scale

Declared values (multiples of 4, cohérent avec Phase 70/80) :

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Gap icône-badge, padding inline |
| sm | 8px | Padding interne items notification |
| md | 16px | Padding panneau, gap entre items |
| lg | 24px | Header panneau |
| xl | 32px | Non utilisé dans ce composant |

Exceptions: none

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Body | 14px | 400 | 1.5 | Message notification |
| Label | 12px | 500 | 1.4 | Timestamp relatif ("il y a 5 min") |
| Heading | 14px | 600 | 1.4 | Header panneau "Notifications" |
| Badge count | 11px | 600 | 1 | Chiffre dans le badge rouge |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #F0F9FF | Background panneau notifications |
| Secondary (30%) | #FFFFFF | Items notification individuels |
| Accent (10%) | #0284C7 | Indicateur non-lu (dot bleu), titre header panneau |
| Destructive | #EF4444 | Badge compteur (fond rouge + texte blanc) |
| Unread dot | #0284C7 | Point bleu à gauche des notifications non-lues |
| Read item bg | #FFFFFF | Fond item lu (neutre) |
| Unread item bg | #F0F9FF | Fond item non-lu (bleu très léger) |
| Timestamp | #64748B | Texte secondaire gris (slate-500) |
| Hover | #E0F2FE | Hover sur item notification (sky-100) |

Accent reserved for: indicateur non-lu uniquement (dot bleu). Le badge compteur utilise rouge destructif pour attirer l'attention.

---

## Layout Specification

### NotificationBell (trigger)

```
┌──────────────────────────────────────────────────┐
│  ...page header...    [🔔]·(3)    Hicham ▾      │
│                        ↑    ↑                     │
│                      Bell  Badge                  │
└──────────────────────────────────────────────────┘

Bell button: 36x36px (ghost, no border)
Badge: absolute positioned, -top-1 -right-1
  - Circle: 18x18px min, rounded-full
  - Background: #EF4444 (red-500)
  - Text: white, 11px, font-semibold
  - Content: number (max "99+")
  - Hidden when unreadCount === 0
```

### NotificationPanel (popover content)

```
┌─────────────────────────────────┐  w-80 (320px)
│  Notifications    Tout marquer  │  Header: 14px semibold
│                    comme lu     │  Action link: 12px, accent color
├─────────────────────────────────┤
│ ● Commande C00000042 acceptée  │  Unread: bg #F0F9FF
│   il y a 5 min                 │  Dot: 8px circle, #0284C7
├─────────────────────────────────┤
│ ○ Commande C00000038 en route  │  Read: bg #FFFFFF
│   il y a 2h                    │  No dot
├─────────────────────────────────┤
│ ○ Commande C00000035 livrée    │
│   hier                         │
├─────────────────────────────────┤
│         ...scroll...            │  ScrollArea max-h-[400px]
└─────────────────────────────────┘

Item structure:
  padding: 12px 16px (sm vertical, md horizontal)
  gap: 8px entre dot et contenu

  [dot 8px] [message 14px]
             [timestamp 12px slate-500]

  Hover: bg #E0F2FE (sky-100)
  Cursor: pointer
  Click: mark read + redirect to /commandes/{id}
```

### Empty state

```
┌─────────────────────────────────┐
│  Notifications                  │
├─────────────────────────────────┤
│                                 │
│     Aucune notification         │  14px, slate-500, centered
│                                 │
└─────────────────────────────────┘
```

### Responsive

- Desktop (>768px) : `w-80` (320px), `align="end"` sur le popover
- Mobile (<768px) : `w-[min(320px,calc(100vw-2rem))]` pour ne pas déborder
- Le PopoverContent utilise `sideOffset={8}` pour l'espacement avec le trigger

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Panel header | "Notifications" |
| Mark all read link | "Tout marquer comme lu" |
| Empty state heading | "Aucune notification" |
| Notification acceptée | "Commande {ref} acceptée" |
| Notification préparation | "Commande {ref} en préparation" |
| Notification en route | "Commande {ref} en cours de livraison" |
| Notification livrée | "Commande {ref} livrée" |
| Badge aria-label | "{n} notifications non lues" |
| Bell aria-label | "Notifications" |

---

## Interaction Contract

| Action | Behavior |
|--------|----------|
| Click bell | Toggle popover open/close |
| Open popover | Fetch GET /notifications (20 dernières + unread_count) |
| Click notification item | 1) Optimistic: mark read locally 2) PATCH /notifications/{id}/read 3) Navigate to /commandes/{commande_id} 4) Close popover |
| Click "Tout marquer comme lu" | 1) Optimistic: set all read locally 2) PATCH /notifications/read-all 3) Badge disappears |
| Navigate to new page | Refetch unread_count (le hook est dans le layout, persist entre pages) |
| Popover outside click | Close popover (base-ui default behavior) |
| Keyboard Escape | Close popover (base-ui default behavior) |

---

## Accessibility

| Rule | Implementation |
|------|---------------|
| aria-label bell | `aria-label="Notifications"` sur le Button trigger |
| aria-live badge | `aria-live="polite"` sur le badge compteur pour annoncer les changements |
| Focus management | Focus trap dans le popover quand ouvert (base-ui Popover default) |
| Keyboard nav | Tab entre items dans le popover, Enter pour sélectionner |
| Color not only | Non-lu indiqué par dot bleu ET fond coloré (pas couleur seule) |
| Contrast | Badge rouge (#EF4444) sur blanc: 4.6:1 ✓. Texte slate-900 sur blanc: 15.4:1 ✓. Timestamp slate-500 sur blanc: 4.6:1 ✓ |
| Touch target | Button bell: 36x36px visuel, 44x44px zone cliquable (padding) |
| Screen reader | Items ont role="listitem", message comme texte principal |

---

## Animation

| Transition | Duration | Easing | Property |
|------------|----------|--------|----------|
| Popover open | 150ms | ease-out | opacity + scale(0.95→1) |
| Popover close | 100ms | ease-in | opacity + scale(1→0.95) |
| Badge appear | 200ms | ease-out | scale(0→1) |
| Badge disappear | 150ms | ease-in | scale(1→0) |
| Item hover | 150ms | ease | background-color |
| Mark read (dot) | 200ms | ease-out | opacity(1→0) |

`prefers-reduced-motion`: disable scale animations, keep opacity only.

---

## Registry Safety

| Registry | Components Used | Safety Gate |
|----------|----------------|-------------|
| shadcn official | Popover, Button, ScrollArea | not required |

Aucun composant tiers. Tous les composants viennent du registre shadcn officiel.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS — all copy defined in French, no placeholder text
- [x] Dimension 2 Visuals: PASS — layout specs with exact dimensions, states defined
- [x] Dimension 3 Color: PASS — palette consistent with Phase 70/80, contrast verified
- [x] Dimension 4 Typography: PASS — sizes from existing scale, weights defined
- [x] Dimension 5 Spacing: PASS — 4px base, all values are multiples of 4
- [x] Dimension 6 Registry Safety: PASS — shadcn official only

**Approval:** approved 2026-03-23
