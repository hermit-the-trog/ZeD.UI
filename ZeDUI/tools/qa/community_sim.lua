-- ZeDUI/tools/qa/community_sim.lua  (Nov 6 2026, QA): multiplayer Phase 5, community: the server side and the client model with no
-- game running. The harness is admin_sim.lua's, in the style of tickets_sim.lua: Lua 5.1 stubs of the game and the real files run
-- against them, ZeD_TicketProto, ZeD_AdminProto, ZeD_CommunityProto, ZeD_ServerCore, ZeD_ServerTickets, ZeD_ServerAdmin,
-- ZeD_ServerCommunity, and on each simulated client ZeD_ServerLink, ZeD_Tickets, ZeD_Admin and ZeD_Community. Every message crosses
-- a stub of the network with the game's rules, a step at a time. Permissions, hostile arguments, the views, saving, revisions and
-- NEW, joining and agreeing, never trapping a player, the news, the appeal line, reports from chat, restarts, a server without any
-- of this. Nov 7: the join rules hold (every command refused until a player agrees, a Kick owed after five minutes, the walk
-- finds a client that never says hello).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/community_sim.lua
-- It prints FAIL lines and a last line "community_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]community_sim%.lua$", "")

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
    "RolesWrite", "RolesRead", "ChangeAndReloadServerOptions", "CantBeKickedByUser", "CantBeBannedByUser", "ToggleInvisibleHimself", "ToggleNoclipHimself",
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
local ADMIN_CAPS = { "RolesWrite", "ChangeAndReloadServerOptions", "CantBeKickedByUser", "CantBeBannedByUser" }
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
    function p.getPlayerNum(self) return self.num or 0 end       -- (the server's index for a split-screen player: 0 the first)
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
    ["ZeD/ZeD_CommunityProto"] = "42/media/lua/shared/ZeD/ZeD_CommunityProto.lua",
    ["ZeD/ZeD_ServerCore"] = "42/media/lua/server/ZeD/ZeD_ServerCore.lua",
    ["ZeD/ZeD_ServerTickets"] = "42/media/lua/server/ZeD/ZeD_ServerTickets.lua",
    ["ZeD/ZeD_ServerHelper"] = "42/media/lua/server/ZeD/ZeD_ServerHelper.lua",
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
        transmit = function() error("the a table must never be transmitted") end,
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
    runFile(env, FILES["ZeD/ZeD_CommunityProto"])
    env.loaded["ZeD/ZeD_CommunityProto"] = true
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerAdmin.lua")
    if not W.noCommunity then runFile(env, "42/media/lua/server/ZeD/ZeD_ServerCommunity.lua") end
    env.Events.OnInitGlobalModData.fire(false)
    return env
end

local function cap1(role_, name) return role_.caps[name] == true end

local function clientJoin(p)
    local env = baseEnv()
    local c = { env = env, p = p, up = true, slash = {}, game = {}, left = 0, extra = 0, shown = 0 }
    W.clients[p.name] = c
    env.isServer = function() return false end
    env.isClient = function() return true end
    env.require = function(n) requireIn(env, n) end
    env.getPlayer = function() return p end
    env.getTextOrNull = function() return nil end
    env.getText = function(k, a)
        local s = W.texts[k] or k
        if a ~= nil then s = string.gsub(s, "%%1", tostring(a)) end
        return s
    end
    env.getServerIP = function() return W.ip end
    env.getServerPort = function() return W.port end
    env.getFileWriter = function(name, create, append)
        local lines = {}
        return { write = function(_, s) lines[#lines + 1] = s end, close = function() W.files[name] = table.concat(lines) end }
    end
    env.getFileReader = function(name)
        local body = W.files[name]
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
    runFile(env, FILES["ZeD/ZeD_CommunityProto"])
    env.loaded["ZeD/ZeD_CommunityProto"] = true
    runFile(env, "42/media/lua/client/ZeD/ZeD_Community.lua")
    env.ZeD.Community.joinScreen = function() c.shown = c.shown + 1 end
    env.Events.OnGameStart.fire()
    env.Events.OnCreatePlayer.fire(0, p)
    advance(500)
    return c
end

local function world()
    W = { clock = 1793913240000, net = {}, logs = {}, online = {}, players = {}, clients = {}, moddata = {}, hours = 12.5 * 24,
        uuid = 0, scripts = { ["Base.Axe"] = true }, ground = {}, sent = 0, gameBans = {}, gameIps = {}, files = {}, ip = "10.0.0.5", port = "16261",
        noCommunity = W and W.noCommunityNext or nil,
        texts = { UI_Policy_Kick = "You were kicked", UI_Policy_KickReason = "You were kicked. Reason: %1", UI_OnConnectFailed_Banned = "You are banned from this server",
            UI_OnConnectFailed_BannedReason = "You are banned from this server. Reason: %1" } }
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
-- the answer to the command just said: the first ack in the box (a refusal's hello brings others after it)
local function firstAck(p)
    for i = 1, #p.box do
        if p.box[i].cmd == "t_ack" then return p.box[i].args or {} end
    end
    return nil
end
local function errOf(p)
    local a = firstAck(p)
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
local function Mo(c) return c.env.ZeD.Community end
local function Cm() return W.server.ZeD.Cm end
local function CT() return W.server.ZeD.Srv.M end
-- long enough that a push held back has gone out
local function flush() advance(W.server.ZeD.Cm.L.PUSH_MS + 600) end
local function logCount(text)
    local n = 0
    for _, l in ipairs(W.logs) do
        if string.find(l.line, text, 1, true) then n = n + 1 end
    end
    return n
end
local function boxCount(p, c)
    local n = 0
    for _, b in ipairs(p.box) do
        if b.cmd == c then n = n + 1 end
    end
    return n
end
local function offline(p)
    for i = #W.online, 1, -1 do
        if W.online[i] == p then table.remove(W.online, i) end
    end
end
local function cmd() return CT().md end
local function sayM(p, command, args)
    p.box = {}
    local a = wire(args)
    net(function() W.server.Events.OnClientCommand.fire("ZeDM", command, p, a) end)
    drain()
end
local function sayT(p, command, args)
    p.box = {}
    local a = wire(args)
    net(function() W.server.Events.OnClientCommand.fire("ZeDT", command, p, a) end)
    drain()
end
local function rulesOf(...)
    local t = { n = select("#", ...) }
    for i, s in ipairs({ ... }) do t[i] = (type(s) == "table") and s or { text = s } end
    return t
end
-- a save as the card makes it, the limits cleared
local function save(p, over)
    nolimit(p)
    local m = cmd()
    local a = { motd = m.motd, appeal = m.appeal, ask = m.ask, reask = m.reask, base = m.saves, rules = { n = m.rules.n } }
    for i = 1, m.rules.n do a.rules[i] = { id = m.rules[i].id, text = m.rules[i].text } end
    for k, v in pairs(over or {}) do a[k] = v end
    sayM(p, "m_save", a)
    return got(p, "t_ack")
end

local function boot()
    W = nil
    world()
    local a = player("Hermit", "admin")
    local ca = clientJoin(a)
    return a, ca
end

-- ---------------------------------------------------------------------------
section("the table, the hello, the views")
do
    local a, ca = boot()
    local name = nil
    for k in pairs(W.moddata) do
        if string.sub(k, 1, 7) == "ZeD_CM_" then name = k end
    end
    check("a secret table exists", name ~= nil)
    for _, l in ipairs(W.logs) do check("the name is in no log", not string.find(l.line, tostring(name), 1, true)) end
    for k in pairs(W.moddata) do check("no plain name", k ~= "ZeD_Community") end
    check("hello carries the view", ca.env.ZeD.ServerPart.cm == true and Mo(ca).view ~= nil)
    check("it reads as live", Mo(ca).live())
    check("an admin's view has the ticks", Mo(ca).view.edit ~= nil and Mo(ca).view.edit.reask == true)
    check("nothing to agree to: nobody is asked", ca.shown == 0 and not Mo(ca).view.ask)
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    check("a plain player's view has no ticks", cu.env.ZeD.Community.view.edit == nil)
    local m = player("Rosa", "moderator")
    local cm2 = clientJoin(m)
    check("a moderator's view has them", Mo(cm2).view.edit ~= nil)
    -- what a plain player is sent, whatever is in the table
    save(a, { motd = "Hello", appeal = "discord.gg/knox", ask = true, rules = rulesOf("One", "Two") })
    sayM(a, "m_agree", { rev = 1 })
    sayM(u, "m_get", {})
    local v = got(u, "m_view")
    check("m_get answers", v ~= nil and v.motd == "Hello" and v.appeal == "discord.gg/knox" and v.rules.n == 2)
    local keys = keysIn(v)
    for _, bad in ipairs({ "agreed", "agreedN", "saves", "nextRule", "reask", "schema", "edit", "by" }) do
        if bad ~= "by" then check("the view leaves out " .. bad, not keys[bad]) end
    end
    local s = ""
    for k in pairs(W.server.ZeD.Srv.M.md.agreed) do s = s .. k end
    check("the table holds Hermit's agreement", s == "hermit")
    check("no name of who agreed goes out", not string.find(string.lower(tostring(v.motd)), "hermit", 1, true))
    -- the demoted get no ticks at the next push
    m.role = ROLES.user
    nolimit(a)
    sayM(a, "m_post", { text = "news" })
    flush()
    check("a demoted client's next view has no ticks", got(m, "m_view") and got(m, "m_view").edit == nil)
end

-- ---------------------------------------------------------------------------
section("who may write, and hostile arguments")
do
    local a = boot()
    local u, m = player("Kade", "user"), player("Rosa", "moderator")
    clientJoin(u)
    clientJoin(m)
    local before = cmd().saves
    sayM(u, "m_save", { motd = "x", appeal = "", rules = rulesOf(), base = 0 })
    check("a player cannot save", errOf(u) == "perm" and cmd().saves == before)
    sayM(m, "m_save", { motd = "x", appeal = "", rules = rulesOf(), base = 0 })
    check("a moderator cannot save the rules", errOf(m) == "perm")
    sayM(u, "m_post", { text = "x" })
    check("a player cannot post", errOf(u) == "perm")
    sayM(m, "m_post", { text = "from Rosa", pin = true, by = "Hermit", t = 5, id = 99 })
    check("a moderator can post", okOf(m))
    check("the name and the time are the server's", cmd().news[1].by == "Rosa" and cmd().news[1].t ~= 5 and cmd().nextPost == 2)
    sayM(u, "m_pin", { id = 1, on = false })
    check("a player cannot pin", errOf(u) == "perm" and cmd().news[1].pin == true)
    sayM(u, "m_del", { id = 1 })
    check("a player cannot delete", errOf(u) == "perm" and cmd().newsN == 1)
    -- a role that loses the power mid-session
    m.role = ROLES.user
    nolimit(m)
    sayM(m, "m_post", { text = "again" })
    check("the power is read at each command", errOf(m) == "perm")
    -- shapes no client of ours sends
    local bad = {
        { motd = 5 }, { motd = string.rep("x", 601) }, { appeal = { 1 } }, { appeal = string.rep("x", 121) },
        { rules = "x" }, { rules = { n = 31 } }, { rules = { n = -1 } }, { rules = { n = 1.5 } }, { rules = { n = 2, { text = "a" } } },
        { rules = { n = 1, { text = string.rep("x", 201) } } }, { rules = { n = 1, { text = "" } } }, { rules = { n = 1, { text = "   \n " } } },
        { rules = { n = 1, "plain" } }, { rules = { n = 1, { text = 7 } } },
    }
    for i, over in ipairs(bad) do
        local n = cmd().saves
        local ack = save(a, over)
        check("bad save " .. i .. " is refused", ack and ack.ok == false and ack.err == "text" and cmd().saves == n, ack and ack.err)
    end
    local ack = save(a, { motd = "  two\nlines  ", appeal = "line\none\t\1", rules = rulesOf("  a rule\nwith a break  ") })
    check("words are cleaned", ack.ok and cmd().motd == "two\nlines" and cmd().appeal == "line one", cmd().appeal)
    check("a rule is one line", cmd().rules[1].text == "a rule with a break", cmd().rules[1].text)
    ack = save(a, { rules = rulesOf({ id = "x", text = "named" }, { id = -3, text = "named2" }, { id = 2.5, text = "named3" }) })
    check("an id that is no number is a new rule", ack.ok and cmd().rules.n == 3)
    local ids = {}
    for i = 1, 3 do
        check("ids are the server's", not ids[cmd().rules[i].id] and type(cmd().rules[i].id) == "number")
        ids[cmd().rules[i].id] = true
    end
    local twice = cmd().rules[1].id
    ack = save(a, { rules = rulesOf({ id = twice, text = "same" }, { id = twice, text = "same" }) })
    check("an id sent twice is new the second time", ack.ok and cmd().rules[1].id ~= cmd().rules[2].id)
    -- post and pin
    nolimit(a)
    for i, args in ipairs({ { text = 5 }, { text = "" }, { text = " \n " }, { text = string.rep("x", 501) }, {} }) do
        nolimit(a)
        sayM(a, "m_post", args)
        check("bad post " .. i, errOf(a) == "text")
    end
    for i, id in ipairs({ "1", -1, 1.5, 999, {} }) do
        nolimit(a)
        sayM(a, "m_pin", { id = id, on = true })
        check("bad pin " .. i, errOf(a) == "gone")
        nolimit(a)
        sayM(a, "m_del", { id = id })
        check("bad delete " .. i, errOf(a) == "gone")
    end
    -- unknown commands, other modules, empty args
    sayM(a, "m_nothing", { x = 1 })
    check("an unknown command is ignored", got(a, "t_ack") == nil)
    p = nil
    net(function() W.server.Events.OnClientCommand.fire("OtherMod", "m_save", a, { motd = "x" }) end)
    drain()
    nolimit(a)
    p = a
    a.box = {}
    net(function() W.server.Events.OnClientCommand.fire("ZeDM", "m_agree", a, nil) end)
    drain()
    check("no args is fine", okOf(a))
    check("no Lua error in any of it", not logHas("handler failed"))
end

-- ---------------------------------------------------------------------------
section("saving: revisions, the changed date, the limit, a second admin")
do
    local a = boot()
    local a2 = player("Bea", "admin")
    clientJoin(a2)
    local ack = save(a, { rules = rulesOf("One", "Two", "Three") })
    check("the first save", ack.ok and cmd().rev == 1 and cmd().rules.n == 3)
    check("every rule at revision 1", cmd().rules[3].rev == 1)
    local changed = cmd().changed
    check("changed is stamped", changed ~= nil)
    W.clock = W.clock + 86400000
    ack = save(a, { motd = "only words" })
    check("the message alone does not touch the rules", cmd().rev == 1 and cmd().changed == changed)
    local one, two, three = cmd().rules[1], cmd().rules[2], cmd().rules[3]
    ack = save(a, { rules = rulesOf({ id = two.id, text = "Two" }, { id = one.id, text = "One" }, { id = three.id, text = "Three" }) })
    check("a move keeps the revision", cmd().rev == 1 and cmd().rules[1].id == two.id and cmd().rules[1].rev == 1)
    check("a move changes the date", cmd().changed > changed)
    ack = save(a, { rules = rulesOf({ id = two.id, text = "Two" }, { id = one.id, text = "One, changed" }, { id = three.id, text = "Three" }, "Four") })
    check("a changed rule and a new one: one revision", cmd().rev == 2 and cmd().rules[2].rev == 2 and cmd().rules[4].rev == 2 and cmd().rules[1].rev == 1)
    check("its id stays", cmd().rules[2].id == one.id)
    local rev = cmd().rev
    ack = save(a, { rules = rulesOf({ id = two.id, text = "Two" }, { id = one.id, text = "One, changed" }, { id = three.id, text = "Three" }) })
    check("a rule taken away asks nobody again", cmd().rev == rev and cmd().rules.n == 3)
    W.server.ZeD.Cm.ASK_ON_REMOVE = true
    ack = save(a, { rules = rulesOf({ id = two.id, text = "Two" }, { id = three.id, text = "Three" }) })
    check("the switch: taken away, asked again", cmd().rev == rev + 1)
    W.server.ZeD.Cm.ASK_ON_REMOVE = false
    -- ask with no rules
    ack = save(a, { rules = rulesOf(), ask = true })
    check("no rules: the tick does not hold", cmd().ask == false and cmd().rules.n == 0)
    -- the limit: starts on an accepted save, and a refused one costs nothing
    nolimit(a)
    sayM(a, "m_save", { motd = 5, appeal = "", rules = rulesOf(), base = cmd().saves })
    check("refused", errOf(a) == "text")
    sayM(a, "m_save", { motd = "a", appeal = "", rules = rulesOf(), base = cmd().saves })
    check("a refused save starts no limit", okOf(a))
    sayM(a, "m_save", { motd = "b", appeal = "", rules = rulesOf(), base = cmd().saves })
    check("the next one waits", errOf(a) == "wait" and cmd().motd == "a")
    -- two admins on the same words
    local base = cmd().saves
    nolimit(a)
    sayM(a, "m_save", { motd = "mine", appeal = "", rules = rulesOf(), base = base })
    nolimit(a2)
    sayM(a2, "m_save", { motd = "theirs", appeal = "", rules = rulesOf(), base = base })
    local g = got(a2, "t_ack")
    check("a Save from an older copy is stopped", g.ok == false and g.err == "stale" and g.by == "Hermit" and g.base == base + 1 and cmd().motd == "mine")
    nolimit(a2)
    sayM(a2, "m_save", { motd = "theirs", appeal = "", rules = rulesOf(), base = g.base })
    check("a second press goes through", okOf(a2) and cmd().motd == "theirs")
    -- the log
    check("a save is logged through Srv.action", logHas("community | rules saved | Hermit | - | "))
    local line = nil
    for _, l in ipairs(W.logs) do if string.find(l.line, "rules saved", 1, true) then line = l.line end end
    local fields = 1
    for _ in string.gmatch(line, " | ") do fields = fields + 1 end
    check("seven fields", fields == 7, line)
    local ring = W.server.ZeD.Srv.A.md.log
    local seen = false
    for i = 1, ring.n do if ring[i].kind == "community" then seen = true end end
    check("the action ring holds it", seen)
end

-- ---------------------------------------------------------------------------
section("joining and agreeing")
do
    local a = boot()
    save(a, { motd = "Hi", ask = true, rules = rulesOf("One", "Two", "Three") })
    local u = player("Aretha", "user")
    local cu = clientJoin(u)
    check("the first join is asked", Mo(cu).view.ask == true)
    advance(100)
    check("the screen goes up", cu.shown == 1)
    check("nothing is marked NEW the first time", #Mo(cu).newRules() == 0)
    check("no agreement yet", cmd().agreed.aretha == nil)
    Mo(cu).agree()
    advance(100)
    check("I agree reaches the server", cmd().agreed.aretha ~= nil and cmd().agreed.aretha.rev == cmd().rev)
    check("the screen is not asked for twice", cu.shown == 1)
    check("the view says no more", Mo(cu).view.ask == nil and Mo(cu).view.since == 1)
    check("the agreement is logged", logHas("community | agreed to the rules | Aretha | "))
    -- a respawn: the same connection
    nolimit(u)
    cu.env.Events.OnCreatePlayer.fire(0, u)
    advance(500)
    check("a respawn asks nothing", cu.shown == 1)
    -- rejoin, nothing changed
    offline(u)
    nolimit(u)
    W.online[#W.online + 1] = u
    cu = clientJoin(u)
    advance(100)
    check("back with nothing changed: not asked", cu.shown == 0 and Mo(cu).view.ask == nil)
    -- a rule changes while they are on: not during play
    local r = cmd().rules
    save(a, { rules = rulesOf({ id = r[1].id, text = "One" }, { id = r[2].id, text = "Two, new" }, { id = r[3].id, text = "Three" }) })
    flush()
    check("on the server when the rules change: nothing pops up", cu.shown == 0)
    check("but the view knows", Mo(cu).view.ask == true and Mo(cu).view.rules[2].text == "Two, new")
    nolimit(u)
    cu.env.Events.OnCreatePlayer.fire(0, u)
    advance(500)
    check("a respawn after the change still waits for the next join", cu.shown == 0)
    offline(u)
    nolimit(u)
    W.online[#W.online + 1] = u
    cu = clientJoin(u)
    advance(100)
    check("the next join is asked again", cu.shown == 1)
    check("rule 2 is NEW", #Mo(cu).newRules() == 1 and Mo(cu).newRules()[1] == 2)
    -- Leave: the client goes, nothing is recorded
    Mo(cu).leave()
    advance(100)
    check("Leave disconnects", cu.left == 1)
    check("Leave agrees to nothing", cmd().agreed.aretha.rev == 1)
    -- reask off
    nolimit(a)
    save(a, { reask = false })
    W.online[#W.online + 1] = u
    nolimit(u)
    cu = clientJoin(u)
    advance(100)
    check("Ask again off: an old agreement stands", cu.shown == 0)
    local v = player("Mags", "user")
    local cv = clientJoin(v)
    advance(100)
    check("Ask again off: a new player is still asked", cv.shown == 1)
    -- ask off
    save(a, { ask = false, reask = true })
    local w = player("Tjk", "user")
    local cw = clientJoin(w)
    advance(100)
    check("Ask off: nobody is asked", cw.shown == 0)
    -- a client that names a later revision, or none
    save(a, { ask = true })
    sayM(w, "m_agree", { rev = 9999 })
    check("a later revision counts as now", cmd().agreed.tjk.rev == cmd().rev)
    nolimit(w)
    sayM(w, "m_agree", { rev = "x" })
    check("a bad revision counts as now", cmd().agreed.tjk.rev == cmd().rev)
    -- agreeing to the words on screen, when they change as you read
    local x = player("Zed", "user")
    local cx = clientJoin(x)
    advance(100)
    local shown = Mo(cx).view.rev
    r = cmd().rules
    save(a, { rules = rulesOf({ id = r[1].id, text = "One, again" }, { id = r[2].id, text = r[2].text }, { id = r[3].id, text = r[3].text }) })
    sayM(x, "m_agree", { rev = shown })
    check("agreeing to an older copy: asked again next time", cmd().agreed.zed.rev == shown and cmd().rev == shown + 1)
    -- case: the game's login matches any case
    local y = player("ARETHA", "user")
    local cy = clientJoin(y)
    check("a name in other case is the same player", Mo(cy).view.since == 1)
    -- the cap
    cmd().agreedN = Cm().L.AGREED_MAX + 1
    cmd().agreed.ancient = { rev = 1, t = 1 }
    nolimit(x)
    sayM(x, "m_agree", { rev = cmd().rev })
    check("past the cap the oldest goes", cmd().agreed.ancient == nil and cmd().agreedN == Cm().L.AGREED_MAX)
end

-- ---------------------------------------------------------------------------
section("never a trap")
do
    -- no server part at all: no hello answers
    world()
    local p0 = player("Kade", "user")
    W.server.Events.OnClientCommand.list = {}
    local c = clientJoin(p0)
    advance(45000)
    check("no server part: present is false", c.env.ZeD.ServerPart.present == false)
    check("no server part: nothing is live", not Mo(c).live() and Mo(c).view == nil)
    check("no server part: no screen", c.shown == 0)
    check("no server part: no appeal", Mo(c).appeal() == nil)

    -- a server part without community (Phases 1 to 4 only)
    W = { noCommunityNext = true }
    world()
    W.noCommunityNext = nil
    local p1 = player("Kade", "user")
    local c1 = clientJoin(p1)
    advance(500)
    check("an older server part: link up, no community", c1.env.ZeD.ServerPart.present == true and c1.env.ZeD.ServerPart.cm == false)
    check("an older server part: nothing shows", not Mo(c1).live() and c1.shown == 0)
    W = nil

    -- the answer is lost on the way
    local a = boot()
    save(a, { ask = true, rules = rulesOf("One") })
    local u = player("Aretha", "user")
    local cu = clientJoin(u)
    advance(100)
    check("asked", cu.shown == 1 and Mo(cu).askAt == nil)
    local saved = W.server.Events.OnClientCommand.list
    W.server.Events.OnClientCommand.list = {}
    Mo(cu).agree()
    advance(20000)
    W.server.Events.OnClientCommand.list = saved
    check("no answer holds nobody: the model waits for nothing", Mo(cu).askAt == nil)
    check("nothing was recorded", cmd().agreed.aretha == nil)
    check("the lost answer's request is forgotten with no error", next(cu.env.ZeD.Tickets.pend) == nil)
    offline(u)
    nolimit(u)
    W.online[#W.online + 1] = u
    cu = clientJoin(u)
    advance(100)
    check("so they are asked next time", cu.shown == 1)

    -- a screen that cannot draw is not a wall
    local v = player("Mags", "user")
    local cv = clientJoin(v, true)
    cv.env.ZeD.Community.joinScreen = function() error("it broke") end
    cv.env.ZeD.Community.joined = nil
    local logged = nil
    cv.env.ZeD.logOnce = function(k) logged = k end
    nolimit(v)
    cv.env.ZeD.Community.askAt = 1
    advance(100)
    check("a screen that fails is logged and let go", logged ~= nil and cv.env.ZeD.Community.askAt == nil)

    -- frozen: reads work, writes stop, nobody is asked
    cmd().schema = 99
    CT().md = nil
    CT().frozen = nil
    W.server.ZeD.Srv.openCommunity()
    check("newer data freezes", CT().frozen == true)
    local w = player("Tjk", "user")
    local cw = clientJoin(w)
    advance(100)
    check("frozen: nobody is asked", cw.shown == 0 and Mo(cw).view.ask == nil)
    check("frozen: the words still read", Mo(cw).view.rules.n == 1 and Mo(cw).view.frozen == true)
    local ack = save(a, { motd = "x" })
    check("frozen: Save is refused", ack.ok == false and ack.err == "frozen")
    nolimit(a)
    sayM(a, "m_post", { text = "x" })
    check("frozen: Post is refused", errOf(a) == "frozen")
    nolimit(w)
    sayM(w, "m_agree", { rev = 1 })
    check("frozen: an agreement is refused", errOf(w) == "frozen" and cmd().agreed.tjk == nil)
    CT().frozen = nil
    cmd().schema = 1

    -- a missing step
    local Cap = W.server.Capability
    W.server.Capability = setmetatable({}, { __index = function(_, k) if k == "ChangeAndReloadServerOptions" then return nil end return Cap[k] end })
    W.server.ZeD.Srv.helloAdds.community = nil
    W.server.ZeD.Srv.handlers["ZeDM.m_save"] = nil
    runFile(W.server, "42/media/lua/server/ZeD/ZeD_ServerCommunity.lua")
    check("a capability a later game renamed leaves this part off", W.server.ZeD.Srv.helloAdds.community == nil and W.server.ZeD.Srv.handlers["ZeDM.m_save"] == nil)
    W.server.Capability = Cap
end

-- ---------------------------------------------------------------------------
section("the news")
do
    local a = boot()
    local m = player("Rosa", "moderator")
    local cm2 = clientJoin(m)
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    sayM(a, "m_post", { text = "Trading post Saturday", pin = true })
    check("posted", okOf(a) and got(a, "t_ack").id == 1)
    advance(100)
    check("in everyone's tab now", Mo(cu).view.news.n == 1 and Mo(cu).view.news[1].text == "Trading post Saturday")
    check("by the poster", Mo(cu).view.news[1].by == "Hermit" and Mo(cu).view.news[1].t ~= nil and Mo(cu).view.news[1].pin == true)
    sayM(m, "m_post", { text = "Vehicle claims are coming" })
    advance(100)
    W.clock = W.clock + 6000
    nolimit(a)
    sayM(a, "m_post", { text = "Restart at 4", pin = true })
    nolimit(m)
    sayM(m, "m_post", { text = "Newest plain" })
    flush()
    local n = Mo(cu).view.news
    check("pinned first, newest first", n[1].text == "Restart at 4" and n[2].text == "Trading post Saturday" and n[3].text == "Newest plain" and n[4].text == "Vehicle claims are coming",
        n[1].text .. "/" .. n[2].text .. "/" .. n[3].text)
    nolimit(m)
    sayM(m, "m_post", { text = "too soon" })
    nolimit(a)
    sayM(a, "m_pin", { id = 1, on = false })
    flush()
    check("unpinned", cmd().news[1].pin == false and Mo(cu).view.news[1].text == "Restart at 4" and Mo(cu).view.news[5].text == "Trading post Saturday")
    nolimit(a)
    sayM(a, "m_del", { id = 2 })
    flush()
    check("deleted, for everyone", Mo(cu).view.news.n == 4 and cmd().news[2] == nil)
    check("each edit is logged", logHas("news posted") and logHas("news unpinned") and logHas("news deleted"))
    sayM(u, "m_get", {})
    W.clock = W.clock + 6000
    -- the cap: the oldest that is not pinned goes
    for i = 1, Cm().L.NEWS_MAX do
        nolimit(a)
        sayM(a, "m_post", { text = "post " .. i })
    end
    check("the news is capped", cmd().newsN == Cm().L.NEWS_MAX)
    check("the pinned stayed", cmd().news[3] ~= nil and cmd().news[3].pin == true and cmd().news[4] == nil)
    for _, post in pairs(cmd().news) do post.pin = true end
    nolimit(a)
    sayM(a, "m_post", { text = "nowhere" })
    check("all pinned: said so", errOf(a) == "pinned")
    -- limits
    for _, post in pairs(cmd().news) do post.pin = false end
    nolimit(a)
    sayM(a, "m_post", { text = "one" })
    sayM(a, "m_post", { text = "two" })
    check("posting is paced", errOf(a) == "wait")
    -- a view stays small
    local v = got(a, "m_view") or W.server.ZeD.Srv.M
    local size = 0
    local function count(t)
        for k, x in pairs(t) do
            size = size + #tostring(k)
            if type(x) == "table" then count(x) else size = size + #tostring(x) end
        end
    end
    nolimit(a)
    for _, post in pairs(cmd().news) do post.text = string.rep("x", 500) end
    for i = 1, 30 do cmd().rules[i] = { id = i, text = string.rep("y", 200), rev = 1 } end
    cmd().rules.n = 30
    sayM(a, "m_get", {})
    count(got(a, "m_view"))
    check("the largest view is under the ceiling", size < 200000, size)
end

-- ---------------------------------------------------------------------------
section("the appeal line")
do
    local a, ca = boot()
    save(a, { appeal = "discord.gg/knox" })
    advance(100)
    check("the client has it", Mo(ca).appeal() == "discord.gg/knox")
    check("kept on this computer", W.files["ZeD_appeal.txt"] == "10.0.0.5:16261|discord.gg/knox\n", W.files["ZeD_appeal.txt"])
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    check("off the server it comes from the file", Mo(cu).kept("10.0.0.5:16261") == "discord.gg/knox")
    check("another server has none", Mo(cu).kept("10.0.0.5:16262") == nil)
    -- with a | in it
    save(a, { appeal = "a|b" })
    advance(100)
    check("a bar stays", Mo(ca).kept("10.0.0.5:16261") == "a|b")
    -- with no view: the kept line
    Mo(cu).view = nil
    check("no view: the kept line", Mo(cu).appeal() == "a|b")
    -- an owner takes it away
    save(a, { appeal = "" })
    advance(100)
    check("taken away, it leaves the file", Mo(ca).kept("10.0.0.5:16261") == nil and Mo(ca).appeal() == nil)
    -- servers are capped
    W.files["ZeD_appeal.txt"] = ""
    Mo(ca).keptNow = nil
    for i = 1, 55 do
        W.ip = "10.0.0." .. i
        Mo(ca).keptNow = nil
        Mo(ca).keep("line " .. i)
    end
    local lines = 0
    for _ in string.gmatch(W.files["ZeD_appeal.txt"], "\n") do lines = lines + 1 end
    check("fifty servers, oldest out", lines == 50 and Mo(ca).kept("10.0.0.1:16261") == nil and Mo(ca).kept("10.0.0.55:16261") == "line 55")
    W.ip = "10.0.0.5"
    -- a timed ban carries it: their client may never have heard it
    nolimit(a)
    save(a, { appeal = "discord.gg/knox" })
    local b = player("Griefer", "user")
    local cb = clientJoin(b)
    W.files["ZeD_appeal.txt"] = nil
    cb.env.ZeD.Community.view = nil
    local shown = nil
    cb.env.ZeD.Admin.leaveScreen = function(info) shown = info end
    nolimit(a)
    say(a, "a_ban", { user = "Griefer", reason = "griefing", len = "d1" })
    advance(1000)
    check("the ban's words reach the client", shown ~= nil and shown.reason == "griefing")
    check("with the appeal line", shown and shown.appeal == "discord.gg/knox", shown and shown.appeal)
    -- what is and is not a removal
    check("a kick reads as removed", Mo(ca).isRemoved("You were kicked. Reason: griefing"))
    check("a ban reads as removed", Mo(ca).isRemoved("You are banned from this server. Reason: griefing") and Mo(ca).isRemoved("You are banned from this server"))
    check("the game's own ban words", Mo(ca).isRemoved("You were banned"))
    check("a lost server does not", not Mo(ca).isRemoved("Connection to server lost") and not Mo(ca).isRemoved(nil))
end

-- ---------------------------------------------------------------------------
section("a report from chat")
do
    local a = boot()
    local u = player("Aretha", "user")
    local cu = clientJoin(u)
    local rep = { who = "mike_d", n = 3,
        { who = "Kade_R", text = "anyone seen my truck?", t = "9:31" },
        { who = "mike_d", text = "lol nope", t = "9:32", mark = true },
        { who = "Rosa", text = "file a ticket", t = "9:33" } }
    local back = nil
    local r = cu.env.ZeD.Tickets.ask("GRIEF", false, "he took it", function(x) back = x end, rep)
    advance(100)
    check("sent", r == "sent" and back and back.ok == true)
    local T2 = W.server.ZeD.Srv.T
    local rec = T2.md.tickets[back.id]
    check("the name and the chat are on the record", rec.report and rec.report.who == "mike_d" and rec.report.n == 3 and rec.report[2].mark == true)
    check("the game's ticket holds none of it", not string.find(back.file, "mike_d", 1, true) and not string.find(back.file, "lol", 1, true))
    local chars = #"he took it" + #"anyone seen my truck?" + #"lol nope" + #"file a ticket"
    check("its words count against the table", T2.md.chars == chars, T2.md.chars)
    sayT(u, "t_one", { id = back.id })
    local one = got(u, "t_one")
    check("the reporter's own view has it", one and one.report and one.report.who == "mike_d" and one.report[2].text == "lol nope")
    local keys = keysIn(one)
    check("a report's view leaves out staff's fields", not keys.notes and not keys.near and not keys.assignee)
    sayT(a, "t_card", { id = back.id })
    local card = got(a, "t_card")
    check("staff read it", card and card.report and card.report.who == "mike_d" and card.report.n == 3)
    -- deleting gives the words back
    sayT(a, "t_delete", { id = back.id })
    check("deleted: every character back", T2.md.chars == 0, T2.md.chars)
    -- hostile shapes
    for i, bad in ipairs({ "x", {}, { who = 5 }, { who = "" }, { who = "x", n = 12 }, { who = "x", n = -1 }, { who = "x", n = 1 }, { who = "x", n = 1, "plain" },
        { who = "x", n = 1, { who = 1, text = "a" } }, { who = "x", n = 1, { who = "a", text = {} } } }) do
        nolimit(u)
        sayT(u, "t_new", { kind = "GRIEF", text = "words", report = bad })
        check("bad report " .. i .. " is refused", errOf(u) == "text", errOf(u))
    end
    check("no bad report is filed", next(T2.md.tickets) == nil)
    nolimit(u)
    sayT(u, "t_new", { kind = "GRIEF", text = "cut", report = { who = "x\ny", n = 1, { who = "a", text = "line\none" .. string.rep("z", 400), t = string.rep("9", 40), mark = "yes" } } })
    local id = got(u, "t_ack").id
    local l = T2.md.tickets[id].report[1]
    check("a line is cut and cleaned", #l.text == 300 and not string.find(l.text, "\n", 1, true), #l.text)
    check("the time is cut", #l.t == 16 and l.mark == nil)
    check("a name is one line", T2.md.tickets[id].report.who == "x y")
    -- without a report nothing changes
    nolimit(u)
    sayT(u, "t_new", { kind = "BUG", text = "plain" })
    check("no report: no field", T2.md.tickets[got(u, "t_ack").id].report == nil)
    -- without the server part the report stays home: a game ticket is public
    local w = player("Mags", "user")
    local cw = clientJoin(w)
    cw.env.ZeD.ServerPart.forceOff = true
    local filed = {}
    cw.env.addTicket = function(_, m) filed[#filed + 1] = m end
    cw.env.getTickets = function() end
    cw.env.ZeD.Tickets.ask("GRIEF", false, "he took it", nil, rep)
    check("no server part: the chat is not filed", filed[1] ~= nil and not string.find(filed[1], "lol", 1, true))
end

-- ---------------------------------------------------------------------------
section("a restart")
do
    local a = boot()
    save(a, { motd = "Hi", appeal = "x", ask = true, rules = rulesOf("One") })
    sayM(a, "m_agree", { rev = 1 })
    nolimit(a)
    sayM(a, "m_post", { text = "news", pin = true })
    local before = cmd()
    local rev, saves = before.rev, before.saves
    W.server = nil
    serverStart()
    check("the same table", cmd() == before and cmd().rev == rev and cmd().saves == saves)
    check("everything is there", cmd().motd == "Hi" and cmd().rules.n == 1 and cmd().news[1].text == "news" and cmd().agreed.hermit ~= nil)
    for k in pairs(W.moddata) do
        if string.sub(k, 1, 7) == "ZeD_CM_" then check("one table", k ~= nil) end
    end
    local names = 0
    for k in pairs(W.moddata) do if string.sub(k, 1, 7) == "ZeD_CM_" then names = names + 1 end end
    check("no second table", names == 1)
    -- a restored backup leaves two: the first by name, and a log line
    W.moddata["ZeD_CM_00000"] = { schema = 1 }
    W.server = nil
    serverStart()
    check("two tables: the first by name", logHas("admin | community tables | @server | - | - | found 2;"))
end

-- ---------------------------------------------------------------------------
section("the review: only a real answer writes anything")
do
    local a = boot()
    local u = player("Kade", "user")
    clientJoin(u)
    local lines = #W.logs
    sayM(u, "m_agree", { rev = 0 })
    check("not being asked: an answer, and nothing else", okOf(u) and got(u, "m_view") == nil)
    check("no record", cmd().agreed.kade == nil and cmd().agreedN == 0)
    check("no line", #W.logs == lines)
    -- the record that would have said they agreed to rules they were never shown
    save(a, { rules = rulesOf("One") })
    save(a, { ask = true })
    nolimit(u)
    sayM(u, "m_get", {})
    check("rules added later ask them", got(u, "m_view").ask == true)
    nolimit(u)
    sayM(u, "m_agree", { rev = 1 })
    check("a real answer is kept", cmd().agreed.kade ~= nil and logCount("agreed to the rules | Kade | ") == 1)
    for _ = 1, 5 do
        nolimit(u)
        sayM(u, "m_agree", { rev = 1 })
    end
    check("the same answer again writes nothing", logCount("agreed to the rules | Kade | ") == 1 and got(u, "m_view") == nil)
end

-- ---------------------------------------------------------------------------
section("the review: a client that skips the screen")
do
    local a = boot()
    save(a, { ask = true, rules = rulesOf("One") })
    local L = Cm().L
    local skip = player("Lee", "user")
    local cs = clientJoin(skip)
    advance(600)
    check("asked", cs.shown == 1 and Mo(cs).view.ask == true)
    local ok1 = player("Bea", "user")
    clientJoin(ok1)
    nolimit(ok1)
    sayM(ok1, "m_agree", { rev = 1 })
    local gone = player("Dee", "user")
    clientJoin(gone)
    offline(gone)
    advance(L.ASKED_MS - 2000)
    check("still reading: no line", logCount("rules not answered") == 0)
    advance(L.ASKED_LOOK_MS + 3000)
    check("no answer: one line, on the log staff read", logCount("rules not answered") == 1 and logCount("Lee") >= 1)
    check("in the ring", (function()
        for _, e in pairs(md().log) do
            if type(e) == "table" and e.what == "rules not answered" and e.kind == "community" then return e.who == "Lee" end
        end
        return false
    end)())
    advance(L.ASKED_MS)
    check("one line for a connection", logCount("rules not answered") == 1)
    check("someone who answered, and someone who left, get none", not logHas("rules not answered | Bea") and not logHas("rules not answered | Dee"))
    check("who left is forgotten", CT().here.dee == nil)
    -- a respawn's hello is not a join: the screen does not come back, so it is not a skip
    local late = player("Oki", "user")
    clientJoin(late)
    nolimit(late)
    sayM(late, "m_agree", { rev = 1 })
    save(a, { rules = rulesOf({ id = cmd().rules[1].id, text = "One" }, "Two") })
    W.server.ZeD.Srv.mem[late.name] = nil
    W.clients[late.name].env.Events.OnCreatePlayer.fire(0, late)
    advance(L.ASKED_MS + L.ASKED_LOOK_MS + 1000)
    check("a rule changed while on: no line", not logHas("rules not answered | Oki"))
end

-- ---------------------------------------------------------------------------
section("the review: the board")
do
    local a = boot()
    local m = player("Rosa", "moderator")
    clientJoin(m)
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    sayM(a, "m_post", { text = "one" })
    advance(100)
    check("the first change goes to everyone at once", Mo(cu).view.news.n == 1)
    u.box = {}
    nolimit(a)
    sayM(a, "m_post", { text = "two" })
    check("whoever pressed has it now", got(a, "m_view") and got(a, "m_view").news.n == 2)
    check("the rest wait", got(u, "m_view") == nil)
    nolimit(a)
    sayM(a, "m_pin", { id = 1, on = true })
    nolimit(a)
    sayM(a, "m_pin", { id = 1, on = false })
    check("still waiting", got(u, "m_view") == nil)
    flush()
    check("then one push carries all of it", boxCount(u, "m_view") == 1 and Mo(cu).view.news.n == 2)
    -- no change, nothing sent
    sayM(a, "m_pin", { id = 1, on = true })
    flush()
    nolimit(a)
    u.box = {}
    local lines = logCount("news pinned")
    sayM(a, "m_pin", { id = 1, on = true })
    check("pinning what is pinned: an answer", okOf(a))
    check("no line, no view", logCount("news pinned") == lines and got(a, "m_view") == nil)
    flush()
    check("and nobody else hears", got(u, "m_view") == nil)
    -- a role does not touch what one above it wrote
    nolimit(m)
    sayM(m, "m_del", { id = 1 })
    check("a moderator can't delete an admin's post", errOf(m) == "rank" and cmd().news[1] ~= nil)
    nolimit(m)
    sayM(m, "m_pin", { id = 1, on = false })
    check("or unpin it", errOf(m) == "rank" and cmd().news[1].pin == true)
    nolimit(m)
    sayM(m, "m_post", { text = "mine" })
    local mine = got(m, "t_ack").id
    nolimit(m)
    sayM(m, "m_pin", { id = mine, on = true })
    check("their own they can", okOf(m))
    nolimit(a)
    sayM(a, "m_del", { id = mine })
    check("an admin can reach down", okOf(a) and cmd().news[mine] == nil)
    check("a post's rank stays home", keysIn(got(a, "m_view") or {}).rank == nil)
    local Adm = W.server.ZeD.Adm
    Adm.RANK_GUARD = false
    nolimit(m)
    sayM(m, "m_del", { id = 2 })
    check("the switch off: a moderator can", okOf(m))
    Adm.RANK_GUARD = true
    -- a full board
    for i = 1, Cm().L.NEWS_MAX do
        nolimit(a)
        sayM(a, "m_post", { text = "post " .. i, pin = i > 1 })
    end
    check("a post pushed off leaves its words in the log", logHas("news pushed off the board") and logHas(": one"))
    nolimit(a)
    sayM(a, "m_post", { text = "last plain" })
    nolimit(a)
    sayM(a, "m_post", { text = "over" })
    check("every post pinned: its own word", errOf(a) == "pinned", errOf(a))
end

-- ---------------------------------------------------------------------------
section("the review: a report that names staff")
do
    local a = boot()
    local rosa = player("Rosa", "moderator")
    clientJoin(rosa)
    local bea = player("Bea", "moderator")
    clientJoin(bea)
    local u = player("Aretha", "user")
    local cu = clientJoin(u)
    local rep = { who = "ROSA", n = 1, { who = "Rosa", text = "move along", t = "9:32", mark = true } }
    local back = nil
    cu.env.ZeD.Tickets.ask("GRIEF", false, "she took it", function(x) back = x end, rep)
    advance(100)
    local T2 = W.server.ZeD.Srv.T
    local rec = T2.md.tickets[back.id]
    sayT(rosa, "t_spam", { id = back.id })
    check("named, in any case: no Spam", errOf(rosa) == "named" and rec.status ~= "Spam", errOf(rosa))
    sayT(rosa, "t_close", { id = back.id })
    check("no Close", errOf(rosa) == "named" and rec.status ~= "Closed")
    sayT(rosa, "t_answer", { id = back.id, text = "no I did not" })
    check("no Answer", errOf(rosa) == "named" and rec.thread.n == 1)
    sayT(bea, "t_answer", { id = back.id, text = "looking at it" })
    check("another moderator can", okOf(bea) and rec.thread.n == 2)
    check("and it is in the log staff read", (function()
        for _, e in pairs(md().log) do
            if type(e) == "table" and e.what == "report answered" and e.kind == "ticket" then return e.who == "Bea" and e.target == "ROSA" end
        end
        return false
    end)())
    sayT(a, "t_close", { id = back.id })
    check("so can an admin", okOf(a) and rec.status == "Closed" and logHas("report closed"))
    -- an admin named is still an admin
    local rep2 = { who = "Hermit", n = 0 }
    nolimit(u)
    cu.env.ZeD.Tickets.ask("GRIEF", false, "him too", function(x) back = x end, rep2)
    advance(100)
    sayT(a, "t_spam", { id = back.id })
    check("somebody has to be able to", okOf(a) and logHas("report marked spam"))
    sayT(a, "t_delete", { id = back.id })
    check("deleted, and said", okOf(a) and logHas("report deleted"))
    -- a plain ticket is left alone
    nolimit(u)
    cu.env.ZeD.Tickets.ask("BUG", false, "plain", function(x) back = x end)
    advance(100)
    local before = logCount("report closed")
    sayT(rosa, "t_close", { id = back.id })
    check("a ticket with no report: as before", okOf(rosa) and logCount("report closed") == before)
    -- one switch
    local Tk = W.server.ZeD.Tk
    check("the server's limit comes from the client's reach", Tk.LIMITS.REPORT_LINES == 2 * Tk.REPORT_AROUND + 1)
end

-- ---------------------------------------------------------------------------
section("the review: the game's words, asked properly")
do
    local a, ca = boot()
    local M = Mo(ca)
    local calls, bare = 0, 0
    ca.env.getText = function(k, x)
        calls = calls + 1
        local s = W.texts[k] or k
        if x == nil and string.find(s, "%1", 1, true) then bare = bare + 1 end
        if x ~= nil then s = string.gsub(s, "%%1", tostring(x)) end
        return s
    end
    M.heads = nil
    for _ = 1, 10 do M.isRemoved("Wrong password") end
    check("no word is asked without its argument", bare == 0, bare)
    check("asked once, not every frame", calls == 4, calls)
    check("a ban with a reason still reads", M.isRemoved("You are banned from this server. Reason: griefing"))
    check("cut at the reason", M.isRemoved("You were kicked. Reason: griefing"))
    check("a lost server still does not", not M.isRemoved("Connection lost"))
end


-- ---------------------------------------------------------------------------
-- RULES THAT HOLD (the director, Nov 7 2026): until a player agrees every ZeD command is refused; five minutes unanswered owes
-- a Kick; a player who never says hello is found by the server's own walk
-- ---------------------------------------------------------------------------
section("the join rules: every ZeD command refused until they agree")
do
    local a = boot()
    save(a, { ask = true, rules = rulesOf("One") })
    local Srv = W.server.ZeD.Srv
    local ran = {}
    for _, mod in ipairs({ "ZeDC", "ZeDX", "ZeDL", "ZeDDash" }) do
        Srv.modules[mod] = true
        Srv.register(mod, "probe", {}, function() ran[mod] = (ran[mod] or 0) + 1 end)
    end
    local u = player("Lee", "user")
    local cu = clientJoin(u)
    cu.env.ZeD.Community.qaHold = true
    advance(600)
    local function fire(mod, cmd, args)
        u.box = {}
        nolimit(u)
        net(function() W.server.Events.OnClientCommand.fire(mod, cmd, u, wire(args or {})) end)
        drain()
    end
    for _, mod in ipairs({ "ZeDC", "ZeDX", "ZeDL", "ZeDDash" }) do
        fire(mod, "probe")
        check("not agreed: " .. mod .. " (claims, extras, log, dash) refused", ran[mod] == nil)
    end
    fire("ZeDT", "t_mine")
    check("not agreed: tickets refused", errOf(u) == "perm" and got(u, "t_mine") == nil)
    fire("ZeDA", "a_players")
    check("not agreed: admin refused", errOf(u) == "perm")
    fire("ZeDM", "m_post", { text = "hi" })
    check("not agreed: community refused", errOf(u) == "perm")
    check("a line says why, one a minute", logHas("refused | Lee | - | - | has not agreed to the rules"))
    fire("ZeD", "hello", { v = 1 })
    check("the hello stays open", got(u, "hello") ~= nil)
    fire("ZeDM", "m_get")
    check("reading the rules stays open", got(u, "m_view") ~= nil)
    fire("ZeDM", "m_agree", { rev = 1 })
    check("agreeing stays open", okOf(u) and cmd().agreed.lee ~= nil)
    for _, mod in ipairs({ "ZeDC", "ZeDX", "ZeDL", "ZeDDash" }) do
        fire(mod, "probe")
        check("agreed: " .. mod .. " runs", ran[mod] == 1)
    end
    fire("ZeDT", "t_mine")
    check("agreed: tickets answer", got(u, "t_mine") ~= nil)
    -- nobody asked mid-play: a rule changed while someone is on shuts nothing
    local v = player("Bea", "user")
    clientJoin(v)
    nolimit(v)
    sayM(v, "m_agree", { rev = 1 })
    save(a, { rules = rulesOf({ id = cmd().rules[1].id, text = "One" }, "Two") })
    nolimit(v)
    sayT(v, "t_mine", {})
    check("a rule added while on: still open", got(v, "t_mine") ~= nil)
end

section("the join rules answered: every part asks again for what the gate refused")
do
    local a = boot()
    save(a, { ask = true, rules = rulesOf("One") })
    local Srv = W.server.ZeD.Srv
    -- (a handler runs only past the gates and its limit: what ran for this player is what the server answered)
    local ran = {}
    for _, h in pairs(Srv.handlers) do
        local fn, name = h.fn, h.name
        h.fn = function(p, ...)
            if p:getUsername() == "Rae" then ran[name] = (ran[name] or 0) + 1 end
            return fn(p, ...)
        end
    end
    local u = player("Rae", "user")
    local cu = clientJoin(u)
    advance(600)
    check("asked at joining: the hello was answered", ran.hello == 1 and Mo(cu).view ~= nil and Mo(cu).view.ask == true)
    check("meanwhile the gate refused my tickets (admin's hello is left open)", ran.t_mine == nil and ran.a_hi == 1)
    Mo(cu).agree(Mo(cu).view.rev)
    advance(600)
    check("the agreement is taken", cmd().agreed.rae ~= nil and ran.m_agree == 1)
    check("the client counts it", cu.env.ZeD.ServerPart.agreedN == 1)
    check("the hello waits out its limit rather than be refused", ran.hello == 1 and cu.env.ZeD.ServerPart.helloDue ~= nil)
    local SP = cu.env.ZeD.ServerPart
    check("with a second to spare, so jitter can't land it early and get it refused", SP.helloDue and SP.helloAt
        and SP.helloDue - SP.helloAt >= W.server.ZeD.Tk.LIMITS.HELLO_MS + 1000, SP.helloDue and SP.helloAt and (SP.helloDue - SP.helloAt))
    advance(W.server.ZeD.Tk.LIMITS.HELLO_MS)
    check("then the hello goes again and is answered", ran.hello == 2)
    check("tickets asked again: my tickets come", ran.t_mine == 1)
    check("admin's hello again, past its own limit", ran.a_hi == 2)
    check("the view comes again: nothing left to ask", Mo(cu).view ~= nil and Mo(cu).view.ask ~= true)
    advance(20000)
    check("and nothing asks twice", ran.hello == 2 and ran.t_mine == 1 and ran.a_hi == 2)
end

section("the join rules: five minutes unanswered owes a Kick")
do
    local a, ca = boot()
    save(a, { ask = true, rules = rulesOf("One") })
    local L = Cm().L
    local u = player("Lee", "user")
    local cu = clientJoin(u)
    cu.env.ZeD.Community.qaHold = true
    local v = player("Bea", "user")
    local cv = clientJoin(v)
    cv.env.ZeD.Community.qaHold = true
    advance(L.ASKED_MS - 60000)
    nolimit(v)
    sayM(v, "m_agree", { rev = 1 })
    advance(60000 + L.ASKED_LOOK_MS + 2000)
    check("unanswered: the log says a kick is owed", logHas("rules not answered | Lee | - |") and logHas("a kick is owed"))
    check("a staff client makes it, with the game's own words", has(ca.slash, '/kickuser "Lee"') and not has(ca.slash, '/kickuser "Lee" -r'))
    check("whoever answered in time is not kicked", not has(ca.slash, '/kickuser "Bea"'))
    -- answered while the Kick waits for a staff client: it goes, nobody is kicked
    local m = player("Mo", "user")
    local cm = clientJoin(m)
    cm.env.ZeD.Community.qaHold = true
    offline(a)
    W.clients.Hermit.up = false
    advance(L.ASKED_MS + L.ASKED_LOOK_MS + 2000)
    local waiting = false
    for _, e in pairs(md().owed) do if e.act == "Kick" and e.target == "Mo" then waiting = true end end
    check("with no staff on, the Kick waits", waiting)
    nolimit(m)
    sayM(m, "m_agree", { rev = 1 })
    W.online[#W.online + 1] = a
    W.clients.Hermit.up = true
    ca.slash = {}
    advance(3000)
    check("answered before it landed: dropped, with a line", not has(ca.slash, '/kickuser "Mo"') and logHas("the rules were answered"))
    -- a role the game will not kick is only written down
    local s = player("Sam", "admin")
    local cs = clientJoin(s)
    cs.env.ZeD.Community.qaHold = true
    advance(L.ASKED_MS + L.ASKED_LOOK_MS + 2000)
    check("a role the game will not kick: a line, no Kick", logHas("rules not answered | Sam") and not has(ca.slash, '/kickuser "Sam"'))
end

section("the join rules: a client that never says hello is found by the walk")
do
    local a, ca = boot()
    save(a, { ask = true, rules = rulesOf("One") })
    local L = Cm().L
    -- on the server, with no ZeD client at all
    local q = player("Quiet", "user")
    advance(L.ASKED_LOOK_MS + 1000)
    check("the walk makes the record", CT().here.quiet ~= nil and CT().here.quiet.ask == true)
    nolimit(q)
    sayT(q, "t_mine", {})
    check("and the gate holds", errOf(q) == "perm")
    advance(L.ASKED_MS + L.ASKED_LOOK_MS)
    check("five minutes on: a line and a Kick", logHas("rules not answered | Quiet") and has(ca.slash, '/kickuser "Quiet"'))
    -- a command before any walk or hello makes the record too
    local r = player("Rush", "user")
    nolimit(r)
    sayT(r, "t_mine", {})
    check("the first word makes the record", errOf(r) == "perm" and CT().here.rush ~= nil)
    -- split screen: a guest on someone's connection can never answer (ZeD's client speaks for its first player only) and the
    -- game's kick by name drops the whole connection, so nothing is owed for a guest and the first player is not kicked
    local host = player("Host", "user")
    clientJoin(host)
    nolimit(host)
    sayM(host, "m_agree", { rev = 1 })
    local guest = player("Guest", "user")
    guest.num = 1
    advance(L.ASKED_LOOK_MS + 1000)
    check("split screen: the first player answered", CT().here.host ~= nil and not W.server.ZeD.Srv.rulesUnanswered("Host"))
    check("split screen: the walk makes no record for the guest", CT().here.guest == nil)
    nolimit(guest)
    sayT(guest, "t_mine", {})
    advance(L.ASKED_MS + L.ASKED_LOOK_MS + 2000)
    check("split screen: no line and no Kick for the guest", not logHas("rules not answered | Guest") and not has(ca.slash, '/kickuser "Guest"'))
    check("split screen: nor for the first player", not has(ca.slash, '/kickuser "Host"'))
    local owedGuest = false
    for _, e in pairs(md().owed) do if e.target == "Guest" or e.target == "Host" then owedGuest = true end end
    check("split screen: nothing owed on that connection", not owedGuest)
end

print("community_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
