-- ZeD QA suite: ItemCard header verbs through the real dispatch (S123, passed on 42.20.2)
-- Spawns a book, bat and apple; fires each verb on a temporary card; checks queue + context.
local p = getPlayer()
local inv = p:getInventory()
local function hand(it) return it and it:getDisplayName() or "nil" end
local function qhead() local q = ISTimedActionQueue.getTimedActionQueue(p); local a = q and q.queue and q.queue[1]; return a and tostring(a.Type) or "none" end
local function clearQueue() local q = ISTimedActionQueue.getTimedActionQueue(p); if q and q.clearQueue then pcall(q.clearQueue, q) end end
local function card(item, ctx) local c = ZeD_ItemCard:new(0, 0, 220, 300, "drawer", 0); c:initialise(); c.item = item; c.playerNum = 0; c.sourceContext = ctx; return c end
local function fire(c, verb) local ok, err = pcall(c._dispatchHeaderVerb, c, verb); print("ZEDQA fire " .. verb .. " ok=" .. tostring(ok) .. " err=" .. tostring(err) .. " qhead=" .. qhead()) end
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local book, bat, apple = inv:AddItem("Base.Book"), inv:AddItem("Base.BaseballBat"), inv:AddItem("Base.Apple")
local worn = nil
do local items = inv:getItems(); for i = 0, items:size() - 1 do local it = items:get(i); if instanceof(it, "Clothing") and p:isEquipped(it) then worn = it; break end end end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
if worn then
    at(10,  function() print("ZEDQA worn=" .. hand(worn) .. " ctx=" .. card(worn, "equipped"):_effectiveContext()); fire(card(worn, "equipped"), "UNEQUIP") end)
    at(250, function() print("ZEDQA after UNEQUIP pEq=" .. tostring(p:isEquipped(worn)) .. " ctx=" .. card(worn, "equipped"):_effectiveContext() .. " (expect inventory)"); fire(card(worn, "inventory"), "EQUIP") end)
    at(490, function() print("ZEDQA after EQUIP pEq=" .. tostring(p:isEquipped(worn)) .. " ctx=" .. card(worn, "inventory"):_effectiveContext() .. " (expect equipped)") end)
end
at(500, function() fire(card(book, "inventory"), "READ") end)
at(560, function() print("ZEDQA after READ qhead=" .. qhead() .. " (expect ISReadABook)"); clearQueue() end)
at(620, function() fire(card(bat, "inventory"), "EQUIP") end)
at(860, function() print("ZEDQA after EQUIP bat primary=" .. hand(p:getPrimaryHandItem()) .. " ctx=" .. card(bat, "inventory"):_effectiveContext() .. " (expect equipped)"); fire(card(bat, "equipped"), "UNEQUIP") end)
at(1100, function() print("ZEDQA after UNEQUIP bat primary=" .. hand(p:getPrimaryHandItem()) .. " (expect nil)"); fire(card(apple, "inventory"), "EAT") end)
at(1160, function() print("ZEDQA after EAT qhead=" .. qhead() .. " (expect ISEatFoodAction)"); clearQueue() end)
at(1230, function() fire(card(apple, "inventory"), "DROP") end)
at(1410, function() print("ZEDQA after DROP cont=" .. tostring(apple:getContainer() and apple:getContainer():getType()) .. " ctx=" .. card(apple, "inventory"):_effectiveContext() .. " (expect floor/ground)"); fire(card(apple, "ground"), "TAKE") end)
at(1600, function() print("ZEDQA after TAKE inInv=" .. tostring(inv:contains(apple)) .. " ctx=" .. card(apple, "ground"):_effectiveContext() .. " (expect inventory)"); print("ZEDQA verbs done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, err = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(err)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA verbs armed")
