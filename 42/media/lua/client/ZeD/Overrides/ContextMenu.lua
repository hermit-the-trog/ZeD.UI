-- ZeD-UI/42/media/lua/client/ZeD/Overrides/ContextMenu.lua
-- ============================================================================
-- CONTEXT MENU HOOK (S88 — rev 2)
--
-- Replaces vanilla ISContextMenu rendering with the ZeD_ContextMenu organism
-- WITHOUT touching the vanilla data model.
--
-- Critical vanilla finding (rev 2): the top-level ISContextMenu is a per-player
-- SINGLETON cached via getPlayerContextMenu(player). It's added to UIManager
-- ONCE at first use and then reused across RMBs — setVisible(true/false) is
-- the show/hide signal, NOT addToUIManager. So we hook prerender + clear:
--
--   - clear()     → reset _zedSpawned (the per-RMB reset signal; called inside
--                   ISContextMenu.get at the start of each menu open)
--   - prerender() → if options are populated and not yet spawned, build the
--                   ActionDef tree and spawn ZeD_ContextMenu, then move the
--                   vanilla menu offscreen so it never draws. Skip orig
--                   prerender entirely to suppress the vanilla slide anim.
--
-- OnFillWorld/InventoryObjectContextMenu events still fire exactly as
-- vanilla expects, so third-party mods continue to populate options.
-- ============================================================================

require "ISUI/ISContextMenu"
require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "ZeD/ContextMenuRegistry"
require "ZeD/ZeD_ContextMenu"

-- Is the user actively driving with a gamepad RIGHT NOW?
--
-- Do NOT use `JoypadState.players[player+1]` for this — it's truthy whenever
-- a controller is merely *connected*, even if the user is right-clicking
-- with the mouse. That mis-detection routed mouse RMB through the gamepad
-- anchor path (focused-row / player-iso), which silently failed to resolve
-- and dropped the menu to dock-bottom (mid-screen) instead of at the cursor.
--
-- ZeD.Input.Detector tracks the last-active input device (Jibb Smart rule:
-- mouse CLICKS count as KBM, mouse MOVES don't), so it's the authoritative
-- answer to "which device just triggered this menu?". Defensive nil-chain
-- in case Detector hasn't loaded yet on some early frame.
local function _isGamepadActive()
    local D = ZeD and ZeD.Input and ZeD.Input.Detector
    -- a mouse button went down a moment ago: this menu is the mouse's (a
    -- right-click on a window used to land at the item's inventory row or
    -- the bottom of the screen when the last input was the controller)
    if D and D.msSinceMouseClick and D.msSinceMouseClick() < 1500 then return false end
    return (D and D.getMode and D.getMode() == "gamepad") or false
end

-- Resolve a player's on-screen position (iso → screen coords). Used as the
-- gamepad-world anchor so the menu opens near the character instead of
-- docked at the bottom-center of the viewport.
local function _playerScreenAnchor(player)
    local pl = getSpecificPlayer(player)
    if not pl then return nil, nil end
    local ok1, sx = pcall(function()
        return isoToScreenX(player, pl:getX(), pl:getY(), pl:getZ())
    end)
    local ok2, sy = pcall(function()
        return isoToScreenY(player, pl:getX(), pl:getY(), pl:getZ())
    end)
    if ok1 and ok2 and sx and sy then return sx, sy end
    return nil, nil
end

-- Compute the screen anchor for a gamepad-opened inventory context menu.
-- S101: now prefers the ring's live focused element over yMap lookup. The
-- yMap path was fragile — an item could be in items[] but NOT in yMap (off-
-- screen, collapsed-category, or stamp-timing edge cases in non-Loot tabs)
-- which silently dropped the menu to dock-bottom. Reading the focused
-- element's bounds from FocusManager is the authoritative "where is the
-- gamepad cursor right now" and works regardless of render timing.
--
-- Order of preference:
--   1. Focused window's focused zone is charMainInv / worldMainInv → use
--      the focused element's panel-local bounds.
--   2. Fall back to yMap lookup on items[1] (mouse RMB with coincidentally
--      matching item, or legacy callers).
--   3. Nil → caller uses dock-bottom.
local function _invRowScreenAnchor(items)
    -- Try focused-element anchor first (works for gamepad where focus is live).
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
    if focWin and focWin._mainContent and Focus.getFocusedZone and Focus.getFocusedElement then
        local zone = Focus.getFocusedZone(focWin)
        local zid  = zone and zone.zone
        if zid == "charMainInv" or zid == "worldMainInv" then
            local el  = Focus.getFocusedElement(focWin)
            local cnt = focWin._mainContent
            if el and cnt then
                local rowH = (ZeD.T and ZeD.T.rowH) or 26  -- S124 scale: T.rowH is pre-scaled; 26 only runs before ZeD.T exists (no T.px then)
                -- el.x may be 0 (invrow focusables zero X). Use panel width
                -- center for the X anchor so the bubble centers on the panel.
                local ax = cnt:getAbsoluteX() + math.floor(cnt:getWidth() / 2)
                local ay = cnt:getAbsoluteY() + (el.y or 0) + math.floor(rowH / 2)
                return ax, ay
            end
        end
        -- S106: MC zone anchor. Elements carry real x + w per column (cs.renderX
        -- + cs.renderW), so center on the column, not the panel. y is the
        -- per-row stamp (or rowH fallback) from the MC builder.
        if zid == "charLootMCColumns" or zid == "worldLootMCColumns" then
            local el  = Focus.getFocusedElement(focWin)
            local cnt = focWin._mainContent
            if el and cnt then
                local rowH = (ZeD.T and ZeD.T.rowH) or 26
                local ax = cnt:getAbsoluteX() + (el.x or 0) + math.floor((el.w or rowH) / 2)
                local ay = cnt:getAbsoluteY() + (el.y or 0) + math.floor(rowH / 2)
                return ax, ay
            end
        end
    end
    -- Fallback: lookup items[1] in either window's yMap. Build the candidate
    -- list without nil holes so `#` / iteration remain well-defined when only
    -- one window is open.
    if not items or #items == 0 then return nil, nil end
    local firstItem = items[1]
    if not firstItem then return nil, nil end
    local candidates = {}
    if ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow then
        local cw = ZeD_CharacterWindow.getWindow()
        if cw then candidates[#candidates + 1] = cw end
    end
    if ZeD_WorldWindow and ZeD_WorldWindow.getWindow then
        local ww = ZeD_WorldWindow.getWindow()
        if ww then candidates[#candidates + 1] = ww end
    end
    for i = 1, #candidates do
        local w = candidates[i]
        if w._mainContent then
            local cnt = w._mainContent
            local yMap = cnt._itemRenderYMap
            local rowY = yMap and yMap[firstItem]
            if rowY then
                local ax = cnt:getAbsoluteX() + math.floor(cnt:getWidth() / 2)
                local ay = cnt:getAbsoluteY() + rowY
                return ax, ay
            end
        end
    end
    return nil, nil
end

-- ---------------------------------------------------------------------------
-- EVERY FRESH MENU — ISContextMenu.get(player, x, y) hands back the player's
-- one reused menu. Its anchor starts as the point asked for; the createMenu
-- wrappers below then set their own. Without this a menu built straight on
-- ISContextMenu.get (vanilla's hotbar slot menu, the belt's lists, other
-- mods) kept the LAST menu's anchor and target, and opened wherever the
-- previous menu had been.
-- ---------------------------------------------------------------------------
local origGet = ISContextMenu.get
ISContextMenu.get = function(player, x, y)
    local context = origGet(player, x, y)
    if context then
        context._zedTarget = nil
        context._zedAnchorMode = "cursor"
        context._zedAnchorX = x
        context._zedAnchorY = y
    end
    return context
end

-- ---------------------------------------------------------------------------
-- WORLD RMB + GAMEPAD X PATH — stamp the target on the returned menu.
-- ISWorldObjectContextMenu.createMenu is the B42.16+ convergence point for
-- both mouse RMB and the gamepad X button.
-- ---------------------------------------------------------------------------
local origWorldCreateMenu = ISWorldObjectContextMenu.createMenu
function ISWorldObjectContextMenu.createMenu(player, worldobjects, x, y, test)
    local menu = origWorldCreateMenu(player, worldobjects, x, y, test)
    if menu and not test then
        menu._zedTarget = worldobjects
        -- S99: gamepad anchors at the PLAYER's screen position for world
        -- objects (instead of dock-bottom). Falls back to dock if we can't
        -- resolve the player's screen coords.
        if _isGamepadActive() then
            local px, py = _playerScreenAnchor(player)
            if px and py then
                menu._zedAnchorMode = "cursor"
                menu._zedAnchorX = px
                menu._zedAnchorY = py
            else
                menu._zedAnchorMode = "dock"
                menu._zedAnchorX = x
                menu._zedAnchorY = y
            end
        else
            -- Mouse RMB: anchor at the cursor like vanilla. Use getMouseX/Y
            -- directly rather than the passed (x, y) — third-party callers
            -- may pass panel-local or stale coords; the live cursor position
            -- is what the user expects the menu to open next to.
            menu._zedAnchorMode = "cursor"
            menu._zedAnchorX = getMouseX() or x
            menu._zedAnchorY = getMouseY() or y
        end
    end
    return menu
end

-- ---------------------------------------------------------------------------
-- INVENTORY RMB PATH — same pattern.
-- S99: gamepad anchors at the selected item's screen row (instead of
-- dock-bottom). Falls back to dock if we can't resolve the row position.
-- ---------------------------------------------------------------------------
local origInvCreateMenu = ISInventoryPaneContextMenu.createMenu
function ISInventoryPaneContextMenu.createMenu(player, isInInv, items, x, y)
    local menu = origInvCreateMenu(player, isInInv, items, x, y)
    if menu then
        menu._zedTarget = items
        if _isGamepadActive() then
            -- a caller that names the spot (X on an Equip row, a belt row or
            -- a belt box) gets it; 0, 0 asks for the focused inventory row
            local ix, iy
            if x and y and (x > 0 or y > 0) then ix, iy = x, y
            else ix, iy = _invRowScreenAnchor(items) end
            if ix and iy then
                menu._zedAnchorMode = "cursor"
                menu._zedAnchorX = ix
                menu._zedAnchorY = iy
            else
                menu._zedAnchorMode = "dock"
                menu._zedAnchorX = x
                menu._zedAnchorY = y
            end
        else
            -- Mouse RMB: anchor at the live cursor like vanilla
            -- ISInventoryPage.createMenu(..., getMouseX(), getMouseY()).
            menu._zedAnchorMode = "cursor"
            menu._zedAnchorX = getMouseX() or x
            menu._zedAnchorY = getMouseY() or y
        end
    end
    return menu
end

-- ---------------------------------------------------------------------------
-- clear() is called per-RMB inside ISContextMenu.get before events fire.
-- This is our signal to forget any previously-spawned ZeD menu and let the
-- next prerender frame build a fresh one.
-- ---------------------------------------------------------------------------
local origClear = ISContextMenu.clear
function ISContextMenu:clear()
    origClear(self)
    self._zedSpawned = false
    -- If the previous RMB's ZeD organism is still alive (user re-clicked
    -- before dismissing), reap it. Guard against double-close by checking
    -- the organism's own open flag.
    if self._zedMenu and self._zedMenu._ctx and self._zedMenu._ctx.open then
        pcall(function() self._zedMenu:close() end)
    end
    self._zedMenu = nil
end

-- ---------------------------------------------------------------------------
-- THE HOOK: override prerender. First frame with populated options spawns
-- the ZeD organism and hides the vanilla menu offscreen. Subsequent frames
-- are a no-op — vanilla stays offscreen, ZeD menu handles all input.
-- ---------------------------------------------------------------------------
local origPrerender = ISContextMenu.prerender
function ISContextMenu:prerender()
    -- Submenu instances — these are the child ISContextMenu objects vanilla
    -- creates via getNew() for drill-down. Our ActionDef tree handles
    -- submenus entirely in the ZeD organism (via the path/drillInto state),
    -- so vanilla submenus are pure noise here. Keep them offscreen.
    if self.parent and type(self.parent) == "table" and self.parent.options then
        self:setX(-100000)
        self:setY(-100000)
        return
    end

    if self._zedSpawned then
        -- Already handled — just keep it offscreen this frame.
        self:setX(-100000)
        return
    end

    -- We need default options (Cancel, Properties, etc.) to be in the tree.
    -- Vanilla adds them inside its prerender via addDefaultOptions(); run
    -- that once ourselves so our tree is complete.
    if self.addDefaultOptions then
        pcall(function() self:addDefaultOptions() end)
    end

    -- Empty menu — let vanilla handle (it'll hide itself at x=100000 per
    -- vanilla's own cheap-hack logic). Nothing to spawn.
    if self:isEmpty() then
        self._zedSpawned = true
        return origPrerender(self)
    end

    -- Build ActionDef tree and spawn the organism.
    self._zedSpawned = true
    local Registry = ZeD.ContextMenu.Registry
    if not Registry then
        self._zedSpawned = false
        return origPrerender(self)
    end
    local target = self._zedTarget
    local tree = Registry.buildActionsFromVanilla(self.options, target, self)
    Registry.applyPins(tree, target)

    -- If tree is empty after translation (all options filtered?), bail to vanilla.
    if #tree == 0 then
        return origPrerender(self)
    end

    local anchorMode = self._zedAnchorMode or "cursor"
    local anchorX    = self._zedAnchorX or self:getX()
    local anchorY    = self._zedAnchorY or self:getY()

    local ok, menuOrErr = pcall(function()
        local m = ZeD_ContextMenu:new(self.player, anchorMode, anchorX, anchorY,
                                       target, tree, self)
        m:initialise()
        m:open()   -- open() internally calls addToUIManager + bringToTop
        return m
    end)
    if ok and menuOrErr then
        self._zedMenu = menuOrErr
        -- Park vanilla offscreen so it never draws while our menu is up
        self:setX(-100000)
        self:setY(-100000)
    else
        -- If the ZeD organism failed to construct, fall back to vanilla so
        -- the player at least has a functioning context menu. Log the error
        -- so closeout can capture it for PZAPI-KNOWLEDGE-BANK if recurring.
        print("[ZeD.ContextMenu] organism spawn failed: " .. tostring(menuOrErr))
        self._zedSpawned = false
        return origPrerender(self)
    end
end

-- ---------------------------------------------------------------------------
-- Suppress vanilla render too — with the menu at x = -100000 it's already
-- off-screen, but short-circuiting render saves a bunch of wasted work on
-- the blink animation + slide update + tooltip sub-lifecycle.
-- ---------------------------------------------------------------------------
local origRender = ISContextMenu.render
function ISContextMenu:render()
    if self._zedSpawned and not self:isEmpty() then
        return   -- handled by ZeD organism
    end
    if self.parent and type(self.parent) == "table" and self.parent.options then
        return   -- submenu — ZeD organism drives submenus internally
    end
    return origRender(self)
end
