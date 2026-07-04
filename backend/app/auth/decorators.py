"""鉴权装饰器。"""
from __future__ import annotations

from functools import wraps
from typing import Any, Callable

import jwt
from flask import current_app, g, request

from app.api.response import error_response
from app.auth.jwt_utils import decode_access_token
from app.config import AppConfig


def _read_bearer_token() -> str | None:
    auth_header: str | None = request.headers.get("Authorization")
    if not auth_header:
        return None
    parts = auth_header.split(" ", 1)
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    return parts[1].strip() or None


def resolve_user_from_request() -> dict[str, str] | None:
    """从 Authorization 解析用户，失败返回 None。"""
    token = _read_bearer_token()
    if not token:
        return None
    config: AppConfig = current_app.config["APP_CONFIG"]
    try:
        payload = decode_access_token(config=config, token=token)
    except jwt.ExpiredSignatureError:
        g.auth_error_code = 40102
        return None
    except Exception:
        g.auth_error_code = 40101
        return None
    user_id = payload.get("sub")
    username = payload.get("username")
    if not user_id or not username:
        g.auth_error_code = 40101
        return None
    return {"user_id": str(user_id), "username": str(username)}


def require_auth(handler: Callable[..., Any]) -> Callable[..., Any]:
    """要求登录的装饰器。"""

    @wraps(handler)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        user = resolve_user_from_request()
        if user is None:
            code = getattr(g, "auth_error_code", 40101)
            message = "登录已过期" if code == 40102 else "未登录或令牌无效"
            return error_response(code, message, 401)
        g.current_user = user
        return handler(*args, **kwargs)

    return wrapper
