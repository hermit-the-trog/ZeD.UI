-- ZeDUI/tools/qa/zedqa_book83.lua  (Nov 3 2026, QA; punch list 83, the survival guide's Full look: the book, Build's b1fae517)
-- With ZeD setup's Survival guide row on Full: F1 opens the book, Escape and F1 close it, Simple opens the window; the
-- pages (title, contents, introduction, a topic a page, Skill Books' rules page after it); the strip's Previous page,
-- Contents, Next page and start-up box; a click on the left page turns back, on the right on; the wheel, the arrow
-- keys, Page Up / Down and Home; every contents row and thumb jumps to its chapter, with matching page numbers; F1 on
-- the Skills tab opens the spread with Skill Books and its rules; clips on the page (effects on) and stills (off); the
-- controller (LB / RB, Y, Down to the strip, A, B). Then a picture of every spread (BOOK83_SPREADS ~= false), and the
-- director's four. Settings put back. Shots zqa_b83_<w>x<h>_*.png; grep "ZEDQA b83".
local function say(s) print("ZEDQA b83 " .. tostring(s)) end
local B, G = ZeD and ZeD.GuideBook, ZeD and ZeD.Guide
if not (B and G and ZeD.Settings and ZeD.Settings.guideStyleOption) then say("ERR the book or its setup row is not loaded"); say("DONE"); return end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_b83_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end) end
local function Bk() return B.books[0] end
local function f1() triggerEvent("OnKeyPressed", core:getKey(KeybindId.TOGGLE_SURVIVAL_GUIDE)) end
local function speed() local s = -1; pcall(function() s = getGameSpeed() end); return s end
local opt = ZeD.Settings.guideStyleOption
local function setLook(v) pcall(function() opt:setValue(v) end) end
local function look() local v = -1; pcall(function() v = opt:getValue() end); return v end
local function pageAt(i) local b = Bk(); return b and b.pages and b.pages[i] end
local function spreadKinds() local b = Bk(); local i = b.spread * 2 - 1; return tostring(pageAt(i) and pageAt(i).kind) .. "+" .. tostring(pageAt(i + 1) and pageAt(i + 1).kind) end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local was = {}

step(60, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    was.look, was.startup, was.video = look(), core:getOptionShowSurvivalGuide(), core:getOptionDoVideoEffects()
    say("before: guide look " .. tostring(was.look) .. ", start-up box " .. tostring(was.startup) .. ", video effects " .. tostring(was.video))
    check(was.look == 1, "ZeD setup's Survival guide row reads Full (the default)")
    setLook(1)
    -- (no tab open: F1 opens on the title page)
    local cw = ZeD_CharacterWindow.getWindow()
    if cw and cw:isReallyVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
end)
-- ---- F1: the book, paused; F1 and Escape close
step(30, function() f1() end)
step(40, function()
    local b = Bk()
    check(B.isOpen(0) and not (G.get(0) and G.get(0):isReallyVisible()), "F1 opens the book (Full), not the window")
    check(speed() == 0, "the game is paused while the book is open")
    -- (Nov 3, 0394db83: the pages are a flow; topics share pages; a long topic runs on)
    local n, rules, flows = #(b.pages or {}), 0, 0
    local topics, perPage, runOns = 0, {}, 0
    for _, p in ipairs(b.pages or {}) do
        if p.kind == "rules" then rules = rules + 1 end
        if p.kind == "flow" then flows = flows + 1 end
    end
    for _, t in ipairs(b.flat) do
        local i = b.pageOf[t.id]
        if i then topics = topics + 1; perPage[i] = (perPage[i] or 0) + 1 end
    end
    local shared = 0
    for _, k in pairs(perPage) do if k >= 2 then shared = shared + 1 end end
    -- a run-on: a flow page with no topic starting on it (its label is the chapter's running line)
    for i, p in ipairs(b.pages) do if p.kind == "flow" and not perPage[i] then runOns = runOns + 1 end end
    say(string.format("pages %d (%d spreads): %d flow, %d pages shared by 2+ topics, %d run-on pages, %d rules; unit %.3f", n, n / 2, flows, shared, runOns, rules, b._u or -1))
    check(topics == #b.flat and rules >= 1 and n % 2 == 0, "every topic has its place, and the rules page is there (" .. topics .. " of " .. #b.flat .. ")")
    check(shared >= 10, "topics share pages (" .. shared .. " pages with two or more)")
    -- every chapter opens a fresh page; Skill Books on a left page, its rules facing
    local fresh = 0
    for _, s in ipairs(b.sections) do
        local i = b.sectionPage[s.id]; local p = b.pages[i]
        local firstHead
        for _, it in ipairs(p and p.items or {}) do if it.k == "head" then firstHead = firstHead or it end end
        if p and p.kind == "flow" and p.si and b.sections[p.si] == s and firstHead and perPage[i] and b.pageOf[s.topics[1].id] == i then fresh = fresh + 1 end
    end
    check(fresh == #b.sections, "every chapter opener begins its own page (" .. fresh .. " of " .. #b.sections .. ")")
    -- nothing past the folio; the items in order without overlap (a clip's foot above what follows)
    local u = b._u or 1
    local floor = (690 - 26) * u
    local past, overlap = {}, {}
    for i, p in ipairs(b.pages) do
        if p.kind == "flow" then
            local lastBottom = -1
            for _, it in ipairs(p.items or {}) do
                local top = it.y - (it.px or 0)
                if it.k == "clip" then top = it.y end
                if it.y > floor then past[#past + 1] = tostring(i) end
                if top + 1 < lastBottom then overlap[#overlap + 1] = tostring(i) .. ":" .. tostring(it.k) end
                lastBottom = (it.k == "clip") and (it.y + it.h) or it.y
            end
        end
    end
    check(#past == 0, "nothing past the folio" .. (#past > 0 and (" (pages " .. table.concat(past, ", ") .. ")") or ""))
    check(#overlap == 0, "no item overlaps the one before it" .. (#overlap > 0 and (" (" .. table.concat(overlap, ", ", 1, math.min(#overlap, 12)) .. ")") or ""))
    check(spreadKinds() == "blank+title", "F1 with no tab opens on the title page (" .. spreadKinds() .. ")")
end)
step(20, function() f1() end)
step(30, function() check(not B.isOpen(0) and speed() == 1, "F1 again closes it, the game runs") end)
step(20, function() f1() end)
step(20, function() check(ZeD.EscapeTakers.guide() == true, "ZeD's Escape taker closes the book") end)
step(20, function() check(not B.isOpen(0), "closed") end)
step(20, function() f1() end)
step(20, function() local b = Bk(); b:onKeyPress(Keyboard.KEY_ESCAPE) end)
step(20, function() check(not B.isOpen(0) and speed() == 1, "Escape closes the book") end)
-- ---- Simple opens the window
step(10, function() setLook(2); f1() end)
step(30, function()
    check(not B.isOpen(0) and G.get(0) and G.get(0):isReallyVisible(), "Simple: F1 opens the window")
    G.get(0):close(); setLook(1)
end)
-- ---- turning: the strip, the keys, the wheel, the clicks
step(20, function() f1() end)
step(30, function()
    local b = Bk()
    b:press("next"); check(b.spread == 2 and spreadKinds() == "contents+intro", "Next page: the contents facing the introduction (" .. spreadKinds() .. ")")
    b:press("next"); local s3 = b.spread
    b:press("prev"); check(b.spread == 2, "Previous page turns back")
    b:onKeyPress(Keyboard.KEY_RIGHT); check(b.spread == 3, "the right arrow turns on")
    b:onKeyPress(Keyboard.KEY_LEFT); check(b.spread == 2, "the left arrow turns back")
    b:onKeyPress(Keyboard.KEY_NEXT); b:onKeyPress(Keyboard.KEY_NEXT); check(b.spread == 4, "Page Down turns on")
    b:onKeyPress(Keyboard.KEY_PRIOR); check(b.spread == 3, "Page Up turns back")
    b:onKeyPress(Keyboard.KEY_HOME); check(b.spread == 2, "Home goes to the contents")
    b:onMouseWheel(1); check(b.spread == 3, "the wheel turns on")
    b:onMouseWheel(-1); check(b.spread == 2, "and back")
    b:press("toc"); check(b.spread == 2, "Contents goes to the contents")
    for _ = 1, 200 do b:turn(1) end
    check(b.spread == #b.pages / 2, "the last spread stops the turning")
    for _ = 1, 200 do b:turn(-1) end
    check(b.spread == 1, "the first spread stops it back")
    b.spread = 5
end)
step(20, function()
    local b = Bk(); local g = b._g
    b:onMouseDown(g.right.x + g.right.w / 2, g.right.y + g.right.h / 2); check(b.spread == 6, "a click on the right page turns on")
    b:onMouseDown(g.left.x + g.left.w / 2, g.left.y + g.left.h / 2); check(b.spread == 5, "a click on the left page turns back")
    local before = core:getOptionShowSurvivalGuide()
    b:press("startup"); check(core:getOptionShowSurvivalGuide() == not before, "the start-up box sets the game's option")
    b:press("startup"); check(core:getOptionShowSurvivalGuide() == before, "and clears it")
    b.spread = 2
end)
-- ---- the contents rows and the thumbs
step(30, function()
    local b = Bk()
    local rows = b._contentsRows or {}
    local ok, bad = 0, {}
    for si, row in ipairs(rows) do
        b.spread = 2
        local want = b.sectionPage[b.sections[si].id]
        b:goToPage(row.page)
        local i = b.spread * 2 - 1
        local hit = (i == want) or (i + 1 == want)
        if row.page == want and hit then ok = ok + 1 else bad[#bad + 1] = tostring(si) end
    end
    check(#rows == #b.sections and ok == #rows, "every contents row opens its chapter's first page (" .. ok .. " of " .. #b.sections .. (#bad > 0 and ("; not: " .. table.concat(bad, ", ")) or "") .. ")")
    local tok, tbad = 0, {}
    for _, r in ipairs(b._thumbs or {}) do
        b.spread = 2
        b:onMouseDown(r.x + r.w / 2, r.y + r.h / 2)
        local i = b.spread * 2 - 1
        local p1, p2 = b.pages[i], b.pages[i + 1]
        local wp = b.sectionPage[b.sections[r.si].id]
        if wp == i or wp == i + 1 then tok = tok + 1 else tbad[#tbad + 1] = tostring(r.si) end
    end
    check(#(b._thumbs or {}) == #b.sections and tok == #b.sections, "every thumb opens its chapter (" .. tok .. " of " .. #b.sections .. (#tbad > 0 and ("; not: " .. table.concat(tbad, ", ")) or "") .. ")")
    b.spread = 2
end)
-- ---- the controller
step(20, function()
    local b = Bk()
    b:onJoypadDown(Joypad.RBumper); check(b.spread == 3, "RB turns on")
    b:onJoypadDown(Joypad.LBumper); check(b.spread == 2, "LB turns back")
    b.spread = 6; b:onJoypadDown(Joypad.YButton); check(b.spread == 2, "Y goes to the contents")
    b:onJoypadDirRight(); check(b.spread == 3, "D-pad right turns on")
    b:onJoypadDirDown(); check(b.footFocus == 4, "Down goes to the strip (Next page)")
    b:onJoypadDirLeft(); check(b.footFocus == 3, "left walks the strip")
    b:onJoypadDown(Joypad.AButton); check(b.spread == 2, "A presses Contents")
    b:onJoypadDirUp(); check(b.footFocus == nil, "Up goes back to the book")
    b:onJoypadDown(Joypad.BButton)
end)
step(20, function() check(not B.isOpen(0) and speed() == 1, "B closes the book and the game runs") end)
-- ---- F1 from the Skills tab: Skill Books and its rules on one spread
step(20, function() ZeD_CharacterWindow.toggleBothPaired(0) end)
step(40, function()
    local cw = ZeD_CharacterWindow.getWindow(); local strip = cw and cw._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:skills" then strip:onMouseDown(z.x + 2, z.y + 2) end end
end)
step(60, function() f1() end)
step(40, function()
    local b = Bk(); local i = b.spread * 2 - 1
    local p1, p2 = b.pages[i], b.pages[i + 1]
    local sb; for _, t in ipairs(b.flat) do if t.titleKey == "SurvivalGuide_skill_books_title" then sb = t end end
    local k1 = (sb and b.pageOf[sb.id] == i) and sb.titleKey or nil; local k2 = p2 and p2.topic and p2.topic.titleKey
    say("Skills -> " .. tostring(p1 and p1.kind) .. " " .. tostring(k1) .. " | " .. tostring(p2 and p2.kind) .. " " .. tostring(k2))
    check(p1 and p1.kind == "flow" and k1 == "SurvivalGuide_skill_books_title" and p2 and p2.kind == "rules", "F1 on Skills opens Skill Books facing its rules page")
end)
-- ---- clips and stills on a chapter opener
step(10, function() local b = Bk(); b._clips = {}; core:setOptionDoVideoEffects(true); b.spread = math.floor((b.sectionPage[b.sections[2].id] + 1) / 2) end)
step(90, function()
    local b = Bk(); local n = 0
    for k, c in pairs(b._clips) do if c and c.video then n = n + 1 end end
    check(n >= 1, "effects on: the clip plays on the page (" .. n .. ")")
    core:setOptionDoVideoEffects(false)
end)
step(40, function()
    local b = Bk(); local n = 0
    for k, c in pairs(b._clips) do if c and c.still and k:sub(-2) == ":s" then n = n + 1 end end
    check(n >= 1, "effects off: the still shows (" .. n .. ")")
end)
step(10, function() B.close(0); local cw = ZeD_CharacterWindow.getWindow(); if cw and cw:isReallyVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
-- ---- every spread, then the director's four
local N = 0
step(30, function() core:setOptionDoVideoEffects(true); B.open(0); N = #Bk().pages / 2; say("spreads " .. N) end)
if BOOK83_SPREADS ~= false then
    for s = 1, 70 do
        step(4, function() local b = Bk(); if s <= N then b.spread = s end end)
        step(14, function() if s <= N then shot(string.format("spread_%02d", s)) end end)
    end
end
step(10, function() Bk().spread = 1 end)
step(40, function() shot("D1_title") end)
step(10, function() Bk().spread = 2 end)
step(40, function() shot("D2_contents_intro") end)
step(10, function() local b = Bk(); b.spread = math.floor((b.sectionPage[b.sections[4].id] + 1) / 2); say("chapter opener: " .. tostring(b.sections[4].title)) end)
step(150, function() shot("D3_chapter_opener_clip") end)
step(10, function() local b = Bk(); for _, t in ipairs(b.flat) do if t.titleKey == "SurvivalGuide_skill_books_title" then b:goToTopic(t.id) end end end)
step(120, function() shot("D4_skill_books_rules") end)
-- ---- put back
step(20, function()
    B.close(0)
    setLook(was.look)
    core:setOptionShowSurvivalGuide(was.startup); core:setOptionDoVideoEffects(was.video)
    pcall(function() core:saveOptions() end)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("put back: guide look " .. tostring(was.look) .. ", start-up box, video effects " .. tostring(was.video))
    say(string.format("RESULT %d pass, %d fail", passes, fails))
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
-- (the book pauses the game: the steps run on OnRenderTick)
Events.OnRenderTick.Add(tick)
say("start")
