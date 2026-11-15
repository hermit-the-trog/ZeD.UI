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
    local items = { pan }
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
    local panel
    local function walk(o, depth)
        if panel or depth > 6 or type(o) ~= "table" then return end
        if o._zedFilter ~= nil then panel = o; return end
        local ok, kids = pcall(function() return o:getChildren() end)
        if ok and kids then for _, k in pairs(kids) do walk(k, depth + 1) end end
    end
    walk(cw, 0)
    if not panel then pcall(function() panel = cw._mainContent and (cw._mainContent.list or cw._mainContent.listPanel) end) end
    say("215 list panel " .. tostring(panel))
    if not panel then return end
    local S = ZeD.InvFilter.of(panel)
    if not S.open then ZeD.InvFilter.toggleOpen(S) end
    ZEDQA_PFG_S = S
end)
at(4700, function()
    if ZEDQA_PFG_S then local ok, e = pcall(ZeD.InvFilter.editField, ZEDQA_PFG_S, cw); say("215 editField ok " .. tostring(ok) .. " " .. tostring(e)) end
end)at(5200, function()
    local f = getJoypadFocus(0)
    say("215 pad focus with the keyboard up: " .. desc(f))
    ZEDQA_PFG_KB = f
    check(f ~= nil and f ~= cw and tostring(desc(f)):lower():find("character") == nil, "215 the on-screen keyboard holds the pad (" .. desc(f) .. ")")
    pcall(function() getCore():TakeFullScreenshot("zqa_pfg_keyboard.png") end)
    if f and f.onJoypadDown then pcall(function() f:onJoypadDown(Joypad.BButton, jd) end) end
end)
at(5800, function()
    local f = getJoypadFocus(0)
    say("226 after B: " .. desc(f) .. " (the Close the keyboard? question); A for Close")
    if f and f.onJoypadDown then pcall(function() f:onJoypadDown(Joypad.AButton, jd) end) end
end)
at(6600, function()
    local f = getJoypadFocus(0)
    say("215 after B then Close: " .. desc(f))
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
