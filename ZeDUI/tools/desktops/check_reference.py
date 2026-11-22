"""Design's check of _desktops.lua.txt against desktops.py: the toned colors, and every desktop as the reference
draws it (rasterized from its draw calls with the staged textures) against the script's own tube fill."""
import importlib.util, sys, numpy as np
from PIL import Image
from lupa import LuaRuntime

STAGE = sys.argv[1]          # the stage folder (holds _desktops.lua.txt and 42/media/...)
SCRIPT = sys.argv[2]         # desktops.py
spec = importlib.util.spec_from_file_location('d', SCRIPT); d = importlib.util.module_from_spec(spec); spec.loader.exec_module(d)

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute("""
ZeD = { T = { scale = 1, accentKey = "teal" }, AccentColors = {
  teal = { dark = { accent = { r = 0x47/255, g = 0xA1/255, b = 0x8C/255 } } },
  orange = { dark = { accent = { r = 0xD4/255, g = 0x92/255, b = 0x2A/255 } } } } }
HC = { r = 0.98, g = 0.56, b = 0.11 }
local ci = { getR = function() return HC.r end, getG = function() return HC.g end, getB = function() return HC.b end }
function getCore() return { getObjectHighlitedColor = function() return ci end } end
Texture = { getSharedTexture = function(path, flags) return { path = path, smooth = false } end }
function getTexture(path) return { path = path, smooth = true } end
CALLS = {}
P = {
  drawRect = function(self, x, y, w, h, a, r, g, b) CALLS[#CALLS + 1] = { "rect", x, y, w, h, a, r, g, b } end,
  drawTextureScaled = function(self, t, x, y, w, h, a) CALLS[#CALLS + 1] = { "tex", t.path, x, y, w, h, a } end,
  setStencilRect = function(self, x, y, w, h) CALLS[#CALLS + 1] = { "stencil", x, y, w, h } end,
  clearStencilRect = function(self) CALLS[#CALLS + 1] = { "clear" } end,
}
""")
D = lua.execute(open(f"{STAGE}/_desktops.lua.txt").read())
G = lua.globals()

# 1. the toned colors
rng = np.random.default_rng(7)
cols = [np.array(c, float) for c in ([0.98, 0.56, 0.11], [1, 1, 1], [0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1],
                                     [1, 1, 0], [0, 1, 1], [1, 0, 1], [0.5, 0.5, 0.5])] + list(rng.random((500, 3)))
worst = 0.0
for c in cols:
    lr = np.array(D.tone(*map(float, c))) * 255
    pr = d.tone(c * 255).astype(np.float64)
    worst = max(worst, float(np.abs(lr - pr).max()))
print(f"tone: {len(cols)} colors, largest difference {worst:.6f} of 255")

# 2. every desktop, drawn by the reference and rasterized, against the script's tube
texcache = {}
def tex(path):
    if path not in texcache:
        texcache[path] = np.asarray(Image.open(f"{STAGE}/42/{path}").convert("RGBA")).astype(np.float64)
    return texcache[path]

def raster(calls, W, H):
    out = np.zeros((H, W, 3))
    stencil = (0, 0, W, H)
    for c in calls:
        kind = c[1]
        if kind == "stencil":
            stencil = tuple(int(v) for v in (c[2], c[3], c[4], c[5]))
        elif kind == "clear":
            stencil = (0, 0, W, H)
        elif kind == "rect":
            x, y, w, h, a, r, g, b = (float(c[i]) for i in range(2, 10))
            out[int(y):int(y + h), int(x):int(x + w)] = np.array([r, g, b]) * 255
        elif kind == "tex":
            t = tex(c[2]); x, y, w, h = (int(c[i]) for i in range(3, 7))
            th, tw = t.shape[:2]
            ys = (np.arange(h) * th // h); xs = (np.arange(w) * tw // w)      # nearest
            img = t[ys][:, xs]
            sx, sy, sw, sh = stencil
            x0, y0, x1, y1 = max(x, sx, 0), max(y, sy, 0), min(x + w, sx + sw, W), min(y + h, sy + sh, H)
            if x1 <= x0 or y1 <= y0: continue
            part = img[y0 - y:y1 - y, x0 - x:x1 - x]
            a = part[..., 3:4] / 255
            out[y0:y1, x0:x1] = out[y0:y1, x0:x1] * (1 - a) + part[..., :3] * a
    return np.round(out)

ids = [k for k, v in D.OPT.items() if v.kind != "game"]
fails = 0
TOT = []
for (W, H, scale, k) in ((960, 720, 1.0, 1), (1920, 1440, 1.75, 2)):
    G.ZeD.T.scale = scale
    for hc in ((0.98, 0.56, 0.11), (0.25, 0.80, 0.25)):
        G.HC.r, G.HC.g, G.HC.b = hc
        for oid in ids:
            lua.execute("CALLS = {}")
            D.draw(G.P, oid, 0, 0, W, H)
            calls = [list(G.CALLS[i].values()) for i in range(1, len(G.CALLS) + 1)]
            calls = [[None] + c for c in calls]
            got = raster(calls, W, H)
            if oid in d.PICTURES:
                p = d.tile(oid); exp = np.round(np.repeat(np.repeat(p, k, 0), k, 1))
            else:
                exp = np.round(d.fill_tube(d.tile(oid, d.rgb01(*hc)), W, H, k).astype(np.float64))
            diff = np.abs(got - exp)
            TOT.append((oid, W, k, float(diff.max()), int((diff > 0).any(2).sum())))
            if diff.max() > 1 or (diff > 0).mean() > 0.001:
                fails += 1
                print(f"  {oid} at {W}x{H} k={k} color {hc}: max {diff.max()}, {int((diff > 0).any(2).sum())} px differ")
        n = len(ids)
    print(f"draw: {W}x{H} at dot zoom {k}: {len(ids)} desktops x 2 colors checked")
print("draw failures:", fails)
print("pixels that differ at all, across every check:", sum(t[4] for t in TOT), "| largest difference:", max(t[3] for t in TOT))
