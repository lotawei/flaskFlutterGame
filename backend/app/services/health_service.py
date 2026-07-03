"""健康检查服务。"""
from __future__ import annotations

from typing import Any

from app.config import AppConfig


class HealthService:
    """运维域：健康探测，不含业务逻辑。"""

    def __init__(self, config: AppConfig) -> None:
        self._config: AppConfig = config

    def check_health(self) -> dict[str, Any]:
        """返回服务健康状态。"""
        return {
            "status": "ok",
            "service": self._config.service_name,
        }
