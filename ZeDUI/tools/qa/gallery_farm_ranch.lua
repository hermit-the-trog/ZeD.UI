-- ZeDUI/tools/qa/gallery_farm_ranch.lua  (Nov 5 2026, QA; the director: "what a crop looks like, what a hutch looks like with eggs
-- in it, what a livestock zone looks like with animals in it"): the pictures for the Farm and Ranch spreads, after
-- zedqa_animals.lua built the hen house, the trough and the hook. Adds a row of crops at four stages, a pasture zone with a small
-- herd, water in the trough, then: the crop card at two stages, the hutch card with its eggs, the trough card, the Ranch page, the
-- pasture's zone card with its roster, an animal's details, Butcher, and a plain picture of the yard. Run through
-- zedqa_mods_run.ps1 so the save comes back as it was. Pictures gfr_<n>.png at 4K. grep "ZEDQA gfr".
local function say(s) print("ZEDQA gfr " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local OC = ZeD.ObjectCards
local AT, AP = ZeD.AnimalsTab, ZeD.AnimalsAlertPoller
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function W() return WWm.getWindow() end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("gfr_" .. n .. ".png") end); say("shot " .. n) end
local px, py = math.floor(p:getX()), math.floor(p:getY())
local PLOTS = {}
local function findIso(kind, r)
    for x = px - r, px + r do for y = py - r, py + r do
        local sq = getCell():getGridSquare(x, y, 0)
        if sq then
            local objs = sq:getObjects()
            for k = 0, objs:size() - 1 do if instanceof(objs:get(k), kind) then return objs:get(k) end end
        end
    end end
end
local function breedOf(kind)
    local def = AnimalDefinitions.getDef(kind)
    return def and def:getBreeds():get(0)
end
add(500, function()
    local ui = UIManager.getUI()
    for k = 0, ui:size() - 1 do local e = ui:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    pcall(function() getGameTime():setTimeOfDay(10) end)
    -- clear skies, as the cinema scenes do
    pcall(function()
        local cm = getClimateManager()
        for k = 0, cm:getFloatMax() - 1 do
            local v = cm:getClimateFloat(k)
            local l = string.lower(tostring(v:getName()))
            if string.find(l, "fog", 1, true) or string.find(l, "precip", 1, true) or string.find(l, "cloud", 1, true) then
                v:setEnableAdmin(true); v:setAdminValue(0)
            end
        end
    end)
    -- the yard cleared of cars (the save comes back after the run)
    local list, it = {}, getCell():getVehicles():iterator()
    while it:hasNext() do list[#list + 1] = it:next() end
    local gone = 0
    for _, v in ipairs(list) do if math.abs(v:getX() - px) < 40 and math.abs(v:getY() - py) < 40 and pcall(function() v:permanentlyRemove() end) then gone = gone + 1 end end
    say(gone .. " cars out of the yard")
    -- crops at their stages: young, growing, full, on the grass by the character
    local names = {}
    for name, pr in pairs(farming_vegetableconf.props) do if type(pr) == "table" and pr.fullGrown and pr.fullGrown >= 4 then names[#names + 1] = name end end
    table.sort(names)
    say("crops: " .. table.concat(names, ", "))
    local want = { "Cabbages", "Carrots", "Tomato", "Broccoli" }
    local use = {}
    for _, n in ipairs(want) do if farming_vegetableconf.props[n] then use[#use + 1] = n end end
    for _, n in ipairs(names) do if #use < 4 then use[#use + 1] = n end end
    for col, crop in ipairs(use) do
        for row = 0, 2 do
            local sq = getCell():getGridSquare(px + 3 + col * 2, py + row * 2 - 1, 0)
            local ok, e = pcall(function()
                SFarmingSystem.instance:plow(sq)
                local lo = SFarmingSystem.instance:getLuaObjectAt(sq:getX(), sq:getY(), 0)
                lo:seed(crop, 10)
                local pr = farming_vegetableconf.props[crop]
                local full = pr.harvestLevel or pr.fullGrown
                local target = (row == 0) and full or ((row == 1) and math.max(3, full - 2) or 2)
                local guard = 0
                while lo.nbOfGrow < target and guard < 12 do guard = guard + 1; SFarmingSystem.instance:growPlant(lo, nil, true) end
                say(string.format("%s row %d: asked %d, grew to %s, state %s", crop, row, target, tostring(lo.nbOfGrow), tostring(lo.state)))
                lo.nbOfGrow = target
                lo.waterLvl, lo.health = 80, 100
                lo.mildewLvl, lo.aphidLvl, lo.fliesLvl, lo.slugsLvl = 0, 0, 0, 0
                lo.fertilizer = 0
                if row == 0 then lo.hasVegetable = true end
                local name = farming_vegetableconf.getSpriteName(lo)
                say("  sprite " .. tostring(name))
                lo:setSpriteName(name)
                local iso = lo:getIsoObject()
                if iso and name then iso:setSpriteFromName(name) end
                pcall(function() lo:setObjectName(farming_vegetableconf.getObjectName(lo)) end)
                lo:saveData()
                PLOTS[#PLOTS + 1] = { sq = sq, crop = crop, row = row, obj = lo:getIsoObject() }
            end)
            if not ok then say("ERR plot: " .. tostring(e)) end
        end
    end
    say(#PLOTS .. " plots")
    -- a small herd on the grass inside the pasture
    local cow, ewe = breedOf("cow"), breedOf("ewe")
    for k = 1, 3 do pcall(function() addAnimal(getCell(), px + 7 + k * 2, py - 11 + k, 0, "cow", cow) end) end
    pcall(function() addAnimal(getCell(), px + 11, py - 6, 0, "cowcalf", cow) end)
    for k = 1, 4 do pcall(function() addAnimal(getCell(), px + 13 + k, py - 8 + k, 0, "ewe", ewe) end) end
    local t = findIso("IsoFeedingTrough", 12)
    if t then pcall(function() t:setWater(t:getMaxWater()) end) end
    pcall(function() p:setX(px + 6.5); p:setY(py - 3.5); p:setLastX(px + 6.5); p:setLastY(py - 3.5); p:setDir(IsoDirections.SE) end)
end)
add(1500, function() pcall(function() getCore():doZoomScroll(0, -1) end) end)
add(5000, function()
    AP.refreshCache()
    say("animals " .. #AP.getAllAnimals() .. ", zones " .. #AP.getZoneList())
    shot("yard")
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(2000, function()
    local one = PLOTS[3] and PLOTS[3].obj
    say("crop card " .. tostring(OC.open(p, "plant", one)) .. " on row " .. tostring(PLOTS[3] and PLOTS[3].row))
end)
add(2000, function() shot("crop_young") end)
add(300, function()
    local one = PLOTS[7] and PLOTS[7].obj
    say("crop card 2 " .. tostring(OC.open(p, "plant", one)) .. " on row " .. tostring(PLOTS[7] and PLOTS[7].row))
end)
add(2000, function() shot("crop_grown") end)
add(300, function()
    local h = findIso("IsoHutch", 12)
    say("hutch " .. tostring(h ~= nil))
    if h then p:setX(h:getX() + 1); p:setY(h:getY() + 3); p:setLastX(p:getX()); p:setLastY(p:getY()) end
end)
add(2500, function() say("hutch card " .. tostring(OC.open(p, "hutch", findIso("IsoHutch", 12)))) end)
add(2000, function()
    shot("hutch_eggs")
    local h = findIso("IsoHutch", 12)
    h = h and (h:getHutch() or h)
    HUTCH_GFR = h
    say("door " .. tostring(pcall(ISHutchMenu.onToggleDoor, h, p)))
end)
add(4500, function() say("hatch " .. tostring(pcall(ISHutchMenu.onToggleEggHatchDoor, HUTCH_GFR, p))) end)
add(4500, function() say("door open " .. tostring(HUTCH_GFR:isOpen()) .. ", hatch open " .. tostring(HUTCH_GFR:isEggHatchDoorOpen())); shot("hutch_open") end)
add(300, function()
    local t = findIso("IsoFeedingTrough", 12)
    if t then p:setX(t:getX() + 1); p:setY(t:getY() + 1); p:setLastX(p:getX()); p:setLastY(p:getY()) end
end)
add(2500, function() say("trough card " .. tostring(OC.open(p, "trough", findIso("IsoFeedingTrough", 12)))) end)
add(2000, function() shot("trough") end)
add(300, function()
    local w = W()
    pcall(function() WWm.closeObjectCard(pn) end)
    pcall(function() w._objectCard:setVisible(false) end)
    w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true
    AT.switchSubmode(w, "ranch")
end)
add(2500, function() shot("ranch") end)
add(300, function()
    local w = W()
    w._animalsScroll = w._animalsScroll
    if w._animalsScroll then w._animalsScroll:setScrollPos(1) end
end)
add(1500, function()
    shot("ranch_foot")
    AT.navigate(W(), "zone", "Home Pasture")
    local cw = CWm.getWindow(); if cw then cw:setVisible(false) end
    local w = W(); w:setX(ZeD.T.px(40)); w:setY(ZeD.T.px(40))
end)
add(2000, function()
    shot("zone")
    local zs = AP.getAnimalsInZone("Home Pasture")
    say("the pasture's animals: " .. #zs)
    if zs[1] then AT.showAnimal(W(), zs[1]) end
end)
add(2000, function() shot("animal"); AT.navigateBack(W()) end)
add(500, function() AT.navigateBack(W()) end)
add(500, function() AT.switchSubmode(W(), "butcher") end)
add(2000, function() shot("butcher"); AT.switchSubmode(W(), "ranch"); CWm.toggleBothPaired(0) end)
add(500, function() say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
