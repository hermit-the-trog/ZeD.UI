-- ZeDUI/tools/qa/gallery_cinema_plizken.lua  (Nov 4 2026, QA; the director's cinema breaks): Plizken at midnight on
-- the field of Louisville's baseball stadium: wrecked cars everywhere, things on fire, smoke, and zombies all around
-- that ignore him for the shot (idle zombies, and he is invisible to them). Urban (snow) camo trousers, a black tank
-- top, black sunglasses, boots, a watch, a pump shotgun.
-- The stadium: the field is the grass rectangle at x 12980-13064, y 1536-1620 (gallery_stadium_map.lua; the changing
-- rooms, baseballchangeroom, line its west side).
-- Everything it lays down is cleared first on a rerun; fires are put out and the zombies removed at the end.
-- Run on the shot save: zedqa_run.ps1 -ShotSave ZeD-Shots-Plizken -Manifest cinema_plizken.txt. The look: High
-- Contrast with the green accent (the director). Pictures cin_plz_<name>.png:
--   equip     the Character window on Equip (the outfit), the World window on Maps
--   vehicle   the Character window on Identity, the World window on Vehicle (the nearest wreck)
--   wide      no windows, pulled back: the field, the wrecks, the fires, the crowd of dead
-- grep "ZEDQA cplz".
local C = CIN
local S = C.seq("cplz")
local p = getPlayer()
local F = nil            -- the field square
local fires = {}

-- the field: gallery_stadium_map.lua drew it as a grass rectangle walled by the stadium's rooms, x 12980-13064,
-- y 1536-1620 (the changing rooms on its west side); he stands near the middle
F = { 13020, 1580 }
S.step(5, function() C.look("hicon", "green"); C.noWindows(); C.time(0.2); C.moveTo(F[1], F[2], 0); pcall(function() p:setGodMod(true) end) end)
S.step(150, function() S.say("field at " .. F[1] .. "," .. F[2]) end)
S.step(10, function()
    if not F then S.say("ERR no field"); return end
    C.clearScene(F[1], F[2], 24)
    local cell = getCell()
    C.moveTo(F[1], F[2], 0)
    -- cars everywhere: wrecks in a loose ring around him
    local cars = {
        { "Base.CarNormalBurnt", 5, -3, "E" }, { "Base.SUVSmashedFront", -6, 2, "N" }, { "Base.SmallCarBurnt", 3, 6, "W" },
        { "Base.TaxiBurnt", -3, -7, "S" }, { "Base.VanBurnt", 8, 4, "N" }, { "Base.PickupBurnt", -9, -3, "E" },
        { "Base.ModernCarBurnt", 7, -8, "W" }, { "Base.CarNormalSmashedLeft", -7, 8, "E" },
    }
    local nc = 0
    for k, c in ipairs(cars) do
        local v = C.car(c[1], F[1] + c[2], F[2] + c[3], c[4])
        if v then nc = nc + 1; if k == 1 then pcall(function() ZeD.MechanicsTab.pin(v) end) end end   -- (the Vehicle tab lists it)
    end
    -- things on fire, and smoke
    -- (two close by at his sides, so the firelight is on him and nothing burns in front of him; the rest on and beside the wrecks)
    for _, o in ipairs({ { 2, -1 }, { -1, 2 }, { 5, -2 }, { 3, 5 }, { -3, -6 }, { 8, 3 }, { -9, -2 }, { 2, -5 } }) do
        local x, y = F[1] + o[1], F[2] + o[2]; C.fire(x, y); fires[#fires + 1] = { x, y }
    end
    for _, o in ipairs({ { 6, -3 }, { -3, -7 }, { 8, 5 }, { -9, -4 } }) do
        local sq = cell:getGridSquare(F[1] + o[1], F[2] + o[2], 0)
        if sq then pcall(function() IsoFireManager.StartSmoke(cell, sq, true, 1000, 5000) end) end
    end
    C.glass(F[1], F[2], 12, 0, 14)
    -- the dead, everywhere, idle (they ignore him; he is invisible to them too); a few burning
    pcall(function() p:setInvisible(true) end)
    pcall(function() p:setGhostMode(true) end)
    local seed, nz = 5, 0
    local function rnd(m) seed = (seed * 1103515245 + 12345) % 2147483648; return seed % m end
    for i = 1, 34 do
        local ang = rnd(360) * math.pi / 180
        local dist = 4 + rnd(15)
        local zx, zy = F[1] + math.floor(dist * math.cos(ang)), F[2] + math.floor(dist * math.sin(ang))
        local burning = (i % 9 == 0)
        local ok = pcall(function()
            addZombiesInOutfit(zx, zy, 0, 1, nil, 50, false, false, false, false, false, false, 1.0, false, 0, false, burning, true)
        end)
        if not ok then ok = pcall(function() addZombiesInOutfit(zx, zy, 0, 1, nil, 50) end) end
        if ok then nz = nz + 1 end
    end
    p:setDir(IsoDirections.S)
    S.say("field dressed: " .. nc .. " cars, " .. #fires .. " fires, 4 smoke, " .. nz .. " zombies")
end)
S.step(10, function()
    C.time(0.2)
    C.clearSky()
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Trousers_CamoUrban", "Base.Shoes_BlackBoots", "Base.Glasses_Sun",
              "Base.WristWatch_Left_DigitalBlack", "Base.Bag_ALICE_BeltSus" }, "Base.Shotgun", { "Base.ShotgunShells", "Base.Lighter", "Base.Cigarettes" })
    C.profession("VETERAN")   -- (a profession that fits the role: the director)
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.07, 0.07, 0.08)
    S.say("dressed; worn " .. tostring(p:getWornItems():size()))
end)
C.lookAround(S, "S")
C.pointerAway(S)
C.zoom(S, 0.5)
S.step(60, function() C.windows("equip", "maps") end)
S.step(150, function() C.shot(S, "plz_equip") end)
S.step(20, function() C.windows("identity", "vehicle") end)
S.step(150, function() C.shot(S, "plz_vehicle") end)
S.step(20, function() C.noWindows() end)
C.zoom(S, 0.75)
S.step(90, function() C.shot(S, "plz_wide") end)
S.step(30, function()
    if F then
        local cell = getCell()
        for dx = -40, 40 do for dy = -40, 40 do
            local sq = cell:getGridSquare(F[1] + dx, F[2] + dy, 0)
            if sq then pcall(function() sq:stopFire() end) end
        end end
        local rm = {}
        pcall(function()
            local zs = cell:getZombieList()
            for i = 0, zs:size() - 1 do
                local z = zs:get(i)
                if math.abs(z:getX() - F[1]) <= 40 and math.abs(z:getY() - F[2]) <= 40 then rm[#rm + 1] = z end
            end
        end)
        for _, z in ipairs(rm) do pcall(function() z:removeFromWorld(); z:removeFromSquare() end) end
        S.say("cleared: fires out, " .. #rm .. " zombies removed")
    end
    pcall(function() p:setInvisible(false) end)
    pcall(function() p:setGhostMode(false) end)
    S.say("DONE")
end)
S.run()
