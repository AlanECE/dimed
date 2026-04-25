"""Service-layer tests for the vignette OCR pipeline (respx-mocked)."""

from __future__ import annotations

from datetime import date

import httpx
import pytest
import respx

from app.config import settings
from app.ocr.service import (
    OcrConfigurationError,
    OcrUpstreamError,
    extract_vignette_fields,
)

_OPENROUTER_URL = f"{settings.openrouter_base_url.rstrip('/')}/chat/completions"

_FAKE_IMAGE = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01"  # minimal JPEG-ish magic bytes


def _mock_reply(content: str) -> dict:
    return {
        "id": "mock",
        "object": "chat.completion",
        "choices": [{"index": 0, "message": {"role": "assistant", "content": content}}],
    }


@pytest.fixture(autouse=True)
def _set_openrouter_key(monkeypatch):
    monkeypatch.setattr(settings, "openrouter_api_key", "sk-test")
    yield


async def test_extract_happy_path() -> None:
    payload = '{"dlc":"2027-05-31","code_article":"ABC123","designation":"Doliprane 1g"}'
    with respx.mock(assert_all_called=True) as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")

    assert result.dlc == date(2027, 5, 31)
    assert result.code_article == "ABC123"
    assert result.designation == "Doliprane 1g"
    assert "ABC123" in result.raw


async def test_extract_month_year_rolls_to_last_day() -> None:
    payload = '{"dlc":"05/2027","code_article":null,"designation":null}'
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert result.dlc == date(2027, 5, 31)
    assert result.code_article is None
    assert result.designation is None


async def test_extract_fenced_json() -> None:
    payload = '```json\n{"dlc":"2028-01-31","code_article":"XYZ","designation":null}\n```'
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert result.dlc == date(2028, 1, 31)
    assert result.code_article == "XYZ"


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


async def test_extract_dlc_null() -> None:
    payload = '{"dlc":null,"code_article":"A1","designation":"Aspegic"}'
    with respx.mock() as mock:
        mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        result = await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
    assert result.dlc is None
    assert result.code_article == "A1"


async def test_extract_sends_authorization_header() -> None:
    payload = '{"dlc":"2027-05-31","code_article":null,"designation":null}'
    with respx.mock(assert_all_called=True) as mock:
        route = mock.post(_OPENROUTER_URL).respond(200, json=_mock_reply(payload))
        await extract_vignette_fields(_FAKE_IMAGE, "image/jpeg")
        sent = route.calls.last.request
        assert sent.headers["Authorization"] == "Bearer sk-test"
        assert sent.headers["X-Title"] == "DIMED Vignette OCR"
