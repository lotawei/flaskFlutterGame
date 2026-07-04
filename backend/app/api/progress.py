"""用户进度 API。"""
from __future__ import annotations

import logging

from flask import Blueprint, current_app, g, request

from app.api.response import error_response, success_response
from app.auth.decorators import require_auth
from app.config import AppConfig
from app.observability.logger import get_logger, log_event
from app.repositories.progress_repository import ProgressRepository
from app.services.progress_service import ProgressService

progress_bp = Blueprint("progress", __name__, url_prefix="/api/v1/users/me")
_logger = get_logger("api.progress")


def _build_service() -> ProgressService:
    config: AppConfig = current_app.config["APP_CONFIG"]
    return ProgressService(progress_repository=ProgressRepository(config.data_dir))


@progress_bp.get("/progress")
@require_auth
def get_progress():
    service = _build_service()
    user = g.current_user
    data = service.get_progress(user_id=user["user_id"])
    log_event(
        _logger,
        logging.INFO,
        "progress.fetch.completed",
        "拉取用户进度",
        user_id=user["user_id"],
        played_levels=data["summary"]["played_levels"],
    )
    return success_response(data)


@progress_bp.post("/sessions")
@require_auth
def submit_session():
    body: dict | None = request.get_json(silent=True)
    if body is None:
        return error_response(40001, "请求体无效", 400)
    service = _build_service()
    user = g.current_user
    try:
        result = service.submit_session(user_id=user["user_id"], payload=body)
        log_event(
            _logger,
            logging.INFO,
            "game.session.submitted",
            "对局结果已上报",
            user_id=user["user_id"],
            level_id=body.get("level_id"),
            reason=body.get("reason"),
            stars=body.get("stars"),
            trace_id=body.get("trace_id"),
        )
        return success_response(result, "对局已记录")
    except ValueError:
        return error_response(40001, "对局数据无效", 400)
