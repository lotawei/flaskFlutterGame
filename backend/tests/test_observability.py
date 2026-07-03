"""后端可观测性与 API 测试。"""
from __future__ import annotations

import logging

import pytest


@pytest.fixture
def caplog_info(caplog):
    caplog.set_level(logging.INFO)
    return caplog


def test_health_returns_ok(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.get_json()
    assert body["code"] == 0
    assert body["data"]["status"] == "ok"


def test_manifest_returns_packs(client):
    response = client.get(
        "/api/v1/content/manifest",
        headers={"X-Trace-Id": "test-trace-001"},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["code"] == 0
    assert len(body["data"]["packs"]) >= 1
    assert response.headers.get("X-Trace-Id") == "test-trace-001"
    assert response.headers.get("X-Request-Id")


def test_manifest_emits_flow_events(client, caplog_info):
    caplog_info.set_level(logging.INFO)
    client.get("/api/v1/content/manifest?client_version=1.0.0")
    logged_text = " ".join(record.message for record in caplog_info.records)
    assert "content.manifest.fetch" in logged_text or "manifest" in logged_text
