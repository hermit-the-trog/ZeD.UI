-- ZeDUI/tools/qa/mp_admin.lua  (Nov 5 2026, QA): multiplayer Phase 2, the admin tools against the real server part on the
-- local server. grep "ZEDQA mad", then the server's logs in C:\Users\you\Zomboid\zedqa_mp\Logs (*_DebugLog-server.txt and
-- *_ZeD.txt).
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"     (the shim carries ZeDQA.role)
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_admin.txt
-- The test client joins as admin (a -debug client must). ZeDQA.role changes the role the server part reads and leaves the
-- connection's, so every perm test here is the server's own. ZeDQA.nolimits clears this player's rate limits.
-- This run proves the Java calls the sims can only stub: getRoles and its positions, a card read from a live player
-- (profession, traits, every perk), Level Up through /addxp, items into the inventory and onto the ground, the secret
-- table, OnTickEvenPaused. Steps that need more than one client are printed as TODO lines: admin_sim.lua proves their logic.
local function say(s) print("ZEDQA mad " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local Adm, S, M, K = ZeD.Adm, ZeD.ServerPart, ZeD.Admin, ZeD.Tickets

local got = {}
local function tap(module, command, args)
    if module == "ZeDA" or module == "ZeDT" or module == "ZeDQA" or module == "ZeD" then got[#got + 1] = { m = module, c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function clear() got = {} end
local function raw(cmd, args) S.send("ZeDA", cmd, args or {}) end
local function role(name) sendClientCommand(p, "ZeDQA", "role", { name = name }) end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local function keysOf(v, out)
    out = out or {}
    if type(v) == "table" then
        for k, x in pairs(v) do
            out[tostring(k)] = true
            keysOf(x, out)
        end
    end
    return out
end
local function count(item)
    local n = 0
    local list = p:getInventory():getItems()
    for i = 0, list:size() - 1 do
        if list:get(i):getFullType() == item then n = n + 1 end
    end
    return n
end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

add(1500, function()
    pass("the tools are here", S.adm == true and M.live(), S.adm)
    local names = ModData.getTableNames()
    local leak = false
    for k = 0, names:size() - 1 do if tostring(names:get(k)):find("ZeD_AD_", 1, true) then leak = true end end
    pass("no admin table on this client", not leak)
    pass("the game's roles read", #M.roles() >= 5, #M.roles())
    pass("every capability has a group", (function()
        for _, c in ipairs(M.allCaps()) do
            if not Adm.CAP_GROUP[c] then return false end
        end
        return true
    end)())
    say("why, for a role without Ban: " .. tostring(M.why("BanUnbanUser")))
    clear()
    raw("a_players")
end)
add(1200, function()
    local a = last("a_players")
    pass("a_players answers", a ~= nil and a.rows ~= nil)
    pass("I am on it, online", a and a.rows[1] and a.rows[1].on == true)
    clear()
    raw("a_card", { user = me })
end)
add(1200, function()
    local a = last("a_card")
    pass("a live card", a ~= nil and a.on == true and a.x ~= nil)
    pass("profession from the server", a and type(a.prof) == "string", a and a.prof)
    pass("every skill from the server", a and a.skills and #a.skills > 20, a and a.skills and #a.skills)
    say("card keys: " .. (function()
        local o = {}
        for k in pairs(keysOf(a)) do o[#o + 1] = k end
        table.sort(o)
        return table.concat(o, " ")
    end)())
    clear()
end)

-- as a plain player
add(500, function() role("user") end)
add(1200, function()
    nolimits()
    raw("a_ban", { target = "Nobody", reason = "x", len = "d1", rid = 7001 })
end)
add(1200, function()
    local a = last("t_ack")
    pass("a plain player: a_ban answers perm", a and a.err == "perm", a and a.err)
    nolimits()
    raw("a_spawn", { item = "Base.Axe", n = 1, to = "me", rid = 7002 })
end)
add(1200, function()
    local a = last("t_ack")
    pass("a plain player: a_spawn answers perm", a and a.err == "perm", a and a.err)
    role("moderator")
end)
add(1200, function()
    nolimits()
    raw("a_rolelog", { what = "save", role = "gm", rid = 7003 })
end)
add(1200, function()
    local a = last("t_ack")
    pass("a moderator: roles answer perm", a and a.err == "perm", a and a.err)
    role("admin")
end)

-- hostile arguments: one bad line each
add(1200, function()
    nolimits()
    raw("a_card", { user = { 1 }, rid = 7004 })
    raw("a_spawn", { item = "Base/../x", n = 1, to = "me", rid = 7005 })
    raw("a_kick", { user = 5, reason = "x", rid = 7006 })
    raw("a_ban", { target = { 1 }, reason = "x", len = "ever", rid = 7007 })
    raw("a_repeat", { text = "x", every = 7, rid = 7008 })
end)

-- the Java calls
local before = 0
add(1500, function()
    nolimits()
    before = count("Base.Axe")
    M.spawn("Base.Axe", 3, "me", function(a) pass("spawn to me acks", a.ok == true, a.err) end)
end)
add(1500, function()
    pass("three axes arrive", count("Base.Axe") == before + 3, count("Base.Axe"))
    nolimits()
    M.spawn("Base.Axe", 2, "ground", function(a) pass("spawn to the ground acks", a.ok == true, a.err) end)
end)
add(1500, function()
    local sq = p:getCurrentSquare()
    local list = sq and sq:getWorldObjects()
    pass("items on the ground", list and list:size() >= 2, list and list:size())
    say("TODO spawn to another player: a second client")
    nolimits()
    M.skill(me, "Woodwork", 1, function(a) pass("Level Up acks", a.ok == true and type(a.amount) == "number", a.amount) end)
end)
local level = 0
add(2000, function()
    level = p:getPerkLevel(Perks.Woodwork)
    say("Woodwork after Level Up: " .. tostring(level))
    nolimits()
    M.skill(me, "Woodwork", -1, function(a) pass("Level Down acks", a.ok == true, a.amount) end)
end)
add(2000, function()
    pass("Level Down lands", p:getPerkLevel(Perks.Woodwork) == level - 1, p:getPerkLevel(Perks.Woodwork))
end)

-- bans on a name nobody holds: the list, the timer, the unban
add(500, function()
    nolimits()
    clear()
    M.banTyped("zedqa_ghost", "QA run", "h1", function(a) pass("a timed ban on a name never seen is refused", a.ok == false and a.err == "unknown", a.err) end)
    nolimits()
    M.banTyped("76561198000000123", "QA run", "h1", function(a) pass("a timed ban acks", a.ok == true and a.untilT ~= nil, a.err) end)
end)
add(1500, function()
    pass("it is on the list", #M.bans >= 1 and M.bans[1].sid == "76561198000000123")
    nolimits()
    M.banTyped("zedqa_ghost2", "QA run", "perm", function(a) pass("a permanent ban acks", a.ok == true, a.err) end)
end)
add(2500, function()
    pass("the owed ban arrived", last("a_owed") ~= nil and last("a_owed").act == "Ban", last("a_owed") and last("a_owed").act)
    say("TODO the game's user list shows zedqa_ghost2 banned, if the account exists; the server's log says so")
    nolimits()
    for _, b in ipairs(M.bans) do
        local row = b
        M.unban(row)
    end
end)
add(2500, function()
    pass("the list is empty again", #M.bans == 0, #M.bans)
    say("TODO a player kicked, banned for a time, the reason on their screen, and the client that stays: a second client (mp_client2.ps1)")
    say("TODO lifted with nobody on (E8): ban a name for 1 hour, leave the server empty, /quit nothing; set the clock forward or wait, read the ZeD log for 'ban lifted'")
end)

-- a repeat
add(500, function()
    nolimits()
    M.message("ZeD QA repeat", 15, function(a) pass("a repeat acks", a.ok == true, a.err) end)
end)
add(1500, function()
    pass("the Stop list has it", #M.repeats == 1, #M.repeats)
    nolimits()
    M.stop(M.repeats[1] and M.repeats[1].id or 0, function(a) pass("Stop acks", a.ok == true, a.err) end)
end)
add(1500, function()
    pass("the Stop list is empty", #M.repeats == 0, #M.repeats)
    say("TODO the repeat's line after 15 minutes: leave it running once")
    say("TODO /save, stop, start: the same admin table. Grep the server's logs for ZeD_AD_: nothing")
    say("TODO grep *_ZeD.txt: 'admin spawn', 'admin ban', 'admin unban', 'admin level up', 'admin repeating message'")
    role("admin")
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then
        Events.OnTick.Remove(drive)
        return
    end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs()
    i = i + 1
    local ok, err = pcall(st.fn)
    if not ok then say("FAIL step " .. tostring(i - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(drive)
