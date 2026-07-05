# 关卡量产流水线

> 目标：让策划/关卡编辑在 **选原型 → 摆地图 → 填梗皮 → 校验 → 发布** 五步法内，快速批量产出可玩关卡。

## 一、架构总览

```
shared/level/
├── level_schema_v2.json      # 契约（客户端/后端/CI 共用）
├── archetypes/*.json         # 6 种玩法原型默认规则
└── templates/*.template.json # 空白关卡模板（复制即用）

app/lib/core/level/
├── level_archetype_id.dart   # 原型/机制/规则枚举
├── archetype_registry.dart   # 原型默认机制与变现钩子
├── level_factory.dart        # 从原型组装关卡
├── level_validator.dart      # 业务校验
└── level_rule_evaluator.dart # 胜利/三星评定

scripts/validate_level.py     # 批量 Schema + 业务校验
```

**核心原则：地图是积木，玩法是原型，梗皮是皮肤。**

| 层 | 策划填什么 | 系统做什么 |
|---|---|---|
| 原型 archetype | 选 1 种玩法 | 自动补齐 mechanics / win_rules / star_rules / monetization_hooks |
| 地图 | platforms / coins / enemies / goal | 引擎加载碰撞与实体 |
| 梗皮 meme_theme | 主题 ID | 映射美术包、文案、结算语录 |
| 变现钩子 | 开关槽位 | UI/广告/复活入口（策划表驱动） |

## 二、六种玩法原型（每关一种核心差异）

| 原型 ID | 名称 | 核心差异 | 参考游戏 | 引擎状态 |
|---|---|---|---|---|
| `rush_standard` | 标准冲关 | 跑到终点就赢 | 经典 Mario | ✅ 已实装 |
| `timed_rush` | 限时冲关 | 倒计时压迫、刷星竞速 | Super Meat Boy 计时关 | ✅ 倒计时 HUD + 超时失败 |
| `reversal_trap` | 反转陷阱 | 假旗失败、找真终点 | 恶搞向解谜 | ✅ 假旗碰撞失败 |
| `greed_tax` | 来财税局 | 贪币增难、路线取舍 | — | 📋 数据就绪，引擎 P2 |
| `lie_flat` | 躺平计量 | 移动掉面子、停下回血 | — | 📋 数据就绪，引擎 P2 |
| `gravity_flip` | 重力反转 | 上下半区重力相反，倒挂走天花板 | **ibb & obb**、VVVVVV | ✅ 分区重力 + 倒挂物理 |

### ibb & obb 式重力关设计要点

1. **`gravity_zones`**：用矩形分区声明 `gravity: up/down`（屏幕上半区向上、下半区向下）。
2. **平台**：下区摆常规地面；上区摆「天花板平台」（玩家站在平台**底面**）。
3. **过渡**：中间留跳跃通道，让玩家**中心点**进入另一分区时自动翻转重力与朝向。
4. **操作**：「跳」始终沿**远离当前重力**方向，与 ibb & obb 一致。

Demo 关：`gravity_flip_demo`（首页「颠倒隧道」）。

详细默认参数见 `shared/level/archetypes/`。

## 三、快速生产五步法

### Step 1 — 选原型

复制对应模板：

```bash
cp shared/level/templates/timed_rush.template.json \
   app/assets/levels/chapter01_level03.json
```

或在代码中用 `LevelFactory.buildFromArchetype()` 只填地图字段。

### Step 2 — 摆地图

必填字段：

- `player_spawn` / `platforms` / `goal`
- 可选：`coins` / `enemies` / `fake_goals`（反转关）

**宽度建议**：Demo 关 50–80 tile；量产关 40–60 tile 为宜，单局 45–90 秒。

### Step 3 — 填梗皮与难度

```json
{
  "meme_theme": "deadline_panic",
  "difficulty": "normal",
  "tip_text": "60 秒内冲到终点！"
}
```

`meme_theme` 不改机制，只换皮和文案（见 `docs/art-direction.md`）。

### Step 4 — 校验

```bash
pip install -r scripts/requirements.txt
python scripts/validate_level.py
```

Dart 侧单元测试：`app/test/level_validator_test.dart`

### Step 5 — 发布

1. 同步到 `backend/app/data/levels/`
2. 在 manifest 注册 `level_id`（后续接 CDN 包）
3. 客户端内置回退：在 `LevelRepository._bundledLevels` 登记

路由试玩：`/gameplay?levelId=timed_rush_demo`

## 四、批量扩关建议

### 章节包结构（推荐）

```
chapter_01/
  c01_01_rush.json      # rush_standard
  c01_02_timed.json     # timed_rush
  c01_03_reversal.json  # reversal_trap
chapter_02/
  ...
```

每章 **至少 3 种原型各 1 关**，保证玩法节奏不单调。

### 复用地图积木

同一 `platforms` 数组可换：

- `archetype`（标准关 → 限时关，加 `time_limit`）
- `meme_theme`（哈基 → 职场 → 恋爱梗）
- `enemies` 密度（easy / hard）

### 策划旋钮（designer_knobs）

各原型 JSON 内 `designer_knobs` 段标注可调范围，例如限时关 `time_budget_sec: 45-120`。

## 五、机制积木清单

| 机制 type | 参数示例 | 说明 |
|---|---|---|
| `time_limit` | `seconds`, `warn_at` | 倒计时，HUD 显示剩余秒数 |
| `reversal_fake_goal` | `fake_goal_fail` | 碰假旗失败 |
| `coin_greed_scale` | `enemy_speed_per_coin` | 每收 N 币敌人加速 |
| `lie_flat_meter` | `drain_per_sec_moving` | 移动掉面子条 |
| `rhythm_step` | （预留） | 节奏踩点门 |

## 六、三星与变现钩子

- **三星**：`star_rules` 数组，由 `LevelRuleEvaluator` 在结算时评定（客户端可展示）。
- **变现钩子**：`monetization_hooks` 只声明槽位开关，具体 UI 由交互策划在 `docs/game-design-playbook.md` 中定义。

| 槽位 slot | 典型触发 |
|---|---|
| `revive_on_fail` | 掉落/碰敌/超时 |
| `double_coins` | 通关结算 |
| `hint_reveal` | 反转关卡关 |
| `skip_hard_section` | 贪税关高难区 |
| `season_bonus` | 限时榜赛季 |

## 七、示例关卡

| level_id | 原型 | 用途 |
|---|---|---|
| `demo_haqi` | rush_standard | 主 Demo / 验收 |
| `timed_rush_demo` | timed_rush | 倒计时试玩 |
| `reversal_trap_demo` | reversal_trap | 假旗教学 |
| `greed_tax_demo` | greed_tax | 贪币数值预埋 |
| `lie_flat_demo` | lie_flat | 躺平机制预埋 |

## 八、CI 集成（建议）

```yaml
- run: pip install -r scripts/requirements.txt
- run: python scripts/validate_level.py
- run: cd app && flutter test
```

## 九、后续路线

- [ ] P2：`coin_greed_scale` / `lie_flat_meter` 引擎实装 + HUD
- [ ] 关卡编辑器（Tiled / 自研 Web 摆砖）
- [ ] manifest 章节包热更新
- [ ] A/B 难度与变现钩子远程配置
