"""Integration tests for the expedition module (colis, pads de tir, scans).

Mirrors the live-API harness used elsewhere in this directory: every test
skips automatically when the API at DIMED_API_URL is unreachable. The full
end-to-end flow drives a real order through préparation → contrôle (création
des colis + étiquettes) → mise sur pad (magasinier) → scan chargement →
validation camion → scan livraison.
"""

from __future__ import annotations

import uuid

import httpx
import pytest

pytestmark = pytest.mark.asyncio


async def _login(client: httpx.AsyncClient, email: str) -> None:
    r = await client.post("/auth/login", json={"email": email, "password": "dimed"})
    if r.status_code != 200:
        pytest.skip(f"login {email} failed (seeds missing?): {r.status_code} {r.text}")


# ---------------------------------------------------------------------------
# Structural tests (auth / roles / 404)
# ---------------------------------------------------------------------------


async def test_lookup_requires_auth(live_api: httpx.AsyncClient) -> None:
    r = await live_api.get("/expedition/colis/CLS00000001")
    assert r.status_code in (401, 403)


async def test_lookup_forbidden_for_pharmacien(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "pharmacien@dimed.dz")
    r = await live_api.get("/expedition/colis/CLS00000001")
    assert r.status_code == 403, r.text


async def test_unknown_colis_404(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "magasinier@dimed.dz")
    r = await live_api.get("/expedition/colis/CLS99999999")
    assert r.status_code == 404, r.text


async def test_pads_seeded_and_listed(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "magasinier@dimed.dz")
    r = await live_api.get("/expedition/pads")
    assert r.status_code == 200, r.text
    pads = r.json()["pads"]
    assert len(pads) >= 1
    codes = {p["code"] for p in pads}
    assert "PAD-01" in codes


async def test_pad_creation_forbidden_for_magasinier(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "magasinier@dimed.dz")
    r = await live_api.post("/expedition/pads", json={"code": "PAD-XX", "nom": "Interdit"})
    assert r.status_code == 403, r.text


async def test_validate_control_requires_nb_colis(live_api: httpx.AsyncClient) -> None:
    await _login(live_api, "controleur@dimed.dz")
    r = await live_api.patch(f"/commandes/{uuid.uuid4()}/validate-control", json={})
    assert r.status_code == 422, r.text


# ---------------------------------------------------------------------------
# Full end-to-end flow
# ---------------------------------------------------------------------------


async def _prepare_order_until_verification(live_api: httpx.AsyncClient) -> str | None:
    """Create + accept + prepare + finalize an order. Returns commande_id or None."""
    await _login(live_api, "operatrice@dimed.dz")

    pharmaciens = (await live_api.get("/commandes/pharmaciens")).json().get("pharmaciens", [])
    if not pharmaciens:
        return None
    pharmacien_id = pharmaciens[0]["id"]

    meds_r = await live_api.get("/medicaments/", params={"limit": 50})
    if meds_r.status_code != 200:
        return None
    meds = [m for m in meds_r.json().get("medicaments", []) if m.get("stock_quantity", 0) >= 2]
    if len(meds) < 2:
        return None

    create_r = await live_api.post(
        "/commandes/",
        json={
            "pharmacien_id": pharmacien_id,
            "articles": [
                {"medicament_id": meds[0]["id"], "qte": 2},
                {"medicament_id": meds[1]["id"], "qte": 1},
            ],
        },
    )
    if create_r.status_code not in (200, 201):
        return None
    commande_id = create_r.json()["id"]

    accept_r = await live_api.patch(f"/commandes/{commande_id}/accept")
    if accept_r.status_code != 200:
        return None

    # Préparation
    await _login(live_api, "preparateur@dimed.dz")
    pool_r = await live_api.get("/commandes/caddies/pool/available")
    pool = pool_r.json().get("items", []) if pool_r.status_code == 200 else []
    if not pool:
        return None
    start_r = await live_api.patch(
        f"/commandes/{commande_id}/start-preparation",
        json={"caddie_pool_id": pool[0]["id"]},
    )
    if start_r.status_code != 200:
        return None

    lignes = (await live_api.get(f"/commandes/{commande_id}/lignes")).json()["lignes"]
    for ligne in lignes:
        ur = await live_api.patch(
            f"/commandes/{commande_id}/update-ligne/{ligne['id']}",
            json={"qte_prelevee": ligne["qte_demandee"], "verifie": True},
        )
        if ur.status_code != 200:
            return None

    fin_r = await live_api.patch(f"/commandes/{commande_id}/finalize-preparation")
    if fin_r.status_code != 200:
        return None
    return commande_id


async def test_full_expedition_flow(live_api: httpx.AsyncClient) -> None:
    commande_id = await _prepare_order_until_verification(live_api)
    if not commande_id:
        pytest.skip("Could not drive an order to EN_VERIFICATION (missing seeds?)")

    # --- Contrôle : camion + validate-control crée les colis -----------------
    await _login(live_api, "controleur@dimed.dz")
    camions = (await live_api.get("/camions/")).json().get("camions", [])
    if not camions:
        await _login(live_api, "operatrice@dimed.dz")
        cr = await live_api.post(
            "/camions/",
            json={"nom": "Camion Test", "plaque": f"TST-{uuid.uuid4().hex[:6]}"},
        )
        if cr.status_code not in (200, 201):
            pytest.skip("No camion available and cannot create one")
        camions = [cr.json()]
        await _login(live_api, "controleur@dimed.dz")

    assign_r = await live_api.patch(
        f"/commandes/{commande_id}/assign-camion",
        json={"camion_id": camions[0]["id"]},
    )
    assert assign_r.status_code == 200, assign_r.text

    validate_r = await live_api.patch(
        f"/commandes/{commande_id}/validate-control",
        json={"nb_colis": 3},
    )
    assert validate_r.status_code == 200, validate_r.text

    colis_r = await live_api.get(f"/expedition/commandes/{commande_id}/colis")
    assert colis_r.status_code == 200, colis_r.text
    colis = colis_r.json()["colis"]
    assert len(colis) == 3
    assert all(k["numero"].startswith("CLS") for k in colis)
    assert all(k["statut"] == "etiquete" for k in colis)
    numeros = [k["numero"] for k in colis]

    # Double validation interdite (colis déjà créés → 409)
    r409 = await live_api.patch(
        f"/commandes/{commande_id}/validate-control",
        json={"nb_colis": 2},
    )
    assert r409.status_code == 409, r409.text

    # --- Étiquettes PDF -------------------------------------------------------
    etiq_r = await live_api.get(f"/expedition/commandes/{commande_id}/etiquettes")
    assert etiq_r.status_code == 200, etiq_r.text
    assert etiq_r.headers["content-type"].startswith("application/pdf")
    assert len(etiq_r.content) > 1000

    # --- Magasinier : lookup + suggestion + dépôt sur pad ---------------------
    await _login(live_api, "magasinier@dimed.dz")

    look0 = (await live_api.get(f"/expedition/colis/{numeros[0]}")).json()
    assert look0["index_colis"] == 1
    assert look0["nb_colis"] == 3
    assert look0["statut"] == "etiquete"
    assert look0["pharmacien_nom"]
    assert look0["contenu"], "le contenu (fallback commande complète) doit être renseigné"
    assert look0["contenu_detaille"] is False
    assert look0["pad_suggere"] is not None
    pad_id = look0["pad_suggere"]["id"]

    dep0 = await live_api.post(
        f"/expedition/colis/{numeros[0]}/depose-pad",
        json={"pad_tir_id": pad_id},
    )
    assert dep0.status_code == 200, dep0.text

    # Le 2e colis de la même commande doit être imposé sur le même pad
    look1 = (await live_api.get(f"/expedition/colis/{numeros[1]}")).json()
    assert look1["pad_impose"] is True
    assert look1["pad_suggere"]["id"] == pad_id

    for numero in numeros[1:]:
        dep = await live_api.post(
            f"/expedition/colis/{numero}/depose-pad",
            json={"pad_tir_id": pad_id},
        )
        assert dep.status_code == 200, dep.text

    # Occupation visible dans la vue des pads
    pads = (await live_api.get("/expedition/pads")).json()["pads"]
    pad_view = next(p for p in pads if p["id"] == pad_id)
    refs = {c["commande_ref"]: c for c in pad_view["commandes"]}
    commande_ref = look0["commande_ref"]
    assert commande_ref in refs
    assert refs[commande_ref]["poses"] == 3
    assert refs[commande_ref]["total"] == 3

    # --- Chargement : validation impossible tant que tout n'est pas scanné ---
    await _login(live_api, "operatrice@dimed.dz")
    feuilles = (await live_api.get("/documents/feuilles-route")).json()["feuilles"]
    feuille_id = next(
        (
            f["id"]
            for f in feuilles
            if any(c["reference_id"] == commande_ref for c in f["commandes"])
        ),
        None,
    )
    assert feuille_id, "la commande doit être liée à une feuille de route"

    vl1 = await live_api.patch(f"/documents/feuilles-route/{feuille_id}/validate-loading", json={})
    assert vl1.status_code == 200, vl1.text
    body1 = vl1.json()
    assert body1["ok"] is False
    nos_manquants = next((m for m in body1["manquants"] if m["commande_ref"] == commande_ref), None)
    assert nos_manquants is not None
    assert set(nos_manquants["colis"]) == set(numeros)

    # --- Scan chargement progressif -------------------------------------------
    s0 = (await live_api.post(f"/expedition/colis/{numeros[0]}/scan-chargement")).json()
    assert s0["charges"] == 1 and s0["total"] == 3
    assert s0["commande_complete"] is False

    # Re-scan du même colis : idempotent
    s0b = (await live_api.post(f"/expedition/colis/{numeros[0]}/scan-chargement")).json()
    assert s0b["deja_scanne"] is True
    assert s0b["charges"] == 1

    for numero in numeros[1:]:
        last = (await live_api.post(f"/expedition/colis/{numero}/scan-chargement")).json()
    assert last["charges"] == 3
    assert last["commande_complete"] is True

    # État temps réel du camion
    charg = (await live_api.get(f"/expedition/feuilles-route/{feuille_id}/chargement")).json()
    notre = next(c for c in charg["commandes"] if c["commande_ref"] == commande_ref)
    assert notre["charges"] == 3 and notre["total"] == 3

    # La validation ne liste plus notre commande en manquants
    vl2 = await live_api.patch(f"/documents/feuilles-route/{feuille_id}/validate-loading", json={})
    assert vl2.status_code == 200, vl2.text
    body2 = vl2.json()
    assert all(m["commande_ref"] != commande_ref for m in body2["manquants"])

    # --- Livraison : signatures de la feuille puis re-scan des colis ----------
    fake_signature = (
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ"
        "AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    )
    for sig_type in ("expedition", "chauffeur"):
        sig_r = await live_api.patch(
            f"/documents/feuilles-route/{feuille_id}/sign",
            json={"type": sig_type, "signature": fake_signature},
        )
        assert sig_r.status_code == 200, sig_r.text

    start_r = await live_api.patch(f"/commandes/{commande_id}/start-delivery")
    assert start_r.status_code == 200, start_r.text

    for numero in numeros:
        sl = (await live_api.post(f"/expedition/colis/{numero}/scan-livraison")).json()
    assert sl["livres"] == 3
    assert sl["commande_complete"] is True

    final = (await live_api.get(f"/expedition/colis/{numeros[0]}")).json()
    assert final["statut"] == "livre"
