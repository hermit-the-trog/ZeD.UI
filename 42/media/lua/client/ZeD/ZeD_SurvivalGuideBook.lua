-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua
-- ============================================================================
-- THE SURVIVAL GUIDE, the Full look: "Survive the Apocalypse" by Stevie Whetstone, Second Edition (Doidbros and
-- Buzzlord, Division of Survival Emergency Publications, 1987). The director, Nov 3 2026: a printed manual "just
-- bought from the bookstore. Book Naked": no marks; set like a 1983 bookstore survival guide (chapter openers in
-- heavy italic capitals over a photo, a bold Title Case line, serif text) with the 1990 survival magazine's grey bar
-- and ruled charts on the rules pages; no drop caps. Mockup: ZeDUI/mockups/zed_survival_guide_v7.html.
--
-- The same topics, text, clips and numbers as the window (ZeD_SurvivalGuide.lua, which opens this one when ZeD
-- setup's Survival guide row is Full). One topic a page, two a spread; a topic with The Rules in Numbers has them on
-- the page after it; a topic too long for its page runs on to the next. Before the chapters: the title page, then
-- the contents facing the introduction with the author's photo.
--
-- Faces: the game's own distance-field faces, drawn at any size with drawTextZoomed (as ZeD_PrintPage.lua):
-- Old Standard TT for the text, Roberto Sans Bold Italic for the headings, Open Sans for the small sans lines.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"

ZeD = ZeD or {}
ZeD.GuideBook = ZeD.GuideBook or {}
local B = ZeD.GuideBook
B.books = B.books or {}

-- the faces, their atlas size and their baseline in the atlas (the game's .fnt files)
local F = {
    text  = { slot = "SdfOldRegular", size = 32, base = 25 },
    textB = { slot = "SdfOldBold", size = 32, base = 25 },
    textI = { slot = "SdfOldItalic", size = 32, base = 25 },
    head  = { slot = "SdfRobertoSans", size = 48, base = 56 },
    sans  = { slot = "SdfRegular", size = 32, base = 35 },
    sansB = { slot = "SdfBold", size = 32, base = 35 },
    sansI = { slot = "SdfItalic", size = 32, base = 35 },
}
for _, f in pairs(F) do f.font = UIFont[f.slot] end

-- the book in design units (1 px at 1080p): two pages, the margins, the type sizes
local U = {
    PW = 520, PH = 690, M = 40, MT = 30, FOOT = 26, EDGE = 6,
    TEXT = 12.5, LEAD = 1.42, CAP = 10, FOLIO = 9, CHAP = 13, OPEN = 30, TITLE = 22, DECK = 14,
    BAR = 19, STRIP_GAP = 10,
}
local INK = { r = 0.137, g = 0.165, b = 0.227 }
local PAPER = { r = 0.961, g = 0.925, b = 0.824 }
local TINT = { r = 0.788, g = 0.769, b = 0.706 }
local DESK = { r = 0.0, g = 0.0, b = 0.0, a = 0.62 }

local function tr(k, ...) return ZeD.tr(k, ...) end
local function upper(s) return ZeD.upper and ZeD.upper(s) or string.upper(s) end
local function realTM() return (ZeD.Text and ZeD.Text.realTM and ZeD.Text.realTM()) or getTextManager() end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UIActivateButton") end) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

-- ---------------------------------------------------------------------------
-- TYPE: measure and draw a face at a size in screen px
-- ---------------------------------------------------------------------------
local function zoom(f, px) return px / f.size end
local function textW(f, s, px) return realTM():MeasureStringX(f.font, s) * zoom(f, px) end
-- (these faces measure a space as next to nothing: take it from "a a" less "aa", at least a quarter em)
local _spaces = {}
local function spaceW(f, px)
    local k = f.slot
    if not _spaces[k] then _spaces[k] = math.max(realTM():MeasureStringX(f.font, "a a") - realTM():MeasureStringX(f.font, "aa"), f.size * 0.25) end
    return _spaces[k] * zoom(f, px)
end
-- text with its baseline at y
local function drawAt(panel, f, s, x, baseY, px, c, a)
    local z = zoom(f, px)
    panel:drawTextZoomed(s, x, baseY - f.base * z, z, c.r, c.g, c.b, a or 1, f.font)
end
local function drawCentre(panel, f, s, cx, baseY, px, c)
    drawAt(panel, f, s, cx - textW(f, s, px) / 2, baseY, px, c)
end

-- words (and the game's small pictures) into lines; widthFor(n) the width of the n-th line from `start`.
-- Each line: { items = { {w=word|tex, x, ww} }, natural, last, indent }
local function wordsOf(para)
    local MARK = ZeD.Guide and ZeD.Guide.MARK or "\1"
    local out = {}
    local i = 1
    while i <= #para do
        local a = para:find(MARK, i, true)
        for wd in para:sub(i, (a or (#para + 1)) - 1):gmatch("%S+") do out[#out + 1] = { word = wd } end
        if not a then break end
        local b = para:find(MARK, a + 1, true)
        if not b then break end
        local tex = ZeD.Guide and ZeD.Guide.inlineTex and ZeD.Guide.inlineTex(para:sub(a + 1, b - 1))
        if tex then out[#out + 1] = { tex = tex } end
        i = b + 1
    end
    return out
end

local function wrapWords(words, f, px, widthFor, start, indent)
    local lines = {}
    local sp = spaceW(f, px)
    local icon = px * 1.1
    local cur, cw, n = {}, 0, start or 1
    local function lim() return widthFor(n) - ((#lines == 0) and (indent or 0) or 0) end
    local function flush(last)
        if #cur == 0 then return end
        lines[#lines + 1] = { items = cur, natural = cw, last = last, indent = (#lines == 0) and (indent or 0) or 0, width = widthFor(n) }
        cur, cw, n = {}, 0, n + 1
    end
    for _, wd in ipairs(words) do
        local ww = wd.tex and icon or textW(f, wd.word, px)
        if #cur > 0 and cw + sp + ww > lim() then flush(false) end
        cw = cw + ((#cur > 0) and sp or 0) + ww
        cur[#cur + 1] = { word = wd.word, tex = wd.tex, ww = ww }
    end
    flush(true)
    return lines, n
end

-- a line, justified unless it ends its paragraph
local function drawLine(panel, f, px, l, x, baseY, c)
    local sp = spaceW(f, px)
    local gaps = #l.items - 1
    local extra = 0
    if not l.last and gaps > 0 then extra = math.max(0, (l.width - l.indent - l.natural) / gaps) end
    if extra > sp * 1.6 then extra = 0 end   -- (a line too loose to justify stays ragged)
    local xx = x + l.indent
    for _, it in ipairs(l.items) do
        if it.tex then
            local s = px * 1.05
            panel:drawTextureScaledAspect(it.tex, xx, baseY - s * 0.82, s, s, 1, 1, 1, 1)
        else
            drawAt(panel, f, it.word, xx, baseY, px, c)
        end
        xx = xx + it.ww + sp + extra
    end
end

-- ---------------------------------------------------------------------------
-- THE PAGES
-- ---------------------------------------------------------------------------
-- the section's own words for its chapter opener and the contents (keys by the game's section title key)
local function stemOf(titleKey) return tostring(titleKey):match("^SurvivalGuide_(.-)_title$") or tostring(titleKey) end
local function blurb(s) local k = "UI_ZeD_Guide_Blurb_" .. stemOf(s.titleKey); local t = tr(k); return t ~= k and t or "" end
local function titleCase(s) return (s:gsub("(%w)([%w']*)", function(a, b) return upper(a) .. b end)) end

-- all of a topic's body lines at width w (the game's line breaks start new lines; a <LINE> paragraph indents)
local function bodyLines(t, f, px, w)
    local out = {}
    local first = true
    for _, para in ipairs(ZeD.Guide.paragraphs(t.text)) do
        local pieceFirst = true
        for piece in (para .. "\n"):gmatch("(.-)\n") do
            local ls = wrapWords(wordsOf(piece), f, px, function() return w end, 1, (first or not pieceFirst) and 0 or px * 1.4)
            for _, l in ipairs(ls) do out[#out + 1] = l end
            first, pieceFirst = false, false
        end
    end
    return out
end

-- the page list for a reading of the topics (front matter, then a page a topic and its rules page)
function B.paginate(bk, u)
    local px = function(n) return n * u end
    local pages = { { kind = "blank" }, { kind = "title" }, { kind = "contents" }, { kind = "intro" } }
    local textW_ = px(U.PW - U.M * 2)
    local lineH = px(U.TEXT) * U.LEAD
    local bottom = px(U.PH - U.FOOT - U.MT)
    bk.sectionPage = {}
    for si, s in ipairs(bk.sections) do
        for ti, t in ipairs(s.topics) do
            local first = ti == 1
            -- the heading's room: Chapter n, the title, the clip, the caption, the deck
            local y = px(U.MT)
            y = y + px(U.CHAP) * 1.6
            local headPx = first and px(U.OPEN) or px(U.TITLE)
            local heads = wrapWords(wordsOf(upper(first and s.title or t.title)), F.head, headPx, function() return textW_ end, 1, 0)
            y = y + #heads * headPx * 1.08 + px(10)
            local clipH = 0
            if t.video and t.video ~= "" then clipH = math.floor(textW_ / 2); y = y + clipH + px(U.CAP) * 2.2 end
            local deckLines = {}
            if first then
                local d = blurb(s)
                if d ~= "" then
                    deckLines = wrapWords(wordsOf(titleCase(d:gsub("%.$", ""))), F.sansB, px(U.DECK), function() return textW_ - px(20) end, 1, 0)
                    y = y + #deckLines * px(U.DECK) * 1.3 + px(8)
                end
                y = y + px(U.TEXT) * 1.6   -- (the topic's own name, a bold sans line, over its text)
            end
            local lines = bodyLines(t, F.text, px(U.TEXT), textW_)
            local room = math.max(1, math.floor((bottom - y) / lineH))
            local page = { kind = "topic", topic = t, section = s, si = si, first = first, heads = heads, headPx = headPx,
                           clipH = clipH, deck = deckLines, lines = {} }
            if first then bk.sectionPage[s.id] = #pages + 1 end
            pages[#pages + 1] = page
            local li = 1
            for k = 1, math.min(room, #lines) do page.lines[#page.lines + 1] = lines[k]; li = k + 1 end
            -- a topic too long for its page runs on
            while li <= #lines do
                local cont = { kind = "topic", topic = t, section = s, si = si, cont = true, lines = {} }
                local r2 = math.floor((bottom - px(U.MT) - px(U.CHAP) * 2) / lineH)
                for k = li, math.min(#lines, li + r2 - 1) do cont.lines[#cont.lines + 1] = lines[k] end
                li = li + r2
                pages[#pages + 1] = cont
            end
            local rf = ZeD.Guide.Rules and ZeD.Guide.Rules[t.titleKey]
            if rf then
                local ok, rules = pcall(rf)
                if ok and rules then pages[#pages + 1] = { kind = "rules", topic = t, section = s, si = si, rules = rules } end
            end
        end
    end
    if #pages % 2 == 1 then pages[#pages + 1] = { kind = "blank" } end
    bk.pages = pages
    bk.pageOf = {}
    for i, p in ipairs(pages) do
        if p.kind == "topic" and not p.cont and not bk.pageOf[p.topic.id] then bk.pageOf[p.topic.id] = i end
    end
end

-- the printed number of the page at index i (the title page is the first right-hand page, ii)
local function printed(i) return i + 1 end

-- ---------------------------------------------------------------------------
-- THE PANEL: the dimmed game, the open book, the strip under it
-- ---------------------------------------------------------------------------
ZeD_GuideBook = ISPanelJoypad:derive("ZeD_GuideBook")

function ZeD_GuideBook:new(pn)
    local o = ISPanelJoypad.new(self, 0, 0, 100, 100)
    o.playerNum = pn or 0
    o.background = false
    o.spread = 1
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o._clips = {}
    o:setWantKeyEvents(true)
    return o
end

function ZeD_GuideBook:readTopics(u)
    local joy = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1] ~= nil
    self.sections, self.byId, self.flat = ZeD.Guide.readTopicList(joy)
    self._u = u
    B.paginate(self, u)
end

-- the unit (screen px per design unit): the UI scale, smaller when the book would not fit the screen
function ZeD_GuideBook:unit()
    local T = ZeD.T
    local pn = self.playerNum
    local u = T.px(100) / 100
    local needW = (U.PW * 2 + U.EDGE * 2 + 20) * u
    local needH = (U.PH + U.STRIP_GAP + 40) * u + ZeD.Molecules.bandH()
    local f = math.min(1, getPlayerScreenWidth(pn) / needW, getPlayerScreenHeight(pn) / needH)
    return u * f
end

function ZeD_GuideBook:layout()
    local pn = self.playerNum
    local sw, sh = getPlayerScreenWidth(pn), getPlayerScreenHeight(pn)
    local sx, sy = getPlayerScreenLeft(pn), getPlayerScreenTop(pn)
    if self.x ~= sx then self:setX(sx) end
    if self.y ~= sy then self:setY(sy) end
    if self.width ~= sw then self:setWidth(sw) end
    if self.height ~= sh then self:setHeight(sh) end
    local u = self:unit()
    if self._u ~= u then self:readTopics(u) end
    local bw, bh = U.PW * 2 * u, U.PH * u
    local stripH = ZeD.Molecules.bandH()
    local total = bh + U.STRIP_GAP * u + stripH
    local g = {}
    g.u = u
    g.book = { x = math.floor((sw - bw) / 2), y = math.floor((sh - total) / 2), w = bw, h = bh }
    g.left = { x = g.book.x, y = g.book.y, w = bw / 2, h = bh }
    g.right = { x = g.book.x + bw / 2, y = g.book.y, w = bw / 2, h = bh }
    g.strip = { x = g.book.x, y = g.book.y + bh + U.STRIP_GAP * u, w = bw, h = stripH }
    local n = #self.pages / 2
    if self.spread > n then self.spread = n end
    if self.spread < 1 then self.spread = 1 end
    self._g = g
end

-- ---------------------------------------------------------------------------
-- DRAWING A PAGE
-- ---------------------------------------------------------------------------
function ZeD_GuideBook:clipTex(t)
    local key = t.id .. (getCore():getOptionDoVideoEffects() and ":v" or ":s")
    local c = self._clips[key]
    if c == nil then
        c = false
        if getCore():getOptionDoVideoEffects() then
            local ok, v = pcall(getVideo, t.video, 960, 480)
            if ok and v then c = { video = v } end
        end
        if not c then
            local base = tostring(t.video):match("([^/\\]+)%.%w+$") or tostring(t.video):match("([^/\\]+)$") or ""
            local tex = getTexture("media/textures/ZeD/guide/" .. base .. ".png")
            if tex then c = { still = tex } end
        end
        self._clips[key] = c
    end
    return c or nil
end

local function folio(panel, pg, x, y, w, u, num, left)
    local fy = y + (U.PH - 12) * u
    local name = upper(tr("UI_ZeD_Guide_BookTitle"))
    local px = U.FOLIO * u
    if left then
        drawAt(panel, F.sansB, tostring(num), x + U.M * u, fy, px * 1.15, INK)
        drawAt(panel, F.sansB, name, x + w - U.M * u - textW(F.sansB, name, px), fy, px, INK)
    else
        drawAt(panel, F.sansB, name, x + U.M * u, fy, px, INK)
        drawAt(panel, F.sansB, tostring(num), x + w - U.M * u - textW(F.sansB, tostring(num), px * 1.15), fy, px * 1.15, INK)
    end
end

function ZeD_GuideBook:drawTopicPage(p, x, y, w, u)
    local m = U.M * u
    local tx, tw_ = x + m, w - m * 2
    local yy = y + U.MT * u
    local t, s = p.topic, p.section
    local chap = p.cont and (tr("UI_ZeD_Guide_BookChapter", p.si) .. "  |  " .. t.title .. "  " .. tr("UI_ZeD_Guide_BookContinued"))
        or (p.first and tr("UI_ZeD_Guide_BookChapter", p.si) or (tr("UI_ZeD_Guide_BookChapter", p.si) .. "  |  " .. s.title))
    yy = yy + U.CHAP * u
    drawAt(self, F.sansB, chap, tx, yy, U.CHAP * u * (p.first and 1.1 or 0.9), INK)
    yy = yy + U.CHAP * u * 0.6
    if not p.cont then
        for _, l in ipairs(p.heads) do
            yy = yy + p.headPx * 1.08
            local words = {}
            for _, it in ipairs(l.items) do words[#words + 1] = it.word or "" end
            drawCentre(self, F.head, table.concat(words, " "), x + w / 2, yy - p.headPx * 0.18, p.headPx, INK)
        end
        yy = yy + 10 * u
        if p.clipH > 0 then
            local c = self:clipTex(t)
            self:drawRect(tx, yy, tw_, p.clipH, 1, INK.r, INK.g, INK.b)
            if c and c.video then
                pcall(function() c.video:RenderFrame() end)
                self:drawTextureScaled(c.video, tx, yy, tw_, p.clipH, 1, 0.96, 0.93, 0.84)
            elseif c and c.still then
                self:drawTextureScaledAspect(c.still, tx, yy, tw_, p.clipH, 1, 0.96, 0.93, 0.84)
            end
            yy = yy + p.clipH + U.CAP * u * 1.5
            drawCentre(self, F.sansI, t.title, x + w / 2, yy, U.CAP * u, INK)
            yy = yy + U.CAP * u * 0.7
        end
        for _, l in ipairs(p.deck or {}) do
            yy = yy + U.DECK * u * 1.3
            local words = {}
            for _, it in ipairs(l.items) do words[#words + 1] = it.word or "" end
            drawCentre(self, F.sansB, table.concat(words, " "), x + w / 2, yy, U.DECK * u, INK)
        end
        if p.first then
            yy = yy + ((#(p.deck or {}) > 0) and 8 * u or 0) + U.TEXT * u * 1.5
            drawAt(self, F.sansB, t.title, tx, yy, U.TEXT * u, INK)
            yy = yy + U.TEXT * u * 0.3
        end
    end
    local lineH = U.TEXT * u * U.LEAD
    for _, l in ipairs(p.lines) do
        yy = yy + lineH
        drawLine(self, F.text, U.TEXT * u, l, tx, yy, INK)
    end
end

function ZeD_GuideBook:drawRulesPage(p, x, y, w, u)
    local m = U.M * u
    local tx, tw_ = x + m, w - m * 2
    local yy = y + U.MT * u
    -- the grey bar
    local barH = U.BAR * u * 1.9
    self:drawRect(tx, yy, tw_, barH, 1, TINT.r, TINT.g, TINT.b)
    self:drawRectBorder(tx, yy, tw_, barH, 1, INK.r, INK.g, INK.b)
    drawCentre(self, F.sansB, upper(tr("UI_ZeD_Guide_Rules")), x + w / 2, yy + barH * 0.68, U.BAR * u, INK)
    yy = yy + barH + U.TEXT * u
    local r = p.rules
    local px = U.TEXT * u
    local lineH = px * U.LEAD
    local function para(text)
        for _, l in ipairs(wrapWords(wordsOf(text), F.text, px, function() return tw_ end, 1, 0)) do
            yy = yy + lineH
            drawLine(self, F.text, px, l, tx, yy, INK)
        end
        yy = yy + lineH * 0.35
    end
    if r.notes and r.notes[1] then para(r.notes[1]) end
    -- the chart, in a ruled box with its caption inside at the foot
    yy = yy + 6 * u
    local boxY = yy
    local pad = 8 * u
    local ncol = #r.cols
    local cpx = 11 * u
    local inner = tw_ - pad * 2
    local dataW, headW = {}, {}
    for c = 1, ncol do
        local wmax = 0
        for _, row in ipairs(r.rows) do wmax = math.max(wmax, textW(F.text, row[c] or "", cpx)) end
        local word = 0
        for wd in tostring(r.cols[c]):gmatch("%S+") do word = math.max(word, textW(F.textB, wd, cpx)) end
        dataW[c], headW[c] = math.max(wmax, word), textW(F.textB, r.cols[c], cpx)
    end
    local gap = 14 * u
    local minT = gap * (ncol - 1)
    for c = 1, ncol do minT = minT + dataW[c] end
    local extra, want = math.max(0, inner - minT), 0
    for c = 1, ncol do want = want + math.max(0, headW[c] - dataW[c]) end
    local colX, xx = {}, tx + pad
    local heads, hl = {}, 1
    for c = 1, ncol do
        local wc = dataW[c] + ((want > 0) and math.floor(math.max(0, headW[c] - dataW[c]) * math.min(1, extra / want)) or 0)
        colX[c] = xx
        heads[c] = wrapWords(wordsOf(r.cols[c]), F.textB, cpx, function() return wc end, 1, 0)
        hl = math.max(hl, #heads[c])
        xx = xx + wc + gap
    end
    local y0 = boxY + pad
    for c = 1, ncol do
        for li, l in ipairs(heads[c]) do
            local words = {}
            for _, it in ipairs(l.items) do words[#words + 1] = it.word or "" end
            drawAt(self, F.textB, table.concat(words, " "), colX[c], y0 + li * cpx * 1.25, cpx, INK)
        end
    end
    local ry = y0 + hl * cpx * 1.25 + 5 * u
    self:drawRect(tx + pad, ry, inner, math.max(1, 1.5 * u), 1, INK.r, INK.g, INK.b)
    for _, row in ipairs(r.rows) do
        ry = ry + cpx * 1.5
        for c = 1, ncol do drawAt(self, F.text, row[c] or "", colX[c], ry, cpx, INK) end
        self:drawRect(tx + pad, ry + cpx * 0.45, inner, math.max(1, u * 0.6), 0.3, INK.r, INK.g, INK.b)
    end
    ry = ry + cpx * 1.8
    drawCentre(self, F.textB, p.topic.title, x + w / 2, ry, cpx, INK)
    local boxH = ry + pad - boxY
    self:drawRectBorder(tx, boxY, tw_, boxH, 1, INK.r, INK.g, INK.b)
    yy = boxY + boxH + 6 * u
    for i = 2, #(r.notes or {}) do para(r.notes[i]) end
end

function ZeD_GuideBook:drawTitlePage(x, y, w, u)
    local cx = x + w / 2
    local yy = y + 180 * u
    for _, line in ipairs({ tr("UI_ZeD_Guide_BookTitle1"), tr("UI_ZeD_Guide_BookTitle2") }) do
        yy = yy + 46 * u
        drawCentre(self, F.head, upper(line), cx, yy, 44 * u, INK)
    end
    yy = yy + 34 * u
    for _, line in ipairs({ tr("UI_ZeD_Guide_BookSub1"), tr("UI_ZeD_Guide_BookSub2") }) do
        drawCentre(self, F.sansB, line, cx, yy, 15 * u, INK)
        yy = yy + 20 * u
    end
    yy = yy + 24 * u
    drawCentre(self, F.sansB, tr("UI_ZeD_Guide_BookEdition"), cx, yy, 12 * u, INK)
    yy = yy + 32 * u
    drawCentre(self, F.sansB, tr("UI_ZeD_Guide_BookBy"), cx, yy, 12 * u, INK)
    local by = y + (U.PH - 90) * u
    drawCentre(self, F.sansB, upper(tr("UI_ZeD_Guide_BookPublisher")), cx, by, 12 * u, INK)
    drawCentre(self, F.sans, tr("UI_ZeD_Guide_BookDivision"), cx, by + 17 * u, 11 * u, INK)
    drawCentre(self, F.sans, "1987", cx, by + 33 * u, 11 * u, INK)
end

function ZeD_GuideBook:drawContentsPage(x, y, w, u, hover)
    local m = U.M * u
    local tx, tw_ = x + m, w - m * 2
    local yy = y + U.MT * u + 28 * u
    drawAt(self, F.head, upper(tr("UI_ZeD_Guide_BookContents")), tx, yy, 28 * u, INK)
    yy = yy + 18 * u
    self._contentsRows = {}
    for si, s in ipairs(self.sections) do
        local pg = self.sectionPage[s.id]
        local rowTop = yy
        yy = yy + 13 * u
        local num = tostring(si) .. "."
        drawAt(self, F.sansB, num, tx + 18 * u - textW(F.sansB, num, 10 * u), yy, 10 * u, INK)
        drawAt(self, F.sansB, upper(s.title), tx + 24 * u, yy, 10 * u, INK)
        yy = yy + 12 * u
        local b = blurb(s)
        local bw = textW(F.sans, b, 9.5 * u)
        drawAt(self, F.sans, b, tx + 24 * u, yy, 9.5 * u, INK)
        local ptxt = pg and tostring(printed(pg)) or ""
        local pw = textW(F.sansB, ptxt, 10 * u)
        drawAt(self, F.sansB, ptxt, tx + tw_ - pw, yy, 10 * u, INK)
        -- the dotted leader
        local dx = tx + 24 * u + bw + 4 * u
        while dx < tx + tw_ - pw - 4 * u do
            self:drawRect(dx, yy - 1.5 * u, math.max(1, u), math.max(1, u), 1, INK.r, INK.g, INK.b)
            dx = dx + 4 * u
        end
        local row = { x = tx, y = rowTop, w = tw_, h = yy - rowTop + 4 * u, page = pg }
        if hover and inRect(row, hover.x, hover.y) then
            self:drawRect(row.x - 4 * u, row.y + 2 * u, row.w + 8 * u, row.h, 0.08, INK.r, INK.g, INK.b)
        end
        self._contentsRows[#self._contentsRows + 1] = row
        yy = yy + 6 * u
    end
end

function ZeD_GuideBook:drawIntroPage(x, y, w, u)
    local m = U.M * u
    local tx, tw_ = x + m, w - m * 2
    local yy = y + U.MT * u + 30 * u
    drawCentre(self, F.head, upper(tr("UI_ZeD_Guide_BookIntro")), x + w / 2, yy, 28 * u, INK)
    yy = yy + 16 * u
    local photo = getTexture("media/textures/ZeD/guide/author.png")
    local ps = 150 * u
    if photo then
        self:drawTextureScaledAspect(photo, tx, yy + 4 * u, ps, ps, 1, 0.96, 0.93, 0.84)
        self:drawRectBorder(tx, yy + 4 * u, ps, ps, 1, INK.r, INK.g, INK.b)
    end
    local px = U.TEXT * u
    local lineH = px * U.LEAD
    local beside = math.ceil((ps + 8 * u) / lineH)
    local narrow, full = tw_ - ps - 14 * u, tw_
    local n = 1
    for i = 1, 4 do
        local text = tr("UI_ZeD_Guide_Intro" .. i)
        local ls
        ls, n = wrapWords(wordsOf(text), F.text, px, function(k) return (k <= beside) and narrow or full end, n, (i == 1) and 0 or px * 1.4)
        for _, l in ipairs(ls) do
            local k = n - #ls + _ - 1
            yy = yy + lineH
            drawLine(self, F.text, px, l, (k <= beside) and (tx + ps + 14 * u) or tx, yy, INK)
        end
    end
    yy = math.max(yy, y + U.MT * u + 46 * u + ps) + 30 * u
    local name = tr("UI_ZeD_Guide_BookAuthor")
    drawAt(self, F.head, name, x + w - m - textW(F.head, name, 17 * u), yy, 17 * u, INK)
    yy = yy + 17 * u
    local place = tr("UI_ZeD_Guide_BookPlace")
    drawAt(self, F.textI, place, x + w - m - textW(F.textI, place, 12 * u), yy, 12 * u, INK)
end

function ZeD_GuideBook:drawPage(i, x, y, w, u, hover)
    local p = self.pages[i]
    if not p then return end
    if p.kind == "title" then self:drawTitlePage(x, y, w, u); return end
    if p.kind == "contents" then self:drawContentsPage(x, y, w, u, hover)
    elseif p.kind == "intro" then self:drawIntroPage(x, y, w, u)
    elseif p.kind == "topic" then self:drawTopicPage(p, x, y, w, u)
    elseif p.kind == "rules" then self:drawRulesPage(p, x, y, w, u)
    else return end
    folio(self, p, x, y, w, u, printed(i), i % 2 == 1)
end

-- ---------------------------------------------------------------------------
-- DRAW
-- ---------------------------------------------------------------------------
local _strip = { buttons = { {}, {}, {} } }
local _check = {}
local _fo = {}
local function focusOpts(win) _fo.win, _fo.focused, _fo.pad = win, true, true; return _fo end

function ZeD_GuideBook:prerender()
    local T = ZeD.T
    if not T then return end
    local ok, err = pcall(self.layout, self)
    if not ok then ZeD.logOnce("survival guide book", err); B.close(self.playerNum); return end
    local g = self._g
    local u = g.u
    self:drawRect(0, 0, self.width, self.height, DESK.a, DESK.r, DESK.g, DESK.b)
    -- the book: its edge, the two pages, the gutter's shade
    local bk = g.book
    self:drawRect(bk.x - U.EDGE * u, bk.y + 3 * u, bk.w + U.EDGE * 2 * u, bk.h, 1, 0.75, 0.71, 0.62)
    self:drawRect(bk.x, bk.y, bk.w, bk.h, 1, PAPER.r, PAPER.g, PAPER.b)
    local gx = bk.x + bk.w / 2
    for k = 1, 10 do
        local a = 0.05 * (11 - k) / 10
        self:drawRect(gx - k * 2 * u, bk.y, 2 * u, bk.h, a, 0.25, 0.18, 0.08)
        self:drawRect(gx + (k - 1) * 2 * u, bk.y, 2 * u, bk.h, a, 0.25, 0.18, 0.08)
    end
    local mx, my = self:getMouseX(), self:getMouseY()
    local hover = { x = mx, y = my }
    local li = self.spread * 2 - 1
    self:drawPage(li, g.left.x, g.left.y, g.left.w, u, hover)
    self:drawPage(li + 1, g.right.x, g.right.y, g.right.w, u, hover)
    -- the thumb index: a printed block for each chapter on the right page's edge, the open one dark
    self._thumbs = {}
    local cur = self.pages[li + 1] and self.pages[li + 1].si or (self.pages[li] and self.pages[li].si)
    local n = #self.sections
    local th = (bk.h - 60 * u) / math.max(1, n)
    for si = 1, n do
        local r = { x = bk.x + bk.w - 16 * u, y = bk.y + 30 * u + (si - 1) * th, w = 16 * u, h = th - 2 * u, si = si }
        local on = cur == si
        local hov = inRect(r, mx, my)
        self:drawRect(r.x, r.y, r.w, r.h, on and 1 or (hov and 0.45 or 0.14), INK.r, INK.g, INK.b)
        if on or hov then drawCentre(self, F.sansB, tostring(si), r.x + r.w / 2, r.y + r.h / 2 + 4 * u, 9 * u, PAPER) end
        self._thumbs[#self._thumbs + 1] = r
    end
    -- the strip under the book: the game's start-up box, Previous page, Contents, Next page
    local joy = self.joyfocus ~= nil
    local c = _check
    c.label = getText("IGUI_Tutorial_ShowGuide")
    c.on = getCore():getOptionShowSurvivalGuide() and true or false
    c.help, c.id = tr("UI_ZeD_Guide_HelpStartup"), "startup"
    c.focus = (joy and self.footFocus == 1) and focusOpts(self) or nil
    local labels = { tr("UI_ZeD_Guide_BookPrev"), tr("UI_ZeD_Guide_BookContents"), tr("UI_ZeD_Guide_BookNext") }
    local ids = { "prev", "toc", "next" }
    for i = 1, 3 do
        local e = _strip.buttons[i]
        e.label = ZeD.btnCase and ZeD.btnCase(labels[i]) or labels[i]
        e.id, e.variant = ids[i], (i == 3) and "primary" or "default"
        e.focus = (joy and self.footFocus == i + 1) and focusOpts(self) or nil
        e.pressed = self._down == ids[i]
    end
    _strip.check, _strip.win = c, self
    local _, rects = ZeD.Molecules.drawBand(self, g.strip.x, g.strip.y, g.strip.w, _strip)
    self._stripRects = rects
end

-- ---------------------------------------------------------------------------
-- TURNING THE PAGES
-- ---------------------------------------------------------------------------
function ZeD_GuideBook:turn(d)
    local n = #self.pages / 2
    local s = math.max(1, math.min(n, self.spread + d))
    if s ~= self.spread then self.spread = s; sound("UISelectListItem") end
end

function ZeD_GuideBook:goToPage(i)
    if not i then return end
    self.spread = math.floor((i + 1) / 2)
    sound("UISelectListItem")
end

function ZeD_GuideBook:goToTopic(id)
    local i = id and self.pageOf and self.pageOf[id]
    if i then self.spread = math.floor((i + 1) / 2) end
end

function ZeD_GuideBook:press(id)
    if id == "startup" then
        sound("UIActivateButton")
        local core = getCore()
        core:setOptionShowSurvivalGuide(not core:getOptionShowSurvivalGuide())
        core:saveOptions()
    elseif id == "prev" then self:turn(-1)
    elseif id == "next" then self:turn(1)
    elseif id == "toc" then self:goToPage(3) end
end

function ZeD_GuideBook:stripHit(x, y)
    local r = self._stripRects
    if not r then return nil end
    if r.check and inRect(r.check, x, y) then return "startup" end
    for _, b in pairs(r.buttons or {}) do if inRect(b, x, y) then return b.id end end
    return nil
end

function ZeD_GuideBook:onMouseDown(x, y)
    local hit = self:stripHit(x, y)
    if hit then self._down = hit; return true end
    for _, r in ipairs(self._thumbs or {}) do
        if inRect(r, x, y) then self:goToPage(self.sectionPage[self.sections[r.si].id]); return true end
    end
    local g = self._g
    if g and self.pages[self.spread * 2 - 1] and self.pages[self.spread * 2 - 1].kind == "contents" then
        for _, row in ipairs(self._contentsRows or {}) do
            if inRect(row, x, y) and row.page then self:goToPage(row.page); return true end
        end
    end
    -- a click on a page turns it: the left page back, the right page on
    if g and inRect(g.left, x, y) then self:turn(-1); return true end
    if g and inRect(g.right, x, y) then self:turn(1); return true end
    return true
end

function ZeD_GuideBook:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down and self:stripHit(x, y) == down then self:press(down) end
    return true
end
function ZeD_GuideBook:onMouseUpOutside() self._down = nil end

function ZeD_GuideBook:onMouseWheel(del)
    self:turn(del > 0 and 1 or -1)
    return true
end

function ZeD_GuideBook:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_GuideBook:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then B.close(self.playerNum); GameKeyboard.eatKeyPress(key)
    elseif key == Keyboard.KEY_LEFT or key == Keyboard.KEY_PRIOR then self:turn(-1)
    elseif key == Keyboard.KEY_RIGHT or key == Keyboard.KEY_NEXT then self:turn(1)
    elseif key == Keyboard.KEY_HOME then self:goToPage(3) end
end

-- the controller: LB, RB and the D-pad's left and right turn the pages; Y the contents; Down to the strip
-- (left and right walk it, A presses, Up back to the book); B closes
function ZeD_GuideBook:onGainJoypadFocus(jd) self.joyfocus = jd end
function ZeD_GuideBook:onLoseJoypadFocus(jd) self.joyfocus = nil end
function ZeD_GuideBook:onJoypadDown(button, jd)
    if button == Joypad.BButton then B.close(self.playerNum)
    elseif button == Joypad.LBumper then self:turn(-1)
    elseif button == Joypad.RBumper then self:turn(1)
    elseif button == Joypad.YButton then self:goToPage(3)
    elseif button == Joypad.AButton and self.footFocus then
        self:press(({ "startup", "prev", "toc", "next" })[self.footFocus])
    end
end
function ZeD_GuideBook:onJoypadDirLeft()
    if self.footFocus then self.footFocus = math.max(1, self.footFocus - 1); sound("UISelectListItem") else self:turn(-1) end
end
function ZeD_GuideBook:onJoypadDirRight()
    if self.footFocus then self.footFocus = math.min(4, self.footFocus + 1); sound("UISelectListItem") else self:turn(1) end
end
function ZeD_GuideBook:onJoypadDirDown() if not self.footFocus then self.footFocus = 4; sound("UISelectListItem") end end
function ZeD_GuideBook:onJoypadDirUp() if self.footFocus then self.footFocus = nil; sound("UISelectListItem") end end

function ZeD_GuideBook:update()
    ISPanelJoypad.update(self)
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (B.qaJoy and self or nil)
end

-- ---------------------------------------------------------------------------
-- ENTRY (ZeD.Guide.open sends here while the Full look is chosen)
-- ---------------------------------------------------------------------------
function B.open(pn, want)
    pn = pn or 0
    local bk = B.books[pn]
    if not bk then
        bk = ZeD_GuideBook:new(pn)
        bk:initialise()
        bk:instantiate()
        B.books[pn] = bk
    end
    bk._clips = {}
    bk:readTopics(bk:unit())
    if want then
        local id = want
        if not bk.byId[id] then for _, t in ipairs(bk.flat) do if t.titleKey == want then id = t.id end end end
        if bk.byId[id] then bk:goToTopic(id) end
    else
        bk.spread = 1
    end
    bk.footFocus = nil
    if not bk:isReallyVisible() then
        bk:setVisible(true)
        bk:addToUIManager()
        bk:setAlwaysOnTop(true)
        pcall(setGameSpeed, 0)
    end
    bk:bringToTop()
    local jd = JoypadState.players[pn + 1]
    if jd then
        if jd.focus ~= bk then bk._prevFocus = jd.focus end
        jd.focus = bk
        jd.activeWhilePaused = true
        updateJoypadFocus(jd)
    end
    return bk
end

function B.isOpen(pn)
    local bk = B.books[pn or 0]
    return bk ~= nil and bk:isReallyVisible()
end

function B.close(pn)
    local bk = B.books[pn or 0]
    if not bk then return end
    bk:setVisible(false)
    bk:removeFromUIManager()
    bk._clips = {}
    pcall(setGameSpeed, 1)
    local jd = JoypadState.players[(pn or 0) + 1]
    if jd then
        jd.focus = bk._prevFocus
        bk._prevFocus = nil
        updateJoypadFocus(jd)
    end
end
