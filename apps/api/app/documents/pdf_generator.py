import io
from datetime import UTC, datetime
from pathlib import Path

import barcode
import qrcode
from barcode.writer import ImageWriter
from num2words import num2words
from reportlab.graphics.shapes import Circle, Drawing, String
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, A6, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
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
CLIENT_HIGHLIGHT = colors.HexColor("#c8e6c9")  # green for client name box
TABLE_HEADER = colors.HexColor("#1a5276")
ROW_ALT = colors.HexColor("#f8f9fa")
BORDER_GREY = colors.HexColor("#b0bec5")


def _ensure_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def _make_qr_image(data: str, size_cm: float) -> Image:
    """Generate a QR code image for the given data string."""
    qr = qrcode.QRCode(version=1, box_size=6, border=2)
    qr.add_data(data)
    qr.make(fit=True)
    pil_img = qr.make_image(fill_color="black", back_color="white")
    buf = io.BytesIO()
    pil_img.save(buf, format="PNG")
    buf.seek(0)
    size = size_cm * cm
    return Image(buf, width=size, height=size)


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


MERINAL_BLUE = colors.HexColor("#1d3557")
HIGHLIGHT_YELLOW = colors.HexColor("#fff59d")


def _amount_in_words_fr(amount: float) -> str:
    """Convert an amount in DZD to French words, Merinal-invoice style."""
    entier = int(amount)
    centimes = int(round((amount - entier) * 100))
    entier_mots = num2words(entier, lang="fr")
    if centimes > 0:
        centimes_mots = num2words(centimes, lang="fr")
        return f"{entier_mots} dinars et {centimes_mots} centimes"
    return f"{entier_mots} dinars"


def _cachet_drawing() -> Drawing:
    """Round official stamp placeholder, bottom-left of the facture."""
    d = Drawing(2.8 * cm, 2.8 * cm)
    d.add(
        Circle(
            1.4 * cm,
            1.4 * cm,
            1.35 * cm,
            strokeColor=MERINAL_BLUE,
            fillColor=colors.white,
            strokeWidth=1.4,
        )
    )
    d.add(
        Circle(
            1.4 * cm,
            1.4 * cm,
            1.1 * cm,
            strokeColor=MERINAL_BLUE,
            fillColor=colors.white,
            strokeWidth=0.6,
        )
    )
    d.add(
        String(
            1.4 * cm,
            1.55 * cm,
            "SPA DIMED",
            textAnchor="middle",
            fontSize=8,
            fontName="Helvetica-Bold",
            fillColor=MERINAL_BLUE,
        )
    )
    d.add(
        String(
            1.4 * cm,
            1.25 * cm,
            "PHARMA",
            textAnchor="middle",
            fontSize=7,
            fontName="Helvetica-Bold",
            fillColor=MERINAL_BLUE,
        )
    )
    d.add(
        String(
            1.4 * cm,
            0.95 * cm,
            "ALGER",
            textAnchor="middle",
            fontSize=6,
            fontName="Helvetica",
            fillColor=MERINAL_BLUE,
        )
    )
    return d


def generate_facture_pdf(
    reference_id: str,
    date_emission: str,
    client_nom: str,
    client_adresse: str | None,
    commande_ref: str,
    lignes: list[dict],
    montant_total: float,
    client_telephone: str | None = None,
    client_secteur: str | None = None,
    commercial: str | None = None,
    prelevement_ref: str | None = None,
    visa_preparateur: str | None = None,  # kept for signature compat (unused)
    visa_controleur: str | None = None,  # kept for signature compat (unused)
    is_proforma: bool = False,
) -> Path:
    """Generate a facture PDF mirroring the real Merinal tax-invoice layout.

    Layout:
    - Top band: SARL DIMED logo block + PRODUCTION/DISTRIBUTION PHARMACEUTIQUE
    - Reference block: yellow-highlighted FACTURE + invoice ref + date
    - Client block with Code / Client / address / contact / legal IDs
    - 12-column detailed table: N°, Article, Designation, Lot, EXP, PPA, QTE,
      PU HT, R%, P.detail, Montant HT, TVA
    - 5-line totals block bottom-right (Total lignes HT / Frais-items /
      Total HT / Montant TVA / TOTAL TTC DZD)
    - Amount in words
    - Round cachet + legal footer
    """
    output_path = STORAGE_ROOT / "factures" / f"{reference_id}.pdf"
    _ensure_dir(output_path)

    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        leftMargin=1.0 * cm,
        rightMargin=1.0 * cm,
        topMargin=0.8 * cm,
        bottomMargin=0.8 * cm,
    )
    styles = getSampleStyleSheet()
    elements: list = []

    printed_at = datetime.now(UTC).strftime("%d/%m/%Y %H:%M")

    # ── 1. LOGO BAND ─────────────────────────────────────────────
    logo_big = ParagraphStyle(
        "LogoBig",
        parent=styles["Normal"],
        fontSize=20,
        fontName="Helvetica-Bold",
        textColor=MERINAL_BLUE,
        leading=22,
    )
    logo_small = ParagraphStyle(
        "LogoSmall",
        parent=styles["Normal"],
        fontSize=7,
        textColor=MERINAL_BLUE,
        leading=8,
    )
    prod_style = ParagraphStyle(
        "Prod",
        parent=styles["Normal"],
        fontSize=11,
        fontName="Helvetica-Bold",
        textColor=MERINAL_BLUE,
        alignment=0,
    )

    logo_band = Table(
        [
            [
                [
                    Paragraph("SARL <b>DIMED</b> PHARMA", logo_big),
                    Paragraph("LABORATOIRES", logo_small),
                ],
                Paragraph("DISTRIBUTION PHARMACEUTIQUE", prod_style),
            ]
        ],
        colWidths=[7.5 * cm, 11.5 * cm],
    )
    logo_band.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "BOTTOM"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                ("LINEBELOW", (0, 0), (-1, -1), 1.2, MERINAL_BLUE),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    elements.append(logo_band)
    elements.append(Spacer(1, 0.3 * cm))

    # ── 2. REFERENCE / CLIENT BLOCK ──────────────────────────────
    label_style = ParagraphStyle(
        "Label",
        parent=styles["Normal"],
        fontSize=7,
        textColor=colors.grey,
        leading=9,
    )
    val_style = ParagraphStyle(
        "Val",
        parent=styles["Normal"],
        fontSize=8,
        textColor=colors.black,
        leading=10,
    )
    val_bold = ParagraphStyle(
        "ValBold",
        parent=styles["Normal"],
        fontSize=9,
        fontName="Helvetica-Bold",
        textColor=colors.black,
        leading=11,
    )
    title_hl = ParagraphStyle(
        "TitleHl",
        parent=styles["Normal"],
        fontSize=13,
        fontName="Helvetica-Bold",
        textColor=colors.black,
        backColor=HIGHLIGHT_YELLOW,
        alignment=1,
        leading=16,
    )
    ref_big = ParagraphStyle(
        "RefBig",
        parent=styles["Normal"],
        fontSize=11,
        fontName="Helvetica-Bold",
        textColor=MERINAL_BLUE,
        leading=13,
    )

    sender_text = (
        "<b>Sarl Laboratoires DIMED</b><br/>"
        "Zone Industrielle, Oued Smar, Alger<br/>"
        "Tel: 023 XX XX XX &nbsp; Fax: 023 XX XX XX<br/>"
        "Email: dimed.pharma@dimed.dz"
    )
    sender_p = Paragraph(sender_text, val_style)

    # Tant que la commande n'est pas contrôlée, le document est une proforma.
    ref_cell = [
        Paragraph("FACTURE PROFORMA" if is_proforma else "FACTURE", title_hl),
        Spacer(1, 0.15 * cm),
        Paragraph(f"N° : <font color='#1d3557'>{reference_id}</font>", ref_big),
        Paragraph(f"Date : <b>{date_emission}</b>", val_style),
        Paragraph(f"CMD : {commande_ref}", val_style),
    ]
    if prelevement_ref:
        ref_cell.append(Paragraph(f"Prelevement : {prelevement_ref}", val_style))

    ref_row = Table(
        [[sender_p, ref_cell]],
        colWidths=[11 * cm, 8 * cm],
    )
    ref_row.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ]
        )
    )
    elements.append(ref_row)
    elements.append(Spacer(1, 0.35 * cm))

    # Client block — Code + name + address + contact
    contact_parts = list(filter(None, [client_telephone, client_secteur]))
    contact_line = " · ".join(contact_parts) if contact_parts else "—"

    client_cell = [
        Paragraph(f"<b>Code :</b> {commande_ref}", val_style),
        Paragraph(f"<b>Client :</b> <b>{client_nom}</b>", val_bold),
        Paragraph(client_adresse or "—", val_style),
        Paragraph(contact_line, val_style),
        Paragraph(
            f"Commercial : {commercial or '—'}",
            val_style,
        ),
    ]
    legal_cell = [
        Paragraph("<b>RC :</b> 16/00-XXXXXXXX B XX", val_style),
        Paragraph("<b>NIF :</b> 00XXXXXXXXXXXXX", val_style),
        Paragraph("<b>NIS :</b> 00XXXXXXXXXXXXXXX", val_style),
        Paragraph("<b>AI :</b> XXXXXXXXXXX", val_style),
        Paragraph("Page 1 sur 1", label_style),
    ]
    client_t = Table(
        [[client_cell, legal_cell]],
        colWidths=[11 * cm, 8 * cm],
    )
    client_t.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BOX", (0, 0), (-1, -1), 0.4, BORDER_GREY),
                ("LINEAFTER", (0, 0), (0, 0), 0.3, BORDER_GREY),
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#fafafa")),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    elements.append(client_t)
    elements.append(Spacer(1, 0.3 * cm))

    # ── 3. LINES TABLE (12 columns, Merinal-style) ───────────────
    hdr_style = ParagraphStyle(
        "Hdr",
        parent=styles["Normal"],
        fontSize=6.5,
        fontName="Helvetica-Bold",
        textColor=colors.white,
        leading=8,
        alignment=1,
    )
    cell_style = ParagraphStyle(
        "Cell",
        parent=styles["Normal"],
        fontSize=6.3,
        leading=7.8,
    )
    cell_num = ParagraphStyle(
        "CellNum",
        parent=cell_style,
        alignment=2,  # right
    )
    cell_center = ParagraphStyle(
        "CellCenter",
        parent=cell_style,
        alignment=1,
    )

    tbl_data = [
        [
            Paragraph("N°", hdr_style),
            Paragraph("Article", hdr_style),
            Paragraph("Designation", hdr_style),
            Paragraph("Lot", hdr_style),
            Paragraph("EXP", hdr_style),
            Paragraph("PPA", hdr_style),
            Paragraph("QTE", hdr_style),
            Paragraph("PU HT", hdr_style),
            Paragraph("R %", hdr_style),
            Paragraph("P. detail", hdr_style),
            Paragraph("Montant HT", hdr_style),
            Paragraph("TVA", hdr_style),
        ]
    ]
    total_brut = 0.0
    total_lignes_ht = 0.0
    total_tva = 0.0
    for i, ln in enumerate(lignes, 1):
        qte = float(ln.get("qte", 0) or 0)
        pu_ht = float(ln.get("prix_unitaire", 0) or 0)
        ppa = float(ln.get("ppa", pu_ht) or pu_ht)
        remise_pct = float(ln.get("remise_pct", 0) or 0)
        taux_tva = float(ln.get("taux_tva", 0) or 0)
        p_detail = pu_ht * (1 - remise_pct / 100)
        montant_ht = qte * p_detail
        brut = qte * pu_ht
        total_brut += brut
        total_lignes_ht += montant_ht
        total_tva += montant_ht * taux_tva / 100

        tbl_data.append(
            [
                Paragraph(str(i), cell_center),
                Paragraph(ln.get("code", "") or "—", cell_style),
                Paragraph(ln.get("designation", ""), cell_style),
                Paragraph(ln.get("lot", "") or "—", cell_center),
                Paragraph(ln.get("exp", "") or "—", cell_center),
                Paragraph(f"{ppa:,.2f}".replace(",", " "), cell_num),
                Paragraph(str(int(qte)), cell_num),
                Paragraph(f"{pu_ht:,.2f}".replace(",", " "), cell_num),
                Paragraph(f"{remise_pct:.2f}", cell_num),
                Paragraph(f"{p_detail:,.2f}".replace(",", " "), cell_num),
                Paragraph(f"{montant_ht:,.2f}".replace(",", " "), cell_num),
                Paragraph(f"{taux_tva:g}" if taux_tva else "—", cell_center),
            ]
        )

    t = Table(
        tbl_data,
        colWidths=[
            0.6 * cm,  # N°
            1.4 * cm,  # Article
            4.2 * cm,  # Designation
            1.3 * cm,  # Lot
            1.6 * cm,  # EXP
            1.4 * cm,  # PPA
            1.0 * cm,  # QTE
            1.5 * cm,  # PU HT
            0.9 * cm,  # R %
            1.4 * cm,  # P. detail
            2.3 * cm,  # Montant HT
            0.8 * cm,  # TVA
        ],
        repeatRows=1,
    )
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), MERINAL_BLUE),
                ("GRID", (0, 0), (-1, -1), 0.3, BORDER_GREY),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#fafafa")]),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 2),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
                ("LEFTPADDING", (0, 0), (-1, -1), 2),
                ("RIGHTPADDING", (0, 0), (-1, -1), 2),
            ]
        )
    )
    elements.append(t)
    elements.append(Spacer(1, 0.25 * cm))

    # ── 4. TOTALS BLOCK (5 lines, Merinal-style) ─────────────────
    remise_totale = total_brut - total_lignes_ht
    # Caller might override via `montant_total`; trust the computed one
    # because it's coherent with the table we just drew.
    net_ttc = total_lignes_ht + total_tva

    t_label = ParagraphStyle(
        "TotLabel",
        parent=styles["Normal"],
        fontSize=8.5,
        textColor=colors.black,
        alignment=0,
    )
    t_val = ParagraphStyle(
        "TotVal",
        parent=styles["Normal"],
        fontSize=8.5,
        textColor=colors.black,
        alignment=2,
    )
    ttc_label = ParagraphStyle(
        "TtcLabel",
        parent=styles["Normal"],
        fontSize=10,
        fontName="Helvetica-Bold",
        textColor=colors.white,
        alignment=0,
    )
    ttc_val = ParagraphStyle(
        "TtcVal",
        parent=styles["Normal"],
        fontSize=10,
        fontName="Helvetica-Bold",
        textColor=colors.white,
        alignment=2,
    )
    ttc_unit = ParagraphStyle(
        "TtcUnit",
        parent=styles["Normal"],
        fontSize=9,
        fontName="Helvetica-Bold",
        textColor=colors.white,
        alignment=1,
    )

    def _fmt(n: float) -> str:
        return f"{n:,.2f}".replace(",", " ")

    tot_rows = [
        [Paragraph("Total lignes HT", t_label), Paragraph(_fmt(total_lignes_ht), t_val), ""],
        [Paragraph("Frais / Items", t_label), Paragraph("0,00", t_val), ""],
        [Paragraph("Total HT", t_label), Paragraph(_fmt(total_lignes_ht), t_val), ""],
        [Paragraph("Montant TVA", t_label), Paragraph(_fmt(total_tva), t_val), ""],
        [
            Paragraph("TOTAL TTC", ttc_label),
            Paragraph(_fmt(net_ttc), ttc_val),
            Paragraph("DZD", ttc_unit),
        ],
    ]
    if remise_totale > 0.001:
        tot_rows.insert(
            1,
            [Paragraph("Remise totale", t_label), Paragraph(f"-{_fmt(remise_totale)}", t_val), ""],
        )

    tot_tbl = Table(
        tot_rows,
        colWidths=[3.2 * cm, 3.0 * cm, 1.2 * cm],
    )
    tot_style: list = [
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("BOX", (0, 0), (-1, -1), 0.5, colors.black),
        ("INNERGRID", (0, 0), (-1, -2), 0.3, BORDER_GREY),
        ("BACKGROUND", (0, -1), (-1, -1), MERINAL_BLUE),
        ("LINEABOVE", (0, -1), (-1, -1), 1, colors.black),
    ]
    tot_tbl.setStyle(TableStyle(tot_style))

    totals_wrapper = Table(
        [["", tot_tbl]],
        colWidths=[11.6 * cm, 7.4 * cm],
    )
    totals_wrapper.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ]
        )
    )
    elements.append(totals_wrapper)
    elements.append(Spacer(1, 0.4 * cm))

    # ── 5. AMOUNT IN WORDS + CACHET ──────────────────────────────
    words_style = ParagraphStyle(
        "Words",
        parent=styles["Normal"],
        fontSize=8.5,
        textColor=colors.black,
        leading=11,
        alignment=0,
    )
    amount_words = _amount_in_words_fr(net_ttc).capitalize()
    words_p = Paragraph(
        f"<b>Arrete la presente facture a la somme de :</b><br/><i>{amount_words}.</i>",
        words_style,
    )

    qr_facture = _make_qr_image(commande_ref, 2.8)
    bottom_row = Table(
        [[_cachet_drawing(), words_p, qr_facture]],
        colWidths=[3.2 * cm, 12.6 * cm, 3.2 * cm],
    )
    bottom_row.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("ALIGN", (2, 0), (2, 0), "RIGHT"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    elements.append(KeepTogether(bottom_row))
    elements.append(Spacer(1, 0.6 * cm))

    # ── 6. LEGAL FOOTER ──────────────────────────────────────────
    foot_style = ParagraphStyle(
        "Foot",
        parent=styles["Normal"],
        fontSize=6,
        textColor=colors.HexColor("#444444"),
        leading=8,
        alignment=1,
    )
    footer_lines = [
        (
            "<b>Siege Social :</b> Zone Industrielle, Oued Smar - Alger - Algerie "
            "&nbsp;·&nbsp; <b>Distribution :</b> Oued Smar, Alger "
            "&nbsp;·&nbsp; <b>Production :</b> Oued Smar, Alger"
        ),
        (
            "Tel : +213 23 XX XX XX &nbsp;·&nbsp; Fax : +213 23 XX XX XX "
            "&nbsp;·&nbsp; Email : dimed.pharma@dimed.dz"
        ),
        (
            "<b>RC :</b> 16/00-XXXXXXXX B XX &nbsp;·&nbsp; "
            "<b>NIF :</b> 00XXXXXXXXXXXXX &nbsp;·&nbsp; "
            "<b>NIS :</b> 00XXXXXXXXXXXXXXX &nbsp;·&nbsp; "
            "<b>AI :</b> XXXXXXXXXXX"
        ),
        (
            "<b>Compte Bancaire :</b> SGA N° 021 000 XX XXX XXX XXX XX "
            "&nbsp;·&nbsp; <b>CCP :</b> N° XXXXXX XXX Cle XX"
        ),
    ]
    for line in footer_lines:
        elements.append(Paragraph(line, foot_style))

    # Print footer with date
    elements.append(Spacer(1, 0.15 * cm))
    elements.append(
        Paragraph(
            f"<para align='right' fontSize='5.5' textColor='grey'>Imprime le {printed_at}</para>",
            styles["Normal"],
        )
    )

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
    client_secteur: str | None = None,
    preparateur_nom: str | None = None,
) -> Path:
    """Generate Merinal-style picking list PDF.

    Layout mirrors the real warehouse document:
    - Top meta line (Heure / Page / Prelevee LE)
    - Big CMD N° bleu + Code128 barcode + round cachet DIMED
    - PRELEVEMENT N° subheader
    - Commercial / Client name / Address block
    - Lines grouped by first letter of designation (sections A, B, C...)
      Each section header shows "Griffe du Preparateur: <name>"
    - Each row has a trailing empty "Griffe" column for manual pen check
    """
    output_path = STORAGE_ROOT / "prelevements" / f"PRL_{commande_ref}.pdf"
    _ensure_dir(output_path)

    now = datetime.now(UTC)
    now_str = now.strftime("%d/%m/%Y %H:%M:%S")
    now_short = now.strftime("%H:%M")

    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        leftMargin=1.0 * cm,
        rightMargin=1.0 * cm,
        topMargin=0.8 * cm,
        bottomMargin=1.0 * cm,
    )
    styles = getSampleStyleSheet()
    elems: list = []

    # ── 1. TOP META BAND ─────────────────────────────────────────
    meta_style = ParagraphStyle(
        "Meta",
        parent=styles["Normal"],
        fontSize=7,
        textColor=colors.grey,
        leading=9,
    )
    top_meta = Table(
        [
            [
                Paragraph(f"Heure de Prelevement {now_short}", meta_style),
                Paragraph(
                    "Page 1 sur 1",
                    ParagraphStyle(
                        "MetaCenter",
                        parent=meta_style,
                        alignment=1,
                    ),
                ),
                Paragraph(
                    f"Prelevee LE : {now_str}",
                    ParagraphStyle(
                        "MetaRight",
                        parent=meta_style,
                        alignment=2,
                    ),
                ),
            ]
        ],
        colWidths=[6.3 * cm, 6.3 * cm, 6.3 * cm],
    )
    top_meta.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elems.append(top_meta)
    elems.append(Spacer(1, 2 * mm))

    # ── 2. CMD BLOCK : big blue CMD + barcode + cachet ────────────
    cmd_title_style = ParagraphStyle(
        "CmdTitle",
        parent=styles["Normal"],
        fontSize=22,
        fontName="Helvetica-Bold",
        textColor=MERINAL_BLUE,
        leading=26,
    )
    # Code128 barcode
    code128 = barcode.get("code128", commande_ref, writer=ImageWriter())
    bar_buf = io.BytesIO()
    code128.write(bar_buf, options={"module_height": 10, "font_size": 7})
    bar_buf.seek(0)
    barcode_img = Image(bar_buf, width=7.5 * cm, height=1.7 * cm)

    qr_img = _make_qr_image(commande_ref, 3.2)

    cmd_cell = [
        Paragraph(f"CMD N° : <b>{commande_ref}</b>", cmd_title_style),
        Spacer(1, 1 * mm),
        barcode_img,
    ]

    right_cell = [_cachet_drawing(), Spacer(1, 2 * mm), qr_img]

    cmd_block = Table(
        [[cmd_cell, right_cell]],
        colWidths=[15.5 * cm, 3.5 * cm],
    )
    cmd_block.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                ("TOPPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
            ]
        )
    )
    elems.append(cmd_block)
    elems.append(Spacer(1, 2 * mm))

    # ── 3. PRELEVEMENT N° + Commercial / Client ──────────────────
    val_style = ParagraphStyle(
        "ValSmall",
        parent=styles["Normal"],
        fontSize=9,
        textColor=colors.black,
        leading=11,
    )
    val_bold = ParagraphStyle(
        "ValBoldClient",
        parent=styles["Normal"],
        fontSize=11,
        fontName="Helvetica-Bold",
        textColor=colors.black,
        leading=13,
    )

    if prelevement_ref:
        prl_p = Paragraph(
            f"<b>PRELEVEMENT N° :</b> {prelevement_ref} "
            f"&nbsp;&nbsp;&nbsp; <b>Nb colis :</b> {nb_colis or 0}",
            val_style,
        )
    else:
        prl_p = Paragraph(f"<b>Nb colis :</b> {nb_colis or 0}", val_style)
    elems.append(prl_p)
    elems.append(Spacer(1, 1 * mm))

    client_row = Table(
        [
            [
                Paragraph(f"Commercial : {commercial or '—'}", val_style),
                Paragraph(client_nom or "—", val_bold),
            ],
            [
                Paragraph("&nbsp;", val_style),
                Paragraph(
                    " · ".join(filter(None, [client_adresse, client_secteur])) or "—",
                    val_style,
                ),
            ],
        ],
        colWidths=[9 * cm, 10 * cm],
    )
    client_row.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BOX", (0, 0), (-1, -1), 0.4, BORDER_GREY),
                ("LINEAFTER", (0, 0), (0, -1), 0.4, BORDER_GREY),
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#fafafa")),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    elems.append(client_row)
    elems.append(Spacer(1, 3 * mm))

    # ── 4. LINES TABLE grouped by first letter ───────────────────
    hdr_style = ParagraphStyle(
        "HdrPrl",
        parent=styles["Normal"],
        fontSize=6.5,
        fontName="Helvetica-Bold",
        textColor=colors.white,
        leading=8,
        alignment=1,
    )
    cell_style = ParagraphStyle(
        "CellPrl",
        parent=styles["Normal"],
        fontSize=6.3,
        leading=7.8,
    )
    cell_center = ParagraphStyle(
        "CellPrlC",
        parent=cell_style,
        alignment=1,
    )
    cell_num = ParagraphStyle(
        "CellPrlR",
        parent=cell_style,
        alignment=2,
    )
    section_label = ParagraphStyle(
        "SecLabel",
        parent=styles["Normal"],
        fontSize=10,
        fontName="Helvetica-Bold",
        textColor=MERINAL_BLUE,
    )
    griffe_label = ParagraphStyle(
        "GriffeLbl",
        parent=styles["Normal"],
        fontSize=8,
        fontName="Helvetica-Oblique",
        textColor=colors.grey,
        alignment=2,
    )

    # Column widths (A4 - 2cm margin = 19 cm)
    col_widths = [
        0.6 * cm,  # N°
        1.5 * cm,  # Code
        5.8 * cm,  # Designation
        1.0 * cm,  # QTE
        1.6 * cm,  # Lot
        1.5 * cm,  # EXP
        1.5 * cm,  # PPA
        2.0 * cm,  # Montant
        3.5 * cm,  # Griffe (empty)
    ]

    header_row = [
        Paragraph("N°", hdr_style),
        Paragraph("Code", hdr_style),
        Paragraph("Designation", hdr_style),
        Paragraph("QTE", hdr_style),
        Paragraph("Lot", hdr_style),
        Paragraph("EXP", hdr_style),
        Paragraph("PPA", hdr_style),
        Paragraph("Montant", hdr_style),
        Paragraph("Griffe", hdr_style),
    ]

    sorted_lignes = sorted(
        lignes,
        key=lambda ln: (ln.get("designation", "")[:1].upper(), ln.get("designation", "")),
    )

    groups: dict[str, list[dict]] = {}
    for ln in sorted_lignes:
        letter = (ln.get("designation", "") or "?")[:1].upper()
        groups.setdefault(letter, []).append(ln)

    tbl_data: list = [header_row]
    section_rows: list[int] = []  # indexes where a section header sits

    row_idx = 1
    for letter, group_lignes in groups.items():
        section_rows.append(row_idx)
        tbl_data.append(
            [
                Paragraph(letter, section_label),
                Paragraph(
                    f"<i>Griffe du Preparateur : {preparateur_nom or '—'}</i>",
                    griffe_label,
                ),
                "",
                "",
                "",
                "",
                "",
                "",
                "",
            ]
        )
        row_idx += 1
        for i, ln in enumerate(group_lignes, 1):
            qte = ln.get("qte_prelevee") or ln.get("qte_demandee", 0) or 0
            pu = float(ln.get("prix_unitaire", 0) or 0)
            ppa = float(ln.get("ppa", pu) or pu)
            montant = float(qte) * pu
            tbl_data.append(
                [
                    Paragraph(str(i), cell_center),
                    Paragraph(ln.get("code", "") or "—", cell_style),
                    Paragraph(ln.get("designation", ""), cell_style),
                    Paragraph(str(int(qte)), cell_num),
                    Paragraph(ln.get("n_lot", "") or "—", cell_center),
                    Paragraph(ln.get("exp", "") or "—", cell_center),
                    Paragraph(f"{ppa:,.2f}".replace(",", " "), cell_num),
                    Paragraph(f"{montant:,.2f}".replace(",", " "), cell_num),
                    "",  # empty griffe column
                ]
            )
            row_idx += 1

    tbl = Table(tbl_data, colWidths=col_widths, repeatRows=1)
    style_cmds: list = [
        ("BACKGROUND", (0, 0), (-1, 0), MERINAL_BLUE),
        ("GRID", (0, 0), (-1, -1), 0.3, BORDER_GREY),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
    ]
    for sec_idx in section_rows:
        style_cmds.append(("BACKGROUND", (0, sec_idx), (-1, sec_idx), HIGHLIGHT_YELLOW))
        style_cmds.append(("SPAN", (1, sec_idx), (-1, sec_idx)))
        style_cmds.append(("LINEBELOW", (0, sec_idx), (-1, sec_idx), 0.5, MERINAL_BLUE))
    tbl.setStyle(TableStyle(style_cmds))
    elems.append(tbl)

    # ── 5. SIGNATURES + FOOTER ───────────────────────────────────
    elems.append(Spacer(1, 0.6 * cm))
    visa_label = ParagraphStyle(
        "VisaLblPrl",
        parent=styles["Normal"],
        fontSize=8,
        textColor=colors.grey,
    )
    visa_data = [
        [
            Paragraph(
                f"<b>Preparateur :</b> {visa_preparateur or preparateur_nom or '_______________'}",
                visa_label,
            ),
            Paragraph(
                f"<b>Controleur :</b> {visa_controleur or '_______________'}",
                visa_label,
            ),
        ]
    ]
    visa_tbl = Table(visa_data, colWidths=[9.5 * cm, 9.5 * cm])
    visa_tbl.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    elems.append(visa_tbl)

    elems.append(Spacer(1, 0.3 * cm))
    elems.append(
        Paragraph(
            f"<para align='right' fontSize='6' textColor='grey'>Imprime le {now_str}</para>",
            styles["Normal"],
        )
    )

    doc.build(elems)
    return output_path


def generate_etiquettes_pdf(
    commande_ref: str,
    client_nom: str,
    client_adresse: str | None,
    client_secteur: str | None,
    date_str: str,
    colis: list[dict],
    controleur_nom: str | None = None,
) -> Path:
    """Generate parcel labels PDF: one A6 landscape page per parcel.

    Each label carries a QR code encoding ONLY the parcel's unique numero —
    the scan looks the rest up through the API. The human-readable side shows
    the numero, "Colis X/N", order ref, destination pharmacist and contents.

    colis items: {numero, index, total, contenu: list[str], contenu_detaille: bool}
    """
    output_path = STORAGE_ROOT / "etiquettes" / f"etiquettes_{commande_ref}.pdf"
    _ensure_dir(output_path)

    page_size = landscape(A6)
    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=page_size,
        leftMargin=0.5 * cm,
        rightMargin=0.5 * cm,
        topMargin=0.4 * cm,
        bottomMargin=0.4 * cm,
    )
    styles = getSampleStyleSheet()

    numero_style = ParagraphStyle(
        "EtiqNumero",
        parent=styles["Normal"],
        fontName="Courier-Bold",
        fontSize=14,
        leading=16,
        textColor=colors.black,
    )
    position_style = ParagraphStyle(
        "EtiqPosition",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=20,
        leading=22,
        textColor=DIMED_BLUE,
    )
    label_style = ParagraphStyle(
        "EtiqLabel",
        parent=styles["Normal"],
        fontSize=8,
        leading=10,
        textColor=colors.grey,
    )
    value_style = ParagraphStyle(
        "EtiqValue",
        parent=styles["Normal"],
        fontSize=9,
        leading=11,
        textColor=colors.black,
    )
    contenu_style = ParagraphStyle(
        "EtiqContenu",
        parent=styles["Normal"],
        fontSize=7,
        leading=9,
        textColor=colors.black,
    )

    elems: list = []
    max_contenu_lines = 6

    for i, item in enumerate(colis):
        if i > 0:
            elems.append(PageBreak())

        qr_img = _make_qr_image(item["numero"], 3.8)

        contenu_lines = item.get("contenu") or []
        shown = contenu_lines[:max_contenu_lines]
        extra = len(contenu_lines) - len(shown)
        contenu_title = "Contenu" if item.get("contenu_detaille") else "Contenu (commande complète)"
        if not contenu_lines:
            contenu_flow = [Paragraph("Contenu non détaillé", contenu_style)]
        else:
            contenu_flow = [Paragraph(f"• {line}", contenu_style) for line in shown]
            if extra > 0:
                contenu_flow.append(Paragraph(f"+ {extra} autres articles", contenu_style))

        left_cell = [
            Paragraph("DIMED — Étiquette colis", label_style),
            Spacer(1, 1 * mm),
            Paragraph(item["numero"], numero_style),
            Paragraph(f"Colis {item['index']} / {item['total']}", position_style),
            Spacer(1, 1.5 * mm),
            Paragraph(f"Commande : <b>{commande_ref}</b> — {date_str}", value_style),
            Paragraph(f"Destinataire : <b>{client_nom}</b>", value_style),
        ]
        if client_adresse:
            left_cell.append(Paragraph(client_adresse, value_style))
        if client_secteur:
            left_cell.append(Paragraph(f"Secteur : {client_secteur}", value_style))
        left_cell.append(Spacer(1, 1.5 * mm))
        left_cell.append(Paragraph(contenu_title, label_style))
        left_cell.extend(contenu_flow)
        if controleur_nom:
            left_cell.append(Spacer(1, 1.5 * mm))
            left_cell.append(Paragraph(f"Contrôlé par : <b>{controleur_nom}</b>", value_style))

        right_cell = [
            qr_img,
            Paragraph(
                f"<para align='center' fontSize='7'>{item['numero']}</para>",
                styles["Normal"],
            ),
        ]

        layout = Table(
            [[left_cell, right_cell]],
            colWidths=[9.2 * cm, 4.3 * cm],
        )
        layout.setStyle(
            TableStyle(
                [
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("BOX", (0, 0), (-1, -1), 1, colors.black),
                    ("LEFTPADDING", (0, 0), (-1, -1), 6),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                    ("TOPPADDING", (0, 0), (-1, -1), 6),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ]
            )
        )
        elems.append(layout)

    doc.build(elems)
    return output_path
