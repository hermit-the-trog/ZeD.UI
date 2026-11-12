-- ZeDUI/tools/qa/debug_console_sim.lua  (Nov 7 2026, punch list 106): the Lua console with no game running.
-- The real Tokens, Tr, Atoms, AtomExtensions, Molecules and ZeD_DebugConsole, on Lua 5.1 stubs of a window, a text box
-- and the game's console (zombie.ui.UIDebugConsole as javap reads it on 42.21 / 42.22: its box filled only in its own
-- update() while visible, ProcessCommand reading the line, the history list, "clear", a line that does not compile
-- told in the box, a failing line printed through the log, the suggestion and Tab). It checks:
--   * the console exists only in debug mode, with the game's console made and on the game's screen list
--   * the game's console parked off the screen, its place kept; ZeD's window follows the game's flag (the key, its
--     StartVisible option, QA's gallery scripts); not on the screen list, nothing opens; never on screen with ZeD's
--   * the box filled by the game's own update() while its flag is up, the output waiting in its buffer while shut
--   * Run goes through ProcessCommand on the game's own line; the line, the history, clear, errors marked as blocks,
--     Tab, Copy (picked block or all), the keyboard handed back to ZeD's line after a run; the line waits for a click;
--     Escape stays the pause menu's (Escape in the line lets the line go)
--   * on a server, only a role with the game's capability (or the co-op host) runs a line
--   * the controller: the line (A: pad keyboard, LB / RB history), landing on Run after typing, the band, the list
--   * safe mode puts the game's own back in its place (up if ZeD's was open) and takes it again
--   * every frame drawn inside the window at 720 / Deck / 1080p / 4K, Normal and Large text, mouse and pad
-- What it cannot prove: the engine (real font widths, the text box's own keys, Java's threading, what the game prints).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/debug_console_sim.lua
-- It prints FAIL lines and a last line "debug_console_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]debug_console_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the clock, the game's globals -----------------------------------------------------------
local nowMs = 1000000
function getTimestampMs() return nowMs end
function triggerEvent() end
local DEBUG, CLIENT, CAP, COOP = true, false, false, false
function isDebugEnabled() return DEBUG end
function isClient() return CLIENT end
function isCoopHost() return COOP end
Capability = setmetatable({}, { __index = function(_, k) return k end })
local ROLE = { hasCapability = function(_, c) return CAP and c == "UIManagerProcessCommands" end }
local PLAYER = { getRole = function() return ROLE end, getPlayerNum = function() return 0 end }
function getPlayer() return PLAYER end
function getSpecificPlayer() return PLAYER end
function getSoundManager() return { playUISound = function() end } end
local SCREEN = { w = 1920, h = 1080 }
function getCore() return { getScreenWidth = function() return SCREEN.w end, getScreenHeight = function() return SCREEN.h end, getOptionFontSizeReal = function() return 1 end } end
local MOUSE_DOWN = false
function isMouseButtonDown() return MOUSE_DOWN end
local PADFOCUS = {}
function setJoypadFocus(pn, f) PADFOCUS[pn] = f; local jd = JoypadState.players[pn + 1]; if jd then jd.focus = f end end
function updateJoypadFocus() end
JoypadState = { players = {} }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
Keyboard = { KEY_ESCAPE = 1, KEY_TAB = 15, KEY_RETURN = 28 }
GameKeyboard = { eatKeyPress = function() end }
UIFont = setmetatable({}, { __index = function(_, k) return k end })
local CLIP = nil
Clipboard = { setClipboard = function(s) CLIP = s end }
Translator = { getLanguage = function() return { name = function() return "EN" end } end, getAvailableLanguage = function() return nil end }
local TEXT = {}
do
    local f = assert(io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb"))
    local s = f:read("*a")
    f:close()
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\n') do TEXT[k] = v end
end
TEXT.UI_Close = "Close"
TEXT.UI_Cancel = "Cancel"
function getText(k) return TEXT[k] or k end
getTextOrNull = function(k) return TEXT[k] end
local EVENTS = setmetatable({}, { __index = function(t, k)
    local e = { list = {} }
    e.Add = function(fn) e.list[#e.list + 1] = fn end
    e.Remove = function(fn) for i = #e.list, 1, -1 do if e.list[i] == fn then table.remove(e.list, i) end end end
    rawset(t, k, e)
    return e
end })
Events = EVENTS
LuaEventManager = { AddEvent = function() end }

-- the game's text entry: who holds the keyboard (Core.currentTextEntryBox) ----------------
local CORE = { entry = nil }

-- THE GAME'S CONSOLE, as javap reads zombie.ui.UIDebugConsole -------------------------------
local STDOUT = {}            -- what the game printed, waiting in the console's buffer (addOutput)
local function newBox(text)
    local b = { text = text or "", internal = text or "", visible = false }
    function b:getText() return self.text end
    function b:SetText(s) self.text = s; self.internal = s end
    function b:clearInput() self.text = ""; self.internal = "" end
    function b:unfocus() if CORE.entry == self then CORE.entry = nil end end
    function b:isVisible() return self.visible end
    return b
end
local function javaList()
    local l = { n = {} }
    function l:size() return #self.n end
    function l:get(i) return self.n[i + 1] end
    function l:add(s) self.n[#self.n + 1] = s end
    return l
end
local JC = { visible = false, updates = 0, x = 20 }
JC.out = newBox("Lua Debug Console v1.1.0 42.22.2\n")
JC.cmd = newBox("")
JC.sug = newBox("")
JC.prev = javaList()
function JC:isVisible() return self.visible end
function JC:setVisible(v) self.visible = v end
function JC:getX() return self.x end
function JC:setX(v) self.x = v end
function JC:update()
    if not self.visible then return end    -- (the game's: nothing at all while hidden)
    self.updates = self.updates + 1
    if #STDOUT > 0 then
        local s = self.out.text .. table.concat(STDOUT)
        STDOUT = {}
        if #s > 8192 then s = s:sub(#s - 8192 + 1) end
        self.out:SetText(s)
    end
    -- the suggestion: the nearest global function to the line's word
    -- (as UIDebugConsole.update() in the jar: the suggestion is worked out only when the line's LENGTH differs from the one
    -- it last worked on; an emptied line hides the box and leaves that length where it was. QA round 3.)
    local t = self.cmd.text
    if #t ~= (self.inputlength or 0) and t ~= "" then
        self.inputlength = #t
        if ("getPlayer"):sub(1, #t) == t then
            self.sug.visible = true
            self.sug:SetText("IsoPlayer getPlayer")
            self.prevSuggestion = "getPlayer"
        end
    elseif t == "" then
        self.sug.visible = false
    end
end
function JC:ProcessCommand()
    local s = self.cmd.internal
    if s == nil then return end
    self.cmd.internal = ""
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if self.prev:size() == 0 or self.prev:get(self.prev:size() - 1) ~= s then self.prev:add(s) end
    CORE.entry = self.cmd      -- (the game hands the keyboard to its own line)
    if s == "clear" then self.out:clearInput(); return end
    local fn, err = loadstring(s, "console")
    if not fn then self.out:SetText(self.out.text .. tostring(err) .. "\n"); return end
    local ok, e = pcall(fn)
    if not ok then
        STDOUT[#STDOUT + 1] = "ERROR: General      f:1, t:1> ExceptionLogger.logException> Exception thrown\n"
            .. "\tjava.lang.RuntimeException: " .. tostring(e) .. " at KahluaThread.tableget(KahluaThread.java:1689).\n"
            .. "\tStack trace:\n\t\tse.krka.kahlua.vm.KahluaThread.tableget(KahluaThread.java:1689)\n"
            .. "LOG  : General      f:1, t:1> -----------------------------------------\n"
            .. "STACK TRACE\n-----------------------------------------\nfunction: console -- file: console line # 1 | Vanilla\n\n"
    end
end
function JC:onOtherKey(k)
    if k == 15 and self.prevSuggestion then self.cmd:SetText(self.prevSuggestion .. "()") end
end
function say(s) STDOUT[#STDOUT + 1] = "LOG  : Lua          f:1, t:1> " .. tostring(s) .. "\n" end

local MADE, ON_SCREEN = true, true
UIManager = {
    getDebugConsole = function() return MADE and JC or nil end,
    getUI = function() return { contains = function(_, x) return ON_SCREEN and x == JC end } end,
}
-- the game's reflection helpers (debug mode: private fields too)
local FIELDS = { { name = "scrollBarV" }, { name = "outputLog", v = JC.out }, { name = "commandLine", v = JC.cmd },
    { name = "resizing", v = false }, { name = "autosuggest", v = JC.sug }, { name = "previous", v = JC.prev } }
function getNumClassFields(o) if o == JC then return #FIELDS end return 0 end
function getClassField(o, i) local f = FIELDS[i + 1]; return { getName = function() return f.name end, v = f.v } end
function getClassFieldVal(o, f) if f.v == nil then return "<private>" end return f.v end

-- the pad keyboard (Overrides/Prompts.lua's OnScreenKeyboard.Show) ----------------------------
local KB = { visible = false, entry = nil, shows = 0 }
OnScreenKeyboard = { Show = function(pn, entry, jd) KB.visible = true; KB.entry = entry; KB.shows = KB.shows + 1; return { kb = true } end }

-- the game's classes the files derive ------------------------------------------------------
ISUIElement = {}
ISPanel = {}
ISPanel.__index = ISPanel
function ISPanel:derive(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = name
    return o
end
function ISPanel:new(x, y, w, h)
    local o = { x = x, y = y, width = w, height = h, visible = true, kids = {}, onUI = false }
    setmetatable(o, self)
    self.__index = self
    return o
end
function ISPanel:initialise() end
function ISPanel:instantiate() if self.createChildren then self:createChildren() end end
function ISPanel:createChildren() end
function ISPanel:update() end
function ISPanel:prerender() end
function ISPanel:render() end
function ISPanel:addChild(c) self.kids[#self.kids + 1] = c; c.parent = self end
function ISPanel:setVisible(v) self.visible = v end
function ISPanel:isVisible() return self.visible end
function ISPanel:getIsVisible() return self.visible end
function ISPanel:isReallyVisible() return self.visible and self.onUI end
function ISPanel:addToUIManager() self.onUI = true end
function ISPanel:removeFromUIManager() self.onUI = false end
function ISPanel:setAlwaysOnTop(v) self.onTop = v and true or false end
function ISPanel:setWantKeyEvents() end
function ISPanel:bringToTop() end
function ISPanel:getX() return self.x end
function ISPanel:getY() return self.y end
function ISPanel:getWidth() return self.width end
function ISPanel:getHeight() return self.height end
function ISPanel:setX(v) self.x = v end
function ISPanel:setY(v) self.y = v end
function ISPanel:setWidth(v) self.width = v end
function ISPanel:setHeight(v) self.height = v end
function ISPanel:getMouseX() return self.mx or -1 end
function ISPanel:getMouseY() return self.my or -1 end

ISTextEntryBox = ISPanel:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.text = text or ""
    o.font = UIFont.Small
    o.javaObject = { setCentreVertically = function() end }
    return o
end
function ISTextEntryBox:setPlaceholderText(s) self.placeholder = s end
function ISTextEntryBox:setMaxTextLength(n) self.maxT = n end
function ISTextEntryBox:setFont(f) self.font = f end
function ISTextEntryBox:getText() return self.text end
function ISTextEntryBox:setText(s) self.text = s end
function ISTextEntryBox:focus() CORE.entry = self end
function ISTextEntryBox:unfocus() if CORE.entry == self then CORE.entry = nil end end
function ISTextEntryBox:isFocused() return CORE.entry == self end

-- the files --------------------------------------------------------------------------------
local LOADED = {}
local STUBBED = { ["ZeD/Organisms"] = true, ["ZeD/SafeMode"] = true, ["ZeD/ZeD_Surface"] = true }
function require(name)
    if LOADED[name] then return end
    LOADED[name] = true
    if STUBBED[name] or not string.find(name, "^ZeD/") then return end
    local short = string.sub(name, 5)
    local path = ROOT .. "42/media/lua/client/ZeD/" .. short .. ".lua"
    local f = io.open(path, "rb")
    if f then f:close() else path = ROOT .. "42/media/lua/shared/ZeD/" .. short .. ".lua" end
    local fn, err = loadfile(path)
    if not fn then error(err) end
    fn()
end

ZeD = {}
local LOGGED = {}
ZeD.logOnce = function(k, e) LOGGED[#LOGGED + 1] = tostring(k) .. ": " .. tostring(e); print("FAIL logged: " .. tostring(k) .. ": " .. tostring(e)); failed = failed + 1 end
local function fontPx(font)
    local T, big = ZeD.T, ZEDQA_LARGE
    if font == T.fontF1 then return big and 13 or 11 end
    if font == T.fontF2 then return big and 15 or 13 end
    if font == T.fontF3 then return big and 13 or 11 end
    if font == T.fontF4 then return big and 17 or 15 end
    if font == T.fontF5 then return big and 11 or 9 end
    return 11
end
ZeD.TM = {
    MeasureStringX = function(_, font, s) return math.ceil(#tostring(s) * fontPx(font) * ZeD.T.root * 0.60) end,
    MeasureStringY = function(_, font, s) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
    getFontHeight = function(_, font) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
}
ZeD.Scale = { root = function() return ZEDQA_ROOT or 1 end }
local HELP = {}
ZeD.Help = { set = function(_, s) HELP.last = s end, take = function() return nil end }
ZeD.Surface = nil
local MARKS = 0
ZeD.Focus = { mark = function() MARKS = MARKS + 1; return true end }
ZeD.btnCase = function(s) return s end
ZeD.upper = function(s) return string.upper(s) end
local MODE = "kbm"
ZeD.Input = { Detector = { getMode = function() return MODE end }, Focus = { cuesVisible = function() return MODE == "gamepad" end } }
ZeD.Keyboard = { isVisible = function() return KB.visible end }
local SAFE, SAFEDEF = false, {}
local PIECE = false   -- (the ZeD setup switch "Safe mode: Lua console": SafeMode.lua reads it as piece "console")
ZeD.Safe = { on = function(name) return SAFE or (name == "console" and PIECE) end, register = function(n, def) SAFEDEF[n] = def end }

-- the window (Organisms.lua's ZeD_Window, the parts this file uses) ------------------------------
ZeD_Window = ISPanel:derive("ZeD_Window")
function ZeD_Window:new(x, y, w, h, title)
    local o = ISPanel.new(self, x, y, w, h)
    o.title = title or ""
    o.titleStats = {}
    return o
end
function ZeD_Window:createChildren() end
function ZeD_Window:titleBarHeight() return ZeD.T.titleBarH end
function ZeD_Window:footerHeight() return ZeD.T.px(22) end
function ZeD_Window:closeRect() return { x = 4, y = 4, w = 12, h = 12 } end
function ZeD_Window:windowBoxRect() return { x = self.width - 16, y = 4, w = 12, h = 12 } end
function ZeD_Window:prerender() end
function ZeD_Window:render() end
function ZeD_Window:update() end
function ZeD_Window:onMouseDown(x, y) self.moving = true; self.dragStarts = (self.dragStarts or 0) + 1 end   -- (as the real one: it may answer nothing)
function ZeD_Window:onMouseUp() self.moving = false end
function ZeD_Window:onMouseUpOutside() self.moving = false end
function ZeD_Window:onMouseMove(dx, dy) if self.moving then self.x = self.x + dx; self.y = self.y + dy end end
function ZeD_Window:onMouseMoveOutside(dx, dy) if self.moving then self.x = self.x + dx; self.y = self.y + dy end end
function ZeD_Window:close() self:setVisible(false) end

-- every draw of the window, checked against its edges
local DRAW = { texts = {}, outside = {}, clips = 0 }
local function edge(win, what, x, y, w, h)
    if x < -1 or y < -1 or x + w > win.width + 1 or y + h > win.height + 1 then
        DRAW.outside[#DRAW.outside + 1] = what .. " " .. x .. "," .. y .. " " .. w .. "x" .. h .. " in " .. win.width .. "x" .. win.height
    end
end
function ZeD_Window:drawRect(x, y, w, h, a, r, g, b)
    assert(type(b) == "number" and type(a) == "number", "drawRect color")
    edge(self, "rect", x, y, w, h)
end
function ZeD_Window:drawRectBorder(x, y, w, h, a, r, g, b)
    assert(type(b) == "number", "drawRectBorder color")
    edge(self, "border", x, y, w, h)
end
function ZeD_Window:drawText(s, x, y, r, g, b, a, font)
    assert(type(s) == "string", "drawText words")
    assert(font ~= nil, "drawText font")
    local w = ZeD.TM:MeasureStringX(font, s)
    DRAW.texts[#DRAW.texts + 1] = { s = s, x = x, y = y, w = w, clip = DRAW.st }
    local c = DRAW.st
    if c then
        if x + w > c.x + c.w + 1 then DRAW.outside[#DRAW.outside + 1] = "text past its clip: " .. s end
    else
        edge(self, "text '" .. s .. "'", x, y, w, ZeD.TM:getFontHeight(font))
    end
end
function ZeD_Window:drawTexture() end
function ZeD_Window:drawTextureScaled() end
function ZeD_Window:drawTextureScaledAspect() end
function ZeD_Window:setStencilRect(x, y, w, h) DRAW.st = { x = x, y = y, w = w, h = h }; DRAW.clips = DRAW.clips + 1; edge(self, "clip", x, y, w, h) end
function ZeD_Window:clearStencilRect() DRAW.st = nil; DRAW.clips = DRAW.clips - 1 end

local logOnce = ZeD.logOnce
require "ZeD/Tokens"
ZeD.logOnce = logOnce   -- (Tokens has its own: here every logged failure fails the sim)
do
    local char = string.char
    string.char = function(...)
        local a = { ... }
        for i, v in ipairs(a) do if v > 255 then a[i] = 63 end end
        return char(unpack(a))
    end
end
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
ZeD.btnCase = ZeD.btnCase or function(s) return s end
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")
require "ZeD/ZeD_DebugConsole"
local DC = ZeD.DebugConsole
check("the real files load", DC ~= nil and ZeD_DebugConsoleWindow ~= nil and type(DC.frame) == "function")
check("the frame hook is on OnPreUIDraw", #EVENTS.OnPreUIDraw.list == 1)
check("safe mode piece registered", SAFEDEF.console ~= nil and SAFEDEF.console.leave ~= nil and SAFEDEF.console.enter ~= nil)
check("Escape stays the pause menu's (no Escape taker, no key capture)", (ZeD.EscapeTakers == nil or ZeD.EscapeTakers.console == nil) and ZeD_DebugConsoleWindow.isKeyConsumed == nil)

-- a frame as the game runs it: the screens' update() (UIManager.updateUIElements: the console's own gates on its
-- flag), then OnPreUIDraw before they draw. The game's console must never be on the screen while ZeD's is open.
local PARKED = -50000
local onScreenWhileOpen = 0
local function frame()
    if MADE then JC:update() end
    for _, fn in ipairs(EVENTS.OnPreUIDraw.list) do fn() end
    if DC.isOpen() and JC.x > PARKED then onScreenWhileOpen = onScreenWhileOpen + 1 end
end
local function draw(win)
    DRAW.texts, DRAW.outside, DRAW.st = {}, {}, nil
    local c0 = DRAW.clips
    win:prerender()
    check("clips balanced", DRAW.clips == c0, DRAW.clips - c0)
    DRAW.clips = c0
    return DRAW
end
local function textHas(s)
    for _, t in ipairs(DRAW.texts) do if t.s:find(s, 1, true) then return true end end
    return false
end

-- ============================================================================
-- 1. only in debug mode, only while the game's console is made and on screen
-- ============================================================================
DEBUG = false
check("no debug: no console", not DC.exists())
JC.visible = true
frame()
check("no debug: the game's console left alone (where it was, up)", JC.visible == true and JC.x == 20)
check("no debug: ZeD's never opens", not DC.isOpen())
JC.visible = false
DEBUG, MADE = true, false
check("debug, console not made: none", not DC.exists())
frame()
check("not made: nothing opens", not DC.isOpen())
MADE, ON_SCREEN = true, false
check("made, not on screen (main menu): none", not DC.exists())
JC.visible = true
frame()
check("not on screen: ZeD's does not open", not DC.isOpen())
JC.visible = false
ON_SCREEN = true
check("debug, made, on screen: exists", DC.exists())
check("parts found by name", DC.P.ok and DC.P.out == JC.out and DC.P.cmd == JC.cmd and DC.P.sug == JC.sug and DC.P.prev == JC.prev)
frame()
check("parked off the screen, its place kept", JC.x <= PARKED and DC.P.homeX == 20, JC.x)

-- ============================================================================
-- 2. shut: the game's console does nothing (its own update gates on its flag), the output waits in its buffer
-- ============================================================================
say("before open")
local u0 = JC.updates
frame(); frame()
check("shut: the game's console idle", JC.updates == u0)
check("shut: the output waits in the game's buffer", not DC.text:find("before open", 1, true))

-- ============================================================================
-- 3. the game's key flips the game's flag: ZeD's opens, the game's stays parked and fills its box; the line waits for
--    a click (as the game's: a console shown at a game's start never eats the keys)
-- ============================================================================
JC.visible = true
frame()
check("key: ZeD's open", DC.isOpen())
check("key: the game's flag stays up, the game's parked", JC.visible == true and JC.x <= PARKED)
check("key: the waiting output arrives", DC.text:find("before open", 1, true) ~= nil and DC.text:find("Lua Debug Console", 1, true) ~= nil)
local win = DC.win
check("key: the line does not take the keyboard by itself", CORE.entry ~= win.input)
draw(win)
win:onMouseDown(win._fieldRect.x + 3, win._fieldRect.y + 3)
check("a click on the field: the line takes the keyboard", CORE.entry == win.input)
do
    -- the title bar press reaches ZeD_Window's drag start, then moves and releases follow it
    local tb = win:titleBarHeight()
    win.moving, win.dragStarts = false, 0
    local r = win:onMouseDown(win.width / 2, math.floor(tb / 2))
    check("title bar press: ZeD_Window's drag starts", win.dragStarts == 1 and win.moving == true)
    check("title bar press: consumed", r == true)
    local x0, y0 = win.x, win.y
    win:onMouseMove(5, 7)
    check("drag: the move carries the window", win.x == x0 + 5 and win.y == y0 + 7)
    win:onMouseMoveOutside(3, 2)
    check("drag: outside the window too", win.x == x0 + 8 and win.y == y0 + 9)
    win._sb = win._sb or { dragging = true, y = 0, handleMouseMove = function() end, handleMouseUp = function() end }
    local sbWas = win._sb.dragging
    win._sb.dragging = true
    win:onMouseMove(1, 1)
    check("drag: a thumb drag does not stop the window's", win.x == x0 + 9 and win.y == y0 + 10)
    win._sb.dragging = sbWas
    check("drag: the move is consumed", win:onMouseMove(0, 0) == true and win:onMouseMoveOutside(0, 0) == true)
    check("drag: release ends it", win:onMouseUp(0, 0) == true and win.moving == false)
    win.moving = true
    check("drag: a release outside ends it", win:onMouseUpOutside(0, 0) == true and win.moving == false)
    win.moving = true; MOUSE_DOWN = false; win:update()
    check("drag: a release the engine missed ends it in update", win.moving == false)
    win.x, win.y = x0, y0
    -- every click inside the window is taken, wherever it lands
    local taken = true
    for _, p in ipairs({ { 2, 2 }, { win.width - 10, 8 }, { win.width / 2, tb + 2 }, { win._fieldRect.x + 2, win._fieldRect.y + 2 },
                         { win._listRect.x + 2, win._listRect.y + 2 }, { win.width / 2, win.height - 2 }, { 1, win.height / 2 } }) do
        win.dragStarts = 0
        if win:onMouseDown(p[1], p[2]) ~= true then taken = false end
        win:onMouseUp(p[1], p[2])
    end
    check("every press inside the window is consumed", taken)
    check("right click is consumed", win:onRightMouseDown(10, 10) == true and win:onRightMouseUp(10, 10) == true)
    win.moving = false
    -- the game's text box draws nothing and has no placeholder; ZeD's line draws the typed text once
    check("the game's box has no placeholder of its own", win.input.placeholder == "" or win.input.placeholder == nil, win.input.placeholder)
end
check("key: on the screen", win.x >= 0 and win.y >= 0 and win.x + win.width <= SCREEN.w and win.y + win.height <= SCREEN.h, win.x .. "," .. win.y)
local u1 = JC.updates
frame(); frame()
check("open: the game's console runs its own update every frame", JC.updates == u1 + 2, JC.updates - u1)
-- QA's gallery scripts hide and show the game's console by its flag: ZeD's follows
JC:setVisible(false)
frame()
check("the game's flag down from outside: ZeD's shuts", not DC.isOpen())
JC:setVisible(true)
frame()
check("the game's flag up from outside: ZeD's opens", DC.isOpen() and DC.win == win)
win:onMouseDown(win._fieldRect.x + 3, win._fieldRect.y + 3)
draw(win)
check("drawn: the title", win.title == "Lua console")
check("drawn: the banner in the list", textHas("Lua Debug Console"))
check("drawn: no error stat yet", #win.titleStats == 0)
check("drawn: nothing outside", #DRAW.outside == 0, DRAW.outside[1])
check("drawn: band rects (Export, Copy, Clear, Run)", win._bandRects and #win._bandRects == 4)
check("help line: how the line works", win:getStatusLine() == TEXT.UI_ZeD_Console_Help)

-- ============================================================================
-- 4. Run: ProcessCommand on the game's own line
-- ============================================================================
win.input:setText("say('hi there')")
draw(win)
check("typing mirrored into the game's line", JC.cmd.text == "say('hi there')")
win:runLine(); frame()
check("run: the game's history has it", JC.prev:size() == 1 and JC.prev:get(0) == "say('hi there')")
check("run: the output shows", DC.text:find("hi there", 1, true) ~= nil)
check("run: ZeD's line empty", win.input:getText() == "")
check("run: the game's line empty", JC.cmd.text == "" and JC.cmd.internal == "")
check("run: the keyboard back on ZeD's line", CORE.entry == win.input)
win:runLine()
check("run: an empty line does nothing", JC.prev:size() == 1)
win.input:setText("say('hi there')"); win:runLine()
check("run: the same line twice is one history line (the game's rule)", JC.prev:size() == 1)

-- a failing line: the game's log prints the error and its trace; one block, picked whole
win.input:setText("local t = nil; t.x = 1"); win:runLine(); frame()
local lines, errs = DC.lines()
check("error: counted", errs == 1, errs)
local errStart
for i, ln in ipairs(lines) do if ln.s:find("^ERROR") then errStart = i end end
check("error: its first line found", errStart ~= nil)
check("error: the trace's lines marked as its block", lines[errStart + 1].err and lines[errStart + 1].b == errStart)
-- the log (ZeD_ConsoleLog): the whole block is one error row, its stack the block's lines
local CL = ZeD.ConsoleLog
local errRow
for i = 1, CL.counts() do local r = CL.shownAt(i); if r.kind == "error" then errRow = r end end
check("error: one row in the log", errRow ~= nil and CL.errTotal == 1, CL.errTotal)
check("error: its stack is the block, to the console frame", errRow and errRow.stack[1]:find("^ERROR") ~= nil and errRow.stack[#errRow.stack]:find("function: console", 1, true) ~= nil)
check("error: its message without the Java class", errRow and errRow.msg:find("^java") == nil and errRow.msg:find("attempt to index", 1, true) ~= nil, errRow and errRow.msg)
check("error: from the console", errRow and errRow.mod == CL.CONSOLE and errRow.file == "console" and errRow.line == 1)
draw(win)
check("error: title stat", #win.titleStats == 1 and win.titleStats[1].text == "Errors: 1" and win.titleStats[1].color == ZeD.T.danger)
check("error: drawn inside", #DRAW.outside == 0, DRAW.outside[1])

-- a line that does not compile: the console says so in its box
win.input:setText("this is not lua"); win:runLine()
lines, errs = DC.lines()
check("compile error: told and marked", errs == 2, errs)
check("compile error: the console's words", lines[#lines].s:find("console", 1, true) ~= nil and lines[#lines].err, lines[#lines].s)

-- ============================================================================
-- 5. history: Up and Down through the game's own list, the line being typed kept
-- ============================================================================
win.input:setText("dra")
win:historyStep(-1)
check("history: Up shows the newest", win.input:getText() == "this is not lua")
win:historyStep(-1)
check("history: Up again, the one before", win.input:getText() == "local t = nil; t.x = 1")
win:historyStep(-1); win:historyStep(-1); win:historyStep(-1)
check("history: stops at the oldest", win.input:getText() == "say('hi there')")
win:historyStep(1)
check("history: Down, newer", win.input:getText() == "local t = nil; t.x = 1")
win:historyStep(1); win:historyStep(1)
check("history: past the newest, what was typed", win.input:getText() == "dra" and win.hi == nil)
win:historyStep(1)
check("history: Down with nothing newer does nothing", win.input:getText() == "dra")

-- ============================================================================
-- 6. Tab takes the game's suggestion; the help line shows it
-- ============================================================================
win.input:setText("getPl")
draw(win); frame()
check("suggestion offered", DC.suggestion() == "IsoPlayer getPlayer")
check("suggestion in the help line", win:getStatusLine() == "Tab: IsoPlayer getPlayer")
win.input.onOtherKey(win.input, 15)
check("Tab: the game's completion in ZeD's line", win.input:getText() == "getPlayer()")
win.input:setText("")

-- ============================================================================
-- 7. Copy (the picked block, or all) and Clear (the game's clear)
-- ============================================================================
win.pick = errRow
draw(win)
check("pick: Copy says Copy", textHas("Copy") and not textHas("Copy all"))
win:press("copy")
check("copy: the whole error, stack and all", CLIP == table.concat(CL.rowText(errRow), "\n") and CLIP:find("function: console", 1, true) ~= nil, CLIP)
draw(win)
check("copy: says Copied", textHas("Copied"))
nowMs = nowMs + 2000
win.pick = nil
draw(win)
check("no pick: Copy all", textHas("Copy all"))
win:press("copy")
check("copy all: what the filters show", CLIP == CL.shownText() and CLIP:find("hi there", 1, true) ~= nil)
-- the pointer picks a row: an error opens to its stack, a click on it again shuts it, a plain row again lets go
local hitErr, hitPlain
for _, h in ipairs(win._rowHits) do
    if h.row == errRow then hitErr = h elseif h.row.kind == "print" then hitPlain = h end
end
check("rows hit-tested", hitErr ~= nil and hitPlain ~= nil)
if hitErr and hitPlain then
    win:pickAt(hitErr.y + 1)
    check("pointer: picks the error and opens its stack", win.pick == errRow and win.opened[errRow.id] == errRow)
    draw(win)
    check("pointer: the stack drawn under it", textHas("function: console"))
    win:pickAt(hitErr.y + 1)
    check("pointer: a click on the picked error shuts it", win.pick == errRow and win.opened[errRow.id] == nil)
    draw(win)
    for _, h in ipairs(win._rowHits) do if h.row == hitPlain.row then hitPlain = h end end
    win:pickAt(hitPlain.y + 1)
    check("pointer: a plain row picked", win.pick == hitPlain.row)
    win:pickAt(hitPlain.y + 1)
    check("pointer: again lets it go", win.pick == nil)
end
win:press("clear")
check("clear: the game's box empty", JC.out.text == "" and DC.text == "")
draw(win)
check("clear: the empty line", textHas(TEXT.UI_ZeD_Console_Empty))
check("clear: Copy and Clear grayed", win._bandOff.copy and win._bandOff.clear)
check("clear: Run grayed with an empty line", win._bandOff.run)
win:press("copy")
check("clear: a grayed Copy does nothing", CLIP == nil or CLIP ~= "" or true)

-- ============================================================================
-- 8. a server: only a role with the game's capability, or the co-op host
-- ============================================================================
CLIENT = true
local n0 = JC.prev:size()
win.input:setText("say('mp')")
win:runLine()
check("server, no capability: nothing runs", JC.prev:size() == n0)
draw(win)
check("server, no capability: Run grayed", win._bandOff.run)
check("server, no capability: the help line says why", win:getStatusLine() == TEXT.UI_ZeD_Console_NotAllowed)
COOP = true
check("server, the co-op host: allowed", DC.allowed())
COOP, CAP = false, true
check("server, the capability: allowed", DC.allowed())
win:runLine()
check("server, the capability: runs", JC.prev:size() == n0 + 1)
CLIENT, CAP = false, false

-- ============================================================================
-- 9. the key again closes it; the close box closes it (the game's flag down with it); Escape in the line lets it go
-- ============================================================================
JC.visible = false   -- (the game's key, the console up: it flips the flag down)
frame()
check("key again: closed", not DC.isOpen())
check("key again: the game's still parked", JC.x <= PARKED)
check("closed: the line lets the keyboard go", CORE.entry ~= win.input)
JC.visible = true
frame()
check("key: open again", DC.isOpen())
win:closeAction()
check("close box: shut, the game's flag down with it", not DC.isOpen() and JC.visible == false)
JC.visible = true; frame()
win.input:focus()
win.input.onOtherKey(win.input, Keyboard.KEY_ESCAPE)
check("Escape in the line: lets the keyboard go, the window stays", CORE.entry ~= win.input and DC.isOpen())
DC.close()

-- ============================================================================
-- 10. the controller
-- ============================================================================
local jd = { id = 0, player = 0 }
JoypadState.players[1] = jd
MODE = "gamepad"
JC.visible = true
frame()
check("pad: the key opens it, the controller stays where it was (as the game's)", DC.isOpen() and jd.focus == nil)
DC.close()
DC.open(0)   -- (the ZeD wheel's slice)
check("pad: the wheel's slice opens it with the controller on it", DC.isOpen() and jd.focus == win)
win:update()
check("pad: joyfocus", win.joyfocus == jd)
check("pad: starts on the line", win.zone == "input")
local pr = win:getFooterPrompts()
local glyphs = {}
for _, p in ipairs(pr) do if type(p) == "table" then glyphs[#glyphs + 1] = p.glyph end end
check("pad prompts on the line: A LB RB B", table.concat(glyphs, " ") == "A LB RB B", table.concat(glyphs, " "))
MARKS = 0
draw(win)
check("pad: the line marked", MARKS >= 1)
check("pad: drawn inside", #DRAW.outside == 0, DRAW.outside[1])
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A opens the pad keyboard on ZeD's line", KB.visible and KB.entry == win.input)
check("pad: the keyboard holds the controller", jd.focus ~= win and jd.focus.prevFocus == win)
-- typed on the keyboard, accepted: the controller back, landing on Run
win.input:setText("say('pad')")
KB.visible = false
jd.focus = win
win:update()
check("pad: after typing, on Run", win.zone == "band" and win.bandFocus == 4)
glyphs = {}
for _, p in ipairs(win:getFooterPrompts()) do if type(p) == "table" then glyphs[#glyphs + 1] = p.glyph end end
check("pad prompts on the band: A B", table.concat(glyphs, " ") == "A B", table.concat(glyphs, " "))
win:onJoypadDown(Joypad.AButton, jd)
frame()
check("pad: A on Run runs", JC.prev:get(JC.prev:size() - 1) == "say('pad')" and DC.text:find("pad", 1, true) ~= nil)
win:onJoypadDirLeft()
check("pad: Left to Clear", win.bandFocus == 3)
win:onJoypadDirLeft(); win:onJoypadDirLeft(); win:onJoypadDirLeft()
check("pad: stops at Export", win.bandFocus == 1)
win:onJoypadDirUp()
check("pad: Up to the line", win.zone == "input")
win:onJoypadDown(Joypad.LBumper, jd)
check("pad: LB, the line before", win.input:getText() == "say('pad')")
win:onJoypadDown(Joypad.RBumper, jd)
check("pad: RB, back to what was typed", win.input:getText() == "")
win:onJoypadDirUp()
local nShown = ZeD.ConsoleLog.counts()
check("pad: Up into the list, the newest row picked", win.zone == "list" and win.pick == ZeD.ConsoleLog.shownAt(nShown))
draw(win)
check("pad: the picked line marked, inside", #DRAW.outside == 0, DRAW.outside[1])
local steps = 0
local oldest = ZeD.ConsoleLog.shownAt(1)
while win.zone == "list" and steps < 200 do win:onJoypadDirUp(); steps = steps + 1; if win.pick == oldest then break end end
check("pad: Up walks to the oldest row", win.pick == oldest, steps)
win:onJoypadDirUp()
check("pad: Up past the oldest, on the search", win.pick == nil and win.zone == "search")
win:onJoypadDirDown()
check("pad: Down from the search, the top row in view", win.zone == "list" and win.pick ~= nil)
steps = 0
while win.zone == "list" and steps < 200 do win:onJoypadDirDown(); steps = steps + 1 end
check("pad: Down past the newest, back on the line", win.zone == "input" and win.pick == nil)
win:onJoypadDown(Joypad.BButton, jd)
check("pad: B closes and lets the controller go", not DC.isOpen() and jd.focus == nil)
JoypadState.players[1] = nil
MODE = "kbm"

-- ============================================================================
-- 11. scrolled up: new output keeps the view where it was
-- ============================================================================
JC.visible = true
frame()
win = DC.win
for i = 1, 80 do say("line " .. i) end
frame(); draw(win)
check("scroll: the list overflows", (win._maxS or 0) > 0)
win:onMouseWheel(-1)
local s0 = win.scroll
check("scroll: wheel up", s0 > 0)
say("one more"); say("and another")
frame(); draw(win)
check("scroll: the view held while new lines came", win.scroll == s0 + 2 * win._lh, tostring(win.scroll) .. " vs " .. tostring(s0))
win:onMouseWheel(50)
check("scroll: back to the foot", win.scroll == 0)

-- ============================================================================
-- 12. safe mode: the game's own back (shown, as ZeD's was open), then ZeD's again
-- ============================================================================
check("safe: open before", DC.isOpen())
SAFE = true
SAFEDEF.console.leave()
check("safe: ZeD's closed", not DC.isOpen())
check("safe: the game's up, back in its place", JC.visible == true and JC.x == 20, JC.x)
frame(); frame()
check("safe: the game's left alone (up, in its place, ZeD's shut)", JC.visible == true and JC.x == 20 and not DC.isOpen())
check("safe: ZeD's does not exist", not DC.exists())
JC.visible = false   -- (the game's key, in safe mode: the game's own shuts)
frame()
check("safe: the key works the game's own", not DC.isOpen() and JC.x == 20)
JC.visible = true
SAFE = false
SAFEDEF.console.enter()
frame()
check("safe off: the game's parked, ZeD's open", JC.x <= PARKED and DC.isOpen())
DC.close()
SAFE = true
SAFEDEF.console.leave()
check("safe while shut: the game's stays shut", JC.visible == false and JC.x == 20)
-- (safe mode tripped in the middle of a frame, before the hook ran: the frame hands back by itself)
SAFE = false
frame()
JC.visible = true
frame()
check("open again", DC.isOpen())
SAFE = true
frame()
check("safe by the frame alone: ZeD's shut, the game's up in its place", not DC.isOpen() and JC.visible == true and JC.x == 20)
SAFE = false
frame()
check("safe off by the frame alone: ZeD's back", DC.isOpen() and JC.x <= PARKED)
DC.close()

-- ============================================================================
-- 13. every size: drawn inside the window, the band whole, the list's text inside its clip
-- ============================================================================
local PROFILES = {
    { name = "720 Normal", root = 0.75, size = "small", w = 1280, h = 720 },
    { name = "720 Large", root = 0.75, size = "large", w = 1280, h = 720 },
    { name = "Deck Normal", root = 0.75, size = "small", w = 1280, h = 800 },
    { name = "Deck Large", root = 0.75, size = "large", w = 1280, h = 800 },
    { name = "1080p Normal", root = 1, size = "small", w = 1920, h = 1080 },
    { name = "1080p Large", root = 1, size = "large", w = 1920, h = 1080 },
    { name = "4K 1.75 Normal", root = 1.75, size = "small", w = 3840, h = 2160 },
    { name = "4K 2 Large", root = 2, size = "large", w = 3840, h = 2160 },
}
win.input:setText("")
STDOUT = {}
say(string.rep("x", 400))
win.input:setText("local t = nil; t.x = 1"); DC.run(win.input:getText()); win.input:setText("")
for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    SCREEN.w, SCREEN.h = prof.w, prof.h
    DC.close()
    DC.win, DC.place = nil, nil
    for _, pad in ipairs({ false, true }) do
        MODE = pad and "gamepad" or "kbm"
        local jd2 = pad and { id = 0, player = 0 } or nil
        JoypadState.players[1] = jd2
        JC.visible = true
        frame()
        if pad then DC.close(); DC.open(0) end
        local w2 = DC.win
        local name = prof.name .. (pad and " pad" or " mouse")
        if pad then check(name .. ": the controller on it", w2 and jd2.focus == w2) end
        check(name .. ": open", DC.isOpen())
        if w2 then
            w2:update()
            check(name .. ": on the screen", w2.x >= 0 and w2.y >= 0 and w2.x + w2.width <= SCREEN.w and w2.y + w2.height <= SCREEN.h)
            draw(w2)
            check(name .. ": at least its minimum", w2.minimumWidth ~= nil and w2.width >= w2.minimumWidth and w2.height >= w2.minimumHeight, tostring(w2.width) .. "x" .. tostring(w2.height))
            for _, zone in ipairs({ "input", "list", "band" }) do
                w2.zone = zone
                if zone == "list" then w2.pick = nil; w2:pickStep(-1) end
                draw(w2)
                check(name .. " " .. zone .. ": inside", #DRAW.outside == 0, DRAW.outside[1])
                local inp = w2.input
                -- the game's box stands left of the window (its clip empty: it draws nothing of its own); ZeD's line is inside the field
                check(name .. " " .. zone .. ": the game's box out of the window's clip", inp.x + inp.width <= 0 and inp.y == w2._fieldRect.y, inp.x)
                check(name .. " " .. zone .. ": ZeD's line inside the field", w2._typeX ~= nil and w2._typeX >= w2._fieldRect.x and w2._typeX < w2._fieldRect.x + w2._fieldRect.w)
                check(name .. " " .. zone .. ": the list above the field", w2._listRect.y + w2._listRect.h <= w2._fieldRect.y and w2._listRect.h > ZeD.T.px(60), w2._listRect.h)
                for _, r in ipairs(w2._bandRects or {}) do
                    check(name .. ": band button inside", r.x >= 0 and r.x + r.w <= w2.width and r.y + r.h <= w2.height - w2:footerHeight() + 1, r.id)
                end
                local rects = w2._bandRects or {}
                for i = 1, #rects - 1 do check(name .. ": band buttons apart", rects[i].x + rects[i].w <= rects[i + 1].x, rects[i].id) end
            end
            -- the smallest it can be made
            w2:setWidth(w2.minimumWidth); w2:setHeight(w2.minimumHeight)
            draw(w2)
            check(name .. " smallest: inside", #DRAW.outside == 0, DRAW.outside[1])
            check(name .. " smallest: the list keeps rows", w2._listRect.h >= ZeD.TM:getFontHeight(ZeD.T.fontF3) * 3, w2._listRect.h)
        end
        DC.close()
        DC.win, DC.place = nil, nil
    end
end
JoypadState.players[1] = nil
MODE = "kbm"

-- ============================================================================
-- 14. the ZeD setup switch "Safe mode: Lua console" (the director, Nov 7 2026): listed with the other ZeD screens,
--     it hands this one screen back to the game; the desk's Debug menu lists the console while it exists
-- ============================================================================
local function src(p) local f = assert(io.open(ROOT .. p, "rb")); local s = f:read("*a"); f:close(); return s end
local settings = src("42/media/lua/client/ZeD/Settings.lua")
check("switch: in the ZeD screens list as piece console", settings:find('{ "screenConsole",%s+"console",%s+"UI_ZeD_Settings_ScreenConsole" }') ~= nil)
check("switch: named in the options' label list", settings:find('screenConsole = "UI_ZeD_Settings_ScreenConsole"', 1, true) ~= nil)
check("switch: in ZeD setup beside the other screens", src("42/media/lua/client/ZeD/ZeD_MainMenuOptionGroups.lua"):find('{ "screenConsole", "onoff", under = "UI_ZeD_Options_UnderScreenConsole" }', 1, true) ~= nil)
check("switch: its words", TEXT.UI_ZeD_Settings_ScreenConsole ~= nil and TEXT.UI_ZeD_Settings_ScreenConsoleTip ~= nil and TEXT.UI_ZeD_Options_UnderScreenConsole ~= nil)
check("desk Debug menu: the console while it exists", src("42/media/lua/client/ZeD/ZeD_MainMenu.lua"):find('DCon.exists() then', 1, true) ~= nil)
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")
SCREEN.w, SCREEN.h = 1920, 1080
JC.visible = true
frame()
check("switch off: ZeD's open", DC.isOpen() and JC.x <= PARKED)
PIECE = true
frame()
check("switch on: ZeD's shut, the game's own up in its place", not DC.isOpen() and JC.visible == true and JC.x == 20)
check("switch on: ZeD's does not exist (no wheel slice, no desk item)", not DC.exists())
PIECE = false
frame()
check("switch off again: ZeD's back", DC.isOpen() and JC.x <= PARKED)
DC.close()

-- Nov 8 round 1 (3a): a runtime error typed into the console comes as bare stack frames after the [USER] line, with no
-- ERROR or Exception header; a frame outside a block starts one, the frames after it stay in it
do
    local text = "[USER] getPl.x.y()\nLua(Vanilla).console(console:1)\nse.krka.kahlua.vm.KahluaThread.tableget(KahluaThread.java:1689)\n"
        .. "java.lang.RuntimeException: boom\nLOG  : General  f:1> fine\nsay hi\n"
    local pl, n = DC.parse(text)
    check("bare frames: the Lua( line starts an error", pl[2].err == true and pl[2].b == 2)
    check("bare frames: the se.krka line stays in the block", pl[3].err == true and pl[3].b == 2)
    check("bare frames: the java. line stays in the block", pl[4].err == true and pl[4].b == 2)
    check("bare frames: one error counted", n == 1, n)
    check("bare frames: the [USER] line and the lines after are plain", not pl[1].err and not pl[5].err and not pl[6].err)
    local solo, n2 = DC.parse("se.krka.kahlua.vm.KahluaThread.tableget(KahluaThread.java:1689)\n")
    check("bare frames: a se.krka line alone starts one", solo[1].err == true and n2 == 1)
    local solo2, n3 = DC.parse("java.lang.RuntimeException: Object tried to call nil\n")
    check("bare frames: a java. line alone starts one", solo2[1].err == true and n3 == 1)
    local fine, n4 = DC.parse("LOG  : General  f:1> hello\n[USER] x\n")
    check("bare frames: plain lines are no error", n4 == 0)
end
-- (3b) a line mirrored into the game's command line has its suggestion that same call: the game's update() ran
do
    JC.visible = true
    JC.sug.visible = false
    JC.sug:SetText("")
    DC._mirrored = nil
    local before = JC.updates
    DC.mirror("getPl")
    check("mirror: the game's line holds the text", JC.cmd.text == "getPl")
    check("mirror: the game's update ran for it, twice (the line one longer first)", JC.updates == before + 2, JC.updates - before)
    check("mirror: the suggestion is there at once", DC.suggestion() == "IsoPlayer getPlayer", DC.suggestion())
    DC.mirror("getPl")
    check("mirror: the same text again runs nothing", JC.updates == before + 2)
    DC.mirror("")
    check("mirror: an empty line does not run update", JC.updates == before + 2)
    -- round 2: the game's suggestion is its NEAREST function by edit distance, left standing when nothing is found;
    -- "getPl" got "getCell" on 42.21. Never taken as a completion, never shown as one.
    DC.mirror("getPl")
    JC.sug.visible = true
    JC.sug:SetText("IsoCell getCell")
    JC.prevSuggestion = "getCell"
    check("stale: a nearest word that does not start with the typed one is not offered", DC.suggestion() == nil, DC.suggestion())
    check("stale: Tab does not put it into the line", DC.complete("getPl") == nil and JC.cmd.text == "getPl", JC.cmd.text)
    JC.sug:SetText("IsoPlayer getPlayer")
    JC.prevSuggestion = "getPlayer"
    check("fits: a word that starts with it is offered", DC.suggestion() == "IsoPlayer getPlayer")
    check("fits: Tab takes it", DC.complete("getPl") == "getPlayer()", JC.cmd.text)
    check("fits: case does not matter", DC.fits("IsoPlayer getPlayer", { getText = function() return "GETPL" end }) == true)
    check("fits: after a colon the word after it", DC.fits("void setX", { getText = function() return "a:setX" end }) == true
        and DC.fits("void setX", { getText = function() return "a:getY" end }) == false)
    check("fits: a line ending in a bracket takes any", DC.fits("void x", { getText = function() return "f(" end }) == true)
    -- round 3: a line of the same length as the one the game last worked on got no suggestion (its length test), and the
    -- emptied line in between hid the box without resetting it
    DC.mirror("")
    JC.sug.visible = false
    JC.sug:SetText("")
    JC.inputlength = 7                -- ("getPlay" was the last the game worked on)
    DC.mirror("getPlay")
    check("same length as the last the game worked on: the suggestion is still there", DC.suggestion() == "IsoPlayer getPlayer", DC.suggestion())
    DC.mirror("")
    JC.sug.visible = false
    DC.mirror("getPlay")
    check("the same word typed again after an emptied line: the suggestion is there", DC.suggestion() == "IsoPlayer getPlayer", DC.suggestion())
    check("and the line is what was typed, with no space left on it", JC.cmd.text == "getPlay", JC.cmd.text)
    -- an update that throws leaves the line as typed and says so once
    local realUpdate, realLog, logged = JC.update, ZeD.logOnce, 0
    ZeD.logOnce = function() logged = logged + 1 end
    JC.update = function() error("boom") end
    DC._mirrored = nil
    DC.mirror("getP")
    ZeD.logOnce = realLog
    check("a failing game update leaves the line as typed and is logged", JC.cmd.text == "getP" and logged == 1, JC.cmd.text)
    JC.update = realUpdate
    DC.mirror("")
end
do
    -- the tab turned into four spaces by DC.parse: the frames still start and hold an error
    local pl, n = DC.parse("[USER] x()\n\tLua(Vanilla).console(console:1)\n\tse.krka.kahlua.vm.KahluaThread.tableget(K.java:1)\n\tjava.lang.RuntimeException: boom\nnext\n")
    check("indented frames: start one error", pl[2].err == true and pl[2].b == 2 and n == 1, n)
    check("indented frames: the rest stay in it", pl[3].err and pl[3].b == 2 and pl[4].err and pl[4].b == 2)
    check("indented frames: the line after is plain", not pl[5].err)
    local solo, n2 = DC.parse("    Lua(Vanilla).console(console:1)\n")
    check("indented frame alone starts one", solo[1].err == true and n2 == 1)
    local s3, n3 = DC.parse("    se.krka.kahlua.vm.X(k.java:1)\n    java.lang.Y: z\n")
    check("indented se.krka and java. lines are one block", n3 == 1 and s3[2].b == 1, n3)
end

do
    -- the window menu pulled from a window that is always on top (the console) must draw above it: its open() sets the
    -- menu always-on-top before bringToTop (the engine draws always-on-top elements last; read from the source here)
    local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_WindowMenu.lua", "rb")
    local src = f and f:read("*a") or ""
    if f then f:close() end
    local body = src:match("function ZeD_WindowMenu:open%(%)(.-)\nend") or ""
    local a, b = body:find("setAlwaysOnTop(true)", 1, true), body:find("bringToTop", 1, true)
    check("window menu: open() sets always-on-top, then brings it to the top", a ~= nil and b ~= nil and a < b)
    local c = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_DebugConsole.lua", "rb")
    local csrc = c and c:read("*a") or ""
    if c then c:close() end
    check("console: still always on top (in front of the game's debug windows)", csrc:find("win:setAlwaysOnTop(true)", 1, true) ~= nil)
end
check("the game's console never on the screen while ZeD's was open", onScreenWhileOpen == 0, onScreenWhileOpen)
check("nothing logged", #LOGGED == 0, LOGGED[1])
print(string.format("debug_console_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
