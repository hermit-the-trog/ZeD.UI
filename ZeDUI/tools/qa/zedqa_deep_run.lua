-- ZeDUI/tools/qa/zedqa_deep_run.lua  (Oct 23 2026)
-- A deep-run fixture for the ZeD-QA save (director: "the character you test
-- with needs to be deep into a run, stocked up ... FILL THE MENUS to stress
-- test and use for navigation planning"). Through the bridge, in game, on the
-- QA save's open field (where the character stands the first time it runs):
--   * protections first: god mode, invisible, invincible; no zombie near;
--   * the character: many traits (good and bad; Strong and Organized for
--     carrying), Strength 10, every other skill from high to low with XP
--     partway into the level, many known recipes, months survived, kills by
--     weapon kind, journal entries, flyers read, map notes;
--   * within reach (the 3 x 3 the World window lists and the Radio tab scans):
--     a crate, a fridge, shelves with a TV, a counter with a radio, a corpse,
--     a pile on the ground with a bucket of water, a car backed up with its
--     trunk at hand;
--   * further off, an object for every card: a fuelled connected generator,
--     a lit campfire, farm plots at four stages, a trough and a rain collector
--     with water, a well, a padlocked door (and a padlocked crate), hens and a
--     cow, crafting stations;
--   * worn: a full outfit, a backpack and a fanny pack, a belt with holster and
--     sheath, a watch, an axe and a torch in hand; the long, varied inventory
--     (food fresh / stale / rotten / cooked / canned, weapons, ammo, tools,
--     medical, books, maps, liquids, clothing, stacks, a purse inside the
--     backpack) goes where it fits: the bags first, then the crate, shelves,
--     counter, fridge, the car's trunk, the ground. The character ends under
--     their carry limit (no Heavy Load); both weights are logged;
--   * last, health: a bandaged scratch, a splinted fracture, one untreated
--     scratch (no infection), moderate fatigue. Nothing bleeds, nothing deep.
--     God mode heals every wound at once, so for the wounds to show it is
--     turned off here, after invincible is on (nothing can hurt the character).
-- Idempotent: each part records itself in the character's mod data
-- (ZeDDeepRun) and is skipped once done; the protections, the weight check
-- and the wounds are fixed values set again on every run, so a second run
-- changes nothing. The state is saved when the game quits (the runner's quit
-- goes through the main menu). Not for the unattended regression (it changes
-- the save on purpose): run it by hand after the prelude, before the pad map.
-- grep "ZEDQA deep".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA deep " .. tostring(s)) end
local VERSION = 3
local md = p:getModData()
md.ZeDDeepRun = md.ZeDDeepRun or { v = VERSION, done = {} }
md.ZeDDeepRun.done = md.ZeDDeepRun.done or {}
local DONE = md.ZeDDeepRun.done
local missing = {}
local function miss(what) missing[#missing + 1] = what; say("MISS " .. what) end
-- DONE a tick later: the runner counts a DONE only after the bridge's own
-- "run #" line, which comes once this chunk has returned (Oct 23: a DONE
-- printed here and now read as a 180 s timeout); and only once the parts that
-- finish on a later tick (the map marks) are done, so the next script starts
-- on the whole scene
local pending = 0
local function done()
    local function later()
        if pending > 0 then return end
        Events.OnTick.Remove(later); say("DONE")
    end
    Events.OnTick.Add(later)
end

-- ---------------------------------------------------------------- protections first
local function clearZombies()
    local list = getCell():getZombieList()
    local n = 0
    for i = list:size() - 1, 0, -1 do
        local z = list:get(i)
        if z then n = n + 1; pcall(function() z:removeFromWorld() end); pcall(function() z:removeFromSquare() end) end
    end
    return n
end
if p:isDead() then say("MISS the character is dead: make the QA save again (zedqa_new_qa_save.lua)"); done(); return end
p:setGodMod(true)
p:setInvisible(true)
pcall(function() p:setInvincible(true) end)
local nz = clearZombies()

-- the scene's home: where the character stood the first time (the QA save's
-- open field). Each run puts them back there, so the 3 x 3 stays at hand; from
-- far off (Oct 23: the full regression left them 140 tiles away) the parts
-- wait below until home's squares have loaded.
local home = md.ZeDDeepRun.home or { x = math.floor(p:getX()), y = math.floor(p:getY()) }
md.ZeDDeepRun.home = home
local dHome = math.max(math.abs(p:getX() - (home.x + 0.5)), math.abs(p:getY() - (home.y + 0.5)))
if dHome > 0.6 then pcall(function() p:teleportTo(home.x + 0.5, home.y + 0.5, 0) end) end
local px, py = home.x, home.y
local function at(dx, dy) return getCell():getGridSquare(px + dx, py + dy, 0) end

local function exists(full) return getScriptManager():FindItem(full) ~= nil end
local function give(inv, full, n)
    if not exists(full) then miss("item " .. full); return nil end
    local last
    for _ = 1, n or 1 do
        local ok, it = pcall(function() return inv:AddItem(full) end)
        if ok and it then last = it end
    end
    return last
end
local function fill(inv, list)
    for _, it in ipairs(list) do give(inv, it[1], it[2] or 1) end
end

-- open squares around home, nearest first, none used twice (the 3 x 3 kept for the near scene)
local used = {}
for dy = -1, 1 do for dx = -1, 1 do used[(px + dx) .. "," .. (py + dy)] = true end end
local function clearSq(sq)
    if not (sq and sq:isFree(false)) then return false end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if not o:isFloor() then
            local spr = o:getSprite() and o:getSprite():getName() or ""
            if not (spr:find("blends_natural") or spr:find("vegetation_groundcover")) then return false end
        end
    end
    return sq:getStaticMovingObjects():size() == 0 and sq:getWorldObjects():size() == 0
end
local function spot(minR, maxR)
    for r = minR, maxR do
        for dy = -r, r do for dx = -r, r do
            if math.max(math.abs(dx), math.abs(dy)) == r then
                local key = (px + dx) .. "," .. (py + dy)
                local sq = at(dx, dy)
                if not used[key] and clearSq(sq) then used[key] = true; return sq end
            end
        end end
    end
    return nil
end

local function findInfo(pat, exact)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        local full = parent and tostring(parent:getScriptObjectFullType()) or ""
        if (exact and full == pat) or ((not exact) and full:lower():find(pat:lower(), 1, true)) then return info, full end
    end
end
local function build(pat, sq, exact)
    local info, full = findInfo(pat, exact)
    if not (info and sq) then return nil end
    local before = sq:getObjects():size()
    p:setBuildCheat(true)
    pcall(function()
        local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
        b.buildCheat = true; b.player = pn; b.sq = sq
        if b:isValid(sq) then b:create(sq:getX(), sq:getY(), 0, false, nil) end
    end)
    p:setBuildCheat(false)
    local objs = sq:getObjects()
    if objs:size() <= before then return nil end
    return objs:get(objs:size() - 1), full
end
local function tileObject(sq, sprites)
    for _, name in ipairs(sprites) do
        if sq and getSprite(name) then
            local o = IsoObject.new(sq, name, nil, false)
            sq:AddTileObject(o)
            pcall(function() o:createContainersFromSpriteProperties() end)
            if o:getContainer() then return o, name end
            sq:transmitRemoveItemFromSquare(o)   -- (not a container tile: try the next)
        end
    end
    return nil
end
local function placed(tag, obj)
    if obj then pcall(function() obj:getModData().ZeDDeepRun = tag end) end
    return obj ~= nil
end
local function tagged(tag)
    for dy = -1, 1 do for dx = -1, 1 do
        local sq = at(dx, dy)
        local objs = sq and sq:getObjects()
        for i = 0, (objs and objs:size() or 0) - 1 do
            local o = objs:get(i)
            local t
            pcall(function() t = o:getModData().ZeDDeepRun end)
            if t == tag then return o end
        end
    end end
end
local function nearCar()
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local t
        pcall(function() t = v:getModData().ZeDDeepRun end)
        if t == "near_car" then return v end
    end
end

local parts = {}
local function part(name, fn, always) parts[#parts + 1] = { name = name, fn = fn, always = always } end

-- ---------------------------------------------------------------- the character
part("traits", function()
    local names = { "STRONG", "ORGANIZED", "FAST_LEARNER", "FIT", "KEEN_HEARING", "EAGLE_EYED", "LUCKY", "OUTDOORSMAN",
        "GRACEFUL", "DEXTROUS", "INVENTIVE", "NIGHT_OWL", "IRON_GUT", "FAST_HEALER", "BRAVE", "HANDY",
        "SMOKER", "CLUMSY", "HIGH_THIRST", "SLOW_READER", "PRONE_TO_ILLNESS", "CONSPICUOUS", "HEMOPHOBIC",
        "SHORT_SIGHTED", "THIN_SKINNED", "WEAK_STOMACH", "ALL_THUMBS", "HEARTY_APPETITE", "SLEEPYHEAD", "AGORAPHOBIC" }
    local n = 0
    for _, k in ipairs(names) do
        local t = CharacterTrait and CharacterTrait[k]
        if t and pcall(function() if not p:getCharacterTraits():get(t) then p:getCharacterTraits():add(t) end end) then n = n + 1 end
    end
    return n >= 10, n .. " traits (Strong and Organized among them)"
end)
part("skills", function()
    local list = PerkFactory.PerkList
    local n, i = 0, 0
    for k = 0, list:size() - 1 do
        local perk = list:get(k)
        if perk and perk:getParent() ~= Perks.None and perk ~= Perks.None then
            i = i + 1
            local lvl = (i * 7) % 11
            if perk == Perks.Strength then lvl = 10 elseif perk == Perks.Fitness then lvl = 9 end
            pcall(function() p:setPerkLevelDebug(perk, lvl) end)
            pcall(function() p:getXp():setXPToLevel(perk, lvl) end)
            if lvl < 10 then
                pcall(function()
                    local need = perk:getXpForLevel(lvl + 1) or 0
                    if need > 0 then p:getXp():AddXP(perk, need * 0.45, false, false, false) end
                end)
            end
            n = n + 1
        end
    end
    return n > 10, n .. " skills set, Strength " .. p:getPerkLevel(Perks.Strength)
end)
part("recipes", function()
    local all = getScriptManager():getAllCraftRecipes()
    local n = 0
    for k = 0, all:size() - 1 do
        local r = all:get(k)
        local ok, need = pcall(function() return r:needToBeLearn() end)
        if ok and need and (k % 2 == 0) and pcall(function() p:learnRecipe(r:getName()) end) then n = n + 1 end
    end
    return n > 0, n .. " recipes learned"
end)
part("time", function()
    pcall(function() p:setHoursSurvived(24 * 96 + 7) end)
    pcall(function() p:setZombieKills(318) end)
    local kd = md.ZeD_Kills or {}
    md.ZeD_Kills = kd
    kd.weapon = { Blunt = 74, SmallBlunt = 31, LongBlade = 22, SmallBlade = 40, Axe = 88, Spear = 12, Firearm = 37, Unarmed = 6, Other = 8 }
    kd.fire, kd.vehicle, kd.explosion = 14, 23, 3
    md.ZeD_Journal = md.ZeD_Journal or { entries = {} }
    local texts = {
        "found the gas station empty. took the map and two cans of beans",
        "rain all day. fixed the fence on the north side, ran out of nails",
        "the cow is doing better. hens laid four eggs",
        "saw smoke to the east. not going",
        "generator needs fuel every 3 days. 2 cans left",
        "planted tomatoes and cabbages by the shed",
        "my arm still hurts. changed the bandage",
        "cleared the house on the corner. nothing but a crowbar",
        "read the carpentry book, finally get how the joints work",
        "radio said nothing again",
        "traded nothing with nobody. talked to the cow",
        "woke up at 3, could not sleep. cleaned the shotgun",
    }
    for i, t in ipairs(texts) do
        local has = false
        for _, e in ipairs(md.ZeD_Journal.entries) do if e.text == t then has = true end end
        if not has then
            table.insert(md.ZeD_Journal.entries, { month = (i % 3) + 6, day = (i * 5) % 28, year = 1993, hour = (i * 3) % 24,
                minute = (i * 13) % 60, survivalDay = i * 8, text = t })
        end
    end
    return true, "96 days, 318 kills, " .. #md.ZeD_Journal.entries .. " journal entries"
end)
part("flyers", function()
    local n = 0
    for id, _ in pairs(PrintMediaDefinitions.MiscDetails) do
        if n >= 14 then break end
        pcall(function() if not p:getReadPrintMedia():contains(id) then p:addReadPrintMedia(id) end end)
        n = n + 1
    end
    return n > 0, p:getReadPrintMedia():size() .. " flyers read"
end)

-- ---------------------------------------------------------------- within reach
part("near", function()
    local got = {}
    -- (reach goes round solid things: a corner square is open only while a
    -- side next to it is, so the corpse lies north, the solid containers on
    -- the corners and sides, the car to the south)
    local c = build("Base.Wood_Crate_Lvl1", at(-1, -1), true)
    if c and c:getContainer() then
        placed("near_crate", c); got[#got + 1] = "crate"
        fill(c:getContainer(), { { "Base.TinnedBeans", 2 }, { "Base.Plank", 3 }, { "Base.Bleach" }, { "Base.Sheet" }, { "Base.BookCarpentry2" } })
    end
    local f = tileObject(at(-1, 0), { "appliances_refrigeration_01_0", "appliances_refrigeration_01_4" })
    if f then
        placed("near_fridge", f); got[#got + 1] = "fridge"
        fill(f:getContainerByType("fridge") or f:getContainer(), { { "Base.Milk" }, { "Base.Cheese" }, { "Base.Egg", 6 }, { "Base.Butter" }, { "Base.Steak", 2 }, { "Base.Chicken" } })
    end
    local s = tileObject(at(1, -1), { "furniture_shelving_01_19", "furniture_shelving_01_23" })
    if s then
        placed("near_shelves", s); got[#got + 1] = "shelves"
        fill(s:getContainer(), { { "Base.CannedCorn", 3 }, { "Base.TinnedSoup", 2 }, { "Base.Pasta", 2 }, { "Base.Rice" }, { "Base.Sugar" } })
    end
    local k = tileObject(at(1, 0), { "fixtures_counters_01_0", "fixtures_counters_01_8" })
    if k then
        placed("near_counter", k); got[#got + 1] = "counter"
        fill(k:getContainer(), { { "Base.KitchenKnife" }, { "Base.Pan" }, { "Base.Spoon", 3 }, { "Base.Fork", 3 }, { "Base.DishCloth", 2 }, { "Base.Kettle" } })
    end
    -- a radio on the counter, a TV on the shelves (the Radio tab scans the 3 x 3)
    pcall(function()
        for _, name in ipairs({ "appliances_radio_01_0", "appliances_radio_01_8" }) do
            if getSprite(name) then local r = IsoRadio.new(getCell(), at(1, 0), getSprite(name)); at(1, 0):AddTileObject(r); got[#got + 1] = "radio"; break end
        end
    end)
    pcall(function()
        for _, name in ipairs({ "appliances_television_01_0", "appliances_television_01_4" }) do
            if getSprite(name) then local t = IsoTelevision.new(getCell(), at(1, -1), getSprite(name)); at(1, -1):AddTileObject(t); got[#got + 1] = "tv"; break end
        end
    end)
    -- a corpse to the north
    pcall(function()
        local z = createZombie(px + 0.5, py - 1 + 0.5, 0, nil, 0, IsoDirections.S)
        z:dressInRandomOutfit()
        z:DoZombieInventory()
        local body = IsoDeadBody.new(z, false)
        pcall(function() z:removeFromWorld(); z:removeFromSquare() end)
        if body and body:getContainer() then fill(body:getContainer(), { { "Base.Wallet" }, { "Base.CigarettePack" }, { "Base.Lighter" } }) end
        got[#got + 1] = "corpse"
    end)
    -- a pile at the character's feet, a bucket of water in it
    for i, full in ipairs({ "Base.Plank", "Base.Saw", "Base.Log", "Base.Bag_Schoolbag", "Base.Apple", "Base.Bucket" }) do
        pcall(function()
            local it = at(0, 0):AddWorldInventoryItem(full, 0.15 + (i % 3) * 0.3, 0.2 + math.floor(i / 3) * 0.3, 0)
            if full == "Base.Bucket" and it and it:getFluidContainer() then
                local fc = it:getFluidContainer(); fc:addFluid(FluidType.Water, fc:getCapacity() * 0.7)
            end
        end)
    end
    got[#got + 1] = "ground pile"
    clearZombies()   -- (the corpse's stand-in)
    return #got >= 6, table.concat(got, ", ")
end)
part("near_car", function()
    -- backed up to the character: facing south, its trunk at the south edge of the 3 x 3
    local ok, car = pcall(function() return addVehicleDebug("Base.CarNormal", IsoDirections.S, nil, at(0, 3)) end)
    if not (ok and car) then return false, "no car" end
    pcall(function() car:getModData().ZeDDeepRun = "near_car" end)
    pcall(function()
        local gb = car:getPartById("GloveBox")
        if gb and gb:getItemContainer() then fill(gb:getItemContainer(), { { "Base.Map" }, { "Base.Lighter" }, { "Base.Pen" }, { "Base.CigarettePack" } }) end
    end)
    return true, string.format("a car at %.1f,%.1f facing south", car:getX(), car:getY())
end)

-- ---------------------------------------------------------------- objects for every card
part("generator", function()
    local sq = spot(3, 6)
    if not sq then return false, "no square" end
    local ok, err = pcall(function()
        local g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq)
        g:setConnected(true)
        g:setFuel(72)
        pcall(function() g:setCondition(85) end)
        pcall(function() g:setActivated(true) end)
        placed("generator", g)
    end)
    return ok, ok and "generator (fuel 72, connected, on)" or tostring(err)
end)
part("campfire", function()
    local sq = spot(3, 6)
    if not sq then return false, "no square" end
    local ok, err = pcall(function()
        local lo = SCampfireSystem.instance:addCampfire(sq)
        lo:addFuel(120)
        lo:lightFire()
    end)
    return ok, ok and "campfire lit" or tostring(err)
end)
part("farm", function()
    local n = 0
    for stage = 1, 4 do
        local sq = spot(3, 7)
        if sq and pcall(function()
            SFarmingSystem.instance:plow(sq)
            local lo = SFarmingSystem.instance:getLuaObjectAt(sq:getX(), sq:getY(), 0)
            lo:seed(({ "Tomato", "Cabbage", "Carrots", "Potato" })[stage])
            for _ = 1, (stage - 1) * 2 do SFarmingSystem.instance:growPlant(lo, nil, true) end
            pcall(function() lo.waterLvl = 60 end)
        end) then n = n + 1 end
    end
    return n >= 2, n .. " farm plots (seeded, growing, grown)"
end)
part("trough", function()
    local o, full = build("Trough", spot(3, 7))
    if not o then return false, "no trough entity" end
    pcall(function() local fc = o:getFluidContainer(); if fc then fc:addFluid(FluidType.Water, fc:getCapacity() * 0.7) end end)
    return true, tostring(full) .. " with water"
end)
part("rain2", function()
    -- the first rain collector the build list has that builds here (some
    -- need a recipe the build cheat does not pass)
    local infos = SpriteConfigManager.GetObjectInfoList()
    local sq = spot(3, 7)
    for i = 0, infos:size() - 1 do
        local parent = infos:get(i):getScript() and infos:get(i):getScript():getParent()
        local full = parent and tostring(parent:getScriptObjectFullType()) or ""
        if full:find("RainCollector", 1, true) then
            local o = build(full, sq, true)
            if o then
                pcall(function() local fc = o:getFluidContainer(); if fc then fc:addFluid(FluidType.Water, fc:getCapacity() * 0.6) end end)
                return true, full .. " with water"
            end
        end
    end
    return false, "no rain collector builds here"
end)
part("water", function()
    -- more liquid sources on the ground: a pot of water, a bucket of dirty water, a jug of milk
    local sq = spot(2, 4)
    if not sq then return false, "no square" end
    local n = 0
    for i, it in ipairs({ { "Base.Bucket", "TaintedWater", 0.8 }, { "Base.Pot", "Water", 0.6 }, { "Base.WaterBottle", "Water", 1 } }) do
        if pcall(function()
            local item = sq:AddWorldInventoryItem(it[1], 0.2 + i * 0.25, 0.5, 0)
            local fc = item:getFluidContainer()
            fc:Empty(); fc:addFluid(FluidType[it[2]] or FluidType.Water, fc:getCapacity() * it[3])
        end) then n = n + 1 end
    end
    return n >= 2, n .. " liquid containers on the ground (the well needs a recipe the build cheat does not pass)"
end)
part("door", function()
    local sq = spot(3, 7)
    if not sq then return false, "no square" end
    build("Base.WoodDoorFrameLvl1", sq, true)
    build("Base.WoodenDoorLvl1", sq, true)
    local door
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoThumpable") and o:isDoor() then door = o end
    end
    if not door then return false, "no door" end
    pcall(function() door:setLockedByPadlock(true); door:setKeyId(727272) end)
    placed("door", door)
    local c = build("Base.Wood_Crate_Lvl1", spot(2, 6), true)
    if c then pcall(function() c:setLockedByPadlock(true); c:setKeyId(626262) end); placed("padlock", c) end
    return true, "a padlocked door in a frame, a padlocked crate"
end)
part("animals", function()
    local function breedOf(kind)
        local def = AnimalDefinitions.getDef(kind)
        return def and def:getBreeds():get(0)
    end
    local n = 0
    for _, kind in ipairs({ "hen", "hen", "hen", "cow" }) do
        local sq = spot(4, 9)
        if sq and pcall(function() addAnimal(getCell(), sq:getX(), sq:getY(), 0, kind, breedOf(kind)):addToWorld() end) then n = n + 1 end
    end
    return n >= 2, n .. " animals"
end)
part("stations", function()
    local n, got = 0, {}
    for _, pat in ipairs({ "Base.Kiln_Small", "Base.Pottery_Wheel", "Base.Herb_Drying_Rack", "Base.Pottery_Bench" }) do
        local o, full = build(pat, spot(3, 8), true)
        if o then n = n + 1; got[#got + 1] = tostring(full) end
    end
    return n >= 2, n .. " stations " .. table.concat(got, ", ")
end)
part("hutch_hook", function()
    -- the hutch and butcher hook cards (the pad map opens every card; animal
    -- tracks come only from the game's migrating animals, so none is staged)
    local got = {}
    if build("Base.ChickenHutch", spot(4, 9), true) then got[#got + 1] = "hutch" end
    if build("Base.ButcherHook", spot(3, 8), true) then got[#got + 1] = "butcher hook" end
    return #got == 2, #got .. " of 2 built: " .. table.concat(got, ", ")
end)
part("hutch2", function()
    -- (Oct 23: the hutch did not fit on the first square tried; it takes more
    -- than one tile) more squares, both hutches; within the card's reach of
    -- home (its nearby list looks 6 squares out)
    for _ = 1, 16 do
        local sq = spot(4, 6)
        if not sq then break end
        for _, full in ipairs({ "Base.ChickenHutch", "Base.ChickenHutch2" }) do
            if build(full, sq, true) then return true, full .. " at " .. sq:getX() .. "," .. sq:getY() end
        end
    end
    return false, "no hutch fits within 6 squares"
end)
part("notes", function()
    -- the map's store needs the World window's map once: opened here, the
    -- marks go in a moment later. Every run puts back any that went missing
    -- (Oct 23: the map notes test's Delete at the map's centre took one)
    pcall(function() ZeD_WorldWindow.openTab(pn, "maps") end)
    local n = 0
    local function later()
        n = n + 1
        if n < 90 then return end
        Events.OnTick.Remove(later)
        local ok, err = pcall(function()
        local N = ZeD.MapNotes
        local api = N.api()
        local function hasSym(id, wx, wy)
            for i = 0, (api and api:getSymbolCount() or 0) - 1 do
                local s = api:getSymbolByIndex(i)
                if s:isUserDefined() and s:isTexture() and s:getSymbolID() == id
                   and math.abs(s:getWorldX() - wx) < 0.5 and math.abs(s:getWorldY() - wy) < 0.5 then return true end
            end
            return false
        end
        local made = 0
        for i, t in ipairs({ { "house on the corner: cleared", 12, -8 }, { "gas station: empty", -30, 20 }, { "zeds on the bridge", 45, 40 },
            { "water tower, fill bottles", -18, -25 }, { "car with keys??", 25, -15 } }) do
            if not N.findByText(t[1]) and pcall(function() N.addNote(t[1], px + t[2], py + t[3], (i % 4) + 1) end) then made = made + 1 end
        end
        for _, s in ipairs({ { "Star", 5, 5, 1 }, { "Skull", 40, 38, 2 } }) do
            if not hasSym(s[1], px + s[2], py + s[3]) and pcall(function() N.addSymbol(s[1], px + s[2], py + s[3], s[4]) end) then made = made + 1 end
        end
        say("notes: " .. made .. " put in (of 5 notes and 2 marks)")
        end)
        if not ok then say("MISS notes: " .. tostring(err)) end
        pcall(function() ZeD_WorldWindow.openTab(pn, "loot") end)
        pending = pending - 1   -- (whatever happened: DONE waits on this)
    end
    pending = pending + 1
    Events.OnTick.Add(later)
    return true, "map notes (in a moment)"
end, true)

-- ---------------------------------------------------------------- worn, and the long inventory where it fits
local function wornBags()
    local bags = {}
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:get(i):getItem()
        if it and it:IsInventoryContainer() then bags[#bags + 1] = it:getInventory() end
    end
    return bags
end
local function limit() return p:getMaxWeight() * 0.85 end
-- one thing where it fits: on the person (only when asked and light enough),
-- a worn bag with room, the crate / shelves / counter / fridge / trunk, else
-- the ground at the character's feet
local function stow(full, n, onPerson, f)
    if not exists(full) then miss("item " .. full); return end
    local dests = {}
    for _, b in ipairs(wornBags()) do dests[#dests + 1] = b end
    for _, tag in ipairs({ "near_crate", "near_shelves", "near_counter", "near_fridge" }) do
        local o = tagged(tag)
        if o and o:getContainer() then dests[#dests + 1] = o:getContainer() end
    end
    local car = nearCar()
    local tb = car and car:getPartById("TruckBed")
    if tb and tb:getItemContainer() then dests[#dests + 1] = tb:getItemContainer() end
    for _ = 1, n or 1 do
        local item = instanceItem(full)
        if item then
            if f then pcall(f, item) end
            local inv = p:getInventory()
            local done = false
            if onPerson and p:getInventoryWeight() + item:getWeight() <= limit() * 0.6 then inv:AddItem(item); done = true end
            for _, c in ipairs(dests) do
                if done then break end
                if c:hasRoomFor(p, item) then
                    c:AddItem(item)
                    if p:getInventoryWeight() > limit() then c:Remove(item) else done = true end
                end
            end
            if not done then pcall(function() at(0, 0):AddWorldInventoryItem(item, 0.5, 0.5, 0) end) end
        end
    end
end
part("worn", function()
    local inv = p:getInventory()
    local n = 0
    for _, full in ipairs({ "Base.Tshirt_DefaultTEXTURE", "Base.Shirt_Lumberjack", "Base.Trousers_Denim", "Base.Socks_Ankle", "Base.Shoes_ArmyBoots",
        "Base.Jacket_Padded", "Base.Hat_BaseballCap", "Base.Gloves_LeatherGloves", "Base.Belt2", "Base.HolsterSimple",
        "Base.WristWatch_Left_DigitalBlack", "Base.Glasses_Normal", "Base.Bag_ALICEpack", "Base.Bag_FannyPackFront" }) do
        local it = give(inv, full)
        if it then
            local ok = pcall(function()
                if it:IsInventoryContainer() and it:canBeEquipped() and it:canBeEquipped() ~= "" then
                    p:setWornItem(it:canBeEquipped(), it)
                else
                    p:setWornItem(it:getBodyLocation(), it)
                end
            end)
            if ok then n = n + 1 else miss("wear " .. full) end
        end
    end
    pcall(function() p:setPrimaryHandItem(give(inv, "Base.Axe")) end)
    pcall(function() p:setSecondaryHandItem(give(inv, "Base.HandTorch")) end)
    -- the belt's slots: a hammer and a knife, a pistol in the holster
    local hb = getPlayerHotbar and getPlayerHotbar(pn)
    if hb then
        pcall(function() hb:refresh() end)
        for _, full in ipairs({ "Base.Hammer", "Base.HuntingKnife", "Base.Pistol" }) do
            local it = give(inv, full)
            if it then
                pcall(function()
                    for slotIdx, slot in pairs(hb.availableSlot or {}) do
                        if not hb.attachedItems[slotIdx] and hb:canBeAttached(slot, it) then
                            hb:attachItem(it, slot.def.attachments[it:getAttachmentType()], slotIdx, slot.def, false)
                            break
                        end
                    end
                end)
            end
        end
    end
    p:resetModelNextFrame()
    return n >= 8, n .. " worn, axe and torch in hand, belt slots filled"
end)
part("bag", function()
    -- on the person: a little of what one carries; the rest where it fits
    for _, it in ipairs({ { "Base.Bandage", 3 }, { "Base.WaterBottle" }, { "Base.Lighter" }, { "Base.Matches" }, { "Base.Map" },
        { "Base.Pencil" }, { "Base.Notebook" }, { "Base.TinnedBeans" }, { "Base.Apple", 2 }, { "Base.9mmClip" } }) do
        stow(it[1], it[2], true)
    end
    for _, it in ipairs({ { "Base.Banana", 2 }, { "Base.Bread" }, { "Base.TinnedBeans", 3 }, { "Base.CannedCorn", 2 },
        { "Base.TinnedSoup", 2 }, { "Base.Crisps" }, { "Base.Crisps2" }, { "Base.PopBottle" },
        { "Base.Bandage", 4 }, { "Base.AlcoholWipes", 3 }, { "Base.Pills" }, { "Base.PillsAntiDep" }, { "Base.SutureNeedle", 2 },
        { "Base.Disinfectant" }, { "Base.Splint" }, { "Base.Battery", 4 }, { "Base.Nails", 30 }, { "Base.Screws", 20 },
        { "Base.DuctTape", 2 }, { "Base.Glue" }, { "Base.Rope", 2 }, { "Base.Screwdriver" }, { "Base.Saw" }, { "Base.Wrench" },
        { "Base.Crowbar" }, { "Base.BaseballBat" }, { "Base.Bullets9mmBox", 2 }, { "Base.ShotgunShellsBox", 2 }, { "Base.Shotgun" },
        { "Base.Book" }, { "Base.BookCarpentry1" }, { "Base.BookCooking2" }, { "Base.Magazine" }, { "Base.HottieZ" },
        { "Base.ComicBook" }, { "Base.Newspaper" }, { "Base.MuldraughMap" }, { "Base.Pen" }, { "Base.Socks_Ankle", 2 },
        { "Base.Tshirt_DefaultTEXTURE", 2 }, { "Base.Trousers_Denim" }, { "Base.Sheet", 2 }, { "Base.RippedSheets", 8 },
        { "Base.Thread", 3 }, { "Base.Needle" }, { "Base.Plank", 4 }, { "Base.Log" }, { "Base.TreeBranch2", 5 }, { "Base.Twigs", 6 },
        { "Base.CigarettePack" }, { "Base.Tarp" }, { "Base.Jack" }, { "Base.LugWrench" } }) do
        stow(it[1], it[2], false)
    end
    -- food in every state
    stow("Base.Steak", 1, false, function(it) it:setAge(it:getOffAgeMax() + 3) end)   -- rotten
    stow("Base.Chicken", 1, false, function(it) it:setAge(it:getOffAge() + 1) end)    -- stale
    stow("Base.Steak", 1, false, function(it) it:setCooked(true) end)                 -- cooked
    stow("Base.Burger", 1, false, function(it) it:setCooked(true) end)
    -- liquids in several containers
    local function liquid(fluid, frac) return function(it)
        local fc = it:getFluidContainer()
        if fc then fc:Empty(); fc:addFluid(FluidType[fluid] or FluidType.Water, fc:getCapacity() * frac) end
    end end
    stow("Base.WaterBottle", 1, false, liquid("Water", 0.8)); stow("Base.Mugl", 1, false, liquid("Coffee", 0.5))
    stow("Base.Pot", 1, false, liquid("Water", 0.4)); stow("Base.PetrolCan", 1, false, liquid("Petrol", 0.7))
    stow("Base.Whiskey", 1, false, liquid("Whiskey", 1))
    -- a purse inside the backpack, with its own things (a bag in a bag)
    local pack = wornBags()[1]
    if pack then
        local purse = give(pack, "Base.Purse")
        if purse then fill(purse:getInventory(), { { "Base.Lipstick" }, { "Base.Money", 12 }, { "Base.Comb" } }) end
    end
    -- a duffel bag in the crate, packed (bags in containers)
    local crate = tagged("near_crate")
    if crate then
        local duffel = give(crate:getContainer(), "Base.Bag_DuffelBag")
        if duffel then fill(duffel:getInventory(), { { "Base.TinnedBeans", 2 }, { "Base.Hammer" }, { "Base.Nails", 10 } }) end
    end
    return true, "stowed: bags, crate, shelves, counter, fridge, trunk, ground"
end)

-- ---------------------------------------------------------------- every run: hands, the weight, then the wounds
part("hands", function()
    -- the axe and torch back in hand (a test that equips something leaves them in the bag)
    local inv = p:getInventory()
    if not p:getPrimaryHandItem() then
        local axe = inv:getFirstTypeRecurse("Base.Axe")
        if axe then pcall(function() p:setPrimaryHandItem(axe) end) end
    end
    if not p:getSecondaryHandItem() then
        local torch = inv:getFirstTypeRecurse("Base.HandTorch")
        if torch then pcall(function() p:setSecondaryHandItem(torch) end) end
    end
    local a, b = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    return a ~= nil and b ~= nil, tostring(a and a:getName()) .. " and " .. tostring(b and b:getName()) .. " in hand"
end, true)
part("quiet", function()
    -- every watch the character has, alarm off (director, Oct 23: a very high
    -- chirp during test runs; vanilla gives a spawned digital watch an alarm at
    -- a random hour, and the tests run the clock fast)
    local n = 0
    local function off(it)
        if it and (instanceof(it, "AlarmClock") or instanceof(it, "AlarmClockClothing")) then
            pcall(function() it:stopRinging() end)
            pcall(function() it:setAlarmSet(false) end)
            n = n + 1
        end
    end
    local function walk(inv)
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            off(it)
            if it:IsInventoryContainer() then walk(it:getInventory()) end
        end
    end
    walk(p:getInventory())
    return true, n .. " watch alarm(s) off"
end, true)
part("weight", function()
    -- under the carry limit, no Heavy Load: the heaviest loose things leave the
    -- main inventory for the crate (or the ground) until it is
    local inv = p:getInventory()
    local moved = 0
    local crate = tagged("near_crate")
    for _ = 1, 200 do
        if p:getInventoryWeight() <= limit() then break end
        local heavy, hw = nil, 0
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local attached = false
            pcall(function() attached = it:getAttachedSlot() > -1 end)
            if not p:isEquipped(it) and not it:isWorn() and not attached and it:getWeight() > hw then heavy, hw = it, it:getWeight() end
        end
        if not heavy then break end
        inv:Remove(heavy)
        if crate and crate:getContainer():hasRoomFor(p, heavy) then crate:getContainer():AddItem(heavy)
        else pcall(function() at(0, 0):AddWorldInventoryItem(heavy, 0.5, 0.5, 0) end) end
        moved = moved + 1
    end
    local w, mx = p:getInventoryWeight(), p:getMaxWeight()
    say(string.format("weight %.1f of %.1f (moved %d things off the character)%s", w, mx, moved, (w > mx) and " OVER" or ""))
    return w <= mx, string.format("%.1f / %.1f", w, mx)
end, true)
part("health", function()
    -- invincible first (on since the top of the run), then god mode off so
    -- the wounds stay; all mild: nothing bleeds, nothing is deep or infected
    pcall(function() p:setInvincible(true) end)
    p:setGodMod(false)
    local bd = p:getBodyDamage()
    -- (the open wounds wear health down between runs, 100 to 85 in six
    -- minutes on Oct 23: back to full first, then the same wounds again)
    local okR = pcall(function() bd:RestoreToFullHealth() end)
    if not okR then say("MISS RestoreToFullHealth: health carries over from the last run") end
    local function bp(n) return bd:getBodyPart(BodyPartType.FromString(n)) end
    local ok1 = pcall(function() local b = bp("Hand_L"); b:setScratched(true, true); b:setScratchTime(12); b:setBandaged(true, 4, false, "Base.Bandage") end)
    -- (the splint's item named too: vanilla's Remove Splint builds its picture from it,
    -- and a splint with none fails in the game's own health menu, Oct 23 2026)
    local ok2 = pcall(function() local b = bp("LowerLeg_L"); b:setFractureTime(20); b:setSplint(true, 0.8); b:setSplintItem("Base.Splint") end)
    local ok3 = pcall(function() local b = bp("UpperArm_R"); b:setScratched(true, true); b:setScratchTime(10) end)
    for k = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
        pcall(function()
            local b = bd:getBodyPart(BodyPartType.FromIndex(k))
            b:setBleeding(false); b:setBleedingTime(0); b:setInfectedWound(false); b:setWoundInfectionLevel(0)
        end)
    end
    local okF = pcall(function() p:getStats():set(CharacterStat.FATIGUE, 0.45) end)
    if not okF then okF = pcall(function() p:getStats():setFatigue(0.45) end) end
    -- a few more moodles for the moodle column: peckish, thirsty, some pain in the splinted leg
    pcall(function() p:getStats():set(CharacterStat.HUNGER, 0.2) end)
    pcall(function() p:getStats():set(CharacterStat.THIRST, 0.18) end)
    pcall(function() bp("LowerLeg_L"):setAdditionalPain(35) end)
    local h = bd:getOverallBodyHealth()
    return ok1 and ok2 and ok3 and not p:isDead(), string.format("bandaged scratch, splinted fracture, open scratch, fatigue %s; health %d", tostring(okF), math.floor(h))
end, true)

-- ---------------------------------------------------------------- run
local function runParts()
    say("start: save " .. tostring(getWorld():getWorld()) .. " at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. ", home " .. px .. "," .. py)
    local made, skipped = 0, 0
    for _, pt in ipairs(parts) do
        if DONE[pt.name] and not pt.always then
            skipped = skipped + 1
        else
            local ok, good, what = pcall(pt.fn)
            -- a part that ran is never run again (what it made stays; a second
            -- run must change nothing), whether or not all of it took
            if ok then DONE[pt.name] = true end
            if ok and good then
                made = made + 1
                say("made " .. pt.name .. ": " .. tostring(what))
            else
                miss(pt.name .. ": " .. tostring(ok and what or good))
            end
        end
    end
    say(string.format("%d zombies removed; %d parts made or set now, %d already there, %d missing; dead %s, health %d",
        nz, made, skipped, #missing, tostring(p:isDead()), math.floor(p:getBodyDamage():getOverallBodyHealth())))
    done()
end
if at(0, 0) and at(-12, -12) and at(12, 12) then
    runParts()
else
    -- home's squares still loading after a long move: wait for them (15 s at most)
    say("back home from " .. math.floor(dHome) .. " tiles off: waiting for the squares to load")
    local waited = 0
    local function wait()
        waited = waited + 1
        local ready = at(0, 0) and at(-12, -12) and at(12, 12)
        if not ready and waited < 900 then return end
        Events.OnTick.Remove(wait)
        if ready then runParts() else miss("home's squares never loaded"); done() end
    end
    Events.OnTick.Add(wait)
end
