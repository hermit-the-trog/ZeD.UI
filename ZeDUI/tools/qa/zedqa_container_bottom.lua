-- ZeDUI/tools/qa/zedqa_container_bottom.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: the container buttons' row at the bottom of
-- each window's list. Beside the pickup's truck bed (a long list): both rows
-- at the bottom, the list scrolled to its end (its last row shows above the
-- row), the controller on the World window's Take all; then a campfire placed
-- beside you (the ribbon at the bottom). Everything given is taken back.
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA cb";
-- captures Screenshots/zqa_cb_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA cb " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cb_" .. n .. ".png") end) end
local function ww() return ZeD_WorldWindow.getWindow() end
local function wc() return ww()._mainContent end
local bed, given = nil, {}
local function select(pred)
    local w = ww()
    for i, c in ipairs(w._containers or {}) do
        if c.inventory and pred(c.inventory) then w._activeContainer = i; w._viewedContainer = nil; w._mainVisible = false; return true end
    end
    return false
end
local function camp() return getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), 0) end

local steps = {
    { 1, function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
        local best, bd
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local v = it:next()
            if v:getScriptName() == "Base.PickUpTruck" then local d = v:DistTo(p); if not bd or d < bd then best, bd = v, d end end
        end
        local part = best and (best:getPartById("TruckBed") or best:getPartById("TruckBedOpen"))
        local c = part and best:getAreaCenter(part:getArea())
        if c then p:teleportTo(c:getX(), c:getY(), 0) end
        bed = part and part:getItemContainer()
    end },
    { 40, function()
        for _, ft in ipairs({ "Base.Nails", "Base.Nails", "Base.Plank", "Base.TinnedBeans", "Base.Screws", "Base.Hammer", "Base.Saw", "Base.Rope" }) do
            local it = bed:AddItem(ft); if it then given[#given + 1] = it end
        end
        local it = p:getInventory():AddItem("Base.Nails"); if it then given[#given + 1] = it end
        if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    end },
    { 40, function() say("bed selected " .. tostring(select(function(inv) return inv == bed end))) end },
    { 40, function()
        local c = wc()
        say(string.format("world list %dx%d, row %s at y %s", c:getWidth(), c:getHeight(), tostring(c._ccH), tostring(c._cc and c._cc.row and c._cc.row.y)))
        shot("01_rows_at_bottom")
    end },
    { 5, function() local c = wc(); if c._scroll then c._scroll:setScrollPos(1.0) end end },
    { 20, function() shot("02_list_end") end },
    { 5, function()
        local F, D = ZeD.Input.Focus, ZeD.Input.Detector
        D.setLockedMode("gamepad")
        F.claimFocus(ww())
        for zi, z in ipairs(ww()._focusRing) do if z.zone == "worldCtl" then ww()._focusIdx = zi; z.focusedElementIdx = 1 end end
    end },
    { 25, function() shot("03_pad_take_all") end },
    { 5, function() ZeD.Input.Detector.setLockedMode(nil); ZeD.Input.Focus.releaseFocus() end },
    { 5, function()
        local lo = camp() and SCampfireSystem.instance:getLuaObjectOnSquare(camp())
        if not lo then SCampfireSystem.instance:addCampfire(camp()) end
    end },
    { 60, function() say("campfire selected " .. tostring(select(function(inv) return inv:getType() == "campfire" end))) end },
    { 30, function() shot("04_campfire_ribbon") end },
    { 5, function()
        local lo = camp() and SCampfireSystem.instance:getLuaObjectOnSquare(camp())
        if lo then pcall(function() SCampfireSystem.instance:removeCampfire(lo) end) end
        for _, it in ipairs(given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
        if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
        say("DONE")
    end },
}
local si, wait = 1, 0
local function t()
    local s = steps[si]
    if not s then Events.OnTick.Remove(t); return end
    wait = wait + 1
    if wait >= s[1] then
        local ok, e = pcall(s[2])
        if not ok then say("ERR step " .. si .. " " .. tostring(e)) end
        si, wait = si + 1, 0
    end
end
Events.OnTick.Add(t)
say("start")
