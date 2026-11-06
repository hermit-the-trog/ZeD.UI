-- ZeDUI/tools/qa/mp_tk_a.lua  (Nov 5 2026, QA): Part D steps 3 to 7 and 11 that mp_tickets.lua leaves as TODO or does not reach, on one client: every
-- refused transition, the director's reply ruling, find and hostile queue args, the two limits, a demotion under an open card, someone else's ticket, a forged
-- answer, a real filing against the staff modal, a removal on the game's window as admin and as moderator, the forged log line, E5, E6, E11, /reloadlua.
-- grep "ZEDQA mta". Needs the server started with -Mods "ZeD_UI;ZeDQAShim".
local function say(s) print("ZEDQA mta " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local Tk, S, K = ZeD.Tk, ZeD.ServerPart, ZeD.Tickets

local got = {}
local function tap(module, command, args)
    if module == "ZeD" or module == "ZeDT" or module == "ZeDQA" then got[#got + 1] = { m = module, c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function count(cmd)
    local n = 0
    for _, m in ipairs(got) do if m.c == cmd then n = n + 1 end end
    return n
end
local function clear() got = {} end
local function raw(cmd, args) S.send("ZeDT", cmd, args or {}) end
local function role(name) sendClientCommand(p, "ZeDQA", "role", { name = name }) end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local function st() return K.card and K.card.status end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

-- the game row of a ticket, from the last full list
local function gameOf(id)
    for _, r in ipairs(K.list and K.list.rows or {}) do
        local _, n = Tk.parse(r.m)
        if n == id then return r.g end
    end
    return nil
end
local function file(kind, text, into)
    add(300, function() nolimits() end)
    add(600, function()
        clear()
        K.ask(kind, false, text, function(a) _G[into] = a and a.id end)
    end)
end

add(1000, function() nolimits(); S.hello() end)
add(1000, function() pass("staff at the start", S.staff == true and S.admin == true); K.openQueue({ status = "All" }) end)
add(2000, function() nolimits() end)

-- ---------------------------------------------------------------------------
-- every transition and every refusal (B4 as built, with the director's ruling)
-- ---------------------------------------------------------------------------
file("BUG", "qa: transitions", "T1")
add(1500, function() pass("filed", T1 ~= nil, T1); K.openCard(T1) end)
add(1000, function() pass("the card opens, Seen", st() == "Seen", st()) end)
local WALK = {
    { "t_reopen", "state", "Seen" }, { "t_unspam", "state", "Seen" }, { "t_close", nil, "Closed" }, { "t_close", "state", "Closed" },
    { "t_take", "state", "Closed" }, { "t_answer", "state", "Closed" }, { "t_addnote", nil, "Closed" }, { "t_reopen", nil, "Progress" },
    { "t_take", nil, "Progress" }, { "t_answer", nil, "Answered" }, { "t_answer", nil, "Answered" }, { "t_close", nil, "Closed" },
    { "t_reopen", nil, "Progress" }, { "t_spam", nil, "Spam" }, { "t_spam", "state", "Spam" }, { "t_take", "state", "Spam" },
    { "t_answer", "state", "Spam" }, { "t_close", "state", "Spam" }, { "t_reopen", "state", "Spam" }, { "t_unspam", nil, "Open" },
}
for n, w in ipairs(WALK) do
    add(250, function() nolimits() end)
    add(350, function() clear(); raw(w[1], { id = T1, text = "qa: walk " .. n, rid = 100 + n }) end)
    add(450, function()
        local a = last("t_ack")
        pass("walk " .. n .. " " .. w[1] .. (w[2] and " refused" or "") .. ", then " .. w[3],
            a and a.err == w[2] and (a.ok == (w[2] == nil)) and st() == w[3], tostring(a and a.err) .. ", " .. tostring(st()))
    end)
end

-- ---------------------------------------------------------------------------
-- the director's ruling: a reply stays open at Answered, and puts the ticket back to In progress
-- ---------------------------------------------------------------------------
add(300, function() nolimits(); raw("t_answer", { id = T1, text = "qa: an answer", rid = 200 }) end)
add(600, function() pass("Answered", st() == "Answered", st()); role("user") end)
add(600, function() nolimits() end)
add(300, function() clear(); raw("t_reply", { id = T1, text = "qa: a follow-up after the answer", rid = 201 }) end)
add(800, function()
    pass("a player's reply on an answered ticket is taken", last("t_ack") and last("t_ack").ok == true, last("t_ack") and last("t_ack").err)
    pass("the player reads In progress", last("t_one") and last("t_one").st == "Progress", last("t_one") and last("t_one").st)
    pass("still may add to it", last("t_one") and last("t_one").can == true)
    role("admin")
end)
add(600, function() nolimits(); raw("t_close", { id = T1, rid = 202 }) end)
add(600, function() role("user") end)
add(600, function() nolimits() end)
add(300, function() clear(); raw("t_reply", { id = T1, text = "qa: on a closed ticket", rid = 203 }) end)
add(600, function()
    pass("a reply on Closed answers state", last("t_ack") and last("t_ack").err == "state", last("t_ack") and last("t_ack").err)
    role("admin")
end)
add(600, function() nolimits(); raw("t_spam", { id = T1, rid = 204 }) end)
add(600, function() role("user") end)
add(600, function() nolimits() end)
add(300, function() clear(); raw("t_reply", { id = T1, text = "qa: on a spammed ticket", rid = 205 }) end)
add(600, function()
    pass("a reply on Spam answers state", last("t_ack") and last("t_ack").err == "state", last("t_ack") and last("t_ack").err)
    role("admin")
end)
add(600, function() nolimits(); raw("t_unspam", { id = T1, rid = 206 }) end)
add(600, function() nolimits() end)

-- ---------------------------------------------------------------------------
-- hostile queue arguments
-- ---------------------------------------------------------------------------
local QUEUEARGS = {
    { find = "%[", rid = 300 }, { find = string.rep("x", 200), rid = 301 }, { status = "bogus", rid = 302 }, { kind = "bogus", rid = 303 },
    { page = -1, rid = 304 }, { page = "a", rid = 305 }, { who = { 1 }, rid = 306 }, { mine = "yes", newest = 12, rid = 307 },
}
for n, q in ipairs(QUEUEARGS) do
    add(1100, function() clear(); nolimits(); raw("t_queue", q) end)
    add(900, function()
        local a, r = last("t_ack"), last("t_queue")
        say("queue args " .. n .. ": ack " .. tostring(a and a.ok) .. " " .. tostring(a and a.err) .. ", page " .. tostring(r and r.n))
        pass("queue args " .. n .. " answered", a ~= nil or r ~= nil)
    end)
end

-- ---------------------------------------------------------------------------
-- the two limits, with no nolimits
-- ---------------------------------------------------------------------------
add(300, function() role("user") end)
add(800, function() say("LOG MARK perm flood starts") end)
for n = 1, 8 do add(650, function() raw("t_queue", { rid = 400 + n }) end) end
add(800, function() say("LOG MARK perm flood ends") end)
add(5500, function()
    clear()
    for n = 1, 25 do raw("t_one", { id = T1, rid = 500 + n }) end
end)
add(1500, function()
    pass("past 10 in 5 s the rest are dropped with no reply", count("t_ack") <= 10 and count("t_ack") >= 8, count("t_ack"))
    role("admin")
end)
add(5500, function() nolimits(); S.hello() end)

-- ---------------------------------------------------------------------------
-- a demotion under an open card: no more pushes reach it
-- ---------------------------------------------------------------------------
add(800, function() raw("t_reopen", { id = T1, rid = 600 }); K.openCard(T1) end)
add(800, function() role("user") end)
add(600, function() clear(); nolimits() end)
add(300, function() raw("t_reply", { id = T1, text = "qa: pushes after a demotion", rid = 601 }) end)
add(1000, function()
    pass("a player's reply went in", last("t_ack") and last("t_ack").ok == true)
    pass("the demoted client's open card got no push", count("t_card") == 0, count("t_card"))
    local staffRows = 0
    for _, m in ipairs(got) do if m.c == "t_row" and not m.a.pv then staffRows = staffRows + 1 end end
    pass("and no staff row", staffRows == 0, staffRows)
    role("admin")
end)
add(800, function() nolimits(); K.closeCard() end)

-- ---------------------------------------------------------------------------
-- someone else's ticket: the same answer as one that does not exist
-- ---------------------------------------------------------------------------
add(300, function()
    addTicket("qa_other", "qa: someone else's words", -1)
    K.closeQueue()
    K.openQueue({ status = "All" })
end)
add(6000, function()
    local found = nil
    for _, r in ipairs(K.queue and K.queue.rows or {}) do if r.author == "qa_other" then found = r end end
    pass("an adopted ticket shows in the queue without a second open", found ~= nil, K.queue and K.queue.n)
    K.closeQueue()
    nolimits()
    K.openQueue({ status = "All" })
end)
add(3000, function()
    for _, r in ipairs(K.queue and K.queue.rows or {}) do if r.author == "qa_other" then OTHER = r.id end end
    pass("no kind, by the game's window", OTHER ~= nil, OTHER)
    role("user")
end)
add(600, function() clear(); nolimits() end)
add(300, function() raw("t_one", { id = OTHER, rid = 700 }) end)
add(600, function()
    local a = last("t_ack")
    pass("t_one of someone else's answers gone", a and a.err == "gone" and last("t_one") == nil, a and a.err)
    clear()
    raw("t_one", { id = 99999, rid = 701 })
end)
add(600, function()
    pass("the same as one that does not exist", last("t_ack") and last("t_ack").err == "gone")
    role("admin")
end)

-- ---------------------------------------------------------------------------
-- a forged answer on an unviewed ticket: notes, and the ticket stays Open
-- ---------------------------------------------------------------------------
file("QUESTION", "qa: to be answered by a forger", "T2")
add(5000, function()
    pass("second ticket", T2 ~= nil, T2)
    K.closeQueue()
    nolimits()
    K.openQueue({ status = "Open" })
end)
add(4000, function()
    G2 = gameOf(T2)
    pass("its game row", G2 ~= nil, G2)
    role("user")
end)
add(600, function() addTicket(me, "qa: a forged answer", G2) end)
add(800, function() role("admin") end)
add(800, function() nolimits(); K.closeQueue(); K.openQueue({ status = "Open" }) end)
add(5000, function() nolimits(); K.closeQueue(); K.openQueue({ status = "Open" }) end)
add(4000, function()
    local row
    for _, r in ipairs(K.queue and K.queue.rows or {}) do if r.id == T2 then row = r end end
    pass("the forged answer leaves it Open", row and row.st == "Open", row and row.st)
    nolimits()
    K.openCard(T2)
end)
add(1200, function()
    local c = K.card
    local inNotes, inThread = false, false
    for k = 1, (c and c.notes and c.notes.n or 0) do if tostring(c.notes[k].text):find("forged", 1, true) then inNotes = c.notes[k].game == true end end
    for k = 1, (c and c.thread and c.thread.n or 0) do if tostring(c.thread[k].text):find("forged", 1, true) then inThread = true end end
    pass("the forged answer is a labeled note", inNotes)
    pass("and not in the thread", not inThread)
    K.closeCard()
end)

-- ---------------------------------------------------------------------------
-- a real filing against the staff modal
-- ---------------------------------------------------------------------------
local fired = 0
local function onAdmin() fired = fired + 1 end
add(500, function()
    Events.OnAdminMessage.Add(onAdmin)
    MODALS = #ISAdminMessage.messages
end)
file("STUCK", "qa: a real filing with staff online", "T3")
add(2500, function()
    Events.OnAdminMessage.Remove(onAdmin)
    pass("the server's message came", fired >= 1, fired)
    pass("no game modal for a ticket", #ISAdminMessage.messages == MODALS, #ISAdminMessage.messages - MODALS)
end)

-- ---------------------------------------------------------------------------
-- removed on the game's window, as an admin, then as a moderator
-- ---------------------------------------------------------------------------
add(300, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
add(4000, function()
    G3 = gameOf(T3)
    pass("linked, the third", G3 ~= nil, G3)
    removeTicket(G3)
    nolimits()
    K.closeQueue()
    K.openQueue({ status = "All" })
end)
add(11500, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
add(14000, function() nolimits(); K.openCard(T3) end)
add(1000, function()
    pass("the record stays and reads Removed", K.card and K.card.id == T3 and K.card.gameGone == true, K.card and tostring(K.card.gameGone))
    K.closeCard()
    role("user")
end)
add(600, function() clear(); nolimits() end)
add(5500, function() raw("t_mine", { rid = 800 }) end)
add(800, function()
    local row
    for _, r in ipairs(last("t_mine") and last("t_mine").rows or {}) do if r.id == T3 then row = r end end
    pass("its author's list still has it", row ~= nil)
    pass("and offers nothing to file again", row and row.file == nil)
    role("moderator")
end)
file("OTHER", "qa: removed as a moderator", "T4")
add(4000, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
add(4000, function()
    G4 = gameOf(T4)
    pass("linked, the fourth", G4 ~= nil, G4)
    removeTicket(G4)
    nolimits()
    K.closeQueue()
    K.openQueue({ status = "All" })
end)
add(11500, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
add(14000, function() nolimits(); K.openCard(T4) end)
add(1000, function()
    pass("a moderator's Remove does not delete", K.card and K.card.id == T4 and K.card.gameGone == true, K.card and tostring(K.card.gameGone))
    K.closeCard()
    role("admin")
end)
add(800, function() nolimits(); K.openCard(T1) end)
add(1000, function()
    pass("own filings marked nothing gone", K.card and K.card.gameGone == nil, K.card and tostring(K.card.gameGone))
    K.closeCard()
end)

-- ---------------------------------------------------------------------------
-- the forged log line, E5, E6
-- ---------------------------------------------------------------------------
add(500, function()
    sendClientCommand(p, "ISLogSystem", "writeLog", { loggerName = "ZeD", logText = "qa: forged through ISLogSystem" })
    sendClientCommand(p, "ISLogSystem", "writeLog", { loggerName = " zed ", logText = "qa: forged, spaced name" })
    sendClientCommand(p, "ISLogSystem", "writeLog", { loggerName = "qa_control", logText = "qa: the channel works" })
    say("E5: os.date " .. tostring(os.date("%H:%M", getTimestamp())) .. " with no zone, utc " .. tostring(os.date("!%H:%M", getTimestamp())))
    local c = Calendar and Calendar.getInstance and Calendar.getInstance()
    say("E5: os.date no arg " .. tostring(os.date("%H:%M")))
end)
add(1000, function()
    clear()
    for n = 1, 200 do S.hello() end
    say("E6: 200 hello in one frame")
end)
add(6000, function()
    pass("E6: not kicked", isClient() and getPlayer() ~= nil)
    pass("E6: one hello answered", count("hello") <= 2, count("hello"))
    role("user")
end)

-- ---------------------------------------------------------------------------
-- E11: a full card
-- ---------------------------------------------------------------------------
file("BUG", "qa: a full card", "T5")
add(1500, function() pass("fifth", T5 ~= nil, T5) end)
for n = 1, 39 do
    add(250, function() nolimits() end)
    add(250, function() raw("t_reply", { id = T5, text = string.format("%02d ", n) .. string.rep("m", 997), rid = 900 + n }) end)
end
add(800, function() nolimits() end)
add(300, function() clear(); raw("t_reply", { id = T5, text = "qa: the 41st", rid = 960 }) end)
add(700, function()
    pass("a thread stops at 40", last("t_ack") and last("t_ack").err == "full", last("t_ack") and last("t_ack").err)
    role("admin")
end)
for n = 1, 20 do
    add(250, function() nolimits() end)
    add(250, function() raw("t_addnote", { id = T5, text = string.format("%02d ", n) .. string.rep("n", 997), rid = 1000 + n }) end)
end
add(800, function() nolimits() end)
add(300, function() clear(); raw("t_addnote", { id = T5, text = "qa: the 21st", rid = 1030 }) end)
add(800, function()
    pass("notes stop at 20", last("t_ack") and last("t_ack").err == "full", last("t_ack") and last("t_ack").err)
    K.closeCard()
    nolimits()
end)
add(500, function()
    clear()
    CARD_AT = getTimestampMs()
    K.openCard(T5)
end)
add(2000, function()
    local c = K.card
    pass("E11: the full card arrives", c and c.id == T5 and c.thread.n == 40 and c.notes.n == 20, c and (tostring(c.thread.n) .. " + " .. tostring(c.notes.n)))
    pass("E11: the last line whole", c and #tostring(c.thread[40].text) == 1000, c and #tostring(c.thread[40].text))
    K.closeCard()
end)

-- ---------------------------------------------------------------------------
-- /reloadlua of both server files: one reply per command, the table open
-- ---------------------------------------------------------------------------
local function reload(name)
    add(500, function() SendCommandToServer('/reloadlua "' .. name .. '"') end)
    add(2500, function() nolimits() end)
    add(300, function() clear(); raw("t_one", { id = T1, rid = 1100 }) end)
    add(800, function()
        pass("after reload of " .. name .. ": one t_one", count("t_one") == 1, count("t_one"))
        pass("after reload of " .. name .. ": one ack", count("t_ack") == 1, count("t_ack"))
        nolimits()
        clear()
        S.hello()
    end)
    add(900, function()
        pass("after reload of " .. name .. ": one hello", count("hello") == 1, count("hello"))
        local h = last("hello")
        pass("after reload of " .. name .. ": still staff", h and h.staff == true and h.frozen ~= true)
        nolimits()
        K.openCard(T5)
    end)
    add(900, function() pass("after reload of " .. name .. ": the table is still there", K.card and K.card.thread.n == 40); K.closeCard() end)
end
reload("ZeD_ServerTickets.lua")
reload("ZeD_ServerCore.lua")

add(500, function()
    K.closeCard()
    K.closeQueue()
    Events.OnServerCommand.Remove(tap)
    say("DONE")
end)

local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < stp.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(stp.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
