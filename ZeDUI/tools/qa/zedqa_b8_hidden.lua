-- ZeDUI/tools/qa/zedqa_b8_hidden.lua  (Nov 8 2026, QA; punch list 109, CHECK_hidden_facts_20261107.md)
-- The guide's two pages that open with a find (ZeD_HiddenFacts.lua): the TV schedule on Television/Radio and the infection
-- odds on Zombie Attacks, read live from the real game (its broadcast scripts, its sandbox). Single player.
--   * Find first (ZeD setup > Hidden facts), the character's marks cleared: each page is the locked page (one column, one
--     row, naming TV Monthly / the First Aid skill); pictures of the book on both
--   * the finds: other reading opens nothing; TV Monthly opens only the schedule; a First Aid book half read opens
--     nothing, read to its last page opens the odds (the same test the reading hook runs: F.readToEnd then F.mark)
--   * the schedule against the game's own clock: only shows that teach, within 7 days, sorted, day / time / channel / what;
--     the time follows the game's 24-hour option (both settings tried); no channel script reads as "not available"
--   * the odds follow the world's Transmission (rows Bitten, Cut, Scratched; Always / Sometimes / Never per the table),
--     behind the spoiler bar; a Mortality-Never world says so first
--   * Always: both open with nothing read; the crafting card's "How to learn" names the magazine for a recipe one teaches
--     (and keeps its own words on Find first)
--   * the book (Full) and the Simple window carry the pages; pictures zqa_b8_hf_*.png
-- Manual: reading a real TV Monthly and a First Aid book to the end in the game (the hook on ISReadABook:perform needs the
-- real timed action), the Deck at Large text, a server's client, split screen. Puts back: the setting, the marks, the
-- spawned books, the look, the clock option. grep "ZEDQA b8hf".
local TAG = "b8hf"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8_hf_" .. n .. ".png") end); say("shot " .. n) end

local p = getPlayer()
local F, G, B = ZeD.Finds, ZeD.Guide, ZeD.GuideBook
if not (F and G and B and ZeD.Settings and ZeD.Settings.hiddenFactsOption) then
    say("ERR ZeD.Finds, the guide or the Hidden facts setting is not loaded"); say("DONE"); return
end
local TV, INF = "SurvivalGuide_television_title", "SurvivalGuide_zombie_attacks_title"
local opt, look = ZeD.Settings.hiddenFactsOption, ZeD.Settings.guideStyleOption
local core = getCore()
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = { given = {}, was = {} }

local function md() return p:getModData() end
local function clearMarks() md().ZeD_Finds = nil; G._rulesC = {} end
local function book() return B.books[0] end
local function bookPages(key)
    local out = {}
    for i, pg in ipairs(book() and book().pages or {}) do
        if pg.kind == "rules" and pg.topic and pg.topic.titleKey == key then out[#out + 1] = { i = i, p = pg } end
    end
    return out
end
local function pageText(t)
    local parts = { tostring(t.title) }
    for _, r in ipairs(t.rows or {}) do parts[#parts + 1] = table.concat(r, " / ") end
    for _, n in ipairs(t.notes or {}) do if n then parts[#parts + 1] = "note: " .. tostring(n) end end
    return table.concat(parts, " | ")
end
local function hasAnyNo(s) return s ~= nil end
local function openBook(key)
    pcall(B.close, 0)
    G.open(0, key)
end
local function showSpread(key, spoilShown)
    local pgs = bookPages(key)
    if #pgs == 0 then return nil end
    if spoilShown then for _, e in ipairs(pgs) do G.spoil[G.spoilKey(e.p.topic, e.p.ri or 1)] = true end end
    book().spread = math.floor((pgs[1].i + 1) / 2)
    return pgs
end
local function give(ft)
    local ok, it = pcall(function() return p:getInventory():AddItem(ft) end)
    if ok and it then S.given[#S.given + 1] = it; return it end
    return nil
end

-- ---- setup
step(20, function()
    S.was.opt, S.was.look = opt:getValue(), look:getValue()
    S.was.finds = md().ZeD_Finds
    S.was.clock = nil
    pcall(function() S.was.clock = core:getOptionClock24Hour() end)
    S.cwOpen = ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isReallyVisible()
    say("before: Hidden facts item " .. tostring(S.was.opt) .. ", guide look " .. tostring(S.was.look) .. ", 24-hour clock " .. tostring(S.was.clock)
        .. ", the character's marks " .. tostring(S.was.finds ~= nil))
    check(not (isClient and isClient()), "single player")
    check(F._hooked == true, "the reading hook on ISReadABook:perform is installed")
    check(F.KIND_OF["Base.TVMagazine"] == "tv" and F.KIND_OF["Base.BookFirstAid3"] == "medical" and F.KIND_OF["Base.Book"] == nil,
          "the finds: TV Monthly opens the schedule, a First Aid book the odds, other books nothing")
    if S.cwOpen then ZeD_CharacterWindow.toggleBothPaired(0) end
    pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end)
    look:setValue(1)
    opt:setValue(1)
    clearMarks()
end)

-- ---- A. Find first, nothing found: the locked pages
step(10, function()
    S.hasTv, S.hasMed = F.has("tv"), F.has("medical")
    say("Find first, marks cleared: TV find held " .. tostring(S.hasTv) .. ", First Aid find held " .. tostring(S.hasMed)
        .. (S.hasTv and " (the character's own reading records already open the schedule)" or "")
        .. (S.hasMed and " (the character's own reading records already open the odds)" or ""))
    check(F.always() == false, "Always is off on Find first")
    local tv, inf = F.tvPage(), F.infectionPage()
    if not S.hasTv then
        check(tv and tv.locked == true and #tv.cols == 1 and #tv.rows == 1, "TV: the locked page is one column and one row")
        local find = tv and tv.rows[1] and tv.rows[1][1] or ""
        check(find:find(tostring(getItemNameFromFullType("Base.TVMagazine")), 1, true) ~= nil, "TV: it names TV Monthly (" .. tostring(find) .. ")")
        check(tv and tv.notes and tv.notes[1] ~= nil, "TV: it says what more it could show")
    end
    if not S.hasMed then
        check(inf and inf.locked == true and #inf.cols == 1 and #inf.rows == 1, "odds: the locked page is one column and one row")
        local find = inf and inf.rows[1] and inf.rows[1][1] or ""
        check(find:find(getText("IGUI_perks_Doctor"), 1, true) ~= nil, "odds: it names the First Aid skill (" .. tostring(find) .. ")")
    end
    openBook(TV)
end)
step(40, function()
    check(B.isOpen(0), "F1's book opens (Full)")
    local pgs = showSpread(TV, false)
    check(pgs ~= nil and #pgs >= 1, "Television/Radio has a rules page in the book (" .. tostring(pgs and #pgs) .. " page(s))")
    if pgs then say("Television/Radio rules page(s) at " .. pgs[1].i .. ", locked now: " .. tostring(not S.hasTv)) end
end)
step(30, function() shot("tv_" .. (S.hasTv and "open_by_records" or "locked")) end)
step(10, function()
    local pgs = showSpread(INF, false)
    check(pgs ~= nil and #pgs >= 1, "Zombie Attacks has a rules page in the book (" .. tostring(pgs and #pgs) .. " page(s))")
    if pgs then
        local last = pgs[#pgs]
        say("Zombie Attacks rules pages at " .. pgs[1].i .. " to " .. last.i .. "; the last is: " .. pageText(last.p.rules))
    end
end)
step(30, function() shot("inf_" .. (S.hasMed and "open_by_records" or "locked")) end)

-- ---- B. the finds
step(10, function()
    pcall(B.close, 0)
    local other = give("Base.Book") or give("Base.Paperback")
    if other then
        check(F.mark(p, other:getFullType()) == false and F.has("tv") == S.hasTv and F.has("medical") == S.hasMed, "other reading opens nothing")
    end
    local mag = give("Base.TVMagazine")
    if mag then
        local end_ = F.readToEnd({ item = mag, character = p }, false)
        say("TV Monthly pages " .. tostring(mag:getNumberOfPages()) .. ", read-to-end test " .. tostring(end_))
        check(end_ == true or (mag:getNumberOfPages() or 0) > 0, "a magazine with no pages counts when read")
        F.mark(p, mag:getFullType())
        check(F.has("tv") == true, "TV Monthly read: the schedule is open")
        check(F.has("medical") == S.hasMed, "TV Monthly read: the odds are as they were (" .. tostring(F.has("medical")) .. ")")
    else
        check(false, "Base.TVMagazine spawned")
    end
    local fa = give("Base.BookFirstAid1")
    if fa then
        local pages = fa:getNumberOfPages() or 0
        say("First Aid I pages " .. tostring(pages))
        check(pages > 0, "First Aid I is a book with pages")
        fa:setAlreadyReadPages(0)
        check(F.readToEnd({ item = fa, character = p }, false) == false, "a First Aid book not yet read does not count")
        fa:setAlreadyReadPages(math.max(1, math.floor(pages / 2)))
        check(F.readToEnd({ item = fa, character = p }, false) == false, "a First Aid book half read does not count")
        check(F.has("medical") == S.hasMed, "half read: the odds are as they were")
        fa:setAlreadyReadPages(pages)
        local done = F.readToEnd({ item = fa, character = p }, false)
        check(done == true, "read to the last page: counts")
        if done then F.mark(p, fa:getFullType()) end
        check(F.has("medical") == true, "First Aid read to the end: the odds are open")
        check(F.readToEnd({ item = fa, character = p }, true) == true, "on a server's client the end of the reading counts")
    else
        check(false, "Base.BookFirstAid1 spawned")
    end
end)

-- ---- C. the schedule
step(10, function()
    local okN, now = pcall(function() return getZomboidRadio():getScriptManager():getCurrentTimeStamp() end)
    check(okN and tonumber(now) ~= nil, "the game's clock (RadioScriptManager current time stamp) reads " .. tostring(now))
    local sched = F.schedule()
    check(sched ~= nil, "the schedule reads in single player (the stations have scripts)")
    if sched then
        say("the schedule: " .. #sched .. " teaching shows in the next " .. F.DAYS .. " days")
        local sorted, within, fields = true, true, true
        for i, s in ipairs(sched) do
            if i > 1 and (sched[i - 1].at > s.at) then sorted = false end
            if s.at + 360 < now or s.at > now + F.DAYS * 1440 + 1440 then within = false end
            if not (s.channel and s.channel ~= "" and s.teaches and s.teaches ~= "" and s.day and s.mins and s.mins >= 0 and s.mins < 1440) then fields = false end
            if i <= 4 then say(string.format("  day +%d %02d:%02d  %s  teaches %s", s.day, math.floor(s.mins / 60), s.mins - math.floor(s.mins / 60) * 60, s.channel, s.teaches)) end
        end
        check(sorted, "the shows are sorted by start")
        check(within, "every show is on now or ahead (the show list holds the one in progress: it started up to 6 hours back) and starts within " .. F.DAYS .. " days")
        check(fields, "every show has a day, a time, a channel and what it teaches")
        local pg = F.tvPage()
        if #sched > 0 then
            check(pg and #pg.cols == 4 and #pg.rows == #sched, "the page has day / time / channel / teaches columns and a row a show (" .. tostring(pg and #pg.rows) .. " rows)")
            local t24, t12 = nil, nil
            pcall(function() core:setOptionClock24Hour(true) end)
            t24 = F.tvPage().rows[1][2]
            pcall(function() core:setOptionClock24Hour(false) end)
            t12 = F.tvPage().rows[1][2]
            pcall(function() if S.was.clock ~= nil then core:setOptionClock24Hour(S.was.clock) end end)
            say("first show's time: 24-hour '" .. tostring(t24) .. "', 12-hour '" .. tostring(t12) .. "'")
            check(t24 ~= nil and t24:find("^%d%d:%d%d$") ~= nil, "24-hour clock: hh:mm")
            check(t12 ~= nil and t12 ~= t24 and (t12:find("M") ~= nil or t12:find("m") ~= nil), "12-hour clock: the time reads with AM or PM")
            local c = pg.cols
            say("columns: " .. table.concat(c, " | ") .. "; notes: " .. tostring(#(pg.notes or {})))
        else
            say("note: no show in the next week teaches anything here; the page says: " .. pageText(pg))
        end
    end
    -- the page when no channel has a script
    local real = F.schedule
    F.schedule = function() return nil end
    local pg2 = F.tvPage()
    F.schedule = real
    check(pg2 and pg2.rows and pg2.rows[1] and pg2.rows[1][1] == ZeD.tr("UI_ZeD_Hidden_TVUnavailable"), "no channel script: the page says the schedule is not available here")
end)

-- ---- D. the odds
step(10, function()
    local W = F.woundsFor
    local A, Sm, N = ZeD.tr("UI_ZeD_Hidden_Always"), ZeD.tr("UI_ZeD_Hidden_Sometimes"), ZeD.tr("UI_ZeD_Hidden_Never")
    local function eq(t, a, b, c) return t[1] == a and t[2] == b and t[3] == c end
    local r1, r2, r3, r4 = { W(1) }, { W(2) }, { W(3) }, { W(4) }
    check(eq(r1, A, Sm, Sm) and eq(r2, A, N, N) and eq(r3, A, Sm, Sm) and eq(r4, N, N, N), "woundsFor: Blood and Saliva, Saliva Only, Everyone, None")
    local pg = F.infectionPage()
    check(pg ~= nil and not pg.locked, "the odds page is open (a First Aid book was read)")
    if pg then
        check(#pg.rows == 3 and pg.spoiler == true, "three rows (Bitten, Cut, Scratched), behind the spoiler bar")
        local tr_ = SandboxVars and SandboxVars.ZombieLore and SandboxVars.ZombieLore.Transmission
        local b, c, s = W(tonumber(tr_) or 1)
        say("this world's Transmission is " .. tostring(tr_) .. "; page: " .. pageText(pg))
        check(pg.rows[1][2] == b and pg.rows[2][2] == c and pg.rows[3][2] == s, "the page follows this world's Transmission")
        local mort = SandboxVars and SandboxVars.ZombieLore and SandboxVars.ZombieLore.Mortality
        if tonumber(mort) == 7 then
            check(#pg.notes == 3, "Mortality Never: a note ahead of the world line says it is not fatal (" .. #pg.notes .. " notes)")
        else
            check(#pg.notes == 2, "Mortality " .. tostring(mort) .. " (not Never): the world line and the odds note only (" .. #pg.notes .. " notes)")
        end
    end
end)

-- ---- E. the book with the finds held, and pictures
step(10, function() openBook(TV) end)
step(40, function()
    local pgs = showSpread(TV, false)
    check(pgs ~= nil and #pgs >= 1, "TV rules page present with the find held")
end)
step(30, function() shot("tv_found") end)
step(10, function() showSpread(INF, true) end)
step(40, function() shot("inf_found_spoiler_shown") end)
-- the Simple window
step(10, function()
    pcall(B.close, 0)
    look:setValue(2)
    G.open(0, TV)
end)
step(40, function()
    local w = G.get(0)
    check(w and w:isReallyVisible(), "Simple look: F1 opens the window")
    if w then w.scroll = w._maxS or 0 end
end)
step(30, function() shot("tv_window") end)
step(10, function()
    local w = G.get(0)
    if w then w:close() end
    G.open(0, INF)
end)
step(40, function()
    local w = G.get(0)
    if w then w.scroll = w._maxS or 0 end
end)
step(30, function() shot("inf_window") end)

-- ---- F. Always: both open with nothing read; the crafting card names the magazine
step(10, function()
    local w = G.get(0)
    if w then w:close() end
    look:setValue(1)
    md().ZeD_Finds = nil
    G._rulesC = {}
    opt:setValue(1)
    local idx = F.recipeIndex()
    local sample, n = nil, 0
    for k, names in pairs(idx) do n = n + 1; if not sample and not tostring(k):find(":", 1, true) then sample = k end end
    say("recipe sources indexed: " .. n .. " recipes; sample " .. tostring(sample))
    check(n > 0, "the item scripts' LearnedRecipes index builds")
    S.sample = sample
    check(F.recipeSourceText(sample) == nil, "Find first: the crafting card keeps its own words (no magazine named)")
    opt:setValue(2)
    check(F.always() == true, "Hidden facts item 2 reads Always")
    local txt = F.recipeSourceText(sample)
    say("Always, '" .. tostring(sample) .. "' -> " .. tostring(txt))
    check(txt ~= nil and txt ~= "", "Always: How to learn names the magazine")
    check(F.has("tv") == true and F.has("medical") == true, "Always: both pages open with nothing read")
    check(F.tvPage().locked ~= true and F.infectionPage().locked ~= true, "Always: neither page is the locked page")
    openBook(TV)
end)
step(40, function()
    local pgs = showSpread(TV, false)
    check(pgs ~= nil and #pgs >= 1, "Always: the book has the TV page")
end)
step(30, function() shot("tv_always") end)

-- ---- put everything back
step(10, function()
    pcall(B.close, 0)
    local w = G.get(0); if w and w:isReallyVisible() then pcall(function() w:close() end) end
    look:setValue(S.was.look or 1)
    opt:setValue(S.was.opt or 1)
    md().ZeD_Finds = S.was.finds
    G._rulesC = {}
    pcall(function() if S.was.clock ~= nil then core:setOptionClock24Hour(S.was.clock) end end)
    for _, it in ipairs(S.given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
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
