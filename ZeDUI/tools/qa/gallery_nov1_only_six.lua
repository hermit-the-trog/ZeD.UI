-- gallery_nov1_only_six.lua (Nov 1 2026, QA): the lot sections health and furniture, and story beat 02, for the six captures done again.
NOV1_ONLY = { health = true, furniture = true }
NOV1_STORY_ONLY = { ["02"] = true }
print("ZEDQA n1o6 sections: health, furniture; story 02")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA n1o6 DONE") end
Events.OnTick.Add(later)
