"""进度业务服务。"""
from __future__ import annotations

from typing import Any

from app.repositories.progress_repository import ProgressRepository


class ProgressService:
    """关卡进度与对局上报。"""

    def __init__(self, *, progress_repository: ProgressRepository) -> None:
        self._progress = progress_repository

    def get_progress(self, *, user_id: str) -> dict[str, Any]:
        return self._progress.get_user_progress(user_id)

    def submit_session(
        self,
        *,
        user_id: str,
        payload: dict[str, Any],
    ) -> dict[str, Any]:
        level_id = str(payload.get("level_id", "")).strip()
        if not level_id:
            raise ValueError("VALIDATION_ERROR")
        reason = str(payload.get("reason", "")).strip()
        allowed = {"victory", "fellOff", "hitByEnemy", "timeUp", "fakeGoal"}
        if reason not in allowed:
            raise ValueError("VALIDATION_ERROR")
        return self._progress.submit_session(
            user_id=user_id,
            level_id=level_id,
            reason=reason,
            coins=int(payload.get("coins", 0)),
            total_coins=int(payload.get("total_coins", 0)),
            seconds=float(payload.get("seconds", 0)),
            stars=int(payload.get("stars", 0)),
            defeated_enemies=int(payload.get("defeated_enemies", 0)),
            trace_id=payload.get("trace_id"),
        )
