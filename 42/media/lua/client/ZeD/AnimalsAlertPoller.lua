-- ZeD-UI/42/media/lua/client/ZeD/AnimalsAlertPoller.lua
-- ============================================================================
-- ALERT POLLER — EveryOneMinute event hook that pre-computes:
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
-- ZONE DISCOVERY — iterate loaded cell animals, group by getDZone()
-- ============================================================================

local function discoverPlayerAnimals(player)
    local animals = {}
    local zoneMap = {}   -- zone ref → list of animals
    local zoneList = {}  -- ordered zone refs

    -- Strategy: iterate all IsoAnimal instances in loaded cells.
    -- PZ exposes getCell():getObjectList() or we walk zones.
    -- Safest approach: walk the player's known designation zones.
    local cell = getCell()
    if not cell then return animals, zoneMap, zoneList end

    -- Approach: scan squares around player in a generous radius.
    -- This catches all animals the player could reasonably manage.
    -- For large ranches, EveryOneMinute cadence keeps it bounded.
    local sq = player:getCurrentSquare()
    if not sq then return animals, zoneMap, zoneList end

    local SCAN_RADIUS = 75  -- covers most ranch setups
    local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()
    local seen = {}  -- dedup by animal ID

    for x = cx - SCAN_RADIUS, cx + SCAN_RADIUS do
        for y = cy - SCAN_RADIUS, cy + SCAN_RADIUS do
            local gs = cell:getGridSquare(x, y, cz)
            if gs then
                local moving = gs:getMovingObjects()
                if moving then
                    for i = 0, moving:size() - 1 do
                        local obj = moving:get(i)
                        if obj and instanceof(obj, "IsoAnimal") and not AD.isWild(obj) then
                            local id = obj:getOnlineID()
                            if not seen[id] then
                                seen[id] = true
                                table.insert(animals, obj)

                                local zone = obj.getDZone and obj:getDZone()
                                if zone then
                                    if not zoneMap[zone] then
                                        zoneMap[zone] = {}
                                        table.insert(zoneList, zone)
                                    end
                                    table.insert(zoneMap[zone], obj)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Also include empty zones from the designation system
    -- (zones with no animals wouldn't be found by the radius scan)
    local allZonesJava = DesignationZoneAnimal and DesignationZoneAnimal.getAllZones and DesignationZoneAnimal.getAllZones()
    if allZonesJava then
        for i = 0, allZonesJava:size() - 1 do
            local zone = allZonesJava:get(i)
            if zone and zone.isStillStreamed and zone:isStillStreamed() then
                if not zoneMap[zone] then
                    zoneMap[zone] = {}
                    table.insert(zoneList, zone)
                end
            end
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
        -- Udder urgent
        if AD.isUdderUrgent(animal) then
            table.insert(alerts, { animal = animal, alertType = "udder_urgent", severity = "danger" })
        end

        -- Ready to milk (non-urgent)
        if AD.canBeMilked(animal) and not AD.isUdderUrgent(animal) then
            table.insert(alerts, { animal = animal, alertType = "ready_milk", severity = "info" })
        end

        -- Ready to shear
        if AD.canBeSheared(animal) then
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

    -- Roof percentage: sample zone squares
    if zone.getX and zone.getY and zone.getWidth and zone.getHeight then
        local ok1, zx = pcall(zone.getX, zone)
        local ok2, zy = pcall(zone.getY, zone)
        local ok3, zw = pcall(zone.getWidth, zone)
        local ok4, zh = pcall(zone.getHeight, zone)
        if ok1 and ok2 and ok3 and ok4 then
            local cell = getCell()
            local roofed, total = 0, 0
            for x = zx, zx + zw - 1 do
                for y = zy, zy + zh - 1 do
                    local gs = cell and cell:getGridSquare(x, y, 0)
                    if gs then
                        total = total + 1
                        if gs:isRoofed() then roofed = roofed + 1 end
                    end
                end
            end
            if total > 0 then summary.roof = math.floor((roofed / total) * 100) end
        end
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
    for _, zone in ipairs(zoneList) do
        local summary = computeZoneSummary(zone, zoneMap[zone] or {})
        local key = summary.name or "?"
        CACHE.zoneSummaries[key] = summary
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
