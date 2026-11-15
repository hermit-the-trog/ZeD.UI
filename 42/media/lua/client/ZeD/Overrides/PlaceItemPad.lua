-- ZeD-UI/42/media/lua/client/ZeD/Overrides/PlaceItemPad.lua
-- ============================================================================
-- A ON THE GAME'S PLACE ITEM CURSOR, ON A CONTROLLER. Client; one wrap, one per-update guard.
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
            print("[ZeD] PlaceItemPad: A sets build")
            return
        end
        if orig then return orig(self, joypadIndex, joypadData, button) end
    end
    print("[ZeD] PlaceItemPad: A places with the game's Place Item cursor on a controller")
end

-- ============================================================================
-- THE SAME A NO LONGER ALSO USES THE WORLD (Nov 15 2026, punch list 184 follow-up).
--
-- The director: placing an item next to a window also opened the window. Lua's press
-- already goes only to the cursor (JoyPadSetup gives it to getDrag and returns), but
-- Java polls A on its own: A is the Interact button, and IsoPlayer.updateUseKey runs
-- doContext (open a door or window, climb, sit on furniture) from it with nothing
-- asking whether a cursor is up. doContext's one gate is the player's ignoreContextKey,
-- which nothing in the game sets. So while any game cursor is up for a player on a
-- controller, that flag is on, and it stays on after the cursor goes (the item placed)
-- until A has been let go for a few updates: the release would fire it too.
-- OnPlayerUpdate runs in the player's update before updateUseKey, so the flag is in
-- place the same frame. Only a flag ZeD set is ever cleared.
-- ============================================================================
local HOLD_UPDATES = 3     -- updates with A up before the world may have it back

local function interactDown(id)
    local ok, down = pcall(function()
        local b = CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.Interact
            and CharacterJoypadButtonBinding.Interact:getJoypadButton() or JoypadButton.A
        return b ~= nil and b:isDown(id)
    end)
    return ok and down == true
end

-- player number -> updates A has been up since the cursor went (present only while ZeD holds the flag)
local held = {}

local function guardContext(player)
    if not player or not player:isLocalPlayer() then return end
    local pn = player:getPlayerNum()
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    local onPad = jd ~= nil and jd.id ~= nil
    local cell = getCell()
    if onPad and cell and cell:getDrag(pn) then
        if held[pn] == nil and not player:isIgnoreContextKey() then
            player:setIgnoreContextKey(true)
            held[pn] = 0
        elseif held[pn] ~= nil then
            held[pn] = 0
        end
        return
    end
    if held[pn] == nil then return end
    if onPad and interactDown(jd.id) then held[pn] = 0; return end
    held[pn] = held[pn] + 1
    if held[pn] >= HOLD_UPDATES then
        player:setIgnoreContextKey(false)
        held[pn] = nil
    end
end

ZeD = ZeD or {}
if not ZeD._placeItemPadCtx then
    ZeD._placeItemPadCtx = true
    Events.OnPlayerUpdate.Add(function(player) pcall(guardContext, player) end)
end

-- (ISPlace3DItemCursor is server Lua, which loads with the save, after the client files and after
-- OnGameBoot: the playtest found the wrap never on. It goes on when the game starts, or a player is made.)
Events.OnGameBoot.Add(apply)
Events.OnGameStart.Add(apply)
Events.OnCreatePlayer.Add(apply)
apply()
