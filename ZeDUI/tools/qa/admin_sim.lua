-- ZeDUI/tools/qa/admin_sim.lua  (Nov 5 2026, QA): the admin tools' server side and client model with no game running.
-- Lua 5.1 stubs of the game, in the style of tickets_sim.lua, and the real files run against them: ZeD_TicketProto,
-- ZeD_AdminProto, ZeD_ServerCore, ZeD_ServerTickets, ZeD_ServerAdmin, and on each simulated client ZeD_ServerLink,
-- ZeD_Tickets and ZeD_Admin. Every message crosses a stub of the network with the game's rules, a step at a time.
-- Permissions, hostile arguments, the views, kick, warn, mute, roles and their powers, Level Up, timed bans lifting with
-- nobody on, a client that does not leave, permanent bans owed to a staff client, repeats, spawns, restarts, the fallback.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/admin_sim.lua
-- It prints FAIL lines and a last line "admin_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]admin_sim%.lua$", "")

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

local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end

local function events()
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

local function drain()
    local guard = 0
    while #W.net > 0 do
        guard = guard + 1
        if guard > 100000 then error("the network never drains") end
        table.remove(W.net, 1)()
    end
end
local function net(fn) W.net[#W.net + 1] = fn end

local function step(ms)
    W.clock = W.clock + ms
    W.server.Events.OnTickEvenPaused.fire()
    for _, c in pairs(W.clients) do
        if c.up then c.env.Events.OnTick.fire() end
    end
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

-- the game's capabilities: a name is a value, and an unknown one is nil, as in the enum
local CAPS = {}
for _, n in ipairs({ "None", "SeePlayersConnected", "CanSeePlayersStats", "KickUser", "BanUnbanUser", "AddUserlog", "TeleportToPlayer",
    "TeleportPlayerToAnotherPlayer", "ChangeAccessLevel", "ModifyNetworkUsers", "AddXP", "DisplayServerMessage", "AddItem",
    "RolesWrite", "RolesRead", "CantBeKickedByUser", "CantBeBannedByUser", "ToggleInvisibleHimself", "ToggleNoclipHimself",
    "ToggleGodModHimself", "AnswerTickets", "SeeNetworkUsers", "ReadUserLog", "TeleportToCoordinates" }) do CAPS[n] = n end

local function role(name, pos, caps)
    local r = { name = name, pos = pos, caps = caps }
    function r.getName(self) return self.name end
    function r.getPosition(self) return self.pos end
    function r.hasCapability(self, cap)
        if cap == nil then error("No implementation found: hasCapability(nil)") end
        return self.caps[cap] == true
    end
    function r.hasAdminPower(self) return self.pos >= 3 end
    return r
end
local function all(list)
    local t = {}
    for _, c in ipairs(list) do t[c] = true end
    return t
end
local MOD_CAPS = { "SeePlayersConnected", "CanSeePlayersStats", "KickUser", "BanUnbanUser", "AddUserlog", "TeleportToPlayer", "TeleportPlayerToAnotherPlayer",
    "ChangeAccessLevel", "ModifyNetworkUsers", "AddXP", "DisplayServerMessage", "AddItem", "AnswerTickets", "ToggleInvisibleHimself", "ToggleNoclipHimself",
    "ToggleGodModHimself", "SeeNetworkUsers", "RolesRead", "ReadUserLog" }
local ADMIN_CAPS = { "RolesWrite", "CantBeKickedByUser", "CantBeBannedByUser" }
for _, c in ipairs(MOD_CAPS) do ADMIN_CAPS[#ADMIN_CAPS + 1] = c end
local ROLES = {
    banned = role("banned", 0, {}),
    user = role("user", 1, {}),
    gm = role("gm", 2, all({ "AddItem", "ToggleGodModHimself", "ToggleInvisibleHimself", "SeePlayersConnected" })),
    moderator = role("moderator", 3, all(MOD_CAPS)),
    admin = role("admin", 4, all(ADMIN_CAPS)),
}
local ROLE_LIST = { ROLES.banned, ROLES.user, ROLES.gm, ROLES.moderator, ROLES.admin }

local XP = { 75, 150, 300, 750, 1500, 3000, 4500, 6000, 7500, 9000 }
local function perkOf(name, parent)
    local p = { name = name, parent = parent }
    function p.getParent(self) return self.parent end
    function p.getName(self) return self.name end
    function p.getTotalXpForLevel(self, lv)
        local n = 0
        for i = 1, lv do n = n + XP[i] end
        return n
    end
    return setmetatable(p, { __tostring = function(self) return self.name end })
end
local PERK_NONE = perkOf("None")
local PERKS = { perkOf("Woodwork", PERK_NONE), perkOf("Cooking", PERK_NONE) }
PERKS[1].parent = perkOf("Crafting", nil)
PERKS[2].parent = perkOf("Crafting", nil)
local PERK_LIST = { PERK_NONE, PERKS[1], PERKS[2] }
PERK_NONE.parent = PERK_NONE

local function player(name, roleName, x, y, z)
    local p = { name = name, role = ROLES[roleName or "user"], x = x or 6280.5, y = y or 5350.5, z = z or 0, box = {}, levels = { Woodwork = 3 }, xp = { Woodwork = 525 }, items = {} }
    function p.getUsername(self) return self.name end
    function p.getRole(self) return self.role end
    function p.getX(self) return self.x end
    function p.getY(self) return self.y end
    function p.getZ(self) return self.z end
    function p.getOnlineID(self) return 7 end
    function p.getSteamID(self) return self.steamNum or 0 end
    function p.getDescriptor(self)
        return { getCharacterProfession = function() return "carpenter" end }
    end
    function p.getCharacterTraits(self)
        return { getKnownTraits = function() return jlist({ "Handy" }) end }
    end
    function p.getPerkLevel(self, perk) return self.levels[perk.name] or 0 end
    function p.getXp(self)
        return { getXP = function(_, perk) return self.xp[perk.name] or 0 end }
    end
    function p.getInventory(self)
        return { AddItem = function(_, t)
            if type(t) ~= "string" then error("AddItem overload") end
            self.items[#self.items + 1] = t
            return { type = t }
        end }
    end
    function p.getCurrentSquare(self)
        return { AddWorldInventoryItem = function(_, t, a, b, c)
            W.ground[#W.ground + 1] = t
            return { type = t }
        end }
    end
    function p.setGhostMode(self, v) self.ghost = v end
    function p.setNoClip(self, v) self.noclip = v end
    function p.setGodMod(self, v) self.god = v end
    W.online[#W.online + 1] = p
    W.players[name] = p
    return p
end
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
    env.getRoles = function() return jlist(ROLE_LIST) end
    return env
end
local function runFile(env, rel)
    local f = assert(loadfile(ROOT .. rel))
    setfenv(f, env)
    return f()
end
local FILES = {
    ["ZeD/ZeD_TicketProto"] = "42/media/lua/shared/ZeD/ZeD_TicketProto.lua",
    ["ZeD/ZeD_AdminProto"] = "42/media/lua/shared/ZeD/ZeD_AdminProto.lua",
    ["ZeD/ZeD_ServerCore"] = "42/media/lua/server/ZeD/ZeD_ServerCore.lua",
    ["ZeD/ZeD_ServerTickets"] = "42/media/lua/server/ZeD/ZeD_ServerTickets.lua",
    ["ZeD/ZeD_ServerLink"] = "42/media/lua/client/ZeD/ZeD_ServerLink.lua",
    ["ZeD/ZeD_Tickets"] = "42/media/lua/client/ZeD/ZeD_Tickets.lua",
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
    env.getServerOptions = function() return { getInteger = function() return 0 end } end
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
        transmit = function() error("the admin table must never be transmitted") end,
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
    env.Perks = { None = PERK_NONE, getMaxIndex = function() return #PERK_LIST end, fromIndex = function(i) return PERK_LIST[i + 1] end }
    env.PerkFactory = { getPerk = function(p) return p end }
    env.CharacterProfessionDefinition = { getCharacterProfessionDefinition = function() return { getUIName = function() return "Carpenter" end } end }
    env.CharacterTraitDefinition = { getCharacterTraitDefinition = function(t) return { getLabel = function() return t end } end }
    env.getScriptManager = function()
        return { FindItem = function(_, s)
            if type(s) ~= "string" then error("FindItem overload") end
            return W.scripts[s]
        end }
    end
    env.sendAddItemToContainer = function(inv, it) W.sent = W.sent + 1 end
    env.ISLogSystem = { writeLog = function(who, packet) W.logs[#W.logs + 1] = { name = packet.loggerName, line = packet.logText } end }
    runFile(env, FILES["ZeD/ZeD_TicketProto"])
    env.loaded["ZeD/ZeD_TicketProto"] = true
    runFile(env, FILES["ZeD/ZeD_AdminProto"])
    env.loaded["ZeD/ZeD_AdminProto"] = true
    runFile(env, FILES["ZeD/ZeD_ServerCore"])
    env.loaded["ZeD/ZeD_ServerCore"] = true
    runFile(env, FILES["ZeD/ZeD_ServerTickets"])
    env.loaded["ZeD/ZeD_ServerTickets"] = true
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerAdmin.lua")
    env.Events.OnInitGlobalModData.fire(false)
    return env
end

local function cap1(role_, name) return role_.caps[name] == true end

local function clientJoin(p)
    local env = baseEnv()
    local c = { env = env, p = p, up = true, slash = {}, game = {}, left = 0, extra = 0 }
    W.clients[p.name] = c
    env.isServer = function() return false end
    env.isClient = function() return true end
    env.require = function(n) requireIn(env, n) end
    env.getPlayer = function() return p end
    env.getTextOrNull = function() return nil end
    env.ZeD = {
        tr = function(k) return k end,
        logOnce = function(k, m) check("no client error", false, tostring(k) .. ": " .. tostring(m)) end,
        Messages = { ticket = function() end, ticketNew = function() end, adminNote = function(t) c.game[#c.game + 1] = "note:" .. t end },
    }
    env.ISAdminMessage = { AddAdminMessage = function() end }
    env.getTickets, env.addTicket = function() end, function() end
    env.sendClientCommand = function(pl, module, command, args)
        local a = wire(args)
        net(function()
            if W.server.Events.OnClientCommand then W.server.Events.OnClientCommand.fire(module, command, pl, a) end
        end)
    end
    env.SendCommandToServer = function(s)
        c.slash[#c.slash + 1] = s
        -- the game's rules (BanSystem): with -ip the player must be on and not on a Steam connection, or nothing happens
        local u = string.match(s, '^/banuser "([^"]*)"')
        local o = u and W.players[u]
        local isOn = false
        for _, x in ipairs(W.online) do isOn = isOn or x == o end
        if u and string.find(s, " -ip", 1, true) then
            if isOn and not o.steamConn then
                W.gameBans[u], W.gameIps[u] = true, true
                offline(o)
            end
        elseif u then
            W.gameBans[u] = true
            if isOn then offline(o) end
        end
    end
    env.banUnbanUserAction = function(a, b, r) c.game[#c.game + 1] = a .. ":" .. b .. ":" .. r end
    env.networkUserAction = function(a, b, r)
        c.game[#c.game + 1] = a .. ":" .. b .. ":" .. r
        local o = W.players[b]
        -- the game applies a role, and switches on what the old role lacked (GameServer.changeRole)
        if a == "SetRole" and o then
            local new = ROLES[r]
            if new.caps.ToggleInvisibleHimself and not o.role.caps.ToggleInvisibleHimself then o.ghost = true end
            if new.caps.ToggleNoclipHimself and not o.role.caps.ToggleNoclipHimself then o.noclip = true end
            if new.caps.ToggleGodModHimself and not o.role.caps.ToggleGodModHimself then o.god = true end
            o.role = new
        end
    end
    env.addWarningPoint = function(u, r, n) c.game[#c.game + 1] = "warn:" .. u .. ":" .. r .. ":" .. n end
    env.requestUsers, env.requestRoles, env.requestUserlog = function() end, function() end, function() end
    env.getBannedIPs, env.getBannedSteamIDs = function() end, function() end
    env.getSteamModeActive = function() return false end
    env.getCurrentUserSteamID = function() return c.sid end
    env.getUsers = function() return jlist({}) end
    env.getCapabilities = function()
        local list = {}
        for n in pairs(CAPS) do list[#list + 1] = { name = function() return n end, n = n } end
        return jlist(list)
    end
    env.forceDisconnect = function()
        c.left = c.left + 1
        offline(p)
    end
    env.sendPlayerExtraInfo = function() c.extra = c.extra + 1 end
    env.ISAdminPowerUI = { OptionById = {} }
    for _, id in ipairs({ "Invisible", "NoClip", "GodMod" }) do
        env.ISAdminPowerUI.OptionById[id] = { setValue = function(_, v) c.game[#c.game + 1] = "power:" .. id .. ":" .. tostring(v) end }
    end
    runFile(env, FILES["ZeD/ZeD_TicketProto"])
    env.loaded["ZeD/ZeD_TicketProto"] = true
    runFile(env, FILES["ZeD/ZeD_AdminProto"])
    env.loaded["ZeD/ZeD_AdminProto"] = true
    runFile(env, FILES["ZeD/ZeD_ServerLink"])
    env.loaded["ZeD/ZeD_ServerLink"] = true
    runFile(env, FILES["ZeD/ZeD_Tickets"])
    env.loaded["ZeD/ZeD_Tickets"] = true
    runFile(env, "42/media/lua/client/ZeD/ZeD_Admin.lua")
    env.Events.OnCreatePlayer.fire(0, p)
    advance(500)
    return c
end

local function world()
    W = { clock = 1793913240000, net = {}, logs = {}, online = {}, players = {}, clients = {}, moddata = {}, hours = 12.5 * 24,
        uuid = 0, scripts = { ["Base.Axe"] = true }, ground = {}, sent = 0, gameBans = {}, gameIps = {} }
    serverStart()
end

-- a raw command, as a client with a Lua console could send it
local function say(p, command, args)
    p.box = {}
    local a = wire(args)
    net(function() W.server.Events.OnClientCommand.fire("ZeDA", command, p, a) end)
    drain()
end
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
local function okOf(p)
    local a = got(p, "t_ack")
    return a and a.ok == true
end
local function A() return W.server.ZeD.Srv.A end
local function md() return A().md end
local function logHas(text)
    for _, l in ipairs(W.logs) do
        if string.find(l.line, text, 1, true) then return true end
    end
    return false
end
local function has(list, s)
    for _, v in ipairs(list) do
        if v == s or string.find(v, s, 1, true) then return true end
    end
    return false
end
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
-- the limits' memory cleared, so a run needs no waits
local function nolimit(p) W.server.ZeD.Srv.mem[p.name] = nil end
local function M(c) return c.env.ZeD.Admin end

local function boot()
    world()
    local a = player("Hermit", "admin")
    local ca = clientJoin(a)
    return a, ca
end

-- ---------------------------------------------------------------------------
section("the table and the hello")
do
    local a, ca = boot()
    local name = nil
    for k in pairs(W.moddata) do
        if string.sub(k, 1, 7) == "ZeD_AD_" then name = k end
    end
    check("a secret admin table exists", name ~= nil)
    for _, l in ipairs(W.logs) do check("the name is in no log", not string.find(l.line, tostring(name), 1, true)) end
    check("hello says the tools are here", ca.env.ZeD.ServerPart.adm == true)
    check("the tools read as live", M(ca).live())
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    check("a plain player's hello: no staff words", cu.env.ZeD.ServerPart.staff == false)
    -- restart: the same table
    local before = md()
    before.bans[9] = { id = 9, user = "x", reason = "r", by = "Hermit", at = 1 }
    W.server = nil
    serverStart()
    W.server.ZeD.Srv.adminTick()
    check("a restart keeps the table", md() == before and md().bans[9] ~= nil)
    -- a table from a newer ZeD freezes writes
    md().schema = 99
    A().md, A().frozen = nil, nil
    serverStart()
    W.server.ZeD.Srv.adminTick()
    nolimit(a)
    say(a, "a_ban", { target = "Kade", reason = "x", len = "d1" })
    check("frozen: a write answers frozen", errOf(a) == "frozen")
    say(a, "a_bans", {})
    check("frozen: reads work", got(a, "a_bans") ~= nil)
end

section("who may do what")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    local cases = { a_players = {}, a_card = { user = "Hermit" }, a_tp = { user = "Hermit" }, a_bring = { user = "Hermit" }, a_kick = { user = "Hermit", reason = "x" },
        a_warn = { user = "Hermit", n = 1, reason = "x" }, a_mute = { user = "Hermit", on = true }, a_role = { user = "Hermit", role = "user" }, a_skill = { user = "Hermit", perk = "Woodwork", dir = 1 },
        a_ban = { user = "Hermit", reason = "x", len = "d1" }, a_unban = { id = 1 }, a_bans = {}, a_gameban = { id = 1 }, a_msg = { text = "x" }, a_repeat = { text = "x", every = 15 },
        a_stop = { id = 1 }, a_repeats = {}, a_spawn = { item = "Base.Axe", n = 1, to = "me" }, a_rolelog = { what = "save", role = "x" } }
    for cmd, args in pairs(cases) do
        nolimit(u)
        say(u, cmd, args)
        check("a plain player: " .. cmd .. " answers perm", errOf(u) == "perm", tostring(errOf(u)))
    end
    check("a refusal writes one line a minute at most", logHas("has no right to"))
    -- a moderator cannot edit roles, an admin can
    local m = player("Rosa", "moderator")
    say(m, "a_rolelog", { what = "save", role = "gm" })
    check("a moderator cannot write roles", errOf(m) == "perm")
    say(a, "a_rolelog", { what = "save", role = "gm" })
    check("an admin can", okOf(a))
    check("it is logged", logHas("admin | roles: save | Hermit | gm |"))
    -- an act needs both of the role's powers
    local gmUser = player("Gale", "gm")
    say(gmUser, "a_role", { user = "Kade", role = "user" })
    check("a role change needs ChangeAccessLevel", errOf(gmUser) == "perm")
end

section("hostile arguments")
do
    local a = boot()
    local bad = { { "a_card", { user = { 1 } } }, { "a_card", { user = 5 } }, { "a_kick", { user = "Kade\nHermit", reason = "x" } }, { "a_kick", { user = string.rep("x", 99), reason = "x" } },
        { "a_warn", { user = "Kade", n = 11, reason = "x" } }, { "a_warn", { user = "Kade", n = 1.5, reason = "x" } }, { "a_warn", { user = "Kade", n = "1", reason = "x" } }, { "a_warn", { user = "Kade", n = 1 } },
        { "a_ban", { target = "Kade", reason = "x", len = "ever" } }, { "a_ban", { target = "Kade", reason = "", len = "d1" } }, { "a_ban", { target = "Kade", reason = string.rep("x", 201), len = "d1" } }, { "a_ban", { target = { 1 }, reason = "x", len = "d1" } },
        { "a_ban", { reason = "x", len = "d1" } }, { "a_role", { user = "Kade", role = 5 } }, { "a_role", { user = "Kade", role = "noone" } },
        { "a_skill", { user = "Hermit2", perk = "Woodwork", dir = 2 } }, { "a_repeat", { text = "x", every = 7 } }, { "a_repeat", { text = "", every = 15 } }, { "a_repeat", { text = string.rep("x", 201), every = 15 } },
        { "a_stop", { id = "1" } }, { "a_stop", { id = -1 } }, { "a_unban", { id = 1.5 } }, { "a_unban", { target = {} } }, { "a_spawn", { item = "Base.Axe", n = 0, to = "me" } }, { "a_spawn", { item = "Base.Axe", n = 101, to = "me" } },
        { "a_spawn", { item = "Base/../x", n = 1, to = "me" } }, { "a_spawn", { item = 5, n = 1, to = "me" } }, { "a_spawn", { item = "Base.Nope", n = 1, to = "me" } }, { "a_spawn", { item = "Base.Axe", n = 1, to = {} } }, { "a_rolelog", { what = "own", role = "x" } } }
    for i, c in ipairs(bad) do
        nolimit(a)
        say(a, c[1], c[2])
        local ack = got(a, "t_ack")
        check("bad args " .. i .. " " .. c[1] .. " refused", ack ~= nil and ack.ok == false, tostring(ack and ack.err))
    end
    check("nothing got on the ban list", next(md().bans) == nil)
    nolimit(a)
    say(a, "a_ban")
    check("no args at all is refused", errOf(a) == "text")
end

section("kick, warn, teleport, mute")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    M(ca).kick("Kade", "Spamming chat", function(r) ca.r = r end)
    drain()
    check("kick acks", ca.r and ca.r.ok == true)
    check("the game's kick carries the reason", has(ca.slash, '/kickuser "Kade" -r "Spamming chat"'), ca.slash[1])
    check("kick logged, with place and reason", logHas("admin | kick | Hermit | Kade | 6280,5350,0 | Spamming chat | day"))
    ca.slash = {}
    M(ca).kick("Hermit", "x", function(r) ca.r = r end)
    drain()
    check("no kicking yourself", ca.r.err == "self" and #ca.slash == 0)
    M(ca).kick("Ghost", "x", function(r) ca.r = r end)
    drain()
    check("no kicking someone offline", ca.r.err == "offline" and #ca.slash == 0)
    local m = player("Rosa", "moderator")
    local cm = clientJoin(m)
    M(cm).kick("Hermit", "x", function(r) cm.r = r end)
    drain()
    check("an admin cannot be kicked by a moderator", cm.r.err == "protected", tostring(cm.r.err))
    a.role = role("owner2", 9, {})
    local higher = a.role
    ROLES.admin.caps.CantBeKickedByUser = nil
    M(cm).kick("Hermit", "x", function(r) cm.r = r end)
    drain()
    check("no acting on a role above yours", cm.r.err == "rank", tostring(cm.r.err))
    ROLES.admin.caps.CantBeKickedByUser = true
    a.role = ROLES.admin
    M(ca).warn("Kade", 2, "Took the generator", function(r) ca.r = r end)
    drain()
    check("warning points go through the game", has(ca.game, "warn:Kade:Took the generator:2"))
    check("warning logged", logHas("admin | warning points | Hermit | Kade |"))
    M(ca).teleport("Kade")
    drain()
    check("teleport goes as the game's", has(ca.slash, '/teleport "Kade"'))
    M(ca).bring("Kade")
    drain()
    check("bring goes as the game's", has(ca.slash, '/teleportplayer "Kade" "Hermit"'))
    check("both logged", logHas("admin | teleport to | Hermit |") and logHas("admin | teleport to you | Hermit |"))
    M(ca).mute("Kade", true)
    drain()
    check("mute: voice goes through the game", has(ca.slash, '/voiceban "Kade" -true'))
    check("mute: every client knows", M(cu).isMuted("Kade") and M(ca).isMuted("Kade"))
    local late = player("Tjk", "user")
    local cl = clientJoin(late)
    check("a player who joins later knows too", M(cl).isMuted("Kade"))
    advance(5000)
    M(ca).mute("Kade", false)
    drain()
    check("unmute", not M(cu).isMuted("Kade"))
end

section("roles and their powers")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    clientJoin(u)
    M(ca).setRole("Kade", "moderator", { "GodMod" }, function(r) ca.r = r end)
    drain()
    check("a role change acks", ca.r.ok == true)
    check("the game's call", has(ca.game, "SetRole:Kade:moderator"))
    check("the game switched them on", u.ghost == true and u.noclip == true and u.god == true)
    advance(1000)
    check("off unless ticked: invisible", u.ghost == false)
    check("off unless ticked: no clip", u.noclip == false)
    check("kept: god mode", u.god == true)
    local cu = W.clients.Kade
    check("their client switches them off with the game's own setter", has(cu.game, "power:Invisible:false") and has(cu.game, "power:NoClip:false") and not has(cu.game, "power:GodMod"))
    check("and tells the server", cu.extra == 1)
    check("nothing left to watch", next(md().watch) == nil)
    check("role logged", logHas("admin | role | Hermit | Kade |"))
    -- no one past their own rank
    local m = player("Rosa", "moderator")
    local cm = clientJoin(m)
    M(cm).setRole("Kade", "admin", nil, function(r) cm.r = r end)
    drain()
    check("no role above your own", cm.r.err == "rank")
    M(cm).setRole("Hermit", "user", nil, function(r) cm.r = r end)
    drain()
    check("no change to a role above your own", cm.r.err == "rank")
    M(cm).setRole("Rosa", "user", nil, function(r) cm.r = r end)
    drain()
    check("not your own", cm.r.err == "self")
    -- a role the game never applied: the watch runs out
    md().players.Gone = { t = 1, role = "user" }
    say(a, "a_role", { user = "Gone", role = "user" })
    check("an offline player's role can change", okOf(a))
    advance(31000)
    check("the watch waits for someone who isn't on", md().watch.Gone ~= nil)
    W.clock = W.clock + 86400 * 1000
    advance(1000)
    check("and then runs out", next(md().watch) == nil)
    nolimit(a)
    say(a, "a_role", { user = "Never", role = "user" })
    check("a name never seen has no rank to test", errOf(a) == "unknown")
end

section("level up and down")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    clientJoin(u)
    M(ca).skill("Kade", "Woodwork", 1, function(r) ca.r = r end)
    drain()
    check("level up: the sum the game's window makes", ca.r.ok and ca.r.amount == 1275 - 525, tostring(ca.r.amount))
    check("through /addxp", has(ca.slash, '/addxp "Kade" Woodwork=750 -false'), ca.slash[1])
    nolimit(a)
    M(ca).skill("Kade", "Woodwork", -1, function(r) ca.r = r end)
    drain()
    check("level down", ca.r.ok and ca.r.amount == 225 - 525, tostring(ca.r.amount))
    u.levels.Woodwork = 0
    nolimit(a)
    say(a, "a_skill", { user = "Kade", perk = "Woodwork", dir = -1 })
    check("not below 0", errOf(a) == "state")
    u.levels.Woodwork = 10
    nolimit(a)
    say(a, "a_skill", { user = "Kade", perk = "Woodwork", dir = 1 })
    check("not past 10", errOf(a) == "state")
    nolimit(a)
    say(a, "a_skill", { user = "Kade", perk = "Nothing", dir = 1 })
    check("an unknown skill", errOf(a) == "gone")
    nolimit(a)
    say(a, "a_skill", { user = "Ghost", perk = "Woodwork", dir = 1 })
    check("an offline player", errOf(a) == "offline")
end

section("the players list and the card")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    advance(6000)
    nolimit(a)
    say(a, "a_players", {})
    local p = got(a, "a_players")
    check("both online", #p.rows == 2 and p.rows[1].on and p.rows[2].on)
    offline(u)
    advance(6000)
    nolimit(a)
    say(a, "a_players", {})
    p = got(a, "a_players")
    local off = nil
    for _, r in ipairs(p.rows) do if r.u == "Kade" then off = r end end
    check("offline, with last seen and role", off and off.on == false and off.last and off.role == "user")
    say(a, "a_card", { user = "Kade" })
    local c = got(a, "a_card")
    check("the offline card comes from the last look", c and c.on == false and c.prof == "Carpenter" and c.traits[1] == "Handy" and c.skills[1].lv == 3)
    check("no place when they are off the map", c.x == nil)
    nolimit(a)
    say(a, "a_card", { user = "Hermit" })
    c = got(a, "a_card")
    check("online: where, and every skill", c.x == 6280 and #c.skills == 2, c.x)
    local allowed = { user = 1, on = 1, muted = 1, last = 1, prof = 1, traits = 1, skills = 1, role = 1, x = 1, y = 1, z = 1, oid = 1, tickets = 1, ticketN = 1, banId = 1, banUntil = 1, hidden = 1, closed = 1, id = 1, name = 1, lv = 1 }
    for k in pairs(keysIn(c)) do
        if type(k) == "string" then check("the card is an allowlist: " .. k, allowed[k] ~= nil) end
    end
    nolimit(a)
    say(a, "a_card", { user = "Nobody" })
    c = got(a, "a_card")
    check("someone never seen: a card with their name", c.user == "Nobody" and c.on == false)
    -- the model merges
    W.clock = W.clock + 6000
    M(ca).watch()
    drain()
    check("the model's list has both", #M(ca).rows == 2, #M(ca).rows)
    check("online first", M(ca).rows[1].user == "Hermit")
    check("Find: a name", #M(ca).findRows("kad", false) == 1)
    check("Find: a role", #M(ca).findRows("admin", false) == 1)
    check("Online only", #M(ca).findRows("", true) == 1)
    check("a pattern is only words", #M(ca).findRows("%", false) == 0)
    -- the cap on the remembered players: oldest out
    for i = 1, 2100 do md().players["old" .. i] = { t = i } end
    for i = 1, 150 do W.server.ZeD.Srv.A.walkAt = nil; W.clock = W.clock + 1000; W.server.ZeD.Srv.adminTick() end
    local n = 0
    for _ in pairs(md().players) do n = n + 1 end
    check("the remembered players stay near their cap", n <= 2102 and n >= 2000, n)
end

section("timed bans")
do
    local a, ca = boot()
    local u = player("Torch", "user")
    local cu = clientJoin(u)
    M(ca).ban("Torch", "Burned the farm, twice", "d3", false, function(r) ca.r = r end)
    drain()
    check("the ban acks", ca.r.ok == true and ca.r.untilT ~= nil)
    check("their client is told to leave, with the reason", M(cu).leave and M(cu).leave.reason == "Burned the farm, twice" and M(cu).leave.untilT == ca.r.untilT)
    check("it is logged", logHas("admin | ban | Hermit | Torch |"))
    check("staff read it", #M(ca).bans == 1 and M(ca).bans[1].by == "Hermit")
    check("no game ban for a timed one", not has(ca.slash, "/banuser"))
    advance(6000)
    check("the reason shows first", cu.left == 0)
    advance(7000)
    check("then the client goes", cu.left == 1)
    advance(3000)
    check("gone on their own: no kick on their record", not has(ca.slash, "/kickuser") and next(md().owed) == nil)
    offline(u)
    offline(a)
    -- nobody on: it lifts to the second
    W.clock = W.clock + 259200 * 1000 - 20000
    W.server.Events.OnTickEvenPaused.fire()
    check("not yet", next(md().bans) ~= nil)
    W.clock = W.clock + 21000
    W.server.Events.OnTickEvenPaused.fire()
    check("lifted with nobody on", next(md().bans) == nil)
    check("the lift is logged", logHas("admin | ban lifted | @server | Torch |"))
end

section("a client that does not leave")
do
    local a, ca = boot()
    local u = player("Torch", "user")
    local cu = clientJoin(u)
    cu.env.forceDisconnect = function() end       -- (a modified client: it reads a_leave and stays)
    say(a, "a_ban", { user = "Torch", reason = "Griefing", len = "w1" })
    drain()
    advance(16000)
    check("a real kick backs up a client that stays", has(ca.slash, '/kickuser "Torch" -r "Griefing"'))
    offline(u)
    advance(6000)
    -- they come back on a modified client: told again, stays
    W.online[#W.online + 1] = u
    u.box = {}
    W.clients.Torch.up = false
    advance(6000)
    check("told on joining, with the server's own eyes", got(u, "a_leave") ~= nil)
    advance(21000)
    check("staff hear it", has(ca.game, "note:UI_ZeD_Adm_NoteStay"))
    check("and it is on the ban", md().bans[1].stay ~= nil)
    check("a line in the log", logHas("has not left"))
    local n = #ca.game
    advance(30000)
    check("not again at once", #ca.game == n)
    advance(300000)
    check("again after five minutes", #ca.game > n)
    -- the game's ban is one press away, and lifts with the timed one through a staff client
    nolimit(a)
    say(a, "a_gameban", { id = 1 })
    check("the game's ban acks", okOf(a))
    advance(2000)
    check("it goes through the staff client", has(ca.slash, '/banuser "Torch" -r "Griefing"'))
    W.clock = W.clock + 604800 * 1000
    advance(2000)
    check("and comes off when the time runs out", has(ca.game, "UnBan:Torch:"))
end

section("permanent bans")
do
    local a, ca = boot()
    local u = player("Loot", "user")
    local cu = clientJoin(u)
    say(a, "a_ban", { user = "Loot", reason = "Scam spam", len = "perm", banIp = true })
    check("acks", okOf(a))
    check("no end date", got(a, "t_ack").untilT == nil)
    drain()
    check("the reason shows on their client", M(cu).leave.reason == "Scam spam")
    check("not banned in the game yet", not has(ca.slash, "/banuser"))
    check("they wait on the reason: no Leave, and the client's clock is the long one", M(cu).leave.hold == true and cu.left == 0)
    advance(13000)
    check("the game's ban, with the IP", has(ca.slash, '/banuser "Loot" -ip -r "Scam spam"'), ca.slash[1])
    check("while they are still on", W.gameIps.Loot == true and W.gameBans.Loot == true)
    advance(4000)
    check("the plain ban always follows", has(ca.slash, '/banuser "Loot" -r "Scam spam"'))
    check("done", next(md().owed) == nil)
    check("the IP stays on the row", md().bans[1].banIp == true and md().bans[1].made == true)
    check("the record stays", md().bans[1] ~= nil and md().bans[1].untilT == nil)
    -- it does not lift
    W.clock = W.clock + 3650 * 86400 * 1000
    advance(1000)
    check("a permanent ban stays", md().bans[1] ~= nil)
    -- Unban behind the game's call
    M(ca).bans = M(ca).bans
    nolimit(a)
    M(ca).unban({ id = 1 }, function(r) ca.r = r end)
    advance(1000)
    check("unban acks", ca.r.ok == true)
    check("the game's unban, with the IP", has(ca.game, "UnBanIP:Loot:"))
    check("off the list", next(md().bans) == nil)

    -- the actor leaves before it lands: another staff member makes the call
    local m = player("Rosa", "moderator")
    local cm = clientJoin(m)
    local v = player("Mike", "user")
    clientJoin(v)
    nolimit(a)
    say(a, "a_ban", { user = "Mike", reason = "Griefing", len = "perm" })
    offline(a)
    advance(13000)
    check("another staff member makes the call", has(cm.slash, '/banuser "Mike" -r "Griefing"'))
    -- with no staff on it waits
    nolimit(m)
    say(m, "a_ban", { target = "Absent", reason = "x", len = "perm" })
    check("a name the server never met: the game's to judge", got(m, "t_ack").unknown == true)
    offline(m)
    advance(30000)
    local waiting = next(md().owed)
    check("with no staff on it waits", waiting ~= nil)
    local back = player("Hermit", "admin")
    W.clients.Hermit = nil
    local c2 = clientJoin(back)
    advance(2000)
    check("and lands when someone returns", has(c2.slash, '/banuser "Absent" -r "x"'))
    -- no word back: it goes again
    player("Nobody", "user")
    local e = { id = 99, act = "Kick", target = "Nobody", reason = "x", at = 0 }
    md().owed[99] = e
    local realDone = c2.env.ZeD.ServerPart.send
    c2.env.ZeD.ServerPart.send = function(m2, c3, a2) if c3 == "a_done" then return true end return realDone(m2, c3, a2) end
    advance(1000)
    c2.slash = {}
    advance(16000)
    check("no word back: it goes again", has(c2.slash, '/kickuser "Nobody"'))
    c2.env.ZeD.ServerPart.send = realDone
    md().owed[99] = nil
end

section("offline bans: a name, a Steam ID, an IP")
do
    local a, ca = boot()
    say(a, "a_ban", { target = "76561198000000002", reason = "Alt", len = "perm" })
    check("a Steam ID acks", okOf(a))
    advance(1000)
    check("through the game's Steam ban, with its reason", has(ca.game, "BanSteamID:76561198000000002:Alt"))
    nolimit(a)
    say(a, "a_ban", { target = "203.0.113.7", reason = "Alt", len = "perm" })
    advance(1000)
    check("an IP through /banip", has(ca.slash, "/banip 203.0.113.7"))
    nolimit(a)
    say(a, "a_ban", { target = "203.0.113.8", reason = "Alt", len = "d1" })
    check("a timed IP is refused", errOf(a) == "ipperm")
    nolimit(a)
    say(a, "a_ban", { target = "Someone", reason = "Alt", len = "d1", banIp = true })
    check("Ban IP too on a timed ban is refused", errOf(a) == "ipperm")
    nolimit(a)
    say(a, "a_ban", { target = "76561198000000009", reason = "Alt", len = "d1" })
    check("a timed Steam ID is ZeD's", okOf(a))
    local u = player("NewName", "user")
    u.steamNum = 76561198000000009
    local cu = clientJoin(u)
    cu.sid = "76561198000000009"
    nolimit(u)
    W.server.ZeD.Srv.mem.NewName = nil
    say(u, "a_hi", { sid = cu.sid })
    drain()
    check("a new account on that Steam ID is told to leave", M(cu).leave ~= nil)
    -- a ban only the game holds: unban by what the row knows
    nolimit(a)
    M(ca).unban({ sid = "76561198000000123", game = true }, function(r) ca.r = r end)
    advance(1000)
    check("a ban only the game holds lifts through the game", has(ca.game, "UnBanSteamID:76561198000000123:"))
    M(ca).gameSids = { { sid = "76561198000000555", reason = "old" } }
    local rows = M(ca).banRows()
    local found = false
    for _, r in ipairs(rows) do if r.sid == "76561198000000555" then found = r.game == true end end
    check("the game's list shows beside ZeD's", found)
end

section("server messages")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    local lines = {}
    cu.env.ZeD.Chat = { serverLine = function(s) lines[#lines + 1] = s end }
    M(ca).message("Hello there", nil, function(r) ca.r = r end)
    drain()
    check("once: the game's /servermsg", has(ca.slash, '/servermsg "Hello there"'))
    check("logged", logHas("admin | server message | Hermit | - | 6280,5350,0"))
    ca.slash = {}
    M(ca).message("Trading post Saturday", 15, function(r) ca.r = r end)
    drain()
    check("a repeat goes once now", has(ca.slash, '/servermsg "Trading post Saturday"'))
    check("staff see the Stop list", #M(ca).repeats == 1 and M(ca).repeats[1].every == 15)
    advance(14 * 60000)
    check("not before its time", #lines == 0)
    advance(61000)
    check("after 15 minutes every client gets it", #lines == 1 and lines[1] == "Trading post Saturday", #lines)
    advance(15 * 60000)
    check("and again", #lines == 2, #lines)
    offline(u)
    offline(a)
    W.clock = W.clock + 3600 * 1000
    W.server.Events.OnTickEvenPaused.fire()
    W.server.Events.OnTickEvenPaused.fire()
    check("nobody on: the clock runs and nothing bursts", (select(2, next(md().repeats))).nextAt > W.clock / 1000)
    W.online[#W.online + 1] = a
    W.clients.Hermit.up = true
    W.clients.Kade.up = false
    local n = #lines
    say(a, "a_stop", { id = 1 })
    check("Stop acks", okOf(a))
    check("the list is empty", next(md().repeats) == nil)
    for i = 1, 11 do
        nolimit(a)
        say(a, "a_repeat", { text = "line " .. i, every = 60 })
    end
    check("ten at most", errOf(a) == "full")
end

section("spawn items")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    clientJoin(u)
    M(ca).spawn("Base.Axe", 5, "me", function(r) ca.r = r end)
    drain()
    check("to me", ca.r.ok and #a.items == 5 and W.sent == 5)
    check("logged", logHas("admin | spawn | Hermit | - | 6280,5350,0 | 5 x Base.Axe to me | day"))
    nolimit(a)
    say(a, "a_spawn", { item = "Base.Axe", n = 2, to = "Kade" })
    check("to a player", #u.items == 2)
    check("logged with the player", logHas("admin | spawn | Hermit | Kade |"))
    nolimit(a)
    say(a, "a_spawn", { item = "Base.Axe", n = 100, to = "ground" })
    check("the ground, a hundred", #W.ground == 100)
    nolimit(a)
    say(a, "a_spawn", { item = "Base.Axe", n = 1, to = "Nobody" })
    check("a player who isn't on", errOf(a) == "offline")
    nolimit(a)
    say(a, "a_spawn", { item = "Base.Axe", n = 1, to = "me" })
    say(a, "a_spawn", { item = "Base.Axe", n = 1, to = "me" })
    check("its own pace", errOf(a) == "wait")
end

section("the log for Phase 4")
do
    local a = boot()
    for i = 1, 2105 do W.server.ZeD.Srv.adminLog("staff" .. (i % 20), "test", "t" .. i) end
    local log = md().log
    check("the ring holds its cap", log.n == 2000 and log[log.at].target == "t2105")
    check("a line has who, what and when", log[log.at].who == "staff5" and log[log.at].t ~= nil and log[log.at].day == 13)
    local eaten = 0
    W.server.ZeD.Srv.log = function() eaten = eaten + 1 end
    W.server.ZeD.Srv.adminLog("Hermit", "test", "x")
    check("it goes through the server part's log", eaten == 1)
    -- the one log: another kind's line lands in the same ring, in the same shape
    local lines = {}
    W.server.ZeD.Srv.log = function(s) lines[#lines + 1] = s end
    W.server.ZeD.Srv.action("safehouse", "Aretha", "claim", nil, nil, 10, 20)
    W.server.ZeD.Srv.action("faction", "Aretha", "create", "River|side\nfake | day 1")
    local l = md().log
    check("a claim line reaches the ring, with its kind", l[l.at].kind == "faction" and l[l.at].who == "Aretha")
    check("the shape: kind, what, who, target, where, detail, day", lines[1] == "safehouse | claim | Aretha | - | 10,20 | - | day 13", lines[1])
    local _, seps = string.gsub(lines[2] or "", " | ", "")
    check("player text cannot add a field or a line", seps == 6 and not string.find(lines[2] or "", "\n", 1, true), lines[2])
end

section("without the server part")
do
    local a, ca = boot()
    local S = ca.env.ZeD.ServerPart
    S.forceOff = true
    local m = M(ca)
    check("not live", not m.live())
    m.kick("Kade", "words", function(r) ca.r = r end)
    check("kick: the game's call at once", has(ca.slash, '/kickuser "Kade" -r "words"') and ca.r.fallback == true)
    m.ban("Kade", "words", "perm", true)
    check("ban: the game's", has(ca.slash, '/banuser "Kade" -ip -r "words"'))
    check("and the plain one, which works whatever the IP's fate", has(ca.slash, '/banuser "Kade" -r "words"'))
    m.ban("Kade", "words", "d3", false, function(r) ca.r = r end)
    check("a timed ban is the server part's: refused, never made permanent", ca.r.err == "part")
    m.banTyped("76561198000000002", "words", "perm")
    check("ban a Steam ID: the game's", has(ca.game, "BanSteamID:76561198000000002:words"))
    m.banTyped("203.0.113.7", "words", "perm")
    check("ban an IP: the game's", has(ca.slash, "/banip 203.0.113.7"))
    m.rows = { { user = "76561198000000005", on = true } }
    ca.slash = {}
    m.banTyped("76561198000000005", "words", "perm")
    check("a typed name on the game's list stays a name", has(ca.slash, '/banuser "76561198000000005" -r "words"'))
    m.rows = {}
    m.ban("76561198000000006", "words", "perm", false)
    check("a row's name is never read by its shape", has(ca.slash, '/banuser "76561198000000006" -r "words"'))
    m.unban({ ip = "203.0.113.9", game = true })
    check("an IP row lifts by its IP", has(ca.game, "UnBanIPOnly:203.0.113.9:"))
    m.unban({ user = "Kade" })
    check("unban: the game's", has(ca.game, "UnBan:Kade:"))
    m.setRole("Kade", "moderator")
    check("role: the game's", has(ca.game, "SetRole:Kade:moderator"))
    m.message("Hello", 30)
    check("a message goes once", has(ca.slash, '/servermsg "Hello"'))
    m.spawn("Base.Axe", 3, "me")
    check("spawn: the game's /additem", has(ca.slash, '/additem "Hermit" "Base.Axe" 3'))
    m.mute("Kade", true)
    check("mute: voice only", has(ca.slash, '/voiceban "Kade" -true'))
    check("and the card can undo it", m.muted("Kade"))
    m.mute("Kade", false)
    check("unmute: voice only", has(ca.slash, '/voiceban "Kade" -false') and not m.muted("Kade"))
    m.spawn("Base.Axe", 3, "ground", function(r) ca.r = r end)
    check("the ground needs the server part", ca.r.err == "part" and not has(ca.slash, '"ground"'))
    check("nothing crossed to the server", next(md().bans) == nil)
end

-- ---------------------------------------------------------------------------
-- THE REVIEW'S CASES, each as it was reproduced
-- ---------------------------------------------------------------------------
local ADMIN_SID = "76561198000000001"

section("a name that looks like a Steam ID")
do
    local a, ca = boot()
    a.steamNum, ca.sid = 76561198000000001, ADMIN_SID
    nolimit(a)
    say(a, "a_hi", { sid = ADMIN_SID })
    local u = player(ADMIN_SID, "user")
    local cu = clientJoin(u)
    M(ca).ban(ADMIN_SID, "griefing", "perm", false, function(r) ca.r = r end)
    drain()
    check("the press on a row means that player", ca.r.ok == true and md().bans[1].user == ADMIN_SID and md().bans[1].sid == nil)
    advance(13000)
    check("the game's call is on the name, never the Steam ID", has(ca.slash, '/banuser "' .. ADMIN_SID .. '" -r "griefing"') and not has(ca.game, "BanSteamID"))
    check("the griefer goes, the admin stays", W.gameBans[ADMIN_SID] == true and cu.up == false and ca.up == true)
    -- the same digits typed: a name this server knows stays a name
    local b, cb = boot()
    b.steamNum, cb.sid = 76561198000000001, ADMIN_SID
    say(b, "a_hi", { sid = ADMIN_SID })
    local v = player(ADMIN_SID, "user")
    clientJoin(v)
    say(b, "a_ban", { target = ADMIN_SID, reason = "griefing", len = "d1" })
    check("typed: read as the name", okOf(b) and md().bans[1].user == ADMIN_SID and md().bans[1].sid == nil)
    advance(13000)
    check("the admin is never told to leave", cb.left == 0 and not M(cb).leave)
end

section("the guard holds on a Steam ID and on an unknown name")
do
    local a, ca = boot()
    a.steamNum = 76561198000000001
    nolimit(a)
    say(a, "a_hi", { sid = ADMIN_SID })
    local m = player("Rosa", "moderator")
    local cm = clientJoin(m)
    say(m, "a_ban", { target = "Hermit", reason = "mine now", len = "w1" })
    check("by name: protected", errOf(m) == "protected")
    nolimit(m)
    say(m, "a_ban", { target = ADMIN_SID, reason = "mine now", len = "w1" })
    check("by Steam ID: the same answer", errOf(m) == "protected")
    nolimit(m)
    say(m, "a_ban", { target = ADMIN_SID, reason = "mine now", len = "perm" })
    check("a permanent one too", errOf(m) == "protected" and next(md().owed) == nil)
    nolimit(m)
    say(m, "a_ban", { target = "Owner", reason = "mine now", len = "w1" })
    check("a timed ban on a name never seen is refused", errOf(m) == "unknown" and next(md().bans) == nil)
    nolimit(m)
    say(m, "a_warn", { user = "Owner", n = 1, reason = "x" })
    check("so are warning points", errOf(m) == "unknown")
    nolimit(m)
    say(m, "a_mute", { user = "Owner", on = true })
    check("and a mute", errOf(m) == "unknown")
    -- a row made before the role was known never removes a protected role
    nolimit(m)
    md().players.Late = { t = 1, role = "user" }
    say(m, "a_ban", { target = "Late", reason = "x", len = "w1" })
    check("a timed ban on someone seen as a player", okOf(m))
    local o = player("Late", "admin")
    local co = clientJoin(o)
    advance(6000)
    check("the role they hold now is above it: not told", not M(co).leave and co.left == 0)
    check("a line says why", logHas("ban does not bind"))
    -- nor a Steam ID nobody had on record
    nolimit(m)
    say(m, "a_ban", { target = "76561198000000077", reason = "x", len = "w1" })
    check("an ID with no record is taken", okOf(m))
    local q = player("Quiet", "admin")
    q.steamNum = 76561198000000077
    local cq = clientJoin(q)
    cq.sid = "76561198000000077"
    say(q, "a_hi", { sid = cq.sid })
    drain()
    advance(6000)
    check("and it can't remove the protected role behind it", not M(cq).leave and cq.left == 0)
end

section("a client's Steam ID is checked against the server's")
do
    local a, ca = boot()
    a.steamNum = 76561198000000001
    nolimit(a)
    say(a, "a_hi", { sid = ADMIN_SID })
    check("the server's number agrees", md().players.Hermit.sid == ADMIN_SID)
    local g = player("Griefer", "user")
    g.steamNum = 76561198000999999
    clientJoin(g)
    nolimit(g)
    say(g, "a_hi", { sid = ADMIN_SID })
    check("someone else's ID is not taken", md().players.Griefer.sid == nil)
    say(a, "a_ban", { user = "Griefer", reason = "griefing", len = "d3", sid = ADMIN_SID })
    check("nor a sid from the card: a ban's ID is the server's", okOf(a) and md().bans[1].sid == nil)
    advance(6000)
    check("their ban never reaches the admin", ca.left == 0 and not M(ca).leave)
    local n = player("NoSteam", "user")
    clientJoin(n)
    nolimit(n)
    say(n, "a_hi", { sid = ADMIN_SID })
    check("no Steam on the server's side: no ID at all", md().players.NoSteam.sid == nil)
end

section("a client that stays and keeps saying hello")
do
    local a, ca = boot()
    local u = player("Torch", "user")
    local cu = clientJoin(u)
    cu.env.forceDisconnect = function() end
    say(a, "a_ban", { user = "Torch", reason = "griefing", len = "w1" })
    for _ = 1, 8 do
        advance(6000)
        nolimit(u)
        say(u, "a_hi", {})
        drain()
    end
    check("the stay note comes all the same", has(ca.game, "note:UI_ZeD_Adm_NoteStay") and md().bans[1].stay ~= nil)
    check("the hello hears a_leave again", got(u, "a_leave") ~= nil)
end

section("owed calls follow their ban")
do
    -- unban in the wait: nothing reaches the game, and the player stays
    local a, ca = boot()
    local u = player("Mike", "user")
    local cu = clientJoin(u)
    say(a, "a_ban", { user = "Mike", reason = "wrong name", len = "perm" })
    drain()
    check("told to leave", M(cu).leave ~= nil)
    advance(4000)
    nolimit(a)
    say(a, "a_unban", { id = 1 })
    drain()
    check("the client's clock stops", M(cu).leave == nil and M(cu).leaveAt == nil)
    advance(14000)
    check("no call left, no ban made, no unban needed", next(md().owed) == nil and not has(ca.slash, "/banuser") and not has(ca.game, "UnBan"))
    check("the player is still here", cu.left == 0 and cu.up == true)
    -- the same with a timed ban
    nolimit(a)
    say(a, "a_ban", { user = "Mike", reason = "wrong name", len = "h1" })
    advance(3000)
    nolimit(a)
    say(a, "a_unban", { id = 2 })
    advance(14000)
    check("a timed ban: no kick after the unban", not has(ca.slash, "/kickuser") and cu.left == 0)
    -- a timed ban lifts with a Kick still owed
    nolimit(a)
    local v = player("Kade", "user")
    local cv = clientJoin(v)
    say(a, "a_ban", { user = "Kade", reason = "griefing", len = "h1" })
    offline(a)
    advance(13000)
    W.clock = W.clock + 3600 * 1000
    advance(2000)
    check("lifted", next(md().bans) == nil)
    check("the Kick went with it", next(md().owed) == nil)
    local back = player("Hermit", "admin")
    W.clients.Hermit = nil
    local c2 = clientJoin(back)
    advance(2000)
    check("nobody is kicked a day later", not has(c2.slash, "/kickuser"))
    -- an author who lost the power: the calls they left behind go nowhere
    local b, cb = boot()
    local r = player("Rosa", "moderator")
    local cr = clientJoin(r)
    say(r, "a_ban", { target = "Victim", reason = "x", len = "perm" })
    cr.env.ZeD.ServerPart.send = function(m2, c3, a2) return true end       -- (a hacked client: no answer)
    advance(1000)
    check("sent to its author", md().owed[1].sentTo == "Rosa")
    r.role = ROLES.user
    advance(16000)
    check("demoted: dropped, not passed to the admin", not has(cb.slash, '/banuser "Victim"') and md().owed[1] == nil)
    check("and written down", logHas("game call dropped"))
end

section("a_done, and who a call may go to")
do
    local a, ca = boot()
    local t = player("Tom", "moderator")
    local ct = clientJoin(t)
    local r = player("Rosa", "moderator")
    local cr = clientJoin(r)
    say(r, "a_ban", { user = "Tom", reason = "abuse", len = "perm" })
    check("a moderator bans a moderator", okOf(r))
    say(a, "a_done", { id = 1 })
    check("a word from a client it was not sent to clears nothing", md().owed[1] ~= nil)
    nolimit(t)
    say(t, "a_done", { id = 1 })
    say(t, "a_unban", { id = 1 })
    check("banned staff act on nothing", t.box[1].args.err == "perm" and md().bans[1] ~= nil)
    offline(r)
    offline(a)
    advance(30000)
    check("never sent to its own target", not has(ct.slash, '/banuser "Tom"') and md().owed[1] ~= nil)
    check("still kept out meanwhile", M(ct).leave ~= nil)
end

section("a permanent ban keeps them out until the game holds it")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    say(a, "a_ban", { user = "Kade", reason = "griefing", len = "perm" })
    offline(a)
    advance(13000)
    check("their client left", cu.left == 1)
    check("nothing made yet", W.gameBans.Kade == nil and next(md().owed) ~= nil)
    W.online[#W.online + 1] = u
    W.clients.Kade = nil
    local c2 = clientJoin(u)
    advance(6000)
    check("back: told to leave all the same", M(c2).leave ~= nil and M(c2).leave.reason == "griefing")
    advance(13000)
    check("and goes", c2.left == 1)
end

section("Ban IP too")
do
    -- they leave before the IP call: the plain ban lands, and the row says what the game holds
    local a, ca = boot()
    local u = player("Loot", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Loot", reason = "griefing", len = "perm", banIp = true })
    advance(3000)
    offline(u)
    advance(13000)
    check("banned all the same", W.gameBans.Loot == true and W.gameIps.Loot == nil)
    check("the row does not claim the IP", md().bans[1].banIp == nil and md().bans[1].made == true)
    check("staff are told", has(ca.game, "note:UI_ZeD_Adm_NoteIpFail"))
    -- on a Steam connection the game refuses and bans nobody: the plain ban follows
    nolimit(a)
    local s = player("Relay", "user")
    s.steamConn = true
    clientJoin(s)
    say(a, "a_ban", { user = "Relay", reason = "griefing", len = "perm", banIp = true })
    advance(20000)
    check("a Steam connection: banned by name", W.gameBans.Relay == true and W.gameIps.Relay == nil)
    check("the row does not claim that IP either", md().bans[2].banIp == nil)
    -- offline: refused up front
    nolimit(a)
    md().players.Gone = { t = 1, role = "user" }
    say(a, "a_ban", { user = "Gone", reason = "x", len = "perm", banIp = true })
    check("offline: the IP can't be banned", errOf(a) == "offline" and md().bans[3] == nil)
end

section("one row per player")
do
    local a, ca = boot()
    local m = player("Rosa", "moderator")
    clientJoin(m)
    local u = player("Torch", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Torch", reason = "x", len = "d3" })
    say(a, "a_ban", { user = "Kade", reason = "x", len = "d3" })
    check("one account's bans are paced", errOf(a) == "wait")
    say(m, "a_ban", { user = "Torch", reason = "y", len = "h1" })
    check("a second ban is refused", errOf(m) == "already")
    local c = 0
    for _ in pairs(md().bans) do c = c + 1 end
    check("one row", c == 1)
    nolimit(a)
    say(a, "a_card", { user = "Torch" })
    local v = got(a, "a_card")
    check("the card knows it", v.banId == 1 and v.banUntil ~= nil)
    -- a timed row with the game's ban: lifting it owes one UnBan
    nolimit(a)
    say(a, "a_gameban", { id = 1 })
    advance(2000)
    check("the game's ban is made", md().bans[1].made == true)
    W.clock = W.clock + 3 * 86400 * 1000
    advance(2000)
    check("and comes off", has(ca.game, "UnBan:Torch:"))
end

section("the Bans card's typed name")
do
    local a, ca = boot()
    local u = player("Kade_R", "user")
    local cu = clientJoin(u)
    say(a, "a_ban", { target = "kade_r", reason = "griefing", len = "d3" })
    check("another case finds the player", okOf(a) and md().bans[1].user == "Kade_R")
    drain()
    check("and they are told", M(cu).leave ~= nil)
    -- the game's login matches names in any case
    local b, cb = boot()
    md().bans[1] = { id = 1, user = "griefer", reason = "x", by = "Hermit", at = 1, untilT = math.floor(W.clock / 1000) + 3600 }
    md().mutes.griefer = "Hermit"
    local g = player("GRIEFER", "user")
    local cg = clientJoin(g)
    advance(6000)
    check("a timed ban holds under another spelling", M(cg).leave ~= nil)
    check("so does a mute", M(cg).isMuted("GRIEFER"))
end

section("a Steam ID row that stays")
do
    local a, ca = boot()
    say(a, "a_ban", { target = "76561198000000044", reason = "alt", len = "w1" })
    local u = player("Other", "user")
    u.steamNum = 76561198000000044
    local cu = clientJoin(u)
    cu.env.forceDisconnect = function() end
    cu.sid = "76561198000000044"
    nolimit(u)
    say(u, "a_hi", { sid = cu.sid })
    advance(26000)
    check("the stay is on the row", md().bans[1].stay ~= nil)
    nolimit(a)
    say(a, "a_gameban", { id = 1 })
    check("the game's ban acks", okOf(a))
    advance(2000)
    check("through the Steam ID", has(ca.game, "BanSteamID:76561198000000044:alt"))
end

section("the card's view")
do
    local a, ca = boot()
    local obs = player("Obs", "gm")
    ROLES.gm.caps.CanSeePlayersStats = true
    clientJoin(obs)
    local u = player("Kade", "user")
    clientJoin(u)
    say(obs, "a_card", { user = "Kade" })
    local v = got(obs, "a_card")
    check("no AnswerTickets: no ticket in the view", v and v.tickets == nil and v.ticketN == nil)
    nolimit(obs)
    say(obs, "a_card", { user = "Hermit" })
    v = got(obs, "a_card")
    check("a role above theirs keeps its place", v.x == nil and v.oid == nil and v.hidden == true)
    nolimit(a)
    say(a, "a_card", { user = "Kade" })
    v = got(a, "a_card")
    check("staff read tickets and the place", v.ticketN ~= nil and v.x ~= nil)
    ROLES.gm.caps.CanSeePlayersStats = nil
end

section("the log can't be flooded")
do
    local a, ca = boot()
    local m = player("Rosa", "moderator")
    clientJoin(m)
    local u = player("Kade", "user")
    clientJoin(u)
    say(a, "a_kick", { user = "Kade", reason = "the line that matters" })
    for i = 1, 2100 do
        nolimit(m)
        W.clock = W.clock + 600
        say(m, "a_power", { id = "GodMod", on = i % 2 == 0 })
    end
    local log, mine, kept = md().log, 0, false
    for i = 1, log.n do
        if log[i].who == "Rosa" then mine = mine + 1 end
        if log[i].what == "kick" then kept = true end
    end
    check("one account holds its share and no more", mine == 400, mine)
    check("another's line stays", kept)
    -- a client's own reports (the container log) have a smaller share, and push out nothing the server saw
    local Srv = W.server.ZeD.Srv
    for i = 1, 300 do Srv.actionStore("container", "Rosa", "took", nil, "report " .. i) end
    local told, proved = 0, 0
    log = md().log
    for i = 1, log.n do
        if log[i].who == "Rosa" then
            if log[i].kind == "container" then told = told + 1 else proved = proved + 1 end
        end
    end
    check("a player with a full share adds no reports over what the server saw", told == 0 and proved == 400, told .. ", " .. proved)
    for i = 1, 300 do Srv.actionStore("container", "Newcomer", "took", nil, "report " .. i) end
    Srv.actionStore("admin", "Newcomer", "kick", "x", "proved")
    told, proved = 0, 0
    log = md().log
    for i = 1, log.n do
        if log[i].who == "Newcomer" then
            if log[i].kind == "container" then told = told + 1 else proved = proved + 1 end
        end
    end
    check("reports hold their own smaller share", told == 100 and proved == 1, told .. ", " .. proved)
    nolimit(m)
    W.clock = W.clock + 2000
    say(m, "a_power", { id = "x on Hermit", on = true })
    check("a power that isn't on the list writes nothing", not logHas("x on Hermit"))
    nolimit(u)
    say(u, "a_power", { id = "GodMod", on = true })
    check("nor one the role lacks", not logHas("power on: GodMod | Kade"))
    say(a, "a_rolelog", { what = "save", role = "a\nb" })
    check("a role's name is one line", not logHas("a\nb"))
end

section("the mute list has a floor and a ceiling")
do
    local a, ca = boot()
    say(a, "a_mute", { user = "Made Up", on = true })
    check("a name nobody has", errOf(a) == "unknown" and next(md().mutes) == nil)
    md().mutes["gone"] = "Hermit"
    nolimit(a)
    say(a, "a_mute", { user = "gone", on = false })
    check("but a name on the list can come off", okOf(a) and next(md().mutes) == nil)
    local u = player("Kade", "user")
    clientJoin(u)
    for i = 1, 500 do md().mutes["m" .. i] = "Hermit" end
    nolimit(a)
    say(a, "a_mute", { user = "Kade", on = true })
    check("the list is full", errOf(a) == "full")
end

section("the bans and owed tables")
do
    local a, ca = boot()
    local now = math.floor(W.clock / 1000)
    for i = 1, 1000 do md().bans[i] = { id = i, user = "fake" .. i, reason = "x", by = "Hermit", at = 1, made = true } end
    md().nextBan = 1001
    md().players.Real = { t = 1, role = "user" }
    say(a, "a_ban", { user = "Real", reason = "x", len = "d1" })
    check("a full list of permanent rows gives way, the oldest first", okOf(a) and md().bans[1] == nil)
    for i = 2, 1000 do md().bans[i] = nil end
    for i = 1, 200 do md().owed[1000 + i] = { id = 1000 + i, act = "UnBan", target = "t" .. i, reason = "", at = now + 99999 } end
    nolimit(a)
    say(a, "a_unban", { user = "Someone" })
    check("full of real calls: refused, and none lost", errOf(a) == "full" and md().owed[1001] ~= nil)
    nolimit(a)
    say(a, "a_ban", { target = "Next", reason = "x", len = "perm" })
    check("a ban too", errOf(a) == "full")
end

section("a banned player's own view")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    say(a, "a_ban", { user = "Kade", reason = "griefing", len = "d1" })
    drain()
    local v = got(u, "a_leave")
    check("no name of who banned them", v and v.by == nil and M(cu).leave.by == nil)
end

section("a new role's rank")
do
    local a, ca = boot()
    local helper = role("helper", -1, all({ "KickUser", "AddUserlog", "SeePlayersConnected" }))
    ROLES.helper = helper
    ROLE_LIST[#ROLE_LIST + 1] = helper
    local h = player("Help", "helper")
    local ch = clientJoin(h)
    local u = player("Kade", "user")
    clientJoin(u)
    M(ch).kick("Kade", "x", function(r) ch.r = r end)
    drain()
    check("a role under user still acts on plain players", ch.r.ok == true, ch.r.err)
    u.role = ROLES.gm
    nolimit(h)
    M(ch).kick("Kade", "x", function(r) ch.r = r end)
    drain()
    check("and on nobody above that", ch.r.err == "rank", ch.r.err)
    ROLE_LIST[#ROLE_LIST] = nil
    ROLES.helper = nil
end

section("a role change across a restart")
do
    local a, ca = boot()
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    M(ca).setRole("Kade", "moderator", {}, function(r) ca.r = r end)
    drain()
    check("pending", md().watch.Kade ~= nil)
    A().md = nil
    serverStart()
    W.server.ZeD.Srv.adminTick()
    check("the watch survives", md().watch.Kade ~= nil)
    advance(40000)
    check("it waits for their hello", md().watch.Kade ~= nil and u.ghost == true)
    nolimit(u)
    say(u, "a_hi", {})
    drain()
    check("then the powers go off", u.ghost == false and u.noclip == false and u.god == false)
    check("their client hears it", has(cu.game, "power:Invisible:false"))
    check("nothing left to watch", next(md().watch) == nil)
end

section("the client's own reads")
do
    local a, ca = boot()
    local m = M(ca)
    -- the name on Steam, not the game's display name
    local nu = { getUsername = function() return "Kade_R" end, isOnline = function() return true end, getRole = function() return ROLES.user end,
        getLastConnection = function() return "x" end, getWarningPoints = function() return 2 end, getKicks = function() return 0 end,
        getSteamid = function() return "76561198000000050" end, getDisplayName = function() return "Kade_R" end,
        getIpBanned = function() return "" end, getSteamIdBanned = function() return "" end }
    ca.env.getUsers = function() return jlist({ nu }) end
    ca.env.getSteamModeActive = function() return true end
    ca.env.getSteamProfileNameFromSteamID = function(s) return s == "76561198000000050" and "kader_ky" or nil end
    ca.env.getSteamProfileNameFromUsername = function() return nil end
    m.refreshRows()
    check("the card's Steam name is the one on Steam", m.row("Kade_R").steam == "kader_ky", m.row("Kade_R").steam)
    check("Find reads it", #m.findRows("kader", false) == 1)
    -- both of the game's lists, on a Steam server too
    local asked = {}
    ca.env.getBannedIPs = function() asked.ip = true end
    ca.env.getBannedSteamIDs = function() asked.sid = true end
    m.listsAt = nil
    m.watch()
    check("both lists are read", asked.ip and asked.sid)
    -- an IP banned on its own has an empty name
    ca.env.Events.ViewBannedIPs.fire(jlist({ { getIp = function() return "203.0.113.9" end, getUsername = function() return "" end, getReason = function() return "" end } }))
    check("no empty name on the row", m.gameIps[1].user == nil)
    nolimit(a)
    m.unban(m.gameIps[1] and { ip = "203.0.113.9", game = true }, function(r) ca.r = r end)
    advance(1000)
    check("it lifts by its IP", ca.r.ok == true and has(ca.game, "UnBanIPOnly:203.0.113.9:"))
    -- a role write lands: the list is read again and the cards hear of it
    m.roles()
    local seq = m.seq
    ca.env.Events.OnRolesReceived.fire()
    check("the role list is read fresh", m.rolesAt == nil and m.seq > seq)
    -- saving a role another admin deleted
    m.qaRoles = {}
    local calls = #ca.game
    m.saveRole({ name = "gone", desc = "", color = { r = 1, g = 1, b = 1 }, caps = {} }, false, function(r) ca.r = r end)
    check("Save answers that it is gone", ca.r.ok == false and ca.r.err == "gone" and #ca.game == calls)
    m.qaRoles = nil
end

section("a game without a capability")
do
    world()
    local saved = CAPS.AddItem
    CAPS.AddItem = nil
    W.logs = {}
    W.moddata = {}
    local ok, err = pcall(serverStart)
    check("the tools stay off and the server stays up", ok, err)
    check("a line says why", logHas("admin tools off"))
    CAPS.AddItem = saved
end

-- a role that sees who is connected, without the game's power for every account, sees no offline rows
do
    local a = boot()
    local u = player("Kade", "user")
    clientJoin(u)
    advance(6000)
    offline(u)
    advance(6000)
    local g = player("Gia", "gm")
    clientJoin(g)
    advance(6000)
    nolimit(g)
    say(g, "a_players", {})
    local gp, gOff = got(g, "a_players"), 0
    for _, r in ipairs(gp.rows) do if r.on == false then gOff = gOff + 1 end end
    check("no offline rows without See every account", #gp.rows > 0 and gOff == 0)
    nolimit(a)
    say(a, "a_players", {})
    local ap, aOff = got(a, "a_players"), 0
    for _, r in ipairs(ap.rows) do if r.on == false then aOff = aOff + 1 end end
    check("staff with it still see them", aOff >= 1)
    -- the offline card follows the same rule: a role with the player stats power but not See every account gets no record
    ROLES.gm.caps.CanSeePlayersStats = true
    nolimit(g)
    say(g, "a_card", { user = "Kade" })
    local gc = got(g, "a_card")
    check("an offline card without See every account: no record", gc and gc.on == false and gc.closed == true
        and gc.prof == nil and gc.traits == nil and gc.skills == nil and gc.role == nil and gc.last == nil)
    nolimit(g)
    say(g, "a_card", { user = "Nobody" })
    gc = got(g, "a_card")
    check("a name never seen reads the same, so the card tells no one an account exists", gc and gc.closed == true)
    nolimit(g)
    say(g, "a_card", { user = "Hermit" })
    gc = got(g, "a_card")
    check("an online card is not closed", gc and gc.on == true and gc.closed == nil)
    -- a ban on the offline name: a closed card keeps it from a role that does not read the bans
    nolimit(a)
    say(a, "a_ban", { user = "Kade", reason = "Griefing", len = "w1" })
    drain()
    nolimit(a)
    say(a, "a_card", { user = "Kade" })
    local ab = got(a, "a_card")
    check("the ban is on the record (staff card)", ab and ab.banId ~= nil)
    nolimit(g)
    say(g, "a_card", { user = "Kade" })
    gc = got(g, "a_card")
    check("a closed card keeps a ban from a role without the ban power", gc and gc.closed == true
        and gc.banId == nil and gc.banUntil == nil)
    ROLES.gm.caps.BanUnbanUser = true
    nolimit(g)
    say(g, "a_card", { user = "Kade" })
    gc = got(g, "a_card")
    check("a role that reads the bans still sees it on a closed card", gc and gc.closed == true and gc.banId == ab.banId)
    ROLES.gm.caps.BanUnbanUser = nil
    ROLES.gm.caps.CanSeePlayersStats = nil
    nolimit(a)
    say(a, "a_card", { user = "Kade" })
    local ac = got(a, "a_card")
    check("staff with it still read the offline record", ac and ac.closed == nil and ac.prof ~= nil and ac.last ~= nil)
    -- a game without the power: the offline card stays closed even for staff, as the list does
    local savedCap = CAPS.SeeNetworkUsers
    CAPS.SeeNetworkUsers = nil
    nolimit(a)
    say(a, "a_card", { user = "Kade" })
    ac = got(a, "a_card")
    check("no SeeNetworkUsers in the game: closed, and no error", ac and ac.closed == true and ac.prof == nil)
    CAPS.SeeNetworkUsers = savedCap
end

print("admin_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
