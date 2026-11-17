#!/usr/bin/env python3
"""Regenerate Capitán's app icons from branding/app_icon_source.jpg.

The source artwork is a full app-icon badge centred on a near-white canvas.
This script crops it, fills the rounded corners so the icon is full-bleed,
and writes every platform size (Android, iOS, macOS, web, Windows, F-Droid).

Requires Pillow and numpy:

    python3 tools/generate_icons.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "branding" / "app_icon_source.jpg"
MASTER = ROOT / "branding" / "app_icon.png"


def shifted(array: np.ndarray, dy: int, dx: int, fill) -> np.ndarray:
    """Return array shifted by (dy, dx), padding with fill."""
    if array.ndim == 2:
        padding = ((1, 1), (1, 1))
    else:
        padding = ((1, 1), (1, 1), (0, 0))
    padded = np.pad(array, padding, constant_values=fill)
    height, width = array.shape[:2]
    return padded[1 + dy : 1 + dy + height, 1 + dx : 1 + dx + width]


def dilate(mask: np.ndarray) -> np.ndarray:
    padded = np.pad(mask, 1, constant_values=False)
    return (
        padded[1:-1, 1:-1]
        | padded[:-2, 1:-1]
        | padded[2:, 1:-1]
        | padded[1:-1, :-2]
        | padded[1:-1, 2:]
    )


def erode(mask: np.ndarray, iterations: int = 1) -> np.ndarray:
    for _ in range(iterations):
        padded = np.pad(mask, 1, constant_values=False)
        mask = (
            padded[1:-1, 1:-1]
            & padded[:-2, 1:-1]
            & padded[2:, 1:-1]
            & padded[1:-1, :-2]
            & padded[1:-1, 2:]
        )
    return mask


def badge_mask(luminance: np.ndarray) -> np.ndarray:
    """Return the badge region, including white artwork inside the badge."""
    dark = luminance < 235
    outside = np.zeros_like(dark)
    outside[0, :] = ~dark[0, :]
    outside[-1, :] = ~dark[-1, :]
    outside[:, 0] = ~dark[:, 0]
    outside[:, -1] = ~dark[:, -1]
    while True:
        grown = outside | (dilate(outside) & ~dark)
        if np.array_equal(grown, outside):
            break
        outside = grown
    return ~outside



def fill_from_mask(rgb: np.ndarray, known: np.ndarray) -> np.ndarray:
    """Fill unknown pixels with colours propagated from the nearest edge."""
    out = rgb.astype(np.float32)
    known = known.copy()
    height, width = known.shape
    for _ in range(max(height, width)):
        if known.all():
            break
        count = np.zeros((height, width), np.float32)
        total = np.zeros((height, width, 3), np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                neighbour_known = shifted(known, dy, dx, False)
                neighbour_colour = shifted(out, dy, dx, 0.0)
                count += neighbour_known
                total += neighbour_colour * neighbour_known[..., None]
        fillable = (~known) & (count > 0)
        out[fillable] = total[fillable] / count[fillable][:, None]
        known |= fillable
    if not known.all():
        raise RuntimeError("could not fill the icon background")
    return np.clip(out, 0, 255).astype(np.uint8)


def extract_master() -> tuple[Image.Image, Image.Image]:
    image = Image.open(SOURCE).convert("RGB")
    rgb = np.asarray(image).astype(np.int16)
    luminance = rgb.mean(axis=2)

    # The badge is the only dark region on the near-white canvas.
    mask = luminance < 235
    ys, xs = np.nonzero(mask)
    side = max(xs.max() - xs.min() + 1, ys.max() - ys.min() + 1)
    cx = (xs.min() + xs.max() + 1) / 2
    cy = (ys.min() + ys.max() + 1) / 2
    left = int(round(cx - side / 2))
    top = int(round(cy - side / 2))
    crop = rgb[top : top + side, left : left + side].copy()

    crop_luminance = crop.mean(axis=2)
    badge = erode(badge_mask(crop_luminance), 2)
    filled = fill_from_mask(crop, badge)

    master = Image.fromarray(filled, "RGB").resize((1024, 1024), Image.LANCZOS)
    alpha = Image.fromarray((badge * 255).astype(np.uint8), "L").resize(
        (1024, 1024), Image.LANCZOS
    )
    MASTER.parent.mkdir(parents=True, exist_ok=True)
    master.save(MASTER, optimize=True)
    return master, alpha


def make_adaptive(master: Image.Image, canvas: int = 1024, content: float = 0.72) -> Image.Image:
    """Place the icon in the adaptive safe zone and extend its edges outward."""
    inner_size = round(canvas * content)
    inner = master.resize((inner_size, inner_size), Image.LANCZOS)
    array = np.asarray(inner)
    offset = (canvas - inner_size) // 2
    ys = np.clip(np.arange(canvas), offset, offset + inner_size - 1) - offset
    xs = np.clip(np.arange(canvas), offset, offset + inner_size - 1) - offset
    extended = array[ys[:, None], xs[None, :]]
    return Image.fromarray(extended, "RGB")


def make_macos(master: Image.Image, alpha: Image.Image, canvas: int = 1024, content: float = 0.84) -> Image.Image:
    """Return a padded, rounded macOS icon with transparent corners."""
    inner_size = round(canvas * content)
    inner = master.resize((inner_size, inner_size), Image.LANCZOS).convert("RGBA")
    inner.putalpha(alpha.resize((inner_size, inner_size), Image.LANCZOS))
    icon = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    offset = (canvas - inner_size) // 2
    icon.paste(inner, (offset, offset), inner)
    return icon


def save(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.LANCZOS).save(path, optimize=True)


def write_android(master: Image.Image, adaptive: Image.Image) -> None:
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in legacy.items():
        save(master, res / f"mipmap-{density}" / "ic_launcher.png", size)

    # Android 8+ adaptive icon. The background bitmap already contains the
    # icon inside the 72dp safe zone, with its edge colours extended outward.
    adaptive_sizes = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for density, size in adaptive_sizes.items():
        save(adaptive, res / f"mipmap-{density}" / "ic_launcher_background.png", size)

    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
        '    <foreground android:drawable="@android:color/transparent" />\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )


def write_appiconset(master: Image.Image, directory: Path) -> None:
    contents = json.loads((directory / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents.get("images", []):
        filename = entry.get("filename")
        if not filename:
            continue
        width = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        save(master, directory / filename, round(width * scale))


def write_web(master: Image.Image, adaptive: Image.Image) -> None:
    save(master, ROOT / "web" / "favicon.png", 32)
    save(master, ROOT / "web" / "icons" / "Icon-192.png", 192)
    save(master, ROOT / "web" / "icons" / "Icon-512.png", 512)
    save(adaptive, ROOT / "web" / "icons" / "Icon-maskable-192.png", 192)
    save(adaptive, ROOT / "web" / "icons" / "Icon-maskable-512.png", 512)


def write_windows(master: Image.Image) -> None:
    target = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    master.save(
        target,
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


def write_fdroid(master: Image.Image) -> None:
    save(master, ROOT / "fastlane" / "metadata" / "android" / "en-US" / "images" / "icon.png", 512)


def main() -> None:
    master, alpha = extract_master()
    adaptive = make_adaptive(master)
    macos = make_macos(master, alpha)
    adaptive.save(ROOT / "branding" / "app_icon_adaptive.png", optimize=True)
    macos.save(ROOT / "branding" / "app_icon_macos.png", optimize=True)

    write_android(master, adaptive)
    write_appiconset(master, ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset")
    write_appiconset(macos, ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset")
    write_web(master, adaptive)
    write_windows(master)
    write_fdroid(master)
    print(f"wrote icons from {MASTER.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
