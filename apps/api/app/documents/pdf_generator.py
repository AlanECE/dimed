import io
from pathlib import Path

import barcode
from barcode.writer import ImageWriter
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Image, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

STORAGE_ROOT = Path(__file__).resolve().parents[3] / "storage" / "documents"


def _ensure_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def generate_facture_pdf(
    reference_id: str,
    date_emission: str,
    client_nom: str,
    client_adresse: str | None,
    commande_ref: str,
    lignes: list[dict],
    montant_total: float,
) -> Path:
    output_path = STORAGE_ROOT / "factures" / f"{reference_id}.pdf"
    _ensure_dir(output_path)

    doc = SimpleDocTemplate(str(output_path), pagesize=A4)
    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph("SPA DIMED PHARMA", styles["Title"]))
    elements.append(Paragraph("FACTURE", styles["Heading2"]))
    elements.append(Spacer(1, 0.5 * cm))

    info_data = [
        ["N° Facture:", reference_id],
        ["Date:", date_emission],
        ["Commande:", commande_ref],
        ["Client:", client_nom],
    ]
    if client_adresse:
        info_data.append(["Adresse:", client_adresse])

    info_table = Table(info_data, colWidths=[4 * cm, 12 * cm])
    info_table.setStyle(TableStyle([("FONTSIZE", (0, 0), (-1, -1), 10)]))
    elements.append(info_table)
    elements.append(Spacer(1, 1 * cm))

    table_data = [["Désignation", "Qté", "Prix unit. (DA)", "Total (DA)"]]
    for ligne in lignes:
        table_data.append(
            [
                ligne["designation"],
                str(ligne["qte"]),
                f"{ligne['prix_unitaire']:.2f}",
                f"{ligne['total']:.2f}",
            ]
        )
    table_data.append(["", "", "TOTAL:", f"{montant_total:.2f}"])

    t = Table(table_data, colWidths=[8 * cm, 2 * cm, 3 * cm, 3 * cm])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.black),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
            ]
        )
    )
    elements.append(t)

    doc.build(elements)
    return output_path


def generate_bl_pdf(
    reference_id: str,
    code_barre: str,
    date_emission: str,
    client_nom: str,
    commande_ref: str,
    lignes: list[dict],
) -> Path:
    output_path = STORAGE_ROOT / "bls" / f"{reference_id}.pdf"
    _ensure_dir(output_path)

    doc = SimpleDocTemplate(str(output_path), pagesize=A4)
    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph("SPA DIMED PHARMA", styles["Title"]))
    elements.append(Paragraph("BON DE LIVRAISON", styles["Heading2"]))
    elements.append(Spacer(1, 0.5 * cm))

    # Generate barcode image
    code128 = barcode.get("code128", code_barre, writer=ImageWriter())
    barcode_buffer = io.BytesIO()
    code128.write(barcode_buffer)
    barcode_buffer.seek(0)
    barcode_img = Image(barcode_buffer, width=10 * cm, height=2.5 * cm)
    elements.append(barcode_img)
    elements.append(Spacer(1, 0.5 * cm))

    info_data = [
        ["N° BL:", reference_id],
        ["Date:", date_emission],
        ["Commande:", commande_ref],
        ["Client:", client_nom],
    ]
    info_table = Table(info_data, colWidths=[4 * cm, 12 * cm])
    info_table.setStyle(TableStyle([("FONTSIZE", (0, 0), (-1, -1), 10)]))
    elements.append(info_table)
    elements.append(Spacer(1, 1 * cm))

    table_data = [["Désignation", "Qté"]]
    for ligne in lignes:
        table_data.append([ligne["designation"], str(ligne["qte"])])

    t = Table(table_data, colWidths=[12 * cm, 4 * cm])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.black),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
            ]
        )
    )
    elements.append(t)

    doc.build(elements)
    return output_path
