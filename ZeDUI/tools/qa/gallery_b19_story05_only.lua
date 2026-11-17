-- ZeDUI/tools/qa/gallery_b19_story05_only.lua  (Nov 17 2026, QA): the beta 19 gallery retake of story beat 05 only
-- (story_05a_barricade_menu: the window's context strip with the round 1b icons). Run before gallery_story_stage.lua;
-- gallery_story_teardown.lua clears STORY_ONLY at its end. grep "ZEDQA s05".
STORY_ONLY = { ["05"] = true }
print("ZEDQA s05 beats: 05")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA s05 DONE") end
Events.OnTick.Add(later)
