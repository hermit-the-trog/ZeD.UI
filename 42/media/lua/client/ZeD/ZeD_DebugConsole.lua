-- ZeD-UI/42/media/lua/client/ZeD/ZeD_DebugConsole.lua
-- ============================================================================
-- THE LUA CONSOLE: the game's debug-mode console (only with -debug: run
-- Lua, read errors and output) as a ZeD window, from ZeD's own atoms and molecules.
-- Client. Organism (ZeD_DebugConsoleWindow on ZeD_Window), one window.
--
-- The game's console is Java (zombie.ui.UIDebugConsole, made by UIManager.init with the in-game screens and kept as
-- UIManager.getDebugConsole()). Its parts, read from the game's class files (42.21 and 42.22):
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
-- The window: a page strip down its left (Log; Commands and Help come later and say so), and the Log page: the
-- filters (KIND, MOD, FILE, each a ticked row with its count), the search with its magnifier and the count "shown of
-- total | errors", the log itself (ZeD_ConsoleLog.lua: the game's output and the F11 error list as one list, a row
-- each, a repeated error one row with its count, an error opening in place to its whole stack), the line to type in,
-- and the band: Export (what the filters show, to a new .log file in Zomboid/Lua), Copy (the picked row, or all that
-- is shown), Clear (the game's clear), Run. Enter runs, Up and Down step through the history, Tab takes the
-- suggestion; Escape lets the line go and stays the pause menu's (the window takes none of the game's keys: it may sit
-- open all game). As the game's, the line waits for a click before it takes the keyboard. Controller: the hand walks
-- the strip, the filters, the search, the log, the line and the band (A ticks, opens, types on ZeD's pad keyboard or
-- presses; LB / RB older and newer lines on the line; X exports; B closes). Opened by the game's own key, and in game
-- from the ZeD wheel (Select) for a controller. It exists exactly when the game's does: debug mode, the console made
-- and on the game's screen list. Safe mode (piece "console") puts the game's own back where it was, open if ZeD's was.
-- ============================================================================

require "ISUI/ISTextEntryBox"
require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_ConsoleLog"

ZeD = ZeD or {}
ZeD.DebugConsole = ZeD.DebugConsole or {}
local DC = ZeD.DebugConsole
local L = ZeD.ConsoleLog

-- design units
local U = { W = 900, H = 480, MIN_W = 520, MIN_H = 260, PAD = 8, GAP = 6, MARK = 6, BOTTOM = 140, LEFT = 20,
            STRIP = 34, FILTERS = 168, HEAD = 34, FOLD = 22, FROW = 20, ICON = 10 }
local F11_MS = 500          -- how often the F11 error list's count is read
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
    if not (P.ok and P.cmd) then return end
    if DC._mirrored == text then
        -- (still what the game's line holds? Something else may have set it: then it is worked again)
        local ok, cur = pcall(function() return P.cmd:getText() end)
        if not ok or cur == nil or tostring(cur) == text then return end
    end
    DC._mirrored = text
    pcall(function() P.cmd:SetText(text) end)
    -- (the game fills its suggestion box in its own update(), when the line's length has changed; it is run now, so the
    -- suggestion is there for Tab and for the help line in this same frame, never a frame late or not at all)
    -- (From UIDebugConsole.update() in the jar: it works the suggestion out only when the LENGTH of the line
    -- differs from the length it last worked on, and an emptied line does not reset that length. So a line of the same
    -- length as an earlier one gets nothing, and the box stays empty. The line is shown one character longer first, so
    -- the second update always sees a changed length and does the work for the line as it is.)
    if P.jc and text ~= "" then
        local ok, err = pcall(function()
            P.cmd:SetText(text .. " ")
            P.jc:update()
            P.cmd:SetText(text)
            P.jc:update()
        end)
        if not ok then
            pcall(function() P.cmd:SetText(text) end)   -- (the line is what was typed, whatever failed)
            ZeD.logOnce("lua console suggestion", tostring(err))
        end
    end
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
    -- (the log's "ran" row goes in first, so what the line prints lands under it)
    L.ran(line)
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
    if ok and t and t ~= "" and DC.fits(tostring(t), P.cmd) then return tostring(t) end
    return nil
end

-- The game's suggestion is the NEAREST global function by edit distance (UIDebugConsole.SuggestionEngine, Levenshtein),
-- not a completion: "getPl" gets "getCell" (3 edits) before "getPlayer" (4). It is also left standing when the line
-- changes to one it finds nothing for. A suggestion is taken as a completion only when its name starts with the word
-- typed after the last ":" or ".", so a nearest-but-unrelated one is never put into the line.
function DC.fits(sug, cmd)
    local line = ""
    pcall(function() line = tostring(cmd:getText() or "") end)
    local word = line:match("([%w_]*)$") or ""
    if word == "" then return true end
    local name = sug:match("([%w_]+)%s*$")
    if not name then return false end
    return name:sub(1, #word):lower() == word:lower()
end

-- Tab: the game's own key handler takes the suggestion into its line; the line comes back
function DC.complete(text)
    local jc = P.jc
    if not (jc and P.ok) then return nil end
    DC.mirror(text)
    if not DC.suggestion() then return nil end   -- (none, or the game's nearest word is not a completion of the line)
    local ok, t = pcall(function()
        jc:onOtherKey(TAB_KEY)
        return P.cmd:getText()
    end)
    if not ok or t == nil then return nil end
    t = tostring(t)
    DC._mirrored = t
    return t
end

-- Clear: the box emptied, as the game's own "clear" does, and the log with it (the F11 list's errors stay read)
function DC.clear()
    L.clear()
    if not (P.ok and P.out) then return end
    pcall(function() P.out:clearInput() end)
    DC.read()
    DC.feed()
end

-- the log fed: the box's new lines when its text changed, the F11 list's count every F11_MS, a waiting error flushed
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

-- ---------------------------------------------------------------------------
-- THE BOX AS LINES: the errors marked (QA scripts count the box's own errors with it; the log is ZeD_ConsoleLog's)
-- ---------------------------------------------------------------------------
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

-- the box's lines and its error count, worked out again when the text changes
function DC.lines()
    if DC._linesRev ~= DC.rev then
        DC._linesRev = DC.rev
        DC._lines, DC._errors = DC.parse(DC.text)
    end
    return DC._lines, DC._errors or 0
end

-- ---------------------------------------------------------------------------
-- THE WINDOW
-- ---------------------------------------------------------------------------
ZeD_DebugConsoleWindow = ZeD_Window:derive("ZeD_DebugConsoleWindow")
local W = ZeD_DebugConsoleWindow

local BAND = { "export", "copy", "clear", "run" }   -- the band's buttons, left to right (Run, the main one, last)
local RUN_AT = 4

-- the page strip's pictures, 10 x 10: lines of text, a slash, a question mark
local MAP_LOG = { "..........", "XXXXXXXXXX", "..........", "XXXXXX....", "..........", "XXXXXXXX..", "..........", "XXXX......", "..........", "XXXXXXX..." }
local MAP_CMD = { "..........", "........X.", ".......X..", "......X...", ".....X....", "....X.....", "...X......", "..X.......", ".X........", ".........." }
local MAP_HELP = { "...XXXX...", "..X....X..", "..X....X..", ".......X..", "......X...", ".....X....", ".....X....", "..........", ".....X....", ".........." }
local PAGES = {
    { id = "log", key = "UI_ZeD_Console_PageLog", map = MAP_LOG },
    { id = "cmds", key = "UI_ZeD_Console_PageCommands", map = MAP_CMD },
    { id = "help", key = "UI_ZeD_Console_PageHelp", map = MAP_HELP },
}

-- the KIND filter's rows: their words and status colors
local KIND_LABEL = { print = "UI_ZeD_Console_KindPrint", warn = "UI_ZeD_Console_KindWarn", error = "UI_ZeD_Console_KindError", ran = "UI_ZeD_Console_KindRan" }
local function kindColor(k)
    local T = ZeD.T
    if k == "error" then return T.danger end
    if k == "warn" then return T.warning end
    if k == "ran" then return T.accent end
    return T.textDim
end
local GROUPS = { { g = "kind", key = "UI_ZeD_Console_FoldKind" }, { g = "mod", key = "UI_ZeD_Console_FoldMod" }, { g = "file", key = "UI_ZeD_Console_FoldFile" } }

function W:new(x, y, w, h)
    local o = ZeD_Window.new(self, x, y, w, h, "")
    o.resizable = true
    o.pin = true
    o.moveWithMouse = false
    o.playerNum = 0
    o.page = "log"
    o.scroll = 0          -- px up from the newest row (0: the newest at the foot, following)
    o.fScroll = 0         -- the filter column's scroll, px from its top
    o.zone = "input"      -- controller: "strip" | "filters" | "search" | "list" | "input" | "band"
    o.bandFocus = RUN_AT  -- controller: Run
    o.stripFocus = 1
    o.fFocus = 1
    o.pick = nil          -- the picked row (a row of the log)
    o.opened = {}         -- the errors opened to their stacks: row id -> row
    o.fold = {}           -- the filter groups folded shut: group -> true
    o.hi = nil            -- the history line shown (nil: what was being typed)
    o.draft = ""
    o._bandOff = {}
    o._findSt = {}
    return o
end

-- a hidden game text box: it takes the keys and the cursor, the window draws its words (_drawTyped)
local function makeEntry(win, maxLen)
    local T = ZeD.T
    local e = ISTextEntryBox:new("", 0, 0, 100, T.inputH)
    -- The game's text box takes the keys; its own text is hidden (fitEntry) and the window draws the
    -- line in F3, Fira Mono, like the lines above it: the box can only draw the game's baked faces.
    e.zedDrawsText = true
    e:initialise()
    e:instantiate()
    e.zedEntry = true
    pcall(function() e.javaObject:setCentreVertically(true) end)
    e:setPlaceholderText("")   -- (ZeD draws the placeholder, _drawTyped)
    e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    e:setMaxTextLength(maxLen)
    win:addChild(e)
    return e
end

function W:createChildren()
    ZeD_Window.createChildren(self)
    local e = makeEntry(self, LINE_MAX)
    local win = self
    e.onCommandEntered = function() win:runLine() end
    e.onPressUp = function() win:historyStep(-1) end
    e.onPressDown = function() win:historyStep(1) end
    e.onOtherKey = function(_, key)
        if key == Keyboard.KEY_ESCAPE then e:unfocus()
        elseif key == TAB_KEY then win:complete() end
    end
    self.input = e
    -- the search: Enter and Escape let it go (the log follows each key, in prerender)
    local f = makeEntry(self, 100)
    f.onCommandEntered = function() f:unfocus() end
    f.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then f:unfocus() end end
    self.find = f
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

-- the words for the clipboard: the picked row (an error with its whole stack), or every row the filters show
function W:copyText()
    if self.pick then return table.concat(L.rowText(self.pick), "\n") end
    return L.shownText()
end

-- Export: what the filters show, to a new file; the band says where
function W:export()
    local shown = L.counts()
    if shown == 0 then return end
    local name, n, tried = L.export()
    local T = ZeD.T
    if name then
        self._status = { text = tr("UI_ZeD_Console_Exported", n, name), color = T.positive }
        DC.lastExport = name
    else
        self._status = { text = tr("UI_ZeD_Console_ExportFailed", tried or ""), color = T.danger }
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

-- keepFlag: the game's console's own flag already went down (or stays up for safe mode); otherwise it goes down too
function W:close(keepFlag)
    if not keepFlag and P.jc then pcall(function() P.jc:setVisible(false) end) end
    if self.input then self.input:unfocus() end
    if self.find then self.find:unfocus() end
    local KB = ZeD.Keyboard
    if KB and KB.instance and (KB.instance.textEntryBox == self.input or KB.instance.textEntryBox == self.find) then pcall(function() KB.instance:hide() end) end
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
local function mark(win, x, y, w, h)
    if ZeD.Focus and ZeD.Focus.mark then return ZeD.Focus.mark(win, x, y, w, h, focusOpts(win)) and true or false end
    return false
end

-- the width of one character of the fixed-pitch face (F3, Fira Mono)
local function charW(font)
    return math.max(1, ZeD.TM:MeasureStringX(font, "0000000000") / 10)
end

-- A typed line, drawn in F3 over the game's hidden text box: the characters that fit, scrolled so the cursor stays
-- in view, the placeholder when empty, and a steady caret while focused. st keeps where it scrolled to (the line
-- keeps it on the window, the search on its own table).
function W:_drawTyped(inp, x, y, w, h, f, focused, placeholder, st)
    local T = ZeD.T
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

-- the hidden box kept left of the window, where its clip is empty, sized and placed as the field it serves
local function parkEntry(inp, ew, y, ih)
    local offX = -(ew + px(60))
    if inp:getX() ~= offX then inp:setX(offX) end
    if inp:getY() ~= y then inp:setY(y) end
    if inp:getWidth() ~= ew then inp:setWidth(ew) end
    if inp:getHeight() ~= ih then inp:setHeight(ih) end
end

-- the click's column in a drawn line, given to the hidden box's cursor
local function placeCursor(inp, st, x)
    if not (st._typeCw and st._typeX) then return end
    local col = (st._typeStart or 0) + math.floor((x - st._typeX) / st._typeCw + 0.5)
    local len = #(inp:getText() or "")
    col = math.max(0, math.min(len, col))
    pcall(function() inp.javaObject:setCursorPos(col) end)
end

function W:prerender()
    local T = ZeD.T
    if not T then return end
    if not DC.exists() then self:close(true); return end
    self.minimumWidth, self.minimumHeight = px(U.MIN_W), px(U.MIN_H)
    self.title = tr("UI_ZeD_Console_Title")
    local errs = L.errTotal or 0
    if errs > 0 then
        self._stat = self._stat or { {} }
        local st = self._stat[1]
        st.text, st.color = tr("UI_ZeD_Console_Errors", errs), T.danger
        self.titleStats = self._stat
    else
        self.titleStats = {}
    end
    -- the search follows each key typed (a new search walks the rows once)
    if self.find then
        local q = tostring(self.find:getText() or "")
        if q ~= L.q then L.setQuery(q); self.scroll = 0 end
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

    -- the page strip
    local sw = px(U.STRIP)
    self:_drawStrip(0, top, sw, bandY - top, joy)
    local cx = sw
    if self.page == "log" then
        local fw = math.min(px(U.FILTERS), math.floor((w - sw) * 0.36))
        self._filterRect = { x = sw, y = top, w = fw, h = bandY - top }
        self:_drawFilters(sw, top, fw, bandY - top, joy)
        cx = sw + fw
        local hh = px(U.HEAD)
        self:_drawHead(cx, top, w - cx, hh, joy)
        local ly0, ly1 = top + hh + px(4), iy - gap
        self._listRect = { x = cx + pad, y = ly0, w = w - cx - 2 * pad, h = math.max(0, ly1 - ly0) }
        self:_drawList(cx + pad, ly0, w - cx - 2 * pad, math.max(0, ly1 - ly0))
    else
        self._filterRect, self._headRect, self._findRect = nil, nil, nil
        self._listRect = { x = cx + pad, y = top + pad, w = w - cx - 2 * pad, h = math.max(0, iy - gap - top - pad) }
        self._rowHits = {}
        ZeD.Molecules.drawEmptyLine(self, cx + pad * 2, top + pad * 2, w - cx - pad * 4, tr("UI_ZeD_Console_Coming"))
    end
    self:_drawLine(cx + pad, iy, w - cx - 2 * pad, ih, joy)
    -- the band: Export, Copy, Clear, Run
    self:_drawBand(bandY, w, joy)
end

-- the line to type in: a field, the prompt mark, the game's text box hidden behind it
function W:_drawLine(fx, iy, fw, ih, joy)
    local T = ZeD.T
    local inp = self.input
    local s1, bs = T.surf1, T.borderS
    self:drawRect(fx, iy, fw, ih, s1.a or 1, s1.r, s1.g, s1.b)
    local focused = inp and inp:isFocused()
    local ib = focused and T.accent or bs
    self:drawRectBorder(fx, iy, fw, ih, ib.a or 1, ib.r, ib.g, ib.b)
    local f3 = T.fontF3
    local mx0 = fx + px(6)
    local td = T.textDim
    self:drawText(">", mx0, iy + math.floor((ih - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
    local ex = mx0 + ZeD.TM:MeasureStringX(f3, ">") + px(4)
    if inp then
        -- The game's box draws its own text, its caret and its placeholder, always opaque (UITextBox2.render passes alpha 1
        -- for them whatever setTextRGBA says), inside a clip clamped to its parent. It keeps the keys and the cursor, so it
        -- stands left of the window, where that clip is empty; ZeD draws the line (_drawTyped) and takes the clicks.
        local ew = fx + fw - px(4) - ex
        parkEntry(inp, ew, iy, ih)
        self:_drawTyped(inp, ex, iy, ew, ih, f3, focused, tr("UI_ZeD_Console_Type"), self)
    end
    if joy and self.zone == "input" then mark(self, fx, iy, fw, ih) end
    self._fieldRect = { x = fx, y = iy, w = fw, h = ih }
end

-- the page strip: a picture per page, the shown page in the accent
function W:_drawStrip(x, y, w, h, joy)
    local T = ZeD.T
    local A = ZeD.Atoms
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
        if hover then ZeD.Help.set(self, tr(pg.key)) end
    end
end

-- the filter column's rows, flat: a fold header per group, then its ticked rows (unless folded); made again only when
-- a mod or file comes or goes, or a group folds
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
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    A.drawDividerV(self, x + w - px(1), y, h)
    local items = self:_filterItems()
    local foldH, rowH = px(U.FOLD), px(U.FROW)
    local total = px(4)
    for _, it in ipairs(items) do total = total + (it.t == "fold" and foldH or rowH) end
    local bar = total > h
    local sbW = T.sp.scrollbarW
    local iw = w - px(1) - (bar and sbW or 0)
    local maxS = math.max(0, total - h)
    -- the controller's row brought into view
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
    local Fo = ZeD.Input and ZeD.Input.Focus
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
    local T = ZeD.T
    local A = ZeD.Atoms
    local onFocus = false
    if hover then
        local hv = T.hover
        self:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
        ZeD.Help.set(self, tr("UI_ZeD_Console_HelpFilter"))
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
    local nw = ZeD.TM:MeasureStringX(f3, ns)
    local dc = onFocus and T.textOnFocus or T.textDim
    self:drawText(ns, x + w - px(6) - nw, y + math.floor((h - fh(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    local c = onFocus and T.textOnFocus or (on and T.text or T.textDim)
    local label = A.truncateText(itemLabel(it), f2, math.max(0, x + w - px(12) - nw - tx))
    self:drawText(label, tx, y + math.floor((h - fh(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
end

-- the head over the log: the search with its magnifier, then "shown of total | errors"
function W:_drawHead(x, y, w, h, joy)
    local T = ZeD.T
    local A = ZeD.Atoms
    local pad = px(U.PAD)
    A.drawDividerH(self, x, y + h - px(1), w)
    local shown, total, errs = L.counts()
    local cs = tr("UI_ZeD_Console_Count", shown, total, errs)
    local f3 = T.fontF3
    local cw = ZeD.TM:MeasureStringX(f3, cs)
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
        self:_drawTyped(self.find, ex, fy, ew, ih, f3, focused, tr("UI_ZeD_Console_Search"), self._findSt)
    end
    if joy and self.zone == "search" then mark(self, fx, fy, fw, ih) end
    self._findRect = { x = fx, y = fy, w = fw, h = ih }
    self._headRect = { x = x, y = y, w = w, h = h }
    local tc = T.textDim
    if fx + fw + px(10) + cw <= x + w then
        self:drawText(cs, x + w - pad - cw, y + math.floor((h - fh(f3)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f3)
    end
end

-- ---------------------------------------------------------------------------
-- THE LOG LIST: a row a line (time | status pixel and kind word | message | mod and file:line | count); the picked
-- row shows its whole message, an opened error its whole stack under it
-- ---------------------------------------------------------------------------
-- a text cut every cpr characters (a fixed-pitch face: the cut is exact)
local function cutInto(out, s, cpr)
    if s == "" then out[#out + 1] = ""; return end
    local p = 1
    while p <= #s do
        out[#out + 1] = s:sub(p, p + cpr - 1)
        p = p + cpr
    end
end

-- the lines a row's message and stack take at these widths (kept on the row until a width or its stack changes)
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

-- the columns of a row at this width: x of each, characters each takes
function W:_cols(x, w)
    local T = ZeD.T
    local f = T.fontF3
    local cw = charW(f)
    local c = self._colsC or {}
    self._colsC = c
    c.cw = cw
    c.timeX = x + px(4)
    c.kindX = c.timeX + 8 * cw + px(8)
    local kw = 0
    for _, k in ipairs(L.KINDS) do kw = math.max(kw, ZeD.TM:MeasureStringX(f, L.kindWord(k))) end
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

-- the rows' heights from the foot: how far up the picked row's top and foot sit, for bringing it into view
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
    local T = ZeD.T
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
    -- new rows while scrolled up: the view stays where it was (the new rows' height added to the scroll)
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
    -- the scrollbar (top-down; this list counts from its foot)
    if bar then
        local win = self
        ZeD.Molecules.scrollBar(self, nil, "log", x + w - sbW, y, sbW, h, maxS - self.scroll, total,
            function(v) win.scroll = math.max(0, (win._maxS or 0) - v) end, { step = lh })
    end
    if n == 0 then
        local _, kept = L.counts()
        ZeD.Molecules.drawEmptyLine(self, x, y, w, kept == 0 and tr("UI_ZeD_Console_Empty") or tr("UI_ZeD_Console_NoMatch"))
        return
    end
    self:_drawRows(c, x, y, h, lh, n)
    -- scrolled up: a mark at the foot that newer rows are below
    if self.scroll > 0 then
        ZeD.Atoms.drawStatusDot(self, c.right - px(8), y + h - px(8), T.accent, px(6))
    end
end

function W:_drawRows(c, x, y, h, lh, n)
    local joy = self.joyfocus ~= nil
    local mx, my = self:getMouseX(), self:getMouseY()
    local Fo = ZeD.Input and ZeD.Input.Focus
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
    if hovered then ZeD.Help.set(self, tr("UI_ZeD_Console_HelpRow")) end
end

-- one line of a row, drawn only where the list shows it (a tall opened stack runs far past the view)
local function inView(c, yy) return yy + c.lh > c.vy0 and yy < c.vy1 end

-- the row's first line: time, status pixel and kind word, the triangle of an error, then its place and count
function W:_drawRowHead(row, c, y, dc, onFocus, isOpen)
    local T = ZeD.T
    local A = ZeD.Atoms
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
        local sw = ZeD.TM:MeasureStringX(f, src)
        self:drawText(src, c.right - c.repW - px(8) - sw, ty, dc.r, dc.g, dc.b, dc.a or 1, f)
    end
    if (row.n or 1) > 1 then
        local rs = "x" .. tostring(row.n)
        local rw = ZeD.TM:MeasureStringX(f, rs)
        self:drawText(rs, c.right - rw, ty, dc.r, dc.g, dc.b, dc.a or 1, f)
    end
end

function W:_drawRow(row, c, x, y, rh, hover)
    local T = ZeD.T
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
    b0.label, b0.help = btn(tr("UI_ZeD_Console_Export")), tr("UI_ZeD_Console_HelpExport")
    b0.disabled = shown == 0
    if (self._copiedUntil or 0) > now then b1.label = btn(tr("UI_ZeD_Msg_Copied"))
    else b1.label = btn(self.pick and tr("UI_ZeD_Msg_CopyOne") or tr("UI_ZeD_Console_CopyAll")) end
    b1.help = self.pick and tr("UI_ZeD_Console_HelpCopy") or tr("UI_ZeD_Console_HelpShown")
    b1.disabled = shown == 0
    b2.label, b2.help = btn(tr("UI_ZeD_Console_Clear")), tr("UI_ZeD_Console_HelpClear")
    b2.disabled = total == 0 and DC.text == ""
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
    _spec.status = self._status
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
-- an error opened to its stack, or shut again
function W:toggleOpen(row)
    if not row or row.kind ~= "error" then return end
    if self.opened[row.id] then self.opened[row.id] = nil else self.opened[row.id] = row end
    L.viewRev = L.viewRev + 1
end

-- A click on a row picks it (again lets it go). An error opens to its stack on its first click; a click on a picked
-- error, or on its triangle, opens or shuts it.
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

-- a press on the filter column: a fold header folds its group, a row ticks or unticks its filter
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
    self.page = id
    sound()
    if id ~= "log" and (self.zone == "filters" or self.zone == "search" or self.zone == "list") then self.zone = "strip" end
end

local function inBar(sb, x, y) return sb and sb.visible and x >= sb.x and x < sb.x + sb.width and y >= sb.y and y < sb.y + sb.height end

function W:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if inRect(self:windowBoxRect(), x, y) then return true end
    local bars = self._zedBars
    -- (the scrollbars read the pointer themselves while they draw: a press on one is theirs alone)
    if bars and (inBar(bars.log, x, y) or inBar(bars.filters, x, y)) then return true end
    for _, r in ipairs(self._bandRects or {}) do
        if inRect(r, x, y) then self._down = r.id; return true end
    end
    for _, r in ipairs(self._stripHits or {}) do
        if inRect(r, x, y) then self:setPage(r.page); return true end
    end
    if inRect(self._fieldRect, x, y) then
        self.zone = "input"
        self.input:focus()
        -- the cursor goes where the click lands in ZeD's drawn line, not the hidden box's own face
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
    -- the title bar (and the edges): ZeD_Window starts the drag or the resize. Whatever it answers, a press inside the window is ours.
    ZeD_Window.onMouseDown(self, x, y)
    return true
end

function W:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down then
        for _, r in ipairs(self._bandRects or {}) do
            if r.id == down and inRect(r, x, y) then self:press(down) end
        end
        return true
    end
    ZeD_Window.onMouseUp(self, x, y)
    return true
end

function W:onMouseUpOutside(x, y)
    self._down = nil
    ZeD_Window.onMouseUpOutside(self, x, y)
    return true
end

-- A drag of the window and a drag on a scrollbar's thumb are separate: the window's drag (ZeD_Window, as every ZeD
-- window) always gets the move, in the window or outside it; the bars follow the pointer themselves as they draw.
function W:onMouseMove(dx, dy)
    ZeD_Window.onMouseMove(self, dx, dy)
    return true
end
function W:onMouseMoveOutside(dx, dy)
    ZeD_Window.onMouseMoveOutside(self, dx, dy)
    return true
end
-- (42.22: a handler that is not there passes the click to what is beneath, one that returns nothing takes it)
function W:onRightMouseDown(x, y) return true end
function W:onRightMouseUp(x, y) return true end

function W:onMouseWheel(del)
    local mx, my = self:getMouseX(), self:getMouseY()
    if inRect(self._filterRect, mx, my) then
        self.fScroll = math.max(0, math.min(self._fMax or 0, self.fScroll + del * px(U.FROW) * 3))
        return true
    end
    local lh = self._lh or px(14)
    self.scroll = math.max(0, math.min(self._maxS or 0, self.scroll - del * lh * 3))
    return true
end

function W:update()
    ZeD_Window.update(self)
    if not self:getIsVisible() then return end
    -- a drag whose release the engine missed (it ticks update every 100 ms) ends here, as the resize does
    if self.moving and not isMouseButtonDown(0) then self.moving = false end
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (DC.qaJoy and self or nil)
    -- the pad keyboard put away: a line typed lands the controller on Run (the main button); the search stays put
    if self._kbOpen then
        local KB = ZeD.Keyboard
        if not (KB and KB.isVisible and KB.isVisible()) then
            self._kbOpen = nil
            if self._kbEntry == self.input then
                local t = self:lineText()
                if t ~= self._kbFrom and not blank(t) then self.zone, self.bandFocus = "band", RUN_AT end
            end
        end
    end
end

-- (KEYS: the window takes none of the game's keys. Escape stays the pause menu's, as with the game's console, which
-- may sit open all game long: the debug option UIDebugConsole.StartVisible. Escape in the typed line lets it go.)

-- ---------------------------------------------------------------------------
-- CONTROLLER: the strip, the filters, the search, the log, the line, the band
-- ---------------------------------------------------------------------------
function W:onGainJoypadFocus(jd) self.joyfocus = jd end
function W:onLoseJoypadFocus(jd) self.joyfocus = nil end

-- the pad keyboard on a line (ZeD's, through the game's OnScreenKeyboard.Show); it gives the controller back here
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

function W:onJoypadDown(button, jd)
    if button == Joypad.BButton then self:close(); return end
    if button == Joypad.XButton and self.page == "log" then
        if L.counts() > 0 then sound("UIActivateButton"); self:export() end
        return
    end
    if button ~= Joypad.AButton then
        if self.zone == "input" then
            if button == Joypad.LBumper then self:historyStep(-1); sound()
            elseif button == Joypad.RBumper then self:historyStep(1); sound() end
        end
        return
    end
    local z = self.zone
    if z == "input" then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus, self.input)
    elseif z == "search" then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus, self.find)
    elseif z == "strip" then local pg = PAGES[self.stripFocus]; if pg then self:setPage(pg.id) end
    elseif z == "filters" then self:useFilter(self:_filterItems()[self.fFocus])
    elseif z == "list" then if self.pick and self.pick.kind == "error" then sound(); self:toggleOpen(self.pick); self.seek = true end
    elseif z == "band" then
        local id = BAND[self.bandFocus]
        if id then self:press(id) end
    end
end

-- the next or previous shown row (d -1: older, up), false at either end
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

-- the top row the list shows now (going down into the log from the search)
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

function W:padDir(dir)
    local z = self.zone
    local log = self.page == "log"
    if z == "strip" then
        if dir == "up" and self.stripFocus > 1 then self.stripFocus = self.stripFocus - 1
        elseif dir == "down" and self.stripFocus < #PAGES then self.stripFocus = self.stripFocus + 1
        elseif dir == "right" then self.zone = log and "filters" or "input" end
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
    local Pr = ZeD.Prompt
    local move = tr("UI_ZeD_Prompt_DPadMove")
    local out = { (Pr and Pr.padNote) and Pr.padNote(move) or move }
    local z = self.zone
    if z == "input" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Keyboard") }
        out[#out + 1] = { glyph = "LB", label = tr("UI_ZeD_Console_PadOlder") }
        out[#out + 1] = { glyph = "RB", label = tr("UI_ZeD_Console_PadNewer") }
    elseif z == "band" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Press") }
    else
        local a = nil
        if z == "strip" then a = tr("UI_ZeD_Prompt_Select")
        elseif z == "search" then a = tr("UI_ZeD_Prompt_Keyboard")
        elseif z == "filters" then
            local it = self:_filterItems()[self.fFocus]
            if it and it.t == "fold" then a = self.fold[it.g] and tr("UI_ZeD_Prompt_Unfold") or tr("UI_ZeD_Prompt_Fold")
            elseif it then a = tr("UI_ZeD_Console_PadTick") end
        elseif z == "list" and self.pick and self.pick.kind == "error" then
            a = self.opened[self.pick.id] and tr("UI_ZeD_Prompt_Fold") or tr("UI_ZeD_Prompt_Unfold")
        end
        if a then out[#out + 1] = { glyph = "A", label = a } end
        if self.page == "log" then out[#out + 1] = { glyph = "X", label = tr("UI_ZeD_Console_Export") } end
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
    -- (the log opens at its foot, every error shut to its first line)
    win.scroll, win.pick, win.hi, win.opened = 0, nil, nil, {}
    win._status = nil
    -- (the game's console up with it, parked: its flag says open, and it fills its box)
    local jc = P.jc
    if jc then
        DC.park(jc)
        if not DC.up(jc) then pcall(function() jc:setVisible(true) end) end
    end
    DC.read()
    DC.feed()
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
    -- (the F11 list keeps only its last 40 entries: it is read while the window is shut too)
    local ok, err = pcall(DC.feed)
    if not ok then ZeD.logOnce("lua console log", err) end
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
