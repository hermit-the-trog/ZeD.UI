-- ZeD-UI/42/media/lua/client/ZeD/Overrides/MainMenu.lua
-- ============================================================================
-- MAIN MENU + PAUSE MENU — HOOK_MAP row 26 (ZeD_MainMenu.lua draws them)
--
-- Vanilla's MainScreen keeps running: its items, sub-screens, joypad focus
-- and Escape handling are untouched. The hooks only
--   * attach the desk (main menu) or the pause window (in game) when it builds,
--   * skip the logo while our menu shows (the desk covers the screen; the
--     pause window stands alone over the dimmed world),
--   * park the vanilla labels off-screen and hide the version / legal /
--     report-bug / mods / seed extras while our menu shows,
--   * hand the controller's D-pad, A, B and Y to our window while it shows,
--   * let Escape close an open menu or question first.
-- Whenever vanilla hides its bottom panel (another screen is up: Load, New
-- Game, Options, Mods, ...), everything here steps aside and vanilla draws.
-- ============================================================================

require "OptionScreens/MainScreen"
require "OptionScreens/LoadGameScreen"
require "OptionScreens/NewGameScreen"
require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuMods"
require "ZeD/ZeD_MainMenuOptions"
require "ZeD/ZeD_MainMenuSpawn"
require "ZeD/ZeD_MainMenuSandbox"
require "ZeD/ZeD_MainMenuTraits"
require "ZeD/ZeD_MainMenuLooks"
require "ZeD/ZeD_MainMenuCredits"
require "ZeD/ZeD_MainMenuJoin"
require "ZeD/ZeD_MainMenuHost"
require "ZeD/ZeD_MainMenuServer"

local MM = ZeD.MainMenu

-- Vanilla's host screen (built inside MainScreen:instantiate) asks for the colour
-- "ProgressYellow", which 42.21 does not have. Its warning walks the Lua stack, and
-- with the instantiate hook below on that stack the engine marks ZeD UI "[ERRORS]"
-- in the pause screen's mod list (KB Q230). That one colour is answered quietly; any
-- other name goes on to vanilla's lookup (a tail call: this frame leaves the stack).
local QUIET_COLORS = { ProgressYellow = { r = 0.93, g = 0.76, b = 0.18, a = 1 } }
_G._zedNamedColor = _G._zedNamedColor or namedColorToTable
function namedColorToTable(name)
    local q = QUIET_COLORS[name]
    if q and not Colors.GetColorByName(name) then return { r = q.r, g = q.g, b = q.b, a = q.a } end
    return _G._zedNamedColor(name)
end

-- the originals, captured once (a Lua reload of this file must not wrap the wrappers)
MainScreen._zedOrig = MainScreen._zedOrig or {
    instantiate       = MainScreen.instantiate,
    prerender         = MainScreen.prerender,
    render            = MainScreen.render,
    onGainJoypadFocus = MainScreen.onGainJoypadFocus,
    onJoypadDown      = MainScreen.onJoypadDown,
    onJoypadDirUp     = MainScreen.onJoypadDirUp,
    onJoypadDirDown   = MainScreen.onJoypadDirDown,
    onJoypadDirLeft   = MainScreen.onJoypadDirLeft,    -- ISPanelJoypad's (MainScreen inherits it)
    onJoypadDirRight  = MainScreen.onJoypadDirRight,
    onKeyRelease      = MainScreen.onKeyRelease,
}
local O = MainScreen._zedOrig

function MainScreen:instantiate()
    O.instantiate(self)
    local ok, err = pcall(MM.attach, self)
    if not ok then print("[ZeD] main menu: attach failed: " .. tostring(err)) end
end

-- Vanilla's prerender minus the logo: on the main menu the desk covers the screen; in game
-- the pause window sits alone over the dimmed world (vanilla's dim and quit-cooldown greys stay).
local function prerenderOwn(self)
    ISPanel.prerender(self)
    if self.inGame then
        self:drawRect(0, 0, self.width, self.height, 0.5, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
        local c = isQuitCooldown() and 0.5 or 1
        if self.exitOption then self.exitOption:setColor(c, c, c) end
        if self.quitToDesktopOption then self.quitToDesktopOption:setColor(c, c, c) end
    end
    if self.delay > 0 then
        if self.firstFrame then
            self.delay = self.delay - UIManager.getMillisSinceLastRender()
        else
            self.firstFrame = true
        end
    end
    self.time = self.time + ((1.0 / 60) * getGameTime():getMultiplier())
    self.warningFade = math.max(0, self.warningFade - ((1.5 / 60) * getGameTime():getMultiplier()))
end

function MainScreen:prerender()
    if MM.isUp(self) and not isDemo() then
        prerenderOwn(self)
    else
        O.prerender(self)
    end
    MM.afterPrerender(self)
end

function MainScreen:render()
    O.render(self)
    if MM.isUp(self) then MM.hideExtras(self) end   -- vanilla re-shows the version button here every frame
end

function MainScreen:onGainJoypadFocus(joypadData)
    O.onGainJoypadFocus(self, joypadData)
    if MM.isUp(self) then MM.joyFocus(self) end
end

function MainScreen:onJoypadDown(button, joypadData)
    if MM.isUp(self) then return MM.joyDown(self, button) end
    return O.onJoypadDown(self, button, joypadData)
end

function MainScreen:onJoypadDirUp(joypadData)
    if MM.isUp(self) then return MM.joyDir(self, "up") end
    return O.onJoypadDirUp(self, joypadData)
end

function MainScreen:onJoypadDirDown(joypadData)
    if MM.isUp(self) then return MM.joyDir(self, "down") end
    return O.onJoypadDirDown(self, joypadData)
end

function MainScreen:onJoypadDirLeft(joypadData)
    if MM.isUp(self) then return MM.joyDir(self, "left") end
    if O.onJoypadDirLeft then return O.onJoypadDirLeft(self, joypadData) end
end

function MainScreen:onJoypadDirRight(joypadData)
    if MM.isUp(self) then return MM.joyDir(self, "right") end
    if O.onJoypadDirRight then return O.onJoypadDirRight(self, joypadData) end
end

function MainScreen:onKeyRelease(key)
    if MM.keyRelease(self, key) then return end
    return O.onKeyRelease(self, key)
end
