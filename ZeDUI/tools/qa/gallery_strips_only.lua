-- ZeDUI/tools/qa/gallery_strips_only.lua  (Oct 30 2026)
-- Punch list 21's clean capture: run before gallery_v3_zed.lua so it takes only its "strips"
-- section, in the director's own theme (GAL_KEEP_THEME). gallery_v3_teardown.lua clears
-- GAL_ONLY at its end. grep "ZEDQA gso".
GAL_ONLY = { strips = true }
GAL_KEEP_THEME = true
print("ZEDQA gso sections: strips, own theme")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA gso DONE") end
Events.OnTick.Add(later)
