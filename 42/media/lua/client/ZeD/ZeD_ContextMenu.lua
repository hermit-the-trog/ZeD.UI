-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ContextMenu.lua
-- ============================================================================
-- ZeD_ContextMenu — Unified Interaction Layer organism (S88)
-- One horizontal icon strip. Serves mouse RMB AND gamepad, identically. See
-- CONTEXT_MENU_SPEC.md for the full design. This file owns render + input
-- routing + open/close lifecycle + settle-timer management.
--
-- Assembly stack (top → bottom):
--   floating label (absolute, tracks selected cell X)
--     ▼
--   [bumper] [chev?] [strip] [chev?] [bumper]      — strip row, flow
--     │
--   target card (static, centered under strip)
--     ▲
--   balloon    (static, centered under target card; upward pointer)
--
-- The organism delegates all pixel work to molecules (drawContextStrip,
-- drawContextBumpers, drawContextFloatingLabel, drawContextTargetCard,
-- drawContextBalloon). This file is pure state + routing + layout math.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/ZeD_Panel"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ContextMenuRegistry"

ZeD_ContextMenu = ZeD_Panel:derive("ZeD_ContextMenu")

-- ============================================================================
-- CONSTRUCTION
-- ============================================================================
--   player:       0-3 for split-screen
--   anchorMode:   "cursor" (mouse RMB — use explicit x,y) or "dock" (gamepad —
--                 compute bottom-center of player screen)
--   anchorX/Y:    only used when anchorMode == "cursor"
--   target:       the world object(s) or inventory item(s) the menu acts on
--                 (passed through to ActionDef callbacks)
--   actionTree:   array of ActionDefs from ContextMenuRegistry.buildActionsFromVanilla
--   vanillaMenu:  reference to the hidden vanilla ISContextMenu (for bookkeeping)
-- ============================================================================
function ZeD_ContextMenu:new(player, anchorMode, anchorX, anchorY, target, actionTree, vanillaMenu)
    local T = ZeD.T
    -- Seed with generous size; we recompute in _layout every frame
    local o = ZeD_Panel:new(0, 0, T.px(400), T.px(240))
    setmetatable(o, self)
    self.__index = self

    o.player      = player or 0
    o.anchorMode  = anchorMode or "cursor"
    o._anchorX    = anchorX or 0
    o._anchorY    = anchorY or 0
    o.vanillaMenu = vanillaMenu

    -- Core state (see CONTEXT_MENU_SPEC §4 for spec)
    o._ctx = {
        open        = false,
        target      = target,
        actions     = actionTree or {},   -- top-level ActionDef array
        path        = {},                  -- parent raw indices; empty = top level
        selected    = 1,                   -- 1-based index into currentItems()
        pos         = 1,                   -- 1-based index into trackItems (truncating)
        truncating  = false,
        items       = nil,                 -- current visible items (cached each _layout)
        trackItems  = nil,                 -- 1 or 3 copies; ref-shared with items
        trackOriginX = 0,                  -- animated pixel offset
        pinnedIds   = ZeD.ContextMenu.Registry.getPinnedIds() or {},
        currentDef  = nil,                 -- resolved selected ActionDef (for balloon etc.)
        parentDef   = nil,                 -- parent ActionDef when in submenu
    }

    -- Animation state — ZeD drawer style (UIManager.getMillisSinceLastRender accumulator)
    -- All these must start as numbers; _layout uses them in arithmetic on the
    -- very first frame before any target-change detection can initialize them.
    o._animFromOriginX = 0
    o._animToOriginX   = 0
    o._animStartMs     = 0
    o._animFromLabelX  = 0
    o._animToLabelX    = 0
    o._animFromStripW  = 0
    o._animToStripW    = 0
    o._currentOriginX  = 0
    o._currentLabelX   = 0
    o._currentStripW   = 0

    -- Settle timer for the triple-render carousel
    o._settleAt        = nil   -- timestamp or nil
    o._suppressFrames  = 0     -- int; skip animation interpolation for N frames

    -- Vertical flip flag — when the click is too close to the top of the
    -- screen for the bubble to fit above the strip, we flip: strip below
    -- cursor, bubble below strip with an upward pointer. Set in
    -- _positionAssembly based on cursor Y vs bubble max height.
    o._flipped = false

    -- Onhighlight tracking — invoked whenever selected changes (mirrors vanilla
    -- ISContextMenu.checkHighlightedOption). Some mods use this for server gating.
    o._lastHighlightedVanilla = nil

    -- Input state
    o._hoveredId     = nil    -- for visual hover (currently tracks last moved-over zone)
    o._pressedId     = nil    -- which bumper/chev is currently mouse-pressed (for visual depress)
    o._joyfocus      = false  -- gamepad controlling the menu

    -- Cached layout rectangles — updated each prerender, read by input routing
    o._layoutCache = {
        stripX = 0, stripY = 0, stripW = 0, stripH = 0,
        cardX = 0, cardY = 0, cardW = 0, cardH = 0,
        balloonX = 0, balloonY = 0, balloonW = 0, balloonH = 0,
        assemblyLeft = 0, assemblyRight = 0,
    }

    return o
end

-- ============================================================================
-- LIFECYCLE
-- ============================================================================

function ZeD_ContextMenu:initialise()
    ZeD_Panel.initialise(self)
end

function ZeD_ContextMenu:open()
    self._ctx.open = true
    -- Initial track build + layout seeding
    self:_rebuildTrack()
    -- Position the panel based on anchor mode
    self:_positionAssembly()
    -- Gamepad prep (all wrapped — these globals may not exist in every build)
    if JoypadState and JoypadState.players and JoypadState.players[self.player + 1] then
        self._joyfocus = true
        pcall(function()
            if setJoypadIgnoreAimUntilCentered then
                setJoypadIgnoreAimUntilCentered(self.player, true)
            end
        end)
        pcall(function()
            if setJoypadFocus then setJoypadFocus(self.player, self) end
        end)
    end
    self:setWantKeyEvents(true)
    self:addToUIManager()
    -- setAlwaysOnTop doesn't exist on ISPanel; bringToTop is the right call.
    pcall(function() self:bringToTop() end)
end

function ZeD_ContextMenu:close()
    self._ctx.open = false
    -- Release gamepad focus
    if self._joyfocus and setJoypadFocus then
        pcall(setJoypadFocus, self.player, nil)
    end
    self._joyfocus = false

    -- S96: return engine focus to FocusManager's tracked window so gamepad
    -- dispatch resumes after context menu dismissal. Without this, engine
    -- focus stays nil and D-pad goes nowhere until a new window is opened.
    -- Defensive nil-check chain: context menu loads before FocusManager in
    -- alphabetical order, so ZeD.Input.Focus may not exist yet on first load.
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.reclaimEngineFocus then
        ZeD.Input.Focus.reclaimEngineFocus()
    end

    -- CRITICAL: do NOT removeFromUIManager on the vanilla menu. It's a cached
    -- per-player singleton (getPlayerContextMenu); removing it breaks the
    -- clear() + prerender re-capture pipeline on every subsequent RMB. We
    -- just hide it and clear our spawn marker so the next clear() cycle
    -- will trigger a fresh ZeD organism on the next prerender frame.
    if self.vanillaMenu then
        pcall(function() self.vanillaMenu:setVisible(false) end)
        self.vanillaMenu._zedSpawned = false
        self.vanillaMenu._zedMenu    = nil
    end
    self:removeFromUIManager()
end

-- ============================================================================
-- LAYOUT — computes assembly anchor, strip rect, bumper rects, card, balloon.
-- Runs each prerender so it tracks anchor changes (player screen moves in
-- split-screen, etc.) and picks up fresh T.ctx every frame.
-- ============================================================================

-- Assemble the current visible list, including synthetic Back cell at pos 0
-- when we're inside a submenu.
function ZeD_ContextMenu:_currentItems()
    if #self._ctx.path == 0 then
        return self._ctx.actions
    end
    local node = self._ctx.actions
    for _, p in ipairs(self._ctx.path) do
        node = node[p].children
    end
    local list = { {
        id = "__back", name = "< Back", isBack = true,
        category = "NAV",
        body = "Return to previous level.",
        disabled = function() return false end,
        stateKind = function() return "ok" end,
        state = function() return "" end,
    } }
    for _, def in ipairs(node) do list[#list + 1] = def end
    return list
end

function ZeD_ContextMenu:_currentParent()
    if #self._ctx.path == 0 then return nil end
    local node = self._ctx.actions
    for i = 1, #self._ctx.path - 1 do node = node[self._ctx.path[i]].children end
    return node[self._ctx.path[#self._ctx.path]]
end

function ZeD_ContextMenu:_parentChain()
    local chain = {}
    if #self._ctx.path == 0 then return chain end
    local node = self._ctx.actions
    for i, p in ipairs(self._ctx.path) do
        chain[#chain + 1] = node[p].name
        if i < #self._ctx.path then node = node[p].children end
    end
    return chain
end

-- Rebuild the triple-concat track when items change (open, drill, pop).
-- Items are ref-shared, not deep-copied — cheap.
function ZeD_ContextMenu:_rebuildTrack()
    local items = self:_currentItems()
    self._ctx.items = items
    local N = #items
    local ctx = ZeD.T.ctx
    self._ctx.truncating = N > ctx.maxVisible
    if self._ctx.truncating then
        local track = {}
        for copy = 1, 3 do
            for _, def in ipairs(items) do track[#track + 1] = def end
        end
        self._ctx.trackItems = track
        -- Start selection in the middle copy
        self._ctx.pos = N + self._ctx.selected
    else
        self._ctx.trackItems = items
        self._ctx.pos = self._ctx.selected
    end
    -- Reset animation anchors so we don't slide from a stale position
    self._animSuppressFrames = 1
end

-- Compute the animated strip origin, label X, strip width. Writes results
-- into _layoutCache and advances the lerp.
function ZeD_ContextMenu:_layout(T)
    local ctx = T.ctx
    local items = self._ctx.items
    local N = #items
    local visibleCount = math.min(N, ctx.maxVisible)
    local innerW = visibleCount * ctx.cellW + math.max(0, visibleCount - 1) * ctx.gap
    local drilled = #self._ctx.path > 0
    local topBorder = drilled and ctx.drilledBorderTop or T.px(1)
    local housingW = innerW + T.px(1) * 2   -- S124 scale: 1px left + right border, same as drawContextStrip
    local housingH = ctx.cellH + topBorder + T.px(1)

    -- Target values for interpolation
    local targetOriginX
    if self._ctx.truncating then
        -- Selected cell centered in the visible window
        targetOriginX = innerW / 2
                        - ((self._ctx.pos - 1) * (ctx.cellW + ctx.gap) + ctx.cellW / 2)
    else
        targetOriginX = 0
    end

    -- Label X (panel-local). In truncating mode the selected cell is always
    -- at the visual center of the strip, so label centers on strip center.
    -- In non-truncating mode label tracks the actual cell.
    local labelTargetX
    if self._ctx.truncating then
        labelTargetX = nil  -- will compute after stripX is known
    else
        -- Offset from strip interior left edge
        labelTargetX = T.px(1) + (self._ctx.selected - 1) * (ctx.cellW + ctx.gap) + ctx.cellW / 2
    end

    -- Kick a new animation if targets changed
    if self._animToOriginX ~= targetOriginX then
        self._animFromOriginX = self._currentOriginX or targetOriginX
        self._animToOriginX   = targetOriginX
        self._animStartMs     = getTimestampMs()
    end
    if self._animToStripW ~= innerW then
        self._animFromStripW = self._currentStripW or innerW
        self._animToStripW   = innerW
        self._animStartMs    = getTimestampMs()
    end

    -- Interpolate (ZeD drawer style — timestamp-based progress)
    local progress
    local justSuppressed = false
    if self._suppressFrames and self._suppressFrames > 0 then
        -- Skip animation for one frame after a silent settle teleport
        progress = 1.0
        self._suppressFrames = self._suppressFrames - 1
        justSuppressed = true
    else
        local elapsed = getTimestampMs() - self._animStartMs
        progress = math.min(1.0, elapsed / ctx.animMs)
    end
    -- Cubic ease-out (matches mockup's cubic-bezier approximation)
    local p = 1 - (1 - progress) * (1 - progress) * (1 - progress)
    self._currentOriginX = self._animFromOriginX + (self._animToOriginX - self._animFromOriginX) * p
    self._currentStripW  = self._animFromStripW  + (self._animToStripW  - self._animFromStripW)  * p
    self._ctx.trackOriginX = math.floor(self._currentOriginX + 0.5)

    -- S101: when suppress just fired (silent carousel teleport), collapse the
    -- from/to ranges so subsequent frames — which use timestamp-based progress
    -- restart at ~0 immediately after the kick — don't interpolate BACK toward
    -- the pre-teleport anchor. Without this, a LEFT press at the first item
    -- slides one cell, snaps to the middle copy, then visibly shuffles back
    -- ~92% of the way on the next frame as the easing restarts from `from`.
    if justSuppressed then
        self._animFromOriginX = self._animToOriginX
        self._animFromStripW  = self._animToStripW
    end

    -- Now that strip width is settled, compute assembly positions.
    -- Assembly is centered horizontally inside our panel.
    -- Total row width includes bumpers + gutters + optional chevrons.
    local gutter = ctx.gutter
    local totalRowW = housingW + gutter * 2 + ctx.bumperMinW * 2
    if self._ctx.truncating then
        totalRowW = totalRowW + (ctx.chevW + gutter) * 2
    end

    local panelCenterX = math.floor(self.width / 2)
    -- Strip Y in panel-local space is set by _positionAssembly (varies by
    -- flip direction). Default to 160 if positioning hasn't run yet.
    local stripY = self._stripYLocal or T.px(160)
    local stripX = panelCenterX - math.floor(housingW / 2)

    -- Now resolve labelX properly
    if self._ctx.truncating then
        labelTargetX = stripX + math.floor(housingW / 2)
    else
        labelTargetX = stripX + labelTargetX
    end
    if self._animToLabelX ~= labelTargetX then
        self._animFromLabelX = self._currentLabelX or labelTargetX
        self._animToLabelX   = labelTargetX
        self._animStartMs    = getTimestampMs()
    end
    self._currentLabelX = self._animFromLabelX + (self._animToLabelX - self._animFromLabelX) * p
    if justSuppressed then
        self._animFromLabelX = self._animToLabelX
    end

    -- Target card + balloon positions (static-centered, flow below strip)
    local cardY = stripY + housingH + ctx.targetCardMarginV

    -- Populate the layout cache for input routing
    local cache = self._layoutCache
    cache.stripX = stripX
    cache.stripY = stripY
    cache.stripW = housingW
    cache.stripH = housingH
    cache.innerW = innerW
    cache.innerX = stripX + T.px(1)
    cache.innerY = stripY + topBorder
    cache.labelX = math.floor(self._currentLabelX + 0.5)
    cache.labelY = stripY - ctx.labelMarginV + T.px(4)  -- rough label top (molecule computes exact)
    cache.cardY  = cardY
    cache.assemblyLeft  = panelCenterX - math.floor(totalRowW / 2)
    cache.assemblyRight = panelCenterX + math.floor(totalRowW / 2)

    -- Resolve currentDef from selection for balloon rendering downstream
    local idx = self._ctx.selected
    if idx >= 1 and idx <= #items then
        self._ctx.currentDef = items[idx]
    else
        self._ctx.currentDef = nil
    end
    self._ctx.parentDef = self:_currentParent()
end

-- ============================================================================
-- RENDER — sequence: strip → bumpers → label → target card → balloon
-- ============================================================================

function ZeD_ContextMenu:prerender()
    if not self._ctx.open then return end
    local T = ZeD.T
    local M = ZeD.Molecules

    -- Refresh visible items in case child lists changed (unusual but possible)
    self._ctx.items = self:_currentItems()

    -- Clear + rebuild hit zones from scratch this frame (ZeD convention)
    self:clearHitZones()

    -- Compute layout
    self:_layout(T)

    -- DRAW ORDER — strip first so bumpers can overlap edge decoration cleanly
    local cache = self._layoutCache
    M.drawContextStrip(self, cache.stripX, cache.stripY, self._ctx, T)

    -- Bumpers + chevrons (conditional)
    M.drawContextBumpers(self, cache.stripX, cache.stripY, cache.stripW, cache.stripH,
                          self._ctx.truncating, self._pressedId, T)

    -- Combined info bubble ABOVE the strip (S88 follow-up). The previous
    -- design had a small floating label up top and a separate balloon below
    -- the (now-removed) target card. Both are now one piece of chrome above
    -- the strip with a downward pointer — the action name is the headline,
    -- body and state rows append below it when they have content.
    --
    -- Target card was removed entirely: right-clicking already shows you what
    -- you clicked on (cursor sits below the strip on the click target).
    local def = self._ctx.currentDef
    local target = self._ctx.target

    local labelText = (def and def.name) or ""
    local rawBody   = def and def.body
    local rawState  = (def and def.state) and def.state(target) or nil
    local stateKind = (def and def.stateKind) and def.stateKind(target) or "ok"
    local parentChain = self:_parentChain()

    -- Bubble centers on the strip horizontally (stable; doesn't chase
    -- selection X). Apex sits a couple of pixels OFF the strip — above when
    -- normal orientation, below when flipped (cursor near top of screen).
    local bubbleCenterX = cache.stripX + math.floor(cache.stripW / 2)
    local apexGap = T.px(2)
    local apexY
    local pointerDir
    if self._flipped then
        apexY = cache.stripY + cache.stripH + apexGap
        pointerDir = "up"      -- pointer at TOP of bubble, points UP at strip
    else
        apexY = cache.stripY - apexGap
        pointerDir = "down"    -- pointer at BOTTOM of bubble, points DOWN at strip
    end

    local bubbleState = {
        labelText   = labelText,
        parentChain = parentChain,
        bodyText    = rawBody or "",
        stateText   = rawState or "",
        stateKind   = stateKind,
        isSubmenu   = #self._ctx.path > 0,
        pointerDir  = pointerDir,
    }
    local balW, balH = M.drawContextBalloon(self, bubbleCenterX, apexY, bubbleState, T)
    cache.balloonX = bubbleCenterX - math.floor(balW / 2)
    cache.balloonY = self._flipped and apexY or (apexY - balH)
    cache.balloonW = balW
    cache.balloonH = balH
    cache.cardX, cache.cardW, cache.cardH = 0, 0, 0   -- card removed

    -- Dispatch onHighlight to the vanilla option whenever selection changes
    if def and def.vanillaRef and def.vanillaRef ~= self._lastHighlightedVanilla then
        -- Leave previous
        if self._lastHighlightedVanilla and self._lastHighlightedVanilla.onHighlight then
            pcall(self._lastHighlightedVanilla.onHighlight, self._lastHighlightedVanilla, false)
        end
        -- Enter new
        if def.vanillaRef.onHighlight then
            pcall(def.vanillaRef.onHighlight, def.vanillaRef, true)
        end
        self._lastHighlightedVanilla = def.vanillaRef
    end
end

-- ============================================================================
-- NAVIGATION — spec §4 "Selection transitions"
-- ============================================================================

function ZeD_ContextMenu:next()
    local items = self._ctx.items
    local N = #items
    if N == 0 then return end
    self._ctx.selected = (self._ctx.selected % N) + 1
    if self._ctx.truncating then
        self._ctx.pos = self._ctx.pos + 1
        self:_scheduleSettle()
    end
end

function ZeD_ContextMenu:prev()
    local items = self._ctx.items
    local N = #items
    if N == 0 then return end
    self._ctx.selected = ((self._ctx.selected - 2 + N) % N) + 1
    if self._ctx.truncating then
        self._ctx.pos = self._ctx.pos - 1
        self:_scheduleSettle()
    end
end

-- Group jump — skip to first item of next category. Wraps. Mirrors mockup JS.
function ZeD_ContextMenu:nextGroup()
    local items = self._ctx.items
    local N = #items
    if N == 0 then return end
    local curCat = items[self._ctx.selected].category or "ACTION"
    for step = 1, N do
        local i = ((self._ctx.selected - 1 + step) % N) + 1
        if items[i].category ~= curCat and not items[i].isBack then
            if self._ctx.truncating then
                self._ctx.pos = self._ctx.pos + step
            end
            self._ctx.selected = i
            if self._ctx.truncating then self:_scheduleSettle() end
            return
        end
    end
end

-- Group jump backward — walk back to the FIRST item of the PREVIOUS category.
-- If we're already at the start of the current category, step into the
-- previous category and walk to its start. Mirrors mockup JS.
function ZeD_ContextMenu:prevGroup()
    local items = self._ctx.items
    local N = #items
    if N == 0 then return end
    local curCat = items[self._ctx.selected].category or "ACTION"
    local start = self._ctx.selected
    while start > 1 and (items[start - 1].category == curCat) do
        start = start - 1
    end
    local target
    if start == self._ctx.selected then
        -- Already at category start — hop to previous category's first item
        local pI = ((self._ctx.selected - 2 + N) % N) + 1
        if items[pI].isBack then
            target = pI
        else
            local pC = items[pI].category
            local first = pI
            while first > 1 and items[first - 1].category == pC and not items[first - 1].isBack do
                first = first - 1
            end
            target = first
        end
    else
        target = start
    end
    if self._ctx.truncating then
        -- Short-way wrap: if target is ahead of us numerically but logically
        -- behind us, step backward through clones to get there
        local delta = target - self._ctx.selected
        local wrap = delta > 0 and (delta - N) or delta
        self._ctx.pos = self._ctx.pos + wrap
    end
    self._ctx.selected = target
    if self._ctx.truncating then self:_scheduleSettle() end
end

function ZeD_ContextMenu:confirm()
    local items = self._ctx.items
    local def = items[self._ctx.selected]
    if not def then return end
    if def.isBack then self:_pop(); return end
    if def.disabled and def.disabled(self._ctx.target) then return end

    -- S99: lazy-populate children for options with a vanilla `subOption` that
    -- wasn't populated at build time (some mods add submenu options only on
    -- hover via onSubMenu; gamepad users never hover). Fire onSubMenu, then
    -- re-read the vanilla submenu's options and rebuild children.
    if def.subOption and def._vanillaMenu and (not def.children or #def.children == 0) then
        local vm = def._vanillaMenu
        local vanillaOpt = def.vanillaRef
        if vanillaOpt and vanillaOpt.onSubMenu then
            pcall(function()
                vanillaOpt:onSubMenu(vm, vanillaOpt)
            end)
        end
        if vm.getSubMenu then
            local ok, sub = pcall(function() return vm:getSubMenu(def.subOption) end)
            if ok and sub and sub.options and #sub.options > 0 then
                local mk = ZeD.ContextMenu.Registry._makeActionDef
                if mk then
                    def.children = {}
                    for j, subOpt in ipairs(sub.options) do
                        def.children[#def.children + 1] = mk(subOpt, j, sub, self._ctx.target)
                    end
                end
            end
        end
    end

    if def.children and #def.children > 0 then
        -- Push raw index (top-level = selected; in submenu subtract 1 for back cell)
        local rawIdx = (#self._ctx.path == 0) and self._ctx.selected or (self._ctx.selected - 1)
        self:_push(rawIdx)
        return
    end
    -- Leaf action → fire + close
    if def.onFire then
        pcall(def.onFire, self._ctx.target)
    end
    self:close()
end

function ZeD_ContextMenu:cancel()
    if #self._ctx.path == 0 then self:close(); return end
    self:_pop()
end

function ZeD_ContextMenu:_push(rawIdx)
    table.insert(self._ctx.path, rawIdx)
    self._ctx.selected = 2   -- skip back cell at position 1
    self:_rebuildTrack()
end

function ZeD_ContextMenu:_pop()
    local exiting = table.remove(self._ctx.path)
    -- If we're back at top level, restore selection to the exiting parent's
    -- top-level index. In submenus, put selection at exiting + 1 (post-back).
    if #self._ctx.path == 0 then
        self._ctx.selected = exiting
    else
        self._ctx.selected = exiting + 1
    end
    self:_rebuildTrack()
end

-- ============================================================================
-- SETTLE TIMER — the silent teleport that keeps the triple-render carousel
-- anchored in the middle copy after an edge-crossing scroll.
-- ============================================================================

function ZeD_ContextMenu:_scheduleSettle()
    if not self._ctx.truncating then return end
    self._settleAt = getTimestampMs() + ZeD.T.ctx.animMs + 20
end

function ZeD_ContextMenu:_settleCarousel()
    local N = #self._ctx.items
    if N == 0 then return end
    if self._ctx.pos < N + 1 or self._ctx.pos > 2 * N then
        -- Normalize pos into the middle copy
        self._ctx.pos = ((self._ctx.pos - 1) % N) + N + 1
        -- Skip animation for one frame so the teleport is silent. _layout
        -- recomputes targetOriginX from the normalized pos and snaps
        -- currentOriginX to it immediately (progress = 1 during suppress).
        self._suppressFrames = 1
    end
end

-- ============================================================================
-- UPDATE — runs every frame. Handles settle timer + outside-click detection.
-- ============================================================================

function ZeD_ContextMenu:update()
    ZeD_Panel.update(self)

    -- Settle timer (truncating mode only)
    if self._settleAt and getTimestampMs() >= self._settleAt then
        self._settleAt = nil
        self:_settleCarousel()
    end

    -- Mouse hover tracking — update _hoveredId so cells / bumpers can use it
    -- (we already re-register hit zones each prerender; here we just probe)
    local mx = self:getMouseX()
    local my = self:getMouseY()
    local zone = self:hitZoneAt(mx, my)
    self._hoveredId = zone and zone.id or nil

    -- If mouse-hover over a cell, update selection (mouse-track selection
    -- mirrors vanilla ISContextMenu and the mockup behavior).
    -- S103: in truncating mode, hover updates `selected` ONLY — no longer
    -- writes to `pos` (the carousel scroll offset). Previously every cell
    -- the cursor entered kicked a recentering animation, so a simple left-
    -- or-right cursor drag scrolled the list at cursor speed (one cell per
    -- ~22px of pointer motion). Hover = selection; scroll = chev / bumper /
    -- keyboard / gamepad. Matches vanilla's behavior where cursor motion
    -- highlights the hovered option but doesn't pan the menu.
    if zone and type(zone.id) == "string" and zone.id:sub(1, 8) == "ctxcell_" then
        local trackIdx = tonumber(zone.id:sub(9))
        if trackIdx then
            local items = self._ctx.items
            local N = #items
            self._ctx.selected = ((trackIdx - 1) % N) + 1
        end
    end
end

-- ============================================================================
-- MOUSE INPUT
-- ============================================================================

function ZeD_ContextMenu:onMouseDown(x, y)
    local zone = self:hitZoneAt(x, y)
    if not zone then return end
    if zone.id == "ctxbump_l" or zone.id == "ctxchev_l" then
        self._pressedId = zone.id
    elseif zone.id == "ctxbump_r" or zone.id == "ctxchev_r" then
        self._pressedId = zone.id
    end
end

function ZeD_ContextMenu:onMouseUp(x, y)
    local zone = self:hitZoneAt(x, y)
    self._pressedId = nil
    if not zone then
        -- LMB inside our panel but outside any action target (bubble area,
        -- inter-element gaps, etc.) → dismiss. The panel's bounding box is
        -- larger than the visible chrome to make room for the bubble; without
        -- this, clicks on the bubble do nothing and the user can't easily
        -- get out via mouse without finding the strip.
        self:close()
        return
    end
    if zone.id == "ctxbump_l" then
        self:prevGroup()
    elseif zone.id == "ctxbump_r" then
        self:nextGroup()
    elseif zone.id == "ctxchev_l" then
        self:prev()
    elseif zone.id == "ctxchev_r" then
        self:next()
    elseif type(zone.id) == "string" and zone.id:sub(1, 8) == "ctxcell_" then
        -- Cell click → confirm (selection was already set on hover)
        self:confirm()
    end
end

-- Right-click while the menu is open: dismiss this menu so the user can
-- re-RMB at a new spot. Our panel's bounding box extends well above the
-- strip to make room for the info bubble, so RMBs that land in that
-- bubble area would otherwise be trapped here without this handler.
--
-- Note: this is a TWO-click flow (first RMB dismisses, second RMB opens
-- the new menu). Synthesizing a redirected world RMB from Lua isn't
-- portable across PZ versions — we ship the predictable close-only
-- behavior and let the player re-click.
function ZeD_ContextMenu:onRightMouseDown(x, y)
    -- Right-click always fully dismisses (does NOT pop a submenu level —
    -- intent is "abort and try elsewhere"). Keyboard Esc / gamepad B still
    -- pop submenus per spec §5.
    self:close()
end

function ZeD_ContextMenu:onRightMouseUp(x, y)
    -- Defensive: PZ sometimes routes UP without a matching DOWN (capture loss)
end

function ZeD_ContextMenu:onRightMouseDownOutside(x, y)
    self:close()
end

function ZeD_ContextMenu:onMouseUpOutside(x, y)
    -- Click outside the menu closes it outright, from any submenu depth
    -- (Esc and gamepad B still step back one level through cancel)
    self:close()
end

-- Scroll wheel inside the menu advances the selection (bonus mouse affordance)
function ZeD_ContextMenu:onMouseWheel(del)
    -- del > 0 scrolls down in PZ — we remap to next/prev
    if del > 0 then self:next() else self:prev() end
    return true
end

-- ============================================================================
-- GAMEPAD INPUT
-- ============================================================================
--   A (Cross)   = confirm
--   B (Circle)  = cancel / pop
--   LB          = prevGroup
--   RB          = nextGroup
--   D-pad L/R   = prev/next
-- ============================================================================

function ZeD_ContextMenu:onJoypadDown(button)
    -- Directional nav (D-pad L/R) intentionally NOT handled here — PZ fires
    -- both onJoypadDown(Joypad.DPadLeft/Right) AND onJoypadDirLeft/Right for
    -- a single physical D-pad press. If we handle both, each press advances
    -- TWO cells instead of one and some items become unreachable. onJoypad-
    -- Dir* below is the named directional path; we own that one. This block
    -- is for discrete buttons only.
    if button == Joypad.AButton then
        self:confirm()
    elseif button == Joypad.BButton then
        self:cancel()
    elseif button == Joypad.LBumper then
        self:prevGroup()
    elseif button == Joypad.RBumper then
        self:nextGroup()
    end
end

function ZeD_ContextMenu:onJoypadDirUp(joypadData)
    -- No-op: menu is horizontal, up/down have no meaning at top level
end
function ZeD_ContextMenu:onJoypadDirDown(joypadData) end

function ZeD_ContextMenu:onJoypadDirLeft(joypadData)  self:prev() end
function ZeD_ContextMenu:onJoypadDirRight(joypadData) self:next() end

-- ============================================================================
-- KEYBOARD INPUT (spec §5)
-- ============================================================================

-- The keys the strip takes, so the game does not also act on them (Escape
-- would otherwise open the pause menu over the strip). Built once at load.
local NAV = {}
if Keyboard then
    NAV = { [Keyboard.KEY_LEFT] = true, [Keyboard.KEY_RIGHT] = true, [Keyboard.KEY_RETURN] = true,
            [Keyboard.KEY_ESCAPE] = true, [Keyboard.KEY_BACK] = true, [Keyboard.KEY_TAB] = true }
end
function ZeD_ContextMenu:isKeyConsumed(key) return NAV[key] == true end

function ZeD_ContextMenu:onKeyPress(key)
    if     key == Keyboard.KEY_LEFT   then self:prev()
    elseif key == Keyboard.KEY_RIGHT  then self:next()
    elseif key == Keyboard.KEY_RETURN then self:confirm()
    elseif key == Keyboard.KEY_ESCAPE or key == Keyboard.KEY_BACK then self:cancel()
    elseif key == Keyboard.KEY_TAB    then
        -- Shift-Tab = prevGroup, Tab = nextGroup
        if isKeyDown and isKeyDown(Keyboard.KEY_LSHIFT) then self:prevGroup()
        else self:nextGroup() end
    end
end

-- ============================================================================
-- POSITIONING — anchors the organism panel in screen space.
-- Called once on open() and again when the anchor mode demands it (split-
-- screen viewport changes, etc.)
-- ============================================================================

function ZeD_ContextMenu:_positionAssembly()
    local T = ZeD.T
    local ctx = T.ctx
    -- Panel sized to hold the bubble on EITHER side of the strip — worst
    -- case is the same in both orientations (bubble extends ~bubbleReserve
    -- past the strip, ~stripH for the strip itself, edge buffers either side).
    local estW = T.px(400)
    local bubbleReserve = T.px(160)        -- max bubble + pointer + padding
    local stripHLocal   = ctx.cellH + ctx.drilledBorderTop + T.px(1)
    local edgeBuffer    = T.px(8)
    local estH = bubbleReserve + stripHLocal + edgeBuffer
    self:setWidth(estW)
    self:setHeight(estH)

    -- Decide flip direction: when there's not enough room ABOVE the cursor
    -- for the bubble, flip and put the bubble BELOW the strip with an
    -- upward-pointing tail. If both sides fit, prefer normal (bubble above).
    local cursorGap = T.px(6)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local pad = T.px(8)

    self._flipped = false
    if self.anchorMode ~= "dock" then
        local spaceAbove = self._anchorY - pad
        local spaceBelow = screenH - self._anchorY - pad
        local needed = bubbleReserve + stripHLocal + cursorGap
        if spaceAbove < needed and spaceBelow > spaceAbove then
            self._flipped = true
        end
    end

    -- Strip Y in panel-local depends on flip. _layout reads the same value
    -- via self._stripYLocal so layout math stays consistent.
    if self._flipped then
        self._stripYLocal = edgeBuffer            -- strip near top, bubble below
    else
        self._stripYLocal = bubbleReserve         -- strip near bottom, bubble above
    end
    local stripBottomLocal = self._stripYLocal + stripHLocal

    local sx, sy
    if self.anchorMode == "dock" then
        -- Gamepad docked anchor: bottom-center of player's viewport, lifted
        -- above the moodle area.
        local psL = getPlayerScreenLeft   and getPlayerScreenLeft(self.player)   or 0
        local psT = getPlayerScreenTop    and getPlayerScreenTop(self.player)    or 0
        local psW = getPlayerScreenWidth  and getPlayerScreenWidth(self.player)  or getCore():getScreenWidth()
        local psH = getPlayerScreenHeight and getPlayerScreenHeight(self.player) or getCore():getScreenHeight()
        sx = psL + math.floor((psW - estW) / 2)
        local moodleAllowance = ZeD.T.px(140)   -- clearance for the belt and the bottom moodle row, which are ZeD's now and scale (code audit Oct 17 2026)
        sy = psT + psH - estH - moodleAllowance
    else
        -- Cursor anchor — center the strip horizontally on the click point,
        -- then anchor vertically depending on flip:
        --   normal:  strip BOTTOM at cursorY - cursorGap (cursor sits right
        --            below strip; bubble extends UP into space above)
        --   flipped: strip TOP at cursorY + cursorGap (cursor sits right
        --            above strip; bubble extends DOWN into space below)
        sx = self._anchorX - math.floor(estW / 2)
        if self._flipped then
            sy = self._anchorY + cursorGap - self._stripYLocal
        else
            sy = self._anchorY - cursorGap - stripBottomLocal
        end
        if sx < pad then sx = pad end
        if sx + estW > screenW - pad then sx = screenW - estW - pad end
        if sy < pad then sy = pad end
        if sy + estH > screenH - pad then sy = screenH - estH - pad end
    end
    self:setX(sx)
    self:setY(sy)
end
