"""JWT 签发与校验。"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

import jwt

from app.config import AppConfig


def create_access_token(
    *,
    config: AppConfig,
    user_id: str,
    username: str,
) -> tuple[str, int]:
    """签发访问令牌，返回 (token, expires_in_seconds)。"""
    expires_in: int = config.jwt_expire_hours * 3600
    payload: dict[str, Any] = {
        "sub": user_id,
        "username": username,
        "exp": datetime.now(tz=timezone.utc) + timedelta(seconds=expires_in),
        "iat": datetime.now(tz=timezone.utc),
    }
    token: str = jwt.encode(payload, config.jwt_secret, algorithm="HS256")
    return token, expires_in


def decode_access_token(*, config: AppConfig, token: str) -> dict[str, Any]:
    """解码并校验访问令牌。"""
    return jwt.decode(token, config.jwt_secret, algorithms=["HS256"])
