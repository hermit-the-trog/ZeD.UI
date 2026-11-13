-- ZeDUI/tools/qa/zedqa_dash_one.lua  (Nov 12 2026, test cleanup): the smoke run's one car. Run right before
-- zedqa_dashpx.lua, it makes that script's next run take one car from the 19-car pass (the Nyala, the plain sedan):
-- spawn on the strip, get in, key in, engine on, the dash drawn; about 10 seconds instead of two minutes.
-- zedqa_dashpx.lua clears the flag as it starts, so only the next run is short. grep "ZEDQA dashone".
ZEDQA_DASH_ONE = "02_nyala"
print("ZEDQA dashone the next zedqa_dashpx.lua runs one car: " .. ZEDQA_DASH_ONE)
local n = 0
local function t() n = n + 1; if n == 20 then Events.OnTick.Remove(t); print("ZEDQA dashone DONE") end end
Events.OnTick.Add(t)
