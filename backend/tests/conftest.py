"""Pytest 共享 fixtures。"""
from __future__ import annotations

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
