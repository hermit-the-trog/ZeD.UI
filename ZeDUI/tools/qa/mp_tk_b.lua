-- ZeDUI/tools/qa/mp_tk_b.lua  (Nov 5 2026, QA): Part D's quit, rejoin, restart and crash checks (steps 2, 4, 7, 11). One client, run by batch_tk_restart.ps1,
-- which writes the phase to Lua/zedqa_tk_phase.txt and stops, starts or empties the server between phases. grep "ZEDQA mtb".
--   1 first join: a ticket answered and left unread, a ticket never filed in the game (as if the client quit first), /save
--   2 after a stop and start with the save: all kept; filed once at this join; one note; Open clears it; a ticket filed and not saved
--   3 rejoin, server still up: not filed twice, no note
--   4 after a kill with no save: the unsaved record gone, its game row adopted with its kind, a reused number links to nothing old
--   5 after zedqa.db went with the save kept: ids restart, reset runs once, no row removed
local function say(s) print("ZEDQA mtb " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local Tk, S, K = ZeD.Tk, ZeD.ServerPart, ZeD.Tickets

local function readLines(name)
    local out, r = {}, getFileReader(name, false)
    if not r then return out end
    local l = r:readLine()
    while l do out[#out + 1] = l; l = r:readLine() end
    r:close()
    return out
end
local PHASE = tonumber((readLines("zedqa_tk_phase.txt")[1] or "1"):match("%d+"))
local IDS = {}
for _, l in ipairs(readLines("zedqa_tk_ids.txt")) do
    local k, v = l:match("^(%w+)=(%d+)$")
    if k then IDS[k] = tonumber(v) end
end
local function saveIds()
    local w = getFileWriter("zedqa_tk_ids.txt", true, false)
    for k, v in pairs(IDS) do w:write(k .. "=" .. tostring(v) .. "\n") end
    w:close()
end

local got = {}
local function tap(module, command, args)
    if module == "ZeD" or module == "ZeDT" or module == "ZeDQA" then got[#got + 1] = { c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function raw(cmd, args) S.send("ZeDT", cmd, args or {}) end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local function notes()
    local src = ZeD.Messages.sources[getText("UI_userpanel_tickets")]
    return src and src.items or {}
end
local function unreadNotes()
    local n = 0
    for _, it in ipairs(notes()) do if it.k == "ticket" and not it.read then n = n + 1 end end
    return n
end
local function ticketNote()
    for _, it in ipairs(notes()) do if it.k == "ticket" then return it end end
    return nil
end
-- my game rows by tag, read fresh
local rows = nil
local function view(list)
    rows = {}
    for k = 0, list:size() - 1 do
        local t = list:get(k)
        rows[#rows + 1] = { g = t:getTicketID(), m = t:getMessage(), a = t:getAuthor() }
    end
end
local function rowsTagged(id)
    local n = 0
    for _, r in ipairs(rows or {}) do
        local _, tag = Tk.parse(r.m)
        if tag == id then n = n + 1 end
    end
    return n
end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function ask(kind, text, into)
    add(300, function() nolimits() end)
    add(500, function() K.ask(kind, true, text, function(a) IDS[into] = a and a.id; say(into .. " = " .. tostring(a and a.id) .. ", " .. tostring(a and a.file)) end) end)
    add(1500, function() end)
end
local function readList(after)
    add(200, function() Events.ViewTickets.Add(view); getTickets(nil) end)
    add(1500, function() Events.ViewTickets.Remove(view); after() end)
end

add(1500, function() nolimits(); S.hello() end)
add(1500, function() pass("phase " .. PHASE .. ": the server part answers", S.present == true and S.staff == true) end)

if PHASE == 1 then
    ask("GRIEF", "qa: kept across a restart", "KEPT")
    add(300, function() K.openQueue({ status = "All" }) end)
    add(5000, function() nolimits(); K.openCard(IDS.KEPT) end)
    add(1000, function()
        pass("linked before the save", K.card and K.card.gameId ~= nil, K.card and K.card.gameId)
        IDS.KEPTG = K.card and K.card.gameId
        nolimits()
        K.answer(IDS.KEPT, "qa: answered, not read")
    end)
    add(1200, function() K.closeCard(); K.closeQueue(); nolimits() end)
    add(500, function() raw("t_new", { kind = "STUCK", here = false, text = "qa: quit before filing", rid = 1 }) end)
    add(1000, function()
        local a = last("t_ack")
        IDS.UNFILED = a and a.id
        pass("a ticket with no game row yet", a and a.ok == true and a.id ~= nil, a and a.id)
        saveIds()
        SendCommandToServer("/save")
    end)
    add(6000, function() say("saved") end)
elseif PHASE == 2 then
    add(3500, function() say("notes unread " .. unreadNotes()); pass("offline answer: one note at the rejoin", unreadNotes() == 1, unreadNotes()) end)
    readList(function()
        pass("the unfiled ticket is filed at the join, once", rowsTagged(IDS.UNFILED) == 1, rowsTagged(IDS.UNFILED))
        nolimits()
        raw("t_mine", {})
    end)
    add(1000, function()
        local kept, unf
        for _, r in ipairs(last("t_mine") and last("t_mine").rows or {}) do
            if r.id == IDS.KEPT then kept = r end
            if r.id == IDS.UNFILED then unf = r end
        end
        pass("the kept ticket came back", kept ~= nil and kept.st == "Answered", kept and kept.st)
        pass("the filed one offers nothing more", unf ~= nil and unf.file == nil)
        nolimits()
        K.openQueue({ status = "All" })
    end)
    add(5000, function() nolimits(); K.openCard(IDS.KEPT) end)
    add(1000, function()
        pass("the same link after the restart", K.card and K.card.gameId == IDS.KEPTG, K.card and K.card.gameId)
        K.closeCard()
        K.closeQueue()
        local it = ticketNote()
        if it then K.openNote(it) end
    end)
    add(1500, function() pass("Open clears the note", unreadNotes() == 0, unreadNotes()) end)
    ask("BUG", "qa: filed after the save, lost in a crash", "LOST")
    add(500, function()
        pass("ids run on after the restart", IDS.LOST and IDS.LOST > IDS.UNFILED, IDS.LOST)
        saveIds()
    end)
elseif PHASE == 3 then
    add(3500, function() pass("no note at the next join", unreadNotes() == 0, unreadNotes()) end)
    readList(function()
        pass("not filed twice", rowsTagged(IDS.UNFILED) == 1, rowsTagged(IDS.UNFILED))
        pass("the last ticket filed once", rowsTagged(IDS.LOST) == 1, rowsTagged(IDS.LOST))
    end)
elseif PHASE == 4 then
    add(500, function() raw("t_one", { id = IDS.KEPT, rid = 2 }) end)
    add(800, function() pass("what was saved is here", last("t_one") and last("t_one").id == IDS.KEPT) end)
    add(300, function() nolimits() end)
    add(500, function() K.openQueue({ status = "All" }) end)
    add(6000, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
    add(3000, function()
        local n = 0
        for _, r in ipairs(K.queue and K.queue.rows or {}) do
            say("row " .. r.id .. " " .. tostring(r.kind) .. " " .. tostring(r.st) .. " " .. tostring(r.src) .. " " .. tostring(r.first))
            if r.kind == "BUG" and r.src == "game" then n = n + 1 end
        end
        pass("the lost ticket's game row was adopted, its kind kept", n == 1, n)
        K.closeQueue()
    end)
    ask("OTHER", "qa: a number used twice", "AGAIN")
    add(300, function() nolimits(); K.openQueue({ status = "All" }) end)
    add(5000, function() nolimits(); K.openCard(IDS.AGAIN) end)
    add(1000, function()
        local c = K.card
        pass("the new ticket reads its own words", c and c.thread[1].text == "qa: a number used twice", c and c.thread[1].text)
        pass("and links to its own row", c and c.gameId ~= nil and c.gameId > (IDS.KEPTG or 0), c and c.gameId)
        say("the lost ticket's number was " .. tostring(IDS.LOST) .. ", this one " .. tostring(IDS.AGAIN))
        K.closeCard()
        K.closeQueue()
    end)
elseif PHASE == 5 then
    add(500, function()
        for n = 1, 5 do addTicket(me, "qa: new db row " .. n, -1) end
    end)
    add(1500, function() nolimits(); K.openQueue({ status = "All" }) end)
    add(8000, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
    add(8000, function() nolimits(); K.closeQueue(); K.openQueue({ status = "All" }) end)
    add(8000, function() end)
    readList(function()
        pass("every row of the new table stands", #(rows or {}) >= 5, #(rows or {}))
        for _, r in ipairs(rows or {}) do say("game row " .. r.g .. " " .. tostring(r.m)) end
        K.closeQueue()
    end)
end

add(500, function()
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
