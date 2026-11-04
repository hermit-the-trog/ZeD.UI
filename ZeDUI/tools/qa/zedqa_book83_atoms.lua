-- ZeDUI/tools/qa/zedqa_book83_atoms.lua  (Nov 3 2026, QA; punch list 83, Build's 8c797b01: the book's words as the game's text atoms)
-- With the real mouse (release_check_mouse.ps1 through Lua/zedqa_click.txt): a contents row, a click over the body
-- text on the right page and on the left, a thumb, the strip's Next and its start-up box, each checked by where the
-- book went (the atoms must not take the clicks). Aiming's clip after a long wait. Frame time on a text-heavy spread
-- against the window look on the same topic. A picture after the book closes (no words left on screen). Settings put
-- back. Shots zqa_b8a_<w>x<h>_*.png; grep "ZEDQA b8a".
local function say(s) print("ZEDQA b8a " .. tostring(s)) end
local B, G = ZeD and ZeD.GuideBook, ZeD and ZeD.Guide
if not (B and G and ZeD.Settings and ZeD.Settings.guideStyleOption) then say("ERR the book is not loaded"); say("DONE"); return end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_b8a_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function Bk() return B.books[0] end
local opt = ZeD.Settings.guideStyleOption
local function setLook(v) pcall(function() opt:setValue(v) end) end
local function look() local v = -1; pcall(function() v = opt:getValue() end); return v end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local was = {}
local function clickDone() local r = getFileReader("zedqa_click_done.txt", false); local l = r and r:readLine(); if r then r:close() end; return l ~= nil and l:find("done", 1, true) ~= nil end
-- a real left click at panel (= screen) x, y; then `after` once the helper says done and the game has had a few frames
local function click(label, getXY, after)
    local at
    step(10, function()
        local b = Bk()
        local x, y = getXY(b)
        at = { x = math.floor(x), y = math.floor(y) }
        pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
        pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write("left " .. at.x .. " " .. at.y); f:close() end)
        say("click " .. label .. " at " .. at.x .. "," .. at.y .. " (spread " .. b.spread .. ")")
    end)
    waitFor(5, 900, clickDone, function() end)
    step(20, function() after(Bk(), at) end)
end
local function spreadOf(i) return math.floor((i + 1) / 2) end

step(60, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    was.look, was.startup, was.video = look(), core:getOptionShowSurvivalGuide(), core:getOptionDoVideoEffects()
    setLook(1); core:setOptionDoVideoEffects(true)
    local cw = ZeD_CharacterWindow.getWindow()
    if cw and cw:isReallyVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
    B.open(0)
end)
step(30, function() Bk().spread = 2 end)
-- a contents row (chapter 5), clicked over its words
click("contents row 5", function(b) local r = b._contentsRows[5]; return r.x + 40, r.y + r.h * 0.45 end, function(b)
    local want = spreadOf(b.sectionPage[b.sections[5].id])
    check(b.spread == want, "a click on a contents row's words opens its chapter (spread " .. b.spread .. ", want " .. want .. ")")
end)
-- over the body text: the right page turns on, the left back (the first chapter's spread)
step(10, function() local b = Bk(); b.spread = spreadOf(b.sectionPage[b.sections[1].id]); was.s = b.spread end)
click("right page body text", function(b) local g = b._g; return g.right.x + g.right.w * 0.4, g.right.y + g.right.h * 0.49 end, function(b)
    check(b.spread == was.s + 1, "a click over the right page's text turns on (" .. b.spread .. ")")
end)
click("left page body text", function(b) local g = b._g; return g.left.x + g.left.w * 0.3, g.left.y + g.left.h * 0.355 end, function(b)
    check(b.spread == was.s, "a click over the left page's text turns back (" .. b.spread .. ")")
end)
-- a thumb (chapter 3), over its number when lit
click("thumb 3", function(b) local r = b._thumbs[3]; return r.x + r.w / 2, r.y + r.h / 2 end, function(b)
    local want = spreadOf(b.sectionPage[b.sections[3].id])
    check(b.spread == want, "a click on a thumb opens its chapter (spread " .. b.spread .. ", want " .. want .. ")")
end)
-- the strip: Next and the start-up box
click("strip Next", function(b) local r; for _, x in pairs(b._stripRects.buttons or {}) do if x.id == "next" then r = x end end; was.s = b.spread; return r.x + r.w / 2, r.y + r.h / 2 end, function(b)
    check(b.spread == was.s + 1, "the strip's Next takes the real click (" .. b.spread .. ")")
end)
click("strip start-up box", function(b) local r = b._stripRects.check; was.su = core:getOptionShowSurvivalGuide(); return r.x + r.w / 2, r.y + r.h / 2 end, function(b)
    check(core:getOptionShowSurvivalGuide() == not was.su, "the strip's start-up box takes the real click")
    core:setOptionShowSurvivalGuide(was.su)
end)
-- Aiming's clip, with a long wait
step(10, function()
    local b = Bk()
    for _, t in ipairs(b.flat) do if t.titleKey == "SurvivalGuide_aiming_title" then b:goToTopic(t.id); was.aim = t end end
    say("Aiming: " .. tostring(was.aim and was.aim.video))
end)
step(240, function()
    local b = Bk(); local c = was.aim and b._clips[was.aim.id .. ":v"]
    say("Aiming's clip entry: " .. tostring(c) .. (c and (" video " .. tostring(c.video) .. " still " .. tostring(c.still)) or ""))
    check(c and c.video, "Aiming's clip loads (sg_aiming.bik)")
    shot("aiming_after_4s")
end)
-- frame time: the book on a text-heavy spread, then the window on the same topic
local function timeFrames(tag)
    local t0, n
    step(30, function() t0 = getTimestampMs(); n = 0 end)
    waitFor(1, 400, function() n = n + 1; return n >= 240 end, function()
        local ms = (getTimestampMs() - t0) / 240
        was[tag] = ms
        say(string.format("%s: %.2f ms a frame (%.0f fps)", tag, ms, 1000 / ms))
    end)
end
step(10, function() local b = Bk(); b.spread = spreadOf(b.sectionPage[b.sections[2].id]) end)
timeFrames("book")
step(10, function() B.close(0); setLook(2); G.open(0, "SurvivalGuide_inventory_title") end)
timeFrames("window")
step(10, function()
    check(was.book and was.window and was.book < was.window * 1.5 + 2, string.format("the book's frame time is near the window's (%.2f against %.2f ms)", was.book or -1, was.window or -1))
    local w = G.get(0); if w then w:close() end
    setLook(1)
end)
-- after closing: nothing left on screen
step(10, function() B.open(0); Bk().spread = 3 end)
step(40, function() shot("open_spread3") end)
step(10, function() B.close(0) end)
step(40, function() shot("after_close"); check(not B.isOpen(0), "the book is closed") end)
step(10, function()
    setLook(was.look); core:setOptionShowSurvivalGuide(was.startup); core:setOptionDoVideoEffects(was.video)
    pcall(function() core:saveOptions() end)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say(string.format("RESULT %d pass, %d fail", passes, fails))
    say("DONE")
end)

local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    if q.cond then
        q.left = (q.left or q.max) - 1
        local ok, done = pcall(q.cond)
        if not (ok and done) and q.left > 0 then return end
        if not (ok and done) then say("WARN step " .. (qi + 1) .. ": waited " .. q.max .. " frames, went on") end
    end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
-- (the book pauses the game: the steps run on OnRenderTick)
Events.OnRenderTick.Add(tick)
say("start")
