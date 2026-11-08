-- ZeDUI/tools/qa/mail_sim.lua  (Nov 7 2026, punch list 104): mail with no game running. The harness is community_sim.lua's: Lua 5.1
-- stubs of the game and the real files run against them, ZeD_TicketProto, ZeD_MailProto, ZeD_ServerCore and ZeD_ServerMail on the
-- server, and on each simulated client ZeD_ServerLink, ZeD_Tickets, ZeD_MailStore and ZeD_Mail, each with its own Zomboid/Lua.
-- Every message crosses a stub of the network with the game's rules (an empty table arrives as nil, a string past 32767 is lost),
-- a step at a time.
--   validation of every field (the sender is the real player, lengths, a letter number, ids), offline delivery on join, the
--   outbox on connect, live delivery, the batches and their answers, the caps (inbox FIFO, the words in all, the players
--   known), the rate limits (between letters, the hour), a letter sent twice after a lost answer, returned mail, privacy
--   (the table never transmitted, nothing about a letter in the log, no command reads another's box), a restart, a frozen
--   table, a gate (a ban or the rules) refusing, a server without mail.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mail_sim.lua
-- It prints FAIL lines and a last line "mail_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mail_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ---------------------------------------------------------------------------
-- THE WORLD
-- ---------------------------------------------------------------------------
local W

local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end

local function events()
    return setmetatable({}, { __index = function(self, name)
        local ev = { list = {} }
        function ev.Add(fn) ev.list[#ev.list + 1] = fn end
        function ev.Remove(fn) for i = #ev.list, 1, -1 do if ev.list[i] == fn then table.remove(ev.list, i) end end end
        function ev.fire(...) for _, fn in ipairs(ev.list) do fn(...) end end
        rawset(self, name, ev)
        return ev
    end })
end

local function netCopy(v)
    local t = type(v)
    if t == "table" then
        local out = {}
        for k, x in pairs(v) do
            if type(k) ~= "string" and type(k) ~= "number" then error("a key the network drops: " .. type(k)) end
            out[k] = netCopy(x)
        end
        return out
    elseif t == "string" then
        if #v > 32767 then W.overlong = true; return "" end
        return v
    elseif t == "number" or t == "boolean" then
        return v
    end
    error("a value the network drops: " .. t)
end
local function wire(a)
    local c = netCopy(a or {})
    if next(c) == nil then return nil end
    return c
end
local function net(fn) W.net[#W.net + 1] = fn end
local function drain()
    local guard = 0
    while #W.net > 0 do
        guard = guard + 1
        if guard > 100000 then error("the network never drains") end
        table.remove(W.net, 1)()
    end
end
local function step(ms)
    W.clock = W.clock + ms
    for _, c in pairs(W.clients) do if c.up then c.env.Events.OnTick.fire() end end
    drain()
end
local function advance(ms)
    drain()
    while ms > 0 do
        local d = math.min(ms, 500)
        step(d)
        ms = ms - d
    end
end

local CAPS = { AnswerTickets = "AnswerTickets", RolesWrite = "RolesWrite" }
local function role(name, caps)
    return { name = name, caps = caps, getName = function(self) return self.name end,
             hasCapability = function(self, cap) if cap == nil then error("No implementation found: hasCapability(nil)") end return self.caps[cap] == true end,
             getPosition = function() return 1 end }
end
local ROLES = { user = role("user", {}), admin = role("admin", { AnswerTickets = true, RolesWrite = true }) }

local function player(name, roleName)
    local p = { name = name, role = ROLES[roleName or "user"], box = {} }
    function p.getUsername(self) return self.name end
    function p.getRole(self) return self.role end
    function p.getX() return 100 end
    function p.getY() return 100 end
    function p.getZ() return 0 end
    W.players[name] = p
    return p
end
local function online(p) W.online[#W.online + 1] = p end
local function offline(p)
    for i = #W.online, 1, -1 do if W.online[i] == p then table.remove(W.online, i) end end
    local c = W.clients[p.name]
    if c then c.up = false end
end

-- ---------------------------------------------------------------------------
-- THE TWO SIDES
-- ---------------------------------------------------------------------------
local function baseEnv()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.Events = events()
    env.print = function(s) env.printed = (env.printed or "") .. tostring(s) .. "\n" end
    env.getTimestampMs = function() return W.clock end
    env.getTimestamp = function() return math.floor(W.clock / 1000) end
    env.Capability = CAPS
    env.loaded = {}
    return env
end
local function runFile(env, rel)
    local f = assert(loadfile(ROOT .. rel))
    setfenv(f, env)
    return f()
end
local FILES = {
    ["ZeD/ZeD_TicketProto"] = "42/media/lua/shared/ZeD/ZeD_TicketProto.lua",
    ["ZeD/ZeD_MailProto"] = "42/media/lua/shared/ZeD/ZeD_MailProto.lua",
    ["ZeD/ZeD_ServerCore"] = "42/media/lua/server/ZeD/ZeD_ServerCore.lua",
    ["ZeD/ZeD_ServerLink"] = "42/media/lua/client/ZeD/ZeD_ServerLink.lua",
    ["ZeD/ZeD_Tickets"] = "42/media/lua/client/ZeD/ZeD_Tickets.lua",
    ["ZeD/ZeD_MailStore"] = "42/media/lua/client/ZeD/ZeD_MailStore.lua",
}
local function requireIn(env, name)
    if env.loaded[name] then return end
    env.loaded[name] = true
    if FILES[name] then runFile(env, FILES[name]) end
end

local function serverStart(noMail)
    local env = baseEnv()
    W.server = env
    env.isServer = function() return true end
    env.isClient = function() return false end
    env.require = function(n) requireIn(env, n) end
    env.getOnlinePlayers = function() return jlist(W.online) end
    env.getGameTime = function() return { getWorldAgeHours = function() return W.hours end } end
    env.getRandomUUID = function() W.uuid = W.uuid + 1; return "uuid-" .. W.uuid end
    env.writeLog = function(name, line) W.logs[#W.logs + 1] = { name = name, line = line } end
    env.ModData = {
        getTableNames = function()
            local n = {}
            for k in pairs(W.moddata) do n[#n + 1] = k end
            table.sort(n)
            return jlist(n)
        end,
        get = function(name) return W.moddata[name] end,
        getOrCreate = function(name) W.moddata[name] = W.moddata[name] or {}; return W.moddata[name] end,
        transmit = function() W.transmitted = true; error("a mail table must never be transmitted") end,
        request = function() error("server cannot request") end,
    }
    env.sendServerCommand = function(a, b, c, d)
        local to, module, command, args
        if type(a) == "table" then to, module, command, args = a, b, c, d else module, command, args = a, b, c end
        local copy = wire(args)
        local list = to and { to } or W.online
        for _, p in ipairs(list) do
            net(function()
                p.box[#p.box + 1] = { module = module, cmd = command, args = copy }
                local cl = W.clients[p.name]
                if cl and cl.up then cl.env.Events.OnServerCommand.fire(module, command, copy) end
            end)
        end
    end
    env.ISLogSystem = { writeLog = function() end }
    for _, n in ipairs({ "ZeD/ZeD_TicketProto", "ZeD/ZeD_MailProto", "ZeD/ZeD_ServerCore" }) do
        runFile(env, FILES[n]); env.loaded[n] = true
    end
    if not noMail then runFile(env, "42/media/lua/server/ZeD/ZeD_ServerMail.lua") end
    env.Events.OnInitGlobalModData.fire(false)
    return env
end

-- a client joins: its own Zomboid/Lua (kept across joins: the player's computer), the link, tickets' requests, the mail
local function clientJoin(p)
    local env = baseEnv()
    local disk = W.disks[p.name] or {}
    W.disks[p.name] = disk
    local c = { env = env, p = p, up = true, disk = disk, errors = {} }
    W.clients[p.name] = c
    online(p)
    env.isServer = function() return false end
    env.isClient = function() return true end
    env.require = function(n) requireIn(env, n) end
    env.getPlayer = function() return p end
    env.getText = function(k) return k end
    env.getTextOrNull = function() return nil end
    env.getServerIP = function() return W.ip end
    env.getServerPort = function() return W.port end
    env.getServerOptions = function() return { getOption = function() return "Test Server" end } end
    env.getFileWriter = function(name)
        local parts = {}
        return { write = function(_, s) parts[#parts + 1] = s end, close = function() disk[name] = table.concat(parts) end }
    end
    env.getFileReader = function(name)
        local body = disk[name]
        if not body then return nil end
        local at = 1
        return { readLine = function()
            local e = string.find(body, "\n", at, true)
            if not e then return nil end
            local l = string.sub(body, at, e - 1)
            at = e + 1
            return l
        end, close = function() end }
    end
    env.ZeD = {
        tr = function(k, ...)
            local a = { ... }
            if #a == 0 then return k end
            for i = 1, #a do a[i] = tostring(a[i]) end
            return k .. "(" .. table.concat(a, ",") .. ")"
        end,
        logOnce = function(k, m) c.errors[#c.errors + 1] = tostring(k) .. ": " .. tostring(m); check("no client error", false, tostring(k) .. ": " .. tostring(m)) end,
        Messages = { ticket = function() end, ticketNew = function() end, adminNote = function() end, sources = {},
                     add = function(name, kind, item) c.notes = (c.notes or 0) + 1; c.lastNote = item.text; return item end,
                     halo = function(text) c.halos = (c.halos or 0) + 1 end },
        -- the over-head notes and the player's own mute list (ZeD_Chat.lua keeps it per server, on this computer)
        Bubbles = { note = function(pn, text) c.bubbles = c.bubbles or {}; c.bubbles[#c.bubbles + 1] = text end },
        Chat = { myMutes = W.mutes[p.name] or {} },
    }
    local Ch = env.ZeD.Chat
    function Ch.mutedByMe(name) return Ch.myMutes[string.lower(tostring(name))] == true end
    function Ch.setMuted(name, on) Ch.myMutes[string.lower(name)] = on and true or nil; W.mutes[p.name] = Ch.myMutes end
    c.sounds = {}
    env.getSoundManager = function() return { playUISound = function(_, n) c.sounds[#c.sounds + 1] = n end } end
    env.ISAdminMessage = { AddAdminMessage = function() end }
    env.getTickets, env.addTicket = function() end, function() end
    env.sendClientCommand = function(pl, module, command, args)
        local a = wire(args)
        c.sentCmds = (c.sentCmds or 0) + 1
        net(function()
            if W.server.Events.OnClientCommand then W.server.Events.OnClientCommand.fire(module, command, W.as[pl.name] or pl, a) end
        end)
    end
    for _, n in ipairs({ "ZeD/ZeD_TicketProto", "ZeD/ZeD_MailProto", "ZeD/ZeD_ServerLink", "ZeD/ZeD_Tickets", "ZeD/ZeD_MailStore" }) do
        runFile(env, FILES[n]); env.loaded[n] = true
    end
    runFile(env, "42/media/lua/client/ZeD/ZeD_Mail.lua")
    env.Events.OnGameStart.fire()
    env.Events.OnCreatePlayer.fire(0, p)
    advance(4000)          -- (the dial-in waits a moment after the hello)
    return c
end
-- (a player who leaves is gone a while before joining again: the server's HELLO_MS and DIAL_MS have passed)
local function leave(c) offline(c.p); W.clock = W.clock + 6000 end

local function world()
    W = { clock = 1793913240000, net = {}, logs = {}, online = {}, players = {}, clients = {}, moddata = {}, hours = 300,
          uuid = 0, ip = "10.0.0.5", port = "16261", disks = {}, as = {}, mutes = {} }
end

-- a command straight from a client of anyone's making, as the server hears it
local function raw(p, command, args)
    W.server.Events.OnClientCommand.fire("ZeDP", command, p, args)
    drain()
end
local function lastAck(p)
    for i = #p.box, 1, -1 do
        local m = p.box[i]
        if m.cmd == "t_ack" then return m.args or {} end
    end
    return nil
end
local function count(p, cmd)
    local n = 0
    for _, m in ipairs(p.box) do if m.cmd == cmd then n = n + 1 end end
    return n
end
local function md()
    for k, v in pairs(W.moddata) do if string.sub(k, 1, 7) == "ZeD_ML_" then return v, k end end
    return nil
end
local function M(c) return c.env.ZeD.Mail end
local function MS(c) return c.env.ZeD.MailStore end
local function box(c) return M(c).box() end
local function inbox(c) return MS(c).load(box(c)).inbox end
local function outbox(c) return MS(c).load(box(c)).outbox end

-- ---------------------------------------------------------------------------
section("joining: the hello, the dial-in")
world()
serverStart()
local rosa, ned = player("Rosa"), player("Ned")
local cr = clientJoin(rosa)
check("the hello says mail is here", cr.env.ZeD.ServerPart.present == true and M(cr).here == true)
check("joining is the dial-in", M(cr).state == "on", tostring(M(cr).state) .. " " .. tostring(M(cr).why))
local tbl, tname = md()
check("the table has a secret random name", tbl ~= nil and tname ~= "ZeD_ML_" and #tname > 10, tname)
check("Rosa is known to the server", tbl.known.rosa and tbl.known.rosa.user == "Rosa")
check("a mailbox on Rosa's computer", box(cr) and box(cr).key == "10.0.0.5:16261/Rosa" and box(cr).server == "Test Server")
check("the dial-in time is kept", box(cr).t > 0)

section("writing in game: the outbox, delivered to an offline player")
local m1 = M(cr).write("Ned", "hello", "Meet at the gas station.")
check("a letter goes to the outbox", m1 ~= nil)
advance(1000)
check("returned: Ned has not been here since mail came", #outbox(cr) == 0 and inbox(cr)[1] and inbox(cr)[1].returned == true, inbox(cr)[1] and inbox(cr)[1].text)
check("the returned letter says why and keeps the words", inbox(cr)[1].text == "UI_ZeD_Mail_RetNobody(Ned)\n\nMeet at the gas station.")
local cn = clientJoin(ned)
check("Ned dials in", M(cn).state == "on")
leave(cn)
advance(100)
M(cr).write("ned", "", "Meet at the gas station.")
advance(3000)
check("sent: out of the outbox, into Sent", #outbox(cr) == 0 and #MS(cr).load(box(cr)).sent == 1)
tbl = md()
check("waiting on the server for Ned", tbl.boxes.ned and tbl.boxes.ned.n == 1)
local w = tbl.boxes.ned[1]
check("the sender is the real player", w.from == "Rosa")
check("the name as the server knows it", w.to == "Ned")
check("an empty subject is fine", w.subj == "")
check("the in-game day is on it", w.day == math.floor(300 / 24) + 1)

section("joining again: the inbox comes on connect, then the server forgets")
cn = clientJoin(ned)
advance(500)
check("Ned has the letter on his computer", #inbox(cn) == 1 and inbox(cn)[1].text == "Meet at the gas station." and inbox(cn)[1].from == "Rosa")
check("unread", MS(cn).unread(box(cn)) == 1)
check("a note in Messages", cn.notes == 1 and cn.lastNote == "UI_ZeD_Mail_NoteOne(Rosa)", cn.lastNote)
check("the server forgot it once Ned had it", md().boxes.ned == nil)
check("the words counted out again", md().chars == 0, md().chars)
check("it is on Ned's disk", (cn.disk["ZeD_mail_1.txt"] or ""):find("Meet at the gas station", 1, true) ~= nil)

section("live: a letter to a player who is on comes down at once")
advance(2500)
M(cr).write("Ned", "now", "You there?")
advance(500)
check("Ned has it at once", inbox(cn)[1] and inbox(cn)[1].subj == "now")
check("and the server has forgotten it", md().boxes.ned == nil)

section("the outbox on connect")
leave(cr)
advance(100)
-- at the desk: Rosa writes while not connected (the store alone, as the main menu's Mail does)
local rb = box(cr)
MS(cr).queue(rb, "Ned", "one", "first")
MS(cr).queue(rb, "Ned", "two", "second")
MS(cr).queue(rb, "Ned", "three", "third")
check("three in Rosa's outbox", #outbox(cr) == 3)
cr = clientJoin(rosa)
advance(8000)
check("on connect the whole outbox went, a letter at a time", #outbox(cr) == 0 and #MS(cr).load(box(cr)).sent == 5, #outbox(cr))
check("in the order written", inbox(cn)[1].subj == "three" and inbox(cn)[2].subj == "two" and inbox(cn)[3].subj == "one")

section("validation: every field, from a client of anyone's making")
local mallory = player("Mallory")
local cm = clientJoin(mallory)
leave(cn)              -- (Ned off: what is sent to him waits on the server, where these checks read it)
advance(2500)
mallory.box = {}
raw(mallory, "p_send", { to = "Ned", subj = "x", text = "forged", cid = "c1", from = "Rosa", rid = 5 })
check("a letter names its sender itself: never from the arguments", md().boxes.ned and md().boxes.ned[md().boxes.ned.n].from == "Mallory")
advance(2500)
local function refused(args, err, name)
    advance(2500)
    mallory.box = {}
    raw(mallory, "p_send", args)
    local a = lastAck(mallory)
    check(name, a and a.ok == false and a.err == err, a and tostring(a.err))
end
refused({ to = "Ned", text = "", cid = "c2", rid = 6 }, "text", "empty words are refused")
refused({ to = "Ned", text = string.rep("w", 2001), cid = "c3", rid = 7 }, "text", "words past TEXT_MAX are refused")
refused({ to = "Ned", text = "hi", subj = string.rep("s", 81), cid = "c4", rid = 8 }, "subj", "a subject past SUBJ_MAX is refused")
refused({ to = string.rep("n", 65), text = "hi", cid = "c5", rid = 9 }, "to", "a name past TO_MAX is refused")
refused({ to = "Nobody", text = "hi", cid = "c6", rid = 10 }, "to", "nobody by that name here")
refused({ to = "Ned", text = "hi", cid = "bad cid!", rid = 11 }, "bad", "a letter number with spaces is refused")
refused({ to = "Ned", text = "hi", rid = 12 }, "bad", "no letter number is refused")
refused({ to = { "Ned" }, text = "hi", cid = "c7", rid = 13 }, "to", "a table for a name is refused")
refused({ to = "Ned", text = 12, cid = "c8", rid = 14 }, "text", "a number for words is refused")
advance(2500)
mallory.box = {}
raw(mallory, "p_send", { to = "Ned", text = "a\1b\0", subj = "s\nt", cid = "c9", rid = 15 })
check("control characters cleaned, a subject's break flattened: taken", lastAck(mallory) and lastAck(mallory).ok == true)
local last = md().boxes.ned[md().boxes.ned.n]
check("control characters out", last.text == "ab", last.text)
check("a subject is one line", last.subj == "s t")
advance(2500)
mallory.box = {}
raw(mallory, "p_got", { ids = "all", rid = 16 })
check("p_got with no list is refused", lastAck(mallory) and lastAck(mallory).err == "bad")
advance(500)
local nedBefore = md().boxes.ned.n
raw(mallory, "p_got", { ids = { n = 2, md().boxes.ned[1].id, md().boxes.ned[2].id }, rid = 17 })
check("p_got only ever touches the player's own box", md().boxes.ned.n == nedBefore)
local ok = pcall(raw, mallory, "p_dial", nil)
check("an empty table (nil on the wire) does not break the server", ok)
check("nothing ever transmitted the table", W.transmitted == nil)

section("rate limits")
advance(5000)
mallory.box = {}
raw(mallory, "p_send", { to = "Ned", text = "a", cid = "r1", rid = 20 })
raw(mallory, "p_send", { to = "Ned", text = "b", cid = "r2", rid = 21 })
local a = lastAck(mallory)
check("a second letter inside SEND_MS waits", a and a.err == "wait" and a.left >= 1, a and a.err)
-- the hour's cap
for i = 1, 70 do
    W.clock = W.clock + 2100
    raw(mallory, "p_send", { to = "Rosa", text = "spam " .. i, cid = "h" .. i, rid = 100 + i })
end
a = lastAck(mallory)
check("past HOUR_MAX in an hour: refused", a and a.err == "hour", a and a.err)
W.clock = W.clock + 3600000
mallory.box = {}
raw(mallory, "p_send", { to = "Rosa", text = "an hour on", cid = "h999", rid = 300 })
check("an hour on, letters go again", lastAck(mallory) and lastAck(mallory).ok == true)

section("the caps")
advance(70000)         -- (Rosa's client answers a handover a second)
local rbox = md().boxes.rosa
check("Rosa is on: every letter came down at once, none waits", rbox == nil, rbox and rbox.n)
-- Rosa is online: her client takes them; take her off to see the box
leave(cr)
advance(100)
local firstId = nil
for i = 1, 55 do
    W.clock = W.clock + 3700000 / 55
    raw(ned, "p_send", { to = "Rosa", text = "letter " .. i, cid = "f" .. i, rid = 400 + i })
end
rbox = md().boxes.rosa
check("FIFO: never more than INBOX_MAX waiting", rbox.n == 50, rbox.n)
check("FIFO: the oldest went", rbox[1].text ~= "letter 1" and rbox[rbox.n].text == "letter 55", rbox[1].text)
local total = 0
for _, b in pairs(md().boxes) do for i = 1, b.n do total = total + #b[i].text + #b[i].subj end end
check("the words in all are counted right", md().chars == total, md().chars .. " vs " .. total)

section("a letter sent twice after a lost answer")
advance(3000)
ned.box = {}
raw(ned, "p_send", { to = "Mallory", text = "once", cid = "dup1", rid = 600 })
advance(3000)
local inBefore = count(mallory, "p_in")
raw(ned, "p_send", { to = "Mallory", text = "once", cid = "dup1", rid = 601 })
a = lastAck(ned)
check("the same letter number answers ok again", a and a.ok == true and a.again == true)
check("and delivers nothing more", count(mallory, "p_in") == inBefore and inBefore >= 1, inBefore)

section("batches: a full box comes down in BATCH-sized handovers")
cr = clientJoin(rosa)
advance(10000)
check("all fifty on Rosa's computer", #inbox(cr) >= 50, #inbox(cr))
check("the server kept none", md().boxes.rosa == nil)
check("each batch was a separate handover", count(rosa, "p_in") >= 5, count(rosa, "p_in"))
local ids = {}
local dupes = 0
for _, m in ipairs(inbox(cr)) do if ids[m.id] and m.id ~= 0 then dupes = dupes + 1 end; ids[m.id] = true end
check("no letter twice", dupes == 0)

section("a handover lost: the next dial-in brings it again, once")
leave(cr)
advance(100)
W.clock = W.clock + 3000
raw(ned, "p_send", { to = "Rosa", text = "lost then found", cid = "lost1", rid = 700 })
-- Rosa joins but her p_got is lost on the wire
cr = clientJoin(rosa)
check("she has it", inbox(cr)[1].text == "lost then found")
local before = #inbox(cr)
md().boxes.rosa = md().boxes.rosa or { n = 1, md().boxes.rosa }
-- the server still holding it (as if the answer were lost): it comes again at the next dial-in
local tb = md()
tb.boxes.rosa = { n = 1, { id = inbox(cr)[1].id, from = "Ned", to = "Rosa", subj = "", text = "lost then found", t = 1, day = 1 } }
tb.chars = tb.chars + #"lost then found"
leave(cr)
advance(100)
cr = clientJoin(rosa)
check("a letter that comes again is kept once", #inbox(cr) == before, #inbox(cr) .. " vs " .. before)
check("and the server lets go of it", md().boxes.rosa == nil)

section("privacy")
local said = {}
for _, l in ipairs(W.logs) do said[#said + 1] = l.line end
local all = table.concat(said, "\n")
check("no letter's words in the log", not all:find("Meet at the gas station", 1, true) and not all:find("lost then found", 1, true))
-- (the log holds only the part's own lines: up, frozen, a table found twice; never a letter, never who wrote to whom)
local mailLines = 0
for _, l in ipairs(W.logs) do
    if l.line:find("mail", 1, true) or l.line:find("p_send", 1, true) or l.line:find("p_dial", 1, true) then
        if not (l.line:find("mail table", 1, true) or l.line:find("bad arguments", 1, true)) then mailLines = mailLines + 1 end
    end
end
check("not who wrote to whom either: no line about a letter", mailLines == 0, mailLines)
check("a bad argument says only the command", (function()
    for _, l in ipairs(W.logs) do
        if l.line:find("bad arguments", 1, true) and (l.line:find("forged", 1, true) or l.line:find("Ned", 1, true)) then return false end
    end
    return true
end)())
local admin = player("Ada", "admin")
local ca = clientJoin(admin)
check("an admin's hello carries only the flag", (function()
    for _, m in ipairs(admin.box) do
        if m.cmd == "hello" then return m.args.ml == 1 and m.args.mail == nil end
    end
    return false
end)())
admin.box = {}
for _, cmd in ipairs({ "p_list", "p_read", "p_all", "p_view" }) do raw(admin, cmd, { user = "Rosa", rid = 1 }) end
check("no command reads anyone's box: unknown commands get nothing", #admin.box == 0)
check("an admin's dial-in brings only the admin's own box", (function()
    for _, m in ipairs(admin.box) do if m.cmd == "p_in" then return false end end
    return true
end)())

section("a gate (a ban, the rules) refusing: the outbox waits")
leave(cr)
advance(100)
local Srv = W.server.ZeD.Srv
for key, h in pairs(Srv.handlers) do
    if string.sub(key, 1, 5) == "ZeDP." then
        local base = h.fn
        h.fn = function(p, args, rid)
            if W.shut and W.shut[p:getUsername()] then Srv.ack(p, rid, false, "perm"); return end
            return base(p, args, rid)
        end
    end
end
W.shut = { Rosa = true }
MS(cr).queue(box(cr), "Ned", "gated", "held")
cr = clientJoin(rosa)
advance(3000)
check("refused: the dial-in did not happen", M(cr).state == "off" and M(cr).why == "perm", tostring(M(cr).state))
check("the outbox kept the letter", #outbox(cr) == 1 and outbox(cr)[1].subj == "gated")
W.shut = nil
M(cr).dial()
advance(4000)
check("allowed again (agreed, unbanned): the dial-in sends it", #outbox(cr) == 0)

section("a restart: what waits survives, the hour's count does not")
leave(cr)
advance(100)
W.clock = W.clock + 3000
raw(ned, "p_send", { to = "Rosa", text = "after the restart", cid = "rs1", rid = 800 })
serverStart()
check("the same table found again", md().boxes.rosa and md().boxes.rosa.n == 1)
cr = clientJoin(rosa)
check("delivered after a restart", inbox(cr)[1].text == "after the restart")

section("a frozen table (data from a newer ZeD)")
leave(cr)
local t2 = md()
t2.schema = 99
serverStart()
ned.box = {}
W.clock = W.clock + 3000
raw(ned, "p_send", { to = "Rosa", text = "x", cid = "fz1", rid = 900 })
check("a frozen table takes no letters", lastAck(ned) and lastAck(ned).err == "frozen")
check("and says so in the log", (function() for _, l in ipairs(W.logs) do if l.line:find("mail table frozen", 1, true) then return true end end return false end)())
t2.schema = 1

section("the dial-in: the modem once a connection, the note over the head")
world()
serverStart()
local dee, eve = player("Dee"), player("Eve")
local ce = clientJoin(eve)
leave(ce)
local cd = clientJoin(dee)
leave(cd)
MS(cd).queue(box(cd), "Eve", "", "one")
W.clock = W.clock + 3000
raw(eve, "p_send", { to = "Dee", text = "hello Dee", cid = "e1", rid = 1 })
W.clock = W.clock + 3000
raw(eve, "p_send", { to = "Dee", text = "again", cid = "e2", rid = 2 })
cd = clientJoin(dee)
check("the modem plays once at the dial-in", #cd.sounds == 1 and cd.sounds[1] == "ZeDModemDial", #cd.sounds)
check("the note over the head: sending 1, receiving 2", cd.bubbles and cd.bubbles[1] == "UI_ZeD_Mail_Connecting(1,2)", cd.bubbles and cd.bubbles[1])
check("and it is kept in Messages' log of over-head notes", (cd.halos or 0) == 1)
M(cd).state = nil
M(cd).dial()
advance(6000)
check("a second dial-in in the same connection plays nothing more", #cd.sounds == 1 and #cd.bubbles == 1, #cd.sounds)
check("the sound's script is the mod's own, a UI sound on a .wav made here", (function()
    local f = io.open(ROOT .. "42/media/scripts/ZeD_Sounds.txt", "r")
    if not f then return false end
    local t = f:read("*a"); f:close()
    local w = io.open(ROOT .. "42/media/sound/ZeD_modem.wav", "rb")
    if not w then return false end
    local head = w:read(12); w:close()
    return t:find("sound ZeDModemDial", 1, true) ~= nil and t:find("category = UI", 1, true) ~= nil and t:find("media/sound/ZeD_modem.wav", 1, true) ~= nil
        and head:sub(1, 4) == "RIFF" and head:sub(9, 12) == "WAVE"
end)())

section("mute: a muted player's letters stop, and the sender is told nothing")
leave(cd)
W.mutes.Dee = { eve = true }
W.clock = W.clock + 3000
raw(eve, "p_send", { to = "Dee", text = "you muted me", cid = "e3", rid = 3 })
check("before Dee dials again, it waits (the server has not heard of the mute yet)", md().boxes.dee and md().boxes.dee.n == 1)
cd = clientJoin(dee)
check("the mute list goes with the dial-in", md().mutes.dee and md().mutes.dee.eve == true)
check("a letter waiting from someone muted goes, unread", (function()
    for _, m in ipairs(inbox(cd)) do if m.text == "you muted me" then return false end end
    return true
end)() and md().boxes.dee == nil)
eve.box = {}
W.clock = W.clock + 3000
raw(eve, "p_send", { to = "Dee", text = "still muted", cid = "e4", rid = 4 })
local a4 = lastAck(eve)
check("the sender gets the same ok as any letter", a4 and a4.ok == true and a4.to == "Dee" and a4.err == nil)
check("and the same fields: nothing says muted", a4 and a4.muted == nil and a4.again == nil)
advance(3000)
check("nothing delivered to Dee", md().boxes.dee == nil and (function()
    for _, m in ipairs(inbox(cd)) do if m.text == "still muted" then return false end end
    return true
end)())
local inN = count(dee, "p_in")
cd.env.ZeD.Chat.setMuted("Eve", false)
advance(2500)
check("unmuting reaches the server at once", md().mutes.dee == nil)
W.clock = W.clock + 3000
raw(eve, "p_send", { to = "Dee", text = "heard now", cid = "e5", rid = 5 })
advance(3000)
check("letters come again", inbox(cd)[1] and inbox(cd)[1].text == "heard now" and count(dee, "p_in") > inN)
cd.env.ZeD.Chat.setMuted("eve", true)
advance(2500)
check("muting while on reaches the server at once", md().mutes.dee and md().mutes.dee.eve == true)
advance(2500)
dee.box = {}
raw(dee, "p_mute", { names = "everyone", rid = 9 })
check("a mute list that is not a list is refused", lastAck(dee) and lastAck(dee).err == "bad")
advance(2500)
local many = { n = 201 }
for i = 1, 201 do many[i] = "p" .. i end
raw(dee, "p_mute", { names = many, rid = 10 })
check("past MUTES_MAX is refused", lastAck(dee) and lastAck(dee).err == "bad")
check("no line in the log says who muted whom", (function()
    for _, l in ipairs(W.logs) do if l.line:find("mute", 1, true) and not l.line:find("bad arguments", 1, true) then return false end end
    return true
end)())

section("a server without mail")
world()
serverStart(true)
local solo = player("Solo")
local cs = clientJoin(solo)
check("the hello says nothing of mail", M(cs).here == false)
check("no dial-in", M(cs).state == nil)
check("writing still lands in the outbox for later", (function() local m = M(cs).write("x", "", "kept"); return m ~= nil and #outbox(cs) == 1 end)())

section("the store on its own")
local S2 = MS(cs)
check("fields round-trip through escaping", S2.unesc(S2.esc("a|b\\c\nd")) == "a|b\\c\nd")
check("a carriage return is dropped", S2.esc("a\r\nb") == "a\\nb")
local qb = box(cs)
for i = 1, S2.OUT_MAX do S2.queue(qb, "x", "", "n" .. i) end
local qn, qe = S2.queue(qb, "x", "", "too many")
check("the outbox holds OUT_MAX and says full", qn == nil and qe == "full")
check("an empty letter cannot be queued", select(2, S2.queue(box(cs), "x", "", "   ")) ~= nil)
S2.reset()
qb.data = nil
check("the outbox comes back from the disk", #S2.load(qb).outbox == S2.OUT_MAX)

print("mail_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
