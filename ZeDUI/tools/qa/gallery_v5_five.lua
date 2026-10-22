-- ZeDUI/tools/qa/gallery_v5_five.lua  (Oct 22 2026)
-- Workshop gallery re-shoot of the five re-added cards (Equipment tab, Health tab, Action
-- bar, On a controller, The car radio): after gallery_v3_core.lua, gallery_v3_reveal.lua
-- and gallery_v3_stage.lua (needs GAL, GAL.spot, GAL.car), with ZeD on. Same staging, same
-- theme (high contrast + PZ Teal, in memory only) as the rest of the set. Full-screen
-- shots in Zomboid/Screenshots, named g5_<scene>.png:
--   g5_equip_doll          Character window, Equipment tab, doll view, zoom 1.0
--   g5_health_exercise     Character window, Health tab, Push-ups picked, zoom 1.0
--   g5_action_bar_reading  windows shut, zoom 0.5, two zombies near, reading a book
--   g5_wheel_emotes        emote wheel on the character, zoom 0.5, thumbs up pointed
--   g5_wheel_vehicle       the vehicle wheel from the driver seat, Engine pointed
--   g5_car_radio           the car radio up close (the wheel's Device Options entry)
-- Puts back what it changes; the scene stays for gallery_v3_teardown.lua.
-- "ZEDQA g5f ..." ending "ZEDQA g5f DONE".
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA g5f ERR run gallery_v3_core.lua and gallery_v3_stage.lua first"); print("ZEDQA g5f DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA g5f ERR ZeD is not loaded"); print("ZEDQA g5f DONE"); return end
if ZeD.trTestOn and ZeD.trTestOn() then print("ZEDQA g5f ERR the test language is on"); print("ZEDQA g5f DONE"); return end
local S = G.newSeq("g5f", 600000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local RO, CR = ZeD.RadioOps, ZeD.CarRadio
local Opt = ZeD.Settings
local Z = { lock = nil, sc = { ok = true, why = "" }, was = {} }
Z.was.ctx = Opt.contextStyleOption:getValue()
Z.was.watch = Opt.watchPlaceOption:getValue()
Z.was.bar = Opt.actionBarOption:getValue()
Z.was.equip = ZeD.EquipDoll.view()
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end

function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) then return false end
    if w._rolled then return false end
    local L = Z.lock
    if not L then
        local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 16
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
        Z.lock = L
    end
    c._anchorRightEdge = L.right
    c:setX(L.right - c:getWidth())
    w:setX(L.left)
    c:setY(L.cy)
    w:setY(L.wy)
    return true
end
function Z.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    Z.place()
end
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function Z.charTab(id) local w = Z.CW(); return (w and Z.goTab(w, w._tabStripPanel, id)) and true or false end
function Z.worldTab(id) local w = Z.WW(); return (w and Z.goTab(w, w._actionTabStrip, id)) and true or false end
function Z.found(ft)
    local items = G.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
function Z.theme(base, accent)
    ZeD.applyTheme(base, accent, ZeD.currentSize)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end
function Z.setup(fn)
    pcall(Z.place)
    G.faceFront()
    Z.sc.ok, Z.sc.why = true, ""
    if not fn then return end
    local ok, a, b = pcall(fn)
    if not ok then Z.sc.ok, Z.sc.why = false, tostring(a)
    elseif a == false then Z.sc.ok, Z.sc.why = false, tostring(b or "setup refused") end
end
function Z.finish(name) if Z.sc.ok then S.shot(name) else S.err(name, Z.sc.why) end end
function Z.Sc(name, settle, fn)
    S.step(2, function() Z.setup(fn) end)
    S.step(settle or 30, function() Z.finish(name) end)
end
function Z.T(name, tab, settle, fn)
    S.step(2, function() Z.sc.ok, Z.sc.why = true, "" end)
    S.poll(2, 120, function() return Z.charTab(tab) end, function() Z.sc.ok = false; Z.sc.why = "no tab " .. tab end)
    S.step(6, function() if Z.sc.ok then Z.setup(fn) end end)
    S.step(settle or 30, function() Z.finish(name) end)
end
local function sliceWith(menu, word)
    for i, s in ipairs(menu and menu.slices or {}) do
        if tostring(s.text or ""):lower():find(word, 1, true) then return i end
    end
    return nil
end

-- ===========================================================================
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    pcall(ZeD.Settings.reapplyFromOptions)
    if ZeD.currentBase ~= "hicon" or ZeD.currentAccent ~= "teal" then Z.theme("hicon", "teal") end
    say("theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " size " .. tostring(ZeD.currentSize)
        .. " | scale " .. tostring(ZeD.Scale and ZeD.Scale.current and ZeD.Scale.current()))
    Opt.watchPlaceOption:setValue(1)
    Opt.contextStyleOption:setValue(1)
    Opt.actionBarOption:setValue(1)
    G.stand()
    Z.openPair()
end)
S.step(40, function() Z.charTab("loot"); Z.worldTab("loot"); Z.place() end)
S.zoomTo(1.0)

-- ---- the Character window's tabs -----------------------------------------------
Z.T("g5_equip_doll", "equip", 55, function() ZeD.EquipDoll.setView("doll") end)
S.step(2, function() ZeD.EquipDoll.setView(Z.was.equip) end)
Z.T("g5_health_exercise", "health", 45, function()
    local w = Z.CW()
    if not (ZeD.HealthTab and ZeD.HealthTab.exerciseInfo and ZeD.HealthTab.exerciseInfo(p, "pushups")) then return false, "no exercise info" end
    Z.was.exSel = w._healthExerciseSel
    w._healthFigureExpanded = true
    pcall(function() w._healthScroll:setScrollPos(0) end)
    w._healthExerciseSel = "pushups"
end)
S.step(2, function() local w = Z.CW(); if w then w._healthExerciseSel = Z.was.exSel end; Z.charTab("loot") end)

-- ---- the action bar --------------------------------------------------------------
S.step(2, function() Z.closePair() end)
S.zoomTo(0.5)
S.step(2, function()
    G.nearZombies(true)
    pcall(function() p:getStats():set(CharacterStat.HUNGER, 0.3); p:getStats():set(CharacterStat.THIRST, 0.35) end)
    p:getModData().ZeD_WatchPop = nil
end)
S.step(90, function() G.faceFront() end)
Z.Sc("g5_action_bar_reading", 90, function()
    local book = Z.found("Base.Book")
    if not book then return false, "no book" end
    local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, pn) end)
    if not ok then ISTimedActionQueue.add(ISReadABook:new(p, book, 150)) end
end)
S.step(2, function()
    pcall(function() ISTimedActionQueue.clear(p) end)
    G.nearZombies(false)
    pcall(function() p:getStats():set(CharacterStat.HUNGER, 0); p:getStats():set(CharacterStat.THIRST, 0) end)
end)
S.step(40, function() end)

-- ---- the emote wheel (windows shut, no zombies, empty hands) -----------------------
S.step(2, function()
    Z.sc.ok, Z.sc.why = true, ""
    G.faceFront()
    Z.handsWas = { p:getPrimaryHandItem(), p:getSecondaryHandItem() }
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
end)
S.step(60, function() G.faceFront() end)
S.step(2, function()
    ISEmoteRadialMenu:new(p):fillMenu()
    local m = getPlayerRadialMenu(pn)
    local i = sliceWith(m, "thumbs up") or sliceWith(m, "thumb")
    say("emote slices: " .. tostring(m and #m.slices) .. " | thumbs up at " .. tostring(i))
    if ZeD.Wheel then ZeD.Wheel.qaPoint = i end
end)
S.step(40, function() S.shot("g5_wheel_emotes") end)
S.step(2, function()
    if ZeD.Wheel then ZeD.Wheel.qaPoint = nil end
    local m = getPlayerRadialMenu(pn); if m then m:undisplay() end
    if Z.handsWas then pcall(function() p:setPrimaryHandItem(Z.handsWas[1]); p:setSecondaryHandItem(Z.handsWas[2]) end) end
    Z.handsWas = nil
end)
S.step(20, function() end)

-- ---- the car: the vehicle wheel and the radio up close -------------------------------
S.zoomTo(1.0)
S.step(2, function()
    local v = G.car
    local d = 99
    pcall(function() d = v:DistTo(p) end)
    if d > 12 then Z.sc.ok, Z.sc.why = false, "car " .. d .. " away"; return end
    local part = v:getPartById("Radio")
    if part and not part:getInventoryItem() then
        pcall(function()
            part:setInventoryItem(instanceItem("Base.RadioRed"))
            Vehicles.InstallComplete.Radio(v, part)
            local dd = part:getDeviceData()
            if dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
        end)
    end
    say("radio part " .. tostring(part ~= nil) .. " fitted " .. tostring(part and part:getInventoryItem() ~= nil))
    pcall(function() v:enter(0, p) end)
    Z.entered = p:getVehicle() ~= nil
    if Z.entered then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
    Z.sc.ok = Z.entered
    Z.sc.why = Z.entered and "" or "could not get in"
end)
S.step(30, function() if Z.entered then pcall(function() G.car:setKeysInIgnition(true) end) end end)
local ES = { tries = 0, last = -9999 }
S.poll(10, 1500, function()
    if not Z.entered then return true end
    local run = false
    pcall(function() run = G.car:isEngineRunning() end)
    if run then return true end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local busy = q and q.queue and #q.queue > 0
    if not busy and S.tick - ES.last > 120 and ES.tries < 5 then
        ES.tries = ES.tries + 1; ES.last = S.tick
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
    end
    return false
end, function() say("note: the engine did not start") end)
S.step(60, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if not (Z.entered and d and d._st) then return end
    if not d._st.radioOn then d:_fire("pwr", false) end
    local part = G.car:getPartById("Radio")
    if part then
        pcall(function() RO.setChannel(p, part, 101200) end)
        pcall(function() RO.run("SetVolume", p, part, 0.6) end)
    end
end)
S.step(90, function() end)
-- the vehicle wheel from the seat, Engine pointed
S.step(2, function()
    if not Z.entered then S.err("g5_wheel_vehicle", Z.sc.why); return end
    pcall(function() ISVehicleMenu.showRadialMenu(p) end)
    local m = getPlayerRadialMenu(pn)
    local i = sliceWith(m, "engine")
    say("vehicle slices: " .. tostring(m and #m.slices) .. " | engine at " .. tostring(i))
    if ZeD.Wheel then ZeD.Wheel.qaPoint = i end
end)
S.step(40, function() if Z.entered then S.shot("g5_wheel_vehicle") end end)
S.step(2, function()
    if ZeD.Wheel then ZeD.Wheel.qaPoint = nil end
    local m = getPlayerRadialMenu(pn); if m then m:undisplay() end
end)
S.step(20, function() end)
-- the radio up close
S.step(2, function()
    local part = G.car:getPartById("Radio")
    if not (part and Z.entered) then S.err("g5_car_radio", "no radio part or not seated"); return end
    pcall(function() ISVehicleMenu.onSignalDevice(p, part) end)
end)
S.step(60, function()
    local pr = CR and CR.props and CR.props[pn]
    if Z.entered and pr and pr:isReallyVisible() then S.shot("g5_car_radio")
    elseif Z.entered then S.err("g5_car_radio", "the radio did not come up") end
    pcall(function() CR.closeFor(pn) end)
end)
S.step(2, function()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
    Z.entered = false
end)
S.step(40, function() G.stand(); G.openTrunk(G.car); G.faceFront() end)

-- ---- back ---------------------------------------------------------------------------
S.step(10, function()
    pcall(ZeD.Settings.reapplyFromOptions)
    Opt.contextStyleOption:setValue(Z.was.ctx)
    Opt.watchPlaceOption:setValue(Z.was.watch)
    Opt.actionBarOption:setValue(Z.was.bar)
    ZeD.EquipDoll.setView(Z.was.equip)
    Z.openPair()
    say("theme back: " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
end)
S.start()
