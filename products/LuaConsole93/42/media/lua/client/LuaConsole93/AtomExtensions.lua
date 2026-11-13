-- LuaConsole93/42/media/lua/client/LuaConsole93/AtomExtensions.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's AtomExtensions.lua the console uses (28
-- of its 51 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/AtomExtensions.lua by
-- ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change ZeD-GUI's file and build again.
-- ============================================================================================================

-- With ZeD-GUI on (mod ZeD_UI; the game can put a backslash before a mod's id), ZeD-GUI's console is the one:
-- this file stops here and defines nothing.
do
    local guiOn = false
    pcall(function()
        local mods = getActivatedMods()
        for i = 0, mods:size() - 1 do
            if string.gsub(tostring(mods:get(i)), "^\\", "") == "ZeD_UI" then guiOn = true end
        end
    end)
    if guiOn then return end
end

LC93 = LC93 or {}
LC93.Atoms = LC93.Atoms or {}

local ROUND_RADIUS = {2, 1}

function LC93.Atoms.fillRounded(panel, x, y, w, h, r, g, b, a)
    local u = LC93.T.hair
    for i, inset in ipairs(ROUND_RADIUS) do
        local ix = inset * u
        panel:drawRect(x + ix, y + (i - 1) * u, w - ix * 2, u, a, r, g, b)
        panel:drawRect(x + ix, y + h - i * u, w - ix * 2, u, a, r, g, b)
    end
    local midTop = #ROUND_RADIUS * u
    local midH   = h - midTop * 2
    if midH > 0 then
        panel:drawRect(x, y + midTop, w, midH, a, r, g, b)
    end
end

function LC93.Atoms.borderRounded(panel, x, y, w, h, r, g, b, a)
    local u = LC93.T.hair
    for i, inset in ipairs(ROUND_RADIUS) do
        local row = i - 1
        local ix = inset * u
        panel:drawRect(x + ix, y + row * u,           w - ix * 2, u, a, r, g, b)
        panel:drawRect(x + ix, y + h - (row + 1) * u, w - ix * 2, u, a, r, g, b)
    end
    local midTop = #ROUND_RADIUS * u
    local midH   = h - midTop * 2
    if midH > 0 then
        panel:drawRect(x,         y + midTop, u, midH, a, r, g, b)
        panel:drawRect(x + w - u, y + midTop, u, midH, a, r, g, b)
    end
end

function LC93.Atoms.borderDoubleRounded(panel, x, y, w, h, r, g, b, a)
    local u = LC93.T.hair
    LC93.Atoms.borderRounded(panel, x, y, w, h, r, g, b, a)
    LC93.Atoms.borderRounded(panel, x + 2 * u, y + 3 * u, w - 4 * u, h - 6 * u, r, g, b, a)
end

local _arrowRows = {}
local function _arrowOffsets(s)
    local rows = _arrowRows[s]
    if rows then return rows end
    local t = math.max(1, math.floor(s / 6 + 0.5))
    local half = math.floor(s / 2)
    local w = half + t
    local ox = math.floor((s - w) / 2)
    rows = { t = t, fwd = {}, back = {} }
    for row = 0, s - 1 do
        local e = math.floor(math.abs(row - (s - 1) / 2))
        local p = math.max(0, half - e)
        rows.fwd[row + 1] = ox + p
        rows.back[row + 1] = ox + (w - t - p)
    end
    _arrowRows[s] = rows
    return rows
end

local SEARCH_MAP = {
    ".XXXX....",
    "X....X...",
    "X....X...",
    "X....X...",
    "X....X...",
    ".XXXX....",
    "......XX.",
    ".......XX",
    "........X",
}
local SEARCH_N = 9
local _searchRuns
local function _searchRunsOf()
    if _searchRuns then return _searchRuns end
    _searchRuns = {}
    for r = 1, SEARCH_N do
        local row, runs, c = SEARCH_MAP[r], {}, 1
        while c <= SEARCH_N do
            if string.sub(row, c, c) == "X" then
                local e = c
                while e < SEARCH_N and string.sub(row, e + 1, e + 1) == "X" do e = e + 1 end
                runs[#runs + 1] = c - 1
                runs[#runs + 1] = e - c + 1
                c = e + 1
            else
                c = c + 1
            end
        end
        _searchRuns[r] = runs
    end
    return _searchRuns
end

function LC93.Atoms.drawSearchIcon(panel, x, y, h, color)
    local T = LC93.T
    local c = color or T.textDim
    local cell = math.max(1, math.floor(T.px(1) + 0.5))
    local size = SEARCH_N * cell
    local oy = y + math.floor((h - size) / 2)
    local a = c.a or 1
    local rows = _searchRunsOf()
    for r = 1, SEARCH_N do
        local runs = rows[r]
        for i = 1, #runs, 2 do
            panel:drawRect(x + runs[i] * cell, oy + (r - 1) * cell, runs[i + 1] * cell, cell, a, c.r, c.g, c.b)
        end
    end
    return size
end

function LC93.Atoms.drawPxMap(panel, map, x, y, cell, color)
    local runs = map._runs
    if not runs then
        runs = {}
        for r = 1, #map do
            local row, out, c, n = map[r], {}, 1, #map[r]
            while c <= n do
                if string.sub(row, c, c) == "X" then
                    local e = c
                    while e < n and string.sub(row, e + 1, e + 1) == "X" do e = e + 1 end
                    out[#out + 1] = c - 1
                    out[#out + 1] = e - c + 1
                    c = e + 1
                else
                    c = c + 1
                end
            end
            runs[r] = out
        end
        map._runs = runs
    end
    local c = color or LC93.T.text
    local a = c.a or 1
    for r = 1, #runs do
        local rr = runs[r]
        for i = 1, #rr, 2 do
            panel:drawRect(x + rr[i] * cell, y + (r - 1) * cell, rr[i + 1] * cell, cell, a, c.r, c.g, c.b)
        end
    end
    return #(map[1] or "") * cell, #map * cell
end

local LINE_DIR = "media/textures/LuaConsole93/lines/"
local _lineTex = {}
function LC93.Atoms.lineTex(name)
    local t = _lineTex[name]
    if t == nil then
        t = (Texture and Texture.getSharedTexture(LINE_DIR .. name .. ".png", 3)) or false
        _lineTex[name] = t
    end
    return t or nil
end

function LC93.Atoms.lineJo(panel)
    if panel.isCollapsed then return nil end
    local dr = panel.drawRect
    local L, UI = LC93.LeanDraw, ISUIElement
    if not ((L and dr == L.drawRect) or (UI and dr == UI.drawRect)) then return nil end
    return panel.javaObject
end

local CHEV_MAX = 40
local _chevY = {}
do
    local y = 0
    for s = 2, CHEV_MAX do _chevY[s] = y; y = y + s + 1 end
end
local CHEV_COL = { rt = 0, lf = 1, dn = 2 }

local function _drawArrow(panel, name, x, y, size, color)
    local c = color or LC93.T.textDim
    local s = math.floor(size)
    if s < 2 then return end
    local a, r, g, b = c.a or 1, c.r, c.g, c.b
    if s <= CHEV_MAX then
        local jo = LC93.Atoms.lineJo(panel)
        local tex = jo and LC93.Atoms.lineTex("chev")
        if tex then
            jo:DrawSubTextureRGBA(tex, (CHEV_COL[name] or 3) * (s + 1), _chevY[s], s, s, x, y, s, s, r, g, b, a)
            return
        end
    end
    local rows = _arrowOffsets(s)
    local t = rows.t
    if name == "rt" then
        local off = rows.fwd
        for row = 0, s - 1 do panel:drawRect(x + off[row + 1], y + row, t, 1, a, r, g, b) end
    elseif name == "lf" then
        local off = rows.back
        for row = 0, s - 1 do panel:drawRect(x + off[row + 1], y + row, t, 1, a, r, g, b) end
    elseif name == "dn" then
        local off = rows.fwd
        for row = 0, s - 1 do panel:drawRect(x + row, y + off[row + 1], 1, t, a, r, g, b) end
    else
        local off = rows.back
        for row = 0, s - 1 do panel:drawRect(x + row, y + off[row + 1], 1, t, a, r, g, b) end
    end
end

function LC93.Atoms.drawTriangleRight(panel, x, y, size, color)
    _drawArrow(panel, "rt", x, y, size, color)
end

function LC93.Atoms.drawTriangleDown(panel, x, y, size, color)
    _drawArrow(panel, "dn", x, y, size, color)
end

function LC93.Atoms.drawResizeRidges(panel, x, y, size)
    local T = LC93.T
    local lt = T.textDim
    local dk = T.base
    local u = T.px(1)
    for i = 0, 2 do
        local offset = T.px(i * 4)
        local x1 = x + size - T.px(4) - offset
        local y1 = y + size - T.px(2)
        local x2 = x + size - T.px(2)
        local y2 = y + size - T.px(4) - offset
        local steps = math.floor(math.max(math.abs(x2 - x1), math.abs(y2 - y1)) / u)
        if steps > 0 then
            for s = 0, steps do
                local px = x1 + math.floor((x2 - x1) * s / steps)
                local py = y1 + math.floor((y2 - y1) * s / steps)
                panel:drawRect(px, py, u, u, T.ridgeLightA, lt.r, lt.g, lt.b)
            end
            for s = 0, steps do
                local px = x1 + math.floor((x2 - x1) * s / steps) + u
                local py = y1 + math.floor((y2 - y1) * s / steps) + u
                if px < x + size - u and py < y + size - u then
                    panel:drawRect(px, py, u, u, T.ridgeDarkA, dk.r, dk.g, dk.b)
                end
            end
        end
    end
end

function LC93.Atoms.drawGrowBox(panel, x, y, size)
    local T = LC93.T
    local bg = T.surf2
    panel:drawRect(x, y, size, size, bg.a, bg.r, bg.g, bg.b)
    panel:drawRectBorder(x, y, size, size, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    LC93.Atoms.drawResizeRidges(panel, x, y, size)
end

function LC93.Atoms.drawCloseBox(panel, x, y, size, hovered)
    local T = LC93.T
    local bg = T.surf2
    panel:drawRect(x, y, size, size, 1, bg.r, bg.g, bg.b)
    if hovered then panel:drawRect(x, y, size, size, T.hover.a, T.hover.r, T.hover.g, T.hover.b) end
    panel:drawRectBorder(x, y, size, size, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    local m = math.max(T.px(3), math.floor(size * 0.25))
    local tc = T.textDim
    local u = T.px(1)
    for i = 0, size - m * 2 - u, u do
        local px = x + m + i
        panel:drawRect(px, y + m + i, u, u, tc.a, tc.r, tc.g, tc.b)
        panel:drawRect(px, y + size - m - u - i, u, u, tc.a, tc.r, tc.g, tc.b)
    end
end
