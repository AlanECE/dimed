import io
from datetime import UTC, datetime
from pathlib import Path

import barcode
from barcode.writer import ImageWriter
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    Image,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

STORAGE_ROOT = Path(__file__).resolve().parents[3] / "storage" / "documents"

# -- DIMED corporate colors --
DIMED_BLUE = colors.HexColor("#1a5276")
DIMED_LIGHT = colors.HexColor("#d6eaf8")
DIMED_GREY = colors.HexColor("#f2f3f4")
HEADER_BG = colors.HexColor("#2c3e50")


def _ensure_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def _dimed_header() -> list:
    """Standard DIMED header block."""
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "DimedTitle",
        parent=styles["Normal"],
        fontSize=11,
        fontName="Helvetica-Bold",
        textColor=DIMED_BLUE,
    )
    sub_style = ParagraphStyle(
        "DimedSub",
        parent=styles["Normal"],
        fontSize=7,
        textColor=colors.grey,
    )
    return [
        Paragraph("SPA DIMED PHARMA", title_style),
        Paragraph(
            "Distribution Pharmaceutique — Zone Industrielle, Oued Smar, Alger",
            sub_style,
        ),
        Paragraph(
            "Email: dimed.pharma@dimed.dz | Tél: 023 XX XX XX",
            sub_style,
        ),
    ]


# ================================================================
# FACTURE
# ================================================================


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

    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        leftMargin=1.5 * cm,
        rightMargin=1.5 * cm,
        topMargin=1 * cm,
        bottomMargin=1 * cm,
    )
    styles = getSampleStyleSheet()
    elements: list = []

    for el in _dimed_header():
        elements.append(el)
    elements.append(Spacer(1, 0.5 * cm))

    # Title
    elements.append(
        Paragraph(
            "FACTURE",
            ParagraphStyle(
                "FTitle",
                parent=styles["Heading1"],
                fontSize=16,
                alignment=1,
                textColor=DIMED_BLUE,
            ),
        )
    )
    elements.append(Spacer(1, 0.5 * cm))

    # Info block
    info_data = [
        ["N° Facture:", reference_id, "Date:", date_emission],
        ["Commande:", commande_ref, "Client:", client_nom],
    ]
    if client_adresse:
        info_data.append(["Adresse:", client_adresse, "", ""])

    info_t = Table(
        info_data,
        colWidths=[3 * cm, 5.5 * cm, 3 * cm, 5.5 * cm],
    )
    info_t.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    elements.append(info_t)
    elements.append(Spacer(1, 0.8 * cm))

    # Lines table
    tbl_data = [["N°", "Désignation", "Qté", "PU (DA)", "Total (DA)"]]
    for i, ln in enumerate(lignes, 1):
        tbl_data.append(
            [
                str(i),
                ln["designation"],
                str(ln["qte"]),
                f"{ln['prix_unitaire']:.2f}",
                f"{ln['total']:.2f}",
            ]
        )
    tbl_data.append(["", "", "", "TOTAL:", f"{montant_total:.2f}"])

    t = Table(
        tbl_data,
        colWidths=[1 * cm, 8 * cm, 1.5 * cm, 3 * cm, 3.5 * cm],
    )
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, 0), 8),
                ("FONTSIZE", (0, 1), (-1, -1), 8),
                ("GRID", (0, 0), (-1, -2), 0.5, colors.Color(0.8, 0.8, 0.8)),
                ("LINEABOVE", (0, -1), (-1, -1), 1, DIMED_BLUE),
                ("FONTNAME", (3, -1), (-1, -1), "Helvetica-Bold"),
                ("ALIGN", (0, 0), (0, -1), "CENTER"),
                ("ALIGN", (2, 0), (-1, -1), "RIGHT"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, DIMED_GREY]),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    elements.append(t)

    # Footer
    elements.append(Spacer(1, 2 * cm))
    footer_data = [
        ["Cachet & Signature:", "", "Le Client:"],
    ]
    ft = Table(footer_data, colWidths=[6 * cm, 5 * cm, 6 * cm])
    ft.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
            ]
        )
    )
    elements.append(ft)

    doc.build(elements)
    return output_path


# ================================================================
# BON DE LIVRAISON
# ================================================================


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

    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        leftMargin=1.5 * cm,
        rightMargin=1.5 * cm,
        topMargin=1 * cm,
        bottomMargin=1 * cm,
    )
    styles = getSampleStyleSheet()
    elements: list = []

    for el in _dimed_header():
        elements.append(el)
    elements.append(Spacer(1, 0.3 * cm))

    elements.append(
        Paragraph(
            "BON DE LIVRAISON",
            ParagraphStyle(
                "BLTitle",
                parent=styles["Heading1"],
                fontSize=16,
                alignment=1,
                textColor=DIMED_BLUE,
            ),
        )
    )
    elements.append(Spacer(1, 0.3 * cm))

    # Barcode
    code128 = barcode.get("code128", code_barre, writer=ImageWriter())
    buf = io.BytesIO()
    code128.write(buf)
    buf.seek(0)
    elements.append(Image(buf, width=8 * cm, height=2 * cm))
    elements.append(Spacer(1, 0.3 * cm))

    # Info
    info_data = [
        ["N° BL:", reference_id, "Date:", date_emission],
        ["Commande:", commande_ref, "Client:", client_nom],
    ]
    info_t = Table(
        info_data,
        colWidths=[3 * cm, 5.5 * cm, 3 * cm, 5.5 * cm],
    )
    info_t.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
            ]
        )
    )
    elements.append(info_t)
    elements.append(Spacer(1, 0.6 * cm))

    # Lines
    tbl_data = [["N°", "Désignation", "Qté"]]
    for i, ln in enumerate(lignes, 1):
        tbl_data.append([str(i), ln["designation"], str(ln["qte"])])

    t = Table(tbl_data, colWidths=[1 * cm, 13 * cm, 3 * cm])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.Color(0.8, 0.8, 0.8)),
                ("ALIGN", (0, 0), (0, -1), "CENTER"),
                ("ALIGN", (2, 0), (2, -1), "RIGHT"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, DIMED_GREY]),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    elements.append(t)

    elements.append(Spacer(1, 2 * cm))
    sig_data = [["Cachet Expédition:", "", "Signature Chauffeur:"]]
    st = Table(sig_data, colWidths=[6 * cm, 5 * cm, 6 * cm])
    st.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
            ]
        )
    )
    elements.append(st)

    doc.build(elements)
    return output_path


# ================================================================
# FEUILLE DE ROUTE (format DIMED réel)
# ================================================================


def generate_feuille_route_pdf(
    date_str: str,
    camion_nom: str,
    camion_plaque: str,
    ligne: str | None,
    commandes: list[dict],
    compteurs: dict,
) -> Path:
    """Generate route sheet PDF matching real DIMED format.

    commandes: list of {
        client, commande_ref, facture_ref, n_prelv,
        c_std, sc_std, bl_std_c_frg, sac_frg, check
    }
    """
    output_path = STORAGE_ROOT / "feuilles" / f"FR_{date_str}_{camion_nom}.pdf"
    _ensure_dir(output_path)

    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=landscape(A4),
        leftMargin=1 * cm,
        rightMargin=1 * cm,
        topMargin=0.8 * cm,
        bottomMargin=0.8 * cm,
    )
    styles = getSampleStyleSheet()
    elements: list = []

    # Header
    for el in _dimed_header():
        elements.append(el)

    now = datetime.now(UTC).strftime("%d/%m/%Y %H:%M")
    elements.append(
        Paragraph(
            f"<para align='right' fontSize='7' textColor='grey'>Page 1 | Le {now}</para>",
            styles["Normal"],
        )
    )
    elements.append(Spacer(1, 0.2 * cm))

    # Title
    elements.append(
        Paragraph(
            "Feuille de route",
            ParagraphStyle(
                "FRTitle",
                parent=styles["Heading1"],
                fontSize=18,
                alignment=1,
                textColor=DIMED_BLUE,
                underline=True,
            ),
        )
    )
    elements.append(Spacer(1, 0.3 * cm))

    # Info row
    info_data = [
        [
            "Code B/R: —",
            f"Date: {date_str}",
            f"Camion: {camion_nom} ({camion_plaque})",
            f"Ligne: {ligne or '—'}",
        ]
    ]
    info_t = Table(info_data, colWidths=[5 * cm, 5 * cm, 9 * cm, 5 * cm])
    info_t.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.black),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    elements.append(info_t)
    elements.append(Spacer(1, 0.3 * cm))

    # Main table — matching real DIMED columns
    headers = [
        "N°",
        "Client",
        "Commandes",
        "Factures",
        "N.Prélv",
        "C.Std",
        "Sc.Std",
        "Bl.Std\nC.Frg",
        "Sac.Frg",
        "Check",
    ]
    col_w = [
        0.8 * cm,
        5 * cm,
        3 * cm,
        3 * cm,
        2 * cm,
        1.5 * cm,
        1.5 * cm,
        1.8 * cm,
        1.5 * cm,
        1.5 * cm,
    ]

    tbl_data = [headers]
    for i, cmd in enumerate(commandes, 1):
        tbl_data.append(
            [
                str(i),
                cmd.get("client", "—"),
                cmd.get("commande_ref", "—"),
                cmd.get("facture_ref", "—"),
                cmd.get("n_prelv", "—"),
                str(cmd.get("c_std", "")),
                str(cmd.get("sc_std", "")),
                str(cmd.get("bl_std_c_frg", "")),
                str(cmd.get("sac_frg", "")),
                "",  # Check column (hand-filled)
            ]
        )

    # Totals row
    tbl_data.append(
        [
            "",
            "TOTAUX",
            "",
            "",
            "",
            str(compteurs.get("colis_std", 0)),
            str(compteurs.get("sachets_std", 0)),
            str(compteurs.get("colis_frg", 0)),
            str(compteurs.get("sachets_frg", 0)),
            "",
        ]
    )

    t = Table(tbl_data, colWidths=col_w)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, 0), 7),
                ("FONTSIZE", (0, 1), (-1, -1), 7),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.black),
                ("ALIGN", (0, 0), (0, -1), "CENTER"),
                ("ALIGN", (5, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, DIMED_GREY]),
                ("BACKGROUND", (0, -1), (-1, -1), DIMED_LIGHT),
                ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    elements.append(t)

    # Signatures
    elements.append(Spacer(1, 1.5 * cm))
    sig_data = [
        [
            "Chauffeur:\n\n\n_______________",
            "Chef Expédition:\n\n\n_______________",
            "Contrôle:\n\n\n_______________",
        ]
    ]
    sig_t = Table(sig_data, colWidths=[8 * cm, 8 * cm, 8 * cm])
    sig_t.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]
        )
    )
    elements.append(sig_t)

    # Footer
    elements.append(Spacer(1, 0.5 * cm))
    elements.append(
        Paragraph(
            f"<para align='right' fontSize='6' textColor='grey'>Imprimé le {now}</para>",
            styles["Normal"],
        )
    )

    doc.build(elements)
    return output_path


# ================================================================
# BON DE PRELEVEMENT / CMD (format DIMED réel)
# ================================================================


def generate_liste_prelevement_pdf(
    commande_ref: str,
    client_nom: str,
    nb_colis: int,
    lignes: list[dict],
    visa_preparateur: str | None = None,
    visa_controleur: str | None = None,
    prelevement_ref: str | None = None,
    commercial: str | None = None,
    client_adresse: str | None = None,
) -> Path:
    """Generate picking list PDF matching real DIMED CMD format."""
    output_path = STORAGE_ROOT / "prelevements" / f"PRL_{commande_ref}.pdf"
    _ensure_dir(output_path)

    now = datetime.now(UTC)
    now_str = now.strftime("%d/%m/%Y %H:%M")

    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        leftMargin=1.2 * cm,
        rightMargin=1.2 * cm,
        topMargin=0.8 * cm,
        bottomMargin=0.8 * cm,
    )
    styles = getSampleStyleSheet()
    elems: list = []

    # Header — matching CMD N° format
    elems.append(
        Paragraph(
            f"<para align='right' fontSize='7' textColor='grey'>"
            f"Page 1 sur 1 | "
            f"Prélevée Le {now_str}</para>",
            styles["Normal"],
        )
    )
    elems.append(Spacer(1, 2 * mm))

    # Big CMD title
    elems.append(
        Paragraph(
            f"<para align='center'>"
            f"<b><font size='16' color='{DIMED_BLUE}'>CMD N°: "
            f"{commande_ref}</font></b></para>",
            styles["Normal"],
        )
    )
    elems.append(Spacer(1, 2 * mm))

    if prelevement_ref:
        elems.append(
            Paragraph(
                f"<para align='center' fontSize='9'>PRÉLÈVEMENT N°: {prelevement_ref}</para>",
                styles["Normal"],
            )
        )
        elems.append(Spacer(1, 2 * mm))

    # Client info block (right side like real doc)
    client_info = [
        [
            f"Commercial: {commercial or '—'}",
            f"<b>{client_nom}</b>",
        ],
        [
            f"Nb colis: {nb_colis}",
            client_adresse or "",
        ],
    ]
    ci_t = Table(client_info, colWidths=[8 * cm, 9 * cm])
    ci_t.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("TOPPADDING", (0, 0), (-1, -1), 2),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ]
        )
    )
    elems.append(ci_t)
    elems.append(Spacer(1, 0.4 * cm))

    # Lines table — matching real CMD format
    headers = ["N°", "Désignation", "Colisage", "QTE", "PPA", "Montant"]
    tbl_data = [headers]
    total_montant = 0.0
    for i, ln in enumerate(lignes, 1):
        qte = ln.get("qte_prelevee", ln.get("qte_demandee", 0))
        pu = ln["prix_unitaire"]
        montant = qte * pu
        total_montant += montant
        tbl_data.append(
            [
                str(i),
                ln["designation"],
                "—",
                str(qte),
                f"{pu:.2f}",
                f"{montant:.2f}",
            ]
        )

    # Total row
    tbl_data.append(["", "", "", "", "TOTAL:", f"{total_montant:.2f}"])

    col_w = [1 * cm, 7 * cm, 2 * cm, 1.5 * cm, 2.5 * cm, 3 * cm]
    tbl = Table(tbl_data, colWidths=col_w)

    style_cmds: list = [
        ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 7),
        ("FONTSIZE", (0, 1), (-1, -1), 7),
        ("GRID", (0, 0), (-1, -2), 0.5, colors.Color(0.8, 0.8, 0.8)),
        ("LINEABOVE", (0, -1), (-1, -1), 1, DIMED_BLUE),
        ("FONTNAME", (4, -1), (-1, -1), "Helvetica-Bold"),
        ("ALIGN", (0, 0), (0, -1), "CENTER"),
        ("ALIGN", (2, 0), (-1, -1), "RIGHT"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, DIMED_GREY]),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
    ]

    # Highlight partial picks in red
    for i, ln in enumerate(lignes, start=1):
        qp = ln.get("qte_prelevee", ln.get("qte_demandee", 0))
        qd = ln.get("qte_demandee", qp)
        if qp < qd:
            style_cmds.append(("TEXTCOLOR", (3, i), (3, i), colors.red))
    tbl.setStyle(TableStyle(style_cmds))
    elems.append(tbl)

    # Signatures
    elems.append(Spacer(1, 1.5 * cm))
    prep = visa_preparateur or "_______________"
    ctrl = visa_controleur or "_______________"
    visa_data = [
        [
            f"Préparateur: {prep}",
            f"Contrôleur: {ctrl}",
        ]
    ]
    visa_tbl = Table(visa_data, colWidths=[8.5 * cm, 8.5 * cm])
    visa_tbl.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
            ]
        )
    )
    elems.append(visa_tbl)

    # Footer
    elems.append(Spacer(1, 0.5 * cm))
    elems.append(
        Paragraph(
            f"<para align='right' fontSize='6' textColor='grey'>Imprimé le {now_str}</para>",
            styles["Normal"],
        )
    )

    doc.build(elems)
    return output_path
