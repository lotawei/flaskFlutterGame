"""认证业务服务。"""
from __future__ import annotations

import re
from typing import Any

from app.auth.jwt_utils import create_access_token
from app.config import AppConfig
from app.repositories.user_repository import UserRepository

_USERNAME_PATTERN = re.compile(r"^[a-zA-Z0-9_]{3,32}$")


class AuthService:
    """注册、登录、当前用户。"""

    def __init__(self, *, config: AppConfig, user_repository: UserRepository) -> None:
        self._config = config
        self._users = user_repository

    def register(
        self,
        *,
        username: str,
        password: str,
        display_name: str | None = None,
    ) -> dict[str, Any]:
        self._validate_credentials(username=username, password=password)
        try:
            profile = self._users.create_user(
                username=username.strip(),
                password=password,
                display_name=display_name.strip() if display_name else None,
            )
        except ValueError as exc:
            if str(exc) == "USERNAME_TAKEN":
                raise ValueError("USERNAME_TAKEN") from exc
            raise
        return self._build_token_response(profile)

    def login(self, *, username: str, password: str) -> dict[str, Any]:
        profile = self._users.verify_credentials(username=username.strip(), password=password)
        if profile is None:
            raise ValueError("INVALID_CREDENTIALS")
        return self._build_token_response(profile)

    def get_profile(self, *, user_id: str) -> dict[str, Any]:
        record = self._users.find_by_id(user_id)
        if record is None:
            raise ValueError("USER_NOT_FOUND")
        return UserRepository._to_profile(record)

    def _build_token_response(self, profile: dict[str, Any]) -> dict[str, Any]:
        token, expires_in = create_access_token(
            config=self._config,
            user_id=profile["user_id"],
            username=profile["username"],
        )
        return {
            "access_token": token,
            "token_type": "Bearer",
            "expires_in": expires_in,
            "user": profile,
        }

    @staticmethod
    def _validate_credentials(*, username: str, password: str) -> None:
        if not _USERNAME_PATTERN.match(username.strip()):
            raise ValueError("VALIDATION_ERROR")
        if len(password) < 6:
            raise ValueError("VALIDATION_ERROR")
