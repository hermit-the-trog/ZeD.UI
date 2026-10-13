-- ZeD QA v5: focused element onActivate wiring (direct call, the A tap resolver is engine-driven) + hint placement
local p = getPlayer(); local D = ZeD.Dashboard; local Focus = ZeD.Input.Focus; local Det = ZeD.Input.Detector
local car; local it = getCell():getVehicles():iterator()
while it:hasNext() do local v = it:next(); if tostring(v:getScriptName()) == "Base.SportsCar" then car = v end end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function info(tag) local d = D.getInstance(); print("ZEDQA gp3 " .. tag .. " focEl=" .. tostring(d and d._focEl and d._focEl.id) .. " lights=" .. tostring(d and d._st and d._st.lights) .. " locked=" .. tostring(d and d._st and d._st.anyLocked) .. " heater=" .. tostring(d and d._st and d._st.heaterOn)) end
at(10, function() if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end; Det.setLockedMode(Det.MODE_GAMEPAD); Focus.releaseFocus() end)
at(30, function() car:enter(0, p); triggerEvent("OnEnterVehicle", p) end)
at(60, function() info("entered"); local d = D.getInstance(); local el = d._focEl; if el and el.onActivate then el.onActivate(d, el) end end)
at(90, function() info("after activate lights") end)
at(100, function() Focus.dispatchJoypadDir(D.getInstance(), "right"); end)
at(115, function() Focus.dispatchJoypadDir(D.getInstance(), "right"); end)
at(130, function() local d = D.getInstance(); local el = d._focEl; if el and el.onActivate then el.onActivate(d, el) end end)
at(160, function() info("after activate lock"); pcall(function() getCore():TakeFullScreenshot("zedqa_gp3_cue.png") end) end)
at(170, function() p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p); Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil); print("ZEDQA gp3 done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
