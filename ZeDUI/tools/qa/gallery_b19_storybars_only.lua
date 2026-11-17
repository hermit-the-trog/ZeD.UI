-- ZeDUI/tools/qa/gallery_b19_storybars_only.lua  (Nov 17 2026, QA): the beta 19 gallery retake of story beats 04, 05, 09 and 11 only
-- (the action bars and moodle notes in the light style, e39286ea1). Run before gallery_story_stage.lua;
-- gallery_story_teardown.lua clears STORY_ONLY at its end. grep "ZEDQA sbar".
STORY_ONLY = { ["04"] = true, ["05"] = true, ["09"] = true, ["11"] = true }
print("ZEDQA sbar beats: 04 05 09 11")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA sbar DONE") end
Events.OnTick.Add(later)
