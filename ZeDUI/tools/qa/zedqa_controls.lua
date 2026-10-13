-- ZeD QA v5: exercise dashboard controls through the organism's own _fire (what A / click do)
local p = getPlayer(); local D = ZeD.Dashboard; local d = D.getInstance(); local car = p:getVehicle()
if not d or not car then print("ZEDQA ctl: no dash/car") return end
local key = car:createVehicleKey(); if key then p:getInventory():AddItem(key) end
pcall(function() local t = car:getPartById("GasTank"); if t then t:setContainerContentAmount(t:getContainerCapacity()) end end)
local function st(tag) local s = d._st or {}; print("ZEDQA ctl " .. tag .. " keysIn=" .. tostring(s.keysIn) .. " running=" .. tostring(s.running) .. " lights=" .. tostring(s.lights) .. " locked=" .. tostring(s.anyLocked) .. " heaterOn=" .. tostring(s.heaterOn) .. " temp=" .. tostring(s.heaterTemp) .. " fan=" .. tostring(s.fan) .. " ac=" .. tostring(s.ac) .. " radio=" .. tostring(s.radioKind) .. "/" .. tostring(s.radioOn) .. " ch=" .. tostring(s.channel) .. " vol=" .. tostring(s.volume) .. " hits=" .. tostring(#(d._hit or {}))) end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
at(10, function() st("t0"); d:_fire("ignition", false) end)
at(50, function() st("after insert"); d:_fire("ignition", false) end)
for k = 1, 4 do at(50 + k * 150, function() if d._st and not d._st.running then d:_fire("ignition", false) end end) end
at(700, function() st("after start"); d:_fire("lights", false) end)
at(730, function() st("after lights"); d:_fire("lock", false) end)
at(760, function() st("after lock"); d:_fire("heat", false) end)
at(790, function() st("after heat"); d:_fire("tempup", false) end)
at(820, function() st("after temp+"); d:_fire("fanup", false) end)
at(850, function() st("after fan+"); d:_fire("ac", false) end)
at(880, function() st("after ac"); d:_fire("pwr", false) end)
at(910, function() st("after pwr"); d:_fire("seek", false) end)
at(940, function() st("after seek"); d:_fire("vol", false) end)
at(970, function() st("after vol"); d:_fire("preset1", true) end)
at(1000, function() st("after preset store"); d:_fire("tune", false) end)
at(1030, function() st("after tune"); d:_fire("preset1", false) end)
at(1060, function() st("after preset recall"); print("ZEDQA ctl done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
