-- ZeDUI/tools/qa/gallery_cinema_laura.lua  (Nov 4 2026, QA; the director's cinema breaks): Laura Craft (the Rosa shot
-- save's character, renamed) at a camp in the woods at dusk: a tent, a lit campfire, logs, planks, nails and tools on
-- the ground, to show the crafting and building windows. A single braid, a teal tank top, shorts, hiking boots, a
-- double holster, a backpack and a pistol in each hand. An outdoor survivor's skills (carpentry, carving, knapping,
-- foraging, trapping, cooking, tailoring) and supplies (branches, twigs, stones, rope, a tarp ...), the grass cut back
-- around the campfire (the director).
-- The camp: a clearing near where the save stands (natural ground, no building within 15 squares, no tree within 2,
-- woods around). The tent and campfire are the game's own (camping.addTent, SCampfireSystem:addCampfire, as the
-- game's tests place them). A rerun clears the last run's camp first.
-- Run: cinema_run.ps1 -Who Laura (the save ZeD-Shots-Rosa). The look: Light with the teal accent (the director). Pictures
-- cin_lau_<name>.png:
--   craft    the Character window on Equip, the World window on Crafting (by the campfire)
--   build    the Character window on Skills, the World window on Building
--   wide     no windows, pulled back: the camp in the woods
-- grep "ZEDQA clau".
local C = CIN
local S = C.seq("clau")
local p = getPlayer()
local site = nil

local function natural(sq)
    local fl = sq and sq:getFloor()
    local nm = string.lower(tostring(fl and fl:getSprite() and fl:getSprite():getName() or ""))
    return nm:find("natural", 1, true) ~= nil
end

-- a clearing: natural ground, nothing built within 15, no tree within 2, at least 6 trees within 12
local function findClearing(cx, cy, r)
    local cell = getCell()
    local best, bd = nil, 1e9
    for dx = -r, r, 3 do for dy = -r, r, 3 do
        local x, y = cx + dx, cy + dy
        local sq = cell:getGridSquare(x, y, 0)
        if sq and natural(sq) and not sq:getBuilding() then
            local ok, trees = true, 0
            for ex = -15, 15, 3 do for ey = -15, 15, 3 do
                local s2 = cell:getGridSquare(x + ex, y + ey, 0)
                if s2 and s2:getBuilding() then ok = false end
            end end
            for ex = -2, 2 do for ey = -2, 2 do
                local s2 = cell:getGridSquare(x + ex, y + ey, 0)
                if not s2 or s2:getTree() or not natural(s2) then ok = false end
            end end
            if ok then
                for ex = -12, 12, 2 do for ey = -12, 12, 2 do
                    local s2 = cell:getGridSquare(x + ex, y + ey, 0)
                    if s2 and s2:getTree() then trees = trees + 1 end
                end end
                local d = dx * dx + dy * dy
                if trees >= 6 and d < bd then best, bd = { x, y, trees }, d end
            end
        end
    end end
    return best
end

S.step(5, function() C.look("light", "teal"); C.noWindows(); pcall(function() p:setGodMod(true) end) end)
-- the save stands in town (a grocery at 6350,5300): look in open country first (spots where the Kohners scene found
-- no road, so likely woods), then near the save
local SPOTS = { { 8800, 10800 }, { 9500, 11600 }, { 10300, 12000 }, { 8200, 9800 } }
for k = 1, #SPOTS do
    S.step(5, function() if site then return end; C.moveTo(SPOTS[k][1], SPOTS[k][2], 0) end)
    S.step(150, function()
        if site then return end
        site = findClearing(SPOTS[k][1], SPOTS[k][2], 60)
        S.say("spot " .. k .. ": clearing " .. tostring(site and (site[1] .. "," .. site[2] .. " (" .. site[3] .. " trees)")))
    end)
end
S.step(10, function()
    if not site then S.say("ERR no clearing"); return end
    local cell = getCell()
    local x, y = site[1], site[2]
    -- a rerun: the last camp out first (its campfire, its tent, the things on the ground)
    for dx = -8, 8 do for dy = -8, 8 do
        local sq = cell:getGridSquare(x + dx, y + dy, 0)
        if sq then
            pcall(function() local cf = SCampfireSystem.instance:getLuaObjectOnSquare(sq); if cf then SCampfireSystem.instance:removeCampfire(cf) end end)
            pcall(function() local t = camping.findTentObject(sq); if t then camping.removeTent(t) end end)
            pcall(function()
                local wo = sq:getWorldObjects()
                for i = wo:size() - 1, 0, -1 do sq:transmitRemoveItemFromSquare(wo:get(i)) end
            end)
        end
    end end
    -- the long grass cut back around the campfire (the director): plants, grass and erosion growth within 4 squares of
    -- it, never trees or the floor itself
    local cut = 0
    for dx = -3, 5 do for dy = -3, 5 do
        local sq = cell:getGridSquare(x + dx, y + dy, 0)
        if sq then
            local objs = sq:getObjects()
            for i = objs:size() - 1, 1, -1 do
                local o = objs:get(i)
                local nm = o:getSprite() and o:getSprite():getName() or ""
                if not instanceof(o, "IsoTree") and (nm:find("^e_") or nm:find("^d_") or nm:find("^blends_grassoverlays") or nm:find("^vegetation")) then
                    if pcall(function() sq:RemoveTileObject(o) end) then cut = cut + 1 end
                end
            end
        end
    end end
    S.say("grass cut: " .. cut)
    -- the tent, behind and to the side; the campfire in front of her
    local tsq = cell:getGridSquare(x + 3, y - 2, 0)
    local tent = nil
    pcall(function() tent = camping.addTent(tsq, "TileIndieStoneTentFrontLeft") end)
    if not tent then pcall(function() tent = camping.addTent(tsq, "camping_01_0") end) end
    local fsq = cell:getGridSquare(x + 1, y + 1, 0)
    local fire = nil
    pcall(function() fire = SCampfireSystem.instance:addCampfire(fsq); fire:addFuel(120); fire:lightFire() end)
    -- the makings: logs, planks, nails and tools on the ground around the camp
    local stuff = { { "Base.Log", -2, 2 }, { "Base.Log", -2, 3 }, { "Base.Log", -3, 2 }, { "Base.Plank", 2, 3 }, { "Base.Plank", 2, 3 },
        { "Base.Plank", 3, 3 }, { "Base.NailsBox", -1, 3 }, { "Base.Hammer", -1, 2 }, { "Base.Saw", 3, 2 }, { "Base.Axe", -3, 1 },
        { "Base.TreeBranch2", 0, 3 }, { "Base.Twigs", 1, 3 } }
    local n = 0
    for _, it in ipairs(stuff) do
        local sq = cell:getGridSquare(x + it[2], y + it[3], 0)
        if sq and pcall(function() sq:AddWorldInventoryItem(it[1], ZombRandFloat(0.2, 0.8), ZombRandFloat(0.2, 0.8), 0) end) then n = n + 1 end
    end
    C.moveTo(x, y, 0)
    p:setDir(IsoDirections.SE)
    S.say("camp: tent " .. tostring(tent ~= nil) .. ", campfire " .. tostring(fire ~= nil) .. ", " .. n .. " things on the ground")
end)
S.step(10, function()
    -- Rosa becomes Laura Craft (the director)
    pcall(function() local d = p:getDescriptor(); d:setForename("Laura"); d:setSurname("Craft") end)
    C.time(20.8)
    C.clearSky()
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Shorts_OliveDrabLong", "Base.Shoes_HikingBoots", "Base.HolsterDouble",
              "Base.WristWatch_Left_DigitalBlack" }, "Base.Pistol", { "Base.Bullets9mm", "Base.Lighter", "Base.WaterBottle" })
    C.profession("PARK_RANGER")   -- (a profession that fits the role: the director)
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.22, 0.55, 0.56)
    pcall(function() local p2 = p:getInventory():AddItem("Base.Pistol"); p:setSecondaryHandItem(p2) end)
    -- an outdoor survivor's skills and supplies (the director): she can make what the camp needs
    local lv = { Woodwork = 6, Carving = 6, FlintKnapping = 5, PlantScavenging = 7, Trapping = 6, Cooking = 5, Tailoring = 4, Maintenance = 5, Fishing = 4 }
    for k, l in pairs(lv) do pcall(function() p:setPerkLevelDebug(Perks[k], l) end) end
    -- the supplies go in the backpack (a bag carries them lighter) and she has a survivor's strength, so no heavy-load
    -- warning shows in the picture
    pcall(function() p:setPerkLevelDebug(Perks.Strength, 10) end)
    local inv = p:getInventory()
    pcall(function() local bag = inv:AddItem("Base.Bag_NormalHikingBag"); p:setClothingItem_Back(bag); inv = bag:getItemContainer() or inv end)
    for _, it in ipairs({ { "Base.Nails", 12 },
                          { "Base.Rope", 1 }, { "Base.Twine", 2 }, { "Base.Tarp", 1 }, { "Base.RippedSheets", 4 }, { "Base.Stake", 2 },
                          { "Base.SharpedStone", 2 }, { "Base.FlintNodule", 2 }, { "Base.HuntingKnife", 1 } }) do   -- (light enough to carry: the logs, planks and saw lie by the camp)
        for i = 1, it[2] do pcall(function() inv:AddItem(it[1]) end) end
    end
    pcall(function()
        local hv = p:getHumanVisual()
        hv:setHairModel("PonyTailBraids")
        hv:setHairColor(ImmutableColor.new(0.30, 0.18, 0.10, 1))
    end)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() p:resetModelNextFrame() end)
    S.say("dressed; worn " .. tostring(p:getWornItems():size()) .. "; name " .. tostring(p:getDescriptor():getForename()) .. " " .. tostring(p:getDescriptor():getSurname()))
end)
C.lookAround(S, "SE")
C.pointerAway(S)
C.zoom(S, 0.5)
S.step(60, function() C.windows("equip", "craft") end)
-- every recipe, not only the ones she can make now (a fresh character has none ready)
S.step(30, function() local ww = ZeD_WorldWindow.getWindow(); if ww and ww._craftState then ZeD.CraftingCore.setShow(ww._craftState, "all") end end)
S.step(150, function() C.shot(S, "lau_craft") end)
S.step(20, function() C.windows("skills", "build") end)
S.step(30, function() local ww = ZeD_WorldWindow.getWindow(); if ww and ww._buildState then ZeD.CraftingCore.setShow(ww._buildState, "all") end end)
S.step(150, function() C.shot(S, "lau_build") end)
S.step(20, function() C.noWindows() end)
C.zoom(S, 0.75)
S.step(90, function() C.shot(S, "lau_wide") end)
S.step(30, function() S.say("DONE") end)
S.run()
