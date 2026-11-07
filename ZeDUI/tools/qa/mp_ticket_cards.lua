-- ZeDUI/tools/qa/mp_ticket_cards.lua  (Nov 5 2026, QA): multiplayer Phase 1, tickets, steps 8 to 10 of Part D
-- (ZeDUI/MP_SERVER_PART_DESIGN.md): every state of the ticket cards, from the mockup's tickets, one picture each.
-- grep "ZEDQA mtc". Pictures: mtc_<state>.png, in the screenshots folder.
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_ticket_cards.txt
-- It holds the cards' traffic (ZeD.TicketCards.qaHold) and puts the mockup's tickets in the model, so nothing here reaches
-- the server's record. mp_tickets.lua is the run against the real server. For Deck, 720 and Large text run it again at
-- those settings (zedqa_run -Width -Height; ZeD setup's text size): the states are the same.
-- ticket_cards_sim.lua loads this file too, for the same states with no game: it sets ZEDQA_CARDS_SIM and gets the table.

local Q = {}

local FILED = 1793913240

local function th(...)
    local out = { n = 0 }
    for _, e in ipairs({ ... }) do
        out.n = out.n + 1
        out[out.n] = { who = e[1], text = e[2], staff = e[3], game = e[4], t = FILED }
    end
    return out
end
local NONE = { n = 0 }

-- the mockup's tickets, as the server part's staffView sends them
function Q.tickets(me)
    return {
        { id = 15, source = "zed", kind = "STUCK", author = me, day = 12, filed = FILED + 1680, place = { x = 6347, y = 5372, z = 0 }, near = { n = 0 },
          status = "Seen", thread = th({ me, "Climbed out a window of the motel and I'm stuck between the fence and the wall. Can't get out either way." }), notes = NONE },
        { id = 14, source = "zed", kind = "GRIEF", author = "Kade_R", day = 12, filed = FILED, place = { x = 6280, y = 5350, z = 0, name = "Riverside farm" },
          near = { n = 2, "Rosa", "Mags_77" }, status = "Open", thread = th({ "Kade_R", "Someone pulled the engine out of my pickup at the farm. It was fine at 6. Doors were locked." }), notes = NONE },
        { id = 13, source = "zed", kind = "STUCK", author = "Rosa", day = 12, filed = FILED - 1380, place = { x = 10650, y = 9970, z = 0, name = "Muldraugh warehouse" }, near = { n = 0 },
          status = "Progress", assignee = "Hermit",
          thread = th({ "Rosa", "Fell through the floor at the warehouse by the gas station. Can't climb out." }, { "Hermit", "On my way. Don't log out.", true }),
          notes = th({ "Hermit", "Floor tile missing at 10651 x 9971, z 1. Tell build-team." }) },
        { id = 12, source = "zed", kind = "BUG", author = "Mags_77", day = 11, filed = FILED - 80000, status = "Answered", assignee = "Hermit",
          thread = th({ "Mags_77", "Generator says it's on but the fridge next to it is dead." },
              { "Hermit", "Generators only reach about 20 tiles and the same floor. Move it closer and it'll come up.", true }), notes = NONE },
        { id = 11, source = "zed", kind = "QUESTION", author = "tjk", day = 11, filed = FILED - 90000, status = "Answered", assignee = "Hermit",
          thread = th({ "tjk", "Can we claim vehicles on this server?" }, { "Hermit", "Not yet. Vehicle claims come with the next update.", true }), notes = NONE },
        { id = 10, source = "zed", kind = "OTHER", author = "Rosa", day = 10, filed = FILED - 180000, status = "Open",
          thread = th({ "Rosa", "Could we do a trading post at the Muldraugh church this weekend? I'll bring the ammo." }), notes = NONE },
        { id = 9, source = "zed", kind = "GRIEF", author = "Kade_R", day = 9, filed = FILED - 260000, place = { x = 6290, y = 5341, z = 0, name = "Riverside farm" },
          near = { n = 1, "tjk" }, status = "Closed", assignee = "Hermit",
          thread = th({ "Kade_R", "My fence got knocked down again." }, { "Hermit", "Checked the log: zombies, not a player. Rebuilt it for you this once.", true }),
          notes = th({ "Hermit", "Log shows a horde of 40 passing at 10:05." }) },
        { id = 8, source = "game", kind = "NONE", author = "mike_d", status = "Open",
          thread = th({ "mike_d", "help my car is stuck on the fence at the gas station" }), notes = NONE },
        { id = 7, source = "zed", kind = "OTHER", author = "lootdrop99", day = 9, filed = FILED - 300000, status = "Spam", spamBy = "Jules",
          thread = th({ "lootdrop99", "FREE KATANAS AND CARS AT ROSEWOOD PM ME!!! FREE FREE FREE" }), notes = NONE },
    }
end

function Q.staffRow(r)
    local where = nil
    if r.place then where = r.place.name or (tostring(r.place.x) .. " x " .. tostring(r.place.y)) end
    return { id = r.id, kind = r.kind, author = r.author, st = r.status, day = r.day, filed = r.filed, where = where,
        assignee = r.assignee, first = string.sub(r.thread[1].text, 1, 120), replies = r.thread.n - 1, src = r.source }
end

local PLAYER_ST = { Open = "Sent", Seen = "Seen", Progress = "Progress", Answered = "Answered", Closed = "Closed", Spam = "Closed" }

function Q.mineRow(r)
    return { pv = true, id = r.id, kind = r.kind, st = PLAYER_ST[r.status], day = r.day, last = string.sub(r.thread[r.thread.n].text, 1, 120), replies = r.thread.n - 1 }
end

function Q.mineView(r, can)
    return { id = r.id, kind = r.kind, st = PLAYER_ST[r.status], day = r.day, filed = r.filed, place = r.place, thread = r.thread, can = can }
end

function Q.byId(list, id)
    for _, r in ipairs(list) do if r.id == id then return r end end
    return nil
end

-- a queue page, as t_queue sends it, of the records a filter keeps
function Q.page(list, keep, page, opts)
    local rows, all = {}, 0
    local authors, seen = {}, {}
    for _, r in ipairs(list) do
        if not seen[r.author] then
            seen[r.author] = true
            authors[#authors + 1] = r.author
        end
        if keep(r) then
            all = all + 1
            if all > (page - 1) * 25 and all <= page * 25 then rows[#rows + 1] = Q.staffRow(r) end
        end
    end
    local out = { page = page, pages = math.max(1, math.ceil(all / 25)), n = all, rows = rows, open = 0, spam = 0, gameMax = 200, skipped = 0, authors = authors }
    for _, r in ipairs(list) do
        if r.status == "Open" or r.status == "Seen" or r.status == "Progress" then out.open = out.open + 1 end
        if r.status == "Spam" then out.spam = out.spam + 1 end
    end
    if opts then for k, v in pairs(opts) do out[k] = v end end
    return out
end

local function isOpen(r) return r.status == "Open" or r.status == "Seen" or r.status == "Progress" end
local KEEP = {
    Open = isOpen,
    Answered = function(r) return r.status == "Answered" end,
    Closed = function(r) return r.status == "Closed" end,
    All = function(r) return r.status ~= "Spam" end,
    Spam = function(r) return r.status == "Spam" end,
}

-- the game's list, as ZeD_Tickets reads a full ViewTickets, for the states without the server part
function Q.gameList()
    local rows = {
        { g = 212, a = "Kade_R", m = "[GRIEF] Someone pulled the engine out of my pickup (6280 x 5350)", v = true },
        { g = 213, a = "Rosa", m = "[STUCK] Fell through the floor at the warehouse", v = true, aw = "Hermit", at = "On my way. Don't log out." },
        { g = 214, a = "mike_d", m = "help my car is stuck on the fence at the gas station", v = false },
    }
    local byId = {}
    for _, r in ipairs(rows) do byId[r.g] = r end
    return { rows = rows, byId = byId, top = 214, at = 0 }
end

-- every state: tab "server" or "admin"; run(win, st) puts it on screen. TC, C and me from Q.bind.
function Q.bind(TC, C, S, me)
    local list = Q.tickets(me)
    local mineList = { Q.byId(list, 15), Q.byId(list, 12), Q.byId(list, 9) }
    local function reset(win, st)
        TC.qaHold, TC.qaRole, TC.qaGo, TC.qaStats, TC.qaLink = true, "admin", true, true, nil
        st.card = nil
        st.screen = "tickets"      -- (the Admin tab holds the queue on its own screen since Phase 2)
        local t = TC.qaState(st)
        t.popup, t.confirm, t.flashText, t.busy = nil, nil, nil, nil
        t.q.status, t.q.kind, t.q.who, t.q.mine, t.q.find, t.q.newest, t.q.page = "Open", nil, nil, nil, "", true, 1
        t.queueKey, t.mineKey = nil, nil
        C.mine, C.one, C.queue, C.card, C.list = {}, {}, nil, nil, nil
        C.counts = { open = 5, spam = 1 }
        C.seq = C.seq + 1
        for _, r in ipairs(mineList) do C.mine[#C.mine + 1] = Q.mineRow(r) end
    end
    local function queue(st, status, opts)
        local t = TC.qaState(st)
        t.q.status = status
        C.queue = Q.page(list, KEEP[status], 1, opts)
        t.queueKey = nil
    end
    local function card(win, st, id, status)
        local r = Q.byId(list, id)
        C.card = r
        TC.qaOpen(win, st, "staff", id)
    end
    local function mine(win, st, id, can)
        C.one[id] = Q.mineView(Q.byId(list, id), can)
        TC.qaOpen(win, st, "mine", id)
    end
    local out = {}
    local function S1(name, tab, fn) out[#out + 1] = { name = name, tab = tab, reset = reset, run = fn } end

    -- the Server tab
    S1("server-list", "server", function() end)
    S1("server-empty", "server", function() C.mine = {}; C.seq = C.seq + 1 end)
    S1("server-flash", "server", function(win, st) TC.qaFlash(st, ZeD.tr("UI_ZeD_Tk_Sent", 16)) end)   -- (the card's own words, in the game's language)
    S1("ask-blank", "server", function(win, st) TC.qaOpen(win, st, "ask") end)
    S1("ask-griefing", "server", function(win, st) TC.qaOpen(win, st, "ask"); TC.qaAsk(st, "GRIEF", true) end)
    S1("ask-off", "server", function(win, st) TC.qaOpen(win, st, "ask"); TC.qaAsk(st, "QUESTION", false) end)
    S1("ask-link-wait", "server", function(win, st)
        TC.qaLink = "wait"
        TC.qaOpen(win, st, "ask")
        TC.qaAsk(st, "BUG", false)
    end)
    S1("ask-refused", "server", function(win, st)
        TC.qaOpen(win, st, "ask")
        TC.qaAsk(st, "BUG", false)
        TC.qaFlash(st, C.errText("wait", 42))
    end)
    S1("mine-open", "server", function(win, st) mine(win, st, 15, true) end)
    S1("mine-answered", "server", function(win, st) mine(win, st, 12, false) end)
    S1("mine-closed", "server", function(win, st) mine(win, st, 9, false) end)
    S1("mine-long", "server", function(win, st)
        local r = { id = 30, kind = "BUG", st = "Progress", day = 3, filed = FILED, thread = { n = 40 }, can = true }
        for i = 1, 40 do r.thread[i] = { who = (i % 2 == 0) and "Hermit" or me, staff = i % 2 == 0, text = string.rep("A long message about the generator. ", 28) } end
        C.one[30] = r
        TC.qaOpen(win, st, "mine", 30)
    end)
    S1("server-fallback", "server", function()
        TC.qaLink = "off"
        C.mine = { { id = 212, kind = "GRIEF", st = "Seen", last = "Someone pulled the engine out of my pickup", replies = 0, game = true,
            text = "Someone pulled the engine out of my pickup (6280 x 5350)" } }
        C.seq = C.seq + 1
    end)
    S1("mine-fallback", "server", function(win, st)
        TC.qaLink = "off"
        C.mine = { { id = 213, kind = "STUCK", st = "Answered", last = "On my way.", replies = 1, game = true, text = "Fell through the floor",
            ansWho = "Hermit", ansText = "On my way. Don't log out." } }
        C.seq = C.seq + 1
        TC.qaOpen(win, st, "mine", 213, true)
    end)

    -- the queue
    S1("queue-link-wait", "admin", function() TC.qaLink = "wait" end)
    S1("queue-loading", "admin", function() C.queue = nil end)
    S1("queue-open", "admin", function(win, st) queue(st, "Open") end)
    S1("queue-answered", "admin", function(win, st) queue(st, "Answered") end)
    S1("queue-closed", "admin", function(win, st) queue(st, "Closed") end)
    S1("queue-all", "admin", function(win, st) queue(st, "All") end)
    S1("queue-spam-admin", "admin", function(win, st) queue(st, "Spam") end)
    S1("queue-spam-moderator", "admin", function(win, st) TC.qaRole = "moderator"; queue(st, "Spam") end)
    S1("queue-none", "admin", function(win, st)
        queue(st, "Open")
        C.queue.rows, C.queue.n = {}, 0
    end)
    S1("queue-no-match", "admin", function(win, st)
        queue(st, "Answered")
        TC.qaState(st).q.kind = "APPEAL"
        C.queue.rows, C.queue.n = {}, 0
    end)
    S1("queue-paged-1", "admin", function(win, st)
        local many = {}
        for i = 1, 26 do many[i] = { id = 100 - i, kind = "BUG", author = "Rosa", day = 2, status = "Open", thread = th({ "Rosa", "Ticket number " .. i }), notes = NONE } end
        C.queue = Q.page(many, isOpen, 1)
        TC.qaState(st).queueKey = nil
    end)
    S1("queue-paged-2", "admin", function(win, st)
        local many = {}
        for i = 1, 26 do many[i] = { id = 100 - i, kind = "BUG", author = "Rosa", day = 2, status = "Open", thread = th({ "Rosa", "Ticket number " .. i }), notes = NONE } end
        TC.qaState(st).q.page = 2
        C.queue = Q.page(many, isOpen, 2)
        TC.qaState(st).queueKey = nil
    end)
    S1("queue-notes", "admin", function(win, st) queue(st, "Open", { noSave = true, skipped = 14 }) end)
    S1("queue-frozen", "admin", function(win, st) TC.qaLink = "frozen"; queue(st, "Open") end)
    S1("queue-pop-kind", "admin", function(win, st) queue(st, "Open"); Q.pop(TC, st, "kind") end)
    S1("queue-pop-mine", "admin", function(win, st) queue(st, "Open"); Q.pop(TC, st, "mine") end)
    S1("queue-pop-who-many", "admin", function(win, st)
        local many = {}
        for i = 1, 90 do many[i] = { id = 300 - i, kind = "BUG", author = "player_" .. i, day = 2, status = "Open", thread = th({ "x", "Ticket " .. i }), notes = NONE } end
        C.queue = Q.page(many, isOpen, 1)
        TC.qaState(st).queueKey = nil
        Q.pop(TC, st, "who")
    end)
    S1("queue-fallback", "admin", function() TC.qaLink = "off"; C.list = Q.gameList(); C.seq = C.seq + 1 end)

    -- the ticket card
    S1("card-open", "admin", function(win, st) queue(st, "Open"); card(win, st, 14) end)
    S1("card-progress-notes", "admin", function(win, st) queue(st, "Open"); card(win, st, 13) end)
    S1("card-answered", "admin", function(win, st) queue(st, "Answered"); card(win, st, 12) end)
    S1("card-closed", "admin", function(win, st) queue(st, "Closed"); card(win, st, 9) end)
    S1("card-no-kind", "admin", function(win, st) queue(st, "Open"); card(win, st, 8) end)
    S1("card-spam-admin", "admin", function(win, st) queue(st, "Spam"); card(win, st, 7) end)
    S1("card-spam-moderator", "admin", function(win, st) TC.qaRole = "moderator"; queue(st, "Spam"); card(win, st, 7) end)
    S1("card-moderator", "admin", function(win, st) TC.qaRole = "moderator"; queue(st, "Open"); card(win, st, 14) end)
    S1("card-confirm", "admin", function(win, st) queue(st, "Open"); card(win, st, 14); TC.qaConfirm(st) end)
    S1("card-no-go", "admin", function(win, st) TC.qaGo = false; queue(st, "Open"); card(win, st, 14) end)
    S1("card-no-stats", "admin", function(win, st) TC.qaStats = false; queue(st, "Open"); card(win, st, 14) end)
    S1("card-frozen", "admin", function(win, st) TC.qaLink = "frozen"; queue(st, "Open"); card(win, st, 14) end)
    S1("card-removed-game", "admin", function(win, st)
        queue(st, "Open")
        local r = {}
        for k, v in pairs(Q.byId(list, 14)) do r[k] = v end
        r.gameGone = true
        C.card = r
        TC.qaOpen(win, st, "staff", 14)
    end)
    S1("card-flash", "admin", function(win, st) queue(st, "Open"); card(win, st, 14); TC.qaFlash(st, "Answered. Kade_R gets a note on the belt.") end)
    S1("card-long", "admin", function(win, st)
        queue(st, "Open")
        local r = { id = 31, source = "zed", kind = "BUG", author = "Rosa", day = 3, filed = FILED, status = "Progress", assignee = "Hermit", thread = { n = 40 }, notes = { n = 20 } }
        for i = 1, 40 do r.thread[i] = { who = (i % 2 == 0) and "Hermit" or "Rosa", staff = i % 2 == 0, text = string.rep("A long message. ", 60) } end
        for i = 1, 20 do r.notes[i] = { who = "Hermit", text = string.rep("A long note. ", 70) } end
        C.card = r
        TC.qaOpen(win, st, "staff", 31)
    end)
    S1("card-fallback", "admin", function(win, st) TC.qaLink = "off"; C.list = Q.gameList(); C.seq = C.seq + 1; TC.qaOpen(win, st, "staff", 212, true) end)
    S1("card-fallback-answered", "admin", function(win, st) TC.qaLink = "off"; C.list = Q.gameList(); C.seq = C.seq + 1; TC.qaOpen(win, st, "staff", 213, true) end)
    S1("card-fallback-confirm", "admin", function(win, st)
        TC.qaLink = "off"
        C.list = Q.gameList()
        C.seq = C.seq + 1
        TC.qaOpen(win, st, "staff", 212, true)
        TC.qaConfirm(st)
    end)
    return out
end

-- a filter's pop-up open: it needs one frame of the queue first
function Q.pop(TC, st, key)
    TC.qaState(st).qaPopNext = key
end

-- ---------------------------------------------------------------------------
if ZEDQA_CARDS_SIM then return Q end

local function say(s) print("ZEDQA mtc " .. tostring(s)) end
local TC, C, S = ZeD.TicketCards, ZeD.Tickets, ZeD.ServerPart
local p = getPlayer()
local states = Q.bind(TC, C, S, p:getUsername())
local CW, WW = ZeD_CharacterWindow.getWindow, ZeD_WorldWindow.getWindow

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

for _, s in ipairs(states) do
    add(250, function()
        local server = s.tab == "server"
        if server then ZeD_CharacterWindow.openTab(0, "server") else ZeD_WorldWindow.openTab(0, "admin") end
    end)
    add(500, function()
        local win = (s.tab == "server") and CW() or WW()
        local st = (s.tab == "server") and win._serverTab or win._adminTab
        if not st then say("no tab state for " .. s.name); return end
        s.reset(win, st)
        s.run(win, st)
    end)
    add(900, function()
        local win = (s.tab == "server") and CW() or WW()
        local def = (s.tab == "server") and ZeD.ServerTab or ZeD.AdminTab
        local n = #def.buildFocusables(win)
        say(s.name .. ": " .. n .. " stops")
        pcall(function() getCore():TakeFullScreenshot("mtc_" .. s.name .. ".png") end)
    end)
end
add(500, function()
    TC.qaHold, TC.qaRole, TC.qaGo, TC.qaStats, TC.qaLink = nil, nil, nil, nil, nil
    C.mine, C.one, C.queue, C.card, C.list = {}, {}, nil, nil, nil
    C.loadMine()
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
