"""JSON 文件读写工具。"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def read_json_file(path: Path, default: Any) -> Any:
    """读取 JSON 文件，不存在则返回 default。"""
    if not path.exists():
        return default
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def write_json_file(path: Path, data: Any) -> None:
    """写入 JSON 文件。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)
