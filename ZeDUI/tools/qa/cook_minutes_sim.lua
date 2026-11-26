-- ZeDUI/tools/qa/cook_minutes_sim.lua  (Nov 25 2026, Build; QA K12, the cooking "min left")
-- QA measured that a food's cooking time is not game minutes: it grew 1.26 a game minute on a campfire, 1.27 in a
-- range at 100 and 1.88 at 300, so "minutes to cook - cooking time" said 50 / 49 / 50 min when the food got there
-- in 38.6 / 38.7 / 26.0. With no game running, the real ZeD/CookClock.lua runs on a stub game clock and a stub food
-- cooking at each measured rate. It checks:
--   no minutes figure before a rate is measured (the rows show their percent then); after one game minute the figure
--   is the real game minutes (38.6 -> 39, 38.7 -> 39, 26.0 -> 26); it counts down with the clock and never goes up
--   while the heat holds; off the heat there is no figure; the time to burn uses the same rate; both call sites
--   (StationAppliance and ObjectCards) ask ZeD.CookClock.minutesLeft, not the old "minutes to cook - cooking time".
-- Run from the repo root:  lua51 ZeDUI/tools/qa/cook_minutes_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]cook_minutes_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function read(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a"):gsub("\r\n", "\n"); f:close()
    return s
end

-- the game clock: world age in hours
local worldHours = 100
getGameTime = function() return { getWorldAgeHours = function() return worldHours end } end
local function advance(min) worldHours = worldHours + min / 60 end

ZeD = {}
assert(loadstring(read("42/media/lua/client/ZeD/CookClock.lua")))()
local CC = ZeD.CookClock
check("CookClock loads", CC and CC.minutesLeft and CC.sample)

local nextId = 1
local function food(ct)
    nextId = nextId + 1
    local id = nextId
    return { ct = ct, getID = function() return id end }
end

-- One food cooking at rate (cooking time per game minute), toCook 50, looked at every 0.1 game minute (a refresh).
-- Returns the first figure shown after the first look, and the real minutes it takes to get there.
local function run(name, rate, startCt, toCook)
    CC.reset()
    local it = food(startCt)
    local first = CC.minutesLeft(it, it.ct, toCook, true)
    check(name .. ": no minutes before a rate is measured", first == nil, first)
    local shown, t, last, rose = nil, 0, nil, false
    while it.ct < toCook do
        advance(0.1); t = t + 0.1
        it.ct = it.ct + rate * 0.1
        local m = CC.minutesLeft(it, it.ct, toCook, true)
        if m and not shown then shown = { m = m, t = t } end
        if m and last and m > last then rose = true end
        if m then last = m end
    end
    local real = (toCook - startCt) / rate
    check(name .. ": a figure within about a game minute", shown and shown.t <= 1.15, shown and shown.t)   -- (ten 0.1 steps add to a hair under 1 in floats: the 11th look)
    -- the first figure shown, plus the minute already gone, is the real time (rounded up)
    local said = shown and (shown.m + shown.t) or -1
    check(name .. ": says the real game minutes (" .. string.format("%.1f", real) .. ")", math.abs(said - real) <= 1, said)
    check(name .. ": never counts up while the heat holds", not rose)
    check(name .. ": reaches 0 or 1 at the end", last and last <= 1, last)
    return shown and shown.m
end

-- QA's three: started cold (cooking time 0, minutes to cook 50 / 49 / 50 as the old line said them)
local m1 = run("campfire 1.26/min", 1.26, 0, 48.6)   -- 48.6 / 1.26 = 38.6 game minutes
local m2 = run("range at 100, 1.27/min", 1.27, 0, 49.1)   -- 38.7
local m3 = run("range at 300, 1.88/min", 1.88, 0, 48.9)   -- 26.0
check("campfire reads 38 or 39 after its first minute", m1 == 38 or m1 == 39, m1)
check("range 100 reads 38 or 39", m2 == 38 or m2 == 39, m2)
check("range 300 reads 25 or 26", m3 == 25 or m3 == 26, m3)
check("the old line would have said 49 / 50, the new one does not", m1 < 45 and m3 < 30)

-- off the heat: no figure; back on, the kept rate gives one at once
CC.reset()
do
    local it = food(10)
    CC.minutesLeft(it, it.ct, 50, true)
    advance(1); it.ct = it.ct + 1.5
    local on = CC.minutesLeft(it, it.ct, 50, true)
    check("on the heat after a minute: 25 min at 1.5/min", on == 26 or on == 25, on)
    advance(5)
    check("off the heat: no figure", CC.minutesLeft(it, it.ct, 50, false) == nil)
    advance(0.1); it.ct = it.ct + 0.15
    local back = CC.minutesLeft(it, it.ct, 50, true)
    check("back on: the kept rate answers at once, not the five cold minutes", back and math.abs(back - (50 - it.ct) / 1.5) <= 1, back)
    -- cooked: the same food counts to burnt (minutes to burn 80) at its own rate
    local burn = CC.minutesLeft(it, it.ct, 80, true)
    check("the time to burn uses the same rate", burn and math.abs(burn - (80 - it.ct) / 1.5) <= 1, burn)
end

-- a long gap (the card was shut) and a cooking time gone down start a new sample without a false rate
CC.reset()
do
    local it = food(0)
    CC.minutesLeft(it, 0, 50, true)
    advance(30); it.ct = 3
    check("after a long gap: still no figure (no rate guessed from it)", CC.minutesLeft(it, it.ct, 50, true) == nil)
    advance(1); it.ct = 5
    local m = CC.minutesLeft(it, it.ct, 50, true)
    check("then the next minute measures it (2/min)", m == 23 or m == 22, m)
end

-- no game clock: no figure, no error
do
    local keep = getGameTime
    getGameTime = nil
    local ok, m = pcall(CC.minutesLeft, food(0), 0, 50, true)
    check("no game clock: no figure, no error", ok and m == nil, m)
    getGameTime = keep
end

-- both call sites use it; the old figure is gone
for _, rel in ipairs({ "42/media/lua/client/ZeD/StationAppliance.lua", "42/media/lua/client/ZeD/ObjectCards.lua" }) do
    local s = read(rel) or ""
    local base = rel:match("([^/]+)%.lua$")
    check(base .. " requires ZeD/CookClock", s:find('require "ZeD/CookClock"', 1, true) ~= nil)
    local _, n = s:gsub("CC%.minutesLeft%(it, ct, toCook, hot%)", "")
    local _, b = s:gsub("CC%.minutesLeft%(it, ct, toBurn, hot%)", "")
    check(base .. " asks CookClock for cook and burn", n == 1 and b == 1, n .. "/" .. b)
    check(base .. " has no raw cooking-time minutes", not s:find("math.ceil(toCook - ct)", 1, true) and not s:find("math.ceil(toBurn - ct)", 1, true))
end

print("cook_minutes_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
