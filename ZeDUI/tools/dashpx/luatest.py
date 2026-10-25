"""Runs the real Lua (PixelFonts, ZeD_PixelParts, DashPx, ZeD_RadioOps, ZeD_Plate, ZeD_Dashboard) under LuaJIT with the game's API
mocked, records every drawRect / drawTextureScaled, and paints them into an image: what the game would draw, frame for
frame, for each design in a given state. Also checks the hit areas against the parts.
usage: python luatest.py [k] [state]"""
import os
import sys
import numpy as np
from PIL import Image
try:
    import lupa.luajit21 as lj
except ImportError:          # no lupa here: luacli.py runs the same through a LuaJIT executable
    lj = None

import designs as DZ

HERE = os.path.dirname(os.path.abspath(__file__))
# In the repo (ZeDUI/tools/dashpx) the Lua and the textures are the mod's own; in a scratch copy, lua/ and out/mod.
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
if os.path.isdir(os.path.join(REPO, "42", "media", "lua", "client", "ZeD")) and not os.path.isdir(os.path.join(HERE, "lua")):
    MOD = os.path.join(REPO, "42")
    LUA_SRC = os.path.join(MOD, "media", "lua", "client", "ZeD")
    RADIOOPS = os.path.join(LUA_SRC, "ZeD_RadioOps.lua")
else:
    MOD = os.path.join(HERE, "out", "mod", "ZeD-UI", "42")
    LUA_SRC = os.path.join(HERE, "lua")
    RADIOOPS = os.path.join(HERE, "..", "physpx", "lua", "ZeD_RadioOps.lua") if os.path.exists(os.path.join(HERE, "..", "physpx", "lua", "ZeD_RadioOps.lua")) else "/mnt/user-data/uploads/ZeD-UI/42/media/lua/client/ZeD/ZeD_RadioOps.lua"
TR_LUA = os.path.join(MOD, "media", "lua", "shared", "ZeD", "Tr.lua")
GAME_MEDIA = next((p for p in ("/mnt/user-data/uploads/Project Zomboid/SteamApps/common/ProjectZomboid/",
                               "E:/Project Zomboid/steamapps/common/ProjectZomboid/") if os.path.isdir(p)),
                  "/mnt/user-data/uploads/Project Zomboid/SteamApps/common/ProjectZomboid/")
SCRIPTS = {"luxury": "Base.CarLuxury", "nyala": "Base.CarNormal", "cossette": "Base.SportsCar", "police": "Base.CarLightsPolice",
           "d6": "Base.PickUpTruck", "dashelite": "Base.ModernCar", "primani": "Base.ModernCar02", "dart": "Base.SmallCar",
           "horizon": "Base.SmallCar02", "wagon": "Base.CarStationWagon", "suv": "Base.SUV", "van": "Base.VanSpiffo",
           "bulldriver": "Base.PickUpVan", "rancher": "Base.OffRoad", "taxi": "Base.CarTaxi", "ambulance": "Base.VanAmbulance",
           "fire": "Base.PickUpTruckLightsFire", "ranger": "Base.CarLightsRanger", "race": "Base.RaceCar12"}

def load_texts():
    """the English the game would hand getTextOrNull for the keys the dash's Lua names: vanilla's (ContextMenu_..., IGUI_...)
    and ZeD's own UI.json (else ZeD.tr falls back to its defaults); none when the game's files are not here"""
    import json, re
    keys = set()
    for f in ("ZeD_Dashboard.lua", "ZeD_Plate.lua", "ZeD_RadioOps.lua"):
        fp = os.path.join(LUA_SRC, f) if f != "ZeD_RadioOps.lua" else RADIOOPS
        if os.path.exists(fp): keys |= set(re.findall(r'"([A-Za-z]+_[A-Za-z0-9_]+)"', open(fp, encoding="utf-8").read()))
    out = {}
    srcs = [os.path.join(GAME_MEDIA, "media", "lua", "shared", "Translate", "EN", n) for n in ("ContextMenu.json", "IG_UI.json", "UI.json", "Tooltip.json")]
    srcs.append(os.path.join(MOD, "media", "lua", "shared", "Translate", "EN", "UI.json"))
    for fp in srcs:
        if not os.path.exists(fp): continue
        try: d = json.load(open(fp, encoding="utf-8"))
        except ValueError: continue
        for k_, v in d.items():
            if k_ in keys and isinstance(v, str): out[k_] = v
    return out


PRELUDE = r'''
-- Kahlua's strings are Java's (16-bit characters): string.char takes a code above 255 there. LuaJIT's does not, so the
-- harness writes those as UTF-8 (the faces' accented and Cyrillic capitals, ZeD_PixelParts)
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
Events = setmetatable({}, { __index = function(t, k) local e = { Add = function() end, Remove = function() end }; rawset(t, k, e); return e end })
Texture = { getSharedTexture = function(path, flags) return { path = path, flags = flags } end }
getTimestampMs = function() return py_now() end
getTextOrNull = function(k) return py_text(k) end
getText = function(k) return k end
getPlayerScreenLeft = function() return 0 end
getPlayerScreenTop = function() return 0 end
getPlayerScreenWidth = function() return py_screen()[1] end
getPlayerScreenHeight = function() return py_screen()[2] end
instanceof = function() return true end
getGameSpeed = function() return 1 end
setGameSpeed = function() end
getGameTime = function() return { getHour = function() return 10 end, getMinutes = function() return 8 end } end
getPlayerVehicleDashboard = function() return nil end
getZomboidRadio = function() return nil end
getSoundManager = function() return { playUISound = function() end } end
sendClientCommand = function(...) py_log("command", ...) end
ISVehicleMenu = setmetatable({}, { __index = function(t, k) return function(...) py_log("ISVehicleMenu." .. k) end end })
ISVehiclePartMenu = setmetatable({}, { __index = function(t, k) return function(...) py_log("ISVehiclePartMenu." .. k) end end })
require = function() end
ZeD = { Scale = { root = function() return py_scale() end }, T = { accent = { r = 0.95, g = 0.62, b = 0.2 }, sp = { scrollbarW = 8 }, px = function(v) return v end } }
ZeD.Safe = { register = function() end, on = function() return false end }
ZeD.logOnce = function(what, err) print("logOnce", what, err) end
ZeD_Panel = {}
ZeD_Panel.__index = ZeD_Panel
function ZeD_Panel:derive(name) local cls = {}; cls.__index = cls; cls.Type = name; setmetatable(cls, { __index = self }); return cls end
function ZeD_Panel:new(x, y, w, h) return { x = x, y = y, width = w, height = h, visible = true } end
function ZeD_Panel:getWidth() return self.width end
function ZeD_Panel:getHeight() return self.height end
function ZeD_Panel:getX() return self.x end
function ZeD_Panel:getY() return self.y end
function ZeD_Panel:setWidth(v) self.width = v end
function ZeD_Panel:setHeight(v) self.height = v end
function ZeD_Panel:setX(v) self.x = v end
function ZeD_Panel:setY(v) self.y = v end
function ZeD_Panel:setVisible(v) self.visible = v end
function ZeD_Panel:isVisible() return self.visible end
function ZeD_Panel:initialise() end
function ZeD_Panel:addToUIManager() end
function ZeD_Panel:getMouseX() return 0 end
function ZeD_Panel:getMouseY() return 0 end
function ZeD_Panel:drawRect(x, y, w, h, a, r, g, b) py_rect(x, y, w, h, a, r, g, b) end
function ZeD_Panel:drawTextureScaled(t, x, y, w, h, a, r, g, b) py_tex(t.path, x, y, w, h, a) end
function ZeD_Panel:drawTextureScaledAspect(t, x, y, w, h, a, r, g, b) py_tex(t.path, x, y, w, h, a) end
'''

VEHICLE = r'''
function make_vehicle(S)
    local v = {}
    local parts = {
        GasTank = { isContainer = function() return true end, getContainerContentAmount = function() return S.fuel * 100 end, getContainerCapacity = function() return 100 end },
        Engine = { getCondition = function() return S.engineCond or 100 end },
        Heater = S.hasHeater ~= false and { getModData = function() return { active = S.heaterOn, temperature = S.heaterTemp } end } or nil,
        Radio = S.radio and {} or nil,
        TruckBed = S.hasTrunk ~= false and {} or nil,
    }
    function v:isEngineRunning() return S.running end
    function v:isEngineStarted() return S.running end
    function v:isKeysInIgnition() return S.keysIn end
    function v:isHotwired() return false end
    function v:getKeyId() return S.keyId or 1 end
    local md = { ZeD_ash = S.ash }
    function v:getModData() return md end
    function v:getMaxPassengers() return 4 end
    function v:getCharacter(i) if i >= 1 and i <= (S.riders or 0) then return {} end return nil end
    function v:getCurrentSpeedKmHour() return S.speed_kmh end
    function v:getEngineSpeed() return S.rpm end
    function v:getTransmissionNumberLetter() return S.gear or "3" end
    function v:getPartById(id) return parts[id] end
    function v:getBatteryCharge() return S.battery end
    function v:getHeadlightsOn() return S.lights end
    function v:areAllDoorsLocked() return S.anyLocked end
    function v:isAnyDoorLocked() return S.anyLocked end
    function v:isTrunkLocked() return false end
    function v:isRegulator() return S.cruise end
    function v:getRegulatorSpeed() return 40 end
    function v:hasLightbar() return S.hasLightbar end
    function v:getLightbarLightsMode() return S.lightbar or 0 end
    function v:getLightbarSirenMode() return S.siren or 0 end
    function v:getScriptName() return S.script end
    function v:getScript() return { getCarModelName = function() return S.script:gsub("^Base%.", "") end, getName = function() return S.script end } end
    function v:getId() return 16 end
    function v:isDriver() return not S.passenger end
    return v
end
function make_player(v)
    local p = {}
    function p:getVehicle() return v end
    function p:getInventory() return { haveThisKeyId = function() return {} end } end
    function p:getPlayerNum() return 0 end
    function p:isLocalPlayer() return true end
    return p
end
'''


class Recorder:
    def __init__(s, w, h):
        s.a = np.zeros((h, w, 4), np.float32)
        s.cache = {}
        s.calls = 0; s.missing = set()

    def rect(s, x, y, w, h, a, r, g, b):
        s.calls += 1
        x, y, w, h = int(x), int(y), int(w), int(h)
        H, W = s.a.shape[:2]
        x0, y0, x1, y1 = max(0, x), max(0, y), min(W, x + w), min(H, y + h)
        if x1 <= x0 or y1 <= y0: return
        reg = s.a[y0:y1, x0:x1]
        col = np.array([r * 255, g * 255, b * 255], np.float32)
        reg[..., :3] = reg[..., :3] * (1 - a) + col * a
        reg[..., 3] = np.maximum(reg[..., 3], 255 * a + reg[..., 3] * (1 - a))

    def tex(s, path, x, y, w, h, a):
        s.calls += 1
        if path not in s.cache:
            fp = os.path.join(MOD, path) if not path.startswith("media/textures/shirtdecals") else os.path.join(GAME_MEDIA, path)
            s.cache[path] = Image.open(fp).convert("RGBA") if os.path.exists(fp) else None
            if s.cache[path] is None: s.missing.add(path)
        im = s.cache[path]
        if im is None: return
        im = im.resize((int(w), int(h)), Image.NEAREST)
        src = np.array(im, np.float32)
        x, y = int(x), int(y)
        H, W = s.a.shape[:2]
        x0, y0, x1, y1 = max(0, x), max(0, y), min(W, x + src.shape[1]), min(H, y + src.shape[0])
        if x1 <= x0 or y1 <= y0: return
        sub = src[y0 - y:y1 - y, x0 - x:x1 - x]
        al = sub[..., 3:4] / 255.0 * a
        reg = s.a[y0:y1, x0:x1]
        reg[..., :3] = reg[..., :3] * (1 - al) + sub[..., :3] * al
        reg[..., 3:4] = np.maximum(reg[..., 3:4], al * 255)

    def image(s): return Image.fromarray(np.clip(s.a, 0, 255).astype(np.uint8), "RGBA")


LAST = {}


def run(did, state, k=1, frames=40, dt=120, log=None, lua_after=None):
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    LAST['L'] = L
    g = L.globals()
    rec = Recorder(800 * k, 172 * k)
    clock = {"t": 1_000_000}
    g.py_now = lambda: clock["t"]
    titles = {SCRIPTS[d].replace("Base.", ""): DZ.DESIGNS[d][0] for d in DZ.ORDER}
    texts = load_texts()
    g.py_text = lambda key: titles.get(str(key).replace("IGUI_VehicleName", ""), None) if str(key).startswith("IGUI_VehicleName") else texts.get(str(key))
    if state.get("vname"):   # the game's own name for the car under test
        g.py_text = lambda key: state["vname"] if str(key).startswith("IGUI_VehicleName") else texts.get(str(key))
    g.py_screen = lambda: L.table(1920 * k, 1080 * k)
    g.py_scale = lambda: float(k)
    g.py_rect = rec.rect
    g.py_tex = rec.tex
    g.py_log = (lambda *a: log.append(" ".join(str(x) for x in a))) if log is not None else (lambda *a: None)
    L.execute(PRELUDE)
    L.execute(open(TR_LUA, encoding="utf-8").read())          # ZeD.tr and its defaults (the translation layer)
    for f in ("PixelFonts.lua", "DashPx.lua"):
        L.execute(open(os.path.join(MOD, "media", "lua", "client", "ZeD", f)).read())
    L.execute(open(os.path.join(LUA_SRC, "ZeD_PixelParts.lua")).read())
    L.execute(open(RADIOOPS).read().replace("return O", "ZeD.RadioOps = O"))
    if os.path.exists(os.path.join(LUA_SRC, "ZeD_Plate.lua")):          # the shared plate template draws the parts
        L.execute(open(os.path.join(LUA_SRC, "ZeD_Plate.lua")).read())
    L.execute(open(os.path.join(LUA_SRC, "ZeD_Dashboard.lua")).read())
    L.execute(VEHICLE)
    if state.get("gamepad"):   # the input detector reports a pad; nothing holds focus, so the hint reads 're-enter the seat'
        L.execute('ZeD.Input = ZeD.Input or {}; ZeD.Input.Detector = { getMode = function() return "gamepad" end }')
    if lua_after: L.execute(lua_after)
    S = L.table_from({k_: v for k_, v in state.items() if not isinstance(v, (dict, list))})
    S.script = state.get("script") or SCRIPTS[did]
    radio = state.get("radio")
    if radio:
        r = L.table_from({"kind": radio, "on": state.get("radioOn", False), "switchOn": state.get("radioOn", False), "channel": 98400 if radio not in ("ham", "army", "hammake") else 98400,
                          "volume": 0.6, "presetIdx": 1, "name": "KNOX TALK", "signal": True, "muted": False, "micMuted": False, "playing": False})
        r.presets = L.table_from([L.table_from({"freq": 98400, "name": "Knox Talk"})])
        g.ZeD.RadioOps.read = lambda part: r
        S.radio = True
    else:
        S.radio = False
    veh = g.make_vehicle(S)
    ply = g.make_player(veh)
    g.getSpecificPlayer = lambda n: ply
    dash = g.ZeD_Dashboard.new(g.ZeD_Dashboard, 0)
    if state.get("meterOn"): dash._meterFlag(dash, veh, True)      # the taxi's flag down
    for i in range(frames):
        clock["t"] += dt
        rec.a[:] = 0
        dash.prerender(dash)
    hits = [(h.id, h.x, h.y, h.w, h.h, h.enabled) for h in dash._hit.values()]
    return rec, hits, dash


STATE_DRIVE = dict(keysIn=True, running=True, lights=True, speed_kmh=72, rpm=2600, fuel=0.62, battery=0.9, heaterOn=True, heaterTemp=17,
                   ac=False, radio="valutech", radioOn=True, gear="3", anyLocked=True, cruise=True, hasLightbar=True, lightbar=2, siren=1,
                   engineCond=100)

HINT_PROBE = r'''
ZeD.Input = { Detector = { getMode = function() return "gamepad" end },
    Focus = { getFocusedWindow = function() return FOCUS_WIN end, getFocusedElement = function(w) return FOCUS_EL end,
              setRingZoneElements = function() end, setZoneFocusable = function() end, registerWindow = function() end,
              claimFocus = function() end, releaseFocus = function() end, unregisterWindow = function() end } }
HINTS = {}
local text0 = ZeD.Px.text
ZeD.Px.text = function(cv, str, x, y, c, font, scale, align, style, shadow)
    if y == 2 and align == "r" then HINTS[#HINTS + 1] = { s = tostring(str), w = ZeD.Px.textWidth(str, font, scale), x = x } end
    return text0(cv, str, x, y, c, font, scale, align, style, shadow)
end
'''


BADGE_CASES = [  # script, the game's name, design, make, model, unit plate lead
    ("Base.VanSpiffo", "Spiffo Van", "van", "FRANKLIN", "VALULINE", None),
    ("Base.Van_KnoxDisti", "Knox Distillery Franklin Valuline", "van", "FRANKLIN", "VALULINE", None),
    ("Base.VanSeats_Creature", "Creature Cruiser", "van", "FRANKLIN", "VALULINE", None),
    ("Base.StepVan_Citr8", "Citr8 Chevalier Step Van", "van", "CHEVALIER", "STEP VAN", None),
    ("Base.PickUpTruckLightsFossoil", "Fossoil Chevalier D6", "d6", "CHEVALIER", "D6", None),
    ("Base.PickUpVanLightsKentuckyLumber", "Kentucky Lumber Dash Bulldriver", "bulldriver", "DASH", "BULLDRIVER", None),
    ("Base.CarNormalSmashedFront", "Wrecked Chevalier Nyala", "nyala", "CHEVALIER", "NYALA", None),
    ("Base.OffRoadSmashedLeft", "Wrecked Dash Rancher", "rancher", "DASH", "RANCHER", None),
    ("Base.CarLuxury", "Mercia Lang 4000", "luxury", "MERCIA", "LANG 4000", None),
    ("Base.ModernCar", "Dash Elite", "dashelite", "DASH", "ELITE", None),
    ("Base.CarLightsPolice", "Muldraugh Police Chevalier Nyala", "police", "CHEVALIER", "NYALA", "POLICE"),
    ("Base.ModernCarLightsMeadeSheriff", "Meade Sheriff Dash Elite", "police", "DASH", "ELITE", "SHERIFF"),
    ("Base.CarLightsKST", "State Trooper Chevalier Nyala", "police", "CHEVALIER", "NYALA", "TROOPER"),
    ("Base.CarLightsLouisvilleCounty", "LCPD Chevalier Nyala", "police", "CHEVALIER", "NYALA", "LCPD"),
    ("Base.ModernCarLightsWestPoint", "West Point Police Dash Elite", "police", "DASH", "ELITE", "POLICE"),
    ("Base.StepVan_LouisvilleSWAT", "Louisville SWAT Chevalier Step Van", "police", "CHEVALIER", "STEP VAN", "SWAT"),
    ("Base.PickUpTruckLightsFire", "Fire Department Chevalier D6", "fire", "CHEVALIER", "D6", "FIRE"),
    ("Base.CarLightsRanger", "Ranger Chevalier Nyala", "ranger", "CHEVALIER", "NYALA", "RANGER"),
    ("Base.CarTaxi", "Taxi", "taxi", "CHEVALIER", "NYALA", "TAXI"),
    ("Base.VanAmbulance", "Ambulance", "ambulance", "FRANKLIN", "VALULINE", "AMBULANCE"),
    # modded cars (not the game's own families) keep their own maker; a leading model year is skipped
    ("Base.92fordCVPI", "1992 Ford Crown Victoria", "nyala", "FORD", "CROWN VICTORIA", None),
    ("Base.MyBronco", "Ford Bronco", "nyala", "FORD", "BRONCO", None),
    ("Base.MyHearse", "Hearse", "nyala", "HEARSE", "HEARSE", None),
]


def badge_check():
    bad = []
    for script, name, did, make, model, lead in BADGE_CASES:
        st = dict(STATE_DRIVE); st.update(script=script, vname=name, radio=None)
        rec, hits, dash = run(did, st, k=1, frames=2)
        b = dash._badge
        # the unit line carries the middle dot as the single byte 183 (a Java char in Kahlua): read it with that swapped out
        unit = LAST['L'].eval('function(b) return (b.unit:gsub(string.char(183), "*")) end')(b)
        got = (str(dash._designId), str(b.make), str(b.model), unit.split(" ")[0])
        want = (did, make, model, lead or got[3])
        print(f"  {name:36s} -> {got[0]:10s} {got[1]:9s} {got[2]:10s} {unit}")
        if got != want: bad.append((name, got, want))
    return bad


def hint_check(hint_w):
    """the gamepad hint, for every control focused in every ignition state, stays inside the room the art leaves for it"""
    worst, bad = (0, ""), []
    for did in DZ.ORDER:
        for ign in (dict(keysIn=False, running=False), dict(keysIn=True, running=False), dict(keysIn=True, running=True)):
            st = dict(STATE_DRIVE); st.update(ign); st["radio"] = DZ.DESIGNS[did][6]; st["gamepad"] = True
            rec, hits, dash = run(did, st, k=1, frames=2, lua_after=HINT_PROBE)
            g = LAST['L'].globals()
            g.FOCUS_WIN = dash
            els = [dash._elements[i] for i in range(1, len(dash._elements) + 1)]
            for e in [None] + els:
                g.FOCUS_EL = e
                g.HINTS = LAST['L'].table()
                dash.prerender(dash)
                for i in range(1, len(g.HINTS) + 1):
                    h = g.HINTS[i]
                    if h.w > worst[0]: worst = (h.w, h.s)
                    if h.w > hint_w: bad.append((did, h.w, h.s))
    return worst, bad


if __name__ == "__main__":
    if lj is None:
        import luacli
        run_ = lambda did, st, k, log: luacli.run(did, st, k=k)[:2] + (None,)
        badge_check, hint_check = luacli.badge_check, luacli.hint_check
    else:
        run_ = lambda did, st, k, log: run(did, st, k=k, log=log)
    if len(sys.argv) > 1 and sys.argv[1] == "badges":
        bad = badge_check()
        for b_ in bad: print("  WRONG:", b_)
        sys.exit(1 if bad else 0)
    if len(sys.argv) > 1 and sys.argv[1] == "hints":
        import dashlib
        worst, bad = hint_check(dashlib.HINT_W)
        print("widest hint", worst, "room", dashlib.HINT_W)
        for b_ in sorted(set(bad)): print("  too wide:", b_)
        sys.exit(1 if bad else 0)
    k = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    out = os.path.join(HERE, "out", "luatest"); os.makedirs(out, exist_ok=True)
    for did in DZ.ORDER:
        st = dict(STATE_DRIVE); st["radio"] = DZ.DESIGNS[did][6]
        st["hasLightbar"] = did in ("police", "fire", "ranger", "ambulance")
        st["ash"], st["meterOn"], st["riders"] = True, True, 2       # round 6: the tray open, the taxi's flag down, two riders
        log = []
        rec, hits, dash = run_(did, st, k, log)
        rec.image().save(os.path.join(out, f"{did}_{k}x.png"))
        print(f"{did:10s} calls={rec.calls:5d} hits={len(hits):2d} missing={sorted(rec.missing)}")
