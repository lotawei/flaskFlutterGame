#!/usr/bin/env python3
"""批量校验关卡 JSON（Schema + 业务规则）。"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    print("请先安装依赖: pip install -r scripts/requirements.txt", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "shared" / "level" / "level_schema_v2.json"
LEVEL_ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]{2,48}$")


def load_schema() -> dict:
    with SCHEMA_PATH.open(encoding="utf-8") as file:
        return json.load(file)


def collect_level_files(paths: list[str]) -> list[Path]:
    files: list[Path] = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            files.extend(sorted(path.glob("*.json")))
        elif path.is_file():
            files.append(path)
    return files


def validate_business_rules(level: dict) -> list[str]:
    issues: list[str] = []
    level_id = level.get("level_id", "")
    if not LEVEL_ID_PATTERN.match(level_id):
        issues.append(f"level_id 格式非法: {level_id}")
    platforms = level.get("platforms") or []
    if not platforms:
        issues.append("至少需要一个 platform")
    spawn = level.get("player_spawn") or {}
    width = level.get("width_tiles", 0)
    height = level.get("height_tiles", 0)
    if spawn.get("x", 0) >= width or spawn.get("y", 0) >= height:
        issues.append("player_spawn 超出地图范围")
    archetype = level.get("archetype", "rush_standard")
    if archetype == "reversal_trap" and not level.get("fake_goals"):
        issues.append("reversal_trap 关需要 fake_goals")
    if archetype == "timed_rush":
        mechanics = level.get("mechanics") or []
        has_timer = any(item.get("type") == "time_limit" for item in mechanics)
        if not has_timer:
            issues.append("timed_rush 关需要 time_limit 机制")
    win_rules = level.get("win_rules") or []
    if not win_rules:
        issues.append("至少一条 win_rules")
    return issues


def validate_file(schema: dict, file_path: Path) -> list[str]:
    issues: list[str] = []
    try:
        with file_path.open(encoding="utf-8") as file:
            level = json.load(file)
    except json.JSONDecodeError as err:
        return [f"JSON 解析失败: {err}"]
    if "REPLACE_" in file_path.name:
        return [f"跳过模板文件: {file_path.name}"]
    try:
        jsonschema.validate(instance=level, schema=schema)
    except jsonschema.ValidationError as err:
        issues.append(f"Schema: {err.message}")
    issues.extend(validate_business_rules(level))
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="校验关卡 JSON")
    parser.add_argument(
        "paths",
        nargs="*",
        default=[
            str(ROOT / "app" / "assets" / "levels"),
            str(ROOT / "backend" / "app" / "data" / "levels"),
        ],
        help="关卡文件或目录",
    )
    args = parser.parse_args()
    schema = load_schema()
    files = collect_level_files(args.paths)
    if not files:
        print("未找到关卡文件", file=sys.stderr)
        return 1
    failed = 0
    for file_path in files:
        issues = validate_file(schema, file_path)
        if issues:
            failed += 1
            print(f"FAIL {file_path}")
            for issue in issues:
                print(f"  - {issue}")
        else:
            print(f"OK   {file_path}")
    print(f"\n共 {len(files)} 个文件，{failed} 个失败")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
