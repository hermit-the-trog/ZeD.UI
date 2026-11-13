-- ZeDUI/tools/qa/zedqa_book83_pause.lua  (Nov 3 2026, QA; punch list 83, Build's 55b7e747: the Game Paused box and ragged lines)
-- The game's paused message flag before, with the book open, and after it closes; a picture with the book open on a
-- long-text spread (Loot) and one after closing (the game paused by hand, so the box shows). Ragged right: the gaps
-- between words in the laid-out lines, none wider than one space. grep "ZEDQA b8p".
local function say(s) print("ZEDQA b8p " .. tostring(s)) end
local B = ZeD.GuideBook
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_b8p_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function flag() local v = nil; pcall(function() v = UIManager.isShowPausedMessage() end); return v end
local opt = ZeD.Settings.guideStyleOption
local was = { look = opt:getValue(), msg = flag() }
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(30, function() opt:setValue(1); say("before: paused message " .. tostring(was.msg)) end)
step(10, function() B.open(0); local b = B.books[0]; b.spread = math.floor((b.sectionPage[b.sections[2].id] + 1) / 2) end)
step(60, function()
    check(flag() == false, "the paused message is off while the book is open (" .. tostring(flag()) .. ")")
    shot("1_open_loot")
end)
step(10, function() B.close(0) end)
step(20, function() check(flag() == was.msg, "it is put back on close (" .. tostring(flag()) .. ")"); setGameSpeed(0) end)
step(60, function() shot("2_closed_paused_by_hand") end)
step(10, function()
    setGameSpeed(1); opt:setValue(was.look)
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
Events.OnRenderTick.Add(tick)
say("start")
