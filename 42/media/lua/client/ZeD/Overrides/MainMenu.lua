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
--
-- While ZeD's safe mode is on, all of it steps aside: MainScreen is vanilla's
-- (its logo, labels, extras, keys and controller, its own Options screen,
-- where Options > Mods > ZeD UI turns safe mode off again). A menu built in
-- safe mode gets ZeD's desk or pause window when safe mode goes off; one that
-- had them hands them back when it comes on, and takes them again after.
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
require "ZeD/SafeMode"
require "OptionScreens/MainOptions"

-- Another mod's broken setting must not stop the game's options screen from building:
-- vanilla builds it inside MainScreen:instantiate, so one error there also leaves the
-- main screen half built and the pause menu dead (Oct 24 2026: Change Sandbox Options
-- (by Star) adds a key binding with no key; vanilla's getKeyName(nil) threw in
-- addModOptionsPanel, on the stack under Project A-Life's addPanels).
-- A key binding without a usable key becomes "no key" (named in the log), and an error
-- left on that page is caught there, so the rest of the screens still build.
do
    local inner = MainOptions and MainOptions.addModOptionsPanel
    if inner and not MainOptions._zedGuarded then
        MainOptions._zedGuarded = true
        MainOptions.addModOptionsPanel = function(self, ...)
            pcall(function()
                for _, mod in ipairs(PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.Data or {}) do
                    for _, o in ipairs(mod.data or {}) do
                        if o.type == "keybind" and tonumber(o.key) == nil then
                            print("[ZeD] Mod options: " .. tostring(mod.name) .. " | " .. tostring(o.name) .. " has no key; shown as no key")
                            o.key = 0
                        end
                    end
                end
            end)
            local ok, err = pcall(inner, self, ...)
            if not ok then print("[ZeD] Mod options: the game's Mods page stopped on another mod's setting (" .. tostring(err) .. "); the other screens still build") end
        end
    end
end

local MM = ZeD.MainMenu
local Safe = ZeD.Safe

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

-- ZeD's desk (main menu) or pause window (in game) onto this MainScreen, once
local function attachZeD(m)
    if not m or m._zedAttached then return end
    m._zedAttached = true
    local ok, err = pcall(MM.attach, m)
    if not ok then print("[ZeD] main menu: attach failed: " .. tostring(err)) end
end

-- ---------------------------------------------------------------------------
-- SAFE MODE: handing MainScreen back to vanilla, and taking it again
-- ---------------------------------------------------------------------------
-- vanilla's extras that follow its bottom panel (ZeD hides them while its menu shows)
local SAFE_EXTRAS = { "reportBug", "termsOfService", "resetLua", "modListDetail", "seedLabel" }
-- what MM.hookOptions put on vanilla's options screen (its Options turn into ZeD's window)
local OPTION_HOOKS = { "close", "setVisible", "showConfirmMonitorSettingsDialog", "showRestartRequiredDialog" }

local function handBack()
    -- the desk goes, and with MM.root gone the screens ZeD redirects (New Game, Load,
    -- Mods, ...) show as vanilla's again, and a game start skips the switch-off
    if MM.root then
        MM._zedSafeRoot = MM.root
        MM.root:setVisible(false)
        MM.root = nil
    end
    if MM.ctx then MM.ctx.open, MM.ctx.hot, MM.ctx.press = nil, nil, nil end
    -- the pause window, ZeD's Options over the world and its pull-down
    if MM.pause and MM.pause:isVisible() then MM.pause:setVisible(false) end
    if MM.pauseOpts and MM.pauseOpts:isVisible() then MM.pauseOpts:setVisible(false) end
    if MM.igDrop and MM.igDrop:isVisible() then MM.igDrop:setVisible(false) end
    MM.pauseView = "pause"
    local m = MainScreen.instance
    if not m then return end
    local bp = m.bottomPanel
    if bp then
        -- vanilla's labels back from off the screen, and its extras with them
        if bp:getX() <= -10000 then bp:setX(m._zedBottomX or 100) end
        local vis = bp:isVisible()
        for _, k in ipairs(SAFE_EXTRAS) do
            local e = m[k]
            if e and e.setVisible then e:setVisible(vis) end
        end
        if not m.inGame and getDebug() and DebugScenarios and DebugScenarios.instance then DebugScenarios.instance:setVisible(vis) end
    end
    -- a screen ZeD keeps showing off the screen (its view mirrors it) comes back
    for _, v in ipairs(MM.views or {}) do
        local s = v.mirror and v.screen and m[v.screen]
        if s and s:getX() <= -10000 then s:setX(s._zedX or 0) end
    end
    -- vanilla's own Options screen (Options > Mods > ZeD UI is how safe mode goes off)
    local o = m.mainOptions
    if o and o._zedHooked and not o._zedSafeHooks then
        local kept = {}
        for _, k in ipairs(OPTION_HOOKS) do kept[k] = rawget(o, k); rawset(o, k, nil) end
        o._zedSafeHooks = kept
        MM._vanillaOptions = nil
    end
end

local function takeOver()
    local m = MainScreen.instance
    local o = m and m.mainOptions
    if o and o._zedSafeHooks then
        for k, fn in pairs(o._zedSafeHooks) do rawset(o, k, fn) end
        o._zedSafeHooks = nil
    end
    -- the desk again (MainScreen's prerender shows it when the menu is up)
    if MM._zedSafeRoot and not MM.root then MM.root = MM._zedSafeRoot end
    MM._zedSafeRoot = nil
    -- a menu built in safe mode gets ZeD's now
    if m and not m._zedAttached then attachZeD(m) end
end

Safe.register("main menu", { leave = handBack, enter = takeOver })

function MainScreen:instantiate()
    -- another mod's step in this chain may fail after vanilla's built the screen (Oct 24 2026:
    -- Change Sandbox Options (by Star) reads a quitToDesktop button 42.21 no longer makes); its
    -- error must not leave the screen without ZeD's desk or pause window
    local ok, err = pcall(O.instantiate, self)
    if not ok then print("[ZeD] Main menu: another mod's part of the main screen failed (" .. tostring(err) .. "); ZeD's menu is built anyway") end
    self._zedBottomX = self.bottomPanel and self.bottomPanel:getX()
    -- vanilla's options screen was just built, and with it the saved options read: Safe mode now
    Safe.reread()
    if Safe.on() then return end
    attachZeD(self)
end

-- safe mode: vanilla's OPTIONS and CREDITS items (ZeD_MainMenuOptions.lua turns them into ZeD's)
if MainScreen.onMenuItemMouseDownMainMenu ~= MainScreen._zedSafeItem then
    MainScreen._zedSafeItemInner = MainScreen.onMenuItemMouseDownMainMenu
    MainScreen._zedSafeItem = function(item, x, y)
        if Safe.on() and MainScreen._zedItemOrig then return MainScreen._zedItemOrig(item, x, y) end
        return MainScreen._zedSafeItemInner(item, x, y)
    end
    MainScreen.onMenuItemMouseDownMainMenu = MainScreen._zedSafeItem
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

-- (safe mode: each of these is vanilla's own, with nothing of ZeD's before or after it)
function MainScreen:prerender()
    if Safe.on() then return O.prerender(self) end
    if MM.isUp(self) and not isDemo() then
        prerenderOwn(self)
    else
        O.prerender(self)
    end
    MM.afterPrerender(self)
end

function MainScreen:render()
    if Safe.on() then return O.render(self) end
    O.render(self)
    if MM.isUp(self) then MM.hideExtras(self) end   -- vanilla re-shows the version button here every frame
end

function MainScreen:onGainJoypadFocus(joypadData)
    if Safe.on() then return O.onGainJoypadFocus(self, joypadData) end
    O.onGainJoypadFocus(self, joypadData)
    if MM.isUp(self) then MM.joyFocus(self) end
end

function MainScreen:onJoypadDown(button, joypadData)
    if Safe.on() then return O.onJoypadDown(self, button, joypadData) end
    if MM.isUp(self) then return MM.joyDown(self, button) end
    return O.onJoypadDown(self, button, joypadData)
end

function MainScreen:onJoypadDirUp(joypadData)
    if Safe.on() then return O.onJoypadDirUp(self, joypadData) end
    if MM.isUp(self) then return MM.joyDir(self, "up") end
    return O.onJoypadDirUp(self, joypadData)
end

function MainScreen:onJoypadDirDown(joypadData)
    if Safe.on() then return O.onJoypadDirDown(self, joypadData) end
    if MM.isUp(self) then return MM.joyDir(self, "down") end
    return O.onJoypadDirDown(self, joypadData)
end

function MainScreen:onJoypadDirLeft(joypadData)
    if Safe.on() then if O.onJoypadDirLeft then return O.onJoypadDirLeft(self, joypadData) end; return end
    if MM.isUp(self) then return MM.joyDir(self, "left") end
    if O.onJoypadDirLeft then return O.onJoypadDirLeft(self, joypadData) end
end

function MainScreen:onJoypadDirRight(joypadData)
    if Safe.on() then if O.onJoypadDirRight then return O.onJoypadDirRight(self, joypadData) end; return end
    if MM.isUp(self) then return MM.joyDir(self, "right") end
    if O.onJoypadDirRight then return O.onJoypadDirRight(self, joypadData) end
end

function MainScreen:onKeyRelease(key)
    if Safe.on() then return O.onKeyRelease(self, key) end
    if MM.keyRelease(self, key) then return end
    return O.onKeyRelease(self, key)
end
