-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Tickets.lua
-- ============================================================================
-- TICKETS, THE CLIENT'S MODEL (ZeDUI/MP_SERVER_PART_DESIGN.md, B7 to B9). No drawing: the cards (ZeD_TicketCards.lua)
-- read this and call it.
--
-- The server holds ZeD's record. The game's own ticket can only be touched from a client (A4), so this file does that
-- work: the player's client files the game's ticket, a staff client reads the game's list and reports it, and acts on
-- the game's row after the server's ack (viewed, the one answer, remove).
--
-- The game's reply is one untagged event, ViewTickets, and only some replies hold the whole list (A4). So every game
-- call goes through one queue here, one in flight at a time, and each says what its reply is. A reply nobody here asked
-- for (the game's own window) is left alone. Before any game call on a ticket the staff client finds that row in its
-- latest full list and tests it against the record (Tk.sameTicket): no row, or a row that differs, no call.
--
-- Without the server part (B9) the same calls fall back to the game's one question and one answer.
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/Tr"
require "ZeD/ZeD_Messages"
require "ISUI/AdminPanel/ISAdminMessage"

ZeD = ZeD or {}
ZeD.Tickets = ZeD.Tickets or {}
local C = ZeD.Tickets
local S = ZeD.ServerPart
local Tk = ZeD.Tk
local L = Tk.LIMITS

local REPLY_MS = 10000        -- no answer in this long reads as fail, and any typed text stays
local BATCH_MS = 1100         -- between t_sync and t_gamediff batches (the server's limit is one a second)
local TWO_LISTS_MS = 10000    -- two full lists this far apart before anything counts as gone
local NOTE_EVERY_MS = 10000   -- "a new ticket" on the belt, at most this often: addTicket has no limit
local ADMIN_POLL_MS = 10000   -- without the server part, the Admin tab's list asks again this often
local SOON_MS = 2000          -- an unlinked ticket reaches the queue: the game's list is read after this, at most this often
local SYNC_TRIES = 5          -- a batch with no answer goes again this many times
local SEEING_MS = 1500        -- a player's card drawn this recently is on screen

C.seq = C.seq or 0            -- bumps on every change (the cards re-read)
C.rowSeq = C.rowSeq or 0      -- bumps on every t_row (the queue's page may be stale)
C.mine = C.mine or {}         -- my rows, newest first
C.one = C.one or {}           -- id -> my ticket as the server last sent it
C.queue = C.queue or nil      -- the staff's queue page as last sent
C.card = C.card or nil        -- the staff card as last sent
C.counts = C.counts or { open = 0, spam = 0 }
C.list = C.list or nil        -- the latest full game list: { rows, byId, top, at }
C.gameMax = C.gameMax or 0
C.absent = C.absent or {}     -- game id -> when a list first lacked it
C.pend = C.pend or {}         -- rid -> { cmd, cb, at }

local fifo = {}               -- game calls waiting
local busy = nil              -- the one game call in flight
local ridNext = 0
local filedTried = {}         -- ticket id -> this session already filed it or is about to
local checked = {}            -- ticket id -> this session already looked for it in the game's list
local waitRow = {}            -- game calls waiting for a list that holds their row
local diffQ = {}              -- t_gamediff batches waiting
local diffAt = 0
local lastNote = nil

local function now() return getTimestampMs() end
local function bump() C.seq = C.seq + 1 end
local function myName()
    local p = getPlayer()
    return p and p:getUsername() or nil
end

-- ---------------------------------------------------------------------------
-- COMMANDS TO THE SERVER
-- ---------------------------------------------------------------------------
-- cb gets the t_ack, or { ok = false, err = "fail" } after REPLY_MS. Returns the rid.
function C.request(cmd, args, cb) return C.requestOn(Tk.MOD, cmd, args, cb) end

-- the same for another module of the server part: every answer comes back as this one t_ack
function C.requestOn(module, cmd, args, cb)
    ridNext = ridNext + 1
    local rid = ridNext
    args = args or {}
    args.rid = rid
    C.pend[rid] = { cmd = cmd, cb = cb, at = now() }
    if not S.send(module, cmd, args) then
        C.pend[rid] = nil
        if cb then cb({ ok = false, err = "fail" }) end
        return nil
    end
    return rid
end

-- the words for an error from the server (B6)
function C.errText(err, left)
    local key = "UI_ZeD_Tk_Err_" .. tostring(err or "fail")
    if err == "many" then return ZeD.tr(key, L.OPEN_PER_PLAYER) end
    if err == "text" then return ZeD.tr(key, L.TEXT_MAX) end
    if err == "wait" then return ZeD.tr(key, left or 1) end
    return ZeD.tr(key)
end

-- ---------------------------------------------------------------------------
-- THE GAME'S SIDE: one call in flight
-- ---------------------------------------------------------------------------
local function pump()
    if busy or #fifo == 0 then return end
    busy = table.remove(fifo, 1)
    busy.at = now()
    local ok, err = pcall(busy.run)
    if not ok then
        busy = nil
        ZeD.logOnce("tickets: game call", err)
    end
end

-- entry: run (the call), got (function(rows, byId, top), its reply)
local function gameCall(entry)
    fifo[#fifo + 1] = entry
    pump()
end

local function readList(list)
    local rows, byId, top = {}, {}, 0
    for i = 0, list:size() - 1 do
        local t = list:get(i)
        local g = t:getTicketID()
        local row = { g = g, a = t:getAuthor() or "", m = t:getMessage() or "", v = t:isViewed() == true }
        local ans = t:getAnswer()
        if ans then
            row.aw = ans:getAuthor() or ""
            row.at = ans:getMessage() or ""
        end
        rows[#rows + 1] = row
        byId[g] = row
        if g > top then top = g end
    end
    table.sort(rows, function(x, y) return x.g < y.g end)
    return rows, byId, top
end

function C.onViewTickets(list)
    local ok, rows, byId, top = pcall(readList, list)
    local b = busy
    busy = nil
    if b and b.full and C.gameSilent then
        C.gameSilent = nil
        bump()
    end
    if ok and b and b.got then
        local okGot, err = pcall(b.got, rows, byId, top)
        if not okGot then ZeD.logOnce("tickets: the game's reply", err) end
    elseif not ok then
        ZeD.logOnce("tickets: reading the game's list", rows)
    end
    pump()
end

-- a call on a row, kept until a full list holds that row; a row that differs from the record gets no call
local function flushWaiting()
    if #waitRow == 0 then return end
    local list = waitRow
    waitRow = {}
    for _, w in ipairs(list) do
        local row = C.list.byId[w.g]
        if row and Tk.sameTicket(row.a, row.m, w.rec) then w.fn(row) end
    end
end

-- a reply that holds the whole list
local function fullList(rows, byId, top)
    C.list = { rows = rows, byId = byId, top = top, at = now() }
    flushWaiting()
    bump()
end

local function askFull(after)
    gameCall({
        full = true,
        run = function() getTickets(nil) end,
        got = function(rows, byId, top)
            fullList(rows, byId, top)
            if after then after() end
        end,
    })
end

local function withRow(g, rec, fn)
    if not g or not rec then return end
    local row = C.list and C.list.byId[g]
    if row then
        if Tk.sameTicket(row.a, row.m, rec) then fn(row) end
        return
    end
    waitRow[#waitRow + 1] = { g = g, rec = rec, fn = fn }
    askFull()
end

-- ---------------------------------------------------------------------------
-- FILING (B8, the player's side). The record decides: a ticket is filed while gameFiled is nil on the server, so one
-- an admin removed on the game's window does not come back at its author's next login.
-- ---------------------------------------------------------------------------
local function confirmFiled(rows, id, file)
    for _, row in ipairs(rows) do
        if row.m == file then
            S.send(Tk.MOD, "t_filed", { id = id })
            return true
        end
    end
    return false
end

local function fileGame(id, file)
    if type(file) ~= "string" or not Tk.whole(id) or filedTried[id] then return end
    filedTried[id] = true
    local me = myName()
    if not me then return end
    gameCall({
        run = function() addTicket(me, file, -1) end,
        got = function(rows) confirmFiled(rows, id, file) end,
    })
end

-- rows from t_mine that still carry their text: the client left before filing, or before the game's reply came. The
-- game's list is read first, so a filing whose reply was lost is not filed twice.
local function checkFiled(list)
    local me = myName()
    if not me or #list == 0 then return end
    gameCall({
        run = function() getTickets(me) end,
        got = function(rows)
            for _, e in ipairs(list) do
                if not confirmFiled(rows, e.id, e.file) then fileGame(e.id, e.file) end
            end
        end,
    })
end

-- ---------------------------------------------------------------------------
-- THE PLAYER
-- ---------------------------------------------------------------------------
-- the game's own row, in my rows' shape
local function gameMineRow(row)
    local kind, _, rest = Tk.parse(row.m)
    if not Tk.isKind(kind) then kind, rest = Tk.NONE, row.m end
    -- (viewed is the one field a plain client cannot set: without it an answer is the game's claim, not an answer, B9)
    local answered = row.aw ~= nil and row.v == true
    return { id = row.g, kind = kind, last = string.sub(row.aw and row.at or rest, 1, L.PREVIEW),
        st = (answered and "Answered") or (row.v and "Seen") or "Sent", replies = row.aw and 1 or 0, game = true,
        text = rest, ansWho = row.aw, ansText = row.at, claim = (row.aw ~= nil and not row.v) or nil }
end

-- a filing on a frozen server: ZeD's rows stay readable, and the new one goes on top
local function addGameRow(rows, msg)
    for i = #rows, 1, -1 do
        if rows[i].m == msg then
            table.insert(C.mine, 1, gameMineRow(rows[i]))
            break
        end
    end
    bump()
end

-- Send. Answers "wait" while the link is unknown and "text" for words the server would refuse, both with the typed
-- text kept; otherwise "sent", with done(ack) to come. Keeps the fallback's path for frozen, as B9 says.
-- report: from chat (Phase 5), the name and the lines around it. Only the server part keeps it: a game ticket is public
function C.ask(kind, here, text, done, report)
    if S.present == nil and not S.forceOff then return "wait" end
    local clean = Tk.clean(text)
    if not Tk.isKind(kind) or not clean or #clean < 1 or #clean > L.TEXT_MAX then return "text" end
    if S.available() and not S.frozen then
        C.request("t_new", { kind = kind, here = here == true, text = clean, report = report }, function(a)
            if a.ok then fileGame(a.id, a.file) end
            if done then done(a) end
            bump()
        end)
        return "sent"
    end
    local me = myName()
    if not me then return "wait" end
    local p, x, y = getPlayer(), nil, nil
    if here == true and p then x, y = math.floor(p:getX()), math.floor(p:getY()) end
    local msg = Tk.plainTag(kind, clean, x, y)
    local frozen = S.available()
    gameCall({
        run = function() addTicket(me, msg, -1) end,
        got = function(rows)
            if frozen then addGameRow(rows, msg) else C.fallbackMine(rows) end
        end,
    })
    if done then done({ ok = true, fallback = true }) end
    return "sent"
end

-- the game's own list of mine, in my rows' shape (B9): kind from the tag, viewed gives Seen, an answer gives Answered
function C.fallbackMine(rows)
    local out = {}
    for i = #rows, 1, -1 do out[#out + 1] = gameMineRow(rows[i]) end
    C.mine = out
    bump()
end

function C.loadMine()
    if S.available() then
        S.send(Tk.MOD, "t_mine", {})
        return
    end
    local me = myName()
    if not me then return end
    gameCall({ run = function() getTickets(me) end, got = function(rows) C.fallbackMine(rows) end })
end

function C.loadOne(id, cb) return C.request("t_one", { id = id }, cb) end
function C.reply(id, text, cb) return C.request("t_reply", { id = id, text = Tk.clean(text) }, cb) end
function C.read(id) S.send(Tk.MOD, "t_read", { id = id }) end
-- the player's card says it is on screen, each frame: an answer read there needs no note
function C.onCard(id) C.seeId, C.seeAt = id, now() end
function C.seeing(id) return C.seeId == id and C.seeAt ~= nil and now() - C.seeAt < SEEING_MS end

-- the note's Open: read, and to the Server tab, where the ticket card opens (C.openId says which)
function C.openNote(item)
    if not item then return end
    item.read = true
    C.read(item.id)
    C.loadOne(item.id)
    C.openId = item.id
    bump()
    if ZeD_CharacterWindow and ZeD_CharacterWindow.openTab then pcall(ZeD_CharacterWindow.openTab, 0, "server") end
end

-- ---------------------------------------------------------------------------
-- THE STAFF: the queue. Every change arrives as t_row; getTickets(nil) runs only on opening and on Refresh.
-- ---------------------------------------------------------------------------
local pumpSync, compare       -- (below; hoisted for what calls them)

local function startBatches(delay)
    local l = C.list
    if not l then return end
    local rows = {}
    for _, r in ipairs(l.rows) do
        if r.g > C.gameMax then rows[#rows + 1] = r end
    end
    C.sync = { rows = rows, i = 1, top = l.top, nextAt = delay or 0, tries = 0 }
    pumpSync()
end

local function cutRow(s) return s and string.sub(s, 1, L.SYNC_CUT) or nil end

-- After every sync: up to 20 rows that sit under a linked id go to the server, the newest first. A row that is not its
-- record proves the game's table was replaced, whatever its top says; only the server can test that. lower says two
-- full lists agree the top is below gameMax: the newest ticket was removed.
local function startProof()
    local l = C.list
    if not l or not C.queueOpen then return end
    local proof, n = {}, 0
    for i = #l.rows, 1, -1 do
        local r = l.rows[i]
        if C.links[r.g] ~= nil and n < L.SYNC_ROWS then
            n = n + 1
            proof[n] = r
        end
    end
    local lower = C.wantLower
    C.wantLower = nil
    if n == 0 and not lower then
        compare(C.links)
        return
    end
    C.sync = { rows = proof, i = 1, top = l.top, nextAt = now() + BATCH_MS, tries = 0, proof = true, lower = lower }
end

-- a full list, for the queue: what the server has not dealt with goes in batches
local function afterList()
    if not C.queueOpen then return end
    local l = C.list
    if l.top < C.gameMax then
        if C.lowAt and l.at - C.lowAt >= TWO_LISTS_MS then
            C.lowAt = nil
            C.wantLower = true
        else
            C.lowAt = C.lowAt or l.at
            C.recheckAt = now() + TWO_LISTS_MS
        end
    else
        C.lowAt = nil
    end
    startBatches()
end

local function syncList() askFull(afterList) end

-- a staff client is the only hands the game's table has: what a batch's ack says the row is owed
local function settleRows(a)
    local l = C.list
    if not l then return end
    for _, e in ipairs(a.remove or {}) do
        local row = l.byId[e.g]
        local _, id = Tk.parse(row and row.m)
        if id == e.id then gameCall({ run = function() removeTicket(e.g) end, got = fullList }) end
    end
    local me = myName()
    for _, e in ipairs(a.owe or {}) do
        local row = l.byId[e.g]
        if row and me then
            if e.view and not row.v then
                row.v = true
                gameCall({ run = function() viewedTicket(me, e.g) end, got = fullList })
            end
            if e.text then gameCall({ run = function() addTicket(me, e.text, e.g) end, got = fullList }) end
        end
    end
end

-- One batch out at a time, and the next only after its ack: gameMax is a watermark, so a batch the general limit drops
-- must never be passed by the one after it. A refused or unanswered batch goes again, the same rows.
pumpSync = function()
    local y = C.sync
    if not y or y.waiting or now() < y.nextAt then return end
    local to, batch, n = y.i, {}, 0
    while n < L.SYNC_ROWS and to <= #y.rows do
        local r = y.rows[to]
        n = n + 1
        batch[n] = { g = r.g, a = cutRow(r.a), m = cutRow(r.m), v = r.v, aw = cutRow(r.aw), at = cutRow(r.at) }
        to = to + 1
    end
    local done = to > #y.rows
    y.waiting = true
    C.request("t_sync", { rows = batch, top = y.top, done = done, reset = y.proof, lower = y.lower }, function(a)
        settleRows(a)
        if C.sync ~= y then return end
        y.waiting = false
        y.nextAt = now() + BATCH_MS
        if a.ok == false then
            y.tries = y.tries + 1
            if (a.err ~= "wait" and a.err ~= "fail") or y.tries > SYNC_TRIES then C.sync = nil end
            return
        end
        y.i, y.tries = to, 0
        if done then C.sync = nil end
    end)
end

local function queueDiff(gone, ans)
    local i, j = 1, 1
    while i <= #gone or j <= #ans do
        local g, a = {}, {}
        while #g < L.DIFF_ROWS and i <= #gone do g[#g + 1] = gone[i]; i = i + 1 end
        while #a < L.DIFF_ROWS and j <= #ans do a[#a + 1] = ans[j]; j = j + 1 end
        diffQ[#diffQ + 1] = { gone = g, ans = a }
    end
end

-- what the game holds against what the server has linked. Runs once the server has said the table is the same one, so
-- a linked id missing from two lists is gone, above the list's top too (a link made after a list was fetched shows in
-- the second). An answer goes with its row: the server tests that row against the record before it writes.
compare = function(links)
    local l = C.list
    if not l then return end
    local gone, ans, again = {}, {}, false
    for g, has in pairs(links) do
        local row = l.byId[g]
        if row then
            C.absent[g] = nil
            if has == false and row.aw then
                ans[#ans + 1] = { g = g, a = cutRow(row.a), m = cutRow(row.m), who = cutRow(row.aw), text = cutRow(row.at) }
            end
        else
            local first = C.absent[g]
            if first and l.at - first >= TWO_LISTS_MS then
                C.absent[g] = nil
                gone[#gone + 1] = g
            else
                C.absent[g] = first or l.at
                again = true
            end
        end
    end
    queueDiff(gone, ans)
    if again and C.queueOpen then C.recheckAt = now() + TWO_LISTS_MS end
end

local function sendQueue()
    local q = C.q or {}
    C.queueRid = C.request("t_queue", { status = q.status, kind = q.kind, who = q.who, mine = q.mine, find = q.find,
        newest = q.newest, page = q.page }, function(a)
        if a.ok == false and a.err == "wait" then C.queueAgainAt = now() + BATCH_MS end
    end)
end

-- the queue opens, or Refresh. q: status, kind, who, mine, find, newest, page
function C.openQueue(q)
    if q then C.q = q end
    C.queueOpen = true
    C.wantSync = true
    sendQueue()
end
-- a changed filter or page: the server's list only
function C.setQueue(q)
    C.q = q
    sendQueue()
end
function C.closeQueue()
    C.queueOpen = false
    C.wantSync = nil
    C.sync = nil
    C.recheckAt = nil
    diffQ = {}
end
-- a ticket came in, or was answered, with no game link yet: the game's list again, soon, once
function C.syncSoon()
    if C.queueOpen and not C.recheckAt then C.recheckAt = now() + SOON_MS end
end

function C.openCard(id, cb)
    C.wantCard = id
    return C.request("t_card", { id = id }, cb)
end
-- the card closed: the next open of this ticket is a fresh one (the game's viewed goes with a fresh one). Only this ends
-- the card's pushes: the queue's own traffic runs under an open card
function C.closeCard()
    C.card = nil
    C.wantCard = nil
    S.send(Tk.MOD, "t_cardoff", {})
end
function C.take(id, cb) return C.request("t_take", { id = id }, cb) end
function C.addNote(id, text, cb) return C.request("t_addnote", { id = id, text = Tk.clean(text) }, cb) end
function C.close(id, cb) return C.request("t_close", { id = id }, cb) end
function C.reopen(id, cb) return C.request("t_reopen", { id = id }, cb) end
function C.spam(id, cb) return C.request("t_spam", { id = id }, cb) end
function C.unspam(id, cb) return C.request("t_unspam", { id = id }, cb) end

function C.answer(id, text, cb)
    local rec = (C.card and C.card.id == id) and C.card or nil
    local clean = Tk.clean(text)
    return C.request("t_answer", { id = id, text = clean }, function(a)
        if a.ok and a.first and a.gameId then
            local me = myName()
            -- (the one game answer; several replies live in ZeD's record, A4)
            withRow(a.gameId, rec, function()
                gameCall({ run = function() addTicket(me, Tk.answerText(clean), a.gameId) end, got = fullList })
            end)
        elseif a.ok and not a.gameId then
            C.syncSoon()         -- (the link will owe the game this answer)
        end
        if cb then cb(a) end
    end)
end

function C.delete(id, cb)
    local rec = (C.card and C.card.id == id) and C.card or nil
    return C.request("t_delete", { id = id }, function(a)
        if a.ok and a.gameId then
            withRow(a.gameId, rec, function()
                gameCall({ run = function() removeTicket(a.gameId) end, got = fullList })
            end)
        elseif a.ok then
            C.syncSoon()         -- (no link: the next sync finds the row by its tag and removes it)
        end
        if cb then cb(a) end
    end)
end

-- ---------------------------------------------------------------------------
-- THE QUEUE WITHOUT THE SERVER PART (B9): the game's list read here, on the 10-second poll the Admin tab always had
-- ---------------------------------------------------------------------------
function C.adminAsk(force)
    local t = now()
    if not force and C.pollAt and t - C.pollAt < ADMIN_POLL_MS then return end
    C.pollAt = t
    askFull()
end

-- a game row in the shape of a staff row: kind from the tag, Seen if viewed, Answered if viewed and it holds the game's
-- one answer. An answer on an unviewed row is any client's claim: it is shown as that, and the ticket stays open.
local function fallbackStaff(r)
    local kind, _, rest = Tk.parse(r.m)
    if not Tk.isKind(kind) then kind, rest = Tk.NONE, r.m end
    local answered = r.aw ~= nil and r.v == true
    return { id = r.g, kind = kind, author = r.a, st = (answered and "Answered") or (r.v and "Seen") or "Open",
        first = string.sub(rest, 1, L.PREVIEW), replies = r.aw and 1 or 0, game = true,
        text = rest, ansWho = r.aw, ansText = r.at, claim = (r.aw ~= nil and not r.v) or nil }
end

function C.fallbackRow(id)
    local r = C.list and C.list.byId[id]
    return r and fallbackStaff(r) or nil
end

function C.fallbackOpen()
    local n = 0
    for _, r in ipairs(C.list and C.list.rows or {}) do
        if not (r.aw and r.v) then n = n + 1 end
    end
    return n
end

local function findIn(find, s) return s ~= nil and string.find(string.lower(s), find, 1, true) ~= nil end

local function fallbackKeep(row, q, find)
    if q.status == "Open" and row.st == "Answered" then return false end
    if q.status == "Answered" and row.st ~= "Answered" then return false end
    if q.kind and row.kind ~= q.kind then return false end
    if q.who and row.author ~= q.who then return false end
    if find and not (findIn(find, row.author) or findIn(find, row.text) or findIn(find, row.ansText)) then return false end
    return true
end

-- a page of the game's list, filtered here: the same shape as the server's t_queue
function C.fallbackQueue(q)
    q = q or {}
    local find = (q.find and q.find ~= "") and string.lower(q.find) or nil
    local list, authors, seen = {}, {}, {}
    for _, r in ipairs(C.list and C.list.rows or {}) do
        local row = fallbackStaff(r)
        if not seen[row.author] then
            seen[row.author] = true
            authors[#authors + 1] = row.author
        end
        if fallbackKeep(row, q, find) then list[#list + 1] = row end
    end
    table.sort(authors)
    if q.newest == false then
        table.sort(list, function(x, y) return x.id < y.id end)
    else
        table.sort(list, function(x, y) return x.id > y.id end)
    end
    local pages = math.max(1, math.ceil(#list / L.PAGE_ROWS))
    local page = math.min(q.page or 1, pages)
    local rows, from = {}, (page - 1) * L.PAGE_ROWS
    for i = 1, math.min(L.PAGE_ROWS, #list - from) do rows[i] = list[from + i] end
    return { page = page, pages = pages, n = #list, rows = rows, open = C.fallbackOpen(), spam = 0, authors = authors }
end

-- the card opened: the game's window shows it viewed, and the player's row reads Seen (B9)
function C.gameView(id)
    local r = C.list and C.list.byId[id]
    local me = myName()
    if r and me and not r.v then
        r.v = true
        gameCall({ run = function() viewedTicket(me, id) end, got = fullList })
    end
end
function C.gameAnswer(id, text)
    local me = myName()
    if me then gameCall({ run = function() addTicket(me, Tk.clean(text), id) end, got = fullList }) end
end
function C.gameRemove(id) gameCall({ run = function() removeTicket(id) end, got = fullList }) end

-- ---------------------------------------------------------------------------
-- WHAT THE SERVER SENDS
-- ---------------------------------------------------------------------------
local on = {}

function on.t_ack(a)
    local e = a.rid and C.pend[a.rid] or nil
    if e then C.pend[a.rid] = nil end
    if a.ok == false and a.err == "perm" and S.hello then S.hello() end
    if e and e.cb then e.cb(a) end
    bump()
end

function on.t_mine(a)
    local out, todo = {}, {}
    for _, row in ipairs(a.rows or {}) do
        out[#out + 1] = row
        if row.file and not filedTried[row.id] and not checked[row.id] then
            checked[row.id] = true
            todo[#todo + 1] = { id = row.id, file = row.file }
        end
    end
    C.mine = out
    checkFiled(todo)
    bump()
end

function on.t_one(a)
    if Tk.whole(a.id) then C.one[a.id] = a end
    bump()
end

local function putRow(list, a)
    if not list then return end
    for i, row in ipairs(list) do
        if row.id == a.id and not row.game then
            list[i] = a
            return true
        end
    end
    return false
end

function on.t_row(a)
    C.rowSeq = C.rowSeq + 1
    if a.open then C.counts = { open = a.open, spam = a.spam or 0, kinds = a.kinds } end
    if a.id then
        if a.pv then
            if not putRow(C.mine, a) then table.insert(C.mine, 1, a) end
            -- (a status changed by staff comes as this row alone: a ticket read on a card is asked for again)
            local held = C.one[a.id]
            if held and held.st ~= a.st then C.loadOne(a.id) end
        else
            if C.queue then putRow(C.queue.rows, a) end
            if a.unlinked then C.syncSoon() end
        end
    end
    bump()
end

function on.t_queue(a)
    if C.queueRid then
        C.pend[C.queueRid] = nil
        C.queueRid = nil
    end
    C.queue = a
    C.counts = { open = a.open or 0, spam = a.spam or 0, kinds = a.kinds }
    C.gameMax = a.gameMax or 0
    if C.wantSync and not S.frozen then
        C.wantSync = nil
        syncList()
    end
    bump()
end

function on.t_syncd(a)
    if a.gameMax then C.gameMax = a.gameMax end
    C.links = a.links or {}
    if a.reset then
        C.lowAt = nil
        startBatches(now() + BATCH_MS)
    elseif a.same then
        compare(C.links)
    else
        startProof()
    end
    bump()
end

function on.t_card(a)
    if C.wantCard ~= a.id then return end    -- (a push for a card closed a moment ago)
    local fresh = not C.card or C.card.id ~= a.id
    C.card = a
    if fresh and a.gameId then
        local row = C.list and C.list.byId[a.gameId]
        if row and not row.v and Tk.sameTicket(row.a, row.m, a) then
            local me, g = myName(), a.gameId
            row.v = true
            gameCall({ run = function() viewedTicket(me, g) end, got = fullList })
        end
    end
    bump()
end

-- on the card already: read as it arrives, so no note and no line at the next login
function on.t_note(a)
    if C.seeing(a.id) then
        C.read(a.id)
    elseif ZeD.Messages and ZeD.Messages.ticket then
        ZeD.Messages.ticket(a.id, a.who)
    end
    bump()
end

function on.t_gone(a)
    local id = a.id
    C.one[id] = nil
    for i = #C.mine, 1, -1 do
        if C.mine[i].id == id and not C.mine[i].game then table.remove(C.mine, i) end
    end
    if C.queue and C.queue.rows then
        for i = #C.queue.rows, 1, -1 do
            if C.queue.rows[i].id == id then table.remove(C.queue.rows, i) end
        end
    end
    if C.card and C.card.id == id then C.card = nil end
    bump()
end

S.on(Tk.MOD, function(command, args)
    local fn = on[command]
    if fn then fn(args) end
end)

-- the hello: the notes that wait, the counts, and my tickets (the catch-up for a ticket filed but never sent to the game)
function C.onHello(a)
    if a.open then C.counts = { open = a.open, spam = a.spam or 0, kinds = a.kinds } end
    if type(a.unread) == "table" and ZeD.Messages and ZeD.Messages.ticket then
        for _, id in ipairs(a.unread) do ZeD.Messages.ticket(id) end
    end
    C.loadMine()
    bump()
end

-- ---------------------------------------------------------------------------
-- THE CLOCK
-- ---------------------------------------------------------------------------
local function expire(t)
    local late = nil
    for rid, e in pairs(C.pend) do
        if t - e.at >= REPLY_MS then
            late = late or {}
            late[#late + 1] = rid
        end
    end
    if not late then return end
    for _, rid in ipairs(late) do
        local e = C.pend[rid]
        C.pend[rid] = nil
        if e.cb then
            local ok, err = pcall(e.cb, { ok = false, err = "fail" })
            if not ok then ZeD.logOnce("tickets: a late answer", err) end
        end
    end
    bump()
end

local function tick()
    if not isClient() then return end
    local t = now()
    expire(t)
    if busy and t - busy.at >= REPLY_MS then
        -- (past about 1 MB the game never answers getTickets: staff get a line, and nothing here tries to mend it)
        if busy.full and not C.gameSilent then
            C.gameSilent = true
            bump()
        end
        busy = nil
        pump()
    end
    pumpSync()
    if #diffQ > 0 and t >= diffAt then
        local b = table.remove(diffQ, 1)
        diffAt = t + BATCH_MS
        C.request("t_gamediff", { gone = b.gone, ans = b.ans })
    end
    if C.queueAgainAt and t >= C.queueAgainAt then
        C.queueAgainAt = nil
        sendQueue()
    end
    if C.recheckAt and t >= C.recheckAt then
        if C.sync then
            C.recheckAt = t + BATCH_MS       -- (one sync at a time)
        else
            C.recheckAt = nil
            syncList()
        end
    end
end

-- ---------------------------------------------------------------------------
-- THE GAME'S MODAL FOR A NEW TICKET (B7): it would cover the screen on each ticket. For staff with the queue it is a
-- note in Messages, at most one in 10 seconds. Any other message passes to the game, and so does this one on a client
-- without AnswerTickets: observer and gm receive it and have no queue to open.
-- ---------------------------------------------------------------------------
local function onAdminMessage(message, x, y, z)
    if S.available() and S.staff and Tk.isTicketMessage(message) then
        local t = now()
        if not lastNote or t - lastNote >= NOTE_EVERY_MS then
            lastNote = t
            if ZeD.Messages and ZeD.Messages.ticketNew then ZeD.Messages.ticketNew() end
        end
        return
    end
    return ISAdminMessage.AddAdminMessage(message, x, y, z)
end

if not C.hooked then
    C.hooked = true
    Events.ViewTickets.Add(function(list) ZeD.Tickets.onViewTickets(list) end)
    Events.OnTick.Add(tick)
    if ISAdminMessage and ISAdminMessage.AddAdminMessage then
        Events.OnAdminMessage.Remove(ISAdminMessage.AddAdminMessage)
        Events.OnAdminMessage.Add(onAdminMessage)
    end
end

return C
