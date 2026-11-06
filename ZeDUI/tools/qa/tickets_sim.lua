-- ZeDUI/tools/qa/tickets_sim.lua  (Nov 5 2026, QA): the ticket server part with no game running.
-- Lua 5.1 stubs of getOnlinePlayers, ModData, sendServerCommand, Capability and the game's ticket table, and the real
-- files run against them: ZeD_TicketProto, ZeD_ServerCore, ZeD_ServerTickets, and on each simulated client
-- ZeD_ServerLink and ZeD_Tickets. Every message crosses a stub of the network with the game's own rules (no functions,
-- an empty top table arrives as nil, a string over 32767 bytes comes back empty), a step at a time.
-- Permissions, limits, views, caps, the sync with the game's table, restarts, and everything Part D asks of steps 1 to 7
-- that does not need the engine. Run from the repo root:
--   lua51 ZeDUI/tools/qa/tickets_sim.lua
-- It prints FAIL lines and a last line "tickets_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]tickets_sim%.lua$", "")

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
local W            -- the world of the current test: clock, network, logs, the game's table, the players

local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end

local function events()
    local E = {}
    return setmetatable({}, { __index = function(self, name)
        local ev = { list = {} }
        function ev.Add(fn) ev.list[#ev.list + 1] = fn end
        function ev.Remove(fn)
            for i = #ev.list, 1, -1 do if ev.list[i] == fn then table.remove(ev.list, i) end end
        end
        function ev.fire(...)
            for _, fn in ipairs(ev.list) do fn(...) end
        end
        rawset(self, name, ev)
        return ev
    end })
end

local function netCopy(v, seen)
    local t = type(v)
    if t == "table" then
        local out = {}
        for k, x in pairs(v) do
            if type(k) ~= "string" and type(k) ~= "number" then error("a key the network drops: " .. type(k)) end
            out[k] = netCopy(x)
        end
        return out
    elseif t == "string" then
        W.bytes = W.bytes + #v
        if #v > 32767 then W.overlong = true; return "" end
        return v
    elseif t == "number" or t == "boolean" then
        W.bytes = W.bytes + 8
        return v
    end
    error("a value the network drops: " .. t)
end

-- the top table over the wire; empty arrives as nil
local function wire(a)
    W.bytes = 0
    local c = netCopy(a or {})
    W.biggest = math.max(W.biggest, W.bytes)
    if next(c) == nil then return nil end
    return c
end

local function drain()
    local guard = 0
    while #W.net > 0 do
        guard = guard + 1
        if guard > 100000 then error("the network never drains") end
        local fn = table.remove(W.net, 1)
        fn()
    end
end
local function net(fn) W.net[#W.net + 1] = fn end

local function step(ms)
    W.clock = W.clock + ms
    for _, c in pairs(W.clients) do
        if c.up then c.env.Events.OnTick.fire() end
    end
    drain()
end
local function advance(ms)
    drain()
    while ms > 0 do
        local d = math.min(ms, 100)
        step(d)
        ms = ms - d
    end
end

local CAPS = { AnswerTickets = "AnswerTickets", RolesWrite = "RolesWrite", TeleportToCoordinates = "TeleportToCoordinates" }
local function role(name, caps)
    local r = { name = name, caps = caps }
    function r.getName(self) return self.name end
    function r.hasCapability(self, cap)
        if cap == nil then error("No implementation found: hasCapability(nil)") end
        return self.caps[cap] == true
    end
    return r
end
local ROLES = {
    user = role("user", {}),
    observer = role("observer", {}),
    moderator = role("moderator", { AnswerTickets = true }),
    admin = role("admin", { AnswerTickets = true, RolesWrite = true }),
}

local function player(name, roleName, x, y, z)
    local p = { name = name, role = ROLES[roleName or "user"], x = x or 6280.5, y = y or 5350.5, z = z or 0, box = {} }
    function p.getUsername(self) return self.name end
    function p.getRole(self) return self.role end
    function p.getX(self) return self.x end
    function p.getY(self) return self.y end
    function p.getZ(self) return self.z end
    W.online[#W.online + 1] = p
    W.players[name] = p
    return p
end
local function offline(p)
    for i = #W.online, 1, -1 do if W.online[i] == p then table.remove(W.online, i) end end
    local c = W.clients[p.name]
    if c then c.up = false end
end

-- the game's own ticket table, as ServerWorldDatabase keeps it: ids never reused, answers rows of their own
local function gameAdd(author, msg, answered)
    W.gameNext = W.gameNext + 1
    local row = { id = W.gameNext, author = author, msg = msg, viewed = false, answered = answered }
    W.game[#W.game + 1] = row
    return row
end
local function gameFind(id)
    for _, r in ipairs(W.game) do if r.id == id and not r.answered then return r end end
    return nil
end
local function gameRemove(id)
    for i = #W.game, 1, -1 do
        local r = W.game[i]
        if r.id == id or r.answered == id then table.remove(W.game, i) end
    end
end
local function dbTicket(r)
    local o = {}
    function o.getTicketID() return r.id end
    function o.getAuthor() return r.author end
    function o.getMessage() return r.msg end
    function o.isViewed() return r.viewed end
    function o.getAnswer()
        for _, a in ipairs(W.game) do
            if a.answered == r.id then return dbTicket(a) end
        end
        return nil
    end
    return o
end
local function gameList(author)
    local out = {}
    for _, r in ipairs(W.game) do
        if not r.answered and (author == nil or author == "" or r.author == author) then out[#out + 1] = dbTicket(r) end
    end
    return jlist(out)
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
    ["ZeD/ZeD_ServerCore"] = "42/media/lua/server/ZeD/ZeD_ServerCore.lua",
    ["ZeD/ZeD_ServerLink"] = "42/media/lua/client/ZeD/ZeD_ServerLink.lua",
}
local function requireIn(env, name)
    if env.loaded[name] then return end
    env.loaded[name] = true
    if FILES[name] then runFile(env, FILES[name]) end
end

local function serverStart()
    local env = baseEnv()
    W.server = env
    env.isServer = function() return true end
    env.isClient = function() return false end
    env.require = function(n) requireIn(env, n) end
    env.getOnlinePlayers = function() return jlist(W.online) end
    env.getGameTime = function() return { getWorldAgeHours = function() return W.hours end } end
    env.getRandomUUID = function()
        W.uuid = W.uuid + 1
        return "11111111-2222-3333-4444-" .. string.format("%012d", W.uuid)
    end
    env.getServerOptions = function()
        return { getInteger = function(_, name) if name == "SaveWorldEveryMinutes" then return W.saveMinutes end return nil end }
    end
    env.writeLog = function(name, line) W.logs[#W.logs + 1] = { name = name, line = line } end
    env.ModData = {
        getTableNames = function()
            local n = {}
            for k in pairs(W.moddata) do n[#n + 1] = k end
            table.sort(n)
            return jlist(n)
        end,
        get = function(name) return W.moddata[name] end,
        getOrCreate = function(name)
            W.moddata[name] = W.moddata[name] or {}
            return W.moddata[name]
        end,
        transmit = function() error("the ticket table must never be transmitted") end,
    }
    env.sendServerCommand = function(p, module, command, args)
        local a = wire(args)
        net(function()
            p.box[#p.box + 1] = { module = module, cmd = command, args = a }
            local c = W.clients[p.name]
            if c and c.up then c.env.Events.OnServerCommand.fire(module, command, a) end
        end)
    end
    env.ISLogSystem = { writeLog = function(who, packet) W.logs[#W.logs + 1] = { name = packet.loggerName, line = packet.logText } end }
    runFile(env, "42/media/lua/shared/ZeD/ZeD_TicketProto.lua")
    env.loaded["ZeD/ZeD_TicketProto"] = true
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerCore.lua")
    env.loaded["ZeD/ZeD_ServerCore"] = true
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerTickets.lua")
    env.Events.OnInitGlobalModData.fire(false)
    return env
end

-- a game client for this player: the real link and model, with the game's four ticket calls stubbed
local function clientJoin(p)
    local env = baseEnv()
    local c = { env = env, p = p, up = true }
    W.clients[p.name] = c
    env.isServer = function() return false end
    env.isClient = function() return true end
    env.require = function(n) requireIn(env, n) end
    env.getPlayer = function() return p end
    local notes, modals = {}, {}
    c.notes, c.modals = notes, modals
    local msgs = {}
    c.msgs = msgs
    env.ZeD = {
        tr = function(k) return k end,
        logOnce = function(k, m) check("no client error", false, tostring(k) .. ": " .. tostring(m)) end,
        Messages = {
            ticket = function(id, who) notes[#notes + 1] = { id = id, who = who } end,
            ticketNew = function() msgs[#msgs + 1] = "new" end,
        },
    }
    env.ISAdminMessage = { AddAdminMessage = function(m) modals[#modals + 1] = m end }
    env.Events.OnAdminMessage.Add(env.ISAdminMessage.AddAdminMessage)
    local function view(author)
        return function() net(function() if c.up then env.Events.ViewTickets.fire(gameList(author)) end end) end
    end
    env.sendClientCommand = function(pl, module, command, args)
        local a = wire(args)
        net(function()
            if W.server.Events.OnClientCommand then W.server.Events.OnClientCommand.fire(module, command, pl, a) end
        end)
    end
    env.getTickets = function(name) W.calls.getTickets = W.calls.getTickets + 1; view(name)() end
    env.addTicket = function(author, msg, id)
        W.calls.addTicket = W.calls.addTicket + 1
        if id == -1 then
            gameAdd(author, msg)
            for _, o in ipairs(W.online) do
                local oc = W.clients[o.name]
                if oc and oc.up and o.role.caps.AnswerTickets then
                    net(function() oc.env.Events.OnAdminMessage.fire("user " .. author .. " added a ticket <LINE> <LINE> " .. msg, -1, -1, -1) end)
                end
            end
            view(author)()
        else
            gameAdd(author, msg, id)
            view(nil)()
        end
    end
    env.viewedTicket = function(author, id)
        if not p.role.caps.AnswerTickets then return end
        W.calls.viewedTicket = W.calls.viewedTicket + 1
        local r = gameFind(id)
        if r then r.viewed = true end
        view(nil)()
    end
    env.removeTicket = function(id)
        if not p.role.caps.AnswerTickets then return end
        W.calls.removeTicket = W.calls.removeTicket + 1
        gameRemove(id)
        view(nil)()
    end
    runFile(env, "42/media/lua/shared/ZeD/ZeD_TicketProto.lua")
    env.loaded["ZeD/ZeD_TicketProto"] = true
    runFile(env, "42/media/lua/client/ZeD/ZeD_ServerLink.lua")
    env.loaded["ZeD/ZeD_ServerLink"] = true
    runFile(env, "42/media/lua/client/ZeD/ZeD_Tickets.lua")
    env.Events.OnCreatePlayer.fire(0, p)
    advance(200)
    return c
end

local function world()
    W = { clock = 1793913240000, net = {}, logs = {}, online = {}, players = {}, clients = {}, moddata = {}, game = {},
        gameNext = 0, hours = 12.5 * 24, uuid = 0, bytes = 0, biggest = 0, saveMinutes = 0,
        calls = { getTickets = 0, addTicket = 0, viewedTicket = 0, removeTicket = 0 } }
    serverStart()
end

-- a raw command, as a client with a Lua console could send it
local function say(p, module, command, args)
    p.box = {}
    local a = wire(args)
    net(function() W.server.Events.OnClientCommand.fire(module, command, p, a) end)
    drain()
end
local function tk(p, command, args) say(p, "ZeDT", command, args) end
local function got(p, cmd)
    for i = #p.box, 1, -1 do
        if p.box[i].cmd == cmd then return p.box[i].args or {} end
    end
    return nil
end
local function errOf(p)
    local a = got(p, "t_ack")
    return a and a.err or nil
end
local function md() return W.server.ZeD.Srv.T.md end
local function rec(id) return md().tickets[id] end
local function setRole(p, name) p.role = ROLES[name] end
local function logHas(text)
    for _, l in ipairs(W.logs) do
        if string.find(l.line, text, 1, true) then return true end
    end
    return false
end
local function logCount(text)
    local n = 0
    for _, l in ipairs(W.logs) do
        if string.find(l.line, text, 1, true) then n = n + 1 end
    end
    return n
end
local function newTicket(p, kind, text, here)
    advance(0)
    W.server.ZeD.Srv.mem[p.name] = nil
    tk(p, "t_new", { kind = kind or "BUG", text = text or "words", here = here })
    local a = got(p, "t_ack")
    return a and a.id, a
end
-- every key anywhere in a table
local function keysIn(v, out)
    out = out or {}
    if type(v) == "table" then
        for k, x in pairs(v) do
            out[k] = true
            keysIn(x, out)
        end
    end
    return out
end
local function valuesHave(v, word)
    if type(v) == "string" then return string.find(v, word, 1, true) ~= nil end
    if type(v) == "table" then
        for _, x in pairs(v) do if valuesHave(x, word) then return true end end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- STEP 1: PROTOCOL AND HELLO
-- ---------------------------------------------------------------------------
section("step 1: the hello")
do
    world()
    local Tk = W.server.ZeD.Tk
    check("the server logs that the part is up", logHas("server part up"))
    check("the 42.22 kinds are six", #Tk.KINDS == 6)
    check("nearby is 30 tiles", Tk.NEAR == 30)
    check("E12 is as drawn", Tk.REPLY_AT_ANSWERED == false)
    check("E13 is filed in full", Tk.FILE_FULL_TEXT == true)

    local admin = player("zedqa", "admin")
    local c = clientJoin(admin)
    local S = c.env.ZeD.ServerPart
    check("client: present", S.present == true)
    check("client: v 1", S.v == 1)
    check("client: staff and admin", S.staff == true and S.admin == true)

    local plain = player("rosa", "user")
    say(plain, "ZeD", "hello", { v = 1 })
    local h = got(plain, "hello")
    check("a plain player: not staff", h and h.staff == false and h.admin == false)
    check("a plain player: no counts", h and h.open == nil and h.spam == nil)
    say(plain, "ZeD", "hello", { v = 1 })
    check("hello 1 per 5 s answers wait, with seconds", errOf(plain) == "wait" and got(plain, "t_ack").left == 5)
    advance(5000)
    say(plain, "ZeD", "hello", {})
    check("empty args arrive as nil: still answered", got(plain, "hello") ~= nil)

    -- every server file on a client does nothing (it runs there too)
    local env = baseEnv()
    env.isServer = function() return false end
    env.isClient = function() return true end
    env.require = function() end
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerCore.lua")
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerTickets.lua")
    check("server files on a client: nothing", env.ZeD == nil and #env.Events.OnClientCommand.list == 0)

    -- a capability missing: off, no listener, and no hasCapability(nil)
    local env2 = baseEnv()
    env2.isServer = function() return true end
    env2.isClient = function() return false end
    env2.require = function() end
    env2.Capability = { AnswerTickets = "AnswerTickets" }
    env2.writeLog = function() end
    runFile(env2, "42/media/lua/shared/ZeD/ZeD_TicketProto.lua")
    runFile(env2, "42/media/lua/server/ZeD/ZeD_ServerCore.lua")
    runFile(env2, "42/media/lua/server/ZeD/ZeD_ServerTickets.lua")
    check("a capability gone: the part stays off", env2.ZeD.Srv.off == true and #env2.Events.OnClientCommand.list == 0)

    -- no reply: asks at 10 s and 30 s, then present is false; a late reply still flips it
    world()
    local q = player("q", "user")
    W.server.Events.OnClientCommand.list = {}
    local cq = clientJoin(q)
    check("no server part: unknown at first", cq.env.ZeD.ServerPart.present == nil)
    local asked = 0
    local real = cq.env.sendClientCommand
    cq.env.sendClientCommand = function(...) asked = asked + 1; return real(...) end
    advance(41000)
    check("no server part: asks twice more", asked == 2, asked)
    check("no server part: present false", cq.env.ZeD.ServerPart.present == false)
    cq.env.Events.OnServerCommand.fire("ZeD", "hello", { v = 1, staff = false, admin = false })
    check("a late reply flips it true", cq.env.ZeD.ServerPart.present == true)

    -- the writeLog channel is closed to the ZeD logger
    world()
    local W1 = #W.logs
    local IL = W.server.ISLogSystem
    for _, n in ipairs({ "ZeD", "zed", "Z-e_D", "myZED2" }) do IL.writeLog(nil, { loggerName = n, logText = "forged" }) end
    check("no line through ISLogSystem to the ZeD log", #W.logs == W1)
    IL.writeLog(nil, { loggerName = "admin", logText = "fine" })
    check("other loggers still pass", #W.logs == W1 + 1)
end

-- ---------------------------------------------------------------------------
-- STEP 2: THE TABLE
-- ---------------------------------------------------------------------------
section("step 2: the table")
do
    world()
    local name
    for k in pairs(W.moddata) do name = k end
    check("made with the secret prefix and a UUID", name and string.find(name, "^ZeD_TK_%x+%-") ~= nil, name)
    check("no table named ZeD_Tickets", W.moddata["ZeD_Tickets"] == nil)
    local p = player("rosa")
    newTicket(p, "BUG", "one")
    newTicket(p, "BUG", "two")
    for _, l in ipairs(W.logs) do check("the name is in no log", not string.find(l.line, name, 1, true)) end
    check("the name is in no print", not string.find(W.server.printed or "", name, 1, true))
    local all = keysIn(p.box)
    check("the name goes in no message", not valuesHave(p.box, name))

    -- a restart: the same table, nextId kept, the limits' memory gone
    local Next = md().nextId
    serverStart()
    local cnt = 0
    for _ in pairs(W.moddata) do cnt = cnt + 1 end
    check("restart: one table", cnt == 1)
    check("restart: nextId kept", md().nextId == Next and rec(1) ~= nil)
    tk(p, "t_new", { kind = "BUG", text = "after the restart" })
    check("restart: a free ticket, as designed", got(p, "t_ack").ok == true)

    -- /reloadlua of both server files: one reply per command, table still open
    local env = W.server
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerCore.lua")
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerTickets.lua")
    check("reload: one listener", #env.Events.OnClientCommand.list == 1)
    advance(6000)
    tk(p, "t_mine", {})
    local n = 0
    for _, m in ipairs(p.box) do if m.cmd == "t_mine" then n = n + 1 end end
    check("reload: one reply per command, and the table is open", n == 1 and got(p, "t_mine").n == 3)

    -- two tables: the most tickets wins, a line in the log, no merge
    world()
    local p2 = player("rosa")
    newTicket(p2, "BUG", "a")
    W.moddata["ZeD_TK_planted"] = { schema = 1, nextId = 9, gameMax = 0, skipped = 0, chars = 0, tickets = {} }
    serverStart()
    check("two tables: the one with more tickets", rec(1) ~= nil)
    check("two tables: a line, and no name in it", logHas("found 2 ticket tables") and not logHas("planted"))

    -- newer data: read it, never change it
    world()
    local p3 = player("rosa")
    local admin = player("zedqa", "admin")
    local id = newTicket(p3, "BUG", "a")
    md().schema = 2
    serverStart()
    W.server.ZeD.Srv.mem = {}
    tk(p3, "t_new", { kind = "BUG", text = "b" })
    check("frozen: a write answers frozen", errOf(p3) == "frozen")
    tk(p3, "t_one", { id = id })
    check("frozen: a read still works", got(p3, "t_one") ~= nil)
    say(p3, "ZeD", "hello", {})
    check("frozen: the hello says so", got(p3, "hello").frozen == true)
    tk(admin, "t_card", { id = id })
    check("frozen: staff read, status unchanged", got(admin, "t_card") ~= nil and rec(id).status == "Open")
    tk(admin, "t_close", { id = id })
    check("frozen: staff write refused", errOf(admin) == "frozen")

    -- a failed migration stops and writes nothing
    world()
    md().schema = 0
    serverStart()
    local p4 = player("mags")
    say(p4, "ZeD", "hello", {})
    check("a missing migration step freezes", got(p4, "hello").frozen == true and md().schema == 0)
end

-- ---------------------------------------------------------------------------
-- STEP 3: FILING AND THE PLAYER'S COMMANDS
-- ---------------------------------------------------------------------------
section("step 3: the player's commands")
do
    world()
    local p = player("kade", "user", 6280.7, 5350.2, 1)
    local id = newTicket(p, "GRIEF", "  my truck  ", true)
    local a = got(p, "t_ack")
    local r = rec(id)
    check("t_new: ok, with the id and the file text", a.ok and a.id == 1 and a.file == "[GRIEF #1] my truck", a.file)
    check("trimmed", r.thread[1].text == "my truck")
    check("stamped by the server", r.author == "kade" and r.day == 13 and r.filed == math.floor(W.clock / 1000))
    check("place from the server", r.place.x == 6280 and r.place.y == 5350 and r.place.z == 1)

    world()
    local liar = player("liar", "user", 100, 200, 0)
    tk(liar, "t_new", { kind = "BUG", text = "x", here = true, author = "rosa", x = 1, y = 2, day = 99, status = "Closed", place = { x = 5 } })
    local rr = rec(got(liar, "t_ack").id)
    check("lying args change nothing", rr.author == "liar" and rr.place.x == 100 and rr.day == 13 and rr.status == "Open")

    world()
    local t = player("len")
    tk(t, "t_new", { kind = "BUG", text = string.rep("a", 1001) })
    check("1001 characters refused", errOf(t) == "text")
    tk(t, "t_new", { kind = "BUG", text = string.rep("a", 1000) })
    check("1000 characters taken", got(t, "t_ack").ok == true)
    tk(t, "t_new", { kind = "BUG", text = "again" })
    local ack = got(t, "t_ack")
    check("a second inside 60 s: wait, with seconds left", ack.err == "wait" and ack.left == 60, ack.left)
    advance(59000)
    tk(t, "t_new", { kind = "BUG", text = "again" })
    check("still waiting at 59 s", errOf(t) == "wait" and got(t, "t_ack").left == 1)
    advance(1000)
    tk(t, "t_new", { kind = "BUG", text = "  \n  " })
    check("nothing but spaces: text", errOf(t) == "text")
    tk(t, "t_new", { kind = "BUG", text = "a bad ticket does not start the 60 s" })
    check("the 60 s starts at an accepted ticket", got(t, "t_ack").ok == true)
    tk(t, "t_new", { kind = "SPAM", text = "x" })
    advance(61000)
    tk(t, "t_new", { kind = "SPAM", text = "x" })
    check("a kind outside the six", errOf(t) == "text")
    tk(t, "t_new", { kind = { 1 }, text = { 1 } })
    check("tables for kind and text", errOf(t) == "text")
    check("a control character goes, a line break stays", W.server.ZeD.Tk.clean("a\1b\nc\r\t") == "ab\nc")

    world()
    local m = player("many")
    for i = 1, 5 do check("five open go in", newTicket(m, "BUG", "t" .. i) ~= nil) end
    newTicket(m, "BUG", "six")
    check("a sixth open: many", errOf(m) == "many")
    tk(m, "t_new", { kind = "BUG", text = "six" })
    rec(1).status = "Closed"
    newTicket(m, "BUG", "six")
    check("closing one frees a place", got(m, "t_ack").ok == true)

    -- hostile arguments: one bad line each, nothing sent back that was not asked for
    world()
    local h = player("hostile")
    local admin = player("zedqa", "admin")
    local good = newTicket(h, "BUG", "mine")
    for _, bad in ipairs({ "14", { 1 }, -1, 14.5, 0, 1e300 }) do
        local before = #W.logs
        advance(1000)
        tk(h, "t_one", { id = bad })
        check("t_one with a bad id answers gone", errOf(h) == "gone" and #h.box == 1, tostring(bad))
        check("one bad line", #W.logs == before + 1 or logCount("bad arguments") >= 6, tostring(bad))
    end
    advance(6000)
    tk(h, "t_one", { id = good, rid = string.rep("x", 5000) })
    check("a long rid is not echoed", got(h, "t_one") ~= nil and #h.box == 1)
    tk(h, "t_one", { id = 999, rid = string.rep("x", 5000) })
    check("no rid in the reply", got(h, "t_ack").rid == nil)
    tk(h, "t_one", { id = 999, rid = 7 })
    check("a good rid is echoed", got(h, "t_ack").rid == 7)
    tk(h, "t_one")
    check("no args at all", errOf(h) == "gone")
    say(h, "ZeDT", "nothing_here", { a = 1 })
    check("an unknown command: silence", #h.box == 0)
    say(h, "OtherMod", "t_new", { kind = "BUG", text = "x" })
    check("another module: not ours", #h.box == 0)
    advance(6000)
    tk(admin, "t_queue", { find = "%[" })
    check("a pattern in find is plain text", got(admin, "t_queue") ~= nil and got(admin, "t_queue").n == 0)
    advance(1100)
    tk(admin, "t_queue", { find = string.rep("a", 65) })
    check("find over 64", errOf(admin) == "text")
    advance(1100)
    tk(admin, "t_queue", { status = "Nope" })
    check("a status outside the set", errOf(admin) == "text")
    advance(1100)
    tk(admin, "t_queue", { page = "2" })
    check("a page that is a string", errOf(admin) == "text")

    -- a handler that fails costs one command
    world()
    local f = player("fail")
    W.server.ZeD.Srv.handlers["ZeDT.t_mine"].fn = function() error("boom") end
    tk(f, "t_mine", { rid = 3 })
    check("a failed handler answers fail", errOf(f) == "fail" and got(f, "t_ack").rid == 3)
    check("and writes a line", logHas("handler failed: t_mine"))

    -- the general limit: 10 commands in any 5 s, then silence, one line a minute
    world()
    local g = player("flood")
    local answers = 0
    for i = 1, 30 do
        tk(g, "t_one", { id = 1 })
        answers = answers + #g.box
    end
    check("ten answered, twenty dropped with no reply", answers == 10, answers)
    check("one line for the flood", logCount("over the general limit") == 1)
    advance(5000)
    tk(g, "t_one", { id = 1 })
    check("after 5 s it answers again", #g.box == 1)
    advance(60000)
    for i = 1, 30 do tk(g, "t_one", { id = 1 }) end
    check("another line a minute later", logCount("over the general limit") == 2)

    -- nearby: 30 tiles on any floor, the player left out, staff counted, at most 20
    world()
    local r0 = player("rosa", "user", 1000, 1000, 0)
    player("near", "user", 1030, 1000, 3)
    player("corner", "user", 1021, 1021, 0)
    player("far", "user", 1031, 1000, 0)
    player("hiddenadmin", "admin", 1000, 1001, 0)
    local nid = newTicket(r0, "GRIEF", "x", true)
    local names = {}
    for i = 1, rec(nid).near.n do names[rec(nid).near[i]] = true end
    check("30 tiles exactly is in, any floor", names.near)
    check("inside the circle", names.corner)
    check("31 tiles is out", not names.far)
    check("not the player", not names.rosa)
    check("invisible staff are counted", names.hiddenadmin)
    world()
    local r1 = player("rosa", "user", 1000, 1000, 0)
    for i = 1, 30 do player("p" .. i, "user", 1001, 1000, 0) end
    local nid2 = newTicket(r1, "GRIEF", "x", true)
    check("at most 20 names", rec(nid2).near.n == 20)
    local nid3 = newTicket(player("away", "user", 1, 1, 0), "BUG", "x", false)
    check("no place unless asked", rec(nid3).place == nil and rec(nid3).near == nil)

    -- t_mine, t_one, t_reply, t_read
    world()
    local o = player("owner")
    local x = player("other")
    local tid = newTicket(o, "BUG", "first")
    tk(x, "t_one", { id = tid })
    local notMine = errOf(x)
    tk(x, "t_one", { id = 999 })
    check("someone else's ticket answers as one that does not exist", notMine == "gone" and errOf(x) == "gone")
    tk(x, "t_reply", { id = tid, text = "x" })
    check("no reply to someone else's", errOf(x) == "gone")
    tk(o, "t_reply", { id = tid, text = "more" })
    check("t_reply goes on the thread", got(o, "t_one") and rec(tid).thread.n == 2)
    tk(o, "t_reply", { id = tid, text = "and more" })
    check("t_reply 1 per 10 s", errOf(o) == "wait")
    advance(10000)
    rec(tid).status = "Answered"
    tk(o, "t_reply", { id = tid, text = "after the answer" })
    check("E12 as drawn: no reply at Answered", errOf(o) == "state")
    rec(tid).status = "Closed"
    advance(10000)
    tk(o, "t_reply", { id = tid, text = "x" })
    check("no reply at Closed", errOf(o) == "state")
    rec(tid).status = "Seen"
    rec(tid).thread.n = 40
    for i = 3, 40 do rec(tid).thread[i] = { who = "owner", t = 1, text = "x" } end
    tk(o, "t_reply", { id = tid, text = "one more" })
    check("the thread holds 40", errOf(o) == "full")
    rec(tid).unread = true
    tk(o, "t_read", { id = tid })
    check("t_read clears unread", rec(tid).unread == nil)
    tk(x, "t_read", { id = tid })

    world()
    local nn = player("lots")
    for i = 1, 60 do
        local r = newTicket(nn, "BUG", "t" .. i)
        rec(r).status = "Closed"
    end
    advance(6000)
    tk(nn, "t_mine", {})
    local mineList = got(nn, "t_mine")
    check("t_mine: the newest 50", mineList.n == 50 and mineList.rows[1].id == 60 and mineList.rows[50].id == 11)

    -- E12 switched on: the field stays open and a reply puts the ticket back in the queue
    world()
    local e = player("e12")
    local admin2 = player("zedqa", "admin")
    local eid = newTicket(e, "QUESTION", "q")
    tk(admin2, "t_answer", { id = eid, text = "a" })
    W.server.ZeD.Tk.REPLY_AT_ANSWERED = true
    check("E12 on: can at Answered", W.server.ZeD.Tk.canReply("Answered"))
    tk(e, "t_one", { id = eid })
    check("E12 on: the view says so", got(e, "t_one").can == true)
    tk(e, "t_reply", { id = eid, text = "follow up" })
    check("E12 on: the reply goes back to Progress", rec(eid).status == "Progress" and rec(eid).thread.n == 3)
    tk(admin2, "t_answer", { id = eid, text = "b" })
    advance(0)
    tk(admin2, "t_answer", { id = eid, text = "c" })
    check("E12 on: staff answer twice", got(admin2, "t_ack").ok == true and rec(eid).thread.n == 5)
    tk(admin2, "t_close", { id = eid })
    check("E12 on: Close at Answered", rec(eid).status == "Closed")
    W.server.ZeD.Tk.REPLY_AT_ANSWERED = false
end

-- ---------------------------------------------------------------------------
-- STEP 4: FILING IN THE GAME'S TABLE
-- ---------------------------------------------------------------------------
section("step 4: the game's ticket")
do
    world()
    local p = player("kade")
    local c = clientJoin(p)
    local T = c.env.ZeD.Tickets
    local done
    local res = T.ask("GRIEF", true, "  the truck ", function(a) done = a end)
    check("sent", res == "sent")
    advance(300)
    check("done with the ack", done and done.ok == true)
    check("the game holds the tagged text", W.game[1] and W.game[1].msg == "[GRIEF #1] the truck" and W.game[1].author == "kade")
    check("t_filed came back", rec(1).gameFiled == true)
    check("filed once", W.calls.addTicket == 1)
    advance(100000)
    check("no retry", W.calls.addTicket == 1)
    check("my row arrived", T.mine[1] and T.mine[1].id == 1 and T.mine[1].st == "Sent")

    -- Send waits while the link is unknown, with the text kept by the caller
    world()
    local w = player("wait")
    W.server.Events.OnClientCommand.list = {}
    local cw = clientJoin(w)
    check("while unknown Send says wait", cw.env.ZeD.Tickets.ask("BUG", false, "x") == "wait")
    check("no game call yet", W.calls.addTicket == 0)
    advance(41000)
    check("no server part: filed with the plain tag", cw.env.ZeD.Tickets.ask("BUG", false, "the bug") == "sent")
    advance(300)
    check("the fallback's tag", W.game[1] and W.game[1].msg == "[BUG] the bug", W.game[1] and W.game[1].msg)
    check("the fallback's list", cw.env.ZeD.Tickets.mine[1] and cw.env.ZeD.Tickets.mine[1].st == "Sent" and cw.env.ZeD.Tickets.mine[1].kind == "BUG")

    -- quit before filing, rejoin: filed once; rejoin again: not twice
    world()
    local q = player("quitter")
    local id = newTicket(q, "STUCK", "under the floor")
    check("no game row yet", #W.game == 0 and rec(id).gameFiled == nil)
    local c2 = clientJoin(q)
    advance(300)
    check("rejoin: filed once", #W.game == 1 and W.game[1].msg == "[STUCK #" .. id .. "] under the floor")
    check("rejoin: confirmed", rec(id).gameFiled == true)
    c2.up = false
    advance(6000)
    clientJoin(q)
    advance(300)
    check("rejoin again: not filed twice", #W.game == 1)

    -- a filing whose reply was lost: the row is there and the record does not know
    world()
    local l = player("lost")
    local id2 = newTicket(l, "BUG", "x")
    gameAdd("lost", "[BUG #" .. id2 .. "] x")
    clientJoin(l)
    advance(300)
    check("a lost reply: not filed a second time", #W.game == 1)
    check("a lost reply: confirmed", rec(id2).gameFiled == true)

    -- a closed ticket is not filed: only while open
    world()
    local k = player("cl")
    local id3 = newTicket(k, "BUG", "x")
    rec(id3).status = "Closed"
    clientJoin(k)
    advance(300)
    check("a closed record is not filed", #W.game == 0)

    -- E13 switched: the stub
    world()
    W.server.ZeD.Tk.FILE_FULL_TEXT = false
    local s = player("stub")
    local sc = clientJoin(s)
    sc.env.ZeD.Tk.FILE_FULL_TEXT = false
    sc.env.ZeD.Tickets.ask("GRIEF", false, "private words")
    advance(300)
    check("E13 off: only the stub in the game's ticket", W.game[1].msg == "[GRIEF #1] see the Tickets queue", W.game[1].msg)
    check("E13 off: confirmed", rec(1).gameFiled == true)
    check("E13 off: the record keeps the words", rec(1).thread[1].text == "private words")
    local st = player("zedqa", "admin")
    local sa = clientJoin(st)
    sa.env.ZeD.Tickets.openQueue({})
    advance(2500)
    check("E13 off: the stub links", rec(1).gameId == W.game[1].id)
end

-- ---------------------------------------------------------------------------
-- STEP 5: STAFF
-- ---------------------------------------------------------------------------
section("step 5: staff")
do
    -- every transition in B4 and every refused one
    local ALL = { "Open", "Seen", "Progress", "Answered", "Closed", "Spam" }
    local RULES = {
        t_take =   { Open = "Progress", Seen = "Progress", Progress = "Progress" },
        t_answer = { Open = "Answered", Seen = "Answered", Progress = "Answered" },
        t_close =  { Open = "Closed", Seen = "Closed", Progress = "Closed" },
        t_reopen = { Answered = "Progress", Closed = "Progress" },
        t_spam =   { Open = "Spam", Seen = "Spam", Progress = "Spam", Answered = "Spam", Closed = "Spam" },
        t_unspam = { Spam = "Open" },
    }
    for cmd, map in pairs(RULES) do
        for _, st in ipairs(ALL) do
            world()
            local p = player("p")
            local admin = player("zedqa", "admin")
            local id = newTicket(p, "BUG", "x")
            rec(id).status = st
            tk(admin, cmd, { id = id, text = "words", rid = 5 })
            if map[st] then
                check(cmd .. " from " .. st, rec(id).status == map[st] and got(admin, "t_ack").ok == true, rec(id).status)
            else
                check(cmd .. " refused from " .. st, rec(id).status == st and errOf(admin) == "state", rec(id).status)
            end
        end
    end
    world()
    local p = player("p")
    local admin = player("zedqa", "admin")
    local id = newTicket(p, "BUG", "x")
    tk(admin, "t_card", { id = id })
    check("opening the card: Open to Seen", rec(id).status == "Seen" and got(admin, "t_card").status == "Seen")
    tk(p, "t_one", { id = id })
    check("the player reads Seen", got(p, "t_one").st == "Seen")
    rec(id).status = "Progress"
    tk(admin, "t_card", { id = id })
    check("a later open changes nothing", rec(id).status == "Progress")
    tk(admin, "t_addnote", { id = id, text = "a note" })
    check("a note, status unchanged", rec(id).notes.n == 1 and rec(id).status == "Progress")
    tk(admin, "t_addnote", { id = id, text = "   " })
    check("an empty note", errOf(admin) == "text")
    tk(admin, "t_take", { id = id })
    check("Take sets the assignee", rec(id).assignee == "zedqa")
    tk(admin, "t_answer", { id = id, text = "   " })
    check("an empty answer", errOf(admin) == "text" and rec(id).status == "Progress")
    tk(admin, "t_spam", { id = id })
    check("Spam sets spamBy and clears unread", rec(id).spamBy == "zedqa" and rec(id).unread == nil)
    tk(admin, "t_unspam", { id = id })
    check("Not spam clears spamBy", rec(id).spamBy == nil and rec(id).status == "Open")
    for i = 2, 20 do rec(id).notes[i] = { who = "x", t = 1, text = "n" } end
    rec(id).notes.n = 20
    tk(admin, "t_addnote", { id = id, text = "one more" })
    check("notes hold 20", errOf(admin) == "full")

    -- a real answer: thread, status, assignee, the note and t_one to the author
    world()
    local a1 = player("author")
    local mod = player("jules", "moderator")
    local aid = newTicket(a1, "QUESTION", "why")
    tk(mod, "t_answer", { id = aid, text = "because", rid = 2 })
    check("Answer goes to the thread as staff", rec(aid).thread[2].staff == true and rec(aid).thread[2].who == "jules")
    check("Answer keeps or sets the assignee", rec(aid).assignee == "jules")
    check("unread", rec(aid).unread == true)
    check("the author gets t_note", got(a1, "t_note") and got(a1, "t_note").who == "jules")
    check("the author gets t_one", got(a1, "t_one") and got(a1, "t_one").st == "Answered")
    check("not linked yet: first is false", got(mod, "t_ack").first == false)

    -- plain players, moderators, admins: as user, each staff command answers perm
    world()
    local u = player("user1")
    local adm = player("zedqa", "admin")
    local tid = newTicket(u, "BUG", "mine")
    local STAFF = { "t_queue", "t_card", "t_take", "t_answer", "t_addnote", "t_close", "t_reopen", "t_spam", "t_unspam", "t_delete", "t_sync", "t_gamediff" }
    for _, c in ipairs(STAFF) do
        advance(1100)
        tk(u, c, { id = tid, text = "x", rid = 4 })
        check(c .. " as a plain player answers perm", errOf(u) == "perm" and #u.box == 1)
    end
    check("the ticket is untouched", rec(tid).status == "Open" and rec(tid).thread.n == 1)
    check("one log line a minute", logCount("has no right") == 1, logCount("has no right"))
    advance(60000)
    for i = 1, 5 do advance(1100); tk(u, "t_queue", {}) end
    check("a second line a minute later", logCount("has no right") == 2, logCount("has no right"))

    local md1 = player("modd", "moderator")
    tk(md1, "t_spam", { id = tid })
    check("a moderator marks spam", rec(tid).status == "Spam")
    tk(md1, "t_delete", { id = tid })
    check("a moderator cannot delete", errOf(md1) == "perm" and rec(tid) ~= nil)
    tk(adm, "t_delete", { id = tid, rid = 8 })
    check("an admin deletes", rec(tid) == nil and got(adm, "t_ack").ok == true)
    check("t_gone to staff and the author", got(md1, "t_gone") and got(u, "t_gone") and got(u, "t_gone").id == tid)
    check("a custom role with RolesWrite deletes", ROLES.admin.caps.RolesWrite == true)
    tk(adm, "t_delete", { id = tid })
    check("gone twice answers gone", errOf(adm) == "gone")
    local chars = md().chars
    check("chars back to zero after Delete", chars == 0, chars)

    -- what a plain player receives: the whole dump
    world()
    local plain = player("plain")
    local boss = player("zedqa", "admin", 6280, 5350, 0)
    local all = {}
    local function keep() for _, m in ipairs(plain.box) do all[#all + 1] = m end end
    local pid = newTicket(plain, "GRIEF", "help", true); keep()
    tk(boss, "t_card", { id = pid }); keep()
    tk(boss, "t_take", { id = pid }); keep()
    tk(boss, "t_addnote", { id = pid, text = "secret note words" }); keep()
    tk(boss, "t_answer", { id = pid, text = "on my way" })
    for _, m in ipairs(plain.box) do all[#all + 1] = m end
    tk(plain, "t_one", { id = pid }); keep()
    advance(6000)
    tk(plain, "t_mine", {}); keep()
    say(plain, "ZeD", "hello", {}); keep()
    tk(boss, "t_spam", { id = pid })
    keep()
    tk(plain, "t_one", { id = pid }); keep()
    local one = got(plain, "t_one")
    advance(6000)
    tk(plain, "t_mine", {}); keep()
    local minerow = got(plain, "t_mine").rows[1]
    say(plain, "ZeD", "hello", {}); keep()
    local keys = keysIn(all)
    for _, bad in ipairs({ "notes", "near", "assignee", "spamBy", "gameId", "gameGone", "gameAns", "source", "open", "spam", "status" }) do
        check("a plain player never receives " .. bad, not keys[bad])
    end
    check("Spam never reaches a player", not valuesHave(all, "Spam"))
    check("a note's words never reach a player", not valuesHave(all, "secret note words"))
    check("a spammed ticket reads Closed", one.st == "Closed" and one.can == false)
    check("my row reads Closed", minerow.st == "Closed")
    local staffOnes = got(boss, "t_row")
    check("staff read Spam", staffOnes and staffOnes.st == "Spam" and staffOnes.spam == 1)
    tk(boss, "t_card", { id = pid })
    check("the staff view has everything", got(boss, "t_card").notes.n == 1 and got(boss, "t_card").near.n >= 0 and got(boss, "t_card").spamBy == "zedqa")

    -- t_one of a staff member's ticket
    world()
    local s = player("hermit", "admin")
    local pl = player("pl")
    local sid = newTicket(s, "BUG", "mine")
    tk(pl, "t_one", { id = sid })
    check("t_one of a staff member's ticket answers gone", errOf(pl) == "gone")

    -- demoted while a card is open
    world()
    local d = player("demoted", "moderator")
    local au = player("au")
    local did = newTicket(au, "BUG", "x")
    tk(d, "t_card", { id = did })
    local admn = player("zedqa", "admin")
    local closed = player("nocard", "moderator")
    local left = player("left", "moderator")
    tk(left, "t_card", { id = did })
    tk(left, "t_queue", {})
    d.box, closed.box, left.box = {}, {}, {}
    tk(admn, "t_addnote", { id = did, text = "first" })
    check("a card open gets the push", got(d, "t_card") ~= nil)
    check("staff without it open do not", got(closed, "t_card") == nil)
    check("t_queue clears the open card", got(left, "t_card") == nil)
    setRole(d, "user")
    d.box = {}
    W.net = {}
    admn.box = {}
    local a2 = wire({ id = did, text = "after the demotion" })
    W.server.Events.OnClientCommand.fire("ZeDT", "t_addnote", admn, a2)
    drain()
    check("demoted: no more pushes", got(d, "t_card") == nil and got(d, "t_row") == nil)

    -- the queue: filters, order, pages at 26
    world()
    local staff = player("zedqa", "admin")
    local ps = {}
    for i = 1, 26 do
        ps[i] = player("u" .. i)
        newTicket(ps[i], (i % 2 == 0) and "BUG" or "GRIEF", "ticket number " .. i)
    end
    local function queue(q)
        advance(1100)
        tk(staff, "t_queue", q)
        return got(staff, "t_queue")
    end
    local q1 = queue({})
    check("26 open: two pages of 25", q1.n == 26 and q1.pages == 2 and #q1.rows == 25 and q1.page == 1)
    check("newest first", q1.rows[1].id == 26)
    check("the counts", q1.open == 26 and q1.spam == 0)
    check("page 1 carries the authors", #q1.authors == 26)
    local q2 = queue({ page = 2 })
    check("page 2", #q2.rows == 1 and q2.rows[1].id == 1 and q2.authors == nil)
    local q3 = queue({ newest = false })
    check("oldest first", q3.rows[1].id == 1)
    local q4 = queue({ kind = "BUG" })
    check("by kind", q4.n == 13)
    local q5 = queue({ who = "u3" })
    check("by player", q5.n == 1 and q5.rows[1].author == "u3")
    local q6 = queue({ find = "NUMBER 7" })
    check("find ignores case", q6.n == 1)
    local q7 = queue({ find = "u4" })
    check("find takes a player", q7.n == 1)
    tk(staff, "t_take", { id = 1 })
    local q8 = queue({ mine = "ME" })
    check("taken by me", q8.n == 1)
    local q9 = queue({ mine = "NOBODY" })
    check("not taken", q9.n == 25)
    tk(staff, "t_spam", { id = 2 })
    tk(staff, "t_close", { id = 3 })
    tk(staff, "t_answer", { id = 4, text = "a" })
    check("open leaves out the rest", queue({}).n == 23)
    check("All leaves out Spam", queue({ status = "All" }).n == 25)
    check("Spam is its own pile", queue({ status = "Spam" }).n == 1)
    check("Answered", queue({ status = "Answered" }).n == 1)
    check("Closed", queue({ status = "Closed" }).n == 1)
    check("past the last page lands on it", queue({ page = 99 }).page == 1 and queue({ status = "All", page = 99 }).page == 1)
    check("the save warning", queue({}).noSave == true)
    W.saveMinutes = 15
    check("no warning with a save timer", queue({}).noSave == false)
    tk(staff, "t_queue", {})
    tk(staff, "t_queue", {})
    check("t_queue 1 per 1 s", errOf(staff) == "wait")
end

-- ---------------------------------------------------------------------------
-- STEP 6: THE GAME'S SIDE
-- ---------------------------------------------------------------------------
section("step 6: sync, link, adopt, game calls")
do
    local function boot(role)
        world()
        local staff = player("zedqa", role or "admin")
        local c = clientJoin(staff)
        return staff, c, c.env.ZeD.Tickets
    end
    local function openQ(T)
        T.closeQueue()
        T.openQueue({})
        advance(4000)
    end

    -- a ticket filed in the game's window appears as No kind
    do
        local staff, c, T = boot()
        gameAdd("mike_d", "help my car is stuck")
        openQ(T)
        local r = rec(1)
        check("adopted: source game, no kind", r and r.source == "game" and r.kind == "NONE" and r.author == "mike_d")
        check("adopted: no day, time or place", r.day == nil and r.filed == nil and r.place == nil)
        check("adopted: Open", r.status == "Open" and r.gameId == 1)
        check("adopted: the line says the game", r.thread[1].game == true and r.thread[1].staff == nil)
        check("gameMax moved", md().gameMax == 1)
        openQ(T)
        local n = 0
        for _ in pairs(md().tickets) do n = n + 1 end
        check("open twice: no second record", n == 1)
    end

    -- a ZeD ticket links by its tag
    do
        local staff, c, T = boot()
        local pl = player("kade")
        local pc = clientJoin(pl)
        pc.env.ZeD.Tickets.ask("GRIEF", false, "the truck")
        advance(300)
        openQ(T)
        check("linked", rec(1).gameId == W.game[1].id and rec(1).source == "zed")
        check("no record adopted", rec(2) == nil)
        check("the modal for staff became one note", #c.msgs == 1 and #c.modals == 0)
    end

    -- forged: same tag, wrong author, wrong words; a viewed-less answer
    do
        local staff, c, T = boot()
        local pl = player("zed1")
        newTicket(pl, "GRIEF", "real words")
        gameAdd("griefer", "[GRIEF #1] real words")
        openQ(T)
        check("a forged tag does not link: wrong author", rec(1).gameId == nil)
        check("adopted apart", rec(2) and rec(2).source == "game" and rec(2).author == "griefer" and rec(2).kind == "GRIEF")
        gameAdd("zed1", "[GRIEF #1] other words")
        openQ(T)
        check("a forged tag does not link: wrong words", rec(1).gameId == nil)
    end

    -- the row's own record: the real file text links even after a forged row was adopted
    do
        local staff, c, T = boot()
        local g = gameAdd("griefer", "ticket")
        gameAdd("griefer", "x", g.id).msg = "[BUG] I answer myself"
        openQ(T)
        check("an answer on an unviewed ticket: notes", rec(1).notes.n == 1 and rec(1).notes[1].game == true)
        check("it stays Open", rec(1).status == "Open" and rec(1).thread.n == 1)
        local g2 = gameAdd("rosa", "viewed and answered")
        g2.viewed = true
        gameAdd("hermit", "the answer", g2.id)
        local g3 = gameAdd("rosa", "viewed only")
        g3.viewed = true
        openQ(T)
        local a, b = rec(2), rec(3)
        check("viewed and answered: Answered", a.status == "Answered")
        check("the answer on a viewed ticket: thread, game, not staff", a.thread.n == 2 and a.thread[2].game == true and a.thread[2].staff == nil)
        check("viewed only: Seen", b.status == "Seen")
    end

    -- caps: 3 per claimed author, 100 open, skipped counts, no rise on the second open
    do
        local staff, c, T = boot()
        for i = 1, 300 do gameAdd("flood", "free stuff " .. i) end
        openQ(T)
        advance(20000)
        check("3 open per claimed author", rec(3) and rec(4) == nil)
        check("skipped counts", md().skipped == 297, md().skipped)
        check("all rows dealt with", md().gameMax == 300, md().gameMax)
        local sk = md().skipped
        openQ(T)
        advance(4000)
        T.closeQueue()
        openQ(T)
        check("open and close twice: no rise", md().skipped == sk)
        for i = 1, 400 do gameAdd("flood" .. i, "free stuff " .. i) end
        openQ(T)
        advance(25000)
        local n, ga = 0, 0
        for _, r in pairs(md().tickets) do n = n + 1; if r.source == "game" and W.server.ZeD.Tk.isOpen(r.status) then ga = ga + 1 end end
        check("100 adopted open in all", ga == 100, ga)
        check("forged tickets do not stop a player filing", newTicket(player("flood1"), "BUG", "real") ~= nil)
    end

    -- evict a record: not adopted again
    do
        local staff, c, T = boot()
        gameAdd("a", "one")
        openQ(T)
        rec(1).status = "Closed"
        rec(1).updated = 1
        W.server.ZeD.Srv.T.md.tickets[1] = nil
        W.server.ZeD.Srv.T.byGame[1] = nil
        openQ(T)
        check("an evicted record does not come back", next(md().tickets) == nil)
    end

    -- Answer: one game answer; a second does not add a game row. Delete removes it there
    do
        local staff, c, T = boot()
        local pl = player("kade")
        local pc = clientJoin(pl)
        pc.env.ZeD.Tickets.ask("BUG", false, "the bug")
        advance(300)
        openQ(T)
        T.openCard(1)
        advance(300)
        check("opening the card: viewed in the game", W.game[1].viewed == true and rec(1).status == "Seen")
        local g = W.game[1].id
        local done
        T.answer(1, "first answer", function(a) done = a end)
        advance(300)
        check("the first answer: first true", done and done.first == true and done.gameId == g)
        local answers = 0
        for _, r in ipairs(W.game) do if r.answered == g then answers = answers + 1 end end
        check("one game answer row", answers == 1)
        check("gameAns", rec(1).gameAns == true)
        T.reopen(1)
        advance(300)
        T.answer(1, "second answer")
        advance(300)
        answers = 0
        for _, r in ipairs(W.game) do if r.answered == g then answers = answers + 1 end end
        check("a second answer adds no game row", answers == 1)
        check("both in ZeD's thread", rec(1).thread.n == 3)
        T.delete(1)
        advance(300)
        check("Delete: gone from both", rec(1) == nil and gameFind(g) == nil)
    end

    -- removed on the game's window: the record stays, nothing files it again, a moderator's Remove is no Delete
    do
        local staff, c, T = boot("moderator")
        local pl = player("kade")
        local pc = clientJoin(pl)
        pc.env.ZeD.Tickets.ask("BUG", false, "one")
        advance(300)
        W.server.ZeD.Srv.mem = {}
        pc.env.ZeD.Tickets.ask("BUG", false, "two")   -- a higher id, so the removed row sits below the list's top
        advance(300)
        openQ(T)
        local g = rec(1).gameId
        check("both linked", g and rec(2).gameId)
        gameRemove(g)
        T.openQueue({})
        advance(5000)
        check("one list is not enough", rec(1).gameId == g and rec(1).gameGone == nil)
        advance(9000)
        check("two lists 10 s apart: gameGone", rec(1).gameGone == true and rec(1).gameId == nil, rec(1).gameId)
        check("the record stays, with its status", rec(1).status == "Open" and rec(1).gameFiled == true)
        check("a moderator's Remove does not delete", rec(1) ~= nil)
        T.answer(1, "later")
        advance(300)
        check("a later answer stays in ZeD", rec(1).thread.n == 2 and #W.game == 1)
        pc.up = false
        advance(6000)
        local c3 = clientJoin(pl)
        advance(300)
        check("the author's next login does not file it", #W.game == 1)
    end

    -- the newest ticket removed: top below gameMax is not a replaced database
    do
        local staff, c, T = boot()
        gameAdd("a", "one")
        gameAdd("b", "two")
        gameAdd("c", "three")
        openQ(T)
        check("three adopted", rec(3) ~= nil and md().gameMax == 3)
        gameRemove(3)
        T.closeQueue()
        T.openQueue({})
        advance(15000)
        check("no reset: links kept", rec(1).gameId == 1 and md().gameMax == 3, md().gameMax)
        local n = 0
        for _ in pairs(md().tickets) do n = n + 1 end
        check("no duplicates", n == 3, n)
        check("no reset line", not logHas("was replaced"))
    end

    -- own filing as staff: nothing marked gone
    do
        local staff, c, T = boot()
        local pl = player("kade")
        newTicket(pl, "BUG", "x")
        gameAdd("kade", "[BUG #1] x")
        gameAdd("rosa", "another")
        openQ(T)
        T.ask("QUESTION", false, "from staff")
        advance(15000)
        check("own filing: nothing gone", rec(1).gameGone == nil and rec(1).gameId ~= nil)
    end

    -- a game-window answer on a linked ticket
    do
        local staff, c, T = boot()
        local pl = player("kade")
        newTicket(pl, "BUG", "x")
        local row = gameAdd("kade", "[BUG #1] x")
        openQ(T)
        gameAdd("griefer", "a forged answer", row.id)
        T.closeQueue()
        openQ(T)
        check("unviewed: to notes", rec(1).notes.n == 1 and rec(1).gameAns == true and rec(1).thread.n == 1)
        check("no status change", rec(1).status == "Open")
        check("no belt note", rec(1).unread == nil)
        local row2 = gameAdd("mags", "second")
        openQ(T)
        row2.viewed = true
        gameAdd("hermit", "a real answer", row2.id)
        T.closeQueue()
        openQ(T)
        check("viewed: to the thread, game", rec(2).thread.n == 2 and rec(2).thread[2].game == true)
    end

    -- a replaced database: reset runs once, rows match afresh, no removeTicket on the wrong row
    do
        local staff, c, T = boot()
        local pl = player("kade")
        local id1 = newTicket(pl, "BUG", "x")
        gameAdd("kade", "[BUG #1] x")
        gameAdd("rosa", "two")
        gameAdd("rosa", "three")
        openQ(T)
        check("before: linked", rec(id1).gameId == 1 and md().gameMax == 3)
        W.game, W.gameNext = {}, 0
        gameAdd("other", "a different ticket")
        T.closeQueue()
        T.openQueue({})
        advance(16000)
        check("reset ran once", logCount("was replaced") == 1, logCount("was replaced"))
        check("gameFiled stays, the link goes", rec(id1).gameId == nil and rec(id1).gameFiled == true)
        check("the new row adopted", md().gameMax == 1)
        T.openCard(id1)
        advance(300)
        local before = W.calls.removeTicket
        T.delete(id1)
        advance(300)
        check("no removeTicket with no link", W.calls.removeTicket == before and gameFind(1) ~= nil)
    end

    -- before any game call: the row is tested against the record
    do
        local staff, c, T = boot()
        local pl = player("kade")
        newTicket(pl, "BUG", "x")
        gameAdd("kade", "[BUG #1] x")
        openQ(T)
        T.openCard(1)
        advance(300)
        c.env.ZeD.Tickets.list.byId[1].m = "something else"
        local before = W.calls.removeTicket
        T.delete(1)
        advance(300)
        check("a row that differs gets no call", W.calls.removeTicket == before and gameFind(1) ~= nil)
    end

    -- batches: 45 new rows, 20 at a time, a second apart
    do
        local staff, c, T = boot()
        for i = 1, 45 do gameAdd("a" .. i, "row " .. i) end
        local sent, sizes = 0, {}
        local real = c.env.sendClientCommand
        c.env.sendClientCommand = function(pl, module, command, args)
            if command == "t_sync" then sent = sent + 1; sizes[sent] = #args.rows end
            return real(pl, module, command, args)
        end
        T.openQueue({})
        advance(5000)
        check("three batches", sent == 3 and sizes[1] == 20 and sizes[2] == 20 and sizes[3] == 5, sent)
        check("every row seen", md().gameMax == 45)
    end

    -- a closed queue stops the batches
    do
        local staff, c, T = boot()
        for i = 1, 45 do gameAdd("a" .. i, "row " .. i) end
        T.openQueue({})
        advance(300)
        T.closeQueue()
        advance(5000)
        check("the batches stop", md().gameMax == 20, md().gameMax)
        T.openQueue({})
        advance(4000)
        check("the next open starts from gameMax", md().gameMax == 45, md().gameMax)
    end

    -- a game row of 32 kB
    do
        local staff, c, T = boot()
        gameAdd("big", string.rep("w", 32000))
        openQ(T)
        check("a long game row is cut to 1000", rec(1) and #rec(1).thread[1].text == 1000)
        check("no string overran", not W.overlong)
    end
end

-- ---------------------------------------------------------------------------
-- CAPS
-- ---------------------------------------------------------------------------
section("the caps")
do
    -- 300 open in all
    world()
    for i = 1, 300 do
        local id = newTicket(player("u" .. i), "BUG", "x")
        check("the 300 go in", id ~= nil)
    end
    local last = player("last")
    tk(last, "t_new", { kind = "BUG", text = "x" })
    check("301 open: full", errOf(last) == "full")
    check("a line in the log", logHas("tickets full"))

    -- history: 500, oldest updated goes, open tickets never
    world()
    local staff = player("zedqa", "admin")
    local M = md()
    for i = 1, 500 do
        M.tickets[i] = { id = i, source = "zed", kind = "BUG", author = "a", status = "Closed", updated = i,
            thread = { n = 1, { who = "a", t = 1, text = "x" } }, notes = { n = 0 } }
    end
    M.nextId, M.chars = 501, 500
    local p = player("p")
    local id = newTicket(p, "BUG", "open one")
    tk(staff, "t_close", { id = id })
    check("history 500: the oldest went", rec(1) == nil and rec(2) ~= nil and rec(id) ~= nil)
    local open2 = newTicket(player("q"), "BUG", "stays")
    rec(open2).updated = 0
    M.chars = 4000000 - 800
    local big = player("big")
    local id3 = newTicket(big, "BUG", string.rep("z", 1000))
    check("past the characters, history goes early", id3 ~= nil and rec(2) == nil and rec(400) ~= nil and M.chars <= 4000000)
    check("open tickets are never evicted", rec(open2) ~= nil)

    -- text held stays true across adds, notes, delete
    world()
    local s2 = player("zedqa", "admin")
    local a = player("a")
    local n1 = newTicket(a, "BUG", "12345")
    tk(s2, "t_addnote", { id = n1, text = "123" })
    tk(s2, "t_answer", { id = n1, text = "12" })
    check("chars kept", md().chars == 10, md().chars)

    -- the characters cap holds with nothing left to evict
    world()
    md().chars = 4000000
    local f = player("f")
    tk(f, "t_new", { kind = "BUG", text = "x" })
    check("no room and no history: full", errOf(f) == "full" and md().chars == 4000000)

    -- the largest card fits the 200 kB rule
    world()
    local s3 = player("zedqa", "admin")
    local w = player("w")
    local nid = newTicket(w, "BUG", string.rep("x", 1000))
    local r = rec(nid)
    for i = 2, 40 do r.thread[i] = { who = "w", t = 1, text = string.rep("x", 1000) } end
    r.thread.n = 40
    for i = 1, 20 do r.notes[i] = { who = "w", t = 1, text = string.rep("x", 1000) } end
    r.notes.n = 20
    W.biggest = 0
    tk(s3, "t_card", { id = nid })
    check("the largest card is under 200 kB", W.biggest < 200000 and got(s3, "t_card") ~= nil, W.biggest)
    check("no string over 32767", not W.overlong)
end

-- ---------------------------------------------------------------------------
-- STEP 7: THE BELT
-- ---------------------------------------------------------------------------
section("step 7: the belt and the modal")
do
    -- online: note; offline: one note at the next hello; opening clears it
    world()
    local staff = player("zedqa", "admin")
    local pl = player("kade")
    local pc = clientJoin(pl)
    local id = newTicket(pl, "BUG", "x")
    tk(staff, "t_answer", { id = id, text = "a" })
    advance(100)
    check("answer while online: a note", #pc.notes == 1 and pc.notes[1].id == id and pc.notes[1].who == "zedqa")
    check("stays unread until read", rec(id).unread == true)
    pc.env.ZeD.Tickets.read(id)
    advance(100)
    check("Open clears it", rec(id).unread == nil)

    world()
    local s2 = player("zedqa", "admin")
    local pp = player("kade")
    local i2 = newTicket(pp, "BUG", "x")
    offline(pp)
    tk(s2, "t_answer", { id = i2, text = "a" })
    W.online[#W.online + 1] = pp
    local pc2 = clientJoin(pp)
    advance(300)
    check("answered offline: one note at the hello", #pc2.notes == 1 and pc2.notes[1].id == i2 and pc2.notes[1].who == nil)
    check("the note sits until Open", rec(i2).unread == true)
    local item = { id = i2 }
    pc2.env.ZeD.Tickets.openNote(item)
    advance(300)
    check("openNote: read, and the card's data asked for", item.read == true and rec(i2).unread == nil and pc2.env.ZeD.Tickets.one[i2] ~= nil)
    advance(6000)
    pc2.env.ZeD.ServerPart.hello()
    advance(300)
    check("no second note after Open", #pc2.notes == 1)

    -- at most 5 ids at the hello
    world()
    local s3 = player("zedqa", "admin")
    local lots = player("lots")
    for i = 1, 7 do
        local t = newTicket(lots, "BUG", "t" .. i)
        rec(t).status = "Closed"
        rec(t).unread = true
    end
    say(lots, "ZeD", "hello", {})
    check("hello lists at most 5", #got(lots, "hello").unread == 5 and got(lots, "hello").unread[1] == 7)
    -- Spam also clears unread
    tk(s3, "t_spam", { id = 7 })
    check("spam clears unread", rec(7).unread == nil)

    -- the game's modal: staff get a note at most once in 10 s; other messages still open
    world()
    local boss = player("zedqa", "admin")
    local bc = clientJoin(boss)
    local fire = bc.env.Events.OnAdminMessage.fire
    check("the game's listener is gone", #bc.env.Events.OnAdminMessage.list == 1)
    fire("user kade added a ticket <LINE> <LINE> words", -1, -1, -1)
    fire("user rosa added a ticket <LINE> <LINE> words", -1, -1, -1)
    check("one note in 10 s, no modal", #bc.msgs == 1 and #bc.modals == 0)
    advance(10000)
    fire("user rosa added a ticket <LINE> <LINE> words", -1, -1, -1)
    check("a second note after 10 s", #bc.msgs == 2)
    fire("A zombie horde is coming", 10, 10, 0)
    check("any other message opens the game's modal", #bc.modals == 1)
    fire("a user added a ticket", -1, -1, -1)
    check("the match is anchored", #bc.modals == 2)
    -- observer and gm receive it and have no queue
    local ob = player("gm1", "observer")
    local oc = clientJoin(ob)
    oc.env.Events.OnAdminMessage.fire("user kade added a ticket <LINE> <LINE> words", -1, -1, -1)
    check("a client without AnswerTickets keeps the modal", #oc.modals == 1 and #oc.msgs == 0)
    -- without the server part it passes too
    bc.env.ZeD.ServerPart.forceOff = true
    fire("user kade added a ticket <LINE> <LINE> words", -1, -1, -1)
    check("forceOff: the game's modal", #bc.modals == 3)
end

print("tickets_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
