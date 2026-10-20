-- ZeDUI/tools/qa/zedqa_car_radio_build.lua  (Oct 15 2026)
-- The car radio up close (ZeD_CarRadio) and the dash's matching radio face, live
-- on the ZeD-QA save: opens it through vanilla's entry point (the wheel's Device
-- Options, ISVehicleMenu.onSignalDevice), checks vanilla's window stays shut,
-- drives it through ZeD_RadioOps (vanilla's radio code) and captures each face:
-- the pickup with each FM radio fitted (premium, ValuTech, makeshift) and the
-- sheriff car with each two-way set (ham, army, makeshift ham). The cars get
-- their own radios back at the end. Copy to Zomboid/Lua/zedqa.lua, bump
-- zedqa.go; grep console.txt for "ZEDQA rb".

local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA rb " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rb_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local RO, CR = ZeD.RadioOps, ZeD.CarRadio
local pickup, police
local orig = {}
local function near(pred, maxD)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if pred(v) then local d = v:DistTo(p); if d < maxD and (not bd or d < bd) then best, bd = v, d end end
    end
    return best
end
-- cars spawned beside the character when the QA save's own are not loaded near it (the character is left wherever
-- the last run ended); removed at the end
local spawned = {}
local dead = false
local finalAt = nil
-- (an abort skips the other steps and jumps the tick counter to just before the final one)
local function abort(msg) say("ERR " .. msg); dead = true; if finalAt then tick = finalAt - 2 end end
local function final(n, fn) finalAt = n; steps[#steps + 1] = { n = n, fn = fn, final = true } end   -- runs even after an abort
local function spawn(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then say("no square for " .. script); return nil end
    local ok, v = pcall(addVehicleDebug, script, IsoDirections.N, nil, sq)
    if ok and v then spawned[#spawned + 1] = v; say("spawned " .. script .. " beside the character"); return v end
    return nil
end
local function radioPart(v) return v and v:getPartById("Radio") end
local function enter(v)
    if not v then say("no vehicle"); return end
    if v:DistTo(p) > 12 then say("too far " .. v:DistTo(p)); return end
    v:enter(0, p); triggerEvent("OnEnterVehicle", p)
end
local function leave() local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end end
local function prop() return CR.props[pn] end
local function vanillaUp()
    for _, t in ipairs({ ISRadioWindow.instances, ISRadioWindow.instancesIso }) do
        local w = t and t[pn]; if w and w:isVisible() then return true end
    end
    return false
end
local function report(tag)
    local part = radioPart(p:getVehicle())
    local st = part and RO.read(part)
    local pr = prop()
    if not st then say(tag .. " no radio"); return end
    local pre = {}
    for i, q in ipairs(st.presets) do pre[#pre + 1] = i .. "=" .. string.format("%.1f", q.freq / 1000) .. " " .. q.name end
    say(string.format("%s kind=%s item=%s on=%s switch=%s powered=%s ch=%s vol=%s preset=%s name=%s signal=%s media=%s playing=%s title=%s flash=%s mic=%s",
        tag, st.kind, st.item:getFullType(), tostring(st.on), tostring(st.switchOn), tostring(st.powered), tostring(st.channel), tostring(st.volume),
        tostring(st.presetIdx), tostring(st.name), tostring(st.signal), tostring(st.hasMedia), tostring(st.playing), tostring(st.mediaTitle), tostring(st.flash), tostring(st.micMuted)))
    say("   presets [" .. table.concat(pre, "; ") .. "]")
    say(string.format("   prop visible=%s at %s,%s %sx%s  vanilla window=%s", tostring(pr and pr:isReallyVisible()), tostring(pr and pr:getX()), tostring(pr and pr:getY()),
        tostring(pr and pr:getWidth()), tostring(pr and pr:getHeight()), tostring(vanillaUp())))
end
-- vanilla's install of a radio item into the part (the mechanics window's), presets made if it has none
local function fit(v, ft)
    local part = radioPart(v); if not part then say("no radio part"); return end
    local ok, e = pcall(function()
        part:setInventoryItem(instanceItem(ft))
        Vehicles.InstallComplete.Radio(v, part)
        local dd = part:getDeviceData()
        if dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
        if dd:getIsTwoWay() then pcall(function() dd:addEmergencyChannel() end) end
    end)
    say("fit " .. ft .. " ok=" .. tostring(ok) .. " " .. tostring(e))
end
local function powerOn(tag)
    local part = radioPart(p:getVehicle()); if not part then return end
    local dd = part:getDeviceData()
    if dd:getIsTurnedOn() then return end
    local ok = RO.power(p, part)
    say(tag .. " power via vanilla's action ok=" .. tostring(ok) .. " canBePoweredHere=" .. tostring(dd:canBePoweredHere()) .. " battery=" .. tostring(p:getVehicle():getBatteryCharge()))
    if not dd:getIsTurnedOn() then dd:setIsTurnedOn(true); say(tag .. " FALLBACK switched on directly") end
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    local clim = getClimateManager()
    for i = 0, clim:getFloatMax() - 1 do
        local v = clim:getClimateFloat(i); local n = tostring(v:getName()):lower()
        if n:find("fog") or n:find("precip") or n:find("cloud") then v:setEnableAdmin(true); v:setAdminValue(0) end
    end
    -- the QA save's own cars when they are loaded near the character; else ones spawned beside it (removed at the end)
    pickup = near(function(v) return v:getScriptName() == "Base.PickUpTruck" end, 25)
    police = near(function(v) return v:hasLightbar() end, 25)
    if not pickup then pickup = spawn("Base.PickUpTruck", -4, 0) end
    if not police then police = spawn("Base.CarLightsPolice", 4, 0) end
    if not (pickup and police) then abort("no " .. (pickup and "police car with a lightbar" or "pickup") .. " within 25 tiles and the spawn failed"); return end
end)
at(10, function()
    for _, v in ipairs({ pickup, police }) do
        local part = radioPart(v)
        local item = part and part:getInventoryItem()
        say(tostring(v and v:getScriptName()) .. " radio=" .. tostring(item and item:getFullType()))
        if v then orig[v] = item and item:getFullType() or nil end
    end
    if pickup and not orig[pickup] then fit(pickup, "Base.RadioRed"); orig[pickup] = "Base.RadioRed" end
    if police and not orig[police] then fit(police, "Base.HamRadio1"); orig[police] = "Base.HamRadio1" end
end)

-- 1. the pickup: Premium Technologies (CD)
at(30, function() enter(pickup) end)
at(70, function() shot("d01_pickup_dash"); report("dash only") end)
at(75, function() local part = radioPart(pickup); if part then ISVehicleMenu.onSignalDevice(p, part) end end)
at(95, function() report("premium off"); shot("r01_premium_off") end)
at(100, function() powerOn("premium") end)
at(105, function()
    local part = radioPart(pickup)
    RO.setChannel(p, part, 101200)
    RO.run("SetVolume", p, part, 0.6)
end)
at(135, function() report("premium on"); shot("r02_premium_on") end)
at(140, function() local part = radioPart(pickup); say("store 4 -> " .. tostring(RO.store(p, part, 4))) end)
at(150, function() report("premium stored"); shot("r03_premium_store") end)
at(160, function() CR.qaPoint = "tune" end)
at(170, function() shot("r04_premium_hover_tune"); CR.qaPoint = nil end)
at(175, function()
    local part = radioPart(pickup)
    local cd = p:getInventory():AddItem("Base.Disc_Retail")
    say("cds carried: " .. #RO.cds(p, part))
    say("insert ok=" .. tostring(RO.insert(p, part, cd)))
end)
at(260, function() local part = radioPart(pickup); report("cd in"); say("play ok=" .. tostring(RO.playStop(p, part))) end)
at(400, function() report("cd playing"); shot("r05_premium_cd") end)
at(405, function() CR.qaJoy = {}; local pr = prop(); if pr then pr.focusId = "p5" end end)
at(415, function() shot("r06_premium_controller"); CR.qaJoy = nil end)
at(420, function() local part = radioPart(pickup); RO.playStop(p, part); say("eject ok=" .. tostring(RO.eject(p, part))) end)
at(500, function() report("ejected"); local pr = prop(); if pr then pr:cdList() end end)
at(515, function() shot("r07_premium_cdlist") end)
at(520, function() local ctx = getPlayerContextMenu(pn); if ctx and ctx:isVisible() then ctx:closeAll() end end)
-- 2. the pickup with a ValuTech, then a makeshift radio
at(530, function() fit(pickup, "Base.RadioBlack") end)
at(540, function() powerOn("valutech"); local part = radioPart(pickup); RO.setChannel(p, part, 98000) end)
at(570, function() report("valutech"); shot("r08_valutech") end)
at(575, function() fit(pickup, "Base.RadioMakeShift") end)
at(585, function() powerOn("makeshift"); local part = radioPart(pickup); RO.setChannel(p, part, 89400) end)
at(615, function() report("makeshift"); shot("r09_makeshift") end)
at(620, function() fit(pickup, orig[pickup] or "Base.RadioRed"); local part = radioPart(pickup); part:getDeviceData():setIsTurnedOn(false); CR.closeFor(pn) end)
at(630, function() report("pickup restored"); leave() end)
-- 3. the sheriff car: the two-way sets
at(660, function() enter(police) end)
at(700, function() local part = radioPart(police); if part then ISVehicleMenu.onSignalDevice(p, part) end end)
at(710, function() powerOn("ham"); local part = radioPart(police); RO.setChannel(p, part, 98400) end)
at(745, function() report("ham"); shot("r10_ham") end)
at(750, function() local part = radioPart(police); RO.mic(p, part); CR.qaJoy = {}; local pr = prop(); if pr then pr.focusId = "mic" end end)
at(780, function() report("ham mic off"); shot("r11_ham_mic_off"); CR.qaJoy = nil end)
at(785, function() local part = radioPart(police); RO.mic(p, part); RO.setChannel(p, part, 146600); say("mem -> " .. tostring(RO.memAdd(p, part))) end)
at(800, function() report("ham mem"); shot("r12_ham_mem") end)
at(805, function()
    -- the siren controller takes the radio's place (one prop up close at a time)
    ZeD.Siren.toggle(p)
    local pr = prop()
    say("siren opened; radio still up = " .. tostring(pr and pr:isReallyVisible()))
end)
at(815, function() ZeD.Siren.takeEscape(); local part = radioPart(police); ISVehicleMenu.onSignalDevice(p, part) end)
at(825, function() fit(police, "Base.HamRadio2") end)
at(835, function() powerOn("army"); local part = radioPart(police); RO.setChannel(p, part, 98400) end)
at(865, function() report("army"); shot("r13_army") end)
at(870, function() fit(police, "Base.HamRadioMakeShift") end)
at(880, function() powerOn("hammake"); local part = radioPart(police); RO.setChannel(p, part, 98000) end)
at(910, function() report("hammake"); shot("r14_hammake") end)
at(915, function()
    fit(police, orig[police] or "Base.HamRadio1")
    local part = radioPart(police)
    -- forget the QA's MEM channel; switch off
    local l = part:getDeviceData():getDevicePresets():getPresets()
    for i = l:size() - 1, 0, -1 do if l:get(i):getFrequency() == 146600 then l:remove(l:get(i)) end end
    part:getDeviceData():setIsTurnedOn(false)
    CR.takeEscape()
end)
at(925, function() report("police restored"); leave() end)
final(940, function()
    leave()
    CR.takeEscape()
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    spawned = {}
    say("DONE" .. (dead and " (aborted)" or ""))
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick and (s.final or not dead) then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 960 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
