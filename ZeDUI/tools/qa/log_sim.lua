-- ZeDUI/tools/qa/log_sim.lua  (Nov 6 2026, QA): the log's server side and client model with no game running.
-- (the review's fixes added: who owns a car, the tow's look, a stopped siphon, the fallback's test, what a tapped line can't carry)
-- The harness is admin_sim.lua's: Lua 5.1 stubs of the game and the real files run against them, ZeD_TicketProto, ZeD_AdminProto,
-- ZeD_LogProto, ZeD_ServerCore, ZeD_ServerTickets, ZeD_ServerAdmin, ZeD_ServerLog, and on each simulated client ZeD_ServerLink,
-- ZeD_Tickets, ZeD_Admin and ZeD_Log. The seven timed actions are small classes of the game's shape, and a stub of
-- NetTimedAction runs them as the bytecode reads: the class's .new by name, then complete through rawget on the action.
-- The one log's shape, who may read it, hostile arguments, the filters and pages, vehicles, the E2 fallback, the game's PvP log,
-- other mods' lines and what they can't do, Around ticket, Add to ticket, a restart, the words for every line, the ticket queue's
-- line when the game's list stops answering. The last sections run ZeD_ServerExtras beside the Log, on the same classes, in the
-- game's load order: Phase 4 and Phase 6 together (world({ extras = true })).
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
    "ToggleGodModHimself", "AnswerTickets", "SeeNetworkUsers", "ReadUserLog", "TeleportToCoordinates", "PVPLogTool",
    "ChangeAndReloadServerOptions", "ManipulateVehicle", "UseBuildCheat" }) do CAPS[n] = n end

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
local ADMIN_CAPS = { "RolesWrite", "CantBeKickedByUser", "CantBeBannedByUser", "PVPLogTool", "ChangeAndReloadServerOptions", "ManipulateVehicle",
    "UseBuildCheat", "TeleportToCoordinates" }
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
    WORDS.IGUI_CheatPanel_GodMod = "God Mode"
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
    ISTakeGasolineFromVehicle = { complete = function() return true end, serverStop = function() W.gasStops = (W.gasStops or 0) + 1 end,
        -- (the game's: an "update" event each second moves the gas, long before complete)
        animEvent = function(self, event)
            if event == "update" and self.part then self.part.amount = self.part.amount - 1 end
        end },
    ISRemoveBurntVehicle = { complete = function(self) self.vehicle.gone = true; self.vehicle.script = nil; return true end },
    -- (the game's answers true whether or not the engine caught)
    ISStartVehicleEngine = { complete = function(self)
        if not W.noStart then self.character:getVehicle().engine = true end
        return true
    end },
    ISHotwireVehicle = { complete = function(self) self.character:getVehicle().wired = not W.wireFails; return true end },
}
function actionClass(name, shape)
    local C = { Type = name }
    C.__index = C
    C.complete = shape.complete
    C.serverStop = shape.serverStop
    C.animEvent = shape.animEvent
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

-- what the game does to a cancelled action: serverStop by the same road, if there is one
function cancel(act)
    local fn = rawget(act, "serverStop") or rawget(getmetatable(act), "serverStop")
    if fn then fn(act) end
end

local function car(id, sql, x)
    local v = { isCar = true, id = id, sql = sql, script = { name = x or "CarNormal" }, parts = {}, x = 6283, y = 5352 }
    function v.getX(self) return self.x end
    function v.getY(self) return self.y end
    function v.getVehicleTowedBy(self) return self.towedBy end
    function v.getSqlId(self) return self.sql end
    function v.getScript(self)
        local s = self.script
        return s and { getName = function() return s.name end, getCarModelName = function() return nil end } or nil
    end
    function v.isDriver(self, o) return self.driver == o end
    function v.isEngineRunning(self) return self.engine == true end
    function v.isHotwired(self) return self.wired == true end
    -- what the server extras call
    v.md = {}
    function v.getModData(self) return self.md end
    function v.getDriver(self) return self.driver end
    function v.isBurnt(self) return self.burnt == true end
    function v.isStarting(self) return self.starting == true end
    function v.shutOff(self) self.engine = false; self.shut = (self.shut or 0) + 1 end
    function v.addPointConstraint(self, p, other) other.towedBy = self end
    -- (breakConstraint(IsoPlayer, boolean, boolean): the game's clears the other car's vehicleTowedBy)
    function v.breakConstraint(self, p, a, b)
        if type(a) ~= "boolean" or type(b) ~= "boolean" then error("No implementation found: breakConstraint") end
        self.broke = (self.broke or 0) + 1
        for _, c in pairs(W.cars) do if c.towedBy == self then c.towedBy = nil end end
    end
    W.cars[id] = v
    return v
end
local function part(v, id, item, door)
    local q = { id = id, item = item, v = v }
    function q.getVehicle(self) return self.v end
    function q.getId(self) return self.id end
    function q.getInventoryItem(self) return self.item end
    function q.getContainerContentAmount(self) return self.amount or 0 end
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
    env.getItemNameFromFullType = function(t) return (t == "Base.Bandage") and "Bandage" or error("no such item") end
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
    ["ZeD/ZeD_ExtrasProto"] = "42/media/lua/shared/ZeD/ZeD_ExtrasProto.lua",
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
    env.getTextOrNull = function(k) return WORDS[k] end
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
    if W.extras then
        env.SafeHouse = { getSafehouseList = function() return jlist(W.safes or {}) end }
        env.WarManager = { isWarStarted = function() return false end }
        env.Faction = { getPlayerFaction = function() return nil end }
        -- the game's own handler for vehicle commands, first in line as it is on a server
        env.Events.OnClientCommand.Add(function(module, command, p, args)
            if module == "vehicle" and command == "attachTrailer" then
                env.getVehicleById(args.vehicleA):addPointConstraint(p, env.getVehicleById(args.vehicleB))
            end
        end)
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
    env.loaded["ZeD/ZeD_ServerAdmin"] = true
    runFile(env, FILES["ZeD/ZeD_LogProto"])
    env.loaded["ZeD/ZeD_LogProto"] = true
    -- (the game's order, alphabetical in the folder: the extras' file loads before the Log's)
    if W.extras then
        runFile(env, FILES["ZeD/ZeD_ExtrasProto"])
        env.loaded["ZeD/ZeD_ExtrasProto"] = true
        runFile(env, "42/media/lua/server/ZeD/ZeD_ServerExtras.lua")
    end
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
local function countBy(rows, what, who)
    local n = 0
    for _, r in ipairs(rows or {}) do
        if r.what == what and r.who == who then n = n + 1 end
    end
    return n
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
    check("the load line has the shape", logHas("admin | server part up | @server | - | - | protocol 1 | day"))
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
    W.server.ZeD.Srv.action("claims", W.server.ZeD.Tk.SYS, "3 changes not logged")
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
    local allow = { s = 1, t = 1, day = 1, k = 1, who = 1, what = 1, target = 1, text = 1, x = 1, y = 1, z = 1, car = 1, part = 1, locked = 1, src = 1, lg = 1, by = 1, hid = 1 }
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
        for _, n in ipairs(p2.names) do if n == "@server" then return false end end
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
    local d3 = { kind = "vehicle", when = "d3" }
    drive(v, mike)
    perform(mike, "ISStartVehicleEngine")
    rows = rowsOf(a, d3)
    r = rowWith(rows, "drive")
    check("a start by someone else drives it off", r and r.who == "mike_d" and r.target == "Kade_R")
    check("the words", L(ca).lineText(r) == "drove off in Kade_R's Chevalier D6", L(ca).lineText(r))
    perform(mike, "ISStartVehicleEngine")
    tick()
    rows = rowsOf(a, d3)
    check("once: the same driver again is no line", countBy(rows, "drive", "mike_d") == 1)
    -- held for the settling time: their own car, no lines
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    local n = countWhat(rows, "part")
    perform(mike, "ISUninstallVehiclePart", part(v, "Battery", { item = 1 }))
    rows = rowsOf(a, d3)
    check("your own car, no line (OWN_CAR_LINES)", countWhat(rows, "part") == n)
    -- a car already running: the look catches it
    leave(v, mike)
    v.engine = true
    drive(v, kade)
    tick()
    rows = rowsOf(a, d3)
    check("into a running car: the 10 second look", countBy(rows, "drive", "Kade_R") == 2, countBy(rows, "drive", "Kade_R"))
    -- engine off: not driving
    leave(v, kade)
    v.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    drive(v, mike)
    tick()
    rows = rowsOf(a, d3)
    check("sat in it with the engine off: no line", countBy(rows, "drive", "mike_d") == 1)
    -- hotwire
    leave(v, mike)
    W.wireFails = true
    drive(v, mike)
    perform(mike, "ISHotwireVehicle")
    rows = rowsOf(a, d3)
    check("a failed hotwire is no line", rowWith(rows, "hotwire") == nil)
    W.wireFails = nil
    perform(mike, "ISHotwireVehicle")
    rows = rowsOf(a, d3)
    r = rowWith(rows, "hotwire")
    check("hotwired, with the owner", r and r.target == "Kade_R", r and r.target)
    check("hotwired is not driven off: the engine isn't on", countBy(rows, "drive", "mike_d") == 1)
    v.engine = true
    tick()
    rows = rowsOf(a, d3)
    check("and driven off once it runs", countBy(rows, "drive", "mike_d") == 2, countBy(rows, "drive", "mike_d"))
    leave(v, mike)
    v.engine = false
    -- a car nobody has driven: logged, with no owner
    local w2 = car(6, 88)
    perform(mike, "ISUninstallVehiclePart", part(w2, "Battery", { item = 1 }))
    rows = rowsOf(a, d3)
    r = nil
    for _, x in ipairs(rows) do if x.what == "part" and x.target == nil then r = x end end
    check("no driver on record: a line with no owner", r ~= nil and L(ca).lineText(r) == "removed the Battery from a Chevalier D6", r and L(ca).lineText(r))
    -- a wreck is read before it goes
    local w3 = car(7, 89, "Burnt")
    perform(mike, "ISRemoveBurntVehicle", w3)
    rows = rowsOf(a, d3)
    r = rowWith(rows, "strip")
    check("a stripped wreck keeps its name", r and r.car == "Burnt" and w3.gone == true)
    -- a car with no id yet
    local w4 = car(8, -1)
    drive(w4, kade)
    w4.engine = true
    tick()
    check("no sqlId yet: nothing kept", Srv().A.md.drivers[-1] == nil)
    leave(w4, kade)
    -- pace
    tick(61)
    for i = 1, 80 do perform(mike, "ISTakeEngineParts", part(w2, "Engine", nil)) end
    rows = rowsOf(a, { kind = "vehicle" })
    local n2 = 0
    for _, l in ipairs(Srv().A.md.world) do if l.what == "eparts" then n2 = n2 + 1 end end
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
    check("one line says so", logHas("vehicle hook reached | @server | ISTakeEngineParts"))
    check("no fallback needed", P0.hooks.ISTakeEngineParts.fallback == nil)
    for i = 1, 5 do perform(kade, "ISTakeEngineParts", part(v, "Engine", nil)) end
    check("a line once", (function()
        local n = 0
        for _, l in ipairs(W.logs) do if string.find(l.line, "hook reached | @server | ISTakeEngineParts", 1, true) then n = n + 1 end end
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
    W.clock = W.clock + Lg_L().HOOK_WAIT_S * 1000
    perform(k2, "ISUninstallVehiclePart", bat())
    check("the third turns the fallback on", Srv().L.P.hooks.ISUninstallVehiclePart.fallback == true)
    check("and says so", logHas("vehicle hook fallback on | @server | ISUninstallVehiclePart"))
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
    client(u, "Vehicle", "[1][ISEnterVehicle][Kade_R][1,2,0][Base.Car]")
    rows = rowsOf(a, { kind = "vehicle" })
    r = rowWith(rows, "ISEnterVehicle")
    check("a claim about someone else names who sent it", r and r.who == "Kade_R" and r.by == "griefer", r and r.by)
    check("the words say so", r and L(ca).sourceText(r) == "from the log Vehicle, sent by griefer, not proved", r and L(ca).sourceText(r))
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
    check("as an admin note, with the line and its place", rec.notes.n == 1 and string.find(rec.notes[1].text, "mike_d took engine parts from", 1, true) ~= nil and string.find(rec.notes[1].text, "at 6283 x 5352", 1, true) ~= nil, rec.notes[1] and rec.notes[1].text)
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
    check("frozen: the line still reaches the file", logHas("vehicle | eparts | Hermit |"))
    local rows = rowsOf(a)
    check("frozen: reads work", rowWith(rows, "mute") ~= nil)
    -- frozen, the wheel: one line in the file, and no write to the table
    local kade = player("Kade_R", "user", 6283, 5352)
    local bob = player("Bob", "user", 6283, 5352)
    local w = car(6, 78)
    drive(w, kade)
    w.engine = true
    tick()
    leave(w, kade)
    drive(w, bob)
    tick()
    tick()
    local c = 0
    for _, l in ipairs(W.logs) do if string.find(l.line, "vehicle | drive | Bob | Kade_R |", 1, true) then c = c + 1 end end
    check("frozen: drove off once, with the owner", c == 1, c)
    check("frozen: the record isn't touched", (Srv().A.md.drivers or {})[78] == nil)
    leave(w, bob)
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
        { "spawned 10 x Bandage to Rosa", "admin", "spawn", "Rosa", "10 x Base.Bandage to Rosa" },
        { "spawned 2 x Bandage to themselves", "admin", "spawn", nil, "2 x Base.Bandage to me" },
        { "spawned 1 x Bandage on the ground", "admin", "spawn", nil, "1 x Base.Bandage to ground" },
        { "spawned 1 x Base.Gone to Rosa", "admin", "spawn", "Rosa", "1 x Base.Gone to Rosa" },
        { "turned on God Mode", "admin", "power on: GodMod" },
        { "turned off God Mode", "admin", "power off: GodMod" },
        { "turned on Invisible", "admin", "power on: Invisible" },
        { "added the role helper", "admin", "roles: add", "helper" },
        { "moved the role helper up", "admin", "roles: up", "helper" },
        { "tried a command they have no right to (a_ban)", "admin", "refused", nil, "has no right to a_ban" },
        { "went over the rate limit, 4 commands dropped so far", "admin", "rate limit", nil, "over the general limit, 4 dropped so far" },
        { "sent arguments no ZeD client sends (a_card)", "admin", "bad arguments", nil, "a_card" },
        { "server part up: protocol 1", "admin", "server part up", nil, "protocol 1" },
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
        ["player added to it"] = "added to #14 Griefing",
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

section("a car's owner")
do
    local a, ca = boot()
    local kade = player("Kade_R", "user", 6283, 5352)
    local bob = player("Bob", "user", 6283, 5352)
    local v = car(5, 77)
    local d3 = { kind = "vehicle", when = "d3" }
    drive(v, kade)
    v.engine = true
    tick()
    leave(v, kade)
    v.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    -- a turned key that starts nothing
    W.noStart = true
    drive(v, bob)
    perform(bob, "ISStartVehicleEngine")
    tick()
    local rows = rowsOf(a, d3)
    check("a failed start: no line", countBy(rows, "drive", "Bob") == 0, countBy(rows, "drive", "Bob"))
    check("and the owner stays", Srv().A.md.drivers[77].u == "Kade_R", Srv().A.md.drivers[77].u)
    leave(v, bob)
    W.noStart = nil
    perform(bob, "ISUninstallVehiclePart", part(v, "Battery", { item = 1 }))
    rows = rowsOf(a, d3)
    local r = rowWith(rows, "part")
    check("so the strip after it is a line, on the owner's car", r and r.who == "Bob" and r.target == "Kade_R", r and r.target)
    -- a theft: the thief strips it around the corner
    drive(v, bob)
    v.engine = true
    tick()
    leave(v, bob)
    v.engine = false
    rows = rowsOf(a, d3)
    r = rowWith(rows, "drive")
    check("driven off, naming the owner", countBy(rows, "drive", "Bob") == 1)
    perform(bob, "ISTakeEngineParts", part(v, "Engine", nil))
    perform(bob, "ISTakeGasolineFromVehicle", part(v, "GasTank", nil))
    rows = rowsOf(a, d3)
    r = rowWith(rows, "eparts")
    check("the thief's work still writes, with the owner's name", r and r.who == "Bob" and r.target == "Kade_R", r and r.target)
    check("the gas too", rowWith(rows, "siphon") ~= nil and rowWith(rows, "siphon").target == "Kade_R")
    -- the owner comes back in the settling time: no line accuses them
    drive(v, kade)
    v.engine = true
    tick()
    leave(v, kade)
    v.engine = false
    rows = rowsOf(a, d3)
    check("the owner takes it back: no drove off", countBy(rows, "drive", "Kade_R") == 1, countBy(rows, "drive", "Kade_R"))
    check("and it is theirs again at once", Srv().A.md.drivers[77].u == "Kade_R" and Srv().A.md.drivers[77].at == nil)
    perform(kade, "ISUninstallVehiclePart", part(v, "Muffler", { item = 1 }))
    rows = rowsOf(a, d3)
    check("their own work: no line", countBy(rows, "part", "Kade_R") == 0)
    -- a third party inside the settling time names the same owner
    drive(v, bob)
    v.engine = true
    tick()
    leave(v, bob)
    local rosa = player("Rosa", "user", 6283, 5352)
    drive(v, rosa)
    tick()
    leave(v, rosa)
    v.engine = false
    rows = rowsOf(a, d3)
    r = nil
    for _, x in ipairs(rows) do if x.what == "drive" and x.who == "Rosa" then r = x end end
    check("the next taker: the owner stays the one on record", r and r.target == "Kade_R", r and r.target)
    -- settled: it is the new driver's
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    local n = countBy(rowsOf(a, d3), "part", "Rosa")
    perform(rosa, "ISUninstallVehiclePart", part(v, "Hood", { item = 1 }))
    check("held for the settling time: their own", countBy(rowsOf(a, d3), "part", "Rosa") == n)
    -- a car on no record, taken for the first time
    local w = car(6, 88)
    drive(w, bob)
    w.engine = true
    tick()
    leave(w, bob)
    w.engine = false
    rows = rowsOf(a, d3)
    r = nil
    for _, x in ipairs(rows) do if x.what == "drive" and x.target == nil and x.who == "Bob" then r = x end end
    check("a car with no record, first taken: a line", r and L(ca).lineText(r) == "drove off in a Chevalier D6", r and r.who)
    local parts0 = Srv().A.md.world.n
    perform(bob, "ISUninstallVehiclePart", part(w, "Battery", { item = 1 }))
    check("their work on it writes, as a car with no owner", Srv().A.md.world.n == parts0 + 1)
    rows = rowsOf(a, d3)
    r = nil
    for _, x in ipairs(rows) do if x.what == "part" and x.who == "Bob" and x.target == nil then r = x end end
    check("not 'Bob's car' to Bob", r ~= nil)
    perform(kade, "ISSmashVehicleWindow", part(w, "WindowFrontLeft", nil))
    rows = rowsOf(a, d3)
    r = rowWith(rows, "smash")
    check("a stranger's work names that first driver", r and r.target == "Bob", r and r.target)
    -- scavenging stays in its own ring
    local logN = Srv().A.md.log.n
    Srv().action("admin", "Hermit", "mute", "x")
    local keep = Srv().A.md.log.at
    for i = 1, 1200 do
        W.clock = W.clock + 3000
        perform(rosa, "ISTakeEngineParts", part(car(2000 + i, 5000 + i), "Engine", nil))
    end
    check("work on cars with no owner stays off the one ring", Srv().A.md.log.n <= logN + 2 and Srv().A.md.log.at == keep, Srv().A.md.log.n)
    check("its ring is capped", Srv().A.md.world.n == Lg_L().VEH_MAX, Srv().A.md.world.n)
    check("and the file has them all", (function()
        local c = 0
        for _, l in ipairs(W.logs) do if string.find(l.line, "vehicle | eparts | Rosa | - |", 1, true) then c = c + 1 end end
        return c
    end)() == 1200)
    rows = rowsOf(a, { kind = "vehicle", when = "hour" })
    check("the Vehicle chip reads them", rowWith(rows, "eparts") ~= nil)
end

section("the pace on vehicle lines")
do
    local a = boot()
    local kade = player("Kade_R", "user", 6283, 5352)
    local bob = player("Bob", "user", 6283, 5352)
    local v = car(5, 77)
    drive(v, kade)
    v.engine = true
    tick()
    leave(v, kade)
    v.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    for i = 1, 40 do perform(bob, "ISTakeEngineParts", part(v, "Engine", nil)) end
    -- the wheel changes hands past the pace: that line is never dropped
    drive(v, bob)
    v.engine = true
    tick()
    leave(v, bob)
    v.engine = false
    local rows = rowsOf(a, { kind = "vehicle", when = "d3" })
    check("a drove off past the pace still writes", countBy(rows, "drive", "Bob") == 1, countBy(rows, "drive", "Bob"))
    tick(61)
    rows = rowsOf(a, { kind = "vehicle", when = "d3" })
    local r = rowWith(rows, "dropped")
    check("the lines over the pace are said", r and r.who == "Bob" and r.text == "10", r and r.text)
    check("in words", WORDS and L(select(2, boot())).lineText({ k = "vehicle", what = "dropped", text = "10" }) == "had 10 more vehicle lines not kept, over the limit for one minute")
end

section("a tow")
do
    local a, ca = boot()
    local kade = player("Kade_R", "user", 6283, 5352)
    local mike = player("mike_d", "user", 6283, 5352)
    local truck = car(5, 77)
    local victim = car(6, 78)
    truck.x, truck.y, victim.x, victim.y = 6281, 5350, 6285, 5354
    drive(truck, mike)
    truck.engine = true
    tick()
    leave(truck, mike)
    truck.engine = false
    drive(victim, kade)
    victim.engine = true
    tick()
    leave(victim, kade)
    victim.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    -- the game's own command, then the game's own listener
    local function tow(p, args, formed)
        local aa = wire(args)
        net(function()
            W.server.Events.OnClientCommand.fire("vehicle", "attachTrailer", p, aa)
            local x, y = W.cars[args.vehicleA], W.cars[args.vehicleB]
            if formed ~= false and x and y then y.towedBy = x end
        end)
        drain()
    end
    local d3 = { kind = "vehicle", when = "d3" }
    tow(mike, { vehicleA = 5, vehicleB = 6 })
    check("no line yet: it may be cancelled", countWhat(rowsOf(a, d3), "tow") == 0)
    tick()
    tick()
    local r = rowWith(rowsOf(a, d3), "tow")
    check("once it took: a line, on the other's car", r and r.who == "mike_d" and r.target == "Kade_R", r and r.target)
    victim.towedBy = nil
    W.clock = W.clock + 301000
    -- the menu can put the victim's car in either slot
    tow(mike, { vehicleA = 6, vehicleB = 5 })
    tick()
    tick()
    local rows = rowsOf(a, d3)
    check("either slot: the same line", countBy(rows, "tow", "mike_d") == 2, countBy(rows, "tow", "mike_d"))
    check("naming the other's car", rows[1].what == "tow" and rows[1].target == "Kade_R", rows[1].target)
    truck.towedBy = nil
    -- a cancelled hookup
    W.clock = W.clock + 301000
    tow(mike, { vehicleA = 5, vehicleB = 6 })
    victim.towedBy = nil
    tick()
    tick()
    check("cancelled before the look: no line", countBy(rowsOf(a, d3), "tow", "mike_d") == 2)
    -- no tow formed, and a car out of reach
    W.clock = W.clock + 61000
    tow(mike, { vehicleA = 5, vehicleB = 6 }, false)
    tick()
    tick()
    check("no tow formed: no line", countBy(rowsOf(a, d3), "tow", "mike_d") == 2)
    W.clock = W.clock + 301000
    victim.x = 7000
    tow(mike, { vehicleA = 5, vehicleB = 6 })
    tick()
    tick()
    check("a car out of reach: no line", countBy(rowsOf(a, d3), "tow", "mike_d") == 2)
    victim.x, victim.towedBy = 6285, nil
    -- one line per pair
    W.clock = W.clock + 61000
    for _ = 1, 3 do
        tow(mike, { vehicleA = 5, vehicleB = 6 })
        tick()
        tick()
    end
    check("the same pair again: one line", countBy(rowsOf(a, d3), "tow", "mike_d") == 3, countBy(rowsOf(a, d3), "tow", "mike_d"))
    -- a flood can't take the other lines' budget or fill anything
    W.clock = W.clock + 301000
    local logN = Srv().A.md.log.n
    for i = 1, 40 do tow(mike, { vehicleA = 5, vehicleB = 6 }) end
    check("a flood of commands waits on a small list", #Srv().L.tows <= Lg_L().TOW_PER_MIN, #Srv().L.tows)
    for i = 1, 30 do perform(mike, "ISTakeEngineParts", part(victim, "Engine", nil)) end
    rows = rowsOf(a, { kind = "vehicle", when = "hour" })
    local n = 0
    for _, l in ipairs(Srv().A.md.log) do if l.what == "eparts" and l.who == "mike_d" then n = n + 1 end end
    check("and costs the real lines nothing", n == 30, n)
    -- hostile
    for _, args in ipairs({ { vehicleA = 1, vehicleB = 1.5 }, { vehicleA = "x", vehicleB = {} }, { vehicleB = 5 }, { vehicleA = 1, vehicleB = 99 } }) do tow(mike, args) end
    net(function() W.server.Events.OnClientCommand.fire("vehicle", "attachTrailer", mike, nil) end)
    drain()
    check("hostile tows: no slip", not logHas("log hook failed"))
    -- a kill stays through a run of lesser lines
    local world2 = boot()
    local k = player("griefer", "user")
    Srv().action("pvp", "griefer", "kill", "Rosa", nil, 1, 2, 0)
    for i = 1, 500 do Srv().action("admin", "griefer", "bad arguments", nil, "x") end
    local found = false
    for i = 1, Srv().A.md.log.n do
        local l = Srv().A.md.log[i]
        if l and l.what == "kill" then found = true end
    end
    check("an account's own lines can't write its kill off the ring", found)
end

section("a siphon stopped early")
do
    local a = boot()
    local mike = player("mike_d", "user", 6283, 5352)
    local v = car(5, 77)
    local tank = part(v, "GasTank", nil)
    tank.amount = 40
    check("the wrap is on the class", W.server.ISTakeGasolineFromVehicle.serverStop ~= nil)
    local act = W.server.ISTakeGasolineFromVehicle.new(W.server.ISTakeGasolineFromVehicle, mike, tank)
    act.tankStart = 40
    tank.amount = 12                -- (the action's update ran on the server, and took this much)
    cancel(act)
    local rows = rowsOf(a, { kind = "vehicle" })
    check("fuel left: a line", countWhat(rows, "siphon") == 1, countWhat(rows, "siphon"))
    local act2 = W.server.ISTakeGasolineFromVehicle.new(W.server.ISTakeGasolineFromVehicle, mike, tank)
    act2.tankStart = 12
    cancel(act2)
    rows = rowsOf(a, { kind = "vehicle" })
    check("stopped at once: none", countWhat(rows, "siphon") == 1)
    check("the game's own serverStop still runs", W.gasStops == 2, W.gasStops)
    local S0 = W.server.ISTakeGasolineFromVehicle
    local act4 = S0.new(S0, mike, tank)
    act4.tankStart = 40
    S0.complete(act4)
    cancel(act4)
    rows = rowsOf(a, { kind = "vehicle" })
    check("a finished one the game then stops: one line", countWhat(rows, "siphon") == 2, countWhat(rows, "siphon"))
    local act3 = W.server.ISTakeGasolineFromVehicle.new(W.server.ISTakeGasolineFromVehicle, mike, tank)
    check("a cancel with no fuel field does no harm", pcall(cancel, act3) and not logHas("log hook failed"))
end

section("the fallback waits for a real miss")
do
    local a = boot()
    local k = player("mike_d", "user")
    local v = car(5, 77)
    local S = W.server
    -- three cancels prove the road: the fallback stays off
    for i = 1, 3 do
        W.clock = W.clock + 60000
        cancel(S.ISUninstallVehiclePart.new(S.ISUninstallVehiclePart, k, part(v, "Battery", { item = 1 })))
    end
    W.clock = W.clock + 200000
    perform(k, "ISUninstallVehiclePart", part(v, "Hood", { item = 1 }))
    check("cancels don't turn it on", Srv().L.P.hooks.ISUninstallVehiclePart.fallback == nil)
    check("and the probe says the class", logHas("vehicle hook reached | @server | ISUninstallVehiclePart | - | by the class"))
    -- actions under way have reached nothing yet
    world()
    local k2 = player("mike_d", "user")
    local v2 = car(5, 77)
    S = W.server
    for i = 1, 5 do S.ISTakeEngineParts.new(S.ISTakeEngineParts, k2, part(v2, "Engine", nil)) end
    check("a few under way, no time gone: off", Srv().L.P.hooks.ISTakeEngineParts.fallback == nil)
    -- on: a later mod's wrap and a subclass stay in the chain
    world({ classMiss = true, raw = {} })
    for name, shape in pairs(ACTIONS) do W.raw[name] = shape.complete end
    local k3 = player("mike_d", "user")
    local v3 = car(5, 77)
    S = W.server
    local h = Srv().L.P.hooks.ISTakeEngineParts
    h.fallback = true
    local C = S.ISTakeEngineParts
    local sub = setmetatable({}, { __index = C })
    sub.__index = sub
    local o1 = C.new(sub, k3, part(v3, "Engine", nil))
    check("a subclass keeps its own road", rawget(o1, "complete") == nil)
    local ran = 0
    local ours = C.complete
    C.complete = function(self)
        ran = ran + 1
        return ours(self)
    end
    local o2 = C.new(C, k3, part(v3, "Engine", nil))
    check("a mod's later wrap isn't shadowed", rawget(o2, "complete") == nil)
    C.complete = ours
    local o3 = C.new(C, k3, part(v3, "Engine", nil))
    check("the class's own action, with ZeD's wrap still on: it carries it", rawget(o3, "complete") == ours)
end

section("what a tapped line can't carry")
do
    local a, ca = boot()
    local m = player("Rosa", "moderator", 10650, 9970)
    local up = player("TopDog", "admin", 6280, 5350)
    local u = player("griefer", "user", 100, 200)
    local function client(p, logger, text)
        local aa = wire({ loggerName = logger, logText = text })
        net(function() W.server.ISLogSystem.writeLog(p, aa) end)
        drain()
    end
    -- a line of brackets costs its length, no more
    for _, text in ipairs({ string.rep("[", 32000), string.rep("[]", 16000), string.rep("[1,1,1", 5000) }) do
        W.clock = W.clock + 61000
        local t0 = os.clock()
        client(u, "Slow", text)
        check("a hostile line reads in no time", os.clock() - t0 < 0.05, os.clock() - t0)
    end
    W.logs = {}
    -- the game's own chatter
    W.clock = W.clock + 61000
    local n0 = Srv().A.md.tap.n
    client(u, "ClientActionLog", "[76561198000000003][ISEnterVehicle][griefer][6280,5350,0][Base.CarNormal]")
    client(u, "PerkLog", "[76561198000000003][griefer][6280,5350,0][Login][Hours Survived: 0]")
    check("the game's chatter stays out of the Log", Srv().A.md.tap.n == n0, Srv().A.md.tap.n)
    check("and stays in the game's files", #W.logs == 2, #W.logs)
    -- a Steam ID: no field of it reaches a reader
    W.clock = W.clock + 61000
    client(u, "LogExtender", "[76561198000000003][griefer][6280,5350,0][Login]")
    client(u, "LogExtender", "[76561198000000003] said hello")
    local rows = rowsOf(m, { when = "hour" })
    for _, r in ipairs(rows) do
        for k, v in pairs(r) do check("no Steam ID in a row: " .. tostring(k), not string.find(tostring(v), "7656119", 1, true), tostring(v)) end
    end
    rows = rowsOf(m, { when = "hour", find = "7656119" })
    check("Find can't reach one", #rows == 0, #rows)
    -- a higher role's place, on a tapped line
    W.clock = W.clock + 61000
    client(u, "LogExtender", "[1][ISEnterVehicle][TopDog][6280,5350,0][Base.CarNormal]")
    rows = rowsOf(m, { when = "hour" })
    local r = rowWith(rows, "ISEnterVehicle")
    check("a higher role's tapped line reads", r ~= nil)
    check("with no place", r and r.x == nil and r.hid == true, r and r.x)
    check("and none in its words", r and not string.find(tostring(r.text), "6280", 1, true), r and r.text)
    check("Find can't reach it", #(rowsOf(m, { when = "hour", find = "6280,5350" })) == 0)
    rows = rowsOf(up, { when = "hour", find = "ISEnterVehicle" })
    check("the role itself reads the place", rows[1] and rows[1].x == 6280, rows[1] and rows[1].x)
    local kade = player("Kade_R", "user", 6280, 5350)
    local id = file(kade)
    again(m)
    rows = rowsOf(m, { when = "hour", find = "ISEnterVehicle" })
    again(m)
    ask(m, { rid = 1, id = id, s = rows[1].s }, "l_tonote")
    local rec = W.server.ZeD.Srv.T.md.tickets[id]
    check("nor in a note", rec.notes.n == 1 and not string.find(rec.notes[1].text, "6280", 1, true), rec.notes[1] and rec.notes[1].text)
    check("the note keeps who really sent it", string.find(rec.notes[1].text, "from the log LogExtender, sent by griefer, not proved", 1, true) ~= nil, rec.notes[1] and rec.notes[1].text)
    -- a place past the map
    W.clock = W.clock + 61000
    client(u, "LogExtender", "[1][ISThing][griefer][99999999,3,0]")
    client(u, "LogExtender", "[1][ISThing2][griefer][" .. string.rep("9", 400) .. ",3,0]")
    rows = rowsOf(a, { when = "hour" })
    check("a place off the map is no place", rowWith(rows, "ISThing") and rowWith(rows, "ISThing").x == nil)
    -- the Who list: forged names can't push real ones off
    W.clock = W.clock + 61000
    for i = 1, 20 do client(u, "LogExtender", string.format("[1][T][!%03d][1,1,0]", i)) end
    local _, pg = rowsOf(a, { when = "hour" })
    check("no forged name on the list", not has(pg.names, "!001"))
    check("the sender is", has(pg.names, "griefer"))
    rows = rowsOf(a, { when = "hour", who = "griefer", find = "!001" })
    check("Who finds what they sent", #rows == 1, #rows)
end

section("the server's own lines")
do
    local a, ca = boot()
    local fake = player("server", "user", 700, 800)
    local kade = player("Kade_R", "user", 700, 800)
    local v = car(5, 77)
    perform(fake, "ISTakeEngineParts", part(v, "Engine", nil))
    kade.x, kade.y = 5, 5
    local _, pg = rowsOf(a, {})
    check("an account called server is on the Who list", has(pg.names, "server"), table.concat(pg.names, ","))
    check("the server's own mark isn't", not has(pg.names, "@server"))
    Srv().action("admin", W.server.ZeD.Tk.SYS, "ban lifted", "x", "the time ran out")
    local rows = rowsOf(a, { kind = "admin" })
    local r = rowWith(rows, "ban lifted")
    check("a server line reads as the server's", L(ca).whoText(r) == "Server:", L(ca).whoText(r))
    r = rowWith(rowsOf(a, { kind = "vehicle" }), "eparts")
    check("a player so named reads as themselves", L(ca).whoText(r) == "server")
    -- the QA lines stay in the file
    check("the hook's line is in the file", logHas("vehicle hook reached"))
    check("and not on staff's chip", rowWith(rowsOf(a, { kind = "admin" }), "vehicle hook reached") == nil)
end

section("IP addresses and Steam IDs on ban lines")
do
    local a, ca = boot()
    ROLES.helper = role("helper", 2, all({ "AnswerTickets" }))
    local h = player("Helper", "helper", 10, 10)
    local S0 = Srv()
    S0.action("admin", "Hermit", "ban", "203.0.113.7", "permanent: spam", 1, 2, 0)
    S0.action("admin", "Hermit", "ban", "76561198000000001", "d3: spam", 1, 2, 0)
    S0.action("admin", "Hermit", "unban", "203.0.113.7", nil, 1, 2, 0)
    S0.action("admin", "Hermit", "game ban", "76561198000000001", "reason", 1, 2, 0)
    S0.action("admin", W.server.ZeD.Tk.SYS, "ban lifted", "76561198000000001", "the time ran out")
    S0.action("admin", "Hermit", "ban", "lootdrop99", "permanent: scam", 1, 2, 0)
    local rows = rowsOf(h, { kind = "admin" })
    for _, r in ipairs(rows) do
        check("no address in a row", not string.find(tostring(r.target), "203.0", 1, true) and not string.find(tostring(r.target), "7656", 1, true), r.target)
    end
    local named = nil
    for _, r in ipairs(rows) do if r.target == "lootdrop99" then named = r end end
    check("a username stays", named ~= nil)
    local r = nil
    for _, x in ipairs(rows) do if x.what == "ban" and x.target == nil and x.text == "d3: spam" then r = x end end
    check("the words stand in for it", r and L(ca).lineText(r) == 'banned a hidden address (3 days): "spam"', r and L(ca).lineText(r))
    check("Find can't reach it", #(rowsOf(h, { find = "203.0.113" })) == 0)
    check("Who can't either", #(rowsOf(h, { who = "203.0.113.7" })) == 0)
    rows = rowsOf(a, { find = "203.0.113" })
    check("a reader with BanUnbanUser sees it", #rows == 2 and rows[1].target == "203.0.113.7", #rows)
    check("and no card is offered on an address", L(ca).otherName(rows[1]) == nil)
    check("nor on a Steam ID", L(ca).otherName({ k = "admin", what = "unban", target = "76561198000000001" }) == nil)
    check("a name still has one", L(ca).otherName({ k = "admin", what = "ban", target = "lootdrop99" }) == "lootdrop99")
    -- a note from a helper
    local k = player("Kade_R", "user")
    local id = file(k)
    local line
    for i = 1, S0.A.md.log.n do
        local l = S0.A.md.log[i]
        if l and l.target == "203.0.113.7" then line = l end
    end
    again(h)
    ask(h, { rid = 1, id = id, s = line.s }, "l_tonote")
    local rec = W.server.ZeD.Srv.T.md.tickets[id]
    check("a note holds no address", rec.notes.n == 1 and not string.find(rec.notes[1].text, "203.0", 1, true), rec.notes[1] and rec.notes[1].text)
    check("the file keeps it", logHas("admin | ban | Hermit | 203.0.113.7 |"))
end

section("a higher role in a fight")
do
    local a = boot()
    local m = player("Rosa", "moderator", 10, 10)
    Srv().action("pvp", "Griefer", "kill", "Hermit", nil, 777, 888, 0)
    local rows = rowsOf(m, { kind = "pvp" })
    check("the victim's place stays out", rows[1] and rows[1].x == nil and rows[1].hid == true, rows[1] and rows[1].x)
    rows = rowsOf(a, { kind = "pvp" })
    check("an admin reads it", rows[1] and rows[1].x == 777)
end

section("Find reads what the card shows")
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
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    perform(mike, "ISSmashVehicleWindow", part(v, "WindowFrontLeft", nil))
    Srv().action("admin", "Hermit", "ban", "lootdrop99", "permanent: Scam spam", 1, 2, 0)
    Srv().action("faction", "Rosa", "member in", "Riverside Farmers")
    for _, w in ipairs({ "smashed", "Chevalier", "window of Kade_R's", "banned", "joined" }) do
        check("Find: " .. w, #(rowsOf(a, { find = w })) >= 1, w)
    end
    check("what isn't there isn't found", #(rowsOf(a, { find = "nothing like this" })) == 0)
    Srv().action("ticket", "Rosa", "filed", "#9", "GRIEF")
    check("a ticket's kind as the card says it", #(rowsOf(a, { find = "griefing" })) == 1)
    check("the server's words are the EN file's", (function()
        for k, v2 in pairs(W.server.ZeD.Lg.EN) do
            if WORDS[k] ~= v2 then return false, k end
        end
        return true
    end)())
    -- a client in another language: its words come as codes
    local Lg0 = ca.env.ZeD.Lg
    local codes = Lg0.findCodes("zerschlug", function(k) return (k == "UI_ZeD_Log_V_Smash") and "zerschlug ein Fenster" or "x" end)
    check("the viewer's words give the codes", codes and #codes == 1 and codes[1] == "smash", codes and codes[1])
    check("no words, no codes", Lg0.findCodes("qqqq", function() return "x" end) == nil)
    local rows = rowsOf(a, { find = "zerschlug", codes = codes })
    check("the server takes them", #rows == 1 and rows[1].what == "smash", #rows)
    check("only with a Find", #(rowsOf(a, { codes = { "smash" }, kind = "faction" })) == 1)
    for i, bad in ipairs({ "smash", { 1 }, { {} }, { string.rep("x", 99) } }) do
        again(a)
        ask(a, { rid = 70 + i, find = "x", codes = bad })
        local ack = got(a, "t_ack")
        check("a bad list " .. i .. " refused", ack ~= nil and ack.ok == false, tostring(ack and ack.err))
    end
    local many = {}
    for i = 1, 40 do many[i] = "c" .. i end
    again(a)
    ask(a, { rid = 80, find = "x", codes = many })
    check("too many refused", got(a, "t_ack") ~= nil and got(a, "t_ack").ok == false)
end

section("a note says what the card says")
do
    local a = boot()
    local kade = player("Kade_R", "user", 6283, 5352)
    local mike = player("mike_d", "user", 6283, 5352)
    local v = car(5, 77)
    drive(v, kade)
    v.engine = true
    tick()
    leave(v, kade)
    v.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    perform(mike, "ISUninstallVehiclePart", part(v, "Battery", { item = 1 }))
    local id = file(kade)
    local r = rowWith(rowsOf(a, { kind = "vehicle" }), "part")
    again(a)
    ask(a, { rid = 1, id = id, s = r.s }, "l_tonote")
    local rec = W.server.ZeD.Srv.T.md.tickets[id]
    local text = rec.notes[1].text
    check("the line's own words", string.find(text, "mike_d removed the Battery from Kade_R's Chevalier D6, at 6283 x 5352", 1, true) ~= nil, text)
    check("nothing twice", not string.find(text, "CarNormal/Battery", 1, true), text)
end

section("who Around names")
do
    local a = boot()
    local m = player("ModAnn", "moderator", 9000, 9000)
    local kade = player("Kade_R", "user", 6280, 5350)
    local rosa = player("Rosa", "user", 6280, 5350)
    local one = file(kade)
    tk(m, "t_seen", { id = one })
    nolimit(m)
    tk(m, "t_note", { id = one, text = "on it" })
    W.clock = W.clock + 3600 * 1000
    local two = file(rosa)
    Srv().action("safehouse", "Aretha", "member out", nil, nil, 6280, 5350)
    local _, p1 = rowsOf(a, { around = two })
    for _, e in ipairs(p1.around.missed) do
        check("a ticket's or a safehouse's line says nothing of who stood there: " .. e.who, e.who ~= "ModAnn" and e.who ~= "Aretha", e.who)
    end
end

section("a game row taken in")
do
    local a, ca = boot()
    local S0 = Srv()
    S0.action("ticket", W.server.ZeD.Tk.SYS, "adopted from the game's window", "#31", "GRIEF: Alice")
    local _, pg = rowsOf(a, {})
    local r = rowWith(pg.rows, "adopted from the game's window")
    check("the server's line", r and r.who == W.server.ZeD.Tk.SYS, r and r.who)
    check("it says not proved", L(ca).lineText(r) == "took in #31 GRIEF from the game's window, filed in the name of Alice, not proved", L(ca).lineText(r))
    check("not on the claimed name's list", not has(pg.names, "Alice"))
end

section("the Container chip")
do
    local a = boot()
    local Lg0 = W.server.ZeD.Lg
    local _, pg = rowsOf(a, {})
    check("no server extras, no chip", pg.opt == nil)
    check("the old switch is gone", Lg0.CONTAINER_LOG == nil and Lg0.containerOn == nil)
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

-- ---------------------------------------------------------------------------
-- PHASE 4 AND PHASE 6 TOGETHER: the real ZeD_ServerExtras beside the real ZeD_ServerLog, on the same classes
-- ---------------------------------------------------------------------------
local HERE_X, HERE_Y = 6283, 5352
local d3 = { kind = "vehicle", when = "d3" }

local function xsay(p, command, args)
    p.box = {}
    nolimit(p)
    local a = wire(args or {})
    net(function() W.server.Events.OnClientCommand.fire("ZeDX", command, p, a) end)
    drain()
end
-- the owner's card: fn changes the set, and the save says what it was made on
local function extras(a, fn)
    local Ex = W.server.ZeD.Ex
    local was = Ex.clean(Srv().X.set)
    local set = Ex.clean(was)
    fn(set)
    W.clock = W.clock + 2000
    xsay(a, "x_save", { set = set, was = was })
    local r = got(a, "t_ack")
    check("the extras saved", r and r.ok == true, r and r.err)
end
local function claimsOn(a, tow)
    extras(a, function(s) s.vc.on, s.vc.tow = true, tow == true end)
end
local function claim(p, v)
    xsay(p, "x_claim", { veh = v.id })
    local r = got(p, "t_ack")
    check(p.name .. " claims the car", r and r.ok == true, r and r.err)
end
local function bomb()
    return setmetatable({}, { __index = function(_, k) error("touched: " .. tostring(k)) end })
end
local function hook(name) return Srv().L.P.hooks[name] end

section("together, every extra off")
do
    local a = boot({ extras = true })
    local S = W.server
    local logWrap = S.ISUninstallVehiclePart.complete
    check("the extras wrapped nothing", next(Srv().exWrapped) == nil and next(Srv().exTop) == nil)
    check("no listener, no clock, no swing watch", not (Srv().exWatchHooked or Srv().exClockHooked or Srv().exHitHooked))
    check("whose car: no claim is read, no car touched", Srv().exOwner(bomb()) == nil)
    check("what a claim stops: nothing, no car touched", Srv().exDriveStops(bomb(), bomb()) == false and Srv().exTowStops(bomb(), bomb(), bomb()) == false)
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    drive(v, kade)
    v.engine = true
    tick()
    leave(v, kade)
    v.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    check("the Log runs as it does alone", perform(mike, "ISUninstallVehiclePart", part(v, "Battery", { item = 1 })) == true)
    local r = rowWith(rowsOf(a, d3), "part")
    check("and names the last driver", r and r.who == "mike_d" and r.target == "Kade_R", r and r.target)
    check("a save with all off wraps nothing either", (function()
        extras(a, function() end)
        return next(Srv().exWrapped) == nil and S.ISUninstallVehiclePart.complete == logWrap
    end)())
    local _, pg = rowsOf(a, {})
    check("the chip is off", pg.opt == nil)
end

section("together: a refused action logs as refused, once")
do
    local a, ca = boot({ extras = true })
    local S = W.server
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    claimsOn(a)
    check("the extras' wrap is outside the Log's", S.ISUninstallVehiclePart.complete == Srv().exTop["ISUninstallVehiclePart.complete"])
    claim(kade, v)
    local battery = part(v, "Battery", { item = 1 })
    check("refused: the game's answer is false", perform(mike, "ISUninstallVehiclePart", battery) == false)
    check("and the part stays", battery.item ~= nil)
    local rows = rowsOf(a, d3)
    check("no line says it came off", countWhat(rows, "part") == 0, countWhat(rows, "part"))
    check("one line says refused", countBy(rows, "refused: parts", "mike_d") == 1)
    local r = rowWith(rows, "refused: parts")
    check("naming the claimer", r and r.target == "Kade_R" and r.k == "vehicle", r and r.target)
    check("in words", L(ca).lineText(r) == "was refused taking parts from Kade_R's Chevalier D6", L(ca).lineText(r))
    check("the road is proved, not missed", hook("ISUninstallVehiclePart").ref == 1 and hook("ISUninstallVehiclePart").done == 0)
    check("the file says the same", logHas("vehicle | refused: parts | mike_d | Kade_R | 6283,5352"))
    -- refused again and again: nothing says the road was missed
    for i = 1, 6 do
        W.clock = W.clock + 60000
        perform(mike, "ISUninstallVehiclePart", part(v, "Hood", { item = 1 }))
    end
    check("refusals don't turn the fallback on", hook("ISUninstallVehiclePart").fallback == nil)
    check("nor is any line a hook failure", not logHas("log hook failed"))
    -- the rest of the vehicle actions the claim stops
    W.clock = W.clock + 10000
    check("engine parts refused", perform(mike, "ISTakeEngineParts", part(v, "Engine", nil)) == false)
    rows = rowsOf(a, d3)
    check("no engine parts line", countWhat(rows, "eparts") == 0)
    -- the claimer's own work writes nothing, and goes through
    check("the claimer's own action runs", perform(kade, "ISUninstallVehiclePart", part(v, "Radio", { item = 1 })) == true)
    rows = rowsOf(a, d3)
    check("and writes no line: a claimed car is theirs", countBy(rows, "part", "Kade_R") == 0)
    -- staff pass a claim, and the line names the claimer
    W.clock = W.clock + 10000
    local before = countWhat(rowsOf(a, d3), "refused: parts")
    check("staff pass", perform(a, "ISTakeEngineParts", part(v, "Engine", nil)) == true)
    rows = rowsOf(a, d3)
    r = rowWith(rows, "eparts")
    check("one line, the claimer's car", countBy(rows, "eparts", "Hermit") == 1 and r.target == "Kade_R", r and r.target)
    check("no refusal for them", countWhat(rows, "refused: parts") == before)
end

section("together: a claimed car's owner is the claimer")
do
    local a, ca = boot({ extras = true })
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local rosa = player("Rosa", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    -- Mike drives it for days, so the record calls it his. Kade claims it
    drive(v, mike)
    v.engine = true
    tick()
    leave(v, mike)
    v.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    claimsOn(a)
    claim(kade, v)
    perform(rosa, "ISSmashVehicleWindow", part(v, "Window", nil))
    local rows = rowsOf(a, d3)
    local r = rowWith(rows, "smash")
    check("a window, which no claim stops: the line names the claimer", r and r.target == "Kade_R", r and r.target)
    check("the record is untouched", Srv().A.md.drivers[77].u == "mike_d")
    check("a claim in words", L(ca).lineText(rowWith(rows, "claim")) == "claimed a Chevalier D6", L(ca).lineText(rowWith(rows, "claim")))
    -- the claimer takes the wheel: no "drove off", a settled car of their own
    drive(v, kade)
    v.engine = true
    tick()
    leave(v, kade)
    v.engine = false
    rows = rowsOf(a, d3)
    check("the claimer driving is no theft", countBy(rows, "drive", "Kade_R") == 0)
    check("and the record follows them", Srv().A.md.drivers[77].u == "Kade_R")
    -- a release: the car is on the record again
    xsay(kade, "x_release", { key = W.server.ZeD.Ex.keyOf(77) })
    check("released", got(kade, "t_ack").ok == true)
    W.clock = W.clock + 10000
    perform(rosa, "ISSmashVehicleWindow", part(v, "Window", nil))
    rows = rowsOf(a, d3)
    check("a release in words", L(ca).lineText(rowWith(rows, "release")) == "released a Chevalier D6", L(ca).lineText(rowWith(rows, "release")))
    -- a release by staff names whose it was
    claim(kade, v)
    xsay(a, "x_release", { key = W.server.ZeD.Ex.keyOf(77) })
    rows = rowsOf(a, d3)
    local rel = nil
    for _, x in ipairs(rows) do if x.what == "release" and x.who == "Hermit" then rel = x end end
    check("staff's release names the owner", rel and L(ca).lineText(rel) == "released Kade_R's Chevalier D6", rel and L(ca).lineText(rel))
    -- parts off, claims on: nothing is refused, and the owner is still the claimer
    claim(kade, v)
    extras(a, function(s) s.vc.parts = false end)
    W.clock = W.clock + 10000
    check("with parts off it runs", perform(rosa, "ISTakeEngineParts", part(v, "Engine", nil)) == true)
    r = rowWith(rowsOf(a, d3), "eparts")
    check("and the line still names the claimer", r and r.who == "Rosa" and r.target == "Kade_R", r and r.target)
    -- a burnt car: the claim goes as the wreck is stripped, and a wreck is nobody's
    v.burnt = true
    W.clock = W.clock + 10000
    perform(rosa, "ISRemoveBurntVehicle", v)
    rows = rowsOf(a, d3)
    check("one line for the claim", countBy(rows, "claim gone: burnt", "Kade_R") == 1, countBy(rows, "claim gone: burnt", "Kade_R"))
    r = rowWith(rows, "strip")
    check("one for the strip, on the record's word now the claim is gone", countBy(rows, "strip", "Rosa") == 1 and r.target == Srv().A.md.drivers[77].u, r and r.target)
    -- claims off: the claim sleeps and the record answers again, with no car touched by the extras
    extras(a, function(s) s.vc.on = false end)
    check("claims off: no owner from a claim", Srv().exOwner(bomb()) == nil)
end

section("together: starting, hotwiring and the look at who is driving")
do
    local a, ca = boot({ extras = true })
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    claimsOn(a)
    claim(kade, v)
    drive(v, mike)
    check("a start refused", perform(mike, "ISStartVehicleEngine") == false and v.engine ~= true)
    W.clock = W.clock + 6000
    v.wired = nil
    check("a hotwire refused", perform(mike, "ISHotwireVehicle") == false and v.wired == nil)
    local rows = rowsOf(a, d3)
    check("neither is a Log line", countWhat(rows, "hotwire") == 0 and countWhat(rows, "drive") == 0)
    check("each is a refusal", countWhat(rows, "refused: drive") == 2, countWhat(rows, "refused: drive"))
    -- in the seat with the engine running, past the refused start: the 2 second clock shuts it off, and the Log's look says nothing
    v.engine = true
    W.server.ZeD.Srv.L.at = nil
    W.server.ZeD.Srv.L.driverSeen(Srv().A.md, mike, v)
    check("a blocked driver moves no record", Srv().A.md.drivers[77] == nil)
    tick()
    check("the clock shut it off", v.engine == false and (v.shut or 0) >= 1, v.shut)
    rows = rowsOf(a, d3)
    check("no 'drove off' for a driver a claim stops", countBy(rows, "drive", "mike_d") == 0)
    check("the record stays empty", Srv().A.md.drivers[77] == nil)
    leave(v, mike)
    -- drive off, claims on: nothing shuts it, and the line names the claimer
    extras(a, function(s) s.vc.drive = false end)
    drive(v, mike)
    v.engine = true
    tick()
    tick()
    rows = rowsOf(a, d3)
    check("a drive the claim lets by: one line", countBy(rows, "drive", "mike_d") == 1, countBy(rows, "drive", "mike_d"))
    check("on the claimer's car", rowWith(rows, "drive").target == "Kade_R")
    check("and in words", L(ca).lineText(rowWith(rows, "drive")) == "drove off in Kade_R's Chevalier D6", L(ca).lineText(rowWith(rows, "drive")))
end

section("together: siphoning")
do
    local a = boot({ extras = true })
    local S = W.server
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    claimsOn(a)
    claim(kade, v)
    local tank = part(v, "GasTank", nil)
    tank.amount = 40
    local C = S.ISTakeGasolineFromVehicle
    local act = C.new(C, mike, tank)
    act.tankStart = 40
    for i = 1, 5 do act:animEvent("update") end
    check("no gas moves", tank.amount == 40, tank.amount)
    check("complete refuses", act:complete() == false)
    cancel(act)
    local rows = rowsOf(a, d3)
    check("no 'siphoned' line", countWhat(rows, "siphon") == 0, countWhat(rows, "siphon"))
    check("one refusal for the whole action", countWhat(rows, "refused: parts") == 1, countWhat(rows, "refused: parts"))
    check("the game's serverStop still runs", W.gasStops == 1, W.gasStops)
    -- a claim landing part way: what had moved really moved, and the line says so, beside the refusal
    local bob = player("Bob", "user", HERE_X, HERE_Y)
    local v2 = car(6, 78)
    local tank2 = part(v2, "GasTank", nil)
    tank2.amount = 40
    local act2 = C.new(C, bob, tank2)
    act2.tankStart = 40
    act2:animEvent("update")
    act2:animEvent("update")
    claim(kade, v2)
    W.clock = W.clock + 6000
    act2:animEvent("update")
    check("the claim stops the rest", tank2.amount == 38, tank2.amount)
    act2:complete()
    cancel(act2)
    rows = rowsOf(a, d3)
    check("gas that moved is a line, on the claimer's car", countBy(rows, "siphon", "Bob") == 1 and rowWith(rows, "siphon").target == "Kade_R", countBy(rows, "siphon", "Bob"))
    check("and so is the refusal", countBy(rows, "refused: parts", "Bob") == 1)
    -- the claimer's own siphon: the wrap is on, the gas moves, nothing is said
    local act3 = C.new(C, kade, tank)
    act3.tankStart = 40
    act3:animEvent("update")
    check("the claimer's gas moves", tank.amount == 39, tank.amount)
    check("the claimer's complete passes", act3:complete() == true)
    rows = rowsOf(a, d3)
    check("no line for their own car", countBy(rows, "siphon", "Kade_R") == 0)
end

section("together: one tow, one line")
do
    local a, ca = boot({ extras = true })
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local truck = car(5, 77)
    local victim = car(6, 78)
    local function tow(p, x, y)
        local args = wire({ vehicleA = x.id, vehicleB = y.id, attachmentA = "trailer", attachmentB = "trailerfront" })
        net(function() W.server.Events.OnClientCommand.fire("vehicle", "attachTrailer", p, args) end)
        drain()
    end
    -- tow off in the settings: the Log's line alone, on the claimer's car
    claimsOn(a, false)
    claim(kade, victim)
    tow(mike, truck, victim)
    check("the tow stands", victim.towedBy == truck)
    tick()
    tick()
    local rows = rowsOf(a, d3)
    check("a tow the claim lets by: one line", countBy(rows, "tow", "mike_d") == 1 and countWhat(rows, "refused: tow") == 0, countBy(rows, "tow", "mike_d"))
    check("naming the claimer", rowWith(rows, "tow").target == "Kade_R", rowWith(rows, "tow").target)
    victim.towedBy = nil
    -- tow on: it comes straight off, and the only line says refused
    extras(a, function(s) s.vc.tow = true end)
    W.clock = W.clock + (Lg_L().TOW_REPEAT_S + 1) * 1000
    perform(mike, "ISTakeEngineParts", part(victim, "Engine", nil))
    W.clock = W.clock + 1000
    tow(mike, truck, victim)
    check("refused: the link is gone", victim.towedBy == nil and truck.broke == 1, truck.broke)
    check("nothing waits for the look", #Srv().L.tows == 0, #Srv().L.tows)
    tick()
    tick()
    rows = rowsOf(a, d3)
    check("no second 'hooked up' line", countBy(rows, "tow", "mike_d") == 1, countBy(rows, "tow", "mike_d"))
    check("a refused tow says so, a second after a refused part", countBy(rows, "refused: tow", "mike_d") == 1, countBy(rows, "refused: tow", "mike_d"))
    local r = rowWith(rows, "refused: tow")
    check("in words", r and L(ca).lineText(r) == "was refused towing Kade_R's Chevalier D6", r and L(ca).lineText(r))
    -- either slot
    W.clock = W.clock + 6000
    tow(mike, victim, truck)
    check("the claimed car in the first slot: off too", truck.towedBy == nil)
    tick()
    tick()
    rows = rowsOf(a, d3)
    check("and the same one line", countBy(rows, "refused: tow", "mike_d") == 2 and countBy(rows, "tow", "mike_d") == 1, countBy(rows, "refused: tow", "mike_d"))
    -- the claimer towing their own: not refused, and their own car writes nothing
    W.clock = W.clock + 6000
    tow(kade, truck, victim)
    check("the claimer's tow stands", victim.towedBy == truck)
    victim.towedBy = nil
    -- a tow of cars nobody claimed, with the setting on: the Log's line as ever
    local c3, c4 = car(7, 79), car(8, 80)
    W.clock = W.clock + (Lg_L().TOW_REPEAT_S + 1) * 1000
    tow(mike, c3, c4)
    tick()
    tick()
    rows = rowsOf(a, d3)
    check("nobody's cars: the tow stands, no refusal", c4.towedBy == c3 and countBy(rows, "refused: tow", "mike_d") == 2)
end

section("together: the fallback keeps the refusal")
do
    -- the world E2 fears: perform doesn't see the class. The extras' class wrap is missed as the Log's is
    world({ extras = true, classMiss = true, raw = {} })
    for name, shape in pairs(ACTIONS) do W.raw[name] = shape.complete end
    local a = player("Hermit", "admin", 9000, 9000)
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    claimsOn(a)
    claim(kade, v)
    local S = W.server
    local C = S.ISUninstallVehiclePart
    local bat = function() return part(v, "Battery", { item = 1 }) end
    -- until the fallback is on, nothing can refuse in that world: said plainly in the design notes
    local one = bat()
    check("before the fallback a class wrap can't refuse", perform(mike, "ISUninstallVehiclePart", one) == true and one.item == nil)
    perform(mike, "ISUninstallVehiclePart", bat())
    W.clock = W.clock + Lg_L().HOOK_WAIT_S * 1000
    local three = bat()
    check("the third turns the fallback on, and is refused", perform(mike, "ISUninstallVehiclePart", three) == false and three.item ~= nil)
    check("on", hook("ISUninstallVehiclePart").fallback == true)
    local o = C.new(C, mike, bat())
    check("the action carries the extras' wrap, not just the Log's", rawget(o, "complete") == Srv().exTop["ISUninstallVehiclePart.complete"])
    W.clock = W.clock + 6000
    local four = bat()
    check("and the next is refused", perform(mike, "ISUninstallVehiclePart", four) == false and four.item ~= nil)
    local rows = rowsOf(a, d3)
    check("as refused, never as done", countBy(rows, "part", "mike_d") == 0 and countBy(rows, "refused: parts", "mike_d") == 2, countBy(rows, "refused: parts", "mike_d"))
    -- someone a claim doesn't stop still gets one line, through the same chain
    local five = bat()
    check("staff pass by the same road", perform(a, "ISUninstallVehiclePart", five) == true and five.item == nil)
    rows = rowsOf(a, d3)
    check("one line for them", countBy(rows, "part", "Hermit") == 1, countBy(rows, "part", "Hermit"))
    -- the siphon's other half goes on the action too
    local G = S.ISTakeGasolineFromVehicle
    local h = hook("ISTakeGasolineFromVehicle")
    h.fallback = true
    local tank = part(v, "GasTank", nil)
    tank.amount = 40
    local act = G.new(G, mike, tank)
    check("a siphon carries animEvent as well", rawget(act, "animEvent") == Srv().exTop["ISTakeGasolineFromVehicle.animEvent"] and rawget(act, "complete") == Srv().exTop["ISTakeGasolineFromVehicle.complete"])
    W.clock = W.clock + 6000
    rawget(act, "animEvent")(act, "update")
    check("and moves no gas", tank.amount == 40, tank.amount)
    -- a system turned on after the fallback: the next action takes the whole chain
    world({ extras = true, classMiss = true, raw = {} })
    for name, shape in pairs(ACTIONS) do W.raw[name] = shape.complete end
    local a2 = player("Hermit", "admin", 9000, 9000)
    local kade2 = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike2 = player("mike_d", "user", HERE_X, HERE_Y)
    local v2 = car(5, 77)
    local S2 = W.server
    local C2 = S2.ISTakeEngineParts
    local logWrap = C2.complete
    hook("ISTakeEngineParts").fallback = true
    check("with the extras off it carries the Log's wrap", rawget(C2.new(C2, mike2, part(v2, "Engine", nil)), "complete") == logWrap)
    claimsOn(a2)
    claim(kade2, v2)
    check("turned on later, the next action carries the refusal", rawget(C2.new(C2, mike2, part(v2, "Engine", nil)), "complete") == Srv().exTop["ISTakeEngineParts.complete"])
    check("and it refuses", perform(mike2, "ISTakeEngineParts", part(v2, "Engine", nil)) == false)
    -- a later mod's wrap over the extras' stays in the chain: nothing shadows it
    local top = C2.complete
    C2.complete = function(self) return top(self) end
    check("a mod's wrap over both isn't shadowed", rawget(C2.new(C2, mike2, part(v2, "Engine", nil)), "complete") == nil)
end

section("together: the Container chip and its lines")
do
    local a, ca = boot({ extras = true })
    local S = W.server
    local rosa = player("Rosa", "user", 500, 500)
    W.safes = { { getX = function() return 490 end, getY = function() return 490 end, getW = function() return 20 end, getH = function() return 20 end } }
    local took = { x = 500, y = 500, z = 0, from = "crate", rows = { { name = "Nails", n = 3 } } }
    local _, pg = rowsOf(a, {})
    check("the setting off: no chip", pg.opt == nil)
    xsay(rosa, "x_took", took)
    check("the setting off: no line", countWhat(rowsOf(a, { when = "d3" }), "took") == 0)
    extras(a, function(s) s.cl.on = true end)
    _, pg = rowsOf(a, {})
    check("the setting on: the chip", pg.opt == true)
    check("the setting is the only switch", S.ZeD.Lg.CONTAINER_LOG == nil)
    xsay(rosa, "x_took", took)
    local rows = rowsOf(a, { kind = "container", when = "d3" })
    local r = rows[1]
    check("the chip finds the line", #rows == 1 and r.what == "took" and r.k == "container", #rows)
    check("the line says who reported it", L(ca).lineText(r) == "took 3 x Nails from crate (reported by their game)", L(ca).lineText(r))
    check("the file says so too", logHas("container | took | Rosa | - | 500,500,0 | 3 x Nails from crate (reported by their game)"))
    check("Find reaches the words", #(rowsOf(a, { find = "reported by", when = "d3" })) == 1)
    local fromCode = W.server.ZeD.Lg.findCodes("took", W.server.ZeD.Lg.enWords)
    local hasTook = false
    for _, c in ipairs(fromCode or {}) do hasTook = hasTook or c == "took" end
    check("a translated Find reaches it", hasTook)
    -- a note on a ticket carries the words: staff can't quote it as the server's own
    local id = file(rosa)
    again(a)
    ask(a, { rid = 1, id = id, s = r.s }, "l_tonote")
    local note = W.server.ZeD.Srv.T.md.tickets[id].notes[1]
    check("a note says it", note and string.find(note.text, "Rosa took 3 x Nails from crate (reported by their game), at 500 x 500", 1, true) ~= nil, note and note.text)
    -- Around doesn't take a report for proof that someone stood there
    local tom = player("Tom", "user", 500, 500)
    xsay(tom, "x_took", took)
    local other = file(rosa)
    local _, around = rowsOf(a, { around = other })
    for _, e in ipairs(around.around.missed or {}) do
        check("a report proves no place: " .. e.who, e.who ~= "Tom", e.who)
    end
    extras(a, function(s) s.cl.on = false end)
    _, pg = rowsOf(a, { when = "d3" })
    check("turned off: the chip goes", pg.opt == nil)
    check("the lines kept stay under All", countWhat(rowsOf(a, { when = "d3" }), "took") == 2)
    -- a frozen extras table is off, whatever it says
    world({ extras = true })
    local a2 = player("Hermit", "admin")
    local cl = player("x", "user")
    extras(a2, function(s) s.cl.on = true end)
    Srv().X.frozen, Srv().X.set = true, W.server.ZeD.Ex.defaults()
    local _, pg2 = rowsOf(a2, {})
    check("frozen: no chip", pg2.opt == nil)
end

section("together: a line's share of the ring")
do
    local a = boot({ extras = true })
    local Srv0 = Srv()
    local AL = W.server.ZeD.Adm.L
    Srv0.actionStore("pvp", "Grief", "kill", "Rosa", nil, 1, 1, 0)
    for i = 1, AL.LOG_TOLD_MAX + 50 do Srv0.actionStore("container", "Grief", "took", nil, "report " .. i) end
    for i = 1, AL.LOG_ACTOR_MAX + 50 do Srv0.actionStore("admin", "Grief", "x", nil, "line " .. i) end
    local log = Srv0.A.md.log
    local kills, told = 0, 0
    for i = 1, log.n do
        local l = log[i]
        if l and l.who == "Grief" then
            if l.kind == "pvp" then kills = kills + 1 end
            if l.kind == "container" then told = told + 1 end
        end
    end
    check("the kill outlasts the run of lesser lines", kills == 1, kills)
    check("reports stay inside their share", told <= AL.LOG_TOLD_MAX, told)
    Srv0.actionStore("vehicle", "Grief", "part", "Kade", "CarNormal/Battery", 1, 1, 0, { car = "CarNormal", part = "Battery" })
    local found = nil
    for i = 1, log.n do if log[i] and log[i].what == "part" then found = log[i] end end
    check("ex still reaches the row", found and found.car == "CarNormal" and found.part == "Battery")
end

section("together: who Around names, and every line's words")
do
    local a, ca = boot({ extras = true })
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local rosa = player("Rosa", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    claimsOn(a)
    claim(kade, v)
    -- gone home, off the server: the claim lapses at the car's place
    offline(kade)
    Srv().action("vehicle", "Kade_R", "claim lapsed", nil, "CarNormal", HERE_X, HERE_Y, nil, { car = "CarNormal" })
    Srv().action("vehicle", "Aretha", "release", "Kade_R", "CarNormal", HERE_X, HERE_Y, nil, { car = "CarNormal" })
    Srv().action("vehicle", "Tom", "claim gone: burnt", nil, "CarNormal", HERE_X, HERE_Y, nil, { car = "CarNormal" })
    Srv().action("vehicle", "Ann", "refused: parts", "Kade_R", "CarNormal", HERE_X, HERE_Y, nil, { car = "CarNormal" })
    local id = file(rosa)
    local _, p1 = rowsOf(a, { around = id })
    local names = {}
    for _, e in ipairs(p1.around.missed or {}) do names[e.who] = true end
    check("a claim's own lines place nobody", not (names.Aretha or names.Tom))
    check("a refusal does: they were at the car", names.Ann == true)
    local M0 = L(ca)
    local function says(r) return M0.lineText(r) end
    check("a lapse", says({ k = "vehicle", what = "claim lapsed", car = "CarNormal" }) == "lost the claim on a Chevalier D6, away too long")
    check("a burnt claim", says({ k = "vehicle", what = "claim gone: burnt", car = "CarNormal" }) == "lost the claim on a Chevalier D6, it burned")
    check("a vanished car", says({ k = "vehicle", what = "claim gone: that car is gone", car = "CarNormal" }) == "lost the claim on a Chevalier D6, the car is gone")
    check("a refused drive", says({ k = "vehicle", what = "refused: drive", target = "Kade_R", car = "CarNormal" }) == "was refused driving Kade_R's Chevalier D6")
    check("a refused dismantle", says({ k = "safehouse", what = "refused: dismantle", target = "Aretha" }) == "was refused dismantling in Aretha's safehouse")
    check("a refused swing", says({ k = "safehouse", what = "refused: destroy", target = "Aretha" }) == "was refused breaking things in Aretha's safehouse")
    check("a save of the extras", says({ k = "admin", what = "server extras", text = "claims on" }) == "changed the server extras: claims on")
    check("a map teleport", says({ k = "admin", what = "map teleport" }) == "teleported by the map")
    check("a safehouse's claim keeps its own words", says({ k = "safehouse", what = "claim" }) == "claimed a safehouse")
    check("both claims answer a translated Find", (function()
        local Lg0 = W.server.ZeD.Lg
        local out = Lg0.findCodes("claimed", Lg0.enWords) or {}
        local n = 0
        for _, c in ipairs(out) do if c == "claim" then n = n + 1 end end
        return n == 2
    end)())
end

section("together: a reload, and no extras at all")
do
    local a = boot({ extras = true })
    local kade = player("Kade_R", "user", HERE_X, HERE_Y)
    local mike = player("mike_d", "user", HERE_X, HERE_Y)
    local v = car(5, 77)
    claimsOn(a)
    claim(kade, v)
    local top = W.server.ISUninstallVehiclePart.complete
    runFile(W.server, "42/media/lua/server/ZeD/ZeD_ServerExtras.lua")
    runFile(W.server, "42/media/lua/server/ZeD/ZeD_ServerLog.lua")
    Srv().openExtras()
    check("a reload of both wraps nothing twice", W.server.ISUninstallVehiclePart.complete == top)
    check("the refusal stands", perform(mike, "ISUninstallVehiclePart", part(v, "Battery", { item = 1 })) == false)
    local rows = rowsOf(a, d3)
    check("one line", countBy(rows, "refused: parts", "mike_d") == 1 and countWhat(rows, "part") == 0, countBy(rows, "refused: parts", "mike_d"))
    -- a game with one capability renamed: the extras' file stops at its head and the Log runs alone, its table unopened at load
    CAPS.ManipulateVehicle = nil
    world({ extras = true })
    CAPS.ManipulateVehicle = "ManipulateVehicle"
    local a2 = player("Hermit", "admin", HERE_X, HERE_Y)
    local k2 = player("Kade_R", "user", HERE_X, HERE_Y)
    local m2 = player("mike_d", "user", HERE_X, HERE_Y)
    local v2 = car(5, 77)
    check("no extras: nothing for the Log to ask", Srv().exOwner == nil and Srv().exTop == nil)
    check("said once, in the file", logHas("server extras off | @server | - | - | this game has no ManipulateVehicle capability"))
    drive(v2, k2)
    v2.engine = true
    tick()
    leave(v2, k2)
    v2.engine = false
    W.clock = W.clock + (Lg_L().SETTLE_S + 1) * 1000
    perform(m2, "ISTakeEngineParts", part(v2, "Engine", nil))
    local r = rowWith(rowsOf(a2, d3), "eparts")
    check("the Log runs alone", r and r.target == "Kade_R", r and r.target)
end

print("log_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
