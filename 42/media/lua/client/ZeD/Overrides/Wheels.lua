-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Wheels.lua
-- ============================================================================
-- VANILLA'S RADIAL WHEELS — HOOK_MAP row 29 (ZeD_Wheel.lua draws them)
--
-- Every wheel in the game is one of two vanilla objects: the shared
-- ISRadialMenu (getPlayerRadialMenu: vehicle, animal, emotes, firearm, light,
-- map, D-pad Up / Down / Right, left stick, furniture, hotbar, and any mod's)
-- and the controller's ISBackButtonWheel, which derives it. ISRadialMenu's own
-- methods are the API every caller uses (clear, addSlice, centre, show; the
-- picks run the caller's command), so they stay; what goes is the engine's
-- drawing underneath. instantiate makes a plain element instead of the Java
-- RadialMenu, the slices live in Lua, the pick is worked out the engine's way
-- (ZeD.Wheel.sliceFromMouse / sliceFromJoypad) and ZeD.Wheel.draw paints it.
-- Vanilla's object is used whenever ZeD's cannot be (no tokens yet).
--
-- The wheels' slices that open a vanilla window ZeD has replaced now open the
-- ZeD surface (the same functions reached from anywhere else go there too):
--   Player Info (Back wheel)            -> the Character window pair
--   Investigate This Area (search window toggle, any caller) -> World window, Foraging
--   Designated Zones (zone panel toggle, any caller)         -> World window, Animals
-- ============================================================================

require "ISUI/ISRadialMenu"
require "ISUI/ISBackButtonWheel"
require "ZeD/ZeD_Wheel"
require "ZeD/SafeMode"

local W = ZeD.Wheel

local function ready()
    return ZeD and ZeD.T and ZeD.T.px and ZeD.T.ctx and ZeD.Molecules and ZeD.Molecules.drawContextCell and true or false
end

-- ---------------------------------------------------------------------------
-- Safe mode (SafeMode.lua): a wheel is built once, as the engine's RadialMenu
-- or as ZeD's plain element, and kept. On the way into safe mode every ZeD
-- wheel drops its element so its next show builds the engine's (instantiate
-- below goes vanilla while safe mode holds); on the way out the engine's drop
-- theirs and come back as ZeD's. Wheels seen so far are kept in a short list:
-- every build and every show (each starts with clear) moves a wheel to the
-- end, so the one least recently used is dropped first and the long-lived
-- shared wheel stays on it.
-- ---------------------------------------------------------------------------
local made = {}
local MADE_MAX = 64

local function remember(menu)
    for i = 1, #made do
        if made[i] == menu then
            if i < #made then
                table.remove(made, i)
                made[#made + 1] = menu
            end
            return
        end
    end
    if #made >= MADE_MAX then table.remove(made, 1) end
    made[#made + 1] = menu
end

-- off the screen, and built again (whichever way) the next time it is shown
local function rebuildOnNextShow(menu)
    if menu.javaObject then pcall(menu.removeFromUIManager, menu) end
    local jf = menu.joyfocus
    if jf and jf.focus == menu then jf.focus = nil end
    menu.javaObject = nil
    if menu._zed then
        menu._zed = nil
        menu.zedScaled = nil
        -- ZeD sized it for its cells; the engine's is sized by its radius
        if menu.outerRadius then menu.width, menu.height = menu.outerRadius * 2, menu.outerRadius * 2 end
    end
end

local function wheelsToVanilla()
    for i = #made, 1, -1 do
        local m = made[i]
        if m._zed then rebuildOnNextShow(m) end
    end
end

local function wheelsToZed()
    if not ready() then return end
    for i = #made, 1, -1 do
        local m = made[i]
        if not m._zed and m.javaObject then rebuildOnNextShow(m) end
    end
end

-- true when a call belongs to the engine's wheel (its own, or any wheel in safe mode)
local function engineSide(menu)
    return not menu._zed and (menu.javaObject ~= nil or ZeD.Safe.on())
end

-- run a slice's command as vanilla does (after the wheel has gone)
local function run(menu, index)
    local cmd = menu:getSliceCommand(index)
    if cmd and cmd[1] then
        W.noteChoice(menu, menu.slices[index])
        cmd[1](cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7])
    end
end

local function hookRadial()
    local R = ISRadialMenu
    if not R or R._zedWheel then return end
    R._zedWheel = true
    local O = {
        instantiate = R.instantiate, addSlice = R.addSlice, clear = R.clear,
        setSliceText = R.setSliceText, setSliceTexture = R.setSliceTexture,
        onMouseDown = R.onMouseDown, onJoypadButtonReleased = R.onJoypadButtonReleased,
        onGainJoypadFocus = R.onGainJoypadFocus,
    }
    R._zedOrig = O

    -- a plain element (drawn in Lua) in place of the engine's RadialMenu
    function R:instantiate()
        remember(self)
        if not ready() or ZeD.Safe.on() then return O.instantiate(self) end
        -- a mod's own wheel class (Smart Radial Menu's SRMMenuObject) draws itself over the
        -- engine's and calls its Java methods (getSliceIndexFromMouse ...): it stays the engine's
        local cls = getmetatable(self)
        if cls ~= ISRadialMenu and cls ~= ISBackButtonWheel then return O.instantiate(self) end
        self._zed = true
        self.zedScaled = true          -- ZeD borders scale with the root (Overrides/TextScale.lua)
        self.wantMouseEvents = true    -- the wheel takes its clicks, as the engine's did
        W.fit(self)
        ISUIElement.instantiate(self)
    end

    -- the slices live in Lua (the engine's copy only when the engine draws)
    function R:addSlice(text, texture, command, arg1, arg2, arg3, arg4, arg5, arg6)
        if engineSide(self) then
            return O.addSlice(self, text, texture, command, arg1, arg2, arg3, arg4, arg5, arg6)
        end
        local slice = { text = text, texture = texture, command = { command, arg1, arg2, arg3, arg4, arg5, arg6 } }
        table.insert(self.slices, slice)
        if ready() then W.fit(self) end
    end

    function R:clear()
        remember(self)   -- every show starts here: the wheel counts as just used
        if engineSide(self) then return O.clear(self) end
        self.slices = {}
        W.onClear(self)
    end

    function R:setSliceText(i, text)
        if engineSide(self) then return O.setSliceText(self, i, text) end
        if i < 1 or i > #self.slices then return end
        self.slices[i].text = text
        self.slices[i]._zedTex = nil
    end

    function R:setSliceTexture(i, texture)
        if engineSide(self) then return O.setSliceTexture(self, i, texture) end
        if i < 1 or i > #self.slices then return end
        self.slices[i].texture = texture
        self.slices[i]._zedTex = nil
    end

    -- the mouse: a press picks by direction (vanilla picks on the press too)
    function R:onMouseDown(x, y)
        if not self._zed then return O.onMouseDown(self, x, y) end
        if self.joyfocus then return end
        local i = W.sliceFromMouse(self, x, y)
        self:undisplay()
        if i > 0 then run(self, i) end
        return true
    end

    -- the controller: letting go of the button that opened it takes the slice the stick points at
    function R:onJoypadButtonReleased(button, joypadData)
        if not self._zed then return O.onJoypadButtonReleased(self, button, joypadData) end
        if button == self.hideWhenButtonReleased then
            local id = self.joyfocus and self.joyfocus.id or (joypadData and joypadData.id)
            local i = W.sliceFromJoypad(self, id)
            self:undisplay()
            if i > 0 then run(self, i) end
        end
    end

    function R:onGainJoypadFocus(joypadData)
        if not self._zed then return O.onGainJoypadFocus(self, joypadData) end
        ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    end

    -- the engine drew the wheel and never called these; ZeD's does
    function R:prerender()
        if not self._zed then return end
        local ok, err = pcall(W.draw, self)
        if not ok then ZeD.logOnce("Wheel: draw failed", err) end
    end
    function R:render() end
    function R:update()
        if not self._zed then return end
        W.update(self)
    end
end

-- ---------------------------------------------------------------------------
-- the wheels' slices that open a window ZeD has replaced
-- ---------------------------------------------------------------------------
local function openPair(playerNum)
    if not (ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad) then return false end
    local ok = pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, playerNum or 0)
    return ok and ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen() or false
end

local function openWorldTab(playerNum, tabId)
    if not (ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return false end
    local ok, done = pcall(ZeD_WorldWindow.openTab, playerNum or 0, tabId, true)
    return ok and done or false
end

local function hookRoutes()
    -- Player Info on the Back wheel: the Character window pair (vanilla opens its character info window)
    if ISBackButtonWheel and not ISBackButtonWheel._zedRoutes then
        ISBackButtonWheel._zedRoutes = true
        local orig = ISBackButtonWheel.onCommand
        ISBackButtonWheel.onCommand = function(self, command)
            if ZeD.Safe.on() then return orig(self, command) end
            local paused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
            if command == "PlayerInfo" and not paused and openPair(self.playerNum) then
                setJoypadFocus(self.playerNum, nil)
                return
            end
            return orig(self, command)
        end
    end
    -- the search window (Investigate This Area: the Back wheel, the screen icons): the Foraging tab
    if ISSearchWindow and ISSearchWindow.toggleWindow and not ISSearchWindow._zedRoute then
        ISSearchWindow._zedRoute = true
        local orig = ISSearchWindow.toggleWindow
        ISSearchWindow.toggleWindow = function(character)
            if ZeD.Safe.on() then return orig(character) end
            local pn = character and character.getPlayerNum and character:getPlayerNum() or 0
            if openWorldTab(pn, "forage") then return end
            return orig(character)
        end
    end
    -- the livestock zone panel (D-pad Right's Designated Zones, the screen icons): the Animals tab
    if ISDesignationZonePanel and ISDesignationZonePanel.toggleZoneUI and not ISDesignationZonePanel._zedRoute then
        ISDesignationZonePanel._zedRoute = true
        local orig = ISDesignationZonePanel.toggleZoneUI
        ISDesignationZonePanel.toggleZoneUI = function(playerNum)
            if ZeD.Safe.on() then return orig(playerNum) end
            if openWorldTab(playerNum, "animals") then return end
            return orig(playerNum)
        end
    end
    if ISDPadWheels and ISDPadWheels.showAnimalZoneUI and not ISDPadWheels._zedRoute then
        ISDPadWheels._zedRoute = true
        local orig = ISDPadWheels.showAnimalZoneUI
        ISDPadWheels.showAnimalZoneUI = function(playerNum)
            if ZeD.Safe.on() then return orig(playerNum) end
            if openWorldTab(playerNum, "animals") then return end   -- (vanilla's first-time zone note stays with its panel)
            return orig(playerNum)
        end
    end
end

local function apply()
    hookRadial()
    hookRoutes()
    ZeD.Safe.register("wheels", { leave = wheelsToVanilla, enter = wheelsToZed })
    if not _G._zedWheelsAnnounced then
        _G._zedWheelsAnnounced = true
        print("[ZeD] Overrides/Wheels: vanilla's radial wheels drawn as ZeD wheels; wheel slices route to ZeD windows")
    end
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
