-- ZeDUI/tools/qa/zedqa_inv_cleanup.lua  (Nov 11 2026, QA): takes out of the QA character's bags what zedqa_animals_quick.lua's Feed step gave and left (Steak, Carrots), and any Bucket or
-- Sheep Shears its dropAll did not take. (zedqa_animals_quick.lua itself takes its first things away, the character's own Bucket and Shears too, and never gives them back.) grep "ZEDQA icl".
local function say(s) print("ZEDQA icl " .. s) end
local p = getPlayer()
local gone = {}
for _, ft in ipairs({ "Base.Steak", "Base.Carrots" }) do
    local list = p:getInventory():getAllTypeRecurse(ft)
    for k = list:size() - 1, 0, -1 do
        local it = list:get(k)
        local c = it:getContainer()
        if c then c:Remove(it); gone[ft] = (gone[ft] or 0) + 1 end
    end
end
for k, v in pairs(gone) do say("removed " .. v .. " x " .. k) end
local n = 0
local function later() n = n + 1; if n > 20 then Events.OnTick.Remove(later); say("DONE") end end
Events.OnTick.Add(later)
say("start")
