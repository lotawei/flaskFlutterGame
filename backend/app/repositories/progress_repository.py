"""用户关卡进度仓库。"""
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.repositories.json_store import read_json_file, write_json_file


class ProgressRepository:
    """按用户存储关卡进度与对局记录。"""

    def __init__(self, data_dir: Path) -> None:
        self._path = data_dir / "progress.json"

    def _load(self) -> dict[str, Any]:
        return read_json_file(self._path, default={"users": {}})

    def _save(self, data: dict[str, Any]) -> None:
        write_json_file(self._path, data)

    def get_user_progress(self, user_id: str) -> dict[str, Any]:
        data = self._load()
        user_data = data.get("users", {}).get(user_id, {})
        levels: dict[str, Any] = user_data.get("levels", {})
        summary = self._build_summary(levels)
        return {
            "user_id": user_id,
            "levels": levels,
            "summary": summary,
        }

    def submit_session(
        self,
        *,
        user_id: str,
        level_id: str,
        reason: str,
        coins: int,
        total_coins: int,
        seconds: float,
        stars: int,
        defeated_enemies: int,
        trace_id: str | None,
    ) -> dict[str, Any]:
        data = self._load()
        users = data.setdefault("users", {})
        user_data = users.setdefault(user_id, {"levels": {}, "sessions": []})
        levels: dict[str, Any] = user_data.setdefault("levels", {})
        now = datetime.now(tz=timezone.utc).isoformat()
        current = levels.get(level_id, {})
        is_victory = reason == "victory"
        updated = {
            "level_id": level_id,
            "best_stars": max(current.get("best_stars", 0), stars if is_victory else 0),
            "best_time_seconds": self._min_time(
                current.get("best_time_seconds"),
                seconds if is_victory else None,
            ),
            "best_coins": max(current.get("best_coins", 0), coins if is_victory else 0),
            "clear_count": current.get("clear_count", 0) + (1 if is_victory else 0),
            "fail_count": current.get("fail_count", 0) + (0 if is_victory else 1),
            "last_reason": reason,
            "last_played_at": now,
        }
        levels[level_id] = updated
        sessions: list[dict[str, Any]] = user_data.setdefault("sessions", [])
        sessions.append(
            {
                "level_id": level_id,
                "reason": reason,
                "coins": coins,
                "total_coins": total_coins,
                "seconds": seconds,
                "stars": stars,
                "defeated_enemies": defeated_enemies,
                "trace_id": trace_id,
                "played_at": now,
            }
        )
        if len(sessions) > 200:
            user_data["sessions"] = sessions[-200:]
        self._save(data)
        summary = self._build_summary(levels)
        return {
            "level_progress": updated,
            "summary": summary,
        }

    @staticmethod
    def _min_time(current: float | None, candidate: float | None) -> float | None:
        if candidate is None:
            return current
        if current is None:
            return candidate
        return min(current, candidate)

    @staticmethod
    def _build_summary(levels: dict[str, Any]) -> dict[str, Any]:
        total_stars = 0
        cleared_levels = 0
        for item in levels.values():
            total_stars += int(item.get("best_stars", 0))
            if int(item.get("clear_count", 0)) > 0:
                cleared_levels += 1
        return {
            "total_stars": total_stars,
            "cleared_levels": cleared_levels,
            "played_levels": len(levels),
        }
