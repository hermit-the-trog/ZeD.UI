-- ZeDUI/tools/qa/fix_fishing_sim.lua (Nov 2026): the Fishing tab's fixes, checked with no game running.
-- The engine stubs of fishing_tab_sim.lua (the game's fishing tables, its manager and rod, the player), plus counters
-- on the game calls that cost the most, a stand-in for the controller (ZeD.Input.Focus) and the real SpatialNav.lua.
-- The real FishingLog.lua, FishingWall.lua and FishingTab.lua run against them. Checks:
--   species found     junk the game writes into its caught record is not counted as a species
--   XP to the next    the Skills tab is asked with the perk's own (translated) name
--   remove bait       the bait on the hook stays pickable when none of its kind is left in the bags
--   clear log         the question goes when the line's state moves on (a cast made with the game's keys)
--   this trip         a trip that went quiet is not shown as this trip; its start time reads to the minute
--   per frame         the bags, the shore test and the item names are not read again every frame
--   hold A            A held on Reel in keeps the line coming in for as long as it is held
--   pad scroll        at the Deck's size the D-pad brings every part of the list into view, the log's last rows and
--                     More detail's facts too, and walks the list's stops in order
-- Run from the repo root:  lua.exe ZeDUI/tools/qa/fix_fishing_sim.lua   (prints FAIL lines and a last summary line)
-- An optional first argument is a folder to load the mod's Lua from instead (an older copy, to see the checks fail).

local ROOT = (arg and arg[1]) or ""
local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. m) end end

-- ---------------------------------------------------------------------------
-- THE ENGINE, STUBBED (as fishing_tab_sim.lua), WITH COUNTERS
-- ---------------------------------------------------------------------------
local clockMs = 100000
local count = { walks = 0, shore = 0, names = 0 }
function getTimestampMs() return clockMs end
function isMultiplayer() return false end
function isMouseButtonDown() return false end
ItemTag = { FISHING_ROD = "FishingRod" }
-- (the perk as the game holds it: an object whose name is translated; a German game here)
Perks = { Fishing = { getName = function() return "Angeln" end } }
IsoFlagType = { water = "water" }
ArrayList = { new = function() return {} end }
function instanceof(o, c) return o and o._class == c end
function getText(k) return k end
function getItemNameFromFullType(ft) count.names = count.names + 1; return (ft or ""):gsub("^Base%.", "") end
function getTexture() return nil end
function getScriptManager() return { FindItem = function() return nil end } end
function getSoundManager() return { playUISound = function() end } end
function getPlayer() return _G.P end
function getClimateManager() return { getWindPower = function() return 0.1 end } end
Events = setmetatable({}, { __index = function(t, k) local e = { list = {} }; function e.Add(f) e.list[#e.list + 1] = f end; rawset(t, k, e); return e end })
require = function() end

local GT = { yr = 1993, mo = 6, dy = 24, hr = 5, mn = 41, wa = 500.7 }
function getGameTime()
    return { getYear = function() return GT.yr end, getMonth = function() return GT.mo end, getDay = function() return GT.dy end,
             getHour = function() return GT.hr end, getMinutes = function() return GT.mn end,
             getWorldAgeHours = function() return GT.wa end, getTimeOfDay = function() return GT.hr + GT.mn / 60 end }
end

local WATER = {}
function getCell()
    return { getGridSquare = function(_, x, y, z)
        return { getProperties = function() return { has = function(_, f) return WATER[x .. "," .. y] == true end } end }
    end }
end

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
    function it:getTex() return nil end
    return it
end
local function rodItem(lure) return item("Base.FishingRod", { tags = { FishingRod = true }, md = { fishing_Lure = lure, fishing_LineType = "Base.FishingLine", fishing_LineCondition = 0.82, fishing_HookType = "Base.FishingHook" } }) end

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
            count.walks = count.walks + 1
            local list = me.inv
            return { size = function() return #list end, get = function(_, i) return list[i + 1] end }
        end }
    end
    return p
end

ZeD = { tr = function(k, ...) local a = { ... }; local s = k; for i = 1, select("#", ...) do s = s .. "|" .. tostring(a[i]) end; return s end,
        logOnce = function(_, e) print("logOnce " .. tostring(e)) end, textCase = function(s) return s end, T = { px = function(n) return n end } }
local SPECIES = { "LargemouthBass", "SmallmouthBass", "WhiteBass", "SpottedBass", "StripedBass", "Bluegill", "WhiteCrappie",
    "BlackCrappie", "RedearSunfish", "YellowPerch", "Sauger", "GreenSunfish", "Walleye", "FreshwaterDrum", "BlueCatfish",
    "ChannelCatfish", "FlatheadCatfish", "Muskellunge", "AligatorGar", "Paddlefish", "BaitFish" }
Fishing = { fishes = {}, ManagerInstances = {},
            lure = { Worms = { ["Base.Worm"] = {} }, Insect = { ["Base.Cricket"] = {}, ["Base.Grasshopper"] = {} },
                     ArtificalLure = { ["Base.JigLure"] = {}, ["Base.MinnowLure"] = {} } },
            trashItems = { "Base.Seaweed", "Base.TinCanEmpty", "Base.WaterBottleEmpty" } }
for _, s in ipairs(SPECIES) do
    Fishing.fishes[#Fishing.fishes + 1] = { itemType = "Base." .. s, lure = { ["Base.Worm"] = 0.5, ["Base.Cricket"] = 0.2 } }
end
function Fishing.IsLure(ft) return ft == "Base.Worm" or ft == "Base.Cricket" or ft == "Base.JigLure" end
function Fishing.IsArtificalLure(ft) return ft == "Base.JigLure" end
function Fishing.isRiver() return true end
Fishing.Utils = {
    skillSizeLimit = { [0] = 1.4, 1.5, 1.9, 2.2, 2.3, 2.8, 4.5, 9, 27, 32, 45 },
    getFishSizeChancesBySkillLevel = function() return 35, 45, 20 end,
    isNearShore = function() count.shore = count.shore + 1; return true end,
    getTimeParams = function() return { coeff = 1.2 } end,
    getTemperatureParams = function() return { coeff = 1 } end,
    getWeatherParams = function() return { isFog = false, isRain = false } end,
    isAccessibleAimDist = function() return true end,
}
Fishing.States = { PickupFish = { start = function() end }, Cast = { start = function() end } }
Fishing.FishingRod = { isReel = function() return false end, isReleaseLine = function() return false end }

-- the game's rod menu calls the tab hands its keys to
local queued = {}
ISInventoryPaneContextMenu = {
    removeLure = function(pn, rod) queued[#queued + 1] = "remove" end,
    addLure = function(pn, rod, it) queued[#queued + 1] = "add:" .. tostring(it and it:getFullType()) end,
    transferIfNeeded = function() queued[#queued + 1] = "transfer" end,
    equipWeapon = function(rod) queued[#queued + 1] = "equip:" .. tostring(rod and rod:getFullType()) end,
}

-- the Skills tab's live XP, keyed as the game names the perk (perk:getName(), translated)
ZeD.SkillsTab = { getPinData = function(p, name) if name == "Angeln" then return { xpPct = 0.42 } end return nil end }

local WW = {}
ZeD_WorldWindow = { addTab = function(def) WW.def = def end, isOpen = function() return false end,
                    isTabShowing = function() return false end, openTab = function() return true end }
ZeD_ScrollbarState = {}
ZeD_ScrollbarState.__index = ZeD_ScrollbarState
function ZeD_ScrollbarState:new() return setmetatable({ scrollPos = 0, visible = false, x = 0, y = 0, width = 9, height = 100 }, ZeD_ScrollbarState) end
function ZeD_ScrollbarState:setBarSize() end
function ZeD_ScrollbarState:draw() end
function ZeD_ScrollbarState:handleMouseDown() end
function ZeD_ScrollbarState:setScrollPos(pos) self.scrollPos = math.max(0, math.min(1, pos)) end

-- the controller, as FocusManager answers the tab: the focused window and stop, and focusWhere over the stops
local PAD = { win = nil, focus = nil, stops = {}, last = nil, aHeld = false }
ZeD.Input = { Focus = {
    getFocusedWindow = function() return PAD.win end,
    getFocusedElement = function() return PAD.focus end,
    isFocused = function(w, z, id) return PAD.focus ~= nil and w == PAD.win and (id == nil or PAD.focus.id == id) end,
    cuesVisible = function() return true end,
    focusWhere = function(w, zone, pred)
        for i, e in ipairs(PAD.stops) do if pred(e, i) then PAD.focus, PAD.last = e, nil; return e end end
        return nil
    end,
    holdingA = function(w) return PAD.aHeld and w == PAD.win end,
} }

-- the real files
dofile(ROOT .. "42/media/lua/client/ZeD/Input/SpatialNav.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/FishingLog.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/FishingWall.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/FishingTab.lua")
local L, FT, N = ZeD.FishingLog, ZeD.FishingTab, ZeD.SpatialNav
ok(L and FT and N, "the files load")
local function resetCarry() if L._resetCarry then L._resetCarry() end end

-- drawing stubs (as fishing_tab_sim.lua), a word wrap and the Deck's scale
local CHAR = 7
local function col(r) return { r = r, g = r, b = r, a = 1 } end
local function tokens(scale)
    local T = { px = function(n) return math.floor(n * scale + 0.5) end, hair = 1, buttonH = math.floor(24 * scale), fillBarH = 6,
                sp = { scrollbarW = math.floor(12 * scale) }, fontF1 = "f1", fontF2 = "f2", fontF3 = "f3", fontF4 = "f4", fontF5 = "f5" }
    for _, n in ipairs({ "text", "textDim", "textHead", "textSec", "accent", "accentText", "danger", "positive", "warning", "hover",
                         "border", "borderS", "textOnFocus", "textOnAccent", "base" }) do T[n] = col(0.5) end
    return T
end
ZeD.TM = { MeasureStringX = function(_, f, s) return #tostring(s) * CHAR end, getFontHeight = function() return 14 end }
ZeD.Surface = { fill = function() end }
ZeD.Help = { set = function() end }
local marks = {}
ZeD.Focus = { mark = function(panel, x, y, w, h, f) marks[#marks + 1] = { x = x, y = y, w = w, h = h }; return false end }
local function wrap(s, font, w)
    local out, cur = {}, ""
    for word in tostring(s):gmatch("%S+") do
        local try = (cur == "") and word or (cur .. " " .. word)
        if #try * CHAR > w and cur ~= "" then out[#out + 1] = cur; cur = word else cur = try end
    end
    if cur ~= "" or #out == 0 then out[#out + 1] = cur end
    return out
end
ZeD.Atoms = setmetatable({ wrapText = wrap, truncateText = function(s) return s end, tagW = function(s) return #s * CHAR + 12 end },
    { __index = function() return function() return 0 end end })
ZeD.Molecules = setmetatable({
    getTabHeaderH = function() return ZeD.T.px(37) end, getTabPad = function() return ZeD.T.px(8) end,
    bandH = function() return ZeD.T.buttonH + 2 * ZeD.T.px(5) end,
    buttonW = function(s) return #s * CHAR + 20 end,
    drawSectionHeader = function() return 20 end,
    -- (the real band's layout: buttons right to left from the edge, the lead keys from the left, 5u down)
    drawBand = function(_, x, y, w, spec)
        local out, T = { buttons = {}, lead = {} }, ZeD.T
        local right = x + w - T.px(8)
        for i = #(spec.buttons or {}), 1, -1 do
            local bw = #spec.buttons[i].label * CHAR + 20
            right = right - bw
            out.buttons[i] = { x = right, y = y + T.px(5), w = bw, h = T.buttonH }
            right = right - T.px(8)
        end
        local left = x + T.px(8)
        for i, b in ipairs(spec.lead or {}) do
            local bw = #b.label * CHAR + 20
            out.lead[i] = { x = left, y = y + T.px(5), w = bw, h = T.buttonH }
            left = left + bw + T.px(8)
        end
        return T.buttonH + 2 * T.px(5), out
    end,
}, { __index = function() return function() return 0 end end })
local function panel()
    local pn = {}
    for _, fn in ipairs({ "drawRect", "drawText", "drawTextureScaledAspect", "drawTextureScaled", "setStencilRect", "clearStencilRect", "drawRectBorder" }) do pn[fn] = function() end end
    pn.getMouseX = function() return -1 end
    pn.getMouseY = function() return -1 end
    pn.getWidth = function() return 4000 end
    pn.getHeight = function() return 4000 end
    return pn
end

local p = player()
_G.P = p
WATER["104,100"] = true
L._resetScan()
local SCALE, TW, TH = 0.74, math.floor(480 * 0.74), math.floor(560 * 0.74)   -- the Deck: a 480 x 560 tab at 0.74
ZeD.T = tokens(SCALE)
local function newWin() local w = { _playerObj = p }; PAD.win, PAD.focus, PAD.last = w, nil, nil; return w end
local function frame(w)
    local okR, err = pcall(FT.render, panel(), w, 0, 0, TW, TH)
    if not okR then ok(false, "the tab draws: " .. tostring(err)) end
    PAD.stops = FT.buildFocusables(w)
    if PAD.focus then
        local id = PAD.focus.id
        PAD.focus = nil
        for _, e in ipairs(PAD.stops) do if e.id == id then PAD.focus = e end end
    end
    return PAD.stops
end
local function settle(w) frame(w); frame(w); frame(w) end
local function byId(id) for _, e in ipairs(PAD.stops) do if e.id == id then return e end end end
local function has(list, k, pred) for _, it in ipairs(list) do if it.k == k and (not pred or pred(it)) then return it end end end
local function ids(b) local t = {}; for _, x in ipairs(b.buttons) do t[#t + 1] = x.id end; return table.concat(t, ",") end
local function fishItem(sp, wt) return item("Base." .. sp, { name = sp, wt = wt, md = { fishing_FishSize = 20 } }) end
local function land(fi, trash)
    local fr = { rodItem = p.prim or rodItem("Base.Worm"), bobber = { lure = "Base.Worm", fish = fi and { fishItem = fi, isTrash = trash } or nil,
                 getX = function() return 104 end, getY = function() return 100 end } }
    Fishing.States.PickupFish.start({ manager = { player = p, fishingRod = fr } })
end
L.install()

-- ---------------------------------------------------------------------------
-- SPECIES FOUND: the game writes junk into its caught record too (every pick-up)
-- ---------------------------------------------------------------------------
p.md.fishing_catchedFish = { ["Base.Bluegill"] = true, ["Base.LargemouthBass"] = true, ["Base.YellowPerch"] = true,
                             ["Base.Seaweed"] = true, ["Base.TinCanEmpty"] = true, ["Base.WaterBottleEmpty"] = true }
ok(L.caughtCount(p) == 3, "species found: 3 species and 3 kinds of junk count 3 (" .. L.caughtCount(p) .. ")")
p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm") }; resetCarry()
land(fishItem("Bluegill", 0.4), false)
local st = { fold = false }
local s = FT.snap(p, st)
local sp = has(FT.build(s, st), "fact", function(it) return it.label == "UI_ZeD_Fish_TripSpecies" end)
ok(sp and sp.value == "UI_ZeD_Fish_NOfM|3|21", "this trip: Species found reads 3 of 21 (" .. tostring(sp and sp.value) .. ")")

-- ---------------------------------------------------------------------------
-- XP TO THE NEXT LEVEL: asked by the perk's own name, as the Skills tab keys it
-- ---------------------------------------------------------------------------
ok(math.abs((s.xpPct or 0) - 0.42) < 1e-9, "XP to the next level read in a German game (" .. tostring(s.xpPct) .. ")")

-- ---------------------------------------------------------------------------
-- REMOVE BAIT: the only Jig Lure on the hook, none left in the bags
-- ---------------------------------------------------------------------------
p.prim = rodItem("Base.JigLure"); p.inv = {}; resetCarry()
st = { fold = false }
s = FT.snap(p, st)
ok(s.state == "ready" and s.sel == "Base.JigLure", "the lure on the hook, bags empty: ready, the hook's lure picked (" .. tostring(s.sel) .. ")")
local items = FT.build(s, st)
ok(has(items, "bait", function(it) return it.r.type == "Base.JigLure" and it.on and it.sel and it.r.n == 0 end),
   "the hook's lure has a row of its own: on the hook, picked, none in the bags")
local bk = FT.band(s, st).buttons[1]
ok(bk.label == "UI_ZeD_Fish_RemoveBait" and not bk.disabled, "the bait key takes it off: Remove bait, enabled (" .. bk.label .. ")")
queued = {}
FT.DO.bait(p, st, s)
ok(table.concat(queued, ",") == "remove", "Remove bait queues the game's Remove Bait only (" .. table.concat(queued, ",") .. ")")
-- the lure on the hook, two crickets in the bags
p.inv = { item("Base.Cricket"), item("Base.Cricket") }; resetCarry()
st = { fold = false }
s = FT.snap(p, st)
ok(s.sel == "Base.JigLure" and FT.band(s, st).buttons[1].label == "UI_ZeD_Fish_RemoveBait", "with crickets in the bags the hook's lure stays the pick: Remove bait")
items = FT.build(s, st)
ok(has(items, "bait", function(it) return it.r.type == "Base.JigLure" end) and has(items, "bait", function(it) return it.r.type == "Base.Cricket" and it.r.n == 2 end),
   "both rows: the hook's lure and the crickets")
st.sel = "Base.Cricket"
s = FT.snap(p, st)
ok(FT.band(s, st).buttons[1].label == "UI_ZeD_Fish_ChangeBait", "the crickets picked: Change bait")
queued = {}
FT.DO.bait(p, st, s)
ok(table.concat(queued, ",") == "remove,add:Base.Cricket", "Change bait: Remove Bait, then Add Bait with a cricket (" .. table.concat(queued, ",") .. ")")
st.sel = "Base.JigLure"
ok(FT.band(FT.snap(p, st), st).buttons[1].label == "UI_ZeD_Fish_RemoveBait", "the hook's row picked again: Remove bait")
-- the crickets picked, then gone from the bags before the key is pressed: the hook keeps its lure
st.sel = "Base.Cricket"
s = FT.snap(p, st)
p.inv = {}
queued = {}
FT.DO.bait(p, st, s)
ok(#queued == 0, "the picked bait left the bags: nothing is taken off the hook (" .. table.concat(queued, ",") .. ")")
-- the controller can stop on the hook's row
local w = newWin()
p.inv = {}; resetCarry()
frame(w)
ok(byId("fish:bait:Base.JigLure") ~= nil, "the hook's row is a controller stop")

-- ---------------------------------------------------------------------------
-- CLEAR LOG: the question belongs to the state it was asked in
-- ---------------------------------------------------------------------------
p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm") }; resetCarry()
w = newWin()
frame(w)
FT.press(w, "clear")
ok(w._fishTab.ask == "clear" and ids(FT.band(w._fishTab.s, w._fishTab)) == "cancel,clearyes", "Clear log asks first")
local mgr = { player = p, states = { Idle = {}, None = {} } }
mgr.state = mgr.states.Idle
local bob = { lure = "Base.Worm", getX = function() return 106 end, getY = function() return 97 end }
mgr.fishingRod = { rodItem = p.prim, bobber = bob, tensionLimit = 180, highTensionTimer = 0, getTension = function() return 0.3 end }
Fishing.ManagerInstances[0] = mgr
frame(w)
ok(w._fishTab.s.state == "wait" and ids(FT.band(w._fishTab.s, w._fishTab)) == "stop,reel", "cast with the game's keys: the band holds Stop fishing and Reel in again")
bob.fish = { isTrash = false }
frame(w)
ok(ids(FT.band(w._fishTab.s, w._fishTab)) == "stop,release,reel", "a fish on: Stop, Let out line, Reel in")
Fishing.ManagerInstances[0] = nil
bob.fish = nil
frame(w)
ok(w._fishTab.s.state == "ready" and w._fishTab.ask == nil, "back to ready: the question does not come back")
FT.press(w, "clear")
frame(w)
ok(w._fishTab.ask == "clear", "asked in ready and still in ready: the question stays")
FT.press(w, "cancel")

-- ---------------------------------------------------------------------------
-- THIS TRIP: a trip that went quiet is over; its start reads to the minute
-- ---------------------------------------------------------------------------
L.clearLog(p)
GT.wa, GT.hr, GT.mn = 500 + 6 + 10 / 60, 6, 10   -- Monday, 06:10: a cast
Fishing.States.Cast.start({ manager = { player = p, fishingRod = { rodItem = p.prim } } })
for i = 1, 5 do land(fishItem("Bluegill", 0.3 + i / 10), false) end
st = { fold = false }
s = FT.snap(p, st)
ok(has(FT.build(s, st), "head", function(it) return it.text == "UI_ZeD_Fish_TripHead" end), "Monday at the water: this trip shows")
GT.wa, GT.hr, GT.mn = 500 + 4 * 24 + 10, 10, 0   -- Friday 10:00, rod in hand, no cast yet
s = FT.snap(p, st)
ok(not has(FT.build(s, st), "head", function(it) return it.text == "UI_ZeD_Fish_TripHead" end), "Friday, rod in hand: Monday's trip is not this trip")
p.prim = nil; p.inv = { rodItem("Base.Worm") }; resetCarry()
s = FT.snap(p, st)
ok(s.state == "norod" and not has(FT.build(s, st), "head", function(it) return it.text == "UI_ZeD_Fish_TripHead" end), "Friday, no rod in hand: no trip either")
p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm") }; resetCarry()
GT.wa, GT.hr, GT.mn = 500 + 6 + 10 / 60 + 2.5, 8, 40   -- Monday, two and a half hours on: the trip goes on
s = FT.snap(p, st)
local th = has(FT.build(s, st), "head", function(it) return it.text == "UI_ZeD_Fish_TripHead" end)
ok(th ~= nil, "Monday, 2.5 quiet hours: still this trip")
ok(th and th.right == "UI_ZeD_Fish_TripSince|06:10", "the trip's start reads 06:10 (" .. tostring(th and th.right) .. ")")
ok(FT.hhmmAgo(GT.wa - 1 / 60) == "08:39" and FT.hhmmAgo(GT.wa - (8 + 40 / 60)) == "00:00" and FT.hhmmAgo(GT.wa - 9) == "23:40",
   "clock times from game hours: a minute ago, midnight, the evening before")

-- ---------------------------------------------------------------------------
-- PER FRAME: the bags, the shore test and the item names are not read again every frame
-- ---------------------------------------------------------------------------
GT.wa, GT.hr, GT.mn = 500.7, 5, 41
L.clearLog(p)
local function frames(w, n, stepMs)
    for _ = 1, n do clockMs = clockMs + (stepMs or 40); frame(w) end
end
p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm"), item("Base.Cricket") }; resetCarry()
w = newWin()
frame(w)
count.walks, count.shore, count.names = 0, 0, 0
frames(w, 10)
ok(count.walks <= 1, "ready, ten frames in 400 ms: the bags walked at most once (" .. count.walks .. ")")
ok(count.shore <= 1, "ready, ten frames: the shore test at most once (" .. count.shore .. ")")
count.walks = 0
frames(w, 1, 600)
ok(count.walks == 1, "after half a second the bags are read again (" .. count.walks .. ")")
p.prim = nil; p.inv = { rodItem("Base.Worm") }; resetCarry()
w = newWin()
frame(w)
ok(w._fishTab.s.state == "norod" and ids(FT.band(w._fishTab.s, w._fishTab)) == "equip", "no rod in hand, one in the bags: Equip rod")
count.walks = 0
frames(w, 10)
ok(count.walks <= 2, "no rod in hand, ten frames: the bags walked at most twice (" .. count.walks .. ")")
queued = {}
count.walks = 0
FT.press(w, "equip")
ok(count.walks == 1 and queued[#queued] == "equip:Base.FishingRod", "Equip rod reads the bags fresh and equips the rod (" .. count.walks .. ")")
p.prim = rodItem(nil); p.inv = {}; resetCarry()
w = newWin()
frame(w)
ok(w._fishTab.s.state == "nobait", "a bare hook, no bait: nobait")
count.names = 0
frames(w, 10)
ok(count.names == 0, "nobait, ten frames: no item name looked up again (" .. count.names .. ")")

-- ---------------------------------------------------------------------------
-- HOLD A ON REEL IN: the line comes in for as long as A is held
-- ---------------------------------------------------------------------------
p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm") }; resetCarry()
mgr.fishingRod.rodItem = p.prim
bob.fish = { isTrash = false }
Fishing.ManagerInstances[0] = mgr
w = newWin()
frame(w)
local reel = byId("fish:b:reel")
ok(reel and reel.onHoldActivate, "fight: Reel in answers a held A")
PAD.focus, PAD.aHeld = reel, true
reel.onHoldActivate(w)
ok(L.pulling() == "reel", "the hold starts the pull")
frames(w, 15, 100)   -- A held 1.5 s more
ok(L.pulling() == "reel", "A still held 1.5 s on: still reeling (" .. tostring(L.pulling()) .. ")")
PAD.aHeld = false
frame(w)
clockMs = clockMs + 300
ok(L.pulling() == nil and w._fishTab.padHold == nil, "A let go: the pull ends within a moment")
-- held, then the focus moves off the key: the pull ends
PAD.focus, PAD.aHeld = byId("fish:b:reel"), true
byId("fish:b:reel").onHoldActivate(w)
PAD.focus = byId("fish:b:stop")
frames(w, 7, 100)
ok(L.pulling() == nil and w._fishTab.padHold == nil, "the focus moved off Reel in: the hold's first pull runs out, not renewed")
PAD.aHeld = false
-- a tap is one short pull
PAD.focus = byId("fish:b:release")
byId("fish:b:release").onActivate(w)
ok(L.pulling() == "release", "a tap on Let out line: a short pull")
frames(w, 7, 100)
ok(L.pulling() == nil, "a tap stays one short pull")
Fishing.ManagerInstances[0] = nil
bob.fish = nil

-- ---------------------------------------------------------------------------
-- PAD SCROLL: the D-pad as FocusManager runs it (the stop's own onDpadDir first, then back the way it came, then the
-- nearest stop that way by SpatialNav, lined up first) at the Deck's size
-- ---------------------------------------------------------------------------
local function move(w, dir)
    local f = PAD.focus
    if f and f.onDpadDir then
        local r = f.onDpadDir(w, f, dir)
        if r ~= false then settle(w); return "own" end
    end
    local OPP = { up = "down", down = "up", left = "right", right = "left" }
    if f and PAD.last and PAD.last.dir == OPP[dir] and PAD.last.to == f.id then
        local e = byId(PAD.last.from)
        if e then PAD.last = { from = f.id, to = e.id, dir = dir }; PAD.focus = e; settle(w); return "back" end
    end
    local best, bt, bc
    for _, e in ipairs(PAD.stops) do
        if e ~= f then
            local t, c = N.cost(f, e, dir)
            if t and (bt == nil or t < bt or (t == bt and c < bc)) then best, bt, bc = e, t, c end
        end
    end
    if not best then return nil end
    PAD.last = { from = f.id, to = best.id, dir = dir }
    PAD.focus = best
    settle(w)
    return "spatial"
end
-- every list row the pad brings fully into view, walking up to the top and down to the band from where it lands
local function walk(label, opts)
    local w = newWin()
    frame(w)
    local tab = w._fishTab
    if opts and opts.fold then tab.fold = true; frame(w) end
    local seen, path = {}, {}
    local function record()
        for i, it in ipairs(tab.items) do
            if it.y >= tab.off and it.y + it.h <= tab.off + tab.sh then seen[i] = true end
        end
        path[#path + 1] = tostring(PAD.focus and PAD.focus.id) .. "@" .. tostring(tab.off)
    end
    PAD.focus = byId(WW.def.landOn(w))
    settle(w); record()
    local ups = 0
    for _ = 1, 60 do if not move(w, "up") then break end; ups = ups + 1; record() end
    -- (Up ends on the list's first stop: it never goes round through the scroll bar again)
    ok(ups < 60 and PAD.focus and PAD.focus.listIdx == 1, label .. ": Up comes to rest on the list's first stop (" .. tostring(PAD.focus and PAD.focus.id) .. ")")
    for _ = 1, 120 do if not move(w, "down") then break end; record() end
    local never = {}
    for i, it in ipairs(tab.items) do if not seen[i] then never[#never + 1] = it.k .. "#" .. i end end
    ok(#never == 0, label .. ": every row comes into view (never: " .. table.concat(never, ",") .. ")")
    return w, path
end
-- no rod in hand, twenty in the log
p.prim = nil; p.inv = { rodItem("Base.Worm") }; resetCarry()
L.clearLog(p)
for i = 1, 20 do land(fishItem("Bluegill", 0.2 + i / 10), false) end
L.data(p).trip = nil
w = walk("no rod in hand, 20 in the log")
ok(PAD.focus and PAD.focus.id == "fish:b:equip", "the walk down ends on the band's Equip rod (" .. tostring(PAD.focus and PAD.focus.id) .. ")")
ok(w._fishTab.scroll.scrollPos >= 1, "and the list was scrolled to its end on the way")
-- from the band, Up goes back onto the scroll bar; Up there scrolls the list back a row at a time
ok(move(w, "up") and PAD.focus.id == "fish:scroll", "Up from the band: back on the scroll bar (" .. tostring(PAD.focus and PAD.focus.id) .. ")")
local pos0 = w._fishTab.scroll.scrollPos
move(w, "up")
ok(PAD.focus.id == "fish:scroll" and w._fishTab.scroll.scrollPos < pos0, "Up on the scroll bar scrolls the list back")
marks = {}
frame(w)
local sc = w._fishTab.scroll
ok(#marks == 1 and marks[1].x == sc.x and marks[1].h == sc.height, "the controller's mark is on the scroll bar")
ok(PAD.focus.extraPrompts and #PAD.focus.extraPrompts == 1, "the help line says D-pad Scroll")
-- the ready state: a worm, a cricket, twenty in the log; the fold opened
p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm"), item("Base.Cricket") }; resetCarry()
local path
w, path = walk("ready, 20 in the log", { fold = true })
ok(PAD.focus and PAD.focus.id == "fish:b:cast", "the walk down ends on Cast (" .. tostring(PAD.focus and PAD.focus.id) .. ")")
-- from Cast with the list at its top, Up reaches the list's stops (the scroll bar first, lined up over Cast's end)
w = newWin()
frame(w)
PAD.focus = byId("fish:b:cast")
settle(w)
move(w, "up")
if PAD.focus and PAD.focus.id == "fish:scroll" then move(w, "up") end
ok(PAD.focus and PAD.focus.listIdx ~= nil and w._fishTab.off == 0,
   "Up from Cast reaches a list stop within two presses, the list still at its top (" .. tostring(PAD.focus and PAD.focus.id) .. ")")
-- the list's stops in order: down from the wall key to the fold, though twenty rows apart
w = newWin()
frame(w)
PAD.focus = byId("fish:bait:Base.Cricket")
settle(w)
marks = {}
frame(w)
ok(#marks == 1 and marks[1].y == PAD.focus.y, "the pad on a bait row: the mark on that row only, none on the log's rows (" .. #marks .. " marks)")
PAD.focus = byId("fish:wall")
settle(w)
move(w, "down")
ok(PAD.focus and PAD.focus.id == "fish:fold", "Down from the wall key: the fold, twenty rows on (" .. tostring(PAD.focus and PAD.focus.id) .. ")")
move(w, "up")
ok(PAD.focus and PAD.focus.id == "fish:wall", "Up from the fold: the wall key")
-- the line in the water, More detail open: the bait rows locked, the wall key and the fold the list's stops
mgr.fishingRod.rodItem = p.prim
bob.fish = nil
Fishing.ManagerInstances[0] = mgr
w = walk("line in the water, More detail open", { fold = true })
ok(w._fishTab.s.state == "wait" and PAD.focus and PAD.focus.id == "fish:b:reel", "the walk down ends on Reel in (" .. tostring(PAD.focus and PAD.focus.id) .. ")")
Fishing.ManagerInstances[0] = nil
-- no bait: the log's rows under the wall key
p.prim = rodItem(nil); p.inv = {}; resetCarry()
walk("no bait, 3 in the log")
-- a fresh game: the log empty, the fold opened, every fact of More detail
p.prim = rodItem("Base.Worm"); p.inv = { item("Base.Worm"), item("Base.Cricket") }; resetCarry()
L.clearLog(p)
L.data(p).trip = nil
walk("ready, empty log, More detail open", { fold = true })
-- a list that fits: no scroll stop, Down from the last stop goes straight to the band
TH = math.floor(1400 * SCALE)
w = newWin()
frame(w)
ok(byId("fish:scroll") == nil, "a list that fits has no scroll stop")
PAD.focus = byId("fish:fold")
settle(w)
move(w, "down")
ok(PAD.focus and PAD.focus.id:sub(1, 7) == "fish:b:", "Down from the last stop: the band (" .. tostring(PAD.focus and PAD.focus.id) .. ")")

print(string.format("fix_fishing_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
