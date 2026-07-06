"""关卡数据访问。"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class LevelRepository:
    """关卡 JSON 文件仓库。"""

    def __init__(self, data_dir: Path | None = None) -> None:
        self._data_dir: Path = data_dir or Path(__file__).resolve().parents[1] / "data" / "levels"

    def fetch_level(self, level_id: str) -> dict[str, Any]:
        """读取关卡 JSON。"""
        level_path: Path = self._data_dir / f"{level_id}.json"
        if not level_path.exists():
            raise FileNotFoundError(f"关卡不存在: {level_id}")
        with level_path.open("r", encoding="utf-8") as file:
            return json.load(file)
