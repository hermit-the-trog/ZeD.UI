"""
Bake the window tab icons at every size the scaled UI draws (ZeD-UI, Oct 13 2026).

The tab strips draw icons at 16 design units, i.e. 16 / 21 / 32 / 43 / 64 screen px
at root scale 1 / 1.33 / 2 / 2.67 / 4. A single 16 px texture stretched to those
sizes goes soft, so each icon is baked from its 512 px master
(ZeDUI/TabIcons/OG/<name>.png) at 8-64 px (every UI scale step: 0.5x .. 2x, the Large text preset, auto roots); the game picks the
smallest baked size at or above the drawn size (ZeD.Atoms.sizedTexture).

Masters: white glyphs on transparent (L+A). A dark glyph master (vehicle-tab.png)
is turned white, keeping its alpha.
Output: 42/media/textures/ZeD/TabIcons/<name>_<size>.png (unique names: vanilla
packed textures can capture shared base names, Q143).

Usage:  py -3.14 ZeDUI/tools/icons/bake_tab_icons.py
"""
import os
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OG = os.path.join(ROOT, "ZeDUI", "TabIcons", "OG")
OUT = os.path.join(ROOT, "42", "media", "textures", "ZeD", "TabIcons")
SIZES = (8, 12, 16, 20, 24, 28, 32, 36, 40, 48, 56, 64)   # 16 design units x every UI scale step (and the Large text preset)

# output name -> master file in OG
ICONS = {
    "loot-tab-white": "loot-tab-white.png",
    "craft-tab-white": "craft-tab-white.png",
    "build-tab-white": "build-tab-white.png",
    "map-tab-white": "map-tab-white.png",
    "forage-tab-white": "forage-tab-white.png",
    "farm-tab-white": "farm-tab-white.png",
    "radio-tab-white": "radio-tab-white.png",
    "vehicle-tab-white": "vehicle-tab.png",       # dark master, made white
    "move-tab-white": "move-tab.png",             # Furniture tab (dark master, made white)
    "equipment-tab-white": "equipment-tab-white.png",
    "health-tab-white": "health-tab-white.png",
    "thermal-tab-white": "thermal-tab-white.png",
    "identy-tab-white": "identy-tab-white.png",
    "journal-tab-white": "journal-tab-white.png",
    "skills-tab-white": "skills-tab-white.png",
}

def white_alpha(path):
    im = Image.open(path).convert("RGBA")
    return im.split()[3]

def main():
    n = 0
    for name, master in ICONS.items():
        src = os.path.join(OG, master)
        if not os.path.exists(src):
            print("missing master: " + src)
            continue
        alpha = white_alpha(src)
        for s in SIZES:
            a = alpha.resize((s, s), Image.LANCZOS)
            out = Image.merge("RGBA", (Image.new("L", (s, s), 255),) * 3 + (a,))
            out.save(os.path.join(OUT, f"{name}_{s}.png"), optimize=True)
            n += 1
    print(f"baked {n} icon textures into {OUT}")

if __name__ == "__main__":
    main()
