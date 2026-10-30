-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Restock.lua
-- ============================================================================
-- RESTOCK AND UNPACK: THE ENGINE (handoff equip_doll_v4_loadouts, parts B4-B6;
-- mockup frames r2_03 to r2_07; the director: "1, 2 and 3. 3 being the
-- accessible option, 1 being hardcore, and 2 being casual")
--
-- No drawing here (the Equip tab's bar and to-do are ZeD_EquipLoadout.lua, the
-- pinned list ZeD_RestockPin.lua). What it does:
--   * the lists applied (one outfit, one loadout, the days), kept with the
--     character beside the lists (player:getModData().ZeD_Lists.applied);
--   * where it looks: the building you're in, or only what's in reach outside
--     one; containers you could open yourself (never a locked one, never one a
--     safehouse keeps you out of) and only the ones you have looked into (an
--     unexplored container's things are not known yet);
--   * the plan: each list line in one of the to-do's states (on you, take from a
--     container, fill at a tap, ask first: the last one in the building, none),
--     with smart picks (the food that spoils first, the tool in the best
--     condition, the fullest bottle, the lightest thing that meets the line);
--   * the game's own timed actions at their own speed, queued: take, wear,
--     equip, attach to a belt slot, fill at a tap; their total time;
--   * the three ways (the Restock setting): Hardcore takes from what is in reach
--     now; Casual queues the takes as containers come into reach; Accessible
--     walks a route over the containers with the game's pathfinding walk and
--     comes back to where you pressed;
--   * it stops (the queue cancelled) for any key or button, a zombie coming into
--     view or getting hurt;
--   * home (the building where you last restocked), what you left with, and
--     Unpack: loot where its kind lives, leftovers packed, gear and outfit on you.
-- Never moves a thing by itself: every take is vanilla's transfer action.
-- Restock follows Loadouts (director, Oct 30 2026): with Loadouts and outfits
-- off (Settings.lua, L.on()) nothing starts, a run going is stopped, and there
-- are no scans and no trip kept on stepping out of home.
-- ============================================================================

require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "ZeD/ZeD_Lists"

ZeD = ZeD or {}
ZeD.Restock = ZeD.Restock or {}
local R = ZeD.Restock
local L = ZeD.Lists

-- a timed action's maxTime in game units; seconds at 1x speed per unit (QA: zedqa_restock.lua times one)
R.SEC_PER_UNIT = 1 / 48
R.WALK_SEC_PER_TILE = 0.45    -- the pathfinding walk, a tile
R.SPOIL_SOON_DAYS = 2         -- leftover food that would spoil within this goes back where food lives
R.gen = R.gen or 0            -- bumped on every change the to-do shows (the applied lists, a run)
R.runs = R.runs or {}         -- per player number: the run going on

local function call(o, m, ...)
    if not o then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
R.call = call
local function touch() R.gen = R.gen + 1 end
R.touch = touch

-- ---------------------------------------------------------------------------
-- THE SETTING (Settings.lua restock: Hardcore, Casual, Accessible)
-- ---------------------------------------------------------------------------
R.MODES = { "hardcore", "casual", "accessible" }
function R.mode()
    local o = ZeD.Settings and ZeD.Settings.restockOption
    local v = o and call(o, "getValue") or 2
    return R.MODES[v] or "casual"
end

-- ---------------------------------------------------------------------------
-- THE LISTS APPLIED: one outfit, one loadout, the days (kept with the lists)
-- ---------------------------------------------------------------------------
function R.applied(p)
    local s = L.store(p)
    if not s then return { days = 1 } end
    if type(s.applied) ~= "table" then s.applied = { days = 1 } end
    local a = s.applied
    if type(a.days) ~= "number" then a.days = 1 end
    if a.outfit and not L.get(p, a.outfit) then a.outfit = nil end
    if a.loadout and not L.get(p, a.loadout) then a.loadout = nil end
    return a
end

--- The outfit, the loadout and the days applied (lists or nil).
function R.current(p)
    local a = R.applied(p)
    return a.outfit and L.get(p, a.outfit) or nil, a.loadout and L.get(p, a.loadout) or nil, a.days
end

function R.setOutfit(p, id) R.applied(p).outfit = id; touch() end
function R.setLoadout(p, id) R.applied(p).loadout = id; touch() end
function R.setDays(p, n)
    n = math.max(1, math.min(30, math.floor(tonumber(n) or 1)))
    R.applied(p).days = n
    touch()
    return n
end

--- Every piece of the outfit worn: n worn, m lines.
function R.outfitWorn(p, outfit)
    if not outfit then return 0, 0 end
    return L.ready(p, outfit, 1)
end

-- ---------------------------------------------------------------------------
-- WHERE IT LOOKS
-- ---------------------------------------------------------------------------
-- a container's name as the loot window shows it (the game's words for its type)
local function contName(o, c)
    local ty = tostring(call(c, "getType") or "")
    local title = ty
    local on = o and call(o, "getName")
    if on and on ~= "" then title = on end
    local key = "IGUI_ContainerTitle_" .. ty
    local t = getText(key)
    if t ~= key then title = t end
    return title
end
R.contName = contName

-- the loot window's rule: a locked thumpable (a code or a padlock whose key you don't carry) is closed to you
local function lockedFor(o, p)
    if not instanceof(o, "IsoThumpable") then return false end
    local locked = call(o, "isLockedToCharacter", p) and true or false
    if call(o, "isLockedByPadlock") and call(p:getInventory(), "haveThisKeyId", call(o, "getKeyId")) then locked = false end
    return locked
end
R.lockedFor = lockedFor

-- multiplayer: a safehouse or claim that keeps you out
local function lootAllowed(sq, p)
    if not isClient() then return true end
    local ok, r = pcall(function() return SafeHouse.isSafehouseAllowLoot(sq, p) end)
    return (not ok) or r == true
end

--- In reach now, as the loot window counts it: the square you stand on or one beside it on
-- your level that nothing walls off.
function R.inReach(p, sq)
    local cur = p and p:getCurrentSquare()
    if not (cur and sq) then return false end
    if sq:getZ() ~= cur:getZ() then return false end
    if math.abs(sq:getX() - cur:getX()) > 1 or math.abs(sq:getY() - cur:getY()) > 1 then return false end
    return sq == cur or cur:canReachTo(sq)
end

local function waterName(o)
    local props = call(o, "getProperties")
    local cn = props and call(props, "get", "CustomName")
    if cn and cn ~= "" then
        local ok, t = pcall(function() return Translator.getMoveableDisplayName(cn) end)
        return (ok and t) or cn
    end
    return getText("ContextMenu_Fill")
end

-- the containers and taps on a square
local function scanSquare(p, sq, out, waters, seen, reach)
    if not lootAllowed(sq, p) then return end
    local obs = sq:getObjects()
    for i = 0, obs:size() - 1 do
        local o = obs:get(i)
        local n = (o and o.getContainerCount) and o:getContainerCount() or 0
        if n > 0 and not lockedFor(o, p) then
            for ci = 0, n - 1 do
                local c = o:getContainerByIndex(ci)
                if c and not seen[c] and c:isExplored() then
                    seen[c] = true
                    out[#out + 1] = { cont = c, obj = o, oi = i, ci = ci, sq = sq, x = sq:getX(), y = sq:getY(), z = sq:getZ(),
                                      name = contName(o, c), reach = reach }
                end
            end
        end
        if o and not instanceof(o, "IsoWorldInventoryObject") and call(o, "hasWater")
           and (call(o, "getFluidAmount") or 0) > 0 and not call(o, "isTaintedWater") then
            local props = call(o, "getProperties")
            local toilet = props and call(props, "get", "CustomName") == "Toilet" or false
            waters[#waters + 1] = { obj = o, sq = sq, x = sq:getX(), y = sq:getY(), z = sq:getZ(), name = waterName(o), reach = reach, toilet = toilet }
        end
    end
end

-- what is in reach now: the squares round you, a vehicle's open parts beside you, the floor
local function scanReach(p, out, waters, seen)
    local cur = p:getCurrentSquare()
    if not cur then return "" end
    local cx, cy, cz = cur:getX(), cur:getY(), cur:getZ()
    local sig = {}
    local vseen = {}
    for dy = -1, 1 do
        for dx = -1, 1 do
            local gs = getCell():getGridSquare(cx + dx, cy + dy, cz)
            if gs and R.inReach(p, gs) and lootAllowed(gs, p) then
                local before = #out
                scanSquare(p, gs, out, waters, seen, true)
                for i = before + 1, #out do out[i].reach = true end
                local veh = gs:getVehicleContainer()
                if veh and not vseen[veh] then
                    vseen[veh] = true
                    for pi = 0, veh:getPartCount() - 1 do
                        local part = veh:getPartByIndex(pi)
                        local c = part and part:getItemContainer()
                        if c and not seen[c] and veh:canAccessContainer(pi, p) then
                            seen[c] = true
                            local nm = getTextOrNull("IGUI_VehiclePart" .. tostring(c:getType())) or tostring(part:getId())
                            out[#out + 1] = { cont = c, sq = gs, x = gs:getX(), y = gs:getY(), z = gs:getZ(), name = nm, reach = true, vehicle = true }
                        end
                    end
                end
                sig[#sig + 1] = gs:getX() .. "," .. gs:getY()
            end
        end
    end
    -- the floor round you: vanilla's own floor container (an item lives in one container at a time)
    local floor = ISInventoryPage and ISInventoryPage.GetFloorContainer and ISInventoryPage.GetFloorContainer(p:getPlayerNum())
    if floor then
        out[#out + 1] = { cont = floor, floor = true, sq = cur, x = cx, y = cy, z = cz, name = getText("IGUI_ContainerTitle_floor"), reach = true }
    end
    for _, s in ipairs(out) do if s.reach then sig[#sig + 1] = tostring(s.cont) end end
    return table.concat(sig, ";")
end

-- the floor's items: the world objects on the squares in reach (vanilla's floor container is filled from them)
local function floorItems(p)
    local cur = p:getCurrentSquare()
    local items = {}
    if not cur then return items end
    for dy = -1, 1 do
        for dx = -1, 1 do
            local gs = getCell():getGridSquare(cur:getX() + dx, cur:getY() + dy, cur:getZ())
            if gs and R.inReach(p, gs) then
                local wobs = gs:getWorldObjects()
                for i = 0, (wobs and wobs:size() or 0) - 1 do
                    local it = wobs:get(i):getItem()
                    if it then items[#items + 1] = it end
                end
            end
        end
    end
    return items
end

function R.buildingOf(p)
    local sq = p and p:getCurrentSquare()
    return sq and sq:getBuilding() or nil
end
function R.bkey(b)
    local d = b and b:getDef()
    if not d then return nil end
    return d:getX() .. "," .. d:getY()
end

--- The building's containers (or, outside one, those in reach) and its taps. Kept for a
-- second (the building's squares are walked); force = look again now.
-- @return { sources = { { cont, obj, sq, x, y, z, name, reach, floor } }, waters = {...},
--           building, bkey, reachSig }
local _scan = {}
function R.scan(p, force)
    if not L.on() then return { sources = {}, waters = {}, reachSig = "", ms = getTimestampMs(), here = "" } end   -- (no scan while off)
    local pn = p:getPlayerNum()
    local now = getTimestampMs()
    local c = _scan[pn]
    local cur = p:getCurrentSquare()
    local here = cur and (cur:getX() .. "," .. cur:getY() .. "," .. cur:getZ()) or ""
    if c and not force and c.here == here and now - c.ms < 1000 then return c end
    local out, waters, seen = {}, {}, {}
    local reachSig = scanReach(p, out, waters, seen)
    local b = R.buildingOf(p)
    if b then
        local d = b:getDef()
        local cell = getCell()
        for z = d:getMinLevel(), d:getMaxLevel() do
            for y = d:getY(), d:getY2() - 1 do
                for x = d:getX(), d:getX2() - 1 do
                    local sq = cell:getGridSquare(x, y, z)
                    if sq and sq:getBuilding() == b then scanSquare(p, sq, out, waters, seen, R.inReach(p, sq)) end
                end
            end
        end
    end
    c = { sources = out, waters = waters, building = b, bkey = R.bkey(b), reachSig = reachSig, ms = now, here = here }
    _scan[pn] = c
    return c
end
function R.forget(p) if p then _scan[p:getPlayerNum()] = nil end end

-- the items a source holds (its top level; the floor: the world items in reach)
local function itemsIn(p, src)
    if src.floor then return floorItems(p) end
    local out = {}
    local items = src.cont:getItems()
    for i = 0, items:size() - 1 do out[#out + 1] = items:get(i) end
    return out
end
R.itemsIn = itemsIn

-- ---------------------------------------------------------------------------
-- SMART PICKS
-- ---------------------------------------------------------------------------
local function amountOf(line, it)
    if line.unit == "l" then return L.waterIn(it) end
    if line.unit == "cal" then return math.max(0, call(it, "getCalories") or 0) end
    return 1
end
R.amountOf = amountOf

local function weightOf(it)
    return call(it, "getUnequippedWeight") or call(it, "getActualWeight") or 0
end
R.weightOf = weightOf

-- days left before it spoils (a thing that doesn't spoil: a large number)
local function spoilLeft(it)
    if not instanceof(it, "Food") then return 1e9 end
    local off = call(it, "getOffAge") or 0
    if off <= 0 or off >= 1e8 then return 1e9 end
    return off - (call(it, "getAge") or 0)
end
R.spoilLeft = spoilLeft

local function condOf(it)
    local mx = call(it, "getConditionMax") or 0
    if mx <= 0 then return 1 end
    return (call(it, "getCondition") or 0) / mx
end

-- the better pick first: the food that spoils first, the tool or weapon in the best condition,
-- the fullest bottle, then the lightest
local function better(a, b)
    local wa, wb = L.waterIn(a), L.waterIn(b)
    if math.abs(wa - wb) > 0.001 then return wa > wb end
    local sa, sb = spoilLeft(a), spoilLeft(b)
    if math.abs(sa - sb) > 0.001 then return sa < sb end
    local ca, cb = condOf(a), condOf(b)
    if math.abs(ca - cb) > 0.001 then return ca > cb end
    local ka, kb = weightOf(a), weightOf(b)
    if math.abs(ka - kb) > 0.0001 then return ka < kb end
    return a:getID() < b:getID()
end
R.better = better

-- a line that has a place to be put (a hand, a belt slot, a worn location, a bag), not "anywhere on you"
local function placed(line)
    if line.sec == "supply" then return false end
    local pl = line.place or "inv"
    return pl ~= "inv"
end

-- a bottle you could fill with water: a fluid container holding water or nothing, with room
local function fillable(it)
    local fc = call(it, "getFluidContainer")
    if not fc then return false end
    local cap = call(fc, "getCapacity") or 0
    local amt = call(fc, "getAmount") or 0
    if cap <= 0 or amt >= cap - 0.01 then return false end
    if amt > 0 and L.waterIn(it) <= 0 then return false end
    return true
end
R.fillable = fillable

local function nearest(p, list)
    local best, bd
    for _, w in ipairs(list) do
        if w.z == math.floor(p:getZ()) or not best then
            -- (a sink or a dispenser before a toilet: the toilet only when it is all there is)
            local d = math.abs(w.x - p:getX()) + math.abs(w.y - p:getY()) + math.abs(w.z - p:getZ()) * 20 + (w.toilet and 1000 or 0)
            if not best or d < bd then best, bd = w, d end
        end
    end
    return best
end

-- ---------------------------------------------------------------------------
-- THE PLAN: each line's state and its picks
-- ---------------------------------------------------------------------------
-- a row: { list, line, key, need, have, short, state = "on" | "take" | "fill" | "ask" | "none" | "far",
--          picks = { { item, src (a source, nil: on you), amt } }, fill = { water, bottles = { { item, src } } },
--          where (a source's or the tap's name) }
-- opts: { okLast = { [row key] = true } (asked and answered), hardcore = true (only what's in reach) }
local function planLine(p, list, ln, days, scan, reserved, opts)
    local r = L.resolve(p, ln, days)
    local key = tostring(list.id) .. ":" .. tostring(ln.id)
    local row = { list = list, line = ln, key = key, need = r.need, have = r.have, picks = {}, state = "on", items = r.items }
    for _, it in ipairs(r.items) do reserved[it] = true end
    if r.ok then return row end
    local d = r.need - r.have
    local eps = 1e-6
    -- on you but not in its place: put in place (no take)
    if placed(ln) then
        local byId = ln.rule == "this" and ln.itemId and not r.fallback
        for _, it in ipairs(L.itemsAt(p, nil)) do
            if d <= eps then break end
            if not reserved[it] and L.matches(ln, it, byId) then
                reserved[it] = true
                row.picks[#row.picks + 1] = { item = it, amt = amountOf(ln, it) }
                d = d - amountOf(ln, it)
            end
        end
    end
    -- the building's containers (Hardcore: what's in reach; the rest is "not in reach")
    local cands, far = {}, nil
    local exact = nil
    if d > eps then
        for _, src in ipairs(scan.sources) do
            for _, it in ipairs(itemsIn(p, src)) do
                if not reserved[it] then
                    if ln.rule == "this" and ln.itemId and it:getID() == ln.itemId then exact = { item = it, src = src } end
                    if L.matches(ln, it, false) and amountOf(ln, it) > 0 then cands[#cands + 1] = { item = it, src = src } end
                end
            end
        end
        if exact then cands = { exact } end
        table.sort(cands, function(a, b) return better(a.item, b.item) end)
        local avail = #cands
        local taken = 0
        for _, c in ipairs(cands) do
            if d <= eps then break end
            if opts.hardcore and not c.src.reach then
                far = far or c.src
            else
                reserved[c.item] = true
                local a = amountOf(ln, c.item)
                row.picks[#row.picks + 1] = { item = c.item, src = c.src, amt = a }
                d = d - a
                taken = taken + 1
            end
        end
        -- the last of a supply in the building: asked first (the last bandage, the last box of rounds). Gear and
        -- outfit pieces are mostly one of a kind, and a line by this one item is yours to take: never asked.
        if taken > 0 and taken >= avail and ln.sec == "supply" and ln.rule ~= "this" and not (opts.okLast and opts.okLast[key]) and scan.building then
            row.ask = true
        end
    end
    -- water short: fill bottles at a tap
    if d > eps and ln.kind == "water" and #scan.waters > 0 then
        local pool = {}
        for _, w in ipairs(scan.waters) do if (not opts.hardcore) or w.reach then pool[#pool + 1] = w end end
        local tap = nearest(p, pool)
        if tap then
            local bottles = {}
            for _, it in ipairs(L.itemsAt(p, nil)) do
                if d <= eps then break end
                if not reserved[it] and fillable(it) then
                    reserved[it] = true
                    local fc = it:getFluidContainer()
                    bottles[#bottles + 1] = { item = it }
                    d = d - (fc:getCapacity() - fc:getAmount())
                end
            end
            if d > eps then
                for _, src in ipairs(scan.sources) do
                    if (not opts.hardcore) or src.reach then
                        for _, it in ipairs(itemsIn(p, src)) do
                            if d <= eps then break end
                            if not reserved[it] and fillable(it) and L.waterIn(it) <= 0 then
                                reserved[it] = true
                                bottles[#bottles + 1] = { item = it, src = src }
                                d = d - it:getFluidContainer():getCapacity()
                            end
                        end
                    end
                end
            end
            if #bottles > 0 then row.fill = { water = tap, bottles = bottles } end
        end
    end
    row.short = d > eps
    row.got = r.need - math.max(0, d)
    if row.ask then row.state = "ask"
    elseif #row.picks > 0 then row.state = "take"
    elseif row.fill then row.state = "fill"
    elseif far then row.state = "far"; row.farSrc = far
    else row.state = "none" end
    -- where: the first container it takes from, else the tap, else on you
    local first = nil
    for _, pk in ipairs(row.picks) do if pk.src then first = pk.src; break end end
    if row.state == "fill" then row.where = row.fill.water.name
    elseif first then row.where = first.name
    elseif row.state == "far" then row.where = far.name end
    return row
end

--- The plan for the lists applied (or those given): rows in list order, outfit first.
-- opts = { outfit, loadout, days, okLast, hardcore, force }
function R.plan(p, opts)
    opts = opts or {}
    local o, lo, days = R.current(p)
    if opts.outfit ~= nil then o = opts.outfit or nil end
    if opts.loadout ~= nil then lo = opts.loadout or nil end
    days = opts.days or days or 1
    if opts.hardcore == nil then opts.hardcore = (R.mode() == "hardcore") end
    if opts.okLast == nil then opts.okLast = R.okLast(p) end
    -- nothing applied: nothing to look for (the building is not walked)
    if not (o or lo) then
        return { rows = {}, days = days, scan = { sources = {}, waters = {} }, count = {}, jobs = {}, secs = 0 }
    end
    local scan = R.scan(p, opts.force)
    local plan = { rows = {}, days = days, scan = scan, count = {} }
    local reserved = {}
    for _, list in ipairs({ o or false, lo or false }) do
        if list then
            for _, ln in ipairs(list.lines) do
                local row = planLine(p, list, ln, days, scan, reserved, opts)
                plan.rows[#plan.rows + 1] = row
                plan.count[row.state] = (plan.count[row.state] or 0) + 1
                if row.short and row.state ~= "none" and row.state ~= "far" then plan.count.short = (plan.count.short or 0) + 1 end
            end
        end
    end
    plan.jobs = R.jobsOf(p, plan)
    plan.secs = R.jobsSecs(p, plan.jobs, R.mode() == "accessible")
    return plan
end

-- answered "take the last one": per player, for this session
local _okLast = {}
function R.okLast(p)
    local pn = p and p:getPlayerNum() or 0
    _okLast[pn] = _okLast[pn] or {}
    return _okLast[pn]
end
function R.confirmLast(p, key) R.okLast(p)[key] = true; touch() end

-- ---------------------------------------------------------------------------
-- WHAT THE PLAN WEIGHS (the to-do's Load after restock, the long trip's warning)
-- ---------------------------------------------------------------------------
-- a supply line's weight for one of its units (from what it would take, else the item's script)
local function unitWeight(ln, row)
    if ln.unit == "l" then return 1.0 end
    for _, pk in ipairs(row and row.picks or {}) do
        local a = pk.amt or 1
        if a > 0 then return weightOf(pk.item) / a end
    end
    local w = 0
    pcall(function()
        local sc = getScriptManager():FindItem(ln.type)
        if sc then w = sc:getActualWeight() end
    end)
    if ln.unit == "cal" then
        local cal = 0
        pcall(function() local sc = getScriptManager():FindItem(ln.type); if sc then cal = sc:getCalories() end end)
        return (cal > 0) and (w / cal) or 0.0005
    end
    return w
end

-- the weight carried with every line met for n days: what you carry now, each supply line's
-- shortfall at its unit weight, and the gear the plan takes
local function weightFor(p, plan, n, uws)
    local w = p:getInventoryWeight()
    for _, row in ipairs(plan.rows) do
        local ln = row.line
        if ln.sec == "supply" then
            local need = (ln.amount or 1) * ((ln.per == "day") and n or 1)
            w = w + math.max(0, need - (row.have or 0)) * uws[row.key]
        elseif row.state ~= "on" then
            for _, pk in ipairs(row.picks) do if pk.src then w = w + weightOf(pk.item) end end
        end
    end
    return w
end

--- The load after restock (the game's carried weight with the bags' reduction, then every line
-- met for the days): { now, max, after, supplies (the supplies you'd carry), worn (worn and gear),
-- byLine = { [row key] = kg of that supply for the days }, uws }
function R.load(p, plan)
    local now = p:getInventoryWeight()
    local max = p:getMaxWeight()
    local supplies = 0
    local by, uws = {}, {}
    for _, row in ipairs(plan and plan.rows or {}) do
        local ln = row.line
        if ln.sec == "supply" then
            local uw = unitWeight(ln, row)
            uws[row.key] = uw
            by[row.key] = uw * (row.need or 0)
            supplies = supplies + uw * math.max(row.need or 0, row.have or 0)
        end
    end
    local after = plan and weightFor(p, plan, plan.days or 1, uws) or now
    return { now = now, max = max, supplies = supplies, worn = math.max(0, after - supplies), after = after, byLine = by, uws = uws }
end

--- Over the limit for the days: { over (kg), heaviest (its row), fits (the most days that fit, 0: not even one) }
function R.overLimit(p, plan)
    local ld = R.load(p, plan)
    if ld.after <= ld.max + 0.001 then return nil end
    local heavy, hw = nil, -1
    for _, row in ipairs(plan.rows) do
        if row.line.sec == "supply" and (ld.byLine[row.key] or 0) > hw then heavy, hw = row, ld.byLine[row.key] end
    end
    local fits = 0
    for n = plan.days, 1, -1 do
        if weightFor(p, plan, n, ld.uws) <= ld.max + 0.001 then fits = n; break end
    end
    local perDay = false
    for _, row in ipairs(plan.rows) do if row.line.sec == "supply" and row.line.per == "day" then perDay = true end end
    return { over = ld.after - ld.max, heaviest = heavy, fits = fits, load = ld, perDay = perDay }
end

-- ---------------------------------------------------------------------------
-- JOBS: one take, put in place, fill or put away, at one square in reach
-- ---------------------------------------------------------------------------
-- a job: { kind = "take" | "place" | "fill" | "put", item, src (a source), dest (ItemContainer),
--          sq (the square to be in reach of), line, row, water (a tap), label }
function R.jobsOf(p, plan)
    local jobs = {}
    for _, row in ipairs(plan.rows) do
        if row.state == "take" or row.state == "fill" then
            for _, pk in ipairs(row.picks) do
                jobs[#jobs + 1] = { kind = pk.src and "take" or "place", item = pk.item, src = pk.src, sq = pk.src and pk.src.sq,
                                    line = row.line, row = row }
            end
            if row.fill then
                for _, b in ipairs(row.fill.bottles) do
                    if b.src then jobs[#jobs + 1] = { kind = "take", item = b.item, src = b.src, sq = b.src.sq, line = row.line, row = row, bottle = true } end
                    jobs[#jobs + 1] = { kind = "fill", item = b.item, water = row.fill.water, sq = row.fill.water.sq, line = row.line, row = row }
                end
            end
        end
    end
    return jobs
end

-- a bag of that full type on you (worn, held or in the inventory)
local function bagOnYou(p, ft)
    local worn = p:getWornItems()
    for i = 0, (worn and worn:size() or 0) - 1 do
        local it = worn:get(i):getItem()
        if it and it:getFullType() == ft and instanceof(it, "InventoryContainer") then return it end
    end
    for _, h in ipairs({ p:getPrimaryHandItem(), p:getSecondaryHandItem() }) do
        if h and h:getFullType() == ft and instanceof(h, "InventoryContainer") then return h end
    end
    local items = p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft and instanceof(it, "InventoryContainer") then return it end
    end
    return nil
end

-- the hotbar slot of that type: index, slot
local function hotbarSlot(p, st)
    local hb = getPlayerHotbar and getPlayerHotbar(p:getPlayerNum())
    if not (hb and hb.availableSlot) then return nil end
    for i, s in pairs(hb.availableSlot) do
        if s and tostring(s.slotType) == st then return i, s, hb end
    end
    return nil
end

-- the worn items at a location (normalised), other than item
local function wornAt(p, loc, item)
    local out = {}
    local worn = p:getWornItems()
    for i = 0, (worn and worn:size() or 0) - 1 do
        local wi = worn:get(i)
        if L.normLoc(wi:getLocation()) == loc and wi:getItem() ~= item then out[#out + 1] = wi:getItem() end
    end
    return out
end

--- The game's timed actions for a job, in order (not queued). live: about to be queued (a
-- floor item is then put in vanilla's floor container, as the loot window does).
function R.actionsFor(p, job, live)
    local acts = {}
    local inv = p:getInventory()
    local item = job.item
    if not item then return acts end
    if job.kind == "put" then
        local from = item:getContainer()
        if from and job.dest and from ~= job.dest then acts[1] = ISInventoryTransferAction:new(p, item, from, job.dest) end
        return acts
    end
    if job.kind == "fill" then
        local from = item:getContainer()
        if from and from ~= inv and not job.prior then acts[#acts + 1] = ISInventoryTransferAction:new(p, item, from, inv) end
        local w = job.water and job.water.obj
        if w then acts[#acts + 1] = ISTakeWaterAction:new(p, item, w, w:isTaintedWater()) end
        return acts
    end
    local ln = job.line
    local place = (ln and ln.place) or "inv"
    if ln and ln.sec == "supply" then place = "inv" end
    -- into the main inventory (or the line's bag), from the container or the bag on you it is in
    local target = inv
    if place:sub(1, 4) == "bag:" then
        local bag = bagOnYou(p, place:sub(5))
        if bag then target = bag:getInventory() end
    end
    local from = item:getContainer()
    if live and job.src and job.src.floor and from ~= job.src.cont then
        -- (an item on the floor lives in vanilla's floor container while the loot window shows it)
        pcall(function() job.src.cont:AddItem(item) end)
        from = job.src.cont
    end
    if job.src and job.src.floor and not live then from = job.src.cont end
    if from and from ~= target then acts[#acts + 1] = ISInventoryTransferAction:new(p, item, from, target) end
    if job.bottle then return acts end
    if place == "hand:main" or place == "hand:off" then
        local main = place == "hand:main"
        acts[#acts + 1] = ISEquipWeaponAction:new(p, item, 50, main, main and (call(item, "isTwoHandWeapon") or false) or false)
    elseif place:sub(1, 5) == "belt:" then
        local i, slot, hb = hotbarSlot(p, place:sub(6))
        local at = slot and call(item, "getAttachmentType")
        local model = at and slot.def and slot.def.attachments and slot.def.attachments[at]
        if model then
            local old = hb.attachedItems and hb.attachedItems[i]
            if old and old ~= item then acts[#acts + 1] = ISDetachItemHotbar:new(p, old) end
            acts[#acts + 1] = ISAttachItemHotbar:new(p, item, model, i, slot.def)
        end
    elseif place:sub(1, 5) == "worn:" then
        -- an outfit piece in the way comes off and goes where the new one came from (a bag in the way only comes off)
        for _, old in ipairs(wornAt(p, place:sub(6), item)) do
            acts[#acts + 1] = ISUnequipAction:new(p, old, 50)
            local full = instanceof(old, "InventoryContainer") and old:getInventory():getItems():size() > 0
            if job.src and not job.src.floor and not full then acts[#acts + 1] = ISInventoryTransferAction:new(p, old, inv, job.src.cont) end
        end
        acts[#acts + 1] = ISWearClothing:new(p, item)
    end
    return acts
end

-- an action's game units (an animation-timed one counts its usual length)
local DEFAULT_UNITS = { ISAttachItemHotbar = 30, ISDetachItemHotbar = 30, ISEquipWeaponAction = 50, ISUnequipAction = 50 }
function R.units(a)
    local t = a and a.maxTime
    if t and t > 0 then return t end
    return DEFAULT_UNITS[a and a.Type or ""] or 30
end

--- Seconds for jobs (their actions), walking the route too when walk is true.
function R.jobsSecs(p, jobs, walk)
    local u = 0
    for _, j in ipairs(jobs) do
        for _, a in ipairs(R.actionsFor(p, j)) do u = u + R.units(a) end
    end
    local s = u * R.SEC_PER_UNIT
    if walk then s = s + R.routeTiles(p, jobs) * R.WALK_SEC_PER_TILE end
    return s
end

--- "0:35"
function R.timeText(sec)
    sec = math.max(0, math.floor((sec or 0) + 0.5))
    local m = math.floor(sec / 60)
    local s = sec - m * 60
    return tostring(m) .. ":" .. (s < 10 and "0" or "") .. tostring(s)
end

-- ---------------------------------------------------------------------------
-- THE ROUTE (Accessible): the stops nearest first, then back where you pressed
-- ---------------------------------------------------------------------------
-- stops = { { sq, jobs = {...} } } in walking order from (x, y)
function R.route(p, jobs)
    local by, stops = {}, {}
    for _, j in ipairs(jobs) do
        local sq = j.sq
        if sq then
            local k = sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ()
            local s = by[k]
            if not s then s = { sq = sq, x = sq:getX(), y = sq:getY(), z = sq:getZ(), jobs = {} }; by[k] = s; stops[#stops + 1] = s end
            s.jobs[#s.jobs + 1] = j
        end
    end
    -- nearest first (a fill's tap after the bottle it fills: the take's stop is the earlier one when equal)
    local out = {}
    local cx, cy, cz = p:getX(), p:getY(), p:getZ()
    local left = stops
    while #left > 0 do
        local bi, bd = 1, nil
        for i, s in ipairs(left) do
            local d = math.abs(s.x - cx) + math.abs(s.y - cy) + math.abs(s.z - cz) * 20
            -- a stop with a fill waits for every stop with a bottle take
            local blocked = false
            for _, j in ipairs(s.jobs) do
                if j.kind == "fill" then
                    for _, s2 in ipairs(left) do
                        if s2 ~= s then for _, j2 in ipairs(s2.jobs) do if j2.bottle and j2.item == j.item then blocked = true end end end
                    end
                end
            end
            if not blocked and (not bd or d < bd) then bi, bd = i, d end
        end
        local s = table.remove(left, bi)
        out[#out + 1] = s
        cx, cy, cz = s.x, s.y, s.z
    end
    return out
end

function R.routeTiles(p, jobs)
    local t = 0
    local cx, cy, cz = p:getX(), p:getY(), p:getZ()
    for _, s in ipairs(R.route(p, jobs)) do
        t = t + math.abs(s.x - cx) + math.abs(s.y - cy) + math.abs(s.z - cz) * 6
        cx, cy, cz = s.x, s.y, s.z
    end
    return t + math.abs(p:getX() - cx) + math.abs(p:getY() - cy) + math.abs(p:getZ() - cz) * 6
end

-- ---------------------------------------------------------------------------
-- RUNS
-- ---------------------------------------------------------------------------
-- run = { pn, mode, kind = "restock" | "unpack", list (its name), acts (queued, in order),
--         stops, stopAt, start = { x, y, z }, z0, hp0, pads, notice, stopped, done, doneMs, ms }
local function queueActs(run, p, acts)
    for _, a in ipairs(acts) do
        ISTimedActionQueue.add(a)
        run.acts[#run.acts + 1] = a
    end
end

-- the run's actions still in the character's queue
function R.pending(p, run)
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local n, u = 0, 0
    if not (q and q.queue) then return 0, 0 end
    local inQ = {}
    for _, a in ipairs(q.queue) do inQ[a] = true end
    for _, a in ipairs(run.acts) do
        if inQ[a] then n = n + 1; u = u + R.units(a) end
    end
    return n, u
end

local function notice(p, run, text)
    run.notice = text
    run.noticeMs = getTimestampMs()
    if HaloTextHelper and HaloTextHelper.addText then pcall(HaloTextHelper.addText, p, text)
    elseif HaloTextHelper and HaloTextHelper.addGoodText then pcall(HaloTextHelper.addGoodText, p, text) end
end

-- "Bandage x2 from the Bathroom Cabinet" per container queued
local function noticeFor(p, run, jobs)
    local by, order = {}, {}
    for _, j in ipairs(jobs) do
        local where = (j.kind == "fill") and (j.water and j.water.name) or (j.kind == "put" and j.destName) or (j.src and j.src.name)
        local nm = j.item and (call(j.item, "getDisplayName") or "?")
        if where and nm then
            local k = where .. "|" .. nm
            if not by[k] then by[k] = { n = 0, where = where, name = nm, kind = j.kind }; order[#order + 1] = k end
            by[k].n = by[k].n + 1
        end
    end
    local parts = {}
    for _, k in ipairs(order) do
        local e = by[k]
        local what = (e.n > 1) and ZeD.tr("UI_ZeD_Restock_Times", e.name, e.n) or e.name
        local key = (e.kind == "fill") and "UI_ZeD_Restock_NoticeFill" or ((e.kind == "put") and "UI_ZeD_Restock_NoticePut" or "UI_ZeD_Restock_NoticeTake")
        parts[#parts + 1] = ZeD.tr(key, what, e.where)
    end
    if #parts > 0 then notice(p, run, table.concat(parts, " | ")) end
end

local function padState(pn)
    local jp = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    if not jp then return nil end
    local id = jp.id
    local s = {}
    for b = 0, 15 do s[b] = (isJoypadPressed and isJoypadPressed(id, b)) and true or false end
    return s
end

local function hpOf(p)
    local bd = p:getBodyDamage()
    return bd and bd:getOverallBodyHealth() or 100
end

--- The jobs a run would do now, and its plan (a fresh plan; unpack: its own).
function R.runJobs(p, kind)
    if kind == "unpack" then
        local up = R.unpackPlan(p)
        return R.unpackJobs(p, up), up
    end
    local plan = R.plan(p, { force = true })
    return plan.jobs, plan
end

-- a run is over: done (its list empty), or stopped (why)
local function finish(p, run, why)
    if run.done then return end
    run.done, run.stopped, run.doneMs = true, why, getTimestampMs()
    if run.kind == "unpack" and not why then
        local s = L.store(p)
        if s then s.trip = nil end
    end
    touch()
end

--- Start restocking (kind "restock") or unpacking ("unpack") the way the setting says.
function R.start(p, kind)
    if not p or not L.on() then return nil end
    kind = kind or "restock"
    local pn = p:getPlayerNum()
    local old = R.runs[pn]
    if old and not old.done then R.stop(p, nil) end
    local mode = R.mode()
    local _, lo = R.current(p)
    local run = { pn = pn, mode = mode, kind = kind, acts = {}, start = { x = p:getX(), y = p:getY(), z = p:getZ() },
                  startSq = p:getCurrentSquare(), z0 = p:getStats():getNumVisibleZombies(), hp0 = hpOf(p),
                  pads = padState(pn), ms = getTimestampMs(), list = lo and lo.name or "", tried = {} }
    R.runs[pn] = run
    -- home is the building where you last restocked
    if kind == "restock" then
        local b = R.buildingOf(p)
        local s = L.store(p)
        if b and s then s.home = { b = R.bkey(b), x = math.floor(p:getX()), y = math.floor(p:getY()), z = math.floor(p:getZ()) }; s.trip = nil end
    end
    R.forget(p)
    local jobs = R.runJobs(p, kind)
    run.jobs0 = #jobs
    if mode == "accessible" then
        run.stops = R.route(p, jobs)
        for _, s in ipairs(run.stops) do
            local adj = AdjacentFreeTileFinder and AdjacentFreeTileFinder.Find(s.sq, p)
            local first = #run.acts + 1
            if adj then queueActs(run, p, { ISWalkToTimedAction:new(p, adj) }) end
            for _, j in ipairs(s.jobs) do queueActs(run, p, R.actionsFor(p, j, true)) end
            s.firstAct = run.acts[first]
        end
        -- the things already on you go in place where you stand
        for _, j in ipairs(jobs) do if not j.sq then queueActs(run, p, R.actionsFor(p, j, true)) end end
        if #run.stops > 0 and run.startSq then queueActs(run, p, { ISWalkToTimedAction:new(p, run.startSq) }) end
        if #run.acts == 0 then finish(p, run, nil) end
    elseif mode == "hardcore" then
        for _, j in ipairs(jobs) do
            if (not j.sq) or R.inReach(p, j.sq) then queueActs(run, p, R.actionsFor(p, j, true)) end
        end
        if #run.acts == 0 then finish(p, run, nil) end
    end
    -- (Casual: its first tick queues what is in reach now)
    touch()
    return run
end

--- Stop the run: the queue cancelled; why = "key" | "zombie" | "hurt" | "user" (pressed again)
function R.stop(p, why)
    local run = R.runs[p:getPlayerNum()]
    if not run or run.done then return end
    if R.pending(p, run) > 0 or ISTimedActionQueue.isPlayerDoingAction(p) then ISTimedActionQueue.clear(p) end
    finish(p, run, why or "user")
end

--- A key or a button: the queue cancelled. Casual keeps its list pinned and waits for the
-- containers in reach to change (you walk with the keys); the other two stop.
function R.onKey(p)
    local run = p and R.runs[p:getPlayerNum()]
    if not run or run.done then return end
    if run.mode == "casual" then
        if R.pending(p, run) > 0 then
            ISTimedActionQueue.clear(p)
            run.acts = {}
            run.held = run.reachSig
            touch()
        end
        return
    end
    R.stop(p, "key")
end

-- Casual, idle: queue the takes from the containers in reach (each once for this set of containers)
local function tickCasual(p, run)
    R.forget(p)
    local jobs, plan = R.runJobs(p, run.kind)
    if #jobs == 0 then
        -- done when the list is empty (lines waiting to be asked stay on it)
        if not (plan and plan.count and (plan.count.ask or 0) > 0) then finish(p, run, nil) end
        return
    end
    local sig = plan.scan and plan.scan.reachSig or ""
    if run.held and run.held == sig then return end
    run.held = nil
    run.reachSig = sig
    local now = {}
    for _, j in ipairs(jobs) do
        local k = tostring(j.item and j.item:getID()) .. "|" .. j.kind
        if ((not j.sq) or R.inReach(p, j.sq)) and run.tried[k] ~= sig then
            run.tried[k] = sig
            now[#now + 1] = j
        end
    end
    if #now == 0 then return end
    run.acts = {}
    for _, j in ipairs(now) do queueActs(run, p, R.actionsFor(p, j, true)) end
    noticeFor(p, run, now)
    touch()
end

-- one run's tick (every 10 ticks)
local function tickRun(p, run)
    -- a zombie coming into view, getting hurt
    local zv = p:getStats():getNumVisibleZombies()
    if zv > (run.z0 or 0) then R.stop(p, "zombie"); return end
    run.z0 = math.min(run.z0 or 0, zv)
    if hpOf(p) < (run.hp0 or 100) - 0.5 then R.stop(p, "hurt"); return end
    -- any button on the pad
    local ps = padState(run.pn)
    if ps and run.pads then
        for b = 0, 15 do
            if ps[b] and not run.pads[b] then run.pads = ps; R.onKey(p); return end
        end
    end
    run.pads = ps
    local busy = R.pending(p, run) > 0 or ISTimedActionQueue.isPlayerDoingAction(p)
    if run.mode == "casual" then
        if not busy then tickCasual(p, run) end
        return
    end
    -- Hardcore / Accessible: done when its actions have run
    if not busy then finish(p, run, nil) end
end

--- Accessible: which stop it walks to, of how many, and the time left (s).
function R.progress(p, run)
    if not (run and run.stops) then return nil end
    local _, u = R.pending(p, run)
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local inQ = {}
    for _, a in ipairs(q and q.queue or {}) do inQ[a] = true end
    local at = #run.stops
    for i, s in ipairs(run.stops) do
        if s.firstAct and inQ[s.firstAct] then at = i; break end
    end
    -- walking left: the tiles from here to the stops not reached, and back
    local tiles = 0
    local cx, cy = p:getX(), p:getY()
    for i = at, #run.stops do
        local s = run.stops[i]
        tiles = tiles + math.abs(s.x - cx) + math.abs(s.y - cy)
        cx, cy = s.x, s.y
    end
    tiles = tiles + math.abs(run.start.x - cx) + math.abs(run.start.y - cy)
    local left = 0
    for _, a in ipairs(run.acts) do if inQ[a] and a.Type ~= "ISWalkToTimedAction" then left = left + R.units(a) end end
    return at, #run.stops, left * R.SEC_PER_UNIT + tiles * R.WALK_SEC_PER_TILE
end

-- ---------------------------------------------------------------------------
-- HOME, WHAT YOU LEFT WITH, UNPACK
-- ---------------------------------------------------------------------------
-- every item on the character (main inventory and the bags in it, held and worn)
local function allOn(p)
    local out = {}
    local function walk(inv, depth)
        if not inv or depth > 4 then return end
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            out[#out + 1] = it
            if instanceof(it, "InventoryContainer") then walk(it:getInventory(), depth + 1) end
        end
    end
    walk(p:getInventory(), 1)
    return out
end
R.allOn = allOn

--- What you leave with (taken when you step out of home; QA calls it directly).
function R.snapshotTrip(p)
    local s = L.store(p)
    if not s then return end
    local ids = {}
    for _, it in ipairs(allOn(p)) do ids[#ids + 1] = it:getID() end
    s.trip = { ids = ids, b = s.home and s.home.b }
    touch()
end

--- You are home with things from a trip: Unpack is offered.
function R.homeNow(p)
    local s = L.store(p)
    if not (s and s.home and s.trip) then return false end
    local b = R.buildingOf(p)
    return b ~= nil and R.bkey(b) == s.home.b
end

-- a container reference kept for a building (a kind's chosen home): its square, object and index
local function refOf(src)
    return { x = src.x, y = src.y, z = src.z, oi = src.oi, ci = src.ci, name = src.name, t = tostring(src.cont:getType()) }
end
local function sourceOfRef(scan, ref)
    if not ref then return nil end
    for _, s in ipairs(scan.sources) do
        if s.x == ref.x and s.y == ref.y and s.z == ref.z and not s.floor and tostring(s.cont:getType()) == ref.t then return s end
    end
    return nil
end

-- a thing's kind for where it lives: its category (the game's display category)
local function kindOf(it)
    return tostring(call(it, "getDisplayCategory") or call(it, "getCategory") or "Item")
end
R.kindOf = kindOf

-- the container in the building holding most of that type, else of that category
local function homeFor(p, scan, it, homes)
    local ft = it:getFullType()
    local cat = kindOf(it)
    local bestT, nT, bestC, nC = nil, 0, nil, 0
    for _, src in ipairs(scan.sources) do
        if not src.floor and not src.vehicle then
            local t, c = 0, 0
            local items = src.cont:getItems()
            for i = 0, items:size() - 1 do
                local x = items:get(i)
                if x:getFullType() == ft then t = t + 1 end
                if kindOf(x) == cat then c = c + 1 end
            end
            if t > nT then bestT, nT = src, t end
            if c > nC then bestC, nC = src, c end
        end
    end
    if bestT then return bestT, "type" end
    if bestC then return bestC, "kind" end
    local chosen = homes and sourceOfRef(scan, homes[cat])
    if chosen then return chosen, "chosen" end
    return nil
end

--- The unpack plan: { loot = { { item, dest, state = "put" | "pick", cat } },
--   leftovers = { { item, state = "stay" | "put", dest } }, stays = { names }, scan }
function R.unpackPlan(p)
    local s = L.store(p)
    local scan = R.scan(p)
    local up = { loot = {}, leftovers = {}, stays = {}, scan = scan }
    if not (s and s.trip) then return up end
    local had = {}
    for _, id in ipairs(s.trip.ids or {}) do had[id] = true end
    local homes = (s.homes and scan.bkey) and s.homes[scan.bkey] or nil
    local _, lo = R.current(p)
    local equipped = {}
    local worn = p:getWornItems()
    for i = 0, (worn and worn:size() or 0) - 1 do equipped[worn:get(i):getItem()] = true end
    equipped[p:getPrimaryHandItem() or false] = true
    equipped[p:getSecondaryHandItem() or false] = true
    local stayNames, seenName = {}, {}
    for _, it in ipairs(allOn(p)) do
        local isBag = instanceof(it, "InventoryContainer")
        local onBelt = L.placeOf(p, it)
        local gear = equipped[it] or (onBelt and onBelt:sub(1, 5) == "belt:")
        if gear or (isBag and had[it:getID()]) then
            local nm = call(it, "getDisplayName") or "?"
            if not seenName[nm] then seenName[nm] = true; stayNames[#stayNames + 1] = nm end
        elseif not had[it:getID()] then
            local dest = homeFor(p, scan, it, homes)
            up.loot[#up.loot + 1] = { item = it, dest = dest, state = dest and "put" or "pick", cat = kindOf(it) }
        else
            local supply = L.classify(it) == "supply"
            if supply and spoilLeft(it) < R.SPOIL_SOON_DAYS and instanceof(it, "Food") then
                local dest = homeFor(p, scan, it, homes)
                up.leftovers[#up.leftovers + 1] = { item = it, dest = dest, state = dest and "put" or "pick", cat = kindOf(it), spoils = spoilLeft(it) }
            elseif supply then
                up.leftovers[#up.leftovers + 1] = { item = it, state = "stay" }
            else
                local nm = call(it, "getDisplayName") or "?"
                if not seenName[nm] then seenName[nm] = true; stayNames[#stayNames + 1] = nm end
            end
        end
    end
    up.stays = stayNames
    return up
end

--- A kind with no home yet: the container picked for it, kept for this building.
function R.setHome(p, cat, src)
    local s = L.store(p)
    local scan = R.scan(p)
    if not (s and scan.bkey and src) then return end
    s.homes = s.homes or {}
    s.homes[scan.bkey] = s.homes[scan.bkey] or {}
    s.homes[scan.bkey][cat] = refOf(src)
    touch()
end

function R.unpackJobs(p, up)
    local jobs = {}
    for _, grp in ipairs({ up.loot, up.leftovers }) do
        for _, e in ipairs(grp) do
            if e.state == "put" and e.dest then
                jobs[#jobs + 1] = { kind = "put", item = e.item, dest = e.dest.cont, destName = e.dest.name, sq = e.dest.sq }
            end
        end
    end
    return jobs
end

-- ---------------------------------------------------------------------------
-- EVENTS: the runs' ticks, keys, hurt; stepping out of home
-- ---------------------------------------------------------------------------
local _tick, _inHome = 0, {}
local function onTick()
    _tick = _tick + 1
    if _tick % 10 ~= 0 then return end
    -- Loadouts and outfits off: a run going stops (its queue cancelled), and nothing else is watched
    if not L.on() then
        for pn, run in pairs(R.runs) do
            local p = getSpecificPlayer(pn)
            if p and not run.done then pcall(R.stop, p, "user") end
        end
        return
    end
    for pn, run in pairs(R.runs) do
        local p = getSpecificPlayer(pn)
        if p and not run.done then
            local ok, err = pcall(tickRun, p, run)
            if not ok then run.done = true; run.stopped = "error"; print("[ZeD] Restock: " .. tostring(err)) end
        end
    end
    if _tick % 30 ~= 0 then return end
    -- stepping out of home after a restock: what you leave with
    for pn = 0, 3 do
        local p = getSpecificPlayer(pn)
        local s = p and p:isLocalPlayer() and L.store(p)
        if s and s.home then
            local b = R.buildingOf(p)
            local inHome = b ~= nil and R.bkey(b) == s.home.b
            if _inHome[pn] and not inHome and not s.trip then R.snapshotTrip(p) end
            _inHome[pn] = inHome
        end
    end
end

if not _G._zedRestockHooked then
    _G._zedRestockHooked = true
    Events.OnTick.Add(function() ZeD.Restock._onTick() end)
    Events.OnKeyPressed.Add(function(key)
        for pn, run in pairs(ZeD.Restock.runs) do
            local p = getSpecificPlayer(pn)
            if p and not run.done and not (JoypadState.players[pn + 1]) then ZeD.Restock.onKey(p) end
        end
    end)
    if Events.OnPlayerGetDamage then
        Events.OnPlayerGetDamage.Add(function(chr)
            if not (chr and instanceof(chr, "IsoPlayer")) then return end
            local run = ZeD.Restock.runs[chr:getPlayerNum()]
            if run and not run.done then ZeD.Restock.stop(chr, "hurt") end
        end)
    end
end
R._onTick = onTick
