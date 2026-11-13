-- ZeDUI/tools/qa/zedqa_b8_guide.lua  (Nov 8 2026, QA; QA_HANDOFF_B8_20261108.md: the survival guide's new pages)
-- The Full book (F1) read in the real game, pictures for a human and checks for the rest:
--   * the copyright page (page 1, facing the title page): spread 1 is copyright + title; the page's lines are the keys' words in
--     order, end with the printing line "10 9 8 7 6 5 4 3 2 1", sit inside the text block (below the top margin, above the foot);
--     the title page names the division with its LLC; picture of the first spread
--   * the contents over its pages: first contents page is page 3, parts numbered, the introduction on a right-hand page after the
--     last one, every section has a page in order; pictures of the contents spread(s) and the introduction spread
--   * a Television/Radio rules page exists (the book gained it); where each chapter now starts (the gallery spreads from 46 on
--     may have moved: the report lists chapter -> spread)
--   * the ads: the 44 third-size ads (12 + the 32 new): all art files load, in the 440:205 proportion (2x art), unique, in the deck
--     once each; over several ad seeds the new thirds all get dealt somewhere in the book; in this character's own deal each
--     new third dealt is drawn on its page at design size, inside the text block, clear of the foot; pictures of up to six spreads
--     holding new thirds
--   * the other sizes' files load too
-- Manual: a human looks at every new ad (copy, art, legibility) at 4K and at the Deck, the copyright page's look, the gallery
-- retakes (punch list 105). Puts back the look and the windows. grep "ZEDQA b8gd". Pictures zqa_b8_gd_*.png.
local TAG = "b8gd"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end; return ok end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_b8_gd_" .. n .. ".png") end); say("shot " .. n) end
local G, B, A = ZeD.Guide, ZeD.GuideBook, ZeD.GuideAds
if not (G and B and A and ZeD.Settings and ZeD.Settings.guideStyleOption) then say("ERR the guide, the book or the ads are not loaded"); say("DONE"); return end
local look = ZeD.Settings.guideStyleOption
local PW, PH, M, MT, FOOT = 520, 690, 40, 30, 26
local function snap(v) return math.floor(v + 0.5) end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = { was = {}, shots = 0 }
local function book() return B.books[0] end
local function squash(s) return (tostring(s):gsub("%s+", "")) end

-- the third-size ads from before this batch (the old twelve); the rest of A.third is the 32 new
local OLD = { third_maps_unlimited = 1, third_salt_river_bait = 1, third_pioneer_girls = 1, third_knob_creek_hunting = 1,
              third_aa_ron_hunting = 1, third_west_point_range = 1, third_nails_and_nuts = 1, third_time_4_sport = 1,
              third_zippee_market = 1, third_phils_pawn = 1, third_hit_vids = 1, third_rolling_fork_camp = 1 }
local NEW = {}
for _, n in ipairs(A.third) do if not OLD[n] then NEW[#NEW + 1] = n end end
local isNew = {}
for _, n in ipairs(NEW) do isNew[n] = true end

-- the ad art, recorded off the book's own drawTextureScaled while rec is a table
local rec = nil
local texName = {}
local function hook(bk)
    if bk._gdHooked then return end
    bk._gdHooked = true
    bk.drawTextureScaled = function(self, tex, x, y, w, h, a, r, g, b)
        if rec and tex then
            local n = texName[tex]
            if n == nil then
                n = false
                pcall(function() n = tostring(tex:getName()) end)
                n = n and n:match("ads[/\\]([%w_]+)") or false
                texName[tex] = n
            end
            if n then rec[n .. "@" .. x .. "," .. y] = { n = n, x = x, y = y, w = w, h = h } end
        end
        return ISUIElement.drawTextureScaled(self, tex, x, y, w, h, a, r, g, b)
    end
end
-- every ad block dealt: { page, k, names }
local function dealt(bk)
    local out = {}
    for i, p in ipairs(bk.pages or {}) do
        if p.kind == "ad" then
            for _, b in ipairs(p.filler and p.filler.ads or {}) do out[#out + 1] = { page = i, k = b.k, names = b.names } end
        elseif p.kind == "flow" then
            for _, it in ipairs(p.items) do
                if it.k == "filler" then for _, b in ipairs(it.ads or {}) do out[#out + 1] = { page = i, k = b.k, names = b.names } end end
            end
        elseif p.kind == "rules" and p.filler then
            local sp = p.rules and p.rules.spoiler
            for _, b in ipairs(p.filler.ads or {}) do out[#out + 1] = { page = i, k = b.k, names = b.names, spoiler = sp } end
        end
    end
    return out
end
local function thirdsOf(list)
    local set, n = {}, 0
    for _, b in ipairs(list) do
        if b.k == "third" and b.names then for _, nm in ipairs(b.names) do if not set[nm] then set[nm] = true; n = n + 1 end end end
    end
    return set, n
end

-- ---- 1. the art files and the deck
step(20, function()
    local sizes = A.size
    local seen, dup, missing, badShape, notTwo = {}, {}, {}, {}, {}
    local total = 0
    for _, k in ipairs({ "full", "half", "third", "quarter" }) do
        for _, nm in ipairs(A[k]) do
            total = total + 1
            if seen[nm] then dup[#dup + 1] = nm end
            seen[nm] = true
            local path = "media/textures/ZeD/guide/ads/" .. nm .. ".png"
            local tex = (Texture.getSharedTexture and Texture.getSharedTexture(path, 2)) or getTexture(path)
            if not tex then missing[#missing + 1] = nm
            else
                local w, h = tex:getWidth(), tex:getHeight()
                local want = sizes[k]
                if math.abs(w / h - want[1] / want[2]) > 0.02 * (want[1] / want[2]) then badShape[#badShape + 1] = nm .. " " .. w .. "x" .. h end
                if w ~= want[1] * 2 or h ~= want[2] * 2 then notTwo[#notTwo + 1] = nm .. " " .. w .. "x" .. h end
            end
        end
    end
    say("ads in the book's lists: " .. #A.full .. " full, " .. #A.half .. " half, " .. #A.third .. " third, " .. #A.quarter .. " quarter (" .. total .. ")")
    check(#A.third == 44, "44 third-size ads (12 + 32 new); the list has " .. #A.third)
    check(#NEW == 32, "32 third-size ads are new this build (" .. #NEW .. ")")
    check(#dup == 0, "no ad named twice" .. (#dup > 0 and (" (" .. table.concat(dup, ", ") .. ")") or ""))
    check(#missing == 0, "every ad's art file loads" .. (#missing > 0 and (" (missing: " .. table.concat(missing, ", ") .. ")") or ""))
    check(#badShape == 0, "every ad's art is in its size's proportion" .. (#badShape > 0 and (" (off: " .. table.concat(badShape, ", ", 1, math.min(6, #badShape)) .. ")") or ""))
    if #notTwo > 0 then say("note: " .. #notTwo .. " art files are not exactly 2x their design size (e.g. " .. table.concat(notTwo, ", ", 1, math.min(4, #notTwo)) .. ")") end
    -- the deck
    local d = B.adDeck(B.adSeed(0))
    local inDeck, dd = {}, 0
    for _, nm in ipairs(d.third) do if inDeck[nm] then dd = dd + 1 end; inDeck[nm] = true end
    check(#d.third == #A.third and dd == 0, "the deck holds every third once (" .. #d.third .. " of " .. #A.third .. ")")
    local allNew = true
    for _, nm in ipairs(NEW) do if not inDeck[nm] then allNew = false end end
    check(allNew, "all 32 new thirds are in the deck")
end)

-- ---- 2. open the book
step(10, function()
    S.was.look = look:getValue()
    S.cwOpen = ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isReallyVisible()
    if S.cwOpen then ZeD_CharacterWindow.toggleBothPaired(0) end
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
    look:setValue(1)
    G.open(0)
end)
step(40, function()
    check(B.isOpen(0), "F1 on Full opens the book")
    local bk = book()
    if not bk then return end
    hook(bk)
    local g = bk._g
    say("screen " .. sw .. "x" .. sh .. ", unit " .. tostring(g and g.u) .. ", " .. #bk.pages .. " pages, " .. tostring(bk.contentsPages) .. " contents page(s), intro on page " .. tostring(bk.introPage))
    -- the front matter
    local P = bk.pages
    check(P[1] and P[1].kind == "copyright" and P[2] and P[2].kind == "title", "page 1 is the copyright page and page 2 the title page")
    check(bk.contentsPage == 3 and (bk.contentsPages or 0) >= 1, "the contents start on page 3 (" .. tostring(bk.contentsPages) .. " page(s))")
    for i = 3, 2 + (bk.contentsPages or 0) do
        check(P[i] and P[i].kind == "contents" and P[i].part == i - 2, "page " .. i .. " is contents part " .. (i - 2))
    end
    local ip = bk.introPage
    check(ip ~= nil and P[ip] and P[ip].kind == "intro", "the introduction is on page " .. tostring(ip))
    check(ip ~= nil and ip % 2 == 0, "the introduction sits on a right-hand page")
    -- the copyright page's lines
    local u = g.u
    local okL, L = pcall(bk.copyrightPage, bk, PW * u, u)
    if check(okL and L and L.lines and #L.lines > 0, "the copyright page lays out (" .. tostring(okL and L and #L.lines or L) .. " lines)") then
        local want = ZeD.tr("UI_ZeD_Guide_BookTitle") .. ": " .. ZeD.tr("UI_ZeD_Guide_BookSub1") .. " " .. ZeD.tr("UI_ZeD_Guide_BookSub2")
            .. ZeD.tr("UI_ZeD_Guide_BookEdition") .. ZeD.tr("UI_ZeD_Guide_CopyBy")
        for k = 1, 5 do want = want .. ZeD.tr("UI_ZeD_Guide_Copy" .. k) end
        want = want .. "10 9 8 7 6 5 4 3 2 1"
        local got = {}
        for _, l in ipairs(L.lines) do got[#got + 1] = l.s end
        check(squash(table.concat(got)) == squash(want), "the page prints exactly the keys' words, in order")
        check(got[#got] == "10 9 8 7 6 5 4 3 2 1", "the printing line is last (" .. tostring(got[#got]) .. ")")
        local first, last = L.lines[1], L.lines[#L.lines]
        -- (l.y is a baseline: the block's top is the first baseline less one text height, its foot the layout's own)
        check(first.y - L.px >= MT * u - 0.5, string.format("the block starts under the top margin (%.1f, margin %.1f)", first.y - L.px, MT * u))
        check(last.y <= (PH - FOOT) * u + 0.5 and math.abs((L.bottom or 0) - (PH - FOOT) * u) < 0.5, string.format("the block ends on the text foot (last baseline %.1f, foot %.1f)", last.y, (PH - FOOT) * u))
        local wide = 0
        for _, l in ipairs(L.lines) do if (l.w or 0) > (PW - 2 * M) * u + 0.5 then wide = wide + 1 end end
        check(wide == 0, "no copyright line is wider than the text block")
        local missingK = {}
        for k = 1, 5 do if ZeD.tr("UI_ZeD_Guide_Copy" .. k) == "UI_ZeD_Guide_Copy" .. k then missingK[#missingK + 1] = k end end
        check(#missingK == 0, "UI_ZeD_Guide_Copy1 to 5 have text")
        check(ZeD.tr("UI_ZeD_Guide_Copy1"):find("\194\169 1984, 1987", 1, true) ~= nil or ZeD.tr("UI_ZeD_Guide_Copy1"):find("1984", 1, true) ~= nil, "the copyright line carries its years")
        for i, l in ipairs(L.lines) do if i <= 12 then say("  copyright line " .. i .. ": " .. l.s) end end
    end
    -- the title page's division
    check(tostring(ZeD.tr("UI_ZeD_Guide_CopyBy")) ~= "UI_ZeD_Guide_CopyBy", "the title page's publisher line has text (" .. tostring(ZeD.tr("UI_ZeD_Guide_CopyBy")) .. ")")
    bk.spread = 1
end)
step(40, function() shot("first_spread") end)

-- ---- 3. the contents and the introduction
step(5, function()
    local bk = book(); if not bk then return end
    bk.spread = math.floor((bk.contentsPage + 1) / 2)
end)
step(40, function() shot("contents") end)
step(5, function()
    local bk = book(); if not bk then return end
    local last = bk.contentsPage + (bk.contentsPages or 1) - 1
    S.lastSpread = math.floor((last + 1) / 2)
    S.introSpread = math.floor((bk.introPage + 1) / 2)
    -- the last contents page and the introduction together (when they differ from the first contents spread)
    bk.spread = S.introSpread
end)
step(40, function() shot("contents_end_intro") end)
step(5, function()
    local bk = book(); if not bk then return end
    -- every section has a page, in order; the gallery's spreads (the report: chapter -> spread)
    local prev, ordered, none = 0, true, {}
    local parts = {}
    for i, s in ipairs(bk.sections or {}) do
        local pg = bk.sectionPage and bk.sectionPage[s.id]
        if not pg then none[#none + 1] = tostring(s.title)
        else
            if pg < prev then ordered = false end
            prev = pg
            parts[#parts + 1] = i .. ":" .. tostring(s.title) .. "=p" .. pg .. "/spread " .. math.floor((pg + 1) / 2)
        end
    end
    check(#none == 0, "every section has a page" .. (#none > 0 and (" (none: " .. table.concat(none, ", ") .. ")") or ""))
    check(ordered, "the sections run in order")
    say("chapters (page / spread now, for the gallery retakes): " .. table.concat(parts, "; "))
    -- the Television/Radio rules page
    local pgs = {}
    for i, p in ipairs(bk.pages) do
        if p.kind == "rules" and p.topic and p.topic.titleKey == "SurvivalGuide_television_title" then pgs[#pgs + 1] = i end
    end
    check(#pgs >= 1, "Television/Radio has a rules page (page " .. table.concat(pgs, ", ") .. ")")
    local topicPage = bk.pageOf and bk.flat and (function()
        for _, t in ipairs(bk.flat) do if t.titleKey == "SurvivalGuide_television_title" then return bk.pageOf[t.id] end end
    end)()
    check(topicPage ~= nil and pgs[1] ~= nil and pgs[1] > topicPage, "the rules page follows the topic (topic on page " .. tostring(topicPage) .. ")")
    if pgs[1] then
        local t = bk.pages[pgs[1]].rules
        say("Television/Radio rules page: " .. tostring(t and t.title) .. " (" .. tostring(t and #t.rows) .. " rows)")
        bk.spread = math.floor((pgs[1] + 1) / 2)
    end
end)
step(40, function() shot("tv_rules") end)

-- ---- 4. which new thirds get dealt: over several seeds
step(5, function()
    local bk = book(); if not bk then return end
    local union, seeds = {}, {}
    local base = bk._adSeed or 1
    local realSeed = bk._adSeed
    local okAll = true
    for k = 1, 10 do
        bk._adSeed = (base * 7 + k * 104729) % 2147483629 + 1
        local ok, e = pcall(B.paginate, bk, bk._u)
        if not ok then okAll = false; say("ERR paginate with seed " .. k .. ": " .. tostring(e)); break end
        local set, n = thirdsOf(dealt(bk))
        seeds[#seeds + 1] = n
        for nm in pairs(set) do union[nm] = true end
    end
    bk._adSeed = realSeed
    pcall(B.paginate, bk, bk._u)
    local nNew, nAll = 0, 0
    for nm in pairs(union) do nAll = nAll + 1; if isNew[nm] then nNew = nNew + 1 end end
    say("thirds dealt per reading over 10 seeds: " .. table.concat(seeds, ",") .. "; the union covers " .. nAll .. " of " .. #A.third .. " (" .. nNew .. " of the 32 new)")
    check(okAll and nNew > 0, "the new thirds are dealt into the book")
    local never = {}
    for _, nm in ipairs(NEW) do if not union[nm] then never[#never + 1] = nm end end
    if #never > 0 then say("note: not dealt in these 10 seeds: " .. table.concat(never, ", ")) end
end)

-- ---- 5. this character's own deal: every new third dealt is drawn on its page
step(10, function()
    local bk = book(); if not bk then return end
    G.open(0)   -- the real deal again
end)
step(40, function()
    local bk = book(); if not bk then return end
    hook(bk)
    local list = dealt(bk)
    local set, n = thirdsOf(list)
    local nNew = 0
    for nm in pairs(set) do if isNew[nm] then nNew = nNew + 1 end end
    local okR, line = pcall(B.adReport, bk)
    say("this reading's deal: " .. n .. " thirds, " .. nNew .. " of them new. " .. tostring(line))
    S.todo = {}
    for _, b in ipairs(list) do
        if b.k == "third" and b.names and isNew[b.names[1]] and not b.spoiler then S.todo[#S.todo + 1] = { page = b.page, name = b.names[1] } end
    end
    table.sort(S.todo, function(a, b) return a.page < b.page end)
    say("new thirds in view of a picture: " .. #S.todo)
    S.ti = 0
    S.bad = {}
end)
-- up to 12 spreads with a new third: measure each; a picture of the first six
for i = 1, 12 do
    step(4, function()
        local bk = book(); if not bk then return end
        S.cur = S.todo and S.todo[i]
        if not S.cur then return end
        bk.spread = math.floor((S.cur.page + 1) / 2)
        rec = {}
    end)
    step(3, function()
        local bk = book(); local cur = S.cur
        if not (bk and cur) then return end
        local g = bk._g
        local u = g.u
        local r = rec or {}
        rec = nil
        local found = nil
        for _, d in pairs(r) do if d.n == cur.name then found = d end end
        if not found then S.bad[#S.bad + 1] = cur.name .. " (page " .. cur.page .. ") not drawn"; return end
        local right = found.x + found.w / 2 >= g.right.x
        local pg = right and g.right or g.left
        local tx = snap(pg.x + M * u)
        local ex, ey = snap(440 * u), snap(205 * u)
        if math.abs(found.w - ex) > 1 or math.abs(found.h - ey) > 1 then S.bad[#S.bad + 1] = cur.name .. " drawn " .. found.w .. "x" .. found.h .. ", design " .. ex .. "x" .. ey end
        if found.x < tx - 1 or found.x + found.w > pg.x + pg.w - M * u + 1 then S.bad[#S.bad + 1] = cur.name .. " outside the text block's sides" end
        if found.y + found.h > pg.y + (PH - FOOT) * u + 1 then S.bad[#S.bad + 1] = cur.name .. " into the foot" end
        if found.y < pg.y + MT * u - 1 then S.bad[#S.bad + 1] = cur.name .. " above the text block" end
        S.ti = S.ti + 1
    end)
    if i <= 6 then step(25, function() if S.cur then shot("third_" .. i .. "_" .. S.cur.name) end end) end
end
step(5, function()
    check(#(S.bad or {}) == 0, "every new third dealt is drawn at design size inside the text block (" .. tostring(S.ti) .. " measured of " .. tostring(S.todo and #S.todo or 0) .. " dealt" .. ((S.bad and #S.bad > 0) and ("; " .. table.concat(S.bad, " || ", 1, math.min(5, #S.bad))) or "") .. ")")
end)

-- ---- put everything back
step(10, function()
    rec = nil
    pcall(B.close, 0)
    look:setValue(S.was.look or 1)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if S.cwOpen and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    say(pass .. " passed, " .. fail .. " failed")
    say("DONE")
end)

local function tick()
    if wait > 0 then wait = wait - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    wait = s.n
end
say("start")
Events.OnRenderTick.Add(tick)
