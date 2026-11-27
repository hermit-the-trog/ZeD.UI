-- ZeDUI/tools/qa/info_fixes_sim.lua  (Nov 27 2026, Build): the Info tab's QA bugs of Nov 27 with no game running.
-- Loads the real IdentityTab.lua against Lua 5.1 stubs and reads its data the way the tab does; cuts the
-- traits' measure, the refresh clock and the photo's wheel out of their files and runs them alone.
--   I3   the weight rounds as the game's Info page (79.6 reads 80, 79.4 reads 79)
--   I6   the profession's name as the game writes it ("DIY Expert", not "Diy Expert")
--   I8   gray hair reads Gray (0.6 and 0.4 gray), browns and black and white keep their words
--   I10  Survived for only while the game's clock shows the date
--   I15  no traits: the measured height holds the empty line
--   I17  the wheel over the bust scrolls the tab; the full body's zoom stops at its bounds
--   refresh: on the clock (500 ms), not every 30 frames
-- Each check fails on the code before these fixes.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/info_fixes_sim.lua
-- It prints FAIL lines and a last line "info_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]info_fixes_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end

--- the text from the line holding a to the first b after it (b included), or nil
local function cut(src, a, b)
    local i = src:find(a, 1, true)
    if not i then return nil end
    local j, k = src:find(b, i + #a, true)
    if not j then return nil end
    return src:sub(i, k)
end

local IT_PATH = "42/media/lua/client/ZeD/IdentityTab.lua"
local CW_PATH = "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua"
local itSrc = readFile(IT_PATH) or ""
local cwSrc = readFile(CW_PATH) or ""
check("IdentityTab.lua read", itSrc ~= "")
check("ZeD_CharacterWindow.lua read", cwSrc ~= "")

-- ---------------------------------------------------------------------------
-- THE GAME, as far as gatherData reaches
-- ---------------------------------------------------------------------------
Events = setmetatable({}, { __index = function(self, n)
    local ev = { Add = function() end, Remove = function() end }
    rawset(self, n, ev)
    return ev
end })
local clockMs = 1000000
function getTimestampMs() return clockMs end
function instanceof(o, cls) return type(o) == "table" and o._is and o._is[cls] == true end
function getText(k) return k end

ZeD = ZeD or {}
ZeD.Atoms = ZeD.Atoms or {}
ZeD.tr = function(k, a) return a ~= nil and (k .. ":" .. tostring(a)) or k end
ZeD.upper = string.upper
ZeD.KillTracker = { total = function() return 0 end }

local DEFS = {}
CharacterProfessionDefinition = {
    getCharacterProfessionDefinition = function(prof) return DEFS[prof.id] end,
    getProfessions = function()
        return { size = function() return 0 end, get = function() return nil end }
    end,
}
local function prof(id, ui)
    local p = { id = id }
    function p:toString() return self.id end
    function p:getName() return self.id end
    DEFS[id] = { getUIName = function() return ui end }
    return p
end

local dateVisible = true
UIManager = { getClock = function() return { isDateVisible = function() return dateVisible end } end }

local P = { _is = { IsoPlayer = true, IsoGameCharacter = true }, md = {}, weight = 80, hair = nil, prof = nil }
function P:getModData() return self.md end
function P:getZombieKills() return 0 end
function P:getTimeSurvived() return "3 days, 4 hours" end
function P:isFemale() return false end
function P:getDescriptor()
    local me = self
    return { getSurname = function() return "Finnegan" end, getForename = function() return "Glen" end,
             getCharacterProfession = function() return me.prof end }
end
function P:getNutrition()
    local f = function() return false end
    local me = self
    return { getWeight = function() return me.weight end, isIncWeightLot = f, isIncWeight = f, isDecWeight = f }
end
function P:getHumanVisual()
    local me = self
    return { getHairColor = function() return me.hair end, getHairModel = function() return "" end,
             getBeardModel = function() return "" end, getBodyHairIndex = function() return 0 end }
end
function P:getCharacterTraits() return { getKnownTraits = function() return nil end } end

local function color(r, g, b)
    return { getRedFloat = function() return r end, getGreenFloat = function() return g end,
             getBlueFloat = function() return b end }
end

local realRequire = require
require = function() end
local okLoad, errLoad = pcall(dofile, ROOT .. IT_PATH)
require = realRequire
check("IdentityTab.lua loads", okLoad, errLoad)
local I = ZeD.IdentityTab or {}
local function gather() return I.gatherData(P) end

-- ---------------------------------------------------------------------------
section("I3 weight rounds as the game")
-- ---------------------------------------------------------------------------
P.weight = 79.6
check("79.6 kg reads 80", gather().weightStr == "UI_ZeD_Identity_WeightKg:80", gather().weightStr)
P.weight = 79.4
check("79.4 kg reads 79", gather().weightStr == "UI_ZeD_Identity_WeightKg:79", gather().weightStr)
P.weight = 80.0
check("80.0 kg reads 80", gather().weightStr == "UI_ZeD_Identity_WeightKg:80", gather().weightStr)

-- ---------------------------------------------------------------------------
section("I6 the profession's own name")
-- ---------------------------------------------------------------------------
P.prof = prof("base:repairman", "DIY Expert")
check("DIY Expert stays DIY Expert", gather().profession == "DIY Expert", gather().profession)
P.prof = prof("base:burgerflipper", "Burger Flipper")
check("Burger Flipper as written", gather().profession == "Burger Flipper", gather().profession)
P.prof = nil
check("no profession: --", gather().profession == "--", gather().profession)

-- ---------------------------------------------------------------------------
section("I8 gray hair")
-- ---------------------------------------------------------------------------
local function hairOf(r, g, b) P.hair = color(r, g, b); return gather().hairColor end
check("gray 0.6 reads Gray", hairOf(0.6, 0.6, 0.6) == "ContextMenu_Grey", hairOf(0.6, 0.6, 0.6))
check("gray 0.4 reads Gray", hairOf(0.4, 0.4, 0.4) == "ContextMenu_Grey", hairOf(0.4, 0.4, 0.4))
check("a slightly warm gray (0.55, 0.53, 0.5) reads Gray", hairOf(0.55, 0.53, 0.5) == "ContextMenu_Grey",
    hairOf(0.55, 0.53, 0.5))
check("white stays White", hairOf(0.95, 0.95, 0.95) == "ContextMenu_White", hairOf(0.95, 0.95, 0.95))
check("black stays Black", hairOf(0.1, 0.1, 0.1) == "ContextMenu_Black", hairOf(0.1, 0.1, 0.1))
check("dark gray (0.25) stays dark (not Gray)", hairOf(0.25, 0.25, 0.25) ~= "ContextMenu_Grey", hairOf(0.25, 0.25, 0.25))
check("brown stays Brown", hairOf(0.42, 0.32, 0.2) == "ContextMenu_Brown", hairOf(0.42, 0.32, 0.2))
check("light brown stays Light Brown", hairOf(0.7, 0.55, 0.35) == "ContextMenu_Light_Brown", hairOf(0.7, 0.55, 0.35))
check("blonde stays Blonde", hairOf(0.95, 0.85, 0.55) == "UI_ZeD_Identity_HairBlonde", hairOf(0.95, 0.85, 0.55))
P.hair = nil

-- ---------------------------------------------------------------------------
section("I10 Survived for only while the clock shows the date")
-- ---------------------------------------------------------------------------
dateVisible = true
local d = gather()
check("date shown: the time survived", d.timeSurv == "3 days, 4 hours" and not d.survHidden, tostring(d.timeSurv))
dateVisible = false
d = gather()
check("date hidden: the time is not told", d.timeSurv ~= "3 days, 4 hours" and d.survHidden == true, tostring(d.timeSurv))
local saveUI = UIManager
UIManager = nil
d = gather()
check("no clock at all: not told", d.timeSurv ~= "3 days, 4 hours", tostring(d.timeSurv))
UIManager = saveUI
-- (QA I10 second pass: the watch parks the game's clock, so the clock's own flag reads false in the gather; the
-- tab asks ZeD.Watch.dateVisible, read before the parking)
dateVisible = false
ZeD.Watch = { dateVisible = function() return true end }
d = gather()
check("the watch says the date shows (the parked clock says no): the time survived", d.timeSurv == "3 days, 4 hours" and not d.survHidden, tostring(d.timeSurv))
ZeD.Watch.dateVisible = function() return false end
d = gather()
check("the watch says the date is hidden: not told", d.survHidden == true, tostring(d.timeSurv))
ZeD.Watch = nil
dateVisible = true
check("Simple drops the row while hidden",
    itSrc:find('if not (data.survHidden and TALL_LABELS[i][2] == "IGUI_char_Survived_For") then', 1, true) ~= nil)

-- ---------------------------------------------------------------------------
section("I15 no traits: the measure holds the empty line")
-- ---------------------------------------------------------------------------
do
    local body = cut(itSrc, "local function traitRowH()", "\n    return h\nend")
    check("the traits' measure found", body ~= nil)
    if body then
        local FH, PX = 20, 1
        local T = { sp = { sm = 6, xs = 2, afterGroove = 4 }, fontF2 = "F2", px = function(n) return n * PX end }
        local env = setmetatable({ ZeD = {
            T = T, tr = function(k) return k end,
            TM = { getFontHeight = function() return FH end },
            -- one line per 200 px of the text's room, at least one
            Atoms = { wrapText = function(_, _, w) local n = math.max(1, math.ceil(400 / math.max(1, w))) local t = {}
                for i = 1, n do t[i] = "x" end return t end },
        } }, { __index = _G })
        local fn = loadstring("local TRAIT_ROW_H, TRAIT_GAP = 23, 4\n" .. body .. "\nreturn measureZoneBH", "=measureZoneBH")
        local measure = fn and setfenv(fn, env)()
        check("the traits' measure loads", measure ~= nil)
        if measure then
            local empty = { posTraits = {}, negTraits = {} }
            local head = 6 + 20 + 4
            local step = FH + 2
            -- wide: 412 px of room, one line; narrow: 212 px, two lines
            local wide = measure(empty, 2, 424)
            check("wide: head + the line + the room under it", wide == head + 1 * step - 2 + 6, wide)
            local narrow = measure(empty, 1, 224)
            check("narrow: head + both lines + the room under it", narrow == head + 2 * step - 2 + 6, narrow)
            local some = measure({ posTraits = { {} }, negTraits = {} }, 2, 424)
            local rowH = math.max(23, FH + 6)
            check("with traits the measure is the groups' as before", some == head + 15 + 2 + (rowH + 4) + 6, some)
        end
    end
end

-- ---------------------------------------------------------------------------
section("I17 the photo's wheel")
-- ---------------------------------------------------------------------------
do
    local body = cut(cwSrc, "    identityModel.onMouseWheel = function(self, del)", "\n    end\n")
    check("the photo's wheel found", body ~= nil)
    if body then
        local fn = loadstring("local win, drawer, identityModel = ...\n" .. body, "=onMouseWheel")
        local scrolled = 0
        local drawer = { onMouseWheel = function(_, del) scrolled = scrolled + del; return true end }
        local win = { _activeTab = "identity", _identityPhotoExpanded = false, _identityCustomZoom = 0 }
        local model = {}
        if fn then fn(win, drawer, model) end
        check("the wheel handler loads", model.onMouseWheel ~= nil)
        if model.onMouseWheel then
            model.onMouseWheel(model, 1)
            model.onMouseWheel(model, 1)
            check("bust: the wheel scrolls the tab", scrolled == 2, scrolled)
            check("bust: no zoom", win._identityCustomZoom == 0, win._identityCustomZoom)
            win._identityPhotoExpanded = true
            scrolled = 0
            model.onMouseWheel(model, 1)
            check("full body: one notch zooms out", win._identityCustomZoom == -2, win._identityCustomZoom)
            for _ = 1, 30 do model.onMouseWheel(model, 1) end
            check("full body: 30 notches out stop at -6", win._identityCustomZoom == -6, win._identityCustomZoom)
            for _ = 1, 30 do model.onMouseWheel(model, -1) end
            check("full body: 30 notches in stop at 12", win._identityCustomZoom == 12, win._identityCustomZoom)
            check("full body: the tab doesn't scroll", scrolled == 0, scrolled)
            win._activeTab = "equip"
            model.onMouseWheel(model, 1)
            check("Equip doll: the wheel scrolls the tab still", scrolled == 1, scrolled)
        end
    end
end

-- ---------------------------------------------------------------------------
section("refresh on the clock")
-- ---------------------------------------------------------------------------
do
    check("render refreshes with dueMs, not a frame count",
        itSrc:find('if dueMs(win, "_identityAt", 500,', 1, true) ~= nil and itSrc:find("_identityTimer", 1, true) == nil)
    local body = cut(itSrc, "local function dueMs(owner, key, periodMs, force)", "\n    return true\nend")
    check("dueMs found", body ~= nil)
    if body then
        local fn = loadstring(body .. "\nreturn dueMs", "=dueMs")
        local dueMs = fn and fn()
        if dueMs then
            -- 2 seconds at 240 Hz: a frame count of 30 runs 16 times; the clock 4 or 5
            local owner, runs = {}, 0
            for _ = 1, 480 do
                clockMs = clockMs + 4
                if dueMs(owner, "_identityAt", 500, false) then runs = runs + 1 end
            end
            check("2 s at 240 Hz: about 4 refreshes", runs >= 4 and runs <= 5, runs)
            check("forced: runs at once", dueMs(owner, "_identityAt", 500, true) == true)
        end
    end
end

print(string.format("info_fixes_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
