-- ZeDUI/tools/qa/zedqa_button_case_game.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: button words in sentence case across the windows.
-- Shoots an item card (header verbs, flag chips, Wash / Repair / Pad), the
-- Health tab's exercise pills, the Thermal tab's view pills, the Animals tab's
-- footer, the Foraging strip, the Craft tab and the Vehicle tab beside the pickup.
-- A shirt is given and taken back. Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go;
-- grep "ZEDQA bg"; captures Screenshots/zqa_bg_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA bg " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bg_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local shirt, pickup
local pairWasOpen = false
-- the pickup: the nearest of the loaded cell, else one spawned beside the character (removed at the end). The
-- character is left wherever the last run ended, so the QA save's own pickup is not always loaded.
local spawned = {}
local dead = false
local finalAt = nil
-- (an abort skips the other steps and jumps the tick counter to just before the final one)
local function abort(msg) say("ERR " .. msg); dead = true; if finalAt then tick = finalAt - 2 end end
local function final(n, fn) finalAt = n; steps[#steps + 1] = { n = n, fn = fn, final = true } end   -- runs even after an abort
local function nearVehicle(pred)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if pred(v) then local d = v:DistTo(p); if not bd or d < bd then best, bd = v, d end end
    end
    return best
end
local function spawnVehicle(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then say("no square for " .. script); return nil end
    local ok, v = pcall(addVehicleDebug, script, IsoDirections.N, nil, sq)
    if ok and v then spawned[#spawned + 1] = v; return v end
    return nil
end
local function removeSpawned()
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    spawned = {}
end
local function charTab(id) local w = ZeD_CharacterWindow.getWindow(); if w then w._activeTab = id end end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    pickup = nearVehicle(function(v) return v:getScriptName() == "Base.PickUpTruck" end)
    if not pickup then
        pickup = spawnVehicle("Base.PickUpTruck", -4, 0)
        say("no pickup in the loaded cell; spawned one beside the character: " .. tostring(pickup ~= nil))
    end
    shirt = p:getInventory():AddItem("Base.Tshirt_DefaultTEXTURE")
    say("pickup " .. tostring(pickup ~= nil) .. " shirt " .. tostring(shirt ~= nil))
    if not pickup then abort("no pickup in the loaded cell and the spawn failed (the Vehicle tab needs one)") end
end)
-- (a moment for a spawned pickup to settle before the character steps beside it)
at(15, function() if pickup then p:teleportTo(pickup:getX() + 2.5, pickup:getY() + 1.5, 0) end end)
at(40, function()
    pairWasOpen = ZeD_CharacterWindow.isOpen()
    if not pairWasOpen then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
at(70, function() say("card open " .. tostring(ZeD.Garment.openCard(p, shirt))) end)
at(110, function() shot("01_item_card") end)
at(120, function() local w = ZeD_CharacterWindow.getWindow(); if w and w._closeDrawer then pcall(function() w:_closeDrawer() end) end; charTab("health") end)
at(160, function() shot("02_health") end)
at(170, function() charTab("thermal") end)
at(210, function() shot("03_thermal") end)
at(220, function() charTab("loot"); ZeD_WorldWindow.openTab(pn, "animals") end)
at(270, function() shot("04_animals") end)
at(280, function() ZeD_WorldWindow.openTab(pn, "forage") end)
at(330, function() shot("05_forage") end)
at(340, function() ZeD_WorldWindow.openTab(pn, "craft") end)
at(420, function() shot("06_craft") end)
at(430, function() ZeD_WorldWindow.openTab(pn, "vehicle") end)
at(500, function() shot("07_vehicle") end)
final(510, function()
    if ZeD_WorldWindow.getWindow() then ZeD_WorldWindow.openTab(pn, "loot") end
    -- the pair back as it was found
    if not pairWasOpen and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() if shirt and shirt:getContainer() then shirt:getContainer():Remove(shirt) end end)
    removeSpawned()
    say("DONE" .. (dead and " (aborted)" or ""))
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick and (s.final or not dead) then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 520 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
