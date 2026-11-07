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
--   Fire kill:   OnZombieDead fires twice within 20s for same zombie: once when
--                the burn takes its last health (the zombie is still on fire),
--                once more when the game lays the body down
--   Vehicle kill: OnZombieDead + zombie on ground + target in vehicle
--   Explosion:   a thrown or placed bomb hits each zombie in range with itself as
--                the weapon and its thrower as the wielder (IsoTrap.explosion), so
--                it arrives here like a weapon kill
--
-- The game's own count (getZombieKills) takes weapon, vehicle and explosion kills
-- already; a fire death clears the attacker, so only fire kills are missing from it.
-- ZeD.KillTracker.total(player) is that count plus the fire kills: the one total the
-- Identity tab, the Journal and the death record all show.
-- ============================================================================

ZeD = ZeD or {}
ZeD.KillTracker = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local STALE_TIMEOUT   = 20000  -- 20s max memory for hit/death tracking
local CLEANUP_EVERY   = 300    -- clean stale entries every 300 frames (~5s at 60fps)
local BOMB_HOLD       = 250    -- ms a bomb's hit outranks a plain hit on the same zombie
local KILLS_VERSION   = 2      -- ZeD_Kills.v: 2 = an older table's rows rebuilt from the game's count

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

--- True only for a real explosive (pipe bomb, aerosol bomb and the like).
-- Not isInstantExplosion(): that is true for any weapon with no timer, sensor or
-- remote, so a bat or bare hands pass it. Not isExplosive() either: 42.21 may not
-- have it. Both getters here return a whole number, 0 for a weapon that is no bomb.
local function isRealExplosive(weapon)
    if not weapon then return false end
    local power = weapon.getExplosionPower and weapon:getExplosionPower() or 0
    local range = weapon.getExplosionRange and weapon:getExplosionRange() or 0
    return power > 0 or range > 0
end

--- True when this death can be the first of a fire kill's two.
-- A fire kill's first death always comes from the burn itself (the game's
-- ReduceHealthWhenBurning). That runs only while the zombie is on fire, and it
-- clears the zombie's attacker on every tick just before it checks for death.
-- A weapon, bomb or car kill reaches OnZombieDead with the attacker still set
-- (the game's Kill sets it first), even when the zombie was burning.
-- A build without one of the calls skips that test (old behavior).
local function mayBeFireDeath(zombie)
    if zombie.isOnFire and not zombie:isOnFire() then return false end
    if zombie.getAttackedBy and zombie:getAttackedBy() ~= nil then return false end
    return true
end

--- The game's own kill count (getZombieKills), or nil when it cannot be read.
local function gameKills(playerObj)
    if not playerObj then return nil end
    local ok, n = pcall(function() return playerObj:getZombieKills() end)
    return ok and tonumber(n) or nil
end

--- One-time fix for kill tables saved before KILLS_VERSION.
-- Up to beta 6 the weapon and explosion rows counted hits, not kills (OnWeaponHitXp
-- fires on every hit), and bombs never reached them. Beta 6a counted kills, but its
-- explosion test passed any weapon with no timer, sensor or remote, so a bat, a gun
-- and a thrown pipe bomb all went under explosion, and a timed bomb under Other.
-- The table keeps only the sums, so no kill's weapon can be told now. The game's own
-- count is exact for every kill but fire, so the rows are rebuilt from it: fire stays,
-- vehicle stays (no more than the game's count, which holds car kills), and the rest
-- of the game's count goes under Other. The rows then add up to the total.
-- A count that cannot be read keeps the old sums, moved to Other. A count of 0 under
-- old rows may not have arrived yet (a server's player): the fix waits for the next call.
local function migrateKillData(kd, playerObj)
    if kd.v == KILLS_VERSION then return end
    local game = gameKills(playerObj)
    if game == nil then
        local old = kd.explosion or 0
        if old > 0 then kd.weapon.Other = (kd.weapon.Other or 0) + old end
    else
        local had = (kd.explosion or 0) + (kd.vehicle or 0)
        for _, n in pairs(kd.weapon) do had = had + (tonumber(n) or 0) end
        if game <= 0 and had > 0 then return end
        local veh = math.min(math.max(kd.vehicle or 0, 0), game)
        kd.vehicle = veh
        kd.weapon = {}
        if game - veh > 0 then kd.weapon.Other = game - veh end
    end
    kd.explosion = 0
    kd.v = KILLS_VERSION
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
            v         = KILLS_VERSION,  -- a new table needs no fixing
        }
    end
    if not md.ZeD_Kills.weapon then
        md.ZeD_Kills.weapon = {}
    end
    migrateKillData(md.ZeD_Kills, playerObj)
    return md.ZeD_Kills
end

--- The character's whole zombie kill count: the game's own count, which leaves out
-- only fire kills (the burn clears the attacker), plus the fire kills counted here.
-- The Identity tab, the Journal and the death record all show this one number.
function ZeD.KillTracker.total(playerObj)
    local n = gameKills(playerObj) or 0
    local md = playerObj and playerObj.getModData and playerObj:getModData()
    local zk = md and md.ZeD_Kills
    return n + ((zk and tonumber(zk.fire)) or 0)
end

--- The character's kill table, made if missing and fixed if old (QA and sims).
function ZeD.KillTracker.data(playerObj)
    if not playerObj then return nil end
    return getKillData(playerObj)
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
    local t   = now()
    local explosive = isRealExplosive(weapon)

    -- On a multiplayer client the game follows a bomb's hit on a zombie another
    -- machine runs with a stand-in hit from a new axe (IsoTrap.explosion). Keep the
    -- bomb: a plain hit a moment after a bomb's does not replace it.
    local prev = hitLog[key]
    if prev and prev.isExplosion and not explosive and (t - prev.ts) < BOMB_HOLD then return end

    hitLog[key] = {
        category    = getWeaponCategory(weapon),
        ts          = t,
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

    -- First death for this zombie: remember it for fire detection, but only when
    -- the burn itself killed it. The game reuses zombie objects, so a key kept
    -- after a weapon or car kill would make the next zombie with that key read as
    -- a fire kill. A hit then burn keeps it (the burn clears the attacker), so
    -- the weapon credit given just below rolls back at the second death.
    local fireMaybe = mayBeFireDeath(zombie)
    if fireMaybe then
        deadLog[key] = t
    else
        deadLog[key] = nil
    end

    -- Weapon kill: a recent hit of ours, unless the game names someone else as
    -- the killer (another player's blow, on a server). No such call: no veto.
    if hit and not hit.counted and (t - hit.ts) < STALE_TIMEOUT then
        local killer = zombie.getAttackedBy and zombie:getAttackedBy()
        if not killer or killer == player then
            tally(kd, hit, 1)
            if fireMaybe then
                hit.counted = true   -- kept until stale, for the fire rollback above
            else
                -- No second death can follow, so nothing to roll back. Forget the
                -- hit, or a reused object that burns to death within 20 s would
                -- take this real kill back off the rows.
                hitLog[key] = nil
            end
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
                -- kept only for a death that may be a burn's first, for the
                -- fire rollback above; same reason as the weapon kill
                if fireMaybe then carLog[key] = t end
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
    -- Fix an older save's kill table now, so the Journal shows it right before
    -- the first kill of this session (getKillData runs the one-time fix).
    local player = getSpecificPlayer(0)
    if player and player:getModData().ZeD_Kills then getKillData(player) end

    Events.OnHitZombie.Add(onHitZombie)
    Events.OnZombieDead.Add(onZombieDead)
    Events.OnTick.Add(onTick)
end

Events.OnGameStart.Add(onGameStart)
