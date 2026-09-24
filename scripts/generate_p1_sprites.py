#!/usr/bin/env python3
"""搞事事 P1 像素资产：重力光圈、天花板砖、粒子、结算横幅、梗气泡。"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
IMAGE_ROOT = ROOT / "app" / "assets" / "images"
MANIFEST = ROOT / "shared" / "art" / "asset_manifest.json"

OUTLINE = (26, 26, 26, 255)
CEILING = (244, 143, 177, 255)
CEILING_HI = (248, 187, 208, 255)
PORTAL = (255, 255, 255, 255)
PORTAL_GLOW = (225, 190, 231, 255)
DUST = (188, 170, 164, 255)
BUBBLE = (255, 253, 231, 255)
BANNER = (255, 109, 0, 255)
ENEMY = (239, 83, 80, 255)
ENEMY_EYE = (255, 253, 231, 255)


def save_image(image: Image.Image, relative_path: str) -> None:
    target = IMAGE_ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, format="PNG")
    print(f"saved {target}")


def save_meta(relative_path: str, payload: dict) -> None:
    target = IMAGE_ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"saved {target}")


def draw_outline_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
) -> None:
    draw.rectangle(box, fill=fill, outline=OUTLINE, width=1)


def generate_tile_ceiling() -> None:
    size = 32
    tile = Image.new("RGBA", (size, size), CEILING)
    draw = ImageDraw.Draw(tile)
    draw.rectangle((2, size - 10, size - 3, size - 3), fill=CEILING_HI)
    for x in range(0, size, 8):
        draw.line((x, size - 8, x, size - 1), fill=CEILING_HI, width=1)
    draw.rectangle((0, 0, size - 1, size - 1), outline=OUTLINE, width=1)
    save_image(tile, "sprites/environment/tile_ceiling.png")


def generate_gravity_portal_sheet() -> None:
    frame = 32
    cols = 4
    sheet = Image.new("RGBA", (frame * cols, frame), (0, 0, 0, 0))
    radii = (10, 12, 14, 12)
    for index, radius in enumerate(radii):
        cell = Image.new("RGBA", (frame, frame), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)
        cx = cy = frame // 2
        draw.ellipse(
            (cx - radius - 2, cy - radius - 2, cx + radius + 2, cy + radius + 2),
            outline=PORTAL_GLOW,
            width=2,
        )
        draw.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            outline=PORTAL,
            width=2,
        )
        draw.ellipse(
            (cx - 3, cy - 3, cx + 3, cy + 3),
            fill=PORTAL_GLOW,
            outline=OUTLINE,
        )
        sheet.paste(cell, (index * frame, 0))
    save_image(sheet, "sprites/environment/gravity_portal_sheet.png")
    save_meta(
        "sprites/environment/gravity_portal_sheet.json",
        {
            "sheet": "gravity_portal_sheet.png",
            "frameWidth": 32,
            "frameHeight": 32,
            "anchor": {"x": 0.5, "y": 0.5},
            "animations": {
                "pulse": {"row": 0, "frameCount": 4, "fps": 8, "loop": True}
            },
        },
    )


def generate_fx_dust_sheet() -> None:
    frame = 16
    cols = 4
    sheet = Image.new("RGBA", (frame * cols, frame), (0, 0, 0, 0))
    sizes = (3, 5, 7, 4)
    for index, size in enumerate(sizes):
        cell = Image.new("RGBA", (frame, frame), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)
        left = (frame - size) // 2
        top = frame - size - 2
        draw.ellipse((left, top, left + size, top + size), fill=DUST, outline=OUTLINE)
        sheet.paste(cell, (index * frame, 0))
    save_image(sheet, "sprites/fx/fx_dust_sheet.png")
    save_meta(
        "sprites/fx/fx_dust_sheet.json",
        {
            "sheet": "fx_dust_sheet.png",
            "frameWidth": 16,
            "frameHeight": 16,
            "anchor": {"x": 0.5, "y": 1.0},
            "animations": {
                "puff": {"row": 0, "frameCount": 4, "fps": 12, "loop": False}
            },
        },
    )


def generate_fx_coin_burst_sheet() -> None:
    frame = 24
    cols = 4
    sheet = Image.new("RGBA", (frame * cols, frame), (0, 0, 0, 0))
    for index in range(cols):
        cell = Image.new("RGBA", (frame, frame), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)
        radius = 2 + index
        cx = cy = frame // 2
        for angle_i in range(6):
            ox = int((3 + index * 2) * (1 if angle_i % 2 == 0 else -1) * (1 if angle_i < 3 else 0.4))
            oy = int((2 + index) * (1 if angle_i % 3 == 0 else -1))
            draw.ellipse(
                (cx + ox - radius, cy + oy - radius, cx + ox + radius, cy + oy + radius),
                fill=(255, 213, 79, 255),
                outline=OUTLINE,
            )
        sheet.paste(cell, (index * frame, 0))
    save_image(sheet, "sprites/fx/fx_coin_burst_sheet.png")
    save_meta(
        "sprites/fx/fx_coin_burst_sheet.json",
        {
            "sheet": "fx_coin_burst_sheet.png",
            "frameWidth": 24,
            "frameHeight": 24,
            "anchor": {"x": 0.5, "y": 0.5},
            "animations": {
                "burst": {"row": 0, "frameCount": 4, "fps": 14, "loop": False}
            },
        },
    )


def generate_ui_meme_bubble() -> None:
    """9-slice 友好的梗文气泡底板（可拉伸角）。"""
    width, height = 96, 48
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_outline_rect(draw, (2, 2, width - 3, height - 11), BUBBLE)
    draw.polygon([(18, height - 11), (28, height - 11), (14, height - 2)], fill=BUBBLE, outline=OUTLINE)
    draw.line([(19, height - 11), (27, height - 11)], fill=BUBBLE, width=2)
    save_image(image, "ui/bubbles/ui_meme_bubble.png")


def generate_ui_result_banner() -> None:
    width, height = 160, 40
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_outline_rect(draw, (0, 4, width - 1, height - 5), BANNER)
    draw.polygon([(0, 4), (12, 20), (0, 36)], fill=(255, 143, 0, 255), outline=OUTLINE)
    draw.polygon(
        [(width - 1, 4), (width - 13, 20), (width - 1, 36)],
        fill=(255, 143, 0, 255),
        outline=OUTLINE,
    )
    save_image(image, "ui/banners/ui_result_banner.png")


def generate_enemy_sheet_upgrade() -> None:
    """强化敌人 walk：尖刺头 + 红身体，方便重力关辨认。"""
    frame_w, frame_h = 28, 28
    cols = 4
    sheet = Image.new("RGBA", (frame_w * cols, frame_h), (0, 0, 0, 0))
    for col in range(cols):
        frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(frame)
        bob = 1 if col % 2 == 0 else 0
        body_top = 8 + bob
        draw_outline_rect(draw, (4, body_top, 23, 24), ENEMY)
        draw.polygon([(6, body_top), (10, body_top - 5), (14, body_top)], fill=ENEMY, outline=OUTLINE)
        draw.polygon([(14, body_top), (18, body_top - 5), (22, body_top)], fill=ENEMY, outline=OUTLINE)
        draw.ellipse((8, body_top + 4, 12, body_top + 8), fill=ENEMY_EYE, outline=OUTLINE)
        draw.ellipse((16, body_top + 4, 20, body_top + 8), fill=ENEMY_EYE, outline=OUTLINE)
        leg = 2 if col % 2 == 0 else -2
        draw.rectangle((8 + leg, 23, 11 + leg, 26), fill=OUTLINE)
        draw.rectangle((17 - leg, 23, 20 - leg, 26), fill=OUTLINE)
        sheet.paste(frame, (col * frame_w, 0))
    save_image(sheet, "sprites/enemies/enemy_basic_sheet.png")
    save_meta(
        "sprites/enemies/enemy_basic_sheet.json",
        {
            "sheet": "enemy_basic_sheet.png",
            "frameWidth": 28,
            "frameHeight": 28,
            "anchor": {"x": 0.5, "y": 1.0},
            "animations": {
                "walk": {"row": 0, "frameCount": 4, "fps": 8, "loop": True}
            },
        },
    )


def update_manifest() -> None:
    data = {
        "version": "1.1.0",
        "tile_size": 32,
        "palette": {
            "sky": "#B3E5FC",
            "ground": "#66BB6A",
            "platform": "#8D6E63",
            "ceiling": "#F48FB1",
            "outline": "#1A1A1A",
            "player": "#7C4DFF",
            "coin": "#FFD54F",
            "coin_shine": "#FFF59D",
            "flag_pole": "#424242",
            "flag_cloth": "#E91E63",
            "enemy": "#EF5350",
            "danger": "#D50000",
            "victory": "#FF6D00",
            "bubble_bg": "#FFFDE7",
            "portal": "#FFFFFF",
        },
        "assets": [
            {
                "id": "player_sheet",
                "path": "sprites/player/player_sheet.png",
                "meta": "sprites/player/player_sheet.json",
                "priority": "P0",
                "status": "ready",
            },
            {
                "id": "coin_sheet",
                "path": "sprites/collectibles/coin_sheet.png",
                "meta": "sprites/collectibles/coin_sheet.json",
                "priority": "P0",
                "status": "ready",
            },
            {
                "id": "tile_ground",
                "path": "sprites/environment/tile_ground.png",
                "priority": "P0",
                "status": "ready",
            },
            {
                "id": "tile_platform",
                "path": "sprites/environment/tile_platform.png",
                "priority": "P0",
                "status": "ready",
            },
            {
                "id": "tile_ceiling",
                "path": "sprites/environment/tile_ceiling.png",
                "priority": "P1",
                "status": "ready",
            },
            {
                "id": "goal_flag",
                "path": "sprites/collectibles/goal_flag.png",
                "priority": "P0",
                "status": "ready",
            },
            {
                "id": "bg_sky",
                "path": "backgrounds/bg_sky.png",
                "priority": "P0",
                "status": "ready",
            },
            {
                "id": "enemy_basic_sheet",
                "path": "sprites/enemies/enemy_basic_sheet.png",
                "meta": "sprites/enemies/enemy_basic_sheet.json",
                "priority": "P1",
                "status": "ready",
            },
            {
                "id": "gravity_portal_sheet",
                "path": "sprites/environment/gravity_portal_sheet.png",
                "meta": "sprites/environment/gravity_portal_sheet.json",
                "priority": "P1",
                "status": "ready",
            },
            {
                "id": "fx_dust_sheet",
                "path": "sprites/fx/fx_dust_sheet.png",
                "meta": "sprites/fx/fx_dust_sheet.json",
                "priority": "P1",
                "status": "ready",
            },
            {
                "id": "fx_coin_burst_sheet",
                "path": "sprites/fx/fx_coin_burst_sheet.png",
                "meta": "sprites/fx/fx_coin_burst_sheet.json",
                "priority": "P1",
                "status": "ready",
            },
            {
                "id": "ui_meme_bubble",
                "path": "ui/bubbles/ui_meme_bubble.png",
                "priority": "P1",
                "status": "ready",
            },
            {
                "id": "ui_result_banner",
                "path": "ui/banners/ui_result_banner.png",
                "priority": "P1",
                "status": "ready",
            },
        ],
    }
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"updated {MANIFEST}")


def main() -> None:
    generate_tile_ceiling()
    generate_gravity_portal_sheet()
    generate_fx_dust_sheet()
    generate_fx_coin_burst_sheet()
    generate_ui_meme_bubble()
    generate_ui_result_banner()
    generate_enemy_sheet_upgrade()
    update_manifest()
    print("P1 sprites generated.")


if __name__ == "__main__":
    main()
