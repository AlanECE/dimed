from uuid import UUID, uuid4

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.colis import Colis, ColisLigne, ColisStatus, PadTir, ScanColis, ScanType
from app.models.commande import Commande, LigneCommande, OrderStatus
from app.models.document import FeuilleDeRoute
from app.models.references import next_colis_ref
from app.models.user import User


async def create_colis_for_commande(
    db: AsyncSession, commande: Commande, nb_colis: int
) -> list[Colis]:
    """Create nb_colis tracked parcels (with unique QR numbers) for an order."""
    existing = await db.execute(
        select(func.count()).select_from(Colis).where(Colis.commande_id == commande.id)
    )
    if (existing.scalar() or 0) > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Des colis existent déjà pour la commande {commande.reference_id}",
        )

    colis_list: list[Colis] = []
    for index in range(1, nb_colis + 1):
        numero = await next_colis_ref(db)
        colis = Colis(
            id=uuid4(),
            numero=numero,
            commande_id=commande.id,
            index_colis=index,
            statut=ColisStatus.ETIQUETE,
        )
        db.add(colis)
        colis_list.append(colis)
    await db.flush()
    return colis_list


async def get_colis_by_numero(db: AsyncSession, numero: str) -> Colis | None:
    result = await db.execute(
        select(Colis)
        .where(Colis.numero == numero.strip().upper())
        .options(
            selectinload(Colis.lignes).selectinload(ColisLigne.ligne_commande),
            selectinload(Colis.pad_tir),
            selectinload(Colis.commande).selectinload(Commande.lignes),
        )
    )
    return result.scalar_one_or_none()


async def get_commande_colis(db: AsyncSession, commande_id: UUID) -> list[Colis]:
    result = await db.execute(
        select(Colis)
        .where(Colis.commande_id == commande_id)
        .options(selectinload(Colis.lignes).selectinload(ColisLigne.ligne_commande))
        .order_by(Colis.index_colis.asc())
    )
    return list(result.scalars().all())


async def suggest_pad(db: AsyncSession, colis: Colis) -> tuple[PadTir | None, bool]:
    """Suggest a pad de tir for a parcel.

    Rule: if another parcel of the same order is already on a pad, that pad is
    imposed (all parcels of an order must be grouped). Otherwise suggest the
    active pad with the fewest parcels currently staged.
    """
    sibling_result = await db.execute(
        select(Colis)
        .where(
            Colis.commande_id == colis.commande_id,
            Colis.id != colis.id,
            Colis.statut == ColisStatus.SUR_PAD,
            Colis.pad_tir_id.is_not(None),
        )
        .options(selectinload(Colis.pad_tir))
        .limit(1)
    )
    sibling = sibling_result.scalar_one_or_none()
    if sibling and sibling.pad_tir:
        return sibling.pad_tir, True

    occupation = (
        select(Colis.pad_tir_id, func.count().label("nb"))
        .where(Colis.statut == ColisStatus.SUR_PAD, Colis.pad_tir_id.is_not(None))
        .group_by(Colis.pad_tir_id)
        .subquery()
    )
    result = await db.execute(
        select(PadTir)
        .outerjoin(occupation, occupation.c.pad_tir_id == PadTir.id)
        .where(PadTir.actif.is_(True))
        .order_by(func.coalesce(occupation.c.nb, 0).asc(), PadTir.code.asc())
        .limit(1)
    )
    pad = result.scalar_one_or_none()
    return pad, False


async def log_scan(
    db: AsyncSession,
    colis: Colis,
    type_scan: ScanType,
    user_id: UUID,
    pad_tir_id: UUID | None = None,
) -> None:
    db.add(
        ScanColis(
            id=uuid4(),
            colis_id=colis.id,
            type_scan=type_scan,
            user_id=user_id,
            pad_tir_id=pad_tir_id,
        )
    )
    await db.flush()


def colis_contenu(colis: Colis) -> tuple[list[dict], bool]:
    """Parcel contents: explicit colis_lignes split if any, else full order lines."""
    if colis.lignes:
        return (
            [
                {
                    "designation": cl.ligne_commande.designation,
                    "quantite": cl.quantite,
                }
                for cl in colis.lignes
            ],
            True,
        )
    commande = colis.commande
    lignes = commande.lignes if commande and "lignes" in commande.__dict__ else []
    return (
        [
            {
                "designation": ln.designation,
                # qte_prelevee peut être 0/None si non renseignée → on retombe
                # sur la quantité demandée pour ne jamais afficher 0.
                "quantite": ln.qte_prelevee or ln.qte_demandee,
            }
            for ln in lignes
        ],
        False,
    )


async def chargement_state(db: AsyncSession, feuille: FeuilleDeRoute) -> dict:
    """Real-time truck loading state, per order, for the route sheet."""
    result = await db.execute(
        select(Commande)
        .where(
            Commande.feuille_route_id == feuille.id,
            Commande.statut.in_([OrderStatus.PRETE, OrderStatus.EN_ROUTE]),
        )
        .order_by(Commande.created_at.asc())
    )
    commandes = list(result.scalars().all())

    pharm_ids = {c.pharmacien_id for c in commandes}
    users_map: dict[UUID, User] = {}
    if pharm_ids:
        users_result = await db.execute(select(User).where(User.id.in_(pharm_ids)))
        users_map = {u.id: u for u in users_result.scalars().all()}

    colis_map: dict[UUID, list[Colis]] = {}
    if commandes:
        colis_result = await db.execute(
            select(Colis)
            .where(Colis.commande_id.in_([c.id for c in commandes]))
            .order_by(Colis.index_colis.asc())
        )
        for colis in colis_result.scalars().all():
            colis_map.setdefault(colis.commande_id, []).append(colis)

    items = []
    total = 0
    charges = 0
    for c in commandes:
        cl = colis_map.get(c.id, [])
        loaded = [k for k in cl if k.statut in (ColisStatus.CHARGE, ColisStatus.LIVRE)]
        total += len(cl)
        charges += len(loaded)
        pharm = users_map.get(c.pharmacien_id)
        items.append(
            {
                "commande_id": str(c.id),
                "commande_ref": c.reference_id,
                "pharmacien_nom": pharm.nom if pharm else "—",
                "statut": c.statut.value,
                "total": len(cl),
                "charges": len(loaded),
                "colis": [
                    {
                        "numero": k.numero,
                        "index_colis": k.index_colis,
                        "statut": k.statut.value,
                    }
                    for k in cl
                ],
            }
        )

    return {
        "feuille_id": str(feuille.id),
        "total": total,
        "charges": charges,
        "commandes": items,
    }


async def validate_repartition(
    db: AsyncSession, commande: Commande, repartition: list
) -> dict[UUID, LigneCommande]:
    """Validate a content split: parcels and lines must belong to the order,
    and the summed quantity per line must not exceed the picked quantity."""
    colis_list = await get_commande_colis(db, commande.id)
    colis_ids = {k.id for k in colis_list}
    lignes_map = {ln.id: ln for ln in commande.lignes}

    totals: dict[UUID, int] = {}
    for item in repartition:
        if item.colis_id not in colis_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Colis {item.colis_id} n'appartient pas à cette commande",
            )
        for ligne_item in item.lignes:
            ligne = lignes_map.get(ligne_item.ligne_id)
            if ligne is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Ligne {ligne_item.ligne_id} n'appartient pas à cette commande",
                )
            totals[ligne.id] = totals.get(ligne.id, 0) + ligne_item.quantite

    for ligne_id, qty in totals.items():
        ligne = lignes_map[ligne_id]
        max_qty = ligne.qte_prelevee if ligne.qte_prelevee is not None else ligne.qte_demandee
        if qty > max_qty:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Quantité répartie ({qty}) supérieure à la quantité prélevée "
                    f"({max_qty}) pour {ligne.designation}"
                ),
            )
    return lignes_map
