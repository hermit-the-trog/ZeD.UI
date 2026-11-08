-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerMail.lua
-- ============================================================================
-- MAIL, THE SERVER'S SIDE. The server holds a player's letters until they are handed over, and forgets each one the
-- moment the player's computer says it has it: the server is the post office, not the mailbox. Everything is decided
-- here from the player the event gives, never from a client's word: the sender is always p:getUsername(). Server only:
-- the first line returns anywhere but a dedicated server or the server process a hosted game starts. Pure ASCII.
--
-- PRIVATE. ZeD's moderation tools give staff tickets, the action log and reports; none of them covers letters between
-- players, so letters stay private: the table has a secret random name (any logged-in client can read a global mod data
-- table it can name) and is never transmitted, no capability reads it, no command lists it, and nothing about a letter
-- reaches the log, not its words and not who wrote to whom. The log hears only what every ZeD command already writes for anyone
-- (Srv.bad for arguments no client of ours sends, the general rate limit). A server's owner can still open the save's
-- files; nothing in Lua can stop that, and the help says so.
--
-- Bans and the join rules: every command is Srv.register's, so ZeD's gates (Srv.gates, ZeD_ServerCore.lua) shut a
-- banned player, or one who has not agreed to the rules, out of mail as out of the rest.
--
--   p_dial   the dial-in: this player can be mailed from now on; the first batch of their waiting letters comes down
--   p_got    { ids }: the client has these; the server forgets them and sends the next batch
--   p_mute   { names }: the players this player muted (their own list, ZeD_Chat.lua). Their letters are no longer
--            delivered, and any already waiting go. The sender is told nothing: the answer is the same ok as a letter
--            delivered
--   p_send   { to, subj, text, cid }: a letter. To any player seen on this server since mail came (online or not).
--            Refusals: "to" (nobody by that name here), "text", "subj", "wait" (Ml.L.SEND_MS), "hour" (Ml.L.HOUR_MAX),
--            "frozen". A cid already delivered answers ok again and delivers nothing (an answer that was lost).
-- Caps, each oldest first: INBOX_MAX letters waiting for one player, CHARS_MAX words in all, KNOWN_MAX players.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_MailProto"
require "ZeD/ZeD_ServerCore"

local Srv = ZeD.Srv
local Tk = ZeD.Tk
local Ml = ZeD.Ml
if not Srv or Srv.off then return end

local ML = Ml.L
local PREFIX = "ZeD_ML_"             -- the table's name: this, then a random UUID
local SCHEMA = 1
local MIGRATE = {}                   -- MIGRATE[1] = function(md) ... end   moves 1 to 2; adds or reshapes, never drops

-- memory only: a /reloadlua of this file leaves it empty and open() fills it again
local T = {}
Srv.Mail = T

-- ---------------------------------------------------------------------------
-- THE TABLE
-- ---------------------------------------------------------------------------
-- the mail table's name, if the save holds one; with several, the first by name and a line in the log
local function findName()
    local names = ModData.getTableNames()
    local best, found = nil, 0
    for i = 0, names:size() - 1 do
        local n = names:get(i)
        if string.sub(n, 1, #PREFIX) == PREFIX then
            found = found + 1
            if not best or n < best then best = n end
        end
    end
    if found > 1 then Srv.fileLine("admin", Tk.SYS, "mail tables", nil, "found " .. found .. "; using the first by name") end
    return best
end

-- the mail table (Srv.openMail): opened once and kept, made under a new secret name the first time, brought up to
-- SCHEMA, and frozen (read, never written) when a newer ZeD made it
local function open()
    if T.md then return T.md end
    local name = findName() or (PREFIX .. getRandomUUID())
    local md = ModData.getOrCreate(name)
    md.schema = md.schema or SCHEMA
    md.boxes = md.boxes or {}         -- lower-case username -> { n = count, [i] = letter }, oldest first
    md.known = md.known or {}         -- lower-case username -> { user, t (seconds, last seen) }
    md.knownN = md.knownN or 0
    md.sent = md.sent or {}           -- lower-case username -> { n, [i] = cid }, the sender's last CIDS letter numbers
    md.chars = md.chars or 0          -- every letter's words and subject
    md.nextId = md.nextId or 1
    md.mutes = md.mutes or {}         -- lower-case username -> { [lower-case name] = true }: whose letters they refuse
    md.hours = md.hours or {}         -- lower-case username -> { n = letters sent, at = the hour's start (ms) }: kept so a
                                      -- restart can't reset the hour's cap
    if md.schema > SCHEMA then
        T.frozen = true               -- data from a newer ZeD: read it, never change it
    end
    while md.schema < SCHEMA do
        local step = MIGRATE[md.schema]
        if not step or not pcall(step, md) then
            T.frozen = true           -- a missing or failed step: stop here, write nothing
            break
        end
        md.schema = md.schema + 1
    end
    if T.frozen then Srv.fileLine("admin", Tk.SYS, "mail table frozen", nil, "schema " .. tostring(md.schema) .. ", this ZeD knows " .. SCHEMA) end
    T.md = md
    return md
end
Srv.openMail = open

local function low(user) return string.lower(tostring(user)) end      -- every key is a lower-case username
local function sizeOf(m) return #(m.text or "") + #(m.subj or "") end   -- a letter's share of CHARS_MAX

-- ---------------------------------------------------------------------------
-- WHO CAN BE MAILED: everyone who has joined since mail came, by the name the game gives them
-- ---------------------------------------------------------------------------
local function know(md, p)
    if T.frozen then return end
    local user = p:getUsername()
    local k = low(user)
    local e = md.known[k]
    if not e then
        md.knownN = md.knownN + 1
        e = {}
        md.known[k] = e
    end
    e.user, e.t = user, getTimestamp()
    if md.knownN <= ML.KNOWN_MAX then return end
    local oldest, at = nil, nil       -- (the one seen longest ago goes; their waiting letters stay until they come back)
    for key, x in pairs(md.known) do
        if key ~= k and (not at or (x.t or 0) < at) then oldest, at = key, x.t or 0 end
    end
    if oldest then
        md.known[oldest] = nil
        md.knownN = md.knownN - 1
        -- (what the server keeps for them goes with them: their sent-letter numbers, their mutes, their hour)
        md.sent[oldest] = nil
        md.mutes[oldest] = nil
        md.hours[oldest] = nil
    end
end

-- ---------------------------------------------------------------------------
-- THE BOXES
-- ---------------------------------------------------------------------------
-- a player's box (k: the lower-case name); make: create it when missing
local function boxOf(md, k, make)
    local b = md.boxes[k]
    if not b and make then
        b = { n = 0 }
        md.boxes[k] = b
    end
    return b
end

-- take letter i out of a box, keeping md.chars right; an empty box goes
local function dropAt(md, k, b, i)
    local m = b[i]
    if not m then return end
    md.chars = md.chars - sizeOf(m)
    for j = i, b.n - 1 do b[j] = b[j + 1] end
    b[b.n] = nil
    b.n = b.n - 1
    if b.n <= 0 then md.boxes[k] = nil end
end

-- the oldest letter anywhere (the lowest id: ids only grow), to make room
local function dropOldest(md)
    local bestK, bestId = nil, nil
    for k, b in pairs(md.boxes) do
        local m = b[1]
        if m and (not bestId or m.id < bestId) then bestK, bestId = k, m.id end
    end
    if not bestK then return false end
    dropAt(md, bestK, md.boxes[bestK], 1)
    return true
end

-- put a letter in a box, making room first: the box's own oldest past INBOX_MAX, then the oldest anywhere past CHARS_MAX
local function deliver(md, k, m)
    local b = boxOf(md, k, true)
    while b.n >= ML.INBOX_MAX do dropAt(md, k, b, 1); b = boxOf(md, k, true) end
    while md.chars + sizeOf(m) > ML.CHARS_MAX do
        if not dropOldest(md) then break end
    end
    b = boxOf(md, k, true)
    b.n = b.n + 1
    b[b.n] = m
    md.chars = md.chars + sizeOf(m)
end

-- what a client receives of a letter, field by field
local function wireOf(m)
    return { id = m.id, from = m.from, to = m.to, subj = m.subj, text = m.text, t = m.t, day = m.day }
end

-- the next batch of a player's waiting letters, oldest first; left: how many wait after it
local function sendBatch(md, p)
    local k = low(p:getUsername())
    local b = boxOf(md, k, false)
    local out = { n = 0 }
    if b then
        for i = 1, math.min(b.n, ML.BATCH) do
            out.n = out.n + 1
            out[out.n] = wireOf(b[i])
        end
        out.left = b.n - out.n
    else
        out.left = 0
    end
    if out.n > 0 then Srv.to(p, Ml.MOD, "p_in", out) end
    return out.n
end

-- ---------------------------------------------------------------------------
-- THE COMMANDS
-- ---------------------------------------------------------------------------
local function reg(command, opts, fn) Srv.register(Ml.MOD, command, opts, fn) end

local applyMutes     -- (below; declared here so p_dial's closure finds it, not a global of that name)

-- the dial-in: remember the player, take a mute list if one comes with it, say how many letters wait, send the first batch
reg("p_dial", { limit = ML.DIAL_MS }, function(p, a, rid)
    local md = open()
    know(md, p)
    if a.mutes ~= nil and not T.frozen then applyMutes(md, p, a.mutes) end
    local b = boxOf(md, low(p:getUsername()), false)
    Srv.ack(p, rid, true, nil, { waiting = b and b.n or 0, frozen = T.frozen and true or nil, v = Ml.PROTO })
    sendBatch(md, p)
end)

-- ids: the letters the client now holds. Only this player's own box is ever touched
-- (no limit of its own: each answers a batch already sent, and the general limit holds it)
reg("p_got", {}, function(p, a, rid)
    local md = open()
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return end
    local ids = a.ids
    if type(ids) ~= "table" or not (ids.n == 0 or Tk.whole(ids.n)) or ids.n > ML.BATCH then
        Srv.bad(p, "p_got")
        Srv.ack(p, rid, false, "bad")
        return
    end
    local want = {}
    for i = 1, ids.n do
        if Tk.whole(ids[i]) then want[ids[i]] = true end
    end
    local k = low(p:getUsername())
    local b = boxOf(md, k, false)
    local i = 1
    while b and i <= b.n do
        if want[b[i].id] then
            dropAt(md, k, b, i)
            b = boxOf(md, k, false)
        else
            i = i + 1
        end
    end
    if rid then Srv.ack(p, rid, true) end
    sendBatch(md, p)
end)

-- a player's mute list, the whole list each time; false when it is not one a client of ours sends
function applyMutes(md, p, names)
    if type(names) ~= "table" or not (names.n == 0 or Tk.whole(names.n)) or names.n > ML.MUTES_MAX then
        Srv.bad(p, "p_mute")
        return false
    end
    local set, any = {}, false
    for i = 1, names.n do
        local n = Ml.line(names[i], ML.TO_MAX)
        if n then set[low(n)] = true; any = true end
    end
    local k = low(p:getUsername())
    md.mutes[k] = any and set or nil
    -- (what already waits from someone now muted goes too)
    local b = boxOf(md, k, false)
    local i = 1
    while any and b and i <= b.n do
        if set[low(b[i].from)] then
            dropAt(md, k, b, i)
            b = boxOf(md, k, false)
        else
            i = i + 1
        end
    end
    return true
end

-- p_mute: the client sends its list at every change (and with the dial-in, before anything comes down)
reg("p_mute", { limit = ML.MUTE_MS }, function(p, a, rid)
    local md = open()
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return end
    if not applyMutes(md, p, a.names) then Srv.ack(p, rid, false, "bad"); return end
    Srv.ack(p, rid, true)
end)

-- this player's hour: a count and the hour's start, in the mod data (a restart keeps it). An hour that has run out
-- (or a clock that went back) starts again
local function hourOf(md, k, now)
    local h = md.hours[k]
    if type(h) ~= "table" or type(h.at) ~= "number" or type(h.n) ~= "number" or now - h.at >= ML.HOUR_MS or now < h.at then
        return nil
    end
    return h
end

-- false when this player has sent HOUR_MAX letters this hour
local function hourRoom(md, k)
    local h = hourOf(md, k, getTimestampMs())
    return not h or h.n < ML.HOUR_MAX
end

-- one more letter in this player's hour; with no hour running, this letter starts one
local function hourCount(md, k)
    local now = getTimestampMs()
    local h = hourOf(md, k, now)
    if h then h.n = h.n + 1 else md.hours[k] = { n = 1, at = now } end
end

-- each sender's last CIDS letter numbers: a number seen again is a letter resent after its answer was lost
local function sentBefore(md, k, cid)
    local s = md.sent[k]
    if not s then return false end
    for i = 1, s.n do if s[i] == cid then return true end end
    return false
end

local function rememberCid(md, k, cid)
    local s = md.sent[k]
    if not s then s = { n = 0 }; md.sent[k] = s end
    if s.n >= ML.CIDS then
        for i = 1, s.n - 1 do s[i] = s[i + 1] end
        s[s.n] = nil
        s.n = s.n - 1
    end
    s.n = s.n + 1
    s[s.n] = cid
end

reg("p_send", { limit = ML.SEND_MS, mark = false }, function(p, a, rid)
    local md = open()
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return end
    local cid = Ml.cid(a.cid)
    local to = Ml.line(a.to, ML.TO_MAX)
    local subj = Ml.subject(a.subj)
    local text = Ml.text(a.text)
    if not cid then
        Srv.bad(p, "p_send")
        Srv.ack(p, rid, false, "bad")
        return
    end
    local me = p:getUsername()
    local k = low(me)
    know(md, p)
    -- (a letter the server already took: its answer was lost. Ok again, nothing more)
    if sentBefore(md, k, cid) then
        Srv.ack(p, rid, true, nil, { cid = cid, again = true })
        return
    end
    if not text then Srv.ack(p, rid, false, "text", { cid = cid }); return end
    if not subj then Srv.ack(p, rid, false, "subj", { cid = cid }); return end
    local dest = to and md.known[low(to)] or nil
    if not dest then Srv.ack(p, rid, false, "to", { cid = cid }); return end
    if not hourRoom(md, k) then Srv.ack(p, rid, false, "hour", { cid = cid }); return end
    Srv.mark(p, "p_send")
    hourCount(md, k)
    local id = md.nextId
    md.nextId = id + 1
    local m = { id = id, from = me, to = dest.user, subj = subj, text = text, t = getTimestamp(), day = Srv.day() }
    rememberCid(md, k, cid)
    -- muted by the one it is for: not delivered, and the sender hears the same ok as ever (a mute is nobody else's business)
    local muted = md.mutes[low(dest.user)]
    if muted and muted[k] then
        Srv.ack(p, rid, true, nil, { cid = cid, to = dest.user })
        return
    end
    deliver(md, low(dest.user), m)
    Srv.ack(p, rid, true, nil, { cid = cid, to = dest.user })
    -- online: it comes down now, as everything does, through the same handover
    -- (only this letter: any others still waiting come with the next batch, after this one's p_got)
    local o = Srv.player(dest.user)
    if o then Srv.to(o, Ml.MOD, "p_in", { n = 1, [1] = wireOf(m), left = 0, live = true }) end
end)

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
Srv.modules[Ml.MOD] = true
-- (the hello says the part is here; joining makes a player someone others can write to, before their client dials)
Srv.helloAdds.mail = function(p, r)
    r.ml = Ml.PROTO
    local ok = pcall(know, open(), p)
    if not ok then r.ml = nil end
end

-- the table opens as the world's mod data loads; the flag lives on Srv, so a /reloadlua never adds the listener twice
if Srv.mailHooked == nil then
    Srv.mailHooked = true
    Events.OnInitGlobalModData.Add(function() if ZeD.Srv.openMail then ZeD.Srv.openMail() end end)
end

return T
