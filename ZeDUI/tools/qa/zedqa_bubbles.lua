-- ZeDUI/tools/qa/zedqa_bubbles.lua  (Oct 24 2026)
-- The overhead bubbles (ZeD/ZeD_Bubbles.lua, handoff ZeDUI/HANDOFF_bubbles_20261024.md):
-- the speech balloon for what the character says (a short line, a long wrapping
-- line), the action bar's verbose layout in the thought bubble (a queue of eating),
-- speaking while acting (the balloon beside the thought), the balloon flipped left
-- at the screen's right edge, the three base themes, and k = 1 (ZeD scale forced to
-- 1.0) besides the run's own k = 2. Also checks the speech hook: after Say() the
-- engine's line is pushed out (getSayLine() reads "" again) and ours is up.
-- The camera keeps the character in the middle of the screen, so the right edge is
-- brought to the head for the flip shot by narrowing what getPlayerScreenWidth()
-- reports to the action bar layer for a moment (put back right after).
-- Captures: Zomboid/Screenshots/zqa_bub_<name>.png. grep "ZEDQA bub".
local TAG = "bub"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local B, AB = ZeD.Bubbles, ZeD.ActionBar
if not (B and AB and ZeD.applyTheme) then say("ERR ZeD bubbles not loaded"); return end
local pn = p:getPlayerNum()
local core = getCore()
local Sc = ZeD.Scale
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local inv = p:getInventory()
local given = {}
local function give(ft, n) local out = {}; for _ = 1, n do local it = inv:AddItem(ft); if it then given[#given + 1] = it; out[#out + 1] = it end end; return out end
local size = ZeD.currentSize
local realW = getPlayerScreenWidth

local function shot(name)
    local f = "zqa_bub_" .. name .. ".png"
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then say("shot " .. f .. " k=" .. tostring(AB.k())) else fails = fails + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
local function closePair()
    if CWm and WWm then
        if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
        else
            if CWm.isOpen() then CWm.toggle(0) end
            if WWm.isOpen() then WWm.close() end
        end
    end
end
local function stopAll() pcall(function() p:StopAllActionQueue() end) end
local function eat(n)
    for _, it in ipairs(give("Base.Apple", n)) do ISInventoryPaneContextMenu.eatItem(it, 0.25, pn) end
end
local function report(what)
    local okL, line = pcall(function() return p:getSayLine() end)
    local okS, spk = pcall(function() return p:isSpeaking() end)
    local sp = B._sp[pn]
    say(what .. ": getSayLine=" .. (okL and tostring(line) or "(error)") .. " isSpeaking=" .. (okS and tostring(spk) or "(error)")
        .. " balloon=" .. tostring(sp and sp.text) .. " lines=" .. tostring(sp and #sp.lines))
end

local Q, qi, wait = {}, 1, nil
local lastHalf = nil      -- the speaking half B.current measured (kept after the balloon goes)
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- 1. a short line and a long one, dark theme
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    closePair(); stopAll()
    ZeD.applyTheme("dark", "orange", size)
end)
step(60, function() p:Say("Ahh. That's the stuff.") end)
step(2, function()
    report("after Say")
    local okL, line = pcall(function() return p:getSayLine() end)
    check(okL and (line == nil or line == ""), "the engine's line is pushed out (getSayLine reads empty)")
    check(B._sp[pn] and B._sp[pn].text == "AHH. THAT'S THE STUFF.", "the balloon has the line in capitals")
end)
step(30, function() shot("speech_dark") end)
step(150, function()
    report("2.5 s on")
    check(B._sp[pn] ~= nil, "the balloon is still up 2.5 s on")
end)
step(360, function()
    local sp0 = B._sp[pn]
    report("8.5 s on")
    say("the engine's speaking half: " .. tostring(sp0 and sp0.half or lastHalf) .. " ms")
    check(B._sp[pn] == nil, "the balloon is gone by 8.5 s (the engine shows a line for twice its speaking half)")
    p:Say("Is anyone out there? I have food, water and a working radio, and I am not going anywhere.")
end)
step(30, function()
    local sp = B._sp[pn]
    check(sp and #sp.lines >= 2, "a long line wraps (" .. tostring(sp and #sp.lines) .. " lines)")
    shot("long_dark")
end)
-- 2. the thought bubble, then speaking while acting, then the flip
step(280, function() eat(3) end)
step(90, function() report("eating"); shot("thought_dark") end)
step(5, function() p:Say("Don't even think about it.") end)
step(30, function() shot("both_dark") end)
step(5, function()
    local hx = AB.headScreen(pn, p)
    local left = getPlayerScreenLeft(pn)
    getPlayerScreenWidth = function(n) if n == pn then return math.floor(hx + 0.5) + 60 * AB.k() - left end; return realW(n) end
end)
step(3, function()
    shot("both_flip_dark")
    getPlayerScreenWidth = realW
    local L = AB._layers[pn] and AB._layers[pn]._lay
    check(L and L.sx and L.tx and L.sx < L.tx, "near the right edge the balloon goes left of the thought bubble")
end)
-- 3. the light and high-contrast themes: thought + speech, then speech alone
for _, t in ipairs({ { "light", "blue" }, { "hicon", "teal" } }) do
    step(10, function() getPlayerScreenWidth = realW; stopAll(); ZeD.applyTheme(t[1], t[2], size) end)
    step(60, function() eat(2) end)
    step(90, function() p:Say("Don't even think about it.") end)
    step(30, function() shot("both_" .. t[1]) end)
    step(5, function() stopAll() end)
    step(60, function() p:Say("Ahh. That's the stuff.") end)
    step(30, function() shot("speech_" .. t[1]) end)
    step(300, function() end)
end
-- 4. k = 1 (the ZeD scale forced to 1.0), dark
step(10, function()
    stopAll()
    Sc.override = 1.0; Sc.refresh(); ZeD.applyTheme("dark", "orange", size)
end)
step(60, function() say("k now " .. tostring(AB.k())); check(AB.k() == 1, "k = 1 at ZeD scale 1.0"); eat(2) end)
step(90, function() p:Say("Don't even think about it.") end)
step(30, function() shot("both_k1") end)
step(5, function() stopAll() end)
step(60, function() p:Say("Is anyone out there? I have food, water and a working radio, and I am not going anywhere.") end)
step(30, function() shot("long_k1") end)
-- 5. put everything back
step(10, function()
    getPlayerScreenWidth = realW
    stopAll()
    Sc.override = nil; Sc.refresh()
    pcall(ZeD.Settings.reapplyFromOptions)
end)
step(30, function()
    for _, it in ipairs(given) do
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        if it:getContainer() then it:getContainer():Remove(it) end
    end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock, whatever the frame rate)
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    local now = getTimestampMs()
    local s0 = B._sp[pn]; if s0 and s0.half then lastHalf = s0.half end
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; getPlayerScreenWidth = realW; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
