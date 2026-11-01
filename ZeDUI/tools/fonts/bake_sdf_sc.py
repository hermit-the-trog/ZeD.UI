"""
Bake the simplified Chinese distance-field face (Noto Sans SC Regular) for ZeD-UI.

Director, Nov 1 2026: text in Chinese drew in the game's own zomboidMediumChinese face (on the
Cred1 slot, see ZeD.Text.scriptFont in 42/media/lua/shared/ZeD/Scale.lua), a traditional set,
so common simplified letters (U+56FE, the "map" in 地图) drew blank. This bakes Noto Sans SC
into the same format as the five Fira role faces (bake_sdf.py: AngelCode text .fnt + RGBA pages,
alpha = distance field, read by the engine as `type = sdf`), and ZeD's font lists put it on Cred1.

Run from the repo root (the OTF is not in the repo; pass where you keep it):
    <python with Pillow + numpy> ZeDUI/tools/fonts/bake_sdf_sc.py path/to/NotoSansSC-Regular.otf

Source: https://github.com/notofonts/noto-cjk, Sans/SubsetOTF/SC/NotoSansSC-Regular.otf
(SIL Open Font License 1.1; the licence ships as 42/media/fonts/sdf/NotoSansSC_OFL.txt).

Output (42/media/fonts/sdf/):
    notoSC.fnt, notoSC1.png ... notoSCn.png

Character set (CHARSET below): ASCII, Latin-1, the GB2312 level-1 hanzi (rows 16-55, the 3,755
most common simplified letters), GB2312 row 1 (CJK punctuation and symbols), GB2312 row 3
(full-width ASCII), the CJK Symbols and Punctuation block. Kana (GB2312 rows 4-5) are left out
on purpose: Japanese then keeps drawing in the game's Japanese face, which carries more of it.

Face size: 32 px per em, spread 1.5 (the Fira roles: 64 px, spread 2). A 64 px face for ~4,200
letters would be ~14 pages and ~8 MB; 32 px is 4 pages. ZeD draws text at 9-20 px x the root
scale (up to ~40 px on the 4K rig), i.e. 0.3x-1.3x of this face. The tighter spread keeps the raw
alpha ramp (+-spread x zoom screen px, PZAPI-KNOWLEDGE-BANK Q141) near one px at 1x and lets the
thin hanzi strokes (Noto Sans SC Regular stems ~0.07 em = ~2.3 face px) reach full opacity.

Needs Pillow + numpy only. Reuses bake_sdf.py's reader, field and packer.
"""

import argparse
import math
import re
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bake_sdf as B  # noqa: E402

FACE = 32
PAD = 2           # box padding in face px (>= the spread, as bake_sdf)
SPREAD = 1.5
ROLE = "notoSC"


def gb2312_row(row):
    out = []
    for col in range(1, 95):
        try:
            ch = bytes([0xA0 + row, 0xA0 + col]).decode("gb2312")
        except UnicodeDecodeError:
            continue
        out.append(ord(ch))
    return out


def charset():
    cps = set(range(0x20, 0x7F)) | set(range(0xA0, 0x100))
    for row in [1, 3] + list(range(16, 56)):
        cps.update(gb2312_row(row))
    cps.update(range(0x3000, 0x3040))
    return sorted(cps)


def main(argv):
    ap = argparse.ArgumentParser(description="Bake the ZeD-UI simplified Chinese SDF face.")
    ap.add_argument("otf", help="NotoSansSC-Regular.otf")
    ap.add_argument("--face", type=int, default=FACE)
    ap.add_argument("--spread", type=float, default=SPREAD)
    args = ap.parse_args(argv)
    B.FACE_PX, B.PAD, B.SPREAD = args.face, max(PAD, int(math.ceil(args.spread))), args.spread
    t0 = time.time()
    ttf = B.TTF(args.otf)
    line_h, base = B.line_metrics(ttf)
    font_hi = ImageFont.truetype(args.otf, B.FACE_PX * B.SS)
    hanzi = sum(len(gb2312_row(r)) for r in range(16, 56))

    glyphs, skipped = [], []
    for cp in charset():
        gid = ttf.cmap.get(cp, 0)
        if gid == 0:
            skipped.append(cp)
            continue
        g = {"id": cp, "xadvance": int(math.floor(ttf.px(ttf.advance_units(gid)) + 0.5)),
             "x": 0, "y": 0, "page": 0}
        baked = B.bake_glyph(font_hi, chr(cp), base)
        if baked is None:
            g.update(w=0, h=0, xoffset=-B.PAD, yoffset=0, alpha=None)
        else:
            g.update(baked)
        glyphs.append(g)

    n_pages = B.pack(glyphs)
    pages = [np.zeros((B.PAGE, B.PAGE), np.uint8) for _ in range(n_pages)]
    for g in glyphs:
        if g["alpha"] is not None:
            pages[g["page"]][g["y"]:g["y"] + g["h"], g["x"]:g["x"] + g["w"]] = g["alpha"]

    out = B.OUT_DIR
    out.mkdir(parents=True, exist_ok=True)
    stale = re.compile(r"^%s\d+\.png$" % re.escape(ROLE))
    for f in out.iterdir():
        if stale.match(f.name):
            f.unlink()
    files, total = [], 0
    for i, a in enumerate(pages):
        rgba = np.empty((B.PAGE, B.PAGE, 4), np.uint8)
        rgba[..., :3] = 255
        rgba[..., 3] = a
        name = f"{ROLE}{i + 1}.png"
        Image.fromarray(rgba, "RGBA").save(out / name, optimize=True)
        files.append(name)
        total += (out / name).stat().st_size

    lines = [
        f'info face="Noto Sans SC" size={B.FACE_PX} bold=0 italic=0 charset="" unicode=0 '
        f'stretchH=100 smooth=1 aa=1 padding={B.PAD},{B.PAD},{B.PAD},{B.PAD} '
        f'spacing={-2 * B.PAD},{-2 * B.PAD}',
        f"common lineHeight={line_h} base={base} scaleW={B.PAGE} scaleH={B.PAGE} "
        f"pages={n_pages} packed=0",
    ]
    lines += [f'page id={i} file="{name}"' for i, name in enumerate(files)]
    lines.append(f"chars count={len(glyphs)}")
    lines += [B.char_line(g) for g in sorted(glyphs, key=lambda g: g["id"])]
    lines.append("kernings count=0")
    fnt = out / f"{ROLE}.fnt"
    with open(fnt, "w", encoding="ascii", newline="\r\n") as f:
        f.write("\n".join(lines) + "\n")
    total += fnt.stat().st_size

    print(f"{ROLE}: face {B.FACE_PX}px, spread {B.SPREAD}, padding {B.PAD}; glyphs {len(glyphs)} "
          f"(GB2312 level-1 hanzi in set: {hanzi}); pages {n_pages}; lineHeight {line_h} "
          f"base {base}; {total / 1e6:.2f} MB; {time.time() - t0:.0f}s")
    if skipped:
        print("skipped (not in the font): " + " ".join(f"U+{cp:04X}" for cp in skipped))


if __name__ == "__main__":
    main(sys.argv[1:])
