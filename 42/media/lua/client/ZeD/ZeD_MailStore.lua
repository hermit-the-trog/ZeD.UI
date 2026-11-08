-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MailStore.lua
-- ============================================================================
-- MAIL ON THIS COMPUTER. Client file, no drawing: the copy the desk reads at the main menu, where no server can be
-- reached. One mailbox for each server and username this computer has dialed in to, each with its Inbox (letters
-- handed over), Outbox (letters written and not sent yet: they go at the next join) and Sent. ZeD_Mail.lua fills it
-- in game; ZeD_MainMenuMail.lua reads it and writes to the Outbox at the desk.
--
-- Files under Zomboid/Lua, the way ZeD keeps its own:
--   ZeD_mail_boxes.txt   the mailboxes: a header, then "n|last dial-in|server key|username|server's name" a line
--   ZeD_mail_<n>.txt     one mailbox: a header, then a record a line, its fields split by "|":
--                          i|id|from|to|t|day|read|subject|words     a letter in the Inbox (id: the server's; 0 for
--                                                                    returned mail)
--                          o|cid|to|t|subject|words                  a letter in the Outbox
--                          s|cid|to|t|subject|words                  a letter in Sent
--                          g|id                                      a letter already handed over (so it never comes twice)
--                        A field's "\" is "\\", its line break "\n" and its "|" "\p": a record is always one line.
-- Caps, oldest first: INBOX_KEEP letters in an Inbox, SENT_KEEP in Sent, GOT_KEEP numbers remembered. The Outbox holds
-- OUT_MAX and says so; BOXES_MAX mailboxes, the one dialed into longest ago goes.
-- Reading never checks the header line, and a record it cannot parse is dropped rather than failing the file.
--
-- For the sims: MS.io holds the two file calls, so a sim can swap in its own, and MS.reset forgets the list read so far.
-- ============================================================================

require "ZeD/ZeD_MailProto"

ZeD = ZeD or {}
ZeD.MailStore = ZeD.MailStore or {}
local MS = ZeD.MailStore
local Ml = ZeD.Ml

MS.INDEX = "ZeD_mail_boxes.txt"
MS.HEADER = "ZeD mail 1"
MS.INBOX_KEEP = 200
MS.SENT_KEEP = 100
MS.GOT_KEEP = 400
MS.OUT_MAX = 20
MS.BOXES_MAX = 20

MS.io = MS.io or {
    reader = function(name) return getFileReader(name, false) end,
    writer = function(name) return getFileWriter(name, true, false) end,
}

MS.seq = MS.seq or 0                 -- bumps on every change (the screens re-read)
local function bump() MS.seq = MS.seq + 1 end

-- the real time in whole seconds, as a letter's t holds it
local function nowS()
    local ok, t = pcall(getTimestamp)
    if ok and type(t) == "number" then return math.floor(t) end
    return 0
end

-- ---------------------------------------------------------------------------
-- FILES AND FIELDS
-- ---------------------------------------------------------------------------
-- The game's Java side can throw; pcall turns a crash into a nil we can test. readLines answers nil for a file that
-- isn't there yet or a read that fails, writeLines false for a write that fails; a failure is logged once.
local function readLines(name)
    local ok, r = pcall(MS.io.reader, name)
    if not ok or not r then return nil end
    local out = {}
    local okR, err = pcall(function()
        local l = r:readLine()
        while l ~= nil do
            out[#out + 1] = l
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
    if not okR then
        if ZeD.logOnce then ZeD.logOnce("mail: reading " .. name, err) end
        return nil
    end
    return out
end

local function writeLines(name, lines)
    local ok, err = pcall(function()
        local w = MS.io.writer(name)
        if not w then error("no writer") end
        w:write(table.concat(lines, "\n") .. "\n")
        w:close()
    end)
    if not ok and ZeD.logOnce then ZeD.logOnce("mail: writing " .. name, err) end
    return ok
end

--- A field to one line and back (by character code and slices, as Tk.clean: the game's strings are UTF-16, and a
--- slice keeps every character whole).
function MS.esc(s)
    s = tostring(s or "")
    local out, from = {}, 1
    for i = 1, #s do
        local b = string.byte(s, i)
        local rep = (b == 92 and "\\\\") or (b == 10 and "\\n") or (b == 124 and "\\p") or (b == 13 and "") or nil
        if rep then
            if i > from then out[#out + 1] = string.sub(s, from, i - 1) end
            out[#out + 1] = rep
            from = i + 1
        end
    end
    if from <= #s then out[#out + 1] = string.sub(s, from) end
    return table.concat(out)
end

function MS.unesc(s)
    s = tostring(s or "")
    local out, from, i = {}, 1, 1
    while i <= #s do
        if string.byte(s, i) == 92 and i < #s then
            if i > from then out[#out + 1] = string.sub(s, from, i - 1) end
            local c = string.byte(s, i + 1)
            out[#out + 1] = (c == 110 and "\n") or (c == 112 and "|") or (c == 92 and "\\") or string.sub(s, i + 1, i + 1)
            i = i + 2
            from = i
        else
            i = i + 1
        end
    end
    if from <= #s then out[#out + 1] = string.sub(s, from) end
    return table.concat(out)
end

local function split(line)
    local out, from = {}, 1
    while true do
        local at = string.find(line, "|", from, true)
        if not at then out[#out + 1] = string.sub(line, from); break end
        out[#out + 1] = string.sub(line, from, at - 1)
        from = at + 1
    end
    return out
end

-- ---------------------------------------------------------------------------
-- THE MAILBOXES
-- ---------------------------------------------------------------------------
--- Every mailbox on this computer, the last dialed into first: read from the index once, then kept.
function MS.boxes()
    if MS._boxes then return MS._boxes end
    local list = {}
    local lines = readLines(MS.INDEX) or {}
    for i = 2, #lines do
        local f = split(lines[i])
        local n = tonumber(f[1])
        if n and n >= 1 and #f >= 5 and #list < MS.BOXES_MAX then
            list[#list + 1] = { n = n, t = tonumber(f[2]) or 0, key = MS.unesc(f[3]), user = MS.unesc(f[4]), server = MS.unesc(f[5]) }
        end
    end
    table.sort(list, function(a, b) return (a.t or 0) > (b.t or 0) end)   -- (the last dialed into first)
    MS._boxes = list
    return list
end

local function writeIndex()
    local lines = { MS.HEADER }
    for _, b in ipairs(MS.boxes()) do
        lines[#lines + 1] = table.concat({ tostring(b.n), tostring(b.t or 0), MS.esc(b.key), MS.esc(b.user), MS.esc(b.server) }, "|")
    end
    return writeLines(MS.INDEX, lines)
end

function MS.fileOf(n) return "ZeD_mail_" .. tostring(n) .. ".txt" end

--- A mailbox's id: the server's address and the username on it.
function MS.keyOf(server, user) return tostring(server) .. "/" .. tostring(user) end

--- The mailbox with this id (MS.keyOf), or nil.
function MS.find(key)
    for _, b in ipairs(MS.boxes()) do if b.key == key then return b end end
    return nil
end

--- The mailbox for this server and user, made when there is none (the one dialed into longest ago goes past
--- BOXES_MAX). One already here takes the server's name as it is now.
function MS.box(serverKey, user, serverName)
    local key = MS.keyOf(serverKey, user)
    local b = MS.find(key)
    if b then
        if serverName and serverName ~= "" and b.server ~= serverName then b.server = serverName; writeIndex() end
        return b
    end
    local list = MS.boxes()
    local used = {}
    for _, x in ipairs(list) do used[x.n] = true end
    if #list >= MS.BOXES_MAX then
        local oldest = list[#list]
        table.remove(list, #list)
        used[oldest.n] = nil
        writeLines(MS.fileOf(oldest.n), {})
    end
    local n = 1
    while used[n] do n = n + 1 end
    b = { n = n, t = 0, key = key, user = tostring(user), server = (serverName and serverName ~= "") and serverName or tostring(serverKey) }
    b.data = { inbox = {}, outbox = {}, sent = {}, got = {} }
    list[#list + 1] = b
    writeIndex()
    MS.save(b)
    bump()
    return b
end

--- A mailbox's letters: { inbox, outbox, sent, got }, read from its file once, then kept on the mailbox.
function MS.load(b)
    if b.data then return b.data end
    local d = { inbox = {}, outbox = {}, sent = {}, got = {} }
    local lines = readLines(MS.fileOf(b.n)) or {}
    for i = 2, #lines do
        local f = split(lines[i])
        local k = f[1]
        if k == "i" and #f >= 9 and tonumber(f[2]) then
            d.inbox[#d.inbox + 1] = { id = tonumber(f[2]), from = MS.unesc(f[3]), to = MS.unesc(f[4]), t = tonumber(f[5]) or 0, day = tonumber(f[6]) or 0,
                                      read = f[7] == "1", subj = MS.unesc(f[8]), text = MS.unesc(f[9]), returned = tonumber(f[2]) == 0 }
        elseif (k == "o" or k == "s") and #f >= 6 then
            local m = { cid = f[2], to = MS.unesc(f[3]), t = tonumber(f[4]) or 0, subj = MS.unesc(f[5]), text = MS.unesc(f[6]) }
            if k == "o" then d.outbox[#d.outbox + 1] = m else d.sent[#d.sent + 1] = m end
        elseif k == "g" and tonumber(f[2]) then
            d.got[#d.got + 1] = tonumber(f[2])
        end
    end
    b.data = d
    return d
end

--- Write the mailbox's file again, whole. True when it was written.
function MS.save(b)
    local d = MS.load(b)
    local lines = { MS.HEADER }
    for _, m in ipairs(d.inbox) do
        lines[#lines + 1] = table.concat({ "i", tostring(m.id), MS.esc(m.from), MS.esc(m.to), tostring(m.t or 0), tostring(m.day or 0), m.read and "1" or "0",
                                           MS.esc(m.subj), MS.esc(m.text) }, "|")
    end
    for _, pair in ipairs({ { "o", d.outbox }, { "s", d.sent } }) do
        for _, m in ipairs(pair[2]) do
            lines[#lines + 1] = table.concat({ pair[1], m.cid, MS.esc(m.to), tostring(m.t or 0), MS.esc(m.subj), MS.esc(m.text) }, "|")
        end
    end
    for _, id in ipairs(d.got) do lines[#lines + 1] = "g|" .. tostring(id) end
    local ok = writeLines(MS.fileOf(b.n), lines)
    bump()
    return ok
end

--- Stamp the dial-in's time on the mailbox, which moves it to the top of the list.
function MS.dialed(b)
    b.t = nowS()
    table.sort(MS.boxes(), function(x, y) return (x.t or 0) > (y.t or 0) end)
    writeIndex()
    bump()
end

-- ---------------------------------------------------------------------------
-- LETTERS
-- ---------------------------------------------------------------------------
local function has(list, v) for _, x in ipairs(list) do if x == v then return true end end return false end

--- A letter handed over: kept (newest first in the Inbox) unless it came before. True when it is new. Saving is the
--- caller's (a batch saves once).
function MS.receive(b, m)
    local d = MS.load(b)
    local id = tonumber(m.id)
    if not id or has(d.got, id) then return false end
    d.got[#d.got + 1] = id
    while #d.got > MS.GOT_KEEP do table.remove(d.got, 1) end
    table.insert(d.inbox, 1, { id = id, from = tostring(m.from or ""), to = tostring(m.to or ""), t = tonumber(m.t) or 0, day = tonumber(m.day) or 0,
                                read = false, subj = tostring(m.subj or ""), text = tostring(m.text or "") })
    while #d.inbox > MS.INBOX_KEEP do table.remove(d.inbox) end
    return true
end

--- A new letter into the Outbox; nil and "full" / "to" / "text" / "subj" when it cannot go. Its cid is this
--- computer's own number for it, so a letter sent again after a lost answer is taken only once.
MS._cidN = MS._cidN or 0
function MS.queue(b, to, subj, text)
    local d = MS.load(b)
    if #d.outbox >= MS.OUT_MAX then return nil, "full" end
    local clean = Ml.line(to, Ml.L.TO_MAX)
    if not clean then return nil, "to" end
    local s = Ml.subject(subj)
    if not s then return nil, "subj" end
    local tx = Ml.text(text)
    if not tx then return nil, "text" end
    MS._cidN = MS._cidN + 1
    local ms = 0
    pcall(function() ms = getTimestampMs() end)
    local m = { cid = "c" .. tostring(math.floor(ms)) .. "-" .. tostring(MS._cidN), to = clean, t = nowS(), subj = s, text = tx }
    d.outbox[#d.outbox + 1] = m
    MS.save(b)
    return m
end

--- The server took it: from the Outbox to Sent.
function MS.sent(b, cid)
    local d = MS.load(b)
    for i, m in ipairs(d.outbox) do
        if m.cid == cid then
            table.remove(d.outbox, i)
            m.t = nowS()
            table.insert(d.sent, 1, m)
            while #d.sent > MS.SENT_KEEP do table.remove(d.sent) end
            MS.save(b)
            return m
        end
    end
    return nil
end

--- The server would not take it (nobody by that name, words it refuses): it comes back to the Inbox as returned mail,
--- the way a 1993 mail server sent it back, and leaves the Outbox. why: the words to say, in the player's language.
function MS.returned(b, cid, why)
    local d = MS.load(b)
    for i, m in ipairs(d.outbox) do
        if m.cid == cid then
            table.remove(d.outbox, i)
            d.retN = (d.retN or 0) + 1
            table.insert(d.inbox, 1, { id = 0, from = "", to = m.to, t = nowS(), day = 0, read = false, returned = true,
                                        subj = m.subj, text = tostring(why or "") .. "\n\n" .. m.text })
            MS.save(b)
            return true
        end
    end
    return false
end

--- How many Inbox letters are not read yet.
function MS.unread(b)
    local n = 0
    for _, m in ipairs(MS.load(b).inbox) do if not m.read then n = n + 1 end end
    return n
end

--- Mark an Inbox letter read, and save.
function MS.markRead(b, m)
    if m.read then return end
    m.read = true
    MS.save(b)
end

--- Delete a letter. folder: "inbox" | "outbox" | "sent"; m: the letter itself.
function MS.remove(b, folder, m)
    local list = MS.load(b)[folder]
    for i, x in ipairs(list or {}) do
        if x == m then
            table.remove(list, i)
            MS.save(b)
            return true
        end
    end
    return false
end

--- Forget the mailbox list read so far: the next MS.boxes reads the index again (the sims start over).
function MS.reset()
    MS._boxes = nil
end

return MS
