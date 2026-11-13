-- ZeD QA suite: ItemCard header verbs through the real dispatch (S123, passed on 42.20.2)
-- Spawns a book, bat and apple; fires each verb on a temporary card; checks queue + context.
-- Nov 12 2026 (test cleanup): the "(expect ...)" prints are real checks now ("ZEDQA verbs PASS / FAIL ..."; the values
-- were the same in every run on record), and the book, bat and apple are taken back at the end (it used to leave
-- three more in the bag each run).
local p = getPlayer()
local inv = p:getInventory()
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; print("ZEDQA verbs PASS " .. what) else nFail = nFail + 1; print("ZEDQA verbs FAIL " .. what) end end
local function hand(it) return it and it:getDisplayName() or "nil" end
local function qhead() local q = ISTimedActionQueue.getTimedActionQueue(p); local a = q and q.queue and q.queue[1]; return a and tostring(a.Type) or "none" end
local function clearQueue() local q = ISTimedActionQueue.getTimedActionQueue(p); if q and q.clearQueue then pcall(q.clearQueue, q) end end
local function card(item, ctx) local c = ZeD_ItemCard:new(0, 0, 220, 300, "drawer", 0); c:initialise(); c.item = item; c.playerNum = 0; c.sourceContext = ctx; return c end
local function fire(c, verb)
    local ok, err = pcall(c._dispatchHeaderVerb, c, verb)
    print("ZEDQA fire " .. verb .. " ok=" .. tostring(ok) .. " err=" .. tostring(err) .. " qhead=" .. qhead())
    check(ok, verb .. " dispatched without an error (" .. tostring(err) .. ")")
end
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local book, bat, apple = inv:AddItem("Base.Book"), inv:AddItem("Base.BaseballBat"), inv:AddItem("Base.Apple")
local worn = nil
do local items = inv:getItems(); for i = 0, items:size() - 1 do local it = items:get(i); if instanceof(it, "Clothing") and p:isEquipped(it) then worn = it; break end end end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
if worn then
    at(10,  function() print("ZEDQA worn=" .. hand(worn) .. " ctx=" .. card(worn, "equipped"):_effectiveContext()); fire(card(worn, "equipped"), "UNEQUIP") end)
    at(250, function()
        local ctx = card(worn, "equipped"):_effectiveContext()
        print("ZEDQA after UNEQUIP pEq=" .. tostring(p:isEquipped(worn)) .. " ctx=" .. ctx)
        check(not p:isEquipped(worn) and ctx == "inventory", "UNEQUIP took the worn thing off and its card reads inventory (" .. ctx .. ")")
        fire(card(worn, "inventory"), "EQUIP")
    end)
    at(490, function()
        local ctx = card(worn, "inventory"):_effectiveContext()
        print("ZEDQA after EQUIP pEq=" .. tostring(p:isEquipped(worn)) .. " ctx=" .. ctx)
        check(p:isEquipped(worn) and ctx == "equipped", "EQUIP put it back on and its card reads equipped (" .. ctx .. ")")
    end)
else
    print("ZEDQA verbs not run: UNEQUIP / EQUIP of a worn thing (the character wears nothing)")
end
at(500, function() fire(card(book, "inventory"), "READ") end)
at(560, function() local q = qhead(); check(q == "ISReadABook", "READ queued the game's read (" .. q .. ")"); clearQueue() end)
at(620, function() fire(card(bat, "inventory"), "EQUIP") end)
at(860, function()
    local ctx = card(bat, "inventory"):_effectiveContext()
    check(p:getPrimaryHandItem() == bat and ctx == "equipped", "EQUIP put the bat in the hand and its card reads equipped (" .. hand(p:getPrimaryHandItem()) .. ", " .. ctx .. ")")
    fire(card(bat, "equipped"), "UNEQUIP")
end)
at(1100, function()
    check(p:getPrimaryHandItem() == nil, "UNEQUIP emptied the hand (" .. hand(p:getPrimaryHandItem()) .. ")")
    fire(card(apple, "inventory"), "EAT")
end)
at(1160, function() local q = qhead(); check(q == "ISEatFoodAction", "EAT queued the game's eat (" .. q .. ")"); clearQueue() end)
at(1230, function() fire(card(apple, "inventory"), "DROP") end)
at(1410, function()
    local cont = tostring(apple:getContainer() and apple:getContainer():getType())
    local ctx = card(apple, "inventory"):_effectiveContext()
    check(cont == "floor" and ctx == "ground", "DROP put the apple on the floor and its card reads ground (" .. cont .. ", " .. ctx .. ")")
    fire(card(apple, "ground"), "TAKE")
end)
at(1600, function()
    local ctx = card(apple, "ground"):_effectiveContext()
    check(inv:contains(apple) and ctx == "inventory", "TAKE brought the apple back and its card reads inventory (" .. ctx .. ")")
end)
-- the three things taken back, wherever they ended up (bag, hand, floor)
at(1620, function()
    clearQueue()
    if p:getPrimaryHandItem() == bat then p:setPrimaryHandItem(nil) end
    if p:getSecondaryHandItem() == bat then p:setSecondaryHandItem(nil) end
    for _, it in ipairs({ book, bat, apple }) do
        pcall(function()
            local wio = it.getWorldItem and it:getWorldItem()
            if wio and wio:getSquare() then wio:getSquare():transmitRemoveItemFromSquare(wio) end
            local c = it:getContainer()
            if c then c:Remove(it) end
        end)
    end
    local left = 0
    for _, it in ipairs({ book, bat, apple }) do if inv:contains(it) then left = left + 1 end end
    check(left == 0, "the book, bat and apple are taken back (" .. left .. " still in the bag)")
    print("ZEDQA verbs " .. nPass .. " passed, " .. nFail .. " failed")
    print("ZEDQA verbs done")
end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, err = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(err)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA verbs armed")
