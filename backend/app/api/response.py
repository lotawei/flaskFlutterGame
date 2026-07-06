"""统一 API 响应格式。"""
from __future__ import annotations

from typing import Any

from flask import jsonify


def success_response(data: Any = None, message: str = "ok") -> tuple[Any, int]:
    """成功响应。"""
    payload: dict[str, Any] = {
        "code": 0,
        "message": message,
        "data": data,
    }
    return jsonify(payload), 200


def error_response(code: int, message: str, http_status: int = 400) -> tuple[Any, int]:
    """错误响应。"""
    payload: dict[str, Any] = {
        "code": code,
        "message": message,
        "data": None,
    }
    return jsonify(payload), http_status
