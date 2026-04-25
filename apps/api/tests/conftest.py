"""Shared pytest fixtures for DIMED API tests.

Service-layer tests run offline and mock HTTPX via respx. Integration tests
target the live Docker API at `DIMED_API_URL` (default http://localhost:8000)
and are skipped automatically if that URL is unreachable.
"""

from __future__ import annotations

import os

import httpx
import pytest


@pytest.fixture
def api_url() -> str:
    return os.environ.get("DIMED_API_URL", "http://localhost:8000")


@pytest.fixture
async def live_api(api_url: str) -> httpx.AsyncClient:
    """Async client for integration tests — skipped if the API is down."""
    try:
        async with httpx.AsyncClient(base_url=api_url, timeout=10.0) as probe:
            r = await probe.get("/health")
            if r.status_code != 200:
                pytest.skip(f"API at {api_url} returned {r.status_code}")
    except httpx.HTTPError as exc:
        pytest.skip(f"API at {api_url} unreachable: {exc}")

    async with httpx.AsyncClient(base_url=api_url, timeout=30.0) as client:
        yield client


@pytest.fixture
async def preparateur_cookies(live_api: httpx.AsyncClient) -> dict[str, str]:
    r = await live_api.post(
        "/auth/login",
        json={"email": "preparateur@dimed.dz", "password": "dimed"},
    )
    if r.status_code != 200:
        pytest.skip(f"preparateur seed login failed: {r.status_code} {r.text}")
    return {k: v for k, v in r.cookies.items()}
