-- ZeD-UI/42/media/lua/client/ZeD/Balloon.lua
-- ============================================================================
-- BALLOON HELP: the one pop-up that explains a control. Client; an atom with
-- its own small state (which balloon is up). Every hover box draws through it:
-- the hint on an icon-only control, the detail card, the context strip's and
-- the context list's balloons, the requirement list on a greyed option, the
-- moodle note and ZeD_Tooltip.
--
-- The look is System 7's Balloon Help in the theme's colors: surface 2 at full
-- strength, the strong border (two hairlines in High contrast), the hard shadow,
-- square corners, and a 10-cell tail drawn on the hairline grid whose tip stops
-- one hairline short of the control. The balloon is placed from the control's
-- rectangle, never the pointer, and the tail is placed from its tip, so a box
-- that slides to stay on screen still points at its control.
--
-- Everything is measured with ZeD.TM in the live faces, scale and text size; a
-- layout is kept until the text or ZeD.Text.measureEpoch changes. One balloon
-- shows at a time (B.claim); Escape or the controller's B hides it until the
-- pointer or focus moves on (B.dismiss).
-- ============================================================================

ZeD = ZeD or {}
ZeD.Balloon = ZeD.Balloon or {}
local B = ZeD.Balloon

-- Design units. T.px already carries Large text's 1.15, so the caps grow with it.
B.HINT_W   = 200    -- the widest a one-line hint gets before it wraps
B.TITLE_W  = 320    -- the widest anything with a title gets
B.WIDEN    = 1.5    -- a word longer than the cap widens the box this far, then breaks
B.PAD_X, B.PAD_Y = 8, 5
B.GAP_T    = 3      -- after the title
B.LEAD     = 2      -- line step = the face's height + this
B.TAIL     = 10     -- the tail's depth in hairline cells
B.INSET    = 6      -- the tail's straight edge, in from the box's corner
B.MARGIN   = 4      -- kept inside the screen
B.TIP_IN   = 12     -- above a control, the tip this far into it (its middle when narrower)
B.PIC      = 32     -- the requirement balloon's picture
B.COL_GAP  = 8
B.MARK     = 7      -- the check and cross, in hairline cells
B.MARK_GAP = 4
B.MIN_VAL  = 60     -- the value column never gets narrower than this
B.STALE_MS = 150    -- a balloon not drawn for this long is down
B.WARM_MS  = 300    -- a neighbor's balloon shows at once while one was up this recently

local CHECK = { "......#", ".....##", "#...##.", "##.##..", ".###...", "..#....", "......." }
local CROSS = { "#.....#", "##...##", ".##.##.", "..###..", ".##.##.", "##...##", "#.....#" }
B.CHECK, B.CROSS = CHECK, CROSS

local function T_() return ZeD.T end
local function px(n) return ZeD.T.px(n) end
local function fontOf(k) return ZeD.T["font" .. k] or ZeD.T.fontF2 end
local function fh(k) return ZeD.TM:getFontHeight(fontOf(k)) end
local function mw(k, s) return ZeD.TM:MeasureStringX(fontOf(k), s) end
local function now() return getTimestampMs() end

-- ---------------------------------------------------------------------------
-- WORDS
-- ---------------------------------------------------------------------------

-- One character from i: its last index. In plain Lua a Cyrillic letter is a run of UTF-8 bytes; in the
-- game a string is characters, so i itself (the continuation range never follows a lead there).
local function charEnd(s, i)
    local b = s:byte(i)
    if not b or b < 0xC0 or b > 0xF7 then return i end
    local j = i
    while true do
        local c = s:byte(j + 1)
        if c and c >= 0x80 and c <= 0xBF then j = j + 1 else break end
    end
    return j
end
B._charEnd = charEnd

-- A word wider than maxW cut between characters; the pieces go on out, the last one is returned
-- (it may still take the next word on its line).
local function breakWord(word, k, maxW, out)
    local part, i, n = "", 1, #word
    while i <= n do
        local j = charEnd(word, i)
        local ch = word:sub(i, j)
        if part ~= "" and mw(k, part .. ch) > maxW then
            out[#out + 1] = part
            part = ch
        else
            part = part .. ch
        end
        i = j + 1
    end
    return part
end

local function wordsOf(s)
    local t = {}
    for w in tostring(s or ""):gmatch("%S+") do t[#t + 1] = w end
    return t
end

--- Wrap text at word breaks to maxW in face k ("F2", "F3", "F4"); a word wider than maxW
--- breaks between characters. Lines are measured whole (kerning makes a line more than its words).
function B.wrap(text, k, maxW)
    local out = {}
    -- (no capture: Kahlua hands an empty capture over as nil; an empty paragraph makes no line anyway)
    for para in tostring(text or ""):gmatch("[^\n]+") do
        local line = ""
        for _, w in ipairs(wordsOf(para)) do
            local test = (line == "") and w or (line .. " " .. w)
            if mw(k, test) <= maxW then
                line = test
            else
                if line ~= "" then out[#out + 1] = line end
                if mw(k, w) > maxW then line = breakWord(w, k, maxW, out) else line = w end
            end
        end
        if line ~= "" then out[#out + 1] = line end
    end
    return out
end

local function widestWord(text, k, acc)
    for _, w in ipairs(wordsOf(text)) do
        local x = mw(k, w)
        if x > acc then acc = x end
    end
    return acc
end

local function widestLine(text, k, acc)
    for para in tostring(text or ""):gmatch("[^\n]+") do
        local x = mw(k, para)
        if x > acc then acc = x end
    end
    return acc
end

-- ---------------------------------------------------------------------------
-- CONTENT
-- content = {
--   kind  = "plain" (a one-line hint: F2, capped at 200u) | "rich" (a title: F4, capped at 320u),
--   title = the words (plain: the hint itself),
--   path  = { "Disassemble", ... }: a submenu path before the title, F4 in textSec, " > " between,
--   lines = { "words", { text = "2.0 kg", font = "F3", color = T.textDim }, ... },
--   req   = a requirement list (ZeD.RichTip.parse): { rows = { { label, values = { { t, st } }, st } },
--                                                    conds = { { t, st } } }; st = "ok" | "bad" | nil,
--   pic   = a Texture (the requirement balloon's picture),
--   pads  = { a, b }: a quick action chord's two buttons (the wheels), drawn under the title,
-- }
-- ---------------------------------------------------------------------------

local function sigOf(c)
    local p = { c.kind or "", "\1", tostring(c.title or "") }
    if c.path then for _, s in ipairs(c.path) do p[#p + 1] = "\2" .. tostring(s) end end
    if c.lines then
        for _, l in ipairs(c.lines) do
            if type(l) == "table" then p[#p + 1] = "\3" .. tostring(l.font or "F2") .. tostring(l.text or "")
            else p[#p + 1] = "\3" .. tostring(l) end
        end
    end
    if c.req then p[#p + 1] = "\4" .. (c.req.sig or tostring(c.req)) end
    if c.pic then p[#p + 1] = "\5pic" end
    if c.pads then p[#p + 1] = "\6" .. tostring(c.pads[1]) .. "+" .. tostring(c.pads[2]) end
    return table.concat(p)
end

local LC = { epoch = false, scale = false, n = 0, map = {} }
B._layoutCache = LC

local function lineOf(l)
    if type(l) == "table" then
        local f = l.font
        local T = ZeD.T
        if f == T.fontF3 then f = "F3" end   -- (older cards pass the font itself; no F1 in a balloon)
        return tostring(l.text or ""), (f == "F3") and "F3" or "F2"
    end
    return tostring(l or ""), "F2"
end

-- the requirement table's words, measured
local function reqNat(req, markW)
    local labelW, valNat, condNat, longest = 0, 0, 0, 0
    for _, r in ipairs(req.rows or {}) do
        labelW = math.max(labelW, mw("F2", r.label or ""))
        for _, v in ipairs(r.values or {}) do
            valNat = math.max(valNat, mw("F2", v.t or ""))
            longest = widestWord(v.t, "F2", longest)
        end
    end
    for _, k in ipairs(req.conds or {}) do
        condNat = math.max(condNat, markW + mw("F2", k.t or ""))
        longest = widestWord(k.t, "F2", longest)
    end
    return labelW, valNat, condNat, longest
end

--- The balloon's layout for content: its size and every line placed in it, in px. Kept per content
--- until the measures change.
function B.layout(c)
    local T = T_()
    local X = ZeD.Text
    local epoch = X and X.measureEpoch and X.measureEpoch() or nil
    local sig = sigOf(c)
    if epoch ~= nil and LC.epoch == epoch and LC.scale == T.scale and LC.fF2 == T.fontF2 then
        local hit = LC.map[sig]
        if hit then return hit end
    else
        LC.epoch, LC.scale, LC.fF2, LC.n, LC.map = epoch, T.scale, T.fontF2, 0, {}
    end
    local lay = B._layout(c)
    if epoch ~= nil then
        if LC.n >= 200 then LC.map, LC.n = {}, 0 end
        LC.map[sig] = lay
        LC.n = LC.n + 1
    end
    return lay
end

function B._layout(c)
    local T = T_()
    local plain = c.kind == "plain"
    local tk = plain and "F2" or "F4"
    local padX, padY, gapT, lead = px(B.PAD_X), px(B.PAD_Y), px(B.GAP_T), px(B.LEAD)
    local cap = px(plain and B.HINT_W or B.TITLE_W)
    local hair = T.hair
    local markW = B.MARK * hair + px(B.MARK_GAP)
    local colGap = px(B.COL_GAP)

    -- the title's words: the path (each part, then ">"), then the title
    local tw = {}
    for _, s in ipairs(c.path or {}) do
        for _, w in ipairs(wordsOf(s)) do tw[#tw + 1] = { s = w, role = "path" } end
        tw[#tw + 1] = { s = ">", role = "path" }
    end
    for _, w in ipairs(wordsOf(c.title)) do tw[#tw + 1] = { s = w, role = "title" } end
    -- Each title word is drawn on its own (the path and the name have their own colors), so the gap between
    -- words is a width of its own: the face's space measured alone, never less than a quarter of the line's
    -- height. (A trailing space did not survive the game's measure: "Disassemble> Metal Cabinet".)
    local gap = math.max(mw(tk, " "), math.floor(fh(tk) / 4 + 0.5))
    local titleNat = 0
    for i, w in ipairs(tw) do titleNat = titleNat + ((i > 1) and gap or 0) + mw(tk, w.s) end
    local longest = 0
    for _, w in ipairs(tw) do longest = math.max(longest, mw(tk, w.s)) end

    local lineNat = 0
    for _, l in ipairs(c.lines or {}) do
        local s, k = lineOf(l)
        lineNat = widestLine(s, k, lineNat)
        longest = widestWord(s, k, longest)
    end

    local padsW = 0
    local PG = ZeD.PadGlyphs
    local padSet = c.pads and PG and PG.set and PG.set()
    if c.pads then
        if padSet then
            local k = PG.k(fh("F2"))
            padsW = PG.width({ c.pads[1] }, k, padSet) + px(3) + mw("F2", "+") + px(3) + PG.width({ c.pads[2] }, k, padSet)
        else
            padsW = mw("F2", tostring(c.pads[1]) .. " + " .. tostring(c.pads[2]))
        end
    end

    local picSz = c.pic and px(B.PIC) or 0
    local picW = c.pic and (picSz + px(B.COL_GAP)) or 0
    local labelW, valNat, condNat, tableNat = 0, 0, 0, 0
    local req = c.req
    local hasRows = req and req.rows and #req.rows > 0
    if req then
        local rl
        labelW, valNat, condNat, rl = reqNat(req, markW)
        longest = math.max(longest, rl)
        tableNat = picW + math.max(hasRows and (labelW + colGap + markW + valNat) or 0, condNat)
    end

    local w = math.ceil(math.max(titleNat, lineNat, tableNat, padsW)) + padX * 2
    w = math.min(w, cap)
    local minInner = longest
    if hasRows then minInner = math.max(minInner, picW + labelW + colGap + markW + px(B.MIN_VAL)) end
    if w - padX * 2 < minInner then w = math.min(math.ceil(minInner) + padX * 2, math.floor(cap * B.WIDEN)) end
    local inner = w - padX * 2

    local lay = { w = w, padX = padX, padY = padY, gapT = gapT, lead = lead, tk = tk, inner = inner,
                  markW = markW, colGap = colGap, picSz = picSz, picW = picW, plain = plain, padSet = padSet }

    -- the title, wrapped; each word keeps its x on its line (the words before it and a gap after each)
    local tLines, cur, curX = {}, nil, 0
    local function flush() if cur then tLines[#tLines + 1] = cur end; cur, curX = nil, 0 end
    for _, wd in ipairs(tw) do
        local ww = mw(tk, wd.s)
        if cur and curX + gap + ww > inner then flush() end
        if ww > inner then
            -- one word wider than the box: its pieces each take a line
            flush()
            local pieces = {}
            local last = breakWord(wd.s, tk, inner, pieces)
            for _, pc in ipairs(pieces) do tLines[#tLines + 1] = { { s = pc, x = 0, role = wd.role } } end
            cur, curX = { { s = last, x = 0, role = wd.role } }, mw(tk, last)
        else
            local x = cur and (curX + gap) or 0
            if not cur then cur = {} end
            cur[#cur + 1] = { s = wd.s, x = x, role = wd.role }
            curX = x + ww
        end
    end
    flush()
    lay.tLines = tLines

    -- the lines
    local lines = {}
    for i, l in ipairs(c.lines or {}) do
        local s, k = lineOf(l)
        for _, ln in ipairs(B.wrap(s, k, inner)) do lines[#lines + 1] = { s = ln, k = k, src = i } end
    end
    lay.lines = lines

    -- the requirement table: picture, labels, marks, values
    local rows, conds = {}, {}
    if req then
        local room = inner - picW
        if hasRows and labelW + colGap + markW + px(B.MIN_VAL) > room then labelW = math.max(px(B.MIN_VAL), room - colGap - markW - px(B.MIN_VAL)) end
        local valW = math.max(px(20), room - labelW - colGap - markW)
        for _, r in ipairs(req.rows or {}) do
            local vals = {}
            for _, v in ipairs(r.values or {}) do
                for _, ln in ipairs(B.wrap(v.t, "F2", valW)) do vals[#vals + 1] = { s = ln, st = v.st } end
            end
            rows[#rows + 1] = { label = B.wrap(r.label or "", "F2", labelW + 1), vals = vals, st = r.st }
        end
        for _, k in ipairs(req.conds or {}) do
            conds[#conds + 1] = { lines = B.wrap(k.t, "F2", math.max(px(20), room - markW)), st = k.st }
        end
    end
    lay.rows, lay.conds, lay.labelW = rows, conds, labelW

    -- the height
    local tStep, bStep = fh(tk) + lead, fh("F2") + lead
    local h = padY
    local above = false
    if #tLines > 0 then h = h + #tLines * tStep - lead; above = true end
    if c.pads then h = h + (above and gapT or 0) + fh("F2"); above = true end
    if #lines > 0 then
        h = h + (above and gapT or 0)
        for _, ln in ipairs(lines) do h = h + fh(ln.k) + lead end
        h = h - lead
        above = true
    end
    if #rows > 0 or #conds > 0 then
        if above then h = h + gapT + lead end
        lay.tableAt = h
        local th = 0
        for _, r in ipairs(rows) do th = th + math.max(#r.label, #r.vals, 1) * bStep end
        for _, k in ipairs(conds) do th = th + math.max(#k.lines, 1) * bStep end
        th = th - lead
        h = h + math.max(th, picSz)
    end
    h = h + padY
    lay.h = h
    lay.tStep, lay.bStep = tStep, bStep
    return lay
end

-- ---------------------------------------------------------------------------
-- PLACEMENT
-- a = the control's rectangle in screen px { x, y, w, h, below = the y the area under starts at
--     (the strip: under it), noFlip }; pref = "above" | "below" | "right" | "left".
-- Returns { x, y, side, corner, tipX, tipY, cell, depth } in screen px.
-- ---------------------------------------------------------------------------
local function screen()
    local c = getCore()
    return 0, 0, c:getScreenWidth(), c:getScreenHeight()
end

function B.place(lay, a, pref, bx, by, bw, bh)
    local T = T_()
    if not bx then bx, by, bw, bh = screen() end
    local cell = T.hair
    local depth = B.TAIL * cell
    local inset, m = px(B.INSET), px(B.MARGIN)
    local w, h = lay.w, lay.h
    local beside
    -- above or under; a box too tall for either goes beside the control (its tail can always reach the control's
    -- middle there), and only when neither side has room either does it slide over, the tail kept on its base
    local function vertical(side, last)
        local tipX = math.floor(a.x + math.min(px(B.TIP_IN), a.w / 2) + 0.5)
        local corner, x = "left", tipX - inset
        if x + w > bx + bw - m then corner = "right"; x = tipX + cell + inset - w end
        x = math.max(bx + m, math.min(x, bx + bw - m - w))
        local below = a.below or (a.y + a.h)
        local yA = a.y - cell - depth - h
        local yB = below + cell + depth
        local fitA, fitB = yA >= by + m, yB + h <= by + bh - m
        if not (fitA or fitB or a.noFlip or last) then
            local pl = beside("right", true)
            if pl then return pl end
        end
        local y
        if side == "above" then
            if fitA or a.noFlip or not fitB then y = yA else side, y = "below", yB end
        else
            if fitB or a.noFlip or not fitA then y = yB else side, y = "above", yA end
        end
        y = math.max(by + m, math.min(y, by + bh - m - h))
        return { x = x, y = y, side = side, corner = corner, tipX = tipX, cell = cell, depth = depth }
    end
    -- beside; nil (when asked from vertical) if neither side has room
    beside = function(want, fromVertical)
        local tipY = math.floor(a.y + a.h / 2 + 0.5)
        local xR = a.x + a.w + cell + depth
        local xL = a.x - cell - depth - w
        local fitR, fitL = xR + w <= bx + bw - m, xL >= bx + m
        local side
        if want == "right" then side = fitR and "right" or (fitL and "left" or nil)
        else side = fitL and "left" or (fitR and "right" or nil) end
        if not side then
            if fromVertical then return nil end
            return vertical("above", true)
        end
        local x = (side == "right") and xR or xL
        local y = math.max(by + m, math.min(tipY - inset, by + bh - m - h))
        return { x = x, y = y, side = side, corner = "top", tipY = tipY, cell = cell, depth = depth }
    end
    if pref == "above" or pref == "below" then return vertical(pref) end
    return beside(pref)
end

--- Where the tail's cells go for a placed box (screen px): the tip's cell, for the checks. The tail is
--- placed from its tip, so it stays on the control however far the box slid (clamped only so its base
--- stays on the box).
function B.tailOrigin(box, pl, bwCells)
    local cell, n = pl.cell, B.TAIL
    bwCells = bwCells or 1
    if pl.side == "above" or pl.side == "below" then
        local x0 = (pl.corner == "left") and pl.tipX or (pl.tipX - (n - 1) * cell)
        x0 = math.max(box.x + bwCells * cell, math.min(x0, box.x + box.w - bwCells * cell - n * cell))
        local tipX = (pl.corner == "left") and x0 or (x0 + (n - 1) * cell)
        local tipY = (pl.side == "above") and (box.y + box.h + (n - 1) * cell) or (box.y - n * cell)
        return x0, tipX, tipY
    end
    local y0 = math.max(box.y + bwCells * cell, math.min(pl.tipY, box.y + box.h - bwCells * cell - n * cell))
    local tipX = (pl.side == "right") and (box.x - n * cell) or (box.x + box.w + (n - 1) * cell)
    return y0, tipX, y0
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local function rect(p, x, y, w, h, c)
    if w > 0 and h > 0 then p:drawRect(x, y, w, h, 1, c.r, c.g, c.b) end
end

local function bitmap(p, rows, x, y, cell, c)
    for r, row in ipairs(rows) do
        local run = nil
        for i = 1, #row + 1 do
            local on = row:sub(i, i) == "#"
            if on and not run then run = i end
            if not on and run then
                p:drawRect(x + (run - 1) * cell, y + (r - 1) * cell, (i - run) * cell, cell, 1, c.r, c.g, c.b)
                run = nil
            end
        end
    end
end
B.bitmap = bitmap

--- The check (met) or cross (missing), 7 hairline cells square, at (x, y).
function B.drawMark(p, kind, x, y, c)
    bitmap(p, kind == "ok" and CHECK or CROSS, x, y, T_().hair, c)
end

-- the tail on box (panel px, with the screen's placement shifted by ox, oy)
local function drawTail(p, box, pl, ox, oy)
    local T = T_()
    local fill, edge = T.surf2, T.borderS
    local cell, n = pl.cell, B.TAIL
    local bwc = T.borderW or 1
    local bwPx = T.line(bwc)
    local sbox = { x = box.x + ox, y = box.y + oy, w = box.w, h = box.h }
    if pl.side == "above" or pl.side == "below" then
        local x0 = B.tailOrigin(sbox, pl, bwc) - ox
        local down = pl.side == "above"
        local yBase = down and (box.y + box.h) or (box.y - cell)
        for r = 0, n - 1 do
            local wOut = n - r
            local yy = down and (yBase + r * cell) or (yBase - r * cell)
            local sx = (pl.corner == "left") and 0 or r
            rect(p, x0 + sx * cell, yy, wOut * cell, cell, edge)
            local wIn = wOut - 2 * bwc
            if wIn > 0 then rect(p, x0 + (sx + bwc) * cell, yy, wIn * cell, cell, fill) end
        end
        -- the frame under the tail's base opens into the box
        local oyy = down and (box.y + box.h - bwPx) or box.y
        rect(p, x0 + bwc * cell, oyy, (n - 2 * bwc) * cell, bwPx, fill)
    else
        local y0 = B.tailOrigin(sbox, pl, bwc) - oy
        local left = pl.side == "right"   -- a balloon right of its control has the tail on its left edge
        local xBase = left and (box.x - cell) or (box.x + box.w)
        for k = 0, n - 1 do
            local hOut = n - k
            local xx = left and (xBase - k * cell) or (xBase + k * cell)
            rect(p, xx, y0, cell, hOut * cell, edge)
            local hIn = hOut - 2 * bwc
            if hIn > 0 then rect(p, xx, y0 + bwc * cell, cell, hIn * cell, fill) end
        end
        local oxx = left and box.x or (box.x + box.w - bwPx)
        rect(p, oxx, y0 + bwc * cell, bwPx, (n - 2 * bwc) * cell, fill)
    end
end

local function stColor(st)
    local T = T_()
    if st == "ok" then return T.positiveText or T.positive end
    if st == "bad" then return T.dangerText or T.danger end
    return T.text
end
B.stColor = stColor

local function text(p, s, x, y, c, k)
    p:drawText(s, x, y, c.r, c.g, c.b, c.a or 1, fontOf(k))
end

--- Draw the box and its words at (x, y) in panel px, with no tail (ZeD_Tooltip, and the body of every
--- balloon). Returns the layout.
function B.drawBox(p, c, x, y, lay)
    local T = T_()
    lay = lay or B.layout(c)
    local w, h = lay.w, lay.h
    ZeD.Atoms.drawHardShadow(p, x, y, w, h)
    rect(p, x, y, w, h, T.surf2)
    ZeD.Atoms.frame(p, x, y, w, h, T.borderS, 1, T.line(T.borderW or 1))
    B.drawWords(p, c, x, y, lay)
    return lay
end

function B.drawWords(p, c, x, y, lay)
    local T = T_()
    local cy = y + lay.padY
    local tk = lay.tk
    local headC = lay.plain and T.text or T.textHead
    local pathC = T.textSec or T.textDim
    for _, ln in ipairs(lay.tLines) do
        for _, wd in ipairs(ln) do
            text(p, wd.s, x + lay.padX + wd.x, cy, (wd.role == "path") and pathC or headC, tk)
        end
        cy = cy + lay.tStep
    end
    local above = #lay.tLines > 0
    if above then cy = cy - lay.lead end
    if c.pads then
        if above then cy = cy + lay.gapT end
        local PG = ZeD.PadGlyphs
        local h2 = fh("F2")
        local tc = T.text
        if lay.padSet and PG then
            local k = PG.k(h2)
            local cx = x + lay.padX
            cx = cx + PG.draw(p, { c.pads[1] }, cx, cy, h2, k, lay.padSet) + px(3)
            text(p, "+", cx, cy, tc, "F2")
            cx = cx + mw("F2", "+") + px(3)
            PG.draw(p, { c.pads[2] }, cx, cy, h2, k, lay.padSet)
        else
            text(p, tostring(c.pads[1]) .. " + " .. tostring(c.pads[2]), x + lay.padX, cy, tc, "F2")
        end
        cy = cy + h2
        above = true
    end
    if #lay.lines > 0 then
        if above then cy = cy + lay.gapT end
        for _, ln in ipairs(lay.lines) do
            local src = c.lines and c.lines[ln.src]
            local col = (type(src) == "table" and src.color) or T.text
            text(p, ln.s, x + lay.padX, cy, col, ln.k)
            cy = cy + fh(ln.k) + lay.lead
        end
        cy = cy - lay.lead
    end
    if lay.tableAt then
        local ty = y + lay.tableAt
        if c.pic then
            local s = lay.picSz
            local px0 = x + lay.padX
            rect(p, px0, ty, s, s, T.surf3)
            ZeD.Atoms.frame(p, px0, ty, s, s, T.borderS, 1, T.hair)
            local i = T.hair
            pcall(function() p:drawTextureScaledAspect(c.pic, px0 + i, ty + i, s - 2 * i, s - 2 * i, 1, 1, 1, 1) end)
        end
        local lx = x + lay.padX + lay.picW
        local mx = lx + lay.labelW + lay.colGap
        local vx = mx + lay.markW
        local step = lay.bStep
        local markOff = math.floor((fh("F2") - B.MARK * T.hair) / 2)
        local ry = ty
        for _, r in ipairs(lay.rows) do
            for i, l in ipairs(r.label) do text(p, l, lx, ry + (i - 1) * step, T.text, "F2") end
            if r.st then B.drawMark(p, r.st, mx, ry + markOff, stColor(r.st)) end
            for i, v in ipairs(r.vals) do text(p, v.s, vx, ry + (i - 1) * step, stColor(v.st), "F2") end
            ry = ry + math.max(#r.label, #r.vals, 1) * step
        end
        for _, k in ipairs(lay.conds) do
            local col = stColor(k.st)
            if k.st then B.drawMark(p, k.st, lx, ry + markOff, col) end
            for i, l in ipairs(k.lines) do text(p, l, lx + lay.markW, ry + (i - 1) * step, col, "F2") end
            ry = ry + math.max(#k.lines, 1) * step
        end
    end
end

-- ---------------------------------------------------------------------------
-- ONE AT A TIME
-- The slot holds the balloon that is up. A balloon whose control was pointed at (or focused) later
-- takes the slot from one still asked for; a menu's balloon (prio 2) outranks a window's hint. While the
-- pointer is on the balloon itself, the slot stays with it (WCAG 1.4.13: the pointer can move onto it).
-- ---------------------------------------------------------------------------
local S = { key = nil, t = -1e9, since = -1e9, prio = 0, box = nil, anchor = nil, owner = nil, content = nil, pref = nil }
B._slot = S
local DIS = { key = nil, t = 0 }
B._dismissed = DIS

local function mouseIn(r, grow)
    if not r then return false end
    local mx, my = getMouseX(), getMouseY()
    grow = grow or 0
    return mx >= r.x - grow and mx < r.x + r.w + grow and my >= r.y - grow and my < r.y + r.h + grow
end

--- True while a balloon was drawn within B.STALE_MS.
function B.up() return S.key ~= nil and now() - S.t <= B.STALE_MS end

--- True when a balloon was up recently enough that the next one shows without the pause.
function B.warm() return S.key ~= nil and now() - S.t <= B.WARM_MS end

--- True while the pointer is on the balloon that is up (and its tail's corridor to the control).
function B.held()
    if not B.up() or not S.box then return false end
    if mouseIn(S.box, ZeD.T.hair) then return true end
    if S.corr and mouseIn(S.corr, 0) then return true end
    return false
end

--- May the balloon for key draw now? since = when its control was first pointed at / focused.
function B.claim(key, prio, since)
    local t = now()
    prio = prio or 1
    if DIS.key ~= nil and prio < 2 then
        if t - DIS.t > B.STALE_MS then DIS.key = nil   -- (its control was left: it may show again)
        elseif DIS.key == key then DIS.t = t; return false end
    end
    if S.key == key then return true end
    if S.key == nil or t - S.t > B.STALE_MS then return true end
    if B.held() and prio <= S.prio then return false end
    if prio > S.prio then return true end
    if prio < S.prio then return false end
    return (since or t) >= (S.since or 0)
end

--- Hide the balloon that is up until the pointer or focus moves to another control (Escape, B).
function B.dismiss()
    if S.key ~= nil and now() - S.t <= B.STALE_MS and S.prio < 2 then
        DIS.key, DIS.t = S.key, now()
        S.key, S.box, S.content, S.corr = nil, nil, nil, nil
    end
end

local _box = { x = 0, y = 0, w = 0, h = 0 }

--- Draw the balloon for content on panel p, pointing at the control's rectangle a (screen px).
--- opts = { key, prio (2 for the menus), since, owner (whose balloon it is: B.redrawHeld), noClaim }.
--- Returns the box in panel px (x, y, w, h), or nil when another balloon holds the slot.
function B.draw(p, c, a, pref, opts)
    opts = opts or {}
    local key = opts.key or sigOf(c)
    if not opts.noClaim and not B.claim(key, opts.prio, opts.since) then return nil end
    if DIS.key ~= nil and DIS.key ~= key and (opts.prio or 1) < 2 then DIS.key = nil end   -- (the pointer or focus moved on)
    local lay = B.layout(c)
    local pl = B.place(lay, a, pref or "above")
    local ox, oy = p:getAbsoluteX(), p:getAbsoluteY()
    local x, y = pl.x - ox, pl.y - oy
    B.drawBox(p, c, x, y, lay)
    _box.x, _box.y, _box.w, _box.h = x, y, lay.w, lay.h
    drawTail(p, _box, pl, ox, oy)
    -- the slot
    local t = now()
    if S.key ~= key then
        S.since = opts.since or t
        S.corr = {}
    end
    S.key, S.t, S.prio, S.owner, S.content, S.pref = key, t, opts.prio or 1, opts.owner, c, pref
    S.box = S.box or {}
    S.box.x, S.box.y, S.box.w, S.box.h = pl.x, pl.y, lay.w, lay.h
    S.anchor = S.anchor or {}
    S.anchor.x, S.anchor.y, S.anchor.w, S.anchor.h, S.anchor.below, S.anchor.noFlip = a.x, a.y, a.w, a.h, a.below, a.noFlip
    -- the corridor between the control and the box (the tail's band), so the pointer crossing it keeps the balloon
    local cr = S.corr or {}
    S.corr = cr
    if pl.side == "above" then cr.x, cr.y, cr.w, cr.h = pl.x, pl.y + lay.h, lay.w, math.max(0, a.y - (pl.y + lay.h))
    elseif pl.side == "below" then local b0 = a.below or (a.y + a.h); cr.x, cr.y, cr.w, cr.h = pl.x, b0, lay.w, math.max(0, pl.y - b0)
    elseif pl.side == "right" then cr.x, cr.y, cr.w, cr.h = a.x + a.w, pl.y, math.max(0, pl.x - (a.x + a.w)), lay.h
    else cr.x, cr.y, cr.w, cr.h = pl.x + lay.w, pl.y, math.max(0, a.x - (pl.x + lay.w)), lay.h end
    B.lastPlace = pl
    return x, y, lay.w, lay.h
end

--- The balloon that is up, drawn again on p while the pointer is on it and its owner no longer asks for
--- it (the pointer left the control for the balloon). True when it drew.
function B.redrawHeld(owner, p)
    if S.owner ~= owner or not S.content or not B.held() then return false end
    if now() - S.t < 4 then return true end   -- (drawn this frame already: the overlay and a hint layer both ask)
    return B.draw(p, S.content, S.anchor, S.pref, { key = S.key, prio = S.prio, since = S.since, owner = owner }) ~= nil
end

--- The room a balloon for c takes above a control: its height and the tail (the belt stacks the game's
--- item box over it).
function B.stackHeight(c)
    local lay = B.layout(c)
    return lay.h + (B.TAIL + 1) * ZeD.T.hair
end

-- Escape hides the balloon that is up (the key still does what it does).
if Events and Events.OnKeyPressed and Keyboard then
    Events.OnKeyPressed.Add(function(key)
        if key == Keyboard.KEY_ESCAPE then B.dismiss() end
    end)
end

return B
