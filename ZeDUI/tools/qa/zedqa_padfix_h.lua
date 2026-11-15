-- ZeDUI/tools/qa/zedqa_padfix_h.lua  (Nov 14 2026, QA): 232 (B at the top of a window cancels the running action) and 230
-- (the pad's rest shows a tooltip: a trait on the ID card, an Equip row; pictures). grep "ZEDQA pfh".
local function say(s) print("ZEDQA pfh " .. tostring(s)) end
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
local Focus = ZeD.Input.Focus
local cw
local function qn() local q = ISTimedActionQueue.getTimedActionQueue(p); return q and q.queue and #q.queue or 0 end
local function qhead() local q = ISTimedActionQueue.getTimedActionQueue(p); local a = q and q.queue and q.queue[1]; return a and tostring(a.Type) or "none" end
local apple
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
-- 232
at(300, function()
    ZeD_CharacterWindow.openTab(0, "equip"); cw = ZeD_CharacterWindow.getInstance(0)
end)
at(1300, function()
    Focus.claimFocus(cw)
    Focus.focusWhere(cw, "charMainInv", function() return true end)
    apple = p:getInventory():AddItem("Base.Apple")
    pcall(function() p:getStats():setHunger(0.4) end)
    ISTimedActionQueue.add(ISEatFoodAction:new(p, apple, 1))
end)
at(1800, function()
    say("232 running: " .. qhead() .. " (" .. qn() .. " queued), focus on " .. tostring(Focus.getFocusedElement(cw) and Focus.getFocusedElement(cw).id))
    Focus.dispatchJoypadDown(cw, Joypad.BButton, jd)
end)
at(2400, function()
    check(qn() == 0, "232 B on a row with nothing to back out of cancels the running eat (queue " .. qn() .. ", head " .. qhead() .. ")")
    check(getJoypadFocus(0) == cw, "232 the window keeps the pad after B cancels (" .. tostring(getJoypadFocus(0) and (getJoypadFocus(0)._zedLabel or getJoypadFocus(0).Type)) .. ")")
    pcall(function() if apple:getContainer() then apple:getContainer():Remove(apple) end end)
end)
-- 230: a trait on the ID card
at(2800, function() ZeD_CharacterWindow.openTab(0, "identity") end)
at(4000, function()
    Focus.claimFocus(cw)
    local found
    for _, s in ipairs(Focus.flatElements(cw)) do local id = tostring(s.id):lower(); if id:find("trait") then found = s; break end end
    say("230 trait stop: " .. tostring(found and found.id))
    if found then Focus.focusWhere(cw, found.zone, function(e) return tostring(e.id) == tostring(found.id) end) end
end)
at(5000, function() pcall(function() getCore():TakeFullScreenshot("zqa_pfh_trait_tip.png") end); say("picture zqa_pfh_trait_tip.png") end)
-- 230: an Equip row
at(5400, function() ZeD_CharacterWindow.openTab(0, "equip") end)
at(6600, function()
    Focus.claimFocus(cw)
    local found
    for _, s in ipairs(Focus.flatElements(cw)) do if s.zone == "charTabContent" and tostring(s.id):lower():find("equip") then found = s; break end end
    say("230 Equip stop: " .. tostring(found and found.id))
    if found then Focus.focusWhere(cw, found.zone, function(e) return tostring(e.id) == tostring(found.id) end) end
end)
at(7600, function()
    pcall(function() getCore():TakeFullScreenshot("zqa_pfh_equip_tip.png") end); say("picture zqa_pfh_equip_tip.png")
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
