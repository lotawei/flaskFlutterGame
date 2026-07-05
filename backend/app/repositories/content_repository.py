"""内容数据访问层（当前为内存 mock，后续接 DB/CDN）。"""
from __future__ import annotations

from typing import Any


class ContentRepository:
    """梗包与 manifest 数据仓库。"""

    def fetch_manifest(self, client_version: str | None) -> dict[str, Any]:
        """获取内容 manifest。"""
        return {
            "schema_version": 1,
            "server_version": "2026.07.03.1",
            "client_version": client_version,
            "packs": [
                {
                    "pack_id": "demo_haqi_highland",
                    "name": "哈基高原（Demo）",
                    "version": "1.0.0",
                    "checksum": "sha256:demo",
                    "download_url": "https://cdn.example.com/packs/demo.zip",
                    "size_bytes": 102400,
                    "deprecated": False,
                },
            ],
        }
