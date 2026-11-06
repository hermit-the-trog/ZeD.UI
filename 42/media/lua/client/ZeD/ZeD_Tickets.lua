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

C.seq = C.seq or 0            -- bumps on every change (the cards re-read)
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
function C.request(cmd, args, cb)
    ridNext = ridNext + 1
    local rid = ridNext
    args = args or {}
    args.rid = rid
    C.pend[rid] = { cmd = cmd, cb = cb, at = now() }
    if not S.send(Tk.MOD, cmd, args) then
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
-- Send. Answers "wait" while the link is unknown and "text" for words the server would refuse, both with the typed
-- text kept; otherwise "sent", with done(ack) to come. Keeps the fallback's path for frozen, as B9 says.
function C.ask(kind, here, text, done)
    if S.present == nil and not S.forceOff then return "wait" end
    local clean = Tk.clean(text)
    if not Tk.isKind(kind) or not clean or #clean < 1 or #clean > L.TEXT_MAX then return "text" end
    if S.available() and not S.frozen then
        C.request("t_new", { kind = kind, here = here == true, text = clean }, function(a)
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
    gameCall({
        run = function() addTicket(me, Tk.plainTag(kind, clean, x, y), -1) end,
        got = function(rows) C.fallbackMine(rows) end,
    })
    if done then done({ ok = true, fallback = true }) end
    return "sent"
end

-- the game's own list of mine, in my rows' shape (B9): kind from the tag, viewed gives Seen, an answer gives Answered
function C.fallbackMine(rows)
    local out = {}
    for i = #rows, 1, -1 do
        local row = rows[i]
        local kind, _, rest = Tk.parse(row.m)
        if not Tk.isKind(kind) then kind, rest = Tk.NONE, row.m end
        out[#out + 1] = { id = row.g, kind = kind, last = string.sub(row.aw and row.at or rest, 1, L.PREVIEW),
            st = (row.aw and "Answered") or (row.v and "Seen") or "Sent", replies = row.aw and 1 or 0, game = true }
    end
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

function C.loadOne(id) return C.request("t_one", { id = id }) end
function C.reply(id, text, cb) return C.request("t_reply", { id = id, text = Tk.clean(text) }, cb) end
function C.read(id) S.send(Tk.MOD, "t_read", { id = id }) end

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
local pumpSync       -- (below; hoisted for startBatches)

local function startBatches()
    local l = C.list
    if not l then return end
    local rows = {}
    for _, r in ipairs(l.rows) do
        if r.g > C.gameMax then rows[#rows + 1] = r end
    end
    C.sync = { rows = rows, i = 1, top = l.top, nextAt = 0 }
    pumpSync()
end

local function cutRow(s) return s and string.sub(s, 1, L.SYNC_CUT) or nil end

-- Two full lists have a top below gameMax. Either the newest ticket was removed, or the game's table was replaced. The
-- server tells them apart from up to 20 rows that sit under a linked id, which still match their records if nothing
-- was replaced.
local function askReset()
    local l = C.list
    local proof, n = {}, 0
    for i = #l.rows, 1, -1 do
        local r = l.rows[i]
        if C.links and C.links[r.g] ~= nil and n < L.SYNC_ROWS then
            n = n + 1
            proof[n] = { g = r.g, a = cutRow(r.a), m = cutRow(r.m) }
        end
    end
    C.request("t_sync", { rows = proof, top = l.top, done = true, reset = true })
end

-- a full list, for the queue: what the server has not dealt with goes in batches
local function afterList()
    if not C.queueOpen then return end
    local l = C.list
    if l.top < C.gameMax and C.sameAt ~= C.gameMax then
        if C.lowAt and C.links and l.at - C.lowAt >= TWO_LISTS_MS then
            C.lowAt = nil
            askReset()
            return
        end
        C.lowAt = C.lowAt or l.at
        C.recheckAt = now() + TWO_LISTS_MS
    else
        C.lowAt = nil
    end
    startBatches()
end

local function syncList() askFull(afterList) end

pumpSync = function()
    local y = C.sync
    if not y or y.over or now() < y.nextAt then return end
    local from, batch, n = y.i, {}, 0
    while n < L.SYNC_ROWS and y.i <= #y.rows do
        local r = y.rows[y.i]
        n = n + 1
        batch[n] = { g = r.g, a = cutRow(r.a), m = cutRow(r.m), v = r.v, aw = cutRow(r.aw), at = cutRow(r.at) }
        y.i = y.i + 1
    end
    local done = y.i > #y.rows
    y.over = done
    y.nextAt = now() + BATCH_MS
    C.request("t_sync", { rows = batch, top = y.top, done = done }, function(a)
        if C.sync ~= y then return end
        if a.ok == false and a.err == "wait" then
            y.i = from
            y.over = false
            y.nextAt = now() + BATCH_MS
        elseif a.ok == false or y.over then
            C.sync = nil
        end
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

-- what the game holds against what the server has linked. Only ids at or below the list's highest: a link made after
-- the list was fetched is not missing. A second list runs only when something looks gone.
local function compare(links)
    local l = C.list
    if not l then return end
    local gone, ans, again = {}, {}, false
    for g, has in pairs(links) do
        local row = l.byId[g]
        if row then
            C.absent[g] = nil
            if has == false and row.aw then
                ans[#ans + 1] = { g = g, who = cutRow(row.aw), text = cutRow(row.at), viewed = row.v }
            end
        elseif g <= l.top then
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
    C.sameAt = nil
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
    C.lowAt = nil
    diffQ = {}
end

function C.openCard(id) return C.request("t_card", { id = id }) end
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
                gameCall({ run = function() addTicket(me, clean, a.gameId) end, got = fullList })
            end)
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
        end
        if cb then cb(a) end
    end)
end

-- ---------------------------------------------------------------------------
-- THE ADMIN TAB'S LIST, until the ticket cards replace it: the game's rows, as the latest full list holds them. With
-- the server part it opens the queue once; without it, it polls as it always did.
-- ---------------------------------------------------------------------------
function C.adminAsk(force)
    if S.available() then
        if force or not C.adminAsked then
            C.adminAsked = true
            C.openQueue()
        end
        return
    end
    local t = now()
    if not force and C.pollAt and t - C.pollAt < ADMIN_POLL_MS then return end
    C.pollAt = t
    askFull()
end

function C.adminRows()
    local out = {}
    for _, r in ipairs(C.list and C.list.rows or {}) do
        out[#out + 1] = { id = r.g, author = r.a, text = r.m, answer = r.aw and (r.aw .. ": " .. tostring(r.at)) or nil }
    end
    return out
end

function C.gameAnswer(id, text)
    local me = myName()
    if me then gameCall({ run = function() addTicket(me, text, id) end, got = fullList }) end
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
        if row.id == a.id then
            list[i] = a
            return true
        end
    end
    return false
end

function on.t_row(a)
    if a.open then C.counts = { open = a.open, spam = a.spam or 0 } end
    if a.id then
        if a.pv then
            if not putRow(C.mine, a) then table.insert(C.mine, 1, a) end
        elseif C.queue then
            putRow(C.queue.rows, a)
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
    C.counts = { open = a.open or 0, spam = a.spam or 0 }
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
        startBatches()
        return
    end
    if a.same then
        C.sameAt = C.gameMax
        C.lowAt = nil
    end
    compare(C.links)
    bump()
end

function on.t_card(a)
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

function on.t_note(a)
    if ZeD.Messages and ZeD.Messages.ticket then ZeD.Messages.ticket(a.id, a.who) end
    bump()
end

function on.t_gone(a)
    local id = a.id
    C.one[id] = nil
    for i = #C.mine, 1, -1 do
        if C.mine[i].id == id then table.remove(C.mine, i) end
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
    if a.open then C.counts = { open = a.open, spam = a.spam or 0 } end
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
        C.recheckAt = nil
        syncList()
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
