#!/usr/bin/env bash
# 推荐试玩入口：Chrome（规避 iOS 模拟器启动问题）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/app"
flutter pub get
API_URL="${API_BASE_URL:-http://localhost:5050}"
echo ">>> Chrome 试玩 | API: ${API_URL}"
echo ">>> 请确保另一终端已运行: bash scripts/start_backend.sh"
flutter run -d chrome --dart-define=API_BASE_URL="$API_URL"
