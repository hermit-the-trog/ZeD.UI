-- ZeDUI/tools/qa/zedqa_console_log.lua  (Nov 12 2026, QA; punch list 136 Phase 1: the Lua console's Log page)
-- The game runs with -debug. The script drives ZeD's Lua console through the game's own flag and ZeD.DebugConsole.run (the
-- game's ProcessCommand), and checks the Log page (ZeD_ConsoleLog.lua) against what 42.22 really writes:
--   1 the flag opens the window on the Log page, the page strip with three pages, Commands and Help say "coming"
--   2 print lines become rows: a plain print is Game's, "[ZeD] ..." is ZeD-GUI's; the line run shows as a "ran" row
--   3 a deliberate error run three times is ONE error row with the count 3 (the box and the F11 list together), its
--     mod Console, its stack kept; the title says Errors: 3
--   4 the filters: unticking Print hides the prints, the error stays; unticking the Console mod hides the error;
--     the counts beside each filter follow the search
--   5 the search: words of a print find it; a word only in the error's stack finds the error
--   6 the error opened to its stack in place, and shut again
--   7 Export writes what the filters show to Zomboid/Lua/ZeD_console_<date>_<time>.log, the band says where; the file
--     is read back (getFileReader): its header, the print, the error with its stack lines indented
--   8 the controller hand on the strip, the filters, the search, the log, the line and the band (shots)
-- The error lines deliberately make the game log three Lua errors naming "console": the manifest says expect=console.
-- grep "ZEDQA conlog"; shots zqa_conlog_*.png. The export it writes stays in Zomboid/Lua (named in the report).
local TAG = "conlog"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local DC = ZeD and ZeD.DebugConsole
local L = ZeD and ZeD.ConsoleLog
if not (p and DC and L) then say("ERR ZeD's console or its log is not loaded"); say("DONE"); return end
if not DC.debug() then say("NOTE the game is not running with -debug: there is no console to check (run with -debug)"); say("DONE"); return end
if not DC.exists() then say("NOTE the game's console is not on the screen list yet (DC.exists is false); nothing to check"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_conlog_" .. n .. ".png") end) end

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
local function shownRows()
    local out = {}
    for i = 1, L.counts() do out[#out + 1] = L.shownAt(i) end
    return out
end
local function rowWith(part, kind)
    for i = L.first, L.last do
        local r = L.rows[i]
        if r and (not kind or r.kind == kind) and tostring(r.msg):find(part, 1, true) then return r end
    end
    return nil
end
local function consoleErrors()
    local out = {}
    for i = L.first, L.last do local r = L.rows[i]; if r and r.kind == "error" and r.mod == L.CONSOLE then out[#out + 1] = r end end
    return out
end
local function search(q) local w = win(); if w and w.find then w.find:setText(q) end end
local errRow = nil
onCleanup(function()
    search("")
    L.showAll()
    DC.qaJoy = nil
    if win() then win().zone = "input" end
    pcall(function() DC.win.input:setText("") end); DC.mirror("")
    flag(wasUp)
end)

-- ===== 1. open on the Log page
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    flag(false)
end)
step(20, function() flag(true) end)
step(30, function()
    check(DC.isOpen(), "1: the flag opens ZeD's Lua console")
    local w = win()
    check(w and w.page == "log", "1: on the Log page")
    check(w and w._stripHits and #w._stripHits == 3, "1: the page strip has three pages")
    DC.clear()
    L.showAll()
    say("NOTE window " .. tostring(w and w:getWidth()) .. "x" .. tostring(w and w:getHeight()) .. ", F11 entries read so far " .. tostring(L._f11Seen))
end)
step(10, function() win():setPage("cmds") end)
step(15, function() shot("commands_coming"); check(win().page == "cmds", "1: the Commands page shows (its 'coming' line in the shot)"); win():setPage("log") end)

-- ===== 2. prints
step(10, function()
    DC.run('print("zedqa_cl_hello from the console")')
    DC.run('print("[ZeD] zedqa_cl_tagged")')
end)
step(40, function()
    local h = rowWith("zedqa_cl_hello from the console", "print")
    check(h ~= nil, "2: a print is a row")
    check(h and h.mod == L.GAME, "2: a plain print is Game's (" .. tostring(h and h.mod) .. ")")
    local z = rowWith("zedqa_cl_tagged", "print")
    check(z and z.mod == "ZeD-GUI", "2: a [ZeD] print is ZeD-GUI's (" .. tostring(z and z.mod) .. ")")
    local ran = rowWith('> print("zedqa_cl_hello', "ran")
    check(ran ~= nil and ran.mod == L.CONSOLE, "2: the line run is a 'ran' row from Console")
    for _, r in ipairs(shownRows()) do say("NOTE row " .. r.kind .. " | " .. tostring(r.msg):sub(1, 100) .. " | " .. L.modName(r.mod) .. " " .. L.srcOf(r)) end
    shot("prints")
end)

-- ===== 3. one error, three times
step(5, function() DC.run("local zedqa_cl_t = nil; zedqa_cl_t.x = 1") end)
step(15, function() DC.run("local zedqa_cl_t = nil;  zedqa_cl_t.x = 1") end)
step(15, function() DC.run("local zedqa_cl_t = nil;   zedqa_cl_t.x = 1") end)
step(60, function()
    local errs = consoleErrors()
    for _, r in ipairs(errs) do
        say("NOTE error row: n=" .. tostring(r.n) .. " box=" .. tostring(r.nBox) .. " f11=" .. tostring(r.nF11) .. " msg=" .. tostring(r.msg):sub(1, 120)
            .. " place=" .. L.srcOf(r) .. " stack lines=" .. #r.stack)
        for i = 1, math.min(#r.stack, 12) do say("NOTE   stack " .. i .. ": " .. tostring(r.stack[i]):sub(1, 140)) end
    end
    check(#errs == 1, "3: the error run three times is one row (" .. #errs .. " rows)")
    errRow = errs[1]
    check(errRow and errRow.n == 3, "3: its count is 3 (" .. tostring(errRow and errRow.n) .. ")")
    check(errRow and #errRow.stack >= 2, "3: its stack is kept")
    local w = win()
    local st = w and w.titleStats and w.titleStats[1]
    check(st and tostring(st.text):find("3", 1, true) ~= nil, "3: the title counts the errors (" .. tostring(st and st.text) .. ")")
    shot("error_x3")
end)

-- ===== 4. filters
step(5, function() L.toggle("kind", "print") end)
step(10, function()
    local shownPrint, shownErr = false, false
    for _, r in ipairs(shownRows()) do
        if r.kind == "print" then shownPrint = true end
        if r == errRow then shownErr = true end
    end
    check(not shownPrint and shownErr, "4: Print unticked: no prints shown, the error still is")
    check((L.cnt.kind.print or 0) >= 2, "4: the Print row still counts its lines (" .. tostring(L.cnt.kind.print) .. ")")
    shot("print_off")
    L.toggle("kind", "print")
    L.toggle("mod", L.CONSOLE)
end)
step(10, function()
    local shownErr = false
    for _, r in ipairs(shownRows()) do if r == errRow then shownErr = true end end
    check(not shownErr, "4: the Console mod unticked hides the error")
    L.toggle("mod", L.CONSOLE)
    check(L.isOn("mod", L.CONSOLE) and L.isOn("kind", "print"), "4: both ticked again")
end)

-- ===== 5. search
step(5, function() search("zedqa_cl_hello") end)
step(10, function()
    local rows = shownRows()
    local all = #rows > 0
    for _, r in ipairs(rows) do if not (tostring(r.msg):find("zedqa_cl_hello", 1, true)) then all = false end end
    check(all and L.q == "zedqa_cl_hello", "5: the search shows only rows with its words (" .. #rows .. ")")
    check((L.cnt.kind.error or 0) == 0, "5: the filter counts follow the search (errors " .. tostring(L.cnt.kind.error) .. ")")
    shot("search_print")
    -- a word from the error's stack that is not in its message
    local word = nil
    if errRow then
        for _, s in ipairs(errRow.stack) do
            local w = s:match("(KahluaThread)") or s:match("(STACK TRACE)") or s:match("(Callframe)")
            if w and not tostring(errRow.msg):find(w, 1, true) then word = w; break end
        end
    end
    say("NOTE stack-only word: " .. tostring(word))
    if word then search(word) end
end)
step(10, function()
    if L.q ~= "" and L.q ~= "zedqa_cl_hello" then
        local found = false
        for _, r in ipairs(shownRows()) do if r == errRow then found = true end end
        check(found, "5: a word only in the stack (" .. L.q .. ") finds the error")
        shot("search_stack")
    else
        say("NOTE no stack-only word to search for")
    end
    search("")
end)

-- ===== 6. the stack opened in place
step(10, function()
    local w = win()
    if w and errRow then w.pick = errRow; w:toggleOpen(errRow); w.seek = true end
end)
step(15, function()
    local w = win()
    check(w and errRow and w.opened[errRow.id] == errRow, "6: the error opened to its stack")
    shot("stack_open")
    if w and errRow then w:toggleOpen(errRow) end
end)
step(10, function()
    local w = win()
    check(w and errRow and w.opened[errRow.id] == nil, "6: and shut again")
    if w then w.pick = nil end
end)

-- ===== 7. Export, read back
step(5, function()
    local w = win()
    DC.lastExport = nil
    if w then w:press("export") end
end)
step(15, function()
    local name = DC.lastExport
    check(name ~= nil and name:find("^ZeD_console_%d%d%d%d%-%d%d%-%d%d_%d%d%d%d%d%d") ~= nil, "7: Export named for the time (" .. tostring(name) .. ")")
    local w = win()
    check(w and w._status and tostring(w._status.text):find(tostring(name), 1, true) ~= nil, "7: the band says where (" .. tostring(w and w._status and w._status.text) .. ")")
    shot("exported")
    local lines = {}
    if name then
        pcall(function()
            local r = getFileReader(name, false)
            if r then
                local l = r:readLine()
                while l ~= nil do lines[#lines + 1] = tostring(l); l = r:readLine() end
                r:close()
            end
        end)
    end
    say("NOTE export " .. tostring(name) .. ": " .. #lines .. " lines")
    check(#lines > 0 and lines[1]:find("^ZeD%-GUI Lua console") ~= nil, "7: read back, its header (" .. tostring(lines[1]) .. ")")
    local hasPrint, hasErr, hasStack = false, false, false
    for _, l in ipairs(lines) do
        if l:find("zedqa_cl_hello from the console", 1, true) and l:find("| print |", 1, true) then hasPrint = true end
        if l:find("| error |", 1, true) and l:find("| x3", 1, true) then hasErr = true end
        if l:find("^    ") then hasStack = true end
    end
    check(hasPrint, "7: the print in the file")
    check(hasErr, "7: the error in the file with its count x3")
    check(hasStack, "7: the stack lines indented under it")
    local shown = L.counts()
    local rowsIn = 0
    for _, l in ipairs(lines) do if l:find("^%d%d:%d%d:%d%d | ") then rowsIn = rowsIn + 1 end end
    check(rowsIn == shown, "7: as many rows as the filters show (" .. rowsIn .. " of " .. shown .. ")")
end)

-- ===== 8. the controller hand through the zones (DC.qaJoy draws the pad's marks with no pad)
local ZONES = { "strip", "filters", "search", "list", "input", "band" }
step(5, function() DC.qaJoy = true end)
for i, z in ipairs(ZONES) do
    step(8, function()
        local w = win()
        if not w then return end
        w.zone = z
        if z == "list" then w.pick = nil; w:pickStep(-1) end
        if z == "filters" then w.fFocus = 2 end
    end)
    step(12, function() shot("pad_" .. i .. "_" .. z) end)
end
step(5, function()
    local w = win()
    if w then w.zone = "list"; w.pick = nil; w:pickStep(-1); w:padDir("up") end
    check(w and w.zone == "list", "8: Up in the log stays in the log while older rows are there")
    DC.qaJoy = nil
end)

ticker = onTick
Events.OnTick.Add(ticker)
