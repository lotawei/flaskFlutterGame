# Blender MCP + 像素烘焙管线

> 目标：用 Blender 做 3D 造型 → 正交渲染 → 最近邻降采样 → **同路径替换** `app/assets/images/` 契约资产。

## 现状（本仓库 / 云端）

| 能力 | 状态 |
|------|------|
| 无头 `blender --python` 烘焙 | ✅ 已落地 `scripts/blender/` |
| Cursor **云端 Agent** 内的 Blender MCP 工具 | ❌ 云端工具目录无 Blender 命名空间 |
| Cursor **本机 Desktop** Blender MCP | ⚠️ 需你在本机 Settings → MCP 启用（见下） |

云端 Agent **不能**直接点 Blender 视口；但本机接上 MCP 后，你在 Desktop 对话里可让 Agent 操控 Blender，再跑同一套导出契约。

---

## 一、本机接入 Blender MCP（Cursor Desktop）

1. 安装 [uv](https://docs.astral.sh/uv/)（提供 `uvx`）
2. 安装 Blender 4.x，并安装插件：

```bash
uvx mcp-for-blender --help
# 按包说明安装 addon，或：
uvx mcp-for-blender install-addon
```

3. 打开 Blender → `N` 面板 → **MCP for Blender** → **Start MCP Server**
4. Cursor → **Settings → MCP**，粘贴配置（仓库已提供模板 `.cursor/mcp.json`）：

**macOS / Linux**

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": ["mcp-for-blender"]
    }
  }
}
```

**Windows**（GUI 找不到 PATH 时）

```json
{
  "mcpServers": {
    "blender": {
      "command": "cmd",
      "args": ["/c", "uvx", "mcp-for-blender"]
    }
  }
}
```

若仍报 `spawn uvx ENOENT`，把 `command` 改成 `uvx` 的绝对路径。

5. 刷新 MCP，确认 `blender` 绿灯；**只开一个客户端**（Cursor 或 Claude Desktop 二选一）。

接入后可对 Agent 说：

> 在 Blender 里做一个 28×28 像素风紫怪玩家，正交渲染，导出到 `app/assets/images/sprites/player/`

---

## 二、无头烘焙（云端 / CI / 本机脚本）

不依赖 MCP，适合批量重产：

```bash
# 可选：BAKE_TARGETS=ceiling,portal,coin
bash scripts/blender/run_bake.sh
```

流程：

1. `bake_pixel_sprites.py` — bpy 正交 EEVEE 渲染到 `_bake_tmp/`
2. `pixelate_bake_output.py` — Pillow 最近邻 + 1px 描边，写入契约路径
3. `validate_art_assets.py` — 校验 manifest

### 契约路径（替换即生效）

| 烘焙产物 | 写入 |
|----------|------|
| 天花板 / 地面 / 跳台 | `sprites/environment/tile_*.png` |
| 重力光圈 sheet | `sprites/environment/gravity_portal_sheet.png` |
| 参考金币 | `sprites/collectibles/coin_blender.png` |
| 参考敌人 | `sprites/enemies/enemy_blender.png` |

动画 sheet（玩家 idle/run、金币旋转帧）仍以 `generate_p1_sprites.py` 为准；Blender 产物用作 **静帧替换或单帧皮肤**，后续可扩成多角度 sheet。

---

## 三、美术规范（烘焙也必须遵守）

见 `shared/art/palette.json`：

- Tile **32×32**，玩家 **28×28**，金币 **20×20**
- **Nearest neighbor**，禁止抗锯齿模糊
- **1px `#1A1A1A` 描边**
- 颜色不越调色板

---

## 四、推荐工作方式（指挥官）

1. **本机 MCP**：交互式捏模型 / 摆光 / 试构图  
2. **固化成 `bake_pixel_sprites.py` 场景逻辑**：可复现、可 CI  
3. **Agent 审图** → `validate_art_assets.py` → PR  

这样即使云端没有 Blender MCP，素材管线仍可持续交付。
