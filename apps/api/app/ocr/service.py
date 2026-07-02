"""OCR service — extract pharmaceutical vignette fields via OpenRouter vision LLM.

We send a photo of a medication vignette and ask the model to return a strict
JSON with five fields imprimés on the label : `lot`, `fab`, `exp`, `ppa`, `designation`.

Dates and prices come in many formats. We normalize:
- dates with `_parse_date()` (month/year → first or last day depending on `month_default`)
- prices with `_parse_decimal()` (handles "DA" suffix, FR comma decimals, dot thousands)
"""

import base64
import calendar
import json
import logging
import re
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from typing import Literal

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


@dataclass
class VignetteExtraction:
    lot: str | None
    fab: date | None
    exp: date | None
    ppa: Decimal | None
    designation: str | None
    raw: str


class OcrConfigurationError(RuntimeError):
    """Raised when DIMED_OPENROUTER_API_KEY is missing."""


class OcrUpstreamError(RuntimeError):
    """Raised when the OpenRouter call fails or the payload is unparseable."""


_SYSTEM_PROMPT = (
    "Tu es un assistant OCR spécialisé dans les vignettes pharmaceutiques "
    "algériennes (étiquettes collées sur les boîtes de médicaments). Lis "
    "la photo et renvoie un JSON strict avec les champs imprimés."
)

_USER_PROMPT = (
    "Analyse cette photo de vignette pharmaceutique. Extrais :\n"
    "- `lot` : numéro de lot (chaîne alphanumérique imprimée), ou `null`.\n"
    "- `fab` : date de fabrication au format ISO `YYYY-MM-DD`. Si seul mois et "
    "année sont visibles (ex 05/2027), utilise le premier jour du mois "
    "(2027-05-01). Si absente, `null`.\n"
    "- `exp` : date de péremption au format ISO `YYYY-MM-DD`. Si seul mois et "
    "année sont visibles (ex 05/2027), utilise le dernier jour du mois "
    "(2027-05-31). Si absente, `null`.\n"
    "- `ppa` : Prix Public Algérien en DA (nombre décimal, sans symbole), ou `null`.\n"
    "- `designation` : nom commercial ou DCI du produit, ou `null`.\n\n"
    "Réponds UNIQUEMENT avec un JSON valide :\n"
    '{"lot": "..."|null, "fab": "YYYY-MM-DD"|null, "exp": "YYYY-MM-DD"|null, '
    '"ppa": 0.00|null, "designation": "..."|null}\n'
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


def _parse_date(
    value: object,
    *,
    month_default: Literal["first", "last"] = "last",
) -> date | None:
    """Parse heterogeneous date strings to a `date`.

    When only month + year are present, fill the day with either the first
    (typical for fabrication dates) or last (typical for expiry) day of the month.
    """
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
        day = 1 if month_default == "first" else _last_day(year, month)
        try:
            return date(year, month, day)
        except ValueError:
            return None

    m = _YEAR_MONTH_RE.match(s)
    if m:
        year, month = int(m.group(1)), int(m.group(2))
        day = 1 if month_default == "first" else _last_day(year, month)
        try:
            return date(year, month, day)
        except ValueError:
            return None

    return None


_DECIMAL_STRIP_RE = re.compile(r"[^\d,.\-]")


def _parse_decimal(value: object) -> Decimal | None:
    """Parse heterogeneous numeric strings to Decimal.

    Handles "DA" suffix, spaces, FR comma decimals ("450,50"), dot thousands
    ("1.250,00"), and US-style ("1,250.00").
    """
    if value is None:
        return None
    if isinstance(value, Decimal):
        return value
    if isinstance(value, (int, float)):
        try:
            return Decimal(str(value))
        except InvalidOperation:
            return None
    if not isinstance(value, str):
        return None
    s = _DECIMAL_STRIP_RE.sub("", value).strip()
    if not s:
        return None
    if "," in s and "." in s:
        # Whichever appears last is the decimal separator
        if s.rfind(",") > s.rfind("."):
            s = s.replace(".", "").replace(",", ".")
        else:
            s = s.replace(",", "")
    elif "," in s:
        s = s.replace(",", ".")
    try:
        return Decimal(s)
    except InvalidOperation:
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
        # NB : pas de response_format — le provider Baidu (ernie vision) renvoie
        # un 400 quand il est présent ; _extract_json tolère déjà le texte libre.
        "temperature": 0.0,
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

    lot = parsed.get("lot")
    lot = str(lot).strip()[:64] if lot else None
    desig = parsed.get("designation")
    desig = str(desig).strip()[:500] if desig else None

    return VignetteExtraction(
        lot=lot or None,
        fab=_parse_date(parsed.get("fab"), month_default="first"),
        exp=_parse_date(parsed.get("exp"), month_default="last"),
        ppa=_parse_decimal(parsed.get("ppa")),
        designation=desig or None,
        raw=content_str[:4000],
    )
