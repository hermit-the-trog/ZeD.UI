-- ZeDUI/tools/qa/showcase_s2_map_light.lua  (Nov 19 2026, QA): the director's markup on description picture 2 ("take
-- it in light mode at the gas station, the Fossoil. So you can see the red highway and the gray neighborhood streets,
-- and ... the markers for like police, fire, school"). Run before showcase_s2.lua (showcase_s2_map_light.txt): only
-- the map section, Light theme, Survey style, centred on West Point's Fossoil (gallery_story_stage.lua's store,
-- 12052..12069 x 7117..7126), zoom 15.75, the World window wide. Picture: sc2_map_light.png. grep "ZEDQA s2l".
SC2_ONLY = { map = true }
SC2_MAPZOOM = 15.75
SC2_MAPWIDE = 0.62
SC2_MAPAT = { x = 12060, y = 7121, area = { 10800, 6000, 13400, 8300 } }
SC2_MAPLOOK = "light"
SC2_MAPNAME = "sc2_map_light"
print("ZEDQA s2l map only: the Fossoil 12060,7121, Light, zoom 15.75")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA s2l DONE") end
Events.OnTick.Add(later)
