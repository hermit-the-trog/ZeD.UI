-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerExtras.lua
-- ============================================================================
-- THE SERVER EXTRAS, THE SERVER'S SIDE (ZeDUI/MP_ADMIN_SCOPE.md, Phase 6). Every extra is a setting, off until the owner
-- turns it on: until then this file wraps nothing, adds no listener and has no clock, so a vanilla-rules server runs the
-- game's own functions. Once a system has been on, its wraps stay in place (a later mod may have wrapped them too) and each
-- starts with one test of a boolean that passes straight to the game's function while the system is off.
--
-- WHAT THE SERVER CAN REFUSE (MP_SERVER_PART_DESIGN.md, the last section, has the proof of each):
--   Timed actions   the server calls an action's Lua complete() when its time is up (NetTimedAction.perform). Returning false
--                   is the game's own refusal: ActionManager marks the action rejected, the client's action stops, and no
--                   anti-cheat counts it. The game's SledgehammerOnlyInSafehouse rule refuses this way. It comes at the end
--                   of the wait, so the Vehicle tab grays what it knows will be refused.
--   Engine, driving ISStartVehicleEngine and ISHotwireVehicle are timed actions. Climbing in is VehicleEnterPacket, with no Lua
--                   hook, so a driver who isn't allowed gets the seat and no engine: a clock shuts a running engine off.
--   Tow             vehicle.attachTrailer is a client command the game's local handler runs, which nothing can stop. This
--                   file's listener comes after it and breaks the link straight away, as vehicle.detachTrailer does.
--   Axe swings      a swing at a door, a built wall or a barricade reaches the server as PlayerHitObjectPacket. Nothing refuses
--                   it, but OnWeaponHitThumpable fires before the damage, so the object is given room for the swing and
--                   put back at its old health on the next tick.
-- WHAT IT CANNOT: item transfers are Java on the server, with no Lua at all (TransactionManager), so a take from a container
-- is reported by the player's own client (x_took) and the log says so; the server tests that the report could be true.
--
-- The table has a secret random name, as the tickets' does (A2), and is never transmitted. Views are allowlists, for one
-- player. Every act goes through Srv.action, with kinds vehicle, safehouse, container and admin.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ExtrasProto"
require "ZeD/ZeD_ServerCore"

local Srv = ZeD.Srv
local Tk, Ex = ZeD.Tk, ZeD.Ex
if not Srv or Srv.off then return end

local L = Ex.L
local PREFIX = "ZeD_EX_"
local SCHEMA = 1
local MIGRATE = {}                   -- MIGRATE[1] = function(md) ... end   moves 1 to 2; adds or reshapes, never drops

-- (a capability a later game renamed would be nil, and hasCapability(nil) matches no overload: the extras stay off)
local CAP = {}
for _, name in ipairs(Ex.SERVER_CAPS) do
    CAP[name] = Capability and Capability[name]
    if not CAP[name] then
        Srv.log("server extras off: this game has no " .. name .. " capability")
        print("[ZeD] server extras off: no " .. name)
        return
    end
end

-- memory only: a /reloadlua of this file leaves it empty and open() fills it again
local T = { pending = {}, pendN = 0 }
Srv.X = T

-- what the wraps read. These outlive a /reloadlua, so a wrap already on the game's class reads the new file's tests
local On = Srv.exOn or {}
Srv.exOn = On
local Tests = Srv.exTests or {}
Srv.exTests = Tests
Srv.exWrapped = Srv.exWrapped or {}

local F = {}     -- the file's helpers (a table: Kahlua counts every local in the chunk)

-- ---------------------------------------------------------------------------
-- THE TABLE
-- ---------------------------------------------------------------------------
function F.findName()
    local names = ModData.getTableNames()
    local best, found = nil, 0
    for i = 0, names:size() - 1 do
        local n = names:get(i)
        if string.sub(n, 1, #PREFIX) == PREFIX then
            found = found + 1
            if not best or n < best then best = n end
        end
    end
    if found > 1 then Srv.log("found " .. found .. " extras tables; using the first by name") end
    return best
end

function F.open()
    if T.md then return T.md end
    local name = F.findName() or (PREFIX .. getRandomUUID())
    local md = ModData.getOrCreate(name)
    md.schema = md.schema or SCHEMA
    md.set = md.set or Ex.defaults()
    md.claims = md.claims or {}          -- key -> { owner, at, name, x, y }
    md.seen = md.seen or {}              -- username -> when a claim's owner was last on
    if md.schema > SCHEMA then
        T.frozen = true                  -- data from a newer ZeD: read it, never change it
    end
    while md.schema < SCHEMA do
        local step = MIGRATE[md.schema]
        if not step or not pcall(step, md) then
            T.frozen = true              -- a missing or failed step: stop here, write nothing
            break
        end
        md.schema = md.schema + 1
    end
    if T.frozen then Srv.log("the extras table is frozen: schema " .. tostring(md.schema) .. ", this ZeD knows " .. SCHEMA) end
    T.md = md
    T.counts = {}
    for _, c in pairs(md.claims) do T.counts[c.owner] = (T.counts[c.owner] or 0) + 1 end
    -- (frozen: nothing here may write, so nothing is enforced and the players are told it's all off)
    F.apply(T.frozen and Ex.defaults() or Ex.clean(md.set))
    return md
end

function F.frozen(p, rid)
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return true end
    return false
end

-- ---------------------------------------------------------------------------
-- WHOSE CAR, WHOSE HOUSE
-- ---------------------------------------------------------------------------
function F.drop(md, key, c)
    md.claims[key] = nil
    local n = (T.counts[c.owner] or 1) - 1
    if n > 0 then
        T.counts[c.owner] = n
    else
        T.counts[c.owner], md.seen[c.owner] = nil, nil
    end
end

-- this car's claim. A burnt car is a wreck: the claim goes with the car it was on
function F.claimOf(v)
    local md = T.md
    if not md then return nil end
    local key = Ex.keyOf(v:getSqlId())
    local c = md.claims[key]
    if not c then return nil end
    if v:isBurnt() then
        F.drop(md, key, c)
        Srv.action("vehicle", c.owner, "claim gone: burnt", nil, c.name, math.floor(v:getX()), math.floor(v:getY()))
        return nil
    end
    return c
end

function F.fellow(p, owner)
    local f = Faction.getPlayerFaction(p)
    return f ~= nil and (f:getOwner() == owner or f:getPlayers():contains(owner))
end

-- the claim that stops this player, or nil
function F.carBlock(p, v)
    if not (p and v) then return nil end
    local c = F.claimOf(v)
    if not c or c.owner == p:getUsername() then return nil end
    if Srv.can(p, CAP[Ex.CAP_CAR]) then return nil end
    if Ex.CLAIM_SHARE_FACTION and F.fellow(p, c.owner) then return nil end
    return c
end

-- every safehouse this square is in, or on the lot of. Any that lets the player in lets them through, or two lots that
-- touch would stop a member at their own fence; a war the game has started lets the attacker through, as its own tests do
function F.houseBlock(p, x, y)
    local list = SafeHouse.getSafehouseList()
    local grow = On.lot and Ex.LOT_TILES or 0
    local stop = nil
    for i = 0, list:size() - 1 do
        local h = list:get(i)
        local hx, hy = h:getX(), h:getY()
        if x >= hx - grow and x < hx + h:getW() + grow and y >= hy - grow and y < hy + h:getH() + grow then
            if h:playerAllowed(p) or WarManager.isWarStarted(h:getOnlineID(), p:getUsername()) then return nil end
            stop = h
        end
    end
    if stop and Srv.can(p, CAP[Ex.CAP_HOUSE]) then return nil end
    return stop
end

-- is this square inside a safehouse's walls, whoever is asking
function F.insideHouse(x, y)
    local list = SafeHouse.getSafehouseList()
    for i = 0, list:size() - 1 do
        local h = list:get(i)
        local hx, hy = h:getX(), h:getY()
        if x >= hx and x < hx + h:getW() and y >= hy and y < hy + h:getH() then return true end
    end
    return false
end

-- a refusal: said to the player and logged, one in NOTE_MS
function F.refused(p, what, kind, who, x, y)
    if Srv.left(p, "x_no", L.NOTE_MS) then return end
    Srv.mark(p, "x_no")
    Srv.to(p, Ex.MOD, "x_no", { what = what, who = who })
    Srv.action(kind, p:getUsername(), "refused: " .. what, who, nil, math.floor(x), math.floor(y))
end

function F.refuseCar(p, v, what)
    local c = F.carBlock(p, v)
    if not c then return false end
    F.refused(p, what, "vehicle", c.owner, v:getX(), v:getY())
    return true
end

function F.refuseHouse(p, sq, what)
    if not sq then return false end
    local x, y = sq:getX(), sq:getY()
    local h = F.houseBlock(p, x, y)
    if not h then return false end
    F.refused(p, what, "safehouse", h:getOwner(), x, y)
    return true
end

-- ---------------------------------------------------------------------------
-- THE WRAPS. Each is put on the first time its system is on, and never before
-- ---------------------------------------------------------------------------
-- complete() on the server; false is the game's own refusal (the head of this file). A test that fails lets the game's
-- function run: a bug here must not stop a game action
function F.wrapDone(name, cls, test)
    Tests[name] = test
    if Srv.exWrapped[name] then return end
    if not (cls and cls.complete) then
        Srv.log("server extras: no " .. name .. " in this game; that part of the extras does nothing")
        return
    end
    Srv.exWrapped[name] = true
    local base = cls.complete
    cls.complete = function(self)
        local ok, no = pcall(Tests[name], self)
        if ok and no then return false end
        return base(self)
    end
end

function F.armParts()
    local function test(self)
        if not On.parts then return false end
        return F.refuseCar(self.character, self.vehicle, "parts")
    end
    F.wrapDone("ISUninstallVehiclePart", ISUninstallVehiclePart, test)
    F.wrapDone("ISTakeEngineParts", ISTakeEngineParts, test)
    F.wrapDone("ISTakeGasolineFromVehicle", ISTakeGasolineFromVehicle, test)
end

function F.armDrive()
    local function test(self)
        if not On.drive then return false end
        local p = self.character
        return F.refuseCar(p, p:getVehicle(), "drive")
    end
    F.wrapDone("ISStartVehicleEngine", ISStartVehicleEngine, test)
    F.wrapDone("ISHotwireVehicle", ISHotwireVehicle, test)
end

-- after the game's own handler: the listeners run in the order they were added, and the game's file loads first
function F.towWatch(module, command, player, args)
    if not On.tow or module ~= "vehicle" or command ~= "attachTrailer" or type(args) ~= "table" then return end
    -- (a client's word: anything but a number here matches no overload of getVehicleById)
    if not (Ex.okVeh(args.vehicleA) and Ex.okVeh(args.vehicleB)) then return end
    local a, b = getVehicleById(args.vehicleA), getVehicleById(args.vehicleB)
    if not (a and b) then return end
    local c = F.carBlock(player, a) or F.carBlock(player, b)
    if not c then return end
    a:breakConstraint(player, true, false)
    F.refused(player, "tow", "vehicle", c.owner, a:getX(), a:getY())
end

function F.armTow()
    if Srv.exTowHooked then return end
    Srv.exTowHooked = true
    -- (looked up at each call, so a reload of this file takes effect)
    Events.OnClientCommand.Add(function(module, command, player, args)
        local ok, err = pcall(function() ZeD.Srv.X.towWatch(module, command, player, args) end)
        if not ok then Srv.log("tow watch failed: " .. tostring(err)) end
    end)
end

function F.armDismantle()
    F.wrapDone("ISDismantleAction", ISDismantleAction, function(self)
        if not On.dismantle then return false end
        return F.refuseHouse(self.character, self.thumpable:getSquare(), "dismantle")
    end)
    F.wrapDone("ISMoveablesAction", ISMoveablesAction, function(self)
        if not On.dismantle or self.mode ~= "scrap" then return false end
        return F.refuseHouse(self.character, self.square, "dismantle")
    end)
    F.wrapDone("ISUnbarricadeAction", ISUnbarricadeAction, function(self)
        if not On.dismantle then return false end
        return F.refuseHouse(self.character, self.item:getSquare(), "dismantle")
    end)
end

-- a swing: the room goes on before the damage, and the old health comes back on the next tick (the head of this file)
function F.swing(chr, weapon, obj)
    if not On.destroy then return end
    if not (instanceof(chr, "IsoPlayer") and (instanceof(obj, "IsoDoor") or instanceof(obj, "IsoThumpable") or instanceof(obj, "IsoBarricade"))) then return end
    if not F.refuseHouse(chr, obj:getSquare(), "destroy") then return end
    local was = obj:getHealth()
    obj:setHealth(was + math.max(1, weapon:getDoorDamage()) * L.HIT_ROOM)
    T.pendN = T.pendN + 1
    T.pending[T.pendN] = { obj = obj, health = was }
end

function F.armDestroy()
    F.wrapDone("ISDestroyStuffAction", ISDestroyStuffAction, function(self)
        if not On.destroy then return false end
        return F.refuseHouse(self.character, self.item:getSquare(), "destroy")
    end)
    if Srv.exHitHooked then return end
    Srv.exHitHooked = true
    Events.OnWeaponHitThumpable.Add(function(chr, weapon, obj)
        local ok, err = pcall(function() ZeD.Srv.X.swing(chr, weapon, obj) end)
        if not ok then Srv.log("swing watch failed: " .. tostring(err)) end
    end)
end

function F.armClock()
    if Srv.exClockHooked then return end
    Srv.exClockHooked = true
    -- (a Lua error costs one pass, not the event chain)
    Events.OnTickEvenPaused.Add(function()
        local ok, err = pcall(function() ZeD.Srv.X.tick() end)
        if not ok and not T.tickFailed then
            T.tickFailed = true
            print("[ZeD] server: extras clock failed: " .. tostring(err))
            Srv.log("extras clock failed: " .. tostring(err))
        end
    end)
end

-- what the settings mean: On for the wraps, and each system's wraps put on the first time it is on
function F.apply(set)
    T.set = set
    local v, s = set.vc, set.sp
    On.claims, On.parts, On.drive, On.tow = v.on, v.on and v.parts, v.on and v.drive, v.on and v.tow
    On.dismantle, On.destroy, On.lot = s.on and s.dismantle, s.on and s.destroy, s.on and s.lot
    if On.parts then F.armParts() end
    if On.drive then F.armDrive() end
    if On.tow then F.armTow() end
    if On.dismantle then F.armDismantle() end
    if On.destroy then F.armDestroy() end
    if On.claims or On.destroy then F.armClock() end
end

-- ---------------------------------------------------------------------------
-- THE CLOCK: only once a system that needs it has been on
-- ---------------------------------------------------------------------------
function F.lapse(md, now)
    local gone, n = {}, 0
    local days = T.set.vc.lapse
    for key, c in pairs(md.claims) do
        if now - (md.seen[c.owner] or c.at) >= days * 86400 then
            n = n + 1
            gone[n] = key
        end
    end
    for i = 1, n do
        local key = gone[i]
        local c = md.claims[key]
        F.drop(md, key, c)
        Srv.action("vehicle", c.owner, "claim lapsed", nil, c.name, c.x, c.y)
    end
end

-- who is on, and who is driving: one pass over the players, no scan of vehicles
function F.poll(md, now)
    Srv.eachOnline(function(o)
        local u = o:getUsername()
        if T.counts[u] then md.seen[u] = now end
        local v = o:getVehicle()
        if v and v:isDriver(o) then
            local c = F.claimOf(v)
            if c then
                if c.owner == u then
                    c.x, c.y = math.floor(v:getX()), math.floor(v:getY())
                elseif On.drive and v:isEngineRunning() and F.carBlock(o, v) then
                    v:shutOff()
                    F.refused(o, "drive", "vehicle", c.owner, v:getX(), v:getY())
                end
            end
        end
    end)
end

function T.tick()
    if T.pendN > 0 then
        for i = 1, T.pendN do
            local e = T.pending[i]
            e.obj:setHealth(e.health)
            T.pending[i] = nil
        end
        T.pendN = 0
    end
    if not On.claims then return end
    local ms = getTimestampMs()
    if T.pollAt and ms - T.pollAt < L.POLL_MS then return end
    T.pollAt = ms
    local md = F.open()
    local now = getTimestamp()
    F.poll(md, now)
    if T.frozen then return end
    if not T.lapseAt or now - T.lapseAt >= L.LAPSE_EVERY_S then
        T.lapseAt = now
        F.lapse(md, now)
    end
end
T.towWatch, T.swing = F.towWatch, F.swing

-- ---------------------------------------------------------------------------
-- THE COMMANDS: every one takes its player from the event
-- ---------------------------------------------------------------------------
local function reg(command, opts, fn) Srv.register(Ex.MOD, command, opts, fn) end

function F.pushSet(set)
    Srv.eachOnline(function(o) Srv.to(o, Ex.MOD, "x_set", { set = set }) end)
end

reg("x_save", { cap = CAP[Ex.CAP_EDIT], limit = L.SAVE_MS }, function(p, a, rid)
    local md = F.open()
    if F.frozen(p, rid) then return end
    if type(a.set) ~= "table" then
        Srv.bad(p, "x_save")
        return Srv.ack(p, rid, false, "text")
    end
    local set = Ex.clean(a.set)
    local was = T.set
    -- (a claim held while the system was off has not been away: its time starts again now)
    if set.vc.on and not was.vc.on then
        local now = getTimestamp()
        for u in pairs(T.counts) do md.seen[u] = now end
    end
    md.set = set
    F.apply(set)
    Srv.action("admin", p:getUsername(), "server extras", nil, Ex.summary(set))
    Srv.ack(p, rid, true)
    F.pushSet(set)
end)

function F.near(p, v)
    local dx, dy = p:getX() - v:getX(), p:getY() - v:getY()
    return dx * dx + dy * dy <= L.REACH_TILES * L.REACH_TILES
end

function F.count(u) return T.counts[u] or 0 end

function F.carName(v)
    local sc = v:getScript()
    return sc and (sc:getCarModelName() or sc:getName()) or nil
end

reg("x_claim", { limit = L.CLAIM_MS }, function(p, a, rid)
    local md = F.open()
    if F.frozen(p, rid) then return end
    local vc = T.set.vc
    if not vc.on then return Srv.ack(p, rid, false, "off") end
    if not Ex.okVeh(a.veh) then
        Srv.bad(p, "x_claim")
        return Srv.ack(p, rid, false, "gone")
    end
    local v = getVehicleById(a.veh)
    if not v then return Srv.ack(p, rid, false, "gone") end
    local u = p:getUsername()
    local d = v:getDriver()
    local sql = v:getSqlId()
    if not F.near(p, v) then return Srv.ack(p, rid, false, "far") end
    if v:isBurnt() then return Srv.ack(p, rid, false, "burnt") end
    if d and d ~= p then return Srv.ack(p, rid, false, "driven") end
    if sql < 0 then return Srv.ack(p, rid, false, "soon") end
    if F.claimOf(v) then return Srv.ack(p, rid, false, "taken") end
    if F.count(u) >= vc.per then return Srv.ack(p, rid, false, "many") end
    if Ex.CLAIM_NEEDS_KEY and not p:getInventory():haveThisKeyId(v:getKeyId()) then return Srv.ack(p, rid, false, "key") end
    local total = 0
    for _ in pairs(md.claims) do total = total + 1 end
    if total >= L.CLAIMS_MAX then return Srv.ack(p, rid, false, "full") end
    local x, y = math.floor(v:getX()), math.floor(v:getY())
    md.claims[Ex.keyOf(sql)] = { owner = u, at = getTimestamp(), name = F.carName(v), x = x, y = y }
    T.counts[u] = F.count(u) + 1
    md.seen[u] = getTimestamp()
    Srv.action("vehicle", u, "claim", nil, F.carName(v), x, y)
    Srv.ack(p, rid, true)
end)

reg("x_release", { limit = L.CLAIM_MS }, function(p, a, rid)
    local md = F.open()
    if F.frozen(p, rid) then return end
    if not Ex.okKey(a.key) then
        Srv.bad(p, "x_release")
        return Srv.ack(p, rid, false, "gone")
    end
    local c = md.claims[a.key]
    if not c then return Srv.ack(p, rid, false, "gone") end
    local u = p:getUsername()
    if c.owner ~= u and not Srv.can(p, CAP[Ex.CAP_CAR]) then
        Srv.deny(p, "x_release")
        return Srv.ack(p, rid, false, "perm")
    end
    F.drop(md, a.key, c)
    Srv.action("vehicle", u, "release", (c.owner ~= u) and c.owner or nil, c.name, c.x, c.y)
    Srv.ack(p, rid, true)
end)

-- what a player may read of one car: who holds it, never when they were last on
reg("x_veh", { limit = L.VEH_MS }, function(p, a, rid)
    local md = F.open()
    if not Ex.okVeh(a.veh) then return Srv.bad(p, "x_veh") end
    local vc = T.set.vc
    if not vc.on then return end
    local v = getVehicleById(a.veh)
    if not v then return end
    local u = p:getUsername()
    local r = { veh = a.veh, n = F.count(u), per = vc.per, staff = Srv.can(p, CAP[Ex.CAP_CAR]) }
    local c = F.claimOf(v)
    if c then
        r.key, r.owner, r.mine = Ex.keyOf(v:getSqlId()), c.owner, c.owner == u
    end
    Srv.to(p, Ex.MOD, "x_veh", r)
end)

-- my own claims, wherever the cars are
reg("x_mine", { limit = L.MINE_MS }, function(p, a, rid)
    local md = F.open()
    local u = p:getUsername()
    local rows, n = {}, 0
    for key, c in pairs(md.claims) do
        if c.owner == u then
            n = n + 1
            rows[n] = { key = key, name = c.name, x = c.x, y = c.y }
        end
    end
    Srv.to(p, Ex.MOD, "x_mine", { rows = rows, n = n, per = T.set.vc.per })
end)

-- the map's click. The game's /teleportto does the going and asks its own capability again: this says the setting is on,
-- and logs it
reg("x_tp", { cap = CAP[Ex.CAP_MAP], limit = L.TP_MS }, function(p, a, rid)
    F.open()
    if not T.set.tp.on then return Srv.ack(p, rid, false, "off") end
    if not (Ex.okCoord(a.x) and Ex.okCoord(a.y)) then
        Srv.bad(p, "x_tp")
        return Srv.ack(p, rid, false, "text")
    end
    Srv.action("admin", p:getUsername(), "map teleport", nil, nil, a.x, a.y)
    Srv.ack(p, rid, true)
end)

-- a client's report of what it took. Item transfers are Java here, so this is the player's word: the line says so, and the
-- server only tests that it could be true (the setting is on, the square is inside a safehouse, the player is by it)
function F.tookText(rows)
    if type(rows) ~= "table" then return nil end
    local parts, n = {}, 0
    for i = 1, L.TOOK_ROWS do
        local r = rows[i]
        if type(r) ~= "table" then break end
        local name = Tk.name(r.name)
        if name == "" or not Tk.whole(r.n) or r.n > L.TOOK_MAX then return nil end
        n = n + 1
        parts[n] = tostring(r.n) .. " x " .. string.sub(name, 1, L.TOOK_NAME)
    end
    if n == 0 then return nil end
    return table.concat(parts, ", ")
end

reg("x_took", { limit = L.TOOK_MS }, function(p, a, rid)
    F.open()
    if not T.set.cl.on then return end
    if not (Ex.okCoord(a.x) and Ex.okCoord(a.y)) or type(a.z) ~= "number" then return Srv.bad(p, "x_took") end
    local text = F.tookText(a.rows)
    if not text then return Srv.bad(p, "x_took") end
    if math.abs(p:getX() - a.x) > L.TOOK_REACH or math.abs(p:getY() - a.y) > L.TOOK_REACH then return Srv.bad(p, "x_took") end
    if not F.insideHouse(a.x, a.y) then return Srv.bad(p, "x_took") end
    local from = (type(a.from) == "string") and string.sub(Tk.name(a.from), 1, L.TOOK_NAME) or nil
    Srv.action("container", p:getUsername(), "took", from, text .. " (reported by their game)", a.x, a.y, a.z)
end)

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
Srv.modules[Ex.MOD] = true
Srv.helloAdds.extras = function(p, r)
    F.open()
    r.ex, r.exFrozen = T.set, T.frozen
end

if Srv.exHooked == nil then
    Srv.exHooked = true
    Events.OnInitGlobalModData.Add(function() if ZeD.Srv.openExtras then ZeD.Srv.openExtras() end end)
end
Srv.openExtras = F.open

return T
