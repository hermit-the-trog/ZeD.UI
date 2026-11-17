-- ZeDUI/tools/qa/gallery_b19_a2.lua  (Nov 17 2026, QA): run right before gallery_b19_a.lua at the mall lot so it takes
-- only the hero (zed_01_hero_mid with the apple stack open). gallery_b19_a.lua clears the flag. grep "ZEDQA gb19o".
GB19A_ONLY = { hero = true }
print("ZEDQA gb19o sections: hero")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA gb19o DONE") end
Events.OnTick.Add(later)
