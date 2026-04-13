"""Generate a sample facture PDF and POST it with an email payload to the n8n webhook.

Run: cd apps/api && .venv/bin/python ../../scripts/send_sample_facture_to_webhook.py
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "apps" / "api"))

from app.documents.pdf_generator import generate_facture_pdf  # noqa: E402

WEBHOOK_URL = "https://n8n.srv938328.hstgr.cloud/webhook/25b12381-13b7-4eb3-a5e1-ee297ec16969"

SAMPLE_REF = "FA-SAMPLE-0001"
SAMPLE_EMAIL_TO = "client@example.com"
SAMPLE_SUBJECT = f"Facture DIMED {SAMPLE_REF}"
SAMPLE_BODY = (
    "Bonjour,\n\nVeuillez trouver ci-joint la facture "
    f"{SAMPLE_REF} emise par SARL DIMED.\n\nCordialement,\nL'equipe DIMED"
)

sample_lignes = [
    {
        "article": "DOLIPRANE",
        "designation": "Doliprane 1000mg bte 8",
        "lot": "L2024A",
        "exp": "12/2026",
        "ppa": 350.0,
        "qte": 10,
        "pu_ht": 280.0,
        "remise": 0.0,
        "p_detail": 320.0,
        "montant_ht": 2800.0,
        "tva": 9.0,
    },
    {
        "article": "AMOXIL",
        "designation": "Amoxicilline 500mg bte 12",
        "lot": "L2024B",
        "exp": "06/2026",
        "ppa": 480.0,
        "qte": 5,
        "pu_ht": 400.0,
        "remise": 5.0,
        "p_detail": 440.0,
        "montant_ht": 1900.0,
        "tva": 9.0,
    },
]

pdf_path = generate_facture_pdf(
    reference_id=SAMPLE_REF,
    date_emission="13/04/2026",
    client_nom="PHARMACIE EXEMPLE",
    client_adresse="12 RUE DES MIMOSAS, ALGER",
    commande_ref="CMD-SAMPLE-0001",
    lignes=sample_lignes,
    montant_total=4700.0,
    client_telephone="+213 555 00 00 00",
    client_secteur="Alger Centre",
    commercial="DIMED",
)

print(f"[ok] PDF generated: {pdf_path}")

result = subprocess.run(
    [
        "curl", "-sS", "-X", "POST", WEBHOOK_URL,
        "-F", f"to={SAMPLE_EMAIL_TO}",
        "-F", f"subject={SAMPLE_SUBJECT}",
        "-F", f"body={SAMPLE_BODY}",
        "-F", f"file=@{pdf_path};type=application/pdf;filename={SAMPLE_REF}.pdf",
        "-w", "\n[http_code=%{http_code}]\n",
    ],
    capture_output=True,
    text=True,
)

print("=== webhook response ===")
print(result.stdout)
if result.stderr:
    print(result.stderr, file=sys.stderr)
sys.exit(result.returncode)
