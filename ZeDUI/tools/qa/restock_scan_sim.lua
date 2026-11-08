-- ZeDUI/tools/qa/restock_scan_sim.lua  (Nov 7 2026, Build; outside performance review, finding 1)
-- Restock's building walk, with no game running. The real ZeD_Restock.lua and ZeD_EquipLoadout.lua run on Lua 5.1
-- stubs of the game, side by side with the versions before the fix (git show PRE:<file>, PRE below):
--   The scan: a 20x20 house on two levels (a porch column outside the building, containers, a two-container
--     dresser, an unexplored and a locked one, a sink, a toilet, an empty rain barrel, a tainted tub); a walk round
--     it, then one more step. Every scan gives the same sources (container, square, object index, name, in reach)
--     and taps, in the same order, as before; the getGridSquare calls are counted, before and after.
--   What changes in the house: a container opened, the sink drained, the barrel filled, a crate placed (with the
--     game's OnObjectAdded) or taken away (OnObjectAboutToBeRemoved), a crate placed with no event (seen once the
--     building is walked again, R.BUILDING_MS), a run's start (R.forgetBuildings): the same as before at once;
--     the build menu, placed furniture and plumbing (wrapped) walk it again; the old buildings dropped.
--   A Casual run's ticks at 20, 30 and 60 frames a second: the building is not walked every tick (getGridSquare and
--     the walks counted; this part fails on 29c27bf4, where the run's forced plan walked it each tick).
--   A clock gone back: the scan, the run tick and the home check carry on.
--   The ticks by the clock: the home check (what you leave with) waits R.HOME_TICK_MS, not 30 frames.
--   The Equip tab's fold, shut: the heading's ready count is the same words as before, and the plan (the walk) is
--     no longer made for it; with the doll's ghosts reading the plan first, the count is the plan's.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/restock_scan_sim.lua   (or add a revision: the new code from git)
-- It prints FAIL lines, the call counts, and a last line "restock_scan_sim: N checks, M failed"; exits 1 if any failed.

local PRE = "7f17686e"   -- main before the fix
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]restock_scan_sim%.lua$", "")
local ZD = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end
local function gitShowAt(rev, rel)
    local cmd = 'git -C "' .. (ROOT == "" and "." or ROOT) .. '" show ' .. rev .. ":" .. rel
    local h = io.popen(cmd)
    if not h then return nil end
    local s = h:read("*a")
    h:close()
    if not s or #s < 100 then return nil end
    return s
end
local function gitShow(rel) return gitShowAt(PRE, rel) end

-- ---------------------------------------------------------------------------
-- THE WORLD (shared by the old and the new code)
-- ---------------------------------------------------------------------------
local W = { now = 100000, gets = 0, sq = {}, nextId = 1 }
local function key(x, y, z) return x .. "," .. y .. "," .. z end
local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, _t = t }
end
local function newId() W.nextId = W.nextId + 1; return W.nextId end

local function newCont(ty, explored)
    local c = { id = newId(), ty = ty, explored = explored ~= false, items = {} }
    function c:getType() return self.ty end
    function c:isExplored() return self.explored end
    function c:getItems() return jlist(self.items) end
    return c
end
-- an object: { conts = { cont... }, water = amount or nil, fluid = true (a fluid container), tainted, custom, class }
local function newObj(o)
    o.id = newId()
    o._class = o.class or "IsoObject"
    o.conts = o.conts or {}
    function o:getContainerCount() return #self.conts end
    function o:getContainerByIndex(i) return self.conts[i + 1] end
    function o:hasWater() return (self.water or 0) > 0 end
    function o:getFluidAmount() return self.water or 0 end
    function o:isTaintedWater() return self.tainted == true end
    function o:getFluidContainer() if self.fluid then return {} end return nil end
    function o:getUsesExternalWaterSource() return self.ext == true end
    function o:getName() return self.name or "" end
    function o:isLockedToCharacter() return self.locked == true end
    function o:isLockedByPadlock() return false end
    function o:getKeyId() return -1 end
    function o:getProperties()
        local cn, piped = self.custom, self.piped
        return { get = function(_, k) if k == "CustomName" then return cn end return nil end,
                 has = function(_, f) return f == "waterPiped" and piped == true end }
    end
    return o
end

local building = {}
local BX, BY, BW, BH = 100, 200, 20, 20
local def = {}
function def:getX() return BX end
function def:getY() return BY end
function def:getX2() return BX + BW end
function def:getY2() return BY + BH end
function def:getMinLevel() return 0 end
function def:getMaxLevel() return 1 end
function building:getDef() return def end

local function newSquare(x, y, z, b)
    local s = { x = x, y = y, z = z, b = b, objs = { newObj({}) } }   -- (the floor)
    function s:getX() return self.x end
    function s:getY() return self.y end
    function s:getZ() return self.z end
    function s:getBuilding() return self.b end
    function s:getObjects() return jlist(self.objs) end
    function s:getWorldObjects() return jlist({}) end
    function s:canReachTo() return true end
    function s:getVehicleContainer() return nil end
    W.sq[key(x, y, z)] = s
    return s
end
for z = 0, 1 do
    for y = BY - 2, BY + BH + 1 do
        for x = BX - 2, BX + BW + 1 do
            local inB = x >= BX and x < BX + BW - 1 and y >= BY and y < BY + BH   -- (the last column is the porch)
            if z == 0 or inB then newSquare(x, y, z, inB and building or nil) end
        end
    end
end
local function put(x, y, z, o) local s = W.sq[key(x, y, z)]; s.objs[#s.objs + 1] = o; return o end

-- the house's things
local OBJ = {}
for i = 0, 9 do OBJ["crate" .. i] = put(BX + 1 + i * 2 % 17, BY + 1 + i, 0, newObj({ conts = { newCont("crate") } })) end
OBJ.dresser = put(BX + 4, BY + 3, 0, newObj({ conts = { newCont("dresser"), newCont("smalldrawer") }, name = "Dresser" }))
OBJ.closed = put(BX + 9, BY + 9, 0, newObj({ conts = { newCont("wardrobe", false) } }))
OBJ.locked = put(BX + 12, BY + 14, 0, newObj({ conts = { newCont("locker") }, class = "IsoThumpable", locked = true }))
OBJ.fridge = put(BX + 2, BY + 2, 0, newObj({ conts = { newCont("fridge"), newCont("freezer") } }))
OBJ.sink = put(BX + 3, BY + 2, 0, newObj({ water = 10, custom = "Sink" }))
OBJ.toilet = put(BX + 6, BY + 15, 0, newObj({ water = 8, custom = "Toilet" }))
OBJ.barrel = put(BX + 15, BY + 4, 0, newObj({ water = 0, fluid = true, custom = "Rain Collector Barrel" }))
OBJ.tub = put(BX + 16, BY + 16, 0, newObj({ water = 30, tainted = true, custom = "Bathtub" }))
OBJ.upCrate = put(BX + 5, BY + 5, 1, newObj({ conts = { newCont("crate") } }))
OBJ.upSink = put(BX + 8, BY + 6, 1, newObj({ water = 4, custom = "Sink" }))
OBJ.porch = put(BX + BW - 1, BY + 5, 0, newObj({ conts = { newCont("mailbox") } }))   -- (outside the building)
-- the world outside: a crate in the yard
OBJ.yard = put(BX - 2, BY - 2, 0, newObj({ conts = { newCont("crate") } }))

local cell = {}
function cell:getGridSquare(x, y, z) W.gets = W.gets + 1; return W.sq[key(x, y, z)] end

-- the player
local P = { x = BX + 1, y = BY + 1, z = 0, inv = {} }
function P:getPlayerNum() return 0 end
function P:getCurrentSquare() return W.sq[key(self.x, self.y, self.z)] end
function P:getX() return self.x + 0.5 end
function P:getY() return self.y + 0.5 end
function P:getZ() return self.z end
function P:isLocalPlayer() return true end
function P:getStats() return { getNumVisibleZombies = function() return 0 end } end
function P:getBodyDamage() return { getOverallBodyHealth = function() return 100 end } end
function P:getInventoryWeight() return 1 end
function P:getMaxWeight() return 20 end
function P:getInventory()
    local inv = {}
    function inv.haveThisKeyId() return false end
    function inv.getItems() return jlist(P.inv) end
    return inv
end

-- ---------------------------------------------------------------------------
-- THE GAME'S GLOBALS (one base; each version of the code gets its own environment over it)
-- ---------------------------------------------------------------------------
local handlers = {}
local function event(name)
    return { Add = function(fn) handlers[name] = handlers[name] or {}; table.insert(handlers[name], fn) end }
end
local function fire(name, ...)
    for _, fn in ipairs(handlers[name] or {}) do fn(...) end
end
local store = { applied = { days = 1 } }
local Lstub = { gen = 0 }
function Lstub.on() return true end
function Lstub.store() return store end
function Lstub.get() return nil end

local base = {
    getCell = function() return cell end,
    getTimestampMs = function() return W.now end,
    instanceof = function(o, cls) return type(o) == "table" and (o._class == cls or (cls == "IsoObject" and o._class ~= nil)) end,
    isClient = function() return false end,
    getText = function(k) return k end,
    getTextOrNull = function() return nil end,
    getSpecificPlayer = function(n) if n == 0 then return P end return nil end,
    require = function() end,
    Events = setmetatable({}, { __index = function(t, k) local e = event(k); rawset(t, k, e); return e end }),
    ISTimedActionQueue = { isPlayerDoingAction = function() return false end, clear = function() end, getTimedActionQueue = function() return nil end },
    IsoFlagType = { waterPiped = "waterPiped" },
    -- the game's build, placing and plumbing (wrapped by the new code to walk the building again)
    ISBuildIsoEntity = { create = function() return "built" end },
    ISMoveableSpriteProps = { placeMoveable = function() return "placed" end },
    ISPlumbItem = { complete = function() return true end, perform = function() end },
    JoypadState = { players = {} },
}
setmetatable(base, { __index = _G })

local function load(src, name, zed)
    local env = setmetatable({}, { __index = base })
    env._G = env
    env.ZeD = zed
    local f = assert(loadstring(src, name))
    setfenv(f, env)
    f()
    return env
end

local NEWREV = arg and arg[1]
local newSrc = NEWREV and gitShowAt(NEWREV, "42/media/lua/client/ZeD/ZeD_Restock.lua") or readFile(ZD .. "ZeD_Restock.lua")
if NEWREV then print("   the new code from " .. NEWREV) end
local oldSrc = gitShow("42/media/lua/client/ZeD/ZeD_Restock.lua")
check("ZeD_Restock.lua found", newSrc ~= nil)
check("the version before the fix found (git show " .. PRE .. ")", oldSrc ~= nil)
if not (newSrc and oldSrc) then
    print("restock_scan_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(1)
end
local NEW = load(newSrc, "@ZeD_Restock.lua", { Lists = Lstub, logOnce = function() end }).ZeD.Restock
local OLD = load(oldSrc, "@ZeD_Restock.lua(" .. PRE .. ")", { Lists = Lstub, logOnce = function() end }).ZeD.Restock

-- a scan's whole result as words (order kept)
local function sig(sc)
    local t = {}
    for _, s in ipairs(sc.sources) do
        t[#t + 1] = table.concat({ tostring(s.cont.id), s.x, s.y, s.z, tostring(s.reach), tostring(s.name), tostring(s.oi), tostring(s.ci),
                                    tostring(s.floor), tostring(s.vehicle), tostring(s.obj and s.obj.id), tostring(s.sq) }, "/")
    end
    t[#t + 1] = "|"
    for _, w in ipairs(sc.waters) do
        t[#t + 1] = table.concat({ tostring(w.obj.id), w.x, w.y, w.z, tostring(w.reach), tostring(w.name), tostring(w.toilet) }, "/")
    end
    t[#t + 1] = "|" .. tostring(sc.reachSig) .. "|" .. tostring(sc.bkey) .. "|" .. tostring(sc.building)
    return table.concat(t, ";")
end
local function scanBoth(force)
    local g0 = W.gets
    local o = OLD.scan(P, force)
    local g1 = W.gets
    local n = NEW.scan(P, force)
    local g2 = W.gets
    return o, n, g1 - g0, g2 - g1
end
local function same(name, force)
    local o, n, go, gn = scanBoth(force)
    check(name, sig(o) == sig(n), "\n  old " .. sig(o) .. "\n  new " .. sig(n))
    return o, n, go, gn
end

-- ---------------------------------------------------------------------------
section("the walk round the house, then a step")
-- ---------------------------------------------------------------------------
local path = {}
for i = 1, 16 do path[#path + 1] = { BX + i, BY + 1 } end
for i = 2, 16 do path[#path + 1] = { BX + 16, BY + i } end
for i = 15, 1, -1 do path[#path + 1] = { BX + i, BY + 16 } end
local walkOld, walkNew = 0, 0
for i, xy in ipairs(path) do
    P.x, P.y = xy[1], xy[2]
    W.now = W.now + 400   -- (a step, then the UI asks twice more inside the second)
    local o, n, go, gn = same("walk step " .. i .. ": the same sources and taps")
    walkOld, walkNew = walkOld + go, walkNew + gn
    for _ = 1, 2 do
        W.now = W.now + 100
        local _, _, go2, gn2 = same("walk step " .. i .. ", asked again")
        walkOld, walkNew = walkOld + go2, walkNew + gn2
    end
    if i == 1 then
        check("the house's containers are found", #n.sources >= 14, #n.sources)
        local names = {}
        for _, w in ipairs(n.waters) do names[#names + 1] = w.name end
        check("the taps: two sinks and the toilet (not the empty barrel, not the tainted tub)", #n.waters == 3, table.concat(names, ","))
        local porch, closed, locked = false, false, false
        for _, s in ipairs(n.sources) do
            if s.cont == OBJ.porch.conts[1] then porch = true end
            if s.cont == OBJ.closed.conts[1] then closed = true end
            if s.cont == OBJ.locked.conts[1] then locked = true end
        end
        check("the porch (outside the building), the unexplored and the locked container are left out", not (porch or closed or locked))
    end
end
check("the walk took more than 10 seconds (the building walked again on the way)", #path * 0.6 > 10, #path * 0.6)
local _, _, stepOld, stepNew
P.x = P.x + 1
W.now = W.now + 400
_, _, stepOld, stepNew = same("one more step: the same")
print(string.format("   getGridSquare, a walk of %d squares (%d scans asked): before %d, after %d", #path, #path * 3, walkOld, walkNew))
print(string.format("   getGridSquare, one more step: before %d, after %d", stepOld, stepNew))
check("the walk calls getGridSquare far less (a tenth or under)", walkNew * 10 <= walkOld, walkNew .. " vs " .. walkOld)
check("a step calls getGridSquare far less (a tenth or under)", stepNew * 10 <= stepOld, stepNew .. " vs " .. stepOld)

-- ---------------------------------------------------------------------------
section("what changes in the house")
-- ---------------------------------------------------------------------------
local function step() W.now = W.now + 1100 end
OBJ.closed.conts[1].explored = true
step(); local _, n1 = same("a container looked into: found, as before")
local found = false
for _, s in ipairs(n1.sources) do if s.cont == OBJ.closed.conts[1] then found = true end end
check("the opened wardrobe is a source now", found)
OBJ.sink.water = 0
step(); same("the sink drained: gone, as before")
OBJ.barrel.water = 20
step(); local _, n2 = same("the barrel filled by the rain: a tap, as before")
local barrel = false
for _, w in ipairs(n2.waters) do if w.obj == OBJ.barrel then barrel = true end end
check("the filled barrel is a tap now", barrel)
OBJ.locked.locked = false
step(); same("the locker unlocked: found, as before")
local placed = put(BX + 7, BY + 12, 0, newObj({ conts = { newCont("crate") } }))
fire("OnObjectAdded", placed)
step(); same("a crate placed (OnObjectAdded): found, as before")
local sqT = W.sq[key(BX + 7, BY + 12, 0)]
table.remove(sqT.objs)
fire("OnObjectAboutToBeRemoved", placed)
step(); same("the crate taken away (OnObjectAboutToBeRemoved): gone, as before")
-- (no event: the building's squares are walked again after R.BUILDING_MS)
local quiet = put(BX + 13, BY + 3, 0, newObj({ conts = { newCont("crate") } }))
step()
local o3, n3 = scanBoth()
local seen3 = false
for _, s in ipairs(n3.sources) do if s.cont == quiet.conts[1] then seen3 = true end end
check("a crate placed with no event: not yet seen inside R.BUILDING_MS (the one difference)", not seen3 and sig(o3) ~= sig(n3))
W.now = W.now + NEW.BUILDING_MS
same("... seen once the building is walked again, as before")
local quiet2 = put(BX + 13, BY + 7, 0, newObj({ conts = { newCont("crate") } }))
step(); NEW.forgetBuildings(); same("a run starts (R.forgetBuildings): the building walked at once, as before")
check("R.BUILDING_MS is 10 seconds", NEW.BUILDING_MS == 10000, NEW.BUILDING_MS)
-- outside the building: only what's in reach
P.x, P.y = BX - 1, BY - 1
step(); local _, n4 = same("outside: only what is in reach, as before")
check("outside: the yard crate in reach", n4.building == nil and #n4.sources == 1, #n4.sources)
-- upstairs
P.x, P.y, P.z = BX + 5, BY + 6, 1
step(); same("upstairs, beside the crate: as before")
P.x, P.y, P.z = BX + 1, BY + 1, 0
NEW.forget(P); OLD.forget(P)
step()
local g0 = W.gets
NEW.scan(P)
check("forget (a Casual run's tick) keeps the building's squares: no walk", W.gets - g0 < 100, W.gets - g0)
local _ = quiet2

-- ---------------------------------------------------------------------------
section("built, placed, plumbed; the water a sink gets later")
-- ---------------------------------------------------------------------------
-- a dry sink the game marks waterPiped: water from outside comes later with no event (the building walked
-- since): seen at once, as before
local pipedSink = put(BX + 10, BY + 15, 0, newObj({ water = 0, custom = "Sink", piped = true }))
step(); NEW.forgetBuildings(); same("a dry waterPiped sink: as before")
pipedSink.water = 6
step(); same("... its water comes: seen at once, as before")
-- a dry sink plumbed (ISPlumbItem): it uses an outside source from then on
local drySink = put(BX + 11, BY + 15, 0, newObj({ water = 0, custom = "Sink" }))
step(); NEW.forgetBuildings(); same("a dry sink, not piped: as before")
NEW.scan(P, true)
check("a scan keeps a building", NEW.buildingsKept and NEW.buildingsKept() > 0)
drySink.ext = true
check("plumbing completes as the game's own (its return kept)", base.ISPlumbItem.complete({}) == true)
check("plumbing walks the building again", NEW.buildingsKept and NEW.buildingsKept() == 0)
step(); same("the plumbed sink, dry: as before")
drySink.water = 3
step(); same("... its water comes with no event: seen at once, as before")
NEW.scan(P, true)
check("the build menu's create as the game's own (its return kept)", base.ISBuildIsoEntity.create({}, 1, 2, 0) == "built")
check("building walks the building again", NEW.buildingsKept and NEW.buildingsKept() == 0)
NEW.scan(P, true)
check("placing furniture as the game's own", base.ISMoveableSpriteProps.placeMoveable({}) == "placed")
check("placing furniture walks the building again", NEW.buildingsKept and NEW.buildingsKept() == 0)
local wrapped = base.ISPlumbItem.complete
if NEW.wrapBuildHooks then NEW.wrapBuildHooks() end
check("wrapped once (again at game start: no second wrap)", base.ISPlumbItem.complete == wrapped)
local lateOrig = function() return "late" end
base.ISBuildIsoEntity = { create = lateOrig }   -- (the build menu's file loads after this one)
fire("OnGameStart")
check("the build menu loaded later is wrapped at game start", base.ISBuildIsoEntity.create ~= lateOrig and base.ISBuildIsoEntity.create() == "late")

-- ---------------------------------------------------------------------------
section("a forced scan, the old buildings")
-- ---------------------------------------------------------------------------
step(); NEW.scan(P)
local g1 = W.gets
NEW.scan(P, true)
check("force (a run's tick) looks again at the squares, never walks the building", W.gets - g1 < 100, W.gets - g1)
-- six small houses away from here, one after another
local smalls = {}
for i = 1, 6 do
    local sb, sd = {}, {}
    local sx, sy = 400 + i * 10, 400
    function sd:getX() return sx end
    function sd:getY() return sy end
    function sd:getX2() return sx + 3 end
    function sd:getY2() return sy + 3 end
    function sd:getMinLevel() return 0 end
    function sd:getMaxLevel() return 0 end
    function sb:getDef() return sd end
    for yy = sy, sy + 2 do for xx = sx, sx + 2 do newSquare(xx, yy, 0, sb) end end
    put(sx + 1, sy + 1, 0, newObj({ conts = { newCont("crate") } }))
    smalls[i] = { x = sx + 1, y = sy }
end
for i = 1, 6 do
    P.x, P.y, P.z = smalls[i].x, smalls[i].y, 0
    step(); same("small house " .. i .. ": as before")
end
check("the last R.BUILDING_KEEP buildings kept, no more", NEW.buildingsKept and NEW.buildingsKept() <= 4, NEW.buildingsKept and NEW.buildingsKept())
P.x, P.y, P.z = BX + 1, BY + 1, 0
W.now = W.now + 61000
same("a minute on, home again: as before")
check("past a minute the others are dropped", NEW.buildingsKept and NEW.buildingsKept() == 1, NEW.buildingsKept and NEW.buildingsKept())

-- ---------------------------------------------------------------------------
section("a Casual run's ticks (20, 30, 60 frames a second)")
-- ---------------------------------------------------------------------------
-- The run's own plan is stubbed to the part that matters here: R.runJobs asks R.plan(p, { force = true }),
-- which scans with force; one job out of reach keeps the run waiting while you walk a step a second.
local realPlan = NEW.plan
local plans = 0
NEW.plan = function(p, opts)
    plans = plans + 1
    local sc = NEW.scan(p, opts.force)
    local farSq = W.sq[key(BX + 17, BY + 17, 0)]
    return { jobs = { { kind = "take", item = { getID = function() return 1 end }, sq = farSq } }, scan = sc, count = {}, rows = {} }
end
local SECS = 30
local function casual(fps, back)
    local run = { pn = 0, mode = "casual", kind = "restock", acts = {}, z0 = 0, hp0 = 100, tried = {}, list = "" }
    NEW.runs[0] = run
    P.x, P.y, P.z = BX + 1, BY + 1, 0
    if NEW.forgetBuildings then NEW.forgetBuildings() end   -- (the run's start)
    local g0, w0, p0 = W.gets, NEW.walks or 0, plans
    local t0 = W.now
    local pAt = nil
    for i = 1, SECS * fps do
        W.now = t0 + math.floor(i * 1000 / fps)
        if back and i > SECS * fps / 2 then
            W.now = W.now - 60000   -- (the clock goes back half way)
            pAt = pAt or plans
        end
        if i % fps == 0 then P.x = BX + 1 + (i / fps) % 12 end
        NEW._onTick()
    end
    NEW.runs[0] = nil
    local pHalf = pAt and (plans - pAt) or 0
    W.now = t0 + SECS * 1000
    return W.gets - g0, (NEW.walks or 0) - w0, plans - p0, run, pHalf
end
for _, fps in ipairs({ 20, 30, 60 }) do
    local gets, walks, ticks, run = casual(fps)
    print(string.format("   Casual run, %d s at %d fps: %d run ticks, %d building walks, getGridSquare %d", SECS, fps, ticks, walks, gets))
    check(fps .. " fps: the run kept going (no error)", not run.done, run.stopped)
    local every = math.ceil(167 / (1000 / fps))   -- (frames between run ticks)
    check(fps .. " fps: the run ticked every R.RUN_TICK_MS (the first frame past it)", ticks >= math.floor(SECS * fps / every) - 1, ticks)
    -- a walk of this house is ~1,000 getGridSquare; a tick without one ~40
    local budget = ticks * 60 + (SECS / 10 + 2) * 1100
    check(fps .. " fps: no building walk per tick (getGridSquare within " .. budget .. ")", gets <= budget, gets)
    check(fps .. " fps: the building walked at the start and every R.BUILDING_MS only", NEW.walks ~= nil and walks <= SECS / 10 + 1, walks)
end
local _, _, _, _, pBack = casual(60, true)
check("a clock gone back: the run still ticks", pBack > 0, pBack)
NEW.plan = realPlan

-- Casual weighs each take it queues: from 1 of 20 kg, three 8 kg takes in reach queue two (1 + 8 + 8), not all three
do
    local function heavy(id) return { getID = function() return id end, getUnequippedWeight = function() return 8 end, getDisplayName = function() return "Axe" end } end
    local src = { name = "Crate" }
    local realJobs, realActs = NEW.runJobs, NEW.actionsFor
    NEW.runJobs = function() return { { kind = "take", item = heavy(11), src = src }, { kind = "take", item = heavy(12), src = src },
                                      { kind = "take", item = heavy(13), src = src } }, { scan = { reachSig = "w" }, count = {} } end
    local queued = 0
    NEW.actionsFor = function() queued = queued + 1; return {} end
    local run = { pn = 0, mode = "casual", kind = "restock", acts = {}, z0 = 0, hp0 = 100, tried = {}, list = "" }
    NEW.runs[0] = run
    W.now = W.now + 1000
    NEW._onTick()
    check("one batch stops at what you can carry: two of three 8 kg takes", queued == 2, queued)
    NEW.runs[0] = nil
    NEW.runJobs, NEW.actionsFor = realJobs, realActs
end

-- ---------------------------------------------------------------------------
section("the ticks by the clock")
-- ---------------------------------------------------------------------------
-- the home check: stepping out of home takes what you leave with
store.home = { b = NEW.bkey(building) }
store.trip = nil
P.x, P.y = BX + 1, BY + 1
W.now = W.now + 5000
NEW._onTick()                        -- (in home)
P.x, P.y = BX - 1, BY - 1            -- out
W.now = W.now + 100
NEW._onTick()
check("out of home: no snapshot inside R.HOME_TICK_MS", store.trip == nil)
W.now = W.now + 100
NEW._onTick()
check("... nor at 200 ms", store.trip == nil)
W.now = W.now + 400
NEW._onTick()
check("... taken once R.HOME_TICK_MS has gone by", store.trip ~= nil)
check("the run tick is 167 ms and the home check 500 ms (the old 10 and 30 frames at 60)", NEW.RUN_TICK_MS == 167 and NEW.HOME_TICK_MS == 500)
local ticksSrc = newSrc:find("_tick %%", 1, false)
check("no frame-count throttle left in ZeD_Restock.lua", ticksSrc == nil)
local pinSrc = readFile(ZD .. "ZeD_RestockPin.lua") or ""
check("no frame-count throttle left in ZeD_RestockPin.lua", not pinSrc:find("n %% 15", 1, false) and pinSrc:find("getTimestampMs", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
section("the Equip tab's fold, shut")
-- ---------------------------------------------------------------------------
local elNew = readFile(ZD .. "ZeD_EquipLoadout.lua")
local elOld = gitShow("42/media/lua/client/ZeD/ZeD_EquipLoadout.lua")
check("ZeD_EquipLoadout.lua, now and before", elNew ~= nil and elOld ~= nil)
-- a loadout of 5 lines and an outfit of 2; which lines are on you (in their place)
local onYou = { a = true, b = false, c = true, d = false, e = false, s1 = true, s2 = false }
local lo = { id = "lo", kind = "loadout", name = "Scavenger", lines = { { id = "a" }, { id = "b" }, { id = "c" }, { id = "d" }, { id = "e" } } }
local outfit = { id = "of", kind = "outfit", name = "Winter", lines = { { id = "s1" }, { id = "s2" } } }
local function zedFor(counter)
    local Rs = { gen = 0, runs = {} }
    function Rs.current() return outfit, lo, 1 end
    function Rs.call() return nil end
    function Rs.homeNow() return nil end
    function Rs.load() return {} end
    function Rs.overLimit() return nil end
    function Rs.timeText() return "0:00" end
    -- the plan's rule (ZeD_Restock planLine): a row is "on" exactly when the line is on you in its place
    function Rs.plan(p, opts)
        counter.plans = counter.plans + 1
        local rows = {}
        for _, list in ipairs({ outfit, lo }) do
            for _, ln in ipairs(list.lines) do rows[#rows + 1] = { list = list, line = ln, state = onYou[ln.id] and "on" or "take", picks = {} } end
        end
        return { rows = rows, jobs = {}, secs = 0, count = {} }
    end
    local Ls = { gen = 0 }
    function Ls.on() return true end
    function Ls.ready(p, list, days)
        local n = 0
        for _, ln in ipairs(list.lines) do if onYou[ln.id] then n = n + 1 end end
        return n, #list.lines
    end
    local T = { sp = { tabHeaderH = 37 }, px = function(v) return v end, fontF1 = 1, fontF4 = 4,
                textDim = { r = 1, g = 1, b = 1, a = 1 }, accent = {}, borderS = {} }
    return {
        Lists = Ls, Restock = Rs, T = T, logOnce = function() end,
        TM = { getFontHeight = function() return 12 end, MeasureStringX = function(_, f, s) return #tostring(s) * 7 end },
        tr = function(k, ...) local a = { ... }; for i = 1, #a do a[i] = tostring(a[i]) end; return k .. "(" .. table.concat(a, ",") .. ")" end,
        Atoms = { mouseIn = function() return false end, truncateText = function(s) return s end, textCase = function(s) return s end },
        Molecules = { drawTabHeader = function() end },
    }
end
base.ZeD_ScrollbarState = { new = function() return {} end }
local cNew, cOld = { plans = 0 }, { plans = 0 }
local zNew, zOld = zedFor(cNew), zedFor(cOld)
local okN, eN = pcall(load, elNew or "", "@ZeD_EquipLoadout.lua", zNew)
local okO, eO = pcall(load, elOld or "", "@ZeD_EquipLoadout.lua(" .. PRE .. ")", zOld)
check("ZeD_EquipLoadout.lua loads on the stubs", okN and okO, tostring(eN) .. " / " .. tostring(eO))
if okN and okO then
    local function panel()
        local pn = { said = {} }
        function pn:drawText(t) self.said[#self.said + 1] = t end
        function pn:getMouseX() return -1 end
        function pn:getMouseY() return -1 end
        return pn
    end
    local winN, winO = { _playerObj = P, playerNum = 0 }, { _playerObj = P, playerNum = 0 }
    local function frame(withDoll)
        local pN, pO = panel(), panel()
        if withDoll then zNew.EquipLoadout.ghosts(winN); zOld.EquipLoadout.ghosts(winO) end
        zNew.EquipLoadout.beginFrame(winN); zOld.EquipLoadout.beginFrame(winO)
        zNew.EquipLoadout.drawSection(pN, winN, 0, 0, 400, nil)
        zOld.EquipLoadout.drawSection(pO, winO, 0, 0, 400, nil)
        return pN.said[1], pO.said[1]
    end
    local t0 = W.now
    local diff = 0
    local first
    for f = 1, 180 do   -- three seconds at 60 a second, the list view (no doll)
        W.now = t0 + math.floor(f * 1000 / 60)
        if f == 90 then onYou.b = true; zNew.Lists.gen = 1; zOld.Lists.gen = 1 end   -- (a line put in place)
        local a, b = frame(false)
        first = first or a
        if a ~= b then diff = diff + 1 end
    end
    check("the shut fold's heading: the same words as before, every frame", diff == 0, diff)
    check("the heading reads the loadout's ready count", first == "Scavenger | UI_ZeD_EqBar_Ready(2,5)", first)
    print(string.format("   plans made for the shut fold, 3 s with no doll: before %d, after %d", cOld.plans, cNew.plans))
    check("the shut fold makes no plan (no walk)", cNew.plans == 0 and cOld.plans >= 3, cNew.plans .. " / " .. cOld.plans)
    -- the doll's view: the ghosts read the plan first; the fold uses it
    cNew.plans, cOld.plans = 0, 0
    local t1 = W.now
    diff = 0
    for f = 1, 120 do
        W.now = t1 + math.floor(f * 1000 / 60)
        if f == 60 then onYou.d = true; zNew.Lists.gen = 2; zOld.Lists.gen = 2 end
        local a, b = frame(true)
        if a ~= b then diff = diff + 1 end
    end
    check("with the doll: the same words as before, every frame", diff == 0, diff)
    check("with the doll: the plan as often as before (the ghosts read it)", cNew.plans == cOld.plans, cNew.plans .. " / " .. cOld.plans)
end

print("restock_scan_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
