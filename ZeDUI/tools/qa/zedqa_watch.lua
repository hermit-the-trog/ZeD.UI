-- ZeD QA v5: watch faces, alarm set mode, speed keys, no-watch strip
local p = getPlayer(); local Wt = ZeD.Watch
local kinds = { "DigitalBlack", "DigitalRed", "DigitalDress", "ClassicBlack", "ClassicBrown", "ClassicGold", "ClassicMilitary", "Expensive" }
local function stripWatches()
    local inv = p:getInventory(); local worn = p:getWornItems(); local rm = {}
    for i = 0, worn:size() - 1 do local it = worn:get(i):getItem(); if it and instanceof(it, "AlarmClockClothing") then rm[#rm + 1] = it end end
    for _, it in ipairs(rm) do p:removeWornItem(it); inv:Remove(it) end
end
local function wear(kind)
    stripWatches()
    local item = p:getInventory():AddItem("Base.WristWatch_Right_" .. kind)
    if item then p:setWornItem(item:getBodyLocation(), item) end
    return item
end
local function shoot(tag)
    local w = Wt.getInstance()
    pcall(function() getCore():TakeFullScreenshot("zedqa_w_" .. tag .. ".png") end)
    print("ZEDQA w " .. tag .. " family=" .. tostring(w and w._family) .. " item=" .. tostring(w and w._item and w._item:getFullType()) .. " size=" .. tostring(w and w:getWidth()) .. "x" .. tostring(w and w:getHeight()) .. " at " .. tostring(w and w:getX()) .. "," .. tostring(w and w:getY()) .. " hits=" .. tostring(w and #(w._hit or {})) .. " setOpen=" .. tostring(w and w._setOpen) .. " speed=" .. tostring(UIManager.getSpeedControls():getCurrentGameSpeed()))
end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local t = 5
for _, k in ipairs(kinds) do local kind = k; at(t, function() wear(kind) end); at(t + 15, function() shoot(kind) end); t = t + 25 end
at(t, function() wear("DigitalBlack") end); t = t + 15
at(t, function() Wt.getInstance():_act("set") end); at(t + 10, function() shoot("setmode") end); t = t + 20
at(t, function() local w = Wt.getInstance(); w:_act("setup"); w:_act("setup") end); at(t + 10, function() shoot("setmode_plus2") end); t = t + 20
at(t, function() Wt.getInstance():_act("set") end); at(t + 5, function() Wt.getInstance():_act("alarm") end); at(t + 15, function() shoot("alarm_armed") end); t = t + 25
at(t, function() Wt.getInstance():_act("speed") end); at(t + 10, function() shoot("speed2x") end); t = t + 20
at(t, function() Wt.getInstance():_act("speed") end); at(t + 10, function() shoot("speed3x") end); t = t + 20
at(t, function() Wt.getInstance():_act("speed") end); at(t + 10, function() shoot("speed1x") end); t = t + 20
at(t, function() Wt.getInstance():_act("start") end); at(t + 10, function() shoot("paused") end); at(t + 15, function() Wt.getInstance():_act("start") end); t = t + 30
at(t, function() wear("Expensive") end); at(t + 10, function() Wt.getInstance():_act("crown") end); at(t + 20, function() shoot("expensive_set") end); at(t + 25, function() Wt.getInstance():_act("crown") end); t = t + 35
at(t, function() stripWatches() end); at(t + 15, function() shoot("none") end); t = t + 25
at(t, function() wear("DigitalBlack"); print("ZEDQA w done") end)
local n, i = 0, 1
local ev = Events.OnTickEvenPaused or Events.OnTick
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then ev.Remove(tick) end end
ev.Add(tick)
