#!/usr/bin/env python3
"""Convert raw device screenshots into Play-Console-ready phone screenshots.

Play accepts 1080×1920 (or any 16:9 / 9:16 aspect) PNG/JPEG, 1MB max each,
2-8 per language. Galaxy S25 captures at 1080×2340 — too tall for 16:9
and slightly under 1080 width is fine, but Play renders better when we
crop the system status bar + nav bar so the in-app chrome takes the
whole frame.

This script:
1. Picks the curated subset (drop dupes, drop anything still in Polish
   for the EN listing).
2. Crops top 92px (status bar) + bottom 144px (nav bar) → 1080×2104.
3. Resizes to 1080×1920 by gentle vertical squash (4 % — visually
   indistinguishable, keeps Play's aspect requirement).
4. Re-saves as optimized PNG.
5. Writes store-assets/screenshots/play/ output + a per-screenshot
   caption manifest in JSON for paste-into-Play.
"""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "store-assets" / "screenshots" / "raw"
OUT_EN = ROOT / "store-assets" / "screenshots" / "play-en"
OUT_PL = ROOT / "store-assets" / "screenshots" / "play-pl"
OUT_EN.mkdir(parents=True, exist_ok=True)
OUT_PL.mkdir(parents=True, exist_ok=True)

# Curated set — order matters; users see screenshot 1+2 the most. Lead
# with the strongest visual.
EN_PIPELINE = [
    ("06_feed_english.png",         "01-feed.png",        "One feed for every team, every race."),
    ("07_article_modal_en.png",     "02-article.png",     "Tap any story for the full read."),
    ("12_feed_with_filters.png",    "03-filters.png",     "Filter by region + discipline. Save filters as defaults."),
    ("11_filter_drawer.png",        "04-filter-drawer.png","Six disciplines. Four regions. Six categories."),
    ("10_settings_en.png",          "05-settings.png",    "Dark + light themes. Nine languages. No login."),
]

PL_PIPELINE = [
    ("05_feed_polish.png",          "01-feed.png",        "Wszystkie wiadomości kolarskie w jednym miejscu."),
    ("01_onboarding_step1.png",     "02-onboarding.png",  "Wybierz regiony i dyscypliny — gotowe w 30 sekund."),
    ("03_onboarding_disciplines.png","03-disciplines.png", "Szosa, MTB, gravel, tor, przełaj, BMX."),
]

# Crop 92 px status bar from top, 144 px Samsung nav bar from bottom.
TOP_CROP = 92
BOTTOM_CROP = 144
PLAY_W = 1080
PLAY_H = 1920

def process(src: Path, dst: Path) -> dict:
    img = Image.open(src).convert("RGB")
    w, h = img.size
    cropped = img.crop((0, TOP_CROP, w, h - BOTTOM_CROP))
    # Squash to exactly 1080x1920 — within 4% so visually unchanged.
    final = cropped.resize((PLAY_W, PLAY_H), Image.LANCZOS)
    final.save(dst, "PNG", optimize=True)
    return {"src": str(src.name), "dst": str(dst.name), "size_kb": dst.stat().st_size // 1024}

def run(pipeline, out_dir: Path, locale: str):
    manifest = []
    for src_name, dst_name, caption in pipeline:
        src = RAW / src_name
        if not src.exists():
            print(f"  ✗ skipped (missing): {src_name}")
            continue
        info = process(src, out_dir / dst_name)
        info["caption"] = caption
        info["locale"] = locale
        manifest.append(info)
        print(f"  ✓ {dst_name} — {info['size_kb']} KB · {caption}")
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    return manifest

print("EN pipeline →", OUT_EN.relative_to(ROOT))
en = run(EN_PIPELINE, OUT_EN, "en-US")
print()
print("PL pipeline →", OUT_PL.relative_to(ROOT))
pl = run(PL_PIPELINE, OUT_PL, "pl")
print()
print(f"Total: {len(en) + len(pl)} screenshots ready for Play Console.")
