-- ZeDUI/tools/qa/vx12_wheel.lua  (Nov 22 2026, QA batch 12; tag vx12_whl): the in-game proof of Build's fix for B12-1,
-- the controller wheels' balloon (commit 263f79200: ZeD.Balloon.draw skips the tail when opts.noTail is set; the
-- strip's balloon, ZeD.Molecules.drawContextBalloon, passes state.noTail on and, with no anchor, centers the box on the
-- ring: a.x = x0 + centerX - floor(Balloon.layout(c).w / 2) + T.px(Balloon.INSET) - 1; ZeD_Wheel's W.draw sets
-- state.noTail = true). Finding: ZeDUI/qa/audits/2026-11-21_beast_batch12.md. Built on rt_kit.lua (the global RT), run
-- after zedqa_prelude.lua. grep "ZEDQA vx12_whl". Manifest vx12.txt: vx12_wheel.lua | vx12_whl | timeout=240
--
-- The finding: on every ZeD wheel the balloon above the ring named the lit slice, but its tail dropped onto the
-- 12 o'clock slice whichever slice was lit, and its box hung right of the ring (its left edge 6u left of the ring's
-- center): W.draw places the balloon from the ring's apex, and beta 10's Balloon Help gave every balloon a tail on its
-- control. The approved wheel look is a caption centered over the ring, with no tail.
--
-- What it checks, on two of ZeD's wheels (D-pad Down, Here and now; D-pad Left, Character), each with three slices
-- pointed in turn: slice 1 (12 o'clock, for contrast), slice 2 and the slice nearest 6 o'clock. For one drawn frame
-- of each it records what the wheel's balloon draws, through three pass-through wrappers put on for the run:
-- ZeD.Molecules.drawContextBalloon (the ring's center x the wheel hands it, and the slice pointed while it draws),
-- ZeD.Balloon.draw (its opts.noTail, and the box it returns: x and width in the wheel's own pixels) and
-- ZeD.Balloon.tailOrigin (the tail's drawing asks it where the tail goes: a call while the wheel's balloon draws is a
-- tail drawn). Each wrapper records only while the wheel's own balloon draws; every other balloon passes through.
--   (a) the balloon draws no tail: the tail's drawing does not run in that frame (opts.noTail said beside it)
--   (b) the box is centered on the ring's center x within 2 px, at whatever scale the run is at; and per wheel, the
--       box's middle is the same for every pointed slice within 2 px (it keeps one place, it does not chase the slice)
--   (c) the balloon still names the pointed slice: the slice's name (its text's first line, which the wheel makes the
--       balloon's title) is in the balloon's words (its title, lines and reason row), as bxr_menus.lua reads it
-- On the old code (263f79200~1) every (a) FAILS (a tail drawn every frame, its tip on the ring's apex over the
-- 12 o'clock slice; opts.noTail nil) and every (b) centering check FAILS (the box's left edge 6u left of the ring's
-- center, its middle half its width less 6u right of it); each wheel's one-place check FAILS when the pointed slices'
-- balloons differ in width (the old box kept its left edge, not its middle); (c) and the put-back PASS. On the fix
-- every check PASSES. Nothing in pixels is written in but the 2 px tolerance: it runs as it is at 4K (UI scale 1.75)
-- and 1280x800 (Auto).
-- Run offline before the first game run (Nov 22 2026: KRun, rt_kit.lua and this script in the game's Kahlua with the
-- real Balloon.lua, ZeD_Wheel.lua and drawContextBalloon of 263f79200 and of 263f79200~1, a stubbed D-pad wheel and
-- windows; the harness is not in the repo).
--
-- How it stages, as bxr_menus.lua stages B7-3 (no controller is plugged in): ZeD's input mode locked to the
-- controller (S.lock("gamepad")), then S.toWheel (no wheel or menu up, the pad let go, the pair shut; again a second
-- later, as the switch to the controller opens the pair a frame after the lock), the wheel opened by the game's own
-- opener (S.openWheel: ISDPadWheels.onDisplayDown / onDisplayLeft, ZeD.DpadWheels.open only if that did not open it),
-- a slice pointed with ZeD.Wheel.qaPoint = k, and its frame read once the wheel is on screen with that slice pointed
-- (S.wheelDrawn(k)) and has drawn its balloon for it; S.closeWheel after each wheel, S.lock(false) in the put-back.
-- What it puts back (also when a step throws or the time runs out): the wheel closed, ZeD.Wheel.qaPoint as found,
-- the three wrappers taken off (checked), the input lock as found (ZeD setup's Input lock, as Settings.lua applies
-- it) and, with no lock found, the mode ZeD read (InputModeDetector's tick copies a lock into its own mode, and only
-- a click, a key or a pad switches it back: so a moment's lock on the mode found, for the tick to take, then none),
-- the Character and World windows open or shut as found, where and as big as they were, on the tabs they were on
-- (a window found open opens on the layout it saved when the test first shut it; one found shut keeps the layout it
-- had: md.ZeD_WinState.char / .world). No option is changed, nothing is applied or saved, no file is written,
-- ZEDQA_LAYOUT_BACK is never called.
-- (Nov 22 2026, review: the put-back left ZeD reading "gamepad" after the lock was lifted, so its own lock check failed
-- on the fix too; and the windows reopened on the layout saved after the controller's open, not the one found. The
-- offline run now follows InputModeDetector's tick, and a controller's open that moves a window and changes its tab.)

if not (RT and RT.make) then
    print("ZEDQA vx12_whl ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx12_whl VERDICT FAIL 1")
    print("ZEDQA vx12_whl DONE")
    return
end

local Q = RT.make("vx12_whl")
Q.maxMs = 180000   -- (three minutes, then the put-back; a run takes well under one)
local Z = ZeD or {}
local D, W, Bn, M = Z.DpadWheels, Z.Wheel, Z.Balloon, Z.Molecules
local S = { p = RT.p, pn = RT.pn, was = { geo = {}, tab = {} }, orig = {}, wrap = {}, rec = { n = 0 }, TOL = 2 }
S.Det = Z.Input and Z.Input.Detector
S.Focus = Z.Input and Z.Input.Focus
S.WHEELS = {
    { dir = "down", fn = "onDisplayDown", name = "D-pad Down (Here and now)", mids = {}, lefts = {}, cxs = {}, done = {} },
    { dir = "left", fn = "onDisplayLeft", name = "D-pad Left (Character)", mids = {}, lefts = {}, cxs = {}, done = {} },
}

-- ===================================================================== words and numbers
-- (every reading asks before it indexes: in -debug a throw caught by pcall still logs a Java exception, and the runner
-- counts it)
function S.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
-- the slice's name: its text's first line, trimmed (W.draw makes it the balloon's title)
function S.firstLine(text)
    for l in tostring(text or ""):gmatch("[^\n]+") do
        local t = l:gsub("^%s+", ""):gsub("%s+$", "")
        if t ~= "" then return t end
    end
    return ""
end
-- the balloon's words: its title, its lines and its reason row (a slice that is off puts its reason there)
function S.words(c)
    if type(c) ~= "table" then return "" end
    local out = { tostring(c.title or "") }
    if type(c.lines) == "table" then
        for _, l in ipairs(c.lines) do
            if type(l) == "table" then out[#out + 1] = tostring(l.text or "") else out[#out + 1] = tostring(l) end
        end
    end
    local rq = (type(c.req) == "table") and c.req or nil
    if rq and type(rq.conds) == "table" then
        for _, k in ipairs(rq.conds) do if type(k) == "table" then out[#out + 1] = tostring(k.t or "") end end
    end
    return table.concat(out, " / ")
end
-- where slice i of n sits on the ring (slice 1 at 12 o'clock, the rest clockwise: ZeD_Wheel's geometry)
function S.clock(i, n)
    local h = math.floor((i - 1) * 12 / math.max(n or 2, 2) + 0.5)
    if h <= 0 then h = 12 end
    return h .. " o'clock"
end
function S.list(t)
    local out = {}
    for _, v in ipairs(t or {}) do out[#out + 1] = S.num(v) end
    return table.concat(out, ", ")
end

-- ===================================================================== the windows
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
-- the pair shut (hfr_common.lua's S.closePair; a pause closes only the Character window, so anything left is shut too)
function S.closePair()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.charOpen() and S.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
-- the windows open or shut as found (the pair by the inventory key's own toggle; then each on its own, as a pause
-- opens only the Character window; the shuts last, so an open that brings its partner is undone too)
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
-- the windows found open get the layout they saved when the test first shut them (before the controller's open and
-- shut wrote theirs), so they open on it; open false: the windows found shut get the layout they had
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
-- the windows at rest: the same places and sizes for 300 ms (a reopened window's drawer slides open over a few frames,
-- DRAWER_PX_SPEED; read or set back halfway, it would be measured or moved mid-slide)
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

-- ===================================================================== the input mode ZeD reads (bxr_menus.lua)
-- the lock as found: ZeD setup's Input lock, as Settings.lua applies it at load ("auto" is no lock); the save's
-- modData copy only when the setting cannot be read (it is written on a change, so it can be stale)
function S.lockFound()
    local key = nil
    local api = PZAPI and PZAPI.ModOptions
    local zo = (api and api.getOptions) and api:getOptions("ZeD_UI") or nil
    local o = zo and zo.dict and zo.dict.inputModeLock
    local keys = Z.Settings and Z.Settings.inputLockKeys
    if o and o.getValue and keys then key = keys[o:getValue() or 1] end
    if key == nil and S.p then
        local md = S.p:getModData()
        local g = md and md.ZeD_Gamepad
        key = g and g.inputModeLock
    end
    return key or "auto"
end
function S.mode() return (S.Det and S.Det.getMode) and S.Det.getMode(S.pn) or nil end
-- mode "gamepad" (the wheels); nil or false puts back the lock found (only a lock this script set)
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
-- the lock this script set lifted, and with no lock found the mode ZeD read: the detector's tick (OnTick) copied the
-- lock into its own mode, and with the lock gone only a click, a key or a pad switches it, so ZeD read "gamepad" on.
-- A moment's lock on the mode found lets the tick take it (its switch waits 200 ms after the last, which was the lock
-- at the start); S.modeFree lifts it. A found "unknown" (no input since the game started) has no way back: the mouse,
-- which ZeD reads it as (only "gamepad" is the controller anywhere in ZeD).
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

-- ===================================================================== the wheels (bxr_menus.lua)
function S.wheelSt() return (D and D.state) and D.state[S.pn] or nil end
function S.radial() return getPlayerRadialMenu and getPlayerRadialMenu(S.pn) or nil end
-- (a wheel never built has no element: it is not on screen, and asking would build one)
function S.vis(m)
    if not (m and m.javaObject ~= nil and m.isReallyVisible) then return false end
    return m:isReallyVisible() and true or false
end
function S.closeWheel()
    if W then W.qaPoint = nil end
    if not D then return end
    if S.wheelSt() and D.close then pcall(D.close, S.pn) end
    local st = S.wheelSt()
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    if D.state then D.state[S.pn] = nil end
    local m = S.radial()
    if m and m.undisplay and S.vis(m) then pcall(m.undisplay, m) end
end
-- a ZeD right-click menu, or the game's, closed (none is up in a run; bxr_menus.lua's S.closeMenu)
function S.closeMenu()
    local v = getPlayerContextMenu and getPlayerContextMenu(S.pn) or nil
    if not v then return end
    local zm = v._zedMenu
    if zm and zm.close then pcall(zm.close, zm) end
    if not v._zedMenu and v.javaObject ~= nil and v.closeAll and v:isVisible() then pcall(v.closeAll, v) end
end
function S.release()
    if S.Focus and S.Focus.releaseFocus then pcall(S.Focus.releaseFocus, S.pn) end
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
-- the wheel opened the way the game opens it; ZeD.DpadWheels.open only when that did not
function S.openWheel(dir, fn)
    if ISDPadWheels and ISDPadWheels[fn] then pcall(ISDPadWheels[fn], { player = S.pn, id = nil }) end
    local st = S.wheelSt()
    if st and st.dir == dir then return true, "the game's opener, ISDPadWheels." .. fn end
    local ok, e = pcall(D.open, dir, { player = S.pn, id = nil })
    if not ok then Q.say("ERR open " .. dir .. ": " .. tostring(e)) end
    st = S.wheelSt()
    return st ~= nil and st.dir == dir, "ZeD.DpadWheels.open (the game's opener left it shut)"
end
-- the wheel is on screen with slice i pointed (ZeD_Wheel's update has run on it)
function S.wheelDrawn(i)
    local st = S.wheelSt()
    local m = st and st.menu
    return m ~= nil and S.vis(m) and m._zedPoint == i
end
-- the slices to point: 1 (12 o'clock), 2, and the one nearest 6 o'clock; an empty place is passed over
function S.pickSlices(slices)
    local n = #slices
    local out, seen = {}, {}
    local function add(k)
        for d = 0, n - 1 do
            local j = k - 1 + d
            local i = j - math.floor(j / n) * n + 1
            if not seen[i] and not W.isPlace(slices[i]) then
                seen[i] = true
                out[#out + 1] = i
                return
            end
        end
    end
    add(1)
    add(2)
    add(math.floor(n / 2) + 1)
    return out
end

-- ===================================================================== the wrappers (one drawn frame, read)
-- R.menu: the wheel whose balloon is read; R.want: the slice it waits for; R.got: the first frame drawn with it
-- pointed and a box drawn. Each wrapper calls ZeD's own function with what it was given and returns all it returns.
function S.hook()
    if S.hooked then return end
    S.orig.ctx, S.orig.draw, S.orig.tail = M.drawContextBalloon, Bn.draw, Bn.tailOrigin
    S.wrap.ctx = function(panel, centerX, apexY, state, T, ...)
        local R = S.rec
        R.cur, R.tailTo = nil, nil
        if R.menu == nil or panel ~= R.menu then return S.orig.ctx(panel, centerX, apexY, state, T, ...) end
        local r = { cx = centerX, point = panel._zedPoint, ox = panel:getAbsoluteX(), tails = 0, drew = false }
        if type(state) == "table" then r.stNoTail, r.label = state.noTail, state.labelText end
        R.cur = r
        local w, h, x, y = S.orig.ctx(panel, centerX, apexY, state, T, ...)
        R.cur, R.tailTo = nil, nil
        R.n = R.n + 1
        r.n = R.n
        if r.drew and r.bx ~= nil then R.lastPoint = r.point end
        if R.want ~= nil and R.got == nil and r.point == R.want and r.drew and r.bx ~= nil and r.bw ~= nil then R.got = r end
        return w, h, x, y
    end
    S.wrap.draw = function(p, c, a, pref, opts, ...)
        local R = S.rec
        local r = R.cur
        if r == nil or R.menu == nil or p ~= R.menu then return S.orig.draw(p, c, a, pref, opts, ...) end
        R.cur = nil
        r.drew = true
        r.c = c
        if type(opts) == "table" then r.noTail = opts.noTail end
        if type(a) == "table" then r.ax = a.x end
        R.tailTo = r
        local x, y, w, h = S.orig.draw(p, c, a, pref, opts, ...)
        R.tailTo = nil
        r.bx, r.by, r.bw, r.bh = x, y, w, h
        return x, y, w, h
    end
    S.wrap.tail = function(box, pl, bwCells, ...)
        local r = S.rec.tailTo
        if r ~= nil then r.tails = r.tails + 1 end
        return S.orig.tail(box, pl, bwCells, ...)
    end
    M.drawContextBalloon, Bn.draw, Bn.tailOrigin = S.wrap.ctx, S.wrap.draw, S.wrap.tail
    S.hooked, S.hookedEver = true, true
end
-- taken off; false when another hand wrapped one of them since (then it is left, and said)
function S.unhook()
    S.rec.menu, S.rec.cur, S.rec.tailTo, S.rec.want, S.rec.got = nil, nil, nil, nil, nil
    if not S.hooked then return true end
    local ok = true
    if M.drawContextBalloon == S.wrap.ctx then M.drawContextBalloon = S.orig.ctx else ok = false end
    if Bn.draw == S.wrap.draw then Bn.draw = S.orig.draw else ok = false end
    if Bn.tailOrigin == S.wrap.tail then Bn.tailOrigin = S.orig.tail else ok = false end
    S.hooked = false
    return ok
end

-- ===================================================================== waits
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

-- ===================================================================== the checks for one pointed slice
function S.judge(wh, k, ok)
    local r = S.rec.got
    local m = wh.menu
    local sl = (m and m.slices) and m.slices[k] or nil
    local name = S.firstLine(sl and sl.text)
    local where = wh.name .. ", slice " .. k .. " of " .. tostring(wh.n) .. " (" .. S.clock(k, wh.n) .. ", \"" .. name .. "\") pointed"
    local how = "none in 6 s"
    if r ~= nil then how = "drawn in frame " .. tostring(r.n) .. " of the wheel's balloon draws" end
    if not (ok and r ~= nil) then
        how = how .. "; the wheel on screen with it pointed when read " .. tostring(S.wheelDrawn(k)) .. ", the last balloon drawn for slice "
            .. tostring(S.rec.lastPoint)
    end
    if not Q.check(ok and r ~= nil, where .. ": the wheel draws its balloon in a frame with that slice pointed", how) then return end
    wh.done[#wh.done + 1] = k
    -- (a) no tail
    Q.check(r.tails == 0, where .. ": (a) the balloon draws no tail",
        "the tail's drawing (Balloon.tailOrigin) ran " .. r.tails .. " time(s) in that frame; Balloon.draw had opts.noTail "
        .. tostring(r.noTail) .. " (the wheel's state.noTail " .. tostring(r.stNoTail) .. ")"
        .. ((r.tails > 0) and "; a tail from the ring's apex, over the 12 o'clock slice, whichever slice is lit" or ""))
    -- (b) centered on the ring
    local mid = r.bx + r.bw / 2
    local off = mid - r.cx
    wh.mids[#wh.mids + 1] = mid
    wh.lefts[#wh.lefts + 1] = r.bx
    wh.cxs[#wh.cxs + 1] = r.cx
    Q.check(math.abs(off) <= S.TOL, where .. ": (b) the box is centered on the ring's center x (within " .. S.TOL .. " px)",
        "box x " .. S.num(r.bx) .. ", w " .. S.num(r.bw) .. " in the wheel's pixels (on screen " .. S.num(r.ox + r.bx) .. " to " .. S.num(r.ox + r.bx + r.bw)
        .. "), its middle " .. S.num(mid) .. "; the ring's center " .. S.num(r.cx) .. " (on screen " .. S.num(r.ox + r.cx) .. "): off by " .. S.num(off)
        .. " px; its left edge " .. S.num(r.cx - r.bx) .. " px left of the ring's center (half the box is " .. S.num(r.bw / 2)
        .. " px; the old code's 6u is " .. S.num(S.six) .. " px); the anchor's x " .. S.num(r.ax))
    -- (c) the words name the pointed slice
    local words = S.words(r.c)
    Q.check(name ~= "" and words:find(name, 1, true) ~= nil, where .. ": (c) the balloon names the pointed slice",
        "the slice's name \"" .. name .. "\"; the balloon reads \"" .. words .. "\"")
end

-- the box keeps one place whichever slice is pointed
function S.oneSpot(wh)
    if #wh.mids < 2 then return end
    local lo, hi, llo, lhi = wh.mids[1], wh.mids[1], wh.lefts[1], wh.lefts[1]
    for _, v in ipairs(wh.mids) do
        if v < lo then lo = v end
        if v > hi then hi = v end
    end
    for _, v in ipairs(wh.lefts) do
        if v < llo then llo = v end
        if v > lhi then lhi = v end
    end
    Q.check(hi - lo <= S.TOL, wh.name .. ": (b) the box keeps one place whichever slice is pointed (it does not chase the slice)",
        "its middle " .. S.list(wh.mids) .. " for slices " .. S.list(wh.done) .. " (spread " .. S.num(hi - lo) .. " px); the ring's center "
        .. S.list(wh.cxs) .. "; its left edge " .. S.list(wh.lefts) .. " (spread " .. S.num(lhi - llo) .. " px)")
end

-- ===================================================================== one wheel, three slices
function S.queueSlice(wh, j)
    local function k() return ((not wh.off) and wh.ks) and wh.ks[j] or nil end
    Q.step(3, function()
        if not k() then return end
        S.rec.want, S.rec.got = k(), nil
        W.qaPoint = k()
    end)
    S.waitUntil(6000, function()
        if not k() then return true end
        return S.rec.got ~= nil and S.wheelDrawn(k())
    end, function(ok)
        if not k() then return end
        S.judge(wh, k(), ok)
    end)
end
function S.queueWheel(wh)
    Q.step(10, function()
        if S.dead then wh.off = true; return end
        -- (again: the switch to the controller opens the pair, and can hand the pad to a window, a frame after the lock)
        S.toWheel()
    end)
    Q.step(10, function()
        if wh.off then return end
        S.toWheel()
        local ok, how = S.openWheel(wh.dir, wh.fn)
        local st = S.wheelSt()
        local m = st and st.menu
        local n = (m and m.slices) and #m.slices or 0
        if not Q.check(ok and n >= 2, wh.name .. ": the wheel opens with its slices", "opened " .. tostring(ok) .. " by " .. tostring(how)
            .. ", " .. n .. " slices; ZeD reads " .. tostring(S.mode())) then
            wh.off = true
            return
        end
        wh.menu, wh.n = m, n
        wh.ks = S.pickSlices(m.slices)
        S.rec.menu, S.rec.want, S.rec.got = m, nil, nil
        S.hook()
        local names = {}
        for _, i in ipairs(wh.ks) do names[#names + 1] = i .. " \"" .. S.firstLine(m.slices[i] and m.slices[i].text) .. "\"" end
        Q.say(wh.name .. " open by " .. tostring(how) .. ": " .. n .. " slices, at " .. S.num(m:getAbsoluteX()) .. "," .. S.num(m:getAbsoluteY())
            .. " " .. S.num(m:getWidth()) .. "x" .. S.num(m:getHeight()) .. "; ZeD reads " .. tostring(S.mode()) .. "; pointing " .. table.concat(names, ", "))
    end)
    for j = 1, 3 do S.queueSlice(wh, j) end
    Q.step(3, function()
        if not wh.off then S.oneSpot(wh) end
        S.rec.menu, S.rec.want, S.rec.got = nil, nil, nil
        S.closeWheel()
    end)
end

-- ===================================================================== start
Q.step(5, function()
    S.was.qaPoint = W and W.qaPoint or nil
    local ready = D ~= nil and D.open ~= nil and D.close ~= nil and D.state ~= nil and W ~= nil and W.isPlace ~= nil
        and Bn ~= nil and Bn.draw ~= nil and Bn.tailOrigin ~= nil and Bn.INSET ~= nil and M ~= nil and M.drawContextBalloon ~= nil
        and S.Det ~= nil and S.Det.setLockedMode ~= nil and S.Det.getMode ~= nil and ISDPadWheels ~= nil and getPlayerRadialMenu ~= nil
        and Z.T ~= nil and Z.T.px ~= nil
    if not Q.check(ready, "ZeD's D-pad wheels, the wheel's drawing, the balloon and the input lock are loaded") then S.dead = true; return end
    if D.gameWheels and D.gameWheels() then
        Q.check(false, "ZeD draws the D-pad wheels here", "the game's own wheels are up (safe mode, the Tutorial, or ZeD not drawn yet): no ZeD balloon to read")
        S.dead = true
        return
    end
    -- as found (the windows' open or shut last: the put-back reads the windows only once it is set)
    local char, world = S.charOpen(), S.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = char and S.geo(cw) or nil, w = world and S.geo(ww) or nil }
    S.was.tab = { c = (char and cw) and cw._activeTab or nil, w = (world and ww) and ww._activeTab or nil }
    local md = S.p and S.p:getModData()
    S.was.ws = { taken = md ~= nil, had = md ~= nil and md.ZeD_WinState ~= nil, v = md and S.copy(md.ZeD_WinState) or nil }
    S.was.mode = S.mode()
    S.lockWas = S.lockFound()
    S.was.wheel = S.wheelSt() ~= nil
    S.six = Z.T.px(Bn.INSET)
    S.was.char, S.was.world = char, world
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(Z.T.scale)
        .. " (1u = " .. S.num(Z.T.px(1)) .. " px, 6u = " .. S.num(S.six) .. " px); Character window open " .. tostring(S.was.char)
        .. " (" .. S.gs(S.was.geo.c) .. ", on " .. tostring(S.was.tab.c) .. "), World window open " .. tostring(S.was.world) .. " ("
        .. S.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w) .. "); Input lock " .. tostring(S.lockWas) .. ", ZeD reads "
        .. tostring(S.was.mode) .. "; a ZeD wheel up " .. tostring(S.was.wheel) .. ", ZeD.Wheel.qaPoint " .. tostring(S.was.qaPoint))
    S.lock("gamepad")
    S.toWheel()
    -- the layout each window found open saved as the pair shut just now (in the mode found): the put-back opens it on this
    S.was.wsShut = md and S.copy(md.ZeD_WinState) or nil
end)
Q.waitMs(1000)
for _, wh in ipairs(S.WHEELS) do S.queueWheel(wh) end

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    S.closeWheel()
    if W then W.qaPoint = S.was.qaPoint end
    S.unhookOk = S.unhook()
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
    -- a window found shut: the layout the character keeps for it, as it was (the controller's open and the shut after it
    -- wrote it)
    S.layoutBack(false)
end)
S.waitUntil(3000, function()
    if S.was.char == nil then return true end
    return S.settled()
end, function()
    if S.was.char == nil then return end
    -- the places and sizes, at rest: the windows open where they keep them; one that did not is set back by its own setters
    local moved = {}
    if S.was.char and S.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and S.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
end)
Q.step(10, function()
    local st = S.wheelSt()
    local m = S.radial()
    Q.check(st == nil and not S.vis(m) and (W == nil or W.qaPoint == S.was.qaPoint),
        "put back: the wheel is closed and no slice is pointed by the test",
        "ZeD's wheel state " .. tostring(st ~= nil) .. ", the shared wheel on screen " .. tostring(S.vis(m)) .. ", ZeD.Wheel.qaPoint "
        .. tostring(W and W.qaPoint) .. " (found " .. tostring(S.was.qaPoint) .. ")")
    if S.hookedEver then
        Q.check(S.unhookOk == true and M.drawContextBalloon == S.orig.ctx and Bn.draw == S.orig.draw and Bn.tailOrigin == S.orig.tail,
            "put back: the balloon draws through ZeD's own functions again (the three wrappers taken off)",
            "drawContextBalloon " .. tostring(M.drawContextBalloon == S.orig.ctx) .. ", Balloon.draw " .. tostring(Bn.draw == S.orig.draw)
            .. ", Balloon.tailOrigin " .. tostring(Bn.tailOrigin == S.orig.tail))
    end
    if S.lockWas ~= nil and S.was.mode ~= nil then
        local now, mode = S.lockFound(), S.mode()
        local unknown = S.was.mode == "unknown" and mode == "kbm"
        Q.check(now == S.lockWas and (mode == S.was.mode or unknown) and S.modeHeld == nil,
            "put back: the input lock as found, and the mode ZeD reads",
            "ZeD setup's Input lock " .. tostring(now) .. " (found " .. tostring(S.lockWas) .. "); ZeD reads " .. tostring(mode)
            .. " (found " .. tostring(S.was.mode) .. ")"
            .. (unknown and "; found unknown, no input since the game started, which ZeD reads as the mouse: the detector has no way back to it" or ""))
    end
    if S.was.char ~= nil then
        local cw, ww = RT.cw(), RT.ww()
        local c, w = S.charOpen(), S.worldOpen()
        local gc = c and S.geo(cw) or nil
        local gw = w and S.geo(ww) or nil
        local tc = (c and cw) and cw._activeTab or nil
        local tw = (w and ww) and ww._activeTab or nil
        Q.check(c == S.was.char and w == S.was.world and S.sameGeo(gc, S.was.geo.c) and S.sameGeo(gw, S.was.geo.w)
            and tc == S.was.tab.c and tw == S.was.tab.w,
            "put back: the Character and World windows open or shut as found, where and as big as they were, on their tabs",
            "Character open " .. tostring(c) .. " " .. S.gs(gc) .. " on " .. tostring(tc) .. " (found " .. tostring(S.was.char) .. " "
            .. S.gs(S.was.geo.c) .. " on " .. tostring(S.was.tab.c) .. "); World open " .. tostring(w) .. " " .. S.gs(gw) .. " on "
            .. tostring(tw) .. " (found " .. tostring(S.was.world) .. " " .. S.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w) .. ")"
            .. (S.moved and ("; the reopen left " .. S.moved .. " elsewhere: set back by its own setters") or ""))
    end
end)
Q.start()
