# 梗次元闯关 — 可观测性排查指南

## 1. 快速定位流程

```
用户反馈问题
    │
    ├─ 客户端有 trace_id → 全链路搜索 trace_id
    │
    ├─ 仅知接口路径/时间 → 搜 event=http.request.completed + path
    │
    └─ 业务步骤失败 → 搜 *.failed 事件（如 content.manifest.fetch.failed）
```

## 2. 关键日志事件

### 服务端（backend）

| event | 含义 |
|-------|------|
| `http.request.received` | 收到 HTTP 请求 |
| `http.request.completed` | 请求处理完成（含 status_code、duration_ms） |
| `content.manifest.fetch.*.started/completed/failed` | manifest 业务各步骤 |
| `api.content.manifest.error` | API 层捕获异常 |

### 客户端（app）

| event | 含义 |
|-------|------|
| `app.startup.completed` | 应用启动 |
| `http.request.sent` / `http.response.received` | 网络进出 |
| `content.manifest.fetch.request_api.*` | manifest 拉取步骤 |
| `home.manifest.load.*` | 首页业务流 |

## 3. 本地运行

### 启动后端

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python run.py
```

### 启动客户端

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

### 运行后端测试

```bash
cd backend && source .venv/bin/activate && pytest -q
```

## 4. 日志示例

**服务端 JSON 日志：**

```json
{
  "timestamp": "2026-07-03T09:20:00",
  "level": "INFO",
  "module": "middleware.access",
  "message": "请求完成 GET /api/v1/content/manifest -> 200",
  "event": "http.request.completed",
  "trace_id": "trace-abc123",
  "request_id": "req-def456",
  "extra_data": {"status_code": 200, "duration_ms": 3.21}
}
```

**客户端 JSON 日志（DevTools Console）：**

```json
{
  "timestamp": "2026-07-03T09:20:00.000Z",
  "level": "INFO",
  "service": "meme-game-app",
  "module": "network",
  "event": "http.response.received",
  "trace_id": "trace-abc123",
  "extra": {"status_code": 200, "request_id": "req-def456"}
}
```

## 5. 后续扩展建议

- 接入 ELK / Loki + Grafana，按 `trace_id` 建索引
- 错误日志上报 Sentry，附带 trace_id
- 生产环境 `LOG_FORMAT=json` 保持不变，便于机器解析
