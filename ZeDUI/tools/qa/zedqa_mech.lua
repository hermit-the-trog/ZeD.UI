-- ZeD QA: Vehicle tab — spawn a damaged sedan, inspect through vanilla's Mechanics path, capture every view, run an uninstall
local p = getPlayer()
local MT = ZeD.MechanicsTab
local function shot(tag) pcall(function() getCore():TakeFullScreenshot("zedqa_mech_" .. tag .. ".png") end); print("ZEDQA mech shot " .. tag) end
local function W() return ZeD_WorldWindow.getWindow() end
local function S() local w = W(); return w and MT.getState(w) end
local v = nil
local steps, t0 = {}, nil
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local phase, n, waitStart = "setup", 0, 0

local function setup()
    if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
    if ZEDQA_MECH_V and ZEDQA_MECH_V:getSquare() then
        v = ZEDQA_MECH_V; print("ZEDQA mech reuse id=" .. tostring(v:getId())); return
    end
    local spot = ZEDQA_MECH_SPOT
    local sq = spot and getCell():getGridSquare(spot[1], spot[2], math.floor(p:getZ()))
            or getCell():getGridSquare(math.floor(p:getX()) + 4, math.floor(p:getY()), math.floor(p:getZ()))
    v = sq and addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq) or nil
    ZEDQA_MECH_V = v
    print("ZEDQA mech spawn " .. tostring(v and v:getScriptName()) .. " id=" .. tostring(v and v:getId()) .. " at " .. tostring(sq and sq:getX()) .. "," .. tostring(sq and sq:getY()))
end
local function damage()
    if not v then return end
    local inv = p:getInventory()
    pcall(function() local key = v:createVehicleKey(); if key then inv:AddItem(key) end end)
    print("ZEDQA mech key on player=" .. tostring(inv:haveThisKeyId(v:getKeyId())))
    for _, t in ipairs({ "Base.Jack", "Base.LugWrench", "Base.Wrench", "Base.Screwdriver", "Base.EngineParts", "Base.EngineParts", "Base.OldTire1" }) do inv:AddItem(t) end
    local rl = v:getPartById("TireRearLeft")
    local types = {}
    if rl and rl:getItemType() then for i = 0, rl:getItemType():size() - 1 do types[#types + 1] = rl:getItemType():get(i) end end
    print("ZEDQA mech tire types " .. table.concat(types, ","))
    if rl then rl:setInventoryItem(nil); pcall(function() v:transmitPartItem(rl) end) end
    local rr = v:getPartById("TireRearRight")
    if rr then rr:setCondition(12); pcall(function() rr:setContainerContentAmount(9) end) end
    local mu = v:getPartById("Muffler"); if mu then mu:setCondition(34) end
    local en = v:getPartById("Engine"); if en then en:setCondition(58) end
    local hood = v:getPartById("EngineDoor"); if hood then hood:setCondition(62) end
    local hl = v:getPartById("HeadlightRight"); if hl then hl:setInventoryItem(nil) end
    local bed = v:getPartById("TruckBed")
    if bed and bed:getItemContainer() then bed:getItemContainer():AddItem("Base.NormalTire1") end
    print("ZEDQA mech damaged; inv jack=" .. tostring(inv:contains("Jack")) .. " wrench=" .. tostring(inv:contains("Wrench")))
end
local function riskCheck(tag)
    local ok, msg = pcall(function()
        local inv = getPlayerInventory(0).inventoryPane.inventoryPage.backpacks
        local loot = getPlayerLoot(0).inventoryPane.inventoryPage.backpacks
        local byType = VehicleUtils.getItems(0)
        local names = {}
        for _, b in ipairs(loot) do names[#names + 1] = tostring(b.inventory:getType()) end
        return "invPages=" .. #inv .. " lootPages=" .. #loot .. " [" .. table.concat(names, ",") .. "] normalTire=" .. tostring(byType["Base.NormalTire1"] and #byType["Base.NormalTire1"] or 0)
            .. " oldTire=" .. tostring(byType["Base.OldTire1"] and #byType["Base.OldTire1"] or 0) .. " jack=" .. tostring(byType["Base.Jack"] and #byType["Base.Jack"] or 0)
    end)
    print("ZEDQA mech risk " .. tag .. " " .. tostring(msg))
end
local function card(id, verb, confirm)
    local s = S(); if not s then return end
    s.view, s.card, s.verb, s.confirm, s.cardScroll, s.pick, s.fixPick = "card", id, verb, confirm, 0, 1, 1
end
local function report(tag)
    local w, s = W(), S()
    print("ZEDQA mech " .. tag .. " tab=" .. tostring(w and w._activeTab) .. " vehicles=" .. tostring(s and #s.vehicles) .. " idx=" .. tostring(s and s.idx)
        .. " inspected=" .. tostring(v and MT.isInspected(v)) .. " view=" .. tostring(s and s.view) .. " card=" .. tostring(s and s.card) .. " verb=" .. tostring(s and s.verb)
        .. " zones=" .. tostring(s and #s.zones) .. " maxScroll=" .. tostring(s and s.maxScroll) .. " win=" .. tostring(w and w:getX()) .. "," .. tostring(w and w:getY()) .. " " .. tostring(w and w:getWidth()) .. "x" .. tostring(w and w:getHeight()))
end

local function afterInspect(base)
    local t = base
    at(t + 40, function() report("overview"); shot("overview") end)
    at(t + 60, function() local s = S(); s.scrollY = 99999 end)
    at(t + 90, function() shot("list_bottom") end)
    at(t + 100, function() local s = S(); s.scrollY = 0; s.sort = "cond" end)
    at(t + 130, function() shot("worst_first") end)
    at(t + 140, function() local s = S(); s.sort = "area" end)
    at(t + 150, function() card("TireRearRight", "inflate") end)
    at(t + 190, function() report("card_tire"); shot("card_tire") end)
    at(t + 200, function() card("TireRearLeft", "install") end)
    at(t + 240, function() report("card_install"); shot("card_install") end)
    at(t + 250, function() card("Engine", "repairEngine") end)
    at(t + 290, function() report("card_engine"); shot("card_engine") end)
    at(t + 300, function() card("EngineDoor", "fix") end)
    at(t + 340, function() report("card_hood"); shot("card_hood") end)
    at(t + 350, function() card("WindowFrontLeft", "smash", "smash") end)
    at(t + 390, function() report("card_confirm"); shot("card_confirm") end)
    at(t + 400, function() card("TireRearRight", "uninstall"); riskCheck("before_uninstall") end)
    at(t + 430, function()
        local s = S(); local z = s and s.byId["mech:verb:uninstall"]
        print("ZEDQA mech uninstall zone=" .. tostring(z ~= nil))
        if z then z.fn() end
    end)
    at(t + 700, function() report("working"); shot("working") end)
    at(t + 1500, function()
        local rr = v and v:getPartById("TireRearRight")
        report("after_uninstall"); shot("after_uninstall")
        print("ZEDQA mech after uninstall: RR item=" .. tostring(rr and rr:getInventoryItem()) .. " playerHasOldTire=" .. tostring(p:getInventory():getCountType("Base.OldTire1")))
    end)
    at(t + 1520, function() local s = S(); s.view, s.card = "overview", nil; print("ZEDQA mech done") end)
end

local function tick()
    n = n + 1
    if phase == "setup" then
        if n == 5 then setup() end
        if n == 30 then damage() end
        if n == 40 then riskCheck("start") end
        if n == 50 then
            if v then ISVehicleMenu.onMechanic(p, v); print("ZEDQA mech onMechanic queued") end
            phase, waitStart = "wait", n
        end
        return
    end
    if phase == "wait" then
        if (n - waitStart) % 120 == 0 then report("waiting") end
        local w = W()
        if v and MT.isInspected(v) and w and w._activeTab == "vehicle" then
            print("ZEDQA mech inspected after " .. tostring(n - waitStart) .. " ticks")
            phase = "run"; afterInspect(n)
        elseif n - waitStart > 2400 then
            print("ZEDQA mech TIMEOUT waiting for inspection"); Events.OnTick.Remove(tick); return
        end
        return
    end
    local i = 1
    while steps[i] do
        if steps[i].n <= n then
            local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end
            table.remove(steps, i)
        else i = i + 1 end
    end
    if #steps == 0 then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick); print("ZEDQA mech armed")
