#!/usr/bin/env bash
# 本地联调：检查依赖 + 跑测试（不启动长驻进程）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ">>> [1/4] 后端依赖 & 测试"
cd "$ROOT/backend"
pip3 install -q -r requirements.txt
PYTHONPATH=. pytest -q

echo ">>> [2/4] Flutter 依赖 & 测试"
cd "$ROOT/app"
flutter pub get
flutter test

echo ">>> [3/4] 关卡 JSON 校验"
cd "$ROOT"
if python3 -c "import jsonschema" 2>/dev/null; then
  python3 scripts/validate_level.py
else
  pip3 install -q jsonschema
  python3 scripts/validate_level.py
fi

echo ">>> [4/4] 全部通过"
echo ""
echo "启动方式（开两个终端）："
echo "  终端1: bash scripts/start_backend.sh"
echo "  终端2: bash scripts/start_app.sh"
echo ""
echo "体验账号: demo / demo123456"
