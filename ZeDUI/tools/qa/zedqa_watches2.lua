-- ZeD QA (Oct 16 2026): the nine watch plates and the new steel Timez item, in game.
-- Wears each watch in turn (left wrist), screenshots it by day, then a few at night, lit, and with the alarm's setting
-- open; checks the new item exists with its name, icon and models; puts the player's own watch and the time back.
local p = getPlayer(); local W = ZeD.Watch; local gt = getGameTime()
local function say(s) print("ZEDQA watches " .. tostring(s)) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local inv = p:getInventory()
local function mk(ft) if instanceItem then return instanceItem(ft) end; return InventoryItemFactory.CreateItem(ft) end
local own, ownLoc = nil, nil
local made = {}
local tod0 = gt:getTimeOfDay()
local LIST = { "DigitalBlack", "DigitalDress", "DigitalRed", "DigitalTimez", "ClassicBlack", "ClassicGold", "ClassicBrown",
               "ClassicMilitary", "Expensive" }
local function inst() return W.getInstance() end
local function ids() local t = {}; for _, h in ipairs(inst()._hit or {}) do t[#t + 1] = h.id end; table.sort(t); return table.concat(t, ",") end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_watch_" .. name .. ".png") end) end
local function wear(name)
    local cur = nil
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then cur = it end
    end
    if cur then p:removeWornItem(cur) end
    local it = made[name]
    if not it then
        it = mk("Base.WristWatch_Left_" .. name)
        if not it then say("FAIL could not make " .. name); return nil end
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
    say("own watch " .. tostring(own and own:getFullType()) .. " at " .. tostring(ownLoc))
    if not ownLoc then
        -- no watch on: borrow the left wrist location from a fresh black digital
        local t = mk("Base.WristWatch_Left_DigitalBlack")
        ownLoc = t and t:getBodyLocation()
        say("no own watch; location " .. tostring(ownLoc))
    end
    setGameSpeed(1)
    gt:setTimeOfDay(10.97)
    -- the new item: does it exist, its name, icon, model
    local t = mk("Base.WristWatch_Left_DigitalTimez")
    local r = mk("Base.WristWatch_Right_DigitalTimez")
    say("item left " .. tostring(t ~= nil) .. " right " .. tostring(r ~= nil))
    if t then
        say("name '" .. tostring(t:getDisplayName()) .. "' icon " .. tostring(t:getTexture() and t:getTexture():getName()) ..
            " world " .. tostring(t:getWorldStaticModel()) .. " clothing " .. tostring(t:getClothingItem() and t:getClothingItem():getName()) ..
            " digital " .. tostring(t:isDigital()) .. " class " .. tostring(instanceof(t, "AlarmClockClothing")))
    end
end)

local n = 30
for _, name in ipairs(LIST) do
    at(n, function() wear(name) end)
    at(n + 20, function()
        local i = inst()
        say(name .. " plate " .. tostring(i._def and i._def.plate) .. " size " .. i:getWidth() .. "x" .. i:getHeight() ..
            " at " .. i:getX() .. "," .. i:getY() .. " hits " .. ids())
        shot("day_" .. name)
    end)
    n = n + 40
end
-- a CaZio digital: the alarm's setting open, then night
at(n, function() wear("DigitalBlack"); end)
at(n + 10, function() inst():_act("set") end)
at(n + 25, function() say("setting open " .. tostring(inst()._setOpen) .. " hits " .. ids()); shot("set_DigitalBlack") end)
at(n + 30, function() inst():_act("setup"); inst():_act("setup") end)
at(n + 40, function() local it = made.DigitalBlack; say("after + + armed " .. tostring(it:isAlarmSet()) .. " hour " .. tostring(it:getHour())); inst():_act("set") end)
n = n + 60
at(n, function() gt:setTimeOfDay(23.5) end)
at(n + 20, function() say("night dark=" .. tostring(inst()._st.dark)); shot("night_DigitalBlack") end)
-- the Timez at night, then lit
for _, name in ipairs({ "DigitalTimez", "ClassicBrown", "Expensive" }) do
    n = n + 40
    at(n, function() wear(name) end)
    at(n + 20, function() shot("night_" .. name) end)
    if name ~= "Expensive" then
        at(n + 25, function() inst():_act("light") end)
        at(n + 35, function() say(name .. " lit=" .. tostring(inst()._st.lit)); shot("lit_" .. name) end)
    end
end
n = n + 260      -- wait past the light's 3 s
at(n, function() say("light out: lit=" .. tostring(inst()._st.lit) .. " dark=" .. tostring(inst()._st.dark)) end)
at(n + 10, function()
    -- put everything back
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i); local it = wi and wi:getItem()
        if it and instanceof(it, "AlarmClockClothing") then p:removeWornItem(it) end
    end
    for _, it in pairs(made) do inv:Remove(it) end
    if own and ownLoc then p:setWornItem(ownLoc, own) end
    gt:setTimeOfDay(tod0)
    say("restored own watch " .. tostring(own and own:getFullType()) .. "; DONE")
end)

local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
