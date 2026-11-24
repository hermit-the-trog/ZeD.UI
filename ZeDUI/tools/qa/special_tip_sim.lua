-- ZeDUI/tools/qa/special_tip_sim.lua  (Nov 23 2026): the trough and farm plot hover facts in ZeD's look
-- (shared/ZeD/ZeD_SpecialTipHook.lua + client/ZeD/ZeD_SpecialTip.lua) with no game running, on stubs.
--   CAPTURE  the hook keeps the game's two DoSpecialTooltip handlers aside as their files add them; every other Add
--            (a mod's, before the hook loads, between and after the game's files) goes through untouched; a handler
--            from another file is never taken when the file can be read; the hook wraps once
--   MUTE     while ZeD draws, the kept game handlers are not called; in safe mode they are (the game's box is back);
--            the tooltip gets a height only when ZeD has facts (it stays up, invisible); a fact ZeD can't read hands
--            the square back to the game's handler
--   TROUGH   water only, feed only, both empty, the linked half reads its partner, nothing past 13 tiles, nothing
--            while the right button is down
--   FARM     Farming under 3 nothing, 3 water + diseases, 6 + the next phase; a dead plant has its title only (bad);
--            the farming cursor up: nothing; past 6 tiles: nothing; the colors as statuses
--   PLACE    place() never covers the character and stays on the screen, for squares all round the character, at
--            1920x1080 and 1280x800, with the character mid-screen and at the edges
--   FRAMES   the balloon draws while the event fires and goes 2 frames after it stops
-- Run from the repo root: lua51 ZeDUI/tools/qa/special_tip_sim.lua
local LUA = "42/media/lua/"

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end
local function run(path) assert(loadstring(slurp(LUA .. path), path))() end

-- ---------------------------------------------------------------- the stubs
require = function() end
local added = {}
local function freshEvents()
    added = {}
    Events = {
        DoSpecialTooltip = { Add = function(fn) added[#added + 1] = fn end, Remove = function() end },
        OnPreUIDraw = { Add = function() end },
    }
end
local FILES = {}
getFilenameOfClosure = nil
function getText(k) return k end
function round(x, n) local m = 10 ^ (n or 0); return math.floor(x * m + 0.5) / m end
local BAD, GOOD = { r = 0.9, g = 0.2, b = 0.2 }, { r = 0.25, g = 0.85, b = 0.25 }
local function ci(c) return { getR = function() return c.r end, getG = function() return c.g end, getB = function() return c.b end } end
local SW, SH = 1920, 1080
local CORE = { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end, getZoom = function() return 1 end,
               getBadHighlitedColor = function() return ci(BAD) end, getGoodHighlitedColor = function() return ci(GOOD) end }
function getCore() return CORE end
local RIGHT = false
Mouse = { isRightDown = function() return RIGHT end }

-- ---------------------------------------------------------------- CAPTURE
freshEvents()
CFeedingTroughSystem, CFarmingSystem = nil, nil
local modA = function() end
Events.DoSpecialTooltip.Add(modA)                  -- (a mod's shared file before ZeD's)
ZeD = {}
run("shared/ZeD/ZeD_SpecialTipHook.lua")
local ST = ZeD.SpecialTip
ok(Events.DoSpecialTooltip.Add == ST._addWrapper, "CAPTURE the Add is wrapped")
local wrapper = Events.DoSpecialTooltip.Add
ST.hookAdd()
ok(Events.DoSpecialTooltip.Add == wrapper and ST._origAdd ~= wrapper, "CAPTURE wrapped once (a second hookAdd keeps the one wrapper)")
local modB = function() end
Events.DoSpecialTooltip.Add(modB)                  -- (a mod's file before the game's client files)
CFarmingSystem = { instance = nil }               -- (CFarmingSystem.lua: the class, then its Add)
local farmFn = function() end
Events.DoSpecialTooltip.Add(farmFn)
local modC = function() end
Events.DoSpecialTooltip.Add(modC)                  -- (between the two game files)
CFeedingTroughSystem = { instance = nil }
local troughFn = function() end
Events.DoSpecialTooltip.Add(troughFn)
local modD = function() end
Events.DoSpecialTooltip.Add(modD)                  -- (after both)
ok(ST.gameFarm == farmFn and ST.gameTrough == troughFn and ST.captured == 2, "CAPTURE both game handlers kept aside")
ok(#added == 4 and added[1] == modA and added[2] == modB and added[3] == modC and added[4] == modD,
   "CAPTURE every mod's Add went through untouched, in order (" .. #added .. " added)")

-- with the file names readable: a handler from another file is never taken, even in the game file's place
freshEvents()
ZeD = {}
CFeedingTroughSystem, CFarmingSystem = nil, nil
getFilenameOfClosure = function(fn) return FILES[fn] end
run("shared/ZeD/ZeD_SpecialTipHook.lua")
ST = ZeD.SpecialTip
CFeedingTroughSystem, CFarmingSystem = {}, {}
local modE = function() end
FILES[modE] = "C:\\Users\\x\\Zomboid\\Workshop\\SomeMod\\media\\lua\\client\\SomeMod.lua"
Events.DoSpecialTooltip.Add(modE)
local troughFn2 = function() end
FILES[troughFn2] = "E:\\PZ\\media\\lua\\client\\FeedingTrough\\CFeedingTroughSystem.lua"
Events.DoSpecialTooltip.Add(troughFn2)
local farmFn2 = function() end
FILES[farmFn2] = "E:\\PZ\\media\\lua\\client\\Farming\\CFarmingSystem.lua"
Events.DoSpecialTooltip.Add(farmFn2)
ok(#added == 1 and added[1] == modE, "CAPTURE a mod's handler with both classes made goes through (its file is not the game's)")
ok(ST.gameTrough == troughFn2 and ST.gameFarm == farmFn2, "CAPTURE the game's handlers known by their files")
getFilenameOfClosure = nil

-- ---------------------------------------------------------------- the client module
local LOG = {}
ZeD.logOnce = function(k, m) LOG[#LOG + 1] = m end
local SAFE = false
ZeD.Safe = { on = function() return SAFE end }
ZeD.T = { hair = 1, px = function(n) return n end, dangerText = { r = 1 }, positiveText = { g = 1 }, textSec = { b = 1 }, warning = { r = 0.5 } }
local DRAWN = {}
ZeD.Balloon = { TAIL = 10, MARGIN = 4,
    layout = function(c) return { w = 240, h = 120 } end,
    draw = function(p, c, a, side, opts) DRAWN[#DRAWN + 1] = { c = c, a = a, side = side, opts = opts }; return opts.place.x end }
ISPanel = nil
run("client/ZeD/ZeD_SpecialTip.lua")
ok(ST.onTip ~= nil and #added == 2, "the client module adds its own handler through the game's Add")
local zedHandler = added[2]

-- the world
local function sqAt(x, y, z) return { getX = function() return x end, getY = function() return y end, getZ = function() return z or 0 end, id = x .. "," .. y } end
local SQ = {}
function getSquare(x, y, z) SQ[x .. "," .. y] = SQ[x .. "," .. y] or sqAt(x, y, z); return SQ[x .. "," .. y] end
local DIST = 2
local PLAYER = { DistToProper = function() return DIST end, DistTo = function() return DIST end,
                 getX = function() return 100 end, getY = function() return 100 end, getZ = function() return 0 end }
function getPlayer() return PLAYER end
function getSpecificPlayer(n) return PLAYER end
function isoToScreenX(pn, x, y, z) return (x - y) * 32 + 960 end
function isoToScreenY(pn, x, y, z) return (x + y - 200) * 16 + 540 - z * 96 end

local troughs = {}
local function trough(feed, water, maxW) return { getCurrentFeedAmount = function() return feed end, getWater = function() return water end,
    getMaxWater = function() return maxW or 1 end } end
CFeedingTroughSystem = { instance = { getLuaObjectOnSquare = function(_, sq) return troughs[sq.id] end } }
local function troughAt(x, y, iso, link)
    local lo = { getIsoObject = function() return iso end }
    if link then lo.linkedX, lo.linkedY = link[1], link[2] end
    troughs[x .. "," .. y] = lo
    return getSquare(x, y, 0)
end

-- ---------------------------------------------------------------- TROUGH
local function has(lines, s) for _, l in ipairs(lines or {}) do if l == s then return true end end return false end
local function hasPre(lines, s) for _, l in ipairs(lines or {}) do if l:sub(1, #s) == s then return true end end return false end
local f = ST.troughFacts(troughAt(101, 100, trough(0, 0.25, 1)))
ok(f and f.title == "ContextMenu_FeedingTrough" and hasPre(f.lines, "IGUI_FeedingTroughUI_Water: 250 / 1000")
   and not hasPre(f.lines, "IGUI_FeedingTroughUI_Feeding"), "TROUGH water only: the water line, no feed line")
ok(f and #f.info == 3 and f.info[1] == "Tooltip_trough_info1" and f.info[3] == "Tooltip_trough_info3", "TROUGH the three how-to lines")
f = ST.troughFacts(troughAt(102, 100, trough(3.456, 0)))
ok(f and has(f.lines, "IGUI_FeedingTroughUI_Feeding: 3.46") and not hasPre(f.lines, "IGUI_FeedingTroughUI_Water"), "TROUGH feed only: the feed line")
f = ST.troughFacts(troughAt(103, 100, trough(0, 0)))
ok(f and has(f.lines, "IGUI_FeedingTroughUI_Water: Fluid_Empty") and has(f.lines, "IGUI_FeedingTroughUI_Feeding: Fluid_Empty"), "TROUGH both empty: both lines, Empty")
troughAt(104, 100, trough(5, 0))
f = ST.troughFacts(troughAt(105, 100, trough(0, 0), { 104, 100 }))
ok(f and has(f.lines, "IGUI_FeedingTroughUI_Feeding: 5") and not hasPre(f.lines, "IGUI_FeedingTroughUI_Water"), "TROUGH the linked half reads its partner")
DIST = 14
ok(ST.troughFacts(getSquare(101, 100, 0)) == nil, "TROUGH past 13 tiles: nothing")
DIST = 2
RIGHT = true
ok(ST.troughFacts(getSquare(101, 100, 0)) == nil, "TROUGH right button down: nothing")
RIGHT = false
ok(ST.troughFacts(getSquare(150, 150, 0)) == nil, "TROUGH no trough on the square: nothing")

-- ---------------------------------------------------------------- FARM
local LEVEL = 3
local CURSOR = false
ISFarmingCursorMouse = { IsVisible = function() return CURSOR end }
ISFarmingMenu = { cheat = false }
local water_rgb = {}
ISFarmingInfo = {
    getGreen = function(_, l) l.r, l.g, l.b = GOOD.r, GOOD.g, GOOD.b end,
    getRed = function(_, l) l.r, l.g, l.b = BAD.r, BAD.g, BAD.b end,
    getOrange = function(_, l) l.r, l.g, l.b = 1, 0.5, 0 end,
    getWhite = function(_, l) l.r, l.g, l.b = 1, 1, 1 end,
}
ISFarmingInfo.getWaterLvl = function(plant) return plant.waterLvl > 60 and "Farming_Fine" or "Farming_Dry" end
ISFarmingInfo.getWaterLvlColor = function(plant, lv)
    if lv >= 3 and plant:isAlive() then
        if plant.waterLvl > 60 then ISFarmingInfo:getGreen(water_rgb) elseif plant.waterLvl > 40 then ISFarmingInfo:getOrange(water_rgb) else ISFarmingInfo:getRed(water_rgb) end
    else ISFarmingInfo:getWhite(water_rgb) end
    return water_rgb
end
ISFarmingInfo.getTitleColor = function(plant)
    if plant.state == "dead" then return { r = BAD.r, g = BAD.g, b = BAD.b } end
    return { r = GOOD.r, g = GOOD.g, b = GOOD.b }
end
ISFarmingInfo.getNextGrowingPhase = function(info) return "12 Farming_Hours" end
ISFarmingInfo.getDiseaseString = function(lv) return lv < 10 and "Farming_Light" or "Farming_Heavy" end
farming_vegetableconf = { getObjectName = function(p) return "Carrots" end, props = {} }
local plants = {}
CFarmingSystem = { instance = { getXp = function() return LEVEL end, getLuaObjectOnSquare = function(_, sq) return plants[sq.id] end } }
local function plantAt(x, y, t)
    t.typeOfSeed = t.typeOfSeed or "Carrots"
    t.aphidLvl, t.mildewLvl, t.fliesLvl, t.slugsLvl = t.aphidLvl or 0, t.mildewLvl or 0, t.fliesLvl or 0, t.slugsLvl or 0
    t.isAlive = function(self) return self.state ~= "dead" end
    plants[x .. "," .. y] = t
    return getSquare(x, y, 0)
end
local psq = plantAt(100, 102, { state = "seeded", waterLvl = 50, aphidLvl = 5, slugsLvl = 40 })
LEVEL = 2
ok(ST.farmFacts(psq) == nil, "FARM Farming 2: nothing")
LEVEL = 3
f = ST.farmFacts(psq)
local L = f and ST.plainLines(f) or {}
ok(f and f.title == "Carrots" and f.titleSt == "good", "FARM 3: the plant's name, the good color")
ok(has(L, "Farming_Water_levels: Farming_Dry") and has(L, "Farming_Aphid: Farming_Light") and has(L, "Farming_Slugs: Farming_Heavy")
   and not hasPre(L, "Farming_Mildew") and not hasPre(L, "Farming_Next_growing_phase"), "FARM 3: water and the diseases there, no next phase")
ok(f and f.rows[1].st == "warn" and f.rows[2].st == "bad", "FARM the orange water level reads warn, a disease bad")
LEVEL = 6
f = ST.farmFacts(psq)
L = f and ST.plainLines(f) or {}
ok(has(L, "Farming_Next_growing_phase: 12 Farming_Hours"), "FARM 6: the next growing phase")
local dsq = plantAt(101, 102, { state = "dead", waterLvl = 80 })
f = ST.farmFacts(dsq)
ok(f and f.titleSt == "bad" and #f.rows == 0, "FARM a dead plant: its title only, in the bad color")
local c = f and ST.content(f)
ok(c and c.titleColor == ZeD.T.dangerText and c.req == nil, "FARM the dead plant's balloon: title in dangerText, no table")
CURSOR = true
ok(ST.farmFacts(psq) == nil, "FARM the farming cursor up: nothing")
CURSOR = false
DIST = 7
ok(ST.farmFacts(psq) == nil, "FARM past 6 tiles: nothing")
DIST = 2
ok(ST.farmFacts(plantAt(102, 102, { state = "plow", typeOfSeed = "none", waterLvl = 0 })) == nil, "FARM an empty plot: nothing")
f = ST.farmFacts(psq)
c = ST.content(f)
ok(c.req and #c.req.rows == 4 and c.req.rows[1].values[1].st == "warn" and type(c.req.sig) == "string", "FARM the balloon's table: label and value rows, a sig")

-- ---------------------------------------------------------------- MUTE
local function tip() local h = 0; return { getHeight = function() return h end, setHeight = function(_, v) h = v end } end
local gameCalls = 0
ST.gameTrough = function() gameCalls = gameCalls + 1 end
ST.gameFarm = function() gameCalls = gameCalls + 1 end
local t1 = tip()
local m0 = ST.muted
ST._frame = 10
zedHandler(t1, getSquare(101, 100, 0))
ok(gameCalls == 0 and t1:getHeight() == 1 and ST.muted == m0 + 1 and ST._hover.kind == "trough", "MUTE ZeD's facts: the game's handlers held back, the tooltip kept up")
local t2 = tip()
zedHandler(t2, getSquare(150, 150, 0))
ok(gameCalls == 0 and t2:getHeight() == 0, "MUTE nothing to show: no height (the game hides its tooltip as before)")
SAFE = true
local t3 = tip()
zedHandler(t3, getSquare(101, 100, 0))
ok(gameCalls == 2 and t3:getHeight() == 0, "MUTE safe mode: the game's own handlers draw (its box is back)")
SAFE = false
gameCalls = 0
local saved = ST.troughFacts
ST.troughFacts = function() error("boom") end
zedHandler(tip(), getSquare(101, 100, 0))
ok(gameCalls == 1 and #LOG >= 1, "MUTE a fact ZeD can't read: the game's trough handler draws, logged once")
ST.troughFacts = saved
gameCalls = 0
local keepT = ST.gameTrough
ST.gameTrough = nil
local t4 = tip()
ST._hover = nil
zedHandler(t4, getSquare(101, 100, 0))
ok(ST._hover == nil and t4:getHeight() == 0, "MUTE a trough handler that wasn't kept aside: ZeD draws nothing over it")
ST.gameTrough = keepT

-- ---------------------------------------------------------------- FRAMES
ST._frame = 20
zedHandler(tip(), getSquare(101, 100, 0))
local p = {}
DRAWN = {}
ST.drawOn(p)
ok(ST.shown and #DRAWN == 1 and ST.kind == "trough" and ST.rect and ST.anchor and ST.charRect, "FRAMES drawn the frame the event fired")
ok(DRAWN[1].opts.place and DRAWN[1].opts.place.cell == 1 and DRAWN[1].opts.place.depth == 10, "FRAMES drawn with ZeD's own placement")
ST._frame = 21
ST.drawOn(p)
ok(ST.shown and #DRAWN == 2, "FRAMES still up one frame on (the layer may draw before the event)")
ST._frame = 22
ST.drawOn(p)
ok(not ST.shown and #DRAWN == 2, "FRAMES gone 2 frames after the event stopped")

-- ---------------------------------------------------------------- PLACE
local function overlaps(x, y, w, h, r) return x < r.x + r.w and r.x < x + w and y < r.y + r.h and r.y < y + h end
local nPlace, badPlace = 0, 0
for _, scr in ipairs({ { 1920, 1080 }, { 1280, 800 } }) do
    local sw, sh = scr[1], scr[2]
    for _, cpos in ipairs({ { sw / 2, sh / 2 }, { 80, sh / 2 }, { sw - 80, sh / 2 }, { sw / 2, 120 }, { sw / 2, sh - 60 }, { 90, 120 }, { sw - 90, sh - 60 } }) do
        local cr = { x = cpos[1] - 26, y = cpos[2] - 100, w = 52, h = 110 }
        for _, box in ipairs({ { 240, 120 }, { 320, 200 }, { 180, 60 } }) do
            for dx = -3, 3 do
                for dy = -3, 3 do
                    if not (dx == 0 and dy == 0) then
                        local a = { x = cpos[1] + dx * 64 - 32, y = cpos[2] + dy * 32 - 24, w = 64, h = 48 }
                        local x, y, side = ST.place(box[1], box[2], a, cr, sw, sh, 11, 4)
                        nPlace = nPlace + 1
                        local onScreen = x >= 0 and y >= 0 and x + box[1] <= sw and y + box[2] <= sh
                        if overlaps(x, y, box[1], box[2], cr) or not onScreen or not side then
                            badPlace = badPlace + 1
                            if badPlace <= 5 then print(string.format("  place %dx%d char %d,%d anchor %d,%d -> %d,%d %s", sw, sh, cpos[1], cpos[2], a.x, a.y, x, y, tostring(side))) end
                        end
                    end
                end
            end
        end
    end
end
ok(badPlace == 0, "PLACE never over the character, always on the screen (" .. nPlace .. " placements, " .. badPlace .. " bad)")
-- the side away from the character first
local cr0 = { x = 934, y = 440, w = 52, h = 110 }
local x, y, side = ST.place(240, 120, { x = 1100, y = 480, w = 64, h = 48 }, cr0, 1920, 1080, 11, 4)
ok(side == "right" and x >= 1100 + 64, "PLACE a square right of the character: the balloon to its right")
x, y, side = ST.place(240, 120, { x = 760, y = 480, w = 64, h = 48 }, cr0, 1920, 1080, 11, 4)
ok(side == "left" and x + 240 <= 760, "PLACE a square left of the character: the balloon to its left")
-- the placement's tail fields
local pl = ST.placement(100, 50, "above", 240, { x = 150, y = 200, w = 64, h = 48 }, 1, 10)
ok(pl.tipX == 182 and pl.corner == "left" and pl.cell == 1 and pl.depth == 10, "PLACE the tail toward the square's middle")
pl = ST.placement(300, 50, "right", 240, { x = 150, y = 200, w = 64, h = 48 }, 1, 10)
ok(pl.corner == "top" and pl.tipY == 224, "PLACE beside: the tail at the square's middle height")

print(string.format("special_tip_sim: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
