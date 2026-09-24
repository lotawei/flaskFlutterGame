#!/usr/bin/env python3
"""将 Blender 高分辨率烘焙结果最近邻降采样到游戏契约路径。"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
IMAGE_ROOT = ROOT / "app" / "assets" / "images"
TMP = IMAGE_ROOT / "_bake_tmp"
OUTLINE = (26, 26, 26, 255)


def nearest(src: Path, size: int) -> Image.Image:
    image = Image.open(src).convert("RGBA")
    return image.resize((size, size), Image.Resampling.NEAREST)


def add_outline(image: Image.Image) -> Image.Image:
    """给不透明像素加 1px 描边，贴合美术规范。"""
    alpha = image.getchannel("A")
    dilated = ImageOps.expand(alpha, border=1, fill=0)
    # 简化：在原图边缘画描边
    pixels = image.load()
    width, height = image.size
    outline_mask = [[False] * width for _ in range(height)]
    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] == 0:
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if nx < 0 or ny < 0 or nx >= width or ny >= height or pixels[nx, ny][3] == 0:
                    outline_mask[y][x] = True
                    break
    out = image.copy()
    out_pixels = out.load()
    for y in range(height):
        for x in range(width):
            if outline_mask[y][x] and pixels[x, y][3] > 0:
                # 仅在边缘内侧加深轮廓感：邻接透明处写描边
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < width and 0 <= ny < height and pixels[nx, ny][3] == 0:
                        out_pixels[nx, ny] = OUTLINE
    return out


def save(image: Image.Image, rel: str) -> None:
    target = IMAGE_ROOT / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)
    print(f"wrote {target}")


def stitch(frames: list[Image.Image], rel: str) -> None:
    width = frames[0].width
    height = frames[0].height
    sheet = Image.new("RGBA", (width * len(frames), height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.paste(frame, (index * width, 0))
    save(sheet, rel)


def main() -> None:
    if not TMP.exists():
        raise SystemExit(f"missing bake tmp: {TMP}")
    mapping = {
        "ceiling.png": ("sprites/environment/tile_ceiling.png", 32),
        "ground.png": ("sprites/environment/tile_ground.png", 32),
        "platform.png": ("sprites/environment/tile_platform.png", 32),
        "coin.png": ("sprites/collectibles/coin_blender.png", 20),
        "enemy.png": ("sprites/enemies/enemy_blender.png", 28),
    }
    for name, (rel, size) in mapping.items():
        src = TMP / name
        if not src.exists():
            print(f"skip missing {src}")
            continue
        save(add_outline(nearest(src, size)), rel)
    portal_frames: list[Image.Image] = []
    for index in range(4):
        src = TMP / f"portal_{index}.png"
        if not src.exists():
            continue
        portal_frames.append(add_outline(nearest(src, 32)))
    if portal_frames:
        stitch(portal_frames, "sprites/environment/gravity_portal_sheet.png")
        meta = {
            "sheet": "gravity_portal_sheet.png",
            "frameWidth": 32,
            "frameHeight": 32,
            "anchor": {"x": 0.5, "y": 0.5},
            "animations": {
                "pulse": {"row": 0, "frameCount": len(portal_frames), "fps": 8, "loop": True}
            },
            "source": "blender_bake",
        }
        meta_path = IMAGE_ROOT / "sprites/environment/gravity_portal_sheet.json"
        meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {meta_path}")
    print("pixelate complete")


if __name__ == "__main__":
    main()
