-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/ContainerCapacityIndicator.lua
-- ============================================================================
-- SUPPORT FOR CONTAINER CAPACITY INDICATOR [B42] (mod id
-- ContainerCapacityIndicator, Workshop 3789660055).
--
-- The mod wraps the render of every container button the game's inventory and
-- loot pages create (ISInventoryPage:addContainerButton) and draws a thin
-- fill bar along the bottom of the button: how full the container is,
--     ratio = container:getCapacityWeight() / container:getEffectiveCapacity(player)
-- (clamped to 0..1), green below 75 percent, amber from 75, red from 95. No
-- bar for a container with no capacity. It marks every button, the main
-- inventory and the floor among them. Its only option is for the magazine
-- marks on loose items ("Show magazine indicators"), which are drawn in item
-- lists and not on container buttons, so no option of the mod changes the
-- container bars. (The mod also draws bars on bag items inside item lists and
-- on magazines; ZeD's item lists are its own and are not covered here.)
-- ZeD's Character and World windows replace the game's pages, so the bars the
-- mod puts on the game's buttons never show under ZeD.
--
-- This file registers a decorator with both container strips (the general hook,
-- StripDecorators.lua: ZeD_CharacterWindow.addStripDecorator and
-- ZeD_WorldWindow.addStripDecorator) which draws the same number as ZeD's
-- compact fill bar (ZeD.Atoms.drawFillBar, the library's one fill) along the
-- bottom of each button, inside the button, in the mod's own bands mapped to
-- the theme's status colours: T.positive, T.warning (from 75 percent) and
-- T.danger (from 95 percent). The numbers are the mod's own, read from the
-- container each frame. ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "ContainerCapacityIndicator"

-- Is the mod switched on? getActivatedMods() is a Java list of mod ids; a
-- workshop id can carry a leading backslash, which is cut off before comparing.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/ExtraContainers"
require "ZeD/StripDecorators"
require "ZeD/ZeD_CharacterWindow"   -- (it loads the World window too)

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.ContainerCapacityIndicator = S

-- The mod's own bands (its getFillColor): red from 95 percent, amber from 75.
local RED_FROM   = 0.95
local AMBER_FROM = 0.75

-- What the decorator drew last, per container (QA reads it): ratio, bar width,
-- band name, the time it was drawn. Records are reused, so no garbage per frame.
S.last = {}

-- The mod's number for one container (its getCapacityRatio): nil when the
-- container has no capacity, else used weight over effective capacity, 0..1.
local function capacityRatio(inv, player)
    if not inv or not player then return nil end
    local capacity = inv:getEffectiveCapacity(player)
    if not capacity or capacity <= 0 then return nil end
    return math.max(0, math.min(inv:getCapacityWeight() / capacity, 1))
end
S.capacityRatio = capacityRatio

-- The theme's status colour (read fresh, never cached) and its name for a ratio.
local function bandOf(ratio, T)
    if ratio >= RED_FROM then return T.danger, "danger" end
    if ratio >= AMBER_FROM then return T.warning, "warning" end
    return T.positive, "positive"
end

-- The decorator for both strips: fn(panel, entry, x, y, w, h, win). The bar
-- sits along the bottom of the button, inset a little from its sides, one unit
-- above the line under the button. The mod draws it for every container with a
-- capacity, an empty one too (the bare well).
function S.decorate(panel, entry, x, y, w, h, win)
    local inv = entry and entry.inventory
    if not inv then return end
    local player = (win and win._playerObj) or getSpecificPlayer(0)
    local ratio = capacityRatio(inv, player)
    if not ratio then return end
    local T, A = ZeD.T, ZeD.Atoms
    local barH = A.fillBarCompactH()
    local inset = T.px(3)
    local barW = w - inset * 2
    if barW < T.px(8) then return end            -- a button too narrow for a bar draws none
    local by = y + h - T.px(1) - T.px(1) - barH  -- over the line under the button, one unit clear of it
    local color, band = bandOf(ratio, T)
    -- the library's bar: a fixed colour (the band's), not its own graduated one
    A.drawFillBar(panel, x + inset, by, barW, ratio, false, color, barH)
    local rec = S.last[inv]
    if not rec then rec = {}; S.last[inv] = rec end
    rec.ratio, rec.barW, rec.band, rec.at = ratio, barW, band, getTimestampMs()
end

ZeD_CharacterWindow.addStripDecorator(MOD_ID, S.decorate)
ZeD_WorldWindow.addStripDecorator(MOD_ID, S.decorate)
