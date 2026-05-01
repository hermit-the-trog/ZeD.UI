"""
Generate BMFont .fnt + .png atlas files from a TTF font.
Replaces Silkscreen Bold with Flexi IBM VGA True for ZeD-UI.

Usage:
    python gen_bmfont.py

Outputs silk700m, silk700, silk700lg at 2x/3x/4x scales into the
mod's media/fonts/EN/ directories.
"""

import os
import math
from PIL import Image, ImageFont, ImageDraw

# ── Config ──────────────────────────────────────────────────────────────
TTF_PATH = r"C:\Users\danie\Downloads\flexi_ibm_vga_true\Flexi_IBM_VGA_True.ttf"
OUT_ROOT = r"C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\fonts\EN"
FACE_NAME = "Flexi IBM VGA True"

# Font sizes: (output_name, base_px)
SIZES = [
    ("silk700m", 11),   # fontSec small/medium preset
    ("silk700",  14),   # fontSec large preset
    ("silk700lg", 20),  # fontSec xl preset (commented out)
]

SCALES = [2, 3, 4]

# Characters to include (same set as existing Silkscreen .fnt files)
CHAR_IDS = list(range(32, 127))       # ASCII printable
CHAR_IDS += list(range(160, 256))     # Latin-1 supplement
CHAR_IDS += [8211, 8212, 8216, 8217, 8220, 8221, 8226, 8230, 8364]  # typographic

ATLAS_W = 1024  # atlas width (matches existing)


def generate_bmfont(ttf_path, face_name, font_size, out_name, out_dir):
    """Generate a single .fnt + .png pair."""
    font = ImageFont.truetype(ttf_path, font_size)

    # Measure all characters
    chars = []
    for cid in CHAR_IDS:
        ch = chr(cid)
        try:
            bbox = font.getbbox(ch)
        except Exception:
            continue
        if bbox is None:
            continue

        left, top, right, bottom = bbox
        w = right - left
        h = bottom - top
        # getbbox returns tight bounding box relative to origin
        # xoffset = left edge offset, yoffset = top edge offset from top of line
        advance = font.getlength(ch)
        if w <= 0 or h <= 0:
            # Space or zero-width — still include with minimal glyph
            chars.append({
                "id": cid, "ch": ch,
                "w": max(1, w), "h": max(1, h),
                "xoff": left, "yoff": top,
                "xadv": int(round(advance)),
                "img": None,
            })
            continue

        # Render glyph to image
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        draw.text((-left, -top), ch, fill=(255, 255, 255, 255), font=font)

        chars.append({
            "id": cid, "ch": ch,
            "w": w, "h": h,
            "xoff": left, "yoff": top,
            "xadv": int(round(advance)),
            "img": img,
        })

    # Get font metrics for line height / baseline
    ascent, descent = font.getmetrics()
    line_height = ascent + descent
    base = ascent

    # Pack glyphs into atlas (simple left-to-right, top-to-bottom)
    spacing = 1
    atlas_w = ATLAS_W
    cx, cy = spacing, spacing
    row_h = 0

    for c in chars:
        gw = c["w"] + spacing
        if cx + gw > atlas_w:
            cy += row_h + spacing
            cx = spacing
            row_h = 0
        c["ax"] = cx
        c["ay"] = cy
        cx += gw
        row_h = max(row_h, c["h"])

    atlas_h_raw = cy + row_h + spacing
    # Round up to power of 2 for GPU friendliness (PZ prefers it)
    atlas_h = 1
    while atlas_h < atlas_h_raw:
        atlas_h *= 2
    # Cap at reasonable size
    atlas_h = min(atlas_h, 2048)

    # Render atlas
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
    for c in chars:
        if c["img"] is not None:
            atlas.paste(c["img"], (c["ax"], c["ay"]))

    # Write .png
    os.makedirs(out_dir, exist_ok=True)
    png_name = f"{out_name}_0.png"
    atlas.save(os.path.join(out_dir, png_name))

    # Write .fnt
    fnt_lines = []
    fnt_lines.append(
        f'info face="{face_name}" size={font_size} bold=0 italic=0 '
        f'charset="" unicode=1 stretchH=100 smooth=1 aa=2 '
        f'padding=0,0,0,0 spacing={spacing},{spacing} outline=0'
    )
    fnt_lines.append(
        f'common lineHeight={line_height} base={base} '
        f'scaleW={atlas_w} scaleH={atlas_h} pages=1 packed=0 '
        f'alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4'
    )
    fnt_lines.append(f'page id=0 file="{png_name}"')
    fnt_lines.append(f'chars count={len(chars)}')

    for c in chars:
        fnt_lines.append(
            f'char id={c["id"]:<6d}'
            f'x={c["ax"]:<8d}'
            f'y={c["ay"]:<8d}'
            f'width={c["w"]:<8d}'
            f'height={c["h"]:<8d}'
            f'xoffset={c["xoff"]:<6d}'
            f'yoffset={c["yoff"]:<6d}'
            f'xadvance={c["xadv"]:<8d}'
            f'page=0  chnl=15'
        )

    fnt_path = os.path.join(out_dir, f"{out_name}.fnt")
    with open(fnt_path, "w", encoding="utf-8") as f:
        f.write("\n".join(fnt_lines) + "\n")

    print(f"  {out_dir}/{out_name}: {len(chars)} chars, atlas {atlas_w}x{atlas_h}")


def main():
    print(f"TTF: {TTF_PATH}")
    print(f"Output: {OUT_ROOT}")
    print()

    for name, base_px in SIZES:
        for scale in SCALES:
            render_px = base_px * scale
            scale_dir = os.path.join(OUT_ROOT, f"{scale}x")
            print(f"Generating {name} @ {scale}x ({render_px}px)...")
            generate_bmfont(TTF_PATH, FACE_NAME, render_px, name, scale_dir)

    print("\nDone! Replace complete.")


if __name__ == "__main__":
    main()
