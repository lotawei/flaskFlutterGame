#!/usr/bin/env python3
"""生成搞事事 P0 像素风精灵资产（程序化，可复现）。"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "app" / "assets" / "images"
OUTLINE = (26, 26, 26, 255)
PLAYER = (124, 77, 255, 255)
GROUND = (102, 187, 106, 255)
PLATFORM = (141, 110, 99, 255)
COIN = (255, 213, 79, 255)
COIN_SHINE = (255, 245, 157, 255)
FLAG_POLE = (66, 66, 66, 255)
FLAG_CLOTH = (233, 30, 99, 255)
SKY_TOP = (179, 229, 252, 255)
SKY_BOTTOM = (225, 245, 254, 255)


def hex_rgb(value: str) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    r, g, b = int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)
    return r, g, b, 255


def save_image(image: Image.Image, relative_path: str) -> None:
    target = ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, format="PNG")
    print(f"saved {target}")


def draw_outline_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
) -> None:
    draw.rectangle(box, fill=fill, outline=OUTLINE, width=1)


def generate_player_sheet() -> None:
    frame_w, frame_h = 28, 28
    rows, cols = 3, 4
    sheet = Image.new("RGBA", (frame_w * cols, frame_h * rows), (0, 0, 0, 0))
    for row in range(rows):
        for col in range(cols):
            frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
            draw = ImageDraw.Draw(frame)
            body_h = 22 - (1 if row == 2 and col == 0 else 0)
            body_y = frame_h - body_h - 2 + (2 if row == 2 else 0)
            draw_outline_rect(draw, (4, body_y, 23, frame_h - 3), PLAYER)
            eye_y = body_y + 5
            draw.ellipse((8, eye_y, 11, eye_y + 3), fill=OUTLINE)
            draw.ellipse((17, eye_y, 20, eye_y + 3), fill=OUTLINE)
            if row == 1:
                leg_offset = 2 if col % 2 == 0 else -2
                draw.rectangle((8 + leg_offset, frame_h - 5, 11 + leg_offset, frame_h - 2), fill=OUTLINE)
                draw.rectangle((17 - leg_offset, frame_h - 5, 20 - leg_offset, frame_h - 2), fill=OUTLINE)
            if row == 2:
                draw.line((7, body_y + 12, 21, body_y + 10), fill=OUTLINE, width=2)
            sheet.paste(frame, (col * frame_w, row * frame_h))
    save_image(sheet, "sprites/player/player_sheet.png")


def generate_coin_sheet() -> None:
    frame_size = 20
    frames = 6
    sheet = Image.new("RGBA", (frame_size * frames, frame_size), (0, 0, 0, 0))
    widths = (18, 14, 8, 8, 14, 18)
    for index, width in enumerate(widths):
        frame = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(frame)
        left = (frame_size - width) // 2
        draw.ellipse((left, 2, left + width, 17), fill=COIN, outline=OUTLINE)
        if width > 10:
            draw.ellipse((left + 3, 5, left + 7, 9), fill=COIN_SHINE)
        sheet.paste(frame, (index * frame_size, 0))
    save_image(sheet, "sprites/collectibles/coin_sheet.png")


def generate_tiles() -> None:
    size = 32
    ground = Image.new("RGBA", (size, size), GROUND)
    draw = ImageDraw.Draw(ground)
    for x in range(0, size, 8):
        draw.line((x, 0, x, 8), fill=(129, 199, 132, 255), width=1)
    draw.rectangle((0, 0, size - 1, size - 1), outline=OUTLINE, width=1)
    save_image(ground, "sprites/environment/tile_ground.png")
    platform = Image.new("RGBA", (size, size), PLATFORM)
    draw_p = ImageDraw.Draw(platform)
    draw_p.rectangle((2, 2, size - 3, size - 8), fill=(161, 136, 127, 255))
    draw_p.rectangle((0, 0, size - 1, size - 1), outline=OUTLINE, width=1)
    save_image(platform, "sprites/environment/tile_platform.png")


def generate_goal_flag() -> None:
    image = Image.new("RGBA", (24, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle((10, 0, 13, 47), fill=FLAG_POLE)
    draw.polygon([(14, 6), (23, 12), (14, 18)], fill=FLAG_CLOTH, outline=OUTLINE)
    save_image(image, "sprites/collectibles/goal_flag.png")


def generate_bg_sky() -> None:
    width, height = 320, 180
    image = Image.new("RGBA", (width, height), SKY_TOP)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        ratio = y / height
        r = int(SKY_TOP[0] * (1 - ratio) + SKY_BOTTOM[0] * ratio)
        g = int(SKY_TOP[1] * (1 - ratio) + SKY_BOTTOM[1] * ratio)
        b = int(SKY_TOP[2] * (1 - ratio) + SKY_BOTTOM[2] * ratio)
        draw.line((0, y, width, y), fill=(r, g, b, 255))
    for cx, cy, cw in ((40, 30, 36), (140, 50, 28), (240, 24, 40)):
        draw.ellipse((cx, cy, cx + cw, cy + 18), fill=(255, 255, 255, 180))
    save_image(image, "backgrounds/bg_sky.png")


def main() -> None:
    generate_player_sheet()
    generate_coin_sheet()
    generate_tiles()
    generate_goal_flag()
    generate_bg_sky()
    print("P0 sprites generated.")


if __name__ == "__main__":
    main()
