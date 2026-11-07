-- ZeDUI/tools/qa/zedqa_book83_reopen.lua  (Nov 3 2026, QA; punch list 83, Build's da1a99cf: reopens and Aiming after jumps)
-- Video effects on. The book opened and closed 4 times, a picture after the last; Simple (the window) opened and
-- closed, then Full again, a picture (on the first chapter's spread). Then every spread visited in turn (a clip for each topic), Aiming's spread last:
-- its clip's isValid() and width, the count of clips made, a picture; closed and reopened on Aiming, again.
-- Settings put back. Shots zqa_b8r_*.png; grep "ZEDQA b8r".
local function say(s) print("ZEDQA b8r " .. tostring(s)) end
local B, G = ZeD.GuideBook, ZeD.Guide
local core = getCore()
local opt = ZeD.Settings.guideStyleOption
local was = { look = opt:getValue(), video = core:getOptionDoVideoEffects() }
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_b8r_" .. n .. ".png") end); say("shot " .. n) end
local function Bk() return B.books[0] end
local function aimInfo(tag)
    local b = Bk(); local n, aim = 0, nil
    for k, c in pairs(b._clips or {}) do if c and c.video then n = n + 1 end; if k:find("aiming") and k:sub(-2) == ":v" then aim = c end end
    local v = aim and aim.video
    local valid, w = nil, nil
    pcall(function() valid = v:isValid() end); pcall(function() w = v:getWidth() end)
    say(string.format("%s: clips made %d; Aiming video %s isValid %s width %s; still %s", tag, n, tostring(v ~= nil), tostring(valid), tostring(w), tostring(aim and aim.still ~= nil)))
end
step(30, function() core:setOptionDoVideoEffects(true); opt:setValue(1) end)
for k = 1, 4 do
    step(20, function() B.open(0); local b = Bk(); b.spread = math.floor((b.sectionPage[b.sections[1].id] + 1) / 2) end)
    step(20, function() if k < 4 then B.close(0) end end)
end
step(40, function() shot("1_after_4_opens") ; B.close(0) end)
step(20, function() opt:setValue(2); G.open(0) end)
step(30, function() G.get(0):close(); opt:setValue(1) end)
step(20, function() B.open(0); local b = Bk(); b.spread = math.floor((b.sectionPage[b.sections[1].id] + 1) / 2) end)
step(40, function() shot("2_after_simple_round_trip") end)
-- every spread, Aiming's last
local N = 0
step(10, function() N = #Bk().pages / 2 end)
for s = 5, 44 do step(6, function() if s <= N then Bk().spread = s end end) end
step(10, function() local b = Bk(); for _, t in ipairs(b.flat) do if t.titleKey == "SurvivalGuide_aiming_title" then b:goToTopic(t.id) end end end)
step(120, function() aimInfo("after visiting every spread"); shot("3_aiming_after_jumps") end)
step(10, function() B.close(0) end)
step(20, function() B.open(0, "SurvivalGuide_aiming_title") end)
step(120, function() aimInfo("closed and reopened on Aiming"); shot("4_aiming_reopened") end)
step(20, function()
    B.close(0); opt:setValue(was.look); core:setOptionDoVideoEffects(was.video)
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
