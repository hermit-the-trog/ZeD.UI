-- ZeDUI/tools/qa/gallery_farm_pre.lua  (Nov 5 2026, QA): the pasture for zedqa_animals.lua: one big zone over the yard and the grass.
ZEDQA_ZONE = { "Home Pasture", -4, -16, 22, 8 }; ZEDQA_NO_DEAD_COW = true
print("ZEDQA gfp set")
local n = 0; local function t() n = n + 1; if n == 30 then Events.OnTick.Remove(t); print("ZEDQA gfp DONE") end end; Events.OnTick.Add(t)
