-- ZeDUI/tools/qa/zedqa_testlang.lua  (Oct 20 2026)
-- Phase 3 of TRANSLATION_PLAN.md: the screenshot walk with the test language.
-- In game on the ZeD-QA save (unpaused). Turns the hidden Test language option
-- On (ZeD.Settings.testLanguageOption, read by ZeD.tr every 500 ms: every ZeD
-- phrase about 40% longer, accented, in brackets), closes and reopens both
-- windows (words built once, like the search placeholders, only change when
-- rebuilt), then walks every ZeD screen reachable in game and takes
-- getCore():TakeFullScreenshot("zqa_tl_<nn>_<name>.png") of each:
--   Character window  every tab; Loot as list and grid; Equip as list and doll
--                     (cap and jacket worn); Thermal's seven views; Journal's
--                     four sub-tabs; Radio (a walkie-talkie in the off hand)
--   World window      Loot, Craft (list, a recipe open), Building (list, a
--                     recipe open), Furniture (its five modes), Maps (Survey,
--                     Color, Paper), Forage, Animals, Radio and Vehicle when
--                     the tab is there, a Fluid object card
--   item cards        a food item, a weapon, a water bottle
--   context menus     the strip on a food item and on a weapon, then as a list
--   the belt          mini watch on the belt, the popped watch, Corner mode,
--                     the hands (hammer, walkie-talkie)
--   the action bar    reading a book: Verbose and Simple
--   wheels            the emote wheel, the vehicle wheel outside a vehicle
--   prompts           question, text box, on-screen keyboard, alarm, timer,
--                     long help note, rich question
--   safe mode         the game's own note after a trip (reset again), and the
--                     state free of safe mode checked at the start and the end
--   the pause menu    the pause window, every group of Options, the Mods page
-- Several items with long names are added to the inventory for the Loot lists.
-- Everything is put back at the end: the option Off, the added items gone, the
-- hands, worn items, view options, map style, watch place and tab as they were,
-- the windows open or shut as they were.
-- A screen that cannot be reached (no radio near, no vehicle in reach...) is
-- printed as "MISSING". Output: "ZEDQA tlang <nn> <what>" per screenshot, ERR
-- lines for anything that failed, "ZEDQA tlang DONE" last. grep "ZEDQA tlang".
-- Driven from OnRenderTick (the pause menu stops OnTick).
local TAG = "tlang"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local pn = p:getPlayerNum()
local inv = p:getInventory()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local MM, S, OC = ZeD.MainMenu, ZeD.Safe, ZeD.ObjectCards
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function zm() local v = getPlayerContextMenu(pn); return v and v._zedMenu end

-- ---------------------------------------------------------------------------
-- What there was, to put back
-- ---------------------------------------------------------------------------
local testOpt = ZeD.Settings.testLanguageOption
local testWas = 1   -- always leave the test language Off: it is saved in ModOptions.ini
local ctxOpt, ctxWas = ZeD.Settings.contextStyleOption, ZeD.Settings.contextStyleOption:getValue()
local watchOpt, watchWas = ZeD.Settings.watchPlaceOption, ZeD.Settings.watchPlaceOption:getValue()
local barOpt, barWas = ZeD.Settings.actionBarOption, ZeD.Settings.actionBarOption:getValue()
local equipWas = ZeD.EquipDoll.view()
local gvStore = p:getModData().ZeD_GridViews
local gridWas = gvStore and gvStore.player
local popWas = p:getModData().ZeD_WatchPop
local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local wasChar, wasWorld = CWm.isOpen(), WWm.isOpen()
local cw0 = CW() and CW()._activeTab
local ww0 = WW() and WW()._activeTab
local speedWas = getGameSpeed()
local mapWas = nil
local thermalFigWas = nil
local weTripped = false
local jumpAbort = false   -- set by a step that finds the walk cannot go on: straight to putting things back

local added, worn = {}, {}
local cur = nil          -- the prompt on screen
local nShot = 0
local lastMiss = false

-- ---------------------------------------------------------------------------
-- Helpers (all above their users)
-- ---------------------------------------------------------------------------
local function shot(name, what)
    nShot = nShot + 1
    local f = string.format("zqa_tl_%02d_%s.png", nShot, name)
    local ok, e = pcall(function() getCore():TakeFullScreenshot(f) end)
    say(string.format("%02d %s -> %s", nShot, what or name, f) .. (ok and "" or (" ERR " .. tostring(e))))
end

local function give(full, name)
    local it = inv:AddItem(full)
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

-- worn only into a free place: nothing the character wears is displaced
local function wear(full)
    local it = inv:AddItem(full)
    if not it then say("ERR could not add " .. full); return nil end
    local busy = false
    pcall(function() busy = p:getWornItem(it:getBodyLocation()) ~= nil end)
    if busy then inv:Remove(it); say("note: " .. full .. " not worn, the place is taken"); return nil end
    p:setWornItem(it:getBodyLocation(), it)
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

local function closePrompt()
    local o = cur
    cur = nil
    if not o then return end
    pcall(function() o:answerCancel() end)
    if not o._dead then pcall(function() o:destroy() end) end
end

local function findNote()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local el = ui:get(i)
        local t = el:getTable()
        if t and t.Type == "ISModalDialog" and el:isVisible() then return t end
    end
    return nil
end
local function closeNote()
    local n = findNote()
    if not n then return false end
    if n.ok then n:onClick(n.ok) else n:destroy() end
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
    say("recipe open in " .. kind .. ": " .. tostring(pick.entry.name))
end
local function closeRecipe(kind)
    local w = WW()
    local st = w and ((kind == "craft") and w._craftState or w._buildState)
    if st then ZeD.CraftingCore.closeCraft(st) end
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

-- a tab: switch, wait, shot. A tab that is not on the strip is MISSING (no shot).
local function visit(w, tab, name, settle, wait)
    lastMiss = false
    poll(2, wait or 60, function()
        if w == "c" then return charTab(tab) end
        return worldTab(tab)
    end, function()
        lastMiss = true
        say("MISSING " .. ((w == "c") and "Character" or "World") .. " tab " .. tab .. " (not reachable here)")
    end)
    step(settle or 30, function() if not lastMiss then shot(name, ((w == "c") and "char tab " or "world tab ") .. tab) end end)
end
-- a state inside the tab just visited: do it, wait, shot
local function sub(name, what, fn, settle)
    step(2, function() if not lastMiss and fn then fn() end end)
    step(settle or 25, function() if not lastMiss then shot(name, what) end end)
end

-- ---------------------------------------------------------------------------
-- Put everything back (safe to run twice; also the abort path)
-- ---------------------------------------------------------------------------
local function restoreAll()
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(closePrompt)
    pcall(function() if ZeD.Keyboard and ZeD.Keyboard.instance and OnScreenKeyboard.IsVisible() then ZeD.Keyboard.instance:cancel() end end)
    pcall(function() local m = getPlayerRadialMenu(pn); if m then m:undisplay() end end)
    pcall(function() local m = zm(); if m then m:close() end end)
    pcall(function() if WWm.getObjectCard and WWm.getObjectCard() then WWm.closeObjectCard() end end)
    pcall(function() selectItem(nil) end)
    pcall(function() closeRecipe("craft"); closeRecipe("build") end)
    pcall(function()
        if weTripped or S.on() then closeNote(); S.reset(); weTripped = false end
    end)
    pcall(function()
        local ms = MainScreen.instance
        if ms and ms.inGame and ms:isVisible() and ToggleEscapeMenu then
            MM.pauseView = "pause"
            ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
        end
    end)
    pcall(function() p:setPrimaryHandItem(prim); p:setSecondaryHandItem(sec) end)
    for _, it in ipairs(worn) do
        pcall(function() p:removeWornItem(it) end)
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    for _, it in ipairs(worn) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    for _, it in ipairs(added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    worn, added = {}, {}
    pcall(function() ctxOpt:setValue(ctxWas) end)
    pcall(function() watchOpt:setValue(watchWas) end)
    pcall(function() barOpt:setValue(barWas) end)
    pcall(function() p:getModData().ZeD_WatchPop = popWas end)
    pcall(function() ZeD.EquipDoll.setView(equipWas) end)
    pcall(function() local gv = p:getModData().ZeD_GridViews; if gv then gv.player = gridWas end end)
    pcall(function()
        local w = WW()
        if mapWas and w then ZeD.MapsTab.setStyle(w, mapWas) end
        local t = CW()
        if t and thermalFigWas ~= nil then t._thermalFigureExpanded = thermalFigWas end
        if t then t._thermalView = 1; t._journalSubTab = 1 end
    end)
    pcall(function() testOpt:setValue(testWas); PZAPI.ModOptions:save() end)   -- the Options step saved On; write Off back
    pcall(function() if getGameSpeed() <= 0 or speedWas > 0 then setGameSpeed(speedWas > 0 and speedWas or 1) end end)
end

-- ===========================================================================
-- THE WALK
-- ===========================================================================

-- ---- 1. the state free of safe mode, the items, the option On, windows rebuilt
step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("start: safe mode on=" .. tostring(S.on()) .. " | test language option=" .. tostring(testWas)
        .. " | windows char " .. tostring(wasChar) .. " world " .. tostring(wasWorld) .. " | tabs " .. tostring(cw0) .. " / " .. tostring(ww0))
    if S.on() then
        say("ERR safe mode is on: ZeD windows are off, nothing to walk")
        jumpAbort = true
    end
    openPair()
    -- items with long names for the lists, a weapon and a food for the cards, a book to read
    give("Base.Hammer", "Extraordinarily Well Preserved Commemorative Claw Hammer")
    give("Base.Axe", "Wilderness Survival Association Limited Edition Splitting Axe")
    give("Base.Apple", "Absurdly Long Named Orchard Fresh Granny Smith Apple")
    give("Base.Apple")
    give("Base.Steak")
    give("Base.BaseballBat")
    give("Base.Book")
    local b1 = give("Base.WaterBottle")
    if b1 then pcall(function() b1:getFluidContainer():addFluid("Water", 0.5) end) end
    give("Base.WaterBottle")
    give("Base.TinnedBeans", "Family Size Hearty Country Style Baked Beans In Rich Tomato Sauce")
    give("Base.Pistol")
    wear("Base.Hat_BaseballCapBlue")
    wear("Base.Jacket_Padded")
    triggerEvent("OnClothingUpdated", p)
    -- the hands: a hammer and a walkie-talkie (the belt's hand boxes, the Radio tab)
    local walkie = give("Base.WalkieTalkie2")
    local hammer = found("Base.Hammer")
    if hammer then p:setPrimaryHandItem(hammer) end
    if walkie then p:setSecondaryHandItem(walkie) end
end)
step(5, function() testOpt:setValue(2) end)
poll(0, 240, function() return ZeD.trTestOn() end, function() say("ERR the test language did not come on within 240 frames") end)
step(3, function()
    local a, b = ZeD.tr("UI_ZeD_Close"), ZeD.tr("UI_ZeD_Search")
    local on = tostring(a):sub(1, 1) == "["
    say("test language: Close=" .. tostring(a) .. " Search=" .. tostring(b) .. " bracketed=" .. tostring(on))
    if not on then say("ERR the test language is not on: stopping, nothing put back wrong"); jumpAbort = true end
    closePair()
end)
step(25, function() openPair() end)
step(50, function() end)

-- ---- 2. the Character window
visit("c", "loot", "char_loot_list", 30)
sub("char_loot_grid", "Loot as a grid", function() ZeD.InventoryRenderer.setGridKey("player", true) end, 30)
step(2, function() ZeD.InventoryRenderer.setGridKey("player", false) end)
-- item cards: a food, a weapon, a bottle
step(25, function()
    lastMiss = false
    local it = found("Base.Apple", true); if it then selectItem(it) end
end)
step(35, function() shot("card_food", "item card on a food (apple)") end)
step(2, function()
    local it = found("Base.BaseballBat"); if it then selectItem(it) end
end)
step(35, function() shot("card_weapon", "item card on a weapon (baseball bat)") end)
step(2, function()
    local it = found("Base.WaterBottle"); if it then selectItem(it) end
end)
step(35, function() shot("card_bottle", "item card on a water bottle") end)
step(2, function()
    local it = found("Base.Pistol"); if it then selectItem(it) end
end)
step(35, function() shot("card_gun", "item card on a pistol") end)
step(2, function() selectItem(nil) end)
step(20, function() end)

visit("c", "equip", "char_equip_list", 30)
sub("char_equip_doll", "Equip as a doll", function() ZeD.EquipDoll.setView("doll") end, 45)
step(2, function() ZeD.EquipDoll.setView("list") end)

visit("c", "health", "char_health", 30)
visit("c", "thermal", "char_thermal_1", 30)
for i = 2, 7 do
    sub("char_thermal_" .. i, "Thermal view " .. i, function() local w = CW(); if w then w._thermalView = i end end, 15)
end
sub("char_thermal_figure", "Thermal figure opened", function()
    local w = CW()
    if w then thermalFigWas = w._thermalFigureExpanded; w._thermalView = 1; w._thermalFigureExpanded = not w._thermalFigureExpanded end
end, 25)
step(2, function() local w = CW(); if w and thermalFigWas ~= nil then w._thermalFigureExpanded = thermalFigWas end end)
visit("c", "identity", "char_identity", 30)
visit("c", "journal", "char_journal_1", 30)
for i = 2, 4 do
    sub("char_journal_" .. i, "Journal sub-tab " .. i, function() local w = CW(); if w then w._journalSubTab = i end end, 20)
end
step(2, function() local w = CW(); if w then w._journalSubTab = 1 end end)
visit("c", "skills", "char_skills", 30)
visit("c", "radio", "char_radio", 30, 150)
visit("c", "loot", "char_loot_back", 20)

-- ---- 3. context menus (on the Loot list's items)
step(2, function()
    ctxOpt:setValue(1)
    local food = found("Base.Apple", true)
    if food then ISInventoryPaneContextMenu.createMenu(pn, true, { food }, 700, 300) end
end)
step(25, function() shot("ctx_strip_food", "context menu strip on a food") end)
step(2, function() local m = zm(); if m then m:close() end end)
step(10, function()
    local bat = found("Base.BaseballBat")
    if bat then ISInventoryPaneContextMenu.createMenu(pn, true, { bat }, 700, 300) end
end)
step(25, function() shot("ctx_strip_weapon", "context menu strip on a weapon") end)
step(2, function() local m = zm(); if m then m:close() end end)
step(10, function()
    ctxOpt:setValue(2)
    local food = found("Base.Apple", true)
    if food then ISInventoryPaneContextMenu.createMenu(pn, true, { food }, 700, 300) end
end)
step(25, function() shot("ctx_list_food", "context menu as a list on a food") end)
step(2, function()
    -- the Eat submenu, if the list has one
    local m = zm()
    local lv = m and m._levels and m._levels[1]
    if not lv then return end
    for i, r in ipairs(lv.rows) do if r.def and tostring(r.def.name):find("Eat", 1, true) then lv.sel = i end end
    pcall(function() m:onJoypadDirRight() end)
end)
step(20, function() shot("ctx_list_submenu", "context menu list, a submenu") end)
step(2, function() local m = zm(); if m then m:close() end; ctxOpt:setValue(ctxWas) end)
step(10, function() end)

-- ---- 4. the World window
visit("w", "loot", "world_loot", 30)
visit("w", "craft", "world_craft_list", 40)
sub("world_craft_recipe", "Crafting with a recipe open", function() openRecipe("craft") end, 40)
step(2, function() closeRecipe("craft") end)
visit("w", "build", "world_build_list", 40)
sub("world_build_recipe", "Building with a recipe open", function() openRecipe("build") end, 40)
step(2, function() closeRecipe("build") end)
visit("w", "furniture", "world_furniture", 40)
for _, m in ipairs({ "rotate", "scrap", "repair", "pickup" }) do
    sub("world_furniture_" .. m, "Furniture mode " .. m, function() ZeD.FurnitureTab.setMode(pn, m) end, 20)
end
step(2, function() pcall(function() ZeD.FurnitureTab.setMode(pn, "place") end) end)
visit("w", "maps", "world_maps", 70)
for _, style in ipairs({ "survey", "color", "paper" }) do
    sub("world_maps_" .. style, "Maps, style " .. style, function()
        local w = WW()
        if w and w._worldMapPanel then
            mapWas = mapWas or w._worldMapPanel.style
            ZeD.MapsTab.setStyle(w, style)
            pcall(function() w._worldMapPanel.mapAPI:centerOn(p:getX(), p:getY()) end)
        end
    end, 70)
end
step(2, function() local w = WW(); if w and mapWas then ZeD.MapsTab.setStyle(w, mapWas) end end)
visit("w", "forage", "world_forage", 40)
visit("w", "animals", "world_animals", 40)
visit("w", "radio", "world_radio", 40, 60)
visit("w", "vehicle", "world_vehicle", 40, 60)
-- a Fluid object card: a bottle of water, in the drawer of the World window
visit("w", "loot", "world_loot_back", 20)
sub("world_card_fluid", "object card: Fluid (a water bottle)", function()
    local bottle = nil
    for _, it in ipairs(added) do
        if it:getFullType() == "Base.WaterBottle" then
            local ok, amt = pcall(function() return it:getFluidContainer():getAmount() end)
            if ok and amt and amt > 0 then bottle = it; break end
        end
    end
    if not bottle then say("MISSING a bottle with water for the Fluid card"); return end
    local ok = OC.open(p, "fluid", { container = ISFluidContainer:new(bottle:getFluidContainer()), source = true })
    if not ok then say("MISSING the Fluid card did not open") end
end, 45)
step(2, function() pcall(function() WWm.closeObjectCard() end) end)
step(20, function() end)

-- ---- 5. the belt, the watch, the hands
local watch = nil
step(2, function()
    p:getModData().ZeD_WatchPop = nil
    watchOpt:setValue(1)
    watch = wear("Base.WristWatch_Left_DigitalBlack")
    if not watch then say("MISSING the watch could not be worn (the wrist place is taken)") end
end)
step(50, function() shot("belt_watch_tucked", "the belt with the mini watch, hammer and walkie-talkie in hand") end)
step(2, function() if watch then ZeD.Watch.togglePop(true) end end)
step(30, function() if watch then shot("belt_watch_popped", "the popped watch") end end)
step(2, function() if watch then ZeD.Watch.togglePop(false) end; watchOpt:setValue(2) end)
step(40, function() if watch then shot("watch_corner", "the watch in the corner (Corner mode)") end end)
step(2, function()
    watchOpt:setValue(watchWas)
    if watch then pcall(function() p:removeWornItem(watch); watch:getContainer():Remove(watch) end) end
    for i = #worn, 1, -1 do if worn[i] == watch then table.remove(worn, i) end end
    for i = #added, 1, -1 do if added[i] == watch then table.remove(added, i) end end
    p:getModData().ZeD_WatchPop = popWas
end)
step(20, function() end)

-- ---- 6. the action bar: reading a book (Verbose, then Simple)
step(2, function()
    barOpt:setValue(1)
    local book = found("Base.Book")
    if not book then say("MISSING the book"); return end
    local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, pn) end)
    if not ok then pcall(function() ISTimedActionQueue.add(ISReadABook:new(p, book, 150)) end) end
end)
step(70, function() shot("actionbar_reading_verbose", "action bar while reading (Verbose)") end)
step(2, function() barOpt:setValue(2) end)
step(30, function() shot("actionbar_reading_simple", "action bar while reading (Simple)") end)
step(2, function() barOpt:setValue(barWas); pcall(function() ISTimedActionQueue.clear(p) end) end)
step(30, function() end)

-- ---- 7. wheels
step(2, function()
    ISEmoteRadialMenu:new(p):fillMenu()
end)
step(30, function() shot("wheel_emotes", "the emote wheel") end)
step(2, function() local m = getPlayerRadialMenu(pn); if m then m:undisplay() end end)
step(15, function() pcall(function() ISVehicleMenu.showRadialMenu(p) end) end)
step(30, function() shot("wheel_vehicle_outside", "the vehicle wheel outside a vehicle") end)
step(2, function() local m = getPlayerRadialMenu(pn); if m then m:undisplay() end end)
step(15, function() end)

-- ---- 8. prompts
local alarm = { h = 6, m = 30, on = true }
function alarm:getHour() return self.h end
function alarm:getMinute() return self.m end
function alarm:isAlarmSet() return self.on end
function alarm:setHour(v) self.h = v end
function alarm:setMinute(v) self.m = v end
function alarm:setAlarmSet(v) self.on = v end
function alarm:syncAlarmClock() end
local function noop() end
local function showPrompt(make)
    local ok, o = pcall(make)
    if ok and o then cur = o else say("ERR prompt did not build: " .. tostring(o)) end
end
step(2, function()
    showPrompt(function()
        local o = ISModalDialog:new(0, 0, 250, 150, getText("IGUI_ConfirmSleep"), true, nil, noop, 0, p, nil)
        o:initialise(); o:addToUIManager()
        return o
    end)
end)
step(35, function() shot("prompt_question", "prompt: a question (sleep)") end)
step(2, function() closePrompt() end)
step(15, function()
    showPrompt(function()
        local o = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_NameThisBag"), "Duffel Bag", nil, noop, 0)
        o:initialise(); o:addToUIManager()
        return o
    end)
end)
step(35, function() shot("prompt_textbox", "prompt: a text box (rename)") end)
step(2, function()
    if cur and cur.entry then
        cur.noEmpty = true; cur.maxChars = 12
        cur.entry:setText("")
    end
end)
step(30, function() shot("prompt_textbox_empty", "prompt: text box emptied (reason shown)") end)
step(2, function()
    if cur and cur.entry then
        cur.entry:setText("Go Bag")
        pcall(function() OnScreenKeyboard.Show(0, cur.entry, nil) end)
    end
end)
step(35, function() shot("prompt_keyboard", "on-screen keyboard over the text box") end)
step(2, function() pcall(function() if ZeD.Keyboard.instance then ZeD.Keyboard.instance:cancel() end end) end)
step(10, function() closePrompt() end)
step(15, function()
    showPrompt(function()
        local o = ISAlarmClockDialog:new(0, 0, 230, 160, 0, alarm)
        o:initialise(); o:addToUIManager()
        return o
    end)
end)
step(35, function() shot("prompt_alarm", "prompt: the alarm clock") end)
step(2, function() closePrompt() end)
step(15, function()
    showPrompt(function()
        local o = ISBombTimerDialog:new(0, 0, 280, 180, getText("IGUI_TimerSecondsBeforeExplosion"), 30, p, nil, noop, p, nil)
        o:initialise(); o:addToUIManager()
        return o
    end)
end)
step(35, function() shot("prompt_timer", "prompt: the trap timer") end)
step(2, function() closePrompt() end)
step(15, function()
    showPrompt(function()
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local o = ISModalRichText:new(sw / 2 - 400, sh / 2 - 300, 600, 600, getText("IGUI_DesignationZone_Info"), false)
        o:initialise()
        o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
        o.alwaysOnTop = true
        o.chatText:paginate()
        o:setHeightToContents()
        o:ignoreHeightChange()
        o:setY(sh / 2 - (o:getHeight() / 2))
        o:setVisible(true)
        o:addToUIManager()
        return o
    end)
end)
step(40, function() shot("prompt_help", "prompt: a long help note") end)
step(2, function() closePrompt() end)
step(15, function()
    showPrompt(function()
        local o = ISModalRichText:new(0, 0, 380, 120, getText("IGUI_WorldMap_ConfirmForget"), true, nil, noop, 0)
        o:initialise(); o:addToUIManager()
        return o
    end)
end)
step(35, function() shot("prompt_rich_question", "prompt: a rich question (forget map)") end)
step(2, function() closePrompt() end)
step(20, function() end)

-- ---- 9. safe mode: the game's note after a trip (and the state free of it)
step(2, function()
    say("safe mode free before the trip: on=" .. tostring(S.on()))
    S.trip("test language walk", "QA: no error, a look at the note")
    weTripped = true
end)
step(40, function()
    local n = findNote()
    say("tripped: note " .. tostring(n ~= nil) .. " | pair open char " .. tostring(CWm.isOpen()) .. " world " .. tostring(WWm.isOpen()))
    shot("safe_note", "safe mode: the game's own note after a trip")
end)
step(2, function() closeNote() end)
step(10, function() S.reset(); weTripped = false end)
step(40, function()
    say("safe mode free after the trip: on=" .. tostring(S.on()))
    openPair()
    local vi, vl = getPlayerInventory(pn), getPlayerLoot(pn)
    if vi then vi:setVisible(false) end
    if vl then vl:setVisible(false) end
    pcall(function()
        local f = getFileWriter("ZeD_safe_trip.txt", true, false)
        f:write(""); f:close()
    end)
end)
step(60, function() end)

-- ---- 10. the pause menu: the window, Options (every group), Mods
local pauseW0 = nil
step(2, function()
    if not ToggleEscapeMenu then say("MISSING ToggleEscapeMenu: the pause menu is not reachable"); return end
    pauseW0 = MM.pause and MM.pause.page
    ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
end)
step(45, function()
    local ms = MainScreen.instance
    say("pause menu up: " .. tostring(ms and ms:isVisible()) .. " | ZeD pause window " .. tostring(MM.pause ~= nil))
    if ms and ms:isVisible() then shot("pause_menu", "the pause menu") end
end)
step(2, function()
    local ms = MainScreen.instance
    if ms and ms:isVisible() then MM.openOptions() end
end)
step(40, function()
    local w = MM.pauseOpts
    say("options up: " .. tostring(w and w:isVisible()) .. " | groups " .. tostring(w and #w:pages()))
end)
for i = 1, 12 do
    step(2, function()
        local w = MM.pauseOpts
        if not (w and w:isVisible()) then return end
        local pages = w:pages()
        local pg = pages[i]
        if not pg then return end
        w.pageIdx = i; w.scroll = 0; w.focusId = nil
        lastMiss = false
    end)
    step(25, function()
        local w = MM.pauseOpts
        if not (w and w:isVisible()) then return end
        local pg = w:pages()[i]
        if pg then shot("options_" .. i .. "_" .. tostring(pg.raw), "Options, group " .. tostring(pg.raw)) end
    end)
end
step(2, function()
    local w = MM.pauseOpts
    if w and w:isVisible() then
        if w:anyChanged() then say("ERR the options window shows changes: leaving them for the player"); end
        w:back()
    end
end)
step(25, function()
    local ms = MainScreen.instance
    if not (ms and ms:isVisible()) then return end
    if MM.pause then MM.pause.page = "mods"; MM.pause.focusId = nil end
end)
step(25, function()
    local ms = MainScreen.instance
    if ms and ms:isVisible() then shot("pause_mods", "the pause menu, Mods page") end
    if MM.pause then MM.pause.page = pauseW0; MM.pause.focusId = nil end
end)
step(5, function()
    local ms = MainScreen.instance
    if ms and ms:isVisible() and ToggleEscapeMenu then
        MM.pauseView = "pause"
        ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
    end
end)
step(30, function()
    local ms = MainScreen.instance
    say("resumed: pause menu visible=" .. tostring(ms and ms:isVisible()) .. " speed " .. tostring(getGameSpeed()))
    if getGameSpeed() <= 0 then setGameSpeed(1) end
end)

-- ---- 11. put everything back
mark("restore")
step(5, function() restoreAll() end)
poll(0, 240, function() return ZeD.trTestOn() == (testWas == 2) end, function() say("ERR the test language did not go off within 240 frames") end)
step(5, function()
   say("test language back: Close=" .. tostring(ZeD.tr("UI_ZeD_Close")))
    closePair()
end)
step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(speedWas > 0 and speedWas or 1) end
    if wasChar and wasWorld then openPair()
    else
        if wasChar then CWm.toggle(0) end
        if wasWorld then WWm.open(0) end
    end
end)
step(50, function()
    if cw0 and CW() then charTab(cw0) end
    if ww0 and WW() then worldTab(ww0) end
    say("safe mode free at the end: on=" .. tostring(S.on()) .. " | test language option=" .. tostring(testOpt:getValue())
        .. " | windows char " .. tostring(CWm.isOpen()) .. " world " .. tostring(WWm.isOpen()) .. " | " .. tostring(nShot) .. " screenshots")
    say("DONE")
end)

-- ---------------------------------------------------------------------------
-- Driving it (OnRenderTick: it runs while the pause menu is up)
-- ---------------------------------------------------------------------------
local tick, qi, lastDone = 0, 1, 0
local MAX_TICKS = 14000   -- a stuck run stops here and puts things back (about 4 minutes at 60 fps)
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
