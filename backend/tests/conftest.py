"""Pytest 共享 fixtures。"""
from __future__ import annotations

import tempfile
from pathlib import Path

import pytest

from app import create_app
from app.config import AppConfig


@pytest.fixture
def app():
    data_dir = Path(tempfile.mkdtemp(prefix="meme-test-"))
    config = AppConfig(
        service_name="meme-game-backend-test",
        log_level="INFO",
        log_format="json",
        debug=True,
        jwt_secret="test-jwt-secret",
        jwt_expire_hours=24,
        data_dir=data_dir,
    )
    return create_app(config)


@pytest.fixture
def client(app):
    return app.test_client()
