-- ZeDUI/tools/qa/zedqa_padfix_g.lua  (Nov 14 2026, QA): 184 (PlaceItemPad installed in game; A on the Place cursor sets
-- build) and 215 (the filter's on-screen keyboard takes the pad, B closes it and gives the pad back). grep "ZEDQA pfg".
local function say(s) print("ZEDQA pfg " .. tostring(s)) end
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
local function desc(o) return o and tostring(o._zedLabel or o.Type or o) or "nil" end
check(ISPlace3DItemCursor and ISPlace3DItemCursor._zedPadA == true, "184 PlaceItemPad is installed in game (_zedPadA " .. tostring(ISPlace3DItemCursor and ISPlace3DItemCursor._zedPadA) .. ")")
local pan = p:getInventory():AddItem("Base.Saucepan")
local cw
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function()
    local items = ArrayList.new(); items:add(pan)
    ISInventoryPaneContextMenu.onPlaceItemOnGround(items, p)
end)
at(1300, function()
    local d = getCell():getDrag(0)
    say("cursor " .. tostring(d and d.Type) .. " canBeBuild " .. tostring(d and d.canBeBuild) .. " fineAim " .. tostring(d and d.joypadPositionActive))
    if d then d:onJoypadPressButton(jd.id, jd, Joypad.AButton) end
end)
at(2600, function()
    local placed = pan:getWorldItem() ~= nil
    check(placed, "184 A on the Place cursor places the saucepan (on the floor " .. tostring(placed) .. ", in the bag " .. tostring(pan:getContainer() == p:getInventory()) .. ")")
    pcall(function() local d = getCell():getDrag(0); if d then d:exitCursor() end end)
end)
-- 215
at(3000, function()
    ZeD_CharacterWindow.openTab(0, "equip"); cw = ZeD_CharacterWindow.getInstance(0)
end)
at(4200, function()
    Focus.claimFocus(cw)
    local found
    for _, s in ipairs(Focus.flatElements(cw)) do if tostring(s.id) == "view:fbar:field" then found = s end end
    if not found then say("no view:fbar:field stop"); return end
    Focus.focusWhere(cw, found.zone, function(e) return tostring(e.id) == "view:fbar:field" end)
    local e = Focus.getFocusedElement(cw)
    if e and e.onActivate then e.onActivate(cw, e) end
end)
at(5200, function()
    local f = getJoypadFocus(0)
    say("215 pad focus with the keyboard up: " .. desc(f))
    ZEDQA_PFG_KB = f
    check(f ~= nil and f ~= cw and tostring(desc(f)):lower():find("character") == nil, "215 the on-screen keyboard holds the pad (" .. desc(f) .. ")")
    pcall(function() getCore():TakeFullScreenshot("zqa_pfg_keyboard.png") end)
    if f and f.onJoypadDown then pcall(function() f:onJoypadDown(Joypad.BButton, jd) end) end
end)
at(6200, function()
    local f = getJoypadFocus(0)
    say("215 after B: " .. desc(f))
    check(f == cw, "215 B closes the keyboard and the pad is back on the Character window (" .. desc(f) .. ")")
    pcall(function() if pan:getWorldItem() then pan:getWorldItem():getSquare():transmitRemoveItemFromSquare(pan:getWorldItem()) end end)
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
