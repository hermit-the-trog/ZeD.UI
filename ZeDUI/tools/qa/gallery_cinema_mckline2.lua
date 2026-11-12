-- ZeDUI/tools/qa/gallery_cinema_mckline2.lua  (Nov 11 2026, QA; the gallery plan v2, shot 3): McKline in his kitchen in
-- the evening, a pot on the stove, ingredients in his bags. High Contrast + Red (his movie's look). Run on his shot save:
--   cinema_run2.ps1 -Manifest cinema_mckline2.txt -ShotSave ZeD-Shots-McKline
-- cin_mck_kitchen.png: the Character window on Cooking with a dish picked (stew, two vegetables in), the World window on
-- Crafting with the oven's panel, on and set (BAKE 175, gallery_t14_indoor.lua's presses). The kitchen: a house kitchen
-- with a stove found near a town (else a stove set down in the nearest room); the game's grid switch on for the run and
-- put back (C.grid). Everything given or set down is taken away after. grep "ZEDQA cmck2".
local C = CIN
local S = C.seq("cmck2")
local p = getPlayer()
local pn = p:getPlayerNum()
local ST, SA, CK = ZeD.Stations, ZeD.StationAppliance, ZeD.CookingTab
local TOWNS = { { 10650, 9800 }, { 10620, 9480 }, { 11880, 6900 }, { 6450, 5350 }, { 8150, 11650 } }
local M = { stove = nil, placed = false, added = {} }
local function isOven(o)
    if not instanceof(o, "IsoStove") then return false end
    local mw = false; pcall(function() mw = o:isMicrowave() end)
    return not mw
end
-- a kitchen stove within r of x, y with a free room square in front of it
local function findStove(cx, cy, r)
    local cell = getCell()
    local best, bd = nil, 1e9
    for dx = -r, r do for dy = -r, r do
        local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
        local room = sq and sq:getRoom()
        if room and string.lower(C.roomName(room)) == "kitchen" then
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if isOven(o) then
                    for _, d in ipairs({ { 0, 1, "N" }, { 1, 0, "W" }, { 0, -1, "S" }, { -1, 0, "E" } }) do
                        local s2 = cell:getGridSquare(sq:getX() + d[1], sq:getY() + d[2], 0)
                        local free = false
                        if s2 then pcall(function() free = s2:isFree(false) and s2:getRoom() ~= nil and s2:canReachTo(sq) end) end
                        local dd = dx * dx + dy * dy
                        if free and dd < bd then best, bd = { obj = o, x = s2:getX(), y = s2:getY(), face = d[3] }, dd end
                    end
                end
            end
        end
    end end
    return best
end

S.step(5, function() C.look("hicon", "red"); C.noWindows(); if getGameSpeed() <= 0 then setGameSpeed(1) end; pcall(function() p:setGodMod(true) end) end)
for k = 1, #TOWNS do
    S.step(5, function() if M.stove then return end; C.moveTo(TOWNS[k][1], TOWNS[k][2], 0) end)
    S.step(200, function()
        if M.stove then return end
        M.stove = findStove(TOWNS[k][1], TOWNS[k][2], 40)
        S.say("town " .. k .. ": kitchen stove " .. tostring(M.stove and (M.stove.x .. "," .. M.stove.y .. " facing " .. M.stove.face)))
        if not M.stove and k == #TOWNS then
            -- no kitchen with a stove anywhere: a stove set down in the nearest room
            local spot = C.findRoomSpot(TOWNS[k][1], TOWNS[k][2], 0, 45)
            if spot then
                local sq = spot.sides[1]
                local o = IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_12"))
                pcall(function() o:createContainersFromSpriteProperties() end)
                sq:AddSpecialObject(o)
                if o:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(o) end) end
                local dx, dy = sq:getX() - spot.x, sq:getY() - spot.y
                M.stove = { obj = o, x = spot.x, y = spot.y, face = (dx > 0 and "E") or (dx < 0 and "W") or (dy > 0 and "S") or "N" }
                M.placed = true
                S.say("note: no kitchen stove found; one set down in " .. C.roomName(spot.room) .. " at " .. sq:getX() .. "," .. sq:getY())
            end
        end
    end)
end
S.step(10, function()
    if not M.stove then S.say("ERR no stove"); return end
    C.moveTo(M.stove.x, M.stove.y, 0)
    C.grid(true)
    C.time(19.5)
    C.clearSky()
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Trousers_Black", "Base.WristWatch_Left_DigitalBlack", "Base.HolsterShoulder", "Base.Bag_Satchel" }, nil,
        { "Base.Pistol", "Base.Bullets9mm", "Base.Lighter", "Base.Cigarettes" })
    pcall(function() local d = p:getDescriptor(); d:setForename("Jon"); d:setSurname("McKline") end)
    C.profession("POLICE_OFFICER")
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.86, 0.83, 0.76)
    -- the ingredients in his bag, a pot of water in hand's reach, a pot of water on the stove
    local bag = nil
    pcall(function() local wi = p:getWornItems(); for i = 0, wi:size() - 1 do local it = wi:get(i):getItem(); if instanceof(it, "InventoryContainer") then bag = it end end end)
    local into = bag and bag:getInventory() or p:getInventory()
    for _, ft in ipairs({ "Base.Carrots", "Base.Potato", "Base.Cabbage", "Base.Onion", "Base.Salt" }) do local it = into:AddItem(ft); if it then M.added[#M.added + 1] = it end end
    local function water(pot) pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
    local pot = p:getInventory():AddItem("Base.Pot"); if pot then water(pot); M.added[#M.added + 1] = pot end
    local sc = M.stove.obj:getContainer()
    local pot2 = sc and sc:AddItem("Base.Pot"); if pot2 then water(pot2); M.added[#M.added + 1] = pot2 end
    local g = false; pcall(function() g = M.stove.obj:getSquare():haveElectricity() or M.stove.obj:getSquare():hasGridPower() end)
    S.say("dressed; bag " .. tostring(bag and bag:getFullType()) .. "; pots " .. tostring(pot ~= nil) .. "/" .. tostring(pot2 ~= nil) .. "; power at the stove " .. tostring(g))
end)
C.lookAround(S, "S")
S.step(5, function() if M.stove then p:setDir(IsoDirections[M.stove.face]) end end)
C.pointerAway(S)
C.zoom(S, 0.75)
S.step(30, function() C.windows("loot", "loot") end)
-- the World window: Crafting, the oven opened in it, BAKE 175 and started
S.step(60, function() S.say("craft tab " .. tostring(C.worldTab("craft"))) end)
S.step(20, function() if not (M.stove and ST.open(p, M.stove.obj)) then S.say("ERR the oven did not open in the Craft tab") end end)
S.step(90, function() end)
local function platePress(id)
    local w = ZeD_WorldWindow.getWindow()
    for _, z in ipairs((w and w._craftState and w._craftState.zones) or {}) do
        if z.type == "plate" and z.id == id then
            SA.onClick(w, w._craftState, ST.current(p), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
            return true
        end
    end
    S.say("ERR no control " .. id .. " on the plate")
    return false
end
for _, id in ipairs({ "bake", "d1", "d7", "d5", "start" }) do S.step(8, function() platePress(id) end) end
S.step(60, function() local on = false; pcall(function() on = M.stove.obj:Activated() end); S.say("oven on " .. tostring(on)) end)
-- the Character window: Cooking, the stew picked, a carrot and a potato in
local function CS() local w = ZeD_CharacterWindow.getWindow(); return w and w._cook end
local function press(id)
    local w, s = ZeD_CharacterWindow.getWindow(), CS()
    local z = s and s.byId and s.byId[id]
    if not (z and w) then S.say("(no zone " .. id .. ")"); return false end
    CK.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
S.step(30, function() local s = CS(); if s then s.scanAt = -1; s.visAt = nil; s.ingCache = nil end end)
S.poll(10, 60, function() return C.charTab("cooking") end)
S.poll(10, 60, function() local w, s = ZeD_CharacterWindow.getWindow(), CS(); return w._activeTab == "cooking" and s and #s.zones > 0 end)
local key = nil
S.step(20, function() press("cook:dish") end)
S.step(20, function()
    local s = CS()
    local label = (getTextOrNull and getTextOrNull("ContextMenu_EvolvedRecipe_Stew")) or "Stew"
    for _, m in ipairs((s and s.dishGeo and s.dishGeo.modes) or {}) do
        if not key and m.label == label and m.id:sub(1, 5) == "dish:" then key = m.id:sub(6) end
    end
    if not (key and press("cook:pop:dish:" .. key)) then S.say("ERR no Stew in the Dish list"); if s then s.popup = nil end end
end)
S.step(20, function() press("cook:ing:Base.Carrots") end)
S.step(20, function() press("cook:ing:Base.Potato") end)
S.step(30, function()
    local s = CS()
    local fts = {}
    for _, e in ipairs((s and s.plan) or {}) do fts[#fts + 1] = e.ft end
    S.say("dish " .. tostring(s and s.dish) .. " | plan " .. table.concat(fts, ", ") .. " | popup " .. tostring(s and s.popup))
end)
S.step(60, function() end)
C.whenStill(S, function()
    local on = false; pcall(function() on = M.stove.obj:Activated() end)
    S.say("oven on " .. tostring(on) .. " | char tab " .. tostring(ZeD_CharacterWindow.getWindow()._activeTab) .. " | world tab " .. tostring(ZeD_WorldWindow.getWindow()._activeTab))
    C.boxes(S, "mck_kitchen")
    C.shot(S, "mck_kitchen")
end)
S.step(20, function()
    pcall(function() if M.stove.obj:Activated() then M.stove.obj:Toggle() end end)
    pcall(function() ST.unbind(p) end)
    for _, it in ipairs(M.added) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    if M.placed and M.stove then local sq = M.stove.obj:getSquare(); if sq then pcall(function() sq:transmitRemoveItemFromSquare(M.stove.obj) end) end end
    local s = CS(); if s then s.plan, s.popup = {}, nil end
    C.grid(false)
    C.noWindows()
    S.say("put back: the oven off, the pots and ingredients taken away, the grid switch")
end)
S.step(30, function() S.say("DONE") end)
S.run()
