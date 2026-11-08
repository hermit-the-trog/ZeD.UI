-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Admin.lua
-- ============================================================================
-- THE ADMIN TOOLS, THE CLIENT'S MODEL (client). No drawing: AdminTab.lua and the admin cards (ZeD_AdminCards.lua and
-- the other card files) read this and call it; ZeD_Chat.lua reads the mutes.
--
-- With the server part every act goes to the server first, and the game's own call follows only on its ack: server Lua
-- cannot kick, ban or set a role, so that call goes from this client once the server has authorized it. Ban calls
-- that wait or must not be lost come back as a_owed, and this client says a_done when it has made them. A name from a row
-- is sent as user and a typed target as target, and the shape of a string decides nothing about a row.
--
-- Without the server part the same functions make the game's call straight away; what only the server part can do (timed
-- bans, repeats, the player's card, the log) is grayed on the cards with the reason.
--
-- The game's data read here, each only with the capability the game asks for it: getUsers (SeeNetworkUsers), getRoles
-- (RolesRead), the banned lists (BanUnbanUser), a player's log (ReadUserLog).
--
-- QA switches, read at call time (the same kind the ticket cards have):
--   M.qaHold   true: no traffic. The screen shows only what the QA script put in the model
--   M.qaLink   true / false: the server part as the cards read it
--   M.qaCaps   a table of capability names: what the cards draw for, whatever the role
--   M.qaRoles, M.qaItems   stand-ins for the game's role list and item list
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Tickets"
require "ZeD/Tr"
require "ZeD/ZeD_Messages"
require "ISUI/AdminPanel/ISAdminPowerUI"

ZeD = ZeD or {}
ZeD.Admin = ZeD.Admin or {}
local M = ZeD.Admin
local S = ZeD.ServerPart
local Tk = ZeD.Tk
local Adm = ZeD.Adm
local K = ZeD.Tickets
local AL = Adm.L

local WATCH_IDLE_MS = 1500            -- read nowhere: with no frame of the tab M.watch is not called, so nothing is asked
local USERS_EVERY_MS = 5000           -- the game's user list and the server's players are asked this often
local READ_EVERY_MS = 1000            -- getUsers has no event: it is read this often while the tab shows
local LISTS_EVERY_MS = 10000          -- bans and repeats
local ROLE_WAIT_MS = 10000            -- a new role waits this long to appear

M.seq = M.seq or 0                    -- bumps on every change (the cards re-read)
M.rows = M.rows or {}                 -- the one Players list
M.cards = M.cards or {}               -- username -> the server's card
M.logs = M.logs or {}                 -- username -> the game's user log
M.bans = M.bans or {}                 -- ZeD's bans, as the server sends them
M.repeats = M.repeats or {}
M.mutes = M.mutes or {}               -- lower-case username -> true
M.voice = M.voice or {}               -- username -> true: voice banned here, with no server part to keep the list
M.steamNames = M.steamNames or {}     -- Steam ID -> the name on Steam, once read
M.gameIps = M.gameIps or {}           -- the game's own banned lists
M.gameSids = M.gameSids or {}
M.srvRows = M.srvRows or {}           -- username -> the server's row

local function now() return getTimestampMs() end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function tr(k, ...) return ZeD.tr(k, ...) end
--- Mark the model changed: M.seq bumps and the cards read it again.
function M.bump() M.seq = M.seq + 1 end

--- This client's username ("" before there is a player).
function M.me()
    local p = getPlayer()
    return p and p:getUsername() or ""
end

--- The server part as the tools read it: up, and new enough to hold them.
function M.live()
    if M.qaLink ~= nil then return M.qaLink end
    return S.available() and S.adm == true
end

--- True when this player's role has the capability (by its name in the game's Capability list).
function M.can(name)
    if M.qaCaps then return M.qaCaps[name] == true end
    local p = getPlayer()
    local c = Capability and Capability[name]
    if not (p and c) then return false end
    return safe(function() return p:getRole():hasCapability(c) end, false) == true
end

-- ---------------------------------------------------------------------------
-- THE GAME'S ROLES
-- ---------------------------------------------------------------------------
local function readRole(r)
    local c = r:getColor()
    local row = { name = r:getName(), desc = r:getDescription() or "", color = { r = c:getR(), g = c:getG(), b = c:getB() },
        pos = r:getPosition(), readOnly = r:isReadOnly() == true, obj = r, caps = {}, defaults = {} }
    local d = r:getDefaults()
    for i = 0, d:size() - 1 do row.defaults[#row.defaults + 1] = d:get(i) end
    local all = getCapabilities()
    for i = 0, all:size() - 1 do
        local cap = all:get(i)
        if r:hasCapability(cap) then row.caps[cap:name()] = true end
    end
    return row
end

--- The roles, least to most, as the game's Roles List has them turned over: top to bottom, least to most, as drawn.
--- Read again at most every 5 s, and at once after a role write or when the game sends the roles.
function M.roles()
    if M.qaRoles then return M.qaRoles end
    local t = now()
    if M.rolesAt and t - M.rolesAt < USERS_EVERY_MS and M.roleList then return M.roleList end
    M.rolesAt = t
    local out = {}
    local ok = pcall(function()
        local list = getRoles()
        for i = 0, list:size() - 1 do out[#out + 1] = readRole(list:get(i)) end
    end)
    if not ok then return M.roleList or {} end
    table.sort(out, function(a, b) return a.pos < b.pos end)
    M.roleList = out
    return out
end

--- One role's row by name, nil when the game has none by that name.
function M.role(name)
    for _, r in ipairs(M.roles()) do
        if r.name == name then return r end
    end
    return nil
end

--- The role new players get, for the Roles row.
function M.defaultRoleName()
    for _, r in ipairs(M.roles()) do
        for _, d in ipairs(r.defaults) do
            if d == "defaultForNewUser" then return r.name end
        end
    end
    return nil
end

-- the capability every list of names has: the least role that has it, past banned
function M.roleWith(capName)
    for _, r in ipairs(M.roles()) do
        if r.caps[capName] and r.name ~= "banned" then return r.name end
    end
    return nil
end

--- The words for a capability (UI_ZeD_Cap_<name>); a capability a later game added has no words yet: its own name.
function M.capWord(name)
    local key = "UI_ZeD_Cap_" .. name
    local s = tr(key)
    if s == key then return name end
    return s
end

--- What a grayed control says: the capability it needs, and the role that has it.
function M.why(capName)
    if #M.roles() == 0 then return tr("UI_ZeD_Adm_NeedCapOnly", M.capWord(capName), capName) end
    local r = M.roleWith(capName)
    if r then return tr("UI_ZeD_Adm_NeedCap", M.capWord(capName), capName, r) end
    return tr("UI_ZeD_Adm_NeedCapNone", M.capWord(capName), capName)
end

--- What a role change means for this player: words for what they gain and lose, and the powers the game switches on.
function M.roleChange(fromName, toName)
    local from, to = M.role(fromName), M.role(toName)
    local gain, lose, powers = {}, {}, {}
    if not to then return gain, lose, powers end
    local isPower = {}
    for _, pw in ipairs(Adm.POWERS) do isPower[pw.cap] = pw end
    for _, g in ipairs(Adm.GROUPS) do
        for _, c in ipairs(g.caps) do
            local had, has = from and from.caps[c], to.caps[c]
            if has and not had then
                if isPower[c] then powers[#powers + 1] = isPower[c] else gain[#gain + 1] = M.capWord(c) end
            elseif had and not has then
                lose[#lose + 1] = M.capWord(c)
            end
        end
    end
    return gain, lose, powers
end

-- ---------------------------------------------------------------------------
-- THE ONE PLAYERS LIST: the game's user list, the server's players, the scoreboard, in that order of trust
-- ---------------------------------------------------------------------------
local function readUser(u)
    local role = u:getRole()
    return { user = u:getUsername(), on = u:isOnline() == true, role = role and role:getName() or nil,
        lastText = u:getLastConnection(), warn = u:getWarningPoints(), kicks = u:getKicks(), sid = u:getSteamid(),
        ipBan = u:getIpBanned(), sidBan = u:getSteamIdBanned() }
end

--- True on a Steam server.
function M.onSteam() return safe(function() return getSteamModeActive() end, false) == true end

-- the name on Steam, as ISScoreboard reads it. NetworkUser.getDisplayName is the name in the game, not this
local function steamName(r)
    if r.sid and r.sid ~= "" then
        local name = M.steamNames[r.sid]
        if not name then
            name = safe(function() return getSteamProfileNameFromSteamID(r.sid) end, nil)
            if name == "[unknown]" then return nil end        -- (Steam has not sent it yet: read again)
            M.steamNames[r.sid] = name
        end
        return name
    end
    local name = safe(function() return getSteamProfileNameFromUsername(r.user) end, nil)
    return (name ~= "[unknown]") and name or nil
end

local function sortRows(out)
    table.sort(out, function(a, b)
        if a.on ~= b.on then return a.on end
        return string.lower(a.user) < string.lower(b.user)
    end)
end

function M.refreshRows()
    if M.qaHold then return end
    local byUser, out = {}, {}
    local function add(row)
        byUser[row.user] = row
        out[#out + 1] = row
    end
    if M.can("SeeNetworkUsers") then
        pcall(function()
            local list = getUsers()
            for i = 0, list:size() - 1 do add(readUser(list:get(i))) end
        end)
    end
    for u, r in pairs(M.srvRows) do
        local row = byUser[u]
        if row then
            row.on = r.on
            row.lastT = r.last
            row.role = r.role or row.role
        else
            add({ user = u, on = r.on, role = r.role, lastT = r.last })
        end
    end
    local Tab = ZeD.ServerTab
    for _, pl in ipairs(Tab and Tab.players or {}) do
        local row = byUser[pl.user]
        if row then row.on = true else add({ user = pl.user, on = true }) end
    end
    if M.onSteam() then
        for _, r in ipairs(out) do r.steam = steamName(r) end
    end
    sortRows(out)
    M.rows = out
    M.onlineN = 0
    local sig = {}
    for i, r in ipairs(out) do
        if r.on then M.onlineN = M.onlineN + 1 end
        sig[i] = table.concat({ r.user, tostring(r.on), tostring(r.role), tostring(r.warn), tostring(r.kicks), tostring(r.lastT), tostring(r.steam) }, ",")
    end
    -- (read every second while the tab shows: the cards rebuild only for a real change)
    sig = table.concat(sig, ";")
    if sig ~= M.rowsSig then
        M.rowsSig = sig
        M.bump()
    end
end

--- The Players row for a username, or nil.
function M.row(user)
    for _, r in ipairs(M.rows) do
        if r.user == user then return r end
    end
    return nil
end

--- The list a Find keeps: a name, a role or a Steam name (onlineOnly: players who are on).
function M.findRows(find, onlineOnly)
    local q = string.lower(Tk.clean(find) or "")
    local out = {}
    for _, r in ipairs(M.rows) do
        local keep = not onlineOnly or r.on
        if keep and q ~= "" then
            keep = string.find(string.lower(r.user), q, 1, true) ~= nil
                or (r.role ~= nil and string.find(string.lower(r.role), q, 1, true) ~= nil)
                or (r.steam ~= nil and string.find(string.lower(r.steam), q, 1, true) ~= nil)
        end
        if keep then out[#out + 1] = r end
    end
    return out
end

--- How many Players rows hold the role.
function M.roleCount(name)
    local n = 0
    for _, r in ipairs(M.rows) do
        if r.role == name then n = n + 1 end
    end
    return n
end

-- ---------------------------------------------------------------------------
-- THE FRAME: the tab says it shows, each frame; nothing is asked otherwise
-- ---------------------------------------------------------------------------
local function askAll(t)
    if M.can("SeeNetworkUsers") then pcall(requestUsers) end
    if M.can("RolesRead") then pcall(requestRoles) end
    if M.live() then
        if M.can("SeePlayersConnected") then S.send(Adm.MOD, "a_players", {}) end
    end
    local Tab = ZeD.ServerTab
    if Tab and Tab.askPlayers then Tab.askPlayers() end
end

local function askLists()
    if M.live() then
        if M.can("BanUnbanUser") then S.send(Adm.MOD, "a_bans", {}) end
        if M.can("DisplayServerMessage") then S.send(Adm.MOD, "a_repeats", {}) end
    end
    if M.can("BanUnbanUser") then
        pcall(getBannedIPs)
        if M.onSteam() then pcall(getBannedSteamIDs) end
    end
end

--- Called each frame the tab or one of its cards shows: the game and the server are asked again when their time is up (users, roles
--- and players every 5 s; bans and repeats every 10 s) and the rows are read again every second.
function M.watch()
    if M.qaHold then return end
    local t = now()
    M.seenAt = t
    if not M.askAt or t - M.askAt >= USERS_EVERY_MS then
        M.askAt = t
        askAll(t)
    end
    if not M.listsAt or t - M.listsAt >= LISTS_EVERY_MS then
        M.listsAt = t
        askLists()
    end
    if not M.readAt or t - M.readAt >= READ_EVERY_MS then
        M.readAt = t
        M.refreshRows()
    end
end

-- ---------------------------------------------------------------------------
-- ACTS: to the server first; the game's call on its ack. Without the server part, the game's call alone.
-- ---------------------------------------------------------------------------
local function act(cmd, args, game, cb)
    if M.live() then
        K.requestOn(Adm.MOD, cmd, args, function(a)
            if a.ok and game then
                local ok, err = pcall(game, a)
                if not ok then ZeD.logOnce("admin: game call " .. cmd, err) end
            end
            if cb then cb(a) end
            M.bump()
        end)
        return
    end
    if game then
        local ok, err = pcall(game, args)
        if not ok then ZeD.logOnce("admin: game call " .. cmd, err) end
    end
    if cb then cb({ ok = true, fallback = true }) end
    M.bump()
end

local Q = Adm.quoted

-- The player verbs below are acts: cb gets the server's answer, or { ok = true, fallback = true } without the part.
--- Go to the player.
function M.teleport(user, cb)
    act("a_tp", { user = user }, function() SendCommandToServer("/teleport " .. Q(user)) end, cb)
end
--- Bring the player here.
function M.bring(user, cb)
    act("a_bring", { user = user }, function() SendCommandToServer("/teleportplayer " .. Q(user) .. " " .. Q(M.me())) end, cb)
end
--- Kick the player, with a reason.
function M.kick(user, reason, cb)
    act("a_kick", { user = user, reason = reason }, function(a)
        SendCommandToServer("/kickuser " .. Q(user) .. " -r " .. Q(a.reason or reason))
    end, cb)
end
--- Add n warning points, with a reason; the player's log is asked for again.
function M.warn(user, n, reason, cb)
    act("a_warn", { user = user, n = n, reason = reason }, function(a)
        addWarningPoint(user, a.reason or reason, a.n or n)
        if M.can("ReadUserLog") then requestUserlog(user) end
    end, cb)
end
--- The game's own mute is voice alone (/voiceban); chat is ZeD's, on the server's list. The voice ban finds only a player
--- who is on (VoiceBanCommand: getPlayerByUserNameForCommand), so for an account that is off (here = false) the server's
--- list is the mute and the game is not asked.
function M.mute(user, on, cb, here)
    act("a_mute", { user = user, on = on }, function()
        if here == false and M.live() then return end
        SendCommandToServer("/voiceban " .. Q(user) .. (on and " -true" or " -false"))
        if not M.live() then M.voice[user] = on or nil end
    end, cb)
end
--- What the card's Mute reads: the server's list, or without it the voice ban made from here.
function M.muted(user) return M.isMuted(user) or M.voice[user] == true end
--- Give the player a role. keep: the ids of the powers the new role brings that stay on; the server has the
--- rest switched off (a_powersoff).
function M.setRole(user, role, keep, cb)
    act("a_role", { user = user, role = role, keep = keep }, function() networkUserAction("SetRole", user, role) end, cb)
end
--- Level Up and Level Down (dir) need the player's own XP, which only the server holds for everyone; the card is
--- read again after.
function M.skill(user, perk, dir, cb)
    act("a_skill", { user = user, perk = perk, dir = dir }, function(a)
        SendCommandToServer("/addxp " .. Q(user) .. " " .. tostring(a.perk) .. "=" .. tostring(a.amount) .. " -false")
    end, function(a)
        if cb then cb(a) end
        if a.ok and M.live() then M.loadCard(user, true) end
    end)
end

--- Ask the server for a player's card (at most every 3 s for the same name, unless forced).
function M.loadCard(user, force)
    if M.qaHold or not M.live() or not M.can("CanSeePlayersStats") then return end
    local t = now()
    if not force and M.cardAskAt and M.cardAskUser == user and t - M.cardAskAt < 3000 then return end
    M.cardAskAt, M.cardAskUser = t, user
    S.send(Adm.MOD, "a_card", { user = user })
end

--- Ask the game for a player's user log (it arrives through OnReceiveUserlog).
function M.loadLog(user)
    if M.qaHold or not M.can("ReadUserLog") then return end
    pcall(requestUserlog, user)
end

-- the game's Manage Inventory, opened on a player the game knows
function M.openInventory(user, oid)
    local id = oid
    if id == nil then
        local who = getPlayerFromUsername(user)
        id = who and who:getOnlineID() or -1
    end
    local ui = ISPlayerStatsManageInvUI:new(100, 100, 900, 650, id, user)
    ui:initialise()
    ui:addToUIManager()
end

-- ---------------------------------------------------------------------------
-- BANS
-- ---------------------------------------------------------------------------
local function banAsk(args, cb)
    K.requestOn(Adm.MOD, "a_ban", args, function(a)
        if cb then cb(a) end
        M.bump()
    end)
end

-- a timed ban is ZeD's: without the server part only the game's permanent one exists
local function noTimed(len, cb)
    if not Adm.LENGTH[len].sec then return false end
    if cb then cb({ ok = false, err = "part" }) end
    return true
end

local function gameBanUser(user, reason, banIp)
    -- (the game's call with the IP needs them on and can refuse, banning nobody: the plain one always follows it)
    if banIp then SendCommandToServer("/banuser " .. Q(user) .. " -ip -r " .. Q(reason)) end
    SendCommandToServer("/banuser " .. Q(user) .. " -r " .. Q(reason))
end

--- From a player's row or card: user is a username, whatever it looks like. len: a key of Adm.LENGTH (a timed
--- length needs the server part).
function M.ban(user, reason, len, banIp, cb)
    if M.live() then
        banAsk({ user = user, reason = reason, len = len, banIp = banIp == true }, cb)
        return
    end
    if noTimed(len, cb) then return end
    gameBanUser(user, reason, banIp)
    if cb then cb({ ok = true, fallback = true }) end
    M.bump()
end

--- Typed on the Bans card: a username, a Steam ID or an IP. A name the game's list holds stays a name.
function M.banTyped(target, reason, len, cb)
    if M.live() then
        banAsk({ target = target, reason = reason, len = len, banIp = false }, cb)
        return
    end
    if noTimed(len, cb) then return end
    local kind = M.row(target) and "user" or Adm.targetKind(target)
    if kind == "ip" then SendCommandToServer("/banip " .. target)
    elseif kind == "sid" then banUnbanUserAction("BanSteamID", target, reason)
    else gameBanUser(target, reason, false) end
    if cb then cb({ ok = true, fallback = true }) end
    M.bump()
end

--- row: from M.banRows. Each is lifted as what it is: a row the game holds on an IP by its IP, and never by the look of a name.
function M.unban(row, cb)
    local onIp = row.ip ~= nil and row.game == true
    if M.live() then
        local args = (row.id and { id = row.id }) or (onIp and { ip = row.ip }) or (row.user and { user = row.user }) or (row.sid and { sid = row.sid }) or { ip = row.ip }
        K.requestOn(Adm.MOD, "a_unban", args, function(a)
            if cb then cb(a) end
            M.bump()
        end)
        return
    end
    if onIp then banUnbanUserAction("UnBanIPOnly", row.ip, "")
    elseif row.user then banUnbanUserAction("UnBan", row.user, "")
    elseif row.sid then banUnbanUserAction("UnBanSteamID", row.sid, "")
    else banUnbanUserAction("UnBanIPOnly", row.ip, "") end
    if cb then cb({ ok = true, fallback = true }) end
    M.bump()
end

--- Add the game's own ban to ZeD's timed ban id, for a client that did not leave; it lifts with the timed ban.
function M.gameBan(id, cb) act("a_gameban", { id = id }, nil, cb) end

--- ZeD's bans and the game's, each once: a row only the game holds has no id, and its who is the game's window.
function M.banRows()
    local out, seen = {}, {}
    for _, b in ipairs(M.bans) do
        out[#out + 1] = b
        if b.user then seen["u:" .. b.user] = true end
        if b.sid then seen["s:" .. b.sid] = true end
        if b.ip then seen["i:" .. b.ip] = true end
    end
    for _, r in ipairs(M.gameSids) do
        if not seen["s:" .. r.sid] then
            seen["s:" .. r.sid] = true
            out[#out + 1] = { sid = r.sid, reason = r.reason, game = true }
        end
    end
    for _, r in ipairs(M.gameIps) do
        if not seen["i:" .. r.ip] then
            seen["i:" .. r.ip] = true
            out[#out + 1] = { ip = r.ip, user = r.user, reason = r.reason, game = true }
        end
    end
    for _, r in ipairs(M.rows) do
        if r.role == "banned" and not seen["u:" .. r.user] then
            seen["u:" .. r.user] = true
            out[#out + 1] = { user = r.user, game = true, sid = (r.sidBan ~= "" and r.sidBan) or nil }
        end
    end
    return out
end

--- The ban on a username (ZeD's or the game's), leaving out the game's IP bans; nil when none.
function M.banOf(user)
    for _, b in ipairs(M.banRows()) do
        if b.user == user and not (b.ip and b.game) then return b end
    end
    return nil
end

-- " -r <reason>", or nothing: the game's commands read an empty quoted reason as a missing argument and refuse the whole line
-- (CommandArgs "(.+)"), and with no -r they use their own words (a Kick for the join rules goes that way)
local function rArg(reason)
    if type(reason) == "string" and reason ~= "" then return " -r " .. Q(reason) end
    return ""
end

local OWED = {
    Ban = function(a) SendCommandToServer("/banuser " .. Q(a.target) .. rArg(a.reason)) end,
    BanIP = function(a) SendCommandToServer("/banuser " .. Q(a.target) .. " -ip" .. rArg(a.reason)) end,
    Kick = function(a) SendCommandToServer("/kickuser " .. Q(a.target) .. rArg(a.reason)) end,
    BanSteamID = function(a) banUnbanUserAction("BanSteamID", a.target, a.reason or "") end,
    BanIPOnly = function(a) SendCommandToServer("/banip " .. a.target) end,
    UnBan = function(a) banUnbanUserAction("UnBan", a.target, "") end,
    UnBanIP = function(a) banUnbanUserAction("UnBanIP", a.target, "") end,
    UnBanSteamID = function(a) banUnbanUserAction("UnBanSteamID", a.target, "") end,
    UnBanIPOnly = function(a) banUnbanUserAction("UnBanIPOnly", a.target, "") end,
    -- after an unban: the game's unban leaves the account on the default user role, so the role it had goes back (reason: the role)
    SetRole = function(a) networkUserAction("SetRole", a.target, a.reason) end,
    -- a mute's voice ban, owed when the muted player came on (the game's /voiceban needs them on and holds for the connection)
    VoiceBan = function(a) SendCommandToServer("/voiceban " .. Q(a.target) .. " -true") end,
}

-- ---------------------------------------------------------------------------
-- SERVER MESSAGES
-- ---------------------------------------------------------------------------
--- A server message. every: minutes, or nil for once. The first goes through the game's /servermsg in any case.
function M.message(text, every, cb)
    local function sendIt(a) SendCommandToServer("/servermsg " .. Q(a.text or text)) end
    if every and M.live() then
        K.requestOn(Adm.MOD, "a_repeat", { text = text, every = every }, function(a)
            if a.ok then sendIt(a) end
            if cb then cb(a) end
            M.bump()
        end)
        return
    end
    act("a_msg", { text = text }, sendIt, cb)
end

--- Stop a repeating message, by its id.
function M.stop(id, cb) act("a_stop", { id = id }, nil, cb) end

-- ---------------------------------------------------------------------------
-- SPAWN ITEMS
-- ---------------------------------------------------------------------------
--- The game's whole item list, read once: names sorted, obsolete and hidden left out as its Items List leaves them.
function M.items()
    if M.qaItems then return M.qaItems end
    if M.itemList then return M.itemList end
    local out = {}
    pcall(function()
        local list = getAllItems()
        for i = 0, list:size() - 1 do
            local it = list:get(i)
            if not it:getObsolete() and not it:isHidden() then
                local cat = it:getDisplayCategory()
                out[#out + 1] = { name = it:getDisplayName(), full = it:getFullName(), cat = cat and getTextOrNull("IGUI_ItemCat_" .. cat) or nil }
            end
        end
    end)
    table.sort(out, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    M.itemList = out
    return out
end

--- The items whose name, full type or category holds the words of a Find.
function M.findItems(find)
    local q = string.lower(Tk.clean(find) or "")
    local all = M.items()
    if q == "" then return all end
    local out = {}
    for _, it in ipairs(all) do
        if string.find(string.lower(it.name), q, 1, true) or string.find(string.lower(it.full), q, 1, true)
            or (it.cat and string.find(string.lower(it.cat), q, 1, true)) then
            out[#out + 1] = it
        end
    end
    return out
end

--- n of an item (its full type) to "me", "ground" or a username; the ground needs the server part.
function M.spawn(full, n, to, cb)
    if to == "ground" and not M.live() then       -- (the game's /additem has no ground)
        if cb then cb({ ok = false, err = "part" }) end
        return
    end
    if M.live() then
        K.requestOn(Adm.MOD, "a_spawn", { item = full, n = n, to = to }, function(a)
            if cb then cb(a) end
            M.bump()
        end)
        return
    end
    local who = (to == "me") and M.me() or to
    SendCommandToServer("/additem " .. Q(who) .. " " .. Q(full) .. " " .. tostring(n))
    if cb then cb({ ok = true, fallback = true }) end
end

-- ---------------------------------------------------------------------------
-- ROLES: the game's calls, each with its line in the server's log first
-- ---------------------------------------------------------------------------
local function roleAct(what, name, game, cb) act("a_rolelog", { what = what, role = name }, game, cb) end

local function setup(role, d)
    local all = getCapabilities()
    local caps = {}
    for i = 0, all:size() - 1 do
        local cap = all:get(i)
        caps[cap] = d.caps[cap:name()] == true
    end
    setupRole(role, d.desc, Color.new(d.color.r, d.color.g, d.color.b, 1.0), caps)
end

--- d: name, desc, color, caps. isNew: the game makes the role, then this waits for it to arrive before filling it in.
function M.saveRole(d, isNew, cb)
    if not isNew and not M.role(d.name) then         -- (another admin deleted it while the card was open)
        if cb then cb({ ok = false, err = "gone" }) end
        return
    end
    roleAct(isNew and "add" or "save", d.name, function()
        if isNew then
            addRole(d.name)
            M.newRole = { d = d, at = now() }
        else
            setup(M.role(d.name).obj, d)
        end
        pcall(requestRoles)
        M.rolesAt = nil
    end, cb)
end

--- Delete a role.
function M.deleteRole(name, cb)
    roleAct("delete", name, function()
        deleteRole(name)
        pcall(requestRoles)
        M.rolesAt = nil
    end, cb)
end

--- Make a role the one new players get.
function M.defaultRole(name, cb)
    roleAct("default", name, function()
        setDefaultRoleFor("defaultForNewUser", name)
        pcall(requestRoles)
        M.rolesAt = nil
    end, cb)
end

--- dir: 1 more rank, -1 less, as moveRole has it. The game's Roles List sorts most first, so there 1 is Up; ZeD's lists least first.
function M.moveRole(name, dir, cb)
    roleAct((dir > 0) and "up" or "down", name, function()
        moveRole(dir, name)
        pcall(requestRoles)
        M.rolesAt = nil
    end, cb)
end

-- ---------------------------------------------------------------------------
-- YOUR OWN POWERS: said to the server for the log
-- ---------------------------------------------------------------------------
--- Tell the server one of your own powers went on or off (id: the game's ISAdminPowerUI option id), for its log.
function M.powerLog(id, on)
    if M.live() then S.send(Adm.MOD, "a_power", { id = id, on = on }) end
end

-- ---------------------------------------------------------------------------
-- WHAT THE SERVER SENDS
-- ---------------------------------------------------------------------------
local on = {}

function on.a_players(a)
    local byUser = {}
    for _, r in ipairs(a.rows or {}) do
        if type(r.u) == "string" then byUser[r.u] = { on = r.on == true, role = r.role, last = r.last } end
    end
    M.srvRows = byUser
    M.refreshRows()
end

function on.a_card(a)
    if type(a.user) == "string" then M.cards[a.user] = a end
    M.bump()
end

function on.a_bans(a)
    M.bans = a.rows or {}
    M.bump()
end

function on.a_repeats(a)
    M.repeats = a.rows or {}
    M.bump()
end

function on.a_mutes(a)
    local set = {}
    for _, u in ipairs(a.list or {}) do set[string.lower(u)] = true end
    M.mutes = set
    M.bump()
end

function on.a_srvmsg(a)
    if ZeD.Chat and ZeD.Chat.serverLine then ZeD.Chat.serverLine(a.text) end
end

function on.a_owed(a)
    local fn = OWED[a.act]
    if not fn then return end
    local ok, err = pcall(fn, a)
    if not ok then
        ZeD.logOnce("admin: owed " .. tostring(a.act), err)
        return
    end
    S.send(Adm.MOD, "a_done", { id = a.id })
end

-- the server asks what the game's own user list says of some names: their roles, as the game keeps a name ban (a_looked).
-- The game sends that list to a role with SeeNetworkUsers; it is asked for here and read when it next arrives (the server judges
-- how fresh that is: LIFT_FRESH_S). One look at a time: a newer question replaces an older one
function on.a_look(a)
    if M.qaHold or not Tk.whole(a.id) or type(a.names) ~= "table" then return end
    local want = {}
    for i = 1, math.min(#a.names, AL.LOOK_N) do
        local n = a.names[i]
        if type(n) == "string" and #n <= AL.TARGET_MAX then want[string.lower(n)] = n end
    end
    M.look = { id = a.id, want = want, at = now() }
    pcall(requestUsers)
end

-- the game's user list arrived: the look waiting for it is answered with each asked name's role, and whether that row comes
-- from the game's own database (inWhitelist; a player on with no row there is sent with their live role)
local function onNetworkUsers()
    local look = M.look
    if not look then return end
    M.look = nil
    if now() - look.at >= AL.LOOK_WAIT_S * 1000 then return end
    local rows = {}
    pcall(function()
        local list = getUsers()
        for i = 0, list:size() - 1 do
            local u = list:get(i)
            local name = u:getUsername()
            local asked = type(name) == "string" and look.want[string.lower(name)] or nil
            if asked and #rows < AL.LOOK_N then
                local r = u:getRole()
                rows[#rows + 1] = { u = asked, role = r and r:getName() or nil, wl = u:isInWhitelist() == true }
            end
        end
    end)
    S.send(Adm.MOD, "a_looked", { id = look.id, rows = rows })
end

function on.a_note(a)
    if a.kind == "stay" and ZeD.Messages and ZeD.Messages.adminNote then
        ZeD.Messages.adminNote(tr("UI_ZeD_Adm_NoteStay", tostring(a.user)), true)
    elseif a.kind == "ipfail" and ZeD.Messages and ZeD.Messages.adminNote then
        ZeD.Messages.adminNote(tr("UI_ZeD_Adm_NoteIpFail", tostring(a.user)), true)
    elseif a.kind == "spawn" and ZeD.Messages and ZeD.Messages.adminNote then
        ZeD.Messages.adminNote(tr("UI_ZeD_Adm_NoteSpawn", tostring(a.n), tostring(a.item)))
    end
    if M.live() then S.send(Adm.MOD, "a_bans", {}) end
end

-- the powers the game switched on with a role and nobody ticked: off, with the game's own setter, as the Admin tab's ticks
function on.a_powersoff(a)
    local p = getPlayer()
    local opts = ISAdminPowerUI and ISAdminPowerUI.OptionById
    if not (p and opts) then return end
    for _, id in ipairs(a.ids or {}) do
        local o = opts[id]
        if o then
            o.player = p
            o:setValue(false)
        end
    end
    sendPlayerExtraInfo(p)
end

-- ---------------------------------------------------------------------------
-- LEAVING: the server says a ban stands. The reason shows, then the client goes. The ban and kick screen is
-- M.leaveScreen(info) when set (ZeD_CommunityCards.lua: it fills in the appeal line), else M.defaultLeave(info)
-- (ZeD_AdminCards.lua). info is kind, reason, untilT, hold, appeal. hold: the game's call lands while they are on, so
-- there is no Leave and the client's own clock runs twice as long, as a last resort.
-- ---------------------------------------------------------------------------
function on.a_leave(a)
    if M.leaveAt then return end         -- (the server says it again: the clock already runs)
    M.leave = { kind = a.kind, reason = a.reason, untilT = a.untilT, hold = a.hold == true, appeal = a.appeal, at = now() }
    M.leaveAt = now() + AL.LEAVE_S * (a.hold and 2000 or 1000)
    local show = M.leaveScreen or M.defaultLeave
    if show then
        local ok, err = pcall(show, M.leave)
        if not ok then ZeD.logOnce("admin: leave screen", err) end
    end
end

-- the ban came off while they read it
function on.a_stay()
    M.leave, M.leaveAt = nil, nil
end

--- Leave the server now: the screen's Leave, or the clock running out.
function M.leaveNow()
    M.leaveAt = nil
    pcall(forceDisconnect)
end

-- the game's user log has no event of its own for one card, so it is kept for every name that arrives
local function onUserlog(username, logs)
    local out = {}
    for i = 0, logs:size() - 1 do
        local l = logs:get(i)
        out[#out + 1] = { type = l:getType(), text = l:getText(), by = l:getIssuedBy(), amount = l:getAmount(), when = l:getLastUpdate() }
    end
    M.logs[username] = out
    M.bump()
end

local function onBannedIPs(list)
    local out = {}
    for i = 0, list:size() - 1 do
        local b = list:get(i)
        local user = b:getUsername()          -- (an IP banned on its own holds an empty name)
        out[#out + 1] = { ip = b:getIp(), user = (user ~= "") and user or nil, reason = b:getReason() }
    end
    M.gameIps = out
    M.bump()
end

local function onBannedSteamIDs(list)
    local out = {}
    for i = 0, list:size() - 1 do
        local b = list:get(i)
        out[#out + 1] = { sid = b:getSteamID(), reason = b:getReason() }
    end
    M.gameSids = out
    M.bump()
end

S.on(Adm.MOD, function(command, args)
    local fn = on[command]
    if fn then fn(args) end
end)

--- hello: my Steam ID for a ban on it, and the mutes. The server walks its players anyway; this is the first word.
function M.onHello(a)
    if a.adm == 1 then
        S.send(Adm.MOD, "a_hi", { sid = safe(function() return getCurrentUserSteamID() end, nil) })
    end
end

-- ---------------------------------------------------------------------------
-- THE CLOCK
-- ---------------------------------------------------------------------------
local function tick()
    if M.leaveAt and now() >= M.leaveAt then M.leaveNow() end
    local nr = M.newRole
    if nr then
        local r = nil
        pcall(function()
            local list = getRoles()
            for i = 0, list:size() - 1 do
                if list:get(i):getName() == nr.d.name then r = list:get(i) end
            end
        end)
        if r then
            M.newRole = nil
            setup(r, nr.d)
            pcall(requestRoles)
            M.rolesAt = nil
            M.bump()
        elseif now() - nr.at >= ROLE_WAIT_MS then
            M.newRole = nil
        end
    end
end

if not M.hooked then
    M.hooked = true
    if Events.OnTick then Events.OnTick.Add(tick) end
    if Events.OnReceiveUserlog then Events.OnReceiveUserlog.Add(onUserlog) end
    if Events.ViewBannedIPs then Events.ViewBannedIPs.Add(onBannedIPs) end
    if Events.ViewBannedSteamIDs then Events.ViewBannedSteamIDs.Add(onBannedSteamIDs) end
    if Events.OnNetworkUsersReceived then Events.OnNetworkUsersReceived.Add(function() onNetworkUsers() end) end
    -- a role write lands here: setupRole and the rest only send a packet, and the cards read the list once a change bumps
    if Events.OnRolesReceived then
        Events.OnRolesReceived.Add(function()
            M.rolesAt = nil
            M.bump()
        end)
    end
end

--- A muted player: their lines are hidden here (ZeD_Chat.lua reads this), and their own client will not send.
function M.isMuted(user) return type(user) == "string" and M.mutes[string.lower(user)] == true end

return M
