-- ZeDUI/tools/qa/zedqa_console_scratch.lua  (Nov 12 2026, QA; punch list 136 Phase 2: the Lua console's scratchpad)
-- The game runs with -debug. The script drives ZeD's Lua console (ZeD.DebugConsole, ZeD.ConsoleScratch) and checks the
-- scratchpad against the real game: Kahlua's loadstring and its error words, the game's multi-line text box and its keys
-- (queueKeyEvent: Enter and Up reach the box as typed keys), Zomboid/Lua on disk.
--   1 the flag opens the window; the Scratchpad keycap swaps the line for the box (the line's words come along); shot
--   2 a run of three lines through Run: a "ran" row with "(+2 lines)", its print from Console under it, the box's own
--     copy of that print skipped (one row); a run past 256 characters runs whole
--   3 Enter typed into the box (a real key) runs it; the box empties
--   4 a block left open (does not compile) and a nil index (fails): error rows from Console, the words noted
--   5 the history: the runs at the end of S.history and in Zomboid/Lua/ZeD_console_history.txt (read back); Up typed
--     on the first line brings the newest run back
--   6 snippets: Save snippet asks in the band (shot), saved under a name, in ZeD_console_snippets.txt (read back);
--     renamed; loaded into the box from the column
--   7 no loadstring (taken away for a few ticks, put back): the notice, Run grayed, nothing runs (shot)
--   8 the controller hand on the box, the column and the name band (shots)
-- The error runs make the game log Lua errors naming "console" if Kahlua logs a pcall's error: the manifest says
-- expect=console. Whatever snippets and history were there before are put back, in memory and on disk, at the end.
-- grep "ZEDQA conscr"; shots zqa_conscr_*.png.
local TAG = "conscr"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local DC = ZeD and ZeD.DebugConsole
local L = ZeD and ZeD.ConsoleLog
local S = ZeD and ZeD.ConsoleScratch
if not (p and DC and L and S) then say("ERR ZeD's console, its log or its scratchpad is not loaded"); say("DONE"); return end
if not DC.debug() then say("NOTE the game is not running with -debug: there is no console to check (run with -debug)"); say("DONE"); return end
if not DC.exists() then say("NOTE the game's console is not on the screen list yet (DC.exists is false); nothing to check"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_conscr_" .. n .. ".png") end) end

-- the step list: step(waitTicks, fn) runs fn that many ticks after the step before
local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
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
    if qc >= s.wait then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end

-- ---- helpers
local jc = DC.game()
local wasUp = DC.up(jc)
local function flag(v) pcall(function() jc:setVisible(v) end) end
local function win() return DC.win end
local function rowWith(part, kind)
    for i = L.last, L.first, -1 do
        local r = L.rows[i]
        if r and (not kind or r.kind == kind) and tostring(r.msg):find(part, 1, true) then return r end
    end
    return nil
end
local function countMsg(msg)
    local n = 0
    for i = L.first, L.last do local r = L.rows[i]; if r and r.msg == msg then n = n + 1 end end
    return n
end
local function lastError()
    for i = L.last, L.first, -1 do local r = L.rows[i]; if r and r.kind == "error" then return r end end
    return nil
end
local function fileText(name)
    local out = {}
    pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        while true do local l = r:readLine(); if l == nil then break end; out[#out + 1] = tostring(l) end
        r:close()
    end)
    return table.concat(out, "\n")
end

-- what was kept before, put back at the end (in memory and on disk)
S.load()
local keptSnips, keptHist = {}, {}
for i, s in ipairs(S.snippets) do keptSnips[i] = { name = s.name, code = s.code } end
for i, c in ipairs(S.history) do keptHist[i] = c end
local LS = loadstring
onCleanup(function()
    loadstring = LS
    S.snippets, S.history = keptSnips, keptHist
    S.rev = S.rev + 1
    S.writeSnippets()
    S.writeHistory()
    DC.qaJoy = nil
    local w = win()
    if w then
        if w.naming then w:nameDone(false) end
        w:setMode("line")
        w.zone = "input"
        pcall(function() w:_padSet("") end)
        pcall(function() w.pad:unfocus() end)
    end
    pcall(function() DC.win.input:setText("") end); DC.mirror("")
    flag(wasUp)
end)

local CODE = "local n = 0\nfor i = 1, 3 do n = n + i end\nprint('zedqa_cs_total', n)"
local LONG = "local s = '" .. string.rep("z", 400) .. "'\nprint('zedqa_cs_long', #s)"

-- ===== 1. open, swap
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    flag(false)
end)
step(20, function() flag(true) end)
step(30, function()
    check(DC.isOpen(), "1: the flag opens ZeD's Lua console")
    say("NOTE loadstring present: " .. tostring(S.canRun()) .. "; snippets kept " .. #S.snippets .. ", runs kept " .. #S.history)
    local w = win()
    w.input:setText("print('zedqa_cs_carried')")
    w:press("topad")
    check(w.mode == "pad", "1: Scratchpad swaps the line for the box")
    check(w:padText() == "print('zedqa_cs_carried')" and w:lineText() == "", "1: the line's words came along")
end)
step(15, function()
    shot("pad")
    local w = win()
    check(w._padRect ~= nil and w._sideRect ~= nil, "1: the box and the column laid out")
    w:press("toline")
    check(w.mode == "line" and w:lineText() == "print('zedqa_cs_carried')", "1: One line swaps back, a one-line box comes along")
    w.input:setText("")
    w:press("topad")
end)

-- ===== 2. runs through Run
step(10, function()
    local w = win()
    w:_padSet(CODE)
    w:press("run")
    check(w:padText() == "", "2: Run emptied the box")
end)
step(40, function()
    local ran = rowWith("> local n = 0", "ran")
    check(ran ~= nil and tostring(ran.msg):find("(+2", 1, true) ~= nil, "2: a ran row with its first line and the lines more (" .. tostring(ran and ran.msg) .. ")")
    local out = rowWith("zedqa_cs_total", "print")
    check(out ~= nil and out.mod == L.CONSOLE, "2: its print a row from Console (" .. tostring(out and out.msg) .. ")")
    check(ran and out and out.id > ran.id, "2: the print under the ran row")
    check(out and countMsg(out.msg) == 1, "2: the box's own copy of the print skipped (" .. tostring(out and countMsg(out.msg)) .. " rows)")
    win():_padSet(LONG)
    win():press("run")
end)
step(40, function()
    local out = rowWith("zedqa_cs_long", "print")
    check(out ~= nil and tostring(out.msg):find("400", 1, true) ~= nil, "2: a run of " .. #LONG .. " characters ran whole (" .. tostring(out and out.msg) .. ")")
end)

-- ===== 3. Enter, a real key
step(10, function()
    local w = win()
    w:_padSet("print('zedqa_cs_enter')")
    w.pad:focus()
end)
step(5, function() queueKeyEvent(Keyboard.KEY_RETURN) end)
step(30, function()
    local w = win()
    check(rowWith("zedqa_cs_enter", "print") ~= nil, "3: Enter typed into the box ran it")
    check(w:padText() == "", "3: the box emptied (" .. tostring(w:padText()) .. ")")
end)

-- ===== 4. errors
step(10, function()
    win():_padSet("for i = 1, 3 do\nprint(i)")
    win():press("run")
end)
step(30, function()
    local e = lastError()
    check(e ~= nil and e.mod == L.CONSOLE, "4: a block left open is an error row from Console")
    say("NOTE compile error words: " .. tostring(e and e.msg) .. " | " .. L.srcOf(e or {}))
    win():_padSet("local x = nil\nreturn x.zedqa")
    win():press("run")
end)
step(30, function()
    local e = lastError()
    check(e ~= nil and e.mod == L.CONSOLE, "4: a run that fails is an error row from Console")
    say("NOTE runtime error words: " .. tostring(e and e.msg))
    check(print ~= nil and rowWith("zedqa_cs_enter", "print") ~= nil, "4: print is the game's again")
end)

-- ===== 5. history
step(10, function()
    check(S.history[#S.history] == "local x = nil\nreturn x.zedqa", "5: the last run is the newest kept")
    local t = fileText(S.HIST_FILE)
    check(t:find("print('zedqa_cs_total', n)", 1, true) ~= nil, "5: the runs are in Zomboid/Lua/" .. S.HIST_FILE)
    local w = win()
    w:_padSet("zedqa draft", 0)
    w.pad:focus()
end)
step(5, function() queueKeyEvent(Keyboard.KEY_UP) end)
step(20, function()
    local w = win()
    check(w:padText() == "local x = nil\nreturn x.zedqa", "5: Up typed on the first line brought the newest run back (" .. tostring(w:padText()):sub(1, 40) .. ")")
    w:padHistory(1)
    check(w:padText() == "zedqa draft", "5: newer past the newest: the draft back")
end)

-- ===== 6. snippets
step(10, function()
    local w = win()
    w.pad:unfocus()
    w:_padSet("-- zedqa where\nprint(getPlayer():getX())")
    w:press("save")
    check(w.naming and w.naming.kind == "save" and w.nameE:getText() == "-- zedqa where", "6: Save snippet asks in the band, the first line offered")
end)
step(15, function()
    shot("name_band")
    local w = win()
    w.nameE:setText("zedqa snippet")
    w:press("nsave")
    local i = S.find("zedqa snippet")
    check(i ~= nil and w.naming == nil, "6: saved under its name")
    check(fileText(S.SNIP_FILE):find("== zedqa snippet\n-- zedqa where", 1, true) ~= nil, "6: in Zomboid/Lua/" .. S.SNIP_FILE)
    w:startNaming("rename", i)
    w.nameE:setText("zedqa renamed")
    w:nameDone(true)
    check(S.find("zedqa renamed") == i and fileText(S.SNIP_FILE):find("== zedqa renamed", 1, true) ~= nil, "6: renamed, on disk too")
    w:_padSet("")
    w:useSide({ t = "snip", i = i })
    check(w:padText() == "-- zedqa where\nprint(getPlayer():getX())", "6: loaded into the box from the column")
end)
step(10, function() shot("snippet_loaded") end)

-- ===== 7. no loadstring
step(10, function()
    loadstring = nil
    local w = win()
    w:_padSet("print('zedqa_cs_nope')")
end)
step(10, function()
    local w = win()
    check(not S.canRun(), "7: no loadstring seen")
    check(w._bandOff.run == true, "7: Run grayed")
    local last = L.last
    w:press("run")
    check(L.last == last and w:padText() == "print('zedqa_cs_nope')", "7: Run does nothing, the words stay")
    shot("noload")
end)
step(5, function()
    loadstring = LS
    check(S.canRun(), "7: loadstring back")
end)

-- ===== 8. the controller hand
step(10, function()
    DC.qaJoy = true
    local w = win()
    w:_padSet("print('zedqa_cs_pad')")
    w.zone = "input"
end)
step(10, function() shot("pad_box"); win():padDir("right") end)
step(10, function()
    local w = win()
    check(w.zone == "side", "8: Right from the box, the column")
    w:padDir("down")
end)
step(10, function()
    shot("pad_column")
    local w = win()
    w:padX()
    check(w.naming ~= nil and w.zone == "band", "8: X in the column asks in the band")
end)
step(10, function()
    shot("pad_name_band")
    local w = win()
    w:onJoypadDown(Joypad.BButton, nil)
    check(w.naming == nil and DC.isOpen(), "8: B cancels the band, the window stays")
end)

step(5, function() end)
ticker = onTick
Events.OnTick.Add(ticker)
