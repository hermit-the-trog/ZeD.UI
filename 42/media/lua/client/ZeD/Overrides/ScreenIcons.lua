-- ============================================================================
-- Overrides/ScreenIcons.lua — the vanilla top-left function buttons go away (S124)
-- ============================================================================
-- Director (Oct 13 2026): "the left over function icons on the left top of the
-- screen need to hide or go. we cover all those functions in our windows."
-- ISEquippedItem (ISUI/ISEquippedItem.lua) is the left-edge HUD column: the two
-- equipped-hand slots, then a button per vanilla window (inventory, health,
-- crafting, build, furniture, forage, zones, map) plus debug / multiplayer
-- buttons. The window buttons are hidden here: each opens a vanilla surface
-- that a ZeD tab owns. The hand slots stay until the ZeD screen-icons surface
-- replaces the whole column (HOOK_MAP row 6). Debug and multiplayer buttons are
-- left alone (dev / MP only, no ZeD equivalent).
--
-- Hiding happens after the vanilla prerender because the buttons are created in
-- initialise() and the panel is rebuilt by checkSidebarSizeOption() whenever the
-- sidebar-size option changes (a fresh instance, hidden again on its first frame).
-- The mouse-over list is filtered too: vanilla's checkToolTip tests bounds, not
-- visibility, so a hidden button would otherwise still raise its label tooltip.
-- ============================================================================

local HIDE = { "invBtn", "healthBtn", "craftingBtn", "buildBtn", "movableBtn", "searchBtn", "zoneBtn", "mapBtn" }

local function hideButtons(panel)
    local hidden = {}
    for _, key in ipairs(HIDE) do
        local b = panel[key]
        if b and b.setVisible then b:setVisible(false); hidden[b] = true end
    end
    if panel.mouseOverList then
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

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
