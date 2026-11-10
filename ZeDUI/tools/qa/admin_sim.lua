-- ZeDUI/tools/qa/admin_sim.lua  (Nov 5 2026, QA; Nov 7 rules that hold): the admin tools' server side and client model with no game running.
-- Lua 5.1 stubs of the game, in the style of tickets_sim.lua, and the real files run against them: ZeD_TicketProto,
-- ZeD_AdminProto, ZeD_ServerCore, ZeD_ServerTickets, ZeD_ServerAdmin, and on each simulated client ZeD_ServerLink,
-- ZeD_Tickets and ZeD_Admin. Every message crosses a stub of the network with the game's rules, a step at a time.
-- Permissions, hostile arguments, the views, kick, warn, mute, roles and their powers, Level Up, timed bans lifting with
-- nobody on, a client that does not leave, permanent bans owed to a staff client, repeats, spawns, restarts, the fallback.
-- Nov 7: every ban is the game's (a timed one's unban owed at its end), a Kick on every stay, a ban shuts out every module,
-- Steam IDs matched on the server's own number, a client's "done" judged again, and the host helper's queue and answers.
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
            if W.addFails and W.addFails[t] then return nil end     -- (the game made nothing: InventoryItemFactory gave nil)
            self.items[#self.items + 1] = t
            return { type = t }
        end }
    end
    function p.getCurrentSquare(self)
        return { AddWorldInventoryItem = function(_, t, a, b, c)
            if W.addFails and W.addFails[t] then return nil end
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

-- the game refuses a name's or a Steam ID's ban: W.refuse[name] true always, a number that many times
local function refuser(name)
    local r = W.refuse and W.refuse[name]
    if type(r) == "number" then
        W.refuse[name] = (r > 1) and (r - 1) or nil
        return true
    end
    return r == true
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
        -- (FindItem(String) is FindItem(s, true): not found by its full type, the bare type in any module. The Item it gives
        -- has its own full type, getFullName)
        return { FindItem = function(_, s)
            if type(s) ~= "string" then error("FindItem overload") end
            local key = W.scripts[s] and s or nil
            if not key then
                local bare = string.match(s, "%.(.+)$") or s
                for k in pairs(W.scripts) do
                    if string.match(k, "%.(.+)$") == bare then key = k end
                end
            end
            if not key then return nil end
            return { getFullName = function(self) return key end }
        end }
    end
    env.sendAddItemToContainer = function(inv, it) W.sent = W.sent + 1 end
    env.ISLogSystem = { writeLog = function(who, packet) W.logs[#W.logs + 1] = { name = packet.loggerName, line = packet.logText } end }
    -- the sandbox (ZeD.HostHelper), Zomboid/Lua's files (getFileWriter, getFileReader: their Java signatures), the game's
    -- Steam ID ban list as NetworkUser.isSteamIdBanned reads it (the ID back, or null)
    env.SandboxVars = { ZeD = W.sandbox }
    env.getFileWriter = function(path, create, append)
        if type(path) ~= "string" or type(create) ~= "boolean" or type(append) ~= "boolean" then error("getFileWriter overload") end
        local buf = append and (W.files[path] or "") or ""
        return { write = function(_, s) buf = buf .. s end, close = function() W.files[path] = buf; W.fileWrites = (W.fileWrites or 0) + 1 end }
    end
    env.getFileReader = function(path, create)
        if type(path) ~= "string" or type(create) ~= "boolean" then error("getFileReader overload") end
        local text = W.files[path]
        if text == nil then return nil end
        local lines, at = {}, 0
        for l in string.gmatch(text, "([^\n]*)\n") do lines[#lines + 1] = l end
        return { readLine = function() at = at + 1; return lines[at] end, close = function() end }
    end
    if W.sidList then
        -- (and getFirstBannedIPForUser: the IP the game's list holds for a name, or null)
        env.NetworkUser = { new = function() return {
            -- (W.dbFail: that many reads hit a database error, which the game catches and answers null, as "not banned")
            isSteamIdBanned = function(_, s)
                if type(s) ~= "string" then error("isSteamIdBanned overload") end
                if (W.dbFail or 0) > 0 then W.dbFail = W.dbFail - 1; return nil end
                return W.sidList[s] and s or nil
            end,
            getFirstBannedIPForUser = function(_, u)
                if type(u) ~= "string" then error("getFirstBannedIPForUser overload") end
                if (W.dbFail or 0) > 0 then W.dbFail = W.dbFail - 1; return nil end
                return W.gameIps[u] and "10.0.0.9" or nil
            end,
        } end }
    end
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
        -- a Kick: the game drops them, when this run lets it (W.kickRemoves) and the name is not one it refuses (W.noKick)
        local k = string.match(s, '^/kickuser "([^"]*)"')
        if k and W.kickRemoves and W.players[k] and not (W.noKick and W.noKick[k]) then offline(W.players[k]) end
        -- the game's rules (BanSystem): with -ip the player must be on and not on a Steam connection, or nothing happens
        local u = string.match(s, '^/banuser "([^"]*)"')
        if u then
            W.accounts = W.accounts or {}
            W.accounts[u] = true       -- (the game's ban makes the account's row if it had none: ServerWorldDatabase.banUser)
        end
        if u and W.refuser and W.refuser(u) then return end      -- (a ban that does not take: a spelling, a dropped packet)
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
    env.banUnbanUserAction = function(a, b, r)
        c.game[#c.game + 1] = a .. ":" .. b .. ":" .. r
        if a == "UnBan" or a == "UnBanIP" then W.gameBans[b] = nil end
        if a == "UnBanIP" then W.gameIps[b] = nil end
        if W.sidList and a == "BanSteamID" and not (W.refuser and W.refuser(b)) then W.sidList[b] = true end
        if W.sidList and a == "UnBanSteamID" and not (W.refuser and W.refuser("un:" .. b)) then W.sidList[b] = nil end
    end
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
    env.requestRoles, env.requestUserlog = function() end, function() end
    -- the game's user list (RequestNetworkUsersPacket, NetworkUsersPacket), with W.userList on: sent only to a role with
    -- SeeNetworkUsers, every account with its role from the game's database (a name the game banned: "banned") and
    -- inWhitelist true. W.dbDown: the game's read of its database failed, so only the players on are sent, with their live
    -- role and inWhitelist false. W.usersStale: this client's list is the one it had before (a reply to an older request)
    c.users = {}
    env.requestUsers = function()
        if not W.userList then return end
        net(function()
            if not (c.up and p.role.caps.SeeNetworkUsers) or W.usersStale then
                if c.up and W.usersStale then c.env.Events.OnNetworkUsersReceived.fire() end
                return
            end
            local names = {}
            for n in pairs(W.players) do names[n] = true end
            for n in pairs(W.gameBans) do names[n] = true end
            for n in pairs(W.accounts or {}) do names[n] = true end
            local list = {}
            for n in pairs(names) do
                local o = W.players[n]
                local isOn = false
                for _, x in ipairs(W.online) do isOn = isOn or x == o end
                local r = W.gameBans[n] and ROLES.banned or (o and o.role) or ROLES.user
                if W.dbDown then r = o and o.role end
                if not W.dbDown or isOn then
                    local wl = not W.dbDown
                    list[#list + 1] = { getUsername = function() return n end, getRole = function() return r end,
                        isInWhitelist = function() return wl end }
                end
            end
            c.users = list
            c.looked = (c.looked or 0) + 1
            c.env.Events.OnNetworkUsersReceived.fire()
        end)
    end
    env.getBannedIPs, env.getBannedSteamIDs = function() end, function() end
    env.getSteamModeActive = function() return false end
    env.getCurrentUserSteamID = function() return c.sid end
    env.getUsers = function() return jlist(c.users) end
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
        uuid = 0, scripts = { ["Base.Axe"] = true }, ground = {}, sent = 0, gameBans = {}, gameIps = {}, files = {}, refuser = refuser,
        sandbox = W and W.sandboxNext or nil, sidList = W and W.sidListNext or nil }
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
    check("the ids go with the names, for the viewer's own language", c.profId == "carpenter" and c.traitIds[1] == "Handy", tostring(c.profId))
    check("no place when they are off the map", c.x == nil)
    nolimit(a)
    say(a, "a_card", { user = "Hermit" })
    c = got(a, "a_card")
    check("online: where, and every skill", c.x == 6280 and #c.skills == 2, c.x)
    local allowed = { user = 1, on = 1, muted = 1, last = 1, prof = 1, profId = 1, traits = 1, traitIds = 1, skills = 1, role = 1, x = 1, y = 1, z = 1, oid = 1, tickets = 1, ticketN = 1, banId = 1, banUntil = 1, hidden = 1, closed = 1, id = 1, name = 1, lv = 1 }
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
    check("the game's ban waits while they read the reason", not has(ca.slash, "/banuser"))
    advance(6000)
    check("the reason shows first", cu.left == 0)
    advance(7000)
    check("then the client goes", cu.left == 1)
    advance(3000)
    check("gone on their own: no kick on their record", not has(ca.slash, "/kickuser"))
    check("and the game's own ban holds them out", has(ca.slash, '/banuser "Torch" -r "Burned the farm, twice"') and next(md().owed) == nil)
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
    check("the game's unban is owed at the end", (function()
        for _, e in pairs(md().owed) do if e.act == "UnBan" and e.target == "Torch" then return true end end
        return false
    end)())
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
    check("the game's ban removes a client that stays", has(ca.slash, '/banuser "Torch" -r "Griefing"') and cu.up == false)
    advance(6000)
    -- the game's ban did not take (W.refuse), and they come back on a modified client: told again, stays
    W.refuse = { Torch = true }
    W.online[#W.online + 1] = u
    u.box = {}
    W.clients.Torch.up = false
    advance(6000)
    check("told on joining, with the server's own eyes", got(u, "a_leave") ~= nil)
    check("found on: the game's ban did not take, and it is asked for again", logHas("game ban did not take") and md().bans[1].reowe == 1)
    advance(21000)
    check("staff hear it", has(ca.game, "note:UI_ZeD_Adm_NoteStay"))
    check("and it is on the ban", md().bans[1].stay ~= nil)
    check("a line in the log", logHas("has not left"))
    check("a stay owes a Kick", has(ca.slash, '/kickuser "Torch" -r "Griefing"'))
    local n = #ca.game
    advance(30000)
    check("not again at once", #ca.game == n)
    advance(300000)
    check("again after five minutes", #ca.game > n)
    check("the ban is asked for again REOWE_MAX times, no more", md().bans[1].reowe == 3 and md().bans[1].gaveUp == true and logHas("asked 3 times"))
    -- the old press is not needed: a timed ban already has the game's
    nolimit(a)
    say(a, "a_gameban", { id = 1 })
    check("Use the game's ban: already done", errOf(a) == "gone")
    W.refuse = nil
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
    -- (outside review, Nov 7) FindItem falls back to the bare type in any module: what is spawned and logged is the item found
    nolimit(a)
    local had = #a.items
    say(a, "a_spawn", { item = "Fake.Axe", n = 2, to = "me" })
    check("a client's module that is not the item's: the real item is spawned", okOf(a) and #a.items == had + 2 and a.items[#a.items] == "Base.Axe", a.items[#a.items])
    check("and logged by its real full type", logHas("2 x Base.Axe to me") and not logHas("Fake.Axe"))
    nolimit(a)
    say(a, "a_spawn", { item = "Fake.Axe", n = 3, to = "ground" })
    check("on the ground too", W.ground[#W.ground] == "Base.Axe" and logHas("3 x Base.Axe to ground"))
    -- the game makes nothing: not done
    W.addFails = { ["Base.Axe"] = true }
    nolimit(a)
    local lines = #W.logs
    say(a, "a_spawn", { item = "Base.Axe", n = 2, to = "me" })
    check("AddItem gives nil: acks false", got(a, "t_ack") and got(a, "t_ack").ok == false and errOf(a) == "item")
    local spawnLine = false
    for i = lines + 1, #W.logs do spawnLine = spawnLine or string.find(W.logs[i].line, "| spawn |", 1, true) ~= nil end
    check("and logs no spawn", not spawnLine)
    nolimit(a)
    say(a, "a_spawn", { item = "Base.Axe", n = 2, to = "ground" })
    check("the ground gives nil: acks false", got(a, "t_ack") and got(a, "t_ack").ok == false)
    W.addFails = nil
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
    W.refuse = { Torch = true }
    say(a, "a_ban", { user = "Torch", reason = "griefing", len = "w1" })
    for _ = 1, 8 do
        advance(6000)
        nolimit(u)
        say(u, "a_hi", {})
        drain()
    end
    check("the stay note comes all the same", has(ca.game, "note:UI_ZeD_Adm_NoteStay") and md().bans[1].stay ~= nil)
    check("the hello hears a_leave again", got(u, "a_leave") ~= nil)
    W.refuse = nil
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
    -- a timed row has the game's ban: lifting it owes one UnBan
    advance(13000)
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
    check("the game's ban went at once, through the Steam ID", has(ca.game, "BanSteamID:76561198000000044:alt"))
    check("the stay is on the row", md().bans[1].stay ~= nil)
    check("found on: asked for again", md().bans[1].reowe ~= nil and md().bans[1].reowe >= 1)
    check("and a Kick is owed", has(ca.slash, '/kickuser "Other" -r "alt"'))
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
    -- an unban asks room for three calls: the unban, the role it gives back, a Steam ID's lift
    for id in pairs(md().owed) do md().owed[id] = nil end
    local max = W.server.ZeD.Adm.L.OWED_MAX
    for i = 1, max - 2 do md().owed[1000 + i] = { id = 1000 + i, act = "UnBan", target = "t" .. i, reason = "", at = now + 99999 } end
    nolimit(a)
    say(a, "a_unban", { user = "Someone" })
    check("an unban with room for two calls: refused", errOf(a) == "full")
    md().owed[1000 + max - 2] = nil
    nolimit(a)
    say(a, "a_unban", { user = "Someone" })
    check("room for three: taken", okOf(a))
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
    -- a role change on a closed card: refused, with the same answer for an account and a name never seen
    ROLES.gm.caps.ChangeAccessLevel, ROLES.gm.caps.ModifyNetworkUsers = true, true
    nolimit(g)
    say(g, "a_role", { user = "Kade", role = "user" })
    check("no role change for an offline account without See every account", errOf(g) == "perm", tostring(errOf(g)))
    nolimit(g)
    say(g, "a_role", { user = "Nobody", role = "user" })
    check("a name never seen gets the same answer", errOf(g) == "perm", tostring(errOf(g)))
    check("and nothing waits for the game", md().watch.Kade == nil and md().watch.Nobody == nil)
    local t = player("Tom", "user")
    clientJoin(t)
    advance(6000)
    nolimit(g)
    say(g, "a_role", { user = "Tom", role = "user" })
    check("an online player's role still changes", okOf(g))
    ROLES.gm.caps.ChangeAccessLevel, ROLES.gm.caps.ModifyNetworkUsers = nil, nil
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
    nolimit(a)
    say(a, "a_role", { user = "Kade", role = "user" })
    check("and no offline role change either", errOf(a) == "perm", tostring(errOf(a)))
    CAPS.SeeNetworkUsers = savedCap
end


-- ---------------------------------------------------------------------------
-- RULES THAT HOLD (the director, Nov 7 2026): each as the task names it
-- ---------------------------------------------------------------------------
local function owedOf(act, target)
    for _, e in pairs(md().owed) do
        if e.act == act and (target == nil or e.target == target) then return e end
    end
    return nil
end
-- the answer to the command just said: the first ack (a refusal makes the client say hello again, which brings others)
local function firstErr(p)
    for i = 1, #p.box do
        if p.box[i].cmd == "t_ack" then return p.box[i].args and p.box[i].args.err end
    end
    return nil
end

section("a timed ban owes the game's ban at once, and the unban at its end")
do
    local a, ca = boot()
    local u = player("Torch", "user")
    u.steamNum = 76561198000000321
    local cu = clientJoin(u)
    cu.sid = "76561198000000321"
    nolimit(u)
    say(u, "a_hi", { sid = cu.sid })
    nolimit(a)
    say(a, "a_ban", { user = "Torch", reason = "Burned the farm", len = "d1" })
    check("acks", okOf(a))
    check("the game's ban is owed at once, after the reason", owedOf("Ban", "Torch") ~= nil)
    check("by name only: the Steam ID is the client's word, never named to the game", owedOf("BanSteamID") == nil)
    check("and the row says it holds the game's ban", md().bans[1].gameBan == true)
    advance(14000)
    check("the game's ban by name", has(ca.slash, '/banuser "Torch" -r "Burned the farm"'))
    advance(4000)
    check("never by the Steam ID the client named", not has(ca.game, "BanSteamID:76561198000000321:Burned the farm"))
    check("made", md().bans[1].made == true and next(md().owed) == nil)
    -- an offline name: the game's ban goes with no wait
    nolimit(a)
    md().players.Away = { t = 1, role = "user" }
    say(a, "a_ban", { user = "Away", reason = "Alt", len = "h1" })
    advance(1000)
    check("offline: at once", has(ca.slash, '/banuser "Away" -r "Alt"'))
    -- never short: nothing lifts before the end, with nobody on
    offline(a)
    W.clock = W.clock + 86400 * 1000 - 30000
    advance(2000)
    check("before its end: no unban owed", owedOf("UnBan", "Torch") == nil and md().bans[1] ~= nil)
    W.clock = W.clock + 40000
    advance(2000)
    check("at its end the row goes", md().bans[1] == nil)
    check("the unban is owed, the name only (no Steam ID was given)", owedOf("UnBan", "Torch") ~= nil and owedOf("UnBanSteamID") == nil)
    advance(60000)
    check("with nobody to make it, it waits: the ban runs past its time, never short", owedOf("UnBan", "Torch") ~= nil)
    local back = player("Hermit", "admin")
    W.clients.Hermit = nil
    local c2 = clientJoin(back)
    advance(2000)
    check("the next staff client lifts it", has(c2.game, "UnBan:Torch:") and not has(c2.game, "UnBanSteamID:76561198000000321:"))
end

section("a timed ban's end gives back the role the game's unban takes away")
do
    local a, ca = boot()
    local u = player("Gemma", "gm")
    clientJoin(u)
    nolimit(a)
    say(a, "a_ban", { user = "Gemma", reason = "Spawned a car", len = "h1" })
    check("acks", okOf(a))
    check("the row keeps the role it had", md().bans[1] and md().bans[1].role == "gm")
    advance(20000)
    offline(a)   -- (nobody on to make the calls: they wait in the table)
    W.clock = W.clock + 3600 * 1000 + 5000
    advance(2000)
    local un, sr = owedOf("UnBan", "Gemma"), owedOf("SetRole", "Gemma")
    check("at its end: the unban, then the role back after it", un ~= nil and sr ~= nil and sr.reason == "gm" and sr.after == un.id)
    W.clients.Hermit = nil
    a = player("Hermit", "admin")
    ca = clientJoin(a)
    advance(4000)
    local iu, ir = nil, nil
    for i, s in ipairs(ca.game) do
        if s == "UnBan:Gemma:" then iu = i end
        if s == "SetRole:Gemma:gm" then ir = i end
    end
    check("the staff client makes both, the unban first", iu ~= nil and ir ~= nil and iu < ir, tostring(iu) .. " " .. tostring(ir))
    -- a plain user gets no role call
    local v = player("Plain", "user")
    clientJoin(v)
    nolimit(a)
    say(a, "a_ban", { user = "Plain", reason = "x", len = "h1" })
    advance(20000)
    W.clock = W.clock + 3600 * 1000 + 5000
    advance(2000)
    check("a user's unban owes no role", owedOf("SetRole", "Plain") == nil and not has(ca.game, "SetRole:Plain:"))
    -- a role changed while banned: the row takes it, so the lift gives back the new one, not a stale one
    local w = player("Wren", "gm")
    clientJoin(w)
    nolimit(a)
    say(a, "a_ban", { user = "Wren", reason = "x", len = "h1" })
    local wb = nil
    for _, b in pairs(md().bans) do if b.user == "Wren" then wb = b end end
    check("the row keeps the role it had", wb ~= nil and wb.role == "gm")
    nolimit(a)
    say(a, "a_role", { user = "Wren", role = "moderator" })
    check("a role change on a banned name acks", okOf(a))
    check("and its row takes the new role", wb ~= nil and wb.role == "moderator")
    -- a staff role change is never an owed call, so never the host helper's
    check("a staff role change owes no game call", owedOf("SetRole", "Wren") == nil)
end

section("a client can't steer a Steam ID ban onto a neighbor's account")
do
    local a, ca = boot()
    local u = player("Steer", "user")
    u.steamNum = 76561198000000400
    -- a neighbor's ID that shares the server's double: the claim the server's own number can't tell from the true one
    local real = string.format("%.0f", u.steamNum)
    local claim = nil
    for n = 385, 415 do
        local s = "76561198000000" .. tostring(n)
        if s ~= real and tonumber(s) == u.steamNum then claim = s; break end
    end
    check("a neighbor's ID with the same double exists", claim ~= nil)
    local cu = clientJoin(u)
    cu.sid = claim
    nolimit(u)
    say(u, "a_hi", { sid = claim })
    check("the server kept the claim as the row's match", md().players.Steer.sid == claim)
    nolimit(a)
    say(a, "a_ban", { user = "Steer", reason = "x", len = "perm" })
    advance(20000)
    check("no Steam ID call at all: the neighbor is never banned", owedOf("BanSteamID") == nil and not has(ca.game, "BanSteamID:" .. tostring(claim) .. ":x"), ca.game)
    check("the name is", has(ca.slash, '/banuser "Steer" -r "x"'))
    nolimit(a)
    say(a, "a_gameban", { id = 1 })
    nolimit(a)
    say(a, "a_unban", { id = 1 })
    advance(3000)
    check("and lifting it names no Steam ID either", not has(ca.game, "UnBanSteamID:" .. tostring(claim) .. ":"), ca.game)
end

section("a stay owes a Kick, every stay")
do
    local a, ca = boot()
    W.refuse = { Torch = true }
    local u = player("Torch", "user")
    local cu = clientJoin(u)
    cu.env.forceDisconnect = function() end
    say(a, "a_ban", { user = "Torch", reason = "Griefing", len = "perm" })
    advance(36000)
    check("the first stay owes a Kick", has(ca.slash, '/kickuser "Torch" -r "Griefing"'))
    -- the kick lands this time; they come back on the same name the game would not ban
    W.kickRemoves = true
    ca.slash = {}
    advance(16000)
    local kicked = 0
    for _, s in ipairs(ca.slash) do if string.find(s, '/kickuser "Torch"', 1, true) then kicked = kicked + 1 end end
    check("a kick that did not take is asked again", logHas("kick did not take") and kicked >= 1)
    check("gone", cu.up == false)
    ca.slash = {}
    W.online[#W.online + 1] = u
    W.clients.Torch.up = false
    advance(30000)
    check("back: told again, and the next stay owes another Kick", has(ca.slash, '/kickuser "Torch" -r "Griefing"'))
    check("a Kick took them, not the game's ban: their login lifts nothing", md().bans[1] ~= nil and not logHas("ban lifted in the game"))
    W.refuse, W.kickRemoves = nil, nil
end

section("a kick that never takes is asked for REOWE_MAX times")
do
    local a, ca = boot()
    W.refuse = { Torch = true }
    local u = player("Torch", "user")
    local cu = clientJoin(u)
    cu.env.forceDisconnect = function() end
    say(a, "a_ban", { user = "Torch", reason = "Griefing", len = "perm" })
    advance(400000)
    local kicked = 0
    for _, s in ipairs(ca.slash) do if string.find(s, '/kickuser "Torch"', 1, true) then kicked = kicked + 1 end end
    check("asked again, a few times", kicked >= 2, kicked)
    check("then a line, not a loop", logHas("kick did not take | @server | Torch | - | asked 3 times"))
    W.refuse = nil
end

section("every ZeD command is refused for a banned player")
do
    local a, ca = boot()
    W.refuse = { Torch = true }
    local u = player("Torch", "user")
    local cu = clientJoin(u)
    cu.env.forceDisconnect = function() end
    local Srv = W.server.ZeD.Srv
    -- a stand-in for each part this sim does not load, on the same register and the same one listener
    local ran = {}
    for _, mod in ipairs({ "ZeDC", "ZeDX", "ZeDL", "ZeDDash" }) do
        Srv.modules[mod] = true
        Srv.register(mod, "probe", {}, function(p) ran[mod] = (ran[mod] or 0) + 1 end)
    end
    local function fire(mod, cmd, args)
        u.box = {}
        nolimit(u)
        net(function() W.server.Events.OnClientCommand.fire(mod, cmd, u, wire(args or {})) end)
        drain()
    end
    for _, mod in ipairs({ "ZeDC", "ZeDX", "ZeDL", "ZeDDash" }) do
        fire(mod, "probe")
        check("before the ban: " .. mod .. " runs", ran[mod] == 1)
    end
    say(a, "a_ban", { user = "Torch", reason = "Griefing", len = "perm" })
    advance(14000)
    for _, mod in ipairs({ "ZeDC", "ZeDX", "ZeDL", "ZeDDash" }) do
        fire(mod, "probe")
        check("banned: " .. mod .. " (claims, extras, log, dash) refused", ran[mod] == 1)
    end
    fire("ZeDT", "t_mine")
    check("banned: tickets refused", firstErr(u) == "perm" and got(u, "t_mine") == nil)
    fire("ZeDA", "a_players")
    check("banned: admin refused", firstErr(u) == "perm" and got(u, "a_players") == nil)
    fire("ZeD", "hello", { v = 1 })
    check("the hello still answers, so their client hears why", got(u, "hello") ~= nil)
    fire("ZeDA", "a_hi", {})
    check("and a_hi still tells them to leave", got(u, "a_leave") ~= nil)
    check("one line a minute says so", logHas("under a ban: probe") or logHas("under a ban:"))
    W.refuse = nil
end

section("a Steam ID ban matches the server's own number, not the client's word")
do
    local a, ca = boot()
    say(a, "a_ban", { target = "76561198000000600", reason = "alt", len = "w1" })
    -- a new account on that Steam ID; its client claims nothing at all
    local u = player("Fresh", "user")
    u.steamNum = 76561198000000600
    local cu = clientJoin(u)
    advance(6000)
    check("no claim: told to leave all the same", M(cu).leave ~= nil)
    nolimit(u)
    say(u, "a_players", {})
    check("and refused", firstErr(u) == "perm")
    -- a client that claims another ID
    local v = player("Liar", "user")
    v.steamNum = 76561198000000600
    local cv = clientJoin(v)
    nolimit(v)
    say(v, "a_hi", { sid = "76561198000999999" })
    advance(6000)
    check("a false claim changes nothing", M(cv).leave ~= nil)
    -- someone else's number is not theirs
    local w = player("Other", "user")
    w.steamNum = 76561198000500000
    local cw = clientJoin(w)
    advance(6000)
    check("another Steam ID is not touched", M(cw).leave == nil)
end

section("a_done is not trusted: the game's list is read back")
do
    W = W or {}
    W.sidListNext = {}
    local a, ca = boot()
    W.sidListNext = nil
    W.refuse = { ["76561198000000700"] = 1 }
    say(a, "a_ban", { target = "76561198000000700", reason = "alt", len = "perm" })
    advance(3000)
    check("the client said done", has(ca.game, "BanSteamID:76561198000000700:alt"))
    check("the game's list said no: asked again, with a line", md().bans[1].reowe == 1 and logHas("the Steam ID is not on the game's list"))
    check("the second one holds: no more", md().bans[1].made == true and W.sidList["76561198000000700"] == true)
    advance(30000)
    check("and nothing more is asked", md().bans[1].reowe == 1 and next(md().owed) == nil)
    -- a round asked again whose calls have not gone yet (made is cleared), then lifted: the first round's game ban may hold,
    -- so the unban is still owed
    local b1 = md().bans[1]
    check("a ban the game was told of remembers it", b1.everMade == true)
    b1.made = nil
    nolimit(a)
    say(a, "a_unban", { id = 1 })
    advance(3000)
    check("lifted with made cleared: the game's unban still goes", has(ca.game, "UnBanSteamID:76561198000000700"), ca.game)
    -- a game that never takes it: the cap, then a line
    W.refuse = { ["76561198000000701"] = true }
    nolimit(a)
    say(a, "a_ban", { target = "76561198000000701", reason = "alt", len = "perm" })
    advance(5000)
    check("never on the list: REOWE_MAX tries, then a line", md().bans[2].reowe == 3 and md().bans[2].gaveUp == true)
    W.refuse = nil
    -- a name: the only proof is that they are gone
    W.refuse = { Kade = 1 }
    local u = player("Kade", "user")
    local cu = clientJoin(u)
    cu.env.forceDisconnect = function() end
    nolimit(a)
    say(a, "a_ban", { user = "Kade", reason = "x", len = "perm" })
    advance(13000)
    check("done, and still on", md().bans[3].made == true and cu.up == true)
    advance(16000)
    check("still on past VERIFY_S: the game's ban did not take, asked again", md().bans[3].reowe == 1 and logHas("they are still on"))
    check("the second lands", cu.up == false and W.gameBans.Kade == true)
    W.refuse = nil
end

section("an unban by Steam ID is read back too")
local function calls(list, s)
    local n = 0
    for _, x in ipairs(list) do if x == s then n = n + 1 end end
    return n
end
do
    W = W or {}
    W.sidListNext = {}
    local a, ca = boot()
    W.sidListNext = nil
    say(a, "a_ban", { target = "76561198000000800", reason = "alt", len = "perm" })
    advance(3000)
    check("on the game's list", W.sidList["76561198000000800"] == true)
    W.refuse = { ["un:76561198000000800"] = 1 }
    nolimit(a)
    say(a, "a_unban", { id = 1 })
    advance(3000)
    check("the client said done but the list still held it: asked again, with a line", logHas("game unban did not take") and calls(ca.game, "UnBanSteamID:76561198000000800:") == 2, ca.game)
    check("the second one lifted it: nothing more", W.sidList["76561198000000800"] == nil and next(md().owed) == nil)
    -- a game that never lifts it: REOWE_MAX more, then a line
    W.refuse = { ["un:76561198000000801"] = true }
    W.sidList["76561198000000801"] = true
    nolimit(a)
    say(a, "a_unban", { sid = "76561198000000801" })
    advance(10000)
    check("never lifted: asked REOWE_MAX more times, then left", calls(ca.game, "UnBanSteamID:76561198000000801:") == 4 and next(md().owed) == nil, calls(ca.game, "UnBanSteamID:76561198000000801:"))
    check("and the last line says so", logHas("asked 3 times"))
    -- a row of ours banning that ID again: its unban is not asked for again
    W.refuse = { ["un:76561198000000802"] = true }
    W.sidList["76561198000000802"] = true
    nolimit(a)
    say(a, "a_unban", { sid = "76561198000000802" })
    md().bans[99] = { id = 99, sid = "76561198000000802", sidGame = "76561198000000802", reason = "again", by = "Hermit", byPos = 4, at = 1, day = 1, v = 2, made = true }
    advance(5000)
    check("banned again meanwhile: the unban is not asked again", calls(ca.game, "UnBanSteamID:76561198000000802:") == 1)
    W.refuse = nil
end

section("the game's unban wins, on the game's own word")
local function count(list, s)
    local n = 0
    for _, x in ipairs(list) do if x == s then n = n + 1 end end
    return n
end
local function back(u)
    W.online[#W.online + 1] = u
    W.clients[u.name] = nil
    return clientJoin(u)
end
-- a row, or an empty one once it is gone (so a run on older code goes on to its next check)
local function row(i) return md().bans[i] or {} end
local function lifts()
    local n = 0
    for _, l in ipairs(W.logs) do if string.find(l.line, "| ban lifted in the game |", 1, true) then n = n + 1 end end
    return n
end
local function unbanned(c, name)
    return has(c.game, "UnBan:" .. name .. ":") or has(c.game, "UnBanIP:" .. name .. ":")
end
do
    -- the review's case: a name ban made while they are on, which the game did NOT take, and their client's own leave screen
    -- disconnects them a moment after the ban goes out. Leaving is no proof: their next login must not close the row, and ZeD
    -- must not lift anything
    local a, ca = boot()
    W.userList = true
    W.refuse = { Kade = true }
    local u = player("Kade", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Kade", reason = "griefing", len = "perm" })
    advance(16000)
    check("the ban went out, the game did not take it, and their own client left", has(ca.slash, '/banuser "Kade" -r "griefing"') and W.gameBans.Kade == nil and W.clients.Kade.up == false)
    check("the game's list was looked at, and it does not say banned", (ca.looked or 0) >= 1 and not row(1).nameSeen)
    W.refuse = nil
    local c2 = back(u)
    c2.env.forceDisconnect = function() end
    advance(16000)
    check("their login closes nothing", md().bans[1] ~= nil and lifts() == 0)
    check("the ban is asked for again, as before", row(1).reowe == 1 and logHas("they are still on"))
    check("ZeD lifted nothing", not unbanned(ca, "Kade"))
    W.userList = nil
end
do
    -- the game held it (a staff client read the role "banned" on the game's user list), then staff lift it in the game's own
    -- window; the player logs in: the row closes on a second look before anything is asked again, and nothing gates them or is
    -- lifted by ZeD
    local a, ca = boot()
    W.userList = true
    local u = player("Kade", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Kade", reason = "griefing", len = "perm" })
    advance(13000)
    check("the game's ban made, and it kicked them", W.gameBans.Kade == true and row(1).made == true)
    advance(4000)
    check("a look at the game's list: the role is banned, so it held", row(1).nameSeen ~= nil)
    advance(20000)
    W.gameBans.Kade = nil                    -- (staff lift it in the game)
    local c2 = back(u)
    advance(1000)
    check("while the look runs: no leave screen and no ban again", M(c2).leave == nil and count(ca.slash, '/banuser "Kade" -r "griefing"') == 1)
    advance(5000)
    check("the row is closed", next(md().bans) == nil)
    check("the log says it was lifted in the game, and how ZeD knew", logHas("ban lifted in the game") and logHas("lifted in the game: the game's user list no longer has the name banned"))
    check("and names the staff client whose look showed it", logHas("no longer has the name banned; seen by Hermit"))
    check("on the line's own field too", (function() for i = 1, md().log.n do local l = md().log[i]; if l and l.what == "ban lifted in the game" then return l.via == "Hermit" end end return false end)())
    check("never banned again", count(ca.slash, '/banuser "Kade" -r "griefing"') == 1 and not logHas("game ban did not take"))
    check("nor told to leave", M(c2).leave == nil and c2.up == true)
    check("nothing owed for them, nothing lifted by ZeD", next(md().owed) == nil and not unbanned(ca, "Kade"))
    check("the gate opens", W.server.ZeD.Srv.gated(u, "ZeDT", "t_mine") == nil)
    -- one lifted in the game while they are off: the row closes at its next look
    nolimit(a)
    md().players.Ola = { t = 1, role = "user" }
    say(a, "a_ban", { user = "Ola", reason = "x", len = "w1" })
    advance(8000)
    check("made while they were off, and the game's list says banned", W.gameBans.Ola == true and row(2).nameSeen ~= nil)
    W.gameBans.Ola = nil
    advance(65000)
    check("a timed row lifted in the game while they are off: closed at its next look", md().bans[2] == nil and lifts() == 2, tostring(md().bans[2] ~= nil) .. " " .. lifts())
    check("and its unban is not owed at its end", owedOf("UnBan", "Ola") == nil and not unbanned(ca, "Ola"))
    W.userList = nil
end
do
    -- no staff client to look: a name row stays as it was, and a login is asked again as before
    local a, ca = boot()
    W.userList = true
    local u = player("Torch", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Torch", reason = "x", len = "perm" })
    advance(20000)
    check("held", row(1).nameSeen ~= nil)
    W.gameBans.Torch = nil
    offline(a)
    local c2 = back(u)
    c2.env.forceDisconnect = function() end
    advance(16000)
    check("nobody to look: the row stands and is asked again", md().bans[1] ~= nil and row(1).reowe == 1 and lifts() == 0)
    check("and the leave screen shows", M(c2).leave ~= nil)
    W.userList = nil
end
do
    -- the game's database read failed: the list holds only the players on, with their live role and not from the database.
    -- That is no word on the ban: nothing closes
    local a, ca = boot()
    W.userList = true
    local u = player("Bix", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Bix", reason = "x", len = "perm" })
    advance(40000)
    check("held", row(1).nameSeen ~= nil)
    W.dbDown = true
    W.refuse = { Bix = true }
    local c2 = back(u)
    c2.env.forceDisconnect = function() end
    advance(30000)
    check("a row not from the game's database proves nothing: the row stands", md().bans[1] ~= nil and lifts() == 0)
    check("after the look, as before: asked again", (row(1).reowe or 0) >= 1, tostring(row(1).reowe))
    W.dbDown, W.refuse = nil, nil
    -- an answer that is the list from before the question (a reply to an older request) and still says banned: held again
    W.userList = nil
end
do
    -- the answer itself: only the client asked, only in time, only names asked, a role from the game's database, and a lift
    -- only from a look asked LIFT_FRESH_S or more after the one that saw the ban
    local a, ca = boot()
    local m = player("Mods", "moderator")
    clientJoin(m)
    local now = math.floor(W.clock / 1000)
    md().bans[1] = { id = 1, user = "Kade", reason = "x", by = "Hermit", byPos = 4, at = now, day = 1, v = 2, made = true, everMade = true, nameSeen = now - 5 }
    local function ask(id, to) A().look = { id = id, to = to, at = math.floor(W.clock / 1000), names = { kade = 1 } } end
    ask(7, "Hermit")
    nolimit(a)
    say(a, "a_looked", { id = 7, rows = { { u = "Kade", role = "user", wl = true } } })
    check("a look too soon after the one that saw the ban proves nothing", md().bans[1] ~= nil)
    row(1).nameSeen = now - 30
    ask(8, "Hermit")
    nolimit(m)
    say(m, "a_looked", { id = 8, rows = { { u = "Kade", role = "user", wl = true } } })
    check("another staff client's word is not taken", md().bans[1] ~= nil and A().look ~= nil)
    nolimit(a)
    say(a, "a_looked", { id = 9, rows = { { u = "Kade", role = "user", wl = true } } })
    check("nor an answer to another look", md().bans[1] ~= nil)
    say(a, "a_looked", { id = 8, rows = { { u = "Kade", role = "user", wl = false } } })
    check("nor a row not from the game's database", md().bans[1] ~= nil)
    ask(10, "Hermit")
    nolimit(a)
    say(a, "a_looked", { id = 10, rows = { { u = "Other", role = "user", wl = true } } })
    check("nor a name not asked; a name missing says nothing", md().bans[1] ~= nil)
    ask(11, "Hermit")
    nolimit(a)
    say(a, "a_looked", { id = 11, rows = { { u = "kade", role = "user", wl = true }, { u = "Kade", role = "banned", wl = true } } })
    check("two rows for a name: banned wins", md().bans[1] ~= nil)
    ask(12, "Hermit")
    W.clock = W.clock + 11000
    nolimit(a)
    say(a, "a_looked", { id = 12, rows = { { u = "Kade", role = "user", wl = true } } })
    check("nor an answer past LOOK_WAIT_S", md().bans[1] ~= nil)
    ask(13, "Hermit")
    nolimit(a)
    say(a, "a_looked", { id = 13, rows = { { u = "Kade", role = "user", wl = true } } })
    check("the asked client, in time, a role from the database, fresh: the row closes", md().bans[1] == nil)
end
do
    -- a Steam ID: the game's own list says so, read twice, timed or not, and with the player off
    W = W or {}
    W.sidListNext = {}
    local a, ca = boot()
    W.sidListNext = nil
    say(a, "a_ban", { target = "76561198000000900", reason = "alt", len = "w1" })
    nolimit(a)
    say(a, "a_ban", { target = "76561198000000901", reason = "alt", len = "perm" })
    advance(3000)
    check("both on the game's list, read back", row(1).sidHeld == true and row(2).sidHeld == true)
    -- a database error answers null, as "not banned": one such read must never close a row or lift anything
    W.dbFail = 1
    advance(12000)
    check("one failed read of the game's list closes nothing", md().bans[1] ~= nil and md().bans[2] ~= nil and lifts() == 0)
    check("and lifts nothing", not has(ca.game, "UnBanSteamID:76561198000000900") and not has(ca.game, "UnBanSteamID:76561198000000901"))
    check("a read that finds it again starts over", row(1).sidOffAt == nil and row(2).sidOffAt == nil)
    W.sidList["76561198000000900"] = nil      -- (unbanid in the game)
    advance(25000)
    check("read off twice: the timed row closes", md().bans[1] == nil and md().bans[2] ~= nil)
    check("the log says it", logHas("lifted in the game: the Steam ID is off the game's list"))
    check("a Steam ID read off the game's list names nobody", not logHas("the Steam ID is off the game's list; seen by"))
    check("never banned again", count(ca.game, "BanSteamID:76561198000000900:alt") == 1)
    check("and no unban owed at its end", owedOf("UnBanSteamID", "76561198000000900") == nil)
    W.clock = W.clock + 604800 * 1000
    advance(3000)
    check("not at the end either", count(ca.game, "UnBanSteamID:76561198000000900:") == 0)
    -- a row whose ID the game never confirmed: the list's word is not taken as a lift
    W.refuse = { ["76561198000000902"] = true }
    nolimit(a)
    say(a, "a_ban", { target = "76561198000000902", reason = "alt", len = "perm" })
    advance(6000)
    check("never on the list: not lifted, asked again", md().bans[3] ~= nil and row(3).reowe == 3)
    W.refuse = nil
end
do
    -- an IP: the game's unban of another account on the same IP clears it from the game's list too (banIp deletes by the IP).
    -- Only the IP part goes; the row and the game's name ban stay, and ZeD lifts nothing
    W = W or {}
    W.sidListNext = {}
    local a, ca = boot()
    W.sidListNext = nil
    local u = player("Loot", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Loot", reason = "x", len = "perm", banIp = true })
    advance(20000)
    check("the IP on the game's list: held", row(1).ipHeld == true and W.gameBans.Loot == true)
    W.gameIps.Loot = nil                     -- (staff unban Loot's alt in the game; the IP they share comes off)
    advance(20000)
    check("the row stays", md().bans[1] ~= nil and lifts() == 0, tostring(md().bans[1] ~= nil) .. " " .. lifts() .. " " .. tostring(W.logs[#W.logs] and W.logs[#W.logs].line))
    check("only its IP part goes, with a line", row(1).banIp == nil and logHas("ip ban lifted in the game") and logHas("the ban on the name stands"))
    check("ZeD lifts nothing: the game's name ban stands", not unbanned(ca, "Loot") and W.gameBans.Loot == true and owedOf("UnBan", "Loot") == nil)
    -- a single failed read of the IP is no proof either
    nolimit(a)
    local v = player("Vex", "user")
    clientJoin(v)
    say(a, "a_ban", { user = "Vex", reason = "x", len = "perm", banIp = true })
    advance(20000)
    check("held", row(2).ipHeld == true)
    W.dbFail = 1
    advance(12000)
    check("one failed read keeps the IP part", row(2).banIp == true)
end
do
    -- the name lifted in the game on a Steam server (its unban leaves the IP on the game's list): the row closes, the log says
    -- the game still holds the IP, and ZeD lifts nothing itself
    W = W or {}
    W.sidListNext = {}
    local a, ca = boot()
    W.sidListNext = nil
    W.userList = true
    local u = player("Rue", "user")
    clientJoin(u)
    say(a, "a_ban", { user = "Rue", reason = "x", len = "perm", banIp = true })
    advance(20000)
    check("held: the name by a look, the IP by the list", row(1).nameSeen ~= nil and row(1).ipHeld == true, tostring(row(1).nameSeen) .. " " .. tostring(row(1).ipHeld) .. " " .. tostring(row(1).banIp) .. " " .. tostring(ca.looked))
    W.gameBans.Rue = nil
    advance(65000)
    check("closed at its next look", md().bans[1] == nil)
    check("the line names what the game still holds", logHas("the game still holds its IP"))
    check("and ZeD never lifts it itself", not has(ca.game, "UnBanIP:Rue:") and not has(ca.game, "UnBan:Rue:") and W.gameIps.Rue == true)
    W.userList = nil
end

section("owed voice bans give way to a ban, as Kicks do")
do
    local a, ca = boot()
    local now = math.floor(W.clock / 1000)
    for i = 1, 150 do md().owed[1000 + i] = { id = 1000 + i, act = "UnBan", target = "t" .. i, reason = "", at = now + 99999 } end
    for i = 1, 50 do md().owed[2000 + i] = { id = 2000 + i, act = "VoiceBan", target = "v" .. i, reason = "", at = now + 99999 } end
    nolimit(a)
    say(a, "a_unban", { user = "Someone" })
    check("full of voice bans: an unban is taken", okOf(a) and owedOf("UnBan", "Someone") ~= nil)
    check("the oldest voice ban made room", md().owed[2001] == nil and md().owed[2002] ~= nil and md().owed[1001] ~= nil)
    check("the log says a VoiceBan was dropped", logHas("dropped a VoiceBan"))
    for i = 1, 150 do md().owed[1000 + i] = nil end
    for i = 1, 200 do md().owed[3000 + i] = { id = 3000 + i, act = "UnBan", target = "u" .. i, reason = "", at = now + 99999 } end
    for id, e in pairs(md().owed) do if e.act == "VoiceBan" then md().owed[id] = nil end end
    nolimit(a)
    say(a, "a_unban", { user = "Other" })
    check("full of real calls, no voice ban to drop: still refused", errOf(a) == "full" and md().owed[3001] ~= nil)
end

section("a mute owes the game's voice ban when they come on")
do
    local a, ca = boot()
    md().players.Away = { t = 1, role = "user" }
    say(a, "a_mute", { user = "Away", on = true })
    check("muted while off: acked", okOf(a))
    advance(6000)
    check("nothing owed while they are off", owedOf("VoiceBan") == nil)
    local u = player("Away", "user")
    local cu = clientJoin(u)
    advance(6000)
    check("on: the next staff client makes the game's voice ban", count(ca.slash, '/voiceban "Away" -true') == 1, table.concat(ca.slash, "; "))
    check("done, nothing left owed", owedOf("VoiceBan") == nil)
    advance(20000)
    check("once a session", count(ca.slash, '/voiceban "Away" -true') == 1)
    offline(u)
    advance(6000)
    back(u)
    advance(6000)
    check("each session: the game holds it for the connection only", count(ca.slash, '/voiceban "Away" -true') == 2)
    -- unmuted before they come on: dropped
    nolimit(a)
    md().players.Bo = { t = 1, role = "user" }
    say(a, "a_mute", { user = "Bo", on = true })
    nolimit(a)
    say(a, "a_mute", { user = "Bo", on = false })
    local b = player("Bo", "user")
    clientJoin(b)
    advance(6000)
    check("unmuted first: no voice ban", not has(ca.slash, '/voiceban "Bo"'))
    -- owed with no staff on, then unmuted before it was made: dropped
    nolimit(a)
    md().players.Cy = { t = 1, role = "user" }
    say(a, "a_mute", { user = "Cy", on = true })
    offline(a)
    local cyp = player("Cy", "user")
    clientJoin(cyp)
    advance(6000)
    check("on with no staff to make it: it waits", owedOf("VoiceBan", "Cy") ~= nil)
    nolimit(a)
    say(a, "a_mute", { user = "Cy", on = false })
    check("unmuted: dropped", owedOf("VoiceBan", "Cy") == nil)
    local back2 = player("Hermit", "admin")
    W.clients.Hermit = nil
    local c2 = clientJoin(back2)
    advance(6000)
    check("and never made", not has(c2.slash, '/voiceban "Cy"'))
    -- muted while on: the staff client's own call, never a second owed one
    local t = player("Torch", "user")
    clientJoin(t)
    advance(6000)
    M(c2).mute("Torch", true)
    advance(12000)
    check("muted while on: one voice ban, the staff client's own", count(c2.slash, '/voiceban "Torch" -true') == 1, table.concat(c2.slash, "; "))
    -- the host helper may make it: on its allow-list, with a name checked as the helper checks it
    local H = W.server.ZeD.Srv.H
    check("the helper takes a voice ban", H.can({ act = "VoiceBan", target = "Away" }) == true)
    check("never a name the console could read as -true or -false", H.can({ act = "VoiceBan", target = "-true" }) == false and H.can({ act = "VoiceBan", target = "-x" }) == false)
    check("nor an unmute", H.can({ act = "VoiceUnban", target = "Away" }) == false)
end
do
    -- with the helper running and no staff on, the helper makes it
    W = W or {}
    W.sandboxNext = { HostHelper = true }
    local a, ca = boot()
    W.sandboxNext = nil
    md().players.Away = { t = 1, role = "user" }
    say(a, "a_mute", { user = "Away", on = true })
    offline(a)
    W.files["ZeD_helper/answers.txt"] = "ZEDA 1 " .. W.server.ZeD.Srv.H.epoch() .. " " .. tostring(math.floor(W.clock / 1000)) .. "\n"
    advance(3000)
    local u = player("Away", "user")
    clientJoin(u)
    advance(8000)
    local q = W.files["ZeD_helper/queue.txt"] or ""
    check("in the helper's queue", string.find(q, "\tVoiceBan\tAway\t", 1, true) ~= nil, q)
    local e = owedOf("VoiceBan", "Away")
    W.files["ZeD_helper/answers.txt"] = "ZEDA 1 " .. W.server.ZeD.Srv.H.epoch() .. " " .. tostring(math.floor(W.clock / 1000)) .. "\n" .. tostring(e and e.id) .. "\t1\tok\tUser Away voice is banned.\n"
    advance(3000)
    check("answered ok: done", owedOf("VoiceBan", "Away") == nil)
end

section("bans from before this build hold too")
do
    W = W or {}
    W.sidListNext = {}
    local a, ca = boot()
    W.sidListNext = nil
    offline(a)
    local now = math.floor(W.clock / 1000)
    local B = md().bans
    B[7] = { id = 7, user = "Old", reason = "grief", by = "Hermit", byPos = 4, at = now - 100, day = 1, untilT = now + 3600, sid = "76561198000000900" }
    B[8] = { id = 8, sid = "76561198000000901", reason = "alt", by = "Hermit", byPos = 4, at = now, day = 1, untilT = now + 3600 }
    B[9] = { id = 9, user = "Perm", sid = "76561198000000902", reason = "x", by = "Hermit", byPos = 4, at = now, day = 1, made = true }
    B[10] = { id = 10, user = "Gone", reason = "x", by = "Hermit", byPos = 4, at = now - 7200, day = 1, untilT = now - 10 }
    B[11] = { id = 11, user = "Ip", ip = nil, banIp = true, reason = "x", by = "Hermit", byPos = 4, at = now, day = 1, untilT = now + 600 }
    md().owed[50] = { id = 50, act = "BanSteamID", target = "76561198000000902", reason = "x", at = 0, banId = 9 }
    md().nextBan, md().nextOwe = 12, 51
    serverStart()                    -- (a restart: this build meets beta 7's rows)
    W.server.ZeD.Srv.adminTick()
    check("a beta 7 timed ban owes the game's ban by name", owedOf("Ban", "Old") ~= nil and md().bans[7].gameBan == true)
    check("never by the Steam ID its player's client named", owedOf("BanSteamID", "76561198000000900") == nil and md().bans[7].sidGame == nil)
    check("a typed Steam ID's timed ban owes the game's Steam ID ban", owedOf("BanSteamID", "76561198000000901") ~= nil and md().bans[8].sidGame == "76561198000000901")
    check("a timed IP ban owes the plain ban, never the IP (that needs them on)", owedOf("Ban", "Ip") ~= nil and owedOf("BanIP") == nil)
    check("a call for a client's Steam ID still waiting goes", md().owed[50] == nil)
    check("a permanent row the game held keeps its Steam ID, to be lifted with it", md().bans[9].sidLift == "76561198000000902" and md().bans[9].sidGame == nil)
    check("a line says each was owed", logHas("game ban owed"))
    check("a row already over is only lifted", md().bans[10] == nil and owedOf("Ban", "Gone") == nil)
    local n = 0
    for _ in pairs(md().owed) do n = n + 1 end
    serverStart()                    -- (another start before anyone made them: nothing owed twice)
    W.server.ZeD.Srv.adminTick()
    local n2 = 0
    for _ in pairs(md().owed) do n2 = n2 + 1 end
    check("a second start owes nothing again", n2 == n, n .. " then " .. n2)
    -- the next staff client makes them
    local back = player("Hermit", "admin")
    W.clients.Hermit = nil
    local c2 = clientJoin(back)
    advance(3000)
    check("made by the next staff client", has(c2.slash, '/banuser "Old" -r "grief"') and has(c2.game, "BanSteamID:76561198000000901:alt"))
    nolimit(back)
    say(back, "a_unban", { id = 9 })
    advance(3000)
    check("the old permanent row lifts what beta 7 gave the game", has(c2.game, "UnBanSteamID:76561198000000902:"))
    -- a frozen table is never touched
    world()
    md().bans[1] = { id = 1, user = "Cold", reason = "x", by = "Hermit", byPos = 4, at = 1, day = 1, untilT = math.floor(W.clock / 1000) + 600, sid = "76561198000000903" }
    md().schema = 99
    serverStart()
    W.server.ZeD.Srv.adminTick()
    check("frozen: no row changed, nothing owed", md().bans[1].v == nil and md().bans[1].gameBan == nil and next(md().owed) == nil)
end

section("the host helper: the queue it reads and the answers it writes")
local function failLines()
    local n = 0
    for _, l in ipairs(W.logs) do
        if string.find(l.line, "host helper failed", 1, true) then n = n + 1 end
    end
    return n
end
do
    W = W or {}
    W.sandboxNext = { HostHelper = true }
    local a, ca = boot()
    W.sandboxNext = nil
    local Srv = W.server.ZeD.Srv
    local H = Srv.H
    check("the setting turns it on", H.on() == true)
    local epoch = H.epoch()
    check("this start has its own word for the helper", type(epoch) == "string" and #epoch > 8)
    check("and it is never saved, so a table a crash rolled back never meets its old answers", md().helperEpoch == nil)
    -- a running helper rewrites its answers file every pass: ans sets what it answers, adv keeps its time fresh
    local function ans(body)
        W.helperBody = body
        W.files["ZeD_helper/answers.txt"] = "ZEDA 1 " .. epoch .. " " .. tostring(math.floor(W.clock / 1000)) .. "\n" .. body
    end
    local function adv(ms)
        while ms > 0 do
            local d = math.min(ms, 2000)
            if W.helperBody then ans(W.helperBody) end
            advance(d)
            ms = ms - d
        end
    end
    -- not known to be running (no answer from it this start): a call goes straight to a staff client, never to the queue
    md().players.Early = { t = 1, role = "user" }
    nolimit(a)
    say(a, "a_ban", { user = "Early", reason = "x", len = "perm" })
    advance(3000)
    check("before the helper's first answer: a staff client makes the call", has(ca.slash, '/banuser "Early" -r "x"'))
    check("and the queue holds nothing", not string.find(W.files["ZeD_helper/queue.txt"] or "", "Early", 1, true), W.files["ZeD_helper/queue.txt"])
    ans("")                          -- (its first pass: the empty queue answered)
    adv(3000)
    check("once it has answered it counts as running", H.alive(math.floor(W.clock / 1000)) == true)
    offline(a)
    md().players.Kade = { t = 1, role = "user" }
    -- a permanent ban with nobody on: the calls go to the queue
    W.server.ZeD.Srv.mem.Hermit = nil
    a.box = {}
    W.online[#W.online + 1] = a
    say(a, "a_ban", { user = "Kade", reason = "Grief and lies", len = "perm" })
    offline(a)
    for _, ow in pairs(md().owed) do ow.reason = "Grief\tand\nlies" end      -- (as if a reason had kept them: the queue's own guard)
    adv(3000)
    local q = W.files["ZeD_helper/queue.txt"] or ""
    check("the queue names this world", string.find(q, "ZEDQ 1 " .. epoch, 1, true) == 1, q)
    check("the call is in it, its reason on one line", string.find(q, "\tBan\tKade\tGrief and lies\n", 1, true) ~= nil, q)
    check("the queue ends with its end line, so a file read mid-write is never taken", string.sub(q, -9) == "ZEDQ end\n", q)
    -- the helper answers ok: done, and judged as any other
    local e = owedOf("Ban", "Kade")
    ans(tostring(e.id) .. "\t1\tok\tSystem banned user Kade\n")
    adv(3000)
    check("ok: the call is done", owedOf("Ban", "Kade") == nil and (function() for _, b in pairs(md().bans) do if b.user == "Kade" then return b.made == true end end end)())
    check("and the queue no longer holds it", not string.find(W.files["ZeD_helper/queue.txt"], "\tBan\tKade", 1, true))
    -- an answer from another world's file is not read
    md().players.Mags = { t = 1, role = "user" }
    W.online[#W.online + 1] = a
    nolimit(a)
    say(a, "a_ban", { user = "Mags", reason = "x", len = "perm" })
    offline(a)
    adv(3000)
    e = owedOf("Ban", "Mags")
    W.files["ZeD_helper/answers.txt"] = "ZEDA 1 not-this-world " .. tostring(math.floor(W.clock / 1000)) .. "\n" .. tostring(e.id) .. "\t1\tok\tx\n"
    adv(3000)
    check("another world's answer changes nothing", owedOf("Ban", "Mags") ~= nil)
    -- refused: it goes to a staff client instead
    ans(tostring(e.id) .. "\t1\trefused\tThis user can't be banned.\n")
    adv(3000)
    check("refused: off the queue, and written down", not string.find(W.files["ZeD_helper/queue.txt"], "\tMags\t", 1, true) and logHas("host helper refused"))
    local back = player("Hermit", "admin")
    W.clients.Hermit = nil
    local c2 = clientJoin(back)
    adv(2000)
    check("then a staff client makes it", has(c2.slash, '/banuser "Mags" -r "x"'))
    -- what the helper never gets: an IP call, a name its patterns refuse
    nolimit(back)
    local ip = player("Loot", "user")
    clientJoin(ip)
    say(back, "a_ban", { user = "Loot", reason = "x", len = "perm", banIp = true })
    md().players["N\195\164me"] = { t = 1, role = "user" }
    nolimit(back)
    say(back, "a_ban", { user = "N\195\164me", reason = "x", len = "perm" })
    adv(1000)
    q = W.files["ZeD_helper/queue.txt"]
    check("an IP call is never the helper's", not string.find(q, "BanIP", 1, true))
    check("a name outside its patterns is never the helper's", not string.find(q, "N\195\164me", 1, true))
    check("both go to the staff client", has(c2.slash, '/banuser "N\195\164me" -r "x"'))
    -- failed: a staff client gets it at once, and the helper a new try
    offline(back)
    md().players.Bo = { t = 1, role = "user" }
    W.online[#W.online + 1] = back
    nolimit(back)
    say(back, "a_ban", { user = "Bo", reason = "x", len = "perm" })
    offline(back)
    adv(3000)
    e = owedOf("Ban", "Bo")
    ans(tostring(e.id) .. "\t1\tfailed\tno answer from the console\n")
    adv(3000)
    check("failed: written down", logHas("host helper failed") and failLines() == 1)
    adv(16000)
    check("no new try before HELPER_WAIT_S: a console it cannot reach is not asked every pass", string.find(W.files["ZeD_helper/queue.txt"], tostring(e.id) .. "\t1\tBan\tBo", 1, true) ~= nil, W.files["ZeD_helper/queue.txt"])
    adv(16000)
    check("then tried again under a new try", string.find(W.files["ZeD_helper/queue.txt"], tostring(e.id) .. "\t2\tBan\tBo", 1, true) ~= nil, W.files["ZeD_helper/queue.txt"])
    -- it fails again: no second line inside HELPER_LOG_S, only a count
    ans(tostring(e.id) .. "\t2\tfailed\tno answer from the console\n")
    adv(3000)
    check("a second failure inside a minute: no new line", failLines() == 1)
    adv(31000)
    check("a third try", string.find(W.files["ZeD_helper/queue.txt"], tostring(e.id) .. "\t3\tBan\tBo", 1, true) ~= nil, W.files["ZeD_helper/queue.txt"])
    ans(tostring(e.id) .. "\t3\tfailed\tno answer from the console\n")
    adv(3000)
    check("HELPER_TRIES failures: left to staff clients, off the queue", owedOf("Ban", "Bo").noHelper == true and not string.find(W.files["ZeD_helper/queue.txt"], "\tBo\t", 1, true))
    check("and one line says so, with the count it held back", failLines() == 2 and logHas("tried 3 times, staff only now") and logHas("(and 1 more since the last line)"))
    adv(60000)
    check("then nothing more: no tries, no lines", failLines() == 2 and owedOf("Ban", "Bo").try == 3)
    -- many calls failing at once: one line, not one a call
    local many = {}
    for _, n in ipairs({ "Fi", "Gus", "Hal", "Ivy" }) do
        md().players[n] = { t = 1, role = "user" }
        W.online[#W.online + 1] = back
        nolimit(back)
        say(back, "a_ban", { user = n, reason = "x", len = "perm" })
        offline(back)
    end
    adv(3000)
    local text = "ZEDA 1 " .. epoch .. " " .. tostring(math.floor(W.clock / 1000)) .. "\n"
    for _, n in ipairs({ "Fi", "Gus", "Hal", "Ivy" }) do
        many[#many + 1] = owedOf("Ban", n)
        text = text .. tostring(many[#many].id) .. "\t1\tfailed\tno answer from the console\n"
    end
    ans((string.gsub(text, "^[^\n]*\n", "")))
    adv(3000)
    check("four failures in one pass: one line, the other three held for the next line", failLines() == 3 and A().helperFails == 3)
    W.files["ZeD_helper/answers.txt"], W.helperBody = nil, nil
    -- a helper that stopped writing: staff are not kept waiting
    md().players.Cy = { t = 1, role = "user" }
    W.online[#W.online + 1] = back
    W.clients.Hermit.up = true
    nolimit(back)
    say(back, "a_ban", { user = "Cy", reason = "x", len = "perm" })
    W.clock = W.clock + 60000
    adv(20000)
    check("an answers file gone stale: the staff client gets it", has(W.clients.Hermit.slash, '/banuser "Cy" -r "x"'))
    -- a timed ban's end with nobody on, the helper running: the unban goes to it
    offline(back)
    nolimit(back)
    md().players.Dee = { t = 1, role = "user" }
    W.online[#W.online + 1] = back
    say(back, "a_ban", { user = "Dee", reason = "x", len = "h1" })
    offline(back)
    adv(1000)
    e = owedOf("Ban", "Dee")
    ans(tostring(e.id) .. "\t1\tok\tSystem banned user Dee\n")
    adv(3000)
    W.clock = W.clock + 3600 * 1000
    adv(3000)
    check("the end of a timed ban: the unban is in the queue", string.find(W.files["ZeD_helper/queue.txt"], "\tUnBan\tDee", 1, true) ~= nil)
    e = owedOf("UnBan", "Dee")
    ans(tostring(e.id) .. "\t1\tok\tSystem unbanned user Dee\n")
    adv(3000)
    check("made by the helper with nobody on", owedOf("UnBan", "Dee") == nil)
    -- a timed ban's end gives back the role: the restore is the helper's too, marked so by the server, after its unban
    nolimit(back)
    md().players.Mo = { t = 1, role = "moderator" }
    W.online[#W.online + 1] = back
    say(back, "a_ban", { user = "Mo", reason = "x", len = "h1" })
    offline(back)
    adv(1000)
    e = owedOf("Ban", "Mo")
    ans(tostring(e.id) .. "\t1\tok\tSystem banned user Mo\n")
    adv(3000)
    W.clock = W.clock + 3600 * 1000
    adv(3000)
    local sr = owedOf("SetRole", "Mo")
    check("a lapsed ban owes the role back, marked a restore", sr ~= nil and sr.restore == true and sr.reason == "moderator")
    check("and that restore is the helper's to make", sr ~= nil and H.can(sr) == true)
    check("not before its unban", not string.find(W.files["ZeD_helper/queue.txt"], "\tSetRole\t", 1, true), W.files["ZeD_helper/queue.txt"])
    e = owedOf("UnBan", "Mo")
    ans(tostring(e.id) .. "\t1\tok\tSystem unbanned user Mo\n")
    adv(3000)
    adv(3000)                        -- (handed to the helper on one pass, written at its next poll)
    check("then in the queue, the role and the mark last", string.find(W.files["ZeD_helper/queue.txt"], "\t1\tSetRole\tMo\tmoderator\trestore\n", 1, true) ~= nil, W.files["ZeD_helper/queue.txt"])
    ans(tostring(sr.id) .. "\t1\tok\tUser Mo is now moderator\n")
    adv(3000)
    check("the role given back by the helper with nobody on", owedOf("SetRole", "Mo") == nil)
    -- a SetRole without the server's mark is never the helper's: not a staff role change, not one a client could shape
    check("an unmarked SetRole is not the helper's", H.can({ act = "SetRole", target = "Mo", reason = "moderator" }) == false)
    check("nor a mark that is not true", H.can({ act = "SetRole", target = "Mo", reason = "moderator", restore = "true" }) == false)
    check("nor a role the console cannot read as one word", H.can({ act = "SetRole", target = "Mo", reason = "mod erator", restore = true }) == false
        and H.can({ act = "SetRole", target = "Mo", reason = "", restore = true }) == false
        and H.can({ act = "SetRole", target = "Mo", reason = string.rep("r", 33), restore = true }) == false)
    -- (the queue file is written only from owed rows, and a mark only from the restore: a hand-made row is still judged)
    md().owed[md().nextOwe] = { id = md().nextOwe, act = "SetRole", target = "Mo", reason = "admin", at = 0, helper = true }
    md().nextOwe = md().nextOwe + 1
    adv(3000)
    check("an unmarked SetRole never reaches the queue", not string.find(W.files["ZeD_helper/queue.txt"], "\tSetRole\tMo\tadmin", 1, true), W.files["ZeD_helper/queue.txt"])
    for id, ow in pairs(md().owed) do if ow.act == "SetRole" then md().owed[id] = nil end end
    -- off: no file at all
    world()
    local z = player("Hermit", "admin")
    clientJoin(z)
    md().players.Kade = { t = 1, role = "user" }
    say(z, "a_ban", { user = "Kade", reason = "x", len = "perm" })
    adv(3000)
    check("off: no queue written", W.files["ZeD_helper/queue.txt"] == nil)
end

section("130: a changed role shows at once, on and off")
do
    local a, ca = boot()
    W.userList = true
    local m = M(ca)
    -- an offline moderator: the server's record and the game's list both say moderator
    local u = player("Wren", "moderator")
    clientJoin(u)
    advance(6000)
    offline(u)
    W.clock = W.clock + 6000
    nolimit(a); m.watch(); drain()
    pcall(ca.env.requestUsers); drain(); m.refreshRows()
    check("130: the row starts as moderator", m.row("Wren") and m.row("Wren").role == "moderator", m.row("Wren") and m.row("Wren").role)
    nolimit(a)
    local looked = ca.looked or 0
    m.setRole("Wren", "user", {}, function(r) ca.r = r end)
    drain()
    check("130: the change acks", ca.r and ca.r.ok == true)
    check("130: the server's saved record takes the new role", md().players.Wren.role == "user", md().players.Wren.role)
    check("130: the row shows it at once", m.row("Wren").role == "user", m.row("Wren").role)
    check("130: the game's call", has(ca.game, "SetRole:Wren:user"))
    check("130: the game was asked for its list again", (ca.looked or 0) > looked, ca.looked)
    -- the server's rows and card, asked again, say the same (they read the saved record of an account that is off)
    W.clock = W.clock + 6000
    nolimit(a); m.watch(); drain()
    check("130: the server's Players rows say user", m.srvRows.Wren and m.srvRows.Wren.role == "user", m.srvRows.Wren and m.srvRows.Wren.role)
    nolimit(a)
    say(a, "a_card", { user = "Wren" })
    local c = got(a, "a_card")
    check("130: the card says user", c and c.role == "user", c and c.role)
    m.refreshRows()
    check("130: the row still says user after a refresh", m.row("Wren").role == "user", m.row("Wren").role)
    -- the hold lets go once both lists agree, and in any case after two minutes
    W.clock = W.clock + 121000
    m.refreshRows()
    check("130: nothing held after two minutes", next(m.roleSet) == nil)
    check("130: and the row reads the server's", m.row("Wren").role == "user", m.row("Wren").role)
    -- an online moderator: the game's live role changes, the row follows
    local o = player("Ash", "moderator")
    local co = clientJoin(o)
    advance(6000)
    nolimit(a); m.watch(); drain()
    nolimit(a)
    m.setRole("Ash", "user", {}, function(r) ca.r = r end)
    drain()
    check("130 online: the change acks", ca.r and ca.r.ok == true)
    check("130 online: the game applied it", o.role == ROLES.user)
    check("130 online: the row shows it at once", m.row("Ash") and m.row("Ash").role == "user", m.row("Ash") and m.row("Ash").role)
    W.clock = W.clock + 6000
    nolimit(a); m.watch(); drain()
    m.refreshRows()
    check("130 online: and after the lists come back", m.row("Ash").role == "user", m.row("Ash").role)
    W.userList = nil
end

print("admin_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
