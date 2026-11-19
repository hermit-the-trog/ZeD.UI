-- ZeDUI/tools/qa/gallery_v1_b_van.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's vanilla crafting picture, ZeD OFF
-- (the save's mods.txt holds ZeDQAShim in place of ZeD_UI: gallery_v1_b_van.txt). Calls nothing of ZeD's.
-- Needs gallery_v1_b_lib.lua first.
--   g1_46_craft_van   46 Crafting (pitch image 4) and 04's left picture: the game's own B42 crafting window
--                     (ISEntityUI.OpenHandcraftWindow, as the game opens it) on the same recipe as g1_46_craft_zed,
--                     read from Zomboid/Lua/gallery_v1_b_recipe.txt (the ZeD run writes it; Make Molotov Cocktail
--                     without it), with the same things carried: a rag and a bottle of brandy given, every other
--                     fluid holder taken out for the run, so ingredients show partly missing
-- In the West Point kitchen (gallery_v1_b_place.lua, GV1P, as the ZeD run), after the QA home. The window opens at the game's place and size; if it covers the character it is slid to
-- the screen's left edge (else the right), its size kept, so the character and the place stay clear beside it. Its
-- place is put back before it closes (the game saves window places when one closes).
-- The glasses go on at the start and again before the shot (game calls only), and the build line at the bottom
-- right (WaterMarkUI) is hidden for the run.
-- The -debug line under the recipe's name ("( DBG:MakeMolotovCocktail)", added by the game's ISWidgetTitleHeader /
-- ISWidgetCraftLogicTitle when isDebugEnabled()) is cut from those title labels for the shot (ISLabel:setName on the
-- window's own labels) and put back after it.
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
    S.say("short sighted " .. tostring(S.L.shortSighted(S)) .. ", prescription glasses " .. (worn and "on" or "off"))
end
-- the window's labels carrying the game's "\n( DBG:<recipe>)" line: cut for the shot (on), put back (off)
function S.walkDbg(el, on, depth)
    if depth > 12 then return end
    for _, c in pairs(el.children or {}) do
        local n = c.name
        if on and type(n) == "string" and c.setName then
            local k = string.find(n, "\n( DBG:", 1, true)
            if k then
                S.dbg[#S.dbg + 1] = { c = c, n = n, o = c.origTitleStr }
                c:setName(string.sub(n, 1, k - 1))
                if c.origTitleStr then c.origTitleStr = string.sub(n, 1, k - 1) end
                if c.setHeightToName then c:setHeightToName(0) end
            end
        end
        S.walkDbg(c, on, depth + 1)
    end
end
function S.noDbg(on)
    local w = S.win()
    if on then
        S.dbg = S.dbg or {}
        if w then S.walkDbg(w, true, 0) end
        S.say("debug lines cut from the title: " .. #S.dbg)
    else
        for _, e in ipairs(S.dbg or {}) do
            e.c:setName(e.n)
            if e.o then e.c.origTitleStr = e.o end
            if e.c.setHeightToName then e.c:setHeightToName(0) end
        end
        S.dbg = {}
    end
end
-- (Nov 18 2026: the beta 19 picture still had three -debug extras: the "( DBG:...)" title line, the Force Action
-- button and a "(tags: ...)" line under every recipe in the list. All three come from the game's own isDebugEnabled()
-- checks (ISWidgetTitleHeader, ISWidgetHandCraftControl, ISRecipeScrollingListBox), so for this window only the global
-- answers false: from just before the window is built until just after it closes.)
function S.debugOff(off)
    if off then
        if not S.dbgFn then S.dbgFn = isDebugEnabled; isDebugEnabled = function() return false end end
    elseif S.dbgFn then
        isDebugEnabled = S.dbgFn; S.dbgFn = nil
    end
    S.say("isDebugEnabled for the window: " .. tostring(isDebugEnabled()))
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
if GV1P then GV1P.kitchen(S) else S.say("ERR gallery_v1_b_place.lua did not run: the shot stays at the QA home") end
S.step(60, function()
    local r = nil
    local sm = getScriptManager()
    r = sm:getCraftRecipe(S.RECIPE)
    if not r and not string.find(S.RECIPE, ".", 1, true) then r = sm:getCraftRecipe("Base." .. S.RECIPE) end
    if not r then S.say("ERR no craft recipe " .. S.RECIPE .. ": the window opens on the game's first recipe") end
    S.debugOff(true)
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
    local okD, eD = pcall(S.noDbg, true)
    if not okD then S.say("ERR the debug line: " .. tostring(eD)) end
    S.L.shot(S, "g1_46_craft_van")
end)

S.step(10, function()
    pcall(S.noDbg, false)
    local w = S.win()
    if w then
        if S.place then w:setX(S.place.x); w:setY(S.place.y) end
        pcall(function() w:close() end)
    end
    S.debugOff(false)
end)
S.step(10, function()
    pcall(S.debugOff, false)
    pcall(S.watermark, true)
    if GV1P then pcall(GV1P.back, S) end
    pcall(S.L.takeBack, S)
    pcall(S.L.unhide, S)
    if S.home then pcall(S.L.moveTo, S, S.home.x, S.home.y, S.home.z) end
    pcall(S.L.putCheats, S)
    pcall(S.L.summary, S)
    S.say("put back: the window shut at its own place, given things out, fluid holders back, the place")
    S.L.done(S)
end)
S.L.run(S)
