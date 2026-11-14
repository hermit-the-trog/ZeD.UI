-- ZeDUI/tools/qa/zedqa_simple_watch.lua  (Nov 2 2026, QA; punch list 60, the Simple watch, build 5807c1a1)
local setGameSpeed = ZEDQA_SPEED or setGameSpeed   -- (Nov 13 2026: the prelude's speed sets the time multiplier too; see zedqa_prelude.lua)
-- In game at 4K, ZeD setup's Watch set to Simple. Pictures for the director and the buttons' work:
--   1. the corner watch with a worn digital watch: the time large, weekday and date, temperature, speed, alarm, and
--      Start/Pause, Speed, Alarm, Set (zqa_sw_1_worn). Start pauses and runs the game, Speed steps it, Alarm sets and
--      clears the watch's alarm.
--   2. Set (zqa_sw_2_set): the alarm hour, -, +, On/off, Done. + and - step the watch's alarm hour; On/off; Done.
--   3. no watch worn (zqa_sw_3_nowatch): Game speed with Pause, x1, x2, x3, each setting the game's speed.
--   4. the watch on the belt (watch place: belt): the plain time box on the belt (zqa_sw_4_belt_box), and the plain
--      watch popped above it as a click on the box pops it (zqa_sw_4_belt_popped).
--   5. Watch set back to Full: the watch's own art at once (zqa_sw_5_full).
-- The steps run on OnTickEvenPaused (Start pauses the game). Everything is put back. grep "ZEDQA sw".
local function say(s) print("ZEDQA sw " .. tostring(s)) end
local p = getPlayer()
local W, S = ZeD and ZeD.Watch, ZeD and ZeD.Settings
if not (p and W and S and S.watchStyleOption and W.simple) then say("ERR the Simple watch is not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sw_" .. n .. ".png") end); say("shot zqa_sw_" .. n) end
local styleWas, placeWas = S.watchStyleOption:getValue(), S.watchPlaceOption and S.watchPlaceOption:getValue()
local speedWas = getGameSpeed()
local inv = p:getInventory()
local watch
local wornBefore = {}
local function inst() return W.getInstance and W.getInstance() end
local function ids()
    local t = {}
    for _, h in ipairs((inst() and inst()._hit) or {}) do t[#t + 1] = tostring(h.id) end
    return table.concat(t, ",")
end
local function spd() return getGameSpeed() end
-- every button holds its word: the drawn buttons (the box's hits) against their words' widths in the button font
local function wordsFit(tag)
    local w = inst()
    if not w then return end
    local ok, worst = true, ""
    for _, h in ipairs(w._hit or {}) do
        local word = h.text or (w._plainBtns and w._plainBtns[h.id])
        if word then
            local tw = ZeD.TM:MeasureStringX(ZeD.T.fontF2, ZeD.btnCase and ZeD.btnCase(word) or word)
            if tw + ZeD.T.px(4) > h.w then ok = false; worst = worst .. " " .. h.id .. "(" .. tw .. ">" .. h.w .. ")" end
        end
    end
    say(tag .. ": button widths " .. (ok and "hold their words" or ("too narrow:" .. worst)) .. " | box " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight()))
end

local Q, qi = {}, 1
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end

-- other watches put aside; Simple, the corner; a worn digital watch
step(5, function()
    if spd() <= 0 then setGameSpeed(1) end
    local worn = p:getWornItems()
    for i = worn:size() - 1, 0, -1 do
        local it = worn:get(i):getItem()
        if it and (instanceof(it, "AlarmClockClothing") or tostring(it:getType()):find("Watch")) then wornBefore[#wornBefore + 1] = it; p:removeWornItem(it) end
    end
    S.watchStyleOption:setValue(2)
    if S.watchPlaceOption then S.watchPlaceOption:setValue(2) end
    watch = inv:AddItem("Base.WristWatch_Left_DigitalBlack")
    p:setWornItem(watch:getBodyLocation(), watch)
    pcall(function() watch:setAlarmSet(false) end)
end)
step(60, function()
    local w = inst()
    check(W.simple(), "60 watch: Watch is Simple")
    check(w and w:getIsVisible(), "60 watch: the corner watch shows")
    say("1: buttons " .. ids() .. " | box " .. (w and (math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight())) or "-"))
    check(ids() == "start,speed,alarm,set", "60 watch: Start/Pause, Speed, Alarm, Set (" .. ids() .. ")")
    wordsFit("1")
    shot("1_worn")
    setGameSpeed(1)
    W.act("start")
end)
step(10, function()
    check(spd() == 0, "60 watch 1: Start/Pause pauses the game (" .. spd() .. ")")
    shot("1_paused")
    W.act("start")
end)
step(10, function()
    check(spd() >= 1, "60 watch 1: pressed again, the game runs (" .. spd() .. ")")
    setGameSpeed(1)
    W.act("speed")
end)
step(10, function()
    check(spd() == 2, "60 watch 1: Speed steps the game to x2 (" .. spd() .. ")")
    W.act("speed")
end)
step(10, function()
    check(spd() == 3, "60 watch 1: again x3 (" .. spd() .. ")")
    setGameSpeed(1)
    W.act("alarm")
end)
step(10, function()
    check(watch:isAlarmSet() == true, "60 watch 1: Alarm sets the watch's alarm")
    shot("1_alarm_on")
    W.act("alarm")
end)
step(10, function()
    check(watch:isAlarmSet() == false, "60 watch 1: Alarm again clears it")
    W.act("set")
end)
-- set mode
local hourWas
step(20, function()
    local w = inst()
    check(w and w._setOpen == true, "60 watch 2: Set opens set mode")
    say("2: buttons " .. ids())
    check(ids() == "setdn,setup,alarmtoggle,set", "60 watch 2: -, +, On/off, Done (" .. ids() .. ")")
    wordsFit("2")
    shot("2_set")
    -- (the watch's own rules: + with the alarm off arms it at 0:00, then steps up; - steps down, and below 0 turns it off)
    pcall(function() watch:setAlarmSet(true); watch:setHour(7); watch:setMinute(0) end)
    hourWas = watch:getHour()
    W.act("setup")
end)
step(10, function()
    local h = watch:getHour()
    check(h == hourWas + 1, "60 watch 2: + steps the alarm hour up (" .. hourWas .. " -> " .. h .. ")")
    W.act("setdn")
end)
step(10, function()
    check(watch:getHour() == hourWas, "60 watch 2: - steps it back (" .. watch:getHour() .. ")")
    local armedB = watch:isAlarmSet()
    W.act("alarmtoggle")
    local w = inst()
    say("2: On/off pressed: alarm " .. tostring(armedB) .. " -> " .. tostring(watch:isAlarmSet()) .. " | set mode " .. tostring(w and w._setOpen))
    check(watch:isAlarmSet() ~= armedB and w and w._setOpen, "60 watch 2: On/off switches the alarm and stays in set mode")
    shot("2_set_toggled")
    if w and not w._setOpen then W.act("set") end   -- (back into set mode for Done)
end)
step(10, function()
    W.act("set")
    local w = inst()
    check(w and not w._setOpen, "60 watch 2: Done closes set mode")
    pcall(function() watch:setAlarmSet(false) end)
end)
-- no watch
step(10, function() p:removeWornItem(watch) end)
step(40, function()
    local w = inst()
    say("3: buttons " .. ids())
    check(w and w:getIsVisible() and ids() == "speed0,speed1,speed2,speed3", "60 watch 3: no watch worn: Game speed with Pause, x1, x2, x3 (" .. ids() .. ")")
    shot("3_nowatch")
    W.act("speed2")
end)
step(10, function()
    check(spd() == 2, "60 watch 3: x2 sets the game's speed (" .. spd() .. ")")
    W.act("speed0")
end)
step(10, function()
    check(spd() == 0, "60 watch 3: Pause pauses (" .. spd() .. ")")
    W.act("speed1")
end)
step(10, function() check(spd() == 1, "60 watch 3: x1 runs it (" .. spd() .. ")") end)
-- the belt
step(10, function()
    if S.watchPlaceOption then S.watchPlaceOption:setValue(1) end
    p:setWornItem(watch:getBodyLocation(), watch)
end)
step(40, function()
    local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()
    local box
    for _, b in ipairs((hud and hud._boxes) or {}) do if b.kind == "watch" then box = b end end
    check(box ~= nil, "60 watch 4: the watch on the belt shows its box")
    shot("4_belt_box")
    W.togglePop(true)   -- (what a click on the belt's box does)
end)
step(30, function()
    local w = inst()
    check(w and w:getIsVisible() and w._popped and ids() == "start,speed,alarm,set", "60 watch 4: the plain watch pops above the belt (" .. ids() .. ")")
    shot("4_belt_popped")
    W.togglePop(false)
    if S.watchPlaceOption then S.watchPlaceOption:setValue(2) end
end)
-- Full again
step(20, function() S.watchStyleOption:setValue(1) end)
step(20, function()
    check(not W.simple(), "60 watch 5: Watch back to Full")
    local w = inst()
    say("5: Full buttons " .. ids())
    check(w and w:getIsVisible() and ids() ~= "start,speed,alarm,set", "60 watch 5: the watch's own art is back at once (its own controls)")
    shot("5_full")
end)
step(10, function()
    pcall(function() p:removeWornItem(watch) end); pcall(function() inv:Remove(watch) end)
    for _, it in ipairs(wornBefore) do pcall(function() p:setWornItem(it:getBodyLocation(), it) end) end
    S.watchStyleOption:setValue(styleWas)
    if S.watchPlaceOption and placeWas then S.watchPlaceOption:setValue(placeWas) end
    setGameSpeed(speedWas > 0 and speedWas or 1)
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
    say("DONE")
end)

local wait = nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTickEvenPaused.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTickEvenPaused.Add(tick)
say("start")
