-- ZeDUI/tools/qa/zedqa_vehicle_small.lua  (Nov 2 2026, QA; punch list 61, the Vehicle tab on small screens)
-- In game, run at 1280x720 or the Deck, Normal text. From the drag strip (ZEDQA_HOME), a plain car is spawned beside the
-- character with its key, and the game's own "Vehicle Mechanics" (ISVehicleMenu.onMechanic) walks over and opens the
-- hood; ZeD's World window shows the Vehicle tab. First a picture of the Vehicle tab before the hood is opened (the figure
-- with Type, Distance and Key beside it, the car not yet looked at); then, once the hood is open and the tab reads the car,
-- one of the tab and one with the hood's card open. Then the car and key are taken away.
-- grep "ZEDQA vsm"; shots zqa_vsm_*.png.
local function say(s) print("ZEDQA vsm " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("vsm") end
local p = getPlayer()
local MT = ZeD and ZeD.MechanicsTab
if not (p and MT) then say("ERR the Vehicle tab is not loaded"); say("DONE"); return end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_vsm_" .. n .. "_" .. sw .. "x" .. sh .. ".png") end); say("shot " .. n) end
local function W() return ZeD_WorldWindow.getWindow() end
if getGameSpeed() <= 0 then setGameSpeed(1) end
local v, key
local t0 = getTimestampMs()
local phase = "settle"
local mark = nil
local function since() return getTimestampMs() - (mark or t0) end
local function spawn()
    for _, o in ipairs({ { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 }, { 4, 2 }, { -4, 2 } }) do
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free then v = addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq); if v then return true end end
    end
    return false
end
local function finish()
    pcall(function() if ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
    if v then pcall(function() v:permanentlyRemove() end) end
    if key then pcall(function() p:getInventory():Remove(key) end) end
    say("DONE")
end
local function tick()
    if phase == "settle" then
        if getTimestampMs() - t0 < 4000 then return end
        if not spawn() then say("ERR no free square for the car"); Events.OnTick.Remove(tick); finish(); return end
        pcall(function() key = p:getInventory():AddItem(v:createVehicleKey()) end)
        say("car " .. tostring(v:getScriptName()) .. " at " .. math.floor(v:getX()) .. "," .. math.floor(v:getY()))
        phase, mark = "physics", getTimestampMs()
    elseif phase == "physics" then
        if since() < 3000 then return end
        -- before the hood: the World window's Vehicle tab on the car not yet looked at (Type, Distance and Key beside the figure)
        if not ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
        phase, mark = "tabpick", getTimestampMs()
    elseif phase == "tabpick" then
        if since() < 1500 then return end
        pcall(ZeD_WorldWindow.openTab, 0, "vehicle")
        phase, mark = "shot0", getTimestampMs()
    elseif phase == "shot0" then
        if since() < 2500 then return end
        local w = W()
        say("before the hood: tab " .. tostring(w and w._activeTab) .. " | inspected " .. tostring(MT.isInspected(v)))
        shot("before_hood")
        ISVehicleMenu.onMechanic(p, v)
        say("onMechanic")
        phase, mark = "inspect", getTimestampMs()
    elseif phase == "inspect" then
        local w = W()
        if MT.isInspected(v) and w and w._activeTab == "vehicle" then
            local hood = v:getPartById("EngineDoor")
            say("Vehicle tab open after " .. since() .. " ms | hood open " .. tostring(hood and hood:getDoor() and hood:getDoor():isOpen())
                .. " | World window " .. math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight())
                .. " | screen " .. sw .. "x" .. sh .. " | UI scale " .. tostring(ZeD.T and ZeD.T.scale))
            phase, mark = "shot1", getTimestampMs()
        elseif since() > 60000 then say("ERR the Vehicle tab never opened (60 s)"); Events.OnTick.Remove(tick); finish() end
    elseif phase == "shot1" then
        if since() < 2500 then return end
        shot("tab")
        local s = MT.getState(W())
        if s then s.view, s.card, s.verb, s.confirm, s.cardScroll = "card", "EngineDoor", nil, nil, 0 end
        phase, mark = "shot2", getTimestampMs()
    elseif phase == "shot2" then
        if since() < 2500 then return end
        shot("hood_card")
        local s = MT.getState(W()); if s then s.view, s.card = "overview", nil end
        Events.OnTick.Remove(tick)
        finish()
    end
end
Events.OnTick.Add(tick)
say("start")
