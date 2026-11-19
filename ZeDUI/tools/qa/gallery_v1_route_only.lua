-- ZeDUI/tools/qa/gallery_v1_route_only.lua  (Nov 18 2026, QA): the 1.0 gallery's chapter 34 "The Route" retake only
-- (story_03_route_map, story_03b_route_note) on beta 20's revised Survey map. Run before gallery_nov1_story.lua
-- (gallery_v1_route.txt): it takes only beat 03. grep "ZEDQA rto".
NOV1_STORY_ONLY = { ["03"] = true }
print("ZEDQA rto beats: 03")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA rto DONE") end
Events.OnTick.Add(later)
