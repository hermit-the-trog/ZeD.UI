-- ZeDUI/tools/qa/bumper_tabs_sim.lua  (Nov 14 2026, punch list 212): LB steps the Character window's tabs and RB the
-- World window's, with no game running. The real FocusManager.lua runs on Lua 5.1 stubs; the bumpers are pressed
-- through Focus.dispatchJoypadDown and held / let go through Focus.qaButton, the tick read through Focus.tick.
--   TAP     a tap steps on release (not on the press), the pad going to that bumper's window; the last tab wraps
--           to the first; only the strip's tabs count (a hidden Radio tab is skipped)
--   HOLD    held past 350 ms: one tab back, then one more every 400 ms; the release adds no forward step
--   BOTH    LB and RB down together: no step
--   GONE    the windows let go of the pad mid-press: no step, and nothing takes the pad back
-- Run from the repo root:  lua51 ZeDUI/tools/qa/bumper_tabs_sim.lua
-- It prints FAIL lines and a last line "bumper_tabs_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]bumper_tabs_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end

-- the engine, as little of it as FocusManager touches here
local now = 100000
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
LuaEventManager = { AddEvent = noop }
triggerEvent = noop
require = noop
getTimestampMs = function() return now end
getSoundManager = function() return { playUISound = noop } end
isDebugEnabled = function() return false end
getSpecificPlayer = function() return nil end
getJoypadData = function() return nil end
getMaxActivePlayers = function() return 4 end
JoypadState = { players = {}, joypads = {}, controllers = {} }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD." then return end realPrint(s) end
ZeD = { Input = {} }
ZeD.Input.Detector = { getMode = function() return "gamepad" end }
ZeD.Input.Action = { fromGamepadButton = function(b)
    if b == Joypad.LBumper then return { "window_prev" } end
    if b == Joypad.RBumper then return { "window_next" } end
    return nil
end }

local okF, errF = pcall(dofile, Z .. "Input/FocusManager.lua")
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus

-- a window with a tab strip: tabs = the strip's stops (only the shown tabs), a list to land on
local function makeWin(name, zone, tabs)
    local w = { _zedLabel = name, playerNum = 0, windowShaded = false, _activeTab = tabs[1], opened = 0 }
    function w:isVisible() return true end
    local els = {}
    for i, id in ipairs(tabs) do
        els[i] = { id = "tab:" .. id, tabId = id, x = 0, y = i * 20, w = 40, h = 20,
                   onActivate = function(win, e) win._activeTab = e.tabId; win.opened = win.opened + 1 end }
    end
    w._focusRing = {
        { zone = zone, focusable = true, elements = els, focusedElementIdx = 1 },
        { zone = name .. "List", focusable = true, elements = { { id = "row1", x = 50, y = 0, w = 100, h = 20 } },
          focusedElementIdx = 1 },
    }
    w._focusIdx = 2
    return w
end
local charWin = makeWin("Character", "charTabBar", { "loot", "health", "skills", "journal" })
-- (the World window's Radio tab is not on the strip: no radio in reach)
local worldWin = makeWin("World", "worldTabBar", { "loot", "craft", "build", "vehicle" })
ZeD_CharacterWindow = { getWindow = function() return charWin end, ensureBothOpenForGamepad = noop }
ZeD_WorldWindow = { getWindow = function() return worldWin end }

local function tick(ms) now = now + (ms or 16); Focus.tick() end
local function press(b) Focus.dispatchJoypadDown(Focus.getFocusedWindow(0) or charWin, b, { player = 0 }) end
local BTN = { [Joypad.LBumper] = "LeftBump", [Joypad.RBumper] = "RightBump" }
local function down(b) Focus.qaButton(BTN[b], true); press(b); tick() end
local function up(b) Focus.qaButton(BTN[b], false); tick(); Focus.qaButton(BTN[b], nil) end
local function tap(b) down(b); up(b) end

-- TAP
Focus.claimFocus(worldWin)
check("TAP: the World window has the pad to start", Focus.getFocusedWindow(0) == worldWin)
down(Joypad.LBumper)
check("TAP: nothing steps on the press", charWin._activeTab == "loot" and charWin.opened == 0, charWin._activeTab)
up(Joypad.LBumper)
check("TAP: LB from the World window takes the pad to the Character window", Focus.getFocusedWindow(0) == charWin)
check("TAP: ... and steps it to its next tab", charWin._activeTab == "health", charWin._activeTab)
tap(Joypad.LBumper); tap(Joypad.LBumper)
check("TAP: two more taps, two more tabs", charWin._activeTab == "journal", charWin._activeTab)
tap(Joypad.LBumper)
check("TAP: the last tab wraps to the first", charWin._activeTab == "loot", charWin._activeTab)
check("TAP: the World window's tab never moved for LB", worldWin._activeTab == "loot" and worldWin.opened == 0)
worldWin._activeTab = "build"
tap(Joypad.RBumper)
check("TAP: RB takes the pad to the World window", Focus.getFocusedWindow(0) == worldWin)
check("TAP: ... on its next tab", worldWin._activeTab == "vehicle", worldWin._activeTab)
tap(Joypad.RBumper)
check("TAP: past the last shown tab (Radio hidden) back to Loot", worldWin._activeTab == "loot", worldWin._activeTab)

-- HOLD
local before = charWin.opened
charWin._activeTab = "skills"
down(Joypad.LBumper)
tick(200)
check("HOLD: under 350 ms, nothing yet", charWin._activeTab == "skills", charWin._activeTab)
tick(200)
check("HOLD: past 350 ms, one tab back", charWin._activeTab == "health", charWin._activeTab)
tick(200)
check("HOLD: 200 ms later, no second step", charWin._activeTab == "health", charWin._activeTab)
tick(250)
check("HOLD: 400 ms on, another step back", charWin._activeTab == "loot", charWin._activeTab)
tick(400)
check("HOLD: back past the first tab wraps to the last", charWin._activeTab == "journal", charWin._activeTab)
up(Joypad.LBumper)
check("HOLD: letting go adds no forward step", charWin._activeTab == "journal" and charWin.opened == before + 3,
    charWin._activeTab .. " " .. tostring(charWin.opened - before))

-- BOTH
before = charWin.opened + worldWin.opened
down(Joypad.LBumper); down(Joypad.RBumper)
Focus.qaButton("LeftBump", false); Focus.qaButton("RightBump", false); tick(); tick()
Focus.qaButton("LeftBump", nil); Focus.qaButton("RightBump", nil)
check("BOTH: LB and RB together step nothing", charWin.opened + worldWin.opened == before)
tap(Joypad.LBumper)
check("BOTH: the next tap steps again", charWin.opened + worldWin.opened == before + 1)

-- GONE
before = charWin.opened + worldWin.opened
Focus.claimFocus(worldWin)
down(Joypad.LBumper)
Focus.releaseFocus(0)
up(Joypad.LBumper)
check("GONE: windows let go of the pad mid-press: no step", charWin.opened + worldWin.opened == before)
check("GONE: ... and nothing took the pad back", Focus.getFocusedWindow(0) == nil)

-- STALE (playtest, Nov 14): the engine's joypad focus left on the Character window while ZeD's is on the World
-- window. Its stubs ask Focus.padTarget: the press goes to the World window and the engine's focus goes back on it.
local engineFocus = "unset"
setJoypadFocus = function(pn, w) engineFocus = w end
Focus.registerWindow(charWin); Focus.registerWindow(worldWin)
Focus.claimFocus(worldWin)
engineFocus = charWin
check("STALE: a press on the Character window is the World window's",
    Focus.padTarget(charWin, { player = 0 }) == worldWin)
check("STALE: ... and the engine's focus is back on the World window", engineFocus == worldWin)
check("STALE: the focused window's own press is its own", Focus.padTarget(worldWin, { player = 0 }) == worldWin)
local stray = makeWin("Stray", "strayBar", { "a" })
check("STALE: a window ZeD never registered gets nothing", Focus.padTarget(stray, { player = 0 }) == nil)

worldWin._activeTab = "craft"
Focus.qaButton("RightBump", true); Focus.dispatchJoypadDown(Focus.padTarget(charWin, { player = 0 }), Joypad.RBumper, { player = 0 }); tick()
Focus.qaButton("RightBump", false); tick(); Focus.qaButton("RightBump", nil)
check("STALE: RB pressed on the stale Character window still steps the World window's tab",
    worldWin._activeTab == "build", worldWin._activeTab)
Focus.releaseFocus(0)
check("STALE: no window holds the pad: a press is nobody's", Focus.padTarget(charWin, { player = 0 }) == nil)

print("bumper_tabs_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
