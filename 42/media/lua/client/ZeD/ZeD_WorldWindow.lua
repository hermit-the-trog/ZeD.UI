-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WorldWindow.lua
-- ============================================================================
-- WORLD WINDOW — "the world and its stuff"
-- Action tab waterfall + placeholder cards + multi-container columns.
-- Container strip LEFT, item list CENTER, drawer RIGHT, action tabs RIGHT EDGE.
-- Ctrl+Click containers for MC columns. XFER strips + cross-column drag-drop.
--
-- Does NOT touch ISInventoryPage. Does NOT register with Java UIManager.
-- Plain ZeD_Window shell with ZeD_Panel content area.
-- ============================================================================

require "ISUI/ISPanel"
require "ISUI/ISMouseDrag"
require "ISUI/ISInventoryPage"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_Panel"
require "ZeD/InventoryRenderer"
require "ZeD/ItemCard"
require "ZeD/CraftingTab"
require "ZeD/BuildingTab"
require "ZeD/MapsTab"
require "ZeD/ForagingTab"
require "ZeD/AnimalsTab"
require "ZeD/RadioTab"
require "ZeD/MechanicsTab"

ZeD = ZeD or {}
ZeD_WorldWindow = {}

-- Shared renderer functions (lazy-init after TestInventory loads)
local R = nil
local function getR()
    if not R then R = ZeD.InventoryRenderer end
    return R
end

-- ============================================================================
-- CONSTANTS
-- S124 scale: every constant below is a DESIGN UNIT (1 px at 1080p). Each use
-- goes through T.px(...) at call time; never add them to screen px unwrapped.
-- ============================================================================

local CONTAINER_STRIP_W    = 36
local CONTAINER_BTN_SZ     = 36
local STRIP_SCROLL_ROW_H   = 16
local DRAWER_W             = 260
local ITEM_CARD_W          = 220
local TAB_DRAWER_W         = 480
local DRAWER_PX_SPEED      = DRAWER_W * 8   -- ~2080 design units/sec, matches char window; scaled at use (T.px(DRAWER_PX_SPEED) * dt)
local ACTION_TAB_STRIP_W   = 36
local ACTION_TAB_BTN_SZ    = 36
-- Tab strip separator (matches CharacterWindow). Moved up from line ~207 in
-- S94 because _buildWorldTabBarElements references these — forward-local refs
-- capture nil in Kahlua (common mistake #16).
local TAB_SEP_H            = 1
local TAB_SEP_MAR          = 2

-- Action tab definitions — group 2 reserved for contextual tabs
local WORLD_TABS = {
    { id = "loot",   label = "Loot",     group = 1, glyph = "L", icon = getTexture("media/textures/ZeD/TabIcons/loot-tab-white.png") },
    { id = "craft",  label = "Crafting", group = 1, glyph = "C", icon = getTexture("media/textures/ZeD/TabIcons/craft-tab-white.png") },
    { id = "build",  label = "Building", group = 1, glyph = "B", icon = getTexture("media/textures/ZeD/TabIcons/build-tab-white.png") },
    { id = "maps",   label = "Maps",     group = 2, glyph = "M", icon = getTexture("media/textures/ZeD/TabIcons/map-tab-white.png") },
    { id = "forage", label = "Foraging", group = 2, glyph = "F", icon = getTexture("media/textures/ZeD/TabIcons/forage-tab-white.png"),
      visible = function(win) return true end },  -- always visible (informational surface)
    { id = "animals", label = "Animals", group = 2, glyph = "A", icon = getTexture("media/textures/ZeD/TabIcons/farm-tab-white.png") },
    -- S115: Radio (contextual) — visible when at least one IsoWaveSignal radio
    -- is reachable in the player's 3x3 grid. Same predicate model as Foraging.
    { id = "radio",  label = "Radio",    group = 2, glyph = "R",
      icon = getTexture("media/textures/ZeD/TabIcons/radio-tab-white.png"),
      visible = function(win)
          return win and win._radios and #win._radios > 0
      end },
    -- S124: Vehicle (contextual) — vehicle mechanics. Visible while a vehicle is
    -- within reach or an inspected one is within six tiles (ZeD.MechanicsTab).
    { id = "vehicle", label = "Vehicle", group = 2, glyph = "V",
      icon = getTexture("media/textures/ZeD/TabIcons/vehicle-tab-white.png"),
      visible = function(win)
          return ZeD.MechanicsTab and ZeD.MechanicsTab.isVisible(win)
      end },
}

-- Check if a tab is visible (tabs without a visible predicate are always shown)
local function isTabVisible(tab, win)
    if not tab.visible then return true end
    return tab.visible(win)
end

-- ============================================================================
-- S94 B-NAV — GAMEPAD FOCUS SUPPORT (World Window)
-- Mirrors ZeD_CharacterWindow's pattern: builds a tabBar focusable list and
-- switches tabs on D-pad cycle. No panel-level focusables this session —
-- Character Window's Loot tab is S94's cone-nav proof point, so World's panel
-- focusables stay empty. S95+ wires real per-tab focusables here.
--
-- Ordering note: placed AFTER isTabVisible so `_buildWorldTabBarElements` can
-- reference it as a resolved upvalue. `_switchWorldTabForNav` is forward-
-- declared as a local slot then assigned inside toggle() because its body
-- references `exitWorldMC` which lives even further down the file.
-- ============================================================================

-- Forward declaration — assigned inside toggle() after its upvalues (exitWorldMC,
-- getWorldActiveScroll) are in scope. Kahlua common mistake #16: closures cannot
-- capture locals declared below them, so we reserve the slot here then fill it
-- lower in the file.
local _switchWorldTabForNav

-- S96: forward-declare _buildWorldInvRowFocusables so container onConfirm can
-- reference it. Assigned below after the definition.
local _buildWorldInvRowFocusables

-- S98: forward-declarations for ring-sync helpers + builders that
-- _syncWorldRingZones references. Each is assigned later (where its own
-- dependencies are in scope). Common mistake #16.
local _buildWorldPanelFocusables
local _buildWorldLootFocusables
local _buildWorldMCColumnFocusables
local _clearGpFocusState
local _syncWorldRingZones
-- S99: worldItemCard zone builder — delegates to win._itemCard's shared API.
local _buildWorldCardActionFocusables
-- S108 Q104 fix: `exitWorldMC` and `mcToggleWorldContainer` are consumed by
-- the onHoldActivate/onActivate closures inside `_buildWorldLootFocusables`
-- (line ~170+). Without hoisting, those closures capture the names as
-- globals at creation time — `if mcToggleWorldContainer then` silently
-- short-circuits, so hold-A on a container does nothing. Mirrors Char's
-- order (mcToggleContainer defined at line 303, above its consumers).
local exitWorldMC
local mcToggleWorldContainer

-- Build the World Window's tabBar focusables. Honors each tab's `visible`
-- predicate so hidden tabs (e.g., contextual tabs without their prerequisite)
-- don't leave empty focus slots. Bounds match drawWorldTabStrip's curY math.
local function _buildWorldTabBarElements(win)
    local T = ZeD.T
    local elements = {}
    local curY = 0
    local lastGroup = 1
    for i, tab in ipairs(WORLD_TABS) do
        if isTabVisible(tab, win) then
            if tab.group ~= lastGroup then
                curY = curY + T.px(TAB_SEP_MAR) + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
                lastGroup = tab.group
            end
            elements[#elements + 1] = {
                x = 0, y = curY, w = T.px(ACTION_TAB_BTN_SZ), h = T.px(ACTION_TAB_BTN_SZ),
                id       = "tab:" .. tab.id,
                tabId    = tab.id,
                tabIndex = i,
            }
            curY = curY + T.px(ACTION_TAB_BTN_SZ)
        end
    end
    return elements
end

-- S95 — Build container strip focusables for World's Loot tab. Strip lives
-- on the LEFT edge of the window (x=0..CONTAINER_STRIP_W). Coordinates in
-- window-local space so the cone algorithm can traverse tabBar<->panel
-- without a frame mismatch.
-- S95 v3: onFocus auto-activates, matching the tab-strip behavior.
-- S113c: shared gamepad-drag reorder for World container strip. Mirror of
-- _gpReorderCharContainer. World containers don't have a stable
-- _containerOrder structure equivalent to Char's — World uses listEntries
-- built per-frame and supports sort modes. The reorder mutates listEntries
-- (or the underlying container array) and forces sortMode = "dist" so the
-- manual order persists. Floor container is pinned and not reorderable.
local function _gpReorderWorldContainer(win, containerIdx, dir)
    if not win or not containerIdx then return end
    local containers = win._containers
    if not containers or #containers == 0 then return end
    -- World stores order via _containerOrder same as Char (per S107+).
    -- If absent, build identity order on the fly.
    local order = win._containerOrder
    if not order or #order == 0 then
        order = {}
        for i = 1, #containers do order[i] = i end
        win._containerOrder = order
    end
    local srcIdx
    for oi, ci in ipairs(order) do
        if ci == containerIdx then srcIdx = oi; break end
    end
    if not srcIdx then return end
    local target
    if dir == "up" and srcIdx > 1 then
        target = srcIdx - 1
    elseif dir == "down" and srcIdx < #order then
        target = srcIdx + 1
    end
    if not target then return end
    -- Skip-floor: if the target slot holds the floor container, hop past it.
    -- Floor is conventionally at containers[#containers] with isFloor=true;
    -- it appears in the order array but reordering should not displace it.
    local function isFloorAt(orderIdx)
        local ci = order[orderIdx]
        local cnt = ci and containers[ci]
        return cnt and cnt.isFloor
    end
    if isFloorAt(target) then
        if dir == "up" and target > 1 then target = target - 1
        elseif dir == "down" and target < #order then target = target + 1
        else return end
        if isFloorAt(target) then return end
    end
    local val = table.remove(order, srcIdx)
    table.insert(order, target, val)
    win._containerSortByWT = false
    win._containerSortMode = "dist"
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if Focus and Focus.setRingZoneElements then
        local newEls = _buildWorldLootFocusables(win) or {}
        local newIdx = 1
        for i, el in ipairs(newEls) do
            if el.containerIdx == containerIdx then newIdx = i; break end
        end
        Focus.setRingZoneElements(win, "worldContainerStrip", newEls, newIdx)
    end
end

_buildWorldLootFocusables = function(win)
    if not win or not win._containers then return {} end
    local n = #win._containers
    if n == 0 then return {} end
    local T = ZeD.T
    local stripY = win:getBodyY()
    -- S108: match the visual render layout of drawWorldContainerStrip exactly.
    -- Strip visual order:
    --   Zone 1 (floor, pinned top) at y=stripY — containers[#containers]
    --   Zone 2 (sort row, NOT focusable) at y=stripY+CONTAINER_BTN_SZ+1, h=20
    --   Zone 3 (scrollable non-floor list) starts at zone3Y = stripY + 37 + 20
    --
    -- Prior (S98) builder stamped elements at (i-1)*36 with containerIdx=i,
    -- which mis-mapped every row:
    --   - floor (containers[n], rendered at TOP) got element position BOTTOM
    --   - non-floor element 2 landed visually on the sort row
    --   - element.containerIdx didn't track listEntries sort reorder
    --
    -- Also fixed: onActivate's `cnt.isMain` read returned nil on World (World
    -- containers use `isFloor`, not `isMain`) — _mainVisible was always false,
    -- floor button never painted active when re-selected.
    --
    -- Mirrors Char S106 _buildLootFocusables pattern exactly, inverted for
    -- World's container layout (floor = last index, pinned top).
    local colHdrH = T.px(20)
    local zone3Y = stripY + T.px(CONTAINER_BTN_SZ) + T.px(1) + colHdrH

    local elements = {}
    local floorIdx = n
    local floorCnt = win._containers[floorIdx]
    if floorCnt and floorCnt.isFloor then
        elements[#elements + 1] = {
            x = 0, y = stripY, w = T.px(CONTAINER_STRIP_W), h = T.px(CONTAINER_BTN_SZ),
            id = "container:" .. tostring(floorIdx),
            containerIdx = floorIdx,
            -- S108 QA: onFocus no longer mutates _activeContainer (Char S106
            -- parity). D-pad cycling on the strip moves focus cue only — the
            -- active container (=the currently-displayed view) is set via
            -- tap-A (onActivate) or hold-A (mcToggle adds to MC without
            -- changing _activeContainer). Without this, every focused
            -- container satisfied `cIdx == _activeContainer` in mcToggle,
            -- hitting the floor-only branch and breaking non-first MC adds.
            onFocus = function(w, el) end,
            -- S107 QA tap = single-view (exit MC, set active + mainVisible).
            -- S108 fix: check `isFloor` not `isMain` — World containers don't
            -- have an isMain field.
            onActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                local cnt = w._containers and w._containers[el.containerIdx]
                local isFloor = cnt and cnt.isFloor and true or false
                if w._activeTab == "loot"
                   and w._mcSelected and #w._mcSelected > 0
                   and exitWorldMC then
                    exitWorldMC(w, c)
                end
                w._activeContainer = el.containerIdx
                w._mainVisible     = isFloor
            end,
            onHoldActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                if w._activeTab == "loot" then
                    if mcToggleWorldContainer then
                        mcToggleWorldContainer(w, c, el.containerIdx)
                    end
                else
                    w._activeContainer = el.containerIdx
                end
            end,
        }
    end

    -- Elements 2..N: non-floor containers in listEntries display order.
    -- Replicate drawWorldContainerStrip's listEntries build + sort so focus
    -- element y-coords track the actual rendered positions.
    local listEntries = {}
    for i, c in ipairs(win._containers) do
        if not c.isFloor then
            listEntries[#listEntries + 1] = i
        end
    end
    local sortMode = win._containerSortMode or "dist"
    if sortMode == "wt" then
        table.sort(listEntries, function(a, b)
            local wa = win._containers[a].inventory and win._containers[a].inventory:getCapacityWeight() or 0
            local wb = win._containers[b].inventory and win._containers[b].inventory:getCapacityWeight() or 0
            return wa > wb
        end)
    elseif sortMode == "type" then
        table.sort(listEntries, function(a, b)
            return (win._containers[a].name or "") < (win._containers[b].name or "")
        end)
    end

    for pos, ci in ipairs(listEntries) do
        local cy = zone3Y + (pos - 1) * T.px(CONTAINER_BTN_SZ)
        elements[#elements + 1] = {
            x = 0, y = cy, w = T.px(CONTAINER_STRIP_W), h = T.px(CONTAINER_BTN_SZ),
            id = "container:" .. tostring(ci),
            containerIdx = ci,
            -- S108 QA: onFocus no longer mutates _activeContainer (Char S106
            -- parity). D-pad cycling on the strip moves focus cue only — the
            -- active container (=the currently-displayed view) is set via
            -- tap-A (onActivate) or hold-A (mcToggle adds to MC without
            -- changing _activeContainer). Without this, every focused
            -- container satisfied `cIdx == _activeContainer` in mcToggle,
            -- hitting the floor-only branch and breaking non-first MC adds.
            onFocus = function(w, el) end,
            onActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                local cnt = w._containers and w._containers[el.containerIdx]
                local isFloor = cnt and cnt.isFloor and true or false
                if w._activeTab == "loot"
                   and w._mcSelected and #w._mcSelected > 0
                   and exitWorldMC then
                    exitWorldMC(w, c)
                end
                w._activeContainer = el.containerIdx
                w._mainVisible     = isFloor
            end,
            onHoldActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                if w._activeTab == "loot" then
                    if mcToggleWorldContainer then
                        mcToggleWorldContainer(w, c, el.containerIdx)
                    end
                else
                    w._activeContainer = el.containerIdx
                end
            end,
            -- S113c: HOLD X + D-pad UP/DOWN = reorder this container in the
            -- strip (mouse-drag parity). Mirror of Char's container drag
            -- binding. Floor container above is intentionally NOT given
            -- this binding — it stays pinned at top, like main on Char.
            onHoldContextDrag = function(w, el, dir)
                if dir == nil then return end
                _gpReorderWorldContainer(w, el.containerIdx, dir)
            end,
            onHoldContextRelease = function(w, el)
                -- Commit is implicit (order already updated). No rollback.
            end,
        }
    end
    return elements
end

-- S109b — Foraging tab focusables.
-- Composition (top to bottom in the tab):
--   1. SEARCH stance button    — A toggles ISSearchManager search mode
--   2. Focus dropdown          — A opens/commits, D-pad nav inside, B closes
--   3. MORE DETAIL disclosure  — A + L/R tree-nav toggles _moreDetailOpen
--   4. Grid-scroll pseudo      — D-pad U/D scrolls win._forageScroll; at
--                                bounds falls through to cone nav so user
--                                escapes back upward
-- Crouch/Aim stance tiles stay non-focusable per feedback_stance_status_only.
local function _buildForageFocusables(win)
    if not win then return {} end
    local elements = {}
    local T = ZeD.T

    -- 1. SEARCH stance button.
    local stanceZones = win._forageStanceZones
    if stanceZones then
        for _, z in ipairs(stanceZones) do
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "forage:stance:" .. tostring(z.id),
                isStance = true,
                stanceId = z.id,
                onFocus = function(w, el)
                    w._gpFocusedForageStance = el.stanceId
                end,
                onActivate = function(w, el)
                    local player = w._playerObj
                    local mgr = player and ISSearchManager
                                 and ISSearchManager.getManager
                                 and ISSearchManager.getManager(player)
                    if mgr and mgr.toggleSearchMode then
                        mgr:toggleSearchMode()
                    end
                end,
            }
        end
    end

    -- 2. FOCUS DROPDOWN. A toggles open/commit; while open, D-pad U/D is
    -- intercepted at win-level to shift dd.hoveredIndex + scrollOffset.
    -- B closes without committing — only when open (else B should fall
    -- through to shade-all per ring model).
    local dd = win._forageDropdown
    if dd and dd.getX then
        local ddH = (T and T.inputH) or 20
        local el = {
            x = dd:getX(), y = dd:getY(), w = dd:getWidth(), h = ddH,
            id = "forage:dropdown",
            isDropdown = true,
            onActivate = function(w, el)
                local d = w._forageDropdown
                if not d then return end
                if d.isOpen then
                    local idx = d.hoveredIndex
                    if idx and idx >= 1 and idx <= #d.options then
                        d.selectedId = d.options[idx].id
                        if d.onChange then d.onChange(d, d.selectedId) end
                    end
                    d.isOpen = false
                    d.scrollOffset = 0
                    if d.setHeight then d:setHeight((T and T.inputH) or 20) end
                else
                    d.isOpen = true
                    d.hoveredIndex = -1
                    for i, opt in ipairs(d.options or {}) do
                        if opt.id == d.selectedId then
                            d.hoveredIndex = i
                            break
                        end
                    end
                    if d.hoveredIndex < 1 then d.hoveredIndex = 1 end
                    -- Widget auto-resizes on next render via its own maxVis
                    -- compute; we just flip the flag.
                end
            end,
        }
        -- onCancel returns false when closed so FocusManager falls through
        -- to shade-all. When open, close without commit and consume B.
        el.onCancel = function(w)
            local d = w._forageDropdown
            if not (d and d.isOpen) then return false end
            d.isOpen = false
            d.scrollOffset = 0
            if d.setHeight then d:setHeight((T and T.inputH) or 20) end
            return true
        end
        elements[#elements + 1] = el
    end

    -- 3. MORE DETAIL disclosure.
    local dz = win._forageDisclosureZone
    if dz then
        elements[#elements + 1] = {
            x = dz.x, y = dz.y, w = dz.w, h = dz.h,
            id = "forage:disclosure",
            isDisclosure = true,
            sectionKey = "moreDetail",  -- used by L/R tree-nav branch
            onActivate = function(w, el)
                w._moreDetailOpen = not (w._moreDetailOpen or false)
            end,
        }
    end

    -- 4. GRID SCROLL pseudo (S102 pattern). Only present when content
    -- overflows. D-pad U/D scrolls win._forageScroll; handler lives in
    -- onJoypadDirUp/Down below. Bounds span the full viewport width so the
    -- element center-x aligns with the disclosure/dropdown above — keeps
    -- cone-nav UP from the scroll back up to the disclosure working.
    local scroll = win._forageScroll
    if scroll and scroll.visible and scroll.height and scroll.height > 0 then
        local sbW = (T and T.sp and T.sp.scrollbarW) or 10
        local viewW = (scroll.x or ((T and T.px) and T.px(460) or 460)) + sbW
        elements[#elements + 1] = {
            x = 0, y = scroll.y or 0,
            w = viewW, h = scroll.height,
            id = "forage:scroll",
            isGridScroll = true,
            -- No onActivate / onFocus — pure scroll surface.
            -- S113: D-pad U/D scrolls _forageScroll; at limits, fall through
            -- to cone-nav so user can escape upward to disclosure / dropdown.
            onDpadDir = function(w, _el, dir)
                local sc = w._forageScroll
                if not sc then return false end
                local pos = sc.scrollPos or 0
                if dir == "down" and pos < 1 then
                    sc:setScrollPos(pos + 0.08); return
                elseif dir == "up" and pos > 0 then
                    sc:setScrollPos(pos - 0.08); return
                end
                return false
            end,
        }
    end

    -- Legacy seed kept for any mouse-path reader; harmless otherwise.
    if elements[1] and elements[1].stanceId then
        win._gpFocusedForageStance = elements[1].stanceId
    end
    return elements
end

-- S109 — Animals tab focusables: state-machine aggregator.
-- Composition varies by (submode × view):
--   ranch overview  → [submode pills, Alerts+Totals disclosures, zone cards]
--   ranch zone      → [submode pills, breadcrumb back, sort btn, roster rows]
--   ranch animal    → [submode pills, breadcrumb back]  (detail = readout)
--   butcher overview→ [submode pills, butcher roster rows]
--   butcher animal  → [submode pills, breadcrumb back]
--
-- Submode pills use onFocus live-switch (no A-press — feedback_no_confirm_for
-- _no_chain). Disclosures toggle via A (onActivate) AND L/R tree-nav (wired in
-- onJoypadDirLeft/Right below). Rosters + zone cards navigate via AT.navigate.
-- Alerts stay readout-only per design director direction.
-- Zone-create / rename / remove confirmation footers are mouse-only (gamepad
-- can't meaningfully drive drag-to-draw or modal YES/NO text prompts in one
-- shot; deferred).
local function _buildAnimalsFocusables(win)
    if not win then return {} end
    local AT = ZeD and ZeD.AnimalsTab
    if not AT or not AT.getState then return {} end
    local state = AT.getState(win)

    -- S109a: Zone-create mode. Ring collapses to a single zone-draw pseudo-
    -- focusable; D-pad is intercepted at win-level for cursor movement,
    -- A fires onActivate (phase advance via gpConfirm), B fires onCancel
    -- (phase back-step via gpCancel — hooked in FocusManager._handleBTap).
    -- id includes phase so the ring rebuilds when phase changes (forces
    -- onFocus re-fire / dirty-check).
    local zc = win._zoneCreate
    if zc and zc.active then
        return {
            {
                x = 0, y = 0, w = 0, h = 0,
                id = "animals:zonedraw:" .. tostring(zc.phase),
                isZoneDraw = true,
                phase = zc.phase,
                onActivate = function(w)
                    if AT.gpConfirm then AT.gpConfirm(w) end
                end,
                onCancel = function(w)
                    if AT.gpCancel then AT.gpCancel(w) end
                end,
                -- S113: D-pad moves the ground cursor by 1 tile per press.
                -- Element-level onDpadDir replaces the win-level isZoneDraw
                -- intercept (deleted alongside the joypad direction wrappers).
                onDpadDir = function(w, _el, dir)
                    if not (AT and AT.gpMoveCursor) then return false end
                    if     dir == "left"  then AT.gpMoveCursor(w, -1, 0)
                    elseif dir == "right" then AT.gpMoveCursor(w,  1, 0)
                    elseif dir == "up"    then AT.gpMoveCursor(w, 0, -1)
                    elseif dir == "down"  then AT.gpMoveCursor(w, 0,  1)
                    else return false end
                    return
                end,
            },
        }
    end

    local elements = {}

    -- 1. Submode pills (always present — live-switch on focus).
    -- Active submode first so preserveIdx=1 seeds to the current submode
    -- (cold tab entry otherwise live-switches back to ranch every time,
    -- losing butcher state).
    local subZones = win._animalsSubmodeZones
    if subZones then
        local activeFirst = {}
        for _, z in ipairs(subZones) do
            if z.id == state.submode then activeFirst[#activeFirst + 1] = z end
        end
        for _, z in ipairs(subZones) do
            if z.id ~= state.submode then activeFirst[#activeFirst + 1] = z end
        end
        for _, z in ipairs(activeFirst) do
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "animals:submode:" .. tostring(z.id),
                isSubmode = true,
                submodeId = z.id,
                -- S123: GAMEPAD_SPEC parity with the Journal pills — focus paints,
                -- A switches the sub-mode.
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    local s = w._animalsState
                    if s and s.submode ~= el.submodeId and AT.switchSubmode then
                        AT.switchSubmode(w, el.submodeId)
                    end
                end,
            }
        end
    end

    -- 2. Breadcrumb back (zone/animal views only).
    if (state.view == "zone" or state.view == "animal")
       and win._animalsBreadcrumbZone then
        local z = win._animalsBreadcrumbZone
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h,
            id = "animals:back:" .. tostring(state.view),
            isBreadcrumb = true,
            onActivate = function(w)
                if AT.navigateBack then AT.navigateBack(w) end
            end,
        }
    end

    -- 3. View-specific elements.
    if state.submode == "ranch" and state.view == "overview" then
        -- Section cat headers — only the ones with real disclosure toggles
        -- (alerts, totals). Zones header is noArrow/non-collapsible — skip.
        if win._animalsSectionZones then
            for _, sz in ipairs(win._animalsSectionZones) do
                if sz.key ~= "zonesExpanded" then
                    elements[#elements + 1] = {
                        x = sz.x, y = sz.y, w = sz.w, h = sz.h,
                        id = "animals:disclosure:" .. tostring(sz.key),
                        isDisclosure = true,
                        sectionKey = sz.key,
                        onActivate = function(w, el)
                            local ov = w._animalsOverviewState
                            if ov then ov[el.sectionKey] = not ov[el.sectionKey] end
                        end,
                    }
                end
            end
        end
        -- Zone summary cards → navigate to zone view.
        if win._animalsZoneCardZones then
            for _, zc in ipairs(win._animalsZoneCardZones) do
                elements[#elements + 1] = {
                    x = zc.x, y = zc.y, w = zc.w, h = zc.h,
                    id = "animals:zonecard:" .. tostring(zc.zoneName),
                    isZoneCard = true,
                    zoneName = zc.zoneName,
                    onActivate = function(w, el)
                        if AT.navigate then
                            AT.navigate(w, "zone", el.zoneName, nil)
                        end
                        -- S109a: land on breadcrumb so back-nav is the
                        -- natural next action. Otherwise idx-clamp lands
                        -- the user mid-ring (on sort btn for idx-4 sources).
                        w._animalsNavFocusTarget = "breadcrumb"
                    end,
                }
            end
        end
        -- + CREATE ZONE footer button → enters drag-to-draw zone creation
        -- mode. Actual drawing step is mouse-only (ground drag), but the
        -- button itself is reachable via gamepad.
        if win._animalsAddZoneBtn then
            local z = win._animalsAddZoneBtn
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "animals:createzone",
                isCreateZone = true,
                onActivate = function(w)
                    if AT.startZoneCreate then AT.startZoneCreate(w) end
                end,
            }
        end
    elseif state.submode == "ranch" and state.view == "zone" then
        -- Sort cycle button.
        if win._animalsSortZone then
            local z = win._animalsSortZone
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "animals:sort",
                isSort = true,
                onActivate = function(w)
                    if AT.cycleSortMode then AT.cycleSortMode(w) end
                end,
            }
        end
        -- Animal roster rows → navigate to animal detail.
        if win._animalsRosterZones then
            for i, rz in ipairs(win._animalsRosterZones) do
                elements[#elements + 1] = {
                    x = rz.x, y = rz.y, w = rz.w, h = rz.h,
                    id = "animals:roster:" .. tostring(i),
                    isRoster = true,
                    animal = rz.animal,
                    rosterIdx = i,
                    onFocus = function(w, el)
                        w._gpFocusedAnimalRow = el.animal
                    end,
                    onActivate = function(w, el)
                        if AT.navigate then
                            AT.navigate(w, "animal", nil, el.animal)
                        end
                        w._animalsNavFocusTarget = "breadcrumb"
                    end,
                }
            end
        end
    elseif state.submode == "butcher" then
        -- Butcher submode renders butcher list in ALL views (AnimalsTab
        -- render dispatch has no animal-view branch for butcher — it falls
        -- through to renderButcherOverview regardless of state.view). So
        -- butcher rows stay focusable whenever they're drawn, matching the
        -- mouse interaction surface.
        if win._animalsButcherZones then
            for i, bz in ipairs(win._animalsButcherZones) do
                elements[#elements + 1] = {
                    x = bz.x, y = bz.y, w = bz.w, h = bz.h,
                    id = "animals:butcher:" .. tostring(i),
                    isButcher = true,
                    animal = bz.animal,
                    rosterIdx = i,
                    onFocus = function(w, el)
                        w._gpFocusedAnimalRow = el.animal
                    end,
                    onActivate = function(w, el)
                        if AT.navigate then
                            AT.navigate(w, "animal", nil, el.animal)
                        end
                        w._animalsNavFocusTarget = "breadcrumb"
                    end,
                }
            end
        end
    end
    -- ranch/animal: submode pills + breadcrumb only. Detail content is
    -- readout-only per design director.

    return elements
end

-- S107 — Crafting tab focusables (World window). Routes through the shared
-- CC.buildFocusables helper with prefix="craft" + ZeD_CraftPins for X-pin
-- + the HandcraftLogic-backed startCraft for the BUILD button. State table
-- (`win._craftState`) is created lazily by ZeD.CraftingTab.render on first
-- frame, so this wrapper returns {} until that state exists.
local function _buildWorldCraftFocusables(win)
    if not (ZeD and ZeD.CraftingCore and ZeD.CraftingTab) then return {} end
    return ZeD.CraftingCore.buildFocusables(win, win and win._craftState,
        "craft", "ZeD_CraftPins", ZeD.CraftingTab.startCraft)
end

-- S107 — Building tab focusables (World window). Same shape as Craft;
-- prefix="build", BuildLogic-backed startBuild (which spawns the placement
-- cursor on success — getCell():setDrag()).
local function _buildWorldBuildFocusables(win)
    if not (ZeD and ZeD.CraftingCore and ZeD.BuildingTab) then return {} end
    return ZeD.CraftingCore.buildFocusables(win, win and win._buildState,
        "build", "ZeD_BuildPins", ZeD.BuildingTab.startBuild)
end

-- Build panel-level focusables for a World tab.
-- S96: Loot auto-pushes invrows. Forage and Animals return flat lists.
-- S107: Craft + Build now wired to CraftingCore via shared focusables helper.
-- Maps still deferred (no zone-tracking renderer).
-- S98 ring model: For Loot tab, this returns INVENTORY ROW elements (the
-- containers live in their own zone — worldContainerStrip). The S91-S96 stack
-- model nested containers above invrows; ring model treats them as siblings.
-- Bumper cycle order on Loot: tabBar -> containerStrip -> tabContent (invrows)
-- -> wraps.
_buildWorldPanelFocusables = function(win, content, tabId)
    if not win then return {} end
    -- S99: Loot invrows now live in worldMainInv zone (always-visible).
    -- worldTabContent carries per-tab secondary content only.
    if tabId == "loot"    then return {}                               end
    if tabId == "forage"  then return _buildForageFocusables(win)      end
    if tabId == "animals" then return _buildAnimalsFocusables(win)     end
    if tabId == "craft"   then return _buildWorldCraftFocusables(win)  end
    if tabId == "build"   then return _buildWorldBuildFocusables(win)  end
    -- S112: Maps canvas annotation tools. MapsTab owns the builder —
    -- returns [disclosure, pinned tools, text tool, colors, grid tools,
    -- canvas cursor]. Mouse hit-zone tables are populated each frame by
    -- the Maps renderer; the builder reads them as the source of truth
    -- for bounds, so builder + render stay in lock-step.
    if tabId == "maps" then
        if ZeD and ZeD.MapsTab and ZeD.MapsTab.buildFocusables then
            return ZeD.MapsTab.buildFocusables(win)
        end
        return {}
    end
    -- S117: Radio drawer focusables. Mirrors the Char window dispatcher
    -- exactly — feedback_gamepad_pattern_parity.md mandates identical
    -- behavior across both windows.
    if tabId == "radio" then
        if ZeD and ZeD.RadioTab and ZeD.RadioTab.buildFocusables then
            return ZeD.RadioTab.buildFocusables(win)
        end
        return {}
    end
    if tabId == "vehicle" then
        if ZeD and ZeD.MechanicsTab and ZeD.MechanicsTab.buildFocusables then
            return ZeD.MechanicsTab.buildFocusables(win)
        end
        return {}
    end
    return {}
end

-- S108 v2 — Per-column MC builder. Each MC column is now its own ring zone
-- (`worldMC1`, `worldMC2`, ..., `worldMCN`) per design director's spec —
-- bumpers cycle ring zones one column at a time. This builder returns
-- elements for ONE column identified by `slot` (1..#_mcSelected).
--
-- colStates convention: [_mcSelected[1], _mcSelected[2], ..., _mcSelected[K],
-- _activeContainer (when _mainVisible)]. So colStates[slot] for slot=1..K maps
-- to the slot-th MC selection.
--
-- Element id pattern "mcrow:slot:i" lets the per-zone refresh dedup. Each
-- element shares the World invrow callback shape: A = ZeD context menu, hold
-- A = vanilla doContextualDblClick, X = take (floor pre-transfer per Q94).
_buildWorldMCColumnFocusables = function(win, slot)
    if not win or win._activeTab ~= "loot" then return {} end
    if not slot then return {} end
    local mcSel = win._mcSelected or {}
    if slot < 1 or slot > #mcSel then return {} end
    local content = win._mainContent
    if not content then return {} end
    local colStates = content._colStates
    if not colStates or slot > #colStates then return {} end

    local cs = colStates[slot]
    if not cs then return {} end

    local elements = {}
    local T = ZeD.T
    local rowH  = (T and T.rowH) or 26
    local items = cs.flatItems or {}
    local yMap  = cs.itemRenderYMap or {}
    local colX  = cs.renderX or 0
    local colW  = cs.renderW or T.px(200)

    for i = 1, #items do
        local item = items[i]
        local yCoord = yMap[item] or (i * rowH)
        elements[#elements + 1] = {
            x = colX, y = yCoord, w = colW, h = rowH,
            id = "mcrow:" .. slot .. ":" .. tostring(i),
            item = item,
            itemIndex = i,
            colIdx = slot,
            mcSlot = slot,
            containerIdx = cs.containerIdx,
            onFocus = function(w, el)
                local cnt = w._mainContent
                if cnt then cnt._gpFocusedRowItem = el.item end
                w._gpFocusedMCItem   = el.item
                w._gpFocusedMCColIdx = el.colIdx
                if w._drawerItem ~= nil and w._updateDrawer and el.item and cnt then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    sel[el.item] = true
                    cnt._selectedItems   = sel
                    cnt._lastClickedItem = el.item
                    w._updateDrawer(cnt)
                end
            end,
            -- S113: A = LMB. Stack rep → toggle expand/collapse; non-stack
            -- item → select (open card drawer). Hold A = double-LMB use.
            -- X = RMB = vanilla context menu (Take/Move-To via floor-routing
            -- inside ContextMenuRegistry).
            onActivate = function(w, el)
                if not el.item then return end
                local cnt = w._mainContent
                local cs2 = cnt and cnt._colStates and cnt._colStates[el.colIdx]
                local stk = cs2 and cs2.stacks and cs2.stacks[el.item]
                if stk and stk.count > 1 then
                    cs2.expandedStacks = cs2.expandedStacks or {}
                    cs2.expandedStacks[stk.key] = not cs2.expandedStacks[stk.key]
                    return
                end
                if cnt and w._updateDrawer then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    -- S117: A toggles the card drawer (mirror Char invrow).
                    if w._drawerItem ~= el.item then
                        sel[el.item] = true
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = el.item
                    else
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = nil
                    end
                    w._updateDrawer(cnt)
                end
            end,
            onHoldActivate = function(w, el)
                if not el.item then return end
                if ISInventoryPane and ISInventoryPane.doContextualDblClick then
                    pcall(ISInventoryPane.doContextualDblClick,
                          { player = 0 }, el.item)
                end
            end,
            onContextMenu = function(w, el)
                if not el.item then return end
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
                    local cnt = w._mainContent
                    local cs2 = cnt and cnt._colStates and cnt._colStates[el.colIdx]
                    local stk = cs2 and cs2.stacks and cs2.stacks[el.item]
                    local itemsArr = (stk and stk.count > 1) and stk.items or {el.item}
                    ISInventoryPaneContextMenu.createMenu(0, false, itemsArr, 0, 0)
                end
            end,
        }
    end
    -- S108 v2 QA: empty MC column needs a placeholder so the zone stays
    -- focusable. Otherwise bumpers skip empty containers, breaking the
    -- "each MC col is its own zone" model.
    if #elements == 0 then
        elements[1] = {
            x = colX, y = 0, w = colW, h = rowH,
            id = "mcempty:" .. slot,
            item = nil,
            colIdx = slot,
            mcSlot = slot,
            containerIdx = cs.containerIdx,
            isPlaceholder = true,
            onFocus = function(w, el)
                w._gpFocusedMCItem   = nil
                w._gpFocusedMCColIdx = el.colIdx
            end,
            onActivate    = function(w, el) end,
            onHoldActivate = function(w, el) end,
            onContextMenu = function(w, el) end,
        }
    end
    return elements
end

-- S98 — Clear all _gpFocused* chrome state fields on the World window +
-- content. Called from _syncWorldRingZones after a tab switch. Mirrors the
-- Character window helper.
_clearGpFocusState = function(w)
    if not w then return end
    w._gpFocusedRowItem        = nil
    w._gpFocusedForageStance   = nil
    w._gpFocusedAnimalSubmode  = nil  -- legacy (S96); no longer written
    w._gpFocusedAnimalRow      = nil  -- S109: roster/butcher row focus
    w._gpFocusedRadioCtl       = nil  -- S117: radio drawer chassis control id
    w._invRowsForContainer     = nil
    -- S107: CC scroll-follow delta-gate pins (one per CC-driven prefix).
    -- Fresh tab visit must re-pin on first focus, not inherit the previous
    -- element's position as "already correct".
    w._lastPinnedRecipeId_craft = nil
    w._lastPinnedRecipeId_build = nil
    -- S107 QA: clear pending card-jump flag on the per-state CC tabs so a
    -- mid-jump tab-switch doesn't force a stale jump on return. Last-row
    -- restore id is left intact — restoring it on re-entry is desirable.
    if w._craftState then w._craftState._gpPendingCardJump = false end
    if w._buildState then w._buildState._gpPendingCardJump = false end
    -- S108: clear MC zone focus + delta-gate pin on tab-switch / mode reset.
    -- Mirror of Char's behavior — re-entry to Loot+MC seeds focus to idx 1
    -- via the per-frame refresh's preserveIdx fallback.
    w._gpFocusedMCItem       = nil
    w._gpFocusedMCColIdx     = nil
    w._lastPinnedMCItem      = nil
    local c = w._mainContent
    if c then c._gpFocusedRowItem = nil end
end

-- S108 v2 — Dynamic per-column MC ring zone restructuring. Each MC selection
-- becomes its own ring zone (worldMC1..worldMCN); bumpers cycle them as
-- standard ring zones. Removes the old single `worldLootMCColumns` zone.
-- Insertion point: between worldContainerStrip and worldMainInv (matches the
-- visual layout where MC cols sit left of mainInv in the content panel).
local function _rebuildWorldMCRingZones(win)
    local ring = win and win._focusRing
    if not ring then return end

    -- Capture current focused zone NAME so we can restore _focusIdx after the
    -- ring's array indices shift.
    local focusedName = nil
    if win._focusIdx and ring[win._focusIdx] then
        focusedName = ring[win._focusIdx].zone
    end

    -- Remove any existing worldMC<n> zones (in reverse to preserve indices).
    for i = #ring, 1, -1 do
        local z = ring[i]
        if z and z.zone and z.zone:match("^worldMC%d+$") then
            table.remove(ring, i)
        end
    end

    -- Insertion point: just before worldMainInv.
    local insertAt = nil
    for i, z in ipairs(ring) do
        if z and z.zone == "worldMainInv" then insertAt = i; break end
    end

    local mcSel = win._mcSelected or {}
    if insertAt and win._activeTab == "loot" and #mcSel > 0 then
        for slot = 1, #mcSel do
            local zoneName = "worldMC" .. slot
            local mcEls = _buildWorldMCColumnFocusables(win, slot) or {}
            local capturedSlot = slot  -- per-iter closure capture
            local newZone = {
                zone = zoneName,
                focusable = #mcEls > 0,
                elements = mcEls,
                focusedElementIdx = 1,
                uiRange = function(w)
                    local T = ZeD.T
                    local content = w._mainContent
                    if content and content._colStates and content._colStates[capturedSlot] then
                        local cs = content._colStates[capturedSlot]
                        if cs.renderX and cs.renderW then
                            return T.px(CONTAINER_STRIP_W) + cs.renderX, cs.renderW
                        end
                    end
                    return T.px(CONTAINER_STRIP_W), T.px(w._baseInvW or 372)
                end,
            }
            table.insert(ring, insertAt, newZone)
            insertAt = insertAt + 1
        end
    end

    -- Restore _focusIdx by name. If the previously-focused zone was a removed
    -- worldMC<n>, fall back to worldContainerStrip (idx 1).
    if focusedName then
        local found = nil
        for i, z in ipairs(ring) do
            if z.zone == focusedName then found = i; break end
        end
        if found then
            win._focusIdx = found
        elseif focusedName:match("^worldMC%d+$") then
            -- Old MC zone gone — likely user just exited MC. Land on inv.
            for i, z in ipairs(ring) do
                if z.zone == "worldMainInv" and z.focusable then
                    win._focusIdx = i; break
                end
            end
        end
    end
end

-- S98 — Sync the ring zones to the new active tab + MC state. Called from
-- _switchWorldTabForNav and from mcToggleWorldContainer. Centralizes the
-- mutations so the various entry points don't drift.
_syncWorldRingZones = function(win, content)
    if not (ZeD and ZeD.Input and ZeD.Input.Focus and win and win._focusRing) then return end
    local Focus  = ZeD.Input.Focus
    local tabId  = win._activeTab

    -- S108 v2 QA: capture currently focused containerIdx BEFORE rebuild.
    -- Container onFocus is a no-op (Char S106 parity), so _activeContainer
    -- doesn't track D-pad navigation — using it as the seed target makes
    -- focus jump unexpectedly after mcToggle (containerStrip rebuilds and
    -- focuses on _activeContainer = floor instead of the user's actual
    -- focused container).
    local focusedCidx = nil
    do
        local zoneNow = Focus.getFocusedZone and Focus.getFocusedZone(win)
        if zoneNow and zoneNow.zone == "worldContainerStrip" then
            local elNow = Focus.getFocusedElement and Focus.getFocusedElement(win)
            if elNow then focusedCidx = elNow.containerIdx end
        end
    end

    local newContentEls   = _buildWorldPanelFocusables(win, content, tabId) or {}
    -- Containers reachable on ALL tabs per user spec (Apr 16). MC is Loot-only.
    local newContainerEls = _buildWorldLootFocusables(win) or {}

    Focus.setRingZoneElements(win, "worldTabContent",     newContentEls, 1)
    Focus.setZoneFocusable   (win, "worldTabContent",     #newContentEls > 0)
    -- S108: containerEls are now in [floor, non-floor display-order] layout
    -- (not container-index order), so seed idx by scanning for containerIdx
    -- match. Prefer focusedCidx (preserve current focus), fall back to
    -- _activeContainer for first-time/cold seeds.
    local seedTarget = focusedCidx or win._activeContainer
    local contIdx = 1
    if seedTarget and #newContainerEls > 0 then
        for i, el in ipairs(newContainerEls) do
            if el.containerIdx == seedTarget then contIdx = i; break end
        end
    end
    Focus.setRingZoneElements(win, "worldContainerStrip", newContainerEls, contIdx)
    Focus.setZoneFocusable   (win, "worldContainerStrip", #newContainerEls > 0)

    -- S108 v2: MC ring zones rebuilt based on _mcSelected count (one zone per
    -- MC selection). Old single worldLootMCColumns zone is gone.
    _rebuildWorldMCRingZones(win)

    -- S99: Tab change always leaves "item" mode (_switchWorldTabForNav flips
    -- _drawerMode). Explicitly disable the card zone so a bumper press in the
    -- same frame can't land on stale card elements before the per-frame
    -- refresh runs next frame.
    Focus.setRingZoneElements(win, "worldItemCard", {})
    Focus.setZoneFocusable   (win, "worldItemCard", false)

    if _clearGpFocusState then _clearGpFocusState(win) end
end

-- S96 — Build inventory-row focusables for the World Window's active container.
-- Mirrors _buildInvRowFocusables from ZeD_CharacterWindow but passes
-- isInPlayerInventory=false for the context menu (world items aren't in player inv).
_buildWorldInvRowFocusables = function(win)
    local c = win and win._mainContent
    local items = c and c._invRowItems
    if not items or #items == 0 then return {} end
    local elements = {}
    -- S98: bounds must be distinct per element so the cone-nav algorithm can
    -- pick neighbors. Prefer the renderer-stamped Y from _itemRenderYMap
    -- (Q91 pattern); fall back to index*rowH when the map hasn't been
    -- populated yet (first frame after tab switch).
    local T = ZeD.T
    local rowH = (T and T.rowH) or 26
    local yMap = c._itemRenderYMap or {}
    for i = 1, #items do
        local item = items[i]
        local yCoord = yMap[item] or (i * rowH)
        elements[#elements + 1] = {
            x = 0, y = yCoord, w = T.px(200), h = rowH,
            id = "invrow:" .. tostring(i),
            item = item,
            itemIndex = i,
            onFocus = function(w, el)
                w._gpFocusedRowItem = el.item
                local cnt = w._mainContent
                if cnt then cnt._gpFocusedRowItem = el.item end
                -- S99: Card follow-focus. When the card is visible (any tab —
                -- on non-Loot tabs the card overlays the tab drawer while
                -- `_drawerMode` stays "tab"), moving the gp cursor to a
                -- different invrow live-swaps the card to the newly-focused
                -- item. Gate on `_drawerItem ~= nil`, not `_drawerMode`.
                if w._drawerItem ~= nil and w._updateDrawer and el.item and cnt then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    sel[el.item] = true
                    cnt._selectedItems   = sel
                    cnt._lastClickedItem = el.item
                    w._updateDrawer()
                end
            end,
            -- S113: A tap = LMB = SELECT item (opens card drawer for it).
            -- On a stack rep (count > 1), A toggles stack expand/collapse
            -- (= LMB on chevron). A hold = double-LMB = use item (vanilla
            -- doContextualDblClick). X = RMB = open vanilla context menu —
            -- the menu's "Take" / "Move To" entries handle floor items via
            -- their own paths (Q44/Q94 floor-routing happens inside
            -- ContextMenuRegistry.makeActionDef.onFire pre-transfer).
            onActivate = function(w, el)
                if not el.item then return end
                local cnt = w._mainContent
                local stk = cnt and cnt._stacks and cnt._stacks[el.item]
                if stk and stk.count > 1 then
                    cnt._expandedStacks = cnt._expandedStacks or {}
                    cnt._expandedStacks[stk.key] = not cnt._expandedStacks[stk.key]
                    return
                end
                if cnt and w._updateDrawer then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    -- S117: A toggles the card drawer (mirror Char invrow).
                    -- World _updateDrawer is closure-scoped — no args.
                    if w._drawerItem ~= el.item then
                        sel[el.item] = true
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = el.item
                    else
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = nil
                    end
                    w._updateDrawer()
                end
            end,
            onHoldActivate = function(w, el)
                if not el.item then return end
                if ISInventoryPane and ISInventoryPane.doContextualDblClick then
                    pcall(ISInventoryPane.doContextualDblClick,
                          { player = 0 }, el.item)
                end
            end,
            onContextMenu = function(w, el)
                if not el.item then return end
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
                    local cnt = w._mainContent
                    local stk = cnt and cnt._stacks and cnt._stacks[el.item]
                    local itemsArr = (stk and stk.count > 1) and stk.items or {el.item}
                    ISInventoryPaneContextMenu.createMenu(0, false, itemsArr, 0, 0)
                end
            end,
        }
    end
    if elements[1] and elements[1].item then
        win._gpFocusedRowItem = elements[1].item
        local cnt = win._mainContent
        if cnt then cnt._gpFocusedRowItem = elements[1].item end
    end
    return elements
end

-- S99 — World Window item card action strip focusables. Same shape as the
-- Character window builder: delegates to the card organism, which stamps live
-- toggle + verb button rects each frame. Returns {} when the card isn't
-- visible. Note: on non-Loot tabs, the card OVERLAYS the tab drawer while
-- `_drawerMode` stays "tab" — gate on `_drawerItem` presence instead.
--
-- S113: Each card button gets:
--   * onDpadDir — D-pad U/D scrolls card content by disclosure (preserves
--     focus); L/R falls through to flat cone-nav between buttons.
--   * onCancel  — B closes the card drawer (mouse parity).
local function _wireWorldCardButtonNav(els, win)
    -- S113c: ItemCard returns ABSOLUTE screen coords. Convert to
    -- itemDrawerPanel-local so _collectFlat's panel-offset translation
    -- doesn't double-offset (mirror of Char window fix).
    local drawerPanel = win and win._itemDrawerPanel
    local panelAbsX = (drawerPanel and drawerPanel.getAbsoluteX
                       and drawerPanel:getAbsoluteX()) or 0
    local panelAbsY = (drawerPanel and drawerPanel.getAbsoluteY
                       and drawerPanel:getAbsoluteY()) or 0
    for i = 1, #els do
        local el = els[i]
        el.x = el.x - panelAbsX
        el.y = el.y - panelAbsY
        el.onDpadDir = function(w, e, dir)
            if dir == "up" and w._itemCard and w._itemCard.scrollToPrevDisclosure then
                w._itemCard:scrollToPrevDisclosure(); return
            elseif dir == "down" and w._itemCard and w._itemCard.scrollToNextDisclosure then
                w._itemCard:scrollToNextDisclosure(); return
            end
            return false
        end
        el.onCancel = function(w, e)
            local content = w._mainContent
            if content and w._updateDrawer then
                local sel = content._selectedItems or {}
                for k in pairs(sel) do sel[k] = nil end
                content._selectedItems   = sel
                content._lastClickedItem = nil
                w._updateDrawer()
            end
        end
    end
end
_buildWorldCardActionFocusables = function(win)
    if not (win and win._itemCard) then return {} end
    if win._drawerItem == nil then return {} end
    local els = win._itemCard:getActionStripElements() or {}
    -- S118: append clothing detail-zone structural docks AFTER the action strip.
    -- Mirrors Character window. Wire helper runs on combined list so dock
    -- elements get the same onDpadDir / onCancel + abs→panel-local conversion.
    local dockEls = win._itemCard:getZoneDockElements() or {}
    for i = 1, #dockEls do els[#els + 1] = dockEls[i] end
    _wireWorldCardButtonNav(els, win)
    return els
end

-- Attach ring-model callbacks to each tabBar element. Closures capture the
-- window ref; callbacks look up `win._mainContent` at fire time.
local function _attachWorldTabBarCallbacks(win, tabElements)
    for _, el in ipairs(tabElements) do
        -- S113c (design director): A press is required to switch tabs. D-pad
        -- focus on a tab no longer auto-switches — supersedes the S98 live-
        -- switch ruling. Mirror of Character window's _attachTabBarCallbacks.
        el.onFocus = function(w, e) end
        el.onActivate = function(w, e)
            local c = w._mainContent
            if c and _switchWorldTabForNav then
                _switchWorldTabForNav(w, c, e.tabId)
            end
        end
    end
end

-- Per-tab drawer width — tabs not listed use default DRAWER_W.
-- All current world tabs use TAB_DRAWER_W; table exists for future tabs.
local WORLD_TAB_DRAWER_WIDTHS = {
    craft = TAB_DRAWER_W,
    build = TAB_DRAWER_W,
    maps   = TAB_DRAWER_W,
    forage = TAB_DRAWER_W,
    animals = TAB_DRAWER_W,
    radio  = TAB_DRAWER_W,  -- S115 — radio chassis matches the wider tab drawer
    vehicle = TAB_DRAWER_W, -- S124 — Vehicle tab (item-card width)
}

local function getWorldTabDrawerW(tab)
    return WORLD_TAB_DRAWER_WIDTHS[tab] or DRAWER_W
end

-- Tab content renderers
local WORLD_TAB_RENDERERS = {}
ZeD.CraftingTab.register(WORLD_TAB_RENDERERS)
ZeD.BuildingTab.register(WORLD_TAB_RENDERERS)
ZeD.MapsTab.register(WORLD_TAB_RENDERERS)
ZeD.ForagingTab.register(WORLD_TAB_RENDERERS)
ZeD.AnimalsTab.register(WORLD_TAB_RENDERERS)
ZeD.RadioTab.register(WORLD_TAB_RENDERERS)
ZeD.MechanicsTab.register(WORLD_TAB_RENDERERS)

-- Fallback icon mapping for container types vanilla doesn't cover
local ICON_FALLBACKS = {
    -- Cabinets
    cupboard             = "wardrobe",
    overhead             = "wardrobe",
    locker               = "wardrobe",
    militarylocker       = "wardrobe",
    dishescabinet        = "wardrobe",
    -- Shelves / displays
    displaycase          = "shelves",
    displaycasebutcher   = "shelves",
    displaycasebakery    = "shelves",
    grocerstand          = "shelves",
    restaurantdisplay    = "shelves",
    shelvesmag           = "shelves",
    clothingrack         = "shelves",
    -- Drawers
    cashregister         = "desk",
    -- Crates / misc
    clothingdryerbasic   = "crate",
    doghouse             = "crate",
    SurvivorCrate        = "crate",
    trough               = "crate",
    plankstash           = "crate",
    -- Oven / heat
    stonefurnace         = "stove",
    -- Mail
    newspaper_dispatch   = "postbox",
    newspaper_herald     = "postbox",
    newspaper_knews      = "postbox",
    newspaper_times      = "postbox",
}

-- Resolve a container icon: try direct, then fallback alias, then nil
local function resolveContainerIcon(containerType)
    if not ContainerButtonIcons then return nil end
    local tex = ContainerButtonIcons[containerType]
    if tex then return tex end
    local alias = ICON_FALLBACKS[containerType]
    if alias then return ContainerButtonIcons[alias] end
    return nil
end

-- Module-level singleton ref
local _worldWin = nil

-- Floor container — created once per player, reused across toggle cycles
local _floorContainer = nil
-- Maps floor items → their real per-square containers (saved before AddItem reparents)
local _floorRealContainers = {}

-- Tab strip separator — TAB_SEP_H/TAB_SEP_MAR hoisted up to line ~52 in S94
-- so _buildWorldTabBarElements can see them as upvalues. TAB_ARROW_ROW_H
-- stays here because only drawWorldTabStrip (further down) uses it.
local TAB_ARROW_ROW_H  = 16

-- ============================================================================
-- ACTION TAB STRIP — mirrored from CharacterWindow, RIGHT edge
-- ============================================================================

local function measureWorldTabStripH(win)
    local T = ZeD.T
    local totalH = 0
    local lastGroup = 1
    for _, tab in ipairs(WORLD_TABS) do
        if isTabVisible(tab, win) then
            if tab.group ~= lastGroup then
                totalH = totalH + T.px(TAB_SEP_MAR) + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
                lastGroup = tab.group
            end
            totalH = totalH + T.px(ACTION_TAB_BTN_SZ)
        end
    end
    return totalH
end

local function drawWorldTabStrip(self, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms  -- S95: was missing; drawTriangleUp/Down calls below crashed
                          --      when World tab list overflowed and needed scroll arrows
                          --      (pre-existing latent bug, not an S95 regression).
    local w  = T.px(ACTION_TAB_STRIP_W)
    local h  = self:getHeight()

    self:clearHitZones()

    -- Strip background provided by ZeD_Window body — no redundant fill

    -- LEFT border (mirrored from char window's right border)
    local bd = T.border
    self:drawRect(0, 0, T.px(1), h, bd.a, bd.r, bd.g, bd.b)

    -- Glyph metrics
    local font  = T.fontF1
    local fontH = ZeD.TM:getFontHeight(font)
    local mx, my = self:getMouseX(), self:getMouseY()

    -- Check if tabs overflow
    local totalTabH = measureWorldTabStripH(win)
    local scrollOff = win._actionTabScrollOffset or 0
    local needsScroll = totalTabH > h
    local arrowRowH = 0

    if needsScroll then
        arrowRowH = T.px(TAB_ARROW_ROW_H)
        local maxScroll = totalTabH - (h - arrowRowH)
        if maxScroll < 0 then maxScroll = 0 end
        scrollOff = math.max(0, math.min(scrollOff, maxScroll))
        win._actionTabScrollOffset = scrollOff

        local canScrollUp   = scrollOff > 0
        local canScrollDown = scrollOff < maxScroll

        -- Bottom arrow row
        local rowY = h - arrowRowH
        local sep = T.borderS
        self:drawRect(0, rowY, w, T.px(1), sep.a, sep.r, sep.g, sep.b)

        local halfW = math.floor(w / 2)

        -- Up button (left half)
        local hoverUp = canScrollUp and (mx >= 0 and mx < halfW and my >= rowY and my < h)
        if hoverUp then
            local s2 = T.surf2
            self:drawRect(0, rowY + T.px(1), halfW, arrowRowH - T.px(1), s2.a, s2.r, s2.g, s2.b)
        end
        local upC = canScrollUp and (hoverUp and T.text or T.textDim) or T.border
        local arrowSz = T.px(5)
        A.drawTriangleUp(self, math.floor((halfW - arrowSz) / 2), rowY + math.floor((arrowRowH - arrowSz) / 2), arrowSz, upC)
        if canScrollUp then
            self:addHitZone("tab_scroll_up", 0, rowY, halfW, arrowRowH)
        end

        -- Down button (right half)
        local hoverDn = canScrollDown and (mx >= halfW and mx < w and my >= rowY and my < h)
        if hoverDn then
            local s2 = T.surf2
            self:drawRect(halfW, rowY + T.px(1), halfW, arrowRowH - T.px(1), s2.a, s2.r, s2.g, s2.b)
        end
        local dnC = canScrollDown and (hoverDn and T.text or T.textDim) or T.border
        A.drawTriangleDown(self, halfW + math.floor((halfW - arrowSz) / 2), rowY + math.floor((arrowRowH - arrowSz) / 2), arrowSz, dnC)
        if canScrollDown then
            self:addHitZone("tab_scroll_down", halfW, rowY, halfW, arrowRowH)
        end
    else
        win._actionTabScrollOffset = 0
    end

    -- Stencil for tab content area (above arrow row)
    local tabAreaH = h - arrowRowH
    self:setStencilRect(0, 0, w, tabAreaH)

    -- S113c: gamepad focus outline (mirror of Char). Resolve focused tabId
    -- once per draw so each tab can compare against it.
    local gpFocusedTabId = nil
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == win then
            local zone = Focus.getFocusedZone and Focus.getFocusedZone(win)
            if zone and zone.zone == "worldTabBar" then
                local el = Focus.getFocusedElement and Focus.getFocusedElement(win)
                if el then gpFocusedTabId = el.tabId end
            end
        end
    end

    local curY      = -scrollOff
    local lastGroup = 1

    -- Resolve active tab (show _tabUnder visually when card overlays)
    local visualActive = win._activeTab

    for _, tab in ipairs(WORLD_TABS) do
        if not isTabVisible(tab, win) then
            -- If the hidden tab was active, fall back to loot
            if tab.id == win._activeTab then win._activeTab = "loot" end
        else
            -- Group separator
            if tab.group ~= lastGroup then
                curY = curY + T.px(TAB_SEP_MAR)
                local sep = T.borderS
                self:drawRect(T.px(1), curY, w - T.px(5), T.px(TAB_SEP_H), sep.a, sep.r, sep.g, sep.b)
                curY = curY + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
                lastGroup = tab.group
            end

            local isActive = (tab.id == visualActive)
            local isHover  = (mx >= 0 and mx < w and my >= curY and my < curY + T.px(ACTION_TAB_BTN_SZ))
            local isGpFocused = (gpFocusedTabId == tab.id) and not isActive

            -- S113c (KBM-parity): mouse hover and gamepad focus paint
            -- identically. Active = 0.55α fill + 2px right-edge strip.
            -- Hover/focus = 0.55α fill only.
            local ac = T.accent
            if isActive then
                self:drawRect(T.px(1),     curY, w - T.px(1), T.px(ACTION_TAB_BTN_SZ), 0.55, ac.r, ac.g, ac.b)
                self:drawRect(w - T.px(2), curY, T.px(2),     T.px(ACTION_TAB_BTN_SZ), ac.a, ac.r, ac.g, ac.b)
            elseif isHover or isGpFocused then
                self:drawRect(T.px(1),     curY, w - T.px(1), T.px(ACTION_TAB_BTN_SZ), 0.55, ac.r, ac.g, ac.b)
            end

            -- Icon tint: active uses textOnAccent (contrasts with accent
            -- fill background); inactive keeps the accent-tinted ghost.
            local ic = isActive and T.textOnAccent or T.toneLo
            local iconAlpha = isActive and 1.0 or 0.7
            local iconSz = T.px(16)  -- icon size: 16 design units (16px source textures at 1080p)
            if tab.icon then
                local ix = math.floor((w - iconSz) / 2)
                local iy = curY + math.floor((T.px(ACTION_TAB_BTN_SZ) - iconSz) / 2)
                self:drawTextureScaledAspect(tab.icon, ix, iy, iconSz, iconSz, iconAlpha, ic.r, ic.g, ic.b)
            else
                local color
                if isActive then     color = T.textOnAccent
                elseif isHover then  color = T.text
                else                 color = T.textDim
                end
                local glyphW = ZeD.TM:MeasureStringX(font, tab.glyph)
                local gx = math.floor((w - glyphW) / 2)
                local gy = curY + math.floor((T.px(ACTION_TAB_BTN_SZ) - fontH) / 2)
                self:drawText(tab.glyph, gx, gy, color.r, color.g, color.b, color.a, font)
            end

            -- Bottom border between tabs
            local bd = T.border
            self:drawRect(0, curY + T.px(ACTION_TAB_BTN_SZ) - T.px(1), w, T.px(1), bd.a, bd.r, bd.g, bd.b)

            -- Hit zone
            if curY + T.px(ACTION_TAB_BTN_SZ) > 0 and curY < tabAreaH then
                self:addHitZone("tab:" .. tab.id, 0, curY, w, T.px(ACTION_TAB_BTN_SZ))
            end

            curY = curY + T.px(ACTION_TAB_BTN_SZ)
        end
    end

    self:clearStencilRect()
end

-- Drawer width dispatch — mode-driven. MC columns live in content, not drawer.
local function getWorldTargetDrawerW(win)
    local T = ZeD.T
    -- S124 scale: returns SCREEN px (compared against the animated _drawerEffW).
    if win._drawerOpen then
        if win._drawerMode == "item" then return T.px(ITEM_CARD_W) end
        if win._drawerMode == "tab"  then return T.px(getWorldTabDrawerW(win._activeTab)) end
        return 0
    end
    return 0
end

-- Scroll dispatch per tab — for future scrollable tab content
local function getWorldActiveScroll(win)
    -- New unified architecture: craft/build tabs manage scroll internally via state
    if win._activeTab == "craft" and win._craftState then return win._craftState.scroll end
    if win._activeTab == "build" and win._buildState then return win._buildState.scroll end
    if win._activeTab == "maps"   then return nil end  -- map handles zoom, not scroll
    if win._activeTab == "forage" then return win._forageScroll end
    if win._activeTab == "animals" then return win._animalsScroll end
    return nil
end

-- Placeholder card for tabs without a registered renderer
local function renderPlaceholder(panel, tabDef, x, y, w, h)
    local T   = ZeD.T
    local A   = ZeD.Atoms
    local pad = T.sp.sm

    -- Heading
    local font = T.fontF4
    local tc   = T.textHead
    panel:drawText(tabDef.label, x + pad, y + pad,
        tc.r, tc.g, tc.b, tc.a, font)

    local headH = ZeD.TM:getFontHeight(font)
    local grooveY = y + pad + headH + T.sp.headGap

    -- Groove divider
    local bd = T.border
    panel:drawRect(x + pad, grooveY, w - pad * 2, T.px(1), bd.a, bd.r, bd.g, bd.b)

    -- Description
    local descY = grooveY + T.px(1) + T.sp.afterGroove
    local secFont = T.fontF1
    local dim = T.textDim
    panel:drawText("Coming soon", x + pad, descY,
        dim.r, dim.g, dim.b, dim.a, secFont)
end

-- ============================================================================
-- MULTI-CONTAINER HELPERS
-- ============================================================================

-- Dynamic MC capacity: max extra columns that fit at MIN_COL_W.
-- Dynamic MC capacity. MC only allowed on Loot tab.
local function getMcCapacity(win)
    if win._activeTab ~= "loot" then return 0 end
    local R = getR()
    local T = ZeD.T
    -- S124 scale: InventoryRenderer exports MIN_COL_W / COMFORT_COL_W / getXferW as design units
    local minColW = T.px(R.MIN_COL_W or 140)
    local screenW = getCore():getScreenWidth()
    -- Loot tab has no drawer, full space available
    local availW = screenW - win:getX() - T.px(CONTAINER_STRIP_W) - T.px(ACTION_TAB_STRIP_W)
    local maxN = 1
    for n = 2, 20 do
        local xferW = T.px(R.getXferW and R.getXferW(n) or 32)
        local needed = n * minColW + (n - 1) * xferW
        if needed > availW then break end
        maxN = n
    end
    return math.max(1, maxN - 1)
end

-- Compute ideal window width for N total columns, clamped to screen.
local function mcComputeTargetWidthWorld(win, totalCols)
    local R = getR()
    local T = ZeD.T
    local comfortW = T.px(R.COMFORT_COL_W or 220)
    local xferW = T.px(R.getXferW and R.getXferW(totalCols) or 32)
    local xferTotal = (totalCols - 1) * xferW
    local effectiveDrawerW = math.floor(win._drawerEffW or 0)
    local idealInvW = totalCols * comfortW + xferTotal
    local idealWinW = T.px(CONTAINER_STRIP_W) + idealInvW + effectiveDrawerW + T.px(ACTION_TAB_STRIP_W)
    local screenW = getCore():getScreenWidth()
    local maxW = screenW - win:getX() - T.px(10)
    idealWinW = math.min(idealWinW, maxW)
    return idealWinW, idealInvW
end

-- Compute inventory drawer target width based on current state.
local function computeInvDrawerTargetWorld(win)
    local T = ZeD.T
    if not win._invDrawerOpen then return 0 end
    local mcSel = win._mcSelected or {}
    if #mcSel > 0 then
        local totalCols = #mcSel + (win._mainVisible and 1 or 0)
        if totalCols >= 2 then
            -- Multi-column: compute ideal width
            local _, invW = mcComputeTargetWidthWorld(win, totalCols)
            return invW
        end
        -- Single column (main hidden, 1 MC): keep base width, don't shrink
    end
    return T.px(win._baseInvW or 372)
end

local function getColumnAtX(content, x)
    local colStates = content._colStates
    if not colStates then return nil, nil end
    for i, cs in ipairs(colStates) do
        if x >= cs.renderX and x < cs.renderX + cs.renderW then
            return i, cs
        end
    end
    return nil, nil
end

local function enterWorldMC(win, content)
    if win._drawerMode == "item" then
        win._drawerItem = nil
        win._tabUnder = nil
    end
    -- Only clear drawer mode when not showing a tab
    if win._drawerMode ~= "tab" then
        win._drawerMode = nil
    end
    win._drawerOpen = true
    content._selectedItems = {}
    content._lastClickedItem = nil
    -- MC requires visible inventory drawer
    win._invDrawerOpen = true
end

exitWorldMC = function(win, content)
    local T = ZeD.T
    win._mcSelected = {}
    win._mainVisible = true
    content._colStates = nil
    content._selectedContainers = nil
    if win._drawerMode ~= "tab" and win._drawerMode ~= "item" then
        win._drawerOpen = false
    end
    -- Always snap window to base (prevents width corruption)
    local baseInv = T.px(win._baseInvW or 372)
    local drawerW = math.floor(win._drawerEffW or 0)
    local snapW = T.px(CONTAINER_STRIP_W) + baseInv + drawerW + T.px(ACTION_TAB_STRIP_W)
    win:setWidth(snapW)
end

-- S94 B-nav: fill the `_switchWorldTabForNav` slot forward-declared above.
-- Assigned here so it has exitWorldMC + getWorldActiveScroll in scope.
-- Mirrors the "different tab" branch of the mouse click handler below
-- (lines ~1900+), with the loot-tab special case folded in. Kept parallel to
-- _switchTabForNav in ZeD_CharacterWindow.
_switchWorldTabForNav = function(win, content, tabId)
    if not win or not content or not tabId then return false end
    if win._activeTab == tabId then return false end
    local T = ZeD.T

    if tabId == "loot" then
        win._activeTab  = "loot"
        win._drawerMode = nil
        win._drawerOpen = false
        win._drawerItem = nil
        win._tabUnder   = nil
        content._selectedItems = {}
        content._lastClickedItem = nil
        local baseInv = T.px(win._baseInvW or 372)
        win._drawerEffW    = 0
        win._prevEffW      = 0
        win._invDrawerOpen = true
        local snapW = T.px(CONTAINER_STRIP_W) + baseInv + T.px(ACTION_TAB_STRIP_W)
        win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
        win:setWidth(snapW)
        if _syncWorldRingZones then _syncWorldRingZones(win, content) end
        return true
    end

    -- Non-loot tab: MC exit FIRST then open drawer
    local mcSel = win._mcSelected or {}
    if #mcSel > 0 then
        exitWorldMC(win, content)
        local baseInv = T.px(win._baseInvW or 372)
        local snapW = T.px(CONTAINER_STRIP_W) + baseInv + T.px(ACTION_TAB_STRIP_W)
        win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
        win:setWidth(snapW)
    end
    win._activeTab  = tabId
    win._drawerMode = "tab"
    win._drawerOpen = true
    win._drawerItem = nil
    win._tabUnder   = nil
    content._selectedItems = {}
    content._lastClickedItem = nil
    local scroll = getWorldActiveScroll(win)
    if scroll then scroll:setScrollPos(0) end
    if _syncWorldRingZones then _syncWorldRingZones(win, content) end
    if _clearGpFocusState  then _clearGpFocusState(win)            end
    return true
end

-- Toggle inventory drawer. Enforces always-visible invariant.
-- MUST be defined after exitWorldMC (forward reference would crash Kahlua).
local function toggleInventoryDrawerWorld(win, content)
    local T = ZeD.T
    if win._invDrawerOpen then
        if win._drawerMode == "tab" and win._drawerOpen then
            win._invDrawerOpen = false
            if #(win._mcSelected or {}) > 0 then
                exitWorldMC(win, content)
            end
            -- Snap window to drawer-only width
            local drawerW = math.floor(win._drawerEffW or 0)
            local snapW = T.px(CONTAINER_STRIP_W) + drawerW + T.px(ACTION_TAB_STRIP_W)
            win:setWidth(snapW)
        end
    else
        win._invDrawerOpen = true
        -- Snap window to include inventory
        local drawerW = math.floor(win._drawerEffW or 0)
        local baseInv = T.px(win._baseInvW or 372)
        local snapW = T.px(CONTAINER_STRIP_W) + baseInv + drawerW + T.px(ACTION_TAB_STRIP_W)
        local maxW = win._maxWinW or math.floor(getCore():getScreenWidth() * 0.5)
        snapW = math.min(snapW, maxW)
        win:setWidth(snapW)
    end
end

mcToggleWorldContainer = function(win, content, cIdx)
    -- MC only allowed on Loot tab
    if win._activeTab ~= "loot" then return end

    local containers = win._containers
    if not containers[cIdx] then return end

    -- S108 QA: branch on isFloor rather than `cIdx == _activeContainer`. The
    -- floor (= the "main"/anchor column) has its own toggle semantics — hide
    -- it / auto-fill MC if empty. Pre-fix used _activeContainer as the proxy
    -- because _activeContainer was always floor at toggle time, but S107's
    -- tap-vs-hold split made _activeContainer track the user's most recent
    -- view-switch. With the focusable onFocus now NOT mutating _activeContainer
    -- (Char S106 parity), this proxy is even more wrong — every non-floor
    -- toggle landed here and silently picked containers[1] as the first MC
    -- entry, with no way to add more (subsequent toggles just flipped
    -- _mainVisible).
    if containers[cIdx].isFloor then
        if win._mainVisible then
            if #(win._mcSelected) > 0 then
                -- MC active: just hide floor
                win._mainVisible = false
            else
                -- No MC: auto-select first non-floor container, then hide floor.
                -- S108: use isFloor to identify the non-floor pick (was
                -- i ~= _activeContainer, which assumed _activeContainer = floor).
                local firstOther = nil
                for i, c in ipairs(containers) do
                    if not c.isFloor then firstOther = i; break end
                end
                if firstOther then
                    win._mcSelected[1] = firstOther
                    enterWorldMC(win, content)
                    win._mainVisible = false
                end
            end
        else
            win._mainVisible = true
        end
        local selected = win._mcSelected
        if #selected == 0 and win._mainVisible then
            -- S98: floor toggled back to single-only — refresh ring (MC zone empty).
            if _syncWorldRingZones then _syncWorldRingZones(win, content) end
            return
        end
    else
        -- Non-active container: toggle in/out of MC selection
        local selected = win._mcSelected
        local wasEmpty = #selected == 0

        local idx = nil
        for i, v in ipairs(selected) do
            if v == cIdx then idx = i; break end
        end

        local maxExtra = getMcCapacity(win)
        if idx then
            table.remove(selected, idx)
            if #selected == 0 then
                if not win._mainVisible then
                    win._mainVisible = true
                end
                exitWorldMC(win, content)  -- snaps window internally
                -- S98: MC fully exited — refresh ring (MC zone goes non-focusable).
                if _syncWorldRingZones then _syncWorldRingZones(win, content) end
                return
            end
        else
            while #selected >= maxExtra do
                table.remove(selected, 1)
            end
            selected[#selected + 1] = cIdx
            if wasEmpty then enterWorldMC(win, content) end
        end
    end

    -- Rebuild per-column states
    local selected = win._mcSelected
    local r = getR()
    if r.rebuildColStates then
        local colSel = {}
        for _, ci in ipairs(selected) do
            colSel[#colSel + 1] = ci
        end
        if win._mainVisible then
            -- S108 v2 QA: dedup _activeContainer if already in _mcSelected,
            -- otherwise the user gets a duplicate column when they tap an
            -- MC-toggled container (tap sets _activeContainer = ci which is
            -- also in selected → colSel = [..., ci, ..., ci]).
            local activeInMc = false
            for _, ci in ipairs(selected) do
                if ci == win._activeContainer then activeInMc = true; break end
            end
            if not activeInMc then
                colSel[#colSel + 1] = win._activeContainer
            end
        end
        content._selectedContainers = colSel
        content._containers = containers
        r.rebuildColStates(content)
        content._activeCol = #colSel
    end

    -- Snap window width for new column count
    local T = ZeD.T
    local colCount = #selected + (win._mainVisible and 1 or 0)
    local baseInv = T.px(win._baseInvW or 372)
    if colCount >= 2 then
        local _, idealInvW = mcComputeTargetWidthWorld(win, colCount)
        local snapW = T.px(CONTAINER_STRIP_W) + idealInvW + T.px(ACTION_TAB_STRIP_W)
        local maxW = getCore():getScreenWidth() - win:getX() - T.px(10)
        snapW = math.min(snapW, maxW)
        win:setWidth(snapW)
    else
        local snapW = T.px(CONTAINER_STRIP_W) + baseInv + T.px(ACTION_TAB_STRIP_W)
        win:setWidth(snapW)
    end

    -- S98: MC selection mutated — refresh ring (worldLootMCColumns focusability
    -- + element list reflect new _mcSelected). Stub returns {} until S99 wires
    -- real MC focusables, so this currently keeps the zone non-focusable.
    if _syncWorldRingZones then _syncWorldRingZones(win, content) end
end

-- ============================================================================
-- PERSISTENCE — save/restore window position + size via modData
-- ============================================================================

local function saveWorldState(win)
    local po = win._playerObj
    if not po then return end
    local T  = ZeD.T
    local sc = (T and T.scale) or 1
    local md = po:getModData()
    md.ZeD_WinState = md.ZeD_WinState or {}
    -- S124 scale: persisted geometry is stored in DESIGN UNITS (screen px / T.scale).
    -- _baseInvW already holds design units; x/y/h are screen px and are divided here.
    -- Pre-S124 saves were written at scale 1.0, so they read back as-is.
    local baseW = CONTAINER_STRIP_W + (win._baseInvW or 372) + ACTION_TAB_STRIP_W   -- design units
    md.ZeD_WinState.world = {
        x = win:getX() / sc,
        y = win:getY() / sc,
        w = baseW,
        h = win:getHeight() / sc,
        activeTab  = win._activeTab,
        drawerMode = win._drawerMode,
        drawerOpen = win._drawerOpen,
        accentKey  = win._accentKey,
    }
end

local function restoreWorldState(win, playerObj)
    local md = playerObj:getModData()
    local ws = md.ZeD_WinState and md.ZeD_WinState.world
    if not ws then return end
    local T = ZeD.T
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    -- S124 scale: stored values are design units (see saveWorldState). Scale to screen px,
    -- then clamp to the screen (a saved position can land off-screen after a root change).
    local xU = ws.x or 40
    local yU = math.max(0, ws.y or 60)
    local wU = math.max(CONTAINER_STRIP_W + 200 + ACTION_TAB_STRIP_W, ws.w or 464)   -- design units
    local x = T.px(xU)
    local y = T.px(yU)
    local w = T.px(wU)
    local h = math.max(win.minimumHeight or T.px(220), math.min(T.px(ws.h or 600), screenH - T.px(20)))
    if y + h > screenH then y = math.max(0, screenH - h) end
    x = math.max(0, math.min(x, screenW - w))
    win:setX(x)
    win:setY(y)
    win:setWidth(w)
    win:setHeight(h)

    -- Sync inventory drawer to restored width (no stale animation state)
    local restoredInvW = wU - CONTAINER_STRIP_W - ACTION_TAB_STRIP_W   -- design units
    restoredInvW = math.max(restoredInvW, 200)
    win._invDrawerEffW    = T.px(restoredInvW)
    win._invDrawerTargetW = T.px(restoredInvW)
    win._baseInvW         = restoredInvW                               -- design units
    win._prevDesiredW     = nil

    -- Restore active tab
    if ws.activeTab then
        win._activeTab = ws.activeTab
    end

    -- Restore drawer state (tab drawer reopens where it was)
    if ws.drawerMode == "tab" and ws.drawerOpen then
        win._drawerMode = "tab"
        win._drawerOpen = true
    end

    -- Restore per-window accent (modData > Settings pending > default)
    if ws.accentKey then
        win._accentKey = ws.accentKey
    elseif ZeD._pendingWorldAccent then
        win._accentKey = ZeD._pendingWorldAccent
    end
end

-- ============================================================================
-- UTILITY
-- ============================================================================

local function round(n, dp)
    local m = 10 ^ (dp or 0)
    return math.floor(n * m + 0.5) / m
end

-- ============================================================================
-- WORLD CONTAINER DISCOVERY
-- Replicates vanilla ISInventoryPage:refreshBackpacks() logic for loot side.
-- 3x3 grid around player, wall check, safehouse check, all container types.
-- ============================================================================

local function buildWorldContainers(playerObj)
    local containers = {}
    local playerNum = playerObj:getPlayerNum()

    -- Floor container: virtual aggregation of ground items
    if not _floorContainer then
        _floorContainer = ItemContainer.new("floor", nil, nil)
    end
    _floorContainer:removeItemsFromProcessItems()
    _floorContainer:clear()

    -- Track which items are still on the ground this cycle
    local currentFloorItems = {}

    local cx = math.floor(playerObj:getX())
    local cy = math.floor(playerObj:getY())
    local cz = math.floor(playerObj:getZ())
    local currentSq = playerObj:getCurrentSquare()

    local vehicleSeen = {}  -- dedup vehicles across tiles

    for dy = -1, 1 do
        for dx = -1, 1 do
            local gs = getCell():getGridSquare(cx + dx, cy + dy, cz)

            -- Wall penetration check
            if gs and gs ~= currentSq and currentSq then
                if not currentSq:canReachTo(gs) then
                    gs = nil
                end
            end

            -- Safehouse permission check (multiplayer)
            if gs and isClient() and not SafeHouse.isSafehouseAllowLoot(gs, playerObj) then
                gs = nil
            end

            if gs then
                -- A. Ground items (IsoWorldInventoryObject)
                local wobs = gs:getWorldObjects()
                if wobs then
                    for i = 0, wobs:size() - 1 do
                        local o = wobs:get(i)
                        if o and o:getItem() then
                            local item = o:getItem()
                            -- Save real container before AddItem reparents
                            local curCont = item:getContainer()
                            if curCont and curCont ~= _floorContainer then
                                _floorRealContainers[item] = curCont
                            end
                            _floorContainer:AddItem(item)
                            currentFloorItems[item] = true
                            -- Item-containers on the ground (dropped backpacks)
                            if item:getCategory() == "Container" then
                                containers[#containers + 1] = {
                                    inventory = item:getInventory(),
                                    name = item:getName(),
                                    texture = item:getTex(),
                                    isFloor = false,
                                    sourceType = "ground_container",
                                }
                            end
                        end
                    end
                end

                -- B. Static moving objects (corpses)
                local sobs = gs:getStaticMovingObjects()
                if sobs then
                    for i = 0, sobs:size() - 1 do
                        local so = sobs:get(i)
                        if so and so:getContainer() then
                            -- Skip animal bodies
                            local isAnimal = instanceof(so, "IsoDeadBody") and so:isAnimal()
                            if not isAnimal then
                                local title = getText("IGUI_Dead_Person")
                                if instanceof(so, "IsoDeadBody") then
                                    -- S123: the player's own corpse (and some B42 bodies) hand
                                    -- back a description without getForename/getSurname — this
                                    -- threw "Object tried to call nil" every frame after a death.
                                    pcall(function()
                                        local desc = so:getDescription()
                                        if desc and desc.getForename and desc.getSurname then
                                            title = desc:getForename() .. " " .. desc:getSurname()
                                        end
                                    end)
                                end
                                local corpseType = "inventorymale"
                                local desc = instanceof(so, "IsoDeadBody") and so:getDescription() or nil
                                if desc and desc.isFemale and pcall(function() if desc:isFemale() then corpseType = "inventoryfemale" end end) then end
                                containers[#containers + 1] = {
                                    inventory = so:getContainer(),
                                    name = title,
                                    texture = resolveContainerIcon(corpseType),
                                    isFloor = false,
                                    sourceType = "corpse",
                                }
                            end
                        end
                    end
                end

                -- C. IsoObjects with containers (furniture, appliances)
                local obs = gs:getObjects()
                if obs then
                    for i = 0, obs:size() - 1 do
                        local o = obs:get(i)
                        if o then
                            local count = 0
                            if o.getContainerCount then
                                count = o:getContainerCount()
                            end
                            for ci = 0, count - 1 do
                                local container = o:getContainerByIndex(ci)
                                if container then
                                    local title = container:getType()
                                    if o:getName() and o:getName() ~= "" then
                                        title = o:getName()
                                    end
                                    -- Translate container type
                                    local transKey = "IGUI_ContainerTitle_" .. container:getType()
                                    local translated = getText(transKey)
                                    if translated ~= transKey then
                                        title = translated
                                    end

                                    local locked = false
                                    if instanceof(o, "IsoThumpable") then
                                        locked = o:isLockedToCharacter(playerObj)
                                        if o:isLockedByPadlock() then
                                            if playerObj:getInventory():haveThisKeyId(o:getKeyId()) then
                                                locked = false
                                            end
                                        end
                                    end

                                    containers[#containers + 1] = {
                                        inventory = container,
                                        name = title,
                                        texture = resolveContainerIcon(container:getType()),
                                        isFloor = false,
                                        sourceType = "object",
                                        locked = locked,
                                        isoObject = o,
                                    }

                                    -- Request server items for unexplored containers
                                    if not container:isExplored() then
                                        if isClient() then
                                            container:requestServerItemsForContainer()
                                        else
                                            ItemPicker.fillContainer(container, playerObj)
                                        end
                                        container:setExplored(true)
                                    end
                                end
                            end
                        end
                    end
                end

                -- D. Vehicles
                local vehicle = gs:getVehicleContainer()
                if vehicle and not vehicleSeen[vehicle] then
                    vehicleSeen[vehicle] = true
                    local partCount = vehicle:getPartCount()
                    for pi = 0, partCount - 1 do
                        local part = vehicle:getPartByIndex(pi)
                        if part and part:getItemContainer()
                           and vehicle:canAccessContainer(pi, playerObj) then
                            local partName = part:getCategory() or "Vehicle"
                            local vehType = part:getCategory() or ""
                            containers[#containers + 1] = {
                                inventory = part:getItemContainer(),
                                name = partName,
                                texture = resolveContainerIcon(vehType),
                                isFloor = false,
                                sourceType = "vehicle",
                            }
                        end
                    end
                end
            end
        end
    end

    -- Purge stale entries from real-container lookup
    for item in pairs(_floorRealContainers) do
        if not currentFloorItems[item] then
            _floorRealContainers[item] = nil
        end
    end

    -- Floor container always last (pinned at bottom of strip)
    containers[#containers + 1] = {
        inventory = _floorContainer,
        name = getTextOrNull("IGUI_ContainerTitle_floor") or "Floor",
        texture = resolveContainerIcon("floor"),
        isFloor = true,
        sourceType = "floor",
    }

    return containers
end


-- ============================================================================
-- CONTAINER STRIP — LEFT EDGE (mirrored from character window's right edge)
-- Active container pinned top, scrollable list below.
-- ============================================================================

local function drawWorldContainerStrip(self, win, content)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local w  = T.px(CONTAINER_STRIP_W)
    local h  = self:getHeight()

    self:clearHitZones()

    -- S108 QA: Resolve gamepad focus for per-button cue paint. Mirrors Char's
    -- S106 pattern at drawContainerStrip top. Without this, the user has no
    -- visual signal that D-pad is moving focus on the strip — the active /
    -- viewed / MC paints don't shift unless the user explicitly tap-A's or
    -- hold-A's. Gated on focused window + zone == "worldContainerStrip" so
    -- the cue clears when LB/RB bumpers to a different ring zone.
    local gpFocusedCI = nil
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
        if focWin == win and Focus.getFocusedZone and Focus.getFocusedElement then
            local zone = Focus.getFocusedZone(focWin)
            if zone and zone.zone == "worldContainerStrip" then
                local el = Focus.getFocusedElement(focWin)
                if el then gpFocusedCI = el.containerIdx end
            end
        end
    end

    -- Periodic container refresh (~every 30 frames)
    win._containerTimer = (win._containerTimer or 0) + 1
    if win._containerTimer >= 30 then
        win._containerTimer = 0
        local oldContainers = win._containers
        win._containers = buildWorldContainers(win._playerObj)

        -- Remap _activeContainer by inventory identity (not raw index)
        local oldActive = oldContainers and oldContainers[win._activeContainer]
        local newActiveIdx = #win._containers  -- default to floor
        if oldActive then
            for i, c in ipairs(win._containers) do
                if c.inventory == oldActive.inventory then
                    newActiveIdx = i
                    break
                end
            end
        end
        win._activeContainer = newActiveIdx

        -- Remap _mcSelected indices by inventory identity
        local newSelected = {}
        for _, oldIdx in ipairs(win._mcSelected or {}) do
            local oldCnt = oldContainers and oldContainers[oldIdx]
            if oldCnt then
                for i, c in ipairs(win._containers) do
                    if c.inventory == oldCnt.inventory then
                        newSelected[#newSelected + 1] = i
                        break
                    end
                end
            end
        end
        win._mcSelected = newSelected

        -- Re-sync active inventory
        local activeCnt = win._containers[win._activeContainer]
        if activeCnt then
            content._inventory = activeCnt.inventory
        end

        -- S115: refresh world radios in player range + clamp browse index.
        -- Wave cache prunes against the new key set (entry.cacheKey is built
        -- from world coords by RadioTab.buildWorldRadios — stable identity).
        win._radios = ZeD.RadioTab.buildWorldRadios(win._playerObj)
        -- S124: vehicles in reach for the Vehicle tab (same 30-frame timer)
        if ZeD.MechanicsTab and ZeD.MechanicsTab.refresh then pcall(ZeD.MechanicsTab.refresh, win) end
        if #win._radios == 0 then
            win._radioIdx = 1
        elseif win._radioIdx > #win._radios then
            win._radioIdx = #win._radios
        end
        if win._radioWaveCache then
            local stillPresent = {}
            for _, entry in ipairs(win._radios) do
                if entry.cacheKey then stillPresent[entry.cacheKey] = true end
            end
            for k in pairs(win._radioWaveCache) do
                if not stillPresent[k] then win._radioWaveCache[k] = nil end
            end
        end
    end

    local containers = win._containers
    local mx, my = self:getMouseX(), self:getMouseY()
    local font   = T.fontF1
    local fontH  = ZeD.TM:getFontHeight(font)
    local iconSz = T.px(CONTAINER_BTN_SZ - 14)  -- 22px icon in 36px cell (design units)

    -- Strip background provided by ZeD_Window body — no redundant fill
    -- Right border (mirrored from char window's left border)
    local bd = T.border
    self:drawRect(w - T.px(1), 0, T.px(1), h, bd.a, bd.r, bd.g, bd.b)

    -- --------------------------------------------------------
    -- ZONE 1: Floor container pinned at top (always last in containers[])
    -- --------------------------------------------------------
    local floorIdx = #containers
    local floorCnt = containers[floorIdx]
    local curY = 0
    if floorCnt and floorCnt.isFloor then
        local isActive = (win._activeContainer == floorIdx)
        local isMC = false
        for _, ci in ipairs(win._mcSelected or {}) do
            if ci == floorIdx then isMC = true; break end
        end

        local isHover = (mx >= 0 and mx < w and my >= curY and my < curY + T.px(CONTAINER_BTN_SZ))
        -- Zone 1 is "on" when: main visible (loot MC), or inventory open showing floor (non-loot)
        local mainVis
        if win._activeTab == "loot" then
            mainVis = win._mainVisible
        else
            mainVis = win._invDrawerOpen and (win._viewedContainer == nil)
        end
        if mainVis and (isActive or isMC) then
            -- S95 v3: active container filled with accent at readable alpha.
            local ac = T.accent
            self:drawRect(0, curY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.55, ac.r, ac.g, ac.b)
            self:drawRect(0, curY, T.px(2), T.px(CONTAINER_BTN_SZ), ac.a, ac.r, ac.g, ac.b)
        elseif isHover then
            self:drawRect(0, curY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.04, T.text.r, T.text.g, T.text.b)
        end
        -- S108 QA: gamepad focus cue on floor (mirrors Char S106). Stacks
        -- on top of mainVis paint — visually identical when both apply, but
        -- guarantees the cue shows when mainVis is false (user navigated to
        -- floor via D-pad without tap-A) so they can see where focus is.
        if gpFocusedCI == floorIdx then
            local ac = T.accent
            self:drawRect(0, curY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.55, ac.r, ac.g, ac.b)
        end

        local iconAlpha = mainVis and 1 or 0.5
        local tex = floorCnt.texture
        if tex then
            local ix = math.floor((w - iconSz) / 2)
            local iy = curY + math.floor((T.px(CONTAINER_BTN_SZ) - iconSz) / 2)
            self:drawTextureScaledAspect(tex, ix, iy, iconSz, iconSz, iconAlpha, 1, 1, 1)
        else
            local glyph = "F"
            local gw = ZeD.TM:MeasureStringX(font, glyph)
            local gx = math.floor((w - gw) / 2)
            local gy = curY + math.floor((T.px(CONTAINER_BTN_SZ) - fontH) / 2)
            local color = mainVis and ((isActive or isMC) and T.accent or T.textSec) or T.textDim
            self:drawText(glyph, gx, gy, color.r, color.g, color.b, color.a, font)
        end

        -- S108 v2 QA: MC badge for floor when shown as a column in MC mode.
        -- Floor is at the LAST colSel position when mainVisible=true, so its
        -- badge = #_mcSelected + 1. Doesn't appear in _mcSelected itself
        -- (floor toggle = visibility, not membership), so position derived
        -- from mcCount instead of lookup.
        local mcCountF = #(win._mcSelected or {})
        if mainVis and mcCountF > 0 then
            local badge = tostring(mcCountF + 1)
            local bw = ZeD.TM:MeasureStringX(font, badge)
            local bx = T.px(4)
            local by = curY + T.px(CONTAINER_BTN_SZ) - fontH - T.px(1)
            local ac = T.accent
            self:drawText(badge, bx, by, ac.r, ac.g, ac.b, ac.a, font)
        end

        self:addHitZone(floorIdx, 0, curY, w, T.px(CONTAINER_BTN_SZ))
        curY = curY + T.px(CONTAINER_BTN_SZ)
    end

    -- Divider below floor
    A.drawDividerH(self, 0, curY, w, true)
    curY = curY + T.px(1)

    local sortMode = win._containerSortMode or "dist"

    -- --------------------------------------------------------
    -- ZONE 2: Sort mode label — aligned with column header bar
    -- Cycles: dist → wt → type → dist
    -- --------------------------------------------------------
    local colHdrH     = T.px(20)
    local sortRowY    = curY
    local sortRowH    = colHdrH
    local f5Font      = T.fontF5
    local f5H         = ZeD.TM:getFontHeight(f5Font)
    local isActive    = sortMode ~= "dist"
    local sortLabel   = string.upper(sortMode)
    local labelW      = ZeD.TM:MeasureStringX(f5Font, sortLabel)
    local isSortHover = (mx >= 0 and mx < w and my >= sortRowY and my < sortRowY + sortRowH)

    local surf2 = T.surf2
    self:drawRect(0, sortRowY, w, sortRowH, surf2.a, surf2.r, surf2.g, surf2.b)
    if isActive then
        local ac = T.accent
        self:drawRect(0, sortRowY, w, sortRowH, 0.15, ac.r, ac.g, ac.b)
    elseif isSortHover then
        self:drawRect(0, sortRowY, w, sortRowH, 0.04, T.text.r, T.text.g, T.text.b)
    end
    local sortColor = isActive and T.toneNorm or T.toneLo
    local labelX = math.floor((w - labelW) / 2)
    local labelY = sortRowY + math.floor((sortRowH - f5H) / 2)
    self:drawText(sortLabel, labelX, labelY, sortColor.r, sortColor.g, sortColor.b, sortColor.a, f5Font)
    if isActive then
        self:drawRect(labelX, labelY + f5H, labelW, T.px(1), sortColor.a, sortColor.r, sortColor.g, sortColor.b)
    end
    self:addHitZone("wt_sort", 0, sortRowY, w, sortRowH)
    A.drawDividerH(self, 0, sortRowY + sortRowH - T.px(1), w, true)
    curY = sortRowY + sortRowH

    -- --------------------------------------------------------
    -- ZONE 3: Non-floor container buttons (scrollable)
    -- --------------------------------------------------------
    local listStartY = curY
    local listEntries = {}
    for i, c in ipairs(containers) do
        if not c.isFloor then
            listEntries[#listEntries + 1] = i
        end
    end

    if sortMode == "wt" then
        table.sort(listEntries, function(a, b)
            local wa = containers[a].inventory and containers[a].inventory:getCapacityWeight() or 0
            local wb = containers[b].inventory and containers[b].inventory:getCapacityWeight() or 0
            return wa > wb
        end)
    elseif sortMode == "type" then
        table.sort(listEntries, function(a, b)
            return (containers[a].name or "") < (containers[b].name or "")
        end)
    end
    -- "dist" = natural order

    -- Scroll geometry
    local totalListH = #listEntries * T.px(CONTAINER_BTN_SZ)
    local scrollArrowH = 0
    local scrollOff = win._stripScrollOffset or 0
    local listAreaH = h - listStartY
    local needsScroll = totalListH > listAreaH
    if needsScroll then
        scrollArrowH = T.px(STRIP_SCROLL_ROW_H)
        listAreaH = h - listStartY - scrollArrowH
        local maxScroll = totalListH - listAreaH
        if maxScroll < 0 then maxScroll = 0 end
        scrollOff = math.max(0, math.min(scrollOff, maxScroll))
        win._stripScrollOffset = scrollOff
    else
        scrollOff = 0
        win._stripScrollOffset = 0
    end

    -- Stencil clip the list area
    if needsScroll then
        self:setStencilRect(0, listStartY, w, listAreaH)
    end

    -- Build MC lookup for visual indicators
    local mcSet = {}
    for _, ci in ipairs(win._mcSelected or {}) do
        mcSet[ci] = true
    end

    local drawY = listStartY - scrollOff
    for _, ci in ipairs(listEntries) do
        local cnt = containers[ci]
        local isMC = mcSet[ci]
        local isActive = (ci == win._activeContainer)
        local isViewed = (ci == win._viewedContainer)
        local isOn = isMC or isActive or isViewed
        if cnt and drawY + T.px(CONTAINER_BTN_SZ) > listStartY and drawY < listStartY + listAreaH then
            local isHover = (mx >= 0 and mx < w and my >= drawY and my < drawY + T.px(CONTAINER_BTN_SZ))

            -- S95 v3: active / sole-MC / viewed containers filled with accent
            -- at readable alpha. Matches tab-strip active highlight.
            local isSoleActive = isMC and not win._mainVisible and #(win._mcSelected or {}) == 1
            if isSoleActive or isViewed then
                local ac = T.accent
                self:drawRect(0, drawY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.55, ac.r, ac.g, ac.b)
                self:drawRect(0, drawY, T.px(2), T.px(CONTAINER_BTN_SZ), ac.a, ac.r, ac.g, ac.b)
            elseif isOn then
                local ac = T.accent
                self:drawRect(0, drawY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.55, ac.r, ac.g, ac.b)
                self:drawRect(0, drawY, T.px(2), T.px(CONTAINER_BTN_SZ), ac.a, ac.r, ac.g, ac.b)
            end

            -- Hover highlight
            if isHover then
                self:drawRect(0, drawY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.04, T.text.r, T.text.g, T.text.b)
            end
            -- S108 QA: gamepad focus cue on non-floor button. Stacks on top
            -- of selection/hover paint to guarantee visibility regardless of
            -- the button's base state. Mirrors Char S106.
            if gpFocusedCI == ci then
                local ac = T.accent
                self:drawRect(0, drawY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.55, ac.r, ac.g, ac.b)
            end

            -- Locked overlay
            if cnt.locked then
                self:drawRect(0, drawY, w - T.px(1), T.px(CONTAINER_BTN_SZ), 0.15, T.danger.r, T.danger.g, T.danger.b)
            end

            -- Icon or glyph
            local tex = cnt.texture
            if tex then
                local ix = math.floor((w - iconSz) / 2)
                local iy = drawY + math.floor((T.px(CONTAINER_BTN_SZ) - iconSz) / 2)
                local alpha = cnt.locked and 0.4 or 1
                self:drawTextureScaledAspect(tex, ix, iy, iconSz, iconSz, alpha, 1, 1, 1)
            else
                local glyph = string.sub(cnt.name or "?", 1, 1)
                local gw = ZeD.TM:MeasureStringX(font, glyph)
                local gx = math.floor((w - gw) / 2)
                local gy = drawY + math.floor((T.px(CONTAINER_BTN_SZ) - fontH) / 2)
                local color = isOn and T.accent or (cnt.locked and T.textDim or T.textSec)
                self:drawText(glyph, gx, gy, color.r, color.g, color.b, color.a, font)
            end

            -- MC column badge number (bottom-left corner, mirrored from char window)
            if isMC then
                local mcIdx = nil
                for mi, mci in ipairs(win._mcSelected or {}) do
                    if mci == ci then mcIdx = mi; break end
                end
                if mcIdx then
                    local badge = tostring(mcIdx)
                    local bw = ZeD.TM:MeasureStringX(font, badge)
                    local bx = T.px(4)
                    local by = drawY + T.px(CONTAINER_BTN_SZ) - fontH - T.px(1)
                    local ac = T.accent
                    self:drawText(badge, bx, by, ac.r, ac.g, ac.b, ac.a, font)
                end
            end

            -- Bottom divider
            self:drawRect(0, drawY + T.px(CONTAINER_BTN_SZ) - T.px(1), w, T.px(1), bd.a, bd.r, bd.g, bd.b)
        end
        -- Hit zone (always register even if off-screen, for scroll calculation)
        self:addHitZone(ci, 0, drawY, w, T.px(CONTAINER_BTN_SZ))
        drawY = drawY + T.px(CONTAINER_BTN_SZ)
    end

    if needsScroll then
        self:clearStencilRect()

        -- Scroll arrows at bottom
        local arrowY = h - scrollArrowH
        local arrBg = T.surf2
        self:drawRect(0, arrowY, w, scrollArrowH, arrBg.a, arrBg.r, arrBg.g, arrBg.b)
        A.drawDividerH(self, 0, arrowY, w, true)

        -- Up arrow (left half)
        local arrowColor = scrollOff > 0 and T.text or T.textDim
        local upX = math.floor(w / 4)
        local upY = arrowY + math.floor(scrollArrowH / 2) - T.px(1)
        A.drawTriangleUp(self, upX, upY, T.px(5), arrowColor)
        self:addHitZone("scroll_up", 0, arrowY, math.floor(w / 2), scrollArrowH)

        -- Down arrow (right half)
        local maxScroll = totalListH - listAreaH
        local downColor = scrollOff < maxScroll and T.text or T.textDim
        local dnX = math.floor(w * 3 / 4)
        local dnY = arrowY + math.floor(scrollArrowH / 2) - T.px(1)
        A.drawTriangleDown(self, dnX, dnY, T.px(5), downColor)
        self:addHitZone("scroll_down", math.floor(w / 2), arrowY, math.floor(w / 2), scrollArrowH)
    end
end


-- ============================================================================
-- TOGGLE
-- ============================================================================

function ZeD_WorldWindow.isOpen()
    return _worldWin ~= nil
end

function ZeD_WorldWindow.getWindow()
    return _worldWin
end

--- Returns the virtual floor container (for identity checks from other modules).
function ZeD_WorldWindow.getFloorContainer()
    return _floorContainer
end

--- Transfer a single InventoryItem off the virtual floor into destInv.
--- Mirrors vanilla ISGrabItemAction:transferItem (removes the IsoWorldInventoryObject).
--- Returns true on success.
function ZeD_WorldWindow.transferFromFloor(playerObj, item, destInv)
    if not _floorContainer then return false end
    if item:getContainer() ~= _floorContainer then return false end
    local worldItem = item:getWorldItem()
    if not worldItem then return false end
    if not destInv:isItemAllowed(item) then return false end
    if not destInv:hasRoomFor(playerObj, item) then return false end

    local sq = worldItem:getSquare()
    if sq then
        sq:transmitRemoveItemFromSquare(worldItem)
        worldItem:removeFromWorld()
        worldItem:removeFromSquare()
        worldItem:setSquare(nil)
    end
    item:setWorldItem(nil)
    item:setJobDelta(0.0)
    destInv:AddItem(item)
    destInv:setDrawDirty(true)
    _floorRealContainers[item] = nil
    return true
end

function ZeD_WorldWindow.toggle(playerNum)
    playerNum = playerNum or 0

    if _worldWin then
        saveWorldState(_worldWin)
        -- S93 Layer 3: tear down joypad focus registration before dropping ref.
        -- unregisterWindow internally releases focus if this window holds it.
        if ZeD and ZeD.Input and ZeD.Input.Focus then
            if ZeD.MapsTab and ZeD.MapsTab.closePopout then ZeD.MapsTab.closePopout(_worldWin) end  -- S123: fold the map pop-out with the window
            ZeD.Input.Focus.unregisterWindow(_worldWin)
        end
        _worldWin:removeFromUIManager()
        _worldWin = nil
        _floorContainer = nil
        return
    end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local r = getR()
    local T = ZeD.T
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local maxWinW = math.floor(screenW * 0.5)
    local invW = 372                                     -- design units (default inventory width)
    local winW = T.px(CONTAINER_STRIP_W) + T.px(invW) + T.px(ACTION_TAB_STRIP_W)  -- 36 + 372 + 36 = 444 design units
    winW = math.min(winW, maxWinW)
    local winH = math.min(T.px(420), screenH - T.px(80))

    -- Position: right page of two-page spread, left edge 5px right of center
    local win = ZeD_Window:new(math.floor(screenW / 2) + T.px(5), 0, winW, winH, "World")
    win:initialise()
    win:addToUIManager()
    win.minimumHeight = T.px(220)
    win._maxWinW = maxWinW

    -- No theme controls on world window — grow box only, no footer toggles
    win.footerToggles = false

    _worldWin = win

    -- Stable label for FocusManager diagnostic logs. win.title gets replaced
    -- with the active container's name mid-session ("Ground  0", "Fridge",
    -- etc.), so _label() in FocusManager prefers _zedLabel when set. Keeps
    -- console.txt grep-able as "World" no matter what the title reads.
    win._zedLabel = "World"

    -- Restore saved position/size (must come after _maxWinW is set)
    restoreWorldState(win, playerObj)

    -- S98: registerWindow fires early; ring construction + claimFocus deferred
    -- to after win._containers / win._activeContainer / win._mcSelected are
    -- populated so containerStrip elements seed correctly.
    if ZeD and ZeD.Input and ZeD.Input.Focus then
        ZeD.Input.Focus.registerWindow(win)
    end

    -- Override close
    win.close = function(self)
        saveWorldState(self)
        -- S93 Layer 3: drop joypad focus before teardown. unregisterWindow
        -- internally calls releaseFocus if this window currently holds it,
        -- so one call handles both concerns.
        if ZeD and ZeD.Input and ZeD.Input.Focus then
            ZeD.Input.Focus.unregisterWindow(self)
        end
        self:removeFromUIManager()
        _worldWin = nil
        _floorContainer = nil
    end

    -- Player ref
    win._playerObj = playerObj

    -- Container state (floor is always last — default active)
    win._containers = buildWorldContainers(playerObj)
    win._activeContainer = #win._containers
    win._containerTimer = 0
    win._stripScrollOffset = 0
    win._containerSortMode = "dist"  -- "dist" | "wt" | "type"
    win._baseInvW = invW             -- S124 scale: DESIGN UNITS (T.px() at every use; saved as-is)

    -- S115: radio contextual tab state. _kind tells RadioTab.render which
    -- discovery source to use ("world" -> 3x3 grid scan for IsoWaveSignal).
    -- Refreshed on the same 30-frame timer as containers.
    win._kind             = "world"
    win._radios           = ZeD.RadioTab.buildWorldRadios(playerObj)
    win._radioIdx         = 1
    win._radioWaveCache   = {}
    if ZeD.MechanicsTab and ZeD.MechanicsTab.refresh then pcall(ZeD.MechanicsTab.refresh, win) end

    -- Drawer state
    win._drawerOpen  = false
    win._drawerEffW  = 0
    win._drawerItem  = nil
    win._drawerMode  = nil          -- nil | "item" | "tab"

    -- Action tab state
    win._activeTab   = "loot"
    win._tabUnder    = nil          -- saved tab id while card overlays a tab
    win._actionTabScrollOffset = 0
    -- Crafting/Building tab state — new unified architecture.
    -- Tab state is lazily created by CraftingCore.createState() on first render.
    -- Only data-gathering caches and container refs live on win directly.
    win._craftTimer          = 0
    win._craftCache          = nil
    win._craftContainers     = nil
    win._craftContainerTimer = 0
    win._craftState          = nil   -- created lazily by CraftingTab

    win._buildTimer          = 0
    win._buildCache          = nil
    win._buildContainers     = nil
    win._buildContainerTimer = 0
    win._buildState          = nil   -- created lazily by BuildingTab

    -- Maps tab state
    win._mapDragging        = false
    win._worldMapPanel      = nil
    win._worldMapFailed     = false
    win._mapActiveTool      = nil
    win._mapActiveColor     = 1
    win._mapToolsExpanded   = false
    win._mapToolZones       = {}
    win._mapColorZones      = {}
    win._mapDisclosureZone  = nil
    win._mapToolRMBZones    = {}

    -- Foraging tab state
    win._foragingStance      = "searching"
    win._foragingCrouch      = false
    win._foragingAim         = false
    win._foragingFocus       = nil
    win._moreDetailOpen      = false
    win._recentFinds         = {}
    win._forageScroll        = ZeD_ScrollbarState:new()
    win._animalsScroll       = ZeD_ScrollbarState:new()
    win._forageStanceZones   = {}
    win._forageDisclosureZone = nil
    win._forageDropdown      = nil
    win._mapTextEntry       = nil
    win._mapEditAnnotIdx    = nil

    -- Multi-container state
    win._mcSelected = {}

    -- S108: gamepad state for worldLootMCColumns zone. _gpFocusedMCItem tracks
    -- the focused Java item for identity preservation across per-frame refresh;
    -- _gpFocusedMCColIdx is its column (for scroll-follow + dispatch edge
    -- detection); _lastPinnedMCItem is the Q99 delta-gate cache.
    win._gpFocusedMCItem     = nil
    win._gpFocusedMCColIdx   = nil
    win._lastPinnedMCItem    = nil

    -- Inventory drawer state (two-drawer architecture)
    win._invDrawerOpen    = true
    win._invDrawerEffW    = T.px(invW)   -- screen px
    win._invDrawerTargetW = T.px(invW)   -- screen px
    win._mainVisible      = true    -- floor container visible (toggleable on Loot)

    -- S98 ring model: construct AFTER container + MC state is initialized.
    -- Zone order (LB/RB cycle): tabs → main_inv → MC columns → containerStrip.
    -- Initial focus on worldTabContent (idx 2) so Y-tap lands cursor on items.
    if ZeD and ZeD.Input and ZeD.Input.Focus then
        local Focus = ZeD.Input.Focus

        local activeTab = win._activeTab or "loot"

        local tabEls = _buildWorldTabBarElements(win)
        _attachWorldTabBarCallbacks(win, tabEls)

        local tabContentEls = _buildWorldPanelFocusables(win, win._mainContent, activeTab) or {}
        -- S99: worldMainInv holds the active container's invrows on ALL tabs
        -- (matches Character's charMainInv pattern — inv is always visible
        -- regardless of active tab). Built even at init; per-frame refresh
        -- keeps it in sync as the container or items change.
        local mainInvEls    = _buildWorldInvRowFocusables(win) or {}
        -- Containers reachable on ALL tabs per user spec (Apr 16). MC toggle
        -- (A press) is Loot-only — enforced inside container onActivate.
        local containerEls  = _buildWorldLootFocusables(win) or {}
        -- S108 v2: per-column MC zones added dynamically post-construction
        -- via _rebuildWorldMCRingZones(). No flat mcEls list at init.

        local activeIdx = 1
        for i, el in ipairs(tabEls) do
            if el.tabId == activeTab then activeIdx = i; break end
        end

        -- S99 HOTFIX: Ring order matches VISUAL left-to-right layout of the
        -- World window (which is MIRRORED from Character):
        --   [containerStrip] [MCColumns] [mainInv] [tabContent] [itemCard] [tabBar]
        -- LB cycles visually LEFT (toward containerStrip); RB cycles visually
        -- RIGHT (toward tabBar). Initial focus on mainInv (idx 3).

        -- S99: uiRange fns for the scoped-underline focus indicator on the
        -- title bar. Read live geometry (drawer width, window width).
        -- S108 v2: worldMainInv uiRange — when MC active, mainInv = the
        -- rightmost (active container) column; else = full inv width.
        -- Per-column MC zones have their own uiRange built inline by
        -- _rebuildWorldMCRingZones (column-precise via colStates renderX/W).
        local function _worldMainInvRange(w)
            local T = ZeD.T
            local content = w._mainContent
            if content and content._colStates and #content._colStates >= 2 then
                local mainCol = content._colStates[#content._colStates]
                if mainCol and mainCol.renderX and mainCol.renderW then
                    return T.px(CONTAINER_STRIP_W) + mainCol.renderX, mainCol.renderW
                end
            end
            return T.px(CONTAINER_STRIP_W), T.px(w._baseInvW or 372)
        end
        local function _worldDrawerRange(w)
            local T = ZeD.T
            local dw = math.floor(w._drawerEffW or 0)
            -- S108 v2 QA: drawer x derived from live window geometry. In MC
            -- mode the inv area expands beyond baseInvW; old hardcoded
            -- (CONTAINER_STRIP_W + baseInvW) anchor put the focus underline
            -- in the wrong x position when card was open over MC. The drawer
            -- always sits between inv area (which can be wide) and the
            -- right-edge action tab strip — derive from total width.
            local ix = w:getWidth() - T.px(ACTION_TAB_STRIP_W) - dw
            return ix, dw
        end

        win._focusRing = {
            { zone = "worldContainerStrip",
              focusable = #containerEls > 0,
              elements = containerEls,
              -- S108: seed by containerIdx match (elements in [floor, non-floor
              -- display-order] layout, not container-index order).
              focusedElementIdx = (function()
                  if not win._activeContainer or #containerEls == 0 then return 1 end
                  for i, el in ipairs(containerEls) do
                      if el.containerIdx == win._activeContainer then return i end
                  end
                  return 1
              end)(),
              uiRange = function(w) return 0, ZeD.T.px(CONTAINER_STRIP_W) end },
            -- S108 v2: Per-column MC zones (worldMC1..worldMCN) inserted here
            -- by _rebuildWorldMCRingZones() called below ring construction.
            -- The single worldLootMCColumns zone has been removed.
            -- S99: Always-visible invrows of the active container. Populated
            -- on every tab — mirrors Character's charMainInv. Focusable
            -- whenever the container has items, regardless of active tab.
            { zone = "worldMainInv",
              focusable = #mainInvEls > 0,
              elements = mainInvEls,
              focusedElementIdx = 1,
              uiRange = _worldMainInvRange },
            { zone = "worldTabContent",
              focusable = #tabContentEls > 0,
              elements = tabContentEls,
              focusedElementIdx = 1,
              uiRange = _worldDrawerRange },
            -- S99: Item card action strip zone — card drawer opens to the
            -- RIGHT of the inventory in World (mirror of Character where it
            -- opens to the LEFT). Focusable only when drawer is in "item" mode.
            { zone = "worldItemCard",
              focusable = false,
              elements = {},
              focusedElementIdx = 1,
              uiRange = _worldDrawerRange },
            { zone = "worldTabBar",
              focusable = #tabEls > 0,
              elements = tabEls,
              focusedElementIdx = activeIdx,
              uiRange = function(w)
                  local T = ZeD.T
                  return w:getWidth() - T.px(ACTION_TAB_STRIP_W), T.px(ACTION_TAB_STRIP_W)
              end },
        }
        -- S108 QA: prefer worldMainInv (idx 3) when focusable, else fall
        -- through to the first focusable zone. mainInv is non-focusable at
        -- toggle-time because content hasn't rendered yet (no _invRowItems);
        -- per-frame refresh populates it next frame. Hardcoded idx=3 left
        -- the user stuck on a non-focusable zone — bumpers cycled around
        -- but D-pad nav within the zone was a silent no-op.
        local function _pickInitialFocusIdx()
            local prefer = 3
            local ring = win._focusRing
            if not ring or #ring == 0 then return 1 end
            if ring[prefer] and ring[prefer].focusable
               and #(ring[prefer].elements or {}) > 0 then return prefer end
            for i = 1, #ring do
                if ring[i].focusable and #(ring[i].elements or {}) > 0 then
                    return i
                end
            end
            return 1
        end
        -- S108 v2: build per-column MC zones (no-op if MC inactive at toggle).
        _rebuildWorldMCRingZones(win)

        win._focusIdx = _pickInitialFocusIdx()

        Focus.claimFocus(win)
    end

    -- Body geometry
    local bodyY = win:getBodyY()
    local bodyH = win:getBodyHeight()

    -- Forward declarations (closures reference these before assignment)
    local content
    local actionTabStrip

    -- ----------------------------------------------------------------
    -- CONTAINER STRIP — left edge, 36px wide
    -- ----------------------------------------------------------------
    local containerStrip = ZeD_Panel:new(0, bodyY, T.px(CONTAINER_STRIP_W), bodyH)
    containerStrip.anchorRight = false
    containerStrip:initialise()
    win:addChild(containerStrip)
    win._containerStrip = containerStrip

    containerStrip._onPrerender = function(self)
        drawWorldContainerStrip(self, win, content)
    end

    containerStrip.onMouseDown = function(self, x, y)
        local zone = self:hitZoneAt(x, y)
        if not zone then return true end
        local zid = zone.id
        local T = ZeD.T

        -- Scroll arrows
        if zid == "scroll_up" then
            win._stripScrollOffset = (win._stripScrollOffset or 0) - T.px(CONTAINER_BTN_SZ)
            return true
        elseif zid == "scroll_down" then
            win._stripScrollOffset = (win._stripScrollOffset or 0) + T.px(CONTAINER_BTN_SZ)
            return true
        end

        -- Sort mode cycle: dist → wt → type → dist
        if zid == "wt_sort" then
            local cycle = { dist = "wt", wt = "type", type = "dist" }
            win._containerSortMode = cycle[win._containerSortMode or "dist"] or "wt"
            return true
        end

        -- Container click
        if type(zid) == "number" and win._containers[zid] then
            local cnt = win._containers[zid]
            if not cnt.locked then
                if win._activeTab == "loot" then
                    -- Loot tab: MC toggle (multi-column)
                    mcToggleWorldContainer(win, content, zid)
                else
                    -- Other tabs: toggle inventory drawer or switch container
                    local currentView = win._viewedContainer or win._activeContainer
                    if zid == currentView and win._invDrawerOpen then
                        -- Same container: close inventory (snap)
                        win._invDrawerOpen = false
                        local drawerW = math.floor(win._drawerEffW or 0)
                        local snapW = T.px(CONTAINER_STRIP_W) + drawerW + T.px(ACTION_TAB_STRIP_W)
                        win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                win:setWidth(snapW)
                    elseif not win._invDrawerOpen then
                        -- Inventory closed: open showing this container (snap)
                        win._viewedContainer = (zid ~= win._activeContainer) and zid or nil
                        win._invDrawerOpen = true
                        local drawerW = math.floor(win._drawerEffW or 0)
                        local baseInv = T.px(win._baseInvW or 372)
                        local snapW = T.px(CONTAINER_STRIP_W) + baseInv + drawerW + T.px(ACTION_TAB_STRIP_W)
                        local maxW = win._maxWinW or math.floor(getCore():getScreenWidth() * 0.5)
                        win:setWidth(math.min(snapW, maxW))
                    else
                        -- Different container: just switch
                        win._viewedContainer = (zid ~= win._activeContainer) and zid or nil
                    end
                    if win._invDrawerOpen then
                        content._inventory = win._containers[win._viewedContainer or win._activeContainer].inventory
                    end
                    content._selectedItems = {}
                    content._lastClickedItem = nil
                end
            end
        end
        return true
    end

    containerStrip.onMouseWheel = function(self, del)
        local T = ZeD.T
        local total = #win._containers - 1  -- minus active
        if total > 0 then
            win._stripScrollOffset = (win._stripScrollOffset or 0) + del * T.px(CONTAINER_BTN_SZ)
        end
        return true
    end

    -- ----------------------------------------------------------------
    -- CONTENT PANEL — item list, fills remaining width
    -- ----------------------------------------------------------------
    content = ZeD_Panel:new(T.px(CONTAINER_STRIP_W), bodyY, winW - T.px(CONTAINER_STRIP_W) - T.px(ACTION_TAB_STRIP_W), bodyH)
    content.anchorRight = false  -- drawer prerender controls width, not ISPanel auto-resize
    content:initialise()
    win:addChild(content)
    win._contentPanel = content
    -- S94 B-nav: expose content panel to gamepad focus callbacks set earlier
    -- in toggle(). Closures look up `win._mainContent` at fire time, so it's
    -- fine that this assignment happens after the focus context was pushed.
    win._mainContent = content

    -- Inventory data refs
    content._playerObj     = playerObj
    local initCnt = win._containers[win._activeContainer]
    content._inventory     = initCnt and initCnt.inventory or nil
    content._selectedItems = {}
    content._lastClickedItem = nil
    content._flatItems     = {}

    -- Sort state
    content._sortCol = "name"
    content._sortAsc = true

    -- Column header Y offset — aligns with container strip's header row
    content._hdrYOffset = T.px(CONTAINER_BTN_SZ) + T.px(1)
    content._defaultHdrYOffset = T.px(CONTAINER_BTN_SZ) + T.px(1)

    -- Collapse state
    content._collapsedGroups = {}

    -- Scrollbar state
    local ZeD_ScrollbarState = ZeD.Molecules.ScrollbarState
    content._scroll = ZeD_ScrollbarState:new()
    content._scroll.visible = true
    content._scroll.onScroll = function(pos) end

    -- Drag state + multi-container state
    local ZeD_DragState = ZeD.Molecules.DragState
    content._drag = ZeD_DragState:new()
    content._deferredSelect = nil
    content._dragSourceCol  = nil
    content._dragSourceInv  = nil
    content._activeCol      = nil
    content._activeScroll   = nil
    content._colWidths      = { cat = math.floor(70 * T.scale), cond = math.floor(50 * T.scale), wt = math.floor(40 * T.scale) }
    content._colDrag        = nil
    content._barH           = 0

    -- ----------------------------------------------------------------
    -- DRAWER PANEL — right edge, slides open/closed with ItemCard
    -- ----------------------------------------------------------------
    local drawer = ZeD_Panel:new(winW - T.px(ACTION_TAB_STRIP_W), bodyY, 0, bodyH)
    drawer.anchorRight = false
    drawer:initialise()
    win:addChild(drawer)
    win._drawerPanel = drawer

    -- Crafting tab search field (ISPanel child of drawer)
    local craftSearch = ZeD_SearchField:new(0, 0, T.px(200), "Search recipes...")
    craftSearch:initialise()
    craftSearch:setVisible(false)
    craftSearch.onFilter = function(self, text)
        if win._craftState then
            if win._craftState.altSlotName then
                win._craftState.altSearch = text
            else
                win._craftState.search = text
                win._craftState.filterDirty = true
                win._craftState.scroll:setScrollPos(0)
            end
        end
        win._craftCache = nil
    end
    drawer:addChild(craftSearch)
    win._craftSearch = craftSearch

    -- Building tab search field
    local buildSearch = ZeD_SearchField:new(0, 0, T.px(200), "Search structures...")
    buildSearch:initialise()
    buildSearch:setVisible(false)
    buildSearch.onFilter = function(self, text)
        if win._buildState then
            if win._buildState.altSlotName then
                win._buildState.altSearch = text
            else
                win._buildState.search = text
                win._buildState.filterDirty = true
                win._buildState.scroll:setScrollPos(0)
            end
        end
        win._buildCache = nil
    end
    drawer:addChild(buildSearch)
    win._buildSearch = buildSearch

    -- ----------------------------------------------------------------
    -- ITEM DRAWER — overlay panel for ItemCard, renders ON TOP of tab drawer
    -- ----------------------------------------------------------------
    local itemDrawer = ZeD_Panel:new(winW - T.px(ACTION_TAB_STRIP_W), bodyY, 0, bodyH)
    itemDrawer.anchorRight = false
    itemDrawer:initialise()
    win:addChild(itemDrawer)
    win._itemDrawerPanel = itemDrawer

    local card = ZeD_ItemCard:new(0, 0, T.px(ITEM_CARD_W), bodyH, "drawer", playerNum)
    card:initialise()
    card:setVisible(false)
    itemDrawer:addChild(card)
    win._itemCard = card

    itemDrawer._onPrerender = function(self)
        local T = ZeD.T
        local effectiveW = math.floor(win._drawerEffW)
        local bodyH = win:getBodyHeight()
        self:setHeight(bodyH)

        local showCard = win._drawerItem ~= nil and effectiveW > 0
        card:setVisible(showCard)

        if showCard then
            -- World window: card always at left edge (inventory-facing)
            self:setX(drawer:getX())
            self:setWidth(math.min(effectiveW, T.px(ITEM_CARD_W)))
            card:setX(0)
            card:setWidth(math.min(self:getWidth(), T.px(ITEM_CARD_W)))
            card:setHeight(bodyH)

            -- Background fill (surf1, 0.98 alpha)
            local dh = self:getHeight()
            local wc = T.surf1
            self:drawRect(0, 0, self:getWidth(), dh, 0.98, wc.r, wc.g, wc.b)
            -- Left border (matches tab drawer's left divider)
            local bd = T.border
            self:drawRect(0, 0, T.px(1), dh, bd.a, bd.r, bd.g, bd.b)
        else
            self:setWidth(0)
        end
    end

    itemDrawer.onMouseWheel = function(self, del)
        if card:getIsVisible() then
            card:onMouseWheel(del)
        end
        return true
    end

    -- Drawer animation + layout sync (runs every frame)
    drawer._onPrerender = function(self)
        local T = ZeD.T

        -- Pixel-based animation toward target width (mode-aware)
        local targetW = getWorldTargetDrawerW(win)
        local effW = win._drawerEffW
        if effW ~= targetW then
            local dt = UIManager.getMillisSinceLastRender() / 1000.0
            if dt > 0.1 then dt = 0.1 end
            if effW < targetW then
                effW = math.min(effW + T.px(DRAWER_PX_SPEED) * dt, targetW)
            else
                effW = math.max(effW - T.px(DRAWER_PX_SPEED) * dt, targetW)
            end
            win._drawerEffW = effW
        end

        local effectiveW = math.floor(effW)
        self:setWidth(effectiveW)

        -- ── Original proven model: tab drawer delta drives window width,
        -- invW is always the residual. Inv toggle snaps width directly. ──
        local prevEffW = win._prevEffW or effectiveW
        local drawerDelta = effectiveW - prevEffW
        win._prevEffW = effectiveW

        local mcActive = #(win._mcSelected or {}) > 0
        local screenW = getCore():getScreenWidth()
        -- S121: when MC + item card both active, cap maxW at user's preferred
        -- inv width (_baseInvW) plus chrome — window expands enough to keep
        -- card visible alongside MC, but not to full screen, so the eviction
        -- loop below fires when MC columns can't all fit at MIN_COL_W.
        local mcItemCap = nil
        if mcActive and win._drawerMode == "item" then
            local baseInv = T.px(win._baseInvW or 372)
            mcItemCap = T.px(CONTAINER_STRIP_W) + baseInv + effectiveW + T.px(ACTION_TAB_STRIP_W)
        end
        local maxW = mcItemCap
            or (mcActive and (screenW - win:getX() - T.px(10)))
            or (win._maxWinW or math.floor(screenW * 0.5))

        if drawerDelta ~= 0 then
            -- S121: card opening in MC mode now expands the window like tab
            -- mode does, instead of evicting MC columns. The S108 v2 design
            -- (shrink inv area + FIFO evict oldest MC col when MC + item)
            -- caused MC to silently collapse on item-select — bad UX after
            -- the new ItemCard rolled. Always resize per drawerDelta now.
            local newW = math.min(win:getWidth() + drawerDelta, maxW)
            win:setWidth(newW)
        else
            -- At rest: accept user resize
            if win:getWidth() > maxW then win:setWidth(maxW) end
        end

        -- invW is ALWAYS the residual
        local invW = win:getWidth() - T.px(CONTAINER_STRIP_W) - effectiveW - T.px(ACTION_TAB_STRIP_W)
        invW = math.max(invW, 0)

        -- Track baseInvW ONLY when user manually resized (not from our snaps).
        if drawerDelta == 0 and effectiveW == 0 and not mcActive and invW > 0 then
            local expectedW = T.px(CONTAINER_STRIP_W) + T.px(win._baseInvW or 372) + T.px(ACTION_TAB_STRIP_W)
            if win:getWidth() ~= expectedW then
                -- S124 scale: _baseInvW is stored in design units (screen px / T.scale);
                -- kept fractional so save/restore round-trips without drift.
                win._baseInvW = invW / (T.scale or 1)
            end
        end

        -- Dynamic minimum
        local bh = win:getBodyHeight()
        win.minimumWidth = T.px(CONTAINER_STRIP_W) + (win._invDrawerOpen and T.px(200) or 0) + effectiveW + T.px(ACTION_TAB_STRIP_W)

        -- ── MC eviction ──────────────────────────────────────────
        if mcActive and #(win._mcSelected) > 0 then
            local R = getR()
            local minColW = T.px(R.MIN_COL_W or 140)
            local totalCols = #win._mcSelected + (win._mainVisible and 1 or 0)
            local xferW = T.px(R.getXferW and R.getXferW(totalCols) or 32)
            local usable = invW - (totalCols - 1) * xferW
            local perCol = totalCols > 0 and (usable / totalCols) or 0
            local evicted = false
            while perCol < minColW and #win._mcSelected > 0 do
                table.remove(win._mcSelected, 1)
                totalCols = #win._mcSelected + 1
                xferW = T.px(R.getXferW and R.getXferW(totalCols) or 32)
                usable = invW - (totalCols - 1) * xferW
                perCol = totalCols > 0 and (usable / totalCols) or invW
                evicted = true
            end
            if evicted then
                if #win._mcSelected == 0 then
                    exitWorldMC(win, content)
                else
                    local R2 = getR()
                    local colSel = {}
                    for _, ci in ipairs(win._mcSelected) do colSel[#colSel + 1] = ci end
                    if win._mainVisible then
                        local activeInMc = false
                        for _, ci in ipairs(win._mcSelected) do
                            if ci == win._activeContainer then activeInMc = true; break end
                        end
                        if not activeInMc then
                            colSel[#colSel + 1] = win._activeContainer
                        end
                    end
                    content._selectedContainers = colSel
                    content._containers = win._containers
                    R2.rebuildColStates(content)
                    content._activeCol = #colSel
                end
                win._invDrawerTargetW = computeInvDrawerTargetWorld(win)
                -- S108 v2 QA: ring zones must reflect new MC count after
                -- FIFO eviction; otherwise stale worldMC<n> zones linger
                -- in the ring and bumpers cycle to zones with no items.
                if _syncWorldRingZones then _syncWorldRingZones(win, content) end
            end
        end

        -- Content: positioned after container strip, width = residual invW
        content:setX(T.px(CONTAINER_STRIP_W))
        content:setWidth(math.max(invW, 0))
        content:setVisible(invW > 0)

        -- Drawer + action tab strip positioned after content
        containerStrip:setHeight(bh)
        content:setHeight(bh)
        self:setX(T.px(CONTAINER_STRIP_W) + invW)
        self:setHeight(bh)
        actionTabStrip:setX(T.px(CONTAINER_STRIP_W) + invW + effectiveW)
        actionTabStrip:setHeight(bh)

        -- Store divider position for top-Z drawing in win.render
        win._dividerX = (effectiveW > 0 and invW > 0) and (T.px(CONTAINER_STRIP_W) + invW) or nil

        -- Card visibility now managed by ITEM.DRAWER overlay panel

        -- Crafting search field visibility (tab mode + craft tab active)
        local showCraft = effectiveW > 0 and win._drawerMode == "tab" and win._activeTab == "craft"
        win._craftSearch:setVisible(showCraft)

        local showBuild = effectiveW > 0 and win._drawerMode == "tab" and win._activeTab == "build"
        win._buildSearch:setVisible(showBuild)

        -- Hide map panel + text entry when Maps tab is not active
        if win._activeTab ~= "maps" then
            if win._worldMapPanel then win._worldMapPanel:setVisible(false) end
            if win._mapTextEntry then win._mapTextEntry:setVisible(false) end
        end

        -- Hide foraging dropdown when not on forage tab
        local showForage = effectiveW > 0 and win._drawerMode == "tab" and win._activeTab == "forage"
        if win._forageDropdown then win._forageDropdown:setVisible(showForage) end

        -- Draw drawer background + content when visible (in MC, only draw for item card or active tab)
        if effectiveW > 0 and (not mcActive or win._drawerMode == "item" or win._drawerMode == "tab") then
            local dh = self:getHeight()
            -- Always stencil-clip drawer content to prevent child overflow (dropdowns, etc.)
            self:setStencilRect(0, 0, effectiveW, dh)

            -- Drawer background fill (theme-aware tonal separation)
            local db = T.drawerBg
            self:drawRect(0, 0, effectiveW, dh, db.a, db.r, db.g, db.b)

            -- Card bg now drawn by ITEM.DRAWER overlay panel
            local bd = T.border
            self:drawRect(0, 0, T.px(1), dh, bd.a, bd.r, bd.g, bd.b)

            -- Tab content rendering (when in tab mode)
            if win._drawerMode == "tab" and win._activeTab then
                local renderer = WORLD_TAB_RENDERERS[win._activeTab]
                if renderer then
                    renderer(self, win, 0, 0, targetW, dh)
                else
                    -- Placeholder for unregistered tabs
                    local tabDef
                    for _, t in ipairs(WORLD_TABS) do
                        if t.id == win._activeTab then tabDef = t; break end
                    end
                    if tabDef then
                        renderPlaceholder(self, tabDef, 0, 0, targetW, dh)
                    end
                end
            end

            self:clearStencilRect()
        end
    end

    -- Drawer mouse wheel → map zoom, tab scroll, or ItemCard scroll
    drawer.onMouseWheel = function(self, del)
        if win._drawerMode == "tab" and win._activeTab == "maps" and win._worldMapPanel then
            win._worldMapPanel:onMouseWheel(del)
            return true
        end
        -- Crafting/Building tabs: delegate to CraftingCore (handles dropdown scroll)
        if win._drawerMode == "tab" and win._activeTab == "craft" then
            ZeD.CraftingTab.onMouseWheel(win, del, self:getMouseX(), self:getMouseY())
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "build" then
            ZeD.BuildingTab.onMouseWheel(win, del, self:getMouseX(), self:getMouseY())
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "vehicle" then
            return ZeD.MechanicsTab.onMouseWheel(win, del)
        end
        if win._drawerMode == "tab" then
            local scroll = getWorldActiveScroll(win)
            if scroll and scroll.visible then
                local step = 0.05
                scroll:setScrollPos(scroll.scrollPos + del * step)
                return true
            end
        end
        -- Card scroll now handled by ITEM.DRAWER overlay panel
        return false
    end

    -- Drawer click → tab content click handler
    drawer.onMouseDown = function(self, x, y)
        if win._drawerMode == "tab" and win._activeTab == "craft" then
            ZeD.CraftingTab.onClick(win, x, y)
            return true  -- always consume in tab mode
        end
        if win._drawerMode == "tab" and win._activeTab == "build" then
            ZeD.BuildingTab.onClick(win, x, y)
            return true  -- always consume in tab mode
        end
        if win._drawerMode == "tab" and win._activeTab == "maps" then
            ZeD.MapsTab.onClick(win, x, y)
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "forage" then
            ZeD.ForagingTab.onClick(win, x, y)
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "animals" then
            ZeD.AnimalsTab.onClick(win, x, y)
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "radio" then
            ZeD.RadioTab.onClick(win, x, y)
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "vehicle" then
            return ZeD.MechanicsTab.onClick(win, x, y)
        end
        return false
    end

    -- Drawer right-click → pin toggle (crafting/building tab)
    drawer.onRightMouseDown = function(self, x, y)
        if win._drawerMode == "tab" and win._activeTab == "craft" then
            ZeD.CraftingTab.onRightClick(win, x, y)
            return true  -- always consume in tab mode
        end
        if win._drawerMode == "tab" and win._activeTab == "build" then
            ZeD.BuildingTab.onRightClick(win, x, y)
            return true  -- always consume in tab mode
        end
        if win._drawerMode == "tab" and win._activeTab == "maps" then
            ZeD.MapsTab.onRightClick(win, x, y)
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "forage" then
            ZeD.ForagingTab.onRightClick(win, x, y)
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "animals" then
            ZeD.AnimalsTab.onRightClick(win, x, y)
            return true
        end
        if win._drawerMode == "tab" and win._activeTab == "vehicle" then
            return ZeD.MechanicsTab.onRightClick(win, x, y)
        end
        return false
    end

    -- Drawer mouse move → map panning
    drawer.onMouseMove = function(self, dx, dy)
        ISPanel.onMouseMove(self, dx, dy)
        if win._mapDragging then
            if not isMouseButtonDown(0) then
                if win._worldMapPanel then win._worldMapPanel:onMouseUp(0, 0) end
                win._mapDragging = false
            else
                if win._worldMapPanel then win._worldMapPanel:onMouseMove(dx, dy) end
            end
        end
    end

    drawer.onMouseMoveOutside = function(self, dx, dy)
        ISPanel.onMouseMoveOutside(self, dx, dy)
        if win._mapDragging then
            if not isMouseButtonDown(0) then
                if win._worldMapPanel then win._worldMapPanel:onMouseUp(0, 0) end
                win._mapDragging = false
            else
                if win._worldMapPanel then win._worldMapPanel:onMouseMove(dx, dy) end
            end
        end
    end

    -- Drawer mouse up → release map drag
    drawer.onMouseUp = function(self, x, y)
        if win._mapDragging then
            if win._worldMapPanel then win._worldMapPanel:onMouseUp(x, y) end
            win._mapDragging = false
        end
        return true
    end

    drawer.onMouseUpOutside = function(self, x, y)
        if win._mapDragging then
            if win._worldMapPanel then win._worldMapPanel:onMouseUp(x, y) end
            win._mapDragging = false
        end
        return true
    end

    -- ----------------------------------------------------------------
    -- ACTION TAB STRIP — right edge, 28px wide
    -- ----------------------------------------------------------------
    actionTabStrip = ZeD_Panel:new(winW - T.px(ACTION_TAB_STRIP_W), bodyY, T.px(ACTION_TAB_STRIP_W), bodyH)
    actionTabStrip.anchorRight = false
    actionTabStrip:initialise()
    win:addChild(actionTabStrip)
    win._actionTabStrip = actionTabStrip

    actionTabStrip._onPrerender = function(self)
        drawWorldTabStrip(self, win)
    end

    actionTabStrip.onMouseDown = function(self, x, y)
        local zone = self:hitZoneAt(x, y)
        if not zone then return true end
        local zid = zone.id
        local T = ZeD.T

        -- Scroll arrows
        if zid == "tab_scroll_up" then
            win._actionTabScrollOffset = (win._actionTabScrollOffset or 0) - T.px(ACTION_TAB_BTN_SZ)
            return true
        elseif zid == "tab_scroll_down" then
            win._actionTabScrollOffset = (win._actionTabScrollOffset or 0) + T.px(ACTION_TAB_BTN_SZ)
            return true
        end

        -- Tab click
        if type(zid) == "string" and zid:sub(1, 4) == "tab:" then
            local tabId = zid:sub(5)

            if tabId == "loot" then
                -- LOOT: snap to inventory-only state (no cross-animation)
                win._activeTab  = "loot"
                win._drawerMode = nil
                win._drawerOpen = false
                win._drawerItem = nil
                win._tabUnder   = nil
                content._selectedItems = {}
                content._lastClickedItem = nil
                -- Snap to base inventory width
                local baseInv = T.px(win._baseInvW or 372)
                win._drawerEffW  = 0
                win._prevEffW    = 0
                win._invDrawerOpen = true
                local snapW = T.px(CONTAINER_STRIP_W) + baseInv + T.px(ACTION_TAB_STRIP_W)
                win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                win:setWidth(snapW)

            elseif tabId == win._activeTab then
                -- SAME TAB: toggle drawer open/closed
                if win._drawerOpen and win._drawerMode == "tab" then
                    -- Closing tab: if inventory hidden, reopen it first
                    if not win._invDrawerOpen then
                        win._invDrawerOpen = true
                        win._invDrawerTargetW = T.px(win._baseInvW or 372)
                    end
                    win._activeTab  = "loot"  -- back to inventory-only = loot view
                    win._drawerOpen = false
                    win._drawerMode = nil
                    win._tabUnder   = nil
                else
                    win._drawerMode = "tab"
                    win._drawerOpen = true  -- triggers window growth animation
                    win._drawerItem = nil
                    win._tabUnder   = nil
                end

            else
                -- NEW TAB: MC exit FIRST (before drawer opens)
                local mcSel2 = win._mcSelected or {}
                if #mcSel2 > 0 and tabId ~= "loot" then
                    exitWorldMC(win, content)
                    local baseInv = T.px(win._baseInvW or 372)
                    local snapW = T.px(CONTAINER_STRIP_W) + baseInv + T.px(ACTION_TAB_STRIP_W)
                    win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                win:setWidth(snapW)
                end
                -- Now open drawer from clean base
                win._activeTab  = tabId
                win._drawerMode = "tab"
                win._drawerOpen = true
                win._drawerItem = nil
                win._tabUnder   = nil
                content._selectedItems = {}
                content._lastClickedItem = nil

                -- Reset tab scroll
                local scroll = getWorldActiveScroll(win)
                if scroll then scroll:setScrollPos(0) end
            end
        end
        -- S123: re-sync gamepad ring zones on every strip click (mirror of the
        -- Character window fix; the gamepad tab path already syncs).
        if _syncWorldRingZones then _syncWorldRingZones(win, content) end
        return true
    end

    actionTabStrip.onMouseWheel = function(self, del)
        local T = ZeD.T
        local totalH = measureWorldTabStripH(win)
        if totalH > self:getHeight() then
            win._actionTabScrollOffset = (win._actionTabScrollOffset or 0) + del * T.px(ACTION_TAB_BTN_SZ)
            return true
        end
        return false
    end

    -- ----------------------------------------------------------------
    -- updateDrawer — 3-mode state machine (nil / item / tab)
    -- ----------------------------------------------------------------
    local function updateDrawer()
        local prevMode = win._drawerMode
        local prevItem = win._drawerItem   -- S99: card-visibility snapshot
        local sel = content._selectedItems
        local count = 0
        local singleItem = nil
        for item, _ in pairs(sel) do
            count = count + 1
            singleItem = item
            if count > 1 then break end
        end

        if count == 1 then
            -- Item selected: show item card (overlay if tab active)
            if singleItem ~= win._drawerItem then
                win._itemCard:setItem(singleItem)
            end
            win._drawerItem = singleItem
            -- S121 (Phase C3): wire the new ItemCard organism's sourceContext.
            -- World drawer items are NEVER "equipped" or "inventory" — always
            -- container or ground. World containers have .isFloor (not .isMain
            -- — that's Char-only); _activeContainer is an INDEX into the
            -- _containers list, not a container reference.
            do
                local cntEntry = win._containers
                    and win._containers[win._activeContainer or 1]
                if cntEntry and cntEntry.isFloor then
                    win._itemCard.sourceContext = "ground"
                else
                    win._itemCard.sourceContext = "container"
                end
            end
            if win._drawerMode ~= "tab" then
                win._drawerMode = "item"
            end
            win._drawerOpen = true

        else
            -- No item (or multi-select): hide card, restore mode
            win._drawerItem = nil
            if win._activeTab ~= "loot" then
                win._drawerMode = "tab"
                win._drawerOpen = true
            elseif #(win._mcSelected or {}) > 0 then
                win._drawerMode = nil
                win._drawerOpen = true  -- keep open for MC columns
            else
                win._drawerMode = nil
                win._drawerOpen = false
            end
        end

        -- S99: If the card just became hidden while focus was on worldItemCard,
        -- snap ring focus back to worldMainInv. Gate on card-visibility
        -- transition (`prevItem ~= nil and now nil`) rather than drawerMode,
        -- since on non-Loot tabs the card is visible with drawerMode=="tab".
        if prevItem ~= nil and win._drawerItem == nil and win._focusRing then
            local cardIdx, invIdx
            for i, z in ipairs(win._focusRing) do
                if z.zone == "worldItemCard"   then cardIdx = i
                elseif z.zone == "worldMainInv" then invIdx  = i end
            end
            if cardIdx and invIdx and win._focusIdx == cardIdx then
                win._focusIdx = invIdx
            end
        end
    end

    -- S99: Expose updateDrawer on win so the invrow A binding (mouse-click
    -- parity: A → select item → drawer opens) can trigger it. Closure keeps
    -- `content` + `win` captured.
    win._updateDrawer = updateDrawer

    -- S113: D-pad direction wrappers RETIRED. Under flat free-nav, D-pad is
    -- pure spatial cone-nav across all focusable zones in the focused window.
    -- Behaviors handled by the old wrappers now live on elements:
    --   * Disclosure expand/collapse → A (onActivate, mouse parity)
    --   * Stack expand/collapse      → A on stack chevron
    --   * Item card open             → A on inv row (selects item, drawer opens)
    --   * Item card close            → B (onCancel)
    --   * Card U/D content scroll    → onDpadDir on card action strip elements
    --   * GridScroll U/D scroll      → onDpadDir on gridScroll pseudo-focusable
    --   * Maps cursor pixel move     → onDpadDir on isCanvasCursor element
    --   * Animals zone-draw cursor   → onDpadDir on isZoneDraw element

    -- Draw hook: render item list + update title bar stats
    content._onPrerender = function(self)
        local T = ZeD.T
        -- Suppress vanilla loot panel if it re-shows
        local vl = getPlayerLoot(0)
        if vl and vl:getIsVisible() then vl:setVisible(false) end

        local mcSel = win._mcSelected or {}
        local colCount = #mcSel + (win._mainVisible and 1 or 0)

        if #mcSel > 0 and colCount >= 2 then
            -- Multi-column MC: render side-by-side
            local colSel = {}
            for _, ci in ipairs(mcSel) do
                colSel[#colSel + 1] = ci
            end
            if win._mainVisible then
                -- S108 v2 QA: dedup _activeContainer if already in mcSel.
                local activeInMc = false
                for _, ci in ipairs(mcSel) do
                    if ci == win._activeContainer then activeInMc = true; break end
                end
                if not activeInMc then
                    colSel[#colSel + 1] = win._activeContainer
                end
            end
            self._selectedContainers = colSel
            self._containers = win._containers
            self._barH = 0
            self._activeCol = math.min(self._activeCol or #colSel, #colSel)
            win.title = #colSel .. " CONTAINERS"
            win.titleStats = {}
            r.renderMultiColumnContent(self)
        else
            -- Single container: determine which to show
            local viewIdx
            if #mcSel > 0 and not win._mainVisible then
                viewIdx = mcSel[1]
            else
                viewIdx = win._viewedContainer or win._activeContainer
            end
            local cnt = win._containers[viewIdx]
            if cnt then
                win.title = "World"
                local cInv = cnt.inventory
                local cItems = cInv and cInv:getItems() and cInv:getItems():size() or 0
                local cWeight = cInv and round(cInv:getCapacityWeight(), 1) or 0
                local cMax = cInv and round(cInv:getMaxWeight(), 1) or 0

                self._containerInfo = {
                    name    = cnt.name,
                    texture = not cnt.isFloor and cnt.texture or nil,
                    stats   = cnt.isFloor and "" or string.format("%.1f/%.0fkg", cWeight, cMax),
                    count   = cItems .. " items",
                }

                win.title = cnt.name .. "  " .. cItems
                self._inventory = cInv
            end
            r.renderItemList(self)
        end

        -- --------------------------------------------------------
        -- S99 RING MODEL: PER-FRAME WORLDMAININV REFRESH (World Window)
        -- Unconditional — worldMainInv holds the active container's invrows
        -- on ALL tabs, mirroring Character's charMainInv. Same dirty check,
        -- identity preservation, container-change guard.
        -- --------------------------------------------------------
        local Focus = ZeD.Input and ZeD.Input.Focus
        if Focus and win._focusRing then

            -- Guard: container source inventory still valid?
            if not self._inventory then
                Focus.setRingZoneElements(win, "worldMainInv", {})
                Focus.setZoneFocusable   (win, "worldMainInv", false)
                win._gpFocusedRowItem = nil
                win._invRowsForContainer = nil
                self._gpFocusedRowItem = nil
                win._lastInvRowSnapshot = nil
            else
                -- Guard: active container changed since rows were last seeded?
                if win._invRowsForContainer
                   and win._invRowsForContainer ~= win._activeContainer then
                    Focus.setRingZoneElements(win, "worldMainInv", {})
                    Focus.setZoneFocusable   (win, "worldMainInv", false)
                    win._gpFocusedRowItem = nil
                    win._invRowsForContainer = nil
                    self._gpFocusedRowItem = nil
                    win._lastInvRowSnapshot = nil
                else
                    local oldSnap = win._lastInvRowSnapshot
                    local newItems = self._invRowItems
                    local oldN = oldSnap and #oldSnap or 0
                    local newN = newItems and #newItems or 0
                    local dirty = (oldN ~= newN)
                    if not dirty and newN > 0 and oldSnap then
                        dirty = (oldSnap[1] ~= newItems[1])
                             or (oldSnap[newN] ~= newItems[newN])
                    end
                    if not oldSnap then dirty = true end
                    -- S108 v2 QA: MC state transition forces rebuild even
                    -- when item count is unchanged. The placeholder branch
                    -- (mcActive + empty mainInv) needs to fire on MC enter
                    -- even if mainInv was already empty before MC.
                    local mcActive = win._mcSelected and #win._mcSelected > 0
                    if win._lastMcActiveForMainInv ~= mcActive then
                        dirty = true
                        win._lastMcActiveForMainInv = mcActive
                    end

                    if dirty then
                        local snap = {}
                        if newItems then
                            for si = 1, #newItems do snap[si] = newItems[si] end
                        end
                        win._lastInvRowSnapshot = snap

                        local newEls = _buildWorldInvRowFocusables(win)
                        -- S108 v2 QA: when MC is active AND the last colState
                        -- is already covered by a worldMC<N> zone (i.e. all
                        -- MC selections are visible columns, no extra "main"
                        -- column appended), worldMainInv would duplicate the
                        -- last MC zone. In that case, force empty so the
                        -- ring skips it (one bumper press from MC<N> → next
                        -- focusable zone instead of two).
                        local mcN  = win._mcSelected and #win._mcSelected or 0
                        local colN = self._colStates and #self._colStates or 0
                        local mainInvDuplicates = (mcN > 0 and colN <= mcN)
                        if mainInvDuplicates then
                            newEls = {}
                        elseif #newEls == 0 and mcN > 0 then
                            -- MC active, mainInv has its OWN unique column
                            -- (e.g. floor when _activeContainer not in MC),
                            -- but it's empty. Placeholder keeps zone reachable.
                            local stripY = win:getBodyY()
                            local rowH   = (T and T.rowH) or 26
                            local colX, colW = 0, T.px(200)
                            local cs = self._colStates and self._colStates[#self._colStates]
                            if cs then
                                colX = cs.renderX or 0
                                colW = cs.renderW or T.px(200)
                            end
                            newEls = {{
                                x = colX, y = stripY + rowH, w = colW, h = rowH,
                                id = "maininv_empty",
                                item = nil,
                                isPlaceholder = true,
                                onFocus    = function(w, el) end,
                                onActivate = function(w, el) end,
                            }}
                        end
                        if #newEls == 0 then
                            Focus.setRingZoneElements(win, "worldMainInv", {})
                            Focus.setZoneFocusable   (win, "worldMainInv", false)
                            win._gpFocusedRowItem = nil
                            win._invRowsForContainer = nil
                            self._gpFocusedRowItem = nil
                        else
                            local preserveIdx = 1
                            local focItem = win._gpFocusedRowItem
                            if focItem then
                                for i, el in ipairs(newEls) do
                                    if el.item == focItem then
                                        preserveIdx = i
                                        break
                                    end
                                end
                                if preserveIdx == 1 and focItem ~= (newEls[1] and newEls[1].item) then
                                    local oldIdx = 1
                                    if win._focusRing then
                                        for _, z in ipairs(win._focusRing) do
                                            if z.zone == "worldMainInv" then
                                                oldIdx = z.focusedElementIdx or 1
                                                break
                                            end
                                        end
                                    end
                                    preserveIdx = math.min(oldIdx, #newEls)
                                end
                            end

                            Focus.setRingZoneElements(win, "worldMainInv", newEls, preserveIdx)
                            Focus.setZoneFocusable   (win, "worldMainInv", true)
                            local resolvedEl = newEls[preserveIdx]
                            if resolvedEl then
                                win._gpFocusedRowItem = resolvedEl.item
                                self._gpFocusedRowItem = resolvedEl.item
                            end
                        end
                    end
                end
            end
        end

        -- --------------------------------------------------------
        -- S108 v2 RING MODEL: PER-FRAME PER-COLUMN MC ZONE REFRESH
        -- Each MC selection has its own ring zone (worldMC1..worldMCN).
        -- Loop over slots and refresh each zone's elements independently.
        -- Identity-preserve via _gpFocusedMCItem (per-zone idx tracked by
        -- Focus.setRingZoneElements). When MC count or active tab changes,
        -- the ring is restructured by _rebuildWorldMCRingZones (called from
        -- mcToggleWorldContainer / _switchWorldTabForNav via _syncWorldRingZones).
        -- --------------------------------------------------------
        if Focus and win._focusRing and win._activeTab == "loot" then
            local mcSel = win._mcSelected or {}
            for slot = 1, #mcSel do
                local zoneName = "worldMC" .. slot
                local newEls = _buildWorldMCColumnFocusables(win, slot) or {}
                local preserveIdx = 1
                if #newEls > 0 and win._gpFocusedMCItem then
                    for i, el in ipairs(newEls) do
                        if el.item == win._gpFocusedMCItem then
                            preserveIdx = i
                            break
                        end
                    end
                end
                Focus.setRingZoneElements(win, zoneName, newEls, preserveIdx)
                Focus.setZoneFocusable   (win, zoneName, #newEls > 0)
            end
        end

        -- S98/S99 per-frame refresh for worldTabContent zone. Runs for
        -- tab-specific non-inv content only (forage stances, animals
        -- submodes, S107: craft + build CC zones, S112: maps toolbar +
        -- canvas cursor). Loot no longer lands here (invrows live in
        -- worldMainInv).
        if Focus and win._focusRing and (
                 win._activeTab == "forage" or
                 win._activeTab == "animals" or
                 win._activeTab == "craft" or
                 win._activeTab == "build" or
                 win._activeTab == "maps" or
                 win._activeTab == "radio" or -- S117: per Char window — radio
                                            -- chassis zones stamped during
                                            -- render, picked up next frame.
                 win._activeTab == "vehicle"  -- S124: Vehicle tab zones stamped during render
               ) then
            -- S98 per-frame refresh for NON-Loot World tabs. _forageStanceZones
            -- and _animalsSubmodeZones are populated by ForagingTab / AnimalsTab
            -- renderers each frame. _syncWorldRingZones fires on tab switch
            -- BEFORE the new tab's renderer runs, so it reads empty tables.
            -- This catch-up keeps worldTabContent in sync with live data.
            local newEls = _buildWorldPanelFocusables(win, self, win._activeTab) or {}
            local snap   = win._lastTabContentSnapshot
            local oldN   = snap and snap.n or -1
            local oldTab = snap and snap.tab or nil
            local newN   = #newEls
            local dirty  = (oldTab ~= win._activeTab) or (oldN ~= newN)
            if not dirty and newN > 0 and snap then
                dirty = (snap.firstId ~= newEls[1].id)
                     or (snap.lastId  ~= newEls[newN].id)
            end
            -- S107 QA: pending card-jump after recipe selection. CC.buildFocusables
            -- recipeRow onActivate sets state._gpPendingCardJump after openCraft.
            -- Card pane renders via split animation over a few frames; once the
            -- first cardSection / action_build element is stamped, jump focus
            -- there and clear the flag. Runs BEFORE the dirty-check so a forced
            -- seedIdx is honored even when the element list signature is stable.
            local pendingState = nil
            if win._activeTab == "craft" then pendingState = win._craftState
            elseif win._activeTab == "build" then pendingState = win._buildState end
            local cardJumpIdx = nil
            if pendingState and pendingState._gpPendingCardJump then
                -- Prefer the action_build button (the actual CRAFT/BUILD target)
                -- so A immediately fires the start action. Fall back to the
                -- first cardSection if the action strip hasn't stamped yet
                -- (first frame after openCraft — split animation still ramping
                -- splitFrac from 0; renderCraftCard skips when cardW == 0).
                for i, e in ipairs(newEls) do
                    if e.craftKind == "actBuild" then
                        cardJumpIdx = i; break
                    end
                end
                if not cardJumpIdx then
                    for i, e in ipairs(newEls) do
                        if e.craftKind == "cardSection" then
                            cardJumpIdx = i; break
                        end
                    end
                end
                if cardJumpIdx then
                    pendingState._gpPendingCardJump = false
                end
            end

            -- S107 QA: craft + build always rebuild (scroll shifts recipeRow
            -- screen-y each frame; stale focusable coords break cone-nav
            -- until the next dirty-fire). Other tabs keep the dirty-gate.
            -- S123 perf: Craft (541 rows) and Build (77) register every recipe
            -- row; the always-rebuild cost ~2.5 ms a frame on Craft. Key the
            -- rebuild on scroll position, list geometry and dropdown state.
            local scrollKey = nil
            do
                local stk = (win._activeTab == "craft" and win._craftState)
                         or (win._activeTab == "build" and win._buildState) or nil
                if stk then
                    local sp = stk.scroll and stk.scroll.scrollPos or 0
                    local lg = stk._listGeo
                    scrollKey = tostring(sp) .. ":" .. tostring(lg and lg.y or 0) .. ":" .. tostring(lg and lg.h or 0)
                        .. ":" .. tostring(stk.catDropdownOpen) .. ":" .. tostring(stk.catDropdownScroll or 0)
                    if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
                end
            end
            if win._activeTab == "vehicle" and ZeD.MechanicsTab and ZeD.MechanicsTab.focusKey then
                scrollKey = ZeD.MechanicsTab.focusKey(win)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            local alwaysRebuild = false

            -- S107 QA: identity-preserve focus by element id. When the
            -- focusables array churns (scroll + always-rebuild, filter
            -- change, dropdown open/close) the focused element's array
            -- index may shift — without preservation, focus would jump to a
            -- different element at the same index. Look up the old focused
            -- id in the new list.
            local preserveIdx = cardJumpIdx
            if not preserveIdx then
                local oldZ = nil
                for _, z in ipairs(win._focusRing) do
                    if z.zone == "worldTabContent" then oldZ = z; break end
                end
                local oldEl = oldZ and oldZ.elements and oldZ.elements[oldZ.focusedElementIdx or 1]
                local oldId = oldEl and oldEl.id or nil
                if oldId then
                    for i, e in ipairs(newEls) do
                        if e.id == oldId then preserveIdx = i; break end
                    end
                end
            end
            -- S109a: post-create-zone focus hint. gpConfirm seeds
            -- win._animalsFocusAfterCreate with the zone name; we resolve
            -- that to a zonecard idx so the new zone lands focused instead
            -- of the ranch submode pill (which otherwise wins via idx-1 clamp).
            if win._activeTab == "animals" and win._animalsFocusAfterCreate then
                for i, e in ipairs(newEls) do
                    if e.isZoneCard and e.zoneName == win._animalsFocusAfterCreate then
                        preserveIdx = i
                        break
                    end
                end
                win._animalsFocusAfterCreate = nil
            end
            -- S109a: navigation focus target. Zonecard/roster/butcher
            -- onActivate sets this to "breadcrumb" so the user lands on the
            -- back-nav element in the new view, not whatever idx-clamp
            -- picks (e.g. sort btn at idx 4 for idx-4 zonecard sources).
            if win._activeTab == "animals" and win._animalsNavFocusTarget then
                local target = win._animalsNavFocusTarget
                for i, e in ipairs(newEls) do
                    if target == "breadcrumb" and e.isBreadcrumb then
                        preserveIdx = i
                        break
                    end
                end
                win._animalsNavFocusTarget = nil
            end

            if win._activeTab == "vehicle" and win._mechFocusTarget and ZeD.MechanicsTab.focusTargetIndex then
                local ti = ZeD.MechanicsTab.focusTargetIndex(win, newEls)
                if ti then preserveIdx = ti; cardJumpIdx = ti end
            end
            if dirty or alwaysRebuild or cardJumpIdx then
                win._lastTabContentSnapshot = {
                    tab     = win._activeTab,
                    scrollKey = scrollKey,
                    n       = newN,
                    firstId = newEls[1] and newEls[1].id or nil,
                    lastId  = newEls[newN] and newEls[newN].id or nil,
                }
                Focus.setRingZoneElements(win, "worldTabContent", newEls, preserveIdx)
                Focus.setZoneFocusable   (win, "worldTabContent", newN > 0)
                -- On card-jump, fire onFocus so any cue-paint / state-
                -- mirroring the landed element does is fresh this frame.
                if cardJumpIdx then
                    local landed = newEls[cardJumpIdx]
                    if landed and landed.onFocus then
                        local ok, err = pcall(landed.onFocus, win, landed)
                        if not ok then
                            print("[ZeD] world cardJump onFocus failed: " .. tostring(err))
                        end
                    end
                end
            end
        end

        -- S99 per-frame refresh for worldItemCard zone. Mirrors Character
        -- window's charItemCard refresh: the card's toggleRects / verbRects
        -- are stamped by render each frame; this picks them up into the ring.
        -- Focusable state tracks card visibility (`_drawerItem ~= nil`), NOT
        -- `_drawerMode`. On non-Loot tabs the card overlays the tab drawer
        -- while `_drawerMode` stays "tab" — the card is still interactive.
        if Focus and win._focusRing then
            local cardVisible = (win._drawerItem ~= nil)
            local cardEls = cardVisible and _buildWorldCardActionFocusables(win) or {}
            Focus.setRingZoneElements(win, "worldItemCard", cardEls)
            Focus.setZoneFocusable   (win, "worldItemCard", cardVisible and #cardEls > 0)
        end

        -- Active tab name → right-side stats when drawer is open
        if win._drawerOpen and win._drawerMode == "tab" and win._activeTab then
            for _, tab in ipairs(WORLD_TABS) do
                if tab.id == win._activeTab then
                    win.titleStats = {
                        {text = tab.label, color = T.textSec},
                    }
                    break
                end
            end
        else
            win.titleStats = {}
        end
    end

    -- Draw drag ghost at window level
    local _baseWinRender = win.render
    win.render = function(self)
        _baseWinRender(self)
        if content._drag and content._drag:isActive() then
            content._drag:drawGhost(self)
        end
        -- 1px vertical divider between drawer and inventory (top Z, after
        -- all children). S103: skip when windowshaded so the line doesn't
        -- bleed into the collapsed title-bar view (mirrors Character fix).
        if win._dividerX and not self.windowShaded then
            local T = ZeD.T
            local brd = T.border
            self:drawRect(win._dividerX, 0, T.px(1), self:getHeight(), 1, brd.r, brd.g, brd.b)
        end
    end

    -- ----------------------------------------------------------------
    -- FLOOR-AWARE TRANSFER — _floorContainer is virtual (no IsoObject),
    -- so ISInventoryTransferAction can't use it directly.
    --   TO floor   → ISInventoryPaneContextMenu.dropItem()
    --   FROM floor → use saved real container (per-square) as source
    --   Otherwise  → normal ISInventoryTransferAction
    -- ----------------------------------------------------------------
    local function doTransfer(contentPanel, items, srcInv, destInv)
        local playerObj = contentPanel._playerObj
        local playerNum = playerObj:getPlayerNum()
        local srcIsFloor  = (srcInv == _floorContainer)
        local destIsFloor = (destInv == _floorContainer)

        for _, item in ipairs(items) do
            if destIsFloor then
                if not item:isFavorite() then
                    ISInventoryPaneContextMenu.dropItem(item, playerNum)
                end
            elseif srcIsFloor then
                -- _floorContainer is virtual (no IsoObject parent) — ISInventoryTransferAction
                -- can't validate it.  Mirror vanilla ISGrabItemAction:transferItem instead:
                -- remove the IsoWorldInventoryObject from the square, then AddItem to dest.
                local worldItem = item:getWorldItem()
                if worldItem and destInv:isItemAllowed(item) and destInv:hasRoomFor(playerObj, item) then
                    local sq = worldItem:getSquare()
                    if sq then
                        sq:transmitRemoveItemFromSquare(worldItem)
                        worldItem:removeFromWorld()
                        worldItem:removeFromSquare()
                        worldItem:setSquare(nil)
                    end
                    item:setWorldItem(nil)
                    item:setJobDelta(0.0)
                    destInv:AddItem(item)
                    destInv:setDrawDirty(true)
                    _floorRealContainers[item] = nil
                end
            else
                if item:getContainer() == srcInv and destInv:isItemAllowed(item) then
                    ISTimedActionQueue.add(
                        ISInventoryTransferAction:new(playerObj, item, srcInv, destInv, 0)
                    )
                end
            end
        end
    end

    -- ----------------------------------------------------------------
    -- STRIP-DROP HELPER — transfer items dropped on container strip
    -- ----------------------------------------------------------------
    local function tryStripDrop(contentPanel, items, srcInv)
        local strip = win._containerStrip
        if not strip or not strip:isMouseOver() then return false end
        local smx, smy = strip:getMouseX(), strip:getMouseY()
        local zone = strip:hitZoneAt(smx, smy)
        if not zone or type(zone.id) ~= "number" then return false end
        local cnt = win._containers[zone.id]
        if not cnt or cnt.locked then return false end
        local destContainer = cnt.inventory
        local srcContainer = srcInv or contentPanel._inventory
        if not destContainer or destContainer == srcContainer then return false end
        doTransfer(contentPanel, items, srcContainer, destContainer)
        return true
    end

    -- ----------------------------------------------------------------
    -- FLOOR-COLUMN HELPER — intercept MC drops involving floor column
    -- ----------------------------------------------------------------
    local function tryFloorTransfer(contentPanel, items, srcInv)
        local colStates = contentPanel._colStates
        if not colStates then return false end
        local mx = contentPanel:getMouseX()
        local _, dropCs = getColumnAtX(contentPanel, mx)
        if not dropCs then return false end
        local destInv = dropCs.inventory
        local srcContainer = srcInv or contentPanel._inventory
        if not destInv or destInv == srcContainer then return false end
        local srcIsFloor  = (srcContainer == _floorContainer)
        local destIsFloor = (destInv == _floorContainer)
        if not srcIsFloor and not destIsFloor then return false end
        doTransfer(contentPanel, items, srcContainer, destInv)
        return true
    end

    -- ----------------------------------------------------------------
    -- MOUSE HANDLERS
    -- ----------------------------------------------------------------
    local scrollW = T.sp.scrollbarW
    local countSelected        = r.countSelected
    local findIndex            = r.findIndex
    local collectSelectedItems = r.collectSelectedItems
    local handleDrop           = r.handleDrop

    content.onMouseDown = function(self, x, y)
        -- MC column-aware scrollbar check
        if #(win._mcSelected or {}) > 0 and self._colStates then
            for _, cs in ipairs(self._colStates) do
                if cs.scroll and cs.scroll.visible
                   and x >= cs.scroll.x and x < cs.scroll.x + cs.scroll.width
                   and y >= cs.scroll.y then
                    cs.scroll:handleMouseDown(y - cs.scroll.y)
                    self._activeScroll = cs.scroll
                    return true
                end
            end
        elseif self._scroll.visible
           and x >= self._scroll.x and x < self._scroll.x + self._scroll.width then
            self._scroll:handleMouseDown(y - self._scroll.y)
            return true
        end

        local zone = self:hitZoneAt(x, y)
        if not zone then return true end
        local zid = zone.id

        -- XFER button click (multi-container transfer)
        if type(zid) == "string" and zid:sub(1, 5) == "xfer:" then
            local targetColIdx = tonumber(zid:sub(6))
            local colStates = self._colStates or {}
            local srcCol = self._activeCol or #colStates
            local srcCs = colStates[srcCol]
            local dstCs = colStates[targetColIdx]
            if srcCs and dstCs and srcCs ~= dstCs then
                local items = {}
                for item, _ in pairs(srcCs.selectedItems) do
                    items[#items + 1] = item
                end
                if #items > 0 then
                    handleDrop(self, items, srcCs.inventory)
                    srcCs.selectedItems = {}
                    srcCs.lastClickedItem = nil
                end
            end
            return true
        end

        -- Column divider drag
        if type(zid) == "string" and zid:sub(1, 4) == "div:" then
            local col = zid:sub(5)
            local colW = self._colWidths
            if colW and colW[col] then
                self._colDrag = {
                    col    = col,
                    startX = getMouseX(),
                    startW = colW[col],
                }
                self:setCapture(true)
            end
            return true
        end

        -- Column header sort (column-aware)
        if type(zid) == "string" and zid:sub(1, 4) == "hdr:" then
            local col = zid:sub(5)
            local hdrColIdx, hdrCs = getColumnAtX(self, x)
            if hdrCs then
                if hdrCs.sortCol == col then
                    hdrCs.sortAsc = not hdrCs.sortAsc
                else
                    hdrCs.sortCol = col
                    hdrCs.sortAsc = true
                end
                hdrCs.scroll:setScrollPos(0)
            else
                if self._sortCol == col then
                    self._sortAsc = not self._sortAsc
                else
                    self._sortCol = col
                    self._sortAsc = true
                end
                self._scroll:setScrollPos(0)
            end
            return true
        end

        -- Category collapse (column-aware)
        if type(zid) == "string" and zid:sub(1, 4) == "cat:" then
            local cat = zid:sub(5)
            local catColIdx, catCs = getColumnAtX(self, x)
            local collapsed = (catCs and catCs.collapsedGroups) or self._collapsedGroups
            if collapsed[cat] then
                collapsed[cat] = nil
            else
                collapsed[cat] = true
            end
            return true
        end

        -- S100: stack chevron toggle
        if type(zid) == "string" and zid:sub(1, 6) == "stack:" then
            local key = zid:sub(7)
            local stkColIdx, stkCs = getColumnAtX(self, x)
            local exp = (stkCs and stkCs.expandedStacks) or self._expandedStacks
            if exp then
                exp[key] = not exp[key]
            end
            return true
        end

        local item = zid
        if type(item) == "string" then return true end  -- not an item

        local screenX, screenY = getMouseX(), getMouseY()
        self._deferredSelect = nil

        -- Determine which column this item is in
        local colIdx, colCs = getColumnAtX(self, x)
        local sel, lastClicked, flatItems
        if colCs then
            sel = colCs.selectedItems
            lastClicked = colCs.lastClickedItem
            flatItems = colCs.flatItems
            self._dragSourceCol = colIdx
            self._dragSourceInv = colCs.inventory
            self._activeCol = colIdx
        else
            sel = self._selectedItems
            lastClicked = self._lastClickedItem
            flatItems = self._flatItems
            self._dragSourceCol = nil
            self._dragSourceInv = self._inventory
        end

        local isCtrl  = isKeyDown(Keyboard.KEY_LCONTROL) or isKeyDown(Keyboard.KEY_RCONTROL)
        local isShift = isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT)

        if isCtrl then
            if sel[item] then sel[item] = nil
            else sel[item] = true end
            if colCs then colCs.lastClickedItem = item
            else self._lastClickedItem = item end
            local dragItems = {}
            for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
            if #dragItems > 0 then
                self._drag:beginPending(dragItems, dragItems[1], screenX, screenY)
            end

        elseif isShift and lastClicked then
            local fromIdx = findIndex(flatItems, lastClicked)
            local toIdx   = findIndex(flatItems, item)
            if fromIdx and toIdx then
                local lo = math.min(fromIdx, toIdx)
                local hi = math.max(fromIdx, toIdx)
                for i = lo, hi do
                    sel[flatItems[i]] = true
                end
            end
            local dragItems = {}
            for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
            if #dragItems > 0 then
                self._drag:beginPending(dragItems, item, screenX, screenY)
            end

        else
            if sel[item] then
                self._deferredSelect = { item = item, colIdx = colIdx }
                local dragItems = {}
                for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
                self._drag:beginPending(dragItems, item, screenX, screenY)
            else
                for k in pairs(sel) do sel[k] = nil end
                sel[item] = true
                if colCs then colCs.lastClickedItem = item
                else self._lastClickedItem = item end
                self._drag:beginPending({item}, item, screenX, screenY)
            end
        end

        -- Sync column selection back for updateDrawer compatibility
        if colCs then
            self._selectedItems = sel
            self._lastClickedItem = colCs.lastClickedItem
        end

        if not self._deferredSelect then
            updateDrawer()
        end

        return true
    end

    content.onMouseUp = function(self, x, y)
        -- Release active scroll (MC column scroll)
        if self._activeScroll then
            self._activeScroll:handleMouseUp()
            self._activeScroll = nil
        end
        self._scroll:handleMouseUp()

        -- Column divider drag finalize
        if self._colDrag then
            self._colDrag = nil
            self:setCapture(false)
            return true
        end

        if self._drag:isActive() then
            local items = self._drag:complete()
            if not tryStripDrop(self, items, self._dragSourceInv)
               and not tryFloorTransfer(self, items, self._dragSourceInv) then
                handleDrop(self, items, self._dragSourceInv)
            end
            self:setCapture(false)
            self._deferredSelect = nil
            self._dragSourceCol = nil
            self._dragSourceInv = nil
            updateDrawer()
            return true
        end

        if self._drag:isPending() then
            self._drag:cancel()
        end

        if self._deferredSelect then
            local def = self._deferredSelect
            self._deferredSelect = nil
            local item = def.item or def
            local colIdx = type(def) == "table" and def.colIdx or nil
            local sel = self._selectedItems

            if colIdx and self._colStates and self._colStates[colIdx] then
                sel = self._colStates[colIdx].selectedItems
            end

            if sel[item] and countSelected(sel) == 1 then
                for k in pairs(sel) do sel[k] = nil end
                if colIdx and self._colStates and self._colStates[colIdx] then
                    self._colStates[colIdx].lastClickedItem = nil
                else
                    self._lastClickedItem = nil
                end
            else
                for k in pairs(sel) do sel[k] = nil end
                sel[item] = true
                if colIdx and self._colStates and self._colStates[colIdx] then
                    self._colStates[colIdx].lastClickedItem = item
                else
                    self._lastClickedItem = item
                end
            end
            self._selectedItems = sel
        end

        self._dragSourceCol = nil
        self._dragSourceInv = nil
        updateDrawer()
        return true
    end

    content.onMouseUpOutside = function(self, x, y)
        if self._colDrag then
            self._colDrag = nil
            self:setCapture(false)
            return true
        end
        if self._drag:isActive() then
            local items = self._drag:complete()
            if not tryStripDrop(self, items, self._dragSourceInv)
               and not tryFloorTransfer(self, items, self._dragSourceInv) then
                handleDrop(self, items, self._dragSourceInv)
            end
            self:setCapture(false)
            self._deferredSelect = nil
            self._dragSourceCol = nil
            self._dragSourceInv = nil
            return true
        end
        if self._drag:isPending() then
            self._drag:cancel()
        end
        self._deferredSelect = nil
        self._dragSourceCol = nil
        self._dragSourceInv = nil
        return true
    end

    content.onMouseMove = function(self, dx, dy)
        ISPanel.onMouseMove(self, dx, dy)
        local T = ZeD.T
        self._scroll:handleMouseMove(self:getMouseY())

        -- Column divider drag
        if self._colDrag then
            local cd = self._colDrag
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW - delta))
            self._colWidths[cd.col] = newW
            return true
        end

        if self._drag:isPending() then
            if self._drag:checkThreshold(getMouseX(), getMouseY()) then
                self:setCapture(true)
                self._deferredSelect = nil
                win._drawerItem = nil  -- hide item card on drag
            end
        elseif self._drag:isActive() then
            self._drag:updateGhostPos(getMouseX(), getMouseY())
        end

        return true
    end

    content.onMouseMoveOutside = function(self, dx, dy)
        local T = ZeD.T
        if self._colDrag then
            local cd = self._colDrag
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW - delta))
            self._colWidths[cd.col] = newW
            return true
        end
        if self._drag:isActive() then
            self._drag:updateGhostPos(getMouseX(), getMouseY())
        end
        return true
    end

    content.onMouseWheel = function(self, del)
        -- MC: scroll the column under mouse
        if #(win._mcSelected or {}) > 0 and self._colStates then
            local mx = self:getMouseX()
            local colIdx, colCs = getColumnAtX(self, mx)
            if colCs and colCs.scroll and colCs.scroll.visible then
                local step = 0.05
                colCs.scroll:setScrollPos(colCs.scroll.scrollPos + del * step)
                return true
            end
        end
        if self._scroll and self._scroll.visible then
            local step = 0.05
            self._scroll:setScrollPos(self._scroll.scrollPos + del * step)
            return true
        end
        return false
    end

    content.onRightMouseDown = function(self, x, y)
        if self._drag:isActive() or self._drag:isPending() then
            self._drag:cancel()
            self:setCapture(false)
            self._deferredSelect = nil
            return true
        end
        return true
    end

    content.onRightMouseUp = function(self, x, y)
        if self._drag:isActive() or self._drag:isPending() then return true end

        local colIdx, colCs = getColumnAtX(self, x)
        local sel = (colCs and colCs.selectedItems) or self._selectedItems
        local inv = (colCs and colCs.inventory) or self._inventory

        -- Build context menu items: use current selection, or the clicked item transiently
        -- Don't change the persistent selection — RMB is context menu only
        local zone = self:hitZoneAt(x, y)
        local menuItems = {}
        local hasSelection = false
        for _ in pairs(sel) do hasSelection = true; break end

        if hasSelection then
            -- Use existing selection for context menu
            for item, _ in pairs(sel) do menuItems[#menuItems + 1] = item end
        elseif zone and type(zone.id) == "string" and zone.id:sub(1, 6) == "stack:" then
            -- S100: right-click on stack chevron → target the full stack
            local key = zone.id:sub(7)
            local stacksTbl = (colCs and colCs.stacks) or self._stacks
            local stk
            for _, info in pairs(stacksTbl or {}) do
                if info and info.key == key then stk = info; break end
            end
            if stk and stk.items then
                for _, it in ipairs(stk.items) do
                    menuItems[#menuItems + 1] = it
                end
            end
        elseif zone and type(zone.id) ~= "string" then
            -- S100: if this item is a stack rep, target the full stack
            local stacksTbl = (colCs and colCs.stacks) or self._stacks
            local stk = stacksTbl and stacksTbl[zone.id]
            if stk and stk.count > 1 then
                for _, it in ipairs(stk.items) do
                    menuItems[#menuItems + 1] = it
                end
            else
                menuItems[#menuItems + 1] = zone.id
            end
        end

        if #menuItems == 0 then return true end

        local playerNum = self._playerObj:getPlayerNum()
        local isInInv = inv:isInCharacterInventory(self._playerObj)
        ISInventoryPaneContextMenu.createMenu(
            playerNum, isInInv, menuItems,
            self:getAbsoluteX() + x, self:getAbsoluteY() + y
        )
        return true
    end

    content.onRightMouseDownOutside = function(self, x, y)
        if self._drag:isActive() or self._drag:isPending() then
            self._drag:cancel()
            self:setCapture(false)
            self._deferredSelect = nil
            return true
        end
        return true
    end

    -- Base prerender (shaded guard only — drawer._onPrerender handles all layout)
    local origPrerender = win.prerender
    win.prerender = function(self)
        origPrerender(self)
    end
end


-- ============================================================================
-- PUBLIC API (called from ZeD_CharacterWindow for keybind pairing)
-- ============================================================================

function ZeD_WorldWindow.open(playerNum)
    if not _worldWin then
        ZeD_WorldWindow.toggle(playerNum)
    end
end

function ZeD_WorldWindow.close()
    if _worldWin then
        saveWorldState(_worldWin)
        -- S93 Layer 3: drop joypad focus before teardown. This public module
        -- function is reached when the Character Window close path calls
        -- ZeD_WorldWindow.close() for paired close semantics — having the
        -- unregister here keeps this entry point symmetric with the toggle()
        -- and win.close override paths.
        if ZeD and ZeD.Input and ZeD.Input.Focus then
            if ZeD.MapsTab and ZeD.MapsTab.closePopout then ZeD.MapsTab.closePopout(_worldWin) end  -- S123: fold the map pop-out with the window
            ZeD.Input.Focus.unregisterWindow(_worldWin)
        end
        _worldWin:removeFromUIManager()
        _worldWin = nil
        _floorContainer = nil
    end
end

-- Save state on game save
Events.OnPostSave.Add(function()
    if _worldWin then saveWorldState(_worldWin) end
end)
