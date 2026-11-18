-- ZeD-UI/42/media/lua/client/ZeD/MapsTabKey.lua
-- ============================================================================
-- THE MAP KEY -- client. The game's own map key (ISWorldMapKey: its eight
-- uses of a building, in its words, IGUI_Map_<use>, and its pictures,
-- Key_<use>.png, the colour-blind patterns when that option is on), which
-- ZeD's map lost when it replaced the game's map. Built into ZeD, mod or no
-- mod (Map Legend UI shows the same eight, so with it on ZeD shows nothing
-- more).
--
-- A Key button on the Maps card's band (its right) opens it as a small panel
-- over the map's
-- bottom-left corner. The key belongs to the Survey map, whose buildings are
-- coloured by use; on Color and Paper the panel says those maps show the ground
-- as it looks, and offers Survey. Through the Maps tab's general hook
-- (MapsTabExt.lua, ZeD.MapsTab.addExtension).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/MapsTab"

ZeD = ZeD or {}

-- the game's eight, in the game's order (ISWorldMapKey:new)
local KEYS = { "Community", "Hospitality", "Industrial", "Medical", "Parks", "Residential",
               "RestaurantsEntertainment", "RetailCommercial" }
-- the three colours on the button (Residential, Community, Retail & Commercial)
local BTN = { { 225, 176, 126 }, { 139, 117, 235 }, { 184, 205, 84 } }

local K = { order = 10, paper = true }   -- (vanilla's paper map has its Map key too: ISMap)

local function keyTex(name)
    local path = "media/textures/worldMap/"
    if getCore():getOptionColorblindPatterns() then path = path .. "Colorblind Patterns/" end
    return getTexture(path .. "Key_" .. name .. ".png")
end

function K.button(win)
    return {
        id = "key",
        text = ZeD.tr("UI_ZeD_Map_KeyButton"),
        hint = ZeD.tr("IGUI_Map_Key"),
        help = ZeD.tr("UI_ZeD_Map_HelpKey"),
        on = win._mapKeyOpen == true,
        glyph = function(panel, x, y, s, c)
            local T = ZeD.T
            local bw = math.max(1, math.floor(s / 4))
            local bh = math.floor(s * 0.7)
            -- (Survey's own colours since Nov 18 2026, MapsSurvey.lua: a highway's red, a home's, a store's)
            local S = ZeD.MapsSurvey
            local pal = S and S.palette()
            local cols = BTN
            if pal then
                local function c(h) local r, g, b = S.rgb(h); return { r, g, b } end
                cols = { c(pal.main), c(pal.b.Residential), c(pal.b.RetailAndCommercial) }
            end
            for i, k in ipairs(cols) do
                panel:drawRect(x + (i - 1) * (bw + T.px(1)) + math.floor(s * 0.15), y + math.floor((s - bh) / 2), bw, bh, 1, k[1] / 255, k[2] / 255, k[3] / 255)
            end
        end,
        activate = function(w) w._mapKeyOpen = not w._mapKeyOpen end,
    }
end

local FOCUS = {}           -- the controller's mark opts (its window: the panel's)
local _surveyOpts = {}

-- The panel's bar, as a ZeD window's title bar: surface 2, the stripes broken
-- behind the close box and the title, the close box at the left, the title in
-- the title bar's face, a structure line under it. Adds the close box's zone.
local function drawBar(mp, x, y, w, headH, focId, zones, ox, oy)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    A.surfaceFill(mp, x, y, w, headH, "surf2")
    local f3 = T.fontF3
    local title = ZeD.tr("IGUI_Map_Key")
    local tw = tm:MeasureStringX(f3, title)
    local tx = x + math.floor((w - tw) / 2)
    local cb = T.closeBoxSz
    local cbx, cby = x + T.px(6), y + math.floor((headH - cb) / 2)
    local st = T.stripe
    if st and (st.a or 0) > 0 then
        local g1, g2 = cbx + cb + T.px(4), tx - T.px(6)
        local g3, g4 = tx + tw + T.px(6), x + w - T.px(2)
        for sy = y + T.px(3), y + headH - T.px(3), T.px(4) do
            if g2 > g1 then mp:drawRect(g1, sy, g2 - g1, T.hair, st.a, st.r, st.g, st.b) end
            if g4 > g3 then mp:drawRect(g3, sy, g4 - g3, T.hair, st.a, st.r, st.g, st.b) end
        end
    end
    local th = T.textHead
    mp:drawText(title, tx, y + math.floor((headH - tm:getFontHeight(f3)) / 2), th.r, th.g, th.b, th.a or 1, f3)
    local zx, zy, zs = cbx - T.px(2), cby - T.px(2), cb + T.px(4)
    local hover = A.mouseIn(mp, zx, zy, zs, zs)
    if hover then ZeD.Help.set(mp, ZeD.tr("UI_ZeD_Map_HelpKeyClose")) end
    if focId == "map:key:close" then ZeD.Focus.mark(mp, zx, zy, zs, zs, FOCUS) end
    A.drawCloseBox(mp, cbx, cby, cb, hover)
    A.drawDividerH(mp, x, y + headH - T.line(T.borderW), w, true)
    zones[#zones + 1] = { id = "map:key:close", x = zx + ox, y = zy + oy, w = zs, h = zs,
        activate = function(w2) w2._mapKeyOpen = false end }
end

-- SURVEY'S KEY (Nov 18 2026, the director's paper-map look, MapsSurvey.lua): two pages laid out as a printed symbol
-- sheet, Colors (roads, water and woodland, buildings by use) and Symbols (places, the map's marks), each in two
-- columns under ruled section heads. The page buttons sit at the body's top.
local _pageOpts = {}
local function surveyBody(mp, win, x, y, w, focId, zones, ox, oy, measureOnly, capCol)
    local T, tm, A, S = ZeD.T, ZeD.TM, ZeD.Atoms, ZeD.MapsSurvey
    local f1, f2 = T.fontF1, T.fontF2
    local h1, h2 = tm:getFontHeight(f1), tm:getFontHeight(f2)
    local page = win._mapKeyPage == "symbols" and "symbols" or "colors"
    local rows = page == "symbols" and S.keySymbols() or S.keyColors()
    local pad = T.px(8)
    local rowH = math.max(T.px(15), h2 + T.px(2))
    local secH = h1 + T.px(6)
    local function hOf(r) return r.sec and secH or rowH end
    local function colH(a, b)
        local hh = 0
        for i = a, b do hh = hh + hOf(rows[i]) end
        return hh
    end
    -- the columns. Two, split where the first passes half, while they fit the map; else (QA's release test, Nov 18
    -- 2026: Symbols ran 557 px tall on a 456 px map at 4K) filled to the height that fits, up to three. A section's
    -- head never ends a column.
    local total = colH(1, #rows)
    local split, acc = #rows, 0
    for i, r in ipairs(rows) do
        acc = acc + hOf(r)
        if acc >= total / 2 then split = i; break end
    end
    if rows[split + 1] and rows[split + 1].sec == nil and rows[split] and rows[split].sec then split = split - 1 end
    local cols = { { 1, split }, { split + 1, #rows } }
    if capCol and math.max(colH(1, split), colH(split + 1, #rows)) > capCol then
        cols = {}
        local a, hh = 1, 0
        for i = 1, #rows do
            local rh = hOf(rows[i])
            if hh + rh > capCol and i > a and #cols < 2 then
                local b = i - 1
                if rows[b].sec and b > a then b = b - 1 end   -- (a head moves down with its first row)
                cols[#cols + 1] = { a, b }
                a = b + 1
                hh = colH(a, i)
            else
                hh = hh + rh
            end
        end
        cols[#cols + 1] = { a, #rows }
    end
    local tallest = 0
    for _, c in ipairs(cols) do tallest = math.max(tallest, colH(c[1], c[2])) end
    local btnH = T.buttonH
    local bodyH = pad + btnH + pad + tallest + pad
    if measureOnly then return bodyH, #cols end
    -- the page buttons
    local M = ZeD.Molecules
    local bx = x + pad
    for _, pg in ipairs({ { "colors", "UI_ZeD_MapKey_PageColors" }, { "symbols", "UI_ZeD_MapKey_PageSymbols" } }) do
        local label = ZeD.tr(pg[2])
        local bw = M.buttonW(label)
        local id = "map:key:page:" .. pg[1]
        local o = _pageOpts[pg[1]] or {}
        _pageOpts[pg[1]] = o
        o.hover = A.mouseIn(mp, bx, y + pad, bw, btnH)
        o.focus = (focId == id) and FOCUS or nil
        M.drawButton(mp, bx, y + pad, bw, btnH, label, page == pg[1] and "primary" or "default", false, nil, o)
        local which = pg[1]
        zones[#zones + 1] = { id = id, x = bx + ox, y = y + pad + oy, w = bw, h = btnH,
            activate = function(w2) w2._mapKeyPage = which end }
        bx = bx + bw + T.px(6)
    end
    -- the columns
    local colW = math.floor((w - pad * (#cols + 1)) / #cols)
    local tc, th = T.text, T.text
    local sw, sh = T.px(22), T.px(11)
    local function column(a, b, cx, cy)
        for i = a, b do
            local r = rows[i]
            if r.sec then
                mp:drawRect(cx, cy + T.px(2), colW, T.line(2), 1, th.r, th.g, th.b)
                mp:drawText(string.upper(ZeD.tr(r.sec)), cx, cy + T.px(4), th.r, th.g, th.b, th.a or 1, f1)
                cy = cy + secH
            else
                local sy = cy + math.floor((rowH - sh) / 2)
                if r.swatch then
                    local cr, cg, cb = S.rgb(r.swatch)
                    if r.line then
                        local lh = T.px(r.line + 1)
                        mp:drawRect(cx, cy + math.floor((rowH - lh) / 2), sw, lh, 1, cr / 255, cg / 255, cb / 255)
                        if r.ties then
                            for tx = cx + T.px(2), cx + sw - T.px(2), T.px(5) do
                                mp:drawRect(tx, cy + math.floor(rowH / 2) - T.px(3), 1, T.px(6), 1, cr / 255, cg / 255, cb / 255)
                            end
                        end
                    else
                        mp:drawRect(cx, sy, sw, sh, 1, cr / 255, cg / 255, cb / 255)
                        if r.woods then
                            local t = getTexture("media/textures/ZeD/map/woods_" .. (S.key()) .. ".png")
                            if t then mp:drawTextureScaled(t, cx, sy, sw, sh, 1, 1, 1, 1) end
                        end
                        A.frame(mp, cx, sy, sw, sh, T.borderS)
                    end
                else
                    local s = math.min(rowH - T.px(2), sw)
                    S.drawKeySymbol(mp, r, cx + math.floor((sw - s) / 2), cy + math.floor((rowH - s) / 2), s)
                end
                local maxW = colW - sw - T.px(6)
                mp:drawText(A.truncateText(r.text or "", f2, maxW), cx + sw + T.px(6), cy + math.floor((rowH - h2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
                cy = cy + rowH
            end
        end
    end
    local top = y + pad + btnH + pad
    for i, c in ipairs(cols) do column(c[1], c[2], x + pad * i + colW * (i - 1), top) end
    return bodyH
end

-- the panel over the map's bottom-left corner; its controls as zones
function K.overlay(mp, win, ox, oy, focId)
    if not win._mapKeyOpen then return nil end
    if (mp.style or "survey") == "survey" and ZeD.MapsSurvey and not mp._paperItem then
        local T, A = ZeD.T, ZeD.Atoms
        local w = math.min(T.px(440), mp:getWidth() - T.px(16))
        local headH = T.px(20)
        local zones = {}
        -- the most a column may take: the map's height less the panel's head, its page buttons and pads
        local capCol = mp:getHeight() - T.px(12) - headH - (T.px(8) * 3 + T.buttonH)
        local bodyH, ncols = surveyBody(mp, win, 0, 0, w, focId, zones, ox, oy, true, capCol)
        if ncols > 2 then w = math.max(w, mp:getWidth() - T.px(16)) end   -- (three columns: the map's width)
        local h = headH + bodyH
        local x = T.px(8)
        local y = math.max(T.px(4), mp:getHeight() - h - T.px(8))
        drawBar(mp, x, y, w, headH, focId, zones, ox, oy)
        A.surfaceFill(mp, x, y + headH, w, h - headH, "surf1")
        surveyBody(mp, win, x, y + headH, w, focId, zones, ox, oy, false, capCol)
        A.frame(mp, x, y, w, h, T.borderS)
        zones[#zones + 1] = { id = "map:key:panel", x = x + ox, y = y + oy, w = w, h = h, inert = true }
        return zones
    end
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local f2 = T.fontF2
    local h2 = tm:getFontHeight(f2)
    local style = mp.style or "survey"
    local w = T.px(226)
    local headH = T.px(20)
    local rowH = math.max(T.px(17), h2 + T.px(3))
    local bodyH, lines
    if style == "survey" then
        bodyH = T.px(13) + #KEYS * (rowH + T.px(3))
    else
        lines = A.wrapText(ZeD.tr(style == "color" and "UI_ZeD_Map_KeyColor" or "UI_ZeD_Map_KeyPaper"), f2, w - T.px(16))
        bodyH = T.px(14) + #lines * (h2 + T.px(2)) + T.px(10) + T.buttonH + T.px(8)
    end
    local h = headH + bodyH
    local x = T.px(8)
    local y = mp:getHeight() - h - T.px(8)
    local zones = {}
    -- the panel's surfaces, each one layer of the window's (ZeD.Surface): the bar's, then the body's under it
    drawBar(mp, x, y, w, headH, focId, zones, ox, oy)
    A.surfaceFill(mp, x, y + headH, w, h - headH, "surf1")
    -- the body
    local by = y + headH + T.px(7)
    if style == "survey" then
        local sw, sh = T.px(22), T.px(11)
        local tc = T.text
        for _, k in ipairs(KEYS) do
            local tex = keyTex(k)
            local sy = by + math.floor((rowH - sh) / 2)
            if tex then mp:drawTextureScaledAspect(tex, x + T.px(8), sy, sw, sh, 1, 1, 1, 1) end
            A.frame(mp, x + T.px(8), sy, sw, sh, T.borderS)
            mp:drawText(ZeD.tr("IGUI_Map_" .. k), x + T.px(8) + sw + T.px(8), by + math.floor((rowH - h2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            by = by + rowH + T.px(3)
        end
    else
        local ts = T.textSec
        for _, l in ipairs(lines) do
            mp:drawText(l, x + T.px(8), by, ts.r, ts.g, ts.b, ts.a or 1, f2)
            by = by + h2 + T.px(2)
        end
        -- Show survey: a push button
        local label = ZeD.tr("UI_ZeD_Map_ShowSurvey")
        local M = ZeD.Molecules
        local bw, bh = M.buttonW(label), T.buttonH
        local bx, byy = x + T.px(8), by + T.px(8)
        local o = _surveyOpts
        o.hover = A.mouseIn(mp, bx, byy, bw, bh)
        o.focus = (focId == "map:key:survey") and FOCUS or nil
        o.help = o.hover and ZeD.tr("UI_ZeD_Map_HelpStyleSurvey") or nil
        M.drawButton(mp, bx, byy, bw, bh, label, "default", false, nil, o)
        zones[#zones + 1] = { id = "map:key:survey", x = bx + ox, y = byy + oy, w = bw, h = bh,
            activate = function(w2) ZeD.MapsTab.setStyle(w2, "survey") end }
    end
    -- the panel's frame, last: nothing inside covers it
    A.frame(mp, x, y, w, h, T.borderS)
    -- the rest of the panel is the key's (a click on it does not reach the map)
    zones[#zones + 1] = { id = "map:key:panel", x = x + ox, y = y + oy, w = w, h = h, inert = true }
    return zones
end

ZeD.MapsTab.addExtension("key", K)
