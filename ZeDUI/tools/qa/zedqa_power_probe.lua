-- ZeDUI/tools/qa/zedqa_power_probe.lua  (Oct 30 2026, QA)
-- Prints the save's grid power: the sandbox's ElecShutModifier, the world's hydro flag, and whether the
-- character's square has grid power. Run first and last in a manifest (two tags) to see that tests which
-- raise them for a run put them back. grep "ZEDQA pw".
local p = getPlayer()
local so = getSandboxOptions()
local o = so and so:getOptionByName("ElecShutModifier")
local sq = p and p:getCurrentSquare()
local grid = false
pcall(function() grid = sq:haveElectricity() end)
local days = -1
pcall(function() days = getGameTime():getNightsSurvived() end)
print(string.format("ZEDQA pw ElecShutModifier %s | hydro on %s | the character's square has grid power %s | nights survived %s",
    tostring(o and o:getValue()), tostring(getWorld():isHydroPowerOn()), tostring(grid), tostring(days)))
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA pw DONE") end
Events.OnTick.Add(later)
