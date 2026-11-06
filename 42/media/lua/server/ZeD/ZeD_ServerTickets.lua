-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerTickets.lua
-- ============================================================================
-- TICKETS, THE SERVER'S SIDE (ZeDUI/MP_SERVER_PART_DESIGN.md, Part B). ZeD's record lives here and is the truth. The
-- table has a secret random name, because any logged-in client can read any global mod data table it can name (A2),
-- and it is never transmitted: each person receives only what they may see, by sendServerCommand. Two functions build
-- every outgoing table from an allowlist (playerView, staffView, and the two rows); nothing else sends ticket data.
--
-- Server Lua cannot touch the game's tickets (A4), so clients do that work and report here (t_filed, t_sync,
-- t_gamediff). What comes back from the game's side is a claim, never proof (B8): an answer from there goes in notes.
--
-- Log lines (Srv.action, kind ticket) carry id, kind, who, what and place: never the text, a note, or the table's name.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ServerCore"

local Srv = ZeD.Srv
local Tk = ZeD.Tk
if not Srv or Srv.off then return end

local L = Tk.LIMITS
local STAFF, ADMIN = Srv.CAP_STAFF, Srv.CAP_ADMIN
local PREFIX = "ZeD_TK_"
local SCHEMA = 1
local MIGRATE = {}                   -- MIGRATE[1] = function(md) ... end   moves 1 to 2; adds or reshapes, never drops

-- memory only: a /reloadlua of this file leaves it empty and open() fills it again
local T = { cards = {}, byGame = {} }
Srv.T = T

-- ---------------------------------------------------------------------------
-- THE TABLE
-- ---------------------------------------------------------------------------
local function countOf(md)
    local n = 0
    if md and type(md.tickets) == "table" then for _ in pairs(md.tickets) do n = n + 1 end end
    return n
end

-- the name already in use: the one with the most tickets if a restored backup left two. They are not merged
local function findName()
    local names = ModData.getTableNames()
    local best, bestN, found = nil, -1, 0
    for i = 0, names:size() - 1 do
        local n = names:get(i)
        if string.sub(n, 1, #PREFIX) == PREFIX then
            found = found + 1
            local c = countOf(ModData.get(n))
            if c > bestN or (c == bestN and n < best) then best, bestN = n, c end
        end
    end
    if found > 1 then Srv.action("admin", Tk.SYS, "ticket tables", nil, "found " .. found .. "; using the one with the most tickets (" .. bestN .. ")") end
    return best
end

local function open()
    if T.md then return T.md end
    local name = findName() or (PREFIX .. getRandomUUID())
    local md = ModData.getOrCreate(name)
    md.schema = md.schema or SCHEMA
    md.nextId = md.nextId or 1
    md.gameMax = md.gameMax or 0
    md.skipped = md.skipped or 0
    md.chars = md.chars or 0
    md.tickets = md.tickets or {}
    md.tombs = md.tombs or {}        -- ticket id -> author: deleted with no game link yet (B8)
    if md.schema > SCHEMA then
        T.frozen = true              -- data from a newer ZeD: read it, never change it
    end
    while md.schema < SCHEMA do
        local step = MIGRATE[md.schema]
        if not step or not pcall(step, md) then
            T.frozen = true          -- a missing or failed step: stop here, write nothing
            break
        end
        md.schema = md.schema + 1
    end
    if T.frozen then Srv.action("admin", Tk.SYS, "ticket table frozen", nil, "schema " .. tostring(md.schema) .. ", this ZeD knows " .. SCHEMA) end
    T.byGame = {}
    for _, rec in pairs(md.tickets) do
        if rec.gameId then T.byGame[rec.gameId] = rec end
    end
    T.md = md
    print("[ZeD] ticket table open: schema " .. tostring(md.schema) .. ", " .. countOf(md) .. " tickets")
    return md
end

local function textOf(rec)
    local n = 0
    for i = 1, rec.thread.n do n = n + #rec.thread[i].text end
    for i = 1, rec.notes.n do n = n + #rec.notes[i].text end
    return n
end

-- a record leaves ZeD's table. The game's row stays, and gameMax or its tag stops it coming back (B8)
local function drop(md, rec)
    md.chars = math.max(0, md.chars - textOf(rec))
    if rec.gameId then T.byGame[rec.gameId] = nil end
    md.tickets[rec.id] = nil
end

-- what goes first: records adopted from the game, which forged rows can fill, so they never push out a ZeD record; then
-- oldest first
local function oldestFirst(a, b)
    local ga, gb = a.source == "game", b.source == "game"
    if ga ~= gb then return ga end
    if a.updated ~= b.updated then return a.updated < b.updated end
    return a.id < b.id
end

-- History (Answered, Closed, Spam) goes past the record cap, or early when the text cap needs the room. Open tickets
-- are never evicted, and keep is the record being written to: it never goes from under its own write.
local function evict(md, extra, keep)
    local list, n, held = {}, 0, 0
    for _, rec in pairs(md.tickets) do
        if not Tk.isOpen(rec.status) then
            held = held + 1
            if rec ~= keep then
                n = n + 1
                list[n] = rec
            end
        end
    end
    if held <= L.HISTORY and md.chars + extra <= L.CHARS_MAX then return end
    table.sort(list, oldestFirst)
    local i = 1
    while i <= n and (held > L.HISTORY or md.chars + extra > L.CHARS_MAX) do
        drop(md, list[i])
        held = held - 1
        i = i + 1
    end
end

-- may staff write n more characters? History goes first; past that the cap holds and the writer is told full
local function room(md, n, keep)
    if md.chars + n <= L.CHARS_MAX then return true end
    evict(md, n, keep)
    return md.chars + n <= L.CHARS_MAX
end

-- may a player's words go in, or words from the game's side? They stop at PLAYER_CHARS, so free accounts can never fill
-- the room staff write in. The only history they can push out is the Spam pile: staff have already said that is nothing.
local function playerRoom(md, n, keep)
    if md.chars + n <= L.PLAYER_CHARS then return true end
    local list, c = {}, 0
    for _, rec in pairs(md.tickets) do
        if rec.status == "Spam" and rec ~= keep then
            c = c + 1
            list[c] = rec
        end
    end
    table.sort(list, oldestFirst)
    local i = 1
    while i <= c and md.chars + n > L.PLAYER_CHARS do
        drop(md, list[i])
        i = i + 1
    end
    return md.chars + n <= L.PLAYER_CHARS
end

local function tally(md)
    local c = { open = 0, spam = 0, gameOpen = 0, zed = {}, claimed = {}, kinds = {} }
    for _, rec in pairs(md.tickets) do
        if Tk.isOpen(rec.status) then
            c.open = c.open + 1
            c.kinds[rec.kind] = (c.kinds[rec.kind] or 0) + 1
            if rec.source == "zed" then
                c.zed[rec.author] = (c.zed[rec.author] or 0) + 1
            else
                c.gameOpen = c.gameOpen + 1
                c.claimed[rec.author] = (c.claimed[rec.author] or 0) + 1
            end
        elseif rec.status == "Spam" then
            c.spam = c.spam + 1
        end
    end
    return c
end

local function line(md, list, who, text, extra)
    local e = { who = who, t = getTimestamp(), text = text }
    if extra then
        e.staff = extra.staff
        e.game = extra.game
    end
    list.n = list.n + 1
    list[list.n] = e
    md.chars = md.chars + #text
end

-- ---------------------------------------------------------------------------
-- WHERE THE FACTS ARE STAMPED: on the server, from the server's own player object
-- ---------------------------------------------------------------------------
-- (E3: no town source is proved yet. Until then the UI shows coordinates.)
local function placeName(x, y, z) return nil end

local function nearby(p, x, y, r)
    local out, me, list = { n = 0 }, p:getUsername(), getOnlinePlayers()
    for i = 0, list:size() - 1 do
        local o = list:get(i)
        local u = o:getUsername()
        if u ~= me then
            local dx, dy = o:getX() - x, o:getY() - y
            if dx * dx + dy * dy <= r * r and out.n < L.NEAR_MAX then
                out.n = out.n + 1
                out[out.n] = u
            end
        end
    end
    return out
end

local function stamp(p, rec, wantPlace)
    rec.author = p:getUsername()
    rec.filed  = getTimestamp()
    rec.day    = math.floor(getGameTime():getWorldAgeHours() / 24) + 1
    if wantPlace then
        local x, y, z = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
        rec.place = { x = x, y = y, z = z, name = placeName(x, y, z) }
        rec.near  = nearby(p, x, y, Tk.NEAR)
    end
end

-- ---------------------------------------------------------------------------
-- WHAT EACH PERSON RECEIVES: built field by field from an allowlist
-- ---------------------------------------------------------------------------
local function placeCopy(pl)
    if not pl then return nil end
    return { x = pl.x, y = pl.y, z = pl.z, name = pl.name }
end

local function threadCopy(list)
    local out = { n = list.n }
    for i = 1, list.n do
        local e = list[i]
        out[i] = { who = e.who, staff = e.staff, game = e.game, t = e.t, text = e.text }
    end
    return out
end

local function playerView(rec)
    return {
        id = rec.id, kind = rec.kind, st = Tk.PLAYER_ST[rec.status], day = rec.day, filed = rec.filed,
        place = placeCopy(rec.place), thread = threadCopy(rec.thread), can = Tk.canReply(rec.status) and true or false,
    }
end

local function staffView(rec)
    local near = nil
    if rec.near then
        near = { n = rec.near.n }
        for i = 1, rec.near.n do near[i] = rec.near[i] end
    end
    return {
        id = rec.id, source = rec.source, kind = rec.kind, author = rec.author, status = rec.status, day = rec.day,
        filed = rec.filed, updated = rec.updated, place = placeCopy(rec.place), near = near, assignee = rec.assignee,
        spamBy = rec.spamBy, gameId = rec.gameId, gameFiled = rec.gameFiled, gameAns = rec.gameAns, gameGone = rec.gameGone,
        unread = rec.unread, thread = threadCopy(rec.thread), notes = threadCopy(rec.notes),
    }
end

local function preview(s) return string.sub(s, 1, L.PREVIEW) end

-- pv marks a player's row: a staff member who filed a ticket receives both kinds
local function playerRow(rec)
    local th = rec.thread
    local r = { pv = true, id = rec.id, kind = rec.kind, st = Tk.PLAYER_ST[rec.status], day = rec.day,
        last = preview(th[th.n].text), replies = th.n - 1 }
    if Tk.isOpen(rec.status) and rec.gameFiled == nil then r.file = Tk.fileText(rec.kind, rec.id, th[1].text) end
    return r
end

local function staffRow(rec)
    return { id = rec.id, kind = rec.kind, author = rec.author, st = rec.status, day = rec.day, filed = rec.filed,
        where = Tk.whereText(rec.place), assignee = rec.assignee, first = preview(rec.thread[1].text),
        replies = rec.thread.n - 1, src = rec.source,
        unlinked = (rec.source == "zed" and rec.gameFiled and not rec.gameId and not rec.gameGone) or nil }
end

-- ---------------------------------------------------------------------------
-- THE PUSHES
-- ---------------------------------------------------------------------------
-- what the Log view needs of a ticket (ZeD_ServerLog.lua): its place, its time, who it found nearby. Never its words
function Srv.ticketFacts(id)
    local rec = open().tickets[id]
    if not rec then return nil end
    local near = {}
    for i = 1, (rec.near and rec.near.n or 0) do near[rec.near[i]] = true end
    return { id = rec.id, author = rec.author, filed = rec.filed, place = placeCopy(rec.place), near = near }
end

local function logTk(rec, what, who)
    local pl = rec.place
    Srv.action("ticket", who, what, "#" .. tostring(rec.id), tostring(rec.kind), pl and pl.x, pl and pl.y, pl and pl.z)
end

-- a game row taken in. Its author is a claim, not a proof (the row came through a staff client), so the line is the server's and
-- the name stays in its detail: it reads "not proved" and counts against no player's share or Who list
local function logAdopted(rec, author)
    Srv.action("ticket", Tk.SYS, "adopted from the game's window", "#" .. tostring(rec.id), tostring(rec.kind) .. ": " .. tostring(author))
end

local function toAuthor(rec, command, args)
    local o = Srv.player(rec.author)
    if o then Srv.to(o, Tk.MOD, command, args) end
end

local function pushStaffRow(md, rec)
    local c = tally(md)
    Srv.eachStaff(function(o)
        local r = staffRow(rec)
        r.open, r.spam, r.kinds = c.open, c.spam, c.kinds
        Srv.to(o, Tk.MOD, "t_row", r)
    end)
end

-- a changed ticket: its row to all staff with the counts, and to its author
local function pushRow(md, rec)
    pushStaffRow(md, rec)
    toAuthor(rec, "t_row", playerRow(rec))
end

-- the counts alone: staff only
local function pushCounts(md)
    local c = tally(md)
    Srv.eachStaff(function(o) Srv.to(o, Tk.MOD, "t_row", { open = c.open, spam = c.spam, kinds = c.kinds }) end)
end

-- the card to staff who have it open; eachStaff tests the power again, so a demoted client gets no more notes
local function pushCard(rec)
    Srv.eachStaff(function(o)
        if T.cards[o:getUsername()] == rec.id then Srv.to(o, Tk.MOD, "t_card", staffView(rec)) end
    end)
end

Srv.helloFill = function(p, r)
    local md = open()
    r.frozen = T.frozen and true or nil
    local ids, n = {}, 0
    local me = p:getUsername()
    for id, rec in pairs(md.tickets) do
        if rec.unread and rec.author == me then
            n = n + 1
            ids[n] = id
        end
    end
    table.sort(ids, function(a, b) return a > b end)
    if n > 0 then
        local out = {}
        for i = 1, math.min(n, 5) do out[i] = ids[i] end
        r.unread = out
    end
    if Srv.can(p, STAFF) then
        local c = tally(md)
        r.open, r.spam, r.kinds = c.open, c.spam, c.kinds
    end
end

-- ---------------------------------------------------------------------------
-- THE PLAYER'S COMMANDS
-- ---------------------------------------------------------------------------
local function reg(command, opts, fn) Srv.register(Tk.MOD, command, opts, fn) end

local function frozen(p, rid)
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return true end
    return false
end

local function recOf(md, id)
    if not Tk.whole(id) then return nil end
    return md.tickets[id]
end

-- a player's own ticket, or nil: someone else's answers exactly as one that does not exist
local function mine(p, md, id)
    local rec = recOf(md, id)
    if rec and rec.author == p:getUsername() then return rec end
    return nil
end

-- the cleaned text, or nil
local function goodText(s)
    local text = Tk.clean(s)
    if not text or #text < 1 or #text > L.TEXT_MAX then return nil end
    return text
end

-- one line a minute for the whole server, with how many were refused: a refused t_new starts no limit
local function fullLine(md, open, who)
    local t = getTimestampMs()
    T.fullN = (T.fullN or 0) + 1
    if T.fullAt and t - T.fullAt < L.MINUTE_MS then return end
    Srv.action("ticket", who, "tickets full", nil, tostring(open) .. " open, " .. tostring(md.chars) .. " characters; " .. tostring(T.fullN) .. " refused")
    T.fullAt, T.fullN = t, 0
end

reg("t_new", { limit = L.NEW_MS, mark = false }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local text = goodText(a.text)
    if not Tk.isKind(a.kind) or not text then
        if not Tk.isKind(a.kind) then Srv.bad(p, "t_new") end
        Srv.ack(p, rid, false, "text")
        return
    end
    local me = p:getUsername()
    local c = tally(md)
    if (c.zed[me] or 0) >= L.OPEN_PER_PLAYER then
        Srv.ack(p, rid, false, "many")
        return
    end
    if c.open >= L.OPEN_ALL or not playerRoom(md, #text) then
        fullLine(md, c.open, me)
        Srv.ack(p, rid, false, "full")
        return
    end
    local id = md.nextId
    md.nextId = id + 1
    local rec = { id = id, source = "zed", kind = a.kind, status = "Open", updated = getTimestamp(),
        thread = { n = 0 }, notes = { n = 0 } }
    stamp(p, rec, a.here == true)
    line(md, rec.thread, me, text)
    md.tickets[id] = rec
    Srv.mark(p, "t_new")
    Srv.ack(p, rid, true, nil, { id = id, file = Tk.fileText(rec.kind, id, text) })
    pushRow(md, rec)
    logTk(rec, "filed", me)
end)

reg("t_filed", {}, function(p, a, rid)
    local md = open()
    if T.frozen then return end
    local rec = mine(p, md, a.id)
    if not rec or rec.gameFiled then return end
    rec.gameFiled = true
    pushStaffRow(md, rec)            -- (it says unlinked: a staff client with the queue open reads the game's list)
end)

reg("t_mine", { limit = L.MINE_MS }, function(p, a, rid)
    local md = open()
    local me = p:getUsername()
    local list, n = {}, 0
    for _, rec in pairs(md.tickets) do
        if rec.author == me then
            n = n + 1
            list[n] = rec
        end
    end
    table.sort(list, function(x, y) return x.id > y.id end)
    local rows = {}
    local count = math.min(n, L.MINE_ROWS)
    for i = 1, count do rows[i] = playerRow(list[i]) end
    Srv.to(p, Tk.MOD, "t_mine", { n = count, rows = rows })
end)

reg("t_one", {}, function(p, a, rid)
    local rec = mine(p, open(), a.id)
    if not rec then
        if not Tk.whole(a.id) then Srv.bad(p, "t_one") end
        Srv.ack(p, rid, false, "gone")
        return
    end
    Srv.to(p, Tk.MOD, "t_one", playerView(rec))
    if rid then Srv.ack(p, rid, true) end
end)

reg("t_reply", { limit = L.REPLY_MS, mark = false }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local rec = mine(p, md, a.id)
    if not rec then
        if not Tk.whole(a.id) then Srv.bad(p, "t_reply") end
        Srv.ack(p, rid, false, "gone")
        return
    end
    if not Tk.canReply(rec.status) then Srv.ack(p, rid, false, "state"); return end
    local text = goodText(a.text)
    if not text then Srv.ack(p, rid, false, "text"); return end
    if rec.thread.n >= L.THREAD_MAX or not playerRoom(md, #text, rec) then Srv.ack(p, rid, false, "full"); return end
    line(md, rec.thread, p:getUsername(), text)
    if rec.status == "Answered" then rec.status = "Progress" end   -- (only with E12 on: back in the queue)
    rec.updated = getTimestamp()
    Srv.mark(p, "t_reply")
    Srv.ack(p, rid, true)
    Srv.to(p, Tk.MOD, "t_one", playerView(rec))
    pushRow(md, rec)
    pushCard(rec)
    logTk(rec, "player added to it", p:getUsername())
end)

reg("t_read", {}, function(p, a, rid)
    local md = open()
    if T.frozen then return end
    local rec = mine(p, md, a.id)
    if rec then rec.unread = nil end
end)

-- ---------------------------------------------------------------------------
-- THE STAFF'S COMMANDS
-- ---------------------------------------------------------------------------
local function okName(s) return s == nil or (type(s) == "string" and #s <= L.FIND_MAX) end

-- the option as the server holds it (the client's copy may not carry it)
local function noSave()
    local so = getServerOptions()
    if not so then return false end
    local ok, n = pcall(function() return so:getInteger("SaveWorldEveryMinutes") end)
    return ok and n == 0
end

local function matches(rec, q, me)
    local st = rec.status
    if q.status == "Open" then
        if not Tk.isOpen(st) then return false end
    elseif q.status == "All" then
        if st == "Spam" then return false end
    elseif st ~= q.status then
        return false
    end
    if q.kind and rec.kind ~= q.kind then return false end
    if q.who and rec.author ~= q.who then return false end
    if q.mine == "ME" and rec.assignee ~= me then return false end
    if q.mine == "NOBODY" and rec.assignee then return false end
    if q.find then
        if string.find(string.lower(rec.author), q.find, 1, true) then return true end
        for i = 1, rec.thread.n do
            if string.find(string.lower(rec.thread[i].text), q.find, 1, true) then return true end
        end
        return false
    end
    return true
end

reg("t_queue", { cap = STAFF, limit = L.QUEUE_MS }, function(p, a, rid)
    local md = open()
    local me = p:getUsername()
    local status = a.status
    if status == nil then status = "Open" end
    local kindOk = a.kind == nil or Tk.isKind(a.kind) or a.kind == Tk.NONE
    local mineOk = a.mine == nil or a.mine == "ME" or a.mine == "NOBODY"
    local pageOk = a.page == nil or Tk.whole(a.page)
    if type(status) ~= "string" or not Tk.QUEUE_ST[status] or not kindOk or not mineOk or not pageOk
        or not okName(a.who) or not okName(a.find) then
        Srv.bad(p, "t_queue")
        Srv.ack(p, rid, false, "text")
        return
    end
    local q = { status = status, kind = a.kind, who = a.who, mine = a.mine, find = a.find and string.lower(a.find) or nil }
    if q.find == "" then q.find = nil end
    local list, n = {}, 0
    local seen, authors, an = {}, {}, 0
    for _, rec in pairs(md.tickets) do
        if matches(rec, q, me) then
            n = n + 1
            list[n] = rec
        end
        if not seen[rec.author] then
            seen[rec.author] = true
            an = an + 1
            authors[an] = rec.author
        end
    end
    if a.newest == false then
        table.sort(list, function(x, y) return x.id < y.id end)
    else
        table.sort(list, function(x, y) return x.id > y.id end)
    end
    local pages = math.max(1, math.ceil(n / L.PAGE_ROWS))
    local page = math.min(a.page or 1, pages)
    local rows = {}
    local from = (page - 1) * L.PAGE_ROWS
    for i = 1, math.min(L.PAGE_ROWS, n - from) do rows[i] = staffRow(list[from + i]) end
    local c = tally(md)
    local r = { page = page, pages = pages, n = n, rows = rows, open = c.open, spam = c.spam, kinds = c.kinds,
        gameMax = md.gameMax, skipped = md.skipped, noSave = noSave() }
    if page == 1 then
        table.sort(authors)
        local out = {}
        for i = 1, math.min(an, L.AUTHORS_MAX) do out[i] = authors[i] end
        r.authors = out
    end
    Srv.to(p, Tk.MOD, "t_queue", r)
end)

-- the record of a staff command that writes, or nil with the answer sent
local function acting(p, a, rid, allowed)
    local md = open()
    if frozen(p, rid) then return nil end
    local rec = recOf(md, a.id)
    if not rec then
        if not Tk.whole(a.id) then Srv.bad(p, "ticket id") end
        Srv.ack(p, rid, false, "gone")
        return nil
    end
    if allowed and not allowed(rec.status) then
        Srv.ack(p, rid, false, "state")
        return nil
    end
    return rec, md
end

-- after a change: the card to the asker and all staff with it open, the row both ways
local function changed(p, md, rec, rid, what)
    rec.updated = getTimestamp()
    evict(md, 0, rec)
    Srv.ack(p, rid, true)
    T.cards[p:getUsername()] = rec.id
    pushCard(rec)
    pushRow(md, rec)
    logTk(rec, what, p:getUsername())
end

reg("t_card", { cap = STAFF }, function(p, a, rid)
    local md = open()
    local rec = recOf(md, a.id)
    if not rec then
        if not Tk.whole(a.id) then Srv.bad(p, "t_card") end
        Srv.ack(p, rid, false, "gone")
        return
    end
    T.cards[p:getUsername()] = rec.id
    if rec.status == "Open" and not T.frozen then
        rec.status = "Seen"
        rec.updated = getTimestamp()
        Srv.to(p, Tk.MOD, "t_card", staffView(rec))
        pushRow(md, rec)
        logTk(rec, "seen", p:getUsername())
    else
        Srv.to(p, Tk.MOD, "t_card", staffView(rec))
    end
    if rid then Srv.ack(p, rid, true) end
end)

-- the card closed: only this ends its pushes
reg("t_cardoff", { cap = STAFF }, function(p, a, rid) T.cards[p:getUsername()] = nil end)

reg("t_take", { cap = STAFF }, function(p, a, rid)
    local rec, md = acting(p, a, rid, Tk.isOpen)
    if not rec then return end
    rec.status = "Progress"
    rec.assignee = p:getUsername()
    changed(p, md, rec, rid, "taken")
end)

reg("t_answer", { cap = STAFF }, function(p, a, rid)
    local rec, md = acting(p, a, rid, Tk.canAnswer)
    if not rec then return end
    local text = goodText(a.text)
    if not text then Srv.ack(p, rid, false, "text"); return end
    if rec.thread.n >= L.THREAD_MAX or not room(md, #text, rec) then Srv.ack(p, rid, false, "full"); return end
    local me = p:getUsername()
    line(md, rec.thread, me, text, { staff = true })
    rec.status = "Answered"
    rec.assignee = rec.assignee or me
    rec.unread = true
    rec.updated = getTimestamp()
    -- the one game answer (A4): the first, while the record is linked and has none
    local first = rec.gameId ~= nil and rec.gameAns == nil
    if first then rec.gameAns = true end
    evict(md, 0, rec)
    Srv.ack(p, rid, true, nil, { first = first, gameId = rec.gameId })
    T.cards[me] = rec.id
    pushCard(rec)
    pushRow(md, rec)
    toAuthor(rec, "t_note", { id = rec.id, who = me })
    toAuthor(rec, "t_one", playerView(rec))
    logTk(rec, "answered", me)
end)

reg("t_addnote", { cap = STAFF }, function(p, a, rid)
    local rec, md = acting(p, a, rid)
    if not rec then return end
    local text = goodText(a.text)
    if not text then Srv.ack(p, rid, false, "text"); return end
    if rec.notes.n >= L.NOTES_MAX or not room(md, #text, rec) then Srv.ack(p, rid, false, "full"); return end
    line(md, rec.notes, p:getUsername(), text)
    rec.updated = getTimestamp()
    Srv.ack(p, rid, true)
    T.cards[p:getUsername()] = rec.id
    pushCard(rec)
    logTk(rec, "note added", p:getUsername())
end)

-- a line from the Log view, as an admin note: t_addnote's road. true, or false and the answer's word
function Srv.ticketNote(p, id, text)
    local md = open()
    if T.frozen then return false, "frozen" end
    local rec = md.tickets[id]
    if not rec then return false, "gone" end
    for i = 1, rec.notes.n do
        if rec.notes[i].text == text then return false, "added" end
    end
    if rec.notes.n >= L.NOTES_MAX or not room(md, #text, rec) then return false, "full" end
    line(md, rec.notes, p:getUsername(), text)
    rec.updated = getTimestamp()
    T.cards[p:getUsername()] = rec.id
    pushCard(rec)
    logTk(rec, "note added", p:getUsername())
    return true
end

reg("t_close", { cap = STAFF }, function(p, a, rid)
    local rec, md = acting(p, a, rid, Tk.canClose)
    if not rec then return end
    rec.status = "Closed"
    changed(p, md, rec, rid, "closed")
end)

reg("t_reopen", { cap = STAFF }, function(p, a, rid)
    local rec, md = acting(p, a, rid, function(st) return st == "Answered" or st == "Closed" end)
    if not rec then return end
    rec.status = "Progress"
    changed(p, md, rec, rid, "reopened")
end)

reg("t_spam", { cap = STAFF }, function(p, a, rid)
    local rec, md = acting(p, a, rid, function(st) return st ~= "Spam" end)
    if not rec then return end
    rec.status = "Spam"
    rec.spamBy = p:getUsername()
    rec.unread = nil
    rec.updated = getTimestamp()
    evict(md, 0, rec)
    Srv.ack(p, rid, true)
    pushCard(rec)
    pushRow(md, rec)                 -- (the author's row reads Closed: playerRow maps it)
    logTk(rec, "marked spam", p:getUsername())
end)

reg("t_unspam", { cap = STAFF }, function(p, a, rid)
    local rec, md = acting(p, a, rid, function(st) return st == "Spam" end)
    if not rec then return end
    rec.status = "Open"
    rec.spamBy = nil
    changed(p, md, rec, rid, "not spam")
end)

-- a ticket deleted with no game link: its row may exist, or come later (the author's client files after the ack). The
-- next sync finds it by its tag and a staff client removes it. A few only: the oldest goes
local function tomb(md, rec)
    local n, low = 0, nil
    for id in pairs(md.tombs) do
        n = n + 1
        if not low or id < low then low = id end
    end
    if n >= L.TOMBS_MAX then md.tombs[low] = nil end
    md.tombs[rec.id] = rec.author
end

reg("t_delete", { cap = ADMIN }, function(p, a, rid)
    local rec, md = acting(p, a, rid)
    if not rec then return end
    local id, author = rec.id, rec.author
    if rec.source == "zed" and not rec.gameId and not rec.gameGone then tomb(md, rec) end
    Srv.ack(p, rid, true, nil, { gameId = rec.gameId })
    logTk(rec, "deleted", p:getUsername())
    drop(md, rec)
    local told = false
    Srv.eachStaff(function(o)
        if o:getUsername() == author then told = true end
        Srv.to(o, Tk.MOD, "t_gone", { id = id })
    end)
    if not told then
        local o = Srv.player(author)
        if o then Srv.to(o, Tk.MOD, "t_gone", { id = id }) end
    end
    pushCounts(md)
end)

-- ---------------------------------------------------------------------------
-- THE GAME'S SIDE (B8): matching is the server's job. Only the server holds every record
-- ---------------------------------------------------------------------------
-- gameClaim: the game's side showed an answer, already in notes. It is not gameAns, so a forged row costs no first answer
local function linksOf()
    local out = {}
    for g, rec in pairs(T.byGame) do out[g] = rec.gameAns == true or rec.gameClaim == true end
    return out
end

local function cut(s) return string.sub(Tk.clean(s) or "", 1, L.TEXT_MAX) end

-- a game ticket with no record of ours. Its author and any answer are claims. Status needs viewed, the one field a
-- plain client cannot set, so a griefer cannot answer a ticket out of the Open queue. Any answer goes in notes, marked
-- as the game's, for staff only: viewed says staff opened the ticket, not who wrote an answer added after that (B8).
local function adopt(md, r, c)
    local kind, _, rest = Tk.parse(r.m)
    if not Tk.isKind(kind) then kind, rest = Tk.NONE, r.m end
    local author = Tk.name(r.a)
    local text = cut(rest)
    local answer = type(r.at) == "string" and cut(r.at) or ""
    local status = (r.v == true) and "Seen" or "Open"
    if c.open >= L.OPEN_ALL or c.gameOpen >= L.ADOPT_OPEN or (c.claimed[author] or 0) >= L.ADOPT_PER_AUTHOR then
        md.skipped = md.skipped + 1
        return
    end
    if not playerRoom(md, #text + #answer) then
        md.skipped = md.skipped + 1
        return
    end
    local id = md.nextId
    md.nextId = id + 1
    local rec = { id = id, source = "game", kind = kind, author = author, status = status, updated = getTimestamp(),
        gameId = r.g, gameFiled = true, thread = { n = 0 }, notes = { n = 0 } }
    line(md, rec.thread, author, text, { game = true })
    rec.thread[1].t = nil            -- (no time came with it)
    if type(r.aw) == "string" or answer ~= "" then rec.gameClaim = true end
    if answer ~= "" then line(md, rec.notes, Tk.name(r.aw), answer, { game = true }) end
    md.tickets[id] = rec
    T.byGame[r.g] = rec
    c.open = c.open + 1
    c.gameOpen = c.gameOpen + 1
    c.claimed[author] = (c.claimed[author] or 0) + 1
    logAdopted(rec, author)
end

-- a record meets its game row. What staff did before the link is owed to that row: viewed, and the one answer
local function link(rec, g, c)
    rec.gameId = g
    rec.gameFiled = true
    rec.gameGone = nil
    T.byGame[g] = rec
    local text = nil
    if rec.gameAns == nil then
        for i = 1, rec.thread.n do
            if rec.thread[i].staff then
                text = rec.thread[i].text
                break
            end
        end
    end
    if text then rec.gameAns = true end
    if text or rec.status ~= "Open" then
        c.owe[#c.owe + 1] = { g = g, view = rec.status ~= "Open", text = text and Tk.answerText(text) or nil }
    end
end

local function syncRow(md, r, c)
    if type(r) ~= "table" or not Tk.whole(r.g) or type(r.a) ~= "string" or type(r.m) ~= "string" then return end
    local g = r.g
    if g <= md.gameMax then return end
    if not T.byGame[g] then
        local _, id = Tk.parse(r.m)
        local rec = id and md.tickets[id]
        if rec and rec.source == "zed" and not rec.gameId and rec.author == r.a and Tk.fileMatches(rec, r.m) then
            link(rec, g, c)
        elseif id and not rec and id < md.nextId then
            -- its record was deleted or evicted before the link: dealt with, not a new ticket. (A crash that rolled nextId
            -- back still adopts: the id is then at or above it.) A deleted one's row goes from the game as well
            if md.tombs[id] == r.a then
                md.tombs[id] = nil
                c.remove[#c.remove + 1] = { g = g, id = id }
            end
        else
            adopt(md, r, c)
        end
    end
    md.gameMax = g                   -- ids are never reused, so this one number stops any row coming back
end

local function resetLinks(md)
    for _, rec in pairs(md.tickets) do rec.gameId = nil end
    T.byGame = {}
    md.gameMax = 0
    Srv.action("ticket", Tk.SYS, "the game's ticket database was replaced", nil, "links cleared, matching again by tag")
end

-- is any of these rows, under a linked id, not the record linked to it? Only that proves a replaced database. A top
-- below gameMax means no more than that the newest ticket was removed
local function replacedDb(rows)
    for i = 1, L.SYNC_ROWS do
        local r = rows[i]
        if type(r) == "table" and Tk.whole(r.g) and type(r.a) == "string" and type(r.m) == "string" then
            local rec = T.byGame[r.g]
            if rec and not Tk.sameTicket(r.a, r.m, rec) then return true end
        end
    end
    return false
end

reg("t_sync", { cap = STAFF, limit = L.SYNC_MS }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local rows = type(a.rows) == "table" and a.rows or {}
    if a.reset == true then
        local replaced = replacedDb(rows)
        if replaced then
            resetLinks(md)
        elseif a.lower == true and type(a.top) == "number" and a.top >= 0 and a.top == math.floor(a.top) and a.top < md.gameMax then
            md.gameMax = a.top       -- (two full lists agree the newest went: ids are never reused, so nothing comes back)
        end
        Srv.ack(p, rid, true)
        Srv.to(p, Tk.MOD, "t_syncd", { links = linksOf(), gameMax = md.gameMax, reset = replaced or nil, same = (not replaced) or nil })
        return
    end
    local c = tally(md)
    c.remove, c.owe = {}, {}
    for i = 1, L.SYNC_ROWS do
        if rows[i] then syncRow(md, rows[i], c) end
    end
    evict(md, 0)
    Srv.ack(p, rid, true, nil, { remove = (#c.remove > 0) and c.remove or nil, owe = (#c.owe > 0) and c.owe or nil })
    if a.done == true then
        Srv.to(p, Tk.MOD, "t_syncd", { links = linksOf(), gameMax = md.gameMax })
    end
    pushCounts(md)
end)

reg("t_gamediff", { cap = STAFF, limit = L.DIFF_MS }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    if type(a.gone) == "table" then
        for i = 1, L.DIFF_ROWS do
            local g = a.gone[i]
            local rec = Tk.whole(g) and T.byGame[g] or nil
            if rec then
                T.byGame[g] = nil
                rec.gameId = nil
                rec.gameGone = true
                rec.updated = getTimestamp()
                logTk(rec, "removed on the game's window", p:getUsername())
                pushCard(rec)
            end
        end
    end
    local differs = false
    if type(a.ans) == "table" then
        for i = 1, L.DIFF_ROWS do
            local e = a.ans[i]
            local rec = type(e) == "table" and Tk.whole(e.g) and T.byGame[e.g] or nil
            if rec and type(e.text) == "string" and type(e.a) == "string" and type(e.m) == "string" then
                if not Tk.sameTicket(e.a, e.m, rec) then
                    differs = true
                elseif not rec.gameAns and not rec.gameClaim then
                    rec.gameClaim = true
                    local text = cut(e.text)
                    if text ~= "" and rec.notes.n < L.NOTES_MAX and playerRoom(md, #text, rec) then
                        line(md, rec.notes, Tk.name(e.who), text, { game = true })
                    end
                    rec.updated = getTimestamp()
                    pushCard(rec)
                end
            end
        end
    end
    Srv.ack(p, rid, true)
    if differs then
        -- (a row under a linked id that is another ticket: the answer stays out of this record, and the rows match afresh)
        resetLinks(md)
        Srv.to(p, Tk.MOD, "t_syncd", { links = linksOf(), gameMax = md.gameMax, reset = true })
    end
    pushCounts(md)
end)

-- a player's tickets for their card (Phase 2): staff rows, the newest first, at most n. Rows only: the card has its own t_card
function Srv.ticketsOf(user, n)
    local md = open()
    local list, c = {}, 0
    for _, rec in pairs(md.tickets) do
        if rec.author == user then
            c = c + 1
            list[c] = rec
        end
    end
    table.sort(list, function(x, y) return x.id > y.id end)
    local rows = {}
    for i = 1, math.min(c, n) do rows[i] = staffRow(list[i]) end
    return rows, c
end

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
if Srv.modDataHooked == nil then
    Srv.modDataHooked = true
    Events.OnInitGlobalModData.Add(function() if ZeD.Srv.openTickets then ZeD.Srv.openTickets() end end)
end
Srv.openTickets = open

return T
