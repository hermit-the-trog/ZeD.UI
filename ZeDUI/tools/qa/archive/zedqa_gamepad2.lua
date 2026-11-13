-- ZeD QA v5: gamepad flow as played - controller mode first, pair closed (no focus), then enter the seat
local p = getPlayer(); local D = ZeD.Dashboard; local Focus = ZeD.Input.Focus; local Det = ZeD.Input.Detector
local car; local it = getCell():getVehicles():iterator()
while it:hasNext() do local v = it:next(); if tostring(v:getScriptName()) == "Base.SportsCar" then car = v end end
if not car then print("ZEDQA gp2 no car") return end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function focInfo(tag)
    local d = D.getInstance(); local fw = Focus.getFocusedWindow(); local el = Focus.getFocusedElement(d)
    print("ZEDQA gp2 " .. tag .. " mode=" .. tostring(Det.getMode()) .. " focusedWin=" .. tostring(fw == d) .. " el=" .. tostring(el and el.id) .. " focEl=" .. tostring(d and d._focEl and d._focEl.id) .. " lights=" .. tostring(d and d._st and d._st.lights) .. " locked=" .. tostring(d and d._st and d._st.anyLocked))
end
at(10, function() if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end; Det.setLockedMode(Det.MODE_GAMEPAD) end)
at(30, function() Focus.releaseFocus(); print("ZEDQA gp2 released, focused=" .. tostring(Focus.getFocusedWindow())) end)
at(40, function() car:enter(0, p); triggerEvent("OnEnterVehicle", p) end)
at(70, function() focInfo("entered") end)
at(80, function() Focus.dispatchJoypadDown(D.getInstance(), "A") end)
at(110, function() focInfo("after A on first"); pcall(function() getCore():TakeFullScreenshot("zedqa_gp2_cue.png") end) end)
at(120, function() Focus.dispatchJoypadDir(D.getInstance(), "right") end)
at(135, function() Focus.dispatchJoypadDir(D.getInstance(), "right") end)
at(150, function() Focus.dispatchJoypadDown(D.getInstance(), "A") end)
at(180, function() focInfo("after right right A"); pcall(function() getCore():TakeFullScreenshot("zedqa_gp2_cue2.png") end) end)
at(190, function() Focus.dispatchJoypadDown(D.getInstance(), "B") end)
at(210, function() focInfo("after B") end)
at(220, function() p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p); Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil); print("ZEDQA gp2 done mode=" .. tostring(Det.getMode())) end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
