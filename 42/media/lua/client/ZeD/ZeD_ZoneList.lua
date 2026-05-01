-- ============================================================================
-- O09: ZeD_ZoneList — scrollable clothing zone list for ItemCard
-- ============================================================================
-- Renders M16 zone rows (drawZoneRow) inside a stencil-clipped, scrollable
-- ISPanel. Dock buttons are clickable; fires onZonePress(zoneIdx, zone).
--
-- API:
--   setZones(zones)       — array of M16 zone config tables
--   getContentHeight()    — total pixel height of all zone rows
--   onZonePress           — callback(zoneIdx, zone) when dock button clicked
-- ============================================================================

require "ISUI/ISPanel"

ZeD_ZoneList = ISPanel:derive("ZeD_ZoneList")

local GROOVE_H = 2  -- 1px dark + 1px light

-- ---------------------------------------------------------------------------
-- CONSTRUCTOR
-- ---------------------------------------------------------------------------
function ZeD_ZoneList:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    local T = ZeD.T
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0}  -- no bg — window provides it
    o.borderColor     = {r = 0, g = 0, b = 0, a = 0}  -- no border — ItemCard provides chrome

    o.zones        = {}
    o.rowHeights   = {}     -- cached per-zone pixel heights
    o.rowOffsets   = {}     -- cumulative Y offset for each zone (for hit testing)
    o.totalH       = 0
    o.scrollPixels = 0
    o.hoveredZone  = 0      -- 1-based; 0 = none
    o.onZonePress  = nil    -- callback(zoneIdx, zone)
    o._lastWidth   = 0      -- detect width changes

    -- Scrollbar: plain Lua state table
    o.sb = ZeD_ScrollbarState:new()
    o.sb.width = T.sp.scrollbarW
    o.sb.visible = false
    o.sb.reserveBottom = 0

    o.sb.onScroll = function(pos)
        local maxScroll = math.max(0, o.totalH - o.height)
        o.scrollPixels = math.floor(pos * maxScroll)
    end

    return o
end

function ZeD_ZoneList:initialise()
    ISPanel.initialise(self)
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------
function ZeD_ZoneList:setZones(zones)
    self.zones = zones or {}
    self.scrollPixels = 0
    self.hoveredZone = 0
    self.sb:setScrollPos(0)
    self:_recalcHeights()
end

function ZeD_ZoneList:getContentHeight()
    return self.totalH
end

-- ---------------------------------------------------------------------------
-- HEIGHT CALCULATION (mirrors drawZoneRow logic without drawing)
-- ---------------------------------------------------------------------------
function ZeD_ZoneList:_recalcHeights()
    local T = ZeD.T
    local bodyH = getTextManager():getFontHeight(T.fontF2)
    local btnSz = T.iconSm + 4
    local barH  = T.fillBarH
    local topH  = math.max(bodyH + 4, barH + 4, btnSz)

    local heights = {}
    local offsets = {}
    local cumY = 0
    for i, zone in ipairs(self.zones) do
        if i > 1 then cumY = cumY + GROOVE_H end
        offsets[i] = cumY

        local hasDock = zone.dock ~= nil
        local soiled = zone.soiled
        local hasSoiled = soiled and (
            (soiled.blood and soiled.blood > 0) or
            (soiled.dirt) or
            (soiled.wet and soiled.wet > 0)
        )
        local h = (hasDock or hasSoiled) and (topH + btnSz) or topH
        heights[i] = h
        cumY = cumY + h
    end

    self.rowHeights = heights
    self.rowOffsets = offsets
    self.totalH = cumY
    self._lastWidth = self:getWidth()
end

-- ---------------------------------------------------------------------------
-- PRERENDER: sync theme colors, detect width changes
-- ---------------------------------------------------------------------------
function ZeD_ZoneList:prerender()
    local T = ZeD.T
    self.sb.width  = T.sp.scrollbarW
    self.sb.arrowH = T.sp.scrollbarW

    -- Recalc if width changed (font metrics depend on column split)
    local w = self:getWidth()
    if w ~= self._lastWidth then
        self:_recalcHeights()
    end

    ISPanel.prerender(self)
end

-- ---------------------------------------------------------------------------
-- RENDER: stencil clip, draw visible zones, scrollbar
-- ---------------------------------------------------------------------------
function ZeD_ZoneList:render()
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local w = self:getWidth()
    local h = self:getHeight()
    local needsScroll = self.totalH > h

    -- Update scrollbar geometry
    self.sb.visible = needsScroll
    if needsScroll then
        self.sb.x = w - self.sb.width
        self.sb.y = 0
        self.sb.height = h
        self.sb:setBarSize(h / self.totalH)
    end

    local contentW = needsScroll and (w - self.sb.width) or w

    -- Clamp scroll
    local maxScroll = math.max(0, self.totalH - h)
    if self.scrollPixels > maxScroll then self.scrollPixels = maxScroll end
    if self.scrollPixels < 0 then self.scrollPixels = 0 end

    -- Stencil clipping
    self:setStencilRect(0, 0, contentW, h)

    for i, zone in ipairs(self.zones) do
        local rowY = self.rowOffsets[i] - self.scrollPixels
        local rowH = self.rowHeights[i]

        -- Skip rows entirely off-screen
        if rowY + rowH > 0 and rowY < h then
            -- Groove divider before row (skip first)
            if i > 1 then
                A.drawGroove(self, 0, rowY - GROOVE_H, contentW)
            end

            -- Draw zone row with hover state
            local isHovered = (i == self.hoveredZone)
            M.drawZoneRow(self, 0, rowY, contentW, zone, isHovered)
        end
    end

    self:clearStencilRect()

    -- Scrollbar (outside stencil)
    if needsScroll then
        self.sb:draw(self)
    end
end

-- ---------------------------------------------------------------------------
-- DOCK BUTTON HIT TESTING
-- ---------------------------------------------------------------------------
-- Returns the dock button rect {x, y, w, h} for a zone, or nil if no active
-- dock. Coordinates are in panel-local space (before scroll offset).
function ZeD_ZoneList:_dockRect(i, contentW)
    local zone = self.zones[i]
    if not zone or not zone.dock or zone.dock.state == "grey" then return nil end

    local T = ZeD.T
    local btnSz = T.iconSm + 4
    local bodyH = getTextManager():getFontHeight(T.fontF2)
    local barH  = T.fillBarH
    local topH  = math.max(bodyH + 4, barH + 4, btnSz)

    -- Dock button lives on the bottom line, right edge
    local d = zone.dock
    local sTextW = d.flag and getTextManager():MeasureStringX(T.fontF1, d.flag) or 0
    local flagW  = math.max(4, sTextW + 8)
    local dockW  = d.icon and (flagW + btnSz) or flagW

    local bx = contentW - dockW
    local by = self.rowOffsets[i] + topH

    return {x = bx, y = by, w = dockW, h = btnSz}
end

-- ---------------------------------------------------------------------------
-- UPDATE: hover detection via absolute coords
-- ---------------------------------------------------------------------------
function ZeD_ZoneList:update()
    ISPanel.update(self)

    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    local w  = self:getWidth()
    local h  = self:getHeight()
    local inPanel = mx >= 0 and mx < w and my >= 0 and my < h
    local contentW = self.sb.visible and (w - self.sb.width) or w

    self.hoveredZone = 0

    if inPanel and (not self.sb.visible or mx < self.sb.x) then
        local localY = my + self.scrollPixels
        for i = 1, #self.zones do
            local rect = self:_dockRect(i, contentW)
            if rect then
                if localY >= rect.y and localY < rect.y + rect.h
                   and mx >= rect.x and mx < rect.x + rect.w then
                    self.hoveredZone = i
                    break
                end
            end
        end
    end

    -- Scrollbar hover/drag
    if self.sb.visible then
        local inSb = inPanel and mx >= self.sb.x
        if inSb then
            self.sb:handleMouseMove(my - self.sb.y)
        else
            self.sb.upHover = false
            self.sb.downHover = false
            self.sb.thumbHover = false
        end
        if self.sb.dragging then
            self.sb:handleMouseMove(my - self.sb.y)
        end
    end
end

-- ---------------------------------------------------------------------------
-- MOUSE EVENTS
-- ---------------------------------------------------------------------------
function ZeD_ZoneList:onMouseDown(x, y)
    -- Scrollbar click
    if self.sb.visible and x >= self.sb.x then
        self.sb:handleMouseDown(y - self.sb.y)
        return true
    end

    -- Dock button click
    local w = self:getWidth()
    local contentW = self.sb.visible and (w - self.sb.width) or w
    local localY = y + self.scrollPixels
    for i = 1, #self.zones do
        local rect = self:_dockRect(i, contentW)
        if rect then
            if localY >= rect.y and localY < rect.y + rect.h
               and x >= rect.x and x < rect.x + rect.w then
                if self.onZonePress then
                    self.onZonePress(i, self.zones[i])
                end
                return true
            end
        end
    end

    return true
end

function ZeD_ZoneList:onMouseUp(x, y)
    self.sb:handleMouseUp()
end

function ZeD_ZoneList:onMouseUpOutside(x, y)
    self.sb:handleMouseUp()
end

function ZeD_ZoneList:onMouseWheel(del)
    if self.sb.visible then
        self.sb:handleMouseWheel(del)
        return true
    end
    return false
end
