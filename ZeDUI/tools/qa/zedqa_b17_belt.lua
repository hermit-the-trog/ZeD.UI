-- ZeDUI/tools/qa/zedqa_b17_belt.lua  (Nov 16 2026, QA): beta 17's controller reach (punch list 250, 251, 263, 265;
-- a9443a4d7) in the running game. Build's offline sims (belt_watch_pad_sim, pad_reach_b17_sim, pad_reach_fixes_sim)
-- prove the logic; this proves it on screen. Needs the prelude (zedqa_prelude.lua: ZEDQA_CAR_*) and a controller
-- plugged in (bound to player 1 as zedqa_b15.lua binds it); without one the belt and watch parts say "not run".
--   250  the Character wheel (D-pad Left) ends with "Belt": 9 slices, 10 with Loadouts on; taking it puts the pad on
--        the belt's first slot; walking off the right end gives the pad back; B gives it back; Start (the game's own
--        route, the controller's onPressButton) opens the pause menu and Start again plays with the pad back on the
--        belt; on the watch box X starts / pauses, Y lights it, A opens the full watch with the pad on it.
--        In the driver's seat the slice reads "Not now".
--   251  the full watch: lands on a key, the D-pad walks the keys, A grabs SPEED (D-pad Up / Down turn the game's speed)
--        and A lets go; A grabs SET / the crown (the setting opens, D-pad Up steps the alarm) and B lets go (the setting
--        closes, the pad stays); B with nothing grabbed gives the pad back to the belt, on its watch. The same with
--        the Watch option on Corner (opened as the wheel's Open the watch does; B gives the pad to the game). The
--        controller strip is drawn on screen both ways (PadGlyphs.drawStrip watched).
--   263  Start from each holder's onJoypadDown reaches the game's pause (a stand-in controller counts the call, so the
--        pause menu is not opened each time): the belt, the watch, a face (an oven placed beside the character),
--        Messages, the reader (a label), the guide window and the guide book, the seat picker or pop-out, the car
--        dash and the car radio. Not opened (no Lua way in single player): the station pop-out (needs a bound
--        station), the siren (a police car), chat (a server); their handlers are called on a stand-in, said so.
--   265  the dash's volume knob (a sedan from ZEDQA_CAR_WAIT, the character seated by ZEDQA_CAR_ENTER): the pad on
--        the dash lands on the knob, tap A grabs (FocusManager's qaButton hook), Right turns up and stops at full (no
--        wrap), Left turns down, B lets go and the dash keeps the pad, X is power (and X again puts it back).
-- Pictures: Screenshots/zqa_b17b_belt_focus.png, zqa_b17b_watch_grabbed.png, zqa_b17b_dash_knob.png.
-- Puts back: the watch worn before, the alarm, Loadouts, the Watch option, game speed 1, the oven, the car and its
-- key, the volume and power, every window opened here, the pad's focus handed back, input mode back to auto.
-- grep "ZEDQA b17b".
-- (Nov 23 2026, QA: the Loadouts split moves the Loadouts switch to the add-on ZeD-GUI: Loadouts; S.loadOpt() reads
-- ZeDLoadouts where it is loaded, else ZeD.Settings. With neither, ZeD alone after the split, the wheel has 9 slices
-- with no Loadouts ring either way.)
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA b17b " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b17b_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local Focus, Det, Bt, Wt, Dw = ZeD.Input and ZeD.Input.Focus, ZeD.Input and ZeD.Input.Detector, ZeD.Belt, ZeD.Watch, ZeD.DpadWheels
if not (Focus and Det and Bt and Bt.focus and Wt and Wt.padOpen and Dw and ZeD.padStart) then say("ERR beta 17's belt, watch or padStart is not loaded"); say("DONE"); return end
local S = { pauseN = 0, home = { x = p:getX(), y = p:getY(), z = p:getZ() } }
-- the table that holds the Loadouts switch: the add-on's ZeDLoadouts (since the split), else ZeD.Settings
function S.loadOpt()
    local LO = ZeDLoadouts
    if type(LO) == "table" and LO.loadoutsOption then return LO end
    return ZeD.Settings
end
function S.loSw() local t = S.loadOpt(); return t and t.loadoutsOption or nil end
local function desc(o) if o == nil then return "the game" end return tostring(o._zedLabel or o.Type or o) end
local function speed() local sc = UIManager.getSpeedControls(); return sc and sc:getCurrentGameSpeed() or -1 end
local function hud() return Bt.getHUD(pn) end
local function watch() return Wt.getInstance() end

-- the controller, bound to player 1 the way zedqa_b15.lua binds it
local jd = JoypadState.players[pn + 1]
if not jd then
    for i = 0, 15 do
        local c = JoypadState.controllers[i]
        if c and c.connected then
            pcall(function() triggerEvent("OnJoypadActivate", i) end)
            jd = JoypadState.players[1] or JoypadState.joypads[1]
            if jd and not JoypadState.players[1] then pcall(function() p:setJoypadBind(i); jd.player = 0; JoypadState.players[1] = jd end) end
            break
        end
    end
end
jd = JoypadState.players[pn + 1]
local function focus() return jd and jd.focus end
-- a stand-in pad for Start: its controller only counts the pause it is asked for
local fakeJd = { player = pn, controller = { onPauseButtonPressed = function() S.pauseN = S.pauseN + 1 end } }
local function startOn(tag, el, note)
    if not (el and el.onJoypadDown) then say("not run: Start on " .. tag .. " (" .. tostring(note or "not open") .. ")"); return end
    local n0 = S.pauseN
    local ok, err = pcall(el.onJoypadDown, el, Joypad.Start, fakeJd)
    if not ok then say("ERR Start on " .. tag .. ": " .. tostring(err)) end
    check(S.pauseN == n0 + 1, "263 " .. tag .. ": Start goes to the game's pause" .. (note and (" (" .. note .. ")") or ""))
end
-- the watch's controller strip, watched as it is drawn
local PG = ZeD.PadGlyphs
local realStrip = PG and PG.drawStrip
if realStrip then
    PG.drawStrip = function(ui, x, y, w, items, ...)
        if ui ~= nil and ui == watch() then
            local h = 0
            pcall(function() h = PG.stripH() end)
            S.strip = { top = ui:getAbsoluteY() + y, h = h, first = items and items[1], n = items and #items or 0 }
        end
        return realStrip(ui, x, y, w, items, ...)
    end
end
local function stripOk(tag)
    local s = S.strip
    local sh = getCore():getScreenHeight()
    check(s ~= nil and s.top >= 0 and s.top + s.h <= sh, string.format("251 %s: the controller strip is on screen (top %s, height %s, screen %d)",
        tag, tostring(s and math.floor(s.top)), tostring(s and math.floor(s.h)), sh))
end

-- ===================================================================== setup
step(10, function()
    say("pad " .. tostring(jd and jd.id) .. ", at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(Focus.releaseFocus, pn)
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if speed() ~= 1 then setGameSpeed(1) end
    if S.loSw() then S.loadWas = S.loSw():getValue() end
    S.placeWas = ZeD.Settings.watchPlaceOption:getValue()
    ZeD.Settings.watchPlaceOption:setValue(1)
    -- a Timez on the left wrist (it has the light), the watch worn now kept aside
    pcall(function()
        local worn = p:getWornItems()
        for i = 0, worn:size() - 1 do
            local wi = worn:get(i)
            if instanceof(wi:getItem(), "AlarmClockClothing") then S.kit, S.kitLoc = wi:getItem(), wi:getLocation() end
        end
        if S.kit then p:removeWornItem(S.kit, false) end
        S.wore = p:getInventory():AddItem("Base.WristWatch_Left_DigitalTimez")
        p:setWornItem(S.wore:getBodyLocation(), S.wore)
    end)
    pcall(function() S.alarm = { set = S.wore:isAlarmSet(), h = S.wore:getHour(), m = 0 } end)
    pcall(function() S.alarm.m = S.wore:getMinute() end)
    check(Wt.beltWatch(p) ~= nil, "a Timez worn: the watch is on the belt")
end)

-- ===================================================================== 250: the wheel's Belt slice
local function wheelOpen() ISDPadWheels.onDisplayLeft({ player = pn, id = nil }) end
local function wheelClose()
    local st = Dw.state[pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    Dw.state[pn] = nil
    local m = getPlayerRadialMenu(pn)
    if m and m:isReallyVisible() then pcall(m.undisplay, m) end
end
-- (the slices from the wheel's own builder, D.B.character, which D.open puts on the wheel: no pad needed to read them)
local function wheelCount(tag, want)
    local es = Dw.B.character(p, pn) or {}
    local last = es[#es]
    check(#es == want and last and last.key == "belt", string.format("250 %s: the Character wheel has %d slices (want %d), the last %s",
        tag, #es, want, tostring(last and last.name)))
    say("  Belt off: " .. tostring(last and last.off))
    return last
end
step(5, function()
    local o = S.loSw()
    if o then o:setValue(1) end
    wheelCount(o and "Loadouts off" or "no Loadouts (ZeD-GUI: Loadouts not loaded)", 9)
    wheelClose()
    if o then o:setValue(2) end
end)
step(5, function()
    if S.loSw() then wheelCount("Loadouts on", 10) else say("not run: Loadouts on (ZeD-GUI: Loadouts is not loaded: no Loadouts ring)") end
    if not jd then say("not run: the pad on the belt (no controller bound: setJoypadFocus needs one)"); return end
    -- (the slice taken from the opened wheel, as the pad takes it)
    wheelOpen()
    local st = Dw.state[pn]
    local es = st and st.path[1].entries or {}
    local e = es[#es]
    if e and e.key == "belt" then Dw.take(pn, e) else say("not run: taking the slice (the wheel did not open)"); wheelClose() end
end)
step(8, function()   -- (the slice's claim waits two frames)
    if not jd then return end
    local h = hud()
    local b = h and h:_gpBox()
    check(jd and focus() == h and h._gp ~= nil, "250 the Belt slice gives the belt the pad (pad on " .. desc(focus()) .. ")")
    check(b and b.kind == "slot", "250 it lands on the first slot (box " .. tostring(b and b.kind) .. ")")
end)
step(20, function() if jd then shot("belt_focus") end end)
-- Start, the game's own route both times: the pause menu, then play with the pad back on the belt
step(5, function()
    if not (jd and jd.controller and focus() == hud()) then say("not run: Start round trip (no pad on the belt)"); return end
    S.realStart = true
    pcall(function() jd.controller:onPressButton(Joypad.Start) end)
end)
step(15, function()
    if not S.realStart then return end
    local m = MainScreen and MainScreen.instance
    check(speed() == 0 and m and m:isReallyVisible(), "263 belt: Start pauses (the pause menu up, speed " .. speed() .. ")")
    pcall(function() jd.controller:onPressButton(Joypad.Start) end)
end)
step(15, function()
    if not S.realStart then return end
    local m = MainScreen and MainScreen.instance
    check(speed() ~= 0 and not (m and m:isReallyVisible()), "263 belt: Start again plays (speed " .. speed() .. ")")
    check(focus() == hud(), "263 belt: the pad is back on the belt (on " .. desc(focus()) .. ")")
    if focus() ~= hud() then Bt.focus(pn) end
end)
step(3, function()
    local h = hud()
    if not (jd and h and h._gp) then return end
    for _ = 1, #h._boxes + 2 do if h._gp then h:onJoypadDirRight() end end
    check(h._gp == nil and focus() ~= h, "250 walking off the belt's right end gives the pad back (on " .. desc(focus()) .. ")")
    Bt.focus(pn)
end)
step(3, function()
    local h = hud()
    if not (jd and h and h._gp) then return end
    h:onJoypadDown(Joypad.BButton, jd)
    check(h._gp == nil and focus() ~= h, "250 B on the belt gives the pad back (on " .. desc(focus()) .. ")")
    Bt.focus(pn)
end)
-- to the watch box (left of the first slot), then X, Y
step(3, function()
    local h = hud()
    if not (jd and h and h._gp) then return end
    startOn("belt", h)
    for _ = 1, #h._boxes do
        local b = h:_gpBox()
        if not b or b.kind == "watch" then break end
        h:onJoypadDirLeft()
        if not h._gp then Bt.focus(pn); break end
    end
    local b = h:_gpBox()
    if not (b and b.kind == "watch") then
        for i, x in ipairs(h._boxes) do if x.kind == "watch" then h._gp.idx = i; say("  (the watch box set straight: the walk left did not reach it)") end end
    end
    b = h:_gpBox()
    S.onWatch = check(b and b.kind == "watch", "250 the pad on the belt's watch box")
    if S.onWatch then h:onJoypadDown(Joypad.XButton, jd) end
end)
step(3, function()
    local h = hud()
    if not (h and h._gp and S.onWatch) then return end
    check(speed() == 0, "250 X on the belt watch pauses (speed " .. speed() .. ")")
    h:onJoypadDown(Joypad.XButton, jd)
end)
step(3, function()
    local h = hud()
    if not (h and h._gp and S.onWatch) then return end
    check(speed() ~= 0, "250 X again starts (speed " .. speed() .. ")")
    h:onJoypadDown(Joypad.YButton, jd)
    local w = watch()
    check(w and (w._litUntil or 0) > getTimestampMs(), "250 Y on the belt watch lights it")
    h:onJoypadDown(Joypad.AButton, jd)
end)

-- ===================================================================== 251: the full watch, from the belt
step(4, function()
    local w, h = watch(), hud()
    if not (jd and w) then say("not run: the full watch on the pad (no controller or no watch)"); return end
    check(focus() == w and w._popped == true, "250 A on the belt watch opens the full watch with the pad on it (on " .. desc(focus()) .. ")")
    check(h and h._gp ~= nil, "251 the belt keeps its place while the watch has the pad")
    check(w._padId ~= nil, "251 the pad lands on a key (" .. tostring(w._padId) .. ")")
    local seen, n = {}, 0
    for _, d in ipairs({ "Right", "Down", "Left", "Up", "Right", "Right", "Down", "Down" }) do
        w["onJoypadDir" .. d](w)
        if w._padId and not seen[w._padId] then seen[w._padId] = true; n = n + 1 end
    end
    check(n >= 2, "251 the D-pad walks the keys (" .. n .. " keys reached)")
end)
local function hasHit(w, id) for _, x in ipairs(w._hit or {}) do if x.id == id then return true end end return false end
local function grabSpeed(tag)
    step(2, function()
        local w = watch()
        if not (w and focus() == w) then return end
        if not hasHit(w, "speed") then say("not run: " .. tag .. " SPEED (no SPEED key on this watch)"); return end
        w._padId, w._grab = "speed", false
        S.sp0 = speed()
        w:onJoypadDown(Joypad.AButton, jd)
        check(w:padGrabbed(), "251 " .. tag .. ": A grabs SPEED")
        w:onJoypadDirUp()
    end)
    step(3, function()
        local w = watch()
        if not (w and S.sp0 and w._padId == "speed") then return end
        check(speed() == S.sp0 + 1, "251 " .. tag .. ": D-pad Up turns the speed up (" .. S.sp0 .. " -> " .. speed() .. ")")
        w:onJoypadDirDown()
    end)
    step(3, function()
        local w = watch()
        if not (w and S.sp0 and w._padId == "speed") then return end
        check(speed() == S.sp0, "251 " .. tag .. ": D-pad Down turns it back (" .. speed() .. ")")
        w:onJoypadDown(Joypad.AButton, jd)
        check(not w:padGrabbed() and focus() == w, "251 " .. tag .. ": A lets go, the pad stays on the watch")
        S.sp0 = nil
    end)
end
grabSpeed("belt")
step(2, function()
    local w = watch()
    if not (w and focus() == w) then return end
    S.setId = hasHit(w, "set") and "set" or (hasHit(w, "crown") and "crown" or nil)
    if not S.setId then say("not run: SET (no SET key or crown on this watch)"); return end
    w._padId, w._grab = S.setId, false
    S.alarm0 = { set = w._item and w._item:isAlarmSet(), h = w._item and w._item:getHour() }
    w:onJoypadDown(Joypad.AButton, jd)
    check(w:padGrabbed() and w._setOpen == true, "251 A grabs " .. S.setId .. " and the setting opens")
    w:onJoypadDirUp()
    S.strip = nil
end)
step(4, function()
    local w = watch()
    if not (w and S.setId) then return end
    local it = w._item
    check(it and (it:isAlarmSet() ~= S.alarm0.set or it:getHour() ~= S.alarm0.h), string.format("251 D-pad Up steps the alarm (%s %s -> %s %s)",
        tostring(S.alarm0.set), tostring(S.alarm0.h), tostring(it and it:isAlarmSet()), tostring(it and it:getHour())))
    stripOk("belt, grabbed")
    check(S.strip and S.strip.first and S.strip.first.pad ~= nil, "251 the strip reads the D-pad's turn while grabbed")
    shot("watch_grabbed")
end)
step(3, function()
    local w = watch()
    if not (w and S.setId) then return end
    w:onJoypadDown(Joypad.BButton, jd)
    check(not w:padGrabbed() and w._setOpen == false and focus() == w, "251 B lets go, the setting closes, the pad stays on the watch")
    startOn("full watch", w)
end)
step(3, function()
    local w, h = watch(), hud()
    if not (w and focus() == w) then return end
    w:onJoypadDown(Joypad.BButton, jd)
    local b = h and h:_gpBox()
    check(focus() == h and b and b.kind == "watch", "251 B with nothing grabbed gives the pad back to the belt, on its watch (on " .. desc(focus()) .. ")")
    check(not w._popped, "251 the popped watch tucks back onto the belt")
    if h and focus() == h then h:onJoypadDown(Joypad.BButton, jd) end
end)
-- the Watch option on Corner, opened as the wheel's Open the watch slice opens it
step(3, function() ZeD.Settings.watchPlaceOption:setValue(2) end)
step(5, function()
    local w = watch()
    if not jd then return end
    S.strip = nil
    check(Wt.padOpen(pn) and focus() == w, "251 Corner: the full watch takes the pad (on " .. desc(focus()) .. ")")
end)
step(4, function()
    local w = watch()
    if not (w and focus() == w) then return end
    check(w._padId ~= nil and not w._popped, "251 Corner: the pad lands on a key (" .. tostring(w._padId) .. "), nothing pops")
    stripOk("Corner")
    local was = w._padId
    w:onJoypadDirLeft(); w:onJoypadDirDown()
    check(w._padId ~= nil, "251 Corner: the D-pad walks (" .. tostring(was) .. " -> " .. tostring(w._padId) .. ")")
end)
grabSpeed("Corner")
step(3, function()
    local w = watch()
    if not (w and focus() == w) then return end
    w:onJoypadDown(Joypad.BButton, jd)
    check(focus() == nil, "251 Corner: B gives the pad back to the game (on " .. desc(focus()) .. ")")
end)
step(3, function()
    ZeD.Settings.watchPlaceOption:setValue(S.placeWas or 1)
    local it = S.wore
    if it and S.alarm then pcall(function() it:setHour(S.alarm.h); it:setMinute(S.alarm.m); it:setAlarmSet(S.alarm.set) end) end
end)

-- ===================================================================== 263: Start from the other holders
local function placeStove(sprite, dx)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()), math.floor(p:getZ()))
    if not sq then return nil end
    local obj = IsoStove.new(getCell(), sq, getSprite(sprite))
    pcall(function() obj:createContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    return obj
end
step(3, function()
    local FP, F = ZeD.FacePop, ZeD.TwoWayFull
    if not (FP and F and FP.on and FP.on()) then say("not run: Start on a face (faces off: Devices on Simple or safe mode)"); return end
    S.stove = placeStove("appliances_cooking_01_12", 2)
    if S.stove then pcall(FP.open, p, S.stove) end
end)
step(3, function()
    local F = ZeD.TwoWayFull
    local v = F and F.get(pn)
    if S.stove then startOn("face (oven)", v and v:isReallyVisible() and v or nil) end
    pcall(function() F.close(pn) end)
    if ZeD.Messages and ZeD.Messages.open then pcall(ZeD.Messages.open) end
end)
step(3, function()
    local win = ZeD.MessagesWindow and ZeD.MessagesWindow.get(pn)
    startOn("Messages", win and win:isReallyVisible() and win or nil)
    if win then pcall(win.close, win) end
    pcall(ZeD.Reader.openLabel, p, "QA label")
end)
step(3, function()
    local win = ZeD.Reader and ZeD.Reader.get(pn)
    startOn("reader", win and win:isReallyVisible() and win or nil)
    if win then pcall(win.close, win) end
    pcall(ZeD.Guide.openWindow, pn)
end)
step(3, function()
    local win = ZeD.Guide and ZeD.Guide.get(pn)
    startOn("guide window", win and win:isReallyVisible() and win or nil)
    if win then pcall(win.close, win) end
    pcall(ZeD.GuideBook.open, pn)
end)
step(3, function()
    local bk = ZeD.GuideBook and ZeD.GuideBook.books and ZeD.GuideBook.books[pn]
    startOn("guide book", bk and bk:isReallyVisible() and bk or nil)
    pcall(ZeD.GuideBook.close, pn)
    -- (no Lua way to open these in single player: their handlers on a stand-in)
    say("not run: opening the station pop-out (needs a bound station), the siren (a police car), chat (a server)")
    if ZeD_StationPopout then startOn("station pop-out", { playerNum = pn, onJoypadDown = ZeD_StationPopout.onJoypadDown }, "handler only") end
    if ZeD_SirenController then startOn("siren", { playerNum = pn, onJoypadDown = ZeD_SirenController.onJoypadDown }, "handler only") end
    if ZeD_ChatWindow then startOn("chat", { playerNum = pn, onJoypadDown = ZeD_ChatWindow.onJoypadDown }, "handler only") end
    if speed() ~= 1 then setGameSpeed(1) end
end)

-- ===================================================================== 265: the car (seat picker, dash knob, radio)
local function moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end
step(3, function()
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_ENTER) then S.carState = "fail"; S.carWhy = "no zedqa_prelude.lua"; return end
    S.carState, S.carT0 = "wait", getTimestampMs()
    ZEDQA_CAR_WAIT("Base.CarNormal", "b17b", function(v) S.car = v; S.carState = "ready" end,
        function(why) S.carState = "fail"; S.carWhy = why end, 6000)
end)
step(1, function()
    if S.carState == "wait" and getTimestampMs() - S.carT0 < 40000 then return "again" end
    if not S.car then say("not run: the car parts (" .. tostring(S.carWhy or "the car never got ready") .. ")"); return end
    moveTo(S.car:getX() + 2.5, S.car:getY() + 0.5, S.car:getZ())
end)
step(20, function()
    if S.car then pcall(ZeD.Seats.toggle, p, S.car) end
end)
step(10, function()
    if not S.car then return end
    local sp = ZeD.Seats.getPopout and ZeD.Seats.getPopout(pn)
    local win = ZeD.Seats.windows and ZeD.Seats.windows[pn]
    local el = (sp and sp:isReallyVisible() and sp) or (win and win:isReallyVisible() and win) or nil
    startOn(el == sp and "seat pop-out" or "seat picker", el)
    if el then pcall(el.close, el) end
end)
step(5, function()
    if not S.car then return end
    S.key = ZEDQA_CAR_PREP(S.car)
    local ok, why = ZEDQA_CAR_ENTER(S.car, 0)
    S.seated = ok
    if not ok then say("not run: the dash knob (" .. tostring(why) .. ")") end
end)
step(60, function()
    if not S.seated then return end
    local e
    for _, x in ipairs(Dw.B.character(p, pn) or {}) do if x.key == "belt" then e = x end end
    check(e and e.off == ZeD.tr("UI_ZeD_Wheel_NotNow"), "250 in the driver's seat the Belt slice reads Not now (" .. tostring(e and e.off) .. ")")
    local D = ZeD.Dashboard
    S.dash = D.getInstance(pn)
    if not (S.dash and D.canTakePad(p)) then say("not run: the dash knob (the dash cannot take the pad)"); S.dash = nil; return end
    S.dash._wantFocus, S.dash._wantUntil = { "vol" }, getTimestampMs() + 1000
    D.takePad(p)
end)
local function dd() local s = S.dash and S.dash._st; local rp = s and s.radioPart; return rp and rp:getDeviceData() end
local function vol() local d = dd(); return d and d:getDeviceVolume() or -1 end
local function tap(name, button)
    Focus.dispatchJoypadDown(S.dash, button); Focus.qaButton(name, false)
end
step(5, function()
    if not S.dash then return end
    local el = Focus.getFocusedElement(S.dash)
    if not check(Focus.getFocusedWindow(pn) == S.dash and el and el.id == "dash:vol", "265 the pad on the dash lands on the volume knob (" .. tostring(el and el.id) .. ")") then
        say("not run: the knob (this car's dash has no volume knob, or the pad did not land)"); S.dash = nil; return
    end
    S.vol0 = vol()
    S.on0 = dd() and dd():getIsTurnedOn()
    -- (the volume moves only on a set that is on and has power, ISRadioAction:isValidSetVolume; set up straight
    -- on the radio, not through the knob: on, at half, the game running)
    pcall(function() dd():setIsTurnedOn(true); dd():setDeviceVolume(0.5) end)
    if speed() == 0 then setGameSpeed(1) end
    tap("A", Joypad.AButton)
end)
step(4, function()
    if not S.dash then return end
    Focus.qaButton("A", nil)
    check(Focus.knobGrabbed(S.dash, "dash:vol"), "265 tap A grabs the knob")
    S.turns = 0
    S.onSet = dd() and dd():getIsTurnedOn()
    say(string.format("  before the turns: speed %s, driver %s, set on %s, power %s, volume %s", tostring(getGameSpeed()),
        tostring(S.dash._driver), tostring(S.onSet), tostring(dd() and dd():getPower()), tostring(vol())))
end)
step(20, function() if S.dash then shot("dash_knob") end end)
step(4, function()
    if not S.dash then return end
    if getGameSpeed() == 0 then setGameSpeed(1) end
    Focus.dispatchJoypadDir(S.dash, "right")
end)
step(4, function()   -- (then one Right a frame, 8 in all: from 0.6 to full and past it; the turn lands on the press)
    if not S.dash then return end
    if S.turns == 0 then check(math.abs(vol() - 0.6) < 0.01, "265 Right turns up from half (volume " .. vol() .. ")") end
    Focus.dispatchJoypadDir(S.dash, "right")
    S.turns = S.turns + 1
    if S.turns < 8 then return "again" end
end)
step(5, function()
    if not S.dash then return end
    check(math.abs(vol() - 1) < 0.01, "265 Right stops at full, no wrap (volume " .. vol() .. ")")
    Focus.dispatchJoypadDir(S.dash, "left")
end)
step(5, function()
    if not S.dash then return end
    check(math.abs(vol() - 0.9) < 0.01, "265 Left turns it down (volume " .. vol() .. ")")
    Focus.dispatchJoypadDown(S.dash, Joypad.BButton)
end)
step(3, function()
    if not S.dash then return end
    check(not Focus.knobGrabbed(S.dash, "dash:vol") and Focus.getFocusedWindow(pn) == S.dash, "265 B lets go, the dash keeps the pad")
    local el = Focus.getFocusedElement(S.dash)
    if not (el and el.onContextMenu) then say("not run: X power (this set's power is its rocker)"); return end
    S.xTried = true
    tap("X", Joypad.XButton)
end)
step(10, function()
    if not S.dash then return end
    Focus.qaButton("X", nil)
    if S.xTried then
        local on = dd() and dd():getIsTurnedOn()
        check(on ~= S.onSet, "265 X is power (" .. tostring(S.onSet) .. " -> " .. tostring(on) .. ")")
    end
end)
step(10, function()
    if not S.dash then return end
    Focus.qaButton("X", nil)
    -- (put back straight on the radio: the volume and the power it had)
    pcall(function() if S.vol0 and S.vol0 >= 0 then dd():setDeviceVolume(S.vol0) end; dd():setIsTurnedOn(S.on0 == true) end)
    startOn("car dash", S.dash)
    if ZeD.CarRadio then pcall(ZeD.CarRadio.toggle, p) end
end)
step(10, function()
    if not S.seated then return end
    local r = ZeD.CarRadio and ZeD.CarRadio.get(pn)
    startOn("car radio", r and r:isReallyVisible() and r or nil, (r == nil) and "no face for this car's radio" or nil)
    if r and r:isReallyVisible() then pcall(r.close, r) end
    say("put back: volume " .. vol() .. " (was " .. tostring(S.vol0) .. "), power " .. tostring(dd() and dd():getIsTurnedOn()) .. " (was " .. tostring(S.on0) .. ")")
    if S.dash then S.dash:_release() end
end)
step(5, function()
    if S.car then ZEDQA_CAR_AWAY(S.car, S.key) end
end)

-- ===================================================================== put back
step(10, function()
    pcall(function() ZeD.TwoWayFull.close(pn) end)
    if S.stove then pcall(function() local sq = S.stove:getSquare(); if sq then sq:transmitRemoveItemFromSquare(S.stove); sq:RemoveTileObject(S.stove) end end) end
    pcall(function() if S.wore then p:removeWornItem(S.wore, false); p:getInventory():Remove(S.wore) end end)
    pcall(function() if S.kit then p:setWornItem(S.kitLoc, S.kit) end end)
    if S.loadWas and S.loSw() then S.loSw():setValue(S.loadWas) end
    if S.placeWas then ZeD.Settings.watchPlaceOption:setValue(S.placeWas) end
    pcall(function() local m = MainScreen.instance; if m and m.inGame and m:isReallyVisible() and jd and jd.controller then JoypadControllerData.onPauseButtonPressed(jd.controller) end end)
    wheelClose()
    pcall(function() Focus.qaButton("A", nil); Focus.qaButton("X", nil) end)
    pcall(Focus.releaseFocus, pn)
    if jd then setJoypadFocus(pn, nil) end
    if PG and realStrip then PG.drawStrip = realStrip end
    moveTo(S.home.x, S.home.y, S.home.z)
    if speed() ~= 1 then setGameSpeed(1) end
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say("put back: Loadouts " .. tostring(S.loSw() and S.loSw():getValue()) .. ", Watch " .. tostring(ZeD.Settings.watchPlaceOption:getValue()) ..
        ", speed " .. speed() .. ", pad on " .. desc(focus()))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- (stepped on each drawn frame: a paused game stops the tick; a step returning "again" runs again next frame)
local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    local ok, r = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(r)) end
    if ok and r == "again" then wait = 1; return end
    qi = qi + 1
end
Events.OnPreUIDraw.Add(tick)
say("start")
