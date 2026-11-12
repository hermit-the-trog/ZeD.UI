-- ZeDUI/tools/qa/gallery_cinema_kohners2.lua  (Nov 11 2026, QA; the gallery plan v2, shot 2): Kohners in a house with
-- power, the washer-dryer running. Dark + Pink (her movie's look). Run on her shot save:
--   cinema_run2.ps1 -Manifest cinema_kohners2.txt -ShotSave ZeD-Shots-Kohners
-- cin_koh_house.png: the Character window on Loot with a shirt's item card open in the drawer, the World window on Loot
-- with the washer-dryer's card (its face), the machine running (washer mode, water and a shirt in). The house: the
-- nearest room with free squares round it near a town (C.findRoomSpot); the game's grid and water switches are on for
-- the run and put back (C.grid), the machine and what was given are taken away after. grep "ZEDQA ckoh2".
local C = CIN
local S = C.seq("ckoh2")
local p = getPlayer()
local pn = p:getPlayerNum()
local CT = ZeD.ContainerControls
local TOWNS = { { 10650, 9800 }, { 10620, 9480 }, { 11880, 6900 }, { 6450, 5350 }, { 8150, 11650 } }
local K = { spot = nil, obj = nil, shirt = nil, added = {} }
local function homeRoom(room)
    local n = string.lower(C.roomName(room))
    return n == "kitchen" or n == "livingroom" or n == "bedroom" or n == "bathroom" or n == "laundry" or n == "hall"
end

S.step(5, function() C.look("dark", "pink"); C.noWindows(); if getGameSpeed() <= 0 then setGameSpeed(1) end; pcall(function() p:setGodMod(true) end) end)
for k = 1, #TOWNS do
    S.step(5, function() if K.spot then return end; C.moveTo(TOWNS[k][1], TOWNS[k][2], 0) end)
    S.step(200, function()
        if K.spot then return end
        K.spot = C.findRoomSpot(TOWNS[k][1], TOWNS[k][2], 0, 45, homeRoom)
        S.say("town " .. k .. ": " .. tostring(K.spot and (K.spot.x .. "," .. K.spot.y .. " room " .. C.roomName(K.spot.room))))
    end)
end
S.step(10, function()
    if not K.spot then S.say("ERR no house room found"); return end
    C.moveTo(K.spot.x, K.spot.y, 0)
    C.grid(true)
    C.time(14.0)
    C.clearSky()
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Trousers_CamoGreen", "Base.Shoes_ArmyBoots", "Base.Glasses_Aviators",
              "Base.WristWatch_Left_DigitalBlack", "Base.Bag_FannyPackFront" }, nil, { "Base.Shotgun", "Base.ShotgunShells", "Base.MuldraughMap", "Base.Lighter", "Base.WaterBottle" })
    pcall(function() local d = p:getDescriptor(); d:setForename("Sara"); d:setSurname("Kohners") end)
    C.profession("BURGER_FLIPPER")
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.16, 0.16, 0.17)
    K.shirt = p:getInventory():AddItem("Base.Shirt_Lumberjack")
    S.say("dressed; worn " .. tostring(p:getWornItems():size()) .. "; shirt " .. tostring(K.shirt ~= nil))
end)
-- the washer-dryer on the first side square (gallery_t14_indoor.lua's putMachine), water in, a shirt in, washer mode
S.step(20, function()
    if not K.spot then return end
    local sq = K.spot.sides[1]
    local tile = nil
    for i = 0, 47 do
        local name = "appliances_laundry_01_" .. i
        local spr = getSprite(name)
        local props = spr and spr:getProperties()
        if not tile and props and props:has("IsoType") and props:get("IsoType") == "IsoCombinationWasherDryer" then tile = name end
    end
    if not (tile and sq) then S.say("ERR no washer-dryer tile or square"); return end
    local obj
    pcall(function() obj = IsoCombinationWasherDryer.new(getCell(), sq, getSprite(tile)) end)
    if not obj then S.say("ERR the washer-dryer was not made"); return end
    pcall(function() obj:createContainersFromSpriteProperties() end)
    pcall(function() obj:createFluidContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    pcall(function() obj:setModeWasher() end)
    pcall(function() obj:getContainer():AddItem("Base.Tshirt_DefaultTEXTURE_TINT") end)
    pcall(function() obj:getModData().canBeWaterPiped = nil end)
    pcall(function() obj:setUsesExternalWaterSource(false) end)
    if (obj:getFluidAmount() or 0) <= 0 then pcall(function() obj:addFluid(FluidType.Water, 20) end) end
    K.obj = obj
    -- face the machine
    local dx, dy = sq:getX() - K.spot.x, sq:getY() - K.spot.y
    S.face = (dx > 0 and "E") or (dx < 0 and "W") or (dy > 0 and "S") or "N"
    local g = false; pcall(function() g = sq:hasGridPower() end)
    S.say(string.format("washer-dryer at %d,%d (facing %s) | grid power %s | water %s", sq:getX(), sq:getY(), S.face, tostring(g), tostring(obj:getFluidAmount())))
end)
C.lookAround(S, "S")
S.step(5, function() p:setDir(IsoDirections[S.face or "S"]) end)
C.pointerAway(S)
C.zoom(S, 0.5)
S.step(30, function() C.windows("loot", "loot") end)
-- the World window: the machine's container, then its gears button (the card), then its power control (running)
S.step(60, function() if K.obj then ZeD_WorldWindow.selectContainer(K.obj:getContainer(), 900) end end)
S.poll(10, 90, function()
    local c = ZeD_WorldWindow.getWindow() and ZeD_WorldWindow.getWindow()._mainContent
    for i, h in ipairs((c and c._cc and c._cc.hits) or {}) do if h.key == "obj:ZeDLaundry" then CT.press(c, i); S.say("gears pressed"); return true end end
    return K.obj == nil
end)
S.poll(10, 90, function()
    local c = ZeD_WorldWindow.getWindow() and ZeD_WorldWindow.getWindow()._objectCard
    local e = c and c.entry
    return K.obj == nil or (e and e.t and e.t._face ~= nil)
end)
S.step(20, function()
    local c = ZeD_WorldWindow.getWindow() and ZeD_WorldWindow.getWindow()._objectCard
    local zs = c and ((c._zones and #c._zones > 0) and c._zones or c._lastZones) or {}
    for _, z in ipairs(zs) do if z.fid == "ldy:power" and z.run then z.run(c, p); S.say("power pressed"); return end end
    S.say("ERR no power control on the card")
end)
S.poll(10, 90, function() return K.obj == nil or K.obj:isActivated() end)
S.step(10, function() S.say("machine running " .. tostring(K.obj and K.obj:isActivated())) end)
-- the Character window: the shirt picked in Loot, its item card in the drawer
S.step(20, function()
    local w = ZeD_CharacterWindow.getWindow()
    local c = w and w._mainContent
    if not (c and K.shirt) then S.say("ERR no Loot content or no shirt"); return end
    local sel = c._selectedItems or {}
    for k2 in pairs(sel) do sel[k2] = nil end
    sel[K.shirt] = true
    c._selectedItems, c._lastClickedItem = sel, K.shirt
    w._updateDrawer(c)
    S.say("shirt picked; drawer " .. tostring(w._drawerMode))
end)
S.step(120, function() end)
C.whenStill(S, function()
    S.say("running " .. tostring(K.obj and K.obj:isActivated()) .. " | char tab " .. tostring(ZeD_CharacterWindow.getWindow()._activeTab) .. " | world tab " .. tostring(ZeD_WorldWindow.getWindow()._activeTab))
    C.boxes(S, "koh_house")
    C.shot(S, "koh_house")
end)
S.step(20, function()
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    if K.obj then
        pcall(function() if K.obj:isActivated() then K.obj:setActivated(false) end end)
        local sq = K.obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(K.obj) end) end
    end
    if K.shirt and K.shirt:getContainer() then pcall(function() K.shirt:getContainer():Remove(K.shirt) end) end
    C.grid(false)
    C.noWindows()
    S.say("put back: the machine and the shirt taken away, the grid and water switches")
end)
S.step(30, function() S.say("DONE") end)
S.run()
