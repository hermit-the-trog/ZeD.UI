-- ZeDUI/tools/qa/console_scratch_sim.lua  (Nov 12 2026, punch list 136 Phase 2): the Lua console's scratchpad with no
-- game running. The harness is debug_console_sim's (the real Tokens, Tr, Atoms, Molecules, ZeD_ConsoleLog and
-- ZeD_DebugConsole on Lua 5.1 stubs of a window, a text box and the game's console), with the game's multi-line box
-- as javap reads UITextBox2 on 42.22 (Enter puts a newline in at the cursor and never calls onCommandEntered;
-- setCursorPos clamps to the cursor line's length while on many lines; Up and Down always call onPressUp / Down),
-- Zomboid/Lua as a table of files, and the game's print landing in the console's box a frame late. It checks:
--   * the swap: the Scratchpad keycap puts the box in place of the line (the line's words come along), One line back
--   * a run of many lines, past 256 characters, through loadstring: a "ran" row, its output from Console under it,
--     the box's late copy of that output skipped (the box writes 42.22.2's prefix; 200 prints and one print of 200
--     lines alike, each line once); Enter runs, Shift+Enter makes a new line
--   * a big box (1500 lines): a steady frame makes no pass over its text and no copy of it, a keystroke reads only
--     near the cursor; S.lines, S.lineCount and the cursor's line and column as the old patterns gave them; a click
--     in a box with \r\n endings
--   * a line that does not compile and a run that fails: an error row from Console with the message given
--   * the history: Up on the first line and Down on the last step through runs, the draft comes back; the cap of 200
--     runs (oldest dropped), no run twice in a row; the file written and read back
--   * snippets: Save snippet asks for a name in the band (its first line offered), a click loads one, a right-click
--     renames it (a name in use refused), the same name saves over; lines starting "==" or a backslash survive the
--     disk; the file read back
--   * no loadstring: the notice, Run grayed, Enter and Run do not run, the lists still there
--   * the controller: Y swaps, A types on the pad keyboard (landing on Run after), the column (fold, load, X renames),
--     X saves through the name band (A types the name, lands on Save), B cancels the band, LB / RB step the runs
--   * every frame drawn inside the window at 720 / Deck / 1080p / 4K, Normal and Large text, mouse and pad
-- What it cannot prove: the engine (Kahlua's loadstring and its error words, the real box's keys, font widths).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/console_scratch_sim.lua
-- It prints FAIL lines and a last line "console_scratch_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]console_scratch_sim%.lua$", "")

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
-- (a print reaches the box as 42.22.2 writes it, DebugLog.formatLogStringForConsole: "LOG  : Lua          f:<frame>> ";
-- 42.21 wrote ", t:<ms>" after the frame, and this stub in that shape hid the scratchpad's doubled lines)
local PREFIX = "LOG  : Lua          f:1> "
function say(s) STDOUT[#STDOUT + 1] = PREFIX .. tostring(s) .. "\n" end

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

-- THE SCRATCHPAD'S PARTS -------------------------------------------------------------------
-- the game's text box with its cursor (UITextBox2): on many lines, setCursorPos clamps to the cursor line's length
local newEntry = ISTextEntryBox.new
function ISTextEntryBox:new(text, x, y, w, h)
    local o = newEntry(self, text, x, y, w, h)
    local box = o
    local j = { cur = #(text or ""), line = 0 }
    function j.setCentreVertically() end
    function j.setWrapLines() end
    function j.setMultipleLine(_, b) box.multi = b end
    function j.getCursorPos(self2) return self2.cur end
    function j.setCursorLine(self2, n) self2.line = n end
    function j.setCursorPos(self2, p)
        local t = box.text or ""
        if box.multi then
            local lines = {}
            for l in (t .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
            p = math.max(0, math.min(#(lines[self2.line + 1] or ""), p))
        else
            p = math.max(0, math.min(#t, p))
        end
        self2.cur = p
    end
    o.javaObject = j
    return o
end
function ISTextEntryBox:setText(s) self.text = s; self.javaObject.cur = #s end
function ISTextEntryBox:setMultipleLine(b) self.multi = b end
function ISTextEntryBox:isMultipleLine() return self.multi == true end
function ISTextEntryBox:setMaxLines(n) self.maxL = n end
local SHIFT = false
function isShiftKeyDown() return SHIFT end
-- typing into a box at its cursor; Enter on many lines is a newline there (the game's onKeyEnter)
local function typeIn(e, s)
    local j = e.javaObject
    e.text = e.text:sub(1, j.cur) .. s .. e.text:sub(j.cur + 1)
    j.cur = j.cur + #s
end
local function enter(e) typeIn(e, "\n") end

-- Zomboid/Lua, as a table of files
local FILES = {}
function getFileWriter(name, create, append)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end,
             close = function() FILES[name] = (append and FILES[name] or "") .. table.concat(buf) end }
end
function getFileReader(name, create)
    local s = FILES[name]
    if s == nil then return nil end
    local lines = {}
    for l in (s:sub(-1) == "\n" and s or s .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
    local i = 0
    return { readLine = function() i = i + 1; return lines[i] end, close = function() end }
end

-- the game's print: into the console's buffer (the box a frame later); the sim's own FAIL lines to the terminal
local sysPrint = print
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    local s = table.concat(parts, "\t")
    if s:find("^FAIL") or s:find("^console_scratch_sim") then sysPrint(s); return end
    STDOUT[#STDOUT + 1] = PREFIX .. s .. "\n"
end
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


local S = ZeD.ConsoleScratch
local L = ZeD.ConsoleLog
check("the scratchpad's file loads", S ~= nil and type(S.run) == "function" and type(L.ranCode) == "function" and type(L.output) == "function")

-- the rows of the log, oldest first, and the last row of a kind
local function rows()
    local out = {}
    for i = L.first, L.last do out[#out + 1] = L.rows[i] end
    return out
end
local function lastOf(kind)
    local rs = rows()
    for i = #rs, 1, -1 do if rs[i].kind == kind then return rs[i], i end end
    return nil
end
local function countMsg(msg)
    local n = 0
    for _, r in ipairs(rows()) do if r.msg == msg then n = n + 1 end end
    return n
end

-- ============================================================================
-- 1. open, swap the line for the box and back
-- ============================================================================
FILES["ZeD_console_history.txt"] = "# head\n==\nprint('from disk')\n"
JC.visible = true
frame()
local win = DC.win
check("open", DC.isOpen() and win ~= nil)
check("the history read from disk on open", S.history[#S.history] == "print('from disk')", S.history[#S.history])
check("starts on the line", win.mode == "line")
draw(win)
check("the line has the Scratchpad keycap", textHas("Scratchpad"))
check("drawn inside (line)", #DRAW.outside == 0, DRAW.outside[1])
win.input:setText("print('carried')")
win.input:focus()
win:press("topad")
check("swap: the box in place of the line", win.mode == "pad")
check("swap: the line's words come along", win:padText() == "print('carried')" and win.input:getText() == "")
check("swap: the keys go to the box", CORE.entry == win.pad)
draw(win)
check("pad: drawn inside", #DRAW.outside == 0, DRAW.outside[1])
check("pad: the box and the column laid out", win._padRect ~= nil and win._sideRect ~= nil and win._fieldRect == nil)
check("pad: the meta line and its keycaps", textHas("Lines: 1 | Characters: 16") and textHas("Save snippet") and textHas("One line"))
check("pad: line numbers in the gutter", textHas("1") and textHas("2"))
win:press("toline")
check("one line: back", win.mode == "line" and win.input:getText() == "print('carried')" and CORE.entry == win.input)
win.input:setText("")
win:press("topad")
check("swap again: the box keeps its words", win:padText() == "print('carried')")
win:_padSet("a\nb")
win:press("toline")
check("one line: a box of many lines stays in the box", win.input:getText() == "" and win:padText() == "a\nb")
win:press("topad")

-- ============================================================================
-- 2. a run of many lines: Enter runs, Shift+Enter makes a new line; the output under the ran row, once
-- ============================================================================
win.pad:focus()
local code = "local n = 0\nfor i = 1, 3 do n = n + i end\nprint('total', n)"
win:_padSet(code)
draw(win)
SHIFT = true
enter(win.pad)
draw(win)
check("Shift+Enter: a new line, nothing run", win:padText() == code .. "\n" and lastOf("ran") == nil)
SHIFT = false
win:_padSet(code)
draw(win)
enter(win.pad)
draw(win)
local ran, ri = lastOf("ran")
check("Enter: the box ran and emptied", win:padText() == "" and ran ~= nil)
check("ran row: its first line and the lines more", ran and ran.msg == "> local n = 0  (+2 lines)" and ran.mod == L.CONSOLE, ran and ran.msg)
local out, oi = lastOf("print")
check("output: a print row from Console under the ran row", out and out.msg == "total    6" and out.mod == L.CONSOLE and oi > ri, out and out.msg)
check("the run on the history", S.history[#S.history] == code)
check("the history file written", (FILES["ZeD_console_history.txt"] or ""):find("for i = 1, 3 do n = n + i end", 1, true) ~= nil)
frame(); frame()
check("the box's late copy of the output skipped", countMsg("total    6") == 1, countMsg("total    6"))
STDOUT[#STDOUT + 1] = PREFIX .. "total\t6\n"
frame()
check("a second print of the same words (not the run's) is a row", countMsg("total    6") == 2, countMsg("total    6"))
-- every line a run prints is one row, however many: 200 prints, and one print of 200 lines (the box's copies
-- skipped past the 64th line too, and the game's prefix off each of them)
local function countHas(part)
    local n = 0
    for _, r in ipairs(rows()) do if r.kind == "print" and r.msg:find(part, 1, true) then n = n + 1 end end
    return n
end
S.run("for i = 1, 200 do print('sep row ' .. i) end")
frame(); frame()
check("200 prints: 200 rows, the box's copies skipped", countHas("sep row ") == 200, countHas("sep row "))
check("200 prints: no row keeps the game's prefix", countHas("f:1>") == 0, countHas("f:1>"))
do
    local many = {}
    for i = 1, 200 do many[i] = "one print line " .. i end
    S.run("print(" .. string.format("%q", table.concat(many, "\n")) .. ")")
end
frame(); frame()
check("one print of 200 lines: 200 rows", countHas("one print line ") == 200, countHas("one print line "))
-- past the game's 256
local long = "local s = '" .. string.rep("x", 400) .. "'\nprint(#s)"
check("the long run is past 256 characters", #long > 256)
win:_padSet(long)
win:press("run")
out = lastOf("print")
check("Run: past 256 characters runs whole", out and out.msg == "400" and win:padText() == "", out and out.msg)
-- the band: Run grayed with an empty box
draw(win)
check("Run grayed on an empty box", win._bandOff.run == true)
win:_padSet("print(1)")
draw(win)
check("Run live with words in the box", win._bandOff.run == false)

-- ============================================================================
-- 3. errors: a line that does not compile, a run that fails
-- ============================================================================
win:_padSet("for i = 1, 3 do\nprint(i)")
win:press("run")
local er = lastOf("error")
check("compile error: an error row", er ~= nil)
check("compile error: from Console, its line", er and er.mod == L.CONSOLE and er.file == "console" and er.line == 2, er and (tostring(er.mod) .. " " .. tostring(er.file) .. ":" .. tostring(er.line)))
check("compile error: loadstring's message", er and er.msg:find("'end' expected", 1, true) ~= nil, er and er.msg)
check("compile error: nothing printed", lastOf("print").msg == "400")
win:_padSet("local x = nil\nreturn x.y")
win:press("run")
er = lastOf("error")
check("runtime error: an error row from Console with pcall's message", er and er.mod == L.CONSOLE and er.msg:find("attempt to index", 1, true) ~= nil, er and er.msg)
check("runtime error: print given back", print ~= nil and S.run("print('after')") == "ran" and lastOf("print").msg == "after")

-- ============================================================================
-- 4. the history: Up on the first line, Down on the last; the cap; the disk
-- ============================================================================
local h = S.history
local n0 = #h
win:_padSet("draft\nline two", 2)
draw(win)
win.pad.onPressUp()
check("Up on the first line: the newest run", win.phi == n0 and win:padText() == h[n0] and win.pad.javaObject.cur == 0)
draw(win)
win.pad.onPressUp()
check("Up again: the one before", win.phi == n0 - 1 and win:padText() == h[n0 - 1])
local t = win:padText()
win:_padSet(t, #t)
draw(win)
win.pad.onPressDown()
check("Down on the last line: newer", win.phi == n0 and win:padText() == h[n0])
t = win:padText(); win:_padSet(t, #t); draw(win)
win.pad.onPressDown()
check("Down past the newest: the draft back", win.phi == nil and win:padText() == "draft\nline two")
win:_padSet("draft\nline two", 8)
draw(win)
win.pad.onPressUp()
check("Up on the second line: the cursor moves, no history step", win.phi == nil and win:padText() == "draft\nline two")
win:_padSet("one\ntwo", 1)
draw(win)
win.pad.onPressDown()
check("Down on the first of two lines: no history step", win.phi == nil and win:padText() == "one\ntwo")
-- the cap
S.history = {}
for i = 1, 205 do S.addHistory("print(" .. i .. ")") end
check("cap: 200 runs kept", #S.history == 200, #S.history)
check("cap: the oldest went first", S.history[1] == "print(6)" and S.history[200] == "print(205)")
S.addHistory("print(205)")
check("cap: not twice in a row", #S.history == 200 and S.history[199] == "print(204)")
S.addHistory("print(205)  ")
check("cap: trailing blanks are the same run", S.history[199] == "print(204)")
S.load(true)
check("disk: the 200 runs read back", #S.history == 200 and S.history[1] == "print(6)" and S.history[200] == "print(205)")
S.addHistory("a = 1\n== not a block\n\\ backslash")
S.load(true)
check("disk: a run with '==' and backslash lines read back whole", S.history[#S.history] == "a = 1\n== not a block\n\\ backslash", S.history[#S.history])
check("disk: still 200", #S.history == 200)

-- ============================================================================
-- 5. snippets: save (the band asks), load, rename, save over, the disk
-- ============================================================================
check("no snippets yet", #S.snippets == 0)
local snip = "-- where am I\nprint(getPlayer())"
win:_padSet(snip)
win:press("save")
check("Save snippet: the band asks for a name, the first line offered", win.naming and win.naming.kind == "save" and win.nameE:getText() == "-- where am I")
check("Save snippet: the name field holds the keys", CORE.entry == win.nameE)
draw(win)
check("name band: drawn inside", #DRAW.outside == 0, DRAW.outside[1])
check("name band: the name shown, Save there", textHas("-- where am I") and textHas("Save"))
win.nameE:setText("")
win.nameE:unfocus()
draw(win)
check("name band: an empty name shows the field's words", textHas("Snippet name"))
win.nameE:focus()
win:press("nsave")
check("name band: no name, nothing saved", #S.snippets == 0 and win.naming ~= nil)
win.nameE:setText("Where am I")
win.nameE.onCommandEntered()
check("Enter in the name: saved", #S.snippets == 1 and S.snippets[1].name == "Where am I" and S.snippets[1].code == snip)
check("saved: the band says where", win._status and win._status.text:find("Where am I", 1, true) and win._status.text:find("ZeD_console_snippets.txt", 1, true))
check("saved: the band back", win.naming == nil)
check("saved: the file written", (FILES["ZeD_console_snippets.txt"] or ""):find("== Where am I\n-- where am I\nprint(getPlayer())", 1, true) ~= nil)
win:_padSet("== a header-looking line\n\\ and a backslash")
win:press("save")
win.nameE:setText("Tricky")
win:press("nsave")
win:_padSet("print(2)")
win:press("save")
win.nameE.onOtherKey(win.nameE, Keyboard.KEY_ESCAPE)
check("Escape in the name: nothing saved, the band back", #S.snippets == 2 and win.naming == nil)
-- the column: a click loads, a right-click renames
draw(win)
local function sideHit(kind, idx)
    local items = win:_sideItems()
    for _, hit in ipairs(win._sHits or {}) do
        local it = items[hit.i]
        if it.t == kind and it.i == idx then return hit end
    end
    return nil
end
local sr = win._sideRect
local hit = sideHit("snip", 1)
check("the column shows the snippet", hit ~= nil and textHas("Where am I"))
win:_padSet("")
win:onMouseDown(sr.x + 10, hit.y + 2)
check("click a snippet: loaded into the box", win:padText() == snip)
win:onRightMouseDown(sr.x + 10, hit.y + 2)
check("right-click a snippet: the band asks a new name", win.naming and win.naming.kind == "rename" and win.nameE:getText() == "Where am I")
win.nameE:setText("Tricky")
win:press("nsave")
check("rename: a name in use refused, still asking", S.snippets[1].name == "Where am I" and win.naming ~= nil)
win.nameE:setText("Here")
win:press("nsave")
check("rename: renamed, written", S.snippets[1].name == "Here" and win.naming == nil and FILES["ZeD_console_snippets.txt"]:find("== Here\n", 1, true) ~= nil)
win:_padSet("print('newer')")
win:press("save")
win.nameE:setText("Here")
win:press("nsave")
check("the same name: saved over", #S.snippets == 2 and S.snippets[1].code == "print('newer')")
local before = { S.snippets[1].name, S.snippets[1].code, S.snippets[2].name, S.snippets[2].code }
S.load(true)
check("disk: the snippets read back", #S.snippets == 2 and S.snippets[1].name == before[1] and S.snippets[1].code == before[2]
    and S.snippets[2].name == before[3] and S.snippets[2].code == before[4], S.snippets[2] and S.snippets[2].code)
draw(win)
hit = sideHit("hist", #S.history)
check("the column shows the newest run", hit ~= nil)
win:onMouseDown(sr.x + 10, hit.y + 2)
check("click a run: loaded, marked as the one shown", win:padText() == S.history[#S.history] and win.phi == #S.history)
-- a fold header folds
local items = win:_sideItems()
check("the column: SNIPPETS first, HISTORY after its rows", items[1].t == "fold" and items[1].g == "snips" and items[4].t == "fold" and items[4].g == "hist")
win:useSide(items[1])
check("fold: SNIPPETS shut", win:_sideItems()[2].t == "fold")
win:useSide(win:_sideItems()[1])

-- ============================================================================
-- 6. no loadstring: the notice, Run grayed, nothing runs, the lists stay
-- ============================================================================
local LS = loadstring
loadstring = nil
check("no loadstring: can't run", not S.canRun())
win:_padSet("print('nope')")
draw(win)
check("no loadstring: the notice", textHas("No loadstring in this build of the game."))
check("no loadstring: drawn inside", #DRAW.outside == 0, DRAW.outside[1])
check("no loadstring: Run grayed", win._bandOff.run == true)
check("no loadstring: the help line says so", win:getStatusLine():find("can't run without loadstring", 1, true) ~= nil)
local last = L.last
win:press("run")
check("no loadstring: Run does nothing", L.last == last and win:padText() == "print('nope')")
win.pad:focus()
draw(win)
enter(win.pad)
draw(win)
check("no loadstring: Enter does not run, the words stay", L.last == last and win:padText() == "print('nope')")
check("no loadstring: the band says why", win._status and win._status.text:find("loadstring", 1, true) ~= nil)
check("no loadstring: S.run says so", S.run("print(1)") == "noload")
check("no loadstring: the lists stay", #win:_sideItems() > 2)
win:press("toline")
check("no loadstring: One line still works", win.mode == "line")
win:press("topad")
loadstring = LS
draw(win)
check("loadstring back: no notice", not textHas("No loadstring in this build of the game."))

-- ============================================================================
-- 7. the controller
-- ============================================================================
DC.close()
local jd = { id = 0, player = 0 }
JoypadState.players[1] = jd
MODE = "gamepad"
DC.open(0)
win = DC.win
win:update()
win:setMode("line")
win.zone = "input"
local function glyphs()
    local g = {}
    for _, p in ipairs(win:getFooterPrompts()) do if type(p) == "table" then g[#g + 1] = p.glyph .. ":" .. p.label end end
    return table.concat(g, " ")
end
check("pad: Y on the line says Scratchpad", glyphs():find("Y:Scratchpad", 1, true) ~= nil, glyphs())
win:onJoypadDown(Joypad.YButton, jd)
check("pad: Y swaps to the box", win.mode == "pad")
check("pad prompts on the box: A LB RB X Y B", glyphs() == "A:Keyboard LB:Older RB:Newer X:Save snippet Y:One line B:Close", glyphs())
MARKS = 0
draw(win)
check("pad: the box marked, drawn inside", MARKS >= 1 and #DRAW.outside == 0, DRAW.outside[1])
win:_padSet("")
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A opens the pad keyboard on the box", KB.visible and KB.entry == win.pad)
win.pad:setText("print('pad')\nprint('two')")
win:_padKeys()
check("pad: the keyboard's newline is not Enter", win:padText() == "print('pad')\nprint('two')")
KB.visible = false
jd.focus = win
win:update()
check("pad: after typing, on Run", win.zone == "band" and win.bandFocus == 4)
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A on Run runs the box", lastOf("ran").msg == "> print('pad')  (+1 lines)" and win:padText() == "")
win:onJoypadDirUp()
check("pad: Up to the box", win.zone == "input")
win:onJoypadDown(Joypad.LBumper, jd)
check("pad: LB, the run before", win:padText() == "print('pad')\nprint('two')")
win:onJoypadDown(Joypad.RBumper, jd)
check("pad: RB, back to what was typed", win:padText() == "")
win:onJoypadDirRight()
check("pad: Right to the column", win.zone == "side" and win.sFocus >= 1)
win.sFocus = 1
draw(win)
check("pad: the column's row marked", #DRAW.outside == 0)
check("pad prompts on a fold header: A Fold", glyphs():find("A:Fold", 1, true) ~= nil, glyphs())
win:onJoypadDirDown()
check("pad: Down to a snippet", win:_sideItems()[win.sFocus].t == "snip")
check("pad prompts on a snippet: A Load, X Rename", glyphs():find("A:Load", 1, true) and glyphs():find("X:Rename", 1, true), glyphs())
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A loads the snippet", win:padText() == S.snippets[1].code)
win:onJoypadDown(Joypad.XButton, jd)
check("pad: X on a snippet renames, in the band", win.naming and win.naming.kind == "rename" and win.zone == "band" and win.bandFocus == 1)
check("pad prompts on the name: A Keyboard, B Cancel", glyphs():find("A:Keyboard", 1, true) and glyphs():find("B:Cancel", 1, true), glyphs())
win:onJoypadDown(Joypad.BButton, jd)
check("pad: B cancels the band, the window stays", win.naming == nil and DC.isOpen())
win.zone = "input"
win:_padSet("print('saved by pad')")
win:onJoypadDown(Joypad.XButton, jd)
check("pad: X saves through the band, on its name", win.naming and win.naming.kind == "save" and win.zone == "band" and win.bandFocus == 1)
win:onJoypadDirRight(); win:onJoypadDirRight(); win:onJoypadDirRight()
check("pad: the name band stops at Save", win.bandFocus == 3)
win:onJoypadDirLeft(); win:onJoypadDirLeft()
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A on the name opens the keyboard on it", KB.visible and KB.entry == win.nameE)
win.nameE:setText("Pad one")
KB.visible = false
jd.focus = win
win:update()
check("pad: after the name, on Save", win.zone == "band" and win.bandFocus == 3)
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A on Save saves", S.snippets[#S.snippets].name == "Pad one" and win.naming == nil and win.bandFocus == 4)
win.zone, win.sFocus = "side", #win:_sideItems()
win:onJoypadDirDown()
check("pad: Down past the column's last row, the band", win.zone == "band")
win:onJoypadDirUp()
win:onJoypadDirRight()
win:onJoypadDirLeft()
check("pad: Left from the column, the box", win.zone == "input")
win:onJoypadDown(Joypad.YButton, jd)
check("pad: Y back to the line", win.mode == "line")
win:onJoypadDown(Joypad.YButton, jd)
DC.close()
JoypadState.players[1] = nil
MODE = "kbm"

-- ============================================================================
-- 8. every size, both text sizes, mouse and pad, the box with a long run loaded, and with no loadstring
-- ============================================================================
local PROFILES = {
    { name = "720p Normal", root = 1, size = "small", w = 1280, h = 720 },
    { name = "Deck Large", root = 1, size = "large", w = 1280, h = 800 },
    { name = "1080p Normal", root = 1, size = "small", w = 1920, h = 1080 },
    { name = "4K 1.75 Normal", root = 1.75, size = "small", w = 3840, h = 2160 },
    { name = "4K 2 Large", root = 2, size = "large", w = 3840, h = 2160 },
}
for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    SCREEN.w, SCREEN.h = prof.w, prof.h
    DC.close()
    DC.win, DC.place = nil, nil
    for _, pad in ipairs({ false, true }) do
        for _, noload in ipairs({ false, true }) do
            MODE = pad and "gamepad" or "kbm"
            local jd2 = pad and { id = 0, player = 0 } or nil
            JoypadState.players[1] = jd2
            JC.visible = true
            frame()
            if pad then DC.close(); DC.open(0) end
            local w2 = DC.win
            local name = prof.name .. (pad and " pad" or " mouse") .. (noload and " no loadstring" or "")
            if w2 then
                w2:update()
                w2:setMode("pad")
                w2:_padSet(long .. "\n" .. string.rep("print(1)\n", 30))
                if noload then loadstring = nil end
                for _, size in ipairs({ { w2.width, w2.height }, { ZeD.T.px(520), ZeD.T.px(260) } }) do
                    w2:setWidth(size[1]); w2:setHeight(size[2])
                    draw(w2)
                    check(name .. " " .. size[1] .. "x" .. size[2] .. ": drawn inside", #DRAW.outside == 0, DRAW.outside[1])
                    local pr, br = w2._padRect, w2._sideRect
                    check(name .. ": the box and the column side by side", pr and br and pr.x + pr.w <= br.x and pr.h > 0)
                end
                w2.naming = nil
                w2:_padSet("print(1)")
                w2:press("save")
                draw(w2)
                check(name .. ": the name band drawn inside", #DRAW.outside == 0, DRAW.outside[1])
                w2:nameDone(false)
                loadstring = LS
                w2:setMode("line")
            end
            DC.close()
        end
    end
end
JoypadState.players[1] = nil

-- ============================================================================
-- 9. a big box (1500 lines, 39 KB, the cursor at its end): a frame works nothing out again over the whole text, a
--    keystroke reads only near the cursor, and what the box draws and where its cursor stands are as before
-- ============================================================================
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")
SCREEN.w, SCREEN.h = 1920, 1080
DC.close()
DC.win, DC.place = nil, nil
MODE = "kbm"
JC.visible = true
frame()
win = DC.win
win:setMode("pad")
win.pad:focus()
local TEMPLATES = { "local inv = getPlayer():getInventory()", "local items = inv:getItems()", "for i = 0, items:size() - 1 do",
    "    local it = items:get(i)", "    if it:getType() == \"Axe\" then", "        print(it:getName(), it:getCondition())", "    end",
    "end", "-- the bag's weight, then the player's", "local w = inv:getCapacityWeight()", "print(w)", "x = x + 1" }
local bigLines = {}
for i = 1, 1500 do bigLines[i] = TEMPLATES[(i - 1) % #TEMPLATES + 1] end
local bigText = table.concat(bigLines, "\n") .. "\nlocal p = getPl"
check("the big box: 39 KB", #bigText > 38000, #bigText)
-- what touches a text of 10000 characters or more: a pattern pass over it (a find that ran past the 10000th character,
-- any match, gmatch or gsub), a copy that long, and how many string.sub calls in all; plain finds are the game's
-- indexOf and stay free
local BIG = 10000
local W9 = { on = false, big = 0, bigSub = 0, subs = 0, what = {} }
local real = { find = string.find, match = string.match, gmatch = string.gmatch, gsub = string.gsub, sub = string.sub }
local function seen(name, p) W9.big = W9.big + 1; W9.what[#W9.what + 1] = name .. " " .. tostring(p) end
string.find = function(s, p, init, plain)
    local r = { real.find(s, p, init, plain) }
    if W9.on and type(s) == "string" and #s >= BIG and not plain and (r[1] == nil or r[1] >= BIG) then seen("find", p) end
    return unpack(r)
end
string.match = function(s, p, ...)
    if W9.on and type(s) == "string" and #s >= BIG then seen("match", p) end
    return real.match(s, p, ...)
end
string.gmatch = function(s, p)
    if W9.on and type(s) == "string" and #s >= BIG then seen("gmatch", p) end
    return real.gmatch(s, p)
end
string.gsub = function(s, p, ...)
    if W9.on and type(s) == "string" and #s >= BIG then seen("gsub", p) end
    return real.gsub(s, p, ...)
end
string.sub = function(s, i, j)
    local r = real.sub(s, i, j)
    if W9.on then
        W9.subs = W9.subs + 1
        if #r >= BIG then W9.bigSub = W9.bigSub + 1 end
    end
    return r
end
local function watch(fn)
    W9.big, W9.bigSub, W9.subs, W9.what = 0, 0, 0, {}
    W9.on = true
    fn()
    W9.on = false
end
win:_padSet(bigText)
draw(win)
draw(win)
watch(function() draw(win) end)
check("big box, a steady frame: no pass over the whole text", W9.big == 0, table.concat(W9.what, ", "))
check("big box, a steady frame: no copy of it", W9.bigSub == 0, W9.bigSub)
check("big box, a steady frame: a few dozen substrings at most (the rows shown)", W9.subs <= 200, W9.subs)
check("big box: the meta line counts its lines", textHas("Lines: 1501 | Characters: " .. #bigText))
check("big box: the last line drawn, its caret on it", textHas("local p = getPl") and win._caret ~= nil)
check("big box: the suggestions follow it", win.ac ~= nil and win.ac.items[1].n == "getPlayer", win.ac and win.ac.items[1].n)
typeIn(win.pad, "a")
watch(function() draw(win) end)
check("big box, a keystroke: no pattern pass over the whole text", W9.big == 0, table.concat(W9.what, ", "))
check("big box, a keystroke: the string scan jumps (not a string.sub per character)", W9.subs < 1000, W9.subs)
check("big box, a keystroke: the box took it", win:padText() == bigText .. "a")
if os.getenv("ZEDQA_VERBOSE") then sysPrint("  big box keystroke: " .. W9.subs .. " string.sub calls, " .. W9.big .. " whole-text passes") end
-- a click on the second line of a text with \r\n endings: the cursor there, at the column clicked (the \r not drawn)
win:_padSet("ab\r\ncd\r\nef", 0)
draw(win)
check("\\r\\n: the rows drawn without the \\r", textHas("cd") and not textHas("cd\r"))
local st = win._padSt
win:padClick(st.tx + st.cw * 1 + 1, st.ty + st.lh + 1)
check("\\r\\n: a click on line 2, column 1, puts the cursor after its c", win._padCur == 5, win._padCur)
string.find, string.match, string.gmatch, string.gsub, string.sub = real.find, real.match, real.gmatch, real.gsub, real.sub

-- the walks that took the place of the patterns give what the patterns gave (copies of the old ones, on random texts)
local function oldLines(text)
    local out = {}
    for l in (tostring(text or ""):gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do out[#out + 1] = l end
    return out
end
local function oldLineCount(text)
    local n = 1
    for _ in tostring(text or ""):gmatch("\n") do n = n + 1 end
    return n
end
local function oldLineCol(text, cur)
    local before = text:sub(1, cur)
    local line = 0
    for _ in before:gmatch("\n") do line = line + 1 end
    local col = #(before:match("([^\n]*)$") or "")
    return line, col
end
math.randomseed(1112)
local ALPHA = { "a", "b", " ", "\n", "\n", "\r", "x" }
local bad = {}
for _ = 1, 400 do
    local parts = {}
    for k = 1, math.random(0, 14) do parts[k] = ALPHA[math.random(#ALPHA)] end
    local t = table.concat(parts)
    local a, b = oldLines(t), S.lines(t)
    if table.concat(a, "|") .. #a ~= table.concat(b, "|") .. #b then bad[#bad + 1] = "lines " .. string.format("%q", t) end
    if oldLineCount(t) ~= S.lineCount(t) then bad[#bad + 1] = "count " .. string.format("%q", t) end
    for cur = 0, #t do
        local l1, c1 = oldLineCol(t, cur)
        local l2, c2 = DC.lineCol(t, cur)
        if l1 ~= l2 or c1 ~= c2 then bad[#bad + 1] = "lineCol " .. string.format("%q", t) .. " " .. cur end
    end
end
check("S.lines, S.lineCount and the cursor's line and column: as the patterns gave", #bad == 0, bad[1])
DC.close()

sysPrint("console_scratch_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
