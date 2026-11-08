-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerLog.lua
-- ============================================================================
-- THE LOG, THE SERVER'S SIDE. Srv.action is the one log: md.log in the admin table holds it, and the file gets each line as
-- it is written. This file reads that ring for the Log view, and adds what the game has no event for (server only: the
-- first line returns anywhere but a dedicated server or the server process a hosted game starts; pure ASCII):
--   vehicles   the seven timed actions wrapped where their complete runs, the last driver by the car's sqlId, a look every
--              10 seconds at who is driving (one pass over the players, never over the vehicles), and the tow command. Work on a
--              car nobody has on record goes in a ring of its own, so scavenging can't push out ZeD's other lines
--   PvP        kills from OnCharacterDeath; the game's own PvP log read off PVPLogTool, in a ring of its own
--   other mods the global writeLog tapped, in a ring of its own. Any client can write to any logger, so those lines are
--              always labeled by where they came from, are never written to the ZeD log, and can't push out anything else
--
-- Not yet proved on a real server, though the bytecode reads well: NetTimedAction.perform takes complete with
-- KahluaTable.rawget, and KahluaTableImpl.rawget walks the metatable, so a wrap on the class is what it calls. serverStop goes
-- the same road, and each class gets one, so a cancelled action proves the road too. Each class also has its .new wrapped, to
-- count. A class that makes HOOK_MISS actions and reaches neither wrap in HOOK_WAIT_S turns the fallback on: each new action of
-- exactly that class carries the wrap itself, while the class's own is still ZeD's. l_probe and one line in the ZeD log per
-- class say which happened (the QA script ZeDUI/tools/qa/mp_log.lua reads them).
--
-- With the server extras (ZeD_ServerExtras.lua, on the same actions): their wrap is outside this file's, so a refused action
-- never reaches a wrap here and its one line is their "refused". The fallback carries their wrap too, refusal and all, and a
-- refusal counts as the road reached. A claimed car's owner is the claimer (Srv.exOwner); the last driver is for every other
-- car. Every Srv.ex* asks one boolean first and may be missing: this file runs with or without them.
--
-- Views are allowlists. A line from the game's PvP log needs PVPLogTool, the place of a role above the reader's stays out of the
-- view, as on the Player card, and an IP address or Steam ID on a ban line needs BanUnbanUser, as the Bans card does. Nothing
-- here touches a ticket's words.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_LogProto"
require "ZeD/ZeD_ServerCore"
require "ZeD/ZeD_ServerTickets"
require "ZeD/ZeD_ServerAdmin"

local Srv = ZeD.Srv
local Tk = ZeD.Tk
local Lg = ZeD.Lg
local Adm = ZeD.Adm
if not Srv or Srv.off then return end

local L = Lg.L
-- (a capability a later game renamed would be nil, and hasCapability(nil) matches no overload: the view stays off)
local CAP_VIEW = Capability and Capability[Lg.VIEW_CAP]
local CAP_PVP = Capability and Capability.PVPLogTool
local CAP_BAN = Capability and Capability.BanUnbanUser
local CAP_ADMIN = Srv.CAP_ADMIN

-- memory only; a /reloadlua of this file keeps the probe's counts
local Lo = Srv.L or { P = { hooks = {}, missing = {}, tap = 0, tapKept = 0, pvp = 0, kills = 0, weapons = 0, polls = 0 }, pace = {}, pvpSeen = {}, weapon = {} }
Srv.L = Lo
Lo.tows = Lo.tows or {}             -- tow commands waiting for the next look
Lo.towSeen = Lo.towSeen or {}       -- player and pair of cars -> when its line was written
Lo.vehDrop = Lo.vehDrop or {}       -- player -> vehicle lines over the pace this minute
Lo.names = Lo.names or {}           -- the game's names the server has looked up
Lo.hays = Lo.hays or {}             -- a line's order -> the words a Find looks through
Lo.hayN = Lo.hayN or 0

-- the rings beside md.log and the last drivers, in the same secret table. Each line takes its s from md.log, so one order holds
local function rings(md)
    md.pvp = md.pvp or { n = 0, at = 0 }
    md.tap = md.tap or { n = 0, at = 0 }
    md.world = md.world or { n = 0, at = 0 }
    md.drivers = md.drivers or {}
    md.driverN = md.driverN or 0
    return md
end

local function ringAdd(md, ring, max, row)
    md.log.s = (md.log.s or 0) + 1
    row.s = md.log.s
    ring.at = (ring.at >= max) and 1 or (ring.at + 1)
    ring.n = math.min(ring.n + 1, max)
    ring[ring.at] = row
end

-- nil until the tables are open: nothing may open them before the game has loaded them
local function table_()
    if not (Srv.A and Srv.A.md) or Srv.logFrozen() then return nil end
    return rings(Srv.A.md)
end

-- the cars' table. Frozen, nothing may be written to the real one, but a line still reaches the ZeD log (the core's promise): a
-- copy in memory keeps who drove, so a line names the owner and "drove off" isn't said every 10 seconds
local function carTable()
    local md = table_()
    if md then return md end
    if not (Srv.A and Srv.A.md) then return nil end
    if not Lo.shadow then
        local drivers, n = {}, 0
        for id, d in pairs(Srv.A.md.drivers or {}) do
            drivers[id] = { u = d.u, t = d.t, at = d.at, prev = d.prev }
            n = n + 1
        end
        Lo.shadow = { drivers = drivers, driverN = n }
    end
    return Lo.shadow
end

-- at most n a minute per key; true when this one is over
local function over(key, n)
    local now = getTimestamp()
    local e = Lo.pace[key]
    if not e or now - e.at >= 60 then
        Lo.pace[key] = { at = now, n = 1 }
        return false
    end
    e.n = e.n + 1
    return e.n > n
end

-- ---------------------------------------------------------------------------
-- VEHICLES
-- ---------------------------------------------------------------------------
local function floor3(o) return math.floor(o:getX()), math.floor(o:getY()), math.floor(o:getZ()) end

-- whose car this is, by the record, and whether it has settled: a new driver holds it for SETTLE_S before it counts as theirs. Until
-- then it stays the driver's before them, so a thief who parks around the corner and strips it still writes lines naming the owner.
-- A first driver on record has no one before them: the name is theirs, but their own work on it isn't "their own car" yet
local function ownerOf(d)
    if not d then return nil, false end
    local settling = d.at ~= nil and getTimestamp() - d.at < L.SETTLE_S
    if settling and d.prev then return d.prev, false end
    return d.u, not settling
end

-- what a line says about a car, read before the action runs: a stripped wreck is gone after it
local function carFacts(md, v)
    local id = v:getSqlId()
    local script = v:getScript()
    local d = (id and id >= 0) and md.drivers[id] or nil
    local owner, settled = ownerOf(d)
    -- (a claim says whose car this is, with nothing to settle, and its name stays on the record's side of the line)
    local claimer = Srv.exOwner and Srv.exOwner(v) or nil
    if claimer then owner, settled = claimer, true end
    return { id = id, car = script and (script:getCarModelName() or script:getName()) or nil, owner = owner, settled = settled }
end

-- one vehicle line. Your own settled car writes nothing (OWN_CAR_LINES); one still settling counts as nobody's. A car with an
-- owner goes through Srv.action (the ZeD log and the ring); work on a car nobody has on record goes to the file and the world ring
local function vehWrite(md, user, x, y, z, what, car, ex)
    local owner = car.owner
    if owner == user then
        if car.settled and not Lg.OWN_CAR_LINES then return end
        if not car.settled then owner = nil end
    end
    -- ("drove off" moves the owner and a tow has its own pace: neither can use up the budget of the other lines, or be dropped by it)
    if what ~= "drive" and what ~= "tow" and over("veh:" .. user, L.VEH_PER_MIN) then
        Lo.vehDrop[user] = (Lo.vehDrop[user] or 0) + 1
        return
    end
    ex = ex or {}
    ex.car = car.car
    local detail = tostring(car.car)
    if ex.part then detail = detail .. "/" .. ex.part end
    if ex.locked then detail = detail .. " locked" end
    if owner then
        Srv.action("vehicle", user, what, owner, detail, x, y, z, ex)
        return
    end
    Srv.fileLine("vehicle", user, what, nil, detail, x, y, z)
    if md.world then
        ringAdd(md, md.world, L.VEH_MAX, { t = getTimestamp(), day = Srv.day(), kind = "vehicle", who = user, what = what, text = detail, x = x, y = y, z = z,
            car = ex.car, part = ex.part, locked = ex.locked })
    end
end

local function vehLine(md, o, what, car, ex)
    local x, y, z = floor3(o)
    vehWrite(md, o:getUsername(), x, y, z, what, car, ex)
end

-- past DRIVERS_MAX cars, the tenth seen longest ago are forgotten
local function trimDrivers(md)
    if md.driverN <= L.DRIVERS_MAX then return end
    local list, n = {}, 0
    for id, d in pairs(md.drivers) do
        n = n + 1
        list[n] = { id = id, t = d.t or 0 }
    end
    table.sort(list, function(a, b) return a.t < b.t end)
    local drop = math.max(1, math.floor(n / 10))
    for i = 1, drop do md.drivers[list[i].id] = nil end
    md.driverN = n - drop
end

-- The rule for "drove off": someone other than the last driver has the car moving. Only a running engine calls this, never a turn of the key.
-- The owner coming back inside the settling time takes the car back with no line: it was never theirs to lose
function Lo.driverSeen(md, o, v)
    -- (a claim is shutting this engine off, and writes its own refusal: nobody drove off, and the record stays)
    if Srv.exDriveStops and Srv.exDriveStops(o, v) then return end
    local id = v:getSqlId()
    if not id or id < 0 then return end
    local user = o:getUsername()
    local d = md.drivers[id]
    local now = getTimestamp()
    if d and d.u == user then
        d.t = now
        return
    end
    local car = carFacts(md, v)
    if not d then md.driverN = md.driverN + 1 end
    if car.owner == user then
        md.drivers[id] = { u = user, t = now }
    else
        vehLine(md, o, "drive", car)
        md.drivers[id] = { u = user, t = now, at = now, prev = car.owner }
    end
    trimDrivers(md)
end

-- each action: the car it works on, read before it runs, and what to say after. r is what the game's complete answered
local ACT = {
    ISSmashVehicleWindow = {
        before = function(act, snap)
            local parent = act.part and act.part:getParent()
            local door = parent and parent:getDoor()
            snap.locked = (door and door:isLocked()) and true or nil
        end,
        after = function(md, o, act, snap) vehLine(md, o, "smash", snap.car, { part = act.part and act.part:getId() or nil, locked = snap.locked }) end,
    },
    ISUninstallVehiclePart = {
        before = function(act, snap) snap.had = act.part ~= nil and act.part:getInventoryItem() ~= nil end,
        -- (the roll can fail: only a part that really came off is a line)
        after = function(md, o, act, snap)
            if snap.had and act.part:getInventoryItem() == nil then vehLine(md, o, "part", snap.car, { part = act.part:getId() }) end
        end,
    },
    ISTakeEngineParts = { after = function(md, o, act, snap) vehLine(md, o, "eparts", snap.car) end },
    ISTakeGasolineFromVehicle = {
        after = function(md, o, act, snap) vehLine(md, o, "siphon", snap.car) end,
        -- (stopped early the tank has already lost what the bar reached, and complete never runs)
        stopped = function(md, o, act, snap)
            if act.part and act.tankStart and act.part:getContainerContentAmount() < act.tankStart then vehLine(md, o, "siphon", snap.car) end
        end,
    },
    ISRemoveBurntVehicle = { after = function(md, o, act, snap) vehLine(md, o, "strip", snap.car) end },
    -- (complete answers true for a key that did nothing: only a running engine is a driver, here or at the next look)
    ISStartVehicleEngine = {
        after = function(md, o, act, snap)
            if snap.v:isEngineRunning() then Lo.driverSeen(md, o, snap.v) end
        end,
    },
    ISHotwireVehicle = {
        after = function(md, o, act, snap)
            if snap.v:isHotwired() then
                vehLine(md, o, "hotwire", snap.car)
                if snap.v:isEngineRunning() then Lo.driverSeen(md, o, snap.v) end
            end
        end,
    },
}
Lo.ACT = ACT

local function actor(act)
    local o = act and act.character
    if o and instanceof(o, "IsoPlayer") then return o end
    return nil
end

-- (each runs inside pcall: a slip here must never cost the game its action)
local function before(name, act)
    local md = carTable()
    local o = actor(act)
    if not (md and o) then return nil end
    local v = act.vehicle or (act.part and act.part:getVehicle()) or o:getVehicle()
    if not v then return nil end
    local snap = { v = v, car = carFacts(md, v) }
    local spec = ACT[name]
    if spec.before then spec.before(act, snap) end
    return snap
end

local function after(name, act, snap, r)
    local h = Lo.P.hooks[name]
    h.done = h.done + 1
    act.zedDone = true              -- (one line per action, if the game stops one that finished)
    if h.done == 1 then Srv.fileLine("admin", Tk.SYS, "vehicle hook reached", name, h.fallback and "by the .new fallback" or "by the class") end
    if r == false or not snap then return end
    local md = carTable()
    local o = actor(act)
    if md and o then ACT[name].after(md, o, act, snap) end
end

local function stopped(name, act)
    local spec = ACT[name]
    if not spec.stopped or act.zedDone then return end
    local snap = before(name, act)
    local md = carTable()
    local o = actor(act)
    if snap and md and o then spec.stopped(md, o, act, snap) end
end

function Lo.before(name, act)
    local ok, snap = pcall(before, name, act)
    if ok then return snap end
    Lo.slip("before " .. name, snap)
    return nil
end
function Lo.after(name, act, snap, r)
    local ok, err = pcall(after, name, act, snap, r)
    if not ok then Lo.slip("after " .. name, err) end
end
function Lo.stopped(name, act)
    local h = Lo.P.hooks[name]
    h.stop = (h.stop or 0) + 1
    local ok, err = pcall(stopped, name, act)
    if not ok then Lo.slip("stop " .. name, err) end
end
--- the server extras refused an action outside this file's wrap: it proves the road, as a complete or a cancel does
--- (ZeD_ServerExtras.lua calls it as Srv.L.refused)
function Lo.refused(name)
    local h = Lo.P.hooks[name]
    if h then h.ref = (h.ref or 0) + 1 end
end
-- what a class holds for method, while that is ZeD's own: this file's wrap, or the server extras' on top of it
local function ours(C, name, method, own)
    local f = C[method]
    if f == nil then return nil end
    if f == own or (Srv.exTop and Srv.exTop[name .. "." .. method] == f) then return f end
    return nil
end
-- an action made. A wrap reached, by a complete, a cancel or a refusal, proves the road, so the fallback waits for none of them to
-- be seen on HOOK_MISS actions, HOOK_WAIT_S after the first (an action under way has reached nothing yet). Its field shadows the
-- class, so it goes only on the class's own actions, and only while the class's wraps are still ZeD's: a mod that wrapped or
-- replaced complete after ZeD stays in the chain, and so does a subclass with its own. It carries the whole of ZeD's chain: a
-- server extra's refusal is in it, and the siphon's animEvent goes on with it
function Lo.made(name, o, C, wrapped, stopWrapped)
    local h = Lo.P.hooks[name]
    h.new = h.new + 1
    h.first = h.first or getTimestamp()
    if h.new >= L.HOOK_MISS and h.done == 0 and (h.stop or 0) == 0 and (h.ref or 0) == 0 and not h.fallback and getTimestamp() - h.first >= L.HOOK_WAIT_S then
        h.fallback = true
        Srv.fileLine("admin", Tk.SYS, "vehicle hook fallback on", name, tostring(h.new) .. " made, none reached")
    end
    if h.fallback and type(o) == "table" and getmetatable(o) == C then
        local top = ours(C, name, "complete", wrapped)
        if top then
            o.complete = top
            if C.serverStop == stopWrapped then o.serverStop = stopWrapped end
            o.animEvent = ours(C, name, "animEvent", nil)
        end
    end
end
-- a hook that threw: one line a minute per place, in the ZeD log and the console
function Lo.slip(where, err)
    if over("slip:" .. where, 1) then return end
    Srv.action("admin", Tk.SYS, "log hook failed", nil, where .. ": " .. tostring(err))
    print("[ZeD] server: log hook failed: " .. where .. ": " .. tostring(err))
end

-- (reload guard: Srv.hooked keeps its place across a /reloadlua, and each wrap looks Srv.L up at every call)
Srv.hooked = Srv.hooked or {}
local function wrap(name)
    if Srv.hooked[name] then return end
    local C = _G[name]
    if type(C) ~= "table" or type(C.complete) ~= "function" or type(C.new) ~= "function" then
        Lo.P.missing[#Lo.P.missing + 1] = name
        return
    end
    Srv.hooked[name] = true
    Lo.P.hooks[name] = Lo.P.hooks[name] or { new = 0, done = 0, stop = 0 }
    local base, baseNew, baseStop = C.complete, C.new, C.serverStop
    local wrapped = function(self)
        local snap = ZeD.Srv.L.before(name, self)
        local r = base(self)
        ZeD.Srv.L.after(name, self, snap, r)
        return r
    end
    -- (most of these have no serverStop of their own: the game calls one if it finds one)
    local stopWrapped = function(self)
        if baseStop then baseStop(self) end
        ZeD.Srv.L.stopped(name, self)
    end
    C.complete = wrapped
    C.serverStop = stopWrapped
    C.new = function(...)
        local o = baseNew(...)
        ZeD.Srv.L.made(name, o, C, wrapped, stopWrapped)
        return o
    end
end
for name in pairs(ACT) do wrap(name) end

-- a tow: the game's own command, through one listener that tests the module first. Nothing limits that command and the game
-- only warns about distance, it goes out as the action starts, and a cancel takes it back. So a command is only noted, at
-- TOW_PER_MIN, with both cars in reach, and the line waits for the next look to see that a tow really formed
local function inReach(o, v)
    local dx, dy = o:getX() - v:getX(), o:getY() - v:getY()
    return dx * dx + dy * dy <= L.TOW_REACH * L.TOW_REACH
end

function Lo.onCommand(module, command, player, args)
    if module ~= "vehicle" or command ~= "attachTrailer" then return end
    if type(args) ~= "table" or not player then return end
    -- (a client's numbers: anything but a whole one would match no overload of getVehicleById)
    if not (Tk.whole(args.vehicleA) and Tk.whole(args.vehicleB)) then return end
    local a, b = getVehicleById(args.vehicleA), getVehicleById(args.vehicleB)
    if not (a and b and inReach(player, a) and inReach(player, b)) then return end
    -- (a claim is taking this tow straight off, and writes its own refusal: one tow, one line)
    if Srv.exTowStops and Srv.exTowStops(player, a, b) then return end
    local user = player:getUsername()
    if over("tow:" .. user, L.TOW_PER_MIN) then return end
    local x, y, z = floor3(player)
    Lo.tows[#Lo.tows + 1] = { user = user, a = args.vehicleA, b = args.vehicleB, at = getTimestamp(), x = x, y = y, z = z }
end

-- either car can be the one in the menu's first slot: the line is about the one that isn't the sender's, B when neither is anyone's
local function towLine(md, t, a, b, now)
    local ca, cb = carFacts(md, a), carFacts(md, b)
    local lo, hi = tostring(ca.id), tostring(cb.id)
    if lo > hi then lo, hi = hi, lo end
    local key = t.user .. ":" .. lo .. ":" .. hi
    local seen = Lo.towSeen[key]
    if seen and now - seen < L.TOW_REPEAT_S then return end
    Lo.towSeen[key] = now
    local car = cb
    if (not cb.owner or cb.owner == t.user) and ca.owner and ca.owner ~= t.user then car = ca end
    vehWrite(md, t.user, t.x, t.y, t.z, "tow", car)
end

-- each noted tow, looked at once POLL_S has passed: a line only if the tow really formed
local function towLook(md, now)
    local keep = {}
    for _, t in ipairs(Lo.tows) do
        if now - t.at < L.POLL_S then
            keep[#keep + 1] = t         -- (a hookup takes seconds, and a cancel in them undoes it)
        else
            local a, b = getVehicleById(t.a), getVehicleById(t.b)
            if a and b and b:getVehicleTowedBy() == a then towLine(md, t, a, b, now) end
        end
    end
    Lo.tows = keep
end

-- one line a minute for what the pace dropped, as the claims pass does
local function dropLines(now)
    local done = {}
    for user, n in pairs(Lo.vehDrop) do
        local e = Lo.pace["veh:" .. user]
        if not e or now - e.at >= 60 then done[user] = n end
    end
    for user, n in pairs(done) do
        Lo.vehDrop[user] = nil
        Srv.action("vehicle", user, "dropped", nil, tostring(n))
    end
end

-- ---------------------------------------------------------------------------
-- PVP
-- ---------------------------------------------------------------------------
-- a kill: IsoGameCharacter.DoDeath fires this, and asks getAttackedBy as here to write the game's own kill line
function Lo.onDeath(chr)
    if not instanceof(chr, "IsoPlayer") or chr:isAnimal() then return end
    local by = chr:getAttackedBy()
    if not by or by == chr or not instanceof(by, "IsoPlayer") then return end
    Lo.P.kills = Lo.P.kills + 1
    local x, y, z = floor3(chr)
    Srv.action("pvp", by:getUsername(), "kill", chr:getUsername(), nil, x, y, z)
end

-- the weapon behind the game's next PvP line, which keeps no weapon of its own. A weapon is forgotten at each read
function Lo.onHit(wielder, target, weapon)
    if not (instanceof(wielder, "IsoPlayer") and instanceof(target, "IsoPlayer") and weapon) then return end
    Lo.P.weapons = Lo.P.weapons + 1
    Lo.weapon[wielder:getUsername() .. "\n" .. target:getUsername()] = weapon:getName()
end

-- the game keeps its last ten hits here on the server (PVPLogTool). A line reads [time] "wielder" hit "target"; the time is
-- the server's own, in a form nothing else here shares, so a line takes the time it was read, at most POLL_S late
function Lo.readPvp(md)
    if not PVPLogTool then
        Lo.weapon = {}
        return
    end
    local list = PVPLogTool.getEvents()
    local seen = {}
    for i = list:size() - 1, 0, -1 do
        local e = list:get(i)
        if e:isSet() then
            local text = e:getText()
            seen[text] = true
            if not Lo.pvpSeen[text] then
                local who, target = string.match(text, '^%[.-%] "(.*)" hit "(.*)"$')
                if who then
                    Lo.P.pvp = Lo.P.pvp + 1
                    ringAdd(md, md.pvp, L.PVP_MAX, { t = getTimestamp(), day = Srv.day(), kind = "pvp", src = "pvp", who = Tk.name(who), what = "hit", target = Tk.name(target),
                        text = Lo.weapon[who .. "\n" .. target], x = math.floor(e:getX()), y = math.floor(e:getY()), z = math.floor(e:getZ()) })
                end
            end
        end
    end
    Lo.pvpSeen = seen
    Lo.weapon = {}
end

-- ---------------------------------------------------------------------------
-- OTHER MODS' LINES. The global writeLog, wrapped: every caller that looks it up at call time passes here, the game's own
-- ISLogSystem channel included. The ZeD log's own lines are skipped by name, and the game's own chatter too (Lg.GAME_LOGGERS). The
-- file gets its line whatever happens here.
-- ---------------------------------------------------------------------------
local function oneLine(text)
    local s = string.gsub(Tk.clean(string.sub(text, 1, 2 * L.TAP_TEXT)) or "", "\n", " ")
    return string.sub(s, 1, L.TAP_TEXT)
end

function Lo.tap(name, text)
    if type(name) ~= "string" or type(text) ~= "string" then return end
    if Lg.plainName(name) == "zed" then return end
    local md = table_()
    if not md then return end
    Lo.P.tap = Lo.P.tap + 1
    if Lg.GAME_LOGGERS[name] then return end
    local by = Srv.tapBy
    if over("tap:" .. (by or ("=" .. name)), L.TAP_PER_MIN) then return end
    Lo.P.tapKept = Lo.P.tapKept + 1
    local kindWord, user, x, y, z, rest = Lg.tapParse(text)
    rest = oneLine(rest)
    ringAdd(md, md.tap, L.TAP_MAX, { t = getTimestamp(), day = Srv.day(), kind = Lg.tapKind(name, kindWord), src = "tap", lg = Tk.name(name), by = by,
        who = Tk.name(user or by or "?"), what = kindWord and Tk.name(kindWord) or nil, text = (rest ~= "") and rest or nil, x = x, y = y, z = z })
end

-- wrapped once (Srv.tapOn outlives a /reloadlua); the tap runs inside pcall, and the game's writeLog always runs after it
if not Srv.tapOn and writeLog then
    Srv.tapOn = true
    local base = writeLog
    writeLog = function(name, text)
        pcall(function() ZeD.Srv.L.tap(name, text) end)
        return base(name, text)
    end
end

-- ---------------------------------------------------------------------------
-- THE CLOCK: POLL_S seconds apart, on OnTickEvenPaused: the game clock stops on an empty server
-- ---------------------------------------------------------------------------
function Lo.tick()
    local now = getTimestamp()
    if Lo.at and now - Lo.at < L.POLL_S then return end
    Lo.at = now
    local md = carTable()
    if not md then return end
    Lo.P.polls = Lo.P.polls + 1
    Srv.eachOnline(function(o)
        local v = o:getVehicle()
        if v and v:isDriver(o) and v:isEngineRunning() then Lo.driverSeen(md, o, v) end
    end)
    towLook(md, now)
    dropLines(now)
    local open = table_()
    if open then Lo.readPvp(open) end
    for key, e in pairs(Lo.pace) do
        if now - e.at >= 60 then Lo.pace[key] = nil end
    end
    for key, at in pairs(Lo.towSeen) do
        if now - at >= L.TOW_REPEAT_S then Lo.towSeen[key] = nil end
    end
end

if not Srv.logHooked then
    Srv.logHooked = true
    -- (looked up at each call, so a reload of this file takes effect; a slip costs one pass, not the event chain)
    local function safely(where, fn)
        return function(...)
            local ok, err = pcall(fn, ...)
            if not ok then ZeD.Srv.L.slip(where, err) end
        end
    end
    Events.OnTickEvenPaused.Add(safely("clock", function() ZeD.Srv.L.tick() end))
    Events.OnClientCommand.Add(safely("tow", function(module, command, player, args) ZeD.Srv.L.onCommand(module, command, player, args) end))
    Events.OnCharacterDeath.Add(safely("death", function(chr) ZeD.Srv.L.onDeath(chr) end))
    Events.OnWeaponHitCharacter.Add(safely("hit", function(wielder, target, weapon) ZeD.Srv.L.onHit(wielder, target, weapon) end))
end

-- ---------------------------------------------------------------------------
-- WHAT EACH PERSON RECEIVES: built field by field from an allowlist
-- ---------------------------------------------------------------------------
local function rowView(l)
    return { s = l.s, t = l.t, day = l.day, k = Lg.kindOf(l.kind), who = l.who, what = l.what, target = l.target, text = l.text, x = l.x, y = l.y, z = l.z,
        car = l.car, part = l.part, locked = l.locked, src = l.src, lg = l.lg, by = l.by, hid = l.hid,
        via = l.via }
end

local function copyOf(l)
    local c = {}
    for k, v in pairs(l) do c[k] = v end
    c.copy = true
    return c
end

local NO_RING = { n = 0 }
local function eachRing(md, fn)
    for _, ring in ipairs({ md.log, md.pvp or NO_RING, md.tap or NO_RING, md.world or NO_RING }) do
        for i = 1, ring.n do
            local l = ring[i]
            if l then fn(l) end
        end
    end
end

-- the lines whose target can be an IP address or a Steam ID: those a ban takes. The Bans card asks BanUnbanUser for the same
local ID_LINE = { ban = true, unban = true, ["ban lifted"] = true, ["ban lifted in the game"] = true, ["game ban"] = true, ["game call dropped"] = true, ["owed game calls full"] = true }

local function isAbove(r, p, name)
    if name == nil then return false end
    local up = r.above[name]
    if up == nil then
        up = Srv.outranks(p, name)
        r.above[name] = up
    end
    return up
end

-- how this reader sees a line, or nil when it is not theirs to see. r: what they can read, and the names found above them so far,
-- this read. Anything left out here stays out of Find, Who, Around and a note, since all of them read what this gives
local function seenBy(l, r, p)
    if l.src == "pvp" and not r.canPvp then return nil end
    local c = l
    if not r.canBan and l.kind == "admin" and ID_LINE[l.what] and l.target and Adm.targetKind(l.target) ~= "user" then
        c = copyOf(l)
        c.target = nil
    end
    -- (a fight's place is where both of them stood)
    if l.x and (isAbove(r, p, l.who) or (l.kind == "pvp" and isAbove(r, p, l.target))) then
        if c == l then c = copyOf(l) end
        c.x, c.y, c.z, c.hid = nil, nil, nil, true
    end
    return c
end

local function canSeePvp(p) return CAP_PVP ~= nil and Srv.can(p, CAP_PVP) end
local function readerOf(p) return { canPvp = canSeePvp(p), canBan = CAP_BAN ~= nil and Srv.can(p, CAP_BAN), above = {} } end

local function badText(s, max)
    return s ~= nil and (type(s) ~= "string" or #s > max)
end

-- the kinds whose place is where the one who did it stood. A ticket's line has the ticket's place and a safehouse's the house's,
-- so neither says who was there. A community line has the place of whoever wrote the rules or a post, or was asked to agree
local PROVES_PLACE = { admin = true, vehicle = true, pvp = true, community = true }
-- (a claim's lines carry the car's place, with its owner anywhere or off the server: Lg.NOT_THERE)

-- who the Around line names: anyone seen here up to the filing whom the ticket's nearby list did not hold
local function missedOf(lines, facts)
    local by, out = {}, {}
    for _, l in ipairs(lines) do
        if l.t <= facts.filed and PROVES_PLACE[l.kind] and l.src ~= "tap" and not (l.what and Lg.NOT_THERE[l.what]) and l.who ~= Tk.SYS and l.who ~= facts.author and not facts.near[l.who] then
            local e = by[l.who]
            if e then
                e.from, e.to = math.min(e.from, l.t), math.max(e.to, l.t)
            else
                e = { who = l.who, from = l.t, to = l.t }
                by[l.who] = e
                out[#out + 1] = e
            end
        end
    end
    table.sort(out, function(a, b) return a.to > b.to end)
    for i = #out, L.MISSED_MAX + 1, -1 do out[i] = nil end
    return out
end

-- the English a Find looks through and a note is written in (Lg.lineWords)
local SAY = { w = Lg.enWords, kind = function(k) return Lg.KIND_EN[k] or tostring(k) end }
function SAY.name(prefix, id)
    local key = prefix .. tostring(id)
    local s = Lo.names[key]
    if s == nil then
        s = getTextOrNull and getTextOrNull(key) or nil
        if s == nil then s = tostring(id) end
        Lo.names[key] = s
    end
    return s
end
function SAY.item(fullType)
    local ok, s = pcall(getItemNameFromFullType, fullType)
    return (ok and s) or fullType
end

-- a line's words don't change, and a read walks every ring, so they are kept by the line's order. A copy made for one reader is
-- built for that read: it holds less than the line
local HAY_MAX = 5000
local function hayOf(l)
    if l.copy then return Lg.hay(l, Lg.lineWords(l, SAY)) end
    local h = Lo.hays[l.s]
    if not h then
        h = Lg.hay(l, Lg.lineWords(l, SAY))
        Lo.hayN = Lo.hayN + 1
        if Lo.hayN > HAY_MAX then Lo.hays, Lo.hayN = {}, 1 end
        Lo.hays[l.s] = h
    end
    return h
end

-- a Find's codes from the client's own words, as a set; false for a list no client of ours sends
local function readCodes(v)
    if v == nil then return nil end
    if type(v) ~= "table" then return false end
    local set, n = {}, 0
    for _, c in pairs(v) do
        n = n + 1
        if n > L.CODES_MAX or badText(c, L.CODE_TEXT) then return false end
        set[c] = true
    end
    return set
end

-- a read: q from the client's words, or nil with the answer sent
local function readQuery(p, a, rid)
    local kind, who, when, find = a.kind, a.who, a.when, a.find
    local codes = readCodes(a.codes)
    if codes == false or (kind ~= nil and not Lg.KIND[kind]) or (when ~= nil and not Lg.WHEN[when]) or badText(who, Tk.LIMITS.NAME_MAX) or badText(find, L.FIND_MAX) or (a.page ~= nil and not Tk.whole(a.page)) then
        Srv.bad(p, "l_query")
        Srv.ack(p, rid, false, "text")
        return nil
    end
    local q = { kind = kind, who = who }
    find = Tk.clean(find)
    if find and find ~= "" then q.find, q.codes, q.hay = string.lower(find), codes, hayOf end
    return q, when or Lg.DEFAULT_WHEN
end

local function query(p, a, rid)
    local md = Srv.logTable()
    local q, when = readQuery(p, a, rid)
    if not q then return end
    local base = {}                 -- the place and time alone, before the card's filters
    local around = nil
    local facts = nil
    if a.around ~= nil then
        if not Tk.whole(a.around) then
            Srv.bad(p, "l_query")
            Srv.ack(p, rid, false, "gone")
            return
        end
        facts = Srv.ticketFacts(a.around)
        if not facts then Srv.ack(p, rid, false, "gone"); return end
        if not (facts.place and facts.filed) then Srv.ack(p, rid, false, "noplace"); return end
        base.near = { x = facts.place.x, y = facts.place.y, r = Tk.NEAR }
        base.since, base.untilT = facts.filed - Lg.AROUND_BEFORE, facts.filed + Lg.AROUND_AFTER
        around = { id = facts.id, x = facts.place.x, y = facts.place.y, from = base.since, to = base.untilT, filed = facts.filed }
    else
        base.since = Lg.since(when, getTimestamp())
    end
    q.near, q.since, q.untilT = base.near, base.since, base.untilT
    local reader = readerOf(p)
    local kept, n, spot, all, names = {}, 0, {}, 0, {}
    eachRing(md, function(l0)
        local l = seenBy(l0, reader, p)
        if not l then return end
        all = all + 1
        -- (a tapped line's name is what a client typed: only the proved sender goes on the list)
        local name = l.who
        if l.src == "tap" then name = l.by end
        if name and name ~= Tk.SYS then names[name] = true end
        if facts and Lg.keep(l, base) then spot[#spot + 1] = l end
        if Lg.keep(l, q) then
            n = n + 1
            kept[n] = l
        end
    end)
    table.sort(kept, Lg.newest)
    local pages = math.max(1, math.ceil(n / L.ROWS))
    local page = math.min(a.page or 1, pages)
    local rows = {}
    for i = (page - 1) * L.ROWS + 1, math.min(n, page * L.ROWS) do rows[#rows + 1] = rowView(kept[i]) end
    -- (opt: the Container chip follows the server's Container log setting. Lines already kept stay under All with it off)
    local out = { qid = Tk.whole(a.qid) and a.qid or nil, rows = rows, n = n, all = all, page = page, pages = pages, opt = (Srv.exContainerLog and Srv.exContainerLog()) and true or nil }
    if page == 1 then
        local list = {}
        for u in pairs(names) do list[#list + 1] = u end
        table.sort(list, function(x, y) return string.lower(x) < string.lower(y) end)
        for i = #list, L.NAMES_MAX + 1, -1 do list[i] = nil end
        out.names = list
    end
    if around then
        around.missed = missedOf(spot, facts)
        out.around = around
    end
    Srv.to(p, Lg.MOD, "l_page", out)
    if rid then Srv.ack(p, rid, true) end
end

-- a line in words the server can write, for an admin note: what the card says, with its time and place. The times are written
-- with the line: the card's dates are the viewer's
local function noteText(l)
    local parts = { "Log, " .. Lg.stamp(l.t) .. ", day " .. tostring(l.day) .. ": " .. Lg.whoWords(l, SAY) .. " " .. Lg.lineWords(l, SAY) }
    if l.x then parts[#parts + 1] = "at " .. tostring(l.x) .. " x " .. tostring(l.y) end
    if l.src == "pvp" then parts[#parts + 1] = "from the game's PvP log" end
    if l.src == "tap" then
        local from = "from the log " .. tostring(l.lg)
        if l.by then from = from .. ", sent by " .. tostring(l.by) end
        parts[#parts + 1] = from .. ", not proved"
    end
    return string.sub(table.concat(parts, ", "), 1, Tk.LIMITS.TEXT_MAX)
end

local function lineOf(md, s)
    local found = nil
    eachRing(md, function(l) if l.s == s then found = l end end)
    return found
end

-- ---------------------------------------------------------------------------
-- THE COMMANDS
-- ---------------------------------------------------------------------------
if CAP_VIEW and Srv.logTable then
    Srv.register(Lg.MOD, "l_query", { cap = CAP_VIEW, limit = L.QUERY_MS }, query)

    -- a line of the log, as an admin note on its ticket
    Srv.register(Lg.MOD, "l_tonote", { cap = Srv.CAP_STAFF, limit = L.NOTE_MS }, function(p, a, rid)
        if not (Tk.whole(a.id) and Tk.whole(a.s)) then
            Srv.bad(p, "l_tonote")
            Srv.ack(p, rid, false, "gone")
            return
        end
        local md = Srv.logTable()
        local l0 = lineOf(md, a.s)
        local l = l0 and seenBy(l0, readerOf(p), p) or nil
        if not l then
            Srv.ack(p, rid, false, "gone")
            return
        end
        local ok, err = Srv.ticketNote(p, a.id, noteText(l))
        Srv.ack(p, rid, ok, err)
    end)

    -- QA: what the hooks have seen (E2, E1). Counts only
    Srv.register(Lg.MOD, "l_probe", { cap = CAP_ADMIN }, function(p, a, rid)
        local P = Lo.P
        local hooks = {}
        for name, h in pairs(P.hooks) do hooks[name] = { new = h.new, done = h.done, stop = h.stop, ref = h.ref, fallback = h.fallback } end
        Srv.to(p, Lg.MOD, "l_probe", { hooks = hooks, missing = P.missing, tap = P.tap, tapKept = P.tapKept, pvp = P.pvp, kills = P.kills, weapons = P.weapons, polls = P.polls, hasPvp = PVPLogTool ~= nil })
    end)

    Srv.modules[Lg.MOD] = true
    Srv.helloAdds.log = function(p, r) r.lg = 1 end
else
    -- (at load, so the file alone: nothing may open the admin table before the game has loaded it)
    Srv.fileLine("admin", Tk.SYS, "log view off", nil, "no " .. Lg.VIEW_CAP .. " capability, or no admin tools to hold the ring")
end

return Lo
