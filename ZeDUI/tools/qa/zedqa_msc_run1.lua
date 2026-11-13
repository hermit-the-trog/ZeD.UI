-- ZeDUI/tools/qa/zedqa_msc_run1.lua  (Nov 12 2026, QA 177; baseline for the Maskarad's Summer Car compatibility fix)
-- Run 1: ZeD on + Summer Car (MaskaradsSummerCar). A plain car on the drag strip with its key; the game's own
-- Vehicle Mechanics (ZeD's Vehicle tab shows). Does the Summer Car engine window appear on its own, what does a
-- real right-click on the Engine row offer, what do the vehicle wheels (mouse key path and the pad's World > Vehicle
-- slice) offer outside and inside the car, the world right-click on the car, the push hotkey. Nothing is fixed here.
-- Needs release_check_mouse.ps1 running (zedqa_msc_run.ps1 starts it). grep "ZEDQA msc1"; shots zqa_msc1_*.png.
local function say(s) print("ZEDQA msc1 " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local MT = ZeD and ZeD.MechanicsTab
local D, W = ZeD and ZeD.DpadWheels, ZeD and ZeD.Wheel
if ZEDQA_HOME then ZEDQA_HOME("msc1") end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_msc1_" .. n .. ".png") end); say("shot " .. n) end
local function Wn() return ZeD_WorldWindow.getWindow() end
local function S() local w = Wn(); return w and MT and MT.getState(w) end
if getGameSpeed() <= 0 then setGameSpeed(1) end
local v, key

-- ---- sequencer: a step is fn() -> true when finished (polled each tick), with a time cap
local Q, qi, qstart, qlast = {}, 0, 0, 0
local function add(name, fn, cap) Q[#Q + 1] = { n = name, fn = fn, cap = cap or 0 } end
local function wait(ms) local t0; add("wait " .. ms, function() t0 = t0 or getTimestampMs(); return getTimestampMs() - t0 >= ms end) end
local function now() return getTimestampMs() end

-- ---- the real mouse / keyboard helper
local function req(line)
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(line); f:close() end)
end
local function reqDone()
    local r = getFileReader("zedqa_click_done.txt", false); local l = r and r:readLine(); if r then r:close() end
    return l ~= nil and l:find("done", 1, true) ~= nil
end
local function realClick(kind, x, y, nm)
    local sent = false
    add(nm or "click", function()
        if not sent then sent = true; req(kind .. " " .. math.floor(x()) .. " " .. math.floor(y())); return false end
        return reqDone()
    end, 15000)
end

-- ---- what is on the UI list
local function findMsc()
    local out, err = {}, nil
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        local t
        local ok = pcall(function() t = e:getTable() end)
        if not ok then err = "getTable failed" end
        if t and tostring(t.Type) == "MSC_EngineComponentsWindow" then out[#out + 1] = t end
    end
    return out, err
end
local function mscLine(tag)
    local ws, err = findMsc()
    if #ws == 0 then say(tag .. ": no Summer Car engine window on the UI list" .. (err and (" (" .. err .. ")") or "")); return nil end
    for _, t in ipairs(ws) do
        say(string.format("%s: Summer Car engine window at %d,%d size %dx%d visible=%s title=%s tab=%s placement=%s", tag,
            math.floor(t:getX()), math.floor(t:getY()), math.floor(t:getWidth()), math.floor(t:getHeight()), tostring(t:isReallyVisible()),
            tostring(t.title), tostring(t.activeTab), tostring(t.mechanicsPlacement)))
    end
    return ws[1]
end
local function mechLine(tag)
    local ui = getPlayerMechanicsUI and getPlayerMechanicsUI(pn)
    if not ui then say(tag .. ": no game mechanics UI object"); return end
    say(string.format("%s: game mechanics window %d,%d %dx%d reallyVisible=%s vehicle=%s msc_lastCanAccess=%s msc_userDismissed=%s", tag,
        math.floor(ui:getX()), math.floor(ui:getY()), math.floor(ui:getWidth()), math.floor(ui:getHeight()), tostring(ui:isReallyVisible()),
        tostring(ui.vehicle ~= nil), tostring(ui.msc_lastCanAccess), tostring(ui.msc_userDismissed)))
end
local function closeMsc()
    for _, t in ipairs((findMsc())) do pcall(function() t:close(false) end) end
end

-- ---- wheel helpers
local function sliceList(m)
    local parts = {}
    for i, s in ipairs(m.slices or {}) do
        local t = tostring(s.text or "(place)"):gsub("\n", " / ")
        parts[#parts + 1] = i .. ":" .. t .. ((W and W.isOff and W.isOff(s)) and " [off]" or "")
    end
    return #(m.slices or {}), table.concat(parts, "  ")
end
local function closeWheels()
    pcall(function()
        local st = D and D.state[pn]
        if st and st.menu and st.menu.undisplay then st.menu:undisplay() end
        if D then D.state[pn] = nil end
        for _, m in ipairs({ getPlayerRadialMenu(pn), getPlayerBackButtonWheel(pn) }) do
            if m and m:isReallyVisible() then m:undisplay() end
        end
    end)
end
local function mouseWheel(tag, snap)
    closeWheels()
    local kcode = getCore():getKey(KeybindId.VEHICLE_RADIAL_MENU)
    pcall(function() ISVehicleMenu.showRadialMenu(p) end)   -- (what the V key handler calls)
    add(tag .. " settle", (function() local t0; return function() t0 = t0 or now(); return now() - t0 > 700 end end)())
    add(tag .. " list", function()
        local m = getPlayerRadialMenu(pn)
        local n, txt = sliceList(m)
        say(string.format("%s (the V key path, ZeD's wheel): visible=%s, %d slices | %s", tag, tostring(m:isReallyVisible()), n, txt))
        shot(snap)
        return true
    end)
    wait(300)
    add(tag .. " close", function() closeWheels(); return true end)
end
local function padWheel(tag, snap)
    local entries
    add(tag .. " open", function()
        closeWheels()
        ISDPadWheels.onDisplayRight({ player = pn, id = nil })
        return true
    end)
    wait(600)
    add(tag .. " enter Vehicle", function()
        local st = D.state[pn]
        local e
        for _, x in ipairs(st and st.path[1].entries or {}) do
            if tostring(x.name):find(ZeD.tr("UI_ZeD_Wheel_Vehicle"), 1, true) then e = x end
        end
        if not e then say(tag .. ": no Vehicle slice in the World wheel"); return true end
        say(tag .. ": World wheel's Vehicle slice off=" .. tostring(e.off))
        if e.off then return true end
        pcall(D.enter, pn, e)
        return true
    end)
    wait(900)
    add(tag .. " list", function()
        local st = D.state[pn]
        local m = st and st.menu
        if not m then say(tag .. ": no wheel"); return true end
        local n, txt = sliceList(m)
        say(string.format("%s (the pad's World > Vehicle wheel through ZeD): visible=%s, %d slices | %s", tag, tostring(m:isReallyVisible()), n, txt))
        shot(snap)
        return true
    end)
    wait(300)
    add(tag .. " close", function() closeWheels(); return true end)
end

local function ctxNames(menu, depth)
    local out = {}
    local ok, items = pcall(function() return menu:_currentItems() end)
    if not ok or not items then return out end
    for _, it in ipairs(items) do
        local dis = false
        pcall(function() dis = it.disabled and it.disabled() or false end)
        out[#out + 1] = string.rep("> ", depth or 0) .. tostring(it.name) .. (dis and " [greyed]" or "") .. (it.category and (" (" .. tostring(it.category) .. ")") or "")
    end
    return out
end
local function zedCtxLine(tag)
    local zm = getPlayerContextMenu and getPlayerContextMenu(pn)
    local m = zm and zm._zedMenu
    if not m then say(tag .. ": ZeD's context menu is not up (vanilla menu visible " .. tostring(zm and zm:isReallyVisible()) .. ")"); return end
    local names = ctxNames(m, 0)
    say(tag .. " (" .. #names .. " cells): " .. table.concat(names, " | "))
end
local function closeCtx()
    pcall(function() local zm = getPlayerContextMenu(pn); if zm and zm._zedMenu and zm._zedMenu.close then zm._zedMenu:close() end end)
    pcall(function() getPlayerContextMenu(pn):setVisible(false) end)
end
if not (MT and D and W) then say("ERR ZeD's Vehicle tab or wheels are not loaded"); say("DONE"); return end

-- ================= setup
add("spawn", function()
    local sqs = { { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 }, { 5, 3 } }
    for _, o in ipairs(sqs) do
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], 0)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free and not v then v = addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq) end
    end
    if not v then say("ERR no free square for the car"); return true end
    pcall(function() key = p:getInventory():AddItem(v:createVehicleKey()) end)
    say("car " .. tostring(v:getScriptName()) .. " at " .. math.floor(v:getX()) .. "," .. math.floor(v:getY()))
    return true
end)
wait(5000)
add("mod state", function()
    if not v then return true end
    say("MSC loaded: " .. tostring(MSC ~= nil) .. " | EngineComponents " .. tostring(MSC and MSC.EngineComponents ~= nil) .. " | VehiclePush " .. tostring(MSC and MSC.VehiclePush ~= nil) .. " | AnimalTowClient " .. tostring(MSC and MSC.AnimalTowClient ~= nil))
    local C = MSC and MSC.EngineComponents
    pcall(function() say("initialized=" .. tostring(C.isInitialized(v)) .. " hoodOpen=" .. tostring(C.isHoodOpen(v)) .. " canAccessEngine=" .. tostring(C.canAccessEngine(v))) end)
    pcall(function() say("ECU installed (as spawned) = " .. tostring(MSC.VehicleDiagnosticsAccess.isEcuInstalled(v))) end)
    return true
end)
add("windows", function()
    if not ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    return true
end)
wait(1500)
add("tab", function() pcall(ZeD_WorldWindow.openTab, 0, "vehicle"); return true end)
wait(2000)
add("before hood", function()
    mscLine("before the hood"); mechLine("before the hood")
    shot("1_before_hood")
    ISVehicleMenu.onMechanic(p, v)
    say("onMechanic called")
    return true
end)
-- watch the Vehicle tab open and sample the Summer Car window every tick for 14 s after it
local watch0, seenFirst, seenLast, seenCount, ticks, hoodAt
add("watch", function()
    watch0 = watch0 or now()
    ticks = (ticks or 0) + 1
    local ws = findMsc()
    if #ws > 0 then
        seenCount = (seenCount or 0) + 1
        seenFirst = seenFirst or (now() - watch0); seenLast = now() - watch0
    end
    local hood = v:getPartById("EngineDoor")
    local open = hood and hood:getDoor() and hood:getDoor():isOpen()
    if open and not hoodAt then hoodAt = now() - watch0; say("hood open after " .. hoodAt .. " ms; canAccessEngine=" .. tostring(MSC.EngineComponents.canAccessEngine(v)) .. " tab inspected=" .. tostring(MT.isInspected(v))) end
    if hoodAt and now() - watch0 > hoodAt + 8000 then return true end
    if now() - watch0 > 70000 then say("ERR the hood never opened (70 s)"); return true end
    return false
end)
add("after watch", function()
    say(string.format("Summer Car window seen on %s of %d ticks; first at %s ms, last at %s ms into the watch", tostring(seenCount or 0), ticks or 0, tostring(seenFirst), tostring(seenLast)))
    mscLine("after the hood is open"); mechLine("after the hood is open")
    local w = Wn(); local s = S()
    say("World window tab " .. tostring(w and w._activeTab) .. " | vehicle tab inspected " .. tostring(MT.isInspected(v)) .. (w and (" | World window " .. math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight())) or ""))
    return true
end)
wait(800)
add("shot tab", function() shot("2_vehicle_tab_hood_open"); return true end)

-- ================= right-click Engine in ZeD's Vehicle tab (real mouse)
local engRow
add("find engine row", function()
    local s = S()
    if not s then say("ERR no Vehicle tab state"); return true end
    local ids = {}
    for _, z in ipairs(s.zones or {}) do ids[#ids + 1] = z.id end
    say("tab zones: " .. table.concat(ids, ", "))
    for _, r in ipairs(s.lastRows or {}) do
        if r.part == "Engine" then engRow = r end
    end
    say("engine row found: " .. tostring(engRow ~= nil))
    return true
end)
realClick("right", function()
    local s = S()
    if not (engRow and s and s.panel) then return 100 end
    return s.panel:getAbsoluteX() + engRow.x + math.min(engRow.w / 2, 200)
end, function()
    local s = S()
    if not (engRow and s and s.panel) then return 100 end
    return s.panel:getAbsoluteY() + engRow.y + engRow.h / 2
end, "right-click Engine row")
-- (realClick takes x and y as functions; the second function is the y)
wait(900)
add("engine menu", function()
    zedCtxLine("ZeD context menu for the Engine row")
    local ui = getPlayerMechanicsUI(pn)
    local vn = {}
    if ui and ui.context then for _, o in ipairs(ui.context.options or {}) do vn[#vn + 1] = tostring(o.name) .. (o.notAvailable and " [greyed]" or "") end end
    say("the game's own part menu object holds: " .. table.concat(vn, ", "))
    shot("3_engine_right_click")
    return true
end)
-- run the "Inspect engine components" option as pressed
add("press Inspect", function()
    local ui = getPlayerMechanicsUI(pn)
    local want = getText("UI_MSC_InspectEngineComponents")
    local opt
    if ui and ui.context then for _, o in ipairs(ui.context.options or {}) do if tostring(o.name) == want then opt = o end end end
    if not opt then say("the Inspect engine components option is not in the menu"); return true end
    local ok, e = pcall(function() opt.onSelect(opt.target, opt.param1, opt.param2, opt.param3) end)
    say("Inspect engine components pressed: ok=" .. tostring(ok) .. (ok and "" or (" " .. tostring(e))))
    return true
end)
wait(1500)
add("after inspect", function() mscLine("after Inspect engine components"); mechLine("after Inspect"); shot("4_after_inspect"); return true end)
wait(5000)
add("still there", function() mscLine("5 s later"); shot("5_inspect_5s_later"); return true end)
add("close msc", function() closeMsc(); closeCtx(); return true end)
wait(800)

-- ================= the world right-click on the car (real mouse) and the push key, outside
add("stage outside", function()
    -- the character beside the car, the hood left as it is; a clear stance
    local vx, vy = v:getX(), v:getY()
    pcall(function() p:setPerkLevelDebug(Perks.Strength, 5) end)
    local found
    for _, o in ipairs({ { 0, 2.3 }, { 0, -2.3 }, { 2.3, 0 }, { -2.3, 0 }, { 0, 2.0 }, { 0, -2.0 }, { 0, 2.8 }, { 0, -2.8 } }) do
        if not found then
            p:setX(vx + o[1]); p:setY(vy + o[2]); p:setLastX(vx + o[1]); p:setLastY(vy + o[2])
            local ok, valid, why = pcall(MSC.VehiclePush.validate, p, v)
            local near = nil
            pcall(function() near = ISVehicleMenu.getVehicleToInteractWith(p) end)
            say(string.format("standing at car%+.1f,%+.1f: Push.validate valid=%s reason=%s | game finds the car to interact with: %s", o[1], o[2], tostring(valid), tostring(why), tostring(near == v)))
            if ok and valid and near == v then found = true end
        end
    end
    say("push position found: " .. tostring(found))
    pcall(function() if ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
    return true
end)
wait(1500)
mouseWheel("outside wheel", "6_outside_wheel_v_key")
padWheel("outside pad wheel", "7_outside_pad_vehicle")
local carX, carY
add("car screen pos", function()
    local x = ISCoordConversion.ToScreen(v:getX(), v:getY(), 0)
    local _, y = ISCoordConversion.ToScreen(v:getX(), v:getY(), 0)
    carX, carY = x, y
    local zoom = getCore():getZoom(pn)
    local ox, oy = 0, 0
    pcall(function() ox = getPlayerScreenLeft(pn); oy = getPlayerScreenTop(pn) end)
    carX, carY = carX + ox, carY + oy
    say("the car on the screen at " .. math.floor(carX) .. "," .. math.floor(carY) .. " (zoom " .. tostring(zoom) .. ")")
    return true
end)
realClick("right", function() return carX or 1920 end, function() return carY or 1080 end, "right-click the car")
wait(900)
add("world menu", function()
    zedCtxLine("ZeD world context menu on the car")

    shot("8_world_menu_on_car")
    return true
end)
add("close world menu", function() closeCtx(); return true end)
wait(600)

-- ---- the push hotkey: bind K, press the real key, watch whether the car or the character react
local push0, bound
add("bind push key", function()
    local ok, e = pcall(function() getCore():addKeyBinding("MSC_VehiclePushHotkey", 37, 0, false, false, false) end)
    bound = ok and getCore():getKey("MSC_VehiclePushHotkey") or nil
    say("push hotkey bound to K: addKeyBinding ok=" .. tostring(ok) .. (ok and "" or (" " .. tostring(e))) .. " | key now " .. tostring(bound))
    pcall(function()
        local valid, err = MSC.VehiclePush.validate(p, v)
        say("Push.validate: valid=" .. tostring(valid) .. " reason=" .. tostring(err))
    end)
    pcall(function() push0 = { x = v:getX(), y = v:getY(), speed = v:getCurrentAbsoluteSpeedKmHour() } end)
    return true
end)
local keyHook = 0
add("hook", function()
    local f = function(k) if k == 37 then keyHook = keyHook + 1 end end
    Events.OnKeyPressed.Add(f); Events.OnKeyStartPressed.Add(f); return true
end)
local keySent
add("press K", function()
    if not keySent then keySent = true; req("keydown 75 37"); return false end
    if not reqDone() then return false end
    return true
end, 15000)
wait(400)
add("release K", function() req("keyup 75 37"); return true end)
wait(700)
add("after K", function() say("OnKeyPressed saw K " .. keyHook .. " time(s) (the engine delivered the real key to the Lua events)"); return true end)
wait(3500)
add("push result", function()
    local moved = push0 and math.sqrt((v:getX() - push0.x) ^ 2 + (v:getY() - push0.y) ^ 2) or -1
    say(string.format("push result: the car moved %.2f squares, speed now %.2f km/h; the character shoving: %s", moved, v:getCurrentAbsoluteSpeedKmHour(), tostring(p:getVariableBoolean("isShoving") or p:isShoving())))
    shot("9_after_push_key")
    return true
end)

-- ================= inside the car
add("enter car", function()
    pcall(function() local x, y = v:getX(), v:getY(); p:setX(x); p:setY(y) end)
    ISVehicleMenu.onEnter(p, v, 0)
    return true
end)
add("wait seated", function() return p:getVehicle() == v end, 25000)
wait(1500)
add("seated", function()
    say("seated=" .. tostring(p:getVehicle() == v))
    pcall(function() say("ECU installed (as spawned) = " .. tostring(MSC.VehicleDiagnosticsAccess.isEcuInstalled(v)) .. " initialized " .. tostring(MSC.EngineComponents.isInitialized(v))) end)
    return true
end)
mouseWheel("inside wheel (no ECU yet)", "10_inside_wheel_v_key")
padWheel("inside pad wheel (no ECU yet)", "11_inside_pad_vehicle")
add("force ECU", function()
    local d = v:getModData()
    d.MSC = d.MSC or {}; d.MSC.diagnostics = d.MSC.diagnostics or {}
    local was = d.MSC.diagnostics.ecuInstalled
    d.MSC.diagnostics.ecuInstalled = true
    say("ECU forced on by vehicle mod data (was " .. tostring(was) .. "): this is staging, the server would set it")
    return true
end)
mouseWheel("inside wheel (ECU forced)", "12_inside_wheel_ecu_v_key")
padWheel("inside pad wheel (ECU forced)", "13_inside_pad_vehicle_ecu")
-- press the ECU slice (the mouse path), then watch whether the window opens and stays
local ecuSlice
add("open wheel for ECU", function()
    closeWheels()
    pcall(function() ISVehicleMenu.showRadialMenu(p) end)
    return true
end)
wait(700)
add("press ECU slice", function()
    local m = getPlayerRadialMenu(pn)
    local want = getText("UI_MSC_OpenEcuDiagnostics")
    for i, s in ipairs(m.slices or {}) do if tostring(s.text) == want then ecuSlice = i end end
    if not ecuSlice then say("no ECU diagnostics slice in the wheel to press"); closeWheels(); return true end
    local s = m.slices[ecuSlice]
    local ok, e = pcall(function() s.command[1](s.command[2], s.command[3], s.command[4]) end)
    say("ECU slice pressed (slice " .. ecuSlice .. "): ok=" .. tostring(ok) .. (ok and "" or (" " .. tostring(e))))
    closeWheels()
    return true
end)
wait(1200)
add("ecu window", function() mscLine("after the ECU slice"); shot("14_ecu_window"); return true end)
wait(5000)
add("ecu window later", function() mscLine("5 s after the ECU slice"); shot("15_ecu_window_5s"); return true end)
add("close ecu", function() closeMsc(); return true end)

-- ================= put back
add("put back", function()
    closeWheels()
    pcall(function() if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end end)
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() if v then v:permanentlyRemove() end end)
    pcall(function() if key then p:getInventory():Remove(key) end end)
    pcall(function() getCore():addKeyBinding("MSC_VehiclePushHotkey", 0, 0, false, false, false) end)
    pcall(function() if ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
    say("put back: car and key removed, push key unbound")
    return true
end)
wait(500)
add("done", function() say("DONE"); return true end)

-- ================= run
local function tick()
    if qi == 0 then qi = 1; qstart = now() end
    local st = Q[qi]
    if not st then Events.OnTick.Remove(tick); return end
    local ok, r = pcall(st.fn)
    if not ok then say("ERR step '" .. st.n .. "': " .. tostring(r)); r = true end
    if not r and st.cap > 0 and now() - qstart > st.cap then say("ERR step '" .. st.n .. "' timed out"); r = true end
    if r then qi = qi + 1; qstart = now() end
end
Events.OnTick.Add(tick)
say("start (" .. #Q .. " steps)")
