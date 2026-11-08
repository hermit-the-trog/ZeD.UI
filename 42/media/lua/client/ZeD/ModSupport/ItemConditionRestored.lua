-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/ItemConditionRestored.lua
-- ============================================================================
-- SUPPORT FOR ITEM CONDITION RESTORED (mod id ItemConditionRestored, Workshop
-- 3834708364; it continues Item Condition by Qudix). Client.
--
-- The mod draws a bar behind each item on the game's hotbar (ISHotbar:render)
-- and a circle behind the two hand items (ISEquippedItem:render): how much is
-- left of the item, measured its way (ItemCondition.Util:Measure):
--   * a liquid container (a pan or pot that is also a weapon only while it
--     holds something): how full it is, in its liquid colors (blue);
--   * a weapon: its condition;
--   * a drainable (a lighter, a battery, thread...): its uses left;
--   * a battery radio or walkie with a battery: its charge.
-- Its options (Options > Mods) set a style for the hotbar and one for the hands:
-- None, or a bar or circle in one color or in colors by how much is left
-- (vertical or horizontal), with an opacity and a color for each tenth.
--
-- ZeD's belt replaces both (the game's hotbar is parked off-screen, the hand
-- items are the belt's circles), so the mod's bars never show under ZeD. The
-- belt already draws a condition strip under each slot and a condition ring in
-- each hand, for items with a condition. This file gives the belt the mod's
-- number through the belt's general hook ZeD.Belt.addMeter, so the same strip
-- and ring show what the mod shows:
--   * the mod's value, where it has one (liquid, a weapon's condition, uses
--     left, charge); items it has nothing for keep ZeD's own condition;
--   * a liquid in the theme's info color (the mod's blue), every other value in
--     the condition's graduated colors when the mod's style is multicolor, in
--     one color (the theme's positive, the mod's green) when it is one color;
--   * the style None hands that place back to ZeD's own condition.
-- The strip stays the belt's ten-segment strip and the ring the belt's ring:
-- the mod's direction (vertical or horizontal), opacity and picked colors are
-- its look on the game's hotbar and do not carry over (the theme sets ZeD's).
-- The mod's numbers are read every frame from its own functions; ZeD stores
-- nothing. Safe mode: the game's hotbar and hands are back, with the mod's bars.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "ItemConditionRestored"

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

require "ZeD/ZeD_Belt"
pcall(require, "ItemConditionRestored/Config")   -- (the mod's files; its globals are read when used, whatever the load order)
pcall(require, "ItemConditionRestored/Util")
pcall(require, "ItemConditionRestored/UI")

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.ItemConditionRestored = S

-- the mod's styles (its combo's order): 1 None, 2 vertical, 3 vertical multicolor, 4 horizontal, 5 horizontal multicolor
local MODE_NONE = 1
local MULTI = { [3] = true, [5] = true }

-- The mod's measure for one item on the belt: f (0..1) and the belt's kind, or nil to leave ZeD's own condition.
-- where: "slot" (the mod's hotbar style) or "hand" (its equipped item style).
function S.meter(item, where)
    local IC = ItemCondition
    if type(IC) ~= "table" or type(IC.Config) ~= "table" or type(IC.UI) ~= "table" or type(IC.UI.Measure) ~= "function" then
        return nil
    end
    local cfg = (where == "hand") and IC.Config.EquippedItem or IC.Config.Hotbar
    local mode = type(cfg) == "table" and tonumber(cfg.ProgressBarMode) or nil
    if not mode or mode <= MODE_NONE then return nil end
    local value, configType = IC.UI:Measure(item)   -- (the mod's own pcall: an item it cannot read is logged once and gives nil)
    if type(value) ~= "number" then return nil end
    if configType ~= nil and configType == IC.Config.TypeWater then return value, "fluid" end
    if MULTI[mode] then return value, nil end   -- (the condition's graduated colors)
    return value, "flat"
end

ZeD.Belt.addMeter(MOD_ID, S.meter)

print("[ZeD] ModSupport: Item Condition Restored (its numbers on the belt's strips and rings)")
