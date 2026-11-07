-- ZeDUI/tools/qa/extras_sim.lua  (Nov 6 2026, QA): multiplayer Phase 6, the server extras, with no game running.
-- Lua 5.1 stubs of the game's vehicles, safehouses, wars, timed actions and client commands, each written from its javap
-- listing, so a call the game would refuse is refused here too: a stub vehicle or safehouse counts every touch, and a Java
-- method the file has no business calling isn't there. The real files run against them: ZeD_TicketProto, ZeD_ExtrasProto,
-- ZeD_ServerCore and ZeD_ServerExtras on the server side (and ZeD_DashProto with ZeD_ServerDash, the dash's odometer command,
-- which writes into the same cars), ZeD_ServerLink, ZeD_Tickets and ZeD_Extras on each simulated client.
-- Every message crosses a stub of the network, with the game's rules, a step at a time.
--
-- First the proof the job asks for: with every extra off, no wrap is on the game's classes, no listener or clock is added,
-- and nothing touches a vehicle or a safehouse. Then the same after a system has been on and off again: the wraps stay, and
-- do no work. Then each system: the settings, claims, parts, driving, tow, lapse, release, safehouse protection and the lot,
-- swings, the map's teleport, the container log, a frozen table, a reload.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/extras_sim.lua
-- It prints FAIL lines and a last line "extras_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]extras_sim%.lua$", "")

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
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
        contains = function(_, v) for _, x in ipairs(t) do if x == v then return true end end return false end }
end

local function events()
    return setmetatable({}, { __index = function(self, name)
        local ev = { list = {} }
        function ev.Add(fn) ev.list[#ev.list + 1] = fn end
        function ev.Remove(fn)
            for i = #ev.list, 1, -1 do if ev.list[i] == fn then table.remove(ev.list, i) end end
        end
        function ev.fire(...) for _, fn in ipairs(ev.list) do fn(...) end end
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
    elseif t == "string" or t == "number" or t == "boolean" then
        return v
    end
    error("a value the network drops: " .. t)
end
local function wire(a)
    local c = netCopy(a or {})
    for _ in pairs(c) do return c end
    return nil
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
    drain()
    for _, c in pairs(W.clients) do
        if c.up then c.env.Events.OnTick.fire() end
    end
    drain()
    if W.server then W.server.Events.OnTickEvenPaused.fire() end
    drain()
end
local function advance(ms)
    drain()
    while ms > 0 do
        local d = math.min(ms, 100)
        step(d)
        ms = ms - d
    end
end

local CAPS = setmetatable({}, { __index = function(_, k) return k end })
local function role(name, caps)
    local r = { name = name, caps = caps }
    function r.getName(self) return self.name end
    function r.hasCapability(self, cap)
        if cap == nil then error("No implementation found: hasCapability(nil)") end
        return self.caps[cap] == true
    end
    return r
end
local ROLES = {
    user = role("user", {}),
    mod = role("moderator", { AnswerTickets = true, TeleportToCoordinates = true }),
    admin = role("admin", { AnswerTickets = true, RolesWrite = true, ChangeAndReloadServerOptions = true, ManipulateVehicle = true,
        UseBuildCheat = true, TeleportToCoordinates = true, CanGoInsideSafehouses = true }),
}

-- every touch of a vehicle or a safehouse counts: with the extras off the count must not move
local function touch() W.touched = W.touched + 1 end

local function newVehicle(id, sql, x, y, script)
    local v = { id = id, sql = sql, x = x, y = y, script = script or "Base.PickUpTruck", running = false, burnt = false, keyId = 100 + id,
        links = {}, shut = 0, broke = 0, md = {} }
    function v.getId(self) touch(); return self.id end
    function v.getModData(self) touch(); return self.md end
    function v.transmitModData(self) self.transmits = (self.transmits or 0) + 1 end
    function v.isStarting(self) touch(); return self.starting == true end
    function v.getSqlId(self) touch(); return self.sql end
    function v.getX(self) touch(); return self.x end
    function v.getY(self) touch(); return self.y end
    function v.getKeyId(self) touch(); return self.keyId end
    function v.getScript(self)
        local name = self.script
        return { getName = function() return name end, getCarModelName = function() return nil end }
    end
    function v.getDriver(self) touch(); return self.driver end
    -- (BaseVehicle.getMaxPassengers, getCharacter(int): the seats, the driver's 0; nothing but a number takes)
    v.seats = {}
    function v.getMaxPassengers(self) touch(); return 4 end
    function v.getCharacter(self, i)
        touch()
        if type(i) ~= "number" then error("No implementation found: getCharacter") end
        if i == 0 then return self.driver end
        return self.seats[i]
    end
    function v.isDriver(self, chr) touch(); return self.driver == chr end
    function v.isBurnt(self) touch(); return self.burnt end
    function v.isEngineRunning(self) touch(); return self.running end
    function v.shutOff(self)
        touch()
        self.running = false
        self.shut = self.shut + 1
    end
    -- breakConstraint(IsoPlayer, boolean, boolean) and (boolean, boolean): nothing else
    function v.breakConstraint(self, a, b, c)
        local twoArg = c == nil and type(a) == "boolean" and type(b) == "boolean"
        local threeArg = type(b) == "boolean" and type(c) == "boolean"
        if not (twoArg or threeArg) then error("No implementation found: breakConstraint") end
        self.broke = self.broke + 1
        self.towed = nil
    end
    function v.addPointConstraint(self, p, other, a, b) self.towed = other end
    W.vehicles[id] = v
    return v
end

local function newSafe(x, y, w, h, owner, members)
    W.safeN = W.safeN + 1
    local s = { x = x, y = y, w = w, h = h, owner = owner, players = members or {}, onlineId = 1000 + W.safeN }
    function s.getX(self) touch(); return self.x end
    function s.getY(self) touch(); return self.y end
    function s.getW(self) touch(); return self.w end
    function s.getH(self) touch(); return self.h end
    function s.getOwner(self) touch(); return self.owner end
    function s.getOnlineID(self) return self.onlineId end
    -- (the game's: a member, the owner, or CanGoInsideSafehouses)
    function s.playerAllowed(self, who)
        touch()
        if type(who) ~= "table" then error("the sim has only the IsoPlayer overload in use") end
        if self.owner == who:getUsername() then return true end
        for _, n in ipairs(self.players) do if n == who:getUsername() then return true end end
        return who.role.caps.CanGoInsideSafehouses == true
    end
    W.safes[#W.safes + 1] = s
    return s
end

local function square(x, y, z)
    return { getX = function() return x end, getY = function() return y end, getZ = function() return z or 0 end }
end

local function player(name, roleName, x, y)
    local p = { name = name, role = ROLES[roleName or "user"], x = x or 100, y = y or 100, z = 0, keys = {} }
    function p.getUsername(self) return self.name end
    function p.getRole(self) return self.role end
    function p.getX(self) return self.x end
    function p.getY(self) return self.y end
    function p.getZ(self) return self.z end
    function p.getVehicle(self) return self.vehicle end
    function p.getSteamID(self) return 0 end
    function p.getInventory(self)
        local me = self
        return { haveThisKeyId = function(_, id) return me.keys[id] end }
    end
    p.isPlayer = true
    W.online[#W.online + 1] = p
    W.players[name] = p
    return p
end

local function door(sq, health, class)
    local d = { sq = sq, health = health, class = class or "IsoDoor" }
    function d.getSquare(self) return self.sq end
    function d.getHealth(self) return self.health end
    function d.setHealth(self, n) self.health = n end
    return d
end

local function weapon(n) return { getDoorDamage = function() return n end } end

-- the game's classes: each complete() counts, and says it ran. An action instance reads its class through the metatable, as
-- NetTimedAction's rawget does (KahluaTableImpl.rawget walks the metatable)
local ACTIONS = { "ISUninstallVehiclePart", "ISTakeEngineParts", "ISTakeGasolineFromVehicle", "ISStartVehicleEngine", "ISHotwireVehicle",
    "ISDismantleAction", "ISMoveablesAction", "ISUnbarricadeAction", "ISDestroyStuffAction", "ISRemoveBurntVehicle" }

-- what the game's getVehicleById finds: Double.intValue, then i2s (javap: LuaManager$GlobalObject.getVehicleById)
local function javaShort(d)
    if d ~= d then return 0 end
    if d > 2147483647 then d = 2147483647 elseif d < -2147483648 then d = -2147483648 end
    d = (d < 0) and math.ceil(d) or math.floor(d)
    local low = math.fmod(d, 65536)
    if low < 0 then low = low + 65536 end
    if low >= 32768 then low = low - 65536 end
    return low
end

local function installGame(env)
    env.originals = {}
    for _, name in ipairs(ACTIONS) do
        local cls = {}
        cls.complete = function(self)
            W.ran[name] = (W.ran[name] or 0) + 1
            return true
        end
        cls.__index = cls
        env[name] = cls
        env.originals[name] = cls.complete
    end
    -- the game's siphon: an "update" event every second moves the gas, on the server, long before complete()
    env.ISTakeGasolineFromVehicle.animEvent = function(self, event)
        if event == "update" and self.tank then
            self.tank.litres = self.tank.litres - 1
            self.tank.can = self.tank.can + 1
        end
    end
    env.originals.siphon = env.ISTakeGasolineFromVehicle.animEvent
    env.getVehicleById = function(id)
        if type(id) ~= "number" then error("No implementation found: getVehicleById") end
        return W.vehicles[javaShort(id)]
    end
    env.SafeHouse = { getSafehouseList = function() touch(); return jlist(W.safes) end }
    env.WarManager = { isWarStarted = function(id, user)
        if type(id) ~= "number" or type(user) ~= "string" then error("No implementation found: isWarStarted") end
        return W.wars[id .. ":" .. user] == true
    end }
    env.Faction = { getPlayerFaction = function(p) return W.factions[p.name] end }
    env.instanceof = function(o, name)
        if name == "IsoPlayer" then return o.isPlayer == true end
        return o.class == name
    end
    env.Capability = CAPS
    env.ModData = {
        getTableNames = function()
            local n = {}
            for k in pairs(W.moddata) do n[#n + 1] = k end
            table.sort(n)
            return jlist(n)
        end,
        getOrCreate = function(name)
            W.moddata[name] = W.moddata[name] or {}
            return W.moddata[name]
        end,
        transmit = function() error("the extras table must never be transmitted") end,
    }
    W.uuid = W.uuid + 1
    env.getRandomUUID = function() return "secret-" .. W.uuid end
end

local function baseEnv()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.next = nil
    env.Events = events()
    env.print = function(s) env.printed = (env.printed or "") .. tostring(s) .. "\n" end
    env.getTimestampMs = function() return W.clock end
    env.getTimestamp = function() return math.floor(W.clock / 1000) end
    env.loaded = {}
    return env
end

local function runFile(env, rel)
    local f = assert(loadfile(ROOT .. rel))
    setfenv(f, env)
    return f()
end

local FILES = {
    ["ZeD/ZeD_TicketProto"] = "42/media/lua/shared/ZeD/ZeD_TicketProto.lua",
    ["ZeD/ZeD_ExtrasProto"] = "42/media/lua/shared/ZeD/ZeD_ExtrasProto.lua",
    ["ZeD/ZeD_DashProto"] = "42/media/lua/shared/ZeD/ZeD_DashProto.lua",
    ["ZeD/ZeD_ServerCore"] = "42/media/lua/server/ZeD/ZeD_ServerCore.lua",
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
    env.getGameTime = function() return { getWorldAgeHours = function() return 270 end } end
    env.writeLog = function(name, line) W.logs[#W.logs + 1] = { name = name, line = line } end
    env.sendServerCommand = function(p, module, command, args)
        local a = wire(args)
        net(function()
            local c = W.clients[p.name]
            if c and c.up then c.env.Events.OnServerCommand.fire(module, command, a) end
        end)
    end
    env.ISLogSystem = { writeLog = function() end }
    installGame(env)
    -- the game's own handler for vehicle commands, first in line as it is on a server
    env.Events.OnClientCommand.Add(function(module, command, p, args)
        if module == "vehicle" and command == "attachTrailer" then
            env.getVehicleById(args.vehicleA):addPointConstraint(p, env.getVehicleById(args.vehicleB), args.attachmentA, args.attachmentB)
        elseif module == "vehicle" and command == "startEngine" then
            -- (the game's: vehicle:tryStartEngine, with no capability test and no action around it)
            local v = p.vehicle
            if v and v.driver == p then v.starting = true end
        end
    end)
    requireIn(env, "ZeD/ZeD_ServerCore")
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerExtras.lua")
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerDash.lua")
    env.Events.OnInitGlobalModData.fire(false)
    return env
end

local function clientJoin(p)
    local env = baseEnv()
    local c = { env = env, p = p, up = true, halo = {}, sent = {}, commands = {} }
    W.clients[p.name] = c
    env.isServer = function() return false end
    env.isClient = function() return true end
    env.require = function(n) requireIn(env, n) end
    env.getPlayer = function() return p end
    env.ZeD = {
        tr = function(k, ...)
            local a = { ... }
            return k .. (a[1] and (":" .. tostring(a[1])) or "")
        end,
        logOnce = function(k, m) check("no client error", false, tostring(k) .. ": " .. tostring(m)) end,
        Messages = {},
    }
    env.ISAdminMessage = { AddAdminMessage = function() end }
    env.HaloTextHelper = {
        addBadText = function(pl, s) c.halo[#c.halo + 1] = s end,
        addGoodText = function(pl, s) c.halo[#c.halo + 1] = s end,
    }
    env.SendCommandToServer = function(s) c.commands[#c.commands + 1] = s end
    env.sendClientCommand = function(pl, module, command, args)
        c.sent[#c.sent + 1] = command
        local a = wire(args)
        net(function()
            if W.server then W.server.Events.OnClientCommand.fire(module, command, pl, a) end
        end)
    end
    env.getTickets, env.addTicket, env.viewedTicket, env.removeTicket = function() end, function() end, function() end, function() end
    env.SafeHouse = { getSafeHouse = function(sq)
        for _, h in ipairs(W.safes) do
            if sq:getX() >= h.x and sq:getX() < h.x + h.w and sq:getY() >= h.y and sq:getY() < h.y + h.h then return h end
        end
        return nil
    end }
    -- the game's transfer action on this client
    local cls = { calls = 0 }
    cls.perform = function(self) cls.calls = cls.calls + 1 end
    env.ISInventoryTransferAction = cls
    c.perform = cls.perform
    requireIn(env, "ZeD/ZeD_ExtrasProto")
    requireIn(env, "ZeD/ZeD_DashProto")
    requireIn(env, "ZeD/ZeD_ServerLink")
    requireIn(env, "ZeD/ZeD_Tickets")
    c.E = runFile(env, "42/media/lua/client/ZeD/ZeD_Extras.lua")
    env.Events.OnCreatePlayer.fire(0, p)
    advance(300)
    return c
end

local function world(noPart)
    W = { clock = 1793913240000, net = {}, logs = {}, online = {}, players = {}, clients = {}, safes = {}, vehicles = {}, moddata = {}, wars = {},
        factions = {}, ran = {}, rejected = 0, suspicious = 0, safeN = 0, touched = 0, uuid = 0 }
    if not noPart then serverStart() end
end

local function logHas(word)
    for _, l in ipairs(W.logs) do
        if l.name == "ZeD" and string.find(l.line, word, 1, true) then return true end
    end
    return false
end
local function logCount(word)
    local n = 0
    for _, l in ipairs(W.logs) do
        if l.name == "ZeD" and string.find(l.line, word, 1, true) then n = n + 1 end
    end
    return n
end
local function haloHas(c, word)
    for _, s in ipairs(c.halo) do
        if string.find(s, word, 1, true) then return true end
    end
    return false
end

-- a timed action as the server runs it: the Lua complete(), false a rejection, and nothing goes near an anti-cheat
local function act(name, fields)
    local cls = W.server[name]
    local a = setmetatable(fields, cls)
    local done = a:complete()
    if not done then W.rejected = W.rejected + 1 end
    return done
end

local function save(c, set)
    local got = nil
    c.E.save(set, function(a) got = a end)
    advance(1200)
    return got
end
local function settings(c, fn)
    local set = c.env.ZeD.Ex.clean(c.E.set)
    fn(set)
    return save(c, set)
end
local function claim(c, v)
    local got = nil
    c.E.claim(v, function(a) got = a end)
    advance(1200)
    return got
end
local function press(c, fn)
    local got = nil
    fn(function(a) got = a end)
    advance(1200)
    return got
end

local function sawCommand(c, cmd)
    for _, s in ipairs(c.sent) do if s == cmd then return true end end
    return false
end

-- ---------------------------------------------------------------------------
-- THE PURE CHECKS
-- ---------------------------------------------------------------------------
section("the settings' shape")
do
    world()
    local a = player("Hermit", "admin")
    local c = clientJoin(a)
    local Ex = c.env.ZeD.Ex
    local d = Ex.defaults()
    check("every extra is off by default", not (d.vc.on or d.sp.on or d.tp.on or d.cl.on))
    check("as drawn: parts, drive, no tow, 2, 7", d.vc.parts and d.vc.drive and not d.vc.tow and d.vc.per == 2 and d.vc.lapse == 7)
    check("as drawn: dismantle, destroy, lot", d.sp.dismantle and d.sp.destroy and d.sp.lot)
    check("junk is the defaults", Ex.same(Ex.clean("junk"), d) and Ex.same(Ex.clean(nil), d) and Ex.same(Ex.clean({}), d))
    local s = Ex.clean({ vc = { on = "yes", per = 99, lapse = 0, tow = true }, sp = { on = true, lot = 1 }, extra = true })
    check("a word isn't a boolean", s.vc.on == false)
    check("numbers are held to the drawing's range", s.vc.per == 5 and s.vc.lapse == 1)
    check("a good boolean stays", s.vc.tow == true and s.sp.on == true)
    check("a wrong field takes its default", s.sp.lot == true)
    check("a fraction is no number of days", Ex.clean({ vc = { lapse = 2.5 } }).vc.lapse == 7)
    check("an unknown field goes", s.extra == nil)
    check("nOn counts systems", Ex.nOn(s) == 1)
    check("keys", Ex.okKey(Ex.keyOf(4021)) and not Ex.okKey("v") and not Ex.okKey("x12") and not Ex.okKey(12) and not Ex.okKey("v" .. string.rep("1", 20)))
    check("vehicle numbers", Ex.okVeh(0) and Ex.okVeh(-5) and not Ex.okVeh(1.5) and not Ex.okVeh("3"))
    check("coordinates", Ex.okCoord(6402) and not Ex.okCoord(-1) and not Ex.okCoord(1.5) and not Ex.okCoord(999999))
end

-- ---------------------------------------------------------------------------
-- WITH EVERY EXTRA OFF: THE PROOF
-- ---------------------------------------------------------------------------
-- every call the game makes that a wrap would catch, by someone with no right to it, on a claimed-looking world
local function everything(v, d, h, p)
    act("ISUninstallVehiclePart", { character = p, vehicle = v })
    act("ISTakeEngineParts", { character = p, vehicle = v })
    act("ISTakeGasolineFromVehicle", { character = p, vehicle = v })
    act("ISStartVehicleEngine", { character = p })
    act("ISHotwireVehicle", { character = p })
    act("ISDismantleAction", { character = p, thumpable = d })
    act("ISMoveablesAction", { character = p, square = d.sq, mode = "scrap" })
    act("ISUnbarricadeAction", { character = p, item = d })
    act("ISDestroyStuffAction", { character = p, item = d })
    act("ISRemoveBurntVehicle", { character = p, vehicle = v })
    setmetatable({ character = p, vehicle = v }, W.server.ISTakeGasolineFromVehicle):animEvent("update")
    W.server.Events.OnWeaponHitThumpable.fire(p, weapon(10), d)
    W.server.Events.OnClientCommand.fire("vehicle", "attachTrailer", p, { vehicleA = v.id, vehicleB = v.id, attachmentA = "a", attachmentB = "b" })
    W.server.Events.OnClientCommand.fire("vehicle", "startEngine", p, {})
end

section("every extra off: nothing is wrapped, added or touched")
do
    world()
    local srv = W.server
    for _, name in ipairs(ACTIONS) do
        check("no wrap on " .. name, srv[name].complete == srv.originals[name])
    end
    check("no wrap on the siphon's event", srv.ISTakeGasolineFromVehicle.animEvent == srv.originals.siphon)
    check("no clock", #srv.Events.OnTickEvenPaused.list == 0, #srv.Events.OnTickEvenPaused.list)
    check("no swing listener", #srv.Events.OnWeaponHitThumpable.list == 0)
    check("two command listeners: the game's and the core's", #srv.Events.OnClientCommand.list == 2, #srv.Events.OnClientCommand.list)
    local a = player("Hermit", "admin")
    local b = player("Grief", "user", 500, 500)
    local ca, cb = clientJoin(a), clientJoin(b)
    check("the hello says all off", ca.E.set ~= nil and ca.env.ZeD.Ex.nOn(ca.E.set) == 0)
    check("no client wrap", cb.env.ISInventoryTransferAction.perform == cb.perform)
    check("a client's tick list has no extras clock", cb.E.logArmed == nil)
    local v = newVehicle(7, 4021, 500, 500)
    b.vehicle = v
    v.driver = b
    v.running = true
    local h = newSafe(490, 490, 20, 20, "Hermit")
    local d = door(square(495, 495), 500)
    W.moddata[(function() for k in pairs(W.moddata) do return k end end)()].claims[srv.ZeD.Ex.keyOf(4021)] = { owner = "Hermit", at = 0 }
    W.touched = 0
    everything(v, d, h, b)
    advance(10000)
    check("nothing touched a vehicle or a safehouse", W.touched == 0, W.touched)
    check("no action refused", W.rejected == 0, W.rejected)
    for _, name in ipairs(ACTIONS) do check("the game's function ran: " .. name, W.ran[name] == 1, W.ran[name]) end
    check("the door takes its swing as ever", d.health == 500)
    check("a running engine stays on", v.running and v.shut == 0)
    check("the tow stands", v.towed ~= nil and v.broke == 0)
    check("no refusal said", #cb.halo == 0)
    W.touched = 0
    -- what a client does with it all off
    cb.sent = {}
    check("the Vehicle tab asks nothing", cb.E.car(v) == nil and cb.E.partsBlock(v) == nil and #cb.sent == 0)
    check("no list of claims", cb.E.mine() == nil and #cb.sent == 0)
    local r = claim(cb, v)
    check("a claim sent anyway is refused: off", r and r.ok == false and r.err == "off")
    local t = press(ca, function(k) ca.E.goTo(10, 10, k) end)
    check("a teleport sent anyway is refused: off", t and t.ok == false and t.err == "off" and #ca.commands == 0)
    b.x, b.y = 495, 495
    W.logs = {}
    W.server.Events.OnClientCommand.fire("ZeDX", "x_took", b, { x = 495, y = 495, z = 0, rows = { { name = "Nails", n = 1 } } })
    drain()
    check("a report sent anyway is dropped", not logHas("container | took"))
end

section("on, then off again: the wraps stay and do no work")
do
    world()
    local srv = W.server
    local a = player("Hermit", "admin")
    local b = player("Grief", "user", 500, 500)
    local ca, cb = clientJoin(a), clientJoin(b)
    local r = settings(ca, function(s) s.vc.on, s.vc.tow, s.sp.on, s.tp.on, s.cl.on = true, true, true, true, true end)
    check("saved", r and r.ok == true)
    for _, name in ipairs(ACTIONS) do
        check("a wrap on " .. name, srv[name].complete ~= srv.originals[name])
    end
    check("a wrap on the siphon's event", srv.ISTakeGasolineFromVehicle.animEvent ~= srv.originals.siphon)
    check("the client's wrap is on", cb.env.ISInventoryTransferAction.perform ~= cb.perform)
    local clocks = #srv.Events.OnTickEvenPaused.list
    check("one clock", clocks == 1, clocks)
    check("one swing listener", #srv.Events.OnWeaponHitThumpable.list == 1)
    check("one tow listener", #srv.Events.OnClientCommand.list == 3)
    r = settings(ca, function(s) s.vc.on, s.sp.on, s.tp.on, s.cl.on = false, false, false, false end)
    check("saved off", r and r.ok == true)
    check("no second set of wraps", #srv.Events.OnTickEvenPaused.list == clocks and #srv.Events.OnClientCommand.list == 3)
    local v = newVehicle(7, 4021, 500, 500)
    b.vehicle = v
    v.driver = b
    v.running = true
    local h = newSafe(490, 490, 20, 20, "Hermit")
    local d = door(square(495, 495), 500)
    W.touched = 0
    W.rejected = 0
    W.ran = {}
    everything(v, d, h, b)
    advance(10000)
    check("nothing touched a vehicle or a safehouse", W.touched == 0, W.touched)
    check("no action refused", W.rejected == 0, W.rejected)
    for _, name in ipairs(ACTIONS) do check("the game's function ran: " .. name, W.ran[name] == 1, W.ran[name]) end
    check("the engine stays on", v.running)
    check("the tow stands", v.broke == 0)
    check("the door takes its swing as ever", d.health == 500)
    check("the client's wrap passes through", (function()
        cb.env.ISInventoryTransferAction.perform({ srcContainer = nil })
        return cb.env.ISInventoryTransferAction.calls == 1
    end)())
end

-- ---------------------------------------------------------------------------
-- THE SETTINGS
-- ---------------------------------------------------------------------------
section("who may save, and everyone hears")
do
    world()
    local a = player("Hermit", "admin")
    local b = player("Kade", "user")
    local m = player("Rosa", "mod")
    local ca, cb, cm = clientJoin(a), clientJoin(b), clientJoin(m)
    local r = settings(cb, function(s) s.vc.on = true end)
    check("a player may not", r and r.ok == false and r.err == "perm")
    r = settings(cm, function(s) s.vc.on = true end)
    check("nor a moderator: it asks ChangeAndReloadServerOptions", r and r.ok == false and r.err == "perm")
    check("nothing changed", not ca.E.set.vc.on)
    r = settings(ca, function(s) s.vc.on, s.vc.per = true, 3 end)
    check("the owner may", r and r.ok == true)
    check("every client hears", ca.E.set.vc.on and cb.E.set.vc.on and cm.E.set.vc.on and cb.E.set.vc.per == 3)
    check("the admin line", logHas("admin | server extras | Hermit") and logHas("claims on"))
    r = press(ca, function(k) ca.E.request("x_save", {}, k) end)
    check("no settings at all: refused", r and r.ok == false and r.err == "text")
    ca.E.request("x_save", { set = { vc = { on = true, per = 500 }, sp = { on = 1 }, tp = "x" }, was = ca.E.set }, function() end)
    advance(1200)
    check("the server cleans what it's sent", ca.E.set.vc.per == 5 and ca.E.set.sp.on == false and ca.E.set.tp.on == false)
    local late = player("Late", "user")
    local cl = clientJoin(late)
    check("a player joining later hears in the hello", cl.E.set.vc.on == true and cl.E.set.vc.per == 5)
end

section("the settings outlast a restart, under a secret name")
do
    world()
    local a = player("Hermit", "admin")
    local ca = clientJoin(a)
    local v = newVehicle(7, 4021, 100, 100)
    settings(ca, function(s) s.vc.on = true end)
    check("claimed", (claim(ca, v) or {}).ok == true)
    local name
    for k in pairs(W.moddata) do name = k end
    check("the table's name is secret", string.find(name, "^ZeD_EX_secret") ~= nil, name)
    W.server = nil
    serverStart()
    local md = W.moddata[name]
    check("the same table", md.claims[W.server.ZeD.Ex.keyOf(4021)] ~= nil)
    W.clients = {}
    local c2 = clientJoin(a)
    check("the settings are back", c2.E.set.vc.on == true)
    local b = player("Kade", "user", 100, 100)
    check("and the wraps with them", W.server.ISUninstallVehiclePart.complete ~= W.server.originals.ISUninstallVehiclePart)
    check("the claim holds after a restart", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
end

-- ---------------------------------------------------------------------------
-- CLAIMS
-- ---------------------------------------------------------------------------
local function claimsWorld(extra)
    world()
    local a = player("Hermit", "admin", 900, 900)
    local o = player("Aretha", "user", 100, 100)
    local b = player("Kade", "user", 100, 100)
    local ca, co, cb = clientJoin(a), clientJoin(o), clientJoin(b)
    settings(ca, function(s)
        s.vc.on = true
        if extra then extra(s) end
    end)
    return a, o, b, ca, co, cb
end

section("claiming a car")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    local far = newVehicle(8, 4022, 300, 300)
    local r = claim(co, far)
    check("too far", r and r.ok == false and r.err == "far")
    local burnt = newVehicle(9, 4023, 100, 101)
    burnt.burnt = true
    r = claim(co, burnt)
    check("a wreck can't be claimed", r and r.ok == false and r.err == "burnt")
    local fresh = newVehicle(10, -1, 100, 101)
    r = claim(co, fresh)
    check("a car the database hasn't numbered waits", r and r.ok == false and r.err == "soon")
    local driven = newVehicle(11, 4024, 100, 101)
    driven.driver = b
    r = claim(co, driven)
    check("someone else at the wheel", r and r.ok == false and r.err == "driven")
    r = claim(co, v)
    check("claimed", r and r.ok == true)
    check("the log says who, what, where", logHas("vehicle | claim | Aretha") and logHas("102,100"))
    r = claim(cb, v)
    check("taken", r and r.ok == false and r.err == "taken")
    co.E.cars = {}
    co.E.car(v)
    advance(200)
    local view = co.E.cars[7].view
    check("the owner's view", view.owner == "Aretha" and view.mine == true and view.n == 1 and view.per == 2 and view.key == "v4021")
    cb.E.car(v)
    advance(200)
    view = cb.E.cars[7].view
    check("another's view", view.owner == "Aretha" and view.mine == false and view.staff == false)
    check("a view holds no times", view.at == nil and view.seen == nil)
    local v2, v3 = newVehicle(12, 4025, 100, 102), newVehicle(13, 4026, 100, 103)
    check("a second car", (claim(co, v2) or {}).ok == true)
    r = claim(co, v3)
    check("the limit, as set", r and r.ok == false and r.err == "many")
    co.E.mineRows = nil
    co.E.mine()
    advance(1200)
    check("my claims", #co.E.mineRows == 2 and co.E.minePer == 2)
    check("a row is an allowlist", co.E.mineRows[1].owner == nil and co.E.mineRows[1].at == nil)
    r = press(cb, function(k) cb.E.request("x_claim", { veh = "7" }, k) end)
    check("a bad number is refused", r and r.ok == false and r.err == "gone")
    W.server.ZeD.Ex.CLAIM_NEEDS_KEY = true
    r = claim(co, newVehicle(14, 4027, 100, 104))
    W.server.ZeD.Ex.CLAIM_NEEDS_KEY = false
    check("(the switch) the key", r and r.ok == false and (r.err == "key" or r.err == "many"))
end

section("the key switch alone")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    W.server.ZeD.Ex.CLAIM_NEEDS_KEY = true
    local r = claim(co, v)
    check("no key, no claim", r and r.ok == false and r.err == "key")
    o.keys[v.keyId] = true
    check("with the key", (claim(co, v) or {}).ok == true)
    W.server.ZeD.Ex.CLAIM_NEEDS_KEY = false
end

section("parts")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    W.ran = {}
    W.logs = {}
    check("the owner takes parts", act("ISUninstallVehiclePart", { character = o, vehicle = v }) == true)
    check("the game's function ran", W.ran.ISUninstallVehiclePart == 1)
    check("another can't", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    check("the game's function did not run", W.ran.ISUninstallVehiclePart == 1)
    check("engine parts neither", act("ISTakeEngineParts", { character = b, vehicle = v }) == false)
    check("nor gas", act("ISTakeGasolineFromVehicle", { character = b, vehicle = v }) == false)
    check("staff pass", act("ISUninstallVehiclePart", { character = a, vehicle = v }) == true)
    local free = newVehicle(8, 4022, 100, 100)
    check("an unclaimed car is the game's", act("ISUninstallVehiclePart", { character = b, vehicle = free }) == true)
    advance(200)
    check("the player is told who", haloHas(cb, "UI_ZeD_Ex_No_parts:Aretha"))
    check("one line for a burst", logCount("refused: parts") == 1, logCount("refused: parts"))
    advance(6000)
    act("ISTakeEngineParts", { character = b, vehicle = v })
    check("another after the pause", logCount("refused: parts") == 2)
    check("no suspicion: a refusal is complete() answering false", W.suspicious == 0)
    settings(ca, function(s) s.vc.parts = false end)
    check("the tick off lets it through", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
end

section("a claim that can't run its test leaves the game alone")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    W.ran = {}
    v.getSqlId = function() error("a game update") end
    check("the game's action still runs", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true and W.ran.ISUninstallVehiclePart == 1)
end

section("driving")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    b.vehicle = v
    v.driver = b
    W.ran = {}
    check("the engine won't start for another", act("ISStartVehicleEngine", { character = b }) == false)
    check("nor hotwire", act("ISHotwireVehicle", { character = b }) == false)
    check("the game's functions did not run", W.ran.ISStartVehicleEngine == nil and W.ran.ISHotwireVehicle == nil)
    v.driver, b.vehicle = o, nil
    o.vehicle = v
    check("it starts for the owner", act("ISStartVehicleEngine", { character = o }) == true)
    v.running = true
    o.x, o.y = 200, 210
    v.x, v.y = 200, 210
    advance(2200)
    check("the owner drives on", v.running and v.shut == 0)
    co.E.mineRows = nil
    co.E.mine()
    advance(1200)
    check("the claim follows the car", co.E.mineRows[1].x == 200 and co.E.mineRows[1].y == 210)
    -- the owner gets out with it running; someone climbs in (a packet with no hook)
    o.vehicle, v.driver = nil, b
    b.vehicle = v
    advance(2200)
    check("a running engine stops for another", not v.running and v.shut == 1)
    check("the player is told", haloHas(cb, "UI_ZeD_Ex_No_drive:Aretha"))
    v.running = true
    v.driver, b.vehicle = a, nil
    a.vehicle = v
    advance(2200)
    check("staff drive on", v.running and v.shut == 1)
    settings(ca, function(s) s.vc.drive = false end)
    v.driver, a.vehicle = b, nil
    b.vehicle = v
    advance(2200)
    check("the tick off leaves it running", v.running)
    check("and the engine starts", act("ISStartVehicleEngine", { character = b }) == true)
end

section("tow")
do
    local a, o, b, ca, co, cb = claimsWorld(function(s) s.vc.tow = true end)
    local v = newVehicle(7, 4021, 102, 100)
    local truck = newVehicle(8, 4022, 100, 100)
    claim(co, v)
    local function hitch(p, va, vb)
        local c = W.clients[p.name]
        c.env.sendClientCommand(p, "vehicle", "attachTrailer", { vehicleA = va.id, vehicleB = vb.id, attachmentA = "trailer", attachmentB = "trailerfront" })
        advance(200)
    end
    hitch(b, truck, v)
    check("a tow on another's car comes straight off", truck.towed == nil and truck.broke == 1)
    check("the player is told", haloHas(cb, "UI_ZeD_Ex_No_tow:Aretha"))
    hitch(b, v, truck)
    check("nor can it pull", v.towed == nil and v.broke == 1)
    hitch(o, truck, v)
    check("the owner tows it", truck.towed == v and truck.broke == 1)
    truck.towed = nil
    hitch(a, truck, v)
    check("staff tow it", truck.towed == v)
    truck.towed = nil
    settings(ca, function(s) s.vc.tow = false end)
    hitch(b, truck, v)
    check("the tick off leaves the game's tow", truck.towed == v)
    W.server.Events.OnClientCommand.fire("vehicle", "startEngine", b, {})
    W.server.Events.OnClientCommand.fire("other", "attachTrailer", b, { vehicleA = 1 })
    check("other commands pass by", true)
    settings(ca, function(s) s.vc.tow = true end)
    local game = W.server.Events.OnClientCommand.list[1]
    W.server.Events.OnClientCommand.list[1] = function() end   -- (the game's handler would fall over first; this is ZeD's own test)
    W.server.Events.OnClientCommand.fire("vehicle", "attachTrailer", b, { vehicleA = "7", vehicleB = {} })
    W.server.Events.OnClientCommand.list[1] = game
    check("a client's junk never reaches a Java call: a word would match no overload", true)
end

section("release, and staff")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local r = press(cb, function(k) cb.E.release("v4021", k) end)
    check("another can't", r and r.ok == false and r.err == "perm")
    r = press(cb, function(k) cb.E.release("junk", k) end)
    check("a bad key", r and r.ok == false and r.err == "gone")
    r = press(ca, function(k) ca.E.release("v4021", k) end)
    check("staff can", r and r.ok == true)
    check("the line names whose", logHas("vehicle | release | Hermit | Aretha"))
    r = press(ca, function(k) ca.E.release("v4021", k) end)
    check("gone", r and r.ok == false and r.err == "gone")
    check("the slot is back", (claim(co, v) or {}).ok == true)
    r = press(co, function(k) co.E.release("v4021", k) end)
    check("the owner can, from anywhere", r and r.ok == true)
    check("the car's free", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
end

section("a burnt car's claim goes")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    v.burnt = true
    check("the wreck is anyone's", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
    check("the line", logHas("claim gone: burnt"))
    co.E.mineRows = nil
    co.E.mine()
    advance(1200)
    check("off my list", #co.E.mineRows == 0)
end

section("lapse")
do
    local a, o, b, ca, co, cb = claimsWorld(function(s) s.vc.lapse = 2 end)
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    advance(3000)
    -- away: off the server
    for i, p in ipairs(W.online) do if p == o then table.remove(W.online, i) end end
    co.up = false
    advance(310000)
    check("a day away holds", (function()
        W.clock = W.clock + 86400000
        advance(310000)
        return act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false
    end)())
    W.clock = W.clock + 86400000
    advance(310000)
    check("the claim lapses", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
    check("the line", logHas("claim lapsed"))
    W.online[#W.online + 1] = o
    co.up = true
    check("the slot is back", (claim(co, v) or {}).ok == true)
    W.clock = W.clock + 3 * 86400000
    advance(310000)
    check("online keeps a claim however long", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
end

section("off for a month, on again: the time starts again")
do
    local a, o, b, ca, co, cb = claimsWorld(function(s) s.vc.lapse = 2 end)
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    for i, p in ipairs(W.online) do if p == o then table.remove(W.online, i) end end
    settings(ca, function(s) s.vc.on = false end)
    W.clock = W.clock + 30 * 86400000
    advance(1000)
    settings(ca, function(s) s.vc.on = true end)
    advance(310000)
    check("the claim holds", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
end

section("the faction switch")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    W.factions.Kade = { getOwner = function() return "Aretha" end, getPlayers = function() return jlist({ "Kade" }) end }
    check("off: a fellow is another", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    W.server.ZeD.Ex.CLAIM_SHARE_FACTION = true
    check("on: a fellow passes", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
    W.server.ZeD.Ex.CLAIM_SHARE_FACTION = false
end

-- ---------------------------------------------------------------------------
-- SAFEHOUSE PROTECTION
-- ---------------------------------------------------------------------------
local function safeWorld(extra)
    world()
    local a = player("Hermit", "admin", 900, 900)
    local o = player("Aretha", "user", 500, 500)
    local m = player("Rosa", "user", 500, 500)
    local b = player("Kade", "user", 500, 500)
    local ca, co, cm, cb = clientJoin(a), clientJoin(o), clientJoin(m), clientJoin(b)
    local h = newSafe(500, 500, 10, 10, "Aretha", { "Rosa" })
    settings(ca, function(s)
        s.sp.on = true
        if extra then extra(s) end
    end)
    return a, o, m, b, ca, co, cm, cb, h
end
local function thing(x, y) return door(square(x, y), 500) end

section("no dismantling, no destroying")
do
    local a, o, m, b, ca, co, cm, cb, h = safeWorld()
    local d = thing(503, 503)
    W.ran = {}
    check("a stranger can't dismantle", act("ISDismantleAction", { character = b, thumpable = d }) == false)
    check("nor scrap furniture", act("ISMoveablesAction", { character = b, square = d.sq, mode = "scrap" }) == false)
    check("nor pry off a barricade", act("ISUnbarricadeAction", { character = b, item = d }) == false)
    check("nor swing a sledgehammer", act("ISDestroyStuffAction", { character = b, item = d }) == false)
    check("none of the game's functions ran", W.ran.ISDismantleAction == nil and W.ran.ISMoveablesAction == nil and W.ran.ISDestroyStuffAction == nil)
    check("picking furniture up isn't scrapping", act("ISMoveablesAction", { character = b, square = d.sq, mode = "pickup" }) == true)
    check("the owner can", act("ISDismantleAction", { character = o, thumpable = d }) == true)
    check("a member can", act("ISDestroyStuffAction", { character = m, item = d }) == true)
    check("staff can", act("ISDestroyStuffAction", { character = a, item = d }) == true)
    local out = thing(600, 600)
    check("elsewhere is the game's", act("ISDestroyStuffAction", { character = b, item = out }) == true)
    advance(200)
    check("the player is told whose", haloHas(cb, "UI_ZeD_Ex_No_dismantle:Aretha"))
    check("the line", logHas("safehouse | refused: dismantle | Kade | Aretha"))
    check("no suspicion", W.suspicious == 0)
    settings(ca, function(s) s.sp.dismantle = false end)
    check("each tick its own: dismantle off", act("ISDismantleAction", { character = b, thumpable = d }) == true)
    check("each tick its own: destroy on", act("ISDestroyStuffAction", { character = b, item = d }) == false)
    settings(ca, function(s) s.sp.dismantle, s.sp.destroy = true, false end)
    check("each tick its own: destroy off", act("ISDestroyStuffAction", { character = b, item = d }) == true)
    check("each tick its own: dismantle on", act("ISDismantleAction", { character = b, thumpable = d }) == false)
end

section("the lot")
do
    local a, o, m, b, ca, co, cm, cb, h = safeWorld()
    local tiles = W.server.ZeD.Ex.LOT_TILES
    local function refused(x, y) return act("ISDestroyStuffAction", { character = b, item = thing(x, y) }) == false end
    check("inside the walls", refused(500, 500))
    check("the last tile of the lot, north west", refused(500 - tiles, 500 - tiles))
    check("the first tile past it", not refused(500 - tiles - 1, 500))
    check("the last tile of the lot, south east", refused(509 + tiles, 509 + tiles))
    check("the first tile past it", not refused(510 + tiles, 509))
    settings(ca, function(s) s.sp.lot = false end)
    check("lot off: the walls only", not refused(499, 500) and refused(500, 500) and not refused(510, 505))
end

section("two lots that touch, and a war")
do
    local a, o, m, b, ca, co, cm, cb, h = safeWorld()
    local h2 = newSafe(514, 500, 10, 10, "Kade")
    check("a member at their own fence passes", act("ISDestroyStuffAction", { character = b, item = thing(512, 505) }) == true)
    check("but not in the other house", act("ISDestroyStuffAction", { character = b, item = thing(505, 505) }) == false)
    W.wars[h.onlineId .. ":Kade"] = true
    check("a war the game has started lets the attacker through", act("ISDestroyStuffAction", { character = b, item = thing(505, 505) }) == true)
end

section("swings")
do
    local a, o, m, b, ca, co, cm, cb, h = safeWorld()
    local hit = function(chr, n, obj)
        W.server.Events.OnWeaponHitThumpable.fire(chr, weapon(n), obj)
        -- the game's damage after the event, at its worst (IsoDoor.WeaponHit: door damage x 2 x 1.7, and a 1 in 10 x 6 x 1.7 on top)
        obj.health = obj.health - math.floor(n * 13.6)
    end
    local d = thing(503, 503)
    hit(b, 30, d)
    check("the door stands through the swing", d.health > 0, d.health)
    advance(200)
    check("back to its health on the next tick", d.health == 500, d.health)
    local weak = door(square(503, 504), 3)
    hit(b, 100, weak)
    check("a nearly broken door doesn't break", weak.health > 0, weak.health)
    advance(200)
    check("and stays as it was", weak.health == 3, weak.health)
    local bar = door(square(503, 505), 300, "IsoBarricade")
    hit(b, 30, bar)
    advance(200)
    check("a barricade the same", bar.health == 300)
    local built = door(square(503, 506), 300, "IsoThumpable")
    hit(b, 30, built)
    advance(200)
    check("a built wall the same", built.health == 300)
    local other = door(square(503, 507), 300, "IsoWindow")
    hit(b, 10, other)
    advance(200)
    check("a window isn't covered, and the card says so", other.health == 300 - 136)
    d = thing(503, 503)
    hit(o, 30, d)
    advance(200)
    check("the owner's swing lands", d.health == 500 - 408, d.health)
    hit({ class = "IsoZombie" }, 30, thing(503, 503))
    advance(200)
    check("a zombie's a matter for the game", true)
    settings(ca, function(s) s.sp.destroy = false end)
    d = thing(503, 503)
    hit(b, 30, d)
    advance(200)
    check("the tick off lets it land", d.health == 500 - 408)
end

-- ---------------------------------------------------------------------------
-- THE MAP
-- ---------------------------------------------------------------------------
section("the map's teleport")
do
    world()
    local a = player("Hermit", "admin")
    local m = player("Rosa", "mod")
    local b = player("Kade", "user")
    local ca, cm, cb = clientJoin(a), clientJoin(m), clientJoin(b)
    settings(ca, function(s) s.tp.on = true end)
    local r = press(cm, function(k) cm.E.goTo(6402, 5410, k) end)
    check("a role with the power goes", r and r.ok == true)
    check("the game's own command does the going", cm.commands[1] == "/teleportto 6402,5410,0", cm.commands[1])
    check("logged", logHas("admin | map teleport | Rosa") and logHas("6402,5410"))
    r = press(cb, function(k) cb.E.goTo(6402, 5410, k) end)
    check("a player can't", r and r.ok == false and r.err == "perm" and #cb.commands == 0)
    r = press(cm, function(k) cm.E.goTo(-5, 5410, k) end)
    check("off the map", r and r.ok == false and #cm.commands == 1)
    settings(ca, function(s) s.tp.on = false end)
    r = press(cm, function(k) cm.E.goTo(6402, 5410, k) end)
    check("the setting off refuses", r and r.ok == false and r.err == "off" and #cm.commands == 1)
end

-- ---------------------------------------------------------------------------
-- THE CONTAINER LOG
-- ---------------------------------------------------------------------------
local function take(c, p, sq, names, mine)
    local items = {}
    for _, n in ipairs(names) do items[#items + 1] = { getDisplayName = function() return n end } end
    local src = { isInCharacterInventory = function() return mine == true end, getSourceGrid = function() return sq end, getType = function() return "crate" end }
    local dest = { isInCharacterInventory = function() return true end }
    c.env.ISInventoryTransferAction.perform({ srcContainer = src, destContainer = dest, character = p, queueList = { { items = items } } })
end

section("the container log")
do
    world()
    local a = player("Hermit", "admin", 900, 900)
    local b = player("Kade", "user", 503, 503)
    local ca, cb = clientJoin(a), clientJoin(b)
    newSafe(500, 500, 10, 10, "Aretha")
    settings(ca, function(s) s.cl.on = true end)
    check("the wrap goes on when the server says so", cb.E.logArmed == true)
    local n = cb.env.ISInventoryTransferAction.calls
    take(cb, b, square(503, 503), { "Nails", "Nails", "Hammer" })
    check("the game's transfer runs", cb.env.ISInventoryTransferAction.calls == n + 1)
    take(cb, b, square(503, 503), { "Nails" })
    advance(1000)
    check("a burst waits", not logHas("container | took"))
    advance(3000)
    check("one line for the burst", logCount("container | took") == 1, logCount("container | took"))
    check("who took what, and whose word it is", logHas("3 x Nails, 1 x Hammer from crate (reported by their game)"))
    check("where, and from what", logHas("crate") and logHas("503,503,0"))
    W.logs = {}
    cb.sent = {}
    take(cb, b, square(700, 700), { "Nails" })
    advance(4000)
    check("outside a safehouse there's no report", not sawCommand(cb, "x_took"))
    take(cb, b, square(503, 503), { "Nails" }, true)
    advance(4000)
    check("your own bags aren't a take", not sawCommand(cb, "x_took"))
    -- a client's word is tested
    local function report(args) cb.env.sendClientCommand(b, "ZeDX", "x_took", args); advance(1200) end
    report({ x = 700, y = 700, z = 0, rows = { { name = "Lies", n = 1 } } })
    check("a report from outside a safehouse is dropped", not logHas("Lies"))
    report({ x = 505, y = 505, z = 0, rows = { { name = "Lies", n = 1 } } })
    check("a report of here, from here, is logged", logHas("Lies"))
    W.logs = {}
    b.x, b.y = 100, 100
    report({ x = 505, y = 505, z = 0, rows = { { name = "Lies", n = 1 } } })
    check("a report from across the map is dropped", not logHas("Lies"))
    b.x, b.y = 503, 503
    report({ x = 505, y = 505, z = 0, rows = { { name = "Lies", n = -1 } } })
    report({ x = 505, y = 505, z = 0, rows = "junk" })
    report({ x = "505", y = 505, z = 0, rows = { { name = "Lies", n = 1 } } })
    check("bad reports are dropped", not logHas("Lies"))
    report({ x = 505, y = 505, z = 0, rows = { { name = "a | b", n = 1 } } })
    check("a name can't pass for a field", logHas("a / b"))
    settings(ca, function(s) s.cl.on = false end)
    W.logs = {}
    cb.sent = {}
    take(cb, b, square(503, 503), { "Nails" })
    advance(4000)
    check("off: nothing sent", not sawCommand(cb, "x_took"))
end

-- ---------------------------------------------------------------------------
-- THE REST
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- THE REVIEW'S CASES
-- ---------------------------------------------------------------------------
section("siphoning: no gas moves for someone a claim stops")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local cls = W.server.ISTakeGasolineFromVehicle
    local function siphon(chr)
        local tank = { litres = 20, can = 0 }
        local act1 = setmetatable({ character = chr, vehicle = v, tank = tank }, cls)
        for _ = 1, 9 do act1:animEvent("update") end
        act1:animEvent("somethingElse")
        return tank, act1
    end
    W.logs = {}
    local tank, act1 = siphon(b)
    check("the tank keeps its gas", tank.litres == 20, tank.litres)
    check("the can stays empty", tank.can == 0, tank.can)
    check("complete() refuses too", act1:complete() == false)
    check("one line for the whole action", logCount("refused: parts") == 1, logCount("refused: parts"))
    advance(200)
    check("the player is told", haloHas(cb, "UI_ZeD_Ex_No_parts:Aretha"))
    tank = siphon(o)
    check("the owner siphons", tank.litres == 11 and tank.can == 9, tank.litres)
    tank = siphon(a)
    check("staff siphon", tank.litres == 11)
    settings(ca, function(s) s.vc.parts = false end)
    tank = siphon(b)
    check("the tick off lets the game's event run", tank.litres == 11)
end

section("a tow can't hide behind a number the game accepts")
do
    local a, o, b, ca, co, cb = claimsWorld(function(s) s.vc.tow = true end)
    local Ex = W.server.ZeD.Ex
    check("a whole id", Ex.vehId(17) == 17)
    check("past the short", Ex.vehId(17 + 65536) == 17)
    check("below it", Ex.vehId(17 - 65536) == 17)
    check("a fraction truncates", Ex.vehId(17.9) == 17 and Ex.vehId(-1.9) == -1)
    check("the top of the short wraps", Ex.vehId(65535) == -1 and Ex.vehId(32768) == -32768)
    check("past the int", Ex.vehId(1e300) == -1 and Ex.vehId(-1e300) == 0)
    check("not a number", Ex.vehId(0 / 0) == 0)
    check("a word isn't a number", Ex.vehId("7") == nil and Ex.vehId(nil) == nil)
    local v = newVehicle(7, 4021, 102, 100)
    local truck = newVehicle(8, 4022, 100, 100)
    claim(co, v)
    for _, id in ipairs({ 7 + 65536, 7 + 131072, 7 - 65536, 7.5 }) do
        truck.towed, truck.broke = nil, 0
        cb.env.sendClientCommand(b, "vehicle", "attachTrailer", { vehicleA = truck.id, vehicleB = id, attachmentA = "trailer", attachmentB = "trailerfront" })
        advance(200)
        check("the game's hitch on " .. tostring(id) .. " comes off", truck.towed == nil and truck.broke == 1, truck.broke)
    end
end

section("vehicle.startEngine, with no action around it")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    b.vehicle, v.driver = v, b
    W.logs = {}
    local function start(c, p)
        v.starting, v.shut = false, 0
        c.env.sendClientCommand(p, "vehicle", "startEngine", {})
        advance(150)
    end
    start(cb, b)
    check("shut off at once, not at the next poll", v.shut == 1, v.shut)
    check("said and logged", logCount("refused: drive") == 1)
    v.driver, b.vehicle = o, nil
    o.vehicle = v
    start(co, o)
    check("the owner's starts", v.starting == true and v.shut == 0)
    o.vehicle, v.driver = nil, b
    b.vehicle = v
    settings(ca, function(s) s.vc.drive = false end)
    start(cb, b)
    check("the tick off leaves it", v.starting == true and v.shut == 0)
end

section("a scrap is judged by the object, not the square a client names")
do
    local a, o, m, b, ca, co, cm, cb, h = safeWorld()
    local d = thing(503, 503)
    local free = square(600, 600)
    W.ran = {}
    check("in the house, from a square outside", act("ISMoveablesAction", { character = b, square = free, mode = "scrap", object = d, moveProps = { object = d } }) == false)
    check("moveProps with no object falls back", act("ISMoveablesAction", { character = b, square = free, mode = "scrap", object = d, moveProps = {} }) == false)
    check("no object at all", act("ISMoveablesAction", { character = b, square = free, mode = "scrap" }) == false)
    check("the game's function did not run", W.ran.ISMoveablesAction == nil)
    check("outside, named from inside", act("ISMoveablesAction", { character = b, square = d.sq, mode = "scrap", object = thing(600, 600) }) == true)
end

section("a neighbor's lot doesn't open another house's walls")
do
    local a, o, m, b, ca, co, cm, cb, h = safeWorld()
    newSafe(513, 500, 10, 10, "Kade")    -- (three tiles off: its lot covers Aretha's east side)
    W.server.ZeD.Srv.X.swing(b, weapon(10), thing(509, 505))
    check("inside her walls, on his lot", act("ISDestroyStuffAction", { character = b, item = thing(509, 505) }) == false)
    check("nor dismantled", act("ISDismantleAction", { character = b, thumpable = thing(509, 505) }) == false)
    check("nor his neighbor's door by the swing", (function()
        local d = thing(509, 505)
        W.server.Events.OnWeaponHitThumpable.fire(b, weapon(10), d)
        return d.health > 500
    end)())
    check("between the houses he passes", act("ISDestroyStuffAction", { character = b, item = thing(511, 505) }) == true)
    check("and she passes too", act("ISDestroyStuffAction", { character = o, item = thing(511, 505) }) == true)
    check("in his own walls he passes", act("ISDestroyStuffAction", { character = b, item = thing(515, 505) }) == true)
    check("she can't come in", act("ISDestroyStuffAction", { character = o, item = thing(515, 505) }) == false)
    advance(200)
end

section("no claim on a car at someone else's safehouse")
do
    local a, o, b, ca, co, cb = claimsWorld()
    newSafe(100, 100, 10, 10, "Aretha", { "Rosa" })
    b.x, b.y = 97, 97
    local inside = newVehicle(7, 4021, 101, 101)
    local yard = newVehicle(8, 4022, 96, 96)
    local street = newVehicle(9, 4023, 94, 94)
    local r = claim(cb, inside)
    check("inside the walls", r and r.ok == false and r.err == "house", r and r.err)
    r = claim(cb, yard)
    check("on the lot, with protection off", r and r.ok == false and r.err == "house", r and r.err)
    check("past the lot is the street", (claim(cb, street) or {}).ok == true)
    o.x, o.y = 100, 100
    check("the owner claims her own", (claim(co, inside) or {}).ok == true)
    local r2 = player("Rosa", "user", 100, 100)
    local cr = clientJoin(r2)
    check("a member too", (claim(cr, yard) or {}).ok == true)
end

section("a number the game gave to a new car isn't the old claim")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local old = newVehicle(7, 4021, 102, 100)
    claim(co, old)
    W.logs = {}
    W.vehicles[7] = nil
    local van = newVehicle(9, 4021, 102, 101, "Base.Van")
    check("the new car is anyone's", act("ISUninstallVehiclePart", { character = b, vehicle = van }) == true)
    check("the line", logHas("claim gone: that car is gone"))
    advance(200)
    check("the owner's list follows", co.E.mineRows ~= nil and #co.E.mineRows == 0)
    check("the slot is back", (claim(co, van) or {}).ok == true)
    check("and it can be claimed", act("ISUninstallVehiclePart", { character = b, vehicle = van }) == false)
    -- the stamp lives on the car, so a restart keeps a claim on the same car
    W.server = nil
    serverStart()
    check("the same car holds its claim", act("ISUninstallVehiclePart", { character = b, vehicle = van }) == false)
    local other = newVehicle(10, 4021, 102, 101, "Base.Van")
    check("after a restart a new car still isn't it", act("ISUninstallVehiclePart", { character = b, vehicle = other }) == true)
end

-- what a client's vehicle:transmitModData() does to the server's copy (ObjectModDataPacket.parse): the same table, wiped by
-- KahluaTableImpl.load, then the client's rows; an empty table is sent as no data, and takes the wipe branch
local function clientSendsModData(v, rows)
    for k in pairs(v.md) do v.md[k] = nil end
    for k, x in pairs(rows or {}) do v.md[k] = x end
end
local function claimRow(v)
    for _, md in pairs(W.moddata) do
        if md.claims then return md.claims[W.server.ZeD.Ex.keyOf(v.sql)] end
    end
end

section("a client's send of the car's mod data doesn't lose the claim")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local c = claimRow(v)
    check("the claim keeps the car's key number", c.kid == v.keyId and c.tok ~= nil)
    W.logs = {}
    -- a dashboard mod on someone's client, which never had the stamp
    clientSendsModData(v, { RetroDash = { odometer = 12 } })
    check("the stamp is gone", v.md.ZeDClaim == nil)
    check("the car stays claimed", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    check("no claim gone line", not logHas("claim gone"))
    check("the stamp is back", v.md.ZeDClaim == c.tok)
    check("the client's rows stay", v.md.RetroDash.odometer == 12)
    advance(200)
    check("the owner's list is untouched", co.E.mineRows == nil or #co.E.mineRows == 1)
    check("the count is untouched", claimRow(v) == c and W.server.ZeD.Srv.X.counts.Aretha == 1)
    -- a send with nothing in it, the same again, and a restart on top
    clientSendsModData(v, nil)
    W.server = nil
    serverStart()
    check("a wiped car holds its claim over a restart", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    check("no claim gone line after the restart", not logHas("claim gone"))
    check("the put-back stamp isn't sent to the clients", v.transmits == nil, v.transmits)
end

section("the reused number stays handled, with a client's send in the way")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local old = newVehicle(7, 4021, 102, 100)
    claim(co, old)
    W.logs = {}
    W.vehicles[7] = nil
    local van = newVehicle(9, 4021, 102, 101, "Base.Van")
    clientSendsModData(van, { RetroDash = { odometer = 1 } })
    check("a new car with a client's rows is anyone's", act("ISUninstallVehiclePart", { character = b, vehicle = van }) == true)
    check("the line", logHas("claim gone: that car is gone"))
    check("the new car gets no stamp", van.md.ZeDClaim == nil)
end

section("a new lock on a claimed car")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local c = claimRow(v)
    W.logs = {}
    -- (Locksmith, on the server: vehicle:setKeyId)
    v.keyId = 55555
    check("the stamp holds it", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    check("the claim takes the new number", c.kid == 55555)
    clientSendsModData(v, nil)
    check("and the new number holds it from then on", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    check("no claim gone line", not logHas("claim gone"))
    -- both between two looks at the car: nothing is left to tell it by. The claim goes, as a lost car's does
    v.keyId = 66666
    clientSendsModData(v, nil)
    check("both lost at once: the claim goes", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
    check("and says so", logHas("claim gone: that car is gone"))
end

section("a car parked after its driver's send")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local c = claimRow(v)
    local T = W.server.ZeD.Srv.X
    W.logs = {}
    o.vehicle, v.driver = v, o
    advance(2100)
    check("a driven car is on the list", T.driven[W.server.ZeD.Ex.keyOf(v.sql)] ~= nil)
    -- RetroDashboardDigital's setVehicle(nil): the send comes as the driver gets out, and it lands after the last look at them
    o.vehicle, v.driver = nil, nil
    advance(2100)
    clientSendsModData(v, { RetroDash = { odometer = 13 } })
    check("the send took the stamp", v.md.ZeDClaim == nil)
    advance(2100)
    check("with no driver and no tab the stamp is back", v.md.ZeDClaim == c.tok)
    check("the client's rows stay", v.md.RetroDash.odometer == 13)
    check("not sent to the clients", v.transmits == nil, v.transmits)
    -- a new lock from outside, with nobody looking at the car (Locksmith's repinVehicle, on the server)
    v.keyId = 77777
    advance(30000)
    check("the claim stays through a new lock", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    check("it takes the new number", c.kid == 77777)
    check("no claim gone line", not logHas("claim gone"))
    check("the list empties", T.driven[W.server.ZeD.Ex.keyOf(v.sql)] == nil)
    -- past the looks a send and a new lock together are the known limit: nothing can tell the car
    clientSendsModData(v, { RetroDash = { odometer = 14 } })
    advance(4000)
    check("no look past the last poll", v.md.ZeDClaim == nil)
    v.keyId = 88888
    check("the limit: both lost on a parked car, the claim goes", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
    check("and says so", logHas("claim gone: that car is gone"))
end

-- ZeD's own dash (ZeD_Dashboard:_odoSend, punch list 94): the driver's client sends a command with the car's figures, never
-- the car's mod data, and the server writes the three keys into its own copy, sends the three figures to the other seats
-- and sends the car out only at the coarse moments
local function odoSend(c, args)
    c.env.ZeD.ServerPart.send(c.env.ZeD.DashProto.MOD, c.env.ZeD.DashProto.ODO, args)
    advance(600)                                       -- (under the general limit: ten commands in 5 s)
end
local function others(md)
    local t = {}
    for k, x in pairs(md) do
        if k ~= "ZeD_odo" and k ~= "ZeD_trip" and k ~= "ZeD_odoTrip" then t[k] = x end
    end
    return t
end
local function sameRows(a, b)
    for k, x in pairs(a) do if b[k] ~= x then return false end end
    for k, x in pairs(b) do if a[k] ~= x then return false end end
    return true
end

section("ZeD's own dash: the driver's odometer command")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local c = claimRow(v)
    local rw = { odo = 812.4 }
    v.md.Roadworthy = rw                               -- (a key another mod keeps only on the server's copy)
    local keep = others(v.md)
    W.logs = {}
    -- what each client hears on the dash's module: the figures to the car's other seats (DP.FIG)
    local heard = {}
    for _, cl in ipairs({ ca, co, cb }) do
        local who = cl.p.name
        cl.env.ZeD.ServerPart.on(cl.env.ZeD.DashProto.MOD, function(command, a) heard[#heard + 1] = { who = who, command = command, a = a } end)
    end
    local function figsTo(who)
        local n, last = 0, nil
        for _, h in ipairs(heard) do if h.who == who and h.command == "fig" then n, last = n + 1, h.a end end
        return n, last
    end
    o.vehicle, v.driver = v, o
    b.vehicle, v.seats[1] = v, b                       -- (a passenger: the only other player who sees this dash)
    v.running = true
    odoSend(co, { veh = 7, odo = 41000.1, trip = 0.1, show = false, save = true })
    check("the driver's command: the odometer written", v.md.ZeD_odo == 41000.1 and v.md.ZeD_trip == 0.1 and v.md.ZeD_odoTrip == false)
    check("a first mileage: sent out from the server", v.transmits == 1, v.transmits)
    check("the claim's stamp stays", v.md.ZeDClaim == c.tok)
    check("the other mod's key stays, the same table", v.md.Roadworthy == rw and rw.odo == 812.4)
    check("nothing but the three keys changed", sameRows(keep, others(v.md)))
    local nb, fb = figsTo("Kade")
    check("the passenger gets the figures", nb == 1 and fb.veh == 7 and fb.odo == 41000.1 and fb.trip == 0.1 and fb.show == false, nb)
    check("only the three figures and the car", fb and fb.Roadworthy == nil and fb.ZeDClaim == nil and fb.save == nil)
    check("the driver gets no figures back", figsTo("Aretha") == 0, figsTo("Aretha"))
    check("someone not in the car gets none", figsTo("Hermit") == 0, figsTo("Hermit"))
    for i = 2, 5 do
        odoSend(co, { veh = 7, odo = 41000 + i / 10, trip = i / 10, show = false, save = false })
        check("driving, send " .. i .. ": written, the stamp and the other key stay",
            v.md.ZeD_odo == 41000 + i / 10 and v.md.ZeDClaim == c.tok and v.md.Roadworthy == rw)
    end
    check("driving: no transmitModData every tenth of a mile", v.transmits == 1, v.transmits)
    nb, fb = figsTo("Kade")
    check("driving: the passenger gets each tenth", nb == 5 and fb.odo == 41000.5 and fb.trip == 0.5, nb)
    check("driving: still nothing to the driver or the bystander", figsTo("Aretha") == 0 and figsTo("Hermit") == 0)
    local n = v.transmits
    odoSend(co, { veh = 7, odo = 41000.5, trip = 0.5, show = false })
    check("the same figures again: nothing to send out", v.transmits == n and figsTo("Kade") == 5, v.transmits - n)
    -- the switch and a reset: presses, sent out
    odoSend(co, { veh = 7, odo = 41000.5, trip = 0.5, show = true, save = true })
    check("the window's switch: sent out", v.md.ZeD_odoTrip == true and v.transmits == n + 1, v.transmits - n)
    nb, fb = figsTo("Kade")
    check("and the passenger's window follows", nb == 6 and fb.show == true, nb)
    odoSend(co, { veh = 7, odo = 41000.5, trip = 0, show = true, save = true })
    check("a trip reset: sent out", v.md.ZeD_trip == 0 and v.md.ZeD_odo == 41000.5 and v.transmits == n + 2, v.transmits - n)
    odoSend(co, { veh = 7, odo = 41000.6, trip = 0.1, show = true })
    check("and the trip counts on from 0, not sent out", v.md.ZeD_trip == 0.1 and v.md.ZeD_odo == 41000.6 and v.transmits == n + 2)
    -- a press whose save flag was lost: the server sees the switch move itself
    odoSend(co, { veh = 7, odo = 41000.6, trip = 0.1, show = false })
    check("a switch with no save flag: sent out all the same", v.md.ZeD_odoTrip == false and v.transmits == n + 3, v.transmits - n)
    odoSend(co, { veh = 7, odo = 41000.65, trip = 0.15, show = true, save = true })
    -- a reset whose command was lost, then the next send: the trip back down, no further than the miles since
    v.md.ZeD_trip = 5
    n = v.transmits
    odoSend(co, { veh = 7, odo = 41000.7, trip = 0.05, show = true })
    check("a reset in between: taken", v.md.ZeD_trip == 0.05 and v.md.ZeD_odo == 41000.7)
    check("and sent out (the trip went down)", v.transmits == n + 1, v.transmits - n)
    -- the engine stops: the last miles, sent out; a second save with nothing new isn't
    v.running = false
    odoSend(co, { veh = 7, odo = 41000.72, trip = 0.07, show = true, save = true })
    check("the engine off: sent out", v.md.ZeD_odo == 41000.72 and v.transmits == n + 2, v.transmits - n)
    odoSend(co, { veh = 7, odo = 41000.72, trip = 0.07, show = true, save = true })
    check("the same again: nothing new to send out", v.transmits == n + 2, v.transmits - n)
    -- the car stopped with the engine on, figures taken; then the engine off with no new miles: what was taken goes out
    v.running = true
    odoSend(co, { veh = 7, odo = 41000.74, trip = 0.09, show = true })
    check("a stop with the engine on: not sent out", v.transmits == n + 2, v.transmits - n)
    v.running = false
    odoSend(co, { veh = 7, odo = 41000.74, trip = 0.09, show = true, save = true })
    check("the engine off, nothing new since: the taken figures go out", v.transmits == n + 3, v.transmits - n)
    -- the engine off seen by the server, the flag lost
    odoSend(co, { veh = 7, odo = 41000.75, trip = 0.1, show = true })
    check("the engine off, no flag: the server sees it, sent out", v.transmits == n + 4, v.transmits - n)
    -- a passenger's ask as they sit down (DP.ASK, ZeD_Dashboard:_odoAsk): a car stopped with its engine on sends no
    -- figures, so the server answers with its own, to the asker alone
    local function ask(c, args)
        c.env.ZeD.ServerPart.send(c.env.ZeD.DashProto.MOD, c.env.ZeD.DashProto.ASK, args)
        advance(600)
    end
    advance(1000)
    local k0, tx0 = figsTo("Kade"), v.transmits
    ask(cb, { veh = 7 })
    nb, fb = figsTo("Kade")
    check("a passenger's ask: the server's figures, to them", nb == k0 + 1 and fb.veh == 7 and fb.odo == v.md.ZeD_odo
        and fb.trip == v.md.ZeD_trip and fb.show == v.md.ZeD_odoTrip, nb - k0)
    check("an ask: the three figures and the car only", fb and fb.Roadworthy == nil and fb.ZeDClaim == nil and fb.save == nil)
    check("an ask sends the car out to nobody", v.transmits == tx0 and figsTo("Aretha") == 0 and figsTo("Hermit") == 0,
        v.transmits - tx0)
    ask(cb, { veh = 7 })
    check("a second ask inside a second: no answer", figsTo("Kade") == k0 + 1, figsTo("Kade") - k0)
    advance(1000)
    ask(co, { veh = 7 })
    ask(ca, { veh = 7 })
    check("the driver's ask, a bystander's: no answer", figsTo("Aretha") == 0 and figsTo("Hermit") == 0)
    advance(1000)
    ask(cb, { veh = 9 })
    check("an ask for a car that isn't there: no answer", figsTo("Kade") == k0 + 1, figsTo("Kade") - k0)
    local bare = newVehicle(8, 4022, 104, 100)
    b.vehicle, bare.seats[1] = bare, b
    advance(1000)
    ask(cb, { veh = 8 })
    check("an ask in a car with no figures yet: no answer", figsTo("Kade") == k0 + 1 and bare.md.ZeD_odo == nil,
        figsTo("Kade") - k0)
    b.vehicle, bare.seats[1] = v, nil
    advance(1000)
    ask(cb, { veh = 7 })
    check("back in the car, asked again: answered", figsTo("Kade") == k0 + 2, figsTo("Kade") - k0)
    v.running = true
    b.vehicle, v.seats[1] = nil, nil
    nb = figsTo("Kade")
    odoSend(co, { veh = 7, odo = 41000.76, trip = 0.11, show = true })
    check("out of the car: the old passenger hears no more", figsTo("Kade") == nb, figsTo("Kade") - nb)
    check("no bad-arguments line for any of it", not logHas("bad arguments"))
    odoSend(co, { veh = 7, odo = 41000.8, trip = 0.15, show = true, save = "yes" })
    check("junk: the save flag not a boolean", v.md.ZeD_odo == 41000.76 and logHas("bad arguments"))
    W.logs = {}
    nb = figsTo("Hermit")
    advance(1000)
    ask(ca, { veh = "seven" })
    check("junk: an ask without a car's number", logHas("bad arguments") and figsTo("Hermit") == nb)
    W.logs = {}

    -- refused: the odometer going back, a trip going further than the odometer, or down further than a reset allows
    local function refused(args, name)
        local was, n0 = others(v.md), v.transmits
        local o0, t0, s0 = v.md.ZeD_odo, v.md.ZeD_trip, v.md.ZeD_odoTrip
        odoSend(co, args)
        check(name, v.md.ZeD_odo == o0 and v.md.ZeD_trip == t0 and v.md.ZeD_odoTrip == s0 and v.transmits == n0
            and sameRows(was, others(v.md)), tostring(v.md.ZeD_odo) .. " / " .. tostring(v.md.ZeD_trip))
    end
    -- the server's answer to its driver (DP.SYNC): heard on the client, through the link's route for the dash's module
    local syncs = {}
    co.env.ZeD.ServerPart.on(co.env.ZeD.DashProto.MOD, function(command, a) syncs[#syncs + 1] = { command = command, a = a } end)
    cb.env.ZeD.ServerPart.on(cb.env.ZeD.DashProto.MOD, function(command, a) syncs[#syncs + 1] = { command = command, a = a, b = true } end)
    refused({ veh = 7, odo = 41000.2, trip = 0.05, show = true }, "the odometer never goes back")
    local s1 = syncs[1]
    check("the driver refused as behind: the server's figures go back to them", #syncs == 1 and s1.command == "sync"
        and s1.a.veh == 7 and s1.a.odo == 41000.76 and s1.a.trip == 0.11 and s1.a.sent == 41000.2, #syncs)
    refused({ veh = 7, odo = 41000.8, trip = 3, show = true }, "the trip can't count more than the odometer did")
    local s2 = syncs[2]
    check("a trip the server can't take: its figures go back too", #syncs == 2 and s2.a.odo == 41000.76
        and s2.a.trip == 0.11 and s2.a.sent == 41000.8, #syncs)
    -- the driver's next send from the server's figures (ZeD_Dashboard:_odoSync: the trip from the server's, plus the miles)
    odoSend(co, { veh = 7, odo = 41000.9, trip = 0.11 + (41000.9 - 41000.76), show = true })
    check("the send after that answer is taken", v.md.ZeD_odo == 41000.9 and math.abs(v.md.ZeD_trip - 0.25) < 1e-6, v.md.ZeD_trip)
    check("no answer for a send that's taken", #syncs == 2, #syncs)
    -- someone not at the wheel is refused without an answer
    odoSend(cb, { veh = 7, odo = 41000.1, trip = 0, show = true })
    check("a send from someone not driving: refused, no answer", v.md.ZeD_odo == 41000.9 and #syncs == 2, #syncs)
    W.logs = {}
    refused({ veh = 7, odo = "41001", trip = 0, show = true }, "junk: a string for the miles")
    refused({ veh = 7, odo = 0 / 0, trip = 0, show = true }, "junk: not a number")
    refused({ veh = 7, odo = 1 / 0, trip = 0, show = true }, "junk: infinite")
    refused({ veh = 7, odo = 1e9, trip = 0, show = true }, "junk: past any odometer")
    refused({ veh = 7, odo = 41001, trip = -1, show = true }, "junk: a trip below 0")
    refused({ veh = 7, odo = 41001, trip = 50000, show = true }, "junk: a trip past the odometer")
    refused({ veh = 7, odo = 41001, trip = 0.3, show = "yes" }, "junk: the switch not a boolean")
    refused({ veh = 7.5, odo = 41001, trip = 0.3, show = true }, "junk: a car's number not whole")
    refused({ odo = 41001, trip = 0.3, show = true }, "junk: no car")
    check("junk is logged as bad arguments", logHas("bad arguments"))
    check("junk gets no answer", #syncs == 2, #syncs)
    odoSend(co, { veh = 99, odo = 41001, trip = 0.3, show = true })
    check("a car that isn't there: nothing, no error", not logHas("handler failed"))

end

section("ZeD's own dash: only the driver, and the driver just out")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    v.md.Roadworthy = { odo = 3 }
    o.vehicle, v.driver = v, o
    v.running = true                                   -- (the engine on: only a coarse moment sends the car out)
    odoSend(co, { veh = 7, odo = 500.1, trip = 0.1, show = false })
    check("the driver's first send", v.md.ZeD_odo == 500.1)
    odoSend(co, { veh = 7, odo = 500.15, trip = 0.15, show = false })
    local n = v.transmits
    check("a first mileage sent out, the next tenth not", n == 1, n)
    -- someone standing by, and a passenger
    odoSend(cb, { veh = 7, odo = 900, trip = 0.2, show = true })
    check("someone not in the car: refused", v.md.ZeD_odo == 500.15 and v.transmits == n)
    b.vehicle = v
    odoSend(cb, { veh = 7, odo = 900, trip = 0.2, show = true })
    check("a passenger: refused", v.md.ZeD_odo == 500.15 and v.md.ZeD_odoTrip == false and v.transmits == n)
    b.vehicle = nil
    -- the driver gets out; the game's exit lands first, the dash's last send just after
    o.vehicle, v.driver = nil, nil
    odoSend(co, { veh = 7, odo = 500.17, trip = 0.17, show = false })
    check("the driver's last send just after getting out: taken, and sent out (the driver left)",
        v.md.ZeD_odo == 500.17 and v.transmits == n + 1, v.transmits - n)
    odoSend(cb, { veh = 7, odo = 900, trip = 0.2, show = true })
    check("but not from anyone else at the empty car", v.md.ZeD_odo == 500.17)
    advance(11000)
    odoSend(co, { veh = 7, odo = 500.3, trip = 0.3, show = false })
    check("long after getting out: refused", v.md.ZeD_odo == 500.17)
    -- the driver moves seats and someone else takes the wheel: the old driver's late send is refused
    o.vehicle, v.driver = v, o
    odoSend(co, { veh = 7, odo = 500.4, trip = 0.4, show = false })
    check("back at the wheel", v.md.ZeD_odo == 500.4)
    v.driver, b.vehicle = b, v
    odoSend(co, { veh = 7, odo = 500.45, trip = 0.45, show = false })
    check("someone else at the wheel: the old driver's send refused", v.md.ZeD_odo == 500.4)
    odoSend(cb, { veh = 7, odo = 500.5, trip = 0.5, show = false })
    check("the new driver's taken", v.md.ZeD_odo == 500.5)
    check("the other mod's key never touched", v.md.Roadworthy.odo == 3)
end

section("ZeD's own dash: the command with every extra off")
do
    world()
    local o = player("Aretha", "user", 100, 100)
    local co = clientJoin(o)
    local v = newVehicle(7, 4021, 102, 100)
    W.touched = 0
    advance(3000)
    check("no command, no car touched", W.touched == 0, W.touched)
    o.vehicle, v.driver = v, o
    odoSend(co, { veh = 7, odo = 123.4, trip = 0, show = false })
    check("the odometer works with every extra off", v.md.ZeD_odo == 123.4 and v.transmits == 1)
    check("no claim stamp is made", v.md.ZeDClaim == nil)
end

section("ZeD's own dash: a driver gone with figures not sent out")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local DPs = W.server.ZeD.DashProto
    local at = DPs.PRUNE_AT
    DPs.PRUNE_AT = 1                                   -- (the server forgets drivers past their grace at once)
    local v = newVehicle(7, 4021, 102, 100)
    local w = newVehicle(8, 4022, 104, 100)
    v.running, w.running = true, true
    o.vehicle, v.driver = v, o
    odoSend(co, { veh = 7, odo = 700, trip = 0, show = false, save = true })
    odoSend(co, { veh = 7, odo = 700.1, trip = 0.1, show = false })
    check("a tenth taken, not sent out", v.md.ZeD_odo == 700.1 and v.transmits == 1, v.transmits)
    -- the driver's connection drops: no coarse send ever comes
    o.vehicle, v.driver = nil, nil
    advance(11000)
    b.vehicle, w.driver = w, b
    odoSend(cb, { veh = 8, odo = 900, trip = 0, show = false, save = true })
    check("forgotten past the grace: what was taken goes out", v.transmits == 2, v.transmits)
    advance(11000)
    odoSend(cb, { veh = 8, odo = 900.1, trip = 0.1, show = false })
    check("and only once", v.transmits == 2, v.transmits)
    DPs.PRUNE_AT = at
end

section("the list after a claim goes, and with every extra off")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local old = newVehicle(7, 4021, 102, 100)
    claim(co, old)
    local T = W.server.ZeD.Srv.X
    o.vehicle, old.driver = old, o
    advance(2100)
    o.vehicle, old.driver = nil, nil
    -- the car is removed and its number reused, and the new car is claimed, inside the looks
    W.vehicles[7] = nil
    local van = newVehicle(9, 4021, 102, 101, "Base.Van")
    local r = claimRow(old)
    r.tok, r.kid = "the van's", van.keyId
    van.md.ZeDClaim = r.tok
    W.logs = {}
    -- (the old object, with nothing of the claim on it: only the entry's token stops the look from reading it as that car)
    old.keyId, old.md = -1, {}
    advance(2100)
    check("the look at the old car leaves the new claim alone", not logHas("claim gone") and claimRow(van) == r)
    check("and the entry goes", T.driven[W.server.ZeD.Ex.keyOf(old.sql)] == nil)
    local v = newVehicle(8, 4022, 102, 100)
    claim(co, v)
    o.vehicle, v.driver = v, o
    advance(2100)
    o.vehicle, v.driver = nil, nil
    settings(ca, function(s) s.vc.on = false end)
    W.touched = 0
    advance(5000)
    check("every extra off: the look stops too", W.touched == 0, W.touched)
end

section("a claim from before the key number")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local c = claimRow(v)
    c.kid = nil
    check("its stamp still proves it", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    check("and it takes the number", c.kid == v.keyId)
    clientSendsModData(v, nil)
    check("so a send can't lose it now", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
    local v2 = newVehicle(8, 4022, 102, 101)
    claim(co, v2)
    local c2 = claimRow(v2)
    c2.kid = nil
    W.logs = {}
    clientSendsModData(v2, nil)
    check("one that lost its stamp first can't be told: it goes", act("ISUninstallVehiclePart", { character = b, vehicle = v2 }) == true)
    check("the line", logHas("claim gone: that car is gone"))
end

section("a client's send with claims stored and every extra off")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    settings(ca, function(s) s.vc.on = false end)
    W.logs, W.touched = {}, 0
    clientSendsModData(v, nil)
    check("the game's function runs", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == true)
    advance(5000)
    check("nothing touched the car", W.touched == 0, W.touched)
    check("nothing put the stamp back", v.md.ZeDClaim == nil)
    check("no line", not logHas("claim gone"))
end

section("a wreck cleared away takes its claim")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    v.burnt = true
    W.ran = {}
    check("the game's clearing runs", act("ISRemoveBurntVehicle", { character = b, vehicle = v }) == true and W.ran.ISRemoveBurntVehicle == 1)
    check("the line", logHas("claim gone: burnt"))
    advance(200)
    check("off the owner's list", co.E.mineRows ~= nil and #co.E.mineRows == 0)
end

section("staff release a claim: the owner's list follows")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    co.E.mineRows = nil
    co.E.mine()
    advance(1200)
    check("held", #co.E.mineRows == 1)
    press(ca, function(k) ca.E.release("v4021", k) end)
    check("the owner hears", #co.E.mineRows == 0)
end

section("two swings in a tick")
do
    local a, o, m, b, ca, co, cm, cb, h = safeWorld()
    local hit = function(chr, n, obj)
        W.server.Events.OnWeaponHitThumpable.fire(chr, weapon(n), obj)
        obj.health = obj.health - n * 2
    end
    local d = thing(503, 503)
    for _ = 1, 5 do
        hit(b, 30, d)
        hit(b, 30, d)
        advance(200)
    end
    check("the door comes back to its health", d.health == 500, d.health)
    local big = thing(503, 504)
    hit(b, 1, big)
    W.server.Events.OnWeaponHitThumpable.fire(b, weapon(100), big)
    check("a heavier second swing gets its own room", big.health >= 500 + 100, big.health)
    advance(200)
    check("and it comes back too", big.health == 500, big.health)
end

section("the container log: an honest game's lines reach the log")
do
    world()
    local a = player("Hermit", "admin", 900, 900)
    local b = player("Kade", "user", 503, 503)
    local ca, cb = clientJoin(a), clientJoin(b)
    newSafe(500, 500, 10, 10, "Aretha")
    settings(ca, function(s) s.cl.on = true end)
    W.logs = {}
    take(cb, b, square(503, 503), { "Rifle", "Ammo" })
    for _ = 1, 40 do
        b.x = b.x + 0.5
        advance(100)
    end
    check("grab and run: the line lands", logHas("1 x Rifle, 1 x Ammo"), b.x)
    W.logs = {}
    b.x, b.y = 503, 503
    local kinds = {}
    for i = 1, 20 do kinds[i] = "Kind" .. i end
    take(cb, b, square(503, 503), kinds)
    advance(8000)
    check("twenty kinds at once: nothing dropped", logHas("1 x Kind1") and logHas("1 x Kind13") and logHas("1 x Kind20"))
    check("in two reports", logCount("container | took") == 2, logCount("container | took"))
    -- an honest burst from six squares, the reports arriving with a network's jitter
    W.logs = {}
    W.server.ZeD.Srv.mem = {}
    for i = 1, 6 do take(cb, b, square(503, 500 + i), { "Item" .. i }) end
    local gate = cb.env.sendClientCommand
    local beat = 0
    cb.env.sendClientCommand = function(...)
        beat = beat + 1
        local args = { ... }
        local late = (beat % 2 == 0) and 0 or 300
        W.later = W.later or {}
        W.later[#W.later + 1] = { at = W.clock + late, run = function() gate(unpack(args)) end }
    end
    for _ = 1, 150 do
        step(100)
        for i = #(W.later or {}), 1, -1 do
            local e = W.later[i]
            if e.at <= W.clock then
                table.remove(W.later, i)
                e.run()
            end
        end
    end
    cb.env.sendClientCommand = gate
    check("six squares, six lines", logCount("container | took") == 6, logCount("container | took"))
    -- a client's word: nothing odd reaches the line
    W.logs = {}
    W.server.ZeD.Srv.mem = {}
    local function report(args) cb.env.sendClientCommand(b, "ZeDX", "x_took", args); advance(700) end
    b.x, b.y, b.z = 503, 503, 0
    report({ x = 505, y = 505, z = 1e300, rows = { { name = "Lies", n = 1 } } })
    report({ x = 505, y = 505, z = 0.5, rows = { { name = "Lies", n = 1 } } })
    report({ x = 505, y = 505, z = 9, rows = { { name = "Lies", n = 1 } } })
    report({ x = 505, y = 505, z = 0 / 0, rows = { { name = "Lies", n = 1 } } })
    check("a floor that can't be right is dropped", not logHas("Lies"))
    report({ x = 505, y = 505, z = 0, from = "not | a type!", rows = { { name = "Odd", n = 1 } } })
    check("a container's word that isn't a type is left out", logHas("1 x Odd (reported") and not logHas("not"))
    report({ x = 505, y = 505, z = 0, from = "Dave", rows = { { name = "Named", n = 1 } } })
    check("the word stays in the text, never the target", logHas("container | took | Kade | - |") and logHas("1 x Named from Dave (reported"))
    b.x, b.y = 503 + 500, 503
    report({ x = 505, y = 505, z = 0, rows = { { name = "Far", n = 1 } } })
    check("a report from the far side of town is dropped", not logHas("Far"))
end

section("two admins at the card")
do
    world()
    local a = player("Hermit", "admin")
    local a2 = player("Second", "admin")
    local ca, c2 = clientJoin(a), clientJoin(a2)
    local mine = c2.env.ZeD.Ex.clean(c2.E.set)
    mine.vc.on = true
    local was = c2.E.set
    settings(ca, function(s) s.cl.on, s.tp.on = true, true end)
    local r = press(c2, function(k) c2.E.save(mine, k, was) end)
    check("a save made on an old set is refused", r and r.ok == false and r.err == "changed", r and r.err)
    check("the other admin's save stands", ca.E.set.cl.on == true and ca.E.set.vc.on == false)
    r = press(c2, function(k) c2.E.save(mine, k) end)
    check("made on the current one, it goes", r and r.ok == true)
end

section("a table from a newer ZeD")
do
    world()
    W.moddata["ZeD_EX_old"] = { schema = 99, set = W.server.ZeD.Ex.defaults(), claims = {}, seen = {} }
    W.moddata["ZeD_EX_old"].set.vc.on = true
    W.server = nil
    serverStart()
    local a = player("Hermit", "admin")
    local ca = clientJoin(a)
    check("all off and said so", ca.E.frozen == true and ca.env.ZeD.Ex.nOn(ca.E.set) == 0)
    local r = settings(ca, function(s) s.vc.on = true end)
    check("a save is refused", r and r.ok == false and r.err == "frozen")
    check("nothing wraps", W.server.ISUninstallVehiclePart.complete == W.server.originals.ISUninstallVehiclePart)
end

section("a reload of the file doesn't wrap twice")
do
    local a, o, b, ca, co, cb = claimsWorld()
    local v = newVehicle(7, 4021, 102, 100)
    claim(co, v)
    local wrap = W.server.ISUninstallVehiclePart.complete
    runFile(W.server, "42/media/lua/server/ZeD/ZeD_ServerExtras.lua")
    W.server.ZeD.Srv.openExtras()
    check("the same wrap", W.server.ISUninstallVehiclePart.complete == wrap)
    check("one clock", #W.server.Events.OnTickEvenPaused.list == 1)
    check("the wrap reads the new file", act("ISUninstallVehiclePart", { character = b, vehicle = v }) == false)
end

section("no server part")
do
    world(true)
    local a = player("Hermit", "admin")
    local ca = clientJoin(a)
    advance(45000)
    check("nothing is live", ca.E.live() == false and ca.E.claimsOn() == false)
    check("no set", ca.E.set == nil)
    check("no wrap", ca.env.ISInventoryTransferAction.perform == ca.perform)
end

section("a game update that renames a capability leaves the extras off")
do
    world(true)
    local saved = CAPS
    CAPS = setmetatable({ ManipulateVehicle = false }, { __index = function(_, k) return k end })
    serverStart()
    check("no command answers", W.server.ZeD.Srv.modules.ZeDX == nil)
    CAPS = saved
end

print("extras_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
