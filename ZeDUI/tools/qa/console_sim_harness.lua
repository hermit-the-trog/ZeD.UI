-- ZeDUI/tools/qa/console_sim_harness.lua  (Nov 12 2026): the Lua console sims' shared stage, with no game running.
-- The real Tokens, Tr, Atoms, Molecules and the console's files on Lua 5.1 stubs of a window, a text box with its
-- cursor, the game's console (as javap reads zombie.ui.UIDebugConsole on 42.22), the pad keyboard, Zomboid/Lua as a
-- table of files and the game's print landing in the console's box a frame late (the stubs console_scratch_sim
-- grew). A sim sets SIM_NAME and ROOT, then:  local H = dofile(ROOT .. "ZeDUI/tools/qa/console_sim_harness.lua")
-- and finds check, frame, draw, textHas, the stubs (JC, KB, CORE, FILES, DRAW, SCREEN, EVENTS...) on H.
-- Loading it requires ZeD_DebugConsole.lua (and through it the console's logic files).

local H = { checks = 0, failed = 0 }
local function check(name, ok, detail)
    H.checks = H.checks + 1
    if not ok then
        H.failed = H.failed + 1
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
ZeD.logOnce = function(k, e) LOGGED[#LOGGED + 1] = tostring(k) .. ": " .. tostring(e); print("FAIL logged: " .. tostring(k) .. ": " .. tostring(e)); H.failed = H.failed + 1 end
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
    if s:find("^FAIL") or s:find("^" .. SIM_NAME) then sysPrint(s); return end
    STDOUT[#STDOUT + 1] = "LOG  : Lua          f:1, t:1> " .. s .. "\n"
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



H.check, H.frame, H.draw, H.textHas = check, frame, draw, textHas
H.JC, H.KB, H.CORE, H.FILES, H.DRAW, H.SCREEN, H.EVENTS, H.STDOUT = JC, KB, CORE, FILES, DRAW, SCREEN, EVENTS, STDOUT
H.typeIn, H.enter, H.sysPrint, H.TEXT, H.SAFEDEF, H.LOGGED = typeIn, enter, sysPrint, TEXT, SAFEDEF, LOGGED
H.setShift = function(v) SHIFT = v end
H.setMode = function(m) MODE = m end
H.setClient = function(c, cap, coop) CLIENT, CAP, COOP = c, cap, coop end
H.player, H.role = PLAYER, ROLE
H.marks = function() return MARKS end
H.resetMarks = function() MARKS = 0 end
H.clip = function() return CLIP end
H.onScreenWhileOpen = function() return onScreenWhileOpen end
return H
