-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Belt.lua
-- ============================================================================
-- HANDS + HOTBAR — HOOK_MAP rows 5 + 6 (the belt, ZeD_Belt.lua)
--
-- * ISHotbar keeps running as the data model (slots, attachments, clothing
--   refresh, the number keys) but no longer draws: its render / prerender are
--   empty and it is parked off-screen, so it never catches a click either.
-- * Holding a hotbar key opens the slot's list (ZeD.Belt.slotMenu, a context
--   menu above the slot) instead of vanilla's radial; the release that ends
--   the hold does not then draw the item.
-- * D-pad Left (vanilla's weapon wheel) focuses the belt on a controller.
-- * The vanilla left-edge column loses its hand slots (the belt shows the
--   hands); in single player without -debug the column itself goes once only
--   ZeD's replaced parts are left on it, since its window buttons were already
--   hidden (Overrides/ScreenIcons.lua). A button another mod added to the
--   column keeps it up. The multiplayer buttons (safety, user, admin, war)
--   stay until a multiplayer pass; Debug stays under -debug.
-- * The Tutorial keeps vanilla's column whole: its first lesson blinks the
--   heart button.
-- * Safe mode (SafeMode.lua, the "belt" hook) hands all of it back: vanilla's
--   hotbar methods (kept in ZeD.Safe._originals.ISHotbar) and its place on the
--   screen, the hand slots and the column, vanilla's hold-a-key radial and
--   D-pad Left; the belt hides.
-- ============================================================================

require "ZeD/ZeD_Belt"
require "ZeD/SafeMode"

local B = ZeD.Belt

-- the hold-a-key list: opened for this press, so its release is not a tap
local heldOpen = {}

local origKeyPressed, origKeepPressed

local function holdKeepPressed(key)
    -- safe mode: vanilla's own hold (its radial)
    if ZeD.Safe.on() then
        if origKeepPressed then return origKeepPressed(key) end
        return
    end
    local playerObj = getSpecificPlayer(0)
    local hb = getPlayerHotbar(0)
    if not hb or not playerObj or playerObj:isDead() then return end
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return end
    if JoypadState.players[1] then return end
    if playerObj:isAttacking() then return end
    local queue = ISTimedActionQueue.queues[playerObj]
    if queue and #queue.queue > 0 then return end
    local i = hb:getSlotForKey(key)
    if i == -1 or not hb.availableSlot[i] then return end
    if heldOpen[key] then return end
    if not hb.keyPressedMS or getTimestampMs() - hb.keyPressedMS <= 500 then return end
    local x, y = B.boxScreen(i)
    if not x then x, y = getMouseX(), getMouseY() end
    heldOpen[key] = true
    B.slotMenu(0, i, x, y)
end

-- The Tutorial teaches the heart button in vanilla's left-edge column (and
-- blinks it), so there vanilla's column stays exactly as it is.
local function inTutorial()
    return getCore():getGameMode() == "Tutorial"
end

-- The column's own children: the hands the belt shows, the window buttons
-- ZeD's tabs replace (Overrides/ScreenIcons.lua) and the hover pop-ups that
-- belong to them. Anything else on the column (a button another mod added,
-- vanilla's Debug button under forceEnable) is not ours to hide.
local COLUMN_OWN = { "mainHand", "offHand", "invBtn", "healthBtn", "craftingBtn", "buildBtn",
    "movableBtn", "searchBtn", "zoneBtn", "mapBtn", "movableTooltip", "movablePopup", "metaPopup", "mapPopup" }
-- frames the column waits before deciding, so other mods' hooks have added theirs
local COLUMN_SETTLE = 30

local function columnForeignVisible(panel)
    local own = {}
    for _, key in ipairs(COLUMN_OWN) do
        local v = panel[key]
        if v then own[v] = true end
    end
    if panel.children then
        for _, child in pairs(panel.children) do
            if not own[child] and child.getIsVisible and child:getIsVisible() then return true end
        end
    end
    return false
end

-- Single player without -debug: the column goes once nothing but ZeD's
-- replaced parts are left on it. Anything else showing keeps it up.
local function columnPrerender(self)
    if self._zedColKeep then return end
    local frames = (self._zedColFrames or 0) + 1
    self._zedColFrames = frames
    if frames < COLUMN_SETTLE then return end
    if frames == COLUMN_SETTLE and columnForeignVisible(self) then
        self._zedColKeep = true
        print("[ZeD] Overrides/Belt: the left-edge column has buttons from elsewhere; leaving it up")
        return
    end
    if self:getIsVisible() then
        self:setVisible(false)
        self._zedColHidden = true
    end
end

local function keyReleased(key)
    if heldOpen[key] then heldOpen[key] = nil; return end
    if origKeyPressed then return origKeyPressed(key) end
end

local swapped = false
local function swapKeyHandlers()
    if swapped or not ISHotbar then return end
    swapped = true
    origKeyPressed = ISHotbar.onKeyPressed
    origKeepPressed = ISHotbar.onKeyKeepPressed
    Events.OnKeyPressed.Remove(ISHotbar.onKeyPressed)
    Events.OnKeyKeepPressed.Remove(ISHotbar.onKeyKeepPressed)
    Events.OnKeyPressed.Add(keyReleased)
    Events.OnKeyKeepPressed.Add(holdKeepPressed)
end

-- the belt draws; vanilla's bar stays alive but out of sight and reach
local ZED_HOTBAR = {
    render = function(self) end,
    prerender = function(self) end,
    setSizeAndPosition = function(self)
        -- top-level panels clamp onto the screen unless told not to
        -- (ISUIElement:setX), which would leave it at the top-left corner
        self.keepOnScreen = false
        self:setX(-10000)
        self:setY(-10000)
    end,
}

-- each local player's hotbar / left-edge column
local function eachHotbar(fn)
    local n = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, math.max(n, 1) - 1 do
        local hb = getPlayerHotbar and getPlayerHotbar(i)
        if hb then pcall(fn, hb) end
    end
end
local function eachColumn(fn)
    local n = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, math.max(n, 1) - 1 do
        local pd = getPlayerData and getPlayerData(i)
        if pd and pd.equipped then pcall(fn, pd.equipped) end
    end
end

-- vanilla's three methods are kept (ZeD.Safe._originals.ISHotbar) the first time
local function parkHotbar()
    if not ISHotbar or ISHotbar._zedBelt then return end
    local O = ZeD.Safe._originals
    O.ISHotbar = O.ISHotbar or { render = ISHotbar.render, prerender = ISHotbar.prerender, setSizeAndPosition = ISHotbar.setSizeAndPosition }
    ISHotbar._zedBelt = true
    ISHotbar.render = ZED_HOTBAR.render
    ISHotbar.prerender = ZED_HOTBAR.prerender
    ISHotbar.setSizeAndPosition = ZED_HOTBAR.setSizeAndPosition
    eachHotbar(function(hb) hb:setSizeAndPosition() end)
end

local function unparkHotbar()
    local orig = ZeD.Safe._originals.ISHotbar
    if not (ISHotbar and ISHotbar._zedBelt and orig) then return end
    ISHotbar._zedBelt = nil
    ISHotbar.render = orig.render
    ISHotbar.prerender = orig.prerender
    ISHotbar.setSizeAndPosition = orig.setSizeAndPosition
    eachHotbar(function(hb) hb.keepOnScreen = nil; hb:setSizeAndPosition() end)
end

local function apply()
    if not ZeD.Safe.on() then parkHotbar() end
    if ISDPadWheels and not ISDPadWheels._zedBelt then
        ISDPadWheels._zedBelt = true
        local origLeft = ISDPadWheels.onDisplayLeft
        function ISDPadWheels.onDisplayLeft(joypadData)
            local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
            if not isPaused and joypadData and joypadData.player == 0 and not ZeD.Safe.on() then
                local ok, took = pcall(B.focus, 0)
                if ok and took then return end
            end
            return origLeft(joypadData)
        end
    end
    if ISEquippedItem and not ISEquippedItem._zedBelt then
        ISEquippedItem._zedBelt = true
        local origRender = ISEquippedItem.render
        -- vanilla's render without the hand items (the belt shows them): the
        -- heart's shake on damage, the debug text, the button tooltips, FPS
        function ISEquippedItem:render()
            if ZeD.Safe.on() or inTutorial() then return origRender(self) end   -- safe mode and the Tutorial: vanilla's, hands and all
            if self.mainHand and self.mainHand:getIsVisible() then self.mainHand:setVisible(false) end
            if self.offHand and self.offHand:getIsVisible() then self.offHand:setVisible(false) end
            -- the hands leave the hover list too (it tests bounds, not visibility;
            -- vanilla's whole list is kept for safe mode to put back)
            if self.mouseOverList and not self._zedHandsOut then
                self._zedOverAll = self._zedOverAll or self.mouseOverList
                local keep = {}
                for _, v in ipairs(self.mouseOverList) do
                    if v.object ~= self.mainHand and v.object ~= self.offHand then keep[#keep + 1] = v end
                end
                self.mouseOverList = keep
                self._zedHandsOut = true
            end
            local bd = self.chr:getBodyDamage()
            if bd:getHealth() ~= self.previousHealth then
                if self.previousHealth > bd:getHealth() then self.healthIconOscillatorLevel = 1 end
                self.previousHealth = bd:getHealth()
            end
            if self.healthBtn and self.healthIconOscillatorLevel > 0.01 then
                local fpsFrac = (UIManager.getMillisSinceLastRender() / 33.3) * 0.5
                self.healthIconOscillatorLevel = self.healthIconOscillatorLevel * self.healthIconOscillatorDecelerator
                self.healthIconOscillatorLevel = self.healthIconOscillatorLevel - (self.healthIconOscillatorLevel * (1 - self.healthIconOscillatorDecelerator) * fpsFrac)
                self.healthIconOscillatorStep = self.healthIconOscillatorStep + self.healthIconOscillatorRate * fpsFrac
                self.healthIconOscillator = math.sin(self.healthIconOscillatorStep)
                self.healthBtn:setX(self.healthIconOscillator * self.healthIconOscillatorLevel * self.healthIconOscillatorScalar)
            elseif self.healthBtn and self.healthIconOscillatorLevel < 0.01 then
                self.healthIconOscillatorLevel = 0
                self.healthBtn:setX(self.healthIconOscillator * self.healthIconOscillatorLevel * self.healthIconOscillatorScalar)
            end
            if self.invBtn == nil then return end
            if ISEquippedItem.text then
                self:drawText(ISEquippedItem.text, self:getRight(), 0, 1, 1, 1, 1, UIFont.Medium)
            end
            self:checkToolTip()
            self:renderFPS()
        end
        local origPre = ISEquippedItem.prerender
        function ISEquippedItem:prerender()
            origPre(self)
            if ZeD.Safe.on() or inTutorial() then return end
            -- single player without -debug: the column goes when nothing but
            -- ZeD's replaced parts is left on it
            if not isClient() and not getCore():getDebug() then columnPrerender(self) end
        end
        -- a button added to the column after it was put away brings it back
        local origAddChild = ISEquippedItem.addChild
        function ISEquippedItem:addChild(child)
            origAddChild(self, child)
            if self._zedColHidden and child and child.getIsVisible and child:getIsVisible() then
                self._zedColKeep = true
                self._zedColHidden = nil
                if not (ISUIHandler and ISUIHandler.allUIVisible == false) then self:setVisible(true) end
            end
        end
    end
    if getPlayerHotbar and getPlayerHotbar(0) then swapKeyHandlers() end
    print("[ZeD] Overrides/Belt: hotbar and hand slots routed to the belt")
end

-- Safe mode (SafeMode.lua): vanilla's bar back in its place, the hand slots
-- and the column showing again with vanilla's whole hover list, the belt hidden
-- (its wanted() says no while safe). Taking over again parks the bar; the hands,
-- the column and their hover list go again on their next frame.
ZeD.Safe.register("belt", {
    leave = function()
        unparkHotbar()
        eachColumn(function(eq)
            if eq._zedOverAll then eq.mouseOverList = eq._zedOverAll; eq._zedOverAll = nil end
            eq._zedHandsOut = nil
            eq._zedColFrames, eq._zedColKeep, eq._zedColHidden = nil, nil, nil
            if eq.mainHand then eq.mainHand:setVisible(true) end
            if eq.offHand then eq.offHand:setVisible(true) end
            if not (ISUIHandler and ISUIHandler.allUIVisible == false) then eq:setVisible(true) end
        end)
        local hud = B._hud
        if hud then
            hud:setVisible(false)
            hud._drawn = false
        end
    end,
    enter = function()
        parkHotbar()
    end,
})

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
-- vanilla registers the hotbar's key handlers in OnGameStart (earlier files
-- first), so the swap runs in ours
Events.OnGameStart.Add(function() apply(); swapKeyHandlers() end)
apply()
