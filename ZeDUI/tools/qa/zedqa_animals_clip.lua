-- ZeDUI/tools/qa/zedqa_animals_clip.lua  (Nov 6 2026, QA; punch list 96, the Animals tab's clip): after zedqa_animals.lua built the pen. Does the Animals tab leave
-- a clip set, as the Admin tab did? The drawer's clip count before and after the tab draws, the World window's numbers, and a picture of each page: Ranch, Ranch at
-- its foot, a zone, an animal, Butcher, an item card over Ranch and closed again, then Loot as the control. Read the tab rail and the footer. Pictures zqa_acl_*.png. grep "ZEDQA acl".
local function say(s) print("ZEDQA acl " .. tostring(s)) end
local AT, AP = ZeD.AnimalsTab, ZeD.AnimalsAlertPoller
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function W() return WWm.getWindow() end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local render, last = AT.render, nil
AT.render = function(panel, ...)
    local a = panel._zedStencilN or 0
    local r = render(panel, ...)
    last = (panel._zedStencilN or 0) - a
    return r
end
local function nums(tag)
    local w = W()
    local s = w and w._actionTabStrip
    if not w then say(tag .. " no window"); return end
    say(tag .. ": tab=" .. tostring(w._activeTab) .. " mode=" .. tostring(w._drawerMode) .. " view=" .. tostring(AT.getState(w).view) .. " clips left by the tab=" .. tostring(last)
        .. " win " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight()) .. " footer=" .. tostring(w.footerHeight and w:footerHeight())
        .. " strip vis=" .. tostring(s and s:isVisible()) .. " zones=" .. tostring(s and s._hitZones and #s._hitZones))
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_acl_" .. n .. ".png") end) end
add(300, function()
    AP.refreshCache()
    say("animals " .. #AP.getAllAnimals() .. ", zones " .. #AP.getZoneList() .. ", alerts " .. #AP.getAlerts())
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(2000, function() local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true; AT.switchSubmode(w, "ranch") end)
add(1800, function() nums("ranch"); shot("01_ranch"); local sb = W()._animalsScroll; if sb then sb:setScrollPos(1) end end)
add(1200, function()
    nums("ranch foot"); shot("02_ranch_foot")
    local sb = W()._animalsScroll; if sb then sb:setScrollPos(0) end
    local name; pcall(function() name = AP.getZoneList()[1]:getName() end)
    say("zone " .. tostring(name)); AT.navigate(W(), "zone", name)
end)
add(1500, function() nums("zone"); shot("03_zone"); local a = AP.getAllAnimals()[1]; if a then AT.showAnimal(W(), a) end end)
add(1500, function() nums("animal"); shot("04_animal"); AT.navigateBack(W()) end)
add(800, function() AT.navigateBack(W()) end)
add(1000, function() AT.switchSubmode(W(), "butcher") end)
add(1500, function() nums("butcher"); shot("05_butcher"); AT.switchSubmode(W(), "ranch") end)
add(1500, function()
    local items = getPlayer():getInventory():getItems()
    W()._drawerItem = items:size() > 0 and items:get(0) or nil
    say("item card over Ranch: " .. tostring(W()._drawerItem and W()._drawerItem:getDisplayName()))
end)
add(1500, function() nums("item card"); shot("06_item_over_ranch"); W()._drawerItem = nil end)
add(1500, function() nums("item closed"); shot("07_item_closed"); WWm.openTab(0, "loot") end)
add(1500, function() nums("loot"); shot("08_loot_control"); AT.render = render; CWm.toggleBothPaired(0); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i >= #plan then AT.render = render; say("DONE") end end
end
Events.OnTick.Add(drive)
