-- ZeDUI/tools/qa/zedqa_trailer.lua  (S124)
-- Animal trailer setup for the QA save. Copy to Zomboid/Lua/zedqa.lua and
-- bump zedqa.go; grep console.txt for "ZEDQA tr". Spawns a Livestock Trailer
-- on clear ground beside the character, loads two sheep, a lamb and two hens
-- (one sheep thirsty and hungry), puts hay in its Food Container and eggs in
-- its Egg Container, opens the lid, stands a ewe and a cow near the back for
-- LOAD FROM HERE, and gives the character water and hay. Run it again to
-- reuse the trailer it made (found by script name within 15 tiles).

local p = getPlayer()
local function say(s) print("ZEDQA tr " .. tostring(s)) end
p:setGodMod(true)

local function breedOf(kind)
    local def = AnimalDefinitions.getDef(kind)
    return def and def:getBreeds():get(0)
end

local function nearestTrailer(r)
    local best, bd = nil, nil
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if v:getScriptName() == "Base.Trailer_Livestock" then
            local dx, dy = v:getX() - p:getX(), v:getY() - p:getY()
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= r and (not bd or d < bd) then best, bd = v, d end
        end
    end
    return best
end

-- a 3x5 patch of free outdoor ground (no objects but the floor, no vehicle)
local function clearPatch()
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for r = 4, 12 do
        for _, o in ipairs({ { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r }, { r, r }, { -r, r }, { r, -r }, { -r, -r } }) do
            local cx, cy = px + o[1], py + o[2]
            local ok = true
            for y = cy - 2, cy + 2 do
                for x = cx - 1, cx + 1 do
                    local sq = getCell():getGridSquare(x, y, 0)
                    if not sq or not sq:isFree(false) or sq:getVehicleContainer() or sq:getObjects():size() > 1
                       or not sq:isOutside() then ok = false end
                end
            end
            if ok then return getCell():getGridSquare(cx, cy, 0) end
        end
    end
    return nil
end

local function give(full, n)
    for _ = 1, n or 1 do
        local ok, it = pcall(function() return p:getInventory():AddItem(full) end)
        if not (ok and it) then say("no item " .. full) return end
    end
end

local v = nil
local n = 0
local function tick()
    n = n + 1
    if n == 1 then
        v = nearestTrailer(15)
        if not v then
            local sq = clearPatch()
            if not sq then say("no clear ground"); Events.OnTick.Remove(tick); return end
            v = addVehicleDebug("Base.Trailer_Livestock", IsoDirections.N, nil, sq)
            say("spawned trailer at " .. sq:getX() .. "," .. sq:getY())
        else
            say("reusing trailer id=" .. v:getId())
        end
    elseif n == 20 and v then
        -- empty it, then load the animals
        local list = v:getAnimals()
        while list:size() > 0 do v:removeAnimalFromTrailer(list:get(0)) end
        local sq = v:getSquare()
        local function load(kind, name, thirst, hunger)
            local a = addAnimal(getCell(), sq:getX(), sq:getY(), 0, kind, breedOf(kind))
            if not a then say("no animal " .. kind) return end
            if name then pcall(function() a:setCustomName(name) end) end
            pcall(function()
                if thirst then a:getStats():set(CharacterStat.THIRST, thirst) end
                if hunger then a:getStats():set(CharacterStat.HUNGER, hunger) end
            end)
            v:addAnimalInTrailer(a)
        end
        load("ewe", "Dolly", 0.6, 0.35)
        load("ram", "Shaun", 0.3, 0)
        load("lamb", nil, 0, 0)
        load("hen", "Clucky", 0, 0)
        load("hen", nil, 0, 0)
        say("animals=" .. v:getAnimals():size() .. " space=" .. v:getCurrentTotalAnimalSize() .. "/" .. v:getAnimalTrailerSize())
        local food = v:getPartById("TrailerAnimalFood")
        local fc = food and food:getItemContainer()
        if fc and fc:getItems():size() == 0 then for _ = 1, 4 do fc:AddItem("Base.HayTuft") end end
        local eggs = v:getPartById("TrailerAnimalEggs")
        local ec = eggs and eggs:getItemContainer()
        if ec and ec:getItems():size() == 0 then for _ = 1, 3 do ec:AddItem("Base.Egg") end end
        local lid = v:getPartById("TrunkDoor") or v:getPartById("DoorRear") or v:getPartById("TrunkDoorOpened")
        if lid and lid:getDoor() then lid:getDoor():setLocked(false); lid:getDoor():setOpen(true) end
        say("lid=" .. tostring(lid and lid:getId()) .. " open=" .. tostring(lid and lid:getDoor() and lid:getDoor():isOpen()))
        -- a ewe and a cow standing near the back for LOAD FROM HERE
        local vec = v:getAreaCenter("AnimalEntry")
        local bx, by = math.floor(vec:getX()), math.floor(vec:getY())
        local ewe = addAnimal(getCell(), bx + 2, by, 0, "ewe", breedOf("ewe"))
        local cow = addAnimal(getCell(), bx - 3, by + 1, 0, "cow", breedOf("cow"))
        say("back at " .. bx .. "," .. by .. " ewe=" .. tostring(ewe ~= nil) .. " cow=" .. tostring(cow ~= nil))
        give("Base.WaterBottle"); give("Base.HayTuft", 3)
        local wb = p:getInventory():getFirstType("Base.WaterBottle")
        local wfc = wb and wb:getFluidContainer()
        if wfc then wfc:Empty(); wfc:addFluid(Fluid.Water, wfc:getCapacity()) end
    elseif n == 40 then
        say("setup done trailer id=" .. tostring(v and v:getId()))
        Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
