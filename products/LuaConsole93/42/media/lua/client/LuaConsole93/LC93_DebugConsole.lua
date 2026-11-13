-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_DebugConsole.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the console: the window over the game's own console, its Log
-- page, the line and the scratchpad.
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_DebugConsole.lua by
-- ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change ZeD-GUI's file and build again.
-- ============================================================================================================

-- With ZeD-GUI on (mod ZeD_UI; the game can put a backslash before a mod's id), ZeD-GUI's console is the one:
-- this file stops here and defines nothing.
do
    local guiOn = false
    pcall(function()
        local mods = getActivatedMods()
        for i = 0, mods:size() - 1 do
            if string.gsub(tostring(mods:get(i)), "^\\", "") == "ZeD_UI" then guiOn = true end
        end
    end)
    if guiOn then print("[Lua Console 93] ZeD-GUI is on: its console is used") return end
end

require "ISUI/ISTextEntryBox"
require "LuaConsole93/Tr"
require "LuaConsole93/Tokens"
require "LuaConsole93/Atoms"
require "LuaConsole93/Molecules"
require "LuaConsole93/Organisms"
require "LuaConsole93/LC93_ConsoleLog"
require "LuaConsole93/LC93_ConsoleScratch"
require "LuaConsole93/LC93_ConsoleComplete"

LC93 = LC93 or {}
LC93.DebugConsole = LC93.DebugConsole or {}
local DC = LC93.DebugConsole
local L = LC93.ConsoleLog
local S = LC93.ConsoleScratch
local AC = LC93.ConsoleComplete

local U = { W = 900, H = 480, MIN_W = 520, MIN_H = 260, PAD = 8, GAP = 6, MARK = 6, BOTTOM = 140, LEFT = 20,
            STRIP = 34, FILTERS = 168, HEAD = 34, FOLD = 22, FROW = 20, ICON = 10,
            PADBOX = 134, PADMIN = 60, META = 26, SIDE = 196, GUT = 26,
            ACROW = 20, ACMIN = 300, ACMAX = 460, ACKIND = 92 }
local PAD_MAX = 60000
local PAD_LINES = 2000
local F11_MS = 500
local LINE_MAX = 256
local PARK_X = -100000
local COPIED_MS = 1500
local TAB_KEY = 15

local function tr(k, ...) return LC93.tr(k, ...) end
local function px(n) return LC93.T.px(n) end
local function fh(font) return LC93.TM:getFontHeight(font) end
local function inRect(r, x, y) return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UISelectListItem") end) end
local function btn(s) return LC93.btnCase and LC93.btnCase(s) or s end

DC.text = DC.text or ""
DC.rev = DC.rev or 0
local P = { jc = nil, ok = false }
DC.P = P

function DC.debug()
    if not isDebugEnabled then return false end
    local ok, v = pcall(isDebugEnabled)
    return ok and v == true
end

function DC.game()
    if not DC.debug() then return nil end
    if not (UIManager and UIManager.getDebugConsole) then return nil end
    local ok, jc = pcall(UIManager.getDebugConsole)
    if ok then return jc end
    return nil
end

local function fieldOf(obj, name)
    local n = getNumClassFields(obj)
    for i = 0, n - 1 do
        local f = getClassField(obj, i)
        if f and f.getName and f:getName() == name then
            local v = getClassFieldVal(obj, f)
            if type(v) == "string" then return nil end
            return v
        end
    end
    return nil
end

function DC.parts(jc)
    if P.jc == jc and P.jc ~= nil then return P end
    P.jc, P.ok = jc, false
    P.out, P.cmd, P.sug, P.prev = nil, nil, nil, nil
    if not jc then return P end
    local ok = pcall(function()
        P.out = fieldOf(jc, "outputLog")
        P.cmd = fieldOf(jc, "commandLine")
        P.sug = fieldOf(jc, "autosuggest")
        P.prev = fieldOf(jc, "previous")
    end)
    P.ok = ok and P.out ~= nil and P.cmd ~= nil
    DC._mirrored = nil
    if not P.ok then print("[Lua Console 93] the game's console parts were not found; the game's own stays") end
    return P
end

local function onScreen(jc)
    local ok, v = pcall(function() return UIManager.getUI():contains(jc) end)
    return ok and v == true
end

local OFF_BY_FILE = false
do
    local ok, r = pcall(getFileReader, "LuaConsole93_off.txt", false)
    if ok and r then
        OFF_BY_FILE = true
        pcall(function() r:close() end)
        print("[Lua Console 93] handed back to the game (Zomboid/Lua/LuaConsole93_off.txt)")
    end
end
function DC.handedBack()
    if OFF_BY_FILE then return true end
    return LC93.Safe ~= nil and LC93.Safe.on ~= nil and LC93.Safe.on("console") == true
end
function DC.exists()
    local jc = DC.game()
    if not jc or DC.handedBack() then return false end
    if not onScreen(jc) then return false end
    return DC.parts(jc).ok
end

function DC.park(jc)
    local ok, x = pcall(function() return jc:getX() end)
    if not ok or type(x) ~= "number" or x <= PARK_X / 2 then return end
    P.homeX = x
    pcall(function() jc:setX(PARK_X) end)
end
function DC.unpark(jc)
    local ok, x = pcall(function() return jc:getX() end)
    if not ok or type(x) ~= "number" or x > PARK_X / 2 then return end
    local home = P.homeX or 20
    pcall(function() jc:setX(home) end)
end

function DC.up(jc)
    local ok, v = pcall(function() return jc:isVisible() end)
    return ok and v == true
end

function DC.read()
    if not (P.ok and P.out) then return end
    local ok, s = pcall(function() return P.out:getText() end)
    s = (ok and s) and tostring(s) or ""
    if s ~= DC.text then
        DC.text = s
        DC.rev = DC.rev + 1
    end
end

function DC.mirror(text)
    text = text or ""
    if not (P.ok and P.cmd) then return end
    if DC._mirrored == text then
        local ok, cur = pcall(function() return P.cmd:getText() end)
        if not ok or cur == nil or tostring(cur) == text then return end
    end
    DC._mirrored = text
    pcall(function() P.cmd:SetText(text) end)
    if P.jc and text ~= "" then
        local ok, err = pcall(function()
            P.cmd:SetText(text .. " ")
            P.jc:update()
            P.cmd:SetText(text)
            P.jc:update()
        end)
        if not ok then
            pcall(function() P.cmd:SetText(text) end)
            LC93.logOnce("lua console suggestion", tostring(err))
        end
    end
end

function DC.allowed()
    if not (isClient and isClient()) then return true end
    local ok, v = pcall(function() return getPlayer():getRole():hasCapability(Capability.UIManagerProcessCommands) end)
    if ok and v then return true end
    local ok2, h = pcall(isCoopHost)
    return ok2 and h == true
end

function DC.run(line)
    local jc = P.jc
    if not (jc and P.ok) then return false end
    if not DC.allowed() then return false end
    line = tostring(line or "")
    L.ran(line)
    S.addHistory(line)
    pcall(function() P.cmd:SetText(line) end)
    local ok, err = pcall(function() jc:ProcessCommand() end)
    pcall(function() P.cmd:SetText("") end)
    pcall(function() P.cmd:unfocus() end)
    DC._mirrored = ""
    if not ok then LC93.logOnce("lua console run", err) end
    DC.read()
    return ok
end

function DC.history()
    local out = {}
    local list = P.ok and P.prev or nil
    if not list then return out end
    pcall(function()
        local n = list:size()
        for i = 0, n - 1 do out[#out + 1] = tostring(list:get(i)) end
    end)
    return out
end

function DC.suggestion()
    local s = P.ok and P.sug or nil
    if not s then return nil end
    local ok, t = pcall(function()
        if not s:isVisible() then return nil end
        return s:getText()
    end)
    if ok and t and t ~= "" and DC.fits(tostring(t), P.cmd) then return tostring(t) end
    return nil
end

function DC.fits(sug, cmd)
    local line = ""
    pcall(function() line = tostring(cmd:getText() or "") end)
    local word = line:match("([%w_]*)$") or ""
    if word == "" then return true end
    local name = sug:match("([%w_]+)%s*$")
    if not name then return false end
    return name:sub(1, #word):lower() == word:lower()
end

function DC.complete(text)
    local jc = P.jc
    if not (jc and P.ok) then return nil end
    DC.mirror(text)
    if not DC.suggestion() then return nil end
    local ok, t = pcall(function()
        jc:onOtherKey(TAB_KEY)
        return P.cmd:getText()
    end)
    if not ok or t == nil then return nil end
    t = tostring(t)
    DC._mirrored = t
    return t
end

function DC.clear()
    L.clear()
    if not (P.ok and P.out) then return end
    pcall(function() P.out:clearInput() end)
    DC.read()
    DC.feed()
end

function DC.feed()
    local ms = getTimestampMs()
    if DC._fedRev ~= DC.rev then
        DC._fedRev = DC.rev
        L.feedText(DC.text, ms)
    end
    if ms - (DC._f11At or 0) >= F11_MS and getLuaDebuggerErrorCount and getLuaDebuggerErrors then
        DC._f11At = ms
        local okN, n = pcall(getLuaDebuggerErrorCount)
        if okN and n and n ~= L._f11Seen then
            local okL, list = pcall(getLuaDebuggerErrors)
            if okL and list then L.feedErrors(list, n, ms) end
        end
    end
    L.tick(ms)
end

function DC.parse(text)
    local lines = {}
    text = tostring(text or "")
    text = text:gsub("\r", "")
    text = text:gsub("\t", "    ")
    local pos, n = 1, #text
    while pos <= n do
        local e = string.find(text, "\n", pos, true)
        if e then
            lines[#lines + 1] = { s = text:sub(pos, e - 1) }
            pos = e + 1
        else
            lines[#lines + 1] = { s = text:sub(pos) }
            pos = n + 1
        end
    end
    local block = nil
    local errors = 0
    for i, ln in ipairs(lines) do
        if L.startsError(ln.s) and not (block and L.continuesError(ln.s)) then
            block = i
            errors = errors + 1
            ln.err, ln.b = true, i
        elseif block and L.continuesError(ln.s) then
            ln.err, ln.b = true, block
        else
            block = nil
            ln.b = i
        end
    end
    return lines, errors
end

function DC.lines()
    if DC._linesRev ~= DC.rev then
        DC._linesRev = DC.rev
        DC._lines, DC._errors = DC.parse(DC.text)
    end
    return DC._lines, DC._errors or 0
end

LC93_DebugConsoleWindow = LC93_Window:derive("LC93_DebugConsoleWindow")
local W = LC93_DebugConsoleWindow

local BAND = { "export", "copy", "clear", "run" }
local RUN_AT = 4

local MAP_LOG = { "..........", "XXXXXXXXXX", "..........", "XXXXXX....", "..........", "XXXXXXXX..", "..........", "XXXX......", "..........", "XXXXXXX..." }
local MAP_CMD = { "..........", "........X.", ".......X..", "......X...", ".....X....", "....X.....", "...X......", "..X.......", ".X........", ".........." }
local MAP_HELP = { "...XXXX...", "..X....X..", "..X....X..", ".......X..", "......X...", ".....X....", ".....X....", "..........", ".....X....", ".........." }
local PAGES = {
    { id = "log", key = "UI_LC93_Console_PageLog", map = MAP_LOG },
    { id = "cmds", key = "UI_LC93_Console_PageCommands", map = MAP_CMD },
    { id = "help", key = "UI_LC93_Console_PageHelp", map = MAP_HELP },
}

local KIND_LABEL = { print = "UI_LC93_Console_KindPrint", warn = "UI_LC93_Console_KindWarn", error = "UI_LC93_Console_KindError", ran = "UI_LC93_Console_KindRan" }
local function kindColor(k)
    local T = LC93.T
    if k == "error" then return T.danger end
    if k == "warn" then return T.warning end
    if k == "ran" then return T.accent end
    return T.textDim
end
local GROUPS = { { g = "kind", key = "UI_LC93_Console_FoldKind" }, { g = "mod", key = "UI_LC93_Console_FoldMod" }, { g = "file", key = "UI_LC93_Console_FoldFile" } }

function W:new(x, y, w, h)
    local o = LC93_Window.new(self, x, y, w, h, "")
    o.resizable = true
    o.pin = true
    o.noWindowBox = true
    o.moveWithMouse = false
    o.playerNum = 0
    o.page = "log"
    o.scroll = 0
    o.fScroll = 0
    o.zone = "input"
    o.bandFocus = RUN_AT
    o.stripFocus = 1
    o.fFocus = 1
    o.pick = nil
    o.opened = {}
    o.fold = {}
    o.hi = nil
    o.draft = ""
    o.mode = "line"
    o.phi = nil
    o.pdraft = ""
    o.sFocus = 1
    o.sScroll = 0
    o.sFold = {}
    o.naming = nil
    o._padSt = {}
    o._nameSt = {}
    o._keyHits = {}
    o._bandOff = {}
    o._findSt = {}
    o.ac = nil
    o.acI = 1
    return o
end

local function makeEntry(win, maxLen)
    local T = LC93.T
    local e = ISTextEntryBox:new("", 0, 0, 100, T.inputH)
    e.lc93DrawsText = true
    e:initialise()
    e:instantiate()
    e.lc93Entry = true
    pcall(function() e.javaObject:setCentreVertically(true) end)
    e:setPlaceholderText("")
    e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    e:setMaxTextLength(maxLen)
    win:addChild(e)
    return e
end

function W:createChildren()
    LC93_Window.createChildren(self)
    local e = makeEntry(self, LINE_MAX)
    local win = self
    e.onCommandEntered = function() if win.ac then win:acTake() else win:runLine() end end
    e.onPressUp = function() if win.ac then win:acMove(-1) else win:historyStep(-1) end end
    e.onPressDown = function() if win.ac then win:acMove(1) else win:historyStep(1) end end
    e.onOtherKey = function(_, key)
        if key == Keyboard.KEY_ESCAPE then
            if win.ac then win:acShut() else e:unfocus() end
        elseif key == TAB_KEY then
            if win.ac then win:acTake() else win:complete() end
        end
    end
    self.input = e
    local f = makeEntry(self, 100)
    f.onCommandEntered = function() f:unfocus() end
    f.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then f:unfocus() end end
    self.find = f
    local p = makeEntry(self, PAD_MAX)
    p:setMultipleLine(true)
    pcall(function() p:setMaxLines(PAD_LINES) end)
    pcall(function() p.javaObject:setWrapLines(false) end)
    pcall(function() p.javaObject:setCentreVertically(false) end)
    p.onPressUp = function() if win.ac then win:_padHold(); win:acMove(-1) else win:padArrow(-1) end end
    p.onPressDown = function() if win.ac then win:_padHold(); win:acMove(1) else win:padArrow(1) end end
    p.onOtherKey = function(_, key)
        if key == Keyboard.KEY_ESCAPE then
            if win.ac then win:acShut() else p:unfocus() end
        elseif key == TAB_KEY then
            win:acTake()
        end
    end
    self.pad = p
    local n = makeEntry(self, S.NAME_MAX)
    n.onCommandEntered = function() win:nameDone(true) end
    n.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then win:nameDone(false) end end
    self.nameE = n
end

function W:lineText()
    return self.input and tostring(self.input:getText() or "") or ""
end
local function blank(s) return string.find(s, "%S") == nil end

function W:runLine()
    local text = self:lineText()
    if blank(text) or not DC.allowed() then return end
    local typing = self.input:isFocused()
    DC.run(text)
    if self._status and self._status.lineFull then self._status = nil end
    self.input:setText("")
    self.hi, self.draft = nil, ""
    self.scroll, self.pick = 0, nil
    if typing then self.input:focus() end
end

function W:historyStep(d)
    local list = DC.history()
    if #list == 0 then return end
    if self.hi == nil then
        if d > 0 then return end
        self.draft = self:lineText()
        self.hi = #list
    else
        self.hi = self.hi + d
    end
    if self.hi < 1 then self.hi = 1 end
    if self.hi > #list then
        self.hi = nil
        self.input:setText(self.draft or "")
    else
        self.input:setText(list[self.hi])
    end
    DC.mirror(self:lineText())
end

function W:complete()
    local t = DC.complete(self:lineText())
    if t and t ~= self:lineText() then
        self.input:setText(t)
        sound()
    end
end

function W:padText()
    return self.pad and tostring(self.pad:getText() or "") or ""
end

local function cursorOf(inp, text)
    local cur = #text
    pcall(function() cur = inp.javaObject:getCursorPos() end)
    return math.max(0, math.min(#text, tonumber(cur) or #text))
end
DC.cursorOf = cursorOf

local function lineCol(text, cur)
    cur = math.max(0, math.min(#text, cur))
    local line, at, p = 0, 0, 1
    while true do
        local e = string.find(text, "\n", p, true)
        if not e or e > cur then break end
        line, at, p = line + 1, e, e + 1
    end
    return line, cur - at
end
DC.lineCol = lineCol

local function padInfo(win, text)
    local c = win._padInfo
    if c and c.text == text then return c end
    local starts, p = { 0 }, 1
    while true do
        local e = string.find(text, "\n", p, true)
        if not e then break end
        starts[#starts + 1] = e
        p = e + 1
    end
    c = { text = text, starts = starts, n = #starts, cr = string.find(text, "\r", 1, true) ~= nil, blank = blank(text) }
    win._padInfo = c
    return c
end

local function lineAt(c, pos)
    local s = c.starts
    local lo, hi = 1, #s
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if s[mid] <= pos then lo = mid else hi = mid - 1 end
    end
    return lo - 1
end

local function padSlice(c, li, left, cols)
    local a = c.starts[li + 1]
    if not a then return nil end
    local nxt = c.starts[li + 2]
    local e = nxt and (nxt - 1) or #c.text
    if c.cr then
        local s = string.gsub(string.sub(c.text, a + 1, e), "\r", "")
        return string.sub(s, left + 1, left + cols)
    end
    return string.sub(c.text, a + 1 + left, math.min(e, a + left + cols))
end

local function setCursor(inp, text, cur, line)
    pcall(function()
        local j = inp.javaObject
        j:setMultipleLine(false)
        j:setCursorPos(cur)
        j:setMultipleLine(true)
        j:setCursorLine(line or (lineCol(text, cur)))
    end)
end

function W:_padSet(text, cur)
    text = tostring(text or "")
    cur = math.max(0, math.min(#text, cur or #text))
    self.pad:setText(text)
    setCursor(self.pad, text, cur, lineAt(padInfo(self, text), cur))
    self._padPrev, self._padCur = text, cur
end

local function shiftDown()
    local ok, v = pcall(function() return isShiftKeyDown() end)
    return ok and v == true
end

function W:_padKeys()
    local inp = self.pad
    if not inp or self.mode ~= "pad" then return end
    local text = self:padText()
    local prev, pc = self._padPrev, self._padCur
    if prev and pc and text ~= prev and #text == #prev + 1 and inp:isFocused()
        and not (self._kbOpen and self._kbEntry == inp)
        and text:sub(1, pc) == prev:sub(1, pc) and text:sub(pc + 2) == prev:sub(pc + 1) then
        local ch = text:sub(pc + 1, pc + 1)
        if ch == "\n" and self.ac and not shiftDown() then
            self:_padSet(prev, pc)
            self:acTake()
            return
        elseif ch == "\t" and self.ac then
            self:_padSet(prev, pc)
            self:acTake()
            return
        elseif ch == "\n" and not shiftDown() then
            self:_padSet(prev, pc)
            self:runPad()
            return
        end
    end
    self._padPrev, self._padCur = text, cursorOf(inp, text)
end

function W:_padHold()
    local text = self:padText()
    if self._padPrev == text and self._padCur then setCursor(self.pad, text, self._padCur, lineAt(padInfo(self, text), self._padCur)) end
end

function W:_acSource()
    if self.page ~= "log" or self.naming then return nil end
    local inp = self.mode == "pad" and self.pad or self.input
    if not inp then return nil end
    if inp:isFocused() or (self._kbOpen and self._kbEntry == inp) or self.zone == "ac" then return inp end
    return nil
end

function W:_acUpdate()
    local inp = self:_acSource()
    if not inp then
        self.ac, self._acKey = nil, nil
        if self.zone == "ac" then self.zone = "input" end
        return
    end
    local text = tostring(inp:getText() or "")
    local cur = cursorOf(inp, text)
    local k = self._acKey
    if k and k.inp == inp and k.cur == cur and k.text == text then return end
    k = { inp = inp, cur = cur, text = text }
    self._acKey = k
    local sk = self._acShutKey
    if sk and sk.inp == inp and sk.cur == cur and sk.text == text then self.ac = nil; return end
    self._acShutKey = nil
    local ok, ac = pcall(AC.complete, text, cur)
    if not ok then LC93.logOnce("lua console suggestions", ac); ac = nil end
    local was = self.ac and self.ac.items[self.acI]
    self.ac, self.acI = ac, 1
    if ac and was then
        for i, it in ipairs(ac.items) do if it.n == was.n then self.acI = i end end
    end
    if not ac and self.zone == "ac" then self.zone = "input" end
end

function W:acMove(d)
    local ac = self.ac
    if not ac then return end
    self.acI = math.max(1, math.min(#ac.items, self.acI + d))
    sound()
end

function W:acShut()
    if not self.ac then return end
    self._acShutKey = self._acKey
    self.ac = nil
    if self.zone == "ac" then self.zone = "input" end
end

function W:acTake(i)
    local ac = self.ac
    if not ac or not ac.items[i or self.acI] then return false end
    local pad = self.mode == "pad"
    local text = pad and self:padText() or self:lineText()
    local t, cur = AC.take(text, ac, i or self.acI)
    if pad then
        self:_padSet(t, cur)
    else
        if #t > LINE_MAX then
            self._status = { text = tr("UI_LC93_Console_LineFull", LINE_MAX), color = LC93.T.warning, lineFull = true }
            return false
        end
        self.input:setText(t)
        pcall(function() self.input.javaObject:setCursorPos(cur) end)
    end
    if self._status and self._status.lineFull then self._status = nil end
    self.ac, self._acKey = nil, nil
    if self.zone == "ac" then self.zone = "input" end
    sound()
    return true
end

function W:padArrow(d)
    local prev, pc = self._padPrev or self:padText(), self._padCur or 0
    if d < 0 and prev:sub(1, pc):find("\n", 1, true) then return end
    if d > 0 and prev:sub(pc + 1):find("\n", 1, true) then return end
    self:padHistory(d)
end

function W:padHistory(d)
    S.load()
    local list = S.history
    if #list == 0 then return false end
    if self.phi == nil then
        if d > 0 then return false end
        self.pdraft = self:padText()
        self.phi = #list
    else
        self.phi = self.phi + d
    end
    if self.phi < 1 then self.phi = 1 end
    local text
    if self.phi > #list then
        self.phi = nil
        text = self.pdraft or ""
    else
        text = list[self.phi]
    end
    self:_padSet(text, d < 0 and 0 or #text)
    return true
end

function W:runPad()
    local text = self:padText()
    if blank(text) or not DC.allowed() then return end
    if not S.canRun() then
        self._status = { text = tr("UI_LC93_Console_HelpNoLoad"), color = LC93.T.danger }
        return
    end
    local typing = self.pad:isFocused()
    self._status = nil
    S.run(text)
    self:_padSet("", 0)
    self.phi, self.pdraft = nil, ""
    self.scroll, self.pick = 0, nil
    if typing then self.pad:focus() end
end

function W:setMode(m)
    if self.mode == m then return end
    if self.naming then self:nameDone(false) end
    local typing = self.input:isFocused() or self.pad:isFocused()
    if m == "pad" then
        S.load()
        local line = self:lineText()
        if blank(self:padText()) and not blank(line) then self:_padSet(line) end
        self.input:setText("")
        self.input:unfocus()
        self.hi = nil
        self.mode = "pad"
        if typing then self.pad:focus() end
    else
        local t = self:padText()
        if blank(self:lineText()) and not t:find("\n", 1, true) and #t <= LINE_MAX then self.input:setText(t) end
        self.pad:unfocus()
        self.mode = "line"
        if typing then self.input:focus() end
        if self.zone == "side" then self.zone = "input" end
    end
    sound()
end

function W:loadCode(code, phi)
    self:_padSet(code)
    self.phi = phi
    self._status = nil
    sound()
    if not self.joyfocus then self.pad:focus() end
end

function W:startNaming(kind, i)
    local name
    if kind == "rename" then
        local s = S.snippets[i]
        if not s then return end
        name = s.name
    else
        if blank(self:padText()) then return end
        name = S.nameFrom(self:padText())
    end
    sound("UIActivateButton")
    self.naming = { kind = kind, i = i }
    self.nameE:setText(name)
    self._status = nil
    if self.joyfocus then self.zone, self.bandFocus = "band", 1 else self.nameE:focus() end
end

function W:nameDone(ok)
    local n = self.naming
    if not n then return end
    local T = LC93.T
    local name = tostring(self.nameE:getText() or "")
    if ok and blank(name) then return end
    if ok then
        if n.kind == "rename" then
            local done, wrote = S.rename(n.i, name)
            if not done then return end
            self._status = wrote and { text = tr("UI_LC93_Console_Renamed", S.snippets[n.i].name), color = T.positive }
                or { text = tr("UI_LC93_Console_ExportFailed", S.SNIP_FILE), color = T.danger }
        else
            local i, wrote = S.saveSnippet(name, self:padText())
            if not i then return end
            self._status = wrote and { text = tr("UI_LC93_Console_Saved", S.snippets[i].name), color = T.positive }
                or { text = tr("UI_LC93_Console_ExportFailed", S.SNIP_FILE), color = T.danger }
        end
        sound("UIActivateButton")
    end
    self.naming = nil
    self.nameE:unfocus()
    self.nameE:setText("")
    if self.zone == "band" then self.bandFocus = RUN_AT end
end

function W:copyText()
    if self.pick then return table.concat(L.rowText(self.pick), "\n") end
    return L.shownText()
end

function W:export()
    local shown = L.counts()
    if shown == 0 then return end
    local name, n, tried = L.export()
    local T = LC93.T
    if name then
        self._status = { text = tr("UI_LC93_Console_Exported", n, name), color = T.positive }
        DC.lastExport = name
    else
        self._status = { text = tr("UI_LC93_Console_ExportFailed", tried or ""), color = T.danger }
    end
end

function W:press(id)
    if self.page ~= "log" and self._pagePress and self:_pagePress(id) then return end
    if id == "run" then
        if self.mode == "pad" then
            if blank(self:padText()) or not DC.allowed() then return end
            sound("UIActivateButton")
            self:runPad()
            return
        end
        if blank(self:lineText()) or not DC.allowed() then return end
        sound("UIActivateButton")
        self:runLine()
        return
    end
    if id == "topad" then self:setMode("pad"); return end
    if id == "toline" then self:setMode("line"); return end
    if id == "save" then self:startNaming("save"); return end
    if id == "nsave" then self:nameDone(true); return end
    if id == "ncancel" then sound("UIActivateButton"); self:nameDone(false); return end
    local shown, total = L.counts()
    if id == "export" then
        if shown == 0 then return end
        sound("UIActivateButton")
        self:export()
        return
    end
    if total == 0 and DC.text == "" then return end
    sound("UIActivateButton")
    self._status = nil
    if id == "clear" then
        DC.clear()
        self.pick, self.scroll, self.opened = nil, 0, {}
    elseif id == "copy" then
        local text = self:copyText()
        pcall(function() Clipboard.setClipboard(text) end)
        DC.lastCopy = text
        self._copiedUntil = getTimestampMs() + COPIED_MS
    end
end

function W:closeAction() sound("UIActivateButton"); self:close() end

function W:close(keepFlag)
    if not keepFlag and P.jc then pcall(function() P.jc:setVisible(false) end) end
    if self.input then self.input:unfocus() end
    if self.find then self.find:unfocus() end
    if self.pad then self.pad:unfocus() end
    if self.naming then self:nameDone(false) end
    self.ac = nil
    local mine = self._pageClose and self:_pageClose() or {}
    local KB = LC93.Keyboard
    local kbe = KB and KB.instance and KB.instance.textEntryBox
    if kbe and (kbe == self.input or kbe == self.find or kbe == self.pad or kbe == self.nameE or mine[kbe]) then pcall(function() KB.instance:hide() end) end
    self._kbOpen = nil
    DC.mirror("")
    DC.place = { x = self:getX(), y = self:getY(), w = self:getWidth(), h = self.windowShaded and (self.preShadeHeight or self:getHeight()) or self:getHeight() }
    self:setVisible(false)
    self:removeFromUIManager()
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then setJoypadFocus(self.playerNum, nil) end
    self.joyfocus = nil
end

local _fo = {}
local function focusOpts(win)
    _fo.win, _fo.focused, _fo.pad = win, true, true
    return _fo
end
local function mark(win, x, y, w, h)
    if LC93.Focus and LC93.Focus.mark then return LC93.Focus.mark(win, x, y, w, h, focusOpts(win)) and true or false end
    return false
end

local function charW(font)
    return math.max(1, LC93.TM:MeasureStringX(font, "0000000000") / 10)
end

function W:_drawTyped(inp, x, y, w, h, f, focused, placeholder, st)
    local T = LC93.T
    st = st or self
    local text = inp:getText() or ""
    local cur = #text
    pcall(function() cur = inp.javaObject:getCursorPos() end)
    cur = math.max(0, math.min(#text, cur or #text))
    local cw = charW(f)
    local n = math.max(1, math.floor((w - px(2)) / cw))
    local start = st._typeStart or 0
    if cur < start then start = cur end
    if cur > start + n then start = cur - n end
    start = math.max(0, math.min(start, math.max(0, #text - n)))
    st._typeStart, st._typeX, st._typeCw = start, x, cw
    local ty = y + math.floor((h - fh(f)) / 2)
    if text == "" then
        local d = T.textDim
        if not focused then self:drawText(placeholder, x, ty, d.r, d.g, d.b, d.a or 1, f) end
    else
        local c = T.text
        self:drawText(text:sub(start + 1, start + n), x, ty, c.r, c.g, c.b, c.a or 1, f)
    end
    if focused then
        local a = T.accent
        self:drawRect(x + (cur - start) * cw, ty, math.max(1, px(1)), fh(f), a.a or 1, a.r, a.g, a.b)
    end
end

local function parkEntry(inp, ew, y, ih)
    local offX = -(ew + px(60))
    if inp:getX() ~= offX then inp:setX(offX) end
    if inp:getY() ~= y then inp:setY(y) end
    if inp:getWidth() ~= ew then inp:setWidth(ew) end
    if inp:getHeight() ~= ih then inp:setHeight(ih) end
end

local function placeCursor(inp, st, x)
    if not (st._typeCw and st._typeX) then return end
    local col = (st._typeStart or 0) + math.floor((x - st._typeX) / st._typeCw + 0.5)
    local len = #(inp:getText() or "")
    col = math.max(0, math.min(len, col))
    pcall(function() inp.javaObject:setCursorPos(col) end)
end

function W:prerender()
    local T = LC93.T
    if not T then return end
    if not DC.exists() then self:close(true); return end
    self.minimumWidth, self.minimumHeight = px(U.MIN_W), px(U.MIN_H)
    self.title = tr("UI_LC93_Console_Title")
    local errs = L.errTotal or 0
    if errs > 0 then
        self._stat = self._stat or { {} }
        local st = self._stat[1]
        st.text, st.color = tr("UI_LC93_Console_Errors", errs), T.danger
        self.titleStats = self._stat
    else
        self.titleStats = {}
    end
    if self.find then
        local q = tostring(self.find:getText() or "")
        if q ~= L.q then L.setQuery(q); self.scroll = 0 end
    end
    self:_padKeys()
    self:_acUpdate()
    LC93_Window.prerender(self)
    if self.windowShaded or self.isCollapsed then return end
    local ok, err = pcall(self._drawBody, self)
    if not ok then LC93.logOnce("lua console", err) end
end

function W:_drawBody()
    local T = LC93.T
    local M = LC93.Molecules
    local w = self.width
    local pad, gap = px(U.PAD), px(U.GAP)
    local top = self:titleBarHeight()
    local bot = self.height - self:footerHeight()
    local bandH = M.bandH()
    local bandY = bot - bandH
    local ih = T.inputH
    local joy = self.joyfocus ~= nil
    self._keyHits = {}
    self._acRect, self._acHits = nil, nil
    if self.page ~= "log" then
        self._filterRect, self._headRect, self._findRect, self._fieldRect, self._padRect, self._sideRect = nil, nil, nil, nil, nil, nil
        self._listRect, self._rowHits, self._bandRects = nil, {}, {}
        local sw = px(U.STRIP)
        self:_drawStrip(0, top, sw, bandY - top, joy)
        if self._drawPage then
            self:_drawPage(sw, top, w - sw, bandY - top, bandY, joy)
        else
            LC93.Molecules.drawEmptyLine(self, sw + pad * 2, top + pad * 2, w - sw - pad * 4, tr("UI_LC93_Console_Coming"))
        end
        return
    end
    local areaH = ih
    local noteH, boxH = 0, 0
    if self.mode == "pad" then
        local sw0 = px(U.STRIP)
        local cx0 = sw0 + (self.page == "log" and math.min(px(U.FILTERS), math.floor((w - sw0) * 0.36)) or 0)
        local room = math.floor((bandY - top) * 0.6) - px(U.META) - px(U.PADMIN)
        if not S.canRun() then noteH = math.max(0, math.min(self:_noteHeight(w - cx0 - 2 * pad) + gap, room)) end
        boxH = math.max(px(U.PADMIN), math.min(px(U.PADBOX), math.floor((bandY - top) * 0.5) - noteH - px(U.META)))
        areaH = noteH + px(U.META) + boxH
    end
    local iy = bandY - pad - areaH
    DC.mirror(self:lineText())

    local sw = px(U.STRIP)
    self:_drawStrip(0, top, sw, bandY - top, joy)
    local fw = math.min(px(U.FILTERS), math.floor((w - sw) * 0.36))
    self._filterRect = { x = sw, y = top, w = fw, h = bandY - top }
    self:_drawFilters(sw, top, fw, bandY - top, joy)
    local cx = sw + fw
    local hh = px(U.HEAD)
    self:_drawHead(cx, top, w - cx, hh, joy)
    local ly0, ly1 = top + hh + px(4), iy - gap
    self._listRect = { x = cx + pad, y = ly0, w = w - cx - 2 * pad, h = math.max(0, ly1 - ly0) }
    self:_drawList(cx + pad, ly0, w - cx - 2 * pad, math.max(0, ly1 - ly0))
    self._caret = nil
    if self.mode == "pad" then
        self._fieldRect = nil
        self:_drawPad(cx + pad, iy, w - cx - 2 * pad, noteH, boxH, joy)
    else
        self._padRect, self._sideRect = nil, nil
        self:_drawLine(cx + pad, iy, w - cx - 2 * pad, ih, joy)
    end
    if self.naming then self:_drawNameBand(bandY, w, joy) else self:_drawBand(bandY, w, joy) end
    if self.ac and self._caret then self:_drawAc(top, bandY, joy) end
end

local AC_KIND = { ["function"] = "UI_LC93_Console_AcFunction", table = "UI_LC93_Console_AcTable", Java = "UI_LC93_Console_AcJava", value = "UI_LC93_Console_AcValue" }
local function acColor(k)
    local T = LC93.T
    if k == "Java" then return T.warning end
    if k == "table" then return T.accent end
    return T.textDim
end

local function acFoot(ac)
    local head
    if not ac.base then head = tr("UI_LC93_Console_AcGlobals")
    elseif ac.java then head = tr("UI_LC93_Console_AcJavaOf", ac.base)
    elseif ac.sep == ":" then head = tr("UI_LC93_Console_AcMethodsOf", ac.base)
    else head = tr("UI_LC93_Console_AcFieldsOf", ac.base) end
    if (ac.more or 0) > 0 then head = head .. " | " .. tr("UI_LC93_Console_AcMore", ac.more) end
    return head
end

function W:_drawAc(top, bottom, joy)
    local T = LC93.T
    local A = LC93.Atoms
    local ac, cr = self.ac, self._caret
    local f3 = T.fontF3
    local rowH = math.max(px(U.ACROW), fh(f3) + px(4))
    local footH = fh(f3) + px(6)
    local kindW = px(U.ACKIND)
    local nameW = 0
    for _, it in ipairs(ac.items) do
        nameW = math.max(nameW, LC93.TM:MeasureStringX(f3, it.n .. (AC.signature(it) or "")))
    end
    local w = math.max(px(U.ACMIN), math.min(px(U.ACMAX), nameW + kindW + px(24)))
    w = math.min(w, self.width - px(16))
    local h = #ac.items * rowH + footH + px(2)
    local x = math.max(px(8), math.min(cr.x - px(4), self.width - w - px(8)))
    local y = cr.y - h - px(2)
    if y < top then y = math.min(cr.y + cr.h + px(2), bottom - h) end
    y = math.max(top, y)
    local s1, bs = T.surf1, T.borderS
    self:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
    self:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
    local mx, my = self:getMouseX(), self:getMouseY()
    if joy then mx, my = nil, nil end
    self._acRect = { x = x, y = y, w = w, h = h }
    self._acHits = {}
    local sq = px(U.MARK)
    for i, it in ipairs(ac.items) do
        local ry = y + px(1) + (i - 1) * rowH
        local rx, rw = x + px(1), w - px(2)
        local picked = i == self.acI
        local hover = mx ~= nil and mx >= rx and mx < rx + rw and my >= ry and my < ry + rowH
        local onFocus = false
        if picked then
            local a = T.accent
            self:drawRect(rx, ry, rw, rowH, a.a or 1, a.r, a.g, a.b)
            if joy and self.zone == "ac" then onFocus = mark(self, rx, ry, rw, rowH) end
        elseif hover then
            local hv = T.hover
            self:drawRect(rx, ry, rw, rowH, hv.a or 1, hv.r, hv.g, hv.b)
        end
        local tc = onFocus and T.textOnFocus or (picked and T.textOnAccent or T.text)
        local dc = onFocus and T.textOnFocus or (picked and T.textOnAccent or T.textDim)
        local ty = ry + math.floor((rowH - fh(f3)) / 2)
        local word = tr(AC_KIND[it.k] or AC_KIND.value)
        local kx = rx + rw - px(8) - kindW
        A.drawStatusDot(self, kx, ry + math.floor((rowH - sq) / 2), picked and tc or acColor(it.k), sq)
        self:drawText(A.truncateText(word, f3, kindW - sq - px(5)), kx + sq + px(5), ty, dc.r, dc.g, dc.b, dc.a or 1, f3)
        local room = kx - px(8) - (rx + px(7))
        local name = A.truncateText(it.n, f3, room)
        self:drawText(name, rx + px(7), ty, tc.r, tc.g, tc.b, tc.a or 1, f3)
        local sig = AC.signature(it)
        local nw = LC93.TM:MeasureStringX(f3, name)
        if sig and name == it.n and nw + LC93.TM:MeasureStringX(f3, sig) <= room then
            self:drawText(sig, rx + px(7) + nw, ty, dc.r, dc.g, dc.b, dc.a or 1, f3)
        end
        self._acHits[i] = { x = rx, y = ry, w = rw, h = rowH }
    end
    local fy = y + px(1) + #ac.items * rowH
    A.drawDividerH(self, x + px(1), fy, w - px(2))
    local td = T.textDim
    self:drawText(A.truncateText(acFoot(ac), f3, w - px(16)), x + px(8), fy + math.floor((footH - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
end

local _kc = {}
function W:_keycap(id, xr, y, h, label, variant, help, joy)
    local T = LC93.T
    local M = LC93.Molecules
    local bw = M.buttonW(label)
    local bh = T.buttonH - px(4)
    local x = xr - bw
    local by = y + math.floor((h - bh) / 2)
    _kc.win, _kc.help = self, help
    _kc.hover = (not joy) and LC93.Atoms.mouseIn(self, x, by, bw, bh) or false
    M.drawButton(self, x, by, bw, bh, label, variant, self._down == id, nil, _kc)
    self._keyHits[#self._keyHits + 1] = { x = x, y = by, w = bw, h = bh, id = id }
    return x
end

function W:_drawLine(fx, iy, fw, ih, joy)
    local T = LC93.T
    local inp = self.input
    local kx = self:_keycap("topad", fx + fw, iy, ih, btn(tr("UI_LC93_Console_Scratchpad")), "default", tr("UI_LC93_Console_HelpToPad"), joy)
    fw = kx - px(U.GAP) - fx
    local s1, bs = T.surf1, T.borderS
    self:drawRect(fx, iy, fw, ih, s1.a or 1, s1.r, s1.g, s1.b)
    local focused = inp and inp:isFocused()
    local ib = focused and T.accent or bs
    self:drawRectBorder(fx, iy, fw, ih, ib.a or 1, ib.r, ib.g, ib.b)
    local f3 = T.fontF3
    local mx0 = fx + px(6)
    local td = T.textDim
    self:drawText(">", mx0, iy + math.floor((ih - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
    local ex = mx0 + LC93.TM:MeasureStringX(f3, ">") + px(4)
    if inp then
        local ew = fx + fw - px(4) - ex
        parkEntry(inp, ew, iy, ih)
        self:_drawTyped(inp, ex, iy, ew, ih, f3, focused, tr("UI_LC93_Console_Type"), self)
        local t = self:lineText()
        self._caret = { x = ex + (cursorOf(inp, t) - (self._typeStart or 0)) * (self._typeCw or charW(f3)), y = iy, h = ih, top = iy }
    end
    if joy and self.zone == "input" then mark(self, fx, iy, fw, ih) end
    self._fieldRect = { x = fx, y = iy, w = fw, h = ih }
end

function W:_noteLines(w)
    local T = LC93.T
    local tw = w - px(8) * 2 - px(U.MARK) - px(8)
    local key = tostring(tw) .. "|" .. tostring(T.fontF2)
    if self._noteKey ~= key then
        self._noteKey = key
        local A = LC93.Atoms
        local out = {}
        for _, s in ipairs(A.wrapText(tr("UI_LC93_Console_NoLoad"), T.fontF2, math.max(1, tw))) do out[#out + 1] = { s = s, head = true } end
        for _, s in ipairs(A.wrapText(tr("UI_LC93_Console_NoLoadBody"), T.fontF2, math.max(1, tw))) do out[#out + 1] = { s = s } end
        self._note = out
    end
    return self._note
end
function W:_noteHeight(w)
    return #self:_noteLines(w) * (fh(LC93.T.fontF2) + px(2)) + px(12)
end

function W:_drawNote(x, y, w, h)
    local T = LC93.T
    local s2, bs = T.surf2, T.borderS
    self:drawRect(x, y, w, h, s2.a or 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
    local f2 = T.fontF2
    local step = fh(f2) + px(2)
    local sq = px(U.MARK)
    if h < fh(f2) + px(6) then return end
    LC93.Atoms.drawStatusDot(self, x + px(8), y + px(6) + math.floor((fh(f2) - sq) / 2), T.danger, sq)
    local tx = x + px(8) + sq + px(8)
    for i, ln in ipairs(self:_noteLines(w)) do
        local ly = y + px(6) + (i - 1) * step
        if ly + fh(f2) > y + h then break end
        local c = ln.head and T.text or T.textDim
        self:drawText(ln.s, tx, ly, c.r, c.g, c.b, c.a or 1, f2)
    end
end

function W:_drawPad(x, y, w, noteH, boxH, joy)
    local T = LC93.T
    local off = not S.canRun()
    if noteH > px(U.GAP) then
        self:_drawNote(x, y, w, noteH - px(U.GAP))
        y = y + noteH
    end
    local mh = px(U.META)
    local text = self:padText()
    local f3 = T.fontF3
    local td = T.textDim
    local meta = tr("UI_LC93_Console_Scratchpad") .. " | " .. tr("UI_LC93_Console_PadMeta", padInfo(self, text).n, #text)
    local kx = self:_keycap("toline", x + w, y, mh - px(4), btn(tr("UI_LC93_Console_OneLine")), off and "primary" or "default", tr("UI_LC93_Console_HelpToLine"), joy)
    kx = self:_keycap("save", kx - px(U.GAP), y, mh - px(4), btn(tr("UI_LC93_Console_SaveSnippet")), "default", tr("UI_LC93_Console_HelpSave"), joy)
    meta = LC93.Atoms.truncateText(meta, f3, math.max(0, kx - px(8) - x))
    self:drawText(meta, x, y + math.floor((mh - px(4) - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
    y = y + mh
    local sw = math.min(px(U.SIDE), math.floor(w * 0.4))
    local bw = w - sw - px(U.GAP)
    self:_drawPadBox(x, y, bw, boxH, joy, off)
    self:_drawSide(x + bw + px(U.GAP), y, sw, boxH, joy)
end

function W:_drawPadBox(x, y, w, h, joy, off)
    local T = LC93.T
    local inp = self.pad
    local f = T.fontF3
    local focused = inp:isFocused()
    local s1 = T.surf1
    self:drawRect(x, y, w, h, s1.a or 1, s1.r, s1.g, s1.b)
    local bc = focused and T.accent or T.borderS
    self:drawRectBorder(x, y, w, h, bc.a or 1, bc.r, bc.g, bc.b)
    local gw = px(U.GUT)
    LC93.Atoms.drawDividerV(self, x + gw, y + px(1), h - px(2))
    parkEntry(inp, w - gw, y, h)
    local text = self:padText()
    local info = padInfo(self, text)
    local cur = cursorOf(inp, text)
    local cl = lineAt(info, cur)
    local cc = cur - info.starts[cl + 1]
    local lh = fh(f) + px(2)
    local rows = math.max(1, math.floor((h - px(8)) / lh))
    local cw = charW(f)
    local tx = x + gw + px(6)
    local cols = math.max(1, math.floor((x + w - px(4) - tx) / cw))
    local st = self._padSt
    local top, left = st.top or 0, st.left or 0
    if cl < top then top = cl elseif cl >= top + rows then top = cl - rows + 1 end
    top = math.max(0, math.min(top, math.max(0, info.n - rows), cl))
    if cc < left then left = cc elseif cc > left + cols then left = cc - cols end
    st.top, st.left, st.tx, st.ty, st.lh, st.cw = top, left, tx, y + px(4), lh, cw
    local alpha = off and (T.disabledAlpha or 0.4) or 1
    local tc, dc = T.text, T.textDim
    self:setStencilRect(x + px(1), y + px(1), w - px(2), h - px(2))
    for r = 0, rows - 1 do
        local li = top + r
        local ly = y + px(4) + r * lh
        local ns = tostring(li + 1)
        self:drawText(ns, x + gw - px(4) - LC93.TM:MeasureStringX(f, ns), ly, dc.r, dc.g, dc.b, (dc.a or 1) * alpha, f)
        local s = padSlice(info, li, left, cols)
        if s and s ~= "" then self:drawText(s, tx, ly, tc.r, tc.g, tc.b, (tc.a or 1) * alpha, f) end
    end
    if text == "" and not focused then
        self:drawText(tr("UI_LC93_Console_Type"), tx, y + px(4), dc.r, dc.g, dc.b, (dc.a or 1) * alpha, f)
    end
    if focused then
        local a = T.accent
        self:drawRect(tx + (cc - left) * cw, y + px(4) + (cl - top) * lh, math.max(1, px(1)), fh(f), a.a or 1, a.r, a.g, a.b)
    end
    self._caret = { x = tx + (cc - left) * cw, y = y + px(4) + (cl - top) * lh, h = lh, top = y }
    self:clearStencilRect()
    if joy and self.zone == "input" then mark(self, x, y, w, h) end
    self._padRect = { x = x, y = y, w = w, h = h }
end

function W:padClick(mx, my)
    local st = self._padSt
    if not (st.lh and st.cw) then return end
    local text = self:padText()
    local info = padInfo(self, text)
    local li = math.max(0, math.min(info.n - 1, (st.top or 0) + math.floor((my - st.ty) / st.lh)))
    local col = math.max(0, (st.left or 0) + math.floor((mx - st.tx) / st.cw + 0.5))
    local pos = info.starts[li + 1] + math.min(col, #padSlice(info, li, 0, #text))
    setCursor(self.pad, text, pos, li)
    self._padCur = pos
end

function W:_sideItems()
    local key = tostring(S.rev) .. "|" .. tostring(self.sFold.snips) .. tostring(self.sFold.hist)
    if self._sKey == key and self._sItems then return self._sItems end
    local items = { { t = "fold", g = "snips", label = "UI_LC93_Console_FoldSnippets", n = #S.snippets } }
    if not self.sFold.snips then
        for i = 1, #S.snippets do items[#items + 1] = { t = "snip", i = i, ns = tostring(S.lineCount(S.snippets[i].code)) } end
    end
    items[#items + 1] = { t = "fold", g = "hist", label = "UI_LC93_Console_FoldHistory", n = #S.history }
    if not self.sFold.hist then
        for i = #S.history, 1, -1 do items[#items + 1] = { t = "hist", i = i, first = string.match(S.history[i] or "", "^([^\n]*)") or "" } end
    end
    self._sKey, self._sItems = key, items
    if self.sFocus > #items then self.sFocus = #items end
    return items
end

function W:_drawSide(x, y, w, h, joy)
    local T = LC93.T
    local M = LC93.Molecules
    local bs = T.border or T.borderS
    self:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
    local items = self:_sideItems()
    local foldH, rowH = px(U.FOLD), px(U.FROW)
    local total = px(4)
    for _, it in ipairs(items) do total = total + (it.t == "fold" and foldH or rowH) end
    local bar = total > h
    local sbW = T.sp.scrollbarW
    local iw = w - (bar and sbW or 0)
    if self.sSeek then
        self.sSeek = nil
        local yy = px(4)
        for i, it in ipairs(items) do
            local ih = it.t == "fold" and foldH or rowH
            if i == self.sFocus then
                if yy < self.sScroll then self.sScroll = yy elseif yy + ih > self.sScroll + h then self.sScroll = yy + ih - h end
                break
            end
            yy = yy + ih
        end
    end
    self.sScroll = math.max(0, math.min(math.max(0, total - h), self.sScroll))
    self._sMax = math.max(0, total - h)
    local mx, my = self:getMouseX(), self:getMouseY()
    if joy then mx, my = nil, nil end
    self._sHits = {}
    self:setStencilRect(x + px(1), y + px(1), w - px(2), h - px(2))
    local yy = y + px(4) - self.sScroll
    for i, it in ipairs(items) do
        local ih = it.t == "fold" and foldH or rowH
        if yy + ih > y and yy < y + h then
            local hover = mx ~= nil and mx >= x and mx < x + iw and my >= yy and my < yy + ih and my >= y and my < y + h
            local foc = joy and self.zone == "side" and self.sFocus == i
            if it.t == "fold" then
                M.drawSectionHeader(self, x + px(8), yy, iw - px(8), tr(it.label), it.n, not self.sFold[it.g], hover, nil, true, px(8), ih, nil, foc and { focus = focusOpts(self) } or nil)
            else
                self:_drawSideRow(it, x + px(1), yy, iw - px(2), ih, hover, foc)
            end
            self._sHits[#self._sHits + 1] = { y = yy, h = ih, i = i }
        end
        yy = yy + ih
    end
    self:clearStencilRect()
    if bar then
        local win = self
        M.scrollBar(self, nil, "side", x + w - sbW, y, sbW, h, self.sScroll, total, function(v) win.sScroll = v end, { step = rowH })
    end
    self._sideRect = { x = x, y = y, w = w, h = h }
end

function W:_drawSideRow(it, x, y, w, h, hover, foc)
    local T = LC93.T
    local A = LC93.Atoms
    local shown = it.t == "hist" and self.phi == it.i
    if shown then
        local ac = T.accent
        self:drawRect(x, y, w, h, T.selectionA or 0.25, ac.r, ac.g, ac.b)
    elseif hover then
        local hv = T.hover
        self:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
    end
    if hover then LC93.Help.set(self, tr(it.t == "snip" and "UI_LC93_Console_HelpSnippet" or "UI_LC93_Console_HelpHistory")) end
    local onFocus = foc and mark(self, x, y, w, h) or false
    local tc = onFocus and T.textOnFocus or T.text
    local dc = onFocus and T.textOnFocus or T.textDim
    local tx = x + px(19)
    if it.t == "snip" then
        local s = S.snippets[it.i]
        local f2, f3 = T.fontF2, T.fontF3
        local ns = it.ns or tostring(S.lineCount(s.code))
        local nw = LC93.TM:MeasureStringX(f3, ns)
        self:drawText(ns, x + w - px(8) - nw, y + math.floor((h - fh(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
        local name = A.truncateText(s.name, f2, math.max(0, x + w - px(14) - nw - tx))
        self:drawText(name, tx, y + math.floor((h - fh(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    else
        local f3 = T.fontF3
        local first = it.first or (S.history[it.i] or ""):match("^([^\n]*)") or ""
        first = A.truncateText(first, f3, math.max(0, x + w - px(6) - tx))
        self:drawText(first, tx, y + math.floor((h - fh(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    end
end

function W:useSide(it)
    if not it then return end
    if it.t == "fold" then
        sound()
        if self.sFold[it.g] then self.sFold[it.g] = nil else self.sFold[it.g] = true end
    elseif it.t == "snip" then
        local s = S.snippets[it.i]
        if s then self:loadCode(s.code, nil) end
    elseif it.t == "hist" then
        local c = S.history[it.i]
        if c then self.pdraft = self.phi == nil and self:padText() or self.pdraft; self:loadCode(c, it.i) end
    end
end

function W:sideItemAt(y)
    for _, hit in ipairs(self._sHits or {}) do
        if y >= hit.y and y < hit.y + hit.h then return hit.i, self:_sideItems()[hit.i] end
    end
    return nil
end

local _nBtns = { { id = "ncancel" }, { id = "nsave", variant = "primary" } }
local _nSpec = { buttons = _nBtns }
local NAME_BAND = { "name", "ncancel", "nsave" }
function W:_drawNameBand(y, w, joy)
    local T = LC93.T
    local c, s = _nBtns[1], _nBtns[2]
    c.label, s.label = btn(getText("UI_Cancel")), btn(tr("UI_LC93_Console_Save"))
    local blankName = blank(tostring(self.nameE:getText() or ""))
    s.disabled = blankName
    for i, b in ipairs(_nBtns) do
        b.focus = (joy and self.zone == "band" and self.bandFocus == i + 1) and focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
    end
    _nSpec.win = self
    local _, out = LC93.Molecules.drawBand(self, 0, y, w, _nSpec)
    self._bandRects = out and out.buttons or {}
    local first = self._bandRects[1]
    local ih = T.inputH
    local fx = px(8)
    local fw = math.max(px(60), (first and first.x or w - px(8)) - px(8) - fx)
    local fy = y + math.floor((LC93.Molecules.bandH() - ih) / 2)
    local s1 = T.base or T.surf1
    self:drawRect(fx, fy, fw, ih, s1.a or 1, s1.r, s1.g, s1.b)
    local focused = self.nameE:isFocused()
    local bc = focused and T.accent or T.borderS
    self:drawRectBorder(fx, fy, fw, ih, bc.a or 1, bc.r, bc.g, bc.b)
    parkEntry(self.nameE, fw - px(12), fy, ih)
    self:_drawTyped(self.nameE, fx + px(6), fy, fw - px(12), ih, T.fontF3, focused, tr("UI_LC93_Console_Name"), self._nameSt)
    if joy and self.zone == "band" and self.bandFocus == 1 then mark(self, fx, fy, fw, ih) end
    self._nameRect = { x = fx, y = fy, w = fw, h = ih }
end

function W:_drawStrip(x, y, w, h, joy)
    local T = LC93.T
    local A = LC93.Atoms
    A.drawDividerV(self, x + w - px(1), y, h)
    local cell = math.max(1, math.floor(px(1.6) + 0.5))
    local size = U.ICON * cell
    local th = px(32)
    local mx, my = self:getMouseX(), self:getMouseY()
    self._stripHits = {}
    for i, pg in ipairs(PAGES) do
        local ty = y + px(2) + (i - 1) * th
        local on = self.page == pg.id
        local hover = not joy and mx >= x and mx < x + w - px(1) and my >= ty and my < ty + th
        if on then
            local a = T.accent
            self:drawRect(x, ty, w - px(1), th, a.a or 1, a.r, a.g, a.b)
        elseif hover then
            local hv = T.hover
            self:drawRect(x, ty, w - px(1), th, hv.a or 1, hv.r, hv.g, hv.b)
        end
        local onFocus = joy and self.zone == "strip" and self.stripFocus == i and mark(self, x, ty, w - px(1), th)
        local c = T.textDim
        if onFocus then c = T.textOnFocus elseif on then c = T.textOnAccent end
        A.drawPxMap(self, pg.map, x + math.floor((w - px(1) - size) / 2), ty + math.floor((th - size) / 2), cell, c)
        self._stripHits[i] = { x = x, y = ty, w = w - px(1), h = th, page = pg.id }
        if hover then LC93.Help.set(self, tr(pg.key)) end
    end
end

local function sortedNames(list, nameOf)
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    table.sort(out, function(a, b)
        if (a == "" or a == L.GAME or a == L.CONSOLE) ~= (b == "" or b == L.GAME or b == L.CONSOLE) then return b == "" or b == L.GAME or b == L.CONSOLE end
        return string.lower(nameOf(a)) < string.lower(nameOf(b))
    end)
    return out
end
function W:_filterItems()
    local key = tostring(L.namesRev) .. "|" .. tostring(self.fold.kind) .. tostring(self.fold.mod) .. tostring(self.fold.file)
    if self._fKey == key and self._fItems then return self._fItems end
    local items = {}
    for _, gr in ipairs(GROUPS) do
        local keys
        if gr.g == "kind" then keys = L.KINDS
        elseif gr.g == "mod" then keys = sortedNames(L.mods, L.modName)
        else keys = sortedNames(L.files, L.fileName) end
        items[#items + 1] = { t = "fold", g = gr.g, label = gr.key, n = #keys }
        if not self.fold[gr.g] then
            for _, k in ipairs(keys) do items[#items + 1] = { t = "cb", g = gr.g, key = k } end
        end
    end
    self._fKey, self._fItems = key, items
    if self.fFocus > #items then self.fFocus = #items end
    return items
end

local function itemLabel(it)
    if it.g == "kind" then return tr(KIND_LABEL[it.key]) end
    if it.g == "mod" then return L.modName(it.key) end
    return L.fileName(it.key)
end

function W:_drawFilters(x, y, w, h, joy)
    local T = LC93.T
    local A = LC93.Atoms
    local M = LC93.Molecules
    A.drawDividerV(self, x + w - px(1), y, h)
    local items = self:_filterItems()
    local foldH, rowH = px(U.FOLD), px(U.FROW)
    local total = px(4)
    for _, it in ipairs(items) do total = total + (it.t == "fold" and foldH or rowH) end
    local bar = total > h
    local sbW = T.sp.scrollbarW
    local iw = w - px(1) - (bar and sbW or 0)
    local maxS = math.max(0, total - h)
    if self.fSeek then
        self.fSeek = nil
        local yy = px(4)
        for i, it in ipairs(items) do
            local ih = it.t == "fold" and foldH or rowH
            if i == self.fFocus then
                if yy < self.fScroll then self.fScroll = yy elseif yy + ih > self.fScroll + h then self.fScroll = yy + ih - h end
                break
            end
            yy = yy + ih
        end
    end
    self.fScroll = math.max(0, math.min(maxS, self.fScroll))
    self._fMax = maxS
    local mx, my = self:getMouseX(), self:getMouseY()
    local Fo = LC93.Input and LC93.Input.Focus
    if joy or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    self._fHits = {}
    self:setStencilRect(x, y, w - px(1), h)
    local yy = y + px(4) - self.fScroll
    local f2, f3 = T.fontF2, T.fontF3
    for i, it in ipairs(items) do
        local ih = it.t == "fold" and foldH or rowH
        if yy + ih > y and yy < y + h then
            local hover = mx ~= nil and mx >= x and mx < x + iw and my >= yy and my < yy + ih
            local foc = joy and self.zone == "filters" and self.fFocus == i
            if it.t == "fold" then
                M.drawSectionHeader(self, x + px(8), yy, iw - px(8), tr(it.label), it.n, not self.fold[it.g], hover, nil, true, px(8), ih, nil, foc and { focus = focusOpts(self) } or nil)
            else
                self:_drawFilterRow(it, x, yy, iw, ih, hover, foc, f2, f3)
            end
            self._fHits[#self._fHits + 1] = { y = yy, h = ih, i = i }
        end
        yy = yy + ih
    end
    self:clearStencilRect()
    if bar then
        local win = self
        M.scrollBar(self, nil, "filters", x + w - px(1) - sbW, y, sbW, h, self.fScroll, total, function(v) win.fScroll = v end, { step = rowH })
    end
end

function W:_drawFilterRow(it, x, y, w, h, hover, foc, f2, f3)
    local T = LC93.T
    local A = LC93.Atoms
    local onFocus = false
    if hover then
        local hv = T.hover
        self:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
        LC93.Help.set(self, tr("UI_LC93_Console_HelpFilter"))
    end
    if foc then onFocus = mark(self, x, y, w, h) end
    local on = L.isOn(it.g, it.key)
    local cb = T.checkboxSz
    local bx = x + px(16)
    A.drawCheckbox(self, bx, y + math.floor((h - cb) / 2), on, hover)
    local tx = bx + cb + px(6)
    if it.g == "kind" then
        local sq = px(U.MARK)
        A.drawStatusDot(self, tx, y + math.floor((h - sq) / 2), kindColor(it.key), sq)
        tx = tx + sq + px(5)
    end
    local n = (L.cnt[it.g] and L.cnt[it.g][it.key]) or 0
    local ns = tostring(n)
    local nw = LC93.TM:MeasureStringX(f3, ns)
    local dc = onFocus and T.textOnFocus or T.textDim
    self:drawText(ns, x + w - px(6) - nw, y + math.floor((h - fh(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    local c = onFocus and T.textOnFocus or (on and T.text or T.textDim)
    local label = A.truncateText(itemLabel(it), f2, math.max(0, x + w - px(12) - nw - tx))
    self:drawText(label, tx, y + math.floor((h - fh(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
end

function W:_drawHead(x, y, w, h, joy)
    local T = LC93.T
    local A = LC93.Atoms
    local pad = px(U.PAD)
    A.drawDividerH(self, x, y + h - px(1), w)
    local shown, total, errs = L.counts()
    local cs = tr("UI_LC93_Console_Count", shown, total, errs)
    local f3 = T.fontF3
    local cw = LC93.TM:MeasureStringX(f3, cs)
    local ih = T.inputH
    local fx, fy = x + pad, y + math.floor((h - ih) / 2)
    local fw = math.max(px(80), w - 2 * pad - cw - px(10))
    local s1 = T.base or T.surf1
    self:drawRect(fx, fy, fw, ih, s1.a or 1, s1.r, s1.g, s1.b)
    local focused = self.find and self.find:isFocused()
    local bc = focused and T.accent or T.borderS
    self:drawRectBorder(fx, fy, fw, ih, bc.a or 1, bc.r, bc.g, bc.b)
    local iw = A.drawSearchIcon(self, fx + px(6), fy, ih)
    local ex = fx + px(6) + iw + px(6)
    local ew = fx + fw - px(4) - ex
    if self.find then
        parkEntry(self.find, ew, fy, ih)
        self:_drawTyped(self.find, ex, fy, ew, ih, f3, focused, tr("UI_LC93_Console_Search"), self._findSt)
    end
    if joy and self.zone == "search" then mark(self, fx, fy, fw, ih) end
    self._findRect = { x = fx, y = fy, w = fw, h = ih }
    self._headRect = { x = x, y = y, w = w, h = h }
    local tc = T.textDim
    if fx + fw + px(10) + cw <= x + w then
        self:drawText(cs, x + w - pad - cw, y + math.floor((h - fh(f3)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f3)
    end
end

local function cutInto(out, s, cpr)
    if s == "" then out[#out + 1] = ""; return end
    local p = 1
    while p <= #s do
        out[#out + 1] = s:sub(p, p + cpr - 1)
        p = p + cpr
    end
end

local function wrapOf(row, cprMsg, cprStk)
    local k = tostring(cprMsg) .. ":" .. tostring(cprStk) .. ":" .. tostring(row.stack and #row.stack or 0)
    if row._wk ~= k then
        row._wk = k
        local m = {}
        cutInto(m, tostring(row.msg or ""), cprMsg)
        row._wm = m
        local s = {}
        if row.stack then for i = 1, #row.stack do cutInto(s, row.stack[i], cprStk) end end
        row._ws = s
    end
    return row._wm, row._ws
end

function W:_rowLines(row, cprMsg, cprStk)
    local isPick, isOpen = row == self.pick, row.kind == "error" and self.opened[row.id] ~= nil
    if not isPick and not isOpen then return 1 end
    local m, s = wrapOf(row, cprMsg, cprStk)
    local n = isPick and #m or 1
    if isOpen then n = n + #s end
    return n
end

function W:_cols(x, w)
    local T = LC93.T
    local f = T.fontF3
    local cw = charW(f)
    local c = self._colsC or {}
    self._colsC = c
    c.cw = cw
    c.timeX = x + px(4)
    c.kindX = c.timeX + 8 * cw + px(8)
    local kw = 0
    for _, k in ipairs(L.KINDS) do kw = math.max(kw, LC93.TM:MeasureStringX(f, L.kindWord(k))) end
    kw = math.min(kw, 7 * cw)
    c.dot = px(U.MARK)
    c.msgX = c.kindX + c.dot + px(5) + kw + px(8)
    c.right = x + w
    c.repW = 5 * cw
    local room = c.right - c.repW - px(8) - c.msgX
    c.srcW = (room > 60 * cw) and math.min(36 * cw, math.floor(room * 0.4)) or 0
    c.tri = math.max(px(6), math.floor(fh(f) * 0.45))
    c.msgTX = c.msgX + c.tri + px(5)
    c.msgEnd = c.right - c.repW - px(8) - (c.srcW > 0 and (c.srcW + px(8)) or 0)
    c.cprMsg = math.max(8, math.floor((c.msgEnd - c.msgTX) / cw))
    c.cprStk = math.max(8, math.floor((c.right - c.msgTX) / cw))
    return c
end

function W:_seekPick(c, lh, h)
    local n = L.counts()
    local foot = 0
    for i = n, 1, -1 do
        local row = L.shownAt(i)
        local rh = self:_rowLines(row, c.cprMsg, c.cprStk) * lh
        if row == self.pick then
            local head = foot + rh
            if foot < self.scroll then self.scroll = foot
            elseif head > self.scroll + h then self.scroll = math.min(head - h, foot) end
            return
        end
        foot = foot + rh
    end
end

function W:_listHeight(c, lh)
    local n = L.counts()
    local total = n * lh
    if self.pick and self.pick.vis then total = total + (self:_rowLines(self.pick, c.cprMsg, c.cprStk) - 1) * lh end
    for _, row in pairs(self.opened) do
        if row.vis and row ~= self.pick then total = total + (self:_rowLines(row, c.cprMsg, c.cprStk) - 1) * lh end
    end
    return total
end

function W:_drawList(x, y, w, h)
    local T = LC93.T
    local f = T.fontF3
    local lh = fh(f) + px(2)
    local sbW = T.sp.scrollbarW
    local c = self:_cols(x, w)
    local total = self:_listHeight(c, lh)
    local bar = total > h
    if bar then
        c = self:_cols(x, w - sbW - px(2))
        total = self:_listHeight(c, lh)
    end
    if self.pick and not self.pick.vis then self.pick = nil end
    local n = L.counts()
    local newest = n > 0 and L.shownAt(n) or nil
    local newestId = newest and newest.id or 0
    if self._seenRev ~= L.viewRev then
        if self.scroll > 0 and self._seenId and newestId > self._seenId and self._seenQ == L.q then
            local add = 0
            for i = n, 1, -1 do
                local row = L.shownAt(i)
                if row.id <= self._seenId then break end
                add = add + self:_rowLines(row, c.cprMsg, c.cprStk) * lh
            end
            self.scroll = self.scroll + add
        end
        self._seenRev = L.viewRev
    end
    self._seenId, self._seenQ = newestId, L.q
    if self.seek and self.pick then
        self.seek = nil
        self:_seekPick(c, lh, h)
    end
    local maxS = math.max(0, total - h)
    if self.scroll > maxS then self.scroll = maxS end
    if self.scroll < 0 then self.scroll = 0 end
    self._maxS, self._lh = maxS, lh
    self._rowHits = {}
    if bar then
        local win = self
        LC93.Molecules.scrollBar(self, nil, "log", x + w - sbW, y, sbW, h, maxS - self.scroll, total,
            function(v) win.scroll = math.max(0, (win._maxS or 0) - v) end, { step = lh })
    end
    if n == 0 then
        local _, kept = L.counts()
        LC93.Molecules.drawEmptyLine(self, x, y, w, kept == 0 and tr("UI_LC93_Console_Empty") or tr("UI_LC93_Console_NoMatch"))
        return
    end
    self:_drawRows(c, x, y, h, lh, n)
    if self.scroll > 0 then
        LC93.Atoms.drawStatusDot(self, c.right - px(8), y + h - px(8), T.accent, px(6))
    end
end

function W:_drawRows(c, x, y, h, lh, n)
    local joy = self.joyfocus ~= nil
    local mx, my = self:getMouseX(), self:getMouseY()
    local Fo = LC93.Input and LC93.Input.Focus
    if joy or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    c.vy0, c.vy1, c.lh = y, y + h, lh
    self:setStencilRect(x, y, c.right - x, h)
    local ybot = y + h + self.scroll
    local hovered = false
    for i = n, 1, -1 do
        if ybot <= y then break end
        local row = L.shownAt(i)
        local rh = self:_rowLines(row, c.cprMsg, c.cprStk) * lh
        local ytop = ybot - rh
        if ytop < y + h then
            local hover = mx ~= nil and mx >= x and mx < c.right and my >= ytop and my < ybot and my >= y and my < y + h
            hovered = hovered or hover
            self:_drawRow(row, c, x, ytop, rh, hover)
            self._rowHits[#self._rowHits + 1] = { y = ytop, h = rh, row = row, triX = c.msgX, triR = c.msgTX }
        end
        ybot = ytop
    end
    self:clearStencilRect()
    if hovered then LC93.Help.set(self, tr("UI_LC93_Console_HelpRow")) end
end

local function inView(c, yy) return yy + c.lh > c.vy0 and yy < c.vy1 end

function W:_drawRowHead(row, c, y, dc, onFocus, isOpen)
    local T = LC93.T
    local A = LC93.Atoms
    local f = T.fontF3
    local lh = c.lh
    local ty = y + math.floor((lh - fh(f)) / 2)
    self:drawText(row.t or "", c.timeX, ty, dc.r, dc.g, dc.b, dc.a or 1, f)
    A.drawStatusDot(self, c.kindX, y + math.floor((lh - c.dot) / 2), kindColor(row.kind), c.dot)
    self:drawText(L.kindWord(row.kind), c.kindX + c.dot + px(5), ty, dc.r, dc.g, dc.b, dc.a or 1, f)
    if row.kind == "error" then
        local ar = onFocus and T.textOnFocus or T.arrow
        local tyT = y + math.floor((lh - c.tri) / 2)
        if isOpen then A.drawTriangleDown(self, c.msgX, tyT, c.tri, ar) else A.drawTriangleRight(self, c.msgX, tyT, c.tri, ar) end
    end
    if c.srcW > 0 then
        local src = L.modName(row.mod)
        local where = L.srcOf(row)
        if where ~= "" then src = src .. " | " .. where end
        src = A.truncateText(src, f, c.srcW)
        local sw = LC93.TM:MeasureStringX(f, src)
        self:drawText(src, c.right - c.repW - px(8) - sw, ty, dc.r, dc.g, dc.b, dc.a or 1, f)
    end
    if (row.n or 1) > 1 then
        local rs = "x" .. tostring(row.n)
        local rw = LC93.TM:MeasureStringX(f, rs)
        self:drawText(rs, c.right - rw, ty, dc.r, dc.g, dc.b, dc.a or 1, f)
    end
end

function W:_drawRow(row, c, x, y, rh, hover)
    local T = LC93.T
    local f = T.fontF3
    local lh = c.lh
    local picked = row == self.pick
    local onFocus = false
    local by0, by1 = math.max(y, c.vy0), math.min(y + rh, c.vy1)
    if picked then
        local ac = T.accent
        self:drawRect(x, by0, c.right - x, by1 - by0, T.selectionA or 0.25, ac.r, ac.g, ac.b)
        if self.joyfocus and self.zone == "list" then onFocus = mark(self, x, by0, c.right - x, by1 - by0) end
    elseif hover then
        local hv = T.hover
        self:drawRect(x, by0, c.right - x, by1 - by0, hv.a or 1, hv.r, hv.g, hv.b)
    end
    local tc = onFocus and T.textOnFocus or T.text
    local dc = onFocus and T.textOnFocus or T.textDim
    local isOpen = row.kind == "error" and self.opened[row.id] ~= nil
    if inView(c, y) then self:_drawRowHead(row, c, y, dc, onFocus, isOpen) end
    local mc = (row.kind == "ran" and not onFocus) and T.accent or tc
    local m, s = nil, nil
    if picked or isOpen then m, s = wrapOf(row, c.cprMsg, c.cprStk) end
    local dy = math.floor((lh - fh(f)) / 2)
    local yy = y
    if picked then
        for i = 1, #m do
            if inView(c, yy) then self:drawText(m[i], c.msgTX, yy + dy, mc.r, mc.g, mc.b, mc.a or 1, f) end
            yy = yy + lh
        end
    else
        local msg = tostring(row.msg or "")
        if #msg > c.cprMsg then msg = msg:sub(1, math.max(1, c.cprMsg - 3)) .. "..." end
        if inView(c, yy) then self:drawText(msg, c.msgTX, yy + dy, mc.r, mc.g, mc.b, mc.a or 1, f) end
        yy = yy + lh
    end
    if isOpen then
        for i = 1, #s do
            if yy >= c.vy1 then break end
            if inView(c, yy) then self:drawText(s[i], c.msgTX, yy + dy, dc.r, dc.g, dc.b, dc.a or 1, f) end
            yy = yy + lh
        end
    end
end

local _btns = { { id = "export" }, { id = "copy" }, { id = "clear" }, { id = "run", variant = "primary" } }
local _spec = { buttons = _btns }
function W:_drawBand(y, w, joy)
    local now = getTimestampMs()
    local shown, total = L.counts()
    local b0, b1, b2, b3 = _btns[1], _btns[2], _btns[3], _btns[4]
    b0.label, b0.help = btn(tr("UI_LC93_Console_Export")), tr("UI_LC93_Console_HelpExport")
    b0.disabled = shown == 0
    if (self._copiedUntil or 0) > now then b1.label = btn(tr("UI_LC93_Msg_Copied"))
    else b1.label = btn(self.pick and tr("UI_LC93_Msg_CopyOne") or tr("UI_LC93_Console_CopyAll")) end
    b1.help = self.pick and tr("UI_LC93_Console_HelpCopy") or tr("UI_LC93_Console_HelpShown")
    b1.disabled = shown == 0
    b2.label, b2.help = btn(tr("UI_LC93_Console_Clear")), tr("UI_LC93_Console_HelpClear")
    b2.disabled = total == 0 and DC.text == ""
    local allowed = DC.allowed()
    b3.label = btn(tr("UI_LC93_Console_Run"))
    if self.mode == "pad" then
        local can = S.canRun()
        b3.help = (not allowed) and tr("UI_LC93_Console_NotAllowed") or (can and tr("UI_LC93_Console_HelpPad") or tr("UI_LC93_Console_HelpNoLoad"))
        b3.disabled = (not allowed) or (not can) or padInfo(self, self:padText()).blank
    else
        b3.help = allowed and tr("UI_LC93_Console_HelpRun") or tr("UI_LC93_Console_NotAllowed")
        b3.disabled = (not allowed) or blank(self:lineText())
    end
    for i, b in ipairs(_btns) do
        self._bandOff[b.id] = b.disabled and true or false
        b.focus = (joy and self.zone == "band" and self.bandFocus == i) and focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
    end
    _spec.win = self
    _spec.status = self._status
    local _, out = LC93.Molecules.drawBand(self, 0, y, w, _spec)
    self._bandRects = out and out.buttons or {}
end

function W:render() LC93_Window.render(self) end

function W:getStatusLine()
    if self.page ~= "log" and self._pageStatus then return self:_pageStatus() end
    if self.ac then return tr("UI_LC93_Console_AcKeys") end
    if not DC.allowed() then return tr("UI_LC93_Console_NotAllowed") end
    if self.mode == "pad" then return S.canRun() and tr("UI_LC93_Console_HelpPad") or tr("UI_LC93_Console_HelpNoLoad") end
    local s = DC.suggestion()
    if s then return tr("UI_LC93_Console_Suggest", s) end
    return tr("UI_LC93_Console_Help")
end

function W:toggleOpen(row)
    if not row or row.kind ~= "error" then return end
    if self.opened[row.id] then self.opened[row.id] = nil else self.opened[row.id] = row end
    L.viewRev = L.viewRev + 1
end

function W:pickAt(x, y)
    if y == nil then x, y = nil, x end
    for _, hit in ipairs(self._rowHits or {}) do
        if y >= hit.y and y < hit.y + hit.h then
            local row = hit.row
            sound()
            if row.kind == "error" then
                local onTri = x ~= nil and x >= hit.triX and x < hit.triR
                if self.pick == row or onTri then self:toggleOpen(row)
                elseif not self.opened[row.id] then self:toggleOpen(row) end
                self.pick = row
            else
                self.pick = (self.pick ~= row) and row or nil
            end
            return true
        end
    end
    self.pick = nil
    return false
end

function W:filterAt(y)
    local items = self:_filterItems()
    for _, hit in ipairs(self._fHits or {}) do
        if y >= hit.y and y < hit.y + hit.h then
            self:useFilter(items[hit.i])
            self.fFocus = hit.i
            return true
        end
    end
    return false
end
function W:useFilter(it)
    if not it then return end
    sound()
    if it.t == "fold" then
        if self.fold[it.g] then self.fold[it.g] = nil else self.fold[it.g] = true end
    else
        L.toggle(it.g, it.key)
        self.scroll = 0
    end
end

function W:setPage(id)
    if self.page == id then return end
    if self.page == "log" then
        if self.naming then self:nameDone(false) end
        if self.input then self.input:unfocus() end
        if self.pad then self.pad:unfocus() end
        if self.find then self.find:unfocus() end
        self.ac, self._acKey = nil, nil
    end
    if self._pageLeave then self:_pageLeave(self.page) end
    self.page = id
    sound()
    if id ~= "log" and self.zone ~= "strip" then self.zone = "strip" end
    if id == "log" and self.zone ~= "strip" then self.zone = "input" end
end

local function inBar(sb, x, y) return sb and sb.visible and x >= sb.x and x < sb.x + sb.width and y >= sb.y and y < sb.y + sb.height end

function W:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if inRect(self:windowBoxRect(), x, y) then return true end
    if self.ac and inRect(self._acRect, x, y) then
        for i, r in ipairs(self._acHits or {}) do
            if inRect(r, x, y) then
                local inp = self.mode == "pad" and self.pad or self.input
                self.acI = i
                self:acTake(i)
                if not self.joyfocus then inp:focus() end
                return true
            end
        end
        return true
    end
    local bars = self._lc93Bars
    if bars and (inBar(bars.log, x, y) or inBar(bars.filters, x, y) or inBar(bars.side, x, y)) then return true end
    for _, r in ipairs(self._bandRects or {}) do
        if inRect(r, x, y) then self._down = r.id; return true end
    end
    for _, r in ipairs(self._keyHits or {}) do
        if inRect(r, x, y) then self._down = r.id; return true end
    end
    if self.naming and inRect(self._nameRect, x, y) then
        self.zone = "band"
        self.nameE:focus()
        placeCursor(self.nameE, self._nameSt, x)
        return true
    end
    if self.mode == "pad" then
        if inRect(self._padRect, x, y) then
            self.zone = "input"
            self.pad:focus()
            self:padClick(x, y)
            return true
        end
        if inRect(self._sideRect, x, y) then
            local i, it = self:sideItemAt(y)
            if i then self.sFocus = i; self:useSide(it) end
            return true
        end
    end
    for _, r in ipairs(self._stripHits or {}) do
        if inRect(r, x, y) then self:setPage(r.page); return true end
    end
    if self.page ~= "log" and self._pageMouseDown and self:_pageMouseDown(x, y) then return true end
    if inRect(self._fieldRect, x, y) then
        self.zone = "input"
        self.input:focus()
        placeCursor(self.input, self, x)
        return true
    end
    if self.page == "log" then
        if inRect(self._findRect, x, y) then
            self.zone = "search"
            self.find:focus()
            placeCursor(self.find, self._findSt, x)
            return true
        end
        if inRect(self._filterRect, x, y) then self:filterAt(y); return true end
        if inRect(self._listRect, x, y) then self:pickAt(x, y); return true end
    end
    LC93_Window.onMouseDown(self, x, y)
    return true
end

function W:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down then
        local hit = false
        for _, r in ipairs(self._bandRects or {}) do
            if not hit and r.id == down and inRect(r, x, y) then hit = true; self:press(down) end
        end
        for _, r in ipairs(self._keyHits or {}) do
            if not hit and r.id == down and inRect(r, x, y) then hit = true; self:press(down) end
        end
        return true
    end
    LC93_Window.onMouseUp(self, x, y)
    return true
end

function W:onMouseUpOutside(x, y)
    self._down = nil
    LC93_Window.onMouseUpOutside(self, x, y)
    return true
end

function W:onMouseMove(dx, dy)
    LC93_Window.onMouseMove(self, dx, dy)
    return true
end
function W:onMouseMoveOutside(dx, dy)
    LC93_Window.onMouseMoveOutside(self, dx, dy)
    return true
end
function W:onRightMouseDown(x, y)
    if self.mode == "pad" and inRect(self._sideRect, x, y) then
        local i, it = self:sideItemAt(y)
        if it and it.t == "snip" then self.sFocus = i; self:startNaming("rename", it.i) end
    end
    return true
end
function W:onRightMouseUp(x, y) return true end

function W:onMouseWheel(del)
    local mx, my = self:getMouseX(), self:getMouseY()
    if self.page ~= "log" then
        if self._pageWheel then self:_pageWheel(del, mx, my) end
        return true
    end
    if inRect(self._filterRect, mx, my) then
        self.fScroll = math.max(0, math.min(self._fMax or 0, self.fScroll + del * px(U.FROW) * 3))
        return true
    end
    if inRect(self._sideRect, mx, my) then
        self.sScroll = math.max(0, math.min(self._sMax or 0, self.sScroll + del * px(U.FROW) * 3))
        return true
    end
    if inRect(self._padRect, mx, my) then return true end
    local lh = self._lh or px(14)
    self.scroll = math.max(0, math.min(self._maxS or 0, self.scroll - del * lh * 3))
    return true
end

function W:update()
    LC93_Window.update(self)
    if not self:getIsVisible() then return end
    if self.moving and not isMouseButtonDown(0) then self.moving = false end
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (DC.qaJoy and self or nil)
    if self._kbOpen then
        local KB = LC93.Keyboard
        if not (KB and KB.isVisible and KB.isVisible()) then
            self._kbOpen = nil
            if self._kbEntry == self.input then
                local t = self:lineText()
                if self.ac then self.zone, self.acI = "ac", 1
                elseif t ~= self._kbFrom and not blank(t) then self.zone, self.bandFocus = "band", RUN_AT end
            elseif self._kbEntry == self.pad then
                local t = self:padText()
                self._padPrev, self._padCur = t, cursorOf(self.pad, t)
                if self.ac then self.zone, self.acI = "ac", 1
                elseif t ~= self._kbFrom and not blank(t) then self.zone, self.bandFocus = "band", RUN_AT end
            elseif self._kbEntry == self.nameE and self.naming then
                self.zone, self.bandFocus = "band", 3
            elseif self._kbEntry and self._kbEntry ~= self.find and self._kbEntry ~= self.nameE and self._pageKbDone then
                self:_pageKbDone(self._kbEntry)
            end
        end
    end
end

function W:onGainJoypadFocus(jd) self.joyfocus = jd end
function W:onLoseJoypadFocus(jd) self.joyfocus = nil end

function W:openKeyboard(jd, entry)
    entry = entry or self.input
    if OnScreenKeyboard and OnScreenKeyboard.Show and jd then
        local ok, osk = pcall(OnScreenKeyboard.Show, self.playerNum, entry, jd)
        if ok and osk then
            osk.prevFocus = self
            jd.focus = osk
            if updateJoypadFocus then updateJoypadFocus(jd) end
            self._kbOpen, self._kbEntry = true, entry
            self._kbFrom = tostring(entry:getText() or "")
            return
        end
    end
    entry:focus()
end

function W:padX()
    if self.mode == "pad" then
        if self.naming then return end
        local it = self.zone == "side" and self:_sideItems()[self.sFocus] or nil
        if it and it.t == "snip" then self:startNaming("rename", it.i) else self:startNaming("save") end
        return
    end
    if self.page == "log" and L.counts() > 0 then sound("UIActivateButton"); self:export() end
end

function W:padBandA(jd)
    if self.naming then
        local id = NAME_BAND[self.bandFocus]
        if id == "name" then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus, self.nameE)
        elseif id then self:press(id) end
        return
    end
    local id = BAND[self.bandFocus]
    if id then self:press(id) end
end

function W:onJoypadDown(button, jd)
    if self.page ~= "log" and self.zone ~= "strip" and self._pageButton and self:_pageButton(button, jd) then return end
    if self.zone == "ac" then
        if button == Joypad.AButton then
            if self:acTake() or not self.ac then self.zone = "input" end
            return
        elseif button == Joypad.BButton then
            sound()
            self:acShut()
            self.zone = "input"
            return
        end
    end
    if button == Joypad.BButton then
        if self.naming then sound("UIActivateButton"); self:nameDone(false); return end
        self:close()
        return
    end
    if self.page ~= "log" then
        if button == Joypad.AButton and self.zone == "strip" then local pg = PAGES[self.stripFocus]; if pg then self:setPage(pg.id) end end
        return
    end
    if button == Joypad.XButton then self:padX(); return end
    if button == Joypad.YButton then self:setMode(self.mode == "pad" and "line" or "pad"); return end
    if button ~= Joypad.AButton then
        if self.zone == "input" then
            local step = self.mode == "pad" and self.padHistory or self.historyStep
            if button == Joypad.LBumper then step(self, -1); sound()
            elseif button == Joypad.RBumper then step(self, 1); sound() end
        end
        return
    end
    local z = self.zone
    if z == "input" then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus, self.mode == "pad" and self.pad or self.input)
    elseif z == "side" then self:useSide(self:_sideItems()[self.sFocus])
    elseif z == "search" then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus, self.find)
    elseif z == "strip" then local pg = PAGES[self.stripFocus]; if pg then self:setPage(pg.id) end
    elseif z == "filters" then self:useFilter(self:_filterItems()[self.fFocus])
    elseif z == "list" then if self.pick and self.pick.kind == "error" then sound(); self:toggleOpen(self.pick); self.seek = true end
    elseif z == "band" then self:padBandA(jd)
    end
end

function W:pickStep(d)
    local n = L.counts()
    if n == 0 then return false end
    local i
    if not self.pick then
        i = (d < 0) and n or 1
    else
        local at = L.indexOf(self.pick)
        if not at then at = (d < 0) and n + 1 or 0 end
        i = at + d
    end
    if i < 1 or i > n then return false end
    self.pick = L.shownAt(i)
    self.seek = true
    return true
end

function W:topRowInView()
    local best = nil
    for _, h in ipairs(self._rowHits or {}) do
        if self._listRect and h.y + h.h > self._listRect.y and (not best or h.y < best.y) then best = h end
    end
    return best and best.row or nil
end

local function padFilters(win, dir)
    local items = win:_filterItems()
    if dir == "up" then if win.fFocus > 1 then win.fFocus = win.fFocus - 1; win.fSeek = true end
    elseif dir == "down" then if win.fFocus < #items then win.fFocus = win.fFocus + 1; win.fSeek = true end
    elseif dir == "left" then win.zone = "strip"
    elseif dir == "right" then
        win.pick = nil
        if win:pickStep(-1) then win.zone = "list" else win.zone = "search" end
    end
end

local function padList(win, dir)
    if dir == "up" then
        if not win:pickStep(-1) then win.zone, win.pick = "search", nil end
    elseif dir == "down" then
        if not win:pickStep(1) then win.zone, win.pick = "input", nil end
    elseif dir == "left" then win.zone = "filters"
    end
end

local function padSide(win, dir)
    local items = win:_sideItems()
    if dir == "up" then if win.sFocus > 1 then win.sFocus = win.sFocus - 1; win.sSeek = true end
    elseif dir == "down" then
        if win.sFocus < #items then win.sFocus = win.sFocus + 1; win.sSeek = true else win.zone = "band" end
    elseif dir == "left" then win.zone = "input"
    end
end

function W:padDir(dir)
    local z = self.zone
    local log = self.page == "log"
    local bandN = self.naming and #NAME_BAND or #BAND
    if not log and z ~= "strip" then
        local moved = self._pageDir and self:_pageDir(dir)
        if not moved and dir == "left" then self.zone = "strip" end
        sound()
        return
    end
    if z == "ac" then
        if dir == "up" or dir == "down" then self:acMove(dir == "up" and -1 or 1)
        else self:acShut(); self.zone = "input"; sound() end
        return
    end
    if z == "input" and dir == "up" and self.ac then self.zone = "ac"; sound(); return end
    if z == "side" then padSide(self, dir); sound(); return end
    if z == "input" and dir == "right" and self.mode == "pad" then self.zone = "side"; sound(); return end
    if z == "band" and dir == "right" and self.bandFocus >= bandN then sound(); return end
    if z == "strip" then
        if dir == "up" and self.stripFocus > 1 then self.stripFocus = self.stripFocus - 1
        elseif dir == "down" and self.stripFocus < #PAGES then self.stripFocus = self.stripFocus + 1
        elseif dir == "right" then self.zone = log and "filters" or "page" end
    elseif z == "filters" then padFilters(self, dir)
    elseif z == "search" then
        if dir == "down" then
            local top = self:topRowInView()
            if top then self.pick, self.seek, self.zone = top, true, "list" else self.zone = "input" end
        elseif dir == "left" then self.zone = "filters" end
    elseif z == "list" then padList(self, dir)
    elseif z == "input" then
        if dir == "up" and log then
            self.pick = nil
            if self:pickStep(-1) then self.zone = "list" else self.zone = "search" end
        elseif dir == "down" then self.zone = "band"
        elseif dir == "left" then self.zone = log and "filters" or "strip" end
    elseif z == "band" then
        if dir == "left" and self.bandFocus > 1 then self.bandFocus = self.bandFocus - 1
        elseif dir == "right" and self.bandFocus < #BAND then self.bandFocus = self.bandFocus + 1
        elseif dir == "up" then self.zone = "input" end
    end
    sound()
end
function W:onJoypadDirUp() self:padDir("up") end
function W:onJoypadDirDown() self:padDir("down") end
function W:onJoypadDirLeft() self:padDir("left") end
function W:onJoypadDirRight() self:padDir("right") end

function W:getFooterPrompts()
    if not self.joyfocus then return nil end
    local Pr = LC93.Prompt
    local move = tr("UI_LC93_Prompt_DPadMove")
    local out = { (Pr and Pr.padNote) and Pr.padNote(move) or move }
    local z = self.zone
    local pad = self.mode == "pad"
    if self.page ~= "log" then
        if z == "strip" then out[#out + 1] = { glyph = "A", label = tr("UI_LC93_Prompt_Select") }
        elseif self._pagePrompts then self:_pagePrompts(out) end
        out[#out + 1] = { glyph = "B", label = (self._pageBLabel and self:_pageBLabel()) or getText("UI_Close") }
        return out
    end
    if z == "ac" then
        out[#out + 1] = { glyph = "A", label = tr("UI_LC93_Console_PadTake") }
        out[#out + 1] = { glyph = "B", label = tr("UI_LC93_Console_PadShut") }
        return out
    end
    if z == "input" then
        out[#out + 1] = { glyph = "A", label = tr("UI_LC93_Prompt_Keyboard") }
        out[#out + 1] = { glyph = "LB", label = tr("UI_LC93_Console_PadOlder") }
        out[#out + 1] = { glyph = "RB", label = tr("UI_LC93_Console_PadNewer") }
        if pad then out[#out + 1] = { glyph = "X", label = tr("UI_LC93_Console_SaveSnippet") } end
    elseif z == "side" then
        local it = self:_sideItems()[self.sFocus]
        if it and it.t == "fold" then out[#out + 1] = { glyph = "A", label = self.sFold[it.g] and tr("UI_LC93_Prompt_Unfold") or tr("UI_LC93_Prompt_Fold") }
        elseif it then out[#out + 1] = { glyph = "A", label = tr("UI_LC93_Console_PadLoad") } end
        out[#out + 1] = { glyph = "X", label = (it and it.t == "snip") and tr("UI_LC93_Console_PadRename") or tr("UI_LC93_Console_SaveSnippet") }
    elseif z == "band" then
        out[#out + 1] = { glyph = "A", label = (self.naming and self.bandFocus == 1) and tr("UI_LC93_Prompt_Keyboard") or tr("UI_LC93_Prompt_Press") }
    else
        local a = nil
        if z == "strip" then a = tr("UI_LC93_Prompt_Select")
        elseif z == "search" then a = tr("UI_LC93_Prompt_Keyboard")
        elseif z == "filters" then
            local it = self:_filterItems()[self.fFocus]
            if it and it.t == "fold" then a = self.fold[it.g] and tr("UI_LC93_Prompt_Unfold") or tr("UI_LC93_Prompt_Fold")
            elseif it then a = tr("UI_LC93_Console_PadTick") end
        elseif z == "list" and self.pick and self.pick.kind == "error" then
            a = self.opened[self.pick.id] and tr("UI_LC93_Prompt_Fold") or tr("UI_LC93_Prompt_Unfold")
        end
        if a then out[#out + 1] = { glyph = "A", label = a } end
        if pad then out[#out + 1] = { glyph = "X", label = tr("UI_LC93_Console_SaveSnippet") }
        elseif self.page == "log" then out[#out + 1] = { glyph = "X", label = tr("UI_LC93_Console_Export") } end
    end
    if not self.naming then out[#out + 1] = { glyph = "Y", label = pad and tr("UI_LC93_Console_OneLine") or tr("UI_LC93_Console_Scratchpad") } end
    out[#out + 1] = { glyph = "B", label = self.naming and getText("UI_Cancel") or getText("UI_Close") }
    return out
end

function DC.isOpen()
    return DC.win ~= nil and DC.win:getIsVisible() == true
end

function DC.open(pn)
    if not (LC93.T and DC.exists()) then return nil end
    local win = DC.win
    if not win then
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local w, h = math.min(px(U.W), sw - px(U.LEFT) * 2), math.min(px(U.H), sh - px(40))
        local x, y = px(U.LEFT), math.max(0, sh - h - px(U.BOTTOM))
        win = LC93_DebugConsoleWindow:new(x, y, w, h)
        win:initialise()
        win:instantiate()
        win._lc93Home = { x = x, y = y, w = w, h = h }
        DC.win = win
    elseif DC.place then
        if win.windowShaded then win:setWindowShaded(false) end
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local p = DC.place
        local w, h = math.min(p.w, sw), math.min(p.h, sh)
        win:setWidth(w); win:setHeight(h)
        win:setX(math.max(0, math.min(p.x, sw - w))); win:setY(math.max(0, math.min(p.y, sh - h)))
    end
    if not win:isReallyVisible() then
        win:setVisible(true)
        win:addToUIManager()
        win:setAlwaysOnTop(true)
    end
    win.scroll, win.pick, win.hi, win.opened = 0, nil, nil, {}
    win._status = nil
    local jc = P.jc
    if jc then
        DC.park(jc)
        if not DC.up(jc) then pcall(function() jc:setVisible(true) end) end
    end
    DC.read()
    DC.feed()
    S.load()
    AC.refresh()
    win.ac, win._acKey, win._acShutKey = nil, nil, nil
    win.zone = "input"
    local jd = pn and JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    if jd then
        win.playerNum = pn
        jd.focus = win
        if updateJoypadFocus then updateJoypadFocus(jd) end
    end
    return win
end

function DC.close()
    if DC.isOpen() then DC.win:close() end
end

function DC.frame()
    if not DC.debug() then return end
    local jc = DC.game()
    if not jc then return end
    if DC.handedBack() or not DC.parts(jc).ok then
        if DC.isOpen() then DC.win:close(true) end
        DC.unpark(jc)
        return
    end
    DC.park(jc)
    local want = DC.up(jc) and onScreen(jc)
    if want and not DC.isOpen() then
        local ok, err = pcall(DC.open)
        if not ok then LC93.logOnce("lua console open", err) end
    elseif not want and DC.isOpen() then
        DC.win:close(true)
    end
    if not DC.isOpen() then return end
    DC.read()
    local ok, err = pcall(DC.feed)
    if not ok then LC93.logOnce("lua console log", err) end
end

if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(DC.frame) end

if LC93.Safe and LC93.Safe.register then
    LC93.Safe.register("console", {
        leave = function()
            if DC.win and DC.isOpen() then DC.win:close(true) end
            DC.mirror("")
            local jc = DC.game()
            if jc then DC.unpark(jc) end
        end,
        enter = function()
            local jc = DC.game()
            if jc and DC.parts(jc).ok then DC.park(jc) end
        end,
    })
end

DC.ui = { U = U, PAGES = PAGES, makeEntry = makeEntry, parkEntry = parkEntry, placeCursor = placeCursor, mark = mark,
          focusOpts = focusOpts, charW = charW, cursorOf = cursorOf, blank = blank }

return DC
