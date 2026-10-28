-- ZeD-UI/42/media/lua/client/ZeD/MapsTab.lua
-- ============================================================================
-- MAPS TAB — World Window standalone tab.
-- Embedded UIWorldMap with stash map markers, flyer location dots,
-- user-placed marks (15 icons, 5 inks, text notes). Since Oct 20 2026 the
-- marks live in vanilla's own map store and the engine draws them
-- (MapNotes.lua); the old modData.ZeD_MapAnnotations is only a backup.
-- ============================================================================

require "ZeD/MapNotes"
require "ZeD/FlyerMap"
require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/MapsTabExt"
require "ISUI/Maps/ISMapDefinitions"

ZeD = ZeD or {}
ZeD.MapsTab = ZeD.MapsTab or {}
local Ext = ZeD.MapsTabExt   -- other pieces on the map: MapsTabExt.lua (ZeD.MapsTab.addExtension)

-- ============================================================================
-- CONSTANTS — duplicated from JournalTab (may diverge)
-- ============================================================================

-- (key: the mark's name, its toolbar button's hint)
local MAP_ICONS = {
    { id = "house",       tex = "media/ui/LootableMaps/map_house.png",       label = "House",    key = "UI_ZeD_Map_MarkHouse" },
    { id = "target",      tex = "media/ui/LootableMaps/map_target.png",      label = "Target",   key = "UI_ZeD_Map_MarkTarget" },
    { id = "skull",       tex = "media/ui/LootableMaps/map_skull.png",       label = "Skull",    key = "UI_ZeD_Map_MarkSkull" },
    { id = "star",        tex = "media/ui/LootableMaps/map_star.png",        label = "Star",     key = "UI_ZeD_Map_MarkStar" },
    { id = "cross",       tex = "media/ui/LootableMaps/map_cross.png",       label = "Cross",    key = "UI_ZeD_Map_MarkCross" },
    { id = "heart",       tex = "media/ui/LootableMaps/map_heart.png",       label = "Heart",    key = "UI_ZeD_Map_MarkHeart" },
    { id = "exclamation", tex = "media/ui/LootableMaps/map_exclamation.png", label = "Alert",    key = "UI_ZeD_Map_MarkAlert" },
    { id = "question",    tex = "media/ui/LootableMaps/map_question.png",    label = "Question", key = "UI_ZeD_Map_MarkQuestion" },
    { id = "fire",        tex = "media/ui/LootableMaps/map_firet.png",       label = "Fire",     key = "UI_ZeD_Map_MarkFire" },
    { id = "gun",         tex = "media/ui/LootableMaps/map_gun.png",         label = "Gun",      key = "UI_ZeD_Map_MarkGun" },
    { id = "burger",      tex = "media/ui/LootableMaps/map_burger.png",      label = "Food",     key = "UI_ZeD_Map_MarkFood" },
    { id = "axe",         tex = "media/ui/LootableMaps/map_axe.png",         label = "Axe",      key = "UI_ZeD_Map_MarkAxe" },
    { id = "gears",       tex = "media/ui/LootableMaps/map_gears.png",       label = "Gears",    key = "UI_ZeD_Map_MarkGears" },
    { id = "x",           tex = "media/ui/LootableMaps/map_x.png",          label = "X",        key = "UI_ZeD_Map_MarkX" },
    { id = "checkmark",   tex = "media/ui/LootableMaps/map_checkmark.png",   label = "Check",    key = "UI_ZeD_Map_MarkCheck" },
}

-- vanilla's inks (MapNotes.INKS: the colour vanilla's map gives each pen), so
-- the swatch, the preview and the mark the engine draws are one colour
local MAP_COLORS = {}
for i, k in ipairs(ZeD.MapNotes.INKS) do
    MAP_COLORS[i] = { r = k.r, g = k.g, b = k.b, a = 1.0, label = k.item }
end

-- design units (the tool buttons are the library's icon buttons, T.buttonH square)
local MAP_ICON_BTN_GAP  = 4
local MAP_COLOR_SZ      = 14
-- Sourced from ZeD.Spacing.tabHeaderH so all drawer / toolbar headers stay
-- in lockstep when the token is tuned.
local MAP_TOOLBAR_ROW_H = (ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37
local MAP_TEXT_INPUT_H   = 24

local MAP_DEFAULT_PINS = { "house", "target", "skull", "star", "cross", "checkmark" }

-- each mark by id, and its controller ids on the toolbar's row and in the full set
local MAP_ICON_BY_ID = {}
for i, icon in ipairs(MAP_ICONS) do
    MAP_ICON_BY_ID[icon.id] = icon
    icon.toolFid = "map:tool:" .. icon.id
    icon.gridFid = "map:gridtool:" .. icon.id
end

-- ============================================================================
-- VANILLA'S MAP RULES — whether there is a map, and whether it can be read
-- ============================================================================

-- The server / sandbox "Allow World Map" setting, and no map in the Tutorial
-- (ISWorldMap.IsAllowed).
function ZeD.MapsTab.isAllowed()
    if ISWorldMap and ISWorldMap.IsAllowed then return ISWorldMap.IsAllowed() == true end
    if getCore():getGameMode() == "Tutorial" then return false end
    return SandboxVars.Map ~= nil and SandboxVars.Map.AllowWorldMap == true
end

-- "Map needs light": vanilla's check before it opens the map
-- (ISWorldMap.ToggleWorldMap). Too dark to read unless an admin, in debug, or
-- in a vehicle with a live battery, a torch on, or any charge left.
function ZeD.MapsTab.tooDark(playerObj)
    if not playerObj then return false end
    local needs
    if ISWorldMap and ISWorldMap.NeedsLight then needs = ISWorldMap.NeedsLight()
    else needs = SandboxVars.Map ~= nil and SandboxVars.Map.MapNeedsLight == true end
    if not needs then return false end
    if isAdmin() or getCore():getDebug() then return false end
    if not playerObj:tooDarkToRead() then return false end
    local v = playerObj:getVehicle()
    if v and (v:hasLiveBattery() or playerObj:getTorchStrength() > 0 or v:getBatteryCharge() > 0) then
        return false
    end
    return true
end

-- ============================================================================
-- INK — vanilla's rules for marking the map (ISWorldMapSymbols canWrite,
-- canErase, checkInventory). Each colour needs its own pen or pencil; a mark
-- needs something to write with; changing or deleting one needs an eraser;
-- an illiterate character cannot write or edit notes (symbols are fine).
-- ============================================================================

-- the pen behind each of MAP_COLORS (same order), and vanilla's line for a missing one
local MAP_COLOR_PENS = {
    { item = "Pencil",   need = "Tooltip_Map_NeedPencil" },
    { item = "Pen",      need = "Tooltip_Map_NeedBlackPen" },
    { item = "BluePen",  need = "Tooltip_Map_NeedBluePen" },
    { item = "RedPen",   need = "Tooltip_Map_NeedRedPen" },
    { item = "GreenPen", need = "Tooltip_Map_NeedGreenPen" },
}

-- a pen by its tag or its type, as vanilla looks for one
local function _invHasPen(inv, item)
    local ok, has = pcall(function()
        return inv:containsTagRecurse(ItemTag.get(ResourceLocation.of(item)))
    end)
    if ok and has then return true end
    return inv:containsTypeRecurse(item) == true
end

-- What the character can mark with: pen[i] per colour, write, erase, literate.
-- Looked up at most four times a second (the toolbar asks every frame); an
-- action passes fresh = true to look again right then.
local _ink = { t = -1, pen = {} }
local function _mapInk(playerObj, fresh)
    local now = getTimestampMs()
    if not fresh and _ink.who == playerObj and now - _ink.t < 250 then return _ink end
    _ink.who, _ink.t = playerObj, now
    local inv = playerObj and playerObj:getInventory()
    _ink.write = false
    for i, p in ipairs(MAP_COLOR_PENS) do
        local has = (inv == nil) or _invHasPen(inv, p.item)
        _ink.pen[i] = has
        if has then _ink.write = true end
    end
    _ink.erase = (inv == nil) or inv:containsTypeRecurse("Base.Eraser") or inv:containsTagRecurse(ItemTag.ERASER)
    _ink.literate = not (playerObj and playerObj:hasTrait(CharacterTrait.ILLITERATE))
    return _ink
end

-- vanilla's line over the character's head
local function _inkSay(playerObj, key)
    if playerObj and HaloTextHelper then HaloTextHelper.addBadText(playerObj, getText(key)) end
end

-- whether a tool can be used, and vanilla's reason when not
local function _toolAllowed(toolId, ink)
    if not ink.write then return false, "Tooltip_Map_CantWrite" end
    if toolId == "text" and not ink.literate then return false, "ContextMenu_Illiterate" end
    return true
end

-- whether a mark can be changed (new text or colour), and why not
local function _editAllowed(ink)
    if not ink.literate then return false, "ContextMenu_Illiterate" end
    if not (ink.write and ink.erase) then return false, "Tooltip_Map_CantEdit" end
    return true
end

-- The colour to mark with: the chosen one while its pen is at hand, else the
-- first colour that is (vanilla picks the first pen it finds the same way).
local function _inkColor(win, ink)
    local c = win._mapActiveColor or 1
    if ink.pen[c] then return c end
    for i = 1, #MAP_COLORS do
        if ink.pen[i] then win._mapActiveColor = i; return i end
    end
    return nil
end

-- the next colour round from cur that has its pen
local function _nextInkColor(cur, ink)
    for step = 1, #MAP_COLORS do
        local i = ((cur - 1 + step) % #MAP_COLORS) + 1
        if ink.pen[i] then return i end
    end
    return cur
end

-- Every frame from the toolbar: a tool whose pen was put away is put down, as
-- vanilla's map does when the inventory changes, and the colour follows the pens.
local function _enforceInk(win)
    local ink = _mapInk(win._playerObj)
    local tool = win._mapActiveTool
    if tool then
        local ok = _toolAllowed(tool, ink)
        if ok and tool == "text" and win._mapEdit then ok = _editAllowed(ink) end
        if not ok then win._mapActiveTool = nil; win._mapEdit = nil end
    end
    if ink.write then _inkColor(win, ink) end
    return ink
end

-- Toolbar or A press on a tool: pick it up (or put it down again)
local function _armTool(win, toolId)
    if win._mapActiveTool == toolId then
        win._mapActiveTool = nil
        win._mapEdit = nil
        return
    end
    local ok, why = _toolAllowed(toolId, _mapInk(win._playerObj, true))
    if not ok then _inkSay(win._playerObj, why); return end
    win._mapActiveTool = toolId
    win._mapEdit = nil
    Ext.putDownAll(win)   -- (an extension's own tool, the drawing pencil say, goes down)
end

-- For the extensions (MapsTabExt.lua): vanilla's ink rules as the toolbar keeps
-- them. ink(win, fresh) -> { pen = {..}, write, erase, literate }; inkColor(win)
-- -> the colour marks are made in now ({ r, g, b }) and its index, or nil with no
-- pen at hand; say(playerObj, key): vanilla's line over the head; putDownTool(win):
-- ZeD's own mark tool down (an extension picked up its own).
function ZeD.MapsTab.ink(win, fresh) return _mapInk(win and win._playerObj, fresh) end
function ZeD.MapsTab.inkColor(win)
    local i = _inkColor(win, _mapInk(win._playerObj))
    if not i then return nil end
    return MAP_COLORS[i], i
end
ZeD.MapsTab.say = function(playerObj, key) _inkSay(playerObj, key) end
function ZeD.MapsTab.putDownTool(win)
    win._mapActiveTool = nil
    win._mapEdit = nil
end

-- Toolbar or A press on a colour: only a colour whose pen is at hand
local function _pickColor(win, idx)
    local ink = _mapInk(win._playerObj, true)
    if not ink.pen[idx] then
        local p = MAP_COLOR_PENS[idx]
        _inkSay(win._playerObj, p and p.need or "Tooltip_Map_CantWrite")
        return
    end
    win._mapActiveColor = idx
end

-- a context-menu option greyed out with vanilla's reason on hover
local function _optionNeeds(opt, key)
    if not opt then return end
    opt.notAvailable = true
    local tip = ISToolTip:new()
    tip:initialise()
    tip:setVisible(false)
    tip.description = getText(key)
    opt.toolTip = tip
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
-- SURVEY / COLOR / PAPER — System 7 radio buttons on the toolbar where they
-- fit; else a pop-up menu (the World window's drawer), whose list opens under
-- its box over the map. These open and shut that list, and take a click while
-- it is open.
-- ============================================================================

local STYLE_ORDER = { "survey", "color", "paper" }
local STYLE_WORD  = { survey = "UI_ZeD_Map_StyleSurvey", color = "UI_ZeD_Map_StyleColor", paper = "UI_ZeD_Map_StylePaper" }
local STYLE_HELP  = { survey = "UI_ZeD_Map_HelpStyleSurvey", color = "UI_ZeD_Map_HelpStyleColor", paper = "UI_ZeD_Map_HelpStylePaper" }

-- where the map's controls are for the controller: the unfolded window's zone,
-- or the World window's drawer's
local function _padHome(win)
    if win._mapPopout then return win._mapPopout, "popMapContent" end
    return win, "worldTabContent"
end

-- the controller lands on the element with this id once it is there
local function _padLand(win, id)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.focusByIdSoon) then return end
    local w, zone = _padHome(win)
    Focus.focusByIdSoon(w, zone, id)
end

-- Open the list (a press on the box). From the controller, focus goes to the
-- current choice in it.
local function _openStyleMenu(win, fromPad)
    win._mapStyleMenuOpen = true
    win._mapStyleMenuZones = nil
    if fromPad then
        local mp = win._worldMapPanel
        _padLand(win, "map:styleRow:" .. tostring(mp and mp.style or "survey"))
    end
end

-- Shut the list. From the controller, focus goes back to the box.
local function _closeStyleMenu(win, fromPad)
    win._mapStyleMenuOpen = nil
    win._mapStyleMenuZones = nil
    if fromPad then _padLand(win, "map:style:menu") end
end

-- A press (tab coordinates) while the list is open: a choice is taken, and any
-- press shuts the list. True when the list was open (the press was its).
local function _styleMenuClick(win, x, y)
    if not win._mapStyleMenuOpen then return false end
    for _, z in ipairs(win._mapStyleMenuZones or {}) do
        if x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h then
            ZeD.MapsTab.setStyle(win, z.id)
            break
        end
    end
    _closeStyleMenu(win, false)
    return true
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
    -- the world map's own item, as vanilla's map binds it (ISWorldMap:instantiate):
    -- the engine then draws vanilla's store of marks and notes on this map
    -- (MapNotes.lua). First, before anything asks the map for its symbols.
    ZeD.MapNotes.bind(self)
    if self.playerObj then pcall(ZeD.MapNotes.migrate, self.playerObj) end

    -- Configure: top-down, no debug, fog-of-war ("HideUnvisited", as vanilla's in-game map sets
    -- it in ISWorldMap:initDataAndStyle; the engine's default is off, and this read
    -- "HideUnvisitedAreas" until Oct 15 2026, a name the engine does not have: the whole county
    -- showed whatever the character had explored)
    self.mapAPI:setBoolean("Isometric", false)
    self.mapAPI:setBoolean("DebugInfo", false)
    self.mapAPI:setBoolean("HideUnvisited", true)
    -- the game's own dots for players, as the server allows (Oct 26 2026, the
    -- map mods pass; Players On Map draws its own squares and names over them)
    pcall(function()
        self.mapAPI:setBoolean("Players", true)
        if isClient() then self.mapAPI:setBoolean("RemotePlayers", true) end
    end)

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

-- THE THREE MAPS (director, Oct 15 2026: "the paper map used in the location selection ...
-- options to show both the paper map and ingame map?"; Oct 19 2026: "there should be two
-- survey maps, one in color"). SURVEY is vanilla's in-game map (its data, streets and
-- style); COLOR is the same ground as the base map's colour picture (pyramid.zip, the
-- aerial look); PAPER is the illustrated county map the spawn screen shows (the base map's
-- spawnSelectImagePyramid, laid out in world squares: not as detailed up close, but fun to
-- look at). All keep vanilla's fog of war: only explored ground shows.
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

-- S124: the label layers are sized in their own units (ISMapDefinitions: 48 / 40 / 32); scale them
-- with the root so street and town names, and the player's notes, grow with the rest of the UI.
local function scaleLabels(mp)
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
end

-- Over a picture (Color, Paper) the map still needs vanilla's text layers: the
-- player's notes are written in "text-note" (vanilla's hand) and the map's own
-- labels in theirs, as on vanilla's map. Without them the engine falls back to
-- one default hand for every label.
local function initTextLayers(mp)
    if MapUtils and MapUtils.initDefaultTextLayersV3 then pcall(MapUtils.initDefaultTextLayersV3, mp) end
    scaleLabels(mp)
end

-- The map's own place labels: every text layer MapUtils.initDefaultTextLayersV3 makes
-- except "text-note", the player's own hand (notes and symbols are not in these layers).
local LABEL_LAYERS = { "text-street", "text-building", "text-place", "text-town", "text-forest",
                       "text-water-small", "text-water-medium", "text-water-nofade" }
ZeD.MapsTab.LABEL_LAYERS = LABEL_LAYERS

-- Paper prints its own names on the illustration, so the map's labels (worldmap-annotations)
-- would only double them: every fill stop of those layers goes fully transparent. The
-- player's notes (text-note) and symbols are untouched and still draw.
local function hideLabels(mp)
    pcall(function()
        local styleAPI = mp.mapAPI:getStyleAPI()
        for _, name in ipairs(LABEL_LAYERS) do
            local layer = styleAPI:getLayerByName(name)
            if layer then
                for i = 0, layer:getFillStops() - 1 do
                    layer:setFillRGBA(i, layer:getFillRed(i), layer:getFillGreen(i), layer:getFillBlue(i), 0)
                end
            end
        end
    end)
end

-- vanilla's in-game map: its data, streets, style (ISWorldMap:initDataAndStyle)
local function initSurvey(mp)
    if not (MapUtils and MapUtils.initDefaultMapData) then return end
    MapUtils.initDefaultMapData(mp)
    mp.mapAPI:setBoundsFromWorld()
    if MapUtils.initDefaultStreetData then
        MapUtils.initDefaultStreetData(mp)
    end
    MapUtils.initDefaultStyleV3(mp)
    scaleLabels(mp)
    if MapUtils.overlayPaper then
        MapUtils.overlayPaper(mp)
    end
    -- (the marks and notes, and the map's own labels, are vanilla's store, drawn
    -- by the engine through the item bound in instantiate: MapNotes.lua)
end

-- the world's map data, undrawn (no style layers): without it the engine has no
-- world until Survey has loaded once, and zoom throws. Loading it also adds each
-- map folder's colour picture (MapUtils.initDirectoryMapData's addImages).
local function initDataOnly(mp)
    if MapUtils and MapUtils.initDefaultMapData then pcall(MapUtils.initDefaultMapData, mp) end
end

-- the colour picture alone over the (undrawn) data
local function initColor(mp)
    local api = mp.mapAPI
    initDataOnly(mp)
    api:setBoolean("ImagePyramid", true)
    api:setBoundsFromWorld()
    initTextLayers(mp)
end

-- the illustration alone (MapSpawnSelectImage's setup), on vanilla's paper colours
local function initPaper(mp)
    local api = mp.mapAPI
    initDataOnly(mp)
    api:clearImages()                 -- (not the colour picture the data brought)
    api:addImagePyramid(paperFile())
    api:setBoolean("ImagePyramid", true)
    api:setBoundsFromWorld()
    local r, g, b = 219 / 255, 215 / 255, 192 / 255
    api:setBackgroundRGBA(r, g, b, 1.0)
    api:setUnvisitedRGBA(r * 0.915, g * 0.915, b * 0.915, 1.0)
    api:setUnvisitedGridRGBA(r * 0.777, g * 0.777, b * 0.777, 1.0)
    initTextLayers(mp)
    hideLabels(mp)
end

-- SURVEY, COLOR or PAPER on the one map (it keeps where it looks)
function ZeD_WorldMap:applyStyle(style)
    local api = self.mapAPI
    if style == true then style = "paper" elseif style == false or style == nil then style = "survey" end
    if style == "paper" and not paperFile() then style = "survey" end
    local paper = style == "paper"
    local cx, cy, z = nil, nil, nil
    if self._styled then cx, cy, z = api:getCenterWorldX(), api:getCenterWorldY(), api:getZoomF() end
    api:getStyleAPI():clear()
    api:clearImages()
    api:clearData()
    api:setBoolean("ImagePyramid", false)
    if paper then initPaper(self) elseif style == "color" then initColor(self) else initSurvey(self) end
    api:setBoolean("HideUnvisited", true)
    -- street and place names: Survey's; not over a picture (the paper prints its own)
    pcall(function()
        api:setBoolean("ShowStreetNames", style == "survey")
        api:setBoolean("PlaceNames", style == "survey")
    end)
    self.style = style
    self.paper = paper
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

-- the character's map style ("survey" / "color" / "paper"; the older true/false
-- ZeD_MapPaper carries over)
local function savedStyle(md)
    if not md then return "survey" end
    if md.ZeD_MapStyle then return md.ZeD_MapStyle end
    return (md.ZeD_MapPaper == true) and "paper" or "survey"
end

function ZeD_WorldMap:createChildren()
    local md = self.playerObj and self.playerObj:getModData() or nil
    self:applyStyle(savedStyle(md))

    -- Center on player position
    if self.playerObj then
        self.mapAPI:centerOn(self.playerObj:getX(), self.playerObj:getY())
        self:_zoomTo(self.paper and 15.0 or 18.0)
    end

    self._annotationsLoaded = false
end

-- A restyle empties the map's data and pictures and loads them again, and the
-- engine's render thread may at that moment still be drawing this map's last
-- frame from those same lists (WorldMapPyramidStyleLayer.renderVisibleCells
-- reads the picture list unguarded; emptied under it, it throws an
-- IndexOutOfBoundsException, regression Oct 20 2026). So a map that is on
-- screen is restyled only once it has been left out of RESTYLE_HOLD frames:
-- ZeD.MapsTab.render keeps it hidden till then (_restyleStep) and restyles it
-- there. A map not drawn lately is restyled at once. self.style is the style
-- chosen from the moment it is asked for (the toolbar shows it).
local RESTYLE_HOLD = 3
function ZeD_WorldMap:requestStyle(style)
    local drawn = self._drawnMs
    if not drawn or getTimestampMs() - drawn > 500 then
        self._styleWanted, self._styleHold = nil, nil
        self:applyStyle(style)
        return
    end
    self._styleWanted, self._styleHold = style, 0
    self.style = style
    self.paper = style == "paper"
end

-- Each frame from ZeD.MapsTab.render: true while a restyle holds the map off
-- the screen; on the frame after the hold it restyles and returns false.
function ZeD_WorldMap:_restyleStep()
    if not self._styleWanted then return false end
    self._styleHold = (self._styleHold or 0) + 1
    if self._styleHold <= RESTYLE_HOLD then return true end
    local style = self._styleWanted
    self._styleWanted, self._styleHold = nil, nil
    self:applyStyle(style)
    return false
end

-- the toolbar's SURVEY / COLOR / PAPER (kept per character, as the pinned icons are)
function ZeD.MapsTab.setStyle(win, style)
    local mp = win and win._worldMapPanel
    if not mp then return end
    if style == "paper" and not paperFile() then return end
    if mp.style == style then return end
    local md = win._playerObj and win._playerObj:getModData()
    if md then md.ZeD_MapStyle = style; md.ZeD_MapPaper = nil end
    mp:requestStyle(style)
    getSoundManager():playUISound("UIActivateTab")
end
function ZeD.MapsTab.setPaper(win, paper) ZeD.MapsTab.setStyle(win, paper and "paper" or "survey") end

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

    -- vanilla's ink rules, looked at again at the moment of marking
    local ink = _mapInk(mp.playerObj, true)
    local ok, why = _toolAllowed(toolId, ink)
    if ok and toolId == "text" and win._mapEdit then ok, why = _editAllowed(ink) end
    if not ok then
        _inkSay(mp.playerObj, why)
        win._mapActiveTool = nil
        win._mapEdit = nil
        return true
    end
    local colorIdx = _inkColor(win, ink) or 1
    local N = ZeD.MapNotes

    -- into vanilla's store, through vanilla's calls (MapNotes.lua)
    local done = false
    if toolId == "text" then
        local noteText = ZeD.tr("UI_ZeD_Map_NoteDefault")
        if win._mapTextEntry then
            local t = win._mapTextEntry:getText()
            if t and t ~= "" then noteText = t end
        end

        -- Editing a note (right-click > Edit note): new words on the same
        -- note, then out of text mode.
        local ed = win._mapEdit
        if ed then
            win._mapEdit = nil
            win._mapActiveTool = nil
            if N.contains(ed.api, ed.sym) then done = N.setText(ed.sym, noteText, ed.api) end
        else
            done = N.addNote(noteText, worldX, worldY, colorIdx) ~= nil
        end
    else
        -- A mark: the tool stays up, so a string of the same mark can be
        -- dropped without picking it again.
        done = N.addSymbol(N.SYMBOL_BY_ICON[toolId], worldX, worldY, colorIdx) ~= nil
    end
    if done then mp.playerObj:playSoundLocal(toolId == "text" and "MapAddNote" or "MapAddSymbol") end
    return true
end

-- Sharing (multiplayer): vanilla's own panel, opened as its sharing tool does
-- (ISWorldMapSymbolTool_Sharing:showPropertiesUI): one ISWorldMapSharing made
-- on the map, the mark set on it, closed by the panel itself (B, or a click
-- outside), which applies the choice. Vanilla shows the tool on the world map in
-- multiplayer only; ZeD's menu offers it for the marks this player owns.
local function _canShare(sym)
    return isClient() and ISWorldMapSharing ~= nil and sym ~= nil and sym:canClientModify() == true
end

local function _openSharing(mp, sym, fromPad)
    if not _canShare(sym) then return end
    local pn = (mp.playerObj and mp.playerObj:getPlayerNum()) or 0
    mp.playerNum = pn                           -- (the panel reads mapUI.playerNum)
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1] or nil
    local ui = mp._zedSharingUI
    if not ui then
        ui = ISWorldMapSharing:new(mp)
        mp:addChild(ui)
        mp._zedSharingUI = ui
        -- vanilla's close hands the pad to the map; ZeD gives it back to the window
        ui.close = function(self2)
            ISWorldMapSharing.close(self2)
            if ZeD.Input and ZeD.Input.Focus and ZeD.Input.Focus.reclaimEngineFocus then
                ZeD.Input.Focus.reclaimEngineFocus()
            end
        end
    end
    if not ui:isVisible() then
        ui:setVisible(true)
        mp:addChild(ui)
    end
    ui:setCurrentSymbol(sym)
    ui:setX(math.max(0, math.floor((mp:getWidth() - ui:getWidth()) / 2)))
    ui:setY(math.max(0, math.floor((mp:getHeight() - ui:getHeight()) / 2)))
    if fromPad and jd then
        -- a frame later: the menu that was just chosen from lets go of the pad as it closes
        local fire
        fire = function()
            Events.OnTick.Remove(fire)
            if ui:isVisible() then pcall(setJoypadFocus, pn, ui) end
        end
        Events.OnTick.Add(fire)
    end
end

-- Shared mark-edit context menu. Opens at absolute screen coords (absX, absY)
-- for the mark `sym` (from MapNotes.hitAt on this map, with its `api`). Used by
-- mouse RMB and by the gamepad X-press when the cursor is over a mark.
local function _openAnnotContextMenu(mp, absX, absY, sym, api, fromPad)
    local N = ZeD.MapNotes
    if not (sym and api and N.canModify(sym)) then return end

    local ctx = ISContextMenu.get(0, absX, absY)

    -- vanilla's tools: deleting needs an eraser; recolouring or rewording
    -- needs an eraser and a pen (and reading); greyed with the reason when not
    local ink = _mapInk(mp.playerObj, true)
    local canEdit, editWhy = _editAllowed(ink)

    local optDel = ctx:addOption(getText("ContextMenu_Delete"), mp, function(self2)
        if not _mapInk(self2.playerObj, true).erase then _inkSay(self2.playerObj, "Tooltip_Map_CantErase"); return end
        if N.contains(api, sym) and N.remove(sym, api) then
            self2.playerObj:playSoundLocal("MapRemoveMarking")
        end
    end)
    if not ink.erase then _optionNeeds(optDel, "Tooltip_Map_CantErase") end

    local optCol = ctx:addOption(ZeD.tr("UI_ZeD_Map_ChangeColor"), mp, function(self2)
        local ink2 = _mapInk(self2.playerObj, true)
        local ok2, why2 = _editAllowed(ink2)
        if not ok2 then _inkSay(self2.playerObj, why2); return end
        if N.contains(api, sym) then   -- round to the next colour there is a pen for
            N.setInk(sym, _nextInkColor(N.inkOf(sym) or 1, ink2), api)
            self2.playerObj:playSoundLocal("MapAddSymbol")
        end
    end)
    if not canEdit then _optionNeeds(optCol, editWhy) end

    -- multiplayer: vanilla's sharing panel for this mark (vanilla's own word for it)
    if _canShare(sym) then
        ctx:addOption(getText("IGUI_Map_Sharing"), mp, function(self2)
            if N.contains(api, sym) then _openSharing(self2, sym, fromPad) end
        end)
    end

    -- (only a note has words: vanilla's marks carry none)
    if not sym:isText() then return end
    local optEdit = ctx:addOption(getText("IGUI_Map_EditNote"), mp, function(self2)
        local pwin = self2._parentWin
        if not pwin then return end
        local ok2, why2 = _editAllowed(_mapInk(self2.playerObj, true))
        if not ok2 then _inkSay(self2.playerObj, why2); return end
        if N.contains(api, sym) then
            pwin._mapActiveTool = "text"
            pwin._mapEdit = { sym = sym, api = api }
            if pwin._mapTextEntry then
                pwin._mapTextEntry:setText(N.textOf(sym) or "")
                pwin._mapTextEntry:setVisible(true)
            end
        end
    end)
    if not canEdit then _optionNeeds(optEdit, editWhy) end
end

-- Mouse drag for panning (or annotation placement when tool is active)
function ZeD_WorldMap:onMouseDown(x, y)
    -- the Survey / Color / Paper list, open over the map, takes the press
    -- (in the tab's coordinates; a press that came by way of MapsTab.onClick shut it there)
    if self._parentWin and _styleMenuClick(self._parentWin, x + self:getX(), y + self:getY()) then
        return true
    end
    -- an extension's tool takes the press (drawing: MapsTabExt.lua)
    if self._parentWin and Ext.mouseDown(self, self._parentWin, x, y) then
        self.dragging, self.dragMoved = true, true
        return true
    end
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
    if self._parentWin and Ext.mouseMove(self, self._parentWin) then return true end
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
    if self._parentWin and Ext.mouseUp(self, self._parentWin, x, y) then
        self.dragging = false
        return true
    end
    -- a click (no drag) on a pinned flyer opens it (FlyerMap)
    local click = self.dragging and not self.dragMoved
    self.dragging = false
    if click then
        local pin = ZeD.FlyerMap.hit(self, x, y)
        if pin then ZeD.FlyerMap.open(self, pin) end
    end
    return true
end

-- A drag keeps panning past the map's edge and ends wherever the button is
-- let go, as on vanilla's map (ISWorldMap:onMouseMoveOutside / onMouseUpOutside).
-- Without these a release over the container strip or off the window left the
-- map panning with the pointer until the next click on it.
function ZeD_WorldMap:onMouseMoveOutside(dx, dy)
    if self.dragging and not isMouseButtonDown(0) then   -- (a release the map never heard)
        self.dragging = false
        self.dragMoved = false
        return true
    end
    return self:onMouseMove(dx, dy)
end

function ZeD_WorldMap:onMouseUpOutside(x, y)
    if self._parentWin then Ext.mouseUp(self, self._parentWin, x, y) end
    self.dragging = false
    self.dragMoved = false
    return true
end

-- Right-click: context menu for a mark's edit / delete
function ZeD_WorldMap:onRightMouseDown(x, y)
    local sym, api = ZeD.MapNotes.hitAt(self, x, y, ZeD.T.px(16))
    if not sym then return false end
    _openAnnotContextMenu(self, self:getAbsoluteX() + x, self:getAbsoluteY() + y, sym, api)
    return true
end

-- Mouse wheel for zoom
function ZeD_WorldMap:onMouseWheel(del)
    local win = self._parentWin
    if win and Ext.wheel(win, self:getMouseX() + self:getX(), self:getMouseY() + self:getY(), del) then return true end
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
-- the read pieces' places as pinned flyers (FlyerMap.lua: only what this
-- character has read, as vanilla's ISWorldMap:renderPrintMedia)
function ZeD_WorldMap:renderFlyerMarkers()
    ZeD.FlyerMap.draw(self)
end

-- The marks and notes are vanilla's store, drawn by the engine (the map is
-- bound to the world map's item in instantiate). What is left to do here is
-- vanilla's per-frame call that loads the map's own labels into the store
-- once (ISWorldMap:prerender); ZeD draws no marks of its own.
function ZeD_WorldMap:renderAnnotations()
    ZeD.MapNotes.initDefaults()
end

-- A mark or note as it will land: vanilla's own preview draws
-- (ISWorldMapSymbols:renderSymbol, ISWorldMapSymbolTool_AddNote:render), so the
-- preview is the size and hand of the mark the engine will draw there.
local function _previewMark(mp, toolId, x, y, c, alpha, text)
    local s = ((ISMap and ISMap.SCALE) or 0.666) * mp.mapAPI:getWorldScale()
    if toolId == "text" then
        if text and text ~= "" then
            pcall(function()
                mp.javaObject:DrawTextSdfRotated("text-note", text, x, y, 0.5, 0.5, 0.0, s, false, true, c.r, c.g, c.b, alpha)
            end)
        end
        return
    end
    local tex = mp._annotTextures and mp._annotTextures[toolId]
    if tex then mp.javaObject:DrawSymbol(tex, x, y, 20, 20, 0.0, s, false, false, c.r, c.g, c.b, alpha) end
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

-- The id of the element the controller's mark shows on now, for paint only: the
-- window that holds the map has the focus and the controller is in use
-- (Focus.liveElement); nil otherwise, so no mark lingers in mouse use or in an
-- unfocused window. (The map's own cursor keeps reading _focusedEl.)
local function _liveFocusId(win)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local owner = _focusOwner(win)
    if not (Focus and Focus.liveElement and owner) then return nil end
    local el = Focus.liveElement(owner)
    return el and el.id or nil
end

-- the controller's mark opts: the window the control is drawn in (ZeD.Focus.mark)
local FOCUS = {}

-- Survey / Color / Paper's open list: the library's pop-up list (the sort menu's,
-- Molecules.drawSortMenuList: solid, framed, the hard shadow, the current choice
-- selected), hung from the box the toolbar drew (win._mapStyleMenuGeo, tab
-- coordinates). Drawn on `target`, whose top-left is at (ox, oy) in the tab: the
-- map, after everything on it, so the list lies over the map and its pieces.
-- Its rows are kept, in the tab's coordinates, for the press and the controller.
local _styleModes = { { id = "survey" }, { id = "color" }, { id = "paper" } }
local _menuOpts = {}
local function _drawStyleMenu(target, win, ox, oy)
    local geo = win._mapStyleMenuGeo
    if not (win._mapStyleMenuOpen and geo) then return end
    for _, m in ipairs(_styleModes) do m.label = ZeD.tr(STYLE_WORD[m.id]) end
    local hoverId = nil
    local F = ZeD.Input and ZeD.Input.Focus
    if not (F and F.cuesVisible and F.cuesVisible()) then
        local mx, my = target:getMouseX() + ox, target:getMouseY() + oy
        for _, z in ipairs(win._mapStyleMenuZones or {}) do
            if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then hoverId = z.id; break end
        end
    end
    local o = _menuOpts
    local fid = _liveFocusId(win)
    o.focusId = (fid and string.sub(fid, 1, 13) == "map:styleRow:") and string.sub(fid, 14) or nil
    o.focus = o.focusId and FOCUS or nil
    o.minW = geo.w
    local mp = win._worldMapPanel
    local _, _, zs = ZeD.Molecules.drawSortMenuList(target, geo.x - ox, geo.y - oy, _styleModes,
        mp and mp.style or "survey", hoverId, o)
    for _, z in ipairs(zs or {}) do z.x, z.y = z.x + ox, z.y + oy end
    win._mapStyleMenuZones = zs
    if hoverId then ZeD.Help.set(target, ZeD.tr(STYLE_HELP[hoverId])) end
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
    if win._mapEdit then return end   -- (rewording a note: the next click puts the words on it)

    local c = MAP_COLORS[win._mapActiveColor or 1] or MAP_COLORS[1]
    local previewText = (win._mapTextEntry and win._mapTextEntry:getText()) or ZeD.tr("UI_ZeD_Map_NoteDefault")
    _previewMark(self, win._mapActiveTool, mx, my, c, 0.5, previewText)
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
    self._gpCursorLive = true     -- (FlyerMap's card follows the cursor)
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
    if win._mapActiveTool and not win._mapEdit then
        local c = MAP_COLORS[win._mapActiveColor or 1] or MAP_COLORS[1]
        local previewText = (win._mapTextEntry and win._mapTextEntry:getText()) or ZeD.tr("UI_ZeD_Map_NoteDefault")
        _previewMark(self, win._mapActiveTool, cx, cy, c, 0.5, previewText)
    end
end

-- ISUIElement render — draw overlays on top of the Java map.
-- Do NOT call ISUIElement.render(self) — Java UIWorldMap handles its own rendering.
function ZeD_WorldMap:render()
    self._drawnMs = getTimestampMs()   -- (requestStyle: drawn lately, so restyle after a hold)
    if self._pendingZoom then self:_zoomTo(self._pendingZoom) end
    self._gpCursorLive = false
    -- what sits ON the map (stash icons, flyer pins and their pulse, previews, the
    -- extensions' marks) is clipped to the map: a pin by the edge never hangs over
    -- the toolbar or the tab strip (Oct 27 2026). One clip, set and cleared here:
    -- nothing inside sets its own (stencils do not nest).
    self:setStencilRect(0, 0, self:getWidth(), self:getHeight())
    self:renderStashMaps()
    self:renderFlyerMarkers()
    self:renderAnnotations()
    self:renderToolCursor()
    self:renderGamepadCursor()
    local win = self._parentWin
    if win then Ext.drawMapUnder(self, win) end   -- the extensions' drawing (MapsTabExt.lua)
    self:clearStencilRect()
    ZeD.FlyerMap.drawCard(self)          -- the hovered pin's card, on top
    if win then
        Ext.drawMapOver(self, win, _liveFocusId(win))   -- the key, the side list, the area name
        _drawStyleMenu(self, win, self:getX(), self:getY())   -- Survey / Color / Paper's open list, over all
    end
end

-- ============================================================================
-- TOOLBAR
-- ============================================================================
-- Built from the library: icon buttons for the marks, the note and the unfold
-- (the hover wash, a hint with the name, help words, the solid active look for
-- the tool in hand), the inks as swatches with the same hover and controller
-- mark, and Survey / Color / Paper as System 7 radio buttons, or a pop-up menu
-- where they do not fit (the World window's drawer). A mark or ink the character
-- lacks the pen for takes the library's disabled look: the help line gives
-- vanilla's reason, and a press still says it over the character's head.

local UNFOLD_ICON, FOLD_ICON = "expand", "contract"   -- ZeD pixel icons
local RADIO_GAP, CHOICE_GAP = 4, 10   -- design units: a radio to its words, between choices (the sort strip's)
local _btnOpts, _radioOpts = {}, {}
local _textGlyphs, _markTex = {}, {}
local COLOR_FIDS = {}
for i = 1, #MAP_COLORS do COLOR_FIDS[i] = "map:color:" .. i end

-- a picture made of a few letters (the note's "Aa"; a mark whose texture is missing)
local function _textGlyph(s)
    local g = _textGlyphs[s]
    if g then return g end
    g = function(p, x, y, sz, c)
        local f, tm = ZeD.T.fontF1, ZeD.TM
        p:drawText(s, x + math.floor((sz - tm:MeasureStringX(f, s)) / 2), y + math.floor((sz - tm:getFontHeight(f)) / 2),
            c.r, c.g, c.b, c.a or 1, f)
    end
    _textGlyphs[s] = g
    return g
end

-- a mark's picture on its button (the game's own map symbol)
local function _markPic(icon)
    local t = _markTex[icon.id]
    if t == nil then t = getTexture(icon.tex) or false; _markTex[icon.id] = t end
    return t or _textGlyph(string.sub(icon.label, 1, 1))
end

-- One tool button (a mark, or the note) at (bx, by), bs square; its zone goes
-- in win._mapToolZones. focusId: its controller id; why: vanilla's reason it
-- cannot be used (nil: it can); grid: a copy in the full set (a right-click or X
-- pins it), pinned: a small square in its corner says it is on the row; hov:
-- the pointer may light it.
local function _toolButton(panel, win, toolId, pic, nameKey, bx, by, bs, focusId, focId, why, grid, pinned, hov)
    local T = ZeD.T
    local o = _btnOpts
    local active = win._mapActiveTool == toolId
    o.hover = hov and ZeD.Atoms.mouseIn(panel, bx, by, bs, bs) or false
    o.active, o.disabled, o.pressed = active, why ~= nil, false
    o.focus = (focId == focusId) and FOCUS or nil
    o.id, o.iconSize, o.tint, o.win = focusId, nil, nil, nil
    o.hint, o.help = nil, nil
    if o.hover then
        local name = ZeD.tr(nameKey)
        o.hint = name
        if why then o.help = ZeD.tr("UI_ZeD_Map_HelpCant", name, getText(why))
        elseif toolId == "text" then o.help = ZeD.tr("UI_ZeD_Map_HelpNote")
        else o.help = ZeD.tr(grid and "UI_ZeD_Map_HelpMarkGrid" or "UI_ZeD_Map_HelpMark", name) end
    end
    ZeD.Molecules.drawIconButton(panel, bx, by, bs, pic, o)
    if pinned then
        local c = active and T.textOnAccent or T.accent
        panel:drawRect(bx + T.px(3), by + T.px(3), T.px(4), T.px(4), (c.a or 1) * (why and T.disabledAlpha or 1), c.r, c.g, c.b)
    end
    local zs = win._mapToolZones
    zs[#zs + 1] = { id = toolId, x = bx, y = by, w = bs, h = bs, isGrid = grid or nil }
end

-- One ink's swatch at (sx, sy), sz square: the hover wash and the controller's
-- mark in a 2u ring round it, the ink (greyed without its pen), a 1u edge, and a
-- 1u ring in the text colour round the ink in use. Its zone goes in win._mapColorZones.
local function _swatch(panel, win, ci, sx, sy, sz, ink, focId, hov)
    local T, A = ZeD.T, ZeD.Atoms
    local c, pen = MAP_COLORS[ci], MAP_COLOR_PENS[ci]
    local has = ink.pen[ci] and true or false
    local ring = T.px(2)
    local rx, ry, rs = sx - ring, sy - ring, sz + 2 * ring
    if hov and A.mouseIn(panel, rx, ry, rs, rs) then
        local hv = T.hover
        panel:drawRect(rx, ry, rs, rs, hv.a or 1, hv.r, hv.g, hv.b)
        local name = pen and (getItemNameFromFullType("Base." .. pen.item) or pen.item) or ""
        ZeD.Help.set(panel, has and ZeD.tr("UI_ZeD_Map_HelpInk", name)
            or ZeD.tr("UI_ZeD_Map_HelpCant", name, getText(pen and pen.need or "Tooltip_Map_CantWrite")))
        A.requestHint(A.windowOf(panel), COLOR_FIDS[ci], name, panel)
    end
    if focId == COLOR_FIDS[ci] then ZeD.Focus.mark(panel, rx, ry, rs, rs, FOCUS) end
    local a = has and 1 or T.disabledAlpha
    panel:drawRect(sx, sy, sz, sz, a, c.r, c.g, c.b)
    -- (vanilla's inks are dark: the edge keeps each swatch apart from the toolbar)
    A.frame(panel, sx, sy, sz, sz, T.borderS, a)
    if has and ci == (win._mapActiveColor or 1) then
        local u = T.hair
        A.frame(panel, sx - u, sy - u, sz + 2 * u, sz + 2 * u, T.text)
    end
    local zs = win._mapColorZones
    zs[#zs + 1] = { idx = ci, x = sx, y = sy, w = sz, h = sz }
end

-- The disclosure triangle at x (it opens the full set of marks); returns its width.
local function _disclosure(panel, win, x, y, rowH, focId, hov)
    local T, A = ZeD.T, ZeD.Atoms
    local expanded = win._mapToolsExpanded or false
    local chevSz = math.max(T.px(8), math.floor(ZeD.TM:getFontHeight(T.fontF1) * 0.7))
    local zx, zw = x - T.px(2), chevSz + T.px(6)
    if hov and A.mouseIn(panel, zx, y, zw, rowH) then
        local hv = T.hover
        panel:drawRect(zx, y, zw, rowH, hv.a or 1, hv.r, hv.g, hv.b)
        ZeD.Help.set(panel, ZeD.tr(expanded and "UI_ZeD_Map_HelpMarksClose" or "UI_ZeD_Map_HelpMarksOpen"))
    end
    local onFocus = (focId == "map:disclosure") and ZeD.Focus.mark(panel, zx, y, zw, rowH, FOCUS)
    local c = onFocus and T.textOnFocus or T.arrow
    local cy = y + math.floor((rowH - chevSz) / 2)
    if expanded then A.drawTriangleDown(panel, x, cy, chevSz, c) else A.drawTriangleRight(panel, x, cy, chevSz, c) end
    win._mapDisclosureZone = { x = x, y = y, w = chevSz + T.px(4), h = rowH }
    return chevSz
end

-- The unfold button at (bx, by): it opens the map in a window of its own, or folds it back.
local function _unfoldButton(panel, win, bx, by, bs, focId, hov)
    local open = win._mapPopout ~= nil
    local o = _btnOpts
    o.hover = hov and ZeD.Atoms.mouseIn(panel, bx, by, bs, bs) or false
    o.active, o.disabled, o.pressed = false, false, false
    o.focus = (focId == "map:popout") and FOCUS or nil
    o.id, o.iconSize, o.tint, o.win = "map:popout", nil, nil, nil
    o.hint = o.hover and ZeD.tr(open and "UI_ZeD_Map_PadFold" or "UI_ZeD_Map_Unfold") or nil
    o.help = o.hover and ZeD.tr(open and "UI_ZeD_Map_HelpFold" or "UI_ZeD_Map_HelpUnfold") or nil
    ZeD.Molecules.drawIconButton(panel, bx, by, bs, open and FOLD_ICON or UNFOLD_ICON, o)
    win._mapPopoutZone = { x = bx, y = by, w = bs, h = bs }
end

-- The pop-up menu's box at (bx, by): the hover wash (lit while its list is open),
-- the controller's mark, the choice's words, a down triangle, a 1u frame. Its list
-- is drawn over the map (_drawStyleMenu) from win._mapStyleMenuGeo.
local function _styleBox(panel, win, bx, by, bw, bh, label, focId, hov)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local over = hov and A.mouseIn(panel, bx, by, bw, bh)
    if over or win._mapStyleMenuOpen then
        local hv = T.hover
        panel:drawRect(bx, by, bw, bh, hv.a or 1, hv.r, hv.g, hv.b)
    end
    if over then ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Map_HelpStyleMenu")) end
    local onFocus = (focId == "map:style:menu") and ZeD.Focus.mark(panel, bx, by, bw, bh, FOCUS)
    local f1 = T.fontF1
    local pad, tri = T.px(6), T.px(5)
    local tc = onFocus and T.textOnFocus or T.text
    panel:drawText(label, bx + pad, by + math.floor((bh - tm:getFontHeight(f1)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f1)
    A.drawTriangleDown(panel, bx + bw - pad - tri, by + math.floor((bh - tri) / 2), tri, onFocus and T.textOnFocus or T.textDim)
    A.frame(panel, bx, by, bw, bh, T.borderS)
    win._mapStyleMenuZone = { x = bx, y = by, w = bw, h = bh }
    win._mapStyleMenuGeo = { x = bx, y = by + bh, w = bw }
end

-- Survey / Color / Paper, right-aligned so it ends at rightX and starts no
-- earlier than minX: the radio buttons when they fit, else the pop-up menu's
-- box, else nothing. Only when the base map carries its illustration.
local function _styleChoice(panel, win, minX, rightX, by, bs, focId, hov)
    win._mapStyleZones = {}
    win._mapStyleMenuZone, win._mapStyleMenuGeo = nil, nil
    if not ZeD.MapsTab.hasPaper() then win._mapStyleMenuOpen = nil; return end
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local f1 = T.fontF1
    local mp = win._worldMapPanel
    local cur = mp and mp.style or "survey"
    local rs = A.radioSize()
    local total, widest = 0, 0
    for i, id in ipairs(STYLE_ORDER) do
        local tw = tm:MeasureStringX(f1, ZeD.tr(STYLE_WORD[id]))
        widest = math.max(widest, tw)
        total = total + rs + T.px(RADIO_GAP) + tw + ((i > 1) and T.px(CHOICE_GAP) or 0)
    end
    if rightX - total >= minX then
        win._mapStyleMenuOpen = nil
        local cx = rightX - total
        local ty = by + math.floor((bs - tm:getFontHeight(f1)) / 2)
        for _, id in ipairs(STYLE_ORDER) do
            local word = ZeD.tr(STYLE_WORD[id])
            local cw = rs + T.px(RADIO_GAP) + tm:MeasureStringX(f1, word)
            local hover = hov and A.mouseIn(panel, cx, by, cw, bs)
            local onFocus = (focId == "map:style:" .. id) and ZeD.Focus.mark(panel, cx - T.px(2), by, cw + T.px(4), bs, FOCUS)
            _radioOpts.hover = hover
            A.drawRadio(panel, cx, by + math.floor((bs - rs) / 2), id == cur, _radioOpts)
            local tc = onFocus and T.textOnFocus or T.text
            panel:drawText(word, cx + rs + T.px(RADIO_GAP), ty, tc.r, tc.g, tc.b, tc.a or 1, f1)
            if hover then ZeD.Help.set(panel, ZeD.tr(STYLE_HELP[id])) end
            local zs = win._mapStyleZones
            zs[#zs + 1] = { id = id, x = cx, y = by, w = cw, h = bs }
            cx = cx + cw + T.px(CHOICE_GAP)
        end
        return
    end
    local bw = widest + T.px(6) * 2 + T.px(5) + T.px(4)
    if rightX - bw < minX then win._mapStyleMenuOpen = nil; return end
    _styleBox(panel, win, rightX - bw, by, bw, bs, ZeD.tr(STYLE_WORD[cur] or STYLE_WORD.survey), focId, hov)
end

-- The full set of marks under row one (the disclosure open), on surface 1 with
-- a content line on top; returns its height.
local function _markGrid(panel, win, x, gy, w, pins, why, focId, hov)
    local T = ZeD.T
    local bs, gap = T.buttonH, T.px(MAP_ICON_BTN_GAP)
    local maxCols = math.max(1, math.floor((w - T.px(8)) / (bs + gap)))
    local h = math.ceil(#MAP_ICONS / maxCols) * (bs + gap) + gap
    ZeD.Atoms.surfaceFill(panel, x, gy, w, h, "surf1")
    ZeD.Atoms.drawDividerH(panel, x, gy, w, false)
    local col, row = 0, 0
    for _, icon in ipairs(MAP_ICONS) do
        local bx = x + T.px(4) + col * (bs + gap)
        local by = gy + gap + row * (bs + gap)
        _toolButton(panel, win, icon.id, _markPic(icon), icon.key, bx, by, bs, icon.gridFid, focId, why, true,
            _isIconPinned(pins, icon.id), hov)
        local rz = win._mapToolRMBZones
        rz[#rz + 1] = { id = icon.id, x = bx, y = by, w = bs, h = bs }
        col = col + 1
        if col >= maxCols then col, row = 0, row + 1 end
    end
    return h
end

local function renderMapToolbar(panel, win, x, y, w)
    local T  = ZeD.T
    local bs     = T.buttonH
    local btnGap = T.px(MAP_ICON_BTN_GAP)
    local colSz  = T.px(MAP_COLOR_SZ)
    local rowH   = T.px(MAP_TOOLBAR_ROW_H)

    win._mapToolZones  = {}
    win._mapColorZones = {}
    win._mapToolRMBZones = {}
    win._mapExtZones = {}   -- the extensions' controls this frame (MapsTabExt.lua)

    local ink   = _enforceInk(win)   -- (first: it may put a tool down or move the colour)
    local pins  = _getMapPins(win._playerObj)
    -- the element the controller's mark is on (only in the window that has the
    -- focus, with the controller in use: feedback_only_focused_zone_shows_active)
    local focId = _liveFocusId(win)
    local hov   = not win._mapStyleMenuOpen   -- (the open style list takes the pointer)
    local markWhy = (not ink.write) and "Tooltip_Map_CantWrite" or nil
    local by = y + math.floor((rowH - bs) / 2)

    -- Row one: the disclosure, the pinned marks, the note, a line, the inks
    local curX = x + T.px(4)
    curX = curX + _disclosure(panel, win, curX, y, rowH, focId, hov) + T.px(6)
    for _, pid in ipairs(pins) do
        local icon = MAP_ICON_BY_ID[pid]
        if icon then
            _toolButton(panel, win, icon.id, _markPic(icon), icon.key, curX, by, bs, icon.toolFid, focId, markWhy, false, false, hov)
            curX = curX + bs + btnGap
        end
    end
    curX = curX + btnGap
    local _, textWhy = _toolAllowed("text", ink)
    _toolButton(panel, win, "text", _textGlyph("Aa"), "UI_ZeD_Map_NoteDefault", curX, by, bs, "map:tool:text", focId, textWhy, false, false, hov)
    curX = curX + bs + btnGap * 2
    -- a content line between the tools and the inks
    ZeD.Atoms.drawDividerV(panel, curX, by, bs, false)
    curX = curX + T.hair + btnGap * 2
    local colY = y + math.floor((rowH - colSz) / 2)
    for ci = 1, #MAP_COLORS do
        _swatch(panel, win, ci, curX, colY, colSz, ink, focId, hov)
        curX = curX + colSz + btnGap
    end

    -- the extensions' buttons (the map key; mods' tools), then the list button
    curX = Ext.drawButtons(panel, win, curX + btnGap, by, bs, focId)

    -- right end: the unfold button, and Survey / Color / Paper before it
    local ux = x + w - T.px(4) - bs
    _unfoldButton(panel, win, ux, by, bs, focId, hov)
    _styleChoice(panel, win, curX + btnGap, ux - btnGap * 3, by, bs, focId, hov)

    local totalH = rowH
    if win._mapToolsExpanded then
        totalH = totalH + _markGrid(panel, win, x, y + rowH, w, pins, markWhy, focId, hov)
        -- an extension's row under the mark grid (Map Symbol Size Slider)
        totalH = totalH + Ext.drawRows(panel, win, x, y + totalH, w, "gridRow", focId)
    end

    -- the extensions' rows under the toolbar (Draw On The Map's tools)
    totalH = totalH + Ext.drawRows(panel, win, x, y + totalH, w, "row", focId)

    -- Inline text input (visible while the note is the tool in hand): surface 2,
    -- a content line on top
    if win._mapActiveTool == "text" then
        local ih = T.px(MAP_TEXT_INPUT_H)
        local inputY = y + totalH
        ZeD.Atoms.surfaceFill(panel, x, inputY, w, ih, "surf2")
        ZeD.Atoms.drawDividerH(panel, x, inputY, w, false)
        local te = win._mapTextEntry
        if te then
            te:setX(x + T.px(4))
            te:setY(inputY + T.px(2))
            te:setWidth(w - T.px(8))
            te:setHeight(ih - T.px(4))
            te:setVisible(true)
        end
        totalH = totalH + ih
    elseif win._mapTextEntry then
        win._mapTextEntry:setVisible(false)
    end

    return totalH
end

-- ============================================================================
-- MAIN RENDERER
-- ============================================================================

-- a line of prose (F2) centred in the width at y
local function _centredLine(panel, text, x, y, w, c)
    local f2 = ZeD.T.fontF2
    local tw = ZeD.TM:MeasureStringX(f2, text)
    panel:drawText(text, x + math.floor((w - tw) / 2), y, c.r, c.g, c.b, c.a or 1, f2)
end

-- Vanilla's world-map rules hold on the tab and the pop-out too: no map where
-- the server or sandbox turns the world map off (or in the Tutorial), and none
-- to read in the dark where the map needs light. The light is looked at twice
-- a second; while either rule refuses, the refusal is drawn in place of the
-- toolbar and map, which stay hidden, and true is returned.
local _light = { t = -1 }
local function _mapBlocked(panel, win, x, y, w, h)
    local msg = nil
    if not ZeD.MapsTab.isAllowed() then
        msg = ZeD.tr("UI_ZeD_Map_Unavailable")
    else
        local now = getTimestampMs()
        if _light.who ~= win._playerObj or now - _light.t >= 500 then
            _light.who, _light.t = win._playerObj, now
            _light.dark = ZeD.MapsTab.tooDark(win._playerObj)
        end
        if _light.dark then msg = ZeD.trBare("ContextMenu_TooDark") end   -- (vanilla's words, as vanilla writes them)
    end
    win._mapBlocked = msg ~= nil
    if not msg then return false end

    local T, tm = ZeD.T, ZeD.TM
    ZeD.Atoms.surfaceFill(panel, x, y, w, h, "surf1")
    _centredLine(panel, msg, x, y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), w, T.textDim)
    if win._worldMapPanel then win._worldMapPanel:setVisible(false) end
    if win._mapTextEntry then win._mapTextEntry:setVisible(false) end
    -- no toolbar this frame: nothing for a click or the controller to land on
    win._mapToolZones, win._mapColorZones, win._mapToolRMBZones, win._mapStyleZones = {}, {}, {}, {}
    win._mapExtZones, win._mapSideZone = {}, nil
    win._mapDisclosureZone, win._mapPopoutZone = nil, nil
    win._mapStyleMenuZone, win._mapStyleMenuGeo, win._mapStyleMenuOpen = nil, nil, nil
    win._mapBlockedZone = { x = x, y = y, w = w, h = h }
    return true
end

function ZeD.MapsTab.render(panel, win, x, y, w, h)
    local T = ZeD.T

    -- S123: while the map is unfolded into the pop-out, the drawer shows a
    -- fold-back placeholder instead of a second live map (the Java UIWorldMap
    -- is owned by exactly one panel at a time). The whole of it is one stop for
    -- the controller (it folds the map back), so it carries the mark.
    if win._mapPopout and panel ~= win._mapPopout._contentPanel then
        ZeD.Atoms.surfaceFill(panel, x, y, w, h, "surf1")
        local onFocus = (_liveFocusId(win) == "map:fold") and ZeD.Focus.mark(panel, x, y, w, h, FOCUS)
        local fh = ZeD.TM:getFontHeight(T.fontF2)
        local cy = y + math.floor(h / 2) - fh
        _centredLine(panel, ZeD.tr("UI_ZeD_Map_Unfolded"), x, cy, w, onFocus and T.textOnFocus or T.text)
        _centredLine(panel, ZeD.tr("UI_ZeD_Map_FoldBack"), x, cy + fh + T.px(4), w, onFocus and T.textOnFocus or T.textDim)
        win._mapFoldZone = { x = x, y = y, w = w, h = h }
        if win._mapTextEntry then win._mapTextEntry:setVisible(false) end
        return
    end
    -- Only the drawer path (no pop-out) may clear the fold zone; the pop-out
    -- renders through this same function every frame and must not race it.
    if not win._mapPopout then win._mapFoldZone = nil end

    if _mapBlocked(panel, win, x, y, w, h) then return end

    -- the toolbar's surface: one layer over the window (ZeD.Surface)
    ZeD.Atoms.surfaceFill(panel, x, y, w, T.px(MAP_TOOLBAR_ROW_H), "surf1")

    -- Lazy-create inline text entry for map annotations
    if not win._mapTextEntry then
        local te = ISTextEntryBox:new(ZeD.tr("UI_ZeD_Map_NoteDefault"), 0, 0, T.px(100), T.px(MAP_TEXT_INPUT_H) - T.px(4))
        te:initialise()
        te.zedEntry = true   -- typed text follows the UI scale (ZeD.Text.fitEntry)
        te:setVisible(false)
        panel:addChild(te)
        -- vanilla's note limit (its note box takes 45 characters)
        pcall(function() te:setMaxTextLength(ZeD.MapNotes.NOTE_MAX_CHARS) end)
        win._mapTextEntry = te
    end

    local toolbarH = renderMapToolbar(panel, win, x, y, w)
    -- the structure line under the toolbar, edge to edge (it meets the frame)
    ZeD.Atoms.drawDividerH(panel, x, y + toolbarH - T.line(T.borderW), w, true)

    -- Map area below toolbar
    local mapY = y + toolbarH
    local mapH = h - toolbarH
    -- the side list docks at the right of the unfolded map (MapsTabExt.lua)
    local sideW = Ext.dockedSideW(win, panel)
    if sideW > 0 then
        Ext.drawSide(panel, win, x + w - sideW, mapY, sideW, mapH, 0, 0, _liveFocusId(win))
        w = w - sideW
    end

    -- Lazy-create the world map panel
    if not win._worldMapPanel and not win._worldMapFailed then
        local ok, err = pcall(function()
            local mp = ZeD_WorldMap:new(x, mapY, w, mapH, win._playerObj)
            mp._parentWin = win
            mp._isPopoutMap = Ext.isPopout(win, panel)
            mp:initialise()
            mp:instantiate()
            panel:addChild(mp)
            win._worldMapPanel = mp
            Ext.mapMade(mp, win)
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
        -- a restyle on hold: the map stays off the screen a few frames (requestStyle)
        local holding = mp:_restyleStep()
        mp:setVisible(not holding)
        if holding then
            ZeD.Atoms.surfaceFill(panel, x, mapY, w, mapH, "surf1")
            _drawStyleMenu(panel, win, 0, 0)   -- (the map draws the open list; it is off the screen)
        end
    else
        -- Fallback: show error state
        local fh = ZeD.TM:getFontHeight(T.fontF2)
        _centredLine(panel, ZeD.tr("UI_ZeD_Map_Unavailable"), x, mapY + math.floor(mapH / 2) - fh, w, T.textDim)
        _drawStyleMenu(panel, win, 0, 0)   -- (no map to draw the open list)
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
    if win._mapBlocked then return end   -- no map here, or too dark to read it
    -- Survey / Color / Paper's list open: the press is its (a choice, or it shuts)
    if _styleMenuClick(win, x, y) then return end
    -- the extensions' controls: toolbar buttons and rows, the key, the side list
    if Ext.onClick(win, x, y) then return end
    -- S123: unfold / fold button
    if win._mapPopoutZone then
        local z = win._mapPopoutZone
        if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            if win._mapPopout then ZeD.MapsTab.closePopout(win) else ZeD.MapsTab.openPopout(win) end
            return
        end
    end

    -- SURVEY / COLOR / PAPER: a radio button, or the pop-up menu's box (opens its list)
    for _, z in ipairs(win._mapStyleZones or {}) do
        if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            ZeD.MapsTab.setStyle(win, z.id)
            return
        end
    end
    do
        local z = win._mapStyleMenuZone
        if z and x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            _openStyleMenu(win, false)
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
                _armTool(win, zone.id)   -- (again on the armed tool puts it down)
                return
            end
        end
    end

    -- Color swatches
    if win._mapColorZones then
        for _, zone in ipairs(win._mapColorZones) do
            if x >= zone.x and x <= zone.x + zone.w
               and y >= zone.y and y <= zone.y + zone.h then
                _pickColor(win, zone.idx)
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
    if win._mapBlocked then return end   -- no map here, or too dark to read it
    -- Survey / Color / Paper's list open: a right-click shuts it
    if win._mapStyleMenuOpen then _closeStyleMenu(win, false); return end
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

    -- No map here, or too dark to read it: the drawer offers nothing; the
    -- pop-out keeps one target over the refusal so A (or B) folds it away.
    if win._mapBlocked then
        local bz = win._mapBlockedZone
        if win._mapBuildingForPopout and bz then
            elements[1] = {
                x = bz.x, y = bz.y, w = bz.w, h = bz.h,
                id = "map:blocked",
                onActivate = function(w, _el) ZeD.MapsTab.closePopout(w) end,
            }
        end
        return elements
    end

    -- Survey / Color / Paper's list open: the controller stays in it (A takes a
    -- choice, B shuts it; either way back to the box). Until the list has drawn
    -- once its rows are not there yet, and the toolbar's stops stand in.
    if win._mapStyleMenuOpen and win._mapStyleMenuZones and #win._mapStyleMenuZones > 0 then
        for _, z in ipairs(win._mapStyleMenuZones) do
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "map:styleRow:" .. tostring(z.id),
                styleId = z.id,
                ownCancel = true,   -- (the unfolded window keeps this B: it shuts the list, not the window)
                onActivate = function(w, el2)
                    ZeD.MapsTab.setStyle(w, el2.styleId)
                    _closeStyleMenu(w, true)
                end,
                onCancel = function(w, _el) _closeStyleMenu(w, true); return true end,
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
                    _armTool(w, el2.toolId)
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
                    _pickColor(w, el2.colorIdx)
                end,
            }
        end
    end

    -- 3a. SURVEY / COLOR / PAPER radio buttons (A takes one), or the pop-up
    -- menu's box where they do not fit (A opens its list)
    for _, sz in ipairs(win._mapStyleZones or {}) do
        elements[#elements + 1] = {
            x = sz.x, y = sz.y, w = sz.w, h = sz.h,
            id = "map:style:" .. sz.id,
            styleId = sz.id,
            onActivate = function(w, el2) ZeD.MapsTab.setStyle(w, el2.styleId) end,
        }
    end
    if win._mapStyleMenuZone then
        local mz = win._mapStyleMenuZone
        elements[#elements + 1] = {
            x = mz.x, y = mz.y, w = mz.w, h = mz.h,
            id = "map:style:menu",
            onActivate = function(w, _el) _openStyleMenu(w, true) end,
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

    -- 3c. The extensions' controls (MapsTabExt.lua): their toolbar buttons and
    -- rows, the key's controls, the side list's rows and its question.
    Ext.addFocusables(win, elements)

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
            extraPrompts = { { glyph = "RT LT", label = getText("UI_Zoom") }, { glyph = "L-STICK", label = ZeD.tr("UI_ZeD_Map_PadMove") } },
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
                    w._mapEdit = nil
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
    if Ext.anyArmed(win) then return end   -- (an extension's tool hears A itself: Ext.padTick)
    -- no tool armed and the cursor on a pinned flyer: A reads it (FlyerMap)
    if not win._mapActiveTool then
        local pin = ZeD.FlyerMap.hit(mp, mp._gpCursorX, mp._gpCursorY)
        if pin then ZeD.FlyerMap.open(mp, pin); return end
    end
    _placeAnnotationAt(mp, mp._gpCursorX, mp._gpCursorY)
end

-- The mark under the controller's cursor ({ sym, api }), or nil: the
-- engine's hit test on vanilla's store, then the nearest mark within the hit
-- radius (MapNotes.hitAt).
function ZeD.MapsTab.gpFindAnnotAtCursor(win)
    if not win then return nil end
    local mp = win._worldMapPanel
    if not mp or not mp._gpCursorX then return nil end
    local sym, api = ZeD.MapNotes.hitAt(mp, mp._gpCursorX, mp._gpCursorY, ZeD.T.px(MAP_GP_HIT_RADIUS_PX))
    if not sym then return nil end
    return { sym = sym, api = api }
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
        hit.sym, hit.api, true)
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
    Ext.padTick(win, mp, cid)   -- an extension's tool: A down / held / up at the cursor
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
        if el.ownCancel and el.onCancel then
            -- (B on the style list shuts the list, as in the drawer)
            e.onCancel = function(_, ee) return el.onCancel(win, ee) end
        else
            e.onCancel = function(_, _ee) ZeD.MapsTab.closePopout(win) end
            e.promptB  = ZeD.tr("UI_ZeD_Map_PadFold")
        end
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
    local pop = ZeD_Window:new(math.floor((sw - pw) / 2), math.floor((sh - ph) / 2), pw, ph, getText("IGUI_ItemType_Map"))
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
        if Ext.wheel(win, self:getMouseX(), self:getMouseY(), del) then return true end   -- the docked side list
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
    win._mapStyleMenuOpen = nil   -- (the style list belongs to the toolbar it hung from)
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
    win._mapStyleMenuOpen = nil

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
