-- ZeDUI/tools/qa/pad_audit_228_sim.lua  (Nov 14 2026, punch list 228, QA's controller pattern audit): who holds the
-- pad, with no game running. The real FocusManager.lua, ZeD_ContextList.lua and the keyboard's show / hide (cut from
-- ZeD_Keyboard.lua) run on Lua 5.1 stubs; the engine's joypad focus is a table the stubs' setJoypadFocus writes.
--   HELD     (228a) Focus.held(pn) is true while something that is not a ZeD window holds the pad (the keyboard, a
--            menu, the oven's pop-out), false for a ZeD window, a part of one, or a holder that is no longer up; Y
--            opens nothing over it; a window a menu option opens still takes the pad (claimFocus reads modalUp)
--   ESCAPE   (228b) the right stick's aim escape leaves a pad held by something else alone; releaseFocus never
--            clears a holder that is not a ZeD window; the game-cursor roll-up always runs (QA's regression: Place item
--            from a menu kept the pad on the Character window), the keyboard keeping its pad
--   TVLIST   (QA's regression on 228c) a radio face's list hands the pad back to the window the face is in, even
--            with a prompt left up from before holding the pad's focus; the window can take the pad again after
--   KEYS     (228b) the keyboard shown again over a field while up, then put away: the character may move again
--   ORIGIN   (228c) a ZeD menu closing hands the pad to its origin (the belt) when that is up, else the focused
--            window; an option that gave the pad to something new keeps it there; the origin is used once
--   WALK     (228d) the list-style menu closes once the player walks more than 2 tiles off or changes floor, and a pad
--            player's list left with no pad focus takes it back
-- Run from the repo root: lua51 ZeDUI/tools/qa/pad_audit_228_sim.lua
-- It prints FAIL lines and a last line "pad_audit_228_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_audit_228_sim%.lua$", "")
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
local function slurp(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
-- the text from `head` to the end of the first "\nend\n" after it
local function cut(src, head)
    local a = src and src:find(head, 1, true)
    if not a then return nil end
    local _, b = src:find("\nend\n", a, true)
    return b and src:sub(a, b) or nil
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
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
isDebugEnabled = function() return false end
getText = function(k) return k end
getMaxActivePlayers = function() return 4 end
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD." then return end realPrint(s) end

-- the pad: player 1's slot has a pad (id 0); the engine's focus is jd.focus
local JD = { id = 0, player = 0, focus = nil }
JoypadState = { players = { JD }, joypads = {}, controllers = {} }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
JoypadButton = setmetatable({}, { __index = function() return { isDown = function() return false end } end })
getJoypadData = function(pn) return pn == 0 and JD or nil end
getJoypadFocus = function(pn) local jd = JoypadState.players[pn + 1]; return jd and jd.focus or nil end
setJoypadFocus = function(pn, f) local jd = JoypadState.players[pn + 1]; if jd then jd.focus = f end end
updateJoypadFocus = noop
setJoypadIgnoreAimUntilCentered = noop
isControllerConnected = function() return true end
getControllerCount = function() return 1 end
local STICK = 0
getControllerAxisValue = function(c, axis) return (axis == 2) and STICK or 0 end
local DRAG = nil
getCell = function() return { getDrag = function() return DRAG end } end

local POS = { x = 100, y = 100, z = 0 }
local BLOCKED = false
local PLAYER = { getPlayerNum = function() return 0 end, isAsleep = function() return false end, isDead = function() return false end,
                 getX = function() return POS.x end, getY = function() return POS.y end, getZ = function() return POS.z end, getVehicle = function() return POS.veh end,
                 isBlockMovement = function() return BLOCKED end, setBlockMovement = function(_, v) BLOCKED = v end }
getSpecificPlayer = function(pn) return (pn or 0) == 0 and PLAYER or nil end

ZeD = { Input = {} }
ZeD.tr = function(k) return k end
ZeD.uiSound = noop
ZeD.Input.Detector = { getMode = function() return "gamepad" end }
ZeD.Input.Action = { fromGamepadButton = function() return nil end }

-- a UI thing: shown or not, with a parent
local function ui(label, parent)
    local o = { _zedLabel = label, parent = parent, shown = true, playerNum = 0, windowShaded = false }
    function o:isReallyVisible() return self.shown end
    function o:isVisible() return self.shown end
    function o:setWindowShaded(v) self.windowShaded = v end
    o._focusRing = { { zone = "z", focusable = true, elements = { { id = "e1", x = 0, y = 0, w = 10, h = 10 } }, focusedElementIdx = 1 } }
    o._focusIdx = 1
    return o
end

-- ---------------------------------------------------------------------------
-- THE REAL FOCUS MANAGER
-- ---------------------------------------------------------------------------
local okF, errF = pcall(dofile, Z .. "Input/FocusManager.lua")
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus
local S0 = Focus._st[0]
local function tick(ms) now = now + (ms or 16); Focus.tick() end

-- HELD (228a)
local win = ui("Character")
Focus.registerWindow(win)
JD.focus = nil
check("HELD: nothing holds the pad: not held", Focus.held(0) == false)
local kb = ui("Keyboard")
JD.focus = kb
check("HELD: the keyboard holds the pad: held", Focus.held(0) == true)
check("HELD: ... and it is the foreign holder", Focus.foreignHolder(0) == kb)
check("HELD: held() with no player reads every player's pad", Focus.held() == true)
check("HELD: ... the keyboard is no prompt or join screen (modalUp)", Focus.modalUp() == false)
kb.shown = false
check("HELD: a holder no longer up does not hold", Focus.held(0) == false)
kb.shown = true
JD.focus = win
check("HELD: a ZeD window holding the pad is not held", Focus.held(0) == false)
local box = ui("text box", ui("drawer", win))
JD.focus = box
check("HELD: a part of a ZeD window holding it is not held", Focus.held(0) == false)

-- Y over the keyboard: no hold starts, nothing opens
JD.focus = kb
Focus.qaButton("Y", true); tick(); tick(500)
check("HELD: Y over the keyboard starts no Y hold", S0.yHeld == false, S0.yHeld)
Focus.qaButton("Y", false); tick(); Focus.qaButton("Y", nil); tick()
check("HELD: ... and the keyboard keeps the pad", JD.focus == kb)
check("HELD: ... and no window took it", Focus.getFocusedWindow(0) == nil)
-- with nothing up, Y does start its hold (the pair's opener)
JD.focus = nil
Focus.qaButton("Y", true); tick()
check("HELD: with nothing over the game, Y starts its hold", S0.yHeld == true)
S0.yUsed = true   -- (no tap: the pair's opener needs the real windows)
Focus.qaButton("Y", false); tick(); Focus.qaButton("Y", nil); tick()

-- a window a menu option opens still takes the pad (claimFocus reads modalUp, not held)
local menu = ui("menu")
JD.focus = menu
Focus.claimFocus(win)
check("HELD: a window opened from a menu option still takes the pad", Focus.getFocusedWindow(0) == win and JD.focus == win)

-- ESCAPE (228b)
JD.focus = kb
S0.wsGrace = 0
STICK = 1
tick(); tick()
check("ESCAPE: the aim escape leaves the keyboard's pad alone", Focus.getFocusedWindow(0) == win and JD.focus == kb)
check("ESCAPE: ... and rolls nothing up", win.windowShaded == false)
STICK = 0
tick()
DRAG = { Type = "ISPlaceItemCursor" }
tick(); tick()
check("ESCAPE: a game cursor up rolls the windows up, under the keyboard too", win.windowShaded == true and Focus.getFocusedWindow(0) == nil)
check("ESCAPE: ... and the keyboard keeps its pad", JD.focus == kb)
DRAG = nil
tick()
win.windowShaded = false
-- (184) Place item from a menu: the menu that started the cursor is still the pad's holder on the next tick
JD.focus = nil
Focus.claimFocus(win)
local closing = ui("ZeD_ContextMenu")
closing.Type = "ZeD_ContextMenu"
JD.focus = closing
DRAG = { Type = "ISPlace3DItemCursor" }
tick(); tick()
check("ESCAPE: Place item from a menu: the cursor's roll-up lets the window go (184)", win.windowShaded == true and Focus.getFocusedWindow(0) == nil)
DRAG = nil
tick()
win.windowShaded = false
JD.focus = nil
Focus.claimFocus(win)
JD.focus = kb
Focus.releaseFocus(0)
check("ESCAPE: releaseFocus never clears a holder that is not a ZeD window", JD.focus == kb)
check("ESCAPE: ... while the window is let go", Focus.getFocusedWindow(0) == nil)
-- with the window holding it, the escape still works
JD.focus = nil
Focus.claimFocus(win)
S0.wsGrace = 0
STICK = 1
tick(); tick()
check("ESCAPE: with the window holding the pad the aim escape rolls it up", win.windowShaded == true and Focus.getFocusedWindow(0) == nil)
STICK = 0
tick()
win.windowShaded = false
-- (228o) another player's furniture cursor is the game's
DRAG = { Type = "ISMoveableCursor" }
check("ESCAPE: player 1's furniture cursor is the Furniture tab's", Focus.gameCursor(0) == nil)
check("ESCAPE: another player's furniture cursor is the game's (228o)", Focus.gameCursor(1) == DRAG)
DRAG = nil

-- ORIGIN (228c)
Focus.claimFocus(win)
local belt = ui("belt")
local vm = { origin = belt }
local m1 = ui("menu strip")
m1.vanillaMenu = vm
JD.focus = m1
Focus.menuClosed(m1, 0)
check("ORIGIN: the menu's origin (the belt) gets the pad back", JD.focus == belt)
check("ORIGIN: ... used once", vm.origin == nil)
JD.focus = m1
Focus.menuClosed(m1, 0)
check("ORIGIN: with no origin the focused window gets it", JD.focus == win)
vm.origin = belt
local prompt = ui("prompt")
JD.focus = prompt
Focus.menuClosed(m1, 0)
check("ORIGIN: an option that gave the pad to a prompt keeps it there", JD.focus == prompt)
vm.origin = belt
belt.shown = false
JD.focus = m1
Focus.menuClosed(m1, 0)
check("ORIGIN: an origin no longer up: the focused window", JD.focus == win)
belt.shown = true

-- TVLIST (QA's regression on 228c): a radio face's list (RtvFace.lua's listMenu, cut) over a stale prompt
do
    local src = (function()
        local f = io.open(Z .. "RtvFace.lua", "rb")
        if not f then return "" end
        local t = f:read("*a"); f:close(); return (t:gsub("\r\n", "\n"))
    end)()
    local a = src:find("local function listMenu(chr, at, items, emptyKey, onPick, target)", 1, true)
    local b = nil
    if a then local _; _, b = src:find("\nend\n", a, true) end
    check("TVLIST: the face's list is found", a ~= nil and b ~= nil)
    if a and b then
        local CTX = { addOption = function() return {} end }
        ISContextMenu = { get = function() return CTX end }
        getMouseX, getMouseY = function() return 0 end, function() return 0 end
        local fn, e = loadstring(src:sub(a, b) .. "\nreturn listMenu\n", "listMenu")
        check("TVLIST: the face's list compiles", fn ~= nil, e)
        if fn then
            local listMenu = fn()
            JD.focus = nil
            Focus.claimFocus(win)
            local stale = ui("prompt left up")
            stale.Type = "ZeD_Prompt"
            JD.focus = stale
            local chr = { getPlayerNum = function() return 0 end }
            listMenu(chr, { x = 0, y = 0 }, {}, "UI_ZeD_Radio_NoTapes", noop, nil)
            check("TVLIST: the list takes the pad", JD.focus == CTX)
            check("TVLIST: its origin is the window the face is in, not the prompt", CTX.origin == win)
            local zm = ui("ZeD_ContextMenu")
            zm.vanillaMenu = CTX
            JD.focus = zm
            Focus.menuClosed(zm, 0)
            check("TVLIST: the list closed, the pad is back on the window (on the face's key)", JD.focus == win)
            check("TVLIST: ... and nothing modal holds it: the window can take the pad again", Focus.modalUp() == false)
            -- a prop holding the pad itself (the car radio) stays the origin
            local car = ui("car radio")
            car.Type = "ZeD_CarRadio"
            JD.focus = car
            listMenu(chr, { x = 0, y = 0 }, {}, "UI_ZeD_Radio_NoTapes", noop, nil)
            check("TVLIST: from the car radio the origin is the car radio", CTX.origin == car)
            JD.focus = win
        end
    end
end

-- KEYS (228b): the keyboard's show / hide, cut from ZeD_Keyboard.lua
do
    local src = slurp(Z .. "ZeD_Keyboard.lua") or ""
    local parts = {
        cut(src, "local function chars(lo, up)"), cut(src, "local function fn(id, label, glyph, opts)"),
        cut(src, "local function append(row, ...)"), cut(src, "local function appendAll(row, list)"),
        cut(src, "local function buildRows(multi, masked)"),
        cut(src, "function ZeD_Keyboard:show(playerNum, textEntryBox, joypadData)"),
        cut(src, "function ZeD_Keyboard:hide()"),
    }
    local body = ""
    for i = 1, #parts do
        check("KEYS: the keyboard's piece " .. i .. " is found", parts[i] ~= nil)
        body = body .. (parts[i] or "")
    end
    ZeD_Keyboard = {}
    MainScreen = { instance = { inGame = true } }
    local fn, e = loadstring(body, "keyboard")
    check("KEYS: the keyboard's show / hide compile", fn ~= nil, e)
    if fn then
        fn()
        local k = setmetatable({}, { __index = ZeD_Keyboard })
        for _, n in ipairs({ "setVisible", "addToUIManager", "setAlwaysOnTop", "layout", "removeFromUIManager" }) do k[n] = noop end
        local function field()
            return { getInternalText = function() return "" end, focus = noop, javaObject = false }
        end
        BLOCKED = false
        k:show(0, field(), JD)
        check("KEYS: shown in game, the character stands still", BLOCKED == true)
        k:show(0, field(), JD)
        check("KEYS: shown again over another field: still still", BLOCKED == true)
        k:hide()
        check("KEYS: put away: the character may move again", BLOCKED == false)
        BLOCKED = true   -- (something else stopped the character: not the keyboard's to undo)
        k:show(0, field(), JD)
        k:hide()
        check("KEYS: a stand-still the keyboard did not set stays", BLOCKED == true)
        BLOCKED = false
    end
end

-- WALK (228d): the real ZeD_ContextList on panel stubs
do
    local SW, SH = 1920, 1080
    getMouseX = function() return 5 end
    getMouseY = function() return 5 end
    getCore = function() return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end } end
    Keyboard = { KEY_UP = 200, KEY_DOWN = 208, KEY_LEFT = 203, KEY_RIGHT = 205, KEY_RETURN = 28, KEY_ESCAPE = 1 }
    ZeD_Panel = {}
    local P = ZeD_Panel
    function P:derive(name) local c = setmetatable({}, { __index = self }); c.Type = name; return c end
    function P:new(x, y, w, h) return { x = x, y = y, w = w, h = h, _hitZones = {} } end
    for _, n in ipairs({ "drawRect", "drawText", "drawTextureScaledAspect", "setWantKeyEvents", "addToUIManager",
                         "removeFromUIManager", "bringToTop", "update", "drawRectBorder", "initialise" }) do P[n] = noop end
    function P:getMouseX() return 5 end
    function P:getMouseY() return 5 end
    function P:isReallyVisible() return self._ctx and self._ctx.open == true end
    function P:hitTest() return false end
    local COLOR = { r = 1, g = 1, b = 1, a = 1 }
    ZeD.T = setmetatable({ px = function(v) return v end, fontF1 = 1, fontF2 = 2 }, { __index = function() return COLOR end })
    ZeD.TM = { MeasureStringX = function(_, _, s) return #tostring(s) * 6 end, getFontHeight = function() return 10 end }
    ZeD.ContextMenu = { Registry = { highlight = noop } }
    local okL, errL = pcall(dofile, Z .. "ZeD_ContextList.lua")
    check("WALK: ZeD_ContextList.lua loads", okL, errL)
    if okL then
        local function open()
            POS.x, POS.y, POS.z = 100, 100, 0
            local m = ZeD_ContextList:new(0, "cursor", 50, 50, nil, { { name = "Eat", category = "a", onFire = noop } }, nil)
            m:open()
            return m
        end
        local m = open()
        check("WALK: the list takes the pad as it opens", JD.focus == m)
        POS.x = 101.5
        m:update()
        check("WALK: a step and a half away it stays", m._ctx.open == true)
        POS.x, POS.y = 102, 101.5
        m:update()
        check("WALK: past 2 tiles it closes", m._ctx.open == false)
        m = open()
        POS.z = 1
        m:update()
        check("WALK: another floor closes it", m._ctx.open == false)
        -- (beast W12: seated in a car it moves with the player, so distance and floor do not close it; getting out does)
        m = open()
        POS.veh = {}; m._openAt = nil; m._openAt = { x = 100, y = 100, z = 0, veh = POS.veh }
        POS.x, POS.y = 140, 100
        m:update()
        check("WALK: in a car it stays open past 2 tiles", m._ctx.open == true)
        POS.veh = nil
        m:update()
        check("WALK: getting out of the car closes it", m._ctx.open == false)
        POS.veh = nil
        m = open()
        JD.focus = nil
        m:update()
        check("WALK: a pad player's list left with no pad focus takes it back", JD.focus == m)
        m:close()
        check("WALK: closed, the pad goes back to the focused window", JD.focus == Focus.getFocusedWindow(0) and JD.focus == win)
    end
end

print("pad_audit_228_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
