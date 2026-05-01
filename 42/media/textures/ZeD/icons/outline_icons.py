"""
Add subtle black outline to icon PNGs to match vanilla PZ's outlined icon style.
Vanilla PZ uses ~1px outline on 64x64 icons. Our 512px icons need ~4px radius
to achieve the same visual weight when downscaled to 16-32px display.

Run from this directory: python outline_icons.py

NOT idempotent — re-copy clean PNGs from source before re-running.
"""
from PIL import Image, ImageFilter
import os

# Vanilla PZ: ~1px outline on 64px icons = 1.5% of icon size
# Our icons: 512px * 1.5% ≈ 8px radius — but that's at source, displayed at 24px
# We want ~1px visible at display. 512/24 ≈ 21 would be 1px at display but too thick.
# Vanilla outline is subtle. Target ~4px at source for a hint of edge definition.
OUTLINE_RADIUS = 4

def add_outline(img_path):
    img = Image.open(img_path).convert("RGBA")

    alpha = img.split()[3]
    dilated = alpha.filter(ImageFilter.MaxFilter(OUTLINE_RADIUS * 2 + 1))

    # Black silhouette from dilated mask
    outline = Image.new("RGBA", img.size, (0, 0, 0, 255))
    outline.putalpha(dilated)
    # Composite: original on top of black outline
    result = Image.alpha_composite(outline, img)
    result.save(img_path)

count = 0
script_name = os.path.basename(__file__)
for f in sorted(os.listdir(".")):
    if f.lower().endswith(".png") and f != script_name:
        add_outline(f)
        count += 1

print(f"Done. Outlined {count} icons (radius={OUTLINE_RADIUS}px).")
