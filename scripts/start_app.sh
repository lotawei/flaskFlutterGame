#!/usr/bin/env bash
# 启动 Flutter 客户端（默认连接 localhost:5050）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/app"
flutter pub get
API_URL="${API_BASE_URL:-http://localhost:5050}"
DEVICE="${FLUTTER_DEVICE:-chrome}"
echo ">>> API: ${API_URL}"
echo ">>> 设备: ${DEVICE}"
flutter run -d "$DEVICE" --dart-define=API_BASE_URL="$API_URL"
