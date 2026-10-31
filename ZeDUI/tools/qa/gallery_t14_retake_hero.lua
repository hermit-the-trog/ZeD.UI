-- ZeDUI/tools/qa/gallery_t14_retake_hero.lua  (Oct 31 2026)
-- gallery_t14_retake_manifest.txt: run before gallery_v3_zed.lua so it takes only its hero section, which holds
-- zed_13_crafting (slide 20's LIST picture, now set to List before the shot). gallery_v3_teardown.lua clears
-- GAL_ONLY at its end. grep "ZEDQA g3h".
GAL_ONLY = { hero = true }
print("ZEDQA g3h sections: hero")
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA g3h DONE") end
Events.OnTick.Add(later)
