-- ZeD-UI/42/media/lua/client/ZeD/MapsSurvey.lua
-- ============================================================================
-- THE SURVEY MAP'S PAPER-MAP LOOK -- client. (The director, Nov 18 2026: the colors a 1993 paper road map or survey
-- map used, "red for major highways, patterns for forests and marshes, lakes versus streams and rivers", carried into
-- ZeD's Dark, Light and High contrast; and the additions picked from the same references: a grid, place symbols, a
-- scale bar and north arrow, town dots, route shields, bridge marks, lakes and the exclusion zone's edge.
-- Mockup: ZeDUI/mockups/zed_survey_map_palettes_v4.html.)
--
-- Two halves:
--   M.restyle(mp)   recolours the game's own Survey layers (MapUtils.initDefaultStyleV3, which MapsTab.lua's
--                   initSurvey builds) for the theme, adds the woodland marks and the lakes as engine layers (so the
--                   map's own labels and the player's notes still draw over them). Called from initSurvey, and again
--                   when the theme or the status colors change (M.watch, from ZeD_WorldMap:render).
--   the extension    draws ZeD's printed additions over the map (MapsTabExt.lua's drawMap): grid, places, shields,
--                   bridges, town dots, the zone's edge, the scale bar and the north arrow.
-- The places, bridges, shields, towns and lakes come from the game's own map files, read once offline by
-- ZeDUI/tools/map/make_survey_data.py into MapsSurveyData.lua. Without that file the colours still apply.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Tr"
require "ZeD/MapsTab"
pcall(require, "ZeD/MapsSurveyData")

ZeD = ZeD or {}
local M = ZeD.MapsSurvey or {}
ZeD.MapsSurvey = M

-- the game's zoom stops (ISMapDefinitions.lua: MINZ 0, MAXZ 24, buildings from 13)
local MINZ, MAXZ, MINZ_B = 0, 24, 13

-- ---------------------------------------------------------------------------
-- THE PALETTES (hex), one per ZeD base theme; "cb" swaps the buildings for the colour blind set while ZeD's status
-- colours are on Color blind (Settings.lua). Every label reads at 4.5 to 1 or better against what it sits on.
-- ---------------------------------------------------------------------------
local P = {
    dark = {
        ground = "1B1C1E", forest = "1F3324", mark = "96D2A0", water = "1F4C63", lake = "24618A", trail = "7A5034",
        small = "45464B", main = "A8363C", sec = "7E4447", rail = "C8C8C8",
        b = { Residential = "B88470", CommunityServices = "8A7BD0", Hospitality = "5DA0B8", Industrial = "8E8A84",
              Medical = "C26878", RestaurantsAndEntertainment = "C9AD3E", RetailAndCommercial = "8FA65A" },
        cb = { Residential = "C48A10", CommunityServices = "2F86C4", Hospitality = "4A9DCB", Industrial = "8E8E92",
               Medical = "B66E97", RestaurantsAndEntertainment = "CFC43C", RetailAndCommercial = "2FA383" },
        t = { street = "F0F0F2", building = "0C0C0C", town = "F5F5F5", forest = "9AD0AC", water = "BFE3F2" },
        ink = "E8E8E8", paper = "141414", zone = "D94A8C",
    },
    light = {
        ground = "D9D9D6", forest = "B9D2A4", mark = "2F5D2A", water = "92C6DC", lake = "6AAAD2", trail = "8B5A2B",
        small = "A8A49C", main = "DE6A6A", sec = "ECA09C", rail = "2B2B2B",
        b = { Residential = "DDAE9B", CommunityServices = "9C8FD0", Hospitality = "86BCD2", Industrial = "9A958E",
              Medical = "DC8692", RestaurantsAndEntertainment = "E6CB5E", RetailAndCommercial = "AAC072" },
        cb = { Residential = "E69F00", CommunityServices = "3F95D3", Hospitality = "8FD3F5", Industrial = "9A9A9A",
               Medical = "CC79A7", RestaurantsAndEntertainment = "F0E442", RetailAndCommercial = "009E73" },
        -- (white labels, the director, Nov 18 2026: the game draws every map label with a black shadow it lets no one
        -- change, which smudged dark labels on Light; under white text it is the label's dark edge, as on the game's
        -- own street names)
        t = { street = "FFFFFF", building = "FFFFFF", town = "FFFFFF", forest = "FFFFFF", water = "FFFFFF" },
        ink = "141414", paper = "F4F1E6", zone = "D0287A",
    },
    hicon = {
        ground = "000000", forest = "003D14", mark = "8CFFAA", water = "1F6FD6", lake = "0A3FB8", trail = "A06A00",
        small = "9A9A9A", main = "FF3B3B", sec = "FF9A9A", rail = "FFFFFF",
        b = { Residential = "FFAE7A", CommunityServices = "B39CFF", Hospitality = "5CD8FF", Industrial = "A8A8A8",
              Medical = "FF6F8C", RestaurantsAndEntertainment = "FFE14A", RetailAndCommercial = "A6FF5C" },
        cb = { Residential = "FFB000", CommunityServices = "3D9BFF", Hospitality = "6CD0FF", Industrial = "8A8A8A",
               Medical = "FF8CC6", RestaurantsAndEntertainment = "FFF04A", RetailAndCommercial = "00D49A" },
        t = { street = "000000", building = "000000", town = "FFFFFF", forest = "8CFFAA", water = "FFFFFF" },
        ink = "FFFFFF", paper = "000000", zone = "FF4FA8",
    },
}
M.PALETTES = P

local function rgb(h) return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16) end
M.rgb = rgb

--- The palette in use: the first player's base theme and status colours.
function M.key()
    local base = ZeD.currentBase or "dark"
    if not P[base] then base = "dark" end
    return base, (ZeD.currentStatus == "cb")
end
function M.palette()
    local base, cb = M.key()
    return P[base], cb
end

-- ---------------------------------------------------------------------------
-- RESTYLE: each named layer's fill is rebuilt with the game's own zoom stops (its fades kept), in the theme's colour
-- ---------------------------------------------------------------------------
-- { layer, colour field, stops { zoom, alpha } }
local POLY = {
    { "water",          "water", { { MINZ, 255 }, { MAXZ, 255 } } },
    { "road-trail",     "trail", { { 12.25, 0 }, { 13, 255 }, { MAXZ, 255 } } },
    { "road-tertiary",  "small", { { 11.5, 0 }, { 13, 255 }, { MAXZ, 255 } } },
    { "road-secondary", "sec",   { { MINZ, 255 }, { MAXZ, 255 } } },
    { "road-primary",   "main",  { { MINZ, 255 }, { MAXZ, 255 } } },
    { "railway",        "rail",  { { MINZ, 255 }, { MAXZ, 255 } } },
}
local BUILD_STOPS = { { MINZ_B, 0 }, { MINZ_B + 0.5, 255 }, { MAXZ, 255 } }
local BUILDINGS = { { "building", "Residential" }, { "building-Residential", "Residential" },
    { "building-CommunityServices", "CommunityServices" }, { "building-Hospitality", "Hospitality" },
    { "building-Industrial", "Industrial" }, { "building-Medical", "Medical" },
    { "building-RestaurantsAndEntertainment", "RestaurantsAndEntertainment" },
    { "building-RetailAndCommercial", "RetailAndCommercial" } }
-- the label layers (MapUtils.initDefaultTextLayersV3) and their stops
local TEXT = {
    { "text-street",       "street",   { { 13, 0 }, { 13.5, 255 } } },
    { "text-building",     "building", { { 13, 0 }, { 13.5, 255 }, { 16.5, 255 }, { 17, 0 } } },
    { "text-place",        "building", { { 13, 0 }, { 13.5, 255 }, { 16.5, 255 }, { 17, 0 } } },
    { "text-town",         "town",     { { 0, 255 }, { 13, 255 }, { 13.5, 0 } } },
    { "text-forest",       "forest",   { { 0, 255 }, { 13, 255 }, { 13.5, 0 } } },
    { "text-water-small",  "water",    { { 0, 255 }, { 16, 255 }, { 16.5, 0 } } },
    { "text-water-medium", "water",    { { 0, 255 }, { 14.5, 255 }, { 15, 0 } } },
    { "text-water-nofade", "water",    { { 0, 255 } } },
}

-- (QA, Nov 18 2026, read from projectzomboid.jar: only the texture, text and pyramid layers have removeAllFill /
-- removeAllTexture; the polygon layers (forest, water, roads, buildings) do not, and a missing method on a Java
-- object throws. Every layer kind has getFillStops / removeFill, and the polygon layers getTextureStops /
-- removeTexture and getScaleStops / removeScale, so stops are cleared one at a time.)
local function clearFills(layer) for _ = 1, layer:getFillStops() do layer:removeFill(0) end end
local function clearTextures(layer) for _ = 1, layer:getTextureStops() do layer:removeTexture(0) end end
local function clearScales(layer) for _ = 1, layer:getScaleStops() do layer:removeScale(0) end end
M._clearFills = clearFills

local function refill(layer, hex, stops)
    if not (layer and hex) then return end
    local r, g, b = rgb(hex)
    clearFills(layer)
    for _, s in ipairs(stops) do layer:addFill(s[1], r, g, b, s[2]) end
end

-- the woodland marks: a small tile of tree marks on the theme's forest colour, laid in screen pixels
-- (as the game lays its colour blind patterns), from zoom 15 where the forest shapes take over from the forest picture
local function woodsTex(base) return "media/textures/ZeD/map/woods_" .. base .. ".png" end

local function lakeName(i) return "zed-lake-" .. i end

function M.restyle(mp)
    local pal, cb = M.palette()
    local api = mp.mapAPI
    local styleAPI = api:getStyleAPI()
    local base = M.key()
    -- the ground, and the ground not yet explored (the game's shades of it)
    local r, g, b = rgb(pal.ground)
    r, g, b = r / 255, g / 255, b / 255
    api:setBackgroundRGBA(r, g, b, 1.0)
    api:setUnvisitedRGBA(r * 0.915, g * 0.915, b * 0.915, 1.0)
    api:setUnvisitedGridRGBA(r * 0.777, g * 0.777, b * 0.777, 1.0)
    for _, d in ipairs(POLY) do refill(styleAPI:getLayerByName(d[1]), pal[d[2]], d[3]) end
    local bset = cb and pal.cb or pal.b
    for _, d in ipairs(BUILDINGS) do refill(styleAPI:getLayerByName(d[1]), bset[d[2]], BUILD_STOPS) end
    for _, d in ipairs(TEXT) do refill(styleAPI:getLayerByName(d[1]), pal.t[d[2]], d[3]) end
    -- the forest picture (below zoom 15) in the theme's forest colour
    local pyr = styleAPI:getLayerByName("pyramid-forest")
    if pyr then
        local fr, fg, fb = rgb(pal.forest)
        clearFills(pyr)
        pyr:addFill(0.0, fr, fg, fb, 255)
        pyr:addFill(14.999, fr, fg, fb, 255)
        pyr:addFill(15.0, 0, 0, 0, 0)
    end
    -- the forest shapes (from zoom 15): white, carrying the tree-mark tile in its own colours
    local forest = styleAPI:getLayerByName("forest")
    if forest then
        clearFills(forest)
        clearTextures(forest)
        clearScales(forest)
        forest:addFill(MINZ, 255, 255, 255, 0)
        forest:addFill(14.5, 255, 255, 255, 0)
        forest:addFill(15, 255, 255, 255, 255)
        forest:addFill(MAXZ, 255, 255, 255, 255)
        forest:addTexture(MINZ, woodsTex(base), "ScreenPixel")
        forest:addScale(MINZ, math.max(1, math.floor(2 * ((ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1) + 0.5)))
    end
    -- the paper grain over everything near (MapUtils.overlayPaper): dark themes darken with it, the light one lightens
    local paperL = styleAPI:getLayerByName("paper")
    if paperL then
        local pr, pg, pb = 255, 255, 255
        if base ~= "light" then pr, pg, pb = 0, 0, 0 end
        clearFills(paperL)
        paperL:addFill(14.00, pr, pg, pb, 0)
        paperL:addFill(15.00, pr, pg, pb, 32)
    end
    M.lakes(mp, pal)
    mp._zedSurveyKey = base .. (cb and ":cb" or "")
end

-- The lakes (the game tags all its water "river"): each a mask picture over the squares it covers, an engine layer
-- just above the water's, so the labels and notes draw over it as over the rest of the map.
function M.lakes(mp, pal)
    local data = ZeD.MapsSurveyData
    if not (data and data.lakes) then return end
    local styleAPI = mp.mapAPI:getStyleAPI()
    local lr, lg, lb = rgb(pal.lake)
    local waterAt = styleAPI:indexOfLayer("water")
    for i, L in ipairs(data.lakes) do
        local name = lakeName(i)
        local layer = styleAPI:getLayerByName(name)
        if not layer then
            layer = styleAPI:newTextureLayer(name)
            layer:setMinZoom(MINZ)
            layer:addTexture(MINZ, L.tex)
            layer:setBoundsInSquares(L.x1, L.y1, L.x2, L.y2)
            local at = styleAPI:indexOfLayer(name)
            if waterAt and waterAt >= 0 and at and at >= 0 then
                styleAPI:moveLayer(at, waterAt + 1)
                waterAt = waterAt + 1
            end
        end
        clearFills(layer)
        layer:addFill(MINZ, lr, lg, lb, 255)
    end
end

--- Each frame of a Survey map (ZeD_WorldMap:render): a theme or status-colour change recolours it in place.
function M.watch(mp)
    if mp.style ~= "survey" or mp._paperItem then return end
    local base, cb = M.key()
    if mp._zedSurveyKey ~= base .. (cb and ":cb" or "") then pcall(M.restyle, mp) end
end

-- ===========================================================================
-- THE PRINTED ADDITIONS (drawn by ZeD over its own map panel)
-- ===========================================================================
-- zoom bands (the map's zoom, getZoomF): towns and shields while zoomed out, places and bridges close up
local Z_TOWN_MAX, Z_SHIELD_MIN, Z_SHIELD_MAX, Z_PLACE_MIN, Z_BRIDGE_MIN = 13.5, 12.5, 17.5, 14.0, 15.0
local GRID_SQ = 1200          -- a grid cell: 1200 squares (four of the map's 300-square cells)

-- the place kinds: a ZeD pixel icon, or a drawn mark where there is none
local PLACE_ICON = { gas = "gas_pump", police = "badge", fire = "flame", hospital = "medkit", pharmacy = "pills",
    school = "book", grocery = "can", lodging = "bed", post = "inbox", military = "star", prison = "padlock",
    mechanic = "wrench", guns = "gun", library = "bookcase" }
M.PLACE_ICON = PLACE_ICON
local DRAWN = { church = true, airport = true, rail = true, bank = true }

local function inkRGB(hex)
    local r, g, b = rgb(hex)
    return r / 255, g / 255, b / 255
end

local function zoomOf(mp)
    local ok, z = pcall(function() return mp.mapAPI:getZoomF() end)
    return ok and z or 0
end

-- px per world square at the map's present zoom
local function pxPerSquare(mp)
    local api = mp.mapAPI
    local x0, y0 = api:getCenterWorldX(), api:getCenterWorldY()
    return math.abs(api:worldToUIX(x0 + 100, y0) - api:worldToUIX(x0, y0)) / 100
end

-- a small paper badge with an ink edge (a place's sign, a town's dot), centred on cx, cy
local function badge(mp, cx, cy, s, paper, ink)
    local x, y = math.floor(cx - s / 2), math.floor(cy - s / 2)
    mp:drawRect(x, y, s, s, 1, paper[1], paper[2], paper[3])
    mp:drawRectBorder(x, y, s, s, 1, ink[1], ink[2], ink[3])
    return x, y
end

local function drawnMark(mp, kind, x, y, s, ink)
    local r, g, b = ink[1], ink[2], ink[3]
    local u = math.max(1, math.floor(s / 8))
    local cx, cy = x + math.floor(s / 2), y + math.floor(s / 2)
    if kind == "church" then        -- a cross
        mp:drawRect(cx - u / 2, y + u, u, s - 2 * u, 1, r, g, b)
        mp:drawRect(x + 2 * u, y + 3 * u, s - 4 * u, u, 1, r, g, b)
    elseif kind == "airport" then   -- a plane seen from above
        mp:drawRect(cx - u / 2, y + u, u, s - 2 * u, 1, r, g, b)
        mp:drawRect(x + u, cy - u, s - 2 * u, u, 1, r, g, b)
        mp:drawRect(cx - 2 * u, y + s - 3 * u, 4 * u, u, 1, r, g, b)
    elseif kind == "rail" then      -- track and ties
        mp:drawRect(x + u, cy - 2 * u, s - 2 * u, u, 1, r, g, b)
        mp:drawRect(x + u, cy + u, s - 2 * u, u, 1, r, g, b)
        for tx = x + 2 * u, x + s - 3 * u, 2 * u do mp:drawRect(tx, cy - 3 * u, u, 5 * u, 1, r, g, b) end
    elseif kind == "bank" then      -- a dollar sign
        local f = UIFont.Small
        local tw = getTextManager():MeasureStringX(f, "$")
        mp:drawText("$", cx - tw / 2, cy - getTextManager():getFontHeight(f) / 2, r, g, b, 1, f)
    end
end

local function placeIcon(kind, box)
    local id = PLACE_ICON[kind]
    if not (id and ZeD.PxIcon and ZeD.PxIcon.has(id)) then return nil end
    return (ZeD.PxIcon.tex(id, box))
end

-- the shields' pictures (ZeDUI/tools/map/make_survey_art.py)
local SHIELD_TEX = { us = "media/textures/ZeD/map/shield_us.png", ky = "media/textures/ZeD/map/shield_ky.png",
                     i = "media/textures/ZeD/map/shield_i.png" }
local _tex = {}
local function tex(path)
    local t = _tex[path]
    if t == nil then t = getTexture(path) or false; _tex[path] = t end
    return t or nil
end

local function onScreen(mp, x, y, pad)
    return x > -pad and y > -pad and x < mp:getWidth() + pad and y < mp:getHeight() + pad
end

local function drawGrid(mp, data, ink, ppsq)
    local api = mp.mapAPI
    local b = data and data.bounds
    if not b then return end
    local T = ZeD.T
    local f = T.fontF5 or UIFont.Small
    local tm = getTextManager()
    local fh = tm:getFontHeight(f)
    local W, H = mp:getWidth(), mp:getHeight()
    local col = 0
    for wx = b[1], b[3], GRID_SQ do
        local sx = api:worldToUIX(wx, b[2])
        if sx >= 0 and sx <= W then mp:drawRect(math.floor(sx), 0, 1, H, 0.30, ink[1], ink[2], ink[3]) end
        -- the column's letter at the view's top, in the middle of its cell
        local mid = api:worldToUIX(wx + GRID_SQ / 2, b[2])
        if mid > 8 and mid < W - 8 and wx + GRID_SQ <= b[3] + GRID_SQ then
            local s = col < 26 and string.char(65 + col) or (string.char(64 + math.floor(col / 26)) .. string.char(65 + col % 26))
            local tw = tm:MeasureStringX(f, s)
            mp:drawRect(mid - tw / 2 - 3, 2, tw + 6, fh, 0.85, ink[4], ink[5], ink[6])
            mp:drawText(s, mid - tw / 2, 2, ink[1], ink[2], ink[3], 1, f)
        end
        col = col + 1
    end
    local row = 1
    for wy = b[2], b[4], GRID_SQ do
        local sy = api:worldToUIY(b[1], wy)
        if sy >= 0 and sy <= H then mp:drawRect(0, math.floor(sy), W, 1, 0.30, ink[1], ink[2], ink[3]) end
        local mid = api:worldToUIY(b[1], wy + GRID_SQ / 2)
        if mid > fh and mid < H - fh then
            local s = tostring(row)
            local tw = tm:MeasureStringX(f, s)
            mp:drawRect(2, mid - fh / 2, tw + 6, fh, 0.85, ink[4], ink[5], ink[6])
            mp:drawText(s, 5, mid - fh / 2, ink[1], ink[2], ink[3], 1, f)
        end
        row = row + 1
    end
end

local function drawZone(mp, data, pal)
    local b = data and data.bounds
    if not b then return end
    local api = mp.mapAPI
    local x1, y1 = api:worldToUIX(b[1], b[2]), api:worldToUIY(b[1], b[2])
    local x2, y2 = api:worldToUIX(b[3], b[4]), api:worldToUIY(b[3], b[4])
    local zr, zg, zb = inkRGB(pal.zone)
    local band = math.max(6, math.floor(pxPerSquare(mp) * 120))   -- 120 squares inside the edge
    local step = math.max(4, math.floor(band / 6))
    local W, H = mp:getWidth(), mp:getHeight()
    -- the out-of-bounds band (the orienteering legend's magenta bars) along each edge that is on screen
    local function bars(bx, by, bw, bh)
        local cx0, cx1 = math.max(0, bx), math.min(W, bx + bw)
        local cy0, cy1 = math.max(0, by), math.min(H, by + bh)
        if cx1 <= cx0 or cy1 <= cy0 then return end
        local start = bx + math.ceil((cx0 - bx) / step) * step
        for x = start, cx1 - 1, step do
            mp:drawRect(x, cy0, math.max(1, math.floor(step / 2)), cy1 - cy0, 0.55, zr, zg, zb)
        end
    end
    bars(x1, y1, x2 - x1, band)
    bars(x1, y2 - band, x2 - x1, band)
    bars(x1, y1 + band, band, (y2 - y1) - 2 * band)
    bars(x2 - band, y1 + band, band, (y2 - y1) - 2 * band)
    -- its name, once, along the top band where it shows
    if y1 + band > 0 and y1 < H then
        local f = ZeD.T.fontF5 or UIFont.Small
        local s = ZeD.tr("UI_ZeD_Map_ExclusionZone")
        local tw = getTextManager():MeasureStringX(f, s)
        local tx = math.max(x1 + band + 4, math.min(x2 - band - tw - 4, (W - tw) / 2))
        local fh = getTextManager():getFontHeight(f)
        local ty = y1 + (band - fh) / 2
        if ty >= 0 and ty + fh <= H then   -- (only where the whole of it is on the map)
            local pr, pg, pbb = inkRGB(pal.paper)
            mp:drawRect(tx - 3, ty, tw + 6, fh, 0.9, pr, pg, pbb)
            mp:drawText(s, tx, ty, zr, zg, zb, 1, f)
        end
    end
end

local function drawTowns(mp, data, ink, paper)
    local api = mp.mapAPI
    local T = ZeD.T
    for _, t in ipairs(data.towns or {}) do
        local sx, sy = api:worldToUIX(t.x, t.y), api:worldToUIY(t.x, t.y)
        if onScreen(mp, sx, sy, 20) then
            -- above the town's name: an open circle for a town, a ringed dot for a larger one, a filled square for a city
            local s = T.px(t.size == 3 and 9 or 8)
            local cy = sy - T.px(16)
            if t.size == 3 then
                mp:drawRect(sx - s / 2, cy - s / 2, s, s, 1, ink[1], ink[2], ink[3])
            else
                badge(mp, sx, cy, s, paper, ink)
                if t.size == 2 then mp:drawRect(sx - 1, cy - 1, 3, 3, 1, ink[1], ink[2], ink[3]) end
            end
        end
    end
end

local function drawPlaces(mp, data, ink, paper, z)
    local api = mp.mapAPI
    local T = ZeD.T
    local s = T.px(z >= 16 and 18 or 14)
    for _, p in ipairs(data.places or {}) do
        local sx, sy = api:worldToUIX(p.x, p.y), api:worldToUIY(p.x, p.y)
        if onScreen(mp, sx, sy, s) then
            local x, y = badge(mp, sx, sy, s, paper, ink)
            local icon = placeIcon(p.kind, s - 2)
            if icon then
                mp:drawTextureScaled(icon, x + 1, y + 1, s - 2, s - 2, 1, ink[1], ink[2], ink[3])
            elseif DRAWN[p.kind] then
                drawnMark(mp, p.kind, x, y, s, ink)
            end
        end
    end
end

local function drawShields(mp, data)
    local api = mp.mapAPI
    local T = ZeD.T
    local f = T.fontF5 or UIFont.Small
    local tm = getTextManager()
    local fh = tm:getFontHeight(f)
    for _, sh in ipairs(data.shields or {}) do
        local sx, sy = api:worldToUIX(sh.x, sh.y), api:worldToUIY(sh.x, sh.y)
        local t = tex(SHIELD_TEX[sh.t] or "")
        if t and onScreen(mp, sx, sy, 30) then
            local n = tostring(sh.n)
            local tw = tm:MeasureStringX(f, n)
            local h = math.max(T.px(18), fh + T.px(6))
            local w = math.max(h, tw + T.px(10))
            mp:drawTextureScaled(t, sx - w / 2, sy - h / 2, w, h, 1, 1, 1, 1)
            local white = sh.t == "i"
            local c = white and 1 or 0
            mp:drawText(n, sx - tw / 2, sy - fh / 2 + (sh.t == "ky" and 0 or T.px(1)), c, c, c, 1, f)
        end
    end
end

local function drawBridges(mp, data, ink, ppsq)
    local api = mp.mapAPI
    local T = ZeD.T
    local len = math.max(T.px(8), math.floor(ppsq * 12))
    local gap = math.max(T.px(4), math.floor(ppsq * 5))
    for _, br in ipairs(data.bridges or {}) do
        local sx, sy = api:worldToUIX(br.x, br.y), api:worldToUIY(br.x, br.y)
        if onScreen(mp, sx, sy, -(len / 2 + gap)) then   -- (a mark only where the whole of it is on the map)
            -- the USGS bridge: two short lines along the road, one each side of it
            local a = ((br.a or 0) % 180 + 180) % 180   -- (Kahlua's % keeps a negative sign)
            if a < 30 or a > 150 then           -- the road runs east-west
                mp:drawRect(sx - len / 2, sy - gap, len, 1, 1, ink[1], ink[2], ink[3])
                mp:drawRect(sx - len / 2, sy + gap, len, 1, 1, ink[1], ink[2], ink[3])
            elseif a > 60 and a < 120 then      -- north-south
                mp:drawRect(sx - gap, sy - len / 2, 1, len, 1, ink[1], ink[2], ink[3])
                mp:drawRect(sx + gap, sy - len / 2, 1, len, 1, ink[1], ink[2], ink[3])
            else                                 -- diagonal: stepped
                local dir = (a < 90) and -1 or 1
                for i = -len / 2, len / 2, 1 do
                    mp:drawRect(sx + i - gap, sy + dir * i - gap, 1, 1, 1, ink[1], ink[2], ink[3])
                    mp:drawRect(sx + i + gap, sy + dir * i + gap, 1, 1, 1, ink[1], ink[2], ink[3])
                end
            end
        end
    end
end

-- the scale bar and the north arrow, in the map's bottom-left corner
local function drawScale(mp, ink, paper, ppsq)
    local T = ZeD.T
    local f = T.fontF5 or UIFont.Small
    local tm = getTextManager()
    local fh = tm:getFontHeight(f)
    -- the bar's length: the round number of squares nearest a third of the map's width (a square is a metre)
    local want = mp:getWidth() / 3 / math.max(0.0001, ppsq)
    local steps = { 10, 20, 50, 100, 200, 500, 1000, 2000, 5000 }
    local m = steps[1]
    for _, s in ipairs(steps) do if s <= want then m = s end end
    local w = math.floor(m * ppsq)
    local pad = T.px(6)
    local bh = T.px(4)
    local label = (m >= 1000) and (tostring(m / 1000) .. " km") or (tostring(m) .. " m")
    local boxW = w + pad * 2 + T.px(24)
    local boxH = fh * 2 + bh + pad * 2
    -- (at the foot's middle: the map key opens over the bottom-left corner, MapsTabKey.lua)
    local bx, by = math.floor((mp:getWidth() - boxW) / 2), mp:getHeight() - boxH - T.px(8)
    mp:drawRect(bx, by, boxW, boxH, 0.9, paper[1], paper[2], paper[3])
    mp:drawRectBorder(bx, by, boxW, boxH, 1, ink[1], ink[2], ink[3])
    -- the bar: four segments, ink and paper by turns
    local x0, y0 = bx + pad, by + pad + fh
    for i = 0, 3 do
        local sx = x0 + math.floor(w * i / 4)
        local sw = math.floor(w * (i + 1) / 4) - math.floor(w * i / 4)
        if i % 2 == 0 then mp:drawRect(sx, y0, sw, bh, 1, ink[1], ink[2], ink[3]) end
    end
    mp:drawRectBorder(x0, y0, w, bh, 1, ink[1], ink[2], ink[3])
    mp:drawText("0", x0 - 2, y0 + bh + 1, ink[1], ink[2], ink[3], 1, f)
    local lw = tm:MeasureStringX(f, label)
    mp:drawText(label, x0 + w - lw, y0 + bh + 1, ink[1], ink[2], ink[3], 1, f)
    -- the north arrow, beside the bar: an upright triangle over an N
    local ax = bx + boxW - pad - T.px(8)
    local ay = by + pad
    for i = 0, T.px(8) do
        local half = math.floor(i / 2)
        mp:drawRect(ax - half, ay + i, half * 2 + 1, 1, 1, ink[1], ink[2], ink[3])
    end
    local nw = tm:MeasureStringX(f, "N")
    mp:drawText("N", ax - nw / 2, ay + T.px(9), ink[1], ink[2], ink[3], 1, f)
end

function M.drawMap(mp, win)
    if mp.style ~= "survey" or mp._paperItem then return end
    local pal = M.palette()
    local data = ZeD.MapsSurveyData or {}
    local z = zoomOf(mp)
    local ir, ig, ib = inkRGB(pal.ink)
    local pr, pg, pb = inkRGB(pal.paper)
    local ink = { ir, ig, ib, pr, pg, pb }
    local paper = { pr, pg, pb }
    local ppsq = pxPerSquare(mp)
    drawZone(mp, data, pal)
    drawGrid(mp, data, ink, ppsq)
    if z >= Z_BRIDGE_MIN then drawBridges(mp, data, ink, ppsq) end
    if z >= Z_PLACE_MIN then drawPlaces(mp, data, ink, paper, z) end
    if z >= Z_SHIELD_MIN and z <= Z_SHIELD_MAX then drawShields(mp, data) end
    if z < Z_TOWN_MAX then drawTowns(mp, data, ink, paper) end
    drawScale(mp, ink, paper, ppsq)
end

-- ---------------------------------------------------------------------------
-- WHAT THE KEY SHOWS (MapsTabKey.lua draws it): two pages, Colors and Symbols, each a list of
-- { section } and { kind, name, colour or icon } rows in the symbol sheets' order
-- ---------------------------------------------------------------------------
M.PLACE_ORDER = { "gas", "police", "fire", "hospital", "pharmacy", "school", "church", "grocery", "lodging", "post",
    "airport", "rail", "military", "prison", "bank", "mechanic", "guns", "library" }

--- The Colors page's rows: { sec = key } or { swatch = hex, line = true for a road, text = words }.
function M.keyColors()
    local pal, cb = M.palette()
    local bset = cb and pal.cb or pal.b
    local rows = {
        { sec = "UI_ZeD_MapKey_Roads" },
        { swatch = pal.main, line = 3, text = ZeD.tr("UI_ZeD_MapKey_Primary") },
        { swatch = pal.sec, line = 3, text = ZeD.tr("UI_ZeD_MapKey_Secondary") },
        { swatch = pal.small, line = 2, text = ZeD.tr("UI_ZeD_MapKey_Street") },
        { swatch = pal.trail, line = 1, text = ZeD.tr("UI_ZeD_MapKey_Trail") },
        { swatch = pal.rail, line = 2, ties = true, text = ZeD.tr("UI_ZeD_MapKey_Railway") },
        { sec = "UI_ZeD_MapKey_WaterWoods" },
        { swatch = pal.water, text = ZeD.tr("UI_ZeD_MapKey_River") },
        { swatch = pal.lake, text = ZeD.tr("UI_ZeD_MapKey_Lake") },
        { swatch = pal.forest, woods = true, text = ZeD.tr("UI_ZeD_MapKey_Woodland") },
        { sec = "UI_ZeD_MapKey_Buildings" },
    }
    -- the game's own words for the building uses (IGUI_Map_<use>)
    local USES = { { "Residential", "Residential" }, { "CommunityServices", "Community" }, { "Hospitality", "Hospitality" },
        { "Industrial", "Industrial" }, { "Medical", "Medical" }, { "RestaurantsAndEntertainment", "RestaurantsEntertainment" },
        { "RetailAndCommercial", "RetailCommercial" } }
    for _, u in ipairs(USES) do rows[#rows + 1] = { swatch = bset[u[1]], text = ZeD.tr("IGUI_Map_" .. u[2]) } end
    return rows
end

--- The Symbols page's rows: { sec = key } or { place = kind | mark = "town" / "city" / "us" / "ky" / "bridge" / "zone", text }.
function M.keySymbols()
    local rows = { { sec = "UI_ZeD_MapKey_Places" } }
    for _, k in ipairs(M.PLACE_ORDER) do rows[#rows + 1] = { place = k, text = ZeD.tr("UI_ZeD_MapKey_Place_" .. k) } end
    rows[#rows + 1] = { sec = "UI_ZeD_MapKey_Marks" }
    for _, k in ipairs({ "town", "city", "us", "ky", "bridge", "zone" }) do
        rows[#rows + 1] = { mark = k, text = ZeD.tr("UI_ZeD_MapKey_Mark_" .. k) }
    end
    return rows
end

--- Draws a Symbols row's picture in an s x s box at x, y (the key's swatch).
function M.drawKeySymbol(panel, row, x, y, s)
    local pal = M.palette()
    local ir, ig, ib = inkRGB(pal.ink)
    local pr, pg, pb = inkRGB(pal.paper)
    local ink, paper = { ir, ig, ib }, { pr, pg, pb }
    local cx, cy = x + s / 2, y + s / 2
    if row.place then
        local bx, by = badge(panel, cx, cy, s, paper, ink)
        local icon = placeIcon(row.place, s - 2)
        if icon then panel:drawTextureScaled(icon, bx + 1, by + 1, s - 2, s - 2, 1, ir, ig, ib)
        elseif DRAWN[row.place] then drawnMark(panel, row.place, bx, by, s, ink) end
    elseif row.mark == "town" or row.mark == "city" then
        local d = math.floor(s * 0.6)
        if row.mark == "city" then panel:drawRect(cx - d / 2, cy - d / 2, d, d, 1, ir, ig, ib)
        else badge(panel, cx, cy, d, paper, ink) end
    elseif row.mark == "us" or row.mark == "ky" then
        local t = tex(SHIELD_TEX[row.mark])
        if t then panel:drawTextureScaled(t, x, y, s, s, 1, 1, 1, 1) end
    elseif row.mark == "bridge" then
        local wr, wg, wb = inkRGB(pal.water)
        panel:drawRect(x, y + s / 4, s, s / 2, 1, wr, wg, wb)
        local mr, mg, mb = inkRGB(pal.main)
        panel:drawRect(x + s / 2 - 2, y, 4, s, 1, mr, mg, mb)
        panel:drawRect(x + s / 2 - 4, y + 2, 1, s - 4, 1, ir, ig, ib)
        panel:drawRect(x + s / 2 + 3, y + 2, 1, s - 4, 1, ir, ig, ib)
    elseif row.mark == "zone" then
        local zr, zg, zb = inkRGB(pal.zone)
        for i = 0, s - 1, 4 do panel:drawRect(x + i, y, 2, s, 0.85, zr, zg, zb) end
    end
end

-- the printed additions as one of the map's extensions (MapsTabExt.lua), under the key and the side list
if ZeD.MapsTab and ZeD.MapsTab.addExtension then
    ZeD.MapsTab.addExtension("zed-survey-print", {
        order = 5,
        drawMap = function(mp, win)
            local ok, err = pcall(M.drawMap, mp, win)
            if not ok and ZeD.Safe and ZeD.Safe.fault then ZeD.Safe.fault("survey print", err) end
        end,
    })
end
