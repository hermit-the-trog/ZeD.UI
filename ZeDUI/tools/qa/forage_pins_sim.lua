-- ZeDUI/tools/qa/forage_pins_sim.lua (Nov 17 2026, Design's over-head handoff, sets A and B): the magnifier pins and
-- the search-mode eye, with no game running. Runs the REAL Overrides/ForagePins.lua on a stand-in ISBaseIcon and
-- ISSearchManager, and the REAL ZeD_Bubbles.lua for the eye note.
--   PIN       identified: back, the item centered on the lens at (29, 26) at its own size, the glass over it; a large
--             item fitted to 32 units, never stretched up; a known poison adds the mark 12 x 12 at (42, 36); every
--             layer at the game's alpha and colour; s = width / 60 follows the pin's size (zoom)
--   UNKNOWN   not identified (or renderItemTexture off): the frosted lens only, no item
--   SAFE      in safe mode the game's own renderPinIcon and renderEye run; a failing ZeD pin draws the game's
--   EYE       the game's eye is not drawn; in search mode ZeD's eye note is in the stack just above the speed note,
--             at the game's fade; out of search mode, no eye; the eye's pixels match Design's 16 x 10 icon
-- Run from the repo root: lua51 ZeDUI/tools/qa/forage_pins_sim.lua
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

function require() end
next = nil
function getTimestampMs() return 1000 end
local SAFE = false
local FAULTS = {}
ZeD = { upper = string.upper, Safe = { on = function() return SAFE end, fault = function(k, e) FAULTS[#FAULTS + 1] = k end } }

-- textures: a name and a size
local TEX = {}
function getTexture(path)
    local name = path:match("([^/]+)%.png$")
    if not name then return nil end
    if not TEX[path] then TEX[path] = { name = name, getWidth = function() return 60 end, getHeight = function() return 90 end } end
    return TEX[path]
end
local function itemTex(w, h) return { name = "item", getWidth = function() return w end, getHeight = function() return h end } end

-- the game's classes
local GAME_PIN, GAME_EYE = 0, 0
ISBaseIcon = {}
function ISBaseIcon:renderPinIcon() GAME_PIN = GAME_PIN + 1 end
ISSearchManager = { players = {} }
function ISSearchManager:renderEye() GAME_EYE = GAME_EYE + 1 end
-- the game's pointer: a homing point that records what is done to it
local MARKERS = {}
local function homingPoint(r, g, b, a)
    local m = { r = r, g = g, b = b, a = a, tex = "arrow_triangle", w = 32, h = 32, sets = 0 }
    function m:setX(v) self.x = v end
    function m:setY(v) self.y = v end
    function m:setHomeOnOffsetX() end
    function m:setHomeOnOffsetY() end
    function m:setTexture(t) self.tex = t; self.sets = self.sets + 1 end
    function m:setRenderWidth(v) self.w = v end
    function m:setRenderHeight(v) self.h = v end
    function m:remove() self.removed = true end
    MARKERS[#MARKERS + 1] = m
    return m
end
function getWorldMarkers() return { addPlayerHomingPoint = function(_, chr, x, y, r, g, b, a) return homingPoint(r, g, b, a) end } end
function ISBaseIcon:updateManagerMarkers() end
function ISBaseIcon:addWorldMarker()   -- (the game's own, 42.21)
    self:updateManagerMarkers()
    if self.isBeingRemoved then return end
    self.worldMarker = getWorldMarkers():addPlayerHomingPoint(self.character, self.xCoord, self.yCoord, 0.8, 0.8, 0.8, 1)
    self:setWorldMarkerPosition()
end
function ISBaseIcon:setWorldMarkerPosition() self.worldMarker:setX(self.xCoord); self.worldMarker:setY(self.yCoord) end

assert(loadfile("42/media/lua/client/ZeD/Overrides/ForagePins.lua"))()

local function pin(width, opts)
    local calls = {}
    local p = setmetatable({
        width = width, height = width * 1.5, textureColor = { r = 0.9, g = 0.8, b = 0.7 },
        itemTexture = opts.item, identified = opts.identified, renderItemTexture = opts.render, isKnownPoison = opts.poison,
        getAlpha = function() return 0.6 end,
        drawTextureScaled = function(self, t, x, y, w, h, a, r, g, b) calls[#calls + 1] = { t = t.name, x = x, y = y, w = w, h = h, a = a, r = r } end,
    }, { __index = ISBaseIcon })
    p:renderPinIcon()
    return calls
end

-- PIN: zoom 1 (60 wide), a 32 x 32 item
local c = pin(60, { item = itemTex(32, 32), identified = true, render = true })
check("identified: three layers, back, item, glass", #c == 3 and c[1].t == "pinB_back" and c[2].t == "item" and c[3].t == "pinB_glass",
    #c .. " " .. tostring(c[1] and c[1].t) .. " " .. tostring(c[2] and c[2].t) .. " " .. tostring(c[3] and c[3].t))
check("the back covers the pin", c[1].x == 0 and c[1].y == 0 and c[1].w == 60 and c[1].h == 90)
check("the item at its own size, centered on (29, 26)", near(c[2].w, 32) and near(c[2].h, 32) and near(c[2].x, 13) and near(c[2].y, 10),
    c[2].x .. "," .. c[2].y .. " " .. c[2].w .. "x" .. c[2].h)
check("every layer at the game's alpha and colour", c[1].a == 0.6 and c[2].a == 0.6 and c[3].a == 0.6 and c[2].r == 0.9)
-- a large item, a small one, and the pin at zoom 2 (30 wide)
c = pin(60, { item = itemTex(64, 48), identified = true, render = true })
check("a 64 x 48 item fitted to 32 on its longer side", near(c[2].w, 32) and near(c[2].h, 24), c[2].w .. "x" .. c[2].h)
c = pin(60, { item = itemTex(16, 16), identified = true, render = true })
check("a 16 x 16 item is never stretched up", near(c[2].w, 16) and near(c[2].h, 16) and near(c[2].x, 21), c[2].w .. " at " .. c[2].x)
c = pin(30, { item = itemTex(32, 32), identified = true, render = true })
check("s follows the pin's size: half the pin, half the item", near(c[2].w, 16) and near(c[2].x, 6.5) and near(c[2].y, 5), c[2].w .. " at " .. c[2].x .. "," .. c[2].y)
-- poison
c = pin(60, { item = itemTex(32, 32), identified = true, render = true, poison = true })
check("a known poison: the mark last, 12 x 12 at (42, 36)", #c == 4 and c[4].t == "poison_mark" and c[4].x == 42 and c[4].y == 36 and c[4].w == 12,
    #c .. " " .. tostring(c[4] and c[4].t))
-- UNKNOWN
c = pin(60, { item = itemTex(32, 32), identified = false, render = true })
check("not identified: the frosted lens only", #c == 1 and c[1].t == "pinB_unknown" and c[1].w == 60, #c)
c = pin(60, { item = itemTex(32, 32), identified = true, render = false })
check("renderItemTexture off: the frosted lens only (the game's own test)", #c == 1 and c[1].t == "pinB_unknown", #c)
c = pin(60, { identified = true, render = true })
check("no item texture: the frosted lens only", #c == 1 and c[1].t == "pinB_unknown", #c)
check("ZeD drew every pin above: the game's never", GAME_PIN == 0, GAME_PIN)
-- SAFE
SAFE = true
c = pin(60, { item = itemTex(32, 32), identified = true, render = true })
check("safe mode: the game's pin", GAME_PIN == 1 and #c == 0, GAME_PIN)
SAFE = false
local p = setmetatable({ width = 60, height = 90, textureColor = {}, itemTexture = itemTex(32, 32), identified = true, renderItemTexture = true,
    getAlpha = function() return 1 end, drawTextureScaled = function() error("boom") end }, { __index = ISBaseIcon })
p:renderPinIcon()
check("a failing ZeD pin draws the game's and counts a fault", GAME_PIN == 2 and FAULTS[1] == "forage pin", GAME_PIN .. " " .. tostring(FAULTS[1]))

-- POINTER: the game's homing point dressed as the hand
local chr = { getX = function() return 100 end, getY = function() return 100 end }
local function find(x, y) return setmetatable({ character = chr, xCoord = x, yCoord = y }, { __index = ISBaseIcon }) end
local f = find(105, 100)   -- east of the character: to the right on screen (x - y grows)
f:addWorldMarker()
local m = f.worldMarker
check("pointer: white at full alpha, not the game's grey", m and m.r == 1 and m.g == 1 and m.b == 1 and m.a == 1, m and m.r)
check("pointer: a find to the right gets hand a (thumb on top pointing right)", m.tex == "zed_forage_hand_up_a", m.tex)
check("pointer: the hand's size, 44 x 77", m.w == 44 and m.h == 77, m.w .. "x" .. m.h)
check("pointer: the game's placement still runs", m.x == 105 and m.y == 100, tostring(m.x))
local sets = m.sets
f:setWorldMarkerPosition(); f:setWorldMarkerPosition()
check("pointer: no texture set again while nothing changes", m.sets == sets, m.sets - sets)
chr.getX = function() return 110 end   -- the character walks past it: the find is now to the left
f:setWorldMarkerPosition()
check("pointer: the find to the left gets hand b (the mirror)", m.tex == "zed_forage_hand_up_b" and m.w == 44, m.tex)
chr.getX = function() return 100 end
local g = find(100, 106)   -- south of the character: to the left on screen
g:addWorldMarker()
check("pointer: a find to the left from the start: hand b", g.worldMarker.tex == "zed_forage_hand_up_b", g.worldMarker.tex)
g.worldMarker:remove(); g.worldMarker = nil
g:addWorldMarker()
check("pointer: a new marker after a remove is dressed again", g.worldMarker.tex == "zed_forage_hand_up_b" and g.worldMarker.w == 44, g.worldMarker.tex)
SAFE = true
f:setWorldMarkerPosition()
check("safe mode: the game's arrow back on the next update", m.tex == "arrow_triangle" and m.w == 32 and m.h == 32, m.tex)
local h = find(105, 100); h:addWorldMarker()
check("safe mode: a new marker is the game's own, grey, its arrow", h.worldMarker.r == 0.8 and h.worldMarker.tex == "arrow_triangle", h.worldMarker.tex)
SAFE = false
f:setWorldMarkerPosition()
check("out of safe mode: the hand again", m.tex == "zed_forage_hand_up_a" and m.w == 44, m.tex)
local gone = find(105, 100); gone.isBeingRemoved = true; gone:addWorldMarker()
check("a find being removed gets no marker (the game's own step)", gone.worldMarker == nil)

-- EYE: the game's own is not drawn
local mgr = setmetatable({ isSearchMode = true, textureColor = { r = 1, g = 1, b = 1, a = 0.33 } }, { __index = ISSearchManager })
mgr:renderEye()
check("the game's eye is not drawn", GAME_EYE == 0, GAME_EYE)
SAFE = true; mgr:renderEye(); SAFE = false
check("safe mode: the game's eye", GAME_EYE == 1, GAME_EYE)

-- the eye note, from the real ZeD_Bubbles
local RECTS = {}
ZeD.Px = { textWidth = function(s) return #tostring(s) * 6 end, k = function() return 1 end,
           rect = function(cv, x, y, w, h, col, a) RECTS[#RECTS + 1] = { x = x, y = y, w = w, h = h, c = col, a = a } end,
           rects = function() end, text = function() end }
ZeD.PixelFonts = {}
ZeD.Font = { sdf = { stat = { font = "TitleSDF", face = 64, sdf = true } } }
ZeD.Text = { realTM = function() return {} end, width = function(f, s, z) return #tostring(s) * 38 * z end, draw = function() end }
local PLAYER = {}
function getSpecificPlayer(n) if n == 0 then return PLAYER end return nil end
local SPEED = 1
function isGamePaused() return false end
function getGameSpeed() return SPEED end
assert(loadfile("42/media/lua/client/ZeD/ZeD_Bubbles.lua"))()
local B = ZeD.Bubbles

check("not in search mode: no notes", B.notes(0, 1000) == nil)
ISSearchManager.players[PLAYER] = mgr
local n = B.notes(0, 1000)
check("in search mode: one note, the eye", n and #n == 1 and n[1].eye == true, n and #n)
check("the eye keeps the game's fade", n and n[1].a == 0.33, n and n[1].a)
SPEED = 3
n = B.notes(0, 1000)
check("with the speed bubble: the eye just above it (the speed nearest the head)", n and #n == 2 and n[1].eye and n[2].speed == 3,
    n and #n)
SPEED = 1
mgr.isSearchMode = false
check("search mode off: no eye", B.notes(0, 1000) == nil)
mgr.isSearchMode = true
-- the eye's pixels
n = B.notes(0, 1000)
local L = { x0 = 0, y0 = 0, x1 = 0, y1 = 0 }
B.layoutNotes(L, n, 1000)
B.drawNotes({ el = {}, ox = 0, oy = 0, k = 1 }, { text = { r = 0, g = 0, b = 0, a = 1 }, borderS = { r = 0, g = 0, b = 0, a = 1 },
    positive = {}, danger = {} }, L)
local lit = {}
local ink = B.EYE_INK
for _, r in ipairs(RECTS) do
    for key, col in pairs(ink) do
        if r.c == col then for x = r.x, r.x + r.w - 1 do lit[(r.y) .. ":" .. x] = key end end
    end
end
local x0, y0 = n[1].x + B.PAD, n[1].y + math.floor((n[1].h - B.EYE_H) / 2)
local match, total = 0, 0
for row = 1, #B.EYE_ROWS do
    local s = B.EYE_ROWS[row]
    for col = 1, #s do
        local ch = s:sub(col, col)
        local got = lit[(y0 + row - 1) .. ":" .. (x0 + col - 1)]
        total = total + 1
        if (ch == "." and got == nil) or got == ch then match = match + 1 end
    end
end
check("the eye drawn pixel for pixel as Design's icon (16 x 10)", match == total, match .. " of " .. total)
check("the eye fits its balloon", n[1].h >= B.EYE_H and n[1].w >= B.EYE_W + 2 * B.PAD, n[1].w .. "x" .. n[1].h)

print("forage_pins_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
