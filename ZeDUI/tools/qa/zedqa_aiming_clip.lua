-- ZeDUI/tools/qa/zedqa_aiming_clip.lua  (Nov 3 2026, QA; punch list 83: is Aiming's clip the book or the file?)
-- Video effects on. The window look opened straight on Aiming, 4 s, a picture; Vaulting the same (a clip that plays,
-- for comparison); then the book opened straight on Aiming's spread (goToTopic), 4 s, a picture. Settings put back.
-- Shots zqa_aim_<n>.png; grep "ZEDQA aim".
local function say(s) print("ZEDQA aim " .. tostring(s)) end
local B, G = ZeD.GuideBook, ZeD.Guide
local core = getCore()
local opt = ZeD.Settings.guideStyleOption
local was = { look = opt:getValue(), video = core:getOptionDoVideoEffects() }
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_aim_" .. n .. ".png") end); say("shot " .. n) end
step(30, function() core:setOptionDoVideoEffects(true); opt:setValue(2); G.open(0, "SurvivalGuide_aiming_title") end)
step(240, function()
    local w = G.get(0)
    say("window on " .. tostring(w.byId[w.sel] and w.byId[w.sel].titleKey) .. ": clip " .. tostring(w._clip) .. ", still " .. tostring(w._still))
    shot("1_window_aiming")
    w:choose(w.flat[3].id, true)
end)
step(240, function() local w = G.get(0); say("window on " .. tostring(w.byId[w.sel].titleKey) .. ": clip " .. tostring(w._clip)); shot("2_window_vaulting"); w:close() end)
step(30, function()
    opt:setValue(1)
    B.open(0, "SurvivalGuide_aiming_title")
    local b = B.books[0]; local i = b.spread * 2 - 1
    say("book opened on spread " .. b.spread .. ": " .. tostring(b.pages[i] and b.pages[i].topic and b.pages[i].topic.titleKey) .. " | " .. tostring(b.pages[i + 1] and b.pages[i + 1].topic and b.pages[i + 1].topic.titleKey))
end)
step(240, function()
    local b = B.books[0]
    for k, c in pairs(b._clips) do say("book clip " .. k .. ": " .. tostring(c and c.video)) end
    shot("3_book_aiming")
    B.close(0)
end)
step(20, function()
    opt:setValue(was.look); core:setOptionDoVideoEffects(was.video)
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
