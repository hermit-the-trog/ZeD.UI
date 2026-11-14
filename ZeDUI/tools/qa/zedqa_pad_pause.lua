-- ZeDUI/tools/qa/zedqa_pad_pause.lua  (Nov 14 2026, QA, punch list 187 + 188): logs only. Binds pad 0 to player 0,
-- then: Start with ZeD's windows open; windows shut, Start for the pause menu, then Y; then a D-pad press.
-- Presses go through the game's own JoypadState.controllers[id]:onPressButton. grep "ZEDQA pps".
local function say(s) print("ZEDQA pps " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local function desc(o)
    if o == nil then return "nil" end
    local s = tostring(o._zedLabel or o.Type or o)
    local ok, v = pcall(function() return o:isReallyVisible() end)
    return s .. " (visible " .. tostring(ok and v) .. ")"
end
local jd = JoypadState.players[1]
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
jd = JoypadState.players[1]
if not jd then say("ERR no pad for player 0"); say("DONE"); return end
local ctl
for i = 0, 15 do local c = JoypadState.controllers[i]; if c and c.joypad == jd then ctl = c end end
if not ctl then say("ERR no controller object"); say("DONE"); return end
local function mouse()
    local a, b = "?", "?"
    pcall(function() a = tostring(getCore():isMouseActive()) end)
    pcall(function() b = tostring(wasMouseActiveMoreRecentlyThanJoypad()) end)
    return "mouseActive " .. a .. ", mouse more recent than pad " .. b
end
local function state(tag)
    local esc = MainScreen and MainScreen.instance
    say(tag .. ": focus " .. desc(jd.focus) .. " | paused " .. tostring(isGamePaused()) .. " | pause menu up " ..
        tostring(esc and esc.inGame and esc:isReallyVisible()) .. " | bind " .. tostring(p:getJoypadBind()) .. " | " .. mouse())
end
-- who handles the presses
local origPause = JoypadControllerData.onPauseButtonPressed
JoypadControllerData.onPauseButtonPressed = function(self, ...) say("  game onPauseButtonPressed ran"); return origPause(self, ...) end
local origNoFocus = JoypadControllerData.onPressButtonNoFocus
JoypadControllerData.onPressButtonNoFocus = function(self, b, ...) say("  onPressButtonNoFocus got " .. tostring(b)); return origNoFocus(self, b, ...) end
local function press(b, name)
    local f = jd.focus
    say("press " .. name .. " (focus " .. desc(f) .. ")")
    if f and f.onJoypadDown then
        local o = f.onJoypadDown
        f.onJoypadDown = function(self, bb, ...) say("  " .. desc(self) .. ":onJoypadDown got " .. tostring(bb)); return o(self, bb, ...) end
        local ok, e = pcall(function() ctl:onPressButton(b) end)
        f.onJoypadDown = o
        if not ok then say("  ERR " .. tostring(e)) end
    else
        local ok, e = pcall(function() ctl:onPressButton(b) end)
        if not ok then say("  ERR " .. tostring(e)) end
    end
end
local function wheels()
    local r = "?"
    pcall(function() r = tostring(getPlayerRadialMenu(0):isReallyVisible()) end)
    local z = "?"
    pcall(function() z = tostring(ZeD.Wheels and ZeD.Wheels.open or (ZeD.wheel and ZeD.wheel:isReallyVisible())) end)
    return "game radial up " .. r .. ", ZeD wheel " .. z
end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(500, function() pcall(function() if not (ZeD.charWin and ZeD.charWin:isReallyVisible()) then ZeD.toggleBothPaired(0) end end); state("windows opened") end)
at(2500, function() state("187 before Start"); press(Joypad.Start, "Start") end)
at(4000, function() state("187 after Start") end)
at(4500, function()
    pcall(function() local m = MainScreen.instance; if m and m.inGame and m:isReallyVisible() then origPause(ctl) end end)
    pcall(function() if ZeD.charWin and ZeD.charWin:isReallyVisible() then ZeD.toggleBothPaired(0) end end)
    state("windows shut")
end)
at(6500, function() press(Joypad.Start, "Start (pause)") end)
at(8000, function() state("188 pause menu, before Y"); press(Joypad.YButton, "Y") end)
at(9500, function() state("188 after Y") end)
at(10000, function() press(Joypad.DPadDown or Joypad.DPadUp, "D-pad down") end)
at(11000, function() state("188 after D-pad"); say("  " .. wheels()) end)
at(12000, function()
    pcall(function() local m = MainScreen.instance; if m and m.inGame and m:isReallyVisible() then origPause(ctl) end end)
    pcall(function() local r = getPlayerRadialMenu(0); if r:isReallyVisible() then r:undisplay() end end)
    JoypadControllerData.onPauseButtonPressed = origPause
    JoypadControllerData.onPressButtonNoFocus = origNoFocus
    state("end")
    say("DONE")
end)
local function tick()
    local now = getTimestampMs()
    if not t0 then t0 = now end
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
