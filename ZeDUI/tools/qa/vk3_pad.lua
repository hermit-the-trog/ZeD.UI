-- ZeDUI/tools/qa/vk3_pad.lua  (Nov 22 2026, QA, KISS batch K3; tag vk3_pad): the in-game proof of Build's K3 work on
-- the pad, the director's picks #8, #13, #14, #15, #18, #20, #21, #26, #30, #34, #36 and #43 (the picks:
-- ZeDUI/qa/audits/2026-11-22_kiss_calls_K3.md). The old code is 0b366177e; the new is 7b8ed6843 (merge ae3f4a2b2 of
-- branch k3: 32b6eb4a1 World window, 7e249bda2 lists, 2dd9cd3e7 wheels and hint strip, 6d5cbe8c8 windows). Built on
-- rt_kit.lua (the global RT), run after zedqa_prelude.lua (its ZEDQA_CAR_* helpers spawn, seat and take away the car,
-- as vk2_pad.lua). grep "ZEDQA vk3_pad". For QA's manifest:
-- vk3_pad.lua | vk3_pad | timeout=480
--
-- What each check reads, and what the old code does there. Every PASS line is a pick proven: staging and the put-back
-- print a FAIL line only when they go wrong (a SAY line when they do not), and "NOTE" lines are readings, never checks.
-- 19 checks, each read from both commits: each FAILS on 0b366177e and PASSES on 7b8ed6843.
--   #14  (Full; and (Lite) for #43) ZeD's input mode locked to the mouse and keyboard, the pair shut, then locked to the
--        controller (the switch the detector makes when the stick is touched): 1.2 s later both windows are still
--        shut; then Y, tapped through FocusManager's poll (its QA hook, no window holding the pad), opens both.
--        Old: FocusManager's ZeD_InputModeChanged listener runs ensureBothOpenForGamepad on the switch: both open.
--   #8   (Full; and (Lite) for #43) a crate built on a free square beside him (an apple and a nail in it, a stove on
--        another square), he turned to face it, the pair shut, the pad let go. (a) Y (the poll) lands the pad on the
--        World window's list, on the crate's first row (the topmost row of that list, a thing in the crate). Old: Y
--        lands on the Character window (Focus.claimFocus(charWin)); the World window opens on the Floor (#13).
--        (b) the pad moved to the crate's second row (the nail), Y tapped on the window (its own press: dispatchJoypadDown,
--        then the poll's release) and Y again from the world: the pad is back on the nail's row. Old: the first Y rolls
--        both windows to bars, the second unrolls them with the Character window's focus.
--   #18  the crate on show in the World window (selectContainer when not; the old code opens on the Floor).
--        (a) the pad on the list's top stop, pad Up (FocusManager's own D-pad dispatch): the pad is on the heading's
--        Loot all (view:lootall). Old: no such button (the heading has the Filter and the view button).
--        (b) A tapped there takes everything from the crate: one move each of the apple and the nail into his
--        inventory, caught at ISTimedActionQueue.add by a recorder that queues nothing. Old: never reached.
--        (c) the pad on the crate's button on the strip, X tapped: the same moves. Old: X there does nothing.
--        NOTE (no check): where Down from the crate's last row lands in the button row (the pick's "lands on Loot all,
--        never To floor"). Build changed no landing rule for it: Loot all only became a word button, and the stop is
--        the nearest one lined up under the row (SpatialNav: a row is 200u wide from the left, the left one wins ties).
--        Read from the code: old To floor; new Full most likely Same type, new Lite (no Same type) To floor again.
--   #30  (a) the pad on the crate's apple row, A held 650 ms (past A_HOLD_MS): the apple is marked and nothing is
--        queued. Old: hold A on food eats it (the eat recorded), nothing marked.
--        (b) a bandage given; the pad on its row in his own inventory (the Character window's list): the footer's hold
--        word (the row's promptHold, read as the footer reads it) is the game's Bandage. Old: "Mark".
--   #34  the pad on the Character window (the bandage row), the bumper of the Eat chord (the chord whose path is the
--        Character wheel's Eat, LB + A by default) held and A pressed (both through FocusManager's dispatch and hook):
--        QuickChords ran that chord (Q.lastChord), neither window turned a tab and A opened no card. Old: A works the
--        row (its card), the bumper's release turns the Character window to its next tab, no chord.
--        (The chord's action, an eat, is recorded and never queued.)
--   #26  the hint strip's first hours' line, read from ZeD_HintStrip's own function (H.teach) with player 1's pad slot
--        stood in for one Lua call (no pad is plugged in, and the line is for a pad only) and its two use counts seen as
--        fresh for that call (restored in the same call: nothing is written): three parts, D-PAD Wheels, LB or, RB
--        + button Quick actions, in the game's words. Old: no such line (H.teach does not exist). SKIP when ZeD
--        setup's hint strip is Off (the pick: "Off aside").
--   #21  D-pad Left opened by the game's opener (ISDPadWheels.onDisplayLeft), the press held as the wheel's QA hook
--        reads it (DpadWheels.qaHeld: 50 ms, then past HOLD_WEAPONS_MS): the Weapons ring opens; tapped (let go
--        before the hold time): the Character wheel stays. A hammer and a kitchen knife given, so Weapons is live.
--        Old: no hold rule (D.qaHeld and D.holdTick do not exist): holding opens the Character wheel only. SKIP with
--        the wheels' Hold setting (the pick leaves it as is).
--   #15  a station in reach (one found, else the stove built beside him). D-pad Right, Craft and build taken as A
--        takes it (WheelGesture.commit): (a) the ring is Crafting (no station named on it), Building, Move furniture
--        and last a slice named for the nearest station; (b) Crafting taken: the World window on Craft, no station
--        bound (ZeD.Stations.current). Old: three slices, Crafting reads "<station>, N tiles" and binds the station.
--   #36  D-pad Right, Map taken: the game's map toggle runs at once (ISWorldMap.ToggleWorldMap stood in for by a
--        recorder for that one call: no map-reading action) and no wheel stays up. Old: Map opens a ring (World map,
--        Back).
--   #20  (Full; and (Lite) for #43) on foot D-pad Up (ISDPadWheels.onDisplayUp) opens Social; seated in a car (the
--        prelude's pickup, the driver's seat) it opens the car's wheel at once (its top level filled by
--        DpadWheels.vehicleFill, the game's vehicle wheel). Old: Social in the car too.
--   #43  Lite on a pad: Build made #8, #14 and #20 hold in every Style (no Lite-only code); the (Lite) legs above run
--        them with Style Lite (the option's value only), so each FAILS on the old code as its Full leg does.
--   #13  is read inside #8 (a): the World window opened by Y shows the crate he faces, not the Floor.
--
-- How it stages, with no controller plugged in: ZeD's input mode locked (S.lock, as vx12_wheel.lua and vk2_pad.lua),
-- each press through the handler the pad's press reaches: FocusManager's QA hook (Focus.qaButton) for the poll's Y,
-- A, X and the bumpers, its dispatchJoypadDown / dispatchJoypadDir for a press on the window holding the pad, the
-- game's ISDPadWheels.onDisplay* for the D-pad wheels, WheelGesture.commit for A on a slice. Nothing is eaten, drunk,
-- moved or used: while a press that could act is in flight, ISTimedActionQueue.add / addAfter keep the action and
-- queue nothing (vk1_pad.lua's recorder; ISInventoryPaneContextMenu.OnNewCraft only records), and a timed action that
-- reaches the real queue anyway is cleared in the same call (FAIL). The hint strip's use counts are held for the run
-- (HintStrip.taught stood in for by a no-op: the run's own wheels and chords spend none of the director's first
-- hours' uses). Order: #14 and #8 with Style Lite, then Full; #18, #30, #34 on the open pair; the wheels; the car.
-- Waits go by the clock; no pixel size is written in (4K at UI scale 1.75 and 1280x800 Auto alike).
-- What it puts back (also when a step throws or the time runs out): the pad's buttons let go, the recorder, the map
-- toggle and HintStrip.taught taken off (checked), DpadWheels.qaHeld cleared, QuickChords.lastChord as found, the
-- wheel and any menu shut, the marks wiped, a station the run bound unbound (one found bound bound again), the
-- crate (and what is in it) and the stove taken away, the bandage, hammer and knife out of his inventory, the car
-- taken away (him out first, its key out of his inventory), him where he was found and facing as he did, a timed
-- action the run queued cleared, Style, the input lock and the mode ZeD read (vx12_wheel.lua's way), the World
-- window's remembered Y row cleared, the windows open or shut as found, where and as big as they were, on their tabs,
-- and the game speed. No option is saved, no file is written, ZEDQA_LAYOUT_BACK is never called.
-- KCheck OK. Not run in game yet; no offline run (the stubbed KRun harness of vk2_pad.lua is not in the repo).

if not (RT and RT.make) then
    print("ZEDQA vk3_pad ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk3_pad VERDICT FAIL 1")
    print("ZEDQA vk3_pad DONE")
    return
end

local Q = RT.make("vk3_pad")
Q.maxMs = 300000   -- (five minutes, then the put-back; a run takes about two, the car's wait the most)
local Z = ZeD or {}
local S = { p = RT.p, pn = RT.pn, was = { geo = {}, tab = {} }, off = {}, held = {}, k8 = {}, k14 = {}, k15 = {}, k18 = {},
    k20 = {}, k21 = {}, k26 = {}, k30 = {}, k34 = {}, k36 = {}, k5 = {} }
S.Det = Z.Input and Z.Input.Detector
S.F = Z.Input and Z.Input.Focus
S.D, S.W, S.G, S.St = Z.DpadWheels, Z.Wheel, Z.WheelGesture, Z.Settings
S.HS, S.QC, S.ST, S.R = Z.HintStrip, Z.QuickChords, Z.Stations, Z.InventoryRenderer
S.PART = { k14L = "#43 (Lite) #14", k14F = "#14", k8L = "#43 (Lite) #8", k8F = "#8", k18 = "#18", k30 = "#30",
    k30b = "#30 (b)", k34 = "#34", k26 = "#26", k21 = "#21", k15 = "#15", k36 = "#36", k20 = "#20", k20c = "#20 seated", crate = "the crate" }
S.CARS = { "Base.PickUpTruck", "Base.CarNormal" }
S.STOVES = { "appliances_cooking_01_0", "appliances_cooking_01_8" }
S.AROUND = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.DIRNAME = { ["1,0"] = "E", ["0,1"] = "S", ["-1,0"] = "W", ["0,-1"] = "N", ["1,1"] = "SE", ["-1,1"] = "SW",
    ["1,-1"] = "NE", ["-1,-1"] = "NW" }
S.BUMP = { LB = { qa = "LeftBump", btn = "LBumper" }, RB = { qa = "RightBump", btn = "RBumper" } }
S.FACE = { A = "AButton", B = "BButton", X = "XButton", Y = "YButton" }

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
-- staging that cannot go on: one FAIL line, the part's checks not run (a part not proven is a FAIL, never a SKIP)
function S.fail(key, why)
    if S.off[key] then return end
    S.off[key] = true
    local part = S.PART[key] or key
    Q.check(false, part .. " staging: " .. tostring(why) .. " (" .. part .. " not proven)")
end
-- the put-back: a SAY line when it is as found, a FAIL line when it is not (never a PASS: it proves no pick)
function S.putBack(ok, what, detail)
    if ok then Q.say("put back: " .. what .. " | " .. tostring(detail))
    else Q.check(false, "put back: " .. what, detail) end
end
function S.itemName(it)
    if not it then return "nothing" end
    local nm = nil
    pcall(function() nm = it:getDisplayName() end)
    return tostring(nm or "a thing")
end

-- ===================================================================== the windows (vk2_pad.lua)
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
-- a window rolled to its bar (either half, FocusManager's own test)
function S.rolled(w)
    if not w then return false end
    if S.F and S.F.isRolled then
        local ok, r = pcall(S.F.isRolled, w)
        if ok then return r and true or false end
    end
    return w.windowShaded and true or false
end
function S.pairWord()
    return "Character open " .. tostring(S.charOpen()) .. (S.rolled(RT.cw()) and " (rolled)" or "") .. ", World open "
        .. tostring(S.worldOpen()) .. (S.rolled(RT.ww()) and " (rolled)" or "")
end
-- the pair shut (a pause closes only the Character window, so anything left is shut too)
function S.closePair()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.charOpen() and S.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.worldOpen() and WW.close then pcall(WW.close, S.pn) end
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
-- the layout the character keeps for each window (md.ZeD_WinState.char / .world; vk2_pad.lua S.layoutBack)
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
-- a click on a tab of a window's strip (the strip's own mouse handler at the tab's place, as RT.goTab)
function S.clickTab(w, strip, id)
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == "tab:" .. id then
            local ok = pcall(strip.onMouseDown, strip, z.x + 2, z.y + 2)
            return ok
        end
    end
    return false
end

-- ===================================================================== the input mode ZeD reads (vx12_wheel.lua)
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
-- mode "gamepad" or "kbm"; nil or false puts back the lock found (only a lock this script set)
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

-- ===================================================================== the wheels (vk2_pad.lua)
function S.wheelSt() return (S.D and S.D.state) and S.D.state[S.pn] or nil end
function S.radial() return getPlayerRadialMenu and getPlayerRadialMenu(S.pn) or nil end
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
-- nothing but the world: no wheel or menu up, the pad let go, the pair shut
function S.toWheel()
    S.closeWheel()
    S.closeMenu()
    S.release()
    S.closePair()
    S.release()
    if setJoypadFocus then pcall(setJoypadFocus, S.pn, nil) end
end
-- the wheel opened the way the D-pad press opens it (ISDPadWheels.onDisplay*); ZeD's own opener only when that left
-- it shut
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
    for _, s in ipairs(S.slices()) do t[#t + 1] = S.firstLine(s.text) end
    return (#t > 0) and table.concat(t, ", ") or "no wheel"
end
function S.wheelUp()
    local st = S.wheelSt()
    return st ~= nil and S.vis(st.menu)
end
-- slice i taken as A takes it on the wheel (ZeD_WheelGesture.lua G.commit)
function S.commit(i)
    local st = S.wheelSt()
    if not (st and st.menu and i) then return false end
    local ok, e = pcall(S.G.commit, S.pn, st, i, true)
    if not ok then Q.say("ERR the wheel's accept: " .. tostring(e)) end
    return ok
end
function S.holder()
    local fw = (S.F and S.F.getFocusedWindow) and S.F.getFocusedWindow(S.pn) or nil
    return S.winName(fw)
end
function S.winName(w)
    if w == nil then return "no ZeD window (the game has the pad)" end
    if w == RT.ww() then return "the World window" end
    if w == RT.cw() then return "the Character window" end
    return tostring(w._zedLabel or w.Type or "a window")
end

-- ===================================================================== the pad's focus
function S.focusNow()
    local F = S.F
    local w = F.getFocusedWindow(S.pn)
    local z = w and F.getFocusedZone(w) or nil
    local el = w and F.getFocusedElement(w) or nil
    return w, (z and z.zone) or nil, el
end
function S.elName(el)
    if not el then return "no stop" end
    return tostring(el.id) .. (el.item and (" (" .. S.itemName(el.item) .. ")") or "")
end
function S.focusSay()
    local w, zn, el = S.focusNow()
    return S.winName(w) .. ", zone " .. tostring(zn) .. ", on " .. S.elName(el)
end
-- a stop's footer word as the footer reads it (a prompt may be a function of the window and the stop)
function S.word(v, w, e)
    if type(v) ~= "function" then return v end
    local ok, r = pcall(v, w, e)
    if ok then return r end
    return nil
end
function S.pending(w)
    if not (w and S.F and S.F.soonPending) then return false end
    return S.F.soonPending(w) and true or false
end
function S.zoneEls(w, zn)
    for _, z in ipairs((w and w._focusRing) or {}) do
        if z.zone == zn then return z.elements or {} end
    end
    return {}
end
function S.elIn(w, zn, pred)
    for _, e in ipairs(S.zoneEls(w, zn)) do
        if pred(e) then return e end
    end
    return nil
end
-- the item rows of a list in view, top to bottom
function S.rows(w, zn)
    local out = {}
    for _, e in ipairs(S.zoneEls(w, zn)) do
        if e.item ~= nil and not e.offscreen and not e.isViewToggle then out[#out + 1] = e end
    end
    table.sort(out, function(a, b) return (a.y or 0) < (b.y or 0) end)
    return out
end
-- the list's top stop (a row, an open stack's header or a category heading; never a heading button)
function S.listTop(w, zn)
    local best = nil
    for _, e in ipairs(S.zoneEls(w, zn)) do
        if not e.isViewToggle and not e.offscreen and (e.item ~= nil or e.isCatHead or e.isStackHead) then
            if best == nil or (e.y or 0) < (best.y or 0) then best = e end
        end
    end
    return best
end
-- a button of the pad pressed and let go through FocusManager's QA hook (the poll reads it), over ms of real time;
-- with a window, the press also goes to that window's own dispatch (what the engine hands the window holding the pad)
function S.tap(key, name, button, wfn, ms)
    Q.step(1, function()
        if S.off[key] then return end
        RT.pad(name, true)
        S.held[name] = true
        if button and wfn then
            local w = wfn()
            if w then RT.padDown(button, w) end
        end
    end)
    Q.waitMs(ms or 120)
    Q.step(1, function() if S.held[name] then RT.pad(name, false) end end)
    Q.step(4, function() if S.held[name] then RT.pad(name, nil); S.held[name] = nil end end)
end
function S.letGo()
    for name in pairs(S.held) do RT.pad(name, nil) end
    S.held = {}
end
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

-- ===================================================================== the recorder (vk1_pad.lua: nothing is queued)
function S.dryOn()
    if S.dry then return S.dry end
    local d = { acts = {} }
    d.add, d.after, d.craft = ISTimedActionQueue.add, ISTimedActionQueue.addAfter, ISInventoryPaneContextMenu.OnNewCraft
    d.wAdd = function(action, ...)
        d.acts[#d.acts + 1] = action
        local ch = (type(action) == "table") and action.character or nil
        if ch ~= nil then return ISTimedActionQueue.getTimedActionQueue(ch) end
        return nil
    end
    d.wAfter = function(prev, action, ...)
        d.acts[#d.acts + 1] = action
        return nil
    end
    d.wCraft = function(item, ...)
        d.acts[#d.acts + 1] = { Type = "OnNewCraft (opening recipe)", item = item }
    end
    ISTimedActionQueue.add, ISTimedActionQueue.addAfter = d.wAdd, d.wAfter
    ISInventoryPaneContextMenu.OnNewCraft = d.wCraft
    S.dry = d
    return d
end
function S.dryOff()
    local d = S.dry
    if d == nil then return nil end
    S.dry = nil
    if ISTimedActionQueue.add == d.wAdd then ISTimedActionQueue.add = d.add else S.dryStuck = true end
    if ISTimedActionQueue.addAfter == d.wAfter then ISTimedActionQueue.addAfter = d.after else S.dryStuck = true end
    if ISInventoryPaneContextMenu.OnNewCraft == d.wCraft then ISInventoryPaneContextMenu.OnNewCraft = d.craft else S.dryStuck = true end
    S.queueGuard()
    return d
end
-- a timed action that reached the real queue around the recorder: cleared at once (the put-back FAILs on it)
function S.queueGuard()
    local n = S.queueN()
    if S.was.queue ~= nil and n > S.was.queue then
        pcall(ISTimedActionQueue.clear, S.p)
        S.leaked = (S.leaked or 0) + (n - S.was.queue)
        Q.say("ERR a timed action reached the real queue during a recording: the queue cleared (" .. n .. ", found " .. S.was.queue .. ")")
    end
end
function S.actWords(acts)
    local t = {}
    for _, a in ipairs(acts or {}) do
        local ty = (type(a) == "table") and tostring(a.Type or "an action") or tostring(a)
        local it = (type(a) == "table") and a.item or nil
        t[#t + 1] = ty .. (it and (" of " .. S.itemName(it)) or "")
    end
    return (#t > 0) and table.concat(t, ", ") or "nothing"
end
-- the recorded moves of the crate's two things into his own inventory
function S.takesBoth(acts)
    local inv = S.p:getInventory()
    local apple, nail = false, false
    for _, a in ipairs(acts or {}) do
        if type(a) == "table" and a.destContainer == inv and a.srcContainer == S.crate.inv then
            if a.item == S.crate.apple then apple = true end
            if a.item == S.crate.nail then nail = true end
        end
    end
    return apple and nail, apple, nail
end

-- ===================================================================== settings (the values only), the player
function S.optVal(o) if o and o.getValue then return o:getValue() end; return nil end
function S.optSet(o, v) if o and o.setValue and v ~= nil and o:getValue() ~= v then o:setValue(v) end end
function S.style(n) if S.St then S.optSet(S.St.lookStyleOption, n) end end
function S.liteNow() return (S.St and S.St.lite and S.St.lite()) and true or false end
function S.styleWord() return S.liteNow() and "Lite" or "Full" end
function S.speed(n) if ZEDQA_SPEED then ZEDQA_SPEED(n) elseif setGameSpeed then setGameSpeed(n) end end
function S.health()
    local bd = S.p:getBodyDamage()
    if not bd then return nil end
    return bd:getOverallBodyHealth()
end
function S.queueN()
    local n = 0
    if ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue then
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        if q and q.queue then n = #q.queue end
    end
    return n
end
function S.queueBack()
    if not S.was.taken then return end
    local n = S.queueN()
    if n > 0 and (S.was.queue or 0) == 0 and ISTimedActionQueue and ISTimedActionQueue.clear then
        S.queued = n
        pcall(ISTimedActionQueue.clear, S.p)
    end
end
function S.where() return S.num(S.p:getX()) .. "," .. S.num(S.p:getY()) .. "," .. S.num(S.p:getZ()) end
function S.homeBack()
    local at = S.was.pos
    if not at or S.p:getVehicle() then return end
    local dx, dy = S.p:getX() - at.x, S.p:getY() - at.y
    if dx * dx + dy * dy <= 2.25 and math.floor(S.p:getZ()) == math.floor(at.z) then return end
    S.movedFrom = S.where()
    S.p:setX(at.x); S.p:setY(at.y); S.p:setZ(at.z)
    S.p:setLastX(at.x); S.p:setLastY(at.y); S.p:setLastZ(at.z)
end
-- him turned to the crate (the World window shows the container on the square he faces: KISS #13)
function S.face()
    local c = S.crate
    if not (c and c.dir and IsoDirections) then return end
    local d = IsoDirections[c.dir]
    if d then pcall(function() S.p:setDir(d) end) end
end
function S.mine(it)
    if not it then return false end
    local inv = S.p:getInventory()
    if not inv then return false end
    return inv:containsID(it:getID()) and true or false
end

-- ===================================================================== the crate and the stove (bx_inventory.lua, bxr_menus.lua)
-- a square beside him: loaded, free, nothing else on it, in reach
function S.freeSq(skip)
    local cell = getCell()
    local here = S.p:getCurrentSquare()
    if not (cell and here) then return nil, nil end
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, d in ipairs(S.AROUND) do
        local sq = cell:getGridSquare(x + d[1], y + d[2], z)
        local ok = false
        if sq and sq ~= skip then
            local objs, wobjs = sq:getObjects(), sq:getWorldObjects()
            ok = objs ~= nil and wobjs ~= nil and sq:isFree(false) and objs:size() <= 1 and wobjs:size() == 0
                and sq:getVehicleContainer() == nil and here:canReachTo(sq)
        end
        if ok then return sq, d end
    end
    return nil, nil
end
function S.mkCrate(sq)
    local c = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
        if not o then return end
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        local inv = o:getContainer()
        if inv then
            pcall(function() inv:setExplored(true) end)
            c = { obj = o, inv = inv, sq = sq }
        end
    end)
    return c
end
function S.mkStove(sq)
    for _, name in ipairs(S.STOVES) do
        local spr = getSprite(name)
        if spr then
            local o = nil
            pcall(function()
                o = IsoStove.new(getCell(), sq, spr)
                if not o then return end
                pcall(function() o:createContainersFromSpriteProperties() end)
                sq:AddSpecialObject(o)
                if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
            end)
            if S.standing(o) then return o end
        end
    end
    return nil
end
-- (bx_inventory.lua H.rmCrate / bxr_inv.lua S.removeObj: the game's removal, then the tile's own when it stands)
function S.removeObj(o)
    if not o then return end
    local sq = o:getSquare()
    if not sq then return end
    pcall(function() sq:transmitRemoveItemFromSquare(o) end)
    if o:getObjectIndex() >= 0 then pcall(function() sq:RemoveTileObject(o) end) end
end
function S.standing(o)
    if not o then return false end
    local sq = o:getSquare()
    local objs = sq and sq:getObjects() or nil
    return objs ~= nil and objs:contains(o) and true or false
end
-- a thing put in the crate, marked as QA's
function S.toCrate(ft)
    local c = S.crate
    local it = nil
    pcall(function() it = c.inv:AddItem(ft) end)
    if it then pcall(function() it:getModData().ZeDQA_spawned = true end) end
    return it
end
function S.inCrate(it)
    local c = S.crate
    if not (c and c.inv and it) then return false end
    local con = nil
    pcall(function() con = it:getContainer() end)
    return con == c.inv
end
function S.crateBack()
    local c = S.crate
    if not c then return end
    for _, it in ipairs({ c.apple or false, c.nail or false }) do
        if it then pcall(function() local con = it:getContainer(); if con then con:Remove(it) end end) end
    end
    S.removeObj(c.obj)
    if S.stove then S.removeObj(S.stove) end
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end
end

-- ===================================================================== the car (vk2_pad.lua, zedqa_prelude.lua)
function S.carStart()
    if not ZEDQA_CAR_WAIT then return S.carSpawn() end
    S.k5.waiting = true
    ZEDQA_CAR_WAIT(S.CARS[1], "vk3_pad", function(v)
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
            local v, why = ZEDQA_CAR_SPAWN(script, "vk3_pad")
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
    local cell = getCell()
    local list = cell and cell:getVehicles() or nil
    if not list then return false end
    -- (QA, Nov 22: IsoCell.getVehicles is a Set on 42.2x, with no get(i): walked with its iterator, as vk1_pad does)
    local it = list:iterator()
    while it:hasNext() do
        if it:next() == v then return true end
    end
    return false
end
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

-- ===================================================================== #14: the switch to the pad, then Y
function S.queue14(L)
    local key = L.key
    Q.step(3, function()
        if S.dead then S.off[key] = true; return end
        S.style(L.style)
        S.toWheel()
        S.lock("kbm")
    end)
    S.waitUntil(3000, function() return S.off[key] or S.mode() == "kbm" end, function(ok)
        if S.off[key] then return end
        if not ok then S.fail(key, "ZeD's input mode did not take the lock to the mouse and keyboard (it reads " .. tostring(S.mode()) .. ")"); return end
        S.toWheel()
    end)
    Q.waitMs(600)   -- (the detector's 200 ms between switches, and any late open)
    Q.step(1, function()
        if S.off[key] then return end
        S.toWheel()
        if S.charOpen() or S.worldOpen() then S.fail(key, "the pair did not shut before the switch (" .. S.pairWord() .. ")"); return end
        L.style0 = S.styleWord()
        S.lock("gamepad")
    end)
    S.waitUntil(3000, function() return S.off[key] or S.mode() == "gamepad" end, function(ok)
        if S.off[key] then return end
        if not ok then S.fail(key, "ZeD's input mode did not take the lock to the controller (it reads " .. tostring(S.mode()) .. ")") end
    end)
    Q.waitMs(1200)
    Q.step(1, function()
        if S.off[key] then return end
        L.c1, L.w1, L.h1 = S.charOpen(), S.worldOpen(), S.holder()
        -- (the old code opened them: shut again, so its Y is read too)
        if L.c1 or L.w1 then S.toWheel() end
        S.face()
    end)
    Q.waitMs(400)
    S.tap(key, "Y", nil, nil, 120)
    S.waitUntil(3000, function() return S.off[key] or (S.charOpen() and S.worldOpen()) end, function(ok)
        if S.off[key] then return end
        Q.check(not L.c1 and not L.w1 and ok,
            L.label .. ": the switch to the controller opens nothing, and Y opens both windows (Style " .. tostring(L.style0) .. ")",
            "1.2 s after ZeD took the controller: Character open " .. tostring(L.c1) .. ", World open " .. tostring(L.w1)
            .. ", the pad on " .. tostring(L.h1) .. "; after Y: " .. S.pairWord() .. ", the pad on " .. S.holder()
            .. " (old code: the switch opens both windows and hands the pad to the Character window)")
        S.toWheel()
    end)
end

-- ===================================================================== #8: Y to the crate, and back to the row it left
function S.queue8(L)
    local key = L.key
    Q.step(3, function()
        if S.dead or S.off.crate then S.off[key] = true; return end
        S.style(L.style)
        S.toWheel()
        S.face()
    end)
    Q.waitMs(500)
    Q.step(1, function()
        if S.off[key] then return end
        S.toWheel()
        S.face()
        if S.charOpen() or S.worldOpen() then S.fail(key, "the pair did not shut (" .. S.pairWord() .. ")"); return end
        if S.mode() ~= "gamepad" then S.fail(key, "ZeD does not read the controller (" .. tostring(S.mode()) .. ")"); return end
        L.style0 = S.styleWord()
    end)
    S.tap(key, "Y", nil, nil, 120)
    S.waitUntil(4000, function()
        if S.off[key] then return true end
        local w, zn, el = S.focusNow()
        return w ~= nil and w == RT.ww() and zn == "worldMainInv" and el ~= nil and S.inCrate(el.item) and not S.pending(w)
    end, function(ok)
        if S.off[key] then return end
        local ww = RT.ww()
        local w, zn, el = S.focusNow()
        local top = ww and S.rows(ww, "worldMainInv")[1] or nil
        local shown = ww and ww._containers and ww._containers[ww._activeContainer or 0] or nil
        local shownWord = shown and (shown.isFloor and "the Floor" or ((shown.inventory == S.crate.inv) and "the crate" or tostring(shown.name))) or "nothing"
        Q.check(ok and top ~= nil and el ~= nil and el.item == top.item,
            L.label .. " (a): near a crate, Y lands the pad on the crate's first row in the World window (Style " .. tostring(L.style0) .. ")",
            "after Y the pad is on " .. S.focusSay() .. "; the crate's first row: " .. S.elName(top) .. "; the World window shows "
            .. shownWord .. " (" .. S.pairWord() .. ") (old code: Y lands on the Character window, the World window on the Floor)")
        -- the pad on the crate's second row, the nail: the row the next Y leaves
        if not ww then S.fail(key, "the World window is not open after Y"); return end
        if ww._activeTab ~= "loot" then RT.worldTab("loot") end
        if shown == nil or shown.inventory ~= S.crate.inv then pcall(ZeD_WorldWindow.selectContainer, S.crate.inv, 60, S.pn) end
        S.F.claimFocus(ww)
    end)
    S.waitUntil(3000, function()
        if S.off[key] then return true end
        return S.elIn(RT.ww(), "worldMainInv", function(e) return e.item == S.crate.nail end) ~= nil
    end, function(ok)
        if S.off[key] then return end
        local ww = RT.ww()
        local e = ok and S.F.focusWhere(ww, "worldMainInv", function(x) return x.item == S.crate.nail end) or nil
        if not e then S.fail(key, "the pad could not be put on the crate's nail row (" .. S.focusSay() .. ")"); return end
        L.left = S.focusSay()
    end)
    Q.waitMs(300)
    S.tap(key, "Y", Joypad.YButton, function() return S.F.getFocusedWindow(S.pn) end, 120)
    Q.waitMs(700)
    Q.step(1, function()
        if S.off[key] then return end
        L.mid = S.pairWord() .. ", the pad on " .. S.holder()
    end)
    S.tap(key, "Y", nil, nil, 120)
    S.waitUntil(4000, function()
        if S.off[key] then return true end
        local w, zn, el = S.focusNow()
        return w ~= nil and w == RT.ww() and el ~= nil and el.item == S.crate.nail and not S.pending(w)
    end, function(ok)
        if S.off[key] then return end
        Q.check(ok, L.label .. " (b): a later Y returns the pad to the row it left (Style " .. tostring(L.style0) .. ")",
            "the pad left " .. tostring(L.left) .. "; after the Y on the window: " .. tostring(L.mid) .. "; after the next Y the pad is on "
            .. S.focusSay() .. " (old code: the first Y rolls both windows to bars, the next unrolls them with the Character window's focus)")
    end)
end

-- ===================================================================== #18, #30 (a): the crate's list on the pad
function S.worldReady()
    local ww = RT.ww()
    if not (ww and S.charOpen() and S.worldOpen()) then return false end
    if ww._activeTab ~= "loot" or S.rolled(ww) then return false end
    local shown = ww._containers and ww._containers[ww._activeContainer or 0]
    if not (shown and shown.inventory == S.crate.inv) then return false end
    local a = S.elIn(ww, "worldMainInv", function(e) return e.item == S.crate.apple end)
    local n = S.elIn(ww, "worldMainInv", function(e) return e.item == S.crate.nail end)
    return a ~= nil and n ~= nil
end
function S.queueC()
    Q.step(3, function()
        if S.dead or S.off.crate then S.off.k18 = true; S.off.k30 = true; return end
        S.closeMenu()
        if not (S.charOpen() and S.worldOpen()) then
            S.release()
            if ZeD_CharacterWindow.ensureBothOpenForGamepad then pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, S.pn) end
        end
        local ww = RT.ww()
        if not ww then return end
        if S.rolled(ww) and S.F.showWin then pcall(S.F.showWin, ww) end
        if ww._activeTab ~= "loot" then RT.worldTab("loot") end
        local shown = ww._containers and ww._containers[ww._activeContainer or 0]
        if not (shown and shown.inventory == S.crate.inv) then pcall(ZeD_WorldWindow.selectContainer, S.crate.inv, 60, S.pn) end
        S.F.claimFocus(ww)
    end)
    S.waitUntil(4000, function() return S.off.k18 or S.worldReady() end, function(ok)
        if S.off.k18 then return end
        if not ok then
            S.fail("k18", "the World window did not show the crate's two rows on Loot (" .. S.pairWord() .. ", the pad on " .. S.focusSay() .. ")")
            S.fail("k30", "the World window did not show the crate's two rows on Loot")
            return
        end
        local ww = RT.ww()
        S.F.claimFocus(ww)
        -- NOTE: Down from the last row, into the button row
        local rows = S.rows(ww, "worldMainInv")
        local last = rows[#rows]
        local e = last and S.F.focusWhere(ww, "worldMainInv", function(x) return x == last end) or nil
        if e then
            RT.padDir("down", ww)
            local _, zn, el = S.focusNow()
            -- (QA, Nov 22: Build built this half of #18 in d0df24046: the band's entry stop is the take button. On
            -- 0b366177e and on the first K3 merge Down landed on Same type in Full and To floor in Lite: FAIL there.)
            -- (Nov 22 2026, the director's "Number 1": the band has no Loot all now; Down past the last row wraps to
            -- the heading's Loot all, view:lootall)
            Q.check(el ~= nil and type(el.id) == "string" and el.id:sub(1, 13) == "view:lootall:",
                "K3 #18: Down from a crate's last row wraps to the heading's Loot all, never To floor",
                "Down from " .. S.elName(last) .. " lands on " .. S.elName(el) .. " (zone " .. tostring(zn) .. ", id "
                .. tostring(el and el.id) .. ", band key " .. tostring(el and el.ccKey) .. ")")
        end
        -- (a) the top stop, then Up
        local top = S.listTop(ww, "worldMainInv")
        local t = top and S.F.focusWhere(ww, "worldMainInv", function(x) return x == top end) or nil
        if not t then S.fail("k18", "the pad could not be put on the list's top stop"); return end
        S.k18.top = S.elName(t)
        RT.padDir("up", ww)
        local _, zn, el = S.focusNow()
        S.k18.up = el
        S.k18.upSay = S.focusSay()
        S.k18.on = el ~= nil and type(el.id) == "string" and el.id:sub(1, 13) == "view:lootall:"
        Q.check(S.k18.on, "#18 (a): on a pad, Loot all sits in the list's heading, one Up from the first row",
            "from the top stop (" .. S.k18.top .. ") Up lands on " .. S.k18.upSay .. ", its A word " .. tostring(el and el.promptA)
            .. " (old code: the heading has no Loot all)")
        if S.k18.on then S.dryOn() end
    end)
    S.tap("k18", "A", Joypad.AButton, function() if S.k18.on then return RT.ww() end; return nil end, 120)
    Q.waitMs(300)
    Q.step(1, function()
        local d = S.dryOff()
        if S.off.k18 then return end
        local all, a, n = S.takesBoth(d and d.acts)
        Q.check(S.k18.on == true and all,
            "#18 (b): A on the heading's Loot all takes everything from the crate (the moves recorded, nothing moved)",
            "A on " .. tostring(S.k18.upSay) .. " recorded: " .. S.actWords(d and d.acts) .. "; the apple's move " .. tostring(a)
            .. ", the nail's " .. tostring(n) .. (S.k18.on and "" or "; not pressed: Up did not reach a Loot all")
            .. " (old code: no Loot all in the heading)")
        -- (c) the crate's button on the strip, then X
        local ww = RT.ww()
        local idx = nil
        for i, c in ipairs((ww and ww._containers) or {}) do if c.inventory == S.crate.inv then idx = i end end
        local e = idx and S.F.focusWhere(ww, "worldContainerStrip", function(x) return x.containerIdx == idx end) or nil
        if not e then S.fail("k18", "the pad could not be put on the crate's button on the strip (" .. S.focusSay() .. ")"); return end
        S.k18.btn = S.focusSay()
        S.k18.xWord = S.word(e.promptX, ww, e)
        S.dryOn()
    end)
    S.tap("k18", "X", Joypad.XButton, function() return RT.ww() end, 120)
    Q.waitMs(300)
    Q.step(1, function()
        local d = S.dryOff()
        if S.off.k18 then return end
        local all, a, n = S.takesBoth(d and d.acts)
        Q.check(all, "#18 (c): on a pad, X on a container's button takes all from it (the moves recorded, nothing moved)",
            "X on " .. tostring(S.k18.btn) .. " (its X word " .. tostring(S.k18.xWord) .. ") recorded: " .. S.actWords(d and d.acts)
            .. "; the apple's move " .. tostring(a) .. ", the nail's " .. tostring(n) .. " (old code: X on a container's button does nothing)")
    end)
    -- #30 (a): the apple's row, A held
    Q.step(1, function()
        if S.off.k30 then return end
        local ww = RT.ww()
        if ww then S.F.claimFocus(ww) end
        local e = ww and S.F.focusWhere(ww, "worldMainInv", function(x) return x.item == S.crate.apple end) or nil
        if not e then S.fail("k30", "the pad could not be put on the crate's apple row (" .. S.focusSay() .. ")"); return end
        S.k30.row = S.focusSay()
        S.k30.hold = S.word(e.promptHold, ww, e)
        if S.R and S.R.padMarkCount and S.R.padMarkCount(ww) > 0 and S.R.padClearMarks then pcall(S.R.padClearMarks, ww, e, true) end
        S.dryOn()
    end)
    S.tap("k30", "A", Joypad.AButton, function() return RT.ww() end, 650)
    Q.waitMs(300)
    Q.step(1, function()
        local d = S.dryOff()
        if S.off.k30 then return end
        local ww = RT.ww()
        local cnt = ww and ww._mainContent
        local marked = cnt ~= nil and type(cnt._selectedItems) == "table" and cnt._selectedItems[S.crate.apple] == true
        local acts = (d and d.acts) or {}
        Q.check(marked and #acts == 0, "#30 (a): on a pad, hold A on food in a crate marks it and eats nothing",
            "hold A on " .. tostring(S.k30.row) .. " (its hold word " .. tostring(S.k30.hold) .. "): the apple marked " .. tostring(marked)
            .. ", recorded " .. S.actWords(acts) .. " (old code: hold A on food eats it, wherever it is)")
        -- the marks wiped (the band's Take marked goes with them)
        if S.R and S.R.padClearMarks then pcall(S.R.padClearMarks, ww, nil) elseif cnt then cnt._selectedItems = {} end
    end)
end

-- ===================================================================== #30 (b), #34: the Character window's list
function S.charRow()
    return S.elIn(RT.cw(), "charMainInv", function(e) return e.item == S.k30.band end)
end
function S.pickChord()
    local QC = S.QC
    local pick = nil
    if QC and QC.CHORDS and QC.get then
        for _, c in ipairs(QC.CHORDS) do
            local ok, path = pcall(QC.get, c)
            if ok and path == "character:3" and pick == nil and S.BUMP[c:sub(1, 2)] and S.FACE[c:sub(4)] then pick = c end
        end
    end
    return pick or "LB+A"
end
function S.queueChar()
    Q.step(3, function()
        if S.dead then S.off.k30b = true; S.off.k34 = true; return end
        if not S.k30.band then S.fail("k30b", "the bandage could not be given"); S.fail("k34", "the bandage could not be given"); return end
        local cw = RT.cw()
        if not cw then S.fail("k30b", "the Character window is not open"); S.fail("k34", "the Character window is not open"); return end
        if S.rolled(cw) and S.F.showWin then pcall(S.F.showWin, cw) end
        if cw._activeTab ~= "loot" or cw._drawerOpen == true then S.clickTab(cw, cw._tabStripPanel, "loot") end
        S.F.claimFocus(cw)
    end)
    S.waitUntil(3000, function() return S.off.k34 or S.charRow() ~= nil end, function(ok)
        if S.off.k34 then return end
        if not ok then
            local why = "the bandage's row is not in the Character window's list (main shown " .. tostring(RT.cw() and RT.cw()._mainVisible) .. ")"
            S.fail("k30b", why)
            S.fail("k34", why)
            return
        end
        local cw = RT.cw()
        S.F.claimFocus(cw)
        local e = S.F.focusWhere(cw, "charMainInv", function(x) return x.item == S.k30.band end)
        local hold = e and S.word(e.promptHold, cw, e) or nil
        local xw = e and S.word(e.promptX, cw, e) or nil
        local want = getText("ContextMenu_Bandage")
        Q.check(e ~= nil and hold == want, "#30 (b): on a pad, in his own bags the footer names hold A's quick use (a bandage: Bandage)",
            "the pad on " .. S.focusSay() .. ": hold A reads " .. tostring(hold) .. " (want " .. tostring(want) .. "), X reads " .. tostring(xw)
            .. " (old code: hold A on a bandage reads Mark)")
        -- #34: the chord's bumper held, then its face button
        S.k34.chord = S.pickChord()
        S.k34.bump = S.BUMP[S.k34.chord:sub(1, 2)]
        S.k34.face = S.k34.chord:sub(4)
        local ww = RT.ww()
        S.k34.ct, S.k34.wt, S.k34.card = cw._activeTab, ww and ww._activeTab, cw._drawerItem
        S.k34.on = S.focusSay()
        S.QC.lastChord = nil
        S.dryOn()
        RT.pad(S.k34.bump.qa, true)
        S.held[S.k34.bump.qa] = true
        RT.padDown(Joypad[S.k34.bump.btn], cw)
    end)
    Q.step(2, function()
        if S.off.k34 then return end
        RT.pad(S.k34.face, true)
        S.held[S.k34.face] = true
        RT.padDown(Joypad[S.FACE[S.k34.face]], RT.cw())
    end)
    Q.waitMs(100)
    Q.step(1, function()
        if S.off.k34 then return end
        RT.pad(S.k34.face, false)
        RT.pad(S.k34.bump.qa, false)
    end)
    Q.step(4, function() S.letGo() end)
    Q.waitMs(500)
    Q.step(1, function()
        local d = S.dryOff()
        if S.off.k34 then return end
        local cw, ww = RT.cw(), RT.ww()
        local ct, wt = cw and cw._activeTab, ww and ww._activeTab
        local card = cw and cw._drawerItem
        Q.check(S.QC.lastChord == S.k34.chord and ct == S.k34.ct and wt == S.k34.wt and card == S.k34.card,
            "#34: in a window, a bumper held with a face button runs the quick action and turns no tab (" .. S.k34.chord .. ")",
            "the pad on " .. tostring(S.k34.on) .. "; the chord QuickChords ran: " .. tostring(S.QC.lastChord) .. "; the Character window on "
            .. tostring(ct) .. " (was " .. tostring(S.k34.ct) .. "), the World window on " .. tostring(wt) .. " (was " .. tostring(S.k34.wt)
            .. "); a card open on " .. S.itemName(card) .. " (was " .. S.itemName(S.k34.card) .. "); recorded " .. S.actWords(d and d.acts)
            .. " (old code: the face button works the row and the bumper's release turns a tab)")
    end)
end

-- ===================================================================== #26: the hint strip's first hours' line
function S.k26Run()
    local HS = S.HS
    local r = {}
    local P = JoypadState and JoypadState.players
    if not (HS and HS.teach and P) then r.none = true; return r end
    r.before = P[S.pn + 1]
    local fake = r.before == nil
    if fake then P[S.pn + 1] = {} end
    r.ok, r.err = pcall(function()
        r.t0 = HS.teach(S.pn)
        local u = HS.uses
        if type(u) == "table" then
            r.u, r.w0, r.c0 = u, u.teach_wheels, u.teach_chords
            r.set = true
            u.teach_wheels, u.teach_chords = 0, 0
        end
        r.t1 = HS.teach(S.pn)
    end)
    if r.set then r.u.teach_wheels, r.u.teach_chords = r.w0, r.c0 end
    if fake then P[S.pn + 1] = nil end
    r.after = P[S.pn + 1]
    return r
end
function S.teachWords(t)
    if type(t) ~= "table" then return "no line" end
    local w = {}
    for _, p in ipairs(t) do w[#w + 1] = tostring(p.glyph) .. " " .. tostring(p.label) end
    return table.concat(w, " | ")
end
function S.real(word, key)
    return type(word) == "string" and word ~= "" and word:sub(1, 6) ~= "UI_ZeD" and word == ZeD.tr(key)
end

-- ===================================================================== start
Q.step(5, function()
    local W, D, G, F, Det, St = S.W, S.D, S.G, S.F, S.Det, S.St
    local ready = S.p ~= nil and D ~= nil and D.open ~= nil and D.close ~= nil and D.state ~= nil and W ~= nil
        and G ~= nil and G.commit ~= nil and F ~= nil and F.claimFocus ~= nil and F.focusWhere ~= nil
        and F.getFocusedWindow ~= nil and F.getFocusedElement ~= nil and F.getFocusedZone ~= nil and F.qaButton ~= nil
        and F.dispatchJoypadDown ~= nil and F.dispatchJoypadDir ~= nil and F.releaseFocus ~= nil
        and Det ~= nil and Det.setLockedMode ~= nil and Det.getMode ~= nil and St ~= nil and St.lookStyleOption ~= nil and St.lite ~= nil
        and S.QC ~= nil and S.ST ~= nil and S.ST.nearby ~= nil and S.ST.current ~= nil and S.ST.unbind ~= nil and S.R ~= nil
        and ISDPadWheels ~= nil and getPlayerRadialMenu ~= nil and ISWorldMap ~= nil and ISTimedActionQueue ~= nil
        and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil and ZeD_WorldWindow.selectContainer ~= nil
        and Z.T ~= nil and Z.T.px ~= nil and Joypad ~= nil and IsoDirections ~= nil and JoypadState ~= nil
    if not ready then
        Q.check(false, "staging: ZeD's wheels, pad focus, input lock, chords, stations, lists and windows are loaded (nothing proven)")
        S.dead = true
        return
    end
    if D.gameWheels and D.gameWheels() then
        Q.check(false, "staging: ZeD draws the D-pad wheels here (nothing proven)", "the game's own wheels are up (safe mode, the Tutorial, or ZeD not drawn yet)")
        S.dead = true
        return
    end
    if S.p:isDead() or S.p:getVehicle() then
        Q.check(false, "staging: the character is alive and on foot (nothing proven)", "dead " .. tostring(S.p:isDead()) .. ", in a car " .. tostring(S.p:getVehicle() ~= nil))
        S.dead = true
        return
    end
    local char, world = S.charOpen(), S.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = char and S.geo(cw) or nil, w = world and S.geo(ww) or nil }
    S.was.tab = { c = (char and cw) and cw._activeTab or nil, w = (world and ww) and ww._activeTab or nil }
    local md = S.p:getModData()
    S.was.ws = { taken = md ~= nil, had = md ~= nil and md.ZeD_WinState ~= nil, v = md and S.copy(md.ZeD_WinState) or nil }
    S.was.mode = S.mode()
    S.lockWas = S.lockFound()
    S.was.style = S.optVal(St.lookStyleOption)
    S.was.speed = getGameSpeed and getGameSpeed() or 1
    S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.was.dir = S.p:getDir()
    S.was.health = S.health()
    S.was.queue = S.queueN()
    S.was.lastChord = S.QC.lastChord
    S.was.bound = S.ST.current(S.p)
    S.was.slot = JoypadState.players[S.pn + 1]
    S.was.taken = true
    S.was.char, S.was.world = char, world
    -- the hint strip's use counts held for the run (the run's wheels and chords spend none of them)
    if S.HS and S.HS.taught then
        S.was.taught = S.HS.taught
        S.noTaught = function() end
        S.HS.taught = S.noTaught
    end
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(Z.T.scale)
        .. "; Character window open " .. tostring(char) .. " (" .. S.gs(S.was.geo.c) .. ", on " .. tostring(S.was.tab.c)
        .. "), World window open " .. tostring(world) .. " (" .. S.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w)
        .. "); Input lock " .. tostring(S.lockWas) .. ", ZeD reads " .. tostring(S.was.mode) .. "; Style " .. tostring(S.was.style)
        .. " (1 Full, 2 Lite); game speed " .. tostring(S.was.speed) .. "; he at " .. S.where() .. "; a station bound "
        .. tostring(S.was.bound ~= nil) .. "; the prelude's car helpers " .. tostring(ZEDQA_CAR_SPAWN ~= nil)
        .. "; a pad in player 1's slot " .. tostring(JoypadState.players[S.pn + 1] ~= nil))
    if S.was.speed ~= 1 then S.speed(1) end
    if S.was.bound then pcall(S.ST.unbind, S.p) end
    S.toWheel()
    S.was.wsShut = md and S.copy(md.ZeD_WinState) or nil
    -- the bandage, hammer and knife on him; the crate he faces (an apple and a nail in it), a stove on another square
    -- when no station is in reach
    S.k30.band = RT.give("Base.Bandage")
    S.k21.hammer = RT.give("Base.Hammer")
    S.k21.knife = RT.give("Base.KitchenKnife")
    local sq, d = S.freeSq(nil)
    S.crate = sq and S.mkCrate(sq) or nil
    if not S.crate then S.fail("crate", "no free square beside him took a crate"); return end
    S.crate.dir = S.DIRNAME[d[1] .. "," .. d[2]]
    S.crate.apple = S.toCrate("Base.Apple")
    S.crate.nail = S.toCrate("Base.Nails")
    if not (S.crate.apple and S.crate.nail) then S.fail("crate", "the apple and the nail could not be put in the crate"); return end
    local near = nil
    pcall(function() near = S.ST.nearby(S.p, true) end)
    if not (near and near[1]) then
        local sq2 = S.freeSq(sq)
        S.stove = sq2 and S.mkStove(sq2) or nil
    end
    S.face()
    Q.say("staged: a crate to the " .. tostring(S.crate.dir) .. " (" .. S.itemName(S.crate.apple) .. ", " .. S.itemName(S.crate.nail)
        .. "); a station in reach before " .. tostring(near ~= nil and near[1] ~= nil) .. ", a stove built " .. tostring(S.stove ~= nil)
        .. "; given " .. S.itemName(S.k30.band) .. ", " .. S.itemName(S.k21.hammer) .. ", " .. S.itemName(S.k21.knife))
end)
Q.waitMs(800)

-- ===================================================================== #14 and #8, Style Lite (#43), then Full
S.queue14({ key = "k14L", style = 2, label = "#43 (Lite) #14" })
S.queue8({ key = "k8L", style = 2, label = "#43 (Lite) #8" })
S.queue14({ key = "k14F", style = 1, label = "#14" })
S.queue8({ key = "k8F", style = 1, label = "#8" })

-- ===================================================================== #18, #30, #34 on the open pair
S.queueC()
S.queueChar()

-- ===================================================================== #26: the hint strip
Q.step(3, function()
    if S.dead then return end
    S.letGo()
    S.toWheel()
end)
Q.waitMs(400)
Q.step(1, function()
    if S.dead then return end
    local m = S.St.hintStripMode and S.St.hintStripMode() or "always"
    if m == "off" then
        Q.skip("#26: the hint strip's first hours' line on a pad", "ZeD setup's hint strip is Off (the pick: Off aside)")
        return
    end
    local r = S.k26Run()
    local t = r.t1
    local ok = r.ok == true and type(t) == "table" and #t == 3 and t[1].glyph == "D-PAD" and t[2].glyph == "LB" and t[3].glyph == "RB"
        and S.real(t[1].label, "UI_ZeD_Hint_Wheels") and S.real(t[2].label, "UI_ZeD_Hint_Or") and S.real(t[3].label, "UI_ZeD_Hint_QuickActions")
    S.k26.slot = (r.none == true) or (r.after == r.before)
    Q.check(ok, "#26: for the first hours, on a pad, the hint strip adds the line D-pad Wheels, LB or RB + button Quick actions",
        (r.none and "the hint strip has no first hours' line (HintStrip.teach)" or ("the line, uses fresh: " .. S.teachWords(t)
        .. "; as the director's uses stand now: " .. S.teachWords(r.t0) .. "; uses kept " .. tostring(r.w0) .. " / " .. tostring(r.c0)
        .. (r.ok and "" or ("; ERR " .. tostring(r.err))))) .. "; the strip set to " .. tostring(m)
        .. " (old code: the strip shows only the game's prompts)")
end)

-- ===================================================================== #21: D-pad Left held, and tapped
Q.step(3, function()
    if S.dead then S.off.k21 = true; return end
    S.toWheel()
    local D = S.D
    if not (D.qaHeld and D.HOLD_WEAPONS_MS and D.holdTick) then
        Q.check(false, "#21: holding D-pad Left opens the Weapons ring at once, and a tap still opens the Character wheel",
            "this code has no hold rule (DpadWheels.qaHeld " .. tostring(D.qaHeld ~= nil) .. ", HOLD_WEAPONS_MS " .. tostring(D.HOLD_WEAPONS_MS)
            .. ", holdTick " .. tostring(D.holdTick ~= nil) .. "): holding D-pad Left opens the Character wheel (old code)")
        S.off.k21 = true
        return
    end
    local mode = S.G.modeOf and S.G.modeOf() or "tap"
    if mode == "hold" then
        Q.skip("#21: holding D-pad Left opens the Weapons ring at once", "the wheels' Hold setting is on (the pick leaves it as is)")
        S.off.k21 = true
        return
    end
    S.k21.mode = mode
    D.qaHeld[S.pn] = 50
    S.k21.set = true
    local ok, how = S.openWheel("left", "onDisplayLeft")
    if not ok then S.fail("k21", "D-pad Left did not open the Character wheel (" .. tostring(how) .. ")") end
end)
Q.step(3, function()
    if S.off.k21 then return end
    local st = S.wheelSt()
    S.k21.arm = st ~= nil and st.holdArm == true and #st.path == 1
    S.k21.ring0 = S.ringWords()
    S.D.qaHeld[S.pn] = S.D.HOLD_WEAPONS_MS + 100
end)
S.waitUntil(1500, function()
    if S.off.k21 then return true end
    local st = S.wheelSt()
    return st ~= nil and #st.path >= 2
end, function(ok)
    if S.off.k21 then return end
    local st = S.wheelSt()
    local we = nil
    for _, e in ipairs((st and st.path[1] and st.path[1].entries) or {}) do if e.sub == S.D.C.weapons then we = e end end
    S.k21.held = ok and we ~= nil and st.path[2].title == (we.crumb or we.name)
    S.k21.heldSay = "held: " .. tostring(st and #st.path) .. " level(s), on " .. tostring(st and st.path[#st.path] and st.path[#st.path].title)
        .. " (" .. S.ringWords() .. "); the Weapons slice " .. tostring(we and we.name) .. ", off " .. tostring(we and we.off)
    S.closeWheel()
    S.D.qaHeld[S.pn] = 50
    local okW, how = S.openWheel("left", "onDisplayLeft")
    if not okW then S.fail("k21", "D-pad Left did not open the Character wheel the second time (" .. tostring(how) .. ")") end
end)
Q.step(3, function() if not S.off.k21 then S.D.qaHeld[S.pn] = false end end)
Q.step(3, function() if not S.off.k21 then S.D.qaHeld[S.pn] = S.D.HOLD_WEAPONS_MS + 100 end end)
Q.waitMs(500)
Q.step(1, function()
    if S.off.k21 then return end
    local st = S.wheelSt()
    local tap = st ~= nil and #st.path == 1 and S.wheelUp()
    Q.check(S.k21.held == true and tap,
        "#21: holding D-pad Left opens the Weapons ring at once, and a tap still opens the Character wheel",
        tostring(S.k21.heldSay) .. "; the hold armed on open " .. tostring(S.k21.arm) .. " (the Character wheel: " .. tostring(S.k21.ring0)
        .. "); tapped: " .. tostring(st and #st.path) .. " level(s), " .. S.ringWords() .. "; the wheels open by " .. tostring(S.k21.mode)
        .. " (old code: no hold rule, holding opens the Character wheel)")
    S.closeWheel()
    S.D.qaHeld[S.pn] = nil
end)

-- ===================================================================== #15: Crafting by hand, the bench its own slice
Q.step(3, function()
    if S.dead then S.off.k15 = true; return end
    S.toWheel()
    local list = nil
    pcall(function() list = S.ST.nearby(S.p, true) end)
    S.k15.st = list and list[1] or nil
    if not S.k15.st then S.fail("k15", "no station in reach (the stove built " .. tostring(S.stove ~= nil) .. ")"); return end
    S.k15.name = tostring(S.k15.st.name)
    local ok, how = S.openWheel("right", "onDisplayRight")
    if not ok then S.fail("k15", "D-pad Right did not open the World wheel (" .. tostring(how) .. ")") end
end)
S.waitUntil(2500, function()
    if S.off.k15 then return true end
    return S.wheelUp() and S.sliceAt(ZeD.tr("UI_ZeD_Wheel_CraftBuild")) ~= nil
end, function(ok)
    if S.off.k15 then return end
    if not ok then S.fail("k15", "the World wheel is not up with its Craft and build slice: " .. S.ringWords()); return end
    S.commit(S.sliceAt(ZeD.tr("UI_ZeD_Wheel_CraftBuild")))
end)
S.waitUntil(2500, function()
    if S.off.k15 then return true end
    local st = S.wheelSt()
    return st ~= nil and #st.path >= 2 and S.wheelUp() and S.sliceAt(getText("IGUI_CraftingWindow_Title")) ~= nil
end, function(ok)
    if S.off.k15 then return end
    if not ok then S.fail("k15", "Craft and build did not open its ring: " .. S.ringWords()); return end
    local st = S.wheelSt()
    local list = st.path[#st.path].entries or {}
    local first, last = list[1], list[#list]
    local craft = getText("IGUI_CraftingWindow_Title")
    local words = {}
    for _, e in ipairs(list) do words[#words + 1] = tostring(e.name) .. (e.detail and (" [" .. tostring(e.detail) .. "]") or "") end
    Q.check(#list == 4 and first ~= nil and first.name == craft and first.detail == nil and last ~= nil and tostring(last.name) == S.k15.name,
        "#15 (a): the World wheel's Craft and build ring: Crafting names no station, and the nearest one has its own slice named for it",
        "the ring: " .. table.concat(words, ", ") .. "; the nearest station: " .. S.k15.name
        .. " (old code: three slices, Crafting reads the station's name and distance)")
    S.k15.ring = table.concat(words, ", ")
    S.commit(S.sliceAt(craft))
end)
S.waitUntil(3000, function()
    if S.off.k15 then return true end
    local ww = RT.ww()
    return S.worldOpen() and ww ~= nil and ww._activeTab == "craft"
end, function(ok)
    if S.off.k15 then return end
    local bound = S.ST.current(S.p)
    local ww = RT.ww()
    Q.check(ok and bound == nil, "#15 (b): the World wheel's Crafting opens the Craft tab by hand, not at the nearest station",
        "after Crafting: the World window open " .. tostring(S.worldOpen()) .. " on " .. tostring(ww and ww._activeTab) .. "; a station bound: "
        .. tostring(bound and bound.name) .. " (old code: Crafting binds the nearest station, " .. S.k15.name .. ")")
    if bound then pcall(S.ST.unbind, S.p) end
    S.toWheel()
end)

-- ===================================================================== #36: Map at once
Q.step(3, function()
    if S.dead then S.off.k36 = true; return end
    S.toWheel()
    local ok, how = S.openWheel("right", "onDisplayRight")
    if not ok then S.fail("k36", "D-pad Right did not open the World wheel (" .. tostring(how) .. ")") end
end)
S.waitUntil(2500, function()
    if S.off.k36 then return true end
    return S.wheelUp() and S.sliceAt(ZeD.tr("UI_ZeD_Wheel_Map")) ~= nil
end, function(ok)
    if S.off.k36 then return end
    if not ok then S.fail("k36", "the World wheel is not up with its Map slice: " .. S.ringWords()); return end
    local i = S.sliceAt(ZeD.tr("UI_ZeD_Wheel_Map"))
    local sl = S.slices()[i]
    local off = false
    if S.W.isOff then pcall(function() off = S.W.isOff(sl) and true or false end) end
    if off then
        Q.skip("#36: the World wheel's Map slice opens the map at once", "the Map slice is off here (no world map on this server or sandbox)")
        S.off.k36 = true
        S.closeWheel()
        return
    end
    -- the game's map toggle stood in for by a recorder for this one call (no map-reading action, no map)
    local calls = {}
    local real = ISWorldMap.ToggleWorldMap
    ISWorldMap.ToggleWorldMap = function(n) calls[#calls + 1] = n end
    S.commit(i)
    if ISWorldMap.ToggleWorldMap ~= real then ISWorldMap.ToggleWorldMap = real end
    S.k36.calls = calls
    S.k36.ring = S.ringWords()
end)
Q.step(3, function()
    if S.off.k36 then return end
    local st = S.wheelSt()
    local n = #(S.k36.calls or {})
    Q.check(n == 1 and S.k36.calls[1] == S.pn and st == nil and not S.vis(S.radial()),
        "#36: the World wheel's Map slice opens the map at once (the game's map toggle runs, no ring is left up)",
        "the map toggle ran " .. n .. " time(s) for player " .. tostring(S.k36.calls[1]) .. "; a wheel up after: " .. tostring(st ~= nil)
        .. (st and (" (" .. S.k36.ring .. ")") or "") .. " (old code: Map opens a ring of World map and Back)")
    S.closeWheel()
end)

-- ===================================================================== #20 on foot: Social
Q.step(3, function()
    if S.dead then S.off.k20 = true; return end
    S.toWheel()
    local ok, how = S.openWheel("up", "onDisplayUp")
    if not ok then S.fail("k20", "D-pad Up did not open a wheel on foot (" .. tostring(how) .. ")") end
end)
S.waitUntil(2500, function()
    if S.off.k20 then return true end
    return S.wheelUp() and #S.slices() > 0
end, function(ok)
    if S.off.k20 then return end
    local st = S.wheelSt()
    local top = st and st.path[1]
    S.k20.foot = ok and top ~= nil and top.fill == nil and #(top.entries or {}) > 0 and top.title == ZeD.tr("UI_ZeD_Wheel_Social")
    S.k20.footSay = "on foot: " .. tostring(top and top.title) .. " (" .. S.ringWords() .. ")"
    S.closeWheel()
end)

-- ===================================================================== #20 seated: the car's wheel (Full; then Lite, #43)
Q.step(10, function()
    if S.dead then S.off.k20c = true; return end
    S.toWheel()
    if S.p:getVehicle() then S.fail("k20c", "he sat in a car before the car leg"); return end
    if not S.carStart() then S.fail("k20c", "no car could be spawned: " .. tostring(S.carWhy)) end
end)
S.waitUntil(ZEDQA_CAR_WAIT and 45000 or 10000, function()
    if S.off.k20c then return true end
    if S.car then return S.carReady() end
    return not S.k5.waiting
end, function(ok)
    if S.off.k20c then return end
    if not (ok and S.car) then
        S.k5.gaveUp = true
        S.fail("k20c", "no car was ready to sit in (" .. (S.car and "its physics never woke" or tostring(S.carWhy or "the prelude's wait gave none")) .. ")")
        S.carAway()
        return
    end
    pcall(function() S.car.scriptName = tostring(S.car.v:getScriptName()) end)
    S.carPrep()
    local okIn, why = S.carIn()
    if not okIn then S.fail("k20c", "he could not be seated at the wheel: " .. tostring(why)); S.carAway() end
end)
S.waitUntil(3000, function()
    if S.off.k20c then return true end
    return S.p:getVehicle() == S.car.v
end, function(ok)
    if S.off.k20c then return end
    if not ok then S.fail("k20c", "he is not in the car") return end
    Q.say("#20: seated in " .. tostring(S.car.scriptName) .. " by " .. tostring(S.car.how))
end)
for _, L in ipairs({ { style = 1, label = "#20" }, { style = 2, label = "#43 (Lite) #20" } }) do
    Q.step(3, function()
        if S.off.k20c then return end
        S.style(L.style)
        S.toWheel()
    end)
    Q.waitMs(500)
    Q.step(1, function()
        if S.off.k20c then return end
        L.style0 = S.styleWord()
        local ok, how = S.openWheel("up", "onDisplayUp")
        if not ok then L.why = "D-pad Up opened no wheel seated (" .. tostring(how) .. ")" end
    end)
    S.waitUntil(2500, function()
        if S.off.k20c then return true end
        return S.wheelUp() and #S.slices() > 0
    end, function(ok)
        if S.off.k20c then return end
        local st = S.wheelSt()
        local top = st and st.path[1]
        local car = ok and top ~= nil and top.fill ~= nil and top.fill == S.D.vehicleFill
        local foot = true
        if L.style == 1 then foot = S.k20.foot == true end
        Q.check(car and foot, L.label .. ": seated, D-pad Up opens the car's wheel at once; on foot it stays Social (Style " .. tostring(L.style0) .. ")",
            "seated: " .. tostring(top and top.title) .. ", filled by the game's vehicle wheel " .. tostring(top ~= nil and top.fill ~= nil and top.fill == S.D.vehicleFill)
            .. " (" .. S.ringWords() .. ")" .. (L.why and ("; " .. L.why) or "") .. ((L.style == 1) and ("; " .. tostring(S.k20.footSay)) or "")
            .. " (old code: Social in the car too)")
        S.closeWheel()
    end)
end
Q.step(3, function()
    S.closeWheel()
    S.release()
    S.style(1)
    S.carAway()
end)
S.waitUntil(6000, function() return S.carGone() end, function(ok)
    if S.car and not ok then Q.check(false, "put back: the #20 car is taken away", "still in the cell; he in a car " .. tostring(S.p:getVehicle() ~= nil)) end
    S.homeBack()
end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    S.k5.gaveUp = true   -- (a car the prelude's wait brings after this is taken away at once)
    S.letGo()
    for _, b in ipairs({ "A", "B", "X", "Y", "LeftBump", "RightBump" }) do RT.pad(b, nil) end
    S.dryOff()
    if S.D and S.D.qaHeld then S.D.qaHeld[S.pn] = nil end
    S.closeWheel()
    S.closeMenu()
    local ww = RT.ww()
    if ww and S.R and S.R.padClearMarks then pcall(S.R.padClearMarks, ww, nil, true) end
    if S.ST and S.ST.current and S.ST.current(S.p) ~= nil then pcall(S.ST.unbind, S.p) end
    S.carAway()
    S.release()
end)
S.waitUntil(6000, function() return S.carGone() end, function(ok)
    S.carGoneOk = ok
    S.homeBack()
    if S.was.dir then pcall(function() S.p:setDir(S.was.dir) end) end
    S.crateBack()
    RT.takeBack()   -- (the bandage, the hammer, the knife)
    S.queueBack()
    if S.was.taken then
        S.style(S.was.style)
        if S.QC then S.QC.lastChord = S.was.lastChord end
        if S.was.bound and S.ST.bind then pcall(S.ST.bind, S.p, S.was.bound) end
    end
    if S.HS and S.noTaught and S.HS.taught == S.noTaught then S.HS.taught = S.was.taught end
    if ZeD_WorldWindow and type(ZeD_WorldWindow._padYLeft) == "table" then ZeD_WorldWindow._padYLeft[S.pn] = nil end
    S.release()
    S.modeBack()
end)
Q.waitMs(400)
Q.step(1, function()
    S.modeFree()
    if S.was.char == nil then return end
    S.layoutBack(true)
    S.windowsBack()
end)
S.waitUntil(5000, function()
    if S.was.char == nil then return true end
    return S.charOpen() == S.was.char and S.worldOpen() == S.was.world
end, function()
    if S.was.char == nil then return end
    S.layoutBack(false)
    local cw, ww = RT.cw(), RT.ww()
    if S.was.char and cw and S.was.tab.c and cw._activeTab ~= S.was.tab.c then S.clickTab(cw, cw._tabStripPanel, S.was.tab.c) end
    if S.was.world and ww and S.was.tab.w and ww._activeTab ~= S.was.tab.w then RT.worldTab(S.was.tab.w) end
    S.restSig = nil
end)
S.waitUntil(3000, function()
    if S.was.char == nil then return true end
    return S.settled()
end, function()
    if S.was.char == nil then return end
    local moved = {}
    if S.was.char and S.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and S.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
end)
Q.step(10, function()
    if not S.was.taken then return end
    if getGameSpeed and getGameSpeed() ~= S.was.speed then S.speed(S.was.speed) end
    -- the stand-ins
    local d = S.dry
    S.putBack(d == nil and not S.dryStuck and ISTimedActionQueue.add ~= nil and (S.HS == nil or S.HS.taught ~= S.noTaught or S.noTaught == nil)
        and (S.D.qaHeld == nil or S.D.qaHeld[S.pn] == nil)
        and S.k26.slot ~= false and JoypadState.players[S.pn + 1] == S.was.slot,
        "the recorder, the hint strip's use counter, the wheel's held D-pad and player 1's pad slot let go",
        "recorder on " .. tostring(d ~= nil) .. ", stuck " .. tostring(S.dryStuck) .. "; the pad slot as found "
        .. tostring(JoypadState.players[S.pn + 1] == S.was.slot) .. " (the #26 call left it as found " .. tostring(S.k26.slot) .. "); HintStrip.taught as found "
        .. tostring(S.HS == nil or S.HS.taught == S.was.taught) .. "; DpadWheels.qaHeld cleared " .. tostring(S.D.qaHeld == nil or S.D.qaHeld[S.pn] == nil))
    -- the wheel and the menus
    local v = getPlayerContextMenu and getPlayerContextMenu(S.pn) or nil
    S.putBack(S.wheelSt() == nil and not S.vis(S.radial()) and not (v and v._zedMenu), "no D-pad wheel and no right-click menu up",
        "ZeD's wheel state " .. tostring(S.wheelSt() ~= nil) .. ", the shared wheel on screen " .. tostring(S.vis(S.radial())))
    -- Style, the chord, the station
    local style = S.optVal(S.St.lookStyleOption)
    local bound = S.ST.current(S.p)
    S.putBack(style == S.was.style and S.QC.lastChord == S.was.lastChord and ((bound == nil) == (S.was.bound == nil)),
        "the Style value, QuickChords' last chord and the station binding as found",
        "Style " .. tostring(style) .. " (found " .. tostring(S.was.style) .. "), last chord " .. tostring(S.QC.lastChord) .. " (found "
        .. tostring(S.was.lastChord) .. "), a station bound " .. tostring(bound ~= nil) .. " (found " .. tostring(S.was.bound ~= nil) .. ")")
    -- the crate, the stove, the things given, the car, him
    local crateUp = S.crate ~= nil and S.standing(S.crate.obj)
    local stoveUp = S.stove ~= nil and S.standing(S.stove)
    local onHim = S.mine(S.k30.band) or S.mine(S.k21.hammer) or S.mine(S.k21.knife) or S.mine(S.crate and S.crate.apple)
        or S.mine(S.crate and S.crate.nail) or S.mine(S.car and S.car.key)
    local carLeft = S.car ~= nil and S.carLive(S.car.v)
    local h = S.health()
    local dx, dy = S.p:getX() - S.was.pos.x, S.p:getY() - S.was.pos.y
    local home = dx * dx + dy * dy <= 2.25 and math.floor(S.p:getZ()) == math.floor(S.was.pos.z)
    S.putBack(not crateUp and not stoveUp and not onHim and not carLeft and S.p:getVehicle() == nil and not S.p:isDead() and home
        and (S.was.health == nil or h == nil or h >= S.was.health - 1),
        "the crate and the stove gone, nothing given left on him, the car gone, he on foot where he was found, alive and unhurt",
        "the crate standing " .. tostring(crateUp) .. ", the stove " .. tostring(stoveUp) .. ", a given thing on him " .. tostring(onHim)
        .. ", the car in the cell " .. tostring(carLeft) .. ", in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", at " .. S.where()
        .. (S.movedFrom and ("; moved back from " .. S.movedFrom) or "") .. ", health " .. S.num(h) .. " (found " .. S.num(S.was.health)
        .. "), dead " .. tostring(S.p:isDead()))
    -- no timed action the run queued
    S.putBack(S.queued == nil and S.leaked == nil and S.queueN() <= (S.was.queue or 0), "no timed action left by the run",
        "queued now " .. tostring(S.queueN()) .. " (found " .. tostring(S.was.queue) .. ")" .. (S.queued and ("; " .. S.queued .. " the run queued, cleared") or "")
        .. (S.leaked and ("; " .. S.leaked .. " reached the queue during a recording, cleared") or ""))
    -- the input lock and the mode ZeD reads
    if S.lockWas ~= nil and S.was.mode ~= nil then
        local now, mode = S.lockFound(), S.mode()
        local unknown = S.was.mode == "unknown" and mode == "kbm"
        S.putBack(now == S.lockWas and (mode == S.was.mode or unknown) and S.modeHeld == nil, "the input lock as found, and the mode ZeD reads",
            "ZeD setup's Input lock " .. tostring(now) .. " (found " .. tostring(S.lockWas) .. "); ZeD reads " .. tostring(mode)
            .. " (found " .. tostring(S.was.mode) .. ")" .. (unknown and "; found unknown, which ZeD reads as the mouse" or ""))
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
    local sp = getGameSpeed and getGameSpeed() or nil
    S.putBack(sp == S.was.speed, "the game speed as found", "speed " .. tostring(sp) .. " (found " .. tostring(S.was.speed) .. ")")
end)
Q.start()
