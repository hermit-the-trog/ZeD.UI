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
CC.SMOOTH = 0.4    -- weight of the newest sample in the smoothed rate
CC.KEEP_MAX = 128  -- foods remembered before the list starts over

-- per food: { ct = cooking time at the last sample, t = game minute of it, rate, shown }
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
        e = { ct = ct, t = now }
        _seen[k] = e
        return nil
    end
    local dt = now - e.t
    -- off the heat, a clock run back (a load), cooking time gone down or a long gap: start the sample here,
    -- keep the rate it had (the food back on the same heat cooks as it did)
    if not hot or dt < 0 or ct < e.ct or dt > CC.STALE then
        e.ct, e.t = ct, now
        return e.rate
    end
    if dt >= CC.SPAN then
        local r = (ct - e.ct) / dt
        if r > 0 then
            e.rate = e.rate and (e.rate + (r - e.rate) * CC.SMOOTH) or r
        end
        e.ct, e.t = ct, now
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
