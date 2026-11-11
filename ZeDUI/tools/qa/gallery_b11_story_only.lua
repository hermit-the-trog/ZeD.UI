-- ZeDUI/tools/qa/gallery_b11_story_only.lua  (Nov 11 2026, a copy of gallery_story_only.lua)
-- Retakes of single story beats: run before gallery_story_stage.lua in a manifest so
-- gallery_story_shots.lua takes only these beats (its STORY_ONLY). Edit the list for the
-- beats wanted; gallery_story_teardown.lua clears it at its end. grep "ZEDQA sto".
STORY_ONLY = { ["09"] = true, ["10"] = true, ["11"] = true }   -- Nov 11 2026 (beta 11 retake: beats 9-11 in Teal, not the blue windows beat 8 left)   -- Oct 28 2026 (0.2.0-t8): the tire install with an Old tire as the spare
local keys = {}
for k in pairs(STORY_ONLY) do keys[#keys + 1] = k end
table.sort(keys)
print("ZEDQA sto beats: " .. table.concat(keys, ", "))
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA sto DONE") end
Events.OnTick.Add(later)

