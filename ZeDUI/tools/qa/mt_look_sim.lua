-- ZeDUI/tools/qa/mt_look_sim.lua  (Nov 26 2026, Build; QA's Vehicle tab map, 2026-11-26_map_mechanics.md)
-- The Vehicle tab's words, layout, focus, part menu, names and odds, with no game running. The real
-- MechanicsTab.lua loads on Lua 5.1 stubs of the game; each check runs on it, then on the tab as it was
-- (git show BASE), where each bug's check must fail.
--   M1   Take engine parts: the soft NEEDS row, the question and the help are the game's warning
--        ("This will set engine condition to 0."), not "loses condition"
--   M5   a card opened on the pad: the focus lands on the main (accent) verb, not the first lit one
--   M8   the half card at 4K (385 px tab, list 420): the list stacks over the right pane, each the full width;
--        the full card keeps the side-by-side split
--   M10a the battery with the engine running: Uninstall's NEEDS names the engine (must be off)
--   M10c a missing brake under its tire: no "must be off" row for Install (the game's InstallTest skips it)
--   M10f a part repaired only off the car: the game's "Can be repaired once uninstalled." line
--   M11  X on a row: the game's part menu opens at the row, the pad on the menu, the window its origin
--   M13b two cars of one name keep their numbers as their order in the list swaps
--   M16c the odds of damage: install 35% of the 35% that fail (12), uninstall every failure (35)
-- What it can't show: the real drawing, the game's own menu code, the pad's dispatch.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mt_look_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mt_look_sim%.lua$", "")
local BASE = "80af98561"   -- main before these fixes
local out = print

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        out("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local WORDS = {}
for k, v in (readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""):gmatch('"([%w_]+)"%s*:%s*"(.-)"%s*,?%s*\r?\n') do WORDS[k] = v end
WORDS.Tooltip_vehicle_TakeEnginePartsWarning = "This will set engine condition to 0."
WORDS.Tooltip_RepairableUninstalled = "Can be repaired once uninstalled."
WORDS.Tooltip_chanceFailure = "Chance of damage:"
WORDS.IGUI_VehiclePartEngine = "Engine"
WORDS.IGUI_VehiclePartTireFrontLeft = "Front Left Tire"
WORDS.UI_On = "On"
WORDS.IGUI_ToHeavy = "Too heavy for inventory."
WORDS.IGUI_VehicleNameCarNormal = "Chevalier Nyala"

-- ---------------------------------------------------------------------------
-- THE GAME, as far as these checks ask
-- ---------------------------------------------------------------------------
local W = {}   -- one load's world
local function partStub(id, f)
    local p = { id = id }
    function p:getId() return self.id end
    function p:getVehicle() return W.v end
    function p:getInventoryItem() return f.item end
    function p:getItemType() return f.itype end
    function p:getTable(k) return f.tables and f.tables[k] or nil end
    function p:getScriptPart() return { isRepairMechanic = function() return f.repairMech == true end } end
    function p:getCondition() return f.cond or 90 end
    function p:getContainerSeatNumber() return -1 end
    function p:getWindow() return nil end
    function p:getDoor() return nil end
    function p:isContainer() return false end
    return p
end
local function typeList(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, isEmpty = function() return #t == 0 end }
end

local function load(src)
    W = { menus = {}, mouseX = 0, mouseY = 0 }
    require = function() end
    Events = nil
    print = function() end
    getText = function(k) return WORDS[k] or k end
    getTextOrNull = function(k) return WORDS[k] end
    getTimestampMs = function() return 1000 end
    getMouseX = function() return W.mouseX end
    getMouseY = function() return W.mouseY end
    getItem = function() return nil end
    getItemName = function(full) return tostring(full) end
    -- the game's string:split (a Lua table here)
    string.split = string.split or function(s, sep)
        local t = {}
        for piece in string.gmatch(s, "[^" .. sep .. "]+") do t[#t + 1] = piece end
        return t
    end
    Perks = { Mechanics = "Mechanics", FromString = function(n) return n end }
    FixingManager = { getFixes = function(item) return typeList(item and item.fixes or {}) end }
    VehicleUtils = {
        getItems = function() return W.byType or {}, {} end,
        RequiredKeyNotFound = function() return false end,
        getItemScripts = function() return {} end,
        split = function(s, sep) local a, b = string.match(s, "^(.-)" .. sep .. "(.*)$"); return a, b end,
        -- the game's own (Vehicles.lua)
        calculateInstallationSuccess = function(perks, chr)
            local success, failure = 100, 0
            if perks and perks ~= "" then
                for perk in string.gmatch(perks, "[^;]+") do
                    local name, level = string.match(perk, "^(.-):(.*)$")
                    level = tonumber(level)
                    local lvl = chr:getPerkLevel(name)
                    if lvl < level then
                        success = success - (20 + (level - lvl) * 15)
                        failure = failure + (20 + (level - lvl) * 15)
                    end
                end
            end
            return math.min(math.max(success, 0), 100), math.min(math.max(failure, 0), 100)
        end,
    }
    ISVehicleMechanics = { getWrench = function() return nil end, getScrewdriver = function() return nil end }
    JoypadState = { players = {} }
    setJoypadFocus = function(pn, c) local j = JoypadState.players[pn + 1]; if j then j.focus = c end end
    -- the game's hidden mechanics window: its part menu opens at (x, y) + its own place, as the game's does
    local ui = { absX = 100, absY = 50 }
    function ui:getAbsoluteX() return self.absX end
    function ui:getAbsoluteY() return self.absY end
    function ui:doPartContextMenu(part, x, y)
        local m = { x = x + self:getAbsoluteX(), y = y + self:getAbsoluteY(), part = part, visible = true }
        function m:getIsVisible() return self.visible end
        self.context = m
        W.menus[#W.menus + 1] = m
    end
    W.ui = ui
    getPlayerMechanicsUI = function() return ui end
    ZeD = {
        tr = function(k, ...) return WORDS[k] or k end,
        trBare = function(k) return WORDS[k] or k end,
        textCase = function(s) return s end,
        MechTrailer = { focusTarget = function() return nil end },
        T = { px = function(n) return math.floor(n * 1.75 + 0.5) end },   -- 4K's scale (the half card: 385 px)
        CraftingCore = { PANE_W_SPLIT = 240 },
    }
    local f, err = loadstring(src, "@MechanicsTab.lua")
    if not f then return nil, err end
    local ok, e2 = pcall(f)
    if not ok then return nil, e2 end
    return ZeD.MechanicsTab
end

-- the character and a car
local function chr(mech)
    local c = {}
    function c:getPlayerNum() return 0 end
    function c:getPerkLevel() return mech or 0 end
    function c:getInventory() return { haveThisKeyId = function() return true end, getNumberOfItem = function() return 0 end } end
    function c:isRecipeActuallyKnown() return true end
    return c
end
local function car(f)
    local v = { parts = {}, running = f.running }
    function v:getId() return f.id or 1 end
    function v:getPartById(id) return self.parts[id] end
    function v:getScript() return { getEngineRepairLevel = function() return 4 end } end
    function v:isEngineStarted() return self.running == true end
    function v:isEngineRunning() return self.running == true end
    function v:canInstallPart() return f.canInstall == true end
    function v:canUninstallPart() return f.canUninstall == true end
    function v:getKeyId() return 7 end
    function v:isHotwired() return false end
    W.v = v
    return v
end
local function hasRow(n, pred) for _, r in ipairs(n and n.rows or {}) do if pred(r) then return r end end return nil end

-- ---------------------------------------------------------------------------
-- One run of every bug's check on a source; returns { [bug] = true when it passes, detail }
-- ---------------------------------------------------------------------------
local function run(src)
    local res, why = {}, {}
    local MT, err = load(src)
    if not MT then res.load = false; why.load = err; return res, why end
    res.load = true
    local T = MT._test or {}
    local function try(bug, fn)
        local ok, pass, d = pcall(fn)
        res[bug] = ok and pass == true
        why[bug] = ok and d or pass
    end

    -- M1: the soft row and the question say what the game says
    try("M1", function()
        local v = car({})
        local eng = partStub("Engine", { cond = 90 })
        v.parts.Engine = eng
        local n = T.needsFor({}, eng, "takeParts", chr(5), v)
        local row = hasRow(n, function(r) return r.soft end)
        local q = string.find(src, 'getText("Tooltip_vehicle_TakeEnginePartsWarning")', 1, true)
        local help = string.find(src, 'takeParts = "Tooltip_vehicle_TakeEnginePartsWarning"', 1, true)
        local loses = string.find(src, "UI_ZeD_Veh_ConfirmTakeParts", 1, true) or string.find(src, "UI_ZeD_Veh_LowersEngine", 1, true)
        return row ~= nil and row.label == WORDS.Tooltip_vehicle_TakeEnginePartsWarning and q ~= nil and help ~= nil and not loses,
            "row " .. tostring(row and row.label)
    end)

    -- M10a: the battery, the engine running
    try("M10a", function()
        local v = car({ running = true, canUninstall = false })
        local bat = partStub("Battery", { item = { fixes = {} }, itype = typeList({ "Base.CarBattery1" }),
            tables = { uninstall = { test = "Vehicles.UninstallTest.Battery", skills = "Mechanics:1" } } })
        v.parts.Battery = bat
        local n = T.needsFor({}, bat, "uninstall", chr(5), v)
        local r = n and n.blocker
        local off = car({ running = false, canUninstall = true })
        off.parts.Battery = bat
        local n2 = T.needsFor({}, bat, "uninstall", chr(5), off)
        return r ~= nil and r.label == "Engine" and n.ok == false and n2.blocker == nil,
            "blocker " .. tostring(r and r.label) .. ", off " .. tostring(n2 and n2.blocker and n2.blocker.label)
    end)

    -- M10c: a missing brake, its tire on: Install is lit and nothing says take the tire off
    try("M10c", function()
        local v = car({ canInstall = true })
        local tire = partStub("TireFrontLeft", { item = {} })
        local brake = partStub("BrakeFrontLeft", { itype = typeList({ "Base.OldBrake1" }),
            tables = { install = { requireUninstalled = "TireFrontLeft", skills = "Mechanics:3" },
                       uninstall = { requireUninstalled = "TireFrontLeft", skills = "Mechanics:3" } } })
        v.parts.TireFrontLeft, v.parts.BrakeFrontLeft = tire, brake
        local spare = { getDisplayName = function() return "Old Brake" end, getCondition = function() return 80 end,
                        getContainer = function() return nil end }
        W.byType = { ["Base.OldBrake1"] = { spare } }
        local n = T.needsFor({ pick = 1, fixPick = 1 }, brake, "install", chr(3), v)
        W.byType = nil
        local offRow = hasRow(n, function(r) return r.kicker == WORDS.UI_ZeD_Veh_KMustBeOff end)
        local stepSrc = string.find(src, 'verb == "install" and {} or idsIn(kv.requireUninstalled)', 1, true)
        return n.ok == true and n.blocker == nil and offRow == nil and stepSrc ~= nil,
            "ok " .. tostring(n.ok) .. ", blocker " .. tostring(n.blocker and n.blocker.label)
    end)

    -- M3 (QA's fourth pass): a spare in a crate that won't fit in his bags: the game drops the whole chain when its
    -- move fails, so the card says it first in the game's words, and Install is grey
    try("M3heavy", function()
        local v = car({ canInstall = true })
        local tire = partStub("TireFrontLeft", { itype = typeList({ "Base.OldTire1" }),
            tables = { install = { skills = "Mechanics:1" } } })
        v.parts.TireFrontLeft = tire
        local crate = { getType = function() return "crate" end, getContainingItem = function() return nil end }
        local spare = { getDisplayName = function() return "Old Tire" end, getCondition = function() return 70 end,
                        getContainer = function() return crate end }
        W.byType = { ["Base.OldTire1"] = { spare } }
        local function heavy(room)
            local c = chr(3)
            local inv = c:getInventory()
            inv.hasRoomFor = function() return room end
            c.getInventory = function() return inv end
            return c
        end
        local n = T.needsFor({ pick = 1, fixPick = 1 }, tire, "install", heavy(false), v)
        local n2 = T.needsFor({ pick = 1, fixPick = 1 }, tire, "install", heavy(true), v)
        W.byType = nil
        local row = hasRow(n, function(r) return r.label == "Old Tire" end)
        return n.ok == false and row ~= nil and row.ok == false and tostring(row.kicker):find("Too heavy", 1, true) ~= nil
            and n2.ok == true, "ok " .. tostring(n.ok) .. ", kicker " .. tostring(row and row.kicker) .. ", fits " .. tostring(n2 and n2.ok)
    end)

    -- M10f: repaired only once off the car
    try("M10f", function()
        local off = partStub("Muffler", { item = { fixes = { 1 } }, itype = typeList({ "Base.OldCarMuffler1" }) })
        local mech = partStub("TireFrontLeft", { item = { fixes = { 1 } }, itype = typeList({ "Base.OldTire1" }), repairMech = true })
        local none = partStub("Seat", { item = { fixes = {} }, itype = typeList({ "Base.NormalCarSeat1" }) })
        local drawn = string.find(src, 'getText("Tooltip_RepairableUninstalled")', 1, true)
        return MT.repairOnlyOff ~= nil and MT.repairOnlyOff(off) and not MT.repairOnlyOff(mech) and not MT.repairOnlyOff(none) and drawn ~= nil
    end)

    -- M16c: the odds of damage
    try("M16c", function()
        local i = MT.damageOdds and MT.damageOdds("install", 65, 35)
        local u = MT.damageOdds and MT.damageOdds("uninstall", 65, 35)
        local label = string.find(src, 'getText("Tooltip_chanceFailure")', 1, true)
        return i == 12 and u == 35 and MT.damageOdds("install", 100, 0) == 0 and label ~= nil, "install " .. tostring(i) .. ", uninstall " .. tostring(u)
    end)

    -- M8: the half card stacks, the full card keeps the split
    try("M8", function()
        if not MT.layout then return false, "no MT.layout" end
        local half = MT.layout(0, 40, 385, 800)
        local full = MT.layout(0, 40, 840, 800)
        local px = ZeD.T.px
        local okHalf = half.stacked and half.list.w == 385 and half.right.w == 385 and half.right.y > half.list.y
            and half.list.h > 0 and half.right.h > 0 and half.splitY ~= nil
        local okFull = (not full.stacked) and full.list.w == px(240) and full.right.x == px(240) + px(1)
            and full.right.w == 840 - px(240) - px(1)
        -- Large text: the list's 240u reads 483 px on the half card's 443: stacked too
        local big = MT.layout(0, 40, 443, 800)
        local used = string.find(src, "local L = MT.layout(x, top, w, bodyH)", 1, true)
        return okHalf and okFull and big.stacked and used ~= nil, "half stacked " .. tostring(half.stacked) .. ", full " .. tostring(full.stacked)
    end)

    -- M5: the card's focus lands on the main verb
    try("M5", function()
        local win = { _mechFocusTarget = "card", _mech = { cmPrimary = "inflate" } }
        local els = { { id = "mech:row:TireFrontLeft" }, { id = "mech:verb:deflate" }, { id = "mech:verb:inflate" } }
        local i = MT.focusTargetIndex(win, els)
        local win2 = { _mechFocusTarget = "card", _mech = { cmPrimary = "repairEngine" } }
        local els2 = { { id = "mech:verb:takeParts" }, { id = "mech:verb:repairEngine" } }
        local i2 = MT.focusTargetIndex(win2, els2)
        local set = string.find(src, "s.cmPrimary = cm and cm.primary or nil", 1, true)
        return i == 3 and i2 == 2 and set ~= nil, "tire on " .. tostring(i and els[i].id) .. ", engine on " .. tostring(i2 and els2[i2].id)
    end)

    -- M11: X on a row on the pad: the menu at the row, the pad on it, the window its origin
    try("M11", function()
        local v = car({})
        v.parts.Engine = partStub("Engine", {})
        local c = chr(5)
        getSpecificPlayer = function() return c end
        JoypadState.players[1] = { focus = "window" }
        local panel = { getAbsoluteX = function() return 2000 end, getAbsoluteY = function() return 400 end }
        local win = { _playerObj = c, playerNum = 0 }
        win._mech = { zones = { { id = "mech:row:Engine", x = 643, y = 190, w = 300, h = 42, isRow = true, part = "Engine",
                                  fn = function() end } },
                      vehicles = { { vehicle = v, id = 1 } }, idx = 1, view = "overview", panel = panel }
        W.mouseX, W.mouseY = 0, 0
        local els = MT.buildFocusables(win)
        local el = els[1]
        if not (el and el.onContextMenu) then return false, "no X on the row" end
        el.onContextMenu()
        local m = W.menus[#W.menus]
        JoypadState.players[1] = nil
        return m ~= nil and m.x == 2643 and m.y == 632 and m.origin == win and m.mouseOver == 1,
            "menu at " .. tostring(m and m.x) .. "," .. tostring(m and m.y) .. ", origin is the window " .. tostring(m and m.origin == win)
    end)
    -- (the pad really lands on the menu: setJoypadFocus is called with it)
    if res.M11 then
        local v = car({})
        v.parts.Engine = partStub("Engine", {})
        local c = chr(5)
        JoypadState.players[1] = { focus = "window" }
        local win = {}
        T.partContextMenu(v.parts.Engine, c, win, 500, 600)
        local m = W.menus[#W.menus]
        res.M11 = JoypadState.players[1].focus == m and m.x == 500 and m.y == 600
        why.M11 = "focus on the menu " .. tostring(JoypadState.players[1].focus == m)
        JoypadState.players[1] = nil
    end

    -- M13b: the numbers stay with the cars as the list's order swaps
    try("M13b", function()
        local function nyala()
            local sc = { getCarModelName = function() return nil end, getName = function() return "CarNormal" end,
                         getMechanicType = function() return 1 end }
            return { getScript = function() return sc end }
        end
        local a, b = nyala(), nyala()
        local first = MT.vehicleTabItems({ { vehicle = a, id = 21, dist = 2 }, { vehicle = b, id = 22, dist = 3 } })
        local la, lb = first[1].label, first[2].label
        local second = MT.vehicleTabItems({ { vehicle = b, id = 22, dist = 2 }, { vehicle = a, id = 21, dist = 3 } })
        return la ~= lb and second[1].label == lb and second[2].label == la, la .. " / " .. lb .. " then " .. second[1].label .. " / " .. second[2].label
    end)
    return res, why
end

-- ---------------------------------------------------------------------------
local BUGS = { "M1", "M3heavy", "M5", "M8", "M10a", "M10c", "M10f", "M11", "M13b", "M16c" }
local src = readFile(ROOT .. "42/media/lua/client/ZeD/MechanicsTab.lua")
check("MechanicsTab.lua is read", src ~= nil)
local res, why = run(src or "")
check("the tab loads on the stubs", res.load, why.load)
for _, b in ipairs(BUGS) do check(b .. " (the tab now)", res[b] == true, why[b]) end

-- the tab as it was: every one of these fails there
local pipe = io.popen('git -C "' .. (ROOT ~= "" and ROOT or ".") .. '" show ' .. BASE .. ':42/media/lua/client/ZeD/MechanicsTab.lua 2>NUL')
local old = pipe and pipe:read("*a") or ""
if pipe then pipe:close() end
if old ~= "" then
    local ro, wo = run(old)
    check("the old tab loads on the stubs", ro.load, wo.load)
    for _, b in ipairs(BUGS) do check(b .. " fails on the old tab", ro[b] ~= true, wo[b]) end
else
    out("(no git: the old tab's checks skipped)")
end

print = out
out("mt_look_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
