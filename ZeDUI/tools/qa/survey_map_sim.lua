-- ZeDUI/tools/qa/survey_map_sim.lua  (Nov 18 2026, Build): MapsSurvey.lua with no game running.
--   * restyle on a stand-in Survey map (the game's layer names): every layer's fill in the theme's colour with the
--     game's fade stops, the forest's tree-mark texture, the paper grain's tint, the lakes as layers just above the
--     water, the ground colours; for Dark, Light and High contrast, standard and colour blind buildings.
--   * watch: a theme change recolours once, an unchanged theme never.
--   * drawMap at zooms 10 to 20 over a stand-in data file: no error, nothing drawn outside the map, and each piece
--     only in its zoom band (towns zoomed out, places and bridges close up).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/survey_map_sim.lua
-- Prints FAIL lines and a last line "survey_map_sim: N checks, M failed"; exits 1 if any failed.

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail and (" (" .. tostring(detail) .. ")") or "")) end
end

-- ---- stand-ins -----------------------------------------------------------------------------------------------
ZeD = { T = { px = function(n) return n end, fontF5 = "F5" }, currentBase = "dark", currentStatus = "standard",
        tr = function(k) return k end, Scale = { root = function() return 1 end } }
ZeD.PxIcon = { has = function(id) return id ~= "can" end, tex = function(id, box) return { id = id }, box end }
ZeD.MapsTab = {}
local ext
ZeD.MapsTab.addExtension = function(id, def) ext = def end
UIFont = { Small = "Small" }
getTexture = function(p) return { path = p } end
getTextManager = function()
    return { MeasureStringX = function(_, f, s) return #s * 6 end, getFontHeight = function() return 10 end }
end
local realRequire = require
require = function(m) if m:find("^ZeD/") then return true end return realRequire(m) end
dofile("42/media/lua/client/ZeD/MapsSurvey.lua")
require = realRequire
local M = ZeD.MapsSurvey
check("module loads and registers its drawing", M ~= nil and ext ~= nil and ext.drawMap ~= nil)

-- (the layer kinds as projectzomboid.jar has them, QA's catch Nov 18 2026: removeAllFill / removeAllTexture only on
-- the texture, text and pyramid layers, never on the polygon ones; a call to a method a kind lacks fails here as it
-- throws in the game)
local function kindOf(name)
    if name:find("^text%-") then return "text" end
    if name == "pyramid-forest" then return "pyramid" end
    if name == "paper" or name:find("^zed%-lake") then return "texture" end
    return "polygon"
end
local function newLayer(name)
    local L = { name = name, fills = {}, textures = {}, scales = {}, kind = kindOf(name) }
    local M = {}
    function M:getFillStops() return #self.fills end
    function M:removeFill(i) table.remove(self.fills, i + 1) end
    function M:addFill(z, r, g, b, a) self.fills[#self.fills + 1] = { z, r, g, b, a } end
    function M:setMinZoom(z) self.minZ = z end
    if L.kind == "polygon" or L.kind == "texture" then
        function M:addTexture(z, p, mode) self.textures[#self.textures + 1] = { z, p, mode } end
        function M:getTextureStops() return #self.textures end
        function M:removeTexture(i) table.remove(self.textures, i + 1) end
    end
    if L.kind == "polygon" then
        function M:addScale(z, s) self.scales[#self.scales + 1] = { z, s } end
        function M:getScaleStops() return #self.scales end
        function M:removeScale(i) table.remove(self.scales, i + 1) end
    else
        function M:removeAllFill() self.fills = {} end
    end
    if L.kind == "texture" then
        function M:removeAllTexture() self.textures = {} end
        function M:setBoundsInSquares(a, b, c, d) self.bounds = { a, b, c, d } end
    end
    return setmetatable(L, { __index = function(_, k)
        if M[k] then return M[k] end
        error("the game's " .. L.kind .. " layer has no " .. tostring(k), 2)
    end })
end
local NAMES = { "forest", "water", "road-trail", "road-tertiary", "road-secondary", "road-primary", "railway",
    "building", "building-Residential", "building-CommunityServices", "building-Hospitality", "building-Industrial",
    "building-Medical", "building-RestaurantsAndEntertainment", "building-RetailAndCommercial", "pyramid-forest",
    "text-note", "text-street", "text-building", "text-place", "text-town", "text-forest", "text-water-small",
    "text-water-medium", "text-water-nofade", "paper" }
local function newMap(z)
    local order = {}
    for _, n in ipairs(NAMES) do order[#order + 1] = newLayer(n) end
    local style = {}
    function style:getLayerByName(n) for _, L in ipairs(order) do if L.name == n then return L end end end
    function style:indexOfLayer(n) for i, L in ipairs(order) do if L.name == n then return i - 1 end end return -1 end
    function style:newTextureLayer(n) local L = newLayer(n); order[#order + 1] = L; return L end
    function style:moveLayer(from, to) local L = table.remove(order, from + 1); table.insert(order, to + 1, L) end
    local api = { cx = 10000, cy = 9000, z = z or 16 }
    function api:getStyleAPI() return style end
    function api:setBackgroundRGBA(r, g, b, a) self.bg = { r, g, b, a } end
    function api:setUnvisitedRGBA(r, g, b, a) self.unv = { r, g, b, a } end
    function api:setUnvisitedGridRGBA(r, g, b, a) self.grid = { r, g, b, a } end
    function api:getZoomF() return self.z end
    function api:getCenterWorldX() return self.cx end
    function api:getCenterWorldY() return self.cy end
    local function k(self) return 2 ^ (self.z - 16) * 4 end   -- px per square: 4 at zoom 16
    function api:worldToUIX(x, y) return 400 + (x - self.cx) * k(self) end
    function api:worldToUIY(x, y) return 300 + (y - self.cy) * k(self) end
    local mp = { mapAPI = api, style = "survey", order = order, draws = 0, outside = 0 }
    function mp:getWidth() return 800 end
    function mp:getHeight() return 600 end
    local function hit(self, x, y, w, h)
        self.draws = self.draws + 1
        if x + (w or 0) < -2 or y + (h or 0) < -2 or x > 802 or y > 602 then self.outside = self.outside + 1 end
    end
    function mp:drawRect(x, y, w, h) hit(self, x, y, w, h) end
    function mp:drawRectBorder(x, y, w, h) hit(self, x, y, w, h) end
    function mp:drawText(s, x, y) hit(self, x, y, 0, 0); self.texts = (self.texts or 0) + 1 end
    function mp:drawTextureScaled(t, x, y, w, h) hit(self, x, y, w, h); self.icons = (self.icons or 0) + 1 end
    return mp
end

ZeD.MapsSurveyData = {
    bounds = { 0, 0, 19200, 15600 },
    towns = { { key = "MapLabel_A", x = 10000, y = 9000, size = 1 }, { key = "MapLabel_B", x = 10400, y = 9100, size = 3 } },
    places = { { kind = "gas", x = 10020, y = 9010 }, { kind = "church", x = 9990, y = 8990 }, { kind = "grocery", x = 10010, y = 9020 } },
    bridges = { { x = 10030, y = 9030, a = 0 }, { x = 10050, y = 9030, a = 90 }, { x = 10060, y = 9030, a = -45 } },
    shields = { { t = "ky", n = "60", x = 10000, y = 9050 }, { t = "us", n = "31W", x = 10100, y = 9050 } },
    lakes = { { tex = "lake_1.png", x1 = 9900, y1 = 8900, x2 = 9960, y2 = 8950 }, { tex = "lake_2.png", x1 = 100, y1 = 100, x2 = 140, y2 = 120 } },
}

-- ---- restyle --------------------------------------------------------------------------------------------------
local function hex(h) return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16) end
for _, base in ipairs({ "dark", "light", "hicon" }) do
    for _, st in ipairs({ "standard", "cb" }) do
        ZeD.currentBase, ZeD.currentStatus = base, st
        local mp = newMap()
        local ok, err = pcall(M.restyle, mp)
        local tag = base .. "/" .. st
        check(tag .. ": restyle runs", ok, err)
        if ok then
            local pal = M.PALETTES[base]
            local S = mp.mapAPI:getStyleAPI()
            local r, g, b = hex(pal.main)
            local pr = S:getLayerByName("road-primary").fills
            check(tag .. ": primary highway in the theme's red", pr[1] and pr[1][2] == r and pr[1][3] == g and pr[1][4] == b)
            local tr = S:getLayerByName("road-trail").fills
            check(tag .. ": the trail keeps the game's fade (0 at 12.25)", tr[1] and tr[1][1] == 12.25 and tr[1][5] == 0)
            local bset = (st == "cb") and pal.cb or pal.b
            local mr = hex(bset.Medical)
            local med = S:getLayerByName("building-Medical").fills
            check(tag .. ": medical buildings in the " .. st .. " set", med[2] and med[2][2] == mr)
            local f = S:getLayerByName("forest")
            check(tag .. ": forest carries the theme's tree marks", f.textures[1] and f.textures[1][2] == "media/textures/ZeD/map/woods_" .. base .. ".png" and f.textures[1][3] == "ScreenPixel")
            local wi = S:indexOfLayer("water")
            check(tag .. ": both lakes just above the water", S:indexOfLayer("zed-lake-1") == wi + 1 and S:indexOfLayer("zed-lake-2") == wi + 2)
            local lr = hex(pal.lake)
            check(tag .. ": lakes in the lake blue", S:getLayerByName("zed-lake-1").fills[1][2] == lr)
            check(tag .. ": ground set", mp.mapAPI.bg ~= nil and math.abs(mp.mapAPI.bg[1] - hex(pal.ground) / 255) < 0.001)
            local town = S:getLayerByName("text-town").fills
            check(tag .. ": town names in the theme's ink, fading at 13.5", town[3] and town[3][1] == 13.5 and town[3][5] == 0 and town[1][2] == hex(pal.t.town))
            -- a second restyle (a theme change) does not add the lakes twice
            local n0 = #mp.order
            M.restyle(mp)
            check(tag .. ": restyling again adds no layers", #mp.order == n0)
            local f2 = S:getLayerByName("forest")
            check(tag .. ": restyling again keeps one woods texture and one scale", #f2.textures == 1 and #f2.scales == 1 and #f2.fills == 4)
        end
    end
end

-- ---- watch ----------------------------------------------------------------------------------------------------
ZeD.currentBase, ZeD.currentStatus = "dark", "standard"
local mp = newMap()
M.restyle(mp)
local calls = 0
local real = M.restyle
M.restyle = function(m) calls = calls + 1; return real(m) end
M.watch(mp); M.watch(mp)
check("watch: no change, no restyle", calls == 0)
ZeD.currentBase = "light"
M.watch(mp); M.watch(mp)
check("watch: a theme change restyles once", calls == 1)
ZeD.currentStatus = "cb"
M.watch(mp)
check("watch: the status colours restyle too", calls == 2)
mp.style = "color"
ZeD.currentBase = "hicon"
M.watch(mp)
check("watch: not on Color or Paper", calls == 2)
M.restyle = real

-- ---- drawMap --------------------------------------------------------------------------------------------------
ZeD.currentBase, ZeD.currentStatus = "dark", "standard"
for z = 10, 20 do
    local m = newMap(z)
    local ok, err = pcall(M.drawMap, m, {})
    check("drawMap at zoom " .. z .. " runs", ok, err)
    check("drawMap at zoom " .. z .. ": nothing drawn off the map", m.outside == 0, m.outside)
    if z == 16 then check("zoom 16: place icons drawn", (m.icons or 0) >= 1) end
end
local mc = newMap(16); mc.style = "color"; M.drawMap(mc, {})
check("drawMap: nothing on the Color map", mc.draws == 0)
local mpaper = newMap(16); mpaper._paperItem = {}; M.drawMap(mpaper, {})
check("drawMap: nothing on a paper map item", mpaper.draws == 0)
local mnone = newMap(16); local saved = ZeD.MapsSurveyData; ZeD.MapsSurveyData = nil
check("drawMap with no data file runs (only the scale bar)", pcall(M.drawMap, mnone, {}))
ZeD.MapsSurveyData = saved


-- ---- the real data file, and the key's pages -------------------------------------------------------------------
ZeD.MapsSurveyData = nil
dofile("42/media/lua/client/ZeD/MapsSurveyData.lua")
local D = ZeD.MapsSurveyData
check("data file: bounds, towns, places, bridges, shields, lakes", D and D.bounds and #D.towns > 0 and #D.places > 0 and #D.bridges > 0 and #D.shields > 0 and #D.lakes > 0)
local known = {}
for _, k in ipairs(M.PLACE_ORDER) do known[k] = true end
local badKind
for _, p in ipairs(D.places) do if not known[p.kind] then badKind = p.kind end end
check("data file: every place kind is one the key lists", badKind == nil, badKind)
for _, base in ipairs({ "dark", "light", "hicon" }) do
    ZeD.currentBase = base
    for _, z in ipairs({ 11, 13, 14.5, 16, 18 }) do
        for _, at in ipairs({ { 11600, 6860 }, { 13200, 2560 }, { 300, 300 }, { 19700, 15800 } }) do
            local m = newMap(z); m.mapAPI.cx, m.mapAPI.cy = at[1], at[2]
            local ok, err = pcall(M.drawMap, m, {})
            check(base .. " real data at zoom " .. z .. " (" .. at[1] .. "," .. at[2] .. ")", ok and m.outside == 0, err or m.outside)
        end
    end
    local panel = newMap(16)
    local ok = pcall(function()
        for _, r in ipairs(M.keyColors()) do assert(r.sec or (r.swatch and r.text)) end
        for _, r in ipairs(M.keySymbols()) do if not r.sec then M.drawKeySymbol(panel, r, 10, 10, 14) end end
    end)
    check(base .. ": key rows build and every symbol draws", ok)
end

print("survey_map_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
