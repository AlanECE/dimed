# Phase 90: Notifications - Research

**Researched:** 2026-03-23
**Mode:** Ecosystem
**Confidence:** High — simple CRUD + polling pattern, well-understood stack

## Standard Stack

Aucune nouvelle dépendance nécessaire. Tout est déjà dans le projet :

| Concern | Solution | Already in project? |
|---------|----------|-------------------|
| Backend model | SQLAlchemy 2.0 async + Alembic migration | Yes |
| Backend endpoints | FastAPI router + Pydantic schemas | Yes |
| Frontend data fetching | `fetchApi` custom + `useEffect` + `useState` | Yes (pattern `useOrders`) |
| UI dropdown | shadcn Popover + ScrollArea | Yes (shadcn installed) |
| Icons | Lucide `Bell` icon | Yes (lucide-react) |
| Feedback toast | sonner `toast()` | Yes |
| Relative time | Intl.RelativeTimeFormat (native browser API) | Built-in |

**Pas besoin de SWR/react-query** — le projet n'en utilise pas, et le pattern `useEffect` + `fetchApi` est établi (cf. `useOrders`). Ajouter une lib de fetching pour un seul hook serait incohérent.

## Architecture Patterns

### Backend : Modèle Notification

```python
# apps/api/app/models/notification.py
class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    commande_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("commandes.id"))
    type: Mapped[str] = mapped_column(String(30))  # acceptee, en_preparation, en_route, livree
    message: Mapped[str] = mapped_column(Text)
    read: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=lambda: datetime.now(UTC))
```

**Index important :** `(user_id, read, created_at DESC)` — couvre la requête principale (non-lues d'un user, triées par date).

### Backend : Création dans transition_order

Le point d'insertion est `apps/api/app/commandes/service.py:transition_order()`, après le `db.flush()` :

```python
NOTIFIABLE_STATUSES = {
    OrderStatus.ACCEPTEE,
    OrderStatus.EN_PREPARATION,
    OrderStatus.EN_ROUTE,
    OrderStatus.LIVREE,
}

STATUS_MESSAGES = {
    OrderStatus.ACCEPTEE: "acceptée",
    OrderStatus.EN_PREPARATION: "en préparation",
    OrderStatus.EN_ROUTE: "en cours de livraison",
    OrderStatus.LIVREE: "livrée",
}

# Dans transition_order, après db.flush() :
if target_status in NOTIFIABLE_STATUSES:
    notification = Notification(
        id=uuid4(),
        user_id=commande.pharmacien_id,
        commande_id=commande.id,
        type=target_status.value,
        message=f"Commande {commande.reference_id} {STATUS_MESSAGES[target_status]}",
    )
    db.add(notification)
    await db.flush()
```

**Pourquoi dans `transition_order` (service) et pas dans le router :** `transition_order` est le point unique de transition de statut. Mettre la création ici garantit que toute transition (peu importe l'endpoint appelant) génère la notification. C'est le même pattern que `generate_order_documents` qui est déjà appelé dans cette fonction.

### Backend : Endpoints notifications

```
GET    /notifications           → liste 20 dernières + unread_count
GET    /notifications/count     → { unread_count: int } (léger, pour le badge)
PATCH  /notifications/{id}/read → marque une notif comme lue
PATCH  /notifications/read-all  → marque toutes comme lues
```

**Pattern recommandé :** L'endpoint `/notifications/count` est séparé et très léger (un seul `SELECT COUNT`) pour être appelé fréquemment sans surcharge. L'endpoint `/notifications` retourne les items + le count en une seule requête.

### Frontend : Hook useNotifications

Suivre exactement le pattern `useOrders` :

```typescript
// hooks/use-notifications.ts
"use client";

export function useNotifications() {
  const [notifications, setNotifications] = useState<NotificationResponse[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(true);

  const doFetch = useCallback(async () => {
    const data = await fetchApi<{
      notifications: NotificationResponse[];
      unread_count: number;
    }>("/notifications");
    setNotifications(data.notifications);
    setUnreadCount(data.unread_count);
    setLoading(false);
  }, []);

  useEffect(() => { doFetch(); }, [doFetch]);

  const markRead = async (id: string) => {
    await fetchApi(`/notifications/${id}/read`, { method: "PATCH" });
    doFetch(); // refetch
  };

  const markAllRead = async () => {
    await fetchApi("/notifications/read-all", { method: "PATCH" });
    doFetch();
  };

  return { notifications, unreadCount, loading, markRead, markAllRead, refetch: doFetch };
}
```

### Frontend : Composant NotificationBell

Pattern shadcn Popover avec Bell icon :

```tsx
// components/notification-bell.tsx
<Popover>
  <PopoverTrigger asChild>
    <Button variant="ghost" size="icon" className="relative">
      <Bell className="h-5 w-5" />
      {unreadCount > 0 && (
        <span className="absolute -top-1 -right-1 h-5 w-5 rounded-full bg-red-500 text-white text-xs flex items-center justify-center">
          {unreadCount > 99 ? "99+" : unreadCount}
        </span>
      )}
    </Button>
  </PopoverTrigger>
  <PopoverContent align="end" className="w-80 p-0">
    <ScrollArea className="h-[400px]">
      {notifications.map(n => (
        <NotificationItem key={n.id} notification={n} onClick={handleClick} />
      ))}
    </ScrollArea>
  </PopoverContent>
</Popover>
```

### Frontend : Placement dans le layout

Le composant `NotificationBell` doit être placé dans le layout authentifié. Actuellement il n'y a pas de header/topbar — la sidebar est le seul élément de navigation.

**Option recommandée :** Ajouter une topbar minimale dans `apps/web/app/(authenticated)/layout.tsx` avec :
- Côté droit : `NotificationBell` + nom utilisateur (déjà dans sidebar, mais la cloche a besoin d'un header)
- Alternativement : intégrer la cloche dans le haut de la sidebar existante

### Frontend : Temps relatif

Utiliser `Intl.RelativeTimeFormat` natif (pas de lib externe) :

```typescript
function relativeTime(dateStr: string): string {
  const now = Date.now();
  const then = new Date(dateStr).getTime();
  const diffSec = Math.round((then - now) / 1000);

  const units: [Intl.RelativeTimeFormatUnit, number][] = [
    ["day", 86400], ["hour", 3600], ["minute", 60], ["second", 1],
  ];

  const rtf = new Intl.RelativeTimeFormat("fr", { numeric: "auto" });
  for (const [unit, sec] of units) {
    if (Math.abs(diffSec) >= sec || unit === "second") {
      return rtf.format(Math.round(diffSec / sec), unit);
    }
  }
  return "";
}
```

## Don't Hand-Roll

| Problem | Use Instead | Why |
|---------|-------------|-----|
| Relative time formatting | `Intl.RelativeTimeFormat` | Native, i18n-ready, no dependency |
| Dropdown positioning | shadcn `Popover` (Radix/base-ui) | Handles portal, focus trap, align, z-index |
| Scroll overflow dans le panneau | shadcn `ScrollArea` | Styled scrollbar, touch support |
| UUID generation backend | `uuid4()` | Pattern établi dans tout le projet |
| Migration | Alembic `revision --autogenerate` | Pattern établi |

## Common Pitfalls

### Backend

1. **Notification créée hors transaction** — La notification DOIT être dans la même transaction que le changement de statut. Si on commit le statut puis fail sur la notif, on a un statut changé sans notification. Solution : les deux dans le même `flush()` avant le `commit()` du router.

2. **N+1 query sur les notifications** — L'endpoint GET /notifications n'a pas besoin de join sur commandes ou users. Le `message` est stocké en texte (dénormalisé) et `commande_id` suffit pour le lien. Pas de relations eager load nécessaires.

3. **Index manquant** — Sans index sur `(user_id, read, created_at)`, la requête "20 dernières notifs d'un user" fera un full scan. Avec quelques milliers de notifs par user, ça reste rapide, mais l'index est gratuit à ajouter.

4. **Migration de l'enum type** — Ne PAS utiliser un `Enum` SQLAlchemy pour `type`. Utiliser `String(30)` — plus flexible si on ajoute des types de notification plus tard. Le projet utilise déjà `StrEnum` côté Python mais `String` en colonne pour la flexibilité.

### Frontend

1. **Fetch à chaque navigation** — Le hook `useNotifications` se re-exécute à chaque montage de composant. Si le `NotificationBell` est dans le layout (pas re-monté), il ne refetch que manuellement. Solution : exposer `refetch()` et l'appeler quand le user interagit (ouvre le panneau).

2. **Optimistic update pour markRead** — Quand le user clique une notif, mettre à jour le state local immédiatement (réduire `unreadCount`, marquer `read=true`) AVANT le PATCH. Si le PATCH fail, revert. Sinon l'UI a un délai visible.

3. **Popover sur mobile** — Le Popover shadcn fonctionne sur mobile mais la largeur `w-80` (320px) peut être trop large sur petit écran. Utiliser `w-[min(320px,calc(100vw-2rem))]` ou responsive.

4. **Badge compteur 0** — Ne pas afficher le badge quand `unreadCount === 0`. Condition `{unreadCount > 0 && <badge />}`.

5. **shadcn v4 utilise base-ui** — Pas Radix. Le Popover est `@base-ui/react` Popover. Vérifier les imports et props (pas `asChild` mais `render` prop si nécessaire).

## Code Examples

### Migration Alembic

```python
# alembic/versions/XXX_add_notifications.py
def upgrade() -> None:
    op.create_table(
        "notifications",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("commande_id", sa.Uuid(), sa.ForeignKey("commandes.id"), nullable=False),
        sa.Column("type", sa.String(30), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("read", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(
        "ix_notifications_user_unread",
        "notifications",
        ["user_id", "read", sa.text("created_at DESC")],
    )

def downgrade() -> None:
    op.drop_table("notifications")
```

### Schema Pydantic

```python
# apps/api/app/notifications/schemas.py
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel

class NotificationResponse(BaseModel):
    id: UUID
    commande_id: UUID
    type: str
    message: str
    read: bool
    created_at: datetime

class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
    unread_count: int
```

### Router FastAPI

```python
# apps/api/app/notifications/router.py
router = APIRouter()

@router.get("/")
async def list_notifications(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> NotificationListResponse:
    # 20 dernières
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(20)
    )
    notifications = result.scalars().all()

    # Count unread
    count_result = await db.execute(
        select(func.count())
        .select_from(Notification)
        .where(Notification.user_id == current_user.id, Notification.read == False)
    )
    unread_count = count_result.scalar()

    return NotificationListResponse(
        notifications=[NotificationResponse.model_validate(n, from_attributes=True) for n in notifications],
        unread_count=unread_count,
    )

@router.patch("/{notification_id}/read")
async def mark_read(
    notification_id: UUID,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    result = await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
    )
    notification = result.scalar_one_or_none()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    notification.read = True
    await db.commit()
    return {"ok": True}

@router.patch("/read-all")
async def mark_all_read(
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> dict:
    from sqlalchemy import update
    await db.execute(
        update(Notification)
        .where(Notification.user_id == current_user.id, Notification.read == False)
        .values(read=True)
    )
    await db.commit()
    return {"ok": True}
```

## Verification Checklist

- [ ] Migration crée la table `notifications` avec index
- [ ] `transition_order` crée une notification pour les 4 statuts
- [ ] GET /notifications retourne les 20 dernières + unread_count
- [ ] PATCH /notifications/{id}/read marque comme lu (vérifie ownership)
- [ ] PATCH /notifications/read-all marque toutes les notifs du user
- [ ] Cloche visible dans le header avec badge compteur
- [ ] Clic sur notif = marque lu + redirect vers /commandes/{id}
- [ ] Badge disparaît quand unreadCount = 0
- [ ] Panneau vide affiche un empty state

---

*Phase: 90-notifications*
*Researched: 2026-03-23*
