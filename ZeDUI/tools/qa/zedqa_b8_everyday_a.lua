-- ZeDUI/tools/qa/zedqa_b8_everyday_a.lua  (Nov 7 2026, QA; CHECK_everyday_leftovers_20261107.md B6, B7, B8, B9, and B13 item 9)
-- Four of the everyday vanilla windows that now go to ZeD, driven through the game's own entry points:
--   B6 heater: ISVehicleMenu.onToggleHeater (what the Heater key and the wheel slice call) in a spawned pickup, key in the
--      ignition: no game ISVehicleACUI, the heater part on, the dash's climate controls lit, off again on the second press,
--      nothing turns on with the key out, the game's own window when the Dashboard switch is the game's / B13.9 a kept note
--      shows on the dash and the balloon's anchor is the dash's note
--   B7 mini-map: the World wheel's Map wheel holds the World map alone; a shown game mini-map is hidden by ZeD.MiniMapOff
--   B8 Read label: ISMediaInfo.openPanel (the Read label option) opens ZeD's reader on the words, not the game's window
--   B9 make-up: no-mirror rows greyed with the game's reason; with a mirror, Apply runs the game's action and the spot is worn,
--      Remove takes it off; the item's Make Up option opens the Character window on Identity, on the make-up part
-- Puts back: the car removed, the make-up taken off, items removed, the Dashboard switch, windows. Manual: the real Heater key,
-- the pad on the dash, a passenger seat, Simple dash, the lit look, the reader's look, row figures, controller join and unplug
-- balloons (B12/B13 need a real pad), Deck size and Large text.  grep "ZEDQA b8ea"; shots zqa_b8ea_*.png.
local TAG = "b8ea"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
if not (p and CW and WW and ZeD.Dashboard and ZeD.MakeUp and ZeD.HairBeard) then say("ERR ZeD's pieces are not loaded"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8ea_" .. n .. ".png") end) end
local function cw() return CW.getWindow() end
local function ww() return WW.getWindow() end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function holdBoth() keepDown(cw()); keepDown(ww()) end

-- the step list: step(waitTicks, fn) runs fn that many ticks after the step before; waitFor(max, cond, fn) runs fn when cond holds (fn(timedOut))
local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local function waitFor(max, cond, fn) Q[#Q + 1] = { max = max, cond = cond, fn = fn } end
local cleanups = {}
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    cleanups = {}
    say("checks: passes=" .. passes .. " misses=" .. misses)
    say("DONE")
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
    qc = qc + 1
    local go, timedOut = false, false
    if s.cond then
        local ok, v = pcall(s.cond)
        if ok and v then go = true elseif qc >= s.max then go, timedOut = true, true end
    else
        go = qc >= s.wait
    end
    if go then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn, timedOut)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end


-- ---- helpers
local HOME = { x = p:getX(), y = p:getY() }
local px, py = math.floor(p:getX()), math.floor(p:getY())
local function sqAt(dx, dy) return getCell():getGridSquare(px + dx, py + dy, 0) end
local wasOpen = { cw = CW.isOpen(), ww = WW.isOpen() }
local inv = p:getInventory()
local given = {}
local function give(ft) local it = inv:AddItem(ft); if it then given[#given + 1] = it end; return it end
local M = ZeD.Messages
local noteName = "B8 QA notice"
local car, spawned = nil, {}
local dashOpt = ZeD.Settings and ZeD.Settings.screenOptions and ZeD.Settings.screenOptions.dashboard
local dashWas = nil
if dashOpt then pcall(function() dashWas = dashOpt:getValue() end) end
local function acuiUp()
    local ui = ISVehicleMenu and ISVehicleMenu.acui and ISVehicleMenu.acui[pn]
    return ui ~= nil and ui:isReallyVisible() == true
end
local function closeAcui()
    local ui = ISVehicleMenu and ISVehicleMenu.acui and ISVehicleMenu.acui[pn]
    if ui and ui:isReallyVisible() then pcall(function() ui:removeFromUIManager() end) end
end
local function heaterOn()
    local part = car and car:getPartById("Heater")
    local md = part and part:getModData()
    return md and md.active == true
end
local function dashInst() return ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(pn) end
local function pressHeater() local ok, e = pcall(ISVehicleMenu.onToggleHeater, p); if not ok then say("ERR heater: " .. tostring(e)) end end
local carKey
local ws = {}   -- makeup worn before we started, to leave it as it was
onCleanup(function()
    if carKey then pcall(function() p:getInventory():Remove(carKey) end) end
    closeAcui()
    if dashOpt and dashWas ~= nil then pcall(function() dashOpt:setValue(dashWas) end) end
    if p:getVehicle() then pcall(function() p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end) end
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    spawned = {}
    pcall(function() M.clear(noteName) end)
    -- make-up worn during the test comes off again
    pcall(function()
        for _, w in ipairs(ZeD.MakeUp.worn(p)) do
            if not ws[w.item:getFullType()] then p:removeWornItem(w.item); p:getInventory():Remove(w.item) end
        end
        triggerEvent("OnClothingUpdated", p)
    end)
    for _, it in ipairs(given) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    given = {}
    local rd = ZeD.Reader and ZeD.Reader.get and ZeD.Reader.get(pn)
    if rd and rd:getIsVisible() then pcall(function() rd:removeFromUIManager() end) end
    if wasOpen.cw and not CW.isOpen() then pcall(CW.toggle, pn) end
    if wasOpen.ww and not WW.isOpen() then pcall(WW.open, pn) end
end)

-- ===== B7 the mini-map, first (no car needed)
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    local Wd = ZeD.DpadWheels and ZeD.DpadWheels.Wd
    local list = (Wd and Wd.map) and Wd.map(p, pn) or {}
    check(#list == 1, "B7.1: the Map wheel has one slice (" .. #list .. ")")
    check(list[1] and list[1].name == getText("IGUI_WorldMap_Toggle"), "B7.1: it is the World map (" .. tostring(list[1] and list[1].name) .. ")")
    local W = ZeD.Wheel
    check(W and type(W.isMiniMapCommand) == "function", "B7.1: ZeD.Wheel.isMiniMapCommand exists")
    if W and W.isMiniMapCommand and ISMiniMap then
        check(W.isMiniMapCommand(ISMiniMap.ToggleMiniMap) == true, "B7.3: the game's mini-map toggle is left out of ZeD's wheels")
        check(W.isMiniMapCommand(ISWorldMap.ToggleWorldMap) ~= true, "B7.3: the world map's toggle is not")
    end
    local MO = ZeD.MiniMapOff
    local mm = getPlayerMiniMap and getPlayerMiniMap(pn)
    if MO and MO.hide and mm then
        local was = mm:isReallyVisible()
        pcall(function() mm:setVisible(true) end)
        local shown = mm:isReallyVisible()
        local took = MO.hide()
        check((not shown) or (took == true and not mm:isReallyVisible()), "B7.4: a shown game mini-map is hidden by ZeD (it was visible: " .. tostring(shown) .. ")")
        pcall(function() mm:setVisible(was) end)
    else
        say("NOTE B7.4: no mini-map object for this player here; the hide check is skipped")
    end
end)

-- ===== B8 Read label
step(10, function()
    local text = "Released February 1993. <LINE> Potassium Records."
    local before = ISMediaInfo and ISMediaInfo.instance
    local R = ZeD.Reader
    local ok, e = pcall(ISMediaInfo.openPanel, pn, text)
    if not ok then say("ERR openPanel: " .. tostring(e)) end
    local win = R and R.get and R.get(pn)
    check(win ~= nil and win:getIsVisible(), "B8.1: ZeD's reader opens on the label")
    check((ISMediaInfo and ISMediaInfo.instance) == before, "B8.1: the game's label window was not made")
    local blocks = R and R.labelWords and R.labelWords(text, nil) or {}
    check(#blocks == 2 and blocks[1].text == "Released February 1993." and blocks[2].text == "Potassium Records.",
        "B8.1: the label's two lines are two paragraphs (" .. #blocks .. ")")
end)
step(30, function() shot("label") end)
step(5, function()
    local win = ZeD.Reader.get(pn)
    if win then pcall(win.removeFromUIManager, win) end
end)

-- ===== B9 make-up
local lipstick, mirrorItem, lipsRow, usesBefore
step(20, function()
    for _, w in ipairs(ZeD.MakeUp.worn(p)) do ws[w.item:getFullType()] = true end
    lipstick = give("Base.Lipstick")
    check(lipstick ~= nil, "B9: a lipstick given")
    local rows = ZeD.MakeUp.rows(p)
    local lips
    for _, r in ipairs(rows) do if r.grp == "Lips" and r.verb == "Apply" then lips = r; break end end
    check(lips ~= nil, "B9.2: the lipstick offers a Lips spot (" .. #rows .. " rows)")
    check(lips and lips.ok == false and lips.reason ~= nil, "B9.2: with no mirror it is greyed with the game's reason (" .. tostring(lips and lips.reason) .. ")")
end)
step(10, function()
    mirrorItem = give("Base.Mirror")
    local rows = ZeD.MakeUp.rows(p, lipstick)
    local lips
    for _, r in ipairs(rows) do if r.grp == "Lips" and r.verb == "Apply" then lips = r; break end end
    check(lips and lips.ok == true, "B9.3: with a mirror carried the spot can be done")
    if lips then
        lipsRow = lips
        usesBefore = lipstick:getCurrentUses()
        lips.run(p)
    end
end)
waitFor(500, function() return not ISTimedActionQueue.isPlayerDoingAction(p) and #ZeD.MakeUp.worn(p) > 0 end, function(t)
    local lips = lipsRow
    check(not t, "B9.3: the game's Apply action ran to its end")
    local wornNow = {}
    for _, w in ipairs(ZeD.MakeUp.worn(p)) do wornNow[#wornNow + 1] = w.item:getFullType() end
    check(lips and #ZeD.MakeUp.worn(p) > 0 and (lips.style == nil or table.concat(wornNow, ","):find(lips.style, 1, true) ~= nil),
        "B9.3: the spot is worn (" .. table.concat(wornNow, ",") .. ")")
    check(usesBefore ~= nil and lipstick:getCurrentUses() < usesBefore, "B9.3: the lipstick's uses dropped by one")
end)
step(10, function()
    local rows = ZeD.MakeUp.rows(p, lipstick)
    local off
    for _, r in ipairs(rows) do if r.grp == "Remove" and not ws[r.style] then off = r; break end end
    check(off ~= nil, "B9.4: the spot just applied shows under Remove")
    if off then off.run(p) end
end)
step(15, function()
    local left = 0
    for _, w in ipairs(ZeD.MakeUp.worn(p)) do if not ws[w.item:getFullType()] then left = left + 1 end end
    check(left == 0, "B9.4: Remove took it off at once (" .. left .. " left)")
end)
-- 5. the item's Make Up option: the Character window on Identity, on the make-up part
step(5, function()
    if CW.isOpen() then pcall(CW.toggle, pn) end
end)
step(15, function()
    local ok, e = pcall(ISInventoryPaneContextMenu.onMakeUp, lipstick, p)
    if not ok then say("ERR onMakeUp: " .. tostring(e)) end
end)
waitFor(150, function() return cw() ~= nil and cw()._activeTab == "identity" end, function(t)
    holdBoth()
    check(not t, "B9.5: the Character window opens on Identity")
end)
step(40, function()
    holdBoth()
    local win = cw()
    local st = win and ZeD.HairBeard.state(win)
    check(st ~= nil and st.part == "makeup", "B9.5: the hair section is on Make Up (part " .. tostring(st and st.part) .. ")")
    local parts = st and ZeD.HairBeard.partsOf(st) or {}
    local hasMk = false
    for _, k in ipairs(parts) do if k == "makeup" then hasMk = true end end
    check(hasMk, "B9.1: the switch carries Make Up (" .. table.concat(parts, ",") .. ")")
    shot("makeup")
end)

-- ===== B6 the heater, in a spawned pickup
step(10, function()
    if CW.isOpen() then pcall(CW.toggle, pn) end
    local sq = sqAt(-5, 3)
    if sq then
        local ok, v = pcall(addVehicleDebug, "Base.PickUpTruck", IsoDirections.N, nil, sq)
        if ZEDQA_VPROBE then ZEDQA_VPROBE(TAG, sq, ok and v or nil) end
        if ok and v then car = v; spawned[#spawned + 1] = v end
    end
    if not car then say("NOTE B6: no car could be spawned; the heater checks are skipped") end
end)
step(50, function()
    if not car then return end
    if car:DistTo(p) > 12 then say("NOTE B6: the car is " .. car:DistTo(p) .. " tiles off; not entering a far vehicle"); car = nil; return end
    car:enter(0, p); triggerEvent("OnEnterVehicle", p)
end)
step(60, function()
    if not car or p:getVehicle() ~= car then car = nil; return end
    pcall(function() carKey = p:getInventory():AddItem(car:createVehicleKey()) end)   -- (Nov 8 QA: the game puts keys in the ignition only for a character who holds the car's key)
    pcall(function() car:setKeysInIgnition(true) end)
    say("B6 diag: keys in ignition right after setting them: " .. tostring(car:isKeysInIgnition()) .. ", the character is in it: " .. tostring(p:getVehicle() == car))
    check(car:getPartById("Heater") ~= nil, "B6: the pickup has a heater part")
    check(dashInst() ~= nil, "B6: ZeD's dash is up for the driver")
end)
-- 1. the key
step(20, function() if car then say("B6 diag: keys in ignition before the press: " .. tostring(car:isKeysInIgnition()) .. ", engine " .. tostring(car:isEngineRunning())); closeAcui(); pressHeater() end end)
step(6, function()
    if not car then return end
    local inst = dashInst()
    check(inst ~= nil and inst._climateUntil ~= nil and inst._climateUntil > getTimestampMs(), "B6.1: the dash's climate controls are lit")
    check(not acuiUp(), "B6.1: the game's heater window did not open")
end)
step(10, function() if car then shot("heater_lit") end end)
step(30, function()
    if not car then return end
    check(heaterOn(), "B6.1: the heater is on (part modData active " .. tostring(car:getPartById("Heater") and car:getPartById("Heater"):getModData().active) .. ")")
end)
-- (Nov 8 QA) when the press left the heater off: is it the press, or does the game's own command path not set it in single player here?
step(5, function() if car and not heaterOn() then say("B6.1 diag: sending the game's own toggleHeater command by hand"); pcall(sendClientCommand, p, "vehicle", "toggleHeater", { on = true, temp = 0 }) end end)
step(30, function()
    if not car then return end
    local pt = car:getPartById("Heater")
    say("B6.1 diag: part modData active " .. tostring(pt and pt:getModData().active) .. ", engine " .. tostring(car:isEngineRunning()) .. ", keys " .. tostring(car:isKeysInIgnition()) .. ", battery " .. tostring(car:getBatteryCharge()))
end)
-- 2. again: off
step(5, function() if car then pressHeater() end end)
step(40, function()
    if not car then return end
    check(not heaterOn(), "B6.2: the second press turns the heater off")
    check(not acuiUp(), "B6.2: still no game heater window")
end)
-- 3. key out: nothing turns on
step(5, function() if car then pcall(function() car:setKeysInIgnition(false) end) end end)
step(10, function() if car then pressHeater() end end)
step(40, function()
    if not car then return end
    check(not heaterOn(), "B6.3: with the key out nothing turns on")
    check(not acuiUp(), "B6.3: and no game window")
    pcall(function() car:setKeysInIgnition(true) end)
    say("B6 diag: keys in ignition right after setting them: " .. tostring(car:isKeysInIgnition()) .. ", the character is in it: " .. tostring(p:getVehicle() == car))
end)
-- 8. the Dashboard switch on the game's own: the game's window
step(5, function()
    if not (car and dashOpt) then return end
    pcall(function() dashOpt:setValue(2) end)
end)
step(60, function()
    if not (car and dashOpt) then return end
    check(ZeD.Safe.on("dashboard") == true, "B6.8: the Dashboard switch reads as the game's own")
    pressHeater()
end)
step(20, function()
    if not (car and dashOpt) then return end
    check(acuiUp(), "B6.8: with the game's dash the key opens the game's heater window")
    closeAcui()
    pcall(function() dashOpt:setValue(dashWas or 1) end)
end)
step(60, function()
    if not (car and dashOpt) then return end
    check(not ZeD.Safe.on("dashboard"), "B6.8: ZeD's dash is back")
    -- the heater the game's window turned on (if any) goes off again with the car
end)

-- ===== B13.9 a kept note on the dash: the balloons come out of it
step(5, function()
    if not car or p:getVehicle() ~= car then return end
    M.notice(noteName, "A QA notice, to see the balloon on the dash.")
end)
step(30, function()
    if not car or p:getVehicle() ~= car then return end
    local W = ZeD.MessagesWindow
    local x, y, w = W.dashNoteRect()
    check(x ~= nil, "B13.9: with a note kept the dash shows the Messages note")
    local nx, ny, tail = W.noticeAnchor(pn)
    check(tail == true and nx ~= nil, "B13.9: the balloon's anchor is the dash's note, with the tail")
    shot("dash_note")
end)
step(5, function()
    pcall(function() M.clear(noteName) end)
    local W = ZeD.MessagesWindow
    check(W.dashNoteRect() == nil or M.count() > 0, "B13.9: with nothing kept the dash shows no note")
end)
step(5, function()
    if p:getVehicle() then pcall(function() p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end) end
end)
step(15, function() end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
