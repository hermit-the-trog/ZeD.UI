-- ZeDUI/tools/qa/gallery_v3_only.lua  (Oct 25 2026)
-- Retakes of some gallery v3 sections: run before gallery_v3_zed.lua in a manifest so it
-- takes only these (its GAL_ONLY). Edit the list for the sections wanted;
-- gallery_v3_teardown.lua clears it at its end. grep "ZEDQA g3o".
GAL_ONLY = { hero = true }   -- Oct 25 2026: the belt's hands swapped ends
local keys = {}
for k in pairs(GAL_ONLY) do keys[#keys + 1] = k end
table.sort(keys)
print("ZEDQA g3o sections: " .. table.concat(keys, ", "))
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA g3o DONE") end
Events.OnTick.Add(later)
