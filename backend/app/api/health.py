"""健康检查 API。"""
from __future__ import annotations

from flask import Blueprint, current_app

from app.api.response import success_response
from app.services.health_service import HealthService

health_bp = Blueprint("health", __name__)


@health_bp.get("/health")
def health_check():
    config = current_app.config["APP_CONFIG"]
    service = HealthService(config)
    return success_response(service.check_health())


@health_bp.get("/ready")
def readiness_check():
    return success_response({"ready": True})
