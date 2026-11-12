-- ZeDUI/tools/qa/zedqa_console_complete.lua  (Nov 12 2026, QA; the Lua console's suggestions and Help page)
-- The game runs with -debug, single player. The script drives ZeD's Lua console (ZeD.DebugConsole,
-- ZeD.ConsoleComplete) against the real game: Kahlua's pairs over _G, the player's real Java metatable and the
-- reflection helpers, the real text boxes and their keys (queueKeyEvent).
--   1 the globals walk: how many names, how long it took (NOTE); kept on the second call
--   2 "getPl" typed in the line: the pull-down opens by itself (shot); getPlayer among the rows; Tab takes it
--   3 "getPlayer():getPl": Java methods of the player, marked Java, with parameter counts from reflection (NOTE: how
--     many methods, how many with a count, how long the first read took); the second read is kept (fast)
--   4 "ZeD.T." fields; "getPlayer():getInventory():get" a chain of get calls
--   5 Down and Up typed as real keys move the pick; Enter typed takes it and does not run; Esc shuts it
--   6 the scratchpad: "getPl" in the box, Enter typed takes it (no run, no new line)
--   7 the controller hand on the pull-down (DC.qaJoy): A takes, B shuts (shots)
--   8 the Help page: its sections drawn, folding one, Back to the log (shots)
-- Nothing in the world changes; the line, the box and the page are put back at the end.
-- grep "ZEDQA concmp"; shots zqa_concmp_*.png.
local TAG = "concmp"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local DC = ZeD and ZeD.DebugConsole
local AC = ZeD and ZeD.ConsoleComplete
if not (p and DC and AC) then say("ERR ZeD's console or its suggestions are not loaded"); say("DONE"); return end
if not DC.debug() then say("NOTE the game is not running with -debug: there is no console to check (run with -debug)"); say("DONE"); return end
if not DC.exists() then say("NOTE the game's console is not on the screen list yet (DC.exists is false); nothing to check"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_concmp_" .. n .. ".png") end) end

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

local jc = DC.game()
local wasUp = DC.up(jc)
local function flag(v) pcall(function() jc:setVisible(v) end) end
local function win() return DC.win end
local function names(ac)
    local out = {}
    for _, it in ipairs(ac and ac.items or {}) do out[#out + 1] = it.n end
    return table.concat(out, ",")
end
local function typeLine(s)
    local w = win()
    w.input:focus()
    w.input:setText(s)
    pcall(function() w.input.javaObject:setCursorPos(#s) end)
end
onCleanup(function()
    DC.qaJoy = nil
    local w = win()
    if w then
        w:setPage("log")
        w:setMode("line")
        w.zone = "input"
        pcall(function() w:_padSet("") end)
        pcall(function() w.pad:unfocus() end)
        pcall(function() w.input:setText(""); w.input:unfocus() end)
        w.ac = nil
    end
    DC.mirror("")
    flag(wasUp)
end)

-- ===== 1. the globals walk
step(1, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    flag(false)
end)
step(20, function() flag(true) end)
step(30, function()
    check(DC.isOpen(), "1: the flag opens ZeD's Lua console")
    AC.refresh()
    local t0 = getTimestampMs()
    local g = AC.globals()
    local ms = getTimestampMs() - t0
    say("NOTE globals walked: " .. #g .. " names in " .. ms .. " ms")
    check(#g > 500, "1: the walk found the game's globals (" .. #g .. ")")
    local t1 = getTimestampMs()
    check(AC.globals() == g, "1: kept on the second call (" .. (getTimestampMs() - t1) .. " ms)")
    local kinds = {}
    for _, it in ipairs(g) do kinds[it.k] = (kinds[it.k] or 0) + 1 end
    say("NOTE kinds: function=" .. tostring(kinds["function"]) .. " table=" .. tostring(kinds.table) .. " Java=" .. tostring(kinds.Java) .. " value=" .. tostring(kinds.value))
    typeLine("getPl")
end)
-- ===== 2. the pull-down opens by itself; Tab takes
step(10, function()
    local w = win()
    shot("globals")
    check(w.ac ~= nil, "2: \"getPl\": the pull-down opened by itself")
    say("NOTE rows: " .. names(w.ac) .. (w.ac and (" (+" .. w.ac.more .. " more)") or ""))
    check(w.ac and names(w.ac):find("getPlayer", 1, true) ~= nil, "2: getPlayer among them")
    if w.ac then for i, it in ipairs(w.ac.items) do if it.n == "getPlayer" then w.acI = i end end end
    w.input.onOtherKey(w.input, Keyboard.KEY_TAB)
    check(w:lineText() == "getPlayer()", "2: Tab took it: " .. w:lineText())
end)
-- ===== 3. Java methods of the player
step(5, function()
    local t0 = getTimestampMs()
    local list, cls = AC.javaMethods(p)
    local ms = getTimestampMs() - t0
    local counted = 0
    for _, it in ipairs(list) do if it.ar ~= nil then counted = counted + 1 end end
    say("NOTE player class " .. tostring(cls) .. ": " .. #list .. " methods, " .. counted .. " with a parameter count, first read " .. ms .. " ms")
    check(#list > 500, "3: the player's Java methods from its metatable (" .. #list .. ")")
    check(counted > 0, "3: parameter counts from reflection (" .. counted .. ")")
    local t1 = getTimestampMs()
    AC.javaMethods(p)
    say("NOTE second read " .. (getTimestampMs() - t1) .. " ms (kept)")
    typeLine("getPlayer():getPl")
end)
step(10, function()
    local w = win()
    shot("java")
    check(w.ac and w.ac.java and w.ac.items[1] and w.ac.items[1].k == "Java", "3: \"getPlayer():getPl\" offers Java methods")
    say("NOTE rows: " .. names(w.ac))
    local it = w.ac and w.ac.items[1]
    say("NOTE first row signature: " .. tostring(it and AC.signature(it)))
    typeLine("ZeD.T.acc")
end)
-- ===== 4. fields, a chain
step(10, function()
    local w = win()
    check(w.ac and names(w.ac):find("accent", 1, true) ~= nil, "4: \"ZeD.T.acc\" offers ZeD.T's fields: " .. names(w.ac))
    typeLine("getPlayer():getInventory():getI")
end)
step(10, function()
    local w = win()
    check(w.ac and w.ac.java and names(w.ac):find("getItems", 1, true) ~= nil, "4: a chain of get calls reaches the inventory: " .. names(w.ac))
    typeLine("ZeD.T.")
end)
-- ===== 5. real keys: Down, Up, Enter, Esc
step(10, function() queueKeyEvent(Keyboard.KEY_DOWN) end)
step(5, function() queueKeyEvent(Keyboard.KEY_DOWN) end)
step(5, function()
    local w = win()
    check(w.acI == 3, "5: Down typed twice moves the pick to the third row (" .. tostring(w.acI) .. ")")
    queueKeyEvent(Keyboard.KEY_UP)
end)
step(5, function()
    local w = win()
    check(w.acI == 2, "5: Up typed moves it back (" .. tostring(w.acI) .. ")")
    w._qaPick = w.ac and w.ac.items[2] and w.ac.items[2].n
    w._qaRuns = DC.history and #DC.history() or 0
    queueKeyEvent(Keyboard.KEY_RETURN)
end)
step(5, function()
    local w = win()
    check(w:lineText() == "ZeD.T." .. tostring(w._qaPick), "5: Enter typed took the pick: " .. w:lineText())
    check(#DC.history() == w._qaRuns, "5: Enter with the pull-down open did not run the line")
    typeLine("getPl")
end)
step(10, function() queueKeyEvent(Keyboard.KEY_ESCAPE) end)
step(5, function()
    local w = win()
    check(w.ac == nil and w.input:isFocused(), "5: Esc typed shuts the pull-down, the line keeps the keys")
    queueKeyEvent(Keyboard.KEY_ESCAPE)
end)
-- ===== 6. the scratchpad
step(5, function()
    local w = win()
    w:setMode("pad")
    w.pad:focus()
    w:_padSet("local q = getPl")
end)
step(10, function()
    local w = win()
    shot("pad")
    check(w.ac ~= nil, "6: the pull-down in the box")
    if w.ac then for i, it in ipairs(w.ac.items) do if it.n == "getPlayer" then w.acI = i end end end
    queueKeyEvent(Keyboard.KEY_RETURN)
end)
step(5, function()
    local w = win()
    check(w:padText() == "local q = getPlayer()", "6: Enter typed in the box took it (no run, no new line): " .. w:padText():gsub("\n", "\\n"))
    w:_padSet("")
    w:setMode("line")
end)
-- ===== 7. the controller
step(5, function()
    DC.qaJoy = true
    local w = win()
    typeLine("ZeD.T.")
end)
step(10, function()
    local w = win()
    w.input:unfocus()
    w.zone = "input"
    w:onJoypadDirUp()
    check(w.zone == "ac", "7: D-pad up from the line reaches the pull-down")
end)
step(5, function()
    shot("pad_ac")
    local w = win()
    w:onJoypadDirDown()
    local pick = w.ac and w.ac.items[w.acI] and w.ac.items[w.acI].n
    w:onJoypadDown(Joypad.AButton, nil)
    check(w:lineText() == "ZeD.T." .. tostring(pick) and w.zone == "input", "7: A takes: " .. w:lineText())
    typeLine("ZeD.T.")
end)
step(10, function()
    local w = win()
    w.input:unfocus()
    w:onJoypadDirUp()
    w:onJoypadDown(Joypad.BButton, nil)
    check(w.ac == nil and DC.isOpen(), "7: B shuts the pull-down, the window stays")
    DC.qaJoy = nil
    w.input:setText("")
end)
-- ===== 8. the Help page
step(5, function()
    local w = win()
    w:setPage("help")
end)
step(10, function()
    shot("help")
    local w = win()
    check(w._hItems ~= nil and #w._hItems > 10, "8: the Help page laid out (" .. tostring(w._hItems and #w._hItems) .. " items)")
    w:helpFold("where")
end)
step(10, function()
    shot("help_folded")
    local w = win()
    check(w.hFold.where == true, "8: What runs where folded")
    w:helpFold("where")
    w:press("tolog")
    check(w.page == "log", "8: Back to the log")
end)

step(5, function() end)
ticker = onTick
Events.OnTick.Add(ticker)
