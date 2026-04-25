"""Integration tests for the per-ligne vignette OCR endpoints.

Mirrors the harness used elsewhere in this directory: the tests skip when
the live API isn't reachable. OCR-dependent assertions are gated on
`DIMED_RUN_LIVE_OCR=1` to avoid burning the OpenRouter free quota during CI.

Structural tests (auth, role, format, size) run without OCR.
"""

from __future__ import annotations

import os
import struct
import uuid
import zlib

import httpx
import pytest

pytestmark = pytest.mark.asyncio


def _tiny_png() -> bytes:
    sig = b"\x89PNG\r\n\x1a\n"

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))

    ihdr = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    raw = b"\x00\xff\x00\x00"
    idat = zlib.compress(raw)
    return sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")


async def _login(client: httpx.AsyncClient, email: str) -> None:
    r = await client.post("/auth/login", json={"email": email, "password": "dimed"})
    if r.status_code != 200:
        pytest.skip(f"login {email} failed (seeds missing?): {r.status_code} {r.text}")


async def _pick_preparation_line(client: httpx.AsyncClient) -> tuple[str, str] | None:
    """Return (commande_id, ligne_id) for the first line of a preparation order."""
    r = await client.get("/commandes/", params={"limit": 20})
    if r.status_code != 200:
        return None
    for c in r.json().get("commandes", []):
        if c.get("statut") in ("en_preparation", "prelevee_partiellement"):
            cid = c["id"]
            lr = await client.get(f"/commandes/{cid}/lignes")
            if lr.status_code != 200:
                continue
            lignes = lr.json().get("lignes", [])
            if lignes:
                return cid, lignes[0]["id"]
    return None


async def test_per_ligne_scan_requires_auth(live_api: httpx.AsyncClient) -> None:
    cid = str(uuid.uuid4())
    lid = str(uuid.uuid4())
    r = await live_api.post(
        f"/commandes/{cid}/lignes/{lid}/vignette",
        files={"file": ("v.png", _tiny_png(), "image/png")},
    )
    assert r.status_code in (401, 403)


async def test_per_ligne_scan_forbidden_for_livreur(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "livreur@dimed.dz")
    cid = str(uuid.uuid4())
    lid = str(uuid.uuid4())
    r = await live_api.post(
        f"/commandes/{cid}/lignes/{lid}/vignette",
        files={"file": ("v.png", _tiny_png(), "image/png")},
    )
    assert r.status_code == 403, r.text


async def test_per_ligne_scan_rejects_non_image(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "preparateur@dimed.dz")
    pair = await _pick_preparation_line(live_api)
    if not pair:
        pytest.skip("No preparation order with lines available")
    cid, lid = pair
    r = await live_api.post(
        f"/commandes/{cid}/lignes/{lid}/vignette",
        files={"file": ("v.txt", b"hello", "text/plain")},
    )
    assert r.status_code == 415, r.text


async def test_per_ligne_scan_rejects_oversized(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "preparateur@dimed.dz")
    pair = await _pick_preparation_line(live_api)
    if not pair:
        pytest.skip("No preparation order with lines available")
    cid, lid = pair
    payload = b"\x89PNG\r\n\x1a\n" + b"\x00" * (10 * 1024 * 1024 + 1)
    r = await live_api.post(
        f"/commandes/{cid}/lignes/{lid}/vignette",
        files={"file": ("big.png", payload, "image/png")},
    )
    assert r.status_code == 413, r.text


async def test_per_ligne_clear_404_when_no_vignette(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "preparateur@dimed.dz")
    pair = await _pick_preparation_line(live_api)
    if not pair:
        pytest.skip("No preparation order with lines available")
    cid, lid = pair
    # Ensure the line has no vignette: we hit DELETE; either 404 (no vignette)
    # or 204 (had one — re-running will give 404 next time). We assert the
    # endpoint responds with one of those two.
    r = await live_api.delete(f"/commandes/{cid}/lignes/{lid}/vignette")
    assert r.status_code in (204, 404), r.text


@pytest.mark.skipif(
    os.environ.get("DIMED_RUN_LIVE_OCR") != "1",
    reason="Set DIMED_RUN_LIVE_OCR=1 to exercise a real OpenRouter call.",
)
async def test_per_ligne_scan_live_ocr(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "preparateur@dimed.dz")
    pair = await _pick_preparation_line(live_api)
    if not pair:
        pytest.skip("No preparation order with lines available")
    cid, lid = pair

    img_path = os.environ.get("DIMED_SAMPLE_VIGNETTE")
    if not img_path:
        pytest.skip("Set DIMED_SAMPLE_VIGNETTE=/path/to/real/vignette.jpg")
    with open(img_path, "rb") as fh:
        data = fh.read()

    r = await live_api.post(
        f"/commandes/{cid}/lignes/{lid}/vignette",
        files={"file": ("vignette.jpg", data, "image/jpeg")},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert "ligne" in body
    assert "vignette" in body
    assert "warnings" in body
    assert isinstance(body["warnings"], list)
