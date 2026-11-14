-- ZeDUI/tools/qa/zedqa_padfix_b.lua  (Nov 14 2026, QA): 186 on a6f4ab1fd. Both windows open, the pad on the Character
-- window's container strip (its first icon), D-pad right through the game's controller press; where focus lands is
-- logged (window, zone, element) and checked against the World window's container strip. grep "ZEDQA pfb".
local function say(s) print("ZEDQA pfb " .. tostring(s)) end
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
local Focus = ZeD.Input.Focus
local function zoneName(z) return z and tostring(z.zone or z.name or "?") or "nil" end
local function elName(e) return e and tostring(e.id or e.label or e.name or (e.item and e.item:getDisplayName()) or e) or "nil" end
local function where()
    local w = Focus.getFocusedWindow(0)
    return tostring(w and (w._zedLabel or w.Type)) .. " / " .. zoneName(w and Focus.getFocusedZone(w)) .. " / " .. elName(w and Focus.getFocusedElement(w))
end
local function ring(w)
    local t = {}
    for k, z in ipairs(w._focusRing or {}) do t[#t + 1] = k .. ":" .. zoneName(z) .. "(" .. tostring(z.elements and #z.elements or 0) .. ")" end
    return table.concat(t, " ")
end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
local cw, ww
at(300, function()
    cw = ZeD_CharacterWindow.getInstance(0)
    pcall(function() if not cw:isReallyVisible() then ZeD.toggleBothPaired(0) end end)
    Focus.claimFocus(cw)
end)
at(1500, function()
    ww = (ZeD.windowsFor and ZeD.windowsFor(0) and ZeD.windowsFor(0)[2]) or ZeD_WorldWindow and ZeD_WorldWindow.getInstance and ZeD_WorldWindow.getInstance(0)
    say("Character ring: " .. ring(cw))
    if ww then say("World ring: " .. ring(ww)) end
    local zn
    for _, z in ipairs(cw._focusRing or {}) do local n = zoneName(z):lower(); if n:find("strip") or n:find("contain") then zn = zoneName(z); break end end
    say("strip zone picked: " .. tostring(zn))
    if zn then Focus.focusWhere(cw, zn, function() return true end) end
    say("before Right: " .. where())
end)
at(2500, function() local f = getJoypadFocus(0); say("right via " .. tostring(f and (f._zedLabel or f.Type))); local ok, e = pcall(function() f:onJoypadDirRight(jd) end); if not ok then say("ERR right " .. tostring(e)) end end)
at(3500, function()
    local w = Focus.getFocusedWindow(0)
    local zn = zoneName(w and Focus.getFocusedZone(w)):lower()
    say("after Right: " .. where())
    check(w ~= cw and (zn:find("strip") or zn:find("contain")) and true or false, "186 Right from the Character strip lands on the World window's container strip (" .. where() .. ")")
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
