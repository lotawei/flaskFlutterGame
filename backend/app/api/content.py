"""内容 API：manifest 等。"""
from __future__ import annotations

import logging

from flask import Blueprint, current_app, request

from app.api.response import error_response, success_response
from app.auth.decorators import resolve_user_from_request
from app.config import AppConfig
from app.observability.logger import get_logger, log_event
from app.repositories.progress_repository import ProgressRepository
from app.repositories.user_repository import UserRepository
from app.services.content_service import ContentService

content_bp = Blueprint("content", __name__, url_prefix="/api/v1/content")
_logger = get_logger("api.content")
_service = ContentService()


@content_bp.get("/manifest")
def get_manifest():
    client_version: str | None = request.args.get("client_version")
    log_event(
        _logger,
        logging.INFO,
        "api.content.manifest.requested",
        "客户端请求 manifest",
        client_version=client_version,
    )
    try:
        user_summary = _build_user_summary()
        manifest = _service.get_manifest(client_version, user_summary=user_summary)
        return success_response(manifest)
    except Exception as exc:
        log_event(
            _logger,
            logging.ERROR,
            "api.content.manifest.error",
            f"manifest 查询异常: {exc}",
            error_type=type(exc).__name__,
        )
        return error_response(50000, "内部服务错误", 500)


def _build_user_summary() -> dict | None:
    user = resolve_user_from_request()
    if user is None:
        return None
    config: AppConfig = current_app.config["APP_CONFIG"]
    profile = UserRepository(config.data_dir).find_by_id(user["user_id"])
    if profile is None:
        return None
    progress = ProgressRepository(config.data_dir).get_user_progress(user["user_id"])
    return {
        "user_id": profile["user_id"],
        "username": profile["username"],
        "display_name": profile["display_name"],
        "summary": progress["summary"],
    }
