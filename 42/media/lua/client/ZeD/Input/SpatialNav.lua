-- ZeD-UI/42/media/lua/client/ZeD/Input/SpatialNav.lua
-- ============================================================================
-- SPATIAL NAVIGATION — where a D-pad press goes, for every ZeD surface
-- (the in-game windows through FocusManager, the main menu's screens).
--
-- Director, Oct 15 2026: "Controller cone navigation is blocking directions
-- that are logical, like buttons to the right, requires moving down a button
-- then over, then up. Controller navigation freedom of movement in menus is
-- crucial."
--
-- The rule (the one console UIs use): a press goes to the nearest control
-- LINED UP in that direction (its edges overlap the focused control's across
-- the move: a button beside a list row, the row below in a column). Only when
-- nothing is lined up does it go to the nearest control that way at any angle,
-- so anything to the right is reachable with Right. Rectangles, not centres:
-- a short button beside a tall row counts as beside it.
--
-- Rects are { x, y, w, h } in one shared space. N.cost(from, to, dir) returns
-- tier, cost (tier 0 = lined up, 1 = off to the side; lower cost is nearer),
-- or nil when `to` is not that way at all. N.pick(fromRect, list, dir, rectOf)
-- returns the best entry of `list` (rectOf(entry) gives its rect, nil = skip).
-- ============================================================================

ZeD = ZeD or {}
ZeD.SpatialNav = ZeD.SpatialNav or {}
local N = ZeD.SpatialNav

local SIDE_WEIGHT = 2      -- a step to the side costs twice a step along the move
local CROSS_WEIGHT = 0.05  -- between equals, the one whose centre lines up better
local LEFT_BIAS = 0.5      -- up / down between equals: the left one (reading order)

function N.cost(f, t, dir)
    local fcx, fcy = f.x + f.w * 0.5, f.y + f.h * 0.5
    local tcx, tcy = t.x + t.w * 0.5, t.y + t.h * 0.5
    local horiz = (dir == "left" or dir == "right")
    local sgn = (dir == "right" or dir == "down") and 1 or -1
    -- it has to lie that way: its centre past the focused control's centre
    local along = horiz and (tcx - fcx) * sgn or (tcy - fcy) * sgn
    if along <= 0.5 then return nil end
    local gap, apart, cross
    if horiz then
        gap = (sgn > 0) and (t.x - (f.x + f.w)) or (f.x - (t.x + t.w))
        apart = math.max(t.y - (f.y + f.h), f.y - (t.y + t.h))   -- below zero: their spans overlap
        cross = math.abs(tcy - fcy)
    else
        gap = (sgn > 0) and (t.y - (f.y + f.h)) or (f.y - (t.y + t.h))
        apart = math.max(t.x - (f.x + f.w), f.x - (t.x + t.w))
        cross = math.abs(tcx - fcx)
        if tcx < fcx then cross = cross * LEFT_BIAS end
    end
    if gap < 0 then gap = 0 end          -- overlapping along the move: as near as can be
    local side = math.max(0, apart)
    -- lined up = a real overlap of 2 px (touching edges are not); compared at
    -- 1.5 so fractional scaling cannot read 2 px as 1.99 (Oct 23 2026, Large
    -- text: Left from a bag row skipped the button beside it for the far body)
    local tier = (apart <= -1.5) and 0 or 1
    return tier, gap + side * SIDE_WEIGHT + cross * CROSS_WEIGHT
end

-- the best of `list` from `fromRect` in `dir` (nil when nothing lies that way)
function N.pick(fromRect, list, dir, rectOf)
    local best, bestTier, bestCost = nil, nil, nil
    for i = 1, #list do
        local e = list[i]
        local r = rectOf and rectOf(e) or e
        if r then
            local tier, c = N.cost(fromRect, r, dir)
            if tier and (bestTier == nil or tier < bestTier or (tier == bestTier and c < bestCost)) then
                best, bestTier, bestCost = e, tier, c
            end
        end
    end
    return best, bestTier
end

return N
