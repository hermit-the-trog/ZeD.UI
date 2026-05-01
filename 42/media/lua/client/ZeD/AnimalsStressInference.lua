-- ZeD-UI/42/media/lua/client/ZeD/AnimalsStressInference.lua
-- ============================================================================
-- STRESS SOURCE INFERENCE — plausible-contributors list for stress display.
-- No confidence ranking. Simple threshold checks on environment + state.
-- Capped at 3 entries to prevent UI overflow.
--
-- Gunshot detection deferred to Phase 2 — no reliable recent-gunshots
-- accessor confirmed in PZ 42.16. Placeholder comment left in.
-- ============================================================================

require "ZeD/AnimalsData"
require "ZeD/AnimalsDisorderCatalog"

ZeD = ZeD or {}
ZeD.AnimalsStressInference = ZeD.AnimalsStressInference or {}

local SI = ZeD.AnimalsStressInference
local AD = ZeD.AnimalsData
local DC = ZeD.AnimalsDisorderCatalog

-- ============================================================================
-- ZOMBIE COUNTING — grid square iteration in radius
-- Same pattern as ISButcherHookUI:lookForCorpse() but for live zombies.
-- ============================================================================

local function countZombiesInRadius(animal, radius)
    local sq = animal:getCurrentSquare()
    if not sq then return 0 end
    local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()
    local count = 0
    local cell = getCell()
    if not cell then return 0 end
    for x = cx - radius, cx + radius do
        for y = cy - radius, cy + radius do
            local gs = cell:getGridSquare(x, y, cz)
            if gs then
                local movingObjects = gs:getMovingObjects()
                if movingObjects then
                    for i = 0, movingObjects:size() - 1 do
                        local obj = movingObjects:get(i)
                        if obj and instanceof(obj, "IsoZombie") then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    return count
end

-- ============================================================================
-- MAIN INFERENCE
-- ============================================================================

--- Infer plausible stress sources for the given animal.
-- @param animal  IsoAnimal instance
-- @param player  IsoPlayer instance (unused in v1, reserved for proximity checks)
-- @return list of short human-readable source strings, max 3
function SI.inferSources(animal, player)
    if not animal then return {} end
    local sources = {}

    -- Hunger
    local hunger = AD.getHunger(animal)
    if hunger > 80 then
        table.insert(sources, "hunger")
    end

    -- Thirst
    local thirst = AD.getThirst(animal)
    if thirst > 80 then
        table.insert(sources, "thirst")
    end

    -- Environment: rain without shelter
    local square = animal.getCurrentSquare and animal:getCurrentSquare()
    if square then
        local roofed = square.isRoofed and square:isRoofed()
        if not roofed then
            local climate = getClimateManager()
            if climate and climate:getPrecipitationIntensity() > 0 then
                table.insert(sources, "rain")
            end
        end
    end

    -- Zombies nearby (radius 15)
    local zombieCount = countZombiesInRadius(animal, 15)
    if zombieCount > 0 then
        if zombieCount == 1 then
            table.insert(sources, "zombie nearby")
        else
            table.insert(sources, zombieCount .. " zombies nearby")
        end
    end

    -- Moving vehicle
    local vehicle = animal.getVehicle and animal:getVehicle()
    if vehicle then
        local ok, speed = pcall(vehicle.getCurrentSpeedKmHour, vehicle)
        if ok and speed and speed > 5 then
            table.insert(sources, "moving vehicle")
        end
    end

    -- Genetic amplifier: anxious trait
    if DC.hasDisorder(animal, "highstress") then
        table.insert(sources, "anxious trait")
    end

    -- Male-on-male aggression (uses engine flag, not manual counting)
    if AD.attacksOtherMales(animal) and not AD.isFemale(animal) and not AD.isBaby(animal) then
        -- Only flag if there's another adult male of same type in the same zone
        local zone = animal.getDZone and animal:getDZone()
        if zone then
            local connected = zone.getAnimalsConnected and zone:getAnimalsConnected()
            if connected then
                local myType = AD.getAnimalType(animal)
                for i = 0, connected:size() - 1 do
                    local other = connected:get(i)
                    if other and other ~= animal
                       and AD.getAnimalType(other) == myType
                       and not AD.isFemale(other)
                       and not AD.isBaby(other) then
                        table.insert(sources, "male-on-male tension")
                        break
                    end
                end
            end
        end
    end

    -- Phase 2: gunshot detection
    -- PZ doesn't expose a queryable recent-gunshots log from Lua.
    -- Options for later: OnWeaponHitCharacter event → ring buffer,
    -- or IsoPlayer:getTimeSinceLastGunShot() if it exists.

    -- Cap at 3 to avoid UI overflow
    if #sources > 3 then
        local extra = #sources - 2
        sources = { sources[1], sources[2], "+" .. extra .. " more" }
    end

    return sources
end
