-- ZeDUI/tools/qa/showcase_s2_retake_only.lua  (Nov 18 2026, QA): Build's slot 2 retakes only: sc2_map wider and
-- closer, sc2_dash / sc2_dash_radio at dusk. Run before showcase_s2.lua (showcase_s2_retake.txt). grep "ZEDQA s2r".
SC2_ONLY = { map = true }   -- (the director, Nov 18: keep the night dash shot)
SC2_DASH_HOUR = 19.5     -- dusk: the street still lit
SC2_MAPZOOM = 15.5       -- shields, place symbols and town names read
SC2_MAPWIDE = 0.62       -- the World window's width as a share of the screen, for the map shot
print("ZEDQA s2r map only; zoom 15.5, World window 0.62 of the screen")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA s2r DONE") end
Events.OnTick.Add(later)
