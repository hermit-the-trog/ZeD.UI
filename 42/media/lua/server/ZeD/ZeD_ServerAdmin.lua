-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerAdmin.lua
-- ============================================================================
-- THE ADMIN TOOLS, THE SERVER'S SIDE. Server only (the first line); pure Lua, pure ASCII. Every power is decided here,
-- from the player the event gives, never from a client's word. A client that passes gets an ack, and only then makes the
-- game's call: server Lua cannot kick, ban or set a role, so that call goes from the acting staff client.
--
-- What crosses the wire: the admin tools' model on the client (client/ZeD/ZeD_Admin.lua) sends the a_ commands on module
-- Adm.MOD (a_ban, a_kick, a_card ...). Back come an ack for each (the tickets' t_ack), the lists (a_players, a_card, a_bans,
-- a_repeats, a_mutes) and the pushes: a_owed (a game call for a staff client to make, answered by a_done), a_look (read the
-- game's user list for these names, answered by a_looked), a_leave and a_stay (a banned player's screen), a_note (word for
-- staff), a_powersoff, and a_srvmsg (a repeating message, to everyone).
--
-- Ban calls that must wait or must not be lost (a player reading the reason first, an unban with the actor gone) sit in
-- md.owed and go to a staff client online until that client says it is done. Each is tied to its ban: unbanned or lifted,
-- the call goes with it, and one whose author lost the power or whose target rose above it is dropped at send time.
--
-- Every ban is the game's ban too: the game's own ban, enforced by the server at login, is owed at once, timed or not,
-- and a timed one's unban is owed at its end. A timed ban may run past its time while nobody can make
-- that call, never short. ZeD's row stays the record (reason, end, who) and still shows the leave screen. A client's "done"
-- is not proof: a banned player the server still finds on after VERIFY_S means the ban did not take, and it is asked for
-- again (REOWE_MAX times, each with a log line); a Steam ID ban is read back from the game's own list. A banned client that
-- stays is reported and a Kick is owed, on every stay. A standing ban shuts its holder out of every ZeD command (Srv.gates).
-- The game's unban wins, on the game's own word only: a Steam ID row the game's list held and twice reads without, or a name
-- row whose role a staff client read as banned on the game's user list and later reads as not, is closed with a log line and
-- nothing is lifted or asked for again. An IP the game held and twice reads without drops the row's IP part only. Presence,
-- a login or a leaving is never taken as proof. With no such word a row stays as it was.
-- A mute owes the game's voice ban whenever its player is on and this session has not made it (the game's voice ban is held
-- for the connection only), so a player muted while off has it when they come on; unmuted first, it is dropped.
-- With the host helper on (ZeD_ServerHelper.lua) the calls it can make go to it as well, so they land with no staff online.
-- Repeating messages run here too, on OnTickEvenPaused: the game clock stops on an empty server.
--
-- The table has a secret random name, as the tickets' does (any logged-in client can read a global mod data table it can
-- name), and is never transmitted. Views are allowlists. Every action goes through Srv.adminLog into the server part's one
-- log (Srv.action): a line in the ZeD log and a line in md.log, which the Log view reads (ZeD_ServerLog.lua). The ring here
-- holds every kind of line, not only these.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_ServerCore"
require "ZeD/ZeD_ServerTickets"
require "ZeD/ZeD_ServerHelper"

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
        Srv.action("admin", Tk.SYS, "admin tools off", nil, "this game has no " .. name .. " capability")
        print("[ZeD] admin tools off: no " .. name)
        return
    end
end

-- memory only: a /reloadlua of this file leaves it empty and open() fills it again
-- looks: the one look at the game's user list in flight; lookedAt: ban id -> when its name was last looked at; hold: ban id ->
-- a held name ban's player found on, waiting for a look; voiced: lower-case name -> the game's voice ban made this session
local T = { told = {}, seen = {}, kicked = {}, lookedAt = {}, hold = {}, voiced = {} }
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
    if found > 1 then Srv.fileLine("admin", Tk.SYS, "admin tables", nil, "found " .. found .. "; using the first by name") end
    return best
end

-- the rows from before this build brought up to it, once a start (Srv.upgradeBans; never a frozen table)
local function upgrade(md)
    if T.upgraded or T.frozen or not Srv.upgradeBans then return end
    T.upgraded = true
    Srv.upgradeBans(md)
end

local function open()
    if T.md then
        upgrade(T.md)
        return T.md
    end
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
    md.mutes = md.mutes or {}        -- lower-case username -> who muted them
    md.watch = md.watch or {}        -- username -> the powers to switch off when a role lands
    md.log = md.log or { n = 0, at = 0, s = 0 }
    -- (a watch back from a restart waits for that player's hello, when their client can hear it)
    for _, w in pairs(md.watch) do w.hi = true end
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
    if T.frozen then Srv.fileLine("admin", Tk.SYS, "admin table frozen", nil, "schema " .. tostring(md.schema) .. ", this ZeD knows " .. SCHEMA) end
    T.md = md
    upgrade(md)
    return md
end

local function frozen(p, rid)
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return true end
    return false
end

-- ---------------------------------------------------------------------------
-- THE LOG'S RING: who, what, on whom, where, real time and in-game day, for every kind of line
-- ---------------------------------------------------------------------------
local function today() return Srv.day() end

-- where a new line goes. A ring of AL.LOG_MAX, oldest out, but one account never pushes out another's: past its share a
-- new line takes the place of that account's own oldest (s says the order; the Log view sorts by time, then s). A kill
-- goes last, so an account can't write its own evidence off the ring with a run of lesser lines. A container line is the
-- player's own game talking, so it has a smaller share and replaces only its own kind: no client's reports push out what
-- the server saw. nil: there's no room for it
local function ringSlot(log, who, kind)
    local mine, oldest, oldestKill, told, oldestTold = 0, nil, nil, 0, nil
    for i = 1, log.n do
        local l = log[i]
        if l and l.who == who then
            mine = mine + 1
            if l.kind == "pvp" then
                if not oldestKill or (l.s or 0) < (log[oldestKill].s or 0) then oldestKill = i end
            elseif not oldest or (l.s or 0) < (log[oldest].s or 0) then
                oldest = i
            end
            if l.kind == "container" then
                told = told + 1
                if not oldestTold or (l.s or 0) < (log[oldestTold].s or 0) then oldestTold = i end
            end
        end
    end
    if kind == "container" and (told >= AL.LOG_TOLD_MAX or mine >= AL.LOG_ACTOR_MAX) then return oldestTold end
    if mine >= AL.LOG_ACTOR_MAX then return oldest or oldestKill end
    log.at = (log.at >= AL.LOG_MAX) and 1 or (log.at + 1)
    log.n = math.min(log.n + 1, AL.LOG_MAX)
    return log.at
end

--- The ring's half of Srv.action (ZeD_ServerCore.lua): the line, with its real time and in-game day, into md.log.
function Srv.actionStore(kind, who, what, target, detail, x, y, z, ex)
    local md = open()
    if T.frozen then return end
    local log = md.log
    local slot = ringSlot(log, who, kind)
    if not slot then return end
    log.s = (log.s or 0) + 1
    local row = { s = log.s, t = getTimestamp(), day = today(), kind = kind, who = who, what = what, target = target, text = detail, x = x, y = y, z = z }
    if ex then row.car, row.part, row.locked, row.via = ex.car, ex.part, ex.locked, ex.via end
    log[slot] = row
end

--- What the Log view reads the ring through (ZeD_ServerLog.lua): the table, and whether it is frozen.
function Srv.logTable() return open() end
function Srv.logFrozen() return T.frozen == true end

function Srv.adminLog(who, what, target, detail, x, y, z) Srv.action("admin", who, what, target, detail, x, y, z) end

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

-- (getRole may answer null)
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

-- a role's rank for RANK_GUARD: its place, but never under the default user role. A new role starts under every other
-- (Roles.addRole), and its holders still act on plain players.
local function rank(r)
    if not r then return -1 end
    local plain = roleNamed("user")
    return math.max(r:getPosition(), plain and plain:getPosition() or 0)
end
Srv.rank = rank                  -- (ZeD_ServerCommunity.lua: a news post keeps its writer's)

--- Is this name's role above p's? The Log view keeps such a player's places to themselves, as the Player card does. A name
--- with no role to read is not above anyone.
function Srv.outranks(p, user)
    return rank(roleOf(open(), user)) > rank(p:getRole())
end

-- nil when p may act on this target, else the error word. A name nobody online holds and the server has never seen has
-- no role to test: "unknown"
local function guard(md, p, user, protect, allowSelf)
    if user == p:getUsername() then
        if allowSelf then return nil end
        return "self"
    end
    if not Srv.player(user) and not md.players[user] then return "unknown" end
    local r = roleOf(md, user)
    if r and protect and r:hasCapability(protect) then return "protected" end
    if r and Adm.RANK_GUARD and rank(r) > rank(p:getRole()) then return "rank" end
    return nil
end

-- the same for a Steam ID: the guard of every player seen with it
local function guardSid(md, p, sid)
    for user, rec in pairs(md.players) do
        if rec.sid == sid then
            local err = guard(md, p, user, CAP.CantBeBannedByUser)
            if err then return err end
        end
    end
    return nil
end

-- does this ban hold over someone in this role, as it did for its author? (asked again whenever it is about to act: a row
-- made on a name or a Steam ID the server knew little about must never remove a protected or higher role)
local function bindsRole(b, r)
    if not r then return true end
    if r:hasCapability(CAP.CantBeBannedByUser) then return false end
    return not (Adm.RANK_GUARD and b.byPos and rank(r) > b.byPos)
end

-- the server's own Steam ID for a player, as a Lua number. IsoPlayer.getSteamID is a long and Lua holds it as a double, so
-- about 16 IDs share one number. 0 or nothing: not a Steam server
local function sidNum(o)
    local real = o and o:getSteamID()
    if type(real) ~= "number" then real = tonumber(tostring(real)) end
    if not real or real == 0 then return nil end
    return real
end

-- the row that keeps this player out now: any ban on their name, or on a Steam ID that is the server's own number for them,
-- whatever their client claims. A permanent ban the game holds should have kept them from logging in at all, so one that finds
-- them here did not take. The game's login matches names in any case, so these do too
local function standingFor(md, user, real)
    local low = string.lower(user)
    for _, b in pairs(md.bans) do
        if (b.user and string.lower(b.user) == low) or (real and b.sid and tonumber(b.sid) == real) then return b end
    end
    return nil
end

-- any row for this name or Steam ID: the game holds one ban per user, so a second row would only lie
local function rowFor(md, user, sid, ip)
    local low = user and string.lower(user) or nil
    for _, b in pairs(md.bans) do
        if (low and b.user and string.lower(b.user) == low) or (sid and b.sid == sid) or (ip and b.ip == ip) then return b end
    end
    return nil
end

local function okUser(s) return type(s) == "string" and #s >= 1 and #s <= AL.TARGET_MAX and Tk.name(s) == s end

-- the name as this server spells it: online, then remembered, in any case; nil for a name it has never met
local function knownName(md, s)
    if Srv.player(s) or md.players[s] then return s end
    local low = string.lower(s)
    local found = nil
    Srv.eachOnline(function(o)
        if not found and string.lower(o:getUsername()) == low then found = o:getUsername() end
    end)
    if found then return found end
    for u in pairs(md.players) do
        if string.lower(u) == low then return u end
    end
    return nil
end

-- the player online under this name in any case (the game's login matches names in any case), or nil
local function onlineAs(user)
    if type(user) ~= "string" then return nil end
    local low, found = string.lower(user), nil
    Srv.eachOnline(function(o)
        if not found and string.lower(o:getUsername()) == low then found = o end
    end)
    return found
end

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

-- what the server reads of a player: their profession, traits and skills, at the moment of asking.
-- The names are in the server's language (a dedicated server's is English), so the ids go too: profId, traitIds (in
-- step with traits) and each skill's id. The viewer's client looks the game's own names up from them in its language.
local function readPlayer(o, all)
    local out = { traits = {}, traitIds = {}, skills = {} }
    local d = o:getDescriptor()
    local prof = d and d:getCharacterProfession()
    local def = prof and CharacterProfessionDefinition.getCharacterProfessionDefinition(prof)
    if def then out.prof, out.profId = def:getUIName(), tostring(prof) end   -- (tostring: "base:farmer")
    local known = o:getCharacterTraits():getKnownTraits()
    for i = 0, known:size() - 1 do
        local tr = CharacterTraitDefinition.getCharacterTraitDefinition(known:get(i))
        if tr then
            out.traits[#out.traits + 1] = tr:getLabel()
            out.traitIds[#out.traits] = tostring(known:get(i))
        end
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

-- what the player's own screen gets: no name of who banned them. hold: a game call must land while they are still on. The
-- appeal line goes with it (ZeD_ServerCommunity.lua): a banned player's client may never have heard it
local function leaveView(b)
    return { kind = "ban", reason = b.reason, untilT = b.untilT, hold = (b.banIp and not b.made) and true or nil,
        appeal = Srv.appealLine and Srv.appealLine() or nil }
end

local function banRows(md)
    local rows = {}
    for _, b in pairs(md.bans) do rows[#rows + 1] = banRow(b) end
    table.sort(rows, function(x, y) return x.id > y.id end)
    return rows
end

local function pushBans(md)
    local rows = banRows(md)
    Srv.eachOnline(function(o)
        if Srv.can(o, CAP.BanUnbanUser) then Srv.to(o, Adm.MOD, "a_bans", { rows = rows }) end
    end)
end

local function noteStaff(args)
    Srv.eachOnline(function(o)
        if Srv.can(o, CAP.BanUnbanUser) then Srv.to(o, Adm.MOD, "a_note", args) end
    end)
end

-- p: who is asking. Their tickets are staff's (the AnswerTickets capability), and the place of a role above theirs stays its own
local function cardView(md, user, p)
    local o = Srv.player(user)
    local rec = md.players[user]
    -- an account that is off shows only to a role with the game's power for the full list, as in a_players. Guarded the
    -- same way: a game without the power shows no one who is off
    local closed = false
    if not o then
        local allCap = Capability and Capability.SeeNetworkUsers
        closed = not (allCap and Srv.can(p, allCap))
    end
    -- (closed, the saved record stays here, whether there is one or not; the card says which power it takes)
    if closed then rec = nil end
    local v = { user = user, on = o ~= nil, muted = md.mutes[string.lower(user)] ~= nil, last = rec and rec.t or nil }
    if closed then v.closed = true end
    if o then
        local r = readPlayer(o, true)
        v.prof, v.traits, v.skills = r.prof, r.traits, r.skills
        v.profId, v.traitIds = r.profId, r.traitIds
        v.role = roleName(o)
        if Adm.RANK_GUARD and rank(o:getRole()) > rank(p:getRole()) then
            v.hidden = true
        else
            v.x, v.y, v.z = math.floor(o:getX()), math.floor(o:getY()), math.floor(o:getZ())
            v.oid = o:getOnlineID()
        end
    elseif rec then
        v.prof, v.traits, v.skills, v.role = rec.prof, listCopy(rec.traits), skillsCopy(rec.skills), rec.role
        v.profId, v.traitIds = rec.profId, listCopy(rec.traitIds)   -- (nil and {} on a record kept before the ids were)
    end
    if Srv.ticketsOf and Srv.can(p, Srv.CAP_STAFF) then v.tickets, v.ticketN = Srv.ticketsOf(user, AL.TICKETS_ROWS) end
    -- (closed, a ban would tell that the name is a real account: it goes only to a role that reads the bans, as a_bans)
    local b = rowFor(md, user)
    if b and (not closed or Srv.can(p, CAP.BanUnbanUser)) then v.banId, v.banUntil = b.id, b.untilT end
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
-- act: Ban (user, reason), BanIP (user, reason, online only), BanSteamID (target, reason), BanIPOnly (target), Kick (user,
-- reason), UnBan (user), UnBanIP (user), UnBanSteamID (target), UnBanIPOnly (target), VoiceBan (user, on only: the game's
-- /voiceban needs them on). at: not before this second.
-- opts: banId, the ban it belongs to; after, the id of a call that goes first
local GAME_BAN = { Ban = true, BanSteamID = true, BanIPOnly = true }
local ON_SID = { BanSteamID = true, UnBanSteamID = true }

-- the calls that give way when the table is full: a Kick is asked again on the next stay, a VoiceBan holds for one session
-- only (a dropped one waits for their next session). Neither may crowd out a ban or an unban
local GIVES_WAY = { Kick = true, VoiceBan = true }

local function owedRoom(md)
    local n, soft = 0, 0
    for _, e in pairs(md.owed) do
        n = n + 1
        if GIVES_WAY[e.act] then soft = soft + 1 end
    end
    return AL.OWED_MAX - n + soft
end

-- a command that can be refused asks owedRoom first; past the cap a Kick or a VoiceBan goes, the oldest, and a ban or an
-- unban never does
local function owe(md, act, target, reason, delay, by, opts)
    local n, low = 0, nil
    for id, e in pairs(md.owed) do
        n = n + 1
        if GIVES_WAY[e.act] and (not low or id < low) then low = id end
    end
    if n >= AL.OWED_MAX and low then
        Srv.adminLog(Tk.SYS, "owed game calls full", md.owed[low].target, "dropped a " .. tostring(md.owed[low].act))
        md.owed[low] = nil
    end
    local id = md.nextOwe
    md.nextOwe = id + 1
    opts = opts or {}
    md.owed[id] = { id = id, act = act, target = target, reason = reason, at = getTimestamp() + (delay or 0), by = by,
        banId = opts.banId, after = opts.after, why = opts.why, n = opts.n }
    return id
end

-- a Kick for this name, unless one already waits. opts: banId, or why = "rules"; n, how many times it was asked before
local function oweKick(md, user, reason, opts)
    local low = string.lower(user)
    for _, e in pairs(md.owed) do
        if e.act == "Kick" and string.lower(tostring(e.target)) == low then return nil end
    end
    return owe(md, "Kick", user, reason or "", 0, nil, opts)
end

local function owedCap(act) if act == "Kick" then return CAP.KickUser end return CAP.BanUnbanUser end

-- every call owed for this ban, gone. True when a game ban among them had already been sent out
local function cancelOwed(md, banId)
    local sent = false
    local out = {}
    for id, e in pairs(md.owed) do
        if e.banId == banId then
            out[#out + 1] = id
            if e.sent and (GAME_BAN[e.act] or e.act == "BanIP") then sent = true end
        end
    end
    for _, id in ipairs(out) do md.owed[id] = nil end
    return sent
end

-- what lifting a ban owes the game: nothing, unless the game's ban was made or may have been. A Steam ID the game was given is
-- lifted with the name, or it would keep every account on it out; a Steam ID only matched, never given, is not touched
local function undoGame(md, b, by)
    local sent = cancelOwed(md, b.id)
    if not (b.made or b.everMade or sent or b.ipSent) then return end   -- (everMade: a round reOwe asked again may have half taken)
    if b.user then owe(md, b.banIp and "UnBanIP" or "UnBan", b.user, "", 0, by) end
    local lift = b.sidGame or b.sidLift
    if lift then owe(md, "UnBanSteamID", lift, "", 0, by) end
    if not (b.user or b.sid) then owe(md, "UnBanIPOnly", b.ip, "", 0, by) end
end

-- the game keeps no IP ban here: it needs the player on, and not on a Steam connection (BanSystem.BanUserByIP)
local function ipRefused(md, b)
    if not (b and b.banIp) then return end
    b.banIp = nil
    Srv.adminLog(Tk.SYS, "ip ban not made", b.user, "the plain ban stands")
    noteStaff({ kind = "ipfail", user = b.user })
    pushBans(md)
end

-- a call that no longer stands: the words for the log, or nil
local function owedStale(md, e, b)
    if e.banId and not b then return "its ban is gone" end
    if e.why == "rules" and not (Srv.rulesUnanswered and Srv.rulesUnanswered(e.target)) then return "the rules were answered" end
    if e.act == "VoiceBan" and not md.mutes[string.lower(tostring(e.target))] then return "they were unmuted" end
    local r = e.by and roleOf(md, e.by) or nil
    if r and not r:hasCapability(CAP.BanUnbanUser) then return "its author lost the power" end
    if b and b.user and not bindsRole(b, roleOf(md, b.user)) then return "its target's role is above it" end
    return nil
end

-- never the target of the call, and never someone a gate shuts out (a ban, the join rules unanswered)
local function mayCall(md, o, e, cap)
    local user = o:getUsername()
    local rec = md.players[user]
    if not Srv.can(o, cap) then return false end
    if ON_SID[e.act] then
        if rec and rec.sid == e.target then return false end
        local real = sidNum(o)
        if real and tonumber(e.target) == real then return false end
    elseif string.lower(user) == string.lower(tostring(e.target)) then
        return false
    end
    return Srv.gated(o, Adm.MOD, "a_done") == nil
end

-- the host helper first, when it is on and its allow-list takes the call: it goes in the helper's queue and stays there until
-- answered. A staff client gets it too once the helper has not answered in HELPER_WAIT_S, has failed or refused it or is not
-- running. True when the helper holds it for now
local function toHelper(e, now)
    local H = Srv.H
    if not (H and H.on()) or e.noHelper or not H.can(e) then return false end
    -- (never handed to a helper not known to be running: until it has answered once this start, staff clients make the calls)
    if not H.alive(now) then return false end
    if not e.helper then
        e.helper, e.try, e.helperAt = true, 1, now
        e.sent = now
        return true
    end
    if e.helperFailed then
        -- (a staff client may take it meanwhile; the helper's next try waits HELPER_WAIT_S, so a console it cannot reach
        -- costs one try a call every half minute, never one every pass)
        if now - (e.failedAt or 0) < AL.HELPER_WAIT_S then return false end
        e.try, e.helperFailed, e.failedAt, e.helperAt = (e.try or 1) + 1, nil, nil, now
        e.sent = now
        return true
    end
    if H.alive(now) and now - (e.helperAt or 0) < AL.HELPER_WAIT_S then
        e.sent = now
        return true
    end
    return false
end

-- to the one who asked if they are on, else any staff member with the power; the one sent to is the one who may answer
local function deliver(md, e, b, now)
    if toHelper(e, now) then return end
    local cap = owedCap(e.act)
    local who = e.by and Srv.player(e.by)
    if not (who and mayCall(md, who, e, cap)) then
        who = nil
        Srv.eachOnline(function(o) if not who and mayCall(md, o, e, cap) then who = o end end)
    end
    if not who then return end
    e.sent, e.sentTo = now, who:getUsername()
    if b and e.act == "BanIP" then b.ipSent = true end
    Srv.to(who, Adm.MOD, "a_owed", { id = e.id, act = e.act, target = e.target, reason = e.reason })
end

local function sendOwed(md, now)
    local ids = {}
    for id in pairs(md.owed) do ids[#ids + 1] = id end
    table.sort(ids)                  -- (in the order they were owed: a Ban after its IP call, an unban after a ban)
    for _, id in ipairs(ids) do
        local e = md.owed[id]
        local behind = e.after ~= nil and md.owed[e.after] ~= nil
        if now >= e.at and not behind and (not e.sent or now - e.sent >= AL.OWED_RETRY_S) then
            local b = e.banId and md.bans[e.banId] or nil
            local stale = owedStale(md, e, b)
            local gone = not Srv.player(e.target)
            if stale then
                md.owed[id] = nil
                Srv.adminLog(Tk.SYS, "game call dropped", e.target, e.act .. ": " .. stale)
            elseif (e.act == "Kick" or e.act == "VoiceBan") and gone then
                md.owed[id] = nil    -- (they went on their own: a kick now would only add to their record; a voice ban is owed
                                     -- again when they are next on)
            elseif e.act == "BanIP" and gone then
                md.owed[id] = nil
                if not e.sent then ipRefused(md, b) end   -- (sent, and gone: that was the game's kick)
            else
                if e.act == "Ban" and b and b.ipSent and not gone then ipRefused(md, b) end   -- (the IP call would have kicked them)
                deliver(md, e, b, now)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- DID THE GAME'S CALL TAKE? A client's "done" only says it made the call without a Lua error
-- ---------------------------------------------------------------------------
-- the game's own list, read back: true or false for a Steam ID, nil when it cannot be read (NetworkUser.isSteamIdBanned is a
-- read-only SELECT on the server's ban table; one overload, a String). The game catches its own database errors and answers
-- null, the same as "not banned": so a false proves nothing alone, and a lift is read twice, OFF_GAP_S apart (readParts)
local function gameHoldsSid(sid)
    if type(sid) ~= "string" or not NetworkUser then return nil end
    local ok, r = pcall(function() return NetworkUser.new():isSteamIdBanned(sid) end)
    if not ok then return nil end
    return r ~= nil
end

-- the game's IP ban on a name, read back the same way: true or false, nil when it cannot be read
-- (NetworkUser.getFirstBannedIPForUser: a read-only SELECT ip FROM bannedip WHERE username = ?; one overload, a String)
local function gameHoldsIp(user)
    if type(user) ~= "string" or not NetworkUser then return nil end
    local ok, r = pcall(function() return NetworkUser.new():getFirstBannedIPForUser(user) end)
    if not ok then return nil end
    return r ~= nil
end

-- the game's ban did not take: asked for again, REOWE_MAX times, each with a line. After that the row still keeps them out
-- (the leave screen, the Kick on a stay) and the log says the game's ban is not holding
local function reOwe(md, b, why)
    for _, e in pairs(md.owed) do
        if e.banId == b.id and GAME_BAN[e.act] then return end     -- (one still waits: nothing to judge yet)
    end
    b.nameSeen = nil         -- (a new round: what the game's list said of the last one proves nothing)
    local who = b.user or b.sid
    if (b.reowe or 0) >= AL.REOWE_MAX then
        if not b.gaveUp then
            b.gaveUp = true
            Srv.adminLog(Tk.SYS, "game ban did not take", who, why .. "; asked " .. tostring(b.reowe) .. " times, the row still keeps them out")
        end
        return
    end
    b.reowe = (b.reowe or 0) + 1
    b.made, b.madeAt = nil, nil
    Srv.adminLog(Tk.SYS, "game ban did not take", who, why .. "; asked again, " .. tostring(b.reowe) .. " of " .. tostring(AL.REOWE_MAX))
    local first = nil
    if b.user then first = owe(md, "Ban", b.user, b.reason, 0, nil, { banId = b.id }) end
    if b.sidGame then owe(md, "BanSteamID", b.sidGame, b.reason, 0, nil, { banId = b.id, after = first }) end
end

-- an unban by Steam ID the game says did not take (its list, read back, still holds the ID): asked again, REOWE_MAX times, each
-- with a line; never while a row of ours bans that ID again
local function reOweUnban(md, e)
    for _, b in pairs(md.bans) do
        if b.sidGame == e.target then return end
    end
    local n = e.n or 0
    if n >= AL.REOWE_MAX then
        Srv.adminLog(Tk.SYS, "game unban did not take", e.target, "the Steam ID is still on the game's list; asked " .. tostring(n) .. " times")
        return
    end
    Srv.adminLog(Tk.SYS, "game unban did not take", e.target, "the Steam ID is still on the game's list; asked again, " .. tostring(n + 1) .. " of " .. tostring(AL.REOWE_MAX))
    owe(md, "UnBanSteamID", e.target, "", 0, e.by, { n = n + 1 })
end

-- a call is done: by the staff client it went to, or by the host helper
local function doneOwed(md, e, now)
    md.owed[e.id] = nil
    local b = e.banId and md.bans[e.banId] or nil
    if b and GAME_BAN[e.act] then
        b.made, b.madeAt, b.everMade = true, now, true
        if e.act == "BanSteamID" then
            local held = gameHoldsSid(e.target)
            if held == false then reOwe(md, b, "the Steam ID is not on the game's list") end
            if held == true then b.sidHeld, b.sidOffAt = true, nil end
        end
        -- (a name ban: a staff client looks at the game's user list soon, and the role it reads there is the proof it held)
        if e.act == "Ban" then T.lookedAt[b.id] = now - AL.LOOK_EVERY_S + AL.LOOK_SETTLE_S end
    end
    -- the game's IP ban read back on its list for the name: what a later read without it is judged against (readParts). Never
    -- proof of the name's ban: an IP row can outlast an unban (a Steam server's unban leaves the game's IP list alone)
    if b and e.act == "BanIP" and b.user and gameHoldsIp(b.user) == true then b.ipHeld, b.ipOffAt = true, nil end
    if e.act == "UnBanSteamID" and gameHoldsSid(e.target) == true then reOweUnban(md, e) end
    if e.act == "BanIP" then
        local at = now + AL.IP_GAP_S
        for _, other in pairs(md.owed) do
            if other.after == e.id then other.at = at end
        end
    end
    if e.act == "Kick" then
        T.kicked[string.lower(tostring(e.target))] = { user = e.target, at = now, n = e.n or 0, reason = e.reason, banId = e.banId, why = e.why }
    end
end

-- ---------------------------------------------------------------------------
-- THE TIMED BANS
-- ---------------------------------------------------------------------------
local function tellLeave(o, b, now)
    T.told[o:getUsername()] = { at = now, id = b.id }
    Srv.to(o, Adm.MOD, "a_leave", leaveView(b))
end

-- the ban is off: whoever was told to leave stays
local function release(b)
    for user, told in pairs(T.told) do
        if told.id == b.id then
            T.told[user] = nil
            local o = Srv.player(user)
            if o then Srv.to(o, Adm.MOD, "a_stay", {}) end
        end
    end
end

-- a banned client still here: staff are told, it is written on the ban, and a Kick is owed (each stay, not only at the ban)
local function reportStay(md, user, b, told, now)
    told.noted = now
    b.stay, b.stayUser = now, user
    Srv.adminLog(Tk.SYS, "a banned client has not left", user)
    noteStaff({ kind = "stay", user = user, id = b.id })
    oweKick(md, user, b.reason, { banId = b.id })
end

-- ---------------------------------------------------------------------------
-- THE GAME'S UNBAN WINS: staff who lift a ban in the game's own admin panel or with /unbanuser
-- have lifted it. ZeD closes its row, owes no ban again, gates no more, and says so in the log. Only on the game's own word
-- that it held the ban and holds it no more, never on a login, a leaving or a client's "done":
--   a Steam ID  the game's list (isSteamIdBanned) read with it after the ban, then twice without it, OFF_GAP_S apart
--   a name      the game keeps a name ban as the account's role, which server Lua cannot read (ServerWorldDatabase is not
--               exposed). The game sends its whole user list, each account's role from its own database, to any client with
--               SeeNetworkUsers (RequestNetworkUsersPacket, NetworkUsersPacket, getWhitelistUsers). So a staff client who can
--               also lift bans looks there and answers (a_look, a_looked): trusting it adds no power it does not have. The
--               role read as "banned" proves the ban held; a later look, asked LIFT_FRESH_S or more after, reading another
--               role proves it was lifted. A name missing from the list, or not from the game's database (inWhitelist
--               false), proves nothing
--   an IP       the game's list for the name (getFirstBannedIPForUser) read with it, then twice without it: only the IP part
--               goes (the game's unban of another account on that IP clears it as well: banIp deletes by the IP), the row
--               and its name ban stay
-- Closing lifts nothing in the game: what the game still holds of the row is named in the log line, for staff to lift. A row
-- with no such word stays as it was.
-- ---------------------------------------------------------------------------
local CAP_LOOK = Capability and Capability.SeeNetworkUsers     -- (nil in a game without it: no looks, name rows stay as they are)

-- the row closes on the game's word. Nothing is lifted or owed; whoever was told to leave stays. via: the staff client whose
-- look at the game's user list said so (a_looked), named on the line (its field via)
local function closeLifted(md, b, how, via)
    cancelOwed(md, b.id)
    md.bans[b.id] = nil
    T.hold[b.id], T.lookedAt[b.id] = nil, nil
    release(b)
    local still = {}
    if b.user and b.banIp and gameHoldsIp(b.user) == true then still[#still + 1] = "its IP" end
    if b.sidLift and gameHoldsSid(b.sidLift) == true then still[#still + 1] = "its Steam ID" end
    if #still > 0 then how = how .. "; the game still holds " .. table.concat(still, " and ") end
    -- (the game tells server Lua nothing of who: its own user log names them, and only a client can ask for that)
    if via then how = how .. "; seen by " .. via end
    Srv.action("admin", Tk.SYS, "ban lifted in the game", b.user or b.sid or b.ip, "lifted in the game: " .. how, nil, nil, nil,
        via and { via = via } or nil)
    pushBans(md)
end

-- a part the game's list held, read again: true when it reads off a second time, OFF_GAP_S or more after the first. A read
-- that finds it starts over; one that cannot be read changes nothing
local function offTwice(b, field, held, now)
    if held == true then
        b[field] = nil
        return false
    end
    if held ~= false then return false end
    if not b[field] then
        b[field] = now
        return false
    end
    return now - b[field] >= AL.OFF_GAP_S
end

-- the Steam ID and IP parts read back: "closed" (the row went), "wait" (a Steam ID read off once, its second read not due), or
-- nil
local function readParts(md, b, now)
    if b.sidHeld and b.sidGame then
        if offTwice(b, "sidOffAt", gameHoldsSid(b.sidGame), now) then
            closeLifted(md, b, "the Steam ID is off the game's list")
            return "closed"
        end
        if b.sidOffAt then return "wait" end
    end
    if b.ipHeld and b.banIp and b.user and offTwice(b, "ipOffAt", gameHoldsIp(b.user), now) then
        b.banIp, b.ipHeld, b.ipOffAt = nil, nil, nil
        Srv.adminLog(Tk.SYS, "ip ban lifted in the game", b.user, "the IP is off the game's list; the ban on the name stands")
        pushBans(md)
    end
    return nil
end

-- the rows whose Steam ID or IP the game held, a few each walk (each read is a query on the game's database): one lifted in
-- the game while its player is off closes too, so the Bans card is right before they come back
local function lookLifted(md, now)
    local ids = {}
    for id, b in pairs(md.bans) do
        if (b.sidHeld or (b.ipHeld and b.banIp)) and (not T.liftCursor or id > T.liftCursor) then ids[#ids + 1] = id end
    end
    if #ids == 0 then
        T.liftCursor = nil
        return
    end
    table.sort(ids)
    for i = 1, math.min(#ids, AL.LIFT_LOOK_N) do
        T.liftCursor = ids[i]
        local b = md.bans[ids[i]]
        if b then readParts(md, b, now) end
    end
end

-- a game ban for this row still owed: the game's state is moving, and no look proves a lift
local function banOwed(md, b)
    for _, e in pairs(md.owed) do
        if e.banId == b.id and GAME_BAN[e.act] then return true end
    end
    return false
end

-- who may look at the game's user list for these names (lower case -> anything): on, with the game's powers to see it and to
-- lift a ban, shut out by no gate, and none of the names
local function looker(md, names)
    if not CAP_LOOK then return nil end
    local who = nil
    Srv.eachOnline(function(o)
        if not who and not names[string.lower(o:getUsername())] and Srv.can(o, CAP_LOOK) and Srv.can(o, CAP.BanUnbanUser)
            and Srv.gated(o, Adm.MOD, "a_looked") == nil then who = o end
    end)
    return who
end

-- one look at a time, LOOK_GAP_S apart at least: the names of held rows whose player is on first, then each name row in turn,
-- LOOK_EVERY_S apart
local function runLooks(md, now)
    local cur = T.look
    if cur and now - cur.at < AL.LOOK_WAIT_S then return end
    T.look = nil
    if not CAP_LOOK or (T.lookAt and now - T.lookAt < AL.LOOK_GAP_S) then return end
    local first, rest = {}, {}
    for id, b in pairs(md.bans) do
        if b.user and (b.made or b.everMade or b.nameSeen) then
            local h = T.hold[id]
            if h and not h.done then
                first[#first + 1] = id
            elseif now - (T.lookedAt[id] or 0) >= AL.LOOK_EVERY_S then
                rest[#rest + 1] = id
            end
        end
    end
    if #first + #rest == 0 then return end
    T.lookAt = now
    table.sort(first)
    table.sort(rest, function(x, y)
        local ax, ay = T.lookedAt[x] or 0, T.lookedAt[y] or 0
        if ax ~= ay then return ax < ay end
        return x < y
    end)
    local names, list = {}, {}
    for _, src in ipairs({ first, rest }) do
        for _, id in ipairs(src) do
            local low = string.lower(md.bans[id].user)
            if #list < AL.LOOK_N and not names[low] then
                names[low] = id
                list[#list + 1] = md.bans[id].user
            end
        end
    end
    local o = looker(md, names)
    if not o then return end
    T.lookN = (T.lookN or 0) + 1
    for _, id in pairs(names) do T.lookedAt[id] = now end
    T.look = { id = T.lookN, to = o:getUsername(), at = now, names = names }
    Srv.to(o, Adm.MOD, "a_look", { id = T.lookN, names = list })
end

-- a held name ban's player found on. The game's login let them in, which proves nothing, but the game's unban may have: their
-- re-ban and leave screen wait up to LOOK_HOLD_S for a look at the game's list (every ZeD command stays shut meanwhile). With no
-- staff client to look, or once a look answered, as before
local function holdForLook(md, b, user, now)
    local h = T.hold[b.id]
    if not h then
        if not looker(md, { [string.lower(b.user)] = true }) then return false end
        T.hold[b.id] = { at = now, user = user }
        return true
    end
    if h.done then return false end
    if now - h.at >= AL.LOOK_HOLD_S then
        h.done = true
        return false
    end
    return true
end

local function checkBan(md, o, user, now)
    local b = standingFor(md, user, sidNum(o))
    if b and not bindsRole(b, o:getRole()) then
        if not b.noBind then
            b.noBind = true
            Srv.adminLog(Tk.SYS, "ban does not bind", user, "their role is above the one who made it")
        end
        b = nil
    end
    if not b then
        T.told[user] = nil
        return
    end
    -- (the game's unban wins, on its own word: a Steam ID lifted there closes the row; a name the game held waits for a look)
    local parts = readParts(md, b, now)
    if parts == "closed" then
        T.told[user] = nil
        return
    end
    if parts == "wait" then return end
    if b.user and b.nameSeen and string.lower(b.user) == string.lower(user) and holdForLook(md, b, user, now) then return end
    -- (the game's ban should have kept them from logging in, or kicked them when it was made)
    if b.made and now - (b.madeAt or 0) >= AL.VERIFY_S then reOwe(md, b, "they are still on") end
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
        undoGame(md, b, nil)         -- (the clock's own act: no author to lose the power)
        md.bans[id] = nil
        T.hold[id], T.lookedAt[id] = nil, nil
        release(b)
        Srv.adminLog(Tk.SYS, "ban lifted", b.user or b.sid, "the time ran out")
    end
end

-- rows made before this build, brought up to it at every load of the table (never a frozen one: open() asks first).
--   v 2: the Steam ID the game is given is only one staff typed (sidGame). A name's row kept its player's client's word in sid,
--        and beta 7 named it to the game too: that is never asked for again (a pending call for it goes), and one that may have
--        gone is still lifted with the row (sidLift), as it was made
--   a standing timed row without the game's ban (beta 7 made timed bans ZeD's alone) owes the game's ban now, as a new one
--   does, so the old bans hold too: the name, the typed Steam ID. Never the IP: that needs the player on
function Srv.upgradeBans(md)
    local now = getTimestamp()
    local ids = {}
    for id in pairs(md.bans) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local b = md.bans[id]
        b.nameHeld = nil             -- (an earlier build's proof of a name ban, from a leaving: never the game's word)
        if not b.v then
            b.v = 2
            if b.sid and not b.user then
                b.sidGame = b.sid
            elseif b.sid then
                local sent = false
                for oid, e in pairs(md.owed) do
                    if e.banId == id and e.act == "BanSteamID" then
                        if e.sent then sent = true end
                        md.owed[oid] = nil
                    end
                end
                if sent or (not b.untilT and (b.made or b.everMade)) then b.sidLift = b.sid end
            end
        end
        if b.untilT and b.untilT > now and not b.gameBan then
            local first = nil
            if b.user then first = owe(md, "Ban", b.user, b.reason, 0, nil, { banId = id }) end
            if b.sidGame then owe(md, "BanSteamID", b.sidGame, b.reason, 0, nil, { banId = id, after = first }) end
            if b.user or b.sidGame then
                b.gameBan = true
                Srv.adminLog(Tk.SYS, "game ban owed", b.user or b.sidGame, "a timed ban from before this build: the game's ban holds it too")
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- THE CLOCK: OnTickEvenPaused fires with nobody on, and getTimestamp is real time
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
        rec.profId, rec.traitIds = r.profId, r.traitIds
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

-- a Kick the game was asked for, and the player still on past VERIFY_S: asked again while its reason holds, REOWE_MAX times
local function checkKicks(md, now)
    local done = nil
    for low, k in pairs(T.kicked) do
        if now - k.at >= AL.VERIFY_S then
            done = done or {}
            done[#done + 1] = low
            local o = Srv.player(k.user)
            local holds = false
            if o and k.banId then
                local b = md.bans[k.banId]
                holds = b ~= nil and standingFor(md, k.user, sidNum(o)) == b and bindsRole(b, o:getRole())
            elseif o and k.why == "rules" then
                holds = Srv.rulesUnanswered ~= nil and Srv.rulesUnanswered(k.user) == true
            end
            if holds then
                if k.n + 1 <= AL.REOWE_MAX then
                    Srv.adminLog(Tk.SYS, "kick did not take", k.user, "asked again, " .. tostring(k.n + 1) .. " of " .. tostring(AL.REOWE_MAX))
                    oweKick(md, k.user, k.reason, { banId = k.banId, why = k.why, n = k.n + 1 })
                else
                    Srv.adminLog(Tk.SYS, "kick did not take", k.user, "asked " .. tostring(k.n) .. " times")
                end
            end
        end
    end
    for _, low in ipairs(done or {}) do T.kicked[low] = nil end
end

local function walkPlayers(md, now)
    local seen, on = {}, {}
    local list = getOnlinePlayers()
    for i = 0, list:size() - 1 do
        local o = list:get(i)
        local user = o:getUsername()
        seen[user] = true
        snap(md, o, user, now)
        checkBan(md, o, user, now)
        -- a muted player on: the game's voice ban, once a session (it holds for the connection only, and /voiceban needs them
        -- on). One muted while they were off gets it here, from the next staff client or the host helper
        local low = string.lower(user)
        on[low] = true
        if md.mutes[low] and not T.voiced[low] then
            T.voiced[low] = true
            owe(md, "VoiceBan", user, "", 0, md.mutes[low])
        end
    end
    for u in pairs(T.told) do
        if not seen[u] then T.told[u] = nil end
    end
    for low in pairs(T.voiced) do
        if not on[low] then T.voiced[low] = nil end
    end
    for id, h in pairs(T.hold) do
        if not seen[h.user] then T.hold[id] = nil end      -- (gone: their next login is held again)
    end
    T.seen = seen
    trimPlayers(md)
    checkKicks(md, now)
    lookLifted(md, now)
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
local function applyWatch(md, user, o, w)
    for _, id in ipairs(w.off) do
        if id == "Invisible" then o:setGhostMode(false)
        elseif id == "NoClip" then o:setNoClip(false)
        elseif id == "GodMod" then o:setGodMod(false) end
    end
    if #w.off > 0 then Srv.to(o, Adm.MOD, "a_powersoff", { ids = w.off }) end
    md.watch[user] = nil
end

local function runWatch(md, now)
    local done = nil
    for user, w in pairs(md.watch) do
        local o = Srv.player(user)
        if o and not w.hi and roleName(o) == w.role then
            done = done or {}
            done[#done + 1] = { user, o, w }
        elseif now - w.at >= (o and AL.ROLE_WATCH_S or AL.ROLE_WATCH_KEEP_S) and not (o and w.hi) then
            md.watch[user] = nil
        end
    end
    for _, d in ipairs(done or {}) do applyWatch(md, d[1], d[2], d[3]) end
end

-- a call the helper failed: one log line every HELPER_LOG_S at most, counting the ones it held back, so a console the helper
-- cannot reach never floods the log ring
local function helperFailLine(e, text, now, last)
    T.helperFails = (T.helperFails or 0) + 1
    if T.helperFailAt and now - T.helperFailAt < AL.HELPER_LOG_S then return end
    T.helperFailAt = now
    local more = T.helperFails - 1
    T.helperFails = 0
    local note = e.act .. ": " .. tostring(text)
    if last then note = note .. "; tried " .. tostring(e.try or 1) .. " times, staff only now" end
    if more > 0 then note = note .. " (and " .. tostring(more) .. " more since the last line)" end
    Srv.adminLog(Tk.SYS, "host helper failed", e.target, note)
end

-- the host helper: its answers read, its queue written, every HELPER_POLL_S
local function runHelper(md, now)
    local H = Srv.H
    if not (H and H.on()) then return end
    if T.helperAt and now - T.helperAt < AL.HELPER_POLL_S then return end
    T.helperAt = now
    local ok, list = pcall(H.read, md)
    if not ok then
        if not T.helperErr then
            T.helperErr = true
            Srv.adminLog(Tk.SYS, "host helper", nil, "its answers could not be read: " .. tostring(list))
        end
        list = nil
    end
    for _, a in ipairs(list or {}) do
        local e = md.owed[a.id]
        if e and e.helper then
            if a.res == "ok" or (a.res == "gone" and (e.act == "Kick" or e.act == "VoiceBan")) then
                doneOwed(md, e, now)
            elseif a.try == e.try and not e.helperFailed and not e.noHelper then
                if a.res == "refused" then
                    e.noHelper, e.helper, e.sent = true, nil, nil
                    Srv.adminLog(Tk.SYS, "host helper refused", e.target, e.act .. ": " .. tostring(a.text))
                elseif (e.try or 1) >= AL.HELPER_TRIES then
                    e.noHelper, e.helper, e.sent = true, nil, nil      -- (tried enough: staff clients only from here)
                    helperFailLine(e, a.text, now, true)
                else
                    e.helperFailed, e.failedAt, e.sent = true, now, nil
                    helperFailLine(e, a.text, now, false)
                end
            end
        end
    end
    local wok, err = pcall(H.write, md)
    if not (wok and err) and not T.helperWriteErr then
        T.helperWriteErr = true
        Srv.adminLog(Tk.SYS, "host helper", nil, "its queue could not be written: " .. tostring(err))
    end
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
    runWatch(md, now)
    runLooks(md, now)
    sendOwed(md, now)
    runHelper(md, now)
end

-- ---------------------------------------------------------------------------
-- THE COMMANDS: every one takes its player from the event, and only an ack's ok lets a client make the game's call
-- ---------------------------------------------------------------------------
-- someone a ban keeps out asks for nothing anywhere in ZeD, not only here: they are on their way out, and that goes for banned
-- staff too. The hello and a_hi stay open, so their client still hears why (Srv.gates, ZeD_ServerCore.lua)
Srv.gates.ban = function(p, module, command)
    if module == Tk.MOD_LINK or (module == Adm.MOD and command == "a_hi") then return nil end
    local md = open()
    local b = standingFor(md, p:getUsername(), sidNum(p))
    if b and bindsRole(b, p:getRole()) then return "under a ban" end
    return nil
end

local function reg(command, opts, fn) Srv.register(Adm.MOD, command, opts, fn) end

-- the Steam ID a client names, when the server's own number agrees. IsoPlayer.getSteamID is a long, and server Lua only ever
-- has it as a double, which holds a Steam ID to the nearest 16. The client's true string rounds to that same double
-- (Long.doubleValue, Double.parseDouble), so the two must be equal: that leaves about 16 IDs around their own, and nothing
-- here can tell those apart. 0 or nothing there: not a Steam server, and no ID stands.
local function sidOf(p, claim)
    if type(claim) ~= "string" or Adm.targetKind(claim) ~= "sid" then return nil end
    local real = p:getSteamID()
    if type(real) ~= "number" then real = tonumber(tostring(real)) end
    if not real or real == 0 or tonumber(claim) ~= real then return nil end
    return claim
end

-- the hello: the Steam ID, and the first word of a ban. A client already told is told again but its clock runs on, or a
-- client that stayed could put off the stay note for good by saying hello.
reg("a_hi", { limit = Tk.LIMITS.HELLO_MS }, function(p, a, rid)
    local md = open()
    local user = p:getUsername()
    if not T.frozen then
        local now = getTimestamp()
        snap(md, p, user, now)
        local sid = sidOf(p, a.sid)
        if sid then md.players[user].sid = sid end
        local told = T.told[user]
        local b = told and md.bans[told.id] or nil
        if b then Srv.to(p, Adm.MOD, "a_leave", leaveView(b)) end
        checkBan(md, p, user, now)
        local w = md.watch[user]
        if w and w.hi then
            w.hi = nil
            if roleName(p) == w.role then applyWatch(md, user, p, w) end
        end
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
    -- offline accounts take the game's own power for the full list, so a role that sees who is
    -- connected sees no more here than in the game's window
    local off, c = {}, 0
    local allCap = Capability and Capability.SeeNetworkUsers
    if allCap and Srv.can(p, allCap) then
        for u, r in pairs(md.players) do
            if not seen[u] then
                c = c + 1
                off[c] = { u = u, on = false, role = r.role, last = r.t }
            end
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
    Srv.to(p, Adm.MOD, "a_card", cardView(open(), a.user, p))
    if rid then Srv.ack(p, rid, true) end
end)

-- the checks every act on a player shares; the target's name, or nil with the answer sent. live: an act that needs them on
local function onUser(p, a, rid, protect, allowSelf, live)
    if not okUser(a.user) then
        Srv.bad(p, "admin target")
        Srv.ack(p, rid, false, "gone")
        return nil
    end
    local md = open()
    if frozen(p, rid) then return nil end
    if live and not Srv.player(a.user) then
        Srv.ack(p, rid, false, "offline")
        return nil
    end
    local err = guard(md, p, a.user, protect, allowSelf)
    if err then
        Srv.ack(p, rid, false, err)
        return nil
    end
    return a.user, md
end

reg("a_tp", { cap = CAP.TeleportToPlayer }, function(p, a, rid)
    local user = onUser(p, a, rid, nil, false, true)
    if not user then return end
    logAt(p, "teleport to", user)
    Srv.ack(p, rid, true)
end)

reg("a_bring", { cap = CAP.TeleportPlayerToAnotherPlayer }, function(p, a, rid)
    local user = onUser(p, a, rid, nil, false, true)
    if not user then return end
    logAt(p, "teleport to you", user)
    Srv.ack(p, rid, true)
end)

reg("a_kick", { cap = CAP.KickUser }, function(p, a, rid)
    local user = onUser(p, a, rid, CAP.CantBeKickedByUser, false, true)
    if not user then return end
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
    if not okUser(a.user) then
        Srv.bad(p, "admin target")
        Srv.ack(p, rid, false, "gone")
        return
    end
    local md = open()
    if frozen(p, rid) then return end
    local user, key, on = a.user, string.lower(a.user), a.on == true
    local err = guard(md, p, user)
    if err and not (err == "unknown" and not on) then     -- (a name can come off the list whoever it was)
        Srv.ack(p, rid, false, err)
        return
    end
    if on and not md.mutes[key] then
        local n = 0
        for _ in pairs(md.mutes) do n = n + 1 end
        if n >= AL.MUTES_MAX then Srv.ack(p, rid, false, "full"); return end
    end
    if on then md.mutes[key] = p:getUsername() else md.mutes[key] = nil end
    -- the game's voice ban: on now, this client makes it with the ack (M.mute, in ZeD_Admin.lua); off, it is owed when they are next on
    -- (walkPlayers). Unmuted, one still owed goes, and an online player's client lifts it with the ack
    T.voiced[key] = (on and onlineAs(user) ~= nil) or nil
    if not on then
        for id, e in pairs(md.owed) do
            if e.act == "VoiceBan" and string.lower(tostring(e.target)) == key then md.owed[id] = nil end
        end
    end
    logAt(p, on and "mute" or "unmute", user)
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
    -- an account that is off takes the game's power for every account, as its card does.
    -- Asked before "unknown", so the answer is the same whether the name is an account or not
    if not Srv.player(a.user) then
        local allCap = Capability and Capability.SeeNetworkUsers
        if not (allCap and Srv.can(p, allCap)) then Srv.ack(p, rid, false, "perm"); return end
    end
    if not Srv.player(a.user) and not md.players[a.user] then Srv.ack(p, rid, false, "unknown"); return end
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
    md.watch[a.user] = { role = new:getName(), off = off, at = getTimestamp() }
    logAt(p, "role", a.user, new:getName())
    Srv.ack(p, rid, true)
end)

reg("a_skill", { cap = CAP.AddXP }, function(p, a, rid)
    local user = onUser(p, a, rid, nil, true, true)
    if not user then return end
    local o = Srv.player(user)
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
    Srv.to(p, Adm.MOD, "a_bans", { rows = banRows(open()) })
end)

-- room for one more row. Permanent bans the game already holds are only ZeD's note of them: the oldest goes
local function banRoom(md)
    local n, oldest = 0, nil
    for id, b in pairs(md.bans) do
        n = n + 1
        if b.made and not b.untilT and (not oldest or id < oldest) then oldest = id end
    end
    if n < AL.BANS_MAX then return true end
    if not oldest then return false end
    Srv.adminLog(Tk.SYS, "ban list full", nil, "dropped row " .. tostring(oldest) .. ", the game still holds that ban")
    md.bans[oldest] = nil
    return true
end

-- who a ban is on, and what kind. a.user comes from a row and is a username whatever it looks like. a.target is typed on
-- the Bans card: a name this server knows stays a name, then its shape decides
local function banTarget(md, a)
    if a.user ~= nil then
        if not okUser(a.user) then return nil end
        return knownName(md, a.user) or a.user, "user"
    end
    if not okUser(a.target) then return nil end
    local real = knownName(md, a.target)
    if real then return real, "user" end
    return a.target, Adm.targetKind(a.target)
end

-- what a ban owes the game. With the IP, the game's call needs the player on, so it goes first, once they have read the
-- reason; the plain ban always follows, since the game can refuse the IP and ban nobody (BanSystem.BanUserByIP).
-- A ban on a name names no Steam ID to the game: the only exact Steam ID the server has for a player is their client's word
-- (sidOf: the server's own number is a double, about 16 IDs wide), and a modified client could steer it onto a neighbor's
-- account. The row still matches the player's Steam ID on the server's own number (standingFor).
local function oweBan(md, b, target, kind, wait, me)
    local opts = { banId = b.id }
    local first = nil
    if kind == "ip" then
        owe(md, "BanIPOnly", target, b.reason, 0, me, opts)
        return
    end
    if kind == "sid" then
        owe(md, "BanSteamID", target, b.reason, 0, me, opts)
        return
    end
    if b.banIp then first = owe(md, "BanIP", target, b.reason, wait, me, opts) end
    owe(md, "Ban", target, b.reason, wait, me, { banId = b.id, after = first })
end

-- a_ban: user (a name from a row), or target (a username, Steam ID or IP, typed on the Bans card)
reg("a_ban", { cap = CAP.BanUnbanUser, limit = AL.BAN_MS, mark = false }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local target, kind = banTarget(md, a)
    local len = Adm.LENGTH[a.len]
    local reason = Adm.line(a.reason, AL.REASON_MAX)
    if not target or not kind or not len then
        Srv.bad(p, "a_ban")
        Srv.ack(p, rid, false, "text")
        return
    end
    if not reason then Srv.ack(p, rid, false, "text"); return end
    local untilT = len.sec and (getTimestamp() + len.sec) or nil
    if kind == "ip" and untilT then Srv.ack(p, rid, false, "ipperm"); return end
    local banIp = a.banIp == true and kind == "user"
    if banIp and untilT and not Adm.TIMED_IP then Srv.ack(p, rid, false, "ipperm"); return end
    local o = (kind == "user") and Srv.player(target) or nil
    if banIp and not o then Srv.ack(p, rid, false, "offline"); return end
    local err = nil
    if kind == "user" then
        err = guard(md, p, target, CAP.CantBeBannedByUser)
        -- (a name the server has never met: the game tests a permanent ban itself, and nothing would test a timed one)
        if err == "unknown" and not untilT then err = nil end
    elseif kind == "sid" then
        err = guardSid(md, p, target)
    end
    if err then Srv.ack(p, rid, false, err); return end
    local rec = (kind == "user") and md.players[target] or nil
    local sid = (kind == "sid" and target) or (rec and rec.sid) or nil
    if rowFor(md, (kind == "user") and target or nil, sid, (kind == "ip") and target or nil) then Srv.ack(p, rid, false, "already"); return end
    if owedRoom(md) < 3 or not banRoom(md) then Srv.ack(p, rid, false, "full"); return end
    Srv.mark(p, "a_ban")
    local me = p:getUsername()
    local id = md.nextBan
    md.nextBan = id + 1
    local b = { id = id, reason = reason, by = me, byPos = rank(p:getRole()), at = getTimestamp(), day = today(), untilT = untilT, banIp = banIp or nil, sid = sid, v = 2 }
    -- (the Steam ID the game is given: only one staff typed. sid is what the row matches, on the server's own number)
    if kind == "sid" then b.sidGame = target end
    if kind == "user" then b.user = target elseif kind == "ip" then b.ip = target end
    md.bans[id] = b
    local wait = o and AL.LEAVE_S or 0
    if o then tellLeave(o, b, getTimestamp()) end
    -- the game's ban, timed or not: enforced by the server at login. A timed one is lifted at its end
    -- (liftDue). Online, it waits LEAVE_S so they read the reason first; the game's ban kicks them, so no Kick goes with it
    oweBan(md, b, target, kind, wait, me)
    if untilT then b.gameBan = true end
    logAt(p, "ban", target, (untilT and (tostring(a.len) .. ": ") or "permanent: ") .. reason)
    Srv.ack(p, rid, true, nil, { id = id, untilT = untilT, unknown = (kind == "user" and not rec and not o) or nil })
    pushBans(md)
end)

-- a_unban: id (ZeD's record), or user, sid or ip for a ban only the game holds, each named for what it is
reg("a_unban", { cap = CAP.BanUnbanUser, limit = AL.BAN_MS, mark = false }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local me = p:getUsername()
    local mine = md.players[me]
    if owedRoom(md) < 2 then Srv.ack(p, rid, false, "full"); return end
    if Tk.whole(a.id) then
        local b = md.bans[a.id]
        if not b then Srv.ack(p, rid, false, "gone"); return end
        if b.user == me or (b.sid and mine and mine.sid == b.sid) then Srv.ack(p, rid, false, "self"); return end
        undoGame(md, b, me)
        md.bans[a.id] = nil
        release(b)
        logAt(p, "unban", b.user or b.sid or b.ip)
    else
        local act, target = nil, nil
        if okUser(a.user) then act, target = "UnBan", a.user
        elseif okUser(a.sid) and Adm.targetKind(a.sid) == "sid" then act, target = "UnBanSteamID", a.sid
        elseif okUser(a.ip) and Adm.targetKind(a.ip) == "ip" then act, target = "UnBanIPOnly", a.ip end
        if not act then
            Srv.bad(p, "a_unban")
            Srv.ack(p, rid, false, "gone")
            return
        end
        if (act == "UnBan" and target == me) or (act == "UnBanSteamID" and mine and mine.sid == target) then Srv.ack(p, rid, false, "self"); return end
        owe(md, act, target, "", 0, me)
        logAt(p, "unban", target)
    end
    Srv.mark(p, "a_unban")
    Srv.ack(p, rid, true)
    pushBans(md)
end)

-- the staff client a call went to made it. Only that client: anyone else's word would clear a ban nobody made. Even then it
-- only says the call went without a Lua error: the ban is judged again (reOwe, checkKicks)
reg("a_done", {}, function(p, a, rid)
    local md = open()
    if T.frozen or not Tk.whole(a.id) then return end
    local e = md.owed[a.id]
    if not (e and e.sentTo == p:getUsername() and Srv.can(p, owedCap(e.act))) then return end
    doneOwed(md, e, getTimestamp())
end)

-- a staff client's look at the game's user list (runLooks): rows of { u, role, wl } for the names asked. Only the client asked,
-- in time, and only names asked count; a name missing, with no role, or not from the game's database (wl false) says nothing.
-- The role "banned" says the game holds the name's ban; another role, LIFT_FRESH_S after the look that saw it, that the game
-- lifted it. An answer that is a lie needs a staff member who could lift the ban anyway
reg("a_looked", {}, function(p, a, rid)
    local md = open()
    local cur = T.look
    if T.frozen or not cur or a.id ~= cur.id or p:getUsername() ~= cur.to then return end
    if not (CAP_LOOK and Srv.can(p, CAP_LOOK) and Srv.can(p, CAP.BanUnbanUser)) then return end
    T.look = nil
    if getTimestamp() - cur.at >= AL.LOOK_WAIT_S then return end
    local said = {}
    if type(a.rows) == "table" then
        for i = 1, math.min(#a.rows, AL.LOOK_N) do
            local r = a.rows[i]
            if type(r) == "table" and type(r.u) == "string" and r.wl == true and type(r.role) == "string" and #r.role <= AL.TARGET_MAX then
                local id = cur.names[string.lower(r.u)]
                if id and said[id] ~= true then said[id] = string.lower(r.role) == AL.BANNED_ROLE end   -- (two rows: banned wins)
            end
        end
    end
    for _, id in pairs(cur.names) do
        local b = md.bans[id]
        local h = T.hold[id]
        if b and said[id] == true then
            if not b.nameSeen then b.nameSeen = cur.at end
        elseif b and said[id] == false and b.nameSeen and cur.at - b.nameSeen >= AL.LIFT_FRESH_S and not banOwed(md, b) then
            closeLifted(md, b, "the game's user list no longer has the name banned", cur.to)
            h = nil
        end
        if h then h.done = true end      -- (answered: a held row's player is judged as before)
    end
end)

-- a client that did not leave: staff reach for the game's ban. It lifts with the timed ban, through a staff client
reg("a_gameban", { cap = CAP.BanUnbanUser }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local b = Tk.whole(a.id) and md.bans[a.id] or nil
    if not b or not b.untilT or b.gameBan then Srv.ack(p, rid, false, "gone"); return end
    if owedRoom(md) < 1 then Srv.ack(p, rid, false, "full"); return end
    local me = p:getUsername()
    if b.user then owe(md, "Ban", b.user, b.reason, 0, me, { banId = b.id })
    elseif b.sidGame then owe(md, "BanSteamID", b.sidGame, b.reason, 0, me, { banId = b.id })
    else Srv.ack(p, rid, false, "gone"); return end
    b.gameBan = true
    logAt(p, "game ban", b.user or b.sid, b.reason)
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
    -- (FindItem falls back to the bare type in any module: "Mod.Axe" can find Base.Axe. What is spawned and logged is the
    -- item it found, by its own full type, never the client's string)
    local found = getScriptManager():FindItem(item)
    local full = found and found:getFullName()
    if type(full) ~= "string" or full == "" then Srv.ack(p, rid, false, "item"); return end
    local made = 0
    if to == "ground" then
        local sq = p:getCurrentSquare()
        if not sq then Srv.ack(p, rid, false, "state"); return end
        for _ = 1, n do
            if not sq:AddWorldInventoryItem(full, 0.5, 0.5, 0) then break end
            made = made + 1
        end
    else
        local o = (to == "me") and p or Srv.player(to)
        if not o then Srv.ack(p, rid, false, "offline"); return end
        local inv = o:getInventory()
        for _ = 1, n do
            local it = inv:AddItem(full)
            if not it then break end
            sendAddItemToContainer(inv, it)
            made = made + 1
        end
    end
    local other = nil
    if to ~= "me" and to ~= "ground" then other = to end
    if made > 0 then
        logAt(p, "spawn", other, tostring(made) .. " x " .. full .. " to " .. to)
        if Adm.SPAWN_TELLS and other then Srv.to(Srv.player(other), Adm.MOD, "a_note", { kind = "spawn", n = made, item = full }) end
    end
    -- (the game made none, or fewer than asked: not done)
    if made < n then Srv.ack(p, rid, false, "item", { n = made }); return end
    Srv.ack(p, rid, true, nil, { n = made })
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
    logAt(p, "roles: " .. a.what, Tk.name(a.role))
    Srv.ack(p, rid, true)
end)

-- your own powers, for the log (the game's own setter already ran; a client that sends this proves nothing but that it
-- did). Only a power on the list, and only with its capability: the id is all that goes in the line
reg("a_power", { limit = AL.POWER_MS }, function(p, a, rid)
    local name = type(a.id) == "string" and Adm.POWER_CAP[a.id] or nil
    local cap = name and Capability[name] or nil
    if not (cap and Srv.can(p, cap)) then return end
    logAt(p, ((a.on == true) and "power on: " or "power off: ") .. a.id)
end)

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
--- A Kick owed for another part (the join rules): reason "" is the game's own words. nil when one already waits or the
--- table is frozen.
function Srv.oweKick(user, reason, why)
    local md = open()
    if T.frozen then return nil end
    return oweKick(md, user, reason, { why = why })
end

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
            ZeD.Srv.action("admin", Tk.SYS, "admin clock failed", nil, err)
        end
    end
    if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(safeTick) end
    Events.OnInitGlobalModData.Add(function() if ZeD.Srv.openAdmin then ZeD.Srv.openAdmin() end end)
end
Srv.openAdmin = open

return T
