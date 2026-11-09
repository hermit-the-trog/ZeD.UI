-- ZeDUI/tools/qa/compat_b10_sim.lua  (Nov 8 2026, Build): punch list 116 and 117, with no game running.
--   * 116 Ellie's Tattoo Parlor V4: ZeD_MakeUp.lua's mirror rule (MU.mirror) through the game's make-up menu function
--     as the mod patches it (the mod's own ETPMakeUpUIFix.lua and ETPContextMenu.lua, loaded from the Workshop copy when it
--     is on this machine; the game's doMakeUpMenu stood in for by its mirror rule). The patch used to error on ZeD's
--     stand-in item (no getMakeUpType) and ZeD fell back to "needs a mirror".
--   * 117 Custom Map Labels: the mod's own CustomMapLabels.lua (and its three data files) on the real
--     Overrides/WorldMap.lua and ModSupport/CustomMapLabels.lua, both orders of the two OnGameStart handlers. Without the
--     support the mod stops at its line 93 (no game map object); with it the game's map is made for the mod, the labels
--     are written, the map is closed again, and every later ShowWorldMap is ZeD's.
-- A mod that is not on this machine has its checks skipped, said in one line.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/compat_b10_sim.lua
-- It prints FAIL lines and a last line "compat_b10_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]compat_b10_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local WS = "E:/Project Zomboid/steamapps/workshop/content/108600/"
local ETP = WS .. "2735059209/mods/Ellie'sTattooParlorV4/42/media/lua/client/ETPUI/"
local CML = WS .. "3559737194/mods/CustomMapLabels/42/media/lua/client/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function exists(p) local f = io.open(p, "rb"); if f then f:close(); return true end return false end

local function loadFile(path)
    local fn, err = loadfile(path)
    if not fn then return false, err end
    return pcall(fn)
end

-- ---------------------------------------------------------------------------
-- STUBS (shared)
-- ---------------------------------------------------------------------------
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, contains = function(_, v)
        for _, x in ipairs(t) do if x == v then return true end end return false end }
end
local ACTIVE = {}
getActivatedMods = function() return list(ACTIVE) end
local TEXT = { Tooltip_NeedMirror = "You need a mirror.", IGUI_MakeUp = "Make Up" }
getText = function(k, a) local s = TEXT[k] or k; if a then s = s .. ":" .. tostring(a) end return s end
getTextOrNull = function(k) return "text of " .. tostring(k) end
local FIRED = {}
Events = setmetatable({}, { __index = function(t, k)
    local e = { fns = {} }
    e.Add = function(fn) e.fns[#e.fns + 1] = fn end
    e.Remove = function(fn) for i, f in ipairs(e.fns) do if f == fn then table.remove(e.fns, i); return end end end
    rawset(t, k, e)
    return e
end })
local function fire(name, ...)
    local copy = {}
    for i, f in ipairs(Events[name].fns) do copy[i] = f end
    local errs = {}
    for _, f in ipairs(copy) do
        local ok, err = pcall(f, ...)
        if not ok then errs[#errs + 1] = tostring(err) end
    end
    return errs
end
instanceof = function() return false end
require = function() return nil end
ZeD = { logs = {}, logOnce = function(id, err) ZeD.logs[#ZeD.logs + 1] = id .. ": " .. tostring(err) end }

-- ===========================================================================
section("116: Ellie's Tattoo Parlor V4, the mirror rule")
-- ===========================================================================
do
    -- the player: a mirror in the bag or not; no world mirror
    local haveMirror = false
    local inv = {
        contains = function(_, t) return haveMirror and t == "Mirror" end,
        FindAndReturn = function() return nil end,
    }
    local p = { getInventory = function() return inv end, getVehicle = function() return nil end }

    -- the game's doMakeUpMenu, its mirror rule only (ISInventoryPaneContextMenu.lua:4299)
    local TIPS = { used = {}, pool = {} }
    ISInventoryPaneContextMenu = { tooltipsUsed = TIPS.used, tooltipPool = TIPS.pool }
    ISInventoryPaneContextMenu.addToolTip = function() local t = { description = "" }; TIPS.used[#TIPS.used + 1] = t; return t end
    ISInventoryPaneContextMenu.doMakeUpMenu = function(context, makeup, playerObj)
        local option = context:addOption(getText("IGUI_MakeUp"), makeup, nil, playerObj)
        local mirror = playerObj:getInventory():contains("Mirror") or makeup:getFullType() == "Base.MakeupFoundation"
        if not mirror then
            local tooltip = ISInventoryPaneContextMenu.addToolTip()
            option.notAvailable = true
            tooltip.description = getText("Tooltip_NeedMirror")
            option.toolTip = tooltip
        end
    end
    local vanillaFn = ISInventoryPaneContextMenu.doMakeUpMenu

    local okZ, errZ = loadFile(CLIENT .. "ZeD_MakeUp.lua")
    check("ZeD_MakeUp.lua loads", okZ, errZ)
    local MU = ZeD.MakeUp
    local function item(ft, kind)
        return { getFullType = function() return ft end, getMakeUpType = function() return kind end,
                 getDisplayName = function() return "name" end }
    end

    -- without the mod: the rule as it was
    local ok1, why1 = MU.mirror(p, nil)
    check("no mod, no mirror: false with the game's words", ok1 == false and why1 == TEXT.Tooltip_NeedMirror, why1)
    haveMirror = true
    check("no mod, a mirror: true", MU.mirror(p, nil) == true)
    haveMirror = false

    if not (exists(ETP .. "ETPMakeUpUIFix.lua") and exists(ETP .. "ETPContextMenu.lua")) then
        print("(skipped: Ellie's Tattoo Parlor V4 is not on this machine)")
    else
        -- the mod's own two files, on stubs of what they call
        local etpTooltipPool = {}
        ISToolTip = { new = function() return { initialise = noop, setVisible = noop, description = "" } end }
        getScriptManager = function() return { FindItem = function() return { getDisplayName = function() return "Item" end } end } end
        instanceItem = function() return item("ElliesTattooParlor.FilledTattooNeedle", "Tattoo") end
        local realRequire = require
        local ETPCtx
        require = function(name)
            if name == "ISUI/ISInventoryPaneContextMenu" then return ISInventoryPaneContextMenu end
            if name == "ETPUI/ETPTattooUI" then return { new = noop } end
            if name == "ETPUI/ETPContextMenu" then
                if not ETPCtx then
                    local fn = assert(loadfile(ETP .. "ETPContextMenu.lua"))
                    ETPCtx = fn()
                end
                return ETPCtx
            end
            return nil
        end
        local okE, errE = loadFile(ETP .. "ETPMakeUpUIFix.lua")
        require = realRequire
        check("the mod's make-up patch loads", okE, errE)
        local patched = ISInventoryPaneContextMenu.doMakeUpMenu
        check("the menu function is the mod's now", patched ~= vanillaFn)

        -- the cause: the old stand-in (a table with a full type only) and a plain menu table
        local oldStandIn = { getFullType = function() return "" end }
        local oldRec = { options = {} }
        function oldRec:addOption(n, t, s, a) local o = { name = n }; self.options[#self.options + 1] = o; return o end
        local okOld = pcall(patched, setmetatable(oldRec, { __index = function() return function() end end }), oldStandIn, p)
        check("(the cause) the patch errors on the old stand-in", okOld == false)

        -- now: the stand-in gives what the patch reads
        ZeD.logs = {}
        local okN, whyN = MU.mirror(p, nil)
        check("mod on, no mirror: false with the game's words", okN == false and whyN == TEXT.Tooltip_NeedMirror, whyN)
        check("no error logged", #ZeD.logs == 0, ZeD.logs[1])
        haveMirror = true
        local okM, whyM = MU.mirror(p, nil)
        check("mod on, a mirror in the bag: true (was: needs a mirror)", okM == true and whyM == nil, whyM)
        check("no error logged with a mirror", #ZeD.logs == 0, ZeD.logs[1])
        local okL = MU.mirror(p, item("Base.Lipstick", "Lipstick"))
        check("a real make-up item with the mod on: true", okL == true)
        local okT = MU.mirror(p, item("ElliesTattooParlor.UpperBody_Tattoo_Heart", "Tattoo"))
        check("a tattoo item through the mod's patch: true, no error", okT == true and #ZeD.logs == 0, ZeD.logs[1])
        haveMirror = false
        local okT2, whyT2 = MU.mirror(p, item("ElliesTattooParlor.UpperBody_Tattoo_Heart", "Tattoo"))
        check("a tattoo item, no mirror: false with a reason", okT2 == false and type(whyT2) == "string" and whyT2 ~= "", whyT2)

        -- an item the patch chokes on (no getMakeUpType): the stand-in answers in its place
        ZeD.logs = {}
        haveMirror = true
        local broken = { getFullType = function() return "Base.Weird" end }
        local okB = MU.mirror(p, broken)
        check("a broken item: the stand-in answers, true", okB == true)
        check("the broken item's error is logged once", #ZeD.logs == 1 and ZeD.logs[1]:find("makeup mirror item", 1, true) ~= nil, ZeD.logs[1])
        haveMirror = false
        local okB2, whyB2 = MU.mirror(p, broken)
        check("a broken item, no mirror: false with the game's words", okB2 == false and whyB2 == TEXT.Tooltip_NeedMirror, whyB2)

        -- the foundation is its own mirror (the real item, so it stays real when the patch is fine)
        check("the foundation: a mirror of its own", MU.mirror(p, item("Base.MakeupFoundation", "Foundation")) == true)
        ISInventoryPaneContextMenu.doMakeUpMenu = vanillaFn
    end
end

-- ===========================================================================
section("117: Custom Map Labels, the game's map at start")
-- ===========================================================================
do
    if not (exists(CML .. "CustomMapLabels.lua") and exists(CML .. "MapLabelData.lua")) then
        print("(skipped: Custom Map Labels is not on this machine)")
    else
        -- a run is one game start: fresh globals, the real WorldMap.lua, the mod's files, optionally the support
        local function run(withSupport, supportFirst)
            Events = setmetatable({}, getmetatable(Events))
            ISWorldMap_instance = nil
            local R = { closed = 0, shown = 0, zedOpened = 0, zedPopout = 0, added = {}, removedAll = false }
            local sym = {
                getSymbolCount = function() return 0 end,
                addUntranslatedText = function(_, key, layer, x, y)
                    local s = { key = key }
                    for _, n in ipairs({ "setRGBA", "setScale", "setRotation", "setAnchor", "setMatchPerspective", "setApplyZoom",
                                         "setMinZoom", "setMaxZoom", "setUserDefined" }) do s[n] = noop end
                    R.added[#R.added + 1] = s
                    return s
                end,
            }
            local mapAPI = { getSymbolsAPIv2 = function() return sym end }
            ISWorldMap = {
                IsAllowed = function() return true end,
                HideWorldMap = noop, ToggleWorldMap = noop,
                ShowWorldMap = function(playerNum)   -- the game's: one map object, kept
                    R.shown = R.shown + 1
                    if not ISWorldMap_instance then
                        ISWorldMap_instance = {
                            javaObject = { getAPIv3 = function() return mapAPI end },
                            close = function() R.closed = R.closed + 1 end,
                        }
                    end
                end,
            }
            ACTIVE = { "EchoCreek MilitaryBase", "ZeD_UI" }
            if withSupport then ACTIVE[#ACTIVE + 1] = "CustomMapLabels" end
            ZeD = { logs = {}, logOnce = noop, Safe = { on = function() return false end }, windowsFor = function() return true end,
                    ModSupport = nil }
            ZeD.MapsTab = { openPopout = function() R.zedPopout = R.zedPopout + 1 end }
            local strip = { _hitZones = { { id = "tab:maps", x = 0, y = 0 } }, onMouseDown = noop }
            local win = { _actionTabStrip = strip, _activeTab = "maps" }
            local isOpen = false
            ZeD_WorldWindow = {
                open = function() isOpen = true; R.zedOpened = R.zedOpened + 1 end,
                getWindow = function() return win end,
                isOpen = function() return isOpen end,
            }
            getSpecificPlayer = function() return {} end
            getCore = function() return { saveOptions = noop } end

            local function modules()
                local okW, errW = loadFile(CLIENT .. "Overrides/WorldMap.lua")
                assert(okW, errW)
                local okS, errS = true, nil
                if withSupport then okS, errS = loadFile(CLIENT .. "ModSupport/CustomMapLabels.lua"); assert(okS, errS) end
            end
            local realRequire = require
            require = function(name)
                local f = ({ LabelDefaults = "LabelDefaults.lua", MapLabelData = "MapLabelData.lua", VanillaLabelData = "VanillaLabelData.lua" })[name]
                if f then return assert(loadfile(CML .. f))() end
                return nil
            end
            if supportFirst then
                -- the support file loading before the override (the alphabetical order the game loads them in)
                if withSupport then assert(loadFile(CLIENT .. "ModSupport/CustomMapLabels.lua")) end
                assert(loadFile(CLIENT .. "Overrides/WorldMap.lua"))
            else
                modules()
            end
            ISWorldMap_instance = nil
            assert(loadFile(CML .. "CustomMapLabels.lua"))   -- the mod adds its OnGameStart handler
            require = realRequire
            R.errs = fire("OnGameStart")
            R.ticksBefore = #Events.OnTick.fns
            R.errsTick = fire("OnTick")
            R.ticksAfter = #Events.OnTick.fns
            -- the player opens the map after the start
            ISWorldMap.ShowWorldMap(0)
            return R
        end

        local A = run(false, false)
        check("(the cause) no support: the mod errors at the start", #A.errs == 1 and A.errs[1]:find("CustomMapLabels.lua:93", 1, true) ~= nil, A.errs[1])
        check("(the cause) ZeD's map took the call, no game map", A.zedOpened >= 1 and A.shown == 0 and #A.added == 0)

        local B = run(true, false)
        check("support: the mod runs without an error", #B.errs == 0, B.errs[1])
        check("support: the mod's labels were written", #B.added >= 1, #B.added)
        check("support: the mod closed the game's map", B.closed == 1, B.closed)
        check("support: ZeD's map was not opened at the start", B.zedOpened == 1 and B.shown == 1, B.zedOpened .. "/" .. B.shown)
        check("support: the window closed after the first tick", B.ticksAfter == 0)
        check("support: the later ShowWorldMap is ZeD's map", B.zedOpened == 1 and B.zedPopout == 1 and B.shown == 1,
              B.zedOpened .. "/" .. B.zedPopout .. "/" .. B.shown)

        local C = run(true, true)
        check("support file first: no error, labels written", #C.errs == 0 and #C.added >= 1, C.errs[1])
        check("support file first: the later ShowWorldMap is ZeD's", C.shown == 1 and C.zedOpened == 1)

        local D = run(false, true)   -- the mod off: the support file not loaded, ZeD as before
        check("mod off: the hook list is empty", #ZeD.WorldMapHook.vanillaWhen == 0)
        check("mod off: nothing changes for the map", D.shown == 0 and D.zedOpened >= 1)
    end
end

print(string.format("compat_b10_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
