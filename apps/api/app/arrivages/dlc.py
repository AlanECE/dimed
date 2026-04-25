"""Shared DLC (date de péremption) resolution from arrivages."""

from __future__ import annotations

from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.arrivage import Arrivage


async def resolve_dlc(
    db: AsyncSession, medicament_ids: list[UUID]
) -> tuple[dict[tuple[UUID, str], date | None], dict[UUID, tuple[date, date | None]]]:
    """Query arrivages and return lookup dicts for DLC resolution.

    Returns (dlc_by_key, latest_dlc_by_med):
      - dlc_by_key: (medicament_id, n_lot) → date_peremption
      - latest_dlc_by_med: medicament_id → (date_arrivage, date_peremption) for the most recent
    """
    dlc_by_key: dict[tuple[UUID, str], date | None] = {}
    latest_dlc_by_med: dict[UUID, tuple[date, date | None]] = {}
    if not medicament_ids:
        return dlc_by_key, latest_dlc_by_med

    arr_result = await db.execute(
        select(
            Arrivage.medicament_id,
            Arrivage.n_lot,
            Arrivage.date_peremption,
            Arrivage.date_arrivage,
        ).where(Arrivage.medicament_id.in_(medicament_ids))
    )
    for row in arr_result:
        if row.n_lot:
            dlc_by_key[(row.medicament_id, row.n_lot)] = row.date_peremption
        existing = latest_dlc_by_med.get(row.medicament_id)
        if existing is None or row.date_arrivage > existing[0]:
            latest_dlc_by_med[row.medicament_id] = (row.date_arrivage, row.date_peremption)

    return dlc_by_key, latest_dlc_by_med


def format_dlc(
    dlc_by_key: dict[tuple[UUID, str], date | None],
    latest_dlc_by_med: dict[UUID, tuple[date, date | None]],
    medicament_id: UUID,
    n_lot: str | None,
) -> str:
    """Return 'MM/YYYY' for the best-matching DLC, or empty string."""
    if n_lot:
        dlc = dlc_by_key.get((medicament_id, n_lot))
        if dlc:
            return dlc.strftime("%m/%Y")
    fallback = latest_dlc_by_med.get(medicament_id)
    if fallback and fallback[1]:
        return fallback[1].strftime("%m/%Y")
    return ""
