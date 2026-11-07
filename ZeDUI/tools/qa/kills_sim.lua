-- ZeDUI/tools/qa/kills_sim.lua  (Nov 7 2026, Build): the kill counts with no game running.
-- Loads the real KillTracker.lua and JournalTab.lua against Lua 5.1 stubs of the game and fires the
-- two events the tracker listens to (OnHitZombie, OnZombieDead) the way the 42.22.2 bytecode does:
--   a weapon kill: one hit, then one death
--   a fire kill: two deaths of a burning zombie (the burn's, then the body's); the burn clears the
--     zombie's attacker every tick before its death check (ReduceHealthWhenBurning), while a weapon,
--     bomb or car kill dies with the attacker set (IsoGameCharacter.Hit and Kill set it)
--   a bomb: IsoTrap.explosion hits each zombie with the bomb as the weapon and the thrower as the
--     wielder; on a multiplayer client a zombie another machine runs then takes a stand-in hit
--     from a new Base.Axe
-- The weapon stub's isInstantExplosion() is the bytecode's (no timer, no sensor, no remote: true),
-- so the old check would pass it for a bat; the tracker must not use it.
-- Also loads IdentityTab.lua: its kill count must be the Journal's total (KillTracker.total), and
-- an older save's rows are rebuilt from the game's own count at load.
-- And PostDeath.lua: the death record's kinds, like the Journal's rows, add up to the total, through
-- real kills on an older save whose fix waits on the game's count (it settles at death).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/kills_sim.lua
-- It prints FAIL lines and a last line "kills_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]kills_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the two files reach
-- ---------------------------------------------------------------------------
local events = setmetatable({}, { __index = function(self, name)
    local ev = { list = {} }
    function ev.Add(fn) ev.list[#ev.list + 1] = fn end
    function ev.Remove(fn)
        for i = #ev.list, 1, -1 do if ev.list[i] == fn then table.remove(ev.list, i) end end
    end
    function ev.fire(...) for _, fn in ipairs(ev.list) do fn(...) end end
    rawset(self, name, ev)
    return ev
end })
Events = events

local clock = 1000000
function getTimestampMs() return clock end
local function wait(ms) clock = clock + ms end

-- WeaponCategory constants: any distinct values do, the tracker only passes them back
WeaponCategory = {
    AXE = "AXE", BLUNT = "BLUNT", SPEAR = "SPEAR", LONG_BLADE = "LONG_BLADE",
    SMALL_BLADE = "SMALL_BLADE", SMALL_BLUNT = "SMALL_BLUNT", UNARMED = "UNARMED",
}

function instanceof(o, cls) return type(o) == "table" and o._is and o._is[cls] == true end

local P = { _is = { IsoGameCharacter = true }, md = {}, kills = 0 }
function P:getModData() return self.md end
function P:getZombieKills() return self.kills end
function P:getTimeSurvived() return "3 days" end
function P:getVehicle() return self.car end
function getSpecificPlayer(n) if n == 0 then return P end end

--- A HandWeapon of the game's shape. o: type, cats (WeaponCategory names), sub, power, range,
--- timer, sensor, remote, canRemote.
local function weapon(o)
    local w = {}
    function w:getType() return o.type end
    function w:getSubCategory() return o.sub or "" end
    function w:getScriptItem()
        return { containsWeaponCategory = function(_, c)
            for _, n in ipairs(o.cats or {}) do if n == c then return true end end
            return false
        end }
    end
    function w:getExplosionPower() return o.power or 0 end
    function w:getExplosionRange() return o.range or 0 end
    -- HandWeapon.isInstantExplosion, as the 42.22.2 bytecode reads
    function w:isInstantExplosion()
        return (o.timer or 0) <= 0 and (o.sensor or 0) <= 0 and (o.remote or -1) == -1 and not o.canRemote
    end
    return w
end

local BAT   = weapon({ type = "BaseballBat", cats = { "BLUNT" } })
local AXE   = weapon({ type = "Axe", cats = { "AXE" } })
local HANDS = weapon({ type = "BareHands", cats = { "UNARMED" } })
local PIPE  = weapon({ type = "PipeBomb", power = 90, range = 7 })   -- weapon.txt: ExplosionPower 90, ExplosionRange 7
local RING  = weapon({ type = "RangeOnly", range = 3 })              -- a modded bomb with range and no power

--- A zombie. id is its key; a reused object keeps it. onFire as IsoGameCharacter.isOnFire.
local function zombie(id, o)
    o = o or {}
    local z = { _is = { IsoZombie = true }, onFire = o.onFire, attackedBy = o.attackedBy, state = o.state }
    function z:getID() return id end
    if not o.noFireCall then
        function z:isOnFire() return self.onFire == true end
    end
    function z:getAttackedBy() return self.attackedBy end
    function z:getActionStateName() return self.state or "idle" end
    function z:getTarget() return self.target end
    return z
end

-- IsoGameCharacter.Hit fires OnHitZombie first, then sets the attacker
local function hit(z, w) events.OnHitZombie.fire(z, P, "Head", w); z.attackedBy = P end
local function dies(z) events.OnZombieDead.fire(z) end
-- the burn's death: ReduceHealthWhenBurning clears the attacker, then fires OnZombieDead
local function burns(z) z.attackedBy = nil; dies(z) end
local function kd() return P.md.ZeD_Kills end
local function fresh() P.md = {}; P.kills = 0 end

-- ---------------------------------------------------------------------------
-- LOAD the real files
-- ---------------------------------------------------------------------------
-- an older save (beta 6 and before): the weapon and explosion rows counted hits, not kills, and
-- the old explosion test filed every bat and gun hit under explosion; the game's count is 30
P.md.ZeD_Kills = { weapon = { Blunt = 2 }, fire = 1, vehicle = 4, explosion = 40 }
P.kills = 30
dofile(ROOT .. "42/media/lua/client/ZeD/KillTracker.lua")
events.OnGameStart.fire()
check("the tracker listens", #events.OnHitZombie.list == 1 and #events.OnZombieDead.list == 1)
check("old save: rebuilt at load, the game's count less car kills under Other", kd().weapon.Other == 26,
    kd().weapon.Other)
check("old save: its explosion row goes", kd().explosion == 0, kd().explosion)
check("old save: its hit-count weapon rows go", kd().weapon.Blunt == nil, kd().weapon.Blunt)
check("old save: fire and vehicle stay", kd().fire == 1 and kd().vehicle == 4)
check("old save: marked fixed", kd().v == 2, kd().v)

-- JournalTab and IdentityTab read ZeD.Atoms at load and require the drawing modules; none of that is under test
local realRequire = require
require = function() end
ZeD.Atoms = ZeD.Atoms or {}
ZeD.tr = function(k, a) return a ~= nil and (k .. ":" .. tostring(a)) or k end
ZeD.upper = string.upper
function getText(k) return k end
dofile(ROOT .. "42/media/lua/client/ZeD/JournalTab.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/IdentityTab.lua")
require = realRequire

-- what IdentityTab.gatherData reads off the player besides the kills: a plain, empty character
P._is.IsoPlayer = true
function P:getDescriptor()
    return { getSurname = function() return "Finnegan" end, getForename = function() return "Glen" end,
             getCharacterProfession = function() return nil end }
end
function P:getNutrition()
    local f = function() return false end
    return { getWeight = function() return 80 end, isIncWeightLot = f, isIncWeight = f, isDecWeight = f }
end
function P:isFemale() return false end
function P:getHumanVisual()
    return { getHairColor = function() return nil end, getHairModel = function() return "" end,
             getBeardModel = function() return "" end, getBodyHairIndex = function() return 0 end }
end
function P:getCharacterTraits() return { getKnownTraits = function() return nil end } end

--- The Identity tab's kill count and the Journal's total, as each tab gathers them.
local function bothTotals()
    return ZeD.IdentityTab.gatherData(P).zKills, ZeD.JournalTab.gatherData(P).totalKills
end
local id0, jr0 = bothTotals()
check("old save: the rows add up to the Journal's total", jr0 == 31 and kd().weapon.Other + kd().vehicle + kd().fire == jr0,
    jr0)
check("old save: the Identity tab shows the same", id0 == tostring(jr0), id0)

-- ---------------------------------------------------------------------------
section("weapon kills land under their weapon, not explosion")
-- ---------------------------------------------------------------------------
fresh()
check("the stub's isInstantExplosion is true for a bat, as the game's is", BAT:isInstantExplosion() == true)
local z = zombie(1)
hit(z, BAT); wait(400); dies(z)
check("a bat kill counts under Blunt", kd().weapon.Blunt == 1, kd().weapon.Blunt)
check("a bat kill is no explosion", kd().explosion == 0, kd().explosion)
z = zombie(2)
hit(z, HANDS); wait(400); dies(z)
check("a bare-hands kill counts under Unarmed", kd().weapon.Unarmed == 1)
z = zombie(3)
hit(z, AXE); wait(400); dies(z)
check("an axe kill counts under Axe", kd().weapon.Axe == 1)
check("still no explosion after three weapon kills", kd().explosion == 0, kd().explosion)

-- ---------------------------------------------------------------------------
section("real explosives count as explosion")
-- ---------------------------------------------------------------------------
fresh()
z = zombie(10)
hit(z, PIPE); dies(z)
check("a pipe bomb kill counts as explosion", kd().explosion == 1, kd().explosion)
check("and under no weapon", next(kd().weapon) == nil)
z = zombie(11)
hit(z, RING); dies(z)
check("explosion range alone is enough", kd().explosion == 2, kd().explosion)
-- multiplayer client: the bomb's hit, then at once the stand-in axe's
z = zombie(12)
hit(z, PIPE); wait(1); hit(z, AXE); wait(50); dies(z)
check("the stand-in axe hit right after a bomb's keeps the bomb", kd().explosion == 3 and kd().weapon.Axe == nil)
-- a real axe blow long after a bomb's hit is the axe's kill
z = zombie(13)
hit(z, PIPE); wait(1500); hit(z, AXE); wait(300); dies(z)
check("an axe blow a second after a bomb's hit is the axe's", kd().weapon.Axe == 1 and kd().explosion == 3)
-- a bomb after a bat: the bomb's
z = zombie(14)
hit(z, BAT); wait(100); hit(z, PIPE); dies(z)
check("a bomb after a bat is the bomb's", kd().explosion == 4 and kd().weapon.Blunt == nil)

-- ---------------------------------------------------------------------------
section("fire kills, and a reused zombie object")
-- ---------------------------------------------------------------------------
fresh()
-- a fire death: two deaths of a burning zombie, nobody's hit
z = zombie(20, { onFire = true })
burns(z); wait(3000); dies(z)
check("a burning zombie's two deaths are one fire kill", kd().fire == 1, kd().fire)
-- hit, then the fire takes it: the weapon credit at the first death is taken back
z = zombie(21, { onFire = true })
hit(z, BAT); wait(500); burns(z)
check("hit then burn: the bat counts at the first death", kd().weapon.Blunt == 1)
wait(4000); dies(z)
check("hit then burn: the second death makes it a fire kill", kd().fire == 2, kd().fire)
check("hit then burn: and takes the bat's credit back", kd().weapon.Blunt == nil, kd().weapon.Blunt)
-- a weapon kill, then the game reuses that zombie object (same key) for a zombie killed within 20 s
z = zombie(22)
hit(z, BAT); wait(400); dies(z)
check("first life: a bat kill", kd().weapon.Blunt == 1)
wait(5000)
local z2 = zombie(22)            -- the same key, a new zombie
hit(z2, AXE); wait(400); dies(z2)
check("reused object: its axe kill counts as an axe kill", kd().weapon.Axe == 1, kd().weapon.Axe)
check("reused object: no fire kill misfiled", kd().fire == 2, kd().fire)
check("reused object: the first life's bat kill stays", kd().weapon.Blunt == 1, kd().weapon.Blunt)
-- the same, when the second life dies with no hit of ours (someone else's kill)
wait(3000)
local z3 = zombie(22)
dies(z3)
check("reused object, no hit: no fire kill", kd().fire == 2, kd().fire)
-- a build without isOnFire keeps the old double-death rule
z = zombie(23, { noFireCall = true })
burns(z); wait(2000); dies(z)
check("no isOnFire call: two deaths still read as fire", kd().fire == 3, kd().fire)
-- a burning zombie killed by a bat (the bat's blow, not the burn): then the game reuses the object
z = zombie(24, { onFire = true })
hit(z, BAT); wait(300); dies(z)
check("burning, killed by a bat: the bat counts", kd().weapon.Blunt == 2, kd().weapon.Blunt)
wait(4000)
z2 = zombie(24)                  -- the same key, a new zombie, not burning
hit(z2, AXE); wait(300); dies(z2)
check("burning bat kill, reused object: no fire kill", kd().fire == 3, kd().fire)
check("burning bat kill, reused object: the axe kill counts", kd().weapon.Axe == 2, kd().weapon.Axe)
check("burning bat kill, reused object: the bat kill stays", kd().weapon.Blunt == 2, kd().weapon.Blunt)
-- a bat kill, then the game reuses the object for a zombie that burns to death within 20 s
z = zombie(25)
hit(z, BAT); wait(300); dies(z)
check("bat kill before a reused object burns: the bat counts", kd().weapon.Blunt == 3, kd().weapon.Blunt)
wait(2000)
z2 = zombie(25, { onFire = true })   -- the same key, a new zombie, on fire
burns(z2); wait(3000); dies(z2)
check("reused object burns: one fire kill", kd().fire == 4, kd().fire)
check("reused object burns: the first life's bat kill stays", kd().weapon.Blunt == 3, kd().weapon.Blunt)

-- ---------------------------------------------------------------------------
section("vehicle kills")
-- ---------------------------------------------------------------------------
fresh()
P.car = { getDriver = function() return P end }
z = zombie(30, { state = "onground" })
z.target = P
dies(z)
check("a zombie run down counts as a vehicle kill", kd().vehicle == 1)
P.car = nil
-- the game reuses that object for a zombie that burns to death within 20 s
wait(2000)
z = zombie(30, { onFire = true })   -- the same key, a new zombie, on fire
burns(z); wait(3000); dies(z)
check("reused object burns after a car kill: one fire kill", kd().fire == 1, kd().fire)
check("reused object burns after a car kill: the car kill stays", kd().vehicle == 1, kd().vehicle)

-- ---------------------------------------------------------------------------
section("the Journal's total: the game's count plus only what it leaves out")
-- ---------------------------------------------------------------------------
fresh()
-- the game's count holds weapon, vehicle and explosion kills; fire kills it leaves out
P.md.ZeD_Kills = { weapon = { Blunt = 5, Axe = 2 }, fire = 2, vehicle = 3, explosion = 1, v = 2 }
P.kills = 5 + 2 + 3 + 1
local data = ZeD.JournalTab.gatherData(P)
check("total = the game's count + fire", data.totalKills == 11 + 2, data.totalKills)
check("the breakdown rows stay", data.fireKills == 2 and data.carKills == 3 and data.explosionKills == 1)
local blunt
for _, c in ipairs(data.weaponCats) do if c.label == "IGUI_perks_Blunt" then blunt = c.count end end
check("the weapon rows stay", blunt == 5, blunt)
-- end to end: kills through the tracker, the game's count raised as the bytecode does
fresh()
local function engineKill(z, w) hit(z, w); wait(300); P.kills = P.kills + 1; dies(z) end   -- hitConsequences adds 1
engineKill(zombie(40), BAT)
engineKill(zombie(41), PIPE)
P.car = { getDriver = function() return P end }
local zc = zombie(42, { state = "onground" }); zc.target = P
P.kills = P.kills + 1; dies(zc)                                                            -- onHitByVehicleApplyDamage adds 1
P.car = nil
local zf = zombie(43, { onFire = true }); burns(zf); wait(2000); dies(zf)                   -- a fire death adds nothing
data = ZeD.JournalTab.gatherData(P)
check("four kills, four in the total", data.totalKills == 4, data.totalKills)
check("one of each", kd().weapon.Blunt == 1 and kd().explosion == 1 and kd().vehicle == 1 and kd().fire == 1)
check("a new kill table is born fixed: its bomb kill stays explosion", kd().v == 2 and kd().weapon.Other == nil)
-- the one-time fix runs once: a table already marked fixed (or seeded by QA with v = 2) keeps its rows
fresh()
P.md.ZeD_Kills = { weapon = { Other = 40 }, fire = 0, vehicle = 0, explosion = 2, v = 2 }
engineKill(zombie(50), BAT)
check("a fixed table is not fixed again: Other and explosion stay",
    kd().weapon.Other == 40 and kd().explosion == 2 and kd().weapon.Blunt == 1,
    tostring(kd().weapon.Other) .. " / " .. tostring(kd().explosion))

-- ---------------------------------------------------------------------------
section("the Identity tab's count is the Journal's total")
-- ---------------------------------------------------------------------------
fresh()
local id, jr = bothTotals()
check("no kill table, no kills: both 0", id == "0" and jr == 0, tostring(id) .. " / " .. tostring(jr))
P.kills = 12
id, jr = bothTotals()
check("no kill table: both the game's count", id == "12" and jr == 12, tostring(id) .. " / " .. tostring(jr))
P.md.ZeD_Kills = { weapon = { Blunt = 9 }, fire = 0, vehicle = 3, explosion = 0, v = 2 }
id, jr = bothTotals()
check("no fire kills: both the game's count", id == "12" and jr == 12, tostring(id) .. " / " .. tostring(jr))
P.md.ZeD_Kills.fire = 5
id, jr = bothTotals()
check("with fire kills: both the game's count + fire", id == "17" and jr == 17, tostring(id) .. " / " .. tostring(jr))
check("the shared total is what both show", ZeD.KillTracker.total(P) == 17, ZeD.KillTracker.total(P))
-- through the tracker: a bat kill (the game counts it) and a fire kill (it does not)
fresh()
engineKill(zombie(60), BAT)
local zb = zombie(61, { onFire = true }); burns(zb); wait(2000); dies(zb)
id, jr = bothTotals()
check("a bat kill and a fire kill: both 2", id == "2" and jr == 2, tostring(id) .. " / " .. tostring(jr))
-- the game's count cannot be read: the fire kills still show on both
local realGZK = P.getZombieKills
P.getZombieKills = function() error("no count") end
id, jr = bothTotals()
check("no game count: both the fire kills alone", id == "1" and jr == 1, tostring(id) .. " / " .. tostring(jr))
P.getZombieKills = realGZK
check("no player: a total of 0", ZeD.KillTracker.total(nil) == 0)

-- ---------------------------------------------------------------------------
section("an older save's rows, rebuilt from the game's count")
-- ---------------------------------------------------------------------------
-- beta 6a: kills, but bats, guns and thrown bombs under explosion, timed bombs under Other
fresh()
P.md.ZeD_Kills = { weapon = { Other = 3 }, fire = 2, vehicle = 1, explosion = 20 }
P.kills = 24
ZeD.KillTracker.data(P)
check("beta 6a table: Other = the game's count less car kills", kd().weapon.Other == 23 and kd().explosion == 0,
    tostring(kd().weapon.Other) .. " / " .. tostring(kd().explosion))
check("beta 6a table: fire and vehicle stay", kd().fire == 2 and kd().vehicle == 1)
id, jr = bothTotals()
check("beta 6a table: rows add up to the total both tabs show", jr == 26 and id == "26"
    and kd().weapon.Other + kd().vehicle + kd().fire == jr, tostring(id) .. " / " .. tostring(jr))
-- more car kills than the game's count holds (it counts every car kill): capped to it
fresh()
P.md.ZeD_Kills = { weapon = {}, fire = 0, vehicle = 9, explosion = 5 }
P.kills = 6
ZeD.KillTracker.data(P)
check("car kills past the game's count: capped to it", kd().vehicle == 6 and kd().weapon.Other == nil,
    tostring(kd().vehicle) .. " / " .. tostring(kd().weapon.Other))
-- the game's count cannot be read: the fix waits, and the rows shown are what the total holds (fire)
fresh()
P.md.ZeD_Kills = { weapon = { Blunt = 2 }, fire = 1, vehicle = 4, explosion = 40 }
P.getZombieKills = function() error("no count") end
local shown = ZeD.KillTracker.data(P)
check("no game count: the fix waits, the old rows kept for it", kd().v == nil and kd().weapon.Blunt == 2 and kd().explosion == 40)
check("no game count: the rows shown are the fire kills alone", shown.fire == 1 and shown.vehicle == 0
    and shown.explosion == 0 and next(shown.weapon) == nil and ZeD.KillTracker.total(P) == 1)
P.getZombieKills = realGZK
-- a count of 0 under old rows has not arrived yet: the fix waits, then runs
fresh()
P.md.ZeD_Kills = { weapon = {}, fire = 0, vehicle = 0, explosion = 7 }
ZeD.KillTracker.data(P)
check("count 0 under old rows: not fixed yet", kd().v == nil and kd().explosion == 7, kd().v)
P.kills = 8
ZeD.KillTracker.data(P)
check("then, once the count reads: fixed", kd().v == 2 and kd().weapon.Other == 8 and kd().explosion == 0,
    kd().weapon.Other)
-- an old table with nothing in it, on a character with no kills: it waits (the count may not have come), empty
fresh()
P.md.ZeD_Kills = { weapon = {}, fire = 0, vehicle = 0, explosion = 0 }
ZeD.KillTracker.data(P)
check("an empty old table, count 0: waits, empty", kd().v == nil and next(kd().weapon) == nil)
-- the mod added to a running save: no table, the game's count already 9; the kills before ZeD go under Other
fresh()
P.kills = 9
ZeD.KillTracker.data(P)
check("a character older than ZeD: the game's count so far under Other", kd().v == 2 and kd().weapon.Other == 9,
    kd().weapon.Other)

-- ---------------------------------------------------------------------------
section("a waiting fix, then real kills: the rows add up to the total, never one over")
-- ---------------------------------------------------------------------------
-- the death record's line, loaded from the real PostDeath.lua (vanilla's screen a bare table)
ISPostDeathUI = {}
ZeD.Safe = { on = function() return false end }
function getGameTime()
    local f = function() return 1 end
    return { getMonth = f, getDay = f, getYear = f, getHour = f, getTimeOfDay = f,
             getDeathString = function() return "survived" end, getGameModeText = function() return nil end }
end
function P:getPlayerNum() return 0 end
require = function() end
dofile(ROOT .. "42/media/lua/client/ZeD/Overrides/PostDeath.lua")
require = realRequire
check("the death record listens", ZeD.Death and ZeD.Death.capture ~= nil)

local OTHERW = weapon({ type = "Plank" })   -- no category: filed under Other

--- Every kill row the Journal lists, added up.
local function journalSum()
    local d = ZeD.JournalTab.gatherData(P)
    local n = d.fireKills + d.carKills + d.explosionKills
    for _, c in ipairs(d.weaponCats) do n = n + c.count end
    return n, d.totalKills
end
--- The death record: its kinds added up, and the number in its "You killed N zombies." line.
local function deathSums(direct)
    if direct then ZeD.Death.capture(P) else events.OnPlayerDeath.fire(P) end
    local rec = ZeD.Death.records[0]
    local n = 0
    for d in string.gmatch(rec.kills or "", "(%d+)") do n = n + tonumber(d) end
    local said
    for _, l in ipairs(rec.lines) do said = said or tonumber(string.match(l, "zombi[a-z]*Count:(%d+)")) end
    return n, said, rec.kills
end
local function sumsTo(name)
    local rows, total = journalSum()
    check(name .. ": the Journal's rows add up to its total", rows == total and total == ZeD.KillTracker.total(P),
        tostring(rows) .. " / " .. tostring(total))
end
-- an old table (hit counts) on a character whose count reads 0: the fix waits
local function oldSave() fresh(); P.md.ZeD_Kills = { weapon = { Blunt = 50 }, fire = 1, vehicle = 2, explosion = 30 } end

oldSave()
sumsTo("waiting")
check("waiting: the saved rows are kept for the fix", kd().v == nil and kd().weapon.Blunt == 50 and kd().explosion == 30)
-- the first kill: the game has counted it (0 -> 1) before OnZombieDead; the fix runs inside the handler
engineKill(zombie(70), BAT)
check("first kill fixes it: marked", kd().v == 2, kd().v)
check("first kill: counted once, under Blunt", kd().weapon.Blunt == 1 and kd().weapon.Other == nil,
    tostring(kd().weapon.Blunt) .. " / " .. tostring(kd().weapon.Other))
check("first kill: old car and explosion rows gone (the count held none)", kd().vehicle == 0 and kd().explosion == 0)
sumsTo("first kill after a wait")
engineKill(zombie(71), AXE)
sumsTo("second kill")
-- the count arrives (30) just before the first kill takes it to 31
oldSave()
P.kills = 30
engineKill(zombie(72), BAT)
check("count arrived: Other = the count before this kill less car kills", kd().weapon.Other == 28 and kd().vehicle == 2
    and kd().weapon.Blunt == 1, tostring(kd().weapon.Other) .. " / " .. tostring(kd().weapon.Blunt))
sumsTo("count arrived, then a kill")
-- the first kill a car's
oldSave()
P.car = { getDriver = function() return P end }
local zv = zombie(73, { state = "onground" }); zv.target = P
P.kills = P.kills + 1; dies(zv)
P.car = nil
check("first kill a car's: one car kill", kd().v == 2 and kd().vehicle == 1, kd().vehicle)
sumsTo("first kill a car's")
-- the first kill a bomb's
oldSave()
engineKill(zombie(74), PIPE)
check("first kill a bomb's: one explosion", kd().v == 2 and kd().explosion == 1 and next(kd().weapon) == nil, kd().explosion)
sumsTo("first kill a bomb's")
-- a fire kill while waiting: the game counts none, so the fix keeps waiting; fire adds up
oldSave()
local zw = zombie(75, { onFire = true }); burns(zw); wait(2000); dies(zw)
check("fire kill while waiting: still waiting, fire counted", kd().v == nil and kd().fire == 2, kd().fire)
sumsTo("fire kill while waiting")
-- hit then burn across the fix: the first death's credit went into the old rows; the count then
-- arrives and a reading fixes the table; the second death must not take that credit off the new rows
oldSave()
local zh = zombie(76, { onFire = true })
hit(zh, OTHERW); wait(300); burns(zh)
check("hit then burn, waiting: credited to the old rows", kd().v == nil and kd().weapon.Other == 1)
P.kills = 10
sumsTo("count arrives between the two deaths")
wait(3000); dies(zh)
check("hit then burn across the fix: Other keeps the count's 8", kd().weapon.Other == 8 and kd().fire == 2,
    tostring(kd().weapon.Other) .. " / " .. tostring(kd().fire))
sumsTo("hit then burn across the fix")
-- an old table fixed inside the handler (the count arrived well before, no reading in between)
fresh()
P.md.ZeD_Kills = { weapon = { Blunt = 3 }, fire = 0, vehicle = 0, explosion = 9 }
P.kills = 12
local zu = zombie(77); hit(zu, BAT); wait(300); P.kills = P.kills + 1; dies(zu)
check("old table fixed by a kill: Other 12, Blunt 1", kd().weapon.Other == 12 and kd().weapon.Blunt == 1,
    tostring(kd().weapon.Other) .. " / " .. tostring(kd().weapon.Blunt))
sumsTo("old table fixed by a kill")
-- a burning zombie's first death after our hit: the game did not count it (the burn cleared the attacker)
fresh()
P.md.ZeD_Kills = { weapon = { Blunt = 3 }, fire = 0, vehicle = 0, explosion = 9 }
P.kills = 12
local zq = zombie(78, { onFire = true }); hit(zq, BAT); wait(300); burns(zq)
check("a burn's first death fixes with nothing pending: Other 12", kd().v == 2 and kd().weapon.Other == 12,
    kd().weapon.Other)
wait(3000); dies(zq)
check("then the fire kill: the bat's credit taken back", kd().weapon.Blunt == nil and kd().fire == 1)
sumsTo("a burn's two deaths fixing an old table")

-- ---------------------------------------------------------------------------
section("the death record: a waiting fix settles")
-- ---------------------------------------------------------------------------
-- the count still 0 at death is the truth: the old rows were hits; fire stays, vehicle capped at 0
oldSave()
local n, said, line = deathSums()
check("death, count 0: settled", kd().v == 2, kd().v)
check("death, count 0: hit rows dropped, fire kept", next(kd().weapon) == nil and kd().explosion == 0
    and kd().vehicle == 0 and kd().fire == 1)
check("death, count 0: the kinds add up to the line's total", n == 1 and said == 1,
    tostring(n) .. " / " .. tostring(said) .. " " .. tostring(line))
-- the record alone settles it too (whatever order the death hooks run in)
oldSave()
n, said = deathSums(true)
check("the record's own reading settles it", kd().v == 2 and n == said and said == 1, tostring(n) .. " / " .. tostring(said))
-- after real kills, through a waited fix
oldSave()
engineKill(zombie(80), BAT)
engineKill(zombie(81), PIPE)
local zd = zombie(82, { onFire = true }); burns(zd); wait(2000); dies(zd)
n, said, line = deathSums()
check("death after kills: the kinds add up to the total", n == said and said == 4,
    tostring(n) .. " / " .. tostring(said) .. " " .. tostring(line))
-- a count that arrived: the record matches it
oldSave()
P.kills = 7
n, said = deathSums()
check("death, count 7: the kinds add up to the total", n == said and said == 8 and kd().weapon.Other == 5,
    tostring(n) .. " / " .. tostring(said))

print("kills_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
