-- ZeDUI/tools/qa/gallery_beta_new.lua  (Nov 2 2026, QA; the gallery's new pages for 0.3.0-beta1)
-- In game at 4K, after gallery_t14_look.lua and gallery_daylight.lua (the default look, daylight, no debug artifacts).
-- Eight new captures, each full screen in Zomboid/Screenshots (Build crops them into the spreads):
--   gb_cmap_window        the controller map window, Xbox pictures
--   gb_bugreport_wheel    the ZeD wheel (the Select wheel) with Bug report pointed
--   gb_bugreport_dialog   its "N errors are copied ..." dialog (two errors made first; expect=qaGalleryError)
--   gb_forms_setup        ZeD setup's Full or simple group (the pause menu's Options, ZeD setup, scrolled to it)
--   gb_simple_watch       the Simple watch in the corner, a digital watch worn
--   gb_plain_radio        the black radio's plain card in the Radio tab (on, a station)
--   gb_plain_dash         the Simple dashboard in a car, engine running
--   gb_simple_belt        the Simple belt
-- Everything is put back. Steps run on OnTickEvenPaused (ZeD setup pauses the game). grep "ZEDQA gbn".
local function say(s) print("ZEDQA gbn " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local S, CM, MS, D, W = ZeD.Settings, ZeD.ControllerMap, ZeD.Messages, ZeD.DpadWheels, ZeD.Wheel
local MM = ZeD.MainMenu
local function shot(n) pcall(function() getCore():TakeFullScreenshot(n .. ".png") end); say("shot " .. n) end
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local inv = p:getInventory()
local was = {
    glyph = S.glyphOption:getValue(), watchStyle = S.watchStyleOption:getValue(), watchPlace = S.watchPlaceOption and S.watchPlaceOption:getValue(),
    dash = S.dashStyleOption:getValue(), devices = S.devicesStyleOption:getValue(), belt = S.beltStyleOption:getValue(),
    prim = p:getPrimaryHandItem(), sec = p:getSecondaryHandItem(), srcs = MS.sources,
}
local added = {}
local function give(ft) local it = inv:AddItem(ft); if it then added[#added + 1] = it end; return it end
local function console(off)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(not off) end end
end
local function prompts(fn)
    local ui = UIManager.getUI()
    for i = ui:size() - 1, 0, -1 do
        local t = nil; pcall(function() t = ui:get(i):getTable() end)
        if type(t) == "table" and t.Type == "ZeD_Prompt" then fn(t) end
    end
end
local function windowsShut() if CW.isOpen() then CW.toggleBothPaired(pn) end end

local Q, qi = {}, 1
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end
local function waitFor(k, max, cond, fn) Q[#Q + 1] = { n = k, fn = fn, cond = cond, max = max } end

-- 1. the controller map
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    console(true); windowsShut()
    for i, k in ipairs(S.glyphKeys) do if k == "xbox" then S.glyphOption:setValue(i) end end
    CM.open(pn)
end)
step(40, function() shot("gb_cmap_window"); CM.close(pn) end)
-- 2. two errors, then the ZeD wheel with Bug report pointed
step(10, function()
    MS.sources = {}
    local function boom1() Events.OnTick.Remove(boom1); local t = nil; return t.qaGalleryErrorOne end
    Events.OnTick.Add(boom1)
end)
step(60, function()
    local function boom2() Events.OnTick.Remove(boom2); local t = nil; return t.qaGalleryErrorTwo end
    Events.OnTick.Add(boom2)
end)
step(120, function()
    local w = getPlayerBackButtonWheel(pn)
    w:addCommands(); w:addToUIManager(true); w:setVisible(true)
end)
step(10, function()
    local st = D.state[pn]
    local m = st and st.menu
    local idx
    for i, s in ipairs((m and m.slices) or {}) do if tostring(s.text or ""):find(ZeD.tr("UI_ZeD_Msg_BugReport"), 1, true) then idx = i end end
    say("the ZeD wheel: " .. tostring(m and #m.slices) .. " slices, Bug report at " .. tostring(idx))
    W.qaPoint = idx
end)
step(30, function() shot("gb_bugreport_wheel") end)
step(5, function()
    W.qaPoint = nil
    local st = D.state[pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    local w = getPlayerBackButtonWheel(pn); if w and w:isReallyVisible() then pcall(w.undisplay, w) end
    local n = MS.copyBugReport(pn)
    say("Bug report: " .. tostring(n) .. " errors copied")
end)
step(30, function() shot("gb_bugreport_dialog"); prompts(function(t) pcall(function() t:pressPrimary() end) end) end)
-- (Nov 11 2026) the two made errors left an error notice on the Messages icon in the pictures after this one: cleared here
step(20, function() MS.sources = {}; MS.toasts = {}; pcall(function() if MS.bubbles then MS.bubbles = {} end end); say('error notices cleared') end)
-- 3. the Simple watch, worn, in the corner
local watch
step(10, function()
    S.watchStyleOption:setValue(2)
    if S.watchPlaceOption then S.watchPlaceOption:setValue(2) end
    watch = give("Base.WristWatch_Left_DigitalBlack")
    if watch then p:setWornItem(watch:getBodyLocation(), watch) end
end)
step(60, function() shot("gb_simple_watch") end)
step(5, function()
    if watch then pcall(function() p:removeWornItem(watch) end) end
    S.watchStyleOption:setValue(was.watchStyle)
    if S.watchPlaceOption and was.watchPlace then S.watchPlaceOption:setValue(was.watchPlace) end
end)
-- 4. the Simple belt
step(5, function() S.beltStyleOption:setValue(2) end)
step(40, function() shot("gb_simple_belt") end)
step(5, function() S.beltStyleOption:setValue(was.belt) end)
-- 5. the black radio's plain card, on a station
local radio
step(10, function()
    S.devicesStyleOption:setValue(2)
    radio = give("Base.RadioBlack")
    local dd = radio and radio:getDeviceData()
    if dd then dd:setHasBattery(true); dd:setPower(0.8); dd:setIsTurnedOn(true); dd:setDeviceVolume(0.5); dd:setChannel(98000) end
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil); p:setPrimaryHandItem(radio)
    if not CW.isOpen() then CW.toggleBothPaired(pn) end
end)
waitFor(5, 200, function() local w = CW.getWindow(); local r = w and w._radios and w._radios[1]; return r ~= nil and r.radioInstance == radio end, function()
    local w = CW.getWindow()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:radio" and (w._activeTab ~= "radio" or not w._drawerOpen) then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
end)
local hWas = {}
step(40, function()
    local w = CW.getWindow(); local t = w and w._radioTw
    hWas.c, hWas.w = w:getHeight(), WW.getWindow():getHeight()
    local need = (t and t.des and t.des.h or 0) + ZeD.T.px(40)
    if t and t.view and need > t.view.h then
        local add = need - t.view.h + 2
        w:setHeight(w:getHeight() + add); WW.getWindow():setHeight(WW.getWindow():getHeight() + add)
    end
end)
step(60, function() shot("gb_plain_radio") end)
step(10, function()
    local w = CW.getWindow(); if hWas.c then w:setHeight(hWas.c); WW.getWindow():setHeight(hWas.w) end
    pcall(function() radio:getDeviceData():setIsTurnedOn(false) end)
    p:setPrimaryHandItem(was.prim); p:setSecondaryHandItem(was.sec)
    S.devicesStyleOption:setValue(was.devices)
    windowsShut()
end)
-- 6. ZeD setup's Full or simple group (the pause menu's Options: the game pauses)
step(10, function() if D.H and D.H.openSetup then D.H.openSetup(p, pn) end end)
step(60, function()
    local w = MM and (MM.pauseOpts or (MM.root and MM.root.optsWin))
    if not w then say("ERR no ZeD setup window"); return end
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    local y = 0
    for _, r in ipairs(w:rowsFor(w:pages()[w.pageIdx])) do
        if r.kind == "header" and tostring(r.text):lower() == ZeD.tr("UI_ZeD_Options_ZedForms"):lower() then break end
        y = y + (r._h or ZeD.T.px(30))
    end
    w.scroll = math.max(0, y - ZeD.T.px(6))
    console(true)
end)
step(40, function() shot("gb_forms_setup") end)
step(10, function()
    local w = MM and (MM.pauseOpts or (MM.root and MM.root.optsWin))
    if w then pcall(function() w:close() end) end
end)
step(20, function()
    if MainScreen and MainScreen.instance and MainScreen.instance:isVisible() then ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
end)
-- 7. the Simple dashboard in a car, engine running (dash19's way in)
local car, carKey
step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    S.dashStyleOption:setValue(2)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "gbn") end
end)
step(120, function()
    for _, o in ipairs({ { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 } }) do
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free then car = addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq); if car then break end end
    end
end)
waitFor(5, 300, function()
    if not car then return true end
    local phys = false; pcall(function() phys = car:isPhysicsActive() end)
    return phys
end, function()
    if not car then say("ERR no car"); return end
    pcall(function() car:repair() end)
    pcall(function() local g = car:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function() carKey = inv:AddItem(car:createVehicleKey()) end)
    car:enter(0, p); triggerEvent("OnEnterVehicle", p)
end)
step(20, function() pcall(function() car:setKeysInIgnition(true) end) end)
step(15, function()
    pcall(function() ISVehicleMenu.onStartEngine(p) end)
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st then
        if not d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
        if not d._st.lights then pcall(function() d:_fire("lights", false) end) end
    end
end)
step(150, function()
    local run = false; pcall(function() run = car:isEngineRunning() end)
    say("the car's engine running " .. tostring(run))
    shot("gb_plain_dash")
end)
step(10, function()
    local v = p:getVehicle(); if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if carKey then pcall(function() inv:Remove(carKey) end) end
end)
step(30, function()
    if car and p:getVehicle() ~= car then pcall(function() car:permanentlyRemove() end) end
    S.dashStyleOption:setValue(was.dash)
    S.glyphOption:setValue(was.glyph)
    MS.sources = was.srcs or {}
    for _, it in ipairs(added) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    console(false)
    say("DONE")
end)

local wait, waited = nil, 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnTickEvenPaused.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        waited = waited + 1
        if not s.cond() and waited < (s.max or 100) then wait = 1; return end
        waited = 0
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTickEvenPaused.Add(tick)
say("start")
