-- ZeD QA (Oct 29 2026): run before zedqa_dash_green.lua for the green cars at night alone (no D6 by day, no fire
-- pickup at speed). Sets ZeD_QA_DGR_GREEN_ONLY; zedqa_dash_green.lua reads it and clears it. grep "ZEDQA dgo".
-- (DONE on the next tick: the runner counts a DONE only after the bridge's own "run #" line for the bump)
ZeD_QA_DGR_GREEN_ONLY = true
if getGameSpeed() == 0 then setGameSpeed(1) end
local n = 0
local function tick()
    n = n + 1
    if n < 5 then return end
    Events.OnTick.Remove(tick)
    print("ZEDQA dgo green cars only for the next zedqa_dash_green.lua")
    print("ZEDQA dgo DONE")
end
Events.OnTick.Add(tick)
