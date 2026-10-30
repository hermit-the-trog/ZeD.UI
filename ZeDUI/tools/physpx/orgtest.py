"""The organisms on the machine plates, run outside the game: the real Lua (the plate template, PhysPx, and each
organism) under LuaJIT with the game's objects mocked the way vanilla behaves (an IsoStove that toggles, counts its
timer and turns itself off; a generator; a propane barbecue; a car radio's device data; a vehicle's lightbar).
Every draw call is painted (text in a stand-in face) so each organism can be looked at, and every vanilla call it makes
is logged so the controls can be checked. Shared by the tests in test_*.py.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
try:
    import lupa.luajit21 as lj      # noqa: E402
except ImportError:                     # no lupa here: luashim.py runs the same through a LuaJIT executable
    import luashim as lj                # noqa: E402

# In the repo (ZeDUI/tools/physpx) the organisms, the generated data and the textures are the mod's own; in a
# scratch copy they are the working copies (lua/) and the last export (out/mod/ZeD-UI).
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
if os.path.isdir(os.path.join(REPO, "42", "media", "lua", "client", "ZeD")) and not os.path.isdir(os.path.join(HERE, "lua")):
    ROOT = REPO
    GEN = SRC = STAGED = os.path.join(REPO, "42", "media", "lua", "client", "ZeD")
else:
    ROOT = os.path.join(HERE, "out", "mod", "ZeD-UI")
    GEN = os.path.join(ROOT, "42", "media", "lua", "client", "ZeD")
    SRC = os.path.join(HERE, "lua")
    STAGED = "/mnt/user-data/uploads/ZeD-UI/42/media/lua/client/ZeD"
# the translation helper (ZeD.tr, ZeD.trDefaults...) comes first: the template calls ZeD.trDefaults as it loads
TR_LUA = next((p for p in (os.path.join(ROOT, "42", "media", "lua", "shared", "ZeD", "Tr.lua"), os.path.join(HERE, "lua", "Tr.lua"))
               if os.path.exists(p)), os.path.join(ROOT, "42", "media", "lua", "shared", "ZeD", "Tr.lua"))
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_PX = {"F1": 11, "F2": 13, "F3": 11, "F4": 15, "F5": 9, "Handwritten": 18}

PRELUDE = r'''
-- Kahlua's strings are Java's (16-bit characters): string.char takes a code above 255 there, LuaJIT's does not, so
-- those go over as UTF-8 (the faces' accented and Cyrillic capitals in ZeD_PixelParts; platesame.py does the same)
local char0 = string.char
string.char = function(...)
    local n = select("#", ...)
    local big = false
    for i = 1, n do if select(i, ...) > 255 then big = true end end
    if not big then return char0(...) end
    local out = {}
    for i = 1, n do
        local c = select(i, ...)
        if c < 128 then out[#out + 1] = char0(c)
        elseif c < 2048 then out[#out + 1] = char0(192 + math.floor(c / 64), 128 + c % 64)
        else out[#out + 1] = char0(224 + math.floor(c / 4096), 128 + math.floor(c / 64) % 64, 128 + c % 64) end
    end
    return table.concat(out)
end
require = function() end
print = function(...) py_print(...) end
Texture = { getSharedTexture = function(path, flags) return { path = path, flags = flags } end }
getTexture = function(path) return { path = path } end
getTimestampMs = function() return py_now() end
getCore = function() return { isCelsius = function() return CELSIUS == true end, getScreenHeight = function() return 1080 end } end
getGameTime = function() return { getHour = function() return HOUR or 10 end, getMinutes = function() return MINUTE or 8 end } end
instanceof = function(o, cls) return type(o) == "table" and o._cls == cls end
getSoundManager = function() return { playUISound = function(_, name) py_log("sound", name) end } end
SandboxVars = {}
UIFont = { Handwritten = "Handwritten", Small = "F2", Medium = "F3", NewSmall = "F1" }
ZeD = {}
ZeD.Scale = { root = function() return SCALE or 1 end, px = function(v) return math.floor(v * (SCALE or 1) + 0.5) end }
local function col(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end
ZeD.T = {
    px = function(v) return math.floor(v * (SCALE or 1) + 0.5) end,
    sp = { catHdrH = 22, scrollbarW = 8, sm = 4 },
    fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", fontF4 = "F4", fontF5 = "F5",
    text = col(0.90, 0.90, 0.88), textDim = col(0.55, 0.55, 0.53), textSec = col(0.7, 0.7, 0.68),
    accent = col(0.95, 0.62, 0.20), warning = col(0.95, 0.70, 0.20), danger = col(0.90, 0.25, 0.20), positive = col(0.35, 0.80, 0.40),
    surf1 = col(0.12, 0.12, 0.13), surf2 = col(0.16, 0.16, 0.17), border = col(0.3, 0.3, 0.3), borderS = col(0.25, 0.25, 0.26),
    inputH = 22,
}
local CHW = { F1 = 7, F2 = 7, F3 = 7, F4 = 8, F5 = 5, Handwritten = 9 }
local FH = { F1 = 11, F2 = 13, F3 = 11, F4 = 15, F5 = 9, Handwritten = 18 }
ZeD.TM = { getFontHeight = function(self, f) return FH[f] or 12 end, MeasureStringX = function(self, f, s) return #tostring(s) * (CHW[f] or 7) end }
ZeD.Text = { realTM = function() return ZeD.TM end }
ZeD.Atoms = {
    drawTextRight = function(p, s, rx, y, f, c) p:drawText(s, rx - ZeD.TM:MeasureStringX(f, s), y, c.r, c.g, c.b, c.a or 1, f) end,
    drawDividerH = function(p, x, y, w) p:drawRect(x, y, w, 1, 1, 0.3, 0.3, 0.3) end,
    drawStatusDot = function(p, x, y, c, sz) p:drawRect(x, y, sz, sz, c.a or 1, c.r, c.g, c.b) end,
}
ZeD.Molecules = {
    drawSectionHeader = function(p, x, y, w, label, count) p:drawRect(x, y, w, 20, 1, 0.18, 0.18, 0.19); p:drawText(label .. "  " .. tostring(count), x + 6, y + 4, 0.8, 0.8, 0.8, 1, "F1") end,
    drawGlyphPrompts = function(p, x, y, h, items) p:drawText("[prompts]", x, y, 0.8, 0.8, 0.8, 1, "F1") end,
}
ZeD.CraftingCore = { truncText = function(s) return s end }

-- a panel that paints through Python
function make_panel(w, h)
    local p = { width = w, height = h, x = 0, y = 0 }
    function p:drawRect(x, y, w, h, a, r, g, b) py_rect(x, y, w, h, a, r, g, b) end
    function p:drawRectBorder(x, y, w, h, a, r, g, b) py_rect(x, y, w, 1, a, r, g, b); py_rect(x, y + h - 1, w, 1, a, r, g, b); py_rect(x, y, 1, h, a, r, g, b); py_rect(x + w - 1, y, 1, h, a, r, g, b) end
    function p:drawText(s, x, y, r, g, b, a, f) py_text(tostring(s), x, y, r, g, b, a, f or "F2", 1) end
    function p:drawTextZoomed(s, x, y, z, r, g, b, a, f) py_text(tostring(s), x, y, r, g, b, a, f or "F2", z) end
    function p:drawTextureScaled(t, x, y, w, h, a) py_tex(t.path, x, y, w, h, a) end
    function p:drawTextureScaledAspect(t, x, y, w, h, a) py_tex(t.path, x, y, w, h, a) end
    function p:setStencilRect(x, y, w, h) py_clip(x, y, w, h) end
    function p:clearStencilRect() py_clip(nil) end
    function p:getMouseX() return MOUSE_X or -1 end
    function p:getMouseY() return MOUSE_Y or -1 end
    function p:getWidth() return self.width end
    function p:getHeight() return self.height end
    return p
end

function make_scroll()
    local s = { visible = false, x = 0, y = 0, height = 0, scrollPos = 0 }
    function s:setBarSize(v) self.bar = v end
    function s:setScrollPos(v) self.scrollPos = v end
    function s:draw(p) p:drawRect(self.x, self.y, 8, self.height, 1, 0.3, 0.3, 0.3) end
    function s:handleMouseWheel(d) self.scrollPos = math.max(0, math.min(1, self.scrollPos + d * 0.1)) end
    return s
end
'''

# vanilla's IsoStove as far as the appliance view reaches it: the server's setOvenParamsAndToggle sets the timer and
# the heat and toggles; while it runs, isRunningFor counts seconds; when the timer is up it turns itself off.
STOVE = r'''
WORLD_S = 0
STOVES = {}
function make_stove(spriteName, micro, x, y)
    local o = { _cls = "IsoStove", temp = 0, timer = 0, active = false, startT = nil, powered = true, x = x or 10, y = y or 20, z = 0, syncs = 0 }
    function o:getMaxTemperature() return self.temp end
    function o:setMaxTemperature(v) self.temp = v end
    function o:getTimer() return self.timer end
    function o:setTimer(v) self.timer = v end
    function o:isRunningFor() if self.active and self.startT then return WORLD_S - self.startT end; return 0 end
    function o:Activated() return self.active end
    function o:Toggle() self.active = not self.active; self.startT = self.active and WORLD_S or nil end
    function o:sync() self.syncs = self.syncs + 1 end
    function o:syncSpriteGridObjects() end
    function o:isMicrowave() return micro end
    function o:getContainer() return { isPowered = function() return o.powered end, getItems = function() return { size = function() return 0 end } end } end
    function o:getSprite() return { getName = function() return spriteName end } end
    function o:getX() return self.x end
    function o:getY() return self.y end
    function o:getZ() return self.z end
    STOVES[#STOVES + 1] = o
    return o
end
-- the world's clock: seconds pass; a timer that is up turns its stove off
function world_tick(sec)
    WORLD_S = WORLD_S + sec
    for _, o in ipairs(STOVES) do
        if o.active and o.timer > 0 and o:isRunningFor() >= o.timer then o.active = false; o.startT = nil; o.timer = 0 end
    end
end
sendClientCommand = function(player, module, command, args)
    py_log("command", module, command)
    if module == "stove" and command == "setOvenParamsAndToggle" then
        for _, o in ipairs(STOVES) do
            if o.x == args.x and o.y == args.y and o.z == args.z then
                py_log("  args", "timer", args.timer, "maxTemperature", args.maxTemperature)
                o:setTimer(args.timer); o:setMaxTemperature(args.maxTemperature); o:Toggle()
            end
        end
    elseif CLIENT_COMMAND then CLIENT_COMMAND(player, module, command, args) end
end
'''


class Paint:
    """paints the calls: rects (blended), textures (the exported PNGs), text (a stand-in face), the stencil"""
    def __init__(s, w, h, bg=(24, 24, 26)):
        s.img = Image.new("RGBA", (w, h), bg + (255,))
        s.a = np.array(s.img).astype(np.float32)
        s.clip = None; s.cache = {}; s.missing = set(); s.texts = []; s.calls = 0
        s.fonts = {}

    def _clip(s, x0, y0, x1, y1):
        if s.clip:
            cx, cy, cw, ch = s.clip
            x0, y0, x1, y1 = max(x0, cx), max(y0, cy), min(x1, cx + cw), min(y1, cy + ch)
        H, W = s.a.shape[:2]
        return max(0, int(x0)), max(0, int(y0)), min(W, int(x1)), min(H, int(y1))

    def rect(s, x, y, w, h, a, r, g, b):
        s.calls += 1
        x0, y0, x1, y1 = s._clip(x, y, x + w, y + h)
        if x1 <= x0 or y1 <= y0: return
        c = np.array([r * 255, g * 255, b * 255], np.float32)
        reg = s.a[y0:y1, x0:x1, :3]
        s.a[y0:y1, x0:x1, :3] = reg * (1 - a) + c * a

    def tex(s, path, x, y, w, h, a):
        s.calls += 1
        if path not in s.cache:
            fp = os.path.join(ROOT, "42", path)
            if not os.path.exists(fp): fp = os.path.join("/mnt/user-data/uploads/ZeD-UI/42", path)
            s.cache[path] = Image.open(fp).convert("RGBA") if os.path.exists(fp) else None
            if s.cache[path] is None: s.missing.add(path)
        im = s.cache[path]
        if im is None: return
        src = np.array(im.resize((max(1, int(w)), max(1, int(h))), Image.NEAREST)).astype(np.float32)
        x, y = int(x), int(y)
        x0, y0, x1, y1 = s._clip(x, y, x + src.shape[1], y + src.shape[0])
        if x1 <= x0 or y1 <= y0: return
        sub = src[y0 - y:y1 - y, x0 - x:x1 - x]
        al = sub[..., 3:4] / 255.0 * a
        s.a[y0:y1, x0:x1, :3] = s.a[y0:y1, x0:x1, :3] * (1 - al) + sub[..., :3] * al

    def text(s, t, x, y, r, g, b, a, f, z):
        s.calls += 1
        s.texts.append((t, int(x), int(y), f))
        px = max(6, int(FONT_PX.get(f, 12) * (z if f == "Handwritten" else 1) * (1 if f != "Handwritten" else 1)))
        if f == "Handwritten": px = max(6, int(18 * z))
        fnt = s.fonts.get(px) or ImageFont.truetype(FONT, px)
        s.fonts[px] = fnt
        im = Image.fromarray(np.clip(s.a, 0, 255).astype(np.uint8), "RGBA")
        layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).text((int(x), int(y)), t, font=fnt, fill=(int(r * 255), int(g * 255), int(b * 255), int(a * 255)))
        if s.clip:
            cx, cy, cw, ch = [int(v) for v in s.clip]
            mask = Image.new("L", im.size, 0); ImageDraw.Draw(mask).rectangle([cx, cy, cx + cw - 1, cy + ch - 1], fill=255)
            layer.putalpha(Image.fromarray(np.minimum(np.array(layer)[..., 3], np.array(mask))))
        im.alpha_composite(layer)
        s.a = np.array(im).astype(np.float32)

    def set_clip(s, x=None, y=None, w=None, h=None):
        s.clip = None if x is None else (x, y, w, h)

    def image(s): return Image.fromarray(np.clip(s.a, 0, 255).astype(np.uint8), "RGBA")


class Org:
    """one Lua world: the mocks, the shared files, the organism's own files"""
    def __init__(s, files, w=480, h=640, scale=1.0):
        s.L = lj.LuaRuntime(unpack_returned_tuples=True, encoding="latin-1")    # Kahlua strings are Java strings: char 183 is the dot
        s.g = s.L.globals()
        s.clock = {"t": 1_000_000}
        s.log = []
        s.paint = Paint(w, h)
        g = s.g
        g.py_now = lambda: s.clock["t"]
        g.py_print = lambda *a: None
        g.py_log = lambda *a: s.log.append(" ".join(str(x) for x in a))
        g.py_rect = lambda *a: s.paint.rect(*a)
        g.py_tex = lambda *a: s.paint.tex(*a)
        g.py_text = lambda *a: s.paint.text(*a)
        g.py_clip = lambda *a: s.paint.set_clip(*a) if a and a[0] is not None else s.paint.set_clip()
        g.SCALE = scale
        s.L.execute(PRELUDE)
        s.L.execute(STOVE)
        for f in [TR_LUA, os.path.join(GEN, "PixelFonts.lua"), os.path.join(SRC, "ZeD_PixelParts.lua"), os.path.join(SRC, "ZeD_RadioOps.lua"),
                  os.path.join(SRC, "ZeD_Plate.lua"), os.path.join(GEN, "PhysPx.lua")] + files:
            s.L.execute(open(f, "rb").read())

    def new_paint(s, w, h):
        s.paint = Paint(w, h)

    def ms(s, dt):
        s.clock["t"] += dt

    def lua(s, code): return s.L.execute(code)
