"""ZeD overhead icons on the light balloon (Nov 17 2026). The director, Nov 17: every bubble is light, "any tooltips,
any bubbles" (8d331a08f). The Nov 15 set (overhead.py, reviewed on the dark balloon as overhead_icons_review_v2) is
redrawn here on the bubbles' light palette, ZeD.Balloon.LIGHT in Balloon.lua: the body surf1 (CCCCCC), its line
borderS (424242), near-black ink; the status square in the light palette's marks, positive 1E7D22 and danger C01C1C,
and for a warning the round 1b light gold B57F00 (white ! on it, 3.5:1). Lines the dark set drew in paper white (the
shut eye, the sound waves, the noise, the typing dots) are ink here. A "don't have it" icon (the key you lack) fades
toward the body instead of darkening. Sizes and shapes are the Nov 15 ones.

writes art/overhead_light/{1x,2x}/<name>.png (the badge: shadow, balloon, icon, status) and icons/<name>.png (the icon
alone, ink on clear, for a balloon ZeD draws itself)"""
import os
import numpy as np
from PIL import Image
import overhead as O

FILL = (204, 204, 204); LINE = (66, 66, 66); INKC = (12, 12, 12)
POS, NEG, WARN = (0x1E, 0x7D, 0x22), (0xC0, 0x1C, 0x1C), (0xB5, 0x7F, 0x00)
STROKE = {"eye_shut", "noise", "typing"}                       # all of their paper white is a line: ink
WAVES = {"speaker": 7}                                          # paper white right of this column is a line: ink

def rows_light(name):
    r = O.ICON[name]
    if name in STROKE: return [s.replace("w", "k") for s in r]
    if name in WAVES:
        c = WAVES[name]; return [s[:c] + s[c:].replace("w", "k") for s in r]
    return r

PAL = dict(O.PAL); PAL["k"] = INKC

def icon_img(name, dim=False):
    im = O.sprite(rows_light(name), PAL)
    if dim:
        a = np.asarray(im).astype(float); m = a[..., 3] > 0
        a[..., :3][m] = a[..., :3][m] * 0.5 + np.array(FILL) * 0.5
        im = Image.fromarray(a.astype(np.uint8), "RGBA")
    return im

def badge(icon, status=None, dim=False, w=None, h=None, tail=True):
    O.FILL, O.INK, O.POS, O.NEG, O.WARN = FILL, LINE, POS, NEG, WARN
    img = O.badge(icon_img(icon, dim), status, False, w, h, tail)
    if status:                                                  # the status square's own line: ink, not the body's grey
        a = np.asarray(img).copy()
        ic = icon_img(icon, dim); bw = w or max(22, ic.width + 8); bh = h or max(20, ic.height + 8)
        sx, sy = bw - 6, bh - 7
        sq = a[sy:sy + 9, sx:sx + 9]
        edge = np.zeros((9, 9), bool); edge[0, :] = edge[-1, :] = edge[:, 0] = edge[:, -1] = True
        sq[edge] = (*INKC, 255)
        img = Image.fromarray(a, "RGBA")
    return img

if __name__ == "__main__":
    for d in ("1x", "2x", "icons"): os.makedirs(f"art/overhead_light/{d}", exist_ok=True)
    out = {}
    for n, kw in O.SET.items():
        im = badge(**kw); out[n] = im.size
        im.save(f"art/overhead_light/1x/{n}.png")
        im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(f"art/overhead_light/2x/{n}.png")
        icon_img(kw["icon"], kw.get("dim", False)).save(f"art/overhead_light/icons/{n}.png")
    for up in (True, False):
        n = "ArrowUp" if up else "ArrowDown"
        rows = ["....k....", "...kek...", "..keeek..", ".keeeeek.", "keeeeeeek", "kkkkkkkkk"] if up else \
               ["kkkkkkkkk", "krrrrrrrk", ".krrrrrk.", "..krrrk..", "...krk...", "....k...."]
        p = dict(PAL); p["e"], p["r"] = POS, NEG
        im = Image.new("RGBA", (13, 13), (0, 0, 0, 0)); im.alpha_composite(O.sprite(rows, p), (2, 3))
        im.save(f"art/overhead_light/1x/{n}.png"); im.resize((26, 26), Image.NEAREST).save(f"art/overhead_light/2x/{n}.png")
        out[n] = im.size
    print(out)
