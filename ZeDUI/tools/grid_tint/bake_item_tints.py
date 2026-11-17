"""Bake each item icon's main color for the grid's item-colored tiles (the director, Nov 16 2026).

    python -I ZeDUI/tools/grid_tint/bake_item_tints.py [<PZ>/media]

Kahlua cannot read a texture's pixels, so the colors are worked out here, once, from the game's own icons:
every Item_* sprite in media/texturepacks/*.pack (UI2.pack wins over the older packs) and the loose
media/textures/**/Item_*.png. Writes 42/media/lua/shared/ZeD/ItemTints.lua: the icon name without "Item_" ->
its main color as one integer, 0xRRGGBB. Only the raw color is stored; the Lua side (InventoryRenderer's
gridTint) turns it into each theme's tint, so a theme change shows at once.

The main color: the saturation-weighted average of the icon's colored pixels. A colored pixel is opaque
(alpha 128 or more), not an outline or a highlight (HLS lightness 0.12 to 0.92) and has HLS saturation 0.18
or more. An icon with too few colored pixels (under 6% of its opaque ones, or under 8) is gray, black or
white: it is left out, and its tile keeps the plain fill.
Run with the ComfyUI venv's Python (Pillow, numpy).
"""
import io
import os
import struct
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "42", "media", "lua", "shared", "ZeD", "ItemTints.lua")
MEDIA = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media"
# the packs in the order the newer one wins (a name in two packs takes the later one's picture)
PACKS = ["IconsMoveables.pack", "RadioIcons.pack", "ApComUI.pack", "UI.pack", "UI2.pack"]

ALPHA_MIN = 128
L_LO, L_HI = 0.12, 0.92
S_MIN = 0.18
SHARE_MIN = 0.06
COUNT_MIN = 8

LUA_KEYWORDS = set("and break do else elseif end false for function if in local nil not or repeat return then "
                   "true until while".split())


def rd_int(f):
    return struct.unpack("<i", f.read(4))[0]


def rd_str(f):
    return f.read(rd_int(f)).decode("utf-8", "replace")


def pages(path):
    """Each page of a PZ texture pack: its sprite entries (name, x, y, w, h, ...) and its PNG bytes."""
    f = open(path, "rb")
    magic = f.read(4)
    if magic == b"PZPK":
        ver = rd_int(f)
        npages = rd_int(f)
    else:
        f.seek(0)
        ver = 0
        npages = rd_int(f)
    for _ in range(npages):
        rd_str(f)
        n = rd_int(f)
        rd_int(f)
        ents = []
        for _ in range(n):
            en = rd_str(f)
            ents.append((en, struct.unpack("<8i", f.read(32))))
        if ver >= 1:
            data = f.read(rd_int(f))
        else:
            buf = bytearray()
            while True:
                b = f.read(4)
                if b == b"\xef\xbe\xad\xde" or not b:
                    break
                buf += b[:1]
                f.seek(-3, 1)
            data = bytes(buf)
        yield ents, data
    f.close()


def main_color(rgba):
    """The saturation-weighted average of the colored pixels, as (r, g, b) 0-255, or None for a gray icon."""
    a = np.asarray(rgba, dtype=np.float64)
    px = a[a[:, :, 3] >= ALPHA_MIN][:, :3] / 255.0
    if len(px) == 0:
        return None
    mx, mn = px.max(axis=1), px.min(axis=1)
    lt = (mx + mn) / 2
    d = mx - mn
    den = 1 - np.abs(2 * lt - 1)
    s = np.where(den > 1e-6, d / np.maximum(den, 1e-6), 0)
    keep = (lt >= L_LO) & (lt <= L_HI) & (s >= S_MIN)
    n = int(keep.sum())
    if n < COUNT_MIN or n < SHARE_MIN * len(px):
        return None
    w = s[keep]
    c = (px[keep] * w[:, None]).sum(axis=0) / w.sum()
    return tuple(int(round(v * 255)) for v in c)


def main():
    global MEDIA
    if len(sys.argv) > 1:
        MEDIA = sys.argv[1]
    colors = {}
    gray = 0
    for pk in PACKS:
        p = os.path.join(MEDIA, "texturepacks", pk)
        if not os.path.isfile(p):
            continue
        for ents, data in pages(p):
            hits = [e for e in ents if e[0].startswith("Item_")]
            if not hits:
                continue
            page = Image.open(io.BytesIO(data)).convert("RGBA")
            for en, (x, y, w, h, _ox, _oy, _tw, _th) in hits:
                colors[en[5:]] = main_color(page.crop((x, y, x + w, y + h)))
    for d, _, fs in os.walk(os.path.join(MEDIA, "textures")):
        for fn in fs:
            if fn.startswith("Item_") and fn.lower().endswith(".png"):
                key = fn[5:-4]
                if key not in colors:
                    colors[key] = main_color(Image.open(os.path.join(d, fn)).convert("RGBA"))
    lines = []
    for k in sorted(colors):
        c = colors[k]
        if c is None:
            # a gray, black or white icon: neutral gray, so its tile takes a soft gray tint (the director, Nov 16)
            gray += 1
            c = (128, 128, 128)
        v = (c[0] << 16) | (c[1] << 8) | c[2]
        ident = k.isidentifier() and k.isascii() and k not in LUA_KEYWORDS
        lines.append(("%s=%d," if ident else '["%s"]=%d,') % (k, v))
    # several entries per line keeps the file short to scroll
    body = []
    row = ""
    for e in lines:
        if len(row) + len(e) > 110:
            body.append("    " + row.rstrip())
            row = ""
        row += e + " "
    if row:
        body.append("    " + row.rstrip())
    head = [
        "-- ZeD-UI/42/media/lua/shared/ZeD/ItemTints.lua",
        "-- ============================================================================",
        "-- EACH ITEM ICON'S MAIN COLOR, for the grid's item-colored tiles (the director, Nov 16 2026): a generated",
        "-- data table, written by ZeDUI/tools/grid_tint/bake_item_tints.py from the game's icons: do not edit by hand.",
        "-- ZeD.ItemTints: the icon's name without \"Item_\" -> its main color, 0xRRGGBB as one number (the saturation-",
        "-- weighted average of its colored pixels). Gray, black or white icons are 0x808080 (a neutral tint); other mods' items are not here.",
        "-- InventoryRenderer turns the raw color into each theme's tint. Shared, plain data. Pure ASCII.",
        "-- %d icons, %d of them gray." % (len(lines), gray),
        "-- ============================================================================",
        "ZeD = ZeD or {}",
        "ZeD.ItemTints = {",
    ]
    with open(OUT, "w", encoding="ascii", newline="\n") as f:
        f.write("\n".join(head + body + ["}", ""]))
    print("wrote %s: %d colors, %d gray, %d bytes" % (OUT, len(lines), gray, os.path.getsize(OUT)))


if __name__ == "__main__":
    main()
