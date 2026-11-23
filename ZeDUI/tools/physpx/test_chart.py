"""The body figure's height chart outside the game (the director, Nov 22 2026: "Draw a diagram background. Very simple,
just to fill in the empty white space on each side.", and of the mock, "I like it."; Nov 23 2026: "remove the notes,
move the skelly up the measure will stop at their height. reason, not filling the space with useful info.").

The real ZeD_BodyFigure.lua draws the chart in the margins of the figure's frame, and the real Molecules.lua lays the
frame out (figureFrame and layoutZoneA, with drawFigureFrame and Atoms.frame). The checks:

- The frame, the chart and the figure together come to the chart the director passed under the figure, within one
  level in 255 (d_chart.approved, the mock's layout). Both sexes, all three bases, at 4K (1.75), 1080p (1.0) and
  1280x800 (0.75): on the Health tab, on the medical card in halves and stacked, at the narrowest halves, and in a span
  too narrow for the figure.
- Every line sits inside the frame's line, on the art's pixel grid, in the ruler's ink and tint, and nothing of it lies
  under the figure's own pixels. The lines' picture is the only picture: no script. Four draws at most, the same for
  him and her, no table made, and Lite draws the same chart as Full.
- The measure stops at the character's height: the ruler's rail ends at the top of the head, nothing of the ruler
  stands above it, and the chart's lines are the ruler's ticks under both heads (half a foot up to 5 1/2 ft). He stands
  5'9" and she 5'8", 4 and 8 rows under the canvas's top, and the canvas is the figure's own size in the Lua and the
  tokens (106 x 254).
- The lines' picture exists, loads once and is nearest-filtered.
- The figure's CHART table is d_chart.py's.
- The four places the figure sits draw the chart after the frame and before the controller's mark and the figure.

usage: python test_chart.py [Lua folder [preview.png]]
  Lua folder: holds ZeD_BodyFigure, Molecules, Atoms, HealthTab, ThermalTab, EquipmentTab and ObjectCardMedic (.lua);
  default the mod's own (Tokens.lua is looked for in ../../shared/ZeD beside it, as the mod lays it out). preview.png:
  also writes the chart as the game draws it, for review."""
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw
import lupa.luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.chdir(HERE)
import d_skeleton as SK          # noqa: E402
import d_chart as DC             # noqa: E402

ROOT = os.path.join(HERE, "out", "mod", "ZeD-UI")
SK.export(ROOT)
DC.export(ROOT)
CLIENT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "..", "42", "media", "lua", "client", "ZeD")
PREVIEW = sys.argv[2] if len(sys.argv) > 2 else None
FAILS = []
COUNT = [0]


def check(what, ok, detail=""):
    COUNT[0] += 1
    if not ok:
        print("  FAIL " + what + "  " + str(detail))
        FAILS.append(what)


def src(name):
    return open(os.path.join(CLIENT, name), "rb").read().decode("utf-8").replace("\r\n", "\n")


# the themes: the mock's Dark and Light (the shipped Teal accent's tones), and High Contrast, which takes the dark ink
THEMES = {
    "dark": dict(surf=(20, 20, 20), border=(56, 56, 56), accent=(71, 161, 140), dim=(161, 161, 161), ink=(255, 255, 255)),
    "light": dict(surf=(190, 190, 190), border=(118, 118, 118), accent=(26, 102, 85), dim=(12, 12, 12), ink=DC.INK_LIGHT),
    "hicon": dict(surf=(17, 17, 17), border=(85, 85, 85), accent=(255, 214, 10), dim=(200, 200, 200), ink=(255, 255, 255)),
}
ICON = (240, 240, 235)
CACHE = {}
MISSING = set()                  # pictures drawn that the tools did not make (drawn as nothing, and a check fails)


def tex(path):
    if path not in CACHE:
        full = os.path.join(ROOT, "42", path)
        if os.path.exists(full):
            CACHE[path] = np.asarray(Image.open(full).convert("RGBA")).astype(np.float32) / 255
        else:
            MISSING.add(path)
            CACHE[path] = np.zeros((1, 1, 4), np.float32)
    return CACHE[path]


class Canvas:
    """the screen: drawRect and drawTextureScaled blended as the game blends them (over, in order)"""
    def __init__(s, w, h, surf):
        s.a = np.zeros((h, w, 3), np.float32) + np.array(surf, np.float32) / 255
        s.calls = []

    def _over(s, x, y, col, al):
        H_, W_ = s.a.shape[:2]
        h, w = al.shape[:2]
        x0, y0, x1, y1 = max(0, x), max(0, y), min(W_, x + w), min(H_, y + h)
        if x1 <= x0 or y1 <= y0:
            return
        c = col[y0 - y:y1 - y, x0 - x:x1 - x]
        a = al[y0 - y:y1 - y, x0 - x:x1 - x]
        s.a[y0:y1, x0:x1] = s.a[y0:y1, x0:x1] * (1 - a) + c * a

    def rect(s, x, y, w, h, alpha, r, g, b):
        s.calls.append(("rect", x, y, w, h, alpha, r, g, b))
        x, y, w, h = int(x), int(y), int(w), int(h)
        if w > 0 and h > 0:
            s._over(x, y, np.broadcast_to(np.array([r, g, b], np.float32), (h, w, 3)),
                    np.full((h, w, 1), alpha, np.float32))

    def draw(s, path, x, y, w, h, alpha, r, g, b):
        s.calls.append(("tex", path, x, y, w, h, alpha, r, g, b))
        im = tex(path)
        w, h = int(w), int(h)
        ih, iw = im.shape[:2]
        im = im[np.arange(h) * ih // h][:, np.arange(w) * iw // w]      # nearest: each screen pixel's art pixel
        s._over(int(x), int(y), im[..., :3] * np.array([r, g, b], np.float32), im[..., 3:4] * alpha)

    def layer(s, a, x, y, z, col):
        """one layer of alpha (art pixels, each z x z) in one color"""
        a = np.repeat(np.repeat(a, z, axis=0), z, axis=1)[..., None]
        s._over(int(x), int(y), np.broadcast_to(np.array(col, np.float32), a.shape[:2] + (3,)), a)

    def u8(s):
        return np.clip(np.round(s.a * 255), 0, 255).astype(np.int16)


def cut(text, start, end):
    a = text.find(start)
    b = text.find(end, a)
    assert a >= 0 and b > a, (start, end)
    return text[a:b + len(end)]


MOL, ATOMS, FIG = src("Molecules.lua"), src("Atoms.lua"), src("ZeD_BodyFigure.lua")
PAD = int(re.search(r"\nlocal TAB_HEADER_PAD\s*=\s*(\d+)", MOL).group(1))
GAP = int(re.search(r"\nlocal TAB_COL_GAP\s*=\s*(\d+)", MOL).group(1))
FRAME_CODE = cut(MOL, "local FIG_FRAME_INSET", "\n-- 11. STAT ROW")
ATOMS_FRAME = cut(ATOMS, "function ZeD.Atoms.frame(", "\nend\n")
ASKED = []                       # (path, filter) for every picture the figure loads


def lua_for(scale, base, sex):
    """the figure in a fresh Lua, with the frame's layout and drawing from Molecules.lua and Atoms.lua, at a UI scale
    (T.px rounds design units to whole pixels, T.art is the nearest whole zoom, as Tokens.lua and Scale.lua)"""
    th = THEMES[base]
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute('''require = function() end
        ISPanel = { render = function() end, onMouseMove = function() end, onMouseMoveOutside = function() end,
                    onMouseDown = function() end }
        function ISPanel:derive(name) local c = {}; c.__index = c; setmetatable(c, { __index = ISPanel }); return c end
        function ISPanel:new(x, y, w, h) return { x = x, y = y, w = w, h = h } end
        ZeD = { T = {}, Molecules = {}, Atoms = {}, Settings = { lite = function() return LITE end } }
        LITE = false
        function ZeD.colorBlend(base, overlay, strength)
            local inv = 1.0 - strength
            return { r = base.r * inv + overlay.r * strength, g = base.g * inv + overlay.g * strength,
                     b = base.b * inv + overlay.b * strength, a = base.a }
        end''')
    g = L.globals()
    g.Texture = L.table_from({"getSharedTexture": lambda path, f: (ASKED.append((path, f)),
                                                                   L.table_from({"path": path, "f": f}))[1]})
    art = max(1, int(np.floor(scale + 0.5 + 1e-6)))
    L.execute(f'''local sc, art = {scale!r}, {art}
        ZeD.T.px = function(u) return math.floor(u * sc + 0.5) end
        ZeD.T.art = art
        ZeD.T.sp = {{ figureW = {SK.FW} * art, figureH = {SK.FH} * art, scrollbarW = math.floor(14 * sc + 0.5) }}
        ZeD.T.baseKey = "{base}"
        ZeD.currentBase = "{base}"''')

    def col(c):
        return L.table_from({"r": c[0] / 255, "g": c[1] / 255, "b": c[2] / 255, "a": 1})
    g.ZeD.T.borderS = col(th["border"])
    g.ZeD.T.iconWhite = col(ICON)
    g.ZeD.T.accent = col(th["accent"])
    g.ZeD.T.textDim = col(th["dim"])
    L.execute(ATOMS_FRAME)
    L.execute(f"local TAB_HEADER_PAD, TAB_COL_GAP = {PAD}, {GAP}\n" + FRAME_CODE)
    L.execute(FIG)
    fig = g.ZeD_BodyFigure.new(g.ZeD_BodyFigure, 0, 0, 100, 100, 0)
    fig.setSex(fig, sex == "f")
    return L, g, fig


def panel(L, cv):
    P = L.table()
    P.drawRect = lambda self, x, y, w, h, a, r, gg, b: cv.rect(x, y, w, h, a, r, gg, b)
    P.drawTextureScaled = lambda self, t, x, y, w, h, a, r, gg, b: cv.draw(t.path, x, y, w, h, a, r, gg, b)
    P.drawTextureScaledUniform = lambda self, t, x, y, s_, a, r, gg, b: cv.draw(
        t.path, x, y, tex(t.path).shape[1] * s_, tex(t.path).shape[0] * s_, a, r, gg, b)
    return P


def tint_of(base):
    th = THEMES[base]
    return [(ICON[i] / 255) * 0.55 + (th["accent"][i] / 255) * 0.45 for i in range(3)]


def ink_of(base):
    th, tint = THEMES[base], tint_of(base)
    return tuple((th["ink"][i] / 255) * tint[i] for i in range(3))


def lay(Lo):
    return {k: Lo[k] for k in ("two", "zoom", "frameX", "frameY", "frameW", "frameH", "figX", "figY", "figW", "figH")}


# the lines' picture, and the figure's own pixels (background, skeleton, parts) in art pixels
LINES = "fig-chart-lines.png"
FIGURE_A = {}
for sex in ("m", "f"):
    a = np.zeros((SK.FH, SK.FW), np.float32)
    for b_ in ("dark", "light"):
        a = np.maximum(a, tex(f"media/textures/ZeD/body/fig-bg-{sex}-{b_}.png")[..., 3])
    a = np.maximum(a, tex(f"media/textures/ZeD/body/{sex}-skeleton.png")[..., 3])
    for p in SK.PARTS:
        a = np.maximum(a, tex(f"media/textures/ZeD/body/{sex}-{p}.png")[..., 3])
    FIGURE_A[sex] = a > 0


def reference(Ld, sex, base, scale, W, H):
    """the frame (Atoms.frame's four lines), the chart the director passed (one layer), the figure as drawAt draws it"""
    th = THEMES[base]
    c = Canvas(W, H, th["surf"])
    t = int(np.floor(scale + 0.5))
    x, y, w, h = Ld["frameX"], Ld["frameY"], Ld["frameW"], Ld["frameH"]
    bc = [v / 255 for v in th["border"]]
    c.rect(x, y, w, t, 1, *bc)
    c.rect(x, y + h - t, w, t, 1, *bc)
    if h > 2 * t:
        c.rect(x, y + t, t, h - 2 * t, 1, *bc)
        c.rect(x + w - t, y + t, t, h - 2 * t, 1, *bc)
    z = Ld["zoom"]
    sideL = (Ld["figX"] - (x + t)) // z
    sideR = (x + w - t - (Ld["figX"] + Ld["figW"])) // z
    c.layer(DC.approved(sex, sideL, sideR), Ld["figX"] - sideL * z, Ld["figY"], z, ink_of(base))
    fx, fy, fw, fh = Ld["figX"], Ld["figY"], Ld["figW"], Ld["figH"]
    c.draw(f"media/textures/ZeD/body/fig-bg-{sex}-{'light' if base == 'light' else 'dark'}.png", fx, fy, fw, fh, 1.0,
           *tint_of(base))
    c.draw(f"media/textures/ZeD/body/{sex}-skeleton.png", fx, fy, fw, fh, 1, 1, 1, 1)
    for p in SK.PARTS:
        c.draw(f"media/textures/ZeD/body/{sex}-{p}.png", fx, fy, fw, fh, 0.10, *[v / 255 for v in th["dim"]])
    return c, sideL, sideR


SCREENS = (("4K (1.75)", 1.75), ("1080p (1.0)", 1.0), ("1280x800 (0.75)", 0.75))


def layouts(g):
    """the places the figure sits at the Lua's scale: (name, layout)"""
    T, M = g.ZeD.T, g.ZeD.Molecules
    px = T.px
    ox, oy = 9, 7
    yield "Health", M.layoutZoneA(ox, oy, px(480) - T.sp.scrollbarW)            # the 480 drawer, less its scroll bar
    yield "medic 336", M.figureFrame(ox + px(10), oy, px(336) - px(10) * 2)      # ObjectCards' 10-unit pads
    yield "medic 220 (stacked)", M.figureFrame(ox + px(10), oy, px(220) - px(10) * 2)
    yield "the narrowest halves", M.figureFrame(ox, oy, 2 * (T.sp.figureW + 2 * px(10)) + px(GAP))
    yield "too narrow for the figure", M.figureFrame(ox + 60, oy, px(60))


SEEN = {}
for sname, scale in SCREENS:
    for base in ("dark", "light", "hicon"):
        for sex in ("m", "f"):
            L, g, fig = lua_for(scale, base, sex)
            for lname, Lo in layouts(g):
                Ld = lay(Lo)
                name = f"{sname}, {lname}, {base}, {sex}"
                W = Ld["frameX"] + max(Ld["frameW"], Ld["figX"] - Ld["frameX"] + Ld["figW"]) + 70
                H = Ld["frameY"] + Ld["frameH"] + 9
                cv = Canvas(W, H, THEMES[base]["surf"])
                P = panel(L, cv)
                # as the tabs draw it: the frame, the chart, then the figure
                g.ZeD.Molecules.drawFigureFrame(P, Lo)
                n0 = len(cv.calls)
                fig.drawChart(fig, P, Lo)
                chart = cv.calls[n0:]
                fig.drawAt(fig, P, Ld["figX"], Ld["figY"], Ld["figW"], Ld["figH"])
                ref, sideL, sideR = reference(Ld, sex, base, scale, W, H)
                diff = int(np.abs(cv.u8() - ref.u8()).max())
                check(f"{name}: the frame, chart and figure come to the chart passed, under the figure", diff <= 1, diff)
                SEEN[(sname, lname, base, sex)] = (cv, Ld, sideL, sideR)

                # every line and picture: inside the frame's line (and the margin), on the art's grid, the ruler's ink
                z, t = Ld["zoom"], int(np.floor(scale + 0.5))
                inL, inR = Ld["frameX"] + t + DC.MARGIN * z, Ld["frameX"] + Ld["frameW"] - t - DC.MARGIN * z
                inT, inB = Ld["frameY"] + t, Ld["frameY"] + Ld["frameH"] - t
                ink = ink_of(base)
                bad = []
                for c in chart:
                    if c[0] == "rect":
                        _, x, y, w, h, a, r, gg, b = c
                        alpha_ok = a == DC.FLOOR_A
                    else:
                        _, path, x, y, w, h, a, r, gg, b = c
                        alpha_ok = a == 1
                    inside = inL <= x and x + w <= inR and inT <= y and y + h <= inB
                    grid = (x - Ld["figX"]) % z == 0 and (y - Ld["figY"]) % z == 0 and w % z == 0 and h % z == 0
                    color = max(abs(r - ink[0]), abs(gg - ink[1]), abs(b - ink[2])) < 1e-9
                    if not (inside and grid and color and alpha_ok and w > 0 and h > 0):
                        bad.append(c[:6])
                check(f"{name}: the chart keeps inside the frame, on the art's grid, in the ruler's ink", not bad, bad[:3])
                # nothing of the chart under the figure's own pixels (the floor goes round the ruler's floor tick; the
                # lines keep off the canvas)
                under = 0
                for c in chart:
                    if c[0] == "tex" and c[1].endswith(LINES):
                        x, w = c[2], c[4]
                        if x < Ld["figX"] + Ld["figW"] and x + w > Ld["figX"]:
                            under += 1
                    if c[0] == "rect":
                        _, x, y, w, h = c[:5]
                        row = (y - Ld["figY"]) // z
                        c0, c1 = max(0, (x - Ld["figX"]) // z), min(SK.FW, (x + w - Ld["figX"]) // z)
                        if 0 <= row < SK.FH and c1 > c0:
                            under += int(FIGURE_A[sex][row, c0:c1].sum())
                check(f"{name}: nothing of the chart lies under the figure", under == 0, under)
                # no script (Nov 23 2026: "remove the notes"): the lines' picture is the only one drawn
                others = sorted({c[1] for c in chart if c[0] == "tex" and not c[1].endswith(LINES)})
                check(f"{name}: no picture but the lines'", not others, others)
                # the lines: their picture on each side with room for them, the whole canvas high; the floor in
                # one or two pieces; four draws at most
                lines = [c for c in chart if c[0] == "tex" and c[1].endswith(LINES)]
                want_lines = int(sideL - 2 * DC.MARGIN > 0) + int(sideR - 2 * DC.MARGIN > 0)
                check(f"{name}: the lines on each side with room for them", len(lines) == want_lines and all(
                    c[3] == Ld["figY"] and c[5] == SK.FH * z for c in lines), (len(lines), want_lines))
                floor = [c for c in chart if c[0] == "rect"]
                check(f"{name}: the floor in at most two pieces, on its row",
                      1 <= len(floor) <= 2 and all(c[2] == Ld["figY"] + SK.FLOOR * z for c in floor), floor)
                check(f"{name}: four draws at most", len(chart) <= 4, len(chart))

check("every picture drawn is one the tools make", not MISSING, sorted(MISSING))

# ---- the picture: it exists, loads once, nearest-filtered (NEAREST = 3, as the figure's own); no script is asked for
line_asks = [(p, f) for p, f in ASKED if p.endswith(LINES)]
check("the lines' picture was asked for", len({p for p, _ in line_asks}) == 1, sorted({p for p, _ in line_asks}))
check("the lines' picture exists", all(os.path.exists(os.path.join(ROOT, "42", p)) for p, _ in line_asks),
      sorted({p for p, _ in line_asks}))
check("the lines' picture is nearest-filtered", all(f == 3 for _, f in line_asks))
notes = sorted({p for p, _ in ASKED if "fig-notes-" in p})
check("no script picture is asked for (the notes went on Nov 23 2026)", not notes, notes)
col = tex("media/textures/ZeD/body/" + LINES)
check("the lines' picture is a column the canvas high, each line on its row", col.shape[:2] == (SK.FH, 1) and all(
    abs(col[y, 0, 3] - a) < 0.5 / 255 for y, a in zip(DC.ROWS, DC.ALPHAS)) and int((col[..., 3] > 0).sum()) == len(
    DC.ROWS), (col.shape, int((col[..., 3] > 0).sum())))
# (each Lua above is a fresh one: within one, a picture loads once however often it is drawn)
L, g, fig = lua_for(1.0, "dark", "m")
ASKED.clear()
cv = Canvas(600, 400, THEMES["dark"]["surf"])
P = panel(L, cv)
Lo = g.ZeD.Molecules.layoutZoneA(0, 0, 466)
for _ in range(3):
    fig.drawChart(fig, P, Lo)
asks = [p for p, _ in ASKED if p.endswith(LINES)]
check("the lines' picture loads once, however often drawn", len(asks) == 1, asks)
# his chart and hers are the same draws: the lines stop under both heads
n0 = len(cv.calls)
fig.drawChart(fig, P, Lo)
his = cv.calls[n0:]
fig.setSex(fig, True)
n0 = len(cv.calls)
fig.drawChart(fig, P, Lo)
hers = cv.calls[n0:]
check("his chart and hers are the same draws", his == hers and len(his) == 4, (his, hers))
# Lite draws the same chart (the director, Nov 22 2026: the chart shows in Lite too, as the flesh and the wounds do)
g.LITE = True
n0 = len(cv.calls)
fig.drawChart(fig, P, Lo)
check("Lite: the same chart as Full", cv.calls[n0:] == hers, cv.calls[n0:])
g.LITE = False
# no table made a frame, once the pictures are loaded (a panel in Lua; the JIT off, the collector stopped): against the
# same frames with one colorBlend each, the table drawAt's tint makes
made, blend = L.execute('''local fig, Lo = ...
    if jit then jit.off() end
    local P = { drawRect = function() end, drawTextureScaled = function() end }
    local T = ZeD.T
    fig:drawChart(P, Lo)
    local function grew(extra)
        collectgarbage("collect"); collectgarbage("stop")
        local before = collectgarbage("count")
        for i = 1, 500 do
            fig:drawChart(P, Lo)
            if extra then ZeD.colorBlend(T.iconWhite, T.accent, 0.45) end
        end
        local kb = collectgarbage("count") - before
        collectgarbage("restart")
        return kb
    end
    return grew(false), grew(true)''', fig, Lo)
check("drawChart makes no table a frame", blend > 10 and made < blend / 20, f"{made:.2f} KB over 500 frames ({blend:.2f} "
      "with a colorBlend each)")

# ---- the measure stops at the character's height (Nov 23 2026: "move the skelly up the measure will stop at their
# height")
for sex in ("m", "f"):
    top = SK.head_top(sex)
    feet_in = round((SK.FLOOR - top) / SK.PX_FT * 12)
    check(f"{sex}: the figure stands {feet_in // 12}'{feet_in % 12}\" on the ruler's scale",
          feet_in == (69 if sex == "m" else 68), feet_in)
    check(f"{sex}: the head's top {top} rows under the canvas's top (his 4, hers 8, as the mock passed)",
          top == (4 if sex == "m" else 8), top)
    ru = SK.ruler(sex)
    rail = np.nonzero(ru[:, SK.RAIL_X])[0]
    check(f"{sex}: the rail runs from the floor up to the top of the head and stops",
          rail.min() == top and rail.max() == SK.FLOOR and len(rail) == SK.FLOOR - top + 1,
          (rail.min(), rail.max(), len(rail)))
    ticks = [int(y) for y in np.nonzero(ru[:, SK.RAIL_X + 1])[0]]
    check(f"{sex}: the ruler's ticks are the floor and the chart's lines, all under the head",
          ticks == sorted([SK.FLOOR] + DC.ROWS) and min(ticks) > top, (ticks, top))
    for light in (False, True):
        bg = np.asarray(SK.background(sex, light))[..., 3]
        check(f"{sex} {'light' if light else 'dark'}: nothing of the ruler or the body above the head's top",
              int(bg[:top].max(initial=0)) == 0 and int(bg[top].max()) > 0, int(bg[:top].max(initial=0)))
check("the lines run half a foot up to 5 1/2 ft, each foot stronger, the next half foot over both heads",
      DC.ROWS == [DC.row_ft(k / 2) for k in range(1, 12)] and DC.ALPHAS == [DC.FOOT_A if k % 2 == 0 else DC.HALF_A
                                                                             for k in range(1, 12)]
      and all(DC.row_ft(6) <= SK.head_top(sex) < DC.ROWS[-1] for sex in ("m", "f")), (DC.ROWS, DC.ALPHAS))
# the canvas is the figure's own size in the Lua and in the tokens (ZeD.Spacing.figureW / H: the frames and the tabs)
cw = re.search(r"\nlocal CANVAS_W\s*=\s*(\d+)", FIG)
ch = re.search(r"\nlocal CANVAS_H\s*=\s*(\d+)", FIG)
check(f"ZeD_BodyFigure.lua's canvas is {SK.FW} x {SK.FH}", cw and ch and (int(cw.group(1)), int(ch.group(1))) == (
    SK.FW, SK.FH), (cw and cw.group(1), ch and ch.group(1)))
TOKENS = os.path.join(CLIENT, "..", "..", "shared", "ZeD", "Tokens.lua")
if os.path.exists(TOKENS):
    tok = open(TOKENS, "rb").read().decode("utf-8")
    tw = re.search(r"\n\s*figureW\s*=\s*(\d+)\s*,", tok)
    th_ = re.search(r"\n\s*figureH\s*=\s*(\d+)\s*,", tok)
    check(f"Tokens.lua's figure is {SK.FW} x {SK.FH}", tw and th_ and (int(tw.group(1)), int(th_.group(1))) == (
        SK.FW, SK.FH), (tw and tw.group(1), th_ and th_.group(1)))
else:
    print("  (no Tokens.lua at " + os.path.normpath(TOKENS) + ": its figureW and figureH were not checked)")

# ---- the figure's CHART table is d_chart.py's
m = re.search(r"\nlocal CHART = \{.*?\n\}\n", FIG, re.S)
check("ZeD_BodyFigure.lua holds the CHART table d_chart.py makes", m is not None and m.group(0)[1:] == DC.lua_table(),
      "regenerate: d_chart.py writes _chart.lua.txt")

# ---- the four places the figure sits: the frame, then the chart, then the controller's mark and the figure


def order(text, *needles):
    """each needle found, in this order, after the one before"""
    at = 0
    for nd in needles:
        i = text.find(nd, at)
        if i < 0:
            return False, nd
        at = i + len(nd)
    return True, None


health, thermal = src("HealthTab.lua"), src("ThermalTab.lua")
equip, medic = src("EquipmentTab.lua"), src("ObjectCardMedic.lua")
fn = cut(health, "function ZeD.HealthTab._drawBodyFigure(", "\nend\n")
ok, miss = order(fn, "fig:setSex(", "if frame then fig:drawChart(panel, frame) end", "ZeD.Focus.mark(", "fig:drawAt(")
check("Health: the chart after the sex, before the controller's mark and the figure", ok, miss)
ok, miss = order(health, "M.drawFigureFrame(panel, layout)", "ZeD.HealthTab._drawBodyFigure(panel, win, data,",
                 "layout.figX, layout.figY, layout.figW, layout.figH, layout)")
check("Health: the frame, then the figure given its frame", ok, miss)
fn = cut(thermal, "function ZeD.ThermalTab._drawBodyFigure(", "\nend\n")
ok, miss = order(fn, "fig:setSex(", "if frame then fig:drawChart(panel, frame) end", "ZeD.Focus.mark(", "fig:drawAt(")
check("Thermal: the chart after the sex, before the controller's mark and the figure", ok, miss)
ok, miss = order(thermal, "M.drawFigureFrame(panel, layout)", "ZeD.ThermalTab._drawBodyFigure(panel, win, data,",
                 "layout.figX, layout.figY, layout.figW, layout.figH, layout)")
check("Thermal: the frame, then the figure given its frame", ok, miss)
fn = cut(equip, "local function _drawDefenseFigure(", "\nend\n")
ok, miss = order(fn, "fig:setSex(", "if frame then fig:drawChart(panel, frame) end", "fig:drawAt(")
check("Equipment: the chart after the sex, before the figure", ok, miss)
ok, miss = order(equip, "M.drawFigureFrame(panel, layout)",
                 "_drawDefenseFigure(panel, win, protData, layout.figX, layout.figY, layout.figW, layout.figH, layout)")
check("Equipment: the frame, then the figure given its frame", ok, miss)
fn = cut(medic, "function def.body(", "\nend\n")
ok, miss = order(fn, "fig:setSex(", "ZeD.Molecules.drawFigureFrame(card, L)", "fig:drawChart(card, L)",
                 "ZeD.Focus.mark(", "fig:drawAt(card, L.figX, L.figY, L.figW, L.figH)")
check("medical card: the frame and the chart, then the controller's marks and the figure", ok, miss)

# ---- the preview: the chart as the game draws it
if PREVIEW:
    import wounds_sheet as WS
    font = WS.font(17)
    picks = [("4K (1.75)", "Health", "dark", "m", "Health tab, 4K, Dark"),
             ("4K (1.75)", "Health", "dark", "f", "her"),
             ("4K (1.75)", "Health", "light", "m", "Light"),
             ("4K (1.75)", "Health", "light", "f", "her, Light"),
             ("4K (1.75)", "Health", "hicon", "m", "High Contrast, a yellow accent"),
             ("4K (1.75)", "medic 220 (stacked)", "dark", "f", "medical card, 220 drawer"),
             ("4K (1.75)", "medic 336", "dark", "m", "medical card, 336"),
             ("1080p (1.0)", "Health", "dark", "m", "Health tab, 1080p (1x)"),
             ("1280x800 (0.75)", "Health", "dark", "m", "Steam Deck (1x)")]
    tiles = []
    for sname, lname, base, sex, label in picks:
        cv, Ld, _, _ = SEEN[(sname, lname, base, sex)]
        im = Image.fromarray(cv.u8().astype(np.uint8))
        x0, y0 = max(0, Ld["frameX"] - 6), max(0, Ld["frameY"] - 6)
        im = im.crop((x0, y0, min(im.width, Ld["frameX"] + Ld["frameW"] + 6), min(im.height, Ld["frameY"] + Ld["frameH"] + 6)))
        tiles.append((label, im))
    pad, top = 16, 30
    rows = [tiles[:5], tiles[5:]]
    width = max(sum(t.width + pad for _, t in r) + pad for r in rows)
    heights = [max(t.height for _, t in r) + top + pad for r in rows]
    sheet = Image.new("RGB", (width, sum(heights) + pad), (40, 38, 34))
    d = ImageDraw.Draw(sheet)
    y = pad
    for r, hh in zip(rows, heights):
        x = pad
        for label, t in r:
            d.text((x, y), label, fill=(220, 218, 214), font=font)
            sheet.paste(t, (x, y + top - 4))
            x += t.width + pad
        y += hh
    sheet.save(PREVIEW)
    print("preview:", PREVIEW, sheet.size)

print(f"test_chart: {COUNT[0]} checks, {len(FAILS)} failed")
sys.exit(1 if FAILS else 0)
