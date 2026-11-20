-- ZeDUI/tools/qa/zedqa_p5_date.lua  (Nov 20 2026, QA)
-- In game on the ZeD-QA save: the bug hunt's P5, the five-character date "12-25" on the CaZio classic faces (black
-- and gold), whose LCD is 44 px wide: at the old pitch the date ran into the weekday. Build's batch 1 set pitch 5.
-- For each classic watch: worn, the watch in Corner (the full plate), the game date set to Dec 25 and the time of
-- day to 10:58; the display's dateMD read ("12-25" wanted) and a full-screen picture zqa_p5_<watch>.png taken with the
-- pointer off the watch. Puts back the player's own watch, the date, the time of day and the watch option.
-- grep "ZEDQA p5d".
local p = getPlayer(); local W = ZeD.Watch; local gt = getGameTime()
local function say(s) print("ZEDQA p5d " .. tostring(s)) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_p5_" .. name .. ".png") end) end
local inv = p:getInventory()
local function mk(ft) if instanceItem then return instanceItem(ft) end; return InventoryItemFactory.CreateItem(ft) end
local own, ownLoc = nil, nil
local made = {}
local tod0, day0, month0 = gt:getTimeOfDay(), gt:getDay(), gt:getMonth()
local placeOpt = ZeD.Settings and ZeD.Settings.watchPlaceOption
local placeWas = placeOpt and placeOpt:getValue()
local fails = 0
local function inst() return W.getInstance() end
local function wear(name)
    local worn = p:getWornItems()
    local cur = {}
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then cur[#cur + 1] = it end
    end
    for _, it in ipairs(cur) do p:removeWornItem(it) end
    local it = made[name]
    if not it then
        it = mk("Base.WristWatch_Left_" .. name)
        if not it then say("FAIL could not make " .. name); fails = fails + 1; return nil end
        inv:AddItem(it); made[name] = it
    end
    p:setWornItem(ownLoc, it)
    return it
end

at(5, function()
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then own = it; ownLoc = wi:getLocation() end
    end
    if not ownLoc then
        local t = mk("Base.WristWatch_Left_DigitalBlack")
        ownLoc = t and t:getBodyLocation()
    end
    say("own watch " .. tostring(own and own:getFullType()) .. " at " .. tostring(ownLoc) .. "; date was " ..
        tostring(month0 + 1) .. "-" .. tostring(day0 + 1))
    setGameSpeed(1)
    if placeOpt then placeOpt:setValue(2) end   -- Corner: the full plate
    gt:setMonth(11); gt:setDay(24)               -- (both counted from 0: December 25)
    gt:setTimeOfDay(10.97)
    pcall(function() Mouse.setXY(20, 20) end)
end)

local n = 30
for _, name in ipairs({ "ClassicBlack", "ClassicGold" }) do
    at(n, function() gt:setTimeOfDay(10.97); wear(name) end)
    at(n + 40, function()
        local w = inst()
        local d = w and w._st and w._st.display or {}
        local plate = w and w._def and w._def.plate
        local ok = d.dateMD == "12-25"
        if not ok then fails = fails + 1 end
        say((ok and "PASS " or "FAIL ") .. name .. " (plate " .. tostring(plate) .. "): the display's date reads " ..
            tostring(d.dateMD) .. " (wanted 12-25), weekday " .. tostring(d.day))
        pcall(function() Mouse.setXY(20, 20) end)
    end)
    at(n + 50, function() shot(name) end)
    n = n + 70
end

at(n, function()
    local worn = p:getWornItems()
    local watches = {}
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then watches[#watches + 1] = it end
    end
    for _, it in ipairs(watches) do p:removeWornItem(it) end
    for _, it in pairs(made) do inv:Remove(it) end
    if own and ownLoc then p:setWornItem(ownLoc, own) end
    gt:setMonth(month0); gt:setDay(day0)
    gt:setTimeOfDay(tod0)
    if placeOpt and placeWas then placeOpt:setValue(placeWas) end
    say("put back: own watch " .. tostring(own and own:getFullType()) .. ", date " .. tostring(gt:getMonth() + 1) .. "-" ..
        tostring(gt:getDay() + 1) .. ((gt:getMonth() == month0 and gt:getDay() == day0) and "" or "  ERR date not back"))
    say((fails == 0) and "PASS all" or ("FAIL " .. fails))
    say("DONE")
end)

local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
