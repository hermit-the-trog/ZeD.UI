-- ZeDUI/tools/qa/fishing_tab_sim.lua (Nov 2026, punch list 167): the World window's Fishing tab with no game running.
-- Lua 5.1 stubs of the game's fishing (Fishing.fishes, the lure tables, FishingManager's states, FishingRod) and of the
-- player, then the real FishingLog.lua, FishingWall.lua and FishingTab.lua run against them. Checks: the tab shows with a
-- rod or water near and hides otherwise; what each state lists and which keys its band holds; a catch recorded through
-- the game's landing (PickupFish:start) updates the log and the trophies (the ten heaviest, the best per species, junk
-- and No catch never on the wall, the caps) and survives a reload of the mod data; bait ratings only from Fishing 6 and
-- only for species caught; the tab opens itself on a cast only while the World window is open; the short pulls.
-- Run from the repo root:  lua.exe ZeDUI/tools/qa/fishing_tab_sim.lua   (prints FAIL lines and a last summary line)

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. m) end end

-- ---------------------------------------------------------------------------
-- THE ENGINE, STUBBED
-- ---------------------------------------------------------------------------
local clockMs = 100000
function getTimestampMs() return clockMs end
function isMultiplayer() return false end
function isMouseButtonDown() return false end
ItemTag = { FISHING_ROD = "FishingRod" }
Perks = { Fishing = "Fishing" }
IsoFlagType = { water = "water" }
ArrayList = { new = function() local t = { n = {} }; return t end }
function instanceof(o, c) return o and o._class == c end
function getText(k) return k end
function getItemNameFromFullType(ft) return (ft or ""):gsub("^Base%.", "") end
function getTexture() return nil end
function getScriptManager() return { FindItem = function() return nil end } end
function getSoundManager() return { playUISound = function() end } end
function getPlayer() return _G.P end
function getClimateManager() return { getWindPower = function() return 0.1 end, getAirTemperatureForCharacter = function() return 20 end } end
Events = setmetatable({}, { __index = function(t, k) local e = { list = {} }; function e.Add(f) e.list[#e.list + 1] = f end; rawset(t, k, e); return e end })
require = function() end

local GT = { yr = 1993, mo = 6, dy = 24, hr = 5, mn = 41, wa = 500.7 }
function getGameTime()
    return { getYear = function() return GT.yr end, getMonth = function() return GT.mo end, getDay = function() return GT.dy end,
             getHour = function() return GT.hr end, getMinutes = function() return GT.mn end,
             getWorldAgeHours = function() return GT.wa end, getTimeOfDay = function() return GT.hr + GT.mn / 60 end }
end

-- water: a set of "x,y" squares
local WATER = {}
function getCell()
    return { getGridSquare = function(_, x, y, z)
        return { getProperties = function() return { has = function(_, f) return WATER[x .. "," .. y] == true end } end }
    end }
end

-- items
local function item(ft, o)
    o = o or {}
    local it = { ft = ft, name = o.name or getItemNameFromFullType(ft), md = o.md or {}, tags = o.tags or {}, wt = o.wt or 1, _class = o.class }
    function it:getFullType() return self.ft end
    function it:getName() return self.name end
    function it:getDisplayName() return self.name end
    function it:getModData() return self.md end
    function it:hasTag(t) return self.tags[t] == true end
    function it:isBroken() return false end
    function it:isCooked() return false end
    function it:getContainer() return { getContainingItem = function() return o.bag end } end
    function it:getActualWeight() return self.wt end
    function it:getScriptItem() return { getDisplayName = function() return "Fishing Rod" end } end
    function it:getCondition() return 8 end
    function it:getConditionMax() return 10 end
    function it:isTwoHandWeapon() return true end
    return it
end
local function rodItem(lure) return item("Base.FishingRod", { tags = { FishingRod = true }, md = { fishing_Lure = lure, fishing_LineType = "Base.FishingLine", fishing_LineCondition = 0.82, fishing_HookType = "Base.FishingHook" } }) end
local satchel = item("Base.Bag_FishingSatchel", { name = "Fishing Satchel" })

-- the player
local function player()
    local p = { md = {}, prim = nil, inv = {}, lv = 6, x = 100.5, y = 100.5, z = 0, vars = {} }
    function p:getModData() return self.md end
    function p:getPrimaryHandItem() return self.prim end
    function p:getPerkLevel() return self.lv end
    function p:getX() return self.x end
    function p:getY() return self.y end
    function p:getZ() return self.z end
    function p:getPlayerNum() return 0 end
    function p:getUsername() return "sim" end
    function p:setVariable(k, v) self.vars[k] = v end
    function p:getInventory()
        local me = self
        return { getAllEvalRecurse = function()
            local list = me.inv
            return { size = function() return #list end, get = function(_, i) return list[i + 1] end }
        end }
    end
    return p
end

-- the game's fish tables: 21 species in the game's order, lures as fishing_properties gives them (a few kinds here)
ZeD = { tr = function(k, ...) local a = { ... }; local s = k; for i = 1, select("#", ...) do s = s .. "|" .. tostring(a[i]) end; return s end,
        logOnce = function(_, e) print("logOnce " .. tostring(e)) end, textCase = function(s) return s end, T = { px = function(n) return n end } }
local SPECIES = { "LargemouthBass", "SmallmouthBass", "WhiteBass", "SpottedBass", "StripedBass", "Bluegill", "WhiteCrappie",
    "BlackCrappie", "RedearSunfish", "YellowPerch", "Sauger", "GreenSunfish", "Walleye", "FreshwaterDrum", "BlueCatfish",
    "ChannelCatfish", "FlatheadCatfish", "Muskellunge", "AligatorGar", "Paddlefish", "BaitFish" }
Fishing = { fishes = {}, lure = { Worms = { ["Base.Worm"] = {} }, Insect = { ["Base.Cricket"] = {} }, ArtificalLure = { ["Base.JigLure"] = {} } },
            trashItems = { "Base.Seaweed", "Base.TinCanEmpty" }, ManagerInstances = {} }
for _, s in ipairs(SPECIES) do
    Fishing.fishes[#Fishing.fishes + 1] = { itemType = "Base." .. s, maxWeight = (s == "Paddlefish") and 27 or 2.5,
        lure = { ["Base.Worm"] = (s == "Bluegill") and 0.9 or 0.5, ["Base.Cricket"] = (s == "Bluegill") and 0.3 or 0.0 } }
end
function Fishing.IsLure(ft) return ft == "Base.Worm" or ft == "Base.Cricket" or ft == "Base.JigLure" end
function Fishing.IsArtificalLure(ft) return ft == "Base.JigLure" end
function Fishing.isRiver() return true end
Fishing.Utils = {
    skillSizeLimit = { [0] = 1.4, 1.5, 1.9, 2.2, 2.3, 2.8, 4.5, 9, 27, 32, 45 },
    getFishSizeChancesBySkillLevel = function() return 35, 45, 20 end,
    isNearShore = function() return true end,
    getTimeParams = function() return { coeff = 1.2 } end,
    getTemperatureParams = function() return { coeff = 1 } end,
    getWeatherParams = function() return { isFog = false, isRain = false } end,
    isAccessibleAimDist = function() return true end,
}
local calls = {}
Fishing.States = { PickupFish = {}, Cast = {} }
function Fishing.States.PickupFish.start(self) calls[#calls + 1] = "pick"; if self.manager.fishingRod.consume then self.manager.fishingRod.rodItem.md.fishing_Lure = nil end end
function Fishing.States.Cast.start(self) calls[#calls + 1] = "cast" end
Fishing.FishingRod = { isReel = function() return false end, isReleaseLine = function() return false end }

-- the World window
local opened = {}
local WW = { open = false, showing = false }
ZeD_WorldWindow = {
    addTab = function(def) WW.def = def end,
    isOpen = function() return WW.open end,
    isTabShowing = function(id) return WW.showing end,
    openTab = function(pn, id) opened[#opened + 1] = id; return true end,
}
ZeD_ScrollbarState = { new = function() return { scrollPos = 0, setScrollPos = function(self, v) self.scrollPos = v end, setBarSize = function() end, draw = function() end } end }

-- the real files
local base = "42/media/lua/client/ZeD/"
dofile(base .. "FishingLog.lua")
dofile(base .. "FishingWall.lua")
dofile(base .. "FishingTab.lua")
local L, FT = ZeD.FishingLog, ZeD.FishingTab
ok(L and FT and ZeD.FishingWall, "the three files load")
ok(WW.def and WW.def.id == "fishing" and WW.def.after == "vehicle" and WW.def.group == 2, "the tab is on the World window's strip, after Vehicle")
ok(type(WW.def.buildFocusables) == "function" and type(WW.def.landOn) == "function", "the tab gives its stops and where the pad lands")

-- ---------------------------------------------------------------------------
-- WHEN THE TAB SHOWS
-- ---------------------------------------------------------------------------
local p = player()
_G.P = p
L._resetScan()
ok(not L.visible(p), "no rod, no water: hidden")
WATER["103,100"] = true
L._resetScan()
ok(L.visible(p), "water 3 tiles away: shows")
local w = L.water(p)
ok(w and w.d == 3 and w.dir == "UI_ZeD_Forage_CompassE", "the nearest water: 3 tiles E")
WATER["103,100"] = nil
WATER["109,100"] = true
L._resetScan()
ok(not L.visible(p), "water 9 tiles away: hidden (within the header's scan, past the tab's reach)")
ok(L.water(p) and L.water(p).d == 9, "the header still names water 9 tiles away")
p.prim = rodItem("Base.Worm")
ok(L.visible(p), "a rod in the main hand: shows, water or not")
WATER["109,100"] = nil; WATER["104,100"] = true
L._resetScan()

-- ---------------------------------------------------------------------------
-- EACH STATE: ITS ROWS AND ITS BAND
-- ---------------------------------------------------------------------------
local function kinds(list) local t = {}; for _, it in ipairs(list) do t[#t + 1] = it.k end; return table.concat(t, ",") end
local function has(list, k, pred) for _, it in ipairs(list) do if it.k == k and (not pred or pred(it)) then return it end end end
local function ids(b) local t = {}; for _, x in ipairs(b.buttons) do t[#t + 1] = x.id end; return table.concat(t, ",") end

p.inv = { item("Base.Worm", { bag = satchel }), item("Base.Worm", { bag = satchel }), item("Base.Cricket", { bag = satchel }), item("Base.JigLure") }
local st = { fold = false }
local s = FT.snap(p, st)
ok(s.state == "ready", "rod with a worm, no line out: ready (" .. tostring(s.state) .. ")")
ok(#s.baits == 3 and s.baits[1].n == 2 and s.baits[1].where == "Fishing Satchel", "bait rows grouped by kind with count and bag")
ok(s.sel == "Base.Worm", "the picked bait starts as the one on the hook")
local items = FT.build(s, st)
ok(items[1].k == "hero" and has(items, "chips"), "ready: the rod hero and the chips first")
ok(has(items, "bait", function(it) return it.on and it.sel end) and not has(items, "bait", function(it) return it.locked end), "ready: bait rows pickable, the hook's marked")
ok(has(items, "head", function(it) return it.wall end), "ready: the catch log's head carries the Trophy wall key")
ok(has(items, "fold"), "ready: the More detail fold")
local b = FT.band(s, st)
ok(ids(b) == "bait,cast" and b.buttons[2].variant == "primary", "ready band: bait key, then Cast as the default (" .. ids(b) .. ")")
ok(b.buttons[1].label == "UI_ZeD_Fish_RemoveBait", "the picked bait is on the hook: the key takes it off")
st.sel = "Base.Cricket"
ok(FT.band(FT.snap(p, st), st).buttons[1].label == "UI_ZeD_Fish_ChangeBait", "another bait picked: Change bait")
ok(FT.landId(s) == "fish:b:cast", "the pad lands on Cast")
st.fold = true
ok(has(FT.build(FT.snap(p, st), st), "fact", function(it) return it.label == "UI_ZeD_Fish_FCast" end), "the fold open: what the level gives")
st.fold = false

-- the line out, waiting
local mgr = { player = p, states = { Idle = {}, None = {} } }
mgr.state = mgr.states.Idle
function mgr:changeState(n) self.changed = n end
local bob = { lure = "Base.Worm", getX = function() return 106 end, getY = function() return 97 end }
mgr.fishingRod = { rodItem = p.prim, bobber = bob, tensionLimit = 180, highTensionTimer = 45, getTension = function() return -0.3 end,
                   damageLine = function(self) self.damaged = true end }
Fishing.ManagerInstances[0] = mgr
s = FT.snap(p, st)
ok(s.state == "wait", "bobber out, nothing on: wait")
ok(s.bobber and s.bobber.d == 7 and s.bobber.dir == "UI_ZeD_Forage_CompassNE", "the header names the bobber: 7 tiles NE")
items = FT.build(s, st)
ok(has(items, "bait", function(it) return it.locked end) and not has(items, "bait", function(it) return not it.locked end), "wait: bait rows locked")
ok(ids(FT.band(s, st)) == "stop,reel", "wait band: Stop fishing, Reel in")
ok(FT.landId(s) == "fish:b:reel", "the pad lands on Reel in")

-- a fish on
bob.fish = { isTrash = false }
s = FT.snap(p, st)
ok(s.state == "fight", "a fish on the line: fight")
items = FT.build(s, st)
ok(items[1].k == "tension" and items[2].k == "hero", "fight: the tension block leads, then the rod")
ok(not has(items, "bait"), "fight: no bait list")
ok(ids(FT.band(s, st)) == "stop,release,reel", "fight band: Stop, Let out line, Reel in")
ok(math.abs(s.held - 0.25) < 1e-9, "held at the limit: the rod's own timer over its limit")

-- no bait anywhere (the sim swaps the bags at once: the half-second copy of what they hold is dropped each time)
Fishing.ManagerInstances[0] = nil
p.prim = rodItem(nil)
p.inv = {}
L._resetCarry()
st = { fold = false }
s = FT.snap(p, st)
ok(s.state == "nobait", "nothing on the hook and none in the bags: nobait")
items = FT.build(s, st)
ok(has(items, "empty", function(it) return it.bad end), "nobait: the bare-hook line, in red")
ok(has(items, "fact", function(it) return it.label == "UI_ZeD_Fish_GWorms" and it.value:find("Worm") end), "nobait: the game's bait groups with item names")
local bnb = FT.band(s, st)
ok(ids(bnb) == "cast,search" and bnb.buttons[2].variant == "primary", "nobait band: Cast, Search for bait (default)")

-- no rod in hand
p.prim = nil
p.inv = { rodItem("Base.Worm") }
L._resetCarry()
s = FT.snap(p, st)
ok(s.state == "norod", "no rod in hand: norod")
ok(ids(FT.band(s, st)) == "equip", "norod band: Equip rod (one in the bags)")
p.inv = {}
L._resetCarry()
ok(ids(FT.band(FT.snap(p, st), st)) == "", "norod, no rod at all: no keys")

-- ---------------------------------------------------------------------------
-- RECORDING A CATCH THROUGH THE GAME'S LANDING
-- ---------------------------------------------------------------------------
ok(L.install(), "the hooks go in")
ok(L.install() and Fishing.States.PickupFish._zedOrigStart ~= nil, "installing twice keeps one wrap")
p.prim = rodItem("Base.Worm")
local function fishItem(sp, wt, len)
    local it = item("Base." .. sp, { name = "Medium " .. sp .. " - " .. len .. "cm", wt = wt, md = { fishing_FishSize = len } })
    return it
end
local function land(fi, trash, consume)
    local fr = { rodItem = p.prim, consume = consume, bobber = { lure = "Base.Worm", fish = fi and { fishItem = fi, isTrash = trash } or nil,
                 getX = function() return 104 end, getY = function() return 100 end } }
    calls = {}
    Fishing.States.PickupFish.start({ manager = { player = p, fishingRod = fr } })
    p.prim.md.fishing_Lure = "Base.Worm"
end
local d = L.data(p)
land(fishItem("Bluegill", 0.42, 12), false, true)
ok(calls[1] == "pick", "the game's own landing ran")
ok(#d.log == 1 and d.log[1].k == "fish" and d.log[1].name == "Medium Bluegill - 12cm" and d.log[1].wt == 0.42, "the catch is in the log as the game named it")
ok(#d.top == 1 and d.best["Base.Bluegill"] and d.best["Base.Bluegill"].river == true, "the first fish: on the wall, with its water")
ok(d.trip and d.trip.landed == 1 and d.trip.baits["Base.Worm"] == 1, "this trip: one fish, the worm it took")
land(item("Base.Seaweed", { wt = 0.1 }), true)
ok(#d.log == 2 and d.log[2].k == "junk" and #d.top == 1, "junk: in the log, never on the wall")
land(nil)
ok(#d.log == 3 and d.log[3].k == "gone" and #d.top == 1, "No catch: in the log, never on the wall")
ok(d.trip.junk == 1 and d.trip.gone == 1, "this trip counts junk and the ones that got away")
-- twelve more fish: the ten heaviest stay, heaviest first; the best per species
local weights = { 3.1, 0.5, 8.4, 1.2, 5.6, 0.9, 2.2, 4.4, 0.3, 6.1, 1.7, 7.7 }
for i, wt in ipairs(weights) do land(fishItem(SPECIES[(i % 5) + 1], wt, 20 + i), false) end
ok(#d.top == 10, "the wall keeps ten")
local sorted = true
for i = 2, #d.top do if d.top[i].wt > d.top[i - 1].wt then sorted = false end end
ok(sorted and d.top[1].wt == 8.4 and d.top[10].wt == 0.9, "heaviest first; the lightest drop off (" .. d.top[10].wt .. ")")
local nb = 0
for _ in pairs(d.best) do nb = nb + 1 end
ok(nb == 6 and d.best["Base.Bluegill"].wt == 0.42, "the best of each species caught (6 kinds)")
local items2, mounted = L.wall(p, "each")
ok(#items2 == 21 and mounted == 6, "Each kind: 21 plaques, 6 mounted")
ok(items2[6].rec and items2[6].rec.type == "Base.Bluegill" and items2[21].rec == nil, "the game's species order; empty plaques have no record")
-- the log's cap
for i = 1, 70 do land(item("Base.Seaweed", { wt = 0.1 }), true) end
ok(#d.log == L.LOG_MAX and d.n == 85, "the log keeps the newest 64 (85 recorded)")
ok(#L.recent(p) == 20 and L.recent(p)[1] == d.log[#d.log], "the tab shows the newest 20, newest first")
ok(#d.top == 10 and nb == 6, "junk never moved the wall")
-- a reload: the mod data copied as the save would hold it
local function deep(t) if type(t) ~= "table" then return t end; local o = {}; for k, v in pairs(t) do o[k] = deep(v) end; return o end
local saved = deep(p.md)
local p2 = player()
p2.md = saved
local d2 = L.data(p2)
ok(#d2.log == 64 and #d2.top == 10 and d2.best["Base.Bluegill"].wt == 0.42 and d2.fish == 13, "a reload keeps the log, the ten and the bests")
land(fishItem("Bluegill", 9.9, 30), false)   -- (on p: the reloaded copy is separate)
ok(L.data(p2).top[1].wt == 8.4, "the reloaded records are their own table")
L.clearLog(p)
ok(#L.data(p).log == 0 and #L.data(p).top == 10, "Clear log empties the log; the wall stays")

-- ---------------------------------------------------------------------------
-- BAIT RATINGS: FROM FISHING 6, CAUGHT SPECIES ONLY
-- ---------------------------------------------------------------------------
p.md.fishing_catchedFish = { ["Base.Bluegill"] = true, ["Base.LargemouthBass"] = true }
p.lv = 5
ok(L.ratings(p, "Base.Worm") == nil, "Fishing 5: no ratings")
p.lv = 6
local g, n = L.ratings(p, "Base.Worm")
ok(n == 2 and g[1].key == "UI_ZeD_Fish_Great" and g[1].types[1] == "Base.Bluegill", "Fishing 6: the worm is great for bluegill")
ok(g[2].key == "UI_ZeD_Fish_Average" and #g[2].types == 1, "and average for the bass; no other species listed")
g = L.ratings(p, "Base.Cricket")
ok(g[1].key == "UI_ZeD_Fish_BelowAvg" and g[2].key == "UI_ZeD_Fish_None", "the cricket: below average for bluegill, none for bass")
ok(L.grade(0.8) == "UI_ZeD_Fish_Great" and L.grade(0.6) == "UI_ZeD_Fish_Good" and L.grade(0.4) == "UI_ZeD_Fish_Average"
   and L.grade(0.2) == "UI_ZeD_Fish_BelowAvg" and L.grade(0.1) == "UI_ZeD_Fish_Poor" and L.grade(0) == "UI_ZeD_Fish_None", "the game's grade bands")
p.inv = { item("Base.Worm") }
L._resetCarry()
st = {}
s = FT.snap(p, st)
ok(has(FT.build(s, st), "rate"), "ready at Fishing 6: the picked bait's ratings show")
p.lv = 4
s = FT.snap(p, st)
ok(not has(FT.build(s, st), "rate"), "ready at Fishing 4: no ratings")

-- ---------------------------------------------------------------------------
-- OPENING ITSELF WHEN THE LINE GOES OUT
-- ---------------------------------------------------------------------------
local castMgr = { player = p, fishingRod = { rodItem = p.prim } }
opened = {}
WW.open = false
Fishing.States.Cast.start({ manager = castMgr })
ok(#opened == 0, "a cast with the World window shut opens nothing")
WW.open, WW.showing = true, false
Fishing.States.Cast.start({ manager = castMgr })
ok(#opened == 1 and opened[1] == "fishing", "a cast with the World window open opens the Fishing tab")
ok(calls[#calls] == "cast", "the game's own cast ran")
WW.showing = true
opened = {}
Fishing.States.Cast.start({ manager = castMgr })
ok(#opened == 0, "already showing: left alone")
ok(L.castAt == clockMs, "the cast is timed for the waiting clock")

-- ---------------------------------------------------------------------------
-- THE KEYS: THE GAME'S OWN CALLS
-- ---------------------------------------------------------------------------
ok(Fishing.FishingRod.isReel({}) == false, "no pull asked: the game's own reel test")
L.pull("reel", 600)
ok(Fishing.FishingRod.isReel({}) == true and Fishing.FishingRod.isReleaseLine({}) == false, "Reel in: the rod reels for a moment")
L.pull("release", 600)
ok(Fishing.FishingRod.isReel({}) == false and Fishing.FishingRod.isReleaseLine({}) == true, "Let out line: the rod lets out, the left mouse ignored")
clockMs = clockMs + 1000
ok(Fishing.FishingRod.isReel({}) == false and L.pulling() == nil, "the pull ends")
local m2 = { player = p, states = { Idle = {}, None = {} }, fishingRod = { damageLine = function(self) self.damaged = true end } }
m2.state = {}
function m2:changeState(n) self.changed = n end
Fishing.ManagerInstances[0] = m2
FT.stopFishing(p)
ok(m2.changed == "None" and m2.fishingRod.damaged and p.vars.FishingFinished == true, "Stop fishing: as the game's stop key (line wears, None, FishingFinished)")
m2.state, m2.changed = m2.states.Idle, nil
local ms = {}
FT.DO.cast(p, ms, {})
ok(m2.changed == "Cast", "Cast from the game's Idle state (aimed at water): the game's Cast state")
m2.state, m2.changed = m2.states.None, nil
FT.DO.cast(p, ms, {})
ok(m2.changed == nil and ms.msg == "UI_ZeD_Fish_AimFirst", "Cast not aimed: no blind cast, the band says to aim first")

-- ---------------------------------------------------------------------------
-- DRAWING: every state and the wall run their draw code against a counting panel (no picture is checked,
-- only that nothing errors and the stops come out), at the 4K scale and the Deck's
-- ---------------------------------------------------------------------------
local drawn = 0
local function panel()
    local pn = {}
    for _, f in ipairs({ "drawRect", "drawText", "drawTextureScaledAspect", "drawTextureScaled", "setStencilRect", "clearStencilRect", "drawRectBorder" }) do
        pn[f] = function() drawn = drawn + 1 end
    end
    pn.getMouseX = function() return -1 end
    pn.getMouseY = function() return -1 end
    pn.getWidth = function() return 900 end
    pn.getHeight = function() return 1200 end
    return pn
end
local function col(r) return { r = r, g = r, b = r, a = 1 } end
local function tokens(scale)
    local T = { px = function(n) return math.floor(n * scale + 0.5) end, hair = 1, buttonH = math.floor(24 * scale), fillBarH = 6,
                sp = { scrollbarW = math.floor(12 * scale) }, fontF1 = "f1", fontF2 = "f2", fontF3 = "f3", fontF4 = "f4", fontF5 = "f5" }
    for _, n in ipairs({ "text", "textDim", "textHead", "textSec", "accent", "accentText", "danger", "positive", "warning", "hover",
                         "border", "borderS", "textOnFocus", "textOnAccent", "base" }) do T[n] = col(0.5) end
    return T
end
ZeD.TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 7 end, getFontHeight = function() return 14 end }
ZeD.Surface = { fill = function() drawn = drawn + 1 end }
ZeD.Help = { set = function() end }
ZeD.Atoms = setmetatable({
    wrapText = function(s) return { s } end, truncateText = function(s) return s end, tagW = function(s) return #s * 7 + 12 end,
    radioSize = function() return 12 end, mouseIn = function() return false end,
}, { __index = function() return function() drawn = drawn + 1; return 0 end end })
ZeD.Molecules = setmetatable({
    getTabHeaderH = function() return 37 end, getTabPad = function() return 8 end, bandH = function() return 34 end,
    buttonW = function(s) return #s * 7 + 20 end,
    drawSectionHeader = function(_, _, _, _, _, _, _, _, _, _, _, h) return h or 20 end,
    drawBand = function(_, x, y, w, spec)
        local out = { buttons = {}, lead = {} }
        for i, b in ipairs(spec.buttons or {}) do out.buttons[i] = { x = x + w - i * 90, y = y + 5, w = 80, h = 24, id = b.id } end
        for i, b in ipairs(spec.lead or {}) do out.lead[i] = { x = x + i * 90, y = y + 5, w = 80, h = 24, id = b.id } end
        return 34, out
    end,
    drawCardBackBar = function(_, x, y, w, name, v, pa, c, rects) rects.back = { x = x + 6, y = y + 6, w = 24, h = 24 }; return 37 end,
}, { __index = function() return function() drawn = drawn + 1; return 0 end end })
ZeD.Px = { canvas = function(el, ox, oy, k) return { el = el, ox = ox, oy = oy, k = k } end,
           rects = function(cv, list) drawn = drawn + #list / 4 end, color = function() return col(0.4) end }
local win = { _playerObj = p }
p.lv = 6
local function renderState(label, scale)
    ZeD.T = tokens(scale)
    local okR, err = pcall(FT.render, panel(), win, 0, 0, math.floor(480 * scale), math.floor(700 * scale))
    ok(okR, label .. ": the tab draws (" .. tostring(err) .. ")")
    local stops = FT.buildFocusables(win)
    ok(#stops > 0, label .. ": the controller has stops")
    return stops
end
for _, sc in ipairs({ 1.75, 0.74 }) do
    local tag = (sc > 1) and "4K" or "Deck"
    Fishing.ManagerInstances[0] = nil
    p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm"), item("Base.Cricket") }; L._resetCarry()
    win._fishTab = nil
    local stops = renderState(tag .. " ready", sc)
    local function hasId(id) for _, e in ipairs(stops) do if e.id == id then return e end end end
    ok(hasId("fish:b:cast") and hasId("fish:b:cast").isPrimary and hasId("fish:wall") and hasId("fish:bait:Base.Cricket"), tag .. " ready: Cast (primary), the wall key and the bait rows are stops")
    hasId("fish:bait:Base.Cricket").onActivate(win)
    ok(win._fishTab.sel == "Base.Cricket", tag .. ": A on a bait row picks it")
    win._fishTab.fold = true
    renderState(tag .. " ready, fold open", sc)
    Fishing.ManagerInstances[0] = mgr
    mgr.fishingRod.rodItem = p.prim
    bob.fish = nil
    renderState(tag .. " wait", sc)
    bob.fish = { isTrash = false }
    mgr.fishingRod.getTension = function() return 0.86 end
    renderState(tag .. " fight", sc)
    Fishing.ManagerInstances[0] = nil
    p.prim = rodItem(nil); p.inv = {}; L._resetCarry()
    renderState(tag .. " nobait", sc)
    p.prim = nil
    renderState(tag .. " norod", sc)
    -- the wall
    p.prim = rodItem("Base.Worm")
    FT.press(win, "wall")
    ok(win._fishTab.wall ~= nil and win._fishTab.wall.mode == "top", tag .. ": the Trophy wall key opens the wall on Top 10")
    stops = renderState(tag .. " wall, Top 10", sc)
    ok(#win._fishTab.wall.plaques == 10, tag .. " wall: ten plaques")
    local plq, back = nil, nil
    for _, e in ipairs(stops) do if e.id == "fish:plq:3" then plq = e end; if e.id == "fish:wb:foot" then back = e end end
    ok(plq and back and back.isPrimary and plq.onCancel, tag .. " wall: plaques and Back are stops; B backs out from a plaque")
    plq.onActivate(win)
    ok(win._fishTab.wall.sel == 3, tag .. " wall: A on a plaque shows its record")
    for _, e in ipairs(stops) do if e.id == "fish:wm:each" then e.onActivate(win) end end
    renderState(tag .. " wall, Each kind", sc)
    ok(#win._fishTab.wall.plaques == 21, tag .. " wall: Each kind hangs 21")
    plq.onCancel(win)
    ok(win._fishTab.wall == nil, tag .. " wall: B returns to the tab")
end
ok(drawn > 1000, "the draw code drew (" .. drawn .. " calls)")

print(string.format("fishing_tab_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
