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

-- ============================================================================
-- A AT A DOOR OR A WINDOW (punch list 218 (beta 19, Nov 16 2026)).
--
-- The prompt says A (Open door, Close window), but the game sets it with no function
-- (ISButtonPrompt:doInteractButtonDoorOrWindowOrWindowFrame): Java does the toggle, in
-- IsoPlayer.updateUseKey on A's release, through doContext. In the director's playtest it
-- never did, with no ZeD window holding the pad (the press logged as reaching the prompt).
-- updateUseKey drops the press when a text box is still typing (Core.currentTextEntryBox) or
-- Lua key presses are off, and doContext when the player blocks movement or ignores the
-- context key; no ZeD path was found leaving one of those on, so the press gets a function:
-- the game's own Open / Close from the right-click menu (ISWorldObjectContextMenu
-- onOpenCloseDoor / onOpenCloseWindow: walk beside it, a timed action), run on the press.
--
-- Never twice: if Java does act, it acts on this same press's release, so the press sets the
-- player's ignoreContextKey (doContext's first gate, as the Place Item guard above) and it
-- stays on until A has been up HOLD_UPDATES updates. The toggle is then ours alone, whether
-- Java would have acted or not. Only the controller's own prompt gets it (the hint strip's
-- keyboard copy keeps the game's nil, and still reads the hint by its words), and only a flag
-- set here is cleared.
-- ============================================================================
-- player number -> updates A has been up since the press (present only while this holds the flag)
local doorHeld = {}

local function isDoorOrWindow(obj)
    if not obj then return false end
    if instanceof(obj, "IsoDoor") or instanceof(obj, "IsoWindow") then return true end
    return instanceof(obj, "IsoThumpable") and obj:isDoor() == true
end

-- the prompt's aFunc: onAPress calls it as bp:aFunc(obj)
local function openCloseDoorOrWindow(bp, obj)
    local pn = bp and bp.player
    local p = pn ~= nil and getSpecificPlayer(pn)
    if not (p and obj) then return end
    if not p:isIgnoreContextKey() then
        p:setIgnoreContextKey(true)
        doorHeld[pn] = 0
    end
    if instanceof(obj, "IsoWindow") then ISWorldObjectContextMenu.onOpenCloseWindow(nil, obj, pn)
    else ISWorldObjectContextMenu.onOpenCloseDoor(nil, obj, pn) end
end
ZeD.PadDoor = { isDoorOrWindow = isDoorOrWindow, press = openCloseDoorOrWindow, held = doorHeld }

local function releaseDoorPress(player)
    if not player or not player:isLocalPlayer() then return end
    local pn = player:getPlayerNum()
    if doorHeld[pn] == nil then return end
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    if jd and jd.id ~= nil and interactDown(jd.id) then doorHeld[pn] = 0; return end
    doorHeld[pn] = doorHeld[pn] + 1
    if doorHeld[pn] < HOLD_UPDATES then return end
    doorHeld[pn] = nil
    if held[pn] ~= nil then return end   -- (the Place Item guard holds it too: it lets go)
    local cell = getCell()
    if cell and cell:getDrag(pn) then held[pn] = 0; return end   -- (a cursor came up meanwhile: that guard takes it over)
    player:setIgnoreContextKey(false)
end

local function wrapDoorPrompt()
    local B = ISButtonPrompt
    if not (B and B.doInteractButtonDoorOrWindowOrWindowFrame) or B._zedPadDoor then return end
    B._zedPadDoor = true
    local orig = B.doInteractButtonDoorOrWindowOrWindowFrame
    B.doInteractButtonDoorOrWindowOrWindowFrame = function(self, dir, obj)
        local before = self.aPrompt
        orig(self, dir, obj)
        if before == nil and self.aPrompt ~= nil and self.aFunc == nil and self.player ~= nil
            and JoypadState and JoypadState.players and JoypadState.players[self.player + 1]
            and isDoorOrWindow(obj) then
            self.aFunc = openCloseDoorOrWindow
            self.aParams = { obj }
        end
    end
end
ZeD.PadDoor.wrap = wrapDoorPrompt

if not ZeD._padDoorCtx then
    ZeD._padDoorCtx = true
    Events.OnPlayerUpdate.Add(function(player) pcall(releaseDoorPress, player) end)
end
wrapDoorPrompt()
Events.OnGameBoot.Add(wrapDoorPrompt)
Events.OnGameStart.Add(wrapDoorPrompt)

-- ============================================================================
-- A ON THE GAME'S BUILD CURSOR, ON A CONTROLLER (QA cb sweep, Nov 25 2026, B1).
--
-- The build cursor (ISBuildIsoEntity, the Build tab's and the game's own build
-- window's) has the same gap as Place Item above: its joypad handler
-- (ISBuildingObject:onJoypadPressButton) turns it with LB and RB and cancels it
-- with B, but has no case for A, and DoTileBuilding's joypad branch never sets
-- the build flag, though the prompt reads "A Build". QA proved it at 4K: A over
-- a clear tile did nothing and nothing was queued.
--
-- Here A, with the tile valid (canBeBuild, which the cursor's isValid already
-- reads false while blockBuild is set), sets the build flag, as the mouse's
-- release does; the game's per-frame DoTileBuilding then runs tryBuild, its walk
-- and its timed action. The other cursors (paint, wallpaper, furniture, destroy)
-- have their own A and are left alone.
-- ============================================================================
local function applyBuild()
    if not ISBuildIsoEntity or ISBuildIsoEntity._zedPadA then return end
    ISBuildIsoEntity._zedPadA = true
    local orig = ISBuildIsoEntity.onJoypadPressButton
    function ISBuildIsoEntity:onJoypadPressButton(joypadIndex, joypadData, button)
        if button == Joypad.AButton then
            if self.canBeBuild and not self.blockBuild then self.build = true end
            return
        end
        if orig then return orig(self, joypadIndex, joypadData, button) end
    end
    print("[ZeD] PlaceItemPad: A places with the game's build cursor on a controller")
end

-- (ISPlace3DItemCursor is server Lua, which loads with the save, after the client files and after
-- OnGameBoot: the playtest found the wrap never on. It goes on when the game starts, or a player is made.)
Events.OnGameBoot.Add(apply)
Events.OnGameStart.Add(apply)
Events.OnCreatePlayer.Add(apply)
apply()
Events.OnGameBoot.Add(applyBuild)
Events.OnGameStart.Add(applyBuild)
Events.OnCreatePlayer.Add(applyBuild)
applyBuild()
