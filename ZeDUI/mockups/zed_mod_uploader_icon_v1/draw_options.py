"""
Mod Uploader desktop icon, three options (Oct 25 2026; director: "Wonder if workshop should have an
icon on the desktop... Look like a FTP program... named, Mod Uploader.").

32 x 32 in the manner of ZeDUI/tools/mainmenu/bake_desktop_icons.py (its palette and helpers),
for the desk's icon column. Writes option_<a|b|c>.png here and mockup.html (the column at 3x on
the desk's wallpaper, each option after Mods, with its name).

  a  To the server: a computer, a cable up to the globe, an up arrow (the FTP programs of the time)
  b  The parcel: a mod packed in a tied box, an up arrow over it
  c  The mods folder sent up: the Mods icon's folder with an up arrow and a modem's waves

Usage:  py -I ZeDUI/mockups/zed_mod_uploader_icon_v1/draw_options.py
"""
import base64
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "ZeDUI", "tools", "mainmenu"))
import bake_desktop_icons as BI  # noqa: E402
from PIL import Image  # noqa: E402

K, W, L, M, D = BI.K, BI.W, BI.L, BI.M, BI.D
G, B, BL, Y, R, F, FD, BR = BI.G, BI.B, BI.BL, BI.Y, BI.R, BI.F, BI.FD, BI.BR
GN = (90, 170, 90, 255)       # the arrow's lit green
GD = (40, 100, 40, 255)       # its shade
SEA = (90, 130, 200, 255)     # the globe's sea
LAND = (110, 170, 90, 255)    # its land
TAN = (196, 160, 110, 255)    # the parcel's card
TAND = (150, 115, 70, 255)    # its shade


def up_arrow(ic, cx, top, h, half=4, shaft=2, fill=GN, shade=GD):
    """a fat up arrow: a triangle head (half wide each side) over a shaft, 1-px black outline"""
    head_h = half + 1
    for i in range(head_h):
        y = top + i
        ic.hline(cx - i, cx + i, y, K)
        if i > 0:
            ic.hline(cx - i + 1, cx + i - 1, y, fill)
    yb = top + head_h
    ic.hline(cx - half, cx + half, yb, K)
    ic.box(cx - shaft, yb, cx + shaft, top + h, fill)
    ic.vline(cx + shaft - 1, yb + 1, top + h - 1, shade)


def globe(ic, cx, cy, r):
    for y in range(32):
        for x in range(32):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d2 = dx * dx + dy * dy
            if d2 <= r * r:
                ic.p(x, y, K if d2 > (r - 1) * (r - 1) else SEA)
    # land, a meridian and the equator
    for (x0, y0, x1, y1) in ((cx - 4, cy - 4, cx - 1, cy - 1), (cx + 1, cy + 1, cx + 3, cy + 4), (cx - 3, cy + 2, cx - 2, cy + 3)):
        ic.rect(int(x0), int(y0), int(x1), int(y1), LAND)
    ic.vline(int(cx), int(cy - r + 1), int(cy + r - 2), BL)
    ic.hline(int(cx - r + 1), int(cx + r - 2), int(cy), BL)


def option_a():
    ic = BI.Icon()
    globe(ic, 22.5, 8.5, 8)
    BI.small_computer(ic, 1, 17)
    # the cable from the computer across and up to the globe
    ic.hline(12, 22, 23, K); ic.vline(22, 16, 23, K)
    ic.hline(12, 21, 22, M); ic.vline(21, 16, 22, M)
    up_arrow(ic, 7, 2, 12, half=4, shaft=2)
    return ic


def option_b():
    ic = BI.Icon()
    # the parcel: a box in perspective, tied with string
    ic.box(5, 16, 26, 29, TAN)
    ic.box(5, 12, 26, 17, TAN)
    ic.hline(6, 25, 13, (226, 196, 150, 255))
    ic.rect(6, 25, 25, 28, TAND)
    ic.vline(15, 12, 29, K); ic.vline(16, 12, 29, R)       # the string
    ic.hline(5, 26, 22, K); ic.hline(6, 25, 21, R)
    for bx in (11, 17):                                       # its bow: two loops
        ic.box(bx, 9, bx + 3, 11, R)
    ic.rect(15, 10, 16, 11, R)
    # the label
    ic.box(19, 23, 25, 27, W); ic.hline(20, 24, 25, M)
    up_arrow(ic, 15, 0, 8, half=4, shaft=2)
    return ic


def option_c():
    ic = BI.Icon()
    # the Mods folder (as icon_mods), smaller
    ic.box(3, 10, 11, 14, F)
    ic.box(3, 13, 25, 29, F)
    ic.hline(4, 10, 11, W); ic.hline(4, 24, 14, W)
    ic.rect(4, 26, 24, 28, FD)
    # the modem's waves, top right
    for i, r in enumerate((3, 6, 9)):
        for a in range(0, 91, 6):
            import math
            x = 22 + int(round(r * math.cos(math.radians(a))))
            y = 10 - int(round(r * math.sin(math.radians(a))))
            ic.p(x, y, K if i != 1 else D)
    ic.rect(21, 9, 22, 10, K)
    up_arrow(ic, 14, 1, 21, half=5, shaft=2)
    return ic


def b64(im, k=1):
    if k != 1:
        im = im.resize((im.width * k, im.height * k), Image.NEAREST)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def main():
    opts = {"a": option_a().im, "b": option_b().im, "c": option_c().im}
    for k, im in opts.items():
        im.save(os.path.join(HERE, "option_%s.png" % k))
    icons = {n: BI.ICONS[n]().im for n in ("pz", "newgame", "load", "join", "options", "mods")}
    wall = Image.open(os.path.join(ROOT, "42", "media", "textures", "ZeD", "mainmenu", "wallpaper.png")).convert("RGB")
    wall = wall.resize((wall.width // 2, wall.height // 2))
    wb = io.BytesIO(); wall.save(wb, "JPEG", quality=70)
    wall64 = "data:image/jpeg;base64," + base64.b64encode(wb.getvalue()).decode()
    names = [("options", "Options"), ("mods", "Mods")]   # the bottom of the column, so the page fits one screen
    TITLES = {"a": "A | To the server", "b": "B | The parcel", "c": "C | The mods folder sent up"}
    NOTES = {"a": "A computer, its cable up to the globe, an up arrow: how the FTP programs of the time looked.",
             "b": "A mod packed in a tied box, with an up arrow over it: sending a parcel.",
             "c": "The Mods icon's lilac folder with an up arrow and a modem's waves: it reads as part of Mods."}
    cols = []
    for k in ("a", "b", "c"):
        cells = "".join('<div class="cell"><img src="%s"><span>%s</span></div>' % (b64(icons[n], 3), lab) for n, lab in names)
        cells += '<div class="cell new"><img src="%s"><span>Mod Uploader</span></div>' % b64(opts[k], 3)
        cols.append('<section><h2>%s</h2><div class="desk" style="background-image:url(%s)">%s</div>'
                    '<div class="big"><img src="%s"><img src="%s"></div><p>%s</p></section>'
                    % (TITLES[k], wall64, cells, b64(opts[k], 6), b64(opts[k], 2), NOTES[k]))
    html = """<!doctype html><html><head><meta charset="utf-8"><title>Mod Uploader icon</title>
<style>
body{margin:0;background:#1a1a1e;color:#d4d4d8;font:14px 'Fira Sans',sans-serif}
header{padding:12px 16px;border-bottom:1px solid rgba(255,255,255,.2);font:600 15px 'Fira Mono',monospace}
header small{display:block;font:400 13px 'Fira Sans',sans-serif;color:rgba(255,255,255,.6);margin-top:4px}
main{display:flex;gap:16px;padding:16px;flex-wrap:wrap}
section{flex:1;min-width:300px;border:1px solid rgba(255,255,255,.2);background:#222226}
h2{margin:0;padding:8px 12px;font:600 14px 'Fira Mono',monospace;color:#d4a04a;border-bottom:1px solid rgba(255,255,255,.1)}
.desk{display:flex;flex-direction:column;align-items:flex-end;gap:10px;padding:14px;background-size:cover;background-position:right center;height:auto}
.cell{width:130px;display:flex;flex-direction:column;align-items:center;gap:4px}
.cell img{width:96px;height:96px;image-rendering:pixelated}
.cell span{font:13px 'Fira Mono',monospace;color:#fff;text-shadow:0 0 3px #000,0 0 2px #000}
.cell.new span{color:#ffd27a}
.big{display:flex;align-items:flex-end;gap:16px;padding:12px;border-top:1px solid rgba(255,255,255,.1)}
.big img{image-rendering:pixelated}
p{margin:0;padding:0 12px 12px;color:rgba(255,255,255,.7)}
</style></head><body>
<header>ZeD-UI | main menu | desktop | Mod Uploader icon | mockup v1
<small>Three options for the Workshop uploader's desktop icon, after Mods at the bottom of the icon column (3x on the desk's wallpaper; each option also at 6x and at 2x). A double click opens the Workshop window, as the File menu's Workshop item does.</small></header>
<main>%s</main></body></html>""" % "".join(cols)
    out = os.path.join(ROOT, "ZeDUI", "mockups", "zed_mod_uploader_icon_v1.html")
    open(out, "w", encoding="utf-8").write(html)
    print("wrote", out, os.path.getsize(out), "bytes")


if __name__ == "__main__":
    main()
