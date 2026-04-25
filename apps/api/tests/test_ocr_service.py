"""Service-layer tests for the vignette OCR pipeline (respx-mocked)."""

from __future__ import annotations

from datetime import date
from decimal import Decimal

import httpx
import pytest
import respx

from app.config import settings
from app.ocr.service import (
    OcrConfigurationError,
    OcrUpstreamError,
    _parse_date,
    _parse_decimal,
    extract_vignette_fields,
)

_OPENROUTER_URL = f"{settings.openrouter_base_url.rstrip('/')}/chat/completions"

_FAKE_IMAGE = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01"


def _mock_reply(content: str) -> dict:
    return {
        "id": "mock",
        "object": "chat.completion",
        "choices": [{"index": 0, "message": {"role": "assistant", "content": content}}],
    }


def _full_payload(
    *,
    lot: str | None = "LOT-A1",
    fab: str | None = "2025-01-15",
    exp: str | None = "2027-05-31",
    ppa: float | None = 450.00,
    designation: str | None = "Doliprane 1g",
) -> str:
    import json as _json

    return _json.dumps({"lot": lot, "fab": fab, "exp": exp, "ppa": ppa, "designation": designation})


@pytest.fixture(autouse=True)
def _set_openrouter_key(monkeypatch):
    monkeypatch.setattr(settings, "openrouter_api_key", "sk-test")
    yield


# ---- _parse_date ----------------------------------------------------------


def test_parse_date_iso() -> None:
    assert _parse_date("2027-05-31") == date(2027, 5, 31)


def test_parse_date_exp_last_day_default() -> None:
    assert _parse_date("05/2027") == date(2027, 5, 31)


def test_parse_date_fab_first_day_when_requested() -> None:
    assert _parse_date("05/2027", month_default="first") == date(2027, 5, 1)


def test_parse_date_year_month_dash() -> None:
    assert _parse_date("2027-05") == date(2027, 5, 31)
    assert _parse_date("2027-05", month_default="first") == date(2027, 5, 1)


def test_parse_date_garbage_returns_none() -> None:
    assert _parse_date("n/a") is None
    assert _parse_date(None) is None
    assert _parse_date(42) is None


# ---- _parse_decimal -------------------------------------------------------


def test_parse_decimal_handles_da_suffix() -> None:
    assert _parse_decimal("1 250,00 DA") == Decimal("1250.00")


def test_parse_decimal_handles_dot_thousands_fr() -> None:
    assert _parse_decimal("1.250,00") == Decimal("1250.00")


def test_parse_decimal_handles_us_thousands() -> None:
    assert _parse_decimal("1,250.00") == Decimal("1250.00")


def test_parse_decimal_handles_plain_number_str() -> None:
    assert _parse_decimal("450.50") == Decimal("450.50")


def test_parse_decimal_handles_native_numbers() -> None:
    assert _parse_decimal(450) == Decimal("450")
    assert _parse_decimal(450.5) == Decimal("450.5")
    assert _parse_decimal(Decimal("12.34")) == Decimal("12.34")


def test_parse_decimal_returns_none_for_garbage() -> None:
    assert _parse_decimal("free") is None
    assert _parse_decimal("") is None
    assert _parse_decimal(None) is None


# ---- extract_vignette_fields ----------------------------------------------


async def test_extract_happy_path() -> None:
    with respx.mock(assert_all_called=True) as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(_full_payload()))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")

    assert result.lot == "LOT-A1"
    assert result.fab == date(2025, 1, 15)
    assert result.exp == date(2027, 5, 31)
    assert result.ppa == Decimal("450.00")
    assert result.designation == "Doliprane 1g"
    assert "LOT-A1" in result.raw


async def test_extract_month_year_fab_first_exp_last() -> None:
    payload = _full_payload(fab="01/2025", exp="05/2027")
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert result.fab == date(2025, 1, 1)
    assert result.exp == date(2027, 5, 31)


async def test_extract_fenced_json() -> None:
    payload = "```json\n" + _full_payload(lot="XYZ", ppa=99.99) + "\n```"
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert result.lot == "XYZ"
    assert result.ppa == Decimal("99.99")


async def test_extract_all_null_fields() -> None:
    payload = _full_payload(lot=None, fab=None, exp=None, ppa=None, designation=None)
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert result.lot is None
    assert result.fab is None
    assert result.exp is None
    assert result.ppa is None
    assert result.designation is None


async def test_extract_ppa_with_da_suffix_in_payload() -> None:
    # Some models stringify the price with units; we should still parse
    payload = '{"lot":"L","fab":null,"exp":null,"ppa":"1 250,00 DA","designation":null}'
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert result.ppa == Decimal("1250.00")


async def test_extract_missing_key(monkeypatch) -> None:
    monkeypatch.setattr(settings, "openrouter_api_key", "")
    with pytest.raises(OcrConfigurationError):
        await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")


async def test_extract_upstream_500() -> None:
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(500, text="oops")
        with pytest.raises(OcrUpstreamError) as exc:
            await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert "500" in str(exc.value)


async def test_extract_non_json_reply() -> None:
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply("no braces here"))
        with pytest.raises(OcrUpstreamError):
            await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")


async def test_extract_invalid_json() -> None:
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply("{ not : valid }"))
        with pytest.raises(OcrUpstreamError):
            await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")


async def test_extract_transport_error() -> None:
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).mock(side_effect=httpx.ConnectError("boom"))
        with pytest.raises(OcrUpstreamError):
            await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")


async def test_extract_sends_authorization_header() -> None:
    with respx.mock(assert_all_called=True) as mock:
        route = mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(_full_payload()))
        await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
        sent = route.calls.last.request
        assert sent.headers["Authorization"] == "Bearer sk-test"
        assert sent.headers["X-Title"] == "DIMED Vignette OCR"
