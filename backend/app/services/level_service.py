"""关卡业务服务。"""
from __future__ import annotations

import logging
from typing import Any

from app.observability.logger import get_logger, log_event
from app.observability.tracer import FlowTracer
from app.repositories.level_repository import LevelRepository


class LevelService:
    """关卡域业务。"""

    def __init__(self, repository: LevelRepository) -> None:
        self._repository = repository
        self._logger = get_logger("services.level")

    def get_level(self, level_id: str) -> dict[str, Any]:
        """获取关卡配置。"""
        tracer = FlowTracer("services.level", "content.level.fetch")
        with tracer.step("load_file", level_id=level_id):
            level_data: dict[str, Any] = self._repository.fetch_level(level_id)
        log_event(
            self._logger,
            logging.INFO,
            "content.level.fetch.summary",
            "关卡读取完成",
            level_id=level_id,
            platform_count=len(level_data.get("platforms", [])),
        )
        return level_data
