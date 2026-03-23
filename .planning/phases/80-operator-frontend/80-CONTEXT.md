# Phase 80: Operator Frontend - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Interface web pour l'opératrice : dashboard de gestion des commandes avec compteurs KPI, validation/rejet depuis le détail, CRUD camions, concept de lignes géographiques, assignation commandes aux camions, page feuilles de route. La sidebar adapte ses items selon le rôle (opératrice vs pharmacien).

Note : cette phase inclut du travail backend (CRUD camions, modèle lignes géographiques, endpoints associés) en plus du frontend.

</domain>

<decisions>
## Implementation Decisions

### Dashboard commandes
- Layout **compteurs KPI en haut + table en dessous**
- 3 cartes KPI : commandes en attente, acceptées aujourd'hui, total du jour
- Table avec colonnes : référence, pharmacien, date, montant, statut (StatusBadge)
- Filtres : **statut dropdown + date picker plage + pharmacien dropdown/search**
- Vue par défaut : **filtrée sur statut "creee"** (commandes en attente)
- Tri interactif par colonnes (clic en-tête → asc/desc, côté client)
- Pagination classique (même pattern que Phase 70)

### Validation / rejet
- Actions **depuis le détail commande uniquement** (pas dans la table)
- Clic sur une ligne → page détail opératrice
- Détail affiche : articles, montant, **nom + email du pharmacien**
- Bouton "Accepter" = **action directe** (un clic, pas de confirmation)
- Bouton "Rejeter" = **confirmation modale** (AlertDialog, action destructive)
- Motif de rejet : pas en v1
- Après acceptation : **reste sur le détail**, badge se met à jour, toast succès
- Après rejet : reste sur le détail, badge "Annulée", toast succès

### Camions (CRUD)
- Page dédiée "Camions" dans la sidebar opératrice
- CRUD complet : ajouter, modifier, supprimer un camion
- Champs camion : nom/identifiant, plaque d'immatriculation
- Table de camions avec actions (modifier, supprimer)
- Backend : nouveau modèle Camion, endpoints CRUD

### Lignes géographiques
- Une **ligne** = zone/secteur géographique (ex: Alger Centre, Blida, Tizi Ouzou)
- Les commandes sont classées par ligne selon l'adresse/zone du pharmacien
- N'importe quel camion peut être affecté à une ligne
- Les commandes acceptées arrivent sur leur "ligne dispo" respective
- L'opératrice assigne un camion à une ligne pour créer/alimenter la feuille de route
- Backend : nouveau modèle Ligne, association pharmacien→ligne, endpoints

### Assignation commandes aux camions
- Depuis le **détail commande** (commandes acceptées) : dropdown "Camion" pour assigner
- L'assignation crée/met à jour la feuille de route du camion automatiquement (API existante DOC-04)
- Une seule feuille de route active par camion (RG-1-05)

### Feuilles de route (visualisation)
- Page dédiée "Feuilles de route" dans la sidebar
- Liste des camions avec leur feuille active
- Chaque feuille montre : commandes assignées (référence, pharmacien, montant), compteurs (colis_std, sachets_std, colis_frg, sachets_frg)
- Lecture seule — l'assignation se fait depuis le détail commande
- Lien vers le PDF de la feuille de route si généré

### Navigation opératrice
- **Même sidebar collapsible** que le pharmacien, items différents selon le rôle
- Opératrice : Dashboard, Feuilles de route, Camions
- Pharmacien : Catalogue, Mes Commandes (inchangé)
- Sidebar dynamique basée sur `user.role` depuis le contexte auth
- Page par défaut opératrice : `/dashboard`

### Claude's Discretion
- Design exact des cartes KPI (icônes, couleurs)
- Empty states pour dashboard vide, feuilles de route vides, camions vides
- Responsive behavior pour les nouvelles pages
- Loading skeletons
- Gestion d'erreurs réseau

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### API endpoints existants
- `apps/api/app/commandes/router.py` — GET /commandes (filtres statut, date, pharmacien_id), PATCH accept/reject
- `apps/api/app/documents/router.py` — Route sheets, association commandes/camions
- `apps/api/app/documents/service.py` — Route sheet generation logic, truck association
- `apps/api/app/models/document.py` — RouteSheet model, truck fields, counters JSONB

### Frontend existant (Phase 70)
- `apps/web/components/sidebar.tsx` — Sidebar à adapter pour rôle dynamique
- `apps/web/components/status-badge.tsx` — Réutiliser pour les badges statut
- `apps/web/lib/api.ts` — API client avec cookie forwarding
- `apps/web/lib/auth.tsx` — AuthProvider, useAuth (user.role)
- `apps/web/lib/types.ts` — Types partagés (OrderResponse, etc.)
- `apps/web/hooks/use-orders.ts` — Hook commandes réutilisable

### CDC
- `CDC_Module1_Commande.docx` — Spécifications fonctionnelles opératrice

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StatusBadge` component : réutiliser tel quel pour les badges commandes
- `useOrders` hook : réutilisable pour le dashboard (mêmes filtres API)
- `fetchApi` : client API prêt avec cookie auth
- shadcn components : Table, Badge, Select, Dialog, AlertDialog, Card, Skeleton, Button, Input déjà installés
- Palette couleurs et fonts : identiques à Phase 70

### Established Patterns
- Tables avec pagination classique (page X sur Y, prev/next)
- Filtres en URL search params via useSearchParams
- AlertDialog pour confirmations destructives
- Toast (sonner) pour feedback actions
- Loading : skeleton rows dans les tables

### Integration Points
- `apps/web/components/sidebar.tsx` : doit devenir dynamique par rôle
- `apps/web/app/(authenticated)/layout.tsx` : déjà avec CartProvider (pharmacien only)
- `apps/web/middleware.ts` : redirection par rôle (pharmacien→/catalogue, opératrice→/dashboard)
- Backend existant : endpoints accept/reject prêts, route sheets prêts

</code_context>

<specifics>
## Specific Ideas

- L'opératrice gère des lignes géographiques, pas juste des camions individuels
- Le flow est : commande acceptée → arrive sur sa ligne dispo → opératrice assigne un camion à la ligne → feuille de route générée
- Le détail commande opératrice est plus riche que celui du pharmacien (nom+email pharmacien, actions accept/reject, assignation camion)
- Les compteurs KPI donnent une vue d'ensemble immédiate de l'activité du jour

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. Le CRUD camion et les lignes sont inclus dans cette phase.

</deferred>

---

*Phase: 80-operator-frontend*
*Context gathered: 2026-03-23*
