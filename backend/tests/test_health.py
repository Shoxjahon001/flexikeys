from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_returns_200(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert "status" in body
    assert "checks" in body
    assert "db" in body["checks"]
    assert "redis" in body["checks"]


@pytest.mark.asyncio
async def test_version_returns_200(client: AsyncClient) -> None:
    response = await client.get("/version")
    assert response.status_code == 200
    body = response.json()
    assert "version" in body