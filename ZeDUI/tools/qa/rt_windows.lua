-- ZeDUI/tools/qa/rt_windows.lua  (Nov 18 2026, QA): the release test's windows (RELEASE_TEST.md, row rt_windows.lua).
-- Built on rt_kit.lua (the global RT). grep "ZEDQA rt_win".
--   1. Mouse: the inventory key's action (ZeD_CharacterWindow.toggleBothPaired) opens both windows and closes both.
--   2. Every tab on both strips (RT.tabs of each strip, pressed through the strip's own mouse handler): it becomes the
--      active tab (win._activeTab), its drawer settles at the half card (220 design units; 260 is gone, Build Nov 18) or the full card
--      (480), nothing between (ZeD.T.px of each, 1 px slack; the World and Character Loot tabs have no drawer), the
--      other window does not move, no new Lua error, and RT.bounds passes.
--   3. The curtain (WindowCurtain.lua) on each window: on a tab with a drawer the side rolls up under its rod (run in
--      the window's update, as a press is), the rod's tab pressed rolls it down, and the window is back in the same
--      box to the pixel, the other window untouched.
--   4. The pad's Y through FocusManager (Focus.qaButton, the input mode locked to the pad for the run): a tap opens
--      the pair, a tap hides it (rolled), a tap shows it, a hold closes it.
-- Put back: the halves' pins, the active tabs, the window places (ZEDQA_LAYOUT_BACK when the prelude ran), the input
-- mode lock, the game speed, and the pair open or shut as found.
local Q = RT.make("rt_win")
local pn = RT.pn
local T = ZeD.T
local S = { tabs = { c = {}, w = {} }, hasErr = false, st = {} }
local MAXT = 24     -- tab slots per strip (a strip with fewer leaves the rest empty)

-- ===================================================================== helpers
local function errCount()
    local n = nil
    pcall(function() n = getLuaDebuggerErrorCount() end)
    return n
end
local function geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
local function gs(g) return g and string.format("%d,%d %dx%d", g.x, g.y, g.w, g.h) or "none" end
local function sameGeo(a, b, slack)
    if not (a and b) then return false end
    slack = slack or 0
    return math.abs(a.x - b.x) <= slack and math.abs(a.y - b.y) <= slack and math.abs(a.w - b.w) <= slack and math.abs(a.h - b.h) <= slack
end
local function wOf(k) if k == "c" then return RT.cw() end; return RT.ww() end
local function otherOf(k) if k == "c" then return RT.ww() end; return RT.cw() end
local function nameOf(k) if k == "c" then return "Character" end; return "World" end
local function press(k, id) if k == "c" then return RT.charTab(id) end; return RT.worldTab(id) end
local function worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(pn) end); return o end
local function bothOpen()
    local c, w = RT.cw(), RT.ww()
    return RT.isOpen() and worldOpen() and c ~= nil and w ~= nil and c:isVisible() and w:isVisible()
end
local function bothShut() return (not RT.isOpen()) and (not worldOpen()) end
local function toggle() return pcall(ZeD_CharacterWindow.toggleBothPaired, pn) end
-- the drawer's card: "closed", "half", "full" or "NEITHER" (screen px; 1 px slack)
local function cardName(eff)
    if eff <= 0 then return "closed" end
    if math.abs(eff - T.px(220)) <= 1 then return "half" end
    if math.abs(eff - T.px(480)) <= 1 then return "full" end
    return "NEITHER"
end
-- true once the window shows tab id and its drawer has held one width for 15 frames
local function settled(k, id)
    local w = wOf(k)
    if not w then return false end
    local e = math.floor(w._drawerEffW or 0)
    if e == S.st.lastE then S.st.same = (S.st.same or 0) + 1 else S.st.same, S.st.lastE = 0, e end
    return w._activeTab == id and S.st.same >= 15
end
local function resetSettle() S.st.same, S.st.lastE = 0, nil end
-- a press the way the engine delivers one: inside the element's update, followed by its onResize
-- (as zedqa_curtain.lua's viaUpdate; el._qaPressDone is false until the update ran it)
local function viaUpdate(el, fn)
    local own = rawget(el, "update")
    el._qaPressDone = false
    el.update = function(self)
        self.update = own
        self:update()
        local ok, e = pcall(fn, self)
        if not ok then S.pressErr = tostring(e) end
        pcall(function() self:onResize() end)
        self._qaPressDone = true
    end
end
-- the halves' pins of both windows, from the character's saved table (WindowHalves.lua keeps them there)
local PIN_KEYS = { "charInv", "charTabs", "char", "worldInv", "worldTabs", "world" }
local function pinAll()
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and w._halves and ZeD.Halves and ZeD.Halves.setPin then pcall(ZeD.Halves.setPin, w, nil, true) end
    end
end
-- the pad's Y: down (with the press handed to the window holding the pad, as the engine's onJoypadDown would),
-- up, and let go of the hook
local function yDown()
    RT.pad("Y", true)
    local F = RT.focus()
    local fw = nil
    pcall(function() fw = F.getFocusedWindow(pn) end)
    if fw and fw:isVisible() and not fw.windowShaded then pcall(F.dispatchJoypadDown, fw, Joypad.YButton) end
end
local function yTap()
    Q.step(2, function() yDown() end)
    Q.step(4, function() RT.pad("Y", false) end)
    Q.step(4, function() RT.pad("Y", nil) end)
end
local function rolledBoth()
    local F = RT.focus()
    local c, w = RT.cw(), RT.ww()
    return F and c and w and F.isRolled(c) and F.isRolled(w) or false
end

-- ===================================================================== setup
Q.step(10, function()
    S.hasErr = errCount() ~= nil
    if not S.hasErr then Q.say("note: no Lua error counter (getLuaDebuggerErrorCount) in this game: the no-error checks are off") end
    S.wasOpen = RT.isOpen()
    S.speed = getGameSpeed()
    if S.speed == 0 then pcall(setGameSpeed, 1) end
    S.snap = (S.wasOpen and ZEDQA_LAYOUT_SNAP) and ZEDQA_LAYOUT_SNAP() or nil
    S.geoC, S.geoW = geo(RT.cw()), geo(RT.ww())
    S.tabC0 = RT.cw() and RT.cw()._activeTab or nil
    S.tabW0 = RT.ww() and RT.ww()._activeTab or nil
    S.pins = {}
    pcall(function()
        local t = RT.p:getModData().ZeD_WinPinned
        if t then for _, k in ipairs(PIN_KEYS) do S.pins[k] = t[k] end end
    end)
    Q.say(string.format("screen %dx%d, half card %d / %d px, full card %d px, pair open %s",
        RT.core:getScreenWidth(), RT.core:getScreenHeight(), T.px(220), T.px(260), T.px(480), tostring(S.wasOpen)))
end)

-- ===================================================================== 1. mouse: the inventory key's action
Q.step(2, function() RT.pairShut() end)
Q.waitFor(5, 240, bothShut, function(ok)
    if S.wasOpen then Q.check(ok, "mouse: the inventory key's action closes both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen())) end
end)
Q.step(5, function() S.tOk = toggle() end)
Q.waitFor(5, 300, bothOpen, function(ok)
    Q.check(ok and S.tOk, "mouse: the inventory key's action opens both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen()))
end)
Q.step(30, function() RT.bounds(Q, "both windows open") end)
Q.step(2, function() S.tOk = toggle() end)
Q.waitFor(5, 300, bothShut, function(ok)
    Q.check(ok and S.tOk, "mouse: the inventory key's action closes both windows again", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen()))
end)
Q.step(5, function() toggle() end)
Q.waitFor(5, 300, bothOpen, function(ok)
    if not ok then Q.check(false, "mouse: the pair opens for the tab walk") end
    pinAll()   -- (no half rolls by itself while the script works: the pointer is elsewhere)
end)

-- ===================================================================== 2. every tab on both strips
local function tabWalk(k)
    Q.step(10, function()
        local w = wOf(k)
        local strip = w and ((k == "c") and RT.charStrip() or RT.worldStrip())
        S.tabs[k] = RT.tabs(strip)
        Q.check(#S.tabs[k] >= 2, nameOf(k) .. " window: its strip offers its tabs", table.concat(S.tabs[k], ", "))
        if #S.tabs[k] > MAXT then Q.check(false, nameOf(k) .. " window: at most " .. MAXT .. " tabs walked", #S.tabs[k] .. " on the strip") end
    end)
    for i = 1, MAXT do
        Q.step(2, function()
            local id = S.tabs[k][i]
            S.cur = id
            if not id then return end
            resetSettle()
            S.err = errCount()
            S.oth = geo(otherOf(k))
            S.pressed = press(k, id)
        end)
        Q.waitFor(5, 600, function()
            if not S.cur then return true end
            return settled(k, S.cur)
        end, function(ok)
            local id = S.cur
            if not id then return end
            local w = wOf(k)
            local label = nameOf(k) .. " tab " .. id
            local act = w and w._activeTab
            Q.check(S.pressed and act == id, label .. ": pressed on the strip, it is the active tab", "active " .. tostring(act))
            local eff = w and math.floor(w._drawerEffW or 0) or -1
            local card = cardName(eff)
            if id == "loot" then
                Q.check(card ~= "NEITHER", label .. ": no drawer, or the half or the full card", eff .. " px = " .. card)
            else
                Q.check(ok and (card == "half" or card == "full"), label .. ": its drawer is the half card or the full card, nothing between",
                    eff .. " px = " .. card .. (ok and "" or " (still moving)"))
            end
            local og = geo(otherOf(k))
            Q.check(sameGeo(og, S.oth, 1), label .. ": the other window did not move or change size", gs(S.oth) .. " -> " .. gs(og))
            if S.hasErr then
                local e = errCount()
                Q.check(e == S.err, label .. ": it opened and drew with no Lua error", "errors " .. tostring(S.err) .. " -> " .. tostring(e))
            end
            RT.bounds(Q, label)
        end)
    end
    Q.step(2, function() resetSettle(); press(k, "loot") end)
    Q.waitFor(5, 600, function() return settled(k, "loot") end, function() end)
end
tabWalk("c")
tabWalk("w")

-- ===================================================================== 3. the curtain rolls and unrolls back to the same box
local CURTAIN_TABS = { c = { "skills", "health", "journal" }, w = { "maps", "forage", "craft" } }
local function curtain(k)
    local label = nameOf(k) .. " curtain"
    Q.step(5, function()
        S.ctab = nil
        for _, want in ipairs(CURTAIN_TABS[k]) do
            for _, id in ipairs(S.tabs[k]) do if id == want and not S.ctab then S.ctab = id end end
        end
        if not S.ctab then for _, id in ipairs(S.tabs[k]) do if id ~= "loot" and not S.ctab then S.ctab = id end end end
        S.cskip = nil
        if not S.ctab then S.cskip = "no tab with a drawer on the strip"; return end
        resetSettle()
        press(k, S.ctab)
    end)
    Q.waitFor(5, 600, function() return S.cskip ~= nil or settled(k, S.ctab) end, function()
        if S.cskip then return end
        local w = wOf(k)
        local can = false
        pcall(function() can = w._curtain.canRoll() end)
        if not can then S.cskip = "the side cannot roll on " .. tostring(S.ctab) .. " here (the drawer hides the list)"; return end
        S.box, S.obox = geo(w), geo(otherOf(k))
        S.err = errCount()
        S.pressErr = nil
        viaUpdate(w, function(self) ZeD.Curtain.roll(self) end)
    end)
    Q.waitFor(2, 400, function()
        if S.cskip then return true end
        local w = wOf(k)
        local rod = w and w._rod
        return w._qaPressDone == true and w._rolled == true and rod ~= nil and rod._chip ~= nil and (rod._h or 999) <= T.titleBarH
    end, function(ok)
        if S.cskip then Q.skip(label, S.cskip); return end
        local w = wOf(k)
        local rod = w._rod
        Q.check(ok and w._rolled == true and rod ~= nil and rod:isVisible(), label .. ": the side rolls up under its rod (on " .. S.ctab .. ")",
            "rolled " .. tostring(w._rolled) .. ", rod " .. tostring(rod ~= nil and rod:isVisible()) .. (S.pressErr and (", error " .. S.pressErr) or ""))
        local g = geo(w)
        local rw = w._rollW or 0
        Q.check(g.w == S.box.w - rw and g.y == S.box.y and g.h == S.box.h, label .. ": rolled, the window is its box less the side",
            gs(S.box) .. " less " .. rw .. " -> " .. gs(g))
        RT.bounds(Q, label .. " rolled")
        -- the rod's tab pressed (in the rod's update): it rolls down, then the side comes back
        if rod and rod._chip then
            local c = rod._chip
            viaUpdate(rod, function(self) self:onMouseDown(c.x + 2, c.y + 2); self:onMouseUp(c.x + 2, c.y + 2) end)
        else
            ZeD.Curtain.unroll(w)
        end
    end)
    Q.waitFor(2, 600, function()
        if S.cskip then return true end
        local w = wOf(k)
        return w and not w._rolled
    end, function(ok)
        if S.cskip then return end
        local w = wOf(k)
        local g = geo(w)
        Q.check(ok, label .. ": the rod's tab rolls the side back down", "rolled " .. tostring(w._rolled))
        Q.check(sameGeo(g, S.box, 0), label .. ": unrolled, the window is back in the same box to the pixel", gs(S.box) .. " -> " .. gs(g))
        Q.check(not (w._rod and w._rod:isVisible()), label .. ": the rod is gone from the screen")
        Q.check(sameGeo(geo(otherOf(k)), S.obox, 0), label .. ": the other window never moved", gs(S.obox) .. " -> " .. gs(geo(otherOf(k))))
        if S.hasErr then Q.check(errCount() == S.err, label .. ": no Lua error through the roll", tostring(S.err) .. " -> " .. tostring(errCount())) end
    end)
    Q.step(2, function() resetSettle(); press(k, "loot") end)
    Q.waitFor(5, 600, function() return settled(k, "loot") end, function() end)
end
curtain("c")
curtain("w")

-- ===================================================================== 4. the pad's Y (FocusManager's own Y tap and hold)
Q.step(5, function()
    S.padOk = RT.focus() ~= nil and RT.focus().qaButton ~= nil and ZeD.Input.Detector ~= nil
    if not S.padOk then return end
    pcall(function() S.lockWas = RT.p:getModData().ZeD_Gamepad and RT.p:getModData().ZeD_Gamepad.inputModeLock end)
    pcall(ZeD.Input.Detector.setLockedMode, "gamepad")
    pcall(RT.focus().releaseFocus, pn)
end)
Q.step(20, function() if S.padOk then RT.pairShut() end end)
Q.waitFor(5, 300, function() return (not S.padOk) or bothShut() end, function(ok)
    if not S.padOk then Q.skip("the pad's Y", "FocusManager has no QA button hook (Focus.qaButton)"); return end
    Q.check(ok, "pad: before Y, both windows are closed")
end)
yTap()
Q.waitFor(2, 300, function() return (not S.padOk) or bothOpen() end, function(ok)
    if S.padOk then Q.check(ok, "pad: a tap of Y opens both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen())) end
end)
Q.step(20, function() if S.padOk then RT.bounds(Q, "opened by the pad") end end)
yTap()
Q.waitFor(2, 300, function() return (not S.padOk) or rolledBoth() end, function(ok)
    if S.padOk then Q.check(ok, "pad: a second tap of Y rolls both windows up (hidden)") end
end)
yTap()
Q.waitFor(2, 300, function() return (not S.padOk) or (bothOpen() and not RT.focus().isRolled(RT.cw()) and not RT.focus().isRolled(RT.ww())) end, function(ok)
    if S.padOk then Q.check(ok, "pad: a third tap of Y brings both windows back") end
end)
-- a hold past the hold time (gp.holdMs, 400 ms) closes the pair
Q.step(10, function() if S.padOk then yDown() end end)
Q.waitFor(2, 900, function() return (not S.padOk) or bothShut() end, function(ok)
    RT.pad("Y", false)
    if S.padOk then Q.check(ok, "pad: holding Y closes both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen())) end
end)
Q.step(4, function() RT.pad("Y", nil) end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    RT.pad("Y", nil)
    if S.padOk then
        pcall(ZeD.Input.Detector.setLockedMode, nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then pcall(ZeD.Input.Detector.setLockedMode, S.lockWas) end
    end
    pcall(function() RT.focus().releaseFocus(pn) end)
    -- the halves' pins as they were (the saved table; the open windows below read it again)
    pcall(function()
        local md = RT.p:getModData()
        md.ZeD_WinPinned = md.ZeD_WinPinned or {}
        for _, k in ipairs(PIN_KEYS) do md.ZeD_WinPinned[k] = S.pins[k] end
    end)
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and w._rolled and ZeD.Curtain then pcall(ZeD.Curtain.finishUnroll, w) end
    end
    if S.wasOpen and not RT.isOpen() then toggle() end
    if (not S.wasOpen) and RT.isOpen() then RT.pairShut() end
end)
Q.waitFor(10, 300, function() return S.wasOpen == bothOpen() or ((not S.wasOpen) and bothShut()) end, function()
    if not S.wasOpen then return end
    local c, w = RT.cw(), RT.ww()
    -- the pins back on the live windows
    if c and c._halves and ZeD.Halves then
        pcall(ZeD.Halves.setPin, c, "inv", S.pins.charInv == true); pcall(ZeD.Halves.setPin, c, "drawer", S.pins.charTabs == true)
    end
    if w and w._halves and ZeD.Halves then
        pcall(ZeD.Halves.setPin, w, "inv", S.pins.worldInv == true); pcall(ZeD.Halves.setPin, w, "drawer", S.pins.worldTabs == true)
    end
    if ZEDQA_LAYOUT_BACK and S.snap then ZEDQA_LAYOUT_BACK(S.snap, "rt_win") end
end)
Q.step(30, function()
    if not S.wasOpen then return end
    if S.tabC0 and S.tabC0 ~= "loot" then RT.charTab(S.tabC0) end
    if S.tabW0 and S.tabW0 ~= "loot" then RT.worldTab(S.tabW0) end
end)
Q.step(60, function()
    if S.speed == 0 then pcall(setGameSpeed, 0) end
    if S.wasOpen then
        local c, w = geo(RT.cw()), geo(RT.ww())
        Q.check(sameGeo(c, S.geoC, 1) and sameGeo(w, S.geoW, 1), "put back: both windows are where and as big as they were",
            "Character " .. gs(S.geoC) .. " -> " .. gs(c) .. ", World " .. gs(S.geoW) .. " -> " .. gs(w))
    else
        Q.check(bothShut(), "put back: the pair is shut, as found")
    end
end)
Q.start()
