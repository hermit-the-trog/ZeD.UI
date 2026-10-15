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
--   hands); in single player without -debug the whole column goes, since its
--   window buttons were already hidden (Overrides/ScreenIcons.lua). The
--   multiplayer buttons (safety, user, admin, war) stay until a multiplayer
--   pass; Debug stays under -debug.
-- ============================================================================

require "ZeD/ZeD_Belt"

local B = ZeD.Belt

-- the hold-a-key list: opened for this press, so its release is not a tap
local heldOpen = {}

local function holdKeepPressed(key)
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

local origKeyPressed
local function keyReleased(key)
    if heldOpen[key] then heldOpen[key] = nil; return end
    if origKeyPressed then return origKeyPressed(key) end
end

local swapped = false
local function swapKeyHandlers()
    if swapped or not ISHotbar then return end
    swapped = true
    origKeyPressed = ISHotbar.onKeyPressed
    Events.OnKeyPressed.Remove(ISHotbar.onKeyPressed)
    Events.OnKeyKeepPressed.Remove(ISHotbar.onKeyKeepPressed)
    Events.OnKeyPressed.Add(keyReleased)
    Events.OnKeyKeepPressed.Add(holdKeepPressed)
end

local function apply()
    if ISHotbar and not ISHotbar._zedBelt then
        ISHotbar._zedBelt = true
        -- the belt draws; vanilla's bar stays alive but out of sight and reach
        function ISHotbar:render() end
        function ISHotbar:prerender() end
        function ISHotbar:setSizeAndPosition()
            -- top-level panels clamp onto the screen unless told not to
            -- (ISUIElement:setX), which would leave it at the top-left corner
            self.keepOnScreen = false
            self:setX(-10000)
            self:setY(-10000)
        end
    end
    if ISDPadWheels and not ISDPadWheels._zedBelt then
        ISDPadWheels._zedBelt = true
        local origLeft = ISDPadWheels.onDisplayLeft
        function ISDPadWheels.onDisplayLeft(joypadData)
            local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
            if not isPaused and joypadData and joypadData.player == 0 then
                local ok, took = pcall(B.focus, 0)
                if ok and took then return end
            end
            return origLeft(joypadData)
        end
    end
    if ISEquippedItem and not ISEquippedItem._zedBelt then
        ISEquippedItem._zedBelt = true
        -- vanilla's render without the hand items (the belt shows them): the
        -- heart's shake on damage, the debug text, the button tooltips, FPS
        function ISEquippedItem:render()
            if self.mainHand and self.mainHand:getIsVisible() then self.mainHand:setVisible(false) end
            if self.offHand and self.offHand:getIsVisible() then self.offHand:setVisible(false) end
            -- the hands leave the hover list too (it tests bounds, not visibility)
            if self.mouseOverList and not self._zedHandsOut then
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
            -- single player without -debug: nothing left in the column
            if not isClient() and not getCore():getDebug() and self:getIsVisible() then self:setVisible(false) end
        end
    end
    if getPlayerHotbar and getPlayerHotbar(0) then swapKeyHandlers() end
    print("[ZeD] Overrides/Belt: hotbar and hand slots routed to the belt")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
-- vanilla registers the hotbar's key handlers in OnGameStart (earlier files
-- first), so the swap runs in ours
Events.OnGameStart.Add(function() apply(); swapKeyHandlers() end)
apply()
