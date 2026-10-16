-- ZeDUI/tools/qa/zedqa_overnight_game.lua  (Oct 15 2026)
-- In game on the ZeD-QA save (copy to Zomboid/Lua/zedqa.lua, bump zedqa.go;
-- grep "ZEDQA ov"):
--   * the D-pad Right wheel's quick use (ZeD_QuickWheel): gives the character
--     an apple, a can of beans, water, a soda, cigarettes and a lighter, pills
--     and a book; opens the wheel, each group, runs one pick (the queued action
--     is checked, then cleared); everything given is taken back at the end;
--   * the Craft and Build tabs' SHOW filter (Ready / Known / All) on vanilla's
--     crafting logic: counts in each mode, how long a scan takes;
--   * the map on a controller: zoom steps on the cursor, the D-pad's growing step.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA ov " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ov_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local Q, CC = ZeD.QuickWheel, ZeD.CraftingCore
local given = {}
local function give(ft, fill)
    local ok, it = pcall(function() return p:getInventory():AddItem(ft) end)
    if ok and it then
        given[#given + 1] = it
        if fill then pcall(function() it:getFluidContainer():addFluid(fill, 0.5) end) end
        say("gave " .. ft)
    else say("could not give " .. ft) end
end
local function slices(tag)
    local menu = getPlayerRadialMenu(pn)
    local t = {}
    for _, s in ipairs(menu.slices or {}) do t[#t + 1] = tostring(s.text) end
    say(tag .. ": [" .. table.concat(t, " | ") .. "]")
end
local function closeWheel()
    local menu = getPlayerRadialMenu(pn)
    pcall(function() menu:undisplay() end)
    pcall(function() menu:removeFromUIManager() end)
end
local function counts(win, key, data, tag)
    local st = win[key]
    local n = { craftable = 0, missing = 0, locked = 0, station = 0, unlocked = 0, other = 0 }
    local fromLogic = 0
    for _, rd in ipairs(data and data.recipes or {}) do
        n[rd.status] = (n[rd.status] or 0) + 1
        if rd.fromLogic then fromLogic = fromLogic + 1 end
    end
    say(string.format("%s show=%s listed=%d | recipes=%d fromLogic=%d craftable=%d missing=%d locked=%d station=%d unlocked=%d",
        tag, tostring(CC.showMode(st, nil)), #(st.filteredCache or {}), #(data and data.recipes or {}), fromLogic,
        n.craftable, n.missing, n.locked, n.station, n.unlocked))
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end
    give("Base.Apple"); give("Base.TinnedBeans"); give("Base.WaterBottle", Fluid.Water); give("Base.Pop")
    give("Base.CigaretteSingle"); give("Base.Lighter"); give("Base.PillsBeta"); give("Base.Book")
    p:getStats():set(CharacterStat.THIRST, 0.4)
    p:getStats():set(CharacterStat.HUNGER, 0.3)
end)
-- 1. the quick use wheel
at(20, function() ISDPadWheels.onDisplayRight({ player = pn }); slices("D-pad Right") end)
at(35, function() shot("01_dpad_right") end)
at(40, function() Q.openGroup(p, "eat"); slices("Eat") end)
at(55, function() shot("02_eat") end)
at(60, function() Q.openGroup(p, "drink"); slices("Drink") end)
at(75, function() shot("03_drink") end)
at(80, function() Q.openGroup(p, "smoke"); slices("Smoke") end)
at(90, function() Q.openGroup(p, "pills"); slices("Take pills") end)
at(100, function() Q.openGroup(p, "read"); slices("Read") end)
at(110, function()
    -- run the Eat group's first pick, as a pick on the wheel would
    Q.openGroup(p, "eat")
    local menu = getPlayerRadialMenu(pn)
    local s = menu.slices and menu.slices[1]
    if s and s.command and s.command[1] then s.command[1](s.command[2], s.command[3], s.command[4]) end
    closeWheel()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local names = {}
    for _, a in ipairs(q and q.queue or {}) do names[#names + 1] = tostring(a.Type) end
    say("after Eat pick, queue: [" .. table.concat(names, ", ") .. "]")
    ISTimedActionQueue.clear(p)
end)
-- 2. the Craft and Build tabs' SHOW filter
at(130, function() ZeD_WorldWindow.openTab(pn, "craft") end)
at(220, function()
    local w = ZeD_WorldWindow.getWindow()
    local t0 = getTimestampMs()
    w._craftLogicAt = 0
    CC.logicScan(w._craftCache, w, "craft", function() return HandcraftLogic.new(p, nil, nil) end)
    say("craft logic scan took " .. (getTimestampMs() - t0) .. " ms")
    counts(w, "_craftState", w._craftCache, "craft")
end)
at(230, function() shot("04_craft_ready") end)
at(235, function() local w = ZeD_WorldWindow.getWindow(); CC.cycleShow(w._craftState, nil) end)
at(250, function() local w = ZeD_WorldWindow.getWindow(); counts(w, "_craftState", w._craftCache, "craft"); shot("05_craft_known") end)
at(255, function() local w = ZeD_WorldWindow.getWindow(); CC.cycleShow(w._craftState, nil) end)
at(270, function() local w = ZeD_WorldWindow.getWindow(); counts(w, "_craftState", w._craftCache, "craft"); shot("06_craft_all") end)
at(275, function() local w = ZeD_WorldWindow.getWindow(); CC.cycleShow(w._craftState, nil) end)
at(280, function() ZeD_WorldWindow.openTab(pn, "build") end)
at(370, function()
    local w = ZeD_WorldWindow.getWindow()
    local t0 = getTimestampMs()
    w._buildLogicAt = 0
    CC.logicScan(w._buildCache, w, "build", function() return BuildLogic.new(p, nil, nil) end)
    say("build logic scan took " .. (getTimestampMs() - t0) .. " ms")
    counts(w, "_buildState", w._buildCache, "build")
end)
at(380, function() shot("07_build_ready") end)
-- 3. the map with a controller: zoom on the cursor, the D-pad's growing step
at(390, function() ZeD_WorldWindow.openTab(pn, "maps") end)
at(470, function()
    local w = ZeD_WorldWindow.getWindow()
    local mp = w and w._worldMapPanel
    if not mp then say("no map panel"); return end
    local z0 = mp.mapAPI:getZoomF()
    ZeD.MapsTab.gpZoom(w, -1); ZeD.MapsTab.gpZoom(w, -1)
    say(string.format("map zoom %.2f -> (two steps in) requested", z0))
    local steps2 = {}
    for i = 1, 6 do steps2[#steps2 + 1] = ZeD.MapsTab.gpCursorStep() end
    say("D-pad steps held: " .. table.concat(steps2, " "))
end)
at(520, function()
    local w = ZeD_WorldWindow.getWindow()
    local mp = w and w._worldMapPanel
    if mp then say(string.format("map zoom now %.2f", mp.mapAPI:getZoomF())) end
    shot("08_map")
end)
at(530, function()
    -- take back what was given
    for _, it in ipairs(given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 540 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
