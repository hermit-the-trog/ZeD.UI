-- ZeD QA S124: tooltip frame in design units, map label layers, dash/watch text after the raw-manager measure fix
local p = getPlayer()
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function shot(tag) pcall(function() getCore():TakeFullScreenshot("zedqa_tm_" .. tag .. ".png") end) end
local function tabsOf(strip) local out = {}; for _, z in ipairs(strip._hitZones or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = { id = z.id:sub(5), x = z.x + math.floor(z.w / 2), y = z.y + math.floor(z.h / 2) } end end; return out end
local tip1, tip2, cur
local t = 5
at(t, function() if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end; print("ZEDQA tm root=" .. tostring(ZeD.Scale.root()) .. " proxy=" .. tostring(getTextManager() == ZeD.TM) .. " realTM=" .. tostring(ZeD.Text.realTM() ~= nil)) end); t = t + 5
-- 1. scripted tooltips: named + texture + footnote, and a plain long description
at(t, function()
    tip1 = ISToolTip:new(); tip1:initialise(); tip1:setVisible(true)
    tip1:setName("Hammer"); tip1:setTexture("Item_Hammer")
    tip1:setDescription("Drives nails, pulls them, breaks things. Needed for most carpentry builds. <LINE> Condition 7/10")
    tip1.footNote = "Right-click for options"
    tip1.followMouse = false; tip1:setX(300); tip1:setY(300); tip1:addToUIManager()
    tip2 = ISToolTip:new(); tip2:initialise(); tip2:setVisible(true)
    tip2:setDescription("A long plain tooltip without a title: the description panel wraps through the text-manager proxy, so the line breaks and the frame must agree with the zoomed glyphs at any root scale.")
    tip2.followMouse = false; tip2:setX(300); tip2:setY(620); tip2:addToUIManager()
end)
at(t + 15, function()
    shot("tooltips")
    local function dims(tp) if not tp then return "nil" end; local dp = tp.descriptionPanel; return tp:getWidth() .. "x" .. tp:getHeight() .. " at " .. tp:getX() .. "," .. tp:getY() .. " desc=" .. tostring(dp and (dp:getWidth() .. "x" .. dp:getHeight() .. " lines=" .. tostring(dp.lines and #dp.lines) .. " font=" .. tostring(dp.defaultFont))) end
    print("ZEDQA tm tip1 " .. dims(tip1)); print("ZEDQA tm tip2 " .. dims(tip2))
    local w = ZeD.Watch and ZeD.Watch.getInstance(); print("ZEDQA tm watch family=" .. tostring(w and w._family) .. " size=" .. tostring(w and w:getWidth()) .. "x" .. tostring(w and w:getHeight()) .. " at " .. tostring(w and w:getX()) .. "," .. tostring(w and w:getY()))
end)
at(t + 20, function() if tip1 then tip1:removeFromUIManager() end; if tip2 then tip2:removeFromUIManager() end end)
t = t + 30
-- 2. Maps tab of the World window
at(t, function() local cw = ZeD_CharacterWindow.getWindow(); if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end end); t = t + 40
at(t, function()
    local ww = ZeD_WorldWindow.getWindow(); local strip = ww and ww._actionTabStrip
    if not strip then print("ZEDQA tm no world strip") return end
    local ids = {}
    for _, tb in ipairs(tabsOf(strip)) do ids[#ids + 1] = tb.id; if tb.id:find("map") then strip:onMouseDown(tb.x, tb.y); print("ZEDQA tm maps tab clicked " .. tb.id) end end
    print("ZEDQA tm world tabs " .. table.concat(ids, ","))
end); t = t + 40
at(t, function() local ww = ZeD_WorldWindow.getWindow(); shot("maps"); print("ZEDQA tm maps shot active=" .. tostring(ww and ww._activeTab) .. " win=" .. tostring(ww and ww:getX()) .. "," .. tostring(ww and ww:getY()) .. " " .. tostring(ww and ww:getWidth()) .. "x" .. tostring(ww and ww:getHeight())) end); t = t + 5
at(t, function() local ww = ZeD_WorldWindow.getWindow(); local strip = ww and ww._actionTabStrip; local tabs = strip and tabsOf(strip); if tabs and tabs[1] then strip:onMouseDown(tabs[1].x, tabs[1].y) end end); t = t + 10
at(t, function() local cw = ZeD_CharacterWindow.getWindow(); if cw and cw:isVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end end); t = t + 20
-- 3. dashboard: spawn a small car beside the player, enter, capture, leave, remove
at(t, function() local v0 = p:getVehicle(); if v0 then v0:exit(p); triggerEvent("OnExitVehicle", p) end end); t = t + 20
at(t, function()
    local sq = getCell():getGridSquare(math.floor(p:getX()) + 5, math.floor(p:getY()) + 2, math.floor(p:getZ()))
    local v = sq and addVehicleDebug("Base.SmallCar02", IsoDirections.N, nil, sq) or nil
    cur = v
    if v then v:enter(0, p); triggerEvent("OnEnterVehicle", p) else print("ZEDQA tm spawn failed sq=" .. tostring(sq)) end
end)
at(t + 20, function() local d = ZeD.Dashboard.getInstance(); if d and d._st then if not d._st.radioOn then d:_fire("pwr", false) end; if not d._st.heaterOn then d:_fire("heat", false) end end end)
at(t + 50, function() shot("dash"); local d = ZeD.Dashboard.getInstance(); print("ZEDQA tm dash design=" .. tostring(d and d._designId) .. " visible=" .. tostring(d and d:isVisible()) .. " size=" .. tostring(d and d:getWidth()) .. "x" .. tostring(d and d:getHeight()) .. " at " .. tostring(d and d:getX()) .. "," .. tostring(d and d:getY())) end)
at(t + 60, function() if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end; if cur then pcall(function() cur:permanentlyRemove() end) end; cur = nil end)
t = t + 70
at(t, function() print("ZEDQA tm done") end)
local n, i = 0, 1
local ev = Events.OnTickEvenPaused or Events.OnTick
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then ev.Remove(tick) end end
ev.Add(tick); print("ZEDQA tm armed")
