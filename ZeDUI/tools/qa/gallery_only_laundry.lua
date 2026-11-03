-- ZeDUI/tools/qa/gallery_only_laundry.lua  (Nov 2 2026, QA): gallery_t14_indoor.lua takes only its laundry section this run
GAL14_ONLY = { laundry = true }
print("ZEDQA gol GAL14_ONLY laundry")
local n = 0
local function tick() n = n + 1; if n >= 5 then Events.OnTick.Remove(tick); print("ZEDQA gol DONE") end end
Events.OnTick.Add(tick)
