import logging
from collections.abc import Iterable
from datetime import UTC, date, datetime
from decimal import Decimal
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.arrivages.dlc import format_dlc, resolve_dlc
from app.documents.pdf_generator import generate_bl_pdf, generate_facture_pdf
from app.models.commande import Commande, LigneCommande, OrderStatus
from app.models.creance import Creance, CreanceStatut
from app.models.document import BonDeLivraison, Facture, FeuilleDeRoute
from app.models.medicament import Medicament
from app.models.references import next_bl_ref, next_facture_ref
from app.models.user import User

logger = logging.getLogger(__name__)


async def _load_commande_pdf_context(
    db: AsyncSession, commande: Commande
) -> tuple[User | None, list[dict]]:
    """Fetch pharmacien + enriched line data (code, lot, dlc, price) for PDFs.

    Always queries lignes explicitly — never touches commande.lignes relation
    to avoid MissingGreenlet errors on async sessions.
    """
    user_result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = user_result.scalar_one_or_none()

    lines_result = await db.execute(
        select(LigneCommande)
        .where(LigneCommande.commande_id == commande.id)
        .order_by(LigneCommande.id)
    )
    commande_lines = list(lines_result.scalars().all())

    medicament_ids = [ln.medicament_id for ln in commande_lines]
    med_by_id: dict = {}
    if medicament_ids:
        med_result = await db.execute(
            select(
                Medicament.id, Medicament.code_article, Medicament.ppa, Medicament.taux_tva
            ).where(Medicament.id.in_(medicament_ids))
        )
        med_by_id = {
            row.id: {
                "code": row.code_article,
                "ppa": float(row.ppa),
                "taux_tva": float(row.taux_tva or 0),
            }
            for row in med_result
        }

    dlc_by_key, latest_dlc_by_med = await resolve_dlc(db, medicament_ids)

    lignes_data = []
    for ligne in commande_lines:
        qte = ligne.qte_prelevee if ligne.qte_prelevee is not None else ligne.qte_demandee
        remise_pct = float(ligne.remise_pct or 0)
        brut = float(ligne.prix_unitaire) * float(qte)
        net = brut * (1 - remise_pct / 100)
        med_info = med_by_id.get(ligne.medicament_id, {})
        dlc_str = format_dlc(dlc_by_key, latest_dlc_by_med, ligne.medicament_id, ligne.n_lot)
        lignes_data.append(
            {
                "code": med_info.get("code", ""),
                "designation": ligne.designation,
                "qte": qte,
                "lot": ligne.n_lot or "",
                "dlc": dlc_str,
                "exp": dlc_str,
                "ppa": med_info.get("ppa", float(ligne.prix_unitaire)),
                "prix_unitaire": float(ligne.prix_unitaire),
                "remise_pct": remise_pct,
                "taux_tva": med_info.get("taux_tva", 0.0),
                "total": net,
            }
        )
    return pharmacien, lignes_data


def _montant_tva(lignes_data: list[dict]) -> Decimal:
    total = sum(
        Decimal(str(ln["total"])) * Decimal(str(ln.get("taux_tva", 0))) / Decimal("100")
        for ln in lignes_data
    )
    return Decimal(total).quantize(Decimal("0.01"))


def _render_facture_pdf(
    facture: Facture,
    commande: Commande,
    pharmacien: User | None,
    lignes_data: list[dict],
    bl_ref: str | None,
) -> None:
    generate_facture_pdf(
        reference_id=facture.reference_id,
        date_emission=facture.date_emission.strftime("%d/%m/%Y"),
        client_nom=pharmacien.nom if pharmacien else "N/A",
        client_adresse=pharmacien.adresse if pharmacien else None,
        client_telephone=pharmacien.telephone if pharmacien else None,
        client_secteur=pharmacien.secteur if pharmacien else None,
        commercial=commande.commercial,
        commande_ref=commande.reference_id,
        prelevement_ref=bl_ref,
        lignes=lignes_data,
        montant_total=float(commande.montant_total),
        visa_preparateur=commande.visa_preparateur,
        visa_controleur=commande.visa_controleur,
        # Une Facture n'existe qu'après validation par l'opératrice : c'est un
        # document définitif. La proforma est un document distinct, générée à
        # la volée via generate_proforma_pdf.
        is_proforma=False,
    )


async def generate_proforma_pdf(db: AsyncSession, commande: Commande) -> Path:
    """Render an on-the-fly FACTURE PROFORMA for a commande (never persisted).

    The proforma reflects the current state of the order lines and is
    available at any stage of the workflow, unlike the facture which only
    exists once the opératrice has validated the order.
    """
    pharmacien, lignes_data = await _load_commande_pdf_context(db, commande)

    bl_result = await db.execute(
        select(BonDeLivraison.code_barre).where(BonDeLivraison.commande_id == commande.id)
    )
    bl_ref = bl_result.scalar_one_or_none()

    return generate_facture_pdf(
        reference_id=f"PRO-{commande.reference_id}",
        date_emission=datetime.now(UTC).strftime("%d/%m/%Y"),
        client_nom=pharmacien.nom if pharmacien else "N/A",
        client_adresse=pharmacien.adresse if pharmacien else None,
        client_telephone=pharmacien.telephone if pharmacien else None,
        client_secteur=pharmacien.secteur if pharmacien else None,
        commercial=commande.commercial,
        commande_ref=commande.reference_id,
        prelevement_ref=bl_ref,
        lignes=lignes_data,
        montant_total=float(commande.montant_total),
        is_proforma=True,
    )


async def generate_order_documents(
    db: AsyncSession, commande: Commande
) -> tuple[Facture, BonDeLivraison]:
    pharmacien, lignes_data = await _load_commande_pdf_context(db, commande)

    facture_ref = await next_facture_ref(db)
    bl_ref = await next_bl_ref(db)
    now = datetime.now(UTC)

    montant_tva = _montant_tva(lignes_data)
    facture = Facture(
        id=uuid4(),
        reference_id=facture_ref,
        commande_id=commande.id,
        date_emission=now,
        montant_ht=commande.montant_total,
        montant_ttc=commande.montant_total + montant_tva,
    )
    db.add(facture)
    await db.flush()  # ensure facture row exists before creance FK references it

    # Create the corresponding créance (payment tracking), due in 30 days
    creance = Creance(
        id=uuid4(),
        pharmacien_id=commande.pharmacien_id,
        facture_id=facture.id,
        montant_total=commande.montant_total,
        montant_paye=Decimal("0"),
        statut=CreanceStatut.EN_ATTENTE,
        echeance=date.fromtimestamp(now.timestamp() + 30 * 86400),
    )
    db.add(creance)

    bl = BonDeLivraison(
        id=uuid4(),
        commande_id=commande.id,
        code_barre=bl_ref,
        date_emission=now,
    )
    db.add(bl)

    _render_facture_pdf(facture, commande, pharmacien, lignes_data, bl_ref)

    generate_bl_pdf(
        reference_id=bl_ref,
        code_barre=bl_ref,
        date_emission=now.strftime("%d/%m/%Y"),
        client_nom=pharmacien.nom if pharmacien else "N/A",
        commande_ref=commande.reference_id,
        lignes=lignes_data,
    )

    return facture, bl


async def regenerate_facture_pdf(
    db: AsyncSession,
    facture: Facture,
    remises: dict[UUID, Decimal] | None = None,
) -> None:
    """Rebuild a facture PDF from DB state.

    If `remises` is provided (ligne_id -> percentage), persist the new
    remise_pct on each matching LigneCommande, recompute Facture montants,
    then regenerate the PDF. Used by both lazy regen and the explicit
    "update remises" endpoint.
    """
    cmd_result = await db.execute(select(Commande).where(Commande.id == facture.commande_id))
    commande = cmd_result.scalar_one_or_none()
    if not commande:
        return

    if remises:
        lines_result = await db.execute(
            select(LigneCommande).where(LigneCommande.commande_id == commande.id)
        )
        lines = list(lines_result.scalars().all())
        for ligne in lines:
            if ligne.id in remises:
                ligne.remise_pct = remises[ligne.id]

        net_total = Decimal("0.00")
        for ligne in lines:
            qte = ligne.qte_prelevee if ligne.qte_prelevee is not None else ligne.qte_demandee
            brut = ligne.prix_unitaire * Decimal(qte)
            net = brut * (Decimal("1") - (ligne.remise_pct / Decimal("100")))
            net_total += net.quantize(Decimal("0.01"))

        facture.montant_ht = net_total
        facture.montant_ttc = net_total
        commande.montant_total = net_total
        await db.flush()

    bl_result = await db.execute(
        select(BonDeLivraison.code_barre).where(BonDeLivraison.commande_id == commande.id)
    )
    bl_ref = bl_result.scalar_one_or_none()

    pharmacien, lignes_data = await _load_commande_pdf_context(db, commande)
    facture.montant_ttc = facture.montant_ht + _montant_tva(lignes_data)
    _render_facture_pdf(facture, commande, pharmacien, lignes_data, bl_ref)


def _normalize_sheet_date(target: date | datetime) -> date:
    return target.date() if isinstance(target, datetime) else target


async def _find_route_sheet(
    db: AsyncSession,
    camion_id: UUID,
    target_date: date,
) -> FeuilleDeRoute | None:
    result = await db.execute(
        select(FeuilleDeRoute).where(
            FeuilleDeRoute.camion_id == camion_id,
            FeuilleDeRoute.date == target_date,
        )
    )
    return result.scalar_one_or_none()


async def _insert_route_sheet(
    db: AsyncSession,
    camion_id: UUID,
    target_date: date,
) -> FeuilleDeRoute:
    feuille = FeuilleDeRoute(
        id=uuid4(),
        camion_id=camion_id,
        date=target_date,
        compteurs={"colis_std": 0, "sachets_std": 0, "colis_frg": 0, "sachets_frg": 0},
    )
    try:
        async with db.begin_nested():
            db.add(feuille)
            await db.flush()
    except IntegrityError:
        logger.warning(
            "Route sheet creation raced for camion=%s date=%s; reloading existing row",
            camion_id,
            target_date,
        )
        existing = await _find_route_sheet(db, camion_id, target_date)
        if existing:
            return existing
        raise
    return feuille


async def create_route_sheet(
    db: AsyncSession, camion_id: UUID, target: date | datetime
) -> FeuilleDeRoute:
    sheet_date = _normalize_sheet_date(target)
    existing = await _find_route_sheet(db, camion_id, sheet_date)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Route sheet already exists for truck {camion_id} on {sheet_date}",
        )

    try:
        return await _insert_route_sheet(db, camion_id, sheet_date)
    except IntegrityError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Route sheet already exists for truck {camion_id} on {sheet_date}",
        ) from exc


async def get_or_create_route_sheet(
    db: AsyncSession, camion_id: UUID, target_date: date
) -> FeuilleDeRoute:
    normalized_date = _normalize_sheet_date(target_date)
    feuille = await _find_route_sheet(db, camion_id, normalized_date)
    if feuille:
        return feuille
    try:
        return await _insert_route_sheet(db, camion_id, normalized_date)
    except IntegrityError as exc:
        logger.exception(
            "Unable to get or create route sheet for camion=%s date=%s",
            camion_id,
            normalized_date,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to create route sheet",
        ) from exc


async def get_route_sheet_orders(
    db: AsyncSession,
    feuille: FeuilleDeRoute,
    statuses: Iterable[OrderStatus] | None = None,
) -> list[Commande]:
    query = select(Commande).where(Commande.feuille_route_id == feuille.id)
    if statuses is not None:
        query = query.where(Commande.statut.in_(list(statuses)))
    query = query.order_by(Commande.created_at.asc())
    result = await db.execute(query)
    return result.scalars().all()


async def get_route_sheet(db: AsyncSession, feuille_id: UUID) -> FeuilleDeRoute | None:
    result = await db.execute(select(FeuilleDeRoute).where(FeuilleDeRoute.id == feuille_id))
    return result.scalar_one_or_none()
