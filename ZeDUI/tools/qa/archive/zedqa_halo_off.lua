-- ZeDUI/tools/qa/zedqa_halo_off.lua  (Nov 4 2026, QA): Overhead notes switched off for the scripts after it (the
-- default and the Vanilla preset), so the game's own lines pass through ZeD's wrappers. grep "ZEDQA hof".
local o = ZeD.Settings.haloBubbleOption
print("ZEDQA hof start")
o:setValue(1)
print("ZEDQA hof Overhead notes on: " .. tostring(ZeD.Settings.haloBubbleOn()))
local n = 0
local function t() n = n + 1; if n == 20 then Events.OnTick.Remove(t); print("ZEDQA hof DONE") end end
Events.OnTick.Add(t)
