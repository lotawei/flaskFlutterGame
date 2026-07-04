"""用户数据仓库（JSON 文件）。"""
from __future__ import annotations

import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from werkzeug.security import check_password_hash, generate_password_hash

from app.repositories.json_store import read_json_file, write_json_file


class UserRepository:
    """用户账号持久化。"""

    def __init__(self, data_dir: Path) -> None:
        self._path = data_dir / "users.json"
        self._ensure_demo_user()

    def _load(self) -> dict[str, Any]:
        return read_json_file(
            self._path,
            default={"users_by_id": {}, "username_index": {}},
        )

    def _save(self, data: dict[str, Any]) -> None:
        write_json_file(self._path, data)

    def _ensure_demo_user(self) -> None:
        data = self._load()
        if "demo" in data.get("username_index", {}):
            return
        user_id = f"user-{uuid.uuid4().hex[:12]}"
        now = datetime.now(tz=UTC).isoformat()
        record = {
            "user_id": user_id,
            "username": "demo",
            "display_name": "Demo 玩家",
            "password_hash": generate_password_hash("demo123456"),
            "created_at": now,
        }
        data.setdefault("users_by_id", {})[user_id] = record
        data.setdefault("username_index", {})["demo"] = user_id
        self._save(data)

    def create_user(
        self,
        *,
        username: str,
        password: str,
        display_name: str | None = None,
    ) -> dict[str, Any]:
        """注册新用户。"""
        data = self._load()
        username_index: dict[str, str] = data.setdefault("username_index", {})
        if username in username_index:
            raise ValueError("USERNAME_TAKEN")
        user_id = f"user-{uuid.uuid4().hex[:12]}"
        now = datetime.now(tz=UTC).isoformat()
        record = {
            "user_id": user_id,
            "username": username,
            "display_name": display_name or username,
            "password_hash": generate_password_hash(password),
            "created_at": now,
        }
        data.setdefault("users_by_id", {})[user_id] = record
        username_index[username] = user_id
        self._save(data)
        return self._to_profile(record)

    def find_by_username(self, username: str) -> dict[str, Any] | None:
        data = self._load()
        user_id = data.get("username_index", {}).get(username)
        if not user_id:
            return None
        return data.get("users_by_id", {}).get(user_id)

    def find_by_id(self, user_id: str) -> dict[str, Any] | None:
        data = self._load()
        return data.get("users_by_id", {}).get(user_id)

    def verify_credentials(self, *, username: str, password: str) -> dict[str, Any] | None:
        record = self.find_by_username(username)
        if record is None:
            return None
        if not check_password_hash(record["password_hash"], password):
            return None
        return self._to_profile(record)

    @staticmethod
    def _to_profile(record: dict[str, Any]) -> dict[str, Any]:
        return {
            "user_id": record["user_id"],
            "username": record["username"],
            "display_name": record["display_name"],
            "created_at": record["created_at"],
        }
