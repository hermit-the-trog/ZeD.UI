-- ZeDUI/tools/qa/mt_calls_sim.lua  (Nov 26 2026, Build; the director's calls on QA's Vehicle tab map,
-- 2026-11-26_map_mechanics.md M4 M6 M7 M10g)
-- The real MechanicsTab.lua (and the World window's tab-leave hook) on Lua 5.1 stubs of the game; each call's check
-- runs on the tab now, then on the tab as it was (git show BASE), where it must fail.
--   M4   Repair on a part at full condition: greyed, kept in view, the NEEDS line "The part is at full condition.";
--        at 90 it is lit. Repair engine at 100 says the same (it was gone before)
--   M6   seated in a car: every part verb greys with the game's "Must exit vehicle." and stays in view; the press
--        queues nothing and says it; X / right-click opens no menu and says it
--   M7   leaving the tab ends no look (the World window's _tabLeft); the reach check ends a look past six tiles with no
--        window drawn and keeps one at three; the look keeps whose it is
--   M10g hidden actions folded: Install on a missing part with no spare in reach is shown greyed (not folded away)
--        and is the verb the card opens on, so the types that fit are listed under it
-- What it can't show: the drawing, the game's own menu and handlers, the pad's dispatch.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mt_calls_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mt_calls_sim%.lua$", "")
local BASE = "727705b40"   -- fix/mech6 before these calls
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
local function gitShow(path)
    local pipe = io.popen('git -C "' .. (ROOT ~= "" and ROOT or ".") .. '" show ' .. BASE .. ':' .. path .. ' 2>NUL')
    local s = pipe and pipe:read("*a") or ""
    if pipe then pipe:close() end
    return s
end

local WORDS = {}
for k, v in (readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""):gmatch('"([%w_]+)"%s*:%s*"(.-)"%s*,?%s*\r?\n') do WORDS[k] = v end
WORDS.IGUI_VehicleSeat_ExitToSwitch = "Must exit vehicle."
WORDS.IGUI_VehiclePartEngine = "Engine"
WORDS.IGUI_VehiclePartTireFrontLeft = "Front Left Tire"
check("the full-condition words are in the English", WORDS.UI_ZeD_Veh_FullCond ~= nil)
local SEATED = WORDS.IGUI_VehicleSeat_ExitToSwitch
local FULL = WORDS.UI_ZeD_Veh_FullCond or "?"

-- ---------------------------------------------------------------------------
-- THE GAME, as far as these checks ask
-- ---------------------------------------------------------------------------
local W = {}
local function typeList(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, isEmpty = function() return #t == 0 end }
end
local function partStub(id, f)
    local p = { id = id }
    function p:getId() return self.id end
    function p:getVehicle() return W.v end
    function p:getInventoryItem() return f.item end
    function p:getItemType() return f.itype end
    function p:getTable(k) return f.tables and f.tables[k] or nil end
    function p:getScriptPart() return { isRepairMechanic = function() return f.repairMech == true end } end
    function p:getCondition() return f.cond or 90 end
    function p:getCategory() return f.cat or "Other" end
    function p:getArea() return "Engine" end
    function p:getContainerSeatNumber() return -1 end
    function p:getItemContainer() return nil end
    function p:getWindow() return nil end
    function p:getDoor() return nil end
    function p:isContainer() return false end
    return p
end

local function load(src)
    W = { menus = {}, said = {}, ran = {}, ticks = {} }
    require = function() end
    Events = { OnPlayerUpdate = { Add = function(fn) W.ticks[#W.ticks + 1] = fn end, Remove = function() end } }
    print = function() end
    getText = function(k) return WORDS[k] or k end
    getTextOrNull = function(k) return WORDS[k] end
    getTimestampMs = function() return 1000 end
    getMouseX = function() return 0 end
    getMouseY = function() return 0 end
    getItem = function() return nil end
    getItemName = function(full) return tostring(full) end
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
        calculateInstallationSuccess = function() return 100, 0 end,
        split = function(s, sep) local a, b = string.match(s, "^(.-)" .. sep .. "(.*)$"); return a, b end,
    }
    local tool = { getContainer = function() return nil end }
    ISVehicleMechanics = { getWrench = function() return tool end, getScrewdriver = function() return tool end }
    UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return 1 end } end }
    HaloTextHelper = { addBadText = function(_, text) W.said[#W.said + 1] = tostring(text) end }
    ISVehiclePartMenu = { onUninstallPart = function() W.ran[#W.ran + 1] = "uninstall" end,
                          onInstallPart = function() W.ran[#W.ran + 1] = "install" end }
    local ui = {}
    function ui:getAbsoluteX() return 0 end
    function ui:getAbsoluteY() return 0 end
    function ui:doPartContextMenu(part) self.context = { part = part }; W.menus[#W.menus + 1] = self.context end
    getPlayerMechanicsUI = function() return ui end
    ZeD = {
        tr = function(k, ...)
            local t, args = WORDS[k] or k, { ... }
            return (string.gsub(t, "%%(%d)", function(n) local v = args[tonumber(n)]; return v ~= nil and tostring(v) or ("%" .. n) end))
        end,
        trBare = function(k) return WORDS[k] or k end,
        textCase = function(s) return s end,
        btnCase = function(s) return s end,
        MechTrailer = { focusTarget = function() return nil end },
        T = { px = function(n) return n end },
        CraftingCore = { PANE_W_SPLIT = 240 },
    }
    -- the hidden-actions sort as Molecules.lua has it, set to "folded"
    ZeD.Disclose = {
        split = function(verbs)
            local shown, hidden = {}, {}
            for _, v in ipairs(verbs or {}) do
                if v.sensible ~= false then
                    if v.canDo then shown[#shown + 1] = v else hidden[#hidden + 1] = v end
                end
            end
            return shown, hidden
        end,
        needsLine = function(v) return v.needsLine or ((v.label or "") .. " needs " .. tostring(v.needs) .. ".") end,
    }
    local f, err = loadstring(src, "@MechanicsTab.lua")
    if not f then return nil, err end
    local ok, e2 = pcall(f)
    if not ok then return nil, e2 end
    return ZeD.MechanicsTab
end

local function chr(seatIn)
    local c = { x = 0, y = 0 }
    function c:getPlayerNum() return 0 end
    function c:getPerkLevel() return 5 end
    function c:getInventory() return { haveThisKeyId = function() return true end, getNumberOfItem = function() return 3 end,
                                       containsTag = function() return true end, getFirstTypeRecurse = function() return nil end } end
    function c:isRecipeActuallyKnown() return true end
    function c:getVehicle() return seatIn end
    function c:getX() return self.x end
    function c:getY() return self.y end
    function c:getZ() return 0 end
    return c
end
local function car(f)
    local v = { parts = {}, x = f.x or 0, y = 0 }
    function v:getId() return f.id or 1 end
    function v:getPartById(id) return self.parts[id] end
    function v:getScript() return { getEngineRepairLevel = function() return 1 end } end
    function v:isEngineStarted() return false end
    function v:isEngineRunning() return false end
    function v:canInstallPart() return f.canInstall == true end
    function v:canUninstallPart() return f.canUninstall == true end
    function v:getKeyId() return 7 end
    function v:isHotwired() return false end
    function v:getX() return self.x end
    function v:getY() return self.y end
    function v:getZ() return 0 end
    function v:getSquare() return {} end
    function v:isRemovedFromWorld() return false end
    function v:setMechanicUIOpen(on) self.mechOpen = on end
    function v:setActiveInBullet() end
    W.v = v
    return v
end
local function verbIn(list, id) for _, sv in ipairs(list or {}) do if sv.id == id then return sv end end return nil end

-- ---------------------------------------------------------------------------
local function run(src, wwSrc)
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

    -- M4: a tire at 100 with what its repair needs at hand
    try("M4", function()
        local v = car({})
        local function tire(cond)
            return partStub("TireFrontLeft", { cond = cond, item = { fixes = { 1 } }, itype = typeList({ "Base.OldTire1" }), repairMech = true })
        end
        local function needs(cond)
            local p = tire(cond)
            v.parts.TireFrontLeft = p
            local s = { pick = 1, fixPick = 1, fixCache = { key = "TireFrontLeft", t = 1000, rows = { { ok = true } } } }
            return T.needsFor(s, p, "fix", chr(nil), v), s, p
        end
        local n100, s, p = needs(100)
        local n90 = needs(90)
        local cm = T.cardModel(s, p, chr(nil), v)
        local fx = verbIn(cm.shown, "fix")
        return n100.ok == false and n100.line == FULL and n90.ok == true and fx ~= nil and fx.canDo == false
            and cm.primary ~= "fix",
            "at 100 ok " .. tostring(n100.ok) .. ", line " .. tostring(n100.line) .. "; at 90 " .. tostring(n90.ok)
            .. "; shown greyed " .. tostring(fx and not fx.canDo)
    end)
    -- M4 (the engine): Repair engine at 100 stays, greyed, with the same words
    try("M4eng", function()
        local v = car({})
        local eng = partStub("Engine", { cond = 100, item = {}, cat = "engine" })
        v.parts.Engine = eng
        local s = { pick = 1, fixPick = 1 }
        local n = T.needsFor(s, eng, "repairEngine", chr(nil), v)
        local cm = T.cardModel(s, eng, chr(nil), v)
        local re = verbIn(cm.shown, "repairEngine")
        return n.ok == false and n.line == FULL and re ~= nil and re.canDo == false,
            "line " .. tostring(n.line) .. ", shown " .. tostring(re ~= nil)
    end)

    -- M6: seated in a car
    try("M6needs", function()
        local v = car({ canUninstall = true })
        local bat = partStub("Battery", { item = { fixes = {} }, itype = typeList({ "Base.CarBattery1" }),
            tables = { uninstall = { skills = "Mechanics:1" } } })
        v.parts.Battery = bat
        local inCar = car({ id = 2 })
        W.v = v
        local n = T.needsFor({ pick = 1, fixPick = 1 }, bat, "uninstall", chr(inCar), v)
        local n0 = T.needsFor({ pick = 1, fixPick = 1 }, bat, "uninstall", chr(nil), v)
        local cm = T.cardModel({ pick = 1, fixPick = 1 }, bat, chr(inCar), v)
        local un = verbIn(cm.shown, "uninstall")
        return n.ok == false and n.line == SEATED and n0.ok == true and un ~= nil and un.canDo == false,
            "seated ok " .. tostring(n.ok) .. ", line " .. tostring(n.line) .. ", standing ok " .. tostring(n0.ok)
    end)
    try("M6press", function()
        local v = car({ canUninstall = true })
        local bat = partStub("Battery", { item = {}, itype = typeList({ "Base.CarBattery1" }), tables = { uninstall = {} } })
        v.parts.Battery = bat
        W.said, W.ran = {}, {}
        T.runVerb({ pick = 1, fixPick = 1 }, "uninstall", bat, chr(car({ id = 2 })))
        local ranSeated, saidSeated = #W.ran, W.said[1]
        W.said, W.menus = {}, {}
        T.partContextMenu(bat, chr(car({ id = 2 })), {}, 10, 10)
        local menus, saidMenu = #W.menus, W.said[1]
        return ranSeated == 0 and saidSeated == SEATED and menus == 0 and saidMenu == SEATED,
            "ran " .. ranSeated .. ", said " .. tostring(saidSeated) .. ", menus " .. menus .. ", said " .. tostring(saidMenu)
    end)

    -- M7: leaving the tab ends nothing; walking away does, with no window drawn
    try("M7tab", function()
        local body = string.match(wwSrc or "", "(function ZeD_WorldWindow%._tabLeft%(win%).-\r?\nend)")
        if not body then return false, "no _tabLeft" end
        local ended = 0
        ZeD_WorldWindow = {}
        ZeD.MechanicsTab = { endLooks = function() ended = ended + 1 end }
        getSpecificPlayer = function() return {} end
        local f = loadstring(body)
        f()
        ZeD_WorldWindow._tabLeft({ _activeTab = "vehicle", playerNum = 0, _playerObj = {} })
        ZeD.MechanicsTab = MT
        return ended == 0, "looks ended " .. ended
    end)
    try("M7reach", function()
        if not MT.reachCheck then return false, "no reach check" end
        local c = chr(nil)
        local near = car({ id = 11, x = 3 })
        local far = car({ id = 12, x = 8 })
        MT._insp[11] = { vehicle = near, chr = c }
        MT._insp[12] = { vehicle = far, chr = c }
        MT._reachDue = nil
        MT.reachCheck(5000)
        local keep, gone = MT._insp[11] ~= nil, MT._insp[12] == nil
        MT._insp[11] = nil
        local stored = string.find(src, "hood = usedHood or (prev and prev.hood), chr = chr }", 1, true)
        return keep and gone and far.mechOpen == false and #W.ticks > 0 and stored ~= nil,
            "near kept " .. tostring(keep) .. ", far ended " .. tostring(gone) .. ", on the player's update " .. tostring(#W.ticks > 0)
    end)

    -- M10g: folded, a missing tire, no spare in reach
    try("M10g", function()
        local v = car({ canInstall = false })
        local tire = partStub("TireFrontLeft", { itype = typeList({ "Base.OldTire1", "Base.NormalTire1" }),
            tables = { install = { skills = "Mechanics:1" } }, cat = "tire" })
        v.parts.TireFrontLeft = tire
        W.byType = {}
        local s = { pick = 1, fixPick = 1 }
        local cm = T.cardModel(s, tire, chr(nil), v)
        local ins = verbIn(cm.shown, "install")
        return ins ~= nil and ins.canDo == false and verbIn(cm.hidden, "install") == nil and s.verb == "install",
            "shown " .. tostring(ins ~= nil) .. ", folded " .. tostring(verbIn(cm.hidden, "install") ~= nil) .. ", verb " .. tostring(s.verb)
    end)
    return res, why
end

-- ---------------------------------------------------------------------------
local BUGS = { "M4", "M4eng", "M6needs", "M6press", "M7tab", "M7reach", "M10g" }
local MTP, WWP = "42/media/lua/client/ZeD/MechanicsTab.lua", "42/media/lua/client/ZeD/ZeD_WorldWindow.lua"
local src, ww = readFile(ROOT .. MTP), readFile(ROOT .. WWP)
check("MechanicsTab.lua is read", src ~= nil)
local res, why = run(src or "", ww)
check("the tab loads on the stubs", res.load, why.load)
for _, b in ipairs(BUGS) do check(b .. " (the tab now)", res[b] == true, why[b]) end

local old, oldWW = gitShow(MTP), gitShow(WWP)
if old ~= "" then
    local ro, wo = run(old, oldWW)
    check("the old tab loads on the stubs", ro.load, wo.load)
    for _, b in ipairs(BUGS) do check(b .. " fails on the old tab", ro[b] ~= true, wo[b]) end
else
    out("(no git: the old tab's checks skipped)")
end

print = out
out("mt_calls_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
