-- ZeD-UI/42/media/lua/client/ZeD/AnimalsAlertPoller.lua
-- ============================================================================
-- ALERT POLLER — client. An EveryOneMinute event hook that pre-computes:
--   1. Alert list (urgent conditions across all player animals)
--   2. Zone summaries (per-zone stats for overview)
--   3. Totals (species counts, production estimates)
--
-- Never poll during render. Render reads from CACHE only.
-- Force-refresh via refreshCache() on tab open.
-- ============================================================================

require "ZeD/AnimalsData"

ZeD = ZeD or {}
ZeD.AnimalsAlertPoller = ZeD.AnimalsAlertPoller or {}

local AP = ZeD.AnimalsAlertPoller
local AD = ZeD.AnimalsData

-- ============================================================================
-- CACHE
-- ============================================================================

local CACHE = {
    alerts        = {},     -- { { animal=, alertType=, severity= }, ... }
    zoneSummaries = {},     -- { [zone] = { name=, animals=, count=, food=, water=, roof=, maleWarnings= }, ... }
    zoneList      = {},     -- ordered list of zone refs for stable iteration
    totals        = {},     -- { speciesCounts={}, milkPerDay=, eggsPerDay=, totalAnimals= }
    allAnimals    = {},     -- flat list of all player animals (for roster)
    lastTick      = 0,
    ready         = false,
}

AP.CACHE = CACHE

-- ============================================================================
-- ZONE DISCOVERY — the cell's animals in reach, grouped by the zones the game
-- connects them to (getAnimalsConnected), getDZone() as the fallback
-- ============================================================================

local function discoverPlayerAnimals(player)
    local animals = {}
    local zoneMap = {}   -- zone ref → list of animals
    local zoneList = {}  -- ordered zone refs

    local cell = getCell()
    if not cell then return animals, zoneMap, zoneList end

    -- The cell's own list of animals, not a walk over squares: the 151 x 151 walk took 25 to 30 ms on every
    -- in-game minute, animals or none, and was every slow frame at 4K.
    -- The same reach as that walk: the player's floor, within SCAN_RADIUS squares.
    local sq = player:getCurrentSquare()
    if not sq then return animals, zoneMap, zoneList end

    local SCAN_RADIUS = 75  -- covers most ranch setups
    local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()
    local seen, placed = {}, {}   -- [animal] = true: in the list; given a zone (no animal counts twice)
    local ok, list = pcall(cell.getAnimals, cell)
    -- (the list is a LinkedList, slow by index: walked once with its iterator)
    local it = ok and list and list:iterator()
    while it and it:hasNext() do
        local obj = it:next()
        if obj and math.floor(obj:getZ()) == cz and math.abs(obj:getX() - cx) <= SCAN_RADIUS
                and math.abs(obj:getY() - cy) <= SCAN_RADIUS and not AD.isWild(obj) then
            table.insert(animals, obj)
            seen[obj] = true
        end
    end

    local function put(zone, obj)
        if not zoneMap[zone] then
            zoneMap[zone] = {}
            table.insert(zoneList, zone)
        end
        if obj and not placed[obj] then
            placed[obj] = true
            table.insert(zoneMap[zone], obj)
            -- (connected to the zone but past the scan's reach: the totals count it too, as the zone row does)
            if not seen[obj] then seen[obj] = true; table.insert(animals, obj) end
        end
    end

    -- Every streamed zone, empty ones too, with the animals the game counts in it: the game's own zone window
    -- counts zone:getAnimalsConnected(). An animal's getDZone() can stay empty long after it is placed (a
    -- spawned hen still had none 200 ticks on), so it is only the fallback below.
    local allZonesJava = DesignationZoneAnimal and DesignationZoneAnimal.getAllZones and DesignationZoneAnimal.getAllZones()
    if allZonesJava then
        for i = 0, allZonesJava:size() - 1 do
            local zone = allZonesJava:get(i)
            if zone and zone.isStillStreamed and zone:isStillStreamed() then
                put(zone, nil)
                local okC, conn = false, nil
                if zone.getAnimalsConnected then okC, conn = pcall(zone.getAnimalsConnected, zone) end
                if okC and conn then
                    for j = 0, conn:size() - 1 do
                        local obj = conn:get(j)
                        if obj then put(zone, obj) end
                    end
                end
            end
        end
    end

    -- the fallback: an animal in reach that no zone listed, by its own zone
    for _, obj in ipairs(animals) do
        if not placed[obj] then
            local zone = obj.getDZone and obj:getDZone()
            if zone then put(zone, obj) end
        end
    end

    return animals, zoneMap, zoneList
end

-- ============================================================================
-- ALERT COMPUTATION
-- ============================================================================

local function computeAlerts(animals)
    local alerts = {}

    for _, animal in ipairs(animals) do
        -- The milk and wool alerts use the game's own menu tests (AD.hasMilk, AD.hasWool): an animal that
        -- can be milked or sheared in principle but has nothing to give is no alert. All milkable and the
        -- roster tags ask the same two functions, so the counts agree.
        local urgent = AD.isUdderUrgent(animal) and AD.hasMilk(animal)
        if urgent then
            table.insert(alerts, { animal = animal, alertType = "udder_urgent", severity = "danger" })
        end

        -- Ready to milk (non-urgent)
        if AD.hasMilk(animal) and not urgent then
            table.insert(alerts, { animal = animal, alertType = "ready_milk", severity = "info" })
        end

        -- Ready to shear
        if AD.hasWool(animal) then
            table.insert(alerts, { animal = animal, alertType = "ready_shear", severity = "info" })
        end

        -- Thirsty (> 80)
        if AD.getThirst(animal) > 80 then
            table.insert(alerts, { animal = animal, alertType = "thirsty", severity = "warn" })
        end

        -- Hungry (> 80)
        if AD.getHunger(animal) > 80 then
            table.insert(alerts, { animal = animal, alertType = "hungry", severity = "warn" })
        end

        -- Stressed (>= 80)
        if AD.getStress(animal) >= 80 then
            table.insert(alerts, { animal = animal, alertType = "stressed", severity = "warn" })
        end

        -- Lost mother (orphan)
        if AD.needsMother(animal) then
            table.insert(alerts, { animal = animal, alertType = "lost_mother", severity = "danger" })
        end
    end

    -- Sort: danger first, then warn, then info
    local SEV_ORDER = { danger = 1, warn = 2, info = 3 }
    table.sort(alerts, function(a, b)
        local sa = SEV_ORDER[a.severity] or 9
        local sb = SEV_ORDER[b.severity] or 9
        return sa < sb
    end)

    return alerts
end

-- ============================================================================
-- ZONE SUMMARY COMPUTATION
-- ============================================================================

local function computeZoneSummary(zone, animals)
    local summary = {
        zone     = zone,
        name     = "",
        count    = #animals,
        animals  = animals,
        food     = 0,       -- 0–100: feed in the zone's troughs against what they hold full
        water    = 0,       -- 0–100: water in the zone's troughs against their capacity
        roof     = 0,       -- 0–100 percentage of roofed squares
        maleWarnings = {},  -- list of species with male-on-male risk
        troughs  = {},      -- IsoFeedingTrough (the zone's, as vanilla's zone window sums them)
        hutches  = {},      -- IsoHutch
        feed     = 0,       -- feed amount summed
        waterL   = 0,       -- litres summed
        waterMax = 0,
    }

    -- Zone name
    if zone.getName then
        local ok, val = pcall(zone.getName, zone)
        summary.name = (ok and val) or "Unnamed Zone"
    end

    -- Troughs and hutches (DesignationZoneAnimal getTroughsConnected / getHutchsConnected)
    local function list(m)
        local out = {}
        if not zone[m] then return out end
        local ok, arr = pcall(zone[m], zone)
        if ok and arr then for i = 0, arr:size() - 1 do out[#out + 1] = arr:get(i) end end
        return out
    end
    summary.troughs = list("getTroughsConnected")
    summary.hutches = list("getHutchsConnected")
    local feed, feedMax = 0, 0
    for _, tr in ipairs(summary.troughs) do
        local ok1, f = pcall(tr.getCurrentFeedAmount, tr)
        local ok2, fm = pcall(tr.getMaxFeed, tr)
        local ok3, wl = pcall(tr.getWater, tr)
        local ok4, wm = pcall(tr.getMaxWater, tr)
        if ok1 and f then feed = feed + f end
        if ok2 and fm then feedMax = feedMax + fm end
        if ok3 and wl then summary.waterL = summary.waterL + wl end
        if ok4 and wm then summary.waterMax = summary.waterMax + wm end
    end
    summary.feed = feed
    if feedMax > 0 then summary.food = math.min(100, math.floor(feed / feedMax * 100)) end
    if summary.waterMax > 0 then summary.water = math.min(100, math.floor(summary.waterL / summary.waterMax * 100)) end

    -- Roof percentage: the game keeps the zone's roofed squares in a list, rebuilt every few seconds (the count
    -- its own zone window shows), so this is one size() a minute and no walk over the zone's squares. A new roof
    -- is added to that list on top of what it holds until the next rebuild, so it can pass the area for a moment.
    if zone.getRoofAreas and zone.getW and zone.getH then
        local ok, roofed, area = pcall(function() return zone:getRoofAreas():size(), zone:getW() * zone:getH() end)
        if ok and area > 0 then summary.roof = math.min(100, math.floor((roofed / area) * 100)) end
    end

    -- Male-on-male warnings: count adult males per species
    local maleCounts = {}  -- type → count of adult males that attack
    for _, animal in ipairs(animals) do
        if AD.attacksOtherMales(animal) and not AD.isFemale(animal) and not AD.isBaby(animal) then
            local atype = AD.getAnimalType(animal)
            maleCounts[atype] = (maleCounts[atype] or 0) + 1
        end
    end
    for atype, count in pairs(maleCounts) do
        if count >= 2 then
            table.insert(summary.maleWarnings, atype)
        end
    end

    return summary
end

-- ============================================================================
-- TOTALS COMPUTATION
-- ============================================================================

local function computeTotals(animals)
    local totals = {
        totalAnimals  = #animals,
        speciesCounts = {},  -- type → count
        milkPerDay    = 0,   -- rough estimate
        eggsPerDay    = 0,   -- rough estimate
    }

    for _, animal in ipairs(animals) do
        local atype = AD.getAnimalType(animal)
        totals.speciesCounts[atype] = (totals.speciesCounts[atype] or 0) + 1

        -- Eggs estimate
        local eggs = AD.getEggsPerDay(animal)
        if eggs > 0 then
            totals.eggsPerDay = totals.eggsPerDay + eggs
        end

        -- Milk rough estimate: maxMilk is roughly the daily capacity
        local maxMilk = AD.getMaxMilk(animal)
        if maxMilk > 0 and AD.isFemale(animal) and not AD.isBaby(animal) then
            totals.milkPerDay = totals.milkPerDay + maxMilk
        end
    end

    return totals
end

-- ============================================================================
-- REFRESH — synchronous full cache rebuild
-- ============================================================================

--- Rebuild the whole cache now. The minute hook calls it; the tab calls it on open so the first frame has data.
function AP.refreshCache()
    local player = getSpecificPlayer(0)
    if not player then return end

    local animals, zoneMap, zoneList = discoverPlayerAnimals(player)

    CACHE.allAnimals = animals
    CACHE.zoneList   = zoneList
    CACHE.alerts     = computeAlerts(animals)
    CACHE.totals     = computeTotals(animals)

    -- Zone summaries (keyed by zone name for stable identity across cache refreshes)
    CACHE.zoneSummaries = {}
    CACHE.zoneOf = {}
    for _, zone in ipairs(zoneList) do
        local summary = computeZoneSummary(zone, zoneMap[zone] or {})
        local key = summary.name or "?"
        CACHE.zoneSummaries[key] = summary
        for _, a in ipairs(zoneMap[zone] or {}) do CACHE.zoneOf[a] = key end
    end

    CACHE.lastTick = getTimestampMs() or 0
    CACHE.ready    = true
end

-- ============================================================================
-- PUBLIC ACCESSORS
-- ============================================================================

function AP.getAlerts()       return CACHE.alerts end
function AP.getZoneList()     return CACHE.zoneList end
function AP.getTotals()       return CACHE.totals end
function AP.getAllAnimals()    return CACHE.allAnimals end
function AP.isReady()         return CACHE.ready end

--- Get zone summary by name (stable key).
function AP.getZoneSummary(zoneName)
    return CACHE.zoneSummaries[zoneName]
end

--- The name of the zone the last refresh put this animal in (the zone rows' own count), or nil.
function AP.getZoneNameOf(animal)
    return CACHE.zoneOf and CACHE.zoneOf[animal] or nil
end

--- Get animals for a specific zone by name (from cache)
function AP.getAnimalsInZone(zoneName)
    local summary = CACHE.zoneSummaries[zoneName]
    return summary and summary.animals or {}
end

-- ============================================================================
-- EVENT HOOK — EveryOneMinute
-- ============================================================================

local function onEveryOneMinute()
    AP.refreshCache()
end

-- ============================================================================
-- LIFECYCLE
-- ============================================================================

local registered = false

function AP.start()
    if registered then return end
    Events.EveryOneMinute.Add(onEveryOneMinute)
    registered = true
    -- Initial populate
    AP.refreshCache()
end

function AP.stop()
    if not registered then return end
    Events.EveryOneMinute.Remove(onEveryOneMinute)
    registered = false
end

-- Auto-start on game load
local function onGameStart()
    AP.start()
end

Events.OnGameStart.Add(onGameStart)
