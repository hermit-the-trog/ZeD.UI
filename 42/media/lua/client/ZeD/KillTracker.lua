-- ZeD-UI/42/media/lua/client/ZeD/KillTracker.lua
-- ============================================================================
-- KILL TRACKER — native kill categorization via PZ event hooks.
-- Tracks weapon category, fire, vehicle, and explosion kills.
--
-- Stores persistent data in player:getModData().ZeD_Kills.
-- No external mod dependencies — uses vanilla PZ events only.
--
-- Event flow:
--   Weapon kill: OnWeaponHitCharacter → OnZombieDead → OnWeaponHitXp
--   Fire kill:   OnZombieDead fires twice within 20s for same zombie
--   Vehicle kill: OnZombieDead + zombie on ground + target in vehicle
-- ============================================================================

ZeD = ZeD or {}
ZeD.KillTracker = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local STALE_TIMEOUT   = 20000  -- 20s max memory for hit/death tracking
local CLEANUP_EVERY   = 300    -- clean stale entries every 300 frames (~5s at 60fps)

-- ============================================================================
-- TRANSIENT STATE (not saved — rebuilt each session)
-- ============================================================================

local hitLog    = {}  -- zombie str → {category, timestamp, isExplosion}
local deadLog   = {}  -- zombie str → first OnZombieDead timestamp
local carLog    = {}  -- zombie str → timestamp (pending vehicle kill)
local frameCount = 0

-- ============================================================================
-- HELPERS
-- ============================================================================

local function now()
    return getTimestampMs()
end

local function isLocalPlayer(char)
    local p = getSpecificPlayer(0)
    return p and p == char
end

--- Get weapon category from a HandWeapon.
-- Checks getCategories() first (skips "Improvised"), falls back to
-- getSubCategory() for firearms, then special-cases BareHands.
local function getWeaponCategory(weapon)
    if not weapon then return "Other" end

    local wtype = weapon:getType()
    if wtype == "BareHands" then return "Unarmed" end

    local cats = weapon:getCategories()
    if cats then
        for i = 0, cats:size() - 1 do
            local cat = cats:get(i)
            if cat ~= "Improvised" then return cat end
        end
    end

    local sub = weapon:getSubCategory()
    if sub and sub ~= "" then return sub end

    return "Other"
end

--- Ensure modData structure exists and return it.
local function getKillData(playerObj)
    local md = playerObj:getModData()
    if not md.ZeD_Kills then
        md.ZeD_Kills = {
            weapon    = {},
            fire      = 0,
            vehicle   = 0,
            explosion = 0,
        }
    end
    if not md.ZeD_Kills.weapon then
        md.ZeD_Kills.weapon = {}
    end
    return md.ZeD_Kills
end

--- Remove entries older than STALE_TIMEOUT from a timestamp table.
local function clearStale(tbl)
    local t = now()
    local remove = {}
    for k, v in pairs(tbl) do
        if type(v) == "number" and (t - v) > STALE_TIMEOUT then
            remove[#remove + 1] = k
        elseif type(v) == "table" and v.ts and (t - v.ts) > STALE_TIMEOUT then
            remove[#remove + 1] = k
        end
    end
    for i = 1, #remove do
        tbl[remove[i]] = nil
    end
end

-- ============================================================================
-- EVENT: OnWeaponHitCharacter
-- Fires on every weapon hit (killing or not). We log the hit so that when
-- OnZombieDead + OnWeaponHitXp confirm the kill, we know the weapon category.
-- ============================================================================

local function onWeaponHitCharacter(wielder, victim, weapon, damage)
    if not wielder or not victim then return end
    if not instanceof(victim, "IsoZombie") then return end
    if not isLocalPlayer(wielder) then return end

    local key = tostring(victim)
    local cat = getWeaponCategory(weapon)
    local explosive = weapon and weapon.isInstantExplosion and weapon:isInstantExplosion() or false

    hitLog[key] = {
        category    = cat,
        ts          = now(),
        isExplosion = explosive,
    }
end

-- ============================================================================
-- EVENT: OnZombieDead
-- Fires when a zombie dies. May fire twice for fire kills (within 20s).
-- Also detects vehicle kills via action state + target checks.
-- ============================================================================

local function onZombieDead(zombie)
    if not zombie then return end
    local player = getSpecificPlayer(0)
    if not player then return end

    local key = tostring(zombie)
    local t   = now()
    local kd  = getKillData(player)

    -- Check for double-fire (fire kill): same zombie died twice within 20s
    if deadLog[key] and (t - deadLog[key]) < STALE_TIMEOUT then
        -- Fire kill confirmed
        kd.fire = kd.fire + 1
        -- Rollback vehicle if it was logged for this zombie
        if carLog[key] then
            kd.vehicle = math.max(0, kd.vehicle - 1)
            carLog[key] = nil
        end
        deadLog[key] = nil
        return
    end

    -- First death for this zombie — store timestamp for fire detection
    deadLog[key] = t

    -- Check vehicle kill: zombie on ground + target is player in vehicle
    if zombie.getActionStateName and zombie:getActionStateName() == "onground" then
        local target = zombie:getTarget()
        if target and instanceof(target, "IsoGameCharacter") then
            local vehicle = target:getVehicle()
            if vehicle and vehicle:getDriver() == player then
                kd.vehicle = kd.vehicle + 1
                carLog[key] = t
            end
        end
    end
end

-- ============================================================================
-- EVENT: OnWeaponHitXp
-- Fires when XP is awarded for a weapon kill — confirms the kill was by weapon.
-- This is the authoritative "weapon kill" signal.
-- ============================================================================

local function onWeaponHitXp(wielder, weapon, victim, damage)
    if not wielder or not victim then return end
    if not instanceof(victim, "IsoZombie") then return end
    if not isLocalPlayer(wielder) then return end

    local player = wielder
    local key = tostring(victim)
    local kd  = getKillData(player)
    local hit = hitLog[key]

    -- Rollback vehicle kill if this was actually a weapon kill
    if carLog[key] then
        kd.vehicle = math.max(0, kd.vehicle - 1)
        carLog[key] = nil
    end

    if hit then
        if hit.isExplosion then
            kd.explosion = kd.explosion + 1
        else
            local cat = hit.category or "Other"
            kd.weapon[cat] = (kd.weapon[cat] or 0) + 1
        end
        hitLog[key] = nil
    else
        -- No hit log (edge case) — use weapon directly
        local cat = getWeaponCategory(weapon)
        kd.weapon[cat] = (kd.weapon[cat] or 0) + 1
    end

    -- Clear dead log since this kill is accounted for
    deadLog[key] = nil
end

-- ============================================================================
-- PERIODIC CLEANUP — runs via OnTick throttled by frame counter
-- ============================================================================

local function onTick()
    frameCount = frameCount + 1
    if frameCount >= CLEANUP_EVERY then
        frameCount = 0
        clearStale(hitLog)
        clearStale(deadLog)
        clearStale(carLog)
    end
end

-- ============================================================================
-- INIT — register event hooks when the game starts
-- ============================================================================

local function onGameStart()
    Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
    Events.OnZombieDead.Add(onZombieDead)
    Events.OnWeaponHitXp.Add(onWeaponHitXp)
    Events.OnTick.Add(onTick)
end

Events.OnGameStart.Add(onGameStart)
