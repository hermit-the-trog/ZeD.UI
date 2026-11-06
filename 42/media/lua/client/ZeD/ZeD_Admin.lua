-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Admin.lua
-- ============================================================================
-- THE ADMIN TOOLS, THE CLIENT'S MODEL (ZeDUI/MP_ADMIN_SCOPE.md, Phase 2). No drawing: AdminTab.lua and ZeD_AdminCards.lua
-- read this and call it.
--
-- With the server part every act goes to the server first, and the game's own call follows only on its ack: server Lua
-- cannot kick, ban or set a role (A7), so that call goes from this client once the server has authorized it. Ban calls
-- that wait or must not be lost come back as a_owed, and this client says a_done when it has made them.
--
-- Without the server part the same functions make the game's call straight away; what only the server part can do (timed
-- bans, repeats, the player's card, the log) is grayed on the cards with the reason.
--
-- The game's data read here, each only with the capability the game asks for it: getUsers (SeeNetworkUsers), getRoles
-- (RolesRead), the banned lists (BanUnbanUser), a player's log (ReadUserLog).
--
-- QA, read at call time (the ticket cards' style):
--   M.qaHold   true: no traffic. The screen shows only what the QA script put in the model
--   M.qaLink   true / false: the server part as the cards read it
--   M.qaCaps   a table of capability names: what the cards draw for, whatever the role
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

local WATCH_IDLE_MS = 1500            -- no frame of the tab for this long: nothing is asked
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
M.mutes = M.mutes or {}               -- username -> true
M.gameIps = M.gameIps or {}           -- the game's own banned lists
M.gameSids = M.gameSids or {}
M.srvRows = M.srvRows or {}           -- username -> the server's row

local function now() return getTimestampMs() end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function tr(k, ...) return ZeD.tr(k, ...) end
function M.bump() M.seq = M.seq + 1 end

function M.me()
    local p = getPlayer()
    return p and p:getUsername() or ""
end

-- the server part as the tools read it: up, and new enough to hold them
function M.live()
    if M.qaLink ~= nil then return M.qaLink end
    return S.available() and S.adm == true
end

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

-- the roles, least to most, as the game's Roles List has them turned over: top to bottom, least to most, as drawn
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

function M.role(name)
    for _, r in ipairs(M.roles()) do
        if r.name == name then return r end
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

-- (a capability a later game added has no words yet: its own name)
function M.capWord(name)
    local key = "UI_ZeD_Cap_" .. name
    local s = tr(key)
    if s == key then return name end
    return s
end

-- what a grayed control says: the capability it needs, and the role that has it
function M.why(capName)
    if #M.roles() == 0 then return tr("UI_ZeD_Adm_NeedCapOnly", M.capWord(capName), capName) end
    local r = M.roleWith(capName)
    if r then return tr("UI_ZeD_Adm_NeedCap", M.capWord(capName), capName, r) end
    return tr("UI_ZeD_Adm_NeedCapNone", M.capWord(capName), capName)
end

-- what a role change means for this player: words for what they gain and lose, and the powers the game switches on
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
        steam = u:getDisplayName(), ipBan = u:getIpBanned(), sidBan = u:getSteamIdBanned() }
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
    sortRows(out)
    M.rows = out
    M.onlineN = 0
    local sig = {}
    for i, r in ipairs(out) do
        if r.on then M.onlineN = M.onlineN + 1 end
        sig[i] = table.concat({ r.user, tostring(r.on), tostring(r.role), tostring(r.warn), tostring(r.kicks), tostring(r.lastT) }, ",")
    end
    -- (read every second while the tab shows: the cards rebuild only for a real change)
    sig = table.concat(sig, ";")
    if sig ~= M.rowsSig then
        M.rowsSig = sig
        M.bump()
    end
end

function M.row(user)
    for _, r in ipairs(M.rows) do
        if r.user == user then return r end
    end
    return nil
end

-- the list a Find keeps: a name, a role or a Steam name
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
        if safe(function() return getSteamModeActive() end, false) then pcall(getBannedSteamIDs) else pcall(getBannedIPs) end
    end
end

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

function M.teleport(user, cb)
    act("a_tp", { user = user }, function() SendCommandToServer("/teleport " .. Q(user)) end, cb)
end
function M.bring(user, cb)
    act("a_bring", { user = user }, function() SendCommandToServer("/teleportplayer " .. Q(user) .. " " .. Q(M.me())) end, cb)
end
function M.kick(user, reason, cb)
    act("a_kick", { user = user, reason = reason }, function(a)
        SendCommandToServer("/kickuser " .. Q(user) .. " -r " .. Q(a.reason or reason))
    end, cb)
end
function M.warn(user, n, reason, cb)
    act("a_warn", { user = user, n = n, reason = reason }, function(a)
        addWarningPoint(user, a.reason or reason, a.n or n)
        if M.can("ReadUserLog") then requestUserlog(user) end
    end, cb)
end
-- the game's own mute is voice alone (/voiceban); chat is ZeD's, on the server's list
function M.mute(user, on, cb)
    act("a_mute", { user = user, on = on }, function()
        SendCommandToServer("/voiceban " .. Q(user) .. (on and " -true" or " -false"))
    end, cb)
end
function M.setRole(user, role, keep, cb)
    act("a_role", { user = user, role = role, keep = keep }, function() networkUserAction("SetRole", user, role) end, cb)
end
-- Level Up and Level Down need the player's own XP, which only the server holds for everyone
function M.skill(user, perk, dir, cb)
    act("a_skill", { user = user, perk = perk, dir = dir }, function(a)
        SendCommandToServer("/addxp " .. Q(user) .. " " .. tostring(a.perk) .. "=" .. tostring(a.amount) .. " -false")
    end, function(a)
        if cb then cb(a) end
        if a.ok and M.live() then M.loadCard(user, true) end
    end)
end

function M.loadCard(user, force)
    if M.qaHold or not M.live() or not M.can("CanSeePlayersStats") then return end
    local t = now()
    if not force and M.cardAskAt and M.cardAskUser == user and t - M.cardAskAt < 3000 then return end
    M.cardAskAt, M.cardAskUser = t, user
    S.send(Adm.MOD, "a_card", { user = user })
end

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
function M.ban(target, reason, len, banIp, sid, cb)
    if M.live() then
        K.requestOn(Adm.MOD, "a_ban", { target = target, reason = reason, len = len, banIp = banIp == true, sid = sid }, function(a)
            if cb then cb(a) end
            M.bump()
        end)
        return
    end
    -- the game's ban, as its own Users List makes it (timed bans are grayed without the server part)
    local kind = Adm.targetKind(target)
    if kind == "ip" then SendCommandToServer("/banip " .. target)
    elseif kind == "sid" then banUnbanUserAction("BanSteamID", target, reason)
    else SendCommandToServer("/banuser " .. Q(target) .. (banIp and " -ip" or "") .. " -r " .. Q(reason)) end
    if cb then cb({ ok = true, fallback = true }) end
    M.bump()
end

-- row: from M.banRows
function M.unban(row, cb)
    if M.live() then
        local args = row.id and { id = row.id } or { target = row.user or row.sid or row.ip }
        K.requestOn(Adm.MOD, "a_unban", args, function(a)
            if cb then cb(a) end
            M.bump()
        end)
        return
    end
    if row.user then banUnbanUserAction("UnBan", row.user, "")
    elseif row.sid then banUnbanUserAction("UnBanSteamID", row.sid, "")
    else banUnbanUserAction("UnBanIPOnly", row.ip, "") end
    if cb then cb({ ok = true, fallback = true }) end
    M.bump()
end

function M.gameBan(id, cb) act("a_gameban", { id = id }, nil, cb) end

-- ZeD's bans and the game's, each once: a row only the game holds has no id, and its who is the game's window
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

function M.banOf(user)
    for _, b in ipairs(M.banRows()) do
        if b.user == user then return b end
    end
    return nil
end

local OWED = {
    Ban = function(a)
        SendCommandToServer("/banuser " .. Q(a.target) .. (a.banIp and " -ip" or "") .. " -r " .. Q(a.reason or ""))
    end,
    Kick = function(a) SendCommandToServer("/kickuser " .. Q(a.target) .. " -r " .. Q(a.reason or "")) end,
    BanSteamID = function(a) banUnbanUserAction("BanSteamID", a.target, a.reason or "") end,
    BanIPOnly = function(a) SendCommandToServer("/banip " .. a.target) end,
    UnBan = function(a) banUnbanUserAction("UnBan", a.target, "") end,
    UnBanSteamID = function(a) banUnbanUserAction("UnBanSteamID", a.target, "") end,
    UnBanIPOnly = function(a) banUnbanUserAction("UnBanIPOnly", a.target, "") end,
}

-- ---------------------------------------------------------------------------
-- SERVER MESSAGES
-- ---------------------------------------------------------------------------
-- every: minutes, or nil for once. The first goes through the game's /servermsg in any case
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

function M.stop(id, cb) act("a_stop", { id = id }, nil, cb) end

-- ---------------------------------------------------------------------------
-- SPAWN ITEMS
-- ---------------------------------------------------------------------------
-- the game's whole list, read once: names sorted, obsolete and hidden left out as its Items List leaves them
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

-- to: "me", "ground" or a username
function M.spawn(full, n, to, cb)
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

-- d: name, desc, color, caps. isNew: the game makes the role, then this waits for it to arrive before filling it in
function M.saveRole(d, isNew, cb)
    roleAct(isNew and "add" or "save", d.name, function()
        if isNew then
            addRole(d.name)
            M.newRole = { d = d, at = now() }
        else
            local r = M.role(d.name)
            if r then setup(r.obj, d) end
        end
        pcall(requestRoles)
        M.rolesAt = nil
    end, cb)
end

function M.deleteRole(name, cb)
    roleAct("delete", name, function()
        deleteRole(name)
        pcall(requestRoles)
        M.rolesAt = nil
    end, cb)
end

function M.defaultRole(name, cb)
    roleAct("default", name, function()
        setDefaultRoleFor("defaultForNewUser", name)
        pcall(requestRoles)
        M.rolesAt = nil
    end, cb)
end

-- dir: 1 up, -1 down, as the game's Roles List
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
    for _, u in ipairs(a.list or {}) do set[u] = true end
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

function on.a_note(a)
    if a.kind == "stay" and ZeD.Messages and ZeD.Messages.adminNote then
        ZeD.Messages.adminNote(tr("UI_ZeD_Adm_NoteStay", tostring(a.user)))
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
-- LEAVING: the server says a ban stands. The reason shows, then the client goes. Phase 5's ban and kick screen takes this
-- over by setting M.leaveScreen(info): info is kind, reason, untilT, by, and it may fill in the appeal line.
-- ---------------------------------------------------------------------------
function on.a_leave(a)
    M.leave = { kind = a.kind, reason = a.reason, untilT = a.untilT, by = a.by, at = now() }
    M.leaveAt = now() + AL.LEAVE_S * 1000
    local show = M.leaveScreen or M.defaultLeave
    if show then
        local ok, err = pcall(show, M.leave)
        if not ok then ZeD.logOnce("admin: leave screen", err) end
    end
end

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
        out[#out + 1] = { ip = b:getIp(), user = b:getUsername(), reason = b:getReason() }
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

-- hello: my Steam ID for a ban on it, and the mutes. The server walks its players anyway; this is the first word.
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
end

-- a muted player: their lines are hidden here (ZeD_Chat.lua reads this), and their own client will not send
function M.isMuted(user) return M.mutes[user] == true end

return M
