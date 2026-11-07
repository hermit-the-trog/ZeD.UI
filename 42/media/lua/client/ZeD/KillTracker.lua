-- ZeD-UI/42/media/lua/client/ZeD/KillTracker.lua
-- ============================================================================
-- KILL TRACKER — native kill categorization via PZ event hooks.
-- Tracks weapon category, fire, vehicle, and explosion kills.
--
-- Stores persistent data in player:getModData().ZeD_Kills.
-- No external mod dependencies — uses vanilla PZ events only.
--
-- Event flow:
--   Weapon kill: OnHitZombie → OnZombieDead. OnHitZombie runs at the top of the
--                game's Hit on single player and on a multiplayer client alike.
--                Alone, the game kills inside that same Hit; on a client the death
--                arrives from the server a moment later (a local server runs no
--                client Lua and has no player 0, so it counts nothing here).
--                OnWeaponHitXp is no use: it fires per hit, and never on a client.
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

local hitLog    = {}  -- zombie key → {category, ts, isExplosion, counted}
local deadLog   = {}  -- zombie key → first OnZombieDead timestamp
local carLog    = {}  -- zombie key → timestamp (pending vehicle kill)
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

-- One zombie's key across its hits and its death. Not tostring alone: that string
-- carries the Crawling and CanWalk flags, which a hit can change.
local function zombieKey(zombie)
    return zombie.getID and zombie:getID() or tostring(zombie)
end

-- WeaponCategory constant -> the name kept in ZeD_Kills.weapon (JournalTab reads these keys).
-- The script item's getWeaponCategories() is an unordered Set, so each one is asked about in turn.
-- Improvised stays out, as it always has: it says nothing about the skill. In the game's own
-- items it only ever comes with one other category, so this order decides nothing there; a
-- modded weapon in two lands in the first, in the order vanilla's XP code asks.
local WEAPON_CATS = {
    { java = "AXE",         key = "Axe" },
    { java = "BLUNT",       key = "Blunt" },
    { java = "SPEAR",       key = "Spear" },
    { java = "LONG_BLADE",  key = "LongBlade" },
    { java = "SMALL_BLADE", key = "SmallBlade" },
    { java = "SMALL_BLUNT", key = "SmallBlunt" },
    { java = "UNARMED",     key = "Unarmed" },
}

--- Get weapon category from a HandWeapon.
-- Special-cases BareHands, asks the script item as vanilla's XP code does, then falls
-- back to getSubCategory() for firearms. A build without one of these names lands on
-- the fallback instead of raising an error on every hit.
local function getWeaponCategory(weapon)
    if not weapon then return "Other" end

    local wtype = weapon:getType()
    if wtype == "BareHands" then return "Unarmed" end

    local script = weapon.getScriptItem and weapon:getScriptItem()
    if WeaponCategory and script and script.containsWeaponCategory then
        for _, def in ipairs(WEAPON_CATS) do
            local cat = WeaponCategory[def.java]
            if cat and script:containsWeaponCategory(cat) then return def.key end
        end
    end

    -- (only names the journal shows: Swinging and Stab would hide an Improvised-only kill)
    local sub = weapon.getSubCategory and weapon:getSubCategory()
    if sub == "Firearm" or sub == "Spear" then return sub end

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

--- Add a logged hit to the tally, or take it back off (delta -1).
local function tally(kd, hit, delta)
    if hit.isExplosion then
        kd.explosion = math.max(0, kd.explosion + delta)
    else
        local cat = hit.category or "Other"
        local n = (kd.weapon[cat] or 0) + delta
        kd.weapon[cat] = n > 0 and n or nil
    end
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
-- EVENT: OnHitZombie
-- Fires on every weapon hit (killing or not). We log the hit so that when
-- OnZombieDead confirms the kill, we know the weapon category.
-- ============================================================================

local function onHitZombie(victim, wielder, bodyPart, weapon)
    if not wielder or not victim then return end
    if not isLocalPlayer(wielder) then return end

    local key = zombieKey(victim)
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
-- The player's last hit, if recent, names the weapon. Also detects vehicle
-- kills via action state + target checks.
-- ============================================================================

local function onZombieDead(zombie)
    if not zombie then return end
    local player = getSpecificPlayer(0)
    if not player then return end

    local key = zombieKey(zombie)
    local t   = now()
    local kd  = getKillData(player)
    local hit = hitLog[key]

    -- Check for double-fire (fire kill): same zombie died twice within 20s
    if deadLog[key] and (t - deadLog[key]) < STALE_TIMEOUT then
        -- Fire kill confirmed
        kd.fire = kd.fire + 1
        -- Rollback vehicle if it was logged for this zombie
        if carLog[key] then
            kd.vehicle = math.max(0, kd.vehicle - 1)
            carLog[key] = nil
        end
        -- Likewise a weapon credited at the first death: one zombie counts once
        if hit and hit.counted then tally(kd, hit, -1) end
        hitLog[key] = nil
        deadLog[key] = nil
        return
    end

    -- First death for this zombie — store timestamp for fire detection
    deadLog[key] = t

    -- Weapon kill: a recent hit of ours, unless the game names someone else as
    -- the killer (another player's blow, on a server). No such call: no veto.
    if hit and not hit.counted and (t - hit.ts) < STALE_TIMEOUT then
        local killer = zombie.getAttackedBy and zombie:getAttackedBy()
        if not killer or killer == player then
            tally(kd, hit, 1)
            hit.counted = true   -- kept until stale, for the fire rollback above
            return
        end
    end

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
    Events.OnHitZombie.Add(onHitZombie)
    Events.OnZombieDead.Add(onZombieDead)
    Events.OnTick.Add(onTick)
end

Events.OnGameStart.Add(onGameStart)
