-- ZeD-UI/42/media/lua/client/ZeD/Overrides/ScreenIcons.lua
-- ============================================================================
-- THE VANILLA TOP-LEFT FUNCTION BUTTONS GO AWAY (override, client)
-- ============================================================================
-- ZeD's windows cover every one of those functions, so the leftover icons
-- only duplicate them.
-- ISEquippedItem (ISUI/ISEquippedItem.lua) is the left-edge HUD column: the two
-- equipped-hand slots, then a button per vanilla window (inventory, health,
-- crafting, build, furniture, forage, zones, map) plus debug / multiplayer
-- buttons. The window buttons are hidden here: each opens a vanilla surface
-- that a ZeD tab owns. The hand slots stay until the ZeD screen-icons surface
-- replaces the whole column. Debug and multiplayer buttons are
-- left alone (dev / MP only, no ZeD equivalent), as is any button another mod
-- added to the column. The Tutorial keeps the whole column: its first lesson
-- blinks the heart button.
--
-- Hiding happens after the vanilla prerender because the buttons are created in
-- initialise() and the panel is rebuilt by checkSidebarSizeOption() whenever the
-- sidebar-size option changes (a fresh instance, hidden again on its first frame).
-- The mouse-over list is filtered too: vanilla's checkToolTip tests bounds, not
-- visibility, so a hidden button would otherwise still raise its label tooltip.
--
-- Safe mode (SafeMode.lua, the "screen icons" hook): the buttons this hid come
-- back with vanilla's whole hover list; taking over again hides them on the
-- next frame. The hook follows the belt's own ZeD setup switch too (its
-- screen), as the hiding does: with the belt handed back, the buttons are back.
-- ============================================================================

require "ZeD/SafeMode"

local HIDE = { "invBtn", "healthBtn", "craftingBtn", "buildBtn", "movableBtn", "searchBtn", "zoneBtn", "mapBtn" }

local function hideButtons(panel)
    local hidden = {}
    local shown = {}   -- the ones vanilla had showing, for safe mode to show again
    for _, key in ipairs(HIDE) do
        local b = panel[key]
        if b and b.setVisible then
            if b:getIsVisible() then shown[#shown + 1] = b end
            b:setVisible(false); hidden[b] = true
        end
    end
    panel._zedHiddenBtns = shown
    if panel.mouseOverList then
        panel._zedOverAll = panel._zedOverAll or panel.mouseOverList
        local keep = {}
        for _, v in ipairs(panel.mouseOverList) do if not hidden[v.object] then keep[#keep + 1] = v end end
        panel.mouseOverList = keep
    end
    panel._zedIconsHidden = true
end

local function apply()
    if not ISEquippedItem or ISEquippedItem._zedScreenIconsPatched then return end
    ISEquippedItem._zedScreenIconsPatched = true
    local origPrerender = ISEquippedItem.prerender
    function ISEquippedItem:prerender()
        origPrerender(self)
        -- the Tutorial's first lesson blinks the heart button: vanilla's column stays
        if ZeD.Safe.on("belt") or tostring(getCore():getGameMode()) == "Tutorial" then return end
        if self.invBtn ~= nil and not self._zedIconsHidden then hideButtons(self) end
        -- vanilla's prerender re-shows the furniture button every frame (and its
        -- mode hint and pop-up while the furniture cursor is up): keep all three
        -- down; the World window's Furniture tab is their home now
        if self.movableBtn then self.movableBtn:setVisible(false) end
        if self.movableTooltip then self.movableTooltip:setVisible(false) end
        if self.movablePopup then self.movablePopup:setVisible(false) end
    end
    print("[ZeD] Overrides/ScreenIcons: vanilla window buttons hidden on the left-edge HUD column")
end

local function showButtons(panel)
    for _, b in ipairs(panel._zedHiddenBtns or {}) do pcall(b.setVisible, b, true) end
    panel._zedHiddenBtns = nil
    if panel._zedOverAll then panel.mouseOverList = panel._zedOverAll; panel._zedOverAll = nil end
    panel._zedIconsHidden = nil
end

ZeD.Safe.register("screen icons", {
    screen = "belt",   -- (the column's window buttons follow the belt's switch, as the prerender check above does)
    leave = function()
        local n = getNumActivePlayers and getNumActivePlayers() or 1
        for i = 0, math.max(n, 1) - 1 do
            local pd = getPlayerData and getPlayerData(i)
            if pd and pd.equipped then pcall(showButtons, pd.equipped) end
        end
    end,
    enter = function() end,
})

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
