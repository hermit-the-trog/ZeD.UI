-- ZeDUI/tools/qa/zedqa_book83_lang.lua  (Nov 3 2026, QA; punch list 83: the guide in the game's language)
-- With the guide on Full: which look F1 opens (the book for Latin, Greek and Cyrillic; the window for Chinese,
-- Japanese, Korean, Thai, Arabic), and pictures: the book's title page, contents and introduction, a chapter opener,
-- Skill Books and its rules; or the window on Skill Books and Find. grep "ZEDQA b8l". Shots zqa_b8l_<lang>_*.png.
local function say(s) print("ZEDQA b8l " .. tostring(s)) end
local B, G = ZeD.GuideBook, ZeD.Guide
local core = getCore()
local lang = "?"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_b8l_" .. lang .. "_" .. n .. ".png") end); say("shot " .. n) end
local opt = ZeD.Settings.guideStyleOption
local was = { look = opt:getValue() }
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local book
step(30, function()
    opt:setValue(1)
    local cw = ZeD_CharacterWindow.getWindow()
    if cw and cw:isReallyVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
    G.open(0)
end)
-- (the open look is read a few frames on: a panel is not "really visible" in the frame it is added)
step(30, function()
    book = B.isOpen(0)
    local win = G.get(0) and G.get(0):isReallyVisible()
    say("language " .. lang .. ": F1 look " .. (book and "the book" or (win and "the window" or "nothing open")))
end)
step(30, function()
    if book then
        local b = B.books[0]
        b.spread = 1
    else
        local w = G.get(0)
        for _, t in ipairs(w.flat) do if t.titleKey == "SurvivalGuide_skill_books_title" then w:choose(t.id, true) end end
    end
end)
step(60, function() shot(book and "1_title" or "1_window_skill_books") end)
step(10, function()
    if book then B.books[0].spread = 2
    else local w = G.get(0); w.scroll = w._maxS or 0 end
end)
step(60, function() shot(book and (((B.books[0].introPage or 4) <= 4) and "2_contents_intro" or "2_contents") or "2_window_rules") end)
-- (Nov 7: a contents of two or more pages: its last page and the introduction on their own spread)
step(10, function() if book then local b = B.books[0]; b.spread = math.floor(((b.introPage or 4) + 1) / 2) end end)
step(60, function() if book and (B.books[0].introPage or 4) > 4 then shot("2b_contents_end_intro") end end)
step(10, function()
    if book then local b = B.books[0]; b.spread = math.floor((b.sectionPage[b.sections[4].id] + 1) / 2) end
end)
step(90, function() if book then shot("3_chapter_opener") end end)
step(10, function()
    if book then local b = B.books[0]; for _, t in ipairs(b.flat) do if t.titleKey == "SurvivalGuide_skill_books_title" then b:goToTopic(t.id) end end end
end)
step(90, function() if book then shot("4_skill_books_rules") end end)
step(10, function()
    if book then B.close(0) else G.get(0):close() end
    opt:setValue(was.look)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
