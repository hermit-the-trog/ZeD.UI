-- ZeD-UI/42/media/lua/client/ZeD/Overrides/CharacterInfo.lua
-- ============================================================================
-- THE GAME'S CHARACTER WINDOW HOOK (Oct 26 2026) — HOOK_MAP "Character info"
-- Everything that shows one of the pages of the game's own Character window
-- goes through ISCharacterInfoWindow:toggleView(viewName) on the window
-- getPlayerInfoPanel(n) returns: the game's keys (Skills, Health, Info,
-- Protection: xpUpdate.displayCharacterInfo), its HUD Health button
-- (ISEquippedItem), its health page's own buttons, and other mods that open
-- the page they care about (Mini Health Panel's click on its body figure,
-- `self.infopanel:toggleView(getText("IGUI_XP_Health"))`). Each of those now
-- lands on ZeD's Character window on the matching tab; the game's window never
-- shows. The same page asked for again folds the tab's drawer, as the game's
-- toggle closes its window.
--   Health -> Health | Skills -> Skills | Info -> Identity
--   Protection -> Equipment (its protection list) | ClothingIns -> Thermal
--   a page another mod added to the game's window -> ZeD's tab of that name
--   (ModSupport tabs), when there is one
-- Vanilla runs when ZeD declines (no such tab, the windows cannot open: a dead
-- or paused character, the Tutorial) and always while safe mode is on.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ZeD_CharacterWindow"
require "XpSystem/ISUI/ISCharacterInfoWindow"

if not ISCharacterInfoWindow then return end

ZeD = ZeD or {}
ZeD.CharInfoRoute = ZeD.CharInfoRoute or { count = 0 }
local Route = ZeD.CharInfoRoute

-- the game's page names (its own words, the language's) -> ZeD's Character window tabs
local function tabFor(viewName)
    if type(viewName) ~= "string" then return nil end
    local map = {
        { "IGUI_XP_Health", "health" },
        { "IGUI_XP_Skills", "skills" },
        { "IGUI_XP_Info", "identity" },
        { "IGUI_XP_Protection", "equip" },
        { "IGUI_XP_ClothingIns", "thermal" },
    }
    for _, m in ipairs(map) do
        if viewName == getText(m[1]) then return m[2] end
    end
    -- a page a mod added to the game's window, with a ZeD tab of the same name
    local ext = ZeD_CharacterWindow and ZeD_CharacterWindow._extTabs or {}
    for id, def in pairs(ext) do
        local ok, label = pcall(function() return def.label and def.label() end)
        if ok and label == viewName then return id end
    end
    return nil
end

-- ZeD's Character window on a tab (the pair opens as the inventory key opens it). toggle:
-- the tab already showing folds its drawer, as a second press of the tab does. Returns
-- true when ZeD has it (the click may land a few ticks later, when the strip has drawn).
function ZeD_CharacterWindow.openTab(playerNum, tabId, toggle)
    playerNum = playerNum or 0
    if not getSpecificPlayer(playerNum) then return false end
    if not ZeD_CharacterWindow.isOpen() then
        ZeD_CharacterWindow.toggleBothPaired(playerNum)
        if not ZeD_CharacterWindow.isOpen() then return false end
        toggle = false
    end
    local win = ZeD_CharacterWindow.getWindow()
    if not win then return false end
    local showing = win._activeTab == tabId and win._drawerOpen and win._drawerMode == "tab"
    if showing and not toggle then return true end
    local pending = true
    local function attempt()
        if not pending then return true end
        local strip = win._tabStripPanel
        for _, z in ipairs(strip and strip._hitZones or {}) do
            if z.id == "tab:" .. tabId then
                pending = false
                strip:onMouseDown(z.x + 2, z.y + 2)
                return true
            end
        end
        return false
    end
    if not attempt() then
        local tries = 0
        local function tick()
            tries = tries + 1
            if attempt() or tries >= 20 then Events.OnTick.Remove(tick) end
        end
        Events.OnTick.Add(tick)
    end
    return true
end

-- the original, kept once (a Lua reload of this file must not wrap the wrapper)
ISCharacterInfoWindow._zedOrigToggleView = ISCharacterInfoWindow._zedOrigToggleView or ISCharacterInfoWindow.toggleView
local _origToggleView = ISCharacterInfoWindow._zedOrigToggleView

function ISCharacterInfoWindow:toggleView(viewName)
    if ZeD.Safe.on() then return _origToggleView(self, viewName) end
    local ok, handled = pcall(function()
        local tab = tabFor(viewName)
        if not tab then return false end
        local playerNum = self.playerNum or 0
        if not ZeD_CharacterWindow.openTab(playerNum, tab, true) then return false end
        -- the game's window stays away (it may have been shown some other way)
        if self:getIsVisible() then self:setVisible(false); self:removeFromUIManager() end
        Route.count = Route.count + 1
        Route.last = { view = viewName, tab = tab, player = playerNum, ms = getTimestampMs() }
        return true
    end)
    if ok and handled then return end
    if not ok then print("[ZeD] CharacterInfo: toggleView route failed: " .. tostring(handled)) end
    return _origToggleView(self, viewName)
end

-- The game's window never shows at a game's start while ZeD is on (Oct 29 2026, the
-- small-screen pass). The game decides its start visibility from layout.ini, which is
-- kept per screen size: on a screen size the player has not used before there is no
-- entry, and the window keeps its default, visible (the game's own first-run look); on
-- one they have, it comes back the way their last game without ZeD left it. Either way
-- ISPlayerDataObject.createUI shows it when `visibleOnStartup` is true after initialise
-- (where the game sets it from the restored state). So the flag is cleared after the
-- game's initialise while ZeD is on; in safe mode the game's rule stands. Seen in the
-- 1280x800 pass: the game's Info page sat under ZeD's windows the whole run.
ISCharacterInfoWindow._zedOrigInitialise = ISCharacterInfoWindow._zedOrigInitialise or ISCharacterInfoWindow.initialise
local _origInitialise = ISCharacterInfoWindow._zedOrigInitialise
function ISCharacterInfoWindow:initialise(...)
    _origInitialise(self, ...)
    if not ZeD.Safe.on() then self.visibleOnStartup = false end
end

print("[ZeD] Overrides/CharacterInfo: the game's Character window pages routed to ZeD's Character window tabs")
