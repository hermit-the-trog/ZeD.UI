-- ZeDUI/tools/qa/zedqa_padfix_death.lua  (Nov 14 2026, QA): 194 on a6f4ab1fd. RUN ONLY ON A BACKED-UP QA SAVE (the
-- character dies). Both windows open and holding the pad at the moment of death; then the death screen must take the
-- pad, A moves on to the respawn desk, and the D-pad walks the desk (its selection logged). grep "ZEDQA pfd".
local function say(s) print("ZEDQA pfd " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
local p = getPlayer()
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
if not jd then say("ERR no pad"); say("DONE"); return end
local ctl
for i = 0, 15 do local c = JoypadState.controllers[i]; if c and c.joypad == jd then ctl = c end end
local function F() local j = JoypadState.joypads[1] or jd; return j and j.focus end
local function desc(o) if o == nil then return "nil" end return tostring(o._zedLabel or o.Type or o) end
local function selState(o)
    if not o then return "nil" end
    local t = {}
    for k, v in pairs(o) do
        local lk = tostring(k):lower()
        if (lk:find("sel") or lk:find("idx") or lk:find("focus") or lk:find("hot") or lk:find("cursor")) and type(v) ~= "table" and type(v) ~= "function" and type(v) ~= "userdata" then
            t[#t + 1] = tostring(k) .. "=" .. tostring(v)
        end
    end
    table.sort(t)
    return table.concat(t, " ")
end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function()
    local cw = ZeD_CharacterWindow.getInstance(0)
    pcall(function() if not cw:isReallyVisible() then ZeD.toggleBothPaired(0) end end)
    ZeD.Input.Focus.claimFocus(ZeD_CharacterWindow.getInstance(0))
    say("alive, focus " .. desc(F()))
    pcall(function() p:setGodMod(false) end); pcall(function() p:setInvincible(false) end)
    p:setHealth(0); pcall(function() p:getBodyDamage():setOverallBodyHealth(0) end); pcall(function() p:Kill(nil) end)
end)
at(8000, function()
    check(F() and F().Type == "ISPostDeathUI", "194 the death screen holds the pad 8 s after death (focus " .. desc(F()) .. ")")
    pcall(function() ctl:onPressButton(Joypad.AButton) end)
end)
at(10000, function()
    local d = F()
    check(d and tostring(desc(d)):find("Respawn") ~= nil, "194 A on the death screen moves to the respawn desk (focus " .. desc(d) .. ")")
    say("desk before D-pad: " .. selState(d))
    pcall(function() d:onJoypadDirDown(JoypadState.joypads[1] or jd) end)
end)
at(11000, function()
    local d = F()
    local s1 = selState(d)
    say("desk after Down: " .. s1)
    pcall(function() d:onJoypadDirDown(JoypadState.joypads[1] or jd) end)
end)
at(12000, function()
    local d = F()
    say("desk after 2nd Down: " .. selState(d))
    pcall(function() d:onJoypadDirUp(JoypadState.joypads[1] or jd) end)
end)
at(13000, function()
    local d = F()
    say("desk after Up: " .. selState(d) .. " | focus " .. desc(d))
    pcall(function() getCore():TakeFullScreenshot("zqa_pfd_respawn_desk.png") end)
    say("passed " .. nPass .. ", failed " .. nFail)
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
