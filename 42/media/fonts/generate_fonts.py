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

Character set: see zed_charset.py (Basic Latin, Latin-1, Latin Extended-A, a chosen part of
Latin Extended-B, Greek, Cyrillic, typographic punctuation, currency). Only code points the
TTF really draws are written; the rest are listed as missing. Glyphs that do not fit one atlas
page spill onto further pages (page 0 keeps ASCII and Latin-1), which the .fnt format allows.
"""

import os
import sys
from PIL import Image, ImageFont, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zed_charset import CHAR_IDS, is_core, read_cmap  # noqa: E402

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

# Character set: shared with the distance-field baker, see zed_charset.py (CHAR_IDS).
# The code points each TTF lacks, per font file, are collected here and printed at the end.
MISSING = {}
_CMAPS = {}


def _cmap_for(ttf_path):
    """Cached set of code points a TTF draws."""
    if ttf_path not in _CMAPS:
        _CMAPS[ttf_path] = read_cmap(ttf_path)
    return _CMAPS[ttf_path]

SCALES = {
    "1x": (1, "."),           # base directory
    "2x": (2, "EN/2x"),
    "3x": (3, "EN/3x"),
    "4x": (4, "EN/4x"),
}

ATLAS_MAX_W = 512  # page width at 1x; page width is this times the scale (512, 1024, 2048, 2048)
ATLAS_MAX_PAGE = 2048  # largest page edge; more glyphs than fit spill onto another page
SPACING = 1        # 1px between glyphs (matching existing)


def _next_pow2(v):
    p = 1
    while p < v:
        p *= 2
    return p


def _pack_pages(glyphs, page_w, page_max):
    """Shelf-pack inked glyphs onto pages that are page_w wide and at most page_max tall.

    Order: the core set (ASCII, Latin-1, the old punctuation) first so it lands together on page
    0, then everything else; within each group tallest first, which keeps the shelves tight.
    Pixel (0, 0) of page 0 stays empty because invisible characters point at it.
    Returns a list of page heights (each rounded up to a power of two).
    """
    inked = [g for g in glyphs if g["img"] is not None]
    inked.sort(key=lambda g: (0 if is_core(g["id"]) else 1, -g["h"], -g["w"], g["id"]))
    heights = []
    page, cur_x, cur_y, row_h = 0, SPACING, SPACING, 0
    for g in inked:
        gw = g["w"] + SPACING
        if gw + SPACING > page_w or g["h"] + 2 * SPACING > page_max:
            raise RuntimeError(f"glyph U+{g['id']:04X} ({g['w']}x{g['h']}) does not fit a {page_w}x{page_max} page")
        if cur_x + gw > page_w:
            cur_y += row_h + SPACING
            cur_x = SPACING
            row_h = 0
        if cur_y + g["h"] + SPACING > page_max:
            heights.append(_next_pow2(cur_y + row_h + SPACING))
            page += 1
            cur_x, cur_y, row_h = SPACING, SPACING, 0
        g["page"] = page
        g["px"], g["py"] = cur_x, cur_y
        row_h = max(row_h, g["h"])
        cur_x += gw
    heights.append(_next_pow2(cur_y + row_h + SPACING))
    return heights


def generate_font(name, ttf_path, face_name, bold, italic, base_size, scale, out_dir,
                   uppercase_only=False, tracking=0, var_axes=None, yoff_adjust=0):
    """Generate one .fnt plus its atlas page(s). Returns (glyph count, page width, page heights)."""
    px_size = base_size * scale
    font = ImageFont.truetype(ttf_path, px_size)
    if var_axes is not None:
        font.set_variation_by_axes(var_axes)
    cmap = _cmap_for(ttf_path)

    # --- Measure all glyphs ---
    glyphs = []
    for cid in CHAR_IDS:
        ch = chr(cid)
        # Uppercase-only: lowercase slots render uppercase glyphs (a single letter, or the
        # two-letter form of the German sharp s)
        if uppercase_only and ch.islower():
            up = ch.upper()
            if len(up) == 1 or cid == 0xDF:
                ch = up
        # A no-break space the TTF lacks is drawn as an ordinary space (Lekton has no U+00A0)
        if cid == 0x00A0 and cid not in cmap and 0x20 in cmap:
            ch = " "
        # Skip anything the TTF does not draw, so the font's missing-glyph box never ships
        if not all(ord(c) in cmap for c in ch):
            MISSING.setdefault(os.path.basename(ttf_path), set()).add(cid)
            continue
        bbox = font.getbbox(ch)
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

    # Natural baseline: glyphs sit where the font designer placed them.
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

    # --- Pack glyphs onto one or more pages ---
    page_w = min(_next_pow2(max(ATLAS_MAX_W * scale, 512)), ATLAS_MAX_PAGE)
    page_max = page_w   # square at most; the last page is trimmed to the height it needs
    heights = _pack_pages(glyphs, page_w, page_max)
    n_pages = len(heights)

    # --- Create atlas images (RGBA: white RGB, alpha = glyph) ---
    atlases = [Image.new("RGBA", (page_w, h), (255, 255, 255, 0)) for h in heights]
    for g in glyphs:
        if g["img"] is None:
            continue
        # Convert L image to RGBA (white + alpha)
        alpha = g["img"]
        rgba = Image.new("RGBA", alpha.size, (255, 255, 255, 0))
        rgba.putalpha(alpha)
        atlases[g["page"]].paste(rgba, (g["px"], g["py"]))

    # --- Write .png (page i is <name>_<i>.png; stale higher pages from older bakes are removed) ---
    os.makedirs(out_dir, exist_ok=True)
    png_names = [f"{name}_{i}.png" for i in range(n_pages)]
    for i, atlas in enumerate(atlases):
        atlas.save(os.path.join(out_dir, png_names[i]), optimize=True)
    stale = n_pages
    while os.path.isfile(os.path.join(out_dir, f"{name}_{stale}.png")):
        os.remove(os.path.join(out_dir, f"{name}_{stale}.png"))
        stale += 1

    # --- Write .fnt ---
    fnt_path = os.path.join(out_dir, f"{name}.fnt")
    with open(fnt_path, "w") as f:
        f.write(f'info face="{face_name}" size={px_size} bold={bold} italic={italic} charset="" unicode=1 stretchH=100 smooth=1 aa=2 padding=0,0,0,0 spacing={SPACING},{SPACING} outline=0\n')
        f.write(f'common lineHeight={line_height} base={base_line} scaleW={page_w} scaleH={max(heights)} pages={n_pages} packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4\n')
        for i, png_name in enumerate(png_names):
            f.write(f'page id={i} file="{png_name}"\n')
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
                xoff = g.get("render_xoff", 0)
                yoff = g.get("render_yoff", 0) - yoff_shift
                f.write(f'char id={cid:<5} x={g["px"]:<6} y={g["py"]:<6} width={g["w"]:<6} height={g["h"]:<6} xoffset={xoff:<6}yoffset={yoff:<6}xadvance={adv:<7}page={g["page"]:<3} chnl=15\n')

    return len(glyphs), page_w, heights


def print_missing():
    """List, per TTF, the wanted code points it does not draw."""
    for ttf_name, cps in sorted(MISSING.items()):
        cps = sorted(cps)
        print(f"  {ttf_name} lacks {len(cps)} wanted code points: "
              + " ".join(f"{cp:04X}" for cp in cps))


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
            count, aw, ahs = generate_font(
                font_name, ttf_path, face_name, bold, italic,
                base_size, scale, out_dir, uppercase_only=uc_only,
                tracking=track, var_axes=var_axes,
                yoff_adjust=ya
            )
            sizes = " + ".join(f"{aw}x{h}" for h in ahs)
            print(f"  {font_name} {scale_name}: {count} chars, {len(ahs)} page(s) {sizes} -> {out_dir}")
            total += 1

    print(f"\nDone: {total} font files generated.")
    print_missing()


if __name__ == "__main__":
    main()
