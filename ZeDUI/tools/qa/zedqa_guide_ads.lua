-- ZeDUI/tools/qa/zedqa_guide_ads.lua  (Nov 7 2026, QA; punch list 98, Build's 9f0c211b: the survival guide's ads)
-- The book on Full, read four ways (Small and Large text, keyboard and pad wording; ZeD.Guide.onPad is swapped for
-- the run). For each: the deal as planned (no ad twice, half and pair take turns, the First Days checklist first on its
-- page, the count line), then every spread turned to and the ads as drawn measured (the panel's drawTextureScaled
-- is recorded): inside the text block, clear of the foot and the folio, full ads at the block's top left, a pair's
-- two quarters level with an even gutter, the size its design size times the page unit, the same ads as planned.
-- Then: close and reopen (the same ads on the same pages), the deck a different seed deals, the spoiler pages (no ad
-- until the numbers show, and showing them changes no other page), the Simple look (no ads).
-- In a language other than English: one reading, the deal, pictures of the house ad and an ad page.
-- Settings put back. grep "ZEDQA gad". Pictures zqa_gad_<w>x<h>_<lang>_<n>.png.
local function say(s) print("ZEDQA gad " .. tostring(s)) end
local B, G = ZeD.GuideBook, ZeD.Guide
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local lang = "EN"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_gad_" .. sw .. "x" .. sh .. "_" .. lang .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end; return ok end
local PW, PH, M, MT, FOOT = 520, 690, 40, 30, 26
local S = ZeD.GuideAds.size
local function snap(v) return math.floor(v + 0.5) end

-- the run's settings, put back at the end
local opt = ZeD.Settings.guideStyleOption
local keep = { look = opt:getValue(), size = ZeD.currentSize, onPad = G.onPad }
local padMode = false
G.onPad = function(pn) return padMode end
local function setSize(k) ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, k) end

local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function now(list) for k = #list, 1, -1 do table.insert(Q, qi + 1, list[k]) end end

-- the drawn ads, recorded off the book's own drawTextureScaled while rec is a table
local rec = nil
local texName = {}
local function hook(bk)
    if bk._gadHooked then return end
    bk._gadHooked = true
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
local function book() return B.books[0] end

-- the plan: each page's dealt blocks, in page order; spoiler pages' feet marked
local function plan(bk)
    local out = {}
    for i, p in ipairs(bk.pages or {}) do
        if p.kind == "ad" then
            out[#out + 1] = { page = i, k = "full", names = { p.ad == nil and "house" or (p.ad or "NOTES") }, whole = true }
        elseif p.kind == "flow" then
            for _, it in ipairs(p.items) do
                if it.k == "filler" then for bi, b in ipairs(it.ads or {}) do out[#out + 1] = { page = i, k = b.k, names = b.names, check = it.check, first = bi == 1 } end end
            end
        elseif p.kind == "rules" and p.filler then
            local sp = p.rules and p.rules.spoiler
            for _, b in ipairs(p.filler.ads or {}) do out[#out + 1] = { page = i, k = b.k, names = b.names, spoiler = sp, topic = p.topic, ri = p.ri } end
        end
    end
    return out
end
local function sig(pl)
    local t = {}
    for _, b in ipairs(pl) do t[#t + 1] = b.page .. ":" .. b.k .. (b.names and (":" .. table.concat(b.names, "+")) or "") end
    return table.concat(t, " ")
end
local function sizeOf(n)
    if n == "house" or n == "NOTES" then return "full" end
    return tostring(n):match("^(%a+)_")
end
-- each size's ads in deal order (the first pass in page order, then the spoiler feet)
local function dealOrder(pl)
    local o = { full = {}, half = {}, quarter = {}, third = {} }
    for pass_ = 1, 2 do
        for _, b in ipairs(pl) do
            if (pass_ == 2) == (b.spoiler == true) and b.names then
                for _, n in ipairs(b.names) do
                    if n ~= "NOTES" then local s = sizeOf(n); if o[s] then o[s][#o[s] + 1] = n end end
                end
            end
        end
    end
    return o
end
local function isPrefix(a, b)
    local s, l = a, b
    if #a > #b then s, l = b, a end
    for i = 1, #s do if s[i] ~= l[i] then return false end end
    return true
end

local orders = {}
local firstSig
local adSpreads = {}

-- one reading: the plan's checks, then every spread drawn and measured
local function reading(name, shootAll, shootSome)
    local fails = {}
    local drawnOn = {}
    local spoilPages = {}
    local pl
    local function bad(s) fails[#fails + 1] = s end
    now({
        { n = 30, fn = function()
            local bk = book()
            hook(bk)
            pl = plan(bk)
            local s = sig(pl)
            say(name .. " deal: " .. s)
            local ok, line = pcall(B.adReport, bk)
            say(name .. " count: " .. tostring(line))
            -- no ad twice
            local seen, dup = {}, {}
            for _, b in ipairs(pl) do
                for _, n in ipairs(b.names or {}) do
                    if n ~= "NOTES" then if seen[n] then dup[#dup + 1] = n end; seen[n] = true end
                end
                if b.spoiler then spoilPages[b.page] = b end
            end
            check(#dup == 0, name .. ": no ad dealt twice" .. (#dup > 0 and (" (" .. table.concat(dup, ", ") .. ")") or ""))
            -- half and pair take turns, unless the other has run out
            local A = ZeD.GuideAds
            local hl, ql, last, turnBad = #A.half, #A.quarter, nil, {}
            local hU, qU = 0, 0
            for pass_ = 1, 2 do
                for _, b in ipairs(pl) do
                    if (pass_ == 2) == (b.spoiler == true) and (b.k == "half" or b.k == "pair") then
                        if last == b.k then
                            local otherLeft = (b.k == "half") and (ql - qU >= 2) or (hl - hU >= 1)
                            if otherLeft then turnBad[#turnBad + 1] = "page " .. b.page end
                        end
                        if b.k == "half" then hU = hU + 1 else qU = qU + 2 end
                        last = b.k
                    end
                end
            end
            check(#turnBad == 0, name .. ": half and pair take turns down the book (" .. hU .. " halves, " .. (qU / 2) .. " pairs" .. (#turnBad > 0 and ("; same twice at " .. table.concat(turnBad, ", ")) or "") .. ")")
            -- the First Days checklist first on its page
            local ck
            for _, b in ipairs(pl) do if b.check and b.first then ck = b; break end end
            check(ck ~= nil and ck.k == "check", name .. ": the First Days checklist comes first on its filler page (" .. (ck and ("page " .. ck.page .. ", first block " .. ck.k) or "no checklist page") .. ")")
            -- the deck's order
            orders[#orders + 1] = { name = name, o = dealOrder(pl) }
            local st = bk.adStats or {}
            say(string.format("%s thirds: 205 slots asked %s, no third left %s, thirds dealt %s of %d; NOTES blocks %s; full pages %s (%s NOTES)", name,
                tostring(st.ask205), tostring(st.miss205), tostring(st.at and st.at.third), #A.third, tostring(st.notes), tostring(st.full), tostring(st.fullMiss)))
            -- the spreads with something dealt
            adSpreads = {}
            for _, b in ipairs(pl) do adSpreads[math.floor((b.page + 1) / 2)] = true end
            -- turn to every spread
            local n = math.floor(#bk.pages / 2)
            local steps = {}
            for s_ = 1, n do
                steps[#steps + 1] = { n = 3, fn = function() book().spread = s_; rec = {} end }
                steps[#steps + 1] = { n = 1, fn = function()
                    local bk2 = book()
                    local g = bk2._g
                    local u = g.u
                    local r = rec or {}
                    rec = nil
                    local onPage = {}
                    for _, d in pairs(r) do
                        local right = d.x + d.w / 2 >= g.right.x
                        local pg = right and g.right or g.left
                        local pi = s_ * 2 - (right and 0 or 1)
                        local tx = snap(pg.x + M * u)
                        local sz = sizeOf(d.n)
                        local e = S[sz]
                        if d.x < tx - 1 or d.x + d.w > pg.x + pg.w - M * u + 1 then bad(d.n .. " p" .. pi .. " outside the text block's sides (x " .. d.x .. "-" .. (d.x + d.w) .. ", block " .. tx .. "-" .. snap(pg.x + pg.w - M * u) .. ")") end
                        if d.y < pg.y + MT * u - 1 then bad(d.n .. " p" .. pi .. " above the text block") end
                        if d.y + d.h > pg.y + (PH - FOOT) * u then bad(d.n .. " p" .. pi .. " into the foot (bottom " .. (d.y + d.h) .. ", foot " .. snap(pg.y + (PH - FOOT) * u) .. ")") end
                        if e and (math.abs(d.w - snap(e[1] * u)) > 1 or math.abs(d.h - snap(e[2] * u)) > 1) then bad(d.n .. " p" .. pi .. " drawn " .. d.w .. "x" .. d.h .. ", design " .. snap(e[1] * u) .. "x" .. snap(e[2] * u)) end
                        if d.x ~= math.floor(d.x) or d.y ~= math.floor(d.y) then bad(d.n .. " p" .. pi .. " off whole pixels (" .. d.x .. "," .. d.y .. ")") end
                        if sz == "full" and (d.x ~= tx or d.y ~= snap(pg.y + MT * u)) then bad(d.n .. " p" .. pi .. " full ad not at the block's top left (" .. d.x .. "," .. d.y .. " vs " .. tx .. "," .. snap(pg.y + MT * u) .. ")") end
                        onPage[pi] = onPage[pi] or {}
                        onPage[pi][#onPage[pi] + 1] = d
                        if drawnOn[d.n] and drawnOn[d.n] ~= pi then bad(d.n .. " drawn on page " .. drawnOn[d.n] .. " and page " .. pi) end
                        drawnOn[d.n] = pi
                    end
                    -- pairs: level, an even gutter
                    for pi, list in pairs(onPage) do
                        local qs = {}
                        for _, d in ipairs(list) do if sizeOf(d.n) == "quarter" then qs[#qs + 1] = d end end
                        if #qs == 2 then
                            table.sort(qs, function(a, b) return a.x < b.x end)
                            local gut = qs[2].x - (qs[1].x + qs[1].w)
                            if qs[1].y ~= qs[2].y then bad("pair p" .. pi .. " not level (" .. qs[1].y .. " / " .. qs[2].y .. ")") end
                            if gut ~= snap(10 * u) then bad("pair p" .. pi .. " gutter " .. gut .. ", expected " .. snap(10 * u)) end
                            say(name .. " pair p" .. pi .. ": tops " .. qs[1].y .. "/" .. qs[2].y .. ", gutter " .. gut .. " px")
                        elseif #qs ~= 0 then bad("page " .. pi .. " has " .. #qs .. " quarters") end
                    end
                    -- drawn against planned
                    for _, pi in ipairs({ s_ * 2 - 1, s_ * 2 }) do
                        local want = {}
                        for _, b in ipairs(pl) do
                            if b.page == pi and b.names and not (b.spoiler and G.spoilHidden(b.topic, b.ri or 1, { spoiler = true })) then
                                for _, n in ipairs(b.names) do if n ~= "house" and n ~= "NOTES" then want[n] = true end end
                            end
                        end
                        local got = {}
                        for _, d in ipairs(onPage[pi] or {}) do got[d.n] = true; if not want[d.n] then bad(d.n .. " drawn on page " .. pi .. " but not dealt there") end end
                        for n in pairs(want) do if not got[n] then bad(n .. " dealt to page " .. pi .. " but not drawn") end end
                        if spoilPages[pi] and G.spoilHidden(spoilPages[pi].topic, spoilPages[pi].ri or 1, { spoiler = true }) and onPage[pi] then bad("spoiler page " .. pi .. " shows an ad while hidden") end
                    end
                end }
                if (shootAll and adSpreads[s_]) or (shootSome and shootSome[s_]) then
                    steps[#steps + 1] = { n = 25, fn = function() end }
                    steps[#steps + 1] = { n = 5, fn = function() shot(name .. "_s" .. string.format("%02d", s_)) end }
                end
            end
            steps[#steps + 1] = { n = 2, fn = function()
                check(#fails == 0, name .. ": every spread's ads inside the text block, clear of the foot, at design size, level pairs, as dealt (" .. n .. " spreads" .. (#fails > 0 and ("; " .. #fails .. " faults: " .. table.concat(fails, " || ", 1, math.min(#fails, 8))) or "") .. ")")
                local cnt = 0
                for _ in pairs(drawnOn) do cnt = cnt + 1 end
                say(name .. ": " .. cnt .. " ad pictures drawn across the book")
            end }
            now(steps)
        end },
    })
end

step(30, function()
    say("language " .. lang .. ", screen " .. sw .. "x" .. sh .. ", UI scale " .. tostring(ZeD.T and ZeD.T.root))
    opt:setValue(1)
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow()
    if cw and cw:isReallyVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
    setSize("small"); padMode = false
    G.open(0)
end)
step(30, function()
    check(B.isOpen(0), "F1 on Full opens the book")
    local bk = book()
    say("unit " .. tostring(bk._g and bk._g.u) .. ", seed " .. tostring(bk._adSeed) .. ", pages " .. #bk.pages)
    firstSig = sig(plan(bk))
end)

if lang == "EN" then
    step(1, function() reading("small_kb", true) end)
    -- close and reopen
    step(10, function() B.close(0) end)
    step(30, function() G.open(0) end)
    step(30, function()
        local s = sig(plan(book()))
        check(s == firstSig, "close and reopen: the same ads on the same pages")
        check(book()._adSeed == B.adSeed(0), "the seed reads the same again")
        -- another character or save: the deck from another name
        local d1 = B.adDeck(book()._adSeed)
        local other = B.hashSeed(tostring(getWorld():getWorld()) .. "|Someone Else")
        local otherSave = B.hashSeed("Another Save|" .. tostring(getPlayer():getDescriptor():getForename()) .. " " .. tostring(getPlayer():getDescriptor():getSurname()))
        local d2, d3 = B.adDeck(other), B.adDeck(otherSave)
        local function same(a, b) for _, k in ipairs({ "full", "half", "third", "quarter" }) do for i = 1, #a[k] do if a[k][i] ~= b[k][i] then return false end end end return true end
        check(not same(d1, d2) and not same(d1, d3), "another character or another save deals another order (seeds " .. d1.full[1] .. "/" .. d2.full[1] .. "/" .. d3.full[1] .. " lead the full pages)")
    end)
    -- the spoiler pages
    local spoilB
    step(5, function()
        G.spoil = G.spoil or {}
        for k in pairs(G.spoil) do G.spoil[k] = nil end
        local pl = plan(book())
        local list = {}
        for _, p in ipairs(book().pages) do if p.kind == "rules" and p.rules and p.rules.spoiler then list[#list + 1] = p end end
        say("spoiler rules pages: " .. #list)
        for i, p in ipairs(book().pages) do
            if p.kind == "rules" and p.rules and p.rules.spoiler then
                local names = {}
                for _, b in ipairs((p.filler and p.filler.ads) or {}) do names[#names + 1] = b.k .. (b.names and (":" .. table.concat(b.names, "+")) or "") end
                say("  page " .. i .. " (" .. tostring(p.topic and p.topic.title) .. "): foot " .. (p.filler and table.concat(names, ", ") or "none"))
                if not spoilB and p.filler then spoilB = { page = i, p = p } end
            end
        end
        if spoilB then book().spread = math.floor((spoilB.page + 1) / 2); rec = {} end
    end)
    step(25, function()
        if not spoilB then say("no spoiler page with a foot"); rec = nil; return end
        local any = 0
        for _, d in pairs(rec or {}) do
            local g = book()._g
            local right = d.x + d.w / 2 >= g.right.x
            if (book().spread * 2 - (right and 0 or 1)) == spoilB.page then any = any + 1 end
        end
        rec = nil
        check(any == 0, "spoiler page " .. spoilB.page .. ": no ad while the numbers are hidden")
        shot("spoiler_hidden")
        G.spoil[G.spoilKey(spoilB.p.topic, spoilB.p.ri or 1)] = true
    end)
    step(5, function() rec = {} end)
    step(25, function()
        if not spoilB then return end
        local names = {}
        local g = book()._g
        for _, d in pairs(rec or {}) do
            local right = d.x + d.w / 2 >= g.right.x
            if (book().spread * 2 - (right and 0 or 1)) == spoilB.page then names[#names + 1] = d.n end
        end
        rec = nil
        local planned = 0
        for _, b in ipairs(spoilB.p.filler.ads or {}) do if b.names then planned = planned + #b.names end end
        check(#names == planned, "spoiler page shown: its foot's ads drawn (" .. #names .. " of " .. planned .. ": " .. table.concat(names, ", ") .. ")")
        check(sig(plan(book())) == firstSig, "showing the numbers changes no other page (the deal is the same)")
        shot("spoiler_shown")
        for k in pairs(G.spoil) do G.spoil[k] = nil end
    end)
    -- the other readings
    step(5, function() padMode = true end)
    step(30, function() reading("small_pad", false, { [1] = false }) end)
    step(5, function() padMode = false; setSize("large") end)
    step(40, function() reading("large_kb", true) end)
    step(5, function() padMode = true end)
    step(30, function() reading("large_pad", false) end)
    -- the order across the four readings
    step(5, function()
        local bad = {}
        for i = 2, #orders do
            for _, k in ipairs({ "full", "half", "quarter", "third" }) do
                if not isPrefix(orders[1].o[k], orders[i].o[k]) then bad[#bad + 1] = orders[i].name .. " " .. k end
            end
        end
        check(#bad == 0, "text size and pad wording keep the order: each reading deals each size from the same list (" .. (#bad > 0 and table.concat(bad, ", ") or (#orders .. " readings")) .. ")")
        for _, o in ipairs(orders) do
            say(o.name .. " dealt: full " .. #o.o.full .. ", half " .. #o.o.half .. ", quarter " .. #o.o.quarter .. ", third " .. #o.o.third)
        end
    end)
    -- pad wording pictures: the first ad spreads at Large
    step(5, function()
        local n, got = 0, {}
        for s_ = 1, math.floor(#book().pages / 2) do if adSpreads[s_] and n < 3 then n = n + 1; got[#got + 1] = s_ end end
        local steps = {}
        for _, s_ in ipairs(got) do
            steps[#steps + 1] = { n = 30, fn = function() book().spread = s_ end }
            steps[#steps + 1] = { n = 5, fn = function() shot("large_pad_s" .. string.format("%02d", s_)) end }
        end
        now(steps)
    end)
    -- the Simple look
    step(5, function() padMode = false; setSize(keep.size or "small"); B.close(0) end)
    step(10, function() opt:setValue(2); G.open(0) end)
    step(40, function()
        local w = G.get and G.get(0)
        check(not B.isOpen(0) and w ~= nil and w:isReallyVisible(), "Simple look: F1 opens the window, not the book")
        shot("simple")
        local hit = false
        pcall(function()
            local ui = UIManager.getUI()
            for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getTable() and e:getTable().Type == "ZeD_GuideBook" and e:isVisible() then hit = true end end
        end)
        check(not hit, "Simple look: no book panel (and so no ads) on screen")
        if w and w:isReallyVisible() then pcall(G.toggle, 0) end
    end)
else
    -- another language: one reading, the house ad and an ad page
    step(1, function() reading("small_kb", false) end)
    step(5, function()
        local pl = plan(book())
        local house, ad
        for _, b in ipairs(pl) do
            if b.k == "full" and b.names[1] == "house" and not house then house = b.page end
            if (b.k == "half" or b.k == "pair" or (b.k == "full" and b.names[1] ~= "house" and b.names[1] ~= "NOTES")) and not ad then ad = b.page end
        end
        say("house ad on page " .. tostring(house) .. ", an English ad on page " .. tostring(ad))
        check(house ~= nil, "the house ad is one of the whole-page ads in " .. lang)
        say("house ad head: " .. tostring(ZeD.tr("UI_ZeD_Guide_Ad1_Head")))
        local steps = {}
        for _, pg in ipairs({ house, ad }) do
            if pg then
                steps[#steps + 1] = { n = 30, fn = function() book().spread = math.floor((pg + 1) / 2) end }
                steps[#steps + 1] = { n = 5, fn = function() shot("p" .. pg) end }
            end
        end
        now(steps)
    end)
end

step(10, function()
    pcall(B.close, 0)
    opt:setValue(keep.look)
    setSize(keep.size or "small")
    G.onPad = keep.onPad
    say(pass .. " passed, " .. fail .. " failed")
    say("DONE")
end)

local function tick()
    if wait > 0 then wait = wait - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    wait = s.n
end
say("start")
Events.OnTick.Add(tick)
