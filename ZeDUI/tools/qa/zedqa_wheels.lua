-- ZeDUI/tools/qa/zedqa_wheels.lua  (S125)
-- The ZeD wheels (HOOK_MAP row 29): opens vanilla's wheels through vanilla's
-- own functions on the QA save, captures each, picks through the wheel's own
-- handlers and checks the routed slices. Copy to Zomboid/Lua/zedqa.lua and
-- bump zedqa.go; grep console.txt for "ZEDQA wh". The character steps into
-- the nearby pickup and out again; the pistol and the torch go back.

local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA wh " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_wh_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local menu = getPlayerRadialMenu(pn)
local function info(tag, m)
    m = m or menu
    local parts = {}
    for i, s in ipairs(m.slices) do parts[#parts + 1] = i .. ":" .. tostring(s.text and s.text:gsub("\n", "/") or "(place)") .. (ZeD.Wheel.isOff(s) and "[off]" or "") end
    say(string.format("%s zed=%s java=%s n=%d x=%d y=%d w=%d vis=%s point=%s title=%s | %s", tag, tostring(m._zed), tostring(m.javaObject and m.javaObject:getClass():getSimpleName()),
        #m.slices, m.x, m.y, m.width, tostring(m:isReallyVisible()), tostring(m._zedPoint), tostring(m._zedTitle), table.concat(parts, "  ")))
end
-- local coordinates of a point in slice i's direction (for the wheel's own onMouseDown)
local function towards(m, i)
    local n = #m.slices
    local cell, icon, r, cx, cy = ZeD.Wheel.geom(m)
    local a = math.rad(-90 + (i - 1) * 360 / math.max(n, 2))
    return cx + r * math.cos(a), cy + r * math.sin(a)
end
-- the pickup the character steps into: one within 20 tiles, else one spawned beside the character (removed at the
-- end). The character is left wherever the last run ended, so the QA save's own pickup is not always near.
local car, spawnedCar
do
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do local v = it:next(); if v:getScript():getFullName() == "Base.PickUpTruck" and v:DistTo(p) < 20 then car = v end end
end
if not car then
    local sq = getCell():getGridSquare(math.floor(p:getX()) - 4, math.floor(p:getY()), math.floor(p:getZ()))
    local ok, v = pcall(function() return sq and addVehicleDebug("Base.PickUpTruck", IsoDirections.N, nil, sq) end)
    if ok and v then car, spawnedCar = v, v end
    say("no pickup within 20 tiles; spawned one beside the character: " .. tostring(spawnedCar ~= nil))
    if not car then say("ERR no pickup within 20 tiles and the spawn failed: the inside-the-vehicle wheel scenes run without one") end
end
local pairWasOpen = ZeD_CharacterWindow.isOpen()
local gaveGear = {}   -- the clip and bullets given for the gun wheel, taken back at the end
local inv = p:getInventory()
local function find(full) local items = inv:getItems(); for i = 0, items:size() - 1 do local x = items:get(i); if x:getFullType() == full then return x end end end
local pistol, torch, prim, sec = find("Base.Pistol"), find("Base.HandTorch"), p:getPrimaryHandItem(), p:getSecondaryHandItem()

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
end)
-- 1. outside a vehicle (V): the trailer / pickup beside the character
at(10, function() ISVehicleMenu.showRadialMenu(p); info("outside") end)
at(35, function() shot("01_outside"); menu:undisplay() end)
-- 2. inside the pickup
at(45, function() if car then car:enter(0, p); triggerEvent("OnEnterVehicle", p) end end)
at(90, function() ISVehicleMenu.showRadialMenu(p); info("inside") end)
at(115, function() shot("02_inside") end)
-- point at slice 3 with the wheel's own picking (mouse): the pointer's direction
at(120, function() local x, y = towards(menu, 3); say("pick test slice3 from mouse -> " .. ZeD.Wheel.sliceFromMouse(menu, x, y)); ZeD.Wheel.qaPoint = 3 end)
at(125, function() shot("03_inside_point") end)
at(135, function() ZeD.Wheel.qaPoint = 2 end)
at(140, function() shot("04_inside_off"); ZeD.Wheel.qaPoint = nil; menu:undisplay() end)
at(150, function() if car then car:exit(p); triggerEvent("OnExitVehicle", p) end end)
-- 3. emotes, then choose Signal through the wheel's own press (opens the category)
at(190, function() ISEmoteRadialMenu:new(p):fillMenu(); info("emotes") end)
at(215, function() shot("05_emotes") end)
at(225, function()
    local sig
    for i, s in ipairs(menu.slices) do if s.text == getText("IGUI_Emote_Signal") then sig = i end end
    sig = sig or 1
    local x, y = towards(menu, sig)
    say("press towards " .. sig .. " (" .. tostring(menu.slices[sig] and menu.slices[sig].text) .. ")")
    menu:onMouseDown(x, y)
end)
at(240, function() info("signal") end)
at(260, function() shot("06_signal") end)
at(265, function() ZeD.Wheel.qaPoint = 2 end)
at(270, function() shot("07_signal_point"); ZeD.Wheel.qaPoint = nil; menu:undisplay() end)
-- 4. firearm (pistol in hand)
at(285, function()
    if pistol then p:setPrimaryHandItem(pistol) end
    if not find("Base.9mmClip") then gaveGear[#gaveGear + 1] = inv:AddItem("Base.9mmClip") end
    if not find("Base.Bullets9mm") then for _ = 1, 20 do gaveGear[#gaveGear + 1] = inv:AddItem("Base.Bullets9mm") end end
end)
at(300, function() local f = ISFirearmRadialMenu:new(p); f:fillMenu(); f:display(); info("gun") end)
at(320, function() ZeD.Wheel.qaPoint = 1 end)
at(325, function() shot("08_gun") end)
at(335, function() ZeD.Wheel.qaPoint = nil; menu:undisplay() end)
-- 5. light (torch in the off hand)
at(345, function() if torch then p:setSecondaryHandItem(torch) end end)
at(360, function() local l = ISLightSourceRadialMenu:new(p); l:fillMenu(); l:display(); info("light") end)
at(380, function() ZeD.Wheel.qaPoint = #menu.slices end)
at(385, function() shot("09_light") end)
at(395, function() ZeD.Wheel.qaPoint = nil; menu:undisplay(); p:setSecondaryHandItem(sec); p:setPrimaryHandItem(prim) end)
-- 6. the controller's Back wheel
local bw = getPlayerData(pn) and getPlayerData(pn).backButtonWheel
at(405, function()
    if bw then bw:addCommands(); bw:setVisible(true); bw:addToUIManager(); info("back", bw) end
end)
at(425, function() ZeD.Wheel.qaPoint = 2 end)
at(430, function() if bw then shot("10_back") end end)
at(440, function() ZeD.Wheel.qaPoint = nil; if bw then bw:removeFromUIManager(); bw:setVisible(false) end end)
-- 7. D-pad Right (maps / zones / guide)
at(450, function() ISDPadWheels.onDisplayRight({ player = pn, id = -1 }); info("dright") end)
at(470, function() ZeD.Wheel.qaPoint = 2 end)
at(475, function() shot("11_dright"); ZeD.Wheel.qaPoint = nil; menu:undisplay() end)
-- 8. routes: the zone panel and the search window open the World window tabs; Player Info the pair
at(490, function()
    ISDesignationZonePanel.toggleZoneUI(pn)
    say("zone route: world=" .. tostring(ZeD_WorldWindow.isOpen()) .. " vanillaZone=" .. tostring(ISDesignationZonePanel.instance and ISDesignationZonePanel.instance:isReallyVisible()))
end)
at(530, function() say("zone tab showing=" .. tostring(ZeD_WorldWindow.isTabShowing and ZeD_WorldWindow.isTabShowing("animals"))); shot("12_zone_route") end)
at(545, function() ISSearchWindow.toggleWindow(p) end)
at(585, function() say("search route: forage showing=" .. tostring(ZeD_WorldWindow.isTabShowing and ZeD_WorldWindow.isTabShowing("forage")) .. " vanillaSearch=" .. tostring(ISSearchWindow.players[p] and ISSearchWindow.players[p]:isReallyVisible())); shot("13_search_route") end)
at(600, function()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
at(630, function()
    if bw then bw:onCommand("PlayerInfo") end
    say("player info route: char=" .. tostring(ZeD_CharacterWindow.isOpen()) .. " vanillaInfo=" .. tostring(getPlayerInfoPanel(pn) and getPlayerInfoPanel(pn):isReallyVisible()))
end)
at(670, function() shot("14_playerinfo_route") end)
at(675, function()
    -- the pair back as it was found, the spawned pickup (if any) gone
    if not pairWasOpen and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    for _, it in ipairs(gaveGear) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    if spawnedCar then pcall(function() spawnedCar:permanentlyRemove() end); spawnedCar = nil end
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 700 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start car=" .. tostring(car) .. " pistol=" .. tostring(pistol) .. " torch=" .. tostring(torch))
