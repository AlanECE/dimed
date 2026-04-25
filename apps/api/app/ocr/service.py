"""OCR service — extract pharmaceutical vignette fields via OpenRouter vision LLM.

We send a single photo of a medication vignette (étiquette pharma) and ask the
model to return a strict JSON with at least the DLC (date de péremption). We
also request the code_article / designation as auxiliary fields to help the
caller suggest a matching line in the commande.

Dates on pharma vignettes come in many formats ("05/2027", "31-05-2027",
"May 2027", "2027-05-31"...). We normalize everything to a Python `date`,
falling back to the last day of the month when only month+year are present.
"""

import base64
import calendar
import json
import logging
import re
from dataclasses import dataclass
from datetime import date, datetime

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


@dataclass
class VignetteExtraction:
    dlc: date | None
    code_article: str | None
    designation: str | None
    raw: str


class OcrConfigurationError(RuntimeError):
    """Raised when DIMED_OPENROUTER_API_KEY is missing."""


class OcrUpstreamError(RuntimeError):
    """Raised when the OpenRouter call fails or the payload is unparseable."""


_SYSTEM_PROMPT = (
    "Tu es un assistant OCR spécialisé dans les vignettes pharmaceutiques "
    "(étiquettes collées sur les boîtes de médicaments). Ta seule tâche : "
    "lire la photo et renvoyer un JSON strict avec la date de péremption (DLC), "
    "le code article si visible, et la désignation du produit."
)

_USER_PROMPT = (
    "Analyse cette photo de vignette pharmaceutique. Extrais :\n"
    "- `dlc` : la date de péremption au format ISO `YYYY-MM-DD`. Si seul le "
    "mois et l'année sont visibles (ex: 05/2027), utilise le dernier jour du "
    "mois (2027-05-31). Si absente, renvoie `null`.\n"
    "- `code_article` : code article / CIP / référence visible (chaîne), ou `null`.\n"
    "- `designation` : nom commercial ou DCI du produit, ou `null`.\n\n"
    "Réponds UNIQUEMENT avec un JSON valide de la forme :\n"
    '{"dlc": "YYYY-MM-DD"|null, "code_article": "..."|null, "designation": "..."|null}\n'
    "Aucun texte avant ou après. Aucun bloc Markdown."
)


def _extract_json(raw: str) -> dict:
    """Pull the first JSON object out of a model reply, tolerating ```json fences."""
    fence = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw, re.DOTALL)
    candidate = fence.group(1) if fence else raw
    start = candidate.find("{")
    end = candidate.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise OcrUpstreamError(f"No JSON object in model reply: {raw[:200]}")
    try:
        return json.loads(candidate[start : end + 1])
    except json.JSONDecodeError as exc:
        raise OcrUpstreamError(f"Invalid JSON from model: {exc}") from exc


_ISO_RE = re.compile(r"^(\d{4})-(\d{1,2})-(\d{1,2})$")
_SLASH_RE = re.compile(r"^(\d{1,2})/(\d{1,2})/(\d{2,4})$")
_DASH_RE = re.compile(r"^(\d{1,2})-(\d{1,2})-(\d{2,4})$")
_MONTH_YEAR_SLASH_RE = re.compile(r"^(\d{1,2})/(\d{4})$")
_MONTH_YEAR_DASH_RE = re.compile(r"^(\d{1,2})-(\d{4})$")
_YEAR_MONTH_RE = re.compile(r"^(\d{4})-(\d{1,2})$")


def _last_day(year: int, month: int) -> int:
    return calendar.monthrange(year, month)[1]


def _parse_dlc(value: object) -> date | None:
    """Best-effort parse of heterogeneous DLC strings into a `date`."""
    if value is None:
        return None
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if not isinstance(value, str):
        return None
    s = value.strip()
    if not s or s.lower() in ("null", "none", "n/a"):
        return None

    m = _ISO_RE.match(s)
    if m:
        y, mo, d = (int(x) for x in m.groups())
        try:
            return date(y, mo, d)
        except ValueError:
            return None

    m = _SLASH_RE.match(s) or _DASH_RE.match(s)
    if m:
        a, b, c = (int(x) for x in m.groups())
        year = c + 2000 if c < 100 else c
        # Day-first (European); swap if clearly year-first
        day, month = (a, b)
        if day > 31 or month > 12:
            day, month = b, a
        try:
            return date(year, month, day)
        except ValueError:
            return None

    m = _MONTH_YEAR_SLASH_RE.match(s) or _MONTH_YEAR_DASH_RE.match(s)
    if m:
        month, year = int(m.group(1)), int(m.group(2))
        try:
            return date(year, month, _last_day(year, month))
        except ValueError:
            return None

    m = _YEAR_MONTH_RE.match(s)
    if m:
        year, month = int(m.group(1)), int(m.group(2))
        try:
            return date(year, month, _last_day(year, month))
        except ValueError:
            return None

    return None


async def extract_vignette_fields(
    image_bytes: bytes,
    content_type: str,
) -> VignetteExtraction:
    if not settings.openrouter_api_key:
        raise OcrConfigurationError("DIMED_OPENROUTER_API_KEY is not set — cannot call OCR service")

    mime = content_type if content_type.startswith("image/") else "image/jpeg"
    b64 = base64.b64encode(image_bytes).decode("ascii")
    data_url = f"data:{mime};base64,{b64}"

    payload = {
        "model": settings.ocr_model,
        "messages": [
            {"role": "system", "content": _SYSTEM_PROMPT},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _USER_PROMPT},
                    {"type": "image_url", "image_url": {"url": data_url}},
                ],
            },
        ],
        "temperature": 0.0,
        "response_format": {"type": "json_object"},
    }

    headers = {
        "Authorization": f"Bearer {settings.openrouter_api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": settings.frontend_url,
        "X-Title": "DIMED Vignette OCR",
    }

    url = f"{settings.openrouter_base_url.rstrip('/')}/chat/completions"
    try:
        async with httpx.AsyncClient(timeout=settings.ocr_timeout_seconds) as client:
            response = await client.post(url, json=payload, headers=headers)
    except httpx.HTTPError as exc:
        reason = str(exc) or type(exc).__name__
        raise OcrUpstreamError(f"OpenRouter request failed: {reason}") from exc

    if response.status_code >= 400:
        raise OcrUpstreamError(f"OpenRouter returned {response.status_code}: {response.text[:300]}")

    try:
        body = response.json()
        content = body["choices"][0]["message"]["content"]
    except (KeyError, IndexError, ValueError) as exc:
        raise OcrUpstreamError(f"Unexpected OpenRouter payload: {exc}") from exc

    content_str = content if isinstance(content, str) else str(content)
    parsed = _extract_json(content_str)

    dlc = _parse_dlc(parsed.get("dlc"))
    code = parsed.get("code_article")
    code = str(code).strip()[:64] if code else None
    desig = parsed.get("designation")
    desig = str(desig).strip()[:500] if desig else None

    return VignetteExtraction(
        dlc=dlc,
        code_article=code or None,
        designation=desig or None,
        raw=content_str[:4000],
    )
