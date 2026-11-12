-- ZeDUI/tools/qa/zedqa_animals_restore.lua  (Nov 11 2026, Build): run once on the QA save to undo what the animals
-- quick-action scripts left behind before they cleaned up after themselves. QA save only (Saves/Sandbox/ZeD-QA), the
-- character at the QA home (the drag strip, 925,13040). Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go, grep console.txt
-- for "ZEDQA ares". It prints every animal and item it takes away and why, then DONE.
--   ANIMALS  taken away when they carry the mark ZeDQA_spawned (the scripts set it now), anywhere loaded. Unmarked ones
--            (the runs before the mark) are taken away only when all of these hold: within 60 squares of the QA home,
--            not wild, alive, not in a trailer, and in no livestock zone but the scripts' own ("QA Quick", "QA Quick2")
--            or in none at all. An animal in any other zone (a player-made pen, the QA Yard fixture) stays.
--   ZONES    "QA Quick" and "QA Quick2" removed (after the animals: the zones decide which animals stay).
--   ITEMS    taken away: carried items with the mark; a school bag holding nothing but carrots (or nothing), which is
--            the old script's bag, with its carrot. Loose Steak and Carrots carry no mark and cannot be told from the
--            character's own: they are counted and left.
--   TOOLS    one Bucket (Base.Bucket) and one pair of Shears (Base.SheepShears) given, each only when none is carried,
--            so a second run gives nothing twice.
local TAG = "ares"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local MARK = "ZeDQA_spawned"
local HOME = { x = 925, y = 13040 }
local RADIUS = 60
local QA_ZONES = { ["QA Quick"] = true, ["QA Quick2"] = true }

local function marked(o)
    local ok, md = pcall(function() return o:getModData() end)
    return ok and md ~= nil and md[MARK] == true
end
local function call(o, m)
    local ok, v = pcall(function() return o[m](o) end)
    if ok then return v end
    return nil
end

-- the animals the game counts in a zone other than the scripts' own: they stay
local function keptByZones()
    local keep = {}
    local all = DesignationZoneAnimal and DesignationZoneAnimal.getAllZones and DesignationZoneAnimal.getAllZones()
    if not all then return keep end
    for k = 0, all:size() - 1 do
        local z = all:get(k)
        local name = z and call(z, "getName")
        if z and not QA_ZONES[name] then
            local conn = call(z, "getAnimalsConnected")
            if conn then for j = 0, conn:size() - 1 do keep[conn:get(j)] = name or "?" end end
        end
    end
    return keep
end

local function sweepAnimals()
    local keep = keptByZones()
    local list = getCell():getAnimals()
    local it = list and list:iterator()
    local out, kept = {}, 0
    while it and it:hasNext() do
        local a = it:next()
        if a then
            local x, y = a:getX(), a:getY()
            local near = math.abs(x - HOME.x) <= RADIUS and math.abs(y - HOME.y) <= RADIUS
            local dz = call(a, "getDZone")
            local dzName = dz and call(dz, "getName")
            local zoneName = keep[a] or ((dzName and not QA_ZONES[dzName]) and dzName or nil)
            local why = nil
            if marked(a) then
                why = "marked"
            elseif near and not call(a, "isWild") and not call(a, "isDead") and not call(a, "getVehicle") and not zoneName then
                why = (dzName and ("in " .. dzName)) or "in no zone"
            elseif near then
                kept = kept + 1
                say("kept " .. tostring(call(a, "getAnimalType")) .. " at " .. math.floor(x) .. "," .. math.floor(y) .. ": "
                    .. (zoneName and ("in zone " .. zoneName) or (call(a, "isWild") and "wild") or (call(a, "isDead") and "dead") or "in a trailer"))
            end
            if why then out[#out + 1] = { a = a, why = why } end
        end
    end
    local gone = 0
    for _, v in ipairs(out) do
        local a = v.a
        local what = tostring(call(a, "getAnimalType")) .. " at " .. math.floor(a:getX()) .. "," .. math.floor(a:getY())
        local ok = pcall(function() a:removeFromWorld(); a:removeFromSquare() end)
        if ok then gone = gone + 1 end
        say((ok and "took away " or "could not take away ") .. what .. " (" .. v.why .. ")")
    end
    say("animals: took away " .. gone .. " of " .. #out .. "; kept " .. kept .. " near home")
end

local function sweepZones()
    local n = 0
    for name in pairs(QA_ZONES) do
        for _ = 1, 4 do
            local z = DesignationZoneAnimal.getZoneByName(name)
            if not z then break end
            pcall(function() DesignationZoneAnimal.removeZone(z, true) end)
            n = n + 1
            say("removed the zone " .. name)
        end
    end
    say("zones: removed " .. n)
end

local function sweepItems()
    local inv = p:getInventory()
    local gone = {}
    local function take(it, why)
        local c = it:getContainer()
        if not c then return end
        pcall(function() p:removeFromHands(it) end)
        c:Remove(it)
        gone[#gone + 1] = tostring(it:getFullType()) .. " (" .. why .. ")"
    end
    -- the marked ones (newest scripts)
    local list = inv:getAllEvalRecurse(function(it) return marked(it) end)
    for k = list:size() - 1, 0, -1 do take(list:get(k), "marked") end
    -- the old script's school bag: carrots only, or empty
    local bags = inv:getAllTypeRecurse("Base.Bag_Schoolbag")
    for k = bags:size() - 1, 0, -1 do
        local bag = bags:get(k)
        local c = bag.getItemContainer and bag:getItemContainer()
        local items = c and c:getItems()
        local onlyCarrots = items ~= nil
        if items then
            for j = 0, items:size() - 1 do
                if items:get(j):getFullType() ~= "Base.Carrots" then onlyCarrots = false end
            end
        end
        if onlyCarrots and items:size() <= 1 then
            for j = items:size() - 1, 0, -1 do take(items:get(j), "in the script's school bag") end
            take(bag, "the script's school bag: carrots only")
        end
    end
    for _, s in ipairs(gone) do say("took away " .. s) end
    say("items: took away " .. #gone .. "; left (no mark, cannot be told from the character's own): Steak "
        .. inv:getAllTypeRecurse("Base.Steak"):size() .. ", Carrots " .. inv:getAllTypeRecurse("Base.Carrots"):size())
end

local function giveTools()
    for _, full in ipairs({ "Base.Bucket", "Base.SheepShears" }) do
        local have = p:getInventory():getAllTypeRecurse(full):size()
        if have == 0 then
            local it = p:getInventory():AddItem(full)
            say((it and "gave one " or "could not give ") .. full)
        else
            say("already carries " .. have .. " " .. full .. ": none given")
        end
    end
end

local n = 0
local function tick()
    n = n + 1
    if n < 30 then return end
    Events.OnTick.Remove(tick)
    local dx, dy = p:getX() - HOME.x, p:getY() - HOME.y
    say(string.format("the character is %.0f squares from the QA home", math.sqrt(dx * dx + dy * dy)))
    if math.abs(dx) > RADIUS or math.abs(dy) > RADIUS then
        say("ERR not at the QA home: only the marked animals are taken away (the home's squares may not be loaded)")
    end
    for _, step in ipairs({ { "animals", sweepAnimals }, { "zones", sweepZones }, { "items", sweepItems }, { "tools", giveTools } }) do
        local ok, e = pcall(step[2])
        if not ok then say("ERR " .. step[1] .. ": " .. tostring(e)) end
    end
    pcall(function() ZeD.AnimalsAlertPoller.refreshCache() end)
    say("DONE")
end
Events.OnTick.Add(tick)
say("start")
