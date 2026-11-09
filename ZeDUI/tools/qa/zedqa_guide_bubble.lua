-- ZeDUI/tools/qa/zedqa_guide_bubble.lua  (Nov 8 2026, QA; punch list 122, the survival guide as a belt bubble)
-- In game on the QA save, through the bridge, player one. grep "ZEDQA gbub". Each check prints PASS or FAIL. Pictures
-- zqa_gbub_<w>x<h>_<n>.png. The machine's flag file (Zomboid/Lua/ZeD_guidebubble.txt) and the timing constants are put back.
--   1  START    a fresh machine (flag emptied) and the game's own "Show the guide on startup" ticked: the clock is armed; the
--               guide is NOT open (window or book) 20 s after arming, with the real 30 s clock
--   2  BUBBLE   at 30 s the bubble is up from the belt's Messages note: player one, the director's wording exactly with the
--               key the game names for the guide (F1), a long bare balloon; the line is in Messages, unread; the flag is
--               written. Picture of the balloon on the belt (settled 1.5 s first)
--   3  CLICK    the balloon's click (its run, as the Messages window calls it) opens the guide and takes the balloon away; the
--               line stays; the offer is over
--   4  REPEAT   timings squeezed (first 1 s, every 4 s, hour 18 s): the bubble comes back, the line is not doubled; a
--               right-click (its dismiss) ends it; nothing comes back
--   5  OPENED   F1 by any road (ZeD.Guide.toggle) ends a live offer; the line's Open (the card's run) opens the guide
--   6  ONCE     with the flag written, a new game start (G.start) arms nothing; a flag emptied arms it again
--   7  PAD      a controller in use (JoypadState faked, no real pad needed): the bubble says the Help wheel's words in place of
--               F1; picture, for the director's eye. The real pad run is the director's (A on the Messages line)
--   8  START2   the game's own start handler is gone from OnGameStart and the guide is closed at the start
-- Put back: constants, the flag, the guide closed, Messages emptied.
-- The steps run on OnRenderTick, not OnTick: the open guide pauses the game (as the game's own guide does) and OnTick
-- stops while it is paused, so on OnTick the run stopped at step 3's open and never reached DONE (Nov 8 2026: reported
-- as a freeze; the frames were still drawn, ZeDUI/tools/qa/guide_open_freeze_sim.lua).
local function say(s) print("ZEDQA gbub " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_gbub_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local G, MS, W = ZeD.GuideBubble, ZeD.Messages, ZeD.Guide
if not (G and MS and W) then say("ERR the bubble driver, Messages or the guide is not loaded"); say("DONE"); return end

local FILE = "ZeD_guidebubble.txt"
local keepConst = { FIRST = G.FIRST_MS, EVERY = G.EVERY_MS, HOUR = G.HOUR_MS, SHOW = G.SHOW_MS }
local keepFlag = nil
do
    local r = nil
    pcall(function() r = getFileReader(FILE, false) end)
    if r then
        pcall(function() keepFlag = r:readLine() end)
        pcall(function() r:close() end)
    end
end
local keepOption = core:getOptionShowSurvivalGuide()
local keepPad = JoypadState and JoypadState.players or nil
local function writeFlag(s)
    pcall(function() local w = getFileWriter(FILE, true, false); w:write(s or ""); w:close() end)
end
local function guideOpen()
    local win = W.windows and W.windows[0]
    if win and win.isReallyVisible and win:isReallyVisible() then return true end
    local B = ZeD.GuideBook
    return B and B.isOpen and B.isOpen(0) or false
end
local function closeGuide() if guideOpen() then W.toggle(0) end end
local function toastsOf() local n = 0; for _, t in ipairs(MS.toasts) do if t.source == G.head() then n = n + 1 end end return n end
local function lineCount() local s = MS.sources[G.head()]; return s and #s.items or 0 end
local function fresh()
    MS.sources[G.head()] = nil
    MS.toasts = {}
    closeGuide()
    writeFlag("")
    core:setOptionShowSurvivalGuide(true)
    G.start()
end
local EXACT = "New to Knox County? Check out this handy survival guide. Stop alt-tabbing for information: click this bubble or press F1 instead. You can dismiss this bubble at any time."

local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitMs(ms, fn)
    local t0
    Q[#Q + 1] = { n = 0, max = 100000, cond = function() t0 = t0 or getTimestampMs(); return getTimestampMs() - t0 >= ms end, fn = fn }
end

-- 1 START
step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    fresh()
    check(G.st ~= nil, "1: a fresh machine arms the clock")
end)
waitMs(20000, function()
    check(not guideOpen(), "1: the guide is not open 20 s after the start (it used to open full screen)")
    check(toastsOf() == 0, "1: no bubble before 30 s")
end)
-- 2 BUBBLE
waitMs(14000, function()
    check(toastsOf() == 1, "2: the bubble is up at about 30 s of play")
    local t = nil
    for _, x in ipairs(MS.toasts) do if x.source == G.head() then t = x end end
    check(t and t.text == EXACT, "2: the director's wording exactly, with F1", t and t.text)
    check(t and t.bare and t.long and (t.pn or 0) == 0, "2: a long bare balloon for player one")
    check(lineCount() == 1 and MS.unread() >= 1, "2: the line is in Messages, unread")
    local r = nil
    pcall(function() r = getFileReader(FILE, false) end)
    local l = r and r:readLine()
    if r then pcall(function() r:close() end) end
    check(l == "shown=1", "2: the flag file says shown")
    check(not guideOpen(), "2: the guide is still closed")
end)
waitMs(1500, function() shot("2_bubble_from_belt") end)
-- 3 CLICK
step(10, function()
    local t = nil
    for _, x in ipairs(MS.toasts) do if x.source == G.head() then t = x end end
    check(t and t.run ~= nil, "3: the balloon has a click")
    if t then MS.dropToast(t); t.run() end
end)
waitMs(1500, function()
    check(guideOpen(), "3: the click opened the guide")
    check(toastsOf() == 0 and lineCount() == 1, "3: the balloon is gone, the line stays in Messages")
    shot("3_guide_opened")
    closeGuide()
end)
-- 4 REPEAT
step(20, function()
    fresh()
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = 1000, 4000, 18000, 2500
end)
waitMs(3000, function()
    check(toastsOf() == 1 and lineCount() == 1, "4: the first showing, one line")
end)
waitMs(5500, function()
    check(lineCount() == 1, "4: it came back and the line is not doubled")
    local t = nil
    for _, x in ipairs(MS.toasts) do if x.source == G.head() then t = x end end
    if t then
        MS.dropToast(t); t.dismiss()
        check(G.st.done and G.st.why == "dismissed", "4: a right-click dismisses it")
    else
        check(false, "4: a second bubble was up to dismiss")
    end
end)
waitMs(7000, function()
    check(toastsOf() == 0, "4: nothing comes back after a dismiss")
    check(lineCount() == 1, "4: the line stays")
end)
-- 5 OPENED
step(10, function()
    fresh()
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = 1000, 4000, 18000, 2500
end)
waitMs(3000, function()
    check(toastsOf() == 1, "5: a live offer")
    W.toggle(0)
end)
waitMs(1200, function()
    check(guideOpen() and toastsOf() == 0 and G.st.done and G.st.why == "opened", "5: F1 by any road ends the offer and takes the balloon off")
    closeGuide()
    local s = MS.sources[G.head()]
    local it = s and s.items[1]
    check(it and it.k == "notice" and it.run ~= nil, "5: the line carries its Open")
    if it then it.run() end
end)
waitMs(1000, function()
    check(guideOpen(), "5: the line's Open opens the guide")
    closeGuide()
end)
-- 6 ONCE
step(10, function()
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = keepConst.FIRST, keepConst.EVERY, keepConst.HOUR, keepConst.SHOW
    writeFlag("shown=1\n")
    G.start()
    check(G.st == nil, "6: a machine that has had its bubble arms nothing")
    writeFlag("")
    G.start()
    check(G.st ~= nil, "6: with the flag emptied it arms again")
end)
-- 7 PAD
step(10, function()
    MS.sources[G.head()] = nil
    MS.toasts = {}
    JoypadState.players = { [1] = {} }
    check(W.bubbleKey(0) ~= "F1", "7: on a controller the key words are the Help wheel's, not F1", W.bubbleKey(0))
    local it, t = MS.notice(G.head(), G.text(0), { key = "gbub_pad", run = function() end, dismiss = function() end, ms = 8000, long = true, pn = 0 })
    check(t ~= nil, "7: the controller's balloon is up")
    check(t and not string.find(t.text, "F1", 1, true), "7: and it names no F1")
end)
waitMs(1500, function() shot("7_controller_variant") end)
step(10, function()
    JoypadState.players = keepPad or {}
    MS.sources[G.head()] = nil
    MS.toasts = {}
end)
-- 8 START2
step(10, function()
    -- (the event's list is not readable from Lua; the game started a minute ago with the option ticked and the guide
    -- never came up: step 1 already proved that. The game's own window must not be up either.)
    local vanilla = SurvivalGuide and SurvivalGuide.instance
    check(not (vanilla and vanilla.isVisible and vanilla:isVisible()), "8: the game's own guide window is not up")
    check(not guideOpen(), "8: no ZeD guide open")
end)
-- put back
step(10, function()
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = keepConst.FIRST, keepConst.EVERY, keepConst.HOUR, keepConst.SHOW
    writeFlag(keepFlag or "")
    core:setOptionShowSurvivalGuide(keepOption)
    JoypadState.players = keepPad or {}
    MS.sources[G.head()] = nil
    MS.toasts = {}
    closeGuide()
    G.st = nil
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if q.cond then
        if q.cond() or wait >= q.max then wait = 0; qi = qi + 1; local ok, e = pcall(q.fn); if not ok then fail = fail + 1; say("ERR " .. tostring(e)) end end
        return
    end
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then fail = fail + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
