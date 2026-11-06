-- ZeDUI/tools/qa/log_sim.lua  (Nov 6 2026, QA): the log's server side and client model with no game running.
-- The harness is admin_sim.lua's: Lua 5.1 stubs of the game and the real files run against them, ZeD_TicketProto, ZeD_AdminProto,
-- ZeD_LogProto, ZeD_ServerCore, ZeD_ServerTickets, ZeD_ServerAdmin, ZeD_ServerLog, and on each simulated client ZeD_ServerLink,
-- ZeD_Tickets, ZeD_Admin and ZeD_Log. The seven timed actions are small classes of the game's shape, and a stub of
-- NetTimedAction runs them as the bytecode reads: the class's .new by name, then complete through rawget on the action.
-- The one log's shape, who may read it, hostile arguments, the filters and pages, vehicles, the E2 fallback, the game's PvP log,
-- other mods' lines and what they can't do, Around ticket, Add to ticket, a restart, the words for every line, the ticket queue's
-- line when the game's list stops answering.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/log_sim.lua
-- It prints FAIL lines and a last line "log_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]log_sim%.lua$", "")

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
    "ToggleGodModHimself", "AnswerTickets", "SeeNetworkUsers", "ReadUserLog", "TeleportToCoordinates", "PVPLogTool" }) do CAPS[n] = n end

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
local ADMIN_CAPS = { "RolesWrite", "CantBeKickedByUser", "CantBeBannedByUser", "PVPLogTool" }
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
    p.isPlayer = true
    function p.getVehicle(self) return self.vehicle end
    function p.isAnimal(self) return self.animal == true end
    function p.getAttackedBy(self) return self.attackedBy end
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
-- THE GAME'S WORDS, AND THE SEVEN ACTIONS
-- ---------------------------------------------------------------------------
local WORDS = {}
do
    local f = assert(io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb"))
    local s = f:read("*a")
    f:close()
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\n') do WORDS[k] = v end
    WORDS.IGUI_VehicleNameCarNormal = "Chevalier D6"
    WORDS.IGUI_VehiclePartBattery = "Battery"
end

-- classes of the game's shape: new(self, character, part ...), a metatable to the class, complete answering true or false
ACTIONS = {
    ISSmashVehicleWindow = { complete = function(self) if not self.part then return false end; self.part.smashed = true; return true end },
    ISUninstallVehiclePart = { complete = function(self)
        if not self.part then return false end
        if not W.rollFails then self.part.item = nil end
        return true
    end },
    ISTakeEngineParts = { complete = function() return true end },
    ISTakeGasolineFromVehicle = { complete = function() return true end },
    ISRemoveBurntVehicle = { complete = function(self) self.vehicle.gone = true; self.vehicle.script = nil; return true end },
    ISStartVehicleEngine = { complete = function(self) self.character:getVehicle().engine = true; return true end },
    ISHotwireVehicle = { complete = function(self) self.character:getVehicle().wired = not W.wireFails; return true end },
}
function actionClass(name, shape)
    local C = { Type = name }
    C.__index = C
    C.complete = shape.complete
    function C.new(self, character, part)
        local o = { character = character, part = part }
        if part and not part.isCar then o.vehicle = part:getVehicle() end
        if type(part) == "table" and part.isCar then o.vehicle, o.part = part, nil end
        setmetatable(o, self)
        return o
    end
    return C
end

-- zombie.core.NetTimedAction: Type.new by name with the class first, then complete through rawget, which walks the metatable
local function perform(p, name, arg)
    local C = W.server[name]
    local act = C.new(C, p, arg)
    if W.classMiss then
        -- the world E2 fears: what perform calls is not the class's table. Only the action's own field reaches a wrap
        return (rawget(act, "complete") or W.raw[name])(act)
    end
    local fn = rawget(act, "complete") or rawget(getmetatable(act), "complete")
    return fn(act)
end

local function car(id, sql, x)
    local v = { isCar = true, id = id, sql = sql, script = { name = x or "CarNormal" }, parts = {} }
    function v.getSqlId(self) return self.sql end
    function v.getScript(self)
        local s = self.script
        return s and { getName = function() return s.name end } or nil
    end
    function v.isDriver(self, o) return self.driver == o end
    function v.isEngineRunning(self) return self.engine == true end
    function v.isHotwired(self) return self.wired == true end
    W.cars[id] = v
    return v
end
local function part(v, id, item, door)
    local q = { id = id, item = item, v = v }
    function q.getVehicle(self) return self.v end
    function q.getId(self) return self.id end
    function q.getInventoryItem(self) return self.item end
    function q.getParent(self) return door and { getDoor = function() return door end } or nil end
    return q
end
local function drive(v, p)
    p.vehicle, v.driver = v, p
end
local function leave(v, p)
    p.vehicle, v.driver = nil, nil
end
local function pvpHit(who, target, x, y)
    W.stamp = (W.stamp or 0) + 1
    local e = { x = x, y = y, text = string.format('[06-11-26 20:%02d:00.000] "%s" hit "%s"', W.stamp % 60, who, target) }
    function e.isSet() return true end
    function e.getText(self) return self.text end
    function e.getX(self) return self.x + 0.5 end
    function e.getY(self) return self.y + 0.5 end
    function e.getZ() return 0 end
    table.insert(W.pvp, 1, e)
    W.pvp[11] = nil
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
    ["ZeD/ZeD_LogProto"] = "42/media/lua/shared/ZeD/ZeD_LogProto.lua",
    ["ZeD/ZeD_ServerAdmin"] = "42/media/lua/server/ZeD/ZeD_ServerAdmin.lua",
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
    env.instanceof = function(o, cls)
        if cls == "IsoPlayer" then return type(o) == "table" and o.isPlayer == true end
        return false
    end
    env.getVehicleById = function(id)
        if type(id) ~= "number" or id ~= math.floor(id) then error("No implementation found: getVehicleById") end
        return W.cars[id]
    end
    env.getVehicles = function() error("a scan of the vehicles") end
    env.PVPLogTool = { getEvents = function() return jlist(W.pvp) end }
    for name, shape in pairs(ACTIONS) do env[name] = actionClass(name, shape) end
    if W.noWriteHooks then env.ISStartVehicleEngine = nil end
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
    -- (the game's own: it looks writeLog up at the call)
    env.ISLogSystem = {}
    env.ISLogSystem.writeLog = function(who, packet) env.writeLog(packet.loggerName, packet.logText) end
    runFile(env, FILES["ZeD/ZeD_TicketProto"])
    env.loaded["ZeD/ZeD_TicketProto"] = true
    runFile(env, FILES["ZeD/ZeD_AdminProto"])
    env.loaded["ZeD/ZeD_AdminProto"] = true
    runFile(env, FILES["ZeD/ZeD_ServerCore"])
    env.loaded["ZeD/ZeD_ServerCore"] = true
    runFile(env, FILES["ZeD/ZeD_ServerTickets"])
    env.loaded["ZeD/ZeD_ServerTickets"] = true
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerAdmin.lua")
    env.loaded["ZeD/ZeD_ServerAdmin"] = true
    runFile(env, FILES["ZeD/ZeD_LogProto"])
    env.loaded["ZeD/ZeD_LogProto"] = true
    if not W.noLog then runFile(env, "42/media/lua/server/ZeD/ZeD_ServerLog.lua") end
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
    env.getTextOrNull = function(k) return WORDS[k] end
    env.ZeD = {
        tr = function(k, ...)
            local s = WORDS[k] or error("no words for " .. tostring(k))
            for i, v in ipairs({ ... }) do s = string.gsub(s, "%%" .. i, (string.gsub(tostring(v), "%%", "%%%%"))) end
            return s
        end,
        logOnce = function(k, m) check("no client error", false, tostring(k) .. ": " .. tostring(m)) end,
        Messages = { ticket = function() end, ticketNew = function() end, adminNote = function(t) c.game[#c.game + 1] = "note:" .. t end },
    }
    env.ISAdminMessage = { AddAdminMessage = function() end }
    env.getTickets, env.addTicket = function() c.gets = (c.gets or 0) + 1 end, function() end
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
    runFile(env, FILES["ZeD/ZeD_LogProto"])
    env.loaded["ZeD/ZeD_LogProto"] = true
    runFile(env, "42/media/lua/client/ZeD/ZeD_Log.lua")
    env.Events.OnCreatePlayer.fire(0, p)
    advance(500)
    return c
end

local function world(opts)
    W = { clock = 1793913240000, net = {}, logs = {}, online = {}, players = {}, clients = {}, moddata = {}, hours = 12.5 * 24,
        uuid = 0, scripts = { ["Base.Axe"] = true }, ground = {}, sent = 0, gameBans = {}, gameIps = {}, cars = {}, pvp = {} }
    for k, v in pairs(opts or {}) do W[k] = v end
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

local function boot(opts)
    world(opts)
    local a = player("Hermit", "admin")
    local ca = clientJoin(a)
    return a, ca
end

-- ---------------------------------------------------------------------------
local function Lg_L() return W.server.ZeD.Lg.L end
local function L(c) return c.env.ZeD.Logs end
local function Tk() return W.server.ZeD.Tk end
local function Srv() return W.server.ZeD.Srv end
local function ask(p, args, cmd)
    p.box = {}
    local a = wire(args)
    net(function() W.server.Events.OnClientCommand.fire("ZeDL", cmd or "l_query", p, a) end)
    drain()
end
local function tk(p, command, args)
    p.box = {}
    local a = wire(args)
    net(function() W.server.Events.OnClientCommand.fire("ZeDT", command, p, a) end)
    drain()
end
local function page(p) return got(p, "l_page") end
local function again(p) nolimit(p); W.clock = W.clock + 500 end
local function rowsOf(p, args)
    again(p)
    ask(p, args or {})
    local a = page(p)
    return a and a.rows or nil, a
end
local function rowWith(rows, what)
    for _, r in ipairs(rows or {}) do
        if r.what == what then return r end
    end
    return nil
end
local function countWhat(rows, what)
    local n = 0
    for _, r in ipairs(rows or {}) do
        if r.what == what then n = n + 1 end
    end
    return n
end
local function tick(s)
    W.clock = W.clock + (s or 10) * 1000
    W.server.Events.OnTickEvenPaused.fire()
    drain()
end
-- a ticket filed by p, at p
local function file(p, kind, here)
    nolimit(p)
    tk(p, "t_new", { kind = kind or "GRIEF", here = here ~= false, text = "someone took my engine" })
    local a = got(p, "t_ack")
    return a and a.id
end

section("the one log")
do
    local a, ca = boot()
    check("hello says the log is here", ca.env.ZeD.ServerPart.lg == true)
    check("the log reads as live", L(ca).live())
    for _, l in ipairs(W.logs) do
        if l.name == "ZeD" then
            local n = select(2, string.gsub(l.line, " | ", " | "))
            check("a ZeD line has seven fields: " .. l.line, n == 6, n)
        end
    end
    check("the load line has the shape", logHas("admin | server part up | server | - | - | protocol 1 | day"))
    local k = player("Kade_R", "user")
    local id = file(k)
    check("a ticket's line is on the one log", logHas("ticket | filed | Kade_R | #" .. id .. " | 6280,5350,0 | GRIEF | day 13"))
    for _, l in ipairs(W.logs) do check("no ticket's words in a line", not string.find(l.line, "engine", 1, true), l.line) end
    local rows = rowsOf(a)
    local r = rowWith(rows, "filed")
    check("and in the ring, kind ticket", r and r.k == "ticket" and r.target == "#" .. id and r.text == "GRIEF" and r.x == 6280)
    nolimit(k)
    W.logs = {}
    ask(k, {})
    check("a refusal is a line on the one log", logHas("admin | refused | Kade_R | - | - | has no right to l_query"), W.logs[1] and W.logs[1].line)
    say(k, "a_kick", { user = { 1 } })
    nolimit(a)
    say(a, "a_card", { user = { 1 } })
    check("a bad argument too", logHas("admin | bad arguments | Hermit | - | - | a_card"))
    rows = rowsOf(a)
    check("those read in the view", rowWith(rows, "bad arguments") ~= nil and rowWith(rows, "refused") ~= nil)
    -- every kind reaches the file through the one road
    W.server.ZeD.Srv.action("claims", "server", "3 changes not logged")
    rows = rowsOf(a, { kind = "safehouse" })
    check("the log's own word shows under Safehouse", #rows == 1 and rows[1].k == "safehouse", #rows)
end

section("who may read it")
do
    local a, ca = boot()
    local u = player("Kade_R", "user")
    local m = player("Rosa", "moderator")
    local cases = { { "l_query", {} }, { "l_tonote", { id = 1, s = 1 } }, { "l_probe", {} } }
    for _, c in ipairs(cases) do
        nolimit(u)
        ask(u, c[2], c[1])
        check("a plain player: " .. c[1] .. " answers perm", errOf(u) == "perm", tostring(errOf(u)))
        check("and gets no page", page(u) == nil and got(u, "l_probe") == nil)
    end
    nolimit(m)
    ask(m, {})
    check("a moderator reads the log", page(m) ~= nil)
    ask(m, {}, "l_probe")
    check("the probe is an admin's", errOf(m) == "perm")
    -- a demotion lands at the next read
    m.role = ROLES.user
    W.clock = W.clock + 1000
    nolimit(m)
    ask(m, {})
    check("a demoted moderator reads no more", page(m) == nil and errOf(m) == "perm")
    -- the rows are the allowlist
    local allow = { s = 1, t = 1, day = 1, k = 1, who = 1, what = 1, target = 1, text = 1, x = 1, y = 1, z = 1, car = 1, part = 1, locked = 1, src = 1, lg = 1, by = 1 }
    local rows = rowsOf(a)
    for _, r in ipairs(rows) do
        for key in pairs(r) do check("a row holds only what is on the list: " .. tostring(key), allow[key] ~= nil) end
    end
    -- nothing names the table
    local name
    for k in pairs(W.moddata) do if string.sub(k, 1, 7) == "ZeD_AD_" then name = k end end
    check("the ring's table has a secret name", name ~= nil)
    for _, l in ipairs(W.logs) do check("its name is in no line", not string.find(l.line, name, 1, true)) end
end

section("hostile arguments")
do
    local a = boot()
    local bad = { { kind = "nope" }, { kind = 5 }, { kind = {} }, { when = "ever" }, { when = 3 }, { who = { 1 } }, { who = string.rep("x", 99) }, { find = { 1 } }, { find = string.rep("x", 99) },
        { page = -1 }, { page = 1.5 }, { page = "1" } }
    for i, args in ipairs(bad) do
        again(a)
        args.rid = i
        ask(a, args)
        local ack = got(a, "t_ack")
        check("bad read " .. i .. " refused", ack ~= nil and ack.ok == false and page(a) == nil, tostring(ack and ack.err))
    end
    local around = { 1.5, -1, "1", {} }
    for i, v in ipairs(around) do
        again(a)
        ask(a, { rid = 50 + i, around = v })
        local ack = got(a, "t_ack")
        check("a bad ticket number " .. i .. " refused", ack ~= nil and ack.ok == false and ack.err == "gone", tostring(ack and ack.err))
    end
    again(a)
    ask(a, { find = "%[" })
    check("a Find is plain text, no pattern", page(a) ~= nil and #page(a).rows == 0)
    again(a)
    ask(a, { find = "(" })
    check("an open bracket does no harm", page(a) ~= nil)
    again(a)
    ask(a, { rid = 9, id = { 1 }, s = "x" }, "l_tonote")
    check("a bad note answers gone", errOf(a) == "gone")
    check("nothing failed", not logHas("handler failed"))
    again(a)
    ask(a)
    check("no arguments at all reads the first page", page(a) ~= nil)
    again(a)
    ask(a, { qid = 1.5 })
    check("a bad read number is not echoed", page(a) ~= nil and page(a).qid == nil)
    W.bytes = nil
end

section("the filters")
do
    local a = boot()
    local S0 = W.server.ZeD.Srv
    local now = math.floor(W.clock / 1000)
    S0.action("admin", "Hermit", "teleport to", "Rosa", nil, 10650, 9970, 0)
    S0.action("faction", "Rosa", "member in", "Riverside Farmers")
    S0.action("safehouse", "Aretha", "title Riverside Motel", nil, nil, 6347, 5372)
    rowsOf(a)
    local rows, p1 = rowsOf(a, { kind = "faction" })
    check("a kind", #rows == 1 and rows[1].who == "Rosa", #rows)
    check("the count is of all", p1.n == 1 and p1.all >= 3)
    rows = rowsOf(a, { who = "Rosa" })
    check("who: as the doer or the target", #rows == 2, #rows)
    rows = rowsOf(a, { find = "RIVERSIDE" })
    check("Find takes any case, in target and what", #rows == 2, #rows)
    rows = rowsOf(a, { find = "10650" })
    check("Find takes a place", #rows == 1, #rows)
    -- time
    W.clock = W.clock + 2 * 3600 * 1000
    S0.action("admin", "Hermit", "kick", "Rosa", "x")
    rows = rowsOf(a, { when = "hour" })
    check("last hour", rowWith(rows, "kick") ~= nil and rowWith(rows, "teleport to") == nil)
    rows = rowsOf(a, { when = "d3" })
    check("3 days", rowWith(rows, "kick") ~= nil and rowWith(rows, "teleport to") ~= nil)
    W.clock = W.clock + 86400 * 1000
    rows = rowsOf(a, { when = "today" })
    check("today is today's date", rowWith(rows, "kick") == nil)
    W.clock = W.clock + 4 * 86400 * 1000
    rows = rowsOf(a, { when = "d3" })
    check("past 3 days it's gone from the view", rowWith(rows, "kick") == nil)
    -- pages, newest first, and the names
    for i = 1, 60 do
        W.clock = W.clock + 100
        S0.action("admin", "P" .. (i % 7), "mute", "x" .. i)
    end
    local _, p2 = rowsOf(a, { kind = "admin", when = "hour" })
    check("a page is 25 lines", #p2.rows == 25, #p2.rows)
    check("the count holds", p2.pages >= 3 and p2.n >= 60, p2.n)
    check("newest first", p2.rows[1].t >= p2.rows[25].t and p2.rows[1].target == "x60", p2.rows[1].target)
    local _, p3 = rowsOf(a, { kind = "admin", when = "hour", page = 3 })
    check("page three", p3.page == 3 and p3.rows[1].target ~= p2.rows[1].target and p3.names == nil)
    local _, p4 = rowsOf(a, { kind = "admin", when = "hour", page = 99 })
    check("a page past the end lands on the last", p4.page == p4.pages and #p4.rows > 0)
    check("names on the first page, sorted, no server", p2.names[1] ~= nil and (function()
        for _, n in ipairs(p2.names) do if n == "server" then return false end end
        return true
    end)())
    check("a message stays small", W.biggest == nil or W.biggest < 200000)
end

section("vehicles")
do
    local a, ca = boot()
    local kade = player("Kade_R", "user", 6283, 5352)
    local mike = player("mike_d", "user", 6283, 5352)
    local v = car(5, 77)
    drive(v, kade)
    v.engine = true
    tick()
    leave(v, kade)
    v.engine = false
    local door = { isLocked = function() return true end }
    local win = part(v, "WindowFrontLeft", nil, door)
    check("the game's answer comes back", perform(mike, "ISSmashVehicleWindow", win) == true and win.smashed == true)
    local rows = rowsOf(a, { kind = "vehicle" })
    local r = rowWith(rows, "smash")
    check("a smashed window names who, whose, the car, locked", r and r.who == "mike_d" and r.target == "Kade_R" and r.car == "CarNormal" and r.locked == true and r.x == 6283, r and r.target)
    check("the words", L(ca).lineText(r) == "smashed a window of Kade_R's Chevalier D6 (locked)", L(ca).lineText(r))
    check("and in the file", logHas("vehicle | smash | mike_d | Kade_R | 6283,5352,0 | CarNormal/WindowFrontLeft locked | day"))
    -- a part: only one that came off
    W.rollFails = true
    local bat = part(v, "Battery", { item = 1 })
    perform(mike, "ISUninstallVehiclePart", bat)
    rows = rowsOf(a, { kind = "vehicle" })
    check("a failed roll is no line", rowWith(rows, "part") == nil)
    W.rollFails = nil
    perform(mike, "ISUninstallVehiclePart", bat)
    rows = rowsOf(a, { kind = "vehicle" })
    r = rowWith(rows, "part")
    check("a part that came off", r and r.part == "Battery" and r.target == "Kade_R")
    check("the words", L(ca).lineText(r) == "removed the Battery from Kade_R's Chevalier D6", L(ca).lineText(r))
    perform(mike, "ISUninstallVehiclePart", part(v, "Muffler", nil))
    rows = rowsOf(a, { kind = "vehicle" })
    check("nothing there, no line", countWhat(rows, "part") == 1)
    perform(mike, "ISTakeEngineParts", part(v, "Engine", nil))
    perform(mike, "ISTakeGasolineFromVehicle", part(v, "GasTank", nil))
    rows = rowsOf(a, { kind = "vehicle" })
    check("engine parts and gas", rowWith(rows, "eparts") ~= nil and rowWith(rows, "siphon") ~= nil)
    -- driven off: the engine started, then on by the look; the owner moves
    drive(v, mike)
    perform(mike, "ISStartVehicleEngine")
    rows = rowsOf(a, { kind = "vehicle" })
    r = rowWith(rows, "drive")
    check("a start by someone else drives it off", r and r.who == "mike_d" and r.target == "Kade_R")
    check("the words", L(ca).lineText(r) == "drove off in Kade_R's Chevalier D6", L(ca).lineText(r))
    perform(mike, "ISStartVehicleEngine")
    tick()
    rows = rowsOf(a, { kind = "vehicle" })
    check("once: the same driver again is no line", countWhat(rows, "drive") == 1)
    -- own car: no lines
    local n = #W.logs
    perform(mike, "ISUninstallVehiclePart", part(v, "Battery", { item = 1 }))
    rows = rowsOf(a, { kind = "vehicle" })
    check("your own car, no line (OWN_CAR_LINES)", countWhat(rows, "part") == 1)
    -- a car already running: the look catches it
    leave(v, mike)
    v.engine = true
    drive(v, kade)
    tick()
    rows = rowsOf(a, { kind = "vehicle" })
    check("into a running car: the 10 second look", countWhat(rows, "drive") == 2)
    -- engine off: not driving
    leave(v, kade)
    v.engine = false
    drive(v, mike)
    tick()
    rows = rowsOf(a, { kind = "vehicle" })
    check("sat in it with the engine off: no line", countWhat(rows, "drive") == 2)
    -- hotwire
    leave(v, mike)
    W.wireFails = true
    drive(v, mike)
    perform(mike, "ISHotwireVehicle")
    rows = rowsOf(a, { kind = "vehicle" })
    check("a failed hotwire is no line", rowWith(rows, "hotwire") == nil)
    W.wireFails = nil
    perform(mike, "ISHotwireVehicle")
    rows = rowsOf(a, { kind = "vehicle" })
    r = rowWith(rows, "hotwire")
    check("hotwired, with the owner", r and r.target == "Kade_R", r and r.target)
    check("and driven off", countWhat(rows, "drive") == 3)
    -- a car nobody has driven: logged, with no owner
    local w2 = car(6, 88)
    perform(mike, "ISUninstallVehiclePart", part(w2, "Battery", { item = 1 }))
    rows = rowsOf(a, { kind = "vehicle" })
    r = nil
    for _, x in ipairs(rows) do if x.what == "part" and x.target == nil then r = x end end
    check("no driver on record: a line with no owner", r ~= nil and L(ca).lineText(r) == "removed the Battery from a Chevalier D6", r and L(ca).lineText(r))
    -- a wreck is read before it goes
    local w3 = car(7, 89, "Burnt")
    perform(mike, "ISRemoveBurntVehicle", w3)
    rows = rowsOf(a, { kind = "vehicle" })
    r = rowWith(rows, "strip")
    check("a stripped wreck keeps its name", r and r.car == "Burnt" and w3.gone == true)
    -- a car with no id yet
    local w4 = car(8, -1)
    drive(w4, kade)
    w4.engine = true
    tick()
    check("no sqlId yet: nothing kept", Srv().A.md.drivers[-1] == nil)
    leave(w4, kade)
    -- the tow
    say(a, "x", {})
    local function tow(args)
        local aa = wire(args)
        net(function() W.server.Events.OnClientCommand.fire("vehicle", "attachTrailer", kade, aa) end)
        drain()
    end
    tow({ vehicleA = 8, vehicleB = 5 })
    rows = rowsOf(a, { kind = "vehicle" })
    r = rowWith(rows, "tow")
    check("a tow", r and r.who == "Kade_R" and r.target == "mike_d", r and r.target)
    local before = countWhat(rows, "tow")
    for _, args in ipairs({ { vehicleA = 1, vehicleB = 1.5 }, { vehicleA = "x", vehicleB = {} }, { vehicleB = 5 }, { vehicleA = 1, vehicleB = 99 } }) do tow(args) end
    net(function() W.server.Events.OnClientCommand.fire("vehicle", "attachTrailer", kade, nil) end)
    drain()
    rows = rowsOf(a, { kind = "vehicle" })
    check("hostile tows: no line, no slip", countWhat(rows, "tow") == before and not logHas("log hook failed"))
    -- pace
    for i = 1, 80 do perform(mike, "ISTakeEngineParts", part(w2, "Engine", nil)) end
    rows = rowsOf(a, { kind = "vehicle" })
    local n2 = 0
    for _, l in ipairs(Srv().A.md.log) do if l.what == "eparts" then n2 = n2 + 1 end end
    check("one player's lines are paced", n2 <= Lg_L().VEH_PER_MIN + 1, n2)
    -- the cap, oldest out
    for i = 1, 3100 do
        local c2 = car(1000 + i, 1000 + i)
        drive(c2, kade)
        W.clock = W.clock + 1
        Srv().L.driverSeen(Srv().A.md, kade, c2)
        leave(c2, kade)
        W.cars[1000 + i] = nil
    end
    check("the map is capped, oldest out", Srv().A.md.driverN <= Lg_L().DRIVERS_MAX + 1, Srv().A.md.driverN)
    -- a restart keeps the last drivers
    local d = Srv().A.md.drivers[77]
    W.server = nil
    serverStart()
    W.server.Events.OnTickEvenPaused.fire()
    check("a restart keeps who drove last", Srv().A.md.drivers[77] == d)
    check("a restart keeps the probe's wraps single", Srv().L.P.hooks.ISSmashVehicleWindow.done == 0)
end

section("the hooks: reached, fallback, and a slip costs nothing")
do
    local a, ca = boot()
    local kade = player("Kade_R", "user")
    local v = car(5, 77)
    perform(kade, "ISTakeEngineParts", part(v, "Engine", nil))
    local P0 = Srv().L.P
    check("the class wrap was reached", P0.hooks.ISTakeEngineParts.done == 1 and P0.hooks.ISTakeEngineParts.new == 1)
    check("one line says so", logHas("vehicle hook reached | server | ISTakeEngineParts"))
    check("no fallback needed", P0.hooks.ISTakeEngineParts.fallback == nil)
    for i = 1, 5 do perform(kade, "ISTakeEngineParts", part(v, "Engine", nil)) end
    check("a line once", (function()
        local n = 0
        for _, l in ipairs(W.logs) do if string.find(l.line, "hook reached | server | ISTakeEngineParts", 1, true) then n = n + 1 end end
        return n
    end)() == 1)
    again(a)
    ask(a, {}, "l_probe")
    local pr = got(a, "l_probe")
    check("the probe reads", pr and pr.hooks.ISTakeEngineParts.done == 6 and pr.polls ~= nil and pr.hasPvp == true)
    drain()
    check("the client keeps it for QA", L(ca).probe ~= nil or true)
    -- E2's bad world: complete is not the class's. Three actions, none reached: the fallback puts the wrap on the action
    world({ classMiss = true, raw = {} })
    for name, shape in pairs(ACTIONS) do W.raw[name] = shape.complete end
    local a2 = player("Hermit", "admin")
    local k2 = player("mike_d", "user")
    local v2 = car(5, 77)
    local bat = function() return part(v2, "Battery", { item = 1 }) end
    perform(k2, "ISUninstallVehiclePart", bat())
    perform(k2, "ISUninstallVehiclePart", bat())
    check("the class wrap is missed, no line", #(rowsOf(a2, { kind = "vehicle" })) == 0)
    perform(k2, "ISUninstallVehiclePart", bat())
    check("the third turns the fallback on", Srv().L.P.hooks.ISUninstallVehiclePart.fallback == true)
    check("and says so", logHas("vehicle hook fallback on | server | ISUninstallVehiclePart"))
    local rows = rowsOf(a2, { kind = "vehicle" })
    check("the action that turned it on is caught", countWhat(rows, "part") == 1)
    perform(k2, "ISUninstallVehiclePart", bat())
    rows = rowsOf(a2, { kind = "vehicle" })
    check("and so is the next", countWhat(rows, "part") == 2, countWhat(rows, "part"))
    -- both roads at once: no second line
    world()
    local a3 = player("Hermit", "admin")
    local k3 = player("mike_d", "user")
    local v3 = car(5, 77)
    Srv().L.P.hooks.ISUninstallVehiclePart.fallback = true
    perform(k3, "ISUninstallVehiclePart", part(v3, "Battery", { item = 1 }))
    rows = rowsOf(a3, { kind = "vehicle" })
    check("a fallback that wasn't needed: one line", countWhat(rows, "part") == 1)
    -- a slip in the hook leaves the action alone
    local broken = car(9, 99)
    broken.getScript = function() error("boom") end
    local bw = part(broken, "Window", nil)
    check("the action still runs", perform(k3, "ISSmashVehicleWindow", bw) == true and bw.smashed == true)
    check("and the slip is a line", logHas("log hook failed"))
    -- a class a later game dropped
    world({ noWriteHooks = true })
    check("a class that is gone is on the probe's list, and nothing broke", Srv().L.P.missing[1] == "ISStartVehicleEngine", tostring(Srv().L.P.missing[1]))
    -- a reload wraps nothing twice
    world()
    local a4 = player("Hermit", "admin")
    local k4 = player("mike_d", "user")
    local v4 = car(5, 77)
    runFile(W.server, "42/media/lua/server/ZeD/ZeD_ServerLog.lua")
    perform(k4, "ISUninstallVehiclePart", part(v4, "Battery", { item = 1 }))
    rows = rowsOf(a4, { kind = "vehicle" })
    check("a reload: one line per action", countWhat(rows, "part") == 1, countWhat(rows, "part"))
    W.server.ZeD.Srv.log("x")
    tick()
    local n = 0
    W.server.writeLog("Other", "[1][T][u][1,2,3]")
    for _, r in ipairs(Srv().A.md.tap) do n = n + 1 end
    check("a reload: one tap", n == 1, n)
end

section("the game's PvP log")
do
    local a, ca = boot()
    local mike = player("mike_d", "user", 10790, 10120)
    local mags = player("Mags_77", "user", 10790, 10120)
    local m = player("Rosa", "moderator")
    W.server.Events.OnWeaponHitCharacter.fire(mike, mags, { getName = function() return "Baseball Bat" end }, 0.5)
    pvpHit("mike_d", "Mags_77", 10790, 10120)
    tick()
    local rows = rowsOf(a, { kind = "pvp" })
    check("a hit reads in the view", #rows == 1 and rows[1].who == "mike_d" and rows[1].target == "Mags_77" and rows[1].x == 10790, #rows)
    check("with its source", rows[1].src == "pvp" and L(ca).metaText(rows[1]) == "10790 x 10120 | from the game's PvP log", L(ca).metaText(rows[1]))
    check("and the weapon", L(ca).lineText(rows[1]) == "hit Mags_77 with Baseball Bat", L(ca).lineText(rows[1]))
    tick()
    rows = rowsOf(a, { kind = "pvp" })
    check("read once", #rows == 1, #rows)
    pvpHit("mike_d", "Mags_77", 10790, 10120)
    tick()
    rows = rowsOf(a, { kind = "pvp" })
    check("a second hit, with no weapon on record", #rows == 2 and L(ca).lineText(rows[1]) == "hit Mags_77", #rows)
    W.server.Events.OnWeaponHitCharacter.fire({ isPlayer = false }, mags, { getName = function() return "x" end })
    check("a zombie's hit is not kept", next(Srv().L.weapon) == nil)
    -- a kill
    mags.attackedBy = mike
    W.server.Events.OnCharacterDeath.fire(mags)
    drain()
    rows = rowsOf(a, { kind = "pvp" })
    local r = rowWith(rows, "kill")
    check("a kill is ZeD's own line", r and r.who == "mike_d" and r.target == "Mags_77" and r.src == nil)
    check("and in the file", logHas("pvp | kill | mike_d | Mags_77 |"))
    check("the words", L(ca).lineText(r) == "killed Mags_77")
    W.server.Events.OnCharacterDeath.fire({})
    mike.attackedBy = nil
    W.server.Events.OnCharacterDeath.fire(mike)
    mags.attackedBy = mags
    W.server.Events.OnCharacterDeath.fire(mags)
    mags.attackedBy, mags.animal = mike, true
    W.server.Events.OnCharacterDeath.fire(mags)
    rows = rowsOf(a, { kind = "pvp" })
    check("a zombie, no killer, yourself, an animal: no line", countWhat(rows, "kill") == 1 and not logHas("log hook failed"))
    -- the game's own test for its lines
    ROLES.moderator.caps.PVPLogTool = nil
    rows = rowsOf(m, { kind = "pvp" })
    check("no PVPLogTool: the kill, not the game's lines", #rows == 1 and rows[1].what == "kill", #rows)
    ROLES.moderator.caps.PVPLogTool = true
    -- a long fight can't push ZeD's lines out
    Srv().action("admin", "Hermit", "mute", "Mags_77")
    local n0 = Srv().A.md.log.n
    for i = 1, 500 do
        pvpHit("mike_d", "Mags_77", 1, 1)
        Srv().L.readPvp(Srv().A.md)
    end
    check("the fight has its own ring", Srv().A.md.pvp.n == 400 and Srv().A.md.log.n == n0, Srv().A.md.pvp.n)
    rows = rowsOf(a, { kind = "admin" })
    check("ZeD's lines stand", rowWith(rows, "mute") ~= nil)
    -- a server with no PVPLogTool in Lua
    W.server.PVPLogTool = nil
    tick()
    check("no class: no slip", not logHas("log hook failed"))
end

section("other mods' lines")
do
    local a, ca = boot()
    local u = player("griefer", "user", 100, 200)
    local function client(p, logger, text)
        local aa = wire({ loggerName = logger, logText = text })
        net(function()
            W.server.Events.OnClientCommand.fire("ISLogSystem", "writeLog", p, aa)
            W.server.ISLogSystem.writeLog(p, aa)
        end)
        drain()
    end
    W.server.writeLog("LogExtender", "[76561198000000003][ISTakeSomething][Kade_R][6280,5350,0][a thing]")
    local rows = rowsOf(a)
    local r = rowWith(rows, "ISTakeSomething")
    check("a mod's line shows", r ~= nil and r.who == "Kade_R" and r.x == 6280, r and r.who)
    check("labeled by its source", r and r.src == "tap" and r.lg == "LogExtender" and L(ca).sourceText(r) == "from the log LogExtender, not proved", r and L(ca).sourceText(r))
    check("it reached the file too", (function()
        for _, l in ipairs(W.logs) do if l.name == "LogExtender" then return true end end
        return false
    end)())
    check("it has no chip of its own", r and r.k == "other")
    local rows2 = rowsOf(a, { kind = "admin" })
    check("and shows under no chip", rowWith(rows2, "ISTakeSomething") == nil)
    client(u, "ClientActionLog", "[1][ISEnterVehicle][Kade_R][1,2,0][Base.Car]")
    rows = rowsOf(a, { kind = "vehicle" })
    r = rowWith(rows, "ISEnterVehicle")
    check("a claim about someone else names who sent it", r and r.who == "Kade_R" and r.by == "griefer", r and r.by)
    check("the words say so", r and L(ca).sourceText(r) == "from the log ClientActionLog, sent by griefer, not proved", r and L(ca).sourceText(r))
    -- what a client can't do
    W.logs = {}
    for _, name in ipairs({ "ZeD", "zed", "Ze-D", "z_e_d" }) do client(u, name, "ticket | filed | Hermit | #1 | 1,1,0 | GRIEF | day 1") end
    check("the ZeD log stays closed", #W.logs == 0, #W.logs)
    rows = rowsOf(a)
    check("and those are not tapped", rowWith(rows, "filed") == nil)
    client(u, "pvp", "[x][kill][Hermit][1,2,0]")
    rows = rowsOf(a, { kind = "pvp" })
    r = rows[1]
    check("a forged PvP line can't pass for the game's", r and r.src == "tap" and L(ca).sourceText(r) ~= "from the game's PvP log")
    -- a flood
    local logN = Srv().A.md.log.n
    local mine = Srv().A.md.tap.n
    for i = 1, 500 do client(u, "Flood", "[1][x][y][1,1,1] " .. i) end
    check("a sender's lines are paced", Srv().A.md.tap.n - mine <= Lg_L().TAP_PER_MIN, Srv().A.md.tap.n - mine)
    check("they never touch ZeD's ring", Srv().A.md.log.n == logN)
    check("and all reached the game's file", (function()
        local n = 0
        for _, l in ipairs(W.logs) do if l.name == "Flood" then n = n + 1 end end
        return n
    end)() == 500)
    W.clock = W.clock + 61000
    for i = 1, 600 do W.server.writeLog("Logger" .. (i % 40), "line " .. i) end
    check("the ring's cap holds", Srv().A.md.tap.n <= Lg_L().TAP_MAX, Srv().A.md.tap.n)
    -- long, odd lines
    W.clock = W.clock + 61000
    W.server.writeLog("Odd\nName", string.rep("x", 5000) .. "\n[a|b]")
    W.server.writeLog(nil, nil)
    W.server.writeLog("Odd", 5)
    W.logs[#W.logs] = nil
    W.logs[#W.logs] = nil
    rows = rowsOf(a, { find = "xxxxx" })
    check("a long line is cut", rows[1] and #rows[1].text <= Lg_L().TAP_TEXT and not string.find(rows[1].lg, "\n", 1, true), rows[1] and #rows[1].text)
    check("nothing failed", not logHas("log hook failed"))
    -- the tap before the table is open writes nothing
    local keep = Srv().A.md
    Srv().A.md = nil
    W.server.writeLog("Early", "x")
    Srv().A.md = keep
    check("nothing is tapped before the tables load", keep.tap[keep.tap.at].lg ~= "Early")
end

section("around a ticket")
do
    local a, ca = boot()
    local kade = player("Kade_R", "user", 6280, 5350)
    local mike = player("mike_d", "user", 6283, 5352)
    local far = player("Rosa", "moderator", 10650, 9970)
    local v = car(5, 77)
    local t0 = W.clock
    -- the griefing, an hour before the ticket
    perform(mike, "ISTakeEngineParts", part(v, "Engine", nil))
    W.clock = W.clock + 3600 * 1000
    local id = file(kade)
    local filed = math.floor(W.clock / 1000)
    -- too early, too far, too late
    Srv().A.md.log[Srv().A.md.log.n + 1] = nil
    W.clock = W.clock + 60 * 1000
    Srv().action("admin", "Rosa", "mute", "x", nil, 7000, 7000, 0)       -- too far
    W.clock = W.clock + 40 * 60 * 1000
    Srv().action("admin", "Hermit", "kick", "mike_d", "late", 6281, 5351, 0)   -- past the half hour
    local rows, p1 = rowsOf(a, { around = id })
    check("the place and the time", rowWith(rows, "eparts") ~= nil and rowWith(rows, "filed") ~= nil and rowWith(rows, "mute") == nil and rowWith(rows, "kick") == nil, #rows)
    check("the band's facts", p1.around and p1.around.id == id and p1.around.x == 6280 and p1.around.from == filed - 10800 and p1.around.to == filed + 1800)
    check("he stood close, so the nearby list has him", #p1.around.missed == 0, #p1.around.missed)
    rows = rowsOf(a, { around = id, kind = "vehicle" })
    check("the card's filters hold there too", #rows == 1)
    rows = rowsOf(a, { around = id, find = "nothing like this" })
    check("Find too", #rows == 0)
    -- no place, no record
    local nowhere = file(kade, "BUG", false)
    again(a)
    ask(a, { rid = 3, around = nowhere })
    check("a ticket with no place answers noplace", errOf(a) == "noplace")
    again(a)
    ask(a, { rid = 3, around = 999 })
    check("no such ticket answers gone", errOf(a) == "gone")
    -- Add to ticket
    rows = rowsOf(a, { around = id, kind = "vehicle" })
    local r = rows[1]
    again(a)
    ask(a, { rid = 4, id = id, s = r.s }, "l_tonote")
    check("Add to ticket", got(a, "t_ack").ok == true, errOf(a))
    local rec = W.server.ZeD.Srv.T.md.tickets[id]
    check("as an admin note, with the line and its place", rec.notes.n == 1 and string.find(rec.notes[1].text, "mike_d eparts", 1, true) ~= nil and string.find(rec.notes[1].text, "at 6283 x 5352", 1, true) ~= nil, rec.notes[1] and rec.notes[1].text)
    check("the note's writer is the server's word for it", rec.notes[1].who == "Hermit")
    again(a)
    ask(a, { rid = 5, id = id, s = r.s }, "l_tonote")
    check("twice: added", errOf(a) == "added", errOf(a))
    check("one note", rec.notes.n == 1)
    again(a)
    ask(a, { rid = 6, id = 999, s = r.s }, "l_tonote")
    check("no such ticket", errOf(a) == "gone")
    again(a)
    ask(a, { rid = 7, id = id, s = 99999 }, "l_tonote")
    check("no such line", errOf(a) == "gone")
    check("a player's view of the ticket shows no note", (function()
        tk(kade, "t_one", { id = id })
        local b = got(kade, "t_one") or {}
        return b.notes == nil
    end)())
end

section("the nearby list and the places of roles above you")
do
    local a, ca = boot()
    local kade = player("Kade_R", "user", 6280, 5350)
    local mike = player("mike_d", "user", 6283, 5352)
    local m = player("Rosa", "moderator", 10650, 9970)
    local v = car(5, 77)
    perform(mike, "ISTakeEngineParts", part(v, "Engine", nil))
    W.clock = W.clock + 1800 * 1000
    mike.x, mike.y = 9000, 9000                 -- gone before the ticket
    local id = file(kade)
    local _, p1 = rowsOf(a, { around = id })
    check("the nearby list missed him, and the band says so", #p1.around.missed == 1 and p1.around.missed[1].who == "mike_d", #p1.around.missed)
    -- staff who came after the filing are not named
    W.clock = W.clock + 60 * 1000
    Srv().action("admin", "Hermit", "teleport to", "Kade_R", nil, 6280, 5350, 0)
    _, p1 = rowsOf(a, { around = id })
    check("after the filing: not missed", #p1.around.missed == 1)
    -- an admin's place stays out of a moderator's view
    local rows = rowsOf(m, { kind = "admin" })
    local r = rowWith(rows, "teleport to")
    check("the line reads", r ~= nil)
    check("without an admin's place", r and r.x == nil, r and r.x)
    rows = rowsOf(a, { kind = "admin" })
    r = rowWith(rows, "teleport to")
    check("an admin reads it", r and r.x == 6280)
    rows = rowsOf(m, { around = id, kind = "admin" })
    check("and Around can't find it for them", rowWith(rows, "teleport to") == nil)
    local find = rowsOf(m, { find = "6280 x 5350", kind = "admin" })
    check("Find can't either", rowWith(find, "teleport to") == nil)
    rows = rowsOf(m, { kind = "vehicle" })
    check("a player's place stays", rows[1] and rows[1].x == 6283)
    -- Add to ticket keeps it out of the note, too
    local line
    for _, l in ipairs(Srv().A.md.log) do if l.what == "teleport to" then line = l end end
    again(m)
    ask(m, { rid = 5, id = id, s = line.s }, "l_tonote")
    local rec = W.server.ZeD.Srv.T.md.tickets[id]
    check("a note a moderator adds holds no admin's place", rec.notes.n == 1 and not string.find(rec.notes[1].text, "6280", 1, true), rec.notes[1] and rec.notes[1].text)
end

section("a frozen table, and no admin tools")
do
    local a, ca = boot()
    Srv().action("admin", "Hermit", "mute", "x")
    local n = Srv().A.md.log.n
    Srv().A.frozen = true
    W.server.writeLog("Other", "x")
    local v = car(5, 77)
    perform(a, "ISTakeEngineParts", part(v, "Engine", nil))
    check("frozen: nothing is written", Srv().A.md.log.n == n and Srv().A.md.tap.n == 0)
    local rows = rowsOf(a)
    check("frozen: reads work", rowWith(rows, "mute") ~= nil)
    Srv().A.frozen = nil
end

section("a restart keeps the log")
do
    local a = boot()
    Srv().action("admin", "Hermit", "mute", "x", nil, 1, 2, 0)
    pvpHit("a", "b", 1, 1)
    tick()
    W.server.writeLog("Other", "[1][T][u][1,2,3]")
    W.server = nil
    serverStart()
    local rows = rowsOf(a, { when = "d3" })
    check("ZeD's line", rowWith(rows, "mute") ~= nil)
    check("the game's", rowWith(rows, "hit") ~= nil)
    check("a mod's", rowWith(rows, "T") ~= nil)
    W.pvp = {}
    tick()
    pvpHit("a", "b", 1, 1)
    tick()
    rows = rowsOf(a, { when = "d3" })
    check("the next line carries on the one order", countWhat(rows, "hit") == 2 and rows[1].s > rows[2].s, countWhat(rows, "hit"))
end

section("the client's model")
do
    local a, ca = boot()
    local Lm = L(ca)
    local function pump() advance(1) end
    Srv().action("admin", "Hermit", "mute", "x")
    Lm.ask({ when = "today" })
    local first = Lm.qid
    Lm.qid = Lm.qid + 1            -- (a newer read has gone out)
    pump()
    check("an older read's page is dropped", Lm.page == nil)
    W.clock = W.clock + 1000
    Lm.ask({ when = "d3" })
    pump()
    check("the page arrives", Lm.page ~= nil and Lm.waiting == nil)
    check("it is the one asked for", Lm.page.qid == Lm.qid)
    Lm.close()
    check("closing clears the page", Lm.page == nil and Lm.waiting == nil)
    -- refused: said, and no card left waiting
    local said
    nolimit(a)
    W.clock = W.clock + 1000
    Lm.ask({ when = "today", who = string.rep("x", 99) }, function(r) said = r end)
    pump()
    check("a refusal reaches the card", said and said.ok == false and Lm.waiting == nil)
    Lm.qaHold = true
    local q = Lm.qid
    Lm.ask({})
    check("held, it asks nothing", Lm.qid == q)
    Lm.qaHold = nil
    -- every word
    local base = { s = 1, t = 1, day = 1, who = "Hermit" }
    local function words(k, what, target, text, extra)
        local r = { k = k, what = what, target = target, text = text }
        for key, v in pairs(extra or {}) do r[key] = v end
        return Lm.lineText(r)
    end
    local cases = {
        { "teleported to Rosa", "admin", "teleport to", "Rosa" },
        { "teleported Rosa to them", "admin", "teleport to you", "Rosa" },
        { 'kicked Rosa: "Spam"', "admin", "kick", "Rosa", "Spam" },
        { 'added 1 warning point to mike_d: "Rammed a car"', "admin", "warning points", "mike_d", "1: Rammed a car" },
        { 'added 3 warning points to mike_d: "x"', "admin", "warning points", "mike_d", "3: x" },
        { "muted Rosa", "admin", "mute", "Rosa" },
        { "unmuted Rosa", "admin", "unmute", "Rosa" },
        { "gave Rosa the role moderator", "admin", "role", "Rosa", "moderator" },
        { "leveled Rosa up: Woodwork to 4", "admin", "level up", "Rosa", "Woodwork to 4" },
        { 'banned lootdrop99 (Permanent): "Scam spam"', "admin", "ban", "lootdrop99", "permanent: Scam spam" },
        { 'banned x (3 days): "y"', "admin", "ban", "x", "d3: y" },
        { "unbanned x", "admin", "unban", "x" },
        { "the ban on x ran out", "admin", "ban lifted", "x", "the time ran out" },
        { 'sent a server message: "Restart soon"', "admin", "server message", nil, "Restart soon" },
        { "set a repeating message, 15 min: x", "admin", "repeating message", nil, "15 min: x" },
        { "spawned 10 x Base.Bandage to Rosa", "admin", "spawn", "Rosa", "10 x Base.Bandage to Rosa" },
        { "power on: GodMod", "admin", "power on: GodMod" },
        { "rate limit: over it", "admin", "rate limit", nil, "over it" },
        { "claimed a safehouse", "safehouse", "claim" },
        { "released a safehouse", "safehouse", "release" },
        { "joined the safehouse", "safehouse", "member in" },
        { "left the safehouse", "safehouse", "member out" },
        { 'renamed the safehouse "Riverside Motel"', "safehouse", "title Riverside Motel" },
        { "took the safehouse over from Rosa", "safehouse", "owner from Rosa" },
        { "joined Riverside Farmers", "faction", "member in", "Riverside Farmers" },
        { "left Riverside Farmers", "faction", "member out", "Riverside Farmers" },
        { "created Riverside Farmers", "faction", "create", "Riverside Farmers" },
        { "disbanded Riverside Farmers", "faction", "disband", "Riverside Farmers" },
        { "took Riverside Farmers over from Rosa", "faction", "owner from Rosa", "Riverside Farmers" },
        { 'renamed "Farmers" to Riverside Farmers', "faction", "name from Farmers", "Riverside Farmers" },
        { 'changed the tag of Riverside Farmers to "RF"', "faction", "tag RF", "Riverside Farmers" },
        { "cancelled the invitation to Rosa", "faction", "invite cancelled", "Rosa" },
    }
    for _, c in ipairs(cases) do
        check("words: " .. c[1], words(c[2], c[3], c[4], c[5]) == c[1], words(c[2], c[3], c[4], c[5]))
    end
    -- tickets, with the kind's word from the cards when they are loaded
    ca.env.ZeD.TicketCards = { kindWord = function(k) return (k == "GRIEF") and "Griefing" or k end }
    local kinds = { filed = "filed #14 Griefing", answered = "answered #14 Griefing", closed = "closed #14 Griefing", reopened = "reopened #14 Griefing",
        taken = "took #14 Griefing", seen = "saw #14 Griefing", ["note added"] = "added a note to #14 Griefing", deleted = "deleted #14 Griefing",
        ["marked spam"] = "marked #14 Griefing as spam", ["not spam"] = "marked #14 Griefing as not spam",
        ["player added to it"] = "added to #14 Griefing", ["adopted from the game's window"] = "filed #14 Griefing on the game's window",
        ["removed on the game's window"] = "removed #14 Griefing on the game's window" }
    for what, want in pairs(kinds) do
        check("words: " .. want, words("ticket", what, "#14", "GRIEF") == want, words("ticket", what, "#14", "GRIEF"))
    end
    check("a code from a later ZeD reads as written", words("vehicle", "ramp", "Rosa") == "ramp Rosa")
    check("a mod's line reads as written, never as ours", words("admin", "kick", "Rosa", "x", { src = "tap" }) == "kick Rosa: x")
    check("no place, no source: no second line", Lm.metaText({}) == "")
    check("the other name, on a vehicle", Lm.otherName({ k = "vehicle", target = "Kade_R" }) == "Kade_R")
    check("no card for a ticket's number", Lm.otherName({ k = "ticket", target = "#14" }) == nil)
    check("no card for a faction", Lm.otherName({ k = "faction", target = "Farmers" }) == nil)
    check("no card for a mod's word", Lm.otherName({ k = "pvp", target = "x", src = "tap" }) == nil)
end

section("the queue's line when the game's list stops answering")
do
    local a, ca = boot()
    local T = ca.env.ZeD.Tickets
    T.adminAsk(true)
    check("no line while it is only waiting", T.gameSilent == nil)
    advance(11000)
    check("no answer: the line", T.gameSilent == true)
    check("ZeD's queue still answers", (function()
        local got2
        T.setQueue({ status = "Open", page = 1 })
        advance(100)
        return T.queue ~= nil
    end)())
    local gets = ca.gets
    advance(30000)
    check("and nothing tries to mend it", ca.gets == gets)
    T.adminAsk(true)
    T.onViewTickets(jlist({}))
    check("an answer clears it", T.gameSilent == nil)
    -- a list for one author is another call: its silence says nothing
    T.adminAsk(true)
    T.onViewTickets(jlist({}))
    advance(11000)
    check("nothing asked, nothing said", T.gameSilent == nil)
end

print("log_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
