"""内容业务服务：manifest 查询与版本比对。"""
from __future__ import annotations

from typing import Any

import logging

from app.observability.logger import get_logger, log_event
from app.observability.tracer import FlowTracer
from app.repositories.content_repository import ContentRepository


class ContentService:
    """内容域业务边界：仅处理梗包/manifest 相关逻辑。"""

    def __init__(self, repository: ContentRepository | None = None) -> None:
        self._repository: ContentRepository = repository or ContentRepository()
        self._logger = get_logger("services.content")

    def get_manifest(
        self,
        client_version: str | None,
        user_summary: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """拉取 manifest，含完整业务流追踪。"""
        tracer = FlowTracer("services.content", "content.manifest.fetch")
        with tracer.step("validate_input", client_version=client_version):
            normalized_version: str | None = client_version.strip() if client_version else None
        with tracer.step("load_from_repository", client_version=normalized_version):
            manifest: dict[str, Any] = self._repository.fetch_manifest(normalized_version)
        if user_summary is not None:
            manifest["user"] = user_summary
        with tracer.step("build_response"):
            pack_count: int = len(manifest.get("packs", []))
            log_event(
                self._logger,
                logging.INFO,
                "content.manifest.fetch.summary",
                "manifest 组装完成",
                pack_count=pack_count,
                server_version=manifest.get("server_version"),
            )
        return manifest
