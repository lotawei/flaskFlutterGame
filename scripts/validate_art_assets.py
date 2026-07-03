#!/usr/bin/env python3
"""校验美术资产交付清单。"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "shared" / "art" / "asset_manifest.json"
IMAGE_ROOT = ROOT / "app" / "assets" / "images"


def main() -> int:
    if not MANIFEST.exists():
        print(f"缺少清单: {MANIFEST}")
        return 1
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    errors: list[str] = []
    for item in data.get("assets", []):
        rel_path = item.get("path", "")
        if rel_path and not (IMAGE_ROOT / rel_path).exists():
            errors.append(f"缺失资产: {rel_path}")
        meta = item.get("meta")
        if meta and not (IMAGE_ROOT / meta).exists():
            errors.append(f"缺失元数据: {meta}")
    if errors:
        for err in errors:
            print(err)
        return 1
    print(f"资产校验通过，共 {len(data.get('assets', []))} 项")
    return 0


if __name__ == "__main__":
    sys.exit(main())
