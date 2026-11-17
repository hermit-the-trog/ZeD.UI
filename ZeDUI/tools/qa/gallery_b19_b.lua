-- ZeDUI/tools/qa/gallery_b19_b.lua  (Nov 17 2026, QA): the beta 19 gallery recapture, second half
-- (ZeDUI/workshop/gallery/B19_RECAPTURE.md). Spreads 35, 38, 39, 40, 42, 45, 47, 48, 53, 54 and six new captures.
-- Run after gallery_b11_look.lua (Dark, PZ Teal, the debug readout off), gallery_daylight.lua, gallery_b10_glasses.lua
-- and gallery_hidecon.lua: see gallery_b19_b.txt. Each picture goes to Zomboid/Screenshots/<gallery name>.png (the
-- collect step moves it into gallery_t14 under the same name). The staging is the earlier scripts' own:
--   AT THE QA HOME (the drag strip, as the beta 13 pictures)
--     zqa_bub_both_dark            zedqa_bubbles.lua: windows shut, three apples queued, a line said while eating
--     gbw_DigitalBlack / DigitalTimez / ClassicGold / DigitalRed   gallery_belt_watches.lua: the watch on the belt, 13:00
--     zqa_g4_guide_bubble          zedqa_guide_bubble.lua step 2: the guide's balloon from the belt (first show at 1.5 s)
--     zqa_pr_01_sleep / 06_keyboard / 07_alarm   zedqa_prompts.lua: the sleep question, the rename box with the
--                                  keyboard ("Go Bag" + "s!"), Set Alarm on a stand-in alarm; each opened on the pointer
--     zqa_padmap_options           zedqa_pad_figure.lua "02_lit": Options > Controls > Button map and test, Xbox set
--     g19_generator_popout (new)   a generator placed beside the character, running, its face popped out (FacePop.open)
--     g19_espresso_popout (new)    Additional appliance support on, the espresso machine placed in the generator's
--                                  power, FacePop.open; "not taken" when the build has no face for it
--     gb_seat_cabin / gb_simple_seat (new)  zedqa_b16_seats.lua: a sedan (ZEDQA_CAR_WAIT), the seat key's own route
--                                  (ZeD.Seats.toggle) with the Dashboard row on Full, then on Simple
--     gb_plain_dash                gallery_beta_new.lua: the same sedan, Simple dashboard, engine running
--     g5_car_radio                 gallery_nov1_radio.lua: the CD receiver (Base.RadioRed) fitted, on and tuned, the
--                                  radio up close (ISVehicleMenu.onSignalDevice). (The drag strip, not the mall lot.)
--     zqa_b19_ask_cancel (new)     zedqa_b17_inv.lua 249: a trash can with three things, A on Remove all: the
--                                  question opens with the pad on Cancel
--     zqa_b19_window_menu (new)    zedqa_b19_pad.lua 228p: the Character window's menu opened with the stand-in pad
--                                  (Bug report, Controller map, Hide interface), the pad on Controller map
--   AWAY (gallery_b11_away.lua's open ground about 70 squares off, as the beta 13 pictures)
--     zqa_g4_belt_toast / zqa_g4_window_radio   zedqa_gallery_t4.lua: two made-up mods' notes, the toast, the window
--     zqa_g3_wheel_character_eat / now_light / use_smoke, zqa_g3_footer_pad   zedqa_gallery_t3.lua (+ r1b_icons:
--                                  the windows away first, then ISDPadWheels.onDisplayLeft)
--     gb_simple_watch / gb_simple_belt / gb_plain_radio / gb_forms_setup   gallery_beta_new.lua
--   NOT HERE (main menu only, pushed by gallery_b11_menus_run.ps1): desk_05_trash_computer (gallery_desk_pass.lua),
--     mm4_01_options_zed / mm4_02_options_interface / mm4_03_options_hidden (gallery_beta_hidden.lua, gallery_v4_menus.lua)
-- Before each shot: about 30 frames to settle, the pointer parked top left (unless the shot needs it), the debug
-- console hidden, god mode and invisible off (zombies-don't-attack on instead), the inventory weight printed.
-- No controller here: pad-only views use a stand-in pad record for one call (withPad) or Focus.qaButton.
-- Puts back: theme, options, items given, objects and the car, the window layout, the time of day, game speed, god
-- mode / invisible / zombies-don't-attack, the character's place. grep "ZEDQA gb19b".
local S = { Q = {}, qi = 1, held = {}, given = {}, placed = {}, took = {}, skipped = {} }
S.p = getPlayer()
S.pn = S.p:getPlayerNum()
S.inv = S.p:getInventory()
S.CW, S.WW = ZeD_CharacterWindow, ZeD_WorldWindow
S.St = ZeD.Settings
S.Focus = ZeD.Input and ZeD.Input.Focus
S.Det = ZeD.Input and ZeD.Input.Detector
S.D, S.W = ZeD.DpadWheels, ZeD.Wheel
S.MS, S.MW = ZeD.Messages, ZeD.MessagesWindow
S.MM = ZeD.MainMenu

function S.say(s) print("ZEDQA gb19b " .. tostring(s)) end
function S.step(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end
function S.cw() return S.CW.getWindow(S.pn) end
function S.ww() return S.WW.getWindow(S.pn) end
function S.notTaken(name, why) S.skipped[#S.skipped + 1] = name; S.say("not taken: " .. name .. " (" .. tostring(why) .. ")") end

-- ---------------------------------------------------------------- the look before a shot
function S.console()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end end
    end)
end
function S.cheats()
    pcall(function() S.p:setGodMod(false) end)
    pcall(function() S.p:setInvisible(false) end)
    pcall(function() S.p:setZombiesDontAttack(true) end)
end
function S.park() pcall(function() Mouse.setXY(20, 20) end) end
-- the pointer off the windows, hover tooltips gone, no item card left in a drawer
function S.pre(keepPointer)
    if not keepPointer then S.park() end
    pcall(function() local m = getPlayerContextMenu(S.pn); if m and m:isVisible() then m:setVisible(false) end end)
    S.console(); S.cheats()
end
function S.shot(name)
    S.console(); S.cheats()
    local ok = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    local wt, cap = "?", "?"
    pcall(function() wt = string.format("%.1f", S.inv:getCapacityWeight()); cap = string.format("%.1f", S.p:getMaxWeight()) end)
    if ok then S.took[#S.took + 1] = name end
    S.say((ok and "shot " or "ERR shot ") .. name .. " (carried " .. wt .. " of " .. cap .. ")")
end
function S.pairShut() if S.CW.isOpen(S.pn) then pcall(S.CW.toggleBothPaired, S.pn) end end
function S.pairOpen() if not S.CW.isOpen(S.pn) then pcall(S.CW.toggleBothPaired, S.pn) end end
function S.give(ft) local it = S.inv:AddItem(ft); if it then S.given[#S.given + 1] = it end; return it end
function S.stopAll() pcall(function() S.p:StopAllActionQueue() end) end
function S.sq(dx, dy) return getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end
function S.moveTo(x, y, z)
    pcall(function() S.p:setX(x); S.p:setY(y); S.p:setZ(z); S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z) end)
end
function S.unplace(o)
    pcall(function() if o.setActivated and o:isActivated() then o:setActivated(false) end end)
    pcall(function() local sq = o:getSquare(); if sq then sq:transmitRemoveItemFromSquare(o) end end)
    pcall(function() local sq = o:getSquare(); if sq then sq:RemoveTileObject(o) end end)
    pcall(function() if instanceof(o, "IsoGenerator") then o:remove() end end)
end
function S.setOpt(o, v) if o and v then pcall(function() o:setValue(v) end) end end
function S.lock(on) pcall(function() if on then S.Det.setLockedMode(S.Det.MODE_GAMEPAD or "gamepad") else S.Det.setLockedMode(S.Det.MODE_KBM or "kbm"); S.Det.setLockedMode(nil) end end) end

-- the stand-in pad: in JoypadState only for the call
S.fake = { player = S.pn, focus = nil }
function S.withPad(fn, ...)
    if JoypadState.players[S.pn + 1] then S.say("note: a real pad is bound; the stand-in is not used"); return fn(...) end
    JoypadState.players[S.pn + 1] = S.fake
    local ok, r = pcall(fn, ...)
    JoypadState.players[S.pn + 1] = nil
    pcall(setPlayerButtonsActive, S.pn, true)
    pcall(setJoypadIgnoreAim, S.pn, false)
    if not ok then S.say("ERR withPad: " .. tostring(r)) end
    return r
end

-- the watch worn now, kept to put back
function S.findKit()
    pcall(function()
        local worn = S.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local wi = worn:get(i)
            if instanceof(wi:getItem(), "AlarmClockClothing") then S.kit, S.kitLoc = wi:getItem(), wi:getLocation() end
        end
    end)
end
function S.wear(name)
    if S.curWatch then pcall(function() S.p:removeWornItem(S.curWatch, false); S.inv:Remove(S.curWatch) end); S.curWatch = nil end
    if S.kit then pcall(function() S.p:removeWornItem(S.kit, false) end) end
    if not name then
        if S.kit then pcall(function() S.p:setWornItem(S.kitLoc, S.kit) end) end
        return
    end
    pcall(function()
        S.curWatch = S.inv:AddItem("Base.WristWatch_Left_" .. name)
        S.p:setWornItem(S.curWatch:getBodyLocation(), S.curWatch)
    end)
end

-- ===================================================================== setup
S.step(10, function()
    local p, St = S.p, S.St
    S.look = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
    S.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    S.speedWas = getGameSpeed()
    S.godWas = p:isGodMod()
    pcall(function() S.invisWas = p:isInvisible() end)
    pcall(function() S.zdaWas = p:isZombiesDontAttack() end)
    S.todWas = getGameTime():getTimeOfDay()
    S.optWas = {}
    for _, k in ipairs({ "watchPlaceOption", "watchStyleOption", "dashStyleOption", "devicesStyleOption", "beltStyleOption",
                         "glyphOption", "gridTintOption", "appliancesOption", "safeModeOption", "messagesCatchOption", "messagesToastOption" }) do
        local o = St[k]
        if o then S.optWas[k] = o:getValue() end
    end
    if ZEDQA_LAYOUT_SNAP then S.snap = ZEDQA_LAYOUT_SNAP() end
    S.findKit()
    -- Full everywhere, tiles plain, safe mode off (the rows' defaults)
    S.setOpt(St.gridTintOption, 1); S.setOpt(St.devicesStyleOption, 1); S.setOpt(St.dashStyleOption, 1)
    S.setOpt(St.beltStyleOption, 1); S.setOpt(St.watchStyleOption, 1); S.setOpt(St.safeModeOption, 1)
    pcall(function() ZeD.applyTheme((GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "teal", S.look[3]) end)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "gb19b") end
    if ZEDQA_SPEED then ZEDQA_SPEED(1) elseif getGameSpeed() ~= 1 then setGameSpeed(1) end
    S.cheats(); S.console()
    S.say("start at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. " | look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent)
        .. " | kit watch " .. tostring(S.kit and S.kit:getFullType()))
end)

-- ===================================================================== 35 bubbles: zqa_bub_both_dark (home)
S.step(10, function() S.pairShut(); S.stopAll() end)
S.step(30, function()
    for _ = 1, 3 do local it = S.give("Base.Apple"); if it then pcall(ISInventoryPaneContextMenu.eatItem, it, 0.25, S.pn) end end
end)
S.step(90, function() S.pre(); S.p:Say("Don't even think about it.") end)
S.step(30, function() S.shot("zqa_bub_both_dark") end)
S.step(10, function() S.stopAll() end)

-- ===================================================================== 38 watches: gbw_* (home)
S.step(300, function()   -- (the line said above runs out first)
    S.pairShut()
    S.setOpt(S.St.watchPlaceOption, 1)   -- the watch on the belt
    getGameTime():setTimeOfDay(13.0)
end)
for _, name in ipairs({ "DigitalBlack", "DigitalTimez", "ClassicGold", "DigitalRed" }) do
    S.step(10, function() S.wear(name) end)
    S.step(60, function() S.pre() end)
    S.step(30, function() S.shot("gbw_" .. name) end)
end
S.step(10, function()
    S.wear(nil)
    S.setOpt(S.St.watchPlaceOption, S.optWas.watchPlaceOption)
    getGameTime():setTimeOfDay(S.todWas)
end)

-- ===================================================================== 39 messages: zqa_g4_guide_bubble (home)
S.GB = { file = "ZeD_guidebubble.txt" }
function S.gbToast()
    local G = ZeD.GuideBubble
    for _, x in ipairs(S.MS.toasts or {}) do if x.source == G.head() then return x end end
end
function S.gbFlag(s) pcall(function() local w = getFileWriter(S.GB.file, true, false); w:write(s or ""); w:close() end) end
S.step(20, function()
    local G = ZeD.GuideBubble
    if not (G and S.MS and ZeD.Guide) then S.notTaken("zqa_g4_guide_bubble", "the guide bubble is not loaded"); return end
    S.GB.ok = true
    S.GB.const = { G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS }
    pcall(function() local r = getFileReader(S.GB.file, false); if r then S.GB.flag = r:readLine(); r:close() end end)
    S.GB.option = getCore():getOptionShowSurvivalGuide()
    S.GB.sources, S.GB.toasts = S.MS.sources, S.MS.toasts
    S.MS.sources, S.MS.toasts = {}, {}
    S.pairShut()
    G.FIRST_MS = 1500
    S.gbFlag("")
    getCore():setOptionShowSurvivalGuide(true)
    G.start()
    S.t = 0
end)
S.step(10, function()   -- (up to about 20 s for the balloon)
    if not S.GB.ok then return end
    S.t = S.t + 1
    if not S.gbToast() and S.t < 120 then return true end
    if not S.gbToast() then S.notTaken("zqa_g4_guide_bubble", "the balloon never came up"); S.GB.ok = false; return end
    S.pre()
end)
S.step(90, function() if S.GB.ok then S.shot("zqa_g4_guide_bubble") end end)
S.step(10, function()
    local G = ZeD.GuideBubble
    if not S.GB.const then return end
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = S.GB.const[1], S.GB.const[2], S.GB.const[3], S.GB.const[4]
    G.st = nil
    S.gbFlag(S.GB.flag or "")
    pcall(function() getCore():setOptionShowSurvivalGuide(S.GB.option) end)
    S.MS.sources, S.MS.toasts = S.GB.sources or {}, S.GB.toasts or {}
    pcall(function() if ZeD.Guide.windows and ZeD.Guide.windows[0] and ZeD.Guide.windows[0]:isReallyVisible() then ZeD.Guide.toggle(0) end end)
end)

-- ===================================================================== 40 questions: zqa_pr_01 / 06 / 07 (home, windows open)
S.alarm = { h = 6, m = 30, on = true }
function S.alarm:getHour() return self.h end
function S.alarm:getMinute() return self.m end
function S.alarm:isAlarmSet() return self.on end
function S.alarm:setHour(v) self.h = v end
function S.alarm:setMinute(v) self.m = v end
function S.alarm:setAlarmSet(v) self.on = v end
function S.alarm:syncAlarmClock() end
function S.noop() end
function S.center() pcall(function() Mouse.setXY(math.floor(getCore():getScreenWidth() / 2), math.floor(getCore():getScreenHeight() / 2)) end) end
S.step(10, function() S.pairOpen(); pcall(function() ZeD.Prompt.qaJoy = nil end) end)
S.step(30, function()
    S.center()
    S.cur = ISModalDialog:new(0, 0, 250, 150, getText("IGUI_ConfirmSleep"), true, nil, S.noop, 0, S.p, nil)
    S.cur:initialise(); S.cur:addToUIManager()
end)
S.step(15, function() S.pre() end)
S.step(30, function() S.shot("zqa_pr_01_sleep") end)
S.step(10, function() pcall(function() S.cur:answerCancel() end) end)
S.step(20, function()
    S.center()
    S.bag = S.give("Base.Bag_DuffelBag")
    S.bagName = S.bag and S.bag:getName()
    if S.bag then pcall(ISInventoryPaneContextMenu.onRenameBag, S.bag, S.pn) end
    S.cur = ZeD.Prompt and ZeD.Prompt.open and ZeD.Prompt.open[#ZeD.Prompt.open]
    if not (S.cur and S.cur.entry) then
        S.cur = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_NameThisBag"), "Duffel Bag", nil, S.noop, 0)
        S.cur:initialise(); S.cur:addToUIManager()
    end
end)
S.step(20, function()
    S.cur.entry:setText("Go Bag")
    pcall(function() OnScreenKeyboard.Show(0, S.cur.entry, nil) end)
end)
S.step(20, function()
    pcall(function() local k = ZeD.Keyboard.instance; k:pressKey({ lo = "s", up = "S" }); k:pressKey({ lo = "!", up = "!" }) end)
    S.say("typed: " .. tostring(S.cur.entry:getText()))
    S.pre()
end)
S.step(30, function() S.shot("zqa_pr_06_keyboard") end)
S.step(10, function() pcall(function() ZeD.Keyboard.instance:cancel() end) end)
S.step(15, function()
    pcall(function() S.cur.entry:setText(S.bagName or "Duffel Bag") end)
    if not pcall(function() S.cur:answerCancel() end) then pcall(function() S.cur:pressPrimary() end) end
end)
S.step(20, function()
    S.center()
    S.cur = ISAlarmClockDialog:new(0, 0, 230, 160, S.pn, S.alarm)
    S.cur:initialise(); S.cur:addToUIManager()
end)
S.step(15, function() S.pre() end)
S.step(30, function() S.shot("zqa_pr_07_alarm") end)
S.step(10, function() pcall(function() S.cur:press(S.cur.ok) end) end)

-- ===================================================================== 47 controller map: zqa_padmap_options (pause menu)
function S.menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
function S.toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
S.step(10, function()
    for i, k in ipairs(S.St.glyphKeys or {}) do if k == "xbox" then S.St.glyphOption:setValue(i) end end
    if not S.menuUp() then S.toggleMenu() end
end)
S.step(50, function() pcall(S.MM.openOptions) end)
S.step(50, function()
    local w = S.MM.pauseOpts
    if not (w and w:isVisible()) then S.notTaken("zqa_padmap_options", "no in-game Options window"); return end
    pcall(function() w:openVanillaController() end)
end)
S.step(70, function()
    S.padWas = S.MM.padState
    S.MM.padState = function()
        return { b = { A = true, DL = true, RB = true, L3 = true }, ls = { 0.6, -0.4 }, rs = { 0, 0 }, lt = 0.6, rt = 0 }
    end
    S.pre()
end)
S.step(40, function()
    local w = S.MM.pauseOpts
    if w and w.sub == "pad" and w._padFig then S.shot("zqa_padmap_options")
    elseif w then S.notTaken("zqa_padmap_options", "Button map and test did not open (" .. tostring(w.sub) .. ")") end
    if S.padWas then S.MM.padState = S.padWas end
end)
S.step(10, function() pcall(function() S.MM.pauseOpts:close() end) end)
S.step(20, function()
    if S.menuUp() then S.toggleMenu() end
    S.setOpt(S.St.glyphOption, S.optWas.glyphOption)
end)

-- ===================================================================== new: g19_generator_popout, g19_espresso_popout (home)
S.FP, S.TF = ZeD.FacePop, ZeD.TwoWayFull
S.step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    S.pairOpen()
    if not (S.FP and S.TF) then S.notTaken("g19_generator_popout", "the pop-outs are not loaded"); return end
    local ok, e = pcall(function()
        local g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), S.sq(2, 0))
        g:setConnected(true); g:setFuel(60); pcall(function() g:setCondition(90) end)
        g:setActivated(true)
        S.gen = g; S.placed[#S.placed + 1] = g
    end)
    if not ok then S.say("ERR placing the generator: " .. tostring(e)) end
end)
S.step(60, function()
    if not S.gen then return end
    S.say("generator running " .. tostring(S.gen:isActivated()) .. ", faces on " .. tostring(S.FP.on()))
    if not S.FP.open(S.p, S.gen) then S.notTaken("g19_generator_popout", "FacePop.open gave false"); S.genOff = true end
end)
S.step(30, function() if S.gen and not S.genOff then S.pre() end end)
S.step(30, function()
    if not (S.gen and not S.genOff) then return end
    local v = S.TF.get(S.pn)
    if v and v:isReallyVisible() then S.shot("g19_generator_popout") else S.notTaken("g19_generator_popout", "the pop-out is not on screen") end
    pcall(S.TF.close, S.pn)
end)
S.step(10, function()
    S.setOpt(S.St.appliancesOption, 2)
    local sq = S.sq(-1, 1)
    if not sq then S.notTaken("g19_espresso_popout", "no square beside the character"); return end
    local o = IsoObject.new(sq, "appliances_cooking_01_61", nil, false)
    sq:AddTileObject(o)
    S.esp = o; S.placed[#S.placed + 1] = o
end)
S.step(40, function()
    if not S.esp then return end
    local A = ZeD.Appliances
    local pw = A and A.powered and A.powered(S.esp:getSquare())
    S.say("espresso: appliance support " .. tostring(A and A.on and A.on()) .. ", powered " .. tostring(pw) .. ", offered " .. tostring(A and A.isEspresso and A.isEspresso(S.esp)))
    local ok, opened = pcall(S.FP.open, S.p, S.esp)
    if not (ok and opened) then
        S.notTaken("g19_espresso_popout", "FacePop has no face for the espresso machine in this build (FacePop.resolve knows ovens, microwaves, radios, generators, the grill and laundry; Appliances.lua: its face is still to be drawn)")
        S.espOff = true
    else S.pre() end
end)
S.step(30, function()
    if not S.esp or S.espOff then return end
    S.shot("g19_espresso_popout")
    S.say("note: g19_espresso_popout is at the drag strip beside the generator, not in a kitchen")
    pcall(S.TF.close, S.pn)
end)
S.step(10, function()
    for _, o in ipairs(S.placed) do S.unplace(o) end
    S.placed, S.gen, S.esp = {}, nil, nil
    S.setOpt(S.St.appliancesOption, S.optWas.appliancesOption)
end)

-- ===================================================================== 45 + 42: the sedan (home)
S.Car = {}
S.step(20, function()
    S.pairShut()
    if not ZEDQA_CAR_WAIT then S.Car.why = "no ZEDQA_CAR_WAIT (run the prelude first)"; return end
    ZEDQA_CAR_WAIT("Base.CarNormal", "gb19b", function(v) S.Car.v = v end, function(why) S.Car.why = why or "no car" end)
    S.t = 0
end)
S.step(10, function()
    S.t = S.t + 1
    if not (S.Car.v or S.Car.why) and S.t < 120 then return true end
    if not S.Car.v then
        S.Car.why = S.Car.why or "the car never got ready"
        for _, n in ipairs({ "gb_seat_cabin", "gb_simple_seat", "gb_plain_dash", "g5_car_radio" }) do S.notTaken(n, S.Car.why) end
        return
    end
    S.moveTo(S.Car.v:getX() + 2.5, S.Car.v:getY() + 0.5, S.Car.v:getZ())
    S.setOpt(S.St.dashStyleOption, 1)
end)
S.step(30, function()
    if not S.Car.v then return end
    local ok, e = pcall(ZeD.Seats.toggle, S.p, S.Car.v)
    if not ok then S.say("ERR seat key: " .. tostring(e)) end
end)
S.step(10, function() S.pre() end)
S.step(30, function()
    if not S.Car.v then return end
    local sp = ZeD.Seats.getPopout and ZeD.Seats.getPopout(S.pn)
    if sp and sp:isReallyVisible() then S.shot("gb_seat_cabin"); sp:close()
    else
        S.notTaken("gb_seat_cabin", "the seat key opened the window, not the cabin (see the [ZeD] SeatPopout line)")
        pcall(function() local w = ZeD.Seats.windows[S.pn]; if w and w:isReallyVisible() then w:close() end end)
    end
end)
S.step(20, function()
    if not S.Car.v then return end
    S.setOpt(S.St.dashStyleOption, 2)
    local ok, e = pcall(ZeD.Seats.toggle, S.p, S.Car.v)
    if not ok then S.say("ERR seat key (Simple): " .. tostring(e)) end
end)
S.step(10, function() S.pre() end)
S.step(30, function()
    if not S.Car.v then return end
    local w = ZeD.Seats.windows and ZeD.Seats.windows[S.pn]
    if w and w:isReallyVisible() then S.shot("gb_simple_seat"); w:close()
    else S.notTaken("gb_simple_seat", "no seat window with the Dashboard row on Simple") end
    pcall(function() local sp = ZeD.Seats.getPopout(S.pn); if sp and sp:isReallyVisible() then sp:close() end end)
end)
-- in the driver's seat, engine running, the Simple dashboard
S.step(20, function()
    if not S.Car.v then return end
    S.Car.key = ZEDQA_CAR_PREP and ZEDQA_CAR_PREP(S.Car.v)
    local ok, why = ZEDQA_CAR_ENTER(S.Car.v, 0)
    if not ok then
        S.Car.inWhy = why
        for _, n in ipairs({ "gb_plain_dash", "g5_car_radio" }) do S.notTaken(n, why) end
        return
    end
    S.Car.inside = true
end)
S.step(20, function() if S.Car.inside then pcall(function() S.Car.v:setKeysInIgnition(true) end); S.t, S.Car.tries = 0, 0 end end)
S.step(10, function()   -- (the engine: up to 5 tries, about 25 s)
    if not S.Car.inside then return end
    S.t = S.t + 1
    local run = false
    pcall(function() run = S.Car.v:isEngineRunning() end)
    if run or S.t > 150 then S.say("engine running " .. tostring(run)); return end
    local q = ISTimedActionQueue.getTimedActionQueue(S.p)
    if not (q and q.queue and #q.queue > 0) and S.t % 12 == 1 and S.Car.tries < 5 then
        S.Car.tries = S.Car.tries + 1
        pcall(function() ISVehicleMenu.onStartEngine(S.p) end)
    end
    return true
end)
S.step(20, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if S.Car.inside and d and d._st then
        if not d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
        if not d._st.lights then pcall(function() d:_fire("lights", false) end) end
    end
end)
S.step(120, function() if S.Car.inside then S.pre() end end)
S.step(30, function() if S.Car.inside then S.shot("gb_plain_dash") end end)
-- the CD receiver up close, the Full dashboard
S.step(10, function()
    if not S.Car.inside then return end
    S.setOpt(S.St.dashStyleOption, 1)
    local v = S.Car.v
    local part = v:getPartById("Radio")
    if not part then S.notTaken("g5_car_radio", "the sedan has no Radio part"); S.Car.noRadio = true; return end
    S.Car.part = part
    local ok, e = pcall(function()
        part:setInventoryItem(instanceItem("Base.RadioRed"))
        Vehicles.InstallComplete.Radio(v, part)
        local dd = part:getDeviceData()
        if dd and dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
    end)
    if not ok then S.notTaken("g5_car_radio", "could not fit the CD receiver: " .. tostring(e)); S.Car.noRadio = true end
end)
S.step(60, function()
    if not S.Car.inside or S.Car.noRadio then return end
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st and not d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    pcall(function() ZeD.RadioOps.setChannel(S.p, S.Car.part, 101200) end)
    pcall(function() ZeD.RadioOps.run("SetVolume", S.p, S.Car.part, 0.6) end)
end)
S.step(90, function() if S.Car.inside and not S.Car.noRadio then pcall(function() ISVehicleMenu.onSignalDevice(S.p, S.Car.part) end) end end)
S.step(30, function() if S.Car.inside and not S.Car.noRadio then S.pre() end end)
S.step(30, function()
    if not S.Car.inside or S.Car.noRadio then return end
    local CR = ZeD.CarRadio
    local pr = CR and CR.props and CR.props[S.pn]
    if pr and pr:isReallyVisible() then
        S.shot("g5_car_radio")
        S.say("note: g5_car_radio is a sedan at the drag strip (the beta 13 picture: the station wagon in the mall lot)")
    else S.notTaken("g5_car_radio", "the car radio did not come up") end
    pcall(function() CR.closeFor(S.pn) end)
end)
S.step(10, function()
    if not S.Car.v then return end
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if S.Car.inside and d and d._st and d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    pcall(function() if S.Car.v:isEngineRunning() then S.Car.v:shutOff() end end)
end)
S.step(30, function()
    if not S.Car.v then return end
    if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(S.Car.v, S.Car.key) end
    S.setOpt(S.St.dashStyleOption, 1)
end)
S.step(40, function() S.moveTo(S.home.x, S.home.y, S.home.z) end)

-- ===================================================================== 40 new: zqa_b19_ask_cancel (home)
function S.fresh(w) if w and w._focusFresh then pcall(w._focusFresh, w) end end
function S.stops(w, pred)
    S.fresh(w)
    local out = {}
    for _, z in ipairs(w and w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if pred(e, z) then out[#out + 1] = { e = e, z = z } end end
    end
    return out
end
function S.focusOn(w, pred)
    local hit = S.stops(w, pred)[1]
    if not hit then return nil end
    local e, z, id = hit.e, hit.z, hit.e.id
    S.Focus.claimFocus(w)
    if S.Focus.focusWhere(w, z.zone, function(x) if id ~= nil then return x.id == id end; return x == e end) then return e end
    for zi, zz in ipairs(w._focusRing) do
        if zz == z then w._focusIdx = zi; for ei, x in ipairs(z.elements) do if x == e then z.focusedElementIdx = ei end end end
    end
    return e
end
function S.tap(w, btn, name)
    S.Focus.dispatchJoypadDown(w, btn)
    if name then S.Focus.qaButton(name, false, S.pn); S.held[#S.held + 1] = name end
end
function S.letGo() for _, n in ipairs(S.held) do pcall(S.Focus.qaButton, n, nil, S.pn) end; S.held = {} end
function S.spec(e)
    local cc = S.ww()._mainContent and S.ww()._mainContent._cc
    local h = e and e.ccIdx and cc and cc.hits and cc.hits[e.ccIdx]
    return h and h.spec and h.spec.id
end
function S.askUp() local cc = S.ww()._mainContent and S.ww()._mainContent._cc; return cc and cc.ask ~= nil end
S.T = {}
S.step(10, function()
    S.pairOpen()
    if not (S.Focus and S.Focus.qaButton and S.Focus.dispatchJoypadDown) then S.notTaken("zqa_b19_ask_cancel", "Focus.qaButton is not loaded"); return end
    S.lock(true)
    S.T.sq = S.sq(1, 0)
    for n = 0, 23 do
        local name = "trashcontainers_01_" .. n
        local spr = S.T.sq and getSprite(name)
        local props = spr and spr:getProperties()
        if props and props:has("IsTrashCan") then
            local o = IsoObject.new(S.T.sq, name, nil, false)
            S.T.sq:AddTileObject(o)
            pcall(function() o:createContainersFromSpriteProperties() end)
            local inv = o:getContainer()
            if inv then
                pcall(function() inv:setExplored(true) end)
                S.T.obj, S.T.inv = o, inv
                for _, t in ipairs({ "Base.Eraser", "Base.Tweezers", "Base.Corkscrew" }) do inv:AddItem(t) end
                break
            end
            pcall(function() S.T.sq:transmitRemoveItemFromSquare(o) end); pcall(function() S.T.sq:RemoveTileObject(o) end)
        end
    end
    if not S.T.inv then S.notTaken("zqa_b19_ask_cancel", "no trash can could be placed") end
end)
S.step(75, function()   -- (the World window looks for containers every 30 frames)
    if not S.T.inv then return end
    local w = S.ww()
    S.T.wTab = w._activeTab
    local on = w._containers and w._containers[w._activeContainer or 1]
    S.T.onShow = on and on.inventory
    S.WW.openTab(S.pn, "loot")
    local st = S.stops(w, function(e, z) return z.zone == "worldContainerStrip" and e.inventory == S.T.inv end)[1]
    if st and st.e.onActivate then st.e.onActivate(w, st.e) end
end)
S.step(30, function()
    if not S.T.inv then return end
    S.T.on = S.focusOn(S.ww(), function(e, z) return z.zone == "worldCtl" and S.spec(e) == "trash" end) ~= nil
    if not S.T.on then S.notTaken("zqa_b19_ask_cancel", "Remove all is not a stop"); return end
    S.tap(S.ww(), Joypad.AButton, "A")
end)
S.step(10, function() if S.T.on then S.pre() end end)
S.step(30, function()
    if not S.T.on then return end
    local e = S.Focus.getFocusedElement(S.ww())
    if S.askUp() and e and e.ccKey == "no" then S.shot("zqa_b19_ask_cancel")
    else S.notTaken("zqa_b19_ask_cancel", "the question is not up with the pad on Cancel (" .. tostring(e and e.ccKey) .. ")") end
    S.tap(S.ww(), Joypad.BButton)
end)
S.step(20, function()
    if S.askUp() then pcall(S.tap, S.ww(), Joypad.BButton) end
    if S.T.obj then pcall(function() S.T.inv:removeAllItems(); S.T.sq:transmitRemoveItemFromSquare(S.T.obj) end); pcall(function() S.T.sq:RemoveTileObject(S.T.obj) end) end
    if S.T.wTab then pcall(S.WW.openTab, S.pn, S.T.wTab) end
    local w = S.ww()
    local st = S.T.onShow and S.stops(w, function(e, z) return z.zone == "worldContainerStrip" and e.inventory == S.T.onShow end)[1]
    if st and st.e.onActivate then pcall(st.e.onActivate, w, st.e) end
    pcall(S.Focus.releaseFocus, S.pn)
    S.lock(false)
end)

-- ===================================================================== 47 new: zqa_b19_window_menu (home)
S.step(20, function()
    S.pairOpen()
    local WM, cw = ZeD.WindowMenu, S.cw()
    if not (WM and cw) then S.notTaken("zqa_b19_window_menu", "no window menu"); return end
    S.lock(true)
    S.withPad(function() WM.open(cw) end)
    local m = WM.current
    local cm = ZeD.tr("UI_ZeD_Wheel_ControllerMap")
    local names = {}
    pcall(function()
        local top = m._levels[1]
        for ri, r in ipairs(top.rows) do
            if r.def then names[#names + 1] = tostring(r.def.name) end
            if r.def and r.def.name == cm then top.sel = ri end
        end
    end)
    S.say("window menu: " .. table.concat(names, " | "))
    S.WMok = m ~= nil
end)
S.step(10, function() if S.WMok then S.pre() end end)
S.step(30, function()
    if not S.WMok then return end
    S.shot("zqa_b19_window_menu")
    pcall(function() ZeD.WindowMenu.current:close() end)
    pcall(S.Focus.releaseFocus, S.pn)
    S.lock(false)
end)

-- ===================================================================== AWAY: the open ground about 70 squares off
S.OFFS = { { 70, 0 }, { -70, 0 }, { 0, 70 }, { 0, -70 }, { 110, 0 }, { -110, 0 } }
S.away = { k = 0 }
S.step(10, function() S.pairShut(); S.stopAll() end)
S.step(90, function()   -- (each try: there, 90 frames for the ground to load, then judged)
    local a = S.away
    if a.k > 0 then
        local x, y = math.floor(S.home.x) + S.OFFS[a.k][1], math.floor(S.home.y) + S.OFFS[a.k][2]
        local ok = true
        for dx = -12, 12, 3 do for dy = -12, 12, 3 do
            local sq = getCell():getGridSquare(x + dx, y + dy, 0)
            if not sq or not sq:getFloor() or sq:getBuilding() then ok = false end
        end end
        S.say(string.format("away %d,%d open %s", S.OFFS[a.k][1], S.OFFS[a.k][2], tostring(ok)))
        if ok then pcall(function() S.p:setDir(IsoDirections.S) end); a.found = true; return end
    end
    a.k = a.k + 1
    if a.k > #S.OFFS then S.say("no open ground found; the away pictures are taken at the home"); S.moveTo(S.home.x, S.home.y, 0); return end
    S.moveTo(math.floor(S.home.x) + S.OFFS[a.k][1] + 0.5, math.floor(S.home.y) + S.OFFS[a.k][2] + 0.5, 0)
    return true
end)

-- ===================================================================== 39 messages: zqa_g4_belt_toast, zqa_g4_window_radio (away)
S.RADIO, S.FARM = "Sample Radio Plus", "Sample Farm Map"
function S.note(src, text, rich)
    S.MS.qaSource = src
    local d
    if rich then d = ISModalRichText:new(0, 0, 420, 300, text, false, {}, S.noop, S.pn)
    else d = ISModalDialog:new(0, 0, 320, 150, text, false, {}, S.noop, S.pn) end
    d:initialise(); d:addToUIManager()
    S.MS.qaSource = nil
end
S.step(30, function()
    S.pairShut()
    S.msgWas = { S.MS.sources, S.MS.toasts }
    S.MS.sources, S.MS.toasts = {}, {}
    S.setOpt(S.St.messagesCatchOption, 2); S.setOpt(S.St.messagesToastOption, 2)
    S.park()
end)
S.step(10, function()
    S.note(S.RADIO, "<H1> Sample Radio Plus 2.1 <LINE> <TEXT> New in this version: the scanner remembers the last ten stations it found. <LINE> <LINE> Hold R beside any radio to scan.", true)
    S.note(S.RADIO, "Sample Radio Plus: your saved stations were moved to the new list.")
end)
S.step(40, function()
    S.note(S.FARM, "<H1> Welcome to Sample Farm <LINE> <TEXT> The farmhouse keys are in the mailbox by the road. The barn's generator needs fuel before the first winter.", true)
    S.pre()
end)
S.step(25, function() S.shot("zqa_g4_belt_toast") end)
S.step(10, function() S.MW.open(S.pn, S.FARM) end)
S.step(30, function() local w = S.MW.get(S.pn); if w then w:choose(S.RADIO) end end)
S.step(30, function() S.pre() end)
S.step(30, function() S.shot("zqa_g4_window_radio") end)
S.step(10, function()
    local w = S.MW.get(S.pn)
    if w then pcall(function() w:close() end) end
    S.MS.sources, S.MS.toasts = S.msgWas[1] or {}, S.msgWas[2] or {}
    S.setOpt(S.St.messagesCatchOption, S.optWas.messagesCatchOption); S.setOpt(S.St.messagesToastOption, S.optWas.messagesToastOption)
end)

-- ===================================================================== 48 wheels and the footer (away)
function S.closeWheel()
    pcall(function()
        local st = S.D.state[S.pn]
        if st and st.menu and st.menu.undisplay then st.menu:undisplay() end
        S.D.state[S.pn] = nil
        local m = getPlayerRadialMenu(S.pn)
        if m and m:isReallyVisible() then m:undisplay() end
    end)
    S.W.qaPoint = nil
end
function S.sliceOf(word, dflt)
    local m = getPlayerRadialMenu(S.pn)
    for i, s in ipairs((m and m.slices) or {}) do if tostring(s.text or ""):find(word, 1, true) == 1 then return i end end
    return dflt
end
S.step(20, function()
    S.lock(true)
    pcall(S.Focus.releaseFocus)
    S.pairShut()
    pcall(S.Focus.releaseFocus)
    pcall(function() setJoypadFocus(S.pn, nil) end)
    S.park()
end)
S.step(20, function() ISDPadWheels.onDisplayLeft({ player = S.pn, id = nil }) end)
S.step(10, function() S.W.qaPoint = S.sliceOf(getText("ContextMenu_Eat"), 3); S.pre() end)
S.step(30, function() S.shot("zqa_g3_wheel_character_eat") end)
S.step(5, S.closeWheel)
S.step(10, function() ISDPadWheels.onDisplayDown({ player = S.pn, id = nil }); S.W.qaPoint = 8; S.pre() end)
S.step(30, function() S.shot("zqa_g3_wheel_now_light") end)
S.step(5, S.closeWheel)
S.step(10, function()
    ISDPadWheels.onDisplayLeft({ player = S.pn, id = nil })
    local st = S.D.state[S.pn]
    local e = st and st.path[1].entries[8]
    if e then S.D.enter(S.pn, e) end
    S.W.qaPoint = 1
    S.pre()
end)
S.step(30, function() S.shot("zqa_g3_wheel_use_smoke") end)
S.step(5, S.closeWheel)
S.step(20, function() S.pairOpen() end)
S.step(25, function() local w = S.cw(); if w then pcall(S.Focus.claimFocus, w) end; S.pre() end)
S.step(40, function() S.shot("zqa_g3_footer_pad") end)
S.step(10, function() pcall(S.Focus.releaseFocus); S.lock(false); S.pairShut() end)

-- ===================================================================== 45 full or simple (away)
S.step(10, function()
    S.setOpt(S.St.watchStyleOption, 2)
    S.setOpt(S.St.watchPlaceOption, 2)
    S.wear("DigitalBlack")
end)
S.step(30, function() S.pre() end)
S.step(30, function() S.shot("gb_simple_watch") end)
S.step(5, function()
    S.wear(nil)
    S.setOpt(S.St.watchStyleOption, 1)
    S.setOpt(S.St.watchPlaceOption, S.optWas.watchPlaceOption)
    S.setOpt(S.St.beltStyleOption, 2)
end)
S.step(10, function() S.pre() end)
S.step(30, function() S.shot("gb_simple_belt") end)
S.step(5, function() S.setOpt(S.St.beltStyleOption, 1) end)
S.R = {}
S.step(10, function()
    S.setOpt(S.St.devicesStyleOption, 2)
    S.R.prim, S.R.sec = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    S.R.radio = S.give("Base.RadioBlack")
    local dd = S.R.radio and S.R.radio:getDeviceData()
    if dd then dd:setHasBattery(true); dd:setPower(0.8); dd:setIsTurnedOn(true); dd:setDeviceVolume(0.5); dd:setChannel(98000) end
    S.p:setPrimaryHandItem(nil); S.p:setSecondaryHandItem(nil); S.p:setPrimaryHandItem(S.R.radio)
    S.pairOpen()
    S.t = 0
end)
S.step(5, function()   -- (up to about 200 frames for the Radio tab to hold the radio)
    S.t = S.t + 1
    local w = S.cw()
    local r = w and w._radios and w._radios[1]
    if not (r and r.radioInstance == S.R.radio) and S.t < 40 then return true end
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:radio" and (w._activeTab ~= "radio" or not w._drawerOpen) then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
end)
S.step(40, function()
    local w = S.cw(); local t = w and w._radioTw
    S.R.hc, S.R.hw = w:getHeight(), S.ww():getHeight()
    local need = (t and t.des and t.des.h or 0) + ZeD.T.px(40)
    if t and t.view and need > t.view.h then
        local add = need - t.view.h + 2
        w:setHeight(w:getHeight() + add); S.ww():setHeight(S.ww():getHeight() + add)
    end
end)
S.step(30, function() S.pre() end)
S.step(30, function() S.shot("gb_plain_radio") end)
S.step(10, function()
    local w = S.cw(); if S.R.hc then w:setHeight(S.R.hc); S.ww():setHeight(S.R.hw) end
    pcall(function() S.R.radio:getDeviceData():setIsTurnedOn(false) end)
    S.p:setPrimaryHandItem(S.R.prim); S.p:setSecondaryHandItem(S.R.sec)
    S.setOpt(S.St.devicesStyleOption, 1)
    pcall(S.CW.openTab, S.pn, "loot")
    S.pairShut()
end)
S.step(10, function() if S.D.H and S.D.H.openSetup then S.D.H.openSetup(S.p, S.pn) end end)
S.step(60, function()
    local w = S.MM and (S.MM.pauseOpts or (S.MM.root and S.MM.root.optsWin))
    if not w then S.notTaken("gb_forms_setup", "no ZeD setup window"); return end
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    local y = 0
    for _, r in ipairs(w:rowsFor(w:pages()[w.pageIdx])) do
        if r.kind == "header" and tostring(r.text):lower() == ZeD.tr("UI_ZeD_Options_ZedForms"):lower() then break end
        y = y + (r._h or ZeD.T.px(30))
    end
    w.scroll = math.max(0, y - ZeD.T.px(6))
    S.formsOk = true
    S.pre()
end)
S.step(40, function() if S.formsOk then S.shot("gb_forms_setup") end end)
S.step(10, function()
    local w = S.MM and (S.MM.pauseOpts or (S.MM.root and S.MM.root.optsWin))
    if w then pcall(function() w:close() end) end
end)
S.step(20, function() if S.menuUp() then S.toggleMenu() end end)

-- ===================================================================== put back
S.step(20, function()
    S.letGo()
    JoypadState.players[S.pn + 1] = nil
    S.closeWheel()
    S.stopAll()
    S.wear(nil)
    for _, o in ipairs(S.placed) do S.unplace(o) end
    for _, it in ipairs(S.given) do
        pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end; if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
        pcall(function() if S.p:isEquippedClothing(it) then S.p:removeWornItem(it) end end)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    for k, v in pairs(S.optWas) do S.setOpt(S.St[k], v) end
    pcall(function() ZeD.applyTheme(S.look[1], S.look[2], S.look[3]) end)
    pcall(function() getGameTime():setTimeOfDay(S.todWas) end)
    S.moveTo(S.home.x, S.home.y, S.home.z)
    pcall(S.Focus.releaseFocus, S.pn)
    S.lock(false)
end)
S.step(30, function()
    if ZEDQA_LAYOUT_BACK and S.snap then ZEDQA_LAYOUT_BACK(S.snap, "gb19b") else S.pairOpen() end
    pcall(function() S.p:setGodMod(S.godWas == true) end)
    pcall(function() S.p:setInvisible(S.invisWas == true) end)
    pcall(function() S.p:setZombiesDontAttack(S.zdaWas == true) end)
    local sp = ZEDQA_SPEED or setGameSpeed
    pcall(sp, S.speedWas or 1)
    S.say("taken " .. #S.took .. ": " .. table.concat(S.took, " "))
    S.say("not taken " .. #S.skipped .. ": " .. table.concat(S.skipped, " "))
    S.say("not here (main menu only, gallery_b11_menus_run.ps1): desk_05_trash_computer mm4_01_options_zed mm4_02_options_interface mm4_03_options_hidden")
    S.say("put back: look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. ", options, items, objects, car, layout, time, speed, cheats")
    S.say("DONE")
end)

-- (stepped on each drawn frame: the pause menu stops the game's tick; a step returning true runs again after n frames;
-- a button held for a tap is let go before the next step)
function S.tick()
    local s = S.Q[S.qi]
    if not s then Events.OnPreUIDraw.Remove(S.tick); return end
    S.wait = (S.wait or s.n) - 1
    if S.wait > 0 then return end
    S.wait = nil
    S.letGo()
    local ok, r = pcall(s.fn)
    if not ok then S.say("ERR step " .. S.qi .. ": " .. tostring(r)) end
    if ok and r == true then return end
    S.qi = S.qi + 1
end
Events.OnPreUIDraw.Add(S.tick)
S.say("start")
