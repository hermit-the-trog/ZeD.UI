-- ZeD-UI/42/media/lua/client/ZeD/CookClock.lua
-- ============================================================================
-- COOK CLOCK (client): how many game minutes a cooking food has left
-- The appliance window's contents (StationAppliance) and the object cards'
-- cooking rows (ObjectCards) both ask here, so the two say the same thing.
--
-- A food's cooking time is not game minutes. The game adds to it faster the
-- hotter the food is: QA measured 1.26 a game minute on a campfire, 1.27 in a
-- range at 100 and 1.88 at 300, so "minutes to cook - cooking time" said 50 min
-- when the food got there in 38.6 (26.0 at 300). Here each food's rate is
-- measured from its own cooking time over the game clock, smoothed, and the time
-- left is divided by it. Until a rate is measured there is no minutes figure
-- (nil), and the rows show their percent instead: nothing false
-- (QA K12, Nov 25 2026).
-- ============================================================================

ZeD = ZeD or {}
ZeD.CookClock = ZeD.CookClock or {}
local CC = ZeD.CookClock

CC.SPAN   = 1      -- game minutes between samples (shorter ones are mostly rounding)
CC.STALE  = 10     -- game minutes: a gap longer than this (the card was shut) starts a new sample
CC.WINDOW = 6      -- game minutes: the rate is the slope over the samples of the last this many minutes
CC.MIN_SPAN = 3    -- game minutes of samples (after the first, skipped) before any rate is given
CC.STEADY = 0.12   -- a rate is given once two slopes in a row agree within this share
CC.RING   = 12     -- samples kept per food
CC.KEEP_MAX = 128  -- foods remembered before the list starts over

-- The first version smoothed each one-minute step, and one step taken as the food heated up (QA saw about
-- 2 a minute where the food then cooked at 1.29) said 24 min for a real 37. Now the rate is the slope over
-- the last several minutes, the minute the food went on the heat is left out, and no figure is given until
-- two slopes agree: the rows show percent until then. (QA K12 second pass, Nov 25 2026)

-- per food: { ring = { {t, ct}, ... }, skip = the anchor sample is still first, rate (steady), last (latest
-- slope), shown }
-- The game's Lua ignores weak keys (__mode), so the list counts its entries and
-- starts over past KEEP_MAX, as the loot card's cache does; keyed by the item's
-- id (a number) when it has one, so nothing holds the item itself.
local _seen = {}
local _seenN = 0

local function nowMin()
    local gt = getGameTime and getGameTime()
    if not gt then return nil end
    local ok, h = pcall(gt.getWorldAgeHours, gt)
    if not ok or type(h) ~= "number" then return nil end
    return h * 60
end

local function keyOf(item)
    local f = item and item.getID
    if f then
        local ok, id = pcall(f, item)
        if ok and id ~= nil then return id end
    end
    return item
end

--- Feed one look at a food: its cooking time now and whether it is on the heat.
--- Returns the food's measured rate (cooking time per game minute) or nil.
function CC.sample(item, ct, hot)
    if item == nil or type(ct) ~= "number" then return nil end
    local now = nowMin()
    if not now then return nil end
    local k = keyOf(item)
    local e = _seen[k]
    if not e then
        _seenN = _seenN + 1
        if _seenN > CC.KEEP_MAX then _seen = {}; _seenN = 1 end
        e = { ring = { { t = now, ct = ct } }, skip = true }
        _seen[k] = e
        return nil
    end
    local ring = e.ring
    local lastS = ring[#ring]
    local dt = now - lastS.t
    -- off the heat, a clock run back (a load), cooking time gone down or a long gap: start the samples here,
    -- keep the rate it had (the food back on the same heat cooks as it did)
    if not hot or dt < 0 or ct < lastS.ct or dt > CC.STALE then
        e.ring = { { t = now, ct = ct } }
        e.skip, e.last = true, nil
        return e.rate
    end
    if dt >= CC.SPAN then
        ring[#ring + 1] = { t = now, ct = ct }
        if #ring > CC.RING then table.remove(ring, 1); e.skip = false end
        -- the first sample: the minute the food went on (it may have been heating, or partway through a step)
        local first = 1
        if e.skip then first = 2 end
        -- only the last WINDOW minutes
        while first < #ring and now - ring[first].t > CC.WINDOW do first = first + 1 end
        local a = ring[first]
        local span = now - a.t
        if span >= CC.MIN_SPAN and ct > a.ct then
            local slope = (ct - a.ct) / span
            if e.last and math.abs(slope - e.last) <= CC.STEADY * slope then e.rate = slope end
            e.last = slope
        end
    end
    return e.rate
end

--- Game minutes until the food's cooking time reaches target (minutes to cook, or to burn), rounded up;
--- nil until its rate is measured or when it is off the heat. Call it each refresh: it samples as it goes.
function CC.minutesLeft(item, ct, target, hot)
    local rate = CC.sample(item, ct, hot)
    if not hot or not rate or rate <= 0 or type(target) ~= "number" then return nil end
    local m = math.max(0, math.ceil((target - ct) / rate))
    -- steady: the smoothed rate wobbles a little, so one minute more than shown is held (it only goes down
    -- between samples); a bigger jump (cooked, now counting to burnt) shows at once
    local e = _seen[keyOf(item)]
    if e then
        if e.shown and m == e.shown + 1 then m = e.shown end
        e.shown = m
    end
    return m
end

--- Forget every food (QA and the sim).
function CC.reset() _seen = {}; _seenN = 0 end
