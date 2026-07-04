# iOS 模拟器启动失败排查

报错示例：

```
FBSOpenApplicationServiceErrorDomain Code: 1
Request denied by service delegate (SBMainWorkspace)
Launchd job spawn failed (Code: 163)
```

多见于 **Xcode / iOS Simulator 测试版** 或模拟器状态损坏，**不一定是项目代码问题**。

## 推荐：先用 Chrome 试玩（最快）

横版梗游在 Web 上可完整试玩，账号/后端联调一致：

```bash
# 终端1
bash scripts/start_backend.sh

# 终端2
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5050
```

或使用脚本（默认就是 chrome）：

```bash
bash scripts/start_app.sh
```

## 方案 B：macOS 桌面版

```bash
cd app
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:5050
```

## 若必须用 iOS 模拟器

按顺序尝试，**每步后重跑** `flutter run`：

### 1. 清理并重装

```bash
cd app
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d "iPhone 16"   # 换成 flutter devices 里列出的模拟器名
```

### 2. 重置模拟器

```bash
# 关闭所有模拟器
xcrun simctl shutdown all

# 列出设备
xcrun simctl list devices available

# 仅擦除当前出问题的设备（把 UDID 换成你的）
xcrun simctl erase 6CA6A654-0872-4AF0-93D6-D376DDBDD90A
```

然后先手动打开 **Simulator.app**，再执行 `flutter run`。

### 3. Xcode 签名

1. 用 Xcode 打开 `app/ios/Runner.xcworkspace`
2. 选中 **Runner** → **Signing & Capabilities**
3. 勾选 **Automatically manage signing**
4. **Team** 选你的 Apple ID（个人团队即可，模拟器调试免费）
5. 若 Bundle ID 冲突，改成唯一值，例如 `com.yourname.memegame`

### 4. 换一台模拟器

```bash
flutter devices
flutter run -d <另一台模拟器 id>
```

优先选 **非 iOS 26 beta** 的稳定机型（若本机有 iOS 18.x 模拟器）。

### 5. 仍失败

多为 **Xcode 26.6 + iOS 26.5 模拟器** 系统级问题，建议：

- `xcode-select --install` 确认命令行工具完整
- App Store 更新 Xcode
- 日常开发用 **Chrome / macOS**，真机调试再用 USB 连 iPhone

## 体验账号

- 用户名：`demo`
- 密码：`demo123456`
