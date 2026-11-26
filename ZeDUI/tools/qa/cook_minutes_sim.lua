-- ZeDUI/tools/qa/cook_minutes_sim.lua  (Nov 25 2026, Build; QA K12, the cooking "min left")
-- QA measured that a food's cooking time is not game minutes: it grew 1.26 a game minute on a campfire, 1.27 in a
-- range at 100 and 1.88 at 300, so "minutes to cook - cooking time" said 50 / 49 / 50 min when the food got there
-- in 38.6 / 38.7 / 26.0. With no game running, the real ZeD/CookClock.lua runs on a stub game clock and a stub food
-- cooking at each measured rate. It checks:
--   no minutes figure before a steady rate is measured (the rows show their percent then); the first figure, within
--   about ten game minutes (QA K12 third pass: a range warming up), is the real game minutes (38.6, 38.7, 26.0); a jump as the food heats up does not set
--   the rate (QA's second pass: 24 said, 37 real); it counts down with the clock and never goes up
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
local function run(name, rate, startCt, toCook, jump, ramp)
    CC.reset()
    local it = food(startCt)
    local first = CC.minutesLeft(it, it.ct, toCook, true)
    check(name .. ": no minutes before a rate is measured", first == nil, first)
    local shown, t, last, rose = nil, 0, nil, false
    while it.ct < toCook do
        advance(0.1); t = t + 0.1
        -- (ramp: a range warming up, the rate climbing from a fifth of its own over the first ramp minutes)
        local r = rate
        if ramp and t < ramp then r = rate * (0.2 + 0.8 * t / ramp) end
        it.ct = it.ct + r * 0.1
        if jump and t > 0.45 and t < 0.55 then it.ct = it.ct + jump; startCt = startCt + jump end   -- (the heat-up step)
        local m = CC.minutesLeft(it, it.ct, toCook, true)
        if m and not shown then shown = { m = m, t = t } end
        if m and last and m > last then rose = true end
        if m then last = m end
    end
    -- the first figure shown, plus the minutes already gone, is the real time (rounded up); the real time is
    -- the minutes the loop took, so a ramp is counted as it cooked
    local real = t
    check(name .. ": a figure within about ten game minutes", shown and shown.t <= 10.2, shown and shown.t)
    local said = shown and (shown.m + shown.t) or -1
    check(name .. ": says the real game minutes (" .. string.format("%.1f", real) .. ")", math.abs(said - real) <= 1.2, said)
    check(name .. ": never counts up while the heat holds", not rose)
    check(name .. ": reaches 0 or 1 at the end", last and last <= 1, last)
    return shown and shown.m
end

-- QA's three: started cold (cooking time 0, minutes to cook 50 / 49 / 50 as the old line said them)
local m1 = run("campfire 1.26/min", 1.26, 0, 48.6)   -- 48.6 / 1.26 = 38.6 game minutes
local m2 = run("range at 100, 1.27/min", 1.27, 0, 49.1)   -- 38.7
local m3 = run("range at 300, 1.88/min", 1.88, 0, 48.9)   -- 26.0
check("the old line would have said 49 / 50, the new one does not", m1 and m3 and m1 < 45 and m3 < 30)
-- QA's second pass: range at 100, 1.29 a minute after a step as it heated (about 2 a minute read in the first
-- minute): 47.8 left after it is 37 game minutes, not 24
run("range at 100 with a heat-up step", 1.29, 0, 47.8 + 6, 6)
-- QA's third pass: a range at 300 warming up (the food at 1.3 of 50 when the first figure came, 15 said for a
-- real 24.8); with the rate climbing over the first four minutes the first figure must still be the real time
run("range at 300 warming up", 1.88, 0, 48.9, nil, 4)

-- off the heat: no figure; back on, measured afresh (the heat may not be the one it left)
CC.reset()
do
    local it = food(0)
    CC.minutesLeft(it, it.ct, 70, true)
    local on = nil
    for _ = 1, 95 do advance(0.1); it.ct = it.ct + 0.15; on = CC.minutesLeft(it, it.ct, 70, true) end
    check("on the heat for nine and a half minutes at 1.5/min: the real minutes", on and math.abs(on - (70 - it.ct) / 1.5) <= 1, on)
    advance(5)
    check("off the heat: no figure", CC.minutesLeft(it, it.ct, 50, false) == nil)
    advance(0.1); it.ct = it.ct + 0.15
    local back = CC.minutesLeft(it, it.ct, 50, true)
    check("back on: no figure until it is measured again", back == nil, back)
    for _ = 1, 90 do advance(0.1); it.ct = it.ct + 0.15; back = CC.minutesLeft(it, it.ct, 50, true) end
    check("back on for nine minutes: the real minutes again", back and math.abs(back - (50 - it.ct) / 1.5) <= 1, back)
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
    local m = nil
    for _ = 1, 80 do advance(0.1); it.ct = it.ct + 0.2; m = CC.minutesLeft(it, it.ct, 50, true) end
    check("then minutes of steady heat measure it (2/min)", m and math.abs(m - (50 - it.ct) / 2) <= 1, m)
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
