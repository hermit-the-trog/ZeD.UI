-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PadFigure.lua
-- ============================================================================
-- THE DRAWN CONTROLLER. Client; draw helpers in the atom mould (no state but
-- the textures it loads). One drawing for two windows: Options > Controls >
-- Button map and test (ZeD_MainMenuOptionsSub.lua, with its labels and the
-- live test) and the quick wheel's Controller map (ZeD_ControllerMap.lua).
--
-- ZeD's beige pad in pixel art, made by ZeDUI/workshop/controller_map/
-- pixel_pad_v2.py into media/textures/ZeD/pad/: per button set the resting pad
-- (zpad_<set>_<layout>.png, 188 x 106 art pixels) and the live test's layers
-- (zpad_<set>_<layout>_parts.png: five 188 x 106 panels side by side, under,
-- caps, shade, light, ink; the generator's header says what each holds). The
-- left stick sits up top on Xbox and Nintendo pads, as on theirs; PlayStation
-- and Steam Deck pads have the D-pad up top.
--
-- Whole multiples only: k screen pixels to an art pixel, nearest filtering,
-- never stretched. A held part is its own pixels in the accent: the shade
-- panel tinted with the accent (white texels give the accent, gray ones its
-- dark dither and rims), the light panel with the accent mixed 38% toward
-- white, the ink panel (letters, symbols, arrows) with the ink that sits on the
-- accent. A held face button or View / Menu draws one art pixel down and right
-- with no shadow; a stick's cap moves round(axis x (well radius - 9)) art
-- pixels; a trigger fills its 7 showing rows from the bottom, round(pull x 7).
--
--   F.CW, F.CH                       the drawing's size in art pixels
--   F.k(w, h)                        the largest whole multiple that fits w x h px (at least 1)
--   F.draw(panel, x, y, k, set, st)  the pad with its top left at (x, y); st nil = at rest, else
--                                    { b = { A = true, DU = true, L3 = true, ... }, ls = { x, y },
--                                      rs = { x, y }, lt = 0..1, rt = 0..1 }
--   F.layoutOf(set)                  "stickup" or "house"
--   F.anchors(set)                   per label id: { side = "L" | "R" | "T" | "B", a = { art x, art y } }
--   F.at(x, k, ax), F.atY(y, k, ay)  the screen coordinates of an art pixel's center, the pad at (x, y)
--   F.layout(W, H, sizes, set, u)    where the pad and its labels go in a W x H box (below)
-- ============================================================================

require "ZeD/AtomExtensions"

ZeD = ZeD or {}   -- Reload-safe: loading this file twice reuses the table instead of wiping it.
ZeD.PadFigure = ZeD.PadFigure or {}
local F = ZeD.PadFigure

local X0, Y0, CW, CH = 8, 21, 188, 106   -- the crop of the 200 x 136 art grid the windows show
F.CW, F.CH, F.X0, F.Y0 = CW, CH, X0, Y0
local DIR = "media/textures/ZeD/pad/"
local PANEL = { under = 0, caps = 1, shade = 2, light = 3, ink = 4 }

-- which drawing each glyph set gets (ZeD_PadGlyphs' sets; nil, the lettered boxes, draws the Xbox pad)
local VARIANT = { xbox = "xbox_stickup", ps = "ps_house", deck = "deck_house", nin = "nin_stickup" }
local LAYOUT = { xbox = "stickup", ps = "house", deck = "house", nin = "stickup" }

-- where the parts sit, in art pixels (the generator's geo())
local GEO = {
    house   = { dpad = { 50, 71 }, ls = { 84, 92, 13 } },
    stickup = { dpad = { 84, 93 }, ls = { 50, 71, 15 } },
}
local RS = { 116, 92, 13 }
local BTN = { Y = { 150, 59 }, A = { 150, 83 }, X = { 138, 71 }, B = { 162, 71 } }
-- boxes (x0, y0, x1, y1): View / Menu; the bumpers; the triggers' columns (their rows that show are 24..30)
local KEYS = { { "SEL", 79, 65, 89, 69 }, { "START", 111, 65, 121, 69 } }
local BUMP = { { "LB", 30, 31, 76, 40 }, { "RB", 124, 31, 170, 40 } }
local TRIG = { { "lt", 34, 59 }, { "rt", 141, 166 } }
local FACE_ORDER = { "Y", "X", "B", "A" }

function F.layoutOf(set) return LAYOUT[set or "xbox"] or "stickup" end

local function geoOf(set) return GEO[F.layoutOf(set)] end

-- the textures, each loaded once with nearest filtering (3); false when the game has none
local _tex = {}
local function tex(name)
    local t = _tex[name]
    if t == nil then
        t = (Texture and Texture.getSharedTexture and Texture.getSharedTexture(DIR .. name .. ".png", 3)) or false
        _tex[name] = t
    end
    return t or nil
end
F._tex = tex

--- The largest whole multiple k that fits the drawing in w x h screen px (at least 1).
function F.k(w, h)
    local k = math.floor((tonumber(w) or 0) / CW)
    if h then k = math.min(k, math.floor((tonumber(h) or 0) / CH)) end
    return math.max(1, k)
end

--- The screen x of the center of art column ax, and the screen y of art row ay, the pad drawn at (x, y).
function F.at(x, k, ax) return x + (ax - X0 + 0.5) * k end
function F.atY(y, k, ay) return y + (ay - Y0 + 0.5) * k end

local function round(v) return math.floor(v + 0.5) end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
-- One box of a parts panel, art pixels x0..x1, y0..y1 (inclusive), to where it rests moved (ox, oy) art pixels,
-- tinted r, g, b (1, 1, 1 for the panels that hold the pad's own colors)
local function box(jo, parts, panel, x, y, k, x0, y0, x1, y1, ox, oy, r, g, b)
    local sw, sh = x1 - x0 + 1, y1 - y0 + 1
    jo:DrawSubTextureRGBA(parts, PANEL[panel] * CW + x0 - X0, y0 - Y0, sw, sh,
        x + (x0 - X0 + ox) * k, y + (y0 - Y0 + oy) * k, sw * k, sh * k, r, g, b, 1)
end

-- the tints a lit part's panels take this frame (ZeD.T, read fresh: a theme or accent change shows at once)
local _tint = { a = {}, hi = {}, ink = {} }
local function tints()
    local T = ZeD.T
    local a = T.accent
    local t = _tint
    t.a.r, t.a.g, t.a.b = a.r, a.g, a.b
    t.hi.r, t.hi.g, t.hi.b = a.r + (1 - a.r) * 0.38, a.g + (1 - a.g) * 0.38, a.b + (1 - a.b) * 0.38
    local on = T.textOnAccent or T.base
    t.ink.r, t.ink.g, t.ink.b = on.r, on.g, on.b
    return t
end

-- a lit part: its shade, light and (letters, arrows) ink boxes
local function lit(jo, parts, x, y, k, x0, y0, x1, y1, ox, oy, inked, t)
    box(jo, parts, "shade", x, y, k, x0, y0, x1, y1, ox, oy, t.a.r, t.a.g, t.a.b)
    box(jo, parts, "light", x, y, k, x0, y0, x1, y1, ox, oy, t.hi.r, t.hi.g, t.hi.b)
    if inked then box(jo, parts, "ink", x, y, k, x0, y0, x1, y1, ox, oy, t.ink.r, t.ink.g, t.ink.b) end
end

-- a stick's offset in art pixels: the stick's push (kept to the unit circle) times the room the cap has
local function capOffset(v, wr)
    if type(v) ~= "table" then return 0, 0 end
    local vx, vy = tonumber(v[1]) or 0, tonumber(v[2]) or 0
    local len = math.sqrt(vx * vx + vy * vy)
    if len > 1 then vx, vy = vx / len, vy / len end
    return round(vx * (wr - 9)), round(vy * (wr - 9))
end
F.capOffset = capOffset

-- the trigger rows that show lit for a pull: the bottom n of the 7 above the bumper (rows 24..30), none at rest
local function trigRows(pull)
    pull = tonumber(pull) or 0
    if pull <= 0.02 then return 0 end
    return math.max(1, math.min(7, round(pull * 7)))
end
F.trigRows = trigRows

-- the live parts over the resting pad: first every patch of the under panel (what a pressed button or a moved
-- cap leaves), then the lit and moved parts, so no patch ever covers a part drawn this frame
local function drawLive(jo, parts, x, y, k, set, st)
    local G = geoOf(set)
    local b = st.b or {}
    local t = tints()
    -- the patches
    for _, r in ipairs(FACE_ORDER) do
        if b[r] then local c = BTN[r]; box(jo, parts, "under", x, y, k, c[1] - 6, c[2] - 6, c[1] + 7, c[2] + 7, 0, 0, 1, 1, 1) end
    end
    for _, q in ipairs(KEYS) do
        if b[q[1]] then box(jo, parts, "under", x, y, k, q[2], q[3], q[4] + 1, q[5] + 1, 0, 0, 1, 1, 1) end
    end
    local lsx, lsy = capOffset(st.ls, G.ls[3])
    local rsx, rsy = capOffset(st.rs, RS[3])
    if lsx ~= 0 or lsy ~= 0 then box(jo, parts, "under", x, y, k, G.ls[1] - 9, G.ls[2] - 9, G.ls[1] + 10, G.ls[2] + 10, 0, 0, 1, 1, 1) end
    if rsx ~= 0 or rsy ~= 0 then box(jo, parts, "under", x, y, k, RS[1] - 9, RS[2] - 9, RS[1] + 10, RS[2] + 10, 0, 0, 1, 1, 1) end
    -- the parts: pressed in (face, View / Menu), lit in place (arms, bumpers, trigger rows)
    for _, r in ipairs(FACE_ORDER) do
        if b[r] then local c = BTN[r]; lit(jo, parts, x, y, k, c[1] - 6, c[2] - 6, c[1] + 6, c[2] + 6, 1, 1, true, t) end
    end
    for _, q in ipairs(KEYS) do
        if b[q[1]] then lit(jo, parts, x, y, k, q[2], q[3], q[4], q[5], 1, 1, false, t) end
    end
    local dx, dy = G.dpad[1], G.dpad[2]
    if b.DU then lit(jo, parts, x, y, k, dx - 4, dy - 13, dx + 4, dy - 5, 0, 0, true, t) end
    if b.DD then lit(jo, parts, x, y, k, dx - 4, dy + 5, dx + 4, dy + 13, 0, 0, true, t) end
    if b.DL then lit(jo, parts, x, y, k, dx - 13, dy - 4, dx - 5, dy + 4, 0, 0, true, t) end
    if b.DR then lit(jo, parts, x, y, k, dx + 5, dy - 4, dx + 13, dy + 4, 0, 0, true, t) end
    for _, q in ipairs(BUMP) do
        if b[q[1]] then lit(jo, parts, x, y, k, q[2], q[3], q[4], q[5], 0, 0, false, t) end
    end
    for _, q in ipairs(TRIG) do
        local n = trigRows(st[q[1]])
        if n > 0 then lit(jo, parts, x, y, k, q[2], 31 - n, q[3], 30, 0, 0, false, t) end
    end
    -- the caps last: they sit over their wells' rims when pushed hard
    local caps = { { G.ls, lsx, lsy, b.L3 }, { RS, rsx, rsy, b.R3 } }
    for _, c in ipairs(caps) do
        local p, ox, oy = c[1], c[2], c[3]
        if ox ~= 0 or oy ~= 0 then box(jo, parts, "caps", x, y, k, p[1] - 9, p[2] - 9, p[1] + 10, p[2] + 10, ox, oy, 1, 1, 1) end
        if c[4] then lit(jo, parts, x, y, k, p[1] - 9, p[2] - 9, p[1] + 9, p[2] + 9, ox, oy, false, t) end
    end
end

--- Draw the pad with its top left at (x, y), k screen px to an art pixel; set: the glyph set (ZeD_PadGlyphs; nil
--- draws the Xbox pad); st: the live input (above), nil at rest. Returns false when the game has no textures.
function F.draw(panel, x, y, k, set, st)
    local v = VARIANT[set or "xbox"] or VARIANT.xbox
    local rest = tex("zpad_" .. v)
    if not rest then return false end
    k = math.max(1, math.floor(k or 1))
    local jo = ZeD.Atoms.lineJo and ZeD.Atoms.lineJo(panel)
    if not jo then
        -- (a panel with a drawRect of its own, such as a fade, keeps its own calls: the resting pad only)
        panel:drawTextureScaled(rest, x, y, CW * k, CH * k, 1, 1, 1, 1)
        return true
    end
    jo:DrawSubTextureRGBA(rest, 0, 0, CW, CH, x, y, CW * k, CH * k, 1, 1, 1, 1)
    local parts = st and tex("zpad_" .. v .. "_parts")
    if parts then drawLive(jo, parts, x, y, k, set or "xbox", st) end
    return true
end

-- ---------------------------------------------------------------------------
-- THE LABELS' PLACES
-- ---------------------------------------------------------------------------
--- Per label id, its side and the art pixel its leader starts from: the left column (the shoulders, the D-pad,
--- the left stick), the right column (the shoulders, Y B A), View and Menu above the pad, the right stick and X
--- below it.
function F.anchors(set)
    local G = geoOf(set)
    local d, l = G.dpad, G.ls
    local up = F.layoutOf(set) == "stickup"
    return {
        LT = { side = "L", a = { 34, 27 } }, LB = { side = "L", a = { 30, 35 } },
        DPAD = { side = "L", a = { d[1] - 13, d[2] } },
        LS = { side = "L", a = up and { l[1] - l[3], l[2] } or { l[1] - l[3], l[2] + 2 } },
        SEL = { side = "T", a = { 84, 64 } }, START = { side = "T", a = { 116, 64 } },
        RT = { side = "R", a = { 166, 27 } }, RB = { side = "R", a = { 170, 35 } },
        Y = { side = "R", a = { 156, 59 } }, B = { side = "R", a = { 168, 71 } }, A = { side = "R", a = { 156, 83 } },
        RS = { side = "B", a = { RS[1], RS[2] + RS[3] } }, X = { side = "B", a = { 138, 77 } },
    }
end

-- the labels of each side column (sorted top to bottom by their part's height on the pad when placed: the D-pad
-- and the left stick swap places between the two layouts)
local SIDE_IDS = { L = { "LT", "LB", "DPAD", "LS" }, R = { "RT", "RB", "Y", "B", "A" } }

--- Where the pad and its labels go in a W x H box (px, the box's own coordinates).
--- sizes[id] = { w, h, mid } (mid: from the label's top to the middle of its first line, where its leader ends);
--- u(n): design units to px (T.px). The pad takes the largest whole multiple that leaves the side columns their
--- room and the top and bottom rows theirs; each side label sits as near its part's height as the others allow,
--- in the parts' order, so no two leaders cross. Returns { k, x, y, w, h (the pad), place = { id = { x, y } },
--- leads = { id = { x1, y1, x2, y2, ... } }, over (true when a side column is taller than its room: its top
--- label is held at the top and meets the next, so the caller shortens the labels) }.
function F.layout(W, H, sizes, set, u)
    local A = F.anchors(set)
    local GAP, MARG = u(22), u(8)
    local function colW(side)
        local m = 0
        for _, id in ipairs(SIDE_IDS[side]) do m = math.max(m, sizes[id].w) end
        return m
    end
    local lw, rw = colW("L"), colW("R")
    local room = W - lw - rw - 2 * (GAP + MARG)
    local k = math.max(1, math.min(math.floor(room / CW), math.floor((H - u(120)) / CH)))
    local pw, ph = CW * k, CH * k
    local topH = math.max(sizes.SEL.h, sizes.START.h)
    local botH = math.max(sizes.RS.h, sizes.X.h)
    local totH = topH + u(8) + ph + u(10) + botH
    local px0 = round(MARG + lw + GAP + (room - pw) / 2)
    local py0 = round((H - totH) / 2 + topH + u(8))
    local L = { k = k, x = px0, y = py0, w = pw, h = ph, place = {}, leads = {} }
    local function U(id) local a = A[id].a; return F.at(px0, k, a[1]), F.atY(py0, k, a[2]) end
    -- above and below: straight up or down from the part to the label's edge, the label hung off that line
    local rows = { { "SEL", true, true }, { "START", true, false }, { "RS", false, true }, { "X", false, false } }
    for _, r in ipairs(rows) do
        local id, above, toLeft = r[1], r[2], r[3]
        local s = sizes[id]
        local ax, ay = U(id)
        local edge = above and (py0 - u(8)) or (py0 + ph + u(10))
        L.place[id] = { x = round(toLeft and (ax + u(12) - s.w) or (ax - u(12))), y = round(above and (edge - s.h) or edge) }
        L.leads[id] = { ax, ay, ax, edge }
    end
    -- the side columns
    local xl = L.place.X
    local xRight = xl.x + sizes.X.w
    for _, side in ipairs({ "L", "R" }) do
        local ids = {}
        for i, id in ipairs(SIDE_IDS[side]) do ids[i] = id end
        table.sort(ids, function(a, b) return A[a].a[2] < A[b].a[2] end)
        local colX = (side == "L") and (px0 - GAP) or (px0 + pw + GAP)
        local lo, hi = u(6), H - u(6)
        if side == "R" and xRight > colX - u(4) then hi = math.min(hi, xl.y - u(6)) end
        local tops = {}
        for i, id in ipairs(ids) do
            local _, ay = U(id)
            local want = ay - sizes[id].mid
            tops[i] = (i > 1) and math.max(want, tops[i - 1] + sizes[ids[i - 1]].h + u(4)) or math.max(want, lo)
        end
        local n = #ids
        if tops[n] + sizes[ids[n]].h > hi then
            for i = n, 1, -1 do
                local lim = (i < n) and (tops[i + 1] - u(4) - sizes[ids[i]].h) or (hi - sizes[ids[i]].h)
                tops[i] = math.min(tops[i], lim)
            end
            -- (still past the top: the column is taller than its room, and the top label below would sit on the
            -- next one; the caller shortens the labels and asks again)
            if tops[1] < lo - 0.5 then L.over = true end
        end
        for i, id in ipairs(ids) do
            local s = sizes[id]
            local top = round(math.max(lo, tops[i]))
            L.place[id] = { x = (side == "L") and (colX - s.w) or colX, y = top }
            local ax, ay = U(id)
            local knee = (side == "L") and (px0 - u(4)) or (px0 + pw + u(4))
            L.leads[id] = { ax, ay, knee, ay, colX, top + s.mid }
        end
    end
    return L
end

return F
