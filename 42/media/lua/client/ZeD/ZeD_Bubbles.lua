-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Bubbles.lua
-- ============================================================================
-- THE OVERHEAD BUBBLES (Oct 24 2026; mockup ZeDUI/mockups/zed_bubbles_v1, approved
-- "Bubbles are good. Themed yes."; handoff ZeDUI/HANDOFF_bubbles_20261024.md).
--
--   speech   what a local player says over their head, in the gallery's System 7
--            balloon: stepped round corners, a 1-unit ink line, a hard shadow, a
--            wedge tail to the head; the line in the 5 x 7 face, in capitals.
--   thought  the action bar's VERBOSE layout inside a rounded bubble, a trail of
--            three small bubbles down to the head (ZeD_ActionBar.lua draws the
--            layout; the frame and the trail are drawn here).
--
-- Everything is in design units on whole multiples (ZeD.Px, k = ZeD.ActionBar.k()),
-- head-relative: (0, 0) is the top of the head (ZeD.ActionBar.headScreen). Colours
-- are ZeD.T tokens read every frame; the shadow (black, no token) is synced like
-- the action bar's dim colour. bubbles.py in the mockup folder draws the same
-- pixels; the shapes below are ported from it one for one.
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
B.LINE = 9               -- line pitch of the 5 x 7 face
B.GAP = 3                -- head top to the tail tip / the trail's end
B.TAIL_H = 9
B.THOUGHT_PAD = 7
B.THOUGHT_H = 30
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
-- inside takes the shadow twice, as in the mockup)
function B.roundBox(cv, x, y, w, h, fill, ink, a)
    boxRows(cv, x, y, w, h, ink, a)
    boxRows(cv, x + 1, y + 1, w - 2, h - 2, fill, a)
end

-- the thought bubble's body: corner radius 10.5 (the ends nearly half round), its ink the cells on its edge
B._clouds = B._clouds or {}
local function cloudLists(w, h)
    local key = w * 1000 + h
    local c = B._clouds[key]
    if c then return c end
    local Rr = 10.5
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

-- the trail: hand-set bubbles (# ink, o fill), their top-left from the trail's origin
local TRAIL = {
    { { ".###.", "#ooo#", "#ooo#", "#ooo#", ".###." }, 3, 0 },
    { { ".##.", "#oo#", "#oo#", ".##." }, 1, 6 },
    { { "##", "##" }, -1, 11 },
}
local TRAIL_LISTS = {}
for t = 1, #TRAIL do
    local pat, bx, by = TRAIL[t][1], TRAIL[t][2], TRAIL[t][3]
    local L = { sh = {}, ink = {}, fill = {} }
    for j = 1, #pat do
        for i = 1, #pat[j] do
            local ch = pat[j]:sub(i, i)
            if ch ~= "." then addCell(L.sh, bx + i, by + j) end
            if ch == "#" then addCell(L.ink, bx + i - 1, by + j - 1) elseif ch == "o" then addCell(L.fill, bx + i - 1, by + j - 1) end
        end
    end
    TRAIL_LISTS[t] = L
end

-- ---------------------------------------------------------------------------
-- the tail: bubbles.py wedge_mask, a triangle on the unit grid. Rasterised the way the mockup's
-- drawing library does (a 4 x 4 grid of samples per unit, a cell is in when 7 of 16 are), so the
-- edge pixels are the mockup's.
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
-- where the rule above and the mockup's library part on an exact half (one cell, at these balloon
-- places): the beside-the-thought tail by its balloon's left edge -> { x, y, in }
local TAIL_FIX = {
    [41] = { { 34, -5, true } }, [46] = { { 18, 2, false } }, [65] = { { 52, -5, true } }, [82] = { { 27, 2, false } },
    [126] = { { 38, 2, false } }, [141] = { { 109, -5, true } }, [154] = { { 45, 2, false } }, [155] = { { 50, 2, false } },
    [157] = { { 51, 2, true } }, [169] = { { 130, -5, true } }, [235] = { { 70, 2, false } },
    [237] = { { 181, -5, true }, { 66, 2, true } }, [239] = { { 71, 2, true } }, [256] = { { 75, 2, false } },
}
-- the tail's runs: its shadow (below the body's bottom line `by`, +2 +2), its ink (the cells on its edge) and
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
                if Y > by then addCell(T.sh, XX + 2, Y + 2) end
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
-- capitals, the chat markup a multiplayer line can carry taken off, spaces collapsed
function B.clean(s)
    s = tostring(s or "")
    s = s:gsub("%[/?%a+[^%]]*%]", "")
    s = s:gsub("<[^<>]*>", "")
    s = s:gsub("%s+", " ")
    s = s:gsub("^ ", "")
    s = s:gsub(" $", "")
    return ZeD.upper and ZeD.upper(s) or string.upper(s)
end
-- words to lines no wider than maxw (a word wider than that stands alone); the widest line's width
function B.wrap(text, maxw)
    local lines, cur = {}, ""
    for w in string.gmatch(text, "%S+") do
        local nxt = (cur == "") and w or (cur .. " " .. w)
        if cur == "" or P.textWidth(nxt, "57", 1) <= maxw then cur = nxt
        else lines[#lines + 1] = cur; cur = w end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    local tw = 0
    for i = 1, #lines do tw = math.max(tw, P.textWidth(lines[i], "57", 1)) end
    return lines, tw
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
        local w, h = tw + B.PAD * 2, #lines * B.LINE - 2 + B.PAD * 2
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
-- The shadow is solid black: the handoff names 35-45% alpha, but the approved picture
-- (zed_bubbles_v4_final.png) shows it solid (the mockup's alpha was dropped when the sheet was
-- flattened to RGB), and the picture is what was approved. One number to change if that is revisited.
B.SHADOW_A = 1
B._shadow = B._shadow or { r = 0, g = 0, b = 0, a = 1 }
function B.syncColours(T)
    B._shadow.a = B.SHADOW_A
end

-- the thought bubble's frame and trail (the layout inside is ZeD.ActionBar's)
function B.drawThought(cv, T, L, a)
    local x, y, w, h = L.tx, L.ty, L.tw, L.th
    local sh = B._shadow
    local cl = cloudLists(w, h)
    rectsA(cv, cl.all, sh, a, x + 2, y + 2)
    local ox, oy = x + math.floor(w / 2) - 6, y + h + 2
    for t = 1, #TRAIL_LISTS do
        local TL = TRAIL_LISTS[t]
        rectsA(cv, TL.sh, sh, a, ox, oy)
        rectsA(cv, TL.ink, T.borderS, a, ox, oy)
        rectsA(cv, TL.fill, T.surf1, a, ox, oy)
    end
    rectsA(cv, cl.ink, T.borderS, a, x, y)
    rectsA(cv, cl.fill, T.surf1, a, x, y)
end

-- the speech balloon: shadow, tail shadow, body, tail (opening into the body), the lines centred
function B.drawSpeech(cv, T, L, a)
    local x, y, w, h, tail = L.sx, L.sy, L.sw, L.sh, L.tail
    local sh = B._shadow
    B.roundBox(cv, x + 2, y + 2, w, h, sh, sh, a)
    rectsA(cv, tail.sh, sh, a, 0, 0)
    B.roundBox(cv, x, y, w, h, T.surf1, T.borderS, a)
    rectsA(cv, tail.ink, T.borderS, a, 0, 0)
    rectsA(cv, tail.fill, T.surf1, a, 0, 0)
    local lines = L.lines
    local el = cv.el
    el._zedAlpha = a * (T.text.a or 1)
    for i = 1, #lines do
        P.text(cv, lines[i], x + math.floor(w / 2), y + B.PAD + (i - 1) * B.LINE, T.text, "57", 1, "c", nil, nil)
    end
    el._zedAlpha = 1
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
-- (isSpeaking() is read on the game tick, after the engine's update: read while drawing it lagged by a
-- second and more, seen in game Oct 25 2026)
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
    if Events.OnGameStart then Events.OnGameStart.Add(function() B._sp, B._skip = {}, {} end) end
end

return B
