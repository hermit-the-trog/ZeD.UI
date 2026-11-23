"""The body figure's wounds outside the game (Design, Nov 22 2026): the real ZeD_BodyFigure.lua, with its WOUNDS
section, draws each part's wounds and their care over the figure. Its drawing must equal the reference (test_body's
picture, then the wounds as wounds_sheet.draw_wounds lays them) pixel for pixel, for both sexes, both theme bases, every
skin tone, at 1x, 2x and a panel smaller than 1x. ZeD_BodyFigure.woundsFrom must turn what the Health list read of a
part into the right wounds; the real HealthTab.lua beside it must hand the figure each part's wounds by the list's own
rules (the looker's First Aid, the cheat, a part another mod holds back) without reading any of the part twice;
setSkinTone and skinToneOf must hold to the game's five tones; and every picture the figure asks for must exist,
nearest-filtered. usage: python test_wounds.py [ZeD_BodyFigure.lua]   (HealthTab.lua beside it)"""
import os
import sys

import numpy as np
from PIL import Image
import lupa.luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.chdir(HERE)
import d_skeleton as SK          # noqa: E402
import d_wounds as WD            # noqa: E402
import wounds_sheet as WS        # noqa: E402

ROOT = os.path.join(HERE, "out", "mod", "ZeD-UI")
SK.export(ROOT)
PICS, PLACES = WD.export(ROOT)
LAYOUT = {sex: WS.layout_of(PICS[sex], PLACES[sex]) for sex in ("m", "f")}
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "..", "42", "media", "lua", "client", "ZeD",
                                                       "ZeD_BodyFigure.lua")      # the mod's own
FAILS = []


def check(what, ok, detail=""):
    print(("  ok   " if ok else "  FAIL ") + what + ("" if ok else "  " + str(detail)))
    if not ok:
        FAILS.append(what)


ICON_WHITE = (0.94, 0.94, 0.92)
ACCENT = (0.36, 0.66, 0.86)
DIM = (0.55, 0.55, 0.55)
TINT = tuple(ICON_WHITE[i] + (ACCENT[i] - ICON_WHITE[i]) * 0.45 for i in range(3))
CACHE = {}


def tex(path):
    if path not in CACHE:
        CACHE[path] = Image.open(os.path.join(ROOT, "42", path)).convert("RGBA")
    return CACHE[path]


class Canvas:
    def __init__(s, w, h):
        s.a = np.zeros((h, w, 4), np.float32)
        s.a[..., 3] = 1
        s.a[..., :3] = 0.12
        s.calls = []

    def draw(s, path, x, y, w, h, alpha, r, g, b):
        s.calls.append(path)
        im = np.array(tex(path).resize((int(w), int(h)), Image.NEAREST)).astype(np.float32) / 255
        x, y = int(x), int(y)
        H_, W_ = s.a.shape[:2]
        x0, y0, x1, y1 = max(0, x), max(0, y), min(W_, x + im.shape[1]), min(H_, y + im.shape[0])
        if x1 <= x0 or y1 <= y0:
            return
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


DISPLAY = {"head": "Head", "neck": "Neck", "up-torso": "Upper Torso", "low-torso": "Lower Torso", "groin": "Groin",
           "bicep-l": "Left Upper Arm", "bicep-r": "Right Upper Arm", "wrist-l": "Left Forearm", "wrist-r": "Right Forearm",
           "hand-l": "Left Hand", "hand-r": "Right Hand", "thigh-l": "Left Upper Leg", "thigh-r": "Right Upper Leg",
           "ankle-l": "Left Lower Leg", "ankle-r": "Right Lower Leg", "foot-l": "Left Foot", "foot-r": "Right Foot"}
COLORS = {"Left Forearm": (0.9, 0.27, 0.2, 0.9), "Head": (0.95, 0.66, 0.24, 0.9)}


def floor_mul(v, s):
    return int(np.floor(v * s + 1e-9))


def reference(sex, light, s, ox, oy, pw, ph, wounds, tone):
    """test_body's picture (background, skeleton, parts), then the wounds in their six passes"""
    c = Canvas(pw + 2 * ox, ph + 2 * oy)
    w, h = int(SK.FW * s), int(SK.FH * s)
    x, y = ox + (pw - w) // 2, oy + (ph - h) // 2
    c.draw(f"media/textures/ZeD/body/fig-bg-{sex}-{'light' if light else 'dark'}.png", x, y, w, h, 1.0, *TINT)
    c.draw(f"media/textures/ZeD/body/{sex}-skeleton.png", x, y, w, h, 1, 1, 1, 1)
    for p in SK.PARTS:
        disp = DISPLAY[p]
        path = f"media/textures/ZeD/body/{sex}-{p}.png"
        if disp in COLORS:
            r, g_, b, a = COLORS[disp]
            c.draw(path, x, y, w, h, a, r, g_, b)
        else:
            c.draw(path, x, y, w, h, 0.10, *DIM)
    tint = WD.skin_tints()[tone]
    lay = LAYOUT[sex]

    def at(name, px, py, t=(1, 1, 1)):
        path = "media/textures/ZeD/body/wounds/" + name
        im = tex(path)
        c.draw(path, x + floor_mul(px, s), y + floor_mul(py, s), im.width * s, im.height * s, 1, *t)
    for ps in range(1, 7):
        for p in SK.PARTS:
            wd = wounds.get(p)
            if not wd:
                continue
            g = lay[p]
            marks = wd.get("marks") or []
            n = min(len(marks), 2)
            slots = g["slots"][max(1, n) - 1]
            if ps == 1 and wd.get("fracture"):
                at(f"{sex}-{p}-fracture.png", *g["fracture"])
            elif ps == 2 and wd.get("bandage"):
                nm = "bandage-dirty" if wd["bandage"] == "dirty" else "bandage"
                at(f"{sex}-{p}-{nm}.png", *g[nm])
            elif ps == 3 and (n > 0 or wd.get("bleed")):
                nm = f"skin{max(1, n)}{'b' if wd.get('bleed') else ''}"
                at(f"{sex}-{p}-{nm}.png", *g[nm], t=tint)
            elif ps == 4 and wd.get("infected") and n > 0:
                cx, cy = slots[0]
                at(f"mark-{marks[0]}-infected.png", cx - WD.MARK_C, cy - WD.MARK_C)
            elif ps == 5:
                for i in range(n):
                    cx, cy = slots[i]
                    at(f"mark-{marks[i]}.png", cx - WD.MARK_C, cy - WD.MARK_C)
                if wd.get("bleed"):
                    cx, cy = slots[max(1, n) - 1]
                    at("mark-bleed.png", cx + WD.BLEED_DX - WD.MARK_C, cy + WD.BLEED_DY - WD.MARK_C)
            elif ps == 6 and wd.get("splint") and "splint" in g:
                at(f"{sex}-{p}-splint.png", *g["splint"])
    return c


def lua_wounds(L, w):
    """a Python wounds dict as the Lua table setPartWounds takes"""
    t = L.table()
    for k, v in w.items():
        t[k] = L.table(*v) if isinstance(v, list) else v
    return t


EDGE = {
    "head": dict(bleed=True),                                              # bleeding with no mark
    "neck": dict(marks=["bite", "cut"], infected=True, bleed=True),        # two marks, infected, bleeding
    "up-torso": dict(splint=True, marks=["glass"]),                        # no splint picture for the chest
    "foot-l": dict(bandage="dirty", splint=True, fracture=True),
    "groin": dict(marks=["burn"], infected=True),
    "hand-r": dict(marks=["deep", "stitch"]),
}
STATES = [("hurt", WS.SOME), ("every", WS.EVERY), ("edge", EDGE)]

for sex in ("m", "f"):
    for light in (False, True):
        # (Nov 23 2026: the panel under 1x is half the canvas high, 0.5, as 204 rows were 0.75 of the 272 before)
        for (pw, ph, want_s) in ((SK.FW, SK.FH, 1), (2 * SK.FW, 2 * SK.FH, 2), (80, SK.FH // 2, 0.5)):
            for sname, state in STATES:
                for tone in ((0, 1, 2, 3, 4) if (pw, sname) == (SK.FW, "every") else (1,)):
                    L, g, fig = lua_for(sex, light)
                    for k, (r, g_, b, a) in COLORS.items():
                        fig.setPartColor(fig, k, r, g_, b, a)
                    for p, w in state.items():
                        fig.setPartWounds(fig, DISPLAY[p], lua_wounds(L, w))
                    fig.setSkinTone(fig, tone)
                    ox, oy = 7, 5
                    cv = Canvas(pw + 2 * ox, ph + 2 * oy)
                    P = L.table()
                    P.drawTextureScaled = lambda self, t, x, y, w, h, a, r, gg, b: cv.draw(t.path, x, y, w, h, a, r, gg, b)
                    P.drawTextureScaledUniform = lambda self, t, x, y, s_, a, r, gg, b: cv.draw(
                        t.path, x, y, tex(t.path).width * s_, tex(t.path).height * s_, a, r, gg, b)
                    fig.drawAt(fig, P, ox, oy, pw, ph)
                    s = float(fig._drawAtS)
                    name = f"{sex} {'light' if light else 'dark'} {pw}x{ph} {sname} tone {tone}"
                    ref = reference(sex, light, s, ox, oy, pw, ph, state, tone)
                    diff = float(np.abs(cv.a - ref.a).max())
                    check(f"{name}: picture equals the reference", diff < 1e-5 and abs(s - want_s) < 1e-6, (s, diff))
                    missing = sorted({c for c in cv.calls if not os.path.exists(os.path.join(ROOT, "42", c))})
                    check(f"{name}: every picture asked for exists", not missing, missing)
                    # (render() draws the same as drawAt: no child-panel figure draws wounds today, but it would)

# a figure with no wounds draws exactly what it drew before the wounds came (test_body's reference)
for sex in ("m", "f"):
    L, g, fig = lua_for(sex, False)
    cv = Canvas(SK.FW * 2 + 14, SK.FH * 2 + 10)
    P = L.table()
    P.drawTextureScaled = lambda self, t, x, y, w, h, a, r, gg, b: cv.draw(t.path, x, y, w, h, a, r, gg, b)
    P.drawTextureScaledUniform = lambda self, t, x, y, s_, a, r, gg, b: cv.draw(
        t.path, x, y, tex(t.path).width * s_, tex(t.path).height * s_, a, r, gg, b)
    for k, (r, g_, b, a) in COLORS.items():
        fig.setPartColor(fig, k, r, g_, b, a)
    fig.setPartWounds(fig, "Head", lua_wounds(L, dict(marks=["cut"])))
    fig.setPartWounds(fig, "Head", None)          # cleared again
    fig.drawAt(fig, P, 7, 5, SK.FW * 2, SK.FH * 2)
    ref = reference(sex, False, 2, 7, 5, SK.FW * 2, SK.FH * 2, {}, 1)
    check(f"{sex}: no wounds, the figure as before", float(np.abs(cv.a - ref.a).max()) < 1e-5)
    check(f"{sex}: no wounds, no wound picture asked for", not any("/wounds/" in c for c in cv.calls))

# ---- the flesh (d_flesh.py, under the bones in <s>-skeleton.png): it fills the body and leaves the outline's line alone
from scipy import ndimage as _ndi
for sex in ("m", "f"):
    sk = np.array(tex(f"media/textures/ZeD/body/{sex}-skeleton.png"))[..., 3]
    bone = np.array(SK.render(sex)[0])[..., 3] > 0           # the bones alone (a thin limb's may touch the line)
    inner = _ndi.binary_erosion(SK.silhouette(sex))
    check(f"{sex}: the flesh fills the body inside its outline", bool((sk[inner] == 255).all()),
          int((sk[inner] != 255).sum()))
    stray = int(((sk > 0) & ~inner & ~bone).sum())
    check(f"{sex}: no flesh on the outline's line or outside it", stray == 0, stray)

# ---- woundsFrom: what the figure draws, from what the Health list read of a part (HealthTab's SEEN)
L, g, fig = lua_for("m", False)


def py(v):
    if v is None:
        return None
    if lj.lua_type(v) == "table":
        keys = list(v.keys())
        if keys and all(isinstance(k, int) for k in keys):
            return [py(v[k]) for k in sorted(keys)]
        return {k: py(v[k]) for k in keys}
    return v


UNIT = [
    ("nothing wrong", dict(), None),
    ("a bandage covers the cut and the bleeding", dict(bandaged=True, clean=True, cut=True, bleed=True),
     {"bandage": "clean"}),
    ("a spent bandage is dirty", dict(bandaged=True, clean=False), {"bandage": "dirty"}),
    ("a stitched deep wound shows its stitches", dict(deep=True, stitched=True), {"marks": ["stitch"]}),
    ("the two most serious marks", dict(bitten=True, deep=True, cut=True, scratch=True), {"marks": ["bite", "deep"]}),
    ("an infection the list names rings the first mark", dict(cut=True, infected=True),
     {"marks": ["cut"], "infected": True}),
    ("an infection with no mark has no ring", dict(infected=True), None),
    ("held back: the bandage only", dict(bandaged=True, clean=True, cut=True, held=True), {"bandage": "clean"}),
    ("held back: the stitches only", dict(stitched=True, cut=True, fracture=True, held=True), {"marks": ["stitch"]}),
    ("held back: no fracture", dict(fracture=True, held=True), None),
    ("a splinted fracture", dict(fracture=True, splint=True), {"fracture": True, "splint": True}),
    ("bleeding alone", dict(bleed=True), {"bleed": True}),
    ("a bandage hides burn and glass", dict(bandaged=True, clean=True, burn=True, glass=True), {"bandage": "clean"}),
    ("a burn before a scratch", dict(scratch=True, burn=True), {"marks": ["burn", "scratch"]}),
    ("bullet and glass, bleeding", dict(bullet=True, glass=True, bleed=True),
     {"marks": ["bullet", "glass"], "bleed": True}),
]
woundsFrom = g.ZeD_BodyFigure.woundsFrom
for name, t, want in UNIT:
    got = py(woundsFrom(L.table_from(t)))
    check(f"woundsFrom: {name}", got == want, got)
check("woundsFrom: nothing for nothing", woundsFrom(None) is None)

# ---- the Health tab's own reading: gatherData hands the figure each part's wounds by the list's rules, and reads
# nothing of a part twice (the real HealthTab.lua beside the figure's file, over stubs of the game, as QA's sims run it)
HEALTH = os.path.join(os.path.dirname(os.path.abspath(SRC)), "HealthTab.lua")
check("HealthTab.lua sits beside the figure's file", os.path.exists(HEALTH), HEALTH)
if os.path.exists(HEALTH):
    H = lj.LuaRuntime(unpack_returned_tuples=True)
    H.execute(r"""
        require = function() end
        Events = setmetatable({}, { __index = function(t, k)
            local e = { Add = function() end, Remove = function() end }; rawset(t, k, e); return e end })
        getText = function(k) return "T:" .. tostring(k) end
        getTextOrNull = function() return nil end
        getTexture = function(n) return { name = n } end
        getTimestampMs = function() return 0 end
        instanceof = function(o, c) return type(o) == "table" and o._class == c end
        Perks = { Doctor = "Doctor" }
        ISHealthPanel = { cheat = false }
        Texture = { getSharedTexture = function(path, f) return { path = path, f = f } end }
        ISPanel = { render = function() end }
        function ISPanel:derive(name) local c = {}; c.__index = c; setmetatable(c, { __index = ISPanel }); return c end
        function ISPanel:new(x, y, w, h) return { x = x, y = y, w = w, h = h } end
        PARTS = { "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin", "UpperArm_L", "UpperArm_R", "ForeArm_L",
            "ForeArm_R", "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }
        BodyPartType = { getDisplayName = function(t) return "Part " .. tostring(t) end,
                         ToString = function(t) return tostring(t) end }
        for _, n in ipairs(PARTS) do BodyPartType[n] = n end
        ZeD = { T = { px = function(n) return n end, sp = {}, positive = "pos", warning = "warn", danger = "dng",
                      accent = "acc", info = "inf" } }
        ZeD.tr = function(k) return "Z:" .. k end
        ZeD.logOnce = function() end
        ZeD.textCase = function(s) return s end
        ZeD.Atoms = { safeGet = function(o, m, ...)
            local f = o and o[m]; if not f then return nil end
            local ok, r = pcall(f, o, ...); if ok then return r end; return nil end }
        -- a body part: each method answers from its state, and counts its calls
        NUMBERS = { getHealth = 100, getFractureTime = 0, getSplintFactor = 0, getBurnTime = 0, getBandageLife = 1,
            getWoundInfectionLevel = 0, getDeepWoundTime = 0, getScratchTime = 0, getCutTime = 0, getStitchTime = 0,
            getStiffness = 0, getAdditionalPain = 0, getPlantainFactor = 0, getComfreyFactor = 0, getGarlicFactor = 0 }
        CALLS = {}
        function mockPart(name, state)
            local calls = {}
            CALLS[name] = calls
            return setmetatable({}, { __index = function(_, k)
                return function()
                    calls[k] = (calls[k] or 0) + 1
                    if k == "getType" then return name end
                    local v = state[k]
                    if v == nil then v = NUMBERS[k] end
                    if v == nil then return false end
                    return v
                end
            end })
        end
        function mockPlayer(target, state, doc)
            local list = {}
            for i, n in ipairs(PARTS) do list[i] = mockPart(n, n == target and state or {}) end
            TARGET = list[8]
            local parts = { size = function() return #list end, get = function(_, i) return list[i + 1] end }
            local body = { getBodyParts = function() return parts end, getOverallBodyHealth = function() return 80 end }
            return { getBodyDamage = function() return body end, getPerkLevel = function() return doc end,
                     isFemale = function() return false end,
                     getHumanVisual = function() return { getSkinTextureIndex = function() return 3 end } end }
        end""")
    H.execute(open(SRC, "rb").read())
    H.execute(open(HEALTH, "rb").read())
    hg = H.globals()
    # the cases name the BodyPart's getters short
    GETTER = {"bandaged": "bandaged", "life": "getBandageLife", "stitched": "stitched", "splint": "getSplintFactor",
              "fracture": "getFractureTime", "bitten": "bitten", "deep": "deepWounded", "bullet": "haveBullet",
              "glass": "haveGlass", "cut": "isCut", "burn": "getBurnTime", "scratch": "scratched", "bleed": "bleeding",
              "infected": "isInfectedWound", "inflevel": "getWoundInfectionLevel"}
    WOUND_GETTERS = set(GETTER.values())
    CASES = [
        ("nothing wrong", dict(), 0, False, False, None),
        ("a bandage covers the cut and the bleeding", dict(bandaged=True, cut=True, bleed=True), 0, False, False,
         {"bandage": "clean"}),
        ("a spent bandage is dirty", dict(bandaged=True, life=0), 0, False, False, {"bandage": "dirty"}),
        ("a stitched deep wound shows its stitches", dict(deep=True, stitched=True), 0, False, False,
         {"marks": ["stitch"]}),
        ("the two most serious marks", dict(bitten=True, deep=True, cut=True, scratch=True), 0, False, False,
         {"marks": ["bite", "deep"]}),
        ("infection hidden from a novice", dict(cut=True, infected=True, inflevel=0.1), 0, False, False,
         {"marks": ["cut"]}),
        ("infection seen by a First Aid 9 doctor", dict(cut=True, infected=True, inflevel=0.1), 9, False, False,
         {"marks": ["cut"], "infected": True}),
        ("infection grown past a novice's eye", dict(cut=True, infected=True, inflevel=0.3), 0, False, False,
         {"marks": ["cut"], "infected": True}),
        ("infection under the cheat", dict(cut=True, infected=True, inflevel=0.1), 0, False, True,
         {"marks": ["cut"], "infected": True}),
        ("held back: the bandage only", dict(bandaged=True, cut=True), 0, True, False, {"bandage": "clean"}),
        ("held back: the stitches only", dict(stitched=True, cut=True, fracture=10), 0, True, False,
         {"marks": ["stitch"]}),
        ("held back: no fracture", dict(fracture=10), 0, True, False, None),
        ("a splinted fracture", dict(fracture=30, splint=1), 0, False, False, {"fracture": True, "splint": True}),
        ("bleeding alone", dict(bleed=True), 0, False, False, {"bleed": True}),
        ("a bandage hides burn, glass, infection", dict(bandaged=True, burn=5, glass=True, infected=True, inflevel=1), 9,
         False, False, {"bandage": "clean"}),
        ("a burn before a scratch", dict(scratch=True, burn=5), 0, False, False, {"marks": ["burn", "scratch"]}),
        ("bullet and glass, bleeding", dict(bullet=True, glass=True, bleed=True), 0, False, False,
         {"marks": ["bullet", "glass"], "bleed": True}),
    ]
    for name, t, doc, held, cheat, want in CASES:
        state = H.table_from({GETTER[k]: v for k, v in t.items()})
        player = hg.mockPlayer("ForeArm_L", state, doc)
        hg.ISHealthPanel.cheat = cheat
        hg.ZeD.HealthTab.extras = H.table()
        if held:
            hg.ZeD.HealthTab.addExtras("test", H.eval("function(t) return { holds = function(p, bp) return bp == t end } end")(
                hg.TARGET))
        data = hg.ZeD.HealthTab.gatherData(player)
        got = py(data.woundsByFigure["Left Forearm"])
        others = [k for k in data.woundsByFigure.keys() if k != "Left Forearm"]
        twice = sorted({f"{part}.{m}" for part, calls in hg.CALLS.items() for m, n in calls.items()
                        if n > 1 and m in WOUND_GETTERS})
        check(f"gatherData: {name}", got == want and not others, (got, others))
        check(f"gatherData: {name}: nothing of a part read twice", not twice, twice)
        check(f"gatherData: {name}: the skin tone", data.skinTone == 3, data.skinTone)
    hg.ISHealthPanel.cheat = False

# ---- the skin tone
L.execute('''
toneChar = { getHumanVisual = function() return { getSkinTextureIndex = function() return 3 end } end }
noVisual = { getHumanVisual = function() error("no visual") end }''')
check("skinToneOf: the character's own tone", g.ZeD_BodyFigure.skinToneOf(L.globals().toneChar) == 3)
check("skinToneOf: 0 when the game gives none", g.ZeD_BodyFigure.skinToneOf(L.globals().noVisual) == 0)
for given, want in ((7, 4), (-1, 0), (None, 0), (2.6, 2)):
    fig.setSkinTone(fig, given)
    check(f"setSkinTone({given}) keeps to the five tones", fig.skinTone == want, fig.skinTone)

# ---- the pictures load nearest-filtered
L, g, fig = lua_for("f", False)
asked = []
L.globals().Texture.getSharedTexture = lambda path, f: (asked.append((path, f)), L.table_from({"path": path}))[1]
P = L.table()
P.drawTextureScaled = lambda *a: None
P.drawTextureScaledUniform = lambda *a: None
for p, w in WS.EVERY.items():
    fig.setPartWounds(fig, DISPLAY[p], lua_wounds(L, w))
fig.drawAt(fig, P, 0, 0, 2 * SK.FW, 2 * SK.FH)
wound_asks = [(p, f) for p, f in asked if "/wounds/" in p]
check(f"f: {len(wound_asks)} wound pictures asked for, all nearest-filtered", wound_asks and all(f == 3 for _, f in wound_asks))
check("f: each wound picture is loaded once", len(wound_asks) == len({p for p, _ in wound_asks}))
print(f"{len(FAILS)} failed", FAILS)
sys.exit(1 if FAILS else 0)
