-- ZeD-UI/42/media/lua/client/ZeD/ZeD_DebugConsole.lua
-- ============================================================================
-- THE LUA CONSOLE (punch list 106, the director, Nov 7 2026): the game's debug-mode console (only with -debug: run
-- Lua, read errors and output) as a ZeD window, from ZeD's own atoms and molecules.
--
-- The game's console is Java (zombie.ui.UIDebugConsole, made by UIManager.init with the in-game screens and kept as
-- UIManager.getDebugConsole()). Its parts, read from the class (javap, 42.21 and 42.22):
--   * outputLog, a text box holding everything the game prints while in debug mode (DebugLog's stream hands each
--     write to addOutput; the console moves it into the box in its own update(), which runs only while it is
--     visible; the box keeps the last 8192 characters), plus what the console says itself (a line that does not
--     compile, and the line echoed back when the debug option UIDebugConsole.EchoCommand is on)
--   * commandLine, the typed line (256 characters); Enter calls ProcessCommand(): the line goes on the history
--     (previous, not twice in a row), "clear" empties the box, anything else is compiled with
--     LuaCompiler.loadstring(line, "console", LuaManager.env) and run with LuaManager.caller.protectedCall on
--     LuaManager.thread; a failure prints through the game's log like any Lua error
--   * Up and Down step through the history; Tab takes the suggestion (autosuggest: a global function of the game's
--     whose name is nearest the word typed, worked out in update())
--   * the key (Toggle Lua Console in the game's key options) flips it, in debug mode only (GameWindow)
--   * on a server, Enter runs a line only for a role with the UIManagerProcessCommands capability or the co-op host
--
-- ZeD keeps the game's console as the engine, parked off the screen (as ZeD parks the game's inventory pages): its
-- visible flag stays the truth, so the game's key, its StartVisible option and anything else that shows or hides the
-- game's console (QA's gallery scripts) open and shut ZeD's window, and the game's console keeps running its own
-- update() while it is up, filling its box exactly as it would on screen. The line typed here is set on the game's own
-- command line and ProcessCommand() runs it (the same Java path, so the same output, errors, history and "clear");
-- the list is the game's own text box; the history is the game's own list, the suggestion the game's own, Tab takes
-- it through the game's own key handler.
--
-- The window: the output and the errors in one list that scrolls as one (an error and its stack trace carry a red
-- mark and are picked whole), the line to type in, and the band: Copy (the picked lines, or all), Clear (the game's
-- clear), Run. Enter runs, Up and Down step through the history, Tab takes the suggestion; Escape lets the line go
-- and stays the pause menu's (the window takes none of the game's keys: it may sit open all game). As the
-- game's, the line waits for a click before it takes the keyboard. Controller: the list (Up / Down pick a line), the
-- line (A: ZeD's pad keyboard; LB / RB older and newer lines), the band (Left / Right, A presses); B closes. Opened
-- by the game's own key, and in game from the ZeD wheel (Select) for a controller. It exists exactly when the game's
-- does: debug mode, the console made and on the game's screen list. Safe mode (piece "console") puts the game's own
-- back where it was, open if ZeD's was.
-- ============================================================================

require "ISUI/ISTextEntryBox"
require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"

ZeD = ZeD or {}
ZeD.DebugConsole = ZeD.DebugConsole or {}
local DC = ZeD.DebugConsole

-- design units
local U = { W = 640, H = 300, MIN_W = 360, MIN_H = 190, PAD = 8, GAP = 6, GUTTER = 14, MARK = 6, BOTTOM = 140, LEFT = 20 }
local LINE_MAX = 256        -- the game's command line takes this many characters
local PARK_X = -100000      -- where the game's console waits, off every screen
local COPIED_MS = 1500      -- Copy says Copied this long
local TAB_KEY = 15          -- Keyboard.KEY_TAB (the game's console tests the number)

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function fh(font) return ZeD.TM:getFontHeight(font) end
local function inRect(r, x, y) return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UISelectListItem") end) end
local function btn(s) return ZeD.btnCase and ZeD.btnCase(s) or s end

-- ---------------------------------------------------------------------------
-- THE GAME'S CONSOLE (the engine)
-- ---------------------------------------------------------------------------
DC.text = DC.text or ""      -- the game's box, as last read
DC.rev = DC.rev or 0         -- counts the changes to it
local P = { jc = nil, ok = false }   -- the console and its parts, found once per console object
DC.P = P

function DC.debug()
    if not isDebugEnabled then return false end
    local ok, v = pcall(isDebugEnabled)
    return ok and v == true
end

-- the game's console object (nil outside debug mode, and before the game made its in-game screens)
function DC.game()
    if not DC.debug() then return nil end
    if not (UIManager and UIManager.getDebugConsole) then return nil end
    local ok, jc = pcall(UIManager.getDebugConsole)
    if ok then return jc end
    return nil
end

-- a field of a Java object by name (the game's reflection helpers, debug mode only; private fields too)
local function fieldOf(obj, name)
    local n = getNumClassFields(obj)
    for i = 0, n - 1 do
        local f = getClassField(obj, i)
        if f and f.getName and f:getName() == name then
            local v = getClassFieldVal(obj, f)
            -- (the game answers "<private>" when it may not read one)
            if type(v) == "string" then return nil end
            return v
        end
    end
    return nil
end

-- the console's parts: the box, the line, the suggestion, the history
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
    if not P.ok then print("[ZeD] Lua console: the game's console parts were not found; the game's own stays") end
    return P
end

-- on the game's screen list: where the game's console can show (the in-game screens, not the main menu)
local function onScreen(jc)
    local ok, v = pcall(function() return UIManager.getUI():contains(jc) end)
    return ok and v == true
end

-- ZeD's console exists exactly when the game's does, and is not handed back
function DC.handedBack()
    return ZeD.Safe ~= nil and ZeD.Safe.on ~= nil and ZeD.Safe.on("console") == true
end
function DC.exists()
    local jc = DC.game()
    if not jc or DC.handedBack() then return false end
    if not onScreen(jc) then return false end
    return DC.parts(jc).ok
end

-- the game's console off every screen, its place kept; and back to its place
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

-- the game's console: is it up? (its own flag: the key, its StartVisible option, anyone's setVisible)
function DC.up(jc)
    local ok, v = pcall(function() return jc:isVisible() end)
    return ok and v == true
end

-- the game's box as it stands (the game's console fills it in its own update() while it is up)
function DC.read()
    if not (P.ok and P.out) then return end
    local ok, s = pcall(function() return P.out:getText() end)
    s = (ok and s) and tostring(s) or ""
    if s ~= DC.text then
        DC.text = s
        DC.rev = DC.rev + 1
    end
end

-- the game's command line holds what is typed here (its suggestion follows it)
function DC.mirror(text)
    text = text or ""
    if not (P.ok and P.cmd) or DC._mirrored == text then return end
    DC._mirrored = text
    pcall(function() P.cmd:SetText(text) end)
    -- (the game fills its suggestion box in its own update(), when the line's length has changed; it is run now, so the
    -- suggestion is there for Tab and for the help line in this same frame, never a frame late or not at all)
    if P.jc and text ~= "" then pcall(function() P.jc:update() end) end
end

-- may this player run a line? (the game's own test on Enter: on a server, the role's capability or the co-op host)
function DC.allowed()
    if not (isClient and isClient()) then return true end
    local ok, v = pcall(function() return getPlayer():getRole():hasCapability(Capability.UIManagerProcessCommands) end)
    if ok and v then return true end
    local ok2, h = pcall(isCoopHost)
    return ok2 and h == true
end

-- run a line, as Enter in the game's console does: ProcessCommand on the game's own command line
function DC.run(line)
    local jc = P.jc
    if not (jc and P.ok) then return false end
    if not DC.allowed() then return false end
    line = tostring(line or "")
    pcall(function() P.cmd:SetText(line) end)
    local ok, err = pcall(function() jc:ProcessCommand() end)
    -- (ProcessCommand leaves the line's words up and hands the keyboard to the game's hidden line: both put back)
    pcall(function() P.cmd:SetText("") end)
    pcall(function() P.cmd:unfocus() end)
    DC._mirrored = ""
    if not ok then ZeD.logOnce("lua console run", err) end
    DC.read()
    return ok
end

-- the game's history, oldest first
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

-- the suggestion the game offers for the line (nil when none)
function DC.suggestion()
    local s = P.ok and P.sug or nil
    if not s then return nil end
    local ok, t = pcall(function()
        if not s:isVisible() then return nil end
        return s:getText()
    end)
    if ok and t and t ~= "" then return tostring(t) end
    return nil
end

-- Tab: the game's own key handler takes the suggestion into its line; the line comes back
function DC.complete(text)
    local jc = P.jc
    if not (jc and P.ok) then return nil end
    DC.mirror(text)
    local ok, t = pcall(function()
        jc:onOtherKey(TAB_KEY)
        return P.cmd:getText()
    end)
    if not ok or t == nil then return nil end
    t = tostring(t)
    DC._mirrored = t
    return t
end

-- Clear: the box emptied, as the game's own "clear" does
function DC.clear()
    if not (P.ok and P.out) then return end
    pcall(function() P.out:clearInput() end)
    DC.read()
end

-- ---------------------------------------------------------------------------
-- THE LIST: the box's text as lines, the errors marked, wrapped to a width
-- ---------------------------------------------------------------------------
-- a line that starts an error: the log's ERROR lines, a stack trace, a line that did not compile ("console:1: ...")
local function startsError(s)
    if s:find("^ERROR") or s:find("^SEVERE") or s:find("^%s*STACK TRACE") then return true end
    if s:find("console[\"%]]*:%d+:") then return true end
    if s:find("Exception") and not s:find("^LOG") then return true end
    -- a runtime error typed into the console comes as bare stack frames after the [USER] line, with no header
    if s:find("^Lua%(") or s:find("^se%.krka") or s:find("^java%.") then return true end
    return false
end
-- a line that goes on with the error above it (its trace)
local function continuesError(s)
    if s == "" then return false end
    if s:find("^%s") then return true end
    if s:find("^STACK TRACE") or s:find("^%-%-%-%-") or s:find("%-%-%-%-%-%-%-%-%-%-$") then return true end
    if s:find("^Lua%(") or s:find("^Callframe") or s:find("^function: ") or s:find("^Caused by") or s:find("^java%.") or s:find("^se%.krka") then return true end
    return false
end

-- the lines of the text: { s, err, b (the block: the first line of its error, or itself) }
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
        if startsError(ln.s) and not (block and continuesError(ln.s)) then
            block = i
            errors = errors + 1
            ln.err, ln.b = true, i
        elseif block and continuesError(ln.s) then
            ln.err, ln.b = true, block
        else
            block = nil
            ln.b = i
        end
    end
    return lines, errors
end

-- the lines and the error count, built again when the text changes
function DC.lines()
    if DC._linesRev ~= DC.rev then
        DC._linesRev = DC.rev
        DC._lines, DC._errors = DC.parse(DC.text)
    end
    return DC._lines, DC._errors or 0
end

-- a line's block: the first and last lines of its error, or the line alone
function DC.blockOf(li)
    local lines = DC.lines()
    local ln = lines[li]
    if not ln then return nil, nil end
    local first = ln.b or li
    local last = first
    while lines[last + 1] and lines[last + 1].err and lines[last + 1].b == first do last = last + 1 end
    if not ln.err then last = li end
    return first, last
end

-- the rows drawn: each line cut every cpr characters (a fixed-pitch face: the cut is exact), kept per text and width
-- (both widths the list tries, with and without its scrollbar, stay kept; a few more while the window is resized)
local ROWS_KEPT = 6
function DC.rows(cpr)
    local lines = DC.lines()
    if DC._rowsRev ~= DC.rev or (DC._rowsN or 0) >= ROWS_KEPT then DC._rowsBy, DC._rowsN, DC._rowsRev = {}, 0, DC.rev end
    DC._rowsCpr = cpr
    local kept = DC._rowsBy[cpr]
    if kept then return kept end
    local rows = {}
    for i, ln in ipairs(lines) do
        local s = ln.s
        if s == "" then
            rows[#rows + 1] = { s = "", li = i, first = true }
        else
            local p = 1
            while p <= #s do
                rows[#rows + 1] = { s = s:sub(p, p + cpr - 1), li = i, first = p == 1 }
                p = p + cpr
            end
        end
    end
    DC._rowsBy[cpr] = rows
    DC._rowsN = DC._rowsN + 1
    return rows
end

-- the words for the clipboard: lines first to last, or everything
function DC.copyText(first, last)
    if not first then return DC.text end
    local lines = DC.lines()
    local out = {}
    for i = first, last or first do
        if lines[i] then out[#out + 1] = lines[i].s end
    end
    return table.concat(out, "\n")
end

-- ---------------------------------------------------------------------------
-- THE WINDOW
-- ---------------------------------------------------------------------------
ZeD_DebugConsoleWindow = ZeD_Window:derive("ZeD_DebugConsoleWindow")
local W = ZeD_DebugConsoleWindow

local BAND = { "copy", "clear", "run" }   -- the band's buttons, left to right (Run, the main one, last)

function W:new(x, y, w, h)
    local o = ZeD_Window.new(self, x, y, w, h, "")
    o.resizable = true
    o.pin = true
    o.moveWithMouse = false
    o.playerNum = 0
    o.scroll = 0          -- px up from the newest row (0: the newest at the foot, following)
    o.zone = "input"      -- controller: "list" | "input" | "band"
    o.bandFocus = 3       -- controller: Run
    o.pick = nil          -- the picked line (an error: its first line, the block picked whole)
    o.hi = nil            -- the history line shown (nil: what was being typed)
    o.draft = ""
    o._bandOff = {}
    return o
end

function W:createChildren()
    ZeD_Window.createChildren(self)
    local T = ZeD.T
    local e = ISTextEntryBox:new("", 0, 0, 100, T.inputH)
    e.font = T.fontF3
    e:initialise()
    e:instantiate()
    e.zedEntry = true
    pcall(function() e.javaObject:setCentreVertically(true) end)
    e:setPlaceholderText(tr("UI_ZeD_Console_Type"))
    e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    e:setMaxTextLength(LINE_MAX)
    local win = self
    e.onCommandEntered = function() win:runLine() end
    e.onPressUp = function() win:historyStep(-1) end
    e.onPressDown = function() win:historyStep(1) end
    e.onOtherKey = function(_, key)
        if key == Keyboard.KEY_ESCAPE then e:unfocus()
        elseif key == TAB_KEY then win:complete() end
    end
    self:addChild(e)
    self.input = e
end

function W:lineText()
    return self.input and tostring(self.input:getText() or "") or ""
end
local function blank(s) return (s:gsub("%s", "")) == "" end

-- Enter, Run, A on Run
function W:runLine()
    local text = self:lineText()
    if blank(text) or not DC.allowed() then return end
    local typing = self.input:isFocused()
    DC.run(text)
    self.input:setText("")
    self.hi, self.draft = nil, ""
    self.scroll, self.pick = 0, nil
    if typing then self.input:focus() end
end

-- Up / Down (LB / RB): the game's history, oldest first; past the newest, the line being typed comes back
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

-- Tab: the game's suggestion into the line
function W:complete()
    local t = DC.complete(self:lineText())
    if t and t ~= self:lineText() then
        self.input:setText(t)
        sound()
    end
end

-- (each press tests afresh what the band grayed: the band was drawn a frame ago, a line typed since counts)
function W:press(id)
    if id == "run" then
        if blank(self:lineText()) or not DC.allowed() then return end
        sound("UIActivateButton")
        self:runLine()
        return
    end
    if DC.text == "" then return end
    sound("UIActivateButton")
    if id == "clear" then
        DC.clear()
        self.pick, self.scroll = nil, 0
    elseif id == "copy" then
        local first, last = nil, nil
        if self.pick then first, last = DC.blockOf(self.pick) end
        local text = DC.copyText(first, last)
        pcall(function() Clipboard.setClipboard(text) end)
        self._copiedUntil = getTimestampMs() + COPIED_MS
    end
end

function W:closeAction() sound("UIActivateButton"); self:close() end

-- keepFlag: the game's console's own flag already went down (or stays up for safe mode); otherwise it goes down too
function W:close(keepFlag)
    if not keepFlag and P.jc then pcall(function() P.jc:setVisible(false) end) end
    if self.input then self.input:unfocus() end
    local KB = ZeD.Keyboard
    if KB and KB.instance and KB.instance.textEntryBox == self.input then pcall(function() KB.instance:hide() end) end
    self._kbOpen = nil
    DC.mirror("")
    DC.place = { x = self:getX(), y = self:getY(), w = self:getWidth(), h = self.windowShaded and (self.preShadeHeight or self:getHeight()) or self:getHeight() }
    self:setVisible(false)
    self:removeFromUIManager()
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then setJoypadFocus(self.playerNum, nil) end
    self.joyfocus = nil
end

-- ---------------------------------------------------------------------------
-- DRAW
-- ---------------------------------------------------------------------------
local _fo = {}
local function focusOpts(win)
    _fo.win, _fo.focused, _fo.pad = win, true, true
    return _fo
end

-- the width of one character of the fixed-pitch face (F3, Fira Mono)
local function charW(font)
    return math.max(1, ZeD.TM:MeasureStringX(font, "0000000000") / 10)
end

function W:prerender()
    local T = ZeD.T
    if not T then return end
    if not DC.exists() then self:close(true); return end
    self.minimumWidth, self.minimumHeight = px(U.MIN_W), px(U.MIN_H)
    self.title = tr("UI_ZeD_Console_Title")
    local _, errs = DC.lines()
    if errs > 0 then
        self._stat = self._stat or { {} }
        local st = self._stat[1]
        st.text, st.color = tr("UI_ZeD_Console_Errors", errs), T.danger
        self.titleStats = self._stat
    else
        self.titleStats = {}
    end
    ZeD_Window.prerender(self)
    if self.windowShaded or self.isCollapsed then return end
    local ok, err = pcall(self._drawBody, self)
    if not ok then ZeD.logOnce("lua console", err) end
end

function W:_drawBody()
    local T = ZeD.T
    local M = ZeD.Molecules
    local w = self.width
    local pad, gap = px(U.PAD), px(U.GAP)
    local top = self:titleBarHeight()
    local bot = self.height - self:footerHeight()
    local bandH = M.bandH()
    local bandY = bot - bandH
    local ih = T.inputH
    local iy = bandY - pad - ih
    local joy = self.joyfocus ~= nil
    -- what is typed is the game's line too (its suggestion follows it)
    DC.mirror(self:lineText())

    -- the line to type in: a field, the prompt mark, the game's text box inside it
    local inp = self.input
    local fx, fw = pad, w - 2 * pad
    local s1, bs = T.surf1, T.borderS
    self:drawRect(fx, iy, fw, ih, s1.a or 1, s1.r, s1.g, s1.b)
    local focused = inp and inp:isFocused()
    local ib = focused and T.accent or bs
    self:drawRectBorder(fx, iy, fw, ih, ib.a or 1, ib.r, ib.g, ib.b)
    local f3 = T.fontF3
    local mark = ">"
    local mx0 = fx + px(6)
    local td = T.textDim
    self:drawText(mark, mx0, iy + math.floor((ih - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
    local ex = mx0 + ZeD.TM:MeasureStringX(f3, mark) + px(4)
    if inp then
        if inp.font ~= f3 then inp.font = f3; pcall(function() inp:setFont(f3) end) end
        if inp:getX() ~= ex then inp:setX(ex) end
        if inp:getY() ~= iy then inp:setY(iy) end
        local ew = fx + fw - px(4) - ex
        if inp:getWidth() ~= ew then inp:setWidth(ew) end
        if inp:getHeight() ~= ih then inp:setHeight(ih) end
    end
    if joy and self.zone == "input" and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(self, fx, iy, fw, ih, focusOpts(self)) end
    self._fieldRect = { x = fx, y = iy, w = fw, h = ih }

    -- the list: the output and the errors, scrolling as one
    local ly0, ly1 = top + pad, iy - gap
    self._listRect = { x = pad, y = ly0, w = w - 2 * pad, h = math.max(0, ly1 - ly0) }
    self:_drawList(pad, ly0, w - 2 * pad, math.max(0, ly1 - ly0))

    -- the band: Copy, Clear, Run
    self:_drawBand(bandY, w, joy)
end

function W:_drawList(x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local f = T.fontF3
    local lh = fh(f) + px(1)
    local gut = px(U.GUTTER)
    local sbW = T.sp.scrollbarW
    local cw = charW(f)
    local function cprFor(tw) return math.max(8, math.floor(tw / cw)) end
    local textW = w - gut
    local rows = DC.rows(cprFor(textW))
    local bar = #rows * lh > h
    if bar then
        textW = w - gut - sbW - px(2)
        rows = DC.rows(cprFor(textW))
    end
    local total = #rows * lh
    local maxS = math.max(0, total - h)
    -- new output while scrolled up: the view stays where it was
    if self._seenRev ~= DC.rev then
        if self.scroll > 0 and self._seenRows and self._seenCpr == DC._rowsCpr and #rows > self._seenRows then
            self.scroll = self.scroll + (#rows - self._seenRows) * lh
        end
        self._seenRev = DC.rev
    end
    self._seenRows, self._seenCpr = #rows, DC._rowsCpr
    -- the picked block brought into view (the controller moved to it)
    local pf, pl = nil, nil
    if self.pick then pf, pl = DC.blockOf(self.pick) end
    if not pf then self.pick = nil end
    if self.seek and pf then
        self.seek = nil
        local firstRow, lastRow = nil, nil
        for i, r in ipairs(rows) do
            if r.li >= pf and r.li <= pl then
                firstRow = firstRow or i
                lastRow = i
            end
        end
        if firstRow then
            local foot = (#rows - lastRow) * lh
            local head = (#rows - firstRow) * lh + lh
            if foot < self.scroll then self.scroll = foot
            elseif head > self.scroll + h then self.scroll = math.min(head - h, foot) end
        end
    end
    if self.scroll > maxS then self.scroll = maxS end
    if self.scroll < 0 then self.scroll = 0 end
    self._maxS, self._lh = maxS, lh

    -- the scrollbar (top-down; this list counts from its foot)
    local sb = self._sb
    if not sb then
        sb = ZeD_ScrollbarState:new()
        local win = self
        sb.onScroll = function(pos) win.scroll = math.floor((1 - pos) * (win._maxS or 0) + 0.5) end
        self._sb = sb
    end
    sb.visible = bar
    sb.width, sb.arrowH = sbW, sbW
    sb.x, sb.y, sb.height = x + w - sbW, y, h
    sb:setBarSize(h / math.max(1, total))
    if not sb.dragging then sb.scrollPos = maxS > 0 and math.min(1, (maxS - self.scroll) / maxS) or 1 end

    self._rowHits = {}
    if #rows == 0 then
        ZeD.Molecules.drawEmptyLine(self, x, y, w, tr("UI_ZeD_Console_Empty"))
        return
    end
    local lines = DC.lines()
    local joy = self.joyfocus ~= nil
    local mx, my = self:getMouseX(), self:getMouseY()
    local Fo = ZeD.Input and ZeD.Input.Focus
    if joy or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    local hoverB = nil
    if mx and inRect(self._listRect, mx, my) then
        local by0 = y + h - lh + self.scroll
        local i = #rows - math.floor((by0 + lh - 1 - my) / lh)
        if i >= 1 and i <= #rows and my >= by0 - (#rows - i) * lh then hoverB = lines[rows[i].li] and lines[rows[i].li].b end
    end
    local textR = x + gut + textW
    self:setStencilRect(x, y, w, h)
    local by = y + h - lh + self.scroll
    -- the picked block: the selection under it, the controller's mark on it
    local onFocus = false
    if pf then
        local top, bottom = nil, nil
        for i = #rows, 1, -1 do
            local r = rows[i]
            local ry = by - (#rows - i) * lh
            if ry + lh < y then break end
            if ry <= y + h and r.li >= pf and r.li <= pl then
                bottom = bottom or (ry + lh)
                top = ry
            end
        end
        if top then
            local t0, t1 = math.max(y, top), math.min(y + h, bottom)
            local ac = T.accent
            self:drawRect(x, t0, textR - x, t1 - t0, T.selectionA or 0.25, ac.r, ac.g, ac.b)
            if joy and self.zone == "list" and ZeD.Focus and ZeD.Focus.mark then
                onFocus = ZeD.Focus.mark(self, x, t0, textR - x, t1 - t0, focusOpts(self)) and true or false
            end
        end
    end
    local tc = onFocus and T.textOnFocus or T.text
    local dg, hv = T.danger, T.hover
    local sq = px(U.MARK)
    for i = #rows, 1, -1 do
        local ry = by - (#rows - i) * lh
        if ry + lh < y then break end
        if ry <= y + h then
            local r = rows[i]
            local ln = lines[r.li]
            local inPick = pf and r.li >= pf and r.li <= pl
            if hoverB and ln and ln.b == hoverB and not inPick then
                self:drawRect(x, ry, textR - x, lh, hv.a or 1, hv.r, hv.g, hv.b)
            end
            if ln and ln.err then
                -- an error: a red mark at its first line, a red rule down its trace
                local cx = x + math.floor((sq - T.hair) / 2)
                if r.first and ln.b == r.li then
                    A.drawStatusDot(self, x, ry + math.floor((lh - sq) / 2), dg, sq)
                    -- (the rule runs on from under the mark while the error goes on: its own wrapped rows or its trace)
                    local nx = rows[i + 1]
                    local nl = nx and lines[nx.li]
                    if nl and nl.err and nl.b == ln.b then
                        self:drawRect(cx, ry + math.floor((lh + sq) / 2), T.hair, lh - math.floor((lh + sq) / 2), 0.6, dg.r, dg.g, dg.b)
                    end
                else
                    self:drawRect(cx, ry, T.hair, lh, 0.6, dg.r, dg.g, dg.b)
                end
            end
            local c = (inPick and onFocus) and tc or T.text
            if r.s ~= "" then self:drawText(r.s, x + gut, ry, c.r, c.g, c.b, c.a or 1, f) end
            self._rowHits[#self._rowHits + 1] = { y = ry, h = lh, li = r.li }
        end
    end
    self:clearStencilRect()
    if sb.visible then sb:draw(self) end
    -- scrolled up: a mark at the foot that newer lines are below
    if self.scroll > 0 then
        A.drawStatusDot(self, textR - px(8), y + h - px(8), T.accent, px(6))
    end
    if hoverB then ZeD.Help.set(self, tr("UI_ZeD_Console_HelpPick")) end
end

local _btns = { { id = "copy" }, { id = "clear" }, { id = "run", variant = "primary" } }
local _spec = { buttons = _btns }
function W:_drawBand(y, w, joy)
    local T = ZeD.T
    local now = getTimestampMs()
    local b1, b2, b3 = _btns[1], _btns[2], _btns[3]
    if (self._copiedUntil or 0) > now then b1.label = btn(tr("UI_ZeD_Msg_Copied"))
    else b1.label = btn(self.pick and tr("UI_ZeD_Msg_CopyOne") or tr("UI_ZeD_Console_CopyAll")) end
    b1.help = self.pick and tr("UI_ZeD_Console_HelpCopy") or tr("UI_ZeD_Console_HelpCopyAll")
    b1.disabled = DC.text == ""
    b2.label, b2.help = btn(tr("UI_ZeD_Console_Clear")), tr("UI_ZeD_Console_HelpClear")
    b2.disabled = DC.text == ""
    local allowed = DC.allowed()
    b3.label = btn(tr("UI_ZeD_Console_Run"))
    b3.help = allowed and tr("UI_ZeD_Console_HelpRun") or tr("UI_ZeD_Console_NotAllowed")
    b3.disabled = (not allowed) or blank(self:lineText())
    for i, b in ipairs(_btns) do
        self._bandOff[b.id] = b.disabled and true or false
        b.focus = (joy and self.zone == "band" and self.bandFocus == i) and focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
    end
    _spec.win = self
    local _, out = ZeD.Molecules.drawBand(self, 0, y, w, _spec)
    self._bandRects = out and out.buttons or {}
end

function W:render() ZeD_Window.render(self) end

-- the help line's words: the game's suggestion while there is one, else how the line works
function W:getStatusLine()
    if not DC.allowed() then return tr("UI_ZeD_Console_NotAllowed") end
    local s = DC.suggestion()
    if s then return tr("UI_ZeD_Console_Suggest", s) end
    return tr("UI_ZeD_Console_Help")
end

-- ---------------------------------------------------------------------------
-- MOUSE
-- ---------------------------------------------------------------------------
function W:pickAt(y)
    for _, hit in ipairs(self._rowHits or {}) do
        if y >= hit.y and y < hit.y + hit.h then
            local first = DC.blockOf(hit.li)
            self.pick = (self.pick ~= first) and first or nil
            sound()
            return true
        end
    end
    self.pick = nil
    return false
end

function W:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if inRect(self:windowBoxRect(), x, y) then return true end
    local sb = self._sb
    if sb and sb.visible and x >= sb.x and x < sb.x + sb.width and y >= sb.y and y < sb.y + sb.height then
        sb:handleMouseDown(y - sb.y)
        return true
    end
    for _, r in ipairs(self._bandRects or {}) do
        if inRect(r, x, y) then self._down = r.id; return true end
    end
    if inRect(self._fieldRect, x, y) then
        self.zone = "input"
        self.input:focus()
        return true
    end
    if inRect(self._listRect, x, y) then self:pickAt(y); return true end
    return ZeD_Window.onMouseDown(self, x, y)
end

function W:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if self._sb then self._sb:handleMouseUp() end
    if down then
        for _, r in ipairs(self._bandRects or {}) do
            if r.id == down and inRect(r, x, y) then self:press(down) end
        end
        return true
    end
    return ZeD_Window.onMouseUp(self, x, y)
end

function W:onMouseUpOutside(x, y)
    self._down = nil
    if self._sb then self._sb:handleMouseUp() end
    return ZeD_Window.onMouseUpOutside(self, x, y)
end

function W:onMouseMove(dx, dy)
    local sb = self._sb
    if sb and sb.dragging then sb:handleMouseMove(self:getMouseY() - sb.y); return end
    return ZeD_Window.onMouseMove(self, dx, dy)
end
function W:onMouseMoveOutside(dx, dy)
    local sb = self._sb
    if sb and sb.dragging then sb:handleMouseMove(self:getMouseY() - sb.y); return end
    return ZeD_Window.onMouseMoveOutside(self, dx, dy)
end

function W:onMouseWheel(del)
    local lh = self._lh or px(14)
    self.scroll = math.max(0, math.min(self._maxS or 0, self.scroll - del * lh * 3))
    return true
end

function W:update()
    ZeD_Window.update(self)
    if not self:getIsVisible() then return end
    local sb = self._sb
    if sb and sb.visible then
        local mx, my = self:getMouseX(), self:getMouseY()
        if sb.dragging or (mx >= sb.x and mx < sb.x + sb.width) then sb:handleMouseMove(my - sb.y) end
        if sb.dragging and not isMouseButtonDown(0) then sb:handleMouseUp() end
    end
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (DC.qaJoy and self or nil)
    -- the pad keyboard put away: a line typed lands the controller on Run (the main button)
    if self._kbOpen then
        local KB = ZeD.Keyboard
        if not (KB and KB.isVisible and KB.isVisible()) then
            self._kbOpen = nil
            local t = self:lineText()
            if t ~= self._kbFrom and not blank(t) then self.zone, self.bandFocus = "band", 3 end
        end
    end
end

-- (KEYS: the window takes none of the game's keys. Escape stays the pause menu's, as with the game's console, which
-- may sit open all game long: the debug option UIDebugConsole.StartVisible. Escape in the typed line lets it go.)

-- ---------------------------------------------------------------------------
-- CONTROLLER: the list, the line, the band
-- ---------------------------------------------------------------------------
function W:onGainJoypadFocus(jd) self.joyfocus = jd end
function W:onLoseJoypadFocus(jd) self.joyfocus = nil end

-- the pad keyboard on the line (ZeD's, through the game's OnScreenKeyboard.Show); it gives the controller back here
function W:openKeyboard(jd)
    if OnScreenKeyboard and OnScreenKeyboard.Show and jd then
        local ok, osk = pcall(OnScreenKeyboard.Show, self.playerNum, self.input, jd)
        if ok and osk then
            osk.prevFocus = self
            jd.focus = osk
            if updateJoypadFocus then updateJoypadFocus(jd) end
            self._kbOpen, self._kbFrom = true, self:lineText()
            return
        end
    end
    self.input:focus()
end

function W:onJoypadDown(button, jd)
    if button == Joypad.BButton then self:close(); return end
    if self.zone == "input" then
        if button == Joypad.AButton then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus)
        elseif button == Joypad.LBumper then self:historyStep(-1); sound()
        elseif button == Joypad.RBumper then self:historyStep(1); sound() end
    elseif self.zone == "band" and button == Joypad.AButton then
        local id = BAND[self.bandFocus]
        if id then self:press(id) end
    end
end

-- the next or previous line in the list (an error is one step), false at either end
function W:pickStep(d)
    local lines = DC.lines()
    local n = #lines
    if n == 0 then return false end
    local li
    if not self.pick then
        li = (d < 0) and n or 1
    else
        local first, last = DC.blockOf(self.pick)
        if not first then first, last = n, n end
        li = (d < 0) and (first - 1) or (last + 1)
    end
    if li < 1 or li > n then return false end
    self.pick = DC.blockOf(li)
    self.seek = true
    return true
end

function W:padDir(dir)
    if self.zone == "list" then
        if dir == "up" then self:pickStep(-1)
        elseif dir == "down" then
            if not self:pickStep(1) then self.zone, self.pick = "input", nil end
        end
    elseif self.zone == "input" then
        if dir == "up" then
            self.pick = nil
            if self:pickStep(-1) then self.zone = "list" end
        elseif dir == "down" then self.zone = "band" end
    elseif self.zone == "band" then
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
    local Pr = ZeD.Prompt
    local move = tr("UI_ZeD_Prompt_DPadMove")
    local out = { (Pr and Pr.padNote) and Pr.padNote(move) or move }
    if self.zone == "input" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Keyboard") }
        out[#out + 1] = { glyph = "LB", label = tr("UI_ZeD_Console_PadOlder") }
        out[#out + 1] = { glyph = "RB", label = tr("UI_ZeD_Console_PadNewer") }
    elseif self.zone == "band" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Press") }
    end
    out[#out + 1] = { glyph = "B", label = getText("UI_Close") }
    return out
end

-- ---------------------------------------------------------------------------
-- OPEN, CLOSE
-- ---------------------------------------------------------------------------
function DC.isOpen()
    return DC.win ~= nil and DC.win:getIsVisible() == true
end

-- open the window; pn: the controller's player when a controller opened it (it takes the pad)
function DC.open(pn)
    if not (ZeD.T and DC.exists()) then return nil end
    local win = DC.win
    if not win then
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local w, h = math.min(px(U.W), sw - px(U.LEFT) * 2), math.min(px(U.H), sh - px(40))
        local x, y = px(U.LEFT), math.max(0, sh - h - px(U.BOTTOM))
        win = ZeD_DebugConsoleWindow:new(x, y, w, h)
        win:initialise()
        win:instantiate()
        win._zedHome = { x = x, y = y, w = w, h = h }
        DC.win = win
    elseif DC.place then
        -- (rolled down, and on the screen, whatever size the screen is now)
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
    win.scroll, win.pick, win.hi = 0, nil, nil
    -- (the game's console up with it, parked: its flag says open, and it fills its box)
    local jc = P.jc
    if jc then
        DC.park(jc)
        if not DC.up(jc) then pcall(function() jc:setVisible(true) end) end
    end
    DC.read()
    -- (as the game's console: the line waits for a click before it takes the keyboard, so a console shown at the
    -- start of a game, the debug option UIDebugConsole.StartVisible, never eats the player's keys)
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


-- ---------------------------------------------------------------------------
-- EVERY FRAME (before the screens draw): the game's console parked, ZeD's window following its flag, the box read
-- ---------------------------------------------------------------------------
function DC.frame()
    if not DC.debug() then return end
    local jc = DC.game()
    if not jc then return end
    if DC.handedBack() or not DC.parts(jc).ok then
        -- (the game's own, where it was)
        if DC.isOpen() then DC.win:close(true) end
        DC.unpark(jc)
        return
    end
    DC.park(jc)
    -- the game's key flips the game's flag (so does its StartVisible option, and anything else that shows or hides
    -- the game's console): ZeD's window follows it, never the controller (the wheel's slice hands that over)
    local want = DC.up(jc) and onScreen(jc)
    if want and not DC.isOpen() then
        local ok, err = pcall(DC.open)
        if not ok then ZeD.logOnce("lua console open", err) end
    elseif not want and DC.isOpen() then
        DC.win:close(true)
    end
    if DC.isOpen() then DC.read() end
end

if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(DC.frame) end

-- ---------------------------------------------------------------------------
-- SAFE MODE: the game's own console back where it was (up if ZeD's was open: its flag stayed up), ZeD's after
-- ---------------------------------------------------------------------------
if ZeD.Safe and ZeD.Safe.register then
    ZeD.Safe.register("console", {
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

return DC
