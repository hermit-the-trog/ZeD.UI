-- ZeDUI/tools/qa/b8r3_sim.lua  (Nov 8 2026, Build; QA round 3 for beta 8): a player's context menu that is not there.
-- The game drops a player's UI data when the character dies (ISPlayerData.destroyPlayerData), so getPlayerContextMenu(n)
-- answers nil and vanilla's ISContextMenu.get throws at its first line (hideAndChildren of nil). QA's Wounds Overhaul run
-- hit it three ways: ZeD's get override, ZeD's Examine menu, and the mod's own menu code through get. This sim runs ZeD's
-- real files on small stubs:
--   Overrides/ContextMenu.lua   get with a menu (vanilla reached, anchor stamped), without one (nil, vanilla never asked), no player
--   HealthTab.lua               treat (the function cut out of the file): no menu for the doctor's player, nothing opens, nothing throws
--   ModSupport/WoundsOverhaul.lua  openPart on a part the mod holds back: with a menu Examine and the gray line, without one nothing
-- Run from the repo root:   lua51 ZeDUI/tools/qa/b8r3_sim.lua         (expects "0 failed")
-- Last line: "b8r3_sim: N checks, M failed"; exit 1 when any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]b8r3_sim%.lua$", "")
local LUA = (os.getenv("ZEDSIM_ZL") or (ROOT .. "42/media/lua/")) .. "client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readAll(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
local function section(s) print("-- " .. s) end
local noop = function() end

-- ---------------------------------------------------------------------------
-- the game's player data: a menu per player number, or none (a dead player)
-- ---------------------------------------------------------------------------
local MENUS = {}
getPlayerContextMenu = function(n) return MENUS[n] end
local function newMenu()
    local m = { options = {}, hidden = 0, visible = true }
    function m:hideAndChildren() self.hidden = self.hidden + 1 end
    function m:addOption(name, target, fn, ...) local o = { name = name, target = target, onSelect = fn }; self.options[#self.options + 1] = o; return o end
    function m:getIsVisible() return self.visible end
    return m
end
local VANILLA_GETS = 0
local function vanillaGet(player, x, y)
    VANILLA_GETS = VANILLA_GETS + 1
    local context = getPlayerContextMenu(player)
    context:hideAndChildren()          -- (ISContextMenu.lua:1168: the line that threw on nil)
    context.requestX, context.requestY = x, y
    return context
end

local realRequire = require
require = function() end

-- ---------------------------------------------------------------------------
section("Overrides/ContextMenu.lua: get")
-- ---------------------------------------------------------------------------
do
    ISContextMenu = { get = vanillaGet, clear = noop, prerender = noop, render = noop }
    ISWorldObjectContextMenu = { createMenu = noop }
    ISInventoryPaneContextMenu = { createMenu = noop }
    local safe = false
    ZeD = { Safe = { on = function() return safe end } }
    assert(loadfile(LUA .. "Overrides/ContextMenu.lua"))()

    MENUS[0] = newMenu()
    VANILLA_GETS = 0
    local ok, ctx = pcall(ISContextMenu.get, 0, 10, 20)
    check("a menu there: get answers it and reaches vanilla once", ok and ctx == MENUS[0] and VANILLA_GETS == 1, ctx)
    check("a menu there: the anchor is stamped (cursor at x, y)", ctx and ctx._zedAnchorMode == "cursor" and ctx._zedAnchorX == 10 and ctx._zedAnchorY == 20)
    check("a menu there: vanilla hid the old one first", MENUS[0].hidden == 1, MENUS[0].hidden)

    MENUS[1] = nil                       -- player 1's UI data is gone (the character died)
    VANILLA_GETS = 0
    local ok2, ctx2 = pcall(ISContextMenu.get, 1, 5, 5)
    check("no menu for the player: get raises nothing", ok2, ctx2)
    check("no menu for the player: it answers nil", ctx2 == nil)
    check("no menu for the player: vanilla's get is never asked (it would throw)", VANILLA_GETS == 0, VANILLA_GETS)

    local ok3, ctx3 = pcall(ISContextMenu.get, nil, 5, 5)
    check("no player number: nothing raised, nil", ok3 and ctx3 == nil and VANILLA_GETS == 0, ctx3)

    safe = true                          -- safe mode hands straight to vanilla, but still never throws
    VANILLA_GETS = 0
    local ok4, ctx4 = pcall(ISContextMenu.get, 1, 5, 5)
    check("safe mode, no menu: nil, nothing raised, vanilla not asked", ok4 and ctx4 == nil and VANILLA_GETS == 0, ctx4)
    MENUS[0]._zedAnchorMode = nil       -- (the one menu per player is reused: forget the stamp of the first call)
    local ok5, ctx5 = pcall(ISContextMenu.get, 0, 5, 5)
    check("safe mode, a menu: vanilla's answer as it is (no anchor stamped)", ok5 and ctx5 == MENUS[0] and ctx5._zedAnchorMode == nil and VANILLA_GETS == 1)
    safe = false

    -- the game's own global missing (early in a load): vanilla decides, as before
    local saved = getPlayerContextMenu
    getPlayerContextMenu = nil
    VANILLA_GETS = 0
    local vget = ISContextMenu.get
    local okA = pcall(function() return vget(0, 1, 1) end)
    check("the global missing: vanilla is asked (it decides)", VANILLA_GETS == 1 and okA == false)
    getPlayerContextMenu = saved
    ISContextMenu, ISWorldObjectContextMenu, ISInventoryPaneContextMenu, ZeD = nil, nil, nil, nil
end

-- ---------------------------------------------------------------------------
section("HealthTab.lua: treat")
-- ---------------------------------------------------------------------------
do
    local src = readAll(LUA .. "HealthTab.lua")
    local a = string.find(src, "\nfunction ZeD.HealthTab.treat(", 1, true)
    local b = a and string.find(src, "\nend\n", a + 1, true)
    check("treat is found in HealthTab.lua", a ~= nil and b ~= nil)
    if a and b then
        local chunk = string.sub(src, a + 1, b + 4)
        local opened = 0
        ZeD = { HealthTab = { extras = {} } }
        ISHealthPanel = { checkItems = noop, checkContainerItems = noop,
            doBodyPartContextMenu = function(self, bp, x, y) opened = opened + 1 end }
        assert(loadstring(chunk, "=treat"))()
        local function person(n)
            return { getPlayerNum = function() return n end }
        end
        local anchor = { getAbsoluteX = function() return 0 end, getAbsoluteY = function() return 0 end }
        local patient, doctor, bp = person(0), person(1), {}
        MENUS[0], MENUS[1] = newMenu(), nil

        local ok, r = pcall(ZeD.HealthTab.treat, patient, nil, bp, anchor, 1, 2, nil)
        check("your own body, your menu there: the game's menu is opened", ok and r ~= nil and opened == 1, r)
        opened = 0
        local ok2, r2 = pcall(ZeD.HealthTab.treat, patient, doctor, bp, anchor, 1, 2, nil)
        check("a doctor with no menu (player 1 gone): nothing opens, nothing raised", ok2 and r2 == nil and opened == 0, r2)
        MENUS[1] = newMenu()
        local ok3, r3 = pcall(ZeD.HealthTab.treat, patient, doctor, bp, anchor, 1, 2, nil)
        check("a doctor with a menu: the game's menu opens for the doctor", ok3 and r3 ~= nil and opened == 1, r3)
        MENUS[0] = nil
        opened = 0
        local ok4, r4 = pcall(ZeD.HealthTab.treat, patient, nil, bp, anchor, 1, 2, nil)
        check("your own body, no menu (you died): nothing opens, nothing raised", ok4 and r4 == nil and opened == 0, r4)
        local ok5 = pcall(ZeD.HealthTab.treat, nil, nil, bp, anchor)
        check("no patient: returns as before", ok5)
        ZeD, ISHealthPanel = nil, nil
    end
end

-- ---------------------------------------------------------------------------
section("ModSupport/WoundsOverhaul.lua: the part's menu")
-- ---------------------------------------------------------------------------
do
    local EXTRA, FAULTS = nil, {}
    local WORDS = { UI_ZeD_Health_Examine = "Examine", IGUI_Wounds_Unexamined = "Something is wrong here." }
    getActivatedMods = function()
        return { size = function() return 1 end, get = function() return "WoundsOverhaul" end }
    end
    getTimestampMs = function() return 1000 end
    ZeD = { tr = function(k) return WORDS[k] or k end,
        logOnce = function(k, m) FAULTS[#FAULTS + 1] = tostring(k) .. ": " .. tostring(m) end,
        HealthTab = { addExtras = function(id, s) EXTRA = s end } }
    Wounds = { body = { needsExamFirst = function() return true end, keyOfType = function() return "k" end,
                        damage = function() return {} end } }
    WoundsBodyView = { refresh = noop, beginExamine = noop }
    local asked = 0
    ISContextMenu = { get = function(num, x, y)
        asked = asked + 1
        local ctxt = getPlayerContextMenu(num)
        if not ctxt then return nil end              -- (ZeD's get answers nil for a player with no menu)
        return ctxt
    end }
    assert(loadfile(LUA .. "ModSupport/WoundsOverhaul.lua"))()
    check("the mod's support file registered its hooks", EXTRA ~= nil and type(EXTRA.openPart) == "function")
    if EXTRA then
        local player = { getPlayerNum = function() return 0 end }
        local part = { getType = function() return "Hand_L" end }
        local panel = { getAbsoluteX = function() return 3 end, getAbsoluteY = function() return 4 end }
        MENUS[0] = newMenu()
        local ok, done = pcall(EXTRA.openPart, player, part, panel, 1, 2)
        check("a part held back, a menu there: handled", ok and done == true, done)
        local names = {}
        for _, o in ipairs(MENUS[0].options) do names[#names + 1] = o.name end
        check("it offers Examine and the mod's gray line", names[1] == "Examine" and names[2] == "Something is wrong here.", table.concat(names, " | "))
        check("the gray line is not available", MENUS[0].options[2] and MENUS[0].options[2].notAvailable == true)
        MENUS[0] = nil                       -- the character died: no menu
        local ok2, done2 = pcall(EXTRA.openPart, player, part, panel, 1, 2)
        check("a part held back, no menu: nothing raised", ok2, done2)
        check("no menu: it counts as handled (the game's own menu is not tried, it would throw too)", done2 == true, done2)
        check("no menu: ZeD logged no fault", #FAULTS == 0, FAULTS[1])
    end
    getActivatedMods, getTimestampMs, ZeD, Wounds, WoundsBodyView, ISContextMenu = nil, nil, nil, nil, nil, nil
end

require = realRequire
print("b8r3_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
