-- ZeDUI/tools/qa/zedqa_container_controls_captures.lua  (Oct 16 2026)
-- Backdrops for the container controls mockup (vanilla's Take all / Transfer all
-- row): the ZeD Character + World windows with the pickup's truck bed open, and
-- vanilla's inventory + loot windows on the same truck bed with their controls.
-- Puts nails, planks, a hammer and canned food in the bed and some nails and a
-- plank in the bag (so the "same type" buttons have something to match); all
-- taken back at the end. Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep
-- "ZEDQA cc"; captures Screenshots/zqa_cc_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA cc " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cc_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local pickup, bed
local given = {}
local function put(container, ft, n)
    for _ = 1, n or 1 do
        local ok, it = pcall(function() return container:AddItem(ft) end)
        if ok and it then given[#given + 1] = it end
    end
end

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
    pickup = best
    local part = pickup and (pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen"))
    if part then
        -- stand at the bed's own access area so vanilla lists it as a container
        local c = pickup:getAreaCenter(part:getArea())
        if c then p:teleportTo(c:getX(), c:getY(), 0) end
    elseif pickup then p:teleportTo(pickup:getX() + 2.5, pickup:getY() + 1.5, 0) end
    say("pickup " .. tostring(pickup ~= nil) .. " bed part " .. tostring(part and part:getId()))
end)
at(40, function()
    local part = pickup and (pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen"))
    bed = part and part:getItemContainer()
    say("truck bed " .. tostring(bed ~= nil) .. " dist " .. string.format("%.1f", pickup and pickup:DistTo(p) or -1))
    if bed then
        put(bed, "Base.Nails", 3); put(bed, "Base.Plank", 4); put(bed, "Base.Hammer"); put(bed, "Base.TinnedBeans", 2); put(bed, "Base.Screws", 2)
    end
    put(p:getInventory(), "Base.Nails", 2); put(p:getInventory(), "Base.Plank", 1)
end)
at(60, function()
    if not (ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
at(110, function()
    local w = ZeD_WorldWindow.getWindow()
    if w and w._containers then
        for i, c in ipairs(w._containers) do
            if c.inventory == bed then w._activeContainer = i; w._mainVisible = false; say("world window on the truck bed (" .. i .. ")") end
        end
    end
end)
at(150, function()
    local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    say(string.format("char %d,%d %dx%d  world %d,%d %dx%d", cw:getX(), cw:getY(), cw:getWidth(), cw:getHeight(), ww:getX(), ww:getY(), ww:getWidth(), ww:getHeight()))
    shot("zed_truckbed")
end)
at(160, function() ZeD_CharacterWindow.toggleBothPaired(pn) end)
at(190, function()
    local vi, vl = getPlayerInventory(pn), getPlayerLoot(pn)
    vi:setVisible(true); vl:setVisible(true)
    pcall(function() vl:refreshBackpacks() end)
    for _, b in ipairs(vl.backpacks or {}) do if b.inventory == bed then vl:selectContainer(b) end end
    say(string.format("vanilla inv %d,%d %dx%d  loot %d,%d %dx%d", vi:getX(), vi:getY(), vi:getWidth(), vi:getHeight(), vl:getX(), vl:getY(), vl:getWidth(), vl:getHeight()))
end)
at(230, function() shot("vanilla_truckbed") end)
at(240, function()
    getPlayerInventory(pn):setVisible(false); getPlayerLoot(pn):setVisible(false)
    for _, it in ipairs(given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 250 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
