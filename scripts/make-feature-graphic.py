#!/usr/bin/env python3
"""Generate the Play Store feature graphic (1024x500) from the brand mark.

Composition:
  • Left 60%: brand mark (Icon-512.png) centred + wordmark "Bike News Room"
    in a serif weight matching the in-app title font feel + tagline.
  • Right 40%: subtle yellow gradient streak echoing the in-app accent
    `#E8C54A`, suggests motion/speed without literal cycling clichés.
  • Background: `#0E0F11` matches the splash + in-app dark theme.

Run:
  python3 scripts/make-feature-graphic.py
Output: store-assets/graphics/feature-graphic-1024x500.png
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SRC_ICON = ROOT / "frontend" / "web" / "icons" / "Icon-512.png"
OUT = ROOT / "store-assets" / "graphics" / "feature-graphic-1024x500.png"
OUT.parent.mkdir(parents=True, exist_ok=True)

W, H = 1024, 500
BG = (14, 15, 17)              # #0E0F11
ACCENT = (232, 197, 74)        # #E8C54A
INK = (240, 240, 240)
INK_DIM = (170, 170, 170)

img = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(img, "RGBA")

# Right-side accent gradient streak — diagonal yellow wedge that fades to bg.
# Subtle motion cue, not a literal pictogram.
for x in range(int(W * 0.55), W):
    ratio = (x - W * 0.55) / (W - W * 0.55)
    alpha = int(60 * ratio)
    # Slight downward sweep — top-right is brighter.
    top_band = int(H * 0.15 * ratio)
    draw.line([(x, top_band), (x, H)], fill=(*ACCENT, alpha))

# Brand mark on the left
ICON_SIZE = 200
icon = Image.open(SRC_ICON).convert("RGBA").resize(
    (ICON_SIZE, ICON_SIZE), Image.LANCZOS
)
icon_x, icon_y = 80, (H - ICON_SIZE) // 2
img.paste(icon, (icon_x, icon_y), icon)

# Try to find a serif + sans font that ships on macOS; fall back to PIL default.
def load_font(candidates, size):
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()

serif = load_font(
    [
        "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
        "/System/Library/Fonts/NewYork.ttf",
        "/Library/Fonts/Georgia.ttf",
    ],
    72,
)
sans = load_font(
    [
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ],
    24,
)
mono = load_font(
    [
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Supplemental/Andale Mono.ttf",
    ],
    18,
)

text_x = icon_x + ICON_SIZE + 40
draw.text((text_x, 160), "Bike News", fill=INK, font=serif)
draw.text((text_x, 240), "Room", fill=ACCENT, font=serif)
draw.text(
    (text_x, 340),
    "Cycling news from every team, every race, every region.",
    fill=INK_DIM,
    font=sans,
)
draw.text(
    (text_x, 380), "REFRESHED EVERY 30 MINUTES", fill=ACCENT, font=mono
)

img.save(OUT, "PNG", optimize=True)
print(f"✓ {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)")
