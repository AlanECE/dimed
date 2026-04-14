"""OCR service — calls a free vision LLM via OpenRouter to parse a picking sheet scan.

We send the scanned image along with the list of expected `code_article` and
`designation` values for the commande, and ask the model to return a strict JSON
array of lines it could read. Each detected entry references a `code_article`
and a `qte_prelevee` integer. The caller matches those back to `LigneCommande`
rows and flips `ocr_verifie` on the matches.

The model is intentionally given the allowed code list so it can snap its reads
to valid values even if the scan is low-quality, and so the prompt stays small.
"""

import base64
import json
import logging
import re
from dataclasses import dataclass

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


@dataclass
class OcrLineHint:
    ligne_id: str
    code_article: str
    designation: str
    qte_demandee: int


@dataclass
class OcrMatch:
    ligne_id: str
    code_article: str
    qte_prelevee: int | None


class OcrConfigurationError(RuntimeError):
    """Raised when DIMED_OPENROUTER_API_KEY is missing."""


class OcrUpstreamError(RuntimeError):
    """Raised when the OpenRouter call fails or the payload is unparseable."""


_SYSTEM_PROMPT = (
    "Tu es un assistant OCR spécialisé dans les bons de prélèvement pharmaceutiques "
    "scannés à la main par un préparateur. Ta seule tâche : identifier les lignes "
    "cochées ou validées sur l'image et renvoyer un JSON strict."
)


def _build_user_prompt(hints: list[OcrLineHint]) -> str:
    lines = "\n".join(
        f"- code={h.code_article}  qte_demandee={h.qte_demandee}  designation={h.designation[:60]}"
        for h in hints
    )
    return (
        "Voici la liste des articles attendus pour cette commande "
        "(utilise uniquement ces `code` dans ta réponse) :\n"
        f"{lines}\n\n"
        "Analyse l'image du bon de prélèvement. Pour chaque ligne que tu lis "
        "avec une coche, un visa manuscrit, ou une quantité notée, renvoie un "
        'objet `{"code_article": str, "qte_prelevee": int|null}`. '
        "Si une ligne n'est ni cochée ni annotée, ne la renvoie pas.\n\n"
        "Réponds UNIQUEMENT avec un JSON valide de la forme :\n"
        '{"matches": [{"code_article": "...", "qte_prelevee": 12}, ...]}\n'
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


async def parse_prelevement_scan(
    image_bytes: bytes,
    content_type: str,
    hints: list[OcrLineHint],
) -> list[OcrMatch]:
    if not settings.openrouter_api_key:
        raise OcrConfigurationError("DIMED_OPENROUTER_API_KEY is not set — cannot call OCR service")
    if not hints:
        return []

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
                    {"type": "text", "text": _build_user_prompt(hints)},
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
        "X-Title": "DIMED Preparation OCR",
    }

    url = f"{settings.openrouter_base_url.rstrip('/')}/chat/completions"
    try:
        async with httpx.AsyncClient(timeout=settings.ocr_timeout_seconds) as client:
            response = await client.post(url, json=payload, headers=headers)
    except httpx.HTTPError as exc:
        raise OcrUpstreamError(f"OpenRouter request failed: {exc}") from exc

    if response.status_code >= 400:
        raise OcrUpstreamError(f"OpenRouter returned {response.status_code}: {response.text[:300]}")

    try:
        body = response.json()
        content = body["choices"][0]["message"]["content"]
    except (KeyError, IndexError, ValueError) as exc:
        raise OcrUpstreamError(f"Unexpected OpenRouter payload: {exc}") from exc

    parsed = _extract_json(content if isinstance(content, str) else str(content))
    raw_matches = parsed.get("matches") or []
    if not isinstance(raw_matches, list):
        raise OcrUpstreamError("'matches' is not a list")

    by_code: dict[str, OcrLineHint] = {h.code_article: h for h in hints}
    out: list[OcrMatch] = []
    seen: set[str] = set()
    for item in raw_matches:
        if not isinstance(item, dict):
            continue
        code = str(item.get("code_article") or "").strip()
        if not code or code in seen:
            continue
        hint = by_code.get(code)
        if hint is None:
            logger.warning("OCR returned unknown code_article=%s", code)
            continue
        qte_raw = item.get("qte_prelevee")
        qte: int | None
        try:
            qte = int(qte_raw) if qte_raw is not None else None
        except (TypeError, ValueError):
            qte = None
        seen.add(code)
        out.append(OcrMatch(ligne_id=hint.ligne_id, code_article=code, qte_prelevee=qte))

    return out
