# Phase 70: Pharmacist Frontend - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Interface web pour le pharmacien : consulter le catalogue de médicaments, composer et passer des commandes, suivre l'historique et le détail de ses commandes. Login inclus. L'interface opératrice est Phase 80.

</domain>

<decisions>
## Implementation Decisions

### Catalogue & recherche
- Layout **table** avec colonnes : désignation, DCI, dosage, forme, PPA, fabricant, action [+]
- **Live search** avec debounce (~300ms) — l'API fuzzy pg_trgm est prête
- Filtres : **forme pharmaceutique** (dropdown) + **fabricant** (dropdown), au-dessus de la table
- **Pagination classique** (boutons page 1, 2, 3...) — API supporte limit/offset

### Panier & commande
- Panier en **sidebar droite** visible en permanence sur la page catalogue
- Modification quantités : **boutons +/- ET champ éditable** (clic sur le chiffre pour taper directement)
- 0 = supprime l'article du panier
- **Étape de confirmation** avant envoi : récap articles, quantités, montant total + bouton "Confirmer la commande"
- Après confirmation : **redirection vers la page détail** de la commande créée + toast de succès
- Panier côté client (state React), pas de persistance serveur

### Historique & suivi commandes
- Layout **table** cohérent avec le catalogue : colonnes référence, date, nb articles, montant, statut (badge coloré)
- Clic sur une ligne = page détail
- Filtres : **dropdown statut** (Toutes, Créée, Acceptée, En préparation, etc.) + **date picker plage** (date_from / date_to)
- Pagination classique (même pattern que catalogue)

### Détail commande
- En-tête : référence, date, statut (badge), montant total
- Table des lignes : désignation, quantité demandée, prix unitaire, sous-total
- Bouton **"Annuler la commande"** visible uniquement quand statut = Créée, avec modale de confirmation

### Navigation & layout
- **Sidebar gauche** : logo DIMED, liens Catalogue et Mes Commandes, infos utilisateur + déconnexion en bas
- Sidebar collapsible pour gagner de l'espace
- Page de login **centrée minimaliste** : logo + formulaire email/mot de passe sur fond clair

### Design & thème
- Palette **bleu médical / professionnel** : fond clair, accents bleus. Couleurs vives réservées aux badges de statut
- Utiliser le skill `ui-ux-pro-max` pour guider le design pendant l'implémentation
- Librairie UI : à la discrétion de Claude (guidé par le skill ui-ux-pro-max)

### Claude's Discretion
- Choix de la librairie UI (shadcn/ui, Ant Design, ou autre — guidé par ui-ux-pro-max)
- Loading states et skeletons
- Responsive breakpoints
- Gestion des états d'erreur (API down, réseau)
- Toast / notification design
- Exact spacing et typography

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### API endpoints (backend prêt)
- `apps/api/app/auth/router.py` — Login (POST /auth/login), refresh, logout, me. Auth par cookies httpOnly
- `apps/api/app/medicaments/router.py` — GET /medicaments (list + fuzzy search pg_trgm, pagination limit/offset), GET /medicaments/{id}
- `apps/api/app/commandes/router.py` — POST /commandes (create), GET /commandes (list filtrable), GET /commandes/{id} (detail), PATCH accept/reject/cancel
- `apps/api/app/commandes/schemas.py` — CreateOrderRequest, OrderResponse, OrderDetailResponse, LigneResponse (contrats API)

### Auth
- `apps/api/app/auth/dependencies.py` — CurrentUser dependency, cookie extraction
- `apps/api/app/auth/schemas.py` — LoginRequest, UserResponse

### Modèles de données
- `apps/api/app/models/commande.py` — OrderStatus enum (state machine), Commande + LigneCommande models
- `apps/api/app/models/medicament.py` — Medicament model (champs disponibles pour la table)

### CDC
- `CDC_Module1_Commande.docx` — Cahier des charges Module 1 (spécifications fonctionnelles pharmacien)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `packages/ui/` — Package UI partagé (vide, prêt à recevoir des composants communs)
- `packages/shared-types/` — Types partagés entre apps (à alimenter avec les types API)

### Established Patterns
- Auth par **cookies httpOnly** (SameSite=Lax) — tous les fetch doivent utiliser `credentials: "include"`
- API retourne `{items: [], total, limit, offset}` pour les listes paginées
- Fuzzy search sur designation via `?search=` query param (min 2 chars)
- Filtres commandes : `?statut=`, `?date_from=`, `?date_to=`

### Integration Points
- `apps/web/app/layout.tsx` — Layout racine Next.js (scaffold vide, à construire)
- `apps/web/app/page.tsx` — Page d'accueil (scaffold vide)
- `apps/web/package.json` — Next.js 15 + React 19, aucune lib UI installée encore
- API accessible sur `http://localhost:8000` (Docker Compose)

</code_context>

<specifics>
## Specific Ideas

- Tables pour les données tabulaires (catalogue ET commandes) — cohérence visuelle
- Le pharmacien est un professionnel qui connaît les noms des médicaments — la recherche est l'outil principal, les filtres sont secondaires
- Sidebar panier toujours visible = le pharmacien compose sa commande sans quitter le catalogue
- Domaine pharma = confirmation obligatoire avant envoi de commande (pas d'envoi accidentel)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 70-pharmacist-frontend*
*Context gathered: 2026-03-23*
