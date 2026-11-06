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
    env.SendCommandToServer = function(s) c.slash[#c.slash + 1] = s end
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
    env.forceDisconnect = function() c.left = c.left + 1 end
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
        uuid = 0, scripts = { ["Base.Axe"] = true }, ground = {}, sent = 0 }
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
    check("it is logged", logHas("roles: save by Hermit on gm"))
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
    check("kick logged, with place and reason", logHas("admin kick by Hermit on Kade at 6280,5350,0: Spamming chat"))
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
    check("warning logged", logHas("admin warning points by Hermit on Kade"))
    M(ca).teleport("Kade")
    drain()
    check("teleport goes as the game's", has(ca.slash, '/teleport "Kade"'))
    M(ca).bring("Kade")
    drain()
    check("bring goes as the game's", has(ca.slash, '/teleportplayer "Kade" "Hermit"'))
    check("both logged", logHas("admin teleport to by Hermit") and logHas("admin teleport to you by Hermit"))
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
    check("nothing left to watch", next(A().watch) == nil)
    check("role logged", logHas("admin role by Hermit on Kade"))
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
    say(a, "a_role", { user = "Gone", role = "user" })
    check("an offline player's role can change", okOf(a))
    advance(31000)
    check("the watch runs out", next(A().watch) == nil)
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
    local allowed = { user = 1, on = 1, muted = 1, last = 1, prof = 1, traits = 1, skills = 1, role = 1, x = 1, y = 1, z = 1, oid = 1, tickets = 1, ticketN = 1, banId = 1, id = 1, name = 1, lv = 1 }
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
    M(ca).ban("Torch", "Burned the farm, twice", "d3", false, nil, function(r) ca.r = r end)
    drain()
    check("the ban acks", ca.r.ok == true and ca.r.untilT ~= nil)
    check("their client is told to leave, with the reason", M(cu).leave and M(cu).leave.reason == "Burned the farm, twice" and M(cu).leave.untilT == ca.r.untilT)
    check("it is logged", logHas("admin ban by Hermit on Torch"))
    check("staff read it", #M(ca).bans == 1 and M(ca).bans[1].by == "Hermit")
    check("no game ban for a timed one", not has(ca.slash, "/banuser"))
    advance(6000)
    check("the reason shows first", cu.left == 0)
    advance(7000)
    check("then the client goes", cu.left == 1)
    check("and a real kick backs it up", has(ca.slash, '/kickuser "Torch" -r "Burned the farm, twice"'))
    advance(1000)
    check("the owed kick is done", next(md().owed) == nil)
    offline(u)
    offline(a)
    -- nobody on: it lifts to the second
    W.clock = W.clock + 259200 * 1000 - 20000
    W.server.Events.OnTickEvenPaused.fire()
    check("not yet", next(md().bans) ~= nil)
    W.clock = W.clock + 21000
    W.server.Events.OnTickEvenPaused.fire()
    check("lifted with nobody on", next(md().bans) == nil)
    check("the lift is logged", logHas("admin ban lifted by server on Torch"))
end

section("a client that does not leave")
do
    local a, ca = boot()
    local u = player("Torch", "user")
    local cu = clientJoin(u)
    say(a, "a_ban", { user = "Torch", reason = "Griefing", len = "w1" })
    drain()
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
    advance(13000)
    check("the game's ban, with the IP", has(ca.slash, '/banuser "Loot" -ip -r "Scam spam"'), ca.slash[1])
    check("done", next(md().owed) == nil)
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
    check("the game's unban", has(ca.game, "UnBan:Loot:"))
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
    say(m, "a_ban", { target = "Absent", reason = "x", len = "perm" })
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
    check("logged", logHas("admin server message by Hermit at"))
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
    check("logged", logHas("admin spawn by Hermit at 6280,5350,0: 5 x Base.Axe to me"))
    nolimit(a)
    say(a, "a_spawn", { item = "Base.Axe", n = 2, to = "Kade" })
    check("to a player", #u.items == 2)
    check("logged with the player", logHas("admin spawn by Hermit on Kade"))
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
    for i = 1, 2105 do W.server.ZeD.Srv.adminLog("Hermit", "test", "t" .. i) end
    local log = md().log
    check("the ring holds its cap", log.n == 2000 and log[log.at].target == "t2105")
    check("a line has who, what and when", log[log.at].who == "Hermit" and log[log.at].t ~= nil and log[log.at].day == 13)
    local eaten = 0
    W.server.ZeD.Srv.log = function() eaten = eaten + 1 end
    W.server.ZeD.Srv.adminLog("Hermit", "test", "x")
    check("it goes through the server part's log", eaten == 1)
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
    m.ban("Kade", "words", "perm", true, nil)
    check("ban: the game's", has(ca.slash, '/banuser "Kade" -ip -r "words"'))
    m.ban("76561198000000002", "words", "perm", false, nil)
    check("ban a Steam ID: the game's", has(ca.game, "BanSteamID:76561198000000002:words"))
    m.ban("203.0.113.7", "words", "perm", false, nil)
    check("ban an IP: the game's", has(ca.slash, "/banip 203.0.113.7"))
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
    check("nothing crossed to the server", next(md().bans) == nil)
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

print("admin_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
