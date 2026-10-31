-- ZeDUI/tools/qa/gallery_t14_retake_tvs.lua  (Oct 31 2026)
-- gallery_t14_retake_manifest.txt: run before gallery_t14_indoor.lua so it takes only its TV section (slide 58).
-- gallery_t14_indoor.lua clears GAL14_ONLY at its end. grep "ZEDQA g14v".
GAL14_ONLY = { tvs = true }
print("ZEDQA g14v sections: tvs")
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA g14v DONE") end
Events.OnTick.Add(later)
