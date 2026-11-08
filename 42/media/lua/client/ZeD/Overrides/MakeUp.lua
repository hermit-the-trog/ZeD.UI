-- ZeD-UI/42/media/lua/client/ZeD/Overrides/MakeUp.lua
-- ============================================================================
-- MAKE-UP (vanilla windows B9; the director, Nov 7 2026: "Makeup is supposed
-- to go with the hair"). The inventory make-up item's Make Up option
-- (ISInventoryPaneContextMenu.onMakeUp, which the game's menu offers greyed
-- with "needs a mirror" when there is none) opened ISMakeUpUI. It now opens
-- the Character window's Identity tab on the Hair and beard section's Make Up
-- part, that item's spots first (ZeD_MakeUp.open, ZeD_HairBeard.showMakeUp).
-- The game's window opens only when ZeD's Character window cannot (its ZeD
-- screens switch for windows, safe mode, a failure).
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ZeD_MakeUp"

local function apply()
    if not (ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onMakeUp) or ISInventoryPaneContextMenu._zedMakeUp then return end
    local vanilla = ISInventoryPaneContextMenu.onMakeUp
    ISInventoryPaneContextMenu._zedMakeUp = vanilla
    ISInventoryPaneContextMenu.onMakeUp = function(makeup, playerObj, ...)
        if ZeD.Safe.on("windows") then return vanilla(makeup, playerObj, ...) end
        local ok, opened = pcall(ZeD.MakeUp.open, playerObj, makeup)
        if ok and opened then return end
        if not ok then print("[ZeD] MakeUp: the make-up kept the game's window: " .. tostring(opened)) end
        return vanilla(makeup, playerObj, ...)
    end
    print("[ZeD] Overrides/MakeUp: Make Up opens the Identity tab's make-up")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
