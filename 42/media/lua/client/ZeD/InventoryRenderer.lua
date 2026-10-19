-- ZeD-UI/42/media/lua/client/ZeD/InventoryRenderer.lua
-- ============================================================================
-- INVENTORY RENDERER — shared module consumed by CharacterWindow + WorldWindow.
-- Extracted from TestInventory.lua.
--
-- 11 exports: renderItemList, renderMultiColumnContent, makeSorter, SORT_COLS,
-- countSelected, findIndex, collectSelectedItems, handleDrop, buildContainers,
-- rebuildColStates, toggleContainer
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_Panel"

ZeD = ZeD or {}

-- ============================================================================
-- SORT COMPARATORS
-- Each returns a comparator function for table.sort.
-- "name" is the default — items grouped by category, sorted by name within.
-- Other columns sort flat (no grouping).
-- ============================================================================

local SORT_COLS = {"name", "cat", "cond", "wt"}
ZeD.InventoryRenderer = {}  -- shared module, consumed by ZeD_CharacterWindow

local function getCondPct(item)
    local mx = item:getConditionMax()
    if not mx or mx <= 0 then return -1 end
    return item:getCondition() / mx
end

local function makeSorter(col, asc)
    if col == "name" then
        if asc then
            return function(a, b) return (a:getName() or "") < (b:getName() or "") end
        else
            return function(a, b) return (a:getName() or "") > (b:getName() or "") end
        end
    elseif col == "cat" then
        if asc then
            return function(a, b)
                local ca, cb = a:getCategory() or "", b:getCategory() or ""
                if ca ~= cb then return ca < cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        else
            return function(a, b)
                local ca, cb = a:getCategory() or "", b:getCategory() or ""
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
-- Builds a table of player containers from main inventory + equipped bags.
-- Reused from ZeD_CharacterWindow pattern.
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
-- (director, Oct 16 2026: "bottom is the right place. less noise down
-- there"), single-container view only; the list ends above it. These helpers
-- keep renderItemList's locals unchanged (it sits at Kahlua's limit of 200
-- active locals): the row's height rides on self._ccH.
local function ccLayout(self, hdrY, barH, colW)
    self._ccH = 0
    local CTL = ZeD.ContainerControls
    if CTL and self._ccSide and not self._compactMode and hdrY > barH then
        local ok, h = pcall(CTL.layout, self, colW)
        if ok then self._ccH = h or 0 else ZeD.logOnce("ContainerControls layout", h) end
    else
        self._ccMarks = nil
        if self._cc then self._cc.layout = nil end
    end
end

local function ccDraw(self, colW, xOff)
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
-- GRID VIEW (Oct 19 2026, mockup zed_inventory_grid_v1.html; director: "Go
-- with inventory grid"). A List | Grid toggle in each column's heading; the
-- list stays the default. The choice is remembered per container (the fridge
-- set to grid opens as a grid next time), in the character's mod data. The
-- grid shows the list's own order: no sorting of its own. Cells register the
-- item itself as their hit zone, so selecting, dragging and the item's menu
-- work exactly as on a row.
-- ============================================================================
local GRID_CELL, GRID_GAP = 52, 4
local GRID_HINT_MS = 450

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

local function gridStore()
    local p = getPlayer and getPlayer()
    if not p then return nil end
    local md = p:getModData()
    md.ZeD_GridViews = md.ZeD_GridViews or {}
    return md.ZeD_GridViews
end

-- a container's own choice (its List | Grid toggle), else the ZeD option "Inventory"
function ZeD.InventoryRenderer.isGridKey(key)
    local s = key and gridStore()
    if s and s[key] ~= nil then return s[key] == true end
    local o = ZeD.Settings and ZeD.Settings.inventoryViewOption
    local ok, v = pcall(function() return o and o:getValue() end)
    return ok and v == 2
end

function ZeD.InventoryRenderer.setGridKey(key, on)
    local s = key and gridStore()
    if s then s[key] = on and true or false end   -- (false: this one a list, whatever the option says)
end

-- a toggle zone was clicked: "view:list:<key>" / "view:grid:<key>"
function ZeD.InventoryRenderer.onViewZone(zid)
    local view, key = tostring(zid):match("^view:(%a+):(.*)$")
    if not (view and key) then return end
    ZeD.InventoryRenderer.setGridKey(key, view == "grid")
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)
end

-- The toggle's controller elements for a column (each builder appends them):
-- rects stamped by the renderer in panel coords; A picks the view.
function ZeD.InventoryRenderer.toggleElements(rects)
    local els = {}
    for _, r in ipairs(rects or {}) do
        els[#els + 1] = {
            x = r.x, y = r.y, w = r.w, h = r.h,
            id = "view:" .. r.view .. ":" .. tostring(r.key),
            isViewToggle = true, view = r.view, key = r.key,
            onFocus = function(w, el) end,
            onActivate = function(w, el) ZeD.InventoryRenderer.setGridKey(el.key, el.view == "grid") end,
        }
    end
    return els
end

local GRID_ICONS = {}
local function gridIcon(name)
    if GRID_ICONS[name] == nil then GRID_ICONS[name] = getTexture("media/textures/ZeD/icons/" .. name .. ".png") or false end
    return GRID_ICONS[name] or nil
end

-- is this item the controller's focused element in an inventory zone? (the
-- rows' own test, shared with the grid's cells)
local function gpFocusedItem(item)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
    local zone   = (focWin and Focus.getFocusedZone) and Focus.getFocusedZone(focWin) or nil
    local zname  = zone and zone.zone or ""
    local isInvZone = zname == "charMainInv" or zname == "worldMainInv"
                   or (zname:match("^worldMC%d+$") ~= nil) or (zname:match("^charMC%d+$") ~= nil)
    local focEl = focWin and Focus.getFocusedElement and Focus.getFocusedElement(focWin) or nil
    return isInvZone and focEl ~= nil and focEl.item == item
end

local function gpFocusedToggle(id)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
    local focEl = focWin and Focus.getFocusedElement and Focus.getFocusedElement(focWin) or nil
    return focEl ~= nil and focEl.isViewToggle and focEl.id == id
end

-- The grid's state for one column (renderItemList keeps it in one table GV)
local function gridState(self, inv, playerObj, colW, scrollW, padX, childParent)
    local T = ZeD.T
    local GV = { key = containerKey(inv, playerObj), toggles = {}, child = childParent }
    GV.on   = ZeD.InventoryRenderer.isGridKey(GV.key)
    GV.cell = T.px(GRID_CELL)
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

-- List | Grid: two joined icon buttons ending at column-local x `right`, in
-- the column heading (top barH, height areaH). Stamps GV.toggles (panel
-- coords) and the hint candidate. Returns the width taken (with its gap).
local function drawViewToggle(self, GV, xOff, right, barH, areaH, padX)
    if not GV.key then return 0 end
    local T = ZeD.T
    local bw, bh = T.px(22), T.px(18)
    local tW = bw * 2 - T.px(1)
    local tx = xOff + right - tW
    local ty = barH + math.floor((areaH - bh) / 2)
    local mx, my = self:getMouseX(), self:getMouseY()
    local ac = T.accent
    for i, v in ipairs({ "list", "grid" }) do
        local zx = tx + (i - 1) * (bw - T.px(1))
        local on = (v == "grid") == (GV.on and true or false)
        local bg = on and ac or T.surf2
        self:drawRect(zx, ty, bw, bh, 1, bg.r, bg.g, bg.b)
        local br = on and T.accentBright or T.borderS
        self:drawRectBorder(zx, ty, bw, bh, br.a or 1, br.r, br.g, br.b)
        local isz = T.px(11)
        ZeD.Atoms.drawIcon(self, gridIcon(v == "list" and "list" or "apps"), zx + math.floor((bw - isz) / 2),
            ty + math.floor((bh - isz) / 2), isz, 1, on and T.textOnAccent or T.textDim)
        local id = "view:" .. v .. ":" .. GV.key
        local over = mx >= zx and mx < zx + bw and my >= ty and my < ty + bh
        if gpFocusedToggle(id) then self:drawRect(zx, ty, bw, bh, 0.55, ac.r, ac.g, ac.b)
        elseif over and not on then self:drawRect(zx, ty, bw, bh, 0.22, ac.r, ac.g, ac.b) end
        if over then self._gridHintCand = { key = id, text = (v == "list") and "List view" or "Grid view", x = zx, y = ty + bh + T.px(4), below = true } end
        GV.toggles[#GV.toggles + 1] = { x = zx, y = ty, w = bw, h = bh, view = v, key = GV.key, id = id }
    end
    return tW + padX
end

-- One cell: the icon, the stack's weight top right, its count bottom right, a
-- condition line along the bottom, a BELT n badge; hover 0.22, selected
-- deeper with the icon darkened (System 7's selected icon), the controller's
-- focus 0.55. Its hit zone is the item itself, as a row's is.
local function drawGridCell(self, GV, item, cx, cy)
    local T = ZeD.T
    local cell, xOff = GV.cell, GV.xOff
    GV.ymap[item] = cy
    GV.xmap[item] = xOff + cx
    if cy + cell <= GV.top or cy >= GV.h then return end
    local ax = xOff + cx
    local ac, bs = T.accent, T.borderS
    self:drawRect(ax, cy, cell, cell, 0.04, 1, 1, 1)
    self:drawRectBorder(ax, cy, cell, cell, bs.a or 1, bs.r, bs.g, bs.b)
    local isSelected = GV.sel and GV.sel[item]
    if isSelected then self:drawRect(ax, cy, cell, cell, 0.36, ac.r, ac.g, ac.b) end
    if self._ccMarks and ccMarked(self, item) then self:drawRect(ax, cy, cell, cell, 0.22, ac.r, ac.g, ac.b) end
    local stackInfo = self._stacks and self._stacks[item]
    local count = (stackInfo and stackInfo.count) or 1
    local tex = item:getTex()
    local isz = math.floor(cell * 32 / 52)
    if tex then
        local tint = isSelected and 0.7 or 1
        self:drawTextureScaledAspect(tex, ax + math.floor((cell - isz) / 2), cy + math.floor((cell - isz) / 2), isz, isz, 1, tint, tint, tint)
    end
    -- the weight of the cell (the whole stack), top right
    local wt = 0
    if stackInfo and stackInfo.items then
        for _, si in ipairs(stackInfo.items) do wt = wt + (si:getUnequippedWeight() or 0) end
    else wt = item:getUnequippedWeight() or 0 end
    local wtStr = string.format("%.1f", wt)
    local f5 = T.fontF5
    local wtw = ZeD.TM:MeasureStringX(f5, wtStr)
    self:drawRect(ax + cell - wtw - T.px(5), cy + T.px(1), wtw + T.px(4), GV.f5FH, 0.55, 0, 0, 0)
    local th = T.toneHi
    self:drawText(wtStr, ax + cell - wtw - T.px(3), cy + T.px(1), th.r, th.g, th.b, th.a or 1, f5)
    -- the count, bottom right
    if count > 1 then
        local cs = "x" .. count
        local f1 = T.fontF1
        local cw2 = ZeD.TM:MeasureStringX(f1, cs)
        local cy2 = cy + cell - GV.secFH - T.px(4)
        self:drawRect(ax + cell - cw2 - T.px(5), cy2, cw2 + T.px(4), GV.secFH, 0.65, 0, 0, 0)
        local tc = T.text
        self:drawText(cs, ax + cell - cw2 - T.px(3), cy2, tc.r, tc.g, tc.b, tc.a or 1, f1)
    end
    -- on the belt: its key, top left (the list's BELT n tag)
    local okAS, aslot = pcall(function() return item:getAttachedSlot() end)
    if okAS and aslot and aslot > 0 and ZeD.Belt and ZeD.Belt.keyLabel then
        local k = tostring(ZeD.Belt.keyLabel(aslot) or aslot)
        local kw = math.max(ZeD.TM:MeasureStringX(f5, k) + T.px(6), GV.f5FH)
        self:drawRect(ax, cy, kw, GV.f5FH, ac.a or 1, ac.r, ac.g, ac.b)
        local tc = T.textOnAccent
        self:drawText(k, ax + math.floor((kw - ZeD.TM:MeasureStringX(f5, k)) / 2), cy, tc.r, tc.g, tc.b, 1, f5)
    end
    -- condition, a line along the bottom (the list's colours)
    local condMax = item:getConditionMax()
    if condMax and condMax > 0 then
        local f = math.max(0, math.min(1, item:getCondition() / condMax))
        local bx, by, bw2 = ax + T.px(3), cy + cell - T.px(3), cell - T.px(6)
        self:drawRect(bx, by, bw2, T.px(2), 1, 0.047, 0.047, 0.047)
        local fc = (f > 0.6 and T.positive) or (f > 0.3 and T.warning) or T.danger
        local fw = math.floor(bw2 * f)
        if fw > 0 then self:drawRect(bx, by, fw, T.px(2), fc.a or 1, fc.r, fc.g, fc.b) end
    end
    -- pointer (0.22, and its name in a hint) / the controller (0.55)
    local over = GV.mouseIn and GV.lmx >= cx and GV.lmx < cx + cell and GV.my >= cy and GV.my < cy + cell
                 and GV.my >= GV.top and GV.my < GV.top + GV.visH
    if gpFocusedItem(item) then
        self:drawRect(ax, cy, cell, cell, 0.55, ac.r, ac.g, ac.b)
    elseif over then
        self:drawRect(ax, cy, cell, cell, 0.22, ac.r, ac.g, ac.b)
    end
    if over then
        local nm = item:getName() or "?"
        if count > 1 then nm = nm .. " x" .. count end
        self._gridHintCand = { key = item, text = nm, x = ax, y = cy }
    end
    self:addHitZone(item, ax, cy, cell, cell)
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

-- The column's heading: the container's icon and name on the left; its
-- weight over its item count on the right, the List | Grid toggle left of them.
-- (Moved out of renderItemList, Oct 19 2026: in -debug the game's compiler
-- keeps every local a function declares, block or not, and stops at 200;
-- renderItemList stood at 193.)
local function drawColumnHeading(self, GV, xOff, colW, barH, hdrY, padX, secFH, f5FH)
    local ci = self._containerInfo
    if not ci then return end
    local T = ZeD.T
    local infoAreaH = hdrY - barH
    -- Right: 2-row stack — weight (F1 hi) over count (F5 norm)
    local wtStr  = ci.stats or ""
    local cntStr = ci.count  or ""
    local wtW    = ZeD.TM:MeasureStringX(T.fontF1, wtStr)
    local cntW   = ZeD.TM:MeasureStringX(T.fontF5, cntStr)
    local stackW = math.max(wtW, cntW)
    local gap    = T.px(2)
    local stackH = secFH + gap + f5FH
    local stackY = barH + math.floor((infoAreaH - stackH) / 2)
    local htc    = T.toneHi
    local ntc    = T.toneNorm
    self:drawText(wtStr,  xOff + colW - wtW  - padX, stackY,               htc.r, htc.g, htc.b, htc.a, T.fontF1)
    self:drawText(cntStr, xOff + colW - cntW - padX, stackY + secFH + gap, ntc.r, ntc.g, ntc.b, ntc.a, T.fontF5)
    -- List | Grid, left of the weight (the zones go in after the hit zones are cleared)
    stackW = stackW + drawViewToggle(self, GV, xOff, colW - stackW - padX * 2, barH, infoAreaH, padX)
    -- Left: icon + name (F4 norm), vertically centred in info area
    local f4FH  = ZeD.TM:getFontHeight(T.fontF4)
    local nameY = barH + math.floor((infoAreaH - f4FH) / 2)
    local cx    = padX
    if ci.texture then
        ZeD.Atoms.drawIcon(self, ci.texture, xOff + cx, nameY, f4FH, 1, T.iconWhite)
        cx = cx + f4FH + T.sp.iconGap
    end
    local maxNameW = colW - stackW - cx - padX * 2
    if maxNameW > 0 then
        local name = ZeD.Atoms.truncateText(ci.name or "", T.fontF4, maxNameW)
        self:drawText(name, xOff + cx, nameY, ntc.r, ntc.g, ntc.b, ntc.a, T.fontF4)
    end
end

-- The grid by category: each category's heading (as the list's: fold on a
-- click) and its cells. Returns the y after them.
local function drawGridGroups(self, GV, catOrder, groups, collapsed, stackedGroups, y, scrollX, catHdrH)
    local T = ZeD.T
    local xOff = GV.xOff
    local s2 = T.surf2
    for _, cat in ipairs(catOrder) do
        local isClosed = collapsed[cat]
        if y + catHdrH > GV.top and y < GV.h then
            if GV.mouseIn and GV.my >= y and GV.my < y + catHdrH and GV.lmx < scrollX then
                self:drawRect(xOff, y, scrollX, catHdrH, 0.06, T.text.r, T.text.g, T.text.b)
            else
                self:drawRect(xOff, y, scrollX, catHdrH, s2.a, s2.r, s2.g, s2.b)
            end
            ZeD.Atoms.drawSecondary(self, (isClosed and "> " or "v ") .. string.upper(cat) .. " (" .. #groups[cat] .. ")",
                xOff + GV.padX + T.px(2), y + math.floor((catHdrH - GV.secFH) / 2), T.toneLo)
            ZeD.Atoms.drawDividerH(self, xOff, y + catHdrH - T.px(1), scrollX, false)
            self:addHitZone("cat:" .. cat, xOff, y, scrollX, catHdrH)
        end
        y = y + catHdrH
        if not isClosed then y = drawGridList(self, GV, stackedGroups[cat], y) end
    end
    return y
end

-- the List | Grid toggle's hit zones (after the column clears its zones)
local function addToggleZones(self, GV)
    for _, r in ipairs(GV.toggles) do self:addHitZone(r.id, r.x, r.y, r.w, r.h) end
end

-- the grid's column bar: no columns to sort by, it names the list's order
local function drawGridOrder(self, x, y, w, sortCol)
    local T = ZeD.T
    local names = { name = "NAME", cat = "CATEGORY", cond = "CONDITION", wt = "WEIGHT" }
    local lbl = "ORDER: " .. (names[sortCol] or "NAME") .. ", AS THE LIST"
    local tc = T.toneLo or T.textDim
    self:drawText(ZeD.Atoms.truncateText(lbl, T.fontF5, w), x, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF5)
end

-- A grid cell (its item's name) or the List | Grid toggle names itself after
-- a pause, in the container buttons' hint look (drawn last, over the column)
local function drawGridHint(self, GV, xOff, colW, contentTop)
    local T = ZeD.T
    local hc = self._gridHintCand
    if not hc then
        if self._gridHintCol == xOff then self._gridHintKey = nil end
        return
    end
    local now = getTimestampMs()
    if self._gridHintKey ~= hc.key then
        self._gridHintKey, self._gridHintSince, self._gridHintCol = hc.key, now, xOff
        return
    end
    if now - (self._gridHintSince or now) < GRID_HINT_MS then return end
    local f2 = T.fontF2
    local hpx, hpy = T.px(10), T.px(4)
    local tw = ZeD.TM:MeasureStringX(f2, hc.text)
    local bw, bh = tw + hpx * 2, ZeD.TM:getFontHeight(f2) + hpy * 2
    local hx = math.max(xOff + T.px(2), math.min(hc.x, xOff + colW - bw - T.px(2)))
    local hy = hc.below and hc.y or (hc.y - bh - T.px(4))
    if not hc.below and hy < contentTop then hy = hc.y + GV.cell + T.px(4) end
    local s2, bs, tc = T.surf2, T.borderS, T.text
    self:drawRect(hx + T.px(2), hy + T.px(2), bw, bh, 0.5, 0, 0, 0)
    self:drawRect(hx, hy, bw, bh, 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(hx, hy, bw, bh, bs.a, bs.r, bs.g, bs.b)
    self:drawText(hc.text, hx + hpx, hy + hpy, tc.r, tc.g, tc.b, tc.a or 1, f2)
end

local function renderItemList(self)
    local T  = ZeD.T
    local A  = ZeD.Atoms

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
    local padX     = T.sp.sm            -- 8px  — left/right inset
    local rowH     = T.rowH             -- 26px (small) / 32px (large)
    local catHdrH  = T.sp.catHdrH       -- category group label row
    local colHdrH  = T.sp.colHdrH       -- column header bar
    local iconW    = rowH - T.px(8)           -- item icon square (closer to text height)
    local iconGap  = T.sp.iconGap       -- 6px  — icon → name gap
    local scrollW  = T.sp.scrollbarW    -- 14px — reserved for scrollbar
    local scale    = T.scale or 1.0     -- text scale factor
    local st       = T.stripe           -- alternating row shading

    -- Column widths: user-resizable with scale-aware defaults
    -- Reset to defaults when text scale changes
    local colWData = self._colWidths
    if not colWData or self._colWidthsScale ~= scale then
        -- measured, not guessed (Oct 19 2026, Large text audit): the longest
        -- common category ("Literature") and a weight in the columns' own
        -- fonts, so Large shows "Literature" whole, not "Liter..."
        colWData = {
            cat  = math.ceil(math.min(ZeD.TM:MeasureStringX(T.fontF1, "Literature"), T.px(96)) + padX * 2),
            cond = math.floor(50 * scale),
            wt   = math.ceil(ZeD.TM:MeasureStringX(T.fontF3, "88.8") + padX * 2),
        }
        self._colWidths = colWData
        self._colWidthsScale = scale
    end

    -- Responsive columns: drop one at a time as panel narrows
    -- Order: cond first, then cat. Name + WT always stay.
    local nameX    = padX + iconW + iconGap
    local MIN_NAME = T.px(100)   -- (Large text audit: names before categories; at Large the category drops before names crush)
    local catColW  = colWData.cat
    local condColW = colWData.cond
    local wtColW   = colWData.wt
    local showCond = true
    local showCat  = true

    -- Force compact in multi-column: NAME + WT only
    if self._compactMode then
        showCond = false
        condColW = 0
        showCat  = false
        catColW  = 0
        wtColW   = math.ceil(ZeD.TM:MeasureStringX(T.fontF3, "88.8") + padX * 2)
    else
        if (colW - nameX - catColW - condColW - wtColW - padX - scrollW) < MIN_NAME then
            showCond = false
            condColW = 0
            if (colW - nameX - catColW - wtColW - padX - scrollW) < MIN_NAME then
                showCat = false
                catColW = 0
            end
        end
    end

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
    local hdrY    = barH + ((type(hdrYOff) == "number") and hdrYOff or 0)

    -- Container buttons: their row sits at the bottom; the list ends above it
    ccLayout(self, hdrY, barH, colW)

    -- --------------------------------------------------------
    -- PRE-COMPUTE: Build item list + determine scroll state
    -- --------------------------------------------------------

    local groups    = {}
    local catOrder  = {}
    local flatItems = {}

    local inv = self._inventory
    -- Hide equipped items from player's main inventory (shown in Equipment tab)
    local playerObj = self._playerObj
    local isPlayerInv = playerObj and inv and inv == playerObj:getInventory()
    if inv then
        local items = inv:getItems()
        if items then
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                if item and not item:isHidden() then
                    -- Skip equipped/worn items in player inventory
                    local skip = false
                    if isPlayerInv then
                        local okE, eq = pcall(function() return item:isEquipped() end)
                        if okE and eq then skip = true end
                        if not skip and playerObj then
                            local okP, peq = pcall(function() return playerObj:isEquipped(item) end)
                            if okP and peq then skip = true end
                        end
                    end
                    if not skip then
                        local cat = item:getCategory() or "Other"
                        if not groups[cat] then
                            groups[cat] = {}
                            catOrder[#catOrder + 1] = cat
                        end
                        groups[cat][#groups[cat] + 1] = item
                    end
                end
            end
        end
    end

    local sortCol  = self._sortCol or "name"
    local sortAsc  = self._sortAsc
    local sorter   = makeSorter(sortCol, sortAsc)
    local useGroups = (sortCol == "name" or sortCol == "cat")
    local collapsed = self._collapsedGroups

    -- S100: item stacking. Group items by fullType within each category;
    -- identical items collapse into one row with a count badge. Expanded
    -- stacks show child rows indented beneath the header. Vanilla PZ UX.
    self._expandedStacks = self._expandedStacks or {}
    local expandedStacks = self._expandedStacks
    local stacks = {}          -- rep item → stack info
    local childParent = {}     -- child item → stack info

    -- Build one stack per (cat, fullType); emit representative + optional
    -- children into flatItems in render order.
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
        for _, s in ipairs(ordered) do
            flatItems[#flatItems + 1] = s.rep
            stacks[s.rep] = s
            if s.count > 1 and expandedStacks[s.key] then
                for ci = 2, #s.items do
                    flatItems[#flatItems + 1] = s.items[ci]
                    childParent[s.items[ci]] = s
                end
            end
        end
    end

    -- S100: stacked per-category iteration list for the useGroups draw path.
    -- The draw loop iterates per-cat; without this the original unstacked
    -- groups[cat] would be used, bypassing stacking entirely.
    local stackedGroups = {}

    local catRowCount = {}  -- cat → rendered row count (stacks + expanded children)
    if useGroups then
        if sortCol == "cat" and not sortAsc then
            table.sort(catOrder, function(a, b) return a > b end)
        else
            table.sort(catOrder)
        end
        for _, cat in ipairs(catOrder) do
            table.sort(groups[cat], sorter)
            if not collapsed[cat] then
                local before = #flatItems
                emitStacks(groups[cat])
                catRowCount[cat] = #flatItems - before
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
                all[#all + 1] = item
            end
        end
        table.sort(all, sorter)
        emitStacks(all)
    end

    self._flatItems      = flatItems
    self._invRowItems    = flatItems   -- S96: alias for focusable builder (external consumers)
    self._useGroups      = useGroups
    self._groups         = groups
    self._stackedGroups  = stackedGroups
    self._catOrder       = catOrder
    self._stacks         = stacks
    self._childParent    = childParent

    -- GRID: this container's view, and the cells' layout (a stack is one cell;
    -- its children are never shown apart, as the card covers the stack)
    -- (one table: renderItemList sits near Kahlua's 200-local limit; the grid's
    -- drawing lives in drawGridList / drawViewToggle, outside this function)
    self._gv = gridState(self, inv, playerObj, colW, scrollW, padX, childParent)

    local totalContentH = 0
    if useGroups then
        for _, cat in ipairs(catOrder) do
            totalContentH = totalContentH + catHdrH
            if self._gv.on then
                totalContentH = totalContentH + gridH(self._gv, gridCount(self._gv, stackedGroups[cat]))
            else
                totalContentH = totalContentH + (catRowCount[cat] or 0) * rowH
            end
        end
    else
        totalContentH = self._gv.on and gridH(self._gv, gridCount(self._gv, flatItems)) or (#flatItems * rowH)
    end

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
    -- COLUMN HEADER BAR
    -- --------------------------------------------------------
    local surf2 = T.surf2
    dR(0, hdrY, colW, colHdrH, surf2.a, surf2.r, surf2.g, surf2.b)

    local hdrTextY = hdrY + math.floor((colHdrH - f5FH) / 2)

    local colDefs = {
        {"NAME", "name", nameX, 0, catX},
    }
    if showCat then
        colDefs[#colDefs + 1] = {"CAT",  "cat",  catX + padX,  catX,   catColW}
    end
    if showCond then
        colDefs[#colDefs + 1] = {"COND", "cond", condX + padX, condX,  condColW}
    end
    colDefs[#colDefs + 1] = {"WT",   "wt",   wtX + padX,   wtX,    wtColW}
    -- the grid has no columns to sort by: the bar names the list's order it shows
    if self._gv.on then
        drawGridOrder(self, xOff + padX, hdrTextY, colW - padX * 2, sortCol)
        colDefs = {}
    end

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
        dT(label, drawX, hdrTextY, color.r, color.g, color.b, color.a, T.fontF5)
        -- Under/overline active sort column (System 7 style)
        if isActive then
            local labelW = ZeD.TM:MeasureStringX(T.fontF5, label)
            if sortAsc then
                dR(drawX, hdrTextY + f5FH, labelW, T.px(1), color.a, color.r, color.g, color.b)
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
        if not divHover then
            for _, def in ipairs(colDefs) do
                local hitX, hitW = def[4], def[5]
                if localMx >= hitX and localMx < hitX + hitW then
                    dR(hitX, hdrY, hitW, colHdrH, 0.04, T.text.r, T.text.g, T.text.b)
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

    -- S96 SCROLL-FOLLOW: if a gamepad-focused row exists, ensure it's
    -- visible before computing the scroll offset. Uses the item's
    -- render Y stamped into `self._itemRenderYMap` during the PREVIOUS
    -- frame's draw loop. One-frame lag is imperceptible (focus changes
    -- are user-initiated).
    -- NOTE: cannot stamp directly on Java item objects (Kahlua throws
    -- "attempted index of non-table"), so we use a Lua-side map table.
    --
    -- S103 DELTA GATE: `_gpFocusedRowItem` is sticky across mode switches
    -- (cleared only on tab-switch or window unclaim). Previous frames would
    -- re-pin scroll every tick whenever the focused row drifted out of
    -- view — e.g. when a KBM user scrolled the mousewheel past it. A mode
    -- gate (getMode() == "gamepad") didn't help because the detector
    -- oscillates kbm↔gamepad within consecutive frames (see console log).
    -- Fix: only pin scroll when the focused item actually CHANGED this
    -- render. Cached in `_lastPinnedRowItem`. Works regardless of input
    -- mode: gamepad D-pad changes focus → one pin fires → stops. KBM user
    -- scrolls past the pinned row → focus unchanged → no re-pin.
    local itemRenderYMap = self._itemRenderYMap or {}
    if self._gpFocusedRowItem
       and self._gpFocusedRowItem ~= self._lastPinnedRowItem
       and totalContentH > visibleH then
        local focY = itemRenderYMap[self._gpFocusedRowItem]
        if focY then
            -- focY is the absolute y from last frame's draw. Convert to
            -- logical offset: logical = y - contentTop + scrollOffset_old.
            -- But we don't have scrollOffset_old yet. Instead, use the
            -- stable relationship: renderY = contentTop + logicalY - scrollOffset.
            -- => logicalY = focY - contentTop + old scrollOffset.
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
    if self._ccH > 0 then ZeD.ContainerControls.addZones(self) end
    -- the List | Grid toggle (its rects are panel coords already)
    addToggleZones(self, self._gv)

    self:setStencilRect(xOff, contentTop, scroll.visible and (colW - scrollW) or colW, visibleH)

    local y      = contentTop - scrollOffset
    local rowIdx = 0

    local selectedItems = self._selectedItems

    -- Shared row drawing function
    local function drawItemRow(item)
        -- S96: stamp render Y into the panel-level map for scroll-follow
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

        -- Selected row bg
        local isSelected = selectedItems[item]
        if isSelected then
            local ac = T.accent
            dR(0, y, scrollX, rowH, T.selectionA, ac.r, ac.g, ac.b)
            if self._drag and self._drag:isActive() then
                local s1 = T.surf1
                dR(0, y, scrollX, rowH, 0.4, s1.r, s1.g, s1.b)
            end
        end

        -- Container buttons: rows a pointed-at Same type button would move
        if self._ccMarks and ccMarked(self, item) then
            dR(0, y, scrollX, rowH, 0.22, T.accent.r, T.accent.g, T.accent.b)
        end

        -- S96: gamepad-focused row accent fill (0.55 alpha, matches
        -- active tab/container grammar). Drawn AFTER selection bg so
        -- accent overlays when both mouse-selected + gamepad-focused.
        -- S100: gated on the currently-focused ring zone being a mainInv
        -- zone, so the cue clears when LB/RB bumpers to another zone
        -- (only the focused zone shows its active item).
        if item == self._gpFocusedRowItem then
            local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
            local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
            local zone   = (focWin and Focus.getFocusedZone) and Focus.getFocusedZone(focWin) or nil
            local zname  = zone and zone.zone or ""
            -- S106 / S108 v2: mainInv + per-column MC zones (charMC1..N,
            -- worldMC1..N) accepted as focus-paint zones. Old single
            -- charLootMCColumns / worldLootMCColumns zones removed in S108 v2.
            -- Item identity unique per Java object so no extra disambiguation.
            local isInvZone = zname == "charMainInv" or zname == "worldMainInv"
                           or (zname:match("^worldMC%d+$") ~= nil)
                           or (zname:match("^charMC%d+$") ~= nil)
            -- S113c: ALSO gate on the LIVE focused element's item matching
            -- this row's item. Both Char and World content panels seed
            -- `_gpFocusedRowItem` to their first row each frame, so without
            -- this cross-check both panels paint accent simultaneously even
            -- though only one window owns gamepad focus. The live focused
            -- element is unique per session — so painting on item-match
            -- naturally restricts the cue to the one actually-focused row.
            local focEl    = focWin and Focus.getFocusedElement and Focus.getFocusedElement(focWin) or nil
            local liveItem = focEl and focEl.item or nil
            if isInvZone and liveItem == item then
                local ac = T.accent
                dR(0, y, scrollX, rowH, 0.55, ac.r, ac.g, ac.b)
            end
        end

        -- S100 stacking: detect this row's stack role. Stack header shows
        -- a chevron + count badge; child is drawn indented; single items
        -- render as before.
        local stackInfo   = self._stacks and self._stacks[item]
        local childParent = self._childParent and self._childParent[item]
        local isStackHead = stackInfo and stackInfo.count > 1
        local isChild     = childParent ~= nil
        local childIndent = isChild and T.px(10) or 0

        -- Icon (children don't show icon; stack header shows icon of rep)
        if not isChild then
            local tex = item:getTex()
            if tex then
                local iconY = y + math.floor((rowH - iconW) / 2)
                dTS(tex, padX, iconY, iconW, iconW, 1, 1, 1, 1)
            end
        end

        -- Name (truncated to column width), with stack prefix / suffix
        local textY  = y + math.floor((rowH - bodyFH) / 2)
        local nameColor = isSelected and T.toneHi or T.toneNorm
        local baseName = item:getName() or "???"
        local prefix = ""
        local suffix = ""
        if isStackHead then
            local expanded = self._expandedStacks and self._expandedStacks[stackInfo.key]
            prefix = expanded and "v " or "> "
            suffix = " x" .. tostring(stackInfo.count)
        end
        -- a cut name keeps its end: a stack's count survives ("> Apple (Fr... x6"; Large text audit)
        local avail = nameW - childIndent
        local displayName = prefix .. baseName .. suffix
        if suffix ~= "" and ZeD.TM:MeasureStringX(T.fontF2, displayName) > avail then
            displayName = truncateText(prefix .. baseName, T.fontF2, avail - ZeD.TM:MeasureStringX(T.fontF2, suffix)) .. suffix
        else
            displayName = truncateText(displayName, T.fontF2, avail)
        end
        dT(displayName, nameX + childIndent, textY,
            nameColor.r, nameColor.g, nameColor.b, nameColor.a, T.fontF2)

        -- On the belt: a BELT n tag after the name (n = the key that draws it),
        -- where vanilla puts its small hotbar icon
        local okAS, aslot = pcall(function() return item:getAttachedSlot() end)
        if okAS and aslot and aslot > 0 and ZeD.Belt and ZeD.Belt.tagFor then
            local tag = ZeD.Belt.tagFor(aslot)
            local tf = T.fontF1
            local tw = ZeD.TM:MeasureStringX(tf, tag) + T.px(8)
            local th = ZeD.TM:getFontHeight(tf) + T.px(2)
            local tx = nameX + childIndent + ZeD.TM:MeasureStringX(T.fontF2, displayName) + T.px(6)
            if tx + tw <= nameX + nameW then
                local ac = T.accent
                local ty = y + math.floor((rowH - th) / 2)
                dRB(tx, ty, tw, th, ac.a or 1, ac.r, ac.g, ac.b)
                dT(tag, tx + T.px(4), ty + T.px(1), ac.r, ac.g, ac.b, ac.a or 1, tf)
            end
        end

        local secTextY = y + math.floor((rowH - secFH) / 2)

        if showCat then
            local catLabel = truncateText(item:getCategory() or "", T.fontF1, catColW - padX * 2)
            local cc = T.toneHi
            dT(catLabel, catX + padX, secTextY, cc.r, cc.g, cc.b, cc.a, T.fontF1)
        end

        if showCond then
            local condMax = item:getConditionMax()
            if condMax and condMax > 0 then
                local condPct = math.max(0, math.min(1, item:getCondition() / condMax))
                local barX = condX + T.px(2)
                local barY = y + math.floor(rowH / 2) - T.px(1)
                local barW = condColW - T.px(4)
                local barH = T.px(3)

                local bg = T.surf3
                dR(barX, barY, barW, barH, bg.a, bg.r, bg.g, bg.b)

                local fillW = math.max(0, math.floor(barW * condPct))
                if fillW > 0 then
                    local fc
                    if condPct > 0.6 then
                        fc = T.positive
                    elseif condPct > 0.3 then
                        fc = T.warning
                    else
                        fc = T.danger
                    end
                    dR(barX, barY, fillW, barH, fc.a, fc.r, fc.g, fc.b)
                end
            end
        end

        -- Weight (K22 Xanthus — stat voice)
        local wt    = item:getUnequippedWeight()
        local wtStr = string.format("%.1f", wt)
        local wtTextY = y + math.floor((rowH - statFH) / 2)
        A.drawTextRight(self, wtStr, xOff + wtX + wtColW - padX, wtTextY, T.fontF3, T.toneHi)

        -- Hit zones: for stack headers, register chevron-area zone FIRST so
        -- it wins hit-testing for clicks on the arrow. Full-row item zone
        -- registers second for the rest of the row.
        if isStackHead then
            hZ("stack:" .. stackInfo.key, 0, y, nameX + T.px(16), rowH)
        end
        hZ(item, 0, y, scrollX, rowH)

        y      = y + rowH
        rowIdx = rowIdx + 1
    end

    -- GRID: the cells draw in drawGridList (outside this function: the local limit)
    self._gv.xOff, self._gv.padX, self._gv.top, self._gv.h, self._gv.visH = xOff, padX, contentTop, h, visibleH
    self._gv.sel, self._gv.ymap, self._gv.xmap = selectedItems, itemRenderYMap, {}
    self._gv.mouseIn, self._gv.lmx, self._gv.my, self._gv.f5FH, self._gv.secFH = mouseInCol, localMx, my, f5FH, secFH
    self._itemRenderXMap = self._gv.xmap


    if self._gv.on then
        if useGroups then
            y = drawGridGroups(self, self._gv, catOrder, groups, collapsed, stackedGroups, y, scrollX, catHdrH)
        else
            y = drawGridList(self, self._gv, flatItems, y)
        end
    elseif useGroups then
        for _, cat in ipairs(catOrder) do
            local catGroup = groups[cat]
            local isClosed = collapsed[cat]

            -- Category header row
            if y + catHdrH > contentTop and y < h then
                -- Hover highlight
                if mouseInCol and my >= y and my < y + catHdrH and localMx < scrollX then
                    dR(0, y, scrollX, catHdrH, 0.06, T.text.r, T.text.g, T.text.b)
                else
                    dR(0, y, scrollX, catHdrH, surf2.a, surf2.r, surf2.g, surf2.b)
                end

                local catLabelY = y + math.floor((catHdrH - secFH) / 2)
                local tri = isClosed and "> " or "v "
                aSec(tri .. string.upper(cat) .. " (" .. #catGroup .. ")",
                    padX + T.px(2), catLabelY, T.toneLo)
                aDiv(0, y + catHdrH - T.px(1), scrollX, false)

                hZ("cat:" .. cat, 0, y, scrollX, catHdrH)
            end
            y = y + catHdrH
            rowIdx = rowIdx + 1  -- count header row so stripe pattern stays consistent

            if not isClosed then
                -- S100: iterate the stacked row list, not raw items — stacking
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

    self:clearStencilRect()

    -- --------------------------------------------------------
    -- EMPTY STATE
    -- --------------------------------------------------------
    if #catOrder == 0 then
        local msg  = "INVENTORY EMPTY"
        local msgW = ZeD.TM:MeasureStringX(T.fontF1, msg)
        local msgX = math.floor((scrollX - msgW) / 2)
        local msgY = contentTop + math.floor((visibleH - secFH) / 2)
        aSec(msg, msgX, msgY)
    end

    -- --------------------------------------------------------
    -- SCROLLBAR (drawn in panel-absolute coords via scroll.x)
    -- --------------------------------------------------------
    scroll:draw(self)

    -- an icon's hover hint (container buttons), over everything
    if self._ccH > 0 then ccHint(self) end

    -- a grid cell (its item's name) or the List | Grid toggle names itself
    drawGridHint(self, self._gv, xOff, colW, contentTop)
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
-- S124 scale: returns DESIGN units (exported; Character/World windows wrap it in T.px)
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

    -- Background
    local bg = T.surf1
    self:drawRect(stripX, y0, sw, stripH - y0, bg.a, bg.r, bg.g, bg.b)

    -- Left/right border lines
    local brd = T.border
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
        local isHover   = mx >= btnX and mx < btnX + btnW
                          and my >= btnY and my < btnY + T.px(XFER_BTN_H)

        if isSource then
            local s2 = T.surf2
            self:drawRect(btnX, btnY, btnW, T.px(XFER_BTN_H), 0.3, s2.r, s2.g, s2.b)
        elseif isHover then
            local pos = T.positive
            self:drawRect(btnX, btnY, btnW, T.px(XFER_BTN_H), 0.15, pos.r, pos.g, pos.b)
            self:drawRectBorder(btnX, btnY, btnW, T.px(XFER_BTN_H), 0.6, pos.r, pos.g, pos.b)
        else
            local s3 = T.surf3
            self:drawRect(btnX, btnY, btnW, T.px(XFER_BTN_H), s3.a, s3.r, s3.g, s3.b)
            self:drawRectBorder(btnX, btnY, btnW, T.px(XFER_BTN_H), brd.a, brd.r, brd.g, brd.b)
        end

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

    -- Background
    local surf2 = T.surf2
    self:drawRect(0, 0, w, T.px(CONTAINER_BAR_H), surf2.a, surf2.r, surf2.g, surf2.b)

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

        local isHover = mx >= btnX and mx < btnX + btnW
                        and my >= btnY and my < btnY + T.px(CBAR_BTN_H)

        -- Draw button
        if isSel then
            local ac = T.accent
            self:drawRect(btnX, btnY, btnW, T.px(CBAR_BTN_H), 0.15, ac.r, ac.g, ac.b)
            self:drawRectBorder(btnX, btnY, btnW, T.px(CBAR_BTN_H), 0.6, ac.r, ac.g, ac.b)
        elseif isHover then
            local s3 = T.surf3
            self:drawRect(btnX, btnY, btnW, T.px(CBAR_BTN_H), s3.a, s3.r, s3.g, s3.b)
            local ac = T.accent
            self:drawRectBorder(btnX, btnY, btnW, T.px(CBAR_BTN_H), 0.3, ac.r, ac.g, ac.b)
        else
            local s3 = T.surf3
            self:drawRect(btnX, btnY, btnW, T.px(CBAR_BTN_H), 0.5, s3.r, s3.g, s3.b)
            local brd = T.borderS
            self:drawRectBorder(btnX, btnY, btnW, T.px(CBAR_BTN_H), brd.a, brd.r, brd.g, brd.b)
        end

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
            local badge = tostring(colNum)
            local ac = T.accent
            A.drawSecondary(self, badge, cx, textY, ac)
        end

        -- Hit zone
        self:addHitZone("cbar:" .. ci, btnX, btnY, btnW, T.px(CBAR_BTN_H))

        btnX = btnX + btnW + T.px(CBAR_BTN_GAP)
    end

    -- Groove divider below bar
    A.drawGroove(self, 0, T.px(CONTAINER_BAR_H) - T.px(2), w)
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

    -- Set bar height so renderItemList shifts content down.
    -- Caller can pre-set _barH = 0 to suppress the container bar (e.g. character window).
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

            -- S100: per-column stack expand state
            self._expandedStacks = cs.expandedStacks or {}
            cs.expandedStacks    = self._expandedStacks

            renderItemList(self)

            cs.flatItems       = self._flatItems
            cs.sortCol         = self._sortCol
            cs.sortAsc         = self._sortAsc
            cs.lastClickedItem = self._lastClickedItem
            cs.stacks          = self._stacks
            cs.childParent     = self._childParent
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
            local capacity = inv and inv:getMaxWeight() or 0
            local capStr   = capacity > 0 and string.format("%.1f", capacity) or "---"
            local statsStr = string.format("%.1f/%skg", weight, capStr)
            local itemCount = inv and inv:getItems():size() or 0
            local countStr  = itemCount .. " items"

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
            self._hdrYOffset        = self._defaultHdrYOffset or T.px(37)
            self._containerInfo     = {
                name    = cData.name or "???",
                stats   = statsStr,
                count   = countStr,
                texture = cData.texture,
            }
            self._colWidths      = nil
            self._colWidthsScale = nil

            -- S100: per-column stack expand state
            self._expandedStacks = cs.expandedStacks or {}
            cs.expandedStacks    = self._expandedStacks

            renderItemList(self)

            -- Save back computed data
            cs.flatItems       = self._flatItems
            cs.sortCol         = self._sortCol
            cs.sortAsc         = self._sortAsc
            cs.lastClickedItem = self._lastClickedItem
            cs.stacks          = self._stacks
            cs.childParent     = self._childParent
            -- S106: save per-column yMap so charLootMCColumns focusables can
            -- read per-row Y for cone-nav bounds. Each column's renderItemList
            -- call writes to self._itemRenderYMap; subsequent columns overwrite
            -- it. Snapshotting after each render preserves each column's stamps
            -- for the next frame's focusable builder.
            cs.itemRenderYMap  = self._itemRenderYMap
            -- the grid: each cell's x, the cell size, the List | Grid toggle (focusables read them)
            cs.itemRenderXMap  = self._itemRenderXMap
            cs.gridCell        = self._gridCell
            cs.viewToggleRects = self._viewToggleRects
        end
    end

    -- Draw XFER strips between columns
    local activeCol = self._activeCol or 1
    local barH = self._barH or 0
    for i = 1, N - 1 do
        renderXferStrip(self, layout[i].xferX, h, selected, containers, activeCol, barH, xferW)
    end

    -- Draw container bar AFTER columns so hit zones survive clearHitZones
    if showBar then renderContainerBar(self) end

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
-- Resolves where dragged items land: another column, vanilla pane, or floor.
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

local function handleDrop(content, items, srcInventory)
    if not items or #items == 0 then return end

    local playerObj = content._playerObj
    local playerNum = playerObj:getPlayerNum()
    local srcContainer = srcInventory or content._inventory

    -- Over the belt (HUD): attach to a slot or equip into a hand. The belt
    -- answers first, or a release over it would drop the items on the floor.
    if ZeD.Belt and ZeD.Belt.takeDrop then
        local ok, took = pcall(ZeD.Belt.takeDrop, playerNum, items)
        if ok and took then return end
    end

    -- Check if mouse is over a different column (multi-column transfer)
    local destContainer = nil
    local mx = content:getMouseX()
    local dropColIdx, dropCs = getColumnAtX(content, mx)
    if dropColIdx and dropCs and dropCs.inventory ~= srcContainer then
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
        local charWin = ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
        local worldWin = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()

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
            local function tryStripResolve(win)
                if not win or not win._containerStrip then return nil end
                local strip = win._containerStrip
                if not strip:isMouseOver() then return nil end
                local smx, smy = strip:getMouseX(), strip:getMouseY()
                local zone = strip:hitZoneAt(smx, smy)
                if not zone then return nil end
                local zid = zone.id
                if type(zid) == "string" and zid:sub(1, 4) == "cnt:" then
                    local ci = tonumber(zid:sub(5))
                    if ci and win._containers and win._containers[ci] then
                        return win._containers[ci].inventory
                    end
                end
                return nil
            end
            destContainer = tryStripResolve(charWin)
            if not destContainer then
                destContainer = tryStripResolve(worldWin)
            end
        end
    end

    -- Same container = no-op
    if destContainer and destContainer == srcContainer then return end

    -- Detect virtual floor container (can't use ISInventoryTransferAction with it)
    local floorContainer = ZeD_WorldWindow.getFloorContainer and ZeD_WorldWindow.getFloorContainer()
    local srcIsVirtualFloor  = floorContainer and srcContainer == floorContainer
    local destIsVirtualFloor = floorContainer and destContainer == floorContainer

    for _, item in ipairs(items) do
        if item:getContainer() ~= srcContainer then
            -- Item moved/gone, skip
        elseif destIsVirtualFloor then
            -- Dropping TO floor — use vanilla drop action (floor container is virtual)
            if not item:isFavorite() then
                ISInventoryPaneContextMenu.dropItem(item, playerNum)
            end
        elseif destContainer then
            if srcIsVirtualFloor then
                ZeD_WorldWindow.transferFromFloor(playerObj, item, destContainer)
            elseif destContainer:isItemAllowed(item) then
                ISTimedActionQueue.add(
                    ISInventoryTransferAction:new(playerObj, item, srcContainer, destContainer, 0)
                )
            end
        else
            if not item:isFavorite() then
                ISInventoryPaneContextMenu.dropItem(item, playerNum)
            end
        end
    end
end

-- ============================================================================
-- SHARED MODULE EXPORTS
-- Used by ZeD_CharacterWindow and any future inventory host.
-- ============================================================================

ZeD.InventoryRenderer.renderItemList            = renderItemList
ZeD.InventoryRenderer.renderMultiColumnContent   = renderMultiColumnContent
ZeD.InventoryRenderer.makeSorter                 = makeSorter
ZeD.InventoryRenderer.SORT_COLS                  = SORT_COLS
ZeD.InventoryRenderer.countSelected              = countSelected
ZeD.InventoryRenderer.findIndex                  = findIndex
ZeD.InventoryRenderer.collectSelectedItems       = collectSelectedItems
ZeD.InventoryRenderer.handleDrop                 = handleDrop
ZeD.InventoryRenderer.buildContainers            = buildContainers
ZeD.InventoryRenderer.rebuildColStates           = rebuildColStates
ZeD.InventoryRenderer.toggleContainer            = toggleContainer
ZeD.InventoryRenderer.getColumnAtX               = getColumnAtX
ZeD.InventoryRenderer.MIN_COL_W                  = MIN_COL_W
ZeD.InventoryRenderer.COMFORT_COL_W              = COMFORT_COL_W
ZeD.InventoryRenderer.getXferW                   = getXferW
