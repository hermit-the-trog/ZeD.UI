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
-- The type follows ZeD's text size like every ZeD surface (QA, Nov 3 2026: Large text never reached the book):
-- each size below is its Small size times the text-size preset (T.scale over the root scale); long topics run on.
local BASE_TYPE = { TEXT = 12.5, CAP = 10, FOLIO = 9, CHAP = 13, OPEN = 30, TITLE = 22, DECK = 14, BAR = 19 }
local TM_ = 1
local function applyType()
    local m = 1
    pcall(function() m = ZeD.T.scale / (ZeD.T.root or ZeD.Scale.root()) end)
    if not (m and m > 0.5 and m < 3) then m = 1 end
    TM_ = m
    for k, v in pairs(BASE_TYPE) do U[k] = v * m end
    return m
end
-- the room left at the top of the screen for the game's "Game Paused" box (QA: it sat over the book at the Deck)
local TOP = 34

local INK = { r = 0.137, g = 0.165, b = 0.227 }
local PAPER = { r = 0.961, g = 0.925, b = 0.824 }
-- the button pictures printed in the book: its ink on its paper (ZeD_PadGlyphs.draw's palette)
local BOOK_PAL = { text = INK, surf3 = PAPER, surf1 = PAPER, base = PAPER }
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
-- THE TEXT LAYER. Lua's drawTextZoomed draws a distance-field face without the game's SDF shader, so the game's
-- faces come out soft with a dark halo (QA, Nov 3 2026, punch list 83). The game's own text atoms (PZAPI's
-- UI.Text, AtomUIText) draw through that shader, so the book's words are a pool of them, laid over the pages
-- each frame at screen positions, one for each run of words; the panel draws everything else.
local LAYER = { root = nil, pool = {}, n = 0, panel = nil }
local function layerReady()
    if LAYER.root then return true end
    if not (PZAPI and PZAPI.UI and PZAPI.UI.Node and PZAPI.UI.Text) then return false end
    local ok = pcall(function()
        -- (a one-pixel root, never handed to the UIManager: an atom root there draws under ZeD's always-on-top
        -- book whatever is raised (QA, Nov 3 2026). The book draws it itself, after its own drawing, in render.)
        local UI = PZAPI.UI
        local root = UI.Node{ x = 0, y = 0, width = 1, height = 1 }
        UI._setParentChildRelationship(root)
        UI._applyHooks(root)
        UI._createAtomObjs(root)
        UI._internalInit(root)
        UI._initElement(root)
        UI._initResize(root)
        LAYER.root = root
    end)
    return ok and LAYER.root ~= nil
end
function B.layerBegin(panel)
    LAYER.n = 0
    LAYER.panel = layerReady() and panel or nil
    if LAYER.panel and LAYER.root and not LAYER.root.visible then LAYER.root:setVisible(true) end
end
local function layerText(font, s, ax, ay, z, c, a)
    LAYER.n = LAYER.n + 1
    local node = LAYER.pool[LAYER.n]
    if not node then
        node = PZAPI.UI.Text{ font = font, text = s, x = ax, y = ay, scaleX = z, scaleY = z, r = c.r, g = c.g, b = c.b, a = a, width = 1, height = 1 }
        PZAPI.UI._addChild(LAYER.root, node)
        LAYER.pool[LAYER.n] = node
        return
    end
    if node.font ~= font then node:setFont(font) end
    if node.text ~= s then node:setText(s) end
    if node.x ~= ax then node:setX(ax) end
    if node.y ~= ay then node:setY(ay) end
    if node.scaleX ~= z then node:setScaleX(z); node:setScaleY(z) end
    if node.r ~= c.r or node.g ~= c.g or node.b ~= c.b or node.a ~= a then node:setColor(c.r, c.g, c.b, a) end
    if not node.visible then node:setVisible(true) end
end
function B.layerEnd()
    for i = LAYER.n + 1, #LAYER.pool do
        local node = LAYER.pool[i]
        if node.visible then node:setVisible(false) end
    end
end
function B.layerHide()
    for _, node in ipairs(LAYER.pool) do if node.visible then node:setVisible(false) end end
    if LAYER.root and LAYER.root.visible then LAYER.root:setVisible(false) end
end
function B.layerToTop() if LAYER.root and LAYER.root.javaObj then pcall(function() LAYER.root.javaObj:bringToTop() end) end end

local function drawAt(panel, f, s, x, baseY, px, c, a)
    local z = zoom(f, px)
    local y = baseY - f.base * z
    if LAYER.panel == panel then
        layerText(f.font, s, panel:getAbsoluteX() + x, panel:getAbsoluteY() + y, z, c, a or 1)
    else
        panel:drawTextZoomed(s, x, y, z, c.r, c.g, c.b, a or 1, f.font)
    end
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
        local ww = wd.tex and ((ZeD.Guide and ZeD.Guide.inlineW) and ZeD.Guide.inlineW(wd.tex, px * 1.05) or icon) or textW(f, wd.word, px)
        if #cur > 0 and cw + sp + ww > lim() then flush(false) end
        cw = cw + ((#cur > 0) and sp or 0) + ww
        cur[#cur + 1] = { word = wd.word, tex = wd.tex, ww = ww }
    end
    flush(true)
    return lines, n
end

-- a line, justified unless it ends its paragraph
-- a line, ragged right; each run of words between the game's small pictures is one string
local function drawLine(panel, f, px, l, x, baseY, c)
    local sp = spaceW(f, px)
    local gaps = #l.items - 1
    -- (ragged right: the text atoms space words by whole spaces, so justifying doubled some gaps; QA, Nov 3 2026)
    local extraN = 0
    local xx = x + l.indent
    local runX, run = xx, nil
    local function flush()
        if run then drawAt(panel, f, run, runX, baseY, px, c) end
        run = nil
    end
    for i, it in ipairs(l.items) do
        if it.tex then
            flush()
            local s = px * 1.05
            ZeD.Guide.inlineDraw(panel, it.tex, xx, baseY - s * 0.82, s, INK, BOOK_PAL)
        else
            if run then run = run .. it.word else run, runX = it.word, xx end
        end
        xx = xx + it.ww
        if i <= gaps then
            local k = 1 + ((extraN > 0) and (math.floor(extraN * i / gaps) - math.floor(extraN * (i - 1) / gaps)) or 0)
            if run and not (l.items[i + 1] and l.items[i + 1].tex) then run = run .. string.rep(" ", k) end
            xx = xx + sp * k
        end
    end
    flush()
end

-- ---------------------------------------------------------------------------
-- THE PAGES
-- ---------------------------------------------------------------------------
-- the section's own words for its chapter opener and the contents (keys by the game's section title key)
local function stemOf(titleKey) return tostring(titleKey):match("^SurvivalGuide_(.-)_title$") or tostring(titleKey) end
local function blurb(s)
    -- (ZeD's own chapters carry their blurb's key)
    local k = s.blurbKey or ("UI_ZeD_Guide_Blurb_" .. stemOf(s.titleKey))
    local t = tr(k)
    return t ~= k and t or ""
end
-- (one capture: Kahlua hands an empty capture to the function as nil, so "a" would break a two-capture form)
local function titleCase(s) return (s:gsub("%w[%w']*", function(w) return upper(w:sub(1, 1)) .. w:sub(2) end)) end

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
-- The pages, as a flow (the director, Nov 3 2026: topics share a page): a chapter opens on a fresh page with its
-- heading, the clip and the line under it; each later topic follows on the same page under its own heading when its
-- heading, clip and three lines still fit, else on the next; a long topic runs on. A topic with The Rules in Numbers
-- starts a left page and its rules page faces it. Each page is a list of placed items (baselines and tops in px).
local RULE_ROWS = 22   -- a rules page's rows at most (a longer table runs on)
function B.paginate(bk, u)
    local px = function(n) return n * u end
    local pages = { { kind = "blank" }, { kind = "title" }, { kind = "contents" }, { kind = "intro" } }
    local textW_ = px(U.PW - U.M * 2)
    local lineH = px(U.TEXT) * U.LEAD
    local bottom = px(U.PH - U.FOOT - U.MT)
    -- a chapter opener's clip spans the text; every other topic's is two-thirds of it, centred, so two short
    -- topics share a page (the director, Nov 4 2026)
    local clipW = { [true] = textW_, [false] = math.floor(textW_ * 2 / 3) }
    local clipH = { [true] = math.floor(textW_ / 2), [false] = math.floor(textW_ / 3) }
    local page, y = nil, 0
    bk.sectionPage, bk.pageOf = {}, {}

    local function newPage(si, s, opener)
        page = { kind = "flow", si = si, section = s, items = {} }
        pages[#pages + 1] = page
        y = px(U.MT) + px(U.CHAP)
        local label = opener and tr("UI_ZeD_Guide_BookChapter", si) or (tr("UI_ZeD_Guide_BookChapter", si) .. "  |  " .. s.title)
        page.items[#page.items + 1] = { k = "label", y = y, text = label, px = px(U.CHAP) * (opener and 1.1 or 0.9) }
        y = y + px(U.CHAP) * 0.6
        page.fresh = true
    end
    local function add(it) page.items[#page.items + 1] = it; page.fresh = false end
    local function heads(text, hp)
        for _, l in ipairs(wrapWords(wordsOf(upper(text)), F.head, hp, function() return textW_ end, 1, 0)) do
            y = y + hp * 1.08
            local words = {}
            for _, it in ipairs(l.items) do words[#words + 1] = it.word or "" end
            add({ k = "head", y = y - hp * 0.18, text = table.concat(words, " "), px = hp })
        end
    end
    local function clip(t, opener)
        if not (t.video and t.video ~= "") then return end
        add({ k = "clip", y = y, w = clipW[opener], h = clipH[opener], topic = t })
        y = y + clipH[opener] + px(U.CAP) * 1.5
        add({ k = "caption", y = y, text = t.title })
        y = y + px(U.CAP) * 0.7
    end
    local function body(t, si, s)
        -- the two ways (ZeD.Guide.twoWays): a small ruled table, its heads, then a line an action. On a controller it
        -- leads the topic (the director, Nov 4 2026, "Option 3"); on a keyboard it follows the text and keeps the
        -- text's last two lines with it (QA: a box stood alone at the top of the next page)
        local ways = ZeD.Guide.twoWays and ZeD.Guide.twoWays(t)
        local rowH = px(U.TEXT) * 1.45
        local wl, need = {}, 0
        if ways then
            local half = textW_ / 2 - px(8)
            for i, r in ipairs(ways) do
                if r.kbText then
                    local a = wrapWords(wordsOf(r.kbText), F.text, px(U.TEXT), function() return half end, 1, 0)
                    local b = wrapWords(wordsOf(r.padText), F.text, px(U.TEXT), function() return half end, 1, 0)
                    wl[i] = { a = a, b = b, n = math.max(#a, #b, 1) }
                else
                    wl[i] = { n = 1 }
                end
            end
            local rows = 0
            for i = 1, #ways do rows = rows + wl[i].n * rowH end
            need = px(U.TEXT) * 1.2 + px(U.CAP) * 1.6 + math.min(rows, rowH * 4) + px(6)
        end
        local function box()
            if y + need > bottom then newPage(si, s, false) end
            y = y + px(U.TEXT) * 1.2 + px(U.CAP)
            local texty = ways[1] and ways[1].kbText ~= nil
            add({ k = "waysHead", y = y, texty = texty })
            y = y + px(U.CAP) * 0.6
            for i, r in ipairs(ways) do
                local n = wl[i].n
                if y + n * rowH > bottom then
                    newPage(si, s, false)
                    y = y + px(U.CAP)
                    add({ k = "waysHead", y = y, texty = texty })
                    y = y + px(U.CAP) * 0.6
                end
                y = y + rowH
                add({ k = "waysRow", y = y, row = r, a = wl[i].a, b = wl[i].b, rowH = rowH })
                y = y + (n - 1) * rowH
            end
            y = y + px(6)
        end
        local padFirst = ways and bk._joyRead
        if padFirst then box() end
        local lines = bodyLines(t, F.text, px(U.TEXT), textW_)
        for i, l in ipairs(lines) do
            local keep = (ways and not padFirst and i == math.max(1, #lines - 1)) and ((#lines - i + 1) * lineH + need) or lineH
            if y + keep > bottom then newPage(si, s, false) end
            y = y + lineH
            add({ k = "line", y = y, line = l })
        end
        if ways and not padFirst then box() end
    end

    for si, s in ipairs(bk.sections) do
        for ti, t in ipairs(s.topics) do
            local first = ti == 1
            local rf = ZeD.Guide.Rules and ZeD.Guide.Rules[t.titleKey]
            if rf then
                -- a fresh left page (a blank before it if need be), so the rules page faces it
                if (#pages + 1) % 2 == 0 then pages[#pages + 1] = { kind = "blank" } end
                newPage(si, s, first)
            elseif first then
                newPage(si, s, true)
            else
                -- room for the heading, the clip and three lines here, or the next page
                local hp = px(U.TITLE)
                local nHead = #wrapWords(wordsOf(upper(t.title)), F.head, hp, function() return textW_ end, 1, 0)
                local need = px(U.TEXT) * 1.2 + nHead * hp * 1.08 + px(6)
                if t.video and t.video ~= "" then need = need + clipH[false] + px(U.CAP) * 2.2 end
                need = need + lineH * 3
                if not page or page.kind ~= "flow" or y + need > bottom then newPage(si, s, false) end
            end
            bk.pageOf[t.id] = #pages
            if first then
                bk.sectionPage[s.id] = #pages
                heads(s.title, px(U.OPEN))
                y = y + px(10)
                clip(t, true)
                local d = blurb(s)
                local dl = {}
                if d ~= "" then dl = wrapWords(wordsOf(titleCase(d:gsub("%.$", ""))), F.sansB, px(U.DECK), function() return textW_ - px(20) end, 1, 0) end
                for _, l in ipairs(dl) do
                    y = y + px(U.DECK) * 1.3
                    local words = {}
                    for _, it in ipairs(l.items) do words[#words + 1] = it.word or "" end
                    add({ k = "deck", y = y, text = table.concat(words, " ") })
                end
                y = y + ((#dl > 0) and px(8) or 0) + px(U.TEXT) * 1.5
                add({ k = "sub", y = y, text = t.title })
                y = y + px(U.TEXT) * 0.3
            else
                if not page.fresh then y = y + px(U.TEXT) * 1.2 end
                heads(t.title, px(U.TITLE))
                y = y + px(6)
                clip(t, false)
            end
            body(t, si, s)
            if rf then
                -- (each table its own rules page, the first facing the topic)
                -- (a long table, 97 traits or 55 crops, runs on over as many pages as it needs: its first note
                -- before the first part, the rest after the last)
                for ri, rules in ipairs(ZeD.Guide.rulesList(t) or {}) do
                    local n, per = #rules.rows, RULE_ROWS
                    local parts = math.max(1, math.ceil(n / per))
                    for c = 1, parts do
                        local part = rules
                        if parts > 1 then
                            local rows = {}
                            for i = (c - 1) * per + 1, math.min(n, c * per) do rows[#rows + 1] = rules.rows[i] end
                            local notes = { (c == 1) and (rules.notes and rules.notes[1]) or false }
                            if c == parts then for i = 2, #(rules.notes or {}) do notes[i] = rules.notes[i] end end
                            local title = rules.title or tr("UI_ZeD_Guide_Rules")
                            if c > 1 then title = title .. " " .. tr("UI_ZeD_Guide_BookContinued") end
                            part = { title = title, cols = rules.cols, rows = rows, notes = notes, spoiler = rules.spoiler }
                        end
                        pages[#pages + 1] = { kind = "rules", topic = t, section = s, si = si, rules = part, ri = ri }
                    end
                end
                page = nil
            end
        end
    end
    if #pages % 2 == 1 then pages[#pages + 1] = { kind = "blank" } end
    bk.pages = pages
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
    local joy = ZeD.Guide.onPad(self.playerNum)
    self._joyRead = joy
    self.sections, self.byId, self.flat = ZeD.Guide.readTopicList(joy)
    self._u = u
    B.paginate(self, u)
end

-- the unit (screen px per design unit): the UI scale, smaller when the book would not fit the screen
function ZeD_GuideBook:unit()
    local T = ZeD.T
    local pn = self.playerNum
    -- The page takes the screen's scale (T.px also carries the text size, which only the type takes), and on a
    -- small screen it grows to fill the screen, up to its 1080p size: a book is read, not glanced at (QA, the Deck).
    local root = T.root or (T.px(100) / 100)
    local cap = math.max(root, 1)
    local wUnits = U.PW * 2 + U.EDGE * 2 + 20
    local hUnits = U.PH + U.STRIP_GAP + 20 + TOP
    local fit = math.min(getPlayerScreenWidth(pn) / wUnits, (getPlayerScreenHeight(pn) - ZeD.Molecules.bandH()) / hUnits)
    return math.min(cap, fit)
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
    local m = applyType()
    -- (a new scale or text size, or a controller picked up or put down: the pages again, in its words)
    if self._u ~= u or self._m ~= m or ZeD.Guide.onPad(self.playerNum) ~= self._joyRead then self._m = m; self:readTopics(u) end
    local bw, bh = U.PW * 2 * u, U.PH * u
    local stripH = ZeD.Molecules.bandH()
    local total = bh + U.STRIP_GAP * u + stripH
    local g = {}
    g.u = u
    g.book = { x = math.floor((sw - bw) / 2), y = math.floor(TOP * u + (sh - TOP * u - total) / 2), w = bw, h = bh }
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
            local valid = false
            if ok and v then pcall(function() valid = v:isValid() end) end
            if ok and v and valid then c = { video = v } end
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

function ZeD_GuideBook:drawFlowPage(p, x, y, w, u)
    local m = U.M * u
    local tx, tw_ = x + m, w - m * 2
    local cx = x + w / 2
    for _, it in ipairs(p.items) do
        local k = it.k
        if k == "line" then
            drawLine(self, F.text, U.TEXT * u, it.line, tx, y + it.y, INK)
        elseif k == "head" then
            drawCentre(self, F.head, it.text, cx, y + it.y, it.px, INK)
        elseif k == "label" then
            drawAt(self, F.sansB, it.text, tx, y + it.y, it.px, INK)
        elseif k == "clip" then
            local c = self:clipTex(it.topic)
            local cy = y + it.y
            local cw_ = it.w or tw_
            local cx_ = tx + math.floor((tw_ - cw_) / 2)
            self:drawRect(cx_, cy, cw_, it.h, 1, INK.r, INK.g, INK.b)
            if c and c.video then
                pcall(function() c.video:RenderFrame() end)
                self:drawTextureScaled(c.video, cx_, cy, cw_, it.h, 1, 0.96, 0.93, 0.84)
            elseif c and c.still then
                self:drawTextureScaledAspect(c.still, cx_, cy, cw_, it.h, 1, 0.96, 0.93, 0.84)
            end
        elseif k == "waysHead" then
            -- (three columns: what, mouse and keyboard, controller; a rule under the heads)
            local c2, c3 = tx + math.floor(tw_ / 3), tx + math.floor(tw_ * 2 / 3)
            if it.texty then c2, c3 = tx, tx + math.floor(tw_ / 2) end
            drawAt(self, F.sansB, ZeD.tr("UI_ZeD_Guide_WaysKB"), c2, y + it.y, U.CAP * u, INK)
            drawAt(self, F.sansB, ZeD.tr("UI_ZeD_Guide_WaysPad"), c3, y + it.y, U.CAP * u, INK)
            self:drawRect(tx, y + it.y + math.floor(U.CAP * u * 0.35), tw_, math.max(1, math.floor(u)), 1, INK.r, INK.g, INK.b)
        elseif k == "waysRow" and it.a then
            -- (words on both sides, each wrapped in its half)
            for c, lines in ipairs({ it.a, it.b }) do
                local lx = (c == 1) and tx or (tx + math.floor(tw_ / 2))
                for li, l in ipairs(lines) do drawLine(self, F.text, U.TEXT * u, l, lx, y + it.y + (li - 1) * it.rowH, INK) end
            end
        elseif k == "waysRow" then
            local r = it.row
            local c2, c3 = tx + math.floor(tw_ / 3), tx + math.floor(tw_ * 2 / 3)
            local s = U.TEXT * u * 1.05
            if r.label then
                -- (a long binding name cut to its column: QA, "Toggle Clothing Protection Panel")
                local lab, lim = r.label, math.floor(tw_ / 3) - 8 * u
                if textW(F.text, lab, U.TEXT * u) > lim then
                    while #lab > 1 and textW(F.text, lab .. "...", U.TEXT * u) > lim do lab = lab:sub(1, #lab - 1) end
                    lab = lab .. "..."
                end
                drawAt(self, F.text, lab, tx, y + it.y, U.TEXT * u, INK)
            end
            for c, list in ipairs({ r.kb, r.pad }) do
                local xx = (c == 1) and c2 or c3
                local lim = xx + math.floor(tw_ / 3)
                for _, o in ipairs(list) do
                    local ow = ZeD.Guide.inlineW(o, s)
                    if xx + ow <= lim then ZeD.Guide.inlineDraw(self, o, xx, y + it.y - s * 0.82, s, INK, BOOK_PAL) end
                    xx = xx + ow + 4 * u
                end
            end
        elseif k == "caption" then
            drawCentre(self, F.sansI, it.text, cx, y + it.y, U.CAP * u, INK)
        elseif k == "deck" then
            drawCentre(self, F.sansB, it.text, cx, y + it.y, U.DECK * u, INK)
        elseif k == "sub" then
            drawAt(self, F.sansB, it.text, tx, y + it.y, U.TEXT * u, INK)
        end
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
    drawCentre(self, F.sansB, upper(p.rules.title or tr("UI_ZeD_Guide_Rules")), x + w / 2, yy + barH * 0.68, U.BAR * u, INK)
    yy = yy + barH + U.TEXT * u
    local r = p.rules
    -- a spoiler (the director, Nov 4 2026): a grey bar to show the numbers, and a line on why they are hidden
    if ZeD.Guide.spoilHidden(p.topic, p.ri or 1, r) then
        local bh = U.TEXT * u * 2.2
        yy = yy + U.TEXT * u
        self:drawRect(tx, yy, tw_, bh, 1, TINT.r, TINT.g, TINT.b)
        self:drawRectBorder(tx, yy, tw_, bh, 1, INK.r, INK.g, INK.b)
        drawCentre(self, F.sansB, upper(tr("UI_ZeD_Guide_SpoilShow")), x + w / 2, yy + bh * 0.64, U.TEXT * u, INK)
        self._spoilRects = self._spoilRects or {}
        self._spoilRects[#self._spoilRects + 1] = { x = tx, y = yy, w = tw_, h = bh, topic = p.topic, ri = p.ri or 1 }
        yy = yy + bh + U.TEXT * u * 0.5
        local px0 = U.TEXT * u
        for _, l in ipairs(wrapWords(wordsOf(tr("UI_ZeD_Guide_SpoilWhy")), F.text, px0, function() return tw_ end, 1, 0)) do
            yy = yy + px0 * U.LEAD
            drawLine(self, F.text, px0, l, tx, yy, INK)
        end
        return
    end
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
    local cpx = 11 * u * TM_
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
    local cu = u * TM_   -- (the contents' type and rows, at the text size)
    self._contentsRows = {}
    for si, s in ipairs(self.sections) do
        local pg = self.sectionPage[s.id]
        local rowTop = yy
        yy = yy + 13 * cu
        local num = tostring(si) .. "."
        drawAt(self, F.sansB, num, tx + 18 * cu - textW(F.sansB, num, 10 * cu), yy, 10 * cu, INK)
        drawAt(self, F.sansB, upper(s.title), tx + 24 * cu, yy, 10 * cu, INK)
        yy = yy + 12 * cu
        local b = blurb(s)
        local bw = textW(F.sans, b, 9.5 * cu)
        drawAt(self, F.sans, b, tx + 24 * cu, yy, 9.5 * cu, INK)
        local ptxt = pg and tostring(printed(pg)) or ""
        local pw = textW(F.sansB, ptxt, 10 * cu)
        drawAt(self, F.sansB, ptxt, tx + tw_ - pw, yy, 10 * cu, INK)
        -- the dotted leader
        local dx = tx + 24 * cu + bw + 4 * u
        while dx < tx + tw_ - pw - 4 * u do
            self:drawRect(dx, yy - 1.5 * u, math.max(1, u), math.max(1, u), 1, INK.r, INK.g, INK.b)
            dx = dx + 4 * u
        end
        local row = { x = tx, y = rowTop, w = tw_, h = yy - rowTop + 4 * cu, page = pg }
        if hover and inRect(row, hover.x, hover.y) then
            self:drawRect(row.x - 4 * u, row.y + 2 * u, row.w + 8 * u, row.h, 0.08, INK.r, INK.g, INK.b)
        end
        self._contentsRows[#self._contentsRows + 1] = row
        yy = yy + 6 * cu
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
    elseif p.kind == "flow" then self:drawFlowPage(p, x, y, w, u)
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
    self._spoilRects = nil   -- (the spoiler bars on the open spread, made again as it draws)
    B.layerBegin(self)
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
    B.layerEnd()
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
    for _, r in ipairs(self._spoilRects or {}) do
        if inRect(r, x, y) then ZeD.Guide.spoil[ZeD.Guide.spoilKey(r.topic, r.ri)] = true; sound("UIActivateButton"); return true end
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
    elseif button == Joypad.AButton then
        -- (A on the pages shows the numbers a spoiler bar on the open spread hides)
        for _, r in ipairs(self._spoilRects or {}) do ZeD.Guide.spoil[ZeD.Guide.spoilKey(r.topic, r.ri)] = true end
        if self._spoilRects and #self._spoilRects > 0 then sound("UIActivateButton") end
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

-- the words: the text atoms drawn over everything the panel drew this frame
function ZeD_GuideBook:render()
    ISPanelJoypad.render(self)
    if LAYER.root and LAYER.panel == self then
        local ok, err = pcall(function() LAYER.root.javaObj:render() end)
        if not ok then ZeD.logOnce("survival guide book text", err) end
    end
end

function ZeD_GuideBook:update()
    ISPanelJoypad.update(self)
    if LAYER.root and LAYER.panel == self then pcall(function() LAYER.root.javaObj:update() end) end
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
    bk._m = applyType()
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
        -- (the open book is the pause: the game's "Game Paused" box would sit over its top on a small screen)
        pcall(function() bk._pausedMsg = UIManager.isShowPausedMessage(); UIManager.setShowPausedMessage(false) end)
    end
    bk:bringToTop()
    B.layerToTop()
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
    B.layerHide()
    if bk._pausedMsg ~= nil then pcall(function() UIManager.setShowPausedMessage(bk._pausedMsg) end); bk._pausedMsg = nil end
    bk._clips = {}
    pcall(setGameSpeed, 1)
    local jd = JoypadState.players[(pn or 0) + 1]
    if jd then
        jd.focus = bk._prevFocus
        bk._prevFocus = nil
        updateJoypadFocus(jd)
    end
end
