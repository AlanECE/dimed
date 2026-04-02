from app.models.commande import OrderStatus

VALID_TRANSITIONS: dict[OrderStatus, list[OrderStatus]] = {
    OrderStatus.CREEE: [OrderStatus.ACCEPTEE, OrderStatus.ANNULEE],
    OrderStatus.ACCEPTEE: [OrderStatus.EN_PREPARATION],
    OrderStatus.EN_PREPARATION: [
        OrderStatus.PRELEVEE_PARTIELLEMENT,
        OrderStatus.EN_VERIFICATION,
    ],
    OrderStatus.PRELEVEE_PARTIELLEMENT: [OrderStatus.EN_VERIFICATION],
    OrderStatus.EN_VERIFICATION: [OrderStatus.PRETE, OrderStatus.EN_PREPARATION],
    OrderStatus.PRETE: [OrderStatus.EN_ROUTE],
    OrderStatus.EN_ROUTE: [
        OrderStatus.LIVREE,
        OrderStatus.REFUSEE,
        OrderStatus.RETOURNEE,
        OrderStatus.LIVREE_PARTIELLEMENT,
    ],
}


def validate_transition(current: OrderStatus, target: OrderStatus) -> None:
    """Validate that a state transition is allowed. Raises ValueError if not."""
    allowed = VALID_TRANSITIONS.get(current, [])
    if target not in allowed:
        raise ValueError(
            f"Invalid transition: {current.value} → {target.value}. "
            f"Allowed: {[s.value for s in allowed]}"
        )
