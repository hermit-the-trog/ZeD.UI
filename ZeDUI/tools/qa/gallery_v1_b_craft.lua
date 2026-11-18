-- ZeDUI/tools/qa/gallery_v1_b_craft.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's crafting pictures, ZeD's half
-- (HANDOFF_design_gallery_v1_20261117.md, "For QA: the shot list"). Needs gallery_v1_b_lib.lua first (gallery_v1_b_zed.txt).
--   g1_46_craft_zed   46 Crafting (and 04's right picture): the World window's Crafting tab with Make Molotov Cocktail
--                     open and its ingredients partly missing: a rag and a bottle of brandy given (the bottle may or
--                     may not count as the glass bottle), no fuel (every carried fluid holder taken out for the run),
--                     so the have / need marks show
--   g1_04_build_zed   04: the Building tab with a recipe open (a crate if the list has one, else the first one the
--                     character can build, else the first listed)
-- The recipe's name goes to Zomboid/Lua/gallery_v1_b_recipe.txt for the vanilla run (gallery_v1_b_van.lua), so the
-- game's own crafting window opens on the same recipe. At the QA home, the window pair at its default places and
-- sizes (the World window to one side, the character clear between; every shot logs the boxes and that check).
-- Puts back: the recipe cards shut, Show as it was, the given things out, the fluid holders back, the place.
-- grep "ZEDQA g1bc".
local S = GV1 and GV1.new("g1bc")
if not S then print("ZEDQA g1bc ERR run gallery_v1_b_lib.lua first"); print("ZEDQA g1bc DONE"); return end
S.L = GV1
S.RECIPE = "MakeMolotovCocktail"   -- (recipes_traps.txt; ZeD lists a recipe by its bare name: "AddACigarette")
S.CW, S.WW = ZeD_CharacterWindow, ZeD_WorldWindow
S.CC = ZeD.CraftingCore
function S.ww() return S.WW.getWindow(S.pn) end
function S.pairOpen() if not S.CW.isOpen(S.pn) then pcall(S.CW.toggleBothPaired, S.pn) end end
function S.bare(name) return (string.gsub(tostring(name or ""), "^Base%.", "")) end
function S.find(data, name)
    for _, rd in ipairs((data and data.recipes) or {}) do
        if rd.entry and S.bare(rd.entry.name) == S.bare(name) then return rd end
    end
    return nil
end
-- the game's own answer for the recipe with what is carried (true: nothing missing)
function S.canMake(name)
    local can = "?"
    pcall(function()
        local sm = getScriptManager()
        local r = sm:getCraftRecipe(name) or sm:getCraftRecipe("Base." .. S.bare(name))
        local l = HandcraftLogic.new(S.p, nil, nil)
        l:setContainers(S.CC.buildContainers(S.p))
        l:setRecipe(r)
        can = tostring(l:canPerformCurrentRecipe())
    end)
    return can
end

S.step(10, function()
    S.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.L.keepCheats(S)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "g1bc") end
    if ZEDQA_SPEED then ZEDQA_SPEED(1) elseif getGameSpeed() ~= 1 then setGameSpeed(1) end
    S.L.cheats(S); S.L.console()
    S.rag = S.L.give(S, "Base.RippedSheets")
    S.bottle = S.L.give(S, "Base.Brandy")
    S.L.hideFluids(S, S.bottle)
    S.say("given: rag " .. tostring(S.rag ~= nil) .. ", brandy " .. tostring(S.bottle ~= nil))
    S.pairOpen()
end)
S.step(30, function() pcall(S.WW.openTab, S.pn, "craft") end)
S.step(30, function()
    local w = S.ww()
    local st = w and w._craftState
    if not st then S.L.notTaken(S, "g1_46_craft_zed", "no Crafting tab state"); return end
    S.showWas = { st.show, st.showAll }
    S.CC.setShow(st, "all")
    local data = ZeD.CraftingTab.gatherData(S.p, w)
    local rd = S.find(data, S.RECIPE)
    if not rd then
        -- (not listed: the first recipe the list marks missing)
        for _, x in ipairs((data and data.recipes) or {}) do if not rd and x.status == "missing" then rd = x end end
        S.say("ERR " .. S.RECIPE .. " is not in the list; the first missing one instead: " .. tostring(rd and rd.entry.name))
    end
    if not rd then S.L.notTaken(S, "g1_46_craft_zed", "no recipe to open"); return end
    S.recipe = rd.entry.name
    S.CC.openCraft(st, S.recipe)
    pcall(function() local f = getFileWriter("gallery_v1_b_recipe.txt", true, false); f:write(S.recipe); f:close() end)
    S.say("recipe open: " .. tostring(S.recipe) .. " (" .. tostring(rd.entry.displayName) .. "), written to Lua/gallery_v1_b_recipe.txt")
end)
S.step(120, function()   -- (the list's craftable answer is refreshed every 1.2 s)
    if not S.recipe then return end
    local rd = S.find(ZeD.CraftingTab.gatherData(S.p, S.ww()), S.recipe)
    local can = S.canMake(S.recipe)
    S.say("list status " .. tostring(rd and rd.status) .. ", the game's check " .. can)
    if can == "true" then S.say("WARN nothing is missing: the have / need marks will all read have") end
    if GAL_UNLOAD and GAL_UNLOAD.park then GAL_UNLOAD.park() end
end)
S.step(40, function() if S.recipe then S.L.shot(S, "g1_46_craft_zed") end end)
S.step(10, function()
    local st = S.ww() and S.ww()._craftState
    if st then
        S.CC.closeCraft(st)
        if S.showWas then st.show, st.showAll, st.filterDirty = S.showWas[1], S.showWas[2], true end
    end
end)

-- ===================================================================== 04: the Building tab
S.step(20, function() pcall(S.WW.openTab, S.pn, "build") end)
S.step(30, function()
    local w = S.ww()
    local st = w and w._buildState
    if not st then S.L.notTaken(S, "g1_04_build_zed", "no Building tab state"); return end
    local data = ZeD.BuildingTab.gatherData(S.p, w)
    local pick, can, miss, any = nil, nil, nil, nil
    for _, rd in ipairs((data and data.recipes) or {}) do
        local nm = string.lower(tostring(rd.entry and rd.entry.displayName or ""))
        if not pick and nm:find("crate", 1, true) and rd.status ~= "locked" then pick = rd end
        if not can and rd.status == "craftable" then can = rd end
        if not miss and (rd.status == "missing" or rd.status == "unlocked") then miss = rd end
        any = any or rd
    end
    pick = pick or can or miss or any
    if not pick then S.L.notTaken(S, "g1_04_build_zed", "no building recipe listed"); return end
    S.build = pick.entry.name
    S.bshowWas = { st.show, st.showAll }
    S.CC.setShow(st, "all")
    S.CC.openCraft(st, S.build)
    S.say("building recipe open: " .. tostring(S.build) .. " (" .. tostring(pick.entry.displayName) .. "), status " .. tostring(pick.status))
end)
S.step(120, function() if GAL_UNLOAD and GAL_UNLOAD.park then GAL_UNLOAD.park() end end)
S.step(40, function() if S.build then S.L.shot(S, "g1_04_build_zed") end end)

-- ===================================================================== put back
S.step(10, function()
    local st = S.ww() and S.ww()._buildState
    if st then
        pcall(S.CC.closeCraft, st)
        if S.bshowWas then st.show, st.showAll, st.filterDirty = S.bshowWas[1], S.bshowWas[2], true end
    end
    pcall(S.WW.openTab, S.pn, "loot")
    pcall(S.L.takeBack, S)
    pcall(S.L.unhide, S)
    if S.home then pcall(S.L.moveTo, S, S.home.x, S.home.y, S.home.z) end
    pcall(S.L.putCheats, S)
    pcall(S.L.summary, S)
    S.say("put back: cards shut, Show as it was, given things out, fluid holders back, the place")
    S.L.done(S)
end)
S.L.run(S)
