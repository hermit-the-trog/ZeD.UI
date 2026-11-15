-- ZeDUI/tools/qa/zedqa_b15.lua  (Nov 15 2026, QA): beta 15's fixes for the director's beta 14 notes, in the game.
-- 245 a stack opened with A lists every item as its own row under a header stop; A on the header shuts it.
-- 184 a game place cursor on a pad keeps A off the world (the player's ignore-context flag), and lets go after.
-- 246 the focused row going with its container, no rows left: focus on the ground's container button, not Filter.
-- 242 paused with a window over the screen's middle: the "Game Paused" balloon shows; unpaused it goes.
-- 240 the input turning to the pad hides the mouse pointer.
-- 237 aiming hides the windows with no window holding the pad, and closes Messages.
-- 241 ZeD setup from the wheel puts the pad on the pause screen.
-- grep "ZEDQA b15"; pictures Screenshots/zqa_b15_*.png.
local function say(s) print("ZEDQA b15 " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b15_" .. n .. ".png") end) end
local p = getPlayer()
local Focus = ZeD.Input.Focus
local Det = ZeD.Input.Detector
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
say("pad " .. tostring(jd and jd.id))
local function desc(o) if o == nil then return "nil" end return tostring(o._zedLabel or o.Type or o) end
local function rows(w, zone, ft)
    local n, head = 0, nil
    for _, s in ipairs(Focus.flatElements(w)) do
        if s.zone == zone and s.el then
            if s.el.isStackHead then
                local it = s.el.rep or (s.el.items and s.el.items[1])
                if it and it.getFullType and it:getFullType() == ft then head = s end
            elseif s.el.item and s.el.item.getFullType and s.el.item:getFullType() == ft then n = n + 1 end
        end
    end
    return n, head
end
local cw, ww, rags = nil, nil, {}
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end

-- 245: three rags, the closed row, A opens, A on the header shuts
local RAG = "Base.RippedSheets"
at(300, function()
    ZeD_CharacterWindow.openTab(0, "equip"); cw = ZeD_CharacterWindow.getInstance(0)
    local inv = p:getInventory()
    local had = inv:getItemsFromFullType(RAG)
    for k = (had and had:size() or 0), 2 do rags[#rags + 1] = inv:AddItem(RAG) end
    say("245 rags added " .. #rags)
end)
at(1500, function()
    Focus.claimFocus(cw)
    local n, head = rows(cw, "charMainInv", RAG)
    check(n == 1 and head == nil, "245 a closed stack is one row (" .. n .. " rows, header " .. tostring(head ~= nil) .. ")")
    Focus.focusWhere(cw, "charMainInv", function(e) return e.item ~= nil and e.item:getFullType() == RAG end)
    say("245 focused " .. tostring(Focus.getFocusedElement(cw) and Focus.getFocusedElement(cw).id))
    -- (A is a tap: down, then up a few frames later; the hold timer decides on the release)
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.qaButton("A", true); Focus.dispatchJoypadDown(cw, Joypad.AButton, jd)
end)
at(1650, function() Focus.qaButton("A", false) end)
at(1900, function() Focus.qaButton("A", nil) end)
at(2300, function()
    local n, head = rows(cw, "charMainInv", RAG)
    local el = Focus.getFocusedElement(cw)
    check(n == 3, "245 A opens the stack: every rag its own row, the first included (" .. n .. ")")
    check(head ~= nil, "245 the open stack has a header stop")
    check(el and el.item and el.item:getFullType() == RAG and not el.isStackHead, "245 A lands on the first item's row (" .. tostring(el and el.id) .. ")")
    shot("stack_open")
    if head then Focus.focusWhere(cw, head.zone, function(e) return e.isStackHead and tostring(e.id) == tostring(head.id) end) end
    say("245 on the header " .. tostring(Focus.getFocusedElement(cw) and Focus.getFocusedElement(cw).isStackHead))
end)
at(2600, function() Focus.qaButton("A", true); Focus.dispatchJoypadDown(cw, Joypad.AButton, jd) end)
at(2750, function() Focus.qaButton("A", false) end)
at(2950, function() Focus.qaButton("A", nil); Det.setLockedMode(nil) end)
at(3300, function()
    local n, head = rows(cw, "charMainInv", RAG)
    local el = Focus.getFocusedElement(cw)
    check(n == 1 and head == nil, "245 A on the header shuts the stack (" .. n .. " rows)")
    check(el and el.item and el.item:getFullType() == RAG, "245 focus on the closed row (" .. tostring(el and el.id) .. ")")
end)

-- 184: a place cursor up on a pad holds the world's A; after it goes, the world gets A back
local apple
at(3400, function()
    apple = p:getInventory():AddItem("Base.Apple")
    local ok, e = pcall(function()
        local cur = ISPlace3DItemCursor:new(p, { apple })
        getCell():setDrag(cur, 0)
    end)
    say("184 cursor up " .. tostring(ok) .. " " .. tostring(e))
end)
at(4000, function()
    check(getCell():getDrag(0) ~= nil and p:isIgnoreContextKey(), "184 with the cursor up the world's A is held (flag " .. tostring(p:isIgnoreContextKey()) .. ")")
    getCell():setDrag(nil, 0)
end)
at(4800, function()
    check(not p:isIgnoreContextKey(), "184 the cursor gone, the world gets A back (flag " .. tostring(p:isIgnoreContextKey()) .. ")")
end)

-- 246: a row in a microwave, the microwave gone, focus on the ground's button
local micro, msq, mapple
at(5200, function()
    ZeD_WorldWindow.openTab(0, "loot"); ww = ZeD_WorldWindow.getWindow(0)
    msq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), math.floor(p:getZ()))
    micro = IsoStove.new(getCell(), msq, getSprite("appliances_cooking_01_24"))
    pcall(function() micro:createContainersFromSpriteProperties() end)
    msq:AddSpecialObject(micro)
    mapple = micro:getContainer():AddItem("Base.Apple")
end)
at(6500, function()
    say("246 selectContainer " .. tostring(ZeD_WorldWindow.selectContainer(micro:getContainer(), 30, 0)))
end)
at(7800, function()
    Focus.claimFocus(ww)
    local ok = Focus.focusWhere(ww, "worldMainInv", function(e) return e.item == mapple end)
    local z = Focus.getFocusedZone(ww)
    say("246 on the microwave's apple " .. tostring(ok) .. " zone " .. tostring(z and z.zone))
    pcall(function() msq:transmitRemoveItemFromSquare(micro) end)
    pcall(function() msq:RemoveTileObject(micro) end)
end)
at(9800, function()
    local z, el = Focus.getFocusedZone(ww), Focus.getFocusedElement(ww)
    -- (the QA site's ground has things on it, so a ground row is a fair landing; with no rows left the fix sends it to
    -- the container buttons. Either way never Filter or the header.)
    local okZone = z and (z.zone == "worldContainerStrip" or (z.zone == "worldMainInv" and el and el.item ~= nil))
    check(okZone, "246 the row gone with its container, focus on the ground (zone " ..
        tostring(z and z.zone) .. ", id " .. tostring(el and el.id) .. ")")
    check(not (el and tostring(el.id):lower():find("filter")), "246 not the Filter button")
    shot("ground_focus")
end)

-- 242: paused, a box over the middle, the balloon

local function balloonUp()
    local ui = UIManager.getUI()
    for j = 0, ui:size() - 1 do
        local t = ui:get(j):getTable()
        if t and t.Type == "ZeD_PausedNoticeBox" then return t:isVisible() end
    end
    return nil
end
at(10200, function()
    setGameSpeed(0)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    -- (a real window over the middle, the Survival Guide: a plain ISPanel takes no clicks so it counts as see-through,
    -- and ZeD files other mods' ISModalDialogs in Messages)
    say("242 guide " .. tostring(pcall(function() ZeD.Guide.openWindow(0) end)) .. " (screen " .. sw .. "x" .. sh .. ")")
end)
at(11000, function()
    check(isGamePaused(), "242 the game is paused")
    check(balloonUp() == true, "242 the Game Paused balloon shows over a window in the middle (" .. tostring(balloonUp()) .. ")")
    shot("paused")
    pcall(function() ZeD.Guide.toggle(0) end)
end)
at(11600, function()
    check(balloonUp() ~= true, "242 nothing over the middle, no balloon")
    setGameSpeed(1)
end)
at(12200, function() check(balloonUp() ~= true, "242 unpaused, no balloon") end)

-- 240: the pad's mode hides the pointer (the call the watcher makes, read back)
local cursorCalls = {}
local realSet = Mouse.setCursorVisible
at(12600, function()
    Mouse.setCursorVisible = function(v) cursorCalls[#cursorCalls + 1] = v; return realSet(v) end
    Det.setLockedMode(Det.MODE_KBM)
end)
at(13100, function() Det.setLockedMode(Det.MODE_GAMEPAD) end)
at(13800, function()
    check(cursorCalls[#cursorCalls] == false, "240 the pad's mode hides the pointer (calls " .. table.concat((function()
        local t = {}; for _, v in ipairs(cursorCalls) do t[#t + 1] = tostring(v) end; return t end)(), ",") .. ")")
    Det.setLockedMode(Det.MODE_KBM)
end)
at(14400, function()
    check(cursorCalls[#cursorCalls] == true, "240 back to the mouse, the pointer shows")
    Mouse.setCursorVisible = realSet
    Det.setLockedMode(nil)
end)

-- 237: both windows up, no window holding the pad, Messages open; aim
-- (the right stick held over: the game's axis read answers 0.9 for the right stick's X, axis 2, while the stub is on;
-- the player's own aiming flag is reset by the game every update, so it can't be set from here)
local realAxis = getControllerAxisValue
local function aimStub(on)
    if on then getControllerAxisValue = function(c, a) if a == 2 then return 0.9 end return realAxis(c, a) end
    else getControllerAxisValue = realAxis end
end
-- (a window in halves hides by rolling its halves, not by its own shade)
local function upState(w)
    if w == nil or not w:isVisible() or w.windowShaded then return false end
    local s = w._halves
    if s and s.inv and s.drawer and s.inv.rolled and s.drawer.rolled then return false end
    return true
end
local MW = ZeD.MessagesWindow
at(14800, function()
    ZeD_CharacterWindow.openTab(0, "equip"); ZeD_WorldWindow.openTab(0, "loot")
    pcall(function() Focus.releaseFocus(0) end)
    setJoypadFocus(0, nil)
    pcall(function() MW.open(0) end)
    -- (the QA save's halves are pinned, and a pinned half stays up on aim by design: unpinned here, put back after)
    for _, w in ipairs({ cw, ww }) do
        local s = w and w._halves
        if s then
            w._qaPins = { inv = s.inv and s.inv.pinned, drawer = s.drawer and s.drawer.pinned, win = w.pinned }
            if s.inv then s.inv.pinned = false end
            if s.drawer then s.drawer.pinned = false end
        else
            w._qaPins = { win = w.pinned }
        end
        w.pinned = false
        say("237 unpinned " .. desc(w) .. " (was inv " .. tostring(w._qaPins.inv) .. ", drawer " .. tostring(w._qaPins.drawer) .. ", window " .. tostring(w._qaPins.win) .. ")")
    end
end)
at(15800, function()
    local mw = MW.get and MW.get(0)
    say("237 before: Character " .. tostring(upState(cw)) .. ", World " .. tostring(upState(ww)) .. ", Messages " .. tostring(mw and mw:isVisible()) .. ", pad on " .. desc(getJoypadFocus(0)))
    shot("before_aim")
    Det.setLockedMode(Det.MODE_GAMEPAD); aimStub(true)   -- (aiming counts on the pad: the mode the director plays in)
end)
at(16400, function() aimStub(false); Det.setLockedMode(nil) end)
at(17600, function()
    local mw = MW.get and MW.get(0)
    check(not upState(cw), "237 aiming hides the Character window (shaded " .. tostring(cw and cw.windowShaded) .. ", visible " .. tostring(cw and cw:isVisible()) .. ")")
    check(not upState(ww), "237 aiming hides the World window (shaded " .. tostring(ww and ww.windowShaded) .. ", visible " .. tostring(ww and ww:isVisible()) .. ")")
    check(not (mw and mw:isVisible()), "237 aiming closes Messages")
    shot("after_aim")
    for _, w in ipairs({ cw, ww }) do
        local s, k = w and w._halves, w and w._qaPins
        if k then
            if s and s.inv then s.inv.pinned = k.inv end
            if s and s.drawer then s.drawer.pinned = k.drawer end
            w.pinned = k.win; w._qaPins = nil
        end
        pcall(function() if ZeD.Halves and w._halves then ZeD.Halves.showAll(w) end end)
    end
end)

-- 241: ZeD setup from the wheel puts the pad on the pause screen
at(18200, function()
    -- (Messages takes the pause key first, so it must be shut before the pause screen can open)
    pcall(function() local mw = MW.get(0); if mw and mw:isVisible() then mw:close() end end)
    local ok, e = pcall(function() ZeD.DpadWheels.H.openSetup(p, 0) end)
    say("241 openSetup " .. tostring(ok) .. " " .. tostring(e))
end)
at(19800, function()
    local m = MainScreen and MainScreen.instance
    local j = JoypadState.players[1]
    check(m and m:isVisible(), "241 the pause screen is up")
    check(j and j.inMainMenu == true and j.focus == m, "241 the wheel's pad is on it (inMainMenu " .. tostring(j and j.inMainMenu) .. ", focus " .. desc(j and j.focus) .. ")")
    shot("setup")
end)
at(20400, function()
    pcall(function() ToggleEscapeMenu(getCore():getKey("Main Menu")) end)
end)
at(21400, function()
    local m = MainScreen and MainScreen.instance
    if m and m:isVisible() then pcall(function() ToggleEscapeMenu(Keyboard.KEY_ESCAPE) end) end
    setGameSpeed(1)
    for _, r in ipairs(rags) do pcall(function() if r:getContainer() then r:getContainer():Remove(r) end end) end
    pcall(function() if apple:getContainer() then apple:getContainer():Remove(apple) end end)
    say("passed " .. nPass .. ", failed " .. nFail)
    say("DONE")
end)
-- (one step a frame, each waiting its gap after the step before it actually ran: when the game stalls (the Guide
-- opening, a cursor going up) the steps behind keep their gaps instead of all firing in the same frame)
local lastAt, lastMs = nil, 0
local function tick()
    local now = getTimestampMs()
    if not lastAt then lastAt = now end
    local nxt = steps[i + 1]
    if nxt and now - lastAt >= nxt.ms - lastMs then
        i = i + 1
        lastAt, lastMs = now, nxt.ms
        local ok, e = pcall(nxt.fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
