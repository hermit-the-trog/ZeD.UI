-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Fluids.lua
-- ============================================================================
-- FLUID HOOKS (override, client)
-- Vanilla's "Transfer Liquid" and "Container Info" open the ZeD fluid card in
-- the World window's card drawer instead of the floating vanilla windows:
--   * ISFluidContainerMenu.showUI (an item's Liquid menu) and
--     ISWorldObjectContextMenu.onFluidTransfer / onFluidInfo (rain barrels,
--     sinks, toilets, wells...) open the card at once within its reach, and
--     past it walk there first (OC.openNear); the pour walks when it runs;
--   * ISFluidTransferUI.OpenPanel / ISFluidInfoUI.OpenPanel catch every
--     other caller (crafting station fluid slots, mods).
-- Each hook sets a _zed*Hooked flag before wrapping, so a Lua reload never
-- wraps the wrapper. Vanilla runs only when ZeD declines (no World window,
-- invalid container, seated in a vehicle), and every time while safe mode is
-- on (SafeMode.lua).
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ObjectCards"
require "ZeD/ObjectCardFluid"

local OC = ZeD.ObjectCards

-- the tile of a world container (nil for an item: a bottle has no walk)
local function squareOf(c)
    local ok, sq = pcall(function()
        if c:isItem() then return nil end
        local o = c:getOwner()
        return o and o:getSquare() or nil
    end)
    return ok and sq or nil
end

-- A world container past the card's reach is walked to first and the card opens at the end of the walk, as the
-- game's own menu walks before its window (ISWorldObjectContextMenu.onFluidTransfer); the card opened, shut on its
-- first frame past its 6 tiles and nothing else happened (QA FL7, Nov 26 2026). Seated, OC.open says no and the
-- game's window opens instead (QA FL5).
local function openCard(label, player, container, source, info)
    if not (player and container) then return false end
    local arg = { container = container, source = source, info = info }
    local sq = squareOf(container)
    local ok, handled
    if sq then ok, handled = pcall(OC.openNear, player, "fluid", arg, sq)
    else ok, handled = pcall(OC.open, player, "fluid", arg) end
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
            if ZeD.Safe.on() then return orig(_player, _container, _source) end   -- safe mode: vanilla's window
            if openCard("transfer", _player, _container, _source, false) then return end
            return orig(_player, _container, _source)
        end
    end
    if ISFluidInfoUI and not ISFluidInfoUI._zedHooked then
        ISFluidInfoUI._zedHooked = true
        local orig = ISFluidInfoUI.OpenPanel
        ISFluidInfoUI.OpenPanel = function(_player, _container)
            if ZeD.Safe.on() then return orig(_player, _container) end
            if openCard("info", _player, _container, true, true) then return end
            return orig(_player, _container)
        end
    end
    if ISFluidContainerMenu and not ISFluidContainerMenu._zedHooked then
        ISFluidContainerMenu._zedHooked = true
        local orig = ISFluidContainerMenu.showUI
        ISFluidContainerMenu.showUI = function(playerObj, container, ui)
            if ZeD.Safe.on() then return orig(playerObj, container, ui) end
            local info = (ui == ISFluidInfoUI)
            if openCard("item menu", playerObj, wrap(container), false, info) then return end
            return orig(playerObj, container, ui)
        end
    end
    if ISWorldObjectContextMenu and not ISWorldObjectContextMenu._zedFluidHooked then
        ISWorldObjectContextMenu._zedFluidHooked = true
        local origT = ISWorldObjectContextMenu.onFluidTransfer
        ISWorldObjectContextMenu.onFluidTransfer = function(player, fluidcontainer)
            if ZeD.Safe.on() then return origT(player, fluidcontainer) end
            if openCard("world transfer", getSpecificPlayer(player), wrap(fluidcontainer), true, false) then return end
            return origT(player, fluidcontainer)
        end
        local origI = ISWorldObjectContextMenu.onFluidInfo
        ISWorldObjectContextMenu.onFluidInfo = function(player, fluidcontainer)
            if ZeD.Safe.on() then return origI(player, fluidcontainer) end
            if openCard("world info", getSpecificPlayer(player), wrap(fluidcontainer), true, true) then return end
            return origI(player, fluidcontainer)
        end
    end
    print("[ZeD] Overrides/Fluids: transfer liquid and container info routed to the fluid card")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
