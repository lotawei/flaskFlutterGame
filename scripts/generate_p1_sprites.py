#!/usr/bin/env python3
"""生成 P1 像素资产：敌人、UI 按钮。"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "app" / "assets" / "images"
OUTLINE = (26, 26, 26, 255)
ENEMY = (213, 0, 0, 255)
ENEMY_EYE = (255, 235, 59, 255)
BTN_BG = (33, 33, 33, 180)
BTN_BORDER = (255, 255, 255, 80)


def save_image(image: Image.Image, relative_path: str) -> None:
    target = ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, format="PNG")
    print(f"saved {target}")


def generate_enemy_sheet() -> None:
    frame_w, frame_h = 28, 28
    frames = 4
    sheet = Image.new("RGBA", (frame_w * frames, frame_h), (0, 0, 0, 0))
    for index in range(frames):
        frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(frame)
        offset = index % 2
        draw.rectangle((4, 6 + offset, 23, 24), fill=ENEMY, outline=OUTLINE)
        draw.ellipse((8, 10 + offset, 12, 14 + offset), fill=ENEMY_EYE)
        draw.ellipse((16, 10 + offset, 20, 14 + offset), fill=ENEMY_EYE)
        draw.line((8, 18 + offset, 20, 18 + offset), fill=OUTLINE, width=2)
        leg = 2 if index % 2 == 0 else -2
        draw.rectangle((8 + leg, 22, 11 + leg, 26), fill=OUTLINE)
        draw.rectangle((17 - leg, 22, 20 - leg, 26), fill=OUTLINE)
        sheet.paste(frame, (index * frame_w, 0))
    save_image(sheet, "sprites/enemies/enemy_basic_sheet.png")


def generate_ui_button(label: str, width: int, height: int, path: str) -> None:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((0, 0, width - 1, height - 1), radius=8, fill=BTN_BG, outline=BTN_BORDER, width=2)
    save_image(image, path)


def main() -> None:
    generate_enemy_sheet()
    generate_ui_button("left", 56, 56, "ui/buttons/ui_btn_left.png")
    generate_ui_button("right", 56, 56, "ui/buttons/ui_btn_right.png")
    generate_ui_button("jump", 72, 56, "ui/buttons/ui_btn_jump.png")
    print("P1 sprites generated.")


if __name__ == "__main__":
    main()
