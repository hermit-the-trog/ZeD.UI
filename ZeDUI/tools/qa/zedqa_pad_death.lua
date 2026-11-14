-- ZeDUI/tools/qa/zedqa_pad_death.lua  (Nov 14 2026, QA, punch list 194): logs only. RUN ONLY ON A BACKED-UP QA SAVE:
-- the character dies. Binds pad 0 to player 0, god mode off, kills the character, then logs the death screen: pad focus,
-- the UI up, and what A / D-pad down do through the game's own press path. grep "ZEDQA pdd".
local function say(s) print("ZEDQA pdd " .. tostring(s)) end
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
jd = JoypadState.players[1] or JoypadState.joypads[1]
local ctl
for i = 0, 15 do local c = JoypadState.controllers[i]; if c and jd and c.joypad == jd then ctl = c end end
say("pad " .. tostring(jd) .. " controller " .. tostring(ctl))
local function ui()
    local t = {}
    pcall(function()
        local list = UIManager.getUI()
        for i = 0, list:size() - 1 do
            local u = list:get(i)
            if u:isVisible() then
                local tbl = u:getTable()
                t[#t + 1] = tostring(tbl and (tbl._zedLabel or tbl.Type) or u:getClass():getSimpleName())
            end
        end
    end)
    return table.concat(t, ", ")
end
local function state(tag)
    local jj = JoypadState.joypads[1]
    say(tag .. ": players[1] " .. tostring(JoypadState.players[1] ~= nil) .. " | focus " .. desc(jj and jj.focus) ..
        " | player data " .. tostring(jj and jj.player) .. " | dead " .. tostring(p:isDead()))
    say("  UI up: " .. ui())
end
local function press(b, name)
    local jj = JoypadState.joypads[1]
    local c = ctl
    if not c then for i = 0, 15 do local cc = JoypadState.controllers[i]; if cc and cc.joypad == jj then c = cc end end end
    if not c then say("press " .. name .. ": no controller object"); return end
    local f = jj and jj.focus
    say("press " .. name .. " (focus " .. desc(f) .. ")")
    local ok, e = pcall(function() c:onPressButton(b) end)
    if not ok then say("  ERR " .. tostring(e)) end
end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function()
    pcall(function() p:setGodMod(false) end)
    pcall(function() p:setInvincible(false) end)
    state("alive")
    p:setHealth(0)
    pcall(function() p:getBodyDamage():setOverallBodyHealth(0) end)
    pcall(function() p:Kill(nil) end)
end)
at(8000, function() state("dead +8 s") end)
at(9000, function() press(Joypad.AButton, "A") end)
at(10500, function() state("after A") end)
at(11000, function() press(Joypad.DPadDown, "D-pad down") end)
at(12500, function() state("after D-pad"); say("DONE") end)
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
