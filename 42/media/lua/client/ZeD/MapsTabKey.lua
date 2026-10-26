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

-- the panel over the map's bottom-left corner; its controls as zones
function K.overlay(mp, win, ox, oy, focId)
    if not win._mapKeyOpen then return nil end
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local f1, f2 = T.fontF1, T.fontF2
    local h1, h2 = tm:getFontHeight(f1), tm:getFontHeight(f2)
    local style = mp.style or "survey"
    local w = T.px(226)
    local headH = T.px(20)
    local rowH = math.max(T.px(17), h2 + T.px(3))
    local bodyH, lines
    if style == "survey" then
        bodyH = T.px(13) + #KEYS * (rowH + T.px(3))
    else
        lines = A.wrapText(ZeD.tr(style == "color" and "UI_ZeD_Map_KeyColor" or "UI_ZeD_Map_KeyPaper"), f1, w - T.px(16))
        bodyH = T.px(14) + #lines * (h1 + T.px(2)) + T.px(30)
    end
    local h = headH + bodyH
    local x = T.px(8)
    local y = mp:getHeight() - h - T.px(8)
    local zones = {}
    local s1, s2, bs, th = T.surf1, T.surf2, T.borderS, T.textHead
    mp:drawRect(x, y, w, h, 0.94, s1.r, s1.g, s1.b)
    mp:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    -- the bar: stripes, a close box, the title
    mp:drawRect(x + T.px(1), y + T.px(1), w - T.px(2), headH - T.px(1), 1, s2.r, s2.g, s2.b)
    for sy = y + T.px(3), y + headH - T.px(3), T.px(4) do
        mp:drawRect(x + T.px(2), sy, w - T.px(4), T.px(1), 0.05, 1, 1, 1)
    end
    mp:drawRect(x, y + headH, w, T.px(1), bs.a, bs.r, bs.g, bs.b)
    local title = ZeD.tr("IGUI_Map_Key")
    local tw = tm:MeasureStringX(f1, title)
    local tx = x + math.floor((w - tw) / 2)
    mp:drawRect(tx - T.px(6), y + T.px(2), tw + T.px(12), headH - T.px(3), 1, s2.r, s2.g, s2.b)
    mp:drawText(title, tx, y + math.floor((headH - h1) / 2), th.r, th.g, th.b, th.a or 1, f1)
    local cb = T.px(10)
    local cbx, cby = x + T.px(6), y + math.floor((headH - cb) / 2)
    mp:drawRect(cbx - T.px(2), cby - T.px(1), cb + T.px(4), cb + T.px(2), 1, s2.r, s2.g, s2.b)
    if focId == "map:key:close" then
        local ac = T.accent
        mp:drawRect(cbx - T.px(2), cby - T.px(2), cb + T.px(4), cb + T.px(4), 0.55, ac.r, ac.g, ac.b)
    end
    A.drawCloseBox(mp, cbx, cby, cb, false)
    zones[#zones + 1] = { id = "map:key:close", x = cbx - T.px(2) + ox, y = cby - T.px(2) + oy, w = cb + T.px(4), h = cb + T.px(4),
        activate = function(w2) w2._mapKeyOpen = false end }
    -- the body
    local by = y + headH + T.px(7)
    local tc = T.text
    if style == "survey" then
        local sw, sh = T.px(22), T.px(11)
        for _, k in ipairs(KEYS) do
            local tex = keyTex(k)
            local sy = by + math.floor((rowH - sh) / 2)
            if tex then mp:drawTextureScaledAspect(tex, x + T.px(8), sy, sw, sh, 1, 1, 1, 1) end
            mp:drawRectBorder(x + T.px(8), sy, sw, sh, 0.6, 0, 0, 0)
            mp:drawText(ZeD.tr("IGUI_Map_" .. k), x + T.px(8) + sw + T.px(8), by + math.floor((rowH - h2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            by = by + rowH + T.px(3)
        end
    else
        local ts = T.textSec
        for _, l in ipairs(lines) do
            mp:drawText(l, x + T.px(8), by, ts.r, ts.g, ts.b, ts.a or 1, f1)
            by = by + h1 + T.px(2)
        end
        local label = ZeD.btnCase(ZeD.tr("UI_ZeD_Map_ShowSurvey"))
        local bw, bh = tm:MeasureStringX(f1, label) + T.px(14), T.px(20)
        local bx, byy = x + T.px(8), by + T.px(5)
        if focId == "map:key:survey" then
            local ac = T.accent
            mp:drawRect(bx, byy, bw, bh, 0.55, ac.r, ac.g, ac.b)
        end
        mp:drawRectBorder(bx, byy, bw, bh, bs.a, bs.r, bs.g, bs.b)
        mp:drawText(label, bx + T.px(7), byy + math.floor((bh - h1) / 2), tc.r, tc.g, tc.b, tc.a or 1, f1)
        zones[#zones + 1] = { id = "map:key:survey", x = bx + ox, y = byy + oy, w = bw, h = bh,
            activate = function(w2) ZeD.MapsTab.setStyle(w2, "survey") end }
    end
    -- the rest of the panel is the key's (a click on it does not reach the map)
    zones[#zones + 1] = { id = "map:key:panel", x = x + ox, y = y + oy, w = w, h = h, inert = true }
    return zones
end

ZeD.MapsTab.addExtension("key", K)
