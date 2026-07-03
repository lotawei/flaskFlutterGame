#!/usr/bin/env python3
"""去除图片右下角水印区域（简单裁剪/填充方案）。"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


def remove_watermark_by_crop(
    input_path: Path,
    output_path: Path,
    crop_right_ratio: float = 0.22,
    crop_bottom_ratio: float = 0.08,
) -> None:
    """裁切右下角水印区域后等比还原尺寸。"""
    image: Image.Image = Image.open(input_path).convert("RGB")
    width, height = image.size
    crop_width: int = int(width * (1 - crop_right_ratio))
    crop_height: int = int(height * (1 - crop_bottom_ratio))
    cropped: Image.Image = image.crop((0, 0, crop_width, crop_height))
    restored: Image.Image = cropped.resize((width, height), Image.Resampling.LANCZOS)
    restored.save(output_path)
    print(f"已输出: {output_path}")


def remove_watermark_by_fill(
    input_path: Path,
    output_path: Path,
    fill_width_ratio: float = 0.24,
    fill_height_ratio: float = 0.07,
) -> None:
    """用右下角邻近区域平均色块覆盖水印（适合纯色/渐变背景）。"""
    image: Image.Image = Image.open(input_path).convert("RGB")
    width, height = image.size
    fill_left: int = int(width * (1 - fill_width_ratio))
    fill_top: int = int(height * (1 - fill_height_ratio))
    sample_box = (
        max(0, fill_left - 20),
        max(0, fill_top - 20),
        fill_left,
        fill_top,
    )
    sample: Image.Image = image.crop(sample_box)
    avg_color = tuple(int(v) for v in sample.resize((1, 1)).getpixel((0, 0)))
    draw = ImageDraw.Draw(image)
    draw.rectangle((fill_left, fill_top, width, height), fill=avg_color)
    image.save(output_path)
    print(f"已输出: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="去除右下角 AI 水印")
    parser.add_argument("input", type=Path, help="输入图片路径")
    parser.add_argument("-o", "--output", type=Path, help="输出路径")
    parser.add_argument(
        "--mode",
        choices=("fill", "crop"),
        default="fill",
        help="fill=色块覆盖（推荐浅灰底）; crop=裁切后拉伸",
    )
    args = parser.parse_args()
    output: Path = args.output or args.input.with_name(
        f"{args.input.stem}_no_watermark{args.input.suffix}"
    )
    if args.mode == "crop":
        remove_watermark_by_crop(args.input, output)
    else:
        remove_watermark_by_fill(args.input, output)


if __name__ == "__main__":
    main()
