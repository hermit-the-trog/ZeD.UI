-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Fluids.lua
-- ============================================================================
-- FLUID HOOKS — HOOK_MAP rows 8 and 9
-- Vanilla's "Transfer Liquid" and "Container Info" open the ZeD fluid card in
-- the World window's card drawer instead of the floating vanilla windows:
--   * ISFluidContainerMenu.showUI (an item's Liquid menu) and
--     ISWorldObjectContextMenu.onFluidTransfer / onFluidInfo (rain barrels,
--     sinks, toilets, wells...) open the card at once (no walk first, no
--     timed action); the pour walks when it runs;
--   * ISFluidTransferUI.OpenPanel / ISFluidInfoUI.OpenPanel catch every
--     other caller (crafting station fluid slots, mods).
-- Vanilla runs only when ZeD declines (no World window, invalid container).
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ObjectCardFluid"

local OC = ZeD.ObjectCards

local function openCard(label, player, container, source, info)
    if not (player and container) then return false end
    local ok, handled = pcall(OC.open, player, "fluid", { container = container, source = source, info = info })
    if not ok then print("[ZeD] Fluids: " .. label .. " route failed: " .. tostring(handled)) end
    return ok and handled
end

local function wrap(fc)
    if not fc then return nil end
    local ok, c = pcall(ISFluidContainer.new, ISFluidContainer, fc)
    return ok and c or nil
end

local function apply()
    if ISFluidTransferUI and not ISFluidTransferUI._zedHooked then
        ISFluidTransferUI._zedHooked = true
        local orig = ISFluidTransferUI.OpenPanel
        ISFluidTransferUI.OpenPanel = function(_player, _container, _source)
            if openCard("transfer", _player, _container, _source, false) then return end
            return orig(_player, _container, _source)
        end
    end
    if ISFluidInfoUI and not ISFluidInfoUI._zedHooked then
        ISFluidInfoUI._zedHooked = true
        local orig = ISFluidInfoUI.OpenPanel
        ISFluidInfoUI.OpenPanel = function(_player, _container)
            if openCard("info", _player, _container, true, true) then return end
            return orig(_player, _container)
        end
    end
    if ISFluidContainerMenu and not ISFluidContainerMenu._zedHooked then
        ISFluidContainerMenu._zedHooked = true
        local orig = ISFluidContainerMenu.showUI
        ISFluidContainerMenu.showUI = function(playerObj, container, ui)
            local info = (ui == ISFluidInfoUI)
            if openCard("item menu", playerObj, wrap(container), false, info) then return end
            return orig(playerObj, container, ui)
        end
    end
    if ISWorldObjectContextMenu and not ISWorldObjectContextMenu._zedFluidHooked then
        ISWorldObjectContextMenu._zedFluidHooked = true
        local origT = ISWorldObjectContextMenu.onFluidTransfer
        ISWorldObjectContextMenu.onFluidTransfer = function(player, fluidcontainer)
            if openCard("world transfer", getSpecificPlayer(player), wrap(fluidcontainer), true, false) then return end
            return origT(player, fluidcontainer)
        end
        local origI = ISWorldObjectContextMenu.onFluidInfo
        ISWorldObjectContextMenu.onFluidInfo = function(player, fluidcontainer)
            if openCard("world info", getSpecificPlayer(player), wrap(fluidcontainer), true, true) then return end
            return origI(player, fluidcontainer)
        end
    end
    print("[ZeD] Overrides/Fluids: transfer liquid and container info routed to the fluid card")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
