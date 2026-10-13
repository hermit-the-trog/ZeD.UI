-- ZeD QA v5: tour every design in the cell, radio + heater on, screenshot each
local p = getPlayer(); local D = ZeD.Dashboard
local list = { "CarNormal", "CarLightsMuldraughPolice", "CarLuxury", "SportsCar", "PickUpTruck", "CarStationWagon2", "CarTaxi2", "VanAmbulance", "SmallCar", "SUVBurnt" }
local by = {}; local it = getCell():getVehicles():iterator(); while it:hasNext() do local v = it:next(); local sn = tostring(v:getScriptName()):gsub("^Base%.", ""); if not by[sn] then by[sn] = v end end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local t = 10
for _, sn in ipairs(list) do
    local name = sn
    at(t, function() local cur = p:getVehicle(); if cur then cur:exit(p); triggerEvent("OnExitVehicle", p) end end)
    at(t + 10, function() local v = by[name]; if v then v:enter(0, p); triggerEvent("OnEnterVehicle", p) else print("ZEDQA tour missing " .. name) end end)
    at(t + 25, function()
        local d = D.getInstance(); if not (d and d._st) then return end
        if not d._st.radioOn then d:_fire("pwr", false) end
        if not d._st.heaterOn then d:_fire("heat", false) end
        if name:find("Police") or name:find("Ambulance") then d:_fire("lbar", false); d:_fire("siren", false) end
    end)
    at(t + 55, function()
        local d = D.getInstance()
        pcall(function() getCore():TakeFullScreenshot("zedqa_tour_" .. name .. ".png") end)
        print("ZEDQA tour " .. name .. " design=" .. tostring(d and d._designId) .. " visible=" .. tostring(d and d:isVisible()) .. " hits=" .. tostring(d and #(d._hit or {})) .. " badge=" .. tostring(d and d._badgeLabel) .. "/" .. tostring(d and d._badgeSub) .. " cluster=" .. tostring(d and d._clusterBrand) .. " st.radio=" .. tostring(d and d._st and d._st.radioOn) .. " heat=" .. tostring(d and d._st and d._st.heaterOn) .. " fan=" .. tostring(d and d._st and d._st.fan))
    end)
    t = t + 70
end
at(t, function() print("ZEDQA tour done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
