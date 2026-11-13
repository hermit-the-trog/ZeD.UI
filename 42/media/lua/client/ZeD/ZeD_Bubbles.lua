-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Bubbles.lua
-- ============================================================================
-- THE OVERHEAD BUBBLES. Client-only: the shapes and layouts every bubble over
-- a head is drawn from, themed from the live palette.
--
--   speech   what a local player says over their head, in the gallery's System 7
--            balloon: stepped round corners, a 1-unit ink line, a hard shadow, a
--            wedge tail to the head; the line in Fira Mono Regular, in the case it was
--            said (the director, Nov 10 2026: lowercase reads easier, and on dyslexia).
--   thought  the action bar's VERBOSE layout inside a rounded bubble, a trail of
--            three small bubbles down to the head (ZeD_ActionBar.lua draws the
--            layout; the frame and the trail are drawn here).
--
-- Everything is in design units on whole multiples (ZeD.Px, k = ZeD.ActionBar.k()),
-- head-relative: (0, 0) is the top of the head (ZeD.ActionBar.headScreen). Colours
-- are ZeD.T tokens read every frame; the shadow (black, no token) is synced like
-- the action bar's dim colour. ZeDUI/mockups/zed_bubbles_v1/bubbles.py draws the
-- same pixels; the shapes below are ported from it one for one.
--
-- The speech hook. Every line the engine puts over a character's head goes
-- through its chat element (IsoGameCharacter.Say, SayShout, typed chat in
-- multiplayer, Java and Lua callers alike); Lua reads the newest one with
-- getSayLine(). The chat element itself is not exposed to Lua, so the engine's
-- drawing is stopped from the character's side: the line is read, then pushed
-- out of the five lines the engine keeps over a player's head with empty lines
-- (addLineChatElement("")), which the engine skips when it draws. The empty
-- lines keep the engine's own clock, so isSpeaking() says how long vanilla would
-- have shown the line. Radio and TV lines over the head (a held radio: SayRadio)
-- are left to the engine: a line that a device has just sent (OnDeviceText) is
-- not taken. Local players only; other players' speech stays the engine's.
-- ============================================================================

require "ZeD/ZeD_PixelParts"

ZeD = ZeD or {}
ZeD.Bubbles = ZeD.Bubbles or {}
local B = ZeD.Bubbles
local P = ZeD.Px

-- The punctuation speech needs, as bubbles.py draws it. PixelFonts.lua is generated from the dashboards'
-- tools (ZeDUI/tools/dashpx/engine.py F35 / F57) and rewritten on every export, so the glyphs are set here,
-- over the faces as loaded (before anything is drawn: the shelf caches glyphs on first use). They replace
-- PixelFontsExt's " (5 x 7) and ? (3 x 5), which differ by a row.
do
    local F = ZeD.PixelFonts
    local G = {
        ["57"] = { ["!"] = { "1", "1", "1", "1", "1", "0", "1" }, ["?"] = { "01110", "10001", "00001", "00110", "00100", "00000", "00100" },
                   [","] = { "00", "00", "00", "00", "00", "01", "10" }, ['"'] = { "101", "101", "000", "000", "000", "000", "000" } },
        ["35"] = { ["!"] = { "1", "1", "1", "0", "1" }, ["?"] = { "111", "001", "010", "000", "010" }, [","] = { "00", "00", "00", "01", "10" },
                   ["&"] = { "010", "101", "010", "101", "011" }, ["|"] = { "1", "1", "1", "1", "1" } },
    }
    for face, glyphs in pairs(G) do
        if F and F[face] then for ch, rows in pairs(glyphs) do F[face][ch] = rows end end
    end
end

-- ---------------------------------------------------------------------------
-- tuning (design units / ms)
-- ---------------------------------------------------------------------------
B.SPEECH_MAXW = 120      -- a balloon's line wraps here
B.SIDE_MAXW = 96         -- ... and here when it sits beside the thought bubble
B.PAD = 5                -- balloon padding
B.LINE = 13              -- line pitch: Fira Mono's line (77 on its 64 face) at B.FONT_PX
B.FONT_PX = 11           -- the balloons' text: Fira Mono Regular (F3 Data, its distance-field face), in units
B.TRIM = 3               -- the face's line box starts this far above its capitals: the padding gives it back
B.GAP = 3                -- head top to the tail tip / the trail's end
B.TAIL_H = 9
B.THOUGHT_PAD = 7
B.THOUGHT_H = 36         -- the action bar's two lines and its 6-unit framed strip,
                         -- plus two units between the lines for the item name's tall accents
B.TRAIL_H = 15
B.MIN_MS = 800           -- a balloon shows at least this long, then as long as the engine's line would (B.current)
B.MAX_MS = 20000
B.WIPE = 5               -- the lines the engine keeps over a player's head (ChatElement maxChatLines)
B.DEVICE_MS = 2000       -- a line a device sent this recently is the device's, not the character's

-- ---------------------------------------------------------------------------
-- small shapes
-- ---------------------------------------------------------------------------
local function rectA(cv, x, y, w, h, c, a) P.rect(cv, x, y, w, h, c, (c.a or 1) * (a or 1)) end
local function rectsA(cv, list, c, a, dx, dy) P.rects(cv, list, c, (c.a or 1) * (a or 1), dx, dy) end

-- a run list {x, y, w, 1, ...}: a cell joins the run it continues on the same row
local function addCell(list, x, y)
    local n = #list
    if n > 0 and list[n - 2] == y and list[n - 3] + list[n - 1] == x then list[n - 1] = list[n - 1] + 1; return end
    list[n + 1], list[n + 2], list[n + 3], list[n + 4] = x, y, 1, 1
end

-- the rows of a stepped round box are trimmed 2, 1 at each end
local function inset(j, hh)
    if j < 2 then return j == 0 and 2 or 1 end
    local r = hh - 1 - j
    if r < 2 then return r == 0 and 2 or 1 end
    return 0
end
local function boxRows(cv, x0, y0, ww, hh, c, a)
    local j = 0
    while j < hh do
        local cIn = inset(j, hh)
        local j2 = j + 1
        while j2 < hh and inset(j2, hh) == cIn do j2 = j2 + 1 end
        rectA(cv, x0 + cIn, y0 + j, ww - 2 * cIn, j2 - j, c, a)
        j = j2
    end
end
-- bubbles.py round_box: the ink rows, the fill rows over them (with the shadow colour for both, the
-- inside takes the shadow twice, as bubbles.py has it)
function B.roundBox(cv, x, y, w, h, fill, ink, a)
    boxRows(cv, x, y, w, h, ink, a)
    boxRows(cv, x + 1, y + 1, w - 2, h - 2, fill, a)
end

-- the thought bubble's body: corner radius 10.5 (the ends nearly half round), its ink the cells on its edge;
-- a taller cloud (the moodles' notes) passes its own radius
B._clouds = B._clouds or {}
local function cloudLists(w, h, r)
    local Rr = r or 10.5
    local key = (w * 1000 + h) * 100 + math.floor(Rr * 2)
    local c = B._clouds[key]
    if c then return c end
    local m = {}
    for Y = 0, h - 1 do
        local row = {}
        for X = 0, w - 1 do
            local cx, cy = X + 0.5, Y + 0.5
            local dx = cx - math.min(math.max(cx, Rr), w - Rr)
            local dy = cy - math.min(math.max(cy, Rr), h - Rr)
            row[X] = dx * dx + dy * dy <= Rr * Rr
        end
        m[Y] = row
    end
    c = { all = {}, ink = {}, fill = {} }
    for Y = 0, h - 1 do
        local row = m[Y]
        for X = 0, w - 1 do
            if row[X] then
                addCell(c.all, X, Y)
                local edge = X == 0 or X == w - 1 or Y == 0 or Y == h - 1
                    or not (row[X - 1] and row[X + 1] and m[Y - 1][X] and m[Y + 1][X])
                if edge then addCell(c.ink, X, Y) else addCell(c.fill, X, Y) end
            end
        end
    end
    B._clouds[key] = c
    return c
end

-- the trail: hand-set bubbles (# ink, o fill), biggest first, each at its top-left from the trail's
-- origin: down to the head (the action bar's), or in a row to the right or left (the moodles'
-- notes), the biggest next to the cloud. B.TRAIL_LEN units from the origin to the far end.
local TRAIL = {
    { ".###.", "#ooo#", "#ooo#", "#ooo#", ".###." },
    { ".##.", "#oo#", "#oo#", ".##." },
    { "##", "##" },
}
B.TRAIL_LEN = 13
local function trailAt(pos)
    local out = {}
    for t = 1, #TRAIL do
        local pat, bx, by = TRAIL[t], pos[t][1], pos[t][2]
        local L = { sh = {}, ink = {}, fill = {} }
        for j = 1, #pat do
            for i = 1, #pat[j] do
                local ch = pat[j]:sub(i, i)
                if ch ~= "." then addCell(L.sh, bx + i, by + j) end
                if ch == "#" then addCell(L.ink, bx + i - 1, by + j - 1) elseif ch == "o" then addCell(L.fill, bx + i - 1, by + j - 1) end
            end
        end
        out[t] = L
    end
    return out
end
local TRAILS = {
    down = trailAt({ { 3, 0 }, { 1, 6 }, { -1, 11 } }),
    right = trailAt({ { 0, -2 }, { 6, -2 }, { 11, -1 } }),
    left = trailAt({ { -5, -2 }, { -10, -2 }, { -13, -1 } }),
}

-- ---------------------------------------------------------------------------
-- the tail: bubbles.py wedge_mask, a triangle on the unit grid. Rasterised the way bubbles.py's
-- drawing library does (a 4 x 4 grid of samples per unit, a cell is in when 7 of 16 are), so the
-- edge pixels match its art.
-- ---------------------------------------------------------------------------
local function trunc(v) if v >= 0 then return math.floor(v) end return math.ceil(v) end
local function wedge(pts)
    local minx, maxx = math.min(pts[1], pts[3], pts[5]), math.max(pts[1], pts[3], pts[5])
    local miny, maxy = math.min(pts[2], pts[4], pts[6]), math.max(pts[2], pts[4], pts[6])
    local x0, y0 = trunc(minx) - 2, trunc(miny) - 2
    local W = trunc(maxx) - x0 + 3
    local px, py = {}, {}
    for i = 1, 3 do px[i] = (pts[2 * i - 1] - x0) * 4; py[i] = (pts[2 * i] - y0) * 4 end
    local hi, edges = {}, {}
    local gy0, gy1 = math.min(py[1], py[2], py[3]), math.max(py[1], py[2], py[3])
    for i = 1, 3 do
        local j = i % 3 + 1
        local xa, ya, xb, yb = px[i], py[i], px[j], py[j]
        if ya == yb then
            for x = math.ceil(math.min(xa, xb)), math.floor(math.max(xa, xb)) do hi[ya * 4096 + x] = true end
        else
            if ya > yb then xa, ya, xb, yb = xb, yb, xa, ya end
            edges[#edges + 1] = { xa, ya, xb, yb, (xb - xa) / (yb - ya) }
        end
    end
    for y = gy0, gy1 do
        local xx = {}
        for e = 1, #edges do
            local E = edges[e]
            if E[2] <= y and y <= E[4] then
                xx[#xx + 1] = (y - E[2]) * E[5] + E[1]
                if y == E[4] and y < gy1 then xx[#xx + 1] = xx[#xx] end
            end
        end
        table.sort(xx)
        for i = 2, #xx, 2 do
            for x = math.floor(xx[i - 1] + 0.5), math.ceil(xx[i] - 0.5) do
                if x >= 0 and x < W * 4 then hi[y * 4096 + x] = true end
            end
        end
    end
    local cnt = {}
    for key, _ in pairs(hi) do
        local y = math.floor(key / 4096)
        local x = key - y * 4096
        local ck = (math.floor(y / 4) + y0 + 512) * 2048 + math.floor(x / 4) + x0 + 1024
        cnt[ck] = (cnt[ck] or 0) + 1
    end
    local cells = {}
    for ck, n in pairs(cnt) do
        if n >= 7 then
            local Y = math.floor(ck / 2048)
            cells[(Y - 512) .. "," .. (ck - Y * 2048 - 1024)] = true
        end
    end
    return cells
end
-- where the rule above and bubbles.py's library part on an exact half (one cell, at these balloon
-- places): the beside-the-thought tail by its balloon's left edge -> { x, y, in }
local TAIL_FIX = {
    [41] = { { 34, -5, true } }, [46] = { { 18, 2, false } }, [65] = { { 52, -5, true } }, [82] = { { 27, 2, false } },
    [126] = { { 38, 2, false } }, [141] = { { 109, -5, true } }, [154] = { { 45, 2, false } }, [155] = { { 50, 2, false } },
    [157] = { { 51, 2, true } }, [169] = { { 130, -5, true } }, [235] = { { 70, 2, false } },
    [237] = { { 181, -5, true }, { 66, 2, true } }, [239] = { { 71, 2, true } }, [256] = { { 75, 2, false } },
}
-- the tail's runs: its shadow (below the body's bottom line `by`, +1 +1), its ink (the cells on its edge) and
-- its fill (inside, so the tail opens into the body); mirrored (x -> -x) for a balloon on the left
local function tailLists(cells, by, mirror)
    local xs, ys = {}, {}
    local minX, maxX, minY, maxY = 99999, -99999, 99999, -99999
    for key, _ in pairs(cells) do
        local c = key:find(",")
        local Y, X = tonumber(key:sub(1, c - 1)), tonumber(key:sub(c + 1))
        if X < minX then minX = X end
        if X > maxX then maxX = X end
        if Y < minY then minY = Y end
        if Y > maxY then maxY = Y end
    end
    local T = { sh = {}, ink = {}, fill = {} }
    local function has(X, Y) return cells[Y .. "," .. X] == true end
    for Y = minY, maxY do
        local a, b, s = minX, maxX, 1
        if mirror then a, b, s = maxX, minX, -1 end
        for X = a, b, s do
            if has(X, Y) then
                local XX = mirror and -X or X
                if Y > by then addCell(T.sh, XX + 1, Y + 1) end
                if Y >= by then
                    if has(X - 1, Y) and has(X + 1, Y) and has(X, Y - 1) and has(X, Y + 1) then addCell(T.fill, XX, Y)
                    else addCell(T.ink, XX, Y) end
                end
            end
        end
    end
    if mirror then minX, maxX = -maxX, -minX end
    T.x0, T.x1, T.y0, T.y1 = minX, maxX + 3, by, maxY + 3      -- its box, with the shadow
    return T
end
B._tails = B._tails or {}
-- the tail of a balloon over the head: a 10-wide base a third along the body's bottom line, its point 1 unit
-- above the head top (the same for a balloon flipped left: the base still sits over the head)
function B.speechTail()
    local t = B._tails.speech
    if not t then t = tailLists(wedge({ -5, -13, 6, -13, 0.5, 0 }), -13, false); B._tails.speech = t end
    return t
end
-- the tail of a balloon beside the thought bubble (left edge x, bottom line at -8): from its lower-left
-- corner to the right side of the head; `mirror` for the balloon flipped to the left (x is then the
-- mirrored balloon's left edge)
function B.sideTail(x, mirror)
    local key = x * 2 + (mirror and 1 or 0)
    local t = B._tails[key]
    if t then return t end
    local cells = wedge({ x + 2, -8, x + 21, -8, 8.5, 6 })
    local fix = TAIL_FIX[x]
    if fix then
        for i = 1, #fix do cells[fix[i][2] .. "," .. fix[i][1]] = fix[i][3] or nil end
    end
    t = tailLists(cells, -8, mirror)
    B._tails[key] = t
    return t
end

-- ---------------------------------------------------------------------------
-- text
-- ---------------------------------------------------------------------------
-- the chat markup a multiplayer line can carry taken off, spaces collapsed; the case as it was said
function B.clean(s)
    s = tostring(s or "")
    s = s:gsub("%[/?%a+[^%]]*%]", "")
    s = s:gsub("<[^<>]*>", "")
    s = s:gsub("%s+", " ")
    s = s:gsub("^ ", "")
    s = s:gsub(" $", "")
    return s
end

-- The balloons' face: ZeD's Fira Mono Regular distance-field entry (ZeD.Font.sdf.stat; ZeD.Text.checkRoleFonts points
-- it at the game's stand-in under Chinese, Japanese, Korean, Thai or the Dyslexic font). A line with letters the face
-- lacks measures and draws in the face that has them, whichever of the two it is (ZeD.Text.faceFor): Chinese said
-- under Simplified Chinese draws in Noto Sans SC, since the game's Chinese stand-in has no simplified-only letters.
-- A line is wrapped at its spaces only, so Chinese, written without them, stays one line however long. Without
-- ZeD.Text (a sim, or before it loads) the 5 x 7 face measures and draws, as before.
local function face()
    local X, F = ZeD.Text, ZeD.Font
    local f = F and F.sdf and F.sdf.stat
    if f and X and X.width and X.draw and X.realTM then return f, X end
    return nil
end
-- a line's width in units
function B.textW(str)
    local f, X = face()
    if f then
        local ok, w = pcall(X.width, f, str, B.FONT_PX / (f.face or 64))
        if ok and type(w) == "number" then return math.ceil(w) end
    end
    return P.textWidth(str, "57", 1)
end
-- a balloon's height for n lines
function B.boxH(n) return n * B.LINE + (B.PAD - B.TRIM) * 2 end
-- a line drawn at (x, y) units, y where its capitals start (align "l" | "c"), alpha a
function B.drawLine(cv, str, x, y, c, a, align)
    local f, X = face()
    if f then
        local k = cv.k
        local ok = pcall(X.draw, cv.el, f, str, cv.ox + x * k, cv.oy + (y - B.TRIM) * k, B.FONT_PX * k / (f.face or 64),
            c.r, c.g, c.b, a, align)
        if ok then return end
    end
    local el = cv.el
    el._zedAlpha = a
    P.text(cv, str, x, y, c, "57", 1, align, nil, nil)
    el._zedAlpha = 1
end
-- words to lines no wider than maxw (a word wider than that stands alone); the widest line's width
-- (pixel: measure in the 5 x 7 face, for a caller that draws in it: RtvFace's screens)
function B.wrap(text, maxw, pixel)
    local tw = pixel and function(t) return P.textWidth(t, "57", 1) end or B.textW
    local lines, cur = {}, ""
    for w in string.gmatch(text, "%S+") do
        local nxt = (cur == "") and w or (cur .. " " .. w)
        if cur == "" or tw(nxt) <= maxw then cur = nxt
        else lines[#lines + 1] = cur; cur = w end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    local w = 0
    for i = 1, #lines do w = math.max(w, tw(lines[i])) end
    return lines, w
end

-- ---------------------------------------------------------------------------
-- layout: where everything goes, in head-relative units
-- ---------------------------------------------------------------------------
-- the thought bubble for a verbose layout iw wide: 6 units right of centre over the head, its bottom 18 above it
function B.thoughtBox(iw)
    local w = iw + B.THOUGHT_PAD * 2
    return -math.floor(w / 2) + 6, -B.GAP - B.TRAIL_H - B.THOUGHT_H, w, B.THOUGHT_H
end
-- the simple bar's box (ZeD_ActionBar: W x H, AB.GAP above the head), for a balloon beside it
local function simpleBox(W, H, gap) return -math.floor(W / 2), -(gap + H), W, gap + H - B.GAP end

-- L (reused): bar = "thought" | "simple" | nil (with iw, or W H gap for simple); sp = the speech or nil;
-- rightU = the screen's right edge in units from the head (a balloon past it goes to the other side).
-- Sets L.tx.. (thought), L.sx, L.sy, L.sw, L.sh, L.lines, L.tail (speech) and the box L.x0 L.y0 L.x1 L.y1.
function B.layout(L, bar, iw, sp, rightU, W, H, gap)
    L.bar, L.sp = bar, sp
    local x0, y0, x1, y1 = 0, 0, 0, 0
    local bx, byy, bw, bh = nil, nil, nil, nil
    if bar == "thought" then
        local x, y, w, h = B.thoughtBox(iw)
        L.tx, L.ty, L.tw, L.th, L.iw = x, y, w, h, iw
        bx, byy, bw, bh = x, y, w, h + B.TRAIL_H
        x0, y0, x1, y1 = math.min(x, -1), y, math.max(x + w + 2, 9), -2
    elseif bar == "simple" then
        bx, byy, bw, bh = simpleBox(W, H, gap)
        x0, y0, x1, y1 = bx - 1, byy, bx + bw + 1, byy + H
    end
    if sp then
        local lines, tw = sp.lines, sp.tw
        if bx then lines, tw = sp.sideLines, sp.sideW end
        local w, h = tw + B.PAD * 2, B.boxH(#lines)
        local x, y, tail
        if bx then
            x, y = bx + bw + 2, byy + bh - 4 - h
            if rightU and x + w + 2 > rightU then
                x = bx - 2 - w
                tail = B.sideTail(-(x + w - 1), true)
            else
                tail = B.sideTail(x, false)
            end
        else
            x, y = -math.floor(w / 3), -B.GAP - B.TAIL_H - h
            if rightU and x + w + 2 > rightU then x = -math.floor(2 * w / 3) end
            tail = B.speechTail()
        end
        L.sx, L.sy, L.sw, L.sh, L.lines, L.tail = x, y, w, h, lines, tail
        local sx0, sy0 = math.min(x, tail.x0), y
        local sx1, sy1 = math.max(x + w + 2, tail.x1), math.max(y + h + 2, tail.y1)
        if bar then
            x0, y0, x1, y1 = math.min(x0, sx0), math.min(y0, sy0), math.max(x1, sx1), math.max(y1, sy1)
        else
            x0, y0, x1, y1 = sx0, sy0, sx1, sy1
        end
    end
    L.x0, L.y0, L.x1, L.y1 = x0, y0, x1, y1
    return L
end

-- ---------------------------------------------------------------------------
-- drawing (T = ZeD.T, read by the caller this frame; B._shadow synced by B.syncColours)
-- ---------------------------------------------------------------------------
-- The shadow is System 7's hard one (cohesion spec: 1 unit right and down, black at 0.5); only the part outside the
-- bubble shows. The bubbles are HUD pieces, so their body stays solid whatever the See-through setting is: B.solid
-- holds opaque copies of the surface tokens the bubbles and the action bar fill with, synced in place each frame.
B.SHADOW_A = 0.5
B._shadow = B._shadow or { r = 0, g = 0, b = 0, a = 0.5 }
B.solid = B.solid or { base = { r = 0, g = 0, b = 0, a = 1 }, surf1 = { r = 0, g = 0, b = 0, a = 1 }, surf3 = { r = 0, g = 0, b = 0, a = 1 } }
local function solidCopy(d, c) d.r, d.g, d.b, d.a = c.r, c.g, c.b, 1 end
function B.syncColours(T)
    B._shadow.a = B.SHADOW_A
    local s = B.solid
    solidCopy(s.base, T.base); solidCopy(s.surf1, T.surf1); solidCopy(s.surf3, T.surf3)
end

-- A thought bubble anywhere, in three passes so the trail tucks under the cloud: the cloud's shadow,
-- the trail (it may be on its own canvas, at another zoom), the cloud. x, y, w, h in units on cv;
-- r the corner radius (10.5 when nil); the trail from (ox, oy) running dir ("down" | "right" | "left").
function B.cloudShadow(cv, x, y, w, h, a, r)
    rectsA(cv, cloudLists(w, h, r).all, B._shadow, a, x + 1, y + 1)
end
function B.drawTrail(cv, T, dir, ox, oy, a)
    local sh = B._shadow
    local trail = TRAILS[dir] or TRAILS.down
    for t = 1, #trail do
        local TL = trail[t]
        rectsA(cv, TL.sh, sh, a, ox, oy)
        rectsA(cv, TL.ink, T.borderS, a, ox, oy)
        rectsA(cv, TL.fill, B.solid.surf1, a, ox, oy)
    end
end
function B.cloudBody(cv, T, x, y, w, h, a, r)
    local cl = cloudLists(w, h, r)
    rectsA(cv, cl.ink, T.borderS, a, x, y)
    rectsA(cv, cl.fill, B.solid.surf1, a, x, y)
end

-- the thought bubble's frame and trail (the layout inside is ZeD.ActionBar's)
function B.drawThought(cv, T, L, a)
    local x, y, w, h = L.tx, L.ty, L.tw, L.th
    B.cloudShadow(cv, x, y, w, h, a)
    B.drawTrail(cv, T, "down", x + math.floor(w / 2) - 6, y + h + 2, a)
    B.cloudBody(cv, T, x, y, w, h, a)
end

-- the speech balloon: shadow, tail shadow, body, tail (opening into the body), the lines centred
function B.drawSpeech(cv, T, L, a)
    local x, y, w, h, tail = L.sx, L.sy, L.sw, L.sh, L.tail
    local sh = B._shadow
    B.roundBox(cv, x + 1, y + 1, w, h, sh, sh, a)
    rectsA(cv, tail.sh, sh, a, 0, 0)
    B.roundBox(cv, x, y, w, h, B.solid.surf1, T.borderS, a)
    rectsA(cv, tail.ink, T.borderS, a, 0, 0)
    rectsA(cv, tail.fill, B.solid.surf1, a, 0, 0)
    local lines = L.lines
    for i = 1, #lines do
        B.drawLine(cv, lines[i], x + math.floor(w / 2), y + B.PAD + (i - 1) * B.LINE, T.text, a * (T.text.a or 1), "c")
    end
end

-- ---------------------------------------------------------------------------
-- OVERHEAD NOTES. The game's red and green lines over the head ("Too heavy", "Can't
-- reach") were nearly unreadable: they become this same balloon, and the Messages window logs them too
-- (ZeD_HaloText.lua hands each line to both). A note is the speech balloon without its tail: the line in the balloons' face, a status mark before it
-- (positive for good news, danger for bad, none for plain), never coloured text. Up to NOTE_N stack above whatever is
-- over the head, the newest nearest; each holds NOTE_MS and fades over NOTE_FADE_MS. The same line again while it
-- shows starts its clock again instead of stacking.
-- ---------------------------------------------------------------------------
B.NOTE_N = 3
B.NOTE_MS = 2600
B.NOTE_FADE_MS = 500
B.NOTE_MAXW = 120
B.NOTE_GAP = 3            -- between stacked notes, and above what is under them
B.NOTE_DOT = 3            -- the status mark (units), and its gap to the text
B._notes = B._notes or {}  -- playerNum -> { { text, lines, tw, tone, ms }, ... } oldest first

-- a note for a player: tone "good" | "bad" | nil
function B.note(pn, text, tone)
    local t = B.clean(text)
    if t == "" then return nil end
    local list = B._notes[pn]
    if not list then list = {}; B._notes[pn] = list end
    local ms = getTimestampMs()
    for i = #list, 1, -1 do
        if list[i].text == t and list[i].tone == tone then
            local n = table.remove(list, i)
            n.ms = ms
            list[#list + 1] = n
            return n
        end
    end
    local lines, tw = B.wrap(t, B.NOTE_MAXW)
    local n = { text = t, lines = lines, tw = tw, tone = tone, ms = ms }
    list[#list + 1] = n
    while #list > B.NOTE_N do table.remove(list, 1) end
    return n
end

-- the notes to draw for a player now (each with .a, its alpha), or nil
function B.notes(pn, ms)
    local list = B._notes[pn]
    if not list or #list == 0 then return nil end
    for i = #list, 1, -1 do
        local t = ms - list[i].ms
        if t >= B.NOTE_MS + B.NOTE_FADE_MS then table.remove(list, i)
        else list[i].a = (t > B.NOTE_MS) and (1 - (t - B.NOTE_MS) / B.NOTE_FADE_MS) or 1 end
    end
    if #list == 0 then return nil end
    return list
end

-- the notes' boxes above what B.layout placed (or above the head), the newest nearest; grows L's box.
-- rightU as for B.layout. Sets each note's .x .y .w .h.
function B.layoutNotes(L, notes, rightU)
    if not notes then L.notes = nil; return L end
    L.notes = notes
    local any = L.bar or L.sp
    local base = any and L.y0 or -B.GAP
    local x0, y0, x1, y1 = L.x0, L.y0, L.x1, L.y1
    if not any then x0, y0, x1, y1 = 0, -B.GAP, 0, -B.GAP end
    for i = #notes, 1, -1 do
        local n = notes[i]
        local w = n.tw + B.PAD * 2 + (n.tone and (B.NOTE_DOT * 2) or 0)
        local h = B.boxH(#n.lines)
        local x = -math.floor(w / 2)
        if rightU and x + w + 2 > rightU then x = rightU - w - 2 end
        local y = base - B.NOTE_GAP - h
        n.x, n.y, n.w, n.h = x, y, w, h
        base = y
        x0, y0, x1 = math.min(x0, x), math.min(y0, y), math.max(x1, x + w + 2)
        y1 = math.max(y1, y + h + 2)
    end
    L.x0, L.y0, L.x1, L.y1 = x0, y0, x1, y1
    return L
end

-- the notes: shadow, body, the status mark, the lines
function B.drawNotes(cv, T, L)
    local notes = L.notes
    if not notes then return end
    local sh = B._shadow
    for i = 1, #notes do
        local n = notes[i]
        local a = n.a or 1
        B.roundBox(cv, n.x + 1, n.y + 1, n.w, n.h, sh, sh, a)
        B.roundBox(cv, n.x, n.y, n.w, n.h, B.solid.surf1, T.borderS, a)
        local tx = n.x + B.PAD
        if n.tone then
            local c = (n.tone == "good") and T.positive or T.danger
            rectA(cv, tx, n.y + B.PAD + 3, B.NOTE_DOT, B.NOTE_DOT, c, a)
            tx = tx + B.NOTE_DOT * 2
        end
        for j = 1, #n.lines do
            B.drawLine(cv, n.lines[j], tx, n.y + B.PAD + (j - 1) * B.LINE, T.text, a * (T.text.a or 1), "l")
        end
    end
end

-- ---------------------------------------------------------------------------
-- THE NOTICES. Every notice is a speech or thought bubble popping out of the one notification icon that keeps
-- errors and other mods' pop-ups, so they all come from one place. ZeD's
-- notices (ZeD_Messages' toasts: a mod's note kept, an error, a ticket, an invitation, a controller plugged in or
-- unplugged) are speech balloons stacked over the Messages note on the belt, the newest nearest it with the tail
-- down to the note; ZeD_MessagesWindow places and draws them. Units are the bubbles' own, from the anchor (the top
-- middle of the note): the balloon stays on the screen, and the tail's base stays under the balloon.
-- ---------------------------------------------------------------------------
B.NOTICE_MAXW = 150      -- a notice's line wraps here
B.NOTICE_LINES = 4       -- past this the last line kept ends "..."
B.NOTICE_LONG_MAXW = 230  -- a long notice's line wraps here (the survival guide's bubble)
B.NOTICE_LONG_LINES = 9   -- and keeps this many lines
B.NOTICE_EDGE = 4        -- from the screen's edge

-- a notice's lines: what it is (its head), then what it is about, in the balloon's face; and the widest one
function B.noticeLines(head, body, long)
    local lines, tw = {}, 0
    -- (a long notice, the survival guide's bubble, wraps wider and keeps more lines; the others are as before)
    local maxW = long and B.NOTICE_LONG_MAXW or B.NOTICE_MAXW
    local maxLines = long and B.NOTICE_LONG_LINES or B.NOTICE_LINES
    for _, part in ipairs({ head or "", body or "" }) do
        local t = B.clean(part)
        if t ~= "" then
            local ls = B.wrap(t, maxW)
            for i = 1, #ls do lines[#lines + 1] = ls[i] end
        end
    end
    if #lines > maxLines then
        while #lines > maxLines do table.remove(lines) end
        lines[#lines] = lines[#lines] .. "..."
    end
    for i = 1, #lines do tw = math.max(tw, B.textW(lines[i])) end
    return lines, tw
end

-- the balloons for notices (oldest first, each { lines, tw, dot }): each gets .x .y .w .h; the last one (the
-- newest) sits lowest, its tail to the anchor when tail is set. leftU / rightU: the screen's edges in units from
-- the anchor. Returns the box over all of them (x0, y0, x1, y1).
function B.layoutNoticeBalloons(list, leftU, rightU, tail)
    local base = tail and (-B.GAP - B.TAIL_H) or -B.GAP
    local x0, y0, x1, y1 = 0, base, 0, 0
    local loE, hiE = (leftU or -100000) + B.NOTICE_EDGE, (rightU or 100000) - B.NOTICE_EDGE
    for i = #list, 1, -1 do
        local n = list[i]
        local w = n.tw + B.PAD * 2 + (n.dot and (B.NOTE_DOT * 2) or 0)
        local h = B.boxH(#n.lines)
        local x = -math.floor(w / 3)
        if tail and i == #list then
            -- the tail's base (-5 .. 6) stays inside the balloon, 3 units in from each end
            x = math.max(9 - w, math.min(-8, x))
        end
        -- then the screen wins
        if x + w + 2 > hiE then x = hiE - w - 2 end
        if x < loE then x = loE end
        local y = base - h
        n.x, n.y, n.w, n.h = x, y, w, h
        base = y - B.NOTE_GAP
        x0, y0, x1 = math.min(x0, x), math.min(y0, y), math.max(x1, x + w + 2)
    end
    if tail and #list > 0 then x0, x1 = math.min(x0, -6), math.max(x1, 8) end
    return x0, y0, x1, y1
end

-- the balloons: shadow, body, the status mark, the lines; the newest one's tail (tail set) to the anchor
function B.drawNoticeBalloons(cv, T, list, tail, a)
    local sh = B._shadow
    a = a or 1
    for i = 1, #list do
        local n = list[i]
        B.roundBox(cv, n.x + 1, n.y + 1, n.w, n.h, sh, sh, a)
        if tail and i == #list then rectsA(cv, B.speechTail().sh, sh, a, 0, 0) end
        B.roundBox(cv, n.x, n.y, n.w, n.h, B.solid.surf1, T.borderS, a)
        if tail and i == #list then
            local tl = B.speechTail()
            rectsA(cv, tl.ink, T.borderS, a, 0, 0)
            rectsA(cv, tl.fill, B.solid.surf1, a, 0, 0)
        end
        local tx = n.x + B.PAD
        if n.dot then
            rectA(cv, tx, n.y + B.PAD + 3, B.NOTE_DOT, B.NOTE_DOT, n.dot, a)
            tx = tx + B.NOTE_DOT * 2
        end
        for j = 1, #n.lines do
            B.drawLine(cv, n.lines[j], tx, n.y + B.PAD + (j - 1) * B.LINE, T.text, a * (T.text.a or 1), "l")
        end
    end
end

-- ---------------------------------------------------------------------------
-- the speech hook (see the header)
-- ---------------------------------------------------------------------------
B._sp = B._sp or {}       -- playerNum -> { text, lines, tw, sideLines, sideW, ms, endMs }
B._skip = B._skip or {}   -- playerNum -> a line left to the engine (a device's)
B._dev = B._dev or {}     -- the last lines devices sent: { text, ms }, oldest dropped first
B._devHead = B._devHead or 0
local DEV_N = 8

local function nowMs() return getTimestampMs() end

function B.onDeviceText(_guid, _codes, _x, _y, _z, line)
    if type(line) ~= "string" or line == "" then return end
    B._devHead = B._devHead % DEV_N + 1
    B._dev[B._devHead] = { line, nowMs() }
end
local function fromDevice(line)
    local t = nowMs()
    for i = 1, DEV_N do
        local d = B._dev[i]
        if d and t - d[2] <= B.DEVICE_MS and d[1] == line then return true end
    end
    return false
end

-- a line to show for a player (the hook calls it; a QA script may too)
function B.say(pn, text)
    local t = B.clean(text)
    if t == "" then B._sp[pn] = nil; return nil end
    local lines, tw = B.wrap(t, B.SPEECH_MAXW)
    local sl, sw = B.wrap(t, B.SIDE_MAXW)
    local sp = { text = t, lines = lines, tw = tw, sideLines = sl, sideW = sw, ms = nowMs() }
    B._sp[pn] = sp
    return sp
end

-- reads the newest line over a local player's head and takes it from the engine
function B.poll(pn, chr)
    if ZeD.Safe and ZeD.Safe.on() then return end
    local ok, line = pcall(chr.getSayLine, chr)
    if not ok or line == nil or line == "" then B._skip[pn] = nil; return end
    if B._skip[pn] == line then return end
    if fromDevice(line) then B._skip[pn] = line; return end
    for _ = 1, B.WIPE do pcall(chr.addLineChatElement, chr, "") end
    B._skip[pn] = nil
    B.say(pn, line)
end

-- the speech to draw for a player now and its alpha, or nil
-- The engine's timing, read from it: its chat element says "speaking" for the first half of a line's
-- display time (ChatElement.updateChatLines: clock / (lineDisplayTime / 2) >= 1) and draws the line until
-- the end, fading it over the last quarter. So when isSpeaking() turns false after D ms, the balloon
-- holds to 1.5 D and fades out by 2 D, as the engine's line would have (game speed included).
-- (isSpeaking() is read on the game tick, after the engine's update: read while drawing, it lagged by a
-- second and more)
function B.watch(pn, chr, ms)
    local sp = B._sp[pn]
    if not sp or sp.half then return end
    local t = ms - sp.ms
    if t < B.MIN_MS then return end
    local ok, v = pcall(chr.isSpeaking, chr)
    if not (ok and v == true) or t > B.MAX_MS then sp.half = t end
end
function B.current(pn, chr, ms)
    local sp = B._sp[pn]
    if not sp then return nil end
    local t = ms - sp.ms
    if not sp.half and t > B.MAX_MS then sp.half = t end
    if sp.half then
        if t >= 2 * sp.half then B._sp[pn] = nil; return nil end
        if t > 1.5 * sp.half then return sp, (2 * sp.half - t) / (0.5 * sp.half) end
    end
    return sp, 1
end

local function pollAll()
    for pn = 0, getNumActivePlayers() - 1 do
        local chr = getSpecificPlayer(pn)
        if chr and chr:isLocalPlayer() and not chr:isDead() and not chr:isAsleep() then
            B.poll(pn, chr)
            B.watch(pn, chr, nowMs())
        end
    end
end
if Events and Events.OnTick and not B._hooked then
    B._hooked = true
    Events.OnTick.Add(function() pcall(pollAll) end)
    if Events.OnDeviceText then Events.OnDeviceText.Add(B.onDeviceText) end
    if Events.OnGameStart then Events.OnGameStart.Add(function() B._sp, B._skip, B._notes = {}, {}, {} end) end
end

return B
