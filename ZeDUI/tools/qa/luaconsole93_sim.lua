-- ZeDUI/tools/qa/luaconsole93_sim.lua: Lua Console 93 Professional Edition with no game running.
-- The mod as ZeDUI/tools/products/build_luaconsole93.py writes it (products/LuaConsole93): every one of its Lua files
-- loaded on Lua 5.1 stubs of the game. The stubs are the console sims' (console_sim_harness.lua: the game's console as
-- javap reads zombie.ui.UIDebugConsole on 42.22, a text box with a cursor, Zomboid/Lua as a table of files, the game's
-- print landing in the console's box a frame late), grown to carry the mod's own window class (ISUIElement's children,
-- the Java element's controls) and the game's parts the mod uses in place of ZeD-GUI's: the on-screen keyboard, the
-- chat box and the Back button wheel. It checks:
--   * with ZeD-GUI on (mod ZeD_UI, and "\ZeD_UI" as the game can hand an id over) every file stops at its guard: no
--     global made, no event hooked, nothing of the game's touched, and the one log line says so
--   * on the plain game: the files load in the game's order and make LC93 and no ZeD; the palette is Dark with the
--     PZ Teal accent in the game's own fonts (the fixed-pitch role on the game's code face); the window opens with the
--     game's console and draws inside itself at 1080p, 4K and the Steam Deck's size; and the key checks of the
--     console's own sims hold: the log (rows, mods, an error's place, a repeat counted, filters, search, export), the
--     scratchpad (runs, snippets and history on disk), the suggestions, the commands (the help words, sending a chat
--     channel through the game's chat), the pad keyboard and the controller's slice on the Back button wheel
--   * no file under 42/media sits at a path ZeD-GUI ships (the Translate files merge by key), no translation key is
--     ZeD-GUI's, every key the code uses has its English, and no ZeD name survives in the code
-- What it cannot prove: the engine (real fonts, the text box's own keys, what the game prints), the order the game
-- loads files in, a Workshop install.
-- Run from the repo root (build the mod first):  lua51 ZeDUI/tools/qa/luaconsole93_sim.lua
-- It prints FAIL lines and a last line "luaconsole93_sim: N checks, M failed", and exits 1 if any failed.

SIM_NAME = "luaconsole93_sim"
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]luaconsole93_sim%.lua$", "")
local PRODUCT = ROOT .. "products/LuaConsole93/"
local LUA_DIR = PRODUCT .. "42/media/lua/client/LuaConsole93/"
local TAG = "[Lua Console 93] "

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local sysPrint = print

-- ---------------------------------------------------------------------------------------------------------------------
-- FILES: reading them, and listing a folder (cmd's dir: the sims run on Windows)
-- ---------------------------------------------------------------------------------------------------------------------
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end
local CWD
do
    local p = io.popen("cd")
    CWD = p and p:read("*l") or ""
    if p then p:close() end
end
local function absolute(path)
    local w = path:gsub("/", "\\")
    if w:match("^%a:") then return w end
    return CWD .. "\\" .. w
end
--- Every file under dir (recursive), as paths relative to it with "/".
local function listFiles(dir)
    local abs = absolute(dir):gsub("\\+$", "")
    local out = {}
    local p = io.popen('dir /s /b /a-d "' .. abs .. '" 2>nul')
    if p then
        for l in p:lines() do
            if l:sub(1, #abs):lower() == abs:lower() then out[#out + 1] = (l:sub(#abs + 2):gsub("\\", "/")) end
        end
        p:close()
    end
    table.sort(out)
    return out
end

local LUA_FILES = {}
for _, f in ipairs(listFiles(LUA_DIR)) do
    if f:find("^[^/]+%.lua$") then LUA_FILES[#LUA_FILES + 1] = f end
end
check("the mod is built (products/LuaConsole93 has its Lua)", #LUA_FILES >= 20, #LUA_FILES)
if #LUA_FILES == 0 then
    sysPrint("luaconsole93_sim: build the mod first: python -I ZeDUI/tools/products/build_luaconsole93.py")
    os.exit(1)
end

-- ---------------------------------------------------------------------------------------------------------------------
-- THE GAME'S GLOBALS
-- ---------------------------------------------------------------------------------------------------------------------
local nowMs = 1000000
function getTimestampMs() return nowMs end
CLOCK = { t = "14:30:05", d = "2026-11-12_143005" }
Locale = { ENGLISH = "en" }
SimpleDateFormat = { new = function(p) return { format = function() if p == "HH:mm:ss" then return CLOCK.t end return CLOCK.d end } end }
Calendar = { getInstance = function() return { getTime = function() return 0 end } end }
local TRIGGERED = {}
function triggerEvent(name) TRIGGERED[#TRIGGERED + 1] = name end
local DEBUG, CLIENT, CAP, COOP = true, false, false, false
function isDebugEnabled() return DEBUG end
function isClient() return CLIENT end
function isServer() return false end
function isCoopHost() return COOP end
Capability = setmetatable({}, { __index = function(_, k) return k end })
local ROLE = { hasCapability = function(_, c) return CAP and c == "UIManagerProcessCommands" end, getName = function() return "admin" end }
local PLAYER = { getRole = function() return ROLE end, getPlayerNum = function() return 0 end, isAiming = function() return false end,
                 isDead = function() return false end, getUsername = function() return "tester" end }
function getPlayer() return PLAYER end
function getSpecificPlayer() return PLAYER end
function getSoundManager() return { playUISound = function() end } end
local SCREEN = { w = 1920, h = 1080, fontOpt = 6 }
local CORE = {
    getScreenWidth = function() return SCREEN.w end, getScreenHeight = function() return SCREEN.h end,
    getOptionFontSize = function() return SCREEN.fontOpt end, getOptionFontSizeReal = function() return 1 end,
    getKey = function() return 41 end, isKey = function() return false end,
    getOptionControllerButtonStyleString = function() return "XBOX" end,
}
function getCore() return CORE end
local MOUSE = { x = -1, y = -1, down = false }
function isMouseButtonDown() return MOUSE.down end
function getMouseX() return MOUSE.x end
function getMouseY() return MOUSE.y end
function isShiftKeyDown() return false end
function getMyDocumentFolder() return "C:\\Users\\Someone\\Zomboid" end
JoypadState = { players = {} }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
Keyboard = { KEY_ESCAPE = 1, KEY_TAB = 15, KEY_RETURN = 28, getKeyName = function() return "`" end }
function setJoypadFocus(pn, f) local jd = JoypadState.players[pn + 1]; if jd then jd.focus = f end end
function updateJoypadFocus() end
UIFont = setmetatable({}, { __index = function(_, k) return k end })
local CLIP = nil
Clipboard = { setClipboard = function(s) CLIP = s end }
Translator = { getLanguage = function() return { name = function() return "EN" end } end }
local EVENTS = setmetatable({}, { __index = function(t, k)
    local e = { list = {} }
    e.Add = function(fn) e.list[#e.list + 1] = fn end
    e.Remove = function(fn) for i = #e.list, 1, -1 do if e.list[i] == fn then table.remove(e.list, i) end end end
    rawset(t, k, e)
    return e
end })
Events = EVENTS
local function hooked()
    local n = 0
    for _, e in pairs(EVENTS) do n = n + #e.list end
    return n
end

-- the active mods (the guard reads them, and the log names a print's mod by them)
local MODS, NAMES = {}, { Bandits = "Bandits", LaddersMod = "Ladders" }
function getActivatedMods() return { size = function() return #MODS end, get = function(_, i) return MODS[i + 1] end } end
function getModInfoByID(id) if NAMES[id] then return { getName = function() return NAMES[id] end } end return nil end

-- the words: the mod's own English (its EN UI.json), and the game's few the window borrows
local TEXT = {}
do
    local s = readFile(PRODUCT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\n') do TEXT[k] = v end
end
TEXT.UI_Close, TEXT.UI_Cancel = "Close", "Cancel"
TEXT.UI_ServerOptionDesc_Teleport = "Teleports to a player."
function getText(k) return TEXT[k] or k end
function getTextOrNull(k) return TEXT[k] end

-- the game's fonts: the line heights of its 1x faces (Small 19, Medium 29, the Noto Sans Mono code face 19), widths
-- per character; FONT_K makes them larger as the game's font size option would (2x faces at 4K)
local FONT_K = 1
local FONT = { Small = { h = 19, w = 7 }, CodeSmall = { h = 19, w = 7 }, Medium = { h = 29, w = 11 }, Large = { h = 33, w = 12 },
               NewSmall = { h = 19, w = 7 }, Code = { h = 16, w = 8 } }
local REAL_TM = {
    MeasureStringX = function(_, font, s) local f = FONT[font] or FONT.Small; return #tostring(s) * f.w * FONT_K end,
    MeasureStringY = function(_, font, s) local f = FONT[font] or FONT.Small; return f.h * FONT_K end,
    getFontHeight = function(_, font) local f = FONT[font] or FONT.Small; return f.h * FONT_K end,
}
local TM_CALLS = 0
function getTextManager() TM_CALLS = TM_CALLS + 1; return REAL_TM end
local ORIG_GET_TM = getTextManager

-- textures: the paths asked for, and whether the mod has the file
local TEX_ASKED = {}
local function texAt(path)
    TEX_ASKED[path] = true
    if readFile(PRODUCT .. "42/" .. path) then return { path = path } end
    return nil
end
Texture = { getSharedTexture = function(path) return texAt(path) end }
function getTexture(path) return texAt(path) end

-- Zomboid/Lua, as a table of files
local FILES = {}
function getFileWriter(name, create, append)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end,
             close = function() FILES[name] = (append and FILES[name] or "") .. table.concat(buf) end }
end
function getFileReader(name)
    local s = FILES[name]
    if s == nil then return nil end
    local lines = {}
    for l in (s:sub(-1) == "\n" and s or s .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
    local i = 0
    return { readLine = function() i = i + 1; return lines[i] end, close = function() end }
end

-- the F11 list
local F11 = { n = 0, list = {} }
function getLuaDebuggerErrorCount() return F11.n end
function getLuaDebuggerErrors() return { size = function() return #F11.list end, get = function(_, i) return F11.list[i + 1] end } end

-- ---------------------------------------------------------------------------------------------------------------------
-- THE GAME'S UI CLASSES: ISUIElement and ISPanel with a Java element (its controls), every draw recorded
-- ---------------------------------------------------------------------------------------------------------------------
local DRAW = { ops = {}, clip = {}, clips = 0 }
local function jlist()
    local l = { n = {} }
    function l:size() return #self.n end
    function l:get(i) return self.n[i + 1] end
    return l
end
ISUIElement = {}
ISUIElement.__index = ISUIElement
ISUIElement.Type = "ISUIElement"
function ISUIElement:derive(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = name
    return o
end
function ISUIElement:new(x, y, w, h)
    local o = { x = x, y = y, width = w, height = h, visible = true, children = {}, onUI = false, kids = {} }
    setmetatable(o, self)
    self.__index = self
    return o
end
function ISUIElement:initialise() end
function ISUIElement:instantiate()
    local me = self
    self.javaObject = {
        controls = jlist(),
        setConsumeMouseEvents = function() end,
        getControls = function(j) return j.controls end,
        DrawSubTextureRGBA = function(_, tex, sx, sy, sw, sh, x, y, w, h) DRAW.ops[#DRAW.ops + 1] = { p = me, k = "tex", x = x, y = y, w = w, h = h } end,
        getAbsoluteX = function() return me:getAbsoluteX() end,
        getAbsoluteY = function() return me:getAbsoluteY() end,
        getXScroll = function() return 0 end, getYScroll = function() return 0 end,
    }
    if self.createChildren then self:createChildren() end
end
function ISUIElement:createChildren() end
function ISUIElement:addChild(c)
    self.kids[#self.kids + 1] = c
    c.parent = self
    if self.javaObject and c.javaObject then self.javaObject.controls.n[#self.javaObject.controls.n + 1] = c.javaObject end
end
function ISUIElement:removeChild(c)
    for i = #self.kids, 1, -1 do if self.kids[i] == c then table.remove(self.kids, i) end end
    if self.javaObject and c.javaObject then
        local n = self.javaObject.controls.n
        for i = #n, 1, -1 do if n[i] == c.javaObject then table.remove(n, i) end end
    end
    c.parent = nil
end
function ISUIElement:getChildren() return self.kids end
function ISUIElement:setVisible(v) self.visible = v end
function ISUIElement:isVisible() return self.visible end
function ISUIElement:getIsVisible() return self.visible end
function ISUIElement:isReallyVisible() return self.visible and self.onUI end
function ISUIElement:addToUIManager() self.onUI = true end
function ISUIElement:removeFromUIManager() self.onUI = false end
function ISUIElement:setAlwaysOnTop(v) self.onTop = v and true or false end
function ISUIElement:bringToTop() end
function ISUIElement:setCapture() end
function ISUIElement:setWantKeyEvents() end
function ISUIElement:setMaxDrawHeight(h) self.maxDrawH = h end
function ISUIElement:clearMaxDrawHeight() self.maxDrawH = nil end
function ISUIElement:getX() return self.x end
function ISUIElement:getY() return self.y end
function ISUIElement:getWidth() return self.width end
function ISUIElement:getHeight() return self.height end
function ISUIElement:setX(v) self.x = v end
function ISUIElement:setY(v) self.y = v end
function ISUIElement:setWidth(v) self.width = v end
function ISUIElement:setHeight(v) self.height = v end
function ISUIElement:getAbsoluteX() return (self.parent and self.parent:getAbsoluteX() or 0) + self.x end
function ISUIElement:getAbsoluteY() return (self.parent and self.parent:getAbsoluteY() or 0) + self.y end
function ISUIElement:getMouseX() return MOUSE.x - self:getAbsoluteX() end
function ISUIElement:getMouseY() return MOUSE.y - self:getAbsoluteY() end
function ISUIElement:isMouseOver()
    local mx, my = self:getMouseX(), self:getMouseY()
    return mx >= 0 and my >= 0 and mx < self.width and my < self.height
end
function ISUIElement:update() end
function ISUIElement:prerender() end
function ISUIElement:render() end
function ISUIElement:drawRect(x, y, w, h, a, r, g, b)
    assert(type(b) == "number" and type(a) == "number", "drawRect color")
    DRAW.ops[#DRAW.ops + 1] = { p = self, k = "rect", x = x, y = y, w = w, h = h, clip = DRAW.clip[self] }
end
function ISUIElement:drawRectBorder(x, y, w, h, a, r, g, b)
    assert(type(b) == "number", "drawRectBorder color")
    DRAW.ops[#DRAW.ops + 1] = { p = self, k = "border", x = x, y = y, w = w, h = h, clip = DRAW.clip[self] }
end
function ISUIElement:drawText(s, x, y, r, g, b, a, font)
    assert(type(s) == "string", "drawText words")
    assert(font ~= nil, "drawText font")
    DRAW.ops[#DRAW.ops + 1] = { p = self, k = "text", s = s, x = x, y = y, w = REAL_TM:MeasureStringX(font, s), h = REAL_TM:getFontHeight(font), font = font, clip = DRAW.clip[self] }
end
function ISUIElement:drawTexture() end
function ISUIElement:drawTextureScaled() end
function ISUIElement:drawTextureScaledAspect() end
function ISUIElement:setStencilRect(x, y, w, h) DRAW.clip[self] = { x = x, y = y, w = w, h = h }; DRAW.clips = DRAW.clips + 1 end
function ISUIElement:clearStencilRect() DRAW.clip[self] = nil; DRAW.clips = DRAW.clips - 1 end
ISPanel = ISUIElement:derive("ISPanel")

-- the game's text box with its cursor (UITextBox2): on many lines, setCursorPos clamps to the cursor line's length
local KEYS = { entry = nil }
ISTextEntryBox = ISPanel:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.text = text or ""
    local box = o
    local j = { cur = #(text or ""), line = 0 }
    function j.setCentreVertically() end
    function j.setWrapLines() end
    function j.setMultipleLine(_, b) box.multi = b end
    function j.getCursorPos(self2) return self2.cur end
    function j.setCursorLine(self2, n) self2.line = n end
    function j.isMultipleLine() return box.multi == true end
    function j.isMasked() return false end
    function j.onTextChange() end
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
    o.entryJava = j
    return o
end
function ISTextEntryBox:instantiate()
    ISUIElement.instantiate(self)
    for k, v in pairs(self.entryJava) do self.javaObject[k] = v end
    self.entryJava = self.javaObject
end
function ISTextEntryBox:setPlaceholderText(s) self.placeholder = s end
function ISTextEntryBox:setMaxTextLength(n) self.maxT = n end
function ISTextEntryBox:setMultipleLine(b) self.multi = b end
function ISTextEntryBox:isMultipleLine() return self.multi == true end
function ISTextEntryBox:setMaxLines(n) self.maxL = n end
function ISTextEntryBox:getMaxLines() return self.maxL or 1 end
function ISTextEntryBox:getText() return self.text end
function ISTextEntryBox:getInternalText() return self.text end
function ISTextEntryBox:setText(s) self.text = s; if self.javaObject then self.javaObject.cur = #s end end
function ISTextEntryBox:focus() KEYS.entry = self end
function ISTextEntryBox:unfocus() if KEYS.entry == self then KEYS.entry = nil end end
function ISTextEntryBox:isFocused() return KEYS.entry == self end

-- ---------------------------------------------------------------------------------------------------------------------
-- THE GAME'S CONSOLE, as javap reads zombie.ui.UIDebugConsole (console_sim_harness.lua's)
-- ---------------------------------------------------------------------------------------------------------------------
local STDOUT = {}
local function newBox(text)
    local b = { text = text or "", internal = text or "", visible = false }
    function b:getText() return self.text end
    function b:SetText(s) self.text = s; self.internal = s end
    function b:clearInput() self.text = ""; self.internal = "" end
    function b:unfocus() end
    function b:isVisible() return self.visible end
    return b
end
local JC = { visible = false, updates = 0, x = 20 }
JC.out = newBox("Lua Debug Console v1.1.0 42.22.2\n")
JC.cmd = newBox("")
JC.sug = newBox("")
JC.prev = jlist()
function JC.prev:add(s) self.n[#self.n + 1] = s end
function JC:isVisible() return self.visible end
function JC:setVisible(v) self.visible = v end
function JC:getX() return self.x end
function JC:setX(v) self.x = v end
function JC:update()
    if not self.visible then return end
    self.updates = self.updates + 1
    if #STDOUT > 0 then
        local s = self.out.text .. table.concat(STDOUT)
        STDOUT = {}
        if #s > 8192 then s = s:sub(#s - 8192 + 1) end
        self.out:SetText(s)
    end
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
    if s == "clear" then self.out:clearInput(); return end
    local fn, err = loadstring(s, "console")
    if not fn then self.out:SetText(self.out.text .. tostring(err) .. "\n"); return end
    local ok, e = pcall(fn)
    if not ok then
        STDOUT[#STDOUT + 1] = "ERROR: General      f:1, t:1> ExceptionLogger.logException> Exception thrown\n"
            .. "\tjava.lang.RuntimeException: " .. tostring(e) .. " at KahluaThread.tableget(KahluaThread.java:1689).\n"
            .. "LOG  : General      f:1, t:1> -----------------------------------------\n"
            .. "STACK TRACE\n-----------------------------------------\nfunction: console -- file: console line # 1 | Vanilla\n\n"
    end
end
function JC:onOtherKey(k)
    if k == 15 and self.prevSuggestion then self.cmd:SetText(self.prevSuggestion .. "()") end
end
local function say(s) STDOUT[#STDOUT + 1] = "LOG  : Lua          f:1, t:1> " .. tostring(s) .. "\n" end
UIManager = {
    getDebugConsole = function() return JC end,
    getUI = function() return { contains = function(_, x) return x == JC end } end,
}
local FIELDS = { { name = "outputLog", v = JC.out }, { name = "commandLine", v = JC.cmd }, { name = "autosuggest", v = JC.sug }, { name = "previous", v = JC.prev } }
function getNumClassFields(o) if o == JC then return #FIELDS end return 0 end
function getClassField(o, i) local f = FIELDS[i + 1]; return { getName = function() return f.name end, v = f.v } end
function getClassFieldVal(o, f) return f.v end

-- ---------------------------------------------------------------------------------------------------------------------
-- THE GAME'S PARTS THE MOD USES IN PLACE OF ZeD-GUI'S: the on-screen keyboard, the chat box, the Back button wheel
-- ---------------------------------------------------------------------------------------------------------------------
-- (the game's keyboard, ISOnScreenKeyboard.lua on 42.22: one instance, made the first time it shows and kept; it
-- keeps its textEntryBox after it hides; hide() gives that box the keys again and hands the controller back to
-- prevFocus, or the box; Accept (KeyFunction_Enter on one line) puts the words in, hides, then queues KEY_RETURN,
-- which the box with the keys gets as Enter: onCommandEntered)
local OSK = { visible = false, shows = 0, queued = {} }
local OSKI = {}
function OSKI:hide()
    OSK.visible = false
    if self.textEntryBox then self.textEntryBox:focus() end
    if self.jd then self.jd.focus = self.prevFocus or self.textEntryBox end
end
function OSKI:accept()
    if self.textEntryBox then self.textEntryBox:setText(self.typed or "") end
    self:hide()
end
function OSKI:KeyFunction_Enter()
    if not (self.textEntryBox and self.textEntryBox:isMultipleLine()) then self:accept() end
    OSK.queued[#OSK.queued + 1] = Keyboard.KEY_RETURN
end
OnScreenKeyboard = {
    IsVisible = function() return OSK.visible end,
    Show = function(pn, entry, jd)
        if OSK.visible then return OnScreenKeyboard.instance end
        if not OnScreenKeyboard.instance then OnScreenKeyboard.instance = setmetatable({}, { __index = OSKI }) end
        local inst = OnScreenKeyboard.instance
        OSK.visible, OSK.shows = true, OSK.shows + 1
        inst.textEntryBox, inst.jd, inst.typed = entry, jd, entry and entry:getText() or ""
        if entry then entry:unfocus() end
        return inst
    end,
}
-- the keys the game queued reach the box with the keys (a one-line box's Enter is its onCommandEntered)
local function deliverQueuedKeys()
    local q = OSK.queued
    OSK.queued = {}
    for _, k in ipairs(q) do
        local e = KEYS.entry
        if k == Keyboard.KEY_RETURN and e and not e:isMultipleLine() and e.onCommandEntered then e.onCommandEntered(e) end
    end
end
-- (the game's chat, ISChat.lua on 42.22: slow mode and a channel of another tab drop the line with no error)
local CHAT = { sent = {} }
ISChat = { instance = { currentTabID = 1, timerMessageSlowMode = 0,
                        textEntry = { text = "", setText = function(self, s) self.text = s end, getText = function(self) return self.text end } } }
ISChat.allChatStreams = {
    { name = "say", command = "/say ", shortCommand = "/s ", tabID = 1 }, { name = "yell", command = "/yell ", shortCommand = "/y ", tabID = 1 },
    { name = "whisper", command = "/whisper ", shortCommand = "/w ", tabID = 1 }, { name = "faction", command = "/faction ", shortCommand = "/f ", tabID = 1 },
    { name = "safehouse", command = "/safehouse ", shortCommand = "/sh ", tabID = 1 }, { name = "general", command = "/all ", tabID = 1 },
    { name = "admin", command = "/admin ", shortCommand = "/a ", tabID = 2 },
}
function ISChat.onCommandEntered(chat)
    local c = ISChat.instance
    local text = c.textEntry:getText()
    if not PLAYER:getRole():hasCapability(Capability.IgnoreChatSlowMode) and c.timerMessageSlowMode > getTimestampMs() then return end
    for _, s in ipairs(ISChat.allChatStreams) do
        if text:sub(1, #s.command) == s.command or (s.shortCommand and text:sub(1, #s.shortCommand) == s.shortCommand) then
            if c.currentTabID ~= s.tabID then return end
            break
        end
    end
    CHAT.sent[#CHAT.sent + 1] = text
end
local SPEED = { v = 1 }
UIManager.getSpeedControls = function() return { getCurrentGameSpeed = function() return SPEED.v end } end
function isGamePaused() return SPEED.v == 0 end
local SENT = {}
function SendCommandToServer(s) SENT[#SENT + 1] = s end
ISBackButtonWheel = { playerNum = 0 }
function ISBackButtonWheel:addCommands() self.slices = { "vanilla" } end
function ISBackButtonWheel:addSlice(text, tex, fn, ...) self.slices[#self.slices + 1] = { text = text, tex = tex, fn = fn } end
local ORIG_ADDCMDS = ISBackButtonWheel.addCommands

-- Kahlua's strings are Java strings: string.char takes any character code. Real Lua's stops at 255 (the test
-- language's accented letters, Tr.lua), so a code past it is a "?" here.
do
    local char = string.char
    string.char = function(...)
        local a = { ... }
        for i, v in ipairs(a) do if v > 255 then a[i] = 63 end end
        return char(unpack(a))
    end
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 1. WITH ZeD-GUI ON: every file stops at its guard
-- ---------------------------------------------------------------------------------------------------------------------
local function globalsNow()
    local s = {}
    for k in pairs(_G) do s[k] = true end
    return s
end
local PRINTED = {}
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    local s = table.concat(parts, "\t")
    if s:find("^FAIL") or s:find("^" .. SIM_NAME) then sysPrint(s); return end
    PRINTED[#PRINTED + 1] = s
    STDOUT[#STDOUT + 1] = "LOG  : Lua          f:1, t:1> " .. s .. "\n"
end
-- (a file past its guard would require the next one: here a require is only counted)
local REQUIRED = 0
require = function() REQUIRED = REQUIRED + 1 end
for _, id in ipairs({ "ZeD_UI", "\\ZeD_UI" }) do
    MODS = { "Bandits", id }
    PRINTED, STDOUT, REQUIRED = {}, {}, 0
    local before = globalsNow()
    local hooks0 = hooked()
    for _, f in ipairs(LUA_FILES) do
        local fn, err = loadfile(LUA_DIR .. f)
        check("loads: " .. f, fn ~= nil, err)
        if fn then
            local ok, e = pcall(fn)
            check("ZeD-GUI on (" .. id .. "): " .. f .. " runs", ok, e)
        end
    end
    local made = {}
    for k in pairs(_G) do if not before[k] then made[#made + 1] = tostring(k) end end
    check("ZeD-GUI on (" .. id .. "): no global made", #made == 0, table.concat(made, ", "))
    check("ZeD-GUI on (" .. id .. "): no file went on to its requires", REQUIRED == 0, REQUIRED)
    check("ZeD-GUI on (" .. id .. "): no event hooked", hooked() == hooks0)
    check("ZeD-GUI on (" .. id .. "): the game's Back button wheel untouched", ISBackButtonWheel.addCommands == ORIG_ADDCMDS and ISBackButtonWheel._lc93Orig == nil)
    check("ZeD-GUI on (" .. id .. "): the game's text manager untouched", getTextManager == ORIG_GET_TM)
    check("ZeD-GUI on (" .. id .. "): one log line says so", #PRINTED == 1 and PRINTED[1] == TAG .. "ZeD-GUI is on: its console is used", PRINTED[1])
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 2. ON THE PLAIN GAME: the files load (every one, in the game's order: by name, the requires first)
-- ---------------------------------------------------------------------------------------------------------------------
MODS = { "Bandits", "LaddersMod" }
PRINTED, STDOUT = {}, {}
local LOADED = {}
function require(name)
    if LOADED[name] then return end
    LOADED[name] = true
    local short = name:match("^LuaConsole93/(.+)$")
    if not short then return end   -- (the game's own files: their stubs are above)
    local fn, err = loadfile(LUA_DIR .. short .. ".lua")
    if not fn then error(err) end
    fn()
end
for _, f in ipairs(LUA_FILES) do
    local ok, err = pcall(require, "LuaConsole93/" .. (f:gsub("%.lua$", "")))
    check("loads on the plain game: " .. f, ok, err)
end
local DC = LC93 and LC93.DebugConsole
check("LC93 made, its console with it", LC93 ~= nil and DC ~= nil and type(DC.frame) == "function" and LC93_DebugConsoleWindow ~= nil)
check("no ZeD global: the mod never looks like ZeD-GUI", ZeD == nil)
do
    local bad = {}
    for k in pairs(_G) do
        local s = tostring(k)
        if s:find("ZeD") or s:lower():find("^zed") or s:find("_[Zz][Ee][Dd]") then bad[#bad + 1] = s end
    end
    check("no global named for ZeD", #bad == 0, table.concat(bad, ", "))
end
check("the game's text manager is the game's (no proxy put in its place)", getTextManager == ORIG_GET_TM)
check("the frame hook is on OnPreUIDraw", (function() for _, fn in ipairs(EVENTS.OnPreUIDraw.list) do if fn == DC.frame then return true end end return false end)())
check("the Back button wheel's slice hooked once", ISBackButtonWheel._lc93Orig == ORIG_ADDCMDS and ISBackButtonWheel.addCommands ~= ORIG_ADDCMDS)
check("the window's borders scale (one design unit)", LC93_Window.drawRectBorder == LC93.scaledBorder and LC93_WindowOverlay.drawRectBorder == LC93.scaledBorder)
check("no safe mode hook (ZeD-GUI's setting is not here)", not (LC93.Safe and LC93.Safe.register))

-- the palette: Dark, PZ Teal, normal text, the game's own fonts
local T = LC93.T
check("palette made at load", T ~= nil and type(T.px) == "function")
check("Dark theme, PZ Teal accent, normal text", LC93.currentBase == "dark" and LC93.currentAccent == "teal" and LC93.currentSize == "small")
check("the accent is PZ Teal (#47A18C)", T.accent and math.abs(T.accent.r - 0x47 / 255) < 1e-6 and math.abs(T.accent.g - 0xA1 / 255) < 1e-6)
check("the roles draw in the game's fonts (F2 Small, F3 the code face)", T.fontF2 == UIFont.Small and T.fontF3 == UIFont.CodeSmall and T.fontF1 == UIFont.Small)
check("nothing zoomed (the game's faces at their own size)", next(T.fontPx) == nil)
check("the font heights measured", T.fontF3H == 19 and T.fontF2H == 19, T.fontF3H)
check("the scale follows the screen: 1 at 1080p", T.px(10) == 10 and LC93.Scale.root() == 1)
do
    local n0 = TM_CALLS
    for _ = 1, 5 do LC93.TM:MeasureStringX(T.fontF3, "kept") end
    check("measures kept (one call to the game for the same string)", TM_CALLS - n0 <= 2, TM_CALLS - n0)
    check("the fixed-pitch face measures by the character", LC93.TM:MeasureStringX(T.fontF3, "0000000000") == 70)
end
check("ZeD-GUI's button-label exception gone", LC93.btnCase("ZED") == "Zed")
-- the data role (buttons, counts, placeholders) in a face that has the language's letters: the game's code face
-- holds the first 256 characters only
do
    local lang = "RU"
    local realLang = Translator.getLanguage
    Translator.getLanguage = function() return { name = function() return lang end } end
    LC93.applyTheme("dark", LC93.DEFAULT_ACCENT, "small")
    check("fonts: in Russian the data role draws in the language's own Small face", LC93.T.fontF3 == UIFont.Small, LC93.T.fontF3)
    lang = "PL"
    LC93.applyTheme("dark", LC93.DEFAULT_ACCENT, "small")
    check("fonts: in Polish too (letters past the code face's 256)", LC93.T.fontF3 == UIFont.Small, LC93.T.fontF3)
    lang = "FR"
    LC93.applyTheme("dark", LC93.DEFAULT_ACCENT, "small")
    check("fonts: in French the data role keeps the code face", LC93.T.fontF3 == UIFont.CodeSmall, LC93.T.fontF3)
    Translator.getLanguage = realLang
    LC93.applyTheme("dark", LC93.DEFAULT_ACCENT, "small")
    T = LC93.T
    check("fonts: in English the code face", T.fontF3 == UIFont.CodeSmall)
end
-- the text stand-in's frame hook makes no function a frame
do
    local h
    for _, fn in ipairs(EVENTS.OnPreUIDraw.list) do
        local src = debug.getinfo(fn, "S").source or ""
        if src:find("LC93_Text%.lua$") then h = fn end
    end
    check("text: the font size hook is on in debug mode", h ~= nil)
    if h then
        local seen = {}
        local realPcall = pcall
        pcall = function(f, ...) seen[#seen + 1] = f; return realPcall(f, ...) end
        h(); h()
        pcall = realPcall
        check("text: the frame hook makes no function a frame (one made at load)", #seen == 2 and seen[1] == seen[2], #seen)
    end
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 3. THE WINDOW: opened by the game's console flag, drawn inside itself at 1080p, 4K and the Deck's size
-- ---------------------------------------------------------------------------------------------------------------------
local PARKED = -50000
local onScreenWhileOpen = 0
local function frame()
    JC:update()
    for _, fn in ipairs(EVENTS.OnPreUIDraw.list) do fn() end
    if DC.isOpen() and JC.x > PARKED then onScreenWhileOpen = onScreenWhileOpen + 1 end
    nowMs = nowMs + 16
end
local function tick(win)
    for _, fn in ipairs(EVENTS.OnTick.list) do fn() end
    if win then win:update() end
end
local outside = {}
local function draw(win)
    DRAW.ops, DRAW.clip, DRAW.clips = {}, {}, 0
    win:prerender()
    local ov = win._lc93Overlay
    if ov then ov:prerender(); ov:render() end
    win:render()
    check("clips balanced", DRAW.clips == 0, DRAW.clips)
    -- (as console_sim_harness.lua: a text inside a clip must not run past the clip's right edge; anything outside a
    -- clip must stay inside the window)
    for _, op in ipairs(DRAW.ops) do
        if op.p == win then
            local c = op.clip
            if c then
                if op.k == "text" and op.x + op.w > c.x + c.w + 1 then outside[#outside + 1] = "text past its clip: " .. op.s end
            elseif op.x < -1 or op.y < -1 or op.x + op.w > win.width + 1 or op.y + op.h > win.height + 1 then
                outside[#outside + 1] = op.k .. (op.s and (" '" .. op.s .. "'") or "") .. " at " .. op.x .. "," .. op.y .. " " .. op.w .. "x" .. op.h .. " in " .. win.width .. "x" .. win.height
            end
        end
    end
end
local function textHas(s)
    for _, op in ipairs(DRAW.ops) do if op.k == "text" and op.s:find(s, 1, true) then return true end end
    return false
end
local function logged()
    local out = {}
    for _, s in ipairs(PRINTED) do if s:find(TAG, 1, true) == 1 then out[#out + 1] = s end end
    return out
end

check("closed while the game's console is shut", DC.exists() and not DC.isOpen())
JC.visible = true
frame()
local win = DC.win
check("the game's console flag opens the window", DC.isOpen() and win ~= nil)
check("the game's console parked off the screen", JC.x <= PARKED)
check("the window's title is the mod's short name", (function() draw(win); return win.title == "Lua Console 93" end)(), win.title)
check("no window box (ZeD-GUI's window menu is not here)", win:windowBoxRect() == nil)
-- (a new screen size: the root scale is worked out again on the game's tick, and the palette made again with it)
local function screen(w, h, k)
    SCREEN.w, SCREEN.h, FONT_K = w, h, k
    for _ = 1, 31 do tick(win) end
end
-- (each size a fresh window, as a game started at that size opens it; the game's key opens it)
local function reopen()
    DC.close()
    DC.win, DC.place = nil, nil
    JC.visible = true
    frame()
    return DC.win
end
for _, s in ipairs({ { 1920, 1080, 1, "1080p" }, { 3840, 2160, 2, "4K" }, { 1280, 800, 1, "Deck" } }) do
    screen(s[1], s[2], s[3])
    win = reopen()
    T = LC93.T
    for _, page in ipairs({ "log", "cmds", "help" }) do
        win:setPage(page)
        draw(win)
    end
    win:setPage("log")
    win:setMode("pad")
    draw(win)
    win:setMode("line")
    draw(win)
    check("draws inside itself at " .. s[4], #outside == 0, outside[1])
    outside = {}
    check("the window fits the screen at " .. s[4], win.x >= 0 and win.y >= 0 and win.x + win.width <= SCREEN.w and win.y + win.height <= SCREEN.h)
end
check("the scale follows the screen: 2 at 4K, 0.75 on the Deck", (function()
    screen(3840, 2160, 2); local a, pa = LC93.Scale.root(), LC93.T.px(10)
    screen(1280, 800, 1); local b, pb = LC93.Scale.root(), LC93.T.px(10)
    screen(1920, 1080, 1)
    return a == 2 and pa == 20 and b == 0.75 and pb == 8
end)())
check("the palette made again for the new scale", LC93.T.px(10) == 10 and LC93.Scale.root() == 1)
win = reopen()
T = LC93.T
-- the clip in force: a stencil on the window (every stencil the console sets is its window's) is the clip a claim
-- is cut to, so a header half scrolled out of a list leaves the body showing above the list
do
    local Sf = LC93.Surface
    win:setStencilRect(10, 20, 30, 40)
    local c = Sf.clip()
    local okIn = c ~= nil and c.x0 == win:getAbsoluteX() + 10 and c.y0 == win:getAbsoluteY() + 20 and c.y1 == win:getAbsoluteY() + 60
    win:clearStencilRect()
    check("surface: a stencil on the window is the clip in force", okIn, c and (c.x0 .. "," .. c.y0) or "no clip")
    check("surface: cleared with the stencil", Sf.clip() == nil)
    check("surface: the clip stack starts empty before each UI draw", (function()
        for _, fn in ipairs(EVENTS.OnPreUIDraw.list) do if fn == Sf.resetClips then return true end end
        return false
    end)())
end
check("the arrows draw from the mod's own chev.png", TEX_ASKED["media/textures/LuaConsole93/lines/chev.png"] == true)
check("every texture the code asked for is in the mod", (function()
    for p in pairs(TEX_ASKED) do if not readFile(PRODUCT .. "42/" .. p) then return false end end
    return true
end)())
check("the game's console never on the screen with the window open", onScreenWhileOpen == 0, onScreenWhileOpen)
check("nothing logged as a failure while drawing", #logged() == 0, logged()[1])

-- ---------------------------------------------------------------------------------------------------------------------
-- 4. THE LOG (console_log_sim's key checks)
-- ---------------------------------------------------------------------------------------------------------------------
local L = LC93.ConsoleLog
local function P(s) return "LOG  : Lua          f:1, t:1> " .. s .. "\n" end
local function rowsOf(kind)
    local out = {}
    for i = 1, L.counts() do local r = L.shownAt(i); if not kind or r.kind == kind then out[#out + 1] = r end end
    return out
end
local BOX_ERR = "ERROR: General      f:4821, t:1762935182311> ExceptionLogger.logException> Exception thrown\n"
    .. "    java.lang.RuntimeException: attempted index: getHealth of non-table: null at KahluaThread.tableget(KahluaThread.java:1666).\n"
    .. "LOG  : General      f:4821, t:1762935182312> -----------------------------------------\n"
    .. "STACK TRACE\n-----------------------------------------\nCallframe at: getHealth\n"
    .. "function: BanditUpdate.Health -- file: BanditUpdate.lua line # 1203 | MOD: Bandits\n"
    .. "function: Event.trigger -- file: Events.lua line # 81 | Vanilla\n"
do
    L.reset(); L.forgetMods()
    L.feedText(P("Lua: loading 3 mods") .. P(TAG .. "ready") .. "WARN : Lua          f:2, t:3> item not found: Base.RopeLadder\n"
        .. P("Bandits: wave 3 in 2 hours") .. P("Ladders: 214 sprites") .. P("Nobody: not a mod"), 1000)
    local shown, total, errs = L.counts()
    check("log: six rows", shown == 6 and total == 6 and errs == 0, shown)
    local r = rowsOf()
    check("log: the prefix taken off", r[1].msg == "Lua: loading 3 mods", r[1].msg)
    check("log: print and warn", r[1].kind == "print" and r[3].kind == "warn")
    check("log: the mod's own prints are its row (MOD filter: Lua Console 93)", r[2].mod == "Lua Console 93", r[2].mod)
    check("log: a print naming an active mod is that mod's", r[4].mod == "Bandits" and r[5].mod == "Ladders", r[5].mod)
    check("log: a word that is no mod stays the game's", r[6].mod == L.GAME)
    check("log: the time on each row", r[1].t == "14:30:05")
    L.feedText(P("x") .. BOX_ERR, 2000)
    L.tick(2000 + L.FLUSH_MS)
    local e = rowsOf("error")[1]
    check("log: an error from the box, its mod and file:line", e and e.mod == "Bandits" and e.file == "BanditUpdate.lua" and e.line == 1203, e and (e.mod .. " " .. tostring(e.file)))
    check("log: the error's words", e and e.msg == "attempted index: getHealth of non-table: null", e and e.msg)
    L.feedText(P("x") .. BOX_ERR .. P("y") .. BOX_ERR, 3000)
    L.tick(3000 + L.FLUSH_MS)
    e = rowsOf("error")[1]
    check("log: a repeated error is one row with a count", #rowsOf("error") == 1 and e.n == 2, e and e.n)
    L.toggle("kind", "print")
    check("log: a kind unticked hides its rows", #rowsOf("print") == 0 and #rowsOf("error") == 1)
    L.toggle("kind", "print")
    L.setQuery("ladders")
    check("log: the search walks the rows", L.counts() == 1 and rowsOf()[1].msg == "Ladders: 214 sprites")
    L.setQuery("")
    local name = L.export()
    check("log: Export names the file for the mod and the time", name == "LuaConsole93_2026-11-12_143005.log", name)
    local text = FILES[name] or ""
    check("log: the export's first line names the mod", text:find("^Lua Console 93 | 2026%-11%-12_143005 | ") ~= nil, text:sub(1, 60))
    check("log: the export holds the stack", text:find("BanditUpdate.lua line # 1203", 1, true) ~= nil)
    check("log: the export's user name taken out", text:find("Your user name is taken out", 1, true) ~= nil)
    check("log: a second export in the same second gets _2", L.export() == "LuaConsole93_2026-11-12_143005_2.log")
end
do
    -- the window over the log: a print through the game, the error row opened
    L.reset()
    DC.clear()
    say("hello from the sim")
    frame(); frame()
    check("window: a print through the game's box is a row", (function() for _, r in ipairs(rowsOf()) do if r.msg == "hello from the sim" then return true end end return false end)())
    draw(win)
    check("window: the row drawn", textHas("hello from the sim"))
    check("window: the count in the head", textHas(" of "))
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 5. THE LINE AND THE SCRATCHPAD (debug_console_sim's and console_scratch_sim's key checks)
-- ---------------------------------------------------------------------------------------------------------------------
local S = LC93.ConsoleScratch
do
    win.input:setText("print('ran here')")
    win:runLine()
    frame(); frame()
    check("line: Enter runs through the game's own console", JC.prev:size() >= 1 and JC.prev:get(JC.prev:size() - 1) == "print('ran here')")
    check("line: the ran row and its print", #rowsOf("ran") >= 1 and (function() for _, r in ipairs(rowsOf("print")) do if r.msg == "ran here" then return true end end return false end)())
    check("line: the run is on the kept history", FILES["LuaConsole93_history.txt"] ~= nil and FILES["LuaConsole93_history.txt"]:find("print('ran here')", 1, true) ~= nil)
    check("history file: the mod's own head", FILES["LuaConsole93_history.txt"]:find("^# Lua Console 93 history") ~= nil, FILES["LuaConsole93_history.txt"]:sub(1, 40))
    win:setMode("pad")
    win:_padSet("print('a')\nprint('b')")
    win:runPad()
    frame()
    local got = {}
    for _, r in ipairs(rowsOf("print")) do if r.mod == L.CONSOLE then got[#got + 1] = r.msg end end
    check("scratchpad: each printed line a row from Console", got[#got - 1] == "a" and got[#got] == "b", table.concat(got, ","))
    check("scratchpad: the box emptied after a run", win:padText() == "")
    S.run("this is not lua")
    check("scratchpad: a line that does not compile is an error row from Console", rowsOf("error")[#rowsOf("error")].mod == L.CONSOLE)
    local i, wrote = S.saveSnippet("two lines", "print(1)\nprint(2)")
    check("snippets: saved to the mod's own file", i ~= nil and wrote and FILES["LuaConsole93_snippets.txt"] ~= nil)
    check("snippets: the file's head names the mod", FILES["LuaConsole93_snippets.txt"]:find("^# Lua Console 93 snippets") ~= nil)
    S._loaded = nil
    S.snippets = {}
    S.load(true)
    check("snippets: read back from disk", S.snippets[1] and S.snippets[1].name == "two lines" and S.snippets[1].code == "print(1)\nprint(2)")
    win:setMode("line")
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 6. THE SUGGESTIONS (console_complete_sim's key checks)
-- ---------------------------------------------------------------------------------------------------------------------
local AC = LC93.ConsoleComplete
do
    AC.refresh()
    local ac = AC.complete("getPl", 5)
    local names = {}
    for _, it in ipairs(ac and ac.items or {}) do names[it.n] = true end
    check("suggestions: globals after two letters", names.getPlayer == true)
    ac = AC.complete("LC93.Debug", 10)
    check("suggestions: a table's fields after a dot", ac and ac.items[1] and ac.items[1].n == "DebugConsole", ac and ac.items[1] and ac.items[1].n)
    local t, cur = AC.take("LC93.Debug", ac, 1)
    check("suggestions: taking one", t == "LC93.DebugConsole" and cur == #t, t)
    check("suggestions: nothing inside a string", AC.complete('print("getPl', 12) == nil)
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 7. THE COMMANDS (console_commands_sim's key checks)
-- ---------------------------------------------------------------------------------------------------------------------
local CC = LC93.ConsoleCommands
do
    check("commands: the list", #CC.list >= 70 and CC.total() == #CC.list, #CC.list)
    local horde2 = CC.byName.createhorde2
    check("commands: the mod's own help words (UI_LC93_ keys)", horde2 and CC.does(horde2):find("^Spawns zombies") ~= nil, horde2 and CC.does(horde2))
    check("commands: the game's help words", CC.does(CC.byName.teleport) == "Teleports to a player.")
    check("commands: single player opens the debug menu's window", CC.alone(CC.byName.godmode).open == "cheats")
    CC.qaServer = true
    check("commands: a chat channel goes through the game's chat", CC.send("/say over here") == "chat" and CHAT.sent[#CHAT.sent] == "/say over here", CHAT.sent[#CHAT.sent])
    check("commands: the chat box emptied after", ISChat.instance.textEntry:getText() == "")
    -- the game's chat drops a line of another tab's channel, and any line in slow mode: never told Sent
    local nSent = #CHAT.sent
    ISChat.instance.currentTabID = 1
    check("commands: /admin while the chat shows General is not told Sent", CC.send("/admin someone's duping") == false and #CHAT.sent == nSent)
    ISChat.instance.currentTabID = 2
    check("commands: /admin from the Admin tab goes", CC.send("/admin someone's duping") == "chat" and CHAT.sent[#CHAT.sent] == "/admin someone's duping")
    check("commands: /say while the chat shows Admin is not told Sent", CC.send("/say over here") == false)
    ISChat.instance.currentTabID = 1
    nSent = #CHAT.sent
    ISChat.instance.timerMessageSlowMode = getTimestampMs() + 3000
    check("commands: a line in the chat's slow mode is not told Sent", CC.send("/say again") == false and #CHAT.sent == nSent)
    ISChat.instance.timerMessageSlowMode = 0
    check("commands: a server command goes to the server", CC.send("/players") == "sent" and SENT[#SENT] == "/players")
    CC.qaServer = nil
    win:setPage("cmds")
    draw(win)
    check("commands: the page draws its first group and its commands", textHas("Players") and textHas("/teleport"))
    win:setPage("log")
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 8. THE CONTROLLER: the Back button wheel's slice, the pad keyboard (the game's own)
-- ---------------------------------------------------------------------------------------------------------------------
do
    DC.close()
    frame()
    local jd = { focus = nil }
    JoypadState.players[1] = jd
    local wheel = setmetatable({ playerNum = 0 }, { __index = ISBackButtonWheel })
    wheel:addCommands()
    local slice = wheel.slices[#wheel.slices]
    check("pad: the Back button wheel keeps its own slices", wheel.slices[1] == "vanilla")
    check("pad: a slice named for the mod", type(slice) == "table" and slice.text == "Lua Console 93", type(slice) == "table" and slice.text)
    check("pad: the slice's picture is in the mod", type(slice) == "table" and slice.tex ~= nil)
    if type(slice) == "table" then slice.fn() end
    win = DC.win
    check("pad: the slice opens the window with the controller in it", DC.isOpen() and jd.focus == win)
    win:update()
    check("pad: the window has the controller", win.joyfocus ~= nil)
    draw(win)
    check("pad: the help line shows the controller's prompts", textHas("Keyboard") or textHas("Older"))
    win.zone = "input"
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A on the line shows the game's own keyboard", OSK.visible and OSK.shows == 1 and LC93.Keyboard.isVisible())
    check("pad: the keyboard types into the window's line", LC93.Keyboard.instance and LC93.Keyboard.instance.textEntryBox == win.input)
    -- (Accept on the game's keyboard: the words in, the keyboard away, then the Enter the game queues)
    local ranBefore = JC.prev:size()
    OnScreenKeyboard.instance.typed = "print(2)"
    OnScreenKeyboard.instance:KeyFunction_Enter()
    deliverQueuedKeys()
    frame(); frame()
    check("pad: Accept on the game's keyboard puts the words in the line and does not run them",
        win.input:getText() == "print(2)" and JC.prev:size() == ranBefore, win.input:getText() .. " | runs " .. (JC.prev:size() - ranBefore))
    check("pad: the game's keyboard hands the controller back to the window", jd.focus == win)
    check("pad: after Accept the line lets the keys go (as ZeD-GUI's keyboard leaves it)", not win.input:isFocused())
    win:update()
    check("pad: the keyboard put away, the hand lands on Run", win.zone == "band" and win.bandFocus == 4, win.zone)
    check("pad: the console sees no keyboard once it is put away", LC93.Keyboard.instance == nil)
    win:onJoypadDown(Joypad.BButton, jd)
    check("pad: B closes the window and gives the controller back", not DC.isOpen() and jd.focus == nil)
    check("pad: no hidden console box holds the keys after the close", KEYS.entry == nil, KEYS.entry and "a box is focused")
    -- the console key closing it after a keyboard use: the same
    win = (function() JC.visible = true; frame(); return DC.win end)()
    win.zone = "input"
    jd.focus = win
    win:onJoypadDown(Joypad.AButton, jd)
    OnScreenKeyboard.instance:hide()
    win:update()
    JC.visible = false
    frame()
    check("pad: the console key's close leaves no hidden box with the keys", not DC.isOpen() and KEYS.entry == nil, KEYS.entry and "a box is focused")
    -- while the game is paused the wheel has no console slice (a paused game drops a window's buttons)
    SPEED.v = 0
    local wp = setmetatable({ playerNum = 0 }, { __index = ISBackButtonWheel })
    wp:addCommands()
    check("pad: no slice while the game is paused", #wp.slices == 1, #wp.slices)
    SPEED.v = 1
    JoypadState.players[1] = nil
    DEBUG = false
    local w2 = setmetatable({ playerNum = 0 }, { __index = ISBackButtonWheel })
    w2:addCommands()
    check("pad: no slice outside debug mode", #w2.slices == 1)
    DEBUG = true
end
check("nothing logged as a failure", #logged() == 0, logged()[1])

-- ---------------------------------------------------------------------------------------------------------------------
-- 9. THE FILES: no clash with ZeD-GUI, the keys, no ZeD name in the code
-- ---------------------------------------------------------------------------------------------------------------------
do
    local zed = {}
    for _, f in ipairs(listFiles(ROOT .. "42/media")) do zed[f:lower()] = true end
    check("ZeD-GUI's own files listed", next(zed) ~= nil)
    local clash = {}
    local mine = listFiles(PRODUCT .. "42/media")
    for _, f in ipairs(mine) do
        if zed[f:lower()] and not f:find("^lua/shared/Translate/[%w_]+/UI%.json$") then clash[#clash + 1] = f end
    end
    check("no file at a path ZeD-GUI ships under media/", #clash == 0, clash[1])
    check("the Lua sits in its own folder", (function()
        for _, f in ipairs(mine) do if f:find("^lua/") and not f:find("^lua/client/LuaConsole93/") and not f:find("^lua/shared/Translate/") then return false end end
        return true
    end)())
    -- the keys: none of ZeD-GUI's, every one the code uses in English, in every language ZeD-GUI ships
    local zk = {}
    local langs = {}
    for _, f in ipairs(listFiles(ROOT .. "42/media/lua/shared/Translate")) do
        local lang = f:match("^([%w_]+)/UI%.json$")
        if lang then
            langs[#langs + 1] = lang
            for k in (readFile(ROOT .. "42/media/lua/shared/Translate/" .. f) or ""):gmatch('"([%w_]+)":') do zk[k] = true end
        end
    end
    local bad, n = {}, 0
    for _, lang in ipairs(langs) do
        local s = readFile(PRODUCT .. "42/media/lua/shared/Translate/" .. lang .. "/UI.json")
        if not s then bad[#bad + 1] = "no " .. lang end
        for k in (s or ""):gmatch('"([%w_]+)":') do
            n = n + 1
            if zk[k] or not k:find("^UI_LC93_") then bad[#bad + 1] = lang .. " " .. k end
        end
    end
    check("every language ZeD-GUI ships, no key of ZeD-GUI's", #bad == 0 and #langs >= 28, bad[1])
    local missing = {}
    for _, f in ipairs(LUA_FILES) do
        for k in (readFile(LUA_DIR .. f) or ""):gmatch('"(UI_LC93_[%w_]+)"') do
            if not TEXT[k] then missing[#missing + 1] = k end
        end
    end
    check("every key the code uses has its English", #missing == 0, missing[1])
    -- no ZeD name in the code (comments and the guard's two strings aside)
    local left = {}
    for _, f in ipairs(LUA_FILES) do
        local n2 = 0
        for line in ((readFile(LUA_DIR .. f) or "") .. "\n"):gmatch("([^\n]*)\n") do
            n2 = n2 + 1
            local code = line:gsub("%-%-.*$", "")
            code = code:gsub('"ZeD_UI"', ""):gsub('"%[Lua Console 93%] ZeD%-GUI is on: its console is used"', "")
            if code:find("ZeD") or code:find("[^%w]zed[%u_]") or code:find("^zed[%u_]") then left[#left + 1] = f .. ":" .. n2 .. ": " .. line end
        end
    end
    check("no ZeD name survives in the code", #left == 0, left[1])
end

-- ---------------------------------------------------------------------------------------------------------------------
-- 10. THE PICTURES, THE LICENCE, THE PAGE
-- ---------------------------------------------------------------------------------------------------------------------
do
    local ART = ROOT .. "ZeDUI/art/lua_console_93/"
    for _, p in ipairs({ { "workshop/preview.png", "preview.png" }, { "42/poster.png", "poster.png" }, { "42/icon.png", "icon.png" },
                         { "42/media/textures/LuaConsole93/console_slice.png", "icon.png" } }) do
        local mine, design = readFile(PRODUCT .. p[1]), readFile(ART .. p[2])
        check("art: " .. p[1] .. " is design's " .. p[2], mine ~= nil and design ~= nil and mine == design)
    end
    local lic = readFile(ROOT .. "LICENSE")
    -- (line endings aside: a Windows checkout gives the repo's LICENSE CRLF)
    local function lf(s) return (tostring(s or ""):gsub("\r\n", "\n")) end
    check("licence: the mod carries the repo's LICENSE as 42/LICENSE.txt", lic ~= nil and lf(readFile(PRODUCT .. "42/LICENSE.txt")) == lf(lic))
    local URL = "https://github.com/hermit-the-trog/ZeD.UI/blob/main/LICENSE"
    local readme = readFile(PRODUCT .. "42/README.txt") or ""
    local page = readFile(PRODUCT .. "workshop_description.bbcode") or ""
    check("licence: the README names its copy and links it", readme:find("LICENSE.txt", 1, true) ~= nil and readme:find(URL, 1, true) ~= nil)
    check("licence: the Workshop page links it", page:find("[url=" .. URL .. "]", 1, true) ~= nil)
    check("page: a controller closes it with B (the Back button does not)", page:find("Close it the same way", 1, true) == nil
        and page:find("with B on a controller", 1, true) ~= nil)
    local gal = readFile(PRODUCT .. "workshop/README.txt") or ""
    check("gallery: the shots are saved outside the built folder (a build rewrites it)", gal:find("ZeDUI/workshop/luaconsole93/", 1, true) ~= nil
        and gal:find("in this folder", 1, true) == nil)
end

-- outside debug mode the text stand-in hooks no frame (the mod does nothing there)
do
    local function textHooks()
        local n = 0
        for _, fn in ipairs(EVENTS.OnPreUIDraw.list) do
            if (debug.getinfo(fn, "S").source or ""):find("LC93_Text%.lua$") then n = n + 1 end
        end
        return n
    end
    local n0 = textHooks()
    DEBUG = false
    local fn = loadfile(LUA_DIR .. "LC93_Text.lua")
    if fn then pcall(fn) end
    DEBUG = true
    check("text: no frame hook outside debug mode", fn ~= nil and textHooks() == n0, textHooks() - n0)
end

sysPrint(SIM_NAME .. ": " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
