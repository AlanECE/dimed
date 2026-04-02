from collections.abc import Iterable
from datetime import UTC, date, datetime
from uuid import UUID, uuid4

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.documents.pdf_generator import generate_bl_pdf, generate_facture_pdf
from app.models.commande import Commande, OrderStatus
from app.models.document import BonDeLivraison, Facture, FeuilleDeRoute
from app.models.references import next_bl_ref, next_facture_ref
from app.models.user import User


async def generate_order_documents(
    db: AsyncSession, commande: Commande
) -> tuple[Facture, BonDeLivraison]:
    # Fetch pharmacien info
    result = await db.execute(select(User).where(User.id == commande.pharmacien_id))
    pharmacien = result.scalar_one_or_none()

    facture_ref = await next_facture_ref(db)
    bl_ref = await next_bl_ref(db)
    now = datetime.now(UTC)

    # Prepare line data for PDF
    lignes_data = [
        {
            "designation": ligne.designation,
            "qte": ligne.qte_demandee,
            "prix_unitaire": float(ligne.prix_unitaire),
            "total": float(ligne.prix_unitaire * ligne.qte_demandee),
        }
        for ligne in commande.lignes
    ]

    # Create Facture record
    facture = Facture(
        id=uuid4(),
        reference_id=facture_ref,
        commande_id=commande.id,
        date_emission=now,
        montant_ht=commande.montant_total,
        montant_ttc=commande.montant_total,  # no tax in v1
    )
    db.add(facture)

    # Create BL record
    bl = BonDeLivraison(
        id=uuid4(),
        commande_id=commande.id,
        code_barre=bl_ref,
        date_emission=now,
    )
    db.add(bl)

    # Generate PDFs
    generate_facture_pdf(
        reference_id=facture_ref,
        date_emission=now.strftime("%d/%m/%Y"),
        client_nom=pharmacien.nom if pharmacien else "N/A",
        client_adresse=pharmacien.adresse if pharmacien else None,
        commande_ref=commande.reference_id,
        lignes=lignes_data,
        montant_total=float(commande.montant_total),
    )

    generate_bl_pdf(
        reference_id=bl_ref,
        code_barre=bl_ref,
        date_emission=now.strftime("%d/%m/%Y"),
        client_nom=pharmacien.nom if pharmacien else "N/A",
        commande_ref=commande.reference_id,
        lignes=lignes_data,
    )

    return facture, bl


async def create_route_sheet(db: AsyncSession, camion_id: UUID, date: datetime) -> FeuilleDeRoute:
    # Normalize to date object
    sheet_date = date.date() if isinstance(date, datetime) else date

    # Check no duplicate active sheet (RG-1-05)
    result = await db.execute(
        select(FeuilleDeRoute).where(
            FeuilleDeRoute.camion_id == camion_id,
            FeuilleDeRoute.date == sheet_date,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Route sheet already exists for truck {camion_id} on {sheet_date}",
        )

    feuille = FeuilleDeRoute(
        id=uuid4(),
        camion_id=camion_id,
        date=sheet_date,
        compteurs={"colis_std": 0, "sachets_std": 0, "colis_frg": 0, "sachets_frg": 0},
    )
    db.add(feuille)
    return feuille


async def get_or_create_route_sheet(
    db: AsyncSession, camion_id: UUID, target_date: date
) -> FeuilleDeRoute:
    result = await db.execute(
        select(FeuilleDeRoute).where(
            FeuilleDeRoute.camion_id == camion_id,
            FeuilleDeRoute.date == target_date,
        )
    )
    feuille = result.scalar_one_or_none()
    if feuille:
        return feuille
    return await create_route_sheet(db, camion_id, target_date)


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
