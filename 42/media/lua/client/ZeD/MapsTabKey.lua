-- ZeD-UI/42/media/lua/client/ZeD/MapsTabKey.lua
-- ============================================================================
-- THE MAP KEY (Oct 26 2026; mockup zed_map_overlays_v1, approved "as
-- recommended"). The game's own map key (ISWorldMapKey: its eight uses of a
-- building, in its words, IGUI_Map_<use>, and its pictures, Key_<use>.png, the
-- colour-blind patterns when that option is on), which ZeD's map lost when it
-- replaced the game's map. Built into ZeD, mod or no mod (Map Legend UI shows
-- the same eight, so with it on ZeD shows nothing more).
--
-- A Key button on the Maps toolbar opens it as a small panel over the map's
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

local K = { order = 10 }

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
            for i, k in ipairs(BTN) do
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

-- the panel over the map's bottom-left corner; its controls as zones
function K.overlay(mp, win, ox, oy, focId)
    if not win._mapKeyOpen then return nil end
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
