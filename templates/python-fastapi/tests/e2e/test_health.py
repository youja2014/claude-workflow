from __future__ import annotations

import pytest
from httpx import ASGITransport, AsyncClient

from __package__.main import app

pytestmark = pytest.mark.e2e


async def test_health_returns_ok() -> None:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/api/v1/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
