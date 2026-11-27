-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WorldWindow.lua
-- ============================================================================
-- WORLD WINDOW — "the world and its stuff". Client; organism: a plain
-- ZeD_Window shell with ZeD_Panel panes, the Character window's mirror.
-- Container strip LEFT, item list CENTER, drawer RIGHT, action tabs RIGHT
-- EDGE. On the Loot tab a click on a strip container opens it as a column
-- beside the others (MC: multi-container); XFER strips and cross-column
-- drag-drop move items.
--
-- toggle() builds the whole window on every open, and its panes' handlers are
-- closures inside that one call. Overrides nothing in ISInventoryPage, and
-- never registers with Java's UIManager (that pairing can't be undone from
-- Lua) — vanilla's loot page is hidden behind this window instead.
-- ============================================================================

require "ISUI/ISPanel"
require "ISUI/ISMouseDrag"
require "ISUI/ISInventoryPage"
require "ZeD/WindowCurtain"
require "ZeD/WindowHalves"
require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_Panel"
require "ZeD/SafeMode"
require "ZeD/ZeD_TabPx"
require "ZeD/ObjectCards"
require "ZeD/InventoryRenderer"
require "ZeD/ItemCard"
require "ZeD/CraftingTab"
require "ZeD/BuildingTab"
require "ZeD/MapsTab"
require "ZeD/ForagingTab"
require "ZeD/AnimalsTab"
require "ZeD/RadioTab"
require "ZeD/MechanicsTab"
require "ZeD/FurnitureTab"
require "ZeD/ExtraContainers"
require "ZeD/StripDecorators"
require "ZeD/ContainerGates"

ZeD = ZeD or {}
ZeD_WorldWindow = {}

-- The shared list renderer (ZeD.InventoryRenderer), cached on first use
local R = nil
local function getR()
    if not R then R = ZeD.InventoryRenderer end
    return R
end

-- ============================================================================
-- CONSTANTS
-- Every constant below is a DESIGN UNIT (1 px at 1080p). Each use goes
-- through T.px(...) at call time; never add them to screen px unwrapped.
-- ============================================================================

local CONTAINER_STRIP_W    = 36
local CONTAINER_BTN_SZ     = 36
-- The container list's refresh, in ms: every `ms` (what 30 frames are at 60 fps, but on the clock);
-- a new square or a container change no sooner than `soonMs` after the last; the radios and vehicles with their tab
-- closed every `sideMs`; `phaseMs` after the window opens, so it does not fall on the Character window's
local WREF = { ms = 500, soonMs = 200, sideMs = 1000, phaseMs = 250 }
local STRIP_SCROLL_ROW_H   = 16
-- The drawer is one of two widths and no other — a full card and a half card;
-- a third width bumps the cards into each other. ITEM_CARD_W is the half card: the item card is drawn at it,
-- and DRAWER_W (the width a small window steps down to) is the same number. TAB_DRAWER_W and
-- OBJECT_CARD_W are the full card.
local ITEM_CARD_W          = 220
local DRAWER_W             = ITEM_CARD_W
local TAB_DRAWER_W         = 480
-- The inventory's minimum width beside an open full card (the same number and
-- reasons as ZeD_CharacterWindow's INV_MIN_BESIDE_CARD): alone the inventory keeps 200
-- units, beside a full card it gives way down to 180 before the tab drops to the half card.
local INV_MIN_BESIDE_CARD  = 180
local OBJECT_CARD_W        = 480   -- object cards (generator, fires, farm plots)
local DRAWER_PX_SPEED      = 260 * 8   -- ~2080 design units/sec, matches char window; scaled at use (T.px(DRAWER_PX_SPEED) * dt)
local ACTION_TAB_STRIP_W   = 36
-- (a tab's cell is row 1's height, ZeD.T.stripH, so the top tab's line runs on the header's: punch list 178)
-- Tab strip separator (matches CharacterWindow). Declared this early because
-- _buildWorldTabBarElements reads them — in Kahlua a closure captures a local
-- declared below it as nil.
local TAB_SEP_H            = 0   -- separator off: the tab borders already divide them
local TAB_SEP_MAR          = 0

-- The Loot view has no tab drawer of its own (the director, Nov 10 2026: the "Coming soon" half card goes). When
-- the Loot tab is shown with the drawer in tab mode (a context tab hid while open, a restored state, a script),
-- the drawer becomes what is left in it: the item card, the object card, the extra columns, or nothing, folded.
local function lootDrawerFallback(win)
    if not win or win._activeTab ~= "loot" or win._drawerMode ~= "tab" then return end
    win._tabUnder = nil
    if win._drawerItem then win._drawerMode = "item"; win._drawerOpen = true
    elseif win._drawerObject then win._drawerMode = "object"; win._drawerOpen = true
    else
        win._drawerMode = nil
        win._drawerOpen = #(win._mcSelected or {}) > 0
    end
end

-- Drop the object card from the drawer. Declared above all its consumers
-- (tab switches, MC entry, item selection, the public close).
local function dropObjectCard(win, why)
    if not win or not win._drawerObject then return end
    -- (Nov 15 2026, QA's beta 16 pass, p336: the grill's card closed under the test with no word why; each drop now
    -- says which path took it, one line per close, not per frame)
    print("[ZeD] WorldWindow: object card dropped (" .. tostring(why or ZeD_WorldWindow._closeWhy or "?") .. ")")
    ZeD_WorldWindow._closeWhy = nil
    -- a pinned card (the trade) stays through tab switches, item cards and the
    -- like; only its own close (closeObjectCard: the close key, B, Cancel) takes it away
    local pd = win._drawerObject.def
    if pd and pd.pinned and not win._forceDrop then
        local okP, pin = pcall(pd.pinned, win._drawerObject.t)
        if okP and pin then return end
    end
    win._drawerObject = nil
    if win._objectCard then win._objectCard:setEntry(nil) end
    if win._drawerMode == "object" then
        win._drawerMode = nil
        win._drawerOpen = #(win._mcSelected or {}) > 0
    end
end

-- Action tab definitions — group 1 the core tabs, group 2 the world-state
-- pages (some only visible in context)
local WORLD_TABS = {
    -- key = ZeD's word for the tab, vkey = vanilla's own where it has the same word; the
    -- tab's name is read where it is shown (ZeD_WorldWindow.tabLabel), so the language applies
    { id = "loot",   key = "UI_ZeD_World_TabLoot", group = 1, glyph = "L", iconName = "loot-tab-white" },
    { id = "craft",  vkey = "IGUI_CraftingWindow_Title", group = 1, glyph = "C", iconName = "craft-tab-white" },
    { id = "build",  key = "UI_ZeD_World_TabBuilding", group = 1, glyph = "B", iconName = "build-tab-white" },
    -- Furniture — vanilla's moveables mode (pick up, place, rotate,
    -- disassemble, repair); opening the tab starts the furniture cursor (ZeD.FurnitureTab)
    { id = "furniture", vkey = "IGUI_CraftingCategories_Furniture", group = 1, glyph = "U", iconName = "move-tab-white" },
    { id = "maps",   key = "UI_ZeD_World_TabMaps", group = 2, glyph = "M", iconName = "map-tab-white" },
    { id = "forage", vkey = "IGUI_ScavengeUI_Title", group = 2, glyph = "F", iconName = "forage-tab-white",
      visible = function(win) return true end },  -- always visible (informational surface)
    { id = "animals", key = "UI_ZeD_World_TabAnimals", group = 2, glyph = "A", iconName = "farm-tab-white" },
    -- Radio (contextual) — visible when at least one IsoWaveSignal radio
    -- is reachable in the player's 3x3 grid. Same predicate model as Foraging.
    { id = "radio",  vkey = "IGUI_ItemType_Radio", group = 2, glyph = "R",
      iconName = "radio-tab-white",
      -- (Nov 14 2026, punch list 216: "Follow what's open": while the device showing on the tab is a TV set the tab
      -- reads Television with the TV icon, its strip picture, its help, the title and the wheel's slice alike;
      -- ZeD.RadioTab.showingTV picks the one showing when both a radio and a TV are in reach)
      tv = { key = "UI_ZeD_World_TabTelevision", px = "tv", iconName = "tv-tab-white" },
      isTV = function(win, list)
          return ZeD.RadioTab ~= nil and ZeD.RadioTab.showingTV ~= nil and ZeD.RadioTab.showingTV(win, list) == true
      end,
      visible = function(win)
          return win and win._radios and #win._radios > 0
      end },
    -- Vehicle (contextual) — vehicle mechanics. Visible while a vehicle is
    -- within reach or an inspected one is within six tiles (ZeD.MechanicsTab).
    { id = "vehicle", key = "UI_ZeD_World_TabVehicle", group = 2, glyph = "V",
      iconName = "vehicle-tab-white",
      visible = function(win)
          return ZeD.MechanicsTab and ZeD.MechanicsTab.isVisible(win)
      end },
}

--- A tab's name in the player's language: its label() if it has one, else
--- vanilla's word (vkey), else ZeD's (key). The D-pad wheels read it too.
--- win (optional), list (optional, the wheel's fresh radio list): a tab that follows what is open on it names that
--- (the Radio tab with a TV showing: Television; Nov 14 2026, punch list 216).
function ZeD_WorldWindow.tabLabel(tab, win, list)
    if tab.tv and (win or list) and tab.isTV(win, list) then return ZeD.tr(tab.tv.key) end
    if tab.label then return tab.label() end
    if tab.vkey then return getText(tab.vkey) end
    return ZeD.tr(tab.key)
end

--- A tab's lit strip picture (ZeD.TabPx id) and its wheel icon name (W.TAB_ICONS key): its own, or the TV's while a
--- TV set shows on the Radio tab (Nov 14 2026, punch list 216).
function ZeD_WorldWindow.tabIcon(tab, win, list)
    if tab.tv and (win or list) and tab.isTV(win, list) then return tab.tv.px, tab.tv.iconName end
    return tab.id, tab.iconName
end

-- The title: the container's name (win._titleBase, set by the inventory side), then the
-- open tab ("Crate  +  Craft"), as the character window does. Built every frame from the
-- window's own prerender — built from the inventory side's prerender it went
-- stale while the tab drawer took the whole window. A rolled side's
-- title is the curtain's (WindowCurtain: the tab alone). Kept until a part changes.
local function composeWorldTitle(win)
    if win._rolled then return end
    local base = win._titleBase or ZeD.tr("UI_ZeD_World_Title")
    local sub = nil
    -- (a tab drawer rolled in by its half keeps its tab in the title, WindowHalves)
    local tabId = (win._drawerOpen and win._drawerMode == "tab" and win._activeTab) or ZeD.Halves.foldedTab(win)
    if tabId then
        for _, tab in ipairs(WORLD_TABS) do
            if tab.id == tabId then
                sub = ZeD_WorldWindow.tabLabel(tab, win)
                break
            end
        end
    end
    if win._ttOut == nil or sub ~= win._ttSub or base ~= win._ttBase then
        win._ttSub, win._ttBase = sub, base
        win._ttOut = sub and (base .. "  +  " .. sub) or base
    end
    win.title = win._ttOut
end

-- Check if a tab is visible (tabs without a visible predicate are always shown)
local function isTabVisible(tab, win)
    if not tab.visible then return true end
    return tab.visible(win)
end
-- A tab another file adds (the Admin tab, AdminTab.lua), as ZeD_CharacterWindow.addTab: def = id, key or
-- label(), group, iconName, after (a tab id), visible(win), render(panel, win, x, y, w, h), and optionally
-- scroll(win), onClick(win, x, y), buildFocusables(win), scrollKey(win), drawerW. Read at run time from
-- ZeD_WorldWindow._extTabs by the window's per-tab dispatch (focus, click, scroll, the focus refresh).
ZeD_WorldWindow._extTabs = ZeD_WorldWindow._extTabs or {}
ZeD_WorldWindow._extPending = ZeD_WorldWindow._extPending or {}

-- The animal each tab stop shows, in order (false for a stop with none): a roster scrolled by whole rows keeps
-- its stops' count, ids and places, so the animals key the ring's rebuild too (a pad X after a mouse scroll
-- ticked the animal the row showed before the scroll).
function ZeD_WorldWindow._tabSnapAnimals(els)
    local out = {}
    for i = 1, #els do out[i] = els[i].animal or false end
    return out
end
--- Whether the tab's stops differ from the last snapshot (the ring is rebuilt then): another tab, another count,
--- other first or last stops, the last one moved or resized, or another animal on any stop.
function ZeD_WorldWindow._tabSnapDirty(snap, tab, els)
    local n = #els
    if not snap or snap.tab ~= tab or snap.n ~= n then return true end
    if n == 0 then return false end
    if snap.firstId ~= els[1].id or snap.lastId ~= els[n].id
        or snap.lastY ~= els[n].y or snap.lastH ~= els[n].h then return true end   -- (the stops move when the tab
    local an = snap.animals                                                         -- scrolls or resizes)
    for i = 1, n do
        if ((an and an[i]) or false) ~= (els[i].animal or false) then return true end
    end
    return false
end
-- the tabs and the test, for the D-pad wheels' Tabs slice (ZeD_DpadWheels.lua)
ZeD_WorldWindow.TABS = WORLD_TABS
ZeD_WorldWindow.isTabVisible = isTabVisible

-- ============================================================================
-- GAMEPAD FOCUS SUPPORT (World Window)
-- Mirrors ZeD_CharacterWindow's pattern: every controller stop is an element
-- in a ring zone (tab bar, container strip, main list, the columns, the tab's
-- content, the item card). The builders below stamp those elements from the
-- places things last drew.
--
-- Ordering note: placed AFTER isTabVisible so `_buildWorldTabBarElements` can
-- reference it as a resolved upvalue. `_switchWorldTabForNav` is forward-
-- declared as a local slot, then assigned after `exitWorldMC`, which its body
-- references and which lives further down the file.
-- ============================================================================

-- Forward declaration — assigned further down, once its upvalues (exitWorldMC,
-- getWorldActiveScroll) are in scope. Kahlua closures cannot capture locals
-- declared below them, so the slot is reserved here and filled lower in the
-- file.
local _switchWorldTabForNav

-- The main list's row builder, forward-declared with the others and assigned
-- further down (its callers, toggle() and the per-frame refresh, sit below it).
local _buildWorldInvRowFocusables

-- Forward declarations for the ring-sync helpers and builders that
-- _syncWorldRingZones references. Each is assigned later, where its own
-- dependencies are in scope (the same Kahlua capture rule).
local _buildWorldPanelFocusables
local _buildWorldLootFocusables
local _buildWorldMCColumnFocusables
local _clearGpFocusState
local _syncWorldRingZones
-- worldItemCard zone builder — delegates to win._itemCard's shared API.
local _buildWorldCardActionFocusables
-- `exitWorldMC` and `mcToggleWorldContainer` are consumed by the
-- onHoldActivate/onActivate closures inside `_buildWorldLootFocusables`.
-- Without hoisting, those closures capture the names as globals at creation
-- time — `if mcToggleWorldContainer then` silently short-circuits, so hold-A
-- on a container does nothing.
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
                x = 0, y = curY, w = T.px(ACTION_TAB_STRIP_W), h = T.stripH,   -- (the strip's width; only the height is row 1)
                id       = "tab:" .. tab.id,
                tabId    = tab.id,
                tabIndex = i,
            }
            curY = curY + T.stripH
        end
    end
    return elements
end

-- The strip's non-floor container indices in display order, kept on the window.
-- Sorted again only when forced (the container list just refreshed), when the
-- list itself was replaced, or when the sort mode changed, not every frame.
-- "wt" heaviest first (each bag's weight read once per sort), "type" by name,
-- "dist" leaves the natural order. Callers must not change the returned table.
local function _worldStripListOrder(win, force)
    local containers = win._containers
    local sortMode = win._containerSortMode or "dist"
    local list = win._worldListOrder
    if force or not list or win._worldListFor ~= containers or win._worldListMode ~= sortMode then
        list = {}
        for i, c in ipairs(containers) do
            if not c.isFloor then list[#list + 1] = i end
        end
        if sortMode == "wt" then
            local wt = {}
            for _, ci in ipairs(list) do
                local inv = containers[ci].inventory
                wt[ci] = inv and inv:getCapacityWeight() or 0
            end
            table.sort(list, function(a, b) return wt[a] > wt[b] end)
        elseif sortMode == "type" then
            table.sort(list, function(a, b)
                return (containers[a].name or "") < (containers[b].name or "")
            end)
        end
        win._worldListOrder, win._worldListFor, win._worldListMode = list, containers, sortMode
    end
    return list
end

-- Gamepad-drag reorder for the World container strip (hold X + D-pad), the
-- mirror of _gpReorderCharContainer: moves the container in
-- win._containerOrder, forces sortMode = "dist", and rebuilds the strip's
-- stops around the moved container. The floor container is pinned and not
-- reorderable.
-- (KISS #18) X on a container's button in the strip takes all from it into his inventory, as the band's Take all does
-- (ContainerControls.lootAllFrom). Module fields, not locals: this file is near Kahlua's local limit.
function ZeD_WorldWindow.padTakeAll(w, el)
    local cnt = w and w._containers and w._containers[el.containerIdx]
    if not (cnt and cnt.inventory and not cnt.locked and w._playerObj and ZeD.ContainerControls) then return end
    if ZeD.ContainerControls.lootAllFrom(w._playerObj, cnt.inventory, ZeD.ContainerControls.takeDest(w._playerObj)) then pcall(function() ZeD.uiSound("UIActivateButton") end) end
end
--- The X prompt on a container's button: the game's Take all, hidden while nothing there is wanted (or it is locked).
function ZeD_WorldWindow.padTakeAllPrompt(w, el)
    local cnt = w and w._containers and w._containers[el.containerIdx]
    local po = w and w._playerObj
    if not (cnt and cnt.inventory and po) or cnt.locked then return false end
    local ok, none = pcall(function() return cnt.inventory:isEmptyOrUnwanted(po) end)
    if not ok or none then return false end
    local s = getText("IGUI_invpage_Loot_all")
    return s:sub(1, 1) .. s:sub(2):lower()   -- (sentence case, as the band's button)
end

-- True while player pn's pad is on the World window's own list (the worldMainInv zone: its rows, an open stack's or a
-- category's heading), one container on show and no columns. Returns the window too. (loot KISS calls 1 and 2, the
-- director, Nov 24 2026)
function ZeD_WorldWindow.padOnRows(w)
    local F = ZeD.Input and ZeD.Input.Focus
    if not (w and F and F.getFocusedZone) then return false end
    local z = F.getFocusedZone(w)
    if not (z and z.zone == "worldMainInv") then return false end
    if w._mcSelected and #w._mcSelected > 0 then return false end   -- (columns: Left and RB mean other things there)
    -- (another tab showing a container viewed over the selection: Left lands on the selection's button, not this one)
    if w._viewedContainer and w._viewedContainer ~= w._activeContainer then return false end
    return w._activeContainer ~= nil
end

--- (loot KISS call 1, the director, Nov 24 2026) The help line's way to Loot all while the pad is on a container's
--- rows: "Left X Take all" (Left lands on the container's button, _worldStripLandOn; X there is padTakeAll). The
--- word is the X prompt's on that button, so it hides when that one does (nothing wanted, locked). nil: no prompt.
function ZeD_WorldWindow.padTakeAllHint(w)
    if not ZeD_WorldWindow.padOnRows(w) then return nil end
    local word = ZeD_WorldWindow.padTakeAllPrompt(w, { containerIdx = w._activeContainer })
    if not word then return nil end
    -- (the left arrow, then X: ZeD_PadGlyphs draws them as the D-pad's left arm and the X button)
    return { glyph = "\226\134\144 X", label = word }
end

--- (loot KISS call 2, the director, Nov 24 2026) RB tapped while the pad is on the list's rows: the next container,
--- as the game's RB on its loot page (ISInventoryPage:selectNextContainer, nextUnlockedContainer with wrap): down the
--- strip's order (the Floor at the top, then the list as drawn), past locked ones, round to the top after the last.
--- It is A on that container's button (its rows show, the pad goes on to its first row). True when it took the press;
--- false leaves RB to turn the tabs, as everywhere else.
function ZeD_WorldWindow.padNextContainer(pn)
    local w = ZeD_WorldWindow.getWindow(pn or 0)   -- (_worldWins is declared further down the file)
    local F = ZeD.Input and ZeD.Input.Focus
    if not (w and F and F.getFocusedWindow and F.getFocusedWindow(pn or 0) == w) then return false end
    if not ZeD_WorldWindow.padOnRows(w) then return false end
    local cnts = w._containers or {}
    -- the strip's order: the Floor (last in the list, drawn at the top), then the others as drawn
    local order = {}
    if cnts[#cnts] and cnts[#cnts].isFloor then order[1] = #cnts end
    for _, ci in ipairs(_worldStripListOrder(w)) do order[#order + 1] = ci end
    local at = 0
    for i, ci in ipairs(order) do if ci == w._activeContainer then at = i; break end end
    local pick = nil
    -- (every other container once; all of them when the one on show is not on the strip)
    for step = 1, (at == 0) and #order or (#order - 1) do
        -- (at + step, wrapped to 1..#order; both sides positive, so Kahlua's % is safe here)
        local ci = order[((at - 1 + step) % #order) + 1]
        if ci and cnts[ci] and not cnts[ci].locked then pick = ci; break end
    end
    if not pick then return true end   -- (no other open container: RB does nothing here, as the game's)
    -- A on that container's button, as a tap on the strip (onActivate: shows it, the pad goes to its first row)
    local zone = nil
    for _, z in ipairs(w._focusRing or {}) do if z.zone == "worldContainerStrip" then zone = z; break end end
    for _, e in ipairs((zone and zone.elements) or {}) do
        if e.containerIdx == pick and e.onActivate then
            pcall(function() ZeD.uiSound("UISelectListItem") end)
            local ok, err = pcall(e.onActivate, w, e)
            if not ok then print("[ZeD] World: RB next container: " .. tostring(err)) end
            return true
        end
    end
    return true
end

local function _gpReorderWorldContainer(win, containerIdx, dir)
    if not win or not containerIdx then return end
    local containers = win._containers
    if not containers or #containers == 0 then return end
    -- the stored order, kept the way the Character window keeps its own;
    -- built as the identity order the first time
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

-- The Loot strip's controller stops, one per container button.
_buildWorldLootFocusables = function(win)
    if not win or not win._containers then return {} end
    local n = #win._containers
    if n == 0 then return {} end
    local T = ZeD.T
    local stripY = win:getBodyY()
    -- Match the visual render layout of drawWorldContainerStrip exactly.
    -- Strip visual order:
    --   Zone 1 (floor, pinned top) at y=stripY — containers[#containers]
    --   Zone 1 is row 1 (T.stripH, its line included)
    --   Zone 2 (sort row, NOT focusable) under it, row 2 (T.sortBarH)
    --   Zone 3 (scrollable non-floor list) starts at zone3Y = stripY + T.stripH + T.sortBarH
    -- The floor is LAST in containers[] but draws at the TOP, and the list
    -- below follows the sort order, so element.containerIdx must come from
    -- listEntries, never from the raw container index.
    --
    -- Mirrors the Character window's _buildLootFocusables, inverted for
    -- World's container layout (floor = last index, pinned top).
    -- Coordinates are panel-local, from the places the strip drew last
    -- (win._stripLay): the focus manager adds the strip panel's own offset,
    -- so window-local numbers sat every button a body-height too low for
    -- the D-pad's sums. The list scrolls: stops follow the scroll.
    local L = win._stripLay
    local zone3Y = (L and L.listY) or (T.stripH + T.sortBarH)
    zone3Y = zone3Y - ((L and L.scroll) or 0)
    stripY = 0

    local elements = {}
    local floorIdx = n
    local floorCnt = win._containers[floorIdx]
    if floorCnt and floorCnt.isFloor then
        elements[#elements + 1] = {
            x = 0, y = stripY, w = T.px(CONTAINER_STRIP_W), h = T.stripH - T.px(1),
            id = "container:" .. tostring(floorIdx),
            containerIdx = floorIdx,
            onContextMenu = ZeD_WorldWindow.padTakeAll, promptX = ZeD_WorldWindow.padTakeAllPrompt,   -- (X: Take all, KISS #18)
            inventory = floorCnt.inventory,
            -- onFocus mutates nothing: D-pad cycling on the strip moves the
            -- focus cue only — the active container (=the currently-displayed
            -- view) is set via tap-A (onActivate) or hold-A (mcToggle adds a
            -- column without changing _activeContainer). Were focus to set
            -- _activeContainer, every focused container would satisfy
            -- `cIdx == _activeContainer` in mcToggle, hit the floor-only
            -- branch, and break every column add after the first.
            onFocus = function(w, el) end,
            -- Tap = single view: exit the columns, set active + mainVisible.
            -- Checks `isFloor`, not `isMain` — World containers don't have
            -- an isMain field.
            onActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                local cnt = w._containers and w._containers[el.containerIdx]
                if cnt and cnt.locked then
                    -- a locked container: its lock card instead of its contents
                    if cnt.isoObject and ZeD.ObjectCardLock then pcall(ZeD.ObjectCardLock.openFor, w._playerObj, cnt.isoObject, false) end
                    return
                end
                local isFloor = cnt and cnt.isFloor and true or false
                if w._activeTab == "loot"
                   and w._mcSelected and #w._mcSelected > 0
                   and exitWorldMC then
                    exitWorldMC(w, c)
                end
                w._activeContainer = el.containerIdx
                w._viewedContainer = nil
                -- (shown, floor or not: a hold A after it adds a column beside it, KISS #10)
                w._mainVisible     = true
                -- the pad goes on to the container's first item (once its
                -- rows have drawn); an empty one keeps the focus here
                local inv = cnt and cnt.inventory
                local Fo = ZeD.Input and ZeD.Input.Focus
                if inv and Fo and Fo.focusSoon then
                    Fo.focusSoon(w, "worldMainInv", function(e) return e.item ~= nil and e.item:getContainer() == inv end, 1)
                end
            end,
            onHoldActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                -- (a locked container opens its lock card on hold-A too, as a column or the view, the same as tap-A's check)
                local cnt = w._containers and w._containers[el.containerIdx]
                if cnt and cnt.locked then
                    if cnt.isoObject and ZeD.ObjectCardLock then pcall(ZeD.ObjectCardLock.openFor, w._playerObj, cnt.isoObject, false) end
                    return
                end
                if w._activeTab == "loot" then
                    if mcToggleWorldContainer then
                        mcToggleWorldContainer(w, c, el.containerIdx)
                    end
                else
                    w._activeContainer = el.containerIdx
                    w._viewedContainer = nil
                end
            end,
        }
    end

    -- Elements 2..N: the non-floor containers in the order the strip drew
    -- them (its stored list, _worldStripListOrder, not sorted again here), so
    -- each stop's y matches its button on screen.
    local listEntries = _worldStripListOrder(win)

    for pos, ci in ipairs(listEntries) do
        local cy = zone3Y + (pos - 1) * T.px(CONTAINER_BTN_SZ)
        elements[#elements + 1] = {
            x = 0, y = cy, w = T.px(CONTAINER_STRIP_W), h = T.px(CONTAINER_BTN_SZ),
            id = "container:" .. tostring(ci),
            containerIdx = ci,
            onContextMenu = ZeD_WorldWindow.padTakeAll, promptX = ZeD_WorldWindow.padTakeAllPrompt,   -- (X: Take all, KISS #18)
            inventory = win._containers[ci] and win._containers[ci].inventory,
            -- onFocus mutates nothing: D-pad cycling on the strip moves the
            -- focus cue only — the active container (=the currently-displayed
            -- view) is set via tap-A (onActivate) or hold-A (mcToggle adds a
            -- column without changing _activeContainer). Were focus to set
            -- _activeContainer, every focused container would satisfy
            -- `cIdx == _activeContainer` in mcToggle, hit the floor-only
            -- branch, and break every column add after the first.
            onFocus = function(w, el) end,
            onActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                local cnt = w._containers and w._containers[el.containerIdx]
                if cnt and cnt.locked then
                    -- a locked container: its lock card instead of its contents
                    if cnt.isoObject and ZeD.ObjectCardLock then pcall(ZeD.ObjectCardLock.openFor, w._playerObj, cnt.isoObject, false) end
                    return
                end
                local isFloor = cnt and cnt.isFloor and true or false
                if w._activeTab == "loot"
                   and w._mcSelected and #w._mcSelected > 0
                   and exitWorldMC then
                    exitWorldMC(w, c)
                end
                w._activeContainer = el.containerIdx
                w._viewedContainer = nil
                w._mainVisible     = true   -- (shown: a hold A after it adds a column beside it, KISS #10)
                -- the pad goes on to the container's first item (once its
                -- rows have drawn); an empty one keeps the focus here
                local inv = cnt and cnt.inventory
                local Fo = ZeD.Input and ZeD.Input.Focus
                if inv and Fo and Fo.focusSoon then
                    Fo.focusSoon(w, "worldMainInv", function(e) return e.item ~= nil and e.item:getContainer() == inv end, 1)
                end
            end,
            onHoldActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                -- (a locked container opens its lock card on hold-A too, as a column or the view, the same as tap-A's check)
                local cnt = w._containers and w._containers[el.containerIdx]
                if cnt and cnt.locked then
                    if cnt.isoObject and ZeD.ObjectCardLock then pcall(ZeD.ObjectCardLock.openFor, w._playerObj, cnt.isoObject, false) end
                    return
                end
                if w._activeTab == "loot" then
                    if mcToggleWorldContainer then
                        mcToggleWorldContainer(w, c, el.containerIdx)
                    end
                else
                    w._activeContainer = el.containerIdx
                    w._viewedContainer = nil
                end
            end,
            -- HOLD X + D-pad UP/DOWN = reorder this container in the strip
            -- (mouse-drag parity), the Character strip's binding mirrored.
            -- The floor element above is deliberately NOT given this binding
            -- — it stays pinned at top, like main on the Character window.
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

-- The strip's stops were once built only when the window opened or a tab
-- switched, so a crate walked up to afterwards had no stop and the floor's
-- stop went on pointing at the floor's old place in the list (A on it
-- opened another container). Rebuilt here whenever the list, its order or its
-- scroll changes; the focus stays on the same container (by inventory).
-- (Nov 15 2026, punch list 246, the director: walking away from a group of containers until only the ground was left
-- moved the controller's focus up to the list's Filter button. The row it was on went with its container, and with no
-- rows left the list's first stop is its view button or Filter. The focus goes to the container buttons instead, onto
-- the one showing (the ground), as when the list empties. A field, not a local: this file is near Kahlua's limit.)
function ZeD_WorldWindow._groundIfNoRows(win, Focus, els)
    for _, e in ipairs(els or {}) do if e.item then return end end
    local z = win._focusRing and win._focusRing[win._focusIdx or 1]
    if not (z and z.zone == "worldMainInv") then return end
    win._gpFocusedRowItem = nil
    if not Focus.focusWhere(win, "worldContainerStrip", function(e) return e.containerIdx == win._activeContainer end) then
        Focus.focusWhere(win, "worldContainerStrip")
    end
end

local function _refreshWorldStripFocus(win, Focus)
    local L = win._stripLay
    local cnts = win._containers
    if not (L and cnts and win._focusRing) then return end
    local sum = 0
    for i, ci in ipairs(L.entries or {}) do sum = sum + i * ci end
    local sig = win._stripFocusSig
    if sig and sig.cnts == cnts and sig.scroll == L.scroll and sig.listY == L.listY
       and sig.sum == sum and sig.n == #cnts then return end
    win._stripFocusSig = { cnts = cnts, scroll = L.scroll, listY = L.listY, sum = sum, n = #cnts }
    local zone
    for _, z in ipairs(win._focusRing) do if z.zone == "worldContainerStrip" then zone = z; break end end
    if not zone then return end
    local old = zone.elements and zone.elements[zone.focusedElementIdx or 1]
    local oldInv = old and old.inventory
    local els = _buildWorldLootFocusables(win) or {}
    local keep = 1
    for i, e in ipairs(els) do
        if (oldInv and e.inventory == oldInv) or (not oldInv and e.containerIdx == win._activeContainer) then keep = i; break end
    end
    Focus.setRingZoneElements(win, "worldContainerStrip", els, keep)
    Focus.setZoneFocusable(win, "worldContainerStrip", #els > 0)
end

-- The item card closes once its item has left the containers this window
-- shows (taken, eaten, moved), as the Character window's card does when an
-- item leaves the character; focus then goes back to the list, on the row's
-- neighbour — the player is back where they started once the action is done.
-- Checked every 10 frames.
-- (A count of its own: sharing win._goneTick with closeCardIfItemGone, the mouse's and the
-- controller's check, would let this one, running later in the same frame, always reach 10 first and reset it, so that check would never run.)
local function _closeCardIfItemGone(win)
    win._goneTickPad = (win._goneTickPad or 0) + 1
    if win._goneTickPad < 10 then return end
    win._goneTickPad = 0
    local di = win._drawerItem
    if not di or not win._updateDrawer then return end
    -- (the controller only: the mouse's card stays as it always has; this window's player's input mode)
    local D = ZeD.Input and ZeD.Input.Detector
    if not (D and D.getMode and D.getMode(win.playerNum) == "gamepad") then return end
    local ok, c = pcall(function() return di:getContainer() end)
    local here = false
    if ok and c then
        for _, cnt in ipairs(win._containers or {}) do
            if cnt.inventory == c then here = true; break end
        end
    end
    if not here then
        local content = win._mainContent
        if content and content._selectedItems then content._selectedItems[di] = nil end
        if content then content._lastClickedItem = nil end
        win._updateDrawer()
    end
end

-- The strip's landing (FocusManager zone.landOn): the container on show.
local function _worldStripLandOn(w, z)
    for i, e in ipairs(z.elements or {}) do
        if e.containerIdx == w._activeContainer then return i end
    end
    return nil
end

-- The list's landing from the side: the row focus last had, while it is a row
-- in view (else the spatial pick).
local function _invListLandOn(w, z, dir)
    if dir == "up" or dir == "down" then return nil end
    local e = z.elements and z.elements[z.focusedElementIdx or 1]
    local c = w._mainContent
    if not (e and e.item and c) then return nil end
    if e.y < 0 or e.y + e.h > c:getHeight() then return nil end
    return z.focusedElementIdx or 1
end

-- Foraging tab focusables.
-- Composition (header, body, band):
--   1. Focus dropdown          — in the header strip; A opens/commits, D-pad
--                                nav inside, B closes
--   2. MORE DETAIL disclosure  — A + L/R tree-nav toggles _moreDetailOpen
--   3. SEARCH button           — the band's main action (isPrimary); A toggles
--                                ISSearchManager search mode, and the stop is
--                                the same id, so focus stays on the button
--   4. Grid-scroll pseudo      — D-pad U/D scrolls win._forageScroll; at
--                                bounds falls through to cone nav so user
--                                escapes back upward
-- Crouch/Aim are read-only status in the band: no stops.
local function _buildForageFocusables(win)
    if not win then return {} end
    local elements = {}
    local T = ZeD.T

    -- 1. FOCUS DROPDOWN. A toggles open/commit; while open, D-pad U/D is
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
                    -- The widget resizes itself on its next render (its own
                    -- maxVis sum); only the flag flips here.
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

    -- 2. MORE DETAIL disclosure.
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

    -- 3. SEARCH / STOP SEARCHING: the band's button, the tab's primary action.
    local sb = win._forageSearchBtn
    if sb then
        local mgr = win._playerObj and ISSearchManager.getManager(win._playerObj) or nil
        elements[#elements + 1] = {
            x = sb.x, y = sb.y, w = sb.w, h = sb.h,
            id = "forage:search",
            isSearch = true,
            isPrimary = true,
            promptA = ZeD.tr((mgr and mgr.isSearchMode) and "UI_ZeD_Forage_BtnStopSearch" or "UI_ZeD_Forage_BtnSearch"),
            onActivate = function(w, el)
                ZeD.ForagingTab.toggleSearch(w)
            end,
        }
    end

    -- 4. GRID SCROLL pseudo. Only present when content overflows. D-pad U/D
    -- scrolls win._forageScroll through the element's own onDpadDir
    -- below. Bounds span the full viewport width so the
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
            -- D-pad U/D scrolls _forageScroll; at limits, fall through
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

    return elements
end

-- Animals tab focusables: a state-machine aggregator.
-- Composition varies by (submode × view):
--   ranch overview  → [submode pills, Alerts+Totals disclosures, zone cards]
--   ranch zone      → [submode pills, breadcrumb back, sort btn, roster rows]
--   ranch animal    → [submode pills, breadcrumb back]  (detail = readout)
--   butcher overview→ [submode pills, butcher roster rows]
--   butcher animal  → [submode pills, breadcrumb back]
--
-- Submode pills: focus paints, A switches. Disclosures toggle via A
-- (onActivate) AND L/R tree-nav. Rosters + zone cards navigate via
-- AT.navigate. Alerts stay readout-only. Zone creation collapses the ring to
-- one zone-draw stop (below); the zone's rename and remove, and their answers,
-- are stops from AT.zoneStops (punch list 253).
local function _buildAnimalsFocusables(win)
    if not win then return {} end
    local AT = ZeD and ZeD.AnimalsTab
    if not AT or not AT.getState then return {} end
    local state = AT.getState(win)

    -- Zone-create mode. Ring collapses to a single zone-draw pseudo-
    -- focusable; its onDpadDir moves the ground cursor,
    -- A fires onActivate (phase advance via gpConfirm), B fires onCancel
    -- (phase back-step via gpCancel — hooked in FocusManager's B tap).
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
                -- D-pad moves the ground cursor by 1 tile per press.
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

    -- 1. Submode pills (always present).
    -- Active submode first so preserveIdx=1 seeds to the current submode
    -- (a cold tab entry otherwise lands back on ranch every time,
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
                -- as the Journal's pills: focus paints, A switches the
                -- sub-mode.
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

    -- 2b. Structures: a zone's hutches and troughs, the Butcher view's hooks
    -- (A opens the card), an animal's hutch, and the genome editor (animal
    -- cheats). Each list exists only while its view is drawn.
    for _, sz in ipairs(win._animalsStructZones or {}) do
        elements[#elements + 1] = {
            x = sz.x, y = sz.y, w = sz.w, h = sz.h,
            id = "animals:struct:" .. tostring(sz.kind) .. ":" .. tostring(sz.idx),
            isStruct = true, structIdx = sz.idx, kind = sz.kind, obj = sz.obj,
            onActivate = function(w, el) if AT.openStruct then AT.openStruct(el.kind, el.obj) end end,
        }
    end
    if win._animalsHutchLink then
        local z = win._animalsHutchLink
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h, id = "animals:hutchlink", isHutchLink = true, obj = z.obj,
            onActivate = function(w, el) if AT.openStruct then AT.openStruct("hutch", el.obj) end end,
        }
    end
    for _, gz in ipairs(win._animalsGenomeZones or {}) do
        elements[#elements + 1] = {
            x = gz.x, y = gz.y, w = gz.w, h = gz.h,
            id = "animals:genome:" .. tostring(gz.gene) .. ":" .. tostring(gz.allele),
            isGenome = true, gene = gz.gene, allele = gz.allele,
            onActivate = function(w, el) w._animalsGenomeSel = { gene = el.gene, allele = el.allele } end,
        }
    end
    for _, b in ipairs(win._animalsGenomeBtns or {}) do
        elements[#elements + 1] = {
            x = b.x, y = b.y, w = b.w, h = b.h, id = "animals:genomebtn:" .. tostring(b.id), isGenomeBtn = true, btnId = b.id,
            onActivate = function(w, el)
                if AT.genomeAct and w._animalsState then AT.genomeAct(w, el.btnId, w._animalsState.animalRef) end
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
        -- The alerts' rows (the page scrolls to them): A presses the row's
        -- button, its verb (Milk, Shear, Walk to); a greyed one does nothing
        -- and its reason shows in a balloon while the row has the focus.
        if win._animalsAlertZones then
            for _, az in ipairs(win._animalsAlertZones) do
                elements[#elements + 1] = {
                    x = az.x, y = az.y, w = az.w, h = az.h,
                    id = "animals:alert:" .. tostring(az.i),
                    isAlertRow = true,
                    animal = az.animal, verb = az.verb,
                    onActivate = function(w, el)
                        if AT.alertAct then AT.alertAct(w, el.animal, el.verb) end
                    end,
                }
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
                        -- land on the breadcrumb so back-nav is the natural
                        -- next action; the index clamp otherwise lands the
                        -- user mid-ring (on the sort button, for one).
                        w._animalsNavFocusTarget = "breadcrumb"
                    end,
                    -- X: the zone's menu, Rename and Remove zone (punch list 253)
                    sx = zc.sx, sy = zc.sy,
                    onContextMenu = function(w, el)
                        if AT.zoneMenu then AT.zoneMenu(w, el.zoneName, el.sx, el.sy, true, el.id) end
                    end,
                    promptX = ZeD.tr("UI_ZeD_Prompt_Menu"),
                }
            end
        end
        -- + CREATE ZONE footer button → enters zone creation. The mouse
        -- drags the zone out on the ground; the pad draws it through the
        -- phased zone-draw stop above.
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
        -- Help: the game's own note on livestock zones.
        if win._animalsZoneHelpZone then
            local z = win._animalsZoneHelpZone
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "animals:zonehelp",
                onActivate = function(w)
                    if AT.zoneHelp then AT.zoneHelp(w) end
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
                    -- X (the right mouse): ticks or clears the row, as its box does
                    onContextMenu = function(w, el)
                        if AT.toggleSelected then AT.toggleSelected(w, el.animal) end
                    end,
                }
            end
        end
        -- The band: All hungry / All milkable, Clear, Milk / Shear over the
        -- ticked rows, Stop. A greyed one does nothing; its reason shows in a
        -- balloon while it has the focus.
        for _, b in ipairs(win._animalsBulkBtns or {}) do
            elements[#elements + 1] = {
                x = b.x, y = b.y, w = b.w, h = b.h,
                id = "animals:bulk:" .. tostring(b.id),
                isBulk = true, bulkId = b.id,
                onActivate = function(w, el)
                    if AT.bulkPress then AT.bulkPress(w, el.bulkId) end
                end,
            }
        end
        -- (Nov 16 2026, punch list 253) The zone's own controls: its name (A renames, X the zone's menu), the band's
        -- Rename and Remove zone; while a rename is open its box (A: the keyboard) with Reset, Cancel and Save; while
        -- the remove question is open its Cancel and Remove. B on the rename or the question is Cancel.
        if AT.zoneStops then
            for _, e in ipairs(AT.zoneStops(win)) do elements[#elements + 1] = e end
        end
    elseif state.submode == "butcher" then
        -- Butcher roster rows (the overview); a row opens the animal view,
        -- whose breadcrumb leads back here. The zones exist only while the
        -- roster is drawn.
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
    -- ranch/animal: submode pills + breadcrumb, the hutch link and (with
    -- animal cheats) the genome editor; the rest of the detail is readout.

    -- a bird the hutch card's Info opened: B goes back to that card (QA HU5, Nov 26 2026)
    if AT.withReturn then AT.withReturn(win, elements) end
    return elements
end

-- Crafting tab focusables (World window). ZeD.CraftingTab.buildFocusables
-- picks them: a station's own view, or the recipe list through the shared
-- CraftingCore.buildFocusables (prefix "craft", ZeD_CraftPins for the X pin,
-- the HandcraftLogic-backed startCraft behind the Craft button). The state
-- (`win._craftState`) is made by ZeD.CraftingTab.render on the tab's first
-- frame, so there are no stops until then. The direct CraftingCore call is
-- the fallback for a CraftingTab without its own builder.
local function _buildWorldCraftFocusables(win)
    if not (ZeD and ZeD.CraftingCore and ZeD.CraftingTab) then return {} end
    -- CraftingTab routes to the recipe view or a station's own view
    if ZeD.CraftingTab.buildFocusables then return ZeD.CraftingTab.buildFocusables(win) end
    return ZeD.CraftingCore.buildFocusables(win, win and win._craftState,
        "craft", "ZeD_CraftPins", ZeD.CraftingTab.startCraft)
end

-- Building tab focusables (World window). Same shape as Craft;
-- prefix="build", BuildLogic-backed startBuild (which spawns the placement
-- cursor on success — getCell():setDrag()).
local function _buildWorldBuildFocusables(win)
    if not (ZeD and ZeD.CraftingCore and ZeD.BuildingTab) then return {} end
    local els = ZeD.CraftingCore.buildFocusables(win, win and win._buildState,
        "build", "ZeD_BuildPins", ZeD.BuildingTab.startBuild)
    if ZeD.BuildingTab.cardCancels then ZeD.BuildingTab.cardCancels(win, els) end
    return els
end

-- Build panel-level focusables for a World tab (the worldTabContent zone).
-- Each tab delegates to its own builder. Loot returns {}: its rows live in
-- the always-visible worldMainInv zone and its containers in
-- worldContainerStrip — sibling ring zones, not nested levels.
_buildWorldPanelFocusables = function(win, content, tabId)
    if not win then return {} end
    -- Loot invrows live in the worldMainInv zone (always visible);
    -- worldTabContent carries per-tab secondary content only.
    if tabId == "loot"    then return {}                               end
    local ext = ZeD_WorldWindow._extTabs[tabId]
    if ext then return ext.buildFocusables and ext.buildFocusables(win) or {} end
    if tabId == "forage"  then return _buildForageFocusables(win)      end
    if tabId == "animals" then return _buildAnimalsFocusables(win)     end
    if tabId == "craft"   then return _buildWorldCraftFocusables(win)  end
    if tabId == "build"   then return _buildWorldBuildFocusables(win)  end
    -- Maps canvas annotation tools. MapsTab owns the builder: the
    -- disclosure, the header's tools and colors, the pop-out button, the
    -- full set of marks while the fold is open, other mods' controls, the
    -- canvas cursor, then the band. Mouse hit-zone tables are populated each
    -- frame by the Maps renderer; the builder reads them as the source of
    -- truth for bounds, so builder + render stay in lock-step.
    if tabId == "maps" then
        if ZeD and ZeD.MapsTab and ZeD.MapsTab.buildFocusables then
            return ZeD.MapsTab.buildFocusables(win)
        end
        return {}
    end
    -- Radio drawer focusables. Mirrors the Character window dispatcher
    -- exactly, so the pad behaves the same in both windows.
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
    if tabId == "furniture" then
        if ZeD and ZeD.FurnitureTab and ZeD.FurnitureTab.buildFocusables then
            return ZeD.FurnitureTab.buildFocusables(win)
        end
        return {}
    end
    return {}
end

-- Per-column MC builder. Each open column is its own ring zone
-- (`worldMC1`, `worldMC2`, ..., `worldMCN`), so the bumpers cycle the
-- columns one at a time. This builder returns
-- elements for ONE column identified by `slot` (1..#_mcSelected).
--
-- colStates convention: [_mcSelected[1], _mcSelected[2], ..., _mcSelected[K],
-- _activeContainer (when _mainVisible)]. So colStates[slot] for slot=1..K maps
-- to the slot-th MC selection.
--
-- Element id pattern "mcrow:slot:i" lets the per-zone refresh dedup. Each
-- element shares the World invrow callback shape: A selects (the card opens),
-- hold A marks, hold X is the quick use, X opens the context menu.
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
    local xMap  = cs.itemRenderXMap or {}   -- (the grid: each cell's x)
    local gcell = cs.gridCell
    local colX  = cs.renderX or 0
    local colW  = cs.renderW or T.px(200)

    for i = 1, #items do
        local item = items[i]
        local yCoord = yMap[item] or (i * rowH)
        elements[#elements + 1] = {
            -- (Nov 15 2026, add-on hooks: a spanned cell's own size, GridLayout.lua; nil maps without one)
            x = (xMap[item] or colX), y = yCoord,
            w = (cs.itemRenderWMap and cs.itemRenderWMap[item]) or gcell or colW,
            h = (cs.itemRenderHMap and cs.itemRenderHMap[item]) or gcell or rowH,
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
                if w._drawerItem ~= nil and w._updateDrawer and el.item and cnt and not w._gpPaint then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    sel[el.item] = true
                    cnt._selectedItems   = sel
                    cnt._lastClickedItem = el.item
                    w._updateDrawer(cnt)
                end
            end,
            -- A = LMB. Stack rep → toggle expand/collapse; non-stack
            -- item → select (open card drawer). Hold X = double-LMB use.
            -- onContextMenu = vanilla context menu (Take/Move-To via floor-routing
            -- inside ContextMenuRegistry). (Nov 14 2026, punch list 223: padItemButtons
            -- puts the menu on A over an open card and X on the game's grab; 225: hold A on food eats)
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
                    ZeD.InventoryRenderer.padClearMarks(w, el, true)   -- (a plain select drops the marks, every list's)
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    -- A toggles the card drawer (as the Character rows do).
                    if w._drawerItem ~= el.item then
                        sel[el.item] = true
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = el.item
                    else
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = nil
                    end
                    w._updateDrawer(cnt)
                    -- the card opened: focus onto its primary action
                    if w._drawerItem == el.item then ZeD.Input.Focus.focusPrimarySoon(w, "worldItemCard", 2) end
                end
            end,
            -- the controller's marks: hold A marks, a held A paints, hold X is the quick use,
            -- B clears the marks (its prompt and X's only while marks exist, read each frame)
            onHoldActivate = function(w, el) ZeD.InventoryRenderer.padMark(w, el) end,
            onPaint        = function(w, el, paint) ZeD.InventoryRenderer.padPaint(w, el, paint) end,
            onHoldContext  = function(w, el)
                if not el.item then return end
                pcall(ZeD.InventoryRenderer.quickUse, el.item, ZeD.playerNumOf(w))
            end,
            onCancel   = ZeD.InventoryRenderer.padCancel,      -- B clears the marks (nothing without them)
            promptB    = ZeD.InventoryRenderer.padPromptB,     -- the footer reads these each frame (functions)
            onContextMenu = function(w, el)
                if not el.item then return end
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
                    local cnt = w._mainContent
                    local cs2 = cnt and cnt._colStates and cnt._colStates[el.colIdx]
                    local stk = cs2 and cs2.stacks and cs2.stacks[el.item]
                    local itemsArr = ZeD.InventoryRenderer.padMarkedItems(w, el) or ((stk and stk.count > 1) and stk.items or {el.item})
                    ISInventoryPaneContextMenu.createMenu(ZeD.playerNumOf(w), false, itemsArr, 0, 0)
                end
            end,
        }
        ZeD.InventoryRenderer.padItemButtons(elements[#elements])   -- (Nov 14 2026, punch list 223: X moves, A on an open card is the menu; 225: hold A on food eats)
    end
    -- an open stack's header row: a stop of its own (Nov 15 2026, punch list 245; A on it shuts the stack)
    for _, e in ipairs(ZeD.InventoryRenderer.headElements(cs.openHeads, yMap, colX, colW, cs.rowView, slot, cs.containerIdx, cs.inventory)) do
        elements[#elements + 1] = e
    end
    -- a category's heading: a stop of its own (Nov 16 2026, punch list 256; A folds or opens it)
    for _, e in ipairs(ZeD.InventoryRenderer.catElements(cs.catHeads, cs.catGroups, yMap, colX, colW, cs.rowView, slot, cs.containerIdx, cs.inventory)) do
        elements[#elements + 1] = e
    end
    -- rows out of the column's view: for the column's own Up / Down only
    ZeD.Input.Focus.markOffscreen(elements, cs.rowView)
    -- the column's view button
    for _, e in ipairs(ZeD.InventoryRenderer.toggleElements(cs.viewToggleRects)) do elements[#elements + 1] = e end
    -- An empty column needs a placeholder so the zone stays focusable;
    -- the bumpers would otherwise skip empty containers, breaking the
    -- "each column is its own zone" model.
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

-- Clear all _gpFocused* chrome state fields on the World window +
-- content. Called from _syncWorldRingZones after a tab switch. Mirrors the
-- Character window helper.
_clearGpFocusState = function(w)
    if not w then return end
    w._gpFocusedRowItem        = nil
    w._gpFocusedAnimalSubmode  = nil  -- nothing writes this any more
    w._gpFocusedAnimalRow      = nil  -- roster/butcher row focus
    w._gpFocusedRadioCtl       = nil  -- the radio tab's focused control id
    w._invRowsForContainer     = nil
    -- CraftingCore scroll-follow delta-gate pins (one per prefix). A fresh
    -- tab visit must re-pin on first focus, not inherit the previous
    -- element's position as "already correct".
    w._lastPinnedRecipeId_craft = nil
    w._lastPinnedRecipeId_build = nil
    -- Clear the pending card-jump flag on the craft/build states so a
    -- mid-jump tab-switch doesn't force a stale jump on return. Last-row
    -- restore id is left intact — restoring it on re-entry is desirable.
    if w._craftState then w._craftState._gpPendingCardJump = false end
    if w._buildState then w._buildState._gpPendingCardJump = false end
    -- Clear MC zone focus + delta-gate pin on tab-switch / mode reset;
    -- re-entry to Loot+MC seeds focus to idx 1
    -- via the per-frame refresh's preserveIdx fallback.
    w._gpFocusedMCItem       = nil
    w._gpFocusedMCColIdx     = nil
    w._lastPinnedMCItem      = nil
    local c = w._mainContent
    if c then c._gpFocusedRowItem = nil end
end

-- True when a Loot column's pad targets need rebuilding: its rows (the same
-- items in the same order), scroll, view, row height, place or container
-- changed since the last build. Records the new state when it says yes.
-- No tables or strings are made on the frames where nothing changed.
local function _worldMCColumnDirty(win, slot, cs)
    win._lastMCSnap = win._lastMCSnap or {}
    local snap = win._lastMCSnap[slot]
    local items = cs.flatItems or {}
    local n = #items
    local scrollPos = cs.scroll and cs.scroll.scrollPos
    local yMap = cs.itemRenderYMap
    local y1 = yMap and n > 0 and yMap[items[1]] or nil
    local nToggles = (cs.viewToggleRects and #cs.viewToggleRects or 0) + 4096 * ZeD.InventoryRenderer.filterGen(win._mainContent)   -- (the Filter's stops move)
    if snap and snap.n == n and snap.scrollPos == scrollPos and snap.y1 == y1
       and snap.gridCell == cs.gridCell and snap.renderX == cs.renderX
       and snap.glg == cs.gridLayoutGen   -- (Nov 15 2026, add-on hooks: a new add-on layout moves the cells)
       and snap.renderW == cs.renderW and snap.rowH == ZeD.T.rowH
       and snap.containerIdx == cs.containerIdx and snap.nToggles == nToggles
       and snap.vb == (cs.rowView and cs.rowView.bottom) then   -- (the view: which rows are out of it)
        local same = true
        local old = snap.items
        for i = 1, n do
            if old[i] ~= items[i] then same = false; break end
        end
        if same then return false end
    end
    local copy = {}
    for i = 1, n do copy[i] = items[i] end
    win._lastMCSnap[slot] = {
        n = n, items = copy, scrollPos = scrollPos, y1 = y1,
        gridCell = cs.gridCell, renderX = cs.renderX, renderW = cs.renderW, glg = cs.gridLayoutGen,
        rowH = ZeD.T.rowH, containerIdx = cs.containerIdx, nToggles = nToggles,
        vb = cs.rowView and cs.rowView.bottom,
    }
    return true
end

-- True when the slot's pad targets must be rebuilt: the column has no state
-- yet, or _worldMCColumnDirty says it changed.
local function _worldMCSlotStale(win, content, slot)
    local colStates = content._colStates
    local cs = colStates and colStates[slot]
    return (not cs) or _worldMCColumnDirty(win, slot, cs)
end

-- Dynamic per-column MC ring zone restructuring. Each MC selection
-- becomes its own ring zone (worldMC1..worldMCN); bumpers cycle them as
-- standard ring zones.
-- Insertion point: between worldContainerStrip and worldMainInv (matches the
-- visual layout where MC cols sit left of mainInv in the content panel).
local function _rebuildWorldMCRingZones(win)
    -- the zones are rebuilt here, so the per-frame change check starts fresh
    if win then win._lastMCSnap = nil end
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

    -- Restore _focusIdx by name. If the focused zone was a column that is now
    -- gone, land on the main list (worldMainInv) when it can take focus.
    if focusedName then
        local found = nil
        for i, z in ipairs(ring) do
            if z.zone == focusedName then found = i; break end
        end
        if found then
            win._focusIdx = found
        elseif focusedName:match("^worldMC%d+$") then
            -- The column's zone is gone (the columns closed, or one was dropped).
            for i, z in ipairs(ring) do
                if z.zone == "worldMainInv" and z.focusable then
                    win._focusIdx = i; break
                end
            end
        end
    end
end

-- Sync the ring zones to the new active tab + MC state. Called wherever the
-- tab or the column set changes. Centralizes the
-- mutations so the various entry points don't drift.
_syncWorldRingZones = function(win, content)
    if not (ZeD and ZeD.Input and ZeD.Input.Focus and win and win._focusRing) then return end
    local Focus  = ZeD.Input.Focus
    local tabId  = win._activeTab

    -- Capture the currently focused containerIdx BEFORE the rebuild.
    -- Container onFocus is a no-op, so _activeContainer
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
    -- Containers stay reachable on ALL tabs; the column toggle is Loot-only.
    local newContainerEls = _buildWorldLootFocusables(win) or {}

    -- Forage lands on its main action, the band's Search
    local contentIdx = 1
    if tabId == "forage" then
        for i, el in ipairs(newContentEls) do
            if el.id == "forage:search" then contentIdx = i; break end
        end
    end
    -- (a tab another file added names its own main action: def.landOn(win) gives the stop's id)
    local extLand = ZeD_WorldWindow._extTabs[tabId]
    if extLand and extLand.landOn then
        local want = extLand.landOn(win)
        for i, el in ipairs(newContentEls) do
            if el.id == want then contentIdx = i; break end
        end
    end
    Focus.setRingZoneElements(win, "worldTabContent",     newContentEls, contentIdx)
    Focus.setZoneFocusable   (win, "worldTabContent",     #newContentEls > 0)
    -- containerEls are in [floor, non-floor display-order] layout
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

    -- MC ring zones rebuilt from the _mcSelected count (one zone per
    -- open column).
    _rebuildWorldMCRingZones(win)

    -- A tab change always leaves "item" mode (_switchWorldTabForNav flips
    -- _drawerMode). Explicitly disable the card zone so a bumper press in the
    -- same frame can't land on stale card elements before the per-frame
    -- refresh runs next frame.
    Focus.setRingZoneElements(win, "worldItemCard", {})
    Focus.setZoneFocusable   (win, "worldItemCard", false)

    if _clearGpFocusState then _clearGpFocusState(win) end
    if win._rolled and win._curtain and win._curtain.onFrame then win._curtain.onFrame() end
end

-- Build inventory-row focusables for the World Window's active container.
-- Mirrors _buildInvRowFocusables from ZeD_CharacterWindow but passes
-- isInPlayerInventory=false for the context menu (world items aren't in player inv).
_buildWorldInvRowFocusables = function(win)
    local c = win and win._mainContent
    local items = c and c._invRowItems
    if not c then return {} end
    -- (Nov 14 2026, punch list 202: an empty container still has its column's view button and Filter: no rows,
    -- but those stops stay, so Right from the strip lands on them and not on the footer's Take all)
    if not items or #items == 0 then
        -- (punch list 256: every category folded leaves no rows, but their headings stay stops to open them by)
        local els = ZeD.InventoryRenderer.catElements(c._useGroups and c._catOrder or nil, c._stackedGroups, c._itemRenderYMap,
            0, ZeD.T.px(200), c._rowView, nil, nil, c._inventory)
        for _, e in ipairs(ZeD.InventoryRenderer.toggleElements(c._viewToggleRects)) do els[#els + 1] = e end
        return els
    end
    local elements = {}
    -- Bounds must be distinct per element so the cone-nav algorithm can
    -- pick neighbors. Prefer the renderer-stamped Y from _itemRenderYMap;
    -- fall back to index*rowH when the map hasn't been
    -- populated yet (first frame after tab switch).
    local T = ZeD.T
    local rowH = (T and T.rowH) or 26
    local yMap = c._itemRenderYMap or {}
    local xMap = c._itemRenderXMap or {}   -- (the grid: each cell's x)
    local gcell = c._gridCell
    for i = 1, #items do
        local item = items[i]
        local yCoord = yMap[item] or (i * rowH)
        elements[#elements + 1] = {
            -- (Nov 15 2026, add-on hooks: a cell an add-on's layout spans over several squares has its own size,
            -- GridLayout.lua; without one the maps are nil and every cell is gcell square, as before)
            x = (xMap[item] or 0), y = yCoord,
            w = (c._itemRenderWMap and c._itemRenderWMap[item]) or gcell or T.px(200),
            h = (c._itemRenderHMap and c._itemRenderHMap[item]) or gcell or rowH,
            id = "invrow:" .. tostring(i),
            item = item,
            itemIndex = i,
            onFocus = function(w, el)
                w._gpFocusedRowItem = el.item
                local cnt = w._mainContent
                if cnt then cnt._gpFocusedRowItem = el.item end
                -- Card follow-focus. When the card is visible (any tab —
                -- on non-Loot tabs the card overlays the tab drawer while
                -- `_drawerMode` stays "tab"), moving the gp cursor to a
                -- different invrow live-swaps the card to the newly-focused
                -- item. Gate on `_drawerItem ~= nil`, not `_drawerMode`.
                if w._drawerItem ~= nil and w._updateDrawer and el.item and cnt and not w._gpPaint then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    sel[el.item] = true
                    cnt._selectedItems   = sel
                    cnt._lastClickedItem = el.item
                    w._updateDrawer()
                end
            end,
            -- A tap = LMB = SELECT item (opens card drawer for it).
            -- On a stack rep (count > 1), A toggles stack expand/collapse
            -- (= LMB on chevron). X hold = double-LMB (InventoryRenderer
            -- quickUse: to the main inventory). (Nov 14 2026, punch list 223: padItemButtons
            -- puts onContextMenu's menu on A over an open card and X on the game's grab;
            -- 225: hold A on food eats.) onContextMenu = vanilla context menu —
            -- the menu's "Take" / "Move To" entries handle floor items via
            -- their own paths (floor-routing happens inside
            -- ContextMenuRegistry.makeActionDef.onFire, before the transfer).
            onActivate = function(w, el)
                if not el.item then return end
                local cnt = w._mainContent
                local stk = cnt and cnt._stacks and cnt._stacks[el.item]
                if stk and stk.count > 1 then
                    cnt._expandedStacks = cnt._expandedStacks or {}
                    cnt._expandedStacks[stk.key] = not cnt._expandedStacks[stk.key]
                    print("[ZeD.Input] Focus: stack row " .. tostring(stk.key) .. " -> " .. tostring(cnt._expandedStacks[stk.key]) .. " (table " .. tostring(cnt._expandedStacks) .. ")")
                    return
                end
                if cnt and w._updateDrawer then
                    ZeD.InventoryRenderer.padClearMarks(w, el, true)   -- (a plain select drops the marks, every list's)
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    -- A toggles the card drawer (as the Character rows do).
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
                    -- the card opened (or swapped to this item):
                    -- focus onto its primary action, so A again does it
                    if w._drawerItem == el.item then ZeD.Input.Focus.focusPrimarySoon(w, "worldItemCard", 2) end
                end
            end,
            -- the controller's marks: hold A marks, a held A paints, hold X is the quick use,
            -- B clears the marks (its prompt and X's only while marks exist, read each frame)
            onHoldActivate = function(w, el) ZeD.InventoryRenderer.padMark(w, el) end,
            onPaint        = function(w, el, paint) ZeD.InventoryRenderer.padPaint(w, el, paint) end,
            onHoldContext  = function(w, el)
                if not el.item then return end
                pcall(ZeD.InventoryRenderer.quickUse, el.item, ZeD.playerNumOf(w))
            end,
            onCancel   = ZeD.InventoryRenderer.padCancel,      -- B clears the marks (nothing without them)
            promptB    = ZeD.InventoryRenderer.padPromptB,     -- the footer reads these each frame (functions)
            onContextMenu = function(w, el)
                if not el.item then return end
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
                    local cnt = w._mainContent
                    local stk = cnt and cnt._stacks and cnt._stacks[el.item]
                    local itemsArr = ZeD.InventoryRenderer.padMarkedItems(w, el) or ((stk and stk.count > 1) and stk.items or {el.item})
                    ISInventoryPaneContextMenu.createMenu(ZeD.playerNumOf(w), false, itemsArr, 0, 0)
                end
            end,
        }
        ZeD.InventoryRenderer.padItemButtons(elements[#elements])   -- (Nov 14 2026, punch list 223: X moves, A on an open card is the menu; 225: hold A on food eats)
    end
    -- an open stack's header row: a stop of its own (Nov 15 2026, punch list 245; A on it shuts the stack)
    for _, e in ipairs(ZeD.InventoryRenderer.headElements(c._openHeads, yMap, 0, T.px(200), c._rowView, nil, nil, c._inventory)) do
        elements[#elements + 1] = e
    end
    -- a category's heading: a stop of its own (Nov 16 2026, punch list 256; A folds or opens it)
    for _, e in ipairs(ZeD.InventoryRenderer.catElements(c._useGroups and c._catOrder or nil, c._stackedGroups, yMap, 0, T.px(200), c._rowView, nil, nil, c._inventory)) do
        elements[#elements + 1] = e
    end
    -- seed only when nothing is remembered: a rebuild (scroll, an item gone) must not
    -- send focus back to the first row
    if elements[1] and elements[1].item and win._gpFocusedRowItem == nil then
        win._gpFocusedRowItem = elements[1].item
        local cnt = win._mainContent
        if cnt then cnt._gpFocusedRowItem = elements[1].item end
    end
    -- rows out of the list's view: for the list's own Up / Down only
    ZeD.Input.Focus.markOffscreen(elements, c._rowView)
    -- the column's view button (up from the first row reaches it)
    for _, e in ipairs(ZeD.InventoryRenderer.toggleElements(c._viewToggleRects)) do elements[#elements + 1] = e end
    return elements
end

-- World Window item card action strip focusables. Same shape as the
-- Character window builder: delegates to the card organism, which stamps live
-- toggle + verb button rects each frame. Returns {} when the card isn't
-- visible. On non-Loot tabs the card OVERLAYS the tab drawer while
-- `_drawerMode` stays "tab", so the gate is `_drawerItem`, not the mode.
--
-- Each card button gets:
--   * onDpadDir — D-pad U/D scrolls card content by disclosure (preserves
--     focus); L/R falls through to flat cone-nav between buttons.
--   * onCancel  — B closes the card drawer (mouse parity).
local function _wireWorldCardButtonNav(els, win)
    -- ItemCard returns ABSOLUTE screen coords. Convert to
    -- itemDrawerPanel-local so _collectFlat's panel-offset translation
    -- doesn't double-offset (the Character window converts the same way).
    local drawerPanel = win and win._itemDrawerPanel
    local panelAbsX = (drawerPanel and drawerPanel.getAbsoluteX
                       and drawerPanel:getAbsoluteX()) or 0
    local panelAbsY = (drawerPanel and drawerPanel.getAbsoluteY
                       and drawerPanel:getAbsoluteY()) or 0
    for i = 1, #els do
        local el = els[i]
        el.x = el.x - panelAbsX
        el.y = el.y - panelAbsY
        -- Up = to the action strip, Down = next control, then
        -- read on (ZeD_ItemCard:gpDpad, shared with the Character window)
        el.onDpadDir = function(w, e, dir)
            if w._itemCard and w._itemCard.gpDpad then
                return w._itemCard:gpDpad(w, e, dir, "worldItemCard")
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
    -- Append clothing detail-zone structural docks AFTER the action strip.
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
        -- An A press is required to switch tabs; D-pad focus on a tab only
        -- paints, never switches. Mirror of the Character window's
        -- _attachTabBarCallbacks.
        el.onFocus = function(w, e) end
        el.onActivate = function(w, e)
            local c = w._mainContent
            if c and _switchWorldTabForNav then
                _switchWorldTabForNav(w, c, e.tabId)
            end
        end
    end
end

-- Per-tab drawer width — tabs not listed use the default DRAWER_W.
-- Every listed tab takes TAB_DRAWER_W today; the table lets one differ.
local WORLD_TAB_DRAWER_WIDTHS = {
    craft = TAB_DRAWER_W,
    build = TAB_DRAWER_W,
    maps   = TAB_DRAWER_W,
    forage = TAB_DRAWER_W,
    animals = TAB_DRAWER_W,
    radio  = TAB_DRAWER_W,  -- the radio chassis needs the wider tab drawer
    vehicle = TAB_DRAWER_W,
    furniture = TAB_DRAWER_W,
}

local function getWorldTabDrawerW(tab)
    return WORLD_TAB_DRAWER_WIDTHS[tab] or DRAWER_W
end

-- Tab content renderers, by tab id (each tab module registers its own below)
local WORLD_TAB_RENDERERS = {}
--- Adds a tab from another file (the def's fields are listed above
--- ZeD_WorldWindow._extTabs). It goes in after the tab def.after names, else
--- last; its drawer is def.drawerW wide, else the full card. A second call
--- with the same id is ignored.
function ZeD_WorldWindow.addTab(def)
    if ZeD_WorldWindow._extTabs[def.id] then return end
    ZeD_WorldWindow._extTabs[def.id] = def
    WORLD_TAB_RENDERERS[def.id] = def.render
    WORLD_TAB_DRAWER_WIDTHS[def.id] = def.drawerW or TAB_DRAWER_W
    local at = #WORLD_TABS + 1
    for i, t in ipairs(WORLD_TABS) do
        if t.id == def.after then at = i + 1 end
    end
    table.insert(WORLD_TABS, at, def)
end
ZeD.CraftingTab.register(WORLD_TAB_RENDERERS)
ZeD.BuildingTab.register(WORLD_TAB_RENDERERS)
ZeD.MapsTab.register(WORLD_TAB_RENDERERS)
ZeD.ForagingTab.register(WORLD_TAB_RENDERERS)
ZeD.AnimalsTab.register(WORLD_TAB_RENDERERS)
ZeD.RadioTab.register(WORLD_TAB_RENDERERS)
ZeD.MechanicsTab.register(WORLD_TAB_RENDERERS)
ZeD.FurnitureTab.register(WORLD_TAB_RENDERERS)

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


--- The picture for a container with none of its own: the game's own box (its
--- cardboard box / crate icon), never a letter glyph — a letter reads as modern
--- UI and breaks the 1993 look. Shared by both windows' strips.
ZeD.genericContainerTex = ZeD.genericContainerTex or function()
    local I = ContainerButtonIcons
    return I and (I.cardboardbox or I.crate or I.smallbox) or getTexture("media/ui/Container_Crate.png")
end

-- Resolve a container icon: try direct, then fallback alias, then nil
local function resolveContainerIcon(containerType)
    if not ContainerButtonIcons then return nil end
    local tex = ContainerButtonIcons[containerType]
    if tex then return tex end
    local alias = ICON_FALLBACKS[containerType]
    if alias then return ContainerButtonIcons[alias] end
    return nil
end

-- The open World windows, one a local player, by player number (0 is the first player). Only the first player's
-- opens for now (ZeD.windowsFor); the map lets split-screen give each player one later.
local _worldWins = {}

-- An open item card lies over the tab drawer's LEFT part (the World window mirrors
-- the Character window; up to coverL, drawer-local): while the tab draws, every
-- clip it sets is cut at the card's right edge, and clearing one puts that cut
-- back (PZ stencils do not nest). With see-through the card no longer hides what
-- is under it, so the tab draws only what the card leaves showing. The counts
-- ZeD_Panel keeps of its stencils stay as the tab's own calls make them.
local function coverStencil(p, x, y, w, h)
    local nx = math.max(x, p._coverL or x)
    return ZeD_Panel.setStencilRect(p, nx, y, math.max(0, x + w - nx), h)
end
local function coverClear(p)
    local n = p._zedStencilN
    if n and n > 0 then p._zedStencilN = n - 1 end
    p._coverClears = (p._coverClears or 0) + 1   -- (it sets one again: one more on than the count says)
    ISPanel.clearStencilRect(p)
    local cl = p._coverL or 0
    return ISPanel.setStencilRect(p, cl, 0, math.max(0, (p._coverR or p:getWidth()) - cl), p:getHeight())
end
local function setTabCover(p, coverL, coverR)
    p._coverL, p._coverR = coverL, coverR
    if coverL then p.setStencilRect, p.clearStencilRect = coverStencil, coverClear
    else p.setStencilRect, p.clearStencilRect = nil, nil end
end

-- Floor container — vanilla's (ISInventoryPage.GetFloorContainer), fetched on the
-- window's first container scan and refilled by it (see buildWorldContainers)
-- (one per local player: split view; ISInventoryPage.GetFloorContainer is per player too)
local _floorContainers = {}
-- whether c is a floor container of any local player's World window
local function _isFloor(c)
    if not c then return false end
    for p = 0, 3 do if _floorContainers[p] == c then return true end end
    return false
end

-- Tab strip separator — TAB_SEP_H/TAB_SEP_MAR live up with the constants
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
            totalH = totalH + T.stripH
        end
    end
    return totalH
end

-- The strip, when it scrolls, brings the tab that matters into view: the controller's focused
-- tab, else the active one. Only when that tab changes (a new focus, a new active tab, the
-- strip just starting to scroll), so the wheel and the arrows can still look elsewhere.
-- (Without it, at 1280x720, UI scale 2.0 and Large text, a controller moving
-- down past Maps focuses Forage, Animals, Radio and Vehicle out of sight.)
local function worldTabStripFollow(win, viewH, scrollOff, maxScroll, focusedId)
    local tgt = focusedId or win._activeTab
    local isPad = focusedId ~= nil
    if tgt == win._tabFollowId and isPad == win._tabFollowPad then return scrollOff end
    win._tabFollowId, win._tabFollowPad = tgt, isPad
    local T = ZeD.T
    local y, lastGroup, btn = 0, 1, T.stripH
    for _, tab in ipairs(WORLD_TABS) do
        if isTabVisible(tab, win) then
            if tab.group ~= lastGroup then
                y = y + T.px(TAB_SEP_MAR) + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
                lastGroup = tab.group
            end
            if tab.id == tgt then
                if y < scrollOff then scrollOff = y
                elseif y + btn > scrollOff + viewH then scrollOff = y + btn - viewH end
                return math.max(0, math.min(scrollOff, maxScroll))
            end
            y = y + btn
        end
    end
    return scrollOff
end

local function drawWorldTabStrip(self, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms  -- the scroll arrows need it: without this local the
                          --      drawTriangleUp/Down calls below crashed the
                          --      first time the tab list overflowed.
    local w  = T.px(ACTION_TAB_STRIP_W)
    local h  = self:getHeight()

    self:clearHitZones()

    -- Strip background provided by ZeD_Window body — no redundant fill

    -- The waterfall's inner edge (LEFT, mirrored from the character window): a structure line
    local bs = T.borderS
    self:drawRect(0, 0, T.px(1), h, bs.a, bs.r, bs.g, bs.b)
    local bd = T.border

    local mx, my = self:getMouseX(), self:getMouseY()
    -- the pointer's hover washes stay off while the controller's mark shows
    local Focus = ZeD.Input and ZeD.Input.Focus
    local cuesOn = Focus and Focus.cuesVisible and Focus.cuesVisible(win.playerNum) or false   -- (this window's player's marks)

    -- The controller's focus on the strip, resolved once: only while this window
    -- has the focus and the controller is in use (Focus.liveZone), so the mark
    -- never lingers in the other window or under the mouse. The active tab shows
    -- it too (the mark on a solid element leaves out its wash). (Resolved before
    -- the scroll: a focused tab out of sight scrolls into view.)
    local gpFocusedTabId = nil
    do
        local zone = Focus and Focus.liveZone and Focus.liveZone(win)
        if zone and zone.zone == "worldTabBar" then
            local el = Focus.liveElement(win)
            if el then gpFocusedTabId = el.tabId end
        end
    end

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
        scrollOff = worldTabStripFollow(win, h - arrowRowH, scrollOff, maxScroll, gpFocusedTabId)
        win._actionTabScrollOffset = scrollOff

        local canScrollUp   = scrollOff > 0
        local canScrollDown = scrollOff < maxScroll

        -- Bottom arrow row
        local rowY = h - arrowRowH
        local sep = T.borderS
        self:drawRect(0, rowY, w, T.px(1), sep.a, sep.r, sep.g, sep.b)

        -- the row's inside, two equal halves with the line between, each arrow centred in its half (the director)
        local L, M, M2, R = A.stripArrowHalves(w, "own", "edge")   -- (the tabs: its own line left, the frame just past the right)
        local arrowSz = T.px(5)
        local arY = rowY + T.px(1) + math.floor((arrowRowH - T.px(1) - arrowSz) / 2)
        A.stripArrowLine(self, M, M2, rowY, h)

        -- Up button (left half)
        local hoverUp = canScrollUp and (mx >= L and mx < M and my >= rowY and my < h) and not cuesOn
        if hoverUp then
            local hv = T.hover   -- (the hover wash)
            self:drawRect(L, rowY + T.px(1), M - L, arrowRowH - T.px(1), hv.a, hv.r, hv.g, hv.b)
        end
        local upC = canScrollUp and (hoverUp and T.text or T.textDim) or T.border
        A.drawTriangleUp(self, A.stripArrowX(L, M, arrowSz), arY, arrowSz, upC)
        if canScrollUp then
            self:addHitZone("tab_scroll_up", 0, rowY, M, arrowRowH)
        end

        -- Down button (right half)
        local hoverDn = canScrollDown and (mx >= M2 and mx < w and my >= rowY and my < h) and not cuesOn
        if hoverDn then
            local hv = T.hover   -- (the hover wash)
            self:drawRect(M2, rowY + T.px(1), R - M2, arrowRowH - T.px(1), hv.a, hv.r, hv.g, hv.b)
        end
        local dnC = canScrollDown and (hoverDn and T.text or T.textDim) or T.border
        A.drawTriangleDown(self, A.stripArrowX(M2, R, arrowSz), arY, arrowSz, dnC)
        if canScrollDown then
            self:addHitZone("tab_scroll_down", M2, rowY, w - M2, arrowRowH)
        end
    else
        win._actionTabScrollOffset = 0
        win._tabFollowId = nil   -- the next time the strip scrolls, it brings the active tab into view
    end

    -- Stencil for tab content area (above arrow row)
    local tabAreaH = h - arrowRowH
    self:setStencilRect(0, 0, w, tabAreaH)

    local tabFocusOpts = { win = win, zone = "worldTabBar" }
    local tabDrawOpts = {}

    local curY      = -scrollOff
    local lastGroup = 1

    -- The tab drawn as active: the open tab (a card over its drawer leaves it lit)
    local visualActive = win._activeTab

    for _, tab in ipairs(WORLD_TABS) do
        if not isTabVisible(tab, win) then
            -- If the hidden tab was active, fall back to loot
            if tab.id == win._activeTab then if ZeD_WorldWindow._tabLeft then ZeD_WorldWindow._tabLeft(win) end; win._activeTab = "loot"; lootDrawerFallback(win) end
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
            local isHover  = (mx >= 0 and mx < w and my >= curY and my < curY + T.stripH)

            -- The tabs in lit pixel art (ZeD_TabPx), as in
            -- the character window. The pointer's hover is the T.hover wash; the
            -- controller's focus is the player's focus mark, on the active tab too.
            -- Every tab id has a lit icon.
            -- (the Radio tab draws the TV's picture while a TV set shows on it: tabIcon, punch list 216)
            local TPX = ZeD.TabPx
            local pxId = tab.tv and ZeD_WorldWindow.tabIcon(tab, win) or tab.id
            if TPX and TPX.has(pxId) then
                tabDrawOpts.focus = (gpFocusedTabId == tab.id) and tabFocusOpts or nil
                tabDrawOpts.help = (isHover and my < tabAreaH) and ZeD.tr("UI_ZeD_World_TabHelp", ZeD_WorldWindow.tabLabel(tab, win)) or nil
                TPX.drawTab(self, T.px(1), curY, w - T.px(1), T.stripH - T.px(1), pxId, isActive,
                    isHover and not cuesOn and not isActive, T.px(1), tabDrawOpts)
            end

            -- Bottom border between tabs (a content line, from the waterfall's inner edge)
            self:drawRect(T.px(1), curY + T.stripH - T.px(1), w - T.px(1), T.px(1), bd.a, bd.r, bd.g, bd.b)

            -- Hit zone
            if curY + T.stripH > 0 and curY < tabAreaH then
                self:addHitZone("tab:" .. tab.id, 0, curY, w, T.stripH)
                -- the tab's name in a balloon beside it: after the pause for the mouse, once the pad has rested
                -- on it for the controller's focus (punch list 230)
                if isHover and my < tabAreaH and (not self.isMouseOver or self:isMouseOver()) then
                    win._tabHintCand = { key = "tab:" .. tab.id, text = ZeD_WorldWindow.tabLabel(tab, win),
                                         x = self:getX(), y = self:getY() + curY, w = w, h = T.stripH, side = "l" }
                    ZeD.Atoms.syncHintLayer(win, win._tabHintLayer)
                elseif cuesOn and gpFocusedTabId == tab.id and not win._tabHintCand then
                    win._tabHintCand = { key = "tab:" .. tab.id, text = ZeD_WorldWindow.tabLabel(tab, win),
                                         x = self:getX(), y = self:getY() + curY, w = w, h = T.stripH, side = "l", now = true }
                    ZeD.Atoms.syncHintLayer(win, win._tabHintLayer)
                end
            end

            curY = curY + T.stripH
        end
    end

    self:clearStencilRect()
end

--- The drawer's width for an open object card, in screen px (def: the card's kind; base: the tab's card under it, 0
--- when there is none; heldIn: the window cannot hold the full card beside the inventory's minimum, the tabs' own
--- rule, ZeD_WorldWindow.heldIn). A kind marked half (the padlock, the recipe preview) is the half card, over a wider
--- tab's card as an item card lies; every other kind is the full card, but the half card where the drawer is held in.
--- The one place the object card's drawer width is decided: QA's runs that picture a card at another width (336, 220)
--- set it here, so the drawer itself is that wide and the card still fills it (they once narrowed only the card and
--- left an empty strip before the tabs: object card fill).
--- (QA OC4: at 1280 wide with the inventory open the full card left the inventory 88 units, where a tab's card gives
--- way to the half card. The object card now gives way by the same rule. The director's call OC4, Nov 26 2026)
function ZeD_WorldWindow.objectDrawerW(def, base, heldIn)
    local T = ZeD.T
    -- (held in, only a kind whose body is laid out for the half card gives way: def.halfOk. The hook, placement,
    -- farm, fire, power and hutch bodies still overlap or spill at 220, so they keep the full card until they get
    -- a half layout; the director's call OC4, Nov 26 2026)
    if (def and def.half) or (heldIn and def and def.halfOk) then return math.max(base or 0, T.px(ITEM_CARD_W)) end
    return T.px(OBJECT_CARD_W)
end

--- The object card's width in a drawer effectiveW px wide: the whole drawer, so its scroll bar sits against the tab
--- strip; a half kind over a wider tab's card keeps the half card (the tab shows beside it). (object card fill)
function ZeD_WorldWindow.objectCardW(def, effectiveW)
    if def and def.half then return math.min(effectiveW, ZeD.T.px(ITEM_CARD_W)) end
    return effectiveW
end

--- A tab's card in the World window: the half card or the full card, never a width between
--- (want: the tab's own width; heldIn: the window cannot hold the full card beside the
--- inventory). The radio tab is the full card wherever it fits, but for a half-card device
--- (halfDev: the CD player, RadioTab.halfCard), which is the half card.
function ZeD_WorldWindow.tabCardW(tabId, want, half, full, heldIn, halfDev)
    if heldIn then return half end
    if tabId == "radio" then return halfDev and half or full end
    return (want <= half) and half or full
end

--- The window is capped at half the screen, so on a small screen or a large text size a full card would squeeze the
--- inventory beside it below its minimum: true where the full card (full, screen px) and the inventory's
--- INV_MIN_BESIDE_CARD do not fit together, and the card gives way to the half card, never a width in between.
--- Multi-column Loot lifts the cap, so it is left alone there; with the inventory hidden nothing is held in.
--- (A rolled side (WindowCurtain) keeps the cap: the drawer stays as wide as it was, so a roll and an unroll only take
--- the side away and give it back. Lifting the cap while rolled widened the drawer, shoved the window against the
--- screen edge and left it elsewhere and at another size after the unroll.)
--- One rule for a tab's card and an object card (the director's call OC4, Nov 26 2026).
function ZeD_WorldWindow.heldIn(win, full)
    local T = ZeD.T
    if not (win and win._invDrawerOpen and #(win._mcSelected or {}) == 0) then return false end
    local maxW = win._maxWinW or math.floor(ZeD.screenOf(win) * 0.5)
    return maxW - T.px(CONTAINER_STRIP_W) - T.px(ACTION_TAB_STRIP_W) - T.px(INV_MIN_BESIDE_CARD) < full
end

-- Drawer width dispatch — mode-driven. MC columns live in content, not drawer.
local function getWorldTargetDrawerW(win)
    local T = ZeD.T
    -- Returns SCREEN px (compared against the animated _drawerEffW).
    if win._drawerOpen then
        local half, full = T.px(DRAWER_W), T.px(TAB_DRAWER_W)
        local base = 0
        local heldIn = ZeD_WorldWindow.heldIn(win, full)
        if win._drawerMode == "item" then base = half
        elseif win._drawerMode == "tab" then
            base = T.px(getWorldTabDrawerW(win._activeTab))
            -- The inventory gives way first, down to INV_MIN_BESIDE_CARD (it scrolls anyway); where even that
            -- does not fit with the full card, the tab gets the half card (heldIn, ZeD_WorldWindow.heldIn).
            -- a two-way radio: a walkie's tab is the half card wherever one of its widths fits
            -- it, else the full card; a ham set's is the full card, or the card a walkie's width
            -- fits with the set's narrow face where the drawer is held in. Never a width between the two.
            -- The World window's radio tab is the full card whatever the set (the face centered
            -- in it, RadioTab's renderTwoWay), the half card only where the drawer is held in.
            -- (a table radio once asked for the half card and left the World window's side half
            -- empty; the Character window's radio keeps the face's own width)
            -- The CD player is the half card (the director, Nov 14: "CD player is half card like walkie talkies").
            local halfDev = win._activeTab == "radio" and ZeD.RadioTab and ZeD.RadioTab.halfCard
                and ZeD.RadioTab.halfCard(win, half) or false
            base = ZeD_WorldWindow.tabCardW(win._activeTab, base, half, full, heldIn, halfDev)
        end
        -- the object card needs the full card, over a tab or on its own, but the half card where the drawer is held in
        -- (a kind marked half, the recipe preview, is the half card over the tab's card like an item card)
        if win._drawerObject and win._drawerItem == nil then
            return ZeD_WorldWindow.objectDrawerW(win._drawerObject.def, base, heldIn)
        end
        return base
    end
    return 0
end

-- A drawer that widened the window into the half-screen cap at the screen's edge was pushed
-- left by the engine (setWidth keeps a top-level panel on screen); the animated close gives
-- that push back as the drawer narrows (drawer._onPrerender, _drawerCapPush). A snap to Loot
-- sets the width in one step and never runs that path, so the push stayed and the amount
-- owed was paid out by a later animated close or grew over roll / unroll cycles
-- (the World window sat 4 to 12 px off on the Steam Deck). Every snap settles it here:
-- the window goes back right by what it was pushed, as far as the screen allows, and both
-- counters start clean.
local function settleCapPush(win)
    local pushed = win._drawerCapPush or 0
    if pushed > 0 then
        local room = ZeD.screenOf(win) + ZeD.screenLeftOf(win) - (win:getX() + win:getWidth())
        local back = math.max(0, math.min(pushed, room))
        if back > 0 then win:setX(win:getX() + back) end
    end
    win._drawerCapPush = 0
    win._drawerCapLost = 0
end
-- (also the halves' snapped fold, WindowHalves)
ZeD_WorldWindow.settleCapPush = settleCapPush

-- Scroll dispatch per tab — the scrollbar state the open tab uses, nil for none
local function getWorldActiveScroll(win)
    -- craft/build manage scroll inside their state tables
    if win._activeTab == "craft" and win._craftState then return win._craftState.scroll end
    if win._activeTab == "build" and win._buildState then return win._buildState.scroll end
    if win._activeTab == "maps"   then return nil end  -- map handles zoom, not scroll
    if win._activeTab == "forage" then return win._forageScroll end
    if win._activeTab == "animals" then return win._animalsScroll end
    local ext = ZeD_WorldWindow._extTabs[win._activeTab]
    if ext and ext.scroll then return ext.scroll(win) end
    return nil
end


-- ============================================================================
-- MULTI-CONTAINER HELPERS
-- ============================================================================

-- Dynamic MC capacity: the most extra columns that fit at MIN_COL_W.
-- Columns are a Loot-tab thing; every other tab gets 0.
local function getMcCapacity(win)
    if win._activeTab ~= "loot" then return 0 end
    local R = getR()
    local T = ZeD.T
    -- InventoryRenderer exports MIN_COL_W / COMFORT_COL_W / getXferW as design units
    local minColW = T.px(R.MIN_COL_W or 140)
    local screenW, _, screenL = ZeD.screenOf(win)
    -- Loot tab has no drawer, full space available (to the right edge of the window's screen)
    local availW = screenL + screenW - win:getX() - T.px(CONTAINER_STRIP_W) - T.px(ACTION_TAB_STRIP_W)
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
    local screenW, _, screenL = ZeD.screenOf(win)
    local maxW = screenL + screenW - win:getX() - T.px(10)
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

-- Right-click picks its items the way vanilla's inventory pane does: the row
-- under the cursor becomes the selection unless it is already part of a
-- multi-selection, which is then kept. A stack header or a stack's main row
-- stands for the whole stack. A click on empty space uses the current
-- selection. Returns the menu's items and whether the selection changed.
local function _worldRmbMenuItems(content, x, y, colIdx, colCs)
    local sel = (colCs and colCs.selectedItems) or content._selectedItems
    local stacksTbl = (colCs and colCs.stacks) or content._stacks
    local zone = content:hitZoneAt(x, y)
    local zid = zone and zone.id
    local rep, clicked, whole
    if type(zid) == "string" then
        if zid:sub(1, 6) == "stack:" then
            -- stacks are keyed by their main item, not by the key string
            local key = zid:sub(7)
            for _, info in pairs(stacksTbl or {}) do
                if info and info.key == key then
                    rep, clicked = info.rep or (info.items and info.items[1]), info.items
                    break
                end
            end
            -- (Nov 15 2026, punch list 245: an open stack's header is no item's row; the stack is picked whole)
            if not rep then
                for _, info in ipairs((colCs and colCs.openHeads) or content._openHeads or {}) do
                    if info.key == key then rep, clicked, whole = info.items[1], info.items, true; break end
                end
            end
        end
    elseif zid ~= nil then
        rep = zid
        local stk = stacksTbl and stacksTbl[zid]
        if stk and stk.count > 1 and stk.items then clicked = stk.items else clicked = { zid } end
    end

    local menuItems = {}
    if not rep or not clicked then
        for item in pairs(sel) do menuItems[#menuItems + 1] = item end
        return menuItems, false
    end

    local selCount, clickedInSel = 0, false
    for _ in pairs(sel) do selCount = selCount + 1 end
    for _, it in ipairs(clicked) do
        if sel[it] then clickedInSel = true; break end
    end
    if selCount > 1 and clickedInSel then
        for item in pairs(sel) do menuItems[#menuItems + 1] = item end
        return menuItems, false
    end

    -- Select the clicked row (same bookkeeping as a plain left-click)
    for k in pairs(sel) do sel[k] = nil end
    sel[rep] = true
    if whole then for _, it in ipairs(clicked) do sel[it] = true end end
    if colCs then
        colCs.lastClickedItem = rep
        content._selectedItems = sel
        content._activeCol = colIdx
    end
    content._lastClickedItem = rep
    for _, it in ipairs(clicked) do menuItems[#menuItems + 1] = it end
    return menuItems, true
end

-- The first extra column opens: the object card (unless pinned) and an item
-- card close (a tab's drawer stays), the selection clears, the inventory shows.
local function enterWorldMC(win, content)
    dropObjectCard(win, "a second column opened")
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

-- Back to one list: the columns close, the list shows again, and the window
-- snaps to its base width (an open drawer keeps its own).
exitWorldMC = function(win, content)
    local T = ZeD.T
    win._mcSelected = {}
    win._mainVisible = true
    content._colStates = nil
    content._selectedContainers = nil
    if win._drawerMode ~= "tab" and win._drawerMode ~= "item" and win._drawerMode ~= "object" then
        win._drawerOpen = false
    end
    -- Always snap window to base (prevents width corruption)
    local baseInv = T.px(win._baseInvW or 372)
    local drawerW = math.floor(win._drawerEffW or 0)
    local snapW = T.px(CONTAINER_STRIP_W) + baseInv + drawerW + T.px(ACTION_TAB_STRIP_W)
    win:setWidth(snapW)
end

--- The Loot columns closed, back to one list, as the tab strip closes them on the way to another tab. "Go to saved
--- position" (ZeD_WindowPlaces.lua) starts with it: a place is kept without columns, and one saved on a tab would
--- otherwise open that tab's card beside them.
ZeD_WorldWindow.closeColumns = function(win)
    if #(win._mcSelected or {}) > 0 and win._mainContent then exitWorldMC(win, win._mainContent) end
end

-- Fill the `_switchWorldTabForNav` slot forward-declared above.
-- Assigned here so it has exitWorldMC + getWorldActiveScroll in scope.
-- Mirrors the "different tab" branch of the tab strip's mouse click
-- handler, with the loot-tab special case folded in. Kept parallel to
-- _switchTabForNav in ZeD_CharacterWindow.
_switchWorldTabForNav = function(win, content, tabId)
    if not win or not content or not tabId then return false end
    if win._activeTab == tabId then
        -- (a drawer folded by the pointer keeps its tab selected: A on that tab brings it back)
        if ZeD.Halves and ZeD.Halves.foldedTab and ZeD.Halves.foldedTab(win) == tabId then ZeD.Halves.showAll(win); return true end
        -- A on the tab already open folds it, as a click on it does (the strip's same-tab branch) (QA K2 review)
        if tabId ~= "loot" and win._drawerOpen and win._drawerMode == "tab" then
            if not win._invDrawerOpen then
                win._invDrawerOpen = true
                win._invDrawerTargetW = ZeD.T.px(win._baseInvW or 372)
            end
            if ZeD_WorldWindow._tabLeft then ZeD_WorldWindow._tabLeft(win) end   -- (QA K1 review: K1-9)
            win._activeTab  = "loot"
            win._drawerOpen = false
            win._drawerMode = nil
            win._tabUnder   = nil
            if _syncWorldRingZones then _syncWorldRingZones(win, content) end
            return true
        end
        return false
    end
    local T = ZeD.T
    dropObjectCard(win, "tab switch " .. tostring(tabId))

    if tabId == "loot" then
        -- (a rolled side comes down first: the snap below measures the whole window)
        if win._rolled then ZeD.Curtain.finishUnroll(win) end
        if ZeD_WorldWindow._tabLeft then ZeD_WorldWindow._tabLeft(win) end   -- (QA K1 review: K1-9)
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
        settleCapPush(win)
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
        settleCapPush(win)
    end
    if ZeD_WorldWindow._tabLeft then ZeD_WorldWindow._tabLeft(win) end   -- (QA K1 review: K1-9)
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

-- Snap window width for the column count
local function snapWorldColumns(win)
    local T = ZeD.T
    local colCount = #win._mcSelected + (win._mainVisible and 1 or 0)
    local baseInv = T.px(win._baseInvW or 372)
    local drawerW = math.floor(win._drawerEffW or 0)   -- (an open card keeps its width, as exitWorldMC)
    if colCount >= 2 then
        local _, idealInvW = mcComputeTargetWidthWorld(win, colCount)
        local snapW = T.px(CONTAINER_STRIP_W) + idealInvW + drawerW + T.px(ACTION_TAB_STRIP_W)
        local screenW, _, screenL = ZeD.screenOf(win)
        local maxW = screenL + screenW - win:getX() - T.px(10)
        snapW = math.min(snapW, maxW)
        win:setWidth(snapW)
    else
        local snapW = T.px(CONTAINER_STRIP_W) + baseInv + drawerW + T.px(ACTION_TAB_STRIP_W)
        win:setWidth(snapW)
    end
end

mcToggleWorldContainer = function(win, content, cIdx)
    -- MC only allowed on Loot tab
    if win._activeTab ~= "loot" then return end

    local containers = win._containers
    if not containers[cIdx] then return end

    -- Branch on isFloor, never on `cIdx == _activeContainer`. The
    -- floor (= the "main"/anchor column) has its own toggle semantics — hide
    -- it / auto-fill MC if empty. _activeContainer tracks the user's most
    -- recent view-switch, so as a stand-in for "is this the floor" it sent
    -- every non-floor toggle down this branch, which silently picked
    -- containers[1] as the first MC entry with no way to add more
    -- (subsequent toggles only flipped _mainVisible).
    if containers[cIdx].isFloor then
        -- The floor counts as shown only while it is visible AND the selection
        -- (as main is in the Character window). A click in the world, a pad tap
        -- or a viewed container coming back to Loot can leave a crate as the
        -- selection; reading that as the floor would take the crate's list for
        -- the floor's, and the floor could not be brought back. A press on a
        -- floor that is not shown shows it.
        if win._mainVisible and win._activeContainer == cIdx then
            if #(win._mcSelected) > 0 then
                -- MC active: hide the floor only
                win._mainVisible = false
            else
                -- No MC: auto-select first non-floor container, then hide floor.
                -- The non-floor pick goes by isFloor (an index test against
                -- _activeContainer assumed the active one was the floor).
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
            -- (KISS #10: Ctrl-click or hold A on the Floor while a container is on show alone adds the Floor beside it:
            -- the shown one becomes a column first, so the Floor does not take its place)
            local cur = containers[win._activeContainer]
            if #(win._mcSelected) == 0 and win._mainVisible and cur and not cur.isFloor then
                win._mcSelected[1] = win._activeContainer
                enterWorldMC(win, content)
            end
            if #(win._mcSelected) == 0 then
                content._inventory = containers[cIdx].inventory
                content._selectedItems = {}
                content._lastClickedItem = nil
            end
            win._mainVisible = true
            win._activeContainer = cIdx
            win._viewedContainer = nil
        end
        local selected = win._mcSelected
        if #selected == 0 and win._mainVisible then
            -- floor toggled back to single-only — refresh the ring (no column zones left)
            if _syncWorldRingZones then _syncWorldRingZones(win, content) end
            return
        end
    else
        -- A non-floor container: toggle it in or out of the columns
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
                -- MC fully exited — refresh the ring (the column zones go non-focusable)
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
            -- Dedup _activeContainer if already in _mcSelected,
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

    snapWorldColumns(win)

    -- The column set changed — refresh the ring so the worldMC zones match
    -- the new _mcSelected.
    if _syncWorldRingZones then _syncWorldRingZones(win, content) end
end

-- (KISS #10) A plain click on a container's picture on Loot: that container alone. Any columns close, the list
-- shows it, nothing stays picked. It counts as shown (_mainVisible), so a Ctrl-click or the pad's hold A after it
-- adds a column beside it rather than in its place. A module field, not a local (this file is near Kahlua's limit).
function ZeD_WorldWindow._showAlone(win, content, cIdx)
    if not (win and content and win._containers and win._containers[cIdx]) then return end
    local hadCols = #(win._mcSelected or {}) > 0
    if hadCols and exitWorldMC then exitWorldMC(win, content) end
    win._activeContainer = cIdx
    win._viewedContainer = nil
    win._mainVisible = true
    content._inventory = win._containers[cIdx].inventory
    content._selectedItems = {}
    content._lastClickedItem = nil
    -- (the columns' stops go with them)
    if hadCols and _syncWorldRingZones then _syncWorldRingZones(win, content) end
end

-- ============================================================================
-- PERSISTENCE — save/restore window position + size via modData
-- ============================================================================

local function worldStateOf(win)
    local T  = ZeD.T
    local sc = (T and T.scale) or 1
    -- Persisted geometry is stored in DESIGN UNITS (screen px / T.scale).
    -- _baseInvW already holds design units; x/y/h are screen px and are divided here.
    -- Saves written before the scale system were at scale 1.0, so they read back as-is.
    local invU = win._baseInvW or 372
    -- (a width this screen's fit brought it down to is saved as the width it came from until the player resizes it)
    if T and win._fitFromInvW and win._fitInvW and math.abs(T.px(invU) - T.px(win._fitInvW)) <= 1 then invU = win._fitFromInvW end
    local baseW = CONTAINER_STRIP_W + invU + ACTION_TAB_STRIP_W   -- design units
    return {
        -- the window's own place: a rolled side where it starts unrolled, and a window the engine pushed left
        -- while a full card holds it against the screen's edge where it stands without the push
        -- (the Character window saves its anchor, which a push never moves)
        x = (win:getX() + (win._drawerCapPush or 0) - (win._rolled and win._rollW or 0)) / sc,
        y = win:getY() / sc,
        w = baseW,
        h = ((win.windowShaded and win.preShadeHeight) or win:getHeight()) / sc,   -- (a rolled-up window: its unrolled height)
        -- (a drawer its half folded opens again on its tab, WindowHalves)
        activeTab  = ZeD.Halves.foldedTab(win) or win._activeTab,
        drawerMode = ZeD.Halves.foldedTab(win) and "tab" or ((win._drawerMode ~= "object") and win._drawerMode or nil),
        drawerOpen = ZeD.Halves.foldedTab(win) and true or win._drawerOpen,
        accentKey  = win._accentKey,
    }
end
--- The window's place as the save keeps it (design units, the drawer's tab), for "Save position" (ZeD_WindowPlaces.lua).
ZeD_WorldWindow.stateOf = worldStateOf

local function saveWorldState(win)
    local po = win._playerObj
    if not po then return end
    local md = po:getModData()
    md.ZeD_WinState = md.ZeD_WinState or {}
    md.ZeD_WinState.world = worldStateOf(win)
end

-- The remembered layout is also written while the window is open, about once
-- a second: the game's OnPostSave runs after the save is already on disk, so a
-- Save and Quit with the window open would otherwise lose every move, resize
-- and tab change made since the window last closed.
local function saveWorldStateThrottled(win)
    local now = getTimestampMs()
    if now - (win._lastStateSaveMs or 0) < 1000 then return end
    win._lastStateSaveMs = now
    saveWorldState(win)
end

-- The window kept on the current screen: no taller than the screen (less 20 units), no wider,
-- wholly on it, the half-screen width cap measured again. Run after a restore and on a
-- resolution change (a layout saved on a bigger screen, or a screen
-- made smaller, left the window hanging off the bottom; a drag was clamped, these were not).
-- The screen is the one the window lives on (ZeD.screenOf: sl, st its left and top).
local function fitWorldToScreen(win)
    if not win then return end
    local T = ZeD.T
    local sw, sh, sl, st = ZeD.screenOf(win)
    win._maxWinW = math.floor(sw * 0.5)
    local w, h = win:getWidth(), win:getHeight()
    local maxH = math.max(win.minimumHeight or T.px(220), sh - T.px(20))
    if h > maxH then h = maxH; win:setHeight(h) end
    if w > sw then w = math.max(win.minimumWidth or 0, sw); win:setWidth(w) end
    local x = math.max(sl, math.min(win:getX(), sl + sw - w))
    local y = math.max(st, math.min(win:getY(), st + sh - h))
    if x ~= win:getX() then win:setX(x) end
    if y ~= win:getY() then win:setY(y) end
end
ZeD_WorldWindow.fitToScreen = fitWorldToScreen

local function applyWorldState(win, ws)
    local T = ZeD.T
    local screenW, screenH, screenL, screenT = ZeD.screenOf(win)
    -- Stored values are design units (see saveWorldState). Scale to screen px,
    -- then clamp to the screen (a saved position can land off-screen after a root change).
    local xU = ws.x or 40
    local yU = math.max(0, ws.y or 60)
    -- no wider than this screen's cap either (half the screen): a layout saved on a bigger
    -- screen kept its inventory width
    local capU = math.floor((win._maxWinW or math.floor(screenW * 0.5)) / ((T and T.scale) or 1))
    local wU = math.max(CONTAINER_STRIP_W + 200 + ACTION_TAB_STRIP_W, math.min(ws.w or 464, capU))   -- design units
    local x = T.px(xU)
    local y = T.px(yU)
    local w = T.px(wU)
    local h = math.max(win.minimumHeight or T.px(220), math.min(T.px(ws.h or 600), screenH - T.px(20)))
    if y + h > screenT + screenH then y = math.max(screenT, screenT + screenH - h) end
    -- Where not even the smallest inventory fits beside a full card at the kept (left) edge, the saved 444-unit width
    -- would be clamped wider than the window was: use the fresh-open width, measured from the kept edge BEFORE the
    -- clamp pulls the window left (QA B9-2)
    local preFrom, preTo
    if ZeD.Scale and ZeD.Scale.fitInvW then
        local _, noRoom = ZeD.Scale.fitInvW(T, math.min(win._maxWinW or math.floor(screenW * 0.5), screenL + screenW - x), CONTAINER_STRIP_W + ACTION_TAB_STRIP_W)
        if noRoom then
            local freshU = ZeD.Scale.fitInvW(T, math.min(win._maxWinW or math.floor(screenW * 0.5), screenW - (math.floor(screenW / 2) + T.px(5))), CONTAINER_STRIP_W + ACTION_TAB_STRIP_W)
            if type(freshU) == "number" and wU - CONTAINER_STRIP_W - ACTION_TAB_STRIP_W > freshU then
                preFrom, preTo = wU - CONTAINER_STRIP_W - ACTION_TAB_STRIP_W, freshU
                wU = CONTAINER_STRIP_W + freshU + ACTION_TAB_STRIP_W
                w = T.px(wU)
            end
        end
    end
    x = math.max(screenL, math.min(x, screenL + screenW - w))
    -- a saved width wider than this screen lets a full card open beside it without shifting: the fitting width
    -- (ZeD.Scale.fitInvW; the director, Nov 11 2026; the window grows right, so its left edge stays)
    local fitU = ZeD.Scale and ZeD.Scale.fitInvW and
        ZeD.Scale.fitInvW(T, math.min(win._maxWinW or math.floor(screenW * 0.5), screenL + screenW - x), CONTAINER_STRIP_W + ACTION_TAB_STRIP_W)
    win._fitInvW, win._fitFromInvW = nil, nil
    if type(fitU) == "number" and wU - CONTAINER_STRIP_W - ACTION_TAB_STRIP_W > fitU then
        win._fitFromInvW, win._fitInvW = wU - CONTAINER_STRIP_W - ACTION_TAB_STRIP_W, fitU
        wU = CONTAINER_STRIP_W + fitU + ACTION_TAB_STRIP_W
        w = T.px(wU)
    end
    -- (narrowed before the clamp above: the saved width is still the one it came from) (QA B9-2)
    if preTo then win._fitFromInvW, win._fitInvW = preFrom, preTo end
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
    fitWorldToScreen(win)         -- (and the window's own minimums against the screen)
    -- (pushed off its kept place to stay on screen: then it may sit on the Character window; the two are spread
    -- apart, ZeD_CharacterWindow.unpilePair) (QA B5-7)
    win._restorePushed = win:getX() ~= T.px(xU) or nil
    if ZeD_CharacterWindow and ZeD_CharacterWindow.unpilePair then ZeD_CharacterWindow.unpilePair(win) end

    -- Restore active tab
    if ws.activeTab then
        win._activeTab = ws.activeTab
    end

    -- Restore drawer state (tab drawer reopens where it was)
    if ws.drawerMode == "tab" and ws.drawerOpen and win._activeTab ~= "loot" then
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
--- A kept place put back on the open window, clamped to this screen ("Go to saved position", ZeD_WindowPlaces.lua).
ZeD_WorldWindow.applyState = applyWorldState

local function restoreWorldState(win, playerObj)
    local md = playerObj:getModData()
    local ws = md.ZeD_WinState and md.ZeD_WinState.world
    if ws then applyWorldState(win, ws) end
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

--- A general hook for other mods (ExtraContainers.lua): fn(playerObj, list)
--- returns more containers for the strip ({ container = ItemContainer, item,
--- parentItem, name, texture }); each gets a button and a column like a
--- container in reach. `list` carries the window's own fields (isFloor, locked,
--- sourceType). A second call with the same id replaces the first.
function ZeD_WorldWindow.addContainerProvider(id, fn)
    ZeD.ExtraContainers.add("world", id, fn)
end

--- A general hook for other mods (StripDecorators.lua): fn(panel, entry, x, y,
--- w, h, win) is called after each strip button's icon is drawn (the floor's
--- too), with the window's entry (entry.inventory) and the button's rectangle,
--- to mark it (a fill bar, a badge). A second call with the same id replaces
--- the first.
function ZeD_WorldWindow.addStripDecorator(id, fn)
    ZeD.StripDecorators.add("world", id, fn)
end

local function buildWorldContainers(playerObj)
    local containers = {}

    -- Floor container: the ground items around the player. It is vanilla's own
    -- floor container (ISInventoryPage.GetFloorContainer), filled the way its
    -- loot window fills it. An item belongs to one container at a time, so a
    -- second floor container of ZeD's would steal the items back and forth
    -- with vanilla's hidden loot window, and a transfer queued from one would
    -- find its item gone. Sharing vanilla's lets floor moves be vanilla's own
    -- transfer action, which in multiplayer is the server's item transaction.
    local floorPn = playerObj:getPlayerNum()
    local floorC = _floorContainers[floorPn]
    if not floorC then
        if ISInventoryPage and ISInventoryPage.GetFloorContainer then
            floorC = ISInventoryPage.GetFloorContainer(floorPn)
        else
            floorC = ItemContainer.new("floor", nil, nil)
        end
        _floorContainers[floorPn] = floorC
    end
    floorC:removeItemsFromProcessItems()
    floorC:clear()

    local cx = math.floor(playerObj:getX())
    local cy = math.floor(playerObj:getY())
    local cz = math.floor(playerObj:getZ())
    local currentSq = playerObj:getCurrentSquare()

    local vehicleSeen = {}  -- dedup vehicles across tiles

    -- Seated in a vehicle: like vanilla's loot window (ISInventoryPage.refreshBackpacks' seated branch),
    -- list only that car's containers the seat can reach and the bags in them, the truck bed last.
    -- No 3x3 scan (no floor items, furniture or corpses beside the car, no filling unexplored ones as
    -- you drive past). No Floor either: seated, the list is the car's alone (KISS #13). (beast W5)
    local seatedIn = playerObj:getVehicle()
    if seatedIn then
        for pass = 1, 2 do   -- pass 1: every part but the truck bed; pass 2: the truck bed
            for pi = 0, seatedIn:getPartCount() - 1 do
                local part = seatedIn:getPartByIndex(pi)
                if part and part:getItemContainer() and seatedIn:canAccessContainer(pi, playerObj)
                   and ((part:getId() == "TruckBed") == (pass == 2)) then
                    local pCont = part:getItemContainer()
                    local pType = tostring(pCont:getType())
                    containers[#containers + 1] = {
                        inventory = pCont,
                        name = getTextOrNull("IGUI_VehiclePart" .. pType) or part:getCategory() or "Vehicle",
                        texture = resolveContainerIcon(pType)
                              or resolveContainerIcon(tostring(part:getId())) or resolveContainerIcon(part:getCategory() or ""),
                        isFloor = false,
                        sourceType = "vehicle",
                        partId = part:getId(),   -- (the glove box is where the list lands seated) (KISS #13)
                    }
                    -- the bags on the seats and in the trunk (not the glove box's), as vanilla
                    if part:getId() and part:getId() ~= "GloveBox" then
                        local pItems = pCont:getItems()
                        for bi = 0, pItems:size() - 1 do
                            local bag = pItems:get(bi)
                            if bag and bag:getCategory() == "Container" then
                                containers[#containers + 1] = {
                                    inventory = bag:getInventory(),
                                    name = bag:getName(),
                                    texture = bag:getTex(),
                                    isFloor = false,
                                    sourceType = "vehicle_container",
                                }
                            end
                        end
                    end
                end
            end
        end
    else
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
                                floorC:AddItem(item)
                                -- Item-containers on the ground (dropped backpacks)
                                if item:getCategory() == "Container" then
                                    containers[#containers + 1] = {
                                        inventory = item:getInventory(),
                                        name = item:getName(),
                                        texture = item:getTex(),
                                        isFloor = false,
                                        sourceType = "ground_container",
                                        sq = gs,   -- (the square it is on: the one he faces shows first) (KISS #13)
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
                                    local corpseType = "inventorymale"
                                    local desc = instanceof(so, "IsoDeadBody") and so:getDescription() or nil
                                    if desc and desc.isFemale and pcall(function() if desc:isFemale() then corpseType = "inventoryfemale" end end) then end
                                    -- a nameless body is titled by vanilla's own word for it ("Corpse")
                                    local title = getText("IGUI_ContainerTitle_" .. corpseType)
                                    if instanceof(so, "IsoDeadBody") then
                                        -- The player's own corpse (and some B42 bodies) hands
                                        -- back a description without getForename/getSurname — this
                                        -- threw "Object tried to call nil" every frame after a death.
                                        pcall(function()
                                            local desc = so:getDescription()
                                            if desc and desc.getForename and desc.getSurname then
                                                local fore, sur = desc:getForename(), desc:getSurname()
                                                if fore and sur then title = fore .. " " .. sur end
                                            end
                                        end)
                                    end
                                    containers[#containers + 1] = {
                                        inventory = so:getContainer(),
                                        name = title,
                                        texture = resolveContainerIcon(corpseType),
                                        isFloor = false,
                                        sourceType = "corpse",
                                        sq = gs,   -- (KISS #13)
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
                                        -- a container renamed the game's way shows its own name (ISInventoryPage) (L1-7)
                                        local custom = container.getCustomName and container:getCustomName()
                                        if custom then title = custom end

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
                                            sq = gs,   -- (KISS #13)
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
                                -- vanilla's name for the container (Trunk, Food Container...)
                                local partName = getTextOrNull("IGUI_VehiclePart" .. tostring(part:getItemContainer():getType()))
                                                 or part:getCategory() or "Vehicle"
                                local vehType = part:getCategory() or ""
                                containers[#containers + 1] = {
                                    inventory = part:getItemContainer(),
                                    name = partName,
                                    texture = resolveContainerIcon(tostring(part:getItemContainer():getType()))
                                          or resolveContainerIcon(tostring(part:getId())) or resolveContainerIcon(vehType),
                                    isFloor = false,
                                    sourceType = "vehicle",
                                    sq = gs,   -- (KISS #13)
                                }
                                -- Bags on the seats and in the trunk get a button of their own,
                                -- as in vanilla's loot window (not the glove box's)
                                if part:getId() and part:getId() ~= "GloveBox" then
                                    local pItems = part:getItemContainer():getItems()
                                    for bi = 0, pItems:size() - 1 do
                                        local bag = pItems:get(bi)
                                        if bag and bag:getCategory() == "Container" then
                                            containers[#containers + 1] = {
                                                inventory = bag:getInventory(),
                                                name = bag:getName(),
                                                texture = bag:getTex(),
                                                isFloor = false,
                                                sourceType = "vehicle_container",
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end   -- (the seated branch above) (beast W5)

    -- Floor container always last in the list (the strip draws it pinned at the top). Seated, none: the Floor beside
    -- a car is always empty, and the list lands on the glove box or his seat instead (KISS #13). The strip, its
    -- stops and the columns all test isFloor, so a list with no Floor draws the car's buttons alone.
    if not seatedIn then
        containers[#containers + 1] = {
            inventory = floorC,
            name = getTextOrNull("IGUI_ContainerTitle_floor") or "Floor",
            texture = resolveContainerIcon("floor"),
            isFloor = true,
            sourceType = "floor",
        }
    end

    -- other mods' containers (ExtraContainers.lua): each one placed after the
    -- container it is carried in; the floor stays last
    return ZeD.ExtraContainers.merge("world", playerObj, containers)
end


-- ============================================================================
-- CONTAINER STRIP — LEFT EDGE (mirrored from character window's right edge)
-- Floor pinned top, sort row, scrollable container list below.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- (KISS #13) THE CONTAINER HE FACES SHOWS, as the game's loot page does (ISInventoryPage.refreshBackpacks):
--   * seated: the glove box, else his own seat's container, else the car's first (there is no Floor seated);
--   * on foot: the first container on the square he faces (the game's lookSquare, one step along getDir), else
--     the first one in reach that is not locked, else the Floor.
-- Returns an index into win._containers. faceOnly: only the faced square counts (nil when nothing is on it), for
-- the turn rule in the strip's refresh. A field on the module table, not a local: this file is near Kahlua's limit.
-- ----------------------------------------------------------------------------
function ZeD_WorldWindow._pickShown(win, playerObj, faceOnly)
    local list = win._containers or {}
    if not playerObj then return #list > 0 and #list or nil end
    local veh = playerObj:getVehicle()
    if veh then
        if faceOnly then return nil end
        -- his seat's own container (the game's way to it: ISWorldObjectContextMenu, the seat UI)
        local seatInv = nil
        pcall(function()
            local part = veh:getPartForSeatContainer(veh:getSeat(playerObj))
            seatInv = part and part:getItemContainer() or nil
        end)
        local glove, seat = nil, nil
        for i, c in ipairs(list) do
            if c.partId == "GloveBox" and not glove then glove = i end
            if seatInv and c.inventory == seatInv then seat = i end
        end
        return glove or seat or (#list > 0 and 1 or nil)
    end
    -- the square he faces: one step along his direction, as the game's lookSquare
    local dir = playerObj:getDir()
    local dx, dy = 0, 0
    if dir == IsoDirections.NW or dir == IsoDirections.W or dir == IsoDirections.SW then dx = -1 end
    if dir == IsoDirections.NE or dir == IsoDirections.E or dir == IsoDirections.SE then dx = 1 end
    if dir == IsoDirections.NW or dir == IsoDirections.N or dir == IsoDirections.NE then dy = -1 end
    if dir == IsoDirections.SW or dir == IsoDirections.S or dir == IsoDirections.SE then dy = 1 end
    local lookSq = getCell():getGridSquare(math.floor(playerObj:getX()) + dx, math.floor(playerObj:getY()) + dy,
                                           math.floor(playerObj:getZ()))
    for i, c in ipairs(list) do
        if lookSq and c.sq == lookSq and not c.locked and not c.isFloor then return i end
    end
    if faceOnly then return nil end
    for i, c in ipairs(list) do
        if not c.isFloor and not c.locked then return i end
    end
    return #list > 0 and #list or nil   -- (the Floor, always last)
end

-- A container viewed from another tab (a strip click there sets
-- win._viewedContainer) wins over the list's selection, but only while the
-- selection is still the container it was picked over (win._viewedOver, by
-- the object): however the selection moves, the view ends with it. (Ended by
-- nothing but that strip, the title and the rows would stay on the viewed
-- container until the window closed.) Back on Loot, where the strip selects,
-- the viewed container becomes the selection, so the list stays where it is
-- and the strip lights its button.
local function _holdWorldView(win)
    local view = win._viewedContainer
    if not view then return end
    local list = win._containers
    local viewed, active = list[view], list[win._activeContainer]
    if viewed and win._activeTab == "loot" then
        win._activeContainer = view
        win._mainVisible = true   -- (KISS #10, as a plain click)
        win._viewedContainer, win._viewedOver = nil, nil
    elseif not viewed or not active or active.inventory ~= win._viewedOver then
        win._viewedContainer, win._viewedOver = nil, nil
        -- (the list moves off the view's container: nothing stays selected there, unseen)
        local content = win._mainContent
        if content and not (viewed and active and viewed.inventory == active.inventory) then
            content._selectedItems = {}
            content._lastClickedItem = nil
        end
    end
end

local function drawWorldContainerStrip(self, win, content)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local w  = T.px(CONTAINER_STRIP_W)
    local h  = self:getHeight()

    self:clearHitZones()
    _holdWorldView(win)

    -- The controller's focus on the strip: the button the ring focuses in this
    -- zone, only while this window has the focus and the controller is in use
    -- (Focus.liveZone), so nothing stays lit in the other window or under the
    -- mouse. Its mark shows on a selected container too (selected is a 0.30 wash).
    local gpFocusedCI = nil
    local cuesOn = false
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local zone = Focus and Focus.liveZone and Focus.liveZone(win)
        if zone and zone.zone == "worldContainerStrip" then
            local el = Focus.liveElement(win)
            if el then gpFocusedCI = el.containerIdx end
        end
        cuesOn = Focus and Focus.cuesVisible and Focus.cuesVisible(win.playerNum) or false   -- (this window's player's marks)
    end
    local stripFocus = { win = win, zone = "worldContainerStrip" }
    local selA = T.selectionA or 0.30

    -- Periodic container refresh. By the clock, not the frame count (30
    -- frames would run it 2.4 times as often at 144 Hz as at 60): every WREF.ms, and
    -- sooner (WREF.soonMs after the last) when the player's square changes or a container changed (OnContainerUpdate).
    -- win._containerTimer stays the window's signal: others set it to 30 for a refresh on the next frame, and it is 0
    -- on the frame the list was rebuilt (the strip's sort reads that).
    local nowMs = getTimestampMs()
    local plSq = win._playerObj and win._playerObj:getCurrentSquare()
    local forced = (win._containerTimer or 0) >= 30
    local due = forced or nowMs >= (win._containerDueMs or 0)
    -- (a turn reads the list again too: the container he now faces shows, KISS #13)
    local plDir = win._playerObj and win._playerObj:getDir()
    if not due and (plSq ~= win._containerSq or win._containersDirty or plDir ~= win._lookDir) then
        due = nowMs - (win._containerAtMs or 0) >= WREF.soonMs
    end
    if not due then
        win._containerTimer = 1
    else
        win._containerTimer = 0
        win._containerAtMs, win._containerDueMs = nowMs, nowMs + WREF.ms
        win._containerSq, win._containersDirty = plSq, nil
        local oldContainers = win._containers
        win._containers = buildWorldContainers(win._playerObj)

        -- Remap _activeContainer by inventory identity (not raw index)
        local oldActive = oldContainers and oldContainers[win._activeContainer]
        -- (gone, the container he faces or the first in reach shows, not the Floor: KISS #13)
        local newActiveIdx = ZeD_WorldWindow._pickShown(win, win._playerObj) or #win._containers
        local activeGone = oldActive ~= nil
        if oldActive then
            for i, c in ipairs(win._containers) do
                if c.inventory == oldActive.inventory then
                    newActiveIdx = i
                    activeGone = false
                    break
                end
            end
        end
        -- (KISS #13) As the game's page: a turn shows the first container on the square he now faces, and a list
        -- that was the Floor alone shows the first container that comes into reach. Not while columns are open
        -- (his own layout), nor while he works (a move turns him to its container, ISInventoryTransferAction: the
        -- turn is taken as seen, so the list holds still under the move).
        do
            local faceDir = win._playerObj and win._playerObj:getDir()
            local turned = faceDir ~= win._lookDir
            win._lookDir = faceDir
            local busy = win._playerObj and ((ISTimedActionQueue and ISTimedActionQueue.isPlayerDoingAction
                and ISTimedActionQueue.isPlayerDoingAction(win._playerObj)) or win._playerObj:shouldBeTurning())
            if #(win._mcSelected or {}) == 0 and not busy then
                local pick = nil
                if turned then pick = ZeD_WorldWindow._pickShown(win, win._playerObj, true) end
                if not pick and oldActive and oldActive.isFloor and oldContainers and #oldContainers == 1
                   and #win._containers > 1 then
                    pick = ZeD_WorldWindow._pickShown(win, win._playerObj)
                end
                if pick and pick ~= newActiveIdx then
                    newActiveIdx = pick
                    win._mainVisible = true
                    content._selectedItems = {}
                    content._lastClickedItem = nil
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

        -- The selected container out of reach with no column open: the floor it fell back to lists, so it is the one lit
        if activeGone and #newSelected == 0 then
            win._mainVisible = true
            content._selectedItems = {}
            content._lastClickedItem = nil
        end

        -- The list viewed from another tab stays on its container too, by the object; a container gone ends the view
        local oldView = oldContainers and win._viewedContainer and oldContainers[win._viewedContainer]
        win._viewedContainer = nil
        if oldView then
            for i, c in ipairs(win._containers) do
                if c.inventory == oldView.inventory then
                    win._viewedContainer = i
                    break
                end
            end
            if not win._viewedContainer then
                content._selectedItems = {}
                content._lastClickedItem = nil
            end
        end

        -- Re-sync active inventory
        local activeCnt = win._containers[win._activeContainer]
        if activeCnt then
            content._inventory = activeCnt.inventory
        end

        -- Refresh world radios in player range + clamp browse index.
        -- Wave cache prunes against the new key set (entry.cacheKey is built
        -- from world coords by RadioTab.buildWorldRadios — stable identity).
        -- The radios (the same 9 squares) are read with the list while the
        -- Radio tab is open and on every new square, else every WREF.sideMs; the vehicles (every vehicle in the cell)
        -- while the Vehicle tab is open, else every WREF.sideMs or WREF.ms after the last on a new square. Both tabs
        -- show only while there is one (WORLD_TABS' visible), and the vehicle read ends inspections out of reach.
        local sideAge = nowMs - (win._sideScanAtMs or 0)
        local sideDue = forced or sideAge >= WREF.sideMs
            or (plSq ~= win._sideScanSq and sideAge >= WREF.ms)
        if sideDue then win._sideScanAtMs, win._sideScanSq = nowMs, plSq end
        if sideDue or win._activeTab == "radio" or plSq ~= win._radioSq then
            win._radioSq = plSq
            win._radios = ZeD.RadioTab.buildWorldRadios(win._playerObj)
        end
        -- Vehicles in reach for the Vehicle tab
        if (sideDue or win._activeTab == "vehicle") and ZeD.MechanicsTab and ZeD.MechanicsTab.refresh then
            pcall(ZeD.MechanicsTab.refresh, win)
        end
        if #win._radios == 0 then
            win._radioIdx = 1
        elseif win._radioIdx > #win._radios then
            win._radioIdx = #win._radios
        end
        -- (Nov 14 2026, punch list 207a: the side strip's stops were built once with the ring, so a tab that shows
        -- later (Radio, Vehicle) had no stop and Down stopped at Animals. Rebuild them when the shown tabs change.)
        local key = ""
        if WORLD_TABS and isTabVisible then
            for _, tab in ipairs(WORLD_TABS) do if isTabVisible(tab, win) then key = key .. tab.id .. "," end end
        end
        if key ~= "" and key ~= win._tabBarKey and win._focusRing and _buildWorldTabBarElements
           and ZeD.Input and ZeD.Input.Focus then
            win._tabBarKey = key
            local els = _buildWorldTabBarElements(win)
            _attachWorldTabBarCallbacks(win, els)
            pcall(ZeD.Input.Focus.setRingZoneElementsKeepId, win, "worldTabBar", els)
        end
    end

    local containers = win._containers
    local mx, my = self:getMouseX(), self:getMouseY()
    local font   = T.fontF1
    local fontH  = ZeD.TM:getFontHeight(font)
    local iconSz = T.px(CONTAINER_BTN_SZ - 14)  -- 22px icon in 36px cell (design units)

    -- Strip background provided by ZeD_Window body — no redundant fill
    -- The strip's inner edge (RIGHT, mirrored from the character window): a
    -- structure line; the lines between buttons are content lines
    local bs = T.borderS
    self:drawRect(w - T.px(1), 0, T.px(1), h, bs.a, bs.r, bs.g, bs.b)
    local bd = T.border

    -- --------------------------------------------------------
    -- ZONE 1: Floor container pinned at top (always last in containers[])
    -- --------------------------------------------------------
    local floorIdx = #containers
    local floorCnt = containers[floorIdx]
    local curY = 0
    -- the floor cell and the line under it are row 1 (T.stripH), level with the tab's header
    local floorH = T.stripH - T.px(1)
    if floorCnt and floorCnt.isFloor then
        local isActive = (win._activeContainer == floorIdx)
        local isMC = false
        for _, ci in ipairs(win._mcSelected or {}) do
            if ci == floorIdx then isMC = true; break end
        end

        local isHover = (mx >= 0 and mx < w and my >= curY and my < curY + floorH) and not cuesOn
        -- Zone 1 is "on" when: main visible (loot MC), or inventory open showing floor (non-loot)
        local mainVis
        if win._activeTab == "loot" then
            mainVis = win._mainVisible
        else
            mainVis = win._invDrawerOpen and (win._viewedContainer == nil)
        end
        -- the one selected look (the shown container), the hover wash, then the controller's mark
        local floorOn = mainVis and (isActive or isMC)
        -- (on the button's tint of its picture's color, with a one-hairline frame when shown: the director, Nov 25 2026)
        local cL, _, _, cR = A.stripArrowHalves(w, "frame", "own")
        -- (the button's fill and the shown one's frame inside the strip's own lines, the insets its scroll row uses:
        -- the frame's right side lay half under the right line, 2 px of its 4 at 4K, QA ctab3, Nov 25 2026)
        ZeD.GridTint.stripCell(self, cL, curY, cR - cL, floorH, floorCnt.texture or ZeD.genericContainerTex(), floorOn, isHover)
        if isHover then ZeD.Help.set(self, ZeD.tr("UI_ZeD_World_FloorHelp")) end
        local onFocusF = false
        if gpFocusedCI == floorIdx then
            stripFocus.solid = floorOn and true or false   -- (on the lit panel the mark leaves out its wash, as on a lit tab)
            onFocusF = ZeD.Focus.mark(self, 0, curY, w - T.px(1), floorH, stripFocus)
        end

        local iconAlpha = mainVis and 1 or 0.5
        local tex = floorCnt.texture or ZeD.genericContainerTex()
        if tex then
            local ix = math.floor((w - iconSz) / 2)
            local iy = curY + math.floor((floorH - iconSz) / 2)
            self:drawTextureScaledAspect(tex, ix, iy, iconSz, iconSz, iconAlpha, 1, 1, 1)
        else
            local glyph = "F"
            local gw = ZeD.TM:MeasureStringX(font, glyph)
            local gx = math.floor((w - gw) / 2)
            local gy = curY + math.floor((floorH - fontH) / 2)
            local color = onFocusF and T.textOnFocus or (mainVis and (floorOn and T.text or T.textSec) or T.textDim)
            self:drawText(glyph, gx, gy, color.r, color.g, color.b, color.a, font)
        end

        -- other mods' marks on the button (StripDecorators.lua); before the badge below so the badge stays on top
        ZeD.StripDecorators.run(self, win, "world", floorCnt, 0, curY, w - T.px(1), floorH)
        -- MC badge for floor when shown as a column in MC mode.
        -- Floor is at the LAST colSel position when mainVisible=true, so its
        -- badge = #_mcSelected + 1. Doesn't appear in _mcSelected itself
        -- (floor toggle = visibility, not membership), so position derived
        -- from mcCount instead of lookup.
        local mcCountF = #(win._mcSelected or {})
        -- (only while the Floor is the shown one: a crate shown with columns beside it carries the number, KISS #10)
        if mainVis and isActive and mcCountF > 0 then
            local badge = tostring(mcCountF + 1)
            local bx = T.px(4)
            local by = curY + floorH - fontH - T.px(1)
            local bc = onFocusF and T.textOnFocus or T.text
            self:drawText(badge, bx, by, bc.r, bc.g, bc.b, bc.a, font)
        end

        self:addHitZone(floorIdx, 0, curY, w, floorH)
        curY = curY + floorH
    end

    -- Divider below floor
    A.drawDividerH(self, 0, curY, w, true)
    curY = curY + T.px(1)

    local sortMode = win._containerSortMode or "dist"

    -- --------------------------------------------------------
    -- ZONE 2: Sort mode label — aligned with column header bar
    -- Cycles: dist → wt → type → dist
    -- --------------------------------------------------------
    -- row 2, the sort bar (T.sortBarH), its word in the sort font: level with the inventory's column header
    local colHdrH     = T.sortBarH
    local sortRowY    = curY
    local sortRowH    = colHdrH
    local f5Font      = T.sortFont
    local f5H         = ZeD.TM:getFontHeight(f5Font)
    local isActive    = sortMode ~= "dist"
    local sortLabel   = ZeD.textCase(ZeD.tr(sortMode == "wt" and "UI_ZeD_World_SortWt" or sortMode == "type" and "UI_ZeD_World_SortType" or "UI_ZeD_World_SortDist"))
    local labelW      = ZeD.TM:MeasureStringX(f5Font, sortLabel)
    local isSortHover = (mx >= 0 and mx < w and my >= sortRowY and my < sortRowY + sortRowH) and not cuesOn

    -- the header row's surface (one layer over the body); an order other than
    -- distance shows as its underlined word, the pointer as the hover wash
    ZeD.Surface.fill(self, 0, sortRowY, w - T.px(1), sortRowH, "surf2")
    if isSortHover then
        local hv = T.hover
        self:drawRect(0, sortRowY, w - T.px(1), sortRowH, hv.a, hv.r, hv.g, hv.b)
        ZeD.Help.set(self, ZeD.tr("UI_ZeD_World_SortHelp"))
    end
    local sortColor = isActive and T.toneNorm or T.toneLo
    local labelX = math.floor((w - labelW) / 2)
    local labelY = sortRowY + math.floor((sortRowH - f5H) / 2)
    -- (QA's visual noise audit 23, Nov 20 2026: "Dist" read as a column head over the buttons; the usual order says
    -- nothing, its word shows while the pointer is on the row. The row still takes the click and gives its help.)
    if isActive or isSortHover then
        self:drawText(sortLabel, labelX, labelY, sortColor.r, sortColor.g, sortColor.b, sortColor.a, f5Font)
    end
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
    -- Sorted again only when the list just refreshed (every 30 frames, above),
    -- was replaced or the sort mode changed, not every frame ("dist" = natural order)
    local listEntries = _worldStripListOrder(win, win._containerTimer == 0)

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
    -- Where the buttons sit (panel-local), for the controller's stops
    -- (_buildWorldLootFocusables)
    do
        local L = win._stripLay or {}
        win._stripLay = L
        L.floorIdx = (floorCnt and floorCnt.isFloor) and floorIdx or nil
        L.listY, L.listH, L.scroll, L.entries = listStartY, listAreaH, scrollOff, listEntries
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
        -- (with columns open and the anchor column hidden, the selection does not show, so it is not lit)
        local isActive = (ci == win._activeContainer) and (#(win._mcSelected or {}) == 0 or win._mainVisible)
        local isViewed = (ci == win._viewedContainer)
        local isOn = isMC or isActive or isViewed
        if cnt and drawY + T.px(CONTAINER_BTN_SZ) > listStartY and drawY < listStartY + listAreaH then
            local isHover = (mx >= 0 and mx < w and my >= drawY and my < drawY + T.px(CONTAINER_BTN_SZ))
                            and my >= listStartY and my < listStartY + listAreaH and not cuesOn

            -- One selected look for a shown container (active, viewed, or one of
            -- the Loot tab's columns): the T.selectionA wash; else the hover wash.
            -- The controller's mark goes on after, so it shows on a selected one.
            -- (on the button's tint of its picture's color: ZeD.GridTint.stripCell, the director, Nov 25 2026)
            local cL, _, _, cR = A.stripArrowHalves(w, "frame", "own")
            ZeD.GridTint.stripCell(self, cL, drawY, cR - cL, T.px(CONTAINER_BTN_SZ),
                cnt.texture or ZeD.genericContainerTex(), isOn, isHover)
            if isHover then
                ZeD.Help.set(self, ZeD.tr(cnt.locked and "UI_ZeD_World_LockedHelp" or "UI_ZeD_World_ContainerHelp", cnt.name or ""))
            end
            local onFocusC = false
            if gpFocusedCI == ci then
                stripFocus.solid = isOn and true or false
                onFocusC = ZeD.Focus.mark(self, 0, drawY, w - T.px(1), T.px(CONTAINER_BTN_SZ), stripFocus)
            end

            -- (a locked container: its dim icon and the padlock below say it, on the same tint as any other)

            -- Icon (the game's own box when it has none of its own; ZeD.genericContainerTex)
            local tex = cnt.texture or ZeD.genericContainerTex()
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
                local color = onFocusC and T.textOnFocus or (isOn and T.text or (cnt.locked and T.textDim or T.textSec))
                self:drawText(glyph, gx, gy, color.r, color.g, color.b, color.a, font)
            end
            -- other mods' marks on the button (StripDecorators.lua); before the padlock and badge so they stay on top
            ZeD.StripDecorators.run(self, win, "world", cnt, 0, drawY, w - T.px(1), T.px(CONTAINER_BTN_SZ))
            -- a small padlock in the corner says why the button is dim
            if cnt.locked then
                local dg = T.danger
                local lx = w - T.px(1) - T.px(11)
                local ly = drawY + T.px(CONTAINER_BTN_SZ) - T.px(13)
                local p1 = T.px(1)
                self:drawRect(lx + T.px(2), ly, T.px(5), p1 * 2, 1, dg.r, dg.g, dg.b)
                self:drawRect(lx + T.px(1), ly + p1, p1 * 2, T.px(4), 1, dg.r, dg.g, dg.b)
                self:drawRect(lx + T.px(6), ly + p1, p1 * 2, T.px(4), 1, dg.r, dg.g, dg.b)
                self:drawRect(lx, ly + T.px(4), T.px(9), T.px(6), 1, dg.r, dg.g, dg.b)
            end

            -- MC column badge number (bottom-left corner, mirrored from char window)
            -- (the container on show with columns beside it is the last column, as the Floor's badge, KISS #10)
            local mcCountL = #(win._mcSelected or {})
            if isActive and not isMC and win._activeTab == "loot" and mcCountL > 0 then
                local bc = onFocusC and T.textOnFocus or T.text
                self:drawText(tostring(mcCountL + 1), T.px(4), drawY + T.px(CONTAINER_BTN_SZ) - fontH - T.px(1),
                              bc.r, bc.g, bc.b, bc.a, font)
            end
            if isMC then
                local mcIdx = nil
                for mi, mci in ipairs(win._mcSelected or {}) do
                    if mci == ci then mcIdx = mi; break end
                end
                if mcIdx then
                    local badge = tostring(mcIdx)
                    local bx = T.px(4)
                    local by = drawY + T.px(CONTAINER_BTN_SZ) - fontH - T.px(1)
                    local bc = onFocusC and T.textOnFocus or T.text
                    self:drawText(badge, bx, by, bc.r, bc.g, bc.b, bc.a, font)
                end
            end

            -- Bottom divider (a content line, up to the strip's inner edge)
            self:drawRect(0, drawY + T.px(CONTAINER_BTN_SZ) - T.px(1), w - T.px(1), T.px(1), bd.a, bd.r, bd.g, bd.b)
        end
        -- Hit zone (always register even if off-screen, for scroll calculation)
        self:addHitZone(ci, 0, drawY, w, T.px(CONTAINER_BTN_SZ))
        drawY = drawY + T.px(CONTAINER_BTN_SZ)
    end

    if needsScroll then
        self:clearStencilRect()

        -- Scroll arrows at bottom
        local arrowY = h - scrollArrowH
        ZeD.Surface.fill(self, 0, arrowY, w - T.px(1), scrollArrowH, "surf2")
        A.drawDividerH(self, 0, arrowY, w - T.px(1), true)
        -- the row's inside between the strip's lines, two equal halves; each arrow centred in its half
        local L, M, M2, R = A.stripArrowHalves(w, "frame", "own")   -- (the containers: the divider left, its own line right)
        local aS = T.px(5)
        if not cuesOn and my >= arrowY and my < h and ((mx >= L and mx < M) or (mx >= M2 and mx < R)) then
            local hv = T.hover
            local hx, hw = L, M - L
            if mx >= M2 then hx, hw = M2, R - M2 end
            self:drawRect(hx, arrowY + T.px(1), hw, scrollArrowH - T.px(1), hv.a, hv.r, hv.g, hv.b)
        end
        A.stripArrowLine(self, M, M2, arrowY, h)
        local arY = arrowY + T.px(1) + math.floor((scrollArrowH - T.px(1) - aS) / 2)   -- (centred under the row's top line)

        -- Up arrow (left half)
        local arrowColor = scrollOff > 0 and T.text or T.textDim
        A.drawTriangleUp(self, A.stripArrowX(L, M, aS), arY, aS, arrowColor)
        self:addHitZone("scroll_up", 0, arrowY, M, scrollArrowH)

        -- Down arrow (right half)
        local maxScroll = totalListH - listAreaH
        local downColor = scrollOff < maxScroll and T.text or T.textDim
        A.drawTriangleDown(self, A.stripArrowX(M2, R, aS), arY, aS, downColor)
        self:addHitZone("scroll_down", M2, arrowY, w - M2, scrollArrowH)
    end
end


-- ============================================================================
-- TOGGLE — opening and closing the window, and the small public helpers
-- around it. toggle() builds the whole window on every open (panes,
-- handlers, the controller's ring).
-- ============================================================================

--- True while the World window is open. pn: whose window (nil: the first player's).
function ZeD_WorldWindow.isOpen(pn)
    return _worldWins[pn or 0] ~= nil
end

--- The picture the strip shows for a container: its button's own (a body, a car's part, a crate) while the window
--- lists it, else the game's icon for its type, else the game's box. Never nil. (A menu row that names a container,
--- Move to's loot row among them, draws it: QA rt_menus, Nov 24 2026, "no icon: Corpse".)
function ZeD_WorldWindow.containerIcon(inv, pn)
    if not inv then return ZeD.genericContainerTex() end
    local win = _worldWins[pn or 0]
    for _, c in ipairs(win and win._containers or {}) do
        if c.inventory == inv and c.texture then return c.texture end
    end
    local ok, t = pcall(function() return inv:getType() end)
    return (ok and t and resolveContainerIcon(t)) or ZeD.genericContainerTex()
end

--- The game's hidden loot page put on the container this window shows. The item menu's "Put in Container (X)" and the
--- Move to submenu's loot entry read that page (getPlayerLoot(pn).inventory, ISInventoryPaneContextMenu), so they name
--- and fill what he sees, never a crate or a body the page last held. With the window shut the page goes on the floor,
--- where the game drops both rows. Returns the page's old fields when it changed them (old.open: the window is up),
--- else nil. (QA's loot KISS test, Nov 24 2026: the battery went into a body beside the crate on show)
function ZeD_WorldWindow.syncLootPage(pn)
    pn = pn or 0
    if ZeD.Safe.on("windows") or not ZeD.windowsFor(pn) then return nil end
    local vl = getPlayerLoot(pn)
    if not (vl and vl.inventoryPane) then return nil end
    local win = _worldWins[pn]
    local c = win and win._containers and win._containers[win._viewedContainer or win._activeContainer]
    local inv, name = c and c.inventory, c and c.name
    local open = inv ~= nil
    if not inv then inv = ISInventoryPage.GetFloorContainer and ISInventoryPage.GetFloorContainer(pn) end
    if not inv or (vl.inventory == inv and vl.inventoryPane.inventory == inv) then return nil end
    local old = { inventory = vl.inventory, pane = vl.inventoryPane.inventory, last = vl.inventoryPane.lastinventory,
                  title = vl.title, open = open }
    vl.inventory, vl.inventoryPane.inventory, vl.inventoryPane.lastinventory = inv, inv, inv
    if name then vl.title = name end
    return old
end
--- Gives the page back what syncLootPage changed (the menu's build with the window shut: the window's own way in,
--- "open on the page's container", stays as it was).
function ZeD_WorldWindow.restoreLootPage(pn, old)
    local vl = old and getPlayerLoot(pn or 0)
    if not (vl and vl.inventoryPane) then return end
    vl.inventory, vl.inventoryPane.inventory, vl.inventoryPane.lastinventory = old.inventory, old.pane, old.last
    vl.title = old.title
end

--- Rebuilds the controller's stops for the tab now showing (Reset windows calls
--- it after putting the window back on Loot). win defaults to the open window.
function ZeD_WorldWindow.syncRing(win)
    win = win or ZeD_WorldWindow.getWindow()
    if win and win._mainContent and _syncWorldRingZones then _syncWorldRingZones(win, win._mainContent) end
end

--- The open World window, or nil. pn: whose window (nil: the first player's).
function ZeD_WorldWindow.getWindow(pn)
    return _worldWins[pn or 0]
end

--- Returns the virtual floor container (for identity checks from other modules).
function ZeD_WorldWindow.getFloorContainer(pn)
    return _floorContainers[pn or 0]
end

--- Is this container in reach now? The list rebuilds as the strip draws, so a rolled window's is as old as the roll-up, and
--- the game's transfer checks no reach of its own. Read once per drop (InventoryRenderer.handleDrop), never per frame.
--- pn: whose window (nil: the first player's).
function ZeD_WorldWindow.inReach(inv, pn)
    local win = _worldWins[pn or 0]
    if not (win and inv) then return false end
    for _, c in ipairs(buildWorldContainers(win._playerObj)) do
        if c.inventory == inv then return not c.locked end
    end
    return false
end

--- Take one ground item into destInv (the player's inventory, a bag, or a
--- container): the one routing point for every floor pickup in ZeD.
--- As vanilla's loot window (its drag and drop and its Grab), this queues
--- vanilla's transfer action from the floor container the item is in. In
--- single player that action takes the item off its square when its time is
--- up; on a multiplayer client the server's item transaction moves it, and
--- the client changes nothing itself. Returns true when the transfer is queued.
function ZeD_WorldWindow.transferFromFloor(playerObj, item, destInv)
    if not (playerObj and item and destInv) then return false end
    local worldItem = item:getWorldItem()
    if not (worldItem and worldItem:getSquare()) then return false end
    -- the floor container the item sits in (vanilla's, which this window shares)
    local src = item:getContainer()
    if not src or src:getType() ~= "floor" or src == destInv then return false end
    if not destInv:isItemAllowed(item) then return false end
    local move = ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, src, destInv)
    move._zedApart = true   -- (the player's own move: Put things back never counts it as an action's, ZeD_PutBack.lua) (L1-3)
    ISTimedActionQueue.add(move)
    return true
end

-- The item card's item gone (eaten, used up by a craft, taken by another
-- player, picked up off the ground by someone else): the card closes, as a
-- deselect would, so its buttons never act on an item that isn't there.
-- An item the player took into their own inventory keeps its card (with
-- inventory buttons). Checked every 10 frames, as the Character window does.
local function closeCardIfItemGone(win, content)
    win._goneTick = (win._goneTick or 0) + 1
    if win._goneTick < 10 then return end
    win._goneTick = 0
    local di = win._drawerItem
    if not di then return end
    local ok, here = pcall(function()
        local c = di:getContainer()
        if c == nil then return false end
        if c:getType() == "floor" then
            local wi = di:getWorldItem()
            return wi ~= nil and wi:getSquare() ~= nil
        end
        return true
    end)
    if ok and not here then
        if content._selectedItems then content._selectedItems[di] = nil end
        for _, cs in ipairs(content._colStates or {}) do
            if cs.selectedItems then cs.selectedItems[di] = nil end
        end
        if win._updateDrawer then win._updateDrawer() end
    end
end

-- Every close of the World window comes here: its close box (Organisms), the
-- curtain rod's close (WindowCurtain), the controller's close-all (FocusManager),
-- toggle, close and forceClose. The map pop-out (the world map or a paper map
-- Read Map opened) folds with the window (keepWorld: the fold comes from the
-- window itself, so the paper doesn't close it a second time), so nothing is
-- left up with no World window behind it.
local function _closeWorldWindow(w)
    ZeD_WorldWindow._endZoneDraw()
    pcall(ZeD_WorldWindow._unlightAll, w)   -- (nothing stays lit in the world once the window closes, KISS #44)
    saveWorldState(w)
    if ZeD.MapsTab and ZeD.MapsTab.closePopout then ZeD.MapsTab.closePopout(w, true) end
    -- a look at a car ends with the window, and the hood it opened shuts (QA K1-9)
    if ZeD.MechanicsTab and ZeD.MechanicsTab.endLooks then
        pcall(ZeD.MechanicsTab.endLooks, w._playerObj or getSpecificPlayer(w.playerNum or 0))
    end
    -- the build cursor the Build tab started goes with the window, as the game's build window's close clears
    -- its cursor (ISBuildPanel.lua:405-407) (QA cb sweep, Nov 25 2026, B5)
    if ZeD.BuildingTab and ZeD.BuildingTab.dropCursor then pcall(ZeD.BuildingTab.dropCursor, w.playerNum or 0) end
    -- the object card goes with the window through its own drop, so its kind tidies up: the placement card saves and
    -- ends the game's placement and its gizmo, the laundry hands the focus back (QA PL1/OC2, Nov 26 2026: the close
    -- box and U left isDoingExtendedPlacement on and the gizmo up). A pinned trade stays pinned, as on a tab switch.
    pcall(dropObjectCard, w, "the World window closed")
    -- unregisterWindow releases focus if this window holds it
    if ZeD and ZeD.Input and ZeD.Input.Focus then ZeD.Input.Focus.unregisterWindow(w) end
    w:removeFromUIManager()
    if _worldWins[w.playerNum or 0] == w then
        _worldWins[w.playerNum or 0] = nil
        _floorContainers[w.playerNum or 0] = nil
    end
end

--- Closes the World window when it is open, else builds and opens it (player 0
--- only; not in safe mode). Other files go through open(), which also refuses
--- a dead character. The whole window is built inside this one call.
function ZeD_WorldWindow.toggle(playerNum)
    playerNum = playerNum or 0
    -- (split-screen: another player's press never opens or closes the first player's window, ZeD.windowsFor)
    if not ZeD.windowsFor(playerNum) then return end

    if _worldWins[playerNum] then
        _closeWorldWindow(_worldWins[playerNum])
        return
    end

    -- safe mode (SafeMode.lua): the window does not open; callers fall back to vanilla's
    if ZeD.Safe.on("windows") then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local r = getR()
    local T = ZeD.T
    -- (the screen the window lives on, ZeD.screenOf: screenL, screenT its left and top)
    local screenW, screenH, screenL, screenT = ZeD.screenOf(playerNum)
    local maxWinW = math.floor(screenW * 0.5)
    local invW = 372                                     -- design units (default inventory width)
    -- (narrower where a full card beside it would shift the window: ZeD.Scale.fitInvW; it grows right from here)
    local fitU = ZeD.Scale and ZeD.Scale.fitInvW and
        ZeD.Scale.fitInvW(T, math.min(maxWinW, screenW - (math.floor(screenW / 2) + T.px(5))), CONTAINER_STRIP_W + ACTION_TAB_STRIP_W)
    if type(fitU) == "number" then invW = fitU end
    local winW = T.px(CONTAINER_STRIP_W) + T.px(invW) + T.px(ACTION_TAB_STRIP_W)  -- 36 + 372 + 36 = 444 design units
    winW = math.min(winW, maxWinW)
    local winH = math.min(T.px(420), screenH - T.px(80))

    -- Position: right page of two-page spread, left edge 5px right of center
    local win = ZeD_Window:new(screenL + math.floor(screenW / 2) + T.px(5), screenT, winW, winH, ZeD.tr("UI_ZeD_World_Title"))
    win:initialise()
    win:addToUIManager()
    -- the game's own roll-up when not in use, each half on its own (WindowHalves, attached with the
    -- curtain below); the pins kept with the character
    win.autoCollapse = true
    win.minimumHeight = T.px(220)
    win._maxWinW = maxWinW
    win.playerNum = playerNum   -- (read as `win.playerNum or 0` by the roll-up and the cards)
    -- the help line folds away while the window has nothing to say (QA's visual noise audit 9, Nov 20 2026)
    -- (Build, Nov 20: off. Folding the strip moved the window's foot and its grow box as the pointer came and went;
    -- the shared frame already draws an empty strip as plain body, which keeps the window still.)
    win.footerWhenUsed = false

    _worldWins[playerNum] = win

    -- Stable label for FocusManager diagnostic logs. win.title gets replaced
    -- with the active container's name mid-session ("Ground  0", "Fridge",
    -- etc.), so _label() in FocusManager prefers _zedLabel when set. Keeps
    -- console.txt grep-able as "World" no matter what the title reads.
    win._zedLabel = "World"

    -- Restore saved position/size (must come after _maxWinW is set)
    if type(fitU) == "number" then win._fitInvW, win._fitFromInvW = fitU, 372 end   -- (the restore below replaces both)
    restoreWorldState(win, playerObj)

    -- registerWindow fires early; ring construction + claimFocus deferred
    -- to after win._containers / win._activeContainer / win._mcSelected are
    -- populated so containerStrip elements seed correctly.
    if ZeD and ZeD.Input and ZeD.Input.Focus then
        ZeD.Input.Focus.registerWindow(win)
    end

    -- Override close
    -- (the close box, the curtain rod's close, the controller's close-all: the
    -- map pop-out folds with the window, _closeWorldWindow)
    win.close = function(self)
        _closeWorldWindow(self)
    end

    -- Player ref
    win._playerObj = playerObj

    -- Container state (floor is always last). The one shown first is the one he faces, seated the glove box or
    -- his seat (KISS #13; the game's loot page), the Floor only when nothing else is in reach.
    win._containers = buildWorldContainers(playerObj)
    win._activeContainer = ZeD_WorldWindow._pickShown(win, playerObj) or #win._containers
    win._lookDir = playerObj:getDir()
    win._containerTimer = 0
    do
        local t0, sq0 = getTimestampMs(), playerObj:getCurrentSquare()
        win._containerAtMs, win._containerDueMs, win._containerSq = t0, t0 + WREF.ms + WREF.phaseMs, sq0
        win._sideScanAtMs, win._sideScanSq, win._radioSq, win._containersDirty = t0, sq0, sq0, nil
    end
    win._stripScrollOffset = 0
    win._containerSortMode = "dist"  -- "dist" | "wt" | "type"
    win._baseInvW = invW             -- DESIGN UNITS (T.px() at every use; saved as-is)

    -- Radio contextual tab state. _kind tells RadioTab.render which
    -- discovery source to use ("world" -> 3x3 grid scan for IsoWaveSignal).
    -- Refreshed on the same 30-frame timer as containers.
    win._kind             = "world"
    win._radios           = ZeD.RadioTab.buildWorldRadios(playerObj)
    win._radioIdx         = 1
    if ZeD.MechanicsTab and ZeD.MechanicsTab.refresh then pcall(ZeD.MechanicsTab.refresh, win) end

    -- Drawer state
    win._drawerOpen  = false
    win._drawerEffW  = 0
    win._prevEffW    = 0            -- (a drawer's first frame widens the window too; nil lost it)
    win._drawerItem  = nil
    win._drawerMode  = nil          -- nil | "item" | "tab" | "object"

    -- Action tab state
    win._activeTab   = "loot"
    win._tabUnder    = nil          -- only ever cleared: a card lies over its tab, which stays active
    win._actionTabScrollOffset = 0
    -- Crafting/Building tab state — new unified architecture.
    -- Tab state is lazily created by CraftingCore.createState() on first render.
    -- Only data-gathering caches and container refs live on win directly.
    win._craftCache          = nil
    win._craftContainers     = nil
    win._craftState          = nil   -- created lazily by CraftingTab

    win._buildCache          = nil
    win._buildContainers     = nil
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
    win._forageSearchBtn     = nil
    win._forageDisclosureZone = nil
    win._forageDropdown      = nil
    win._mapTextEntry       = nil

    -- Multi-container state
    win._mcSelected = {}

    -- Controller state for the column zones (worldMC1..N): _gpFocusedMCItem is
    -- the focused Java item, kept by identity across the per-frame refresh;
    -- _gpFocusedMCColIdx is its column. _gpFocusedMCColIdx and _lastPinnedMCItem
    -- are only written and cleared; nothing reads them.
    win._gpFocusedMCItem     = nil
    win._gpFocusedMCColIdx   = nil
    win._lastPinnedMCItem    = nil

    -- Inventory drawer state (two-drawer architecture)
    win._invDrawerOpen    = true
    win._invDrawerEffW    = T.px(invW)   -- screen px
    win._invDrawerTargetW = T.px(invW)   -- screen px
    win._mainVisible      = true    -- floor container visible (toggleable on Loot)

    -- The controller's ring, built AFTER the container and MC state above, so
    -- the strip's stops seed on the right container. The zone order is with
    -- the ring below; the first focus goes to the main list.
    if ZeD and ZeD.Input and ZeD.Input.Focus then
        local Focus = ZeD.Input.Focus

        local activeTab = win._activeTab or "loot"

        local tabEls = _buildWorldTabBarElements(win)
        _attachWorldTabBarCallbacks(win, tabEls)

        local tabContentEls = _buildWorldPanelFocusables(win, win._mainContent, activeTab) or {}
        -- worldMainInv holds the active container's invrows on ALL tabs
        -- (matches Character's charMainInv pattern — inv is always visible
        -- regardless of active tab). Built even at init; per-frame refresh
        -- keeps it in sync as the container or items change.
        local mainInvEls    = _buildWorldInvRowFocusables(win) or {}
        -- The containers can be reached on ALL tabs; adding a column (hold A)
        -- is Loot-only, checked in the stop's onHoldActivate.
        local containerEls  = _buildWorldLootFocusables(win) or {}
        -- The per-column MC zones are added after the ring is built, by
        -- _rebuildWorldMCRingZones(); there is no flat list of column stops here.

        local activeIdx = 1
        for i, el in ipairs(tabEls) do
            if el.tabId == activeTab then activeIdx = i; break end
        end

        -- Ring order matches the VISUAL left-to-right layout of the World
        -- window (which is MIRRORED from Character):
        --   [containerStrip] [MCColumns] [mainInv] [tabContent] [itemCard] [tabBar]
        -- LB cycles visually LEFT (toward containerStrip); RB cycles visually
        -- RIGHT (toward tabBar). The first focus goes to mainInv, found by name
        -- (_pickInitialFocusIdx below).

        -- uiRange fns for the scoped-underline focus indicator on the
        -- title bar. Read live geometry (drawer width, window width).
        -- worldMainInv's uiRange: with MC active, mainInv = the rightmost
        -- (active container) column; else = full inv width.
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
            -- The drawer's x comes from the live window width: it always sits
            -- between the inv area and the right-edge action tab strip, and in
            -- MC mode the inv area grows past baseInvW, so a fixed
            -- (CONTAINER_STRIP_W + baseInvW) anchor would put the focus
            -- underline in the wrong place with a card open over MC.
            local ix = w:getWidth() - T.px(ACTION_TAB_STRIP_W) - dw
            return ix, dw
        end

        win._focusRing = {
            { zone = "worldContainerStrip",
              focusable = #containerEls > 0,
              elements = containerEls,
              -- Seed by containerIdx match (elements in [floor, non-floor
              -- display-order] layout, not container-index order).
              focusedElementIdx = (function()
                  if not win._activeContainer or #containerEls == 0 then return 1 end
                  for i, el in ipairs(containerEls) do
                      if el.containerIdx == win._activeContainer then return i end
                  end
                  return 1
              end)(),
              landOn = _worldStripLandOn,
              uiRange = function(w) return 0, ZeD.T.px(CONTAINER_STRIP_W) end },
            -- The per-column MC zones (worldMC1..worldMCN) go in here, put in
            -- by _rebuildWorldMCRingZones() after the ring is built: one zone
            -- per column, no single zone for all of them.
            -- Always-visible invrows of the active container. Populated
            -- on every tab — mirrors Character's charMainInv. Focusable
            -- whenever the container has items, regardless of active tab.
            { zone = "worldMainInv",
              focusable = #mainInvEls > 0,
              elements = mainInvEls,
              focusedElementIdx = 1,
              landOn = _invListLandOn,
              uiRange = _worldMainInvRange },
            { zone = "worldTabContent",
              focusable = #tabContentEls > 0,
              elements = tabContentEls,
              focusedElementIdx = 1,
              -- (an item or object card over the drawer hides the tab's controls)
              covered = function(w) return w._drawerItem ~= nil or w._drawerObject ~= nil end,
              uiRange = _worldDrawerRange },
            -- Item card action strip zone — card drawer opens to the
            -- RIGHT of the inventory in World (mirror of Character where it
            -- opens to the LEFT). Focusable only while a card shows (the
            -- per-frame refresh: an item card, or an object card with none over it).
            { zone = "worldItemCard",
              focusable = false,
              elements = {},
              focusedElementIdx = 1,
              landOn = Focus.landOnPrimary,   -- (into a card, onto its primary action)
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
        -- Prefer worldMainInv when focusable, else fall through to the first
        -- focusable zone. mainInv is non-focusable at toggle-time because
        -- content hasn't rendered yet (no _invRowItems); per-frame refresh
        -- populates it next frame. A fixed index would leave the player on a
        -- non-focusable zone — the bumpers still cycle, but D-pad nav within
        -- the zone does nothing.
        local function _pickInitialFocusIdx()
            local ring = win._focusRing
            if not ring or #ring == 0 then return 1 end
            -- (by name: the ring's third zone is the tab drawer, not the list)
            local prefer
            for i, z in ipairs(ring) do if z.zone == "worldMainInv" then prefer = i; break end end
            if prefer and ring[prefer].focusable
               and #(ring[prefer].elements or {}) > 0 then return prefer end
            for i = 1, #ring do
                if ring[i].focusable and #(ring[i].elements or {}) > 0 then
                    return i
                end
            end
            return 1
        end
        -- Build the per-column MC zones (none while MC is inactive, as at open).
        _rebuildWorldMCRingZones(win)

        win._focusIdx = _pickInitialFocusIdx()
        -- Entering the window lands on the list's first row once
        -- it has rows (the rows draw a frame after the window opens); see
        -- Focus.ensureEntry
        win._focusEntryZone    = "worldMainInv"
        -- (Nov 15 2026, the director: Right from the Character window is "probably where they want to go": the
        -- container buttons, on a container other than the floor when there is one (the one showing, else the first),
        -- the floor when it is the only one. It saves the press over and then down. Focus only: A still opens it.)
        win._padLandFromSide = function(w, dir)
            if dir ~= "right" then return false end
            local F = ZeD.Input and ZeD.Input.Focus
            local cnts = w._containers or {}
            local function isFloor(i) return cnts[i] ~= nil and cnts[i].isFloor == true end
            local want = nil
            if w._activeContainer and cnts[w._activeContainer] and not isFloor(w._activeContainer) then want = w._activeContainer end
            local pick = function(e)
                if want then return e.containerIdx == want end
                return e.containerIdx ~= nil and not isFloor(e.containerIdx)
            end
            local got = F and F.focusWhere(w, "worldContainerStrip", pick)
            if not got and F then got = F.focusWhere(w, "worldContainerStrip", function(e) return e.containerIdx ~= nil end) end
            if got then pcall(function() ZeD.uiSound("UISelectListItem") end) end
            return got ~= nil
        end
        win._focusPendingEntry = true

        -- (Nov 14 2026, punch list: not while the pair opens with the pad already on a ZeD window)
        if not (ZeD_CharacterWindow and ZeD_CharacterWindow.pairKeepsPad
                and ZeD_CharacterWindow.pairKeepsPad(win.playerNum)) then Focus.claimFocus(win) end
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
    containerStrip._zedLabel = "world container strip"   -- its own name in console.txt and safe mode's watchdog
    containerStrip.anchorRight = false
    -- (Nov 14 2026, punch list 201: nor the height; the drawer's layout sets it. Anchored, a quick
    -- Y unhide stretched the strip and the list for a frame or two before that layout ran)
    containerStrip.anchorBottom = false
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
                    -- (KISS #10) Loot tab: a plain click shows this container alone, as the game's container
                    -- button and the pad's tap A do; Ctrl-click adds it as a column (multi-column), as hold A does
                    if isCtrlKeyDown() then
                        mcToggleWorldContainer(win, content, zid)
                    else
                        ZeD_WorldWindow._showAlone(win, content, zid)
                    end
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
                        win._viewedOver = (win._containers[win._activeContainer] or {}).inventory
                        win._invDrawerOpen = true
                        local drawerW = math.floor(win._drawerEffW or 0)
                        local baseInv = T.px(win._baseInvW or 372)
                        local snapW = T.px(CONTAINER_STRIP_W) + baseInv + drawerW + T.px(ACTION_TAB_STRIP_W)
                        local maxW = win._maxWinW or math.floor(ZeD.screenOf(win) * 0.5)
                        win:setWidth(math.min(snapW, maxW))
                    else
                        -- Different container: switch to it
                        win._viewedContainer = (zid ~= win._activeContainer) and zid or nil
                        win._viewedOver = (win._containers[win._activeContainer] or {}).inventory
                    end
                    if win._invDrawerOpen then
                        content._inventory = win._containers[win._viewedContainer or win._activeContainer].inventory
                    end
                    content._selectedItems = {}
                    content._lastClickedItem = nil
                end
            elseif cnt.isoObject and ZeD.ObjectCardLock then
                -- a locked container: its lock card (code, key) instead of a dead click
                pcall(ZeD.ObjectCardLock.openFor, win._playerObj, cnt.isoObject, false)
            end
        end
        return true
    end

    containerStrip.onMouseWheel = function(self, del)
        local T = ZeD.T
        local total = #win._containers - 1  -- minus the floor (pinned, not in the scrolled list)
        if total > 0 then
            win._stripScrollOffset = (win._stripScrollOffset or 0) + del * T.px(CONTAINER_BTN_SZ)
        end
        return true
    end

    -- ----------------------------------------------------------------
    -- CONTENT PANEL — item list, fills remaining width
    -- ----------------------------------------------------------------
    content = ZeD_Panel:new(T.px(CONTAINER_STRIP_W), bodyY, winW - T.px(CONTAINER_STRIP_W) - T.px(ACTION_TAB_STRIP_W), bodyH)
    content._zedLabel = "world content"   -- its own name in console.txt and safe mode's watchdog
    content.anchorRight = false  -- drawer prerender controls width, not ISPanel auto-resize
    content.anchorBottom = false  -- (Nov 14 2026, punch list 201: and height, as the container strip's)
    content:initialise()
    win:addChild(content)
    win._contentPanel = content
    -- (Nov 14 2026, punch list 201: the strip and the list draw before the drawer's layout in a
    -- frame, so the first frame after an unhide gets their top and height here, at once)
    win.setWindowShaded = function(self, shaded)
        ZeD_Window.setWindowShaded(self, shaded)
        if shaded or self.windowShaded then return end
        local by, bh = self:getBodyY(), self:getBodyHeight()
        containerStrip:setY(by); containerStrip:setHeight(bh)
        content:setY(by); content:setHeight(bh)
    end
    -- Expose the content panel to gamepad focus callbacks set earlier
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
    -- (row 1, T.stripH: set again before each draw, so a new text size or UI scale moves it with the strips)
    content._hdrYOffset = T.stripH
    content._defaultHdrYOffset = T.stripH

    -- Container buttons (ContainerControls): the row at the bottom of the list
    content._ccSide = "world"
    content._ccWin  = win

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
    -- DRAWER PANEL — right of the list; the open tab draws here, and its
    -- width animates open and shut (the item card lies over it: ITEM DRAWER)
    -- ----------------------------------------------------------------
    local drawer = ZeD_Panel:new(winW - T.px(ACTION_TAB_STRIP_W), bodyY, 0, bodyH)
    drawer._zedLabel = "world drawer"   -- its own name in console.txt and safe mode's watchdog
    drawer.anchorRight = false
    drawer:initialise()
    win:addChild(drawer)
    win._drawerPanel = drawer

    -- Crafting tab search field (ISPanel child of drawer)
    local craftSearch = ZeD_SearchField:new(0, 0, T.px(200), getText("IGUI_CraftingWindow_SearchRecipes"))
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
    local buildSearch = ZeD_SearchField:new(0, 0, T.px(200), ZeD.tr("UI_ZeD_World_SearchStructures"))
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
    itemDrawer._zedLabel = "world item drawer"   -- its own name in console.txt and safe mode's watchdog
    itemDrawer.anchorRight = false
    itemDrawer:initialise()
    win:addChild(itemDrawer)
    win._itemDrawerPanel = itemDrawer

    local card = ZeD_ItemCard:new(0, 0, T.px(ITEM_CARD_W), bodyH, "drawer", playerNum)
    card:initialise()
    card:setVisible(false)
    itemDrawer:addChild(card)
    win._itemCard = card
    -- the card's back key shuts the card, as B does (_wireWorldCardButtonNav's onCancel);
    -- without this handler a click on it does nothing.
    card.onBackClick = function()
        local content = win._mainContent
        if content and win._updateDrawer then
            local sel = content._selectedItems or {}
            for k in pairs(sel) do sel[k] = nil end
            content._selectedItems   = sel
            content._lastClickedItem = nil
            win._updateDrawer()
        end
    end

    -- Object card (generator, fires, farm plots): same overlay, the full card's
    -- width (a kind marked half takes the half card)
    local objCard = ZeD_ObjectCard:new(0, 0, T.px(OBJECT_CARD_W), bodyH, playerNum)
    objCard:initialise()
    objCard:setVisible(false)
    itemDrawer:addChild(objCard)
    win._objectCard = objCard

    itemDrawer._onPrerender = function(self)
        local T = ZeD.T
        local effectiveW = math.floor(win._drawerEffW)
        local bodyH = win:getBodyHeight()
        self:setHeight(bodyH)

        local showCard = win._drawerItem ~= nil and effectiveW > 0
        local showObj = (not showCard) and win._drawerObject ~= nil and effectiveW > 0
        card:setVisible(showCard)
        objCard:setVisible(showObj)

        if showCard then
            -- World window: card always at left edge (inventory-facing)
            self:setX(drawer:getX())
            self:setWidth(math.min(effectiveW, T.px(ITEM_CARD_W)))
            card:setX(0)
            card:setWidth(math.min(self:getWidth(), T.px(ITEM_CARD_W)))
            card:setHeight(bodyH)
            -- over a tab's content the card draws the edge that faces the tab (its right:
            -- the World window is mirrored); alone in the drawer the window's own lines
            -- bound it (the divider or the strip's edge, the waterfall's edge, the help line)
            card.overlayEdge = (win._drawerMode == "tab" and card:getWidth() < effectiveW) and "right" or nil
            card.overlayFrame = (win._drawerMode == "tab")   -- (a line all round over a tab: the director, Nov 26 2026)

            -- Background fill: surface 1 at the window's see-through, claimed so the
            -- body is not drawn under it as well (one layer, ZeD.Surface)
            local dh = self:getHeight()
            ZeD.Surface.fill(self, 0, 0, self:getWidth(), dh, "surf1")
            -- (no left edge of its own: the window's divider or the container strip's
            -- inner edge is the pane line there)
        elseif showObj then
            self:setX(drawer:getX())
            local od = win._drawerObject and win._drawerObject.def
            -- the card fills the drawer it is given (no strip left between its scroll bar and the tabs) (object card fill)
            self:setWidth(ZeD_WorldWindow.objectCardW(od, effectiveW))
            objCard:setX(0)
            objCard:setY(0)
            objCard:setWidth(self:getWidth())
            objCard:setHeight(bodyH)
        else
            self:setWidth(0)
        end
    end

    itemDrawer.onMouseWheel = function(self, del)
        if card:getIsVisible() then
            card:onMouseWheel(del)
        elseif objCard:getIsVisible() then
            objCard:onMouseWheel(del)
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

        -- ── The drawer's change in width drives the window's width;
        -- invW is always the residual. Inv toggle snaps width directly. ──
        local prevEffW = win._prevEffW or effectiveW
        local drawerDelta = effectiveW - prevEffW
        win._prevEffW = effectiveW

        local mcActive = #(win._mcSelected or {}) > 0
        local screenW = ZeD.screenOf(win)
        -- When MC + item card are both active, cap maxW at user's preferred
        -- inv width (_baseInvW) plus chrome — window expands enough to keep
        -- card visible alongside MC, but not to full screen, so the eviction
        -- loop below fires when MC columns can't all fit at MIN_COL_W.
        local mcItemCap = nil
        if mcActive and win._drawerMode == "item" then
            local baseInv = T.px(win._baseInvW or 372)
            mcItemCap = T.px(CONTAINER_STRIP_W) + baseInv + effectiveW + T.px(ACTION_TAB_STRIP_W)
        end
        local maxW = mcItemCap
            or (mcActive and (screenW + ZeD.screenLeftOf(win) - win:getX() - T.px(10)))
            or (win._maxWinW or math.floor(screenW * 0.5))

        if drawerDelta ~= 0 then
            -- A card opening in MC mode expands the window like tab mode
            -- does, instead of making room by shrinking the inv area and
            -- evicting the oldest MC column (which would collapse MC silently
            -- on every item select). Always resize per drawerDelta.
            -- The cap swallows part of an opening drawer's width (at 1080p the Maps drawer
            -- runs the window into the half-screen cap); that loss is remembered and given back while
            -- the drawer closes, so the window comes back to the width it had, instead of 7 px short
            -- (which the rest-state check below then kept as if the player had resized it).
            -- (a rolled side's width is the full width less the rolled-off part: the cap in those terms)
            local cap = maxW - (win._rolled and (win._rollW or 0) or 0)
            local want = win:getWidth() + drawerDelta
            local lost = win._drawerCapLost or 0
            local newW
            if drawerDelta > 0 then
                newW = math.min(want, cap)
                lost = lost + (want - newW)
            else
                local back = math.min(lost, -drawerDelta)
                lost = lost - back
                newW = math.min(want + back, cap)
            end
            win._drawerCapLost = lost
            -- The engine keeps a top-level panel on screen when it widens (setWidth moves it left);
            -- that push is remembered and undone as the drawer closes, so the window comes back to
            -- its place as well as its width (a drag by the player is not a push: it is kept).
            local xBefore = win:getX()
            win:setWidth(newW)
            -- (the engine keeps a panel on the whole screen only; on a player's part in split view the window is
            -- pushed left inside its part here, the same push: QA's half-screen stand-in, Nov 13 2026)
            if drawerDelta > 0 and win:getX() + win:getWidth() > screenW + ZeD.screenLeftOf(win) then
                win:setX(math.max(ZeD.screenLeftOf(win), screenW + ZeD.screenLeftOf(win) - win:getWidth()))
            end
            local pushed = win._drawerCapPush or 0
            if drawerDelta > 0 then
                pushed = pushed + math.max(0, xBefore - win:getX())
            elseif pushed > 0 then
                local room = screenW + ZeD.screenLeftOf(win) - (win:getX() + win:getWidth())
                local back = math.max(0, math.min(pushed, room))
                if back > 0 then win:setX(win:getX() + back) end
                pushed = pushed - back
            end
            win._drawerCapPush = pushed
        else
            -- At rest: accept user resize
            if win:getWidth() > maxW then win:setWidth(maxW) end
            -- (a window the player made narrower than the cap has nothing to give back)
            if (win._drawerCapLost or 0) > 0 and win:getWidth() + (win._rolled and (win._rollW or 0) or 0) < maxW - 1 then win._drawerCapLost = 0 end
        end

        -- invW is ALWAYS the residual. A rolled-up side (WindowCurtain) has
        -- no strip and no inventory: the window is the drawer and the tabs.
        ZeD.Curtain.sync(win)
        local stripW = win._rolled and 0 or T.px(CONTAINER_STRIP_W)
        local invW = win._rolled and 0 or (win:getWidth() - stripW - effectiveW - T.px(ACTION_TAB_STRIP_W))
        invW = math.max(invW, 0)
        -- (Grid width, the director, Nov 22 2026) a grid side hugs its whole cells: the window's width follows
        -- (ZeD.Halves.gridHug; at rest or under a drag, never while a drawer slides)
        invW = ZeD.Halves.gridHug(win, content, invW, drawerDelta == 0, maxW)

        -- Track baseInvW ONLY when user manually resized (not from our snaps).
        -- (nor while a grid hugs its cells: _baseInvW stays the list's width, given back when the list returns)
        if drawerDelta == 0 and effectiveW == 0 and not mcActive and invW > 0 and not win._gridHug then
            local expectedW = T.px(CONTAINER_STRIP_W) + T.px(win._baseInvW or 372) + T.px(ACTION_TAB_STRIP_W)
            if win:getWidth() ~= expectedW then
                -- _baseInvW is stored in design units (screen px / T.scale);
                -- kept fractional so save/restore round-trips without drift.
                win._baseInvW = invW / (T.scale or 1)
            end
        end

        -- Dynamic minimum
        local bh = win:getBodyHeight()
        -- (never above the maximum, so a resize drag and the cap above agree)
        -- (the inventory's least: 200 units, a little under while a grid hugs three cells, ZeD.Halves.invMin)
        win.minimumWidth = math.min(maxW, stripW + (win._invDrawerOpen and not win._rolled and ZeD.Halves.invMin(win, content) or 0) + effectiveW + T.px(ACTION_TAB_STRIP_W))

        -- (QA OC7, Nov 26 2026) the columns an object card pushed out come back when it closes: at 1280x800 three
        -- columns and the lock card did not fit, one went, and after the card only two came back. Put back in front,
        -- as they were; the eviction below takes them again if the window still has no room.
        -- (they wait for the room: the drawer slides shut over a few frames, and a column put back on the first one was
        -- taken again by the eviction below while the card's width was still there; QA OC7 second pass. Given up
        -- after a few seconds, or when the columns change in between.)
        local fits = false
        if win._mcEvicted and not win._drawerObject and mcActive and #(win._mcSelected) > 0 then
            local R0 = getR()
            local n = #win._mcSelected + #win._mcEvicted + (win._mainVisible and 1 or 0)
            local xw = T.px(R0.getXferW and R0.getXferW(n) or 32)
            fits = (invW - (n - 1) * xw) / n >= T.px(R0.MIN_COL_W or 140)
            win._mcEvictedAt = win._mcEvictedAt or getTimestampMs()
            if not fits and getTimestampMs() - win._mcEvictedAt > 3000 then win._mcEvicted, win._mcEvictedAt = nil, nil end
        elseif win._mcEvicted and not win._drawerObject then
            win._mcEvicted, win._mcEvictedAt = nil, nil
        end
        if win._mcEvicted and fits then
            local back = win._mcEvicted
            win._mcEvicted, win._mcEvictedAt = nil, nil
            if mcActive and #(win._mcSelected) > 0 then
                for i = #back, 1, -1 do
                    local ci = back[i]
                    local have = false
                    for _, c in ipairs(win._mcSelected) do if c == ci then have = true; break end end
                    if not have and win._containers and win._containers[ci] then table.insert(win._mcSelected, 1, ci) end
                end
                local colSel = {}
                for _, ci in ipairs(win._mcSelected) do colSel[#colSel + 1] = ci end
                if win._mainVisible then
                    local activeInMc = false
                    for _, ci in ipairs(win._mcSelected) do
                        if ci == win._activeContainer then activeInMc = true; break end
                    end
                    if not activeInMc then colSel[#colSel + 1] = win._activeContainer end
                end
                content._selectedContainers = colSel
                content._containers = win._containers
                getR().rebuildColStates(content)
                content._activeCol = #colSel
                win._invDrawerTargetW = computeInvDrawerTargetWorld(win)
                if _syncWorldRingZones then _syncWorldRingZones(win, content) end
            end
        end

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
                local gone = table.remove(win._mcSelected, 1)
                -- (an object card's room: kept, to come back when the card closes; QA OC7)
                if win._drawerObject then
                    win._mcEvicted = win._mcEvicted or {}
                    win._mcEvicted[#win._mcEvicted + 1] = gone
                    win._mcEvictedAt = nil   -- (the wait for room starts once the card is gone)
                end
                totalCols = #win._mcSelected + (win._mainVisible and 1 or 0)   -- (a hidden floor takes no column: one extra stays)
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
                -- The ring zones must reflect the new MC count after
                -- FIFO eviction; otherwise stale worldMC<n> zones linger
                -- in the ring and bumpers cycle to zones with no items.
                if _syncWorldRingZones then _syncWorldRingZones(win, content) end
            end
        end

        -- Content: positioned after container strip, width = residual invW
        content:setX(stripW)
        content:setWidth(math.max(invW, 0))
        content:setVisible(invW > 0)
        -- the content's prerender (the controller's stops) does not run while it is hidden: the
        -- drawer runs the refresh instead (without it the Craft card and band have no stops at
        -- 1280x720, UI scale 2.0)
        if invW <= 0 and content._focusRefresh then content._focusRefresh(content) end
        containerStrip:setVisible(not win._rolled)

        -- Drawer + action tab strip positioned after content
        containerStrip:setHeight(bh)
        content:setHeight(bh)
        self:setX(stripW + invW)
        self:setHeight(bh)
        actionTabStrip:setX(stripW + invW + effectiveW)
        actionTabStrip:setHeight(bh)
        -- the two strips' widths and every panel's top follow the scale too: without this, a
        -- text size or scale change with the window open (the smallest font, for one) leaves the
        -- strips at the width they were built with, the container strip over the list and the
        -- tab strip past the window's edge
        local csW, tsW, bodyY = T.px(CONTAINER_STRIP_W), T.px(ACTION_TAB_STRIP_W), win:getBodyY()
        if containerStrip:getWidth() ~= csW then containerStrip:setWidth(csW) end
        if actionTabStrip:getWidth() ~= tsW then actionTabStrip:setWidth(tsW) end
        if containerStrip:getY() ~= bodyY then containerStrip:setY(bodyY) end
        if content:getY() ~= bodyY then content:setY(bodyY) end
        if self:getY() ~= bodyY then self:setY(bodyY) end
        if actionTabStrip:getY() ~= bodyY then actionTabStrip:setY(bodyY) end
        if itemDrawer:getY() ~= bodyY then itemDrawer:setY(bodyY) end

        -- Store divider position for top-Z drawing in win.render
        win._dividerX = (effectiveW > 0 and invW > 0) and (stripW + invW) or nil

        -- (the card's visibility is the item drawer's job: itemDrawer._onPrerender)

        -- Crafting search field visibility (tab mode + craft tab active)
        local showCraft = effectiveW > 0 and win._drawerMode == "tab" and win._activeTab == "craft"
        -- stations: a drying rack or an oven has no recipe search
        if showCraft and ZeD.Stations and ZeD.Stations.hidesSearch and ZeD.Stations.hidesSearch(win) then
            showCraft = false
        end
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
            self:setStencilRect(0, 0, effectiveW + ZeD.T.px(1), dh + ZeD.T.px(1))   -- (+1 hairline: a scroll bar's right and bottom lines land on the divider and footer rule; QA sb_edges)

            -- Drawer background fill (theme-aware tonal separation)
            local db = T.drawerBg
            self:drawRect(0, 0, effectiveW, dh, db.a, db.r, db.g, db.b)

            -- The card's background is the item drawer's (itemDrawer._onPrerender). No left
            -- edge of its own: the pane line is the window's divider (inventory open) or the
            -- container strip's inner edge (inventory closed); a second line here would double it.

            -- Tab content rendering (when in tab mode)
            if win._drawerMode == "tab" and win._activeTab then
                local renderer = WORLD_TAB_RENDERERS[win._activeTab]
                if renderer then
                    -- An open item card lies over the tab's left part: the tab draws only
                    -- what the card leaves showing (setTabCover), so the see-through card is
                    -- one surface over the world, not over a second layer of UI. (A card as
                    -- wide as the drawer leaves nothing: the tab still runs, for its zones.)
                    -- (an object card lies there the same way)
                    local od = win._drawerObject and win._drawerObject.def
                    local coverL = (win._drawerItem ~= nil) and math.min(effectiveW, T.px(ITEM_CARD_W))
                        or ((win._drawerObject ~= nil) and ZeD_WorldWindow.objectCardW(od, effectiveW)) or nil
                    if coverL and coverL > 0 then
                        self:clearStencilRect()
                        self:setStencilRect(coverL, 0, effectiveW - coverL, dh)
                        setTabCover(self, coverL, effectiveW)
                    else
                        coverL = nil
                    end
                    -- (a tab that throws must not repeat its error every frame or leave its own clip
                    -- set: log once, put the drawer's clip back, draw on)
                    -- (a tab may leave a clip set — the Admin tab and its cards once did; this stays as
                    -- the safety net for any other — and under a card every clear of any tab leaves one,
                    -- since coverClear sets it again: one left on hides everything drawn after the drawer,
                    -- the card, the tab strip and the help line with it. So the clips the tab left are
                    -- cleared after it runs; a tab that ends level with no card over it clears nothing here.)
                    local clipsBefore = self._zedStencilN or 0
                    self._coverClears = 0
                    local okR, errR = pcall(renderer, self, win, 0, 0, targetW, dh)
                    if coverL then
                        setTabCover(self, nil)
                        -- the tab's own boxes (child panels) the card would lie over hide: a
                        -- child panel can't be cut by the drawer's clip. After the tab ran, as
                        -- the tabs show their boxes while they draw.
                        local kids = self._coverKids or {}
                        self._coverKids = kids
                        kids[1], kids[2], kids[3] = win._craftSearch, win._buildSearch, win._forageDropdown
                        kids[4], kids[5] = win._worldMapPanel, win._mapTextEntry
                        for i = 1, 5 do
                            local c = kids[i]
                            if c and c.parent == self and c:isVisible() and c:getX() < coverL then c:setVisible(false) end
                        end
                    end
                    for _ = 1, (self._zedStencilN or 0) - clipsBefore + self._coverClears do self:clearStencilRect() end
                    if not okR then
                        self:clearStencilRect()
                        self:setStencilRect(0, 0, effectiveW + ZeD.T.px(1), dh + ZeD.T.px(1))   -- (+1 hairline: a scroll bar's right and bottom lines land on the divider and footer rule; QA sb_edges)
                        ZeD.logOnce("world tab " .. tostring(win._activeTab), errR)
                    end
                else
                    -- (no tab drawer: the Loot view. Nothing is drawn; the drawer becomes what is left in it)
                    lootDrawerFallback(win)
                end
            end

            self:clearStencilRect()
        end
    end

    -- Drawer mouse wheel → map zoom, tab scroll, or ItemCard scroll
    drawer.onMouseWheel = function(self, del)
        -- a two-way radio's face: the wheel turns the knob under it (else its body scrolls)
        if win._drawerMode == "tab" and win._activeTab == "radio" and ZeD.RadioTab.onWheel(win, del, self:getMouseX(), self:getMouseY()) then
            return true
        end
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
        if win._drawerMode == "tab" and win._activeTab == "furniture" then
            return ZeD.FurnitureTab.onMouseWheel(win, del)
        end
        -- (the Animals tab's own wheel: the Ranch page, a zone's roster, Butcher, an animal's details)
        if win._drawerMode == "tab" and win._activeTab == "animals" then
            return ZeD.AnimalsTab.onMouseWheel(win, del)
        end
        if win._drawerMode == "tab" then
            local scroll = getWorldActiveScroll(win)
            if scroll and scroll.visible then
                local step = 0.05
                scroll:setScrollPos(scroll.scrollPos + del * step)
                return true
            end
        end
        -- (the card's own scroll is the item drawer's: itemDrawer.onMouseWheel)
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
        if win._drawerMode == "tab" and win._activeTab == "furniture" then
            return ZeD.FurnitureTab.onClick(win, x, y)
        end
        local ext = win._drawerMode == "tab" and ZeD_WorldWindow._extTabs[win._activeTab]
        if ext and ext.onClick then ext.onClick(win, x, y); return true end
        return false
    end

    -- Drawer right-click → the open tab's own (on Craft and Build it pins a recipe)
    drawer.onRightMouseDown = function(self, x, y)
        -- a two-way radio's control: its second meaning (MEM names, a knob turns down)
        if win._drawerMode == "tab" and win._activeTab == "radio" then
            ZeD.RadioTab.onRightClick(win, x, y)
            return true
        end
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
    -- ACTION TAB STRIP — right edge, 36px wide (ACTION_TAB_STRIP_W)
    -- ----------------------------------------------------------------
    actionTabStrip = ZeD_Panel:new(winW - T.px(ACTION_TAB_STRIP_W), bodyY, T.px(ACTION_TAB_STRIP_W), bodyH)
    actionTabStrip._zedLabel = "world action strip"   -- its own name in console.txt and safe mode's watchdog
    actionTabStrip.anchorRight = false
    actionTabStrip:initialise()
    win:addChild(actionTabStrip)
    win._actionTabStrip = actionTabStrip

    -- The tab hover hint: a click-through layer above everything (ZeD.Atoms.newHintLayer)
    win._tabHintLayer = ZeD.Atoms.newHintLayer(win, "_tabHintCand")
    win._tabHintLayer:setWidth(win:getWidth())
    win._tabHintLayer:setHeight(win:getHeight())
    win:addChild(win._tabHintLayer)

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
            win._actionTabScrollOffset = (win._actionTabScrollOffset or 0) - T.stripH
            return true
        elseif zid == "tab_scroll_down" then
            win._actionTabScrollOffset = (win._actionTabScrollOffset or 0) + T.stripH
            return true
        end

        -- Tab click
        if type(zid) == "string" and zid:sub(1, 4) == "tab:" then
            local tabId = zid:sub(5)

            -- A click on the tab under an open object card only closes the
            -- card (a pinned card stays); any other tab click drops it and
            -- switches as usual.
            if win._drawerObject then
                local overTab = win._drawerMode == "tab" and win._drawerOpen and tabId == win._activeTab
                dropObjectCard(win, "tab clicked " .. tostring(tabId))
                if overTab then
                    if _syncWorldRingZones then _syncWorldRingZones(win, content) end
                    return true
                end
            end

            if tabId == "loot" then
                -- LOOT: snap to inventory-only state (no cross-animation).
                -- A rolled side comes down first: the snap below measures the
                -- whole window (the side was added on top of it afterwards).
                if win._rolled then ZeD.Curtain.finishUnroll(win) end
                if ZeD_WorldWindow._tabLeft then ZeD_WorldWindow._tabLeft(win) end   -- (QA K1 review: K1-9)
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
                settleCapPush(win)

            elseif tabId == win._activeTab then
                -- SAME TAB: toggle drawer open/closed
                if win._drawerOpen and win._drawerMode == "tab" then
                    -- Closing tab: if inventory hidden, reopen it first
                    if not win._invDrawerOpen then
                        win._invDrawerOpen = true
                        win._invDrawerTargetW = T.px(win._baseInvW or 372)
                    end
                    if ZeD_WorldWindow._tabLeft then ZeD_WorldWindow._tabLeft(win) end   -- (QA K1 review: K1-9)
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
                    settleCapPush(win)
                end
                -- Now open drawer from clean base
                if ZeD_WorldWindow._tabLeft then ZeD_WorldWindow._tabLeft(win) end   -- (QA K1 review: K1-9)
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
        -- Re-sync gamepad ring zones on every strip click (as the Character
        -- window does; the gamepad tab path syncs on its own).
        if _syncWorldRingZones then _syncWorldRingZones(win, content) end
        return true
    end

    actionTabStrip.onMouseWheel = function(self, del)
        local T = ZeD.T
        local totalH = measureWorldTabStripH(win)
        if totalH > self:getHeight() then
            win._actionTabScrollOffset = (win._actionTabScrollOffset or 0) + del * T.stripH
            return true
        end
        return false
    end

    -- ----------------------------------------------------------------
    -- updateDrawer — the drawer's mode from the selection (nil / item / tab / object)
    -- ----------------------------------------------------------------
    local function updateDrawer()
        local prevItem = win._drawerItem   -- card-visibility snapshot
        local sel = content._selectedItems
        local count = 0
        local singleItem = nil
        for item, _ in pairs(sel) do
            count = count + 1
            singleItem = item
            if count > 1 then break end
        end

        if count == 0 then content._padMarks = nil end   -- (the marks gone, their rule with them)
        -- the controller's marks hide the card even at one, as the mouse's many do
        if count == 1 and not content._padMarks then
            -- Item selected: show item card (overlay if tab active)
            if win._drawerObject then   -- the item card replaces an object card
                win._drawerObject = nil
                if win._objectCard then win._objectCard:setEntry(nil) end
            end
            if singleItem ~= win._drawerItem then
                win._itemCard:setItem(singleItem)
            end
            win._drawerItem = singleItem
            -- The card's starting sourceContext (ItemCard re-reads the item's own
            -- container every render; this stamp is the fallback).
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
            elseif win._drawerObject then   -- an object card stays open
                win._drawerMode = "object"
                win._drawerOpen = true
            elseif #(win._mcSelected or {}) > 0 then
                win._drawerMode = nil
                win._drawerOpen = true  -- keep open for MC columns
            else
                win._drawerMode = nil
                win._drawerOpen = false
            end
        end

        -- If the card has gone while focus was on worldItemCard,
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

    -- Expose updateDrawer on win so the invrow A binding (mouse-click
    -- parity: A → select item → drawer opens) can trigger it. Closure keeps
    -- `content` + `win` captured.
    win._updateDrawer = updateDrawer

    -- No D-pad direction wrappers: the D-pad is plain spatial cone-nav across
    -- all focusable zones in the focused window. Anything special lives on
    -- the elements themselves:
    --   * Disclosure expand/collapse → A (onActivate, mouse parity)
    --   * Stack expand/collapse      → A on stack chevron
    --   * Item card open             → A on inv row (selects item, drawer opens)
    --   * Item card close            → B (onCancel)
    --   * Card U/D content scroll    → onDpadDir on card action strip elements
    --   * GridScroll U/D scroll      → onDpadDir on gridScroll pseudo-focusable
    --   * Maps canvas cursor         → the left stick (MapsTab); the D-pad still navigates
    --   * Animals zone-draw cursor   → onDpadDir on isZoneDraw element

    -- Draw hook: render item list + update title bar stats
    -- the selection box being drawn from empty space, over the rows of every column (punch list 146)
    content._onRender = function(self) if self._box and ZeD.BoxSelect then ZeD.BoxSelect.draw(self) end end
    content._onPrerender = function(self)
        local T = ZeD.T
        -- Suppress vanilla loot panel if it re-shows (not once safe mode has handed
        -- it back: this window may draw one last frame after a trip)
        local vl = getPlayerLoot(win.playerNum or 0)   -- (this window's own player's page: split view)
        if vl and vl:getIsVisible() and not ZeD.Safe.on("windows") then vl:setVisible(false) end

        closeCardIfItemGone(win, self)

        -- what the list shows follows the selection, by the container object: the view, a last column
        -- whose container left reach, and below the columns themselves (InventoryRenderer's syncColStates)
        _holdWorldView(win)
        if #(win._mcSelected or {}) == 0 and self._colStates then
            exitWorldMC(win, self)
            if _syncWorldRingZones then _syncWorldRingZones(win, self) end
        end
        local colsBefore = self._colStates

        local mcSel = win._mcSelected or {}
        local colCount = #mcSel + (win._mainVisible and 1 or 0)

        if #mcSel > 0 and colCount >= 2 then
            -- Multi-column MC: render side-by-side
            local colSel = {}
            for _, ci in ipairs(mcSel) do
                colSel[#colSel + 1] = ci
            end
            if win._mainVisible then
                -- Dedup _activeContainer if already in mcSel.
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
            win._titleBase = ZeD.tr(#colSel == 1 and "UI_ZeD_World_ContainersOne" or "UI_ZeD_World_ContainersMany", #colSel)
            win._titleCount = nil
            self._ccEntry = nil
            self._defaultHdrYOffset = ZeD.T.stripH   -- (row 1, read fresh: punch list 178)
            r.renderMultiColumnContent(self)
            -- (after the columns drew: they now hold this frame's picks) the help line's own words,
            -- every shown column's things, and what is picked across them (InventoryPicked.lua)
            win._statusLine = ZeD.InventoryPicked.line(self, self._colStates, nil,
                "UI_ZeD_Inv_ItemsOne", "UI_ZeD_Inv_ItemsMany", win._playerObj)
        else
            -- Single container: determine which to show
            local viewIdx
            if #mcSel > 0 and not win._mainVisible then
                viewIdx = mcSel[1]
                -- (one column left: this list, and the pointer's and the drop's column state follows it)
                self._selectedContainers, self._containers = { viewIdx }, win._containers
                r.syncColStates(self)
            else
                viewIdx = win._viewedContainer or win._activeContainer
            end
            local cnt = win._containers[viewIdx]
            -- (set every frame: the title adds the open tab to it, composeWorldTitle)
            win._titleBase = ZeD.tr("UI_ZeD_World_Title")
            win._titleCount, win._statusLine = nil, nil
            if cnt then
                local cInv = cnt.inventory
                -- (what the rows show is counted, as the Character window does; a mod's gate, ContainerGates.lua,
                -- lets only some show, and its words stand for the weight; Immersive Searching's "Not searched")
                local cItems = cInv and ZeD.InventoryRenderer.shownCount(self, cInv, win._playerObj) or 0
                local cWeight = cInv and round(cInv:getCapacityWeight(), 1) or 0
                local cMax = cInv and round(ZeD.InventoryRenderer.capacityOf(cInv, win._playerObj), 1) or 0

                self._containerInfo = {
                    name    = cnt.name,
                    texture = not cnt.isFloor and cnt.texture or nil,
                    stats   = cnt.isFloor and "" or ZeD.ContainerGates.status(cInv, win._playerObj) or ZeD.Atoms.loadText(cWeight, cMax),
                    -- (QA's visual noise audit 2, Nov 20 2026: an empty list says "Nothing here." alone, no "0 items")
                    count   = (cItems == 0) and "" or ZeD.tr(cItems == 1 and "UI_ZeD_Inv_ItemsOne" or "UI_ZeD_Inv_ItemsMany", cItems),
                }

                -- the title is the container's name (the open tab follows it, below). (QA's visual noise audit 1,
                -- Nov 20 2026: its count was a title stat too, over the heading's own count; the heading keeps it)
                win._titleBase = cnt.name
                win._titleCount = nil
                self._inventory = cInv
                -- the help line's own words: "3 of 48 picked | 4.2 kg" while rows are picked
                -- (InventoryPicked.lua); nothing at rest, the heading counts. The one column
                -- left of several keeps its picks in its column state, so that counts too.
                win._statusLine = ZeD.InventoryPicked.line(self,
                    (#mcSel > 0 and not win._mainVisible) and self._colStates or nil, cItems,
                    "UI_ZeD_Inv_ItemsOne", "UI_ZeD_Inv_ItemsMany", win._playerObj)
            end
            self._ccEntry = cnt
            self._hdrYOffset = ZeD.T.stripH   -- (row 1, read fresh: punch list 178)
            r.renderItemList(self)
        end
        -- (the columns were rebuilt above: a column gone snaps the width, as a click on the strip does, and the
        -- controller's stops take the new columns. A container that only changed place keeps the width and the
        -- controller's focus: the sync is a mode's reset, and the per-frame _worldMCSlotStale follows the new place.)
        if colsBefore and self._colStates ~= colsBefore and #self._colStates ~= #colsBefore then
            snapWorldColumns(win)
            self._activeCol = #self._colStates
            if _syncWorldRingZones then _syncWorldRingZones(win, self) end
        end
        if ZeD.ContainerControls then
            local okF, eF = pcall(ZeD.ContainerControls.syncFocus, win, self)
            if not okF then ZeD.logOnce("ContainerControls focus", eF) end
        end

        -- the controller's stops (a function of its own: the drawer runs it too while this
        -- side does not draw, the tab drawer taking the whole window)
        content._focusRefresh(self)

        -- The title is built in the window's prerender (composeWorldTitle: this side does
        -- not draw while the tab drawer takes the whole window). The stats are status
        -- only: the item count.
        local stats = win._titleStatsT or {}
        win._titleStatsT = stats
        local st1 = stats[1] or {}
        stats[1] = st1
        if win._titleCount then
            st1.text, st1.noMark = win._titleCount, true
            win.titleStats = stats
        else
            win.titleStats = {}
        end
    end

    -- The World window's tab stops, the per-frame refresh of the worldTabContent zone (kept out of
    -- content._focusRefresh so the controller can ask for it between frames: win._focusFresh)
    content._tabStopsRefresh = function(self, Focus)
        -- Per-frame refresh for the worldTabContent zone. Runs for
        -- tab-specific content that is not an item list (forage stances,
        -- animals submodes, the craft and build zones, the maps toolbar
        -- and canvas cursor). Loot no longer lands here (invrows live in
        -- worldMainInv).
        if Focus and win._focusRing and (
                 win._activeTab == "forage" or
                 win._activeTab == "animals" or
                 win._activeTab == "craft" or
                 win._activeTab == "build" or
                 win._activeTab == "maps" or
                 win._activeTab == "radio" or -- as in the Char window: radio
                                            -- chassis zones stamped during
                                            -- render, picked up next frame.
                 win._activeTab == "vehicle" or -- Vehicle tab zones stamped during render
                 win._activeTab == "furniture" or -- Furniture tab zones stamped during render
                 ZeD_WorldWindow._extTabs[win._activeTab] ~= nil   -- a tab another file added (addTab)
               ) then
            -- Per-frame refresh for NON-Loot World tabs. Their hit zones (the
            -- Forage search button and disclosure, _animalsSubmodeZones, ...)
            -- are stamped by each tab's renderer every frame. _syncWorldRingZones
            -- fires on tab switch BEFORE the new tab's renderer runs, so it reads
            -- empty tables. This catch-up keeps worldTabContent in sync with live data.
            local newEls = _buildWorldPanelFocusables(win, self, win._activeTab) or {}
            local snap   = win._lastTabContentSnapshot
            local newN   = #newEls
            local dirty  = ZeD_WorldWindow._tabSnapDirty(snap, win._activeTab, newEls)
            -- Pending card-jump after recipe selection. CC.buildFocusables
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

            -- Craft + build: the scroll shifts recipeRow screen-y, and stale
            -- focusable coords break cone-nav until the next rebuild. They
            -- register every recipe row (Craft 541, Build 77), so rebuilding
            -- every frame costs ~2.5 ms a frame on Craft; the rebuild is keyed
            -- on scroll position, list geometry and dropdown state instead.
            local scrollKey = nil
            do
                local stk = (win._activeTab == "craft" and win._craftState)
                         or (win._activeTab == "build" and win._buildState) or nil
                if stk then
                    local sp = stk.scroll and stk.scroll.scrollPos or 0
                    local lg = stk._listGeo
                    scrollKey = tostring(sp) .. ":" .. tostring(lg and lg.y or 0) .. ":" .. tostring(lg and lg.h or 0)
                        .. ":" .. tostring(stk.catDropdownOpen) .. ":" .. tostring(stk.catDropdownScroll or 0)
                        -- (the band's stops are last and never move, so the card's and the
                        -- alternatives' scroll and the band's pop-up lists key the rebuild too)
                        .. ":" .. tostring(stk.cardScroll and stk.cardScroll.scrollPos or 0)
                        .. ":" .. tostring(stk.altScroll and stk.altScroll.scrollPos or 0)
                        .. ":" .. tostring(stk.sortMenuOpen) .. ":" .. tostring(stk.showMenuOpen)
                        -- (the band's shape, - n + or the one amount box, and the recipe it was drawn
                        -- for, both stamped by the draw that made the zones. Keyed on state.selected
                        -- the key would change one frame early, while the zones were still the last
                        -- recipe's; the next frame's stops could match the old count and ends, and the
                        -- box would go without its stop at 1280x720, UI scale 2.0, Large text)
                        .. ":" .. tostring(stk._bandSingle) .. ":" .. tostring(stk._bandSel)
                        -- (the list itself: a search, a category or a Show that filters it rebuilds the sections, and
                        -- the rows' stops must follow; the scroll and geometry alone stayed the same, so a pad player
                        -- who searched could not move onto the results: QA cb_calls, Nov 25 2026)
                        .. ":" .. tostring(stk._sections) .. ":" .. tostring(stk._sectionsTotalH or 0)
                    -- stations: binding, station dropdown and station-view controls
                    if win._activeTab == "craft" and ZeD.CraftingTab and ZeD.CraftingTab.focusKey then
                        scrollKey = scrollKey .. ":" .. tostring(ZeD.CraftingTab.focusKey(win))
                    end
                    if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
                end
            end
            -- Forage: its last stop (the body's scroll surface) and
            -- the band's Search never move, so the body's scroll and the fold key the rebuild (More
            -- detail's disclosure scrolls with the body)
            if win._activeTab == "forage" then
                local sc = win._forageScroll
                scrollKey = tostring(sc and sc.scrollPos or 0) .. ":" .. tostring(win._moreDetailOpen)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            -- (the Ranch page's stops move with its scroll)
            if win._activeTab == "animals" and win._animalsScroll and win._animalsScroll.visible then
                scrollKey = tostring(win._animalsScroll.scrollPos)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            local extT = ZeD_WorldWindow._extTabs[win._activeTab]
            if extT and extT.scrollKey then
                scrollKey = tostring(extT.scrollKey(win))
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            if win._activeTab == "vehicle" and ZeD.MechanicsTab and ZeD.MechanicsTab.focusKey then
                scrollKey = ZeD.MechanicsTab.focusKey(win)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            if win._activeTab == "furniture" and ZeD.FurnitureTab and ZeD.FurnitureTab.focusKey then
                scrollKey = ZeD.FurnitureTab.focusKey(win)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            local alwaysRebuild = false

            -- Identity-preserve focus by element id. When the
            -- focusables array churns (a scroll, a filter
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
            -- Craft / Build name where the focus lands as a pop-up list opens (its
            -- current choice) or shuts (back on its box), as the Character window honours it
            if (win._activeTab == "craft" or win._activeTab == "build") and newEls._focusIdx then
                preserveIdx = newEls._focusIdx
            end
            -- Post-create-zone focus hint. gpConfirm seeds
            -- win._animalsFocusAfterCreate with the zone name; it is resolved
            -- here to a zonecard idx so the new zone lands focused instead
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
            -- Navigation focus target. Zonecard/roster/butcher
            -- onActivate sets this to "breadcrumb" so the user lands on the
            -- back-nav element in the new view, not whatever idx-clamp
            -- picks (e.g. sort btn at idx 4 for idx-4 zonecard sources).
            -- It may also be an element's id: a zone band button pressed
            -- lands on the one that takes its place (All hungry -> Clear).
            -- (a target not drawn yet is kept a moment: AT.navFocusIndex)
            local navIdx = nil
            if win._activeTab == "animals" and win._animalsNavFocusTarget and ZeD.AnimalsTab
               and ZeD.AnimalsTab.navFocusIndex then
                navIdx = ZeD.AnimalsTab.navFocusIndex(win, newEls, getTimestampMs())
                if navIdx then preserveIdx = navIdx end
            end

            if win._activeTab == "vehicle" and win._mechFocusTarget and ZeD.MechanicsTab.focusTargetIndex then
                local ti = ZeD.MechanicsTab.focusTargetIndex(win, newEls)
                if ti then preserveIdx = ti; cardJumpIdx = ti end
            end
            if dirty or alwaysRebuild or cardJumpIdx or navIdx then
                win._lastTabContentSnapshot = {
                    tab     = win._activeTab,
                    scrollKey = scrollKey,
                    n       = newN,
                    firstId = newEls[1] and newEls[1].id or nil,
                    lastId  = newEls[newN] and newEls[newN].id or nil,
                    lastY   = newEls[newN] and newEls[newN].y or nil,
                    lastH   = newEls[newN] and newEls[newN].h or nil,
                    animals = ZeD_WorldWindow._tabSnapAnimals(newEls),
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
    end

    -- What the controller reads between frames (FocusManager calls it before a press is worked on, a landing is
    -- looked for or the stops are listed): the tab's stops, when they waited for the mouse (Focus.stopsMayWait)
    win._focusFresh = function(w)
        local Focus = ZeD.Input and ZeD.Input.Focus
        if w._tabStopsStale and Focus and w._focusRing then
            w._tabStopsStale = nil
            content._tabStopsRefresh(content, Focus)
        end
    end

    -- The World window's per-frame stop refresh (the container strip, the main list, the MC columns,
    -- the tab's stops, the item card). It lives outside the content's
    -- prerender, which does not run while the content is hidden (the tab drawer takes the whole
    -- window at 1280x720, UI scale 2.0): the Craft tab's stops would stay as they were when
    -- the tab opened (no card, no amount box, no Craft). The drawer's prerender runs it then.
    content._focusRefresh = function(self)
        local T = ZeD.T
        -- --------------------------------------------------------
        -- RING MODEL: PER-FRAME WORLDMAININV REFRESH (World Window)
        -- Unconditional — worldMainInv holds the active container's invrows
        -- on ALL tabs, mirroring Character's charMainInv. Same dirty check,
        -- identity preservation, container-change guard.
        -- --------------------------------------------------------
        local Focus = ZeD.Input and ZeD.Input.Focus
        if Focus and win._focusRing then
            _refreshWorldStripFocus(win, Focus)   -- (the container strip's stops)
            _closeCardIfItemGone(win)

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
                    -- MC state transition forces rebuild even
                    -- when item count is unchanged. The placeholder branch
                    -- (mcActive + empty mainInv) needs to fire on MC enter
                    -- even if mainInv was already empty before MC.
                    local mcActive = win._mcSelected and #win._mcSelected > 0
                    if win._lastMcActiveForMainInv ~= mcActive then
                        dirty = true
                        win._lastMcActiveForMainInv = mcActive
                    end
                    -- Rebuild on the rows' places too (scroll, list or grid, width)
                    -- (Nov 15 2026, add-on hooks: and an add-on layout's number, GridLayout.lua: a new layout moves the cells)
                    local geo = tostring(self._scroll and self._scroll.scrollPos) .. ":" .. tostring(self._gridCell) .. ":" .. tostring(self._gridLayoutGen)
                        .. ":" .. tostring(self._renderW or self:getWidth()) .. ":" .. #(self._viewToggleRects or {}) .. ":" .. ZeD.InventoryRenderer.filterGen(self)
                        .. ":" .. tostring(self._rowView and self._rowView.bottom)   -- (the list's view: which rows are out of it)
                    if win._lastInvRowGeo ~= geo then win._lastInvRowGeo = geo; dirty = true end
                    -- (the container shown is part of what these rows are, by the object)
                    if win._lastInvRowInv ~= self._inventory then win._lastInvRowInv = self._inventory; dirty = true end
                    local keepId = nil
                    for _, z in ipairs(win._focusRing or {}) do
                        if z.zone == "worldMainInv" then
                            local fe = z.elements and z.elements[z.focusedElementIdx or 1]
                            -- (an open stack's header too: no item; punch list 245)
                            if fe and (fe.isViewToggle or fe.isStackHead or fe.isCatHead) then keepId = fe.id end
                        end
                    end

                    if dirty then
                        local snap = {}
                        if newItems then
                            for si = 1, #newItems do snap[si] = newItems[si] end
                        end
                        win._lastInvRowSnapshot = snap

                        local newEls = _buildWorldInvRowFocusables(win)
                        -- When MC is active AND the last colState
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
                                    -- (the neighbouring ROW: the view button
                                    -- and the Filter come after the rows, never a stand-in for one)
                                    local nRows = 0
                                    for _, ne in ipairs(newEls) do if ne.item then nRows = nRows + 1 end end
                                    preserveIdx = math.min(oldIdx, math.max(1, nRows))
                                end
                            end
                            if keepId then
                                for i, el in ipairs(newEls) do if el.id == keepId then preserveIdx = i end end
                            end

                            Focus.setRingZoneElements(win, "worldMainInv", newEls, preserveIdx)
                            Focus.setZoneFocusable   (win, "worldMainInv", true)
                            -- (punch list 246: the row it was on gone and no rows left: the ground's button, not Filter)
                            if focItem and not keepId then ZeD_WorldWindow._groundIfNoRows(win, Focus, newEls) end
                            local resolvedEl = newEls[preserveIdx]
                            if resolvedEl then
                                -- (a stack's header: its first item, and its row's place for the scroll; punch list 245)
                                win._gpFocusedRowItem = resolvedEl.item or resolvedEl.rep
                                self._gpFocusedRowItem = resolvedEl.item or resolvedEl.yKey
                            end
                        end
                    end
                end
            end
        end

        -- --------------------------------------------------------
        -- RING MODEL: PER-FRAME PER-COLUMN MC ZONE REFRESH
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
                -- rebuilt only when the column changed (_worldMCSlotStale)
                if _worldMCSlotStale(win, self, slot) then
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
                    -- (a view or Filter stop keeps the focus: a press on the Filter bar rebuilds the column)
                    preserveIdx = ZeD.InventoryRenderer.keepToggleIdx(win, zoneName, newEls, preserveIdx)
                    Focus.setRingZoneElements(win, zoneName, newEls, preserveIdx)
                    Focus.setZoneFocusable   (win, zoneName, #newEls > 0)
                end
            end
        else
            win._lastMCSnap = nil  -- the zones are rebuilt on the way back to Loot
        end

        -- the tab's stops (content._tabStopsRefresh, above). Rebuilt every
        -- frame they cost the most on Craft (every recipe row). With the mouse and keyboard in use, no controller mark
        -- showing and no landing waiting (Focus.stopsMayWait) they wait; the first frame after, and anything
        -- the controller does first (FocusManager's win._focusFresh), rebuilds them from scratch.
        if Focus and win._focusRing then
            if not (Focus.stopsMayWait and Focus.stopsMayWait(win)) then
                win._tabStopsStale = nil
                content._tabStopsRefresh(self, Focus)
            else
                win._tabStopsStale, win._lastTabContentSnapshot = true, nil
            end
        end

        -- Per-frame refresh for worldItemCard zone. Mirrors Character
        -- window's charItemCard refresh: the card's toggleRects / verbRects
        -- are stamped by render each frame; this picks them up into the ring.
        -- Focusable state tracks card visibility (`_drawerItem ~= nil`), NOT
        -- `_drawerMode`. On non-Loot tabs the card overlays the tab drawer
        -- while `_drawerMode` stays "tab" — the card is still interactive.
        if Focus and win._focusRing then
            local cardVisible = (win._drawerItem ~= nil)
            -- the object card shares the card zone when no item card shows
            local objCard = win._objectCard
            local objVisible = (not cardVisible) and win._drawerObject ~= nil and objCard ~= nil
                and objCard:getIsVisible()
            local cardEls, keepIdx = {}, nil
            if cardVisible then
                cardEls = _buildWorldCardActionFocusables(win)
            elseif objVisible then
                -- keep the focused element by id across rebuilds; honour a
                -- pending jump (ADD FUEL / LIGHT / confirm) once it is stamped
                local zoneT
                for _, z in ipairs(win._focusRing) do
                    if z.zone == "worldItemCard" then zoneT = z; break end
                end
                local prev = zoneT and zoneT.elements and zoneT.elements[zoneT.focusedElementIdx or 1]
                local wantId = objCard._pendingFocus or (prev and prev.id)
                cardEls = objCard:buildFocusables(win)
                for i, el in ipairs(cardEls) do
                    if el.id == wantId then keepIdx = i; break end
                end
                if keepIdx and objCard._pendingFocus == wantId then objCard._pendingFocus = nil end
                if not keepIdx and objCard._grabFocus then
                    -- the primary verb, else the first verb, else the back button (the verbs sit in the band at the
                    -- foot, a danger one leftmost, so the first is no longer the main one: Hermit, Nov 26 2026)
                    for i, el in ipairs(cardEls) do
                        if el.isPrimary and string.sub(el.id or "", 1, 8) == "oc:verb:" then keepIdx = i; break end
                    end
                    if not keepIdx then
                        for i, el in ipairs(cardEls) do
                            if string.sub(el.id or "", 1, 8) == "oc:verb:" then keepIdx = i; break end
                        end
                    end
                    keepIdx = keepIdx or 1
                end
            end
            if cardVisible then
                Focus.setRingZoneElementsKeepId(win, "worldItemCard", cardEls)
            else
                Focus.setRingZoneElements(win, "worldItemCard", cardEls, keepIdx)
            end
            Focus.setZoneFocusable   (win, "worldItemCard", (cardVisible or objVisible) and #cardEls > 0)
            if objVisible and objCard._grabFocus and #cardEls > 0 then
                -- opened from a menu: the controller lands on the card
                for i, z in ipairs(win._focusRing) do
                    if z.zone == "worldItemCard" then win._focusIdx = i; break end
                end
                win._focusPendingEntry = nil   -- (the card holds the focus now)
                -- a card opened from the world menu (or after a walk, as 3D
                -- placement does) finds no ZeD window focused: take focus, so
                -- the controller is on the card without pressing RB first (this window's player's pad and focus)
                local D = ZeD.Input and ZeD.Input.Detector
                if D and D.getMode and D.getMode(win.playerNum) == "gamepad" and Focus.getFocusedWindow(win.playerNum) ~= win then
                    Focus.claimFocus(win)
                end
                objCard._grabFocus = nil
            end
        end
    end
    -- the help line's words when the pointer is over nothing with help of its own
    win.getStatusLine = function(self) return self._statusLine end

    -- Draw drag ghost at window level
    local _baseWinRender = win.render
    win.render = function(self)
        _baseWinRender(self)
        if content._drag and content._drag:isActive() then
            content._drag:drawGhost(self)
        end
        -- The structure line between the inventory and the drawer (after all
        -- children, so the drawer's content never covers it). It runs from the
        -- title bar's line to the help line's line only: never across the title
        -- bar, the help line or the frame. None while windowshaded.
        if win._dividerX and not self.windowShaded then
            local T = ZeD.T
            local brd = T.borderS
            local y0 = self:titleBarHeight()
            local y1 = self:getHeight() - self:footerHeight()
            if y1 > y0 then self:drawRect(win._dividerX, y0, T.px(1), y1 - y0, brd.a or 1, brd.r, brd.g, brd.b) end
        end
        saveWorldStateThrottled(self)  -- keep the remembered layout current (about once a second)
    end

    -- Curtain (WindowCurtain.lua): the containers roll up under their title
    -- while a tab drawer stays open (the map as a minimap)
    ZeD.Curtain.attach(win, {
        sideW = function() return ZeD.T.px(CONTAINER_STRIP_W) + content:getWidth() end,
        canRoll = function()
            return win._drawerOpen and win._drawerMode == "tab" and win._activeTab ~= nil
                and #(win._mcSelected or {}) == 0 and (win._rolled or content:isVisible())
        end,
        chip = function()
            -- (the container the list shows: a mouse pick on a non-Loot tab sets only the view) (QA B11-3)
            local e = win._containers and win._containers[win._viewedContainer or win._activeContainer]
            local inv = e and e.inventory
            -- (what the list shows, not the raw count: a gate mod hides some) (QA B10-5)
            return e and e.name or ZeD.tr("UI_ZeD_World_Title"), inv and ZeD.InventoryRenderer.liveCount(inv, win._playerObj) or 0
        end,
        dropInv = function()
            local e = win._containers and win._containers[win._viewedContainer or win._activeContainer]   -- (QA B11-3)
            -- the rolled list is frozen and the game's transfer has no distance check: a container out of reach takes
            -- no drop, as the title-bar drop refuses it (QA B11-3)
            if e and not e.isFloor and not ZeD_WorldWindow.inReach(e.inventory, win.playerNum) then return nil end
            return e and e.inventory
        end,
        title = function()
            for _, tab in ipairs(WORLD_TABS) do if tab.id == win._activeTab then return ZeD_WorldWindow.tabLabel(tab, win) end end
            return ZeD.tr("UI_ZeD_World_Title")
        end,
        onChange = function(rolled)
            if not rolled and _syncWorldRingZones then _syncWorldRingZones(win, content) end
        end,
        onFrame = function()
            local Focus = ZeD.Input and ZeD.Input.Focus
            if not (Focus and win._focusRing) then return end
            Focus.setRingZoneElements(win, "worldMainInv", {})
            Focus.setZoneFocusable(win, "worldMainInv", false)
            local el = ZeD.Curtain.padElement(win, containerStrip:getX(), containerStrip:getY())
            Focus.setRingZoneElements(win, "worldContainerStrip", el and { el } or {}, 1)
            Focus.setZoneFocusable(win, "worldContainerStrip", el ~= nil)
        end,
    })
    -- Halves (WindowHalves.lua): the containers (left) and the drawer (right) each roll up
    -- and pin on their own; the pins sit at the title bar's two ends (the Maps tab pinned
    -- open while the containers roll with the pointer)
    ZeD.Halves.attach(win, { key = "world", side = "right", strip = "_actionTabStrip", zone = "worldTitlePins" })

    -- ----------------------------------------------------------------
    -- FLOOR-AWARE TRANSFER
    --   TO floor   → ISInventoryPaneContextMenu.dropItem() (vanilla's drop)
    --   FROM floor → ZeD_WorldWindow.transferFromFloor (vanilla's transfer
    --                from the floor container; the server's in multiplayer)
    --   Otherwise  → vanilla's transfer action, with vanilla's own time
    -- ----------------------------------------------------------------
    local function doTransfer(contentPanel, items, srcInv, destInv)
        local playerObj = contentPanel._playerObj
        local playerNum = playerObj:getPlayerNum()
        local srcIsFloor  = srcInv ~= nil and srcInv:getType() == "floor"
        local destIsFloor = destInv ~= nil and destInv:getType() == "floor"
        if srcIsFloor and destIsFloor then return end
        -- seated with the window shut, nothing goes out to the ground (QA B6-9)
        if destIsFloor and ZeD.InventoryRenderer.carWindowShut(playerObj) then return end
        -- a mod's gate refuses things into this container (ContainerGates.lua: never searched)
        if destInv and not destIsFloor and ZeD.ContainerGates.refuses(destInv, playerObj) then return end
        -- (Nov 15 2026, add-on hooks: what an add-on's rule refuses stays, the first reason over the head, ItemRules.lua)
        items = ZeD.ItemRules.filter(items, destInv, playerObj, srcInv)

        for _, item in ipairs(items) do
            if destIsFloor then
                if not item:isFavorite() then
                    ISInventoryPaneContextMenu.dropItem(item, playerNum)
                end
            elseif srcIsFloor then
                ZeD_WorldWindow.transferFromFloor(playerObj, item, destInv)
            else
                if item:getContainer() == srcInv and destInv:isItemAllowed(item) then
                    local move = ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, srcInv, destInv)
                    move._zedApart = true   -- (a drag: never part of an action's run, ZeD_PutBack.lua) (L1-3)
                    ISTimedActionQueue.add(move)
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
        -- only a release inside the list top to bottom picks a column; outside it falls through (beast W1)
        local my = contentPanel:getMouseY()
        if my < 0 or my >= contentPanel:getHeight() then return false end
        local _, dropCs = getColumnAtX(contentPanel, mx)
        if not dropCs then return false end
        local destInv = dropCs.inventory
        local srcContainer = srcInv or contentPanel._inventory
        if not destInv or destInv == srcContainer then return false end
        local srcIsFloor  = _isFloor(srcContainer)
        local destIsFloor = _isFloor(destInv)
        if not srcIsFloor and not destIsFloor then return false end
        -- (Nov 15 2026, add-on hooks: released over an add-on's grid, its drop first; a refused place moves nothing,
        -- GridLayout.lua. False without one)
        if ZeD.GridLayout.active() and ZeD.GridLayout.takeDrop(contentPanel, ZeD.InventoryRenderer.dragItems(contentPanel, items, srcContainer), srcContainer) then return true end
        doTransfer(contentPanel, items, srcContainer, destInv)
        return true
    end

    -- ----------------------------------------------------------------
    -- MOUSE HANDLERS
    -- ----------------------------------------------------------------
    local countSelected        = r.countSelected
    local findIndex            = r.findIndex
    local handleDrop           = r.handleDrop

    -- Select all: every row of the list (the column under the pointer), the card shut; a double-click on the list's
    -- empty space (ZeD_BoxSelect.doubleEmpty; punch list 146)
    content.zedSelectAll = function(self)
        local _, cs = getColumnAtX(self, self:getMouseX())
        local sel = (cs and cs.selectedItems) or self._selectedItems
        local flat = (cs and cs.flatItems) or self._flatItems
        if not (sel and flat) then return false end
        for k in pairs(sel) do sel[k] = nil end
        for _, it in ipairs(flat) do sel[it] = true end
        local last = flat[#flat]
        if cs then cs.lastClickedItem = last else self._lastClickedItem = last end
        self._padMarks = true
        updateDrawer()
        return true
    end

    content.onMouseDown = function(self, x, y)
        self._padMarks = nil   -- (a mouse press: the mouse's card rule again)
        -- the container buttons' row
        do
            local ccZone = self:hitZoneAt(x, y)
            local ccId = ccZone and ccZone.id
            if type(ccId) == "string" and ccId:sub(1, 3) == "cc:" and ZeD.ContainerControls then
                -- (paused, the container buttons wait for play with the other actions: KISS #41)
                if ZeD.PausedLook and ZeD.PausedLook.on() == true then return true end
                ZeD.ContainerControls.press(self, tonumber(ccId:sub(4)))
                return true
            end
        end
        -- MC column-aware scrollbar check. Only a press on a bar as drawn is the bar's (hitY): the strip above it,
        -- beside the heading's controls, holds the Filter's Clear and the end of its chips' lines.
        if #(win._mcSelected or {}) > 0 and self._colStates then
            for _, cs in ipairs(self._colStates) do
                local sy = cs.scroll and cs.scroll:hitY(x, y)
                if sy then
                    cs.scroll:handleMouseDown(sy)
                    self._activeScroll = cs.scroll
                    return true
                end
            end
        else
            local sy = self._scroll:hitY(x, y)
            if sy then
                self._scroll:handleMouseDown(sy)
                return true
            end
        end

        local zone = self:hitZoneAt(x, y)
        if not zone then
            -- empty space: a double-click selects every row; a drag from here draws a box that selects the rows it
            -- crosses (punch list 146)
            if ZeD.BoxSelect and ZeD.BoxSelect.doubleEmpty and ZeD.BoxSelect.doubleEmpty(self, x, y) and self.zedSelectAll then
                self:zedSelectAll()
                return true
            end
            if ZeD.BoxSelect then
                local _, bCs = getColumnAtX(self, x)
                local bSel = (bCs and bCs.selectedItems) or self._selectedItems
                if bSel then
                    ZeD.BoxSelect.start(self, x, y, bSel, bCs and function(px) return (getColumnAtX(self, px)) end or nil)
                end
            end
            return true
        end
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

        -- a column's view button (InventoryRenderer: "view:flip:<container>")
        if type(zid) == "string" and zid:sub(1, 5) == "view:" then
            ZeD.InventoryRenderer.onViewZone(zid, self)
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

        -- Stack chevron toggle
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
        -- double-click: vanilla's quick use (InventoryRenderer.doubleClick)
        -- (Shift too, as the game: Shift + double-click takes a garment and wears it; the first click of the pair
        -- still does Shift's run selection below, L1-5)
        if not isCtrlKeyDown() and self._playerObj
            and ZeD.InventoryRenderer.doubleClick(self, item, self._playerObj:getPlayerNum(), (getColumnAtX(self, x)), isShiftKeyDown()) then
            self._deferredSelect = nil
            return true
        end

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

        -- (the game's own readers, as the Character window's copy of this click and this function's double-click
        -- guard use; Nov 18 2026, QA's release test could not reach the keys read directly)
        local isCtrl  = isCtrlKeyDown()
        local isShift = isShiftKeyDown()

        if isCtrl then
            self._padMarks = true   -- (picking rows: the card stays shut, even at one; punch list 146)
            if sel[item] then sel[item] = nil
            else sel[item] = true end
            if colCs then colCs.lastClickedItem = item
            else self._lastClickedItem = item end
            local dragItems = {}
            for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
            if #dragItems > 0 then
                -- (the chip counts what the rows carry: a closed stack's row is its whole stack)
                self._drag:beginPending(dragItems, dragItems[1], screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, dragItems, self._dragSourceInv))
            end

        elseif isShift and lastClicked then
            self._padMarks = true   -- (picking rows: the card stays shut, even at one; punch list 146)
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
                self._drag:beginPending(dragItems, item, screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, dragItems, self._dragSourceInv))
            end

        else
            if sel[item] then
                self._deferredSelect = { item = item, colIdx = colIdx }
                local dragItems = {}
                for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
                self._drag:beginPending(dragItems, item, screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, dragItems, self._dragSourceInv))
            else
                for k in pairs(sel) do sel[k] = nil end
                sel[item] = true
                if colCs then colCs.lastClickedItem = item
                else self._lastClickedItem = item end
                self._drag:beginPending({item}, item, screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, {item}, self._dragSourceInv))
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

        if self._box then
            local last, bCol = ZeD.BoxSelect.finish(self)
            if last then
                self._padMarks = true   -- (rows picked by a box: the card stays shut, even at one)
                local cs = bCol and self._colStates and self._colStates[bCol]
                if cs then cs.lastClickedItem = last else self._lastClickedItem = last end
            end
            updateDrawer()
            return true
        end

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
            -- (the rows let go over another list: this list lets go of their picks too) (QA B5-10)
            if ZeD_CharacterWindow and ZeD_CharacterWindow.letGoOfDragged then
                ZeD_CharacterWindow.letGoOfDragged(self, items, self._dragSourceInv, x, y)
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
        if self._box then
            local last, bCol = ZeD.BoxSelect.finish(self)
            if last then
                self._padMarks = true   -- (rows picked by a box: the card stays shut, even at one)
                local cs = bCol and self._colStates and self._colStates[bCol]
                if cs then cs.lastClickedItem = last else self._lastClickedItem = last end
            end
            updateDrawer()
            return true
        end
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
            -- (released outside this list: it lets go of the dragged rows' picks, as the game's list does) (QA B5-10)
            if ZeD_CharacterWindow and ZeD_CharacterWindow.letGoOfDragged then
                ZeD_CharacterWindow.letGoOfDragged(self, items, self._dragSourceInv)
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
        if self._box then ZeD.BoxSelect.move(self, self:getMouseX(), self:getMouseY()); return true end
        ISPanel.onMouseMove(self, dx, dy)
        local T = ZeD.T
        self._scroll:handleMouseMove(self:getMouseY() - self._scroll.y)   -- (on the bar's own y, as its press is)

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
        if self._box then ZeD.BoxSelect.move(self, self:getMouseX(), self:getMouseY()); return true end
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
        -- (Nov 15 2026, add-on hooks: during a drag over an add-on's grid the wheel turns the dragged thing,
        -- GridLayout.lua; nothing without one)
        if ZeD.GridLayout.dragTurn() then return true end
        -- over the container buttons' ribbon: it scrolls sideways
        if ZeD.ContainerControls and ZeD.ContainerControls.wheel(self, del) then return true end
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
        self._padMarks = nil
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
        if ZeD.PausedLook and ZeD.PausedLook.on() == true then return true end   -- (paused: no item menu, as the game's; KISS #41)

        local colIdx, colCs = getColumnAtX(self, x)
        local inv = (colCs and colCs.inventory) or self._inventory

        -- The menu acts on the row under the cursor, as in vanilla: a row that
        -- is not already selected becomes the selection first (see _worldRmbMenuItems).
        local menuItems, reselected = _worldRmbMenuItems(self, x, y, colIdx, colCs)
        if reselected then updateDrawer() end

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

    -- Base prerender (shaded guard only — drawer._onPrerender handles all layout); the
    -- title, every frame, from the window itself, whichever way the tab changed
    local origPrerender = win.prerender
    win.prerender = function(self)
        -- (Loot with the drawer left in tab mode folds every frame the window shows, not only when the drawer draws)
        lootDrawerFallback(self)
        composeWorldTitle(self)
        -- the container on show lit in the world (KISS #44; pcall: a light never stops the window drawing)
        pcall(ZeD_WorldWindow._lightShown, self)
        origPrerender(self)
    end
end


-- ============================================================================
-- PUBLIC API — what other files call: open and close (ZeD_CharacterWindow
-- pairs the two windows' keys through them), a tab, a container, a column,
-- an object card.
-- ============================================================================

--- Opens the World window. Player 0 only (other split-screen players keep the
--- game's own windows); never for a dead character or in safe mode. Does
--- nothing when the window is already open.
function ZeD_WorldWindow.open(playerNum)
    if not ZeD.windowsFor(playerNum) then return end   -- (split-screen: the game's own, ZeD.windowsFor)
    -- (never for a dead character)
    local p = getSpecificPlayer(playerNum or 0)
    if p and p:isDead() then return end
    if ZeD.Safe.on("windows") then return end   -- safe mode: no ZeD window (SafeMode.lua)
    if not _worldWins[playerNum or 0] then
        ZeD_WorldWindow.toggle(playerNum)
    end
end

--- True while tabId is the open tab and its drawer shows. pn: whose window (nil: the first player's).
function ZeD_WorldWindow.isTabShowing(tabId, pn)
    local win = _worldWins[pn or 0]
    return win ~= nil and win._activeTab == tabId and win._drawerMode == "tab" and win._drawerOpen == true
end

--- Opens an object card ({ def, t } from ZeD.ObjectCards) in the drawer.
--- Opens the window if needed, closes any extra columns, clears the item
--- selection, and overlays the active tab (or opens the drawer on the Loot
--- view). The controller lands on the card. Returns true when it is up.
function ZeD_WorldWindow.openObjectCard(playerNum, entry)
    if not entry then return false end
    if not ZeD.windowsFor(playerNum) then return false end   -- (split-screen: the game's own, ZeD.windowsFor)
    if not _worldWins[playerNum or 0] then
        local ok = pcall(ZeD_WorldWindow.open, playerNum or 0)
        if not ok then return false end
    end
    local win = _worldWins[playerNum or 0]
    if not (win and win._objectCard) then return false end
    local content = win._mainContent
    if content then
        -- (QA OC7, Nov 26 2026) the Loot columns stay: a card opened from the game's menu or a locked crate's
        -- button closed his extra columns (2 to 0) and never gave them back. The drawer sits beside the columns
        -- as the item card does; only a new column opened under a card still takes the card (enterWorldMC).
        content._selectedItems = {}
        content._lastClickedItem = nil
    end
    win._drawerItem = nil
    win._drawerObject = entry
    if win._drawerMode ~= "tab" then win._drawerMode = "object" end
    win._drawerOpen = true
    win._objectCard:setEntry(entry)
    win._objectCard._grabFocus = true
    return true
end

--- Closes the object card, a pinned one too; the tab underneath (or the Loot
--- view) shows again. pn: whose window (nil: the first player's).
function ZeD_WorldWindow.closeObjectCard(pn)
    local win = _worldWins[pn or 0]
    if not (win and win._drawerObject) then return end
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if win._focusRing and Focus then
        local cardIdx, backIdx
        local backZone = (win._drawerMode == "tab") and "worldTabContent" or "worldMainInv"
        for i, z in ipairs(win._focusRing) do
            if z.zone == "worldItemCard" then cardIdx = i
            elseif z.zone == backZone and z.focusable then backIdx = i end
        end
        if not backIdx then
            for i, z in ipairs(win._focusRing) do
                if z.zone == "worldMainInv" then backIdx = i end
            end
        end
        if cardIdx and backIdx and win._focusIdx == cardIdx then win._focusIdx = backIdx end
        if cardIdx then
            Focus.setRingZoneElements(win, "worldItemCard", {})
            Focus.setZoneFocusable(win, "worldItemCard", false)
        end
    end
    -- (the card's own close: a pinned card goes too, and its kind hears it was the player's close)
    win._forceDrop = true
    ZeD_WorldWindow._closingCard = true
    local ok, err = pcall(dropObjectCard, win, ZeD_WorldWindow._closeWhy or "closeObjectCard, from outside the card (a route, a tab, a trade)")
    win._forceDrop = nil
    ZeD_WorldWindow._closingCard = nil
    if not ok then print("[ZeD] WorldWindow: closing the card failed: " .. tostring(err)) end
end

--- The object card organism while a card is open in the drawer, else nil. pn: whose window (nil: the first player's).
function ZeD_WorldWindow.getObjectCard(pn)
    local win = _worldWins[pn or 0]
    return win and win._drawerObject and win._objectCard or nil
end

--- Shows one container (by its ItemContainer) in the Loot pane, leaving the
--- tab drawer as it is. The container list rebuilds every 30 frames and only
--- holds what is in reach, so a container still being walked to is looked for
--- again each tick (forcing a rebuild every 20) for up to `tries` ticks (60 by
--- default). Returns true when it showed at once; otherwise it keeps looking.
--- pn: whose window (nil: the first player's).
function ZeD_WorldWindow.selectContainer(inv, tries, pn)
    local win = _worldWins[pn or 0]
    if not (win and inv) then return false end
    local n, paused = 0, 0
    local function attempt()
        if win ~= _worldWins[pn or 0] then return true end
        for i, c in ipairs(win._containers or {}) do
            if c.inventory == inv then
                local content = win._mainContent
                if content and #(win._mcSelected or {}) > 0 and exitWorldMC then exitWorldMC(win, content) end
                win._activeContainer = i
                win._viewedContainer = nil
                win._mainVisible = true   -- (shown: a Ctrl-click or hold A after it adds a column beside it, KISS #10)
                if content then
                    content._inventory = inv
                    content._selectedItems = {}
                    content._lastClickedItem = nil
                end
                if not win._invDrawerOpen then
                    win._invDrawerOpen = true
                    win._invDrawerTargetW = ZeD.T.px(win._baseInvW or 372)
                end
                return true
            end
        end
        if (n + paused) % 20 == 0 then
            win._containerTimer = 30
            -- (a rolled window draws no strip, so the line above never reaches it and the list stays as old as the roll-up:
            -- a walk to a trailer (MechTrailer) with the pointer elsewhere would run out its tries. So it comes down once
            -- the container is in reach.)
            if win.windowShaded and ZeD_WorldWindow.inReach(inv, pn) then
                win._autoShaded = false
                win:setWindowShaded(false)
                win._outSince = getTimestampMs() + 500
            end
        end
        return false
    end
    if attempt() then return true end
    -- (OnTickEvenPaused: a click while the game is paused is looked for while it is paused, not from the unpause on.
    -- `tries` counts live ticks, a walk's worth, so a pause spends none of it: the game frozen, 120 frames of looking,
    -- then the rest wait for the unpause, MechTrailer's walk to the trailer among them.)
    local ev = Events.OnTickEvenPaused or Events.OnTick
    local function tick()
        local live = getGameSpeed() > 0
        if live then n = n + 1 else paused = paused + 1 end
        if not live and paused > 120 then return end
        -- an error in attempt() ends the retries too (the tick never outlives it)
        local ok, done = pcall(attempt)
        if not ok or done or n >= (tries or 60) then ev.Remove(tick) end
    end
    ev.Add(tick)
    return false
end

-- ----------------------------------------------------------------------------
-- (KISS #44) THE CONTAINER ON SHOW IS LIT IN THE WORLD, as the game's loot page lights it
-- (ISInventoryPage:updateContainerHighlight and onMouseOverButton, read in the game's files):
--   * the container on show (and each open Loot column) in the game's object highlight color, and outlined too
--     while the game's own option "container outline" is on (getCore():getOptionDoContainerOutline());
--   * the one under the pointer on the strip (or under the pad's mark there) outlined in the world item color,
--     only with that option on, as the game's hover.
-- The World window's list rolled away or the window rolled up: nothing is lit. A container with no object in the
-- world (the Floor, a bag in a crate) and the player himself are never lit, as in the game. Another piece of the
-- game lighting an object (the right-click menu's hover, through ISInventoryPage.OnObjectHighlighted) keeps it: ZeD
-- leaves that object alone until it lets go, as the game's page does. Lit objects: win._lit[obj] = true.
-- Module fields, not locals: this file is near Kahlua's limit.
-- ----------------------------------------------------------------------------
ZeD_WorldWindow._litElsewhere = ZeD_WorldWindow._litElsewhere or { {}, {}, {}, {} }

-- the object a container belongs to in the world (the game's ISInventoryPage:getContainerParent), or nil
function ZeD_WorldWindow._parentOf(inv)
    if not inv then return nil end
    local par = inv:getParent()
    if par then return par end
    local item = inv:getContainingItem()
    return item and item:getWorldItem() or nil
end

function ZeD_WorldWindow._unlight(pn, obj)
    pcall(function()
        obj:setHighlighted(pn, false, false)
        obj:setOutlineHighlight(pn, false)
        obj:setOutlineHlAttached(pn, false)
    end)
end

-- (QA belt row run, Nov 22 2026: #44 at 4K, crate A stayed lit after a plain click showed crate B.) What ZeD lit is
-- kept per player, not per window: a light a World window left (one closed by a path that did not put it out, or one
-- built again over it) is still known, so the window on show puts it out once it is no longer wanted.
ZeD_WorldWindow._litFor = ZeD_WorldWindow._litFor or {}
function ZeD_WorldWindow._litTable(pn)
    local t = ZeD_WorldWindow._litFor[pn + 1]
    if not t then t = {}; ZeD_WorldWindow._litFor[pn + 1] = t end
    return t
end

-- Another piece of the game holds the light on an object only while a menu of that player is up (the right-click
-- menu's hover, the disassemble menu: they let go when it closes). With no menu up, a mark left behind is stale and
-- dropped, so ZeD can put the object out. (QA belt row run, Nov 22 2026)
function ZeD_WorldWindow._elsewhereHolds(pn, obj)
    local elsewhere = ZeD_WorldWindow._litElsewhere[pn + 1]
    if not (elsewhere and elsewhere[obj]) then return false end
    local up = false
    pcall(function()
        local c = getPlayerContextMenu(pn)
        up = c ~= nil and (c:getIsVisible() or (c._zedMenu ~= nil and c._zedMenu._ctx ~= nil and c._zedMenu._ctx.open == true))
    end)
    if not up then elsewhere[obj] = nil end
    return up
end

function ZeD_WorldWindow._unlightAll(win)
    if not win then return end
    local pn = win.playerNum or 0
    local lit = ZeD_WorldWindow._litTable(pn)
    -- (keys gathered first: a table is not changed while pairs walks it, Kahlua)
    local objs = {}
    for obj in pairs(lit) do objs[#objs + 1] = obj end
    for _, obj in ipairs(objs) do
        if not ZeD_WorldWindow._elsewhereHolds(pn, obj) then ZeD_WorldWindow._unlight(pn, obj) end
        lit[obj] = nil
    end
    win._lit = lit
end

function ZeD_WorldWindow._lightShown(win)
    local pn = win.playerNum or 0
    -- (a World window that is not the player's window now lights nothing: only the one on show decides) (QA belt row
    -- run, Nov 22 2026)
    if _worldWins[pn] ~= win then return end
    local list = win._containers or {}
    local want = {}   -- object -> "show" | "hover"
    local function add(ci, kind)
        local c = ci and list[ci]
        local obj = c and not c.isFloor and ZeD_WorldWindow._parentOf(c.inventory) or nil
        -- (never the player himself; a body is lit, as the game's test)
        if obj and ((not instanceof(obj, "IsoPlayer")) or instanceof(obj, "IsoDeadBody")) and not want[obj] then
            want[obj] = kind
        end
    end
    -- the list on show: not rolled up, its side not rolled under the rod
    if not (win.windowShaded or win._rolled) then
        if win._activeTab == "loot" then
            if #(win._mcSelected or {}) == 0 or win._mainVisible then add(win._activeContainer, "show") end
            for _, ci in ipairs(win._mcSelected or {}) do add(ci, "show") end
        elseif win._invDrawerOpen then
            add(win._viewedContainer or win._activeContainer, "show")
        end
        -- the strip's button under the pointer, or under the pad's mark
        local strip = win._containerStrip
        local hoverCI = nil
        if strip and strip:isMouseOver() then
            local z = strip:hitZoneAt(strip:getMouseX(), strip:getMouseY())
            if z and type(z.id) == "number" then hoverCI = z.id end
        end
        local Focus = ZeD.Input and ZeD.Input.Focus
        local zone = Focus and Focus.liveZone and Focus.liveZone(win)
        if not hoverCI and zone and zone.zone == "worldContainerStrip" then
            local el = Focus.liveElement(win)
            hoverCI = el and el.containerIdx or nil
        end
        if hoverCI then add(hoverCI, "hover") end
    end
    local outline = getCore():getOptionDoContainerOutline()
    local lit = ZeD_WorldWindow._litTable(pn)
    -- what is no longer on show goes dark: highlight and outline off (keys gathered first: a table is not changed
    -- while pairs walks it, Kahlua) (QA belt row run, Nov 22 2026)
    local gone = {}
    for obj in pairs(lit) do
        if not want[obj] then gone[#gone + 1] = obj end
    end
    for _, obj in ipairs(gone) do
        if not ZeD_WorldWindow._elsewhereHolds(pn, obj) then ZeD_WorldWindow._unlight(pn, obj) end
        lit[obj] = nil
    end
    -- the rest is lit every frame, as the game's page does it (another light on the object may have ended)
    for obj, kind in pairs(want) do
        if ZeD_WorldWindow._elsewhereHolds(pn, obj) then
            lit[obj] = nil
        elseif kind == "show" then
            pcall(function()
                local col = getCore():getObjectHighlitedColor()
                obj:setHighlighted(pn, true, false)
                obj:setOutlineHighlight(pn, outline and true or false)
                obj:setOutlineHlAttached(pn, outline and true or false)
                if outline then obj:setOutlineHighlightCol(pn, col:getR(), col:getG(), col:getB(), 1) end
                obj:setHighlightColor(pn, col)
            end)
            lit[obj] = true
        elseif outline then
            pcall(function()
                local col = getCore():getWorldItemHighlightColor()
                obj:setHighlighted(pn, false, false)
                obj:setOutlineHighlight(pn, true)
                obj:setOutlineHlAttached(pn, true)
                obj:setOutlineHighlightCol(pn, col:getR(), col:getG(), col:getB(), 1)
            end)
            lit[obj] = true
        elseif lit[obj] then
            -- (the outline option turned off while it was lit: dark)
            ZeD_WorldWindow._unlight(pn, obj)
            lit[obj] = nil
        end
    end
    win._lit = lit
end

-- Another piece of the game lighting an object tells the game's pages (ISInventoryPage.OnObjectHighlighted): ZeD
-- hears it too, so it never paints over that light (KISS #44). Wrapped once; the game's own pages still hear it.
if ISInventoryPage and ISInventoryPage.OnObjectHighlighted and not ZeD_WorldWindow._hlWrapped then
    ZeD_WorldWindow._hlWrapped = true
    ZeD_WorldWindow._hlOrig = ISInventoryPage.OnObjectHighlighted
    ISInventoryPage.OnObjectHighlighted = function(playerNum, object, isHighlighted)
        local t = ZeD_WorldWindow._litElsewhere[(playerNum or 0) + 1]
        if t and object then t[object] = isHighlighted or nil end
        return ZeD_WorldWindow._hlOrig(playerNum, object, isHighlighted)
    end
end

-- (QA #44, Nov 22 2026) The game's own loot and inventory pages light their container too. ZeD hides them, but a
-- hidden page is still updated (the engine's UIElement.update tests only "enabled", not "visible"), and
-- ISInventoryPage:update calls updateContainerHighlight every 100 ms: the hidden loot page lit the container it had
-- picked itself (the crate he faces, crate A) again and again, so A stayed lit after a click showed crate B, however
-- often ZeD put it out. While ZeD's windows stand in for the pages, a hidden page lights nothing: its last light goes
-- out once and it lets go of it. A page on show (safe mode, a page shown for a frame) works as the game's.
function ZeD_WorldWindow._pageLightIsZeDs(page)
    if not page or page:getIsVisible() then return false end
    if ZeD.Safe and ZeD.Safe.on("windows") then return false end
    return ZeD.windowsFor(page.player or 0) == true
end

function ZeD_WorldWindow._pageLightOut(page)
    local inv = page.coloredInv
    if not inv then return end
    page.coloredInv = nil
    local pn = page.player or 0
    local obj = ZeD_WorldWindow._parentOf(inv)
    -- (left lit when ZeD's World window lights it itself, or when a menu holds its light)
    if obj and not ZeD_WorldWindow._litTable(pn)[obj] and not ZeD_WorldWindow._elsewhereHolds(pn, obj) then
        ZeD_WorldWindow._unlight(pn, obj)
    end
end

if ISInventoryPage and ISInventoryPage.updateContainerHighlight and not ZeD_WorldWindow._pageHlWrapped then
    ZeD_WorldWindow._pageHlWrapped = true
    ZeD_WorldWindow._pageHlOrig = ISInventoryPage.updateContainerHighlight
    ISInventoryPage.updateContainerHighlight = function(self)
        if ZeD_WorldWindow._pageLightIsZeDs(self) then return ZeD_WorldWindow._pageLightOut(self) end
        return ZeD_WorldWindow._pageHlOrig(self)
    end
end

-- ----------------------------------------------------------------------------
-- (KISS #8) WHERE THE PAD'S Y LANDS. The Y tap (FocusManager's _handleYTap, through Focus.yLand) still opens or
-- shows both windows; only the landing is here:
--   * a Y that hid the pair kept the row the pad was on (padYRemember); the next Y returns to it while it is
--     still there (its window open, a World row's container still in reach); by a container, only when it is a
--     row of the container he faces now (loot KISS call 3, the director, Nov 24 2026);
--   * else, near a container (one in reach that is not locked, seated the car's), the pad lands in the World
--     window on Loot, on the container he faces (KISS #13; shown even when the old one is still in reach, call 3):
--     its first row, or its button on the strip when it is empty;
--   * else nothing here: the caller lands on the Character window, as before.
-- Returns true when it took the pad. Module fields, not locals: this file is near Kahlua's limit.
-- ----------------------------------------------------------------------------
ZeD_WorldWindow._padYLeft = ZeD_WorldWindow._padYLeft or {}

--- The pair is about to hide on a Y: keep where player pn's pad is (window, zone, row).
function ZeD_WorldWindow.padYRemember(pn)
    pn = pn or 0
    ZeD_WorldWindow._padYLeft[pn] = nil
    local F = ZeD.Input and ZeD.Input.Focus
    local w = F and F.getFocusedWindow and F.getFocusedWindow(pn)
    if not w then return end
    local z = F.getFocusedZone(w)
    local el = F.getFocusedElement(w)
    -- (which of the pair it was: a Y tap now closes the pair, so the next Y finds the row in the windows built anew;
    -- KISS #25)
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(pn)
    local kind = (w == _worldWins[pn] and "world") or (w == cw and "char") or nil
    ZeD_WorldWindow._padYLeft[pn] = { win = w, kind = kind, zone = z and z.zone, id = el and el.id, item = el and el.item }
end

--- (loot KISS call 3, the director, Nov 24 2026) The container the World window would show for him now (a fresh look:
--- the one on the square he faces, else the first in reach, _pickShown), or nil when no container that is not locked
--- is in reach (the Floor alone does not count).
function ZeD_WorldWindow._padYFaced(ww)
    local po = ww and ww._playerObj
    if not po then return nil end
    local list = buildWorldContainers(po)
    local near = false
    for _, c in ipairs(list) do
        if not c.isFloor and not c.locked then near = true; break end
    end
    if not near then return nil end
    local i = ZeD_WorldWindow._pickShown({ _containers = list }, po)
    return i and list[i] and list[i].inventory or nil
end

--- Player pn's Y landing (above). back: the pair was hidden and comes back (a remembered row may count).
function ZeD_WorldWindow.padYLand(pn, back)
    pn = pn or 0
    local F = ZeD.Input and ZeD.Input.Focus
    if not (F and F.claimFocus and F.focusSoon) then return false end
    local ww = _worldWins[pn]
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(pn)
    local mem = ZeD_WorldWindow._padYLeft[pn]
    ZeD_WorldWindow._padYLeft[pn] = nil
    -- (the window of the pair it was on, as built now: the Y that closed the pair took the old ones, KISS #25)
    if mem and mem.kind then mem.win = (mem.kind == "world") and ww or cw end
    -- (loot KISS call 3, the director, Nov 24 2026) the container he faces now, when one is in reach (nil: none)
    local faced = ZeD_WorldWindow._padYFaced(ww)
    -- a later Y: back to the row it left
    if back and mem and mem.win and (mem.win == ww or mem.win == cw) then
        local still = true
        if faced then
            -- (call 3) by a container the pad lands on the one he faces: the row it left comes back only when it is
            -- a row of that same container (anything else, the Character window's too, gives way to it)
            still = mem.win == ww and mem.item ~= nil and mem.item:getContainer() == faced
        elseif mem.item and mem.win == ww then
            local inv = mem.item:getContainer()
            still = inv ~= nil and ZeD_WorldWindow.inReach(inv, pn)
        end
        if still then
            F.claimFocus(mem.win)
            if mem.zone and (mem.item or mem.id) then
                F.focusSoon(mem.win, mem.zone, function(e)
                    if mem.item then return e.item == mem.item end
                    return e.id == mem.id
                end, 1)
            end
            return true
        end
    end
    -- near a container: the World window's Loot, on the container he faces
    if not (ww and ww._playerObj and ww._mainContent) then return false end
    if not faced then return false end   -- (no container in reach that is not locked)
    -- (the list is read afresh on its next drawing: a turn or a walk while the pair was hidden shows the container
    -- he now faces, the strip's refresh, KISS #13)
    ww._containerTimer = 30
    -- (call 3) the faced container is the one on show, even when the old one is still in reach: by index when the
    -- list has it already (the refresh keeps it by its inventory); else the refresh's turn rule shows the one on the
    -- square he faces. Not while columns are open (his own layout, as the refresh's rule).
    if #(ww._mcSelected or {}) == 0 then
        local idx = nil
        for i, c in ipairs(ww._containers or {}) do if c.inventory == faced then idx = i; break end end
        if idx then
            if idx ~= ww._activeContainer and ww._mainContent then ww._mainContent._selectedItems = {} end
            ww._activeContainer, ww._viewedContainer, ww._mainVisible = idx, nil, true
        else
            ww._lookDir = nil
        end
    end
    if ww._activeTab ~= "loot" and _switchWorldTabForNav then _switchWorldTabForNav(ww, ww._mainContent, "loot") end
    F.claimFocus(ww)
    -- first its button on the strip (an empty container keeps the pad there, as a tap A on it), then its first row
    F.focusSoon(ww, "worldContainerStrip", function(e) return e.containerIdx == ww._activeContainer end, 2)
    F.focusSoon(ww, "worldMainInv", function(e)
        local c = ww._containers and ww._containers[ww._activeContainer]
        return e.item ~= nil and c ~= nil and e.item:getContainer() == c.inventory
    end, 3)
    return true
end

--- Shows a tab from code (stations, the crafting and build keys, wheels,
--- routes), opening the window first when needed. Replays a tab-strip click
--- so every side effect (multi-select exit, drawer growth, gamepad ring
--- re-sync) matches the mouse path. The strip stamps its hit zones while
--- drawing, so a freshly opened window retries for up to 20 ticks. toggle =
--- true hides the tab again when it is already showing (vanilla's crafting
--- and build keys toggle their windows). Returns false when the window
--- can't open.
function ZeD_WorldWindow.openTab(playerNum, tabId, toggle)
    if not ZeD.windowsFor(playerNum) then return false end   -- (split-screen: the game's own, ZeD.windowsFor)
    local opened = false   -- (this press opened the window: KISS #25)
    if not _worldWins[playerNum or 0] then
        local ok = pcall(ZeD_WorldWindow.open, playerNum or 0)
        if not ok then return false end
        opened = true
    end
    local win = _worldWins[playerNum or 0]
    if not win then return false end
    -- (rolled up by the hover roll-up: down first, its roll-up counted again from now)
    if win.windowShaded then
        win._autoShaded = false
        win:setWindowShaded(false)
        win._outSince = getTimestampMs() + 500
    end
    -- The same key again (Crafting, Build) closes what it opened, as the game's second press closes its window: a
    -- World window this key opened on this tab closes again; one that was up already only folds the tab. (KISS #25)
    if toggle and win._keyOpenedTab == tabId and ZeD_WorldWindow.isTabShowing(tabId, playerNum) then
        win._keyOpenedTab = nil
        ZeD_WorldWindow.close(playerNum or 0)
        return true
    end
    win._keyOpenedTab = (toggle and opened) and tabId or nil
    if ZeD_WorldWindow.isTabShowing(tabId, playerNum) and not toggle then return true end
    local wantClick = true
    local function attempt()
        if not wantClick then return true end
        local strip = win._actionTabStrip
        if strip and strip._hitZones then
            for _, z in ipairs(strip._hitZones) do
                if z.id == "tab:" .. tabId then
                    wantClick = false
                    strip:onMouseDown(z.x + 2, z.y + 2)
                    return true
                end
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

-- Called just before the window leaves a tab. Leaving the Vehicle tab no longer ends the look: Loot to fetch the jack,
-- the trailer's Open and Info, a folded drawer all came back to "Not inspected" and a shut hood. The look now ends
-- only when he walks past six tiles (MechanicsTab's reach check) or the window closes, as the game's window does.
-- Kept as the one place a tab change can hand off to. (the director's call, M7, Nov 26 2026)
function ZeD_WorldWindow._tabLeft(win)
    if not win or win._activeTab ~= "vehicle" then return end
end

-- A livestock zone drawing in progress ends with the window: AnimalsTab holds
-- the world menu off and the zones shown while one runs
function ZeD_WorldWindow._endZoneDraw()
    local AT = ZeD.AnimalsTab
    if AT and AT.endZoneDraw then pcall(AT.endZoneDraw) end
end

--- Closes the World window if it is open. pn: whose window (nil: the first player's).
function ZeD_WorldWindow.close(pn)
    -- (also reached when the Character window's close calls it for paired close)
    if _worldWins[pn or 0] then
        _closeWorldWindow(_worldWins[pn or 0])
    end
end

--- Safe mode's hand-back (SafeMode.lua, through ZeD_CharacterWindow's "windows"
--- hook): closes the window even when it broke halfway through opening and the
--- ordinary close fails on it. pn: whose window (nil: the first player's).
function ZeD_WorldWindow.forceClose(pn)
    ZeD_WorldWindow._endZoneDraw()
    -- (nothing it lit stays lit, whichever way the close goes) (QA belt row run, Nov 22 2026)
    if _worldWins[pn or 0] then pcall(ZeD_WorldWindow._unlightAll, _worldWins[pn or 0]) end
    local ok = pcall(ZeD_WorldWindow.close, pn)
    if ok and not _worldWins[pn or 0] then return end
    local w = _worldWins[pn or 0]
    _worldWins[pn or 0] = nil
    _floorContainers[pn or 0] = nil
    if not w then return end
    pcall(function()
        if ZeD.MapsTab and ZeD.MapsTab.closePopout then ZeD.MapsTab.closePopout(w, true) end
        if ZeD.Input and ZeD.Input.Focus then ZeD.Input.Focus.unregisterWindow(w) end
    end)
    pcall(w.removeFromUIManager, w)
end

-- Save state on game save (each window into its own character's modData)
Events.OnPostSave.Add(function()
    for _, w in pairs(_worldWins) do saveWorldState(w) end
end)

-- A resolution change keeps every open window on the new screen
if Events.OnResolutionChange then
    Events.OnResolutionChange.Add(function() for _, w in pairs(_worldWins) do fitWorldToScreen(w) end end)
-- split view: refit on a player joining or leaving too (each player's part changes size; off until ZeD.splitWindows)
local function _refitWorlds() if ZeD.splitWindows then for _, w in pairs(_worldWins) do fitWorldToScreen(w) end end end
Events.OnCreatePlayer.Add(_refitWorlds)
Events.OnPlayerDeath.Add(_refitWorlds)
end

-- A container changed (an item moved, a container opened or emptied): the container list reads afresh on the next
-- frame the strip draws, WREF.soonMs after its last read at the soonest
if Events.OnContainerUpdate then
    Events.OnContainerUpdate.Add(function() for _, w in pairs(_worldWins) do w._containersDirty = true end end)
end

-- ----------------------------------------------------------------------------
-- A container's column in the Loot tab's multi-column view, by its ItemContainer,
-- as a click on its icon in the container strip does (the Workshop gallery
-- shows several containers open side by side, and the QA scripts drive it
-- from here). The container list only holds what is in reach and rebuilds every
-- 30 frames, so a fresh one may need a moment. Returns true when it was found.
-- pn: whose window (nil: the first player's).
-- ----------------------------------------------------------------------------
function ZeD_WorldWindow.toggleColumn(inv, pn)
    local win = _worldWins[pn or 0]
    if not (win and inv and win._mainContent) then return false end
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            mcToggleWorldContainer(win, win._mainContent, i)
            return true
        end
    end
    return false
end

-- ----------------------------------------------------------------------------
-- THE GAME'S LOOT PAGE, WHEREVER IT IS ASKED FOR. A left click on a container in the world is the game's
-- own (ISObjectClickHandler: in reach, not aiming, the safehouse rule and the lock checked, the container
-- explored or its items asked of the server): it hands the container to the game's loot page and shows it.
-- The right-click menu and the controller show that page by their own ways too. Hiding the page again only
-- from ZeD's own windows' drawing is not enough: with both windows closed, or the World window rolled up,
-- the game's page would stay, and an open window would never take the clicked container. So, each tick:
-- the game's loot page showing means a container was asked for, so the page hides, the World window opens
-- (or rolls down, counting its roll-up again from now) and shows that container in its Loot pane, as the
-- page's setNewContainer would. The game's inventory page only hides.
-- Safe mode hands the game's pages back (SafeMode.lua), so nothing here runs then.
-- ----------------------------------------------------------------------------
-- (the game makes its pages showing when it builds them, for a new character, a respawn or a new screen size:
-- for a moment after those the pages only hide, so the World window does not open by itself)
local _lootGraceUntil = 0
local function _lootGrace() _lootGraceUntil = getTimestampMs() + 3000 end
local function _lootPadToWorld(pn)
    pn = pn or 0
    local CW = ZeD_CharacterWindow
    if CW and CW.ensureBothOpenForGamepad then pcall(CW.ensureBothOpenForGamepad, pn) end
    local win = _worldWins[pn]
    local F = ZeD.Input and ZeD.Input.Focus
    if not (win and F and F.claimFocus) then return end
    if win.windowShaded then win:setWindowShaded(false) end
    -- (claimFocus does nothing when ZeD already counts the World window as focused: the engine's focus is put back too)
    if F.getFocusedWindow and F.getFocusedWindow(pn) == win then
        if F.reclaimEngineFocus then pcall(F.reclaimEngineFocus, pn) end
    else
        pcall(F.claimFocus, win)
    end
end
-- THE PAGE IS NEVER DRAWN (not even a flash of it: a flash is an access problem too, not only a look). The
-- click that shows the page runs in the engine's UIManager.update, OnTick after it, the drawing after that; but
-- OnTick does not run while the game is paused, so a paused click would reach the drawing with the page
-- showing: one UI frame behind ZeD's windows (their prerender then hides it and loses the request), or the
-- whole pause with both windows closed or rolled up. So the watch runs on OnTickEvenPaused too (each frame,
-- paused or not, after the click and before the drawing; OnTick stays, a trunk's timed action runs after
-- OnTickEvenPaused has fired), and the last look below runs on OnPreUIDraw, the engine's last step before it
-- walks the UI list: whatever showed the page by whatever way, it never reaches a draw. The last look only
-- hides (a window built inside the drawing pass is no good): _lootAsked keeps the request for the next watch.
-- (each local player whose windows are ZeD's has their own pages: player 1, and with split view on players 2 to 4)
local _lootAsked = {}
local function _lootPageLastLookFor(pn)
    if not getSpecificPlayer(pn) then return end
    local vi, vl = getPlayerInventory(pn), getPlayerLoot(pn)
    if vi and vi:getIsVisible() then vi:setVisible(false) end
    if vl and vl:getIsVisible() then
        vl:setVisible(false)
        _lootAsked[pn] = true
    end
end
local function _lootPageLastLook()
    if ZeD.Safe.on("windows") then return end
    for pn = 0, 3 do if ZeD.windowsFor(pn) then _lootPageLastLookFor(pn) end end
end
local function _lootPageWatchFor(pn)
    local p = getSpecificPlayer(pn)
    if not p then return end
    local vi = getPlayerInventory(pn)
    local vl = getPlayerLoot(pn)
    -- (the controller's way in, ISButtonPrompt:cmdShowLoot, also hands the pad's focus to the page: a hidden page
    -- would hold it, so it goes to ZeD's World window instead, as RB does)
    local jp = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    local padOnPage = jp ~= nil and jp.focus ~= nil and (jp.focus == vl or jp.focus == vi)
    if vi and vi:getIsVisible() then vi:setVisible(false) end
    if not (vl and (_lootAsked[pn] or vl:getIsVisible())) then
        if padOnPage and getTimestampMs() >= _lootGraceUntil then _lootPadToWorld(pn) end
        return
    end
    _lootAsked[pn] = false
    vl:setVisible(false)
    local now = getTimestampMs()
    if p:isDead() or now < _lootGraceUntil then return end
    if padOnPage then _lootPadToWorld(pn) end
    -- (a vehicle's trunk opened names its container this way: ISOpenVehicleDoor)
    local inv = vl.inventory
    if vl.forceSelectedContainer and (vl.forceSelectedContainerTime or 0) > now then inv = vl.forceSelectedContainer end
    if not _worldWins[pn] then ZeD_WorldWindow.open(pn) end
    local win = _worldWins[pn]
    if not win then return end
    -- (an unpinned window rolls up again a moment after the pointer is away: counted from the click, a little
    -- longer than the hover's wait, as the game's page counts from -30 after a click)
    win._outSince = now + 500
    if win._halves and ZeD.Halves and ZeD.Halves.showAll then
        -- (the halves' own "come and look": the whole window down, and an inventory side the pointer rolled
        -- under its rod comes down too, as a bumper or Y brings it; a side rolled by hand stays) (QA B5-1)
        ZeD.Halves.showAll(win)
    elseif win.windowShaded then
        win._autoShaded = false
        win:setWindowShaded(false)
    end
    if inv then ZeD_WorldWindow.selectContainer(inv, 60, pn) end
end
local function _lootPageWatch()
    if ZeD.Safe.on("windows") then return end
    -- (four numbers each frame, paused too: cheap)
    for pn = 0, 3 do if ZeD.windowsFor(pn) then _lootPageWatchFor(pn) end end
end
Events.OnTick.Add(_lootPageWatch)
if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(_lootPageWatch) end
if Events.OnPreUIDraw then Events.OnPreUIDraw.Add(_lootPageLastLook) end
if Events.OnGameStart then Events.OnGameStart.Add(_lootGrace) end
if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(_lootGrace) end
if Events.OnResolutionChange then Events.OnResolutionChange.Add(_lootGrace) end
