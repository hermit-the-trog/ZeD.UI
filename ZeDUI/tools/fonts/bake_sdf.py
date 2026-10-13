"""
Bake signed-distance-field (SDF) BMFont atlases for the five ZeD-UI Fira roles.

Run from the repo root:
    py -3.14 ZeDUI/tools/fonts/bake_sdf.py                 # all roles, 64 px face, spread 4
    py -3.14 ZeDUI/tools/fonts/bake_sdf.py body stat       # a subset
    py -3.14 ZeDUI/tools/fonts/bake_sdf.py --face 32       # vanilla-sized face
    py -3.14 ZeDUI/tools/fonts/bake_sdf.py --spread 2      # tighter field (see SPREAD)

Output (42/media/fonts/sdf/):
    <role>.fnt            BMFont text descriptor
    <role>1.png, ...      512x512 RGBA pages (RGB white, alpha = distance field)
and ZeDUI/tools/fonts/fonts_txt_snippet.txt (the fonts.txt blocks for the integrator).

Format contract = the engine's own SDF fonts (media/fonts/sdfRegular.fnt, made with Hiero),
except for the face size (see FACE_PX):
  * padding = the SDF spread in px at the face size (4, as vanilla)
  * alpha = clamp(0.5 + d / (2 * spread), 0, 1), d = signed distance to the outline in
    face px, positive inside - the same field slope per texel as vanilla. Shader
    media/shaders/sdf.frag reads .a and smoothsteps around 0.5.
  * every glyph box = ink box (whole px, origin-aligned) grown by the padding on all
    sides, so xoffset/yoffset include -padding (vanilla 'A' at 32 px: xoffset=-4
    yoffset=8 28x31)
  * xadvance = plain advance rounded to px (the header's spacing=-8,-8 is Hiero's record
    of the advance adjustment that cancels the padding, copied verbatim)
  * base = ceil(ascent), lineHeight = ceil(ascent) + ceil(descent) + lineGap (hhea)
  * page ids from 0, page files numbered from 1, CRLF line endings, Hiero column layout
  * blank glyphs (space, nbsp): x=0 y=0 width=0 height=0 xoffset=-padding yoffset=0
  * the engine parser (zombie.core.fonts.AngelCodeFont) reads lineHeight, the page
    files (relative to the .fnt's folder), char and kerning lines; info/padding/spacing
    are informational only.

Method: each glyph is rasterised by FreeType (Pillow) at 8x the face size, thresholded at
50% coverage, run through an exact Euclidean distance transform (separable: column
sweeps, then a bounded row search, exact up to the clamp radius), signed, area-averaged
8x8 down to the face grid and encoded. The glyph origin sits on a face pixel corner, so
the outline keeps its exact sub-pixel position relative to the pen. Advances come from
the TTF's hmtx table (Pillow's are quantised by hinting). Packing puts ASCII first so
plain English strings draw from one texture.

Needs Pillow + numpy only (no fontTools, no scipy).
"""

import argparse
import math
import os
import re
import struct
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
REPO = Path(__file__).resolve().parents[3]
OUT_DIR = REPO / "42" / "media" / "fonts" / "sdf"
SNIPPET = Path(__file__).resolve().parent / "fonts_txt_snippet.txt"

# Face size in px per em (CLI: --face). Vanilla bakes 32, but the engine draws an atlas
# at its native face size at zoom 1 and the edge softness on screen grows with the zoom:
# the ZeD text path (ISUIElement:drawText / drawTextZoomed -> UIElement.DrawText ->
# TextManager.DrawString -> AngelCodeFont) never binds sdf.frag (only the PZAPI atoms
# AtomUIText/AtomUITextEntry and the world map do), so what shows is the raw field used as
# alpha: a ramp of +-spread texels around the edge. A 32 px face drawn at 1x-2x looks
# soft-to-blobby. ZeD body text is 13 px x root scale (13 px at 1080p, 26 px on the 4K
# rig), so a 64 px face puts the common sizes at 0.2x-0.4x, where that ramp is about one
# screen px (+-spread * zoom).
FACE_PX = 64
# Padding = SDF spread in face px (CLI: --spread sets both). Vanilla: 4 at its 32 px face,
# i.e. the same field slope per texel (alpha 0.5 + d/8) that sdf.frag's thresholds expect.
# On the raw-alpha path a pixel fully inside a stroke only reaches 0.5 + halfwidth / (2 *
# spread), so with 4 at 64 px Fira stems peak near 0.8-0.9 opacity; 2 gets them to 1.0 and
# halves the edge ramp (see preview_sdf.py's UI-size rows), at the cost of half the room
# for sdf.frag outlines/shadows and a harder edge below ~0.15x.
PAD = 4           # box padding in face px (vanilla: padding=4,4,4,4)
SPREAD = 4.0      # distance (face px) mapped to alpha 0 / 1 around the 0.5 edge
SS = 8            # supersampling: glyphs are rendered at FACE_PX * SS
PAGE = 512        # atlas page size, like the engine's own multi-page SDF fonts
GUTTER = 1        # empty px between packed glyphs (and along the page edges)

# role, TTF file, typography role, fonts.txt slot
ROLES = [
    ("sec",   "FiraMono-Bold.ttf",              "F1 chrome",  "NewMedium"),
    ("body",  "FiraSans-Medium.ttf",            "F2 body",    "Small"),
    ("stat",  "FiraMono-Regular.ttf",           "F3 data",    "Medium"),
    ("head",  "FiraSansCondensed-SemiBold.ttf", "F4 heading", "NewLarge"),
    ("title", "FiraSansCondensed-Regular.ttf",  "F5 micro",   "Code"),
]
SNIPPET_ORDER = ["Small", "NewMedium", "Medium", "NewLarge", "Code"]

# ASCII, Latin-1 (incl. degree 176 and middle dot 183), dashes, curly quotes, bullet,
# ellipsis, euro
CHARSET = (list(range(32, 127)) + list(range(160, 256)) +
           [0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2026, 0x20AC])

FONT_DIR = os.path.expanduser("~/AppData/Local/Microsoft/Windows/Fonts")
FONT_DIR_SYS = os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts")


def _find_font(name):
    """Find font in local or system font directory (same helper as generate_fonts.py)."""
    local = os.path.join(FONT_DIR, name)
    if os.path.isfile(local):
        return local
    system = os.path.join(FONT_DIR_SYS, name)
    if os.path.isfile(system):
        return system
    return local  # fallback - will fail with clear error


# ---------------------------------------------------------------------------
# Minimal TrueType reader: units per em, hhea metrics, cmap, advances
# ---------------------------------------------------------------------------
class TTF:
    def __init__(self, path):
        self.path = path
        data = self.data = Path(path).read_bytes()
        num = struct.unpack(">H", data[4:6])[0]
        self.tables = {}
        for i in range(num):
            tag, _cs, off, ln = struct.unpack(">4sIII", data[12 + 16 * i:28 + 16 * i])
            self.tables[tag.decode("latin-1")] = (off, ln)
        o = self.tables["head"][0]
        self.upm = struct.unpack(">H", data[o + 18:o + 20])[0]
        o = self.tables["hhea"][0]
        self.ascender, self.descender, self.line_gap = struct.unpack(">hhh", data[o + 4:o + 10])
        self.num_hmetrics = struct.unpack(">H", data[o + 34:o + 36])[0]
        self.cmap = self._read_cmap()

    def _read_cmap(self):
        data = self.data
        o = self.tables["cmap"][0]
        n = struct.unpack(">H", data[o + 2:o + 4])[0]
        subs = {}
        for i in range(n):
            pid, eid, off = struct.unpack(">HHI", data[o + 4 + 8 * i:o + 12 + 8 * i])
            subs[(pid, eid)] = o + off
        for key in [(3, 10), (0, 4), (3, 1), (0, 3)]:
            if key not in subs:
                continue
            so = subs[key]
            fmt = struct.unpack(">H", data[so:so + 2])[0]
            if fmt == 12:
                return self._cmap12(so)
            if fmt == 4:
                return self._cmap4(so)
        raise RuntimeError(f"{self.path}: no usable Unicode cmap (format 4/12)")

    def _cmap12(self, so):
        data, m = self.data, {}
        ngroups = struct.unpack(">I", data[so + 12:so + 16])[0]
        for g in range(ngroups):
            a, b, s = struct.unpack(">III", data[so + 16 + 12 * g:so + 28 + 12 * g])
            for c in range(a, b + 1):
                m[c] = s + c - a
        return m

    def _cmap4(self, so):
        data, m = self.data, {}
        segx2 = struct.unpack(">H", data[so + 6:so + 8])[0]
        seg = segx2 // 2
        ends = struct.unpack(">%dH" % seg, data[so + 14:so + 14 + segx2])
        starts = struct.unpack(">%dH" % seg, data[so + 16 + segx2:so + 16 + 2 * segx2])
        deltas = struct.unpack(">%dh" % seg, data[so + 16 + 2 * segx2:so + 16 + 3 * segx2])
        ro_base = so + 16 + 3 * segx2
        ros = struct.unpack(">%dH" % seg, data[ro_base:ro_base + segx2])
        for i in range(seg):
            for c in range(starts[i], ends[i] + 1):
                if c == 0xFFFF:
                    continue
                if ros[i] == 0:
                    gid = (c + deltas[i]) & 0xFFFF
                else:
                    a = ro_base + 2 * i + ros[i] + 2 * (c - starts[i])
                    gid = struct.unpack(">H", data[a:a + 2])[0]
                    if gid:
                        gid = (gid + deltas[i]) & 0xFFFF
                if gid:
                    m[c] = gid
        return m

    def advance_units(self, gid):
        hb = self.tables["hmtx"][0]
        i = min(gid, self.num_hmetrics - 1)
        return struct.unpack(">H", self.data[hb + 4 * i:hb + 4 * i + 2])[0]

    def px(self, units):
        return units * FACE_PX / self.upm


def line_metrics(ttf):
    """(lineHeight, base) at FACE_PX, Hiero/Java style: ascent and descent rounded up."""
    asc = math.ceil(ttf.px(ttf.ascender) - 1e-9)
    desc = math.ceil(ttf.px(-ttf.descender) - 1e-9)
    gap = int(math.floor(ttf.px(ttf.line_gap) + 0.5))
    return asc + desc + gap, asc


# ---------------------------------------------------------------------------
# Distance field
# ---------------------------------------------------------------------------
def clamp_radius():
    """Distance clamp in hi-res px: the spread plus one 8x8 block (covers the averaging)."""
    return int(math.ceil(SPREAD * SS)) + SS


def edt_sq(feature, cap):
    """Squared Euclidean distance from every pixel to the nearest True pixel of `feature`.

    Last two axes are (H, W); leading axes are a batch. Exact for distances <= cap, any
    larger distance comes back as some value > cap**2 (the caller clamps).
    Pass 1 sweeps each column both ways (vertical distance to the nearest feature);
    pass 2 takes min over |k| <= cap of k^2 + g(x+k)^2 along each row.
    """
    big = cap + 1
    dt = np.int16 if big * big + cap * cap < 32767 else np.int32
    g = np.where(feature, 0, big).astype(dt)
    h, w = g.shape[-2:]
    for y in range(1, h):
        np.minimum(g[..., y, :], g[..., y - 1, :] + 1, out=g[..., y, :])
    for y in range(h - 2, -1, -1):
        np.minimum(g[..., y, :], g[..., y + 1, :] + 1, out=g[..., y, :])
    g *= g
    padded = np.full(g.shape[:-1] + (w + 2 * cap,), big * big, dtype=dt)
    padded[..., cap:cap + w] = g
    d = g.copy()
    for k in range(1, cap + 1):
        k2 = k * k
        np.minimum(d, padded[..., cap + k:cap + k + w] + k2, out=d)
        np.minimum(d, padded[..., cap - k:cap - k + w] + k2, out=d)
    return d


def coverage_to_alpha(cov):
    """Hi-res coverage (H*SS, W*SS uint8) -> encoded field (H, W uint8) at FACE_PX."""
    cap = clamp_radius()
    inside = cov >= 128
    d2 = edt_sq(np.stack([~inside, inside]), cap).astype(np.float32)
    d_in = np.sqrt(d2[0])     # inside px: distance to the nearest outside px centre
    d_out = np.sqrt(d2[1])    # outside px: distance to the nearest inside px centre
    sd = np.where(inside, d_in - 0.5, 0.5 - d_out)   # edge halfway between centres
    np.clip(sd, -cap, cap, out=sd)
    hh, ww = sd.shape[0] // SS, sd.shape[1] // SS
    sd = sd.reshape(hh, SS, ww, SS).mean(axis=(1, 3)) / SS      # area average, face px
    alpha = np.clip(0.5 + sd / (2.0 * SPREAD), 0.0, 1.0)
    return np.rint(alpha * 255.0).astype(np.uint8)


# ---------------------------------------------------------------------------
# Glyphs
# ---------------------------------------------------------------------------
def bake_glyph(font_hi, ch, base):
    """Render one glyph at 8x and return its box metrics + field, or None if blank."""
    bx0, by0, bx1, by1 = font_hi.getbbox(ch, anchor="ls")
    margin = (PAD + 4) * SS
    ox = SS * math.ceil((margin - min(bx0, 0)) / SS)     # origin on a multiple of SS
    oy = SS * math.ceil((margin - min(by0, 0)) / SS)
    cw = ox + max(bx1, 0) + margin
    chh = oy + max(by1, 0) + margin
    img = Image.new("L", (cw, chh), 0)
    ImageDraw.Draw(img).text((ox, oy), ch, font=font_hi, fill=255, anchor="ls")
    cov = np.asarray(img, dtype=np.uint8)
    ys, xs = np.nonzero(cov)
    if xs.size == 0:
        return None
    ix0, ix1, iy0, iy1 = int(xs.min()), int(xs.max()) + 1, int(ys.min()), int(ys.max()) + 1
    if ix0 == 0 or iy0 == 0 or ix1 == cw or iy1 == chh:
        raise RuntimeError(f"glyph U+{ord(ch):04X} touches the render canvas edge")
    # ink box in whole face pixels relative to the pen origin (y down, baseline = 0)
    left = (ix0 - ox) // SS
    right = -((ox - ix1) // SS)
    top = (iy0 - oy) // SS
    bottom = -((oy - iy1) // SS)
    x0, x1 = ox + (left - PAD) * SS, ox + (right + PAD) * SS
    y0, y1 = oy + (top - PAD) * SS, oy + (bottom + PAD) * SS
    if x0 < 0 or y0 < 0 or x1 > cw or y1 > chh:     # padded box past the canvas: grow it
        cov = np.pad(cov, ((max(0, -y0), max(0, y1 - chh)), (max(0, -x0), max(0, x1 - cw))))
        x1 -= min(0, x0)
        y1 -= min(0, y0)
        x0 = max(0, x0)
        y0 = max(0, y0)
    alpha = coverage_to_alpha(cov[y0:y1, x0:x1])
    return {
        "w": right - left + 2 * PAD,
        "h": bottom - top + 2 * PAD,
        "xoffset": left - PAD,
        "yoffset": base + top - PAD,
        "alpha": alpha,
    }


def pack(glyphs):
    """Shelf-pack inked glyphs into PAGE x PAGE pages, ASCII first (tallest first within
    each group) so ordinary strings stay on one texture. Returns the page count."""
    inked = [g for g in glyphs if g["alpha"] is not None]
    inked.sort(key=lambda g: (g["id"] > 126, -g["h"], -g["w"], g["id"]))
    page, x, y, shelf = 0, GUTTER, GUTTER, 0
    for g in inked:
        if g["w"] + 2 * GUTTER > PAGE or g["h"] + 2 * GUTTER > PAGE:
            raise RuntimeError(f"glyph {g['id']} ({g['w']}x{g['h']}) does not fit a page")
        if x + g["w"] + GUTTER > PAGE:
            x, y, shelf = GUTTER, y + shelf + GUTTER, 0
        if y + g["h"] + GUTTER > PAGE:
            page, x, y, shelf = page + 1, GUTTER, GUTTER, 0
        g["x"], g["y"], g["page"] = x, y, page
        x += g["w"] + GUTTER
        shelf = max(shelf, g["h"])
    return page + 1 if inked else 1


def face_name(font):
    family, style = font.getname()
    return family if style in ("Regular", "Book", "") else f"{family} {style}"


def char_line(g):
    # Hiero's layout: "char id=" %-7s + " ", then x..page as %-5s, then "chnl=0 "
    return ("char id=%-7d x=%-5dy=%-5dwidth=%-5dheight=%-5dxoffset=%-5dyoffset=%-5d"
            "xadvance=%-5dpage=%-5dchnl=0 " % (g["id"], g["x"], g["y"], g["w"], g["h"],
                                               g["xoffset"], g["yoffset"], g["xadvance"],
                                               g["page"]))


def bake_role(role, ttf_name):
    t0 = time.time()
    path = _find_font(ttf_name)
    if not os.path.isfile(path):
        raise FileNotFoundError(f"TTF not found: {path}")
    ttf = TTF(path)
    line_h, base = line_metrics(ttf)
    font_hi = ImageFont.truetype(path, FACE_PX * SS)

    glyphs, skipped = [], []
    for cp in CHARSET:
        gid = ttf.cmap.get(cp, 0)
        if gid == 0:
            skipped.append(cp)
            continue
        adv = ttf.px(ttf.advance_units(gid))
        g = {"id": cp, "xadvance": int(math.floor(adv + 0.5)), "x": 0, "y": 0, "page": 0}
        baked = bake_glyph(font_hi, chr(cp), base)
        if baked is None:   # blank (space, nbsp): vanilla writes a 0x0 box at -padding
            g.update(w=0, h=0, xoffset=-PAD, yoffset=0, alpha=None)
        else:
            g.update(baked)
        glyphs.append(g)

    n_pages = pack(glyphs)
    pages = [np.zeros((PAGE, PAGE), np.uint8) for _ in range(n_pages)]
    for g in glyphs:
        if g["alpha"] is not None:
            pages[g["page"]][g["y"]:g["y"] + g["h"], g["x"]:g["x"] + g["w"]] = g["alpha"]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    stale = re.compile(r"^%s\d+\.png$" % re.escape(role))
    for f in OUT_DIR.iterdir():
        if stale.match(f.name):
            f.unlink()
    files = []
    for i, a in enumerate(pages):
        rgba = np.empty((PAGE, PAGE, 4), np.uint8)
        rgba[..., :3] = 255
        rgba[..., 3] = a
        name = f"{role}{i + 1}.png"
        Image.fromarray(rgba, "RGBA").save(OUT_DIR / name, optimize=True)
        files.append(name)

    lines = [
        f'info face="{face_name(font_hi)}" size={FACE_PX} bold=0 italic=0 charset="" unicode=0 '
        f'stretchH=100 smooth=1 aa=1 padding={PAD},{PAD},{PAD},{PAD} spacing={-2 * PAD},{-2 * PAD}',
        f"common lineHeight={line_h} base={base} scaleW={PAGE} scaleH={PAGE} "
        f"pages={n_pages} packed=0",
    ]
    lines += [f'page id={i} file="{name}"' for i, name in enumerate(files)]
    lines.append(f"chars count={len(glyphs)}")
    lines += [char_line(g) for g in sorted(glyphs, key=lambda g: g["id"])]
    lines.append("kernings count=0")
    with open(OUT_DIR / f"{role}.fnt", "w", encoding="ascii", newline="\r\n") as f:
        f.write("\n".join(lines) + "\n")

    by_page = [sum(1 for g in glyphs if g["alpha"] is not None and g["page"] == p)
               for p in range(n_pages)]
    ascii_pages = sorted({g["page"] for g in glyphs if g["alpha"] is not None and g["id"] < 127})
    return {
        "role": role, "ttf": ttf_name, "face": face_name(font_hi), "glyphs": len(glyphs),
        "inked": sum(1 for g in glyphs if g["alpha"] is not None), "pages": n_pages,
        "by_page": by_page, "ascii_pages": [p + 1 for p in ascii_pages],
        "lineHeight": line_h, "base": base, "skipped": skipped, "secs": time.time() - t0,
        "adv_H": next(g["xadvance"] for g in glyphs if g["id"] == ord("H")),
    }


def write_snippet():
    by_slot = {slot: role for role, _ttf, _label, slot in ROLES}
    blocks = [f"font {slot}\n{{\n    fnt = sdf/{by_slot[slot]}.fnt,\n    type = sdf,\n}}\n"
              for slot in SNIPPET_ORDER]
    SNIPPET.write_text("\n".join(blocks), encoding="ascii", newline="\n")


def main(argv):
    global FACE_PX, PAD, SPREAD
    ap = argparse.ArgumentParser(description="Bake ZeD-UI SDF BMFont atlases.")
    ap.add_argument("roles", nargs="*", help="roles to bake (default: all): "
                    + ", ".join(r[0] for r in ROLES))
    ap.add_argument("--face", type=int, default=FACE_PX,
                    help=f"face size in px per em (default {FACE_PX}; vanilla uses 32)")
    ap.add_argument("--spread", type=int, default=PAD,
                    help=f"SDF spread = box padding in face px (default {PAD}, as vanilla)")
    args = ap.parse_args(argv)
    if args.face < 8 or args.spread < 1:
        ap.error("--face must be >= 8 and --spread >= 1")
    FACE_PX, PAD, SPREAD = args.face, args.spread, float(args.spread)
    wanted = set(args.roles) or {r[0] for r in ROLES}
    unknown = wanted - {r[0] for r in ROLES}
    if unknown:
        ap.error(f"unknown role(s): {', '.join(sorted(unknown))}")
    print(f"SDF bake: face {FACE_PX}px, padding/spread {PAD}px, {SS}x supersampling, "
          f"{PAGE}x{PAGE} pages -> {OUT_DIR}")
    t0 = time.time()
    for role, ttf_name, label, slot in ROLES:
        if role not in wanted:
            continue
        s = bake_role(role, ttf_name)
        print(f"  {role:<5} {label:<10} {s['face']:<29} glyphs {s['glyphs']:>3} "
              f"({s['inked']} inked)  pages {s['pages']} {s['by_page']}  ASCII on page "
              f"{','.join(map(str, s['ascii_pages']))}  lineHeight {s['lineHeight']}  "
              f"base {s['base']}  H adv {s['adv_H']}  {s['secs']:.1f}s")
        if s["skipped"]:
            print("        skipped (not in TTF): " +
                  " ".join(f"U+{cp:04X}" for cp in s["skipped"]))
    write_snippet()
    print(f"fonts.txt snippet -> {SNIPPET}")
    print(f"done in {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main(sys.argv[1:])
