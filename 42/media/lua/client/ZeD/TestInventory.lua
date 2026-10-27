-- ZeD-UI/42/media/lua/client/ZeD/TestInventory.lua
-- ============================================================================
-- F6 TEST WINDOW — dev-only proving ground for InventoryRenderer.
-- Not required for production — safe to remove from Workshop builds.
-- Extracted renderer module to InventoryRenderer.lua.
-- ============================================================================

require "ZeD/InventoryRenderer"

-- Shorthand refs to renderer exports used by the test window
local buildContainers     = ZeD.InventoryRenderer.buildContainers
local rebuildColStates    = ZeD.InventoryRenderer.rebuildColStates
local toggleContainer     = ZeD.InventoryRenderer.toggleContainer
local renderMultiColumnContent = ZeD.InventoryRenderer.renderMultiColumnContent
local handleDrop          = ZeD.InventoryRenderer.handleDrop
local findIndex           = ZeD.InventoryRenderer.findIndex
local countSelected       = ZeD.InventoryRenderer.countSelected
local getColumnAtX        = ZeD.InventoryRenderer.getColumnAtX

local function collectFromMap(map)
    local result = {}
    for item, _ in pairs(map) do
        result[#result + 1] = item
    end
    return result
end

-- ============================================================================
-- TEST WINDOW
-- ============================================================================

local _testWin = nil

local function toggleTestInventory()
    if _testWin then
        _testWin:removeFromUIManager()
        _testWin = nil
        return
    end

    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end

    local T       = ZeD.T
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local winW    = T.px(600)
    local winH    = math.min(T.px(600), screenH - T.px(80))

    local win = ZeD_Window:new(
        screenW - winW - T.px(20), T.px(40),
        winW, winH,
        "ZeD Inventory Test"
    )
    win:initialise()
    win:addToUIManager()
    _testWin = win

    -- Content panel — ZeD_Panel, fills the window body
    local bodyY = win:getBodyY()
    local bodyH = win:getBodyHeight()

    local content = ZeD_Panel:new(0, bodyY, winW, bodyH)
    content.drawBg = false   -- (the window body is under it: one layer of see-through)
    content:initialise()
    win:addChild(content)
    win._content = content

    -- ----------------------------------------------------------------
    -- MULTI-CONTAINER STATE
    -- ----------------------------------------------------------------
    content._playerObj  = playerObj
    content._containers = buildContainers(playerObj)
    content._selectedContainers = {1}   -- start with main inventory
    content._activeCol  = 1             -- which column has focus

    -- Initialize column states
    content._colStates = {}
    rebuildColStates(content)

    -- Bind initial single-column state
    local cs = content._colStates[1]
    content._inventory       = cs.inventory
    content._selectedItems   = cs.selectedItems
    content._lastClickedItem = cs.lastClickedItem
    content._flatItems       = cs.flatItems
    content._sortCol         = cs.sortCol
    content._sortAsc         = cs.sortAsc
    content._collapsedGroups = cs.collapsedGroups
    content._scroll          = cs.scroll

    -- Column resize state (single-column only)
    content._colWidths = {
        cat  = math.floor(70 * T.scale),
        cond = math.floor(50 * T.scale),
        wt   = math.floor(40 * T.scale),
    }
    content._colDrag = nil

    -- Drag state
    local ZeD_DragState = ZeD.Molecules.DragState
    content._drag = ZeD_DragState:new()
    content._deferredSelect = nil
    content._dragSourceCol  = nil
    content._dragSourceInv  = nil

    -- Draw hooks: multi-column dispatcher replaces renderItemList
    content._onPrerender = renderMultiColumnContent
    content._onRender = function(self) self._drag:drawGhost(self) end

    -- Refresh containers periodically
    content._containerRefreshTimer = 0
    local origUpdate = content.update
    content.update = function(self)
        if origUpdate then origUpdate(self) end
        self._containerRefreshTimer = self._containerRefreshTimer + 1
        if self._containerRefreshTimer >= 30 then
            self._containerRefreshTimer = 0
            self._containers = buildContainers(self._playerObj)
            -- Re-bind inventories in case items changed
            for _, cs2 in ipairs(self._colStates) do
                if self._containers[cs2.containerIdx] then
                    cs2.inventory = self._containers[cs2.containerIdx].inventory
                end
            end
        end
    end

    -- ----------------------------------------------------------------
    -- MOUSE HANDLERS (column-aware)
    -- ----------------------------------------------------------------
    content._activeScroll = nil   -- tracks which scrollbar is being dragged

    content.onMouseDown = function(self, x, y)
        local colStates = self._colStates
        local N = #self._selectedContainers

        -- Determine which column was clicked
        local colIdx, cs2 = getColumnAtX(self, x)

        -- Check scrollbar in the clicked column
        if colIdx and cs2 then
            local scroll = cs2.scroll
            if scroll and scroll.visible
               and x >= scroll.x and x < scroll.x + scroll.width
               and y >= scroll.y then
                scroll:handleMouseDown(y - scroll.y)
                self._activeScroll = scroll
                return true
            end
            self._activeCol = colIdx
        end

        -- Hit zone lookup
        local zone = self:hitZoneAt(x, y)
        if not zone then return true end
        local zid = zone.id

        -- Container bar click — toggle container selection
        if type(zid) == "string" and zid:sub(1, 5) == "cbar:" then
            local cIdx = tonumber(zid:sub(6))
            if cIdx then
                toggleContainer(self, cIdx)
            end
            return true
        end

        -- XFER button click — transfer items from active column
        if type(zid) == "string" and zid:sub(1, 5) == "xfer:" then
            local targetColIdx = tonumber(zid:sub(6))
            local srcCol = self._activeCol or 1
            local srcCs = colStates[srcCol]
            local dstCs = colStates[targetColIdx]
            if srcCs and dstCs and srcCs ~= dstCs then
                local items = collectFromMap(srcCs.selectedItems)
                if #items > 0 then
                    handleDrop(self, items, srcCs.inventory)
                    -- Clear source selection after transfer
                    srcCs.selectedItems = {}
                    srcCs.lastClickedItem = nil
                end
            end
            return true
        end

        -- Column divider drag (single-column mode only)
        if not self._compactMode and N == 1
           and type(zid) == "string" and zid:sub(1, 4) == "div:" then
            local col = zid:sub(5)
            local colWData = self._colWidths
            if colWData and colWData[col] then
                self._colDrag = {
                    col    = col,
                    startX = getMouseX(),
                    startW = colWData[col],
                }
                self:setCapture(true)
            end
            return true
        end

        -- Column header click → toggle sort (on the clicked column's state)
        if colIdx and cs2 and type(zid) == "string" and zid:sub(1, 4) == "hdr:" then
            local col = zid:sub(5)
            if cs2.sortCol == col then
                cs2.sortAsc = not cs2.sortAsc
            else
                cs2.sortCol = col
                cs2.sortAsc = true
            end
            cs2.scroll:setScrollPos(0)
            return true
        end

        -- Category header click → toggle collapse
        if colIdx and cs2 and type(zid) == "string" and zid:sub(1, 4) == "cat:" then
            local cat = zid:sub(5)
            if cs2.collapsedGroups[cat] then
                cs2.collapsedGroups[cat] = nil
            else
                cs2.collapsedGroups[cat] = true
            end
            return true
        end

        -- Item click — selection + drag pending (on the clicked column)
        if not colIdx or not cs2 then return true end
        local item = zid
        if type(item) == "string" then return true end  -- not an item

        local selectedItems = cs2.selectedItems
        local screenX, screenY = getMouseX(), getMouseY()
        self._deferredSelect = nil
        self._dragSourceCol = colIdx
        self._dragSourceInv = cs2.inventory

        if isCtrlKeyDown() then
            if selectedItems[item] then
                selectedItems[item] = nil
            else
                selectedItems[item] = true
            end
            cs2.lastClickedItem = item
            local dragItems = collectFromMap(selectedItems)
            if #dragItems > 0 then
                self._drag:beginPending(dragItems, dragItems[1], screenX, screenY)
            end

        elseif isShiftKeyDown() and cs2.lastClickedItem then
            local flatItems = cs2.flatItems
            local fromIdx = findIndex(flatItems, cs2.lastClickedItem)
            local toIdx   = findIndex(flatItems, item)
            if fromIdx and toIdx then
                local lo = math.min(fromIdx, toIdx)
                local hi = math.max(fromIdx, toIdx)
                for idx = lo, hi do
                    selectedItems[flatItems[idx]] = true
                end
            end
            local dragItems = collectFromMap(selectedItems)
            if #dragItems > 0 then
                self._drag:beginPending(dragItems, item, screenX, screenY)
            end

        else
            if selectedItems[item] then
                self._deferredSelect = { item = item, colIdx = colIdx }
                local dragItems = collectFromMap(selectedItems)
                self._drag:beginPending(dragItems, item, screenX, screenY)
            else
                cs2.selectedItems = {[item] = true}
                cs2.lastClickedItem = item
                self._drag:beginPending({item}, item, screenX, screenY)
            end
        end

        return true
    end

    content.onMouseUp = function(self, x, y)
        if self._activeScroll then
            self._activeScroll:handleMouseUp()
            self._activeScroll = nil
        end
        if self._colDrag then
            self._colDrag = nil
            self:setCapture(false)
            return true
        end
        if self._drag:isActive() then
            local dragItems = self._drag:complete()
            handleDrop(self, dragItems, self._dragSourceInv)
            self:setCapture(false)
            self._deferredSelect = nil
            self._dragSourceCol = nil
            self._dragSourceInv = nil
            return true
        end
        if self._drag:isPending() then
            self._drag:cancel()
        end
        if self._deferredSelect then
            local def = self._deferredSelect
            self._deferredSelect = nil
            local cs2 = self._colStates[def.colIdx]
            if cs2 then
                local item = def.item
                if cs2.selectedItems[item] and countSelected(cs2.selectedItems) == 1 then
                    cs2.selectedItems = {}
                    cs2.lastClickedItem = nil
                else
                    cs2.selectedItems = {[item] = true}
                    cs2.lastClickedItem = item
                end
            end
        end
        self._dragSourceCol = nil
        self._dragSourceInv = nil
        return true
    end

    content.onMouseMove = function(self, dx, dy)
        local my = self:getMouseY()
        if self._activeScroll then
            self._activeScroll:handleMouseMove(my - self._activeScroll.y)
            return true
        end
        for _, cs2 in ipairs(self._colStates) do
            if cs2.scroll and not self._activeScroll then
                cs2.scroll:handleMouseMove(my - cs2.scroll.y)
            end
        end
        if self._colDrag then
            local cd = self._colDrag
            local T = ZeD.T
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW + delta))
            self._colWidths[cd.col] = newW
            return true
        end
        if self._drag:isPending() then
            if self._drag:checkThreshold(getMouseX(), getMouseY()) then
                self:setCapture(true)
                self._deferredSelect = nil
            end
        elseif self._drag:isActive() then
            self._drag:updateGhostPos(getMouseX(), getMouseY())
        end
        return true
    end

    content.onMouseMoveOutside = function(self, dx, dy)
        if self._activeScroll then
            local my = self:getMouseY()
            self._activeScroll:handleMouseMove(my - self._activeScroll.y)
        end
        if self._colDrag then
            local cd = self._colDrag
            local T = ZeD.T
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW + delta))
            self._colWidths[cd.col] = newW
            return true
        end
        if self._drag:isActive() then
            self._drag:updateGhostPos(getMouseX(), getMouseY())
        end
        return true
    end

    content.onMouseUpOutside = function(self, x, y)
        if self._activeScroll then
            self._activeScroll:handleMouseUp()
            self._activeScroll = nil
        end
        if self._colDrag then
            self._colDrag = nil
            self:setCapture(false)
            return true
        end
        if self._drag:isActive() then
            local dragItems = self._drag:complete()
            handleDrop(self, dragItems, self._dragSourceInv)
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
        local colIdx, cs2 = getColumnAtX(self, x)
        if not colIdx or not cs2 then return true end
        local zone = self:hitZoneAt(x, y)
        if zone and type(zone.id) ~= "string" then
            local item = zone.id
            if not cs2.selectedItems[item] then
                cs2.selectedItems = {[item] = true}
                cs2.lastClickedItem = item
            end
        end
        local items = collectFromMap(cs2.selectedItems)
        if #items == 0 then return true end
        local playerNum = self._playerObj:getPlayerNum()
        local isInInv = cs2.inventory:isInCharacterInventory(self._playerObj)
        ISInventoryPaneContextMenu.createMenu(
            playerNum, isInInv, items,
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

    content.onMouseWheel = function(self, del)
        local mx = self:getMouseX()
        local colIdx, cs2 = getColumnAtX(self, mx)
        if colIdx and cs2 and cs2.scroll then
            cs2.scroll:handleMouseWheel(del)
        end
        return true
    end
end

-- ============================================================================
-- KEY BINDING
-- ============================================================================

Events.OnKeyPressed.Add(function(key)
    if key == Keyboard.KEY_F6 then
        toggleTestInventory()
    end
end)
