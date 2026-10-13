-- ZeD QA v5: tour #3 - spawn the remaining designs on a square beside the player
local p = getPlayer(); local D = ZeD.Dashboard
local spawnList = { "Base.SmallCar02", "Base.ModernCar", "Base.ModernCar02", "Base.SUV", "Base.Van", "Base.PickUpVan", "Base.OffRoad" }
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function shoot(tag)
    local d = D.getInstance()
    pcall(function() getCore():TakeFullScreenshot("zedqa_t3_" .. tag .. ".png") end)
    print("ZEDQA t3 " .. tag .. " design=" .. tostring(d and d._designId) .. " visible=" .. tostring(d and d:isVisible()) .. " hits=" .. tostring(d and #(d._hit or {})) .. " badge=" .. tostring(d and d._badgeLabel) .. "/" .. tostring(d and d._badgeSub) .. " cluster=" .. tostring(d and d._clusterBrand))
end
local function prep() local d = D.getInstance(); if not (d and d._st) then return end; if not d._st.radioOn then d:_fire("pwr", false) end; if not d._st.heaterOn then d:_fire("heat", false) end end
local t = 10
at(t, function() local cur = p:getVehicle(); if cur then cur:exit(p); triggerEvent("OnExitVehicle", p) end end)
t = t + 20
local cur = nil
for _, sc in ipairs(spawnList) do
    local script = sc; local tag = sc:gsub("^Base%.", "")
    at(t, function()
        local sq = getCell():getGridSquare(math.floor(p:getX()) + 5, math.floor(p:getY()) + 2, math.floor(p:getZ()))
        local v = sq and addVehicleDebug(script, IsoDirections.N, nil, sq) or nil
        cur = v
        if v then v:enter(0, p); triggerEvent("OnEnterVehicle", p) else print("ZEDQA t3 spawn failed " .. script .. " sq=" .. tostring(sq)) end
    end)
    at(t + 20, prep)
    at(t + 50, function() shoot(tag) end)
    at(t + 60, function() if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end; if cur then pcall(function() cur:permanentlyRemove() end) end; cur = nil end)
    t = t + 80
end
at(t, function() print("ZEDQA t3 done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
