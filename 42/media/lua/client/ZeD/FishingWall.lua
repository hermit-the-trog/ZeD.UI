-- ZeD-UI/42/media/lua/client/ZeD/FishingWall.lua
-- ============================================================================
-- THE TROPHY WALL — client; an organism drawn over the Fishing tab.
-- The Trophy wall key in the catch log's head opens it as a card at the tab's
-- full width, the back bar on top as on an item card. Under the bar:
--   Top 10 / Each kind   two radios: the ten heaviest fish of the whole game, or
--                        the best of each of the game's species in its own order
--                        (an empty plaque stays a mystery: "Not caught yet")
--   the wall             pixel-art plaques on the window's own surface, one scroll
--   the record           the picked plaque's whole record
--   the band             Back
-- Each plaque is a stained board with its fish in pixel art (one picture per
-- kind of fish) and a brass plate: the catch as the game named it, weight,
-- date, the water and the bait. The wood keeps its colours in every theme, as
-- the desk and the other props do; the chrome around it follows the theme.
-- Pixels stay whole: one art pixel is kp screen pixels, kp the whole number
-- nearest to 3 design units, so the boards stay crisp at every scale.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_PixelParts"
require "ZeD/FishingLog"

ZeD = ZeD or {}   -- Reload-safe: loading this file twice reuses the table instead of wiping it.
ZeD.FishingWall = ZeD.FishingWall or {}
local FW = ZeD.FishingWall
local Log = ZeD.FishingLog

local ART_W, ART_H = 72, 52           -- a plaque, in art pixels
local GAP_X, GAP_Y, TOP = 24, 22, 18  -- design units
local MODES_H = 30

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function nowMs() return (getTimestampMs and getTimestampMs()) or 0 end
local function itemName(ft)
    local ok, v = pcall(getItemNameFromFullType, ft)
    return (ok and v) or ft or ""
end

-- ---------------------------------------------------------------------------
-- THE PIXEL ART: a board and a fish, built once per kind as flat rect lists by colour
-- ---------------------------------------------------------------------------
-- each kind's body: length and depth in art pixels, its colours and its marks
FW.KINDS = {
    sunfish = { L = 26, D = 7.5, back = "#3f5a3a", side = "#7d9a5a", belly = "#d08a3a", mark = "bars", fin = "#2f4430" },
    perch = { L = 32, D = 5.5, back = "#5a5a22", side = "#c8b040", belly = "#e2d6a0", mark = "bars", fin = "#c0602a" },
    bass = { L = 36, D = 6, back = "#3e5226", side = "#7f9a4a", belly = "#dcd8b0", mark = "band", fin = "#3e5226" },
    bronze = { L = 34, D = 6, back = "#5a4426", side = "#9a7a46", belly = "#dcd0a8", mark = "bars", fin = "#5a4426" },
    crappie = { L = 28, D = 7, back = "#5a6a62", side = "#b8c2b8", belly = "#e6e6dc", mark = "spots", fin = "#5a6a62" },
    cat = { L = 36, D = 5, back = "#4a525a", side = "#7a848c", belly = "#d6d6cc", mark = "spots", fin = "#3a4248", whisk = true },
    drum = { L = 36, D = 7, back = "#6a6a6a", side = "#aeb0a8", belly = "#e0dcd0", mark = "none", fin = "#5a5a5a", hump = true },
    silver = { L = 34, D = 6, back = "#4a5a66", side = "#b8c0c4", belly = "#e8e8e2", mark = "band", fin = "#4a5a66" },
    long = { L = 44, D = 4, back = "#4a5236", side = "#8a9466", belly = "#d8d4b4", mark = "spots", fin = "#4a5236" },
    bait = { L = 14, D = 2.5, back = "#5a6a70", side = "#c0c8cc", belly = "#e8e8e2", mark = "band", fin = "#5a6a70" },
}
local KEYW = 256
local function key(x, y) return (y + 8) * KEYW + (x + 8) end

-- a board with its corners cut c pixels, filled into cells
local function oct(cells, x0, y0, w, h, c, col)
    for r = 0, h - 1 do
        local inset = math.max(0, c - r, c - (h - 1 - r))
        for x = x0 + inset, x0 + w - 1 - inset do cells[key(x, y0 + r)] = col end
    end
end
local function rect(cells, x0, y0, w, h, col)
    for y = y0, y0 + h - 1 do
        for x = x0, x0 + w - 1 do cells[key(x, y)] = col end
    end
end

-- the fish, its body drawn column by column from a few numbers, a one-pixel dark outline round it
local function fish(cells, kind, ox, oy)
    local k = FW.KINDS[kind] or FW.KINDS.bass
    local L, cy = k.L, oy + 8
    local body = {}
    local function put(x, y, c) body[key(x, y)] = c end
    for x = 0, L - 1 do
        local t = x / L
        local h = k.D * (math.sin(math.pi * math.min(1, (t + 0.05) / 1.1)) ^ 0.7)
        if t > 0.82 then h = math.max(1, h * (1 - (t - 0.82) * 3)) end
        local top = math.floor(cy - h - ((k.hump and t > 0.15 and t < 0.5) and 1 or 0) + 0.5)
        local bot = math.floor(cy + h * 0.85 + 0.5)
        for y = top, bot do
            local c = (y < cy - h * 0.35) and k.back or ((y > cy + h * 0.35) and k.belly or k.side)
            if k.mark == "band" and y == cy and x > 5 and x < L - 5 then c = k.back end
            if k.mark == "bars" and x > 6 and x < L - 6 and x % 5 == 0 and y < cy + 1 then c = k.back end
            if k.mark == "spots" and (x * 7 + y * 13) % 11 == 0 and y < cy + 1 and x > 4 then c = k.back end
            put(ox + x, y, c)
        end
        if t > 0.35 and t < 0.62 then put(ox + x, top - 1, k.fin) end   -- the dorsal fin
    end
    for i = 0, 5 do                                                     -- the tail
        for y = -i - 1, i + 1 do
            if math.abs(y) >= i - 1 then put(ox + L + i, cy + y, k.fin) end
        end
    end
    put(ox + 3, cy - 1, "#111111")                                      -- the eye
    put(ox + 1, cy + 1, "#2a1a10")                                      -- the mouth
    if k.whisk then
        put(ox - 1, cy, "#2a2a2a"); put(ox - 2, cy + 1, "#2a2a2a"); put(ox - 1, cy - 2, "#2a2a2a"); put(ox - 2, cy - 3, "#2a2a2a")
    end
    for kk in pairs(body) do
        local x, y = (kk % KEYW) - 8, math.floor(kk / KEYW) - 8
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local n = key(x + d[1], y + d[2])
            if not body[n] then cells[n] = "#1c1008" end
        end
    end
    for kk, c in pairs(body) do cells[kk] = c end
end

-- cells -> { [colour] = flat rect list } as one-pixel-tall runs per row (ZeD.Px.rects merges them down)
local function lists(cells, w, h)
    local out = {}
    for y = -2, h + 2 do
        local x = -6
        while x <= w + 6 do
            local c = cells[key(x, y)]
            if c then
                local x1 = x
                while cells[key(x1 + 1, y)] == c do x1 = x1 + 1 end
                local l = out[c]
                if not l then l = {}; out[c] = l end
                l[#l + 1], l[#l + 2], l[#l + 3], l[#l + 4] = x, y, x1 - x + 1, 1
                x = x1 + 1
            else
                x = x + 1
            end
        end
    end
    return out
end

local _art = {}
--- The plaque's picture for kind (a fish kind from FW.KINDS): { [colour] = flat rect list }, built once.
function FW.art(kind)
    local a = _art[kind]
    if a then return a end
    local cells = {}
    oct(cells, 0, 0, ART_W, ART_H, 3, "#1c1008")
    oct(cells, 1, 1, ART_W - 2, ART_H - 2, 3, "#6b3f1f")
    oct(cells, 3, 3, ART_W - 6, ART_H - 6, 2, "#7a4924")
    rect(cells, 5, 3, 62, 1, "#93603a"); rect(cells, 3, 5, 1, 42, "#93603a")      -- lit top and left edges
    rect(cells, 5, 48, 62, 1, "#4e2c14"); rect(cells, 68, 5, 1, 42, "#4e2c14")    -- shaded bottom and right
    rect(cells, 9, 9, 14, 1, "#6b3f1f"); rect(cells, 40, 13, 20, 1, "#6b3f1f"); rect(cells, 14, 27, 22, 1, "#6b3f1f")   -- grain
    rect(cells, 35, 5, 2, 2, "#c9a23a")                                           -- the hanger
    local k = FW.KINDS[kind] or FW.KINDS.bass
    fish(cells, kind, math.floor((ART_W - k.L - 6) / 2 + 0.5), 7)
    a = lists(cells, ART_W, ART_H)
    _art[kind] = a
    return a
end

-- the empty plaque's outline fish (10 x 10)
local GHOST = { "..........", "..........", "...xxxx...", "..xxxxxx.x", ".x.xxxxxx.", ".xxxxxxxx.", "..xxxxxx.x", "...xxxx...", "..........", ".........." }
local _ghost
local function ghostList()
    if _ghost then return _ghost end
    local l = {}
    for y, row in ipairs(GHOST) do
        for x = 1, #row do
            if row:sub(x, x) == "x" then l[#l + 1], l[#l + 2], l[#l + 3], l[#l + 4] = x - 1, y - 1, 1, 1 end
        end
    end
    _ghost = l
    return l
end

--- One art pixel in screen pixels: the whole number nearest to 3 design units, at least 1.
function FW.kp() return math.max(1, math.floor(px(3) + 0.5)) end

-- ---------------------------------------------------------------------------
-- STATE AND WORDS
-- ---------------------------------------------------------------------------
--- Opens the wall over the Fishing tab (st: the tab's state); the controller lands on the first plaque.
function FW.open(win, st)
    st.wall = { mode = "top", sel = 1, scroll = ZeD_ScrollbarState:new() }
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.focusSoon then Fo.focusSoon(win, "worldTabContent", function(e) return e.id == "fish:plq:1" or e.id == "fish:wb:foot" end, 1) end
end

--- Back to the tab; the controller returns to the Trophy wall key.
function FW.close(win, st)
    st.wall = nil
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.focusSoon then Fo.focusSoon(win, "worldTabContent", function(e) return e.id == "fish:wall" end, 1) end
end

local function placeOf(r)
    if r.river == nil then return nil end
    return tr(r.river and "UI_ZeD_Fish_River" or "UI_ZeD_Fish_Lake")
end

-- the record band's facts for plaque it: { { label, value }, ... }
function FW.facts(it, lv)
    local r = it.rec
    local FT = ZeD.FishingTab
    local out = {}
    if not r then return out end
    out[#out + 1] = { tr("UI_ZeD_Fish_RWeight"), string.format("%.2f", r.wt or 0) }
    if r.len then out[#out + 1] = { tr("UI_ZeD_Fish_RLength"), tr("UI_ZeD_Fish_Cm", r.len) } end
    out[#out + 1] = { tr("UI_ZeD_Fish_RCaught"), FT.date(r) .. ", " .. FT.hhmm(r) }
    local pl = placeOf(r)
    if pl then out[#out + 1] = { tr("UI_ZeD_Fish_RAt"), (r.tx and tr("UI_ZeD_Fish_PlaceAt", pl, r.tx, r.ty)) or pl } end
    if r.bait then out[#out + 1] = { tr("UI_ZeD_Fish_Bait"), itemName(r.bait) } end
    if r.rod then out[#out + 1] = { tr("UI_ZeD_Fish_Rod"), r.rod } end
    if r.lv then out[#out + 1] = { getText("IGUI_perks_Fishing"), tostring(r.lv) } end
    if it.rank then out[#out + 1] = { tr("UI_ZeD_Fish_RRank"), tr("UI_ZeD_Fish_RankOf", it.rank, Log.TOP_MAX) } end
    return out
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local MEDAL = { "#c9a23a", "#aab0b6", "#a86a3a" }
local BRASS, BRASS_HI, BRASS_LO, INK = "#b48f3e", "#e0c06a", "#4a3812", "#241905"

local function txt(panel, s, x, y, c, font) panel:drawText(s, x, y, c.r, c.g, c.b, c.a or 1, font) end
local function cut(s, font, w) return ZeD.Atoms.truncateText(s or "", font, math.max(0, w)) end

--- Draws plaque it ({ rec, rank, type }) with its top-left at (x, y); kp screen pixels an art pixel.
function FW.drawPlaque(panel, it, x, y, kp, sel, focus)
    local T, P = ZeD.T, ZeD.Px
    local tm = ZeD.TM
    local w, h = ART_W * kp, ART_H * kp
    if sel then
        local a = T.accent
        ZeD.Atoms.frame(panel, x - px(4), y - px(4), w + px(8), h + px(8), a)
    end
    local cv = P.canvas(panel, x, y, kp)
    local r = it.rec
    if not r then
        -- not caught yet: an outline, no name (the game keeps an uncaught species a mystery too)
        local gold = P.color("#d8b862")
        panel:drawRect(x, y, w, h, 0.18, 0, 0, 0)
        ZeD.Atoms.frame(panel, x, y, w, h, gold, 0.28)
        local gk = math.max(1, kp)
        P.rects(P.canvas(panel, x + math.floor((w - 10 * gk * 2) / 2), y + math.floor(h * 0.25), gk * 2), ghostList(), gold, 0.35)
        local s = tr("UI_ZeD_Fish_NotCaught")
        local f = T.fontF3
        txt(panel, cut(s, f, w - px(8)), x + math.floor((w - math.min(w - px(8), tm:MeasureStringX(f, s))) / 2), y + math.floor(h * 0.62), { r = gold.r, g = gold.g, b = gold.b, a = 0.6 }, f)
    else
        for col, list in pairs(FW.art(Log.KIND[r.type] or "bass")) do P.rects(cv, list, P.color(col)) end
        -- the brass plate: the game's name for the catch, weight and date, the water and the bait
        local f2, f3 = T.fontF2, T.fontF3
        local f2h, f3h = tm:getFontHeight(f2), tm:getFontHeight(f3)
        local plx, plw = x + 4 * kp, w - 8 * kp
        local plh = f2h + 2 * f3h + px(6)
        local ply = y + h - 4 * kp - plh
        local b, hi, lo, ink = P.color(BRASS), P.color(BRASS_HI), P.color(BRASS_LO), P.color(INK)
        panel:drawRect(plx, ply, plw, plh, 1, b.r, b.g, b.b)
        ZeD.Atoms.frame(panel, plx, ply, plw, plh, lo)
        panel:drawRect(plx + T.hair, ply, plw - 2 * T.hair, T.hair, 1, hi.r, hi.g, hi.b)
        local FT = ZeD.FishingTab
        local lines = {
            { r.name or itemName(r.type), f2 },
            { string.format("%.2f", r.wt or 0) .. " | " .. FT.date(r), f3 },
            { table.concat({ placeOf(r) or "-", r.bait and itemName(r.bait) or "-" }, " | "), f3 },
        }
        local ly = ply + px(3)
        for _, ln in ipairs(lines) do
            local s = cut(ln[1], ln[2], plw - px(8))
            txt(panel, s, plx + math.floor((plw - tm:MeasureStringX(ln[2], s)) / 2), ly, ink, ln[2])
            ly = ly + tm:getFontHeight(ln[2])
        end
        if it.rank then
            -- the rank tab: gold, silver and bronze for the first three
            local ms = px(18)
            local mc = P.color(MEDAL[it.rank] or "#3a2412")
            local mx, my = x + 4 * kp, y + 3 * kp
            panel:drawRect(mx, my, ms, ms, 1, mc.r, mc.g, mc.b)
            ZeD.Atoms.frame(panel, mx, my, ms, ms, P.color("#1a1206"))
            local nc = P.color(it.rank <= 3 and "#1a1206" or "#d8b862")
            local s = tostring(it.rank)
            local f1 = T.fontF1
            txt(panel, s, mx + math.floor((ms - tm:MeasureStringX(f1, s)) / 2), my + math.floor((ms - tm:getFontHeight(f1)) / 2), nc, f1)
        end
    end
    if focus and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(panel, x, y, w, h, focus) end
end

-- the picked plaque's record, under the wall; returns its height (measured when draw is false)
local function recordBand(panel, wl, it, x, y, w, lv, draw)
    local T = ZeD.T
    local tm = ZeD.TM
    local f2, f3, f4 = T.fontF2, T.fontF3, T.fontF4
    local pad = px(12)
    local hh = px(7) + tm:getFontHeight(f4) + px(3)
    local facts = it and FW.facts(it, lv) or {}
    -- the facts flow left to right, "Weight 8.47", wrapping to the width
    local cx, rows = 0, 1
    local spots = {}
    for _, f in ipairs(facts) do
        local lw = tm:MeasureStringX(f3, f[1]) + px(6)
        local fw = lw + tm:MeasureStringX(f3, f[2])
        if cx > 0 and cx + fw > w - 2 * pad then cx = 0; rows = rows + 1 end
        spots[#spots + 1] = { f = f, x = cx, row = rows, lw = lw }
        cx = cx + fw + px(14)
    end
    local rowH = tm:getFontHeight(f3) + px(2)
    local note = nil
    if it and not it.rec then
        local _, d = Log.wall(wl.p, "each")
        note = tr("UI_ZeD_Fish_StillToCatch", math.max(0, #Log.species() - d))
        local lim = Fishing and Fishing.Utils and Fishing.Utils.skillSizeLimit and Fishing.Utils.skillSizeLimit[lv]
        for _, sp in ipairs(Log.species()) do
            if sp.type == it.type and lim and sp.cfg.maxWeight and sp.cfg.maxWeight > lim then
                note = note .. " " .. tr("UI_ZeD_Fish_TooHeavy", lv)
            end
        end
    end
    local noteLines = note and ZeD.Atoms.wrapText(note, f2, w - 2 * pad) or {}
    local h = hh + ((#facts > 0) and rows * rowH or #noteLines * (tm:getFontHeight(f2) + px(2))) + px(8)
    if not draw then return h end
    ZeD.Surface.fill(panel, x, y, w, h, "surf2")
    ZeD.Atoms.drawDividerH(panel, x, y, w, false)
    local name = it and it.rec and (it.rec.name or itemName(it.rec.type)) or tr("UI_ZeD_Fish_NotCaught")
    txt(panel, cut(name, f4, w - 2 * pad), x + pad, y + px(7), (it and it.rec) and T.text or T.textDim, f4)
    local ty = y + hh
    for _, sp in ipairs(spots) do
        local yy = ty + (sp.row - 1) * rowH
        txt(panel, sp.f[1], x + pad + sp.x, yy, T.textDim, f3)
        txt(panel, sp.f[2], x + pad + sp.x + sp.lw, yy, T.text, f3)
    end
    for i, ln in ipairs(noteLines) do txt(panel, ln, x + pad, ty + (i - 1) * (tm:getFontHeight(f2) + px(2)), T.textDim, f2) end
    return h
end

local _band = { buttons = { {} } }
--- Draws the wall over the tab in win (st: the tab's state; st.wall the wall's).
function FW.render(panel, win, st, x, y, w, h)
    local T, M, A = ZeD.T, ZeD.Molecules, ZeD.Atoms
    local tm = ZeD.TM
    local wl = st.wall
    local p = win._playerObj or getPlayer()
    if not p then return end
    wl.p = p
    local FT = ZeD.FishingTab
    local d = Log.data(p)
    local items, mounted = Log.wall(p, wl.mode)
    wl.items = items
    if wl.sel > #items then wl.sel = math.max(1, #items) end
    local lv = p:getPerkLevel(Perks.Fishing)
    wl.hits = {}
    -- the back bar, as on an item card
    wl.bar = {}
    local barH = M.drawCardBackBar(panel, x, y, w, tr("UI_ZeD_Fish_WallTitle"), nil, false, false, wl.bar,
        { win = win, focusParts = { back = FT.focusOf(win, "fish:wb:back") }, backHelp = tr("UI_ZeD_Fish_HelpBack") })
    -- Top 10 / Each kind
    local my0 = y + barH
    local mh = px(MODES_H)
    A.drawDividerH(panel, x, my0 + mh - T.hair, w, false)
    local f3 = T.fontF3
    local rs = A.radioSize()
    local cx = x + px(12)
    wl.modes = {}
    for _, m in ipairs({ { id = "top", key = "UI_ZeD_Fish_ModeTop" }, { id = "each", key = "UI_ZeD_Fish_ModeEach" } }) do
        local label = tr(m.key)
        local mw = rs + px(6) + tm:MeasureStringX(f3, label)
        local ry = my0 + math.floor((mh - px(20)) / 2)
        local f = FT.focusOf(win, "fish:wm:" .. m.id)
        local onF = false
        if f and ZeD.Focus and ZeD.Focus.mark then onF = ZeD.Focus.mark(panel, cx - px(2), ry, mw + px(4), px(20), f) end
        A.drawRadio(panel, cx, my0 + math.floor((mh - rs) / 2), wl.mode == m.id, { hover = A.mouseIn(panel, cx, ry, mw, px(20)) })
        txt(panel, label, cx + rs + px(6), my0 + math.floor((mh - tm:getFontHeight(f3)) / 2), onF and T.textOnFocus or T.text, f3)
        wl.modes[#wl.modes + 1] = { x = cx - px(2), y = ry, w = mw + px(4), h = px(20), id = m.id }
        cx = cx + mw + px(16)
    end
    local right = (wl.mode == "top") and tr("UI_ZeD_Fish_ByWeight") or tr("UI_ZeD_Fish_NOfM", mounted, #Log.species())
    local rx = x + w - px(12)
    if rx - tm:MeasureStringX(f3, right) > cx then
        txt(panel, right, rx - tm:MeasureStringX(f3, right), my0 + math.floor((mh - tm:getFontHeight(f3)) / 2), T.textDim, f3)
    end
    -- the foot: Back, and how many fish the save holds
    local bandH = M.bandH()
    local b = _band.buttons[1]
    b.label, b.variant, b.id = tr("UI_ZeD_Fish_Back"), "primary", "back"
    b.focus = FT.focusOf(win, "fish:wb:foot")
    b.help = tr("UI_ZeD_Fish_HelpBack")
    _band.win = win
    _band.status = { text = tr("UI_ZeD_Fish_WallKept", d.fish or 0) }
    local _, out = M.drawBand(panel, x, y + h - bandH, w, _band)
    wl.foot = out.buttons[1]
    -- the record of the picked plaque, over the band
    local cur = items[wl.sel]
    local recH = (#items > 0) and recordBand(panel, wl, cur, x, 0, w, lv, false) or 0
    local recY = y + h - bandH - recH
    if recH > 0 then recordBand(panel, wl, cur, x, recY, w, lv, true) end
    -- the wall: the plaques in rows, scrolled as one
    local sy, sh = my0 + mh, recY - (my0 + mh)
    local kp = FW.kp()
    local pw, ph = ART_W * kp, ART_H * kp
    local scroll = wl.scroll
    local cols = math.max(1, math.floor((w - T.sp.scrollbarW - px(24) + px(GAP_X)) / (pw + px(GAP_X))))
    local rows = math.ceil(#items / cols)
    local listH = px(TOP) + rows * (ph + px(GAP_Y)) - ((rows > 0) and px(GAP_Y) or 0) + px(22)
    local needs = listH > sh
    scroll.visible = needs
    local maxOff = math.max(0, listH - sh)
    if needs then
        scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, sy, sh
        scroll:setBarSize(sh / math.max(1, listH))
        FT.follow(win, scroll, maxOff, sh)
    else
        scroll:setScrollPos(0)
    end
    local off = needs and math.floor(scroll.scrollPos * maxOff) or 0
    local cw = w - (needs and T.sp.scrollbarW or 0)
    local gx = x + math.floor((cw - (cols * pw + (cols - 1) * px(GAP_X))) / 2)
    wl.sy, wl.sh, wl.off = sy, sh, off
    wl.plaques = {}
    panel:setStencilRect(x, sy, w, sh)
    if #items == 0 then
        M.drawEmptyLine(panel, x + px(12), sy + px(12), cw - px(24), tr("UI_ZeD_Fish_WallEmpty"))
    end
    for i, it in ipairs(items) do
        local c = (i - 1) % cols
        local r = math.floor((i - 1) / cols)
        local cy = px(TOP) + r * (ph + px(GAP_Y))
        local pxx, pyy = gx + c * (pw + px(GAP_X)), sy + cy - off
        wl.plaques[i] = { x = pxx, y = pyy, w = pw, h = ph, cy = cy }
        if pyy + ph >= sy - px(8) and pyy <= sy + sh + px(8) then
            FW.drawPlaque(panel, it, pxx, pyy, kp, i == wl.sel, FT.focusOf(win, "fish:plq:" .. i))
        end
    end
    panel:clearStencilRect()
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    if needs then scroll:draw(panel) end
    panel:clearStencilRect()
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end
local function inside(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

function FW.setMode(st, mode)
    if st.wall.mode == mode then return end
    st.wall.mode, st.wall.sel = mode, 1
    st.wall.scroll:setScrollPos(0)
    sound("UISelectListItem")
end

function FW.onClick(win, st, x, y)
    local wl = st.wall
    if inside(wl.bar and wl.bar.back, x, y) or inside(wl.foot, x, y) then sound(); FW.close(win, st); return true end
    for _, m in ipairs(wl.modes or {}) do
        if inside(m, x, y) then FW.setMode(st, m.id); return true end
    end
    local sc = wl.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return true
    end
    if y >= (wl.sy or 0) and y < (wl.sy or 0) + (wl.sh or 0) then
        for i, r in ipairs(wl.plaques or {}) do
            if inside(r, x, y) then wl.sel = i; sound("UISelectListItem"); return true end
        end
    end
    return true
end

--- The controller's stops on the wall: back key, the two modes, each plaque, Back. B anywhere goes back.
function FW.stops(win, st)
    local wl = st.wall
    local out = {}
    local function close(w) sound(); FW.close(w, st) end
    local function stop(e)
        e.onFocus = e.onFocus or function() end
        e.onCancel = close
        e.promptB = tr("UI_ZeD_Fish_Back")
        e.fish = true
        out[#out + 1] = e
    end
    local bk = wl.bar and wl.bar.back
    if bk then stop({ x = bk.x, y = bk.y, w = bk.w, h = bk.h, id = "fish:wb:back", promptA = tr("UI_ZeD_Fish_Back"), onActivate = close }) end
    for _, m in ipairs(wl.modes or {}) do
        local id = m.id
        stop({ x = m.x, y = m.y, w = m.w, h = m.h, id = "fish:wm:" .. id, onActivate = function() FW.setMode(st, id) end })
    end
    for i, r in ipairs(wl.plaques or {}) do
        local n = i
        stop({ x = r.x, y = r.y, w = r.w, h = r.h, cy = r.cy, id = "fish:plq:" .. i, promptA = tr("UI_ZeD_Fish_PromptRecord"),
               onActivate = function() wl.sel = n; sound("UISelectListItem") end })
    end
    local ft = wl.foot
    if ft then stop({ x = ft.x, y = ft.y, w = ft.w, h = ft.h, id = "fish:wb:foot", isPrimary = true, promptA = tr("UI_ZeD_Fish_Back"), onActivate = close }) end
    return out
end

--- The wall's stops are rebuilt when its mode, its plaques or its scroll change.
function FW.key(st)
    local wl = st.wall
    return "wall," .. tostring(wl.mode) .. "," .. tostring(#(wl.plaques or {})) .. "," .. tostring(wl.off or 0)
end

return FW
