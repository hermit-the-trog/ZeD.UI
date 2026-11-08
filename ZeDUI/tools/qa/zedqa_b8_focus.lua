-- ZeDUI/tools/qa/zedqa_b8_focus.lua  (Nov 8 2026, QA; punch list 109, CHECK_alt_tab_gaps_20261107.md part 3)
-- The game's Pause on Focus Loss (Options > Display, options.ini focusloss; getCore():getOptionPauseOnFocusloss) pauses
-- only while the speed controls are "really visible" (IngameState.onDisplayFocusLost, 42.21). ZeD parks them off screen
-- but must keep their visible flag on in single player. Read in the live game:
--   * single player (not a server's client); the option reads, and is switched On and Off by hand
--   * with it On, then Off, over many frames: the speed controls stay visible = true and parked (Y below 0, never drawn),
--     the clock stays parked; the watch (if the character wears one) keeps drawing
--   * the game's option itself is untouched by ZeD (it reads what was set)
--   * the watch's "screen switch" (ZeD setup > Safe mode > Watch) On: the speed controls come back on screen, Off: parked
--     again and still visible = true
-- Manual (a script cannot alt-tab): the pause on a real alt-tab with the option On, no pause with it Off, the watch /
-- speed keys reading paused, alt-tab back still paused; multiplayer (nothing pauses, controls hidden); the whole Safe
-- mode toggle. Puts back: the option, the watch switch. grep "ZEDQA b8fo".
local TAG = "b8fo"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end; return ok end
local core = getCore()
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = { was = {} }

local function readOpt() local ok, v = pcall(function() return core:getOptionPauseOnFocusloss() end); if ok then return v end; return nil end
local function setOpt(v) return pcall(function() core:setOptionPauseOnFocusloss(v) end) end
local function sc() return UIManager.getSpeedControls and UIManager.getSpeedControls() end
local function clock() return UIManager.getClock and UIManager.getClock() end
local function state()
    local s, c = sc(), clock()
    return string.format("speed controls: visible %s, y %s; clock: visible %s, y %s", tostring(s and s:isVisible()), tostring(s and s:getY()),
        tostring(c and c:isVisible()), tostring(c and c:getY()))
end
local function parkedOk()
    local s = sc()
    return s ~= nil and s:isVisible() == true and s:getY() < 0
end

-- read for N frames: any frame with the flag off or the controls on screen is a failure
local function watchFrames(label, frames)
    S.bad, S.seen = 0, 0
    S.until_, S.label = frames, label
end
local function onFrame()
    if not S.until_ or S.until_ <= 0 then return end
    S.until_ = S.until_ - 1
    S.seen = S.seen + 1
    if not parkedOk() then S.bad = S.bad + 1; S.firstBad = S.firstBad or state() end
end
local function report()
    check(S.bad == 0, S.label .. ": the speed controls stayed visible = true and parked over " .. S.seen .. " frames" .. (S.bad > 0 and (" (" .. S.bad .. " frames not; first: " .. tostring(S.firstBad) .. ")") or ""))
    S.firstBad = nil
end

step(20, function()
    check(not (isClient and isClient()), "single player (not a server's client)")
    S.was.opt = readOpt()
    say("the game's Pause on Focus Loss reads: " .. tostring(S.was.opt))
    check(S.was.opt ~= nil, "getOptionPauseOnFocusloss is readable")
    check(sc() ~= nil, "the game has speed controls")
    say(state())
    S.was.watch = ZeD.Settings.screenOptions and ZeD.Settings.screenOptions.watch and ZeD.Settings.screenOptions.watch:getValue()
    say("the watch screen switch reads item " .. tostring(S.was.watch) .. " (1 = ZeD's)")
    say("a watch is installed: " .. tostring(ZeD_Watch and ZeD_Watch.getInstance and ZeD_Watch.getInstance() ~= nil))
end)
-- the option On
step(5, function()
    local ok = setOpt(true)
    check(ok and readOpt() == true, "Pause on Focus Loss set On by hand")
    watchFrames("option On", 90)
end)
step(100, function() report() end)
-- the option Off
step(5, function()
    local ok = setOpt(false)
    check(ok and readOpt() == false, "Pause on Focus Loss set Off by hand")
    watchFrames("option Off", 90)
end)
step(100, function()
    report()
    -- ZeD never writes the option
    check(readOpt() == false, "ZeD left the option as set (Off)")
    setOpt(true)
end)
step(60, function()
    check(readOpt() == true, "ZeD left the option as set (On)")
    watchFrames("option On again", 60)
end)
step(70, function() report() end)
-- the watch's screen switch (Safe mode > Watch): handed to the game's own, then ZeD's again
step(5, function()
    local o = ZeD.Settings.screenOptions and ZeD.Settings.screenOptions.watch
    if not o then check(false, "the watch screen switch is readable"); return end
    pcall(function() o:setValue(2) end)
    pcall(function() ZeD.Safe.reread() end)
    say("watch switch On (the game's own): " .. state())
end)
step(60, function()
    local s = sc()
    say("a second later: " .. state())
    check(s ~= nil and s:isVisible() == true and s:getY() >= 0, "watch handed back: the speed controls are on screen again (y " .. tostring(s and s:getY()) .. ")")
    local o = ZeD.Settings.screenOptions.watch
    pcall(function() o:setValue(S.was.watch or 1) end)
    pcall(function() ZeD.Safe.reread() end)
end)
step(90, function()
    say("after taking the watch back: " .. state())
    check(parkedOk(), "watch taken back: the speed controls parked again, flag still on")
end)
step(10, function()
    if S.was.opt ~= nil then setOpt(S.was.opt) end
    check(readOpt() == S.was.opt, "the game's option is back at " .. tostring(S.was.opt))
    say(pass .. " passed, " .. fail .. " failed")
    say("DONE")
end)

local function tick()
    onFrame()
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
