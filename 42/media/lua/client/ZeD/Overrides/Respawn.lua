-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Respawn.lua
-- ============================================================================
-- BACK TO THE DESK: A NEW SURVIVOR AFTER A DEATH, OR A NEW SPLIT-SCREEN PLAYER
-- (HOOK_MAP row 19b; VANILLA_WINDOWS_20261107.md B3; the director, Nov 7 2026:
-- "back to the desk; the next survivor is built in ZeD's own Looks, Traits and
-- Spawn screens, as a new game")
--
-- Both of the game's ways to make a character in a running game go through
-- CoopCharacterCreation: Restart on the death screen (ISPostDeathUI:onRespawn,
-- ZeD's alert in Overrides/PostDeath.lua calls it) and a second controller's
-- "Add new player" (ISJoypadListBox:cmdAddNew). Its four screens are the
-- game's respawn screens: CoopUserName (a second player's name on a server),
-- CoopMapSpawnSelect, CoopCharacterCreationProfession, CoopCharacterCreationMain.
--
-- Vanilla's CoopCharacterCreation stays the engine, as MapSpawnSelect,
-- CharacterCreationProfession and CharacterCreationMain are on the main menu:
-- its screens are built and kept hidden, they keep every rule (the towns and
-- the "with player" places, the server's spawn point and safehouse, points,
-- clothing for the occupation) and its accept makes the character exactly as
-- before: the same world and save in single player (setPlayerMouse /
-- setPlayerJoypad), the same connection on a server. Its cancel puts the death
-- screen back. What shows is ZeD's: the desk is built over the world (the
-- room, the monitor, the menu bar with only the ZeD menu's About block) and
-- the monitor switches on to ZeD's Spawn, Traits and Looks windows, each
-- through the same redirect the main menu uses (MM.redirect: the screen's
-- setVisible(true) lands on the view; the view's Next and Back are the
-- screen's own).
--
-- The one step with no ZeD window, CoopUserName, shows as the game's over the
-- world, and the desk comes back with the next step. Another mod that shows a
-- respawn screen of the game's own (MM.redirectPass) gets the same.
--
-- Keys: the desk takes Escape (each window's Back) and Return (Next / Play)
-- when the respawning player is on the mouse; a controller drives it the way
-- it drives the main menu (A, B, X, Y, the bumpers, the D-pad).
--
-- Safe mode: nothing here runs and the game's screens show. When safe mode
-- comes on while the desk is up, the respawn steps back to the death screen
-- (the game's own then) and Restart builds the game's screens.
-- ============================================================================

require "ISUI/ISPanelJoypad"
require "OptionScreens/CoopCharacterCreation"
require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuSpawn"
require "ZeD/ZeD_MainMenuTraits"
require "ZeD/ZeD_MainMenuLooks"
require "ZeD/SafeMode"

if not CoopCharacterCreation then return end

ZeD = ZeD or {}
ZeD.Respawn = ZeD.Respawn or {}
local R = ZeD.Respawn
local MM = ZeD.MainMenu

-- the game's respawn screens with a ZeD window, and the view each lands on
local SCREENS = { { "mapSpawnSelect", "spawn" }, { "charCreationProfession", "traits" }, { "charCreationMain", "looks" } }
local VIEWS = { spawn = true, traits = true, looks = true }
-- every screen of the game's that can show (the one without a ZeD window first)
local ALL = { "coopUserName", "mapSpawnSelect", "charCreationProfession", "charCreationMain" }
local OFF = -20000   -- the game's panel waits here, off the screen, while the desk shows
-- what MM.joyDown / MM.joyDir / MM.window read for the desk (the view's window takes the controller)
local JOY = { inGame = false, respawn = true }
R.JOY = JOY

-- vanilla's, kept once (a Lua reload of this file must not keep ZeD's as "vanilla")
CoopCharacterCreation._zedOrig = CoopCharacterCreation._zedOrig or {
    createChildren = CoopCharacterCreation.createChildren,
    accept         = CoopCharacterCreation.accept,
    cancel         = CoopCharacterCreation.cancel,
    prerender      = rawget(CoopCharacterCreation, "prerender"),   -- (nil: ISPanelJoypad's)
}
local O = CoopCharacterCreation._zedOrig

-- ============================================================================
-- THE DESK IN GAME: the main menu's room, its menu bar and the three windows
-- ============================================================================
ZeD_MMRespawnDesk = ZeD_MMDesk:derive("ZeD_MMRespawnDesk")

function ZeD_MMRespawnDesk:new()
    local o = ZeD_MMDesk.new(self)
    o.respawn = true
    return o
end

function ZeD_MMRespawnDesk:createChildren()
    self.bar = ZeD_MMBar:new()
    self.bar:initialise()
    self:addChild(self.bar)
    -- only the windows a new survivor goes through (the main menu's others stay on the main menu)
    for _, v in ipairs(MM.views) do
        if VIEWS[v.view] then
            local w = v.make()
            w:initialise()
            self:addChild(w)
            w:setVisible(false)
            self[v.field] = w
        end
    end
    self.drop = ZeD_MMDrop:new()
    self.drop:initialise()
    self:addChild(self.drop)
    self.drop:setVisible(false)
    self.glass = ZeD_MMGlass:new()
    self.glass:initialise()
    self:addChild(self.glass)
    self.wake = ZeD_MMWake:new()     -- (dark until the pictures are in; then the monitor switches on)
    self.wake:initialise()
    self:addChild(self.wake)
end

function ZeD_MMRespawnDesk:prerender()
    ZeD_MMDesk.prerender(self)
    self._hits = {}   -- (no power button: nothing on this desk leaves the game)
end

function ZeD_MMRespawnDesk:update()
    ISPanel.update(self)
    local v = MM.view
    for _, rv in ipairs(MM.views) do
        local w = self[rv.field]
        if w and w:isVisible() ~= (v == rv.view) then w:setVisible(v == rv.view) end
    end
    if not MM.waking and not MM.poweringOn() then MM.pointer(MM.ctx, { self.drop, MM.activeWindow(), self.bar, self }) end
    local open = MM.ctx.open ~= nil
    if self.drop and self.drop:isVisible() ~= open then self.drop:setVisible(open) end
end

-- the respawning player's controller (the windows pick their own first focus as they show)
function ZeD_MMRespawnDesk:onJoypadDown(button, joypadData) MM.joyDown(JOY, button) end
function ZeD_MMRespawnDesk:onJoypadDirUp(joypadData) MM.joyDir(JOY, "up") end
function ZeD_MMRespawnDesk:onJoypadDirDown(joypadData) MM.joyDir(JOY, "down") end
function ZeD_MMRespawnDesk:onJoypadDirLeft(joypadData) MM.joyDir(JOY, "left") end
function ZeD_MMRespawnDesk:onJoypadDirRight(joypadData) MM.joyDir(JOY, "right") end

-- ============================================================================
-- STARTING, KEEPING IN STEP, FINISHING
-- ============================================================================
-- The desk goes up as the game builds its respawn screens, before the first of them shows.
function R.begin(coop)
    if MM.root or MM.respawn then return false end   -- (a desk is already up)
    local m = MainScreen and MainScreen.instance
    if not m then return false end
    local r = { coop = coop, joypadData = coop.joypadData, playerIndex = coop.playerIndex, ms = m, hadMain = rawget(m, "charCreationMain") }
    MM.respawn = r
    -- the views find the game's screens where they find the main menu's (the game itself sets
    -- MainScreen.instance.desc and .charCreationProfession here; the looks screen it leaves out)
    m.charCreationMain = coop.charCreationMain
    for _, s in ipairs(SCREENS) do MM.redirect(coop[s[1]], s[2]) end
    MM.view = nil
    MM.ctx.open, MM.ctx.hot, MM.ctx.press, MM.ctx.dragHit = nil, nil, nil, nil
    MM._framing, MM._dip, MM.powerOn, MM.powerOff = nil, nil, nil, nil
    local desk = ZeD_MMRespawnDesk:new()
    desk:initialise()
    desk:addToUIManager()
    desk:setVisible(false)   -- (up with its first window: MM.showView)
    r.desk = desk
    MM.root = desk
    coop.keepOnScreen = false   -- (a panel with no parent is kept on the screen: ISUIElement:setX)
    coop:setX(OFF)
    return true
end

-- The desk comes down: the character was made, the player went back to the death screen, or
-- ZeD stepped aside. The game's panel finishes on its own.
function R.finish()
    local r = MM.respawn
    if not r then return end
    MM.respawn = nil
    local desk = r.desk
    if MM.root == desk then MM.root = nil end
    if MM._zedSafeRoot == desk then MM._zedSafeRoot = nil end   -- (safe mode's hand-back kept it to bring back)
    if desk then
        pcall(MM.unfocusEntries, desk)
        desk:setVisible(false)
        desk:removeFromUIManager()
    end
    if r.ms then r.ms.charCreationMain = r.hadMain end
    if r.joypadData and desk and r.joypadData.focus == desk then r.joypadData.focus = nil end
    MM.view = "main"
    MM.ctx.open, MM.ctx.hot, MM.ctx.press, MM.ctx.dragHit = nil, nil, nil, nil
    MM._framing, MM._dip, MM.powerOn = nil, nil, nil
    MM.waking = false
end

-- Every frame of the game's panel: a screen of the game's own showing (the name step, or a
-- mod's) shows over the world and the desk steps back; otherwise the panel waits off the screen.
function R.sync(coop)
    local r = MM.respawn
    if not r or r.coop ~= coop then return end
    if ZeD.Safe.on() then
        -- safe mode came on: back to the death screen (the game's own now); Restart builds the game's screens
        if not r.cancelling then r.cancelling = true; coop:cancel() end
        return
    end
    local up = false
    for _, k in ipairs(ALL) do
        local s = coop[k]
        if s and s:isVisible() then up = true end
    end
    if up then
        if coop:getX() ~= 0 then coop:setX(0) end
        if r.desk and r.desk:isVisible() then r.desk:setVisible(false) end
    elseif coop:getX() ~= OFF then
        coop:setX(OFF)
    end
end

-- ============================================================================
-- THE GAME'S RESPAWN PANEL, HOOKED
-- ============================================================================
function CoopCharacterCreation:createChildren()
    O.createChildren(self)
    if ZeD.Safe.on() or not (ZeD.T and MM and MM.redirect and ZeD_MMDesk) then return end
    local ok, err = pcall(R.begin, self)
    if not ok then
        print("[ZeD] respawn: ZeD's screens could not be built (" .. tostring(err) .. "); the game's own show")
        pcall(R.finish)
        pcall(function() self:setX(0) end)
    end
end

function CoopCharacterCreation:prerender()
    if MM.respawn and MM.respawn.coop == self then
        local ok, err = pcall(R.sync, self)
        if not ok then print("[ZeD] respawn: " .. tostring(err)) end
    end
    if O.prerender then return O.prerender(self) end
    return ISPanelJoypad.prerender(self)
end

function CoopCharacterCreation:accept()
    local r = MM.respawn
    if not (r and r.coop == self) then return O.accept(self) end
    local ok, err = pcall(O.accept, self)
    if not ok then print("[ZeD] respawn: the game's accept failed (" .. tostring(err) .. ")") end
    if CoopCharacterCreation.instance == self and MM.respawn == r then
        -- the game did not take the choices (its accept1: no spawn point for this occupation in the
        -- town): its screens are all hidden by now, so the Looks window comes back to try again
        MM.showView("looks")
        return
    end
    R.finish()
end

function CoopCharacterCreation:cancel()
    local r = MM.respawn
    if r and r.coop == self then R.finish() end
    return O.cancel(self)
end

-- ============================================================================
-- KEYS (the respawning player on the mouse; a controller has the desk's focus)
-- ============================================================================
local function deskKeys()
    local r = MM.respawn
    if not r or r.joypadData then return false end
    local d = MM.root
    return d ~= nil and d:isVisible() and not ZeD.Safe.on()
end
R.deskKeys = deskKeys

-- Escape: an open menu, then a question, then the window's Back. The desk keeps it either way:
-- the pause menu does not open over the desk (it opens again from the world or the death screen).
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.respawn = function()
    if not deskKeys() then return false end
    if MM.ctx.open then MM.ctx.open = nil; return true end
    local w = MM.activeWindow()
    if w and w.keyEscape and w:keyEscape() then return true end
    if w and w.confirm then w:setConfirm(false) end
    return true
end

-- Return (Next / Play) and the arrows, as at the main menu
function R.onKey(key)
    if key == Keyboard.KEY_ESCAPE or not deskKeys() or MM.ctx.open then return end
    local w = MM.activeWindow()
    if w and w.keyOther then pcall(w.keyOther, w, key) end
end
if not R._keysAdded then
    R._keysAdded = true
    Events.OnKeyPressed.Add(function(key) R.onKey(key) end)
end
