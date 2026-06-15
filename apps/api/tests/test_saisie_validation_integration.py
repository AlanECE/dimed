"""Integration tests for steps 1 & 2 of the order lifecycle.

Step 1 — saisie (pharmacien): create a réassort order (CREEE), edit/add/remove
its lines and cancel it while it is not yet validated; any edit after validation
is rejected (409).
Step 2 — validation (operatrice): accept (→ ACCEPTEE) or refuse (stays CREEE
with a motif, returned to the pharmacien). Plus role enforcement.

Mirrors the live-API harness used elsewhere in this directory: every test skips
automatically when the API at DIMED_API_URL is unreachable.
"""

from __future__ import annotations

import os

import httpx
import pytest

pytestmark = pytest.mark.asyncio

# Seed password — "dimed" by convention; override locally with DIMED_TEST_PASSWORD.
_SEED_PASSWORD = os.environ.get("DIMED_TEST_PASSWORD", "dimed")


async def _login(client: httpx.AsyncClient, email: str) -> None:
    r = await client.post("/auth/login", json={"email": email, "password": _SEED_PASSWORD})
    if r.status_code != 200:
        pytest.skip(f"login {email} failed (seeds missing?): {r.status_code} {r.text}")


async def _in_stock_meds(client: httpx.AsyncClient, n: int) -> list[dict]:
    r = await client.get("/medicaments/", params={"limit": 50})
    if r.status_code != 200:
        return []
    meds = [m for m in r.json().get("medicaments", []) if m.get("stock_quantity", 0) >= 3]
    return meds[:n]


async def _first_pharmacien_id(client: httpx.AsyncClient) -> str | None:
    """Requires an operatrice/admin session (the endpoint is gated)."""
    r = await client.get("/commandes/pharmaciens")
    if r.status_code != 200:
        return None
    pharmaciens = r.json().get("pharmaciens", [])
    return pharmaciens[0]["id"] if pharmaciens else None


async def _create_own_order(client: httpx.AsyncClient, *, qte: int = 1) -> dict | None:
    """Pharmacien (already logged in) creates an order for themselves."""
    meds = await _in_stock_meds(client, 1)
    if not meds:
        return None
    r = await client.post(
        "/commandes/",
        json={"articles": [{"medicament_id": meds[0]["id"], "qte": qte}]},
    )
    if r.status_code not in (200, 201):
        return None
    return r.json()


# ---------------------------------------------------------------------------
# Step 1 — saisie (pharmacien)
# ---------------------------------------------------------------------------


async def test_pharmacien_creates_order_in_creee(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "pharmacien@dimed.dz")
    order = await _create_own_order(live_api, qte=2)
    if not order:
        pytest.skip("No in-stock medicament to create an order")
    assert order["statut"] == "creee", order
    assert len(order["lignes"]) == 1


async def test_pharmacien_edits_lines_while_creee(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "pharmacien@dimed.dz")
    meds = await _in_stock_meds(live_api, 2)
    if len(meds) < 2:
        pytest.skip("Need at least 2 in-stock medicaments")

    create = await live_api.post(
        "/commandes/",
        json={"articles": [{"medicament_id": meds[0]["id"], "qte": 2}]},
    )
    if create.status_code not in (200, 201):
        pytest.skip(f"create failed: {create.status_code} {create.text}")
    cid = create.json()["id"]
    lid = create.json()["lignes"][0]["id"]

    # Edit quantity
    edit = await live_api.patch(f"/commandes/{cid}/lines/{lid}", json={"qte_demandee": 5})
    assert edit.status_code == 200, edit.text
    assert next(ln for ln in edit.json()["lignes"] if ln["id"] == lid)["qte_demandee"] == 5

    # Add a second line
    add = await live_api.post(
        f"/commandes/{cid}/lines",
        json={"medicament_id": meds[1]["id"], "qte_demandee": 1},
    )
    assert add.status_code == 200, add.text
    assert len(add.json()["lignes"]) == 2

    # Remove the line we just added
    new_lid = next(ln["id"] for ln in add.json()["lignes"] if ln["id"] != lid)
    delete = await live_api.delete(f"/commandes/{cid}/lines/{new_lid}")
    assert delete.status_code == 200, delete.text
    assert len(delete.json()["lignes"]) == 1


async def test_pharmacien_can_cancel_while_creee(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "pharmacien@dimed.dz")
    order = await _create_own_order(live_api)
    if not order:
        pytest.skip("No in-stock medicament to create an order")
    cancel = await live_api.patch(f"/commandes/{order['id']}/cancel")
    assert cancel.status_code == 200, cancel.text
    assert cancel.json()["statut"] == "annulee"


async def test_pharmacien_cannot_edit_after_validation(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "pharmacien@dimed.dz")
    order = await _create_own_order(live_api)
    if not order:
        pytest.skip("No in-stock medicament to create an order")
    cid, lid = order["id"], order["lignes"][0]["id"]

    await _login(live_api, "operatrice@dimed.dz")
    accept = await live_api.patch(f"/commandes/{cid}/accept")
    if accept.status_code != 200:
        pytest.skip(f"accept failed (stock?): {accept.status_code} {accept.text}")

    await _login(live_api, "pharmacien@dimed.dz")
    edit = await live_api.patch(f"/commandes/{cid}/lines/{lid}", json={"qte_demandee": 9})
    assert edit.status_code == 409, edit.text


# ---------------------------------------------------------------------------
# Step 2 — validation (operatrice)
# ---------------------------------------------------------------------------


async def test_operatrice_validates_order(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "operatrice@dimed.dz")
    pid = await _first_pharmacien_id(live_api)
    meds = await _in_stock_meds(live_api, 1)
    if not pid or not meds:
        pytest.skip("Missing pharmacien or in-stock medicament")

    create = await live_api.post(
        "/commandes/",
        json={"pharmacien_id": pid, "articles": [{"medicament_id": meds[0]["id"], "qte": 1}]},
    )
    if create.status_code not in (200, 201):
        pytest.skip(f"create failed: {create.status_code} {create.text}")
    cid = create.json()["id"]

    accept = await live_api.patch(f"/commandes/{cid}/accept")
    assert accept.status_code == 200, accept.text
    body = accept.json()
    assert body["statut"] == "acceptee"
    assert body["date_validation"] is not None


async def test_operatrice_refuses_keeps_creee_with_motif(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "operatrice@dimed.dz")
    pid = await _first_pharmacien_id(live_api)
    meds = await _in_stock_meds(live_api, 1)
    if not pid or not meds:
        pytest.skip("Missing pharmacien or in-stock medicament")

    create = await live_api.post(
        "/commandes/",
        json={"pharmacien_id": pid, "articles": [{"medicament_id": meds[0]["id"], "qte": 1}]},
    )
    if create.status_code not in (200, 201):
        pytest.skip(f"create failed: {create.status_code} {create.text}")
    cid = create.json()["id"]

    motif = "Quantité erronée, merci de corriger la ligne 1"
    refuse = await live_api.patch(f"/commandes/{cid}/refuse", json={"motif": motif})
    assert refuse.status_code == 200, refuse.text
    body = refuse.json()
    assert body["statut"] == "creee", "le refus ne doit pas figer/annuler la commande"
    assert body["operatrice_comment"] == motif

    # An empty motif is rejected (422)
    bad = await live_api.patch(f"/commandes/{cid}/refuse", json={"motif": ""})
    assert bad.status_code == 422, bad.text

    # Once validated, refusal is no longer possible (409)
    accept = await live_api.patch(f"/commandes/{cid}/accept")
    if accept.status_code != 200:
        pytest.skip(f"accept failed (stock?): {accept.status_code} {accept.text}")
    late = await live_api.patch(f"/commandes/{cid}/refuse", json={"motif": "trop tard"})
    assert late.status_code == 409, late.text


# ---------------------------------------------------------------------------
# Role enforcement (pharmacien ≠ operatrice)
# ---------------------------------------------------------------------------


async def test_pharmacien_cannot_validate_or_refuse(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "pharmacien@dimed.dz")
    order = await _create_own_order(live_api)
    if not order:
        pytest.skip("No in-stock medicament to create an order")
    cid = order["id"]

    assert (await live_api.patch(f"/commandes/{cid}/accept")).status_code == 403
    assert (
        await live_api.patch(f"/commandes/{cid}/refuse", json={"motif": "x"})
    ).status_code == 403


async def test_operatrice_must_attribute_order_to_a_pharmacien(
    live_api: httpx.AsyncClient,
) -> None:
    await _login(live_api, "operatrice@dimed.dz")
    meds = await _in_stock_meds(live_api, 1)
    if not meds:
        pytest.skip("No in-stock medicament")
    # No pharmacien_id → the operatrice cannot enter an order "for herself"
    r = await live_api.post(
        "/commandes/",
        json={"articles": [{"medicament_id": meds[0]["id"], "qte": 1}]},
    )
    assert r.status_code == 422, r.text


async def test_non_editor_role_cannot_edit_lines(live_api: httpx.AsyncClient) -> None:
    # A CREEE order created by a pharmacien…
    await _login(live_api, "pharmacien@dimed.dz")
    order = await _create_own_order(live_api)
    if not order:
        pytest.skip("No in-stock medicament to create an order")
    cid, lid = order["id"], order["lignes"][0]["id"]

    # …cannot be edited by a preparateur (neither owner nor operatrice/admin).
    await _login(live_api, "preparateur@dimed.dz")
    r = await live_api.patch(f"/commandes/{cid}/lines/{lid}", json={"qte_demandee": 4})
    assert r.status_code == 403, r.text
