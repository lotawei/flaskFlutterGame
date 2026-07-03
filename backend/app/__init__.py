"""Flask 应用工厂。"""
from __future__ import annotations

import logging

from flask import Flask
from flask_cors import CORS

from app.api.content import content_bp
from app.api.health import health_bp
from app.api.levels import levels_bp
from app.config import AppConfig, load_config
from app.middleware.request_context import register_request_context_middleware
from app.observability.logger import get_logger, log_event, setup_logging


def create_app(config: AppConfig | None = None) -> Flask:
    """创建并配置 Flask 应用。"""
    app_config: AppConfig = config or load_config()
    setup_logging(app_config)
    app = Flask(__name__)
    app.config["JSON_AS_ASCII"] = False
    app.config["APP_CONFIG"] = app_config
    CORS(app, expose_headers=["X-Trace-Id", "X-Request-Id"])
    register_request_context_middleware(app)
    app.register_blueprint(health_bp)
    app.register_blueprint(content_bp)
    app.register_blueprint(levels_bp)
    startup_logger = get_logger("app.startup")
    log_event(
        startup_logger,
        logging.INFO,
        "app.startup.completed",
        "Flask 应用初始化完成",
        service=app_config.service_name,
        log_level=app_config.log_level,
    )
    return app
