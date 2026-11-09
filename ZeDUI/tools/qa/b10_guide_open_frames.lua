-- ZeDUI/tools/qa/b10_guide_open_frames.lua (Nov 8 2026, Build): opens the survival guide by its three roads and counts
-- the frames drawn while it is open. grep "ZEDQA gframes". Runs on OnRenderTick: the open guide pauses the game, and
-- OnTick stops while paused (why b10_guide_open_repro.lua, on OnTick, timed out with the game still drawing).
--   for each road (ZeD.Guide.open(0), the guide bubble's click, F1 by ZeD.Guide.toggle):
--     PASS the guide is open and the game paused; 120 frames drawn with it open, the average frame under 100 ms
--     (the time printed); then F1 closes it and the game plays again
-- Picture zqa_gframes_<w>x<h>_<road>.png of the open book. Put back: the guide closed, the bubble's offer as it was.
local function say(s) print("ZEDQA gframes " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local W, G = ZeD.Guide, ZeD.GuideBubble
if not W then say("ERR the guide is not loaded"); say("DONE"); return end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local function guideOpen()
    local win = W.windows and W.windows[0]
    if win and win.isReallyVisible and win:isReallyVisible() then return true end
    local B = ZeD.GuideBook
    return (B and B.isOpen and B.isOpen(0)) and true or false
end
local keepSt = G and G.st or nil

local ROADS = {
    { id = "open", fn = function() W.open(0) end },
    { id = "bubble", fn = function()
        if not G then W.open(0); return end
        -- (a live offer, as the balloon's click finds it; the machine's once-ever flag file left as it is)
        local keepMark = G.markShown
        G.markShown = function() end
        G.st = { shows = 1 }
        local ok, err = pcall(G.open)
        G.markShown = keepMark
        if not ok then error(err) end
    end },
    { id = "f1", fn = function() W.toggle(0) end },
}
local ri, n, t0, phase = 1, 0, nil, "settle"
local function tick()
    local r = ROADS[ri]
    if not r then
        if G then G.st = keepSt end
        if guideOpen() then W.toggle(0) end
        say(string.format("RESULT %d pass, %d fail", pass, fail))
        say("DONE")
        Events.OnRenderTick.Remove(tick)
        return
    end
    n = n + 1
    if phase == "settle" then
        if n < 20 then return end
        if guideOpen() then W.toggle(0) end
        if getGameSpeed() <= 0 then setGameSpeed(1) end
        say(r.id .. ": opening")
        local ok, err = pcall(r.fn)
        check(ok, r.id .. ": the open returns" .. (ok and "" or (" (" .. tostring(err) .. ")")))
        check(getGameSpeed() == 0, r.id .. ": the game is paused while it is open")
        phase, n, t0 = "count", 0, getTimestampMs()
        return
    end
    if phase == "count" then
        -- (the window shows on the frame after the open, so "open" is read a couple of frames in)
        if n == 2 then check(guideOpen(), r.id .. ": the guide is open") end
        if n == 60 then pcall(function() core:TakeFullScreenshot("zqa_gframes_" .. sw .. "x" .. sh .. "_" .. r.id .. ".png") end) end
        if n < 120 then return end
        local ms = getTimestampMs() - t0
        local avg = ms / 120
        say(string.format("%s: 120 frames with the guide open in %d ms (%.1f ms a frame)", r.id, ms, avg))
        check(guideOpen(), r.id .. ": still open after 120 frames")
        check(avg < 100, r.id .. ": the average frame is under 100 ms")
        W.toggle(0)
        check(not guideOpen(), r.id .. ": F1 closes it")
        check(getGameSpeed() > 0, r.id .. ": the game plays again")
        ri, n, phase = ri + 1, 0, "settle"
    end
end
Events.OnRenderTick.Add(tick)
say("start")
