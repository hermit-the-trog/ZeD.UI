-- ZeDUI/tools/qa/zedqa_visual_audit.lua  (Oct 20 2026)
-- The visual audit walk: screenshots of every ZeD panel in every theme, at both
-- text sizes, and every accent, with every scrolling panel taken at its top AND
-- scrolled to its bottom. In game on the ZeD-QA save (unpaused). Not in
-- regression.txt (it takes a few hundred screenshots): run it by hand.
-- Screenshots: getCore():TakeFullScreenshot("va_<nn>_<theme>_<accent>_<text>_<screen>.png")
--   theme  dark | light | hicon (the base themes ZeD.Settings.baseKeys offers)
--   text   normal (ZeD's Small) | large
--
-- Pass 1, the combinations: text Normal then Large (the windows are closed and
-- reopened after a size change, so every metric is rebuilt), and in each, the
-- three base themes, at the accent the player had:
--   Character window   Loot as a list, as a grid, an item card on a food, the
--                      multi-container view (inventory + a worn bag: list, grid);
--                      Equip, Health, Thermal, Identity, Journal (diary), Skills.
--                      Each scrolling panel at its top and at its bottom.
--   World window       Loot, Craft (list, a recipe open), Building (list, a
--                      recipe open), Furniture, Forage, Animals (top and bottom);
--                      Maps, Radio and Vehicle (one shot each, when the tab is there).
-- Pass 2, the accents: text Normal, the themes light and dark, each of the nine
-- accents: the inventory grid, a food's item card, the Health tab (accent-tinted
-- text and chips).
-- Thirty mixed items are added to the inventory and thirty to a bag (worn, else
-- in the hand) so that the lists scroll; the bag is also the second column of
-- the multi-container view. Everything is put back at the end: theme, accent,
-- text size (set with ZeD.applyTheme, so no mod option is touched and nothing
-- is written to disk; the test language option is not touched and is only read
-- and printed), grid views, the added items, the hands, worn items, the windows
-- open or shut as they were, the tabs, the windows' own accent choices.
-- Window accent choices are cleared for the walk (a window with its own accent
-- would hide the global accent) and put back.
-- Output: "ZEDQA va <nn> <what> -> <file>" per screenshot, "MISSING" for a screen
-- that cannot be reached, ERR lines for anything that failed, "ZEDQA va DONE" last.
-- Driven from OnRenderTick. Skipped on purpose: the Journal's other sub-tabs,
-- Thermal's other views and the World window's multi-container view (their
-- shots are in zedqa_testlang.lua / zedqa_container_*.lua), and screens that
-- would only repeat another.
local TAG = "va"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end

-- Targeted run: the global ZEDQA_VA_ONLY (a comma list, set by a prelude line such as
-- zedqa_va_only.lua, or typed into the Lua command line before the run) keeps pass 1 to the named
-- sections and drops pass 2. Sections: list card grid mc equip health thermal identity journal skills
-- wloot craft build furn maps forage animals acc. With ZEDQA_VA_ONLY set, ZEDQA_VA_BASES (default
-- "dark,light") picks the base themes. Nothing set = the whole walk, as before.
local ONLY, ONLY_BASES = nil, nil
do
    local raw = rawget(_G, "ZEDQA_VA_ONLY")
    if type(raw) == "string" and raw ~= "" and raw ~= "all" then
        ONLY = {}
        for w in string.gmatch(raw, "[%w_]+") do ONLY[w] = true end
        ONLY_BASES = {}
        for w in string.gmatch(tostring(rawget(_G, "ZEDQA_VA_BASES") or "dark,light"), "[%w_]+") do ONLY_BASES[w] = true end
    end
end
local function want(section) return (not ONLY) or ONLY[section] == true end
local p = getPlayer()
if not p then say("ERR no player"); return end
local pn = p:getPlayerNum()
local inv = p:getInventory()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local S = ZeD.Safe
local IR = ZeD.InventoryRenderer
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end

-- ---------------------------------------------------------------------------
-- What there was, to put back
-- ---------------------------------------------------------------------------
local baseWas, accentWas, sizeWas = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
local testOpt = ZeD.Settings.testLanguageOption
local testAtStart = testOpt and testOpt:getValue()
local gvStore = p:getModData().ZeD_GridViews
local gridWas = gvStore and gvStore.player
local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local wasChar, wasWorld = CWm.isOpen(), WWm.isOpen()
local cw0 = CW() and CW()._activeTab
local ww0 = WW() and WW()._activeTab
local speedWas = getGameSpeed()
local ws0 = p:getModData().ZeD_WinState
local function accentOf(win, st) if win then return win._accentKey end; return st and st.accentKey end
local accC0 = accentOf(CW(), ws0 and ws0.char)
local accW0 = accentOf(WW(), ws0 and ws0.world)
local furModeWas = ZeD.FurnitureTab and ZeD.FurnitureTab.state and ZeD.FurnitureTab.state.mode
local furVisited = false
local jumpAbort = false   -- set by a step that finds the walk cannot go on: straight to putting things back

local added, worn = {}, {}
local bagInv, bagKey = nil, nil
local nShot = 0
local lastMiss = false

-- ---------------------------------------------------------------------------
-- Helpers (all above their users)
-- ---------------------------------------------------------------------------
local function shot(screen, note)
    nShot = nShot + 1
    local text = (ZeD.currentSize == "large") and "large" or "normal"
    local f = string.format("va_%03d_%s_%s_%s_%s.png", nShot, tostring(ZeD.currentBase), tostring(ZeD.currentAccent), text, screen)
    local ok, e = pcall(function() getCore():TakeFullScreenshot(f) end)
    say(string.format("%03d %s%s -> %s", nShot, screen, note and (" (" .. note .. ")") or "", f) .. (ok and "" or (" ERR " .. tostring(e))))
end

local function give(into, full, name)
    local it = into:AddItem(full)
    if it then
        added[#added + 1] = it
        if name then pcall(function() it:setName(name); it:setCustomName(true) end) end
    else
        say("ERR could not add " .. full)
    end
    return it
end

-- an item this script added, by type; plain = true skips the ones given a custom name
local function found(full, plain)
    for _, it in ipairs(added) do
        local ok, hit = pcall(function()
            return it:getFullType() == full and not (plain and it:isCustomName())
        end)
        if ok and hit then return it end
    end
    return nil
end

-- worn only into a free place: nothing the character wears is displaced. The place is resolved as
-- vanilla's ISWearClothing does: a bag (a container that can be equipped) by canBeEquipped() -- its
-- getBodyLocation() is null, and setWornItem(null, ...) is the NullPointerException that left the bag
-- unworn -- clothing by its body location. Returns the item only when it really is worn.
local function wear(full)
    local it = inv:AddItem(full)
    if not it then say("ERR could not add " .. full); return nil end
    local loc = nil
    pcall(function()
        if instanceof(it, "InventoryContainer") then
            local c = it:canBeEquipped()
            if c ~= nil and tostring(c) ~= "" then loc = c end
        end
        if loc == nil then loc = it:getBodyLocation() end
    end)
    if loc == nil then inv:Remove(it); say("note: " .. full .. " not worn, no body location"); return nil end
    local busy = false
    pcall(function() busy = p:getWornItem(loc) ~= nil end)
    if busy then inv:Remove(it); say("note: " .. full .. " not worn, the place is taken"); return nil end
    local ok, e = pcall(function() p:setWornItem(loc, it) end)
    local isWorn = false
    pcall(function() isWorn = p:isEquippedClothing(it) or (p:getWornItem(loc) == it) end)
    if not ok or not isWorn then
        pcall(function() p:removeWornItem(it) end)
        inv:Remove(it)
        say("note: " .. full .. " could not be worn (" .. tostring(e) .. ")")
        return nil
    end
    worn[#worn + 1] = it
    return it
end

local function closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
local function openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end

-- the strip's own click (as the player's); true when the tab is on the strip
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return (w and goTab(w, w._tabStripPanel, id)) and true or false end
local function worldTab(id) local w = WW(); return (w and goTab(w, w._actionTabStrip, id)) and true or false end

-- an item selected in the Character window's Loot list opens its card (nil closes it)
local function selectItem(item)
    local w = CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end

local function openRecipe(kind)   -- "craft" | "build": the first recipe the character can make
    local w = WW()
    if not w then return end
    local mod = (kind == "craft") and ZeD.CraftingTab or ZeD.BuildingTab
    local st = (kind == "craft") and w._craftState or w._buildState
    if not st then say("ERR no " .. kind .. " state"); return end
    local data = mod.gatherData(p, w)
    local pick = nil
    for _, rd in ipairs(data and data.recipes or {}) do
        if rd.status == "unlocked" then pick = rd; break end
    end
    pick = pick or (data and data.recipes and data.recipes[1])
    if not pick then say("MISSING a recipe to open in " .. kind); return end
    ZeD.CraftingCore.openCraft(st, pick.entry.name)
end
local function closeRecipe(kind)
    local w = WW()
    local st = w and ((kind == "craft") and w._craftState or w._buildState)
    if st then ZeD.CraftingCore.closeCraft(st) end
end

-- the window accents: cleared for the walk, put back at the end (live windows and the saved state)
local function clearWindowAccents()
    local c, w = CW(), WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end
local function putAccentsBack()
    local c, w = CW(), WW()
    if c then c._accentKey = accC0 end
    if w then w._accentKey = accW0 end
    local ws = p:getModData().ZeD_WinState
    if ws then
        if ws.char then ws.char.accentKey = accC0 end
        if ws.world then ws.world.accentKey = accW0 end
    end
end

-- ---- the bag: the second column of the multi-container view
local function bagIdx()
    local w = CW()
    for i, c in ipairs(w and w._containers or {}) do
        if bagInv and c.inventory == bagInv then return i end
    end
    return nil
end
-- the bag's button on the container strip, clicked as the player does; true when it was clicked
local function clickBag()
    local w = CW()
    local idx = bagIdx()
    local strip = w and w._containerStrip
    if not (strip and idx) then return false end
    for _, z in ipairs(strip._hitZones or {}) do
        if z.id == "cnt:" .. idx then
            strip:onMouseDown(z.x + 2, z.y + 2)
            strip:onMouseUp(z.x + 2, z.y + 2)
            return true
        end
    end
    return false
end
local function setGrids(on)   -- the inventory and the bag: grid or list
    IR.setGridKey("player", on)
    if bagKey then IR.setGridKey(bagKey, on) end
end

-- ---- scrolling: every scroll state a panel can have, set to the top (0) or the bottom (1)
local function lootBars(c)
    local list = {}
    if c then
        list[#list + 1] = c._scroll
        for _, cs in ipairs(c._colStates or {}) do list[#list + 1] = cs.scroll end
    end
    return list
end
local function charBars()
    local w = CW()
    if not w then return {} end
    local t = w._activeTab
    if t == "loot" then return lootBars(w._mainContent) end
    if t == "health" then return { w._healthScroll } end
    if t == "skills" then return { w._skillsScroll } end
    if t == "thermal" then return { w._thermalScroll } end
    if t == "identity" then return { w._identityScroll } end
    if t == "equip" then return { w._equipScroll } end
    if t == "journal" then return { w._journalScroll } end   -- (the diary sub-tab)
    return {}
end
local function worldBars()
    local w = WW()
    if not w then return {} end
    local t = w._activeTab
    if t == "loot" then return lootBars(w._mainContent) end
    if t == "craft" or t == "build" then
        local st = (t == "craft") and w._craftState or w._buildState
        if st then return { st.scroll, st.altScroll, st.cardScroll } end
        return {}
    end
    if t == "forage" then return { w._forageScroll } end
    if t == "animals" then return { w._animalsScroll } end
    return {}
end
local function barsOf(which) if which == "c" then return charBars() end; return worldBars() end
local function scrollTo(which, pos)
    if which == "w" then
        local w = WW()
        if w and w._activeTab == "furniture" and w._fur then w._fur.scrollY = (pos >= 1) and 1000000 or 0 end
    end
    for _, sc in ipairs(barsOf(which)) do
        if sc.setScrollPos then sc:setScrollPos(pos) end
    end
end
-- how much of the panel shows (1 = it all fits), for the line in the log
local function fitNote(which)
    local lo = nil
    for _, sc in ipairs(barsOf(which)) do
        local r = sc.barSizeRatio
        if r and (not lo or r < lo) then lo = r end
    end
    return lo and string.format("shows %d%% of the panel", math.floor(lo * 100 + 0.5)) or nil
end

-- ---------------------------------------------------------------------------
-- The sequencer: step(after, fn) runs fn once, `after` frames after the step
-- before it ended; poll(after, max, fn, onTimeout) runs fn every frame until
-- it returns true (onTimeout after max frames). A failing step prints ERR and
-- the walk goes on.
-- ---------------------------------------------------------------------------
local queue, marks = {}, {}
local function step(after, fn) queue[#queue + 1] = { after = after, fn = fn } end
local function poll(after, max, fn, onTimeout) queue[#queue + 1] = { after = after, fn = fn, max = max, timeout = onTimeout } end
local function mark(name) marks[name] = #queue + 1 end
local function noop() end

-- ---- enqueue helpers
-- go to a tab (lastMiss true when it is not there; an optional tab is skipped without a word)
local function openTab(which, tab, optional)
    step(0, function() lastMiss = false end)
    poll(2, optional and 6 or 90, function()
        if which == "c" then return charTab(tab) end
        return worldTab(tab)
    end, function()
        lastMiss = true
        if not optional then say("MISSING " .. ((which == "c") and "Character" or "World") .. " tab " .. tab .. " (not reachable here)") end
    end)
end
-- the panel on screen, at its top, then scrolled to its bottom, then back at the top
local function scrollShots(which, name, settle)
    step(2, function() if not lastMiss then scrollTo(which, 0) end end)
    step(settle or 30, function() if not lastMiss then shot(name .. "_top") end end)
    step(2, function() if not lastMiss then scrollTo(which, 1) end end)
    step(16, function() if not lastMiss then shot(name .. "_bottom", fitNote(which)) end end)
    step(2, function() if not lastMiss then scrollTo(which, 0) end end)
end
local function tabWalk(which, tab, name, settle, optional)
    openTab(which, tab, optional)
    scrollShots(which, name, settle)
end
local function singleShot(which, tab, name, settle, optional)
    openTab(which, tab, optional)
    step(settle or 30, function() if not lastMiss then shot(name) end end)
end

-- a theme / accent / text size; a new text size closes and reopens the windows (every metric rebuilt)
local planSize = ZeD.currentSize
local function look(base, accent, size)
    step(2, function()
        clearWindowAccents()
        ZeD.applyTheme(base, accent, size)
    end)
    if size and size ~= planSize then
        planSize = size
        step(10, function() closePair() end)
        step(30, function() openPair() end)
        step(70, function() clearWindowAccents() end)
    else
        step(25, function() end)
    end
end

-- ---------------------------------------------------------------------------
-- Put everything back (safe to run twice; also the abort path)
-- ---------------------------------------------------------------------------
local function restoreAll()
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() selectItem(nil) end)
    pcall(function() closeRecipe("craft"); closeRecipe("build") end)
    pcall(function()
        local w = CW()
        if w and #(w._mcSelected or {}) > 0 then clickBag() end
    end)
    pcall(function() scrollTo("c", 0); scrollTo("w", 0) end)
    pcall(function()
        if furVisited and ZeD.FurnitureTab then ZeD.FurnitureTab.setMode(pn, furModeWas or "place") end
    end)
    pcall(function() p:setPrimaryHandItem(prim); p:setSecondaryHandItem(sec) end)
    for _, it in ipairs(added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    for _, it in ipairs(worn) do pcall(function() p:removeWornItem(it) end) end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    for _, it in ipairs(worn) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    worn, added = {}, {}
    pcall(function()
        local gv = p:getModData().ZeD_GridViews
        if gv then
            gv.player = gridWas
            if bagKey then gv[bagKey] = nil end
        end
    end)
    pcall(function() ZeD.applyTheme(baseWas, accentWas, sizeWas) end)
    pcall(putAccentsBack)
    pcall(function() if getGameSpeed() <= 0 or speedWas > 0 then setGameSpeed(speedWas > 0 and speedWas or 1) end end)
end

-- ===========================================================================
-- THE WALK
-- ===========================================================================
-- the thirty things for the inventory and the thirty for the bag (names given to a few so rows wrap)
local INV_ITEMS = {
    { "Base.Hammer", "Extraordinarily Well Preserved Commemorative Claw Hammer" }, { "Base.Apple" },
    { "Base.Apple", "Absurdly Long Named Orchard Fresh Granny Smith Apple" }, { "Base.Steak" }, { "Base.BaseballBat" },
    { "Base.Book" }, { "Base.WaterBottle" }, { "Base.WaterBottle" },
    { "Base.TinnedBeans", "Family Size Hearty Country Style Baked Beans In Rich Tomato Sauce" }, { "Base.Pistol" },
    { "Base.Nails" }, { "Base.Screws" }, { "Base.Plank" }, { "Base.Rope" }, { "Base.Banana" }, { "Base.Orange" },
    { "Base.Pop" }, { "Base.Crisps" }, { "Base.Screwdriver" }, { "Base.Wrench" }, { "Base.Bandage" }, { "Base.Pills" },
    { "Base.Matches" }, { "Base.Lighter" }, { "Base.Torch" }, { "Base.Battery" }, { "Base.Cheese" }, { "Base.Bread" },
    { "Base.KitchenKnife" }, { "Base.Axe", "Wilderness Survival Association Limited Edition Splitting Axe" },
}
local BAG_ITEMS = {
    { "Base.Pen" }, { "Base.Pencil" }, { "Base.Scissors" }, { "Base.Tweezers" }, { "Base.Money" }, { "Base.Twine" },
    { "Base.Needle" }, { "Base.Candle" }, { "Base.Sheet" }, { "Base.Egg" }, { "Base.Carrots" }, { "Base.Potato" },
    { "Base.Spoon" }, { "Base.Fork" }, { "Base.Banana" }, { "Base.Orange" }, { "Base.Crisps" }, { "Base.Nails" },
    { "Base.Screws" }, { "Base.Rope" }, { "Base.Bandage" }, { "Base.Pills" }, { "Base.Matches" }, { "Base.Lighter" },
    { "Base.Battery" }, { "Base.Cheese" }, { "Base.Bread" }, { "Base.Apple" },
    { "Base.Book", "The Complete Illustrated Encyclopedia of Rural Survival Skills Volume Three" }, { "Base.TinnedBeans" },
}

-- ---- 1. the windows, the items, the bag
step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("start: theme " .. tostring(baseWas) .. "/" .. tostring(accentWas) .. "/" .. tostring(sizeWas)
        .. " | test language option " .. tostring(testAtStart) .. " (left alone) | windows char " .. tostring(wasChar)
        .. " world " .. tostring(wasWorld) .. " | tabs " .. tostring(cw0) .. " / " .. tostring(ww0))
    if S.on() then
        say("ERR safe mode is on: ZeD windows are off, nothing to walk")
        jumpAbort = true
    end
    openPair()
    for _, e in ipairs(INV_ITEMS) do
        local it = give(inv, e[1], e[2])
        if it and e[1] == "Base.WaterBottle" then pcall(function() it:getFluidContainer():addFluid("Water", 0.5) end) end
    end
    -- the bag: worn on the back, else in the primary hand (either way it is a container of the window)
    local bag = wear("Base.Bag_Schoolbag")
    if not bag then
        bag = give(inv, "Base.Bag_DuffelBag")
        if bag then p:setPrimaryHandItem(bag) end
    end
    if bag then
        bagInv = bag:getInventory()
        bagKey = IR.containerKey(bagInv, p)
        for _, e in ipairs(BAG_ITEMS) do give(bagInv, e[1], e[2]) end
    else
        say("MISSING a bag: the multi-container view will be skipped")
    end
    triggerEvent("OnClothingUpdated", p)
    say("added " .. #added .. " items (inventory and bag) | bag key " .. tostring(bagKey))
end)
step(60, function() end)

-- ---- 2. one combination: the Character window, then the World window
-- (every section is behind want(): a targeted run -- ZEDQA_VA_ONLY -- takes only the ones it names)
local function comboWalk()
    -- Character window: Loot as a list, a food's card, as a grid
    step(2, function() setGrids(false) end)
    if want("list") then tabWalk("c", "loot", "char_loot_list", 30) end
    if want("card") then
        openTab("c", "loot")
        step(2, function()
            if lastMiss then return end
            local it = found("Base.Apple", true); if it then selectItem(it) end
        end)
        step(45, function() if not lastMiss then shot("char_loot_card_food") end end)
        step(2, function() selectItem(nil) end)
        step(25, function() end)
    end
    if want("grid") then
        openTab("c", "loot")
        step(2, function() setGrids(true) end)
        scrollShots("c", "char_loot_grid", 30)
        step(2, function() setGrids(false) end)
    end
    -- the multi-container view: the inventory and the bag side by side
    if want("mc") then
        openTab("c", "loot")
        step(0, function() lastMiss = false end)
        poll(2, 240, function() return clickBag() end, function()
            lastMiss = true
            say("MISSING the bag's button on the container strip (no multi-container view)")
        end)
        step(45, function()
            if lastMiss then return end
            local w = CW()
            local n = w and #(w._mcSelected or {}) or 0
            say("multi-container: " .. n .. " bag column(s), inventory column " .. tostring(w and w._mainVisible))
            if n == 0 then lastMiss = true; say("MISSING the multi-container view did not open") end
        end)
        scrollShots("c", "char_mc_list", 30)
        step(2, function() if not lastMiss then setGrids(true) end end)
        scrollShots("c", "char_mc_grid", 30)
        step(2, function() setGrids(false) end)
        poll(2, 120, function()
            local w = CW()
            if not w or #(w._mcSelected or {}) == 0 then return true end
            clickBag()   -- (the view is shut at once: the next frame sees it)
            return false
        end, function() say("ERR the multi-container view did not close") end)
        step(30, function() end)
    end
    -- the other Character tabs
    if want("equip") then tabWalk("c", "equip", "char_equip", 30) end
    if want("health") then tabWalk("c", "health", "char_health", 30) end
    if want("thermal") then tabWalk("c", "thermal", "char_thermal", 30) end
    if want("identity") then tabWalk("c", "identity", "char_identity", 30) end
    if want("journal") then
        step(2, function() local w = CW(); if w then w._journalSubTab = 1 end end)
        tabWalk("c", "journal", "char_journal", 30)
    end
    if want("skills") then tabWalk("c", "skills", "char_skills", 30) end
    -- World window
    if want("wloot") then tabWalk("w", "loot", "world_loot", 30) end
    if want("craft") then
        tabWalk("w", "craft", "world_craft_list", 40)
        step(2, function() if not lastMiss then openRecipe("craft") end end)
        scrollShots("w", "world_craft_recipe", 40)
        step(2, function() closeRecipe("craft") end)
    end
    if want("build") then
        tabWalk("w", "build", "world_build_list", 40)
        step(2, function() if not lastMiss then openRecipe("build") end end)
        scrollShots("w", "world_build_recipe", 40)
        step(2, function() closeRecipe("build") end)
    end
    if want("furn") then
        step(2, function() furVisited = true end)
        tabWalk("w", "furniture", "world_furniture", 40)
    end
    if want("maps") then singleShot("w", "maps", "world_maps", 70) end
    if want("forage") then tabWalk("w", "forage", "world_forage", 40) end
    if want("animals") then tabWalk("w", "animals", "world_animals", 40) end
    if want("radio") then singleShot("w", "radio", "world_radio", 40, true) end
    if want("vehicle") then singleShot("w", "vehicle", "world_vehicle", 40, true) end
    step(2, function() pcall(function() ZeD.FurnitureTab.setMode(pn, furModeWas or "place") end) end)
    openTab("w", "loot")
    step(10, function() end)
end

-- ---- pass 1: text Normal then Large, each in every base theme, at the player's accent
for _, size in ipairs({ "small", "large" }) do
    for _, base in ipairs(ZeD.Settings.baseKeys) do
        if (not ONLY_BASES) or ONLY_BASES[base] then
            look(base, accentWas, size)
            comboWalk()
        end
    end
end

-- ---- pass 2: every accent, text Normal, light and dark: the grid, a card, the Health tab
local function accentWalk()
    step(2, function() IR.setGridKey("player", true) end)
    openTab("c", "loot")
    step(25, function() if not lastMiss then shot("acc_inventory_grid") end end)
    step(2, function()
        if lastMiss then return end
        local it = found("Base.Apple", true); if it then selectItem(it) end
    end)
    step(45, function() if not lastMiss then shot("acc_item_card") end end)
    step(2, function() selectItem(nil) end)
    openTab("c", "health")
    step(30, function() if not lastMiss then shot("acc_health") end end)
end
if want("acc") then
    for _, base in ipairs({ "light", "dark" }) do
        for _, accent in ipairs(ZeD.Settings.accentKeys) do
            look(base, accent, "small")
            accentWalk()
        end
    end
end

-- ---- 3. put everything back
mark("restore")
step(5, function() restoreAll() end)
step(25, function() closePair() end)
step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(speedWas > 0 and speedWas or 1) end
    if wasChar and wasWorld then openPair()
    else
        if wasChar then CWm.toggle(0) end
        if wasWorld then WWm.open(0) end
    end
end)
step(50, function()
    pcall(putAccentsBack)
    if cw0 and CW() then charTab(cw0) end
    if ww0 and WW() then worldTab(ww0) end
    say("back: theme " .. tostring(ZeD.currentBase) .. "/" .. tostring(ZeD.currentAccent) .. "/" .. tostring(ZeD.currentSize)
        .. " (was " .. tostring(baseWas) .. "/" .. tostring(accentWas) .. "/" .. tostring(sizeWas) .. ")"
        .. " | test language option " .. tostring(testOpt and testOpt:getValue()) .. " (was " .. tostring(testAtStart) .. ")"
        .. " | safe mode on=" .. tostring(S.on())
        .. " | windows char " .. tostring(CWm.isOpen()) .. " world " .. tostring(WWm.isOpen())
        .. " | " .. tostring(nShot) .. " screenshots")
    say("DONE")
end)

-- ---------------------------------------------------------------------------
-- Driving it (OnRenderTick, like zedqa_testlang.lua)
-- ---------------------------------------------------------------------------
local tick, qi, lastDone = 0, 1, 0
local MAX_TICKS = 30000   -- a stuck run stops here and puts things back (about 8 minutes at 60 fps)
local function onFrame()
    tick = tick + 1
    if jumpAbort and marks.restore and qi < marks.restore then
        jumpAbort = false
        say("aborting the walk, putting things back")
        qi = marks.restore; lastDone = tick
    end
    local s = queue[qi]
    if not s then Events.OnRenderTick.Remove(onFrame); return end
    if tick > MAX_TICKS and marks.restore and qi < marks.restore then
        say("ERR the walk ran past " .. MAX_TICKS .. " frames at step " .. qi .. ": putting things back")
        qi = marks.restore; lastDone = tick
        return
    end
    if not s.startTick then
        if tick - lastDone < s.after then return end
        s.startTick = tick
    end
    local done = true
    local ok, r = pcall(s.fn)
    if not ok then
        say("ERR step " .. qi .. " (frame " .. tick .. ") " .. tostring(r))
    elseif s.max then
        done = r == true
        if not done and tick - s.startTick >= s.max then
            local ok2, e2 = pcall(s.timeout or noop)
            if not ok2 then say("ERR step " .. qi .. " timeout " .. tostring(e2)) end
            done = true
        end
    end
    if done then
        lastDone = tick
        qi = qi + 1
    end
end
Events.OnRenderTick.Add(onFrame)
say("start (" .. #queue .. " steps)")
