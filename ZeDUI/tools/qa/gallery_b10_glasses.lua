-- ZeDUI/tools/qa/gallery_b10_glasses.lua  (Nov 9 2026, QA)
-- The QA character is short-sighted: the game blurs the world past a short distance unless prescription glasses are
-- worn (zedqa_eyesight.lua, Oct 25). The full gallery run gets them from gallery_v3_stage.lua; the short reruns
-- (moodles, notebook) skip that staging, so this puts a pair on. Stays on; the game quits after the run. grep "ZEDQA gls".
local p = getPlayer()
local function say(s) print("ZEDQA gls " .. tostring(s)) end
local g = p:getInventory():AddItem("Base.Glasses_Prescription")
if g then
    p:setWornItem(g:getBodyLocation(), g)
    say("wearing " .. tostring(p:getWornItem(g:getBodyLocation()) and p:getWornItem(g:getBodyLocation()):getFullType()))
else say("ERR no glasses item") end
local n = 0
local function later() n = n + 1; if n < 90 then return end; Events.OnTick.Remove(later); say("DONE") end
Events.OnTick.Add(later)
