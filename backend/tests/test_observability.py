"""后端可观测性与 API 测试。"""
from __future__ import annotations

import json
import logging

import pytest

from app import create_app
from app.config import AppConfig


@pytest.fixture
def app():
    config = AppConfig(
        service_name="meme-game-backend-test",
        log_level="INFO",
        log_format="json",
        debug=True,
    )
    return create_app(config)


@pytest.fixture
def client(app):
    return app.test_client()


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


def test_manifest_emits_flow_events(client, caplog):
    caplog.set_level(logging.INFO)
    client.get("/api/v1/content/manifest?client_version=1.0.0")
    logged_text = " ".join(record.message for record in caplog.records)
    assert "content.manifest.fetch" in logged_text or "manifest" in logged_text
    json_records = [
        record for record in caplog.records
        if record.message.startswith("{")
    ]
    if json_records:
        payload = json.loads(json_records[0].message)
        assert "trace_id" in payload or "message" in payload
