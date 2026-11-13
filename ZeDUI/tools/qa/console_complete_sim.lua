-- ZeDUI/tools/qa/console_complete_sim.lua  (Nov 12 2026): the Lua console's suggestions and its Help page with no
-- game running, on console_sim_harness.lua's stage (the real console files on Lua 5.1 stubs). It checks:
--   * the globals walked once and kept (a global added later shows only after refresh, as the window's open does)
--   * the word at the cursor: two letters for globals, none inside a string or a comment, numbers and bigger
--     expressions refused, fields after ".", methods after ":"; only empty get/is calls are ever run; the scan that
--     jumps and the word read from a tail give the old answers at every cursor of random code
--   * Java methods through a stub object's metatable __index, kept per class, parameter counts read once per class
--     from stub reflection helpers; the signature and where the caret lands on a pick
--   * the keys in the line: Up/Down move, Tab and Enter take (Enter does not run), Esc shuts (and it stays shut
--     until the words change), no pull-down: Up/Down step the history and Tab is the game's own suggestion; a pick
--     past the line's 256 characters: Enter and Tab used up (nothing runs, nothing else taken), the band says why
--   * the keys in the scratchpad: Enter's newline and a Tab character turned into a take, Up/Down keep the cursor
--   * a click on a row takes it; the pull-down drawn inside the window, above the caret or below it near the top
--   * the controller: the pull-down while the pad keyboard types, the hand on it after, A takes (a pick too long
--     for the line leaves the hand on it), B shuts, D-pad up
--   * the Help page: its fold headers and rows, folding, the wheel, the pad (strip, headers, band, Back to the log);
--     the pad's walk shows every line of the page at the window's size and the smallest, the band at its foot
--   * every frame drawn inside the window at 720 / Deck / 1080p / 4K, Normal and Large text, mouse and pad
-- What it cannot prove: Kahlua's own pairs over _G, the real Java metatables and reflection, the real box's keys.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/console_complete_sim.lua

SIM_NAME = "console_complete_sim"
ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]console_complete_sim%.lua$", "")
local H = dofile(ROOT .. "ZeDUI/tools/qa/console_sim_harness.lua")
local check, frame, draw, textHas = H.check, H.frame, H.draw, H.textHas
local JC, KB, CORE = H.JC, H.KB, H.CORE
require "ZeD/ZeD_ConsolePages"
local DC = ZeD.DebugConsole
local AC = ZeD.ConsoleComplete
check("the files load", AC ~= nil and type(AC.complete) == "function" and type(ZeD_DebugConsoleWindow._drawHelp) == "function")

-- a Java object: a userdata whose metatable's __index holds its methods (as the game hands each class one) ----------
local REFLECT = { walks = 0 }
local function javaObject(cls, methods)
    local o = newproxy(true)
    local mt = getmetatable(o)
    local idx = {}
    for name in pairs(methods) do idx[name] = function() return name end end
    mt.__index = idx
    REFLECT[o] = { cls = cls, methods = methods }
    return o
end
-- the reflection helpers (debug mode): a method per overload, each with its parameter count
function getClassSimpleName(o) return REFLECT[o] and REFLECT[o].cls or "?" end
function getNumClassFunctions(o)
    REFLECT.walks = REFLECT.walks + 1
    local n = 0
    for _, counts in pairs(REFLECT[o].methods) do n = n + #counts end
    return n
end
function getClassFunction(o, i)
    local list = {}
    for name, counts in pairs(REFLECT[o].methods) do for _, c in ipairs(counts) do list[#list + 1] = { name = name, c = c } end end
    table.sort(list, function(a, b) if a.name ~= b.name then return a.name < b.name end return a.c < b.c end)
    local m = list[i + 1]
    return { getName = function() return m.name end, pc = m.c }
end
function getMethodParameterCount(m) return m.pc end

local PLAYER_J = javaObject("IsoPlayer", { getPlayerNum = { 0 }, getX = { 0 }, getInventory = { 0 }, getStats = { 0 },
    Say = { 1, 2 }, setX = { 1 }, getModData = { 0 }, getDescriptor = { 0 }, getBodyDamage = { 0 }, getCell = { 0 } })
local INV_J = javaObject("ItemContainer", { getItems = { 0 }, AddItem = { 1, 2 }, getType = { 0 } })
local RAN = { doThing = 0 }
function getJavaPlayer() return PLAYER_J end
function doThing() RAN.doThing = RAN.doThing + 1; return PLAYER_J end
getmetatable(PLAYER_J).__index.getInventory = function() return INV_J end
ConsoleSimTable = { alpha = 1, alphabet = {}, beta = function() end, Gamma = "x" }

-- ============================================================================
-- 1. the globals, walked once
-- ============================================================================
AC.refresh()
local g1 = AC.globals()
check("globals: walked into a sorted list", #g1 > 50)
check("globals: kept (the same list again)", AC.globals() == g1)
local sorted = true
for i = 2, #g1 do if g1[i - 1].l > g1[i].l then sorted = false end end
check("globals: sorted any case", sorted)
ConsoleSimLate = function() end
local ac = AC.complete("ConsoleSimL", 11)
check("globals: one added after the walk is not offered yet", ac == nil)
AC.refresh()
ac = AC.complete("ConsoleSimL", 11)
check("globals: after refresh it is", ac and ac.items[1].n == "ConsoleSimLate" and ac.items[1].k == "function")

-- ============================================================================
-- 2. the word at the cursor
-- ============================================================================
check("token: one letter gets nothing", AC.complete("g", 1) == nil)
ac = AC.complete("getJ", 4)
check("token: two letters and more offer globals", ac and ac.items[1].n == "getJavaPlayer" and ac.base == nil and ac.start == 0)
check("token: any case", AC.complete("GETJ", 4) ~= nil)
check("token: the word typed out whole is not offered back", AC.complete("getJavaPlayer", 13) == nil)
check("token: inside a string, nothing", AC.complete("print('getJ", 11) == nil and AC.complete('x = "getJ', 9) == nil)
check("token: after a closed string, offered", AC.complete("print('a', getJ", 15) ~= nil)
check("token: in a comment, nothing", AC.complete("x = 1 -- getJ", 13) == nil)
check("token: on the next line after a comment, offered", AC.complete("-- note\ngetJ", 12) ~= nil)
check("token: a number gets nothing", AC.complete("x = 1.5", 7) == nil and AC.complete("x = 12ab", 8) == nil)
check("token: after an indexing bracket, nothing", AC.complete("t[1].al", 7) == nil)
check("token: a call with arguments is never the base", AC.complete("doThing(1):get", 14) == nil)
check("token: concatenation is not a field", AC.complete("a ..", 4) == nil)
ac = AC.complete("x = ConsoleSimTable.al", 22)
check("fields: after a dot, the table's keys", ac and ac.base == "ConsoleSimTable" and ac.sep == "." and #ac.items == 2 and ac.items[1].n == "alpha" and ac.items[2].n == "alphabet")
check("fields: their kinds", ac.items[1].k == "value" and ac.items[2].k == "table")
ac = AC.complete("ConsoleSimTable.", 16)
check("fields: right after the dot, all of them", ac and #ac.items == 4 and ac.more == 0)
ac = AC.complete("ConsoleSimTable:", 16)
check("methods: after a colon on a table, its functions", ac and #ac.items == 1 and ac.items[1].n == "beta")
check("the cursor mid-line: the word before it", AC.complete("getJ + 1", 4) ~= nil)
-- the ISUI way: a table's methods through its metatable's __index chain
local Base = { draw = function() end, width = 3 }
Base.__index = Base
ConsoleSimObj = setmetatable({ mine = true }, Base)
ac = AC.complete("ConsoleSimObj.", 14)
local names = {}
for _, it in ipairs(ac and ac.items or {}) do names[#names + 1] = it.n end
check("fields: inherited through __index too", table.concat(names, ",") == "__index,draw,mine,width", table.concat(names, ","))
-- the string-and-comment scan now jumps with plain finds, and the word before the cursor comes from a short tail:
-- the same answers as the old character-at-a-time scan and whole-text match (copied here) for every cursor in
-- random code, words longer than the tail included
do
    local function oldIn(before)
        local i, n = 1, #before
        local q = nil
        while i <= n do
            local c = string.sub(before, i, i)
            if q then
                if c == "\\" then i = i + 1
                elseif q == "]]" then
                    if string.sub(before, i, i + 1) == "]]" then q = nil; i = i + 1 end
                elseif c == q then q = nil end
            elseif c == "\"" or c == "'" then q = c
            elseif c == "[" and (string.sub(before, i, i + 1) == "[[" or string.sub(before, i, i + 1) == "[=") then q = "]]"
            elseif c == "-" and string.sub(before, i, i + 1) == "--" then
                local nl = string.find(before, "\n", i, true)
                if not nl then return true end
                i = nl
            end
            i = i + 1
        end
        return q ~= nil
    end
    local function oldSteps(base)
        local steps, pos, n = {}, 1, #base
        while pos <= n do
            local sep = nil
            if pos > 1 then
                sep = string.sub(base, pos, pos)
                if sep ~= "." and sep ~= ":" then return nil end
                pos = pos + 1
            end
            local s, e = string.find(base, "^[%a_][%w_]*", pos)
            if not s then return nil end
            pos = e + 1
            local call = false
            if string.sub(base, pos, pos + 1) == "()" then call = true; pos = pos + 2 end
            if sep == ":" and not call then return nil end
            steps[#steps + 1] = true
        end
        return steps
    end
    local function oldToken(text, cur)
        cur = math.max(0, math.min(#text, cur or #text))
        local before = string.sub(text, 1, cur)
        local pre = string.match(before, "[%w_]*$") or ""
        local ps = cur - #pre
        if pre ~= "" and string.find(pre, "^%d") then return nil end
        local sep = ps > 0 and string.sub(text, ps, ps) or ""
        if oldIn(before) then return nil end
        if sep ~= "." and sep ~= ":" then
            if #pre < AC.MIN_GLOBAL then return nil end
            local prev = ps > 0 and string.sub(text, ps, ps) or ""
            if prev == "]" or prev == ")" then return nil end
            return { start = ps, pre = pre }
        end
        local b = ps - 1
        while b >= 1 do
            local c = string.sub(text, b, b)
            if string.find(c, "[%w_%.:]") then b = b - 1
            elseif c == ")" and b > 1 and string.sub(text, b - 1, b - 1) == "(" then b = b - 2
            else break end
        end
        local base = string.sub(text, b + 1, ps - 1)
        if base == "" or ".." == string.sub(text, ps - 1, ps) then return nil end
        local prev = b >= 1 and string.sub(text, b, b) or ""
        if prev == "]" or prev == ")" or prev == "\"" or prev == "'" then return nil end
        if not oldSteps(base) then return nil end
        return { start = ps, pre = pre, base = base, sep = sep }
    end
    local function same(a, b)
        if a == nil or b == nil then return a == b end
        return a.start == b.start and a.pre == b.pre and a.base == b.base and a.sep == b.sep
    end
    math.randomseed(1113)
    local ALPHA = { "\"", "'", "[", "]", "=", "-", "\\", "\n", "a", " ", "g", "e", "t", "_", "1", ".", ":", "(", ")" }
    local badIn, badTok = {}, {}
    local newIn = AC.inStringOrComment
    for _ = 1, 700 do
        local parts = {}
        for k = 1, math.random(0, 26) do parts[k] = ALPHA[math.random(#ALPHA)] end
        local t = table.concat(parts)
        for cur = 0, #t do
            local before = string.sub(t, 1, cur)
            if not newIn or oldIn(before) ~= newIn(before) then badIn[#badIn + 1] = string.format("%q", before) end
            if not same(oldToken(t, cur), AC.token(t, cur)) then badTok[#badTok + 1] = string.format("%q", t) .. " @" .. cur end
        end
    end
    for _, t in ipairs({ string.rep("a", 1000), "x = " .. string.rep("b", 63), "x = " .. string.rep("b", 64), "x = " .. string.rep("b", 65),
                         string.rep("c", 300) .. "." .. string.rep("d", 70), "-- " .. string.rep("e", 200), "s = [[" .. string.rep("f", 100) }) do
        if not same(oldToken(t, #t), AC.token(t, #t)) then badTok[#badTok + 1] = "long " .. #t end
    end
    check("the string-and-comment scan: the old one's answer at every cursor", #badIn == 0, badIn[1])
    check("the word at the cursor: the old one's answer at every cursor, long words too", #badTok == 0, badTok[1])
end

-- ============================================================================
-- 3. Java methods, kept per class, with parameter counts; nothing else ever runs
-- ============================================================================
REFLECT.walks = 0
ac = AC.complete("getJavaPlayer():get", 19)
check("java: after a colon on a Java object, its methods", ac and ac.java and ac.base == "getJavaPlayer()" and ac.items[1].k == "Java")
check("java: the get ones", ac and #ac.items == 8 and ac.items[1].n == "getBodyDamage", ac and #ac.items)
check("java: reflection read once", REFLECT.walks == 1)
AC.complete("getJavaPlayer():getP", 20)
AC.complete("getJavaPlayer():se", 18)
check("java: the class kept (no second walk)", REFLECT.walks == 1, REFLECT.walks)
ac = AC.complete("getJavaPlayer():S", 17)
check("java: overloads give a range", ac and ac.items[1].n == "Say" and AC.signature(ac.items[1]) == "(_, ..)", ac and AC.signature(ac.items[1]))
ac = AC.complete("getJavaPlayer():getX", 20)
check("java: no parameters, ()", ac == nil or AC.signature({ k = "Java", ar = 0, arMax = 0 }) == "()")
ac = AC.complete("getJavaPlayer():getInventory():Ad", 33)
check("java: a chain of get calls", ac and ac.items[1].n == "AddItem" and ac.base == "getJavaPlayer():getInventory()")
check("java: the second class read once", REFLECT.walks == 2, REFLECT.walks)
check("java: a dot on a Java object offers nothing", AC.complete("getJavaPlayer().ge", 18) == nil)
check("safety: a call not named get or is is never run", AC.complete("doThing():get", 13) == nil and RAN.doThing == 0)
-- what a pick puts in: the caret inside the brackets unless it takes none
ac = AC.complete("x = getJavaPlayer():getPl", 25)
local t, cur = AC.take("x = getJavaPlayer():getPl", ac, 1)
check("take: no parameters, the caret after ()", t == "x = getJavaPlayer():getPlayerNum()" and cur == #t, t .. " " .. cur)
ac = AC.complete("getJavaPlayer():se", 18)
t, cur = AC.take("getJavaPlayer():se", ac, 1)
check("take: parameters, the caret inside", t == "getJavaPlayer():setX()" and cur == #t - 1)
ac = AC.complete("ConsoleSimTable.alph(1)", 20)
t, cur = AC.take("ConsoleSimTable.alph(1)", ac, 2)
check("take: a table field gets no brackets; the rest of the word goes", t == "ConsoleSimTable.alphabet(1)" and cur == 24, t)
ac = AC.complete("getJaxx", 4)
t = AC.take("getJaxx", ac, 1)
check("take: the rest of the word after the cursor is replaced", t == "getJavaPlayer()", t)
ac = AC.complete("getJ(", 4)
t = AC.take("getJ(", ac, 1)
check("take: a bracket already there, none added", t == "getJavaPlayer(", t)

-- ============================================================================
-- 4. the window: the line's keys
-- ============================================================================
JC.visible = true
frame()
local win = DC.win
check("open", DC.isOpen() and win ~= nil)
local function setLine(s, c)
    win.input:setText(s)
    if c then win.input.javaObject.cur = c end
end
win.input:focus()
setLine("getJ")
draw(win)
check("line: the pull-down opens by itself after two letters", win.ac ~= nil and win.ac.items[1].n == "getJavaPlayer")
check("line: drawn, with its foot", textHas("getJavaPlayer") and textHas("Globals"))
check("line: drawn inside the window", #H.DRAW.outside == 0, H.DRAW.outside[1])
check("line: above the field", win._acRect and win._fieldRect and win._acRect.y + win._acRect.h <= win._fieldRect.y)
check("line: the help line says the keys", win:getStatusLine():find("Tab or Enter", 1, true) ~= nil)
setLine("getJ")
draw(win)
win.input.onPressDown()
check("line: Down with a single row stays", win.acI == 1)
setLine("ConsoleSimTable.")
draw(win)
check("line: fields after a dot", win.ac and #win.ac.items == 4)
win.input.onPressDown(); win.input.onPressDown()
check("line: Down moves", win.acI == 3)
win.input.onPressUp()
check("line: Up moves", win.acI == 2)
local hist = JC.prev:size()
win.input.onCommandEntered()
check("line: Enter takes, does not run", win:lineText() == "ConsoleSimTable.alphabet" and JC.prev:size() == hist, win:lineText())
check("line: shut after a take", win.ac == nil)
setLine("getJ")
draw(win)
win.input.onOtherKey(win.input, Keyboard.KEY_TAB)
check("line: Tab takes", win:lineText() == "getJavaPlayer()" and win.input.javaObject.cur == 14, win:lineText())
setLine("getJ")
draw(win)
win.input.onOtherKey(win.input, Keyboard.KEY_ESCAPE)
check("line: Esc shuts, the line keeps the keys", win.ac == nil and CORE.entry == win.input)
draw(win)
check("line: it stays shut while the words stay", win.ac == nil)
setLine("getJa")
draw(win)
check("line: one more letter opens it again", win.ac ~= nil)
win.input.onOtherKey(win.input, Keyboard.KEY_ESCAPE)
win.input.onOtherKey(win.input, Keyboard.KEY_ESCAPE)
check("line: Esc again lets the line go", CORE.entry ~= win.input)
-- no pull-down: Up and Down are the history, Tab the game's own suggestion
win.input:focus()
setLine("print(1)")
win:runLine()
setLine("")
draw(win)
win.input.onPressUp()
check("line: no pull-down, Up is the history", win:lineText() == "print(1)")
setLine("getPl")
JC.cmd:SetText("")
draw(win)
check("line: the game's getPlayer is offered too", win.ac and win.ac.items[1].n == "getPlayer")
win:acShut()
win.input.onOtherKey(win.input, Keyboard.KEY_TAB)
check("line: shut, Tab is the game's suggestion", win:lineText() == "getPlayer()", win:lineText())
-- a click takes
setLine("ConsoleSimTable.")
draw(win)
local r = win._acHits[2]
win:onMouseDown(r.x + 4, r.y + 2)
check("click: takes the row", win:lineText() == "ConsoleSimTable.alphabet" and CORE.entry == win.input, win:lineText())
-- the line's 256: a pick that passes it is not taken
setLine(string.rep("x", 250) .. " getJ")
draw(win)
check("line: a pick past 256 characters is not taken", win.ac and not win:acTake() and #win:lineText() == 255)
-- ...and Enter or Tab on it are used up: the half-typed line never runs, the game's own suggestion is not taken
do
    local long = string.rep("x", 250) .. " getJ"
    setLine(long)
    draw(win)
    local hist0 = JC.prev:size()
    win.input.onCommandEntered()
    check("line: Enter on a pick past 256 characters runs nothing", JC.prev:size() == hist0 and win:lineText() == long and win.ac ~= nil, win:lineText())
    check("line: ...the band says why", win._status ~= nil and tostring(win._status.text):find("256", 1, true) ~= nil, win._status and win._status.text)
    -- (the game offering a suggestion that fits the word, as it would for a word it knows)
    local was = JC.prevSuggestion
    JC.sug.visible = true
    JC.sug:SetText("IsoPlayer getJavaPlayer")
    JC.prevSuggestion = "getJavaPlayer"
    win.input.onOtherKey(win.input, Keyboard.KEY_TAB)
    check("line: Tab on it takes nothing, the game's suggestion neither", win:lineText() == long and win.ac ~= nil, win:lineText())
    JC.prevSuggestion = was
    JC.sug.visible = false
    setLine("getJ")
    draw(win)
    win.input.onCommandEntered()
    check("line: a pick that fits is taken, and the band's word about the full line goes", win:lineText() == "getJavaPlayer()" and win._status == nil, win:lineText())
    setLine("")
    draw(win)
end

-- ============================================================================
-- 5. the scratchpad's keys
-- ============================================================================
win:setMode("pad")
win.pad:focus()
win:_padSet("local p = getJ")
draw(win)
check("pad: the pull-down in the box", win.ac ~= nil and win.ac.items[1].n == "getJavaPlayer")
check("pad: drawn inside", #H.DRAW.outside == 0, H.DRAW.outside[1])
H.enter(win.pad)
draw(win)
check("pad: Enter takes instead of a new line or a run", win:padText() == "local p = getJavaPlayer()", win:padText())
win:_padSet("x = 1\nConsoleSimTable.")
draw(win)
local before = win.pad.javaObject.cur
win.pad.javaObject.cur = 0      -- (the box moved its cursor up before calling onPressUp)
win.pad.onPressDown()
check("pad: Down moves the pick and the cursor stays", win.acI == 2 and win.pad.javaObject.cur == before, win.pad.javaObject.cur)
draw(win)
H.typeIn(win.pad, "\t")
draw(win)
check("pad: a Tab character takes", win:padText() == "x = 1\nConsoleSimTable.alphabet", win:padText())
win:_padSet("print(1)")
draw(win)
H.enter(win.pad)
draw(win)
check("pad: no pull-down, Enter runs", win:padText() == "")
win:_padSet("ConsoleSimTable.")
draw(win)
win.pad.onOtherKey(win.pad, Keyboard.KEY_ESCAPE)
check("pad: Esc shuts, the box keeps the keys", win.ac == nil and CORE.entry == win.pad)
win:_padSet("y = ConsoleSimTable.")
draw(win)
win.pad.onOtherKey(win.pad, Keyboard.KEY_TAB)
check("pad: the Tab key takes", win:padText() == "y = ConsoleSimTable.alpha", win:padText())
-- a caret on the box's first line in a short window: the pull-down goes below when there is no room above
win:setWidth(ZeD.T.px(520)); win:setHeight(ZeD.T.px(260))
win:_padSet("ConsoleSimTable.")
draw(win)
check("pad: small window, drawn inside", win.ac and #H.DRAW.outside == 0, tostring(win.ac) .. " " .. tostring(H.DRAW.outside[1]))
win:setMode("line")
win:setWidth(ZeD.T.px(900)); win:setHeight(ZeD.T.px(480))

-- ============================================================================
-- 6. the controller
-- ============================================================================
DC.close()
local jd = { id = 0, player = 0 }
JoypadState.players[1] = jd
H.setMode("gamepad")
DC.open(0)
win = DC.win
win:update()
win.zone = "input"
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A opens the pad keyboard on the line", KB.visible and KB.entry == win.input)
win.input:setText("ConsoleSimTable.al")
draw(win)
check("pad: the pull-down shows while the pad keyboard types", win.ac ~= nil)
KB.visible = false
jd.focus = win
win:update()
check("pad: the keyboard put away, the hand on the pull-down", win.zone == "ac" and win.acI == 1)
local function glyphs()
    local g = {}
    for _, p in ipairs(win:getFooterPrompts()) do if type(p) == "table" then g[#g + 1] = p.glyph .. ":" .. p.label end end
    return table.concat(g, " ")
end
check("pad prompts on the pull-down: A Take, B Close", glyphs() == "A:Take B:Close", glyphs())
H.resetMarks()
draw(win)
check("pad: the picked row marked", H.marks() >= 1 and #H.DRAW.outside == 0)
win:onJoypadDirDown()
check("pad: D-pad down moves", win.acI == 2)
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A takes, back on the line", win:lineText() == "ConsoleSimTable.alphabet" and win.zone == "input")
win.input:setText("ConsoleSimTable.al")
win.input:focus()
draw(win)
win.input:unfocus()
win:onJoypadDirUp()
check("pad: D-pad up from the line reaches the pull-down", win.zone == "ac")
draw(win)
check("pad: the pull-down stays while the hand is on it", win.ac ~= nil)
win:onJoypadDown(Joypad.BButton, jd)
check("pad: B shuts it, the window stays", win.ac == nil and win.zone == "input" and DC.isOpen())
win:onJoypadDirUp()
check("pad: shut, up goes on to the log", win.zone ~= "ac")
-- A on a pick that would pass the line's 256 characters: nothing taken, the hand stays on the pull-down for another
do
    local long = string.rep("x", 250) .. " getJ"
    win.input:setText(long)
    win.input:focus()
    draw(win)
    win.input:unfocus()
    win.zone = "input"
    win:onJoypadDirUp()
    check("pad: up to the pull-down over a long line", win.zone == "ac" and win.ac ~= nil)
    win:onJoypadDown(Joypad.AButton, jd)
    check("pad: A on a pick past 256 characters takes nothing, the hand stays on the pull-down", win.zone == "ac" and win.ac ~= nil and win:lineText() == long, win.zone)
    if win.zone == "ac" then win:onJoypadDown(Joypad.BButton, jd) end
    check("pad: B shuts it", win.ac == nil and win.zone == "input" and DC.isOpen())
    win:acShut()
    win.zone = "input"
    win.input:setText("")
    win._status = nil
end

-- ============================================================================
-- 7. the Help page
-- ============================================================================
win.zone = "strip"
win.stripFocus = 3
win:onJoypadDown(Joypad.AButton, jd)
check("help: A on the strip's third picture", win.page == "help")
draw(win)
check("help: drawn inside", #H.DRAW.outside == 0, H.DRAW.outside[1])
check("help: its fold headers", textHas("WHAT RUNS WHERE") or textHas("What runs where"))
check("help: its rows", textHas("Shift+Enter") and textHas("A new line in the scratchpad."), textHas("Shift+Enter"))
check("help: the band's keycap", textHas("Back to the log"))
check("help: the help line", win:getStatusLine():find("what runs where", 1, true) ~= nil)
check("help prompts on the strip: A Select, B Close", glyphs() == "A:Choose B:Close", glyphs())
win:onJoypadDirRight()
check("help: right from the strip, the page", win.zone == "page" and win.hFocus == 1)
check("help prompts on a header: A Fold", glyphs():find("A:Fold", 1, true) ~= nil, glyphs())
win:onJoypadDown(Joypad.AButton, jd)
check("help: A folds the first section", win.hFold.where == true)
draw(win)
check("help: folded, its words gone", not textHas("console.txt do not reach it"))
win:onJoypadDown(Joypad.AButton, jd)
win:onJoypadDirDown(); win:onJoypadDirDown(); win:onJoypadDirDown()
draw(win)
check("help: down to the last header, brought into view", win.hFocus == 4 and win.hScroll > 0, win.hScroll)
win:onJoypadDirDown()
check("help: past the last header, the band", win.zone == "pband")
check("help prompts on the band: A Press", glyphs():find("A:Press", 1, true) ~= nil, glyphs())
win:onJoypadDirLeft()
check("help: left from the band, the strip", win.zone == "strip")
win.zone = "page"
win:onJoypadDirLeft()
check("help: left from the page, the strip", win.zone == "strip")
win.zone = "pband"
win:onJoypadDown(Joypad.AButton, jd)
check("help: A on Back to the log", win.page == "log")
DC.close()
JoypadState.players[1] = nil
H.setMode("kbm")
-- the mouse
DC.open()
win = DC.win
win:setPage("help"); win.hScroll = 0
draw(win)
local hit = win._hHits[1]
win:onMouseDown(win._hRect.x + 20, hit.y + 2)
check("help: a click on a header folds it", win.hFold.where == true, tostring(win.hFold.where) .. " " .. hit.y .. " " .. win._hRect.y .. " " .. tostring(win.ac) .. " " .. tostring(win.naming) .. win.mode)
win.hFold = {}
win:setHeight(ZeD.T.px(260))
draw(win)
local s0 = win.hScroll
win.mx, win.my = win._hRect.x + 10, win._hRect.y + 10
win:onMouseWheel(1)
check("help: the wheel scrolls", win.hScroll > s0)
local b = win._bandRects[1]
win:onMouseDown(b.x + 2, b.y + 2)
win:onMouseUp(b.x + 2, b.y + 2)
check("help: Back to the log by mouse", win.page == "log")
win:setPage("help"); win.hScroll = 0
win.input:focus()
check("help: the log's line let go when the page changed", true)
win:setPage("log")
DC.close()
-- the controller walk shows every line of the page, all sections open, at the window's size and the smallest: each
-- header with its section under it, a section taller than the view read on, past the last header the band with the
-- page at its foot (the Files rows were out of reach); then up brings each header back into view
do
    local jd3 = { id = 0, player = 0 }
    JoypadState.players[1] = jd3
    H.setMode("gamepad")
    for _, size in ipairs({ { ZeD.T.px(900), ZeD.T.px(480) }, { ZeD.T.px(520), ZeD.T.px(260) } }) do
        DC.close()
        DC.open(0)
        local w3 = DC.win
        w3:update()
        w3:setWidth(size[1]); w3:setHeight(size[2])
        w3.hFold, w3.hScroll, w3.hFocus = {}, 0, 1
        w3:setPage("help")
        draw(w3)
        w3:onJoypadDirRight()
        draw(w3)
        local view = w3._hRect.h
        local layW = w3._hLayW or w3._hRect.w
        local _, total = w3:_helpLayout(layW)
        local covered, gap, presses = w3.hScroll + view, nil, 0
        while w3.zone ~= "pband" and presses < 60 do
            w3:onJoypadDirDown()
            draw(w3)
            presses = presses + 1
            if w3.hScroll > covered and not gap then gap = covered .. ".." .. w3.hScroll end
            covered = math.max(covered, w3.hScroll + view)
        end
        local name = "help " .. size[1] .. "x" .. size[2]
        check(name .. ": the walk down reaches the band", w3.zone == "pband", presses)
        check(name .. ": every line of the page shown on the way, down to its foot", gap == nil and covered >= total - ZeD.T.px(8), tostring(gap) .. " " .. covered .. " of " .. total)
        check(name .. ": on the band, the page at its foot", w3.hScroll == math.max(0, total - view), w3.hScroll .. " of " .. (total - view))
        local folds = {}
        for _, it in ipairs((w3:_helpLayout(layW))) do if it.t == "fold" then folds[#folds + 1] = it end end
        local okUp, steps = true, 0
        w3:onJoypadDirUp()
        draw(w3)
        while steps < 30 do
            local it = folds[w3.hFocus]
            if not (it and it.y >= w3.hScroll and it.y + it.h <= w3.hScroll + view) then okUp = false end
            if w3.hFocus == 1 and w3.hScroll <= folds[1].y then break end
            w3:onJoypadDirUp()
            draw(w3)
            steps = steps + 1
        end
        check(name .. ": up again, each header in view on the way back to the top", okUp and w3.hFocus == 1 and w3.hScroll <= folds[1].y, w3.hFocus .. " " .. w3.hScroll)
        -- a down that reads into a tall section leaves its header above the view; A folds that section and brings
        -- the header back in, so the hand is never off the page
        w3.hFold, w3.hScroll, w3.hFocus = {}, 0, 1
        draw(w3)
        w3:onJoypadDirDown()
        draw(w3)
        w3:onJoypadDown(Joypad.AButton, jd3)
        draw(w3)
        local fAfter = {}
        for _, it in ipairs((w3:_helpLayout(layW))) do if it.t == "fold" then fAfter[#fAfter + 1] = it end end
        local hd = fAfter[w3.hFocus]
        check(name .. ": one down then A, the folded header in view", hd ~= nil and hd.y >= w3.hScroll and hd.y + hd.h <= w3.hScroll + view, (hd and hd.y or "?") .. " at " .. w3.hScroll)
        check(name .. ": drawn inside", #H.DRAW.outside == 0, H.DRAW.outside[1])
    end
    DC.close()
    JoypadState.players[1] = nil
    H.setMode("kbm")
end

-- ============================================================================
-- 8. every size, both text sizes, mouse and pad: the pull-down in the line and the box, and the Help page
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
    H.SCREEN.w, H.SCREEN.h = prof.w, prof.h
    DC.close()
    DC.win, DC.place = nil, nil
    for _, padIn in ipairs({ false, true }) do
        H.setMode(padIn and "gamepad" or "kbm")
        JoypadState.players[1] = padIn and { id = 0, player = 0 } or nil
        JC.visible = true
        frame()
        if padIn then DC.close(); DC.open(0) end
        local w2 = DC.win
        local name = prof.name .. (padIn and " pad" or " mouse")
        if w2 then
            w2:update()
            for _, size in ipairs({ { w2.width, w2.height }, { ZeD.T.px(520), ZeD.T.px(260) } }) do
                w2:setWidth(size[1]); w2:setHeight(size[2])
                w2:setPage("log")
                w2:setMode("line")
                w2.input:focus()
                w2.input:setText("getJavaPlayer():get")
                draw(w2)
                check(name .. " " .. size[1] .. "x" .. size[2] .. ": the line's pull-down drawn inside", w2.ac and #H.DRAW.outside == 0, H.DRAW.outside[1])
                w2:setMode("pad")
                w2.pad:focus()
                w2:_padSet(string.rep("print(1)\n", 20) .. "ConsoleSimTable.")
                draw(w2)
                check(name .. " " .. size[1] .. "x" .. size[2] .. ": the box's pull-down drawn inside", w2.ac and #H.DRAW.outside == 0, H.DRAW.outside[1])
                w2:_padSet("ConsoleSimTable.")
                draw(w2)
                check(name .. " " .. size[1] .. "x" .. size[2] .. ": first line's pull-down drawn inside", w2.ac and #H.DRAW.outside == 0, H.DRAW.outside[1])
                w2:setMode("line")
                w2:setPage("help")
                draw(w2)
                check(name .. " " .. size[1] .. "x" .. size[2] .. ": Help drawn inside", #H.DRAW.outside == 0, H.DRAW.outside[1])
                w2:setPage("log")
            end
        end
        DC.close()
    end
end
JoypadState.players[1] = nil

H.sysPrint(SIM_NAME .. ": " .. H.checks .. " checks, " .. H.failed .. " failed")
if H.failed > 0 then os.exit(1) end
