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
--
-- The scratchpad (ZeD_ConsoleScratch.lua) opens in place of the line: the Scratchpad keycap beside the line swaps it
-- for a box of many lines with numbered lines, and One line swaps back. Beside the box, SNIPPETS and HISTORY under fold
-- headers (both kept in Zomboid/Lua); a click or A loads one into the box, a right-click or X on a snippet renames it.
-- Enter runs the box and Shift+Enter makes a new line; Up on the first line and Down on the last step through the
-- runs. Save snippet asks for a name in the band (the name field, Cancel, Save). With no loadstring the box grays, a
-- notice says why, Run grays and One line is the default keycap. Controller: the hand reaches the box, the lists and
-- the band; A types or loads, X saves a snippet, Y swaps the line and the box.
-- The game's multi-line text box never calls onCommandEntered: Enter puts a newline in at the cursor. So Enter is
-- told by the text: one newline more, where the cursor was, Shift up, and the box runs with that newline taken out.
-- Its setCursorPos also clamps to the length of the cursor's line, so a cursor is placed with multi-line off. The
-- box may hold 2000 lines: its text is split once per text (padInfo), and a frame reads only that.
--
-- The suggestions (ZeD_ConsoleComplete.lua) open by themselves as a pull-down above the caret, in the line and the
-- box: globals after two letters, a table's fields after ".", an object's methods after ":" (Java ones marked
-- Java). Tab or Enter takes one, Up and Down move through them, Escape shuts them (again, lets the line go); a
-- click takes one. With no pull-down, Tab is still the game's own suggestion. Controller: the pull-down shows while
-- the pad keyboard types; when it is put away the hand lands on the pull-down (D-pad up reaches it from the line),
-- A takes one, B shuts it. The Help and Commands pages are drawn by ZeD_ConsolePages.lua.
-- ============================================================================

require "ISUI/ISTextEntryBox"
require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_ConsoleLog"
require "ZeD/ZeD_ConsoleScratch"
require "ZeD/ZeD_ConsoleComplete"

ZeD = ZeD or {}
ZeD.DebugConsole = ZeD.DebugConsole or {}
local DC = ZeD.DebugConsole
local L = ZeD.ConsoleLog
local S = ZeD.ConsoleScratch
local AC = ZeD.ConsoleComplete

-- design units
local U = { W = 900, H = 480, MIN_W = 520, MIN_H = 260, PAD = 8, GAP = 6, MARK = 6, BOTTOM = 140, LEFT = 20,
            STRIP = 34, FILTERS = 168, HEAD = 34, FOLD = 22, FROW = 20, ICON = 10,
            PADBOX = 134, PADMIN = 60, META = 26, SIDE = 196, GUT = 26,
            ACROW = 20, ACMIN = 300, ACMAX = 460, ACKIND = 92 }
local PAD_MAX = 60000       -- the scratchpad takes this many characters (the game's line: 256)
local PAD_LINES = 2000      -- and this many lines
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
-- (a file Zomboid/Lua/ZeD_console_off.txt hands the console back to the game for good, read once when this file
-- loads: a switch for QA to rule ZeD's console in or out of a fault in one launch, Nov 12 2026)
local OFF_BY_FILE = false
do
    local ok, r = pcall(getFileReader, "ZeD_console_off.txt", false)
    if ok and r then
        OFF_BY_FILE = true
        pcall(function() r:close() end)
        print("[ZeD] Lua console: handed back to the game (Zomboid/Lua/ZeD_console_off.txt)")
    end
end
function DC.handedBack()
    if OFF_BY_FILE then return true end
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
    -- (the log's "ran" row goes in first, so what the line prints lands under it; the run goes on the kept history)
    L.ran(line)
    S.addHistory(line)
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
    o.mode = "line"       -- "line" | "pad" (the scratchpad in its place)
    o.phi = nil           -- the scratchpad's kept run shown (an index of S.history; nil: what was being typed)
    o.pdraft = ""
    o.sFocus = 1          -- controller: the row of the snippets and history column
    o.sScroll = 0
    o.sFold = {}          -- "snips" / "hist" folded shut
    o.naming = nil        -- the band asking for a name: { kind = "save" | "rename", i = snippet }
    o._padSt = {}
    o._nameSt = {}
    o._keyHits = {}
    o._bandOff = {}
    o._findSt = {}
    o.ac = nil            -- the suggestions open (ZeD.ConsoleComplete.complete's answer), nil when shut
    o.acI = 1             -- the one picked
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
    -- (with the suggestions open, Enter, Tab, Up, Down and Escape are theirs, a pick too long for the line included:
    -- the key is used up, never passed on to run the half-typed line or to the game's own suggestion)
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
    -- the search: Enter and Escape let it go (the log follows each key, in prerender)
    local f = makeEntry(self, 100)
    f.onCommandEntered = function() f:unfocus() end
    f.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then f:unfocus() end end
    self.find = f
    -- the scratchpad: the game's box on many lines, never wrapped (a line of code is a line); Enter is told in prerender
    local p = makeEntry(self, PAD_MAX)
    p:setMultipleLine(true)
    pcall(function() p:setMaxLines(PAD_LINES) end)
    pcall(function() p.javaObject:setWrapLines(false) end)
    pcall(function() p.javaObject:setCentreVertically(false) end)
    -- (the box has moved its cursor before it calls these: with the suggestions open it goes back where it was)
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
    -- the name a snippet is saved under, asked in the band
    local n = makeEntry(self, S.NAME_MAX)
    n.onCommandEntered = function() win:nameDone(true) end
    n.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then win:nameDone(false) end end
    self.nameE = n
end

function W:lineText()
    return self.input and tostring(self.input:getText() or "") or ""
end
-- (stops at the first character that is not a space: taking every space out copied the whole box)
local function blank(s) return string.find(s, "%S") == nil end

-- Enter, Run, A on Run
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


-- ---------------------------------------------------------------------------
-- THE SCRATCHPAD: the box, its runs and its kept history, the swap, the snippets
-- ---------------------------------------------------------------------------
function W:padText()
    return self.pad and tostring(self.pad:getText() or "") or ""
end

-- where the cursor of a game text box is (0: before the first character)
local function cursorOf(inp, text)
    local cur = #text
    pcall(function() cur = inp.javaObject:getCursorPos() end)
    return math.max(0, math.min(#text, tonumber(cur) or #text))
end
DC.cursorOf = cursorOf

-- the line (0-based) and column a cursor stands at
-- (a walk from newline to newline with plain finds: the unanchored match for the cursor's column restarted at every
-- character and cost about 300 ms over a 1500-line box)
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

-- The box's text, worked out once per text and kept on the window: where each line starts (0-based, the character
-- after a newline), how many lines, whether any line holds a "\r" (taken out when drawn, as S.lines does) and
-- whether it is blank. Everything the box draws each frame reads from it.
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

-- the line (0-based) a position stands on: the last line start at or before it
local function lineAt(c, pos)
    local s = c.starts
    local lo, hi = 1, #s
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if s[mid] <= pos then lo = mid else hi = mid - 1 end
    end
    return lo - 1
end

-- line li (0-based) as drawn, its columns left + 1 to left + cols ("" when it ends before them; nil past the last)
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

-- (the game's setCursorPos clamps to the cursor line's length while the box is on many lines: placed with it off)
local function setCursor(inp, text, cur, line)
    pcall(function()
        local j = inp.javaObject
        j:setMultipleLine(false)
        j:setCursorPos(cur)
        j:setMultipleLine(true)
        j:setCursorLine(line or (lineCol(text, cur)))
    end)
end

--- The box's words set, the cursor at cur (default: the end); what the Enter test compares with follows.
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

-- One newline more than last frame, where the cursor stood, with Shift up: that was Enter, which runs the box.
-- (The pad keyboard's Enter makes a new line: the band's Run runs.)
-- With the suggestions open, Enter takes one instead, and so does a Tab the box put in as a character.
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

-- the box's cursor back where it stood last frame (Up and Down moved it while the suggestions were open)
function W:_padHold()
    local text = self:padText()
    if self._padPrev == text and self._padCur then setCursor(self.pad, text, self._padCur, lineAt(padInfo(self, text), self._padCur)) end
end

-- ---------------------------------------------------------------------------
-- THE SUGGESTIONS: worked out when the words or the cursor change, never on a frame where neither did
-- ---------------------------------------------------------------------------
-- the text box they follow: the line or the box, while it is typed in (on the keys or the pad keyboard) or the
-- controller's hand is on the pull-down; nil on the other pages and while the band asks a name
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
    -- (the box, the cursor and the words as they were last worked out, compared as they are: joined into one key
    -- string they made a copy of the whole box every frame)
    local k = self._acKey
    if k and k.inp == inp and k.cur == cur and k.text == text then return end
    k = { inp = inp, cur = cur, text = text }
    self._acKey = k
    -- (shut with Escape: it stays shut until the words or the cursor move)
    local sk = self._acShutKey
    if sk and sk.inp == inp and sk.cur == cur and sk.text == text then self.ac = nil; return end
    self._acShutKey = nil
    local ok, ac = pcall(AC.complete, text, cur)
    if not ok then ZeD.logOnce("lua console suggestions", ac); ac = nil end
    -- (a list that only narrows keeps the same name picked)
    local was = self.ac and self.ac.items[self.acI]
    self.ac, self.acI = ac, 1
    if ac and was then
        for i, it in ipairs(ac.items) do if it.n == was.n then self.acI = i end end
    end
    if not ac and self.zone == "ac" then self.zone = "input" end
end

--- Up (-1) or Down (1) through the suggestions.
function W:acMove(d)
    local ac = self.ac
    if not ac then return end
    self.acI = math.max(1, math.min(#ac.items, self.acI + d))
    sound()
end

--- Escape: the suggestions shut until the words or the cursor move.
function W:acShut()
    if not self.ac then return end
    self._acShutKey = self._acKey
    self.ac = nil
    if self.zone == "ac" then self.zone = "input" end
end

--- Take suggestion i (default: the picked one) into the line or the box. False when none is open, or when the
--- pick would not fit the line (the pull-down stays and the band says why).
function W:acTake(i)
    local ac = self.ac
    if not ac or not ac.items[i or self.acI] then return false end
    local pad = self.mode == "pad"
    local text = pad and self:padText() or self:lineText()
    local t, cur = AC.take(text, ac, i or self.acI)
    if pad then
        self:_padSet(t, cur)
    else
        -- (the game's line takes 256 characters: a pick that would pass them is not taken)
        if #t > LINE_MAX then
            self._status = { text = tr("UI_ZeD_Console_LineFull", LINE_MAX), color = ZeD.T.warning, lineFull = true }
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

-- Up and Down in the box (the game has moved its cursor already): from the first line, or the last, the kept runs
function W:padArrow(d)
    local prev, pc = self._padPrev or self:padText(), self._padCur or 0
    if d < 0 and prev:sub(1, pc):find("\n", 1, true) then return end
    if d > 0 and prev:sub(pc + 1):find("\n", 1, true) then return end
    self:padHistory(d)
end

--- The kept runs, oldest first: d -1 older, 1 newer; past the newest, what was being typed comes back. An older run
--- lands with the cursor on its first line, a newer one on its last, so the next step goes on.
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

--- Run the box (Enter, Run, A on Run): through loadstring, the run and its output in the log, the box emptied.
function W:runPad()
    local text = self:padText()
    if blank(text) or not DC.allowed() then return end
    if not S.canRun() then
        self._status = { text = tr("UI_ZeD_Console_HelpNoLoad"), color = ZeD.T.danger }
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

--- The line or the scratchpad. The line's words go into an empty box; a box of one short line comes back to an
--- empty line. Whichever held the keys hands them over.
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

--- A snippet or a run into the box (the run marked as the one shown, so Up and Down go on from it).
function W:loadCode(code, phi)
    self:_padSet(code)
    self.phi = phi
    self._status = nil
    sound()
    if not self.joyfocus then self.pad:focus() end
end

--- The band asks for a name: "save" (the box as a new snippet, its first line offered) or "rename" (snippet i).
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

--- The band's answer: ok saves or renames under the name typed (a rename to a name in use waits for another).
function W:nameDone(ok)
    local n = self.naming
    if not n then return end
    local T = ZeD.T
    local name = tostring(self.nameE:getText() or "")
    -- (Save is grayed with no name: Enter on an empty field waits for one too)
    if ok and blank(name) then return end
    if ok then
        if n.kind == "rename" then
            local done, wrote = S.rename(n.i, name)
            if not done then return end
            self._status = wrote and { text = tr("UI_ZeD_Console_Renamed", S.snippets[n.i].name), color = T.positive }
                or { text = tr("UI_ZeD_Console_ExportFailed", S.SNIP_FILE), color = T.danger }
        else
            local i, wrote = S.saveSnippet(name, self:padText())
            if not i then return end
            self._status = wrote and { text = tr("UI_ZeD_Console_Saved", S.snippets[i].name), color = T.positive }
                or { text = tr("UI_ZeD_Console_ExportFailed", S.SNIP_FILE), color = T.danger }
        end
        sound("UIActivateButton")
    end
    self.naming = nil
    self.nameE:unfocus()
    self.nameE:setText("")
    if self.zone == "band" then self.bandFocus = RUN_AT end
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

-- keepFlag: the game's console's own flag already went down (or stays up for safe mode); otherwise it goes down too
function W:close(keepFlag)
    if not keepFlag and P.jc then pcall(function() P.jc:setVisible(false) end) end
    if self.input then self.input:unfocus() end
    if self.find then self.find:unfocus() end
    if self.pad then self.pad:unfocus() end
    if self.naming then self:nameDone(false) end
    self.ac = nil
    local mine = self._pageClose and self:_pageClose() or {}
    local KB = ZeD.Keyboard
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
    -- Enter in the scratchpad runs it
    self:_padKeys()
    -- the suggestions follow the words and the cursor
    self:_acUpdate()
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
    local joy = self.joyfocus ~= nil
    self._keyHits = {}
    self._acRect, self._acHits = nil, nil
    -- the Commands and Help pages: the strip, then the page and its own band (ZeD_ConsolePages.lua)
    if self.page ~= "log" then
        self._filterRect, self._headRect, self._findRect, self._fieldRect, self._padRect, self._sideRect = nil, nil, nil, nil, nil, nil
        self._listRect, self._rowHits, self._bandRects = nil, {}, {}
        local sw = px(U.STRIP)
        self:_drawStrip(0, top, sw, bandY - top, joy)
        if self._drawPage then
            self:_drawPage(sw, top, w - sw, bandY - top, bandY, joy)
        else
            ZeD.Molecules.drawEmptyLine(self, sw + pad * 2, top + pad * 2, w - sw - pad * 4, tr("UI_ZeD_Console_Coming"))
        end
        return
    end
    -- the input: the line, or the scratchpad in its place (its notice, its meta line, the box at most half the room)
    local areaH = ih
    local noteH, boxH = 0, 0
    if self.mode == "pad" then
        local sw0 = px(U.STRIP)
        local cx0 = sw0 + (self.page == "log" and math.min(px(U.FILTERS), math.floor((w - sw0) * 0.36)) or 0)
        -- (the notice gets what is left of six tenths of the room once the meta line and the smallest box are in;
        -- on a short window it shows its first lines only)
        local room = math.floor((bandY - top) * 0.6) - px(U.META) - px(U.PADMIN)
        if not S.canRun() then noteH = math.max(0, math.min(self:_noteHeight(w - cx0 - 2 * pad) + gap, room)) end
        boxH = math.max(px(U.PADMIN), math.min(px(U.PADBOX), math.floor((bandY - top) * 0.5) - noteH - px(U.META)))
        areaH = noteH + px(U.META) + boxH
    end
    local iy = bandY - pad - areaH
    -- what is typed is the game's line too (its suggestion follows it)
    DC.mirror(self:lineText())

    -- the page strip
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
    -- the band: Export, Copy, Clear, Run (or, naming a snippet: the name, Cancel, Save)
    if self.naming then self:_drawNameBand(bandY, w, joy) else self:_drawBand(bandY, w, joy) end
    -- the suggestions over everything, by the caret
    if self.ac and self._caret then self:_drawAc(top, bandY, joy) end
end

-- ---------------------------------------------------------------------------
-- THE SUGGESTIONS' PULL-DOWN: above the caret (below it when there is no room), a row each, the foot saying what
-- they are; the picked row in the accent, a status pixel and a word at the right (function, table, Java, value)
-- ---------------------------------------------------------------------------
local AC_KIND = { ["function"] = "UI_ZeD_Console_AcFunction", table = "UI_ZeD_Console_AcTable", Java = "UI_ZeD_Console_AcJava", value = "UI_ZeD_Console_AcValue" }
local function acColor(k)
    local T = ZeD.T
    if k == "Java" then return T.warning end
    if k == "table" then return T.accent end
    return T.textDim
end

-- what the foot says: "Globals", "Fields of ZeD", "Methods of x", "Java methods of getPlayer()", and how many more
local function acFoot(ac)
    local head
    if not ac.base then head = tr("UI_ZeD_Console_AcGlobals")
    elseif ac.java then head = tr("UI_ZeD_Console_AcJavaOf", ac.base)
    elseif ac.sep == ":" then head = tr("UI_ZeD_Console_AcMethodsOf", ac.base)
    else head = tr("UI_ZeD_Console_AcFieldsOf", ac.base) end
    if (ac.more or 0) > 0 then head = head .. " | " .. tr("UI_ZeD_Console_AcMore", ac.more) end
    return head
end

function W:_drawAc(top, bottom, joy)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ac, cr = self.ac, self._caret
    local f3 = T.fontF3
    local rowH = math.max(px(U.ACROW), fh(f3) + px(4))
    local footH = fh(f3) + px(6)
    local kindW = px(U.ACKIND)
    local nameW = 0
    for _, it in ipairs(ac.items) do
        nameW = math.max(nameW, ZeD.TM:MeasureStringX(f3, it.n .. (AC.signature(it) or "")))
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
        local nw = ZeD.TM:MeasureStringX(f3, name)
        if sig and name == it.n and nw + ZeD.TM:MeasureStringX(f3, sig) <= room then
            self:drawText(sig, rx + px(7) + nw, ty, dc.r, dc.g, dc.b, dc.a or 1, f3)
        end
        self._acHits[i] = { x = rx, y = ry, w = rw, h = rowH }
    end
    local fy = y + px(1) + #ac.items * rowH
    A.drawDividerH(self, x + px(1), fy, w - px(2))
    local td = T.textDim
    self:drawText(A.truncateText(acFoot(ac), f3, w - px(16)), x + px(8), fy + math.floor((footH - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
end

-- a keycap inside the window (Scratchpad, One line, Save snippet), right edge at xr, centered on a row y, h tall;
-- returns its left edge
local _kc = {}
function W:_keycap(id, xr, y, h, label, variant, help, joy)
    local T = ZeD.T
    local M = ZeD.Molecules
    local bw = M.buttonW(label)
    local bh = T.buttonH - px(4)
    local x = xr - bw
    local by = y + math.floor((h - bh) / 2)
    _kc.win, _kc.help = self, help
    _kc.hover = (not joy) and ZeD.Atoms.mouseIn(self, x, by, bw, bh) or false
    M.drawButton(self, x, by, bw, bh, label, variant, self._down == id, nil, _kc)
    self._keyHits[#self._keyHits + 1] = { x = x, y = by, w = bw, h = bh, id = id }
    return x
end

-- the line to type in: a field, the prompt mark, the game's text box hidden behind it
function W:_drawLine(fx, iy, fw, ih, joy)
    local T = ZeD.T
    local inp = self.input
    -- the Scratchpad keycap at the right swaps the line for the box
    local kx = self:_keycap("topad", fx + fw, iy, ih, btn(tr("UI_ZeD_Console_Scratchpad")), "default", tr("UI_ZeD_Console_HelpToPad"), joy)
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
    local ex = mx0 + ZeD.TM:MeasureStringX(f3, ">") + px(4)
    if inp then
        -- The game's box draws its own text, its caret and its placeholder, always opaque (UITextBox2.render passes alpha 1
        -- for them whatever setTextRGBA says), inside a clip clamped to its parent. It keeps the keys and the cursor, so it
        -- stands left of the window, where that clip is empty; ZeD draws the line (_drawTyped) and takes the clicks.
        local ew = fx + fw - px(4) - ex
        parkEntry(inp, ew, iy, ih)
        self:_drawTyped(inp, ex, iy, ew, ih, f3, focused, tr("UI_ZeD_Console_Type"), self)
        -- (where the caret stands, for the suggestions' pull-down)
        local t = self:lineText()
        self._caret = { x = ex + (cursorOf(inp, t) - (self._typeStart or 0)) * (self._typeCw or charW(f3)), y = iy, h = ih, top = iy }
    end
    if joy and self.zone == "input" then mark(self, fx, iy, fw, ih) end
    self._fieldRect = { x = fx, y = iy, w = fw, h = ih }
end

-- ---------------------------------------------------------------------------
-- THE SCRATCHPAD, DRAWN: the notice (no loadstring), the meta line and its keycaps, the box, the two lists
-- ---------------------------------------------------------------------------
-- the notice's lines at this width: its first sentence, then the rest wrapped (kept until the width changes)
function W:_noteLines(w)
    local T = ZeD.T
    local tw = w - px(8) * 2 - px(U.MARK) - px(8)
    local key = tostring(tw) .. "|" .. tostring(T.fontF2)
    if self._noteKey ~= key then
        self._noteKey = key
        local A = ZeD.Atoms
        local out = {}
        for _, s in ipairs(A.wrapText(tr("UI_ZeD_Console_NoLoad"), T.fontF2, math.max(1, tw))) do out[#out + 1] = { s = s, head = true } end
        for _, s in ipairs(A.wrapText(tr("UI_ZeD_Console_NoLoadBody"), T.fontF2, math.max(1, tw))) do out[#out + 1] = { s = s } end
        self._note = out
    end
    return self._note
end
function W:_noteHeight(w)
    return #self:_noteLines(w) * (fh(ZeD.T.fontF2) + px(2)) + px(12)
end

function W:_drawNote(x, y, w, h)
    local T = ZeD.T
    local s2, bs = T.surf2, T.borderS
    self:drawRect(x, y, w, h, s2.a or 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
    local f2 = T.fontF2
    local step = fh(f2) + px(2)
    local sq = px(U.MARK)
    if h < fh(f2) + px(6) then return end
    ZeD.Atoms.drawStatusDot(self, x + px(8), y + px(6) + math.floor((fh(f2) - sq) / 2), T.danger, sq)
    local tx = x + px(8) + sq + px(8)
    for i, ln in ipairs(self:_noteLines(w)) do
        local ly = y + px(6) + (i - 1) * step
        if ly + fh(f2) > y + h then break end
        local c = ln.head and T.text or T.textDim
        self:drawText(ln.s, tx, ly, c.r, c.g, c.b, c.a or 1, f2)
    end
end

-- the scratchpad from (x, y): the notice, the meta line (lines and characters; Save snippet, One line), the box and,
-- beside it, the snippets and history
function W:_drawPad(x, y, w, noteH, boxH, joy)
    local T = ZeD.T
    local off = not S.canRun()
    if noteH > px(U.GAP) then
        self:_drawNote(x, y, w, noteH - px(U.GAP))
        y = y + noteH
    end
    local mh = px(U.META)
    local text = self:padText()
    local f3 = T.fontF3
    local td = T.textDim
    local meta = tr("UI_ZeD_Console_Scratchpad") .. " | " .. tr("UI_ZeD_Console_PadMeta", padInfo(self, text).n, #text)
    local kx = self:_keycap("toline", x + w, y, mh - px(4), btn(tr("UI_ZeD_Console_OneLine")), off and "primary" or "default", tr("UI_ZeD_Console_HelpToLine"), joy)
    kx = self:_keycap("save", kx - px(U.GAP), y, mh - px(4), btn(tr("UI_ZeD_Console_SaveSnippet")), "default", tr("UI_ZeD_Console_HelpSave"), joy)
    meta = ZeD.Atoms.truncateText(meta, f3, math.max(0, kx - px(8) - x))
    self:drawText(meta, x, y + math.floor((mh - px(4) - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
    y = y + mh
    local sw = math.min(px(U.SIDE), math.floor(w * 0.4))
    local bw = w - sw - px(U.GAP)
    self:_drawPadBox(x, y, bw, boxH, joy, off)
    self:_drawSide(x + bw + px(U.GAP), y, sw, boxH, joy)
end

-- the box: a gutter of line numbers, the lines (never wrapped; scrolled to keep the cursor in view), the caret
function W:_drawPadBox(x, y, w, h, joy, off)
    local T = ZeD.T
    local inp = self.pad
    local f = T.fontF3
    local focused = inp:isFocused()
    local s1 = T.surf1
    self:drawRect(x, y, w, h, s1.a or 1, s1.r, s1.g, s1.b)
    local bc = focused and T.accent or T.borderS
    self:drawRectBorder(x, y, w, h, bc.a or 1, bc.r, bc.g, bc.b)
    local gw = px(U.GUT)
    ZeD.Atoms.drawDividerV(self, x + gw, y + px(1), h - px(2))
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
        self:drawText(ns, x + gw - px(4) - ZeD.TM:MeasureStringX(f, ns), ly, dc.r, dc.g, dc.b, (dc.a or 1) * alpha, f)
        local s = padSlice(info, li, left, cols)
        if s and s ~= "" then self:drawText(s, tx, ly, tc.r, tc.g, tc.b, (tc.a or 1) * alpha, f) end
    end
    if text == "" and not focused then
        self:drawText(tr("UI_ZeD_Console_Type"), tx, y + px(4), dc.r, dc.g, dc.b, (dc.a or 1) * alpha, f)
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

-- a click in the box: the cursor to the line and column under it
function W:padClick(mx, my)
    local st = self._padSt
    if not (st.lh and st.cw) then return end
    local text = self:padText()
    local info = padInfo(self, text)
    local li = math.max(0, math.min(info.n - 1, (st.top or 0) + math.floor((my - st.ty) / st.lh)))
    local col = math.max(0, (st.left or 0) + math.floor((mx - st.tx) / st.cw + 0.5))
    -- (the line's start in the text, then the column, no further than the line as drawn)
    local pos = info.starts[li + 1] + math.min(col, #padSlice(info, li, 0, #text))
    setCursor(self.pad, text, pos, li)
    self._padCur = pos
end

-- the column's rows, flat: SNIPPETS and its rows, HISTORY and its rows (newest first); made again on a change, each
-- with what it shows (a snippet's line count, a run's first line), so a frame counts no lines
function W:_sideItems()
    local key = tostring(S.rev) .. "|" .. tostring(self.sFold.snips) .. tostring(self.sFold.hist)
    if self._sKey == key and self._sItems then return self._sItems end
    local items = { { t = "fold", g = "snips", label = "UI_ZeD_Console_FoldSnippets", n = #S.snippets } }
    if not self.sFold.snips then
        for i = 1, #S.snippets do items[#items + 1] = { t = "snip", i = i, ns = tostring(S.lineCount(S.snippets[i].code)) } end
    end
    items[#items + 1] = { t = "fold", g = "hist", label = "UI_ZeD_Console_FoldHistory", n = #S.history }
    if not self.sFold.hist then
        for i = #S.history, 1, -1 do items[#items + 1] = { t = "hist", i = i, first = string.match(S.history[i] or "", "^([^\n]*)") or "" } end
    end
    self._sKey, self._sItems = key, items
    if self.sFocus > #items then self.sFocus = #items end
    return items
end

function W:_drawSide(x, y, w, h, joy)
    local T = ZeD.T
    local M = ZeD.Molecules
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

-- a snippet (its name, its line count) or a kept run (its first line); the run in the box is marked
function W:_drawSideRow(it, x, y, w, h, hover, foc)
    local T = ZeD.T
    local A = ZeD.Atoms
    local shown = it.t == "hist" and self.phi == it.i
    if shown then
        local ac = T.accent
        self:drawRect(x, y, w, h, T.selectionA or 0.25, ac.r, ac.g, ac.b)
    elseif hover then
        local hv = T.hover
        self:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
    end
    if hover then ZeD.Help.set(self, tr(it.t == "snip" and "UI_ZeD_Console_HelpSnippet" or "UI_ZeD_Console_HelpHistory")) end
    local onFocus = foc and mark(self, x, y, w, h) or false
    local tc = onFocus and T.textOnFocus or T.text
    local dc = onFocus and T.textOnFocus or T.textDim
    local tx = x + px(19)
    if it.t == "snip" then
        local s = S.snippets[it.i]
        local f2, f3 = T.fontF2, T.fontF3
        local ns = it.ns or tostring(S.lineCount(s.code))
        local nw = ZeD.TM:MeasureStringX(f3, ns)
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

--- A row of the column used (a click, A): a fold header folds, a snippet or a run loads into the box.
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

-- the column's row under y (nil: none)
function W:sideItemAt(y)
    for _, hit in ipairs(self._sHits or {}) do
        if y >= hit.y and y < hit.y + hit.h then return hit.i, self:_sideItems()[hit.i] end
    end
    return nil
end

-- the band asking for a snippet's name: the name field at the left, then Cancel and Save
local _nBtns = { { id = "ncancel" }, { id = "nsave", variant = "primary" } }
local _nSpec = { buttons = _nBtns }
local NAME_BAND = { "name", "ncancel", "nsave" }
function W:_drawNameBand(y, w, joy)
    local T = ZeD.T
    local c, s = _nBtns[1], _nBtns[2]
    c.label, s.label = btn(getText("UI_Cancel")), btn(tr("UI_ZeD_Console_Save"))
    local blankName = blank(tostring(self.nameE:getText() or ""))
    s.disabled = blankName
    for i, b in ipairs(_nBtns) do
        b.focus = (joy and self.zone == "band" and self.bandFocus == i + 1) and focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
    end
    _nSpec.win = self
    local _, out = ZeD.Molecules.drawBand(self, 0, y, w, _nSpec)
    self._bandRects = out and out.buttons or {}
    local first = self._bandRects[1]
    local ih = T.inputH
    local fx = px(8)
    local fw = math.max(px(60), (first and first.x or w - px(8)) - px(8) - fx)
    local fy = y + math.floor((ZeD.Molecules.bandH() - ih) / 2)
    local s1 = T.base or T.surf1
    self:drawRect(fx, fy, fw, ih, s1.a or 1, s1.r, s1.g, s1.b)
    local focused = self.nameE:isFocused()
    local bc = focused and T.accent or T.borderS
    self:drawRectBorder(fx, fy, fw, ih, bc.a or 1, bc.r, bc.g, bc.b)
    parkEntry(self.nameE, fw - px(12), fy, ih)
    self:_drawTyped(self.nameE, fx + px(6), fy, fw - px(12), ih, T.fontF3, focused, tr("UI_ZeD_Console_Name"), self._nameSt)
    if joy and self.zone == "band" and self.bandFocus == 1 then mark(self, fx, fy, fw, ih) end
    self._nameRect = { x = fx, y = fy, w = fw, h = ih }
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
    if self.mode == "pad" then
        local can = S.canRun()
        b3.help = (not allowed) and tr("UI_ZeD_Console_NotAllowed") or (can and tr("UI_ZeD_Console_HelpPad") or tr("UI_ZeD_Console_HelpNoLoad"))
        b3.disabled = (not allowed) or (not can) or padInfo(self, self:padText()).blank
    else
        b3.help = allowed and tr("UI_ZeD_Console_HelpRun") or tr("UI_ZeD_Console_NotAllowed")
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
    local _, out = ZeD.Molecules.drawBand(self, 0, y, w, _spec)
    self._bandRects = out and out.buttons or {}
end

function W:render() ZeD_Window.render(self) end

-- the help line's words: the game's suggestion while there is one, else how the line works
function W:getStatusLine()
    if self.page ~= "log" and self._pageStatus then return self:_pageStatus() end
    if self.ac then return tr("UI_ZeD_Console_AcKeys") end
    if not DC.allowed() then return tr("UI_ZeD_Console_NotAllowed") end
    if self.mode == "pad" then return S.canRun() and tr("UI_ZeD_Console_HelpPad") or tr("UI_ZeD_Console_HelpNoLoad") end
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
    -- (the log page's boxes let the keys go: they wait off the window and would still take them)
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
    -- a click on a suggestion takes it, and the keys stay where they were
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
    local bars = self._zedBars
    -- (the scrollbars read the pointer themselves while they draw: a press on one is theirs alone)
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
        local hit = false
        for _, r in ipairs(self._bandRects or {}) do
            if not hit and r.id == down and inRect(r, x, y) then hit = true; self:press(down) end
        end
        for _, r in ipairs(self._keyHits or {}) do
            if not hit and r.id == down and inRect(r, x, y) then hit = true; self:press(down) end
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
-- (a right-click on a snippet renames it, in the band)
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
            -- (suggestions open when it went away: the hand lands on them, A takes one)
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

-- X: in the scratchpad, save a snippet (on a snippet's row, rename it); on the log with the line, Export
function W:padX()
    if self.mode == "pad" then
        if self.naming then return end
        local it = self.zone == "side" and self:_sideItems()[self.sFocus] or nil
        if it and it.t == "snip" then self:startNaming("rename", it.i) else self:startNaming("save") end
        return
    end
    if self.page == "log" and L.counts() > 0 then sound("UIActivateButton"); self:export() end
end

-- A on the band: the name band's field, Cancel, Save; else the band's buttons
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
    -- the Commands and Help pages take the buttons first (the strip stays the window's)
    if self.page ~= "log" and self.zone ~= "strip" and self._pageButton and self:_pageButton(button, jd) then return end
    if self.zone == "ac" then
        if button == Joypad.AButton then
            -- (a pick too long for the line stays on the pull-down, for another one or B)
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

-- the snippets and history column: up and down its rows; left back to the box; down past its last row, the band
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
        -- (left from a page's first column: the page strip)
        local moved = self._pageDir and self:_pageDir(dir)
        if not moved and dir == "left" then self.zone = "strip" end
        sound()
        return
    end
    -- the suggestions: up and down through them; left or right shuts them
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
    local Pr = ZeD.Prompt
    local move = tr("UI_ZeD_Prompt_DPadMove")
    local out = { (Pr and Pr.padNote) and Pr.padNote(move) or move }
    local z = self.zone
    local pad = self.mode == "pad"
    if self.page ~= "log" then
        if z == "strip" then out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Select") }
        elseif self._pagePrompts then self:_pagePrompts(out) end
        out[#out + 1] = { glyph = "B", label = (self._pageBLabel and self:_pageBLabel()) or getText("UI_Close") }
        return out
    end
    if z == "ac" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Console_PadTake") }
        out[#out + 1] = { glyph = "B", label = tr("UI_ZeD_Console_PadShut") }
        return out
    end
    if z == "input" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Keyboard") }
        out[#out + 1] = { glyph = "LB", label = tr("UI_ZeD_Console_PadOlder") }
        out[#out + 1] = { glyph = "RB", label = tr("UI_ZeD_Console_PadNewer") }
        if pad then out[#out + 1] = { glyph = "X", label = tr("UI_ZeD_Console_SaveSnippet") } end
    elseif z == "side" then
        local it = self:_sideItems()[self.sFocus]
        if it and it.t == "fold" then out[#out + 1] = { glyph = "A", label = self.sFold[it.g] and tr("UI_ZeD_Prompt_Unfold") or tr("UI_ZeD_Prompt_Fold") }
        elseif it then out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Console_PadLoad") } end
        out[#out + 1] = { glyph = "X", label = (it and it.t == "snip") and tr("UI_ZeD_Console_PadRename") or tr("UI_ZeD_Console_SaveSnippet") }
    elseif z == "band" then
        out[#out + 1] = { glyph = "A", label = (self.naming and self.bandFocus == 1) and tr("UI_ZeD_Prompt_Keyboard") or tr("UI_ZeD_Prompt_Press") }
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
        if pad then out[#out + 1] = { glyph = "X", label = tr("UI_ZeD_Console_SaveSnippet") }
        elseif self.page == "log" then out[#out + 1] = { glyph = "X", label = tr("UI_ZeD_Console_Export") } end
    end
    if not self.naming then out[#out + 1] = { glyph = "Y", label = pad and tr("UI_ZeD_Console_OneLine") or tr("UI_ZeD_Console_Scratchpad") } end
    out[#out + 1] = { glyph = "B", label = self.naming and getText("UI_Cancel") or getText("UI_Close") }
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
    -- (the snippets and the kept runs, read from Zomboid/Lua the first time)
    S.load()
    -- (the globals walked again the first time a suggestion needs them: mods may have added some since)
    AC.refresh()
    win.ac, win._acKey, win._acShutKey = nil, nil, nil
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
    -- the log is fed only while the window is up (Nov 12 2026: debug launches stopped logging at the main menu once
    -- the feed ran every frame with the window shut; until that is understood, nothing of the log's runs while the
    -- window is shut, as before Phase 1. The F11 list's last 40 entries are read when the window opens.)
    if not DC.isOpen() then return end
    DC.read()
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

-- the window's drawing helpers, for the pages drawn in ZeD_ConsolePages.lua
DC.ui = { U = U, PAGES = PAGES, makeEntry = makeEntry, parkEntry = parkEntry, placeCursor = placeCursor, mark = mark,
          focusOpts = focusOpts, charW = charW, cursorOf = cursorOf, blank = blank }

return DC
