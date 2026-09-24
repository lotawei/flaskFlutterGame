#!/usr/bin/env bash
# 一键：Blender 无头烘焙 → 像素降采样 → 校验 manifest
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if ! command -v blender >/dev/null 2>&1; then
  echo "ERROR: blender not found. Install Blender 4.x or enable PATH."
  exit 1
fi

export BAKE_TARGETS="${BAKE_TARGETS:-ceiling,ground,platform,portal,coin,enemy}"
echo "== Blender bake: $BAKE_TARGETS =="
blender --background --python "$ROOT/scripts/blender/bake_pixel_sprites.py"

echo "== Pixelate =="
python3 "$ROOT/scripts/blender/pixelate_bake_output.py"

echo "== Validate =="
python3 "$ROOT/scripts/validate_art_assets.py"
echo "OK: Blender pipeline finished."
