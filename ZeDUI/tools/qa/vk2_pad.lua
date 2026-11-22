-- ZeDUI/tools/qa/vk2_pad.lua  (Nov 22 2026, QA, KISS batch K2; tag vk2_pad): the in-game proof of Build's fixes for
-- K2-1, K2-4 and K2-5, the three the player meets on a pad (findings: ZeDUI/qa/audits/2026-11-22_kiss_fixes_K2.md; the
-- old code 0ebd56570, the fixes in 194d5dd2a (K2-5) and da6134ec4 (K2-1, K2-4)). Built on rt_kit.lua (the global RT),
-- run after zedqa_prelude.lua (its ZEDQA_CAR_* helpers spawn, wait for, seat and take away the car; without the prelude
-- the car is spawned as beta21_report.lua:459-494 spawns its pickup). grep "ZEDQA vk2_pad". For QA's manifest:
-- vk2_pad.lua | vk2_pad | timeout=300
--
-- The findings, as the player meets them on a pad:
--   K2-1  the right-click strip moves only with Left and Right: Up and Down are dead (ZeD_ContextMenu:onJoypadDirUp /
--         onJoypadDirDown were no-ops), while the List look already takes them.
--   K2-4  A on the tab that is already open does nothing (ZeD_CharacterWindow.lua _switchTabForNav returned false for
--         the open tab), where a mouse click on it folds it.
--   K2-5  in the driver's seat, Vehicle > Dashboard puts the pad on the dash's first stop, the trip reset (on Lite's
--         dash, the Dash Elite, its first lit key), not the ignition; and the wheel's Dashboard line said "Back lets
--         go" where the dash itself calls B Drive.
-- The fixes: onJoypadDirUp / Down call prev / next (Up back, Down forward); _switchTabForNav folds the open tab with the
-- strip's own same-tab branch; ZeD_Dashboard:_ring moves dash:ignition to the front of the dash's stops, whatever order
-- the plate drew them in; UI_ZeD_Wheel_DashboardDetail reads "The D-pad on its controls. Drive lets go."
--
-- What each check reads, and what the old code does there. Every PASS line in this script is a fix proven: staging and
-- the put-back print a FAIL line only when they go wrong (a SAY line when they do not), so nothing in it prints PASS on
-- the old code. 8 checks: read from the code, each FAILs on 0ebd56570 and PASSes on da6134ec4.
--   K2-1 (a) Context menu set to the strip (the option's value only), a hammer given and its menu opened by the call A
--            on an open card's row makes (ISInventoryPaneContextMenu.createMenu, ZeD_CharacterWindow.lua:1855; ZeD's
--            menu comes up on the game's menu's next frame). From the strip's selected cell, in one frame: pad Down
--            (ZeD_ContextMenu:onJoypadDirDown, the handler the engine calls on the pad's focus, JoyPadSetup.lua:724)
--            moves to the next cell, the step pad Right makes from where it then is; keyboard Down (the strip's
--            onKeyPress) still does not move it, and the strip still leaves that key to the game (isKeyConsumed
--            false). Old code FAIL: pad Down leaves the selection where it was.
--   K2-1 (b) the same for Up: one cell back, the step pad Left makes; keyboard Up as Down. Old code FAIL: Up is dead.
--   K2-1 (c) Context menu set to the list, the same menu: pad Down and Up move the list's row down and back as they
--            did, to the rows keyboard Down and Up reach (the list takes those keys), and the strip answers them as (a)
--            and (b). Old code FAIL: the strip's half (the list's half reads the same on both codes:
--            ZeD_ContextList.lua is not touched by the fix).
--   K2-4     the Character window on Loot and the tab used (Skills, else Health, Identity, Thermal or Journal: the
--            first with a place on the strip and a stop for the pad): a click on it opens it, a click on the open tab
--            folds it (the strip's own mouse handler, as a click and ZeD_CharacterWindow.openTab press it): the
--            reference. Then on the pad: its focus on the tab's stop, A tapped (FocusManager's A, its QA hook holding
--            the button: RT.pad / RT.padDown) opens it; A tapped again on the open tab: the window back on Loot, the
--            drawer shut, where and as wide as the click's fold left it (1 px). Old code FAIL: the second A does
--            nothing, the tab stays open.
--   K2-5 (a) a pickup spawned (without the prelude: a pickup, else a Nyala), he at its wheel, its key in his inventory
--            (so the ignition is a live stop); Style Full (the value only): the car's own plate, the pickup's d6. The
--            dash's stops as a fresh dash holds them (the stop it keeps for the pad cleared, as after a load: the first
--            time a player takes the dash), D-pad Right (ISDPadWheels.onDisplayRight) opens the World wheel, Vehicle
--            and then Dashboard are taken as A takes a slice (ZeD.WheelGesture.commit), Dashboard hands the pad to the
--            dash a frame later: the pad's first stop is dash:ignition. Old code FAIL: dash:tripReset, the first the
--            plate draws.
--   K2-5 (b) that wheel's Dashboard slice: its line names B by the dash's own word for B on that stop (Drive), and B
--            (the dash's onJoypadDown, the stop's onCancel) lets go of the dash. Old code FAIL: the line reads "The
--            D-pad on its controls. Back lets go."
--   K2-5 (c) (a) with Style Lite (the value only): Lite's dash, the Dash Elite in its black cabin. Old code FAIL: the
--            plate's first lit key (the lights: the odometer key is dark with the key out of the lock).
--   K2-5 (d) (b) on Lite's dash. Old code FAIL: as (b).
-- (Lite's dash is a plate since beta 21: Settings.dashSimple answers false, so the plain strip, ZeD_Dashboard:_plain,
-- never shows. _ring serves it too, but no player reaches it, and nothing here stages it.)
--
-- How it stages, with no controller plugged in: ZeD's input mode locked to the controller (S.lock("gamepad"), as
-- vx12_wheel.lua; every pad path here reads that mode), the pair shut and the pad let go for the D-pad wheels, and each
-- press through the handler the pad's press reaches: the strip's and the list's onJoypadDir* and onJoypadDown (the
-- engine calls them on the pad's focus), their onKeyPress for the keys, FocusManager's A for the tab, D-pad Right's
-- ISDPadWheels.onDisplayRight, ZeD.WheelGesture.commit for A on a slice, the dash's onJoypadDown for B. The car: the
-- prelude's ZEDQA_CAR_WAIT (a pickup on the drag strip's marked stretch, the next spot when one's physics does not wake),
-- ZEDQA_CAR_PREP (repaired, its key in his inventory), ZEDQA_CAR_ENTER (the driver's seat; it refuses a car not ready
-- or far, which drops the game to the main menu). Nothing is fired but the two slices: no menu choice, no dash
-- control, nothing used, eaten, drunk or worn, no timed action. Order: K2-5 (the pair shut), then K2-4 and K2-1 (the
-- pair open). Waits go by the clock; no pixel size is written in (4K at UI scale 1.75 and 1280x800 Auto alike).
-- What it puts back (also when a step throws or the time runs out): the wheel and any menu shut, the Context menu and
-- Style values (values only: nothing applied, nothing saved), the car taken away (ZEDQA_CAR_AWAY: him out first, its
-- key out of his inventory, the car removed ticks later), him where he was found, the hammer, the dash let go and the
-- stop it keeps for the pad as found, the tab's scroll, the halves' timers, a timed action the run queued (none
-- should be), the input lock and the mode ZeD read (vx12_wheel.lua's way), the windows open or shut as found, where
-- and as big as they were, on their tabs, and the game speed. No option is saved, no file is written, ZEDQA_LAYOUT_BACK
-- is never called.
-- Run offline before the first game run (Nov 22 2026: KRun, rt_kit.lua and this script in the game's Kahlua with the
-- real ZeD_ContextMenu.lua and ZeD_ContextList.lua, the real ZeD_Dashboard:_ring and _switchTabForNav and the wheel's
-- UI.json line of 0ebd56570 and of da6134ec4, the rest of the game stubbed; the harness is not in the repo):
-- da6134ec4 PASS 8; 0ebd56570 FAIL 8, each for the finding's own reason; the put-back clean on both. Also run: the pair
-- found shut, the Character window found on Skills, Style found Lite, the Context menu found on the list, no prelude, the
-- dash slow to see the key, a first car whose physics never wakes (the next spot is used), 4K; the clock leaping past
-- the limit every 3 frames through the run (the kit's own FAIL only, the put-back clean each time); no car at all (K2-5
-- FAILs as staging, K2-4 and K2-1 still prove). KCheck OK. Not run in game yet.

if not (RT and RT.make) then
    print("ZEDQA vk2_pad ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk2_pad VERDICT FAIL 1")
    print("ZEDQA vk2_pad DONE")
    return
end

local Q = RT.make("vk2_pad")
Q.maxMs = 200000   -- (some three minutes, then the put-back; a run takes about one)
local Z = ZeD or {}
local S = { p = RT.p, pn = RT.pn, was = { geo = {}, tab = {} }, off = {}, k1 = {}, k4 = { sc = {} }, k5 = {} }
S.Det = Z.Input and Z.Input.Detector
S.F = Z.Input and Z.Input.Focus
S.D, S.W, S.G, S.Dash, S.St = Z.DpadWheels, Z.Wheel, Z.WheelGesture, Z.Dashboard, Z.Settings
S.JD = { player = S.pn }   -- (what the engine hands a pad handler: the pressing pad's player)
S.PART = { k1 = "K2-1", k4 = "K2-4", k5 = "K2-5" }
S.CARS = { "Base.PickUpTruck", "Base.CarNormal" }
S.TABS = { "skills", "health", "identity", "thermal", "journal" }
S.LEGS = {
    { name = "Full", style = 1, a = "(a)", b = "(b)", plate = "Style Full, the car's own plate" },
    { name = "Lite", style = 2, a = "(c)", b = "(d)", design = "dashelite", plate = "Style Lite, Lite's dash: the Dash Elite" },
}

-- ===================================================================== words and numbers
function S.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function S.lines(text)
    local out = {}
    for l in tostring(text or ""):gmatch("[^\n]+") do out[#out + 1] = l end
    return out
end
function S.firstLine(text)
    local l = S.lines(text)[1]
    if not l then return "" end
    local t = l:gsub("^%s+", ""):gsub("%s+$", "")
    return t
end
function S.flat(text)
    local t = tostring(text or ""):gsub("\n", " / ")
    return t
end
-- one cell forward or back on a ring of n (n >= 2; the left side of % is never negative: Kahlua's % keeps its sign)
function S.fwd(i, n) return (i % n) + 1 end
function S.bwd(i, n) return ((i - 2 + n) % n) + 1 end
-- staging that cannot go on: one FAIL line, the part's checks not run (a part not proven is a FAIL, never a SKIP)
function S.fail(key, why)
    if S.off[key] then return end
    S.off[key] = true
    Q.check(false, S.PART[key] .. " staging: " .. tostring(why) .. " (" .. S.PART[key] .. " not proven)")
end
-- the put-back: a SAY line when it is as found, a FAIL line when it is not (never a PASS: it proves no fix)
function S.putBack(ok, what, detail)
    if ok then Q.say("put back: " .. what .. " | " .. tostring(detail))
    else Q.check(false, "put back: " .. what, detail) end
end

-- ===================================================================== the windows (vx12_wheel.lua)
function S.charOpen()
    local CW = ZeD_CharacterWindow
    return (CW ~= nil and CW.isOpen ~= nil and CW.isOpen(S.pn)) and true or false
end
function S.worldOpen()
    local WW = ZeD_WorldWindow
    return (WW ~= nil and WW.isOpen ~= nil and WW.isOpen(S.pn)) and true or false
end
function S.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function S.gs(g)
    if not g then return "none" end
    return S.num(g.x) .. "," .. S.num(g.y) .. " " .. S.num(g.w) .. "x" .. S.num(g.h)
end
function S.sameGeo(a, b)
    if a == nil or b == nil then return a == nil and b == nil end
    return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1
end
function S.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    local out = {}
    for k, v in pairs(t) do out[k] = (depth < 6) and S.copy(v, depth + 1) or v end
    return out
end
-- the pair shut (a pause closes only the Character window, so anything left is shut too)
function S.closePair()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.charOpen() and S.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
-- the pair open (the inventory key's own toggle; then each on its own)
function S.openPair()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if not S.charOpen() and not S.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if not S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if not S.worldOpen() and WW.open then pcall(WW.open, S.pn) end
end
-- the windows open or shut as found (the opens first, the shuts last, so an open that brings its partner is undone)
function S.windowsBack()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.was.char and S.was.world and not S.charOpen() and not S.worldOpen() and CW.toggleBothPaired then
        pcall(CW.toggleBothPaired, S.pn)
    end
    if S.was.char and not S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world and not S.worldOpen() and WW.open then pcall(WW.open, S.pn) end
    if S.was.char == false and S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world == false and S.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
-- the layout the character keeps for each window (md.ZeD_WinState.char / .world, what a window opens on). open true:
-- the windows found open get the layout they saved when the run first shut them; open false: the windows found shut
-- get the layout they had (vx12_wheel.lua S.layoutBack)
function S.layoutBack(open)
    local ws = S.was.ws
    local md = (ws and ws.taken and S.p) and S.p:getModData() or nil
    if not md then return end
    if not open and not ws.had and not (S.was.char or S.was.world) then md.ZeD_WinState = nil; return end
    local src = open and S.was.wsShut or ws.v
    if type(src) ~= "table" then src = {} end
    local cur = md.ZeD_WinState
    if type(cur) ~= "table" then
        cur = {}
        md.ZeD_WinState = cur
    end
    for _, k in ipairs({ { "char", S.was.char == true }, { "world", S.was.world == true } }) do
        if k[2] == open and (src[k[1]] ~= nil or not open) then cur[k[1]] = S.copy(src[k[1]]) end
    end
end
-- the windows at rest: the same places and sizes for 300 ms
function S.settled()
    local cw, ww = S.charOpen() and RT.cw() or nil, S.worldOpen() and RT.ww() or nil
    local sig = S.gs(S.geo(cw)) .. " | " .. S.gs(S.geo(ww))
    local now = getTimestampMs()
    if sig ~= S.restSig then
        S.restSig, S.restAt = sig, now
        return false
    end
    return now - S.restAt >= 300
end
-- a window not where it was found, set back by its own setters (never ZEDQA_LAYOUT_BACK); true when it moved it
function S.placeBack(w, g)
    if not (w and g) or S.sameGeo(S.geo(w), g) then return false end
    if math.abs(w:getWidth() - g.w) > 1 then
        w.minimumWidth = math.min(w.minimumWidth or g.w, g.w)
        w:setWidth(g.w)
    end
    if math.abs(w:getHeight() - g.h) > 1 then
        w.minimumHeight = math.min(w.minimumHeight or g.h, g.h)
        w:setHeight(g.h)
    end
    if w:getX() ~= g.x then w:setX(g.x) end
    if w:getY() ~= g.y then w:setY(g.y) end
    if w._anchorRightEdge ~= nil then w._anchorRightEdge = g.x + w:getWidth() end
    return true
end

-- ===================================================================== the input mode ZeD reads (vx12_wheel.lua)
-- the lock as found: ZeD setup's Input lock, as Settings.lua applies it ("auto" is no lock); the save's modData copy
-- only when the setting cannot be read
function S.lockFound()
    local key = nil
    local api = PZAPI and PZAPI.ModOptions
    local zo = (api and api.getOptions) and api:getOptions("ZeD_UI") or nil
    local o = zo and zo.dict and zo.dict.inputModeLock
    local keys = S.St and S.St.inputLockKeys
    if o and o.getValue and keys then key = keys[o:getValue() or 1] end
    if key == nil and S.p then
        local md = S.p:getModData()
        local g = md and md.ZeD_Gamepad
        key = g and g.inputModeLock
    end
    return key or "auto"
end
function S.mode() return (S.Det and S.Det.getMode) and S.Det.getMode(S.pn) or nil end
-- mode "gamepad"; nil or false puts back the lock found (only a lock this script set)
function S.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    if mode then
        if S.lockWas == nil then S.lockWas = S.lockFound() end
        S.Det.setLockedMode(mode)
        S.locked = true
        return
    end
    if not S.locked then return end
    S.locked = false
    S.Det.setLockedMode(nil)
    if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
end
-- the lock lifted, and with no lock found the mode ZeD read: a moment's lock on it lets the detector's tick take it
-- (its switch waits 200 ms after the last); S.modeFree lifts that
function S.modeBack()
    local held = S.locked
    S.lock(false)
    if not (held and S.lockWas == "auto" and S.was.mode ~= nil and S.Det and S.Det.setLockedMode) then return end
    local want = (S.was.mode == "gamepad") and "gamepad" or "kbm"
    if S.mode() == want then return end
    S.Det.setLockedMode(want)
    S.modeHeld = want
end
function S.modeFree()
    if not S.modeHeld then return end
    S.modeHeld = nil
    S.Det.setLockedMode(nil)
end

-- ===================================================================== the wheels (vx12_wheel.lua, kiss_pad.lua)
function S.wheelSt() return (S.D and S.D.state) and S.D.state[S.pn] or nil end
function S.radial() return getPlayerRadialMenu and getPlayerRadialMenu(S.pn) or nil end
-- (a wheel never built has no element: it is not on screen, and asking would build one)
function S.vis(m)
    if not (m and m.javaObject ~= nil and m.isReallyVisible) then return false end
    return m:isReallyVisible() and true or false
end
function S.closeWheel()
    local D = S.D
    if not D then return end
    if S.wheelSt() and D.close then pcall(D.close, S.pn) end
    local st = S.wheelSt()
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    if D.state then D.state[S.pn] = nil end
    local m = S.radial()
    if m and m.undisplay and S.vis(m) then pcall(m.undisplay, m) end
end
-- a ZeD right-click menu, or the game's, closed
function S.closeMenu()
    local v = getPlayerContextMenu and getPlayerContextMenu(S.pn) or nil
    if not v then return end
    local zm = v._zedMenu
    if zm and zm.close then pcall(zm.close, zm) end
    if not v._zedMenu and v.javaObject ~= nil and v.closeAll and v:isVisible() then pcall(v.closeAll, v) end
end
function S.release()
    if S.F and S.F.releaseFocus then pcall(S.F.releaseFocus, S.pn) end
end
-- nothing but the wheel: no wheel or menu up, the pad let go, the pair shut
function S.toWheel()
    S.closeWheel()
    S.closeMenu()
    S.release()
    S.closePair()
    S.release()
    if setJoypadFocus then pcall(setJoypadFocus, S.pn, nil) end
end
-- the wheel opened the way the D-pad press opens it (ISDPadWheels.onDisplay*, where ZeD puts its own); ZeD's own
-- opener only when that left it shut
function S.openWheel(dir, fn)
    if ISDPadWheels and ISDPadWheels[fn] then pcall(ISDPadWheels[fn], { player = S.pn, id = nil }) end
    local st = S.wheelSt()
    if st and st.dir == dir then return true, "ISDPadWheels." .. fn .. ", the D-pad press's own call" end
    local ok, e = pcall(S.D.open, dir, { player = S.pn, id = nil })
    if not ok then Q.say("ERR open " .. dir .. ": " .. tostring(e)) end
    st = S.wheelSt()
    return st ~= nil and st.dir == dir, "ZeD.DpadWheels.open (the press's own call left it shut)"
end
function S.slices()
    local st = S.wheelSt()
    local m = st and st.menu
    return (m and m.slices) or {}
end
function S.sliceAt(word)
    for i, s in ipairs(S.slices()) do
        if S.firstLine(s.text) == word then return i end
    end
    return nil
end
function S.ringWords()
    local t = {}
    for _, s in ipairs(S.slices()) do
        local off = false
        if S.W and S.W.isOff then pcall(function() off = S.W.isOff(s) and true or false end) end
        t[#t + 1] = S.firstLine(s.text) .. (off and " (off)" or "")
    end
    return (#t > 0) and table.concat(t, ", ") or "no wheel"
end
-- slice i taken as A takes it on the wheel (ZeD_WheelGesture.lua G.commit, the wheel's own accept): a slice with a
-- ring of its own opens it in place (D.enter), any other closes the wheel and runs it (D.take)
function S.commit(i)
    local st = S.wheelSt()
    if not (st and st.menu and i) then return false end
    local ok, e = pcall(S.G.commit, S.pn, st, i, true)
    if not ok then Q.say("ERR the wheel's accept: " .. tostring(e)) end
    return ok
end
-- what holds the pad
function S.holder()
    local fw = (S.F and S.F.getFocusedWindow) and S.F.getFocusedWindow(S.pn) or nil
    if not fw then return "the game (no ZeD window holds it)" end
    return tostring(fw._zedLabel or fw.Type or "a window")
end

-- ===================================================================== settings (the values only), the player
function S.optVal(o) if o and o.getValue then return o:getValue() end; return nil end
function S.optSet(o, v) if o and o.setValue and v ~= nil and o:getValue() ~= v then o:setValue(v) end end
function S.liteNow() return (S.St and S.St.lite and S.St.lite()) and true or false end
function S.styleWord() return S.liteNow() and "Lite" or "Full" end
function S.speed(n) if ZEDQA_SPEED then ZEDQA_SPEED(n) elseif setGameSpeed then setGameSpeed(n) end end
function S.health() local h = nil; pcall(function() h = S.p:getBodyDamage():getOverallBodyHealth() end); return h end
function S.queueN()
    local n = 0
    if ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue then
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        if q and q.queue then n = #q.queue end
    end
    return n
end
-- a timed action the run queued (none should be) cleared, only when none was queued at the start
function S.queueBack()
    if not S.was.taken then return end
    local n = S.queueN()
    if n > 0 and (S.was.queue or 0) == 0 and ISTimedActionQueue and ISTimedActionQueue.clear then
        S.queued = n
        pcall(ISTimedActionQueue.clear, S.p)
    end
end
function S.where() return S.num(S.p:getX()) .. "," .. S.num(S.p:getY()) .. "," .. S.num(S.p:getZ()) end
-- him back where he was found (the car's door and the prelude's home spot are elsewhere), as ZEDQA_HOME moves him
function S.homeBack()
    local at = S.was.pos
    if not at or S.p:getVehicle() then return end
    local dx, dy = S.p:getX() - at.x, S.p:getY() - at.y
    if dx * dx + dy * dy <= 2.25 and math.floor(S.p:getZ()) == math.floor(at.z) then return end
    S.movedFrom = S.where()
    S.p:setX(at.x); S.p:setY(at.y); S.p:setZ(at.z)
    S.p:setLastX(at.x); S.p:setLastY(at.y); S.p:setLastZ(at.z)
end

-- ===================================================================== the car (zedqa_prelude.lua, kiss_pad.lua, beta21_report.lua)
-- the car: the prelude's ZEDQA_CAR_WAIT (a pickup on the drag strip's marked stretch, the next spot when one does not
-- wake in 4 s), else one spawn beside him as beta21_report.lua's. A car that wakes after the run stopped waiting for it
-- is taken away at once (S.k5.gaveUp).
function S.carStart()
    if not ZEDQA_CAR_WAIT then return S.carSpawn() end
    S.k5.waiting = true
    ZEDQA_CAR_WAIT(S.CARS[1], "vk2_pad", function(v)
        S.k5.waiting = false
        if S.k5.gaveUp then
            if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v) end
            return
        end
        S.car = { v = v, script = S.CARS[1], how = "the prelude's ZEDQA_CAR_WAIT (the drag strip's marked stretch)" }
    end, function(why)
        S.k5.waiting = false
        S.carWhy = why
    end, 4000)
    return true
end
-- a bare 3 x 7 footprint round sq0 (beta21_report.lua's place test, widened to the car as kiss_pad.lua's)
function S.carClear(sq0)
    if not sq0 then return false end
    local cell = getCell()
    local cx, cy, z = sq0:getX(), sq0:getY(), sq0:getZ()
    for dy = -3, 3 do
        for dx = -1, 1 do
            local sq = cell:getGridSquare(cx + dx, cy + dy, z)
            if not sq then return false end
            local ok = false
            pcall(function() ok = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil and sq:getRoom() == nil end)
            if not ok then return false end
        end
    end
    return true
end
function S.carSpawn()
    if ZEDQA_CAR_SPAWN then
        for _, script in ipairs(S.CARS) do
            local v, why = ZEDQA_CAR_SPAWN(script, "vk2_pad")
            if v then
                S.car = { v = v, script = script, how = "the prelude's ZEDQA_CAR_SPAWN (the drag strip's marked stretch)" }
                return true
            end
            S.carWhy = why
        end
        return false
    end
    local cell = getCell()
    for _, o in ipairs({ { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 } }) do
        local sq = cell:getGridSquare(math.floor(S.p:getX()) + o[1], math.floor(S.p:getY()) + o[2], math.floor(S.p:getZ()))
        if S.carClear(sq) then
            for _, script in ipairs(S.CARS) do
                local v = nil
                pcall(function() v = addVehicleDebug(script, IsoDirections.N, nil, sq) end)
                if v then
                    S.car = { v = v, script = script, how = "addVehicleDebug beside him (beta21_report.lua:459-464; no prelude)" }
                    return true
                end
            end
        end
    end
    S.carWhy = "no bare 3 x 7 footprint at beta21_report.lua's five places round him"
    return false
end
-- (zedqa_prelude.lua ZEDQA_CAR_READY: a square, a chunk, its physics seen awake once, near him)
function S.carReady()
    local c = S.car
    if not (c and c.v) then return false end
    if ZEDQA_CAR_READY then
        local ok, r = pcall(ZEDQA_CAR_READY, c.v)
        return ok and r == true
    end
    local r = false
    pcall(function() r = c.v:getSquare() ~= nil and c.v:isPhysicsActive() end)
    if r then c.seen = true end
    return c.seen == true
end
-- repaired, its key in his inventory (the ignition is a live stop on the dash with the key on him)
function S.carPrep()
    local c = S.car
    local key = nil
    if ZEDQA_CAR_PREP then
        local ok, k = pcall(ZEDQA_CAR_PREP, c.v)
        if ok then key = k end
    else
        pcall(function() c.v:repair() end)
        pcall(function() key = S.p:getInventory():AddItem(c.v:createVehicleKey()) end)
    end
    if key then pcall(function() key:getModData().ZeDQA_spawned = true end) end
    c.key = key
end
-- the driver's seat (ZEDQA_CAR_ENTER refuses a car that is not ready or is far: seating one drops to the main menu)
function S.carIn()
    local c = S.car
    if ZEDQA_CAR_ENTER then
        local okc, ok, why = pcall(ZEDQA_CAR_ENTER, c.v, 0)
        if not okc then return false, tostring(ok) end
        return ok == true, why
    end
    if not S.carReady() then return false, "the car is not ready" end
    pcall(function() c.v:enter(0, S.p); triggerEvent("OnEnterVehicle", S.p) end)
    return S.p:getVehicle() == c.v, "entered directly"
end
function S.carLive(v)
    if not v then return false end
    local live = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do if it:next() == v then live = true end end
    end)
    return live
end
-- him out, the key out, the car away ticks later (removing it in the tick of the exit is a NullPointerException and
-- the main menu: ZEDQA_CAR_AWAY's sweep removes it two ticks on; without the prelude, S.carGone half a second on, once)
function S.carAway()
    local c = S.car
    if not c or c.going then return end
    c.going = true
    c.awayAt = getTimestampMs()
    if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, c.v, c.key); return end
    c.manual = true
    if S.p:getVehicle() == c.v then pcall(function() c.v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end) end
    local k = c.key
    if k then pcall(function() local con = k:getContainer(); if con then con:Remove(k) end end) end
end
function S.carGone()
    local c = S.car
    if not c then return true end
    if c.manual and not c.removed and S.p:getVehicle() ~= c.v and getTimestampMs() - (c.awayAt or 0) > 500 and S.carLive(c.v) then
        c.removed = true
        pcall(function() c.v:permanentlyRemove() end)
    end
    return not S.carLive(c.v)
end

-- ===================================================================== the dash
function S.dash() return (S.Dash and S.Dash.getInstance) and S.Dash.getInstance(S.pn) or nil end
function S.dashZone(d) return (d and d._focusRing) and d._focusRing[1] or nil end
function S.dashCount(d) local z = S.dashZone(d); return (z and z.elements) and #z.elements or 0 end
function S.dashHas(d, id)
    local z = S.dashZone(d)
    for _, e in ipairs((z and z.elements) or {}) do if e.id == id then return true end end
    return false
end
-- the dash's stops in the order the pad holds them (the first n, "dash:" left off)
function S.dashIds(d, n)
    local z = S.dashZone(d)
    local out = {}
    for i, e in ipairs((z and z.elements) or {}) do
        if i > n then break end
        local s = tostring(e.id):gsub("^dash:", "")
        out[#out + 1] = s
    end
    return (#out > 0) and table.concat(out, ", ") or "none"
end
-- the order the plate draws its controls in (ZeD/DashPx.lua: the design's click areas, the old code's stop order)
function S.plateOrder(id, n)
    local DP = Z.DashPx
    local des = (DP and DP.designs and id) and DP.designs[id] or nil
    local out = {}
    for i, hz in ipairs((des and des.hits) or {}) do
        if i > n then break end
        out[#out + 1] = tostring(hz.id)
    end
    return out
end
-- the dash as a fresh one holds its stops (ZeD_Dashboard:new: no stops, the first kept): the stop it keeps for the pad
-- from an earlier drive cleared, so the pad's landing is the first time a player takes the dash after a load
function S.dashFresh(d)
    local z = S.dashZone(d)
    if not z then return false end
    z.elements = {}
    z.focusedElementIdx = 1
    return true
end
-- B's word on a stop, as the dash's hint draws it
function S.padWord(el)
    if not el then return nil end
    if type(el.promptBWord) == "string" then return el.promptBWord end
    if type(el.promptB) == "string" then return el.promptB end
    return nil
end
-- (put-back) the dash let go, unregistered as found, and, hidden again, the stop it keeps for the pad as found
function S.dashBack()
    local d = S.dash()
    if not (d and S.F) then return end
    if S.F.getFocusedWindow(S.pn) == d then pcall(d._release, d) end
    if not S.was.dashReg and S.F.isRegistered and S.F.isRegistered(d) then pcall(d._unregister, d) end
    local z = S.dashZone(d)
    if z and S.was.dashTaken and not d:isVisible() then
        z.elements = S.was.dashEls
        z.focusedElementIdx = S.was.dashIdx
    end
end

-- ===================================================================== the right-click menus
-- ZeD's open menu of the player (the game's menu carries it once its first frame made it), of that Type when asked
function S.zedMenu(ty)
    local v = getPlayerContextMenu and getPlayerContextMenu(S.pn) or nil
    local zm = v and v._zedMenu or nil
    if not (zm and zm._ctx and zm._ctx.open) then return nil end
    if ty and zm.Type ~= ty then return nil end
    return zm
end
-- the hammer's menu, by the call A on an open card's row makes (the row's own menu, ZeD_CharacterWindow.lua:1855)
function S.openMenu()
    local it = S.k1.item
    if not (it and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu) then return false end
    local ok, e = pcall(ISInventoryPaneContextMenu.createMenu, S.pn, true, { it }, 0, 0)
    if not ok then Q.say("ERR the hammer's menu: " .. tostring(e)) end
    return ok
end
function S.cellName(zm, i)
    local items = zm and zm._ctx and zm._ctx.items
    local d = (items and i) and items[i] or nil
    return d and tostring(d.name) or "?"
end
function S.rowName(lm, i)
    local L = lm and lm._levels
    local lv = L and L[#L] or nil
    local r = (lv and lv.rows and i) and lv.rows[i] or nil
    return (r and r.def) and tostring(r.def.name) or "?"
end
-- the strip, in one frame (no update between the presses: a resting pointer cannot take the selection): pad Down,
-- pad Up, pad Right, pad Left, then keyboard Down and Up; the selected cell after each
function S.stripRun(zm)
    local function sel() return zm._ctx.selected end
    local r = { n = #(zm._ctx.items or {}) }
    r.s0 = sel()
    zm:onJoypadDirDown(S.JD); r.s1 = sel()
    zm:onJoypadDirUp(S.JD); r.s2 = sel()
    zm:onJoypadDirRight(S.JD); r.s3 = sel()
    zm:onJoypadDirLeft(S.JD); r.s4 = sel()
    r.kd, r.ku = zm:isKeyConsumed(Keyboard.KEY_DOWN), zm:isKeyConsumed(Keyboard.KEY_UP)
    zm:onKeyPress(Keyboard.KEY_DOWN); r.s5 = sel()
    zm:onKeyPress(Keyboard.KEY_UP); r.s6 = sel()
    r.names = {}
    for _, k in ipairs({ "s0", "s1", "s2", "s3", "s4", "s5", "s6" }) do r.names[k] = S.cellName(zm, r[k]) end
    return r
end
-- the list, in one frame: pad Down, pad Up, then keyboard Down and Up; the row selected after each, on its top level
function S.listRun(lm)
    local function lv() local L = lm._levels or {}; return L[#L] end
    local function sel() local l = lv(); return l and l.sel or nil end
    -- (a submenu the real pointer opened by resting on a row, ZeD_ContextList:update, is shut first, as pad Left
    -- shuts it: Up and Down are read on the top level, whose row is selected at open)
    local L0 = lm._levels or {}
    for k = #L0, 2, -1 do L0[k] = nil end
    local r = {}
    r.y0 = sel()
    lm:onJoypadDirDown(S.JD); r.y1 = sel()
    lm:onJoypadDirUp(S.JD); r.y2 = sel()
    r.kd, r.ku = lm:isKeyConsumed(Keyboard.KEY_DOWN), lm:isKeyConsumed(Keyboard.KEY_UP)
    lm:onKeyPress(Keyboard.KEY_DOWN); r.y3 = sel()
    lm:onKeyPress(Keyboard.KEY_UP); r.y4 = sel()
    r.live = 0
    local l = lv()
    for _, row in ipairs((l and l.rows) or {}) do if row.def and not row.def.heading then r.live = r.live + 1 end end
    r.names = {}
    for _, k in ipairs({ "y0", "y1", "y2", "y3", "y4" }) do r.names[k] = S.rowName(lm, r[k]) end
    return r
end

-- ===================================================================== the Character window's tabs (K2-4)
function S.tabZone(w, id)
    local strip = w and w._tabStripPanel
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == "tab:" .. id then return strip, z end
    end
    return nil, nil
end
-- a click on a tab: the strip's own mouse handler at the tab's place (as RT.goTab and ZeD_CharacterWindow.openTab)
function S.clickTab(w, id)
    local strip, z = S.tabZone(w, id)
    if not (strip and z) then return false end
    local ok, e = pcall(strip.onMouseDown, strip, z.x + 2, z.y + 2)
    if not ok then Q.say("ERR the click on the " .. tostring(id) .. " tab: " .. tostring(e)) end
    return ok
end
-- the tab's stop for the pad (the strip's zone charTabBar: one stop a shown tab, its onActivate A on it)
function S.tabStop(w, id)
    for _, z in ipairs((w and w._focusRing) or {}) do
        if z.zone == "charTabBar" then
            for _, e in ipairs(z.elements or {}) do if e.tabId == id then return e end end
        end
    end
    return nil
end
function S.pickTab(w)
    for _, id in ipairs(S.TABS) do
        local _, z = S.tabZone(w, id)
        if z and S.tabStop(w, id) then return id end
    end
    return nil
end
-- a tab's own scroll, which a press on the tab sets to the top (vx10_tab.lua X.tabScroll)
function S.tabScroll(w, id)
    if not w then return nil end
    if id == "skills" then return w._skillsScroll end
    if id == "health" then return w._healthScroll end
    if id == "thermal" then return w._thermalScroll end
    if id == "identity" then return w._identityScroll end
    if id == "journal" and (w._journalSubTab or 1) == 1 then return w._journalScroll end
    return nil
end
function S.keepScroll(w, id)
    if id == nil or id == "loot" or S.k4.sc[id] then return end
    local sc = S.tabScroll(w, id)
    S.k4.sc[id] = { pos = (type(sc) == "table") and sc.scrollPos or nil }
end
function S.scrollBack()
    local w = RT.cw()
    for id, t in pairs(S.k4.sc) do
        local sc = (t.pos ~= nil) and S.tabScroll(w, id) or nil
        if type(sc) == "table" and sc.setScrollPos then pcall(sc.setScrollPos, sc, t.pos) end
    end
end
-- the halves' roll timers held (win._outSince in the future, WindowHalves.lua H.update: "QA's staging"), so where the
-- real pointer rests rolls nothing and folds no drawer; nothing is held before the found values are kept
function S.hold()
    local o = S.k4.out
    if not o then return end
    local t = getTimestampMs() + 600000
    if o.cw then o.cw._outSince = t end
    if o.ww then o.ww._outSince = t end
end
function S.k4Back()
    S.scrollBack()
    local o = S.k4.out
    if not o then return end
    S.k4.out = nil
    if o.cw then o.cw._outSince = o.c end
    if o.ww then o.ww._outSince = o.w end
end
-- what the window shows: its tab, its drawer, its place and size
function S.wstate(w)
    if not w then return { tab = "no window", open = false, eff = 0 } end
    return { tab = tostring(w._activeTab), open = w._drawerOpen == true, mode = w._drawerMode, eff = w._drawerEffW or 0, geo = S.geo(w) }
end
function S.ws(s)
    if not s then return "not read" end
    return "on " .. tostring(s.tab) .. ", its drawer " .. (s.open and "open" or "shut") .. " (mode " .. tostring(s.mode) .. ", "
        .. S.num(s.eff) .. " px wide), the window at " .. S.gs(s.geo)
end
-- the window at rest: its tab, drawer and place unchanged for 300 ms (S.k4.sig cleared before each wait)
function S.restNow(w)
    if not w then return false end
    local sig = S.gs(S.geo(w)) .. " " .. S.num(w._drawerEffW or 0) .. " " .. tostring(w._activeTab) .. " " .. tostring(w._drawerOpen)
    local now = getTimestampMs()
    if sig ~= S.k4.sig then
        S.k4.sig, S.k4.at = sig, now
        return false
    end
    return now - S.k4.at >= 300
end
function S.isOpenOn(w, id) return w ~= nil and w._activeTab == id and w._drawerOpen == true and w._drawerMode == "tab" end
function S.isFolded(w) return w ~= nil and w._activeTab == "loot" and w._drawerOpen ~= true and (w._drawerEffW or 0) <= 0.5 end

-- ===================================================================== waits and the pad's A
-- until cond() holds (asked every drawn frame; it never throws), for at most ms of real time; then fn(ok)
function S.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if cond() then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- A tapped on the Character window: FocusManager's dispatch takes the press, its QA hook holds the button for four
-- frames (its tick fires the focused stop's onActivate as A comes up), then hands the button back (rt_cards.lua H.queueA)
function S.tapA(key)
    Q.step(1, function()
        if S.off[key] then return end
        local w = RT.cw()
        if not w then return end
        RT.pad("A", true)
        RT.padDown(Joypad.AButton, w)
        S.aDown = true
    end)
    Q.step(4, function() if S.aDown then RT.pad("A", false) end end)
    Q.step(4, function() if S.aDown then RT.pad("A", nil); S.aDown = nil end end)
end

-- ===================================================================== K2-5: one Style's leg
function S.legFail(L, why)
    if L.off then return end
    L.off = true
    Q.check(false, "K2-5 " .. L.name .. " staging: " .. tostring(why) .. " (not proven on " .. L.plate .. ")")
end
function S.queueLeg(L)
    local wantLite = (L.style == 2)
    -- this leg's Style (the value only), the pair shut, the pad let go
    Q.step(5, function()
        if S.off.k5 then L.off = true; return end
        S.toWheel()
        S.optSet(S.St.lookStyleOption, L.style)
    end)
    -- the dash on this Style's plate (its design worked out for it), the ignition one of its stops
    S.waitUntil(4000, function()
        if L.off then return true end
        local d = S.dash()
        if not (d and d:isVisible() and d._designId and d._badgeKey) then return false end
        if S.liteNow() ~= wantLite or d._badgeKey.lite ~= wantLite then return false end
        if L.design and d._designId ~= L.design then return false end
        return S.dashHas(d, "dash:ignition")
    end, function(ok)
        if L.off then return end
        local d = S.dash()
        if not ok then
            S.legFail(L, "the dash did not show this Style's plate with the ignition among its stops (design "
                .. tostring(d and d._designId) .. ", Style " .. S.styleWord() .. ", stops " .. S.dashIds(d, 8) .. ")")
            return
        end
        L.designId = d._designId
        L.order = S.plateOrder(L.designId, 6)
        if L.order[1] == "ignition" then
            S.legFail(L, "this plate (" .. L.designId .. ") draws the ignition first: the old code lands there too, so nothing is proven on it")
            return
        end
        L.found = S.dashIds(d, 8)
        S.dashFresh(d)
    end)
    -- drawn once more from fresh; then D-pad Right
    S.waitUntil(2000, function()
        if L.off then return true end
        return S.dashCount(S.dash()) > 0
    end, function(ok)
        if L.off then return end
        if not ok then S.legFail(L, "the dash did not draw its stops again"); return end
        S.toWheel()
        local okW, how = S.openWheel("right", "onDisplayRight")
        L.how = how
        if not okW then S.legFail(L, "D-pad Right did not open the World wheel (" .. tostring(how) .. ")") end
    end)
    -- A on Vehicle: the game's vehicle wheel, filled, with ZeD's Dashboard slice after its own (ZeD_DpadWheels.lua
    -- D.B.world's Vehicle: ISVehicleMenu.showRadialMenu, then H.dashSlice)
    S.waitUntil(2000, function()
        if L.off then return true end
        local st = S.wheelSt()
        return st ~= nil and S.vis(st.menu) and S.sliceAt(S.word.vehicle) ~= nil
    end, function(ok)
        if L.off then return end
        if not ok then S.legFail(L, "the World wheel is not up with its Vehicle slice: " .. S.ringWords()); return end
        S.commit(S.sliceAt(S.word.vehicle))
    end)
    -- A on Dashboard: the wheel closes and its run hands the pad to the dash a frame later (D.takePad)
    S.waitUntil(2000, function()
        if L.off then return true end
        local st = S.wheelSt()
        return st ~= nil and st.path ~= nil and #st.path >= 2 and S.vis(st.menu) and S.sliceAt(S.word.dash) ~= nil
    end, function(ok)
        if L.off then return end
        if not ok then S.legFail(L, "Vehicle did not open a wheel with a Dashboard slice: " .. S.ringWords()); return end
        local j = S.sliceAt(S.word.dash)
        local sl = S.slices()[j]
        L.text = S.flat(sl and sl.text)
        L.line = S.lines(sl and sl.text)[2] or ""
        L.ring = S.ringWords()
        S.commit(j)
    end)
    -- the pad on the dash: its first stop; then B
    S.waitUntil(3000, function()
        if L.off then return true end
        local d = S.dash()
        return d ~= nil and S.F.getFocusedWindow(S.pn) == d
    end, function(ok)
        if L.off then return end
        local d = S.dash()
        if not ok then S.legFail(L, "Dashboard did not hand the pad to the dash (the pad is on " .. S.holder() .. "; the vehicle wheel: " .. tostring(L.ring) .. ")"); return end
        local el = S.F.getFocusedElement(d)
        L.first = el and el.id or nil
        L.bWord = S.padWord(el)
        Q.check(L.first == "dash:ignition",
            "K2-5 " .. L.a .. ": seated at the wheel on a pad, Vehicle > Dashboard puts the pad on the ignition, the dash's first stop (" .. L.plate .. ")",
            "the pad landed on " .. tostring(L.first) .. "; the dash's stops in the order the pad holds them: " .. S.dashIds(d, 8)
            .. "; before the fresh start: " .. tostring(L.found) .. "; the plate (design " .. tostring(L.designId) .. ") draws "
            .. table.concat(L.order, ", ") .. " first (the old code's order: its first live stop was its landing); Style "
            .. S.styleWord() .. "; the World wheel by " .. tostring(L.how))
        L.pressedB = true
        local okB, e = pcall(d.onJoypadDown, d, Joypad.BButton, S.JD)
        if not okB then Q.say("ERR B on the dash: " .. tostring(e)) end
    end)
    S.waitUntil(2000, function()
        if L.off or not L.pressedB then return true end
        return S.F.getFocusedWindow(S.pn) ~= S.dash()
    end, function(ok)
        if L.off or not L.pressedB then return end
        local has = L.bWord ~= nil and L.bWord ~= "" and string.find(L.line or "", L.bWord, 1, true) ~= nil
        Q.check(has and ok,
            "K2-5 " .. L.b .. ": the wheel's Dashboard line names B by the dash's own word for it, and B lets go of the dash (" .. L.plate .. ")",
            "the Dashboard slice reads \"" .. tostring(L.text) .. "\"; B on the dash's first stop reads " .. tostring(L.bWord)
            .. "; after B the pad is on " .. S.holder() .. " (old code: the line says Back lets go)")
    end)
end

-- ===================================================================== start
Q.step(5, function()
    local W, D, G, F, Det, St = S.W, S.D, S.G, S.F, S.Det, S.St
    local ready = S.p ~= nil and D ~= nil and D.open ~= nil and D.close ~= nil and D.state ~= nil and W ~= nil
        and G ~= nil and G.commit ~= nil and S.Dash ~= nil and S.Dash.getInstance ~= nil and S.Dash.canTakePad ~= nil
        and F ~= nil and F.claimFocus ~= nil and F.focusWhere ~= nil and F.getFocusedWindow ~= nil and F.getFocusedElement ~= nil
        and F.qaButton ~= nil and F.dispatchJoypadDown ~= nil and F.releaseFocus ~= nil and F.isRegistered ~= nil
        and Det ~= nil and Det.setLockedMode ~= nil and Det.getMode ~= nil
        and St ~= nil and St.contextStyleOption ~= nil and St.lookStyleOption ~= nil and St.lite ~= nil
        and ZeD_ContextMenu ~= nil and ZeD_ContextList ~= nil and ISInventoryPaneContextMenu ~= nil and getPlayerContextMenu ~= nil
        and ISDPadWheels ~= nil and ISDPadWheels.onDisplayRight ~= nil and getPlayerRadialMenu ~= nil
        and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil and Z.T ~= nil and Z.T.px ~= nil and Joypad ~= nil and Keyboard ~= nil
    if not ready then
        Q.check(false, "staging: ZeD's wheels, dash, pad focus, input lock, right-click menus and windows are loaded (nothing proven)")
        S.dead = true
        return
    end
    if D.gameWheels and D.gameWheels() then
        Q.check(false, "staging: ZeD draws the D-pad wheels here (nothing proven)", "the game's own wheels are up (safe mode, the Tutorial, or ZeD not drawn yet)")
        S.dead = true
        return
    end
    if S.p:isDead() then
        Q.check(false, "staging: the character is alive (nothing is run on a dead one)")
        S.dead = true
        return
    end
    S.word = { vehicle = ZeD.tr("UI_ZeD_Wheel_Vehicle"), dash = getText("IGUI_VehiclePartCatdashboard") }
    -- as found (the windows' open or shut last: the put-back reads the windows only once it is set)
    local char, world = S.charOpen(), S.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = char and S.geo(cw) or nil, w = world and S.geo(ww) or nil }
    S.was.tab = { c = (char and cw) and cw._activeTab or nil, w = (world and ww) and ww._activeTab or nil }
    local md = S.p:getModData()
    S.was.ws = { taken = md ~= nil, had = md ~= nil and md.ZeD_WinState ~= nil, v = md and S.copy(md.ZeD_WinState) or nil }
    S.was.mode = S.mode()
    S.lockWas = S.lockFound()
    S.was.ctx = S.optVal(St.contextStyleOption)
    S.was.style = S.optVal(St.lookStyleOption)
    S.was.speed = getGameSpeed and getGameSpeed() or 1
    S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.was.health = S.health()
    S.was.queue = S.queueN()
    local d = S.dash()
    local z = S.dashZone(d)
    if z then S.was.dashTaken, S.was.dashEls, S.was.dashIdx = true, z.elements, z.focusedElementIdx end
    S.was.dashReg = (d ~= nil and F.isRegistered(d)) and true or false
    S.was.taken = true
    S.was.char, S.was.world = char, world
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(Z.T.scale)
        .. " (1u = " .. S.num(Z.T.px(1)) .. " px); Character window open " .. tostring(char) .. " (" .. S.gs(S.was.geo.c) .. ", on "
        .. tostring(S.was.tab.c) .. "), World window open " .. tostring(world) .. " (" .. S.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w)
        .. "); Input lock " .. tostring(S.lockWas) .. ", ZeD reads " .. tostring(S.was.mode) .. "; Context menu " .. tostring(S.was.ctx)
        .. " (1 strip, 2 list), Style " .. tostring(S.was.style) .. " (1 Full, 2 Lite); game speed " .. tostring(S.was.speed)
        .. "; he at " .. S.where() .. ", in a car " .. tostring(S.p:getVehicle() ~= nil) .. "; the dash keeps "
        .. S.dashIds(d, 1) .. " for the pad; the prelude's car helpers " .. tostring(ZEDQA_CAR_SPAWN ~= nil))
    if S.was.speed ~= 1 then S.speed(1) end   -- (paused, the wheels and the game's vehicle wheel stay shut)
    S.lock("gamepad")
    S.toWheel()
    -- the layout each window found open saved as the pair shut just now: the put-back opens a shut one on this
    S.was.wsShut = md and S.copy(md.ZeD_WinState) or nil
end)
Q.waitMs(1000)

-- ===================================================================== K2-5: at the wheel, the dash's first stop
Q.step(10, function()
    if S.dead then S.off.k5 = true; return end
    -- (again: the switch to the controller opens the pair a frame after the lock)
    S.toWheel()
    if S.p:getVehicle() then S.fail("k5", "he sat in a car when the run began"); return end
    if not S.carStart() then S.fail("k5", "no car could be spawned: " .. tostring(S.carWhy)) end
end)
-- (the prelude's wait tries the strip's spots in turn, 4 s each; without it, one spawn and 10 s for its physics)
S.waitUntil(ZEDQA_CAR_WAIT and 45000 or 10000, function()
    if S.off.k5 then return true end
    if S.car then return S.carReady() end
    return not S.k5.waiting
end, function(ok)
    if S.off.k5 then return end
    if not (ok and S.car) then
        S.k5.gaveUp = true
        S.fail("k5", "no car was ready to sit in (" .. (S.car and "its physics never woke" or tostring(S.carWhy or "the prelude's wait gave none")) .. ")")
        S.carAway()
        return
    end
    pcall(function() S.car.scriptName = tostring(S.car.v:getScriptName()) end)
    S.carPrep()
    local okIn, why = S.carIn()
    if not okIn then S.fail("k5", "he could not be seated at the wheel: " .. tostring(why)); S.carAway() end
end)
S.waitUntil(4000, function()
    if S.off.k5 then return true end
    local d = S.dash()
    return S.p:getVehicle() == S.car.v and d ~= nil and d:isVisible() and d._driver == true and S.dashCount(d) > 0
        and S.Dash.canTakePad(S.p)
end, function(ok)
    if S.off.k5 then return end
    local d = S.dash()
    if not ok then
        S.fail("k5", "the dash did not come up for him at the wheel (in the car " .. tostring(S.p:getVehicle() == S.car.v)
            .. ", the dash shown " .. tostring(d ~= nil and d:isVisible()) .. ")")
        return
    end
    local seat = -1
    pcall(function() seat = S.car.v:getSeat(S.p) end)
    Q.say("K2-5: " .. tostring(S.car.scriptName) .. " by " .. tostring(S.car.how) .. ", he in seat " .. tostring(seat)
        .. " (the driver's), its key in his inventory " .. tostring(S.car.key ~= nil) .. "; the dash up on design "
        .. tostring(d._designId) .. ", Style " .. S.styleWord() .. "; its stops " .. S.dashIds(d, 8))
end)
Q.waitMs(500)   -- (the dash reads the key on him every 200 ms: its ignition lights with it)
for _, L in ipairs(S.LEGS) do S.queueLeg(L) end
Q.step(3, function()
    S.closeWheel()
    S.release()
    if S.was.taken then S.optSet(S.St.lookStyleOption, S.was.style) end
    S.carAway()
end)
S.waitUntil(5000, function() return S.carGone() end, function(ok)
    if S.car and not ok then Q.check(false, "put back: the K2-5 car is taken away", "still in the cell; he in a car " .. tostring(S.p:getVehicle() ~= nil)) end
    S.homeBack()
    S.dashBack()
end)

-- ===================================================================== K2-4: A on the open tab
Q.step(5, function()
    if S.dead then S.off.k4 = true; return end
    S.release()
    S.openPair()
    S.restSig = nil
end)
S.waitUntil(5000, function()
    if S.off.k4 then return true end
    return S.charOpen() and S.worldOpen() and RT.cw() ~= nil and RT.ww() ~= nil and S.settled()
end, function(ok)
    if S.off.k4 then return end
    if not ok then S.fail("k4", "the window pair did not open (Character " .. tostring(S.charOpen()) .. ", World " .. tostring(S.worldOpen()) .. ")"); return end
    local cw, ww = RT.cw(), RT.ww()
    if cw.windowShaded then S.fail("k4", "the Character window is rolled up to its title bar"); return end
    if #(cw._mcSelected or {}) > 0 then S.fail("k4", "the Character window has Loot columns open (a tab press closes them, and they could not be put back)"); return end
    S.k4.out = { cw = cw, ww = ww, c = cw._outSince, w = ww._outSince }
    S.hold()
    S.k4.sig = nil
    -- (on Loot with nothing over the list: a press on Loot, as the player's, also puts an item card away)
    if cw._activeTab ~= "loot" or cw._drawerOpen == true then S.clickTab(cw, "loot") end
end)
S.waitUntil(3000, function()
    if S.off.k4 then return true end
    local cw = RT.cw()
    return S.isFolded(cw) and S.restNow(cw)
end, function(ok)
    if S.off.k4 then return end
    local cw = RT.cw()
    if not ok then S.fail("k4", "the Character window did not come to rest on Loot: " .. S.ws(S.wstate(cw))); return end
    local t = S.pickTab(cw)
    if not t then S.fail("k4", "none of the tabs " .. table.concat(S.TABS, ", ") .. " has both a place on the strip and a stop for the pad"); return end
    S.k4.tab = t
    S.k4.loot = S.wstate(cw)
    S.keepScroll(cw, t)
    S.hold()
    S.k4.sig = nil
    -- the reference, as the mouse does it: a click on the tab opens it
    if not S.clickTab(cw, t) then S.fail("k4", "the click on the " .. t .. " tab could not be made") end
end)
S.waitUntil(3000, function()
    if S.off.k4 then return true end
    local cw = RT.cw()
    return S.isOpenOn(cw, S.k4.tab) and S.restNow(cw)
end, function(ok)
    if S.off.k4 then return end
    local cw = RT.cw()
    if not ok then S.fail("k4", "a click on the " .. S.k4.tab .. " tab did not open it: " .. S.ws(S.wstate(cw))); return end
    S.hold()
    S.k4.sig = nil
    -- a click on the open tab folds it (the strip's same-tab branch)
    S.clickTab(cw, S.k4.tab)
end)
S.waitUntil(3000, function()
    if S.off.k4 then return true end
    local cw = RT.cw()
    return S.isFolded(cw) and S.restNow(cw)
end, function(ok)
    if S.off.k4 then return end
    local cw = RT.cw()
    S.k4.ref = S.wstate(cw)
    if not ok then S.fail("k4", "a click on the open " .. S.k4.tab .. " tab did not fold it: " .. S.ws(S.k4.ref)); return end
    -- the pad on the Character window (as Y, LB or the pair's opening give it), its focus on the tab's stop (as LB or
    -- the D-pad on the strip leave it)
    S.F.claimFocus(cw)
    local e = S.F.focusWhere(cw, "charTabBar", function(el) return el.tabId == S.k4.tab end)
    if not e then S.fail("k4", "the pad's focus did not land on the " .. S.k4.tab .. " tab's stop (the pad is on " .. S.holder() .. ")"); return end
    S.hold()
    S.k4.sig = nil
    Q.say("K2-4: the " .. S.k4.tab .. " tab; a click opened it and a click on the open tab folded it, the window " .. S.ws(S.k4.ref)
        .. " (on Loot before: " .. S.ws(S.k4.loot) .. "); the pad on the tab's stop (" .. tostring(e.id) .. ")")
end)
S.tapA("k4")
S.waitUntil(3000, function()
    if S.off.k4 then return true end
    local cw = RT.cw()
    return S.isOpenOn(cw, S.k4.tab) and S.restNow(cw)
end, function(ok)
    if S.off.k4 then return end
    local cw = RT.cw()
    S.k4.openSt = S.wstate(cw)
    if not ok then S.fail("k4", "pad A on the " .. S.k4.tab .. " tab did not open it: " .. S.ws(S.k4.openSt)); return end
    -- (the focus stays on the tab's stop: A on it again is the finding's press)
    local el = S.F.getFocusedElement(cw)
    if not (el and el.tabId == S.k4.tab) then
        S.k4.refocus = tostring(el and el.id)
        local e = S.F.focusWhere(cw, "charTabBar", function(x) return x.tabId == S.k4.tab end)
        if not e then S.fail("k4", "the pad's focus left the " .. S.k4.tab .. " tab's stop and could not be put back on it"); return end
    end
    S.hold()
    S.k4.sig = nil
end)
S.tapA("k4")
S.waitUntil(3000, function()
    if S.off.k4 then return true end
    local cw = RT.cw()
    return S.isFolded(cw) and S.restNow(cw)
end, function(ok)
    if S.off.k4 then return end
    local cw = RT.cw()
    local now, ref = S.wstate(cw), S.k4.ref
    local same = ref ~= nil and now.tab == ref.tab and now.open == ref.open and now.mode == ref.mode and S.sameGeo(now.geo, ref.geo)
    Q.check(ok and same,
        "K2-4: on a pad, A on the open " .. S.k4.tab .. " tab folds it, as a click on it does (the drawer shut, the window back on Loot)",
        "after A on the open tab the window is " .. S.ws(now) .. "; a click on the open tab left it " .. S.ws(ref)
        .. "; the first A opened it: " .. S.ws(S.k4.openSt)
        .. (S.k4.refocus and ("; NOTE the pad's focus had moved to " .. S.k4.refocus .. " after the first A: put back on the tab") or "")
        .. " (old code: A on the open tab does nothing, the tab stays open)")
    -- (left open by the old code: folded by a click, the put-back)
    if S.isOpenOn(cw, S.k4.tab) then S.k4.sig = nil; S.clickTab(cw, S.k4.tab) end
    S.k4.sig = nil
end)
S.waitUntil(3000, function()
    if S.off.k4 then return true end
    local cw = RT.cw()
    return S.isFolded(cw) and S.restNow(cw)
end, function(ok)
    if S.off.k4 or ok then return end
    Q.check(false, "put back: the Character window folded back to Loot after K2-4", S.ws(S.wstate(RT.cw())))
end)

-- ===================================================================== K2-1: Up and Down on the right-click menu
Q.step(5, function()
    if S.dead then S.off.k1 = true; return end
    S.k1.item = RT.give("Base.Hammer")
    if not S.k1.item then S.fail("k1", "a hammer could not be put in his inventory"); return end
    S.closeMenu()
    S.optSet(S.St.contextStyleOption, 1)
    if not S.openMenu() then S.fail("k1", "the hammer's menu could not be made") end
end)
S.waitUntil(3000, function()
    if S.off.k1 then return true end
    return S.zedMenu("ZeD_ContextMenu") ~= nil
end, function(ok)
    if S.off.k1 then return end
    local zm = S.zedMenu("ZeD_ContextMenu")
    if not (ok and zm) then
        local zm0 = S.zedMenu(nil)
        S.fail("k1", "the right-click strip did not open on the hammer (ZeD's menu up: " .. tostring(zm0 and zm0.Type) .. ")")
        S.closeMenu()
        return
    end
    local okR, r = pcall(S.stripRun, zm)
    if not okR then S.fail("k1", "the strip's presses threw: " .. tostring(r)); S.closeMenu(); return end
    local n = r.n
    if n < 2 or type(r.s0) ~= "number" then S.fail("k1", "the hammer's strip has " .. tostring(n) .. " cell(s): nothing to step between"); S.closeMenu(); return end
    local nm = r.names
    S.k1.a = r.s1 == S.fwd(r.s0, n) and r.s3 == S.fwd(r.s2, n) and r.s5 == r.s4 and r.kd ~= true
    S.k1.b = r.s2 == S.bwd(r.s1, n) and r.s4 == S.bwd(r.s3, n) and r.s6 == r.s5 and r.ku ~= true
    Q.check(S.k1.a, "K2-1 (a): on a pad, Down steps the right-click strip forward one cell, as Right does; keyboard Down still leaves it to the game",
        "from cell " .. tostring(r.s0) .. " (" .. nm.s0 .. ") pad Down went to " .. tostring(r.s1) .. " (" .. nm.s1 .. "), want "
        .. S.fwd(r.s0, n) .. "; pad Right from " .. tostring(r.s2) .. " went to " .. tostring(r.s3) .. " (" .. nm.s3 .. "); keyboard Down left it on "
        .. tostring(r.s5) .. " (it was on " .. tostring(r.s4) .. "), the strip takes Down from the game " .. tostring(r.kd) .. "; " .. n
        .. " cells (old code: Down leaves the selection where it was)")
    Q.check(S.k1.b, "K2-1 (b): on a pad, Up steps the right-click strip back one cell, as Left does; keyboard Up still leaves it to the game",
        "from cell " .. tostring(r.s1) .. " (" .. nm.s1 .. ") pad Up went to " .. tostring(r.s2) .. " (" .. nm.s2 .. "), want "
        .. S.bwd(r.s1, n) .. "; pad Left from " .. tostring(r.s3) .. " went to " .. tostring(r.s4) .. " (" .. nm.s4 .. "); keyboard Up left it on "
        .. tostring(r.s6) .. " (it was on " .. tostring(r.s5) .. "), the strip takes Up from the game " .. tostring(r.ku)
        .. " (old code: Up is dead)")
    -- B shuts it, as the pad's B does at the strip's top level (cancel)
    local okB, e = pcall(zm.onJoypadDown, zm, Joypad.BButton)
    if not okB then Q.say("ERR B on the strip: " .. tostring(e)) end
end)
S.waitUntil(2000, function()
    if S.off.k1 then return true end
    return S.zedMenu(nil) == nil
end, function(ok)
    if S.off.k1 then return end
    if not ok then Q.check(false, "put back: B shut the right-click strip", "a ZeD menu is still up: shut by its close"); S.closeMenu() end
    S.optSet(S.St.contextStyleOption, 2)
    if not S.openMenu() then S.fail("k1", "the hammer's menu could not be made a second time") end
end)
S.waitUntil(3000, function()
    if S.off.k1 then return true end
    return S.zedMenu("ZeD_ContextList") ~= nil
end, function(ok)
    if S.off.k1 then return end
    local lm = S.zedMenu("ZeD_ContextList")
    if not (ok and lm) then
        local zm0 = S.zedMenu(nil)
        S.fail("k1", "the list look did not open on the hammer (ZeD's menu up: " .. tostring(zm0 and zm0.Type) .. ")")
        S.closeMenu()
        return
    end
    local okR, r = pcall(S.listRun, lm)
    if not okR then S.fail("k1", "the list's presses threw: " .. tostring(r)); S.closeMenu(); return end
    local nm = r.names
    local listOk = r.live >= 2 and r.y0 ~= nil and r.y1 ~= r.y0 and r.y2 == r.y0 and r.y3 == r.y1 and r.y4 == r.y0 and r.kd == true and r.ku == true
    Q.check(listOk and S.k1.a == true and S.k1.b == true,
        "K2-1 (c): on a pad, Down and Up move the selection on either look of the right-click menu: the list's rows as before, the strip's cells now",
        "the list: from row " .. tostring(r.y0) .. " (" .. nm.y0 .. ") pad Down went to " .. tostring(r.y1) .. " (" .. nm.y1 .. ") and pad Up back to "
        .. tostring(r.y2) .. "; keyboard Down to " .. tostring(r.y3) .. ", Up to " .. tostring(r.y4) .. "; it takes Down and Up from the game "
        .. tostring(r.kd) .. " / " .. tostring(r.ku) .. "; " .. tostring(r.live) .. " rows to choose; the strip: Down " .. tostring(S.k1.a)
        .. ", Up " .. tostring(S.k1.b) .. " (old code: the list moves, the strip does not)")
    local okB, e = pcall(lm.onJoypadDown, lm, Joypad.BButton)
    if not okB then Q.say("ERR B on the list: " .. tostring(e)) end
end)
S.waitUntil(2000, function()
    if S.off.k1 then return true end
    return S.zedMenu(nil) == nil
end, function(ok)
    if not S.off.k1 and not ok then Q.check(false, "put back: B shut the list", "a ZeD menu is still up: shut by its close") end
    S.closeMenu()
    if S.was.taken then S.optSet(S.St.contextStyleOption, S.was.ctx) end
end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    S.k5.gaveUp = true   -- (a car the prelude's wait brings after this is taken away at once)
    if S.aDown then RT.pad("A", nil); S.aDown = nil end
    S.closeWheel()
    S.closeMenu()
    -- (a run stopped in K2-4 may have left its tab open: folded by a click, as the reference did)
    local cw = RT.cw()
    if S.k4.tab and cw and S.isOpenOn(cw, S.k4.tab) and S.was.tab.c ~= S.k4.tab then S.clickTab(cw, S.k4.tab) end
    if S.was.taken then
        S.optSet(S.St.contextStyleOption, S.was.ctx)
        S.optSet(S.St.lookStyleOption, S.was.style)
    end
    S.carAway()
    S.release()
end)
S.waitUntil(6000, function() return S.carGone() end, function(ok)
    S.carGoneOk = ok
    S.homeBack()
    S.dashBack()
    RT.takeBack()   -- (the hammer)
    S.k4Back()
    S.queueBack()
    S.release()
    S.modeBack()
end)
-- (the detector's tick takes the moment's lock, if one was set; real time, at any frame rate)
Q.waitMs(400)
Q.step(1, function()
    S.modeFree()
    if S.was.char == nil then return end   -- (the run stopped before it read the windows)
    S.layoutBack(true)
    S.windowsBack()
end)
S.waitUntil(5000, function()
    if S.was.char == nil then return true end
    return S.charOpen() == S.was.char and S.worldOpen() == S.was.world
end, function()
    if S.was.char == nil then return end
    -- a window found shut: the layout the character keeps for it, as it was
    S.layoutBack(false)
    -- the Character window on the tab it was found on (K2-4 left it on Loot)
    local cw = RT.cw()
    if S.was.char and cw and S.was.tab.c and cw._activeTab ~= S.was.tab.c then S.clickTab(cw, S.was.tab.c) end
    S.restSig = nil
end)
S.waitUntil(3000, function()
    if S.was.char == nil then return true end
    return S.settled()
end, function()
    if S.was.char == nil then return end
    S.scrollBack()
    local moved = {}
    if S.was.char and S.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and S.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
end)
Q.step(10, function()
    if not S.was.taken then return end
    local F = S.F
    if getGameSpeed and getGameSpeed() ~= S.was.speed then S.speed(S.was.speed) end
    -- the wheel and the menus
    local zm = S.zedMenu(nil)
    S.putBack(S.wheelSt() == nil and not S.vis(S.radial()) and zm == nil, "no D-pad wheel and no right-click menu up",
        "ZeD's wheel state " .. tostring(S.wheelSt() ~= nil) .. ", the shared wheel on screen " .. tostring(S.vis(S.radial()))
        .. ", a ZeD menu " .. tostring(zm and zm.Type))
    -- the two option values (values only, never applied or saved)
    local ctx, style = S.optVal(S.St.contextStyleOption), S.optVal(S.St.lookStyleOption)
    S.putBack(ctx == S.was.ctx and style == S.was.style, "the Context menu and Style values as found",
        "Context menu " .. tostring(ctx) .. " (found " .. tostring(S.was.ctx) .. "), Style " .. tostring(style) .. " (found " .. tostring(S.was.style) .. ")")
    -- the car, the key, the hammer, him
    local keyOn = false
    local key = S.car and S.car.key
    if key then pcall(function() keyOn = S.p:getInventory():containsID(key:getID()) end) end
    local hammerOn = false
    local hammer = S.k1.item
    if hammer then pcall(function() hammerOn = S.p:getInventory():containsID(hammer:getID()) end) end
    local carLeft = S.car ~= nil and S.carLive(S.car.v)
    local h = S.health()
    local dx, dy = S.p:getX() - S.was.pos.x, S.p:getY() - S.was.pos.y
    local home = dx * dx + dy * dy <= 2.25 and math.floor(S.p:getZ()) == math.floor(S.was.pos.z)
    S.putBack(not carLeft and not keyOn and not hammerOn and S.p:getVehicle() == nil and not S.p:isDead() and home
        and (S.was.health == nil or h == nil or h >= S.was.health - 1),
        "the car gone, its key and the hammer out of his inventory, he on foot where he was found, alive and unhurt",
        "the car in the cell " .. tostring(carLeft) .. ", its key on him " .. tostring(keyOn) .. ", the hammer on him " .. tostring(hammerOn)
        .. ", in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", at " .. S.where() .. " (found at " .. S.num(S.was.pos.x) .. ","
        .. S.num(S.was.pos.y) .. "," .. S.num(S.was.pos.z) .. (S.movedFrom and ("; moved back from " .. S.movedFrom) or "")
        .. "), health " .. S.num(h) .. " (found " .. S.num(S.was.health) .. "), dead " .. tostring(S.p:isDead()))
    -- no timed action the run queued
    S.putBack(S.queued == nil and S.queueN() <= (S.was.queue or 0), "no timed action left by the run",
        "queued now " .. tostring(S.queueN()) .. " (found " .. tostring(S.was.queue) .. ")" .. (S.queued and ("; " .. S.queued .. " the run queued, cleared") or ""))
    -- the dash: let go, registered as found, the stop it keeps for the pad as found
    local d = S.dash()
    local z = S.dashZone(d)
    local reg = (d ~= nil and F.isRegistered(d)) and true or false
    local kept = (not S.was.dashTaken) or (z ~= nil and z.elements == S.was.dashEls and z.focusedElementIdx == S.was.dashIdx)
    S.putBack((d == nil or F.getFocusedWindow(S.pn) ~= d) and reg == S.was.dashReg and kept,
        "the dash let go of the pad, registered as found, the stop it keeps for the pad as found",
        "the pad on " .. S.holder() .. ", the dash registered " .. tostring(reg) .. " (found " .. tostring(S.was.dashReg) .. "), its kept stop restored "
        .. tostring(kept) .. ", shown " .. tostring(d ~= nil and d:isVisible()))
    -- the input lock and the mode ZeD reads
    if S.lockWas ~= nil and S.was.mode ~= nil then
        local now, mode = S.lockFound(), S.mode()
        local unknown = S.was.mode == "unknown" and mode == "kbm"
        S.putBack(now == S.lockWas and (mode == S.was.mode or unknown) and S.modeHeld == nil, "the input lock as found, and the mode ZeD reads",
            "ZeD setup's Input lock " .. tostring(now) .. " (found " .. tostring(S.lockWas) .. "); ZeD reads " .. tostring(mode)
            .. " (found " .. tostring(S.was.mode) .. ")"
            .. (unknown and "; found unknown, no input since the game started, which ZeD reads as the mouse: the detector has no way back to it" or ""))
    end
    -- the windows
    if S.was.char ~= nil then
        local cw, ww = RT.cw(), RT.ww()
        local c, w = S.charOpen(), S.worldOpen()
        local gc = c and S.geo(cw) or nil
        local gw = w and S.geo(ww) or nil
        local tc = (c and cw) and cw._activeTab or nil
        local tw = (w and ww) and ww._activeTab or nil
        S.putBack(c == S.was.char and w == S.was.world and S.sameGeo(gc, S.was.geo.c) and S.sameGeo(gw, S.was.geo.w)
            and tc == S.was.tab.c and tw == S.was.tab.w,
            "the Character and World windows open or shut as found, where and as big as they were, on their tabs",
            "Character open " .. tostring(c) .. " " .. S.gs(gc) .. " on " .. tostring(tc) .. " (found " .. tostring(S.was.char) .. " "
            .. S.gs(S.was.geo.c) .. " on " .. tostring(S.was.tab.c) .. "); World open " .. tostring(w) .. " " .. S.gs(gw) .. " on "
            .. tostring(tw) .. " (found " .. tostring(S.was.world) .. " " .. S.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w) .. ")"
            .. (S.moved and ("; the reopen left " .. S.moved .. " elsewhere: set back by its own setters") or ""))
    end
    -- the game speed
    local sp = getGameSpeed and getGameSpeed() or nil
    S.putBack(sp == S.was.speed, "the game speed as found", "speed " .. tostring(sp) .. " (found " .. tostring(S.was.speed) .. ")")
end)
Q.start()
