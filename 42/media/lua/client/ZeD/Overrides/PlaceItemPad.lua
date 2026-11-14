-- ZeD-UI/42/media/lua/client/ZeD/Overrides/PlaceItemPad.lua
-- ============================================================================
-- A ON THE GAME'S PLACE ITEM CURSOR, ON A CONTROLLER. Client; one wrap.
--
-- On 42.22.2 the game's Place Item cursor (ISPlace3DItemCursor) never places on
-- a controller: its build flag is set only on a mouse release (ISBuildingObject
-- DoTileBuilding takes the joypad branch and leaves it false), and its joypad
-- handler has no case for A, though the prompt says "A Place Item". The
-- furniture cursor (ISMoveableCursor) does handle A. Found in the director's
-- playtest, Nov 14 2026 (punch list 184).
--
-- Here A, with the spot valid and the fine-aim (Y held) off, sets the cursor's
-- build flag; the game's own per-frame building code then places the item
-- through its tryBuild, its walk and its timed action, as the mouse does.
-- ============================================================================

local function apply()
    if not ISPlace3DItemCursor or ISPlace3DItemCursor._zedPadA then return end
    ISPlace3DItemCursor._zedPadA = true
    local orig = ISPlace3DItemCursor.onJoypadPressButton
    function ISPlace3DItemCursor:onJoypadPressButton(joypadIndex, joypadData, button)
        if button == Joypad.AButton and not self.joypadPositionActive and self.canBeBuild then
            self.build = true
            return
        end
        if orig then return orig(self, joypadIndex, joypadData, button) end
    end
    print("[ZeD] PlaceItemPad: A places with the game's Place Item cursor on a controller")
end

Events.OnGameBoot.Add(apply)
apply()
