"""The body figure outside the game: the real ZeD_BodyFigure.lua draws the reworked skeleton (d_skeleton.py) for both
sexes on both theme bases, at 1x, 2x and odd panel sizes; its drawing must equal the reference (the tinted grid, the
skeleton, the parts dim or tinted) pixel for pixel, at a whole multiple when the panel allows; and each part must be the
one hit where its bones are. usage: python test_body.py [ZeD_BodyFigure.lua]"""
import os, sys
import numpy as np
from PIL import Image
import lupa.luajit21 as lj
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); os.chdir(HERE)
import d_skeleton as SK          # noqa: E402
ROOT = os.path.join(HERE, "out", "mod", "ZeD-UI")
SK.export(ROOT)
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "body", "ZeD_BodyFigure.lua")
FAILS = []
def check(what, ok, detail=""):
    print(("  ok   " if ok else "  FAIL ") + what + ("" if ok else "  " + str(detail)))
    if not ok: FAILS.append(what)

ICON_WHITE = (0.94, 0.94, 0.92); ACCENT = (0.36, 0.66, 0.86); DIM = (0.55, 0.55, 0.55)
TINT = tuple(ICON_WHITE[i] + (ACCENT[i] - ICON_WHITE[i]) * 0.45 for i in range(3))
CACHE = {}
def tex(path):
    if path not in CACHE: CACHE[path] = Image.open(os.path.join(ROOT, "42", path)).convert("RGBA")
    return CACHE[path]

class Canvas:
    def __init__(s, w, h): s.a = np.zeros((h, w, 4), np.float32); s.a[..., 3] = 1; s.a[..., :3] = 0.12; s.calls = []
    def draw(s, path, x, y, w, h, alpha, r, g, b):
        s.calls.append(path)
        im = np.array(tex(path).resize((int(w), int(h)), Image.NEAREST)).astype(np.float32) / 255
        x, y = int(x), int(y)
        H_, W_ = s.a.shape[:2]
        x0, y0, x1, y1 = max(0, x), max(0, y), min(W_, x + im.shape[1]), min(H_, y + im.shape[0])
        sub = im[y0 - y:y1 - y, x0 - x:x1 - x]
        col = sub[..., :3] * np.array([r, g, b], np.float32)
        al = sub[..., 3:4] * alpha
        s.a[y0:y1, x0:x1, :3] = s.a[y0:y1, x0:x1, :3] * (1 - al) + col * al

def lua_for(sex, light):
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute('''require = function() end
        Texture = { getSharedTexture = function(path, f) return { path = path, f = f } end }
        getTexture = function(path) return { path = path, f = 0 } end
        ISPanel = { render = function() end, onMouseMove = function() end, onMouseMoveOutside = function() end,
                    onMouseDown = function() end }
        function ISPanel:derive(name) local c = {}; c.__index = c; setmetatable(c, { __index = ISPanel }); return c end
        function ISPanel:new(x, y, w, h) return { x = x, y = y, w = w, h = h } end
        ZeD = { T = {} }
        function ZeD.colorBlend(a, b, t) return { r = a.r + (b.r - a.r) * t, g = a.g + (b.g - a.g) * t, b = a.b + (b.b - a.b) * t } end''')
    L.execute(f"ZeD.T.iconWhite = {{ r = {ICON_WHITE[0]}, g = {ICON_WHITE[1]}, b = {ICON_WHITE[2]} }}; "
              f"ZeD.T.accent = {{ r = {ACCENT[0]}, g = {ACCENT[1]}, b = {ACCENT[2]} }}; "
              f"ZeD.T.textDim = {{ r = {DIM[0]}, g = {DIM[1]}, b = {DIM[2]} }}; "
              f"ZeD.currentBase = '{'light' if light else 'dark'}'")
    L.execute(open(SRC, "rb").read())
    g = L.globals()
    fig = g.ZeD_BodyFigure.new(g.ZeD_BodyFigure, 0, 0, 100, 100, 0)
    fig.setSex(fig, sex == "f")
    return L, g, fig

def reference(sex, light, s, ox, oy, pw, ph, colors, hover=None):
    c = Canvas(pw + 2 * ox, ph + 2 * oy)
    w, h = int(220 * s), int(260 * s)
    x, y = ox + (pw - w) // 2, oy + (ph - h) // 2
    c.draw(f"media/textures/ZeD/body/fig-bg-{sex}-{'light' if light else 'dark'}.png", x, y, w, h, 1.0, *TINT)
    c.draw(f"media/textures/ZeD/body/{sex}-skeleton.png", x, y, w, h, 1, 1, 1, 1)
    for p in SK.PARTS:
        disp = DISPLAY[p]
        if disp in colors:
            r, g_, b, a = colors[disp]
            c.draw(f"media/textures/ZeD/body/{sex}-{p}.png", x, y, w, h, a, r, g_, b)
        else:
            c.draw(f"media/textures/ZeD/body/{sex}-{p}.png", x, y, w, h, 0.10, *DIM)
    return c

DISPLAY = {"head": "Head", "neck": "Neck", "up-torso": "Upper Torso", "low-torso": "Lower Torso", "groin": "Groin",
           "bicep-l": "Left Upper Arm", "bicep-r": "Right Upper Arm", "wrist-l": "Left Forearm", "wrist-r": "Right Forearm",
           "hand-l": "Left Hand", "hand-r": "Right Hand", "thigh-l": "Left Upper Leg", "thigh-r": "Right Upper Leg",
           "ankle-l": "Left Lower Leg", "ankle-r": "Right Lower Leg", "foot-l": "Left Foot", "foot-r": "Right Foot"}
COLORS = {"Left Forearm": (0.9, 0.27, 0.2, 0.9), "Head": (0.95, 0.66, 0.24, 0.9)}

for sex in ("m", "f"):
    sk_img, _, owner = SK.render(sex)
    # every bone inside the body: no skeleton pixel outside the traced outline (Oct 17 2026: the hips poked out)
    outside = int(((np.array(sk_img)[..., 3] > 0) & ~SK.silhouette(sex)).sum())
    check(f"{sex}: no bone outside the body's outline", outside == 0, outside)
    # the head, neck, shoulders and chest evenly inside it (Oct 19 2026): flesh shows between the bones' dark rim and
    # the outline's line, so no drawn skeleton pixel there sits on that line or the pixel just inside it
    from scipy import ndimage as _ndi
    _sil = SK.silhouette(sex)
    _d = _ndi.distance_transform_edt(_sil)
    _drawn = np.array(sk_img)[..., 3] > 0
    _top = np.isin(owner, [SK.PID[p] for p in ("head", "neck", "up-torso")])
    _near = int((_drawn & _top & (_d < 2.0)).sum())
    check(f"{sex}: head, shoulders and chest leave the outline showing", _near == 0, _near)
    for light in (False, True):
        for (pw, ph, want_s) in ((220, 260, 1), (440, 520, 2), (300, 300, 1), (500, 700, 2), (165, 195, 0.75)):
            L, g, fig = lua_for(sex, light)
            for k, (r, g_, b, a) in COLORS.items(): fig.setPartColor(fig, k, r, g_, b, a)
            ox, oy = 7, 5
            cv = Canvas(pw + 2 * ox, ph + 2 * oy)
            P = L.table()
            P.drawTextureScaled = lambda self, t, x, y, w, h, a, r, gg, b: cv.draw(t.path, x, y, w, h, a, r, gg, b)
            P.drawTextureScaledUniform = lambda self, t, x, y, s_, a, r, gg, b: cv.draw(t.path, x, y, tex(t.path).width * s_,
                                                                                        tex(t.path).height * s_, a, r, gg, b)
            P.drawTextureScaledAspect = P.drawTextureScaled
            fig.drawAt(fig, P, ox, oy, pw, ph)
            name = f"{sex} {'light' if light else 'dark'} {pw}x{ph}"
            s = float(fig._drawAtS)
            check(f"{name}: scale {want_s}", abs(s - want_s) < 1e-6, s)
            ref = reference(sex, light, s, ox, oy, pw, ph, COLORS)
            same = np.abs(cv.a - ref.a).max() < 1e-5
            check(f"{name}: picture equals the reference", same, np.abs(cv.a - ref.a).max())
        # every part is hit where its bones are (at 2x): at least 85% of its pixels hit it
        L, g, fig = lua_for(sex, light)
        P = L.table(); P.drawTextureScaled = lambda *a: None; P.drawTextureScaledUniform = lambda *a: None
        fig.drawAt(fig, P, 0, 0, 440, 520)
        for p in SK.PARTS:
            ys, xs = np.nonzero(owner == SK.PID[p])
            hits = [fig.hitTestAt(fig, int(x) * 2 + 1, int(y) * 2 + 1) for x, y in zip(xs[::3], ys[::3])]
            frac = sum(1 for h in hits if h == DISPLAY[p]) / max(1, len(hits))
            check(f"{sex} {'light' if light else 'dark'}: {p} hit on {frac:.0%} of its bones", frac >= 0.85, frac)
    # every texture the figure asks for exists, at nearest filtering
    L, g, fig = lua_for(sex, False)
    asked = []
    L.globals().Texture.getSharedTexture = lambda path, f: (asked.append((path, f)), L.table_from({"path": path}))[1]
    fig.loadTextures(fig); fig._background(fig)
    check(f"{sex}: {len(asked)} textures, all present", all(os.path.exists(os.path.join(ROOT, "42", p)) for p, _ in asked), asked)
    check(f"{sex}: all nearest-filtered", all(f == 3 for _, f in asked))
print(f"{len(FAILS)} failed", FAILS)
sys.exit(1 if FAILS else 0)
