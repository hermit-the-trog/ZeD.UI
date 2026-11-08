-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Mail.lua
-- ============================================================================
-- MAIL, THE CLIENT'S MODEL IN GAME. Client side, no drawing: ZeD_MailCards.lua reads this. The model is early-90s
-- email: dial in, mail moves both ways, hang up, read offline.
--
-- Joining a server is the dial-in. When the hello says the server keeps mail (r.ml), this client says p_dial once in the
-- connection: the letters waiting for this player come down in batches, each kept in the copy on this computer
-- (ZeD_MailStore.lua) and then answered with p_got, so the server forgets them; and the Outbox goes up a letter at a
-- time. A letter written in game goes through the same Outbox, so there is one road. While the player is on, a letter
-- sent to them comes down at once. The moment itself: "Dialing in..." on the Mail block, then what came and went, and a
-- note in Messages when letters arrive.
--
-- A refusal by the server (nobody by that name here, words it will not take) sends the letter back to the Inbox as
-- returned mail, the way 1993 mail did. A refusal of the player (a ban, the join rules not answered yet, the hourly cap,
-- no answer at all) leaves the Outbox as it is for the next dial-in. With ZeD's gates (the join rules) a player who has
-- not agreed to the rules dials again the moment they agree (S.onAgreed).
--
-- Test hooks, read at call time: M.qaHold true: no traffic. M.qaLink true / false: whether the server keeps mail.
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_MailProto"
require "ZeD/ZeD_MailStore"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Tickets"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Mail = ZeD.Mail or {}
local M = ZeD.Mail
local S = ZeD.ServerPart
local Ml = ZeD.Ml
local MS = ZeD.MailStore
local K = ZeD.Tickets
local Tk = ZeD.Tk

M.seq = M.seq or 0
local function bump() M.seq = M.seq + 1 end
local function now() return getTimestampMs() end
-- pacing (the server answers at most GENERAL_N ZeD commands in GENERAL_MS from one player, every part together, and a
-- join is busy: tickets, admin and community all ask then)
local DIAL_AFTER_MS = 3000           -- the dial-in waits this long after the hello
local DIAL_TRIES = 3                 -- a dial-in with no answer is tried again, this many times in a connection
local RETRY_MS = 15000               -- after no answer at all
local GOT_EVERY_MS = 1000            -- one p_got a second at most

local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end

--- True when the server keeps mail (its hello said so).
function M.live()
    if M.qaLink ~= nil then return M.qaLink end
    return S.available() and M.here == true
end

function M.serverKey()
    return safe(function() return tostring(getServerIP()) .. ":" .. tostring(getServerPort()) end, nil)
end

function M.serverName()
    local so = getServerOptions and getServerOptions()
    local name = safe(function() return so:getOption("PublicName") end, "")
    if name == "" then name = safe(function() return getServerName() end, "") end
    return name
end

function M.user() return safe(function() return getPlayer():getUsername() end, nil) end

--- This connection's mailbox on this computer: made the first time it is asked for (the dial-in asks first), nil
--- until the server and the player's name are known.
function M.box()
    if M._box then return M._box end
    local key, user = M.serverKey(), M.user()
    if not (key and user) then return nil end
    M._box = MS.box(key, user, M.serverName())
    return M._box
end

-- ---------------------------------------------------------------------------
-- THE DIAL-IN
-- ---------------------------------------------------------------------------
-- the player's own mute list for this server (ZeD_Chat.lua keeps it), as the server takes it: { n, [i] = name }
function M.mutes()
    local out = { n = 0 }
    local Ch = ZeD.Chat
    if not (Ch and Ch.mutedByMe) then return out end
    pcall(Ch.mutedByMe, "")                -- (reads the file the first time)
    for name in pairs(Ch.myMutes or {}) do
        if out.n >= Ml.L.MUTES_MAX then break end
        out.n = out.n + 1
        out[out.n] = name
    end
    return out
end

-- a change to the mute list goes to the server at once (muting someone also stops their mail)
function M.hookMute()
    local Ch = ZeD.Chat
    if not (Ch and Ch.setMuted) or Ch._mailHooked then return end
    Ch._mailHooked = true
    local base = Ch.setMuted
    Ch.setMuted = function(...)
        local r = base(...)
        if M.state == "on" and not M.qaHold then pcall(S.send, Ml.MOD, "p_mute", { names = M.mutes() }) end
        return r
    end
end

-- THE MODEM: once a connection, the handshake (our own sound, made by ZeDUI/tools/sound/make_modem.py, on the game's UI
-- volume) when the dial-in starts, and "Connecting... sending N, receiving M" as a Messages notice when the server answers
-- (every ZeD notice is a bubble out of the Messages icon, never over the head)
function M.ring()
    if M.rang then return end
    M.rang = true
    pcall(function() getSoundManager():playUISound("ZeDModemDial") end)
end
function M.connectNote(sending, receiving)
    local text = ZeD.tr("UI_ZeD_Mail_Connecting", sending or 0, receiving or 0)
    M.lastNote = text
    M.notice(text)
end

-- a notice from Mail: through Messages' notice path (ZeD.Messages.notice: filed under Mail's name, with its toast);
-- a Messages without that path gets a plain item under Mail's name instead, one item kept and brought up to date
function M.notice(text)
    local Msg = ZeD.Messages
    if not Msg then return end
    local name = ZeD.tr("UI_ZeD_Mail_Title")
    if Msg.notice then
        pcall(Msg.notice, name, text, "mail")
        return
    end
    local s = Msg.sources and Msg.sources[name]
    for _, it in ipairs(s and s.items or {}) do
        if it.k == "mail" then
            it.text, it.read = text, false
            return
        end
    end
    if Msg.add then pcall(Msg.add, name, "mods", { k = "mail", text = text }) end
end

-- state: nil (not yet), "dialing", "on" (dialed in this connection), "off" (the server said no; why in M.why)
function M.dial()
    if M.qaHold or not M.live() or M.state == "dialing" then return end
    local b = M.box()
    if not b then return end
    M.state, M.why = "dialing", nil
    M.tries = (M.tries or 0) + 1
    M.got, M.sent = 0, 0
    M.hookMute()
    M.ring()
    bump()
    K.requestOn(Ml.MOD, "p_dial", { mutes = M.mutes() }, function(a)
        if a.ok then
            M.state = "on"
            MS.epoch(b, a.ep)   -- (before any letter of this dial-in comes down: the ack is sent first)
            MS.dialed(b)
            if not M.noted then
                M.noted = true
                M.connectNote(#MS.load(b).outbox, tonumber(a.waiting) or 0)
            end
            M.drain()
        elseif a.err == "wait" then
            M.state, M.dialAt = nil, now() + (tonumber(a.left) or 1) * 1000 + 250   -- (a quick rejoin: dial again shortly)
        elseif a.err == "fail" and (M.tries or 0) < DIAL_TRIES then
            M.state, M.dialAt = nil, now() + RETRY_MS                              -- (no answer: the join was busy)
        else
            M.state, M.why = "off", a.err
        end
        bump()
    end)
end

--- The server's hello (ZeD_ServerLink.lua hands it on): its ml says whether the server keeps mail, and if so the
--- dial-in is set for DIAL_AFTER_MS later. Another server than the last one in this Lua session starts fresh.
function M.onHello(a)
    -- (another server than the last one in this Lua session: a fresh dial-in)
    local key = M.serverKey()
    if M._boxKey ~= key then
        M._boxKey, M._box, M.state, M.why, M.sending, M.retryAt, M.stopped, M.tries = key, nil, nil, nil, nil, nil, nil, 0
        M.rang, M.noted = nil, nil
        M.gotQ = {}
    end
    M.here = a.ml ~= nil
    bump()
    if M.here and M.state ~= "on" and M.state ~= "dialing" and not M.dialAt then M.dialAt = now() + DIAL_AFTER_MS end
end

-- ---------------------------------------------------------------------------
-- THE OUTBOX: a letter at a time
-- ---------------------------------------------------------------------------
-- the words for a letter the server sent back
function M.returnedWhy(err, to)
    if err == "to" then return ZeD.tr("UI_ZeD_Mail_RetNobody", tostring(to)) end
    return ZeD.tr("UI_ZeD_Mail_RetWords")
end

function M.drain()
    if M.qaHold or M.sending or M.state ~= "on" then return end
    local b = M.box()
    if not b then return end
    local m = MS.load(b).outbox[1]
    if not m then return end
    M.sending = m.cid
    K.requestOn(Ml.MOD, "p_send", { to = m.to, subj = m.subj, text = m.text, cid = m.cid }, function(a)
        M.sending = nil
        if a.ok then
            MS.sent(b, m.cid)
            M.sent = (M.sent or 0) + 1
            M.drain()
        elseif a.err == "wait" then
            M.retryAt = now() + (tonumber(a.left) or 1) * 1000 + 250
        elseif a.err == "fail" then
            M.retryAt = now() + RETRY_MS     -- (no answer: the same letter number goes again, and the server takes it once)
        elseif a.err == "to" or a.err == "text" or a.err == "subj" or a.err == "bad" then
            MS.returned(b, m.cid, M.returnedWhy(a.err, m.to))
            M.drain()
        else
            M.stopped = a.err            -- (perm, hour, frozen, no answer: it waits for the next dial-in)
        end
        bump()
    end)
end

--- A letter written in game: into the Outbox, and on its way at once. nil and why when it cannot go.
function M.write(to, subj, text)
    local b = M.box()
    if not b then return nil, "nobox" end
    local m, err = MS.queue(b, to, subj, text)
    if not m then return nil, err end
    M.stopped = nil
    M.drain()
    bump()
    return m
end

-- ---------------------------------------------------------------------------
-- WHAT THE SERVER SENDS: letters, kept here, then answered so the server forgets them
-- ---------------------------------------------------------------------------
function M.note(n, froms)
    local Msg = ZeD.Messages
    if not (Msg and n > 0) then return end
    M.notice((n == 1) and ZeD.tr("UI_ZeD_Mail_NoteOne", froms[1] or "") or ZeD.tr("UI_ZeD_Mail_NoteMany", n))
end

function M.onIn(a)
    local b = M.box()
    if not b then return end
    local ids, froms, fresh = { n = 0 }, {}, 0
    for i = 1, math.min(tonumber(a.n) or 0, Ml.L.BATCH) do
        local m = a[i]
        if type(m) == "table" and Tk.whole(m.id) then
            ids.n = ids.n + 1
            ids[ids.n] = m.id
            if MS.receive(b, m) then
                fresh = fresh + 1
                froms[#froms + 1] = tostring(m.from)
            end
        end
    end
    if fresh > 0 then MS.save(b) end
    M.got = (M.got or 0) + fresh
    if ids.n > 0 and not M.qaHold then
        M.gotQ = M.gotQ or {}
        M.gotQ[#M.gotQ + 1] = ids
    end
    if fresh > 0 then M.note(MS.unread(b), froms) end
    bump()
end

S.on(Ml.MOD, function(command, args)
    if command == "p_in" then M.onIn(args) end
end)

-- ---------------------------------------------------------------------------
-- THE CLOCK, THE HELLO, A NEW CONNECTION
-- ---------------------------------------------------------------------------
local function tick()
    if M.dialAt and now() >= M.dialAt then
        M.dialAt = nil
        M.dial()
    end
    -- what came down is answered a batch a second; the server then sends the next
    if M.gotQ and #M.gotQ > 0 and (not M.gotAt or now() - M.gotAt >= GOT_EVERY_MS) then
        M.gotAt = now()
        local ids = table.remove(M.gotQ, 1)
        if not M.qaHold then S.send(Ml.MOD, "p_got", { ids = ids }) end
    end
    if M.retryAt and now() >= M.retryAt then
        M.retryAt = nil
        M.drain()
    end
end

if not M.hooked then
    M.hooked = true
    if Events.OnTick then Events.OnTick.Add(tick) end
    -- (with ZeD's gates: a player who had not agreed to the rules was refused; agreeing dials again)
    if S.onAgreed then S.onAgreed("mail", function() if M.state ~= "on" then M.dial() end end) end
end

return M
