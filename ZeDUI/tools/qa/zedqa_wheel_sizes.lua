-- ZeDUI/tools/qa/zedqa_wheel_sizes.lua  (S125)
-- The ZeD wheel at different slice counts (3, 3, 5, 9, 10, 11), resting and
-- pointed, for the director's sizing questions. Copy to Zomboid/Lua/zedqa.lua
-- and bump zedqa.go; grep console.txt for "ZEDQA ws". Uses ZeD.Wheel.qaPoint.
local p = getPlayer()
local m = getPlayerRadialMenu(0)
local W = ZeD.Wheel
local ui = UIManager.getUI()
for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ws_" .. n .. ".png") end) end
local function find(full) local items = p:getInventory():getItems(); for i = 0, items:size() - 1 do local x = items:get(i); if x:getFullType() == full then return x end end end
-- the gun wheel needs a ranged weapon in hand: the character's pistol, or one given for the run
-- (find returns nothing, not nil, when there is none, which handed setPrimaryHandItem no argument)
local gave
local function pistol()
    local x = find("Base.Pistol")
    if not x then x = p:getInventory():AddItem("Base.Pistol"); gave = x end
    return x
end
-- the pickup the 11-slice vehicle wheel needs: one within 20 tiles, else one spawned beside the character (removed at
-- the end). The character is left wherever the last run ended, so the QA save's own pickup is not always near.
local car, spawnedCar
do local it = getCell():getVehicles():iterator(); while it:hasNext() do local v = it:next(); if v:getScript():getFullName() == "Base.PickUpTruck" and v:DistTo(p) < 20 then car = v end end end
if not car then
    local sq = getCell():getGridSquare(math.floor(p:getX()) - 4, math.floor(p:getY()), math.floor(p:getZ()))
    local ok, v = pcall(function() return sq and addVehicleDebug("Base.PickUpTruck", IsoDirections.N, nil, sq) end)
    if ok and v then car, spawnedCar = v, v end
    print("ZEDQA ws no pickup within 20 tiles; spawned one beside the character: " .. tostring(spawnedCar ~= nil))
    if not car then print("ZEDQA ws ERR no pickup within 20 tiles and the spawn failed: the vehicle wheel scenes run without one") end
end
local prim = p:getPrimaryHandItem()
local bw = getPlayerData(0).backButtonWheel
local scenes = {
    { "a_gun3", function() p:setPrimaryHandItem(pistol()); local f = ISFirearmRadialMenu:new(p); f:fillMenu(); f:display() end, -1 },
    { "b_dright3", function() ISDPadWheels.onDisplayRight({ player = 0, id = -1 }) end, 2 },
    { "c_emotes5", function() ISEmoteRadialMenu:new(p):fillMenu() end, 4 },
    { "d_signal9", function() ISEmoteRadialMenu:new(p):fillMenu("signal") end, 8 },
    { "e_back10", function() bw:addCommands(); bw:setVisible(true); bw:addToUIManager() end, 2, true },
    { "f_enter", function() if car then car:enter(0, p); triggerEvent("OnEnterVehicle", p) end end, nil },
    { "g_car11", function() ISVehicleMenu.showRadialMenu(p) end, -1 },
    { "h_car11pt", function() ISVehicleMenu.showRadialMenu(p) end, 6 },
}
local t0 = 5
for _, sc in ipairs(scenes) do
    at(t0, function() sc[2](); W.qaPoint = sc[3] end)
    if sc[3] ~= nil then
        at(t0 + 25, function()
            local mm = sc[4] and bw or m
            local _, _, r = W.geom(mm)
            print(string.format("ZEDQA ws %s n=%d r=%d w=%d", sc[1], #mm.slices, r, mm.width))
            shot(sc[1])
        end)
        at(t0 + 45, function() W.qaPoint = nil; if sc[4] then bw:removeFromUIManager(); bw:setVisible(false) else m:undisplay() end end)
    end
    t0 = t0 + 55
end
at(t0, function() p:setPrimaryHandItem(prim); if gave then p:getInventory():Remove(gave) end; if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end end)
at(t0 + 3, function()
    if spawnedCar then pcall(function() spawnedCar:permanentlyRemove() end); spawnedCar = nil end
    print("ZEDQA ws done")
end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then print("ZEDQA ws ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > t0 + 5 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
