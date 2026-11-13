-- ZeDUI/tools/qa/summercar_sim.lua  (Nov 12 2026, Build): ModSupport/MaskaradsSummerCar.lua with ZeD's Vehicle tab and
-- no game running. The real MechanicsTab.lua and the real support file run on Lua 5.1 stubs of the game, with a FAKE
-- Summer Car written here from the mod's 0.0.1 code (its window's openFromMechanics with its own placement rule, its
-- update's close test, its close with the dismissal and the pad hand-back, its menu wrap, its lift and ECU windows).
-- The mod's own file is checked by summercar_contract_sim.lua; this one needs no mod files.
--   VIS      what the anchor counts as shown: closed, another tab, folded, rolled, not inspected, dead, safe mode,
--            player 1 (gone or hidden for now); a card over the tab and the rolled inventory side keep it shown
--   AUTO     opens once shown, accessible and still for 150 ms; not while the window moves, paused, seated (yes in
--            debug); another car closes the old window and opens one for the new car
--   DISMISS  the player's close lasts through a fold, a roll, another tab and a card; it ends with the World window
--            closed, another car, the inspection over, access lost and back, and death; a fold's own close comes back
--   EDGE     nothing opens that the mod's next update would close: past six tiles, the car off its square, no assembly
--   PLACE    the mod's free side; where it would slide ZeD's window, the larger side at its widths; the rod counted; the
--            band swept at 1080 and 1280; ZeD's window never moves; a World window that grows into it moves it again
--            unless the player dragged it
--   CLOSE    every hide shape closes the anchored window in the same frame with close(false); the ECU and lift windows
--            are left alone
--   HOLD     the pointer on the engine window or a menu up holds the roll-up (from nil too); a longer hold stays
--   MENU     the mod's Inspect option in ZeD's part menu points at the anchor, no pad grab; picking it opens beside
--   VERBS    the Engine's footer: Inspect engine components, no Repair engine / Take engine parts; the hood's line
--   PAD      the anchor answers every pad method; a pad handed to it goes back with the game's own stack intact
--   LIFT     the auto-open leaves the mod's lift and ECU windows; the footer verb may replace them
--   FAIL     missing pieces, a throwing openFromMechanics, a throwing anchor: no error escapes, the window closes
--   OFF      mod off: the file returns first, the tab is exactly as built
--   RELOAD   the support file twice; MechanicsTab.lua reloaded after it keeps the verb's words and order
--   OLD      the base MechanicsTab.lua (git show BASE) without the support file: the reported bug reproduces
-- What it can't show: the real game's drawing and timing; the mod's own code (the contract sim's job).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/summercar_sim.lua
-- It prints FAIL lines and a last line "summercar_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]summercar_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/"
local BASE = "feed35cbd"   -- the commit this work started from (its MechanicsTab.lua is "the old tab")
local out = print

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        out("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) out("-- " .. s) end
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- English words: ZeD's UI.json, and the few of the game's and the mod's this file shows
local WORDS = {}
for k, v in (readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""):gmatch('"([%w_]+)"%s*:%s*"(.-)"%s*,?%s*\r?\n') do WORDS[k] = v end
WORDS.UI_MSC_InspectEngineComponents = "Inspect engine components"
WORDS.UI_MSC_InspectEngineComponentsTooltip = "Open the internal engine-component view."
WORDS.UI_MSC_HoodMustBeOpen = "The hood must be open to inspect engine components."
WORDS.UI_MSC_EngineAssemblyUnavailable = "Engine components are unavailable because the engine is not installed or has not synchronized."
WORDS.UI_MSC_RemoveEngineAtLift = "Remove engine at lift"
WORDS.IGUI_VehiclePartEngineDoor = "Hood"
WORDS.IGUI_RepairEngine = "Repair Engine"
WORDS.IGUI_TakeEngineParts = "Take Engine Parts"
check("ZeD's words are read", WORDS.UI_ZeD_Veh_NothingNeeded ~= nil and WORDS.UI_ZeD_Veh_StClosed ~= nil)

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the tab, the support file and the fake mod ask
-- ---------------------------------------------------------------------------
local P = {}            -- the world of one setup
local PRINTS = {}
local FAULTS = {}
local clock = 1000000

local function newEvent()
    local e = { list = {}, adds = 0 }
    e.Add = function(f) e.adds = e.adds + 1; e.list[#e.list + 1] = f end
    e.Remove = function(f) for i = #e.list, 1, -1 do if e.list[i] == f then table.remove(e.list, i) end end end
    return e
end
local function fire(e, ...)
    local copy = {}
    for i, f in ipairs(e.list) do copy[i] = f end
    for _, f in ipairs(copy) do f(...) end
end
local function newMenu()
    local m = { options = {}, visible = false }
    function m:addOption(name, target, onSelect, p1, p2, p3)
        local o = { name = name, target = target, onSelect = onSelect, param1 = p1, param2 = p2, param3 = p3 }
        self.options[#self.options + 1] = o
        return o
    end
    function m:removeOptionByName(n)
        for i, o in ipairs(self.options) do if o.name == n then table.remove(self.options, i); return end end
    end
    function m:setVisible(b) self.visible = b end
    function m:getIsVisible() return self.visible end
    return m
end

local function newPart(pid, v)
    local p = { pid = pid, v = v }
    function p:getId() return self.pid end
    function p:getVehicle() return self.v end
    function p:getInventoryItem() return {} end
    function p:getItemType() return nil end
    function p:getWindow() return nil end
    function p:getDoor() return nil end
    function p:getItemContainer() return nil end
    function p:isContainer() return false end
    function p:getTable() return nil end
    function p:getCategory() return "engine" end
    function p:getCondition() return 80 end
    function p:getScriptPart() return { isRepairMechanic = function() return false end } end
    return p
end
local function newVehicle(id, x, y)
    local v = { id = id, x = x, y = y, access = { can = true, reason = nil }, onSquare = true }
    v.sq = { getMovingObjects = function() return { indexOf = function(_, o) return (o == v and v.onSquare) and 0 or -1 end } end }
    function v:getId() return self.id end
    function v:getX() return self.x end
    function v:getY() return self.y end
    function v:getZ() return 0 end
    function v:getSquare() if self.gone then return nil end return self.sq end
    function v:getPartById(pid) return self.parts[pid] end
    function v:getScript() return { getEngineRepairLevel = function() return 4 end } end
    v.parts = { Engine = newPart("Engine", v), EngineDoor = newPart("EngineDoor", v) }
    return v
end
local function newPlayer()
    local c = { x = 100, y = 100, dead = false, veh = nil }
    function c:getPlayerNum() return 0 end
    function c:isDead() return self.dead end
    function c:getVehicle() return self.veh end
    function c:getX() return self.x end
    function c:getY() return self.y end
    function c:DistTo(x, y) return math.sqrt((x - self.x) ^ 2 + (y - self.y) ^ 2) end
    function c:getPerkLevel() return 5 end
    function c:getInventory() return {} end
    return c
end
local function newWorldWin(chr, x, y, w, h)
    local win = { x = x, y = y, w = w, h = h, rv = true, windowShaded = false, _rolled = false, _rollW = 0,
                  _drawerEffW = 700, _playerObj = chr, _activeTab = "vehicle", _drawerMode = "tab", _drawerOpen = true }
    function win:getX() return self.x end
    function win:getY() return self.y end
    function win:getWidth() return self.w end
    function win:getHeight() return self.h end
    function win:isReallyVisible() return self.rv end
    return win
end

-- THE FAKE MOD: Summer Car 0.0.1's window, as its own code does it (MSC_EngineComponentsWindow.lua)
local function fakeMod()
    local W = { instances = {} }
    local C = {}
    function C.canAccessEngine(v) return v.access.can end
    function C.getEngineAccessReason(v) if v == nil then return "vehicleUnavailable" end return v.access.reason end
    MSC = { EngineComponentsWindow = W, EngineComponents = C, VERSION = "0.0.1" }
    P.W, P.C, P.opens, P.autoOpens = W, C, 0, 0
    local function calc(mui)
        local sw, sh = P.sw, P.sh
        local mx, my, mw = mui:getX(), mui:getY(), mui:getWidth()
        local ww = math.min(500, sw - 20)
        local avail = sw - mw - 10 - 20
        if avail >= 420 then ww = math.min(ww, avail) end
        local wh = math.min(785, sh - 20)
        local wy = math.max(10, math.min(sh - wh - 10, my))
        local rx = mx + mw + 10
        if rx + ww <= sw - 10 then return rx, wy, ww, wh, nil end
        local lx = mx - ww - 10
        if lx >= 10 then return lx, wy, ww, wh, nil end
        local comb = mw + 10 + ww
        if comb <= sw - 20 then
            local tx = math.floor((sw - comb) / 2)
            mui:setX(tx)
            return tx + mw + 10, wy, ww, wh, { originalX = mx, tiledX = tx }
        end
        return math.max(10, math.min(sw, sw - ww - 10)), wy, ww, wh, nil
    end
    local Win = {}
    Win.__index = Win
    function Win:getX() return self.x end
    function Win:getY() return self.y end
    function Win:getWidth() return self.w end
    function Win:getHeight() return self.h end
    function Win:setX(x) self.x = x end
    function Win:setY(y) self.y = y end
    function Win:setWidth(w) self.w = w end
    function Win:bringToTop() self.tops = (self.tops or 0) + 1 end
    function Win:update()
        if self.engineItem ~= nil then
            if self.engineItem.gone then self:close(false) end
            return
        end
        if self.ecuReadOnly then
            if self.playerObj:getVehicle() ~= self.vehicle then self:close(false) end
            return
        end
        if self.mechanicsUI == nil or not self.mechanicsUI:isReallyVisible() or self.mechanicsUI.vehicle ~= self.vehicle then
            self:close(false); return
        end
        if C.getEngineAccessReason(self.vehicle) ~= nil then self:close(false); return end
        if self.vehicle and self.playerObj:DistTo(self.vehicle:getX(), self.vehicle:getY()) > 6 then
            self:close(false)
        elseif not self.vehicle or not self.vehicle:getSquare() or self.vehicle:getSquare():getMovingObjects():indexOf(self.vehicle) < 0 then
            self:close(false)
        end
    end
    function Win:close(isUserDismissal)
        local isDismissed = (isUserDismissal ~= false)
        self.closed = true
        self.closedAsUser = isDismissed
        if self.mechanicsPlacement ~= nil and self.mechanicsUI ~= nil
            and math.abs(self.mechanicsUI:getX() - self.mechanicsPlacement.tiledX) < 0.1 then
            self.mechanicsUI:setX(self.mechanicsPlacement.originalX)
        end
        if self.mechanicsUI ~= nil then self.mechanicsUI.msc_userDismissed = isDismissed end
        if W.instances[self.playerNum] == self then W.instances[self.playerNum] = nil end
        local joypadData = JoypadState.players[self.playerNum + 1]
        if joypadData and self.mechanicsUI and self.mechanicsUI:isReallyVisible() then
            setJoypadFocus(self.playerNum, self.mechanicsUI)
        end
    end
    local function new(fields)
        local o = setmetatable(fields, Win)
        o.playerNum = 0
        o.minimumWidth = 420
        return o
    end
    function W.openFromMechanics(playerObj, part, mechanicsUI, isAutoOpen)
        P.calls = (P.calls or 0) + 1
        if P.openThrows then error("openFromMechanics broke") end
        local vehicle = part and part:getVehicle()
        if vehicle == nil or mechanicsUI == nil or C.getEngineAccessReason(vehicle) ~= nil then return end
        mechanicsUI.msc_userDismissed = false
        local existing = W.instances[0]
        if existing ~= nil then
            if existing.vehicle == vehicle then existing:bringToTop(); return end
            existing:close(false)
        end
        local x, y, w, h, placement = calc(mechanicsUI)
        local win = new({ x = x, y = y, w = w, h = h, playerObj = playerObj, vehicle = vehicle,
                          mechanicsUI = mechanicsUI, mechanicsPlacement = placement, autoOpen = isAutoOpen })
        W.instances[0] = win
        P.opens = P.opens + 1
        if not isAutoOpen and JoypadState.players[1] then setJoypadFocus(0, win) end
    end
    function W.openFromEngine(playerObj, engineItem)
        local e = W.instances[0]
        if e then e:close(false) end
        W.instances[0] = new({ x = 1670, y = 680, w = 500, h = 785, playerObj = playerObj, engineItem = engineItem })
    end
    function W.openFromEcu(playerObj, vehicle)
        local e = W.instances[0]
        if e then e:close(false) end
        W.instances[0] = new({ x = 1670, y = 680, w = 500, h = 631, playerObj = playerObj, vehicle = vehicle, ecuReadOnly = true })
    end
    -- the mod's install guards and its menu wrap on the game's mechanics window
    ISVehicleMechanics.MSC_originalPrerender = function() end
    local orig = ISVehicleMechanics.doPartContextMenu
    ISVehicleMechanics.MSC_originalDoPartContextMenu = orig
    function ISVehicleMechanics:doPartContextMenu(part, x, y)
        orig(self, part, x, y)
        if part == nil or part:getId() ~= "Engine" then return end
        self.context:removeOptionByName(getText("IGUI_TakeEngineParts"))
        self.context:removeOptionByName(getText("IGUI_RepairEngine"))
        local onSelect = P.menuOther and function() end or W.openFromMechanics
        local o = self.context:addOption(getText("UI_MSC_InspectEngineComponents"), getSpecificPlayer(0), onSelect, part, self)
        if C.getEngineAccessReason(part:getVehicle()) ~= nil then o.notAvailable = true end
        P.liftOpt = self.context:addOption(getText("UI_MSC_RemoveEngineAtLift"), getSpecificPlayer(0), function() end, part:getVehicle(), "remove")
        self.context:setVisible(true)
    end
end

-- One setup: a fresh game, ZeD's pieces, the real MechanicsTab.lua, the fake mod, the support file
local function setup(opts)
    opts = opts or {}
    clock = clock + 1000000
    PRINTS, FAULTS = {}, {}
    print = function(...)
        local t = {}
        for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
        PRINTS[#PRINTS + 1] = table.concat(t, " ")
    end
    P = { sw = opts.sw or 3840, sh = opts.sh or 2160, speed = 1, mouseX = 0, mouseY = 0, safe = false, reclaims = 0, debug = false }
    ZeD, MSC, ZeD_WorldWindow, ISVehicleMechanics = nil, nil, nil, nil
    require = function() end
    Events = { OnTickEvenPaused = newEvent(), OnTick = newEvent(), OnPlayerDeath = newEvent(), OnGameStart = newEvent(),
               OnMechanicActionDone = newEvent() }
    P.mods = opts.modOff and { "ZeD_UI" } or { "ZeD_UI", "\\MaskaradsSummerCar" }
    getActivatedMods = function()
        return { size = function() return #P.mods end, get = function(_, i) return P.mods[i + 1] end }
    end
    getTimestampMs = function() return clock end
    getText = function(k) return WORDS[k] or k end
    getTextOrNull = function(k) return WORDS[k] end
    getCore = function() return { getScreenWidth = function() return P.sw end, getScreenHeight = function() return P.sh end } end
    getMouseX = function() return P.mouseX end
    getMouseY = function() return P.mouseY end
    getPlayer = function() return nil end
    getSpecificPlayer = function(pn) if pn == 0 then return P.chr end return nil end
    isDebugEnabled = function() return P.debug end
    isClient = function() return false end
    isAdmin = function() return false end
    getAccessLevel = function() return "" end
    UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return P.speed end } end }
    P.ctx = newMenu()
    getPlayerContextMenu = function() return P.ctx end
    VehicleUtils = { getItems = function() return {}, {} end }
    ISTimedActionQueue = { getTimedActionQueue = function() return nil end }
    JoypadState = { players = {} }
    getJoypadFocus = function(pn) local j = JoypadState.players[pn + 1]; return j and j.focus or nil end
    setJoypadFocus = function(pn, c)
        local j = JoypadState.players[pn + 1]
        if not j then return end
        if c ~= nil and c.toString then c:toString() end
        if c ~= nil and c ~= j.focus then j.prevprevfocus = j.prevfocus; j.prevfocus = j.focus end
        j.focus = c
    end
    setPrevFocusForPlayer = function(pn)
        local j = JoypadState.players[pn + 1]
        if not j then return end
        j.focus = j.prevfocus; j.prevfocus = j.prevprevfocus; j.prevprevfocus = nil
    end
    -- ZeD's pieces the tab and the support file ask for
    ZeD = {
        tr = function(k, ...) return WORDS[k] or k end,
        trBare = function(k) return WORDS[k] or k end,
        textCase = function(s) return s end,
        btnCase = function(s) return s end,
        logOnce = function(...) FAULTS[#FAULTS + 1] = table.concat({ ... }, " ") end,
        Safe = { on = function() return P.safe end },
        windowsFor = function(pn) return pn == nil or pn == 0 end,
        Input = { Focus = { reclaimEngineFocus = function() P.reclaims = P.reclaims + 1; setJoypadFocus(0, P.zedFocus) end } },
        Disclose = {
            split = function(list)
                local shown, hidden = {}, {}
                for _, v in ipairs(list) do
                    if v.sensible ~= false then
                        if v.canDo then shown[#shown + 1] = v else hidden[#hidden + 1] = v end
                    end
                end
                return shown, hidden
            end,
        },
    }
    ZeD_WorldWindow = {
        getWindow = function(pn) if (pn or 0) == 0 then return P.win end return nil end,
        isTabShowing = function(tab, pn)
            local w = (pn or 0) == 0 and P.win or nil
            return w ~= nil and w._activeTab == tab and w._drawerMode == "tab" and w._drawerOpen == true
        end,
    }
    -- the game's mechanics window ZeD never shows (the part menu's self)
    ISVehicleMechanics = {}
    function ISVehicleMechanics:doPartContextMenu(part)
        self.context = newMenu()
        self.context:addOption(getText("IGUI_RepairEngine"), nil, function() end, part)
        self.context:addOption(getText("IGUI_TakeEngineParts"), nil, function() end, part)
    end
    P.ui = setmetatable({ playerNum = 0, getAbsoluteX = function() return 0 end, getAbsoluteY = function() return 0 end,
                          getX = function() return 1520 end, getY = function() return 767 end, getWidth = function() return 800 end,
                          setX = function() end },
                        { __index = function(t, k) return ISVehicleMechanics[k] end })
    getPlayerMechanicsUI = function() return P.ui end
    -- the world: the character, a car beside it, the World window on the Vehicle tab
    P.chr = newPlayer()
    P.v = newVehicle(11, 102, 100)
    P.win = newWorldWin(P.chr, opts.wx or 1929, 0, opts.ww or 1617, 735)
    -- the tab, real
    local src = opts.mtSource or readFile(CLIENT .. "ZeD/MechanicsTab.lua")
    local f, err = loadstring(src, "@MechanicsTab.lua")
    check("MechanicsTab.lua compiles", f ~= nil, err)
    local okL, errL = pcall(f)
    check("MechanicsTab.lua loads on the stubs", okL, errL)
    P.MT = ZeD.MechanicsTab
    P.win._mech = { vehicles = { { vehicle = P.v, id = P.v.id } }, idx = 1, zones = {}, byId = {} }
    if not opts.notInspected then P.MT._insp[P.v.id] = { vehicle = P.v } end
    if not opts.noMod then fakeMod() end
    if opts.before then opts.before() end
    if not opts.noSupport then
        local g = {}
        for k in pairs(_G) do g[k] = true end
        P.globalsBefore = g
        local fs, errS = loadfile(CLIENT .. "ZeD/ModSupport/MaskaradsSummerCar.lua")
        check("the support file compiles", fs ~= nil, errS)
        local okS, errS2 = pcall(fs)
        check("the support file loads", okS, errS2)
    end
    P.S = ZeD.ModSupport and ZeD.ModSupport.MaskaradsSummerCar
    return P
end

-- Time: frames of 16 ms; the mod's update every 100 ms (the game's UI update), then the poll (OnTickEvenPaused)
local nextUpdate = 0
local function frames(n, each)
    for _ = 1, n do
        clock = clock + 16
        if clock >= nextUpdate then
            nextUpdate = clock + 100
            local e = P.W and P.W.instances[0]
            if e then
                local ok, err = pcall(e.update, e)
                if not ok then P.updateErr = err end
            end
        end
        if each then each() end
        local ok, err = pcall(fire, Events.OnTickEvenPaused)
        if not ok then P.pollErr = err end
    end
end
local function ms(n, each) frames(math.ceil(n / 16), each) end
local function eng() return P.W and P.W.instances[0] end
local function anchor() return P.S.standIn(0) end
local function noted(place) return P.S.noted[place] == true end
local function printed(pat)
    for _, l in ipairs(PRINTS) do if l:find(pat, 1, true) then return true end end
    return false
end
local function setOpen(win) win._activeTab, win._drawerMode, win._drawerOpen = "vehicle", "tab", true end

-- ===========================================================================
section("VIS: when the anchor counts as shown")
setup()
local S = P.S
check("the support file is up", S ~= nil and type(S.look) == "function")
local v1 = S.shown(0)
check("VIS: the Vehicle tab on an inspected car: shown", v1 == P.v)
local cases = {
    { "closed",            function() P.savedWin = P.win; P.win = nil end, function() P.win = P.savedWin end, true },
    { "another tab",       function() P.win._activeTab = "loot" end, function() setOpen(P.win) end, false },
    { "drawer folded",     function() P.win._drawerOpen = false; P.win._drawerMode = nil end, function() setOpen(P.win) end, false },
    { "rolled to its bar", function() P.win.windowShaded = true end, function() P.win.windowShaded = false end, false },
    { "not inspected",     function() P.MT._insp[P.v.id] = nil end, function() P.MT._insp[P.v.id] = { vehicle = P.v } end, true },
    { "dead",              function() P.chr.dead = true end, function() P.chr.dead = false end, true },
    { "safe mode",         function() P.safe = true end, function() P.safe = false end, true },
    { "car gone",          function() P.v.gone = true end, function() P.v.gone = false end, true },
}
for _, c in ipairs(cases) do
    c[2]()
    local v, _, _, gone, hv = S.look(0)
    check("VIS: " .. c[1] .. ": not shown", v == nil)
    check("VIS: " .. c[1] .. ": " .. (c[4] and "gone" or "hidden for now"), gone == c[4], tostring(gone))
    if not c[4] then check("VIS: " .. c[1] .. ": the car it will show again", hv == P.v) end
    c[3]()
end
local _, _, _, g1 = S.look(1)
check("VIS: player 1 (split screen): gone", S.look(1) == nil and g1 == true)
P.win._drawerObject = { card = true }
check("VIS: a card over the tab: still shown", S.shown(0) == P.v)
P.win._drawerObject = nil
P.win._rolled, P.win._rollW = true, 300
check("VIS: the inventory side rolled: still shown", S.shown(0) == P.v)
local fx, _, fw = S.footprint(P.win)
check("VIS: the rod counted in the footprint", fx == 1629 and fw == 1917, fx .. "," .. fw)
P.win._rolled, P.win._rollW = false, 0
check("VIS: the anchor's rect is the footprint", anchor():getX() == 1929 and anchor():getY() == 0 and anchor():getWidth() == 1617 and anchor():getHeight() == 735)

-- ===========================================================================
section("AUTO: the mod's auto-open, against the anchor")
setup()
frames(1)
check("AUTO: not in the first frame (the window must stand still 150 ms)", eng() == nil)
ms(200)
check("AUTO: opens once still", eng() ~= nil)
check("AUTO: anchored to the stand-in", eng() and eng().mechanicsUI == anchor())
check("AUTO: for the car the tab shows", eng() and eng().vehicle == P.v)
check("AUTO: opened as an auto-open (no pad grab)", eng() and eng().autoOpen == true)
ms(5000)
check("AUTO: still open 5 s later (the reported bug)", eng() ~= nil and not eng().closed)
check("AUTO: opened once", P.opens == 1, P.opens)
-- moving
setup()
ms(1000, function() P.win.x = P.win.x - 1 end)
check("AUTO: not while the World window moves", eng() == nil)
ms(300)
check("AUTO: once it stops", eng() ~= nil)
setup()
ms(500, function() P.win._drawerEffW = P.win._drawerEffW + 5 end)
check("AUTO: not while the drawer slides", eng() == nil)
-- paused, seated, debug
setup(); P.speed = 0; ms(500)
check("AUTO: not paused", eng() == nil)
P.speed = 1; ms(300)
check("AUTO: after the pause", eng() ~= nil)
setup(); P.chr.veh = P.v; ms(500)
check("AUTO: not seated", eng() == nil)
P.debug = true; ms(300)
check("AUTO: seated in debug: yes", eng() ~= nil)
-- another car
setup(); ms(300)
local first = eng()
local v2 = newVehicle(12, 98, 100)
P.MT._insp[v2.id] = { vehicle = v2 }
P.win._mech.vehicles = { { vehicle = v2, id = v2.id } }
frames(1)
check("AUTO: another car closes the old window in the same frame", first.closed and first.closedAsUser == false)
ms(300)
check("AUTO: and opens one for the new car", eng() ~= nil and eng().vehicle == v2)

-- ===========================================================================
section("DISMISS: the player's close lasts as beside the game's window")
local function dismissed() ms(300); local e = eng(); e:close(); ms(500); return eng() == nil end
local hides = {
    { "a fold",          function() P.win._drawerOpen = false; P.win._drawerMode = nil end, function() setOpen(P.win) end },
    { "a roll",          function() P.win.windowShaded = true end, function() P.win.windowShaded = false end },
    { "another tab",     function() P.win._activeTab = "loot" end, function() setOpen(P.win) end },
    { "a card",          function() P.win._drawerObject = {} end, function() P.win._drawerObject = nil end },
}
for _, h in ipairs(hides) do
    setup()
    check("DISMISS: the title-bar X closes it and it stays shut", dismissed())
    check("DISMISS: the close is the player's", anchor().msc_userDismissed == true)
    h[2](); ms(3000); h[3](); ms(2000)
    check("DISMISS: still shut after " .. h[1], eng() == nil, tostring(eng()))
end
local resets = {
    { "the World window closed and opened", function() P.savedWin = P.win; P.win = nil; ms(200); P.win = P.savedWin end },
    { "another car and back", function()
        local v3 = newVehicle(13, 99, 100); P.MT._insp[v3.id] = { vehicle = v3 }; v3.access.can = false
        P.win._mech.vehicles = { { vehicle = v3, id = 13 } }; ms(300)
        P.win._mech.vehicles = { { vehicle = P.v, id = P.v.id } } end },
    { "the inspection over and again", function() P.MT._insp[P.v.id] = nil; ms(300); P.MT._insp[P.v.id] = { vehicle = P.v } end },
    { "access lost and back, on another tab", function()
        P.win._activeTab = "loot"; ms(200); P.v.access.can = false; ms(200); P.v.access.can = true; ms(200); setOpen(P.win) end },
    { "death", function() fire(Events.OnPlayerDeath, P.chr) end },
}
for _, r in ipairs(resets) do
    setup()
    dismissed()
    r[2]()
    ms(500)
    check("DISMISS: opens again after " .. r[1], eng() ~= nil and eng().vehicle == P.v)
end
setup(); ms(300)
P.win._drawerOpen = false; P.win._drawerMode = nil; frames(1)
check("DISMISS: a fold's own close is not the player's", eng() == nil and anchor().msc_userDismissed == false)
setOpen(P.win); ms(400)
check("DISMISS: and the window comes back with the tab", eng() ~= nil)

-- ===========================================================================
section("EDGE: nothing opens that the mod's next update would close")
setup()
P.chr.x = P.v.x - 6.5   -- past six tiles, the tab not yet refreshed (the inspection still on)
ms(1500)
check("EDGE: past six tiles: no window", eng() == nil and P.opens == 0)
check("EDGE: and openFromMechanics never asked", (P.calls or 0) == 0, P.calls)
setup(); ms(300)
local opened = P.opens
ms(1000, function() P.chr.x = P.chr.x - 0.1 end)   -- walking off
check("EDGE: walking past six tiles: closed by the mod, never reopened", eng() == nil and P.opens == opened, P.opens)
setup(); P.v.onSquare = false; ms(800)
check("EDGE: the car off its square: no window", eng() == nil and (P.calls or 0) == 0)
setup(); P.v.access.reason = "assemblyUnavailable"; ms(800)
check("EDGE: no assembly (access true, a reason): no per-frame calls", (P.calls or 0) == 0, P.calls)
setup(); P.chr.x = P.v.x - 6.5
P.MT._test.runVerb(P.MT.getState(P.win), "mscInspect", P.v.parts.Engine, P.chr)
check("EDGE: the footer verb past six tiles opens nothing", eng() == nil and (P.calls or 0) == 0)

-- ===========================================================================
section("PLACE")
setup(); ms(300)
check("PLACE: 4K default: left of the World window, the mod's gap and width", eng().x == 1419 and eng().w == 500 and eng().y == 10,
    eng().x .. "," .. eng().y .. " " .. eng().w)
check("PLACE: ZeD's window not moved", P.win.x == 1929)
setup({ wx = 100 }); ms(300)
check("PLACE: room on the right: the mod's own place", eng().x == 1727, eng().x)
setup({ sw = 1920, sh = 1080, wx = 498, ww = 924 }); ms(300)
check("PLACE: 1080 tile band: ZeD's window stays", P.win.x == 498)
check("PLACE: 1080 tile band: the larger side, within the mod's widths", eng().x == 1432 and eng().w == 478, eng().x .. " " .. eng().w)
setup({ sw = 1280, sh = 800, wx = 320, ww = 640 }); ms(300)
check("PLACE: 1280, no side holds 420: 420 wide at x 10", eng().x == 10 and eng().w == 420, eng().x .. " " .. eng().w)
check("PLACE: 1280: clear of the drawer (384 into the window)", eng().x + eng().w <= 320 + 384)
setup()
P.win._rolled, P.win._rollW = true, 200
ms(300)
check("PLACE: the rod counted", eng().x == 1219, eng().x)
-- the band, swept
local bad = 0
for _, cfg in ipairs({ { 1920, 1080, 924 }, { 1280, 800, 640 }, { 1280, 720, 640 }, { 3840, 2160, 1617 } }) do
    for x = 0, cfg[1] - cfg[3], 10 do
        setup({ sw = cfg[1], sh = cfg[2], wx = x, ww = cfg[3] })
        ms(250)
        local e = eng()
        local ok = e ~= nil and P.win.x == x and e.x >= 0 and e.x + e.w <= cfg[1] and e.w >= 420 and e.w <= 500
        local over = e and e.x < x + cfg[3] and e.x + e.w > x
        if over and not (e.x == 10 and e.w == 420 and e.x + e.w <= x + 384) then ok = false end
        if not ok then bad = bad + 1; if bad < 4 then out("   sweep miss " .. cfg[1] .. " x=" .. x .. (e and (" eng " .. e.x .. "+" .. e.w) or " none")) end end
    end
end
check("PLACE: the sweep at 1080, 1280 x 800, 1280 x 720 and 4K: on screen, ZeD's window still, never over the tab", bad == 0, bad)
-- the World window grows into it
setup(); ms(300)
check("PLACE: before the growth", eng().x == 1419)
P.win.x, P.win.w = 1700, 1846
ms(300)
check("PLACE: the World window grew left into it: placed again, clear", eng().x + eng().w <= 1700 - 10 and eng().x == 1190, eng().x)
eng():setX(800)                 -- the player drags it
P.win.x, P.win.w = 600, 2946
ms(300)
check("PLACE: a window the player dragged stays where they put it", eng().x == 800)

-- ===========================================================================
section("CLOSE: with the tab, in the same frame")
local shapes = {
    { "the drawer folded", function() P.win._drawerOpen = false end },
    { "rolled to its bar", function() P.win.windowShaded = true end },
    { "another tab", function() P.win._activeTab = "loot" end },
    { "the World window closed", function() P.win = nil end },
    { "the inspection over", function() P.MT._insp[P.v.id] = nil end },
}
for _, sh in ipairs(shapes) do
    setup(); ms(300)
    local e = eng()
    nextUpdate = clock + 1000      -- (the mod's own update not due: the poll alone)
    sh[2](); frames(1)
    check("CLOSE: " .. sh[1] .. ": closed in the same frame", e.closed == true and eng() == nil)
    check("CLOSE: " .. sh[1] .. ": as a close(false)", e.closedAsUser == false)
end
setup(); ms(300)
local e0 = eng()
fire(Events.OnPlayerDeath, P.chr)
check("CLOSE: death closes it at once", e0.closed and eng() == nil)
setup(); P.chr.veh = P.v; P.W.openFromEcu(P.chr, P.v); local ecu = eng()
P.win._activeTab = "loot"; ms(500)
check("CLOSE: the ECU window left alone", eng() == ecu and not ecu.closed)

-- ===========================================================================
section("HOLD: the roll-up held while the pointer is on the engine window")
setup(); ms(300)
P.win._outSince = nil
P.mouseX, P.mouseY = eng().x + 5, eng().y + 5
local okH = pcall(frames, 1)
check("HOLD: from nil, no error", okH and P.pollErr == nil, P.pollErr)
check("HOLD: the pointer on it: held ahead", P.win._outSince ~= nil and P.win._outSince >= clock + 400)
P.win._outSince = clock + 5000
frames(1)
check("HOLD: a longer hold is never shortened", P.win._outSince == clock - 16 + 5000)
P.mouseX, P.mouseY = 10, 10
P.win._outSince = nil
frames(3)
check("HOLD: the pointer elsewhere: untouched", P.win._outSince == nil)
P.ctx.visible = true
frames(1)
check("HOLD: a context menu up: held", P.win._outSince ~= nil and P.win._outSince > clock)
P.ctx.visible = false

-- ===========================================================================
section("MENU: the mod's Inspect option in ZeD's part menu")
local function rightClickEngine()
    local s = P.win._mech
    s.lastRows = { { x = 0, y = 0, w = 100, h = 20, clip = { x = 0, y = 0, w = 100, h = 20 }, part = "Engine" } }
    P.MT.onRightClick(P.win, 5, 5)
    local ctx = P.ui.context
    local insp, names = nil, {}
    for _, o in ipairs(ctx and ctx.options or {}) do
        names[#names + 1] = o.name
        if o.name == WORDS.UI_MSC_InspectEngineComponents then insp = o end
    end
    return insp, table.concat(names, ", ")
end
setup()
local insp, names = rightClickEngine()
check("MENU: the menu holds Inspect engine components and the lift option", insp ~= nil and names:find("Remove engine at lift", 1, true) ~= nil, names)
check("MENU: no Repair engine / Take engine parts", not names:find("Repair Engine", 1, true) and not names:find("Take Engine Parts", 1, true), names)
check("MENU: Inspect points at the anchor", insp and insp.param2 == anchor())
check("MENU: with no pad grab", insp and insp.param3 == true)
check("MENU: its part and target kept", insp and insp.param1 == P.v.parts.Engine and insp.target == P.chr)
check("MENU: the lift option untouched", P.liftOpt.param1 == P.v and P.liftOpt.param2 == "remove")
insp.onSelect(insp.target, insp.param1, insp.param2, insp.param3)
frames(1)
check("MENU: picking it opens the engine window, anchored", eng() ~= nil and eng().mechanicsUI == anchor())
ms(5000)
check("MENU: and it stays", eng() ~= nil)
setup(); P.menuOther = true
insp = rightClickEngine()
check("MENU: an option that no longer calls openFromMechanics is left as it is", insp and insp.param2 == P.ui)
check("MENU: with one line", noted("menu"))
setup()
P.MT._test.partContextMenu(P.v.parts.EngineDoor, P.chr)
check("MENU: another part's menu untouched", P.ui.context and #P.ui.context.options == 2)

-- ===========================================================================
section("VERBS: the Engine's footer")
local function vlist(part) return table.concat(P.MT._test.verbsFor(part or P.v.parts.Engine, P.chr), ",") end
setup()
check("VERBS: the Engine: Inspect engine components only", vlist() == "mscInspect", vlist())
check("VERBS: another part: as built", vlist(P.v.parts.EngineDoor) == "", vlist(P.v.parts.EngineDoor))
local s = P.MT.getState(P.win)
local n = P.MT._test.needsFor(s, P.v.parts.Engine, "mscInspect", P.chr, P.v)
check("VERBS: accessible: can be done", n.ok == true)
local cm = P.MT._test.cardModel(s, P.v.parts.Engine, P.chr, P.v)
check("VERBS: the card: the mod's words on the verb", cm.shown[1] and cm.shown[1].label == "Inspect engine components", cm.shown[1] and cm.shown[1].label)
check("VERBS: the card: it is the primary verb", cm.primary == "mscInspect", cm.primary)
check("VERBS: the card: the mod's help line", cm.shown[1] and cm.shown[1].help == WORDS.UI_MSC_InspectEngineComponentsTooltip)
P.v.access.reason = "hoodClosed"; s.needsCache = nil
check("VERBS: the hood closed: still there", vlist() == "mscInspect")
n = P.MT._test.needsFor(s, P.v.parts.Engine, "mscInspect", P.chr, P.v)
check("VERBS: the hood closed: not now, the mod's sentence as the line", n.ok == false and n.line == WORDS.UI_MSC_HoodMustBeOpen)
check("VERBS: the hood closed: the row reads Hood | Closed", n.rows[1].label == "Hood" and n.rows[1].value == WORDS.UI_ZeD_Veh_StClosed)
s.needsCache = nil
cm = P.MT._test.cardModel(s, P.v.parts.Engine, P.chr, P.v)
check("VERBS: the folded row says how many, not a With line", cm.hidden[1] and cm.hidden[1].needs == "")
check("VERBS: the NEEDS line is the mod's", cm.hidden[1] and cm.hidden[1].needsLine == WORDS.UI_MSC_HoodMustBeOpen)
P.v.access.reason = "assemblyUnavailable"
check("VERBS: no assembly: the verb is gone", vlist() == "", vlist())
P.v.access.reason = nil; P.chr.veh = P.v
check("VERBS: seated, not an admin: gone", vlist() == "", vlist())
P.chr.veh = nil
P.MT._test.runVerb(s, "mscInspect", P.v.parts.Engine, P.chr)
frames(1)
check("VERBS: the verb opens the engine window beside", eng() ~= nil and eng().mechanicsUI == anchor() and eng().x == 1419)
setup({ before = function() ISVehicleMechanics.MSC_originalDoPartContextMenu = nil end })
check("VERBS: without the mod's menu wrap the footer stays as built", vlist() == "repairEngine,takeParts", vlist())

-- ===========================================================================
section("PAD")
setup()
local PADLIST = { "toString", "isVisible", "getIsVisible", "getJoypadNavigateStartDelay", "onGainJoypadFocus",
    "onLoseJoypadFocus", "onJoypadDown", "onJoypadButtonReleased", "onJoypadDirUp", "onJoypadDirDown", "onJoypadDirLeft",
    "onJoypadDirRight", "onJoypadBeforeDeactivate", "onJoypadBeforeReactivate", "onJoypadReactivate",
    "onJoypadNavigateStart", "onJoypadNavigateEnd", "onJoypadNavigateUp", "onJoypadNavigateDown",
    "onJoypadNavigateLeft", "onJoypadNavigateRight", "onJoypadNavigateParent" }
local PZ = os.getenv("ZEDSIM_PZ_LUA")
local jps = PZ and readFile(PZ .. "/client/ISUI/Gamepad/JoyPadSetup.lua")
if jps then
    for m in jps:gmatch(":(onJoypad%w+)%(") do PADLIST[#PADLIST + 1] = m end
    out("   (pad methods also read from the game's JoyPadSetup.lua)")
end
local a = anchor()
local missingPad = {}
for _, m in ipairs(PADLIST) do
    local okM = type(a[m]) == "function" and pcall(a[m], a, nil, nil)
    if not okM then missingPad[#missingPad + 1] = m end
end
check("PAD: the anchor answers every method the game's pad code calls on a focus", #missingPad == 0, table.concat(missingPad, ","))
check("PAD: a field that is not a pad method reads nil", a.somethingElse == nil and a.vehicle ~= false)
P.zedFocus = { toString = function() return "ZeD World window" end }
local older = { toString = function() return "older" end }
JoypadState.players[1] = { focus = P.zedFocus, prevfocus = older, prevprevfocus = nil }
ms(300)
check("PAD: the auto-open never takes the pad", getJoypadFocus(0) == P.zedFocus)
eng():close()                     -- the player's close, a pad attached: the mod hands the pad to the anchor
check("PAD: (the mod handed the pad to the anchor)", getJoypadFocus(0) == a)
frames(1)
check("PAD: back on ZeD's window in the next poll", getJoypadFocus(0) == P.zedFocus)
check("PAD: the game's focus stack as it was", JoypadState.players[1].prevfocus == older, tostring(JoypadState.players[1].prevfocus and JoypadState.players[1].prevfocus:toString()))
check("PAD: no reclaim needed", P.reclaims == 0)
setup()
P.zedFocus = { toString = function() return "ZeD World window" end }
JoypadState.players[1] = { focus = nil }
ms(300)
setJoypadFocus(0, nil)
local e1 = eng()
JoypadState.players[1].prevfocus = nil
e1:close()
frames(1)
check("PAD: with nothing before it, ZeD reclaims the pad", P.reclaims == 1 and getJoypadFocus(0) == P.zedFocus)
-- the pad check runs after the poll's own close in the same frame
setup()
P.zedFocus = { toString = function() return "ZeD" end }
JoypadState.players[1] = { focus = P.zedFocus }
ms(300)
nextUpdate = clock + 1000
P.win._drawerOpen = false
frames(1)
check("PAD: a hide's close: the pad never left with the anchor", getJoypadFocus(0) ~= a)
setup()
JoypadState.players[1] = { focus = P.zedFocus }
P.MT._test.runVerb(P.MT.getState(P.win), "mscInspect", P.v.parts.Engine, P.chr)
check("PAD: the footer verb by pad: the engine window does not take the pad", eng() ~= nil and getJoypadFocus(0) ~= eng())

-- ===========================================================================
section("LIFT: the mod's own windows are left alone by the auto-open")
setup()
P.W.openFromEngine(P.chr, { gone = false })
local lift = eng()
ms(800)
check("LIFT: the lift window stays with an inspected car in the tab", eng() == lift and not lift.closed)
P.MT._test.runVerb(P.MT.getState(P.win), "mscInspect", P.v.parts.Engine, P.chr)
check("LIFT: the footer verb may replace it", eng() ~= lift and eng().mechanicsUI == anchor())
setup(); P.chr.veh = P.v
P.W.openFromEcu(P.chr, P.v); local ecu2 = eng()
P.debug = true; ms(800)
check("LIFT: the ECU window stays (seated, debug)", eng() == ecu2)

-- ===========================================================================
section("FAIL: a mod update that breaks the contract")
setup({ noMod = true })
ms(500)
check("FAIL: no MSC: nothing acts, no error", P.pollErr == nil and #Events.OnTickEvenPaused.list == 1)
check("FAIL: no MSC: the startup line names it", P.S.check() == false and printed("not found (another version of the mod?)"))
check("FAIL: no MSC: the footer as built", vlist() == "repairEngine,takeParts", vlist())
setup()
P.openThrows = true
ms(800)
check("FAIL: openFromMechanics throws: one line", noted("openFromMechanics"))
check("FAIL: and the auto-open is off for the session", P.S.autoOff == true and P.calls == 1, P.calls)
setup(); ms(300)
local e2 = eng()
P.S.look = function() error("look broke") end
ms(400)
check("FAIL: S.shown throws: no error escapes the poll", P.pollErr == nil, P.pollErr)
check("FAIL: no error escapes the mod's update", P.updateErr == nil, P.updateErr)
check("FAIL: the mod's own update closes the window", e2.closed == true and eng() == nil)
check("FAIL: with one line each", noted("poll") and noted("anchor"))
check("FAIL: the poll is off", #Events.OnTickEvenPaused.list == 0)
check("FAIL: ZeD.logOnce never called", #FAULTS == 0, table.concat(FAULTS, " | "))
setup()
P.S.check()
check("FAIL: the startup line when the contract holds", printed("[ZeD] Summer Car: on (the mod's 0.0.1"))

-- ===========================================================================
section("OFF: the mod off")
setup({ modOff = true })
check("OFF: the file returns first", ZeD.ModSupport == nil)
check("OFF: no extra registered", #P.MT.extras == 0)
check("OFF: no Events added", Events.OnTickEvenPaused.adds == 0 and Events.OnPlayerDeath.adds == 0 and Events.OnGameStart.adds == 0
    and Events.OnTick.adds == 0)
local newG = {}
for k in pairs(_G) do if not P.globalsBefore[k] then newG[#newG + 1] = k end end
check("OFF: no new globals", #newG == 0, table.concat(newG, ","))
check("OFF: the Engine's verbs as built", vlist() == "repairEngine,takeParts", vlist())
P.MT._test.partContextMenu(P.v.parts.Engine, P.chr)
local opt
for _, o in ipairs(P.ui.context.options) do if o.name == WORDS.UI_MSC_InspectEngineComponents then opt = o end end
check("OFF: the part menu is the game's (and the mod's) alone", opt and opt.param2 == P.ui)

-- ===========================================================================
section("RELOAD")
setup(); ms(300)
local a1, e3 = anchor(), eng()
local fs = loadfile(CLIENT .. "ZeD/ModSupport/MaskaradsSummerCar.lua")
fs()
P.S = ZeD.ModSupport.MaskaradsSummerCar
check("RELOAD: the anchor kept", P.S.standIn(0) == a1)
check("RELOAD: one poll handler", #Events.OnTickEvenPaused.list == 1)
check("RELOAD: one death and one start handler", #Events.OnPlayerDeath.list == 1 and #Events.OnGameStart.list == 1)
check("RELOAD: one extra", #P.MT.extras == 1)
ms(500)
check("RELOAD: the open window kept, still anchored", eng() == e3 and not e3.closed)
local fm = loadstring(readFile(CLIENT .. "ZeD/MechanicsTab.lua"), "@MechanicsTab.lua")
fm()
P.MT = ZeD.MechanicsTab
local s2 = P.MT.getState(P.win)
s2.needsCache = nil
local cm2 = P.MT._test.cardModel(s2, P.v.parts.Engine, P.chr, P.v)
check("RELOAD: MechanicsTab reloaded after: the verb keeps its words", cm2.shown[1] and cm2.shown[1].label == "Inspect engine components", cm2.shown[1] and cm2.shown[1].label)
check("RELOAD: and its help", cm2.shown[1] and cm2.shown[1].help == WORDS.UI_MSC_InspectEngineComponentsTooltip)
check("RELOAD: and stays the primary verb", cm2.primary == "mscInspect", cm2.primary)
check("RELOAD: one extra still", #P.MT.extras == 1)

-- ===========================================================================
section("OLD (the base tab without the support file: the bug)")
local pipe = io.popen('git -C "' .. (ROOT ~= "" and ROOT or ".") .. '" show ' .. BASE .. ':42/media/lua/client/ZeD/MechanicsTab.lua 2>NUL')
local oldSrc = pipe and pipe:read("*a") or ""
if pipe then pipe:close() end
if oldSrc == "" then
    out("   (OLD skipped: git show " .. BASE .. " gave nothing)")
else
    setup({ mtSource = oldSrc, noSupport = true })
    check("OLD: the base tab has no extras hook", P.MT.addExtras == nil)
    local oi = rightClickEngine()
    check("OLD: (the mod's option is there, pointed at the hidden game window)", oi and oi.param2 == P.ui)
    P.ui.isReallyVisible = function() return false end
    oi.onSelect(oi.target, oi.param1, oi.param2, oi.param3)
    local oe = eng()
    ms(200)
    check("OLD: the engine window closes at once: this sim tells the two apart", oe ~= nil and oe.closed == true and eng() == nil)
    setup({ mtSource = oldSrc })
    oi = rightClickEngine()
    check("OLD: with the support file but the base tab, the option is not rebound (the hook is needed)", oi and oi.param2 == P.ui)
end

print = out
out(string.format("summercar_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
