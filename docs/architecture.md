# 梗次元闯关 — 架构与业务边界

## 1. Monorepo 总览

```
flaskFlutterGame/
├── docs/                 # 架构、规范、运维文档
├── backend/              # Flask 内容中台 & API（独立部署单元）
├── app/                  # Flutter + Flame 客户端（独立部署单元）
└── shared/               # 跨端约定（trace header、错误码、manifest schema）
```

| 模块 | 职责 | 禁止越界 |
|------|------|----------|
| **app（客户端）** | 渲染、输入、本地缓存、调用 API、上报埋点 | 不做内容审核、不做持久化业务主数据 |
| **backend（服务端）** | 内容 manifest、梗包元数据、审核、统计聚合 | 不做游戏渲染、不持有 Flame 引擎逻辑 |
| **shared** | 契约定义（JSON Schema / 常量） | 不含可执行业务逻辑 |

---

## 2. 后端分层（backend/app）

```
HTTP 请求
   │
   ▼
┌─────────────────────────────────────┐
│ middleware/   请求上下文、访问日志    │  ← trace_id / request_id 注入
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│ api/          路由 & 入参校验         │  ← 仅编排，不写业务细节
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│ services/     业务用例 & 流程编排      │  ← 关键业务流程打印（FlowTracer）
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│ repositories/ 数据访问 & 外部 IO     │  ← DB / 文件 / CDN 元数据
└─────────────────────────────────────┘
```

### 服务边界

| 服务 | 包路径 | 业务边界 |
|------|--------|----------|
| ContentService | `services/content_service.py` | 梗包 manifest 查询、版本比对 |
| HealthService | `services/health_service.py` | 健康检查、依赖探测 |

后续扩展（占位，不在本阶段实现）：

- `SeasonService` — 赛季/通行证配置
- `ReviewService` — UGC 梗投稿审核
- `AnalyticsService` — 事件聚合

---

## 3. 客户端分层（app/lib）

```
main.dart
   │
   ▼
┌─────────────────────────────────────┐
│ app/          路由、主题、依赖注入     │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│ core/observability/  日志 & 链路     │
│ core/network/        HTTP + 拦截器    │
│ core/config/         环境配置         │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│ features/     按功能垂直切分           │
│   home/       章节选择                │
│   gameplay/   Flame 闯关（后续）       │
│   content/    热更下载（后续）         │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│ data/         Repository 实现         │
└─────────────────────────────────────┘
```

---

## 4. 可观测性约定（跨端统一）

### 4.1 关联 ID

| 字段 | 生成方 | 传递方式 | 用途 |
|------|--------|----------|------|
| `trace_id` | 客户端发起请求时生成；服务端可继承 | Header `X-Trace-Id` | 串联一次用户操作的全链路 |
| `request_id` | 服务端每个 HTTP 请求 | Header `X-Request-Id`（响应回写） | 定位单次 API 调用 |
| `span_id` | 各层子步骤 | 仅日志字段 | 定位业务流程内子步骤 |

### 4.2 日志结构（JSON）

```json
{
  "timestamp": "2026-07-03T09:15:00.000Z",
  "level": "INFO",
  "service": "meme-game-backend",
  "trace_id": "abc-123",
  "request_id": "req-456",
  "span_id": "span-789",
  "module": "content_service",
  "event": "manifest.fetch.completed",
  "message": "manifest 拉取完成",
  "duration_ms": 12,
  "extra": { "pack_count": 3 }
}
```

### 4.3 关键业务事件命名

| 域 | 事件 | 说明 |
|----|------|------|
| `http` | `http.request.received` / `http.request.completed` | 接口进出 |
| `content` | `content.manifest.fetch.started/completed/failed` | manifest 流程 |
| `content` | `content.pack.download.started/completed/failed` | 梗包下载（客户端） |
| `game` | `game.level.load.started/completed` | 关卡加载（后续） |
| `game` | `game.session.started/ended` | 单局生命周期（后续） |

### 4.4 排查手册

1. 用户提供现象时间 → 在日志平台搜 `trace_id` 或 `request_id`
2. 无 trace_id → 搜 `event=content.manifest.fetch.failed` + 时间范围
3. 接口 5xx → 搜 `level=ERROR` + `module=api`
4. 客户端问题 → 搜 `service=meme-game-app` + 对应 `event`

---

## 5. 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LOG_LEVEL` | `INFO` | 日志级别 |
| `LOG_FORMAT` | `json` | `json` 或 `text` |
| `SERVICE_NAME` | `meme-game-backend` | 服务名标识 |
| `API_BASE_URL` | `http://localhost:5000` | 客户端 API 地址 |
