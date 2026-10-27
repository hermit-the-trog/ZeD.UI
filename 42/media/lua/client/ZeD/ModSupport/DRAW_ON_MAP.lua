-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/DRAW_ON_MAP.lua
-- ============================================================================
-- SUPPORT FOR DRAW ON THE MAP (mod id DRAW_ON_MAP, Workshop 2804531012).
-- Mockup zed_map_overlays_v1, approved "as recommended" Oct 26 2026.
--
-- The mod puts a pencil button and a floating panel on the game's map (its
-- FreeHandUI: Draw, Line, Erase, Thickness, Fill) with three tools of its own
-- (WorldMapSymbolTool_FreeHandTool / _LineTool / _FreeHandEraser) that expect the
-- game's map panel. ZeD's Maps tab is its own map, so ZeD draws the same tools
-- itself, through the Maps tab's general hook (MapsTabExt.lua):
--   * a Draw button on the toolbar after the inks (the pencil; an icon only in the
--     World window's drawer) opens a second row with the mod's tools and words:
--     Draw, Line, Erase, Thickness, Fill (the mod's ranges and defaults);
--   * strokes are what the mod makes: the mod's own "c" symbol (a solid circle,
--     its MapSymbolDefinitions entry) laid along the pointer as ordinary map
--     marks in the game's store (so they show on the game's map too), in the ink
--     of the pen picked on the toolbar, at the mod's spacing
--     (ISMap.SCALE * 2.4 * thickness / 3 / fill) and size (ISMap.SCALE * thickness
--     / 10), up to the mod's limit of 250,000 marks;
--   * Draw and Line need a pen or pencil, Erase needs an eraser (the game's own
--     "Requires ..." lines, as the mod's FreeHandUI:checkInventory); a tool whose
--     pen or eraser is put away is put down;
--   * Erase sweeps the pointer as the mod's eraser does (rings around it, and the
--     path since the last frame), taking off any mark this player may change;
--   * controller: on the map's cursor, A held draws along the left stick
--     (Draw), A down and up again draws a straight line (Line), A held erases.
-- While a drawing tool is up, a press on the map draws instead of panning; the
-- mouse wheel still zooms. ZeD's own mark tools and these put each other down.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "DRAW_ON_MAP"

local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/MapNotes"
require "ZeD/MapsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.DRAW_ON_MAP = S

-- the mod's numbers (FreeHandUI, WorldMapSymbolTool_FreeHandTool)
local SIZE_MIN, SIZE_MAX, SIZE_STEP, SIZE_DEFAULT = 0.5, 25.0, 0.5, 2.5
local FILL_MIN, FILL_MAX, FILL_STEP, FILL_DEFAULT = 0.05, 1.0, 0.05, 1.0
local DEFAULT_SCALE = 3
local LIMIT = 250000
local LINE_TEX = "c"
local DOT_PATH = "media/ui/maps/symbols/solid-circle.png"

local function scale() return (ISMap and ISMap.SCALE) or 0.666 end

-- The mod's own words (UI_DrawOnMap_*). Its English is in an old-style
-- UI_EN.txt that Build 42.21 no longer reads, so the game hands back the raw
-- key; ZeD's own key with the same word stands in until the mod's loads.
local WORD = { UI_DrawOnMap_Draw = "UI_ZeD_Map_DrawDraw", UI_DrawOnMap_Line = "UI_ZeD_Map_DrawLine",
               UI_DrawOnMap_Erase = "UI_ZeD_Map_DrawErase", UI_DrawOnMap_Thickness = "UI_ZeD_Map_DrawThickness",
               UI_DrawOnMap_Fill = "UI_ZeD_Map_DrawFill" }
local function word(key)
    local t = getTextOrNull and getTextOrNull(key)
    if t and t ~= "" and t ~= key then return ZeD.tr(key) end
    return ZeD.tr(WORD[key])
end

-- the drawing state, per window (kept for the session: the mod keeps its
-- sliders the same way, for as long as the game's map exists)
local function st(win)
    local s = win._zedDraw
    if not s then
        s = { open = false, tool = nil, thick = SIZE_DEFAULT, fill = FILL_DEFAULT }
        win._zedDraw = s
    end
    return s
end
S.state = st

-- whether a tool can be used, and the game's line when not
local function allowed(win, tool, fresh)
    local ink = ZeD.MapsTab.ink(win, fresh)
    if tool == "erase" then
        if not ink.erase then return false, "Tooltip_Map_CantErase" end
    elseif not ink.write then
        return false, "Tooltip_Map_CantWrite"
    end
    return true
end

-- pick a tool up (or put it down again)
function S.arm(win, tool)
    local s = st(win)
    if s.tool == tool then s.tool = nil; return end
    local ok, why = allowed(win, tool, true)
    if not ok then ZeD.MapsTab.say(win._playerObj, why); return end
    s.tool = tool
    s.open = true
    ZeD.MapsTab.putDownTool(win)   -- (ZeD's own mark tool goes down)
end

-- ---------------------------------------------------------------------------
-- STROKES: the mod's addSymbol / drawLine, into the game's store
-- ---------------------------------------------------------------------------
local function addDot(win, wx, wy, sound)
    local api = ZeD.MapNotes.api()
    if not api then return false end
    if api:getSymbolCount() > LIMIT then return false end
    local c = ZeD.MapsTab.inkColor(win)
    if not c then return false end
    local s = st(win)
    local sym = api:addTexture(LINE_TEX, wx, wy)
    if not sym then return false end
    sym:setRGBA(c.r, c.g, c.b, 1.0)
    sym:setAnchor(0.5, 0.5)
    sym:setScale(scale() * s.thick / 10)
    if sound and win._playerObj then win._playerObj:playSoundLocal("MapAddSymbol") end
    return true
end

-- dots from the stroke's last point to (wx, wy), at the mod's spacing
local function drawTo(win, wx, wy, stroke)
    local s = st(win)
    local limit = scale() * (2.4 * s.thick / DEFAULT_SCALE / s.fill)
    local dx, dy = wx - stroke.wx, wy - stroke.wy
    local diff = math.abs(dx) + math.abs(dy)
    if diff <= limit then return end
    local n = math.floor(diff / limit) + 1
    for i = 1, n do
        if not addDot(win, stroke.wx + dx / n * i, stroke.wy + dy / n * i, false) then break end
    end
    stroke.wx, stroke.wy = wx, wy
end

-- the mod's eraser at (x, y) on this map (its hit test), any mark this
-- player may change
local function eraseAt(mp, x, y, sweep)
    local api = ZeD.MapNotes.panelAPI(mp)
    if not api then return end
    local idx = api:hitTest(x, y)
    if not idx or idx < 0 then return end
    local sym = api:getSymbolByIndex(idx)
    if not ZeD.MapNotes.canModify(sym) then return end
    if isClient() and sym:isShared() and not sym:isText() then
        api:sendRemoveSymbol(sym)
    else
        api:removeSymbolByIndex(idx)
    end
    sweep.hit = true
end

-- one frame of erasing: rings around the pointer along the path since the
-- last frame (WorldMapSymbolTool_FreeHandEraser:render)
local function eraseSweep(mp, win, x, y)
    local s = st(win)
    local sweep = { hit = false }
    eraseAt(mp, x, y, sweep)
    local steps, px, py = 1, 0, 0
    if s.prevX then
        local dx, dy = x - s.prevX, y - s.prevY
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 10 then steps = math.min(5, math.ceil(math.sqrt(d / 3))) end
        px, py = dx / steps, dy / steps
    end
    local sx, sy = s.prevX or x, s.prevY or y
    local k = ZeD.T.px(1)
    for p = 1, steps do
        local x2, y2 = sx + px * p, sy + py * p
        local spread, rot = 2 * k, 0
        for _ = 1, 2 do
            for a = 0, 7 do
                local ang = rot + a * math.pi / 4
                eraseAt(mp, x2 + math.cos(ang) * spread, y2 + math.sin(ang) * spread, sweep)
            end
            spread = spread + 4 * k
            rot = rot + math.pi / 2
        end
    end
    s.prevX, s.prevY = x, y
    local now = getTimestampMs()
    if sweep.hit and win._playerObj and now - (s.eraseSound or 0) > 150 then
        s.eraseSound = now
        win._playerObj:playSoundLocal("MapRemoveMarking")
    end
end

-- ---------------------------------------------------------------------------
-- THE EXTENSION
-- ---------------------------------------------------------------------------
local X = { order = 20 }
local _pencil = nil

function X.button(win)
    if not _pencil then _pencil = getTexture("media/textures/ZeD/icons/edit.png") end
    local s = st(win)
    return { id = "draw", text = word("UI_DrawOnMap_Draw"), icon = _pencil, on = s.open,
        help = ZeD.tr("UI_ZeD_Map_HelpDraw"),
        activate = function(w)
            local s2 = st(w)
            s2.open = not s2.open
            if not s2.open then s2.tool = nil end
        end }
end

-- the second row: the mod's tools and sliders
function X.row(win)
    local s = st(win)
    if not s.open then return nil end
    return { h = 32, draw = function(ctx)
        local ink = ZeD.MapsTab.ink(win)
        if not ctx.narrow then ctx:label(word("UI_DrawOnMap_Draw")) end
        -- (a greyed tool's hint is the game's reason: the help line says it)
        local function tool(id, key, helpKey)
            local ok, why = allowed(win, id)
            ctx:button("draw:" .. id, word(key), { on = s.tool == id, dim = not ok,
                hint = (not ok) and ZeD.tr(why) or nil, help = ZeD.tr(helpKey),
                activate = function(w) S.arm(w, id) end })
        end
        tool("draw", "UI_DrawOnMap_Draw", "UI_ZeD_Map_HelpDrawFree")
        tool("line", "UI_DrawOnMap_Line", "UI_ZeD_Map_HelpDrawLine")
        tool("erase", "UI_DrawOnMap_Erase", "UI_ZeD_Map_HelpDrawErase")
        ctx:gap(4)
        local sw = ctx.narrow and 56 or 90
        ctx:text(word("UI_DrawOnMap_Thickness"), true)
        ctx:slider("draw:thick", { w = sw, min = SIZE_MIN, max = SIZE_MAX, step = SIZE_STEP, tick = SIZE_DEFAULT,
            get = function() return s.thick end, set = function(v) s.thick = v end,
            fmt = function(v) return string.format("%.1f", v) end, help = ZeD.tr("UI_ZeD_Map_HelpThickness") })
        ctx:text(word("UI_DrawOnMap_Fill"), true)
        ctx:slider("draw:fill", { w = sw, min = FILL_MIN, max = FILL_MAX, step = FILL_STEP, tick = FILL_DEFAULT,
            get = function() return s.fill end, set = function(v) s.fill = v end,
            fmt = function(v) return tostring(math.floor(v * 100 + 0.5)) .. "%" end, help = ZeD.tr("UI_ZeD_Map_HelpFill") })
        if not ctx.narrow and ink.write then
            local _, idx = ZeD.MapsTab.inkColor(win)
            local k = idx and ZeD.MapNotes.INKS[idx]
            if k then ctx:text(ZeD.tr("UI_ZeD_Map_DrawInk", getItemNameFromFullType("Base." .. k.item) or k.item), true) end
        end
    end }
end

function X.armed(win)
    local s = win._zedDraw
    if not (s and s.tool) then return false end
    -- the pen or eraser put away: the tool goes down (the mod's checkInventory)
    if not allowed(win, s.tool) then s.tool = nil; s.stroke = nil; return false end
    return true
end

function X.putDown(win)
    local s = win._zedDraw
    if s then s.tool, s.stroke, s.erasing = nil, nil, nil end
end

local function press(mp, win, x, y)
    local s = st(win)
    local wx, wy = mp.mapAPI:uiToWorldX(x, y), mp.mapAPI:uiToWorldY(x, y)
    if s.tool == "draw" then
        s.stroke = { wx = wx, wy = wy }
        addDot(win, wx, wy, true)
    elseif s.tool == "line" then
        s.stroke = { wx = wx, wy = wy, line = true }
    elseif s.tool == "erase" then
        s.erasing, s.prevX, s.prevY = true, nil, nil
    end
    return true
end

local function move(mp, win, x, y)
    local s = st(win)
    if s.tool == "draw" and s.stroke then
        drawTo(win, mp.mapAPI:uiToWorldX(x, y), mp.mapAPI:uiToWorldY(x, y), s.stroke)
    end
end

local function release(mp, win, x, y)
    local s = st(win)
    if s.stroke and (s.tool == "draw" or s.tool == "line") then
        local first = s.stroke.line
        drawTo(win, mp.mapAPI:uiToWorldX(x, y), mp.mapAPI:uiToWorldY(x, y), s.stroke)
        if first and win._playerObj then win._playerObj:playSoundLocal("MapAddSymbol") end
    end
    s.stroke, s.erasing, s.prevX, s.prevY = nil, nil, nil, nil
end

function X.mouseDown(mp, win, x, y) return press(mp, win, x, y) end
function X.mouseMove(mp, win, x, y) move(mp, win, x, y) end
function X.mouseUp(mp, win, x, y) release(mp, win, x, y) end

function X.padA(mp, win, x, y, phase)
    if phase == "down" then press(mp, win, x, y)
    elseif phase == "hold" then move(mp, win, x, y)
    else release(mp, win, x, y) end
end

-- erasing runs every frame while held (as the mod's eraser renders)
function X.drawMap(mp, win)
    local s = win._zedDraw
    if not (s and s.erasing and s.tool == "erase") then return end
    if not mp._gpCursorLive and not isMouseButtonDown(0) then s.erasing = nil; return end
    local x, y = ZeD.MapsTabExt.pointer(mp)
    eraseSweep(mp, win, x, y)
end

-- the preview: the mod's dot at the pointer, the line while it is pulled out,
-- a ring for the eraser
local _dot = nil
function X.cursor(mp, win, x, y)
    local s = st(win)
    local T = ZeD.T
    if s.tool == "erase" then
        -- the eraser's ring, a 1u line in the text colour
        local r = T.px(10)
        ZeD.Atoms.frame(mp, x - r, y - r, r * 2, r * 2, T.text)
        return
    end
    if not _dot then _dot = getTexture(DOT_PATH) end
    local c = ZeD.MapsTab.inkColor(win)
    if not (_dot and c) then return end
    local sz = math.max(2, _dot:getWidth() * s.thick * scale() * 0.1 * mp.mapAPI:getWorldScale())
    local function dot(px, py) mp:drawTextureScaledAspect(_dot, px - sz / 2, py - sz / 2, sz, sz, 1, c.r, c.g, c.b) end
    if s.tool == "line" and s.stroke then
        local x0 = mp.mapAPI:worldToUIX(s.stroke.wx, s.stroke.wy)
        local y0 = mp.mapAPI:worldToUIY(s.stroke.wx, s.stroke.wy)
        for i = 0, 20 do dot(x0 + (x - x0) * i / 20, y0 + (y - y0) * i / 20) end
    else
        dot(x, y)
    end
end

S.X = X   -- (the QA scripts drive it)
ZeD.MapsTab.addExtension(MOD_ID, X)
