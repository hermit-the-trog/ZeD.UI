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
-- Identity tab, the Journal and the death record all show. Their rows come from
-- ZeD.KillTracker.data(player), which runs an old save's one-time fix (or retries it)
-- and always adds up to that total.
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
-- Inside the kill handler the game has already counted the kill about to be tallied
-- (hitConsequences and onHitByVehicleApplyDamage add 1 before OnZombieDead), so that
-- kill (pending) comes off the count first: the tally adds it back to its own row.
-- A count of 0 (or none) may not have arrived yet (a server's player): the fix waits,
-- retried by every reading and every kill, and the readers get a copy rebuilt from
-- the count as it stands. A kill the game has counted proves the count is there, so
-- the fix inside the kill handler never waits. At death it settles on whatever the
-- count is; a count still 0 then is the truth: the old weapon and explosion rows were
-- hits and go, fire stays, and vehicle is capped at the count like any other time.
-- No path leaves hit-count rows under a total they exceed.
local fixEpoch = 0   -- one more each time a table is rebuilt: a credit given before it is not taken back after

--- The rows rebuilt from base (the game's count less the kill not yet tallied).
local function rebuildRows(kd, base)
    local veh = math.min(math.max(tonumber(kd.vehicle) or 0, 0), base)
    kd.vehicle = veh
    kd.weapon = {}
    if base - veh > 0 then kd.weapon.Other = base - veh end
    kd.explosion = 0
end

local function migrateKillData(kd, playerObj, pending, settle)
    if kd.v == KILLS_VERSION then return end
    local game = gameKills(playerObj) or 0
    if game <= 0 and not settle then return end
    rebuildRows(kd, math.max(game - (pending or 0), 0))
    kd.v = KILLS_VERSION
    fixEpoch = fixEpoch + 1
end

--- Ensure modData structure exists, fix it if old, and return it.
-- pending: kills the game has counted that the caller is about to tally (0 or 1);
-- settle: the fix may not wait any longer (death).
local function getKillData(playerObj, pending, settle)
    local md = playerObj:getModData()
    if not md.ZeD_Kills then
        -- left unmarked, so the fix below fills it at once: on a character older than
        -- ZeD (the mod added to a running save) the game's count so far goes under
        -- Other, and the rows add up to the total from the start
        md.ZeD_Kills = { weapon = {}, fire = 0, vehicle = 0, explosion = 0 }
    end
    local kd = md.ZeD_Kills
    if not kd.weapon then kd.weapon = {} end
    kd.fire      = tonumber(kd.fire) or 0
    kd.vehicle   = tonumber(kd.vehicle) or 0
    kd.explosion = tonumber(kd.explosion) or 0
    migrateKillData(kd, playerObj, pending, settle)
    return kd
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

--- The character's kill rows, for every reader (the Journal, the death record, QA).
-- Makes the table if missing and runs (or retries) the one-time fix. While the fix
-- waits, this is a copy rebuilt from the count as it stands, so its rows add up to
-- total(); write to it only when its v is KILLS_VERSION. settle: the fix may not wait.
function ZeD.KillTracker.data(playerObj, settle)
    if not playerObj then return nil end
    local kd = getKillData(playerObj, 0, settle)
    if kd.v == KILLS_VERSION then return kd end
    local view = { fire = kd.fire, vehicle = kd.vehicle }
    rebuildRows(view, gameKills(playerObj) or 0)
    return view
end

--- At death: the fix runs on whatever the count is (the death record's reading).
function ZeD.KillTracker.settle(playerObj)
    return ZeD.KillTracker.data(playerObj, true)
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
    local hit = hitLog[key]

    -- The kill table is fetched only once this death's kind is known: an old table's
    -- fix, run here, takes the kill the game has already counted off its count
    -- (getKillData's pending), since the tally below adds it to its own row.

    -- Check for double-fire (fire kill): same zombie died twice within 20s
    if deadLog[key] and (t - deadLog[key]) < STALE_TIMEOUT then
        -- Fire kill confirmed (the game counts no fire kill: nothing pending)
        local kd = getKillData(player, 0)
        kd.fire = kd.fire + 1
        -- Take back a car or weapon credit given at the first death (one zombie
        -- counts once), unless the table was rebuilt since: the credit went with it
        local car = carLog[key]
        if car and car.epoch == fixEpoch then
            kd.vehicle = math.max(0, kd.vehicle - 1)
        end
        carLog[key] = nil
        if hit and hit.counted == fixEpoch then tally(kd, hit, -1) end
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
            -- the game counted it when we are the attacker (or no call can say), and
            -- for a death with no attacker that is not burning (a server client's
            -- late attacker); a burn's first death clears the attacker and counts none
            local counted = (killer == player or not zombie.getAttackedBy or not fireMaybe) and 1 or 0
            local kd = getKillData(player, counted)
            tally(kd, hit, 1)
            if fireMaybe then
                hit.counted = fixEpoch   -- kept until stale, for the fire rollback above
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
                -- onHitByVehicleApplyDamage has counted it: one pending; a burning
                -- zombie on the ground that dies here with no attacker died of the burn,
                -- which the game does not count (review, Nov 7)
                local kd = getKillData(player, fireMaybe and 0 or 1)
                kd.vehicle = kd.vehicle + 1
                -- kept only for a death that may be a burn's first, for the
                -- fire rollback above; same reason as the weapon kill
                if fireMaybe then carLog[key] = { ts = t, epoch = fixEpoch } end
                return
            end
        end
    end

    -- Not ours: nothing to tally, but the table is made (and an old one's fix retried)
    getKillData(player, 0)
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
    if player then getKillData(player, 0) end

    Events.OnHitZombie.Add(onHitZombie)
    Events.OnZombieDead.Add(onZombieDead)
    Events.OnTick.Add(onTick)
    -- an old table's fix still waiting settles at death (the death record settles it too)
    Events.OnPlayerDeath.Add(function(p)
        if isLocalPlayer(p) then pcall(ZeD.KillTracker.settle, p) end
    end)
end

Events.OnGameStart.Add(onGameStart)
