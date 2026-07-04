#!/usr/bin/env bash
# 启动 Flask 后端（默认端口 5050，规避 macOS AirPlay 占用 5000）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/backend"
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
