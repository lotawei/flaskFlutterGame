#!/usr/bin/env python3
"""Blender 无头正交烘焙（仅渲染高分辨率透明 PNG 到 _bake_tmp）。

像素降采样由 scripts/blender/pixelate_bake_output.py 用系统 Pillow 完成。

  blender --background --python scripts/blender/bake_pixel_sprites.py
"""
from __future__ import annotations

import math
import os
import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
OUT_ROOT = Path(os.environ.get("BAKE_OUT_ROOT", str(REPO_ROOT / "app" / "assets" / "images")))
TMP = OUT_ROOT / "_bake_tmp"

PALETTE = {
    "coin": (1.0, 0.835, 0.310, 1.0),
    "coin_shine": (1.0, 0.961, 0.616, 1.0),
    "ground": (0.400, 0.733, 0.416, 1.0),
    "platform": (0.553, 0.431, 0.388, 1.0),
    "ceiling": (0.957, 0.561, 0.694, 1.0),
    "enemy": (0.937, 0.325, 0.314, 1.0),
    "portal": (1.0, 1.0, 1.0, 1.0),
    "portal_glow": (0.882, 0.745, 0.906, 1.0),
    "eye": (1.0, 0.992, 0.906, 1.0),
}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)


def make_emit(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = color
    emission.inputs["Strength"].default_value = 1.2
    links.new(emission.outputs["Emission"], output.inputs["Surface"])
    return mat


def setup_camera(ortho_scale: float = 1.2) -> None:
    bpy.ops.object.camera_add(location=(0.0, -5.0, 0.0), rotation=(math.radians(90.0), 0.0, 0.0))
    camera = bpy.context.active_object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = ortho_scale
    bpy.context.scene.camera = camera


def setup_render(resolution: int = 128) -> None:
    scene = bpy.context.scene
    # Blender 4.0 Debian 包: EEVEE
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 15


def render_png(path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    # filepath 不含扩展名时 Blender 会追加 .png
    bpy.context.scene.render.filepath = str(path.with_suffix(""))
    bpy.ops.render.render(write_still=True)
    out = path if path.suffix == ".png" else path.with_suffix(".png")
    if not out.exists():
        raise FileNotFoundError(f"render failed: {out}")
    print(f"rendered {out}")
    return out


def bake_coin() -> None:
    clear_scene()
    setup_camera(1.3)
    setup_render()
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=32,
        radius=0.48,
        depth=0.14,
        location=(0, 0, 0),
        rotation=(math.radians(90), 0, 0),
    )
    bpy.context.active_object.data.materials.append(make_emit("coin", PALETTE["coin"]))
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16,
        radius=0.16,
        depth=0.16,
        location=(-0.12, -0.05, 0.12),
        rotation=(math.radians(90), 0, 0),
    )
    bpy.context.active_object.data.materials.append(make_emit("shine", PALETTE["coin_shine"]))
    render_png(TMP / "coin.png")


def bake_tile(name: str, color_key: str) -> None:
    clear_scene()
    setup_camera(1.15)
    setup_render()
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    bpy.context.active_object.data.materials.append(make_emit(name, PALETTE[color_key]))
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.48, 0.32))
    bar = bpy.context.active_object
    bar.scale = (0.88, 0.04, 0.18)
    hi = (
        min(1.0, PALETTE[color_key][0] * 1.18),
        min(1.0, PALETTE[color_key][1] * 1.18),
        min(1.0, PALETTE[color_key][2] * 1.18),
        1.0,
    )
    bar.data.materials.append(make_emit(name + "_hi", hi))
    render_png(TMP / f"{name}.png")


def bake_portal_frames() -> None:
    for index in range(4):
        clear_scene()
        setup_camera(1.5)
        setup_render()
        pulse = 0.9 + 0.12 * math.sin(index / 4 * math.pi * 2)
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.55 * pulse,
            minor_radius=0.07,
            major_segments=48,
            minor_segments=16,
            location=(0, 0, 0),
            rotation=(math.radians(90), 0, 0),
        )
        bpy.context.active_object.data.materials.append(make_emit("portal", PALETTE["portal"]))
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(0, 0, 0))
        bpy.context.active_object.data.materials.append(make_emit("glow", PALETTE["portal_glow"]))
        render_png(TMP / f"portal_{index}.png")


def bake_enemy() -> None:
    clear_scene()
    setup_camera(1.35)
    setup_render()
    bpy.ops.mesh.primitive_cube_add(size=0.85, location=(0, 0, -0.05))
    bpy.context.active_object.data.materials.append(make_emit("enemy", PALETTE["enemy"]))
    for x in (-0.22, 0.22):
        bpy.ops.mesh.primitive_cone_add(
            vertices=4,
            radius1=0.16,
            depth=0.32,
            location=(x, 0, 0.42),
        )
        bpy.context.active_object.data.materials.append(make_emit("spike", PALETTE["enemy"]))
    for x in (-0.18, 0.18):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.07, location=(x, -0.42, 0.08))
        bpy.context.active_object.data.materials.append(make_emit("eye", PALETTE["eye"]))
    render_png(TMP / "enemy.png")


def main() -> None:
    TMP.mkdir(parents=True, exist_ok=True)
    raw = os.environ.get("BAKE_TARGETS", "ceiling,ground,platform,portal,coin,enemy")
    targets = [item.strip() for item in raw.split(",") if item.strip()]
    print(f"targets={targets} tmp={TMP}")
    for target in targets:
        if target == "coin":
            bake_coin()
        elif target == "ceiling":
            bake_tile("ceiling", "ceiling")
        elif target == "ground":
            bake_tile("ground", "ground")
        elif target == "platform":
            bake_tile("platform", "platform")
        elif target == "portal":
            bake_portal_frames()
        elif target == "enemy":
            bake_enemy()
        else:
            print(f"skip unknown: {target}")
    print("blender hi-res bake complete")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # noqa: BLE001
        print(f"BAKE_ERROR: {exc}", file=sys.stderr)
        raise
