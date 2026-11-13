-- ZeDUI/tools/qa/perf_throttles_sim.lua  (Nov 7 2026, Build): the outside performance review's #12 and #15 in the
-- files Build owns (ZeDUI/qa/REVIEW_PERF_20261107.md), with no game running. Each part runs the real code (the whole
-- file on Lua 5.1 stubs, or the lines cut out of it) beside the code before the change (git show BASE), on a clock
-- the sim moves frame by frame, and counts the calls.
--   HEALTH    gatherData gives exactly the old data for 400 made-up bodies (every flag, five First Aid levels, the
--             cheat), with fewer getter calls on the body parts
--   CLOCK     Health, Skills (data and training) and Equipment (both) refresh on the clock: the same count a
--             second at 30, 60, 144 and 240 FPS (250 ms / 500 ms, as 15 / 30 frames were at 60), where the old frame
--             counts ran 2.4 and 4 times as often at 144 and 240; a dropped cache refreshes on that frame and the
--             period starts again; two windows opened on the same frame don't refresh on the same frames
--   TRAINING  the training section's walk of the inventory and books runs only while some of it is in the scroll
--             view, and on the first frame it comes back into view when due
--   CARDS     an object card's data refresh and nearby scan: 250 ms and 1 s at any frame rate; the kinds' "now" and
--             "in three" keep their meaning; the scan doesn't run in step with the refresh
--   EQUIP     a slot with layers shows its outermost item (a jacket over a sweater: the jacket), as the doll does;
--             the old tab showed the innermost
--   PINS      the title bar's pin words are the old ones for every kind of pin, and P.stats makes no closure
--   FLYERS    the places marked as visited are the old ones, from rectangles worked out once
--   COOKING   the ingredient groups are sorted when the list or the sort changes, not every frame, in the same order
-- What it can't show: frame times in the game (suite_perf.lua in game), the tabs' drawing.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/perf_throttles_sim.lua
-- It prints FAIL lines and a last line "perf_throttles_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]perf_throttles_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local BASE = "7f17686e"   -- main when this work started

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function note(s) print("   " .. s) end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))   -- (the cuts below match LF line ends)
end
local function baseFile(name)
    local p = io.popen('git -C "' .. (ROOT ~= "" and ROOT or ".") .. '" show ' .. BASE .. ':42/media/lua/client/ZeD/' .. name .. ' 2>NUL')
    local s = p and p:read("*a") or ""
    if p then p:close() end
    return s ~= "" and (s:gsub("\r\n", "\n")) or nil
end
-- the text from the first `from` (plain, searched from init) to the end of the line where the first `to` after it is
local function cut(src, from, to, init)
    local a = string.find(src, from, init or 1, true)
    if not a then return nil end
    local b = string.find(src, to, a + #from, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src
    return string.sub(src, a, e)
end
local function run(src, name, env)
    local f, err = loadstring(src, "=" .. name)
    assert(f, err)
    if env then setfenv(f, setmetatable(env, { __index = _G })) end
    return f()
end

-- deep equality (functions and userdata-like tables by identity)
local function same(a, b, seen)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    seen = seen or {}
    if seen[a] == b then return true end
    seen[a] = b
    for k, v in pairs(a) do if not same(v, b[k], seen) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

-- the clock the sim moves
local CLOCK = 1.7e12   -- past 2^31, as the game's
getTimestampMs = function() return math.floor(CLOCK) end

-- ---------------------------------------------------------------------------
-- The game, as stubs
-- ---------------------------------------------------------------------------
require = function() end
Events = setmetatable({}, { __index = function(t, k)
    local e = { fns = {} }
    e.Add = function(f) e.fns[#e.fns + 1] = f end
    e.Remove = function() end
    rawset(t, k, e)
    return e
end })
getText = function(k) return "T:" .. tostring(k) end
getTextOrNull = function(k) return nil end
getTexture = function(n) return { name = n } end
instanceof = function(o, c) return type(o) == "table" and o._class == c end
Perks = { Doctor = "Doctor", Cooking = "Cooking" }
ISHealthPanel = { cheat = false }
local PARTS = { "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin", "UpperArm_L", "UpperArm_R", "ForeArm_L",
    "ForeArm_R", "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }
BodyPartType = { getDisplayName = function(t) return "Part " .. tostring(t) end, ToString = function(t) return tostring(t) end }
for _, n in ipairs(PARTS) do BodyPartType[n] = n end
local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
    isEmpty = function() return #t == 0 end, contains = function(_, v) for _, x in ipairs(t) do if x == v then return true end end return false end } end

local function installZeD()
    ZeD = { T = { px = function(n) return n end, sp = {}, positive = "pos", warning = "warn", danger = "dng",
                  accent = "acc", info = "inf" } }
    ZeD.tr = function(k, ...)
        local s = "Z:" .. k
        for i = 1, select("#", ...) do s = s .. "|" .. tostring((select(i, ...))) end
        return s
    end
    ZeD.logOnce = function() end
    ZeD.textCase = function(s) return s end
    ZeD.Atoms = { safeGet = function(o, m, ...)
        local f = o and o[m]
        if not f then return nil end
        local ok, r = pcall(f, o, ...)
        if ok then return r end
        return nil
    end }
    ZeD_BodyFigure = {}
end

-- ---------------------------------------------------------------------------
-- HEALTH: the data, and the getters it costs
-- ---------------------------------------------------------------------------
section("HEALTH (gatherData: the old data, fewer getter calls)")
local CALLS = 0
local function countingPart(state)
    -- every method a call: the state's value (a getter) or flag
    return setmetatable({}, { __index = function(_, k)
        return function()
            CALLS = CALLS + 1
            local v = state[k]
            if v == nil then return 0 end
            return v
        end
    end })
end
local seed = 12345
local function rnd(n) seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n end
local function newBody()
    local parts = {}
    for i, n in ipairs(PARTS) do
        local s = {
            getType = n, getHealth = (rnd(4) == 0) and rnd(100) or 100,
            bitten = rnd(12) == 0, bleeding = rnd(6) == 0, deepWounded = rnd(5) == 0, getDeepWoundTime = rnd(14),
            isInfectedWound = rnd(6) == 0, getWoundInfectionLevel = rnd(10) / 10,
            getFractureTime = (rnd(4) == 0) and rnd(70) or 0, getSplintFactor = (rnd(3) == 0) and rnd(7) or 0,
            haveBullet = rnd(9) == 0, haveGlass = rnd(9) == 0,
            scratched = rnd(4) == 0, getScratchTime = rnd(20), isCut = rnd(4) == 0, getCutTime = rnd(20),
            getBurnTime = (rnd(6) == 0) and rnd(30) or 0, isNeedBurnWash = rnd(2) == 0,
            getStiffness = (rnd(3) == 0) and rnd(60) or 0, getAdditionalPain = (rnd(3) == 0) and rnd(80) or 0,
            bandaged = rnd(4) == 0, getBandageLife = rnd(3), stitched = rnd(6) == 0, getStitchTime = rnd(60),
            getPlantainFactor = rnd(8) == 0 and 1 or 0, getComfreyFactor = rnd(8) == 0 and 1 or 0,
            getGarlicFactor = rnd(8) == 0 and 1 or 0,
        }
        parts[i] = countingPart(s)
    end
    local list = jlist(parts)
    return { getBodyParts = function() return list end, getOverallBodyHealth = function() return 77 end }
end
local function newPlayer(body, doc)
    return { getBodyDamage = function() return body end, getPerkLevel = function() return doc end,
             isFemale = function() return false end }
end

local healthNew = readFile(Z .. "HealthTab.lua")
local healthOld = baseFile("HealthTab.lua")
check("HEALTH: the base file (git show " .. BASE .. ")", healthOld ~= nil)
installZeD()
run(healthOld, "HealthTab@base")
local oldGather = ZeD.HealthTab.gatherData
installZeD()
run(healthNew, "HealthTab")
local newGather = ZeD.HealthTab.gatherData
local NewHealth = ZeD.HealthTab
local oldCalls, newCalls, bodies, diffs, conds = 0, 0, 0, 0, 0
for b = 1, 400 do
    local body = newBody()
    local doc = ({ 0, 3, 5, 7, 9 })[b % 5 + 1]
    ISHealthPanel.cheat = (b % 7 == 0)
    local p = newPlayer(body, doc)
    CALLS = 0
    local a = oldGather(p)
    oldCalls = oldCalls + CALLS
    CALLS = 0
    local c = newGather(p)
    newCalls = newCalls + CALLS
    -- a second read of the same body: the same again (the cached figure lookup)
    local c2 = newGather(p)
    bodies = bodies + 1
    for _, e in ipairs(c.entries) do conds = conds + #e.conditions end
    if not (same(a, c) and same(c, c2)) then diffs = diffs + 1 end
end
ISHealthPanel.cheat = false
check("HEALTH: the same data for every body", diffs == 0, diffs .. " of " .. bodies .. " differ")
check("HEALTH: fewer getter calls", newCalls < oldCalls, oldCalls .. " -> " .. newCalls)
check("HEALTH: the bodies hold conditions to compare (over 2,000 tags)", conds > 2000, conds)
-- the sim tells a change apart: a wrong word on a splinted fracture shows as a difference
do
    local broken = healthNew:gsub('elseif fractureT > 2 then word = getText%("IGUI_health_Moderate"%)',
        'elseif fractureT > 2 then word = getText("IGUI_health_Good")')
    installZeD()
    run(broken, "HealthTab@broken")
    local badGather = ZeD.HealthTab.gatherData
    seed = 12345
    local d = 0
    for b = 1, 400 do
        local body = newBody()
        local doc = ({ 0, 3, 5, 7, 9 })[b % 5 + 1]
        ISHealthPanel.cheat = (b % 7 == 0)
        local p = newPlayer(body, doc)
        if not same(oldGather(p), badGather(p)) then d = d + 1 end
    end
    ISHealthPanel.cheat = false
    check("HEALTH: a changed rule shows as a difference (the check is not blind)", d > 0, d)
end
note(string.format("body-part getter calls per refresh (17 parts): %.1f -> %.1f", oldCalls / 400, newCalls / 400))

-- ---------------------------------------------------------------------------
-- CLOCK: the tabs' refreshes per second at any frame rate
-- ---------------------------------------------------------------------------
section("CLOCK (Health, Skills, Equipment: on the clock, not frames drawn)")
local skillsNew = readFile(Z .. "SkillsTab.lua")
local equipNew = readFile(Z .. "EquipmentTab.lua")
local skillsOld, equipOld = baseFile("SkillsTab.lua"), baseFile("EquipmentTab.lua")
local DUE_FROM, DUE_TO = "local function dueMs(owner, key, periodMs, force)", "    return true\nend"
local dueH = cut(healthNew, DUE_FROM, DUE_TO)
local dueS = cut(skillsNew, DUE_FROM, DUE_TO)
local dueE = cut(equipNew, DUE_FROM, DUE_TO)
check("CLOCK: dueMs is in all three tabs", dueH and dueS and dueE)
check("CLOCK: the three copies are the same", dueH == dueS and dueS == dueE)
check("CLOCK: no % on the clock", dueH and not dueH:find("%", 1, true))

-- a throttle block cut from a file, run as function(win, gather) with the file's dueMs (or none, the old blocks)
local function block(src, from, to, gatherName, withDue)
    local text = cut(src, from, to)
    if not text then return nil end
    text = text:gsub("ZeD%.[%w]+%.gather[%w]+%(win%._playerObj%)", "GATHER()")
    local body = (withDue and (dueH .. "\n") or "") .. "return function(win, GATHER)\n" .. text .. "\nend"
    local env = { ZeD = { }, getTimestampMs = function() return math.floor(CLOCK) end }
    return run(body, gatherName, env)
end
local BLOCKS = {
    { "Health", healthNew, healthOld, 'if dueMs(win, "_healthAt"', "    win._healthTimer = (win._healthTimer or 0) + 1", 250 },
    { "Skills", skillsNew, skillsOld, 'if dueMs(win, "_skillsAt"', "    win._skillsTimer = (win._skillsTimer or 0) + 1", 250 },
    { "Equipment", equipNew, equipOld, 'if dueMs(win, "_equipAt"', "    win._equipTimer = (win._equipTimer or 0) + 1", 250 },
    { "Protection", equipNew, equipOld, 'if dueMs(win, "_equipProtAt"', "    win._equipProtTimer = (win._equipProtTimer or 0) + 1", 250 },
}
local function cacheKey(newFrom)
    return newFrom:match("_(%a+)At") == "health" and "_healthCache" or newFrom:match("_(%a+)At") == "skills" and "_skillsCache"
        or newFrom:match("_(%a+)At") == "equip" and "_equipCache" or "_equipProtCache"
end
local function frames(fps, secs, fn)
    local dt = 1000 / fps
    for _ = 1, math.floor(fps * secs) do CLOCK = CLOCK + dt; fn() end
end
for _, b in ipairs(BLOCKS) do
    local name, nsrc, osrc, nfrom, ofrom, period = b[1], b[2], b[3], b[4], b[5], b[6]
    local nfn = block(nsrc, nfrom, "    end", name, true)
    local ofn = block(osrc, ofrom, "    end", name .. "@base", false)
    check(name .. ": the blocks cut", nfn and ofn)
    if nfn and ofn then
        local ck = cacheKey(nfrom)
        local row = {}
        for _, fps in ipairs({ 30, 60, 144, 240 }) do
            local wn, wo, n, o = {}, {}, 0, 0
            frames(fps, 10, function()
                nfn(wn, function() n = n + 1; return {} end)
                ofn(wo, function() o = o + 1; return {} end)
                -- (the block stores the data in the cache itself: the GATHER result)
            end)
            row[#row + 1] = fps .. " FPS " .. o .. " -> " .. n
            check(name .. " at " .. fps .. " FPS: 41 refreshes in 10 s (one at once, then every " .. period .. " ms)",
                n >= 40 and n <= 41, n)
            if fps == 60 then check(name .. " at 60 FPS: as the old frame count", math.abs(n - o) <= 1, o .. " vs " .. n) end
            if fps == 240 then check(name .. " at 240 FPS: the old count ran 4 times as often", o >= 4 * (n - 1), o) end
        end
        note(name .. " refreshes in 10 s, old -> new: " .. table.concat(row, ", "))
        -- a dropped cache: refreshed on that frame, then the whole period again
        local w, n = {}, 0
        local g = function() n = n + 1; return {} end
        frames(60, 1, function() nfn(w, g) end)
        local before = n
        CLOCK = CLOCK + 16
        w[ck] = nil
        nfn(w, g)
        check(name .. ": a dropped cache refreshes on that frame", n == before + 1)
        local at = n
        local t0 = CLOCK
        while n == at and CLOCK - t0 < 2000 do CLOCK = CLOCK + 1; nfn(w, g) end
        check(name .. ": then the whole period again", CLOCK - t0 >= period - 1 and CLOCK - t0 <= period + 1, CLOCK - t0)
    end
end
-- two windows opened on the same frame (the shared phase counter): their second refreshes fall on different frames
do
    local nfn = block(healthNew, 'if dueMs(win, "_healthAt"', "    end", "Health2", true)
    local w1, w2, f1, f2 = {}, {}, {}, {}
    local frame = 0
    frames(144, 2, function()
        frame = frame + 1
        nfn(w1, function() f1[#f1 + 1] = frame; return {} end)
        nfn(w2, function() f2[#f2 + 1] = frame; return {} end)
    end)
    check("CLOCK: two windows refresh on their first frame", f1[1] == 1 and f2[1] == 1)
    local together = 0
    local s2 = {}
    for i = 2, #f2 do s2[f2[i]] = true end
    for i = 2, #f1 do if s2[f1[i]] then together = together + 1 end end
    check("CLOCK: two windows opened together don't refresh together after", together == 0, together)
    check("CLOCK: each window has its own phase", w1._zedPhase and w2._zedPhase and w1._zedPhase ~= w2._zedPhase)
end

-- ---------------------------------------------------------------------------
-- TRAINING: the walk only while the section shows
-- ---------------------------------------------------------------------------
section("TRAINING (the books' walk only while the section is in view)")
do
    local top = cut(skillsNew, "    if not win._trainingCache then", "    end")
    local gate = cut(skillsNew, "    if trainingStartY < scrollY + scrollH", "    end")
    check("TRAINING: the blocks cut", top and gate)
    local src = dueH .. "\nreturn function(win, trainingStartY, trainingH, scrollY, scrollH, GATHER)\n"
        .. (top or ""):gsub("ZeD%.SkillsTab%.gatherTrainingData%(win%._playerObj%)", "GATHER()")
        .. "    local training = win._trainingCache\n"
        .. (gate or ""):gsub("ZeD%.SkillsTab%.gatherTrainingData%(win%._playerObj%)", "GATHER()")
        .. "    return training\nend"
    local fn = run(src, "SkillsTraining", { ZeD = {} })
    local w, n = {}, 0
    local data = 0
    local g = function() n = n + 1; data = data + 1; return { stamp = data } end
    -- in view (the grid folded: the section right under the header)
    frames(60, 10, function() fn(w, 100, 300, 50, 400, g) end)
    check("TRAINING in view: every 500 ms (21 in 10 s)", n >= 20 and n <= 21, n)
    -- scrolled away below the view
    local hidden0 = n
    frames(60, 10, function() fn(w, 900, 300, 50, 400, g) end)
    check("TRAINING below the view: no walk", n == hidden0, n - hidden0)
    -- scrolled away above
    frames(60, 3, function() fn(w, -400, 300, 50, 400, g) end)
    check("TRAINING above the view: no walk", n == hidden0, n - hidden0)
    -- back in view: the walk on that very frame, and the rows drawn are the new ones
    CLOCK = CLOCK + 16
    local shown = fn(w, 300, 300, 50, 400, g)
    check("TRAINING back in view: fresh on the first frame", n == hidden0 + 1 and shown and shown.stamp == data)
    -- half in view (its top row under the bottom of the view)
    CLOCK = CLOCK + 600
    fn(w, 440, 300, 50, 400, g)
    check("TRAINING partly in view: walked", n == hidden0 + 2)
    -- a dropped cache (a tab switch): gathered at the top, for the measure
    w._trainingCache = nil
    CLOCK = CLOCK + 16
    fn(w, 900, 300, 50, 400, g)
    check("TRAINING dropped cache: gathered even out of view (the measure needs it)", n == hidden0 + 3)
    note("training walks in 10 s: in view " .. hidden0 .. ", scrolled away 0 (old: 20 at 60 FPS, 80 at 240, in view or not)")
end

-- ---------------------------------------------------------------------------
-- CARDS: the object card's refresh and scan
-- ---------------------------------------------------------------------------
section("CARDS (ObjectCards: 250 ms and 1 s on the clock)")
do
    local ocNew, ocOld = readFile(Z .. "ObjectCards.lua"), baseFile("ObjectCards.lua")
    local function load(src, withHelpers)
        local helpers = withHelpers and cut(src, "local function sixtieths(o, atKey, now)", "    return e._zedPhase\nend") or ""
        local tick = cut(src, "function OC.tick(e, player)", "    return true\nend")
        if not tick then return nil end
        local OC = { REFRESH = 15, BROWSE_EVERY = 60, LEASH = 6, squareDist = function() return 0 end }
        local env = { OC = OC, ZeD = { logOnce = function() end }, getTimestampMs = function() return math.floor(CLOCK) end }
        run(helpers .. "\n" .. tick, "OC.tick", env)
        return OC
    end
    local OCn, OCo = load(ocNew, true), load(ocOld, false)
    check("CARDS: the blocks cut", OCn and OCo and OCn.tick and OCo.tick)
    local player = { getVehicle = function() return nil end, isDead = function() return false end, getZ = function() return 0 end }
    local function entry(stats)
        local t = { key = "a" }
        local def = { valid = function() return true end,
                      refresh = function(tt) stats.r = stats.r + 1; stats.rf[#stats.rf + 1] = stats.frame; tt.d = {} end,
                      nearby = function() stats.b = stats.b + 1; stats.bf[#stats.bf + 1] = stats.frame; return { t } end }
        return { def = def, t = t }
    end
    local row = {}
    for _, fps in ipairs({ 30, 60, 144, 240 }) do
        local sn = { r = 0, b = 0, rf = {}, bf = {}, frame = 0 }
        local so = { r = 0, b = 0, rf = {}, bf = {}, frame = 0 }
        local en, eo = entry(sn), entry(so)
        frames(fps, 10, function()
            sn.frame = sn.frame + 1; so.frame = so.frame + 1
            OCn.tick(en, player); OCo.tick(eo, player)
        end)
        row[#row + 1] = string.format("%d FPS refresh %d -> %d, scan %d -> %d", fps, so.r, sn.r, so.b, sn.b)
        check("CARDS at " .. fps .. " FPS: 40 or 41 refreshes in 10 s", sn.r >= 40 and sn.r <= 41, sn.r)
        check("CARDS at " .. fps .. " FPS: 10 or 11 scans in 10 s", sn.b >= 10 and sn.b <= 11, sn.b)
        if fps == 60 then check("CARDS at 60 FPS: as the old count", math.abs(sn.r - so.r) <= 1 and math.abs(sn.b - so.b) <= 1) end
        -- the scan doesn't run in step with the refresh (after the card's first frame)
        local rs, together = {}, 0
        for i = 2, #sn.rf do rs[sn.rf[i]] = true end
        for i = 2, #sn.bf do if rs[sn.bf[i]] then together = together + 1 end end
        check("CARDS at " .. fps .. " FPS: the scan not on a refresh frame", together == 0, together)
    end
    note("in 10 s, old -> new: " .. table.concat(row, "; "))
    -- the kinds' "refresh now" and "in three"
    local s = { r = 0, b = 0, rf = {}, bf = {}, frame = 0 }
    local e = entry(s)
    frames(144, 1, function() OCn.tick(e, player) end)
    local r0 = s.r
    e.t._refreshT = OCn.REFRESH
    CLOCK = CLOCK + 7; OCn.tick(e, player)
    check("CARDS: _refreshT = OC.REFRESH refreshes on the next frame", s.r == r0 + 1)
    e.t._refreshT = OCn.REFRESH - 3
    local t0, r1 = CLOCK, s.r
    while s.r == r1 and CLOCK - t0 < 1000 do CLOCK = CLOCK + 1000 / 144; OCn.tick(e, player) end
    check("CARDS: OC.REFRESH - 3 refreshes 50 ms later at 144 FPS (3 frames at 60)", CLOCK - t0 >= 49 and CLOCK - t0 <= 56, CLOCK - t0)
end

-- ---------------------------------------------------------------------------
-- EQUIP: the outermost layer in a slot
-- ---------------------------------------------------------------------------
section("EQUIP (a slot shows its outermost layer)")
do
    local function item(name)
        return { _n = name, getDisplayName = function() return name end, getCondition = function() return 5 end,
                 getConditionMax = function() return 10 end }
    end
    -- the game's order: innermost first (WornItems.setItem by the BodyLocations.lua order: Tshirt, Shirt, Sweater, Jacket)
    local worn = {
        { "base:tshirt", item("T-shirt") }, { "base:shirt", item("Shirt") }, { "base:sweater", item("Sweater") },
        { "base:jacket", item("Jacket") }, { "base:shoes", item("Shoes") },
    }
    local wl = {}
    for i, w in ipairs(worn) do wl[i] = { getItem = function() return w[2] end, getLocation = function() return w[1] end } end
    local p = { getWornItems = function() return jlist(wl) end, getPrimaryHandItem = function() return nil end,
                getSecondaryHandItem = function() return nil end, getPlayerNum = function() return 0 end,
                isFemale = function() return false end }
    local function slotItem(data, ty)
        for _, g in ipairs(data.groups) do for _, s in ipairs(g.slots) do if s.type == ty then return s.item and s.item._n end end end
    end
    local function gatherWith(src, name)
        installZeD()
        ZeD.ProtectionTab = { gatherData = function() return {} end }
        ZeD.EquipDoll = {}
        local ok, err = pcall(run, src, name)
        if not ok then return nil, err end
        local ok2, data = pcall(ZeD.EquipmentTab.gatherData, p)
        if not ok2 then return nil, data end
        return data
    end
    local dn, en = gatherWith(equipNew, "EquipmentTab")
    local dold, eo = gatherWith(equipOld, "EquipmentTab@base")
    check("EQUIP: the tab's gatherData ran", dn and dold, en or eo)
    if dn and dold then
        check("EQUIP: the outer slot shows the jacket (worn over the sweater)", slotItem(dn, "OUT") == "Jacket", slotItem(dn, "OUT"))
        check("EQUIP: the inner slot shows the shirt (worn over the T-shirt)", slotItem(dn, "INR") == "Shirt", slotItem(dn, "INR"))
        check("EQUIP: a one-layer slot is the same", slotItem(dn, "BOT") == "Shoes")
        check("EQUIP: the old tab showed the sweater (this sim tells them apart)", slotItem(dold, "OUT") == "Sweater", slotItem(dold, "OUT"))
    end
    -- the doll, the same order (its own comment and loop)
    local doll = readFile(Z .. "EquipDoll.lua") or ""
    check("EQUIP: the doll reads the worn list from its end too", doll:find("for i = n - 1, 0, -1 do", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
-- PINS: the same words, no closure
-- ---------------------------------------------------------------------------
section("PINS (the title bar's words, without a closure per pin)")
do
    local pinsNew, pinsOld = readFile(Z .. "ZeD_Pins.lua"), baseFile("ZeD_Pins.lua")
    local stats = cut(pinsNew, "function P.stats(p)", "    return out\nend")
    check("PINS: P.stats makes no closure", stats and not stats:find("function", #"function P.stats(p)" + 1, true))
    local function mk(k, id, it)
        return { k = k, id = id, it = it }
    end
    local items = {
        [1] = { getDisplayName = function() return "Carpentry Vol. 2: Advanced Joinery" end, getNumberOfPages = function() return 220 end,
                getAlreadyReadPages = function() return 48 end },
        [2] = { getDisplayName = function() return "Water Bottle" end, getFluidContainer = function()
                    return { getAmount = function() return 0.2 end, getCapacity = function() return 1 end } end },
        [3] = { getDisplayName = function() return "Flashlight" end, getCurrentUsesFloat = function() return 0.62 end },
        [4] = { getDisplayName = function() return "Axe" end, getCondition = function() return 2 end, getConditionMax = function() return 10 end },
        [5] = { getDisplayName = function() return "Broken jug" end, getFluidContainer = function() return nil end },   -- throws: no pin
        [6] = { getDisplayName = function() return "Read book" end, getNumberOfPages = function() return 10 end,
                getAlreadyReadPages = function() return 10 end },
        [7] = { getDisplayName = function() return "Spent" end, getCondition = function() return 0 end, getConditionMax = function() return 10 end },
    }
    local pins = { { k = "skill", id = "Carpentry" }, { k = "skill", id = "Cooking" }, { k = "book", id = 1 }, { k = "fluid", id = 2 },
                   { k = "uses", id = 3 }, { k = "cond", id = 4 }, { k = "fluid", id = 5 }, { k = "book", id = 6 },
                   { k = "cond", id = 7 }, { k = "cond", id = 99 }, { k = "other", id = 3 } }
    local p = { getModData = function() return { ZeD_Pins = pins } end,
                getInventory = function() return { getItemWithIDRecursiv = function(_, id) return items[id] end,
                                                    getFirstTypeRecurse = function() return nil end } end }
    local function statsWith(src, name)
        installZeD()
        _G._zedPinsHooked = true
        ZeD.SkillsTab = { getPinData = function(_, id)
            if id == "Carpentry" then return { name = "Carpentry", level = 3, xpInLevel = 120, xpForLevel = 300 } end
            if id == "Cooking" then return { name = "Cooking", level = 10, xpInLevel = 0, xpForLevel = 0 } end
        end }
        run(src, name)
        return ZeD.Pins.stats(p)
    end
    local a = statsWith(pinsOld, "ZeD_Pins@base")
    local b = statsWith(pinsNew, "ZeD_Pins")
    -- (the base's last shorter form, the numbers alone, is gone on purpose: the title bar drops a pin before it shows
    -- numbers with no word to them; the words, the colors and the name cut short are as before)
    local function worded(list)
        local out = {}
        for i, e in ipairs(list) do out[i] = { text = e.text, color = e.color, short = e.alts and e.alts[1] } end
        return out
    end
    check("PINS: the same entries, words and colors as before", same(worded(a), worded(b)))
    local bare = 0
    for _, e in ipairs(b) do for _, al in ipairs(e.alts or {}) do if not tostring(al):find("%a") then bare = bare + 1 end end end
    check("PINS: no shorter form is numbers alone (each keeps the pin's name)", bare == 0, bare)
    check("PINS: every kind answered (8 pins with words)", #b == 8, #b)
end

-- ---------------------------------------------------------------------------
-- FLYERS: the same visits, rectangles once
-- ---------------------------------------------------------------------------
section("FLYERS (visits from rectangles worked out once)")
do
    local fNew, fOld = readFile(Z .. "FlyerMap.lua"), baseFile("FlyerMap.lua")
    local READS = 0
    local raw = {}
    for i = 1, 60 do
        local d = {}
        for j = 1, 1 + i % 4 do
            local locs = {}
            for k = 1, 1 + (i + j) % 3 do
                local x1, y1 = (i * 37 + j * 11 + k * 5) % 300, (i * 53 + j * 7 + k * 13) % 300
                locs[k] = { x1 = x1, y1 = y1, x2 = x1 + 4 + k, y2 = y1 + 3 + j }
            end
            d["location" .. j] = locs
        end
        raw["piece" .. i] = d
    end
    local function counted(t)
        return setmetatable({}, { __index = function(_, k) READS = READS + 1; return t[k] end })
    end
    local defs = {}
    for id, d in pairs(raw) do defs[id] = counted(d) end
    -- (pairs on the definitions themselves: a plain table of counted pieces)
    local function visitsWith(src, name)
        installZeD()
        ZeD.Print = {}
        Events = setmetatable({}, getmetatable(Events))
        PrintMediaDefinitions = { MiscDetails = defs }
        Texture = { getSharedTexture = function() return nil end }
        run(src, name)
        local cb = Events.OnPlayerUpdate.fns[1]
        local md = {}
        local px, py = 0, 0
        local pl = { isLocalPlayer = function() return true end, getPlayerNum = function() return 0 end,
                     getZ = function() return 0 end, getX = function() return px end, getY = function() return py end,
                     getModData = function() return md end }
        READS = 0
        local checksRun = 0
        for x = 0, 310, 3 do
            for y = 0, 310, 7 do
                px, py = x + 0.5, y + 0.5
                CLOCK = CLOCK + 1001
                cb(pl)
                checksRun = checksRun + 1
            end
        end
        return md.ZeD_FlyerSeen or {}, READS / checksRun
    end
    local seenOld, readsOld = visitsWith(fOld, "FlyerMap@base")
    local seenNew, readsNew = visitsWith(fNew, "FlyerMap")
    local n = 0
    for _ in pairs(seenNew) do n = n + 1 end
    check("FLYERS: the same places visited", same(seenOld, seenNew), n)
    check("FLYERS: some places visited (the sim walks into them)", n > 20, n)
    check("FLYERS: the definitions read once, not each second", readsNew < 1, readsNew)
    note(string.format("definition reads per check: %.0f -> %.2f (%d places marked)", readsOld, readsNew, n))
end

-- ---------------------------------------------------------------------------
-- COOKING: the groups sorted when the list changes
-- ---------------------------------------------------------------------------
section("COOKING (ingredient groups: sorted when the list or the sort changes)")
do
    local src = readFile(Z .. "CookingTab.lua")
    local blk = cut(src, "    local gc = s._ingGroups", "    s._ingGroups = { src = ing, sort = s.sort, groups = groups }\n    end")
    check("COOKING: the block cut", blk ~= nil)
    local fn = run("return function(s, ing)\n" .. (blk or "") .. "\nreturn groups\nend", "CookingGroups", {})
    -- the old way, as the old renderIngredients grouped and sorted (every frame)
    local function oldGroups(s, ing)
        local groups = {}
        if s.sort == "kind" then
            local byK = {}
            for _, g in ipairs(ing) do
                local k = byK[g.kind]
                if not k then k = { label = g.kindLabel, kind = g.kind, rows = {} }; byK[g.kind] = k; groups[#groups + 1] = k end
                k.rows[#k.rows + 1] = g
            end
            table.sort(groups, function(a, b)
                if (a.kind == "_spice") ~= (b.kind == "_spice") then return b.kind == "_spice" end
                return a.label < b.label
            end)
        else
            local rows = {}
            for _, g in ipairs(ing) do rows[#rows + 1] = g end
            groups[1] = { label = getText("IGUI_perks_Cooking"), rows = rows, kind = "_all" }
        end
        for _, grp in ipairs(groups) do table.sort(grp.rows, function(a, b) return a.name < b.name end) end
        return groups
    end
    local kinds = { { "Vegetables", "Veg" }, { "Fruits", "Fruit" }, { "_spice", "Seasoning" }, { "Meat", "Meat" } }
    local ing = {}
    for i = 1, 30 do
        local k = kinds[i % 4 + 1]
        ing[i] = { ft = "Base.F" .. i, name = "Food " .. string.char(65 + (i * 7) % 26) .. i, kind = k[1], kindLabel = k[2] }
    end
    local sorts = 0
    local realSort = table.sort
    table.sort = function(t, f) sorts = sorts + 1; return realSort(t, f) end
    local s = { sort = "kind" }
    local first = fn(s, ing)
    check("COOKING by kind: the old groups and order", same(first, oldGroups({ sort = "kind" }, ing)))
    sorts = 0
    local again
    for _ = 1, 60 do again = fn(s, ing) end
    check("COOKING: 60 frames of the same list sort nothing", sorts == 0, sorts)
    check("COOKING: the same groups", again == first)
    s.sort = "name"
    sorts = 0
    local byName = fn(s, ing)
    check("COOKING: a new sort sorts again", sorts == 1, sorts)
    check("COOKING by ingredient: the old order", same(byName, oldGroups({ sort = "name" }, ing)))
    local ing2 = {}
    for i = 1, 12 do ing2[i] = ing[i] end
    sorts = 0
    local fresh = fn(s, ing2)
    check("COOKING: a new list (ingCache) sorts again", sorts == 1 and same(fresh, oldGroups({ sort = "name" }, ing2)))
    table.sort = realSort
    note("sorts over 60 frames of one list: old " .. (60 * 5) .. " (by kind: 4 groups + their order), new 0")
end

print("perf_throttles_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
