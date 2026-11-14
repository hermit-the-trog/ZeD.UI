-- ZeDUI/tools/qa/zedqa_farm_troughs.lua  (Nov 13 2026, QA): the farm spot BY the troughs, for one look at the Animals zone
-- page with many troughs (Build's scroll fix, "Animals zone page"). Stands the character at the director's first pick
-- beside the barn (1625,14221), where a 17 x 17 zone takes in the farm's eight troughs; run zedqa_animals_quick_more.lua
-- after it and read its band pictures (zqa_aq2_1_band_normal, 5_pad_run: the trough list must end above the band).
-- grep "ZEDQA ftr".
local function say(s) print("ZEDQA ftr " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
pcall(function() local car = p:getVehicle(); if car then car:exit(p); triggerEvent("OnExitVehicle", p) end end)
p:setX(1625.5); p:setY(14221.5); p:setZ(0); p:setLastX(1625.5); p:setLastY(14221.5); p:setLastZ(0)
pcall(function() local gt = getGameTime(); local h = gt:getTimeOfDay(); if h < 8 or h > 17 then gt:setTimeOfDay(11.0) end end)
local n = 0
local function wait()
    n = n + 1
    if n < 300 then return end
    Events.OnRenderTick.Remove(wait)
    say("at 1625,14221 by the troughs")
    say("DONE")
end
Events.OnRenderTick.Add(wait)
