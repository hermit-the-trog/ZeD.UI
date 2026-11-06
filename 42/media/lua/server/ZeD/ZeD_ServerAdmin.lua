-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerAdmin.lua
-- ============================================================================
-- THE ADMIN TOOLS, THE SERVER'S SIDE (ZeDUI/MP_ADMIN_SCOPE.md, Phase 2; MP_SERVER_PART_DESIGN.md, A3, A7 and E7). Every
-- power is decided here, from the player the event gives, never from a client's word. A client that passes gets an ack,
-- and only then makes the game's call: server Lua cannot kick, ban or set a role (A7), so that call goes from the acting
-- staff client.
--
-- Ban calls that must wait or must not be lost (a player reading the reason first, an unban with the actor gone) sit in
-- md.owed and go to a staff client online until one says it is done.
--
-- Timed bans are ZeD's own (E7, settled): the server keeps the list and lifts each to the second, with nobody on. On
-- joining, the server tells the client to show the reason and leave; a client that stays is reported to staff, who can
-- use the game's ban. Permanent bans are the game's. Repeating messages run here too, on OnTickEvenPaused (A1): the game
-- clock stops on an empty server.
--
-- The table has a secret random name, as the tickets' does (A2), and is never transmitted. Views are allowlists. Every
-- action goes through Srv.adminLog: a line in the ZeD log and a line in md.log, which Phase 4's Log view reads.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_ServerCore"
require "ZeD/ZeD_ServerTickets"

local Srv = ZeD.Srv
local Tk = ZeD.Tk
local Adm = ZeD.Adm
if not Srv or Srv.off then return end

local AL = Adm.L
local PREFIX = "ZeD_AD_"
local SCHEMA = 1
local MIGRATE = {}                   -- MIGRATE[1] = function(md) ... end   moves 1 to 2; adds or reshapes, never drops

-- (a capability a later game renamed would be nil, and hasCapability(nil) matches no overload: the part stays off)
local CAP = {}
for _, name in ipairs(Adm.SERVER_CAPS) do
    CAP[name] = Capability and Capability[name]
    if not CAP[name] then
        Srv.log("admin tools off: this game has no " .. name .. " capability")
        print("[ZeD] admin tools off: no " .. name)
        return
    end
end

-- memory only: a /reloadlua of this file leaves it empty and open() fills it again
local T = { told = {}, seen = {}, watch = {} }
Srv.A = T

-- ---------------------------------------------------------------------------
-- THE TABLE
-- ---------------------------------------------------------------------------
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
    if found > 1 then Srv.log("found " .. found .. " admin tables; using the first by name") end
    return best
end

local function open()
    if T.md then return T.md end
    local name = findName() or (PREFIX .. getRandomUUID())
    local md = ModData.getOrCreate(name)
    md.schema = md.schema or SCHEMA
    md.nextBan = md.nextBan or 1
    md.nextRep = md.nextRep or 1
    md.nextOwe = md.nextOwe or 1
    md.bans = md.bans or {}          -- id -> a ban; a timed one holds untilT
    md.repeats = md.repeats or {}    -- id -> a repeating message
    md.owed = md.owed or {}          -- id -> a game call for a staff client
    md.players = md.players or {}    -- username -> what was last seen of them
    md.mutes = md.mutes or {}        -- username -> who muted them
    md.log = md.log or { n = 0, at = 0 }
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
    if T.frozen then Srv.log("the admin table is frozen: schema " .. tostring(md.schema) .. ", this ZeD knows " .. SCHEMA) end
    T.md = md
    return md
end

local function frozen(p, rid)
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return true end
    return false
end

-- ---------------------------------------------------------------------------
-- THE LOG: who, what, on whom, where, real time and in-game day
-- ---------------------------------------------------------------------------
local function today() return math.floor(getGameTime():getWorldAgeHours() / 24) + 1 end

-- a ring of AL.LOG_MAX lines: md.log[at] is the newest, the oldest is overwritten
function Srv.adminLog(who, what, target, detail, x, y, z)
    local md = open()
    local line = "admin " .. tostring(what) .. " by " .. tostring(who)
    if target then line = line .. " on " .. tostring(target) end
    if x then line = line .. " at " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) end
    if detail then line = line .. ": " .. tostring(detail) end
    Srv.log(line)
    if T.frozen then return end
    local log = md.log
    log.at = (log.at >= AL.LOG_MAX) and 1 or (log.at + 1)
    log.n = math.min(log.n + 1, AL.LOG_MAX)
    log[log.at] = { t = getTimestamp(), day = today(), who = who, what = what, target = target, text = detail, x = x, y = y, z = z }
end

local function logAt(p, what, target, detail)
    Srv.adminLog(p:getUsername(), what, target, detail, math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ()))
end

-- ---------------------------------------------------------------------------
-- WHO MAY ACT ON WHOM
-- ---------------------------------------------------------------------------
local function roleNamed(name)
    local roles = getRoles()
    for i = 0, roles:size() - 1 do
        local r = roles:get(i)
        if r:getName() == name then return r end
    end
    return nil
end

-- (A3: the field may be null)
local function roleName(o)
    local r = o:getRole()
    return r and r:getName() or nil
end

-- the target's role as far as the server can tell: online, the role they hold; offline, the one last seen
local function roleOf(md, user)
    local o = Srv.player(user)
    if o then return o:getRole() end
    local rec = md.players[user]
    return rec and rec.role and roleNamed(rec.role) or nil
end

local function position(o)
    local r = o:getRole()
    return r and r:getPosition() or -1
end

-- nil when p may act on this target, else the error word
local function guard(md, p, user, protect, allowSelf)
    if user == p:getUsername() then
        if allowSelf then return nil end
        return "self"
    end
    local r = roleOf(md, user)
    if r and protect and r:hasCapability(protect) then return "protected" end
    if r and Adm.RANK_GUARD and r:getPosition() > position(p) then return "rank" end
    return nil
end

local function okUser(s) return type(s) == "string" and #s >= 1 and #s <= AL.TARGET_MAX and Tk.name(s) == s end

-- ---------------------------------------------------------------------------
-- WHAT EACH PERSON RECEIVES: built field by field from an allowlist
-- ---------------------------------------------------------------------------
local function listCopy(list)
    local out = {}
    for i, v in ipairs(list or {}) do out[i] = v end
    return out
end

local function skillsCopy(list)
    local out = {}
    for i, s in ipairs(list or {}) do out[i] = { id = s.id, name = s.name, lv = s.lv } end
    return out
end

-- what the server reads of a player: their profession, traits and skills, at the moment of asking
local function readPlayer(o, all)
    local out = { traits = {}, skills = {} }
    local d = o:getDescriptor()
    local prof = d and d:getCharacterProfession()
    local def = prof and CharacterProfessionDefinition.getCharacterProfessionDefinition(prof)
    if def then out.prof = def:getUIName() end
    local known = o:getCharacterTraits():getKnownTraits()
    for i = 0, known:size() - 1 do
        local tr = CharacterTraitDefinition.getCharacterTraitDefinition(known:get(i))
        if tr then out.traits[#out.traits + 1] = tr:getLabel() end
    end
    for i = 0, Perks.getMaxIndex() - 1 do
        local perk = Perks.fromIndex(i)
        local pf = PerkFactory.getPerk(perk)
        if pf and pf:getParent() ~= Perks.None then
            local lv = o:getPerkLevel(perk)
            if all or lv > 0 then out.skills[#out.skills + 1] = { id = tostring(perk), name = pf:getName(), lv = lv } end
        end
    end
    return out
end

local function banRow(b)
    return { id = b.id, user = b.user, sid = b.sid, ip = b.ip, reason = b.reason, by = b.by, at = b.at, day = b.day,
        untilT = b.untilT, banIp = b.banIp, stay = b.stay, gameBan = b.gameBan }
end

local function leaveView(b)
    return { kind = "ban", reason = b.reason, untilT = b.untilT, by = b.by }
end

local function cardView(md, user)
    local o = Srv.player(user)
    local rec = md.players[user]
    local v = { user = user, on = o ~= nil, muted = md.mutes[user] ~= nil, last = rec and rec.t or nil }
    if o then
        local r = readPlayer(o, true)
        v.prof, v.traits, v.skills = r.prof, r.traits, r.skills
        v.role = roleName(o)
        v.x, v.y, v.z = math.floor(o:getX()), math.floor(o:getY()), math.floor(o:getZ())
        v.oid = o:getOnlineID()
    elseif rec then
        v.prof, v.traits, v.skills, v.role = rec.prof, listCopy(rec.traits), skillsCopy(rec.skills), rec.role
    end
    if Srv.ticketsOf then v.tickets, v.ticketN = Srv.ticketsOf(user, AL.TICKETS_ROWS) end
    for _, b in pairs(md.bans) do
        if b.user == user then v.banId = b.id end
    end
    return v
end

local function repeatRows(md)
    local out = {}
    for _, r in pairs(md.repeats) do out[#out + 1] = { id = r.id, text = r.text, every = r.every, by = r.by } end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function pushRepeats(md)
    local rows = repeatRows(md)
    Srv.eachOnline(function(o)
        if Srv.can(o, CAP.DisplayServerMessage) then Srv.to(o, Adm.MOD, "a_repeats", { rows = rows }) end
    end)
end

local function muteList(md)
    local out = {}
    for u in pairs(md.mutes) do out[#out + 1] = u end
    table.sort(out)
    return out
end

-- ---------------------------------------------------------------------------
-- WHAT IS OWED TO THE GAME: a ban call a staff client must make
-- ---------------------------------------------------------------------------
-- act: Ban (user, reason, banIp), BanSteamID (target, reason), BanIPOnly (target), Kick (user, reason), UnBan (user),
-- UnBanSteamID (target), UnBanIPOnly (target). at: not before this second.
local function owe(md, act, target, reason, delay, by, banIp)
    local n, low = 0, nil
    for id in pairs(md.owed) do
        n = n + 1
        if not low or id < low then low = id end
    end
    if n >= AL.OWED_MAX then
        Srv.log("owed game calls full: dropped " .. tostring(md.owed[low].act) .. " on " .. tostring(md.owed[low].target))
        md.owed[low] = nil
    end
    local id = md.nextOwe
    md.nextOwe = id + 1
    md.owed[id] = { id = id, act = act, target = target, reason = reason, at = getTimestamp() + (delay or 0), by = by, banIp = banIp }
end

local function owedCap(act) if act == "Kick" then return CAP.KickUser end return CAP.BanUnbanUser end

-- to the one who asked if they are on, else any staff member with the power
local function sendOwed(md, now)
    for _, e in pairs(md.owed) do
        if now >= e.at and (not e.sent or now - e.sent >= AL.OWED_RETRY_S) then
            local cap = owedCap(e.act)
            local who = e.by and Srv.player(e.by)
            if not (who and Srv.can(who, cap)) then
                who = nil
                Srv.eachOnline(function(o) if not who and Srv.can(o, cap) then who = o end end)
            end
            if who then
                e.sent = now
                Srv.to(who, Adm.MOD, "a_owed", { id = e.id, act = e.act, target = e.target, reason = e.reason, banIp = e.banIp })
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- THE TIMED BANS
-- ---------------------------------------------------------------------------
local function timedFor(md, user, sid)
    for _, b in pairs(md.bans) do
        if b.untilT and (b.user == user or (sid and b.sid == sid)) then return b end
    end
    return nil
end

local function tellLeave(o, b, now)
    T.told[o:getUsername()] = { at = now, id = b.id }
    Srv.to(o, Adm.MOD, "a_leave", leaveView(b))
end

-- a banned client still here: staff are told, and it is written on the ban
local function reportStay(md, user, b, told, now)
    told.noted = now
    b.stay = now
    Srv.log("a banned client has not left: " .. tostring(user))
    Srv.eachOnline(function(o)
        if Srv.can(o, CAP.BanUnbanUser) then Srv.to(o, Adm.MOD, "a_note", { kind = "stay", user = user, id = b.id }) end
    end)
end

local function checkBan(md, o, user, now)
    local rec = md.players[user]
    local b = timedFor(md, user, rec and rec.sid)
    if not b then
        T.told[user] = nil
        return
    end
    local told = T.told[user]
    if not told or told.id ~= b.id then
        tellLeave(o, b, now)
    elseif now - told.at >= AL.STAY_S and (not told.noted or now - told.noted >= AL.STAY_EVERY_S) then
        reportStay(md, user, b, told, now)
        Srv.to(o, Adm.MOD, "a_leave", leaveView(b))
    end
end

local function liftDue(md, now)
    local due = nil
    for id, b in pairs(md.bans) do
        if b.untilT and b.untilT <= now then
            due = due or {}
            due[#due + 1] = id
        end
    end
    for _, id in ipairs(due or {}) do
        local b = md.bans[id]
        md.bans[id] = nil
        T.told[b.user or ""] = nil
        if b.gameBan then owe(md, "UnBan", b.user, "", 0, b.by) end
        Srv.adminLog("server", "ban lifted", b.user or b.sid, "the time ran out")
    end
end

-- ---------------------------------------------------------------------------
-- THE CLOCK: OnTickEvenPaused fires with nobody on (A1), and getTimestamp is real time
-- ---------------------------------------------------------------------------
local function snap(md, o, user, now)
    local rec = md.players[user]
    if not rec then
        rec = {}
        md.players[user] = rec
    end
    rec.t = now
    rec.role = roleName(o)
    if not rec.snapAt or now - rec.snapAt >= AL.SNAP_S then
        rec.snapAt = now
        local r = readPlayer(o, false)
        rec.prof, rec.traits, rec.skills = r.prof, r.traits, r.skills
    end
end

local function trimPlayers(md)
    local n, oldest, oldT = 0, nil, nil
    for u, r in pairs(md.players) do
        n = n + 1
        if not T.seen[u] and (not oldT or (r.t or 0) < oldT) then oldest, oldT = u, r.t or 0 end
    end
    if n > AL.PLAYERS_MAX and oldest then md.players[oldest] = nil end
end

local function walkPlayers(md, now)
    local seen = {}
    local list = getOnlinePlayers()
    for i = 0, list:size() - 1 do
        local o = list:get(i)
        local user = o:getUsername()
        seen[user] = true
        snap(md, o, user, now)
        checkBan(md, o, user, now)
    end
    for u in pairs(T.told) do
        if not seen[u] then T.told[u] = nil end
    end
    T.seen = seen
    trimPlayers(md)
end

local function runRepeats(md, now)
    for _, r in pairs(md.repeats) do
        if now >= r.nextAt then
            r.nextAt = now + r.every * 60      -- (from now, so a paused or empty stretch never fires a burst)
            if getOnlinePlayers():size() > 0 then
                sendServerCommand(Adm.MOD, "a_srvmsg", { text = r.text })
            end
        end
    end
end

-- a role change waits for the game: once it has applied, the powers nobody ticked go off (it set them on the server's
-- object in GameServer.changeRole, so they are off there too, and the player's own client tells the rest)
local function runWatch(now)
    local done = nil
    for user, w in pairs(T.watch) do
        local o = Srv.player(user)
        if o and roleName(o) == w.role then
            for _, id in ipairs(w.off) do
                if id == "Invisible" then o:setGhostMode(false)
                elseif id == "NoClip" then o:setNoClip(false)
                elseif id == "GodMod" then o:setGodMod(false) end
            end
            if #w.off > 0 then Srv.to(o, Adm.MOD, "a_powersoff", { ids = w.off }) end
            done = done or {}
            done[#done + 1] = user
        elseif now - w.at >= AL.ROLE_WATCH_S then
            done = done or {}
            done[#done + 1] = user
        end
    end
    for _, u in ipairs(done or {}) do T.watch[u] = nil end
end

function Srv.adminTick()
    local now = getTimestamp()
    if T.at == now then return end
    T.at = now
    local md = open()
    if T.frozen then return end
    liftDue(md, now)
    if not T.walkAt or now - T.walkAt >= AL.POLL_S then
        T.walkAt = now
        walkPlayers(md, now)
    end
    runRepeats(md, now)
    runWatch(now)
    sendOwed(md, now)
end

-- ---------------------------------------------------------------------------
-- THE COMMANDS: every one takes its player from the event, and only an ack's ok lets a client make the game's call
-- ---------------------------------------------------------------------------
local function reg(command, opts, fn) Srv.register(Adm.MOD, command, opts, fn) end

-- the steam id a client says it has: a timed ban on a Steam ID is client enforced anyway (IsoPlayer.getSteamID is a long
-- past what a Lua number holds), and a client that lies about it is one that would not have left. The hello's echo too.
reg("a_hi", { limit = Tk.LIMITS.HELLO_MS }, function(p, a, rid)
    local md = open()
    local user = p:getUsername()
    if not T.frozen then
        local now = getTimestamp()
        snap(md, p, user, now)
        if type(a.sid) == "string" and #a.sid <= AL.TARGET_MAX and Adm.targetKind(a.sid) == "sid" then md.players[user].sid = a.sid end
        T.told[user] = nil           -- (back within one walk of leaving: told again)
        checkBan(md, p, user, now)
    end
    Srv.to(p, Adm.MOD, "a_mutes", { list = muteList(md) })
end)

reg("a_players", { cap = CAP.SeePlayersConnected, limit = AL.PLAYERS_MS }, function(p, a, rid)
    local md = open()
    local rows, n, seen = {}, 0, {}
    Srv.eachOnline(function(o)
        local u = o:getUsername()
        seen[u] = true
        n = n + 1
        rows[n] = { u = u, on = true, role = roleName(o) }
    end)
    local off, c = {}, 0
    for u, r in pairs(md.players) do
        if not seen[u] then
            c = c + 1
            off[c] = { u = u, on = false, role = r.role, last = r.t }
        end
    end
    table.sort(off, function(x, y) return (x.last or 0) > (y.last or 0) end)
    for i = 1, math.min(c, AL.PLAYERS_ROWS - n) do
        n = n + 1
        rows[n] = off[i]
    end
    Srv.to(p, Adm.MOD, "a_players", { rows = rows, muted = muteList(md) })
end)

reg("a_card", { cap = CAP.CanSeePlayersStats, limit = AL.CARD_MS, mark = true }, function(p, a, rid)
    if not okUser(a.user) then
        Srv.bad(p, "a_card")
        Srv.ack(p, rid, false, "gone")
        return
    end
    local v = cardView(open(), a.user)
    Srv.to(p, Adm.MOD, "a_card", v)
    if rid then Srv.ack(p, rid, true) end
end)

-- the checks every act on a player shares; the target's name, or nil with the answer sent
local function onUser(p, a, rid, protect, allowSelf)
    if not okUser(a.user) then
        Srv.bad(p, "admin target")
        Srv.ack(p, rid, false, "gone")
        return nil
    end
    local md = open()
    if frozen(p, rid) then return nil end
    local err = guard(md, p, a.user, protect, allowSelf)
    if err then
        Srv.ack(p, rid, false, err)
        return nil
    end
    return a.user, md
end

local function online(p, rid, user)
    local o = Srv.player(user)
    if not o then Srv.ack(p, rid, false, "offline") end
    return o
end

reg("a_tp", { cap = CAP.TeleportToPlayer }, function(p, a, rid)
    local user = onUser(p, a, rid)
    if not user or not online(p, rid, user) then return end
    logAt(p, "teleport to", user)
    Srv.ack(p, rid, true)
end)

reg("a_bring", { cap = CAP.TeleportPlayerToAnotherPlayer }, function(p, a, rid)
    local user = onUser(p, a, rid)
    if not user or not online(p, rid, user) then return end
    logAt(p, "teleport to you", user)
    Srv.ack(p, rid, true)
end)

reg("a_kick", { cap = CAP.KickUser }, function(p, a, rid)
    local user = onUser(p, a, rid, CAP.CantBeKickedByUser)
    if not user or not online(p, rid, user) then return end
    local reason = Adm.line(a.reason, AL.REASON_MAX)
    if not reason then Srv.ack(p, rid, false, "text"); return end
    logAt(p, "kick", user, reason)
    Srv.ack(p, rid, true, nil, { reason = reason })
end)

reg("a_warn", { cap = CAP.AddUserlog }, function(p, a, rid)
    local user = onUser(p, a, rid)
    if not user then return end
    local reason = Adm.line(a.reason, AL.REASON_MAX)
    local n = a.n
    if not reason or not Tk.whole(n) or n > AL.WARN_MAX then Srv.ack(p, rid, false, "text"); return end
    logAt(p, "warning points", user, tostring(n) .. ": " .. reason)
    Srv.ack(p, rid, true, nil, { reason = reason, n = n })
end)

reg("a_mute", { cap = CAP.BanUnbanUser }, function(p, a, rid)
    local user, md = onUser(p, a, rid)
    if not user then return end
    if a.on == true then md.mutes[user] = p:getUsername() else md.mutes[user] = nil end
    logAt(p, (a.on == true) and "mute" or "unmute", user)
    Srv.ack(p, rid, true)
    sendServerCommand(Adm.MOD, "a_mutes", { list = muteList(md) })
end)

reg("a_role", { cap = CAP.ChangeAccessLevel }, function(p, a, rid)
    if not Srv.can(p, CAP.ModifyNetworkUsers) then
        Srv.deny(p, "a_role")
        Srv.ack(p, rid, false, "perm")
        return
    end
    if not okUser(a.user) or type(a.role) ~= "string" or #a.role > AL.TARGET_MAX then
        Srv.bad(p, "a_role")
        Srv.ack(p, rid, false, "gone")
        return
    end
    local md = open()
    if frozen(p, rid) then return end
    if a.user == p:getUsername() then Srv.ack(p, rid, false, "self"); return end
    local new = roleNamed(a.role)
    if not new then Srv.ack(p, rid, false, "gone"); return end
    local mine = position(p)
    local old = roleOf(md, a.user)
    if new:getPosition() > mine or (old and old:getPosition() > mine) then Srv.ack(p, rid, false, "rank"); return end
    local keep = {}
    if type(a.keep) == "table" then
        for _, id in ipairs(a.keep) do keep[id] = true end
    end
    local off = {}
    for _, pw in ipairs(Adm.POWERS) do
        local c = CAP[pw.cap]
        if new:hasCapability(c) and not (old and old:hasCapability(c)) and not keep[pw.id] then off[#off + 1] = pw.id end
    end
    T.watch[a.user] = { role = new:getName(), off = off, at = getTimestamp() }
    logAt(p, "role", a.user, new:getName())
    Srv.ack(p, rid, true)
end)

reg("a_skill", { cap = CAP.AddXP }, function(p, a, rid)
    local user = onUser(p, a, rid, nil, true)
    if not user then return end
    local o = online(p, rid, user)
    if not o then return end
    if type(a.perk) ~= "string" or #a.perk > AL.TARGET_MAX or (a.dir ~= 1 and a.dir ~= -1) then
        Srv.bad(p, "a_skill")
        Srv.ack(p, rid, false, "text")
        return
    end
    local perk = nil
    for i = 0, Perks.getMaxIndex() - 1 do
        local one = Perks.fromIndex(i)
        if tostring(one) == a.perk then perk = one end
    end
    if not perk then Srv.ack(p, rid, false, "gone"); return end
    local level = o:getPerkLevel(perk) + a.dir
    if level < 0 or level > 10 then Srv.ack(p, rid, false, "state"); return end
    local amount = perk:getTotalXpForLevel(level) - o:getXp():getXP(perk)
    logAt(p, (a.dir > 0) and "level up" or "level down", user, a.perk .. " to " .. tostring(level))
    Srv.ack(p, rid, true, nil, { perk = a.perk, amount = amount, level = level })
end)

-- ---------------------------------------------------------------------------
-- BANS
-- ---------------------------------------------------------------------------
reg("a_bans", { cap = CAP.BanUnbanUser, limit = AL.LIST_MS }, function(p, a, rid)
    local md = open()
    local rows = {}
    for _, b in pairs(md.bans) do rows[#rows + 1] = banRow(b) end
    table.sort(rows, function(x, y) return x.id > y.id end)
    Srv.to(p, Adm.MOD, "a_bans", { rows = rows })
end)

local function banCount(md)
    local n = 0
    for _ in pairs(md.bans) do n = n + 1 end
    return n
end

local function pushBans(md)
    local rows = {}
    for _, b in pairs(md.bans) do rows[#rows + 1] = banRow(b) end
    table.sort(rows, function(x, y) return x.id > y.id end)
    Srv.eachOnline(function(o)
        if Srv.can(o, CAP.BanUnbanUser) then Srv.to(o, Adm.MOD, "a_bans", { rows = rows }) end
    end)
end

-- a_ban: user (a username), or target (a username, Steam ID or IP, typed on the Bans card); sid when the card knows it
reg("a_ban", { cap = CAP.BanUnbanUser }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local target = a.user or a.target
    local kind = Adm.targetKind(target)
    local len = Adm.LENGTH[a.len]
    local reason = Adm.line(a.reason, AL.REASON_MAX)
    if not okUser(target) or not kind or not len then
        Srv.bad(p, "a_ban")
        Srv.ack(p, rid, false, "text")
        return
    end
    if not reason then Srv.ack(p, rid, false, "text"); return end
    if banCount(md) >= AL.BANS_MAX then Srv.ack(p, rid, false, "full"); return end
    local untilT = len.sec and (getTimestamp() + len.sec) or nil
    if kind == "ip" and untilT then Srv.ack(p, rid, false, "ipperm"); return end
    local banIp = a.banIp == true and kind == "user"
    if banIp and untilT and not Adm.TIMED_IP then Srv.ack(p, rid, false, "ipperm"); return end
    if kind == "user" then
        local err = guard(md, p, target, CAP.CantBeBannedByUser)
        if err then Srv.ack(p, rid, false, err); return end
    end
    local me = p:getUsername()
    local id = md.nextBan
    md.nextBan = id + 1
    local b = { id = id, reason = reason, by = me, at = getTimestamp(), day = today(), untilT = untilT, banIp = banIp or nil }
    if kind == "user" then
        b.user = target
        local rec = md.players[target]
        b.sid = (type(a.sid) == "string" and Adm.targetKind(a.sid) == "sid" and a.sid) or (rec and rec.sid) or nil
    elseif kind == "sid" then
        b.sid = target
    else
        b.ip = target
    end
    md.bans[id] = b
    local o = (kind == "user") and Srv.player(target) or nil
    local wait = o and AL.LEAVE_S or 0
    if o then tellLeave(o, b, getTimestamp()) end
    if untilT then
        if o then owe(md, "Kick", target, reason, wait, me) end
    elseif kind == "user" then
        owe(md, "Ban", target, reason, wait, me, banIp or nil)
    elseif kind == "sid" then
        owe(md, "BanSteamID", target, reason, 0, me)
    else
        owe(md, "BanIPOnly", target, reason, 0, me)
    end
    logAt(p, "ban", target, (untilT and (tostring(a.len) .. ": ") or "permanent: ") .. reason)
    Srv.ack(p, rid, true, nil, { id = id, untilT = untilT })
    pushBans(md)
end)

-- a_unban: id (ZeD's record), or kind and target for a ban only the game holds
reg("a_unban", { cap = CAP.BanUnbanUser }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local me = p:getUsername()
    if Tk.whole(a.id) then
        local b = md.bans[a.id]
        if not b then Srv.ack(p, rid, false, "gone"); return end
        md.bans[a.id] = nil
        if b.user then T.told[b.user] = nil end
        if not b.untilT or b.gameBan then
            if b.user then owe(md, "UnBan", b.user, "", 0, me)
            elseif b.sid then owe(md, "UnBanSteamID", b.sid, "", 0, me)
            else owe(md, "UnBanIPOnly", b.ip, "", 0, me) end
        end
        logAt(p, "unban", b.user or b.sid or b.ip)
    else
        local target = a.target
        local kind = Adm.targetKind(target)
        if not okUser(target) or not kind then
            Srv.bad(p, "a_unban")
            Srv.ack(p, rid, false, "gone")
            return
        end
        owe(md, (kind == "ip" and "UnBanIPOnly") or (kind == "sid" and "UnBanSteamID") or "UnBan", target, "", 0, me)
        logAt(p, "unban", target)
    end
    Srv.ack(p, rid, true)
    pushBans(md)
end)

-- a staff client made the game's call
reg("a_done", {}, function(p, a, rid)
    local md = open()
    if T.frozen or not Tk.whole(a.id) then return end
    local e = md.owed[a.id]
    if e and Srv.can(p, owedCap(e.act)) then md.owed[a.id] = nil end
end)

-- a client that did not leave: staff reach for the game's ban. It lifts with the timed ban, through a staff client
reg("a_gameban", { cap = CAP.BanUnbanUser }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local b = Tk.whole(a.id) and md.bans[a.id] or nil
    if not b or not b.user then Srv.ack(p, rid, false, "gone"); return end
    b.gameBan = true
    owe(md, "Ban", b.user, b.reason, 0, p:getUsername())
    logAt(p, "game ban", b.user, b.reason)
    Srv.ack(p, rid, true)
    pushBans(md)
end)

-- ---------------------------------------------------------------------------
-- SERVER MESSAGES
-- ---------------------------------------------------------------------------
reg("a_msg", { cap = CAP.DisplayServerMessage }, function(p, a, rid)
    local text = Adm.line(a.text, AL.MSG_MAX)
    if not text then Srv.ack(p, rid, false, "text"); return end
    logAt(p, "server message", nil, text)
    Srv.ack(p, rid, true, nil, { text = text })
end)

reg("a_repeat", { cap = CAP.DisplayServerMessage }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local text = Adm.line(a.text, AL.MSG_MAX)
    if not text or not Adm.EVERY_OK[a.every] then Srv.ack(p, rid, false, "text"); return end
    local n = 0
    for _ in pairs(md.repeats) do n = n + 1 end
    if n >= AL.REPEATS_MAX then Srv.ack(p, rid, false, "full"); return end
    local id = md.nextRep
    md.nextRep = id + 1
    md.repeats[id] = { id = id, text = text, every = a.every, by = p:getUsername(), nextAt = getTimestamp() + a.every * 60 }
    logAt(p, "repeating message", nil, tostring(a.every) .. " min: " .. text)
    Srv.ack(p, rid, true, nil, { id = id, text = text })
    pushRepeats(md)
end)

reg("a_stop", { cap = CAP.DisplayServerMessage }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    if not Tk.whole(a.id) or not md.repeats[a.id] then Srv.ack(p, rid, false, "gone"); return end
    md.repeats[a.id] = nil
    logAt(p, "repeating message stopped", nil, tostring(a.id))
    Srv.ack(p, rid, true)
    pushRepeats(md)
end)

reg("a_repeats", { cap = CAP.DisplayServerMessage, limit = AL.LIST_MS }, function(p, a, rid)
    Srv.to(p, Adm.MOD, "a_repeats", { rows = repeatRows(open()) })
end)

-- ---------------------------------------------------------------------------
-- SPAWN ITEMS: the server makes them, as server/ClientCommands.lua does, and each spawn is logged
-- ---------------------------------------------------------------------------
reg("a_spawn", { cap = CAP.AddItem, limit = AL.SPAWN_MS }, function(p, a, rid)
    local item, n, to = a.item, a.n, a.to
    if type(item) ~= "string" or #item > AL.TARGET_MAX * 2 or not string.match(item, "^[%w_%-]+%.[%w_%-%.]+$")
        or not Tk.whole(n) or n > AL.SPAWN_MAX or type(to) ~= "string" or #to > AL.TARGET_MAX then
        Srv.bad(p, "a_spawn")
        Srv.ack(p, rid, false, "text")
        return
    end
    if not getScriptManager():FindItem(item) then Srv.ack(p, rid, false, "item"); return end
    if to == "ground" then
        local sq = p:getCurrentSquare()
        if not sq then Srv.ack(p, rid, false, "state"); return end
        for _ = 1, n do sq:AddWorldInventoryItem(item, 0.5, 0.5, 0) end
    else
        local o = (to == "me") and p or Srv.player(to)
        if not o then Srv.ack(p, rid, false, "offline"); return end
        local inv = o:getInventory()
        for _ = 1, n do
            local it = inv:AddItem(item)
            if it then sendAddItemToContainer(inv, it) end
        end
    end
    local other = nil
    if to ~= "me" and to ~= "ground" then other = to end
    logAt(p, "spawn", other, tostring(n) .. " x " .. item .. " to " .. to)
    if Adm.SPAWN_TELLS and other then Srv.to(Srv.player(other), Adm.MOD, "a_note", { kind = "spawn", n = n, item = item }) end
    Srv.ack(p, rid, true, nil, { n = n })
end)

-- ---------------------------------------------------------------------------
-- ROLES: the game's calls need RolesWrite on their own packet; this writes the line and says the card may go on
-- ---------------------------------------------------------------------------
local ROLE_ACTS = { add = true, save = true, delete = true, default = true, up = true, down = true }

reg("a_rolelog", { cap = CAP.RolesWrite }, function(p, a, rid)
    if not ROLE_ACTS[a.what] or type(a.role) ~= "string" or #a.role < 1 or #a.role > AL.TARGET_MAX then
        Srv.bad(p, "a_rolelog")
        Srv.ack(p, rid, false, "text")
        return
    end
    logAt(p, "roles: " .. a.what, a.role)
    Srv.ack(p, rid, true)
end)

-- your own powers, for the log (the game's own setter already ran; a client that sends this proves nothing but that it did)
reg("a_power", { limit = AL.POWER_MS }, function(p, a, rid)
    local role = p:getRole()
    if type(a.id) ~= "string" or #a.id > AL.TARGET_MAX or not (role and role:hasAdminPower()) then return end
    logAt(p, ((a.on == true) and "power on: " or "power off: ") .. Tk.name(a.id))
end)

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
Srv.modules[Adm.MOD] = true
Srv.helloAdds.admin = function(p, r)
    open()
    r.adm = 1
end

if Srv.adminHooked == nil then
    Srv.adminHooked = true
    -- (looked up at each call, so a reload of this file takes effect; a Lua error costs one second, not the event chain)
    local function safeTick()
        local ok, err = pcall(function() ZeD.Srv.adminTick() end)
        if not ok then
            print("[ZeD] server: admin clock failed: " .. tostring(err))
            ZeD.Srv.log("admin clock failed: " .. tostring(err))
        end
    end
    if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(safeTick) end
    Events.OnInitGlobalModData.Add(function() if ZeD.Srv.openAdmin then ZeD.Srv.openAdmin() end end)
end
Srv.openAdmin = open

return T
