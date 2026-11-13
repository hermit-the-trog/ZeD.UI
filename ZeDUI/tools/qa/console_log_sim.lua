-- ZeDUI/tools/qa/console_log_sim.lua  (Nov 12 2026, punch list 136 Phase 1): the Lua console's Log page with no game running.
-- The real Tokens, Tr, Atoms, AtomExtensions, Molecules, ZeD_ConsoleLog and ZeD_DebugConsole on the same Lua 5.1 stubs as
-- debug_console_sim.lua (the window, the text boxes, the game's console as javap reads it), plus the F11 list
-- (getLuaDebuggerErrors / getLuaDebuggerErrorCount, its last 40 entries), getFileWriter, the clock and the active mods.
-- It checks:
--   * rows from the box's prints and warnings (the log prefix taken off), a line not finished yet waits, the box losing
--     its front past 8192 characters reads only what is new, a cleared box starts again
--   * the mod and file:line of an error from the 42.22 stack lines ("| MOD: X", "| Vanilla", "Lua((MOD:X)).fn(f:n)",
--     "Lua(Vanilla).fn(f:n)"), a mod's frame before the game's code it called, unknown -> Game; a print's "[Tag]" / "Tag:"
--   * a repeated error is one row with a count, the box and the F11 list telling the same error count it once
--   * the filters (KIND / MOD / FILE) and their counts, which follow the search; the search across message, mod, file and
--     every stack line; filtering walks the rows only when the search or a tick changes
--   * an error opened to its stack in place and shut again (closed when the log opens)
--   * Export: what the filters show, its header, the stacks, the file named for the time (a second in the same second gets
--     _2), the band saying where; Copy and Copy all
--   * the cap (FIFO: the oldest rows go, the names that went with them too), and 6000 lines fed in chunks under the cap
--   * the window: the page strip (Commands and Help say "coming"), the filter column, the search field, the pad walk
--     (strip, filters, search, log, line, band; A ticks, opens, types, presses; X exports; B closes), Deck 1280 x 800 Auto
--   * the log prefix in every shape 42.22.2 writes it (the frame alone, " t:", " st:", " at <caller>") and 42.21's;
--     the lines a scratchpad run told ahead skipped once each in the box (past the 64th too), forgotten after
--     EXPECT_MS or past EXPECT_CAP, and a box full of lines nobody told read fast
-- What it cannot prove: the engine (real fonts, the text box's keys, what 42.22 really writes into the box and the list).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/console_log_sim.lua
-- It prints FAIL lines and a last line "console_log_sim: N checks, M failed", and exits 1 if any failed.

-- the clock (SimpleDateFormat over Calendar, as ZeD_ConsoleLog reads it)
CLOCK = { t = "14:30:05", d = "2026-11-12_143005" }
Locale = { ENGLISH = "en" }
SimpleDateFormat = { new = function(p) return { format = function(_, _) if p == "HH:mm:ss" then return CLOCK.t end return CLOCK.d end } end }
Calendar = { getInstance = function() return { getTime = function() return 0 end } end }
-- the active mods
local MODS = { { id = "Bandits", name = "Bandits" }, { id = "LaddersMod", name = "Ladders" } }
function getActivatedMods() return { size = function() return #MODS end, get = function(_, i) return MODS[i + 1].id end } end
function getModInfoByID(id) for _, m in ipairs(MODS) do if m.id == id then return { getName = function() return m.name end } end end return nil end
-- the F11 list: its last 40 entries, and a count of every entry it ever added
F11 = { n = 0, list = {} }
function getLuaDebuggerErrorCount() return F11.n end
function getLuaDebuggerErrors()
    return { size = function() return #F11.list end, get = function(_, i) return F11.list[i + 1] end }
end
function F11add(s)
    F11.n = F11.n + 1
    F11.list[#F11.list + 1] = s
    if #F11.list > 40 then table.remove(F11.list, 1) end
end
-- the files written in Zomboid/Lua
FILES = {}
function getFileWriter(name, create, append)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() FILES[name] = table.concat(buf) end }
end

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]console_log_sim%.lua$", "")

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
function ISTextEntryBox:setMultipleLine(b) self.multi = b end   -- (the scratchpad's box, Phase 2)
function ISTextEntryBox:isMultipleLine() return self.multi == true end
function ISTextEntryBox:setMaxLines(n) self.maxL = n end
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


local L = ZeD.ConsoleLog
check("the log module loads with the console", L ~= nil and type(L.feedText) == "function" and type(L.feedErrors) == "function")
local function P(s) return "LOG  : Lua          f:1, t:1> " .. s .. "\n" end
local function rowsOf(kind)
    local out = {}
    for i = 1, L.counts() do local r = L.shownAt(i); if not kind or r.kind == kind then out[#out + 1] = r end end
    return out
end
local function findRow(msgPart)
    for i = L.first, L.last do local r = L.rows[i]; if r.msg:find(msgPart, 1, true) then return r end end
    return nil
end

-- the error as the box writes it on 42.22 (ExceptionLogger, then the Lua stack), a Bandits mod frame over the game's
local BOX_ERR = "ERROR: General      f:4821, t:1762935182311> ExceptionLogger.logException> Exception thrown\n"
    .. "    java.lang.RuntimeException: attempted index: getHealth of non-table: null at KahluaThread.tableget(KahluaThread.java:1666).\n"
    .. "LOG  : General      f:4821, t:1762935182312> -----------------------------------------\n"
    .. "STACK TRACE\n-----------------------------------------\nCallframe at: getHealth\n"
    .. "function: BanditUpdate.Health -- file: BanditUpdate.lua line # 1203 | MOD: Bandits\n"
    .. "function: BanditUpdate.OnZombieUpdate -- file: BanditUpdate.lua line # 1488 | MOD: Bandits\n"
    .. "function: Event.trigger -- file: Events.lua line # 81 | Vanilla\n"
-- the same error as the F11 list keeps it: a separator with the message, the Lua dump, the exception
local function f11Bandits()
    F11add("-----------------------------------------\nattempted index: getHealth of non-table: null")
    F11add("dumping Lua stack trace\nfunction: BanditUpdate.Health -- file: BanditUpdate.lua line # 1203 | MOD: Bandits\n"
        .. "function: BanditUpdate.OnZombieUpdate -- file: BanditUpdate.lua line # 1488 | MOD: Bandits")
    F11add("java.lang.RuntimeException: attempted index: getHealth of non-table: null at KahluaThread.tableget(KahluaThread.java:1666).")
end

-- ============================================================================
-- 1. rows from the box: prints and warnings, the prefix off, a mod named where the line says
-- ============================================================================
do
    L.reset(); L.forgetMods()
    local box = P("Lua: loading 3 mods") .. P("[ZeD] ready: 27 languages") .. "WARN : Lua          f:2, t:3> ScriptManager.getItem> item not found: Base.RopeLadder\n"
        .. P("Bandits: wave 3 in 2 hours") .. P("Ladders: 214 sprites") .. P("Nobody: not a mod")
    L.feedText(box, 1000)
    local shown, total, errs = L.counts()
    check("box: six rows", shown == 6 and total == 6 and errs == 0, shown)
    local r = rowsOf()
    check("box: the log prefix taken off", r[1].msg == "Lua: loading 3 mods", r[1].msg)
    check("box: kinds print and warn", r[1].kind == "print" and r[3].kind == "warn" and r[3].msg:find("^ScriptManager") ~= nil)
    check("box: the game's line is Game's", r[1].mod == L.GAME)
    check("box: [ZeD] is ZeD-GUI's", r[2].mod == "ZeD-GUI", r[2].mod)
    check("box: 'Bandits:' names the active mod", r[4].mod == "Bandits", r[4].mod)
    check("box: a mod's name (not its id) in front", r[5].mod == "Ladders", r[5].mod)
    check("box: a word that is no mod stays Game's", r[6].mod == L.GAME)
    check("box: the time on each row", r[1].t == "14:30:05")
    check("box: a print names no file", r[1].file == "" and L.srcOf(r[1]) == "")
    -- a line the game has not finished yet waits; the rest of it comes and it is one row
    L.feedText(box .. "LOG  : Lua          f:1, t:1> half", 1100)
    check("partial: no row until its newline", L.counts() == 6)
    L.feedText(box .. P("half done"), 1200)
    check("partial: one row when it ends", L.counts() == 7 and rowsOf()[7].msg == "half done", rowsOf()[7] and rowsOf()[7].msg)
    -- the box keeps its last 8192 characters: the front goes, only the new lines are read
    local long = box .. P("half done")
    local more = {}
    for i = 1, 150 do more[#more + 1] = P("filler line " .. i) end
    local full = long .. table.concat(more)
    L.feedText(full:sub(-8192), 1250)
    check("box under 8192: all of it", L.counts() == 157 and #full < 8192, L.counts())
    more = {}
    for i = 151, 300 do more[#more + 1] = P("filler line " .. i) end
    full = full .. table.concat(more)
    L.feedText(full:sub(-8192), 1300)
    check("trimmed box: only the new lines read", L.counts() == 307 and rowsOf()[307].msg == "filler line 300", L.counts())
    local before = L.counts()
    local next1 = (full .. P("after the trim")):sub(-8192)
    L.feedText(next1, 1400)
    check("trimmed box again: one new row", L.counts() == before + 1 and rowsOf()[before + 1].msg == "after the trim")
    -- the same text twice adds nothing; a cleared box starts again
    L.feedText(next1, 1500)
    check("same text: nothing new", L.counts() == before + 1)
    L.feedText("", 1600)
    L.feedText(P("fresh start"), 1700)
    check("cleared box: its new lines read", rowsOf()[#rowsOf()].msg == "fresh start" and L.counts() == before + 2)
    -- more than 8192 characters between two reads: what the box lost is lost, its cut first line is skipped
    local flood = {}
    for i = 1, 400 do flood[#flood + 1] = P("flood " .. i) end
    local before2 = L.counts()
    local ftext = (P("fresh start") .. table.concat(flood)):sub(-8192)
    L.feedText(ftext, 1650)
    local whole = 0
    for l in ftext:gmatch("([^\n]*)\n") do whole = whole + 1 end
    check("flood: only whole lines read", L.counts() == before2 + whole - 1 and rowsOf()[before2 + 1].msg:find("^flood %d+$") ~= nil, rowsOf()[before2 + 1].msg)
    L.feedText("", 1660)
    L.feedText(P("fresh start"), 1670)
    -- the console's own echo of a line run here is not a second "ran" row
    L.ran("print(1)")
    L.feedText(P("fresh start") .. "[USER] print(1)\n" .. P("1"), 1800)
    local ran = rowsOf("ran")
    check("ran: one row for a line run here", #ran == 1 and ran[1].msg == "> print(1)" and ran[1].mod == L.CONSOLE)
    -- 42.22 (QA's beta 12 release pass): the echo reads [USER] - "line". and the print comes twice, bare (the console's
    -- print callback) and through the log with its prefix; one "ran" row and one print row
    L.reset(); L._twins = nil
    L.ran('print("hello")')
    local b2 = P("start") .. '[USER] - "print("hello")".\n' .. "hello\n" .. P("hello")
    L.feedText(b2, 1900)
    local ran2, pr = rowsOf("ran"), 0
    for _, r in ipairs(rowsOf("print")) do if r.msg == "hello" then pr = pr + 1 end end
    check("42.22 echo: one ran row", #ran2 == 1 and ran2[1].msg == '> print("hello")', #ran2 .. " " .. tostring(ran2[2] and ran2[2].msg))
    check("42.22 print: bare and prefixed copies are one row", pr == 1, pr)
    -- print(a, b): the tab the same in both copies
    L.feedText(b2 .. "true\ttrue\n" .. P("true\ttrue"), 1950)
    local ab = 0
    for _, r in ipairs(rowsOf("print")) do if r.msg:find("^true%s+true$") then ab = ab + 1 end end
    check("42.22 print(a, b): one row", ab == 1, ab)
    -- the same words printed twice through the log are two prints, two rows
    L.feedText(b2 .. "true\ttrue\n" .. P("true\ttrue") .. P("again") .. P("again"), 2000)
    local ag = 0
    for _, r in ipairs(rowsOf("print")) do if r.msg == "again" then ag = ag + 1 end end
    check("two prints of the same words stay two rows", ag == 2, ag)
    -- a scratchpad run: the row is told ahead, and both box copies are skipped
    L.output("scr", nil, 2100)
    L.feedText(b2 .. "true\ttrue\n" .. P("true\ttrue") .. P("again") .. P("again") .. "scr\n" .. P("scr"), 2100)
    local sc = 0
    for _, r in ipairs(rowsOf("print")) do if r.msg == "scr" then sc = sc + 1 end end
    check("scratchpad print: one row", sc == 1, sc)
end

-- ============================================================================
-- 2. errors: where they came from, from 42.22's stack lines
-- ============================================================================
do
    L.reset(); L.forgetMods()
    L.feedText(BOX_ERR, 2000)
    check("box error: waits while its stack may go on", L.counts() == 0)
    L.tick(2000 + L.FLUSH_MS)
    local e = rowsOf("error")[1]
    check("box error: one row once FLUSH_MS passed", e ~= nil and L.counts() == 1)
    check("box error: the message without the Java class or its 'at ...'", e and e.msg == "attempted index: getHealth of non-table: null", e and e.msg)
    check("box error: the mod from '| MOD: Bandits'", e and e.mod == "Bandits")
    check("box error: the file and line of the mod's top frame", e and e.file == "BanditUpdate.lua" and e.line == 1203 and L.srcOf(e) == "BanditUpdate.lua:1203")
    check("box error: the whole block is its stack, without the dividers", e and #e.stack == 6 and e.stack[#e.stack]:find("| Vanilla", 1, true) ~= nil, e and #e.stack)
    check("box error: counted", L.errTotal == 1 and select(3, L.counts()) == 1)
    -- a following plain line closes the block at once
    L.reset()
    L.feedText(BOX_ERR .. P("next"), 2100)
    check("box error: a plain line after closes it", L.counts() == 2 and rowsOf()[1].kind == "error" and rowsOf()[2].msg == "next")
    -- the frame shapes
    local m, f, l = L.placeOf("x\n\tLua((MOD:Ladders!? (v0.0.13))).climb(Ladders.lua:12)\n\tLua(Vanilla).update(ISUI.lua:4)")
    check("frames: Lua((MOD:X)) with a bracket in the name", m == "Ladders!? (v0.0.13)" and f == "Ladders.lua" and l == 12, tostring(m) .. " " .. tostring(f))
    m, f, l = L.placeOf("x\n\tLua(Vanilla).bareCharacter(spawnpoints.lua:206)\n\tLua((MOD:Bandits Week One)).open(BWOMenu.lua:9)")
    check("frames: the mod's frame before the game code it called", m == "Bandits Week One" and f == "BWOMenu.lua" and l == 9)
    m, f, l = L.placeOf("function: ISInventoryPane.doContextualDblClick -- file: ISInventoryPane.lua line # 1045 | Vanilla")
    check("frames: '| Vanilla' alone is the game's, with its place", m == L.GAME and f == "ISInventoryPane.lua" and l == 1045)
    m, f, l = L.placeOf("java.lang.RuntimeException: boom")
    check("frames: no frame, Game's and no file", m == L.GAME and f == "" and l == nil)
    m, f, l = L.placeOf("console:1: '<eof>' expected near 'end'", "console:1: '<eof>' expected near 'end'")
    check("frames: a line that did not compile is the Console's", m == L.CONSOLE and f == "console" and l == 1)
    check("message: a compile error as the console said it", L.messageOf("[string \"console\"]:1: unexpected symbol near 'is'") == "[string \"console\"]:1: unexpected symbol near 'is'")
    check("message: from the exception line, not the ERROR head", L.messageOf("ERROR: General f:1, t:1> ExceptionLogger.logException> Exception thrown\n\tjava.lang.RuntimeException: Object tried to call nil in isClimbing at KahluaUtil.fail(KahluaUtil.java:82).") == "Object tried to call nil in isClimbing")
end

-- ============================================================================
-- 3. a repeated error is one row with a count; the box and the F11 list telling one error count it once
-- ============================================================================
do
    L.reset(); L.forgetMods()
    F11.n, F11.list = 0, {}
    L.feedText(BOX_ERR .. P("after"), 3000)
    f11Bandits()
    L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 3000)
    L.tick(3000 + L.FLUSH_MS)
    local errs = rowsOf("error")
    check("one error, two sources: one row", #errs == 1, #errs)
    check("one error, two sources: counted once", errs[1] and errs[1].n == 1 and L.errTotal == 1, errs[1] and errs[1].n)
    f11Bandits(); f11Bandits()
    L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 3500)
    L.tick(3500 + L.FLUSH_MS)
    errs = rowsOf("error")
    check("x3: still one row", #errs == 1 and L.counts() == 2)
    check("x3: its count", errs[1].n == 3 and L.errTotal == 3, errs[1].n)
    check("x3: the row keeps its place in the list", rowsOf()[1] == errs[1])
    -- the box prints it a second time: the F11 list already counted three, so still three
    L.feedText(BOX_ERR .. P("after") .. BOX_ERR .. P("again"), 3600)
    check("box sees it again: the larger count stays", errs[1].n == 3 and errs[1].nBox == 2 and errs[1].nF11 == 3)
    -- the F11 list full (40 kept): only the count's rise is read, from the end; read every half second, nothing is lost
    for b = 1, 4 do
        for i = 1, 5 do f11Bandits() end
        L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 4000 + b)
    end
    L.tick(4004 + L.FLUSH_MS)
    check("F11 list past 40 entries: every new error read", errs[1].n == 23 and #F11.list == 40, errs[1].n)
    -- 20 errors (60 entries) between two reads: the list kept the last 40, so 13 whole errors are there to read
    for i = 1, 20 do f11Bandits() end
    L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 4050)
    L.tick(4050 + L.FLUSH_MS)
    check("60 entries at once: what the list still holds", errs[1].n == 36, errs[1].n)
    F11add("-----------------------------------------\nObject tried to call nil in isClimbing")
    F11add("java.lang.RuntimeException: Object tried to call nil in isClimbing at KahluaUtil.fail(KahluaUtil.java:82).\n\tLua((MOD:Ladders)).climbLadder(Ladders.lua:88)")
    L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 4100)
    L.tick(4100 + L.FLUSH_MS)
    local lad = findRow("isClimbing")
    check("another error: its own row", lad ~= nil and lad.n == 1 and lad.mod == "Ladders" and L.srcOf(lad) == "Ladders.lua:88")
    check("nothing read twice", L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 4200) == false)
end

-- ============================================================================
-- 3b. an error typed into the console in -debug (QA b12 round 2): the box's block is the Lua dump and the Java frames
--     with no "Exception:" line, the F11 list has the message; both at ZeD_DebugConsole.lua:266. Run 3 times: one row
--     x3, "Errors: 3", whichever source comes first
-- ============================================================================
do
    local CON_BOX = "ERROR: Lua          f:244> \tLua(Vanilla).console(console:1)\n"
        .. "\tLua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)\n"
        .. "\tLua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)\n"
        .. "\tse.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:1108)\n"
        .. "\tse.krka.kahlua.integration.LuaCaller.protectedCall(LuaCaller.java:109)\n"
        .. "\tzombie.ui.UIDebugConsole.ProcessCommand(UIDebugConsole.java:391)\n"
        .. "\tjava.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n"
        .. "\tzombie.GameWindow.logic(GameWindow.java:391)\n"
        .. "\tjava.base/java.lang.Thread.run(Unknown Source)\n"
    local function f11Con()
        F11add("-----------------------------------------\nattempted index of non-table")
        F11add("dumping Lua stack trace\n-----------------------------------------\nSTACK TRACE\n-----------------------------------------\n"
            .. "Lua(Vanilla).console(console:1)\nLua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)\nLua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)")
    end
    check("message: a block of Java frames and Lua dump only has none", L.messageOf(CON_BOX) == "")
    for order = 1, 3 do
        L.reset(); L.forgetMods()
        F11.n, F11.list = 0, {}
        local box, ms = "", 9000
        local function boxOnce() box = box .. CON_BOX .. P("ran " .. ms); L.feedText(box, ms) end
        local function f11Once() f11Con(); L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), ms) end
        for i = 1, 3 do
            ms = ms + 600
            if order == 1 then boxOnce(); f11Once()
            elseif order == 2 then f11Once(); boxOnce()
            else boxOnce() end
            L.tick(ms + L.FLUSH_MS)
        end
        if order == 3 then for i = 1, 3 do ms = ms + 600; f11Once(); L.tick(ms + L.FLUSH_MS) end end
        local errs = rowsOf("error")
        local tag = "console error x3 (" .. ({ "box first", "F11 first", "box all, then F11" })[order] .. "): "
        check(tag .. "the rows shown and kept agree", select(2, L.counts()) == L.last - L.first + 1 and L.shownErr == 1)
        check(tag .. "one row", #errs == 1, #errs .. " rows: " .. tostring(errs[1] and errs[1].msg) .. " / " .. tostring(errs[2] and errs[2].msg))
        check(tag .. "counted 3", errs[1] and errs[1].n == 3, errs[1] and errs[1].n)
        check(tag .. "Errors: 3", L.errTotal == 3, L.errTotal)
        check(tag .. "the F11 list's message", errs[1] and errs[1].msg == "attempted index of non-table", errs[1] and errs[1].msg)
        check(tag .. "its place", errs[1] and L.srcOf(errs[1]) == "ZeD_DebugConsole.lua:266" and errs[1].mod == "ZeD-GUI", errs[1] and L.srcOf(errs[1]))
        check(tag .. "the search finds the message", L.setQuery("non-table") and L.counts() == 1)
        L.setQuery("")
    end
    -- two different errors typed one after the other, at the same place: two rows, one each
    L.reset(); L.forgetMods()
    F11.n, F11.list = 0, {}
    local box = CON_BOX .. P("one")
    L.feedText(box, 12000); f11Con(); L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 12000)
    L.tick(12000 + L.FLUSH_MS)
    L.feedText(box .. CON_BOX .. P("two"), 12600)
    F11add("-----------------------------------------\nattempt to call nil")
    F11add("dumping Lua stack trace\nLua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)")
    L.feedErrors(getLuaDebuggerErrors(), getLuaDebuggerErrorCount(), 12600)
    L.tick(12600 + L.FLUSH_MS)
    local errs = rowsOf("error")
    check("two console errors at one place: two rows", #errs == 2 and errs[1].n == 1 and errs[2].n == 1 and L.errTotal == 2,
        #errs .. " rows, total " .. L.errTotal)
    check("two console errors: each its message", errs[2] and errs[1].msg == "attempted index of non-table" and errs[2].msg == "attempt to call nil",
        errs[2] and errs[2].msg)
end

-- ============================================================================
-- 4. filters and their counts; the search across message, mod, file and every stack line
-- ============================================================================
do
    L.reset(); L.forgetMods()
    F11.n, F11.list = 0, {}
    L.feedText(P("[ZeD] card: Base.Axe") .. P("Bandits: wave 3") .. "WARN : Lua f:2, t:3> Bandits: program Looter idling\n" .. BOX_ERR .. P("tail line"), 5000)
    local walks = 0
    local realRefilter = L.refilter
    L.refilter = function() walks = walks + 1; return realRefilter() end
    local shown, total = L.counts()
    check("filters: five rows", shown == 5 and total == 5, shown)
    check("filters: kind counts", L.cnt.kind.print == 3 and L.cnt.kind.warn == 1 and L.cnt.kind.error == 1)
    check("filters: mod counts", L.cnt.mod.Bandits == 3 and L.cnt.mod["ZeD-GUI"] == 1 and L.cnt.mod[L.GAME] == 1, L.cnt.mod.Bandits)
    check("filters: file counts", L.cnt.file[""] == 4 and L.cnt.file["BanditUpdate.lua"] == 1)
    check("filters: the mods listed once each", #L.mods == 3 and #L.files == 2)
    L.toggle("kind", "print")
    shown = L.counts()
    check("untick Print: prints hidden", shown == 2 and not L.isOn("kind", "print"))
    check("untick Print: the counts stay (they follow the search, not the ticks)", L.cnt.kind.print == 3)
    L.toggle("mod", "Bandits")
    check("untick Bandits too: nothing left", L.counts() == 0)
    L.toggle("kind", "print"); L.toggle("mod", "Bandits")
    check("tick both again: all five", L.counts() == 5)
    L.toggle("file", "")
    check("untick No file: only the error", L.counts() == 1 and L.shownAt(1).kind == "error")
    L.toggle("file", "")
    local w0 = walks
    check("search: a word only in a stack line finds the error", L.setQuery("OnZombieUpdate") and L.counts() == 1 and L.shownAt(1).kind == "error")
    check("search: the counts follow it", (L.cnt.kind.print or 0) == 0 and L.cnt.kind.error == 1 and L.cnt.mod.Bandits == 1)
    check("search: the same words again walk nothing", L.setQuery("OnZombieUpdate") == false and walks == w0 + 1)
    L.setQuery("bandits")
    check("search: a mod's name, any case", L.counts() == 3, L.counts())
    L.setQuery("BanditUpdate.lua:1203")
    check("search: a file:line", L.counts() == 1)
    L.setQuery("zed-gui")
    check("search: ZeD's own name", L.counts() == 1 and L.shownAt(1).mod == "ZeD-GUI")
    L.setQuery("game")
    check("search: the Game mod's shown name", L.counts() >= 1 and L.shownAt(1).mod == L.GAME)
    L.setQuery("no such words")
    check("search: nothing matches, none shown, counts zero", L.counts() == 0 and (L.cnt.kind.print or 0) == 0)
    L.setQuery("")
    check("search cleared: all back", L.counts() == 5)
    -- new rows while filtered: counted and shown as they come, no walk
    L.toggle("kind", "warn")
    local w1 = walks
    L.feedText(P("[ZeD] card: Base.Axe") .. P("Bandits: wave 3") .. "WARN : Lua f:2, t:3> Bandits: program Looter idling\n" .. BOX_ERR .. P("tail line")
        .. P("one more") .. "WARN : Lua f:9, t:9> another warning\n", 5100)
    check("new rows while filtered: no walk", walks == w1)
    check("new rows while filtered: the print shown, the warning hidden, both counted", L.counts() == 5 and L.cnt.kind.warn == 2 and L.cnt.kind.print == 4)
    L.toggle("kind", "warn")
    L.refilter = realRefilter
end

-- ============================================================================
-- 5. the cap: the oldest rows go first, and the names that went with them
-- ============================================================================
do
    L.reset(); L.forgetMods()
    local cap = L.CAP
    L.CAP = 50
    local text = P("Bandits: first")
    for i = 1, 119 do text = text .. P("row " .. i) end
    L.feedText(text, 6000)
    local shown, total = L.counts()
    check("cap: 50 rows kept of 120", total == 50 and shown == 50, total)
    check("cap: the oldest went first", L.shownAt(1).msg == "row 70" and L.shownAt(50).msg == "row 119", L.shownAt(1).msg)
    check("cap: Bandits went with its only row", L.all.mod.Bandits == nil and #L.mods == 1 and (L.cnt.mod.Bandits or 0) == 0)
    L.toggle("kind", "print")
    L.feedText(text .. P("row 120"), 6100)
    check("cap while filtered: nothing shown, still 50 kept", L.counts() == 0 and select(2, L.counts()) == 50)
    L.toggle("kind", "print")
    check("cap: every kept row shown again", L.counts() == 50 and L.shownAt(50).msg == "row 120")
    L.CAP = cap
    -- 6000 lines fed as a game would, a hundred at a time: kept to the cap, nothing walked again
    L.reset()
    local walks = 0
    local realRefilter = L.refilter
    L.refilter = function() walks = walks + 1; return realRefilter() end
    local acc = {}
    local t0 = os.clock()
    for i = 1, 6000 do
        acc[#acc + 1] = P("bulk " .. i)
        if i % 100 == 0 then L.feedText(table.concat(acc):sub(-8192), 7000 + i) end
    end
    local took = os.clock() - t0
    L.refilter = realRefilter
    check("6000 lines: kept to the cap", select(2, L.counts()) == cap and L.shownAt(cap).msg == "bulk 6000", select(2, L.counts()))
    check("6000 lines: no row walked again while they came", walks == 0, walks)
    check("6000 lines: read fast (" .. string.format("%.2f", took) .. " s)", took < 5)
end

-- ============================================================================
-- 6. Export and Copy: what the filters show, the file named for the time
-- ============================================================================
do
    L.reset(); L.forgetMods()
    FILES = {}
    L.feedText(P("[ZeD] card: Base.Axe") .. P("Bandits: wave 3") .. BOX_ERR .. P("tail line"), 8000)
    L.toggle("mod", "ZeD-GUI")
    local name, n = L.export()
    check("export: named for the time", name == "ZeD_console_2026-11-12_143005.log", name)
    check("export: what the filters show", n == 3, n)
    local s = FILES[name] or ""
    check("export: the header says how many of how many", s:find("^ZeD%-GUI Lua console | 2026%-11%-12_143005 | 3 of 4 | errors 1") ~= nil, s:sub(1, 80))
    check("export: a hidden row left out", s:find("Base.Axe", 1, true) == nil)
    check("export: a row as time | kind | message | mod place | count", s:find("14:30:05 | error | attempted index: getHealth of non-table: null | Bandits BanditUpdate.lua:1203", 1, true) ~= nil)
    check("export: the error's stack under it, indented", s:find("\n    function: BanditUpdate.OnZombieUpdate", 1, true) ~= nil)
    check("export: Game's name on a game line", s:find("| print | tail line | Game", 1, true) ~= nil)
    local name2 = L.export()
    check("export: a second in the same second gets its own name", name2 == "ZeD_console_2026-11-12_143005_2.log" and FILES[name2] ~= nil, name2)
    CLOCK.d = "2026-11-12_143006"
    check("export: a new second, a new plain name", L.export() == "ZeD_console_2026-11-12_143006.log")
    CLOCK.d = "2026-11-12_143005"
    L.setQuery("OnZombieUpdate")
    local name4 = L.export()
    check("export: the search named in the header", (FILES[name4] or ""):find("search \"OnZombieUpdate\"", 1, true) ~= nil)
    L.setQuery("")
    L.toggle("mod", "ZeD-GUI")
    local copied = table.concat(L.rowText(findRow("getHealth")), "\n")
    check("copy one: the error and its stack", copied:find("^14:30:05 | error |") ~= nil and select(2, copied:gsub("\n", "")) == 6)
    check("copy all: every shown row", select(2, L.shownText():gsub("\n", "")) == 4 + 6 - 1)
    local realW = getFileWriter
    getFileWriter = function() error("disk full") end
    local bad, n0, tried = L.export()
    check("export that cannot write: nil and the name it tried", bad == nil and n0 == 0 and tried ~= nil)
    getFileWriter = realW
end

-- ============================================================================
-- 7. the window: the strip, the filters, the search, the stack opened in place, the band
-- ============================================================================
L.reset(); L.forgetMods()
F11.n, F11.list = 0, {}
FILES = {}
DC.close(); DC.win, DC.place = nil, nil
JC.out:SetText("")
STDOUT = {}
say("[ZeD] ready")
say("Bandits: wave 3 in 2 hours")
STDOUT[#STDOUT + 1] = BOX_ERR .. "\n"
say("tail line")
JC.visible = true
frame()
local win = DC.win
check("window: open", DC.isOpen() and win ~= nil)
nowMs = nowMs + 1000
frame()
draw(win)
check("window: drawn inside", #DRAW.outside == 0, DRAW.outside[1])
check("window: four rows in the log", L.counts() == 4, L.counts())
check("window: the strip has three pages", win._stripHits and #win._stripHits == 3)
check("window: the filter column's fold headers", textHas("KIND") or textHas("Kind"))
check("window: the count beside the search", textHas("4 of 4 | Errors: 1"))
check("window: the search's placeholder", textHas("Search the log"))
check("window: a row's kind word and time", textHas("14:30:05") and textHas("print") and textHas("error"))
check("window: the error's mod and place", textHas("Bandits | BanditUpdate.lua:1203"))
do
    local open = 0
    for _ in pairs(win.opened) do open = open + 1 end
    check("window: no error open at first", open == 0)
end
check("window: the stack not drawn while shut", not textHas("OnZombieUpdate"))
do
    local e = findRow("getHealth")
    local hit
    for _, h in ipairs(win._rowHits) do if h.row == e then hit = h end end
    check("window: the error row hit-tested", hit ~= nil)
    win:pickAt(hit.triX + 1, hit.y + 1)
    draw(win)
    check("open: a click opens its stack in place", win.opened[e.id] == e and textHas("OnZombieUpdate"))
    check("open: drawn inside", #DRAW.outside == 0, DRAW.outside[1])
    for _, h in ipairs(win._rowHits) do if h.row == e then hit = h end end
    win:pickAt(hit.triX + 1, hit.y + 1)
    draw(win)
    check("shut: the triangle again shuts it", win.opened[e.id] == nil and not textHas("OnZombieUpdate"))
    win.opened[e.id] = e
    DC.close(); JC.visible = true; frame(); win = DC.win
    local open = 0
    for _ in pairs(win.opened) do open = open + 1 end
    check("shut: every error shut again when the log opens", open == 0 and win.pick == nil)
end
-- the search field: typed words filter the log on the next draw
win.find:setText("OnZombieUpdate")
draw(win)
check("search field: the log follows it", L.q == "OnZombieUpdate" and L.counts() == 1 and textHas("1 of 4 | Errors: 1"))
win.find:setText("")
draw(win)
check("search field emptied: all back", L.counts() == 4)
-- a click on the search takes the keyboard there
win:onMouseDown(win._findRect.x + 4, win._findRect.y + 2)
check("search field: a click takes the keyboard", CORE.entry == win.find)
win.find:unfocus()
-- the filter column: a click on the Print row unticks it
do
    local printY
    for _, h in ipairs(win._fHits) do
        local it = win:_filterItems()[h.i]
        if it.t == "cb" and it.g == "kind" and it.key == "print" then printY = h.y + 2 end
    end
    check("filters: the Print row hit-tested", printY ~= nil)
    win:onMouseDown(win._filterRect.x + 20, printY)
    draw(win)
    check("filters: a click unticks Print", not L.isOn("kind", "print") and L.counts() == 1 and textHas("1 of 4"))
    win:onMouseDown(win._filterRect.x + 20, printY)
    check("filters: again ticks it", L.isOn("kind", "print") and L.counts() == 4)
    local foldY = win._fHits[1].y + 2
    win:onMouseDown(win._filterRect.x + 20, foldY)
    draw(win)
    check("filters: a click on KIND folds it", win.fold.kind == true and #win:_filterItems() < 10)
    win:onMouseDown(win._filterRect.x + 20, foldY)
    check("filters: again unfolds it", win.fold.kind == nil)
end
-- the strip: Commands and Help say they are coming; Log again
do
    win:onMouseDown(win._stripHits[2].x + 2, win._stripHits[2].y + 2)
    draw(win)
    check("strip: Commands page", win.page == "cmds" and textHas(TEXT.UI_ZeD_Console_Coming))
    check("strip: Commands drawn inside, the log's line not on it", #DRAW.outside == 0 and win._fieldRect == nil, DRAW.outside[1])
    win:onMouseDown(win._stripHits[3].x + 2, win._stripHits[3].y + 2)
    draw(win)
    check("strip: Help page", win.page == "help" and textHas(TEXT.UI_ZeD_Console_Coming))
    win:onMouseDown(win._stripHits[1].x + 2, win._stripHits[1].y + 2)
    draw(win)
    check("strip: back on the Log", win.page == "log" and textHas("4 of 4"))
end
-- the band: Export writes what is shown and says where
do
    draw(win)
    local ex
    for _, r in ipairs(win._bandRects) do if r.id == "export" then ex = r end end
    check("band: Export first", win._bandRects[1].id == "export" and win._bandRects[4].id == "run")
    win:onMouseDown(ex.x + 2, ex.y + 2); win:onMouseUp(ex.x + 2, ex.y + 2)
    draw(win)
    check("band: Export wrote the file", DC.lastExport ~= nil and FILES[DC.lastExport] ~= nil, DC.lastExport)
    check("band: says where", textHas("Saved 4 lines to Zomboid/Lua/" .. tostring(DC.lastExport)))
    win:press("clear")
    draw(win)
    check("band: Clear empties the log", L.counts() == 0 and select(2, L.counts()) == 0 and textHas(TEXT.UI_ZeD_Console_Empty))
    check("band: Export grayed with nothing shown", win._bandOff.export == true)
    check("band: the F11 list's errors stay read after Clear", L._f11Seen == F11.n)
end

-- ============================================================================
-- 8. the pad walk: strip, filters, search, log, line, band; A ticks, opens, types, presses; X exports; B closes
-- ============================================================================
do
    say("Bandits: wave 4")
    STDOUT[#STDOUT + 1] = BOX_ERR .. "\n"
    say("after the error")
    frame(); nowMs = nowMs + 1000; frame()
    local jd = { id = 0, player = 0 }
    JoypadState.players[1] = jd
    MODE = "gamepad"
    DC.close(); DC.open(0); win = DC.win
    win:update()
    check("pad: on the line at first", win.zone == "input" and jd.focus == win)
    local function glyphs()
        local g = {}
        for _, p in ipairs(win:getFooterPrompts()) do if type(p) == "table" then g[#g + 1] = p.glyph .. ":" .. p.label end end
        return table.concat(g, " ")
    end
    win:onJoypadDirLeft()
    check("pad: Left from the line to the filters", win.zone == "filters" and win.fFocus == 1)
    MARKS = 0; draw(win)
    check("pad: the KIND header marked", MARKS >= 1 and #DRAW.outside == 0)
    check("pad: prompts on a header: Fold, Export, Scratchpad, Close", glyphs() == "A:Fold X:Export Y:Scratchpad B:Close", glyphs())
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A folds KIND", win.fold.kind == true)
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A again unfolds it", win.fold.kind == nil)
    win:onJoypadDirDown()
    local it = win:_filterItems()[win.fFocus]
    check("pad: Down to the Print row", it and it.t == "cb" and it.key == "print")
    check("pad: prompts on a row: Tick", glyphs():find("A:Tick", 1, true) ~= nil, glyphs())
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A unticks Print", not L.isOn("kind", "print"))
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A ticks it again", L.isOn("kind", "print"))
    for _ = 1, 40 do win:onJoypadDirDown() end
    check("pad: Down stops at the last filter", win.fFocus == #win:_filterItems())
    draw(win)
    check("pad: the last filter brought into view, inside", #DRAW.outside == 0, DRAW.outside[1])
    win:onJoypadDirLeft()
    check("pad: Left to the strip", win.zone == "strip" and win.stripFocus == 1)
    MARKS = 0; draw(win)
    check("pad: the strip marked", MARKS >= 1)
    win:onJoypadDirDown(); win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A on Commands shows it", win.page == "cmds")
    win:onJoypadDirRight()
    check("pad: Right from the strip on Commands goes to the page", win.zone == "page")
    win:onJoypadDirLeft(); win:onJoypadDirUp(); win:onJoypadDown(Joypad.AButton, jd)
    check("pad: back to the Log", win.page == "log" and win.zone == "strip")
    win:onJoypadDirRight(); win:onJoypadDirRight()
    local n = L.counts()
    check("pad: Right, Right: the log, its newest row", win.zone == "list" and win.pick == L.shownAt(n))
    local e = findRow("getHealth")
    local steps = 0
    while win.pick ~= e and steps < 20 do win:onJoypadDirUp(); steps = steps + 1 end
    check("pad: Up to the error", win.pick == e)
    check("pad: prompts on an error: Unfold", glyphs():find("A:Unfold", 1, true) ~= nil, glyphs())
    win:onJoypadDown(Joypad.AButton, jd)
    MARKS = 0; draw(win)
    check("pad: A opens its stack", win.opened[e.id] == e and textHas("OnZombieUpdate") and MARKS >= 1)
    check("pad: prompts now Fold", glyphs():find("A:Fold", 1, true) ~= nil)
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A shuts it", win.opened[e.id] == nil)
    FILES = {}
    win:onJoypadDown(Joypad.XButton, jd)
    check("pad: X exports", DC.lastExport ~= nil and FILES[DC.lastExport] ~= nil)
    steps = 0
    while win.zone == "list" and steps < 20 do win:onJoypadDirUp(); steps = steps + 1 end
    check("pad: Up past the oldest row, the search", win.zone == "search" and win.pick == nil)
    MARKS = 0; draw(win)
    check("pad: the search marked", MARKS >= 1)
    check("pad: prompts on the search: Keyboard", glyphs():find("A:Keyboard", 1, true) ~= nil)
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A opens the pad keyboard on the search", KB.visible and KB.entry == win.find)
    win.find:setText("wave")
    KB.visible = false
    jd.focus = win
    win:update()
    draw(win)
    check("pad: typed words filter the log; the hand stays on the search", win.zone == "search" and L.q == "wave" and L.counts() == 1, L.counts())
    win.find:setText(""); draw(win)
    win:onJoypadDirDown()
    check("pad: Down from the search into the log", win.zone == "list" and win.pick ~= nil)
    steps = 0
    while win.zone == "list" and steps < 20 do win:onJoypadDirDown(); steps = steps + 1 end
    check("pad: Down past the newest, the line", win.zone == "input")
    win:onJoypadDirDown()
    check("pad: Down to the band, on Run", win.zone == "band" and win.bandFocus == 4)
    win:onJoypadDirLeft(); win:onJoypadDirLeft(); win:onJoypadDirLeft()
    check("pad: Left to Export", win.bandFocus == 1)
    FILES = {}
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A on Export presses it", DC.lastExport ~= nil and FILES[DC.lastExport] ~= nil)
    win:onJoypadDown(Joypad.BButton, jd)
    check("pad: B closes", not DC.isOpen() and jd.focus == nil)
    JoypadState.players[1] = nil
    MODE = "kbm"
end

-- ============================================================================
-- 9. the Deck, 1280 x 800 at Auto (the root clamps to 0.75), Normal and Large text, mouse and pad
-- ============================================================================
for _, prof in ipairs({ { "Deck Normal", 0.75, "small", 1280, 800 }, { "Deck Large", 0.75, "large", 1280, 800 }, { "720 Normal", 0.75, "small", 1280, 720 }, { "4K 1.75", 1.75, "small", 3840, 2160 } }) do
    ZEDQA_ROOT, ZEDQA_LARGE = prof[2], prof[3] == "large"
    ZeD.applyTheme("dark", "orange", prof[3])
    SCREEN.w, SCREEN.h = prof[4], prof[5]
    DC.close(); DC.win, DC.place = nil, nil
    JC.visible = true
    frame()
    local w2 = DC.win
    local name = prof[1]
    check(name .. ": open, on the screen", w2 and w2.x >= 0 and w2.y >= 0 and w2.x + w2.width <= SCREEN.w and w2.y + w2.height <= SCREEN.h)
    w2.opened[findRow("getHealth").id] = findRow("getHealth")
    for _, z in ipairs({ "strip", "filters", "search", "list", "input", "band" }) do
        w2.zone = z
        if z == "list" then w2.pick = nil; w2:pickStep(-1) end
        w2.joyfocus = (z ~= "input") and w2 or nil
        draw(w2)
        check(name .. " " .. z .. ": inside", #DRAW.outside == 0, DRAW.outside[1])
    end
    w2.joyfocus = nil
    check(name .. ": the list keeps rows beside the filters", w2._listRect.w > ZeD.T.px(240) and w2._listRect.h > ZeD.TM:getFontHeight(ZeD.T.fontF3) * 6, w2._listRect.w)
    check(name .. ": the search beside the count", textHas("of") and w2._findRect.w >= ZeD.T.px(80))
    w2:setWidth(w2.minimumWidth); w2:setHeight(w2.minimumHeight)
    draw(w2)
    check(name .. " smallest: inside", #DRAW.outside == 0, DRAW.outside[1])
    check(name .. " smallest: the list keeps three rows", w2._listRect.h >= ZeD.TM:getFontHeight(ZeD.T.fontF3) * 3, w2._listRect.h)
    DC.close(); DC.win, DC.place = nil, nil
end
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")
SCREEN.w, SCREEN.h = 1920, 1080

-- ============================================================================
-- 10. the prefix as 42.22.2 writes it, and the lines a scratchpad run told ahead (each skipped once in the box)
-- ============================================================================
do
    -- the shapes of DebugLog.formatLogStringForConsole: the frame alone (42.22.2), with its debug options' " t:",
    -- " st:" or " at <caller>" padded to 36 (from this build's console.txt), and 42.21's ", t:"
    local SHAPES = {
        { "LOG  : Lua          f:30> hello", "LOG", "hello" },
        { "LOG  : Lua          f:30>   two spaces kept", "LOG", "  two spaces kept" },
        { "LOG  : Lua          f:12 t:1762935182311> timed", "LOG", "timed" },
        { "LOG  : Lua          f:12 st:345> server time", "LOG", "server time" },
        { "WARN : Lua          f:0 at Lua(Vanilla).ISCampingMenu          > require(\"Camping/CCampfireSystem\") failed", "WARN", "require(\"Camping/CCampfireSystem\") failed" },
        { "WARN : Lua          f:0 at Lua(Vanilla).ISInventoryTransferUtil> require(\"x\") failed", "WARN", "require(\"x\") failed" },
        { "ERROR: General      f:0 at AngelCodeFont.parseFnt              > AngelCodeFont failed to load page 0", "ERROR", "AngelCodeFont failed to load page 0" },
        { "LOG  : General      f:4821, t:1762935182311> 42.21's shape", "LOG", "42.21's shape" },
        { "LOG  : Lua          f:30> a -> b > c", "LOG", "a -> b > c" },
        { "LOG  : Lua          f:30> ", "LOG", "" },
        { "a bare line, f:1> not a prefix", nil, "a bare line, f:1> not a prefix" },
    }
    local bad = {}
    for _, sh in ipairs(SHAPES) do
        local lvl, rest = nil, sh[1]
        if L.splitPrefix then lvl, rest = L.splitPrefix(sh[1]) end
        if lvl ~= sh[2] or rest ~= sh[3] then bad[#bad + 1] = sh[1] .. " -> " .. tostring(lvl) .. " | " .. tostring(rest) end
    end
    check("prefix: every shape the game writes taken off", L.splitPrefix ~= nil and #bad == 0, bad[1])
    -- the box in 42.22.2's shape: rows without the prefix, the warning a warning, [ZeD] ZeD-GUI's
    L.reset(); L.forgetMods()
    local P2 = function(s) return "LOG  : Lua          f:30> " .. s .. "\n" end
    L.feedText(P2("Lua: loading 3 mods") .. P2("[ZeD] ready") .. "WARN : Lua          f:31 at Lua(Vanilla).ISCampingMenu          > item not found\n", 8000)
    local r = rowsOf()
    check("42.22.2 box: three rows, the prefix off", #r == 3 and r[1].msg == "Lua: loading 3 mods" and r[3].msg == "item not found", r[1] and r[1].msg)
    check("42.22.2 box: the warning is a warning, [ZeD] is ZeD-GUI's", r[3] and r[3].kind == "warn" and r[2] and r[2].mod == "ZeD-GUI", r[2] and r[2].mod)
    -- told ahead, then printed in the box: once each, 200 prints and one print of 200 lines
    L.reset()
    local ms = 9000
    local box = {}
    for i = 1, 200 do L.output("sep " .. i, nil, ms); box[#box + 1] = P2("sep " .. i) end
    L.feedText(table.concat(box), ms + 16)
    check("200 prints told ahead: 200 rows", select(2, L.counts()) == 200, select(2, L.counts()))
    L.reset()
    local many = {}
    for i = 1, 200 do many[i] = "line " .. i end
    L.output(table.concat(many, "\n"), nil, ms)
    L.feedText("LOG  : Lua          f:30> " .. table.concat(many, "\n") .. "\n", ms + 16)
    check("one print of 200 lines told ahead: 200 rows (none past the 64th twice)", select(2, L.counts()) == 200, select(2, L.counts()))
    -- the same words from the game before the run's: each counted once, whichever came first
    L.reset()
    L.output("x", nil, ms); L.output("y", nil, ms)
    L.feedText(P2("x") .. P2("y") .. P2("x"), ms + 16)
    check("the game's x before the run's x and y: three rows for three prints", select(2, L.counts()) == 3, select(2, L.counts()))
    -- a line the box never printed waits EXPECT_MS, then a print of its words is a row of its own
    L.reset()
    L.output("late", nil, ms)
    L.tick(ms + L.EXPECT_MS)
    L.feedText(P2("late"), ms + L.EXPECT_MS + 16)
    check("told ahead, never printed: forgotten after EXPECT_MS", select(2, L.counts()) == 2, select(2, L.counts()))
    -- past EXPECT_CAP the oldest told are forgotten (the box keeps no more lines than that)
    L.reset()
    local cap = L.EXPECT_CAP
    L.EXPECT_CAP = 8
    for i = 1, 20 do L.output("c" .. i, nil, ms) end
    local cbox = {}
    for i = 1, 20 do cbox[#cbox + 1] = P2("c" .. i) end
    L.feedText(table.concat(cbox), ms + 16)
    check("past EXPECT_CAP: the last 8 told skipped, the 12 before them rows again", select(2, L.counts()) == 32, select(2, L.counts()))
    L.EXPECT_CAP = cap
    -- 4000 lines told and never printed, then 3000 box lines nobody told: each box line one lookup, nothing walked
    L.reset()
    for i = 1, 4000 do L.output("pending " .. i, nil, ms) end
    local spam = {}
    for i = 1, 3000 do spam[#spam + 1] = P2("spam " .. i) end
    local t0 = os.clock()
    L.feedText(table.concat(spam):sub(-8192), ms + 16)
    local took = os.clock() - t0
    check("4000 waiting, a full box of lines nobody told: read fast (" .. string.format("%.3f", took) .. " s)", took < 0.5)
    L.reset()
end

-- an error thrown in a mod's event handler, as 42.22 writes it to the box (QA's gallery run, Nov 13 2026): the
-- exception, the Lua dump and the debug-mode trace, then a second mod's separator, message, dump and exception. Each
-- is ONE error row; nothing of it is a print row.
do
    L.reset(); L.forgetMods()
    local E = "ERROR: General      f:570> "
    local F = "ERROR: General      f:570 at KahluaThread.flushErrorMessage      > "
    local trail = E .. "Lua((MOD:Trail Markers)).readMarker> Exception thrown\n"
        .. "\tse.krka.kahlua.vm.KahluaException: could not load marker 15: no coordinates at BaseLib.error(BaseLib.java:307).\n"
        .. "\tStack trace:\n\t\tse.krka.kahlua.stdlib.BaseLib.error(BaseLib.java:307)\n"
        .. "\t\tLua((MOD:Trail Markers)).readMarker(TrailMarkers.lua:8)\n\t\tLua((MOD:Trail Markers)).onTick(TrailMarkers.lua:16)\n"
        .. "\t\tzombie.Lua.Event.trigger(Event.java:55)\n"
        .. F .. "dumping Lua stack trace\n-----------------------------------------\nSTACK TRACE\n-----------------------------------------\n"
        .. "\tLua((MOD:Trail Markers)).readMarker(TrailMarkers.lua:8)\n\tLua((MOD:Trail Markers)).onTick(TrailMarkers.lua:16)\n"
        .. "DEBUG-MODE STACK TRACE:\n"
        .. "\tLua((MOD:Trail Markers)).readMarker(TrailMarkers.lua:8)\n\tLua((MOD:Trail Markers)).onTick(TrailMarkers.lua:16)\n"
        .. "\tse.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:1108)\n\tjava.base/java.lang.Thread.run(Unknown Source)\n"
    local stove = F .. "-------------------------------------------------------------\n"
        .. "attempted index: minutes of non-table: null\n"
        .. F .. "dumping Lua stack trace\n-----------------------------------------\nSTACK TRACE\n-----------------------------------------\n"
        .. "\tLua((MOD:Camp Stove Plus)).fuelOf(CampStove.lua:6)\n\tLua((MOD:Camp Stove Plus)).onTick(CampStove.lua:14)\n"
        .. E .. "Lua((MOD:Camp Stove Plus)).fuelOf> Exception thrown\n"
        .. "\tjava.lang.RuntimeException: attempted index: minutes of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).\n"
        .. "\tStack trace:\n\t\tse.krka.kahlua.vm.KahluaThread.tableget(KahluaThread.java:1430)\n"
    local box = ""
    local ms = 5000
    for i = 1, 3 do
        box = box .. trail .. P("[Radio Logbook] tick " .. i) .. stove .. P("Kentucky time: 13:0" .. i)
        L.feedText(box, ms); ms = ms + 4000; L.tick(ms)
    end
    local errs, prints = rowsOf("error"), rowsOf("print")
    check("event handler errors: two error rows (one per mod)", #errs == 2, #errs)
    local tr_ = findRow("could not load marker 15")
    check("Trail Markers: one row, x3, its message, at TrailMarkers.lua:8",
        tr_ and tr_.n == 3 and tr_.mod == "Trail Markers" and tr_.file == "TrailMarkers.lua" and tr_.line == 8,
        tr_ and (tr_.n .. " " .. tostring(tr_.mod) .. " " .. tostring(tr_.file) .. ":" .. tostring(tr_.line)))
    local st = findRow("minutes of non-table")
    check("Camp Stove Plus: one row, x3, at CampStove.lua:6", st and st.kind == "error" and st.n == 3 and st.file == "CampStove.lua" and st.line == 6,
        st and (st.kind .. " " .. st.n .. " " .. tostring(st.file) .. ":" .. tostring(st.line)))
    check("no 'dumping Lua stack trace' row", findRow("dumping Lua stack trace") == nil)
    check("no 'DEBUG-MODE STACK TRACE' row", findRow("DEBUG-MODE") == nil)
    local stray = 0
    for _, r in ipairs(prints) do if not (r.msg:find("Radio Logbook", 1, true) or r.msg:find("Kentucky time", 1, true)) then stray = stray + 1 end end
    check("only the mods' real prints are print rows (6)", #prints == 6 and stray == 0, #prints .. " prints, " .. stray .. " stray")
    check("the Trail Markers row keeps the whole stack", tr_ and #tr_.stack >= 10, tr_ and #tr_.stack)
    local noise = 0
    for _, r in ipairs({ tr_, st }) do
        for _, l in ipairs(r and r.stack or {}) do
            if l:find("dumping Lua stack trace", 1, true) or l:find("^%s*%-%-%-%-%-") or l:find("> %-%-%-%-%-") or l:find("STACK TRACE$") or l:find("DEBUG%-MODE") then noise = noise + 1 end
        end
    end
    check("an opened error's stack has no dividers (dump line, dashes, STACK TRACE)", noise == 0, noise)
    -- the second error right after the first, no print between (QA, Nov 13: the lone Camp Stove error): its separator
    -- ends in dashes and must not join the first error, or its message line becomes a print
    L.reset(); L.forgetMods()
    L.feedText(trail .. stove .. P("after"), 50000); L.tick(60000)
    local st2 = findRow("minutes of non-table")
    check("back to back: two error rows", #rowsOf("error") == 2, #rowsOf("error"))
    check("back to back: Camp Stove's message is its error row, not a print", st2 and st2.kind == "error" and #rowsOf("print") == 1,
        (st2 and st2.kind or "nil") .. " " .. #rowsOf("print") .. " prints")
    L.reset()
end

-- the source keeps to the Kahlua rules this sim cannot see: no next(), no non-ASCII
do
    for _, p in ipairs({ "42/media/lua/client/ZeD/ZeD_ConsoleLog.lua", "42/media/lua/client/ZeD/ZeD_DebugConsole.lua" }) do
        local f = assert(io.open(ROOT .. p, "rb")); local s = f:read("*a"); f:close()
        check(p .. ": no next()", s:find("[^%w_%.:]next%s*%(") == nil)
        check(p .. ": ASCII only", s:find("[\128-\255]") == nil)
    end
end
check("nothing logged", #LOGGED == 0, LOGGED[1])
print(string.format("console_log_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
