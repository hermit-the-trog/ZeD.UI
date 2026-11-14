-- ZeDUI/tools/qa/zedqa_padfix_a.lua  (Nov 14 2026, QA): checks for Build's pad fixes a6f4ab1fd, each with a ZeD window
-- holding the pad (ZeD_CharacterWindow.getInstance(0) opened + ZeD.Input.Focus.claimFocus). 184 Place item from the
-- right-click menu then A; 187 Start pauses; 188 Y and the D-pad in the pause menu; 189 Wear from a crate with Put things
-- back on. Presses go through the game's JoypadState.controllers[id]:onPressButton. grep "ZEDQA pfa".
local function say(s) print("ZEDQA pfa " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local function desc(o) if o == nil then return "nil" end return tostring(o._zedLabel or o.Type or o) end
-- the pad for player 0
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
if not jd then say("ERR no pad for player 0 (no controller connected)"); say("DONE"); return end
local ctl
for i = 0, 15 do local c = JoypadState.controllers[i]; if c and c.joypad == jd then ctl = c end end
local Focus = ZeD.Input and ZeD.Input.Focus
local function press(b) local ok, e = pcall(function() ctl:onPressButton(b) end); if not ok then say("ERR press " .. tostring(e)) end end
local function claim()
    local win = ZeD_CharacterWindow.getInstance(0)
    pcall(function() if not win:isReallyVisible() then ZeD.toggleBothPaired(0) end end)
    win = ZeD_CharacterWindow.getInstance(0)
    pcall(function() Focus.claimFocus(win) end)
    return win
end
local function pauseUp() local m = MainScreen and MainScreen.instance; return m and m.inGame and m:isReallyVisible() and true or false end
local function radialUp() local r = false; pcall(function() r = getPlayerRadialMenu(0):isReallyVisible() end); return r end
local putBackWas = nil
local mug, shirt, crate, csq
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
-- 184
at(300, function()
    local win = claim()
    say("184 focus before Place: " .. desc(getJoypadFocus(0)))
    check(getJoypadFocus(0) == win, "184 setup: a ZeD window holds the pad (" .. desc(getJoypadFocus(0)) .. ")")
    mug = p:getInventory():AddItem("Base.Saucepan") or p:getInventory():AddItem("Base.Apple")
    say("184 mug " .. tostring(mug and mug:getDisplayName()) .. " in the bag " .. tostring(mug and mug:getContainer() == p:getInventory()))
    local items = ArrayList.new(); items:add(mug)
    ISInventoryPaneContextMenu.onPlaceItemOnGround(items, p)
end)
at(1500, function()
    say("184 after Place: focus " .. desc(getJoypadFocus(0)) .. ", cursor " .. tostring(getCell():getDrag(0) and getCell():getDrag(0).Type))
    check(getJoypadFocus(0) == nil, "184 the pad is let go while the Place cursor is up (" .. desc(getJoypadFocus(0)) .. ")")
    press(Joypad.AButton)
end)
at(3000, function()
    local inBag = mug:getContainer() == p:getInventory()
    local onFloor = mug:getWorldItem() ~= nil
    check(not inBag and onFloor, "184 A placed the mug (in the bag " .. tostring(inBag) .. ", on the floor " .. tostring(onFloor) .. ")")
    pcall(function() local d = getCell():getDrag(0); if d then d:exitCursor() end end)
end)
-- 187
at(3500, function()
    local win = claim()
    say("187 focus before Start: " .. desc(getJoypadFocus(0)))
    press(Joypad.Start)
end)
at(5000, function()
    check(pauseUp() and isGamePaused(), "187 Start with a ZeD window focused opens the pause menu (up " .. tostring(pauseUp()) .. ", paused " .. tostring(isGamePaused()) .. ")")
end)
-- 188 (the pause menu is up from 187)
at(5500, function() say("188 focus in the pause menu: " .. desc(getJoypadFocus(0))); press(Joypad.YButton) end)
at(7000, function()
    check(pauseUp() and getJoypadFocus(0) == MainScreen.instance, "188 after Y the pause menu keeps the pad (focus " .. desc(getJoypadFocus(0)) .. ")")
    press(Joypad.DPadDown)
end)
at(8500, function()
    check(not radialUp(), "188 the D-pad in the pause menu opens no wheel (radial up " .. tostring(radialUp()) .. ")")
    check(pauseUp() and getJoypadFocus(0) == MainScreen.instance, "188 after the D-pad the pause menu still has the pad (" .. desc(getJoypadFocus(0)) .. ")")
    pcall(function() if pauseUp() then JoypadControllerData.onPauseButtonPressed(ctl) end end)
    pcall(function() if radialUp() then getPlayerRadialMenu(0):undisplay() end end)
end)
-- 189
at(10000, function()
    say("189 paused " .. tostring(isGamePaused()))
    pcall(function() putBackWas = ZeD.Settings.putBackOption:getValue(); ZeD.Settings.putBackOption:setValue(2) end)
    say("189 Put things back on: " .. tostring(ZeD.Settings.putBackOn and ZeD.Settings.putBackOn()))
    csq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), math.floor(p:getZ()))
    crate = IsoThumpable.new(getCell(), csq, "carpentry_01_16", false, nil)
    crate:setIsContainer(true); crate:getContainer():setType("crate"); csq:AddSpecialObject(crate)
    shirt = crate:getContainer():AddItem("Base.Tshirt_DefaultTEXTURE_TINT")
    local c = ZeD_ItemCard:new(0, 0, 220, 300, "drawer", 0); c:initialise(); c.item = shirt; c.playerNum = 0; c.sourceContext = "loot"
    local ok, e = pcall(c._dispatchHeaderVerb, c, "EQUIP")
    say("189 EQUIP ok=" .. tostring(ok) .. " " .. tostring(e))
end)
at(22000, function()
    local worn = false; pcall(function() worn = p:isEquipped(shirt) end)
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local n = q and q.queue and #q.queue or 0
    check(worn, "189 with Put things back on, the shirt worn from a crate stays on (worn " .. tostring(worn) .. ", in " ..
        tostring(shirt:getContainer() and shirt:getContainer():getType()) .. ", queue " .. n .. ")")
    pcall(function() if p:isEquipped(shirt) then p:removeWornItem(shirt) end; local c = shirt:getContainer(); if c then c:Remove(shirt) end end)
    pcall(function() csq:RemoveTileObject(crate) end)
    pcall(function() if putBackWas then ZeD.Settings.putBackOption:setValue(putBackWas) end end)
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
