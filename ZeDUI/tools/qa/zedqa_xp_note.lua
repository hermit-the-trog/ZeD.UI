-- ZeDUI/tools/qa/zedqa_xp_note.lua  (Nov 17 2026, QA): the game's floating "+XP" note over the head with ZeD on
-- (ZeD_HaloText.lua). Build's fix: a Java colour is matched by identity only, never probed, so no "Exception thrown"
-- from ZeD_HaloText in -debug. Gives skill XP a few times (two skills), takes a picture while the note is up, and
-- counts the errors the game's error box shows (the runner also reports Java exceptions in this script's window).
-- grep "ZEDQA xpn". Pictures Screenshots/zqa_xpn_*.png. Puts back: nothing lasting (the XP stays in the QA save copy).
local p = getPlayer()
local function say(s) print("ZEDQA xpn " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_xpn_" .. n .. ".png") end); say("shot zqa_xpn_" .. n) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = {}

local function give(perk, amt)
    -- (Nov 17 2026: B42 has no Perks.Carpentry; a nil perk makes the game throw inside AddXP)
    if perk == nil then say("AddXP skipped: that perk does not exist in this build"); return end
    local ok, err = pcall(function() p:getXp():AddXP(perk, amt) end)
    say("AddXP " .. tostring(perk) .. " " .. amt .. ": ok " .. tostring(ok) .. (ok and "" or (" " .. tostring(err))))
end

step(20, function() say("start"); give(Perks.Woodwork or Perks.Carpentry, 25) end)
step(20, function() shot("1_carpentry") end)
step(40, function() give(Perks.Cooking, 25) end)
step(20, function() shot("2_cooking") end)
step(40, function() give(Perks.Fitness, 15); give(Perks.Strength, 15) end)
step(20, function() shot("3_two_at_once") end)
step(120, function()
    say("the error box and the console's ZeD_HaloText exceptions are counted by the runner for this window")
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
