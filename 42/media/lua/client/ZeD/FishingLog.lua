-- ZeD-UI/42/media/lua/client/ZeD/FishingLog.lua
-- ============================================================================
-- THE FISHING TAB'S MODEL — client; no drawing.
-- What the World window's Fishing tab reads, worked out from the game's own
-- fishing code (Fishing.FishingManager, FishingRod, Bobber, Fish and
-- fishing_properties): when the tab shows, which state the line is in, the rod,
-- the bait in the bags, the bait ratings the game gives from Fishing 6, the
-- catch log and the trophy records.
--
-- The log and the trophies live in the player's mod data (ZeD_Fishing), so they
-- are kept with the save and stay small: the newest 64 catches, the 10 heaviest
-- fish and the best of each of the game's species (21), nothing more.
--
-- A catch is recorded where the game lands it: Fishing.States.PickupFish:start
-- is wrapped, the game's own start runs first and untouched, then ZeD writes down
-- what came up (a fish, junk or nothing). Fishing.States.Cast:start is wrapped
-- the same way, so the tab can open itself when the line goes out. The game's
-- own functions are kept once (_zedOrig*), so a Lua reload never wraps the wrapper.
-- ============================================================================

ZeD = ZeD or {}   -- Reload-safe: loading this file twice reuses the table instead of wiping it.
ZeD.FishingLog = ZeD.FishingLog or {}
local L = ZeD.FishingLog

L.KEY = "ZeD_Fishing"
L.LOG_MAX = 64          -- catches kept in the save
L.LOG_SHOW = 20         -- the newest the tab shows
L.TOP_MAX = 10          -- the heaviest fish kept for the wall
L.VIS_R = 6             -- water this close shows the tab (tiles)
L.SCAN_R = 10           -- the header names water this close
L.RATE_LV = 6           -- the game shows what a fish likes from this Fishing level

-- the plaque's fish picture for each of the game's species (the wall draws them in pixel art)
L.KIND = {
    ["Base.LargemouthBass"] = "bass", ["Base.SmallmouthBass"] = "bronze", ["Base.WhiteBass"] = "silver",
    ["Base.SpottedBass"] = "bass", ["Base.StripedBass"] = "silver", ["Base.Bluegill"] = "sunfish",
    ["Base.WhiteCrappie"] = "crappie", ["Base.BlackCrappie"] = "crappie", ["Base.RedearSunfish"] = "sunfish",
    ["Base.YellowPerch"] = "perch", ["Base.Sauger"] = "perch", ["Base.GreenSunfish"] = "sunfish",
    ["Base.Walleye"] = "perch", ["Base.FreshwaterDrum"] = "drum", ["Base.BlueCatfish"] = "cat",
    ["Base.ChannelCatfish"] = "cat", ["Base.FlatheadCatfish"] = "cat", ["Base.Muskellunge"] = "long",
    ["Base.AligatorGar"] = "long", ["Base.Paddlefish"] = "long", ["Base.BaitFish"] = "bait",
}

-- the lure chances graded as the game's own comment on FishConfig:getLureChance grades them
L.GRADES = {
    { min = 0.8, key = "UI_ZeD_Fish_Great" }, { min = 0.6, key = "UI_ZeD_Fish_Good" },
    { min = 0.4, key = "UI_ZeD_Fish_Average" }, { min = 0.2, key = "UI_ZeD_Fish_BelowAvg" },
    { min = 0.0001, key = "UI_ZeD_Fish_Poor" }, { min = -1, key = "UI_ZeD_Fish_None" },
}

local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function nowMs() return (getTimestampMs and getTimestampMs()) or 0 end

-- ---------------------------------------------------------------------------
-- THE GAME'S FISHING STATE
-- ---------------------------------------------------------------------------
--- The game's fishing manager for player p (FishingHandler keys it by username in multiplayer).
function L.manager(p)
    local M = Fishing and Fishing.ManagerInstances
    if not (M and p) then return nil end
    local idx = (isMultiplayer and isMultiplayer()) and p:getUsername() or p:getPlayerNum()
    return M[idx]
end

--- True when item is a fishing rod (the game's own test, FishingHandler.isFishingValid).
function L.isRod(item)
    return item ~= nil and safe(function() return item:hasTag(ItemTag.FISHING_ROD) end, false) == true
end

--- The rod in p's main hand, or nil.
function L.rodInHand(p)
    local it = p and p:getPrimaryHandItem()
    if L.isRod(it) then return it end
    return nil
end

-- every item p carries, bags included (the game's own walk, as its rod menu takes it)
local function carried(p)
    local out = {}
    local list = safe(function() return p:getInventory():getAllEvalRecurse(function() return true end, ArrayList.new()) end, nil)
    if not list then return out end
    for i = 0, list:size() - 1 do out[#out + 1] = list:get(i) end
    return out
end
L._carried = carried

-- The bait rows and the bag rod, kept for half a second per player. The tab asks every frame, and each answer walks
-- every item in every bag (a few hundred items for someone out fishing); what p carries hardly changes in that time.
-- The tab's Bait and Equip keys read fresh (fresh = true) before they act.
L.CARRY_MS = 500
local _carry = {}
local function carryCache(p)
    local key = p:getPlayerNum()
    local c = _carry[key]
    if not c then c = {}; _carry[key] = c end
    return c
end
function L._resetCarry() _carry = {} end

--- A rod in p's bags that is not broken (for Equip rod), or nil. fresh: walk the bags now, not the half-second copy.
function L.rodInBags(p, fresh)
    local c = carryCache(p)
    local t = nowMs()
    if not fresh and c.rodAt and t - c.rodAt < L.CARRY_MS then return c.rod end
    local rod = nil
    for _, it in ipairs(carried(p)) do
        if L.isRod(it) and not safe(function() return it:isBroken() end, false) then rod = it; break end
    end
    c.rod, c.rodAt = rod, t
    return rod
end

--- The bait p carries, one row per kind, as the game's Add Bait menu finds it (a lure the game knows,
--- not cooked): { type, name, n, where, item, lure (an artificial lure) }, in the order first met.
--- fresh: walk the bags now, not the half-second copy.
function L.baits(p, fresh)
    if not (Fishing and Fishing.IsLure) then return {} end
    local c = carryCache(p)
    local t = nowMs()
    if not fresh and c.baitsAt and t - c.baitsAt < L.CARRY_MS then return c.baits end
    local rows, byType = {}, {}
    for _, it in ipairs(carried(p)) do
        local ft = it:getFullType()
        if Fishing.IsLure(ft) and not (instanceof(it, "Food") and it:isCooked()) then
            local r = byType[ft]
            if not r then
                local box = safe(function() return it:getContainer():getContainingItem() end, nil)
                r = { type = ft, name = it:getName(), n = 0, item = it,
                      where = box and box:getName() or nil,
                      lure = Fishing.IsArtificalLure and Fishing.IsArtificalLure(ft) or false }
                byType[ft] = r
                rows[#rows + 1] = r
            end
            r.n = r.n + 1
        end
    end
    c.baits, c.baitsAt = rows, t
    return rows
end

--- The tab's state for p: "fight" (a fish on the line), "wait" (the line out), "ready" (rod in hand),
--- "nobait" (rod in hand, nothing on the hook and none in the bags) or "norod".
function L.state(p, baits)
    local rod = L.rodInHand(p)
    if not rod then return "norod" end
    local m = L.manager(p)
    local fr = m and m.fishingRod
    if fr and fr.bobber then
        if fr.bobber.fish then return "fight" end
        return "wait"
    end
    if fr and (fr.spawnBobberDelayTimer or 0) > 0 then return "wait" end   -- (cast, the bobber still in the air)
    local lure = rod:getModData().fishing_Lure
    if lure == nil and #(baits or L.baits(p)) == 0 then return "nobait" end
    return "ready"
end

--- The lure on rod's hook (its full type), or nil.
function L.onHook(rod)
    return rod and rod:getModData().fishing_Lure or nil
end

--- The rod's line and hook from its mod data: line type, condition 0 to 1, hook type (nil: none).
function L.tackle(rod)
    local md = rod and rod:getModData()
    if not md then return nil end
    return { line = md.fishing_LineType or "Base.FishingLine", cond = md.fishing_LineCondition or 1, hook = md.fishing_HookType }
end

-- ---------------------------------------------------------------------------
-- WHERE THE WATER IS
-- ---------------------------------------------------------------------------
local COMPASS = {
    "UI_ZeD_Forage_CompassN", "UI_ZeD_Forage_CompassNE", "UI_ZeD_Forage_CompassE", "UI_ZeD_Forage_CompassSE",
    "UI_ZeD_Forage_CompassS", "UI_ZeD_Forage_CompassSW", "UI_ZeD_Forage_CompassW", "UI_ZeD_Forage_CompassNW",
}
--- The compass point (a translation key) from (x0, y0) toward (x1, y1); the map's north is y going down.
function L.bearing(x0, y0, x1, y1)
    local dx, dy = x1 - x0, -(y1 - y0)
    if dx == 0 and dy == 0 then return COMPASS[1] end
    local heading = 90 - math.deg(math.atan2(dy, dx))
    while heading < 0 do heading = heading + 360 end      -- (no %: Kahlua's keeps a negative's sign)
    while heading >= 360 do heading = heading - 360 end
    local i = math.floor((heading + 22.5) / 45) + 1
    if i > 8 then i = 1 end
    return COMPASS[i]
end

local function isWater(sq)
    return sq ~= nil and safe(function() return sq:getProperties():has(IsoFlagType.water) end, false) == true
end

-- the nearest water square, cached for half a second per player (the windows ask every frame)
local _scan = {}
--- The nearest water within L.SCAN_R tiles of p: { d (tiles), x, y, dir (compass key) }, or nil.
function L.water(p)
    if not p then return nil end
    local key = p:getPlayerNum()
    local c = _scan[key]
    local t = nowMs()
    if c and t - c.at < 500 then return c.hit end
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local cell = getCell()
    local best, bd = nil, nil
    if cell and pz == 0 then
        for dy = -L.SCAN_R, L.SCAN_R do
            for dx = -L.SCAN_R, L.SCAN_R do
                local d2 = dx * dx + dy * dy
                if (not bd or d2 < bd) and d2 <= L.SCAN_R * L.SCAN_R and isWater(cell:getGridSquare(px + dx, py + dy, 0)) then
                    best, bd = { x = px + dx, y = py + dy }, d2
                end
            end
        end
    end
    if best then
        best.d = math.floor(math.sqrt(bd) + 0.5)
        best.dir = L.bearing(px, py, best.x, best.y)
    end
    _scan[key] = { at = t, hit = best }
    return best
end
function L._resetScan() _scan = {} end

--- True while the tab shows: a rod in the main hand, or water within L.VIS_R tiles.
function L.visible(p)
    if not p then return false end
    if L.rodInHand(p) then return true end
    local w = L.water(p)
    return w ~= nil and w.d <= L.VIS_R
end

-- ---------------------------------------------------------------------------
-- THE GAME'S FISH TABLES
-- ---------------------------------------------------------------------------
--- The game's species in its own order (Fishing.fishes): { type, cfg } each.
function L.species()
    local out = {}
    for _, cfg in ipairs((Fishing and Fishing.fishes) or {}) do
        out[#out + 1] = { type = cfg.itemType, cfg = cfg }
    end
    return out
end

local function speciesKnown(ft)
    for _, cfg in ipairs((Fishing and Fishing.fishes) or {}) do
        if cfg.itemType == ft then return true end
    end
    return false
end

--- The grade key for a lure chance (0 to 1), as the game's comment grades it.
function L.grade(ch)
    ch = math.max(0, math.min(1, ch or 0))
    for _, g in ipairs(L.GRADES) do
        if ch >= g.min then return g.key end
    end
    return L.GRADES[#L.GRADES].key
end

--- The game's own record of the species p has landed (fishing_catchedFish), as a count. The game writes junk
--- into that record too (every pick-up, Seaweed and empty cans included), so only its species are counted.
function L.caughtCount(p)
    local t = p and p:getModData().fishing_catchedFish
    local n = 0
    if t then
        for _, cfg in ipairs((Fishing and Fishing.fishes) or {}) do
            if t[cfg.itemType] then n = n + 1 end
        end
    end
    return n
end

--- How many species the game has (Fishing.fishes), without building L.species' list.
function L.speciesCount()
    return #((Fishing and Fishing.fishes) or {})
end

--- What bait type `bt` is worth to each species p has caught, from Fishing L.RATE_LV, as the game rates it:
--- { { key = grade key, types = { full types } }, ... } best grade first, and the count of species caught.
--- nil below the level or with no bait.
function L.ratings(p, bt)
    if not (p and bt) or p:getPerkLevel(Perks.Fishing) < L.RATE_LV then return nil end
    local caught = p:getModData().fishing_catchedFish or {}
    local groups, byKey, n = {}, {}, 0
    for _, cfg in ipairs((Fishing and Fishing.fishes) or {}) do
        if caught[cfg.itemType] then
            n = n + 1
            local k = L.grade(cfg.lure and cfg.lure[bt] or 0)
            local g = byKey[k]
            if not g then g = { key = k, types = {} }; byKey[k] = g end
            g.types[#g.types + 1] = cfg.itemType
        end
    end
    for _, gr in ipairs(L.GRADES) do
        if byKey[gr.key] then groups[#groups + 1] = byKey[gr.key] end
    end
    return groups, n
end

-- ---------------------------------------------------------------------------
-- THE SAVED RECORDS (player mod data)
-- ---------------------------------------------------------------------------
--- p's fishing records, made on first use: { v, n (catches recorded), fish (fish landed), log (oldest
--- first), top (heaviest first), best = { [type] = record }, trip }.
function L.data(p)
    local md = p:getModData()
    local d = md[L.KEY]
    if type(d) ~= "table" then
        d = { v = 1, n = 0, fish = 0, log = {}, top = {}, best = {} }
        md[L.KEY] = d
    end
    d.log = d.log or {}
    d.top = d.top or {}
    d.best = d.best or {}
    d.n = d.n or #d.log
    d.fish = d.fish or 0
    return d
end

--- The game's clock now: year, month (0-based), day (0-based), hour, minute and the world's age in hours.
function L.clock()
    local gt = getGameTime()
    return { yr = gt:getYear(), mo = gt:getMonth(), dy = gt:getDay(), hr = gt:getHour(), mn = gt:getMinutes(),
             wa = gt:getWorldAgeHours() }
end

local function copy(t)
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end

--- Writes one catch into p's records. c = { kind = "fish" | "junk" | "gone", type, name, wt (the item's
--- weight), len (cm), bait (the lure's type), rod (its name), lv (Fishing), river (true / false), tx, ty }.
--- The log keeps the newest L.LOG_MAX; a fish goes on the wall when it is one of the L.TOP_MAX heaviest or
--- the heaviest of its species. Junk and No catch never reach the wall. Returns the record.
function L.record(p, c)
    local d = L.data(p)
    local t = c.clock or L.clock()
    local e = { k = c.kind or "fish", type = c.type, name = c.name, wt = c.wt or 0, len = c.len, bait = c.bait,
                yr = t.yr, mo = t.mo, dy = t.dy, hr = t.hr, mn = t.mn, wa = t.wa }
    d.log[#d.log + 1] = e
    while #d.log > L.LOG_MAX do table.remove(d.log, 1) end
    d.n = (d.n or 0) + 1
    L.tripAdd(d, e, c)
    if e.k ~= "fish" then return e end
    d.fish = (d.fish or 0) + 1
    local r = copy(e)
    r.k = nil
    r.rod, r.lv, r.river, r.tx, r.ty = c.rod, c.lv, c.river, c.tx, c.ty
    -- the ten heaviest, heaviest first
    local top = d.top
    local at = #top + 1
    for i = 1, #top do
        if r.wt > (top[i].wt or 0) then at = i; break end
    end
    if at <= L.TOP_MAX then
        table.insert(top, at, copy(r))
        while #top > L.TOP_MAX do table.remove(top) end
    end
    -- the heaviest of each of the game's species
    if r.type and speciesKnown(r.type) then
        local b = d.best[r.type]
        if not b or r.wt > (b.wt or 0) then d.best[r.type] = copy(r) end
    end
    return e
end

--- Empties the catch log (the trophies stay).
function L.clearLog(p)
    local d = L.data(p)
    d.log = {}
    d.trip = nil
end

--- The newest catches, newest first, at most n (default L.LOG_SHOW).
function L.recent(p, n)
    local d = L.data(p)
    local out = {}
    n = n or L.LOG_SHOW
    for i = #d.log, 1, -1 do
        out[#out + 1] = d.log[i]
        if #out >= n then break end
    end
    return out
end

--- How many species have a plaque on the wall (the heaviest of each kind landed).
function L.mountedCount(p)
    local n = 0
    for _ in pairs(L.data(p).best) do n = n + 1 end
    return n
end

--- The wall's plaques. mode "top": the ten heaviest, each { rec, rank }. mode "each": one per species in the
--- game's order, each { rec or nil, type }. Also the count of species mounted.
function L.wall(p, mode)
    local d = L.data(p)
    local out, mounted = {}, 0
    for _ in pairs(d.best) do mounted = mounted + 1 end
    if mode == "each" then
        for _, s in ipairs(L.species()) do out[#out + 1] = { rec = d.best[s.type], type = s.type } end
    else
        for i, r in ipairs(d.top) do out[#out + 1] = { rec = r, rank = i, type = r.type } end
    end
    return out, mounted
end

-- ---------------------------------------------------------------------------
-- THIS TRIP: from the first cast after a quiet spell to now
-- ---------------------------------------------------------------------------
L.TRIP_GAP = 3   -- game hours with no cast or catch end a trip

--- d's trip while it is still going at world age wa (game hours): a cast or a catch within L.TRIP_GAP hours.
--- nil once it has gone quiet. A trip is only replaced at the next cast or catch, so the record outlives its trip;
--- whatever shows "this trip" asks here first.
function L.liveTrip(d, wa)
    local tr = d and d.trip
    if not tr or (wa or 0) - (tr.last or tr.wa0 or 0) > L.TRIP_GAP then return nil end
    return tr
end

--- Starts a trip when there is none or the last one went quiet; d = L.data(p).
function L.tripTouch(d, wa, lineCond)
    local tr = L.liveTrip(d, wa)
    if not tr then
        tr = { wa0 = wa, landed = 0, junk = 0, gone = 0, total = 0, baits = {}, line0 = lineCond }
        d.trip = tr
    end
    tr.last = wa
    if lineCond then tr.line1 = lineCond end
    return tr
end

function L.tripAdd(d, e, c)
    local tr = L.tripTouch(d, e.wa or 0, c.lineCond)
    if e.k == "fish" then
        tr.landed = tr.landed + 1
        tr.total = tr.total + (e.wt or 0)
        if not tr.heavyWt or (e.wt or 0) > tr.heavyWt then tr.heavyWt, tr.heavy = e.wt, e.name end
    elseif e.k == "junk" then tr.junk = tr.junk + 1
    else tr.gone = tr.gone + 1 end
    if e.bait and c.used then tr.baits[e.bait] = (tr.baits[e.bait] or 0) + 1 end
end

-- ---------------------------------------------------------------------------
-- A SHORT PULL ON THE LINE FROM THE TAB
-- The game reels while the left mouse is down and lets line out while the right one is (on a pad: the
-- right stick turning). The tab's Reel in and Let out line ask for the same for a moment; the rod's own
-- reel and releaseLine still do the work.
-- ---------------------------------------------------------------------------
L._pull = nil
local _pullRec = {}   -- (one record, renewed every frame while a key is held: no table per frame)
--- Reel ("reel") or let out ("release") for ms milliseconds from now.
function L.pull(kind, ms)
    _pullRec.kind, _pullRec.till = kind, nowMs() + (ms or 600)
    L._pull = _pullRec
end
--- The pull asked for now, or nil.
function L.pulling()
    local pl = L._pull
    if pl and nowMs() < pl.till then return pl.kind end
    L._pull = nil
    return nil
end

-- ---------------------------------------------------------------------------
-- THE HOOKS INTO THE GAME
-- ---------------------------------------------------------------------------
L.onCast = L.onCast or {}   -- listeners: fn(player), after the line goes out

local function catchInfo(mgr)
    local fr = mgr and mgr.fishingRod
    local bob = fr and fr.bobber
    local fish = bob and bob.fish
    local p = mgr and mgr.player
    local rod = fr and fr.rodItem
    local info = { lv = p and p:getPerkLevel(Perks.Fishing) or 0, rod = rod and rod:getScriptItem():getDisplayName() or nil,
                   bait = (bob and bob.lure) or (rod and rod:getModData().fishing_Lure) or nil,
                   tx = bob and math.floor(bob:getX()) or nil, ty = bob and math.floor(bob:getY()) or nil }
    if info.rod then info.rod = getText(info.rod) end
    if info.tx and Fishing.isRiver then info.river = safe(function() return Fishing.isRiver(info.tx, info.ty) end, nil) end
    local tk = rod and L.tackle(rod)
    info.lineCond = tk and tk.cond or nil
    local item = fish and fish.fishItem
    if not item then
        info.kind = "gone"
        return p, info
    end
    info.kind = fish.isTrash and "junk" or "fish"
    info.type = item:getFullType()
    info.name = item:getName()
    info.wt = item:getActualWeight()
    info.len = item:getModData().fishing_FishSize
    return p, info
end
L._catchInfo = catchInfo

--- Wraps the game's landing and casting states (once; a reload keeps the first wrap).
function L.install()
    local S = Fishing and Fishing.States
    if not (S and S.PickupFish and S.Cast) then return false end
    local P, C = S.PickupFish, S.Cast
    P._zedOrigStart = P._zedOrigStart or P.start
    C._zedOrigStart = C._zedOrigStart or C.start
    local pickOrig, castOrig = P._zedOrigStart, C._zedOrigStart
    P.start = function(self)
        -- (read before the game's start runs: it hands the fish to the pick-up action)
        local ok, p, info = pcall(catchInfo, self.manager)
        local fr = self.manager and self.manager.fishingRod
        local rod = fr and fr.rodItem
        pickOrig(self)
        if ok and p and info then
            -- (the game's start uses the bait up or not: gone from the hook now means this catch took it)
            info.used = info.bait ~= nil and rod ~= nil and rod:getModData().fishing_Lure == nil
            local ok2, err = pcall(L.record, p, info)
            if not ok2 and ZeD.logOnce then ZeD.logOnce("fishing log", err) end
        end
    end
    C.start = function(self)
        castOrig(self)
        local p = self.manager and self.manager.player
        if not p then return end
        pcall(function()
            local tk = L.tackle(self.manager.fishingRod and self.manager.fishingRod.rodItem)
            L.tripTouch(L.data(p), L.clock().wa, tk and tk.cond)
            L.castAt = nowMs()
        end)
        for _, fn in ipairs(L.onCast) do
            local ok, err = pcall(fn, p)
            if not ok and ZeD.logOnce then ZeD.logOnce("fishing cast", err) end
        end
    end
    -- the tab's short pulls (L.pull): asked for, they win over the mouse and the stick for that moment
    local R = Fishing.FishingRod
    if R then
        R._zedOrigIsReel = R._zedOrigIsReel or R.isReel
        R._zedOrigIsRelease = R._zedOrigIsRelease or R.isReleaseLine
        local reelOrig, relOrig = R._zedOrigIsReel, R._zedOrigIsRelease
        R.isReel = function(self)
            local k = L.pulling()
            if k then return k == "reel" end
            return reelOrig(self)
        end
        R.isReleaseLine = function(self)
            local k = L.pulling()
            if k then return k == "release" end
            return relOrig(self)
        end
    end
    return true
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function() L.install() end)
end

return L
