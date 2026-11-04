-- ZeDUI/tools/qa/gallery_beta3_breaks.lua  (Nov 4 2026, QA; the director: full-screen breaks between the book's
-- spreads, ZeDUI/workshop/gallery/BETA3_ORDER.md). Run after gallery_t14_look.lua (no debug text, the default look).
-- Plain full-screen pictures of the game with Beta 3's screens in them:
--   br_onscreen   both windows open, the character beside a car (the hint strip: E Enter Vehicle), three pins on the
--                 title bar, a speech bubble with an overhead note above it
--   br_equip      the Character window on its Equip tab
--   br_craft      the World window on its Crafting tab
--   br_guide      the survival guide's book on chapter 16 (ZeD)
--   br_reader     a newspaper in ZeD's reader
-- Pins, items and the tabs put back. grep "ZEDQA gb3". Pictures gal_b3_<name>.png.
local function say(s) print("ZEDQA gb3 " .. tostring(s)) end
local core = getCore()
local function shot(n) pcall(function() core:TakeFullScreenshot("gal_b3_" .. n .. ".png") end); say("shot " .. n) end
local p = getPlayer()
local md = p:getModData()
local keep = { pins = md.ZeD_Pins }
local items = {}
local CW = ZeD_CharacterWindow.getWindow()
local WW = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
keep.ctab, keep.wtab = CW and CW._activeTab, WW and WW._activeTab
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function moveTo(x, y) p:setX(x + 0.5); p:setY(y + 0.5); p:setLastX(x + 0.5); p:setLastY(y + 0.5) end
local DIRS = { IsoDirections.N, IsoDirections.NE, IsoDirections.E, IsoDirections.SE, IsoDirections.S, IsoDirections.SW, IsoDirections.W, IsoDirections.NW }

-- the nearest car
local car
step(20, function()
    local px, py = p:getX(), p:getY()
    local it = getCell():getVehicles():iterator()
    local best
    while it:hasNext() do
        local v = it:next()
        local d = (v:getX() - px) ^ 2 + (v:getY() - py) ^ 2
        if not best or d < best then best, car = d, v end
    end
    say("car " .. tostring(car and car:getScriptName()) .. " at " .. tostring(car and math.floor(car:getX())) .. "," .. tostring(car and math.floor(car:getY())))
    -- pins: a book, a water bottle, a lighter, from their right-click menus' own action
    local inv = p:getInventory()
    for _, t in ipairs({ "Base.BookCarpentry1", "Base.WaterBottle", "Base.Lighter" }) do items[#items + 1] = inv:AddItem(t) end
    pcall(function() items[1]:setAlreadyReadPages(73) end)
    pcall(function() local fc = items[2]:getFluidContainer(); fc:Empty(); fc:addFluid(Fluid.Water, fc:getCapacity() * 0.6) end)
    md.ZeD_Pins = {}
    for _, it2 in ipairs(items) do ZeD.Pins.toggle(p, ZeD.Pins.kindOf(it2), it2:getID(), it2:getDisplayName()) end
end)
-- stand beside the car, facing a door the game offers
local spots, si = {}, 0
step(5, function()
    if not car then return end
    local cx, cy = math.floor(car:getX()), math.floor(car:getY())
    for _, o in ipairs({ { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 1 }, { -2, -1 }, { 1, 2 }, { -1, -2 } }) do spots[#spots + 1] = { cx + o[1], cy + o[2] } end
end)
for k = 1, 8 do
    step(4, function() if keep.faced or not spots[k] then return end; moveTo(spots[k][1], spots[k][2]) end)
    step(12, function()
        if keep.faced or not spots[k] then return end
        local bp = ISButtonPrompt:new(0)
        for _, d in ipairs(DIRS) do
            p:setDir(d); bp:clearButtonBindings(); pcall(function() bp:getBestInteractButtonAction(d) end)
            if bp.aPrompt and bp.aPrompt ~= "" then keep.faced = bp.aPrompt; return end
        end
    end)
end
step(30, function()
    say("facing: " .. tostring(keep.faced))
    keep.halo = ZeD.Settings.haloBubbleOption:getValue(); ZeD.Settings.haloBubbleOption:setValue(2)
    p:Say("Keys are still in it.")
    HaloTextHelper.addGoodText(p, getText("IGUI_HaloNote_LearnedRecipe", "Make Plank"), "[br/]")
end)
step(25, function() shot("br_onscreen") end)
-- the Equip tab
step(10, function() if CW then CW._activeTab = "equip"; CW._drawerMode = "tab"; CW._drawerOpen = true end end)
step(60, function() shot("br_equip") end)
-- the Crafting tab
step(10, function() if WW then WW._activeTab = "craft"; WW._drawerMode = "tab"; WW._drawerOpen = true end end)
step(60, function() shot("br_craft") end)
-- the guide's book on chapter 16
step(10, function()
    ZeD.Settings.guideStyleOption:setValue(1)
    ZeD.GuideBook.open(0)
    local b = ZeD.GuideBook.books[0]
    local s16 = b.sections[16]
    if s16 then b.spread = math.floor((b.sectionPage[s16.id] + 1) / 2) end
end)
step(90, function() shot("br_guide") end)
-- a newspaper in the reader
step(10, function()
    ZeD.GuideBook.close(0)
    local m = ZeD.Print.ofId("KnoxKnews_July1")
    local it = instanceItem("Base.Newspaper")
    it:getModData().printMedia = { id = m.id, title = m.title, info = m.info, text = m.text }
    ZeD.Reader.openPrint(p, it)
end)
step(60, function() shot("br_reader") end)
step(20, function()
    pcall(function() ZeD.Reader.get(0):setVisible(false) end)
    md.ZeD_Pins = keep.pins
    if keep.halo then ZeD.Settings.haloBubbleOption:setValue(keep.halo) end
    local inv = p:getInventory()
    for _, it in ipairs(items) do pcall(function() inv:Remove(it) end) end
    if CW then CW._activeTab = keep.ctab or CW._activeTab end
    if WW then WW._activeTab = keep.wtab or WW._activeTab end
    if ZEDQA_HOME then pcall(ZEDQA_HOME) end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
