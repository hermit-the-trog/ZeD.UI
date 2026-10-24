-- ZeDUI/tools/qa/zedqa_put_back.lua  (Oct 24 2026)
-- Putting things back after an action (ZeD_PutBack.lua; QUICK_CHORDS_SPEC.md
-- section 4), with the switch on:
--   * half an apple from a worn bag: the rest goes back into the bag;
--   * a cigarette and a lighter from the bag: the lighter goes back;
--   * a drink of water from the bag: the bottle goes back;
--   * a rear tire off the deep run's car with the jack and the wrench in the bag:
--     the tools go back into the bag, the tire stays on you; then on again
--     (the game reaches a trunk only from its own side, never from a wheel);
--   * an apple, the eating stopped halfway: it stays on you (no tidying);
--   * the switch off: an apple stays on you.
-- The switch, the car's tire and the things given are put back as they were.
-- Run on the deep-run character. grep "ZEDQA pb".
local p = getPlayer()
local pn = p:getPlayerNum()
local PB, S = ZeD.PutBack, ZeD.Settings
local function say(s) print("ZEDQA pb " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_pb_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- waits up to max frames for cond, then runs fn(true | false)
local function waitFor(max, cond, fn) Q[#Q + 1] = { n = 1, max = max, cond = cond, fn = fn } end

if not (PB and S and S.putBackOption) then say("ERR ZeD.PutBack or its setting is not loaded"); say("DONE"); return end

local wasOn = S.putBackOption:getValue()
-- (the game's Auto-drink drinks from a bottle the moment it reaches the main inventory, before the drink
-- action starts: off for this test, put back at the end)
local wasAutoDrink = getCore():getOptionAutoDrink()
getCore():setOptionAutoDrink(false)
local function setOn(v) pcall(function() S.putBackOption:setValue(v and 2 or 1) end) end
local main = p:getInventory()
local bag, bagInv
local given = {}
local function give(inv, ft) local it = inv:AddItem(ft); if it then given[#given + 1] = it end; return it end
local function stopAll() pcall(function() p:StopAllActionQueue() end); pcall(function() ISTimedActionQueue.clear(p) end) end
local function queueEmpty() local q = ISTimedActionQueue.getTimedActionQueue(p); return not (q and q.queue and #q.queue > 0) end
local function where(it) local c = it and it:getContainer(); return c and (c == main and "main" or (c == bagInv and "bag" or tostring(c:getType()))) or "nowhere" end

step(20, function()
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(ZeD.Input.Focus.releaseFocus)
    stopAll()
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:get(i):getItem()
        if it and it:IsInventoryContainer() then bag = it; bagInv = it:getInventory(); break end
    end
    -- (none worn: a bag carried in the main inventory is a bag you carry too; never a key ring, which takes keys only)
    if not bag then
        local items = main:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if instanceof(it, "InventoryContainer") and it ~= p:getPrimaryHandItem() and it ~= p:getSecondaryHandItem()
                and not tostring(it:getType()):find("KeyRing", 1, true) and it:getInventory():getCapacity() >= 2 then
                bag = it; bagInv = it:getInventory(); break
            end
        end
    end
    -- (none at all: a school bag, carried, taken away at the end)
    if not bag then
        bag = main:AddItem("Base.Bag_Schoolbag")
        if bag then given[#given + 1] = bag; bagInv = bag:getInventory() end
    end
    setOn(true)
    PB.debug = true
    check(PB.on(), "the switch is on")
    say("the bag: " .. tostring(bag and bag:getDisplayName()) .. "; hands: " .. tostring(p:getPrimaryHandItem()) .. " / " .. tostring(p:getSecondaryHandItem()))
end)

-- half an apple from the bag
local apple
step(5, function()
    if not check(bagInv ~= nil, "a worn bag to take things from") then return end
    apple = give(bagInv, "Base.Apple")
    ISInventoryPaneContextMenu.onEatItems({ apple }, 0.5, pn)
end)
waitFor(1800, function() return queueEmpty() end, function(done)
    say("apple: queue empty " .. tostring(done) .. ", the apple is in " .. where(apple) .. "; put back queued " .. tostring(PB.last and PB.last.backs))
    check(where(apple) == "bag", "half an apple: the rest went back into the bag")
    check(PB.last and PB.last.backs == 0, "half an apple: the game put it back itself, ZeD moved nothing twice")
end)

-- a cigarette with the lighter from the bag
local cig, lighter
step(5, function()
    if not bagInv then return end
    -- (the character's own fire sources would be found first: out of the way until the end)
    for _, t in ipairs({ "Lighter", "Matches" }) do
        local list = main:getAllTypeRecurse(t)
        for i = 0, list:size() - 1 do
            local x = list:get(i)
            local c = x:getContainer()
            if c then c:Remove(x); given[#given + 1] = { putBack = x, into = c } end
        end
    end
    cig, lighter = give(bagInv, "Base.CigaretteSingle"), give(bagInv, "Base.Lighter")
    ISInventoryPaneContextMenu.onEatItems({ cig }, 1, pn)
end)
waitFor(2400, function() return queueEmpty() end, function(done)
    say("smoke: queue empty " .. tostring(done) .. ", the lighter is in " .. where(lighter) .. ", the cigarette in " .. where(cig))
    check(where(lighter) == "bag", "a cigarette: the lighter went back into the bag")
end)

-- a drink from a bottle in the bag
local bottle
step(5, function()
    if not bagInv then return end
    bottle = give(bagInv, "Base.WaterBottle")
    local fc = bottle and bottle:getFluidContainer()
    if fc then fc:Empty(); fc:addFluid(FluidType.Water, fc:getCapacity() * 0.8) end
    pcall(function() p:getStats():set(CharacterStat.THIRST, 0.4) end)
    local g = ZeD.QuickWheel.group("drink")
    say(string.format("drink: thirst %.2f, the bottle holds %.2f", p:getStats():get(CharacterStat.THIRST), bottle:getFluidContainer():getAmount()))
    g.act(p, bottle)
end)
-- (a frame by frame look while the bottle comes out of the bag and the drink starts)
for i = 1, 8 do
    step(i == 1 and 25 or 2, function()
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        local names = {}
        for _, a in ipairs(q and q.queue or {}) do
            local ok, v = pcall(function() return a:isValid() end)
            names[#names + 1] = tostring(a.Type) .. (ok and (v and "" or " [not valid]") or " [?]")
        end
        say("drink look " .. i .. ": " .. table.concat(names, ", ") .. "; the bottle in " .. where(bottle) .. string.format(", holds %.2f", bottle:getFluidContainer():getAmount()))
    end)
end
waitFor(1800, function() return queueEmpty() end, function(done)
    say("drink: queue empty " .. tostring(done) .. ", the bottle is in " .. where(bottle))
    check(where(bottle) == "bag", "a drink: the bottle went back into the bag")
end)

-- a tire off the deep run's car, the tools from its trunk, then on again
local car, tirePart, trunk, jack, wrench, tire
step(5, function()
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local t
        pcall(function() t = v:getModData().ZeDDeepRun end)
        if t == "near_car" and v:DistTo(p) < 10 then car = v end
    end
    if not car then say("no deep-run car within 10 tiles: the tire scene is skipped"); return end
    tirePart = car:getPartById("TireRearLeft")   -- (beside the trunk: the game walks to the wheel, then reaches for the tools)
    local tb = car:getPartById("TruckBed")
    trunk = tb and tb:getItemContainer()
    if not (tirePart and tirePart:getInventoryItem() and trunk) then say("the car has no tire or trunk: skipped"); car = nil; return end
    -- the tools in the bag you carry (the game reaches a trunk only from its own side, never from a wheel:
    -- QA Oct 24 2026), the character's own out of the way
    jack, wrench = give(bagInv or main, "Base.Jack"), give(bagInv or main, "Base.LugWrench")
    for _, ft in ipairs({ "Base.Jack", "Base.LugWrench" }) do
        local mine = main:getFirstTypeRecurse(ft:sub(6))
        while mine and mine ~= jack and mine ~= wrench do
            mine:getContainer():Remove(mine); given[#given + 1] = { putBack = mine, into = main }
            mine = main:getFirstTypeRecurse(ft:sub(6))
        end
    end
    -- the trunk open, so its things are in reach (the door is its own part)
    local door = car:getPartById("TrunkDoor") or car:getPartById("DoorRear")
    if door and door:getDoor() then
        pcall(function() door:getDoor():setLocked(false) end)
        pcall(function() door:getDoor():setOpen(true) end)
    end
    local tbl = tirePart:getTable("uninstall")
    local need = {}
    if tbl and tbl.items then for _, x in pairs(tbl.items) do need[#need + 1] = tostring(x.type or x.tags) end end
    say("tire: uninstall needs " .. table.concat(need, ", ") .. "; skills " .. tostring(tbl and tbl.skills) .. "; recipes " .. tostring(tbl and tbl.recipes)
        .. "; trunk door " .. tostring(door and door:getDoor() and door:getDoor():isOpen()))
    -- (the deep run's things round the car can block the walk to the wheel: the character starts at the wheel)
    local c = car:getAreaCenter(tirePart:getArea())
    if c then pcall(function() p:teleportTo(c:getX(), c:getY(), car:getZ()) end) end
    say("the character at the wheel: " .. string.format("%.1f, %.1f", p:getX(), p:getY()))
    ISVehiclePartMenu.onUninstallPart(p, tirePart)
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local names = {}
    for _, a in ipairs(q and q.queue or {}) do
        local ok, v = pcall(function() return a:isValid() end)
        names[#names + 1] = tostring(a.Type) .. (ok and (v and "" or " [not valid here]") or " [?]")
    end
    local reach = false
    pcall(function() reach = ISInventoryPaneContextMenu.getContainers(p):contains(trunk) end)
    say("tire: queued " .. table.concat(names, ", ") .. "; the trunk in reach " .. tostring(reach))
end)
step(300, function()
    if not car then return end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local names = {}
    for _, a in ipairs(q and q.queue or {}) do names[#names + 1] = tostring(a.Type) end
    say("tire after 300 frames: queue " .. table.concat(names, ", ") .. "; the jack is in " .. where(jack) .. "; the tire still on " .. tostring(tirePart:getInventoryItem() ~= nil))
end)
waitFor(4800, function() return not car or (queueEmpty() and tirePart:getInventoryItem() == nil) end, function(done)
    if not car then return end
    tire = nil
    local items = main:getItems()
    for i = 0, items:size() - 1 do local x = items:get(i); if x:getFullType():find("Tire", 1, true) then tire = x end end
    say("tire off: done " .. tostring(done) .. ", the jack is in " .. where(jack) .. ", the wrench in " .. where(wrench) .. ", the tire " .. tostring(tire and where(tire)))
    check(tirePart:getInventoryItem() == nil, "the tire came off")
    check(jack:getContainer() == bagInv and wrench:getContainer() == bagInv, "tire off: the jack and the wrench went back into the bag")
    shot("tire_off")
end)
step(5, function()
    if not (car and tire) then return end
    ISVehiclePartMenu.onInstallPart(p, tirePart, tire)
end)
waitFor(4800, function() return not (car and tire) or (queueEmpty() and tirePart:getInventoryItem() ~= nil) end, function(done)
    if not (car and tire) then return end
    say("tire on: done " .. tostring(done) .. ", the jack is in " .. where(jack) .. ", the wrench in " .. where(wrench))
    check(tirePart:getInventoryItem() ~= nil, "the tire went on again")
    check(jack:getContainer() == bagInv and wrench:getContainer() == bagInv, "tire on: the jack and the wrench went back into the bag")
end)

-- stopped halfway: no tidying
local apple2
step(5, function()
    if not bagInv then return end
    apple2 = give(bagInv, "Base.Apple")
    ISInventoryPaneContextMenu.onEatItems({ apple2 }, 1, pn)
end)
waitFor(1200, function() local q = ISTimedActionQueue.getTimedActionQueue(p); local a = q and q.queue and q.queue[1]; return a and a.Type == "ISEatFoodAction" end, function() end)
step(60, function() stopAll() end)
step(240, function()
    say("stopped: the apple is in " .. where(apple2))
    check(where(apple2) ~= "bag", "stopped halfway: the apple stays on you")
end)

-- the switch off: a bottle stays on you (the game puts eaten food back by itself, a bottle it leaves)
local bottle2
step(5, function()
    if not bagInv then return end
    setOn(false)
    bottle2 = give(bagInv, "Base.WaterBottle")
    local fc = bottle2 and bottle2:getFluidContainer()
    if fc then fc:Empty(); fc:addFluid(FluidType.Water, fc:getCapacity() * 0.8) end
    pcall(function() p:getStats():set(CharacterStat.THIRST, 0.4) end)
    ZeD.QuickWheel.group("drink").act(p, bottle2)
end)
waitFor(1800, function() return queueEmpty() end, function(done)
    say("switch off: the bottle is in " .. where(bottle2))
    check(where(bottle2) == "main", "the switch off: the bottle stays on you")
end)

-- put back
step(10, function()
    stopAll()
    for _, it in ipairs(given) do
        if type(it) == "table" and it.putBack then it.into:AddItem(it.putBack)
        elseif it and it.getContainer then
            if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
            if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
            if it:getContainer() then it:getContainer():Remove(it) end
        end
    end
    if tire and tirePart and not tirePart:getInventoryItem() then
        pcall(function() if tire:getContainer() then tire:getContainer():Remove(tire) end; tirePart:setInventoryItem(tire); car:transmitPartItem(tirePart) end)
    end
    PB.debug = nil
    getCore():setOptionAutoDrink(wasAutoDrink)
    pcall(function() S.putBackOption:setValue(wasOn or 1) end)
    if S.save then S.save() end
    say("put back: the switch " .. tostring(S.putBackOption:getValue()) .. " (was " .. tostring(wasOn) .. ")")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- (stepped on each drawn frame)
local qi, wait, waited = 1, nil, 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    if s.cond then
        waited = waited + 1
        local ok, met = pcall(s.cond)
        if not (ok and met) and waited < s.max then return end
        qi = qi + 1; local w = waited; waited = 0
        local ok2, err = pcall(s.fn, ok and met and true or false)
        if not ok2 then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
        if not (ok and met) then say("(waited " .. w .. " frames)") end
        return
    end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
