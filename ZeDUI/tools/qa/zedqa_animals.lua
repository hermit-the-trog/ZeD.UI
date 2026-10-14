-- ZeDUI/tools/qa/zedqa_animals.lua  (S124)
-- Animal cards setup for the QA save. Copy to Zomboid/Lua/zedqa.lua and bump
-- zedqa.go; grep console.txt for "ZEDQA an". Builds around the character
-- (build cheat, Q155): a hen house with three hens (one sitting in a box),
-- eggs and a dead hen, a metal trough with feed, a butcher hook, a dead cow
-- beside the hook, an animal zone over all of it, and the tools (knife,
-- bucket, broom, water bottle, hay). The character must stand on open ground.

local p = getPlayer()
local function say(s) print("ZEDQA an " .. tostring(s)) end
p:setGodMod(true)

local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end

local function spawnNear(full, offsets)
    local info = findInfo(full)
    if not info then say("no info " .. full); return nil end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for _, o in ipairs(offsets) do
        p:setBuildCheat(true)
        local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
        b.buildCheat = true
        b.player = p:getPlayerNum()
        local sq = getCell():getGridSquare(px + o[1], py + o[2], 0)
        local ok, valid = pcall(function() b.sq = sq; return b:isValid(sq) end)
        if ok and valid then
            pcall(function() b:create(px + o[1], py + o[2], 0, false, nil) end)
            p:setBuildCheat(false)
            say("spawned " .. full .. " at " .. (px + o[1]) .. "," .. (py + o[2]))
            return sq
        end
    end
    p:setBuildCheat(false)
    say("no room for " .. full)
    return nil
end

local function findAround(cls, r)
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for y = py - r, py + r do
        for x = px - r, px + r do
            local sq = getCell():getGridSquare(x, y, 0)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    if instanceof(objs:get(i), cls) then return objs:get(i) end
                end
            end
        end
    end
end

local function breedOf(kind)
    local def = AnimalDefinitions.getDef(kind)
    return def and def:getBreeds():get(0)
end

local function give(full, n)
    for _ = 1, n or 1 do
        local ok, it = pcall(function() return p:getInventory():AddItem(full) end)
        if not (ok and it) then say("no item " .. full) return end
    end
end

local n = 0
local function tick()
    n = n + 1
    if n == 1 then
        if not findAround("IsoHutch", 10) then spawnNear("Base.ChickenHutch", { { 2, -3 }, { -3, -3 }, { 2, 1 }, { -3, 1 }, { 4, -4 }, { 5, 3 } }) end
        if not findAround("IsoFeedingTrough", 10) then spawnNear("Base.FeedingTroughDoubleMetal", { { -3, 3 }, { 3, 3 }, { 0, 3 }, { -4, 0 }, { 4, 0 } }) end
        if not findAround("IsoButcherHook", 10) then spawnNear("Base.ButcherHook", { { -3, -2 }, { 3, -2 }, { -2, 3 }, { 2, -3 } }) end
    elseif n == 30 then
        local h = findAround("IsoHutch", 10)
        local t = findAround("IsoFeedingTrough", 10)
        local k = findAround("IsoButcherHook", 10)
        say("found hutch=" .. tostring(h ~= nil) .. " trough=" .. tostring(t ~= nil) .. " hook=" .. tostring(k ~= nil))
        if h then
            h = h:getHutch() or h
            local hen = breedOf("hen")
            for i = 1, 3 do
                local a = addAnimal(getCell(), 0, 0, 0, "hen", hen)
                a:getData():setPreferredHutchPosition(i - 1)
                h:addAnimalInside(a)
            end
            local sitter = addAnimal(getCell(), 0, 0, 0, "hen", hen)
            h:addAnimalInNestBox(sitter)
            for b = 0, 2 do
                local nest = h:getNestBox(b)
                if nest then for e = 1, (b == 0 and 4 or 2) do nest:addEgg(instanceItem("Base.Egg")) end end
            end
            h:setHutchDirt(46)
            local dead = h:getAnimal(2)
            if dead then h:killAnimal(dead) end
            say("hutch birds=" .. h:getAnimalInside():size() .. " dirt=" .. h:getHutchDirt())
        end
        if t then pcall(ISFeedingTroughMenu.onAddFoodDebug, p, t) say("trough fed") end
        if k then
            local ksq = k:getSquare()
            local cow = addAnimal(getCell(), ksq:getX() + 1, ksq:getY() + 1, 0, "cow", breedOf("cow"))
            if cow then cow:setHealth(0) say("cow killed") end
        end
        -- an animal zone over the yard
        local px, py = math.floor(p:getX()), math.floor(p:getY())
        local ok, zerr = pcall(function() DesignationZoneAnimal.new("QA Yard", px - 8, py - 8, 0, px + 8, py + 8, true) end)
        say("zone ok=" .. tostring(ok) .. " " .. tostring(zerr or ""))
        give("Base.HuntingKnife"); give("Base.Bucket"); give("Base.Broom"); give("Base.WaterBottle"); give("Base.HayTuft", 3); give("Base.AnimalFeedBag")
        local wb = p:getInventory():getFirstType("Base.WaterBottle")
        local fc = wb and wb:getFluidContainer()
        if fc then fc:Empty(); fc:addFluid(Fluid.Water, fc:getCapacity()) end
    elseif n == 60 then
        say("setup done")
        Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
