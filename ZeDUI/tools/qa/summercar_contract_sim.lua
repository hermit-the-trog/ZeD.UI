-- ZeDUI/tools/qa/summercar_contract_sim.lua  (Nov 12 2026, Build): the contract between ModSupport/MaskaradsSummerCar.lua
-- and Maskarad's Summer Car's own code (its window file MSC_EngineComponentsWindow.lua and its lift menu
-- MSC_EngineLiftMenu.lua), read from the mod's copy on disk and run on Lua 5.1 stubs of the game. A Summer Car update
-- that changes what ZeD leans on fails here before release.
--   STATIC   the mod's version; its four text keys; the functions ZeD calls; every member the window reads of its
--            "mechanics window" is one the anchor answers; isAutoOpen only gates the pad grab; the menu option's shape;
--            the mod's numbers ZeD repeats; fingerprints of its auto-open (prerender wrap) and its placement
--   OPEN     openFromMechanics against a recording anchor: one window, anchored; the anchor asked only what it answers
--   TILE     neither side free: the mod asks to slide the anchor (recorded, nothing moves); ZeD places the window
--   UPDATE   the mod's own update keeps it while the tab shows the car, closes it (not as the player's) when hidden or
--            for another car
--   CLOSE    the player's close writes the dismissal on the anchor
--   PAD      the mod hands the pad to the anchor; the anchor answers every method the game's pad code calls
--   MENU     the mod's two menu wraps on a stand-in of the game's builder; ZeD's partMenu rebinds only Inspect
-- Where the mod is: the environment variable ZEDSIM_MSC_DIR (its mods/MaskaradsSummerCar folder), else SteamCMD's
-- Workshop download. Not there: SKIP, exit 0. The game's JoyPadSetup.lua is read from ZEDSIM_PZ_LUA (its media/lua).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/summercar_contract_sim.lua
-- It prints FAIL lines and a last line "summercar_contract_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]summercar_contract_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/"
local out = print

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end
local CANDIDATES = { "C:/steamcmd/steamapps/workshop/content/108600/3790160840/mods/MaskaradsSummerCar" }
if os.getenv("ZEDSIM_MSC_DIR") then table.insert(CANDIDATES, 1, os.getenv("ZEDSIM_MSC_DIR")) end   -- (ipairs stops at a nil)
local MOD
for _, c in ipairs(CANDIDATES) do
    if c and readFile(c .. "/42/media/lua/client/MSC_EngineComponentsWindow.lua") then MOD = c; break end
end
if not MOD then
    out("summercar_contract_sim: SKIP: Summer Car's copy is not on disk (set ZEDSIM_MSC_DIR, or SteamCMD: workshop_download_item 108600 3790160840)")
    os.exit(0)
end
local LUA = MOD .. "/42/media/lua/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        out("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) out("-- " .. s) end

-- comments out (a "--" not inside a string is rare enough in this code to cut at)
local function stripComments(s)
    s = s:gsub("%-%-%[%[.-%]%]", "")
    s = s:gsub("%-%-[^\n]*", "")
    return s
end
local function norm(s) return (s:gsub("%s+", " ")) end
local function fingerprint(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return string.format("%08x", h)
end
-- the body of a top-level function, from its header line to the next "end" at column 0
local function body(src, header)
    local a = src:find(header, 1, true)
    if not a then return nil end
    local b = src:find("\nend\n", a, true)
    return b and src:sub(a, b + 4) or nil
end

-- What this file was read against (0.0.1): the mod's auto-open and its placement, normalized
local FP_PRERENDER = "d0dadbaa"
local FP_PLACEMENT = "c1c56577"

-- ===========================================================================
section("STATIC")
local W_SRC = stripComments((readFile(LUA .. "client/MSC_EngineComponentsWindow.lua"):gsub("\r\n", "\n")))
local C_SRC = stripComments(readFile(LUA .. "shared/MSC_EngineComponents.lua") or "")
local info = readFile(MOD .. "/42/mod.info") or readFile(MOD .. "/mod.info") or ""
local ver = info:match("modversion=([%w%.%-]+)")
out("   the mod's version: " .. tostring(ver))
check("STATIC: the mod is the version this support was read against (0.0.1)", ver == "0.0.1", ver)
local en = readFile(LUA .. "shared/Translate/EN/UI.json") or ""
for _, k in ipairs({ "UI_MSC_InspectEngineComponents", "UI_MSC_InspectEngineComponentsTooltip", "UI_MSC_HoodMustBeOpen",
                     "UI_MSC_EngineAssemblyUnavailable" }) do
    check("STATIC: the mod's key " .. k, en:find('"' .. k .. '"', 1, true) ~= nil)
end
check("STATIC: MSC.EngineComponents.canAccessEngine", C_SRC:find("function Components.canAccessEngine(vehicle)", 1, true) ~= nil)
check("STATIC: MSC.EngineComponents.getEngineAccessReason", C_SRC:find("function Components.getEngineAccessReason(vehicle)", 1, true) ~= nil)
check("STATIC: MSC.EngineComponentsWindow = Window", W_SRC:find("MSC.EngineComponentsWindow = Window", 1, true) ~= nil)
check("STATIC: Window.openFromMechanics(playerObj, part, mechanicsUI, isAutoOpen)",
    W_SRC:find("function Window.openFromMechanics(playerObj, part, mechanicsUI, isAutoOpen)", 1, true) ~= nil)
check("STATIC: Window.instances", W_SRC:find("Window.instances = Window.instances or {}", 1, true) ~= nil)
local nAuto = 0
for _ in W_SRC:gmatch("isAutoOpen") do nAuto = nAuto + 1 end
check("STATIC: isAutoOpen only gates the pad grab", nAuto == 2 and W_SRC:find("if not isAutoOpen then", 1, true) ~= nil, nAuto)
for k, val in pairs({ WINDOW_GAP = "10", CONTENT_PADDING = "10", MINIMUM_WIDTH = "420", DEFAULT_WIDTH = "500" }) do
    check("STATIC: the mod's " .. k .. " is " .. val, W_SRC:match("local " .. k .. " = (%d+)") == val, W_SRC:match("local " .. k .. " = (%d+)"))
end

-- the support file's contract (loaded with the mod "on")
local function loadSupport()
    MODS_ON = true
    getActivatedMods = function() return { size = function() return 1 end, get = function() return "MaskaradsSummerCar" end } end
    local f, err = loadfile(CLIENT .. "ZeD/ModSupport/MaskaradsSummerCar.lua")
    check("the support file compiles", f ~= nil, err)
    local ok, e2 = pcall(f)
    check("the support file loads", ok, e2)
    return ZeD.ModSupport.MaskaradsSummerCar
end

local ANCHOR_OK = {}
-- (filled once the support file is loaded below)
local members = {}
for m in W_SRC:gmatch("mechanicsUI[%.:]([%w_]+)") do members[m] = true end

local pre = body(W_SRC, "function ISVehicleMechanics:prerender()")
local fpPre = pre and fingerprint(norm(pre)) or "none"
check("STATIC: the mod's auto-open unchanged since 0.0.1 (compare W ISVehicleMechanics:prerender with S.autoOpen)",
    fpPre == FP_PRERENDER, fpPre)
local plc = body(W_SRC, "local function calculatePlacement(mechanicsUI)")
local fpPlc = plc and fingerprint(norm(plc)) or "none"
check("STATIC: the mod's placement unchanged since 0.0.1 (compare calculatePlacement with S.place)", fpPlc == FP_PLACEMENT, fpPlc)
local menuNorm = norm(W_SRC)
check("STATIC: the menu adds Inspect with (openFromMechanics, part, self)",
    menuNorm:find('getText("UI_MSC_InspectEngineComponents"), playerObj, Window.openFromMechanics, part, self )', 1, true) ~= nil)
check("STATIC: the menu removes Take engine parts", W_SRC:find('removeOptionByName(getText("IGUI_TakeEngineParts"))', 1, true) ~= nil)
check("STATIC: the menu removes Repair engine", W_SRC:find('removeOptionByName(getText("IGUI_RepairEngine"))', 1, true) ~= nil)

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the mod's window and lift menu ask at load and in these steps
-- ---------------------------------------------------------------------------
local clock = 5000000
local function anyEvent() return { Add = function() end, Remove = function() end } end
Events = setmetatable({}, { __index = function(t, k) local e = anyEvent(); rawset(t, k, e); return e end })
require = function() end
getTimestampMs = function() return clock end
local SW, SH = 1920, 1080
getCore = function()
    return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end,
             isKey = function() return false end, getKey = function() return 0 end }
end
getTextManager = function() return { getFontHeight = function() return 16 end, MeasureStringX = function() return 50 end } end
UIFont = setmetatable({}, { __index = function(_, k) return k end })
getText = function(k) return k end
getTextOrNull = function(k) return k end
UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return 1 end } end }
isDebugEnabled = function() return false end
isClient = function() return false end
isAdmin = function() return false end
getAccessLevel = function() return "" end
getTexture = function() return {} end
Keyboard = { KEY_ESCAPE = 1 }
JoypadState = { players = {} }
local FOCUS = {}
getJoypadFocus = function(pn) local j = JoypadState.players[pn + 1]; return j and j.focus end
setJoypadFocus = function(pn, c)
    local j = JoypadState.players[pn + 1]
    if not j then return end
    if c and c.toString then c:toString() end
    FOCUS[#FOCUS + 1] = c
    j.focus = c
end
local BaseUI = {}
BaseUI.__index = BaseUI
function BaseUI:derive(name) local o = {}; setmetatable(o, self); self.__index = self; o.Type = name; return o end
function BaseUI.new(cls, x, y, w, h) local o = { x = x, y = y, w = w, h = h }; setmetatable(o, cls); cls.__index = cls; return o end
function BaseUI:initialise() end
function BaseUI:addToUIManager() self.onUI = true end
function BaseUI:removeFromUIManager() self.onUI = false end
function BaseUI:setVisible(b) self.visible = b end
function BaseUI:bringToTop() self.tops = (self.tops or 0) + 1 end
function BaseUI:setResizable() end
function BaseUI:setWantKeyEvents() end
function BaseUI:getX() return self.x end
function BaseUI:getY() return self.y end
function BaseUI:getWidth() return self.w end
function BaseUI:getHeight() return self.h end
function BaseUI:setX(x) self.x = x end
function BaseUI:setY(y) self.y = y end
function BaseUI:setWidth(w) self.w = w end
function BaseUI:update() end
function BaseUI.TitleBarHeight() return 16 end
ISCollapsableWindow = setmetatable({}, BaseUI)
ISCollapsableWindow.__index = ISCollapsableWindow
ISCollapsableWindow.TitleBarHeight = BaseUI.TitleBarHeight
ISCollapsableWindow.update = BaseUI.update
ISToolTip = { new = function() return { initialise = function() end, setVisible = function() end } end }
ISVehicleMenu = { showRadialMenu = function() end, showRadialMenuOutside = function() end }

local function newMenu()
    local m = { options = {} }
    function m:addOption(name, target, onSelect, p1, p2, p3)
        local o = { name = name, target = target, onSelect = onSelect, param1 = p1, param2 = p2, param3 = p3 }
        self.options[#self.options + 1] = o
        return o
    end
    function m:removeOptionByName(n) for i, o in ipairs(self.options) do if o.name == n then table.remove(self.options, i); return end end end
    function m:setVisible() end
    return m
end
-- the game's part menu builder, as far as the Engine goes
ISVehicleMechanics = {}
function ISVehicleMechanics:doPartContextMenu(part)
    self.context = newMenu()
    self.context:addOption(getText("IGUI_RepairEngine"), nil, function() end, part)
    self.context:addOption(getText("IGUI_TakeEngineParts"), nil, function() end, part)
end
function ISVehicleMechanics:prerender() end
function ISVehicleMechanics:close() end

-- the world: a player, a car, the engine
local ACCESS = { reason = nil, can = true }
local V = { x = 102, y = 100, onSquare = true }
V.sq = { getMovingObjects = function() return { indexOf = function(_, o) return (o == V and V.onSquare) and 0 or -1 end } end }
function V:getX() return self.x end
function V:getY() return self.y end
function V:getSquare() return self.sq end
function V:getId() return 11 end
local ENGINE = { getId = function() return "Engine" end, getVehicle = function() return V end }
function V:getPartById(id) if id == "Engine" then return ENGINE end end
local PLAYER = { x = 100, y = 100, veh = nil }
function PLAYER:getPlayerNum() return 0 end
function PLAYER:getVehicle() return self.veh end
function PLAYER:DistTo(x, y) return math.sqrt((x - self.x) ^ 2 + (y - self.y) ^ 2) end
function PLAYER:isDead() return false end
getSpecificPlayer = function(pn) if pn == 0 then return PLAYER end end
getPlayer = function() return nil end

MSC = {
    VERSION = "0.0.1",
    EngineComponents = setmetatable({
        DEFINITIONS = {},
        canAccessEngine = function() return ACCESS.can end,
        getEngineAccessReason = function(v) if v == nil then return "vehicleUnavailable" end return ACCESS.reason end,
    }, { __index = function() return function() return nil end end }),
    VehicleDiagnosticsAccess = { isEcuInstalled = function() return false end },
    Sandbox = setmetatable({}, { __index = function() return function() return nil end end }),
    EngineLift = { isEngineRemoved = function() return false end, findWrench = function() return nil end,
                   validateOperation = function() return false, "liftMissing" end, isAssemblyOnLift = function() return false end },
}

section("LOAD: the mod's own window file and lift menu")
local function loadMod(rel)
    local f, err = loadfile(LUA .. rel)
    check("loads: " .. rel .. " compiles", f ~= nil, err)
    if not f then return false end
    local ok, e2 = pcall(f)
    check("loads: " .. rel .. " runs on the stubs", ok, e2)
    return ok
end
local okW = loadMod("client/MSC_EngineComponentsWindow.lua")
local okL = loadMod("client/MSC_EngineLiftMenu.lua")
local W = MSC.EngineComponentsWindow
check("LOAD: the signals are set", type(ISVehicleMechanics.MSC_originalDoPartContextMenu) == "function"
    and type(ISVehicleMechanics.MSC_originalPrerender) == "function")
if not (okW and okL and type(W) == "table") then
    out(string.format("summercar_contract_sim: %d checks, %d failed", checks, failed))
    os.exit(1)
end

-- ZeD's side: the support file, with a World window
ZeD = { windowsFor = function(pn) return pn == nil or pn == 0 end, tr = function(k) return k end,
        Safe = { on = function() return false end }, Input = { Focus = {} } }
local WIN = { x = 498, y = 0, w = 924, h = 735, _activeTab = "vehicle", _drawerMode = "tab", _drawerOpen = true, _drawerEffW = 500 }
WIN._playerObj = PLAYER
function WIN:getX() return self.x end
function WIN:getY() return self.y end
function WIN:getWidth() return self.w end
function WIN:getHeight() return self.h end
function WIN:isReallyVisible() return true end
local SHOWN = true
ZeD_WorldWindow = {
    getWindow = function(pn) if (pn or 0) == 0 then return WIN end end,
    isTabShowing = function() return SHOWN end,
}
ZeD.MechanicsTab = { getState = function() return { vehicles = { { vehicle = V } }, idx = 1 } end,
                     isInspected = function() return true end }
local printed = print
print = function() end
local S = loadSupport()
print = printed
for _, m in ipairs(S.CONTRACT.anchor) do ANCHOR_OK[m] = true end
for m in pairs(members) do
    check("STATIC: the mod reads mechanicsUI." .. m .. ": the anchor answers it", ANCHOR_OK[m] == true,
        "the mod now reads mechanicsUI." .. m .. ": the anchor needs it")
end
for _, k in ipairs(S.CONTRACT.window) do check("CONTRACT: window." .. k, W[k] ~= nil) end
for _, k in ipairs(S.CONTRACT.signals) do check("CONTRACT: signal " .. k, type(ISVehicleMechanics[k]) == "function") end

-- a recorder around the anchor: every read and write logged, then passed on
local REC = {}
local real = S.standIn(0)
local rec = setmetatable({}, {
    __index = function(_, k)
        REC[#REC + 1] = "get " .. tostring(k)
        local val = real[k]
        if type(val) == "function" then return function(_, ...) return val(real, ...) end end
        return val
    end,
    __newindex = function(_, k, val) REC[#REC + 1] = "set " .. tostring(k); real[k] = val end,
})
local function recSeen()
    local seen = {}
    for _, r in ipairs(REC) do seen[r] = true end
    local t = {}
    for r in pairs(seen) do t[#t + 1] = r end
    table.sort(t)
    return table.concat(t, ", ")
end

-- ===========================================================================
section("OPEN")
SW, SH = 3840, 2160
WIN.x, WIN.w = 1929, 1617
REC = {}
W.openFromMechanics(PLAYER, ENGINE, rec, true)
local e = W.instances[0]
check("OPEN: one window, anchored to what it was given", e ~= nil and e.mechanicsUI == rec)
check("OPEN: the anchor was asked only getX, getY, getWidth and the dismissal written",
    recSeen() == "get getWidth, get getX, get getY, set msc_userDismissed", recSeen())
check("OPEN: placed left of the World window at 4K, 500 wide, gap 10", e and e.x == 1419 and e.w == 500 and e.y == 10,
    e and (e.x .. "," .. e.y .. " " .. e.w))
check("OPEN: no pad grab (isAutoOpen)", #FOCUS == 0)

section("UPDATE")
REC = {}
e:update()
check("UPDATE: shown, same car, access: stays", W.instances[0] == e)
check("UPDATE: it asks isReallyVisible and the vehicle", recSeen():find("get isReallyVisible", 1, true) ~= nil
    and recSeen():find("get vehicle", 1, true) ~= nil, recSeen())
SHOWN = false
e:update()
check("UPDATE: hidden: closed", W.instances[0] == nil)
check("UPDATE: hidden: not as the player's", real.msc_userDismissed == false)
SHOWN = true
W.openFromMechanics(PLAYER, ENGINE, rec, true)
e = W.instances[0]
real.vehicle = { other = true }
local oldRV = rec.isReallyVisible
rawset(rec, "isReallyVisible", function() return true end)   -- (the anchor refreshes .vehicle; held here to test the mod's own test)
e:update()
check("UPDATE: another car: closed", W.instances[0] == nil)
rawset(rec, "isReallyVisible", nil)
real.vehicle = nil

section("CLOSE")
W.openFromMechanics(PLAYER, ENGINE, rec, true)
e = W.instances[0]
e:close()
check("CLOSE: the player's close writes the dismissal on the anchor", real.msc_userDismissed == true)

section("TILE")
SW, SH = 1920, 1080
WIN.x, WIN.w = 498, 924
REC = {}
real._askedX = nil
W.openFromMechanics(PLAYER, ENGINE, rec, true)
e = W.instances[0]
check("TILE: the mod asked to slide the anchor (recorded)", real._askedX ~= nil and recSeen():find("get setX", 1, true) ~= nil, recSeen())
check("TILE: ZeD's window did not move", WIN.x == 498)
S.place(e, 0)
check("TILE: the engine window on a free side, clear of ZeD's window",
    e.x + e.w <= WIN.x - 10 or e.x >= WIN.x + WIN.w + 10, e.x .. "+" .. e.w)
check("TILE: on screen, within the mod's widths", e.x >= 10 and e.x + e.w <= SW - 10 and e.w >= 420 and e.w <= 500)
e:close(false)
check("TILE: the mod's put-back moves nothing either", WIN.x == 498)

section("PAD")
JoypadState.players[1] = { focus = nil }
FOCUS = {}
W.openFromMechanics(PLAYER, ENGINE, rec, true)
e = W.instances[0]
e:close()
check("PAD: the mod hands the pad to the anchor on close", FOCUS[1] == rec)
JoypadState.players[1] = nil
local padNames = { "toString", "isVisible", "getIsVisible", "getJoypadNavigateStartDelay", "onGainJoypadFocus", "onLoseJoypadFocus" }
local PZ = os.getenv("ZEDSIM_PZ_LUA")
local jps = PZ and readFile(PZ .. "/client/ISUI/Gamepad/JoyPadSetup.lua")
if jps then
    for m in jps:gmatch(":(onJoypad%w+)%(") do padNames[#padNames + 1] = m end
else
    out("   (ZEDSIM_PZ_LUA not set: the fixed list of the game's pad methods)")
    for _, m in ipairs({ "onJoypadDown", "onJoypadButtonReleased", "onJoypadDirUp", "onJoypadDirDown", "onJoypadDirLeft",
        "onJoypadDirRight", "onJoypadBeforeDeactivate", "onJoypadBeforeReactivate", "onJoypadReactivate",
        "onJoypadNavigateStart", "onJoypadNavigateEnd", "onJoypadNavigateUp", "onJoypadNavigateDown",
        "onJoypadNavigateLeft", "onJoypadNavigateRight", "onJoypadNavigateParent" }) do padNames[#padNames + 1] = m end
end
local miss = {}
for _, m in ipairs(padNames) do
    if type(real[m]) ~= "function" or not pcall(real[m], real) then miss[#miss + 1] = m end
end
check("PAD: the anchor answers every pad method", #miss == 0, table.concat(miss, ","))

section("MENU")
local ui = setmetatable({ playerNum = 0 }, { __index = ISVehicleMechanics })
ui:doPartContextMenu(ENGINE, 0, 0)
local insp, lift, names = nil, nil, {}
for _, o in ipairs(ui.context.options) do
    names[#names + 1] = o.name
    if o.name == "UI_MSC_InspectEngineComponents" then insp = o end
    if o.name == "UI_MSC_RemoveEngineAtLift" then lift = o end
end
check("MENU: Inspect engine components is the mod's openFromMechanics on (part, the window)",
    insp and insp.onSelect == W.openFromMechanics and insp.param1 == ENGINE and insp.param2 == ui and insp.param3 == nil)
check("MENU: the lift option is there (the lift menu loaded after the window file)", lift ~= nil, table.concat(names, ", "))
check("MENU: the game's two engine options are gone", not table.concat(names, ","):find("IGUI_RepairEngine", 1, true)
    and not table.concat(names, ","):find("IGUI_TakeEngineParts", 1, true), table.concat(names, ", "))
local liftBefore = lift and (tostring(lift.param1) .. tostring(lift.param2) .. tostring(lift.onSelect))
S.partMenu(ENGINE, PLAYER, ui)
check("MENU: ZeD points Inspect at the anchor, no pad grab", insp.param2 == real and insp.param3 == true)
check("MENU: nothing else changed", lift and (tostring(lift.param1) .. tostring(lift.param2) .. tostring(lift.onSelect)) == liftBefore)
JoypadState.players[1] = { focus = nil }
FOCUS = {}
insp.onSelect(insp.target, insp.param1, insp.param2, insp.param3)
check("MENU: picking it opens the engine window anchored to the tab", W.instances[0] and W.instances[0].mechanicsUI == real)
check("MENU: and the pad is not grabbed", #FOCUS == 0)
JoypadState.players[1] = nil

out(string.format("summercar_contract_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
