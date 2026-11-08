-- ZeDUI/tools/qa/zedqa_b8_console.lua  (Nov 7 2026, QA; CHECK_debug_console_20261107.md, the "What to do" list and the safe switch)
-- The game's debug-mode Lua console is a ZeD window (ZeD_DebugConsole.lua); the game's console is the engine, parked off the screen.
-- The game runs with -debug, so the script drives it through the game's own flag (what the Toggle Lua Console key flips) and
-- ZeD.DebugConsole.run (the game's ProcessCommand on the game's own line), and checks:
--   1 the flag down shuts ZeD's window, the flag up opens it, the game's own console parked off the screen, never on it
--   3 print("...") lands in the list; the line is emptied and in the history
--   4 a runtime error and 5 a line that does not compile each add an error block ("Errors: N" in the title)
--   6 the history keeps oldest first, a line run twice in a row is kept once
--   7 the game's suggestion for "getPl" and Tab giving getPlayer()
--   8 Clear and the "clear" command empty the list
--  11 the close box shuts it, the key (flag) opens it again
--  12 "Safe mode: Lua console" On hands the game's own console back in its place, open; Off takes it again
--  14 the pad wheel (Select) has the Lua console slice last in debug mode
-- The error lines deliberately make the game log two Lua errors ("attempted index", "console:1:"): the manifest says expect=.
-- Manual: typing by keyboard (the text box's own keys, Enter, Up, Down, Tab, Escape), picking and Copy to the clipboard, scrolling,
-- resizing, dragging, rolling up, the Debug menu entry, the controller (part 2 of the check), sizes, the run WITHOUT -debug, a server.
-- 3b (Nov 8): typed line drawn by ZeD: short, placeholder, long (scrolls), Home/End/arrows (cursor via Java), click placing the caret.
-- grep "ZEDQA b8dc"; shots zqa_b8dc_*.png.
local TAG = "b8dc"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local DC = ZeD and ZeD.DebugConsole
if not (p and CW and WW and DC) then say("ERR ZeD's console module is not loaded"); say("DONE"); return end
if not DC.debug() then say("NOTE the game is not running with -debug: there is no console to check (run with -debug)"); say("DONE"); return end
if not DC.exists() then say("NOTE the game's console is not on the screen list yet (DC.exists is false); nothing to check"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8dc_" .. n .. ".png") end) end
local function cw() return CW.getWindow() end
local function ww() return WW.getWindow() end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function holdBoth() keepDown(cw()); keepDown(ww()) end

-- the step list: step(waitTicks, fn) runs fn that many ticks after the step before; waitFor(max, cond, fn) runs fn when cond holds (fn(timedOut))
local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local function waitFor(max, cond, fn) Q[#Q + 1] = { max = max, cond = cond, fn = fn } end
local cleanups = {}
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    cleanups = {}
    say("checks: passes=" .. passes .. " misses=" .. misses)
    say("DONE")
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
    qc = qc + 1
    local go, timedOut = false, false
    if s.cond then
        local ok, v = pcall(s.cond)
        if ok and v then go = true elseif qc >= s.max then go, timedOut = true, true end
    else
        go = qc >= s.wait
    end
    if go then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn, timedOut)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end


-- ---- helpers
local jc = DC.game()
local wasUp = DC.up(jc)
local opt = ZeD.Settings and ZeD.Settings.screenOptions and ZeD.Settings.screenOptions.console
local optWas = nil
if opt then pcall(function() optWas = opt:getValue() end) end
local function flag(v) pcall(function() jc:setVisible(v) end) end
local function parked() local ok, x = pcall(function() return jc:getX() end); return ok and type(x) == "number" and x <= -50000 end
local function errCount() local _, n = DC.lines(); return n or 0 end
local function textHas(s) return DC.text:find(s, 1, true) ~= nil end
local function lineEmpty()
    local ok, t = pcall(function() return DC.P.cmd:getText() end)
    return ok and (t == nil or tostring(t) == "")
end
local e0, e1 = 0, 0
local hist0 = 0
onCleanup(function()
    if opt and optWas ~= nil then pcall(function() opt:setValue(optWas) end) end
    DC.mirror("")
    flag(wasUp)
end)

-- ===== 1. the flag opens and shuts ZeD's window; the game's own stays parked
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("NOTE the console was up at the start: " .. tostring(wasUp) .. " (UI.DebugConsole.StartVisible)")
    flag(false)
end)
step(25, function()
    check(not DC.isOpen(), "1: with the game's flag down ZeD's Lua console is shut")
    check(parked(), "1: the game's own console is off the screen")
    flag(true)
end)
step(30, function()
    check(DC.isOpen(), "1: with the flag up (the key) ZeD's Lua console opens")
    check(parked(), "1: and the game's own console stays parked off the screen")
    check(DC.win ~= nil and DC.win:isReallyVisible(), "1: the window is on the screen")
end)
step(20, function() shot("open") end)

-- ===== 3. print
step(5, function()
    DC.clear()
    DC.run('print("hello_b8dc")')
end)
step(40, function()
    DC.read()
    check(textHas("hello_b8dc"), "3: print(...) shows in the list")
    check(lineEmpty(), "3: the game's line is empty after the run")
    local h = DC.history()
    hist0 = #h
    check(h[#h] == 'print("hello_b8dc")', "3: the line is the newest history entry (" .. tostring(h[#h]) .. ")")
    DC.run('print("hello_b8dc")')
end)
step(10, function()
    check(#DC.history() == hist0, "6: the same line twice in a row keeps one history entry (" .. hist0 .. " then " .. #DC.history() .. ")")
end)

-- ===== 3b. (Nov 8 QA, Build's 80d07c55) the typed line is drawn by ZeD in F3; the game's box is keys only (its text alpha 0 by design)
local LONG = "local longline = 'the quick brown fox jumps over the lazy dog'; for i = 1, 20 do print(i .. longline) end -- 0123456789 ABCDEFGHIJ end"
local function inp() return DC.win and DC.win.input end
local function curPos() local ok, c = pcall(function() return inp().javaObject:getCursorPos() end); return ok and c or nil end
local function setCur(c) pcall(function() inp().javaObject:setCursorPos(c) end) end
local function typed() local i = inp(); return i and tostring(i:getText() or "") or "" end
local function geom(tag)
    local w, i = DC.win, inp()
    if not (w and i) then return end
    local ok, ax, ay = pcall(function() return w:getAbsoluteX(), w:getAbsoluteY() end)
    local fr = w._fieldRect or {}
    say("3b geom " .. tag .. ": win abs " .. tostring(ax) .. "," .. tostring(ay) .. " size " .. tostring(w:getWidth()) .. "x" .. tostring(w:getHeight())
        .. "; field " .. tostring(fr.x) .. "," .. tostring(fr.y) .. " " .. tostring(fr.w) .. "x" .. tostring(fr.h)
        .. "; typeX " .. tostring(w._typeX) .. " cw " .. tostring(w._typeCw) .. " start " .. tostring(w._typeStart)
        .. "; cursor " .. tostring(curPos()) .. " len " .. #typed() .. "; scale " .. tostring(ZeD.T.scale or (ZeD.T.getScale and ZeD.T.getScale())) .. " F3 px " .. tostring(ZeD.T.fontPx and ZeD.T.fontPx[ZeD.T.fontF3]))
end
local function fits() local w = DC.win; return w and w._typeCw and math.max(1, math.floor((((w._fieldRect and w._fieldRect.w) or 0) / w._typeCw))) end
step(5, function() DC.run('print("a printed line above the typed one")') end)
-- short text, focused: same size as the printed lines; the caret
step(20, function()
    local i = inp()
    check(i ~= nil, "3b: ZeD's input line exists")
    check(i ~= nil and i.zedDrawsText == true, "3b: the box is marked as drawn by ZeD (the game's own text is alpha 0 by design)")
    if i then pcall(function() i:setText("typed text in the input line GgYy 0123"); i:focus() end) end
end)
step(30, function()
    check(inp() and inp():isFocused(), "3b: the input line is focused")
    geom("short")
    shot("typed")
end)
-- placeholder: empty and unfocused
step(5, function() local i = inp(); if i then pcall(function() i:setText(""); i:unfocus() end) end end)
step(25, function()
    check(typed() == "" and not (inp() and inp():isFocused()), "3b: empty and unfocused")
    geom("placeholder")
    shot("placeholder")
end)
-- empty and focused: no placeholder, a caret
step(5, function() local i = inp(); if i then pcall(function() i:focus() end) end end)
step(25, function() geom("empty_focused"); shot("empty_focused") end)
-- a line longer than the box
step(5, function() local i = inp(); if i then pcall(function() i:setText(LONG); i:focus() end); setCur(#LONG) end end)
step(30, function()
    geom("long_end")
    local w = DC.win
    local n = fits()
    check(#LONG > (n or 0), "3b: the typed line is longer than the box (" .. #LONG .. " chars, about " .. tostring(n) .. " fit)")
    check(curPos() == #LONG, "3b: the cursor is at the end of the long line (" .. tostring(curPos()) .. ")")
    check((w._typeStart or 0) > 0, "3b: the long line scrolled (first drawn char " .. tostring(w._typeStart) .. ")")
    check(curPos() ~= nil and curPos() >= (w._typeStart or 0), "3b: the caret is in view at the end")
    shot("long_end")
    setCur(0)
end)
-- Home
step(25, function()
    geom("home")
    check(curPos() == 0, "3b: Home puts the cursor at 0")
    check((DC.win._typeStart or 0) == 0, "3b: and the line scrolled back to its start")
    shot("home")
    setCur(#LONG)
end)
-- End
step(25, function()
    geom("end")
    check(curPos() == #LONG, "3b: End puts the cursor at the end")
    check((DC.win._typeStart or 0) > 0, "3b: and the line scrolled to show it")
    shot("end")
    local c = curPos() or 0
    for _ = 1, 3 do c = c - 1; setCur(c) end
end)
-- arrows: left three, then keep going left to walk past the left edge of the view
step(20, function()
    geom("left3")
    check(curPos() == #LONG - 3, "3b: Left x3 from the end gives " .. (#LONG - 3) .. " (" .. tostring(curPos()) .. ")")
    local n = fits() or 40
    setCur(math.max(0, #LONG - n - 15))
end)
step(25, function()
    local w, c = DC.win, curPos()
    geom("left_far")
    check(c ~= nil and c >= (w._typeStart or 0), "3b: walking left, the caret stays in view (cursor " .. tostring(c) .. ", first drawn char " .. tostring(w._typeStart) .. ")")
    shot("left_far")
    setCur((c or 0) + 1)
end)
step(20, function()
    check(curPos() ~= nil, "3b: Right moves the cursor (" .. tostring(curPos()) .. ")")
    geom("right1")
    setCur(0)
end)
-- a click in the middle of the visible line
step(25, function()
    local w = DC.win
    local fr, tx, cw = w._fieldRect, w._typeX, w._typeCw
    if not (fr and tx and cw) then check(false, "3b: click: no geometry"); return end
    local want = (w._typeStart or 0) + 12
    local cx, cy = tx + 12 * cw + cw * 0.2, fr.y + fr.h / 2
    w._qaWant = want
    inp():unfocus()
    local ok, e = pcall(w.onMouseDown, w, cx, cy)
    say("3b click at " .. cx .. "," .. cy .. " ok " .. tostring(ok) .. " " .. (ok and "" or tostring(e)))
end)
step(25, function()
    local w = DC.win
    geom("click")
    check(inp():isFocused(), "3b: a click in the line focuses it")
    check(curPos() == w._qaWant, "3b: the click put the cursor at column " .. tostring(w._qaWant) .. " (" .. tostring(curPos()) .. ")")
    shot("click")
    -- a click past the end of a short line puts the cursor at its end
    pcall(function() inp():setText("short"); end)
    local fr = w._fieldRect
    pcall(w.onMouseDown, w, fr.x + fr.w - 4, fr.y + fr.h / 2)
end)
step(20, function()
    check(curPos() == 5, "3b: a click past the end of a short line puts the cursor at its end (" .. tostring(curPos()) .. ")")
    shot("click_end")
    pcall(function() inp():setText(""); inp():unfocus() end)
end)


-- ===== 4 / 5. errors
step(5, function()
    DC.read()
    e0 = errCount()
    DC.run("local t = nil; t.x = 1")
end)
step(45, function()
    DC.read()
    e1 = errCount()
    check(e1 >= e0 + 1, "4: a runtime error adds an error block (" .. e0 .. " then " .. e1 .. ")")
    do -- (Nov 8 QA) the first bytes of the frame lines, and what the parser does with a clean copy
        local ls = DC.lines()
        for i = 14, 18 do if ls[i] then say("4 bytes line " .. i .. ": " .. table.concat({ ls[i].s:byte(1, 6) }, ",") .. " err=" .. tostring(ls[i].err)) end end
        local l2, n2 = DC.parse('x\nLua(Vanilla).console(a.lua:1)\nse.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)\n')
        say("4 parse of a clean copy: " .. tostring(n2) .. " error block(s); line 2 err " .. tostring(l2[2] and l2[2].err) .. "; text length " .. tostring(#DC.text) .. ", lines " .. tostring(#ls) .. ", errors counted " .. tostring(select(2, DC.lines())))
    end
    do -- (Nov 8 QA) what the box holds after a runtime error: the last lines, as the list reads them
        local ls = DC.lines()
        for i = 1, 0 do say("4 diag line " .. i .. (ls[i].err and " [err]" or "") .. ": " .. tostring(ls[i].s):sub(1, 110)) end
    end
    check(textHas("attempted index") or textHas("non-table") or textHas("nil"), "4: its words are in the list")
    DC.run("this is not lua")
end)
step(45, function()
    DC.read()
    local e2 = errCount()
    check(e2 >= e1 + 1, "5: a line that does not compile adds an error block (" .. e1 .. " then " .. e2 .. ")")
    check(textHas("console"), "5: the console's own compile message is in the list")
end)
step(25, function() shot("errors") end)
step(5, function()
    local h = DC.history()
    local n = #h
    check(n >= 3 and h[n] == "this is not lua", "6: the history ends with the last line run (oldest first; " .. n .. " entries)")
end)

-- ===== 7. the suggestion and Tab
-- (Nov 8 QA, after Build's round 2: the game suggests the CLOSEST global, so "getPl" gives getCell and ZeD uses a suggestion only when it starts with the typed word)
step(5, function() DC.mirror("getPlay") end)
step(35, function()
    local s = DC.suggestion()
    check(s ~= nil and s:find("getPlayer", 1, true) ~= nil, "7: the game's suggestion for getPlay names getPlayer (" .. tostring(s) .. ")")
    local t = DC.complete("getPlay")
    check(t ~= nil and t:find("getPlayer", 1, true) == 1, "7: Tab turns getPlay into getPlayer() (" .. tostring(t) .. ")")
    DC.mirror("")
end)
step(5, function() DC.mirror("getPl") end)
step(35, function()
    local s = DC.suggestion()
    check(s == nil or s:sub(1, 5) == "getPl", "7: a suggestion that does not start with the typed word (getPl) is not offered (" .. tostring(s) .. ")")
    local t = DC.complete("getPl")
    check(t == nil or t == "getPl", "7: Tab on getPl changes nothing (" .. tostring(t) .. ")")
    DC.mirror("")
end)

-- ===== 8. clear
step(5, function() DC.clear() end)
step(10, function()
    DC.read()
    check(DC.text == "", "8: Clear empties the list")
    DC.run('print("again_b8dc")')
end)
step(35, function()
    DC.read()
    check(textHas("again_b8dc"), "8: new output shows after a clear")
    DC.run("clear")
end)
step(35, function()
    DC.read()
    check(not textHas("again_b8dc"), "8: the typed command clear empties the list too")
end)

-- ===== 11. the close box and the key
step(5, function() DC.close() end)
step(25, function()
    check(not DC.isOpen(), "11: the close box shuts ZeD's window")
    check(not DC.up(jc), "11: and the game's flag goes down with it")
    flag(true)
end)
step(30, function()
    check(DC.isOpen(), "11: the key (the flag) opens it again")
end)

-- ===== 14. the wheel
step(5, function()
    local B = ZeD.DpadWheels and ZeD.DpadWheels.B
    local list = (B and B.zed) and B.zed(p, pn) or {}
    local last = list[#list]
    check(last ~= nil and last.name == ZeD.tr("UI_ZeD_Console_Title"), "pad 1: the ZeD wheel's last slice is the Lua console (" .. tostring(last and last.name) .. ")")
    check(last ~= nil and last.icon == "pencil", "pad 1: with the pencil icon")
end)

-- ===== 12. the switch "Safe mode: Lua console"
step(5, function()
    if not opt then say("NOTE 12: no console switch in ZeD setup; skipped"); return end
    pcall(function() opt:setValue(2) end)
end)
step(70, function()
    if not opt then return end
    check(DC.handedBack(), "12: the switch On hands the console back to the game")
    check(not DC.isOpen(), "12: ZeD's window is shut")
    local okx, x = pcall(function() return jc:getX() end)
    check(okx and type(x) == "number" and x > -50000, "12: the game's own console is back in its place (x " .. tostring(x) .. ")")
    check(DC.up(jc), "12: and open, as ZeD's was")
    shot("handed_back")
    pcall(function() opt:setValue(optWas or 1) end)
end)
step(70, function()
    if not opt then return end
    check(not DC.handedBack(), "12: the switch Off takes it again")
    check(DC.isOpen(), "12: ZeD's window is back")
    check(parked(), "12: the game's own console is parked again")
end)
step(10, function() end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
