-- ZeDUI/tools/qa/oc_power_sim.lua  (Nov 26 2026, Build): QA's power card bugs from the Nov 26 card map
-- (ZeDUI/qa/audits/2026-11-26_map_cards_power_fluid_fire.md), with no game running. The real ObjectCardPower.lua,
-- FacePop.lua and ZeD_DpadWheels.lua run on Lua 5.1 with a forgiving stand-in for everything else (a global or field
-- nobody set is a stand-in that takes any call) and small fakes of generators, fires and the player.
--   PW1  a generator started indoors: the Lights wheel's slice and the pop-out's engine switch carry the game's
--        fumes line (IGUI_Generator_IsToxic), and turning it on there says it over his head at the press
--   PW2  the Lights wheel turns on / off the generator nearest him, not the first in reading order
--   PW4  at condition 0 Turn on is greyed with its reason on the card, the pop-out and the wheel, not the main verb;
--        a press on the face's engine switch says why; the condition line says it won't start
--   FI4  the Lights wheel puts out the fire nearest him, with the game's action for its kind (a campfire the camping
--        one, a fireplace or charcoal grill ISBBQMenu.onExtinguish, a propane grill its Turn off)
-- Each check fails on the code before this work.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_power_sim.lua
-- It prints FAIL lines and a last line "oc_power_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_power_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ---------------------------------------------------------------------------
-- THE FORGIVING WORLD
-- ---------------------------------------------------------------------------
local autoMT = {}
local function auto() return setmetatable({}, autoMT) end
autoMT.__index = function(t, k) return auto() end
autoMT.__call = function() return auto() end
autoMT.__concat = function(a, b) return "" end
autoMT.__unm = function() return 0 end
for _, m in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow" }) do autoMT[m] = function() return 0 end end
setmetatable(_G, { __index = function(t, k)
    if k == "arg" then return nil end
    local s = auto(); rawset(t, k, s); return s
end })

function getTimestampMs() return 1000000 end
function getText(k, a) if a ~= nil then return k .. "(" .. tostring(a) .. ")" end return k end
function getTextOrNull() return nil end
function instanceof(o, cls) return type(o) == "table" and o._class == cls end
function require() return true end
function isClient() return false end
local QUEUE = {}
ISTimedActionQueue = { add = function(a) QUEUE[#QUEUE + 1] = a end }
local HALO = {}
HaloTextHelper = { addBadText = function(p, t) HALO[#HALO + 1] = t end, addGoodText = function() end }
local CALLS = {}
ISWorldObjectContextMenu = {
    onActivateGenerator = function(wo, enable, g, pn) CALLS[#CALLS + 1] = { fn = "activate", enable = enable, obj = g } end,
}
ISCampingMenu = { onPutOutCampfire = function(wo, pl, c) CALLS[#CALLS + 1] = { fn = "campfire", obj = c } end }
ISBBQMenu = {
    onExtinguish = function(wo, n, o) CALLS[#CALLS + 1] = { fn = "extinguish", obj = o } end,
    onToggle = function(wo, n, o) CALLS[#CALLS + 1] = { fn = "toggle", obj = o } end,
}
Perks = { Electricity = "Electricity" }
local function reset() QUEUE, HALO, CALLS = {}, {}, {}; ISTimedActionQueue.add = function(a) QUEUE[#QUEUE + 1] = a end end
local function haloHas(t) for _, h in ipairs(HALO) do if h == t then return true end end return false end

ZeD = setmetatable({}, { __index = function(t, k) return auto() end })
ZeD.Safe = { on = function() return false end, register = function() end }
function ZeD.tr(k, a) if a ~= nil then return k .. "(" .. tostring(a) .. ")" end return k end
function ZeD.trDefaults() end
function ZeD.logOnce(where, err) print("logOnce " .. tostring(where) .. ": " .. tostring(err)) end
ZeD.Settings = { devicesSimple = function() return false end }

-- the shared card host: only what the power card and the wheel ask of it
local function ocall(o, m, ...)
    if o == nil then return nil end
    local ok, f = pcall(function() return o[m] end)
    if not (ok and f) then return nil end
    local ok2, r = pcall(f, o, ...)
    if ok2 then return r end
    return nil
end
ZeD.ObjectCards = { kinds = {}, call = ocall, ui = auto(), LEASH = 6, CARD_W = 480 }
local OC = ZeD.ObjectCards
function OC.register(def) OC.kinds[def.id] = def end
function OC.keyOf(sq, p) return p .. sq:getX() .. "," .. sq:getY() end
function OC.sortTargets(l) return l end
function OC.eachSquare() end
function OC.faceZone() end
-- the face's plate: one engine rocker and one outlet key
ZeD.Plate = { draw = function() end, cue = function() end, hoverKey = function() end, markKey = function() end,
    centre = function() return 0 end,
    controls = function() return { { id = "engine", kind = "rocker", x = 0, y = 0, w = 10, h = 10 },
                                   { id = "outlet", kind = "key", x = 20, y = 0, w = 10, h = 10 } } end }
ZeD.Px = { canvas = function() return {} end, tex = function() return nil end, pick = function(id) return { w = 100, h = 50 }, id end,
           kFit = function() return 1 end }
ZeD.PhysPx = { items = {}, fallback = { generator = "gen" }, plates = { gen = { w = 100, h = 50 } }, texdir = "" }

-- ---------------------------------------------------------------------------
-- FAKES
-- ---------------------------------------------------------------------------
local function square(x, y, outside)
    return { getX = function() return x end, getY = function() return y end, getZ = function() return 0 end,
             isOutside = function() return outside end, getBuilding = function() return (not outside) and {} or nil end,
             getRoom = function() return nil end }
end
local function generator(name, x, y, o)
    local g = { _class = "IsoGenerator", name = name, sq = square(x, y, o.outside ~= false) }
    g.on, g.fuel, g.cond, g.conn = o.on or false, o.fuel or 5, o.cond or 80, o.conn ~= false
    function g:getSquare() return self.sq end
    function g:isActivated() return self.on end
    function g:getFuel() return self.fuel end
    function g:getMaxFuel() return 10 end
    function g:getFuelPercentage() return self.fuel * 10 end
    function g:getCondition() return self.cond end
    function g:isConnected() return self.conn end
    function g:getObjectIndex() return 1 end
    return g
end
local player = { x = 10.5, y = 10.5 }
function player:getX() return self.x end
function player:getY() return self.y end
function player:DistToSquared(x, y) return (x - self.x) ^ 2 + (y - self.y) ^ 2 end
function player:getCurrentSquare() return square(10, 10, true) end
function player:getPlayerNum() return 0 end
function player:getPerkLevel() return 0 end
function player:getInventory()
    return { getAllEvalRecurse = function() return { size = function() return 0 end } end,
             getFirstTypeRecurse = function() return nil end }
end

local function loadZ(path)
    local f, err = loadfile(CLIENT .. path)
    if not f then return false, err end
    return pcall(f)
end

-- ===========================================================================
section("loading")
-- ===========================================================================
local okP, errP = loadZ("ObjectCardPower.lua")
check("ObjectCardPower.lua loads", okP, errP)
local OCP = ZeD.ObjectCardPower
local def = OC.kinds.generator
check("the generator kind registers", def ~= nil)
ZeD.Wheel = {}
ZeD.DpadWheels = {}
local okD, errD = loadZ("ZeD_DpadWheels.lua")
check("ZeD_DpadWheels.lua loads", okD, errD)
local H = ZeD.DpadWheels.H
check("the Lights wheel is there", H and type(H.lights) == "function")

-- the generators the wheel sees, in reading order (the north one first)
local GENS = {}
def.nearby = function()
    local l = {}
    for _, g in ipairs(GENS) do l[#l + 1] = { obj = g, sq = g:getSquare() } end
    return l
end
local FIRES = {}
OC.kinds.fire = { nearby = function() return FIRES end }
local function lightsSlice(i)
    local ok, out = pcall(H.lights, player, 0)
    if not ok then print("lights failed: " .. tostring(out)); return nil end
    return out[i]
end

-- ===========================================================================
section("PW2: the wheel's generator is the nearest one")
-- ===========================================================================
do
    local north = generator("north", 10, 5, {})
    local near = generator("near", 11, 10, {})
    GENS = { north, near }
    reset()
    local s = lightsSlice(2)
    check("the slice can run", s and type(s.run) == "function", s and s.off)
    if s and s.run then pcall(s.run, player, 0) end
    check("Turn on starts the one beside him", CALLS[1] and CALLS[1].obj == near and CALLS[1].enable == true,
        CALLS[1] and CALLS[1].obj and CALLS[1].obj.name)
    north.on, near.on = true, true
    reset()
    s = lightsSlice(2)
    check("with both running the slice reads Turn off", s and s.detail == "ContextMenu_Turn_Off", s and s.detail)
    if s and s.run then pcall(s.run, player, 0) end
    check("Turn off stops the one beside him", CALLS[1] and CALLS[1].obj == near and CALLS[1].enable == false,
        CALLS[1] and CALLS[1].obj and CALLS[1].obj.name)
end

-- ===========================================================================
section("PW1: indoors, the wheel and the pop-out warn")
-- ===========================================================================
do
    local garage = generator("garage", 10, 11, { outside = false })
    GENS = { garage }
    reset()
    local s = lightsSlice(2)
    check("the slice carries the game's fumes line", s and type(s.detail) == "string" and s.detail:find("IGUI_Generator_IsToxic", 1, true) ~= nil,
        s and s.detail)
    if s and s.run then pcall(s.run, player, 0) end
    check("it still starts (a warning, not a block)", CALLS[1] and CALLS[1].fn == "activate" and CALLS[1].enable == true)
    check("the press says the fumes line over his head", haloHas("IGUI_Generator_IsToxic"))
    -- outside: no warning
    local yard = generator("yard", 10, 11, {})
    GENS = { yard }
    reset()
    s = lightsSlice(2)
    check("outside the slice has no fumes line", s and s.detail == "ContextMenu_Turn_On", s and s.detail)
    if s and s.run then pcall(s.run, player, 0) end
    check("outside the press says nothing", #HALO == 0)

    -- the card and its face (the pop-out draws the same face)
    local t = { obj = garage, sq = garage:getSquare() }
    local okR, errR = pcall(def.refresh, t, player)
    check("the card reads the garage generator", okR, errR)
    check("the card's body still warns", t.d and t.d.toxic == true)
    local zones = {}
    local card = { zone = function(self, z) zones[#zones + 1] = z end, focusOf = function() return nil end }
    local okF, errF = pcall(OCP.face, card, 0, 0, 1, { w = 100, h = 50 }, t)
    check("the face draws", okF, errF)
    local eng
    for _, z in ipairs(zones) do if z.fid == "gen:engine" then eng = z end end
    check("the engine switch's line is the fumes warning", eng and eng.help == "IGUI_Generator_IsToxic", eng and eng.help)
    reset()
    if eng and eng.run then pcall(eng.run, card, player) end
    check("the engine switch starts it", CALLS[1] and CALLS[1].fn == "activate" and CALLS[1].enable == true)
    check("and says the fumes line over his head", haloHas("IGUI_Generator_IsToxic"))
    -- the card's Turn on verb takes the same path
    local pv
    for _, v in ipairs(t.verbs or {}) do if v.id == "power" then pv = v end end
    reset()
    if pv and pv.run then pcall(pv.run, player, t) end
    check("the card's Turn on says the fumes line too", haloHas("IGUI_Generator_IsToxic"))

    -- the pop-out's driver: its pad strip and the mouse line read the warning
    local okFP, errFP = loadZ("FacePop.lua")
    check("FacePop.lua loads", okFP, errFP)
    local drv = ZeD.FacePop and ZeD.FacePop.generator
    check("the generator pop-out driver is there", drv ~= nil)
    if drv then
        local panel = { zone = function(self, z) local l = self._zones; if l then l[#l + 1] = z end end, focusOf = function() return nil end }
        local dev = { t = t, obj = garage }
        local okDF, hits = pcall(drv.drawFace, panel, 0, 0, 1, { dev = dev, des = { w = 100, h = 50 } })
        check("the pop-out draws the face", okDF and type(hits) == "table", hits)
        local h
        for _, x in ipairs(okDF and hits or {}) do if x.id == "gen:engine" then h = x end end
        check("the pop-out's mouse line is the fumes warning", h and drv.help(dev, "gen:engine", h) == "IGUI_Generator_IsToxic",
            h and drv.help(dev, "gen:engine", h))
        check("the pop-out's pad A reads the fumes warning", drv.labelA("gen:engine") == "IGUI_Generator_IsToxic", drv.labelA("gen:engine"))
        check("the outlet keeps its name", drv.labelA("gen:outlet") == "UI_ZeD_PlainCard_Outlet", drv.labelA("gen:outlet"))
        reset()
        pcall(drv.press, player, dev, "gen:engine")
        check("the pop-out's press starts it and warns over his head", CALLS[1] and CALLS[1].enable == true and haloHas("IGUI_Generator_IsToxic"))
    end
end

-- ===========================================================================
section("PW4: condition 0")
-- ===========================================================================
do
    local broken = generator("broken", 11, 10, { cond = 0 })
    GENS = { broken }
    reset()
    local s = lightsSlice(2)
    check("the wheel greys it", s and s.run == nil)
    check("the wheel says it needs repair", s and s.off == "UI_ZeD_Power_NeedRepair", s and s.off)
    local t = { obj = broken, sq = broken:getSquare() }
    local okR, errR = pcall(def.refresh, t, player)
    check("the card reads the broken generator", okR, errR)
    local pv
    for _, v in ipairs(t.verbs or {}) do if v.id == "power" then pv = v end end
    check("the card's Turn on is greyed", pv and pv.enabled == false)
    check("and not the main verb", pv and not pv.primary)
    check("its reason is the repair", pv and pv.needs == "UI_ZeD_Power_NeedsRepair", pv and pv.needs)
    check("the engine switch has no toggle", t.toggle == nil)
    local zones = {}
    local card = { zone = function(self, z) zones[#zones + 1] = z end, focusOf = function() return nil end }
    pcall(OCP.face, card, 0, 0, 1, { w = 100, h = 50 }, t)
    local eng
    for _, z in ipairs(zones) do if z.fid == "gen:engine" then eng = z end end
    check("the engine switch's line says why", eng and eng.help == "UI_ZeD_Power_NeedRepair", eng and eng.help)
    reset()
    if eng and eng.run then pcall(eng.run, card, player) end
    check("a press queues nothing", #CALLS == 0 and #QUEUE == 0)
    check("a press says why over his head", haloHas("UI_ZeD_Power_NeedRepair"))
    -- the condition line (its source: the body draws it through the card's widgets)
    local src = io.open(CLIENT .. "ObjectCardPower.lua"):read("*a")
    check("the condition line says it won't start at 0", src:find('d.cond <= 0 then condTxt = ZeD.tr("UI_ZeD_Power_Broken"', 1, true) ~= nil)
    -- a running generator at 0 can still be turned off
    broken.on = true
    reset()
    s = lightsSlice(2)
    check("a running one at 0 still turns off", s and type(s.run) == "function" and s.detail == "ContextMenu_Turn_Off")
end

-- ===========================================================================
section("FI4: the wheel's fire is the nearest, with its kind's action")
-- ===========================================================================
do
    local fireplace = { _class = "IsoFireplace", name = "fireplace", isLit = function() return true end }
    local camp = { name = "campfire", isLit = true, updateFromIsoObject = function() end }
    FIRES = { { kind = "fireplace", obj = fireplace, sq = square(10, 5, false) },
              { kind = "campfire", obj = camp, sq = square(11, 10, true) } }
    reset()
    local s = lightsSlice(3)
    check("the slice reads Put out", s and s.name == "ContextMenu_Put_out_fire", s and s.name)
    if s and s.run then pcall(s.run, player, 0) end
    check("Put out goes to the campfire beside him", CALLS[1] and CALLS[1].fn == "campfire" and CALLS[1].obj == camp,
        CALLS[1] and (CALLS[1].fn .. " " .. tostring(CALLS[1].obj and CALLS[1].obj.name)))
    -- the fireplace alone: the game's own extinguish for it (ISBBQMenu, as its menu and loot window do)
    FIRES = { { kind = "fireplace", obj = fireplace, sq = square(10, 5, false) } }
    reset()
    s = lightsSlice(3)
    if s and s.run then pcall(s.run, player, 0) end
    check("a fireplace goes out with ISBBQMenu.onExtinguish", CALLS[1] and CALLS[1].fn == "extinguish" and CALLS[1].obj == fireplace)
    -- a lit propane grill: its burner's Turn off
    local grill = { name = "grill", isLit = function() return true end }
    FIRES = { { kind = "propane", obj = grill, sq = square(11, 10, true) } }
    reset()
    s = lightsSlice(3)
    check("a lit propane grill reads Turn off", s and s.name == "ContextMenu_Turn_Off", s and s.name)
    if s and s.run then pcall(s.run, player, 0) end
    check("a propane grill turns off with ISBBQMenu.onToggle", CALLS[1] and CALLS[1].fn == "toggle" and CALLS[1].obj == grill)
end

print("oc_power_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
