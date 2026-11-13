-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_PadEntry.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the controller's way in: a slice on the game's Back button
-- wheel, where ZeD-GUI has a slice on its own wheel.
-- Written by ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change the tool and build
-- again.
-- ============================================================================================================

-- With ZeD-GUI on (mod ZeD_UI; the game can put a backslash before a mod's id), ZeD-GUI's console is the one:
-- this file stops here and defines nothing.
do
    local guiOn = false
    pcall(function()
        local mods = getActivatedMods()
        for i = 0, mods:size() - 1 do
            if string.gsub(tostring(mods:get(i)), "^\\", "") == "ZeD_UI" then guiOn = true end
        end
    end)
    if guiOn then return end
end

require "ISUI/ISBackButtonWheel"

LC93 = LC93 or {}

-- In debug mode, with the game's console made, the game's Back button wheel (ISBackButtonWheel) gets one more slice:
-- the console, opened with the controller in it, as the wheel's own slices open their windows. The keyboard's way in
-- is the game's own key. Keep the game's addCommands once, so a Lua reload never wraps the wrapper.
-- While the game is paused the slice is left off, as the game leaves off its own window slices (Player Info,
-- Crafting): a paused game drops every button but the D-pad for a window holding the controller
-- (JoypadControllerData:onPressButton), so the console could be neither typed in nor closed.
local function paused()
    local ok, yes = pcall(function()
        local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
        if sc and sc:getCurrentGameSpeed() == 0 then return true end
        return isGamePaused ~= nil and isGamePaused() == true
    end)
    return ok and yes == true
end
local function consoleHere()
    local DC = LC93.DebugConsole
    return DC and DC.exists and DC.exists()
end
if ISBackButtonWheel and not ISBackButtonWheel._lc93Orig then
    ISBackButtonWheel._lc93Orig = ISBackButtonWheel.addCommands
    function ISBackButtonWheel:addCommands()
        ISBackButtonWheel._lc93Orig(self)
        local DC = LC93.DebugConsole
        local ok, here = pcall(consoleHere)
        if ok and here and not paused() then
            local pn = self.playerNum
            self:addSlice(LC93.tr("UI_LC93_Console_Title"), getTexture("media/textures/LuaConsole93/console_slice.png"), function() DC.open(pn) end)
        end
    end
end
