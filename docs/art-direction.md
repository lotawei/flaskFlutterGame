# 搞事事 · 美术方向（摘要）

> 完整规范见并行 Art Agent 产出 + `shared/art/asset_manifest.json`

## 视觉支柱

- **Tile**：32×32 px，像素 nearest neighbor
- **玩家**：28×28 px，头大身小，#7C4DFF 紫怪脸
- **调性**：离谱但可爱、梗感、1px #1A1A1A 描边
- **背景**：#B3E5FC 天空 + 白云朵视差

## P0 资产（已接入）

| 资产 | 路径 | 用途 |
|------|------|------|
| player_sheet | sprites/player/ | idle/run/jump 动画 |
| coin_sheet | sprites/collectibles/ | 旋转金币 |
| tile_ground/platform | sprites/environment/ | 地面/跳台 |
| goal_flag | sprites/collectibles/ | 终点旗 |
| bg_sky | backgrounds/ | 平铺天空 |

## 动画规格

见各目录下 `.json` 元数据（row、frameCount、fps、loop、anchor）。

## 重生资产

```bash
python scripts/generate_p0_sprites.py
python scripts/validate_art_assets.py
```

## 下一步 P1

- 敌人 patrol 动画
- 金币收集粒子、落地尘土
- 结算横幅、梗文气泡 9-patch
- 触控按钮像素皮肤
