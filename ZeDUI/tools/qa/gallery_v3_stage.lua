-- ZeDUI/tools/qa/gallery_v3_stage.lua  (Oct 21 2026)
-- Workshop gallery v3, part 2: after gallery_v3_core.lua (needs GAL and GAL.spot).
-- Stages the scene on the spot: the character's own clothes, belt and loose items put
-- aside (kept in GAL.R, put back by gallery_v3_teardown.lua), the kit worn (backpack,
-- chest rig, fanny pack, satchel, jacket, vest, gloves, boots, cap, belt, holster,
-- knee pads, watch, glasses), the belt slots, the holster and the back slot filled, a
-- crowbar in hand; a station wagon east of the character with its trunk full (the
-- character on the trunk's square), a duffel bag and loose things on the ground, a few
-- more parked cars round the lot, and zombies in the background made useless (they
-- stand, they do not attack; the character also has ZombiesDontAttack and god mode).
-- ZeD-independent (the vanilla run uses it too). "ZEDQA g3s ..." ending "g3s DONE".
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA g3s ERR no GAL spot: run gallery_v3_core.lua first"); print("ZEDQA g3s DONE"); return end
local S = G.newSeq("g3s", 240000)
local say = S.say
local p, inv, pn = G.p, G.inv, G.pn
local SM = getScriptManager()
local function exists(ft)
    local ok, it = pcall(function() return SM:FindItem(ft) end)
    return ok and it ~= nil
end

G.KIT = {
    wear = {
        { "Base.Tshirt_DefaultTEXTURE_TINT", "Base.Tshirt_DefaultTEXTURE" },
        { "Base.Shirt_Lumberjack", "Base.Shirt_Denim" },
        { "Base.Jacket_ArmyOliveDrab", "Base.Jacket_Black" },
        { "Base.Vest_Hunting_Khaki", "Base.Vest_BulletCivilian" },
        { "Base.Trousers_Denim", "Base.Trousers_JeanBaggy" },
        { "Base.Socks_Heavy", "Base.Socks_Ankle" },
        { "Base.Shoes_ArmyBoots", "Base.Shoes_HikingBoots" },
        { "Base.Gloves_LeatherGlovesBlack", "Base.Gloves_LeatherGloves" },
        { "Base.Hat_BaseballCapGreen", "Base.Hat_BaseballCap" },
        { "Base.Belt2" },
        { "Base.HolsterSimple_Black", "Base.HolsterSimple" },
        { "Base.Kneepad_Left_Tactical" }, { "Base.Kneepad_Right_Tactical" },
        { "Base.WristWatch_Left_DigitalBlack" },
        { "Base.Glasses_Aviators" },
        { "Base.Bag_ALICEpack_Army", "Base.Bag_ALICEpack" },
        { "Base.Bag_ChestRig" },
        { "Base.Bag_FannyPackBack" },
        { "Base.Bag_Satchel_Leather", "Base.Bag_Satchel" },
    },
    belt = { { "Base.HuntingKnife" }, { "Base.Hammer" } },
    holster = { "Base.Pistol" },
    back = { "Base.Shotgun", "Base.Axe" },
    hand = "Base.Crowbar",
    bags = {
        back = { "Base.WaterBottle", "Base.TinnedBeans", "Base.TinnedBeans", "Base.Crisps", "Base.BeefJerky", "Base.Bandage",
                 "Base.Bandage", "Base.Matches", "Base.Rope", "Base.Saw", "Base.Nails", "Base.DuctTape", "Base.Battery" },
        webbing = { "Base.Bandage", "Base.Disinfectant", "Base.Bullets9mmBox" },
        fannypackback = { "Base.Lighter", "Base.Pencil" },
        satchel = { "Base.Notebook", "Base.Book", "Base.Peanuts" },
    },
    loose = { "Base.Apple", "Base.Apple", "Base.Chocolate", "Base.Machete", "Base.Book", "Base.WalkieTalkie2" },
    trunk = { "Base.PetrolCan", "Base.Toolbox", "Base.Tarp", "Base.Plank", "Base.Plank", "Base.CarBattery1", "Base.Jack",
              "Base.LugWrench", "Base.WaterBottle", "Base.TinnedSoup", "Base.Bag_DuffelBagTINT" },
    duffel = { "Base.TinnedBeans", "Base.TinnedBeans", "Base.CannedCorn", "Base.ShotgunShellsBox", "Base.Bullets9mmBox",
               "Base.FirstAidKit", "Base.Screwdriver", "Base.Wrench", "Base.Hammer" },
    floor = { "Base.Plank", "Base.Sledgehammer", "Base.PetrolCan" },
}

-- ---------------------------------------------------------------------------
-- 1. aside: what the character wears, holds, has on the belt and carries loose
-- ---------------------------------------------------------------------------
function G.putAside()
    local R = G.R
    if R.aside then return end
    R.aside = true
    R.prim, R.sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    R.hot = {}
    local hb = getPlayerHotbar and getPlayerHotbar(pn)
    if hb then
        for i, it in pairs(hb.attachedItems or {}) do R.hot[#R.hot + 1] = { i = i, it = it } end
        for _, h in ipairs(R.hot) do pcall(function() hb:removeItem(h.it, false) end) end
    end
    R.worn = {}
    pcall(function()
        local wi = p:getWornItems()
        for i = 0, wi:size() - 1 do R.worn[#R.worn + 1] = { it = wi:get(i):getItem(), loc = wi:get(i):getLocation() } end
    end)
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    for _, w in ipairs(R.worn) do pcall(function() p:removeWornItem(w.it, false) end) end
    R.items = {}
    local items = inv:getItems()
    for i = 0, items:size() - 1 do R.items[#R.items + 1] = items:get(i) end
    for _, it in ipairs(R.items) do pcall(function() inv:Remove(it) end) end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say(string.format("aside: %d worn, %d on the belt, %d items, hands %s / %s", #R.worn, #R.hot, #R.items,
        tostring(R.prim and R.prim:getFullType()), tostring(R.sec and R.sec:getFullType())))
end

-- ---------------------------------------------------------------------------
-- 2. the kit
-- ---------------------------------------------------------------------------
local function locOf(it)
    local loc = nil
    pcall(function()
        local ce = it:canBeEquipped()
        if instanceof(it, "InventoryContainer") and ce and ce ~= "" then loc = ce else loc = it:getBodyLocation() end
    end)
    return loc
end
function G.wearOne(cands)
    for _, ft in ipairs(cands) do
        if exists(ft) then
            local it = inv:AddItem(ft)
            if it then
                local loc = locOf(it)
                local busy = true
                if loc and loc ~= "" then pcall(function() busy = p:getWornItem(loc) ~= nil end) end
                if not busy then
                    local ok = pcall(function() p:setWornItem(loc, it) end)
                    local on = false
                    pcall(function() on = p:getWornItem(loc) == it end)
                    if ok and on then G.A.worn[#G.A.worn + 1] = it; return it end
                end
                inv:Remove(it)
            end
        end
    end
    return nil
end
function G.attach(cands, want)
    local hb = getPlayerHotbar and getPlayerHotbar(pn)
    if not hb then return nil end
    pcall(function() hb:refresh() end)
    for _, ft in ipairs(cands) do
        if exists(ft) then
            local it = inv:AddItem(ft)
            if it then
                for i, slot in ipairs(hb.availableSlot or {}) do
                    if not hb.attachedItems[i] then
                        local att = nil
                        pcall(function() att = slot.def.attachments[it:getAttachmentType()] end)
                        local typ = tostring(slot.def and slot.def.type or ""):lower()
                        local kind = (typ:find("back", 1, true) and "back") or (typ:find("holster", 1, true) and "holster") or "belt"
                        if att and kind == want then
                            local ok = pcall(function() hb:attachItem(it, att, i, slot.def, false) end)
                            if ok and hb.attachedItems[i] == it then
                                G.A.attached[#G.A.attached + 1] = it
                                return it, typ
                            end
                        end
                    end
                end
                inv:Remove(it)
            end
        end
    end
    return nil
end
function G.fill(container, list)
    local n = 0
    for _, ft in ipairs(list) do
        if exists(ft) then
            local it = nil
            pcall(function() it = container:AddItem(ft) end)
            if it then n = n + 1 end
        end
    end
    return n
end
function G.dress()
    local K = G.KIT
    local worn, miss = {}, {}
    for _, c in ipairs(K.wear) do
        local it = G.wearOne(c)
        if it then worn[#worn + 1] = it:getFullType():gsub("^Base%.", "") else miss[#miss + 1] = c[1] end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say("worn: " .. table.concat(worn, " "))
    if #miss > 0 then say("note: not worn: " .. table.concat(miss, " ")) end
    -- what goes in which bag (by the place it is worn)
    G.bags = {}
    for _, it in ipairs(G.A.worn) do
        if instanceof(it, "InventoryContainer") then
            local loc = tostring(locOf(it)):lower():gsub("^.*:", "")
            for key, list in pairs(K.bags) do
                if loc == key then
                    G.bags[key] = it
                    say("bag " .. key .. " (" .. it:getFullType() .. "): " .. G.fill(it:getInventory(), list) .. " things")
                end
            end
        end
    end
    for _, ft in ipairs(K.loose) do if exists(ft) then inv:AddItem(ft) end end
    local bw = G.bags.back and G.bags.back:getInventory():getItems()
    pcall(function()
        for i = 0, bw:size() - 1 do
            local w = bw:get(i)
            if w:getFullType() == "Base.WaterBottle" then w:getFluidContainer():addFluid("Water", 0.6) end
        end
    end)
end
function G.arm()
    local K = G.KIT
    local got = {}
    for _, b in ipairs(K.belt) do
        local it, typ = G.attach(b, "belt")
        got[#got + 1] = it and (it:getType() .. "@" .. tostring(typ)) or ("none:" .. b[1])
    end
    local h, ht = G.attach(K.holster, "holster")
    got[#got + 1] = h and (h:getType() .. "@" .. tostring(ht)) or "holster:none"
    local bk, bt = G.attach(K.back, "back")
    got[#got + 1] = bk and (bk:getType() .. "@" .. tostring(bt)) or "back:none"
    say("belt: " .. table.concat(got, " "))
    local w = exists(K.hand) and inv:AddItem(K.hand)
    if w then
        p:setPrimaryHandItem(w)
        local both = false
        pcall(function() both = w:isRequiresEquippedBothHands() end)
        if both then p:setSecondaryHandItem(w) end
    end
    pcall(function()
        local hb = getPlayerHotbar(pn)
        local slots = {}
        for i, slot in ipairs(hb.availableSlot or {}) do slots[#slots + 1] = tostring(slot.def.type) .. (hb.attachedItems[i] and "*" or "") end
        say("hotbar slots: " .. table.concat(slots, " "))
    end)
end

-- ---------------------------------------------------------------------------
-- 3. props: the car, the bag and things on the ground, parked cars, zombies
-- ---------------------------------------------------------------------------
function G.spawnCar(script, dir, skin, x, y)
    local sq = G.sqAt(x, y)
    if not sq then return nil end
    local ok, v = pcall(addVehicleDebug, script, dir, skin, sq)
    if ok and v then G.A.cars[#G.A.cars + 1] = v; return v end
    say("note: " .. script .. " would not spawn at " .. x .. "," .. y .. ": " .. tostring(v))
    return nil
end
function G.worldItem(ft, x, y, ox, oy)
    local sq = G.sqAt(x, y)
    if not (sq and exists(ft)) then return nil end
    local it = nil
    pcall(function() it = sq:AddWorldInventoryItem(ft, ox or 0.5, oy or 0.5, 0) end)
    if it then G.A.world[#G.A.world + 1] = it end
    return it
end
function G.zombie(x, y, faceX, faceY)
    local z = nil
    pcall(function()
        local l = addZombiesInOutfit(x, y, 0, 1, nil, 50)
        if l and l:size() > 0 then z = l:get(0) end
    end)
    if not z then return nil end
    pcall(function() z:setUseless(true) end)
    pcall(function() z:faceLocation(faceX or x, faceY or y) end)
    return z
end
function G.removeZombie(z)
    pcall(function() z:removeFromWorld() end)
    pcall(function() z:removeFromSquare() end)
end
-- near zombies: two flanking the character (right and left on screen), for some shots only
function G.nearZombies(on)
    for _, z in ipairs(G.A.near) do G.removeZombie(z) end
    G.A.near = {}
    if not on then return end
    local s = G.spot
    for _, o in ipairs({ { 2, -5 }, { -5, 2 } }) do
        local x, y = G.nearLot(s.px + o[1], s.py + o[2], 3)
        if x then
            local z = G.zombie(x, y, s.px, s.py)
            if z then G.A.near[#G.A.near + 1] = z end
        end
    end
end

-- the trunk lid unlocked and up (a closed trunk cannot be reached)
function G.openTrunk(v)
    local d = v and v:getPartById("TrunkDoor")
    if not d then return "no TrunkDoor part" end
    local ok, e = pcall(function()
        d:getDoor():setLocked(false)
        d:getDoor():setOpen(true)
        v:transmitPartDoor(d)
    end)
    return ok and "open" or tostring(e)
end

local K2 = { car = nil, trunk = nil, duffel = nil }
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0)
    G.putAside()
end)
S.step(10, function() G.dress() end)
S.step(10, function() G.arm() end)
-- the car east of the character, facing east: its trunk at the character's end
S.step(10, function()
    local s = G.spot
    K2.car = G.spawnCar("Base.CarStationWagon", IsoDirections.E, 0, s.px + 4, s.py)
    if not K2.car then K2.car = G.spawnCar("Base.CarNormal", IsoDirections.E, 0, s.px + 4, s.py) end
    G.car = K2.car
end)
S.step(40, function()
    local v = G.car
    if not v then S.err("car", "no car"); return end
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity() * 0.6) end)
    pcall(function() G.carKey = inv:AddItem(v:createVehicleKey()) end)
    say("trunk lid: " .. G.openTrunk(v))
    local part = v:getPartById("TruckBed")
    local c = nil
    if part then
        G.trunkPart = part
        c = part:getItemContainer()
        G.trunk = c
        local n = c and G.fill(c, G.KIT.trunk) or 0
        say("trunk: " .. n .. " things")
        -- the character on the trunk's area
        local vec = nil
        pcall(function() vec = v:getAreaCenter(part:getArea()) end)
        if vec then
            G.spot.px, G.spot.py = math.floor(vec:getX()), math.floor(vec:getY())
            say(string.format("trunk area centre %.1f,%.1f: the character goes to %d,%d", vec:getX(), vec:getY(), G.spot.px, G.spot.py))
        end
    else
        S.err("car", "no TruckBed part")
    end
    G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0)
end)
S.step(30, function()
    local v, part = G.car, G.trunkPart
    local inA, acc = false, false
    pcall(function() inA = v:isInArea(part:getArea(), p) end)
    pcall(function() acc = v:canAccessContainer(part:getIndex(), p) end)
    say(string.format("at %d,%d: in the trunk area %s, trunk reachable %s", math.floor(p:getX()), math.floor(p:getY()), tostring(inA), tostring(acc)))
    -- the duffel bag and the loose things on the ground, left of the character on screen
    local s = G.spot
    local d = G.worldItem("Base.Bag_DuffelBag", s.px - 1, s.py + 1, 0.5, 0.4)
    if d then
        G.duffel = d
        say("duffel on the ground: " .. G.fill(d:getInventory(), G.KIT.duffel) .. " things")
    end
    local fl = { { s.px - 1, s.py, 0.3, 0.6 }, { s.px, s.py + 1, 0.6, 0.3 }, { s.px - 1, s.py - 1, 0.5, 0.5 } }
    for i, ft in ipairs(G.KIT.floor) do
        local q = fl[i]
        if q then G.worldItem(ft, q[1], q[2], q[3], q[4]) end
    end
end)
-- parked cars round the lot (up the screen and to the sides), only on clear lot rectangles
S.step(5, function()
    local s = G.spot
    local spots = { { -9, -10, "Base.CarNormal", IsoDirections.N, 1 }, { -15, -4, "Base.PickUpTruck", IsoDirections.N, 0 },
                    { 4, -14, "Base.SmallCar", IsoDirections.E, 2 }, { -4, 9, "Base.Van", IsoDirections.E, 0 },
                    { 12, -6, "Base.CarLightsPolice", IsoDirections.N, 0 } }
    local n = 0
    G.reservedOn = true
    for _, q in ipairs(spots) do
        local x, y = s.px + q[1], s.py + q[2]
        local ok = true
        for dy = -3, 3 do
            for dx = -2, 2 do
                local ax, ay = x + dx, y + dy
                if q[4] == IsoDirections.E then ax, ay = x + dy, y + dx end
                if G.reserved(ax, ay) or not G.isLot(G.sqAt(ax, ay)) then ok = false end
            end
        end
        if ok and G.spawnCar(q[3], q[4], q[5], x, y) then n = n + 1 end
    end
    say("parked cars spawned: " .. n .. " | cars within 22 now: " .. G.vehiclesNear(s.px, s.py, 22))
end)
-- zombies in the background (up the screen) and a couple far off to the sides
S.step(30, function()
    local s = G.spot
    local spots = { { -10, -13 }, { -14, -9 }, { -7, -16 }, { -17, -15 }, { -12, -20 }, { -20, -8 }, { 9, -12 }, { -11, 7 }, { 14, 3 } }
    for _, o in ipairs(spots) do
        local x, y = G.nearLot(s.px + o[1], s.py + o[2], 4)
        if x then
            local z = G.zombie(x, y, s.px, s.py)
            if z then G.A.zombies[#G.A.zombies + 1] = z end
        end
    end
    say("background zombies: " .. #G.A.zombies .. " | in the cell " .. getCell():getZombieList():size())
end)
S.step(150, function()
    local alive = 0
    for _, z in ipairs(G.A.zombies) do
        local ok, here = pcall(function() return z:getCurrentSquare() ~= nil and not z:isDead() end)
        if ok and here then alive = alive + 1 end
    end
    say("zombies still there after 150 frames: " .. alive .. "/" .. #G.A.zombies .. " | in the cell " .. getCell():getZombieList():size())
    G.faceFront()
end)
S.zoomTo(1.0)
S.step(30, function() G.faceFront(); S.shot("g3_stage_mid") end)
S.start()
