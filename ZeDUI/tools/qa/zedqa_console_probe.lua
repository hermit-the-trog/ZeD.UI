-- ZeDUI/tools/qa/zedqa_console_probe.lua
-- ============================================================================
-- THE CONSOLE PROBE: what a Lua console can reach in the game, asked before the
-- bigger console is built. QA only, never staged. Read-only towards the world
-- and the save; grep "ZEDQA con0".
--
-- Two ways to run it:
--   * with -debug, through the QA bridge (console_probe.txt for zedqa_run.ps1):
--     the bridge loads it with a player in the world, so it starts at once;
--   * in a normal game (no -debug, where the bridge sleeps), dropped into the
--     mod's client folder as a game file: it loads at the main menu, finds no
--     player and waits for OnGameStart, so it runs again after every
--     quit-to-menu and Continue (that second run answers the save-reload
--     question).
--
-- Every answer is one line: PASS (works as a console needs), FACT (what the
-- game does, yes or no), NOTE (left for a person). ERR only when a probe step
-- itself breaks.
--
-- What it touches, all put back or harmless:
--   * two deliberate Lua errors (one caught, one uncaught from a one-shot
--     OnTick) so the error list has an entry to read; the corner's red error
--     count goes up by one;
--   * "/help" and one unknown command sent the way the chat box sends them;
--   * with -debug, the game's console shown for about a second if it was shut
--     (ZeD's console window opens with it), then shut again;
--   * Zomboid/Lua/zedqa_con0_test.log written over each run: it is the Export
--     test and carries this run's error marker to the next run.
--
-- Every Java call is looked up first and made inside pcall: the game's Java
-- side can throw, and a call that matches none of a method's overloads can
-- break later calls far from here, so each call passes the exact argument
-- types the game's class files list (42.22).
-- ============================================================================

local TAG = "con0"
local STATE_FILE = "zedqa_con0_test.log"

-- the run's id: the wall clock in ms, also the text that marks this run's errors
local ID = "0"
do
    local ok, t = pcall(function() return getTimestampMs() end)
    if ok and t then ID = string.format("%.0f", t) end
end
local MARK_CAUGHT = "con0 deliberate caught error " .. ID
local MARK_UNCAUGHT = "con0 deliberate uncaught error " .. ID

-- a value as one short line: newlines shown as " | ", the user folder taken out (QA reports go to a public repo)
local function clip(s, n)
    s = tostring(s)
    s = string.gsub(s, "[Uu]sers[/\\][^/\\]+", "Users/you")
    s = string.gsub(s, "/home/[^/]+", "/home/you")
    s = string.gsub(s, "\r", "")
    s = string.gsub(s, "\n", " | ")
    s = string.gsub(s, "\t", " ")
    n = n or 240
    if #s > n then s = string.sub(s, 1, n) .. " [+" .. tostring(#s - n) .. " chars]" end
    return s
end

local function say(kind, q, text)
    print("ZEDQA " .. TAG .. " " .. kind .. " " .. q .. " " .. tostring(text))
end

-- does this object (a table or a Java object) answer to this name with a function?
local function has(o, name)
    if o == nil then return false end
    local ok, f = pcall(function() return o[name] end)
    return ok and type(f) == "function"
end

-- a global function, or nil
local function glob(name)
    local f = _G[name]
    if type(f) == "function" then return f end
    return nil
end

-- calls f(...) inside pcall; returns ok and the first result (or the error)
local function try(f, ...)
    if not f then return false, "absent" end
    return pcall(f, ...)
end

local function isDebug()
    local ok, v = try(glob("isDebugEnabled"))
    return ok and v == true
end

-- a field of a Java object by name, through the game's reflection helpers (nil when absent or private)
local function fieldOf(obj, name)
    if not (glob("getNumClassFields") and glob("getClassField") and glob("getClassFieldVal")) then return nil end
    local ok, v = pcall(function()
        local n = getNumClassFields(obj)
        for i = 0, n - 1 do
            local f = getClassField(obj, i)
            if f and has(f, "getName") and f:getName() == name then
                local val = getClassFieldVal(obj, f)
                -- (the game answers the string "<private>" for a field it may not read)
                if type(val) == "string" and val == "<private>" then return nil end
                return val
            end
        end
        return nil
    end)
    if ok then return v end
    return nil
end

-- run state, shared by the steps below (declared before the steps that close over them)
local R = {
    debug = false, jc = nil, out = nil, outBefore = nil, wasUp = nil, shown = false,
    prev = nil, msgs = {}, onMsg = nil, boom = nil, countStart = 0, seen = "no",
}

-- ---------------------------------------------------------------------------
-- the state file: read last run's line, write this run's
-- ---------------------------------------------------------------------------
local function readState()
    local r = nil
    local ok = pcall(function() r = getFileReader(STATE_FILE, false) end)
    if not (ok and r) then return nil end
    local st = {}
    pcall(function()
        local line = r:readLine()
        while line do
            local k, v = string.match(line, "^(%w+)=(.*)$")
            if k then st[k] = v end
            line = r:readLine()
        end
    end)
    pcall(function() r:close() end)
    if not st.id then return nil end
    return st
end

local function writeState(count)
    local w = nil
    local ok, err = pcall(function() w = getFileWriter(STATE_FILE, true, false) end)
    if not (ok and w) then return false, (ok and "no writer" or tostring(err)) end
    local wrote, werr = pcall(function()
        w:writeln("con0 console probe state (ZeD QA; safe to delete)")
        w:writeln("id=" .. ID)
        w:writeln("debug=" .. tostring(R.debug))
        w:writeln("count=" .. tostring(count))
        w:writeln("marker=" .. MARK_UNCAUGHT)
        w:writeln("seen=" .. R.seen)
    end)
    pcall(function() w:close() end)
    return wrote, werr
end

-- ---------------------------------------------------------------------------
-- 1. the F11 error list
-- ---------------------------------------------------------------------------
local function errorList()
    local okC, count = try(glob("getLuaDebuggerErrorCount"))
    local okL, list = try(glob("getLuaDebuggerErrors"))
    local size = nil
    if okL and list and has(list, "size") then
        local okS, s = pcall(function() return list:size() end)
        if okS then size = s end
    end
    return (okC and count or nil), (okL and list or nil), size
end

-- the index and text of the first entry holding this text, or nil
local function findIn(list, size, text)
    if not (list and size) then return nil end
    for i = 0, size - 1 do
        local ok, e = pcall(function() return list:get(i) end)
        if ok and type(e) == "string" and string.find(e, text, 1, true) then return i, e end
    end
    return nil
end

-- one entry's shape: its type, length, line count, how many lines look like stack frames, its first three lines
local function entryShape(e)
    if type(e) ~= "string" then return "type=" .. type(e) .. " value=" .. clip(e, 120) end
    local lines, frames, firsts = 0, 0, {}
    for line in string.gmatch(e .. "\n", "([^\n]*)\n") do
        line = line or ""
        lines = lines + 1
        if string.find(line, "function:", 1, true) or string.find(line, "line #", 1, true)
            or string.find(line, "%.lua") then frames = frames + 1 end
        if #firsts < 3 then firsts[#firsts + 1] = clip(line, 110) end
    end
    return "type=string chars=" .. #e .. " lines=" .. lines .. " stackish lines=" .. frames
        .. " first lines: " .. table.concat(firsts, " / ")
end

local function q1Start()
    local count, list, size = errorList()
    R.countStart = count or 0
    say("FACT", "q1.api", "getLuaDebuggerErrorCount=" .. tostring(glob("getLuaDebuggerErrorCount") ~= nil)
        .. " getLuaDebuggerErrors=" .. tostring(glob("getLuaDebuggerErrors") ~= nil)
        .. " getLuaStackTrace=" .. tostring(glob("getLuaStackTrace") ~= nil))
    if list then
        say("PASS", "q1.list", "the list is readable: count=" .. tostring(count) .. " size=" .. tostring(size)
            .. " java class=" .. tostring(select(2, try(glob("getClassSimpleName"), list))))
        if size and size > 0 then
            local ok, e = pcall(function() return list:get(0) end)
            say("FACT", "q1.entry", "the first entry already there: " .. (ok and entryShape(e) or ("threw " .. clip(e))))
        end
    else
        say("FACT", "q1.list", "no list (getLuaDebuggerErrors absent or threw); count=" .. tostring(count))
    end
    -- the run before this one, from the state file: is its uncaught error still listed?
    local prev = R.prev
    if prev then
        local okT, now = pcall(function() return getTimestampMs() end)
        local ago = "?"
        if okT and now and tonumber(prev.id) then ago = string.format("%.0f", (now - tonumber(prev.id)) / 1000) end
        local idx = findIn(list, size, prev.marker or "?")
        local verdict
        if prev.seen ~= "yes" then
            verdict = "no answer (that run never saw its own error in the list)"
        elseif idx then
            verdict = "the list SURVIVED since that run (same game launch, so it survives a save reload)"
        else
            verdict = "the list was RESET since that run (a save reload or a new launch in between)"
        end
        say("FACT", "q1.reload", "the run before: " .. ago .. " s ago, debug=" .. tostring(prev.debug) .. ", count then="
            .. tostring(prev.count) .. ", its error seen then=" .. tostring(prev.seen) .. "; count now=" .. tostring(count)
            .. "; its error listed now=" .. tostring(idx ~= nil) .. ": " .. verdict)
    else
        say("NOTE", "q1.reload", "no earlier run in " .. STATE_FILE .. ": the reload answer comes from the next run (quit to the main menu, Continue)")
    end
    -- a caught error: does pcall keep it out of the list?
    pcall(error, MARK_CAUGHT)
    local c2, l2, s2 = errorList()
    say("FACT", "q1.caught", "a pcall-caught error: count " .. tostring(count) .. " -> " .. tostring(c2)
        .. ", listed=" .. tostring(findIn(l2, s2, MARK_CAUGHT) ~= nil))
    -- an uncaught one, from a one-shot OnTick (the game logs it and carries on)
    R.boom = function()
        Events.OnTick.Remove(R.boom)
        error(MARK_UNCAUGHT)
    end
    Events.OnTick.Add(R.boom)
    say("NOTE", "q1.uncaught", "one uncaught error raised on the next tick on purpose (\"" .. MARK_UNCAUGHT .. "\")")
end

local function q1After()
    local count, list, size = errorList()
    local idx, e = findIn(list, size, MARK_UNCAUGHT)
    R.seen = idx and "yes" or "no"
    if idx then
        say("PASS", "q1.uncaught", "the uncaught error is listed: count " .. tostring(R.countStart) .. " -> "
            .. tostring(count) .. ", at index " .. tostring(idx) .. " of " .. tostring(size))
        say("FACT", "q1.shape", entryShape(e))
    else
        say("FACT", "q1.uncaught", "the uncaught error is NOT listed (debug=" .. tostring(R.debug) .. "): count "
            .. tostring(R.countStart) .. " -> " .. tostring(count) .. ", size=" .. tostring(size))
    end
    local okS, st = try(glob("getLuaStackTrace"))
    if okS and st and has(st, "size") then
        local n = st:size()
        local first = n > 0 and clip(st:get(0), 120) or "-"
        say("FACT", "q1.stacktrace", "getLuaStackTrace() from a tick: a list of " .. tostring(n) .. ", first: " .. first)
    else
        say("FACT", "q1.stacktrace", "getLuaStackTrace(): " .. clip(st, 120))
    end
end

-- ---------------------------------------------------------------------------
-- 2. loadstring
-- ---------------------------------------------------------------------------
local function q2()
    if type(loadstring) ~= "function" then say("FACT", "q2.loadstring", "absent (type " .. type(loadstring) .. ")"); return end
    local f, err = loadstring("return 1 + 2", "con0_sum")
    local ok, v = false, err
    if f then ok, v = pcall(f) end
    if ok and v == 3 then say("PASS", "q2.run", "loadstring compiles and runs: return 1 + 2 -> 3")
    else say("FACT", "q2.run", "loadstring did not run the chunk: " .. clip(v)) end
    local _, serr = loadstring("return +", "con0_syntax")
    say("FACT", "q2.syntax", "the message for a syntax error: " .. clip(serr))
    local rf = loadstring("local t = nil\nreturn t.x", "con0_runtime")
    local rok, rerr = pcall(rf)
    say("FACT", "q2.runtime", "a runtime error inside pcall: ok=" .. tostring(rok) .. " message: " .. clip(rerr))
    -- past the game's 256-character line: a multi-line chunk of about 600 characters
    local parts = { "local s = 0" }
    for i = 1, 40 do parts[#parts + 1] = "s = s + " .. i end
    parts[#parts + 1] = "return s"
    local long = table.concat(parts, "\n")
    local lf = loadstring(long, "con0_long")
    local lok, lv = false, "no chunk"
    if lf then lok, lv = pcall(lf) end
    say(lok and lv == 820 and "PASS" or "FACT", "q2.long", "a " .. #long .. "-character, " .. #parts .. "-line chunk -> " .. clip(lv))
    say("FACT", "q2.globals", "setfenv=" .. type(setfenv) .. " getfenv=" .. type(getfenv) .. " load=" .. type(load)
        .. " loadstream=" .. type(loadstream) .. " dofile=" .. type(dofile) .. " require=" .. type(require))
end

-- ---------------------------------------------------------------------------
-- 3. the game's console and what reaches its output box
-- ---------------------------------------------------------------------------
local CONSOLE_NAMES = { "ProcessCommand", "update", "render", "onOtherKey", "levenshteinDistance", "addOutput",
    "historyPrev", "historyNext", "ClearConsole", "SpoolText", "SuggestionEngine", "setVisible", "isVisible",
    "getX", "setX", "onMouseDown" }

-- the names a Java object's class lists through getNumClassFunctions / getClassFunction, once each
local function classFunctionNames(obj)
    local names, seen = {}, {}
    local ok, n = try(glob("getNumClassFunctions"), obj)
    if not ok or type(n) ~= "number" then return nil, n end
    for i = 0, n - 1 do
        local okM, m = pcall(getClassFunction, obj, i)
        if okM and m and has(m, "getName") then
            local nm = m:getName()
            if not seen[nm] then seen[nm] = true; names[#names + 1] = nm end
        end
    end
    return names, n
end

local function q3Start()
    local okJ, jc = false, nil
    if UIManager and has(UIManager, "getDebugConsole") then okJ, jc = pcall(UIManager.getDebugConsole) end
    if not (okJ and jc) then say("FACT", "q3.console", "UIManager.getDebugConsole() gives nothing (debug=" .. tostring(R.debug) .. ")"); return end
    R.jc = jc
    local _, cls = try(glob("getClassSimpleName"), jc)
    local okV, up = pcall(function() return jc:isVisible() end)
    say("FACT", "q3.console", "the game's console object exists: class " .. tostring(cls) .. ", visible=" .. tostring(okV and up))
    local vis, hid = {}, {}
    for _, nm in ipairs(CONSOLE_NAMES) do
        if has(jc, nm) then vis[#vis + 1] = nm else hid[#hid + 1] = nm end
    end
    say("FACT", "q3.methods", "callable from Lua: " .. table.concat(vis, ", ") .. "; not: " .. table.concat(hid, ", "))
    local names, n = classFunctionNames(jc)
    if names then
        say("FACT", "q3.reflect", "getClassFunction lists " .. tostring(n) .. " (" .. #names .. " names): "
            .. clip(table.concat(names, " "), 900))
    else
        say("FACT", "q3.reflect", "getNumClassFunctions on the console: " .. clip(n))
    end
    -- the debug options that steer the window
    local dopts = { "UIDebugConsole.StartVisible", "UIDebugConsole.EchoCommand", "UIDebugConsole.DebugLog" }
    local okD, dop = try(glob("getDebugOptions"))
    local vals = {}
    for _, nm in ipairs(dopts) do
        local v = "?"
        if okD and dop and has(dop, "getOptionByName") then
            local okO, o = pcall(function() return dop:getOptionByName(nm) end)
            if okO and o == nil then v = "no such option"
            elseif okO and has(o, "getValue") then v = tostring(o:getValue()) end
        end
        vals[#vals + 1] = nm .. "=" .. v
    end
    say("FACT", "q3.options", table.concat(vals, " "))
    -- the output box (a private field: through reflection)
    R.out = fieldOf(jc, "outputLog")
    if not (R.out and has(R.out, "getText")) then
        say("FACT", "q3.box", "the output box is not readable from Lua here (debug=" .. tostring(R.debug) .. ")")
        R.out = nil
        return
    end
    local okT, t = pcall(function() return R.out:getText() end)
    R.outBefore = okT and tostring(t or "") or ""
    say("FACT", "q3.box", "the output box is readable: " .. #R.outBefore .. " characters now")
    -- shown for a moment so its own update() moves the new output into the box (debug only: the window is real there)
    R.wasUp = okV and up == true
    if R.debug and not R.wasUp then
        R.shown = pcall(function() jc:setVisible(true) end)
    end
    -- one marker down each road
    print("con0 route marker print " .. ID)
    if DebugLog and has(DebugLog, "log") then
        pcall(function() DebugLog.log("con0 route marker DebugLog.log " .. ID) end)
        local okT2, dt = pcall(function() return DebugType.General end)
        local okI, isDT = false, false
        if okT2 and dt ~= nil then okI, isDT = try(glob("instanceof"), dt, "DebugType") end
        if okI and isDT == true then
            pcall(function() DebugLog.log(dt, "con0 route marker DebugLog.log(General) " .. ID) end)
        else
            say("FACT", "q3.debugtype", "DebugType.General is not reachable as a DebugType from Lua")
        end
    else
        say("FACT", "q3.debuglog", "DebugLog.log is not callable from Lua")
    end
end

local function q3After()
    if not R.out then return end
    local okT, t = pcall(function() return R.out:getText() end)
    local now = okT and tostring(t or "") or ""
    local roads = {
        { "print", "con0 route marker print " .. ID },
        { "DebugLog.log(String)", "con0 route marker DebugLog.log " .. ID },
        { "DebugLog.log(General, String)", "con0 route marker DebugLog.log(General) " .. ID },
        { "a caught error", MARK_CAUGHT },
        { "an uncaught error", MARK_UNCAUGHT },
        { "this probe's ZEDQA lines", "ZEDQA " .. TAG .. " FACT q3.box" },
    }
    local res = {}
    for _, r in ipairs(roads) do
        res[#res + 1] = r[1] .. "=" .. (string.find(now, r[2], 1, true) and "yes" or "no")
    end
    say("FACT", "q3.routes", "reached the output box (" .. #R.outBefore .. " -> " .. #now .. " chars, console "
        .. (R.wasUp and "was up" or (R.shown and "shown for the test" or "shut")) .. "): " .. table.concat(res, ", "))
    if R.shown then pcall(function() R.jc:setVisible(false) end) end
    R.outBefore = now
    if has(R.jc, "levenshteinDistance") then
        local okL, d = pcall(function() return R.jc:levenshteinDistance("getPl", "getPlayer") end)
        say("FACT", "q3.levenshtein", "levenshteinDistance(\"getPl\", \"getPlayer\") = " .. clip(okL and d or ("threw " .. tostring(d))))
    end
end

-- ---------------------------------------------------------------------------
-- 4. a slash command the way the chat box sends it (ISChat.onCommandEntered: SendCommandToServer(line))
-- ---------------------------------------------------------------------------
local function q4Start()
    local isC = select(2, try(glob("isClient")))
    local isS = select(2, try(glob("isServer")))
    say("FACT", "q4.where", "isClient=" .. tostring(isC) .. " isServer=" .. tostring(isS)
        .. " ISChat=" .. type(ISChat) .. " ISChat.instance=" .. tostring(ISChat ~= nil and ISChat.instance ~= nil)
        .. " ISChat.onCommandEntered=" .. tostring(ISChat ~= nil and has(ISChat, "onCommandEntered")))
    say("FACT", "q4.globals", "SendCommandToServer=" .. tostring(glob("SendCommandToServer") ~= nil)
        .. " ProcessAdminChatMessage=" .. tostring(glob("ProcessAdminChatMessage") ~= nil)
        .. " sendClientCommand=" .. tostring(glob("sendClientCommand") ~= nil) .. " (only SendCommandToServer is called)")
    -- listen for what comes back as chat while the commands go out
    if Events.OnAddMessage then
        R.onMsg = function(msg, tab)
            local text = msg
            if has(msg, "getText") then
                local ok, t = pcall(function() return msg:getText() end)
                if ok then text = t end
            end
            R.msgs[#R.msgs + 1] = clip(text, 160) .. " (tab " .. tostring(tab) .. ")"
        end
        Events.OnAddMessage.Add(R.onMsg)
    end
    local send = glob("SendCommandToServer")
    if not send then say("FACT", "q4.send", "SendCommandToServer is absent"); return end
    if R.out then
        local okT, t = pcall(function() return R.out:getText() end)
        R.outBefore = okT and tostring(t or "") or R.outBefore
    end
    for _, line in ipairs({ "/help", "/con0nosuchcommand" }) do
        local ok, r = pcall(send, line)
        say("FACT", "q4.send", "SendCommandToServer(\"" .. line .. "\"): ok=" .. tostring(ok) .. " returned "
            .. type(r) .. " " .. clip(r, 160))
    end
end

local function q4After()
    if R.onMsg then pcall(function() Events.OnAddMessage.Remove(R.onMsg) end) end
    local first = {}
    for i = 1, math.min(#R.msgs, 4) do first[#first + 1] = R.msgs[i] end
    say("FACT", "q4.reply", "chat messages in the next 3 s: " .. #R.msgs .. (#first > 0 and (": " .. table.concat(first, " / ")) or ""))
    if R.out then
        local okT, t = pcall(function() return R.out:getText() end)
        local now = okT and tostring(t or "") or ""
        local added = ""
        if #now > #R.outBefore then
            -- the new lines, less this probe's own (the box keeps its last 8192 characters, so a full box only grows
            -- at the end while it trims the start: the comparison is by length, close enough for a look)
            local keep = {}
            for line in string.gmatch(string.sub(now, #R.outBefore + 1) .. "\n", "([^\n]*)\n") do
                line = line or ""
                if line ~= "" and not string.find(line, "ZEDQA " .. TAG, 1, true) then keep[#keep + 1] = line end
            end
            added = table.concat(keep, "\n")
        end
        say("FACT", "q4.box", "new in the console's box since the commands: " .. (added ~= "" and clip(added, 400) or "nothing"))
    end
end

-- ---------------------------------------------------------------------------
-- 5. reflection: listing a Java object's methods and fields (the player)
-- ---------------------------------------------------------------------------
local function q5()
    local p = getPlayer()
    local names = { "getClassSimpleName", "getNumClassFunctions", "getClassFunction", "getMethodParameterCount",
        "getMethodParameter", "getNumClassFields", "getClassField", "getClassFieldVal", "instanceof", "getMethodName" }
    local have = {}
    for _, nm in ipairs(names) do have[#have + 1] = nm .. "=" .. tostring(glob(nm) ~= nil) end
    say("FACT", "q5.globals", table.concat(have, " "))
    local okN, cls = try(glob("getClassSimpleName"), p)
    say("FACT", "q5.simplename", "getClassSimpleName(player) = " .. clip(okN and cls or ("threw " .. tostring(cls))))
    local io = glob("instanceof")
    local i1 = select(2, try(io, p, "IsoPlayer"))
    local i2 = select(2, try(io, p, "IsoGameCharacter"))
    local i3 = select(2, try(io, p, "IsoZombie"))
    say("FACT", "q5.instanceof", "IsoPlayer=" .. tostring(i1) .. " IsoGameCharacter=" .. tostring(i2) .. " IsoZombie=" .. tostring(i3))
    if has(p, "getClass") then
        local okC, c = pcall(function() return p:getClass() end)
        local sn = "no getSimpleName"
        if okC and has(c, "getSimpleName") then sn = tostring(c:getSimpleName()) end
        say("FACT", "q5.getclass", "player:getClass() ok=" .. tostring(okC) .. " getSimpleName: " .. sn)
    else
        say("FACT", "q5.getclass", "player:getClass is not callable from Lua")
    end
    -- the method list
    local okF, n = try(glob("getNumClassFunctions"), p)
    if okF and type(n) == "number" then
        local sample, found, named = {}, false, 0
        for i = 0, n - 1 do
            local okM, m = pcall(getClassFunction, p, i)
            if okM and m and has(m, "getName") then
                named = named + 1
                local nm = m:getName()
                if nm == "getPlayerNum" then found = true end
                if #sample < 6 then
                    local pc = select(2, try(glob("getMethodParameterCount"), m))
                    local rt = "?"
                    if has(m, "getReturnType") then
                        local okR, r = pcall(function() return m:getReturnType():getSimpleName() end)
                        if okR then rt = tostring(r) end
                    end
                    local p0 = ""
                    if type(pc) == "number" and pc > 0 then p0 = tostring(select(2, try(glob("getMethodParameter"), m, 0))) end
                    sample[#sample + 1] = rt .. " " .. tostring(nm) .. "(" .. tostring(pc) .. (p0 ~= "" and (": " .. p0) or "") .. ")"
                end
            end
        end
        say(named > 0 and "PASS" or "FACT", "q5.methods", "getNumClassFunctions(player) = " .. tostring(n) .. ", named "
            .. named .. ", getPlayerNum among them=" .. tostring(found) .. "; sample: " .. table.concat(sample, ", "))
    else
        say("FACT", "q5.methods", "getNumClassFunctions(player): " .. clip(n))
    end
    -- the field list
    local okFl, nf = try(glob("getNumClassFields"), p)
    if okFl and type(nf) == "number" then
        local fs, privates = {}, 0
        for i = 0, nf - 1 do
            local okG, f = pcall(getClassField, p, i)
            if okG and f and has(f, "getName") then
                if #fs < 8 then fs[#fs + 1] = tostring(f:getName()) end
                local okV, v = pcall(getClassFieldVal, p, f)
                if okV and v == "<private>" then privates = privates + 1 end
            end
        end
        say("FACT", "q5.fields", "getNumClassFields(player) = " .. tostring(nf) .. ", private (unreadable) " .. privates
            .. "; first: " .. table.concat(fs, ", "))
    else
        say("FACT", "q5.fields", "getNumClassFields(player): " .. clip(nf))
    end
    -- the metatable road (autocomplete without reflection)
    local okMt, mt = pcall(getmetatable, p)
    if not okMt then mt = nil end
    local idx = nil
    if type(mt) == "table" then
        local okI, v = pcall(function() return mt.__index end)
        if okI then idx = v end
    end
    local keys, hasPN = 0, false
    if type(idx) == "table" then
        for k in pairs(idx) do
            keys = keys + 1
            if k == "getPlayerNum" then hasPN = true end
        end
    end
    say("FACT", "q5.metatable", "getmetatable(player)=" .. type(mt) .. " __index=" .. type(idx) .. " keys=" .. keys
        .. " getPlayerNum among them=" .. tostring(hasPN))
end

-- ---------------------------------------------------------------------------
-- 6. files: reading the logs, writing a .log for Export
-- ---------------------------------------------------------------------------
-- can getFileReader open it? (never prints the contents: only whether it opened and its first line's length)
local function readable(path)
    local r = nil
    local ok, err = pcall(function() r = getFileReader(path, false) end)
    if not ok then return "threw " .. clip(err, 160) end
    if not r then return "no (nil)" end
    local okL, line = pcall(function() return r:readLine() end)
    pcall(function() r:close() end)
    return "OPENED (first line " .. ((okL and line) and tostring(#line) or "?") .. " chars)"
end

local function q6()
    local paths = { "../console.txt", "..\\console.txt", "../coop-console.txt", "../options.ini", "../Logs/", "ModOptions.ini" }
    local res = {}
    for _, pth in ipairs(paths) do res[#res + 1] = pth .. ": " .. readable(pth) end
    say("FACT", "q6.read", table.concat(res, "; "))
    local okD, doc = try(glob("getMyDocumentFolder"))
    if okD and type(doc) == "string" then
        say("FACT", "q6.absolute", "<game folder>/console.txt by absolute path: " .. readable(doc .. "/console.txt"))
    else
        say("FACT", "q6.absolute", "getMyDocumentFolder: " .. clip(doc, 100))
    end
end

-- written last, so it carries this run's answer; then read back
local function q6Write(count)
    local ok, err = writeState(count)
    if not ok then say("FACT", "q6.write", "getFileWriter could not write Lua/" .. STATE_FILE .. ": " .. clip(err)); return end
    local back = readState()
    if back and back.id == ID then
        say("PASS", "q6.write", "getFileWriter wrote Lua/" .. STATE_FILE .. " and getFileReader read it back (Export can use a .log)")
    else
        say("FACT", "q6.write", "wrote Lua/" .. STATE_FILE .. " but reading it back gave " .. tostring(back and back.id))
    end
end

-- ---------------------------------------------------------------------------
-- 7. the research's other open questions
-- ---------------------------------------------------------------------------
local function q7()
    say("FACT", "q7.debugmenu", "ISDebugMenu=" .. type(ISDebugMenu)
        .. " addButtonInfo=" .. tostring(ISDebugMenu ~= nil and has(ISDebugMenu, "addButtonInfo"))
        .. " setupButtons=" .. tostring(ISDebugMenu ~= nil and has(ISDebugMenu, "setupButtons"))
        .. " (media/lua/client/DebugUIs/DebugMenu/ISDebugMenu.lua)")
    -- wrapping print: the road the log pane takes for Lua output
    local orig, got = print, nil
    local okW = pcall(function()
        print = function(...) got = select("#", ...) > 0 and tostring((...)) or ""; return orig(...) end
        print("con0 print wrap test " .. ID)
    end)
    print = orig
    say((okW and got and string.find(got, ID, 1, true)) and "PASS" or "FACT", "q7.printwrap",
        "a replaced global print sees print() calls: " .. tostring(got ~= nil))
    -- events that might report errors or log lines as they happen
    local evs = {}
    if type(Events) == "table" then
        for k in pairs(Events) do
            local s = tostring(k)
            if string.find(s, "rror") or string.find(s, "Log") or string.find(s, "Console") or string.find(s, "Debug") then
                evs[#evs + 1] = s
            end
        end
    end
    table.sort(evs)
    say("FACT", "q7.events", "events named like error / log / console / debug: " .. (#evs > 0 and table.concat(evs, ", ") or "none"))
    say("NOTE", "q7.byhand", "by hand: the game's own console (paste, select and copy, scrollback, UI scale, controller) and the debug menu and Admin Panel with a controller")
end

-- ---------------------------------------------------------------------------
-- the run: steps on OnTick, a few ticks apart
-- ---------------------------------------------------------------------------
local Q, qi, waited = {}, 1, 0
local ticker = nil
local function step(ticks, name, fn) Q[#Q + 1] = { ticks = ticks, name = name, fn = fn } end

local function finish()
    local count = errorList()
    pcall(q6Write, count)
    say("NOTE", "end", "debug=" .. tostring(R.debug) .. " id=" .. ID .. " (" .. STATE_FILE .. " now carries this run for the next)")
    ZEDQA_CON0_RUNNING = nil
    print("ZEDQA " .. TAG .. " DONE")
end

ticker = function()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); return end
    waited = waited + 1
    if waited < s.ticks then return end
    waited = 0
    qi = qi + 1
    local ok, e = pcall(s.fn)
    if not ok then say("ERR", s.name, "the probe step broke: " .. clip(e, 200)) end
end

step(30, "head", function()
    R.debug = isDebug()
    local okV, ver = false, nil
    if has(getCore(), "getVersion") then okV, ver = pcall(function() return getCore():getVersion() end) end
    say("NOTE", "head", "debug=" .. tostring(R.debug) .. " game=" .. tostring(okV and ver or "?") .. " id=" .. ID)
    R.prev = readState()
    -- (under -debug an uncaught error would open the Lua debugger and stop the game; the QA bridge turns that off
    -- too, this covers the drop-in run)
    if R.debug and UIManager and has(UIManager, "setShowLuaDebuggerOnError") then
        pcall(function() UIManager.setShowLuaDebuggerOnError(false) end)
    end
end)
step(1, "q1", q1Start)
step(1, "q2", q2)
step(1, "q3", q3Start)
step(30, "q1b", q1After)
step(10, "q3b", q3After)
step(1, "q4", q4Start)
step(1, "q5", q5)
step(1, "q6", q6)
step(1, "q7", q7)
step(90, "q4b", q4After)
step(1, "end", finish)

local function start()
    if ZEDQA_CON0_RUNNING then say("NOTE", "start", "a run is already going; this one stands down"); return end
    ZEDQA_CON0_RUNNING = true
    Events.OnTick.Add(ticker)
end

if getPlayer() then
    start()   -- through the QA bridge: in the world already
elseif not ZEDQA_CON0_HOOKED then
    -- a game file in the mod's client folder: run once each time a game starts
    ZEDQA_CON0_HOOKED = true
    Events.OnGameStart.Add(start)
    print("ZEDQA " .. TAG .. " NOTE load loaded as a game file; it runs when a game starts")
end
