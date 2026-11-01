-- ZeDUI/tools/qa/zedqa_picks_large.lua  (Oct 31 2026, QA): run before zedqa_picks_check.lua for Large text.
ZEDQA_PICK_TEXT = "large"
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA pkl DONE") end
Events.OnTick.Add(later)
