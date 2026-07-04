"""认证 API。"""
from __future__ import annotations

import logging

from flask import Blueprint, current_app, g, request

from app.api.response import error_response, success_response
from app.auth.decorators import require_auth
from app.config import AppConfig
from app.observability.logger import get_logger, log_event
from app.repositories.user_repository import UserRepository
from app.services.auth_service import AuthService

auth_bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")
_logger = get_logger("api.auth")


def _build_service() -> AuthService:
    config: AppConfig = current_app.config["APP_CONFIG"]
    return AuthService(config=config, user_repository=UserRepository(config.data_dir))


@auth_bp.post("/register")
def register():
    body: dict | None = request.get_json(silent=True)
    if body is None:
        return error_response(40001, "请求体无效", 400)
    service = _build_service()
    try:
        result = service.register(
            username=str(body.get("username", "")),
            password=str(body.get("password", "")),
            display_name=body.get("display_name"),
        )
        log_event(
            _logger,
            logging.INFO,
            "auth.register.completed",
            "用户注册成功",
            user_id=result["user"]["user_id"],
            username=result["user"]["username"],
        )
        return success_response(result, "注册成功")
    except ValueError as exc:
        code_map = {
            "USERNAME_TAKEN": (40104, "用户名已被占用", 409),
            "VALIDATION_ERROR": (40001, "用户名或密码格式无效", 400),
        }
        code, message, status = code_map.get(str(exc), (50000, "内部服务错误", 500))
        return error_response(code, message, status)


@auth_bp.post("/login")
def login():
    body: dict | None = request.get_json(silent=True)
    if body is None:
        return error_response(40001, "请求体无效", 400)
    service = _build_service()
    try:
        result = service.login(
            username=str(body.get("username", "")),
            password=str(body.get("password", "")),
        )
        log_event(
            _logger,
            logging.INFO,
            "auth.login.completed",
            "用户登录成功",
            user_id=result["user"]["user_id"],
            username=result["user"]["username"],
        )
        return success_response(result, "登录成功")
    except ValueError as exc:
        if str(exc) == "INVALID_CREDENTIALS":
            return error_response(40103, "用户名或密码错误", 401)
        return error_response(50000, "内部服务错误", 500)


@auth_bp.get("/me")
@require_auth
def me():
    service = _build_service()
    user = g.current_user
    try:
        profile = service.get_profile(user_id=user["user_id"])
        return success_response(profile)
    except ValueError:
        return error_response(40105, "用户不存在", 404)
