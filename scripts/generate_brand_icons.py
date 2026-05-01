"""Generate Spoked-O brand icons for the Flutter Web build.

This produces the favicon + PWA icon set as PNGs from a vector spec, so the
brand stays in sync with the in-app `BrandMark` widget. Re-run after any
brand-shape change.

  Outputs:
    frontend/web/favicon.png                 32x32
    frontend/web/icons/Icon-192.png          192x192   (PWA + apple-touch)
    frontend/web/icons/Icon-512.png          512x512
    frontend/web/icons/Icon-maskable-192.png 192x192   (PWA maskable, padded)
    frontend/web/icons/Icon-maskable-512.png 512x512

The maskable variants leave a 12% safe-zone around the mark so OS launchers
can apply rounded-square / squircle masks without clipping the wheel.
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

BG = (14, 15, 17, 255)
FG = (246, 244, 238, 255)


def draw_spoked_o(
    size: int,
    bg: tuple,
    fg: tuple,
    *,
    safe_padding: float = 0.0,
    spokes: int = 8,
) -> Image.Image:
    img = Image.new("RGBA", (size, size), bg)
    d = ImageDraw.Draw(img)
    cx = cy = size / 2
    rim_stroke = max(2.0, size * 0.06)
    spoke_stroke = max(1.2, size * 0.035)
    radius = size / 2 * (1 - safe_padding) - rim_stroke
    hub_radius = max(2.0, size * 0.08)
    d.ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        outline=fg,
        width=int(round(rim_stroke)),
    )
    spoke_radius = radius * 0.96
    for i in range(spokes):
        angle = (math.pi * i) / spokes
        dx = math.cos(angle) * spoke_radius
        dy = math.sin(angle) * spoke_radius
        d.line(
            (cx - dx, cy - dy, cx + dx, cy + dy),
            fill=fg,
            width=int(round(spoke_stroke)),
        )
    d.ellipse(
        (cx - hub_radius, cy - hub_radius, cx + hub_radius, cy + hub_radius),
        fill=fg,
    )
    return img


def write(path: str, img: Image.Image) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print(f"  wrote {path}  {img.size[0]}x{img.size[1]}")


def main() -> None:
    web = os.path.join(os.path.dirname(__file__), "..", "frontend", "web")
    web = os.path.abspath(web)
    write(os.path.join(web, "favicon.png"),
          draw_spoked_o(32, BG, FG, spokes=4))
    write(os.path.join(web, "icons", "Icon-192.png"),
          draw_spoked_o(192, BG, FG, spokes=8))
    write(os.path.join(web, "icons", "Icon-512.png"),
          draw_spoked_o(512, BG, FG, spokes=8))
    write(os.path.join(web, "icons", "Icon-maskable-192.png"),
          draw_spoked_o(192, BG, FG, safe_padding=0.12, spokes=8))
    write(os.path.join(web, "icons", "Icon-maskable-512.png"),
          draw_spoked_o(512, BG, FG, safe_padding=0.12, spokes=8))


if __name__ == "__main__":
    main()
