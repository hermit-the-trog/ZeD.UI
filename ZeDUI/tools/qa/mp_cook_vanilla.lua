-- ZeDUI/tools/qa/mp_cook_vanilla.lua  (Nov 5 2026, QA; multiplayer): the same add as mp_cook.lua (a carrot into the pot
-- of water, the Stew recipe) through the game's own action, ISAddItemInRecipe, as its right-click menu queues it. Tells
-- whether the stopped add on a server is ZeD's (ZeD_CookAdd) or the game's. grep "ZEDQA mcv".
local function say(s) print("ZEDQA mcv " .. tostring(s)) end
local p = getPlayer()
pcall(function() p:setGodMod(true); sendPlayerExtraInfo(p) end)   -- (the test character lingers on the server)
local inv = p:getInventory()
local pot = inv:getFirstTypeRecurse("Pot")
local carrot = inv:getFirstTypeRecurse("Carrots")
local recipe
local names = {}
for i = 0, getEvolvedRecipes():size() - 1 do
    local r = getEvolvedRecipes():get(i)
    local n1, n2 = tostring(r:getName()), ""
    pcall(function() n2 = tostring(r:getOriginalname()) end)
    if #names < 6 then names[#names + 1] = n1 .. "/" .. n2 end
    if n1 == "Stew" or n2 == "Stew" or n1:lower():find("stew") then recipe = recipe or r end
end
say("some recipe names: " .. table.concat(names, ", "))
say("pot " .. tostring(pot) .. ", carrot " .. tostring(carrot) .. ", recipe " .. tostring(recipe and recipe:getName()))
if not (pot and carrot and recipe) then
    local n0 = 0
    local function t0() n0 = n0 + 1; if n0 == 20 then Events.OnTick.Remove(t0); say("DONE") end end
    Events.OnTick.Add(t0)
    return
end
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
