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
-- the contents over as many pages as it needs, the last facing the introduction with the author's photo (a blank
-- left-hand page between them when the contents takes an even count: the publisher's house ad, as old paperbacks ran
-- up front). The title page faces the copyright page, the publisher's small print (punch list 103).
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
B.applyType = applyType   -- (for ZeDUI/tools/qa/guide_ads_sim.lua: the text size without the panel)

-- the guide's ads (design, Nov 6 2026): media/textures/ZeD/guide/ads/<name>.png, 2x art; sizes in design px
ZeD.GuideAds = {
    size = { full = { 440, 628 }, half = { 440, 310 }, third = { 440, 205 }, quarter = { 215, 310 } },
    full = { "full_ready_prep", "full_greenes_grocery", "full_crossroads_mall" },
    half = { "half_well_regulated_militia", "half_better_bed_than_dead", "half_zacs_hardware", "half_body_chisel",
             "half_jamieton_army_surplus", "half_mccoys_lumber", "half_pharmahug" },
    third = { "third_maps_unlimited", "third_salt_river_bait", "third_pioneer_girls", "third_knob_creek_hunting",
              "third_aa_ron_hunting", "third_west_point_range", "third_nails_and_nuts", "third_time_4_sport",
              "third_zippee_market", "third_phils_pawn", "third_hit_vids", "third_rolling_fork_camp" },
    quarter = { "quarter_xray_specs", "quarter_iron_mike", "quarter_safari_club", "quarter_brine_buddies",
                "quarter_learn_magic", "quarter_kentucky_seed_co", "quarter_kitten_knives",
                "quarter_purrfect_barkner", "quarter_motorbikes_and_more", "quarter_wizards_keep",
                "quarter_juke_box_bowling", "quarter_seat_yourself_furniture" },
}
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

-- ---------------------------------------------------------------------------
-- THE ADS (design, Nov 6 2026, punch list 98; ZeDUI/HANDOFF_design_guide_ads_20261106.md): the back pages of a 1987
-- paperback. A whole page the layout leaves over takes a full-page ad (the publisher's house ad, drawn in Lua and
-- translated, is one of them), and when they have run out the smaller ads as a filler over its text block; a flow
-- page a third or more empty takes the largest that fits. Each ad at most once
-- a book: a slot with no ad left falls through to the next step, and at the end comes the ruled NOTES block.
-- The deal is made once each time the pages are laid out (B.paginate), never while drawing, so turning the pages
-- never reshuffles; a new layout (text size, pad or keyboard wording, language) deals again from the same seed, so
-- the order stays and only how far down each list the book gets moves.
-- ---------------------------------------------------------------------------
local AD_DIR = "media/textures/ZeD/guide/ads/"
local AD_GAP = 18        -- design px after each ad
local HOUSE = "house"    -- the publisher's own full-page ad in the full-page shuffle (drawAdPage draws it)

-- A seeded generator (Park and Miller's "minimal standard", stepped by Schrage's method): every value it makes or
-- multiplies stays below 2^31. Kahlua needs that (its % goes wrong past 2^31), and math.random is one stream for
-- the whole game, so it could not give the same book twice. Here math.floor does the modulo.
local PM_M, PM_A, PM_Q, PM_R = 2147483647, 16807, 127773, 2836
local function pmNext(x)
    local hi = math.floor(x / PM_Q)      -- x = hi * Q + lo
    local lo = x - hi * PM_Q
    x = PM_A * lo - PM_R * hi            -- (A * x) mod M without ever making A * x (at most 2147463604)
    if x <= 0 then x = x + PM_M end
    return x                             -- 1 .. M - 1
end
B.pmNext = pmNext

-- a string to a seed: each character folded in, kept below 2^24 so the next h * 33 stays below 2^31
function B.hashSeed(s)
    s = tostring(s or "")
    local h = 5381
    for i = 1, #s do
        h = h * 33 + (s:byte(i) or 0)
        h = h - math.floor(h / 16777213) * 16777213   -- (h mod 16777213, without Kahlua's %)
    end
    return pmNext(h + 1)                 -- (+1: the generator's seed must not be 0)
end

-- WHAT "A BOOK" IS. The Full look's book is the F1 guide, one panel a player (B.books[pn]); no guide item lies in
-- the world to carry an ID in its modData. So a book is a character in a save: the seed is the save's name and the
-- character's name, hashed. It needs nothing written (player modData written by a client may not last in
-- multiplayer), reads the same after a reload, and a new character or another save prints other back pages.
function B.adSeed(pn)
    local parts = {}
    pcall(function() parts[#parts + 1] = tostring(getWorld():getWorld()) end)
    pcall(function()
        local d = getSpecificPlayer(pn or 0):getDescriptor()
        parts[#parts + 1] = tostring(d:getForename()) .. " " .. tostring(d:getSurname())
    end)
    if #parts == 0 then parts[1] = "player " .. tostring(pn or 0) end
    return B.hashSeed(table.concat(parts, "|"))
end

-- a copy of `list` shuffled by the generator from state x (Fisher-Yates); returns it and the generator's state
local function shuffled(list, x)
    local out = {}
    for i, v in ipairs(list) do out[i] = v end
    for i = #out, 2, -1 do
        x = pmNext(x)
        local j = math.floor((x - 1) / (PM_M - 1) * i) + 1   -- 1 .. i (a fraction below 1, times i)
        out[i], out[j] = out[j], out[i]
    end
    return out, x
end

-- the book's deck: each size's list shuffled from the seed (the house ad among the full pages); `at` counts what
-- each list has dealt. houseUpFront: the house ad already has its page in the front matter (B.paginate), so it
-- leaves the full pages' list after the shuffle; the others keep their order and every other list is as it was.
function B.adDeck(seed, houseUpFront)
    local A = ZeD.GuideAds
    local x = pmNext(pmNext(seed or 1))   -- (two steps in: neighboring seeds part ways)
    local d = { at = { full = 0, half = 0, third = 0, quarter = 0 }, halfNext = true }
    local full = { HOUSE }
    for _, n in ipairs(A.full) do full[#full + 1] = n end
    d.full, x = shuffled(full, x)
    d.half, x = shuffled(A.half, x)
    d.third, x = shuffled(A.third, x)
    d.quarter, x = shuffled(A.quarter, x)
    if houseUpFront then
        for i = #d.full, 1, -1 do if d.full[i] == HOUSE then table.remove(d.full, i) end end
        d.houseUpFront = true
    end
    return d
end

-- the next n ads of a size (a list), or nil when fewer than n are left: never a repeat
local function deal(d, size, n)
    n = n or 1
    local at = d.at[size]
    if at + n > #d[size] then return nil end
    local out = {}
    for k = 1, n do out[k] = d[size][at + k] end
    d.at[size] = at + n
    return out
end

-- A filler's plan (y0 and y1 from the page's top, screen px): blocks { k, y, names } drawn by drawFiller.
-- 1. The First Days checklist when it fits (checkH its height, nil on other pages).
-- 2. Room for 310: a half, or a pair of quarters side by side (215 + 10 + 215); the book alternates, a half then a
--    pair, and takes the other when one runs out (a pair needs two quarters left).
-- 3. Room for 205: a third.  4. What is left: the ruled NOTES block.  18 after each ad.
-- st counts the slots asked for and missed (B.adReport).
local function planFiller(d, y0, y1, u, checkH, st)
    local plan = {}
    local S = ZeD.GuideAds.size
    local h = y1 - y0
    if h < 60 * u then return plan end
    if checkH and h >= checkH then
        plan[#plan + 1] = { k = "check", y = y0 }
        y0 = y0 + checkH + AD_GAP * u
        h = y1 - y0
        if h < 80 * u then return plan end
    end
    if h >= S.half[2] * u then
        st.ask310 = st.ask310 + 1
        local half, pair
        if d.halfNext then
            half = deal(d, "half")
            if not half then pair = deal(d, "quarter", 2) end
        else
            pair = deal(d, "quarter", 2)
            if not pair then half = deal(d, "half") end
        end
        if half or pair then
            plan[#plan + 1] = { k = half and "half" or "pair", y = y0, names = half or pair }
            d.halfNext = not half            -- (after a half a pair, after a pair a half)
            y0 = y0 + (S.half[2] + AD_GAP) * u
            h = y1 - y0
            if h < 80 * u then return plan end
        else
            st.miss310 = st.miss310 + 1      -- (no ad of that height left: on to the third)
        end
    end
    if h >= S.third[2] * u then
        st.ask205 = st.ask205 + 1
        local third = deal(d, "third")
        if third then
            plan[#plan + 1] = { k = "third", y = y0, names = third }
            y0 = y0 + (S.third[2] + AD_GAP) * u
            h = y1 - y0
            if h < 80 * u then return plan end
        else
            st.miss205 = st.miss205 + 1
        end
    end
    plan[#plan + 1] = { k = "notes", y = y0 }
    st.notes = st.notes + 1
    return plan
end

-- The deal, in page order: a whole page its full ad (p.ad: a name or "house"; false when they have run out, and the
-- page is then a filler over its whole text block, p.filler), each filler its plan (it.ads on a flow page's filler
-- item, p.filler.ads at a rules page's foot or on a whole page). textW_ the text block's width.
-- (a whole page's text block runs from the top margin to where a full ad ends, 6 over the foot)
local WHOLE_FOOT = U.PH - U.FOOT - 6
-- The feet of rules pages behind a spoiler bar are dealt last, from what is left: their ads stay hidden until the
-- reader shows the numbers, so they never take an ad a page in plain sight would then go without. (Whether a table
-- is a spoiler is fixed by the layout, not by whether its numbers are shown now, so showing them never deals again.)
-- The front matter's left-hand page before the introduction (p.front, B.paginate) is the house ad already: it is
-- not dealt, and the house ad leaves the deck so no later page repeats it.
function B.dealAds(bk, pages, u, textW_)
    local front = false
    for _, p in ipairs(pages) do if p.front then front = true; break end end
    local d = B.adDeck(bk._adSeed or 1, front)
    local st = { full = 0, fullMiss = 0, ask310 = 0, miss310 = 0, ask205 = 0, miss205 = 0, notes = 0, frontHouse = front and 1 or 0 }
    local later = {}   -- (the spoiler pages' feet, kept for the second pass)
    for _, p in ipairs(pages) do
        if p.front then
            p.ad = HOUSE                     -- (placed by B.paginate, never dealt)
        elseif p.kind == "ad" then
            local a = deal(d, "full")
            p.ad = a and a[1] or false
            p.filler = nil
            st.full = st.full + 1
            if not a then
                st.fullMiss = st.fullMiss + 1
                -- (no full ad left: the whole text block as a filler, the smaller ads before NOTES. QA, Nov 7 2026:
                -- at Large text with pad wording 6 whole pages had 4 full ads, and 2 printed NOTES while halves and
                -- quarters went unused)
                p.filler = { y = U.MT * u, y1 = WHOLE_FOOT * u }
                p.filler.ads = planFiller(d, p.filler.y, p.filler.y1, u, nil, st)
            end
        elseif p.kind == "flow" then
            for _, it in ipairs(p.items) do
                if it.k == "filler" then
                    local ch = it.check and bk:drawChecklist(0, textW_, 0, u, true) or nil
                    it.ads = planFiller(d, it.y, it.y1, u, ch, st)
                end
            end
        elseif p.kind == "rules" and p.filler then
            if p.rules and p.rules.spoiler then
                later[#later + 1] = p
            else
                p.filler.ads = planFiller(d, p.filler.y, p.filler.y1, u, nil, st)
            end
        end
    end
    -- the second pass: the hidden feet, in page order, take what the rest of the book left
    for _, p in ipairs(later) do
        p.filler.ads = planFiller(d, p.filler.y, p.filler.y1, u, nil, st)
    end
    st.at = d.at
    bk.adStats = st
    return st
end

-- one line on how far the ads went at this layout (QA's count: whether 34 ads cover every slot). Logged in -debug
-- each time it changes, so a text size or wording change shows its own count in console.txt.
function B.adReport(bk)
    local st = bk and bk.adStats
    if not st then return "no deal" end
    local A = ZeD.GuideAds
    local fh = st.frontHouse or 0
    return string.format("ZeD guide ads (text x%.2f, %s): full pages %d (%d with no full ad left)%s; 310 slots %d (%d with no half or pair left);"
        .. " 205 slots %d (%d with no third left); NOTES blocks %d; dealt full %d/%d, half %d/%d, quarter %d/%d, third %d/%d",
        TM_, bk._joyRead and "pad" or "keyboard", st.full, st.fullMiss, (fh > 0) and ", the house ad up front" or "",
        st.ask310, st.miss310, st.ask205, st.miss205, st.notes,
        st.at.full + fh, #A.full + 1, st.at.half, #A.half, st.at.quarter, #A.quarter, st.at.third, #A.third)
end

-- the textures, each loaded the first time a page draws it (all 34 at 2x are about 60 MB once loaded).
-- Flags 2 (the engine's TextureID reads them as bits when it uploads the texture): 2 = point filtering when the
-- texture is drawn LARGER than its PNG (u above 2), so the pixel pictures stay crisp there. Bit 1 (point filtering
-- when drawn smaller) stays off: at u 2 and below (1080p, 4K at 1.75x) the art is shrunk, and point sampling would
-- drop whole art pixels from the thin strokes of its type, so shrinking stays linear (smooth). Bit 4 (texture
-- compression) stays off too, so the game's compression option cannot blotch the fine print.
local AD_TEX_FLAGS = 2
local _adTex = {}
local function adTex(name)
    local t = _adTex[name]
    if t == nil then
        local path = AD_DIR .. name .. ".png"
        t = (Texture and Texture.getSharedTexture and Texture.getSharedTexture(path, AD_TEX_FLAGS)) or getTexture(path) or false
        _adTex[name] = t
    end
    return t or nil
end
-- a whole screen pixel: v rounded to the nearest (half up), so the art never sits between pixels, where linear
-- filtering would smear it further
local function snap(v) return math.floor(v + 0.5) end
-- an ad at its design size times u, top left at (x, y), on whole pixels; returns its right edge (the pair's second
-- quarter starts from it)
local function drawAd(panel, name, size, x, y, u)
    local s = ZeD.GuideAds.size[size]
    local x0, w = snap(x), snap(s[1] * u)
    local tex = adTex(name)
    if tex then panel:drawTextureScaled(tex, x0, snap(y), w, snap(s[2] * u), 1, 1, 1, 1) end
    return x0 + w
end

-- the page list for a reading of the topics (front matter, then a page a topic and its rules page)
-- The pages, as a flow (the director, Nov 3 2026: topics share a page): a chapter opens on a fresh page with its
-- heading, the clip and the line under it; each later topic follows on the same page under its own heading when its
-- heading, clip and three lines still fit, else on the next; a long topic runs on. A topic with The Rules in Numbers
-- starts a left page and its rules page faces it. Each page is a list of placed items (baselines and tops in px).
local RULE_ROWS = 22   -- a rules page's rows at most (a longer table runs on)
-- the printed number of the page at index i (the title page is the first right-hand page, ii)
local function printed(i) return i + 1 end
function B.paginate(bk, u)
    local px = function(n) return n * u end
    -- (the front matter as the chapters are laid out: the contents' own pages are counted after them, below)
    -- (the first left-hand page, facing the title page, is the copyright page: drawCopyrightPage)
    local pages = { { kind = "copyright" }, { kind = "title" }, { kind = "contents" }, { kind = "intro" } }
    local textW_ = px(U.PW - U.M * 2)
    local lineH = px(U.TEXT) * U.LEAD
    local bottom = px(U.PH - U.FOOT - U.MT)
    -- a chapter opener's clip spans the text; every other topic's is two-thirds of it, centred, so two short
    -- topics share a page (the director, Nov 4 2026)
    local clipW = { [true] = textW_, [false] = math.floor(textW_ * 2 / 3) }
    local clipH = { [true] = math.floor(textW_ / 2), [false] = math.floor(textW_ / 3) }
    local page, y = nil, 0
    bk.sectionPage, bk.pageOf = {}, {}
    -- (the publisher fills its pages, the director, Nov 4 2026: "publishers [don't] like printing blank pages. It
    -- costs more money, so they generally fill the content"): a flow page a third or more empty takes a filler, from
    -- 16 under where its text ends to the foot. fillerRoom: that filler's height for a page ending at endY, or nil.
    local room = bottom - px(U.MT)
    local function fillerRoom(endY)
        if bottom - endY >= room / 3 then return bottom - (endY + px(16)) end
        return nil
    end
    -- THE FIRST DAYS CHECKLIST prints once, in its chapter (the director, Nov 7 2026: "I want the text to print"):
    -- at the head of the first of the chapter's fillers with the room for it, as before; when none has the room
    -- (Small text: QA, Nov 7 2026), as a block of its own at the chapter's end, on a new page if the last has no
    -- room, so it is never split, never over the text and never twice. Decided when the chapter is done (below).
    -- (measured in a pcall: if it throws, the book lays out without the checklist block, it never closes)
    local checkOk, checkH = pcall(bk.drawChecklist, bk, 0, textW_, 0, u, true)
    if not checkOk then ZeD.logOnce("survival guide checklist", checkH); checkH = nil end
    if type(checkH) ~= "number" then checkH = nil end
    local checkPage = nil   -- (the flow page whose filler opens with it)

    local function newPage(si, s, opener)
        if page then page.endY = y end
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
            -- (a topic's last line never alone atop a page: the line before goes with it, QA Nov 4 2026)
            local keep = (i == #lines - 1) and (2 * lineH) or lineH
            if ways and not padFirst and i == math.max(1, #lines - 1) then keep = (#lines - i + 1) * lineH + need end
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
                -- (the page that makes room is a full-page ad, never a blank page: the director, Nov 4 2026,
                -- "options for callouts and advertisement styling. Look more built by a large publisher"; which
                -- ad is dealt when the pages are done, B.dealAds)
                if (#pages + 1) % 2 == 0 then pages[#pages + 1] = { kind = "ad" } end
                -- a fresh left page (a blank before it if need be), so the rules page faces it
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
                    local long = 0
                    for _, row in ipairs(rules.rows) do long = math.max(long, #tostring(row[#rules.cols] or "")) end
                    if long > 28 then per = 16 end   -- (QA: 16 still fit on the Deck at Large text)
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
                if page then page.endY = y end
                page = nil
            end
        end
        if checkH and s.id == "zedch:firstdays" and bk.sectionPage[s.id] then
            -- (the chapter is done: its last page ends at y, the next chapter opens a page of its own)
            for i = bk.sectionPage[s.id], #pages do
                local pg = pages[i]
                local endY = (pg == page) and y or pg.endY
                local h = pg.kind == "flow" and pg.section == s and endY and fillerRoom(endY)
                if h and h >= checkH then checkPage = pg; break end
            end
            if not checkPage then
                if not page or y + px(16) + checkH > bottom then newPage(si, s, false) end
                add({ k = "check", y = y + px(16) })
                y = y + px(16) + checkH
            end
        end
    end
    if page then page.endY = y end
    -- THE CONTENTS, now the chapters' pages are known (B.contentsLayout): as many pages as its rows need after the
    -- title page, then the introduction on a right-hand page, facing the last contents page when their count is odd
    -- and after a left-hand page when it is even (as a printer would). That left-hand page is the publisher's house ad
    -- (the director, Nov 7 2026: old paperbacks ran an "also from this publisher" ad up front; p.front, so the deal
    -- leaves it be and never repeats the house ad later, B.dealAds). It is no text page: no chapter, topic or contents
    -- row points at it, and it has no section for the thumbs. The front matter is always an even
    -- count, so the chapters keep their sides; every page moves on by what the contents added (shift), and the rows
    -- print the numbers of the pages as they end up (laid out again while the shift grows: a wider number can wrap).
    local shift, cpages = 0, nil
    for _ = 1, 8 do
        cpages = B.contentsLayout(bk, u, function(s)
            local i = bk.sectionPage[s.id]
            return i and tostring(printed(i + shift)) or nil
        end)
        local n = #cpages
        local want = n + ((n % 2 == 0) and 1 or 0) - 1
        if want == shift then break end
        shift = want
    end
    local front = { pages[1], pages[2] }
    for _, cp in ipairs(cpages) do front[#front + 1] = cp end
    if #cpages % 2 == 0 then front[#front + 1] = { kind = "ad", ad = HOUSE, front = true } end
    front[#front + 1] = pages[4]
    bk.contentsPage, bk.contentsPages, bk.introPage = 3, #cpages, #front
    for i = 5, #pages do front[#front + 1] = pages[i] end
    pages = front
    for k, i in pairs(bk.sectionPage) do bk.sectionPage[k] = i + shift end
    for k, i in pairs(bk.pageOf) do bk.pageOf[k] = i + shift end
    for _, cp in ipairs(cpages) do
        for _, r in ipairs(cp.rows) do r.page = bk.sectionPage[r.sid] end
    end
    for _, pg in ipairs(pages) do
        local fh = pg.kind == "flow" and pg.endY and fillerRoom(pg.endY)
        if fh then
            pg.items[#pg.items + 1] = { k = "filler", y = pg.endY + px(16), y1 = bottom, check = (pg == checkPage) }
        elseif pg.kind == "rules" then
            -- (a rules page's foot: the page measured now, drawn dry, so its filler is dealt with the rest; the
            -- numbers counted as shown even behind a spoiler bar, so showing them never deals again)
            local ok, endY = pcall(bk.drawRulesPage, bk, pg, 0, 0, px(U.PW), u, true)
            if ok and endY and bottom - endY >= px(U.PH - U.MT - U.FOOT) / 3 then
                pg.filler = { y = endY + px(16), y1 = bottom }
            end
        end
    end
    if #pages % 2 == 1 then pages[#pages + 1] = { kind = "ad" } end
    bk.pages = pages
    -- the ads, dealt for this layout (THE ADS, above)
    local ok, err = pcall(B.dealAds, bk, pages, u, textW_)
    if not ok then ZeD.logOnce("survival guide ads", err) end
end

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
    -- (the ads' seed: this character in this save, read again each time since a split-screen seat can change hands)
    self._adSeed = B.adSeed(self.playerNum)
    B.paginate(self, u)
    -- (in -debug, the ads' count for this layout when it changes: QA's question of whether 34 ads cover the book)
    local ok, dbg = pcall(isDebugEnabled)
    if ok and dbg then
        local okR, line = pcall(B.adReport, self)
        if okR and line ~= self._adLine then self._adLine = line; print(line) end
    end
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
        elseif k == "filler" then
            self:drawFiller(tx, tw_, y, it, u)
        elseif k == "check" then
            -- (the First Days checklist in the chapter's flow, where no filler had the room: B.paginate)
            self:drawChecklist(tx, tw_, y + it.y, u)
        elseif k == "caption" then
            drawCentre(self, F.sansI, it.text, cx, y + it.y, U.CAP * u, INK)
        elseif k == "deck" then
            drawCentre(self, F.sansB, it.text, cx, y + it.y, U.DECK * u, INK)
        elseif k == "sub" then
            drawAt(self, F.sansB, it.text, tx, y + it.y, U.TEXT * u, INK)
        end
    end
end

-- dry: measure only (B.paginate, for the page's filler): nothing drawn, the numbers counted as shown even behind a
-- spoiler; returns where the text ends, from the page's top
function ZeD_GuideBook:drawRulesPage(p, x, y, w, u, dry)
    local draw = not dry
    local m = U.M * u
    local tx, tw_ = x + m, w - m * 2
    local yy = y + U.MT * u
    -- the grey bar
    local barH = U.BAR * u * 1.9
    if draw then
        self:drawRect(tx, yy, tw_, barH, 1, TINT.r, TINT.g, TINT.b)
        self:drawRectBorder(tx, yy, tw_, barH, 1, INK.r, INK.g, INK.b)
        drawCentre(self, F.sansB, upper(p.rules.title or tr("UI_ZeD_Guide_Rules")), x + w / 2, yy + barH * 0.68, U.BAR * u, INK)
    end
    yy = yy + barH + U.TEXT * u
    local r = p.rules
    -- a spoiler (the director, Nov 4 2026): a grey bar to show the numbers, and a line on why they are hidden
    if draw and ZeD.Guide.spoilHidden(p.topic, p.ri or 1, r) then
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
            if draw then drawLine(self, F.text, px, l, tx, yy, INK) end
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
    for c = 1, draw and ncol or 0 do   -- (no columns to draw when dry)
        for li, l in ipairs(heads[c]) do
            local words = {}
            for _, it in ipairs(l.items) do words[#words + 1] = it.word or "" end
            drawAt(self, F.textB, table.concat(words, " "), colX[c], y0 + li * cpx * 1.25, cpx, INK)
        end
    end
    local ry = y0 + hl * cpx * 1.25 + 5 * u
    if draw then self:drawRect(tx + pad, ry, inner, math.max(1, 1.5 * u), 1, INK.r, INK.g, INK.b) end
    -- (the last column wraps in the room left; the row takes its lines: QA, the Deck ran them off the page)
    local lastW = math.max(40 * u, tx + pad + inner - colX[ncol])
    for _, row in ipairs(r.rows) do
        ry = ry + cpx * 1.5
        local lines = wrapWords(wordsOf(tostring(row[ncol] or "")), F.text, cpx, function() return lastW end, 1, 0)
        if draw then
            for c = 1, ncol - 1 do drawAt(self, F.text, row[c] or "", colX[c], ry, cpx, INK) end
            for li, l in ipairs(lines) do drawLine(self, F.text, cpx, l, colX[ncol], ry + (li - 1) * cpx * 1.3, INK) end
        end
        if #lines > 1 then ry = ry + (#lines - 1) * cpx * 1.3 end
        if draw then self:drawRect(tx + pad, ry + cpx * 0.45, inner, math.max(1, u * 0.6), 0.3, INK.r, INK.g, INK.b) end
    end
    ry = ry + cpx * 1.8
    if draw then drawCentre(self, F.textB, r.title or p.topic.title, x + w / 2, ry, cpx, INK) end
    local boxH = ry + pad - boxY
    if draw then self:drawRectBorder(tx, boxY, tw_, boxH, 1, INK.r, INK.g, INK.b) end
    yy = boxY + boxH + 6 * u
    for i = 2, #(r.notes or {}) do para(r.notes[i]) end
    if dry then return yy - y end
    -- its foot, when a third or more is left: the filler measured and dealt with the layout (B.paginate)
    if p.filler then self:drawFiller(tx, tw_, y, p.filler, u) end
end

-- A FILLER (what the publisher prints where the text leaves room): the shops' ads dealt for it (THE ADS, above),
-- then a ruled NOTES block as a real manual leaves for its owner.

-- the First Days checklist (the director, Nov 4 2026: tick-box checklists, the FEMA pamphlets' way): a framed box, its
-- head, the items each with an empty tick box; returns its height
local CHECK_N = 7
function ZeD_GuideBook:drawChecklist(tx, tw_, by, u, measureOnly)
    local px = U.TEXT * u
    local lineH = px * U.LEAD
    local ix, iw = tx + 12 * u, tw_ - 24 * u
    local sq = math.floor(px * 0.8)
    local rows = {}
    for i = 1, CHECK_N do rows[i] = wrapWords(wordsOf(tr("UI_ZeD_Guide_Check" .. i)), F.text, px, function() return iw - sq - 10 * u end, 1, 0) end
    local h = 14 * u + U.TITLE * u + 10 * u
    for i = 1, CHECK_N do h = h + #rows[i] * lineH + 4 * u end
    h = h + 10 * u
    if measureOnly then return h end
    local lw = math.max(1, math.floor(2 * u))
    for i = 0, lw - 1 do self:drawRectBorder(tx + i, by + i, tw_ - i * 2, h - i * 2, 1, INK.r, INK.g, INK.b) end
    local yy = by + 14 * u + U.TITLE * u * 0.8
    drawAt(self, F.head, upper(tr("UI_ZeD_Guide_CheckTitle")), ix, yy, U.TITLE * u * 0.85, INK)
    yy = yy + 6 * u
    self:drawRect(ix, yy, iw, math.max(1, u), 1, INK.r, INK.g, INK.b)
    yy = yy + 4 * u
    for i = 1, CHECK_N do
        for li, l in ipairs(rows[i]) do
            yy = yy + lineH
            if li == 1 then self:drawRectBorder(ix, yy - sq, sq, sq, 1, INK.r, INK.g, INK.b) end
            drawLine(self, F.text, px, l, ix + sq + 10 * u, yy, INK)
        end
        yy = yy + 4 * u
    end
    return h
end

-- NOTES: the word, a rule, then ruled lines down to y1
local function drawNotes(self, tx, tw_, y0, y1, u)
    local lineH = U.TEXT * u * U.LEAD
    local yy = y0 + U.CAP * u
    drawAt(self, F.sansB, upper(tr("UI_ZeD_Guide_Notes")), tx, yy, U.CAP * u * 1.1, INK)
    yy = yy + 5 * u
    self:drawRect(tx, yy, tw_, math.max(1, math.floor(1.5 * u)), 1, INK.r, INK.g, INK.b)
    local gapL = lineH * 1.35
    yy = yy + gapL
    while yy < y1 - 4 * u do
        self:drawRect(tx, yy, tw_, math.max(1, math.floor(u * 0.6)), 0.45, INK.r, INK.g, INK.b)
        yy = yy + gapL
    end
end

-- a filler f ({ y, y1, ads }, from the page's top at y) as dealt: the checklist, the ads, NOTES (planFiller)
function ZeD_GuideBook:drawFiller(tx, tw_, y, f, u)
    local S = ZeD.GuideAds.size
    for _, b in ipairs(f.ads or {}) do
        local by = y + b.y
        if b.k == "check" then
            self:drawChecklist(tx, tw_, by, u)
        elseif b.k == "half" then
            drawAd(self, b.names[1], "half", tx, by, u)
        elseif b.k == "pair" then
            -- (two quarters side by side, tops level: 215, a 10 gutter, 215. The second starts at the first's rounded
            -- right edge plus the rounded gutter, so both sit on whole pixels and the gutter stays even)
            local right = drawAd(self, b.names[1], "quarter", tx, by, u)
            drawAd(self, b.names[2], "quarter", right + math.floor((S.half[1] - S.quarter[1] * 2) * u + 0.5), by, u)
        elseif b.k == "third" then
            drawAd(self, b.names[1], "third", tx, by, u)
        elseif b.k == "notes" then
            drawNotes(self, tx, tw_, by, y + f.y1, u)
        end
    end
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

-- a contents page p (B.contentsLayout) at index pi: its heading and rows as laid out; each row drawn goes on the
-- list the mouse picks from (_contentsRows, made again each frame), with the page it sits on
function ZeD_GuideBook:drawContentsPage(p, x, y, w, u, hover, pi)
    local m = U.M * u
    local tx, tw_ = x + m, w - m * 2
    drawAt(self, F.head, p.head or upper(tr("UI_ZeD_Guide_BookContents")), tx, y + U.MT * u + 28 * u, p.headPx or 28 * u, INK)
    local cu = p.cu or (u * TM_)   -- (the contents' type and rows, at the text size it was laid out at)
    self._contentsRows = self._contentsRows or {}
    for _, r in ipairs(p.rows or {}) do
        local rowTop = y + r.y
        local yy = rowTop + 13 * cu
        local num = tostring(r.si) .. "."
        drawAt(self, F.sansB, num, tx + 18 * cu - textW(F.sansB, num, 10 * cu), yy, 10 * cu, INK)
        for k, l in ipairs(r.titles) do
            if k > 1 then yy = yy + 12 * cu end
            drawAt(self, F.sansB, l.s, tx + 24 * cu, yy, 10 * cu, INK)
        end
        for _, l in ipairs(r.blurbs) do
            yy = yy + 12 * cu
            if l.s ~= "" then drawAt(self, F.sans, l.s, tx + 24 * cu, yy, 9.5 * cu, INK) end
        end
        -- the page number and the dotted leader, on the blurb's last line
        local pw = textW(F.sansB, r.num, 10 * cu)
        drawAt(self, F.sansB, r.num, tx + tw_ - pw, yy, 10 * cu, INK)
        local dx = tx + 24 * cu + r.blurbs[#r.blurbs].w + 4 * u
        while dx < tx + tw_ - pw - 4 * u do
            self:drawRect(dx, yy - 1.5 * u, math.max(1, u), math.max(1, u), 1, INK.r, INK.g, INK.b)
            dx = dx + 4 * u
        end
        local row = { x = tx, y = rowTop, w = tw_, h = r.h, page = r.page, si = r.si, onPage = pi }
        if hover and inRect(row, hover.x, hover.y) then
            self:drawRect(row.x - 4 * u, row.y + 2 * u, row.w + 8 * u, row.h, 0.08, INK.r, INK.g, INK.b)
        end
        self._contentsRows[#self._contentsRows + 1] = row
    end
end

-- A WHOLE PAGE the layout leaves over (before a topic that faces its rules, the last page): the full-page ad dealt
-- for it (p.ad), at the text block; the publisher's house ad (below) is one of them, or has the front matter's page
-- before the introduction (p.front) and is then never dealt again; when they have run out, the filler dealt over the
-- whole text block (a half or a pair, a third, then NOTES: B.dealAds), drawn as every filler
function ZeD_GuideBook:drawFullAd(p, x, y, w, u)
    if p.ad == nil or p.ad == HOUSE then self:drawAdPage(x, y, w, u); return end
    local tx, top = x + U.M * u, y + U.MT * u
    if p.ad then drawAd(self, p.ad, "full", tx, top, u); return end
    if p.filler then self:drawFiller(tx, w - U.M * u * 2, y, p.filler, u); return end
    drawNotes(self, tx, w - U.M * u * 2, top, y + WHOLE_FOOT * u, u)
end

-- THE PUBLISHER'S HOUSE AD: a full-page mail-order ad in the 1980s survival magazines' manner, for the publisher's
-- own (fictional) titles, in the game's language. A heavy frame, the headline, a deck, a paragraph, the titles with
-- tick boxes, a price box and a coupon with a dashed edge.
-- Every line keeps inside the frame (QA, Nov 7 2026: the deck ran past both sides at Large text and in German at
-- Small, and the price filled its box edge to edge at Large): each part wraps to the frame's inner width (the titles
-- to their box, the price to its own), centered parts in even lines; the price box is its words plus half the price's
-- size each side (never under its old 92). When the wrapped words would push the coupon past the frame, the gaps
-- close up first (the same proportions, down to 55%); then a part that wrapped steps down one size (the deck, the
-- titles, the coupon, the paragraph, the headline, in that order). Name and Address wrap to leave a writing line;
-- a headline word too wide for the frame takes the headline a size down before it is cut. Laid out once for a
-- width, unit, text size, wording and measure epoch (ZeD_GuideBook:houseAd) and drawn from that list each frame.

-- one character from i: its last index (a UTF-8 run in plain Lua; in the game a string is characters, so i itself)
local function adCharEnd(s, i)
    local b = s:byte(i)
    if not b or b < 0xC0 or b > 0xF7 then return i end
    local j = i
    while true do
        local c = s:byte(j + 1)
        if c and c >= 0x80 and c <= 0xBF then j = j + 1 else break end
    end
    return j
end
-- the character at i: its code point and its last index
local function adCp(s, i)
    local e = adCharEnd(s, i)
    local cp = s:byte(i)
    if cp and e > i then
        cp = (e - i == 1) and (cp - 0xC0) or ((e - i == 2) and (cp - 0xE0) or (cp - 0xF0))
        for k = i + 1, e do cp = cp * 64 + (s:byte(k) - 0x80) end
    end
    return cp, e
end
-- may a line break between two characters (code points): never before a Thai mark that sits on the letter before
-- it, a Thai vowel that follows its consonant (sara a, aa, am, lakkhangyao), the repeat mark or the abbreviation
-- mark, or a Chinese or Japanese comma, stop or closing bracket; never after a Thai vowel written before its
-- consonant (sara e, ae, o, ai maimuan, ai maimalai)
local AD_NOSTART = { [0x3001] = true, [0x3002] = true, [0x300D] = true, [0x300F] = true, [0xFF01] = true, [0xFF09] = true,
                     [0xFF0C] = true, [0xFF0E] = true, [0xFF1A] = true, [0xFF1B] = true, [0xFF1F] = true,
                     [0x0E2F] = true, [0x0E30] = true, [0x0E31] = true, [0x0E32] = true, [0x0E33] = true,
                     [0x0E45] = true, [0x0E46] = true }
local function adThLead(cp) return cp ~= nil and cp >= 0x0E40 and cp <= 0x0E44 end
local function adMayBreak(cp, ncp)
    if not cp or not ncp then return true end
    if adThLead(cp) or AD_NOSTART[ncp] then return false end
    return not ((ncp >= 0x0E34 and ncp <= 0x0E3A) or (ncp >= 0x0E47 and ncp <= 0x0E4E))
end
-- a break Thai prefers (Thai runs without spaces and the book has no dictionary): where a syllable surely starts or
-- ends, before a vowel written before its consonant or after sara a or sara am; any break that may be is good
-- elsewhere (Chinese and Japanese break between any two characters)
local function adThai(cp) return cp ~= nil and cp >= 0x0E00 and cp <= 0x0E7F end
local function adGoodBreak(cp, ncp)
    if not (adThai(cp) or adThai(ncp)) then return true end
    return adThLead(ncp) or cp == 0x0E30 or cp == 0x0E33 or not adThai(cp) or not adThai(ncp)
end
-- the widest word that must not be cut (one with no Thai, Chinese, Japanese or Korean in it), or 0
local function adWidestWhole(text, f, px)
    local mx = 0
    for wd in tostring(text or ""):gmatch("%S+") do
        local whole, i = true, 1
        while i <= #wd do
            local cp, e = adCp(wd, i)
            if adThai(cp) or (cp and cp >= 0x2E80) then whole = false; break end
            i = e + 1
        end
        if whole then mx = math.max(mx, textW(f, wd, px)) end
    end
    return mx
end

-- words into lines no wider than maxW: { { s = the line, w = its width } }. A word wider than a line (Chinese,
-- Japanese and Thai run without spaces) is cut between characters, its first piece filling the line it starts on
-- (Thai at the last break it prefers, when that fills at least half the room).
-- A line's width is the larger of its words and spaces (as the pages measure them) and the whole string measured.
local function adWrap(text, f, px, maxW)
    local lines = {}
    local sp = spaceW(f, px)
    local cur, cw = nil, 0
    for wd in tostring(text or ""):gmatch("%S+") do
        local ww = textW(f, wd, px)
        if cur and cw + sp + ww <= maxW then
            cur, cw = cur .. " " .. wd, cw + sp + ww
        elseif ww <= maxW then
            if cur then lines[#lines + 1] = { s = cur, w = cw } end
            cur, cw = wd, ww
        else
            local i, n = 1, #wd
            while i <= n do
                local room = cur and (maxW - cw - sp) or maxW
                local j, cut, good = i, nil, nil
                while j <= n do
                    local cp, e = adCp(wd, j)
                    if textW(f, wd:sub(i, e), px) > room then break end
                    if e >= n then
                        cut, good = e, e
                    else
                        local ncp = adCp(wd, e + 1)
                        if adMayBreak(cp, ncp) then
                            cut = e
                            if adGoodBreak(cp, ncp) then good = e end
                        end
                    end
                    j = e + 1
                end
                if good and cut and good < cut and textW(f, wd:sub(i, good), px) >= room * 0.5 then cut = good end
                if not cut and cur then
                    lines[#lines + 1] = { s = cur, w = cw }
                    cur, cw = nil, 0
                else
                    if not cut then
                        -- (not one character fits a whole line: the smallest piece that may end one)
                        local cp
                        cp, cut = adCp(wd, i)
                        while cut < n do
                            local ncp, ne = adCp(wd, cut + 1)
                            if adMayBreak(cp, ncp) then break end
                            cp, cut = ncp, ne
                        end
                    end
                    local piece = wd:sub(i, cut)
                    local pw = textW(f, piece, px)
                    if cur then cur, cw = cur .. " " .. piece, cw + sp + pw else cur, cw = piece, pw end
                    i = cut + 1
                    if i <= n then
                        lines[#lines + 1] = { s = cur, w = cw }
                        cur, cw = nil, 0
                    end
                end
            end
        end
    end
    if cur then lines[#lines + 1] = { s = cur, w = cw } end
    for _, l in ipairs(lines) do l.w = math.max(l.w, textW(f, l.s, px)) end
    return lines
end

-- a centered part's lines, evened out: as few lines as at maxW, at the narrowest width that keeps that many (a
-- headline's manner: two even lines rather than a full one and a word)
local function adWrapEven(text, f, px, maxW)
    local lines = adWrap(text, f, px, maxW)
    if #lines < 2 then return lines end
    local lo, hi = 0, maxW
    for _ = 1, 10 do
        local mid = (lo + hi) / 2
        if #adWrap(text, f, px, mid) == #lines then hi = mid else lo = mid end
    end
    return adWrap(text, f, px, hi)
end

-- THE COPYRIGHT PAGE (design, Nov 7 2026, punch list 103; ZeDUI/HANDOFF_design_guide_copyright_20261107.md): the
-- first left-hand page, facing the title page, set as the znix manual's (ZeDUI/workshop/gallery/title_spread.py) in
-- the publisher's dry register. The small print sits low, as copyright pages set it: one block in the body face a
-- step under the body size (U.CAP), left aligned and ragged over the full text-block width, its last line's
-- descender on the text block's foot (U.PH - U.FOOT), so Large text grows it upward and never past the foot. The
-- znix page's spacing: 1 after the title and the edition, 9 after the "by" line, 7 between paragraphs, 4 more
-- before "Printed in" and the printing line straight under it (all times the text size). Wrapped with adWrap, which
-- cuts Chinese, Japanese and Thai between characters. No folio (drawPage returns before it, as for the title page).
local COPY_KEYS = { "UI_ZeD_Guide_BookTitle", "UI_ZeD_Guide_BookSub1", "UI_ZeD_Guide_BookSub2", "UI_ZeD_Guide_BookEdition",
                    "UI_ZeD_Guide_CopyBy", "UI_ZeD_Guide_Copy1", "UI_ZeD_Guide_Copy2", "UI_ZeD_Guide_Copy3",
                    "UI_ZeD_Guide_Copy4", "UI_ZeD_Guide_Copy5" }
local COPY_DESC = 0.25   -- (the face's descender, a quarter of its size: the block's bottom under its last baseline)
-- the block at page width w and unit u: { lines = { { s, w, y = baseline from the page's top } }, px, top, bottom }
-- (in the improbable case the block would rise over the top margin, its size steps down until it fits)
function B.copyrightLayout(w, u)
    local t = {}
    for i, k in ipairs(COPY_KEYS) do t[i] = tr(k) end
    local paras = {
        { t[1] .. ": " .. t[2] .. " " .. t[3], 1 }, { t[4], 1 }, { t[5], 9 },
        { t[6], 7 }, { t[7], 7 }, { t[8], 7 }, { t[9], 7 + 4 },
        { t[10], 0 }, { "10 9 8 7 6 5 4 3 2 1", 0 },   -- (the printing line is no key, as the title page's "1987")
    }
    local tw_ = w - U.M * u * 2
    local foot = (U.PH - U.FOOT) * u
    local L
    for step = 0, 6 do
        local px = U.CAP * u * (0.92 ^ step)
        local lead, g = px * 1.2, px / 10
        local lines, y = {}, 0
        for _, p in ipairs(paras) do
            for _, l in ipairs(adWrap(p[1], F.text, px, tw_)) do
                lines[#lines + 1] = { s = l.s, w = l.w, y = y }
                y = y + lead
            end
            y = y + p[2] * g
        end
        local shift = foot - (lines[#lines].y + px * COPY_DESC)
        for _, l in ipairs(lines) do l.y = l.y + shift end
        L = { lines = lines, px = px, top = lines[1].y - px, bottom = foot }
        if L.top >= U.MT * u then break end
    end
    return L
end

-- the block kept on the panel: laid out again when the width, unit, text size, words or measure epoch change (as
-- the house ad, ZeD_GuideBook:houseAd)
function ZeD_GuideBook:copyrightPage(w, u)
    local X = ZeD.Text
    local ep = X and X.measureEpoch and X.measureEpoch() or nil
    local c = self._copyright
    local same = c ~= nil and ep ~= nil and c.ep == ep and c.w == w and c.u == u and c.m == TM_
    if same then
        for i, k in ipairs(COPY_KEYS) do
            if c.words[i] ~= tr(k) then same = false; break end
        end
    end
    if same then return c.L end
    local words = {}
    for i, k in ipairs(COPY_KEYS) do words[i] = tr(k) end
    c = { ep = ep, w = w, u = u, m = TM_, words = words, L = B.copyrightLayout(w, u) }
    self._copyright = c
    return c.L
end

function ZeD_GuideBook:drawCopyrightPage(x, y, w, u)
    local L = self:copyrightPage(w, u)
    local tx = x + U.M * u
    for _, l in ipairs(L.lines) do drawAt(self, F.text, l.s, tx, y + l.y, L.px, INK) end
end

-- THE CONTENTS (the director, Nov 7 2026: "2-3 pages, however many pages it needs. I'm sure it'll expand"): the
-- sections come from the game's guide and ZeD's chapters at run time, so their count is not fixed. A row for each
-- section that has a page (numOf(s), its printed number, or nil for none), laid out at the text size and in the
-- wording into as many pages as it needs, whole rows only, none past the body text's bottom. A row: the chapter's
-- number and title (wrapped to the text block), its blurb wrapped to the room before its page number (QA, Nov 7
-- 2026: at Large text some languages' blurbs ran into their numbers), the dotted leader and the number on the
-- blurb's last line. A later page heads with the contents title and the book's "continued", as the rules pages do.
-- Places in px at u from the page's top; B.paginate places the pages, drawContentsPage draws them.
function B.contentsLayout(bk, u, numOf)
    local cu = u * TM_
    local tw_ = (U.PW - U.M * 2) * u
    local bottom = (U.PH - U.FOOT - U.MT) * u
    local top = (U.MT + 28 + 18) * u
    local pages = {}
    local page, y = nil, top
    local function newPage()
        local h = upper(tr("UI_ZeD_Guide_BookContents"))
        if #pages > 0 then h = h .. " " .. upper(tr("UI_ZeD_Guide_BookContinued")) end
        -- (a heading wider than the text block comes down to fit it)
        local hp = 28 * u
        local hw = textW(F.head, h, hp)
        if hw > tw_ then hp = hp * tw_ / hw end
        page = { kind = "contents", head = h, headPx = hp, cu = cu, rows = {}, part = #pages + 1 }
        pages[#pages + 1] = page
        y = top
    end
    newPage()
    for si, s in ipairs(bk.sections or {}) do
        local num = numOf(s)
        if num then
            local titles = adWrap(upper(s.title or ""), F.sansB, 10 * cu, tw_ - 24 * cu)
            if #titles == 0 then titles = { { s = "", w = 0 } } end
            local room = tw_ - 24 * cu - textW(F.sansB, num, 10 * cu) - 16 * u
            local b = blurb(s)
            local blurbs = (b ~= "") and adWrap(b, F.sans, 9.5 * cu, room) or {}
            if #blurbs == 0 then blurbs = { { s = "", w = 0 } } end
            local h = 13 * cu + (#titles - 1 + #blurbs) * 12 * cu + 4 * cu
            -- (a row that would pass the bottom starts the next page; one row always goes on a page)
            if y + h > bottom and #page.rows > 0 then newPage() end
            page.rows[#page.rows + 1] = { si = si, sid = s.id, num = num, titles = titles, blurbs = blurbs, y = y, h = h, room = room }
            y = y + h + 2 * cu
        end
    end
    return pages
end

-- the price's lines: its words in two halves (the first the longer) when both fit maxW, else wrapped to maxW
local function adPriceLines(s, px, maxW)
    local pw = {}
    for wd in s:gmatch("%S+") do pw[#pw + 1] = wd end
    local half = math.ceil(#pw / 2)
    local out = {}
    for part = 1, 2 do
        local a, b = (part == 1) and 1 or (half + 1), (part == 1) and half or #pw
        if a <= b then
            local l = adWrap(table.concat(pw, " ", a, b), F.sansB, px, 1e9)[1]
            if not l or l.w > maxW then return adWrap(s, F.sansB, px, maxW) end
            out[#out + 1] = l
        end
    end
    return out
end

-- one try at the ad, its parts at the sizes in sz (screen px) and its gaps times g, from the page's corner; .fits when
-- the coupon has room for its words, Name and Address. A draw in a group (a box and what is in it) is kept or left
-- out with its group.
local function houseAdTry(w, u, g, sz, down)
    local ops, wrapped = {}, {}
    local L = { ops = ops, wrapped = wrapped, g = g }
    local function text(f, s, x, y, px, c, wd, box, grp)
        ops[#ops + 1] = { k = "t", f = f, s = s, x = x, y = y, px = px, c = c, w = wd, box = box, grp = grp }
    end
    local function rect(x, y, rw, rh, c, grp, role) ops[#ops + 1] = { k = "r", x = x, y = y, w = rw, h = rh, c = c, grp = grp, role = role } end
    local function border(x, y, rw, rh, grp) ops[#ops + 1] = { k = "b", x = x, y = y, w = rw, h = rh, grp = grp } end
    local m = U.M * u
    local tx, tw_ = m, w - m * 2
    local cx = w / 2
    local top, bot = U.MT * u, (U.PH - U.FOOT - 6) * u
    local lw = math.max(1, math.floor(2 * u))
    local hair = math.max(1, u)
    L.frame = { x = tx, y = top, w = tw_, h = bot - top, lw = lw }
    for i = 0, lw - 1 do border(tx + i, top + i, tw_ - i * 2, bot - top - i * 2, "frame") end
    local ix, iw = tx + 14 * u, tw_ - 28 * u
    L.inner = { x = ix, w = iw }
    -- the headline and the deck, centered, line by line (a headline word too wide for the frame, in a language that
    -- spaces its words, takes the headline a size down before it is ever cut)
    local yy = top + 16 * u * g
    local hp, dp = sz.head, sz.deck
    local head = upper(tr("UI_ZeD_Guide_Ad1_Head"))
    if hp > down.head and adWidestWhole(head, F.head, hp) > iw then hp = down.head end
    L.headPx = hp
    local hl = adWrapEven(head, F.head, hp, iw)
    wrapped.head = #hl > 1
    for i, l in ipairs(hl) do
        yy = yy + ((i == 1) and hp or hp * 1.05)
        text(F.head, l.s, cx - l.w / 2, yy, hp, INK, l.w, "inner")
    end
    local dl = adWrapEven(tr("UI_ZeD_Guide_Ad1_Deck"), F.sansB, dp, iw)
    wrapped.deck = #dl > 1
    for i, l in ipairs(dl) do
        yy = yy + ((i == 1) and dp * (1 + 0.6 * g) or dp * 1.3)
        text(F.sansB, l.s, cx - l.w / 2, yy, dp, INK, l.w, "inner")
    end
    yy = yy + U.TEXT * u * 0.8 * g
    rect(ix, yy, iw, hair, INK)
    -- the paragraph
    local bp = sz.body
    local bl = adWrap(tr("UI_ZeD_Guide_Ad1_Body"), F.text, bp, iw)
    wrapped.body = #bl > 1
    for _, l in ipairs(bl) do
        yy = yy + bp * U.LEAD
        text(F.text, l.s, ix, yy, bp, INK, l.w, "inner")
    end
    -- the price in a black box at the right: its words, half its size clear on each side
    yy = yy + bp * U.LEAD * 0.8 * g
    local boxY = yy
    local pp = sz.price
    local pls = adPriceLines(upper(tr("UI_ZeD_Guide_Ad1_Price")), pp, iw * 0.4 - pp)
    if #pls > 2 then
        -- (more than two lines: the price a size down)
        pp = U.TEXT * u
        pls = adPriceLines(upper(tr("UI_ZeD_Guide_Ad1_Price")), pp, iw * 0.4 - pp)
    end
    local pTextW = 0
    for _, l in ipairs(pls) do pTextW = math.max(pTextW, l.w) end
    local priceW = math.max(92 * u, pTextW + pp)
    local pY = boxY + 10 * u * g
    local unit5 = pp * 5   -- (the box's height for two lines: 70 at the Small deck size)
    local pH = unit5 * (0.64 + 0.36 * (math.max(#pls, 2) - 1))
    local px0 = ix + iw - priceW
    L.price = { x = px0, y = pY, w = priceW, h = pH, pad = pp * 0.5 }
    rect(px0, pY, priceW, pH, INK, "price")
    local pc = px0 + priceW / 2
    for i, l in ipairs(pls) do
        local by = (#pls == 1) and (pY + pH * 0.6) or (pY + unit5 * (0.42 + 0.36 * (i - 1)))
        text(F.sansB, l.s, pc - l.w / 2, by, pp, PAPER, l.w, "price", "price")
    end
    -- the titles, each with its tick box, in a ruled box at the left
    local listW = iw - priceW - 10 * u
    local ip = sz.items
    local ilh = ip * U.LEAD
    local sq = math.floor(ip * 0.8)
    local itx = ix + 8 * u + sq + 8 * u
    local itw = ix + listW - 8 * u - itx
    for i = 1, 5 do
        local tl = adWrap(tr("UI_ZeD_Guide_Ad1_T" .. i), F.textB, ip, itw)
        if #tl > 1 then wrapped.items = true end
        for j, l in ipairs(tl) do
            yy = yy + ((j == 1) and ilh * (1 + 0.15 * g) or ilh)
            if j == 1 then border(ix + 8 * u, yy - sq, sq, sq, "list") end
            text(F.textB, l.s, itx, yy, ip, INK, l.w, "list", "list")
        end
    end
    yy = yy + ilh * 0.6 * g
    L.list = { x = ix, y = boxY, w = listW, h = yy - boxY, pad = 8 * u }
    border(ix, boxY, listW, yy - boxY, "list")
    yy = math.max(yy, pY + pH + 10 * u * g)
    -- the coupon: a dashed edge, the words, lines to write on
    yy = yy + 16 * u * g
    local cY = yy
    local cH = bot - 14 * u - cY
    local cp = sz.coupon
    local cl = adWrap(tr("UI_ZeD_Guide_Ad1_Coupon"), F.text, cp, iw - 20 * u)
    wrapped.coupon = #cl > 1
    local step = cp * (1 + 1.2 * g)
    -- Name and Address: each wrapped to leave a writing line of at least 40 after its last line
    local labs, labH = {}, 0
    for li, k in ipairs({ "UI_ZeD_Guide_Ad1_Name", "UI_ZeD_Guide_Ad1_Address" }) do
        local ll = adWrap(tr(k), F.sansB, cp, iw - 20 * u - 8 * u - 40 * u)
        if #ll == 0 then ll = { { s = "", w = 0 } } end
        if #ll > 1 then wrapped.coupon = true end
        labs[li] = ll
        labH = labH + step + (#ll - 1) * cp * 1.3
    end
    L.fits = cH > 60 * u and 6 * u + #cl * cp * 1.35 + labH + 6 * u <= cH
    if cH > 60 * u then
        L.coupon = { x = ix, y = cY, w = iw, h = cH, pad = 10 * u }
        local dash, gapD = 6 * u, 4 * u
        local xx = ix
        while xx < ix + iw do
            local dw = math.min(dash, ix + iw - xx)
            rect(xx, cY, dw, hair, INK, "coupon")
            rect(xx, cY + cH, dw, hair, INK, "coupon")
            xx = xx + dash + gapD
        end
        local yy2 = cY
        while yy2 < cY + cH do
            local dh = math.min(dash, cY + cH - yy2)
            rect(ix, yy2, hair, dh, INK, "coupon")
            rect(ix + iw, yy2, hair, dh, INK, "coupon")
            yy2 = yy2 + dash + gapD
        end
        local cy2 = cY + 6 * u
        for _, l in ipairs(cl) do
            cy2 = cy2 + cp * 1.35
            if cy2 + cp * 0.3 > cY + cH then break end
            text(F.text, l.s, ix + 10 * u, cy2, cp, INK, l.w, "coupon")
        end
        L.lines = 0
        for li, ll in ipairs(labs) do
            -- (a label with its writing line, whole or not at all)
            local endY = cy2 + step + (#ll - 1) * cp * 1.3
            if endY > cY + cH - 4 * u then break end
            local grp = "label" .. li
            for j, l in ipairs(ll) do
                cy2 = cy2 + ((j == 1) and step or cp * 1.3)
                text(F.sansB, l.s, ix + 10 * u, cy2, cp, INK, l.w, "coupon", grp)
            end
            local lx = ix + 10 * u + ll[#ll].w + 8 * u
            rect(lx, cy2 + 2 * u, ix + iw - 10 * u - lx, hair, INK, grp, "write")
            L.lines = L.lines + 1
        end
    end
    -- (whatever is left past the frame's inside, in the last and smallest try, is left out: a box with all it holds)
    local inBot = bot - lw
    local past = {}
    for _, o in ipairs(ops) do
        local b = (o.k == "t") and (o.y + o.px * 0.3) or (o.y + o.h)
        o.past = b > inBot + 0.01 and o.grp ~= "frame"
        if o.past and o.grp then past[o.grp] = true end
    end
    for i = #ops, 1, -1 do
        local o = ops[i]
        if o.past or (o.grp and past[o.grp]) then table.remove(ops, i) end
        o.past = nil
    end
    L.dropped = past
    return L
end

-- the ad's layout at page width w and unit u: the list of what to draw, from the page's corner
local AD_DOWN = { "deck", "items", "coupon", "body", "head" }
function B.houseAdLayout(w, u)
    local sz = { head = U.OPEN * u, deck = U.DECK * u, body = U.TEXT * u, items = U.TEXT * u, coupon = U.CAP * u * 1.1, price = U.DECK * u }
    local down = { head = U.TITLE * u, deck = U.TEXT * u, items = U.CAP * u * 1.1, coupon = U.CAP * u, body = U.CAP * u * 1.1 }
    local L
    for s = 0, #AD_DOWN do
        local part = AD_DOWN[s]
        if s == 0 or (L and L.wrapped[part]) then
            if part then sz[part] = down[part] end
            for _, g in ipairs({ 1, 0.85, 0.7, 0.55 }) do
                L = houseAdTry(w, u, g, sz, down)
                if L.fits then L.sz = sz; return L end
            end
        end
    end
    L.sz = sz
    return L
end

local AD_KEYS = { "UI_ZeD_Guide_Ad1_Head", "UI_ZeD_Guide_Ad1_Deck", "UI_ZeD_Guide_Ad1_Body", "UI_ZeD_Guide_Ad1_T1",
                  "UI_ZeD_Guide_Ad1_T2", "UI_ZeD_Guide_Ad1_T3", "UI_ZeD_Guide_Ad1_T4", "UI_ZeD_Guide_Ad1_T5",
                  "UI_ZeD_Guide_Ad1_Price", "UI_ZeD_Guide_Ad1_Coupon", "UI_ZeD_Guide_Ad1_Name", "UI_ZeD_Guide_Ad1_Address" }
-- the layout kept on the panel: laid out again when the width, unit, text size, words or measure epoch change (no
-- epoch while the fonts load: laid out each frame until they settle)
function ZeD_GuideBook:houseAd(w, u)
    local X = ZeD.Text
    local ep = X and X.measureEpoch and X.measureEpoch() or nil
    local c = self._houseAd
    local same = c ~= nil and ep ~= nil and c.ep == ep and c.w == w and c.u == u and c.m == TM_
    if same then
        for i, k in ipairs(AD_KEYS) do
            if c.words[i] ~= tr(k) then same = false; break end
        end
    end
    if same then return c.L end
    local words = {}
    for i, k in ipairs(AD_KEYS) do words[i] = tr(k) end
    c = { ep = ep, w = w, u = u, m = TM_, words = words, L = B.houseAdLayout(w, u) }
    self._houseAd = c
    return c.L
end

function ZeD_GuideBook:drawAdPage(x, y, w, u)
    local L = self:houseAd(w, u)
    for _, o in ipairs(L.ops) do
        if o.k == "t" then
            drawAt(self, o.f, o.s, x + o.x, y + o.y, o.px, o.c)
        elseif o.k == "r" then
            self:drawRect(x + o.x, y + o.y, o.w, o.h, 1, o.c.r, o.c.g, o.c.b)
        else
            self:drawRectBorder(x + o.x, y + o.y, o.w, o.h, 1, INK.r, INK.g, INK.b)
        end
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
    if p.kind == "copyright" then self:drawCopyrightPage(x, y, w, u); return end
    if p.kind == "contents" then self:drawContentsPage(p, x, y, w, u, hover, i)
    elseif p.kind == "intro" then self:drawIntroPage(x, y, w, u)
    elseif p.kind == "flow" then self:drawFlowPage(p, x, y, w, u)
    elseif p.kind == "rules" then self:drawRulesPage(p, x, y, w, u)
    elseif p.kind == "ad" then self:drawFullAd(p, x, y, w, u)
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
    self._contentsRows = {}   -- (the contents rows on this spread, as its pages draw them)
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
    elseif id == "toc" then self:goToPage(self.contentsPage or 3) end
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
    -- (a contents row on either page of the open spread opens its chapter)
    local li = self.spread * 2 - 1
    for _, row in ipairs(self._contentsRows or {}) do
        if (row.onPage == li or row.onPage == li + 1) and row.page and inRect(row, x, y) then self:goToPage(row.page); return true end
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
    elseif key == Keyboard.KEY_HOME then self:goToPage(self.contentsPage or 3) end
end

-- the controller: LB, RB and the D-pad's left and right turn the pages; Y the contents; Down to the strip
-- (left and right walk it, A presses, Up back to the book); B closes
function ZeD_GuideBook:onGainJoypadFocus(jd) self.joyfocus = jd end
function ZeD_GuideBook:onLoseJoypadFocus(jd) self.joyfocus = nil end
function ZeD_GuideBook:onJoypadDown(button, jd)
    if button == Joypad.BButton then B.close(self.playerNum)
    elseif button == Joypad.LBumper then self:turn(-1)
    elseif button == Joypad.RBumper then self:turn(1)
    elseif button == Joypad.YButton then self:goToPage(self.contentsPage or 3)
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
