-- ZeDUI/tools/qa/gallery_t14_retake_tabs.lua  (Oct 31 2026, QA)
-- gallery_t14_retake_manifest.txt: run before gallery_v3_zed.lua so it takes only its tabs section, which holds
-- zed_13_crafting (slide 20's LIST picture, now set to List before the shot). gallery_v3_teardown.lua clears
-- GAL_ONLY at its end. grep "ZEDQA g3tb".
GAL_ONLY = { tabs = true }
print("ZEDQA g3tb sections: tabs")
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA g3tb DONE") end
Events.OnTick.Add(later)
