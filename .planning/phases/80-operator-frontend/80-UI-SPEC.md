---
phase: 80
slug: operator-frontend
status: draft
shadcn_initialized: true
preset: none
created: 2026-03-23
---

# Phase 80 — UI Design Contract

> Visual and interaction contract for the Operator Frontend. Covers dashboard, order detail (accept/reject), truck CRUD, route sheets, and role-based sidebar.
> Inherits design system from Phase 70 (palette, fonts, spacing, components).

---

## Design System

Inherited from Phase 70. No changes.

| Property | Value |
|----------|-------|
| Tool | shadcn/ui (already initialized) |
| Component library | base-ui (via shadcn v4) |
| Icon library | Lucide React |
| Font | Figtree (headings) / Noto Sans (body) |

**Additional shadcn components needed:** none (all already installed in Phase 70)

---

## Spacing Scale

Inherited from Phase 70. No changes.

---

## Typography

Inherited from Phase 70. Additional role:

| Role | Size | Weight | Line Height | Font |
|------|------|--------|-------------|------|
| KPI number | 28px | 700 | 1.0 | Figtree |
| KPI label | 13px | 500 | 1.4 | Noto Sans |

---

## Color

Inherited from Phase 70. Additional tokens:

| Role | Value | Usage |
|------|-------|-------|
| KPI card bg | `#FFFFFF` | KPI stat cards background |
| KPI accent (pending) | `#FEF3C7` | "En attente" KPI card accent border-left |
| KPI accent (accepted) | `#D1FAE5` | "Acceptées" KPI card accent border-left |
| KPI accent (total) | `#DBEAFE` | "Total" KPI card accent border-left |
| Accept button | `#059669` | Green for accept action (emerald-600) |
| Accept hover | `#047857` | Accept button hover (emerald-700) |

Status badges: same as Phase 70 (7 statuses).

---

## Page Layouts

### Dashboard (`/dashboard`)

```
┌──────────────────────────────────────────────────────┐
│  Dashboard                                           │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │▎En attente│ │▎Acceptées │ │▎Total    │            │
│  │   12      │ │    8      │ │   20     │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│                                                      │
│  [Statut ▼ Créée] [Du ___] [Au ___] [Pharmacien ▼] │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │ Réf.  │ Pharmacien │ Date  │ Montant │ Statut│ ▲▼│
│  ├───────┼────────────┼───────┼─────────┼───────│   │
│  │ C012  │ Dr Salhi   │ 23/03 │ 3200 DA │ Créée │   │
│  │ C011  │ Dr Bouali  │ 23/03 │ 1640 DA │ Créée │   │
│  │ C010  │ Dr Amrani  │ 22/03 │ 5100 DA │ Créée │   │
│  └──────────────────────────────────────────────┘    │
│  ← 1 2 3 →                                          │
└──────────────────────────────────────────────────────┘
  KPI cards: 3 cards, flex row, gap-md
  Card: white bg, shadow-sm, rounded-lg, border-l-4 colored
  Table: sortable headers (▲▼ icon on hover)
  Default filter: statut = "creee"
  Clic ligne → /dashboard/commandes/{id}
```

### Détail commande opératrice (`/dashboard/commandes/[id]`)

```
┌──────────────────────────────────────────────────────┐
│  ← Retour                                            │
│                                                      │
│  Commande C0000000012              [Badge: Créée]    │
│  Passée le 23/03/2026                                │
│  Pharmacien : Dr Ahmed Salhi (ahmed@pharma.dz)       │
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
│  ┌─ Si statut = Créée ─────────────────────────┐    │
│  │ [Rejeter]                    [Accepter ✓]    │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌─ Si statut = Acceptée ──────────────────────┐    │
│  │ Camion : [Sélectionner un camion ▼]          │    │
│  │          • Camion A (AB-123-CD)              │    │
│  │          • Camion B (EF-456-GH)              │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
└──────────────────────────────────────────────────────┘
  Accept button: bg-emerald-600, text-white
  Reject button: outline destructive (same as cancel Phase 70)
  Reject → AlertDialog confirmation
  Accept → direct action, toast, badge update
  Camion dropdown → visible only for Acceptée, assigns to truck
```

### Camions CRUD (`/dashboard/camions`)

```
┌──────────────────────────────────────────────────────┐
│  Camions                        [+ Ajouter camion]   │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │ Nom         │ Plaque      │ Actions          │    │
│  ├─────────────┼─────────────┼──────────────────│    │
│  │ Camion A    │ AB-123-CD   │ [✎] [🗑]        │    │
│  │ Camion B    │ EF-456-GH   │ [✎] [🗑]        │    │
│  │ Camion C    │ IJ-789-KL   │ [✎] [🗑]        │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
└──────────────────────────────────────────────────────┘
  Ajouter/Modifier: Dialog avec champs nom + plaque
  Supprimer: AlertDialog confirmation
  Icônes: Lucide Pencil + Trash2 (ghost buttons)
  Empty state: "Aucun camion. Ajoutez un camion pour commencer."
```

### Feuilles de route (`/dashboard/routes`)

```
┌──────────────────────────────────────────────────────┐
│  Feuilles de route                                   │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ Camion A (AB-123-CD)        FR-001  3 cmd      │  │
│  │ ▎ C012  Dr Salhi    1 640 DA                   │  │
│  │ ▎ C009  Dr Amrani   2 300 DA                   │  │
│  │ ▎ C007  Dr Kaci       980 DA                   │  │
│  │ Colis std: 5  Sachets std: 2  Frigo: 1         │  │
│  │                               [Voir PDF →]     │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ Camion B (EF-456-GH)        FR-002  1 cmd      │  │
│  │ ▎ C008  Dr Meziane  4 200 DA                   │  │
│  │ Colis std: 3  Sachets std: 0  Frigo: 0         │  │
│  │                               [Voir PDF →]     │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ Camion C (IJ-789-KL)        Aucune feuille     │  │
│  │ Pas de commandes assignées                      │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
  Layout: cards empilées, une par camion
  Card: white bg, border, rounded-lg
  Commandes: liste compacte dans la card
  Compteurs: inline, text-sm, muted
  PDF link: ghost button, opens in new tab
  Empty (no trucks): "Aucun camion configuré. Ajoutez un camion d'abord."
  Empty (no sheets): "Pas de commandes assignées" dans la card camion
```

### Sidebar dynamique

```
Opératrice:                  Pharmacien (inchangé):
┌───────────────┐            ┌────────────┐
│  DIMED        │            │  DIMED     │
│               │            │            │
│ ■ Dashboard   │ (LayoutDashboard) │ ■ Catalogue │ (Package)
│ ■ Routes      │ (Route)    │ ■ Commandes│ (ClipboardList)
│ ■ Camions     │ (Truck)    │            │
│               │            │            │
│────────────── │            │────────────│
│  User name    │            │  User name │
│  Déconnexion  │            │  Déconnexion│
└───────────────┘            └────────────┘
  Icônes Lucide: LayoutDashboard, Route, Truck
  Active state: same as Phase 70 (border-l-3 primary + bg muted)
```

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Dashboard title | "Dashboard" |
| KPI pending | "En attente" |
| KPI accepted | "Acceptées aujourd'hui" |
| KPI total | "Total du jour" |
| Accept button | "Accepter" |
| Reject button | "Rejeter" |
| Reject confirmation title | "Rejeter la commande" |
| Reject confirmation body | "Cette commande sera annulée. Voulez-vous continuer ?" |
| Reject confirm button | "Oui, rejeter" |
| Reject cancel button | "Non, garder" |
| Accept success toast | "Commande acceptée" |
| Reject success toast | "Commande rejetée" |
| Truck assign success | "Commande assignée au camion {nom}" |
| Empty dashboard | "Aucune commande en attente" |
| Empty trucks | "Aucun camion. Ajoutez un camion pour commencer." |
| Empty route sheets | "Pas de commandes assignées" |
| Add truck button | "Ajouter un camion" |
| Add truck dialog title | "Nouveau camion" |
| Edit truck dialog title | "Modifier le camion" |
| Delete truck confirmation | "Supprimer ce camion ? Cette action est irréversible." |
| Truck name label | "Nom / identifiant" |
| Truck plate label | "Plaque d'immatriculation" |
| Routes page title | "Feuilles de route" |
| Trucks page title | "Camions" |
| PDF link | "Voir PDF" |
| Pharmacien info label | "Pharmacien" |

---

## Interaction States

### KPI cards
- Default: white bg, shadow-sm, border-l-4 colored
- Hover: shadow-md transition 150ms (clickable → filters table to that status)

### Accept button
- Default: `bg-emerald-600 text-white`
- Hover: `bg-emerald-700`
- Disabled: `opacity-50 cursor-not-allowed`
- Loading: spinner replaces text

### Reject button
- Same as destructive-outline from Phase 70

### Table sort headers
- Default: text-muted-foreground
- Hover: text-foreground + sort icon appears (ArrowUpDown)
- Active sort: text-foreground + ArrowUp or ArrowDown

### Truck CRUD
- Edit/Delete: ghost icon buttons, visible on row hover
- Delete: AlertDialog confirmation

---

## Responsive Behavior

Same breakpoints as Phase 70. Additional:

| Breakpoint | Layout change |
|------------|---------------|
| >= 1024px | KPI cards: 3 in a row |
| 768-1023px | KPI cards: 3 in a row (narrower) |
| < 768px | KPI cards: stacked vertically, table scrolls horizontally |

Route sheet cards: always full width, stacked.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | (all already installed from Phase 70) | not required |

No new registry blocks needed.

---

## Accessibility Checklist

Inherited from Phase 70, plus:
- [x] KPI cards have aria-label describing the metric
- [x] Sort buttons have aria-label "Trier par {colonne}"
- [x] Accept/Reject buttons clearly labeled
- [x] Truck delete confirmation accessible
- [x] Route sheet cards have meaningful structure (headings, lists)

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-03-23
