-- ZeDUI/tools/qa/b10_guide_open_repro.lua (Nov 8 2026, QA): opens the survival guide by ZeD.Guide.open(0), nothing else
-- (the beta 10 bubble check froze the game right after the bubble's click opened it). grep "ZEDQA gopen".
local function say(s) print("ZEDQA gopen " .. tostring(s)) end
local n, opened = 0, false
local function tick()
    n = n + 1
    if n == 20 and not opened then
        opened = true
        say("opening")
        ZeD.Guide.open(0)
        say("open returned")
    elseif n == 120 then
        say("still ticking at 120")
        pcall(function() ZeD.Guide.toggle(0) end)
    elseif n == 160 then
        say("DONE"); Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
