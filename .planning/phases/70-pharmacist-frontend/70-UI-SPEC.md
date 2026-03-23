---
phase: 70
slug: pharmacist-frontend
status: draft
shadcn_initialized: false
preset: none
created: 2026-03-23
---

# Phase 70 — UI Design Contract

> Visual and interaction contract for the Pharmacist Frontend. Covers catalog, cart, order history, order detail, login, and layout shell.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | shadcn/ui (init during implementation) |
| Preset | default (blue theme override) |
| Component library | Radix UI (via shadcn) |
| Icon library | Lucide React |
| Font | Figtree (headings) / Noto Sans (body) |

**shadcn components needed:** Table, Input, Button, Badge, Select, Dialog, Sheet, Separator, Skeleton, Toast, DropdownMenu, Pagination, Card

---

## Spacing Scale

Declared values (multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact element spacing, table cell padding |
| md | 16px | Default element spacing, input padding |
| lg | 24px | Section padding, sidebar item spacing |
| xl | 32px | Layout gaps between major sections |
| 2xl | 48px | Page-level vertical spacing |
| 3xl | 64px | Not used in this phase |

Exceptions: Sidebar width fixed at 256px (expanded) / 64px (collapsed)

---

## Typography

| Role | Size | Weight | Line Height | Font |
|------|------|--------|-------------|------|
| Body | 14px | 400 | 1.5 | Noto Sans |
| Label | 12px | 500 | 1.4 | Noto Sans |
| Table cell | 14px | 400 | 1.4 | Noto Sans |
| Table header | 13px | 600 | 1.4 | Noto Sans |
| Heading (h2) | 24px | 600 | 1.3 | Figtree |
| Heading (h3) | 18px | 600 | 1.3 | Figtree |
| Display (h1) | 30px | 700 | 1.2 | Figtree |
| Nav item | 14px | 500 | 1.4 | Noto Sans |
| Button | 14px | 500 | 1.0 | Noto Sans |

Number formatting: tabular figures (`font-variant-numeric: tabular-nums`) for prices, quantities, reference IDs.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F0F9FF` | Page background |
| Surface | `#FFFFFF` | Cards, table rows, sidebar, modals |
| Secondary (30%) | `#EFF7FB` | Muted backgrounds, sidebar hover, table header |
| Primary | `#0284C7` | Primary buttons, links, active nav, focus rings |
| Primary hover | `#0369A1` | Primary button hover state |
| Accent (10%) | `#0284C7` | Add-to-cart button, pagination active, search icon |
| Destructive | `#DC2626` | Cancel order button, error states |
| Destructive hover | `#B91C1C` | Destructive button hover |
| Text primary | `#0F172A` | Headings, body text, table cells |
| Text secondary | `#64748B` | Labels, timestamps, secondary info |
| Border | `#E0F0F8` | Table borders, card borders, input borders |
| Ring | `#0284C7` | Focus ring (3px) |

### Status badges

| Status | Background | Text | Border |
|--------|------------|------|--------|
| Créée | `#FEF3C7` | `#92400E` | `#FDE68A` |
| Acceptée | `#D1FAE5` | `#065F46` | `#A7F3D0` |
| En préparation | `#DBEAFE` | `#1E40AF` | `#BFDBFE` |
| Prête à livrer | `#E0E7FF` | `#3730A3` | `#C7D2FE` |
| En livraison | `#FED7AA` | `#9A3412` | `#FDBA74` |
| Livrée | `#BBF7D0` | `#14532D` | `#86EFAC` |
| Annulée | `#FEE2E2` | `#991B1B` | `#FECACA` |

Accent reserved for: primary CTA buttons, active nav indicator, pagination current page, focus rings. Never used for decorative backgrounds.

---

## Page Layouts

### Login (`/login`)

```
┌──────────────────────────────────────────────┐
│              Background: #F0F9FF             │
│                                              │
│         ┌──────────────────────┐             │
│         │   [DIMED logo]       │             │
│         │                      │             │
│         │   Email              │             │
│         │   [_______________]  │             │
│         │                      │             │
│         │   Mot de passe       │             │
│         │   [_______________]  │             │
│         │                      │             │
│         │   [  Se connecter  ] │  ← Primary  │
│         │                      │             │
│         └──────────────────────┘             │
│           Card: white, shadow-md             │
│           max-w-sm, centered                 │
└──────────────────────────────────────────────┘
```

### App Shell (authenticated)

```
┌────────────┬─────────────────────────────────┐
│  DIMED     │  Page title (h2)                │
│            │                                 │
│  ■ Catalog │  ┌─────────────────────────────┐│
│  ■ Commandes│  │  Content area              ││
│            │  │                             ││
│            │  │                             ││
│            │  │                             ││
│────────────│  └─────────────────────────────┘│
│  User name │                                 │
│  Déconnexion│                                │
└────────────┴─────────────────────────────────┘
  Sidebar:       Content:
  w-64 (256px)   flex-1, p-lg (24px)
  bg-white       bg-#F0F9FF
  border-r       max-w-7xl
```

Sidebar: collapsible to 64px (icon-only). Active item: left border `#0284C7` 3px + bg `#EFF7FB`.

### Catalogue (`/catalogue`)

```
┌──────────────────────────────────────────────────────────┬──────────────┐
│  Catalogue                                               │  Panier (3)  │
│                                                          │              │
│  [🔍 Rechercher un médicament...        ]                │  DOLIPRANE   │
│  [Forme ▼]  [Fabricant ▼]                                │  x3   750 DA │
│                                                          │  [-][3][+]   │
│  ┌──────────────────────────────────────────────────┐    │              │
│  │ Désignation    │ DCI       │ Dosage │ Forme │ PPA│    │  AUGMENTIN   │
│  ├────────────────┼───────────┼────────┼───────┼────│    │  x1   890 DA │
│  │ DOLIPRANE 1g   │ Paracétam │ 1000mg │ Cp    │250 │[+] │  [-][1][+]   │
│  │ AUGMENTIN 1g   │ Amoxicill │ 1g     │ Sach  │890 │[+] │              │
│  │ VOLTARENE 75mg │ Diclofén  │ 75mg   │ Gél   │340 │[+] │  ────────    │
│  └──────────────────────────────────────────────────┘    │  Total:      │
│  ← 1 2 3 ... 12 →                                       │  1 640 DA    │
│                                                          │              │
│                                                          │  [Valider →] │
└──────────────────────────────────────────────────────────┴──────────────┘
  Table: flex-1                                              Sidebar: w-80
  overflow-x-auto                                            (320px)
  hover: bg-#EFF7FB                                          sticky top
  20 rows/page                                               border-l
```

### Confirmation commande (Dialog)

```
┌───────────────────────────────────────┐
│  Confirmer la commande                │
│                                       │
│  Articles : 4                         │
│  Montant total : 1 640 DA             │
│                                       │
│  ┌───────────────────────────────┐    │
│  │ Désignation      │ Qté │ Prix│    │
│  │ DOLIPRANE 1g     │  3  │ 750 │    │
│  │ AUGMENTIN 1g     │  1  │ 890 │    │
│  └───────────────────────────────┘    │
│                                       │
│  [Annuler]          [Confirmer →]     │
│                      ↑ Primary        │
└───────────────────────────────────────┘
  Dialog: max-w-lg, centered overlay
  Scrim: black/50
```

### Commandes (`/commandes`)

```
┌──────────────────────────────────────────────────────┐
│  Mes Commandes                                       │
│                                                      │
│  [Statut ▼ Toutes]  [Du ___]  [Au ___]              │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │ Référence   │ Date       │ Art. │ Montant │ Statut    │
│  ├─────────────┼────────────┼──────┼─────────┼──────────│
│  │ C0000000012 │ 23/03/2026 │  5   │ 3200 DA │ 🟢Acceptée │
│  │ C0000000011 │ 22/03/2026 │  3   │ 1640 DA │ 🟡Créée    │
│  │ C0000000010 │ 21/03/2026 │  8   │ 5100 DA │ 🔵En livr. │
│  └──────────────────────────────────────────────┘    │
│  ← 1 2 3 →                                          │
│                                                      │
└──────────────────────────────────────────────────────┘
  Clic sur ligne → /commandes/{id}
  Statut = Badge composant (couleurs ci-dessus)
  Pas d'emoji — utiliser Badge shadcn avec dot coloré
```

### Détail commande (`/commandes/[id]`)

```
┌──────────────────────────────────────────────────────┐
│  ← Retour                                           │
│                                                      │
│  Commande C0000000012              [Badge: Créée]    │
│  Passée le 23/03/2026                                │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │ Désignation      │ Quantité │ Prix U. │ Total│    │
│  ├──────────────────┼──────────┼─────────┼──────│    │
│  │ DOLIPRANE 1g     │    3     │  250 DA │ 750  │    │
│  │ AUGMENTIN 1g     │    1     │  890 DA │ 890  │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  Montant total : 1 640 DA                            │
│                                                      │
│  [Annuler la commande]   ← Destructive, only Créée  │
│                                                      │
└──────────────────────────────────────────────────────┘
  "Annuler" ouvre Dialog de confirmation
  Button variant: destructive (rouge)
```

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA (catalogue) | "Valider la commande" |
| Primary CTA (confirmation) | "Confirmer la commande" |
| Add to cart | "Ajouter" (bouton +) |
| Empty cart heading | "Votre panier est vide" |
| Empty cart body | "Ajoutez des médicaments depuis le catalogue pour passer commande." |
| Empty orders heading | "Aucune commande" |
| Empty orders body | "Vos commandes apparaîtront ici une fois passées." |
| Login button | "Se connecter" |
| Login error | "Email ou mot de passe incorrect. Vérifiez vos identifiants." |
| Cancel confirmation | "Annuler la commande : Cette action est irréversible. Voulez-vous continuer ?" |
| Cancel confirm button | "Oui, annuler" |
| Cancel cancel button | "Non, garder" |
| Order success toast | "Commande créée avec succès" |
| Cancel success toast | "Commande annulée" |
| Network error | "Erreur de connexion. Vérifiez votre réseau et réessayez." |
| Search placeholder | "Rechercher un médicament..." |

---

## Interaction States

### Table rows
- Default: `bg-white`
- Hover: `bg-#EFF7FB` transition 150ms
- Active/clicked: no special state (navigates)

### Buttons
- Primary: `bg-#0284C7 text-white` → hover `bg-#0369A1` → disabled `opacity-50 cursor-not-allowed`
- Destructive: `bg-white text-#DC2626 border-#DC2626` → hover `bg-#FEE2E2` → disabled `opacity-50`
- Ghost: `text-#64748B` → hover `bg-#EFF7FB`

### Inputs
- Default: `border-#E0F0F8` → focus `ring-2 ring-#0284C7 border-#0284C7`
- Error: `border-#DC2626 ring-#DC2626`

### Cart sidebar
- Sticky `top-0 right-0 h-screen`
- Quantity: `[-]` ghost button / editable number field / `[+]` ghost button
- Remove: quantity reaches 0

### Loading states
- Tables: skeleton rows (6 rows, shimmer animation 1.5s)
- Buttons: spinner icon replaces text, disabled during loading
- Cart validation: "Valider" button shows spinner

### Focus management
- Focus ring: 3px `#0284C7` on all interactive elements
- After login error: auto-focus email field
- After order cancel dialog: focus returns to trigger button
- Tab order: sidebar nav → content → cart sidebar

---

## Responsive Behavior

| Breakpoint | Layout change |
|------------|---------------|
| >= 1280px | Full layout: sidebar (256px) + content + cart sidebar (320px) |
| 1024-1279px | Sidebar collapsed (64px) + content + cart sidebar (280px) |
| 768-1023px | No sidebar (top nav instead) + content full width + cart as Sheet (slide-in) |
| < 768px | Top nav + stacked content + cart as Sheet + table cards on mobile |

Mobile table fallback: medication cards with key info (désignation, PPA, bouton +). Orders table scrolls horizontally with sticky first column (référence).

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | table, input, button, badge, select, dialog, sheet, separator, skeleton, toast, dropdown-menu, pagination, card | not required |

No third-party registry blocks needed.

---

## Accessibility Checklist

- [x] All text contrast >= 4.5:1 (WCAG AA)
- [x] Focus rings 3px on all interactive elements
- [x] `aria-label` on icon-only buttons (collapse sidebar, +/- quantity)
- [x] Table uses semantic `<table>`, `<thead>`, `<th scope="col">`
- [x] Status badges include text (not color-only)
- [x] Form labels visible (not placeholder-only)
- [x] `prefers-reduced-motion` respected (no shimmer, instant transitions)
- [x] Keyboard navigation: Tab through nav → content → cart
- [x] Skip link to main content
- [x] Min touch target 44x44px for all buttons

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
