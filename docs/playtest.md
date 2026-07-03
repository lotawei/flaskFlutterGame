# 搞事事 · 试玩指南

## 最快试玩（无需后端）

```bash
cd app
flutter pub get
flutter run -d chrome
```

1. 打开首页，点击 **「开始试玩」**
2. **键盘**：`A/D` 或 `←/→` 移动，`W/↑/空格` 跳跃
3. **触控**：屏幕底部左右/跳跃按钮
4. 收集金币，到达右侧 **粉色旗子** 通关
5. 掉出地图则失败，可「再来一局」

## 完整联调（含后端热更关卡）

**终端 1 — 后端：**
```bash
cd backend
pip install -r requirements.txt
python run.py
```

**终端 2 — 客户端：**
```bash
cd app
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

后端启动后，客户端会优先从 API 拉取关卡并缓存到本地；后端不可用时自动回退内置 `assets/levels/demo_haqi.json`。

## 验证 API

```bash
curl http://localhost:5000/api/v1/content/levels/demo_haqi
curl http://localhost:5000/api/v1/content/manifest
```

## 测试

```bash
# 客户端
cd app && flutter test

# 后端
cd backend && PYTHONPATH=. pytest -q
```

## 当前可玩内容

| 项目 | 状态 |
|------|------|
| Flame 跑跳 + 碰撞 | ✅ |
| Demo 关卡 demo_haqi | ✅ |
| 金币收集 + 终点通关 | ✅ |
| 失败（掉落）+ 结算页 | ✅ |
| 键盘 + 触控 | ✅ |
| 关卡远程拉取 + 本地缓存 | ✅ |
| 多关卡 / 梗包 zip | 🔜 下一步 |

## 排查

- 游戏黑屏：看 DevTools Console 搜 `game.level.load.failed`
- 无法连接后端：首页会提示「梗包服务未连接」，本地试玩不受影响
- 用 `trace_id` 串联日志，详见 [observability.md](./observability.md)
