"""Generate Spoked-O brand icons for the Flutter Web build.

This produces the favicon + PWA icon set as PNGs from a vector spec, so the
brand stays in sync with the in-app `BrandMark` widget.

The browser-tab favicon (16/32) gets a different treatment than the PWA
icons (192/512) on purpose:

  - **Favicon** (16/32): bold accent-yellow background with a dark wheel.
    Tabs render the favicon at 16×16 against varied browser chromes — a
    dark-on-dark icon disappears. Yellow stands out on every theme.
  - **PWA / launcher** (192/512): wheel on near-black, matching the in-app
    brand mark. These show on home-screens / app drawers / app-store
    listings with consistent backgrounds.

  Outputs:
    frontend/web/favicon.png                 32x32   (yellow tab badge)
    frontend/web/favicon-16.png              16x16   (smallest tab variant)
    frontend/web/icons/Icon-192.png          192x192 (PWA + apple-touch)
    frontend/web/icons/Icon-512.png          512x512
    frontend/web/icons/Icon-maskable-192.png 192x192 (PWA maskable, padded)
    frontend/web/icons/Icon-maskable-512.png 512x512

The maskable variants leave a 12% safe-zone around the mark so OS launchers
can apply rounded-square / squircle masks without clipping the wheel.
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

# Theme tokens — match lib/core/theme/tokens.dart.
DARK_BG = (14, 15, 17, 255)         # #0E0F11
LIGHT_FG = (246, 244, 238, 255)     # #F6F4EE
ACCENT_BG = (232, 197, 74, 255)     # #E8C54A — sodium yellow
ACCENT_INK = (42, 34, 13, 255)      # #2A220D — dark contrast on accent


def draw_spoked_o(
    size: int,
    bg: tuple,
    fg: tuple,
    *,
    safe_padding: float = 0.0,
    spokes: int = 8,
    rim_scale: float = 0.06,
    spoke_scale: float = 0.035,
    hub_scale: float = 0.085,
) -> Image.Image:
    """Render the wheel.

    `rim_scale`, `spoke_scale`, `hub_scale` control stroke / radius as
    a fraction of `size`. Tab-size icons need beefier strokes (~0.10 rim)
    so the wheel reads at 16×16; large PWA icons can use thinner strokes
    (~0.05) for a more elegant look.
    """
    img = Image.new("RGBA", (size, size), bg)
    d = ImageDraw.Draw(img)
    cx = cy = size / 2
    rim_stroke = max(2.0, size * rim_scale)
    spoke_stroke = max(1.5, size * spoke_scale)
    radius = size / 2 * (1 - safe_padding) - rim_stroke
    hub_radius = max(2.0, size * hub_scale)

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

    # ── Favicons (browser tab) — bold yellow background, dark wheel ──
    # Tab favicons are tiny; thin lines vanish. Switch palette to high-
    # contrast accent + use thicker strokes so the wheel reads at 16×16.
    write(
        os.path.join(web, "favicon.png"),
        draw_spoked_o(
            32, ACCENT_BG, ACCENT_INK,
            spokes=3, rim_scale=0.10, spoke_scale=0.07, hub_scale=0.16,
        ),
    )
    write(
        os.path.join(web, "favicon-16.png"),
        draw_spoked_o(
            16, ACCENT_BG, ACCENT_INK,
            spokes=3, rim_scale=0.13, spoke_scale=0.10, hub_scale=0.20,
        ),
    )

    # ── PWA icons (home screen / app drawer) — dark wheel on near-black ──
    write(
        os.path.join(web, "icons", "Icon-192.png"),
        draw_spoked_o(192, DARK_BG, LIGHT_FG, spokes=8),
    )
    write(
        os.path.join(web, "icons", "Icon-512.png"),
        draw_spoked_o(512, DARK_BG, LIGHT_FG, spokes=8),
    )
    write(
        os.path.join(web, "icons", "Icon-maskable-192.png"),
        draw_spoked_o(192, DARK_BG, LIGHT_FG, safe_padding=0.12, spokes=8),
    )
    write(
        os.path.join(web, "icons", "Icon-maskable-512.png"),
        draw_spoked_o(512, DARK_BG, LIGHT_FG, safe_padding=0.12, spokes=8),
    )


if __name__ == "__main__":
    main()
