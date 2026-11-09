-- ZeDUI/tools/qa/mp_community.lua  (Nov 6 2026, QA): multiplayer Phase 5, community, on the local server. grep "ZEDQA mcom", then the
-- server's logs in %USERPROFILE%\Zomboid\zedqa_mp\Logs (*_ZeD.txt and *_DebugLog-server.txt).
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"     (the shim carries ZeDQA.role)
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_community.txt
-- The test client joins as admin (a -debug client must). ZeDQA.role changes the role the server part reads and leaves the connection's,
-- so every perm test here is the server's own. ZeDQA.nolimits clears this player's rate limits.
-- Steps that need more than this bridge are printed as TODO lines: a second player, a real quit and rejoin, a kick, a ban, a restart with
-- /save, a controller. community_sim.lua and community_cards_sim.lua prove their logic without the game. PROBE lines are what only the
-- game can settle (MP_SERVER_PART_DESIGN.md, the last section).
local function say(s) print("ZEDQA mcom " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local Cm, S, M, K = ZeD.Cm, ZeD.ServerPart, ZeD.Community, ZeD.Tickets

-- every message the server part sends this client
local got = {}
local function tap(module, command, args)
    if module == "ZeD" or module == "ZeDM" or module == "ZeDT" then got[#got + 1] = { m = module, c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function firstAck()
    for i = 1, #got do if got[i].c == "t_ack" then return got[i].a end end
    return nil
end
local function clear() got = {} end
local function raw(cmd, args) S.send(Cm.MOD, cmd, args or {}) end
local function role(name) sendClientCommand(p, "ZeDQA", "role", { name = name }) end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end

local function hasKey(v, name)
    if type(v) ~= "table" then return false end
    for k, x in pairs(v) do
        if k == name or hasKey(x, name) then return true end
    end
    return false
end

-- ModData.request of the obvious name
local modReply = nil
local function onMod(tag, tbl) if tag == "ZeD_Community" then modReply = tbl end end
Events.OnReceiveGlobalModData.Add(onMod)

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local base = 0

local function rulesOf(...)
    local t = { n = 0 }
    for k, s in ipairs({ ... }) do
        t[k] = { text = s }
        t.n = k
    end
    return t
end

-- ---------------------------------------------------------------------------
-- THE LINK AND THE TABLE
-- ---------------------------------------------------------------------------
add(1500, function()
    pass("the server part says community is here", S.cm == true, S.cm)
    pass("the model reads as live", M.live())
    pass("an admin's view has the ticks", M.view and M.view.edit ~= nil)
    base = (M.view and M.view.edit and M.view.edit.base) or 0
    say("view: " .. tostring(M.view and M.view.rules.n) .. " rules, revision " .. tostring(M.view and M.view.rev) .. ", base " .. tostring(base))
    ModData.request("ZeD_Community")
end)
add(1500, function()
    pass("ModData.request of ZeD_Community gives nothing", modReply == false or modReply == nil, tostring(modReply))
    local names = ModData.getTableNames()
    local leak = false
    for k = 0, names:size() - 1 do if tostring(names:get(k)):find("ZeD_CM_", 1, true) then leak = true end end
    pass("no community table on this client", not leak)
    say("TODO /save, stop, start: the same table, the same revision. Grep the server's logs for ZeD_CM_: nothing")
    role("user")
end)

-- ---------------------------------------------------------------------------
-- AS A PLAIN PLAYER
-- ---------------------------------------------------------------------------
add(800, function() clear(); nolimits(); raw("m_save", { motd = "x", appeal = "", rules = rulesOf(), base = base }) end)
add(800, function()
    local a = firstAck()
    pass("a plain player cannot save", a and a.ok == false and a.err == "perm", a and a.err)
    clear()
    nolimits()
    raw("m_post", { text = "x" })
end)
add(800, function()
    local a = firstAck()
    pass("a plain player cannot post", a and a.ok == false and a.err == "perm", a and a.err)
    clear()
    nolimits()
    raw("m_get", {})
end)
add(800, function()
    local v = last("m_view")
    pass("m_get answers a plain player", v ~= nil)
    pass("with no ticks", v and not hasKey(v, "edit"))
    pass("and nobody's agreement", v and not hasKey(v, "agreed"))
    role("admin")
end)

-- ---------------------------------------------------------------------------
-- WRITING
-- ---------------------------------------------------------------------------
add(800, function()
    clear()
    nolimits()
    M.save({ motd = "QA: the message of the day", appeal = "discord.gg/zedqa", ask = true, reask = true, base = base, rules = rulesOf("Be decent in chat.", "Leave roads clear.") }, function(a)
        say("save: " .. tostring(a.ok) .. " " .. tostring(a.err))
    end)
end)
add(1000, function()
    local v = last("m_view")
    pass("the save comes back to everyone", v and v.motd == "QA: the message of the day" and v.rules.n == 2)
    pass("the appeal line is there", v and v.appeal == "discord.gg/zedqa")
    pass("and is kept on this computer", M.kept(M.serverKey()) == "discord.gg/zedqa", M.kept(M.serverKey()))
    say("PROBE the key the appeal line is kept under, which the connect screen must match: " .. tostring(M.serverKey()))
    clear()
    nolimits()
    raw("m_save", { motd = string.rep("x", 700), appeal = "", rules = rulesOf(), base = v and v.edit and v.edit.base })
end)
add(800, function()
    local a = firstAck()
    pass("too long is refused", a and a.err == "text", a and a.err)
    clear()
    nolimits()
    raw("m_post", { text = "QA: a pinned post", pin = true })
end)
add(800, function()
    local v = last("m_view")
    pass("posted", v and v.news.n >= 1 and v.news[1].text == "QA: a pinned post" and v.news[1].pin == true)
    pass("in the server's name for the poster", v and v.news[1].by == me, v and v.news[1].by)
    clear()
    nolimits()
    raw("m_pin", { id = v and v.news[1].id, on = false })
end)
add(800, function()
    local v = last("m_view")
    pass("unpinned", v and v.news[1].pin == false)
    clear()
    nolimits()
    raw("m_del", { id = v and v.news[1].id })
end)
add(800, function()
    local a = firstAck()
    pass("deleted", a and a.ok == true)
    say("TODO grep the ZeD log: 'community | rules saved | " .. me .. "', 'news posted', 'news unpinned', 'news deleted', each seven fields")
end)

-- ---------------------------------------------------------------------------
-- BEING ASKED
-- ---------------------------------------------------------------------------
add(800, function()
    clear()
    nolimits()
    S.hello()
end)
add(1000, function()
    local h = last("hello")
    pass("the hello asks", h and h.cm and h.cm.ask == true)
    pass("nothing is NEW the first time", h and h.cm and #Cm.newRules(h.cm) == 0)
    M.joined = nil
    M.askAt = getTimestampMs()
end)
add(1200, function()
    pass("the join screen is up", ZeD.CommunityCards.joinWin ~= nil)
    pcall(function() getCore():TakeFullScreenshot("mcom_join.png") end)
end)
add(800, function()
    local w = ZeD.CommunityCards.joinWin
    if w then w:press("agree") end
end)
add(1000, function()
    pass("I agree closes it", ZeD.CommunityCards.joinWin == nil)
    local v = last("m_view")
    pass("the server took it", v and not v.ask, v and tostring(v.ask))
    say("PROBE with the screen up: WASD still walks (only a focused text box stops GameKeyboard.isKeyDown), I, T and Esc do nothing (doKeyPress)")
    say("PROBE the pad: Up and Down scroll, Left and Right pick, A presses, Y and the bumpers do nothing")
    say("TODO Leave, on a second client: it disconnects, nothing is recorded")
    say("TODO change a rule, quit, rejoin: the rule is marked NEW, the foot says which")
    say("TODO stop the server's part with the screen up (mp_server.ps1 -Stop): the game's disconnect screen, Exit and Quit reachable")
    clear()
    nolimits()
    local r = { who = "qa_griefer", n = 2, { who = "qa_griefer", text = "lol nope", t = "9:32", mark = true }, { who = me, text = "hey", t = "9:33" } }
    K.ask("GRIEF", false, "QA: a report from chat", function(a) say("report: " .. tostring(a.ok) .. " " .. tostring(a.err) .. " #" .. tostring(a.id)) end, r)
end)
add(1200, function()
    local a = firstAck()
    pass("a report from chat is filed", a and a.ok == true, a and a.err)
    pass("the game's ticket holds no name", a and a.file and not a.file:find("qa_griefer", 1, true), a and a.file)
    say("TODO open it from the Admin tab: Reported, Player card, the chat, whose chat it is")
end)

-- ---------------------------------------------------------------------------
-- WHAT ONLY THE GAME CAN SAY
-- ---------------------------------------------------------------------------
add(500, function()
    say("TODO /kickuser on a second client: the game's words, and the appeal line under them")
    say("TODO a timed ban on a second client: the reason and the appeal line on the ban screen, then the connect screen's refusal with the line")
    say("TODO a permanent ban: reconnect: the connect screen shows the kept line")
    say("TODO chat: pick a line with a second player: Report, Mute, Unmute; relog: the mute is kept. Admin: Player card, Teleport")
    Events.OnServerCommand.Remove(tap)
    Events.OnReceiveGlobalModData.Remove(onMod)
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
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
