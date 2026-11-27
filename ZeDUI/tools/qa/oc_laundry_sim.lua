-- ZeDUI/tools/qa/oc_laundry_sim.lua  (Nov 26 2026, Build): QA's laundry card bugs from the Nov 26 card map
-- (ZeDUI/qa/audits/2026-11-26_map_cards_lock_medic_rest.md, LA sections), with no game running. The real
-- ObjectCardLaundry.lua runs on Lua 5.1 with a forgiving stand-in for everything else (a global or field nobody set
-- is a stand-in that takes any call) and small fakes of a washer, its drum, the player and the game's queue.
--   LA1  Power pressed twice from 4 tiles (a double click, or the pad's A A: both run the zone's own run) queues
--        one walk and one toggle, not two of each; while that chain is queued every control is greyed with
--        "Needs the action under way to finish"; the pop-out (its own target, the same machine) shares the gate;
--        once the chain is done Power works again
--   LA2  the clothes inside read in the game's tooltip words (Tooltip_clothing_bloody / _dirty / _wet) with the
--        tooltip's thresholds; no made-up RINSE / SPIN lamp however long it runs; the dial reads the load's
--        progress; the Simple form's big word is Running, not a phase
--   LA4  Door from past the loot window's reach walks over first and shows the drum at the end; with no way there
--        it says "Too far away from" the machine; in reach it shows at once
-- Each check fails on the code before this work.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_laundry_sim.lua
-- It prints FAIL lines and a last line "oc_laundry_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_laundry_sim%.lua$", "")
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

local noop = function() end
local HOURS = 100
function getTimestampMs() return 1000000 end
function getGameSpeed() return 1 end
function getGameTime() return { getWorldAgeHours = function() return HOURS end } end
function getText(k, a) if a ~= nil then return k .. "(" .. tostring(a) .. ")" end return k end
function getTextOrNull() return nil end
function instanceof(o, cls) return type(o) == "table" and o._class == cls end
function require() return true end

-- the game's queue: one list, read through getTimedActionQueue as the game's is
local QUEUE = {}
local QO = { queue = QUEUE }
ISTimedActionQueue = { add = function(a) QUEUE[#QUEUE + 1] = a end, getTimedActionQueue = function() return QO end,
                       clear = noop }
local function clearQueue() for i = #QUEUE, 1, -1 do QUEUE[i] = nil end end
local function kinds()
    local l = {}
    for _, a in ipairs(QUEUE) do l[#l + 1] = a.kind or a.Type or "?" end
    return table.concat(l, ",")
end
ISBaseTimedAction = {
    derive = function(self, name) local c = { Type = name }; c.__index = c; return setmetatable(c, { __index = self }) end,
    new = function(cls, ch) return setmetatable({ character = ch }, cls) end,
    perform = noop, stop = noop,
}
local WALK = "far"   -- "far": a walk is queued; "near": already beside it; "none": no way there
luautils = { walkAdj = function(p, sq)
    if WALK == "none" then return false end
    if WALK == "far" then ISTimedActionQueue.add({ kind = "walk" }) end
    return true
end }
local function action(kind) return { new = function(self, p, o) return { kind = kind, obj = o } end } end
ISToggleClothingWasher = action("toggle")
ISToggleClothingDryer = action("toggleDryer")
ISToggleComboWasherDryer = action("toggleCombo")
ISWorldObjectContextMenu = { getMoveableDisplayName = function() return "Washer" end,
    onSetComboWasherDryerMode = function(p, o, mode) ISTimedActionQueue.add({ kind = "mode" }) end }
local HALO = {}
local SHOWN = {}
local REACH = false
ZeD_WorldWindow = { selectContainer = function(c) SHOWN[#SHOWN + 1] = c end, inReach = function() return REACH end }

ZeD = setmetatable({}, { __index = function(t, k) return auto() end })
function ZeD.tr(k, a) if a ~= nil then return k .. "(" .. tostring(a) .. ")" end return k end
function ZeD.trBare(k) return k end
function ZeD.trDefaults() end
ZeD.T = setmetatable({ px = function(v) return v end }, { __index = function() return auto() end })
ZeD.paperTone = function(c) return c end
ZeD.Scale = { root = function() return 1 end }

local ROWS, READOUT, PLAIN = {}, nil, false
ZeD.ObjectCardPower = { sayWhy = function(p, why) HALO[#HALO + 1] = why end }
ZeD.ObjectCardPlain = { on = function() return PLAIN end,
    readout = function(card, x, y, w, spec) READOUT = spec; return 10 end,
    row = function(card, x, y, w, spec) ROWS[#ROWS + 1] = spec; return 10 end }

local function ocall(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
local PAIRS = {}
ZeD.ObjectCards = { kinds = {}, call = ocall, LEASH = 6,
    ui = { hovered = function() return false end,
           pairWide = function(card, x, y, w, l, v) PAIRS[#PAIRS + 1] = { l = l, v = v }; return 20 end } }
local OC = ZeD.ObjectCards
function OC.register(def) OC.kinds[def.id] = def end
function OC.keyOf(sq, p) return p .. ":" .. sq:getX() .. "," .. sq:getY() end
function OC.sortTargets(l) return l end
OC.eachSquare, OC.faceZone, OC.spriteIcon = noop, noop, noop

local CONTROLS = { { id = "power", x = 0, y = 0, w = 10, h = 10 }, { id = "door", x = 20, y = 0, w = 10, h = 10 } }
ZeD.Plate = { draw = noop, hoverKey = noop, markKey = noop, centre = function() return 0 end,
    controls = function() return CONTROLS end }
ZeD.Px = { canvas = function() return {} end, tex = noop, rect = noop, color = function() return { r = 0, g = 0, b = 0 } end,
    baseId = function(id) return id end, k = function() return 1 end,
    pick = function(pid) return { w = 100, h = 50, parts = {} }, pid end }
ZeD.PhysPx = { laundry = { classes = { IsoClothingWasher = "washer" } }, plates = { washer = { w = 100, h = 50, parts = {} } },
    widths = {}, narrow = {}, texdir = "" }

-- ---------------------------------------------------------------------------
-- FAKES
-- ---------------------------------------------------------------------------
local function shirt(dirt, blood, wet)
    local c = { _class = "Clothing", dirt = dirt, blood = blood, wet = wet }
    function c:getDirtiness() return self.dirt end
    function c:getBloodLevel() return self.blood end
    function c:getWetness() return self.wet end
    return c
end
local DRUM = {}
local container = { getItems = function() return { size = function() return #DRUM end, get = function(_, i) return DRUM[i + 1] end } end,
                    isPowered = function() return true end, getType = function() return "clothingwasher" end }
local sq = { getX = function() return 14 end, getY = function() return 10 end, getZ = function() return 0 end }
local washer = { _class = "IsoClothingWasher", on = false }
function washer:getSquare() return sq end
function washer:getObjectIndex() return 1 end
function washer:isActivated() return self.on end
function washer:getContainer() return container end
function washer:getFluidAmount() return 10 end
function washer:getFluidCapacity() return 20 end
local player = {}
function player:getPlayerNum() return 0 end

local function newCard()
    local card = { zones = {} }
    function card:zone(z) self.zones[#self.zones + 1] = z end
    function card:focusOf() return nil end
    function card:drawRect() end
    return card
end
local function zoneOf(card, fid)
    for _, z in ipairs(card.zones) do if z.fid == fid then return z end end
    return nil
end

-- (the card defines its door action as "X = X or derive(..)": unset here, not a stand-in)
rawset(_G, "ZeDLaundryDoorAction", false)
local okL, errL = pcall(function() local f = assert(loadfile(CLIENT .. "ObjectCardLaundry.lua")); f() end)
check("ObjectCardLaundry.lua loads", okL, errL)
local LD = ZeD.ObjectCardLaundry
local def = OC.kinds.laundry
check("the laundry kind registers", def ~= nil)
if not (okL and def) then
    print("oc_laundry_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(1)
end

-- a target as the card makes it, its data read, and its face drawn: the zones
local function draw(t)
    def.refresh(t, player)
    local card = newCard()
    PAIRS, ROWS, READOUT = {}, {}, nil
    local ok, err = pcall(def.body, card, 0, 0, 300, t, player)
    if not ok then print("body failed: " .. tostring(err)) end
    return card
end
local function press(t, fid)
    local z = zoneOf(draw(t), fid)
    if z and z.run then z.run(nil, player); return true end
    return false, z and z.help
end

-- ===========================================================================
section("LA1: Power twice from 4 tiles queues one walk and one toggle")
-- ===========================================================================
do
    clearQueue(); WALK = "far"
    local t = def.resolve(player, washer)
    -- a double click, or A A: both presses land before the face has read the queue again
    local card = draw(t)
    local z = zoneOf(card, "ldy:power")
    check("the switch can run", z and z.run ~= nil)
    if z and z.run then z.run(card, player); z.run(card, player) end
    check("two presses in one frame queue walk, toggle", kinds() == "walk,toggle", kinds())
    -- the next frame: every control greyed with why, the pad's A (the same run) does nothing
    local ran, help = press(t, "ldy:power")
    check("while the chain is queued Power has no run", not ran)
    check("Power says it waits for the action under way", help == "UI_ZeD_Craft_BadgeNeeds(UI_ZeD_Fluid_NeedsIdle)", help)
    local ranD, helpD = press(t, "ldy:door")
    check("the Door waits too", not ranD and helpD == "UI_ZeD_Craft_BadgeNeeds(UI_ZeD_Fluid_NeedsIdle)", helpD)
    check("still one walk and one toggle", kinds() == "walk,toggle", kinds())
    -- the pop-out resolves its own target on the same machine: it shares the gate
    local t2 = def.resolve(player, washer)
    local ranP = press(t2, "ldy:power")
    check("the pop-out's Power waits for the card's chain", not ranP)
    check("and queues nothing", kinds() == "walk,toggle", kinds())
    -- the walk and the toggle done: Power works again
    clearQueue(); washer.on = true
    local ranA = press(t, "ldy:power")
    check("after the chain Power runs again", ranA)
    check("and queues one walk and one toggle", kinds() == "walk,toggle", kinds())
    clearQueue(); washer.on = false
end

-- ===========================================================================
section("LA2: the clothes in the game's words, no made-up phases")
-- ===========================================================================
do
    local function pair(l)
        for _, p in ipairs(PAIRS) do if p.l == l then return p.v end end
        return nil
    end
    local t = def.resolve(player, washer)
    DRUM = { shirt(60, 60, 0) }
    washer.on = true
    draw(t)
    check("a bloody shirt reads Bloody 60%", pair("Tooltip_clothing_bloody") == "60%", pair("Tooltip_clothing_bloody"))
    check("and Dirty 60%", pair("Tooltip_clothing_dirty") == "60%", pair("Tooltip_clothing_dirty"))
    check("not wet", pair("Tooltip_clothing_wet") == nil, pair("Tooltip_clothing_wet"))
    -- what the game did to it: dirt 60 -> 0, blood 60 -> 0, wet 0 -> 100
    DRUM = { shirt(0, 0, 100) }
    draw(t)
    check("washed: Wet 100%", pair("Tooltip_clothing_wet") == "100%", pair("Tooltip_clothing_wet"))
    check("washed: no Bloody", pair("Tooltip_clothing_bloody") == nil)
    check("washed: no Dirty", pair("Tooltip_clothing_dirty") == nil)
    -- the tooltip's thresholds: dirt under 1 isn't shown; a little blood is
    DRUM = { shirt(0.5, 0.3, 0) }
    draw(t)
    check("dirt under 1 isn't Dirty", pair("Tooltip_clothing_dirty") == nil)
    check("any blood is Bloody, at least 1%", pair("Tooltip_clothing_bloody") == "1%", pair("Tooltip_clothing_bloody"))
    -- running a long time: never RINSE or SPIN, the game hasn't got them
    DRUM = { shirt(60, 0, 0) }
    local lit = {}
    for m = 0, 60, 1 do
        HOURS = 100 + m / 60
        def.refresh(t, player)
        local st = LD.plateState(t, t.d)
        for _, k in ipairs({ "phRinse", "phSpin", "phCool" }) do if st[k] then lit[k] = true end end
    end
    check("no RINSE lamp in an hour of running", not lit.phRinse)
    check("no SPIN lamp in an hour of running", not lit.phSpin)
    def.refresh(t, player)
    local st = LD.plateState(t, t.d)
    check("WASH is lit while it runs", st.phWash == true)
    check("the dial reads the load: dirt 60 is 0.4 of the way", math.abs((st.cycleF or -1) - 0.4) < 1e-6, st.cycleF)
    DRUM = { shirt(0, 0, 100) }
    def.refresh(t, player)
    st = LD.plateState(t, t.d)
    check("clean: the dial at the end", math.abs((st.cycleF or -1) - 1) < 1e-6, st.cycleF)
    -- the Simple form: Running, not a phase; the clothes' rows there too
    PLAIN = true
    draw(t)
    local big = READOUT and READOUT.cols and READOUT.cols[1] and READOUT.cols[1].big
    check("the Simple form's big word is Running", big == "UI_ZeD_Power_PillRunning", big)
    local wetRow = false
    for _, r in ipairs(ROWS) do if r.label == "Tooltip_clothing_wet" and r.value == "100%" then wetRow = true end end
    check("the Simple form lists Wet 100%", wetRow)
    PLAIN = false
    washer.on = false
    DRUM = {}
end

-- ===========================================================================
section("LA4: Door from 3 tiles walks over, then shows the drum")
-- ===========================================================================
do
    local t = def.resolve(player, washer)
    clearQueue(); SHOWN = {}; HALO = {}
    REACH, WALK = false, "far"
    local ran = press(t, "ldy:door")
    check("the Door can run", ran)
    check("out of reach: nothing shown yet", #SHOWN == 0, #SHOWN)
    check("a walk, then the door's action", kinds() == "walk,ZeDLaundryDoorAction", kinds())
    -- the walk done, beside it now: the action at the end shows it
    local last = QUEUE[#QUEUE]
    REACH = true
    if last and last.perform then last:perform() end
    check("at the end of the walk the drum shows", SHOWN[1] == container)
    -- no way there: a word, not silence
    clearQueue(); SHOWN = {}; HALO = {}
    REACH, WALK = false, "none"
    press(t, "ldy:door")
    check("no way there says Too far away", HALO[1] == "IGUI_TradingUI_TooFarAway(Washer)", HALO[1])
    check("and shows nothing", #SHOWN == 0)
    -- in reach: at once, no walk
    clearQueue(); SHOWN = {}; HALO = {}
    REACH, WALK = true, "near"
    press(t, "ldy:door")
    check("in reach the drum shows at once", SHOWN[1] == container)
    check("with no walk queued", #QUEUE == 0, kinds())
    clearQueue()
end

print("oc_laundry_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
