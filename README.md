# 梗次元闯关（Meme Game）

Flame 2D 像素风闯关 + Flask 热梗内容中台。

## 仓库结构

```
├── app/          # Flutter 客户端（Flame 游戏 + GetX）
├── backend/      # Flask API 内容中台
├── docs/         # 架构 & 可观测性文档
└── shared/       # 跨端契约（trace header、错误码）
```

## 快速开始

**验收测试：** 见 [docs/acceptance-test.md](docs/acceptance-test.md)

详见 [docs/observability.md](docs/observability.md)

## 架构说明

- [docs/architecture.md](docs/architecture.md)
- [docs/art-agent.md](docs/art-agent.md) — 美术智能体并行规范
- [docs/art-direction.md](docs/art-direction.md) — 视觉方向摘要
