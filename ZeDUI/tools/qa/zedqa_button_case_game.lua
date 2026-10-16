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
local shirt
local function charTab(id) local w = ZeD_CharacterWindow.getWindow(); if w then w._activeTab = id end end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if v:getScriptName() == "Base.PickUpTruck" then local d = v:DistTo(p); if not bd or d < bd then best, bd = v, d end end
    end
    if best then p:teleportTo(best:getX() + 2.5, best:getY() + 1.5, 0) end
    shirt = p:getInventory():AddItem("Base.Tshirt_DefaultTEXTURE")
    say("pickup " .. tostring(best ~= nil) .. " shirt " .. tostring(shirt ~= nil))
end)
at(40, function() if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end end)
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
at(510, function()
    ZeD_WorldWindow.openTab(pn, "loot")
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() if shirt and shirt:getContainer() then shirt:getContainer():Remove(shirt) end end)
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 520 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
