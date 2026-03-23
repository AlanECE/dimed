# Phase 90: Notifications - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Notifications pharmacien sur les changements de statut de commande. Le pharmacien voit une icône cloche avec compteur dans le header, un panneau dropdown avec les notifications récentes (lu/non-lu), et peut cliquer pour accéder au détail de la commande. Backend : table notification en BDD, endpoints CRUD, création automatique dans transition_order. Pas de temps réel — polling au chargement de page.

</domain>

<decisions>
## Implementation Decisions

### Transport
- **Pas de temps réel** (pas de SSE, WebSocket, ni polling intervalle)
- Notifications récupérées au **chargement de page** (fetch on mount/navigation)
- Endpoint GET /notifications retourne les 20 dernières avec compteur non-lues

### Déclenchement backend
- Notification créée **dans transition_order** (router commandes), après le commit du changement de statut
- 4 statuts déclencheurs : **Acceptée, En préparation, En route, Livrée**
- Insertion directe dans la table notification (pas d'event listener séparé)
- `NOTIFIABLE_STATUSES` = set des 4 statuts

### Contenu des messages
- Format simple : **référence commande + statut**
- Acceptée : "Commande C00000042 acceptée"
- En préparation : "Commande C00000042 en préparation"
- En route : "Commande C00000042 en cours de livraison"
- Livrée : "Commande C00000042 livrée"

### Persistance
- **Table notification en PostgreSQL** : id (UUID), user_id (FK), commande_id (FK), type (varchar), message (text), read (boolean default false), created_at (timestamp)
- Endpoints : GET /notifications (avec ?unread=true), PATCH /notifications/{id}/read, PATCH /notifications/read-all
- Migration Alembic dédiée

### Affichage UI
- **Icône cloche dans le header** (haut droite), à côté des infos utilisateur
- **Badge rouge avec compteur** non-lues
- Clic cloche ouvre un **panneau dropdown** avec les 20 dernières notifications
- Indicateur visuel lu/non-lu (point ou opacité)
- **Clic sur une notification = marque comme lu + redirection** vers /commandes/{id}
- Icône : Bell de Lucide icons (déjà installé)

### Claude's Discretion
- Design exact du panneau dropdown (Popover shadcn ou custom)
- Animation d'ouverture du panneau
- Empty state quand aucune notification
- Bouton "Tout marquer comme lu" dans le panneau (optionnel)
- Format relative time ("il y a 5 min")

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend — Transition de statut
- `apps/api/app/commandes/router.py` — Endpoints commandes, transition_order (où insérer la création de notification)
- `apps/api/app/models/state_machine.py` — VALID_TRANSITIONS, validate_transition()
- `apps/api/app/models/commande.py` — OrderStatus enum (statuts déclencheurs)

### Backend — Modèle & migration
- `apps/api/app/models/` — Répertoire modèles existants (pattern à suivre pour Notification)
- `apps/api/alembic/versions/` — Migrations existantes (pattern de nommage)

### Frontend — UI existante
- `apps/web/app/layout.tsx` — Layout racine avec Toaster sonner (top-right)
- `apps/web/components/sidebar.tsx` — Sidebar dynamique par rôle (header à modifier pour la cloche)
- `apps/web/lib/api.ts` — fetchApi avec cookie forwarding (pour les appels notifications)
- `apps/web/lib/auth.tsx` — AuthProvider, useAuth (user context)
- `apps/web/lib/types.ts` — Types partagés (ajouter NotificationResponse)

### CDC
- `CDC_Module1_Commande.docx` — Spécifications fonctionnelles Module 1

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sonner` (Toaster) : déjà installé et configuré top-right — peut servir de feedback immédiat en complément
- `StatusBadge` component : réutilisable pour afficher le statut dans les notifications
- `fetchApi` : client API prêt avec cookie auth
- shadcn components : Popover, Button, Badge, ScrollArea disponibles pour le panneau
- Lucide icons : Bell icon disponible

### Established Patterns
- Auth par cookies httpOnly — tous les fetch utilisent `credentials: "include"`
- Toast (sonner) pour feedback actions utilisateur
- URL params via useSearchParams pour les filtres
- Tables avec pagination (pattern réutilisable pour la liste notifs)

### Integration Points
- `apps/web/app/(authenticated)/layout.tsx` — Layout authentifié, ajouter le header avec cloche
- `apps/api/app/main.py` — Inclure le nouveau router notifications
- `apps/api/app/commandes/router.py` — Ajouter création notification dans les endpoints accept/reject/transition

</code_context>

<specifics>
## Specific Ideas

- Pas de temps réel : simple polling au chargement de page, le pharmacien n'a pas besoin d'être notifié à la seconde
- La cloche est le point d'entrée unique pour les notifications — pas de page dédiée
- Le message est volontairement minimal (référence + statut) — le détail est accessible en un clic

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 90-notifications*
*Context gathered: 2026-03-23*
