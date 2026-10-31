-- ZeDUI/tools/qa/gallery_t14_v3only.lua  (Oct 30 2026)
-- The t14 retake's sections of gallery_v3_zed.lua: run before it in gallery_t14_manifest.txt so it takes only the
-- sections the slides use (hero 1 + 19, tabs 20-23 + 25 + 27, hud 26, more 20 + 28 + 29, themes 45); car, settings and
-- strips are left out. gallery_v3_teardown.lua clears GAL_ONLY at its end. grep "ZEDQA g3o".
GAL_ONLY = { hero = true, tabs = true, hud = true, more = true, themes = true }
local keys = {}
for k in pairs(GAL_ONLY) do keys[#keys + 1] = k end
table.sort(keys)
print("ZEDQA g3o sections: " .. table.concat(keys, ", "))
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA g3o DONE") end
Events.OnTick.Add(later)
