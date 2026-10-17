"""The pixel-art strap behind the hotbar, outside the game: the real ZeD_Belt.lua's _drawStrap under LuaJIT draws the
strap at several lengths at 1x and 2x; the picture must equal d_belt.assemble (the ends, the middle repeated and cut)
pixel for pixel. usage: python test_belt.py"""
import os, sys
import numpy as np
from PIL import Image
import lupa.luajit21 as lj
HERE = os.path.dirname(os.path.abspath(__file__))
PHYS = HERE
sys.path.insert(0, PHYS)
os.chdir(PHYS)
import d_belt as DB   # noqa: E402
DB.export(os.path.join(PHYS, "out", "mod", "ZeD-UI"))
ROOT = os.path.join(PHYS, "out", "mod", "ZeD-UI", "42")
# the belt's Lua: the mod's own in the repo, the working copy in a scratch folder
_REPO = os.path.join(HERE, "..", "..", "..", "42", "media", "lua", "client", "ZeD", "ZeD_Belt.lua")
SRC = _REPO if os.path.exists(_REPO) else os.path.join(HERE, "..", "belt", "ZeD_Belt.lua")
FAILS = []


class Paint:
    def __init__(s, w, h):
        s.a = np.zeros((h, w, 4), np.uint8); s.clip = None; s.cache = {}
    def tex(s, path, x, y, w, h):
        if path not in s.cache: s.cache[path] = Image.open(os.path.join(ROOT, path)).convert("RGBA")
        im = np.array(s.cache[path].resize((int(w), int(h)), Image.NEAREST))
        x, y = int(x), int(y)
        x0, y0, x1, y1 = x, y, x + im.shape[1], y + im.shape[0]
        if s.clip:
            cx, cy, cw, ch = s.clip
            x0, y0, x1, y1 = max(x0, cx), max(y0, cy), min(x1, cx + cw), min(y1, cy + ch)
        x0, y0 = max(0, x0), max(0, y0); x1, y1 = min(s.a.shape[1], x1), min(s.a.shape[0], y1)
        if x1 <= x0 or y1 <= y0: return
        sub = im[y0 - y:y1 - y, x0 - x:x1 - x]
        m = sub[..., 3] > 0
        s.a[y0:y1, x0:x1][m] = sub[m]


def run(w, k):
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute('''require = function() end
        Texture = { getSharedTexture = function(path, f) return { path = path } end }
        local function derive(base, name) local c = {}; c.__index = c; setmetatable(c, { __index = base }); c.derive = derive; return c end
        ZeD_Panel = { derive = derive }
        Events = setmetatable({}, { __index = function(t, k) local e = { Add = function() end, Remove = function() end }; rawset(t, k, e); return e end })
        ZeD = {}''')
    L.execute(f"ZeD.T = {{ scale = {k}, px = function(v) return math.floor(v * {k} + 0.5) end }}")
    L.execute(open(SRC, "rb").read())
    p = Paint(w + 20, 30 * k + 20)
    g = L.globals()
    g.py_tex = lambda path, x, y, ww, hh: p.tex(path, x, y, ww, hh)
    g.py_clip = lambda x, y, ww, hh: setattr(p, "clip", (int(x), int(y), int(ww), int(hh)))
    g.py_unclip = lambda: setattr(p, "clip", None)
    L.execute(f'''local o = setmetatable({{ _strap = {{ x = 10, y = 10, w = {w}, h = {30 * k} }} }}, {{ __index = ZeD_BeltHUD }})
        function o:drawTextureScaled(t, x, y, w, h) py_tex(t.path, x, y, w, h) end
        function o:setStencilRect(x, y, w, h) py_clip(x, y, w, h) end
        function o:clearStencilRect() py_unclip() end
        function o:drawRect() error("fell back to the plain strap") end
        o:_drawStrap()''')
    got = p.a[10:10 + 30 * k, 10:10 + w]
    want = np.array(DB.assemble(w, k))
    ok = np.array_equal(got, want)
    print(("  ok   " if ok else "  FAIL ") + f"strap {w} px at {k}x")
    if not ok: FAILS.append((w, k))


for k in (1, 2):
    for w in (60, 129, 252, 333):
        run(w * k, k)
print(f"{len(FAILS)} failed", FAILS)
sys.exit(1 if FAILS else 0)
