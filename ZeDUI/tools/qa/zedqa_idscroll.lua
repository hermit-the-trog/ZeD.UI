-- ZeDUI/tools/qa/zedqa_idscroll.lua  (Nov 14 2026, QA, punch list 190b): what moves the ID card's page when Right is pressed
-- on the Hair | Beard switch (hb:part). Wraps the scroll's setScrollPos and logs the scroll, _idLastH and _idOffPx for 10
-- frames after the press. grep "ZEDQA ids".
local function say(s) print("ZEDQA ids " .. tostring(s)) end
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
local Focus = ZeD.Input.Focus
local w
local frames = -1
local function state() local sc = w and w._identityScroll; return "scrollPos " .. tostring(sc and sc.scrollPos) .. " | _idLastH " .. tostring(w and w._idLastH) .. " | _idOffPx " .. tostring(w and w._idOffPx) end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function() ZeD_CharacterWindow.openTab(0, "identity"); w = ZeD_CharacterWindow.getInstance(0) end)
at(1500, function()
    Focus.claimFocus(w)
    for _, s in ipairs(Focus.flatElements(w)) do if tostring(s.id) == "hb:part" then Focus.focusWhere(w, s.zone, function(e) return tostring(e.id) == "hb:part" end) end end
    local sc = w._identityScroll
    say("scroll object " .. tostring(sc) .. " setScrollPos " .. tostring(sc and sc.setScrollPos))
    if sc and sc.setScrollPos then
        local o = sc.setScrollPos
        sc.setScrollPos = function(self, pos, ...)
            local tb = ""
            pcall(function() if debug and debug.traceback then tb = debug.traceback() end end)
            say("setScrollPos(" .. tostring(pos) .. ") frame " .. tostring(frames) .. " " .. tb)
            return o(self, pos, ...)
        end
    end
    say("before Right, on " .. tostring(Focus.getFocusedElement(w) and Focus.getFocusedElement(w).id) .. " | " .. state())
end)
at(2300, function()
    frames = 0
    Focus.dispatchJoypadDir(w, "right", jd)
    say("Right sent; on " .. tostring(Focus.getFocusedElement(w) and Focus.getFocusedElement(w).id) .. " | " .. state())
end)
at(3500, function() say("DONE") end)
local function tick()
    local now = getTimestampMs()
    if not t0 then t0 = now end
    if frames >= 0 and frames < 10 then frames = frames + 1; say("frame " .. frames .. " | " .. state()) end
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
