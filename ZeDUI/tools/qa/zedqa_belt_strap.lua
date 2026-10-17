-- ZeD QA (Oct 16 2026): the pixel-art belt strap. Screenshots the belt, and again with a fourth slot filled if the
-- hotbar has one (a longer strap).
local function say(s) print("ZEDQA belt " .. tostring(s)) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
at(5, function() setGameSpeed(1); say("textures " .. tostring(getTexture("media/textures/ZeD/belt/strap_mid.png") ~= nil)) end)
at(30, function() pcall(function() getCore():TakeFullScreenshot("zqa_belt_strap_1.png") end); say("shot; DONE") end)
local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
