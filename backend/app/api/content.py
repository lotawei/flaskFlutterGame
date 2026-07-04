"""内容 API：manifest 等。"""
from __future__ import annotations

import logging

from flask import Blueprint, request

from app.api.response import error_response, success_response
from app.observability.logger import get_logger, log_event
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
        manifest = _service.get_manifest(client_version)
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
