"""关卡 API。"""
from __future__ import annotations

import logging

from flask import Blueprint

from app.api.response import error_response, success_response
from app.observability.logger import get_logger, log_event
from app.repositories.level_repository import LevelRepository as LevelFileRepository
from app.services.level_service import LevelService

levels_bp = Blueprint("levels", __name__, url_prefix="/api/v1/content/levels")
_logger = get_logger("api.levels")
_service = LevelService(LevelFileRepository())


@levels_bp.get("/<level_id>")
def get_level(level_id: str):
    log_event(
        _logger,
        logging.INFO,
        "api.content.level.requested",
        "客户端请求关卡",
        level_id=level_id,
    )
    try:
        level_data = _service.get_level(level_id)
        return success_response(level_data)
    except FileNotFoundError:
        return error_response(10004, f"关卡不存在: {level_id}", 404)
    except Exception as exc:
        log_event(
            _logger,
            logging.ERROR,
            "api.content.level.error",
            f"关卡查询异常: {exc}",
            level_id=level_id,
        )
        return error_response(50000, "内部服务错误", 500)
