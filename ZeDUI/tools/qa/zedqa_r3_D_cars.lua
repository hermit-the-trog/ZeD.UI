-- ZeDUI/tools/qa/zedqa_r3_D_cars.lua  (Oct 26 2026, compatibility round 3, group D)
-- zedqa_compat_vehicles.lua (round 2) for group D's vehicle packs, at the Irvington Speedway's drag strip
-- (open ground, director Oct 24 2026), with a vanilla CarNormal first for the dashboard / mechanics mods.
-- Each car: spawned, driver's seat, key, engine; ZeD's dashboard design and place; a census of the visible UI
-- (another dashboard or the game's mechanics window over ZeD's); the World window's Vehicle tab; a picture of
-- each. The character goes back home at the end. grep "ZEDQA cv".
CV_LIST = {
    { wid = "vanilla", script = "Base.CarNormal" },
    { wid = "2791656602", script = "Base.fhqH1" },
    { wid = "2791656602", script = "Base.fhqAZ1" },
    { wid = "2843855721", script = "Base.U1550L" },
    { wid = "2843855721", script = "Base.U1550LOffRoad" },
    { wid = "3404737883", script = "Base.AMC_quad" },
    { wid = "3404737883", script = "Base.AMC_harley" },
    { wid = "3402493701", script = "Base.TrailerHome" },
    { wid = "3402493701", script = "Base.TrailerKbac" },
    { wid = "3402812859", script = "Base.ATAArmyBus" },
    { wid = "3402812859", script = "Base.ATAPrisonBus" },
    { wid = "3409723807", script = "Base.UH1BHuey" },
    { wid = "3683878228", script = "Base.fr_gr_llv_89" },
    { wid = "3683878228", script = "Base.fr_po_gto_65" },
    { wid = "3775809123", script = "Base.DashRoamer" },
    { wid = "3775809123", script = "Base.DashRoamerStellarCommand" },
    { wid = "3409472393", script = "Base.SemiTruck" },
    { wid = "3409472393", script = "Base.SemiTruckBox" },
    { wid = "3554424111", script = "Base.M998_Humvee" },
}

local pmdHome = getPlayer():getModData()
local HOME = { x = getPlayer():getX(), y = getPlayer():getY(), z = getPlayer():getZ() }
local SITE = { x = 925, y = 13040 }
local function tp(x, y, z)
    local q = getPlayer()
    q:teleportTo(x, y, z or 0)
    pcall(function() q:setX(x); q:setY(y); q:setZ(z or 0); q:setLastX(x); q:setLastY(y); q:setLastZ(z or 0) end)
end
local function censusLine(label)
    local ui = UIManager.getUI(); local parts = {}
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:isVisible() then local t = e:getTable(); parts[#parts + 1] = tostring(t and (t.Type or t.type) or e:getClass():getSimpleName()) .. "@" .. math.floor(e:getX()) .. "," .. math.floor(e:getY()) .. "," .. math.floor(e:getWidth()) .. "x" .. math.floor(e:getHeight()) end end
    print("ZEDQA cv ui " .. label .. ": " .. table.concat(parts, " ; "))
end
local p = getPlayer()
local pn = p:getPlayerNum()
local D = ZeD.Dashboard
local MAX_PER_ITEM, SHOTS = 2, 40
local function say(s) print("ZEDQA cv " .. tostring(s)) end
local fails, checked = 0, 0
local function check(ok, what) checked = checked + 1; if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
if getGameSpeed() == 0 then setGameSpeed(1) end

-- the modded vehicle scripts, grouped by Workshop item
local list, perItem = {}, {}
-- (compat_vehicles_list.lua, run first, names them from the mods' own script files: the game keeps no
-- path for a vehicle script, so the scan below finds none on 42.21)
if CV_ONLY then CV_LIST = CV_ONLY end
if CV_LIST then
    for _, e in ipairs(CV_LIST) do
        perItem[e.wid] = (perItem[e.wid] or 0) + 1
        list[#list + 1] = { wid = e.wid, script = e.script, trailer = e.script:lower():find("trailer", 1, true) ~= nil }
    end
end
if #list == 0 then
    local all = getScriptManager():getAllVehicleScripts()
    for i = 0, all:size() - 1 do
        local vs = all:get(i)
        local fn = tostring(vs:getFileName() or "")
        local wid = fn:match("108600[\\/](%d+)[\\/]")
        if wid then
            perItem[wid] = (perItem[wid] or 0) + 1
            if perItem[wid] <= MAX_PER_ITEM then
                local name = tostring(vs:getFullName())
                list[#list + 1] = { wid = wid, script = name, trailer = name:lower():find("trailer", 1, true) ~= nil }
            end
        end
    end
end
local items = 0
for _ in pairs(perItem) do items = items + 1 end
say("modded vehicle scripts: " .. #list .. " to try, from " .. items .. " Workshop items")

local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local cur, curKey = nil, nil
local function leave()
    local v = p:getVehicle()
    if v then v:exit(p); triggerEvent("OnExitVehicle", p) end
    if cur then pcall(function() cur:permanentlyRemove() end) end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
local function vehTab(on)
    local w = ZeD_WorldWindow.getWindow()
    if not w then
        if on and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
        w = ZeD_WorldWindow.getWindow()
        if not w then return nil end
    end
    local want = on and "tab:vehicle" or "tab:loot"
    for _, z in ipairs(w._actionTabStrip and w._actionTabStrip._hitZones or {}) do
        if z.id == want and w._activeTab ~= (on and "vehicle" or "loot") then w._actionTabStrip:onMouseDown(z.x + 2, z.y + 2) end
    end
    return w
end

local t = 10
at(t, leave)
at(t + 5, function() tp(SITE.x + 0.5, SITE.y + 0.5, 0) end)
t = t + 400
for n, e in ipairs(list) do
    at(t, function()
        local sq = getCell():getGridSquare(SITE.x + 4 + (n % 4) * 4, SITE.y - 8 + (n % 2) * 16, 0)
        local v = sq and addVehicleDebug(e.script, IsoDirections.N, nil, sq) or nil
        if not check(v ~= nil, e.wid .. " " .. e.script .. ": spawns") then return end
        cur = v
        pcall(function() v:repair() end)
        pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
        pcall(function()
            local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
            if it then pcall(function() it:setCurrentUsesFloat(1.0) end) end
        end)
        if e.trailer then pcall(function() tp(sq:getX() - 3 + 0.5, sq:getY() + 0.5, 0) end) end
        if not e.trailer then
            pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
            v:enter(0, p); triggerEvent("OnEnterVehicle", p)
        end
    end)
    at(t + 20, function() if cur and not e.trailer then pcall(function() cur:setKeysInIgnition(true) end) end end)
    at(t + 35, function() if cur and not e.trailer then pcall(function() ISVehicleMenu.onStartEngine(p) end) end end)
    at(t + 150, function()
        if not cur or e.trailer then return end
        local d = D.getInstance()
        local vis = d and d:getIsVisible()
        local x, y, w, h = -1, -1, -1, -1
        pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        say(string.format("%s %s: design %s, dashboard %s at %d,%d %dx%d", e.wid, e.script, tostring(d and d._designId), tostring(vis), x, y, w, h))
        check(vis and d._designId ~= nil, e.wid .. " " .. e.script .. ": the dashboard shows with a design")
        check(vis and x >= 0 and y >= 0 and x + w <= sw and y + h <= sh, e.wid .. " " .. e.script .. ": the dashboard is on screen")
        censusLine(e.script .. " seated")
        if n <= SHOTS then pcall(function() getCore():TakeFullScreenshot("zqa_r3D_cv_" .. n .. "_dash.png") end) end
    end)
    at(t + 165, function()
        local v = p:getVehicle()
        if v then v:exit(p); triggerEvent("OnExitVehicle", p) end
        vehTab(true)
    end)
    at(t + 220, function()
        local w = ZeD_WorldWindow.getWindow()
        local onTab = w and w._activeTab == "vehicle"
        local parts = 0
        pcall(function() parts = cur:getPartCount() end)
        say(string.format("%s %s: Vehicle tab %s, %d parts", e.wid, e.script, tostring(onTab), parts))
        check(onTab, e.wid .. " " .. e.script .. ": the World window's Vehicle tab opens beside it")
        censusLine(e.script .. " vehicle tab")
        if n <= SHOTS then pcall(function() getCore():TakeFullScreenshot("zqa_r3D_cv_" .. n .. "_tab.png") end) end
    end)
    at(t + 235, function() vehTab(false); leave() end)
    t = t + 255
end
at(t + 5, function() tp(HOME.x, HOME.y, HOME.z) end)
at(t + 300, function()
    say(string.format("back home %d,%d", math.floor(p:getX()), math.floor(p:getY())))
    say(string.format("%d checks, %d failed", checked, fails))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local i, n = 1, 0
local function tick()
    n = n + 1
    while steps[i] and steps[i].n <= n do
        local ok, err = pcall(steps[i].f)
        if not ok then fails = fails + 1; say("ERR step: " .. tostring(err)) end
        i = i + 1
    end
    if not steps[i] then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
say("start")
