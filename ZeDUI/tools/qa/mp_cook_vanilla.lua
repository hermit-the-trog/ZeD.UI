-- ZeDUI/tools/qa/mp_cook_vanilla.lua  (Nov 5 2026, QA; multiplayer): the same add as mp_cook.lua (a carrot into the pot
-- of water, the Stew recipe) through the game's own action, ISAddItemInRecipe, as its right-click menu queues it. Tells
-- whether the stopped add on a server is ZeD's (ZeD_CookAdd) or the game's. grep "ZEDQA mcv".
local function say(s) print("ZEDQA mcv " .. tostring(s)) end
local p = getPlayer()
local inv = p:getInventory()
local pot = inv:getFirstTypeRecurse("Pot")
local carrot = inv:getFirstTypeRecurse("Carrots")
local recipe
for i = 0, getEvolvedRecipes():size() - 1 do local r = getEvolvedRecipes():get(i); if r:getName() == "Stew" then recipe = r end end
say("pot " .. tostring(pot) .. ", carrot " .. tostring(carrot) .. ", recipe " .. tostring(recipe and recipe:getName()))
if not (pot and carrot and recipe) then say("DONE") return end
local a = ISAddItemInRecipe:new(p, recipe, pot, carrot)
local os, ost = a.stop, a.start
a.start = function(self) say("start"); return ost(self) end
a.stop = function(self) say("STOP"); return os(self) end
ISTimedActionQueue.add(a)
local n = 0
local function t()
    n = n + 1
    if n == 600 then
        Events.OnTick.Remove(t)
        local l = inv:getAllTypeRecurse("Base.PotOfStew")
        say("after: stews " .. l:size() .. ", pots " .. inv:getCountTypeRecurse("Base.Pot") .. ", carrots " .. inv:getCountTypeRecurse("Base.Carrots"))
        say("DONE")
    end
end
Events.OnTick.Add(t)
