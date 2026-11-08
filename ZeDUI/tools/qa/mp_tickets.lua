-- ZeDUI/tools/qa/mp_tickets.lua  (Nov 5 2026, QA): multiplayer Phase 1, tickets, steps 1 to 7 of Part D
-- (docs/specs/MP_SERVER_PART_DESIGN.md) on the local server. grep "ZEDQA mtk", then the server's logs in
-- %USERPROFILE%\Zomboid\zedqa_mp\Logs (*_DebugLog-server.txt and *_ZeD.txt).
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"     (the shim carries ZeDQA.role)
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_tickets.txt
-- The test client joins as admin (a -debug client must). ZeDQA.role changes the role the server part reads and leaves the
-- connection's, so every perm test here is the server's own. mp_nonadmin.lua cannot stand in: it changes only the client.
-- ZeDQA.nolimits clears this player's rate limits, so a run files six tickets without waiting five minutes.
-- Steps that need more than this bridge are printed as TODO lines: a second player (step 3's nearby, E4), quitting and
-- rejoining (steps 4 and 7), a restart with /save (step 2). tickets_sim.lua proves their logic without the game.
local function say(s) print("ZEDQA mtk " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local Tk, S, K = ZeD.Tk, ZeD.ServerPart, ZeD.Tickets

-- every message the server part sends this client, kept for the dumps
local got = {}
local function tap(module, command, args)
    if module == "ZeD" or module == "ZeDT" or module == "ZeDQA" then got[#got + 1] = { m = module, c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function clear() got = {} end
local function raw(cmd, args) S.send("ZeDT", cmd, args or {}) end
local function role(name) sendClientCommand(p, "ZeDQA", "role", { name = name }) end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end

local function hasKey(v, name)
    if type(v) ~= "table" then return false end
    for k, x in pairs(v) do
        if k == name or hasKey(x, name) then return true end
    end
    return false
end
local function hasWord(v, word)
    if type(v) == "string" then return v:find(word, 1, true) ~= nil end
    if type(v) == "table" then
        for _, x in pairs(v) do if hasWord(x, word) then return true end end
    end
    return false
end

-- ModData.request of the obvious name
local modReply = nil
local function onMod(tag, tbl) if tag == "ZeD_Tickets" then modReply = tbl end end
Events.OnReceiveGlobalModData.Add(onMod)

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

-- ---------------------------------------------------------------------------
-- STEP 1 AND 2
-- ---------------------------------------------------------------------------
add(1500, function()
    pass("step 1: present", S.present == true, S.present)
    pass("step 1: v = 1", S.v == 1, S.v)
    pass("step 1: staff and admin", S.staff == true and S.admin == true)
    ModData.request("ZeD_Tickets")
end)
add(1500, function()
    pass("step 2: ModData.request of ZeD_Tickets gives false", modReply == false or modReply == nil, tostring(modReply))
    local names = ModData.getTableNames()
    local leak = false
    for k = 0, names:size() - 1 do if tostring(names:get(k)):find("ZeD_TK_", 1, true) then leak = true end end
    pass("step 2: no ticket table on this client", not leak)
    say("TODO step 2: /save, stop, start; the same table, nextId kept. Grep the server's logs for ZeD_TK_: nothing")
    role("user")
end)

-- ---------------------------------------------------------------------------
-- STEP 3: as a plain player
-- ---------------------------------------------------------------------------
local firstId = nil
add(1000, function()
    pass("ZeDQA.role answered user", last("role") and last("role").name == "user", "needs -Mods \"ZeD_UI;ZeDQAShim\"")
    S.hello()
end)
add(1000, function()
    pass("step 5: a plain player's hello", last("hello") and last("hello").staff == false and last("hello").open == nil)
    clear()
    raw("t_new", { kind = "GRIEF", here = true, text = "qa: lying args", author = "somebody", x = 1, y = 1, day = 999, rid = 1 })
end)
add(1000, function()
    local a = last("t_ack")
    firstId = a and a.id
    pass("step 3: t_new accepted", a and a.ok == true, a and a.err)
    raw("t_new", { kind = "BUG", text = "qa: too soon", rid = 2 })
end)
add(1000, function()
    local a = last("t_ack")
    pass("step 3: a second inside 60 s answers wait with seconds left", a and a.err == "wait" and a.left and a.left > 0, a and a.left)
    nolimits()
    raw("t_new", { kind = "BUG", text = string.rep("a", 1001), rid = 3 })
end)
add(1000, function()
    pass("step 3: 1001 characters refused", last("t_ack") and last("t_ack").err == "text")
    raw("t_new", { kind = "BUG", text = string.rep("a", 1000), rid = 4 })
end)
add(1000, function()
    pass("step 3: 1000 characters taken", last("t_ack") and last("t_ack").ok == true)
end)
for n = 3, 5 do
    add(300, function() nolimits() end)
    add(500, function() raw("t_new", { kind = "OTHER", text = "qa: filler " .. n, rid = 10 + n }) end)
end
add(300, function() nolimits() end)
add(800, function() raw("t_new", { kind = "OTHER", text = "qa: the sixth", rid = 20 }) end)
add(1000, function()
    local a = last("t_ack")
    pass("step 3: a sixth open ticket refused", a and a.err == "many", a and a.err)
    clear()
    nolimits()
end)
-- hostile arguments: one bad line each in the ZeD log, and nothing back that was not asked for
local HOSTILE = { "14", { 1 }, -1, 14.5 }
for n, bad in ipairs(HOSTILE) do
    add(500, function() raw("t_one", { id = bad, rid = 30 + n }) end)
end
add(1000, function()
    local n, others = 0, 0
    for _, m in ipairs(got) do
        if m.c == "t_ack" and m.a.err == "gone" then n = n + 1 elseif m.m ~= "ZeDQA" then others = others + 1 end
    end
    pass("step 3: a bad id answers gone", n == #HOSTILE, n)
    pass("step 3: nothing else came back", others == 0, others)
    clear()
    raw("t_one", { id = firstId, rid = string.rep("x", 4000) })
end)
add(800, function()
    pass("step 3: a long rid is not echoed", last("t_one") ~= nil and not hasKey(last("t_one"), "rid"))
    S.send("ZeDT", "t_one", {})
end)
add(800, function()
    pass("step 3: no args answers", last("t_ack") and last("t_ack").err == "gone")
    say("TODO step 3: the nearby list needs a second player (E4); tickets_sim.lua covers it")
end)

-- ---------------------------------------------------------------------------
-- STEP 5: refused, as a plain player
-- ---------------------------------------------------------------------------
local STAFF = { "t_queue", "t_card", "t_take", "t_answer", "t_addnote", "t_close", "t_reopen", "t_spam", "t_unspam", "t_delete", "t_sync", "t_gamediff" }
for _, c in ipairs(STAFF) do
    add(250, function() nolimits() end)
    add(350, function() clear(); raw(c, { id = firstId, text = "qa", rid = 50 }) end)
    add(500, function()
        pass("step 5: " .. c .. " as a user answers perm", last("t_ack") and last("t_ack").err == "perm", last("t_ack") and last("t_ack").err)
    end)
end

-- ---------------------------------------------------------------------------
-- STEP 4 AND 5: the game's ticket, and the staff's commands
-- ---------------------------------------------------------------------------
add(500, function() role("admin") end)
add(800, function() nolimits(); S.hello() end)   -- (limits first: the last perm answer sent a hello of its own, inside hello's 5 s)
add(1000, function()
    pass("step 5: admin again", S.staff == true and S.admin == true)
    -- (the five above are open: staff reset them through the queue so filing works)
    K.openQueue({ status = "Open" })
end)
add(3000, function()
    local q = K.queue
    pass("step 5: the queue answers", q and q.n >= 1, q and q.n)
    pass("step 5: the counts on the tab", K.counts.open >= 1, K.counts.open)
    say("the save warning for staff: " .. tostring(q and q.noSave))
    for _, r in ipairs(q and q.rows or {}) do raw("t_close", { id = r.id }) end
end)
add(5500, function()
    nolimits()
    clear()
    pass("step 4: Send", K.ask("GRIEF", true, "qa: the truck", function(a) FILED = a end) == "sent")
end)
add(1500, function()
    local a = FILED
    pass("step 4: t_ack with the file text", a and a.ok == true and a.file ~= nil, a and a.file)
    TICKET = a and a.id
    getTickets(me)
end)
local seen = nil
local function viewOnce(list)
    seen = {}
    for k = 0, list:size() - 1 do seen[#seen + 1] = list:get(k):getMessage() end
end
add(100, function() Events.ViewTickets.Add(viewOnce); getTickets(me) end)
add(1200, function()
    Events.ViewTickets.Remove(viewOnce)
    local found = false
    for _, m in ipairs(seen or {}) do if m == FILED.file then found = true end end
    pass("step 4: the game's ticket reads [GRIEF #n] ...", found, FILED and FILED.file)
    say("TODO step 4: quit before filing, rejoin: filed once; rejoin again: not twice; tickets_sim.lua covers it")
    nolimits()
    K.openQueue({ status = "Open" })
end)
add(3000, function() nolimits(); K.openCard(TICKET) end)
add(1000, function()
    local c = K.card
    pass("step 5: the card, Seen", c and c.id == TICKET and c.status == "Seen", c and c.status)
    pass("step 6: linked by the tag", c and c.gameId ~= nil, c and c.gameId)
    say("the game's id " .. tostring(c and c.gameId) .. "; the place " .. tostring(c and c.place and c.place.x))
    K.take(TICKET)
end)
add(800, function()
    pass("step 5: Take", K.card and K.card.status == "Progress" and K.card.assignee == me)
    K.addNote(TICKET, "qa: a note only staff see")
end)
add(800, function()
    pass("step 5: a note", K.card and K.card.notes and K.card.notes.n == 1)
    role("user")
end)
-- the dump: a plain player's view of a ticket with notes
add(800, function() clear(); nolimits(); raw("t_one", { id = TICKET }) end)
add(800, function() raw("t_mine", {}) end)
add(800, function() S.hello() end)
add(1000, function()
    local bad = {}
    for _, name in ipairs({ "notes", "near", "assignee", "spamBy", "open", "spam", "gameId", "gameGone", "gameAns", "source" }) do
        if hasKey(got, name) then bad[#bad + 1] = name end
    end
    pass("step 5: a plain player's dump holds none of the staff fields", #bad == 0, table.concat(bad, ", "))
    pass("step 5: no note's words in it", not hasWord(got, "a note only staff see"))
    pass("step 5: the player reads In progress", last("t_one") and last("t_one").st == "Progress", last("t_one") and last("t_one").st)
    role("moderator")
end)
add(800, function() nolimits(); clear(); K.spam(TICKET) end)
add(800, function()
    pass("step 5: a moderator marks spam", last("t_ack") and last("t_ack").ok == true)
    raw("t_delete", { id = TICKET, rid = 60 })
end)
add(800, function()
    pass("step 5: a moderator cannot delete", last("t_ack") and last("t_ack").err == "perm")
    role("user")
end)
add(800, function() clear(); nolimits(); raw("t_one", { id = TICKET }) end)
add(800, function()
    local a = last("t_one")
    pass("step 5: a spammed ticket reads Closed", a and a.st == "Closed", a and a.st)
    pass("step 5: the word never reaches a player", not hasWord(got, "Spam"))
    role("admin")
end)
add(800, function() nolimits(); clear(); K.unspam(TICKET) end)
add(800, function()
    pass("step 5: Not spam", K.card and K.card.status == "Open", K.card and K.card.status)
    NOTES_BEFORE = 0
    local src = ZeD.Messages.sources[getText("UI_userpanel_tickets")]
    NOTES_BEFORE = src and #src.items or 0
    K.answer(TICKET, "qa: the first answer", function(a) ANS = a end)
end)

-- ---------------------------------------------------------------------------
-- STEP 6 AND 7
-- ---------------------------------------------------------------------------
add(1500, function()
    pass("step 6: the first answer", ANS and ANS.ok == true and ANS.first == true, ANS and ANS.first)
    pass("step 7: this client's own ticket: t_note", last("t_note") ~= nil)
    local src = ZeD.Messages.sources[getText("UI_userpanel_tickets")]
    local n = src and #src.items or 0
    pass("step 7: a note on the belt", n > NOTES_BEFORE, n)
    say("toasts now: " .. #ZeD.Messages.toasts)
    K.reopen(TICKET)
end)
add(800, function() ANS = nil; K.answer(TICKET, "qa: the second answer", function(a) ANS = a end) end)
add(1200, function()
    pass("step 6: a second answer: first false", ANS and ANS.ok == true and ANS.first == false, ANS and ANS.first)
    nolimits()
    getTickets(nil)
end)
add(1000, function()
    local row = K.list and K.list.byId[K.card and K.card.gameId or 0]
    pass("step 6: the game's window shows one answer, the stub", row and row.at == Tk.answerText("qa: the first answer"), row and row.at)   -- (the director: the game's copy holds only the stub)
    -- from the bridge, as a plain player: forged tags and answers
    role("user")
end)
add(800, function()
    addTicket(me, "[GRIEF #" .. tostring(TICKET) .. "] forged words", -1)
    addTicket("qa_victim", "[GRIEF #1] filed under another name", -1)
    addTicket(me, "qa: the game's window, no tag", -1)
    for n = 1, 300 do addTicket("qa_flood", "qa: flood " .. n, -1) end
    say("filed 303 game tickets as a plain player")
end)
add(3000, function() role("admin") end)
add(1000, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
add(25000, function()
    say("after the first sync: gameMax " .. tostring(K.gameMax) .. ", the list " .. tostring(K.list and #K.list.rows))
    K.closeQueue()
    K.openQueue({ status = "All" })
end)
-- (a page is read before its sync runs, so skipped shows at the next open: the rise is measured from that one)
add(8000, function()
    SKIPPED = K.queue and K.queue.skipped
    say("second open: skipped " .. tostring(SKIPPED) .. ", gameMax " .. tostring(K.gameMax))
    K.closeQueue()
    K.openQueue({ status = "All" })
end)
add(8000, function()
    local q = K.queue
    pass("step 6: the caps stop the flood, skipped counts", q and q.skipped and q.skipped > 250, q and q.skipped)
    pass("step 6: open and close twice, no rise", q and q.skipped == SKIPPED, tostring(q and q.skipped) .. " was " .. tostring(SKIPPED))
    local forged = false
    for _, r in ipairs(q and q.rows or {}) do
        if r.id ~= TICKET and r.first and r.first:find("forged words", 1, true) then forged = r end
    end
    pass("step 6: the forged tag became a record of its own", forged ~= false)
    say("TODO step 6: remove a linked ticket on the game's own window, press Refresh twice 10 s apart: Removed; rejoin: not filed again")
    nolimits()
    K.delete(TICKET, function(a) DEL = a end)
end)
add(2000, function()
    pass("step 6: Delete", DEL and DEL.ok == true, DEL and DEL.err)
    getTickets(nil)
end)
add(1000, function()
    local row = K.card == nil and true or false
    pass("step 6: the card is gone", row)
    -- the game's modal: a ticket as a note, anything else still opens
    local src = ZeD.Messages.sources[getText("UI_userpanel_tickets")]
    local before = src and #src.items or 0
    triggerEvent("OnAdminMessage", "user qa added a ticket <LINE> <LINE> words", -1, -1, -1)
    triggerEvent("OnAdminMessage", "user qa2 added a ticket <LINE> <LINE> words", -1, -1, -1)
    src = ZeD.Messages.sources[getText("UI_userpanel_tickets")]
    local after = src and #src.items or 0
    pass("step 7: the game's modal: one note, not a window", after <= before + 1, after - before)
    local n = #ISAdminMessage.messages
    triggerEvent("OnAdminMessage", "qa: any other admin message", -1, -1, -1)
    pass("step 7: other admin messages still open", #ISAdminMessage.messages == n + 1)
    local m = ISAdminMessage.messages[#ISAdminMessage.messages]
    if m then pcall(function() m:destroy() end) end
    say("TODO step 7: answer offline, rejoin: one note; Open clears it. tickets_sim.lua covers it")
end)
add(500, function()
    K.closeQueue()
    Events.OnServerCommand.Remove(tap)
    Events.OnReceiveGlobalModData.Remove(onMod)
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
