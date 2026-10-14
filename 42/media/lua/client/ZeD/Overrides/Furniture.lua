-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Furniture.lua
-- ============================================================================
-- FURNITURE HOOKS — HOOK_MAP row 15
--   * Moveables mode: ZeD.FurnitureTab hooks ISMoveableCursor.setInfoPanel
--     (to read what the cursor reads) and ISMoveableInfoWindow.render (quiet
--     while the Furniture tab is up), and opens the tab for a cursor started
--     any other way. Nothing more is needed here.
--   * Extended 3D Placement: ISExtendedPlacementAction:perform (vanilla walks
--     next to the item first) opens the placement card in the World window
--     card drawer instead of ISExtendedPlacementUI.
-- Vanilla runs only when ZeD declines (no World window, item gone).
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/FurnitureTab"
require "ZeD/ObjectCardPlacement"

local OC = ZeD.ObjectCards

local function apply()
    if ZeD.FurnitureTab and ZeD.FurnitureTab.install then ZeD.FurnitureTab.install() end
    if ISExtendedPlacementAction and not ISExtendedPlacementAction._zedHooked then
        ISExtendedPlacementAction._zedHooked = true
        local orig = ISExtendedPlacementAction.perform
        ISExtendedPlacementAction.perform = function(self)
            local ok, handled = pcall(OC.open, self.character, "place3d", self.item)
            if ok and handled then
                ISBaseTimedAction.perform(self)
                return
            end
            if not ok then print("[ZeD] Furniture: placement route failed: " .. tostring(handled)) end
            return orig(self)
        end
    end
    print("[ZeD] Overrides/Furniture: moveables info and extended placement routed to the Furniture tab and placement card")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
