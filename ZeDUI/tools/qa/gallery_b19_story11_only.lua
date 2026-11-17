-- ZeDUI/tools/qa/gallery_b19_story11_only.lua  (Nov 17 2026, QA): the beta 19 gallery retake of story beat 11 only
-- (story_11_smoke_break: the moodle balloon in the light style, beta 16). Run before gallery_story_stage.lua;
-- gallery_story_teardown.lua clears STORY_ONLY at its end. grep "ZEDQA s11".
STORY_ONLY = { ["11"] = true }
print("ZEDQA s11 beats: 11")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA s11 DONE") end
Events.OnTick.Add(later)
