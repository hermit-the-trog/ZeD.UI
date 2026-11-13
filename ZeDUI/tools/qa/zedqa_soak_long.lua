-- ZeDUI/tools/qa/zedqa_soak_long.lua  (Nov 12 2026, test cleanup): once per release, right before zedqa_soak.lua,
-- makes that script's next run the long one (12 rounds, 10 to 13 minutes). zedqa_soak.lua clears the flag as it
-- starts, so only the next run is long. Manifest: "zedqa_soak_long.lua | soaklong", then
-- "zedqa_soak.lua | soak | timeout=2700". grep "ZEDQA soaklong".
ZEDQA_SOAK_ROUNDS = 12
print("ZEDQA soaklong the next zedqa_soak.lua runs " .. ZEDQA_SOAK_ROUNDS .. " rounds")
local n = 0
local function t() n = n + 1; if n == 20 then Events.OnTick.Remove(t); print("ZEDQA soaklong DONE") end end
Events.OnTick.Add(t)
