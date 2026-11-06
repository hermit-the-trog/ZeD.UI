-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerCore.lua
-- ============================================================================
-- THE SERVER PART'S CORE (ZeDUI/MP_SERVER_PART_DESIGN.md, B6 and B10). Runs on a dedicated server and a host's server,
-- and nowhere else (the first line). ZeD.Srv: who may do what, the rate limits, the one OnClientCommand listener, the
-- hello, the pushes to staff and the ZeD log. Later phases register their modules here.
--
-- Every command takes its player from the event, never a name from its arguments, and the handler runs inside pcall:
-- a Lua logic error costs one command, not the server's event chain. ZeD.Srv is a global and the listener is added
-- only while ZeD.Srv.listening is nil: /reloadlua of this file would otherwise run every command twice.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"

ZeD = ZeD or {}
ZeD.Srv = ZeD.Srv or {}
local Srv = ZeD.Srv
local Tk = ZeD.Tk
local L = Tk.LIMITS

Srv.handlers = Srv.handlers or {}
Srv.mem = Srv.mem or {}          -- username -> the limits' memory; a restart clears it

-- Both are in the 42.22 enum. If a game update renames one the local is nil, and hasCapability(nil) would match no
-- overload, which corrupts the game's call pool even inside pcall. So a missing one leaves the part off (below).
local CAP_STAFF = Capability and Capability.AnswerTickets
local CAP_ADMIN = Capability and Capability.RolesWrite
Srv.CAP_STAFF, Srv.CAP_ADMIN = CAP_STAFF, CAP_ADMIN

function Srv.can(p, cap)
    local role = p and p:getRole()
    return role ~= nil and role:hasCapability(cap) == true
end

-- every line goes to Zomboid/Logs/<date>_ZeD.txt. Never a ticket's text or a note, never the table's name
function Srv.log(text) writeLog("ZeD", text) end

local function memOf(user)
    local m = Srv.mem[user]
    if not m then
        m = { ring = {}, at = 1, last = {}, over = 0 }
        Srv.mem[user] = m
    end
    return m
end

-- the general limit: the time of each of the last GENERAL_N commands, in a ring. A dropped command does not enter it.
local function general(user, now)
    local m = memOf(user)
    local oldest = m.ring[m.at]
    if oldest and now - oldest < L.GENERAL_MS then
        m.over = m.over + 1
        if not m.overLog or now - m.overLog >= L.MINUTE_MS then
            m.overLog = now
            Srv.log("rate limit: " .. tostring(user) .. " over the general limit, " .. tostring(m.over) .. " dropped so far")
        end
        return false
    end
    m.ring[m.at] = now
    if m.at >= L.GENERAL_N then m.at = 1 else m.at = m.at + 1 end
    return true
end

-- a command's own limit: the seconds left, or nil when it may run
function Srv.left(p, key, ms)
    local last = memOf(p:getUsername()).last[key]
    if not last then return nil end
    local gone = getTimestampMs() - last
    if gone >= ms then return nil end
    return math.ceil((ms - gone) / 1000)
end
function Srv.mark(p, key) memOf(p:getUsername()).last[key] = getTimestampMs() end

-- one line a minute per player for a refused power, or the denial itself fills the disk
function Srv.deny(p, what)
    local m = memOf(p:getUsername())
    local now = getTimestampMs()
    if m.denyLog and now - m.denyLog < L.MINUTE_MS then return end
    m.denyLog = now
    Srv.log("refused: " .. tostring(p:getUsername()) .. " has no right to " .. tostring(what))
end

-- a line for arguments no client of ours sends, a few a minute per player
function Srv.bad(p, what)
    local m = memOf(p:getUsername())
    local now = getTimestampMs()
    if not m.badAt or now - m.badAt >= L.MINUTE_MS then m.badAt, m.badN = now, 0 end
    if m.badN >= L.BAD_LINES then return end
    m.badN = m.badN + 1
    Srv.log("bad arguments: " .. tostring(p:getUsername()) .. " on " .. tostring(what))
end

function Srv.to(p, module, command, args) sendServerCommand(p, module, command, args) end

-- the answer to a command: rid only if the client sent a good one
function Srv.ack(p, rid, ok, err, extra)
    local a = extra or {}
    a.ok = ok == true
    a.rid = rid
    a.err = err
    Srv.to(p, Tk.MOD, "t_ack", a)
end

function Srv.eachOnline(fn)
    local list = getOnlinePlayers()
    for i = 0, list:size() - 1 do fn(list:get(i)) end
end
-- can is tested again at every push, so a demoted client gets no more
function Srv.eachStaff(fn)
    local list = getOnlinePlayers()
    for i = 0, list:size() - 1 do
        local o = list:get(i)
        if Srv.can(o, CAP_STAFF) then fn(o) end
    end
end
-- (getPlayerFromUsername is not server-safe: it calls GameClient.instance)
function Srv.player(user)
    local list = getOnlinePlayers()
    for i = 0, list:size() - 1 do
        local o = list:get(i)
        if o:getUsername() == user then return o end
    end
    return nil
end

-- opts: cap (the capability it needs), limit (ms between runs), mark = false when the handler marks an accepted run itself
function Srv.register(module, command, opts, fn)
    Srv.handlers[module .. "." .. command] = { name = command, cap = opts.cap, limit = opts.limit, mark = opts.mark, fn = fn }
end

local function run(h, p, a, rid)
    if h.cap and not Srv.can(p, h.cap) then
        Srv.deny(p, h.name)
        Srv.ack(p, rid, false, "perm")
        return
    end
    if h.limit then
        local left = Srv.left(p, h.name, h.limit)
        if left then
            Srv.ack(p, rid, false, "wait", { left = left })
            return
        end
        if h.mark ~= false then Srv.mark(p, h.name) end
    end
    h.fn(p, a, rid)
end

function Srv.onCommand(module, command, player, args)
    if module ~= Tk.MOD_LINK and module ~= Tk.MOD then return end
    if Srv.off or not player then return end
    if not general(player:getUsername(), getTimestampMs()) then return end
    local h = Srv.handlers[module .. "." .. tostring(command)]
    if not h then return end            -- (a newer client's command: both sides ignore what they do not know)
    if type(args) ~= "table" then args = {} end   -- (an empty table arrives as nil)
    local rid = Tk.whole(args.rid) and args.rid or nil
    local ok, err = pcall(run, h, player, args, rid)
    if not ok then
        Srv.log("handler failed: " .. tostring(command) .. " from " .. tostring(player:getUsername()) .. ": " .. tostring(err))
        print("[ZeD] server: " .. tostring(command) .. " failed: " .. tostring(err))
        pcall(Srv.ack, player, rid, false, "fail")
    end
end

-- ---------------------------------------------------------------------------
-- HELLO: is the server part here, and what may this player do
-- ---------------------------------------------------------------------------
Srv.register(Tk.MOD_LINK, "hello", { limit = L.HELLO_MS }, function(p, a, rid)
    local r = { v = Tk.PROTO, staff = Srv.can(p, CAP_STAFF), admin = Srv.can(p, CAP_ADMIN) }
    if Srv.helloFill then Srv.helloFill(p, r) end   -- (ZeD_ServerTickets.lua: frozen, unread, the counts for staff)
    Srv.to(p, Tk.MOD_LINK, "hello", r)
end)

-- ---------------------------------------------------------------------------
-- UP, OR OFF
-- ---------------------------------------------------------------------------
if not (CAP_STAFF and CAP_ADMIN) then
    Srv.off = true
    print("[ZeD] server part off: this game has no AnswerTickets or RolesWrite capability")
    Srv.log("server part off: a capability is missing from this game version")
    return
end
Srv.off = nil

if Srv.listening == nil then
    Srv.listening = true
    -- (looked up at each call, so a reload of this file takes effect)
    Events.OnClientCommand.Add(function(module, command, player, args) ZeD.Srv.onCommand(module, command, player, args) end)
end

-- Any client can write to any logger through ISLogSystem (A5). The ZeD log is closed to that channel, by name with
-- its case and punctuation ignored. ISLogSystem.OnClientCommand looks the function up at each call.
if not Srv.logClosed and ISLogSystem and ISLogSystem.writeLog then
    Srv.logClosed = true
    local base = ISLogSystem.writeLog
    ISLogSystem.writeLog = function(who, packet)
        local name = packet and packet.loggerName
        if type(name) == "string" then
            local plain = string.gsub(string.lower(name), "[^%a]", "")
            if string.find(plain, "zed", 1, true) then return end
        end
        return base(who, packet)
    end
end

print("[ZeD] server part up, protocol " .. tostring(Tk.PROTO))
Srv.log("server part up, protocol " .. tostring(Tk.PROTO))

return Srv
