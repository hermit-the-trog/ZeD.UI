-- ZeD-UI/42/media/lua/client/ZeD/InventoryRenderer.lua
-- ============================================================================
-- INVENTORY RENDERER — shared module consumed by CharacterWindow + WorldWindow.
-- Extracted from TestInventory.lua.
--
-- 43 exports. The core 12: renderItemList, renderMultiColumnContent, makeSorter,
-- SORT_COLS, countSelected, findIndex, collectSelectedItems, handleDrop,
-- buildContainers, rebuildColStates, toggleContainer, dirtyModels (every list
-- model rebuilds on its next draw). The rest are the pad, grid, category and
-- column helpers the two windows call.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_Panel"
require "ZeD/ReadMarks"
require "ZeD/ContainerGates"   -- (a mod that hides a container's things until searched: ModSupport files)
require "ZeD/ContainerGroups"  -- (a mod that files things into groups of its own: ModSupport files)
require "ZeD/InventoryFilter"  -- (the window's Filter: its state, matching and bar)
require "ZeD/GridLayout"       -- (Nov 15 2026, add-on hooks: an add-on's grid layout, item spans and placing)
require "ZeD/ItemRules"        -- (Nov 15 2026, add-on hooks: an add-on's rule about what may go where)

ZeD = ZeD or {}

-- ============================================================================
-- SORT COMPARATORS
-- Each returns a comparator function for table.sort.
-- "name" is the default - one flat A-Z list (Z-A reversed), no category headers.
-- Only "cat" groups under category headers (name within each); cond / wt sort flat.
-- ============================================================================

local SORT_COLS = {"name", "cat", "cond", "wt"}
ZeD.InventoryRenderer = {}  -- shared module: both windows and the Equip tab read it

-- An item's category as vanilla's inventory shows it: the display category set in the item
-- script, else the Java category. This KEY groups, sorts and names the collapsed state;
-- catLabel turns it into the player's word (vanilla's IGUI_ItemCat_<key>), the key itself
-- when the game has no word for it.
function ZeD.InventoryRenderer.catKey(item)
    local dc = item:getDisplayCategory()
    if dc and dc ~= "" then return dc end
    return item:getCategory() or "Other"
end
-- (KISS #11) The group worn and held things stand in at the top of the player's own list, when the Worn and held
-- setting lists them there (Settings.wornInList): its key, and the question the list asks.
ZeD.InventoryRenderer.WORN_KEY = "zed:worn"
function ZeD.InventoryRenderer.wornListed()
    return ZeD.Settings and ZeD.Settings.wornInList and ZeD.Settings.wornInList() or false
end
-- The game's own mark for a worn or held thing (its small equipped icon, drawn over the row's icon corner), for a row
-- of the worn group. (x, y, size: the row's icon box.)
function ZeD.InventoryRenderer.drawWornMark(panel, x, y, size)
    local R = ZeD.InventoryRenderer
    if R._wornTex == nil then R._wornTex = getTexture("media/ui/icon.png") or false end
    if not R._wornTex then return end
    local m = math.max(8, math.floor(size / 2))
    panel:drawTextureScaled(R._wornTex, x + size - m, y + size - m, m, m, 1, 1, 1, 1)
end
-- (kept per key: rows ask every frame; dropped when the game's language changes, ZeD._trGen)
local _catLbl, _catGen = {}, -1
function ZeD.InventoryRenderer.catLabel(key)
    key = tostring(key)
    if key == ZeD.InventoryRenderer.WORN_KEY then return ZeD.tr("UI_ZeD_Inv_WornHeld") end   -- (KISS #11)
    -- a mod's group (ContainerGroups.lua): its words, asked fresh (a folder can be renamed)
    local own = ZeD.ContainerGroups.label(key)
    if own then return own end
    if _catGen ~= ZeD._trGen then _catLbl, _catGen = {}, ZeD._trGen end
    local s = _catLbl[key]
    if s == nil then
        s = (getTextOrNull and getTextOrNull("IGUI_ItemCat_" .. key)) or key
        _catLbl[key] = s
    end
    return s
end

-- the COND / AMT column's share: the item's one bar, its condition or how full it is (ItemMeter.lua, punch list
-- 152); no bar sorts below an empty one
local function getCondPct(item)
    return ZeD.ItemMeter.sortKey(item)
end

local function makeSorter(col, asc)
    if col == "name" then
        if asc then
            return function(a, b) return string.lower(a:getName() or "") < string.lower(b:getName() or "") end
        else
            return function(a, b) return string.lower(a:getName() or "") > string.lower(b:getName() or "") end
        end
    elseif col == "cat" then
        if asc then
            return function(a, b)
                local ca, cb = ZeD.InventoryRenderer.catKey(a), ZeD.InventoryRenderer.catKey(b)
                if ca ~= cb then return ca < cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        else
            return function(a, b)
                local ca, cb = ZeD.InventoryRenderer.catKey(a), ZeD.InventoryRenderer.catKey(b)
                if ca ~= cb then return ca > cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        end
    elseif col == "cond" then
        if asc then
            return function(a, b)
                local ca, cb = getCondPct(a), getCondPct(b)
                if ca ~= cb then return ca < cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        else
            return function(a, b)
                local ca, cb = getCondPct(a), getCondPct(b)
                if ca ~= cb then return ca > cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        end
    else -- "wt"
        if asc then
            return function(a, b)
                local wa, wb = a:getUnequippedWeight(), b:getUnequippedWeight()
                if wa ~= wb then return wa < wb end
                return (a:getName() or "") < (b:getName() or "")
            end
        else
            return function(a, b)
                local wa, wb = a:getUnequippedWeight(), b:getUnequippedWeight()
                if wa ~= wb then return wa > wb end
                return (a:getName() or "") < (b:getName() or "")
            end
        end
    end
end

-- ============================================================================
-- TEXT TRUNCATION
-- Truncates text with ellipsis when it exceeds maxW pixels.
-- ============================================================================

local truncateText = ZeD.Atoms.truncateText

-- ============================================================================
-- CONTAINER ENUMERATION
-- Builds a table of the player's containers: the main inventory first, then
-- equipped bags and key rings.
-- ============================================================================

local function buildContainers(playerObj)
    local containers = {}
    local mainInv = playerObj:getInventory()
    containers[#containers + 1] = {
        inventory = mainInv,
        name      = getText("IGUI_InventoryTooltip"),
        texture   = nil,
        isMain    = true,
    }
    local items = mainInv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and (
            (item:getCategory() == "Container" and playerObj:isEquipped(item))
            or item:isItemType(ItemType.KEY_RING)
            or item:hasTag(ItemTag.KEY_RING)
        ) then
            containers[#containers + 1] = {
                inventory = item:getInventory(),
                name      = item:getName(),
                texture   = item:getTex(),
                isMain    = false,
            }
        end
    end
    return containers
end

-- ============================================================================
-- COLUMN STATE MANAGEMENT
-- Per-column state for multi-container mode.
-- ============================================================================

local function makeColState(containers, cIdx)
    local ZeD_ScrollbarState = ZeD.Molecules.ScrollbarState
    local scroll = ZeD_ScrollbarState:new()
    scroll.visible = true
    scroll.onScroll = function() end
    return {
        containerIdx    = cIdx,
        inventory       = containers[cIdx].inventory,
        scroll          = scroll,
        selectedItems   = {},
        lastClickedItem = nil,
        sortCol         = "name",
        sortAsc         = true,
        collapsedGroups = {},
        flatItems       = {},
        renderX         = 0,
        renderW         = 0,
    }
end

local function rebuildColStates(content)
    local containers = content._containers
    local selected   = content._selectedContainers
    local oldStates  = content._colStates or {}
    local newStates  = {}

    for i, cIdx in ipairs(selected) do
        -- Reuse existing state if container was already in a column
        local existing = nil
        for _, old in ipairs(oldStates) do
            if old.containerIdx == cIdx then
                existing = old
                break
            end
        end
        if existing then
            -- Update inventory ref in case it changed
            existing.inventory = containers[cIdx].inventory
            newStates[i] = existing
        else
            newStates[i] = makeColState(containers, cIdx)
        end
    end

    content._colStates = newStates
end

-- A column's rows follow the container selected for it, by the container object, never by its place in the list
-- (a column pointed at a list index can go stale until the window closes). Each column is checked against the
-- selection before it draws; any that disagrees is re-pointed by its object (keeping its scroll and selection) and
-- the columns rebuilt, whichever way the list or the selection moved. Returns true when it rebuilt them.
local function syncColStates(content)
    local selected, containers = content._selectedContainers, content._containers
    if not (selected and containers) then return false end
    local states = content._colStates
    local same = states ~= nil and #states == #selected
    if same then
        for i, cIdx in ipairs(selected) do
            local c, cs = containers[cIdx], states[i]
            if not c or cs.containerIdx ~= cIdx or cs.inventory ~= c.inventory then same = false; break end
        end
    end
    if same then return false end
    for _, cs in ipairs(states or {}) do
        cs.containerIdx = nil
        for i, c in ipairs(containers) do
            if c.inventory == cs.inventory then cs.containerIdx = i; break end
        end
    end
    for i = #selected, 1, -1 do
        if not containers[selected[i]] then table.remove(selected, i) end
    end
    rebuildColStates(content)
    return true
end

local function toggleContainer(content, cIdx, maxTotal)
    if not content._containers[cIdx] then return end
    local selected = content._selectedContainers
    local cap = maxTotal or 3  -- caller provides dynamic capacity

    -- Check if already selected
    local idx = nil
    for i, v in ipairs(selected) do
        if v == cIdx then idx = i; break end
    end

    if idx then
        -- Deselect (unless it's the last one)
        if #selected > 1 then
            table.remove(selected, idx)
            if content._activeCol > #selected then
                content._activeCol = #selected
            end
        end
    else
        -- Select — if at capacity, FIFO evict the oldest first
        while #selected >= cap do
            table.remove(selected, 1)
            if content._activeCol > #selected then
                content._activeCol = #selected
            end
        end
        selected[#selected + 1] = cIdx
    end

    rebuildColStates(content)
end

-- ============================================================================
-- ITEM LIST RENDERER
-- Called as ZeD_Panel._onPrerender — self = the content ZeD_Panel.
-- Draws column header, grouped+scrolled item rows, and live scrollbar.
-- Rebuilds hit zones each frame for click detection.
--
-- Multi-column support:
--   self._renderXOffset — X offset for all drawing within the panel
--   self._renderW       — override width (column width)
--   self._compactMode   — force NAME+WT only (no cat/cond)
--   self._skipClearHitZones — caller handles clearHitZones
-- ============================================================================

-- Container buttons (ContainerControls): one row at the bottom of the list
-- (the bottom keeps the noise out of the way), single-container view only;
-- the list ends above it. These helpers
-- keep renderItemList's locals unchanged (it sits at Kahlua's limit of 200
-- active locals): the row's height rides on self._ccH.
local function ccLayout(self, hdrY, barH, colW)
    self._ccH = 0
    local CTL = ZeD.ContainerControls
    if CTL and self._ccSide and not self._compactMode and hdrY > barH then
        local ok, h = pcall(CTL.layout, self, colW)
        if ok then self._ccH = h or 0 else ZeD.logOnce("ContainerControls layout", h) end
    elseif CTL and self._compactMode and hdrY > barH and CTL.headLootOn(self) then
        -- (Transfer in the footer, the director, Nov 22 2026) a Loot column's own foot: its Take all (drawColumnFoot)
        self._ccH = ZeD.Molecules.bandH()
    else
        self._ccMarks = nil
        if self._cc then self._cc.layout = nil end
    end
end

local function ccDraw(self, colW, xOff)
    if self._compactMode then return ZeD.InventoryRenderer.drawColumnFoot(self, self._gv, xOff, colW) end
    local ok, e = pcall(ZeD.ContainerControls.draw, self, self:getHeight() - self._ccH, colW, xOff, true)
    if not ok then ZeD.logOnce("ContainerControls draw", e) end
end

-- an icon's hover hint, drawn last (over the rows)
local function ccHint(self)
    local ok, e = pcall(ZeD.ContainerControls.drawHint, self)
    if not ok then ZeD.logOnce("ContainerControls hint", e) end
end

-- a row a pointed-at (or focused) Same type button would move (a stack's
-- row when any of its things would)
local function ccMarked(self, item)
    local marks = self._ccMarks
    if marks[item] then return true end
    local stk = self._stacks and self._stacks[item]
    if stk and stk.count > 1 then
        for _, si in ipairs(stk.items) do if marks[si] then return true end end
    end
    return false
end

-- ============================================================================
-- GRID VIEW. A view button in each column's heading; the
-- list stays the default. The choice is remembered per container (the fridge
-- set to grid opens as a grid next time), in the character's mod data. The
-- grid shows the list's own order: no sorting of its own. Cells register the
-- item itself as their hit zone, so selecting, dragging and the item's menu
-- work exactly as on a row.
-- ============================================================================
local GRID_CELL, GRID_GAP = 52, 4

-- a stable name for a container: the player's bag, a bag by its item id, a
-- vehicle part, a world object by its square, else its kind
local function containerKey(inv, playerObj)
    if not inv then return nil end
    local ok, k = pcall(function()
        if playerObj and inv == playerObj:getInventory() then return "player" end
        local it = inv:getContainingItem()
        if it then return "item:" .. tostring(it:getID()) end
        local vp = inv.getVehiclePart and inv:getVehiclePart()
        if vp then
            local v = vp:getVehicle()
            return "veh:" .. tostring(v and v:getSqlId() or "?") .. ":" .. tostring(vp:getId())
        end
        local t = tostring(inv:getType())
        local par = inv:getParent()
        local sq = par and par.getSquare and par:getSquare()
        if sq then return "obj:" .. sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ() .. ":" .. t end
        return "type:" .. t
    end)
    return ok and k or nil
end
ZeD.InventoryRenderer.containerKey = containerKey

-- p: whose choices (a window's own player; nil: the game's player 1, as before split view)
local function gridStore(p)
    p = p or (getPlayer and getPlayer())
    if not p then return nil end
    local md = p:getModData()
    md.ZeD_GridViews = md.ZeD_GridViews or {}
    return md.ZeD_GridViews
end

-- a container's own choice (its view button), else the ZeD option "Inventory"
function ZeD.InventoryRenderer.isGridKey(key, playerObj)
    local s = key and gridStore(playerObj)
    if s and s[key] ~= nil then return s[key] == true end
    local o = ZeD.Settings and ZeD.Settings.inventoryViewOption
    local ok, v = pcall(function() return o and o:getValue() end)
    return ok and v == 2
end

--- The most a container holds, as the game counts it for this character (the number its heading shows after the
--- load): the character's own inventory, the weight it can carry (getMaxWeight); any other container, its capacity
--- with the Organized or Disorganized trait applied (getEffectiveCapacity), which is what the game checks a transfer
--- against and what its own inventory shows. A plain getMaxWeight on a bag reads the bare capacity: 28 for an
--- Organized character's ALICE pack that takes 36. Two getter calls, no table: the headings ask every frame.
function ZeD.InventoryRenderer.capacityOf(inv, playerObj)
    if not inv then return 0 end
    if not playerObj or inv == playerObj:getInventory() then return inv:getMaxWeight() end
    return inv:getEffectiveCapacity(playerObj)
end

function ZeD.InventoryRenderer.setGridKey(key, on, playerObj)
    local s = key and gridStore(playerObj)
    if s then s[key] = on and true or false end   -- (false: this one a list, whatever the option says)
end

-- the heading's view button, R3 and A on the button: the container goes to the other view, saved as its own choice
function ZeD.InventoryRenderer.flipGridKey(key, playerObj)
    if not key then return false end
    ZeD.InventoryRenderer.setGridKey(key, not ZeD.InventoryRenderer.isGridKey(key, playerObj), playerObj)
    pcall(function() ZeD.uiSound("UISelectListItem") end)
    return true
end

-- (List columns, the director, Nov 22 2026) the sort a list draws with: its own, but a sort on the Status column
-- while the list has dropped it sorts by Name (the heading underlines Name, the only key with a heading that
-- matches). The choice itself is kept, so the Status sort comes back with the column when the list widens. A sort by
-- Category stays as it is with its column hidden: it groups the rows under category headings, which say it. The
-- grid has no columns and every key, so it keeps every sort. Asks the grid choice only on that rare case.
function ZeD.InventoryRenderer.listSort(panel, col, showCond)
    if col ~= "cond" or showCond then return col end
    local p = panel._playerObj
    if ZeD.InventoryRenderer.isGridKey(containerKeyOf(panel._inventory, p), p or getSpecificPlayer(0)) then return col end
    return "name"
end

-- ---------------------------------------------------------------------------
-- (Grid width, the director, Nov 22 2026: "In grid mode, can the width of the inventory hug the grid width? That
-- is, shrink to reduce white space.") The width a grid column takes for whole cells: its left pad, n cells and the
-- n - 1 gaps between them, its right pad and the scrollbar's gutter (the grid keeps it as the list does; gridState's
-- cols is the inverse of this). colW: the width to snap (px); how: "up" (the least whole width at or past colW),
-- true (the nearest whole width: a drag), else the widest whole width at or under it. Always at least one cell.
-- Returns the width (px).
function ZeD.InventoryRenderer.gridHugW(colW, how)
    local T = ZeD.T
    local step = T.px(GRID_CELL) + T.px(GRID_GAP)
    local frame = T.sp.sm * 2 + T.sp.scrollbarW - T.px(GRID_GAP)   -- (n cells and n - 1 gaps: n steps less a gap)
    local n = (colW - frame) / step
    if how == "up" then n = math.ceil(n - 1e-6) elseif how then n = math.floor(n + 0.5) else n = math.floor(n + 1e-6) end
    return math.max(1, n) * step + frame
end

-- The inventory side's width (px) for n grid columns side by side (Loot columns: n - 1 transfer strips xferW wide
-- between them; one column: n = 1, xferW 0) snapped to whole cells, each column as gridHugW snaps it (how). Never
-- under the narrowest whole width: one column, the widest at or under the inventory's 200-unit minimum (three cells;
-- the heading stacks its name over the weight there, headStacks); several, the least at or past MIN_COL_W, so the
-- windows' eviction (a column under MIN_COL_W) never fires on a snap.
function ZeD.InventoryRenderer.hugInvW(invW, n, xferW, how)
    local R, T = ZeD.InventoryRenderer, ZeD.T
    n, xferW = math.max(1, n or 1), xferW or 0
    local per = R.gridHugW((invW - (n - 1) * xferW) / n, how)
    local least = (n > 1) and R.gridHugW(T.px(R.MIN_COL_W), "up") or R.gridHugW(T.px(200))
    if per < least then per = least end
    return n * per + (n - 1) * xferW
end

-- ---------------------------------------------------------------------------
-- The controller's L3 / R3 in a window: view-only changes (sort, List |
-- Grid), and only while a window holds the pad. They act on the list the
-- pad is on (a multi-container column, else the window's list), else the
-- window's list on show.
-- ---------------------------------------------------------------------------
local function padList(win)
    local cnt = win and win._mainContent
    if not cnt then return nil end
    local F = ZeD.Input and ZeD.Input.Focus
    local el = F and F.getFocusedElement and F.getFocusedElement(win)
    local colIdx = el and el.colIdx
    local cs = colIdx and cnt._colStates and cnt._colStates[colIdx] or nil
    return cnt, cs
end

-- L3: a second press on a sort reverses it (as a second header click does), the press after that
-- goes on to the next column (Name, Category, Condition, Weight, round again), A-Z first
function ZeD.InventoryRenderer.padSort(win)
    local cnt, cs = padList(win)
    if not cnt then return false end
    local cur = (cs and cs.sortCol) or cnt._sortCol or "name"
    local asc
    if cs then asc = cs.sortAsc else asc = cnt._sortAsc end
    local nxt, nxtAsc = cur, false
    if asc == false then
        local i = 1
        for k, c in ipairs(SORT_COLS) do if c == cur then i = k end end
        nxt, nxtAsc = SORT_COLS[i % #SORT_COLS + 1], true
        -- (List columns, the director, Nov 22 2026) a list whose Status column is hidden skips it: that sort would
        -- show as Name (listSort), a press that seemed to do nothing. The grid has every key (its bar lists them).
        local shown = cs or cnt
        if nxt == "cond" and shown._showCond == false then nxt = SORT_COLS[(i + 1) % #SORT_COLS + 1] end
    end
    if cs then
        cs.sortCol, cs.sortAsc = nxt, nxtAsc
        if cs.scroll then cs.scroll:setScrollPos(0) end
    else
        cnt._sortCol, cnt._sortAsc = nxt, nxtAsc
        if cnt._scroll then cnt._scroll:setScrollPos(0) end
    end
    pcall(function() ZeD.uiSound("UISelectListItem") end)
    return true
end

-- R3: the container on show between List and Grid (as its heading's view button does)
function ZeD.InventoryRenderer.padView(win)
    local cnt, cs = padList(win)
    if not cnt then return false end
    local idx = (cs and cs.containerIdx) or win._viewedContainer or win._activeContainer
    local c = idx and win._containers and win._containers[idx]
    -- (a window always has its player; player 1 is only the fallback for one built without)
    local playerObj = win._playerObj or getSpecificPlayer(0)
    local key = c and c.inventory and containerKey(c.inventory, playerObj)
    return ZeD.InventoryRenderer.flipGridKey(key, playerObj)
end

-- the footer's words for the two, where the pad is in a list: L3 sorts, R3 shows what it switches to
function ZeD.InventoryRenderer.padPrompts(win)
    local cnt, cs = padList(win)
    if not cnt then return nil end
    local idx = (cs and cs.containerIdx) or win._viewedContainer or win._activeContainer
    local c = idx and win._containers and win._containers[idx]
    local key = c and c.inventory and containerKey(c.inventory, win._playerObj or getSpecificPlayer(0))
    local grid = key and ZeD.InventoryRenderer.isGridKey(key, win._playerObj)
    return { { glyph = "L3", label = ZeD.tr("UI_ZeD_Prompt_Sort") },
             { glyph = "R3", label = ZeD.tr(grid and "UI_ZeD_Settings_ViewList" or "UI_ZeD_Settings_ViewGrid") } }
end

-- a heading zone was clicked: the view button's "view:flip:<key>"; the Filter's "view:filter:<key>" and its bar's
-- "view:fbar:field" / "clear" / "chip:<category>" / "bg" (content: the list panel the press was on)
function ZeD.InventoryRenderer.onViewZone(zid, content)
    local view, key = tostring(zid):match("^view:(%a+):(.*)$")
    if not (view and key) then return end
    if view == "filter" or view == "fbar" then
        local S = content and content._zedFilter
        if not S then return end
        if view == "filter" then ZeD.InvFilter.act(S, "filter")
        elseif key == "field" then
            -- (a click: the field's own box takes the keys; never the controller's keyboard)
            local f = S.field
            if f and f.input then pcall(function() f.input:focus() end) end
        else ZeD.InvFilter.act(S, key) end
        return
    end
    if view == "all" then   -- (KISS #45: Pick all)
        if content and content.zedSelectAll then content:zedSelectAll() end
        return
    end
    if view == "flip" then ZeD.InventoryRenderer.flipGridKey(key, content and content._playerObj) end
    if view == "lootall" then ZeD.InventoryRenderer.lootAllOf(content, key) end   -- (KISS #18; key: its column's)
end

-- The heading's Loot all (the World window's list): everything wanted in the container on show comes over, as the
-- band's Loot all does. (KISS #18)
-- key: the heading's container key (its toggle's); in a Loot view of several columns the column with that key is
-- the one taken from, not the list the panel was last bound to. (Header order, the director, Nov 22 2026)
function ZeD.InventoryRenderer.lootAllOf(content, key)
    local po = content and content._playerObj
    local src = content and content._inventory
    local cols = content and content._colStates
    if key and cols and #cols > 1 then
        src = nil
        for _, cs in ipairs(cols) do
            if cs.inventory and containerKey(cs.inventory, po) == key then src = cs.inventory; break end
        end
    end
    if not (po and src) then return end
    if isGamePaused() then return end
    -- (Nov 22 2026, "Number 1": into the bag on show, where the band's Loot all put them; it is the only one now)
    ZeD.ContainerControls.lootAllFrom(po, src, ZeD.ContainerControls.otherInventory(content))
end

-- Double-click a row: vanilla's quick use. In your main inventory the item's
-- basic action (eat, equip, wear, read); anywhere else it comes to your main
-- inventory (ISInventoryPane:onMouseUp's rule). True when this click was the
-- second of a pair, so the window skips its select / drag.
local DBL_MS = 400
-- colIdx: the column the click is in (a multi-column view); the earlier release has cleared _dragSourceCol by now,
-- so the caller names it (QA K2 review)
-- shift: Shift is held (the game's Shift + double-click: a garment taken from elsewhere is worn too, L1-5). The first
-- click of a pair still does its Shift selection in the window; only the second one is the quick use.
function ZeD.InventoryRenderer.doubleClick(win, item, playerNum, colIdx, shift)
    local now = getTimestampMs()
    local last = win._zedLastClick
    win._zedLastClick = { item = item, t = now }
    if not (last and last.item == item and now - last.t <= DBL_MS) then return false end
    win._zedLastClick = nil
    -- a closed stack's row is the whole stack, as vanilla's double-click takes it (its rows beyond the first all
    -- come over); an open stack's row, or a thing already in the main inventory, is the one thing (QA K2-8)
    local rows = nil
    local src = item and item:getContainer()
    local pl = getSpecificPlayer(playerNum)
    if src and pl and src ~= pl:getInventory() and ZeD.InventoryRenderer.dragItems then
        local keepCol = win._dragSourceCol
        win._dragSourceCol = colIdx   -- dragItems reads the stacks of this column
        local all = ZeD.InventoryRenderer.dragItems(win, { item }, src)
        win._dragSourceCol = keepCol
        if all and #all > 1 then rows = all end
    end
    -- the game wears only from a stack's own row (ISInventoryPane:onMouseDoubleClick's group row), not from one
    -- thing of an opened stack: a thing whose stack holds more but came alone is such a thing (L1-5)
    local wear = shift == true
    if wear and not rows then
        local cs = colIdx and win._colStates and win._colStates[colIdx] or nil
        local stacks = (cs and cs.stacks) or win._stacks
        local stk = stacks and stacks[item]
        if stk and stk.count and stk.count > 1 then wear = false end
    end
    ZeD.InventoryRenderer.quickUse(item, playerNum, rows, wear)
    return true
end


-- ============================================================================
-- CONTROLLER MARKS
-- Hold A on a row MARKS it (the row's wash, as Ctrl-click); hold A on a marked row unmarks it; while A
-- stays held, Up and Down mark the rows passed (Shift-click's run, painted; FocusManager fires onPaint on
-- the row landed on). With marks on the list the card hides (as with the mouse), X moves every marked row
-- (punch list 223, below), the band's Take / Drop / Move act on them, and B clears the marks and leaves the
-- focus where it is. Tap A on a marked row opens its card and drops the marks (the plain click's way).
-- Hold X on a row is the quick use (a double-click). Marks belong to one list: a stack header marks its
-- whole stack; a mark in another column or container is another list (the column's own selection).
-- ============================================================================
-- the selection table a row belongs to (a column's or the main list's), the content and the column
local function padSel(w, el)
    local cnt = w and w._mainContent
    if not cnt then return nil end
    local cs = el and el.colIdx and cnt._colStates and cnt._colStates[el.colIdx] or nil
    if cs then cs.selectedItems = cs.selectedItems or {}; return cs.selectedItems, cnt, cs end
    cnt._selectedItems = cnt._selectedItems or {}
    return cnt._selectedItems, cnt, nil
end
local function padStackItems(cnt, cs, item)
    local stacks = cs and cs.stacks or (cnt and cnt._stacks)
    local stk = stacks and stacks[item]
    if stk and stk.count > 1 and stk.items then return stk.items end
    return { item }
end
local function padRefresh(w, cnt)
    if w._updateDrawer then pcall(w._updateDrawer, cnt) end   -- (the World's takes no argument; the extra one is ignored)
end
-- how many rows are marked in the content (the main list and every column; in column mode the
-- renderer binds one column's table as the content's own, so a table counts once)
local function markCountOf(cnt)
    if not cnt then return 0 end
    local n, seen = 0, {}
    local function add(t) if t and not seen[t] then seen[t] = true; for _ in pairs(t) do n = n + 1 end end end
    add(cnt._selectedItems)
    for _, cs in ipairs(cnt._colStates or {}) do add(cs.selectedItems) end
    return n
end
function ZeD.InventoryRenderer.padMarkCount(w) return markCountOf(w and w._mainContent) end
ZeD.InventoryRenderer.padMarkCountOf = markCountOf
-- every marked item of the content, list after list (the band's Take / Move marked); nil without any
function ZeD.InventoryRenderer.padMarkedAll(cnt)
    if not cnt then return nil end
    local out, seenT, seenI = {}, {}, {}
    local function add(t)
        if not t or seenT[t] then return end
        seenT[t] = true
        for it in pairs(t) do if not seenI[it] then seenI[it] = true; out[#out + 1] = it end end
    end
    add(cnt._selectedItems)
    for _, cs in ipairs(cnt._colStates or {}) do add(cs.selectedItems) end
    if #out == 0 then return nil end
    return out
end
-- hold A: mark or unmark the row (a stack header: its whole stack) and arm the painted run
function ZeD.InventoryRenderer.padMark(w, el)
    if not (el and el.item) then return end
    local sel, cnt, cs = padSel(w, el)
    if not sel then return end
    local adding = not sel[el.item]
    for _, it in ipairs(padStackItems(cnt, cs, el.item)) do sel[it] = adding or nil end
    cnt._lastClickedItem = el.item
    cnt._padMarks = true   -- (the controller's marks: the card hides even at one; the drawer reads it)
    w._gpPaint = { adding = adding, col = el.colIdx }
    padRefresh(w, cnt)
end
-- the painted run: the row landed on while A stays held takes the stroke's mark (the same list only)
function ZeD.InventoryRenderer.padPaint(w, el, paint)
    if not (el and el.item and paint) then return end
    if (paint.col or false) ~= (el.colIdx or false) then return end
    local sel, cnt, cs = padSel(w, el)
    if not sel then return end
    for _, it in ipairs(padStackItems(cnt, cs, el.item)) do sel[it] = paint.adding or nil end
    cnt._lastClickedItem = el.item
    cnt._padMarks = true
    padRefresh(w, cnt)
end
-- the marked rows of the row's own list, for X's menu; nil when nothing is marked
function ZeD.InventoryRenderer.padMarkedItems(w, el)
    if ZeD.InventoryRenderer.padMarkCount(w) == 0 then return nil end
    local sel = padSel(w, el)
    local out = {}
    for it in pairs(sel or {}) do out[#out + 1] = it end
    if #out == 0 then return nil end
    return out
end
-- the marks go, in place (the renderer's column tables and the content's alias one another, so the
-- tables stay and empty); no drawer refresh here, the caller's own follows
local function wipeMarks(cnt)
    if not cnt then return end
    local seen = {}
    local function wipe(t) if t and not seen[t] then seen[t] = true; for k in pairs(t) do t[k] = nil end end end
    wipe(cnt._selectedItems)
    for _, cs in ipairs(cnt._colStates or {}) do wipe(cs.selectedItems) end
    cnt._lastClickedItem = nil
    cnt._padMarks = nil
end
ZeD.InventoryRenderer.padClearMarksOf = wipeMarks
-- B: every mark in the window goes; the focus stays where it is (quiet: the caller refreshes the drawer)
function ZeD.InventoryRenderer.padClearMarks(w, el, quiet)
    local cnt = w and w._mainContent
    if not cnt then return end
    wipeMarks(cnt)
    if not quiet then padRefresh(w, cnt) end
end
-- B on a row: with marks it clears them; without, nothing (false: no sound, and the prompt hides)
function ZeD.InventoryRenderer.padCancel(w, el)
    if ZeD.InventoryRenderer.padMarkCount(w) == 0 then return false end
    ZeD.InventoryRenderer.padClearMarks(w, el)
    return true
end
-- the footer's words, read every frame (a prompt may be a function; false hides it, nil is the default word)
function ZeD.InventoryRenderer.padPromptB(w, el)
    if ZeD.InventoryRenderer.padMarkCount(w) == 0 then return false end
    return ZeD.tr("UI_ZeD_Inv_PromptClearMarks")
end
-- (KISS #30) Is this row's thing in the player's own bags (the main inventory or a bag they carry)? Hold A runs the game's
-- quick use there and marks everywhere else.
function ZeD.InventoryRenderer.padOwnBags(w, el)
    local po = getSpecificPlayer(ZeD.playerNumOf(w))
    local c = el and el.item and el.item:getContainer()
    if not (po and c) then return false end
    if c == po:getInventory() then return true end
    local ok, r = pcall(function() return c:isInCharacterInventory(po) end)
    return ok and r and true or false
end
-- (KISS #30) The word of the game's quick use of a thing (what hold X and, in his own bags, hold A run: the game's
-- double-click): Eat, Drink, Take Pills, Bandage. nil when the thing has none we name.
function ZeD.InventoryRenderer.padQuickWord(item)
    if not item then return nil end
    local R = ZeD.InventoryRenderer
    if R.padIsFood(item) then return R.padEatWord(item) end
    if R.padIsDrink(item) then return R.padDrinkWord(item) end
    local okB, canB = pcall(function() return item:isCanBandage() end)
    if okB and canB then return getText("ContextMenu_Bandage") end
    if R.padIsUse(item) then
        local okT, pill = pcall(function() return item:hasTag(ItemTag.CONSUMABLE) end)
        if okT and pill then
            local ok, own = pcall(function() return item:getCustomMenuOption() end)
            if ok and own and own ~= "" then return tostring(own) end
            return getText("ContextMenu_Take_pills")
        end
    end
    return nil
end
-- (Nov 14 2026, punch list 223: X is the game's grab, so its word says where the row goes: Grab from the World
-- window, Drop onto the floor, Move into a container; the marked words of the band's own button with marks.
-- Nowhere to go (your side with no container across): no X.)
function ZeD.InventoryRenderer.padPromptX(w, el)
    local cnt = w and w._mainContent
    local CT = ZeD.ContainerControls
    local dest = cnt and CT and CT.otherInventory and CT.otherInventory(cnt)
    -- (KISS #30) hold X is the game's quick use, now named beside the tap: "Grab, hold: Eat"
    local quick = el and el.item and ZeD.InventoryRenderer.padQuickWord(el.item)
    if not dest then
        if quick then return ZeD.tr("UI_ZeD_Prompt_Hold", quick) end
        return false
    end
    local toFloor = dest:getType() == "floor"
    local mine = cnt._ccSide == "char"
    if ZeD.InventoryRenderer.padMarkCount(w) > 0 then
        if not mine then return ZeD.tr("UI_ZeD_Controls_TakeMarked") end
        return ZeD.tr(toFloor and "UI_ZeD_Controls_DropMarked" or "UI_ZeD_Controls_MoveMarked")
    end
    local tap
    if not mine then tap = getText("ContextMenu_Grab")
    else tap = toFloor and getText("ContextMenu_Drop") or ZeD.tr("UI_ZeD_Inv_PromptMove") end
    if quick then return ZeD.tr("UI_ZeD_Prompt_TapHold", tap, quick) end
    return tap
end
function ZeD.InventoryRenderer.padPromptHold(w, el)
    -- (KISS #30) in his own bags hold A runs the game's quick use and names it (Eat, Drink, Take Pills, Bandage);
    -- anywhere else (a crate, the floor) hold A always marks, so a fridge of food can be marked
    if el and ZeD.InventoryRenderer.padOwnBags(w, el) then
        local quick = ZeD.InventoryRenderer.padQuickWord(el.item)
        if quick then return quick end
    end
    local sel = padSel(w, el)
    local marked = sel and el and el.item and sel[el.item]
    return ZeD.tr(marked and "UI_ZeD_Inv_PromptUnmark" or "UI_ZeD_Inv_PromptMark")
end

-- ============================================================================
-- THE GAME'S CONTROLLER INVENTORY (Nov 14 2026, punch list 223, the design lead's "Match the game"; punch list 225,
-- "Eat on a hold")
-- X tapped on a row moves it to the other window's container, as the game's own X (doGrabOnJoypadSelected): a
-- stack header takes its whole stack (the game's grab of a folded stack), marked rows all go (the band's Move /
-- Take marked). A on a row whose card is already open is the game's menu (X's old job); A on any other row opens
-- the card as before. Hold X stays the quick use. On food, hold A eats (never a tap); hold A elsewhere marks.
-- Each list's builder hands its item elements to padItemButtons once they are made.
-- ============================================================================
-- the card's test for food (ItemCardOrganism's categoryOf: a thing with fluid in it is a drink, not food)
function ZeD.InventoryRenderer.padIsFood(item)
    if not item then return false end
    local ok, cat = pcall(function() return item:getCategory() end)
    if not (ok and cat == "Food") then return false end
    local okF, fc = pcall(function() return item:getFluidContainer() end)
    return not (okF and fc)
end
-- the card's Eat word: the game's own verb when the food has one (Smoke, Drink, Chew ...), else Eat
function ZeD.InventoryRenderer.padEatWord(item)
    local ok, own = pcall(function() return item:getCustomMenuOption() end)
    if ok and own and own ~= "" then return tostring(own) end
    return getText("ContextMenu_Eat")
end
-- the card's EAT (ZeD_ItemCard:_dispatchHeaderVerb): the game's eat, which brings the food over first
function ZeD.InventoryRenderer.padEat(w, el)
    local item = el and el.item
    local pn = ZeD.playerNumOf(w)
    local playerObj = getSpecificPlayer(pn)
    if not (item and playerObj and item:getContainer()) then return end
    if playerObj.isAsleep and playerObj:isAsleep() then return end
    -- the card's own rule and verb (QA K1-2): stuffed, nothing (the game grays its Eat); else the eat that
    -- runs the opening recipe first (ZeD_QuickWheel's)
    local IC, Q = ZeD.ItemCard, ZeD.QuickWheel
    if IC and IC.eatOff and IC.eatOff(item, playerObj) then return end
    if Q and Q.eat then Q.eat(playerObj, item); return end
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.eatItem then ISInventoryPaneContextMenu.eatItem(item, 1, pn) end
end
-- (Nov 14 2026, punch list 228q: a drink is a hold too. A bottle, a can of pop, a canteen: the card's test for its
-- Drink (ItemCardOrganism's headerVerbsForContext: fluid in it, not empty, not sealed); A, A on the row drank it,
-- bleach and petrol included, since the card's Drink was a tap)
function ZeD.InventoryRenderer.padIsDrink(item)
    if not item then return false end
    -- the card's own rule (QA K1-2): only a beverage the game offers Drink on, so a held A never drinks
    -- bleach, gasoline or rubbing alcohol; anything else held marks
    local IC = ZeD.ItemCard
    if IC and IC.canDrink then return (IC.canDrink(item)) and true or false end
    local okF, fc = pcall(function() return item:getFluidContainer() end)
    if not (okF and fc) then return false end
    local okE, empty = pcall(function() return fc:isEmpty() end)
    if okE and empty then return false end
    local okS, sealed = pcall(function() return item:isSealed() end)
    return not (okS and sealed)
end
-- the card's Drink word: the game's own verb when the drink has one, else Drink
function ZeD.InventoryRenderer.padDrinkWord(item)
    local ok, own = pcall(function() return item:getCustomMenuOption() end)
    if ok and own and own ~= "" then return tostring(own) end
    return getText("ContextMenu_Drink")
end
-- the card's DRINK (ZeD_ItemCard:_dispatchHeaderVerb): the game's drink, which brings the bottle over first
function ZeD.InventoryRenderer.padDrink(w, el)
    local item = el and el.item
    local pn = ZeD.playerNumOf(w)
    local playerObj = getSpecificPlayer(pn)
    if not (item and playerObj and item:getContainer()) then return end
    if playerObj.isAsleep and playerObj:isAsleep() then return end
    -- the card's rule and verb (QA K1-2): grayed (too full) does nothing; water by thirst, another drink whole
    local IC, Q = ZeD.ItemCard, ZeD.QuickWheel
    if IC and IC.canDrink then
        local ok, off = IC.canDrink(item, playerObj)
        if not ok or off then return end
    end
    if Q and Q.drink then Q.drink(playerObj, item); return end
    local CM = ISInventoryPaneContextMenu
    if CM and CM.onDrinkFluid then CM.onDrinkFluid(item, 1, playerObj, nil, item) end
end
-- (Nov 14 2026, punch list 228q follow-up, the design lead's "Yes, hold uses it": a thing whose card's main verb is
-- Use (a drainable: pills, cigarettes, anything the game uses by its double-click) is a hold too, as food and drinks are;
-- marking it is a painted run started on another row)
function ZeD.InventoryRenderer.padIsUse(item)
    if not item then return false end
    local IC = ZeD.ItemCard
    if not (IC and IC.categoryOf) then return false end
    local ok, cat = pcall(IC.categoryOf, item)
    -- a drainable gets Use only where the card gives it one: wipes and thread don't (QA K2 review)
    return ok and cat == "Drainable" and IC.drainableUse and IC.drainableUse(item) or false
end
-- the card's Use word
function ZeD.InventoryRenderer.padUseWord()
    local IC = ZeD.ItemCard
    if IC and IC.verbText then return IC.verbText("USE") end
    return ZeD.tr("UI_ZeD_Card_VerbUse")
end
-- the card's USE (ZeD_ItemCard:_dispatchHeaderVerb): the game's double-click, which takes a pill or smokes, bringing
-- the thing over first
function ZeD.InventoryRenderer.padUse(w, el)
    local item = el and el.item
    local pn = ZeD.playerNumOf(w)
    local playerObj = getSpecificPlayer(pn)
    if not (item and playerObj and item:getContainer()) then return end
    if playerObj.isAsleep and playerObj:isAsleep() then return end
    if ISInventoryPane and ISInventoryPane.doContextualDblClick then ISInventoryPane.doContextualDblClick({ player = pn }, item) end
end
-- a stack header with more than one in it (A on it folds or opens the stack)
local function padIsStack(w, el)
    local _, cnt, cs = padSel(w, el)
    return #padStackItems(cnt, cs, el.item) > 1
end
-- the row's card is the one open in the drawer (the second A is the menu)
function ZeD.InventoryRenderer.padCardOpen(w, el)
    return el and el.item ~= nil and w and w._drawerItem == el.item and not padIsStack(w, el)
end
-- X tapped: the row (its stack, or every marked row) to the other window's container
function ZeD.InventoryRenderer.padMove(w, el)
    if not (el and el.item) then return end
    local cnt = w and w._mainContent
    local CT = ZeD.ContainerControls
    if not (cnt and CT and CT.moveToOther) then return end
    local marked = ZeD.InventoryRenderer.padMarkedAll(cnt)
    local _, _, cs = padSel(w, el)
    local items = marked or padStackItems(cnt, cs, el.item)
    if CT.moveToOther(cnt, items) and marked then
        wipeMarks(cnt)
        padRefresh(w, cnt)
    end
end
-- an item row's or cell's controller buttons, on top of what its builder gave it: the builder's onContextMenu
-- (the game's menu) moves to A on an open card, X becomes the move, hold A on food eats
function ZeD.InventoryRenderer.padItemButtons(el)
    local tap, menu, mark = el.onActivate, el.onContextMenu, el.onHoldActivate
    el.onItemMenu = menu
    el.onActivate = function(w, e)
        if menu and ZeD.InventoryRenderer.padCardOpen(w, e) then return menu(w, e) end
        if tap then return tap(w, e) end
    end
    el.onContextMenu = ZeD.InventoryRenderer.padMove
    el.onHoldActivate = function(w, e)
        -- (KISS #30) the quick use only in his own bags (food, a drink, pills, a bandage); elsewhere hold A marks
        if ZeD.InventoryRenderer.padOwnBags(w, e) and ZeD.InventoryRenderer.padQuickWord(e.item) then
            if ZeD.InventoryRenderer.padIsFood(e.item) then return ZeD.InventoryRenderer.padEat(w, e) end
            if ZeD.InventoryRenderer.padIsDrink(e.item) then return ZeD.InventoryRenderer.padDrink(w, e) end   -- (punch list 228q)
            return ZeD.InventoryRenderer.padUse(w, e)   -- (pills, a bandage: the game's double-click)
        end
        if mark then return mark(w, e) end
    end
    el.promptA = function(w, e)
        if menu and ZeD.InventoryRenderer.padCardOpen(w, e) then return ZeD.tr("UI_ZeD_Prompt_Menu") end
        return nil
    end
    el.promptX = ZeD.InventoryRenderer.padPromptX
    el.promptHold = ZeD.InventoryRenderer.padPromptHold
    -- (Nov 15 2026, add-on hooks: with an add-on's grid layout on, X held on a cell of its grid places the thing,
    -- GridLayout.lua; elsewhere, and without an add-on, X held stays the quick use)
    ZeD.GridLayout.padButtons(el)
    return el
end

-- (Nov 15 2026, punch list 245) An open stack's header row as a controller stop. It is the stack, not an item:
-- A shuts the stack (as A on its row opened it), X moves the whole stack (or the marked rows), hold A marks or
-- unmarks every item in it, B clears the marks. It carries no .item; the window's remembered row is the stack's
-- first item, so focus lands on the shut stack's row after A, and the list's scroll follows "stackhead:<key>".
local function headFocus(w, el)
    local cnt = w._mainContent
    if cnt then cnt._gpFocusedRowItem = el.yKey end
    if el.colIdx then
        w._gpFocusedMCItem, w._gpFocusedMCColIdx = el.rep, el.colIdx
    else
        w._gpFocusedRowItem = el.rep
    end
end
local function headToggle(w, el)
    local cnt = w._mainContent
    local cs = el.colIdx and cnt and cnt._colStates and cnt._colStates[el.colIdx] or nil
    local exp = cs and cs.expandedStacks or (cnt and cnt._expandedStacks)
    if exp then exp[el.stackKey] = not exp[el.stackKey] end
    -- (QA, Nov 15 2026: A on a header left a stack open that A had opened; the log says which table it turned)
    print("[ZeD.Input] Focus: stack header " .. tostring(el.stackKey) .. " col " .. tostring(el.colIdx) .. " -> "
        .. tostring(exp and exp[el.stackKey]) .. " (table " .. tostring(exp) .. ", list's " .. tostring(cnt and cnt._expandedStacks) .. ")")
end
local function headMove(w, el)
    local cnt = w and w._mainContent
    local CT = ZeD.ContainerControls
    if not (cnt and CT and CT.moveToOther) then return end
    local marked = ZeD.InventoryRenderer.padMarkedAll(cnt)
    if CT.moveToOther(cnt, marked or el.stack.items) and marked then
        wipeMarks(cnt)
        padRefresh(w, cnt)
    end
end
local function headMark(w, el)
    local sel, cnt = padSel(w, el)
    if not sel then return end
    local adding = false
    for _, it in ipairs(el.stack.items) do if not sel[it] then adding = true end end
    for _, it in ipairs(el.stack.items) do sel[it] = adding or nil end
    cnt._padMarks = true
    padRefresh(w, cnt)
end
--- The stops for a list's open stack headers (heads: the renderer's _openHeads / a column's openHeads; yMap: its
--- row places; x, w: the rows' span; view: its _rowView; colIdx: the column's slot, nil for a window's main list;
--- inv: the list's container). Appended to the item rows' stops by each list's builder.
function ZeD.InventoryRenderer.headElements(heads, yMap, x, w, view, colIdx, containerIdx, inv)
    local els = {}
    local T = ZeD.T
    local rowH = (T and T.rowH) or 26
    for _, s in ipairs(heads or {}) do
        local yKey = "stackhead:" .. s.key
        local y = yMap and yMap[yKey]
        if y then
            els[#els + 1] = {
                x = x, y = y, w = w, h = rowH,
                id = "stackhead:" .. tostring(colIdx or 0) .. ":" .. s.key,
                isStackHead = true, stackKey = s.key, stackInv = inv, stack = s, rep = s.items[1], yKey = yKey,
                colIdx = colIdx, mcSlot = colIdx, containerIdx = containerIdx,
                -- (out of the list's view: a stop for its own list's Up / Down only, as Focus.markOffscreen marks rows)
                offscreen = (view and view.top and view.bottom and (y + rowH <= view.top or y >= view.bottom)) or nil,
                onFocus = headFocus, onActivate = headToggle, onContextMenu = headMove, onHoldActivate = headMark,
                onCancel = ZeD.InventoryRenderer.padCancel, promptB = ZeD.InventoryRenderer.padPromptB,
                promptX = ZeD.InventoryRenderer.padPromptX, promptHold = ZeD.InventoryRenderer.padPromptHold,
            }
        end
    end
    return els
end

-- (Nov 16 2026, punch list 256) A category's heading as a controller stop: A folds or opens it, as a click does. It
-- carries no item; the list's scroll follows "cat:<category>" (the renderer stamps the heading's place under it).
-- The window's remembered row is the category's first row (nil while it is folded).
local function catFolds(w, el)
    local cnt = w and w._mainContent
    local cs = el.colIdx and cnt and cnt._colStates and cnt._colStates[el.colIdx] or nil
    return (cs and cs.collapsedGroups) or (cnt and cnt._collapsedGroups)
end
local function catFocus(w, el)
    local cnt = w._mainContent
    if cnt then cnt._gpFocusedRowItem = el.yKey end
    if el.colIdx then
        w._gpFocusedMCItem, w._gpFocusedMCColIdx = el.rep, el.colIdx
    else
        w._gpFocusedRowItem = el.rep
    end
end
local function catToggle(w, el)
    local folds = catFolds(w, el)
    if not folds then return end
    if folds[el.cat] then folds[el.cat] = nil else folds[el.cat] = true end
    pcall(function() ZeD.uiSound("UISelectListItem") end)
end
local function catPromptA(w, el)
    local folds = catFolds(w, el)
    return ZeD.tr((folds and folds[el.cat]) and "UI_ZeD_Prompt_Unfold" or "UI_ZeD_Prompt_Fold")
end
--- The stops for a list's category headings (cats: the renderer's _catHeads / a column's catHeads, in order; groups:
--- its rows by category, for each heading's first row; yMap, x, w, view, colIdx, containerIdx, inv: as headElements).
--- Appended to the item rows' stops by each list's builder; a heading not drawn this frame (no place in yMap) has none.
function ZeD.InventoryRenderer.catElements(cats, groups, yMap, x, w, view, colIdx, containerIdx, inv)
    local els = {}
    if not (cats and yMap) then return els end
    local T = ZeD.T
    local hh = (T and T.sp and T.sp.catHdrH) or (T and T.rowH) or 26
    for _, cat in ipairs(cats) do
        local yKey = "cat:" .. tostring(cat)
        local y = yMap[yKey]
        if y then
            local rows = groups and groups[cat]
            els[#els + 1] = {
                x = x, y = y, w = w, h = hh,
                id = "cathead:" .. tostring(colIdx or 0) .. ":" .. tostring(cat),
                isCatHead = true, cat = cat, catInv = inv, rep = rows and rows[1] or nil, yKey = yKey,
                colIdx = colIdx, mcSlot = colIdx, containerIdx = containerIdx,
                offscreen = (view and view.top and view.bottom and (y + hh <= view.top or y >= view.bottom)) or nil,
                onFocus = catFocus, onActivate = catToggle, promptA = catPromptA,
                onCancel = ZeD.InventoryRenderer.padCancel, promptB = ZeD.InventoryRenderer.padPromptB,
            }
        end
    end
    return els
end

-- The quick use itself, for the double-click and the controller's hold X on
-- a row. Vanilla's basic action does nothing for a thing in a crate, so, as
-- vanilla's double-click does, a thing elsewhere comes over first.
-- wear: the game's Shift + double-click, each garment that comes over (not a broken one) is put on after (L1-5)
function ZeD.InventoryRenderer.quickUse(item, playerNum, rows, wear)   -- rows: the closed stack's things, if it is one (QA K2-8)
    local playerObj = getSpecificPlayer(playerNum)
    local src = item and item:getContainer()
    if not (playerObj and src) then return end
    local mainInv = playerObj:getInventory()
    -- (into the bag on show, as the game's double-click fills its page's selected bag; a Shift + double-click wears,
    -- so it comes to the main inventory first. A thing already in that bag is used, as in the game. QA's loot KISS)
    local dest = wear and mainInv or ZeD.ContainerControls.takeDest(playerObj) or mainInv
    if src == mainInv or src == dest then
        ISInventoryPane.doContextualDblClick({ player = playerNum }, item)
    elseif isForceDropHeavyItem and isForceDropHeavyItem(item) then
        ISInventoryPaneContextMenu.equipHeavyItem(playerObj, item)
    elseif not (item:isHumanCorpse() and playerObj:getVehicle()) then
        local floor = src:getType() == "floor"
        if floor or luautils.walkToContainer(src, playerNum) then
            ZeD.ContainerControls.moveItems(playerObj, rows or { item }, dest)
            if wear then
                for _, it in ipairs(rows or { item }) do
                    if instanceof(it, "Clothing") and not it:isBroken() then ISTimedActionQueue.add(ISWearClothing:new(playerObj, it)) end
                end
            end
        end
    end
end

-- The heading's controller elements for a column (each builder appends them):
-- rects stamped by the renderer in panel coords; A on the view button flips the view.
-- The Filter's stops (its button, the bar's field, Clear and chips): A does what a click does (on the field it opens
-- the controller's keyboard), X clears the filter wherever the pad is in the bar.
local function filterOf(w)
    local c = w and w._mainContent
    return c and c._zedFilter
end
local function filterPromptX(w)
    return ZeD.InvFilter.active(filterOf(w)) and ZeD.tr("UI_ZeD_Inv_FilterClear") or false
end
local function filterElement(el)
    el.onActivate = function(w, e)
        local S = filterOf(w)
        if S then ZeD.InvFilter.act(S, e.view == "filter" and "filter" or e.key, w) end
    end
    el.onContextMenu = function(w)
        local S = filterOf(w)
        if S then ZeD.InvFilter.clear(S) end
    end
    el.promptX = filterPromptX
    if el.key == "field" then el.promptA = ZeD.tr("UI_ZeD_Inv_PromptType") end
end

function ZeD.InventoryRenderer.toggleElements(rects)
    local els = {}
    for _, r in ipairs(rects or {}) do
        if not (r.view == "fbar" and r.key == "bg") then   -- (the bar's ground is no stop)
            local el = {
                x = r.x, y = r.y, w = r.w, h = r.h,
                id = "view:" .. r.view .. ":" .. tostring(r.key),
                isViewToggle = true, view = r.view, key = r.key,
                onFocus = function(w, el) end,
                onActivate = function(w, el) ZeD.InventoryRenderer.flipGridKey(el.key, w and w._playerObj) end,
            }
            if r.view == "filter" or r.view == "fbar" then filterElement(el) end
            if r.view == "all" then
                -- (KISS #45) A on Pick all picks every row, as the click does
                el.promptA = ZeD.tr("UI_ZeD_Inv_PickAll")
                el.onActivate = function(w, e)
                    local cnt = w and w._mainContent
                    if cnt and cnt.zedSelectAll then cnt:zedSelectAll() end
                end
            end
            if r.view == "lootall" then
                -- (KISS #18) the heading's Loot all: A takes everything wanted from the container on show
                el.promptA = ZeD.ContainerControls.lootAllLabel()
                el.onActivate = function(w, e)
                    local cnt = w and w._mainContent
                    if cnt then ZeD.InventoryRenderer.lootAllOf(cnt, e.key) end   -- (its own column's: Header order, Nov 22 2026)
                end
            end
            els[#els + 1] = el
        end
    end
    return els
end

--- A number that changes whenever the Filter's stops move (opened, shut, laid out again): the windows' pad stops
--- rebuild on it.
function ZeD.InventoryRenderer.filterGen(content)
    local S = content and content._zedFilter
    return S and S.lgen or 0
end

--- A column's stops built again (a Loot column's charMC / worldMC zone): the index in els of the stop the zone's
--- focus is on when that is a view or Filter stop, else idx. Those stops carry no item for the rows' own match to
--- find, and a press on the Filter bar builds the stops again: without this the focus fell back to a row.
function ZeD.InventoryRenderer.keepToggleIdx(win, zoneName, els, idx)
    local ring = win and win._focusRing
    if not ring then return idx end
    for _, z in ipairs(ring) do
        if z.zone == zoneName then
            local fe = z.elements and z.elements[z.focusedElementIdx or 1]
            -- (an open stack's header too, punch list 245, and a category's heading, 256: they carry no item either)
            if fe and (fe.isViewToggle or fe.isStackHead or fe.isCatHead) then
                for i, el in ipairs(els) do if el.id == fe.id then return i end end
            end
            return idx
        end
    end
    return idx
end


-- is this item the controller's focused element in an inventory zone? (the
-- rows' own test, shared with the grid's cells). Only in the focused window
-- while the controller is in use (Focus.liveZone): no mark in mouse mode.
-- Returns the focus mark's opts ({ win, zone }) when it is, else false.
local _itemFocus, _toggleFocus = {}, {}
-- pn: the drawing panel's player (in split view each player's pad focuses a window of their own)
local function gpFocusedItem(item, pn)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow(pn) or nil
    local zone   = (focWin and Focus.liveZone) and Focus.liveZone(focWin) or nil
    local zname  = zone and zone.zone or ""
    local isInvZone = zname == "charMainInv" or zname == "worldMainInv"
                   or (zname:match("^worldMC%d+$") ~= nil) or (zname:match("^charMC%d+$") ~= nil)
    if not isInvZone then return false end
    local focEl = Focus.liveElement(focWin)
    if not (focEl ~= nil and focEl.item == item) then return false end
    _itemFocus.win, _itemFocus.zone = focWin, zname
    return _itemFocus
end

-- (Nov 14 2026, punch list 227b, the director: the pointer's quick look at a row, the loot card, on the controller's
-- row too.) The row or cell the pad rests on asks for the card at once, as a pointer resting on
-- it would; it stands beside the row (there is no pointer to stand by).
-- (Nov 17 2026, the director: "Controller tooltips, item info tooltips. Those need to be instant on controller, just
-- like they are on mouse." The pointer's card never waited; the pad's waited 400 ms on each row. It shows at once now,
-- on the frame the pad lands on the row or cell.)
local _padTipRect = { x = 0, y = 0, w = 0, h = 0 }
local function padTip(self, item, x, y, w, h, count)
    if not ZeD.InvTip then return end
    _padTipRect.x, _padTipRect.y, _padTipRect.w, _padTipRect.h = x, y, w, h
    ZeD.InvTip.want(self, item, _padTipRect, count, true, nil, true)
end

local function gpFocusedToggle(id, pn)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow(pn) or nil
    local focEl = (focWin and Focus.liveElement) and Focus.liveElement(focWin) or nil
    if not (focEl ~= nil and focEl.isViewToggle and focEl.id == id) then return nil end
    _toggleFocus.win = focWin
    return _toggleFocus
end

-- (Nov 15 2026, punch list 245) is the controller on this list's open stack header (key: the stack's)? The focus
-- mark's opts when it is, else false. Headers carry no item, so the stop names its stack and its container.
local function gpFocusedHead(key, inv, pn)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow(pn) or nil
    local focEl = (focWin and Focus.liveElement) and Focus.liveElement(focWin) or nil
    if not (focEl ~= nil and focEl.isStackHead and focEl.stackKey == key and focEl.stackInv == inv) then return false end
    local zone = Focus.liveZone and Focus.liveZone(focWin) or nil
    _itemFocus.win, _itemFocus.zone = focWin, zone and zone.zone or ""
    return _itemFocus
end

-- (Nov 16 2026, punch list 256) is the controller on this list's category heading? As gpFocusedHead; nil when not.
local function gpFocusedCat(cat, inv, pn)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow(pn) or nil
    local focEl = (focWin and Focus.liveElement) and Focus.liveElement(focWin) or nil
    if not (focEl ~= nil and focEl.isCatHead and focEl.cat == cat and focEl.catInv == inv) then return nil end
    local zone = Focus.liveZone and Focus.liveZone(focWin) or nil
    _itemFocus.win, _itemFocus.zone = focWin, zone and zone.zone or ""
    return _itemFocus
end

-- the pointer's hover is off while the controller's mark shows (the mouse
-- clears the mark; a pointer left resting never paints a second highlight)
local function cuesOn()
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    return Focus and Focus.cuesVisible and Focus.cuesVisible() or false
end

local _tipRect = { x = 0, y = 0, w = 0, h = 0 }   -- (the hovered row or cell, handed to ZeD.InvTip.want)

-- What a row asks the game about its item, kept a short while: the picture, the name, the belt slot, the
-- bar, the cooking state and the weight. Every visible row asked about a dozen of these every frame (a
-- stack's head asked them of every item in the stack), the bulk of the lists' 3 ms a draw at 4K. The whole
-- table starts over every ROW_KEEP_MS and on every container event (the models' number), so a rename, a
-- worn condition or a drained lighter shows at most a quarter second late, and nothing is kept for long.
-- (QA's speed audit, Nov 20 2026, finding 2)
local ROW_KEEP_MS = 250
local _rowKeep, _rowKeepAt, _rowKeepGen = {}, 0, -1
local function rowRec(key)
    local now = ZeD._nowMs or getTimestampMs()
    local IR = ZeD.InventoryRenderer
    local gen = IR.modelGen and IR.modelGen() or 0
    if now - _rowKeepAt >= ROW_KEEP_MS or now < _rowKeepAt or gen ~= _rowKeepGen then
        _rowKeep, _rowKeepAt, _rowKeepGen = {}, now, gen
    end
    local r = _rowKeep[key]
    if not r then r = {}; _rowKeep[key] = r end
    return r
end
ZeD.InventoryRenderer.rowRec = rowRec   -- (weightText and stackWeight reach it here: QA's sims lift them out alone)
local function keptTex(item)
    local r = rowRec(item)
    if r.tex == nil then r.tex = item:getTex() or false end
    return r.tex or nil
end
local function keptName(item)
    local r = rowRec(item)
    if r.name == nil then r.name = item:getName() or "???" end
    return r.name
end
local function keptSlot(item)
    local r = rowRec(item)
    if r.slot == nil then
        local ok, s = pcall(item.getAttachedSlot, item)
        r.slot = (ok and s) or false
    end
    return r.slot or nil
end

-- An item waiting to move (punch list 146, after the streamer's clips: vanilla's rows say "Moving to container" with
-- a bar while he reads on): "Moving" in the category column (wordW > 0) and a thin bar along the row's or cell's
-- foot, filling as it goes. True when the item is waiting.
-- (Nov 14 2026, punch list 222, the director ate a raw pork chop: nothing on its row said it was still cooking.)
-- Food on a lit stove, oven or fire: how far along (0..1) and whether it is now burning; nil when not cooking.
-- Read only for Food rows; heating is the food's own heat above 1.6, the game's test (ISInventoryPane).
local cookStateNow
local function cookState(item)
    -- (kept with the row's record: see rowRec)
    local r = rowRec(item)
    if r.cDone then return r.cp, r.cb end
    r.cp, r.cb = cookStateNow(item)
    r.cDone = true
    return r.cp, r.cb
end
cookStateNow = function(item)
    if not (instanceof and instanceof(item, "Food")) then return nil end
    local ok, p, burning = pcall(function()
        if not item:isCookable() or item:isBurnt() then return nil end
        -- (punch list 224: heating is the game's own test, the food's heat, as its inventory pane reads it: an
        -- oven switched on with no power or gas reads Activated, yet cooks nothing)
        if item:isFrozen() or (item:getHeat() or 0) <= 1.6 then return nil end
        local ct, toCook, toBurn = item:getCookingTime() or 0, item:getMinutesToCook() or 0, item:getMinutesToBurn() or 0
        if item:isCooked() or (toCook > 0 and ct >= toCook) then
            return math.max(0, math.min(1, (ct - toCook) / math.max(1, toBurn - toCook))), true
        end
        return (toCook > 0) and math.max(0, math.min(1, ct / toCook)) or 0, false
    end)
    if not ok or p == nil then return nil end
    return p, burning
end

local function queueMark(self, item, wordX, wordY, wordW, rx, ry, rw, rh)
    local IT = ZeD.InvTip
    local d = IT and IT.queued and IT.queued(self, item)
    local T = ZeD.T
    if d == nil then
        -- cooking: the same thin bar along the foot, the accent while it cooks, danger once it burns, and the
        -- game's word for it in the category column
        local p, burning = cookState(item)
        if p == nil then return false end
        local c = burning and T.danger or T.accent
        local base = T.base
        local bh = T.px(2)
        self:drawRect(rx, ry + rh - bh, rw, bh, 1, base.r, base.g, base.b)
        if p > 0 then self:drawRect(rx, ry + rh - bh, math.max(1, math.floor(rw * p)), bh, 1, c.r, c.g, c.b) end
        if wordW and wordW > 0 then
            local s = ZeD.Atoms.truncateText(ZeD.textCase(getText(burning and "IGUI_invpanel_Burning" or "IGUI_invpanel_Cooking")), T.fontF1, wordW)
            local tc = burning and T.danger or (T.accentText or T.accent)
            self:drawText(s, wordX, wordY, tc.r, tc.g, tc.b, 1, T.fontF1)
        end
        return true
    end
    local ac, base = T.accent, T.base
    local bh = T.px(2)
    self:drawRect(rx, ry + rh - bh, rw, bh, 1, base.r, base.g, base.b)
    if d > 0 then self:drawRect(rx, ry + rh - bh, math.max(1, math.floor(rw * d)), bh, 1, ac.r, ac.g, ac.b) end
    if wordW and wordW > 0 then
        local s = ZeD.Atoms.truncateText(ZeD.tr("UI_ZeD_Inv_Moving"), T.fontF1, wordW)
        local c = T.accentText or ac
        self:drawText(s, wordX, wordY, c.r, c.g, c.b, 1, T.fontF1)
    end
    return true
end

-- A row tag's width as ZeD.Molecules.drawTag draws it (F1, sentence case, no box, its status square before the word)
local function tagW(text)
    return ZeD.Atoms.tagW(text, true)
end

-- a container's key, kept per container object (asked by every column every frame; a container's
-- key never changes: its owner, bag, vehicle part or square stay its own)
local _ckey, _ckeyN = {}, 0
local function containerKeyOf(inv, playerObj)
    if not inv then return nil end
    if not playerObj then return containerKey(inv, playerObj) end
    local k = _ckey[inv]
    if k == nil then
        k = containerKey(inv, playerObj)
        -- (a vehicle part's key carries the car's database id, which a new car only gets once it is
        -- saved, and a container of no known kind may yet find one: those are asked every time)
        if not k or k:sub(1, 4) == "veh:" or k:sub(1, 5) == "type:" then return k end
        _ckeyN = _ckeyN + 1
        if _ckeyN > 96 then _ckey, _ckeyN = {}, 1 end
        _ckey[inv] = k
    end
    return k
end

-- ============================================================================
-- THE FILTER (InventoryFilter.lua): one per window, across all its columns. A
-- frame starts (filterFrame: which containers show, so their saved filter;
-- where the bar sits and how tall), each column adds its matches
-- (filterColumn), the frame ends with the bar drawn over the list side's full
-- width (filterEnd). Kept out of renderItemList: it sits near the local limit.
-- ============================================================================
local IFL = ZeD.InvFilter
local _fkeys = {}   -- (the shown containers' keys, refilled each frame: no table made per frame)

-- multi: the side-by-side columns (renderMultiColumnContent), else the one list with its heading
local function filterFrame(self, multi)
    local S = IFL.of(self)
    IFL.frameStart(S)
    local hdr = multi and (self._defaultHdrYOffset or ZeD.T.stripH) or self._hdrYOffset
    if type(hdr) ~= "number" or hdr <= 0 then
        -- (no heading, no Filter button: nothing narrows)
        S.shown, self._fbarH = false, 0
        IFL.hideField(S)
        return
    end
    S.shown = true
    local n, p = 0, self._playerObj
    if multi then
        for _, cs in ipairs(self._colStates or {}) do
            n = n + 1
            _fkeys[n] = containerKeyOf(cs.inventory, p) or false
        end
    else
        n = 1
        _fkeys[1] = containerKeyOf(self._inventory, p) or false
    end
    IFL.sync(S, _fkeys, n)
    S.y = (self._barH or 0) + hdr
    if S.open then
        -- (the chips are last frame's: a change in them moves the rows one frame later)
        IFL.layout(S, self:getWidth(), S.agg)
        self._fbarH = S.barH
    else
        self._fbarH = 0
    end
end

-- a column's model drew: its matches join the window's count; its rows dim by self._fres while something narrows
local function filterColumn(self, M)
    local S = self._zedFilter
    if not (S and S.shown and S.open) then self._fres = nil; return end
    local res = IFL.result(S, M)
    IFL.frameAdd(S, res)
    self._fres = res.active and res or nil
end

-- the frame's end: the bar, after the columns, so its count is this frame's
local function filterEnd(self)
    local S = self._zedFilter
    if not (S and S.shown and S.open) then
        if S then IFL.hideField(S) end
        return
    end
    local agg = IFL.aggregate(S, ZeD.InventoryRenderer.catLabel)
    IFL.layout(S, self:getWidth(), agg)
    IFL.draw(self, S, agg, gpFocusedToggle)
end

-- a row or a cell that does not match: faded toward the window's base, in place. Its hit zone stays, so it is still
-- picked, dragged and given its menu.
local function filterDim(self, x, y, w, h)
    local b = ZeD.T.base
    self:drawRect(x, y, w, h, IFL.DIM_A, b.r, b.g, b.b)
end

-- a list row's marks: the letters that matched underlined in the accent (where the shown name still holds them),
-- or the row dimmed. Never on the row the controller is on: its mark stays clear.
local function filterRowMarks(self, fr, item, nx, ty, shown, x, y, w, h, onFocus)
    if fr.match[item] then
        local at = fr.hit[item]
        if not at then return end
        local seg = string.sub(shown, at, at + #fr.ql - 1)
        if string.lower(seg) ~= fr.ql then return end
        local T, tm = ZeD.T, ZeD.TM
        local ux = nx + (at > 1 and tm:MeasureStringX(T.fontF2, string.sub(shown, 1, at - 1)) or 0)
        local c = T.accentText or T.accent
        self:drawRect(ux, ty + tm:getFontHeight(T.fontF2) - T.px(1), tm:MeasureStringX(T.fontF2, seg), T.px(1), c.a or 1, c.r, c.g, c.b)
    elseif not onFocus then
        filterDim(self, x, y, w, h)
    end
end

-- The grid's state for one column (renderItemList keeps it in one table GV)
local function gridState(self, inv, playerObj, colW, scrollW, padX, childParent)
    local T = ZeD.T
    local GV = { key = containerKeyOf(inv, playerObj), toggles = {}, child = childParent, player = playerObj or getSpecificPlayer(0) }
    GV.on   = ZeD.InventoryRenderer.isGridKey(GV.key, GV.player)
    GV.cell = T.px(GRID_CELL)
    GV.zedCell = GV.cell   -- (ZeD's own square, kept: an add-on's layout sets GV.cell to its own; drawShapeCell)
    GV.gap  = T.px(GRID_GAP)
    GV.cols = math.max(1, math.floor((colW - scrollW - padX * 2 + GV.gap) / (GV.cell + GV.gap)))
    self._gridCell = GV.on and GV.cell or nil
    return GV
end

local function gridCount(GV, list)
    local n = 0
    for _, it in ipairs(list or {}) do if not GV.child[it] then n = n + 1 end end
    return n
end

local function gridH(GV, n)
    if n <= 0 then return 0 end
    return GV.gap + math.ceil(n / GV.cols) * (GV.cell + GV.gap)
end

-- The view button: one icon button showing the view on show (the list's picture in list view, the grid's in grid
-- view), solid accent as the chosen view; a press flips to the other (the director, Nov 11: one button, not a List
-- and a Grid side by side). Starts at column-local x `left`, in the column heading (top barH, height areaH); names
-- its view in a hint after the pause (the library's). Stamps GV.toggles (panel coords). Returns the width taken
-- (with its gap). (Buttons right, the director, Nov 22 2026: "Buttons in headers and footers. Let's keep it
-- consistent, move them to the right, because on any dialogue or in other places, they're always on the right."
-- The heading reads [icon] [name] ... [weight and count] [buttons], the buttons at its right end in a dialog's
-- order, Take all first; this replaces the same morning's buttons-first order.)
-- measure: true returns the width only, drawing and stamping nothing (the heading works out the name's room first).
local _viewOpts = {}
local _liteOpen = { fill = { r = 0, g = 0, b = 0, a = 0 } }
local function liteOpen()   -- (Lite's Filter key while its bar is open: the selection wash under the word)
    local ac, f = ZeD.T.accent, _liteOpen.fill
    f.r, f.g, f.b, f.a = ac.r, ac.g, ac.b, ZeD.T.selectionA
    return _liteOpen
end
local function drawViewToggle(self, GV, xOff, left, barH, areaH, padX, measure)
    if not GV.key then return 0 end
    local T = ZeD.T
    local M = ZeD.Molecules
    local bw = math.max(T.px(16), math.min(T.buttonH, areaH - T.px(4)))
    -- Filter first, a little apart from the view button (Filter is not a view), where the window has a Filter
    -- (filterFrame: a heading)
    local S = self._zedFilter
    local withF = S ~= nil and S.shown
    local fgap = T.px(6)
    -- (beta 21, Lite: the two keys say what they are in words, "Filter" and "List" or "Grid", in place of the funnel
    -- and the view's picture: the director's answer to "buttons not obvious")
    -- (Name first, QA's Lite finding, Nov 22 2026: a short heading's buttons give way before its name, GV.headLevel
    -- from headFit: 1 Lite's words become the pictures, 2 no view flip, 3 no Filter either, 4 no Pick all either)
    local lvl = GV.headLevel or 0
    local lite = M.lite and M.lite() and lvl < 1
    if lvl >= 3 and withF then
        withF = false
        -- (the Filter's key gave way, its open bar has not: the bar's stops still ride with the toggles)
        if S.open and not measure then for _, r in ipairs(S.rects) do GV.toggles[#GV.toggles + 1] = r end end
    end
    local grid0 = GV.on and true or false
    local fWord = ZeD.tr("UI_ZeD_Inv_Filter")
    local vWord = grid0 and ZeD.tr("UI_ZeD_Inv_GridView") or getText("IGUI_CraftingWindow_ListView")
    local fw = lite and M.buttonW(fWord) or bw
    local vw = lite and M.buttonW(vWord) or bw
    -- (Selection in the header, the director, Nov 22 2026: "Transfer buttons, always in the footer. Selection buttons,
    -- always in the header." The heading's Take all (KISS #18) went back to the footer: ContainerControls' band, and
    -- a Loot column's own foot, drawColumnFoot. The heading holds Pick all, the Filter and the view flip only.)
    -- (KISS #45) a Pick all button beside the Filter (the window's zedSelectAll picks every row of the column)
    local allWord = ZeD.tr("UI_ZeD_Inv_PickAll")
    local allOn = lvl < 4
    local flipOn = lvl < 2
    local aw = M.buttonW(allWord)
    local tW = (flipOn and vw or 0) + (withF and (fw + fgap) or 0) + (allOn and (aw + fgap) or 0)
    if not flipOn and tW > 0 then tW = tW - fgap end   -- (the last button has no gap after it)
    if tW <= 0 then return 0 end
    if measure then return tW + padX end
    local tx = xOff + left   -- (left: where the heading puts the run, at its right end: Buttons right)
    local ty = barH + math.floor((areaH - bw) / 2)
    if allOn then
        local id = "view:all:" .. GV.key
        local o = _viewOpts
        o.active, o.hover = false, ZeD.Atoms.mouseIn(self, tx, ty, aw, bw)
        o.disabled = nil
        o.focus, o.hint, o.id = gpFocusedToggle(id, ZeD.playerNumOf(self)), allWord, id
        o.help = ZeD.tr("UI_ZeD_Inv_PickAllHelp")
        M.drawButton(self, tx, ty, aw, bw, allWord, "default", false, nil, o)
        GV.toggles[#GV.toggles + 1] = { x = tx, y = ty, w = aw, h = bw, view = "all", key = GV.key, id = id }
        tx = tx + aw + fgap
    end
    if withF then
        local id = "view:filter:" .. GV.key
        local o = _viewOpts
        o.active, o.hover = S.open, ZeD.Atoms.mouseIn(self, tx, ty, bw, bw)
        o.focus, o.hint, o.id = gpFocusedToggle(id, ZeD.playerNumOf(self)), ZeD.tr("UI_ZeD_Inv_Filter"), id
        o.help = ZeD.tr("UI_ZeD_Inv_FilterHelp")
        o.iconSize = math.min(T.px(16), bw - T.px(6))
        if lite then
            o.hover = ZeD.Atoms.mouseIn(self, tx, ty, fw, bw)
            M.drawButton(self, tx, ty, fw, bw, fWord, "default", false, S.open and liteOpen() or nil, o)
        else
            o.marks = T.marks   -- (its drop in the theme's blue at rest, as the menu's marks: Icon color, Nov 22 2026)
            M.drawIconButton(self, tx, ty, bw, "filter", o)   -- (the ZeD pixel funnel)
            o.marks = nil
        end
        GV.toggles[#GV.toggles + 1] = { x = tx, y = ty, w = fw, h = bw, view = "filter", key = GV.key, id = id }
        tx = tx + fw + fgap
        -- the bar's stops ride with every column's toggles: the controller reaches them from any column, and their
        -- zones go in before the rows' (a cell scrolled half under the bar never takes its press)
        if S.open then
            for _, r in ipairs(S.rects) do GV.toggles[#GV.toggles + 1] = r end
        end
    end
    if not flipOn then return tW + padX end
    -- (one id whichever view is on show: the pad's stop keeps its place across the flip)
    local grid = GV.on and true or false
    local id = "view:flip:" .. GV.key
    local o = _viewOpts
    -- (QA's visual noise audit 37, Nov 20 2026: drawn solid it was the brightest thing in every heading, and it is a
    -- view switch, not an action; an outline now, as the Filter button beside it)
    o.active, o.hover = false, ZeD.Atoms.mouseIn(self, tx, ty, bw, bw)
    o.focus, o.id = gpFocusedToggle(id, ZeD.playerNumOf(self)), id
    o.hint = grid and ZeD.tr("UI_ZeD_Inv_GridView") or getText("IGUI_CraftingWindow_ListView")
    o.help = ZeD.tr(grid and "UI_ZeD_Inv_GridHelp" or "UI_ZeD_Inv_ListHelp")
    o.iconSize = math.min(T.px(16), bw - T.px(6))
    if lite then
        o.hover = ZeD.Atoms.mouseIn(self, tx, ty, vw, bw)
        M.drawButton(self, tx, ty, vw, bw, vWord, "default", false, nil, o)
    else
        o.marks = T.marks   -- (the bullets or the first tile in the theme's blue at rest: Icon color, Nov 22 2026)
        M.drawIconButton(self, tx, ty, bw, grid and "view_grid" or "view_list", o)   -- (ZeD pixel icons)
        o.marks = nil
    end
    GV.toggles[#GV.toggles + 1] = { x = tx, y = ty, w = vw, h = bw, view = "flip", key = GV.key, id = id }
    return tW + padX
end

-- A grid cell's bar: the framed strip (ZeD.Atoms.drawFillBar) along the cell's bottom, compact to fit under the
-- icon: its condition in a status bar's five segments, or how full it is in the fill bar's ten (ItemMeter.lua,
-- punch list 152). Returns its top (or the cell's bottom when there is none) and true while the pointer is on it
-- (its help line: "Condition 64%", "Remaining 50%"). 52 units less 6: 34 px at 0.75.
-- (Nov 15 2026, add-on hooks: cell is the cell's width; ch its height, nil for a square cell. A cell an add-on's
-- layout spans over several squares (GridLayout.lua) is wider or taller than it is the other way.)
local function drawCellCondition(self, item, ax, cy, cell, stackInfo, ch, thin, segs, geo)
    local T = ZeD.T
    local IM = ZeD.ItemMeter
    ch = ch or cell   -- (a square cell: as tall as it is wide, as every cell was before)
    local kind, f = IM.ofStack(item, stackInfo and stackInfo.count > 1 and stackInfo.items or nil)   -- (162)
    if kind == nil or kind == "hidden" then return cy + ch, false end
    local fc, graduated = IM.style(kind)
    local bx, bw, bh = ax + T.px(3), cell - T.px(6), T.px(5)
    local by = cy + ch - T.px(3) - bh
    if geo then
        -- (Nov 18 2026, the director, Multi-Slot: "The status bar should take up the whole bottom. There should be no
        -- padding on the left, right, or bottom, and it should sit at the bottom of the tile. That way it can fill the
        -- tile and be larger." A shaped cell's strip runs the last square's whole width and sits on its foot, just
        -- inside the shape's dark outline, so the outline stays closed; on the left it runs to the square's edge where
        -- the square joins another. 8 units tall (5 before); a one-square shape's 6 (3 before), so its picture, which
        -- fills most of the square, keeps its look.)
        -- (Nov 18 2026: the strip moved to the first square; each side that joins another square has no outline, so
        -- the strip runs to the square's edge there)
        local t = geo.t or 0
        local li, ri, bi = geo.lopen and 0 or t, geo.ropen and 0 or t, geo.bopen and 0 or t
        bh = thin and T.px(6) or T.px(8)
        bx, bw, by = ax + li, cell - li - ri, cy + ch - bi - bh
    elseif thin then
        -- (Nov 17 2026, Multi-Slot 0.2, QA: thin, a one-square shape: a slim strip along the square's very foot)
        bh = T.px(3); by = cy + ch - T.px(1) - bh
    end
    -- (segs: a shaped cell's strip, three segments, the director Nov 17 2026; nil every other cell, as before)
    local hov = ZeD.Atoms.drawFillBar(self, bx, by, bw, f, graduated, fc, bh, IM.label(kind), segs)
    return by, hov
end

-- A stack's total weight, summed as vanilla's inventory sums a stack
-- (ISInventoryPane: getUnequippedWeight of each).
local function stackWeight(stackInfo)
    local RR = ZeD.InventoryRenderer.rowRec
    local r = RR and RR(stackInfo) or {}   -- (kept a short while: see rowRec)
    if r.total then return r.total end
    local total = 0
    for _, si in ipairs(stackInfo.items) do total = total + (si:getUnequippedWeight() or 0) end
    r.total = total
    return total
end

-- A row's or a cell's weight: an item's own ("0.5"), a stack's total in
-- brackets ("(2.5)": five at 0.5; open the stack and each row shows its
-- own). A total wider than room in font drops its
-- decimal ("(120)"), then gives way to the item's own.
local function weightText(item, stackInfo, font, room)
    local RR = ZeD.InventoryRenderer.rowRec
    local r = RR and RR(item) or {}   -- (the item's own weight, worded once a while: see rowRec)
    local unit = r.unit
    if not unit then unit = string.format("%.1f", item:getUnequippedWeight() or 0); r.unit = unit end
    if not (stackInfo and stackInfo.count > 1 and stackInfo.items) then return unit end
    local total = stackWeight(stackInfo)
    local s = "(" .. string.format("%.1f", total) .. ")"
    if room and ZeD.TM:MeasureStringX(font, s) > room then
        s = "(" .. string.format("%.0f", total) .. ")"
        if ZeD.TM:MeasureStringX(font, s) > room then return unit end
    end
    return s
end
ZeD.InventoryRenderer.weightText = weightText

-- The bracket's share of a weight column set px wide: what it holds past the
-- unit's width. COND and CAT drop on the column less this share, so the bracket
-- never drops a column; it takes its room from the name instead.
local function wtShare(cw, set)
    return math.max(0, math.min(cw.wtB - cw.wtU, set - cw.wtU))
end

-- The list's weight column for room px (the row less the icon, the paddings and
-- the other columns): its set width while the name keeps minName less the
-- bracket's share; past that the bracket gives way (a stack's row draws what
-- fits, see weightText), so it only gives way where the name, with the unit
-- alone, is already under minName. A column set under the unit's width (a drag)
-- is left as set.
local function wtFit(cw, set, room, minName)
    local share = wtShare(cw, set)
    local give = math.min(share, (minName - share) - (room - set))
    return set - math.max(0, give)
end

-- (Nov 16 2026, Multi-Slot 0.2, GridLayout version 2) a shape's rects (a flat list of x, y, w, h from its geo) filled
-- at ox, oy; and is the point mx, my (relative to the shape's box) on one of them
local function paintRects(self, list, ox, oy, a, r, g, b)
    for k = 1, #list, 4 do self:drawRect(ox + list[k], oy + list[k + 1], list[k + 2], list[k + 3], a, r, g, b) end
end
local function onRects(list, mx, my)
    for k = 1, #list, 4 do
        if mx >= list[k] and mx < list[k] + list[k + 2] and my >= list[k + 1] and my < list[k + 1] + list[k + 3] then return true end
    end
    return false
end

-- One SHAPED cell (an add-on's layout, GridLayout version 2; geo is its drawing, made once with the layout): each
-- square filled with the item's tint (always on here: the director's approved shapes are all tinted; a plain tile
-- where the item has no main color), the gaps between its squares one shade darker, a dark outline round the shape.
-- The game's picture sits in the FIRST square (top row, leftmost) at one size for every item; the weight is at the
-- top right of the top row's run (or of the square below the picture, when the run is one square); the condition strip, the count
-- and the read mark are on the LAST square (bottom row, rightmost). Hover, selection, the Filter's dim and the
-- click zones cover the shape's squares only: the holes in its box are not the item's. The controller's mark sits on
-- the first square. No tables or strings made here but the hint's, as drawGridCell.
local function drawShapeCell(self, GV, item, cx, cy, g)
    local T = ZeD.T
    local xOff = GV.xOff
    local cw, ch, sq = g.bw, g.bh, g.cell
    GV.ymap[item] = cy
    GV.xmap[item] = xOff + cx
    if cy + ch <= GV.top or cy >= GV.h then return end
    local ax = xOff + cx
    local ac = T.accent
    local tex = item:getTex()
    local fa, fr, fg, fb
    if ZeD.GridTint then fr, fg, fb = ZeD.GridTint.of(T, tex, true) end
    if fr then
        fa = T.surf1.a or 1
    else
        local st = T.stripe
        fa, fr, fg, fb = st.a, st.r, st.g, st.b
    end
    paintRects(self, g.fill, ax, cy, fa, fr, fg, fb)
    paintRects(self, g.gaps, ax, cy, fa, fr * 0.8, fg * 0.8, fb * 0.8)           -- (one shade darker)
    local isSelected = GV.sel and GV.sel[item]
    local over = GV.mouseIn and not cuesOn() and GV.my >= GV.top and GV.my < GV.top + GV.visH
                 and onRects(g.hits, GV.lmx - cx, GV.my - cy)
    if isSelected then
        paintRects(self, g.hits, ax, cy, T.selectionA, ac.r, ac.g, ac.b)
    elseif over or (self._ccMarks and ccMarked(self, item)) then
        local hv = T.hover
        paintRects(self, g.hits, ax, cy, hv.a, hv.r, hv.g, hv.b)
    end
    paintRects(self, g.edges, ax, cy, 1, fr * 0.45, fg * 0.45, fb * 0.45)       -- (the dark outline)
    local stackInfo = self._stacks and self._stacks[item]
    local count = (stackInfo and stackInfo.count) or 1
    local fo = gpFocusedItem(item, ZeD.playerNumOf(self))
    if fo then
        ZeD.Focus.mark(self, ax + g.fx, cy + g.fy, sq, sq, fo)
        padTip(self, item, ax, cy, cw, ch, count)
    end
    -- (Nov 17 2026, QA's 0.2 pass: on a ONE-square shape the picture fills most of the square, so the labels gave
    -- way to it: no weight chip there (the item's card has it), the count small at the top right, the condition a slim
    -- strip along the foot. And no chip is ever wider than its square: "(10)" spilled over the next item.)
    -- (Nov 18 2026, the director, Multi-Slot at a bigger square: "picture and labels side by side, see things at a
    -- glance". A one-square shape at least three quarters of ZeD's own cell (Multi-Slot draws them at four fifths) is
    -- labeled as ZeD's own cell is: the weight top right, the count in its usual font above the strip, the full strip.
    -- A smaller square, another provider's scale, keeps the slim fallback above.)
    -- (Nov 18 2026, the director: "move status and numbers back to icon tile". Every label now sits on the first
    -- square, with the picture, on every shape, so this rule is the same for every shape: one = the slim fallback.)
    local one = not (GV.zedCell and sq >= math.floor(GV.zedCell * 0.75))
    -- the picture, in the first square
    local isz = (GV.L and GV.L.isz) or math.floor(sq * 0.8)
    local rs = ZeD.ReadMarks.state(GV.player, item)
    if tex then
        local ia = (rs and rs.st == "r" and ZeD.ReadMarks.dimOn()) and 0.5 or 1
        local o = math.floor((sq - isz) / 2)
        local px, py = ax + g.fx + o, cy + g.fy + o
        -- (Build's call, Nov 18 2026: on a labeled one-square shape smaller than ZeD's own cell, the picture stands
        -- above the strip rather than under it: as big as fits over the strip, never bigger than it was, centred across
        -- and put just under the square's top outline. The weight chip still takes the top right corner, as on ZeD's
        -- own cells.)
        if not one and GV.zedCell and sq < GV.zedCell - 1 and not rs then
            local t = g.t or 0
            local room = sq - t - T.px(8) - (g.bopen and 0 or t) - T.px(1)
            if room < isz then isz = math.max(1, room) end
            px, py = ax + g.fx + math.floor((sq - isz) / 2), cy + g.fy + t + T.px(1)
        end
        self:drawTextureScaledAspect(tex, px, py, isz, isz, ia, 1, 1, 1)
    end
    -- the condition strip along the first square's foot (a readable item: its read mark instead)
    local lx, ly = ax + g.ix, cy + g.iy
    local condTop, condHov = ly + sq, false
    if not rs then condTop, condHov = drawCellCondition(self, item, lx, ly, sq, stackInfo, sq, one, 3, g) end   -- (three segments: the director)
    local f5 = T.fontF5
    local s1 = T.surf1
    -- the weight, top right of the first square (not in the slim fallback)
    if not one then
        local wtStr = weightText(item, stackInfo, f5, g.wroom - T.px(6))
        local wtw = ZeD.TM:MeasureStringX(f5, wtStr)
        local wr, wt = ax + g.wx + sq, cy + g.wy
        self:drawRect(wr - wtw - T.px(5), wt + T.px(1), wtw + T.px(4), GV.f5FH, s1.a or 1, s1.r, s1.g, s1.b)
        local th = T.accentText or T.text
        self:drawText(wtStr, wr - wtw - T.px(3), wt + T.px(1), th.r, th.g, th.b, th.a or 1, f5)
    end
    -- the count: bottom right of the first square, above the condition strip (one square: top right, small); the
    -- small font when the usual one is wider than the square, and never past the square's left edge
    if count > 1 then
        local cs = "(" .. count .. ")"
        local fc, fh = T.fontF1, GV.secFH
        local cw2 = ZeD.TM:MeasureStringX(fc, cs)
        if one or cw2 + T.px(5) > sq then
            fc, fh = f5, GV.f5FH
            cw2 = ZeD.TM:MeasureStringX(fc, cs)
        end
        local chipW = math.min(cw2 + T.px(4), sq - T.px(2))
        local cx2 = lx + sq - chipW - T.px(1)
        local cy2 = one and (ly + T.px(1)) or math.min(ly + sq - fh - T.px(4), condTop - fh - T.px(1))
        self:drawRect(cx2, cy2, chipW, fh, s1.a or 1, s1.r, s1.g, s1.b)
        local tc = T.text
        self:drawText(cs, cx2 + math.floor((chipW - cw2) / 2), cy2, tc.r, tc.g, tc.b, tc.a or 1, fc)
    end
    GV._beltW = 0
    if rs then
        local RM = ZeD.ReadMarks
        local ms = RM.markSize()
        RM.drawMark(self, lx + T.px(3), ly + sq - ms - T.px(3), rs.st)
        if rs.next and RM.nextOn() then RM.drawUp(self, ax + g.fx + T.px(2), cy + g.fy + T.px(2)) end
    end
    queueMark(self, item, nil, nil, 0, ax + g.fx, cy + g.fy, sq, sq)   -- (waiting to move: the bar along its first square)
    if over then
        local nm = item:getName() or "?"
        if count > 1 then nm = nm .. " (" .. count .. ")" end
        self._gridHintCand = { key = item, text = nm, read = rs, x = ax, y = cy, w = cw, h = ch }
        if ZeD.InvTip and not cuesOn() then
            local r = _tipRect
            r.x, r.y, r.w, r.h = ax, cy, cw, ch
            ZeD.InvTip.want(self, item, r, count, true)
        end
        if not condHov then ZeD.Help.set(self, ZeD.tr("UI_ZeD_Inv_RowHelpLoot", nm)) end
    end
    -- the Filter: a match takes the accent outline while text is typed; no match dims its squares
    local fres = self._fres
    if fres then
        if fres.match[item] then
            if fres.ql ~= "" then paintRects(self, g.edges, ax, cy, 1, ac.r, ac.g, ac.b) end
        elseif not fo then
            local h = g.hits
            for k = 1, #h, 4 do filterDim(self, ax + h[k], cy + h[k + 1], h[k + 2], h[k + 3]) end
        end
    end
    -- the click zones: the shape's squares and the gaps between them, never its holes
    local h = g.hits
    for k = 1, #h, 4 do self:addHitZone(item, ax + h[k], cy + h[k + 1], h[k + 2], h[k + 3]) end
end

-- One cell: the icon, the stack's weight top right, its count bottom right, the
-- condition strip along the bottom, a BELT n key square; hover T.hover, selected
-- the T.selectionA wash, the controller's focus mark under the icon. Its hit zone
-- is the item itself, as a row's is.
-- (Nov 15 2026, add-on hooks: cw, ch are the cell's width and height in px, nil for ZeD's own square cell. An add-on's
-- layout (GridLayout.lua) spans a cell over several squares: everything below is drawn on the span, the hit zone is
-- the whole span, and the icon grows to fit it, up to twice its square size. With cw and ch nil every number below
-- is the one it was before.)
local function drawGridCell(self, GV, item, cx, cy, cw, ch, geo)
    if geo then return drawShapeCell(self, GV, item, cx, cy, geo) end   -- (a shape: GridLayout version 2)
    local T = ZeD.T
    local cell, xOff = GV.cell, GV.xOff
    cw, ch = cw or cell, ch or cell   -- (a square cell when no span is given)
    GV.ymap[item] = cy
    GV.xmap[item] = xOff + cx
    if cy + ch <= GV.top or cy >= GV.h then return end
    local ax = xOff + cx
    local ac, bs = T.accent, T.borderS
    local tex = item:getTex()
    -- the fill: a soft tint of the item's main color with "Item-colored tiles" on (GridTint.lua; the director,
    -- Nov 16 2026), at the window surface's alpha so See-through holds; else the plain stripe
    local gr, gg, gb
    if ZeD.GridTint then gr, gg, gb = ZeD.GridTint.of(T, tex) end
    if gr then
        self:drawRect(ax, cy, cw, ch, T.surf1.a or 1, gr, gg, gb)
    else
        local st = T.stripe
        self:drawRect(ax, cy, cw, ch, st.a, st.r, st.g, st.b)
    end
    self:drawRectBorder(ax, cy, cw, ch, bs.a or 1, bs.r, bs.g, bs.b)
    local isSelected = GV.sel and GV.sel[item]
    -- the pointer (its name in a hint, and the help line) / the controller
    local over = GV.mouseIn and not cuesOn() and GV.lmx >= cx and GV.lmx < cx + cw and GV.my >= cy and GV.my < cy + ch
                 and GV.my >= GV.top and GV.my < GV.top + GV.visH
    if isSelected then
        self:drawRect(ax, cy, cw, ch, T.selectionA, ac.r, ac.g, ac.b)
    elseif over or (self._ccMarks and ccMarked(self, item)) then
        -- (rows a pointed-at Same type button would move read as pointed at too)
        local hv = T.hover
        self:drawRect(ax, cy, cw, ch, hv.a, hv.r, hv.g, hv.b)
    end
    local fo = gpFocusedItem(item, ZeD.playerNumOf(self))
    if fo then
        ZeD.Focus.mark(self, ax, cy, cw, ch, fo)
        local si = self._stacks and self._stacks[item]
        padTip(self, item, ax, cy, cw, ch, si and si.count or 1)
    end
    local stackInfo = self._stacks and self._stacks[item]
    local count = (stackInfo and stackInfo.count) or 1
    local isz = math.floor(cell * 32 / 52)
    -- (the icon's box on a span: the same share of the span as of a square, at most twice the square's icon; the
    -- texture keeps its own shape inside it. On a square cell both are isz, as before.)
    local iw, ih = math.min(math.floor(cw * 32 / 52), isz * 2), math.min(math.floor(ch * 32 / 52), isz * 2)
    -- the read mark (ReadMarks.lua): read items faded when "Dim read items" is on
    local rs = ZeD.ReadMarks.state(GV.player, item)
    if tex then
        local ia = (rs and rs.st == "r" and ZeD.ReadMarks.dimOn()) and 0.5 or 1
        self:drawTextureScaledAspect(tex, ax + math.floor((cw - iw) / 2), cy + math.floor((ch - ih) / 2), iw, ih, ia, 1, 1, 1)
    end
    -- condition, the framed strip along the bottom (the list's colours); a readable
    -- item shows its read mark instead, as the list's COND column does
    local condTop, condHov = cy + ch, false
    if not rs then condTop, condHov = drawCellCondition(self, item, ax, cy, cw, stackInfo, ch) end
    -- on the belt: its key, top left (the list's BELT n tag), drawn below; measured here for the weight's room
    local f5 = T.fontF5
    local okAS, aslot = pcall(function() return item:getAttachedSlot() end)
    local k = okAS and aslot and aslot > 0 and ZeD.Belt and ZeD.Belt.keyLabel and tostring(ZeD.Belt.keyLabel(aslot) or aslot)
    local kw = k and math.max(ZeD.TM:MeasureStringX(f5, k) + T.px(6), GV.f5FH) or 0
    -- the weight, top right: the item's own, a stack's total in brackets (the grid opens no
    -- stacks: the card has each one's own); short of the key or the next level's arrow (ReadMarks.drawUp, 5 x 4)
    local leftW = (kw > 0 and kw + T.px(2) or 0) + ((rs and rs.next and ZeD.ReadMarks.nextOn()) and T.px(9) or 0)
    local wtStr = weightText(item, stackInfo, f5, cw - T.px(6) - leftW)
    local wtw = ZeD.TM:MeasureStringX(f5, wtStr)
    -- (the chips fill from the window's surface token, at the see-through value like the rest of
    -- the window: no literal alpha; they are small and sit over the cell, so they are not claimed)
    local s1 = T.surf1
    self:drawRect(ax + cw - wtw - T.px(5), cy + T.px(1), wtw + T.px(4), GV.f5FH, s1.a or 1, s1.r, s1.g, s1.b)
    local th = T.accentText or T.text
    self:drawText(wtStr, ax + cw - wtw - T.px(3), cy + T.px(1), th.r, th.g, th.b, th.a or 1, f5)
    -- the count, bottom right (above the condition strip)
    if count > 1 then
        local cs = "(" .. count .. ")"   -- (Nov 15 2026, the director: counts read as the game's, "(3)", like the totals' weight)
        local f1 = T.fontF1
        local cw2 = ZeD.TM:MeasureStringX(f1, cs)
        local cy2 = math.min(cy + ch - GV.secFH - T.px(4), condTop - GV.secFH - T.px(1))
        self:drawRect(ax + cw - cw2 - T.px(5), cy2, cw2 + T.px(4), GV.secFH, s1.a or 1, s1.r, s1.g, s1.b)
        local tc = T.text
        self:drawText(cs, ax + cw - cw2 - T.px(3), cy2, tc.r, tc.g, tc.b, tc.a or 1, f1)
    end
    -- the belt key (measured above)
    if k then
        self:drawRect(ax, cy, kw, GV.f5FH, ac.a or 1, ac.r, ac.g, ac.b)
        local tc = T.textOnAccent
        self:drawText(k, ax + math.floor((kw - ZeD.TM:MeasureStringX(f5, k)) / 2), cy, tc.r, tc.g, tc.b, 1, f5)
        GV._beltW = kw
    else
        GV._beltW = 0
    end
    -- read: the square mark in the free corner, bottom left; a book for the next level: the small arrow top left (after a BELT key)
    if rs then
        local RM = ZeD.ReadMarks
        local ms = RM.markSize()
        RM.drawMark(self, ax + T.px(3), cy + ch - ms - T.px(3), rs.st)
        if rs.next and RM.nextOn() then RM.drawUp(self, ax + T.px(2) + (GV._beltW > 0 and GV._beltW + T.px(2) or 0), cy + T.px(2)) end
    end
    queueMark(self, item, nil, nil, 0, ax, cy, cw, ch)   -- (waiting to move: the bar along its foot)
    if over then
        local nm = item:getName() or "?"
        if count > 1 then nm = nm .. " (" .. count .. ")" end
        self._gridHintCand = { key = item, text = nm, read = rs, x = ax, y = cy, w = cw, h = ch }
        if ZeD.InvTip and not cuesOn() then   -- (the loot card, Alt the game's tooltip: punch list 146)
            local r = _tipRect
            r.x, r.y, r.w, r.h = ax, cy, cw, ch
            ZeD.InvTip.want(self, item, r, count, true)   -- (beside the cell, not over it)
        end
        if not condHov then ZeD.Help.set(self, ZeD.tr("UI_ZeD_Inv_RowHelpLoot", nm)) end   -- (on the strip: its condition)
    end
    -- the Filter: a matched cell takes an accent edge while text is typed (a picture has no letters to underline);
    -- one that does not match dims in place, unless the controller is on it
    local fr = self._fres
    if fr then
        if fr.match[item] then
            if fr.ql ~= "" then ZeD.Atoms.frame(self, ax, cy, cw, ch, T.accent) end
        elseif not fo then
            filterDim(self, ax, cy, cw, ch)
        end
    end
    self:addHitZone(item, ax, cy, cw, ch)
end

-- A list of items as cells from y; returns the y after them
local function drawGridList(self, GV, list, y)
    local n = 0
    local top = y + GV.gap
    for _, item in ipairs(list or {}) do
        if not GV.child[item] then
            local c, r = n % GV.cols, math.floor(n / GV.cols)
            drawGridCell(self, GV, item, GV.padX + c * (GV.cell + GV.gap), top + r * (GV.cell + GV.gap))
            n = n + 1
        end
    end
    return y + gridH(GV, n)
end

-- The column's heading: its buttons at the left, then the container's icon and
-- name; its weight over its item count on the right. (Header order, the director,
-- Nov 22 2026: the buttons and the icon and name switched places.)
-- (Kept out of renderItemList: in -debug the game's compiler keeps every
-- local a function declares, block or not, and stops at 200; renderItemList
-- runs close to that limit.)
local function drawColumnHeading(self, GV, xOff, colW, barH, hdrY, padX, secFH, f5FH)
    local ci = self._containerInfo
    if not ci then return end
    local T = ZeD.T
    local infoAreaH = hdrY - barH - (self._fbarH or 0)   -- (the Filter bar, while open, sits under the heading)
    local wtStr  = ci.stats or ""
    -- (Nov 15 2026, add-on hooks: an add-on's layout may word this line itself, "15 / 30 squares", GridLayout.lua)
    local cntStr = (GV.L and GV.L.headLine) or ci.count  or ""
    local wtW    = ZeD.TM:MeasureStringX(T.fontF1, wtStr)
    local cntW   = ZeD.TM:MeasureStringX(T.fontF5, cntStr)
    local gap    = T.px(2)
    local f4FH   = ZeD.TM:getFontHeight(T.fontF4)
    -- (Name first, Nov 22 2026: the buttons give way before the name does; headFit sets GV.headLevel)
    ZeD.InventoryRenderer.headFit(self, GV, colW, padX, infoAreaH, f4FH)
    -- (Grid width, the director, Nov 22 2026: a grid hugging its cells runs down to three; there the heading takes
    -- this same narrow step where one row would drop the weight, so the buttons, the name and the weight all stay)
    if (self._compactMode or ZeD.InventoryRenderer.headStacks(self, GV, colW, padX, wtW, f4FH, infoAreaH))
       and (f4FH + gap + secFH) <= infoAreaH then
        -- A column among several is narrow (about 210 px): the weight stack and the toggle on the
        -- right would leave the name three or four letters ("Sma..."). Here the name takes the whole line
        -- left of the buttons, and the weight and the item count sit under it.
        -- (Buttons right, the director, Nov 22 2026: the buttons at the heading's right end, the name and weight
        -- from its left edge)
        local togW = drawViewToggle(self, GV, xOff, padX, barH, infoAreaH, padX, true)   -- (their width, with a pad)
        drawViewToggle(self, GV, xOff, colW - togW, barH, infoAreaH, padX)
        local totalH = f4FH + gap + secFH
        local topY   = barH + math.floor((infoAreaH - totalH) / 2)
        local htc, ntc = T.toneHi, T.toneNorm
        local cx = padX
        local lineX = cx         -- (the weight line starts under the icon)
        if ci.texture then
            ZeD.Atoms.drawIcon(self, ci.texture, xOff + cx, topY, f4FH, 1, T.iconTone or T.iconWhite)
            cx = cx + f4FH + T.sp.iconGap
        end
        local maxNameW = colW - togW - cx - padX   -- (ends a pad short of the buttons)
        if maxNameW > 0 then
            local name = ZeD.Atoms.truncateText(ci.name or "", T.fontF4, maxNameW)
            self:drawText(name, xOff + cx, topY, ntc.r, ntc.g, ntc.b, ntc.a, T.fontF4)
        end
        -- the weight, then the count on the same baseline when it fits (the weight alone when not)
        local lineY = topY + f4FH + gap
        local lineW = colW - togW - padX * 2
        if wtW <= lineW then
            self:drawText(wtStr, xOff + lineX, lineY, htc.r, htc.g, htc.b, htc.a, T.fontF1)
            local cx2 = lineX + wtW + T.px(8)
            if cx2 + cntW <= lineX + lineW then
                self:drawText(cntStr, xOff + cx2, lineY + math.max(0, secFH - f5FH), ntc.r, ntc.g, ntc.b, ntc.a, T.fontF5)
            end
        end
        return
    end
    -- Right: 2-row stack — weight (F1 hi) over count (F5 norm). The stack stays inside the
    -- heading's own row: where both lines do not fit (large text) the count goes, then the
    -- weight (the window's foot line says both); centred, it would run up over the title
    -- bar's own weight
    local stackH = secFH + gap + f5FH
    -- (no count, an empty list: the weight alone, centred; QA's visual noise audit 2, Nov 20 2026)
    if cntStr == "" then cntStr, cntW, stackH = nil, 0, secFH end
    if stackH > infoAreaH then cntStr, cntW, stackH = nil, 0, secFH end
    if stackH > infoAreaH then wtStr, wtW, stackH = nil, 0, 0 end
    -- and where the stack would cut the container's name (a narrow window at Large text: "Invent..."), the count
    -- goes, then the weight; the title bar shows the weight and the foot line the count. The buttons' width is
    -- drawViewToggle's own, measured (Header order, Nov 22 2026: it counts every button now, Loot all and Pick
    -- all too; the old sum had only the Filter and the view button).
    local togW = drawViewToggle(self, GV, xOff, padX, barH, infoAreaH, padX, true)
    do
        local lead = padX + togW + (ci.texture and (f4FH + T.sp.iconGap) or 0)
        local need = lead + ZeD.TM:MeasureStringX(T.fontF4, ci.name or "") + padX * 2
        if cntStr and need + math.max(wtW, cntW) > colW then cntStr, cntW = nil, 0 end
        if wtStr and need + wtW > colW then wtStr, wtW = nil, 0 end
    end
    local stackW = math.max(wtW, cntW)
    local stackY = barH + math.max(0, math.floor((infoAreaH - stackH) / 2))
    local htc    = T.toneHi
    local ntc    = T.toneNorm
    -- (Buttons right, the director, Nov 22 2026: the stack sits left of the buttons, which end the heading)
    local stackR = colW - togW - padX   -- (the stack's right edge: a pad short of the buttons)
    if wtStr then self:drawText(wtStr, xOff + stackR - wtW, stackY, htc.r, htc.g, htc.b, htc.a, T.fontF1) end
    if cntStr then self:drawText(cntStr, xOff + stackR - cntW, stackY + secFH + gap, ntc.r, ntc.g, ntc.b, ntc.a, T.fontF5) end
    -- the buttons at the right end (the zones go in after the hit zones are cleared)
    drawViewToggle(self, GV, xOff, colW - togW, barH, infoAreaH, padX)
    -- then icon + name (F4 norm) from the heading's left edge, vertically centred in info area; the name truncates
    -- first, before the weight and the buttons
    local nameY = barH + math.floor((infoAreaH - f4FH) / 2)
    local cx    = padX
    if ci.texture then
        ZeD.Atoms.drawIcon(self, ci.texture, xOff + cx, nameY, f4FH, 1, T.iconTone or T.iconWhite)
        cx = cx + f4FH + T.sp.iconGap
    end
    local maxNameW = stackR - stackW - cx - padX
    if maxNameW > 0 then
        local name = ZeD.Atoms.truncateText(ci.name or "", T.fontF4, maxNameW)
        self:drawText(name, xOff + cx, nameY, ntc.r, ntc.g, ntc.b, ntc.a, T.fontF4)
    end
end

-- (Transfer in the footer, the director, Nov 22 2026: "Transfer buttons, always in the footer. Selection buttons,
-- always in the header.") A Loot column's foot: the band's surface along the column's bottom (self._ccH high, set by
-- ccLayout) and its own Take all at the right end, as a dialog's footer. Its stop and its press are the heading's
-- old Take all's ("view:lootall:<key>", lootAllOf takes from this column's container), so the pad finds it in the
-- column's own zone: Down past the column's last row lands on it (FocusManager's Focus._lootAllWrap, matched by key).
local _footOpts = {}
function ZeD.InventoryRenderer.drawColumnFoot(self, GV, xOff, colW)
    if not (GV and GV.key) then return end
    local T, M, A = ZeD.T, ZeD.Molecules, ZeD.Atoms
    local CTL = ZeD.ContainerControls
    local h = self._ccH
    local top = self:getHeight() - h
    ZeD.Surface.fill(self, xOff, top, colW, h, "surf2")
    A.drawDividerH(self, xOff, top, colW, true)
    local word = CTL.lootAllLabel()
    local padX = T.px(CTL.PAD_X or 10)
    local bw = T.buttonH
    local lw = math.min(M.buttonW(word), colW - padX * 2)
    local tx, ty = xOff + colW - padX - lw, top + math.floor((h - bw) / 2)
    local id = "view:lootall:" .. GV.key
    local o = _footOpts
    o.active, o.hover = false, A.mouseIn(self, tx, ty, lw, bw)
    o.disabled = not CTL.headLootEnabled(self)
    o.focus, o.hint, o.id, o.help = gpFocusedToggle(id, ZeD.playerNumOf(self)), word, id, word
    M.drawButton(self, tx, ty, lw, bw, word, "default", false, nil, o)
    GV.toggles[#GV.toggles + 1] = { x = tx, y = ty, w = lw, h = bw, view = "lootall", key = GV.key, id = id }
end

-- (Name first, QA's Lite finding, Nov 22 2026; the director's rule "name always wins") How far a heading's buttons give
-- way so its name keeps at least its first three letters and the dots: GV.headLevel, the first level that fits (0 all
-- as they are; 1 Lite's words drawn as the pictures, as in Full; 2 the view flip goes, the least used, R3 still
-- flips; 3 the Filter goes too; 4 Pick all goes too, the window's own Pick all key still picks). The weight and
-- count give way after that, by drawColumnHeading's own rule. Measures only (five widths at most).
function ZeD.InventoryRenderer.headFit(self, GV, colW, padX, areaH, f4FH)
    GV.headLevel = 0
    local ci = self._containerInfo
    if not (ci and GV.key) then return end
    local T, tm = ZeD.T, ZeD.TM
    local name = ci.name or ""
    local nameMin = math.min(tm:MeasureStringX(T.fontF4, name), tm:MeasureStringX(T.fontF4, name:sub(1, 3) .. "..."))
    local lead = padX + (ci.texture and (f4FH + T.sp.iconGap) or 0) + nameMin + padX * 2   -- (a pad each side of the name)
    for lvl = 0, 4 do
        GV.headLevel = lvl
        if lead + drawViewToggle(self, GV, 0, padX, 0, areaH, padX, true) <= colW then return end
    end
end

-- (Grid width, the director, Nov 22 2026) does a grid's heading on one row lose its weight to the name (the test
-- drawColumnHeading's one-row layout makes below)? Then it takes the stacked step, the name over the weight, as a
-- column among several does. A list keeps its one row as before. wtW: the weight's width (0: none).
function ZeD.InventoryRenderer.headStacks(self, GV, colW, padX, wtW, f4FH, areaH)
    if not (GV and GV.on) or (wtW or 0) <= 0 then return false end
    local T, ci = ZeD.T, self._containerInfo
    local togW = drawViewToggle(self, GV, 0, padX, 0, areaH, padX, true)   -- (measure only: draws nothing)
    local lead = padX + togW + (ci.texture and (f4FH + T.sp.iconGap) or 0)
    return lead + ZeD.TM:MeasureStringX(T.fontF4, ci.name or "") + padX * 2 + wtW > colW
end

-- The grid by category: each category's heading (as the list's: fold on a
-- click) and its cells. Returns the y after them.
-- A category's row ("v Weapons (4)", the library's category row: the triangle,
-- F1 sentence case, the count): a press folds it. hover = the pointer is on it.
local _catOpts = {}
local function drawCatRow(self, x, y, w, h, cat, n, isClosed, hover, inset)
    local o = _catOpts
    o.hover, o.h, o.inset = hover, h, inset
    o.focus = gpFocusedCat(cat, self._inventory, ZeD.playerNumOf(self))   -- (punch list 256: the pad's stop)
    if o.focus then o.hover = false end
    ZeD.Molecules.drawCategoryRow(self, x, y, w, ZeD.InventoryRenderer.catLabel(cat), n, not isClosed, o)
    -- (while the Filter narrows, a category with nothing matching dims with its rows)
    local fr = self._fres
    if fr and (fr.catMatched[cat] or 0) == 0 then filterDim(self, x, y, w, h) end
    if hover then ZeD.Help.set(self, ZeD.tr(isClosed and "UI_ZeD_Inv_CatOpenHelp" or "UI_ZeD_Inv_CatFoldHelp")) end
end

local function drawGridGroups(self, GV, catOrder, groups, collapsed, stackedGroups, y, scrollX, catHdrH)
    local xOff = GV.xOff
    local T = ZeD.T
    for _, cat in ipairs(catOrder) do
        local isClosed = collapsed[cat]
        if GV.ymap then GV.ymap["cat:" .. cat] = y end   -- (the heading's place: its pad stop, punch list 256)
        if y + catHdrH > GV.top and y < GV.h then
            local hover = GV.mouseIn and not cuesOn() and GV.my >= y and GV.my < y + catHdrH and GV.lmx < scrollX
            drawCatRow(self, xOff, y, scrollX, catHdrH, cat, #groups[cat], isClosed, hover, GV.padX + T.px(2))
            self:addHitZone("cat:" .. cat, xOff, y, scrollX, catHdrH)
        end
        y = y + catHdrH
        if not isClosed then y = drawGridList(self, GV, stackedGroups[cat], y) end
    end
    return y
end

-- the view button's hit zones (after the column clears its zones)
local function addToggleZones(self, GV)
    for _, r in ipairs(GV.toggles) do self:addHitZone(r.id, r.x, r.y, r.w, r.h) end
end

-- the grid's column bar: the list's own sort keys and labels (same state, same
-- "hdr:<key>" zones, same underline), laid end to end from the left instead of
-- over columns the grid doesn't have. Same row shape as renderItemList's colDefs:
-- {label, key, drawX, hitX, hitW} in column-local x. A key that no longer fits
-- is left off (Name always stays).
local function gridSortDefs(padX, colW)
    local T = ZeD.T
    local keys = {
        { "UI_ZeD_Inv_ColName", "name" }, { "UI_ZeD_Inv_ColCat", "cat" },
        { "UI_ZeD_Inv_ColCond", "cond" }, { "UI_ZeD_Inv_ColWt", "wt" },
    }
    local defs, x = {}, 0
    for i, k in ipairs(keys) do
        local label = ZeD.tr(k[1])
        local lead = (i == 1) and padX or math.floor(padX / 2)   -- Name lines up with the first cell
        local w = ZeD.TM:MeasureStringX(T.sortFont, label) + lead + padX   -- (row 2's font)
        if i > 1 and x + w > colW then break end
        defs[#defs + 1] = { label, k[2], x + lead, x, math.min(w, colW - x) }
        x = x + w
    end
    return defs
end

-- A readable item's hover card, the library's detail
-- card: its name, its read status in the game's own words, and the next level a
-- skill book suits. Asked of the window's overlay, which shows it after the
-- shared pause, pointing at the item.
local function requestReadCard(self, hc)
    local rs = hc.read
    local lines = {}
    for _, l in ipairs(rs.lines or {}) do lines[#lines + 1] = l end
    if rs.next and ZeD.ReadMarks.nextOn() then lines[#lines + 1] = ZeD.tr("UI_ZeD_Read_NextFor", rs.next) end
    ZeD.Atoms.requestDetailCard(ZeD.Atoms.windowOf(self), hc.key, { title = hc.text, lines = lines }, self, hc.x and hc or nil)
    self._readHintAt = getTimestampMs()   -- (when the card was last asked for)
end

-- A list row's read mark (ReadMarks.lua): in the COND column a square mark and a word, or (the column hidden) the
-- same after the name, in readTagW's width (colW nil: the mark alone); the mark's shape (hollow, half, full) and colour
-- carry the status. Returns nothing.
local function drawReadCond(self, rs, x, y, rowH, colW, padX, focusTxt)
    local T, tm = ZeD.T, ZeD.TM
    local RM = ZeD.ReadMarks
    local d = RM.markSize()
    RM.drawMark(self, x, y + math.floor((rowH - d) / 2), rs.st)
    if not colW then return end
    local f3 = T.fontF3
    local tx = x + d + T.px(5)
    local room = colW - (tx - x) - math.floor(padX / 2)
    local word = rs.word
    if rs.short and tm:MeasureStringX(f3, word) > room then word = rs.short end
    if tm:MeasureStringX(f3, word) > room then return end   -- (no room for a word: the dot alone; the hover has it)
    local c = focusTxt or T.text
    self:drawText(word, tx, y + math.floor((rowH - tm:getFontHeight(f3)) / 2), c.r, c.g, c.b, c.a or 1, f3)
end
ZeD.InventoryRenderer._drawReadCond = drawReadCond

-- The read tag after a name, for a row whose Status column is hidden: the mark, its lead and its word (the short
-- word when the status has one, "30%"), so the tag keeps its word at Large text too (punch list 175f(1): it was
-- the bare square). Returns its width in px; drawReadCond draws it given this width plus half the pad.
local function readTagW(rs)
    local T = ZeD.T
    return ZeD.ReadMarks.markSize() + T.px(5) + ZeD.TM:MeasureStringX(T.fontF3, rs.short or rs.word or "")
end
ZeD.InventoryRenderer._readTagW = readTagW

-- Which of the Category and Status columns a list row keeps, given the room past the name's least width (room)
-- and the two columns' widths. (List columns, the director, Nov 22 2026: "Name always wins. Weight comes in second
-- place. Category comes in third place. And if there's room, it shows condition.") The name and the weight always
-- stay; Category shows when it fits; Status only after Category, and only where the name still keeps condName more
-- than its least width (COND_NAME_U), so the usual 372-unit list shows the category, not the bar. Read marks no
-- longer win Status the room: with Status hidden the mark and its word sit after the name (readTagW), as at
-- Large text. Returns showCond, showCat.
local function fitColumns(room, catW, condW, condName)
    if catW > room then return false, false end
    return catW + condW + (condName or 0) <= room, true
end
ZeD.InventoryRenderer._fitColumns = fitColumns
-- the least width (design units) a name keeps beside the Status column: past MIN_NAME's 100 (List columns, the
-- director, Nov 22 2026)
ZeD.InventoryRenderer.COND_NAME_U = 140

-- A grid cell names its item in a hint, a readable row or cell shows its read
-- card: the library's hover boxes, asked of the window's overlay (which keeps
-- the one pause and points them at the cell, over everything)
local function drawGridHint(self, GV, xOff, colW, contentTop)
    local hc = self._gridHintCand
    if not hc then return end
    -- (the game's tooltip is up for it: it names the item, so no second box; punch list 146)
    if ZeD.InvTip and ZeD.InvTip.wantedBy(self, hc.key) then return end
    if hc.read then return requestReadCard(self, hc) end
    ZeD.Atoms.requestHint(ZeD.Atoms.windowOf(self), hc.key, hc.text, self, hc.x and hc or nil)
end

-- ============================================================================
-- LIST MODEL
-- A list's rows: its categories, the items sorted in each, and the stacks.
-- Built only when the container changes (its item count or weight, the sort,
-- the folds, what the player holds), at once after a container event or a
-- drop (dirtyModels), and about once a second anyway for what changes nothing
-- of those (a renamed item, a worn-down condition); each column on its own
-- beat (its phase), so open columns do not rebuild on the same frame.
-- Rebuilding and re-sorting a whole list in every open column every frame would
-- be wasted work, so the model is kept until one of the above changes.
-- (Kept out of renderItemList, which sits near Kahlua's 200-local limit.)
-- ============================================================================

local MODEL_REFRESH_MS = 1000   -- the time-based rebuild, ms (each column on its own phase)
local MODEL_EVENT_MS   = 500    -- an event's rebuild comes at most this long after the last build (a storm of events)
local _modelGen, _modelPhases = 0, 0

-- every list model rebuilds on its next draw: a container's things changed
-- (the game's OnContainerUpdate, a player's clothes put on or off), a drop moved things
function ZeD.InventoryRenderer.dirtyModels()
    _modelGen = _modelGen + 1
end
-- the number dirtyModels moves: the container buttons rebuild when it does
-- (ContainerControls; QA's speed audit, Nov 20 2026)
function ZeD.InventoryRenderer.modelGen() return _modelGen end
if Events then
    if Events.OnContainerUpdate then Events.OnContainerUpdate.Add(ZeD.InventoryRenderer.dirtyModels) end
    if Events.OnClothingUpdated then
        Events.OnClothingUpdated.Add(function(chr)
            -- (only a player on this machine: zombies dress through this event too)
            local ok, mine = pcall(function() return instanceof(chr, "IsoPlayer") and chr:isLocalPlayer() end)
            if ok and mine then ZeD.InventoryRenderer.dirtyModels() end
        end)
    end
end

-- x mod m for m > 0 on any size of number (Kahlua's % breaks past 2^31; the clock is past it)
local function modPos(x, m)
    return x - math.floor(x / m) * m
end

-- when a model built now rebuilds by time: the next tick of the column's own
-- one-second beat that is at least half a second away (0.5-1.5 s, 1 s apart after)
local function modelDue(now, phase)
    local due = now + MODEL_REFRESH_MS - modPos(now - phase, MODEL_REFRESH_MS)
    if due - now < MODEL_REFRESH_MS / 2 then due = due + MODEL_REFRESH_MS end
    return due
end

-- the folds that are set in a fold table, as one string ("" when none)
local function foldKey(t)
    if not t then return "" end
    local s = ""
    for k, v in pairs(t) do
        if v then s = s .. tostring(k) .. "\n" end
    end
    return s
end

-- equipped or worn by the player (hidden from their own list: the Equip tab shows them)
local function heldByPlayer(playerObj, item)
    local okE, eq = pcall(function() return item:isEquipped() end)
    if okE and eq then return true end
    local okP, peq = pcall(function() return playerObj:isEquipped(item) end)
    return okP and peq or false
end

-- The same answer for a whole list at once: what the player wears and holds,
-- asked once per build. item:isEquipped() asks the character whose container
-- holds the item, playerObj:isEquipped(item) asks that player's worn items and
-- two hands (IsoGameCharacter.isEquipped, 42.21; both compare the very object).
-- So while the container is the player's own (its parent is the player, or
-- nothing) one set answers both. nil: ask each item itself (heldByPlayer).
local function heldSet(playerObj, inv)
    local ok, set = pcall(function()
        local par = inv:getParent()
        if par ~= nil and par ~= playerObj then return nil end
        local s = {}
        local worn = playerObj:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:get(i):getItem()
            if it then s[it] = true end
        end
        local ph, sh = playerObj:getPrimaryHandItem(), playerObj:getSecondaryHandItem()
        if ph then s[ph] = true end
        if sh then s[sh] = true end
        return s
    end)
    if ok then return set end
    return nil
end

-- DECORATE-SORT-UNDECORATE. Each item's sort keys are asked once per build
-- (decorate), the list is sorted on those, then put back as items (undecorate).
-- The comparators answer every pair exactly as makeSorter's do (the same keys,
-- the same tests, name the tiebreak; Sort by Name compares the lowered name),
-- so table.sort makes the same moves and ties land where they always did.
-- makeSorter asked the game for 2-4 things inside every comparison.
local function keyedNameTie(a, b) return a.nm < b.nm end
local KEYED = {
    name = {
        [true]  = function(a, b) return a.lo < b.lo end,
        [false] = function(a, b) return a.lo > b.lo end,
    },
    cat = {
        [true]  = function(a, b) if a.k ~= b.k then return a.k < b.k end return keyedNameTie(a, b) end,
        [false] = function(a, b) if a.k ~= b.k then return a.k > b.k end return keyedNameTie(a, b) end,
    },
    cond = {
        [true]  = function(a, b) if a.k ~= b.k then return a.k < b.k end return keyedNameTie(a, b) end,
        [false] = function(a, b) if a.k ~= b.k then return a.k > b.k end return keyedNameTie(a, b) end,
    },
    wt = {
        [true]  = function(a, b) if a.k ~= b.k then return a.k < b.k end return keyedNameTie(a, b) end,
        [false] = function(a, b) if a.k ~= b.k then return a.k > b.k end return keyedNameTie(a, b) end,
    },
}

-- one item's keys for a sort column (as makeSorter reads them)
local function sortRec(item, col)
    if col == "name" then
        return { it = item, lo = string.lower(item:getName() or "") }
    end
    local k
    if col == "cat" then
        k = ZeD.InventoryRenderer.catKey(item)
    elseif col == "cond" then
        k = ZeD.ItemMeter.sortKey(item)   -- (getCondPct: the column's bar)
    else
        k = item:getUnequippedWeight()
    end
    return { it = item, k = k, nm = item:getName() or "" }
end

-- sorts list in place, in the order table.sort(list, makeSorter(col, asc)) gives
local function sortItems(list, col, asc)
    local n = #list
    if n < 2 then return end   -- (nothing to compare: table.sort asks nothing either)
    if col ~= "name" and col ~= "cat" and col ~= "cond" then col = "wt" end   -- (makeSorter's else)
    local recs = {}
    for i = 1, n do recs[i] = sortRec(list[i], col) end
    table.sort(recs, KEYED[col][asc and true or false])
    for i = 1, n do list[i] = recs[i].it end
end

local NO_OPEN = {}   -- (no stack open: the grid's model, punch list 245)

local function buildItemModel(inv, playerObj, isPlayerInv, sortCol, sortAsc, collapsed, expandedStacks)
    local groups, catOrder, flatItems = {}, {}, {}
    local catOf = {}   -- item -> its category key (the rows draw it every frame)
    local items = inv and inv:getItems()
    -- a mod's gate (ContainerGates.lua): only the things it lets show (a search's finds so far)
    local gate = ZeD.ContainerGates.get(inv, playerObj)
    -- what the player wears and holds, once for the list (an item held elsewhere: asked item by item)
    local held = isPlayerInv and items and heldSet(playerObj, inv) or nil
    local nShown = 0   -- (the things the rows show: the heading and the help line count these)
    -- (KISS #11) with the setting on, what is worn or held stays in the list, in a group of its own at the end (the director, Nov 23 2026)
    local wornOn = isPlayerInv and ZeD.InventoryRenderer.wornListed()
    local wornRows = {}   -- (the worn and held things, for the flat lists)
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local shown = item and not item:isHidden()
            local isWorn = false
            if shown and isPlayerInv then
                if held and item:getContainer() == inv then isWorn = held[item] and true or false
                else isWorn = heldByPlayer(playerObj, item) end
                if isWorn and not wornOn then shown = false end   -- (the Equipment tab shows it)
            end
            if shown and (not gate or ZeD.ContainerGates.keeps(gate, item)) then
                -- a mod's group first (ContainerGroups.lua: a folder the player filed it in), else its category
                local cat = ZeD.ContainerGroups.groupOf(item, inv, playerObj, isPlayerInv) or ZeD.InventoryRenderer.catKey(item)
                if isWorn then cat = ZeD.InventoryRenderer.WORN_KEY end   -- (KISS #11)
                catOf[item] = cat
                -- the game's list ages every food it draws, and in single player nothing else does: a steak in a
                -- freezer never froze while only this list showed it. Once per item per model build (about every
                -- second per visible column), as vanilla's refreshContainer does (QA B5-9)
                if instanceof and instanceof(item, "Food") then pcall(item.updateAge, item) end
                if not groups[cat] then
                    groups[cat] = {}
                    catOrder[#catOrder + 1] = cat
                end
                groups[cat][#groups[cat] + 1] = item
                if isWorn then wornRows[#wornRows + 1] = item end   -- (KISS #11)
                nShown = nShown + 1
            end
        end
    end
    -- a mod's groups listed even with nothing in them (ContainerGroups.lua: a folder with
    -- nothing filed yet is a group row of its own, count 0, as an empty container); the
    -- grouped view only (the other sorts are one flat list)
    if sortCol == "cat" then
        for _, key in ipairs(ZeD.ContainerGroups.keys(inv, playerObj, isPlayerInv)) do
            if not groups[key] then
                groups[key] = {}
                catOrder[#catOrder + 1] = key
            end
        end
    end

    local useGroups = (sortCol == "cat")   -- only Sort by Category has category headers; the rest is one flat list
    local stacks = {}          -- rep item → stack info (a closed stack's row, or a single thing's)
    local childParent = {}     -- child item → stack info
    -- (Nov 15 2026, punch list 245) an open stack's header is the stack, no item's row: heads lists them in order,
    -- headOf names the one drawn just above its first item's row
    local heads, headOf = {}, {}

    -- Build one stack per (cat, fullType); emit representative + optional
    -- children into flatItems in render order. Expanded stacks show their
    -- child rows indented beneath the header, as vanilla's inventory does.
    local function emitStacks(itemList)
        local byType = {}
        local ordered = {}
        for _, item in ipairs(itemList) do
            local ft = item.getFullType and item:getFullType() or tostring(item)
            if not byType[ft] then
                byType[ft] = { rep = item, items = { item }, count = 1, key = ft }
                ordered[#ordered + 1] = byType[ft]
            else
                local s = byType[ft]
                s.items[#s.items + 1] = item
                s.count = s.count + 1
            end
        end
        -- sorted by weight, a stack goes by its total, the number its row shows (as vanilla's inventory sorts)
        if sortCol == "wt" then
            -- (each stack's total and name asked once, not in every comparison)
            local snm = {}
            for _, s in ipairs(ordered) do s.wt = stackWeight(s); snm[s] = s.rep:getName() or "" end
            table.sort(ordered, function(a, b)
                if a.wt ~= b.wt then if sortAsc then return a.wt < b.wt end return a.wt > b.wt end
                return snm[a] < snm[b]
            end)
        end
        for _, s in ipairs(ordered) do
            if s.count > 1 and expandedStacks[s.key] then
                -- (Nov 15 2026, punch list 245: the header row stood for the first item, so the first flyer of a stack
                -- had no row of its own while the stack was open. Now every item has its row under the header, the
                -- first too, as vanilla's pane lists them; the header is drawn from heads, not from flatItems)
                heads[#heads + 1] = s
                headOf[s.items[1]] = s
                for ci = 1, #s.items do
                    flatItems[#flatItems + 1] = s.items[ci]
                    childParent[s.items[ci]] = s
                end
            else
                flatItems[#flatItems + 1] = s.rep
                stacks[s.rep] = s
            end
        end
    end

    -- Stacked per-category iteration list for the useGroups draw path.
    -- The draw loop iterates per-cat; without this the original unstacked
    -- groups[cat] would be used, bypassing stacking entirely.
    local stackedGroups = {}
    local catRowCount = {}  -- cat → rendered row count (stacks + expanded children)
    if useGroups then
        -- (a mod's ranked groups first, ContainerGroups.lua; then the categories, either way)
        ZeD.ContainerGroups.sortKeys(catOrder, not (sortCol == "cat" and not sortAsc))
        -- (KISS #11) the worn and held group stands last, whichever way the rest is sorted: what is in the pockets
        -- before what is worn, as the game's list does (its sorts put equipped things last; the director, Nov 23 2026:
        -- "you want to access the things that are in your pockets before the things that you're wearing")
        for ci = 1, #catOrder - 1 do
            if catOrder[ci] == ZeD.InventoryRenderer.WORN_KEY then
                table.remove(catOrder, ci)
                catOrder[#catOrder + 1] = ZeD.InventoryRenderer.WORN_KEY
                break
            end
        end
        for _, cat in ipairs(catOrder) do
            sortItems(groups[cat], sortCol, sortAsc)
            if not (collapsed and collapsed[cat]) then
                local before, headsBefore = #flatItems, #heads
                emitStacks(groups[cat])
                catRowCount[cat] = #flatItems - before + #heads - headsBefore   -- (an open stack's header is a row too)
                -- Snapshot the stacked rows for this category so the draw
                -- loop can iterate per-cat without using the unstacked source.
                local catRows = {}
                for i = before + 1, #flatItems do
                    catRows[#catRows + 1] = flatItems[i]
                end
                stackedGroups[cat] = catRows
            else
                catRowCount[cat] = 0
                stackedGroups[cat] = {}
            end
        end
    else
        -- Non-grouped (sortCol = cond/wt): stack across all items.
        local all = {}
        for _, cat in ipairs(catOrder) do
            for _, item in ipairs(groups[cat]) do
                if catOf[item] ~= ZeD.InventoryRenderer.WORN_KEY then all[#all + 1] = item end   -- (KISS #11: worn ones last, below)
            end
        end
        sortItems(all, sortCol, sortAsc)
        emitStacks(all)
        -- (KISS #11) what is worn or held ends the flat list, sorted among themselves (as the game's sorts put
        -- equipped things last: the director, Nov 23 2026)
        if #wornRows > 0 then
            sortItems(wornRows, sortCol, sortAsc)
            emitStacks(wornRows)
        end
    end

    return {
        groups = groups, catOrder = catOrder, flatItems = flatItems, useGroups = useGroups,
        stacks = stacks, childParent = childParent, stackedGroups = stackedGroups,
        catRowCount = catRowCount, catOf = catOf, nShown = nShown,
        heads = heads, headOf = headOf,
    }
end

-- The list model for this column's container: the cached one while nothing
-- it is built from has changed, a fresh one otherwise.
local function itemModel(self, inv, playerObj, isPlayerInv, sortCol, sortAsc, collapsed, expandedStacks)
    local items = inv and inv:getItems()
    local n = items and items:size() or -1
    local w = inv and inv:getCapacityWeight() or -1
    local ph, sh = nil, nil
    local wo = false   -- (KISS #11: the Worn and held choice and how many things are worn; the list is built again when they change)
    if isPlayerInv then
        ph, sh = playerObj:getPrimaryHandItem(), playerObj:getSecondaryHandItem()
        local okW, wn = pcall(function() return playerObj:getWornItems():size() end)
        wo = tostring(ZeD.InventoryRenderer.wornListed()) .. ":" .. tostring(okW and wn or 0)
    end
    local cf, ef = foldKey(collapsed), foldKey(expandedStacks)
    -- a mod's gate: its signature changes as it lets more show (ContainerGates.lua)
    local gate = ZeD.ContainerGates.get(inv, playerObj)
    local gs = gate and (gate.sig or true) or false
    -- a mod's groups: their signature changes as things are filed (ContainerGroups.lua)
    local gg = ZeD.ContainerGroups.sig(inv, playerObj, isPlayerInv)
    local cache = self._modelCache
    if not cache then
        cache = {}
        self._modelCache, self._modelCacheN = cache, 0
    end
    local key = inv or cache   -- (no container: one shared empty model)
    local c = cache[key]
    -- this column's beat (MODEL_REFRESH_MS apart, each new column a little later than the last)
    if not self._modelPhase then
        _modelPhases = _modelPhases + 1
        self._modelPhase = modPos(_modelPhases * 397, MODEL_REFRESH_MS)
    end
    local now = getTimestampMs()
    -- kept: not due by time (and the clock not set back), no event since it was built (or one
    -- within MODEL_EVENT_MS of the last build: it waits that long), nothing it is built from changed
    if c and now < c.due and now >= c.t and (c.gen == _modelGen or now - c.t < MODEL_EVENT_MS)
       and c.n == n and c.w == w and c.sortCol == sortCol
       and c.sortAsc == sortAsc and c.cf == cf and c.ef == ef and c.ph == ph and c.sh == sh and c.wo == wo
       and c.isP == isPlayerInv and c.gs == gs and c.gg == gg then
        return c.m
    end
    if not c then
        -- containers come and go as the player walks: start over past 24
        self._modelCacheN = (self._modelCacheN or 0) + 1
        if self._modelCacheN > 24 then
            cache = {}
            self._modelCache, self._modelCacheN = cache, 1
            key = inv or cache
        end
        c = {}
        cache[key] = c
    end
    c.t, c.due, c.gen = now, modelDue(now, self._modelPhase), _modelGen
    c.n, c.w, c.sortCol, c.sortAsc = n, w, sortCol, sortAsc
    c.cf, c.ef, c.ph, c.sh, c.isP, c.gs, c.gg, c.wo = cf, ef, ph, sh, isPlayerInv, gs, gg, wo
    c.m = buildItemModel(inv, playerObj, isPlayerInv, sortCol, sortAsc, collapsed, expandedStacks)
    return c.m
end

--- How many things panel's list of inv shows: the count its heading and its help line give, so they agree with the
--- rows. What the player wears and holds leaves their own list (the Equip tab shows it), so a bare character's list
--- is empty though the glasses on their face are in the container. From the list's last model (one frame behind at
--- most); before the list has drawn, the container's own count (ContainerGates.count).
function ZeD.InventoryRenderer.shownCount(panel, inv, playerObj)
    local cache = panel and inv and panel._modelCache
    local c = cache and cache[inv]
    if c and c.m and c.m.nShown then return c.m.nShown end
    return ZeD.ContainerGates.count(inv, playerObj)
end

--- How many things the list of inv would show, worked out on its own (no list needed): the number a rolled-up
--- inventory tab gives, which must match the heading when it rolls down. Same filter as buildItemModel: not hidden,
--- not worn or held (the player's own main inventory only), and what a mod's gate keeps. The list stops drawing
--- while its side is rolled, so shownCount's model would be stale there; this counts itself, at most every 250 ms
--- and again at once when the item count, worn count, hands or the gate change (QA B10-5).
function ZeD.InventoryRenderer.liveCount(inv, playerObj)
    local items = inv and inv:getItems()
    if not items then return 0 end
    local R = ZeD.InventoryRenderer
    local cache = R._liveCache
    if not cache then cache = {}; R._liveCache = cache; R._liveCacheN = 0 end
    local gate = ZeD.ContainerGates.get(inv, playerObj)
    local isP = playerObj and inv == playerObj:getInventory() or false
    local size = items:size()
    local wornN, ph, sh = 0, nil, nil
    if isP then
        local okW, wn = pcall(function() return playerObj:getWornItems():size() end)
        wornN = okW and wn or 0
        ph, sh = playerObj:getPrimaryHandItem(), playerObj:getSecondaryHandItem()
    end
    local sig = gate and gate.sig or nil
    local now = getTimestampMs()
    local c = cache[inv]
    if c and c.size == size and c.wornN == wornN and c.ph == ph and c.sh == sh and c.sig == sig and now - c.t < 250 then
        return c.n
    end
    local held = isP and heldSet(playerObj, inv) or nil
    local n = 0
    for i = 0, size - 1 do
        local item = items:get(i)
        local shown = item and not item:isHidden()
        if shown and isP and not ZeD.InventoryRenderer.wornListed() then   -- (KISS #11: listed, the worn count too)
            if held and item:getContainer() == inv then shown = not held[item]
            else shown = not heldByPlayer(playerObj, item) end
        end
        if shown and (not gate or ZeD.ContainerGates.keeps(gate, item)) then n = n + 1 end
    end
    if not c then
        -- (a handful of containers at a time: start over rather than keep every one ever seen)
        if R._liveCacheN >= 64 then cache = {}; R._liveCache = cache; R._liveCacheN = 0 end
        c = {}
        cache[inv] = c
        R._liveCacheN = R._liveCacheN + 1
    end
    c.size, c.wornN, c.ph, c.sh, c.sig, c.t, c.n = size, wornN, ph, sh, sig, now, n
    return n
end

-- ============================================================================
-- ROW PARTS (kept out of renderItemList, which sits near Kahlua's local limit)
-- ============================================================================

-- A list row's states, under its words, in panel coords: selected (the
-- T.selectionA wash; faded while a drag carries it), else the pointer's hover
-- (also the rows a pointed-at Same type button would move), then the
-- controller's focus mark on the one row that is both this panel's seed and the
-- live focused element. pointed = the pointer is on the row.
-- @return true when the row's words switch to T.textOnFocus
local function rowStates(self, item, isSelected, x, y, w, rowH, pointed)
    local T = ZeD.T
    local hover = pointed and not cuesOn()
    if isSelected then
        local ac = T.accent
        self:drawRect(x, y, w, rowH, T.selectionA, ac.r, ac.g, ac.b)
        if self._drag and self._drag:isActive() then
            local s1 = T.surf1
            self:drawRect(x, y, w, rowH, 0.4, s1.r, s1.g, s1.b)
        end
    elseif hover or (self._ccMarks and ccMarked(self, item)) then
        local hv = T.hover
        self:drawRect(x, y, w, rowH, hv.a, hv.r, hv.g, hv.b)
    end
    local si = self._stacks and self._stacks[item]
    if hover then
        ZeD.Help.set(self, ZeD.tr("UI_ZeD_Inv_RowHelpLoot", item:getName() or ""))
        -- the loot card at once, by the pointer; Alt: the game's tooltip (punch list 146: ZeD_InvTip.lua)
        -- (Nov 15 2026, punch list 244: a stack's count too, so the card's title reads as the row, "Rag x3"; the
        -- pointer's card said "Rag" while the pad's said the count)
        if ZeD.InvTip then
            local r = _tipRect
            r.x, r.y, r.w, r.h = x, y, w, rowH
            ZeD.InvTip.want(self, item, r, si and si.count or 1)
        end
    end
    if item ~= self._gpFocusedRowItem then return false end
    local fo = gpFocusedItem(item, ZeD.playerNumOf(self))
    if not fo then return false end
    padTip(self, item, x, y, w, rowH, si and si.count or 1)
    return ZeD.Focus.mark(self, x, y, w, rowH, fo) and true or false
end

-- A tag after a row's name (Next level, Belt 2): the library's tag (no box), its status square (mark) before the
-- word in the secondary ink, centered in the row. The square makes it read as a tag: bare, the word read as more of
-- the item's name.
local _rowTagOpts = {}
local function rowTag(self, x, y, rowH, text, focusTxt, mark)
    local T = ZeD.T
    _rowTagOpts.textColor = focusTxt or T.textDim
    ZeD.Molecules.drawTag(self, x, y + math.floor((rowH - T.px(16)) / 2), text, mark, _rowTagOpts)
end

-- A row's bar in the COND / AMT column: the framed strip (ZeD.Atoms.drawFillBar) at the list rows' compact height,
-- centred in the row. One bar an item (the director, Nov 11 2026: "condition is not always condition. Sometimes it's
-- how much is in something"; ItemMeter.lua, punch list 152): something that wears, its condition in the status
-- bar's five segments and colours; something that holds a liquid or runs down, how full it is in the fill bar's ten
-- (a liquid blue, the rest a light neutral); nothing for what neither wears nor holds.
-- Returns true when it drew a bar (a row with none lends the cell's room to its category's words).
local function rowCondition(self, item, x, y, w, rowH, stackInfo)
    if w <= 0 then return false end
    local IM = ZeD.ItemMeter
    -- (a stack's head: its emptiest item's bar, punch list 162)
    local kind, f = IM.ofStack(item, stackInfo and stackInfo.count > 1 and stackInfo.items or nil)
    if kind == nil or kind == "hidden" then return false end
    local A = ZeD.Atoms
    local fc, graduated = IM.style(kind)
    local ch = (A.fillBarCompactH and A.fillBarCompactH()) or ZeD.T.px(8)
    A.drawFillBar(self, x, y + math.floor((rowH - ch) / 2), w, f, graduated, fc, ch, IM.label(kind))
    return true
end

local function renderItemList(self)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    -- one list with its heading: the frame's Filter starts here (side by side, renderMultiColumnContent starts it)
    if not self._compactMode then filterFrame(self, false) end

    -- Multi-column: X offset and column width
    local xOff = self._renderXOffset or 0
    local colW = self._renderW or self:getWidth()
    local h    = self:getHeight()

    -- Drawing wrappers that apply xOff to all X coordinates
    local function dR(x, y, w, ht, a, r, g, b)
        self:drawRect(xOff + x, y, w, ht, a, r, g, b)
    end
    local function dRB(x, y, w, ht, a, r, g, b)
        self:drawRectBorder(xOff + x, y, w, ht, a, r, g, b)
    end
    local function dT(str, x, y, r, g, b, a, font)
        self:drawText(str, xOff + x, y, r, g, b, a, font)
    end
    local function dTS(tex, x, y, w, ht, a, r, g, b)
        self:drawTextureScaledAspect(tex, xOff + x, y, w, ht, a, r, g, b)
    end
    local function hZ(id, x, y, w, ht)
        self:addHitZone(id, xOff + x, y, w, ht)
    end
    local function aSec(str, x, y, c)
        A.drawSecondary(self, str, xOff + x, y, c)
    end
    local function aDiv(x, y, w, strong)
        A.drawDividerH(self, xOff + x, y, w, strong)
    end
    local function aIcon(tex, x, y, sz, al, c)
        A.drawIcon(self, tex, xOff + x, y, sz, al, c)
    end

    -- --------------------------------------------------------
    -- LAYOUT CONSTANTS (computed from tokens each frame)
    -- --------------------------------------------------------
    local padX     = T.sp.sm            -- 10u — left/right inset
    local rowH     = T.rowH             -- 30u (Small text) / 34u (Large)
    local catHdrH  = T.sp.catHdrH       -- category group label row
    local colHdrH  = T.sp.colHdrH       -- column header bar
    local iconW    = rowH - T.px(8)           -- item icon square (closer to text height)
    local iconGap  = T.sp.iconGap       -- 8u — icon → name gap
    local scrollW  = T.sp.scrollbarW    -- 14u — reserved for scrollbar
    local scale    = T.scale or 1.0     -- text scale factor
    local st       = T.stripe           -- alternating row shading

    -- Column widths: user-resizable with scale-aware defaults
    -- Reset to defaults when text scale changes
    local colWData = self._colWidths
    local readOn = ZeD.ReadMarks.on()   -- (the read marks' room in COND only while they are on)
    if not colWData or self._colWidthsScale ~= scale or (colWData.readOn ~= nil and colWData.readOn ~= readOn) or not colWData.wtB then
        -- measured, not guessed: the longest
        -- common category ("Literature") and a weight in the columns' own
        -- fonts, so Large text shows "Literature" whole, not "Liter..."
        colWData = {
            -- (bug B2 of QA's visual noise audit, Nov 20 2026: "Tool / ..." and "Fire So..." in every capture, the two
            -- most common long ones, while Status beside them had room; measured on them too, up to 120 units,
            -- the room taken from the name, which has the most)
            cat  = math.ceil(math.min(math.max(ZeD.TM:MeasureStringX(T.fontF1, ZeD.InventoryRenderer.catLabel("Literature")),
                                               ZeD.TM:MeasureStringX(T.fontF1, ZeD.InventoryRenderer.catLabel("ToolWeapon")),
                                               ZeD.TM:MeasureStringX(T.fontF1, ZeD.InventoryRenderer.catLabel("FireSource"))),
                                      T.px(120)) + padX * 2),
            -- (a book's read status takes the column, a dot and a word; room
            -- for the one-word statuses, so the column still shows in the default window; longer ones shorten)
            -- (and room for its heading, "Cond / Amt", whole: up to 90 units of F5, past that it shortens; the cap
            -- runs wider by T.sortWidthK when the sort font is F1, at Large, so a heading that fit in F5 still fits)
            cond = math.max(readOn and math.max(math.floor(50 * scale), ZeD.ReadMarks.wordRoom() + padX) or math.floor(50 * scale),
                            math.min(math.ceil(ZeD.TM:MeasureStringX(T.sortFont, ZeD.tr("UI_ZeD_Inv_ColCond")) + padX * 2), math.floor(90 * scale * (T.sortWidthK or 1)))),
            readOn = readOn,
            -- (a stack's row shows its total in brackets, "(2.5)"; wtU is an item's
            -- own, the width the bracket gives way to, see wtFit)
            wtB  = math.ceil(ZeD.TM:MeasureStringX(T.fontF3, "(88.8)") + padX * 2),
            wtU  = math.ceil(ZeD.TM:MeasureStringX(T.fontF3, "88.8") + padX * 2),
        }
        colWData.wt  = colWData.wtB
        colWData.wtC = colWData.wtB   -- the compact (side-by-side) weight column, never resized
        self._colWidths = colWData
        self._colWidthsScale = scale
    end

    -- Responsive columns: drop one at a time as panel narrows
    -- Order: cond first, then cat. Name + WT always stay; the weight's bracket
    -- takes its room from the name (names shorten
    -- before a column drops for it).
    local nameX    = padX + iconW + iconGap
    local MIN_NAME = T.px(100)   -- (names before categories: at Large text the category drops before names crush)
    local catColW  = colWData.cat
    local condColW = colWData.cond
    -- (a column among several, Loot columns: the compact weight column, never resized)
    local wtColW   = self._compactMode and colWData.wtC or colWData.wt
    local showCond = true
    local showCat  = true

    -- (List columns, the director, Nov 22 2026) one priority for every list, a column among several too (it used to
    -- show the name and the weight alone): the name, the weight, then Category where it fits, then Status where the
    -- name keeps COND_NAME_U beside it (fitColumns). The widths were measured once above, so this is sums only.
    local wtD = wtColW - wtShare(colWData, wtColW)   -- (the unit's width: the bracket drops no column)
    showCond, showCat = fitColumns(colW - nameX - wtD - padX - scrollW - MIN_NAME, catColW, condColW,
        T.px(ZeD.InventoryRenderer.COND_NAME_U) - MIN_NAME)
    if not showCond then condColW = 0 end
    if not showCat then catColW = 0 end
    wtColW = wtFit(colWData, wtColW, colW - nameX - catColW - condColW - padX - scrollW, MIN_NAME)
    -- (the panel keeps which show: the controller's L3 sort skips a hidden Status, renderMultiColumnContent copies
    -- them to each column; fields, not locals: this function is near Kahlua's 200-local limit)
    self._showCat, self._showCond = showCat, showCond

    -- Column X positions (all column-local, 0-based)
    local nameW   = colW - nameX - catColW - condColW - wtColW - padX - scrollW
    local catX    = nameX + nameW
    local condX   = catX + catColW
    local wtX     = condX + condColW
    local scrollX = colW - scrollW

    -- Font heights for vertical centering
    local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
    local secFH  = ZeD.TM:getFontHeight(T.fontF1)
    local statFH = ZeD.TM:getFontHeight(T.fontF3)
    local f5FH   = ZeD.TM:getFontHeight(T.fontF5)

    -- Bar height — container toggle bar sits above all column content
    local barH = self._barH or 0

    -- Header Y offset — pushed down by bar + container info header
    local hdrYOff = self._hdrYOffset
    local hdrY    = barH + ((type(hdrYOff) == "number") and hdrYOff or 0) + (self._fbarH or 0)   -- (and the Filter bar)

    -- Container buttons: their row sits at the bottom; the list ends above it
    ccLayout(self, hdrY, barH, colW)

    -- --------------------------------------------------------
    -- PRE-COMPUTE: Build item list + determine scroll state
    -- --------------------------------------------------------

    local inv = self._inventory
    -- Hide equipped items from player's main inventory (shown in Equipment tab)
    local playerObj = self._playerObj
    local isPlayerInv = playerObj and inv and inv == playerObj:getInventory()

    -- (List columns, the director, Nov 22 2026: a sort on a column the list has dropped falls back; listSort)
    local sortCol  = ZeD.InventoryRenderer.listSort(self, self._sortCol or "name", showCond)
    local sortAsc  = self._sortAsc
    local collapsed = self._collapsedGroups

    -- Item stacking: identical items collapse into one row with their count
    -- ("Apple x6"). The rows are built in itemModel, only when the container changes.
    self._expandedStacks = self._expandedStacks or {}
    -- (Nov 15 2026, punch list 245: the grid opens no stacks, a stack is one cell; its model is built as if every
    -- stack were shut, so an open one in the list never takes its cell away)
    -- (Nov 15 2026, add-on hooks: with an add-on's grid layout on, the grid's model ignores the folds, so the add-on
    -- is handed every item; GridLayout.modelFolds hands the folds back untouched otherwise)
    local M = itemModel(self, inv, playerObj, isPlayerInv, sortCol, sortAsc, ZeD.GridLayout.modelFolds(collapsed, inv, playerObj, self),
        ZeD.InventoryRenderer.isGridKey(containerKeyOf(inv, playerObj), playerObj or getSpecificPlayer(0)) and NO_OPEN or self._expandedStacks)
    -- a container this list starts showing while on screen: a mod's pick hook (ContainerGates.seen)
    ZeD.ContainerGates.seen(self, inv, playerObj)
    filterColumn(self, M)   -- (this list's matches, kept until the filter or the model changes)
    local groups, catOrder, flatItems = M.groups, M.catOrder, M.flatItems
    local useGroups, stackedGroups, catRowCount = M.useGroups, M.stackedGroups, M.catRowCount
    local childParent = M.childParent
    local stacks = M.stacks

    self._flatItems      = flatItems
    self._invRowItems    = flatItems   -- (the same rows, under the name both windows' controller stops read)
    self._useGroups      = useGroups
    self._groups         = groups
    self._stackedGroups  = stackedGroups
    self._catOrder       = catOrder
    self._stacks         = stacks
    self._childParent    = childParent
    self._catOf          = M.catOf
    self._openHeads      = M.heads    -- (punch list 245: an open stack's header rows, the pad's stops for them)
    self._headOf         = M.headOf

    -- GRID: this container's view, and the cells' layout (a stack is one cell;
    -- its children are never shown apart, as the card covers the stack)
    -- (one table: renderItemList sits near Kahlua's 200-local limit; the grid's
    -- drawing lives in drawGridList / drawViewToggle, outside this function)
    self._gv = gridState(self, inv, playerObj, colW, scrollW, padX, childParent)
    -- (Nov 15 2026, add-on hooks: an add-on's layout for this grid, GridLayout.lua: kept until the model rebuilds, it
    -- sets self._gv.L and the rows the pad and the drag read; nothing without an add-on. No new locals here: this
    -- function sits near Kahlua's 200-local limit)
    ZeD.GridLayout.attach(self, self._gv, M, inv, playerObj, useGroups, catHdrH, colW - scrollW - padX * 2)
    -- (List columns, Nov 22 2026: the grid's bar has every sort key, so nothing counts as hidden there)
    if self._gv.on then self._showCat, self._showCond = true, true end
    -- (Grid width, the director, Nov 22 2026) a list alone on its panel tells the window whether it hugs: a grid of
    -- ZeD's own cells (an add-on's layout sizes its own squares, so it is left as it is). renderMultiColumnContent
    -- sets these for side-by-side columns. The windows read them (ZeD.Halves.gridHug).
    if not self._compactMode then
        self._hugN = (self._gv.on and not self._gv.L) and 1 or nil
        self._hugXfer, self._hugCols = 0, 1
    end

    -- No head row over an empty list (QA's visual noise audit 2, Nov 20 2026: "Name Cat Status Wt" over "Nothing
    -- here.") nor over a grid, which has no columns (audit 36): the grid's sort keys come with its Filter bar, under
    -- it while the bar is open; the controller's L3 sorts either way. (No new local: this function is near Kahlua's
    -- 200-local limit.)
    if #catOrder == 0 or (self._gv.on and not (self._zedFilter and self._zedFilter.shown and self._zedFilter.open)) then
        colHdrH = 0
    end

    local totalContentH = 0
    if self._gv.L then
        totalContentH = self._gv.L.totalH   -- (the add-on's grid: its height worked out with the layout)
    elseif useGroups then
        for _, cat in ipairs(catOrder) do
            totalContentH = totalContentH + catHdrH
            if self._gv.on then
                totalContentH = totalContentH + gridH(self._gv, gridCount(self._gv, stackedGroups[cat]))
            else
                totalContentH = totalContentH + (catRowCount[cat] or 0) * rowH
            end
        end
    else
        totalContentH = self._gv.on and gridH(self._gv, gridCount(self._gv, flatItems)) or ((#flatItems + #M.heads) * rowH)
    end
    -- (KISS #11) the Worn and held line ends the list when what is worn stays on the Equipment tab: one more row
    -- (ContainerControls.wornLineOn; a flag on the panel, as this function is near Kahlua's 200 locals)
    self._wornLine = not self._gv.on and ZeD.ContainerControls.wornLineOn(self) or false
    if self._wornLine then totalContentH = totalContentH + rowH end

    local contentTop = hdrY + colHdrH
    local visibleH   = h - contentTop - self._ccH   -- (the container buttons' row below)
    local scroll     = self._scroll

    -- Scrollbar geometry — uses panel-absolute X via xOff
    scroll.y      = contentTop
    scroll.height = visibleH
    scroll.width  = scrollW
    scroll.arrowH = scrollW
    scroll.visible = totalContentH > visibleH

    if totalContentH > 0 then
        scroll:setBarSize(math.min(1.0, visibleH / totalContentH))
    else
        scroll:setBarSize(1.0)
    end

    if not scroll.visible then
        scroll:setScrollPos(0)
        scrollX = colW
        -- Recalculate column positions to fill full width (no scrollbar gap)
        nameW  = colW - nameX - catColW - condColW - wtColW - padX
        catX   = nameX + nameW
        condX  = catX + catColW
        wtX    = condX + condColW
    end

    -- Scrollbar X in panel-absolute coords
    scroll.x = xOff + (scroll.visible and (colW - scrollW) or colW)

    -- --------------------------------------------------------
    -- CONTAINER INFO HEADER (when hdrY > 0)
    -- --------------------------------------------------------
    self._viewToggleRects = self._gv.toggles
    self._gridHintCand = nil
    if hdrY > 0 then
        -- (drawn by drawColumnHeading: renderItemList keeps its locals few, see there)
        drawColumnHeading(self, self._gv, xOff, colW, barH, hdrY, padX, secFH, f5FH)
        aDiv(0, hdrY - T.px(1), colW, true)
    end

    -- the container buttons' row
    if self._ccH > 0 then ccDraw(self, colW, xOff) end

    -- --------------------------------------------------------
    -- COLUMN HEADER BAR (its surface claimed over the body: one layer)
    -- --------------------------------------------------------
    ZeD.Surface.fill(self, xOff, hdrY, colW, colHdrH, "surf2")

    -- (row 2: T.sortBarH high, its words in the sort font, F1, which grows with Large; punch list 178)
    local hdrTextY = hdrY + math.floor((colHdrH - ZeD.TM:getFontHeight(T.sortFont)) / 2)

    local colDefs = {
        {ZeD.tr("UI_ZeD_Inv_ColName"), "name", nameX, 0, catX},
    }
    if showCat then
        colDefs[#colDefs + 1] = {ZeD.tr("UI_ZeD_Inv_ColCat"),  "cat",  catX + padX,  catX,   catColW}
    end
    if showCond then
        -- (left, as Name and Category: only Weight, a number, sits at the right, over its values' right edge, the
        -- 6th field; the director, Nov 11 2026: "I miscommunicated ... Change that back to left aligned")
        colDefs[#colDefs + 1] = {ZeD.tr("UI_ZeD_Inv_ColCond"), "cond", condX + padX, condX,  condColW}
    end
    colDefs[#colDefs + 1] = {ZeD.tr("UI_ZeD_Inv_ColWt"),   "wt",   wtX + padX,   wtX,    wtColW, wtX + wtColW - padX}
    -- the grid has no columns: its bar carries the same sort keys end to end
    if self._gv.on then colDefs = gridSortDefs(padX, scroll.visible and (colW - scrollW) or colW) end
    if colHdrH == 0 then colDefs = {} end   -- (no head row: above)

    -- Divider hit zones (registered BEFORE header zones for priority)
    local DIV_W = T.px(6)
    if not self._compactMode and not self._gv.on then
        if showCat then
            hZ("div:cat", catX - DIV_W / 2, hdrY, DIV_W, colHdrH)
        end
        if showCond then
            hZ("div:cond", condX - DIV_W / 2, hdrY, DIV_W, colHdrH)
        end
        hZ("div:wt", wtX - DIV_W / 2, hdrY, DIV_W, colHdrH)
    end

    for _, def in ipairs(colDefs) do
        local label, key, drawX, hitX, hitW = def[1], def[2], def[3], def[4], def[5]
        local isActive = (sortCol == key)
        local color = T.toneNorm
        -- a header never runs past its own column: too long ends in "..."
        local rightX = def[6]
        label = truncateText(label, T.sortFont, rightX and (rightX - hitX - T.px(2)) or (hitX + hitW - drawX - T.px(2)))
        if rightX then drawX = rightX - ZeD.TM:MeasureStringX(T.sortFont, label) end
        dT(label, drawX, hdrTextY, color.r, color.g, color.b, color.a, T.sortFont)
        -- Under/overline active sort column (System 7 style)
        if isActive then
            local labelW = ZeD.TM:MeasureStringX(T.sortFont, label)
            if sortAsc then
                dR(drawX, hdrTextY + ZeD.TM:getFontHeight(T.sortFont), labelW, T.px(1), color.a, color.r, color.g, color.b)
            else
                dR(drawX, hdrTextY - T.px(1), labelW, T.px(1), color.a, color.r, color.g, color.b)
            end
        end
        hZ("hdr:" .. key, hitX, hdrY, hitW, colHdrH)
    end

    -- Hover highlight on hovered column header
    local mx      = self:getMouseX()
    local my      = self:getMouseY()
    local localMx = mx - xOff
    local mouseInCol = localMx >= 0 and localMx < colW and my >= 0 and my < h
    local colDrag = self._colDrag

    if mouseInCol and my >= hdrY and my < hdrY + colHdrH and localMx < scrollX then
        -- Check for divider hover
        local divHover = false
        if not self._compactMode then
            local zone = self:hitZoneAt(mx, my)
            if zone and type(zone.id) == "string" and zone.id:sub(1, 4) == "div:"
               and zone.x >= xOff and zone.x < xOff + colW then
                divHover = true
                local ac = T.accent
                dR(zone.x - xOff + DIV_W / 2 - T.px(1), hdrY, T.px(2), colHdrH, ac.a, ac.r, ac.g, ac.b)
            end
        end
        if not divHover and not cuesOn() then
            for _, def in ipairs(colDefs) do
                local hitX, hitW = def[4], def[5]
                if localMx >= hitX and localMx < hitX + hitW then
                    local hv = T.hover
                    dR(hitX, hdrY, hitW, colHdrH, hv.a, hv.r, hv.g, hv.b)
                    ZeD.Help.set(self, ZeD.tr("UI_ZeD_Inv_ColHelp", def[1]))
                    break
                end
            end
        end
    end

    -- Active column drag: draw accent line at current divider position
    if colDrag then
        local dragCol = colDrag.col
        local divX
        if dragCol == "cat" then divX = catX
        elseif dragCol == "cond" then divX = condX
        else divX = wtX end
        local ac = T.accent
        dR(divX - T.px(1), hdrY, T.px(2), h, ac.a, ac.r, ac.g, ac.b)
    end

    aDiv(0, hdrY + colHdrH - T.px(1), colW, true)

    -- --------------------------------------------------------
    -- DRAW ROWS (clipped to below column header)
    -- --------------------------------------------------------

    -- SCROLL-FOLLOW: if a controller-focused row exists, make sure it's
    -- visible before the scroll offset is worked out. Uses the item's
    -- render Y stamped into `self._itemRenderYMap` during the PREVIOUS
    -- frame's draw loop. The one-frame lag doesn't show (focus only moves
    -- on a press).
    -- The map is a Lua table because a field can't be stamped onto a Java
    -- item object (Kahlua throws "attempted index of non-table").
    --
    -- DELTA GATE: `_gpFocusedRowItem` stays set when the input mode
    -- switches, so pinning whenever the focused row is out of view would
    -- re-pin the scroll every tick — a mouse user scrolling the wheel past
    -- it would be pulled back. A mode gate (getMode() == "gamepad") doesn't
    -- help: with a drifting stick and the mouse both live, the detector
    -- swaps kbm <-> gamepad from one frame to the next. So the scroll pins
    -- only when the focused item actually CHANGED this render (kept in
    -- `_lastPinnedRowItem`), whatever the input mode: a D-pad move changes
    -- focus → one pin fires → stops; a mouse user scrolls past the pinned
    -- row → focus unchanged → no re-pin.
    local itemRenderYMap = self._itemRenderYMap or {}
    if self._gpFocusedRowItem
       and self._gpFocusedRowItem ~= self._lastPinnedRowItem
       and totalContentH > visibleH then
        local focY = itemRenderYMap[self._gpFocusedRowItem]
        if focY then
            -- focY is the absolute y from last frame's draw. A row draws at
            -- renderY = contentTop + logicalY - scrollOffset, so
            -- logicalY = focY - contentTop + scrollOffset, with the bar's
            -- current position taken as the offset it was drawn at.
            local oldScrollOff = math.floor(scroll.scrollPos * (totalContentH - visibleH))
            local logicalY = focY - contentTop + oldScrollOff

            -- If the focused row's logical top is above the viewport, scroll up
            if logicalY < oldScrollOff then
                scroll:setScrollPos(logicalY / (totalContentH - visibleH))
            -- If the focused row's logical bottom is below viewport, scroll down
            elseif logicalY + (self._gv.on and self._gv.cell or rowH) > oldScrollOff + visibleH then
                local newOff = logicalY + (self._gv.on and self._gv.cell or rowH) - visibleH
                scroll:setScrollPos(newOff / (totalContentH - visibleH))
            end
        end
        self._lastPinnedRowItem = self._gpFocusedRowItem
    end
    -- (Nov 15 2026, add-on hooks: the pad's place mode keeps its ghost in view the same way, GridLayout.lua)
    ZeD.GridLayout.followPad(self, inv, scroll, totalContentH, visibleH, contentTop)
    -- Fresh map for this frame's stamps (cleared each frame so stale items
    -- don't accumulate).
    itemRenderYMap = {}
    self._itemRenderYMap = itemRenderYMap

    local scrollOffset = 0
    if totalContentH > visibleH then
        scrollOffset = math.floor(scroll.scrollPos * (totalContentH - visibleH))
    end

    if not self._skipClearHitZones then
        self:clearHitZones()
    end

    -- Re-register divider + column header hit zones (must survive clear or co-exist)
    if not self._compactMode and not self._gv.on then
        if showCat then
            hZ("div:cat", catX - DIV_W / 2, hdrY, DIV_W, colHdrH)
        end
        if showCond then
            hZ("div:cond", condX - DIV_W / 2, hdrY, DIV_W, colHdrH)
        end
        hZ("div:wt", wtX - DIV_W / 2, hdrY, DIV_W, colHdrH)
    end
    for _, def in ipairs(colDefs) do
        hZ("hdr:" .. def[2], def[4], hdrY, def[5], colHdrH)
    end
    if self._ccH > 0 and not self._compactMode then ZeD.ContainerControls.addZones(self) end   -- (a column's foot: its toggle)
    -- the view button (its rects are panel coords already)
    addToggleZones(self, self._gv)

    self:setStencilRect(xOff, contentTop, scroll.visible and (colW - scrollW) or colW, visibleH)
    -- the rows' view this frame, in the rows' own space: a row stop out of it
    -- is for its own list only (Focus.markOffscreen; MC columns copy it)
    local rv = self._rowView or {}
    rv.top, rv.bottom = contentTop, contentTop + visibleH
    self._rowView = rv

    local y      = contentTop - scrollOffset
    local rowIdx = 0

    local selectedItems = self._selectedItems

    -- Shared row drawing function
    local function drawItemRow(item)
        -- (Nov 15 2026, punch list 245) an open stack's header, drawn just above its first item's row: the stack
        -- itself (its icon, name and count, its total weight), no item's row. A press anywhere on it shuts the
        -- stack (as a category row folds), the right button gives the whole stack's menu. Its place is stamped
        -- under "stackhead:<key>" for the pad's stop and the scroll's follow.
        local hs = self._headOf and self._headOf[item]
        if hs then
            local hk = "stackhead:" .. hs.key
            itemRenderYMap[hk] = y
            if y + rowH > contentTop and y < h then
                if rowIdx % 2 == 1 then dR(0, y, scrollX, rowH, st.a, st.r, st.g, st.b) end
                local hfo = gpFocusedHead(hs.key, self._inventory, ZeD.playerNumOf(self))
                if not hfo and not cuesOn() and mouseInCol and my >= y and my < y + rowH and my >= contentTop
                   and my < contentTop + visibleH and localMx < scrollX then
                    local hv = T.hover
                    dR(0, y, scrollX, rowH, hv.a, hv.r, hv.g, hv.b)
                    if ZeD.InvTip then   -- (the loot card names the stack as its row does: "Rag x3")
                        local r = _tipRect
                        r.x, r.y, r.w, r.h = xOff, y, scrollX, rowH
                        ZeD.InvTip.want(self, hs.rep, r, hs.count)
                    end
                end
                if hfo then ZeD.Focus.mark(self, xOff, y, scrollX, rowH, hfo) end
                local htc = hfo and (T.textOnFocus or T.toneNorm) or nil
                local htex = keptTex(hs.rep)
                if htex then dTS(htex, padX, y + math.floor((rowH - iconW) / 2), iconW, iconW, 1, 1, 1, 1) end
                local tri = math.min(T.px(8), rowH - T.px(4))
                A.drawTriangleDown(self, xOff + nameX, y + math.floor((rowH - tri) / 2), tri, htc or T.toneLo or T.textDim)
                local hsuf = " (" .. tostring(hs.count) .. ")"
                local hroom = nameW - tri - T.px(6)
                -- (bug B4 of QA's visual noise audit, Nov 20 2026: "Apple (Fr... (3)" over three whole "Apple (Fresh)"
                -- rows. A name that does not fit with its count takes the Category cell's room too; the closed stack's
                -- row and the group heading still say the category)
                local hspill = showCat and ZeD.TM:MeasureStringX(T.fontF2, keptName(hs.rep) .. hsuf) > hroom
                if hspill then hroom = hroom + catColW end
                local hname = truncateText(keptName(hs.rep), T.fontF2, hroom - ZeD.TM:MeasureStringX(T.fontF2, hsuf)) .. hsuf
                local hc = htc or T.toneNorm
                dT(hname, nameX + tri + T.px(6), y + math.floor((rowH - bodyFH) / 2), hc.r, hc.g, hc.b, hc.a or 1, T.fontF2)
                if showCat and not hspill then
                    local hcat = truncateText(ZeD.InventoryRenderer.catLabel(self._catOf[hs.rep] or ZeD.InventoryRenderer.catKey(hs.rep)),
                        T.fontF1, catColW - padX * 2)
                    local cc = htc or T.toneHi
                    dT(hcat, catX + padX, y + math.floor((rowH - secFH) / 2), cc.r, cc.g, cc.b, cc.a, T.fontF1)
                end
                A.drawTextRight(self, weightText(hs.rep, hs, T.fontF3, wtColW - padX * 2), xOff + wtX + wtColW - padX,
                    y + math.floor((rowH - statFH) / 2), T.fontF3, htc or T.toneHi)
                hZ("stack:" .. hs.key, 0, y, scrollX, rowH)
            end
            y      = y + rowH
            rowIdx = rowIdx + 1
        end

        -- Stamp the row's render Y into the panel-level map for scroll-follow
        -- (read next frame). Stamp BEFORE the visibility cull so items that
        -- just scrolled off-screen still have a valid entry for the follow
        -- algorithm. Cannot stamp on Java item objects directly (Kahlua
        -- throws "attempted index of non-table").
        itemRenderYMap[item] = y

        if y + rowH <= contentTop or y >= h then
            y      = y + rowH
            rowIdx = rowIdx + 1
            return
        end

        -- Alternating row stripe
        if rowIdx % 2 == 1 then
            dR(0, y, scrollX, rowH, st.a, st.r, st.g, st.b)
        end

        -- The row's states, under its words: selected (the T.selectionA wash),
        -- else the pointer's hover (and rows a pointed-at Same type button would
        -- move), then the controller's focus mark on the one row that is both
        -- this panel's seed and the live focused element of an inventory zone
        -- (gpFocusedItem). The mark says when the words switch to T.textOnFocus.
        local isSelected = selectedItems[item]
        local onFocus = rowStates(self, item, isSelected, xOff, y, scrollX, rowH,
            mouseInCol and my >= y and my < y + rowH and my >= contentTop and my < contentTop + visibleH and localMx < scrollX)
        local focusTxt = onFocus and (T.textOnFocus or T.toneNorm) or nil

        -- Stacking: this row's role in a stack. A stack's head shows a
        -- triangle and its count; an open stack's rows (every item, the first
        -- too: punch list 245) are drawn indented under its header; a single
        -- item draws as a plain row.
        local stackInfo   = self._stacks and self._stacks[item]
        local childParent = self._childParent and self._childParent[item]
        local isStackHead = stackInfo and stackInfo.count > 1
        local isChild     = childParent ~= nil
        local childIndent = isChild and T.px(10) or 0

        -- the read mark's status (ReadMarks.lua): read items dimmed with "Dim read items", the icon faded and the name in
        -- T.textDim at full strength (it keeps 4.6 : 1 in every theme; the name faded to half was pale gray on pale gray
        -- in Light; punch list 175f(2))
        local rs = ZeD.ReadMarks.state(playerObj or getSpecificPlayer(0), item)
        local dimA = (rs and rs.st == "r" and ZeD.ReadMarks.dimOn()) and 0.5 or 1

        -- Icon (children don't show icon; stack header shows icon of rep)
        if not isChild then
            local tex = keptTex(item)   -- (kept: rowRec)
            if tex then
                local iconY = y + math.floor((rowH - iconW) / 2)
                dTS(tex, padX, iconY, iconW, iconW, dimA, 1, 1, 1)
                -- (KISS #11) a worn or held thing wears the game's equipped mark
                if self._catOf and self._catOf[item] == ZeD.InventoryRenderer.WORN_KEY then
                    ZeD.InventoryRenderer.drawWornMark(self, xOff + padX, iconY, iconW)
                end
            end
        end

        -- Name (truncated to column width), with the stack's triangle / count
        local textY  = y + math.floor((rowH - bodyFH) / 2)
        local nameColor = focusTxt or (dimA < 1 and T.textDim) or (isSelected and T.toneHi or T.toneNorm)
        local baseName = keptName(item)   -- (kept: rowRec)
        local suffix = ""
        local chevW = 0
        if isStackHead then
            -- a stack's triangle (right when folded, down when open, the category rows' atom) stands
            -- left of its name; the press on it is the stack's zone below
            local expanded = self._expandedStacks and self._expandedStacks[stackInfo.key]
            local tri = math.min(T.px(8), rowH - T.px(4))
            local tcol = focusTxt or T.toneLo or T.textDim
            local tx, ty = xOff + nameX + childIndent, y + math.floor((rowH - tri) / 2)
            if expanded then A.drawTriangleDown(self, tx, ty, tri, tcol) else A.drawTriangleRight(self, tx, ty, tri, tcol) end
            chevW = tri + T.px(6)
            suffix = " (" .. tostring(stackInfo.count) .. ")"
        end
        -- a cut name keeps its end: a stack's count survives ("Apple (Fr... x6"), at Large text too
        local avail = nameW - childIndent - chevW
        -- room kept for the Next level tag (it never drops off a long name) and, with COND hidden, the read mark
        local nextTag = rs and rs.next and ZeD.ReadMarks.nextOn() and ZeD.tr("UI_ZeD_Read_NextLevel") or nil
        local nextW = nextTag and tagW(nextTag) or 0
        if nextTag then avail = avail - nextW - T.px(6) end
        local dotW = (rs and not showCond) and readTagW(rs) or 0   -- (the mark and its word: readTagW)
        if dotW > 0 then avail = avail - dotW - T.px(6) end
        local displayName = baseName .. suffix
        if suffix ~= "" and ZeD.TM:MeasureStringX(T.fontF2, displayName) > avail then
            displayName = truncateText(baseName, T.fontF2, avail - ZeD.TM:MeasureStringX(T.fontF2, suffix)) .. suffix
        else
            displayName = truncateText(displayName, T.fontF2, avail)
        end
        dT(displayName, nameX + childIndent + chevW, textY,
            nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1, T.fontF2)
        local afterName = nameX + childIndent + chevW + ZeD.TM:MeasureStringX(T.fontF2, displayName) + T.px(6)
        if ZeD.InvTip then ZeD.InvTip.nameEnd(self, item, xOff + afterName) end   -- (the loot card's tail past the name)
        if nextTag then
            -- (the accent, as the grid's next-level arrow)
            rowTag(self, xOff + afterName, y, rowH, nextTag, focusTxt, T.accentText or T.accent)
            afterName = afterName + nextW + T.px(6)
        end
        if dotW > 0 then
            drawReadCond(self, rs, xOff + afterName, y, rowH, dotW + math.floor(padX / 2), padX, focusTxt)
            afterName = afterName + dotW + T.px(6)
        end

        -- On the belt: a Belt n tag after the name (n = the key that draws it),
        -- where vanilla puts its small hotbar icon
        local aslot = keptSlot(item)   -- (kept: rowRec)
        if aslot and aslot > 0 and ZeD.Belt and ZeD.Belt.tagFor then
            local tag = ZeD.Belt.tagFor(aslot)
            if afterName + tagW(tag) <= nameX + nameW then rowTag(self, xOff + afterName, y, rowH, tag, focusTxt, T.info) end
        end

        local secTextY = y + math.floor((rowH - secFH) / 2)

        -- the COND cell first: a row with nothing in it (no bar, no read mark, most rows) lends its room to the
        -- category's words, which otherwise were cut short beside an empty cell ("Gardeni...")
        local condFree = showCond
        if showCond and rs then
            drawReadCond(self, rs, xOff + condX + T.px(6), y, rowH, condColW - T.px(6), padX, focusTxt)
            condFree = false
        elseif showCond then
            -- the framed condition strip (ZeD.Atoms.drawFillBar), compact, centered in the row
            condFree = not rowCondition(self, item, xOff + condX + T.px(2), y, condColW - T.px(4), rowH, stackInfo)
        end

        if showCat then
            -- (waiting to move: "Moving" in place of the category, a bar along the row's foot; punch list 146)
            -- (an open stack's own rows leave the category to the stack's header row: they show only what can differ,
            -- the name with its freshness, the condition and the weight; QA's visual noise audit 35, Nov 20 2026)
            if not queueMark(self, item, catX + padX, secTextY, catColW - padX * 2, xOff, y, scrollX, rowH) and not isChild then
                local catLabel = truncateText(ZeD.InventoryRenderer.catLabel(self._catOf[item] or ZeD.InventoryRenderer.catKey(item)), T.fontF1,
                    catColW - padX * 2 + (condFree and condColW or 0))
                local cc = focusTxt or T.toneHi
                dT(catLabel, catX + padX, secTextY, cc.r, cc.g, cc.b, cc.a, T.fontF1)
            end
        else
            queueMark(self, item, nil, nil, 0, xOff, y, scrollX, rowH)
        end

        -- Weight (F3, the data voice); a stack's head shows its total in brackets
        local wtStr = weightText(item, stackInfo, T.fontF3, wtColW - padX * 2)
        local wtTextY = y + math.floor((rowH - statFH) / 2)
        A.drawTextRight(self, wtStr, xOff + wtX + wtColW - padX, wtTextY, T.fontF3, focusTxt or T.toneHi)

        -- Hit zones: for stack headers, register chevron-area zone FIRST so
        -- it wins hit-testing for clicks on the arrow. Full-row item zone
        -- registers second for the rest of the row.
        if isStackHead then
            hZ("stack:" .. stackInfo.key, 0, y, nameX + T.px(16), rowH)
        end
        hZ(item, 0, y, scrollX, rowH)
        -- the Filter: the matched letters underlined, or the row dimmed (it keeps its zone above)
        if self._fres then
            filterRowMarks(self, self._fres, item, xOff + nameX + childIndent + chevW, textY, displayName, xOff, y, scrollX, rowH, onFocus)
        end
        -- a readable row shows its read card after the pause (the library's detail card, its balloon
        -- above the row's icon and name)
        if rs and mouseInCol and my >= y and my < y + rowH and my >= contentTop and my < contentTop + visibleH and localMx < scrollX then
            self._gridHintCand = { key = item, text = baseName, read = rs, x = xOff, y = y, w = math.min(scrollX, nameX + T.px(60)), h = rowH }
        end

        y      = y + rowH
        rowIdx = rowIdx + 1
    end

    -- GRID: the cells draw in drawGridList (outside this function: the local limit)
    self._gv.xOff, self._gv.padX, self._gv.top, self._gv.h, self._gv.visH = xOff, padX, contentTop, h, visibleH
    self._gv.sel, self._gv.ymap, self._gv.xmap = selectedItems, itemRenderYMap, {}
    self._gv.mouseIn, self._gv.lmx, self._gv.my, self._gv.f5FH, self._gv.secFH = mouseInCol, localMx, my, f5FH, secFH
    self._itemRenderXMap = self._gv.xmap


    if self._gv.on then
        if self._gv.L then
            -- (Nov 15 2026, add-on hooks: the add-on's layout draws its cells, spans and strips, GridLayout.lua)
            y = ZeD.GridLayout.draw(self, self._gv, y, scrollX, catHdrH)
        elseif useGroups then
            y = drawGridGroups(self, self._gv, catOrder, groups, collapsed, stackedGroups, y, scrollX, catHdrH)
        else
            y = drawGridList(self, self._gv, flatItems, y)
        end
    elseif useGroups then
        for _, cat in ipairs(catOrder) do
            local catGroup = groups[cat]
            local isClosed = collapsed[cat]

            -- Category row ("v Weapons (4)": the library's category row; a press folds it)
            itemRenderYMap["cat:" .. cat] = y   -- (its place, before the cull: the pad's stop and its scroll follow, 256)
            if y + catHdrH > contentTop and y < h then
                drawCatRow(self, xOff, y, scrollX, catHdrH, cat, #catGroup, isClosed,
                    mouseInCol and not cuesOn() and my >= y and my < y + catHdrH and localMx < scrollX, padX + T.px(2))
                hZ("cat:" .. cat, 0, y, scrollX, catHdrH)
            end
            y = y + catHdrH
            rowIdx = rowIdx + 1  -- count header row so stripe pattern stays consistent

            if not isClosed then
                -- Iterate the stacked row list, not raw items — stacking
                -- collapses identical fullTypes into a single row (expanded
                -- reveals children).
                local catRows = (self._stackedGroups and self._stackedGroups[cat]) or catGroup
                for _, item in ipairs(catRows) do
                    drawItemRow(item)
                end
            end
        end
    else
        for _, item in ipairs(flatItems) do
            drawItemRow(item)
        end
    end
    -- (KISS #11) the Worn and held line, under the last row
    if self._wornLine then
        ZeD.ContainerControls.drawWornLine(self, xOff, y, scrollX, rowH, contentTop, contentTop + visibleH)
    end

    self:clearStencilRect()

    -- one list with its heading: the Filter bar, over the full width (side by side, after the last column)
    if not self._compactMode then filterEnd(self) end

    -- --------------------------------------------------------
    -- EMPTY STATE
    -- --------------------------------------------------------
    -- (the library's empty line: F2 dim, at the list's text inset, 8u under its header)
    if #catOrder == 0 and not self._wornLine then   -- (KISS #11: the Worn and held line stands in for it)
        -- (a mod's gate words its own: "Not searched.")
        ZeD.Molecules.drawEmptyLine(self, xOff + padX, contentTop + T.px(8), scrollX - padX * 2,
            ZeD.ContainerGates.emptyText(inv, playerObj) or ZeD.tr("UI_ZeD_Inv_Empty"))
    end

    -- --------------------------------------------------------
    -- SCROLLBAR (drawn in panel-absolute coords via scroll.x)
    -- --------------------------------------------------------
    scroll:draw(self)

    -- an icon's hover hint (container buttons), over everything
    if self._ccH > 0 then ccHint(self) end

    -- a grid cell (its item's name) or the view button names itself
    drawGridHint(self, self._gv, xOff, colW, contentTop)
    -- (Nov 15 2026, add-on hooks: a drag over this list that an add-on's rule refuses says why on the help line,
    -- ItemRules.lua; nothing without a rule)
    ZeD.ItemRules.dragOver(self, inv)
end

-- ============================================================================
-- XFER STRIP RENDERER
-- Draws a narrow transfer strip between two inventory columns.
-- Contains destination buttons for each selected container.
-- ============================================================================

local MIN_COL_W      = 140   -- minimum usable column width (compact mode)
local COMFORT_COL_W  = 220   -- preferred column width when space allows
local XFER_W_NORMAL  = 32    -- transfer strip between columns (2-3 cols)
local XFER_W_COMPACT = 24    -- narrower XFER strip at 4+ cols (drop badge, keep arrow+icon)

-- Adaptive XFER strip width based on column count
-- Returns DESIGN units (exported; the Character and World windows wrap it in T.px)
local function getXferW(colCount)
    if colCount >= 4 then return XFER_W_COMPACT end
    return XFER_W_NORMAL
end

local XFER_BTN_H = 22
local XFER_HDR_H = 6   -- small top padding (no text label)

local function renderXferStrip(self, stripX, stripH, selectedContainers, containers, activeCol, topY, xferW)
    local T = ZeD.T
    local A = ZeD.Atoms
    local y0 = topY or 0
    local sw = xferW or T.px(XFER_W_NORMAL)
    local btnW = sw - T.px(6)  -- 3px margin each side
    local compact = (sw <= T.px(XFER_W_COMPACT))

    -- (no fill of its own: the window body is under it, one layer)
    -- Left/right edges: structure lines between the panes
    local brd = T.borderS
    self:drawRect(stripX, y0, T.px(1), stripH - y0, brd.a, brd.r, brd.g, brd.b)
    self:drawRect(stripX + sw - T.px(1), y0, T.px(1), stripH - y0, brd.a, brd.r, brd.g, brd.b)

    -- Destination buttons (no header label — just small top padding)
    local btnX = stripX + T.px(3)
    local btnY = y0 + T.px(XFER_HDR_H)

    local mx = self:getMouseX()
    local my = self:getMouseY()

    for i, cIdx in ipairs(selectedContainers) do
        local container = containers[cIdx]
        local isSource  = (i == activeCol)
        local isHover   = (not isSource) and A.mouseIn(self, btnX, btnY, btnW, T.px(XFER_BTN_H))

        -- An icon button's look (the rounded single outline, the hover wash);
        -- the source column's own is the disabled control
        if isHover then
            local hv = T.hover
            A.fillRounded(self, btnX, btnY, btnW, T.px(XFER_BTN_H), hv.r, hv.g, hv.b, hv.a or 1)
            ZeD.Help.set(self, ZeD.tr("UI_ZeD_Inv_XferHelp", i))
        end
        local ob = T.borderS
        A.borderRounded(self, btnX, btnY, btnW, T.px(XFER_BTN_H), ob.r, ob.g, ob.b, (ob.a or 1) * (isSource and T.disabledAlpha or 1))

        -- Arrow direction (geometric)
        local arrowSz = T.px(5)
        local arrowDrawY = btnY + math.floor((T.px(XFER_BTN_H) - arrowSz) / 2)
        local arrowDrawX = btnX + math.floor((btnW - arrowSz) / 2)
        local txtColor = isSource and T.textDim or T.textSec
        if i == activeCol then
            -- Dash for source column (1px horizontal line)
            local dc = txtColor
            self:drawRect(arrowDrawX, arrowDrawY + math.floor(arrowSz / 2), arrowSz, T.px(1), dc.a or 1, dc.r, dc.g, dc.b)
        elseif i < activeCol then
            A.drawTriangleLeft(self, arrowDrawX, arrowDrawY, arrowSz, txtColor)
        else
            A.drawTriangleRight(self, arrowDrawX, arrowDrawY, arrowSz, txtColor)
        end

        -- Container icon (tiny)
        if container and container.texture then
            local icoSz = compact and T.px(10) or T.px(12)
            local icoX = btnX + math.floor((btnW - icoSz) / 2)
            local icoY = btnY + math.floor((T.px(XFER_BTN_H) - icoSz) / 2)
            self:drawTextureScaledAspect(container.texture, icoX, icoY, icoSz, icoSz,
                isSource and 0.3 or 0.7, 1, 1, 1)
        end

        -- Badge number — only at normal width
        if not compact then
            local numStr = tostring(i)
            local numColor = isSource and T.textDim or T.text
            A.drawSecondary(self, numStr, btnX + btnW - T.px(8), arrowDrawY, numColor)
        end

        -- Hit zone for non-source buttons
        if not isSource then
            self:addHitZone("xfer:" .. i, btnX, btnY, btnW, T.px(XFER_BTN_H))
        end

        btnY = btnY + T.px(XFER_BTN_H) + T.px(2)
    end
end

-- ============================================================================
-- CONTAINER BAR RENDERER
-- Clickable horizontal row at top of content panel.
-- Click to toggle containers in/out of the selection.
-- ============================================================================

local CONTAINER_BAR_H = 28
local CBAR_PAD        = 4   -- padding inside bar
local CBAR_BTN_H      = 20  -- button height
local CBAR_BTN_GAP    = 4   -- gap between buttons
local CBAR_ICON_SZ    = 14  -- icon size inside button

local function renderContainerBar(self)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local w  = self:getWidth()

    local containers = self._containers
    local selected   = self._selectedContainers
    if not containers or #containers == 0 then return end

    -- Background (claimed over the body: one layer)
    ZeD.Surface.fill(self, 0, 0, w, T.px(CONTAINER_BAR_H), "surf2")

    -- Build selection lookup: containerIdx → column number (1-based)
    local selMap = {}
    for colNum, cIdx in ipairs(selected) do
        selMap[cIdx] = colNum
    end

    local secFH = ZeD.TM:getFontHeight(T.fontF1)
    local btnY  = T.px(CBAR_PAD)
    local btnX  = T.px(CBAR_PAD)
    local mx    = self:getMouseX()
    local my    = self:getMouseY()

    for ci = 1, #containers do
        local c       = containers[ci]
        local colNum  = selMap[ci]
        local isSel   = colNum ~= nil

        -- Measure button width: icon + gap + name + padding
        local label = truncateText(c.name or "???", T.fontF1, T.px(80))
        local labelW = ZeD.TM:MeasureStringX(T.fontF1, label)
        local btnW = T.px(CBAR_PAD) * 2 + labelW
        if c.texture then
            btnW = btnW + T.px(CBAR_ICON_SZ) + T.sp.iconGap
        end
        if isSel then
            -- Extra room for badge number
            btnW = btnW + T.px(12)
        end

        -- Clamp to available space
        if btnX + btnW > w - T.px(CBAR_PAD) then break end

        local isHover = A.mouseIn(self, btnX, btnY, btnW, T.px(CBAR_BTN_H))

        -- Draw button: selected = the T.selectionA wash, hover = T.hover, one outline
        if isSel then
            local ac = T.accent
            self:drawRect(btnX, btnY, btnW, T.px(CBAR_BTN_H), T.selectionA, ac.r, ac.g, ac.b)
        elseif isHover then
            local hv = T.hover
            self:drawRect(btnX, btnY, btnW, T.px(CBAR_BTN_H), hv.a, hv.r, hv.g, hv.b)
        end
        local brd = T.borderS
        self:drawRectBorder(btnX, btnY, btnW, T.px(CBAR_BTN_H), brd.a, brd.r, brd.g, brd.b)

        -- Icon
        local cx = btnX + T.px(CBAR_PAD)
        if c.texture then
            local icoY = btnY + math.floor((T.px(CBAR_BTN_H) - T.px(CBAR_ICON_SZ)) / 2)
            self:drawTextureScaledAspect(c.texture, cx, icoY, T.px(CBAR_ICON_SZ), T.px(CBAR_ICON_SZ),
                isSel and 1 or 0.5, 1, 1, 1)
            cx = cx + T.px(CBAR_ICON_SZ) + T.sp.iconGap
        end

        -- Label
        local textY = btnY + math.floor((T.px(CBAR_BTN_H) - secFH) / 2)
        local textColor = isSel and T.text or T.textDim
        A.drawSecondary(self, label, cx, textY, textColor)
        cx = cx + labelW

        -- Badge number for selected containers
        if isSel then
            cx = cx + T.px(4)
            A.drawSecondary(self, tostring(colNum), cx, textY, T.text)
        end

        -- Hit zone
        self:addHitZone("cbar:" .. ci, btnX, btnY, btnW, T.px(CBAR_BTN_H))

        btnX = btnX + btnW + T.px(CBAR_BTN_GAP)
    end

    -- The structure line under the bar
    A.drawDividerH(self, 0, T.px(CONTAINER_BAR_H) - T.px(1), w, true)
end

-- ============================================================================
-- MULTI-COLUMN CONTENT DISPATCHER
-- Replaces renderItemList as _onPrerender when multi-column is active.
-- Dispatches to renderItemList per column with state swapping.
-- ============================================================================


local function renderMultiColumnContent(self)
    local T = ZeD.T
    local colStates = self._colStates
    local selected  = self._selectedContainers
    local containers = self._containers
    local N = #selected

    -- Persist any mouse-handler state changes from between frames.
    -- Mouse handlers may replace self._selectedItems with a new table;
    -- save it back to the column state before we overwrite it.
    if colStates and #colStates > 0 then
        -- After the previous frame's dispatcher, self fields point to the
        -- LAST column rendered (main = rightmost). Save back to that column.
        local lastCs = colStates[#colStates]
        if lastCs then
            lastCs.selectedItems   = self._selectedItems
            lastCs.lastClickedItem = self._lastClickedItem
            lastCs.sortCol         = self._sortCol
            lastCs.sortAsc         = self._sortAsc
        end
    end
    -- (after the save above: that belongs to the columns as the last frame drew them)
    if syncColStates(self) then colStates, N = self._colStates, #selected end

    -- Set bar height so renderItemList shifts content down.
    -- Caller can pre-set _barH = 0 to suppress the container bar (both windows do).
    local showBar = (self._barH == nil) or (self._barH > 0)
    if showBar then
        self._barH = T.px(CONTAINER_BAR_H)
    end

    if N <= 1 then
        -- Single column: bind colStates[1] and call renderItemList directly
        local cs = colStates[1]
        if cs then
            -- Update render bounds for getColumnAtX
            cs.renderX = 0
            cs.renderW = self:getWidth()

            self._inventory       = cs.inventory
            self._selectedItems   = cs.selectedItems
            self._lastClickedItem = cs.lastClickedItem
            self._scroll          = cs.scroll
            self._sortCol         = cs.sortCol
            self._sortAsc         = cs.sortAsc
            self._collapsedGroups = cs.collapsedGroups

            self._renderXOffset     = 0
            self._renderW           = nil
            self._compactMode       = false
            self._skipClearHitZones = false
            self._hdrYOffset        = 0
            self._containerInfo     = nil

            -- each column keeps its own open stacks
            self._expandedStacks = cs.expandedStacks or {}
            cs.expandedStacks    = self._expandedStacks

            renderItemList(self)

            cs.flatItems       = self._flatItems
            cs.sortCol         = self._sortCol
            cs.sortAsc         = self._sortAsc
            cs.lastClickedItem = self._lastClickedItem
            cs.stacks          = self._stacks
            cs.childParent     = self._childParent
            cs.openHeads       = self._openHeads   -- (punch list 245: its open stacks' header rows)
            cs.catHeads        = self._useGroups and self._catOrder or nil   -- (punch list 256: its category headings)
            cs.catGroups       = self._stackedGroups
            cs._showCond       = self._showCond   -- (List columns, Nov 22 2026: the pad's L3 skips a hidden Status)
        else
            renderItemList(self)
        end
        -- Draw container bar AFTER columns so hit zones survive clearHitZones
        if showBar then renderContainerBar(self) end
        return
    end

    -- Multi-column layout with adaptive XFER width and minimum column floor
    local totalW = self:getWidth()
    local h      = self:getHeight()
    local xferW  = T.px(getXferW(N))
    local xferCount = N - 1
    local usableW   = totalW - (xferCount * xferW)
    local baseColW  = math.floor(usableW / N)
    baseColW = math.max(baseColW, T.px(MIN_COL_W))  -- enforce minimum column width

    -- Compute per-column X and W
    local layout = {}
    local cx = 0
    for i = 1, N do
        local w = baseColW
        if i == N then w = usableW - (baseColW * (N - 1)) end  -- last col gets remainder
        layout[i] = { x = cx, w = w }
        colStates[i].renderX = cx
        colStates[i].renderW = w
        cx = cx + w
        if i < N then
            layout[i].xferX = cx
            cx = cx + xferW
        end
    end

    -- Clear all hit zones once
    self:clearHitZones()

    -- (Grid width, the director, Nov 22 2026) the windows hug side-by-side columns only when every one is a grid of
    -- ZeD's own cells (one list among them keeps the list's width); set after the columns draw, read next frame
    local allGrid = true

    -- the window's one Filter across these columns: which containers show, where its bar sits
    filterFrame(self, true)

    -- Render each column
    for i = 1, N do
        local cs    = colStates[i]
        local cIdx  = cs.containerIdx
        local cData = containers[cIdx]
        local lx    = layout[i].x
        local lw    = layout[i].w

        if cData then
            -- Build container info header
            local inv = cs.inventory
            local weight   = inv and inv:getCapacityWeight() or 0
            local capacity = ZeD.InventoryRenderer.capacityOf(inv, self._playerObj)
            -- (a mod's gate: its words for the weight, and only the things it lets show)
            local statsStr = ZeD.ContainerGates.status(inv, self._playerObj) or ZeD.Atoms.loadText(weight, capacity)
            local itemCount = inv and ZeD.InventoryRenderer.shownCount(self, inv, self._playerObj) or 0   -- (as the rows)
            -- (QA's visual noise audit 2, Nov 20 2026: an empty column says "Nothing here." alone, no "0 items")
            local countStr  = (itemCount == 0) and "" or ZeD.tr(itemCount == 1 and "UI_ZeD_Inv_ItemsOne" or "UI_ZeD_Inv_ItemsMany", itemCount)

            -- Bind column state onto self
            self._inventory         = cs.inventory
            self._selectedItems     = cs.selectedItems
            self._lastClickedItem   = cs.lastClickedItem
            self._scroll            = cs.scroll
            self._sortCol           = cs.sortCol
            self._sortAsc           = cs.sortAsc
            self._collapsedGroups   = cs.collapsedGroups
            self._renderXOffset     = lx
            self._renderW           = lw
            self._compactMode       = true
            self._skipClearHitZones = true
            self._hdrYOffset        = self._defaultHdrYOffset or T.stripH   -- (row 1)
            self._containerInfo     = {
                name    = cData.name or "???",
                stats   = statsStr,
                count   = countStr,
                texture = cData.texture,
            }
            -- each column keeps its own widths (measured once, not every frame)
            self._colWidths      = cs.colWidths
            self._colWidthsScale = cs.colWidthsScale

            -- each column keeps its own open stacks
            self._expandedStacks = cs.expandedStacks or {}
            cs.expandedStacks    = self._expandedStacks

            renderItemList(self)

            -- Save back computed data
            cs.colWidths       = self._colWidths
            cs.colWidthsScale  = self._colWidthsScale
            cs.flatItems       = self._flatItems
            cs.sortCol         = self._sortCol
            cs.sortAsc         = self._sortAsc
            cs.lastClickedItem = self._lastClickedItem
            cs.stacks          = self._stacks
            cs.childParent     = self._childParent
            cs.openHeads       = self._openHeads   -- (punch list 245: its open stacks' header rows)
            cs.catHeads        = self._useGroups and self._catOrder or nil   -- (punch list 256: its category headings)
            cs.catGroups       = self._stackedGroups
            cs._showCond       = self._showCond   -- (List columns, Nov 22 2026: the pad's L3 skips a hidden Status)
            if not (self._gv and self._gv.on and not self._gv.L) then allGrid = false end
            -- Each column keeps its own row-Y map, so the per-column controller
            -- zones (charMC1.., worldMC1..) can read each row's y to move between
            -- rows. Each column's renderItemList call writes to
            -- self._itemRenderYMap and the next column overwrites it; the copy
            -- taken after each render keeps each column's stamps for the next
            -- frame's focusable builder.
            cs.itemRenderYMap  = self._itemRenderYMap
            -- (and its rows' view: values copied, the panel's table is the next column's)
            local rv = self._rowView
            if rv then
                cs.rowView = cs.rowView or {}
                cs.rowView.top, cs.rowView.bottom = rv.top, rv.bottom
            end
            -- the grid: each cell's x, the cell size, the view button (focusables read them)
            cs.itemRenderXMap  = self._itemRenderXMap
            cs.gridCell        = self._gridCell
            cs.viewToggleRects = self._viewToggleRects
            -- (Nov 15 2026, add-on hooks: an add-on's spans and its layout's number, GridLayout.lua; nil without one)
            cs.itemRenderWMap  = self._itemRenderWMap
            cs.itemRenderHMap  = self._itemRenderHMap
            cs.gridLayoutGen   = self._gridLayoutGen
        end
    end

    self._hugN = allGrid and N or nil
    self._hugXfer, self._hugCols = xferW, N

    -- Draw XFER strips between columns
    local activeCol = self._activeCol or 1
    local barH = self._barH or 0
    for i = 1, N - 1 do
        renderXferStrip(self, layout[i].xferX, h, selected, containers, activeCol, barH, xferW)
    end

    -- Draw container bar AFTER columns so hit zones survive clearHitZones
    if showBar then renderContainerBar(self) end

    -- the Filter bar over every column and the transfer strips between them
    filterEnd(self)
    self._fres = nil

    -- Reset transient fields
    self._renderXOffset     = 0
    self._renderW           = nil
    self._compactMode       = false
    self._skipClearHitZones = false
end

-- ============================================================================
-- SELECTION HELPERS
-- ============================================================================

local function countSelected(tbl)
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end

local function findIndex(flatItems, item)
    for i, v in ipairs(flatItems) do
        if v == item then return i end
    end
    return nil
end

local function collectSelectedItems(content)
    local result = {}
    for item, _ in pairs(content._selectedItems) do
        result[#result + 1] = item
    end
    return result
end

-- ============================================================================
-- DROP HANDLER
-- Resolves where dragged items land: another column, vanilla pane, a
-- container button, or (released over the world only) the floor.
-- ============================================================================

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

-- The container under the pointer on a window's container buttons, or nil.
-- The Character window names its buttons "cnt:<index>", the World window by
-- the bare index (its Floor button too). A locked container takes nothing.
local function stripDropTarget(win)
    if not win or not win._containerStrip then return nil end
    local strip = win._containerStrip
    if not strip:isMouseOver() then return nil end
    local zone = strip:hitZoneAt(strip:getMouseX(), strip:getMouseY())
    if not zone then return nil end
    local zid = zone.id
    local ci = nil
    if type(zid) == "number" then
        ci = zid
    elseif type(zid) == "string" and zid:sub(1, 4) == "cnt:" then
        ci = tonumber(zid:sub(5))
    elseif zid == "main_toggle" then
        -- the Character window's top button, the main inventory (QA's Mac run, Nov 10 2026: eight rows dropped on it
        -- moved nothing; its zone is named, not numbered)
        for i, c in ipairs(win._containers or {}) do if c.isMain then ci = i; break end end
    end
    local cnt = ci and win._containers and win._containers[ci]
    if not cnt or cnt.locked then return nil end
    return cnt.inventory
end

-- The list a release on another ZeD window's title bar lands in: the bar is all a rolled-up window has, and its
-- roll-down takes up to a tenth of a second, so the bar itself takes the drop. The same pointer test as
-- ZeD_Window:_autoCollapse. The source's own bar takes nothing, as its own list doesn't, nor a bar the source window
-- covers; a window showing no list takes nothing. A rolled World window's list doesn't refresh with its strip, so a
-- container left behind, or locked since, takes nothing either.
local function titleBarDropTarget(win, srcWin)
    if not (win and win ~= srcWin and win._contentPanel and win:getIsVisible()) then return nil end
    if win._invDrawerOpen == false then return nil end
    local px, py = getMouseX(), getMouseY()
    local function inside(w, h)
        local dx, dy = px - w:getAbsoluteX(), py - w:getAbsoluteY()
        return dx >= 0 and dx <= w:getWidth() and dy >= 0 and dy < h
    end
    if not inside(win, win:titleBarHeight()) then return nil end
    if srcWin and inside(srcWin, srcWin:shownHeight()) then return nil end
    local panel = win._contentPanel
    local cols = panel._colStates
    local last = cols and cols[#cols]
    local inv = last and last.inventory or panel._inventory
    if inv and win.windowShaded and win == ZeD_WorldWindow.getWindow(ZeD.playerNumOf(win)) and not ZeD_WorldWindow.inReach(inv, ZeD.playerNumOf(win)) then return nil end
    return inv
end

-- True when the pointer is over a window or panel that takes the mouse (as
-- vanilla's pane asks before it drops dragged items on the floor). Read once
-- per drop, never per frame. When it can't tell, it answers true: a drop that
-- does nothing beats items left on the ground.
local function pointerOverUI()
    local ok, over = pcall(function()
        local mx, my = getMouseX(), getMouseY()
        local uis = UIManager.getUI()
        for i = 0, uis:size() - 1 do
            local ui = uis:get(i)
            if ui:isPointOver(mx, my) then
                -- a see-through overlay (it lets clicks through) is not a window
                local okC, takes = pcall(function() return ui:isConsumeMouseEvents() end)
                if not okC or takes then return true end
            end
        end
        return false
    end)
    return (not ok) or over
end

--- The things a drag from a list carries: a closed stack's row is every thing in
--- the stack, as vanilla's drag moves the whole stack; an open stack's rows each
--- carry their own thing. The grid opens no stacks, so a grid cell is always the
--- whole stack. content: the list dragged from (its source column, if any, in
--- content._dragSourceCol); items: the rows dragged. Returns a new list.
local function dragItems(content, items, srcInventory)
    local cs = content._dragSourceCol and content._colStates and content._colStates[content._dragSourceCol] or nil
    local stacks = cs and cs.stacks or content._stacks
    if not stacks then return items end
    local open = (cs and cs.expandedStacks) or content._expandedStacks or {}
    local grid = ZeD.InventoryRenderer.isGridKey(containerKeyOf(srcInventory or content._inventory, content._playerObj), content._playerObj)
    local out, seen = {}, {}
    for _, item in ipairs(items) do
        local stk = stacks[item]
        local rows = (stk and stk.count > 1 and stk.items and (grid or not open[stk.key])) and stk.items or nil
        if rows then
            for _, si in ipairs(rows) do
                if not seen[si] then seen[si] = true; out[#out + 1] = si end
            end
        elseif not seen[item] then
            seen[item] = true; out[#out + 1] = item
        end
    end
    return out
end

ZeD.InventoryRenderer.dragItems = dragItems   -- (the double-click takes a closed stack the way a drag does, QA K2-8)

local function handleDrop(content, items, srcInventory)
    if not items or #items == 0 then return end
    ZeD.InventoryRenderer.dirtyModels()   -- (a drop moves things: every list model rebuilds)

    local playerObj = content._playerObj
    local playerNum = playerObj:getPlayerNum()
    local srcContainer = srcInventory or content._inventory

    -- Over a slot of the Equip tab's doll: an item that fits it is worn there
    if ZeD.EquipDoll and ZeD.EquipDoll.takeDrop then
        local ok, took = pcall(ZeD.EquipDoll.takeDrop, playerNum, items)
        if ok and took then return end
    end

    -- Over a body part or a wound row on the Health tab: the game's own treatment drop (a bandage on a wound) (QA K2-7)
    if ZeD.HealthTab and ZeD.HealthTab.takeDrop then
        local ok, took = pcall(ZeD.HealthTab.takeDrop, playerNum, items)
        if ok and took then return end
    end

    -- Over the belt (HUD): attach to a slot, equip into a hand, or into the bag button's bag (with the list and its
    -- container, so a row brings its closed stack: Belt row, Nov 23 2026). The belt
    -- answers first, or a release over it would drop the items on the floor.
    if ZeD.Belt and ZeD.Belt.takeDrop then
        local ok, took = pcall(ZeD.Belt.takeDrop, playerNum, items, content, srcContainer)
        if ok and took then return end
    end

    -- From here on the drop is a move into a container or onto the floor: a row
    -- dragged from a list carries its whole closed stack (the doll and the belt
    -- above take the one thing). An Equip slot's drag is no list's (no source set).
    if content._dragSourceInv ~= nil then items = dragItems(content, items, srcContainer) end

    -- (Nov 15 2026, add-on hooks: released over an add-on's grid, GridLayout.lua: its drop goes first; a place it
    -- refused, or a move inside the one container it took, ends the drop here)
    if ZeD.GridLayout.takeDrop(content, items, srcContainer) then return end

    -- A rolled-up side's tab (WindowCurtain) takes the drop for its container;
    -- otherwise: is the mouse over a different column (multi-column transfer)
    local destContainer = ZeD.Curtain and ZeD.Curtain.dropTarget and ZeD.Curtain.dropTarget() or nil
    local mx = content:getMouseX()
    -- A column counts only while the pointer is inside the list top to bottom too: a release above
    -- or below the window (or over another window) at a column's X must fall through to the floor
    -- and cross-window checks, not land in that column's container. (beast W1)
    local myIn = content:getMouseY()
    local dropColIdx, dropCs = nil, nil
    if myIn >= 0 and myIn < content:getHeight() then dropColIdx, dropCs = getColumnAtX(content, mx) end
    if not destContainer and dropColIdx and dropCs and dropCs.inventory ~= srcContainer then
        destContainer = dropCs.inventory
    end

    -- Check XFER button hit zone
    if not destContainer then
        local my = content:getMouseY()
        local zone = content:hitZoneAt(mx, my)
        if zone and type(zone.id) == "string" and zone.id:sub(1, 5) == "xfer:" then
            local targetColIdx = tonumber(zone.id:sub(6))
            if targetColIdx and content._colStates[targetColIdx] then
                local targetInv = content._colStates[targetColIdx].inventory
                if targetInv ~= srcContainer then
                    destContainer = targetInv
                end
            end
        end
    end

    -- Check vanilla inventory/loot pane
    if not destContainer then
        local invPage  = getPlayerInventory(playerNum)
        local lootPage = getPlayerLoot(playerNum)

        if invPage and invPage:isVisible() and invPage.inventoryPane then
            local pane = invPage.inventoryPane
            if pane:isMouseOver() then
                destContainer = pane.inventory
            end
        end

        if not destContainer and lootPage and lootPage:isVisible() and lootPage.inventoryPane then
            local pane = lootPage.inventoryPane
            if pane:isMouseOver() then
                destContainer = pane.inventory
            end
        end
    end

    -- Check cross-window ZeD drop (character <-> world)
    if not destContainer then
        -- (the dragging player's own pair: in split view another player's windows are no drop target)
        local charWin = ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(ZeD.playerNumOf(content))
        local worldWin = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(ZeD.playerNumOf(content))

        -- Content panel detection (main inventory area)
        local otherContent = nil
        if charWin and charWin._contentPanel and charWin._contentPanel ~= content then
            if charWin._contentPanel:isMouseOver() then otherContent = charWin._contentPanel end
        end
        if not otherContent and worldWin and worldWin._contentPanel and worldWin._contentPanel ~= content then
            if worldWin._contentPanel:isMouseOver() then otherContent = worldWin._contentPanel end
        end

        if otherContent then
            local localX = getMouseX() - otherContent:getAbsoluteX()
            local _, dropCs = getColumnAtX(otherContent, localX)
            if dropCs then
                destContainer = dropCs.inventory
            else
                destContainer = otherContent._inventory
            end
        end

        -- Container strip detection (waterfall sidebar — both windows)
        if not destContainer then
            destContainer = stripDropTarget(charWin) or stripDropTarget(worldWin)
        end

        -- A window's title bar: that window's list, rolled or not
        if not destContainer then
            local srcWin = (charWin and charWin._contentPanel == content and charWin)
                or (worldWin and worldWin._contentPanel == content and worldWin) or nil
            destContainer = titleBarDropTarget(charWin, srcWin) or titleBarDropTarget(worldWin, srcWin)
        end
    end

    local srcIsFloor  = srcContainer ~= nil and srcContainer:getType() == "floor"
    local destIsFloor = destContainer ~= nil and destContainer:getType() == "floor"

    -- Same container = no-op
    if destContainer and (destContainer == srcContainer or (srcIsFloor and destIsFloor)) then return end

    -- No container under the pointer. As vanilla: items fall to the floor only
    -- on a release over the world, never over a window (the source list, a
    -- tab, the card, a locked container's button), and never from the floor.
    if not destContainer and (srcIsFloor or pointerOverUI()) then return end

    -- Seated in a car, things go out to the ground only through the seat's door window when it is open, broken
    -- out or missing, as vanilla's loot pane rules (ISInventoryPane.lua ~1913-1931) (beast W5)
    if (destIsFloor or not destContainer) and not srcIsFloor and ZeD.InventoryRenderer.carWindowShut(playerObj) then return end

    -- A mod's gate refuses things put into this container (ContainerGates.lua: Immersive
    -- Searching's never-searched container, as its hasRoomFor refuses them in vanilla's lists)
    if destContainer and not destIsFloor and ZeD.ContainerGates.refuses(destContainer, playerObj) then return end

    -- (Nov 15 2026, add-on hooks: things an add-on's rule refuses stay where they are; the first reason shows once in
    -- the notice over the head, ItemRules.lua. Without a rule the same list comes back)
    items = ZeD.ItemRules.filter(items, destContainer, playerObj, srcContainer)

    for _, item in ipairs(items) do
        local cur = item:getContainer()
        if not (cur == srcContainer or (srcIsFloor and cur ~= nil and cur:getType() == "floor")) then
            -- Item moved/gone, skip
        elseif destIsFloor or not destContainer then
            -- To the floor: vanilla's drop action
            if not item:isFavorite() then
                ISInventoryPaneContextMenu.dropItem(item, playerNum)
            end
        elseif srcIsFloor then
            -- Off the floor: the World window's routing point (vanilla's transfer)
            ZeD_WorldWindow.transferFromFloor(playerObj, item, destContainer)
        elseif destContainer:isItemAllowed(item) then
            -- vanilla's own transfer time (as its loot window's drag and drop)
            local move = ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, srcContainer, destContainer)
            move._zedApart = true   -- (a drag: never part of an action's run, ZeD_PutBack.lua) (L1-3)
            ISTimedActionQueue.add(move)
        end
    end
end

-- ============================================================================
-- NO ROOM (KISS #19). While a mouse drag from a ZeD list is over a container that cannot take what it carries (not
-- enough room by weight, or the container refuses a thing), the drag chip turns the danger color and reads "No room"
-- (Molecules.DragState:drawGhost asks this each frame). The game tints such rows red during its drag; a dead drop said
-- nothing. The container under the pointer is found as the drop finds it: another column, the other window's list
-- or column, a container's button, a rolled side's tab, a window's title bar.
-- ============================================================================
local _room = { rows = nil, dest = nil, t = 0, bad = false }   -- (asked again at most every 250 ms per drag and container)
function ZeD.InventoryRenderer.dragNoRoom(pn)
    local content, drag = ZeD.GridLayout.mouseDrag(pn)
    if not (content and drag and drag.items and content._dragSourceInv ~= nil) then return false end
    local src = content._dragSourceInv
    local playerObj = content._playerObj or getSpecificPlayer(pn)
    if not playerObj then return false end
    -- the container under the pointer
    local dest = ZeD.Curtain and ZeD.Curtain.dropTarget and ZeD.Curtain.dropTarget() or nil
    if not dest then
        local mx, my = content:getMouseX(), content:getMouseY()
        if my >= 0 and my < content:getHeight() then
            local _, cs = getColumnAtX(content, mx)
            if cs then dest = cs.inventory end
        end
    end
    local charWin = ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(pn)
    local worldWin = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn)
    if not dest then
        local other = nil
        if charWin and charWin._contentPanel and charWin._contentPanel ~= content and charWin._contentPanel:isMouseOver() then
            other = charWin._contentPanel
        end
        if not other and worldWin and worldWin._contentPanel and worldWin._contentPanel ~= content and worldWin._contentPanel:isMouseOver() then
            other = worldWin._contentPanel
        end
        if other then
            local _, cs = getColumnAtX(other, getMouseX() - other:getAbsoluteX())
            dest = cs and cs.inventory or other._inventory
        end
    end
    if not dest then dest = stripDropTarget(charWin) or stripDropTarget(worldWin) end
    if not dest then
        local srcWin = (charWin and charWin._contentPanel == content and charWin)
            or (worldWin and worldWin._contentPanel == content and worldWin) or nil
        dest = titleBarDropTarget(charWin, srcWin) or titleBarDropTarget(worldWin, srcWin)
    end
    -- nothing under the pointer, the same container, or the floor: no weight limit to read here
    if not dest or dest == src or dest:getType() == "floor" then return false end
    local now = getTimestampMs()
    if _room.rows == drag.items and _room.dest == dest and now >= _room.t and now - _room.t < 250 then return _room.bad end
    local bad = false
    local total = 0
    for _, item in ipairs(dragItems(content, drag.items, src)) do
        if item:getContainer() ~= dest then
            total = total + (item:getUnequippedWeight() or 0)
            if not dest:isItemAllowed(item) then bad = true end
        end
    end
    if not bad and total > 0 and not dest:hasRoomFor(playerObj, total) then bad = true end
    _room.rows, _room.dest, _room.t, _room.bad = drag.items, dest, now, bad
    return bad
end

-- ============================================================================
-- MODULE EXPORTS
-- The rest of the public table: the Character and World windows read these,
-- the Equip tab its drops (handleDrop), and the F6 test window (TestInventory).
-- ============================================================================

--- (beast W5, QA B6-9) true when the player sits in a car and the seat's door window is shut: things then cannot go
--- out to the ground (vanilla's loot pane test, ISInventoryPane.lua ~1913-1931; its Drop option is greyed the same way).
--- A window broken out, missing or open, or no window at all, lets them out. Every way ZeD drops to the floor asks it.
function ZeD.InventoryRenderer.carWindowShut(playerObj)
    local shut = false
    pcall(function()
        local vehicle = playerObj and playerObj:getVehicle()
        if not vehicle then return end
        local door = vehicle:getPassengerDoor(vehicle:getSeat(playerObj))
        -- an open door lets things out too (vanilla's Drop option checks the door before the window)
        local dd = door and door:getDoor()
        if dd and dd:isOpen() then return end
        local windowPart = VehicleUtils.getChildWindow(door)
        -- a window part with a pane in it (not one already smashed out) that can open and is closed
        if windowPart and (not windowPart:getItemType() or windowPart:getInventoryItem()) then
            local window = windowPart:getWindow()
            if window and window:isOpenable() and not window:isOpen() then shut = true end
        end
    end)
    return shut
end

ZeD.InventoryRenderer.renderItemList            = renderItemList
ZeD.InventoryRenderer.renderMultiColumnContent   = renderMultiColumnContent
ZeD.InventoryRenderer.makeSorter                 = makeSorter
ZeD.InventoryRenderer.SORT_COLS                  = SORT_COLS
ZeD.InventoryRenderer.countSelected              = countSelected
ZeD.InventoryRenderer.findIndex                  = findIndex
ZeD.InventoryRenderer.collectSelectedItems       = collectSelectedItems
ZeD.InventoryRenderer.handleDrop                 = handleDrop
ZeD.InventoryRenderer.dragItems                  = dragItems
ZeD.InventoryRenderer.buildContainers            = buildContainers
ZeD.InventoryRenderer.rebuildColStates           = rebuildColStates
ZeD.InventoryRenderer.syncColStates              = syncColStates
ZeD.InventoryRenderer.toggleContainer            = toggleContainer
ZeD.InventoryRenderer.getColumnAtX               = getColumnAtX
ZeD.InventoryRenderer.MIN_COL_W                  = MIN_COL_W
ZeD.InventoryRenderer.COMFORT_COL_W              = COMFORT_COL_W
ZeD.InventoryRenderer.getXferW                   = getXferW
-- (Nov 15 2026, add-on hooks: GridLayout.lua draws an add-on's cells and headings with the grid's own parts)
ZeD.InventoryRenderer._drawGridCell              = drawGridCell
ZeD.InventoryRenderer._drawCatRow                = drawCatRow
ZeD.InventoryRenderer._containerKeyOf            = containerKeyOf
