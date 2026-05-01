"""
Generate BMFont-format bitmap fonts for ZeD-UI.
Produces .fnt + .png pairs at 4 scales (1x, 2x, 3x, 4x).

Pairing D: Fira Mono + Fira Sans Condensed (SIL OFL).
5 typography roles × 2 size presets = 10 active fonts:

  sec        — Fira Mono Bold               11px  (NewMedium — F1 Chrome @ small)
  secLg      — Fira Mono Bold               13px  (NewSmall  — F1 Chrome @ large)
  body       — Fira Sans Medium              13px  (Small     — F2 Body @ small)
  bodyLg     — Fira Sans Medium              15px  (Large     — F2 Body @ large)
  stat       — Fira Mono Regular            11px  (Medium    — F3 Data @ small)
  statLg     — Fira Mono Regular            13px  (CodeMedium— F3 Data @ large)
  head       — Fira Sans Cond. SemiBold     15px  (NewLarge  — F4 Heading @ small)
  headLg     — Fira Sans Cond. SemiBold     17px  (CodeLarge — F4 Heading @ large)
  title      — Fira Sans Cond. Regular       9px  (Code      — F5 Micro @ small)
  titleLg    — Fira Sans Cond. Regular      11px  (CodeSmall — F5 Micro @ large)

Reserved slots (4 — speech, TV/radio, HOW YOU DIED, TBD):
  rsv1       — Chicago                      20px  (Cred1)
  rsv2       — Chicago                      24px  (Cred2)
  rsv3       — Lekton Bold                  16px  (MainMenu1)
  rsv4       — Lekton Bold                  20px  (MainMenu2)
"""

import os
import sys
from PIL import Image, ImageFont, ImageDraw

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
FONT_DIR = os.path.expanduser("~/AppData/Local/Microsoft/Windows/Fonts")
FONT_DIR_SYS = os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts")

def _find_font(name):
    """Find font in local or system font directory."""
    local = os.path.join(FONT_DIR, name)
    if os.path.isfile(local):
        return local
    system = os.path.join(FONT_DIR_SYS, name)
    if os.path.isfile(system):
        return system
    return local  # fallback — will fail with clear error

FONT_SIZES = {
    # 5 roles × 2 size presets = 10 active slots
    "sec":       11,   # F1 Chrome — Fira Mono Bold @ small
    "secLg":     13,   # F1 Chrome — Fira Mono Bold @ large
    "body":      13,   # F2 Body — Fira Sans Regular @ small
    "bodyLg":    15,   # F2 Body — Fira Sans Regular @ large
    "stat":      11,   # F3 Data — Fira Mono Regular @ small
    "statLg":    13,   # F3 Data — Fira Mono Regular @ large
    "head":      15,   # F4 Heading — Fira Sans Condensed SemiBold @ small
    "headLg":    17,   # F4 Heading — Fira Sans Condensed SemiBold @ large
    "title":      9,   # F5 Micro — Fira Sans Condensed Regular @ small
    "titleLg":   11,   # F5 Micro — Fira Sans Condensed Regular @ large
    # 4 reserved (placeholders — unchanged)
    "rsv1":      20,
    "rsv2":      24,
    "rsv3":      16,
    "rsv4":      20,
}

# Font definitions: (ttf_path, face_name, bold, italic, var_axes)
# var_axes: list of axis values for variable fonts, or None
_FIRA_SANS_SEMI  = _find_font("FiraSansCondensed-SemiBold.ttf")
_FIRA_SANS_COND  = _find_font("FiraSansCondensed-Regular.ttf")
_FIRA_SANS_MED   = _find_font("FiraSans-Medium.ttf")
_FIRA_MONO_BOLD  = _find_font("FiraMono-Bold.ttf")
_FIRA_MONO_REG   = _find_font("FiraMono-Regular.ttf")
# Reserved slots still use Chicago + Lekton until those roles are specced
_CHIC = _find_font("ChicagoFLF.ttf")
_LEKT = _find_font("Lekton-Bold.ttf")

FONTS = {
    # F1 Chrome — Fira Mono Bold (title bars, tabs, button labels)
    "sec":     (_FIRA_MONO_BOLD, "Fira Mono", 1, 0, None),
    "secLg":   (_FIRA_MONO_BOLD, "Fira Mono", 1, 0, None),
    # F2 Body — Fira Sans Medium (list rows, content text)
    "body":    (_FIRA_SANS_MED,  "Fira Sans", 0, 0, None),
    "bodyLg":  (_FIRA_SANS_MED,  "Fira Sans", 0, 0, None),
    # F3 Data — Fira Mono Regular (numbers, percentages, stat values)
    "stat":    (_FIRA_MONO_REG,  "Fira Mono", 0, 0, None),
    "statLg":  (_FIRA_MONO_REG,  "Fira Mono", 0, 0, None),
    # F4 Heading — Fira Sans Condensed SemiBold (section headers, item names)
    "head":    (_FIRA_SANS_SEMI, "Fira Sans Condensed", 0, 0, None),
    "headLg":  (_FIRA_SANS_SEMI, "Fira Sans Condensed", 0, 0, None),
    # F5 Micro — Fira Sans Condensed Regular (chips, badges, metadata labels)
    "title":   (_FIRA_SANS_COND, "Fira Sans Condensed", 0, 0, None),
    "titleLg": (_FIRA_SANS_COND, "Fira Sans Condensed", 0, 0, None),
    # Reserved (unchanged)
    "rsv1":    (_CHIC, "Chicago", 0, 0, None),
    "rsv2":    (_CHIC, "Chicago", 0, 0, None),
    "rsv3":    (_LEKT, "Lekton",  1, 0, None),
    "rsv4":    (_LEKT, "Lekton",  1, 0, None),
}

# Character set — ASCII + extended Latin + smart quotes/dashes/currency
CHAR_IDS = list(range(32, 127)) + list(range(160, 256)) + [8211, 8212, 8216, 8217, 8220, 8221, 8226, 8230, 8364]

SCALES = {
    "1x": (1, "."),           # base directory
    "2x": (2, "EN/2x"),
    "3x": (3, "EN/3x"),
    "4x": (4, "EN/4x"),
}

ATLAS_MAX_W = 512  # initial; doubled if needed
SPACING = 1        # 1px between glyphs (matching existing)


def generate_font(name, ttf_path, face_name, bold, italic, base_size, scale, out_dir,
                   uppercase_only=False, tracking=0, var_axes=None, yoff_adjust=0):
    """Generate one .fnt + .png pair."""
    px_size = base_size * scale
    font = ImageFont.truetype(ttf_path, px_size)
    if var_axes is not None:
        font.set_variation_by_axes(var_axes)

    # --- Measure all glyphs ---
    glyphs = []
    for cid in CHAR_IDS:
        ch = chr(cid)
        # Uppercase-only: lowercase slots render uppercase glyphs
        if uppercase_only and ch.islower():
            ch = ch.upper()
        try:
            bbox = font.getbbox(ch)
        except Exception:
            continue
        if bbox is None:
            # Invisible char (space, NBSP, soft hyphen)
            adv = font.getlength(ch)
            glyphs.append({
                "id": cid, "ch": ch,
                "w": 0, "h": 0,
                "xoff": 0, "yoff": 0,
                "xadv": int(round(adv)),
                "img": None,
            })
            continue

        x0, y0, x1, y1 = bbox
        gw = x1 - x0
        gh = y1 - y0
        adv = font.getlength(ch)

        glyphs.append({
            "id": cid, "ch": ch,
            "w": gw, "h": gh,
            "xoff": x0, "yoff": y0,
            "xadv": int(round(adv)),
            "img_offset": (x0, y0),
        })

    # --- Compute line metrics ---
    # Force lineHeight = pixel size (matching PZ convention where lineHeight == size).
    # This keeps getFontHeight() returning the expected value so UI layout math works.
    # Glyphs that exceed the cell just paint into adjacent space (PZ handles this fine).
    ascent, descent = font.getmetrics()
    natural_height = ascent + descent
    line_height = px_size

    # Natural baseline — glyphs sit where the font designer placed them.
    # yoff_adjust shifts all yoffsets down (+) or up (-) to fix cross-font alignment.
    base_line = ascent
    yoff_shift = -yoff_adjust  # positive adjust = glyphs move down = subtract from shift

    # --- Render glyphs to individual images ---
    for g in glyphs:
        if g["w"] == 0 and g["h"] == 0:
            g["img"] = None
            continue
        # Render with enough padding for negative offsets
        pad = max(abs(g["xoff"]), 0) + 2
        tmp_w = g["w"] + pad * 2
        tmp_h = g["h"] + pad * 2
        tmp = Image.new("L", (tmp_w, tmp_h), 0)
        draw = ImageDraw.Draw(tmp)
        draw.text((pad - g["xoff"], pad - g["yoff"]), g["ch"], fill=255, font=font)
        # Crop to actual content
        bbox = tmp.getbbox()
        if bbox is None:
            g["img"] = None
            g["w"] = 0
            g["h"] = 0
            continue
        cropped = tmp.crop(bbox)
        g["img"] = cropped
        # Recalculate offsets based on crop
        g["render_xoff"] = bbox[0] - pad + g["xoff"]
        g["render_yoff"] = bbox[1] - pad + g["yoff"]
        g["w"] = cropped.width
        g["h"] = cropped.height

    # --- Pack glyphs into atlas ---
    # Simple row packing
    atlas_w = ATLAS_MAX_W * scale
    atlas_w = max(atlas_w, 512)

    # Calculate needed height
    cur_x = SPACING
    cur_y = SPACING
    row_h = 0
    positions = {}

    for g in glyphs:
        if g["img"] is None:
            positions[g["id"]] = (0, 0)
            continue
        gw = g["w"] + SPACING
        gh = g["h"] + SPACING
        if cur_x + gw > atlas_w:
            cur_y += row_h + SPACING
            cur_x = SPACING
            row_h = 0
        positions[g["id"]] = (cur_x, cur_y)
        row_h = max(row_h, g["h"])
        cur_x += gw

    atlas_h = cur_y + row_h + SPACING
    # Round up to power of 2
    def next_pow2(v):
        p = 1
        while p < v:
            p *= 2
        return p
    atlas_h = next_pow2(atlas_h)
    atlas_w_final = next_pow2(atlas_w)

    # --- Create atlas image (RGBA: white RGB, alpha = glyph) ---
    atlas = Image.new("RGBA", (atlas_w_final, atlas_h), (255, 255, 255, 0))

    for g in glyphs:
        if g["img"] is None:
            continue
        px, py = positions[g["id"]]
        # Convert L image to RGBA (white + alpha)
        alpha = g["img"]
        rgba = Image.new("RGBA", alpha.size, (255, 255, 255, 0))
        rgba.putalpha(alpha)
        atlas.paste(rgba, (px, py))

    # --- Write .png ---
    os.makedirs(out_dir, exist_ok=True)
    png_name = f"{name}_0.png"
    png_path = os.path.join(out_dir, png_name)
    atlas.save(png_path)

    # --- Write .fnt ---
    fnt_path = os.path.join(out_dir, f"{name}.fnt")
    with open(fnt_path, "w") as f:
        f.write(f'info face="{face_name}" size={px_size} bold={bold} italic={italic} charset="" unicode=1 stretchH=100 smooth=1 aa=2 padding=0,0,0,0 spacing={SPACING},{SPACING} outline=0\n')
        f.write(f'common lineHeight={line_height} base={base_line} scaleW={atlas_w_final} scaleH={atlas_h} pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4\n')
        f.write(f'page id=0 file="{png_name}"\n')
        f.write(f'chars count={len(glyphs)}\n')

        # Tracking: extra pixels per glyph, scaled with font scale
        track_px = round(tracking * scale) if tracking else 0

        for g in glyphs:
            cid = g["id"]
            adv = g["xadv"] + track_px
            if g["img"] is None:
                # Invisible character
                f.write(f'char id={cid:<5} x=0     y=0     width=1     height=1     xoffset=0     yoffset={line_height - 1:<6}xadvance={adv:<7}page=0  chnl=15\n')
            else:
                px, py = positions[cid]
                xoff = g.get("render_xoff", 0)
                yoff = g.get("render_yoff", 0) - yoff_shift
                f.write(f'char id={cid:<5} x={px:<6} y={py:<6} width={g["w"]:<6} height={g["h"]:<6} xoffset={xoff:<6}yoffset={yoff:<6}xadvance={adv:<7}page=0  chnl=15\n')

    return len(glyphs), atlas_w_final, atlas_h


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    total = 0

    # Fonts that render uppercase only (lowercase slots show uppercase glyphs)
    # K22 Xanthus was all-caps by design. Fira Mono has real lowercase — no override.
    # rsv3 (Lekton) stays uppercase-only since it is still Lekton.
    UPPERCASE_ONLY = {"rsv3"}
    # Extra letter-spacing in base pixels (scaled with font scale)
    # Mono tracking halved (was 1, now 0). Natural Fira Mono spacing is fine.
    # F5 Micro: small tracking at 9px for chip/badge legibility.
    TRACKING = {
        "title": 1, "titleLg": 1,   # F5 Micro (9/11px needs help)
    }
    # Per-font Y-offset adjustment: pushes glyphs down (+) to fix cross-font alignment
    # K22 Xanthus baseline quirk gone. Start at 0 for all Fira fonts.
    # Add adjustments here after first regen if visual baseline mismatch found.
    YOFF_ADJUST = {}

    for font_name, (ttf_path, face_name, bold, italic, var_axes) in FONTS.items():
        if not os.path.isfile(ttf_path):
            print(f"ERROR: TTF not found: {ttf_path}")
            sys.exit(1)

        uc_only = font_name in UPPERCASE_ONLY
        track = TRACKING.get(font_name, 0)
        ya = YOFF_ADJUST.get(font_name, 0)
        for scale_name, (scale, sub_dir) in SCALES.items():
            out_dir = os.path.join(script_dir, sub_dir) if sub_dir != "." else script_dir
            base_size = FONT_SIZES.get(font_name, 14)
            count, aw, ah = generate_font(
                font_name, ttf_path, face_name, bold, italic,
                base_size, scale, out_dir, uppercase_only=uc_only,
                tracking=track, var_axes=var_axes,
                yoff_adjust=ya
            )
            print(f"  {font_name} {scale_name}: {count} chars, {aw}x{ah} atlas -> {out_dir}")
            total += 1

    print(f"\nDone: {total} font files generated.")


if __name__ == "__main__":
    main()
