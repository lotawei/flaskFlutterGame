#!/usr/bin/env bash
# 修复 iOS 模拟器启动失败 (FBSOpenApplicationServiceErrorDomain / Launchd 163)
# 适用：macOS 26 + Xcode 26 + iOS 26.5 模拟器
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/app"
BUNDLE_ID="com.meme.game.memeGame"

echo ">>> [1/7] 环境检查"
command -v flutter >/dev/null || { echo "错误: 未安装 Flutter，请先安装并加入 PATH"; exit 1; }
command -v xcrun >/dev/null || { echo "错误: 未安装 Xcode Command Line Tools"; exit 1; }
flutter --version
xcodebuild -version
echo ""

echo ">>> [2/7] 检查模拟器 arm64 排除项（Xcode 26 必须原生 arm64）"
PBXPROJ="$APP_DIR/ios/Runner.xcodeproj/project.pbxproj"
if grep -q 'EXCLUDED_ARCHS.*arm64' "$PBXPROJ" 2>/dev/null; then
  echo "警告: 项目在 Excluded Architectures 中排除了 arm64，请在 Xcode Build Settings 中移除"
else
  echo "OK: 未发现 arm64 排除"
fi
echo ""

echo ">>> [3/7] 清理构建缓存"
cd "$APP_DIR"
flutter clean
flutter pub get
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo ""

echo ">>> [4/7] 重置模拟器"
killall Simulator 2>/dev/null || true
killall Xcode 2>/dev/null || true
xcrun simctl shutdown all 2>/dev/null || true
# 仅删除本 App 的旧安装，避免全量 erase
for udid in $(xcrun simctl list devices booted -j 2>/dev/null | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  for devs in d.get('devices',{}).values():
    for dev in devs:
      if dev.get('state')=='Booted':
        print(dev['udid'])
except: pass
" 2>/dev/null); do
  xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true
done
echo ""

echo ">>> [5/7] 重建 iOS 模拟器产物"
flutter build ios --simulator --debug
echo ""

echo ">>> [6/7] 诊断：列出可用模拟器"
flutter devices
echo ""

echo ">>> [7/7] 启动建议"
cat <<'EOF'

若仍报 RequestDenied / Launchd 163，按顺序尝试：

A. 安装 Universal 版 iOS 26 模拟器运行时（macOS 26 最常见根因）
   1. Xcode → Settings → Components → 删除 iOS 26.x 运行时
   2. 终端执行：
      xcodebuild -downloadPlatform iOS -architectureVariant universal
   3. 重启 Xcode，新建 iPhone 16 / iOS 26 模拟器再试

B. 换较稳定的 iOS 18 模拟器（绕过 iOS 26 beta 问题）
   Xcode → Settings → Platforms → 下载 iOS 18.x
   flutter run -d "iPhone 16"

C. Xcode 签名
   Runner → Signing & Capabilities → 勾选 Automatically manage signing
   选择 Team（需登录 Apple ID）

D. 查看真实原因（比 Xcode 弹窗更详细）
   log stream --predicate 'process CONTAINS "Runner" OR eventMessage CONTAINS "memeGame"' --level debug
   另开终端: flutter run -d ios -v

E. 升级 Flutter 到最新 stable（需 ≥ 3.38.8 支持 UIScene）
   flutter upgrade
   flutter doctor -v

EOF

DEVICE="${FLUTTER_DEVICE:-}"
if [[ -n "$DEVICE" ]]; then
  echo ">>> 正在启动: $DEVICE"
  API_URL="${API_BASE_URL:-http://localhost:5050}"
  flutter run -d "$DEVICE" --dart-define=API_BASE_URL="$API_URL" -v
else
  echo "完成。手动运行:"
  echo "  cd app && flutter run -d \"iPhone 16\" --dart-define=API_BASE_URL=http://localhost:5050"
  echo "或指定设备:"
  echo "  FLUTTER_DEVICE=\"iPhone 16\" bash scripts/fix_ios_simulator.sh"
fi
