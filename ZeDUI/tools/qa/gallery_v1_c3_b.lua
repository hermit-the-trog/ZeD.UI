-- ZeDUI/tools/qa/gallery_v1_c3_b.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's lived-in retakes, part b: chapters
-- 64 Controller, 66 Quick Actions and 73 Immersive or Simple, all on the West Point Fossoil's forecourt beside the pump
-- and the story's station wagon (spot pump). Same content and settings as the captures they replace; the new rule: the
-- window sits to one side (the pause screen's Options window is moved off the middle by its own place(), wrapped on the
-- instance for the shot and put back) and Angel and the forecourt stay uncovered.
--   64  zqa_padmap_options        Options > Controls > Button map and test, the Xbox set, a made-up moment of input lit
--                                 (A, the D-pad's left arm, RB, the left stick's click, the stick pushed, LT 60%)
--                                 (gallery_b19_b.lua's 47; zedqa_pad_figure.lua "02_lit")
--   66  zqa_g3_setup_chords       ZeD setup on the pause screen in the controller's look, the Quick actions rows in
--       zqa_g3_setup_list         view, LB + X marked; that row's action list dropped from its box; then the Put
--       zqa_g3_setup_putback      things back row mid-list, marked (gallery_nov1_t3.lua)
--   73  gb_simple_watch           the watch on the belt, Simple (DigitalBlack), windows shut
--       gb_simple_belt            the belt, Simple
--       gb_plain_radio            Devices on Simple: a RadioBlack in the hand, on, the Character window's Radio tab
--       gb_forms_setup            ZeD setup scrolled to the ZeD forms rows
--       gb_plain_dash             in the story's station wagon, engine running, the Simple dashboard
--                                 (gallery_b19_b.lua's 45 and 42 shots; all five in this one spot)
-- Puts back: the options (watch, belt, devices, dashboard, button pictures), the watch worn, the radio, the car key and
-- seat, the pause screen shut, the input mode, the look, the windows, the place. grep "ZEDQA c3b".
if not C3 then print("ZEDQA c3b ERR run gallery_v1_c3_common.lua first"); print("ZEDQA c3b DONE"); return end
local Q = C3.make("c3b", 1500000)
local B = { given = {}, optWas = {} }
B.p, B.pn, B.core = C3.p, C3.pn, C3.core
B.St, B.MM, B.Det = ZeD.Settings, ZeD.MainMenu, ZeD.Input and ZeD.Input.Detector
B.D = ZeD.DpadWheels

function B.setOpt(o, v) if o and v then pcall(function() o:setValue(v) end) end end
function B.menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
function B.toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
function B.opts() return B.MM.pauseOpts or (B.MM.root and B.MM.root.optsWin) end
-- the Options window's own place() centres it every frame: wrapped on this instance to sit at one side
function B.pin(w)
    if not w or w._c3pin then return end
    w._c3pin = true
    w.place = function(self)
        local a, b = ZeD_MMOptions.place(self)
        local x = C3.sideX(self:getWidth(), "left")
        if self.x ~= x then self:setX(x) end
        return a, b
    end
end
function B.unpin(w) if w and w._c3pin then w.place = nil; w._c3pin = nil end end
function B.give(ft) local it = B.p:getInventory():AddItem(ft); if it then B.given[#B.given + 1] = it end; return it end
-- the watch worn now, kept to put back
function B.findKit()
    pcall(function()
        local worn = B.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local wi = worn:get(i)
            if instanceof(wi:getItem(), "AlarmClockClothing") then B.kit, B.kitLoc = wi:getItem(), wi:getLocation() end
        end
    end)
end
function B.wear(name)
    if B.curWatch then pcall(function() B.p:removeWornItem(B.curWatch, false); B.p:getInventory():Remove(B.curWatch) end); B.curWatch = nil end
    if B.kit then pcall(function() B.p:removeWornItem(B.kit, false) end) end
    if not name then
        if B.kit then pcall(function() B.p:setWornItem(B.kitLoc, B.kit) end) end
        return
    end
    pcall(function()
        B.curWatch = B.p:getInventory():AddItem("Base.WristWatch_Left_" .. name)
        B.p:setWornItem(B.curWatch:getBodyLocation(), B.curWatch)
    end)
end
-- ZeD setup's rows (gallery_nov1_t3.lua's T3.find / mark / rect)
function B.find(pred)
    local o = B.o
    local rows = o:rowsFor(o:pages()[o.pageIdx or 1])
    local idx, y = 0, 0
    for i, r in ipairs(rows) do
        if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then idx = idx + 1 end
        if pred(r) then return { r = r, i = i, idx = idx, y = y, h = r._h or ZeD.T.px(30) } end
        y = y + (r._h or ZeD.T.px(30))
    end
    return nil
end
function B.mark(f) B.o.focusId = "orow:" .. f.idx; B.o._cellRow = f.r end

-- ===================================================================== setup
Q.step(10, function()
    B.look = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
    B.wins = C3.snapWins()
    B.prim, B.sec = B.p:getPrimaryHandItem(), B.p:getSecondaryHandItem()
    B.home = { x = B.p:getX(), y = B.p:getY(), z = B.p:getZ() }
    for _, k in ipairs({ "watchPlaceOption", "watchStyleOption", "dashStyleOption", "devicesStyleOption", "beltStyleOption", "glyphOption" }) do
        local o = B.St[k]
        if o then B.optWas[k] = o:getValue() end
    end
    B.padStateWas = B.MM.padState
    B.forceWas = B.MM.forceGamepad
    B.findKit()
    B.setOpt(B.St.devicesStyleOption, 1); B.setOpt(B.St.dashStyleOption, 1); B.setOpt(B.St.beltStyleOption, 1); B.setOpt(B.St.watchStyleOption, 1)
    C3.theme((GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "teal", B.look[3])
    C3.listView(true)
    C3.go(Q, "pump", "SE")
    C3.pairShut()
    Q.say("kit watch " .. tostring(B.kit and B.kit:getFullType()) .. " | car " .. tostring(STORY and STORY.car ~= nil) .. " | " .. C3.where())
end)
Q.still(60, function() end)

-- ===================================================================== 64 Controller: zqa_padmap_options
Q.step(10, function()
    for i, k in ipairs(B.St.glyphKeys or {}) do if k == "xbox" then B.St.glyphOption:setValue(i) end end
    if not B.menuUp() then B.toggleMenu() end
end)
Q.step(50, function() pcall(B.MM.openOptions) end)
Q.step(50, function()
    local w = B.MM.pauseOpts
    if not (w and w:isVisible()) then Q.notTaken("zqa_padmap_options", "no in-game Options window"); return end
    B.pin(w)
    pcall(function() w:openVanillaController() end)
end)
Q.step(70, function()
    B.MM.padState = function()
        return { b = { A = true, DL = true, RB = true, L3 = true }, ls = { 0.6, -0.4 }, rs = { 0, 0 }, lt = 0.6, rt = 0 }
    end
    C3.park()
end)
Q.step(40, function()
    local w = B.MM.pauseOpts
    if w and w.sub == "pad" and w._padFig then Q.shot("zqa_padmap_options", { { "options", w } })
    elseif w then Q.notTaken("zqa_padmap_options", "Button map and test did not open (" .. tostring(w.sub) .. ")") end
    B.MM.padState = B.padStateWas
end)
Q.step(10, function()
    local w = B.MM.pauseOpts
    pcall(function() w:closeSub() end)
    B.unpin(w)
    pcall(function() w:close() end)
end)
Q.step(20, function()
    if B.menuUp() then B.toggleMenu() end
    B.setOpt(B.St.glyphOption, B.optWas.glyphOption)
end)

-- ===================================================================== 66 Quick Actions: the setup rows
Q.step(20, function()
    pcall(function() B.Det.setLockedMode("gamepad") end)
    B.MM.forceGamepad = true
    B.D.H.openSetup(B.p, B.pn)
end)
Q.step(40, function()
    B.o = B.MM.pauseOpts
    if not B.o then Q.say("ERR no ZeD setup"); return end
    B.pin(B.o)
    C3.park()
end)
Q.step(10, function() end)
Q.step(2, function()
    if not B.o then return end
    local first = B.find(function(r) return r.kind == "chord" end)
    B.chord = B.find(function(r) return r.kind == "chord" and r.chord == "LB+X" end)
    if not (first and B.chord) then Q.say("ERR setup_chords: no Quick actions rows"); return end
    B.o.scroll = math.max(0, first.y - ZeD.T.px(40))
    B.mark(B.chord)
end)
Q.step(30, function()
    if not (B.o and B.chord) then Q.notTaken("zqa_g3_setup_chords", "no Quick actions rows"); return end
    Q.say("setup: LB + X runs " .. tostring(ZeD.QuickChords and ZeD.QuickChords.get and ZeD.QuickChords.get("LB+X")))
    Q.shot("zqa_g3_setup_chords", { { "options", B.o } })
end)
Q.step(5, function()
    local o, f = B.o, B.chord
    if not (o and f) then return end
    local want = tostring(o.kind) .. ":r" .. f.i .. ":box"
    local hit = nil
    for _, h in ipairs(o._hits or {}) do if h.id == want then hit = h end end
    if hit and hit.fn then hit.fn(); Q.say("setup: the LB + X box clicked")
    else o:activateRow(f.r); Q.say("setup: no box hit (" .. want .. "): the row activated") end
end)
Q.step(30, function()
    if not (B.o and B.chord) then Q.notTaken("zqa_g3_setup_list", "no Quick actions rows"); return end
    Q.say("setup list: open " .. tostring(B.MM.ctx and B.MM.ctx.open))
    Q.shot("zqa_g3_setup_list", { { "options", B.o } })
end)
Q.step(5, function()
    if B.MM.ctx then B.MM.ctx.open = nil end
    B.MM.popup = nil
    if not B.o then return end
    B.putback = B.find(function(r) return r.labelKey == "UI_ZeD_Settings_PutBack" end)
    if not B.putback then return end
    local vh = (B.o._list and B.o._list.h) or ZeD.T.px(400)
    B.o.scroll = math.max(0, B.putback.y - math.floor((vh - B.putback.h) / 2))
    B.mark(B.putback)
end)
Q.step(30, function()
    if not (B.o and B.putback) then Q.notTaken("zqa_g3_setup_putback", "no Put things back row"); return end
    Q.shot("zqa_g3_setup_putback", { { "options", B.o } })
end)
Q.step(5, function()
    local o = B.o
    B.MM.forceGamepad = B.forceWas
    if o then o._cellRow = nil; o.focusId = nil; o.scroll = 0; B.unpin(o); pcall(function() o:finish() end) end
    if B.menuUp() then B.toggleMenu() end
end)
Q.step(20, function()
    pcall(function() B.Det.setLockedMode(nil) end)
    pcall(ZeD.Input.Focus.releaseFocus)
end)

-- ===================================================================== 73 Immersive or Simple (the same spot)
Q.step(10, function()
    C3.pairShut()
    B.setOpt(B.St.watchStyleOption, 2)
    B.setOpt(B.St.watchPlaceOption, 2)
    B.wear("DigitalBlack")
end)
Q.step(60, function() C3.park() end)
Q.step(10, function() Q.shot("gb_simple_watch") end)
Q.step(5, function()
    B.wear(nil)
    B.setOpt(B.St.watchStyleOption, 1)
    B.setOpt(B.St.watchPlaceOption, B.optWas.watchPlaceOption)
    B.setOpt(B.St.beltStyleOption, 2)
end)
Q.step(40, function() Q.shot("gb_simple_belt") end)
Q.step(5, function() B.setOpt(B.St.beltStyleOption, 1) end)
Q.step(10, function()
    B.setOpt(B.St.devicesStyleOption, 2)
    B.radio = B.give("Base.RadioBlack")
    local dd = B.radio and B.radio:getDeviceData()
    if dd then dd:setHasBattery(true); dd:setPower(0.8); dd:setIsTurnedOn(true); dd:setDeviceVolume(0.5); dd:setChannel(98000) end
    B.p:setPrimaryHandItem(nil); B.p:setSecondaryHandItem(nil); B.p:setPrimaryHandItem(B.radio)
    C3.pairOpen()
    Q.hold = C3.pairSide
end)
Q.waitFor(5, 200, function() local w = C3.CW(); local r = w and w._radios and w._radios[1]; return r ~= nil and r.radioInstance == B.radio end,
    function(ok) C3.charTab("radio") end)
Q.step(40, function()
    local w = C3.CW(); local t = w and w._radioTw
    B.hc, B.hw = w:getHeight(), C3.WW():getHeight()
    local need = (t and t.des and t.des.h or 0) + ZeD.T.px(40)
    if t and t.view and need > t.view.h then
        local add = need - t.view.h + 2
        w:setHeight(w:getHeight() + add); C3.WW():setHeight(C3.WW():getHeight() + add)
    end
end)
Q.still(30, function() Q.shot("gb_plain_radio") end)
Q.step(10, function()
    Q.hold = nil
    local w = C3.CW(); if B.hc then w:setHeight(B.hc); C3.WW():setHeight(B.hw) end
    pcall(function() B.radio:getDeviceData():setIsTurnedOn(false) end)
    B.p:setPrimaryHandItem(B.prim); B.p:setSecondaryHandItem(B.sec)
    B.setOpt(B.St.devicesStyleOption, 1)
    C3.charTab("loot")
    C3.pairShut()
end)
Q.step(10, function() if B.D.H and B.D.H.openSetup then B.D.H.openSetup(B.p, B.pn) end end)
Q.step(60, function()
    local w = B.opts()
    if not w then return end
    B.pin(w)
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    local y = 0
    for _, r in ipairs(w:rowsFor(w:pages()[w.pageIdx])) do
        if r.kind == "header" and tostring(r.text):lower() == ZeD.tr("UI_ZeD_Options_ZedForms"):lower() then break end
        y = y + (r._h or ZeD.T.px(30))
    end
    w.scroll = math.max(0, y - ZeD.T.px(6))
    B.formsOk = true
    C3.park()
end)
Q.step(40, function()
    if B.formsOk then Q.shot("gb_forms_setup", { { "options", B.opts() } }) else Q.notTaken("gb_forms_setup", "no ZeD setup window") end
end)
Q.step(10, function()
    local w = B.opts()
    if w then B.unpin(w); pcall(function() w:close() end) end
end)
Q.step(20, function() if B.menuUp() then B.toggleMenu() end end)
-- in the story's station wagon by the pump, engine running, the Simple dashboard
Q.waitFor(10, 600, function() return STORY and STORY.car and ZEDQA_CAR_READY and ZEDQA_CAR_READY(STORY.car) end, function(ok)
    local v = STORY and STORY.car
    if not (ok and v and ZEDQA_CAR_ENTER) then B.carWhy = "the story's car is not ready (or no prelude)"; return end
    B.key = ZEDQA_CAR_PREP and ZEDQA_CAR_PREP(v)
    local okE, why = ZEDQA_CAR_ENTER(v, 0)
    if not okE then B.carWhy = why; return end
    B.inside = true
    B.setOpt(B.St.dashStyleOption, 2)
    pcall(function() v:setKeysInIgnition(true) end)
    B.tries, B.t = 0, 0
end)
Q.waitFor(10, 1500, function()
    if not B.inside then return true end
    local v = STORY.car
    local run = false
    pcall(function() run = v:isEngineRunning() end)
    if run then return true end
    B.t = B.t + 1
    local q = ISTimedActionQueue.getTimedActionQueue(B.p)
    if not (q and q.queue and #q.queue > 0) and B.t % 60 == 1 and B.tries < 5 then
        B.tries = B.tries + 1
        pcall(function() ISVehicleMenu.onStartEngine(B.p) end)
    end
    return false
end, function(ok)
    if not B.inside then return end
    local run = false
    pcall(function() run = STORY.car:isEngineRunning() end)
    Q.say("engine running " .. tostring(run) .. " after " .. tostring(B.tries) .. " tries")
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st then
        if not d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
        if not d._st.lights then pcall(function() d:_fire("lights", false) end) end
    end
end)
Q.step(120, function() C3.park() end)
Q.step(10, function()
    if B.inside then Q.shot("gb_plain_dash") else Q.notTaken("gb_plain_dash", B.carWhy or "not in the car") end
end)
Q.step(10, function()
    if not B.inside then return end
    local v = STORY.car
    pcall(function() local d = ZeD.Dashboard.getInstance(); if d and d._st then if d._st.radioOn then d:_fire("pwr", false) end; if d._st.lights then d:_fire("lights", false) end end end)
    pcall(function() v:engineDoShuttingDown() end)
    pcall(function() v:setKeysInIgnition(false) end)
    pcall(function() v:exit(B.p); triggerEvent("OnExitVehicle", B.p) end)
    B.inside = false
    Q.say("out of the car: " .. tostring(B.p:getVehicle() == nil))
end)

-- ===================================================================== put back
Q.mark()
Q.step(20, function()
    Q.hold = nil
    B.MM.padState = B.padStateWas
    B.MM.forceGamepad = B.forceWas
    pcall(function() local w = B.opts(); if w then B.unpin(w); if w:isVisible() then w:close() end end end)
    if B.menuUp() then B.toggleMenu() end
    if B.inside and STORY and STORY.car then pcall(function() STORY.car:exit(B.p); triggerEvent("OnExitVehicle", B.p) end) end
    if B.key then pcall(function() local c = B.key:getContainer(); if c then c:Remove(B.key) end end) end
    B.wear(nil)
    for _, it in ipairs(B.given) do
        pcall(function() if B.p:getPrimaryHandItem() == it then B.p:setPrimaryHandItem(nil) end end)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    pcall(function() B.p:setPrimaryHandItem(B.prim); B.p:setSecondaryHandItem(B.sec) end)
    for k, v in pairs(B.optWas) do B.setOpt(B.St[k], v) end
    pcall(function() B.Det.setLockedMode(nil) end)
    pcall(ZeD.Input.Focus.releaseFocus)
    C3.listView(false)
    C3.theme(B.look[1], B.look[2], B.look[3])
    pcall(function() STORY.tp(B.home.x, B.home.y, B.home.z) end)
end)
Q.step(20, function()
    C3.backWins(B.wins)
    Q.say("put back: options, watch, radio, car key and seat, pause screen, input mode, look " .. tostring(ZeD.currentBase) .. " "
        .. tostring(ZeD.currentAccent) .. ", windows, place")
end)
Q.start()
