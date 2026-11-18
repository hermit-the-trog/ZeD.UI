-- ZeDUI/tools/qa/gallery_v1_b_van.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's vanilla crafting picture, ZeD OFF
-- (the save's mods.txt holds ZeDQAShim in place of ZeD_UI: gallery_v1_b_van.txt). Calls nothing of ZeD's.
-- Needs gallery_v1_b_lib.lua first.
--   g1_46_craft_van   46 Crafting (pitch image 4) and 04's left picture: the game's own B42 crafting window
--                     (ISEntityUI.OpenHandcraftWindow, as the game opens it) on the same recipe as g1_46_craft_zed,
--                     read from Zomboid/Lua/gallery_v1_b_recipe.txt (the ZeD run writes it; Make Molotov Cocktail
--                     without it), with the same things carried: a rag and a bottle of brandy given, every other
--                     fluid holder taken out for the run, so ingredients show partly missing
-- At the QA home (925,13040). The window opens at the game's place and size; if it covers the character it is slid to
-- the screen's left edge (else the right), its size kept, so the character and the place stay clear beside it. Its
-- place is put back before it closes (the game saves window places when one closes).
-- The glasses go on at the start and again before the shot (game calls only), and the build line at the bottom
-- right (WaterMarkUI) is hidden for the run.
-- Puts back: the build line shown, the window shut at its own place, the given things out, the fluid holders back, the place. grep "ZEDQA g1bv".
local S = GV1 and GV1.new("g1bv")
if not S then print("ZEDQA g1bv ERR run gallery_v1_b_lib.lua first"); print("ZEDQA g1bv DONE"); return end
S.L = GV1
if ZeD and ZeD_CharacterWindow then
    S.say("ERR ZeD-UI is loaded: this script is for the ZeD-off run")
    S.say("DONE")
    return
end
S.RECIPE = "MakeMolotovCocktail"
function S.win() local w = nil; pcall(function() w = ISEntityUI.GetWindowInstance(S.pn, "HandcraftWindow") end); return w end
-- the game's build line ("42.22.2 ... pzBullet(...)", WaterMarkUI from ISVersionWaterMark.lua) hidden for the run
-- by the game's own element walk, and shown again at the end. No ZeD calls.
function S.watermark(show)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        local t = e:getTable()
        if t and t.Type == "WaterMarkUI" then
            if show then
                if S.wmWas then e:setVisible(true) end
            elseif e:isVisible() then
                S.wmWas = true
                e:setVisible(false)
            end
        end
    end
end
-- the prescription glasses on, by the game's own calls only (GV1.glasses: the item added if none is carried,
-- setWornItem on its body location); again before the shot
function S.glasses()
    local ok, e = pcall(S.L.glasses, S)
    if not ok then S.say("ERR glasses: " .. tostring(e)) end
    local worn = false
    local items = S.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == S.L.GLASSES and S.p:isEquippedClothing(it) then worn = true end
    end
    S.say("prescription glasses worn " .. tostring(worn))
end
function S.charCovered()
    return S.L.clear(S):find("COVERED", 1, true) ~= nil
end

S.step(10, function()
    S.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.L.keepCheats(S)
    if getGameSpeed() ~= 1 then setGameSpeed(1) end
    if math.abs(S.p:getX() - S.L.HOME.x) > 3 or math.abs(S.p:getY() - S.L.HOME.y) > 3 then
        S.L.moveTo(S, S.L.HOME.x, S.L.HOME.y, S.L.HOME.z)
        S.say("moved to the QA home")
    end
    pcall(function()
        local r = getFileReader("gallery_v1_b_recipe.txt", false)
        if r then local l = r:readLine(); r:close(); if l and #l > 0 then S.RECIPE = l end end
    end)
    S.say("recipe " .. S.RECIPE)
    S.L.cheats(S); S.L.console()
    S.glasses()
    pcall(S.watermark, false)
    S.say("build line hidden " .. tostring(S.wmWas == true))
    S.rag = S.L.give(S, "Base.RippedSheets")
    S.bottle = S.L.give(S, "Base.Brandy")
    S.L.hideFluids(S, S.bottle)
end)
S.step(60, function()
    local r = nil
    local sm = getScriptManager()
    r = sm:getCraftRecipe(S.RECIPE)
    if not r and not string.find(S.RECIPE, ".", 1, true) then r = sm:getCraftRecipe("Base." .. S.RECIPE) end
    if not r then S.say("ERR no craft recipe " .. S.RECIPE .. ": the window opens on the game's first recipe") end
    local ok, e = pcall(function() ISEntityUI.OpenHandcraftWindow(S.p, nil, nil, true, r) end)
    if not ok then S.say("ERR open: " .. tostring(e)) end
end)
S.step(90, function()
    local w = S.win()
    if not w then S.L.notTaken(S, "g1_46_craft_van", "the crafting window did not open"); return end
    S.place = { x = w:getX(), y = w:getY() }
    S.say("the window at the game's place: " .. math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight()))
    pcall(function()
        local l = w.handCraftPanel and w.handCraftPanel.logic
        local rc = l and l:getRecipe()
        S.say("selected recipe " .. tostring(S.L.call(rc, "getName")) .. ", can make " .. tostring(l and l:canPerformCurrentRecipe()))
    end)
    if S.charCovered() then
        w:setX(40)
        if S.charCovered() then w:setX(getCore():getScreenWidth() - w:getWidth() - 40) end
        S.say("slid to one side: x " .. math.floor(w:getX()) .. " (the character " .. S.L.clear(S) .. ")")
    end
    if GAL_UNLOAD and GAL_UNLOAD.park then GAL_UNLOAD.park() end
end)
S.step(40, function()
    if not S.win() then return end
    S.glasses()
    pcall(S.watermark, false)
    S.L.shot(S, "g1_46_craft_van")
end)

S.step(10, function()
    local w = S.win()
    if w then
        if S.place then w:setX(S.place.x); w:setY(S.place.y) end
        pcall(function() w:close() end)
    end
end)
S.step(10, function()
    pcall(S.watermark, true)
    pcall(S.L.takeBack, S)
    pcall(S.L.unhide, S)
    if S.home then pcall(S.L.moveTo, S, S.home.x, S.home.y, S.home.z) end
    pcall(S.L.putCheats, S)
    pcall(S.L.summary, S)
    S.say("put back: the window shut at its own place, given things out, fluid holders back, the place")
    S.L.done(S)
end)
S.L.run(S)
