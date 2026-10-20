-- ZeD-UI/42/media/lua/client/ZeD/MapsTab.lua
-- ============================================================================
-- MAPS TAB — World Window standalone tab.
-- Embedded UIWorldMap with stash map markers, flyer location dots,
-- user-placed annotations (15 icons, 5 colors, text notes).
-- Same annotation data as JournalTab Maps sub-tab (modData.ZeD_MapAnnotations).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ISUI/Maps/ISMapDefinitions"

ZeD = ZeD or {}
ZeD.MapsTab = {}

-- ============================================================================
-- CONSTANTS — duplicated from JournalTab (may diverge)
-- ============================================================================

local MAP_ICONS = {
    { id = "house",       tex = "media/ui/LootableMaps/map_house.png",       label = "House" },
    { id = "target",      tex = "media/ui/LootableMaps/map_target.png",      label = "Target" },
    { id = "skull",       tex = "media/ui/LootableMaps/map_skull.png",       label = "Skull" },
    { id = "star",        tex = "media/ui/LootableMaps/map_star.png",        label = "Star" },
    { id = "cross",       tex = "media/ui/LootableMaps/map_cross.png",       label = "Cross" },
    { id = "heart",       tex = "media/ui/LootableMaps/map_heart.png",       label = "Heart" },
    { id = "exclamation", tex = "media/ui/LootableMaps/map_exclamation.png", label = "Alert" },
    { id = "question",    tex = "media/ui/LootableMaps/map_question.png",    label = "Question" },
    { id = "fire",        tex = "media/ui/LootableMaps/map_firet.png",       label = "Fire" },
    { id = "gun",         tex = "media/ui/LootableMaps/map_gun.png",         label = "Gun" },
    { id = "burger",      tex = "media/ui/LootableMaps/map_burger.png",      label = "Food" },
    { id = "axe",         tex = "media/ui/LootableMaps/map_axe.png",         label = "Axe" },
    { id = "gears",       tex = "media/ui/LootableMaps/map_gears.png",       label = "Gears" },
    { id = "x",           tex = "media/ui/LootableMaps/map_x.png",          label = "X" },
    { id = "checkmark",   tex = "media/ui/LootableMaps/map_checkmark.png",   label = "Check" },
}

local MAP_COLORS = {
    { r = 0.6, g = 0.6, b = 0.6, a = 0.9, label = "Pencil" },
    { r = 0.1, g = 0.1, b = 0.1, a = 0.9, label = "Black" },
    { r = 0.2, g = 0.4, b = 0.9, a = 0.9, label = "Blue" },
    { r = 0.9, g = 0.2, b = 0.2, a = 0.9, label = "Red" },
    { r = 0.2, g = 0.8, b = 0.3, a = 0.9, label = "Green" },
}

local MAP_ICON_BTN_SZ   = 20
local MAP_ICON_BTN_GAP  = 4
local MAP_COLOR_SZ      = 14
-- Sourced from ZeD.Spacing.tabHeaderH so all drawer / toolbar headers stay
-- in lockstep when the token is tuned.
local MAP_TOOLBAR_ROW_H = (ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37
local MAP_ANNOT_DRAW_SZ = 22
local MAP_TEXT_INPUT_H   = 24

local MAP_DEFAULT_PINS = { "house", "target", "skull", "star", "cross", "checkmark" }

local MAP_ICON_BY_ID = {}
for i, icon in ipairs(MAP_ICONS) do
    MAP_ICON_BY_ID[icon.id] = icon
end

-- ============================================================================
-- PIN HELPERS — persistent per-player pinned icon list
-- ============================================================================

local function _getMapPins(playerObj)
    local md = playerObj:getModData()
    if not md.ZeD_MapPinnedIcons then
        md.ZeD_MapPinnedIcons = {}
        for _, id in ipairs(MAP_DEFAULT_PINS) do
            md.ZeD_MapPinnedIcons[#md.ZeD_MapPinnedIcons + 1] = id
        end
    end
    return md.ZeD_MapPinnedIcons
end

local function _isIconPinned(pins, id)
    for _, pid in ipairs(pins) do
        if pid == id then return true end
    end
    return false
end

local function _togglePin(pins, id)
    for i, pid in ipairs(pins) do
        if pid == id then
            table.remove(pins, i)
            return
        end
    end
    pins[#pins + 1] = id
end

-- ============================================================================
-- MAP PANEL — ISUIElement wrapping a Java UIWorldMap
-- ============================================================================

local ZeD_WorldMap = ISUIElement:derive("ZeD_WorldMap")
-- (its outlines scale with the UI like every ZeD element; it is local, so TextScale's
-- class list cannot reach it; code audit Oct 17 2026)
ZeD_WorldMap.zedScaled = true

function ZeD_WorldMap:new(x, y, w, h, playerObj)
    local o = ISUIElement:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.anchorLeft   = true
    o.anchorRight  = false
    o.anchorTop    = true
    o.anchorBottom = true
    o.playerObj    = playerObj
    o.dragging     = false
    o.dragMoved    = false
    return o
end

function ZeD_WorldMap:instantiate()
    self.javaObject = UIWorldMap.new(self)
    self.mapAPI = self.javaObject:getAPIv3()

    -- Configure: top-down, no debug, fog-of-war ("HideUnvisited", as vanilla's in-game map sets
    -- it in ISWorldMap:initDataAndStyle; the engine's default is off, and this read
    -- "HideUnvisitedAreas" until Oct 15 2026, a name the engine does not have: the whole county
    -- showed whatever the character had explored)
    self.mapAPI:setBoolean("Isometric", false)
    self.mapAPI:setBoolean("DebugInfo", false)
    self.mapAPI:setBoolean("HideUnvisited", true)

    -- Pre-load annotation icon textures
    self._annotTextures = {}
    for _, icon in ipairs(MAP_ICONS) do
        self._annotTextures[icon.id] = getTexture(icon.tex)
    end

    self.javaObject:setX(self.x)
    self.javaObject:setY(self.y)
    self.javaObject:setWidth(self.width)
    self.javaObject:setHeight(self.height)
    self.javaObject:setAnchorLeft(true)
    self.javaObject:setAnchorRight(false)
    self.javaObject:setAnchorTop(true)
    self.javaObject:setAnchorBottom(true)

    self:createChildren()
end

-- THE TWO MAPS (director, Oct 15 2026: "the paper map used in the location selection ...
-- options to show both the paper map and ingame map?"). SURVEY is vanilla's in-game map
-- (its data, streets and style); PAPER is the illustrated county map the spawn screen shows
-- (the base map's spawnSelectImagePyramid, laid out in world squares). Both keep vanilla's
-- fog of war: only explored ground shows.
local PAPER_MAX_ZOOM = 16.0   -- past this the illustration is only enlarged
local PAPER_FILE = nil
local function paperFile()
    if PAPER_FILE == nil then
        PAPER_FILE = false
        local info = getMapInfo and getMapInfo("Muldraugh, KY")
        local f = info and info.spawnSelectImagePyramid
        if f and f ~= "" then PAPER_FILE = f end
    end
    return PAPER_FILE or nil
end
ZeD.MapsTab.hasPaper = function() return paperFile() ~= nil end

-- vanilla's in-game map: its data, streets, style (ISWorldMap:initDataAndStyle)
local function initSurvey(mp)
    if not (MapUtils and MapUtils.initDefaultMapData) then return end
    MapUtils.initDefaultMapData(mp)
    mp.mapAPI:setBoundsFromWorld()
    if MapUtils.initDefaultStreetData then
        MapUtils.initDefaultStreetData(mp)
    end
    MapUtils.initDefaultStyleV3(mp)
    -- S124: the label layers are sized in their own units (ISMapDefinitions: 48 / 40 / 32); scale them
    -- with the root so street and town names grow with the rest of the UI.
    pcall(function()
        local root = (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1
        local styleAPI = mp.mapAPI:getStyleAPI()
        local BASE = { ["text-note"] = 40, ["text-street"] = 48, ["text-building"] = 48, ["text-place"] = 48, ["text-town"] = 48,
                       ["text-forest"] = 32, ["text-water-small"] = 32, ["text-water-medium"] = 32, ["text-water-nofade"] = 32 }
        for name, base in pairs(BASE) do
            local layer = styleAPI:getLayerByName(name)
            if layer then layer:setLineHeight(math.floor(base * root + 0.5)) end
        end
    end)
    if MapUtils.overlayPaper then
        MapUtils.overlayPaper(mp)
    end
    -- NOTE: getSymbolsAPIv2() crashes on embedded UIWorldMaps (Java uiSymbols is null).
    -- Default annotations are skipped; we render our own overlays in render().
end

-- the illustration alone (MapSpawnSelectImage's setup), on vanilla's paper colours
local function initPaper(mp)
    local api = mp.mapAPI
    -- the world's map data too, undrawn (no style layers): without it the
    -- engine has no world until Survey has loaded once, and zoom throws
    if MapUtils and MapUtils.initDefaultMapData then pcall(MapUtils.initDefaultMapData, mp) end
    api:addImagePyramid(paperFile())
    api:setBoolean("ImagePyramid", true)
    api:setBoundsFromWorld()
    local r, g, b = 219 / 255, 215 / 255, 192 / 255
    api:setBackgroundRGBA(r, g, b, 1.0)
    api:setUnvisitedRGBA(r * 0.915, g * 0.915, b * 0.915, 1.0)
    api:setUnvisitedGridRGBA(r * 0.777, g * 0.777, b * 0.777, 1.0)
end

-- SURVEY or PAPER on the one map (it keeps where it looks)
function ZeD_WorldMap:applyStyle(paper)
    local api = self.mapAPI
    if paper and not paperFile() then paper = false end
    local cx, cy, z = nil, nil, nil
    if self._styled then cx, cy, z = api:getCenterWorldX(), api:getCenterWorldY(), api:getZoomF() end
    api:getStyleAPI():clear()
    api:clearImages()
    api:clearData()
    if paper then initPaper(self) else initSurvey(self) end
    api:setBoolean("HideUnvisited", true)
    self.paper = paper and true or false
    self._styled = true
    if cx then
        api:centerOn(cx, cy)
        self:_zoomTo(paper and math.min(z, PAPER_MAX_ZOOM) or z)
    end
end

-- setZoom needs the map's world loaded: the paper style (pictures only, no
-- data) has none until it has drawn once, and the engine throws. Retried at
-- the next render until it takes (vanilla's spawn map zooms in prerender too).
function ZeD_WorldMap:_zoomTo(z)
    if pcall(function() self.mapAPI:setZoom(z) end) then
        self._pendingZoom, self._zoomTries = nil, nil
        return
    end
    -- (each miss logs the engine's stack; give up after a few frames)
    self._zoomTries = (self._zoomTries or 0) + 1
    self._pendingZoom = self._zoomTries < 10 and z or nil
end

function ZeD_WorldMap:createChildren()
    local md = self.playerObj and self.playerObj:getModData() or nil
    self:applyStyle(md and md.ZeD_MapPaper == true)

    -- Center on player position
    if self.playerObj then
        self.mapAPI:centerOn(self.playerObj:getX(), self.playerObj:getY())
        self:_zoomTo(self.paper and 15.0 or 18.0)
    end

    self._annotationsLoaded = false
end

-- the toolbar's SURVEY / PAPER (kept per character, as the pinned icons are)
function ZeD.MapsTab.setPaper(win, paper)
    local mp = win and win._worldMapPanel
    if not mp then return end
    paper = paper and paperFile() ~= nil
    if mp.paper == paper then return end
    local md = win._playerObj and win._playerObj:getModData()
    if md then md.ZeD_MapPaper = paper end
    mp:applyStyle(paper)
    getSoundManager():playUISound("UIActivateTab")
end

-- Shared annotation placement — used by both mouse LMB and gamepad A-press.
-- uiX / uiY are panel-local pixel coordinates inside the map panel. Returns
-- true when an annotation was placed/edited, false when no tool was active
-- (so the caller can fall through to pan/drag behavior if it wants).
local function _placeAnnotationAt(mp, uiX, uiY)
    local win = mp._parentWin
    if not (win and win._mapActiveTool) then return false end

    local worldX = mp.mapAPI:uiToWorldX(uiX, uiY)
    local worldY = mp.mapAPI:uiToWorldY(uiX, uiY)
    local toolId = win._mapActiveTool
    local colorIdx = win._mapActiveColor or 1

    local md = mp.playerObj:getModData()
    if not md.ZeD_MapAnnotations then md.ZeD_MapAnnotations = {} end

    if toolId == "text" then
        local noteText = "Note"
        if win._mapTextEntry then
            local t = win._mapTextEntry:getText()
            if t and t ~= "" then noteText = t end
        end

        -- Editing existing annotation (right-click → Edit Note path): update
        -- text on the same entry and exit text mode.
        if win._mapEditAnnotIdx then
            local annots = md.ZeD_MapAnnotations
            local a = annots and annots[win._mapEditAnnotIdx]
            if a then a.text = noteText end
            win._mapEditAnnotIdx = nil
            win._mapActiveTool = nil
        else
            local annots = md.ZeD_MapAnnotations
            annots[#annots + 1] = {
                worldX   = worldX,
                worldY   = worldY,
                iconId   = "text",
                colorIdx = colorIdx,
                text     = noteText,
            }
        end
    else
        -- Icon annotation: persistent mode (tool stays active so user can
        -- drop a string of the same marker without re-selecting).
        local annots = md.ZeD_MapAnnotations
        annots[#annots + 1] = {
            worldX   = worldX,
            worldY   = worldY,
            iconId   = toolId,
            colorIdx = colorIdx,
            text     = "",
        }
    end
    return true
end

-- Shared annotation-edit context menu. Opens at absolute screen coords
-- (absX, absY) for annotation index `hitIdx`. Used by mouse RMB and by the
-- gamepad X-press when the cursor is over an annotation.
local function _openAnnotContextMenu(mp, absX, absY, hitIdx)
    local md = mp.playerObj:getModData()
    local annots = md and md.ZeD_MapAnnotations
    if not annots or not annots[hitIdx] then return end

    local ctx = ISContextMenu.get(0, absX, absY)

    ctx:addOption("Delete", mp, function(self2)
        local md2 = self2.playerObj:getModData()
        if md2.ZeD_MapAnnotations then
            table.remove(md2.ZeD_MapAnnotations, hitIdx)
        end
    end)

    ctx:addOption("Change Color", mp, function(self2)
        local md2 = self2.playerObj:getModData()
        local a = md2.ZeD_MapAnnotations and md2.ZeD_MapAnnotations[hitIdx]
        if a then a.colorIdx = ((a.colorIdx or 1) % #MAP_COLORS) + 1 end
    end)

    ctx:addOption("Edit Note", mp, function(self2)
        local pwin = self2._parentWin
        if not pwin then return end
        local md2 = self2.playerObj:getModData()
        local a = md2.ZeD_MapAnnotations and md2.ZeD_MapAnnotations[hitIdx]
        if a then
            pwin._mapActiveTool = "text"
            pwin._mapEditAnnotIdx = hitIdx
            if pwin._mapTextEntry then
                pwin._mapTextEntry:setText(a.text or "")
                pwin._mapTextEntry:setVisible(true)
            end
        end
    end)
end

-- Mouse drag for panning (or annotation placement when tool is active)
function ZeD_WorldMap:onMouseDown(x, y)
    if _placeAnnotationAt(self, x, y) then return true end

    self.dragging = true
    self.dragMoved = false
    self.dragStartX = x
    self.dragStartY = y
    self.dragStartCX = self.mapAPI:getCenterWorldX()
    self.dragStartCY = self.mapAPI:getCenterWorldY()
    self.dragStartZoomF = self.mapAPI:getZoomF()
    self.dragStartWorldX = self.mapAPI:uiToWorldX(x, y)
    self.dragStartWorldY = self.mapAPI:uiToWorldY(x, y)
    return true
end

function ZeD_WorldMap:onMouseMove(dx, dy)
    local T = ZeD.T
    if self.dragging then
        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()
        if not self.dragMoved
           and math.abs(mouseX - self.dragStartX) <= T.px(4)
           and math.abs(mouseY - self.dragStartY) <= T.px(4) then
            return
        end
        self.dragMoved = true
        local worldX = self.mapAPI:uiToWorldX(mouseX, mouseY,
            self.dragStartZoomF, self.dragStartCX, self.dragStartCY)
        local worldY = self.mapAPI:uiToWorldY(mouseX, mouseY,
            self.dragStartZoomF, self.dragStartCX, self.dragStartCY)
        self.mapAPI:centerOn(
            self.dragStartCX + self.dragStartWorldX - worldX,
            self.dragStartCY + self.dragStartWorldY - worldY)
    end
    return true
end

function ZeD_WorldMap:onMouseUp(x, y)
    self.dragging = false
    return true
end

-- Right-click: context menu for annotation edit/delete
function ZeD_WorldMap:onRightMouseDown(x, y)
    local T = ZeD.T
    if not self._annotationHits then return false end

    local hitRadius = T.px(16)
    for _, hit in ipairs(self._annotationHits) do
        local cx = hit.x + hit.w / 2
        local cy = hit.y + hit.h / 2
        local ddx = x - cx
        local ddy = y - cy
        if ddx * ddx + ddy * ddy <= hitRadius * hitRadius then
            _openAnnotContextMenu(self,
                self:getAbsoluteX() + x, self:getAbsoluteY() + y, hit.idx)
            return true
        end
    end
    return false
end

-- Mouse wheel for zoom
function ZeD_WorldMap:onMouseWheel(del)
    self.mapAPI:zoomAt(self:getMouseX(), self:getMouseY(), del)
    return true
end

-- Get bounds of a stash map by name (cached, uses temporary UIWorldMap)
function ZeD_WorldMap:getStashMapBounds(stashName)
    self._stashBounds = self._stashBounds or {}
    if self._stashBounds[stashName] then
        return self._stashBounds[stashName]
    end
    if not self._boundsUI then
        local ui = {}
        ui.javaObject = UIWorldMap.new(ui)
        ui.mapAPI = ui.javaObject:getAPIv3()
        self._boundsUI = ui
    end
    local bounds = {}
    local f = LootMaps and LootMaps.Init and LootMaps.Init[stashName]
    if f then
        self._boundsUI.mapAPI:clearData()
        self._boundsUI.mapAPI:getStyleAPI():clear()
        f(self._boundsUI)
        bounds.x1 = self._boundsUI.mapAPI:getMinXInSquares()
        bounds.y1 = self._boundsUI.mapAPI:getMinYInSquares()
        bounds.x2 = self._boundsUI.mapAPI:getMaxXInSquares() + 1
        bounds.y2 = self._boundsUI.mapAPI:getMaxYInSquares() + 1
    end
    self._stashBounds[stashName] = bounds
    return bounds
end

-- Render stash map icons on top of the world map
function ZeD_WorldMap:renderStashMaps()
    local T = ZeD.T
    if not StashSystem then return end
    local stashNameList = StashSystem.getAlreadyReadMap()
    if not stashNameList then return end

    local iconTex = getTexture("Item_Map")
    if not iconTex then return end
    local iconSize = T.px(24)
    local pw, ph = self:getWidth(), self:getHeight()

    for i = 1, stashNameList:size() do
        local stashName = stashNameList:get(i - 1)
        local bounds = self:getStashMapBounds(stashName)
        if bounds and bounds.x1 then
            local cx = bounds.x1 / 2 + bounds.x2 / 2
            local cy = bounds.y1 / 2 + bounds.y2 / 2
            local sx = self.mapAPI:worldToUIX(cx, cy) - iconSize / 2
            local sy = self.mapAPI:worldToUIY(cx, cy) - iconSize / 2
            if sx > -iconSize and sy > -iconSize and sx < pw and sy < ph then
                self:drawTextureScaledAspect(iconTex, sx, sy, iconSize, iconSize, 1.0, 1.0, 1.0, 1.0)
            end
        end
    end
end

-- Render flyer location markers from PrintMediaDefinitions
function ZeD_WorldMap:renderFlyerMarkers()
    if not PrintMediaDefinitions or not PrintMediaDefinitions.MiscDetails then return end

    local T = ZeD.T
    local dotSz = T.px(8)
    local ac = T.accent
    local pw, ph = self:getWidth(), self:getHeight()

    for _, detail in pairs(PrintMediaDefinitions.MiscDetails) do
        if detail.location1 then
            for _, loc in ipairs(detail.location1) do
                local cx = (loc.x1 + loc.x2) / 2
                local cy = (loc.y1 + loc.y2) / 2
                local sx = self.mapAPI:worldToUIX(cx, cy) - dotSz / 2
                local sy = self.mapAPI:worldToUIY(cx, cy) - dotSz / 2
                if sx > -dotSz and sy > -dotSz and sx < pw and sy < ph then
                    self:drawRect(sx, sy, dotSz, dotSz, 0.8, ac.r, ac.g, ac.b)
                end
            end
        end
    end
end

-- Render user-placed annotations from modData
function ZeD_WorldMap:renderAnnotations()
    local md = self.playerObj:getModData()
    local annots = md and md.ZeD_MapAnnotations
    if not annots or #annots == 0 then return end

    local T = ZeD.T
    local tm = ZeD.TM
    local pw, ph = self:getWidth(), self:getHeight()
    local sz = T.px(MAP_ANNOT_DRAW_SZ)
    local halfSz = sz / 2

    self._annotationHits = {}

    for i, ann in ipairs(annots) do
        local sx = self.mapAPI:worldToUIX(ann.worldX, ann.worldY) - halfSz
        local sy = self.mapAPI:worldToUIY(ann.worldX, ann.worldY) - halfSz

        if sx > -sz and sy > -sz and sx < pw and sy < ph then
            local colorDef = MAP_COLORS[ann.colorIdx or 1] or MAP_COLORS[1]
            local c = colorDef

            if ann.iconId == "text" then
                local dotSz = T.px(6)
                local dotX = sx + halfSz - dotSz / 2
                local dotY = sy + halfSz - dotSz / 2
                self:drawRect(dotX + T.px(1), dotY,     dotSz - T.px(2), T.px(1),        0.9, c.r, c.g, c.b)
                self:drawRect(dotX,     dotY + T.px(1), dotSz,     dotSz - T.px(2), 0.9, c.r, c.g, c.b)
                self:drawRect(dotX + T.px(1), dotY + dotSz - T.px(1), dotSz - T.px(2), T.px(1), 0.9, c.r, c.g, c.b)
            else
                local tex = self._annotTextures and self._annotTextures[ann.iconId]
                if tex then
                    self:drawTextureScaledAspect(tex, sx, sy, sz, sz, 0.9, c.r, c.g, c.b)
                else
                    local m = T.px(4)
                    for di = 0, sz - m * 2 - 1 do  -- S124 scale: walks screen px; the -1 is the inclusive loop bound
                        self:drawRect(sx + m + di, sy + m + di, T.px(1), T.px(1), 0.7, c.r, c.g, c.b)
                        self:drawRect(sx + m + di, sy + sz - m - T.px(1) - di, T.px(1), T.px(1), 0.7, c.r, c.g, c.b)
                    end
                end
            end

            if ann.text and ann.text ~= "" then
                local tw = tm:MeasureStringX(T.fontF1, ann.text)
                local tx = sx + halfSz - tw / 2
                local ty = sy - tm:getFontHeight(T.fontF1) - T.px(2)
                self:drawText(ann.text, tx + T.px(1), ty + T.px(1), 0, 0, 0, 0.6, T.fontF1)
                self:drawText(ann.text, tx, ty, c.r, c.g, c.b, 1, T.fontF1)
            end

            self._annotationHits[#self._annotationHits + 1] = {
                idx = i,
                x = sx, y = sy, w = sz, h = sz,
            }
        end
    end
end

-- Read the currently-focused ring element if focus belongs to the owning
-- window. Returns nil when another window has focus, or when the ring isn't
-- initialized yet. Used to drive gamepad-only overlays without leaking them
-- into KBM sessions.
-- S123: the map can live in the World drawer OR in the unfolded pop-out
-- window. Focus-dependent paint (cursor, toolbar cues) must read whichever
-- of the two currently owns FocusManager focus.
local function _focusOwner(win)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if not Focus or not win then return nil end
    local fw = Focus.getFocusedWindow()
    if fw == win then return win end
    if win._mapPopout and fw == win._mapPopout then return fw end
    return nil
end

local function _focusedEl(win)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local owner = _focusOwner(win)
    if not Focus or not owner then return nil end
    return Focus.getFocusedElement(owner)
end

-- Render cursor preview when a tool is active (MOUSE path only — skipped
-- when gamepad focus is on the canvas cursor, which draws its own preview
-- at the gp cursor position instead).
function ZeD_WorldMap:renderToolCursor()
    local win = self._parentWin
    if not win or not win._mapActiveTool then return end

    local el = _focusedEl(win)
    if el and el.isCanvasCursor then return end  -- gamepad owns the cursor

    local mx, my = self:getMouseX(), self:getMouseY()
    if mx < 0 or my < 0 or mx > self:getWidth() or my > self:getHeight() then return end

    local T = ZeD.T
    local sz = T.px(MAP_ANNOT_DRAW_SZ)
    local colorDef = MAP_COLORS[win._mapActiveColor or 1] or MAP_COLORS[1]
    local c = colorDef

    if win._mapActiveTool == "text" then
        local dotSz = T.px(6)
        local dotX = mx - dotSz / 2
        local dotY = my - dotSz / 2
        self:drawRect(dotX + T.px(1), dotY,     dotSz - T.px(2), T.px(1),        0.4, c.r, c.g, c.b)
        self:drawRect(dotX,     dotY + T.px(1), dotSz,     dotSz - T.px(2), 0.4, c.r, c.g, c.b)
        self:drawRect(dotX + T.px(1), dotY + dotSz - T.px(1), dotSz - T.px(2), T.px(1), 0.4, c.r, c.g, c.b)
        local previewText = (win._mapTextEntry and win._mapTextEntry:getText()) or "Note"
        if previewText ~= "" then
            self:drawText(previewText, mx + T.px(6), my - T.px(10), c.r, c.g, c.b, 0.4, T.fontF1)
        end
    else
        local tex = self._annotTextures and self._annotTextures[win._mapActiveTool]
        if tex then
            self:drawTextureScaledAspect(tex, mx - sz / 2, my - sz / 2, sz, sz, 0.5, c.r, c.g, c.b)
        end
    end
end

-- Lazy-seed the gamepad cursor to panel center on first focus. Stored on the
-- map panel in panel-local pixel coords; the render + move helpers read/
-- write these fields.
function ZeD_WorldMap:seedGpCursor()
    if self._gpCursorX and self._gpCursorY then return end
    self._gpCursorX = math.floor(self:getWidth()  / 2)
    self._gpCursorY = math.floor(self:getHeight() / 2)
end

-- Render the gamepad crosshair + tool preview at the gp cursor position.
-- Only runs when the canvas cursor pseudo-focusable is the focused ring
-- element; otherwise the crosshair would bleed into KBM sessions.
function ZeD_WorldMap:renderGamepadCursor()
    local win = self._parentWin
    if not win then return end

    local el = _focusedEl(win)
    if not el or not el.isCanvasCursor then return end

    self:seedGpCursor()
    local cx, cy = self._gpCursorX, self._gpCursorY

    local T = ZeD.T
    local ac = T.accent

    -- Crosshair — two short orthogonal segments + a small gap in the middle
    -- so the exact pixel the cursor points at is never obscured. Pattern
    -- parallels AnimalsTab line 757 (idle-phase tile highlight).
    local arm   = T.px(8)    -- arm length in pixels
    local gap   = T.px(3)    -- half-gap (no pixels drawn within `gap` of center)
    -- Horizontal arms
    self:drawRect(cx - arm, cy,     arm - gap, T.px(1), ac.a, ac.r, ac.g, ac.b)
    self:drawRect(cx + gap, cy,     arm - gap, T.px(1), ac.a, ac.r, ac.g, ac.b)
    -- Vertical arms
    self:drawRect(cx,       cy - arm, T.px(1), arm - gap, ac.a, ac.r, ac.g, ac.b)
    self:drawRect(cx,       cy + gap, T.px(1), arm - gap, ac.a, ac.r, ac.g, ac.b)
    -- Center pixel for precise targeting
    self:drawRect(cx, cy, T.px(1), T.px(1), 1.0, ac.r, ac.g, ac.b)

    -- Tool preview at cursor when a tool is armed, so the user sees what
    -- A-press will place. Mirrors renderToolCursor's mouse-preview styling.
    if win._mapActiveTool then
        local sz = T.px(MAP_ANNOT_DRAW_SZ)
        local colorDef = MAP_COLORS[win._mapActiveColor or 1] or MAP_COLORS[1]
        local c = colorDef

        if win._mapActiveTool == "text" then
            local previewText = (win._mapTextEntry and win._mapTextEntry:getText()) or "Note"
            if previewText ~= "" then
                self:drawText(previewText, cx + T.px(8), cy - T.px(10), c.r, c.g, c.b, 0.5, T.fontF1)
            end
        else
            local tex = self._annotTextures and self._annotTextures[win._mapActiveTool]
            if tex then
                self:drawTextureScaledAspect(tex, cx - sz / 2, cy - sz / 2,
                    sz, sz, 0.5, c.r, c.g, c.b)
            end
        end
    end
end

-- ISUIElement render — draw overlays on top of the Java map.
-- Do NOT call ISUIElement.render(self) — Java UIWorldMap handles its own rendering.
function ZeD_WorldMap:render()
    if self._pendingZoom then self:_zoomTo(self._pendingZoom) end
    self:renderStashMaps()
    self:renderFlyerMarkers()
    self:renderAnnotations()
    self:renderToolCursor()
    self:renderGamepadCursor()
end

-- ============================================================================
-- TOOLBAR
-- ============================================================================

--- Draw a single icon tool button at (bx, by). `isGpFocused` paints the
-- 0.55α accent focus cue when this button is the currently-focused ring
-- element (gamepad path); the caller computes the match by id.
local function _drawIconBtn(panel, win, icon, bx, by, btnSz, isActive, isPinned, isGpFocused)
    local T = ZeD.T

    -- Focus cue first so active-state paint composes on top and remains
    -- visible (feedback_focus_paint_convention: 0.55α accent fill, not a border).
    if isGpFocused then
        local ac = T.accent
        panel:drawRect(bx, by, btnSz, btnSz, 0.55, ac.r, ac.g, ac.b)
    end

    if isActive then
        local ac = T.accent
        panel:drawRect(bx, by, btnSz, btnSz, 0.2, ac.r, ac.g, ac.b)
        panel:drawRectBorder(bx, by, btnSz, btnSz, 0.6, ac.r, ac.g, ac.b)
    else
        local bd = T.border
        panel:drawRectBorder(bx, by, btnSz, btnSz, bd.a * 0.3, bd.r, bd.g, bd.b)
    end

    local mapPanel = win._worldMapPanel
    local tex = mapPanel and mapPanel._annotTextures and mapPanel._annotTextures[icon.id]
    if tex then
        local tc = isActive and T.accent or T.text
        local alpha = isActive and 0.9 or 0.6
        panel:drawTextureScaledAspect(tex, bx + T.px(2), by + T.px(2), btnSz - T.px(4), btnSz - T.px(4),
            alpha, tc.r, tc.g, tc.b)
    else
        local lbl = string.sub(icon.label, 1, 1)
        local dc = isActive and T.accent or T.textDim
        panel:drawText(lbl, bx + T.px(5), by + T.px(2), dc.r, dc.g, dc.b, 0.6, T.fontF1)
    end

    if isPinned then
        local ac = T.accent
        panel:drawRect(bx + T.px(1), by + T.px(1), T.px(3), T.px(3), 0.7, ac.r, ac.g, ac.b)
    end

    win._mapToolZones[#win._mapToolZones + 1] = {
        id = icon.id,
        x = bx, y = by, w = btnSz, h = btnSz,
    }
end

local function renderMapToolbar(panel, win, x, y, w)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local secH = tm:getFontHeight(T.fontF1)
    local btnSz  = T.px(MAP_ICON_BTN_SZ)
    local btnGap = T.px(MAP_ICON_BTN_GAP)
    local colSz  = T.px(MAP_COLOR_SZ)

    win._mapToolZones  = {}
    win._mapColorZones = {}
    win._mapToolRMBZones = {}

    local activeTool  = win._mapActiveTool
    local activeColor = win._mapActiveColor or 1
    local expanded    = win._mapToolsExpanded or false
    local pins        = _getMapPins(win._playerObj)

    -- Read the focused ring element id once per frame so we can paint the
    -- 0.55α focus cue on whichever toolbar element currently owns focus.
    -- feedback_only_focused_zone_shows_active: only paint when THIS window
    -- owns focus (prevents stale paint when focus is on the Character window).
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focId = nil
    do
        local owner = _focusOwner(win)  -- S123: drawer or pop-out
        if Focus and owner then
            local fe = Focus.getFocusedElement and Focus.getFocusedElement(owner)
            focId = fe and fe.id or nil
        end
    end

    local rowH = T.px(MAP_TOOLBAR_ROW_H)
    local btnY = y + math.floor((rowH - btnSz) / 2)

    -- Row 1: disclosure chevron + pinned icons + Aa + separator + color swatches
    local curX = x + T.px(4)

    -- Disclosure chevron
    local chevSz = math.max(T.px(8), math.floor(secH * 0.7))
    local chevY  = y + math.floor((rowH - chevSz) / 2)
    if focId == "map:disclosure" then
        local ac = T.accent
        panel:drawRect(curX - T.px(2), y, chevSz + T.px(6), rowH, 0.55, ac.r, ac.g, ac.b)
    end
    if expanded then
        A.drawTriangleDown(panel, curX, chevY, chevSz, T.arrow)
    else
        A.drawTriangleRight(panel, curX, chevY, chevSz, T.arrow)
    end
    win._mapDisclosureZone = { x = curX, y = y, w = chevSz + T.px(4), h = rowH }
    curX = curX + chevSz + T.px(6)

    -- Pinned icon buttons. Ring-focus id for a pinned-row tool is
    -- "map:tool:<iconId>" (grid copies use "map:gridtool:<iconId>").
    for _, pid in ipairs(pins) do
        local icon = MAP_ICON_BY_ID[pid]
        if icon then
            local isActive = (activeTool == icon.id)
            local isFoc = (focId == "map:tool:" .. icon.id)
            _drawIconBtn(panel, win, icon, curX, btnY, btnSz, isActive, false, isFoc)
            curX = curX + btnSz + btnGap
        end
    end

    -- "Aa" text note button
    curX = curX + btnGap
    local textActive = (activeTool == "text")
    if focId == "map:tool:text" then
        local ac = T.accent
        panel:drawRect(curX, btnY, btnSz, btnSz, 0.55, ac.r, ac.g, ac.b)
    end
    if textActive then
        local ac = T.accent
        panel:drawRect(curX, btnY, btnSz, btnSz, 0.2, ac.r, ac.g, ac.b)
        panel:drawRectBorder(curX, btnY, btnSz, btnSz, 0.6, ac.r, ac.g, ac.b)
    else
        local bd = T.border
        panel:drawRectBorder(curX, btnY, btnSz, btnSz, bd.a * 0.3, bd.r, bd.g, bd.b)
    end
    local tC = textActive and T.accent or T.textDim
    panel:drawText("Aa", curX + T.px(2), btnY + T.px(2), tC.r, tC.g, tC.b, 0.7, T.fontF1)
    win._mapToolZones[#win._mapToolZones + 1] = {
        id = "text",
        x = curX, y = btnY, w = btnSz, h = btnSz,
    }
    curX = curX + btnSz + btnGap * 2

    -- Separator
    local sepC = T.border
    panel:drawRect(curX, btnY, T.px(1), btnSz, sepC.a * 0.4, sepC.r, sepC.g, sepC.b)
    curX = curX + T.px(1) + btnGap * 2

    -- Color swatches. Paint the focus cue in a slightly oversized rect so
    -- it reads clearly around the small 14px swatch without obscuring the
    -- color sample itself.
    local colY = y + math.floor((rowH - colSz) / 2)
    for ci, colorDef in ipairs(MAP_COLORS) do
        local c = colorDef
        local isActiveCol = (ci == activeColor)
        local isFocCol = (focId == "map:color:" .. tostring(ci))

        if isFocCol then
            local ac = T.accent
            panel:drawRect(curX - T.px(2), colY - T.px(2), colSz + T.px(4), colSz + T.px(4),
                0.55, ac.r, ac.g, ac.b)
        end

        panel:drawRect(curX, colY, colSz, colSz, 0.85, c.r, c.g, c.b)
        if isActiveCol then
            local bd = T.text
            panel:drawRectBorder(curX - T.px(1), colY - T.px(1), colSz + T.px(2), colSz + T.px(2),
                bd.a, bd.r, bd.g, bd.b)
        end

        win._mapColorZones[#win._mapColorZones + 1] = {
            idx = ci,
            x = curX, y = colY, w = colSz, h = colSz,
        }

        curX = curX + colSz + btnGap
    end

    -- SURVEY / PAPER, right-anchored before the unfold button (a pill pair: A or a click
    -- switches; only when the base map carries its illustration, and only where it fits)
    win._mapStyleZones = {}
    if ZeD.MapsTab.hasPaper() then
        local f1 = T.fontF1
        local mp = win._worldMapPanel
        local isPaper = mp and mp.paper or false
        local pills = { { id = "survey", text = "Survey" }, { id = "paper", text = "Paper" } }
        local pad = T.px(6)
        local total = 0
        for _, p in ipairs(pills) do p.w = tm:MeasureStringX(f1, p.text) + pad * 2; total = total + p.w end
        local sx = x + w - T.px(4) - btnSz - btnGap * 3 - total
        if sx > curX then
            local ac, bd = T.accent, T.border
            local th = tm:getFontHeight(f1)
            for _, p in ipairs(pills) do
                local on = (p.id == "paper") == isPaper
                if focId == "map:style:" .. p.id then
                    panel:drawRect(sx, btnY, p.w, btnSz, 0.55, ac.r, ac.g, ac.b)
                end
                if on then
                    panel:drawRect(sx, btnY, p.w, btnSz, 0.2, ac.r, ac.g, ac.b)
                    panel:drawRectBorder(sx, btnY, p.w, btnSz, 0.6, ac.r, ac.g, ac.b)
                else
                    panel:drawRectBorder(sx, btnY, p.w, btnSz, bd.a * 0.3, bd.r, bd.g, bd.b)
                end
                local tc = on and T.accent or T.textDim
                panel:drawText(p.text, sx + pad, btnY + math.floor((btnSz - th) / 2), tc.r, tc.g, tc.b, on and 0.9 or 0.7, f1)
                win._mapStyleZones[#win._mapStyleZones + 1] = { id = p.id, x = sx, y = btnY, w = p.w, h = btnSz }
                sx = sx + p.w
            end
        end
    end

    -- S123: UNFOLD / FOLD button, right-anchored. Pops the map out into a
    -- large centred window (ZeD.MapsTab.openPopout) or folds it back.
    do
        local bx = x + w - T.px(4) - btnSz
        local isOpen = win._mapPopout ~= nil
        if focId == "map:popout" then
            local ac = T.accent
            panel:drawRect(bx, btnY, btnSz, btnSz, 0.55, ac.r, ac.g, ac.b)
        end
        local bd = T.border
        panel:drawRectBorder(bx, btnY, btnSz, btnSz, bd.a * 0.3, bd.r, bd.g, bd.b)
        if not win._mapPopoutTex then
            win._mapPopoutTex = getTexture("media/textures/ZeD/icons/crafting-game-037-map.png")
            win._mapFoldTex   = getTexture("media/textures/ZeD/icons/compress.png")
        end
        local tex = isOpen and win._mapFoldTex or win._mapPopoutTex
        local tc = T.text
        if tex then
            panel:drawTextureScaledAspect(tex, bx + T.px(3), btnY + T.px(3), btnSz - T.px(6), btnSz - T.px(6), 0.75, tc.r, tc.g, tc.b)
        else
            panel:drawText(isOpen and "x" or "+", bx + T.px(6), btnY + T.px(2), tc.r, tc.g, tc.b, 0.7, T.fontF1)
        end
        win._mapPopoutZone = { x = bx, y = btnY, w = btnSz, h = btnSz }
    end

    local totalH = rowH

    -- Expanded rows: ALL icons in a wrapping grid
    if expanded then
        local gridX = x + T.px(4)
        local gridY = y + rowH
        local gridW = w - T.px(8)
        local maxCols = math.max(1, math.floor(gridW / (btnSz + btnGap)))
        local col = 0
        local rowIdx = 0

        local bd = T.border
        panel:drawRect(x, gridY - T.px(1), w, T.px(1), bd.a * 0.2, bd.r, bd.g, bd.b)

        local s1 = T.surf1
        local expandedRowCount = math.ceil(#MAP_ICONS / maxCols)
        local expandedH = expandedRowCount * (btnSz + btnGap) + btnGap
        panel:drawRect(x, gridY, w, expandedH, s1.a, s1.r, s1.g, s1.b)

        for _, icon in ipairs(MAP_ICONS) do
            local gx = gridX + col * (btnSz + btnGap)
            local gy = gridY + btnGap + rowIdx * (btnSz + btnGap)
            local isActive = (activeTool == icon.id)
            local isPinned = _isIconPinned(pins, icon.id)
            local isFoc    = (focId == "map:gridtool:" .. icon.id)
            _drawIconBtn(panel, win, icon, gx, gy, btnSz, isActive, isPinned, isFoc)
            -- Tag the zone _drawIconBtn just appended as a grid entry so
            -- the gamepad builder can wire pin-toggle via X on grid icons
            -- without confusing them with pinned-row copies at row-1 Y.
            win._mapToolZones[#win._mapToolZones].isGrid = true

            win._mapToolRMBZones[#win._mapToolRMBZones + 1] = {
                id = icon.id,
                x = gx, y = gy, w = btnSz, h = btnSz,
            }

            col = col + 1
            if col >= maxCols then
                col = 0
                rowIdx = rowIdx + 1
            end
        end

        totalH = totalH + expandedH
    end

    -- Inline text input (visible when text tool is active)
    if textActive then
        local inputY = y + totalH
        local inputX = x + T.px(4)
        local inputW = w - T.px(8)
        local inputBg = T.surf2
        panel:drawRect(x, inputY, w, T.px(MAP_TEXT_INPUT_H), inputBg.a, inputBg.r, inputBg.g, inputBg.b)
        local bds = T.borderS
        panel:drawRect(x, inputY + T.px(MAP_TEXT_INPUT_H) - T.px(1), w, T.px(1), bds.a * 0.3, bds.r, bds.g, bds.b)

        if win._mapTextEntry then
            win._mapTextEntry:setX(inputX)
            win._mapTextEntry:setY(inputY + T.px(2))
            win._mapTextEntry:setWidth(inputW)
            win._mapTextEntry:setHeight(T.px(MAP_TEXT_INPUT_H) - T.px(4))
            win._mapTextEntry:setVisible(true)
        end

        totalH = totalH + T.px(MAP_TEXT_INPUT_H)
    else
        if win._mapTextEntry then
            win._mapTextEntry:setVisible(false)
        end
    end

    return totalH
end

-- ============================================================================
-- MAIN RENDERER
-- ============================================================================

function ZeD.MapsTab.render(panel, win, x, y, w, h)
    local T = ZeD.T

    -- S123: while the map is unfolded into the pop-out, the drawer shows a
    -- fold-back placeholder instead of a second live map (the Java UIWorldMap
    -- is owned by exactly one panel at a time).
    if win._mapPopout and panel ~= win._mapPopout._contentPanel then
        local s1 = T.surf1
        panel:drawRect(x, y, w, h, s1.a, s1.r, s1.g, s1.b)
        local tm = ZeD.TM
        local msg1 = "MAP UNFOLDED"
        local msg2 = "A or click here to fold it back"
        local w1 = tm:MeasureStringX(T.fontF1, msg1)
        local w2 = tm:MeasureStringX(T.fontF1, msg2)
        local fh = tm:getFontHeight(T.fontF1)
        local cy = y + math.floor(h / 2) - fh
        ZeD.Atoms.drawSecondary(panel, msg1, x + math.floor((w - w1) / 2), cy, T.text)
        ZeD.Atoms.drawSecondary(panel, msg2, x + math.floor((w - w2) / 2), cy + fh + T.px(4), T.textDim)
        win._mapFoldZone = { x = x, y = y, w = w, h = h }
        if win._mapTextEntry then win._mapTextEntry:setVisible(false) end
        return
    end
    -- Only the drawer path (no pop-out) may clear the fold zone; the pop-out
    -- renders through this same function every frame and must not race it.
    if not win._mapPopout then win._mapFoldZone = nil end

    -- Toolbar background
    local toolbarBg = T.surf1
    panel:drawRect(x, y, w, T.px(MAP_TOOLBAR_ROW_H), toolbarBg.a, toolbarBg.r, toolbarBg.g, toolbarBg.b)

    -- Lazy-create inline text entry for map annotations
    if not win._mapTextEntry then
        local te = ISTextEntryBox:new("Note", 0, 0, T.px(100), T.px(MAP_TEXT_INPUT_H) - T.px(4))
        te:initialise()
        te.zedEntry = true   -- typed text follows the UI scale (ZeD.Text.fitEntry)
        te:setVisible(false)
        panel:addChild(te)
        win._mapTextEntry = te
    end

    local toolbarH = renderMapToolbar(panel, win, x, y, w)
    local bd = T.border
    panel:drawRect(x, y + toolbarH - T.px(1), w, T.px(1), bd.a * 0.3, bd.r, bd.g, bd.b)

    -- Map area below toolbar
    local mapY = y + toolbarH
    local mapH = h - toolbarH

    -- Lazy-create the world map panel
    if not win._worldMapPanel and not win._worldMapFailed then
        local ok, err = pcall(function()
            local mp = ZeD_WorldMap:new(x, mapY, w, mapH, win._playerObj)
            mp._parentWin = win
            mp:initialise()
            mp:instantiate()
            panel:addChild(mp)
            win._worldMapPanel = mp
        end)
        if not ok then
            win._worldMapFailed = true
        end
    end

    if win._worldMapPanel then
        local mp = win._worldMapPanel
        mp:setX(x)
        mp:setY(mapY)
        mp:setWidth(w)
        mp:setHeight(mapH)
        mp:setVisible(true)
    else
        -- Fallback: show error state
        local secH = ZeD.TM:getFontHeight(T.fontF1)
        local centerX = x + math.floor(w / 2)
        local centerY = mapY + math.floor(mapH / 2) - secH
        local label = "MAP UNAVAILABLE"
        local labelW = ZeD.TM:MeasureStringX(T.fontF1, label)
        ZeD.Atoms.drawSecondary(panel, label, centerX - math.floor(labelW / 2), centerY, T.textDim)
    end
end

-- ============================================================================
-- CLICK HANDLERS
-- ============================================================================

function ZeD.MapsTab.onClick(win, x, y)
    -- S123: clicks on the drawer placeholder while unfolded -> fold back.
    if win._mapPopout and not win._mapClickFromPopout then
        local z = win._mapFoldZone
        if z and x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            ZeD.MapsTab.closePopout(win)
        end
        return
    end
    -- S123: unfold / fold button
    if win._mapPopoutZone then
        local z = win._mapPopoutZone
        if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            if win._mapPopout then ZeD.MapsTab.closePopout(win) else ZeD.MapsTab.openPopout(win) end
            return
        end
    end

    -- SURVEY / PAPER
    for _, z in ipairs(win._mapStyleZones or {}) do
        if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            ZeD.MapsTab.setPaper(win, z.id == "paper")
            return
        end
    end

    -- Disclosure chevron toggle
    if win._mapDisclosureZone then
        local z = win._mapDisclosureZone
        if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            win._mapToolsExpanded = not win._mapToolsExpanded
            return
        end
    end

    -- Icon tool buttons
    if win._mapToolZones then
        for _, zone in ipairs(win._mapToolZones) do
            if x >= zone.x and x <= zone.x + zone.w
               and y >= zone.y and y <= zone.y + zone.h then
                if win._mapActiveTool == zone.id then
                    win._mapActiveTool = nil  -- deselect
                else
                    win._mapActiveTool = zone.id
                end
                return
            end
        end
    end

    -- Color swatches
    if win._mapColorZones then
        for _, zone in ipairs(win._mapColorZones) do
            if x >= zone.x and x <= zone.x + zone.w
               and y >= zone.y and y <= zone.y + zone.h then
                win._mapActiveColor = zone.idx
                return
            end
        end
    end

    -- Forward to map panel for drag-start
    if win._worldMapPanel then
        local mp = win._worldMapPanel
        local mx = x - mp:getX()
        local my = y - mp:getY()
        if mx >= 0 and mx < mp:getWidth() and my >= 0 and my < mp:getHeight() then
            mp:onMouseDown(mx, my)
            win._mapDragging = mp.dragging
        end
    end
end

function ZeD.MapsTab.onRightClick(win, x, y)
    -- Expanded toolbar: RMB toggles pin state
    if win._mapToolsExpanded and win._mapToolRMBZones then
        for _, zone in ipairs(win._mapToolRMBZones) do
            if x >= zone.x and x <= zone.x + zone.w
               and y >= zone.y and y <= zone.y + zone.h then
                local pins = _getMapPins(win._playerObj)
                _togglePin(pins, zone.id)
                return
            end
        end
    end

    -- Forward to map panel for annotation context menu
    if win._worldMapPanel then
        local mp = win._worldMapPanel
        local mx = x - mp:getX()
        local my = y - mp:getY()
        if mx >= 0 and mx < mp:getWidth() and my >= 0 and my < mp:getHeight() then
            mp:onRightMouseDown(mx, my)
        end
    end
end

-- ============================================================================
-- FOCUSABLE BUILDER — ring elements for the World window's worldTabContent
-- ============================================================================
-- Called each frame from ZeD_WorldWindow's per-frame refresh when the Maps
-- tab is active. Returns elements for LB/RB/D-pad navigation across:
--   [disclosure → pinned tool icons → text tool → colors →
--    (if expanded) grid tool icons → canvas cursor]
-- Panel-local coordinates (content-panel-relative) — the same frame used by
-- the mouse hit-zone tables that the render fills each frame.

function ZeD.MapsTab.buildFocusables(win)
    if not win then return {} end
    local elements = {}

    -- S123: while unfolded, the drawer exposes a single "fold" target so A
    -- on the placeholder brings the map back. The pop-out builds its own
    -- elements through _renderPopout (flag set while it does).
    if win._mapPopout and not win._mapBuildingForPopout then
        local z = win._mapFoldZone
        if z then
            elements[1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "map:fold",
                onActivate = function(w, _el) ZeD.MapsTab.closePopout(w) end,
                onCancel   = function(w, _el) ZeD.MapsTab.closePopout(w) end,
            }
        end
        return elements
    end

    -- 1. Disclosure chevron (row 1, always present).
    local dz = win._mapDisclosureZone
    if dz then
        elements[#elements + 1] = {
            x = dz.x, y = dz.y, w = dz.w, h = dz.h,
            id = "map:disclosure",
            isDisclosure = true,
            isMapDisclosure = true,
            onActivate = function(w, _el)
                w._mapToolsExpanded = not w._mapToolsExpanded
            end,
        }
    end

    -- 2. Tool icons (pinned row + grid when expanded) + text tool.
    -- _mapToolZones is appended in draw order: pinned row, then text tool,
    -- then (if expanded) the full grid. Grid entries carry isGrid=true so
    -- we can wire X → pin-toggle on grid items only. Distinct IDs per
    -- position keep the ring free of duplicates (same icon can appear in
    -- both row and grid when pinned).
    if win._mapToolZones then
        for _, tz in ipairs(win._mapToolZones) do
            local isGrid = tz.isGrid == true
            local el = {
                x = tz.x, y = tz.y, w = tz.w, h = tz.h,
                id = (isGrid and "map:gridtool:" or "map:tool:") .. tostring(tz.id),
                isMapTool = true,
                isMapGridTool = isGrid,
                toolId = tz.id,
                onActivate = function(w, el2)
                    -- Re-selecting the active tool deselects; otherwise arm
                    -- the tool. Matches mouse onClick behavior.
                    if w._mapActiveTool == el2.toolId then
                        w._mapActiveTool = nil
                    else
                        w._mapActiveTool = el2.toolId
                    end
                end,
            }
            if isGrid then
                -- X = pin/unpin parity with mouse right-click on grid icons.
                el.onContextMenu = function(w, el2)
                    local pins = _getMapPins(w._playerObj)
                    _togglePin(pins, el2.toolId)
                end
            end
            elements[#elements + 1] = el
        end
    end

    -- 3. Color swatches.
    if win._mapColorZones then
        for _, cz in ipairs(win._mapColorZones) do
            elements[#elements + 1] = {
                x = cz.x, y = cz.y, w = cz.w, h = cz.h,
                id = "map:color:" .. tostring(cz.idx),
                isMapColor = true,
                colorIdx = cz.idx,
                onActivate = function(w, el2)
                    w._mapActiveColor = el2.colorIdx
                end,
            }
        end
    end

    -- 3a. SURVEY / PAPER pills (A switches, as the sub-tab pills do).
    for _, sz in ipairs(win._mapStyleZones or {}) do
        elements[#elements + 1] = {
            x = sz.x, y = sz.y, w = sz.w, h = sz.h,
            id = "map:style:" .. sz.id,
            styleId = sz.id,
            onActivate = function(w, el2) ZeD.MapsTab.setPaper(w, el2.styleId == "paper") end,
        }
    end

    -- 3b. S123: unfold / fold button.
    if win._mapPopoutZone then
        local pz = win._mapPopoutZone
        elements[#elements + 1] = {
            x = pz.x, y = pz.y, w = pz.w, h = pz.h,
            id = "map:popout",
            isMapPopout = true,
            onActivate = function(w, _el)
                if w._mapPopout then ZeD.MapsTab.closePopout(w) else ZeD.MapsTab.openPopout(w) end
            end,
        }
    end

    -- 4. Canvas cursor pseudo-focusable (always last). Bounds = the map
    -- panel's bbox inside the content panel, so cone-nav from toolbar
    -- elements naturally drops onto the canvas when the user D-pads down.
    -- D-pad WHILE this element is focused is intercepted at win-level and
    -- routed to ZeD.MapsTab.gpMoveCursor — see ZeD_WorldWindow joypadDir
    -- handlers.
    local mp = win._worldMapPanel
    if mp then
        elements[#elements + 1] = {
            x = mp:getX(),
            y = mp:getY(),
            w = mp:getWidth(),
            h = mp:getHeight(),
            id = "map:canvas:cursor",
            isCanvasCursor = true,
            mapWin = win,      -- the window that owns the map (the pop-out's copies keep it)
            extraPrompts = { { glyph = "RT LT", label = "Zoom" }, { glyph = "L-STICK", label = "Move" } },
            onFocus = function(w, _el)
                -- Seed cursor on first landing so the crosshair appears
                -- immediately (not after first D-pad press).
                local mp2 = w._worldMapPanel
                if mp2 and mp2.seedGpCursor then mp2:seedGpCursor() end
            end,
            onActivate = function(w, _el)
                ZeD.MapsTab.gpPlaceAtCursor(w)
            end,
            onContextMenu = function(w, _el)
                ZeD.MapsTab.gpContextMenuAtCursor(w)
            end,
            -- Oct 19 2026 (the nav audit; director: "the map tab was
            -- particularly unfriendly to my logic"): the D-pad no longer
            -- moves the cursor. It moved it from S113 on, so on the map the
            -- D-pad stopped navigating (only B got out). Now the D-pad
            -- navigates here as everywhere; the left stick moves the cursor
            -- (pushing it at an edge pans the map) and the triggers zoom,
            -- as the footer says.
            onCancel = function(w, _el)
                -- B tap: if a tool is armed, exit tool mode and consume B.
                -- Otherwise (no tool), escape the cursor entirely by jumping
                -- focus to the first non-cursor toolbar element above. The
                -- cursor's onDpadDir intercepts ALL D-pad presses for cursor
                -- movement, so without this escape the user is stuck on the
                -- canvas with no way to reach the toolbar (S113c QA finding).
                if w._mapActiveTool then
                    w._mapActiveTool = nil
                    w._mapEditAnnotIdx = nil
                    return true
                end
                if w._focusRing then
                    for zi, z in ipairs(w._focusRing) do
                        if z.zone == "worldTabContent" and z.focusable
                           and z.elements and #z.elements > 0 then
                            for ei, el in ipairs(z.elements) do
                                if not el.isCanvasCursor then
                                    w._focusIdx = zi
                                    z.focusedElementIdx = ei
                                    if el.onFocus then
                                        pcall(el.onFocus, w, el)
                                    end
                                    return true
                                end
                            end
                        end
                    end
                end
                return true
            end,
        }
    end

    return elements
end

-- ============================================================================
-- GAMEPAD HELPERS — exported for ring wiring and win-level D-pad intercept
-- ============================================================================
-- The Maps tab registers a canvas-cursor pseudo-focusable in the world
-- window's ring. When that element is focused, D-pad is intercepted at the
-- World window level and routed to gpMoveCursor — it nudges the cursor in
-- panel-local pixels, and when the cursor approaches a viewport margin it
-- pans the world instead so the cursor sits at the margin and the map
-- scrolls underneath (classic "scrolloff" pattern).

local MAP_GP_STEP_PX       = 6    -- cursor pixels per D-pad press (held: speeds up to MAP_GP_STEP_MAX)
local MAP_GP_STEP_MAX      = 40   -- cursor pixels per press once the D-pad has been held a while
local MAP_GP_STICK_PX_S    = 900  -- cursor pixels a second with the left stick fully over
local MAP_GP_STICK_DEAD    = 0.22 -- left stick dead zone
local MAP_GP_ZOOM_EVERY_MS = 110  -- one zoom step this often while a trigger is pulled
local MAP_GP_PAN_MARGIN_PX = 48   -- viewport margin that triggers auto-pan
local MAP_GP_HIT_RADIUS_PX = 16   -- annotation hit radius for X-press

-- Nudge the gamepad cursor by (dx, dy) panel-pixels. If the cursor would
-- leave the inner viewport (panel minus margin), clamp it to the margin and
-- pan the world by the overshoot instead. Converts panel-pixel overshoot
-- to world-coord delta via a two-point uiToWorld sample so the conversion
-- survives any projection tweaks (isometric vs top-down).
function ZeD.MapsTab.gpMoveCursor(win, dx, dy)
    local T = ZeD.T
    if not win then return end
    local mp = win._worldMapPanel
    if not mp then return end
    mp:seedGpCursor()

    local pw, ph   = mp:getWidth(), mp:getHeight()
    local margin   = T.px(MAP_GP_PAN_MARGIN_PX)
    local cxWant   = mp._gpCursorX + (dx or 0)
    local cyWant   = mp._gpCursorY + (dy or 0)
    local panDX, panDY = 0, 0

    if cxWant < margin then
        panDX = cxWant - margin
        mp._gpCursorX = margin
    elseif cxWant > pw - margin then
        panDX = cxWant - (pw - margin)
        mp._gpCursorX = pw - margin
    else
        mp._gpCursorX = cxWant
    end

    if cyWant < margin then
        panDY = cyWant - margin
        mp._gpCursorY = margin
    elseif cyWant > ph - margin then
        panDY = cyWant - (ph - margin)
        mp._gpCursorY = ph - margin
    else
        mp._gpCursorY = cyWant
    end

    if panDX ~= 0 or panDY ~= 0 then
        local mapAPI = mp.mapAPI
        local wx0 = mapAPI:uiToWorldX(0, 0)
        local wx1 = mapAPI:uiToWorldX(1, 0)
        local wy0 = mapAPI:uiToWorldY(0, 0)
        local wy1 = mapAPI:uiToWorldY(0, 1)
        local wppx = wx1 - wx0
        local wppy = wy1 - wy0
        mapAPI:centerOn(
            mapAPI:getCenterWorldX() + panDX * wppx,
            mapAPI:getCenterWorldY() + panDY * wppy)
    end
end

-- A-press while canvas cursor is focused: place an annotation at the cursor
-- if a tool is armed. Delegates to _placeAnnotationAt so mouse and gamepad
-- share one placement path.
function ZeD.MapsTab.gpPlaceAtCursor(win)
    if not win then return end
    local mp = win._worldMapPanel
    if not mp or not mp._gpCursorX then return end
    _placeAnnotationAt(mp, mp._gpCursorX, mp._gpCursorY)
end

-- Return the annotation hit (from mp._annotationHits) whose center is within
-- the hit radius of the cursor, or nil. The hits table is refreshed each
-- frame by renderAnnotations; this uses the most recent pass.
function ZeD.MapsTab.gpFindAnnotAtCursor(win)
    local T = ZeD.T
    if not win then return nil end
    local mp = win._worldMapPanel
    if not mp or not mp._annotationHits or not mp._gpCursorX then return nil end
    local cx, cy = mp._gpCursorX, mp._gpCursorY
    local rSq = T.px(MAP_GP_HIT_RADIUS_PX) * T.px(MAP_GP_HIT_RADIUS_PX)
    for _, hit in ipairs(mp._annotationHits) do
        local hx = hit.x + hit.w / 2
        local hy = hit.y + hit.h / 2
        local ddx = cx - hx
        local ddy = cy - hy
        if ddx * ddx + ddy * ddy <= rSq then
            return hit
        end
    end
    return nil
end

-- X-press while canvas cursor is focused: if the cursor is over an
-- annotation, open the edit/delete/recolor context menu at the cursor's
-- absolute screen position. No-op when the cursor isn't on an annotation
-- (avoids emitting an empty menu).
function ZeD.MapsTab.gpContextMenuAtCursor(win)
    if not win then return end
    local mp = win._worldMapPanel
    if not mp or not mp._gpCursorX then return end
    local hit = ZeD.MapsTab.gpFindAnnotAtCursor(win)
    if not hit then return end
    _openAnnotContextMenu(mp,
        mp:getAbsoluteX() + mp._gpCursorX,
        mp:getAbsoluteY() + mp._gpCursorY,
        hit.idx)
end

-- Step per D-pad press: small for a tap, growing while the D-pad is held
-- (presses closer than 250 ms apart are the hold's repeats). Director, Oct 15
-- 2026: "Map is really hard to use on controller".
local _gpStep = { t = 0, n = 0 }
function ZeD.MapsTab.gpCursorStep()
    local T = ZeD.T
    local now = getTimestampMs()
    if now - _gpStep.t < 250 then _gpStep.n = _gpStep.n + 1 else _gpStep.n = 0 end
    _gpStep.t = now
    local px = math.min(MAP_GP_STEP_MAX, MAP_GP_STEP_PX + _gpStep.n * 3)
    return T.px(px)
end

-- Zoom the map one step on the controller's cursor (dir -1 in, +1 out: the
-- mouse wheel's sense)
function ZeD.MapsTab.gpZoom(win, dir)
    local mp = win and win._worldMapPanel
    if not (mp and mp.mapAPI) then return end
    mp:seedGpCursor()
    mp.mapAPI:zoomAt(mp._gpCursorX, mp._gpCursorY, dir)
end

-- Every tick, while the map's canvas has the controller: the left stick moves
-- the cursor (panning at the edges), the triggers zoom on it (RT in, LT out).
local _pad = { t = 0, zoomAt = 0, rest = {} }
local function _triggerPull(cid, axis)
    local v = getControllerAxisValue(cid, axis) or 0
    local key = cid * 8 + axis
    local rest = _pad.rest[key]
    if rest == nil or v < rest then rest = v; _pad.rest[key] = v end
    local travel = (rest < -0.5) and 2 or 1          -- XInput triggers rest at -1 (see InputModeDetector)
    return (v - rest) / travel
end
local function _mapPadTick()
    local now = getTimestampMs()
    local dt = math.min(0.1, (now - _pad.t) / 1000)
    _pad.t = now
    local Focus = ZeD.Input and ZeD.Input.Focus
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Focus and Focus.getFocusedWindow and Det and Det.getMode and Det.getMode() == "gamepad") then return end
    local fw = Focus.getFocusedWindow()
    local el = fw and Focus.getFocusedElement and Focus.getFocusedElement(fw)
    if not (el and el.isCanvasCursor and el.mapWin) then return end
    local win = el.mapWin
    local mp = win._worldMapPanel
    if not (mp and mp:isReallyVisible()) then return end
    local jd = getJoypadData and getJoypadData(0)
    local cid = jd and jd.id
    if not cid then return end
    -- the left stick
    local sx = getControllerAxisValue(cid, 0) or 0
    local sy = getControllerAxisValue(cid, 1) or 0
    local mag = math.sqrt(sx * sx + sy * sy)
    if mag > MAP_GP_STICK_DEAD then
        local k = ((math.min(1, mag) - MAP_GP_STICK_DEAD) / (1 - MAP_GP_STICK_DEAD))
        local speed = ZeD.T.px(MAP_GP_STICK_PX_S) * k * k * dt / mag
        ZeD.MapsTab.gpMoveCursor(win, sx * speed, sy * speed)
    end
    -- the triggers
    local lt, rt = _triggerPull(cid, 4), _triggerPull(cid, 5)
    local dir = (rt > 0.3 and -1) or (lt > 0.3 and 1) or 0
    if dir ~= 0 and now >= _pad.zoomAt then
        ZeD.MapsTab.gpZoom(win, dir)
        _pad.zoomAt = now + MAP_GP_ZOOM_EVERY_MS
    elseif dir == 0 then
        _pad.zoomAt = 0
    end
end
if Events and Events.OnTick then Events.OnTick.Add(_mapPadTick) end

-- ============================================================================
-- POP-OUT (S123) -- "unfold" the map into a large centred window.
--
-- Mode, not a new feature: the pop-out reuses the SAME toolbar, tools,
-- colours, pins, annotations, cursor and gamepad wiring as the drawer. The
-- live Java UIWorldMap can only belong to one panel, so while the pop-out
-- is open the drawer's map is parked (invisible) and the drawer renders a
-- fold-back placeholder. Closing restores the drawer map untouched.
--
-- Gamepad: the pop-out registers as its own FocusManager window with one
-- zone ("popMapContent"); elements come from the shared buildFocusables
-- with every callback re-bound to the WORLD window (which owns the map
-- state), and B on any of them folds the map back.
-- ============================================================================

function ZeD.MapsTab.isPopoutOpen(win)
    return win ~= nil and win._mapPopout ~= nil
end

function ZeD.MapsTab._renderPopout(content, win, pop)
    if not win or not pop or win._mapPopout ~= pop then return end
    -- Track the window size (resizable chrome).
    local bw = pop:getWidth()
    local bh = pop:getBodyHeight()
    if content:getWidth() ~= bw then content:setWidth(bw) end
    if content:getHeight() ~= bh then content:setHeight(bh) end
    if content:getY() ~= pop:getBodyY() then content:setY(pop:getBodyY()) end

    ZeD.MapsTab.render(content, win, 0, 0, bw, bh)

    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if not Focus or not pop._focusRing then return end
    win._mapBuildingForPopout = true
    local ok, src = pcall(ZeD.MapsTab.buildFocusables, win)
    win._mapBuildingForPopout = false
    if not ok or not src then return end

    -- Re-bind callbacks to the world window; B folds the map on any element.
    local wrapped = {}
    for i = 1, #src do
        local el = src[i]
        local e = {}
        for k, v in pairs(el) do e[k] = v end
        if el.onActivate     then e.onActivate     = function(_, ee)      return el.onActivate(win, ee) end end
        if el.onContextMenu  then e.onContextMenu  = function(_, ee)      return el.onContextMenu(win, ee) end end
        if el.onHoldActivate then e.onHoldActivate = function(_, ee)      return el.onHoldActivate(win, ee) end end
        if el.onFocus        then e.onFocus        = function(_, ee)      return el.onFocus(win, ee) end end
        if el.onDpadDir      then e.onDpadDir      = function(_, ee, dir) return el.onDpadDir(win, ee, dir) end end
        e.onCancel = function(_, _ee) ZeD.MapsTab.closePopout(win) end
        e.promptB  = "Fold"
        wrapped[#wrapped + 1] = e
    end

    -- Identity-preserve focus by id across the per-frame rebuild.
    local preserveIdx = nil
    local zone = pop._focusRing[1]
    local oldEl = zone and zone.elements and zone.elements[zone.focusedElementIdx or 1]
    if oldEl and oldEl.id then
        for i, e in ipairs(wrapped) do if e.id == oldEl.id then preserveIdx = i; break end end
    end
    -- First landing: start on the canvas cursor so D-pad pans immediately.
    if not preserveIdx and not pop._mapPopSeeded then
        for i, e in ipairs(wrapped) do if e.isCanvasCursor then preserveIdx = i; break end end
        if preserveIdx then pop._mapPopSeeded = true end
    end
    Focus.setRingZoneElements(pop, "popMapContent", wrapped, preserveIdx)
    Focus.setZoneFocusable(pop, "popMapContent", #wrapped > 0)
end

function ZeD.MapsTab.openPopout(win)
    local T = ZeD.T
    if not win or win._mapPopout then return end
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local pw = math.max(T.px(600), math.floor(sw * 0.72))
    local ph = math.max(T.px(400), math.floor(sh * 0.78))
    local pop = ZeD_Window:new(math.floor((sw - pw) / 2), math.floor((sh - ph) / 2), pw, ph, "Map")
    pop:initialise()
    pop:addToUIManager()
    pop._zedLabel     = "MapPopout"
    pop._isMapPopout  = true
    pop._worldWin     = win
    pop.minimumWidth  = T.px(600)
    pop.minimumHeight = T.px(400)

    local content = ZeD_Panel:new(0, pop:getBodyY(), pw, pop:getBodyHeight())
    content:initialise()
    pop:addChild(content)
    pop._contentPanel = content
    content._onPrerender = function(self) ZeD.MapsTab._renderPopout(self, win, pop) end

    -- Mouse: same handlers the World drawer uses, routed through the shared
    -- MapsTab entry points. The flag tells onClick the click is the pop-out's.
    content.onMouseDown = function(self, x, y)
        win._mapClickFromPopout = true
        ZeD.MapsTab.onClick(win, x, y)
        win._mapClickFromPopout = false
        return true
    end
    content.onRightMouseDown = function(self, x, y)
        win._mapClickFromPopout = true
        ZeD.MapsTab.onRightClick(win, x, y)
        win._mapClickFromPopout = false
        return true
    end
    local function dragMove(self, dx, dy)
        if win._mapDragging then
            if not isMouseButtonDown(0) then
                if win._worldMapPanel then win._worldMapPanel:onMouseUp(0, 0) end
                win._mapDragging = false
            elseif win._worldMapPanel then
                win._worldMapPanel:onMouseMove(dx, dy)
            end
        end
    end
    content.onMouseMove        = function(self, dx, dy) ISPanel.onMouseMove(self, dx, dy); dragMove(self, dx, dy) end
    content.onMouseMoveOutside = function(self, dx, dy) ISPanel.onMouseMoveOutside(self, dx, dy); dragMove(self, dx, dy) end
    content.onMouseUp = function(self, x, y)
        if win._mapDragging then
            if win._worldMapPanel then win._worldMapPanel:onMouseUp(x, y) end
            win._mapDragging = false
        end
        return true
    end
    content.onMouseUpOutside = content.onMouseUp
    content.onMouseWheel = function(self, del)
        if win._worldMapPanel then win._worldMapPanel:onMouseWheel(del) end
        return true
    end

    -- Park the drawer's live map and text entry; render() builds fresh ones
    -- inside the pop-out on its first frame.
    win._worldMapPanelInline = win._worldMapPanel
    if win._worldMapPanelInline then win._worldMapPanelInline:setVisible(false) end
    win._worldMapPanel = nil
    win._mapTextEntryInline = win._mapTextEntry
    if win._mapTextEntryInline then win._mapTextEntryInline:setVisible(false) end
    win._mapTextEntry = nil
    win._mapDragging = false
    win._mapPopout = pop

    -- Gamepad registration: one content zone, elements rebuilt per frame.
    pop._focusRing = {
        { zone = "popMapContent", focusable = false, elements = {}, focusedElementIdx = 1,
          uiRange = function(w) return 0, w:getWidth() end },
    }
    pop._focusIdx = 1
    pop.close = function(self) ZeD.MapsTab.closePopout(win) end

    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if Focus then
        Focus.registerWindow(pop)
        Focus.claimFocus(pop)
    end
    pcall(function() getSoundManager():playUISound("UIActivateTab") end)
end

function ZeD.MapsTab.closePopout(win)
    local pop = win and win._mapPopout
    if not pop then return end
    win._mapPopout = nil
    win._mapDragging = false

    -- Drop the pop-out's map and text entry (children of the pop-out), then
    -- restore the drawer's parked ones.
    local big = win._worldMapPanel
    if big then pcall(function() big:setVisible(false) end) end
    if win._mapTextEntry then pcall(function() win._mapTextEntry:setVisible(false) end) end
    win._worldMapPanel = win._worldMapPanelInline
    win._worldMapPanelInline = nil
    win._mapTextEntry = win._mapTextEntryInline
    win._mapTextEntryInline = nil
    win._mapFoldZone = nil

    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if Focus then Focus.unregisterWindow(pop) end   -- hands focus back to the last registered window
    pcall(function() pop:removeFromUIManager() end)
    pcall(function() getSoundManager():playUISound("UIActivateTab") end)
    -- the controller lands back on the unfold button it left from (Oct 19 2026
    -- nav audit: it landed on the tab column)
    if Focus and Focus.focusByIdSoon then
        Focus.claimFocus(win)
        Focus.focusByIdSoon(win, "worldTabContent", "map:popout")
    end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.MapsTab.register(dispatchTable)
    dispatchTable["maps"] = ZeD.MapsTab.render
end
