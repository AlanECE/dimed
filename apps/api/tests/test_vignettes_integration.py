"""End-to-end integration tests against the live Docker API.

These exercise the full HTTP surface: auth, order creation, preparation flow,
vignette upload / assign / delete. The OpenRouter call is NOT mocked here —
to avoid burning the free quota, this test uploads only one vignette in the
happy path and ONLY runs when `DIMED_RUN_LIVE_OCR=1` is set AND a real
`DIMED_OPENROUTER_API_KEY` is configured on the API side.

Other (non-OCR) tests only need the API + DB up.
"""

from __future__ import annotations

import io
import os
import struct
import uuid
import zlib

import httpx
import pytest

pytestmark = pytest.mark.asyncio


def _tiny_png() -> bytes:
    """Build a 1x1 valid PNG without third-party deps."""
    sig = b"\x89PNG\r\n\x1a\n"

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))

    ihdr = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    raw = b"\x00\xff\x00\x00"  # filter byte + RGB pixel
    idat = zlib.compress(raw)
    return sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")


async def _login(client: httpx.AsyncClient, email: str) -> None:
    r = await client.post("/auth/login", json={"email": email, "password": "dimed"})
    assert r.status_code == 200, r.text


async def _pick_order_in_preparation(client: httpx.AsyncClient) -> str | None:
    r = await client.get("/commandes/", params={"limit": 20})
    assert r.status_code == 200
    for c in r.json().get("commandes", []):
        if c.get("statut") in ("en_preparation", "prelevee_partiellement"):
            return c["id"]
    return None


async def test_vignette_upload_requires_auth(live_api: httpx.AsyncClient) -> None:
    fake_id = str(uuid.uuid4())
    r = await live_api.post(
        f"/commandes/{fake_id}/vignettes",
        files={"file": ("v.png", _tiny_png(), "image/png")},
    )
    assert r.status_code in (401, 403)


async def test_vignette_upload_forbidden_for_livreur(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "livreur@dimed.dz")
    fake_id = str(uuid.uuid4())
    r = await live_api.post(
        f"/commandes/{fake_id}/vignettes",
        files={"file": ("v.png", _tiny_png(), "image/png")},
    )
    assert r.status_code == 403, r.text


async def test_vignette_list_returns_empty_when_none(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "preparateur@dimed.dz")
    order_id = await _pick_order_in_preparation(live_api)
    if not order_id:
        pytest.skip("No preparateur order in progress to list vignettes for")
    r = await live_api.get(f"/commandes/{order_id}/vignettes")
    assert r.status_code == 200
    assert isinstance(r.json().get("vignettes"), list)


async def test_vignette_upload_rejects_bad_mime(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "preparateur@dimed.dz")
    order_id = await _pick_order_in_preparation(live_api)
    if not order_id:
        pytest.skip("No preparateur order in progress to upload to")
    r = await live_api.post(
        f"/commandes/{order_id}/vignettes",
        files={"file": ("v.txt", b"hello", "text/plain")},
    )
    assert r.status_code == 400


@pytest.mark.skipif(
    os.environ.get("DIMED_RUN_LIVE_OCR") != "1",
    reason="Set DIMED_RUN_LIVE_OCR=1 to exercise a real OpenRouter call.",
)
async def test_vignette_upload_live_ocr(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "preparateur@dimed.dz")
    order_id = await _pick_order_in_preparation(live_api)
    if not order_id:
        pytest.skip("No preparateur order in progress for live OCR")

    img_path = os.environ.get("DIMED_SAMPLE_VIGNETTE")
    if not img_path:
        pytest.skip("Set DIMED_SAMPLE_VIGNETTE=/path/to/real/vignette.jpg")
    with open(img_path, "rb") as fh:
        data = fh.read()

    r = await live_api.post(
        f"/commandes/{order_id}/vignettes",
        files={"file": ("vignette.jpg", io.BytesIO(data), "image/jpeg")},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert "id" in body
    assert "path" in body
    # DLC may be None if the model fails to read it, but the record must exist
    assert body["commande_id"] == order_id
