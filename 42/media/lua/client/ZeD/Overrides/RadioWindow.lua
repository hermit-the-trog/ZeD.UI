-- ZeD-UI/42/media/lua/client/ZeD/Overrides/RadioWindow.lua
-- ============================================================================
-- RADIO WINDOW OVERRIDE (S115)
-- Suppress vanilla ISRadioWindow's auto-open behavior. ZeD-UI's RadioTab
-- (S115) renders the radio chassis inline in the Character/World Window
-- drawer; the legacy floating ISRadioWindow popup is redundant and breaks
-- the "complete UI, not a skin" project rule by stealing focus and covering
-- the ZeD chrome whenever a radio is equipped.
--
-- Vanilla registers ISRadioWindow.onEquip on OnEquipPrimary + OnEquipSecondary
-- in RadioCom/ISRadioWindow.lua:412-413. We unregister both handlers at boot
-- once vanilla has finished loading.
--
-- Right-click "Use" on a world radio also calls ISRadioWindow.activate
-- (ISWorldObjectContextMenu.lua:222) — that's user-initiated and rare; left
-- alone this session. Will be replaced by ZeD context menu route in S115b.
--
-- While ZeD's safe mode is on, vanilla's handler is put back (the popup opens
-- on equip again) and taken off once more when safe mode goes off.
-- ============================================================================

require "ZeD/SafeMode"

ZeD = ZeD or {}
-- kept on the module so a reload of this file still knows whether vanilla's handler is off
ZeD.RadioWindowHook = ZeD.RadioWindowHook or { removed = false }
local RW = ZeD.RadioWindowHook

local function suppressVanillaRadioAutoOpen()
    if RW.removed then return end
    if ISRadioWindow == nil or ISRadioWindow.onEquip == nil then return end
    -- Events.OnEquipPrimary / .OnEquipSecondary are PZ event tables that
    -- expose a .Remove(handler) method. Calling it with the same function
    -- reference vanilla used to subscribe unregisters that listener.
    if Events and Events.OnEquipPrimary and Events.OnEquipPrimary.Remove then
        Events.OnEquipPrimary.Remove(ISRadioWindow.onEquip)
    end
    if Events and Events.OnEquipSecondary and Events.OnEquipSecondary.Remove then
        Events.OnEquipSecondary.Remove(ISRadioWindow.onEquip)
    end
    RW.removed = true
end

-- safe mode: vanilla's handler goes back on, once
local function restoreVanillaRadioAutoOpen()
    if not RW.removed then return end
    RW.removed = false
    if ISRadioWindow == nil or ISRadioWindow.onEquip == nil then return end
    if Events and Events.OnEquipPrimary and Events.OnEquipPrimary.Add then
        Events.OnEquipPrimary.Add(ISRadioWindow.onEquip)
    end
    if Events and Events.OnEquipSecondary and Events.OnEquipSecondary.Add then
        Events.OnEquipSecondary.Add(ISRadioWindow.onEquip)
    end
end

-- Defer to OnGameBoot so vanilla's ISRadioWindow.lua has already executed
-- its top-level Events.OnEquipPrimary.Add(...) calls before we remove them.
Events.OnGameBoot.Add(function()
    if ZeD.Safe.on() then return end
    suppressVanillaRadioAutoOpen()
end)

ZeD.Safe.register("radio window", { leave = restoreVanillaRadioAutoOpen, enter = suppressVanillaRadioAutoOpen })

-- S115b: replace vanilla's auto-open behavior with our own — when the player
-- equips a radio, if the ZeD Character Window is open, flip its active tab to
-- the radio tab so the drawer is showing the just-equipped device. Doesn't
-- force-open the window; if the user has it closed, equipping doesn't pop it.
local function onEquipRadioAutoSwitch(player, item)
    if ZeD.Safe.on() then return end
    if player == nil or player ~= getPlayer() then return end
    if item == nil or not instanceof(item, "Radio") then return end
    -- Refresh the radio list immediately so the predicate that gates the tab
    -- visibility sees the new radio without waiting for the 30-frame timer.
    local charWin = ZeD_CharacterWindow and ZeD_CharacterWindow.getInstance
                    and ZeD_CharacterWindow.getInstance() or nil
    if charWin == nil then return end
    if not charWin:isVisible() then return end
    if ZeD.RadioTab and ZeD.RadioTab.buildEquippedRadios then
        charWin._radios = ZeD.RadioTab.buildEquippedRadios(player)
    end
    if charWin._radios and #charWin._radios > 0 then
        charWin._activeTab = "radio"
        charWin._radioIdx = 1
    end
end

Events.OnEquipPrimary.Add(onEquipRadioAutoSwitch)
Events.OnEquipSecondary.Add(onEquipRadioAutoSwitch)
