-- ZeDUI/tools/qa/mp_log.lua  (Nov 6 2026, QA): multiplayer Phase 4, logs and accountability, on the local server. grep "ZEDQA mlg",
-- then the server's logs in C:\Users\danie\Zomboid\zedqa_mp\Logs (*_ZeD.txt: seven fields on every line).
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"     (the shim carries ZeDQA.role)
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_log.txt
-- PROBE lines are what the code could not settle: read them against MP_SERVER_PART_DESIGN.md's last section. The first is E2: a
-- window is smashed on a car spawned beside the character, and the probe says whether the class's complete was reached or the
-- .new fallback had to go on. What needs a second player (a real PvP hit, a kill, someone else driving off) prints as TODO:
-- log_sim.lua proves their logic without the game. mp_log_cards.lua takes the pictures. The test client joins as admin; ZeDQA.role
-- makes it a plain user for the refused steps.
local function say(s) print("ZEDQA mlg " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local Lg, Lm, S, Tk, K = ZeD.Lg, ZeD.Logs, ZeD.ServerPart, ZeD.Tk, ZeD.Tickets

local got = {}
local function tap(module, command, args)
    if module == Lg.MOD or module == Tk.MOD then got[#got + 1] = { c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function clear() got = {} end
local function raw(cmd, args) S.send(Lg.MOD, cmd, args or {}) end
local function role(name) sendClientCommand(p, "ZeDQA", "role", { name = name }) end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local function rowsWith(a, what)
    local out = {}
    for _, r in ipairs(a and a.rows or {}) do
        if r.what == what then out[#out + 1] = r end
    end
    return out
end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

-- ---------------------------------------------------------------------------
-- THE LINK, THE READ
-- ---------------------------------------------------------------------------
add(1500, function()
    pass("hello says the log is here", S.lg == true)
    pass("the log reads as live", Lm.live())
    clear()
    nolimits()
    raw("l_query", { when = "d3" })
end)
add(1000, function()
    local a = last("l_page")
    pass("a read answers", a ~= nil)
    say("PROBE lines on the log at the start: " .. tostring(a and a.all))
    pass("the first page holds names", a and a.names ~= nil)
    for _, bad in ipairs({ { kind = "nope" }, { when = 3 }, { who = { 1 } }, { find = { 1 } }, { page = -1 }, { around = 1.5 } }) do
        nolimits()
        raw("l_query", bad)
    end
    raw("l_query", { find = "%[" })
end)
add(1200, function()
    pass("a Find that looks like a pattern is words", last("l_page") ~= nil)
    say("grep the ZeD log for 'bad arguments': one line each, a few a minute. 'handler failed' must not appear")
    role("user")
end)
add(800, function()
    clear()
    nolimits()
    S.send(Lg.MOD, "l_query", { rid = 7 })
    S.send(Lg.MOD, "l_probe", { rid = 8 })
    S.send(Lg.MOD, "l_tonote", { rid = 9, id = 1, s = 1 })
end)
add(800, function()
    local n = 0
    for _, e in ipairs(got) do if e.c == "t_ack" and e.a.err == "perm" then n = n + 1 end end
    pass("as a plain user, all three answer perm", n == 3, n)
    pass("and no page came", last("l_page") == nil and last("l_probe") == nil)
    role("admin")
end)

-- ---------------------------------------------------------------------------
-- OTHER MODS' LINES: the tap, and what a client can't do
-- ---------------------------------------------------------------------------
add(800, function()
    local x, y = math.floor(p:getX()), math.floor(p:getY())
    ISLogSystem.sendLog(p, "ZedQaTap", "[1][ISQaThing][" .. me .. "][" .. x .. "," .. y .. ",0][hello]")
    ISLogSystem.sendLog(p, "ZeD", "ticket | filed | forged | #1 | 1,1,0 | GRIEF | day 1")
    ISLogSystem.sendLog(p, "Z.e-D", "forged again")
    nolimits()
end)
add(1000, function()
    clear()
    raw("l_query", { when = "hour", find = "ISQaThing" })
end)
add(800, function()
    local a = last("l_page")
    local r = a and a.rows and a.rows[1]
    pass("the tap took a client's line", r ~= nil and r.src == "tap" and r.lg == "ZedQaTap")
    pass("it names who sent it", r ~= nil and r.by == me, r and r.by)
    say("PROBE tapped line: " .. tostring(r and Lm.metaText(r)))
    say("grep the ZeD log for 'forged': it must not be there. grep *_ZedQaTap.txt: the line reached the game's own file")
    say("TODO E1: subscribe Log Extender on the QA rig, grep its Lua for writeLog, and read which of its lines land here")
end)

-- ---------------------------------------------------------------------------
-- TICKETS ON THE ONE LOG, AROUND A TICKET
-- ---------------------------------------------------------------------------
local ticketId = nil
add(800, function()
    clear()
    nolimits()
    K.ask("GRIEF", true, "qa: someone took my engine", function(a) ticketId = a.id end)
end)
add(1500, function()
    pass("a ticket went in", ticketId ~= nil, ticketId)
    clear()
    nolimits()
    raw("l_query", { kind = "ticket", when = "hour" })
end)
add(800, function()
    local list = rowsWith(last("l_page"), "filed")
    pass("the ticket's line is on the log", #list >= 1 and list[1].target == "#" .. tostring(ticketId))
    pass("with no ticket's words in it", #list >= 1 and list[1].text == "GRIEF")
    say("PROBE words: " .. tostring(list[1] and Lm.lineText(list[1])))
    clear()
    nolimits()
    raw("l_query", { around = ticketId })
end)
add(800, function()
    local a = last("l_page")
    pass("Around answers", a ~= nil and a.around ~= nil and a.around.id == ticketId)
    local r = a and a.rows and a.rows[1]
    pass("it holds the filing", r ~= nil)
    if r then
        Lm.toNote(ticketId, r.s, function(b) pass("Add to ticket", b.ok == true, b.err) end)
    end
end)
add(1200, function()
    if ticketId then K.delete(ticketId) end
end)

-- ---------------------------------------------------------------------------
-- E2: A WINDOW SMASHED ON THE SERVER, AND THE PROBE
-- ---------------------------------------------------------------------------
local car = nil
add(800, function()
    SendCommandToServer('/addvehicle "Base.CarNormal" "' .. me .. '"')
end)
add(3000, function()
    -- (the cell's vehicles are a HashSet in 42.22: no get by number)
    local it = getCell():getVehicles():iterator()
    local best = nil
    while it:hasNext() do
        local v = it:next()
        local d = v:DistTo(p)
        if d < 12 and (not best or d < best) then best, car = d, v end
    end
    if not car then
        say("TODO E2: no car came within 12 tiles: smash a window by hand on the local server, then read PROBE E2 below")
        return
    end
    local part = car:getPartById("WindowFrontLeft")
    say("PROBE car: " .. tostring(car:getScript():getName()) .. " sqlId " .. tostring(car:getSqlId()) .. ", a window part: " .. tostring(part ~= nil))
    if part then ISTimedActionQueue.add(ISSmashVehicleWindow:new(p, part)) end
end)
add(6000, function()
    clear()
    nolimits()
    raw("l_probe", {})
end)
add(800, function()
    local a = last("l_probe")
    pass("the probe answers", a ~= nil)
    local h = a and a.hooks and a.hooks.ISSmashVehicleWindow
    say("PROBE E2 ISSmashVehicleWindow: new " .. tostring(h and h.new) .. ", done " .. tostring(h and h.done) .. ", stopped " .. tostring(h and h.stop) .. ", refused " .. tostring(h and h.ref) .. ", fallback " .. tostring(h and h.fallback))
    say("PROBE E2 reads: done 1 with no fallback settles it, and stopped 1 from a cancel does too. new with done 0 and stopped 0: run it three times, two minutes apart, and the fallback must go on, and the line appear")
    say("PROBE wrapped classes missing: " .. tostring(a and a.missing and #a.missing))
    say("PROBE the game's PvP tool in server Lua: " .. tostring(a and a.hasPvp) .. ", hits read " .. tostring(a and a.pvp) .. ", weapons seen " .. tostring(a and a.weapons) .. ", kills " .. tostring(a and a.kills))
    say("PROBE tap: " .. tostring(a and a.tap) .. " lines seen, " .. tostring(a and a.tapKept) .. " kept; the clock's passes: " .. tostring(a and a.polls))
    pass("the clock runs (OnTickEvenPaused)", a and a.polls and a.polls > 0)
    clear()
    nolimits()
    raw("l_query", { kind = "vehicle", when = "hour" })
end)
add(800, function()
    local list = rowsWith(last("l_page"), "smash")
    say("PROBE a smash line: " .. tostring(list[1] and Lm.lineText(list[1])))
    say("TODO two clients: drive a car, get out, the second client starts it: 'drove off in', with the owner")
    say("TODO two clients: the running engine (first client leaves it on), the 10 second look")
    say("TODO two clients, PvP on: a hit (the game's PvP log, with its weapon if PROBE weapons rises) and a kill (OnCharacterDeath on the server, E21)")
    say("TODO a tow from the game's menu: a 'hooked up' line within 20 seconds; cancel one part way: no line")
    say("TODO cancel a siphon part way: a 'siphoned' line (PROBE E2's road, serverStop); read the tank's level drop first")
    say("TODO the server's words: Add to ticket on a vehicle line, the car's name reads as the game's (getTextOrNull on a dedicated server), or as the script name if not")
end)
add(500, function()
    Events.OnServerCommand.Remove(tap)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
