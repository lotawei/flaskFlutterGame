#!/usr/bin/env bash
# 启动 Flask 后端（默认端口 5050，规避 macOS AirPlay 占用 5000）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/backend"
PY_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
echo ">>> Python ${PY_VERSION}"
JWT_UTILS="$ROOT/backend/app/auth/jwt_utils.py"
if grep -q "from datetime import UTC" "$JWT_UTILS" 2>/dev/null; then
  echo ">>> 错误: 代码仍是旧版（不兼容 Python 3.9）"
  echo ">>> 请先执行: git pull origin cursor/account-system-ec4c"
  echo ">>> 或手动把 jwt_utils.py 里的 datetime.UTC 改为 timezone.utc"
  exit 1
fi
if ! python3 -c "import flask, jwt" 2>/dev/null; then
  echo ">>> 安装 Python 依赖..."
  pip3 install -r requirements.txt
fi
PORT="${PORT:-5050}"
export PORT
export PYTHONPATH=.
echo ">>> 后端启动: http://127.0.0.1:${PORT}"
echo ">>> 健康检查: curl http://127.0.0.1:${PORT}/health"
python3 run.py
