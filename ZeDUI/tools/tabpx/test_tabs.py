"""The lit tabs outside the game: the real ZeD_TabPx.lua under LuaJIT draws every icon, active, washed and plain, in
each base theme (dark, light, high contrast) with several accents, at 1x and 2x; the picture must equal this file's own
drawing of the same thing (the reference the concept sheets were made from), pixel for pixel. usage: python test_tabs.py"""
import os
import sys

import numpy as np
from PIL import Image
import lupa.luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from icons import ICONS, TONES     # noqa: E402
import export_tabs as EX           # noqa: E402

# In the repo (ZeDUI/tools/tabpx) the Lua is the mod's own and the masks are exported to a scratch folder; in a scratch
# copy, the Lua beside this file (or physpx's working copy of the pixel parts).
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
ROOT = os.path.join(HERE, "out", "mod", "ZeD-UI")
if os.path.isdir(os.path.join(REPO, "42", "media", "lua", "client", "ZeD")) and not os.path.exists(os.path.join(HERE, "ZeD_TabPx.lua")):
    _SRC = os.path.join(REPO, "42", "media", "lua", "client", "ZeD")
    LUA, PIXPARTS = os.path.join(_SRC, "ZeD_TabPx.lua"), os.path.join(_SRC, "ZeD_PixelParts.lua")
else:
    LUA = os.path.join(HERE, "ZeD_TabPx.lua")
    PIXPARTS = os.path.join(HERE, "..", "physpx", "lua", "ZeD_PixelParts.lua")

def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))

THEMES = {   # base: (surface, textOnAccent rule) ; accents: (accent, bright, textOnAccent) dark / light
    "dark":  ("#141414", {"orange": ("#D4922A", "#E8A830", "#0C0C0C"), "blue": ("#4488CC", "#66AAEE", "#0C0C0C"),
                          "mono": ("#888888", "#AAAAAA", "#0C0C0C"), "pink": ("#DD5588", "#FF77AA", "#0C0C0C")}),
    "light": ("#BEBEBE", {"orange": ("#7A5010", "#B07818", "#F2F0EC"), "blue": ("#1A4477", "#336699", "#F2F0EC"),
                          "mono": ("#3A3A3A", "#666666", "#F2F0EC"), "pink": ("#882244", "#BB4470", "#F2F0EC")}),
    "hicon": ("#111111", {"orange": ("#D4922A", "#E8A830", "#0C0C0C"), "green": ("#44AA44", "#66CC66", "#0C0C0C")}),
}


class Paint:
    def __init__(s, w, h, bg):
        s.a = np.zeros((h, w, 3), np.float64); s.a[...] = np.array(bg) * 255; s.cache = {}

    def rect(s, x, y, w, h, a, r, g, b):
        x0, y0, x1, y1 = int(x), int(y), int(x + w), int(y + h)
        x0, y0 = max(0, x0), max(0, y0); x1, y1 = min(s.a.shape[1], x1), min(s.a.shape[0], y1)
        if x1 <= x0 or y1 <= y0: return
        c = np.array([r, g, b]) * 255
        s.a[y0:y1, x0:x1] = s.a[y0:y1, x0:x1] * (1 - a) + c * a

    def tex(s, path, x, y, w, h, a, r, g, b):
        if path not in s.cache:
            s.cache[path] = np.array(Image.open(os.path.join(ROOT, "42", path)).convert("RGBA"))
        im = s.cache[path]
        k = int(w) // im.shape[1]
        al = np.repeat(np.repeat(im[..., 3] / 255.0, k, 0), k, 1) * a
        x, y = int(x), int(y)
        reg = s.a[y:y + al.shape[0], x:x + al.shape[1]]
        al = al[:reg.shape[0], :reg.shape[1], None]
        c = np.array([r, g, b]) * 255
        s.a[y:y + al.shape[0], x:x + al.shape[1]] = reg * (1 - al) + c * al

    def image(s): return np.clip(np.floor(s.a + 0.5), 0, 255).astype(np.uint8)


# ---- the reference drawing (the same arithmetic as ZeD_TabPx.lua) ----
def clamp(v): return min(1.0, max(0.0, v))
def shade(c, f): return tuple(clamp(x * f) for x in c)
def mix(a, b, t): return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))
WHITE = (1.0, 250 / 255, 240 / 255)
ENGRAVE = {"w": 0.45, "l": 0.55, "m": 0.68, "d": 0.80, "k": 0.92}


def tones(acc, bright, on, active):
    if active:
        onLight = sum(on) > 1.5
        return {t: mix(acc, on, (1.37 - ENGRAVE[t]) if onLight else ENGRAVE[t]) for t in TONES}
    return {"w": mix(shade(bright, 1.0), WHITE, 0.55), "l": shade(bright, 1.22), "m": shade(acc, 1.0),
            "d": shade(acc, 0.58), "k": shade(acc, 0.34)}


def ref_tab(p, x, y, w, h, name, active, washed, line, k, acc, bright, on):
    b = line
    if active:
        p.rect(x, y, w, h, 1, *shade(acc, 0.85))
        p.rect(x, y + h - 2 * b, w, 2 * b, 1, *shade(acc, 0.55))
        p.rect(x + w - b, y, b, h, 1, *shade(acc, 0.60))
        p.rect(x, y, w, b, 1, *shade(bright, 1.10))
        p.rect(x, y, b, h, 1, *shade(bright, 1.05))
    elif washed:
        p.rect(x, y, w, h, 0.30, *acc)
    sz = 16 * k
    cx, cy = x + w // 2, y + h // 2
    ix, iy = cx - sz // 2, cy - sz // 2
    p.tex(f"{EX.DIR}/{name}_sh.png", ix + k, iy + k, sz, sz, 0.25 if active else 0.55, 0, 0, 0)
    tn = tones(acc, bright, on, active)
    for t in TONES:
        p.tex(f"{EX.DIR}/{name}_{t}.png", ix, iy, sz, sz, 1, *tn[t])


def lua():
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute('''Texture = { getSharedTexture = function(path, f) return { path = path } end }
                 getTimestampMs = function() return 0 end
                 require = function() end
                 ZeD = {}''')
    L.execute(open(PIXPARTS, "rb").read())
    L.execute(open(LUA, "rb").read())
    return L


FAILS = []


def run(scale):
    k = max(1, int(scale + 0.5))
    line = max(1, int(scale + 0.5))
    W, B = 36 * k, 36 * k
    L = lua()
    names = list(ICONS)
    sheets = []
    for base, (surf, accs) in THEMES.items():
        for an, (a, br, on) in accs.items():
            acc, bright, onc = hx(a), hx(br), hx(on)
            H = B * len(names)
            got = Paint(W * 3, H, hx(surf)); want = Paint(W * 3, H, hx(surf))
            L.globals().SCALE = scale
            L.execute(f'''ZeD.Scale = {{ root = function() return {scale} end }}
                ZeD.T = {{ accent = {{ r = {acc[0]}, g = {acc[1]}, b = {acc[2]}, a = 1 }},
                           accentBright = {{ r = {bright[0]}, g = {bright[1]}, b = {bright[2]}, a = 1 }},
                           textOnAccent = {{ r = {onc[0]}, g = {onc[1]}, b = {onc[2]}, a = 1 }} }}''')
            el = L.table_from({})
            el.drawRect = lambda self, x, y, w, h, al, r, g, b: got.rect(x, y, w, h, al, r, g, b)
            el.drawTextureScaled = lambda self, t, x, y, w, h, al, r, g, b: got.tex(t.path, x, y, w, h, al, r, g, b)
            draw = L.eval("ZeD.TabPx.drawTab")
            for i, n in enumerate(names):
                for col, (act, wash) in enumerate(((False, False), (True, False), (False, True))):
                    draw(el, col * W, i * B, W, B, n, act, wash, line)
                    ref_tab(want, col * W, i * B, W, B, n, act, wash, line, k, acc, bright, onc)
            g, w_ = got.image(), want.image()
            d = np.abs(g.astype(int) - w_.astype(int)).max()
            ok = d <= 1
            print(("  ok   " if ok else "  FAIL ") + f"{scale}x {base} {an}: max difference {d}")
            if not ok: FAILS.append(f"{scale} {base} {an}")
            sheets.append(Image.fromarray(g, "RGB"))
    return sheets


if __name__ == "__main__":
    EX.export(ROOT)
    s1 = run(1.0); s2 = run(2.0)
    # a sheet of every theme at 1x: plain / active / washed columns per theme
    Wd = sum(s.width + 8 for s in s1) + 8
    sheet = Image.new("RGB", (Wd, s1[0].height + 16), (60, 60, 64))
    x = 8
    for s in s1: sheet.paste(s, (x, 8)); x += s.width + 8
    sheet.save(os.path.join(HERE, "tabs_themes_1x.png"))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(HERE, "tabs_themes_2x.png"))
    print(f"{len(FAILS)} failed", FAILS)
    sys.exit(1 if FAILS else 0)
