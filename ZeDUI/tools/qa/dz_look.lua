-- ZeDUI/tools/qa/dz_look.lua  (Nov 23 2026, QA; tag dz_look): Design's two approved handoffs, merged on main in 1bedb2505,
-- their "## QA" lists in game, with pictures:
--   ZeDUI/HANDOFF_design_car_parts_glass_20261123.md  the Vehicle tab's six side parts drawn (brake, spring, battery,
--                                                     muffler, engine, gas tank) and the glass cracked (MechanicsTab.lua,
--                                                     MechFigs.lua, 620 textures)
--   ZeDUI/HANDOFF_design_belt_blocks_20261123.md      every belt box a white block, the hands kept round (ZeD_Belt.lua)
-- Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. Manifest dz_look.txt. grep "ZEDQA dz_look".
-- Run at 4K (UI scale 1.75) and on a true 1280x800 Deck window. The window layout is reset first (ZEDQA_LAYOUT_DEFAULT).
--
-- PART A, the Vehicle tab. For each kind: a sedan (Base.CarNormal), a van (Base.Van), a pickup (Base.PickUpTruck), a
-- sports car (Base.SportsCar) and the horse trailer (Base.Trailer_Horsebox, the game's
-- media/scripts/generated/vehicles/vehicle_trailer_horsebox.txt): spawned on the drag strip (the prelude's
-- ZEDQA_CAR_WAIT, gc_cleanup.lua's way), repaired, him moved beside it, the tab opened as the mechanics key does
-- (MechanicsTab.openFromAction). A kind that will not spawn is a SKIP with the reason. Staged: the front left brake at
-- 100 (green), the front left spring at 50 (yellow), the battery at 10 (red; the trailer has none: its rear left brake
-- at 10); cars only: the windshield chipped (60), the first side window at 10 (smashed glass) and the next side window
-- (or the rear windshield) taken out. The drawer panel's draws recorded for one frame (gc_cleanup's recorder).
-- Checks, for each kind:
--   pictures   every part the figure draws (the overlay's pictures that have a MechFigs layer) is drawn from its own
--              picture (zm_<key>, or its _rim) at MechFigs' size, and has a hit box (figZones); in Dark, Light, High
--              contrast (and the sedan's accent change)
--   wear       the brake at 100 has no wear, the spring at 50 its _wear1, the battery at 10 its _wear2; each tinted
--              its status color (statusColor, lifted by the theme's mechFig.lift), the three different; the chipped
--              windshield _wear1, the side window at 10 _wear2 (or its rim alone if the game smashed it); the window
--              taken out its rim alone, in the danger color
--   overlap    no part beside the car (brake, spring, battery, muffler, engine, gas tank) overlaps another or the car
--              body (the base picture's rect), as drawn
--   size       the base picture is MechFigs' size, the zoom whole (2x at 4K, 1x on the Deck) and the car centered in
--              the diagram's room (gc_cleanup's rule); the biggest figure is still 147 x 169
--   mouse      every part on the figure hovers and is lit by the pointer at a point its hit box gives it (the tab's
--              own smallest-box rule, read through the drawer's getMouseX / getMouseY), and a click
--              (MechanicsTab.onClick) chooses it; the lit box (the T.text frame) contains the part's drawn picture and
--              is at most 3 units bigger on any side
--   pad        every part's row is a pad stop (mech:row:<id>, FocusManager.focusWhere): the focus lights the part on
--              the figure with the same box rule, and A (Focus.qaButton and dispatchJoypadDown) chooses it
--   errors     no new Lua error in the kind's run; the car gone from the world after
-- Pictures: dz_car_<kind>_<dark|light|hc>_<w>x<h>, dz_car_sedan_accent_<w>x<h> (Dark, the accent changed).
--
-- PART B, the belt. Staged as bl_side.lua does: the ALICE belt and suspenders worn (Base.Bag_ALICE_BeltSus, a plain
-- belt only if the belt slots are missing), his items off the four side slots for the run, a hunting knife on
-- SmallBeltLeft (condition 60%: its strip), the angle-head flashlight on WebbingRight lit (its lamp), SmallBeltRight and
-- WebbingLeft left empty (their names). Hands: a wood axe in both (the off hand peeks), then a pistol and a hammer (the
-- ammo tab). The belt's _prerender recorded for one frame (bl_side's recorder, plus drawRectBorder and drawFillBar).
-- Checks, in Dark, Light, High contrast and Dark with the accent changed, both hand stages:
--   blocks     every square box (slots, the bag, the speed keys, a mod's box, chat, PvP) draws the block as _drawBox /
--              _drawButton do: the shadow (drawHardShadow's two rects, 0.5 black, right and bottom), the paper fill
--              (ZeD.Belt.PAPER; the speed in use the accent) and the ink edge (drawRectBorder in ZeD.Belt.INK; the
--              speed in use its bright accent; a slot whose item is in hand its dashed edge instead)
--   round      the two hands are discs: no square paper fill, a paper disc, a round shadow one unit right and down,
--              an ink ring (baked round pictures or their rows)
--   marks      the L tag a black box and the R tag a white box with its ink edge (drawRectBorder SIDE_BLACK); an empty
--              slot's name in the ink at 0.6; the knife's condition strip; the flashlight's lamp in its box; the speed
--              keys with exactly one in use; the off hand peeking (one item in both hands); the ammo tab, the pistol in
--              the main hand and the hammer in the off hand (the gun stage)
--   drag       a screwdriver dragged (ZeD's DragState, as an inventory drag starts) over the belt: each slot and hand
--              that takes it (its own _dropState) is washed and edged in the accent, every other one grey under the
--              ink at 0.45
-- Pictures: dz_belt_<dark|light|hc|accent>_peek_<w>x<h>, dz_belt_<dark|light|hc|accent>_<w>x<h>, dz_belt_drag_<w>x<h>.
-- Every picture: the pointer the game reads parked, the real pointer hidden, unread Messages marked read (no notice in
-- the corner), no QA overlay (hg_injury.lua's S.shot).
--
-- Puts back (also when a step throws or the time runs out): each car's conditions and items as found, its look ended
-- and the car removed; the drawer's pointer reads, the recorders, the pad's focus and its A, the input lock, the chosen
-- card and the list's folds; the belt's _prerender, its draw methods and pointer reads, ZeD.Atoms.drawLamp and
-- drawFillBar; the drag (ISMouseDrag.dragging as found); the flashlight off, the run's items off the hotbar and taken
-- away, the run's gear off, his worn items, his hotbar slots and items and his modData hotbar as found; his hands as
-- found; the theme (base, accent, size); the game speed; both windows open or shut as found, their places, tabs and
-- his modData ZeD_WinState (ZEDQA_LAYOUT_BACK); him where he stood. Checked at the end, with no new Lua error over the
-- run. Unread Messages marked read before each picture are not undone (kiss_loot.lua's practice).
-- Not run offline; parse-checked with the game's Kahlua compiler (KCheck).

if not (RT and RT.make) then
    print("ZEDQA dz_look ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA dz_look VERDICT FAIL 1")
    print("ZEDQA dz_look DONE")
    return
end

local Q = RT.make("dz_look")
Q.maxMs = 2100000   -- (35 minutes, then the put-back; the runner gives 2400 s)
local S = { p = RT.p, pn = RT.pn, was = {}, rec = {}, held = {}, given = {}, his = {}, pic = {}, gone = {}, k = {},
            bItems = {} }
S.F = ZeD and ZeD.Input and ZeD.Input.Focus
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector
S.OFF = -100000
S.ptX, S.ptY = S.OFF, S.OFF

S.KINDS = {
    { kind = "sedan", script = "Base.CarNormal", accent = true },
    { kind = "van", script = "Base.Van" },
    { kind = "pickup", script = "Base.PickUpTruck" },
    { kind = "sportscar", script = "Base.SportsCar" },
    { kind = "horsetrailer", script = "Base.Trailer_Horsebox", trailer = true },
}
S.THEMES = {
    { key = "dark", tag = "dark", say = "Dark" },
    { key = "light", tag = "light", say = "Light" },
    { key = "hicon", tag = "hc", say = "High contrast" },
}
S.BTHEMES = {
    { key = "dark", tag = "dark", say = "Dark" },
    { key = "light", tag = "light", say = "Light" },
    { key = "hicon", tag = "hc", say = "High contrast" },
    { key = "dark", tag = "accent", say = "Dark with the accent changed", accent = true },
}
S.SIDE_WORDS = { "battery", "brake", "suspension", "engine", "gastank", "muffler" }
S.SIDE_WIN = { "WindowFrontLeft", "WindowFrontRight", "WindowRearLeft", "WindowRearRight", "WindshieldRear" }
S.REC_FNS = { "drawRect", "drawRectBorder", "drawTexture", "drawTextureScaled", "drawTextureScaledAspect",
              "drawTextureScaledUniform", "drawText" }
S.BELT_FNS = { "drawRect", "drawRectBorder", "drawTextureScaledAspect", "drawText" }
S.BSLOTS = { "SmallBeltLeft", "SmallBeltRight", "WebbingLeft", "WebbingRight" }
S.KNIFE_T, S.LAMP_T = "SmallBeltLeft", "WebbingRight"
S.EMPTY_T = { "SmallBeltRight", "WebbingLeft" }
S.GEAR, S.BELT = "Base.Bag_ALICE_BeltSus", "Base.Belt2"
S.BLACK = { r = 0, g = 0, b = 0 }
S.FR = { 4, 3, 5, 2, 6, 1, 7 }   -- the points tried across a hit box, in eighths, from the middle out
S.BESIDE = { { -3, 0 }, { 3, 0 }, { -3, 1 }, { 3, -1 }, { 0, -5 }, { 0, 5 } }

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.n(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    return tostring(math.floor(x * 10 + 0.5) / 10)
end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = getCore():getScreenWidth(), getCore():getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sz() local w, h = S.screen(); return w .. "x" .. h end
function S.near(a, b, tol) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 0.5) end
function S.sameCol(d, c, tol)
    tol = tol or 0.02
    return d ~= nil and c ~= nil and S.near(d.r, c.r, tol) and S.near(d.g, c.g, tol) and S.near(d.b, c.b, tol)
end
function S.rt(r)
    if not r then return "none" end
    return S.n(r.x) .. "," .. S.n(r.y) .. " " .. S.n(r.w) .. "x" .. S.n(r.h)
end
function S.ct(c)
    if not c then return "none" end
    return S.n(c.r) .. "/" .. S.n(c.g) .. "/" .. S.n(c.b)
end
function S.list(t, none) if #t == 0 then return none or "none" end; return table.concat(t, "; ") end
function S.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) elseif setGameSpeed then pcall(setGameSpeed, n) end end
function S.gameSpeed() local v = nil; pcall(function() v = getGameSpeed() end); return v end
function S.tr(key) local s = nil; pcall(function() s = ZeD.tr(key) end); return s end
function S.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    if depth > 4 then return nil end
    local o = {}
    for k, v in pairs(t) do o[k] = S.copy(v, depth + 1) end
    return o
end
function S.md() return S.p:getModData() end
function S.itemShow(it) local n = nil; pcall(function() n = it:getDisplayName() end); return tostring(n) end
-- waits by the clock (bl_side.lua's)
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
function S.settle(minMs, maxMs, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(maxMs / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if now - st.t >= minMs then
            local okC, r = pcall(cond)
            if okC and r then st.ok = true; return true end
        end
        return now - st.t >= maxMs
    end, function() fn(st.ok == true) end)
end

-- ===================================================================== the draw recorder (gc_cleanup.lua's)
function S.texInfo(tex)
    local nm, tw, th = nil, nil, nil
    if type(tex) == "string" then return tex, nil, nil end
    if tex == nil then return nil, nil, nil end
    pcall(function() nm = tex:getName() end)
    pcall(function() tw = tex:getWidthOrig(); th = tex:getHeightOrig() end)
    if tw == nil then pcall(function() tw = tex:getWidth(); th = tex:getHeight() end) end
    return nm, tw, th
end
function S.recAdd(R, fn, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    local d = { fn = fn }
    if fn == "drawRect" or fn == "drawRectBorder" then
        d.x, d.y, d.w, d.h = a1, a2, a3, a4
        d.a, d.r, d.g, d.b = tonumber(a5), tonumber(a6), tonumber(a7), tonumber(a8)
    elseif fn == "drawText" then
        d.str, d.x, d.y, d.w, d.h = tostring(a1), a2, a3, 0, 0
        d.r, d.g, d.b, d.a = tonumber(a4), tonumber(a5), tonumber(a6), tonumber(a7)
    else
        d.tex = a1
        d.name, d.tw, d.th = S.texInfo(a1)
        d.x, d.y = a2, a3
        if fn == "drawTexture" then
            d.w, d.h = d.tw or 0, d.th or 0
            d.a, d.r, d.g, d.b = tonumber(a4), tonumber(a5), tonumber(a6), tonumber(a7)
        elseif fn == "drawTextureScaledUniform" then
            d.w, d.h = (d.tw or 0) * (a4 or 1), (d.th or 0) * (a4 or 1)
            d.a, d.r, d.g, d.b = tonumber(a5), tonumber(a6), tonumber(a7), tonumber(a8)
        else
            d.w, d.h = a4, a5
            d.a, d.r, d.g, d.b = tonumber(a6), tonumber(a7), tonumber(a8), tonumber(a9)
        end
        if type(d.name) == "string" then
            d.lname = string.lower(d.name)
            d.key = d.lname:match("zm_([%w_]+)")
        end
    end
    d.x, d.y, d.w, d.h = tonumber(d.x) or 0, tonumber(d.y) or 0, tonumber(d.w) or 0, tonumber(d.h) or 0
    R.list[#R.list + 1] = d
end
function S.recFn(R, fn, orig)
    return function(self, a1, a2, a3, a4, a5, a6, a7, a8, a9, ...)
        pcall(S.recAdd, R, fn, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        return orig(self, a1, a2, a3, a4, a5, a6, a7, a8, a9, ...)
    end
end
function S.recOn(key, panel)
    S.recOff(key)
    if not panel then return false end
    local R = { panel = panel, own = {}, list = {} }
    for _, fn in ipairs(S.REC_FNS) do
        R.own[fn] = rawget(panel, fn) or false
        local orig = panel[fn]
        if orig then panel[fn] = S.recFn(R, fn, orig) end
    end
    S.rec[key] = R
    return true
end
function S.recOff(key)
    local R = S.rec[key]
    if not R then return nil end
    for _, fn in ipairs(S.REC_FNS) do
        local o = R.own[fn]
        if o then R.panel[fn] = o else R.panel[fn] = nil end
    end
    S.rec[key] = nil
    return R
end
function S.recCount()
    local n = 0
    for _ in pairs(S.rec) do n = n + 1 end
    return n
end
function S.recAllOff()
    local keys = {}
    for k in pairs(S.rec) do keys[#keys + 1] = k end
    for _, k in ipairs(keys) do S.recOff(k) end
end
function S.drawsOf(R, key)
    local out = {}
    for _, d in ipairs(R and R.list or {}) do if d.key == key then out[#out + 1] = d end end
    return out
end

-- ===================================================================== the pointer, the input lock, the windows held
-- the drawer's own pointer reads (renderSplit asks panel:getMouseX / getMouseY): S.ptX, S.ptY while on
function S.panel() local ww = RT.ww(); return ww and ww._drawerPanel or nil end
function S.ptrOn(panel)
    if not panel then return end
    if S.ptr and S.ptr.panel == panel then return end
    S.ptrOff()
    S.ptr = { panel = panel, x = rawget(panel, "getMouseX"), y = rawget(panel, "getMouseY") }
    panel.getMouseX = function() return S.ptX end
    panel.getMouseY = function() return S.ptY end
end
function S.ptrOff()
    local P = S.ptr
    if not P then return end
    S.ptr = nil
    P.panel.getMouseX, P.panel.getMouseY = P.x, P.y
end
-- the pointer the game reads, parked, the real one hidden (hg_injury.lua's S.park)
function S.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return S.OFF end
            getMouseY = function() return S.OFF end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function S.hold(w)
    if not w then return end
    for _, h in ipairs(S.held) do if h.w == w then return end end
    S.held[#S.held + 1] = { w = w, own = rawget(w, "pointerOn") }
    w.pointerOn = function() return true end
end
function S.unholdAll()
    for _, h in ipairs(S.held) do h.w.pointerOn = h.own end
    S.held = {}
end
function S.opt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.opt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    return key or "auto"
end
-- (gc_cleanup.lua's: a mode pins ZeD's input mode; false puts the found lock back)
function S.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    pcall(function()
        if S.lockWas == nil then S.lockWas = S.lockFound() end
        if mode then
            S.Det.setLockedMode(mode)
            S.locked = true
            return
        end
        if not S.locked then return end
        S.locked = false
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
end
function S.theme(base, accent)
    accent = accent or ZeD.currentAccent
    if ZeD.currentBase == base and ZeD.currentAccent == accent then return end
    pcall(ZeD.applyTheme, base, accent, ZeD.currentSize)
    Q.say("theme " .. tostring(ZeD.currentBase) .. " (" .. tostring(ZeD.currentAccent) .. ", " .. tostring(ZeD.currentSize) .. ")")
end
function S.otherAccent() if S.was.accent ~= "orange" then return "orange" end; return "purple" end
-- unread Messages marked read and their error notices dropped before a picture (gc_cleanup.lua's)
function S.notesRead()
    local M = ZeD.Messages
    if not (M and M.unread and M.markAllRead) then return end
    if M.readErrors then pcall(M.readErrors) end
    local un = 0
    pcall(function() un = M.unread() end)
    if (un or 0) > 0 then pcall(M.markAllRead) end
    if M.toasts and M.dropToast then
        for i = #M.toasts, 1, -1 do
            local t = M.toasts[i]
            if t and t.kind == "crit" then pcall(M.dropToast, t) end
        end
    end
    if (un or 0) > 0 then Q.say("NOTE before the picture " .. tostring(un) .. " unread message(s) marked read") end
end
-- a picture: the pointer parked and hidden, the picture, the pointer back (hg_injury.lua's S.shot); off() true skips it
function S.shotQ(name, what, off)
    Q.step(1, function()
        if off and off() then return end
        S.notesRead()
        S.park(true)
    end)
    Q.step(4, function()
        if off and off() then Q.say("SKIP picture " .. name .. " (nothing staged for it)"); S.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then
            S.pic[#S.pic + 1] = name
            Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        S.park(false)
    end)
    Q.waitMs(1200)
end

-- ===================================================================== windows (bl_side.lua's)
function S.charOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(S.pn) end); return o and true or false end
function S.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function S.none() return not S.charOpen() and not S.worldOpen() end
function S.shutAll()
    if S.charOpen() and S.worldOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn); return end
    if S.charOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
    if S.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
end
function S.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function S.placeBack(w, g)
    if not (w and g) then return end
    pcall(function()
        if math.abs(w:getWidth() - g.w) > 1 then w.minimumWidth = math.min(w.minimumWidth or g.w, g.w); w:setWidth(g.w) end
        if math.abs(w:getHeight() - g.h) > 1 then w.minimumHeight = math.min(w.minimumHeight or g.h, g.h); w:setHeight(g.h) end
        if w:getX() ~= g.x then w:setX(g.x) end
        if w:getY() ~= g.y then w:setY(g.y) end
    end)
end

-- ===================================================================== the car on the strip (gc_cleanup.lua's)
function S.st()
    local ww = RT.ww()
    if not ww then return nil end
    local s = nil
    pcall(function() s = ZeD.MechanicsTab.getState(ww) end)
    return s
end
function S.dist(v)
    local d = 999
    pcall(function()
        local dx, dy = v:getX() - S.p:getX(), v:getY() - S.p:getY()
        d = math.sqrt(dx * dx + dy * dy)
    end)
    return d
end
function S.tpTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
-- him within the tab's reach of the car (4.5 tiles), on a free square beside it
function S.carNear(v)
    local d = S.dist(v)
    if d <= 4.0 then return d end
    local vx, vy, z = math.floor(v:getX()), math.floor(v:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(S.BESIDE) do
        local sq = nil
        pcall(function() sq = getCell():getGridSquare(vx + o[1], vy + o[2], z) end)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and sq:getVehicleContainer() == nil end) end
        if free then
            S.tpTo(vx + o[1] + 0.5, vy + o[2] + 0.5, z)
            Q.say("moved him beside the vehicle (it stood " .. S.n(d) .. " tiles away): " .. (vx + o[1]) .. "," .. (vy + o[2]))
            return S.dist(v)
        end
    end
    return d
end
-- (the cell's vehicles are a set, not a list: walked with its iterator, never get(i))
function S.carLive(v)
    if not v then return false end
    local vs, it, live = nil, nil, false
    pcall(function() vs = getCell():getVehicles() end)
    if not vs then return false end
    pcall(function() it = vs:iterator() end)
    if not it then return false end
    pcall(function() while it:hasNext() do if it:next() == v then live = true end end end)
    return live
end
function S.carTabReady()
    local ww = RT.ww()
    local v = S.car and S.car.v
    if not (ww and v and ww._activeTab == "vehicle") then return false end
    local s = S.st()
    local cur = s and s.vehicles and s.vehicles[s.idx or 1]
    return cur ~= nil and cur.vehicle == v and s.view == "overview" and s.figZones ~= nil and #s.figZones > 0 and s.rightClip ~= nil
end
function S.carAway()
    local c = S.car
    if S.carTok then S.carTok.gaveUp = true end
    pcall(function() ZeD.MechanicsTab.endLooks(S.p) end)
    if not c or c.going then return end
    c.going = true
    if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, c.v, nil) end
end
-- the figure's prefix and the overlay's table for the vehicle (MechanicsTab's overlayInfo)
function S.prefixOf(v)
    local OV = ISCarMechanicsOverlay
    if not (OV and OV.CarList and v) then return nil, nil, nil end
    local name = nil
    pcall(function() name = v:getScriptName() end)
    pcall(function()
        local sc = v:getScript()
        if sc and sc:getCarMechanicsOverlay() then name = sc:getCarMechanicsOverlay() end
    end)
    local props = name and OV.CarList[name] or nil
    return props and props.imgPrefix or nil, props, name
end
-- a part's pictures (MechanicsTab's partImgs)
function S.imgsOf(K, id)
    local OV = ISCarMechanicsOverlay
    local props = K.props
    local pp = (props and props.PartList and props.PartList[id]) or (OV and OV.PartList and OV.PartList[id])
    if not (pp and pp.img) then return nil end
    if pp.multipleImg then return pp.img end
    return { pp.img }
end
function S.layerKeys(K, id)
    local out = {}
    local F = ZeD.MechFigs
    for _, img in ipairs(S.imgsOf(K, id) or {}) do
        local key = K.prefix .. img
        if F.layers[key] then out[#out + 1] = key end
    end
    return out
end
-- the parts the tab lists (collectParts: every part but "nodisplay")
function S.partsOf(v)
    local out = {}
    pcall(function()
        for i = 0, v:getPartCount() - 1 do
            local part = v:getPartByIndex(i)
            local cat = part:getCategory() or "Other"
            if cat ~= "nodisplay" then out[#out + 1] = { id = part:getId(), part = part } end
        end
    end)
    return out
end
function S.isSide(key)
    for _, w in ipairs(S.SIDE_WORDS) do if key:find(w, 1, true) then return true end end
    return false
end
function S.meets(a, b)
    return a.x < b.x + b.w - 0.01 and b.x < a.x + a.w - 0.01 and a.y < b.y + b.h - 0.01 and b.y < a.y + a.h - 0.01
end

-- ===================================================================== the staging: conditions and glass
function S.partOf(id)
    local v = S.car and S.car.v
    local part = nil
    if v then pcall(function() part = v:getPartById(id) end) end
    return part
end
function S.keepPart(K, id)
    local part = S.partOf(id)
    if not part then return nil end
    local f = { id = id, part = part }
    pcall(function() f.cond = part:getCondition() end)
    pcall(function() f.item = part:getInventoryItem() end)
    K.kept[#K.kept + 1] = f
    return part
end
function S.setCond(K, id, c, wear)
    local part = S.keepPart(K, id)
    if not part then return false end
    pcall(function() part:setCondition(c) end)
    K.want[id] = { cond = c, wear = wear }
    return true
end
function S.stageCar(K)
    K.kept, K.want = {}, {}
    S.setCond(K, "BrakeFrontLeft", 100, "none")
    S.setCond(K, "SuspensionFrontLeft", 50, "wear1")
    if not S.setCond(K, "Battery", 10, "wear2") then S.setCond(K, "BrakeRearLeft", 10, "wear2") end
    if not K.trailer then
        S.setCond(K, "Windshield", 60, "wear1")
        local n = 0
        for _, id in ipairs(S.SIDE_WIN) do
            if n < 2 and S.partOf(id) then
                n = n + 1
                if n == 1 then
                    S.setCond(K, id, 10, "wear2")
                    K.sideWin = id
                else
                    local part = S.keepPart(K, id)
                    pcall(function() part:setInventoryItem(nil) end)
                    K.want[id] = { wear = "rim", removed = true }
                    K.goneWin = id
                end
            end
        end
    end
    local said = {}
    for id, W in pairs(K.want) do
        local part = S.partOf(id)
        local c, sm, item = nil, false, nil
        pcall(function() c = part:getCondition() end)
        pcall(function() local w = part:getWindow(); sm = w ~= nil and w:isDestroyed() end)
        pcall(function() item = part:getInventoryItem() end)
        said[#said + 1] = id .. " " .. (W.removed and ("taken out (item " .. tostring(item ~= nil) .. ")") or ("at " .. tostring(c)))
            .. (sm and " (the game smashed it)" or "")
    end
    Q.say(K.kind .. " staged: " .. table.concat(said, ", "))
end
function S.unstageCar(K)
    for i = #(K.kept or {}), 1, -1 do
        local f = K.kept[i]
        pcall(function() if f.item and f.part:getInventoryItem() ~= f.item then f.part:setInventoryItem(f.item) end end)
        if f.cond then pcall(function() f.part:setCondition(f.cond) end) end
    end
    K.kept = {}
end

-- ===================================================================== the car's reads (one recorded frame)
-- every part the figure draws has its picture at MechFigs' size and a hit box
function S.carPics(K, R, s, lab)
    local F = ZeD.MechFigs
    local want, miss, wrong, noLayer = 0, {}, {}, {}
    local zoneIds = {}
    for _, z in ipairs(s.figZones or {}) do zoneIds[z.id] = true end
    for _, P in ipairs(S.partsOf(S.car.v)) do
        local any = false
        for _, img in ipairs(S.imgsOf(K, P.id) or {}) do
            local key = K.prefix .. img
            local L = F.layers[key]
            if L then
                any = true
                want = want + 1
                local got = S.drawsOf(R, key)[1] or S.drawsOf(R, key .. "_rim")[1]
                if not got then miss[#miss + 1] = P.id .. " (" .. key .. " not drawn)"
                elseif got.tw ~= L.w or got.th ~= L.h then
                    wrong[#wrong + 1] = tostring(got.key) .. " is " .. tostring(got.tw) .. "x" .. tostring(got.th) .. ", MechFigs " .. L.w .. "x" .. L.h
                end
            else
                noLayer[#noLayer + 1] = key
            end
        end
        if any and not zoneIds[P.id] then miss[#miss + 1] = P.id .. " (no hit box)" end
    end
    Q.check(want > 0 and #miss == 0 and #wrong == 0,
        lab .. ": every part the figure draws is drawn from its own picture at MechFigs' size and has a hit box",
        want .. " layers on " .. #(s.figZones or {}) .. " hit boxes; missing: " .. S.list(miss) .. "; wrong size: " .. S.list(wrong))
    if #noLayer > 0 and not K.noLayerSaid then
        K.noLayerSaid = true
        Q.say("NOTE " .. K.kind .. ": the overlay names pictures with no MechFigs layer (not drawn, as before): " .. table.concat(noLayer, ", "))
    end
end
-- the tint a part at cond takes (statusColor, lifted by the theme's mechFig.lift)
function S.tint(cond)
    local c = ZeD.Atoms.statusColor((cond or 0) / 100)
    local look = ZeD.T.mechFig
    local k = look and look.lift or 0
    if k > 0 and ZeD.colorBlend then return ZeD.colorBlend(c, { r = 1, g = 1, b = 1 }, k) end
    return c
end
-- one staged part against its want: nil when right, else why
function S.wearWhy(K, R, id, W, tints)
    local part = S.partOf(id)
    local smashed, cond = false, nil
    pcall(function() local w = part:getWindow(); smashed = w ~= nil and w:isDestroyed() end)
    pcall(function() cond = part:getCondition() end)
    local exp = W.wear
    if smashed then exp = "rim" end
    local keys = S.layerKeys(K, id)
    if #keys == 0 then return "no layer on the figure" end
    local why = {}
    for _, key in ipairs(keys) do
        local plain, rim = S.drawsOf(R, key)[1], S.drawsOf(R, key .. "_rim")[1]
        local w1, w2 = #S.drawsOf(R, key .. "_wear1"), #S.drawsOf(R, key .. "_wear2")
        if exp == "rim" then
            if not (rim and S.sameCol(rim, ZeD.T.danger)) then why[#why + 1] = key .. ": no rim in the danger color" end
            if plain or w1 + w2 > 0 then why[#why + 1] = key .. ": its picture or wear drawn too" end
        else
            if not plain then why[#why + 1] = key .. ": not drawn"
            else
                local want = S.tint(cond)
                if not S.sameCol(plain, want) then why[#why + 1] = key .. " tinted " .. S.ct(plain) .. ", want " .. S.ct(want) .. " (condition " .. tostring(cond) .. ")" end
                tints[exp] = tints[exp] or plain
            end
            if exp == "none" and w1 + w2 > 0 then why[#why + 1] = key .. ": wear on a part at " .. tostring(cond) end
            if exp == "wear1" and not (w1 > 0 and w2 == 0) then why[#why + 1] = key .. ": wear1 " .. w1 .. ", wear2 " .. w2 .. " (want the light wear)" end
            if exp == "wear2" and not (w2 > 0 and w1 == 0) then why[#why + 1] = key .. ": wear1 " .. w1 .. ", wear2 " .. w2 .. " (want the heavy wear)" end
        end
    end
    if #why == 0 then return nil, exp end
    return table.concat(why, ", "), exp
end
function S.carWear(K, R, lab)
    local bad, seen, tints = {}, {}, {}
    local glass, gBad = {}, {}
    for id, W in pairs(K.want) do
        local isGlass = id:find("Window", 1, true) ~= nil or id:find("Windshield", 1, true) ~= nil
        local why, exp = S.wearWhy(K, R, id, W, isGlass and {} or tints)
        local line = id .. " " .. tostring(exp)
        if isGlass then
            glass[#glass + 1] = line
            if why then gBad[#gBad + 1] = id .. ": " .. why end
        else
            seen[#seen + 1] = line
            if why then bad[#bad + 1] = id .. ": " .. why end
        end
    end
    local g, y, r = tints.none, tints.wear1, tints.wear2
    local three = g ~= nil and y ~= nil and r ~= nil and not S.sameCol(g, y) and not S.sameCol(y, r) and not S.sameCol(g, r)
    Q.check(#bad == 0 and three, lab .. ": the brake at 100 green with no wear, the spring at 50 yellow with its light wear, the "
        .. (K.trailer and "rear brake" or "battery") .. " at 10 red with its heavy wear (three different tints)",
        S.list(seen) .. "; tints " .. S.ct(g) .. " | " .. S.ct(y) .. " | " .. S.ct(r) .. ((#bad > 0) and ("; WRONG: " .. S.list(bad)) or ""))
    if K.trailer then
        Q.skip(lab .. ": the glass (a chipped windshield, a smashed side window, a window taken out)", "the horse trailer has no glass")
    else
        Q.check(#glass >= 3 and #gBad == 0, lab .. ": the glass: the windshield at 60 cracked (light wear), a side window at 10 cracked (heavy wear, or its rim if smashed), a window taken out its rim alone",
            S.list(glass) .. " (" .. tostring(K.sideWin) .. " at 10, " .. tostring(K.goneWin) .. " taken out)" .. ((#gBad > 0) and ("; WRONG: " .. S.list(gBad)) or ""))
    end
end
-- no part beside the car overlaps another or the body
function S.carOverlap(K, R, lab)
    local pre = K.prefix
    local base = S.drawsOf(R, pre .. "base")[1]
    local sides, seen = {}, {}
    for _, d in ipairs(R.list) do
        local k = d.key
        if k and k:sub(1, #pre) == pre and k ~= pre .. "base" and not k:find("_wear", 1, true) and S.isSide(k) then
            local kk = (k:gsub("_rim$", ""))
            if not seen[kk] then seen[kk] = true; sides[#sides + 1] = { key = kk, r = d } end
        end
    end
    local bad = {}
    for i = 1, #sides do
        local a = sides[i]
        if base and S.meets(a.r, base) then bad[#bad + 1] = a.key .. " " .. S.rt(a.r) .. " on the body " .. S.rt(base) end
        for j = i + 1, #sides do
            local b = sides[j]
            if S.meets(a.r, b.r) then bad[#bad + 1] = a.key .. " " .. S.rt(a.r) .. " on " .. b.key .. " " .. S.rt(b.r) end
        end
    end
    Q.check(base ~= nil and #sides >= 6 and #bad == 0, lab .. ": no part beside the car overlaps another part or the car body",
        #sides .. " side parts, body " .. S.rt(base) .. ((#bad > 0) and ("; WRONG: " .. S.list(bad)) or ""))
end
-- the figure's size and place (gc_cleanup.lua's carCheck; 1x on the Deck as well)
function S.carSize(K, R, lab)
    local F, T = ZeD.MechFigs, ZeD.T
    local pre = K.prefix
    local base = S.drawsOf(R, pre .. "base")[1]
    local L, U = F.layers[pre .. "base"], F.unions[pre]
    if not (base and L and U) then
        Q.check(false, lab .. ": the car's base picture is drawn", "base " .. tostring(base and base.name) .. ", prefix " .. tostring(pre))
        return
    end
    local s = S.st()
    local clip = s and s.rightClip
    local sc = base.w / L.w
    local whole = math.abs(sc - math.floor(sc + 0.5)) < 0.01
    local sw, sh = S.screen()
    local want = nil
    if sw >= 3800 then want = 2 elseif sh <= 800 then want = 1 end
    local pad = T.px(10)
    local areaC = clip and (clip.x + pad + (clip.w - T.sp.scrollbarW - 2 * pad) / 2) or 0
    local ox = base.x - (L.x - U.x) * sc
    local uC = ox + U.w * sc / 2
    Q.check(base.tw == L.w and base.th == L.h and clip ~= nil and whole and (want == nil or math.abs(sc - want) < 0.01) and math.abs(uC - areaC) <= 1,
        lab .. ": the car is the size it was, a whole zoom" .. (want and (" (" .. want .. "x on this screen)") or "") .. ", centered in the diagram's room",
        "base " .. tostring(base.tw) .. "x" .. tostring(base.th) .. " (MechFigs " .. L.w .. "x" .. L.h .. ", union " .. U.w .. "x" .. U.h
        .. "), zoom " .. S.n(sc) .. ", the car's middle at x " .. S.n(uC) .. ", the room's at " .. S.n(areaC) .. ", screen " .. sw .. "x" .. sh)
end
function S.carRead(K, R, lab, full)
    local s = S.st()
    if not (R and s and S.car) then Q.check(false, lab .. ": one frame of the Vehicle tab recorded"); return end
    S.carPics(K, R, s, lab)
    if not full then return end
    S.carWear(K, R, lab)
    S.carOverlap(K, R, lab)
    S.carSize(K, R, lab)
end

-- ===================================================================== hover and select (mouse, pad)
function S.hitZ(z, x, y) return x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end
function S.zoneOf(s, id)
    for _, z in ipairs(s and s.figZones or {}) do if z.id == id then return z end end
    return nil
end
-- the tab's own rule (figurePartAt): the smallest hit box under the point
function S.partAt(s, x, y)
    local best, bestA = nil, nil
    for _, z in ipairs(s.figZones or {}) do
        if S.hitZ(z, x, y) then
            local a = z.w * z.h
            if not bestA or a < bestA then best, bestA = z.id, a end
        end
    end
    return best
end
function S.pointFor(s, id)
    local z = S.zoneOf(s, id)
    if not z then return nil end
    local clip = s.figClip
    for _, fy in ipairs(S.FR) do
        for _, fx in ipairs(S.FR) do
            local x, y = math.floor(z.x + z.w * fx / 8), math.floor(z.y + z.h * fy / 8)
            if (not clip or S.hitZ(clip, x, y)) and S.partAt(s, x, y) == id then return x, y end
        end
    end
    return nil
end
-- the part's picture as drawn this frame (its layers, rims and wear)
function S.drawnRect(R, K, id)
    local x0, y0, x1, y1 = nil, nil, nil, nil
    for _, key in ipairs(S.layerKeys(K, id)) do
        for _, d in ipairs(R and R.list or {}) do
            local k = d.key
            if k == key or k == key .. "_rim" or k == key .. "_wear1" or k == key .. "_wear2" then
                x0 = x0 and math.min(x0, d.x) or d.x
                y0 = y0 and math.min(y0, d.y) or d.y
                x1 = x1 and math.max(x1, d.x + d.w) or (d.x + d.w)
                y1 = y1 and math.max(y1, d.y + d.h) or (d.y + d.h)
            end
        end
    end
    if not x0 then return nil end
    return { x = x0, y = y0, w = x1 - x0, h = y1 - y0 }
end
-- the lit box (ZeD.Atoms.frame in T.text: its top and left edges), the one nearest the part's picture
function S.litFrame(R, dr)
    local T = ZeD.T
    local t = T.hair or 1
    local best, bestD = nil, nil
    for _, top in ipairs(R and R.list or {}) do
        if top.fn == "drawRect" and S.near(top.h, t) and top.w > 2 * t and S.sameCol(top, T.text) then
            for _, left in ipairs(R.list) do
                if left.fn == "drawRect" and S.near(left.x, top.x) and S.near(left.y, top.y + t) and S.near(left.w, t) and S.sameCol(left, T.text) then
                    local f = { x = top.x, y = top.y, w = top.w, h = left.h + 2 * t }
                    local dd = math.abs((f.x + f.w / 2) - (dr.x + dr.w / 2)) + math.abs((f.y + f.h / 2) - (dr.y + dr.h / 2))
                    if not bestD or dd < bestD then best, bestD = f, dd end
                end
            end
        end
    end
    return best
end
function S.litWhy(R, K, id)
    local dr = R and S.drawnRect(R, K, id)
    if not dr then return "its picture was not drawn" end
    local fr = S.litFrame(R, dr)
    if not fr then return "no lit box drawn (picture " .. S.rt(dr) .. ")" end
    local m = { dr.x - fr.x, dr.y - fr.y, fr.x + fr.w - (dr.x + dr.w), fr.y + fr.h - (dr.y + dr.h) }
    local most = ZeD.T.px(3) + 0.5
    for _, v in ipairs(m) do
        if v < -0.5 then return "the box " .. S.rt(fr) .. " cuts the picture " .. S.rt(dr) end
        if v > most then return "the box " .. S.rt(fr) .. " is " .. S.n(v) .. " px off the picture " .. S.rt(dr) .. " (at most " .. S.n(most) .. ")" end
    end
    return nil
end
function S.cardShut()
    local s = S.st()
    if s then
        s.card, s.verb, s.confirm, s.sortOpen = nil, nil, nil, nil
        s.cardScroll = 0
        s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
    end
    local ww = RT.ww()
    if ww then ww._mechFocusTarget = nil end
end
function S.partBad(L, id, why)
    L.bad[#L.bad + 1] = tostring(id) .. ": " .. why
    L.i, L.phase, L.wait = L.i + 1, 0, 1
end
function S.mouseStep(L)
    local K, id = L.K, L.ids[L.i]
    local s = S.st()
    if L.phase == 0 then
        S.ptrOn(S.panel())
        local px, py = S.pointFor(s, id)
        if not px then return S.partBad(L, id, "no point in its hit box maps to it (the tab's smallest box rule)") end
        L.px, L.py = px, py
        S.ptX, S.ptY = px, py
        S.recOn("lit", S.panel())
        L.phase, L.wait = 1, 2
        return
    end
    local R = S.recOff("lit")
    local hl = s and s.hl
    local why = S.litWhy(R, K, id)
    S.ptX, S.ptY = S.OFF, S.OFF
    pcall(ZeD.MechanicsTab.onClick, RT.ww(), L.px, L.py)
    local card = s and s.card
    S.cardShut()
    if hl == id and why == nil and card == id then L.ok = L.ok + 1
    else
        L.bad[#L.bad + 1] = tostring(id) .. ": at " .. S.n(L.px) .. "," .. S.n(L.py) .. " lit " .. tostring(hl) .. ", the click chose "
            .. tostring(card) .. ", " .. (why or "the box fits")
    end
    L.i, L.phase, L.wait = L.i + 1, 0, 2
end
function S.padStep(L)
    local K, id = L.K, L.ids[L.i]
    local s, ww, F = S.st(), RT.ww(), S.F
    local rowId = "mech:row:" .. tostring(id)
    if L.phase == 0 then
        local e = F.focusWhere(ww, "worldTabContent", function(x) return x.id == rowId end)
        if not e then return S.partBad(L, id, "the pad has no stop for it (" .. rowId .. ")") end
        S.recOn("lit", S.panel())
        L.phase, L.wait = 1, 3
        return
    end
    if L.phase == 1 then
        local R = S.recOff("lit")
        L.gp, L.hl = s and s.gpId, s and s.hl
        L.why = S.litWhy(R, K, id)
        F.qaButton("A", true, S.pn)
        pcall(function() F.dispatchJoypadDown(ww, Joypad.AButton) end)
        L.phase, L.wait = 2, 2
        return
    end
    if L.phase == 2 then
        F.qaButton("A", false, S.pn)
        L.phase, L.wait = 3, 3
        return
    end
    F.qaButton("A", nil, S.pn)
    local card = s and s.card
    S.cardShut()
    if L.gp == rowId and L.hl == id and L.why == nil and card == id then L.ok = L.ok + 1
    else
        L.bad[#L.bad + 1] = tostring(id) .. ": the pad's stop " .. tostring(L.gp) .. ", lit " .. tostring(L.hl) .. ", A chose "
            .. tostring(card) .. ", " .. (L.why or "the box fits")
    end
    L.i, L.phase, L.wait = L.i + 1, 0, 3
end
function S.loopStart(K, mode)
    S.L = nil
    if K.off then return end
    local s = S.st()
    local ids = {}
    for _, z in ipairs(s and s.figZones or {}) do ids[#ids + 1] = z.id end
    local L = { K = K, mode = mode, ids = ids, i = 1, phase = 0, wait = 0, ok = 0, bad = {} }
    S.L = L
    S.ptX, S.ptY = S.OFF, S.OFF
    S.cardShut()
    if mode == "pad" then
        -- (gc_cleanup.lua: FocusManager's poll drops held presses unless ZeD reads the pad's mode)
        S.lock("gamepad")
        local ww = RT.ww()
        pcall(S.F.releaseFocus, S.pn)
        pcall(S.F.claimFocus, ww)
        local fw = nil
        pcall(function() fw = S.F.getFocusedWindow(S.pn) end)
        if fw ~= ww then L.noPad = true end
        L.wait = 8
    else
        S.lock("kbm")
    end
end
function S.loopTick()
    local L = S.L
    if not L or L.noPad then return true end
    if L.wait > 0 then L.wait = L.wait - 1; return false end
    if L.i > #L.ids then return true end
    local fn = (L.mode == "mouse") and S.mouseStep or S.padStep
    local ok, e = pcall(fn, L)
    if not ok then
        S.recOff("lit")
        S.ptX, S.ptY = S.OFF, S.OFF
        S.partBad(L, L.ids[L.i], "the step threw " .. tostring(e))
    end
    return false
end
function S.loopEnd(ok)
    local L = S.L
    S.L = nil
    S.recOff("lit")
    S.ptX, S.ptY = S.OFF, S.OFF
    if not L then return end
    if L.mode == "pad" then
        pcall(S.F.qaButton, "A", nil, S.pn)
        pcall(S.F.releaseFocus, S.pn)
        S.lock("kbm")
    end
    S.cardShut()
    local K = L.K
    local what
    if L.mode == "mouse" then
        what = K.lab .. ": every part on the figure is lit by the pointer (its lit box fits its picture) and chosen by a click"
    else
        what = K.lab .. ": every part's row is a pad stop that lights the part on the figure (its lit box fits its picture), and A chooses it"
    end
    local detail = L.ok .. " of " .. #L.ids .. " parts" .. (ok and "" or " (the loop ran out of time)")
        .. (L.noPad and "; the World window did not take the pad's focus" or "") .. ((#L.bad > 0) and ("; " .. S.list(L.bad)) or "")
    Q.check(ok and not L.noPad and #L.ids > 0 and L.ok == #L.ids, what, detail)
end
function S.loopQ(K, mode)
    Q.step(2, function() S.loopStart(K, mode) end)
    Q.waitFor(1, 6000, S.loopTick, function(ok) S.loopEnd(ok) end)
end

-- ===================================================================== one vehicle kind
function S.carOpen(K)
    local v = S.car.v
    pcall(function() v:repair() end)
    local d = S.carNear(v)
    K.prefix, K.props, K.oname = S.prefixOf(v)
    local ok, r = pcall(ZeD.MechanicsTab.openFromAction, S.p, v)
    local nm = nil
    pcall(function() nm = v:getScriptName() end)
    S.k.ids[#S.k.ids + 1] = K.kind .. " " .. tostring(nm)
    Q.say(K.kind .. ": " .. tostring(nm) .. " (asked " .. K.script .. "), overlay " .. tostring(K.oname) .. ", figure "
        .. tostring(K.prefix) .. ", " .. S.n(d) .. " tiles away; the Vehicle tab opened " .. tostring(ok and r))
    if not (K.prefix and ZeD.MechFigs.unions[K.prefix]) then
        K.off = true
        Q.check(false, K.lab .. ": the vehicle has a figure (its overlay's prefix in MechFigs)", "prefix " .. tostring(K.prefix) .. ", overlay " .. tostring(K.oname))
    end
end
function S.carStage(K)
    S.theme("dark", S.was.accent)
    local ww = RT.ww()
    S.hold(ww)
    S.ptX, S.ptY = S.OFF, S.OFF
    S.ptrOn(S.panel())
    local s = S.st()
    if s then
        K.coll = s.collapsed
        s.collapsed = {}
        s.scrollY, s.cardScroll = 0, 0
    end
    S.cardShut()
    S.stageCar(K)
end
function S.carTheme(K, TH)
    local lab = K.lab .. " in " .. TH.say
    Q.step(2, function() if not K.off then S.theme(TH.key, S.was.accent); S.ptrOn(S.panel()) end end)
    Q.waitMs(900)
    Q.step(1, function() if not K.off then S.recOn("car", S.panel()) end end)
    Q.step(1, function()
        local R = S.recOff("car")
        if not K.off then S.carRead(K, R, lab, TH.key == "dark") end
    end)
    S.shotQ("dz_car_" .. K.kind .. "_" .. TH.tag .. "_" .. S.sz(), "the Vehicle tab on the " .. K.kind .. " in " .. TH.say
        .. ": a brake at 100, a spring at 50, the " .. (K.trailer and "rear brake" or "battery") .. " at 10"
        .. (K.trailer and "" or ", the windshield chipped, a side window at 10, a window taken out"), function() return K.off end)
end
function S.carAccent(K)
    Q.step(2, function() if not K.off then S.theme("dark", S.otherAccent()); S.ptrOn(S.panel()) end end)
    Q.waitMs(900)
    Q.step(1, function() if not K.off then S.recOn("car", S.panel()) end end)
    Q.step(1, function()
        local R = S.recOff("car")
        if not K.off then S.carRead(K, R, K.lab .. " in Dark with the accent " .. tostring(ZeD.currentAccent), false) end
    end)
    S.shotQ("dz_car_" .. K.kind .. "_accent_" .. S.sz(), "the Vehicle tab on the " .. K.kind .. " in Dark with the accent changed",
        function() return K.off end)
    Q.step(2, function() S.theme("dark", S.was.accent) end)
end
function S.carEnd(K)
    S.recOff("car")
    S.recOff("lit")
    if S.L then S.loopEnd(false) end
    S.cardShut()
    local s = S.st()
    if s and K.coll then s.collapsed = K.coll; K.coll = nil end
    if s then s.scrollY, s.cardScroll = 0, 0 end
    if S.car and K.kept then S.unstageCar(K) end
    S.ptrOff()
    S.unholdAll()
    pcall(RT.worldTab, "loot")
    S.carAway()
end
function S.buildCar(K)
    K.lab = "Vehicle tab, " .. K.kind
    Q.step(5, function()
        if S.dead then K.off = true; return end
        K.e0 = S.errN()
        S.car, S.carWhy = nil, nil
        local tok = {}
        S.carTok = tok
        if not ZEDQA_CAR_WAIT then S.carWhy = "the prelude's car helpers are not loaded"; return end
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "dz_look") end
        ZEDQA_CAR_WAIT(K.script, "dz_look", function(v)
            if tok.gaveUp then if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v) end; return end
            S.car = { v = v, K = K }
            S.gone[#S.gone + 1] = v
        end, function(why) S.carWhy = why end, 4000)
    end)
    S.wait(60000, function() return K.off or S.car ~= nil or S.carWhy ~= nil end, function()
        if K.off or S.car then return end
        if S.carTok then S.carTok.gaveUp = true end
        K.off = true
        Q.skip(K.lab, "the " .. K.script .. " did not spawn ready on the strip: " .. tostring(S.carWhy or "no ready car in 60 s"))
    end)
    Q.step(5, function() if not K.off then S.carOpen(K) end end)
    S.wait(8000, function() return K.off or S.carTabReady() end, function(ok)
        if K.off then return end
        if not ok then
            K.off = true
            local ww = RT.ww()
            Q.check(false, K.lab .. ": the Vehicle tab shows its diagram (staging)", "tab " .. tostring(ww and ww._activeTab))
        end
    end)
    Q.step(2, function() if not K.off then S.carStage(K) end end)
    Q.waitMs(900)
    for _, TH in ipairs(S.THEMES) do S.carTheme(K, TH) end
    if K.accent then S.carAccent(K) end
    Q.step(3, function() if not K.off then S.theme("dark", S.was.accent); S.ptrOn(S.panel()) end end)
    Q.waitMs(700)
    S.loopQ(K, "mouse")
    S.loopQ(K, "pad")
    Q.step(3, function() S.carEnd(K) end)
    S.wait(6000, function() return not (S.car and S.carLive(S.car.v)) end, function(ok)
        if not S.car then return end
        local e1 = S.errN()
        Q.check(ok, K.lab .. ": the vehicle removed after its run (its conditions put back first)")
        if K.e0 and e1 then Q.check(e1 == K.e0, K.lab .. ": no new Lua error in its run", (e1 - K.e0) .. " new") end
    end)
end

-- ===================================================================== the belt and the hotbar (bl_side.lua's)
function S.hud() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
function S.hb() local h = nil; pcall(function() h = ZeD.Belt.hotbar(S.pn) end); return h end
function S.drawnOk() local hud = S.hud(); return hud ~= nil and hud._drawn == true end
function S.slots() local hb = S.hb(); return (hb and hb.availableSlot) or {} end
function S.attached(i) local hb = S.hb(); return hb and hb.attachedItems and hb.attachedItems[i] or nil end
function S.idxOf(t)
    for i, sl in ipairs(S.slots()) do if sl.slotType == t then return i end end
    return nil
end
function S.box(t)
    local hud = S.hud()
    for _, b in ipairs((hud and hud._boxes) or {}) do
        if b.kind == "slot" and b.s and b.s.slot and b.s.slot.slotType == t then return b end
    end
    return nil
end
function S.boxName(b)
    if b.kind == "slot" then return "slot " .. tostring(b.s and b.s.slot and b.s.slot.slotType) end
    if b.kind == "hand" then return "hand " .. tostring(b.which) .. (b.peek and " (peeking)" or "") end
    if b.kind == "speed" then return "speed key " .. tostring(b.n) end
    return tostring(b.kind) .. (b.id and (" " .. tostring(b.id)) or "")
end
function S.typesText()
    local out = {}
    for i, sl in ipairs(S.slots()) do
        local it = S.attached(i)
        out[#out + 1] = i .. " " .. tostring(sl.slotType) .. (it and (" (" .. S.itemShow(it) .. ")") or "")
    end
    return table.concat(out, ", ")
end
function S.allBoxes()
    for _, t in ipairs(S.BSLOTS) do if not S.box(t) then return false end end
    return true
end
function S.fh() local h = nil; pcall(function() h = ZeD.TM:getFontHeight(ZeD.T.fontF1) end); return h end
function S.wornList()
    local out = {}
    local wl = nil
    pcall(function() wl = S.p:getWornItems() end)
    if not wl then return out end
    pcall(function()
        for i = 0, wl:size() - 1 do
            local wi = wl:get(i)
            local it, loc = nil, nil
            if wi then it = wi:getItem(); loc = wi:getLocation() end
            if it and loc ~= nil then out[#out + 1] = { loc = loc, item = it } end
        end
    end)
    return out
end
function S.isWorn(it)
    for _, e in ipairs(S.wornList()) do if e.item == it then return true end end
    return false
end
function S.locOf(it)
    local loc = nil
    pcall(function()
        if it:IsInventoryContainer() then loc = it:canBeEquipped() end
        if loc == nil or loc == "" then loc = it:getBodyLocation() end
    end)
    if loc == "" then loc = nil end
    return loc
end
function S.refresh()
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    local hb = S.hb()
    if hb then pcall(function() hb:refresh() end) end
end
function S.wear(it)
    local loc = it and S.locOf(it) or nil
    if not loc then return false end
    pcall(function() S.p:setWornItem(loc, it) end)
    return S.isWorn(it)
end
function S.unwear(it)
    if not (it and S.isWorn(it)) then return end
    pcall(function() S.p:removeWornItem(it) end)
end
function S.give(ft)
    local it = RT.give(ft)
    if it then S.given[#S.given + 1] = it end
    return it
end
function S.isGiven(it)
    for _, g in ipairs(S.given) do if g == it then return true end end
    return false
end
function S.inInv(it) local y = false; pcall(function() y = S.p:getInventory():contains(it) end); return y end
function S.hands(pri, sec)
    pcall(function() S.p:setPrimaryHandItem(pri) end)
    pcall(function() S.p:setSecondaryHandItem(sec) end)
end
function S.orderSame()
    local sl = S.slots()
    if #sl ~= #S.was.slots then return false end
    for i, f in ipairs(S.was.slots) do if not (sl[i] and sl[i].slotType == f.t) then return false end end
    return true
end
-- the slots in the found order, then his items on their found slots (bl_side.lua's hotbarBack)
function S.hotbarBack()
    local hb = S.hb()
    if not (hb and S.was.slots) then return end
    if not S.orderSame() then
        S.reordered = true
        local on = {}
        for _, it in pairs(hb.attachedItems or {}) do on[#on + 1] = it end
        for _, it in ipairs(on) do pcall(function() hb:removeItem(it, false) end) end
        local cur, list, used = {}, {}, {}
        for _, sl in ipairs(hb.availableSlot or {}) do cur[sl.slotType] = sl end
        for _, f in ipairs(S.was.slots) do
            local sl = cur[f.t]
            if not sl then pcall(function() local d = hb:getSlotDef(f.t); if d then sl = { slotType = d.type, name = d.name, def = d } end end) end
            if sl then list[#list + 1] = sl; used[f.t] = true end
        end
        for _, sl in ipairs(hb.availableSlot or {}) do if not used[sl.slotType] then list[#list + 1] = sl end end
        hb.availableSlot = list
        pcall(function() hb:savePosition() end)
    end
    for i, f in ipairs(S.was.slots) do
        local sl = hb.availableSlot[i]
        if f.item and sl and sl.slotType == f.t and hb.attachedItems[i] ~= f.item then
            pcall(function()
                if f.item:getAttachedSlot() > -1 then hb:removeItem(f.item, false) end
                local there = hb.attachedItems[i]
                if there then hb:removeItem(there, false) end
                if S.inInv(f.item) then hb:attachItem(f.item, sl.def.attachments[f.item:getAttachmentType()], i, sl.def, false) end
            end)
        end
    end
    pcall(function() hb:reloadIcons() end)
end
-- the belt's own pointer reads parked (bl_side.lua's)
function S.bPark(on)
    if on then
        if S.bParked then return end
        local hud = S.hud()
        if not hud then return end
        S.bParked = { hud = hud, x = rawget(hud, "getMouseX"), y = rawget(hud, "getMouseY") }
        hud.getMouseX = function() return S.OFF end
        hud.getMouseY = function() return S.OFF end
        return
    end
    local P = S.bParked
    if not P then return end
    S.bParked = nil
    P.hud.getMouseX, P.hud.getMouseY = P.x, P.y
end

-- ===================================================================== one frame of the belt, recorded (bl_side.lua's)
function S.bArm()
    local hud = S.hud()
    if not (hud and ZeD_BeltHUD and type(ZeD_BeltHUD._prerender) == "function") then return false end
    S.brec, S.brecDone, S.brecErr = nil, false, nil
    S.bHud = hud
    if not S.bOrig then S.bOrig = ZeD_BeltHUD._prerender end
    ZeD_BeltHUD._prerender = S.bRecPre
    return true
end
function S.bRecPre(self)
    if self ~= S.bHud then return S.bOrig(self) end
    ZeD_BeltHUD._prerender = S.bOrig
    local rec = { list = {}, lamps = {}, bars = {} }
    S.brec = rec
    local raw = {}
    for _, fn in ipairs(S.BELT_FNS) do
        raw[fn] = rawget(self, fn) or false
        local orig = self[fn]
        if orig then self[fn] = S.recFn(rec, fn, orig) end
    end
    local A = ZeD.Atoms
    local bL, bF = A.drawLamp, A.drawFillBar
    A.drawLamp = function(panel, x, y, d, c, a)
        if panel == self then rec.lamps[#rec.lamps + 1] = { x = x, y = y, w = d, h = d } end
        return bL(panel, x, y, d, c, a)
    end
    A.drawFillBar = function(panel, x, y, w, ...)
        if panel == self then rec.bars[#rec.bars + 1] = { x = x, y = y, w = w } end
        return bF(panel, x, y, w, ...)
    end
    local ok, err = pcall(S.bOrig, self)
    for _, fn in ipairs(S.BELT_FNS) do
        if raw[fn] then self[fn] = raw[fn] else self[fn] = nil end
    end
    A.drawLamp, A.drawFillBar = bL, bF
    if not ok then S.brecErr = tostring(err) end
    S.brecDone = true
end
function S.bDisarm()
    if S.bOrig and ZeD_BeltHUD and ZeD_BeltHUD._prerender == S.bRecPre then ZeD_BeltHUD._prerender = S.bOrig end
end
function S.bReadQ(label, fn)
    Q.step(2, function()
        if not S.bOk then return end
        S.bPark(true)
        if not S.bArm() then S.brecErr = "the belt or its _prerender is missing"; S.brecDone = true end
    end)
    Q.waitFor(1, 300, function() return not S.bOk or S.brecDone == true end, function()
        if not S.bOk then return end
        S.bDisarm()
        if S.brecDone and S.brec and not S.brecErr then fn(S.brec)
        else Q.check(false, label .. ": one frame of the belt recorded", "done " .. tostring(S.brecDone) .. ", error " .. tostring(S.brecErr)) end
    end)
end

-- ===================================================================== the belt's reads
function S.findRect(rec, fn, x, y, w, h, a, c)
    for _, d in ipairs(rec.list) do
        if d.fn == fn and S.near(d.x, x) and S.near(d.y, y) and S.near(d.w, w) and S.near(d.h, h)
            and (a == nil or S.near(d.a, a, 0.02)) and (c == nil or S.sameCol(d, c)) then return d end
    end
    return nil
end
-- a round draw of color c at alpha a whose left edge is x0: the baked round picture (as wide as the box) or its rows
-- (a rect shorter than the box)
function S.roundDraw(rec, b, x0, c, a)
    for _, d in ipairs(rec.list) do
        if S.sameCol(d, c) and S.near(d.a, a, 0.02) and S.near(d.x, x0, 1) and d.y >= b.y - 1 and d.y <= b.y + b.h + 2 then
            if d.fn == "drawRect" then
                if d.h < b.h - 0.5 then return d end
            elseif d.fn == "drawTextureScaledAspect" and S.near(d.w, b.w, 1) then
                return d
            end
        end
    end
    return nil
end
function S.speedLit(b)
    local sp = nil
    pcall(function() sp = ZeD.Belt.speedNow() end)
    return sp ~= nil and (sp == b.n or (b.n == 4 and sp > 4))
end
function S.squareWhy(rec, b, u)
    local B, T = ZeD.Belt, ZeD.T
    local lit = b.kind == "speed" and S.speedLit(b)
    local fillC = lit and T.accent or B.PAPER
    local edgeC = lit and (T.accentBright or T.accent) or B.INK
    if b.kind == "pvp" and b.zone then edgeC = T.accent end
    local inHand = b.kind == "slot" and b.s and b.s.inHand
    local why = {}
    if not S.findRect(rec, "drawRect", b.x + b.w, b.y + u, u, b.h, 0.5, S.BLACK) then why[#why + 1] = "no shadow at the right" end
    if not S.findRect(rec, "drawRect", b.x + u, b.y + b.h, b.w - u, u, 0.5, S.BLACK) then why[#why + 1] = "no shadow at the bottom" end
    if not S.findRect(rec, "drawRect", b.x, b.y, b.w, b.h, 1, fillC) then why[#why + 1] = "no " .. (lit and "accent" or "paper") .. " fill" end
    if not inHand and not S.findRect(rec, "drawRectBorder", b.x, b.y, b.w, b.h, nil, edgeC) then why[#why + 1] = "no " .. (lit and "bright accent" or "ink") .. " edge" end
    if #why == 0 then return nil end
    return table.concat(why, ", ")
end
function S.roundWhy(rec, b, u)
    local B = ZeD.Belt
    local why = {}
    if S.findRect(rec, "drawRect", b.x, b.y, b.w, b.h, 1, B.PAPER) then why[#why + 1] = "a square paper fill" end
    if not S.roundDraw(rec, b, b.x, B.PAPER, 1) then why[#why + 1] = "no paper disc" end
    if not S.roundDraw(rec, b, b.x + u, S.BLACK, 0.5) then why[#why + 1] = "no round shadow one unit right and down" end
    if not S.roundDraw(rec, b, b.x, B.INK, 1) then why[#why + 1] = "no ink ring" end
    if #why == 0 then return nil end
    return table.concat(why, ", ")
end
function S.blocks(rec, lab)
    local hud = S.hud()
    local u = ZeD.T.hair or 1
    local bad, sq, rd, kinds = {}, 0, 0, {}
    for _, b in ipairs(hud and hud._boxes or {}) do
        local k = b.kind
        local why = nil
        if k == "hand" then
            rd = rd + 1
            why = S.roundWhy(rec, b, u)
        elseif k == "slot" or k == "extra" or k == "bag" or k == "speed" or k == "chat" or k == "pvp" then
            sq = sq + 1
            kinds[k] = (kinds[k] or 0) + 1
            why = S.squareWhy(rec, b, u)
        end
        if why then bad[#bad + 1] = S.boxName(b) .. " " .. S.rt(b) .. ": " .. why end
    end
    local said = {}
    for k, n in pairs(kinds) do said[#said + 1] = n .. " " .. k end
    Q.check(sq > 0 and rd == 2 and #bad == 0, lab .. ": every square box is a white block (the hard shadow at the right and bottom, the paper, the ink edge) and the two hands are round (a paper disc, a round shadow, an ink ring)",
        sq .. " square boxes (" .. table.concat(said, ", ") .. "), " .. rd .. " hands" .. ((#bad > 0) and ("; WRONG: " .. S.list(bad)) or ""))
end
-- the side tag at a box's top right (bl_side.lua's tagAt) in fill c
function S.tagAt(rec, b, fh, c)
    for _, d in ipairs(rec.list) do
        if d.fn == "drawRect" and S.near(d.y, b.y, 1) and S.near(d.h, fh, 1) and d.w < b.w / 2 + 1 and S.near(d.x + d.w, b.x + b.w, 1) and S.sameCol(d, c) then return d end
    end
    return nil
end
function S.inBox(d, b) return d.x >= b.x - 1 and d.y >= b.y - 1 and d.x < b.x + b.w and d.y < b.y + b.h end
function S.texIn(rec, b, it)
    local tex = nil
    if it then pcall(function() tex = it:getTex() end) end
    if not tex then return false end
    for _, d in ipairs(rec.list) do if d.tex == tex and S.inBox(d, b) then return true end end
    return false
end
function S.handBox(which)
    local hud = S.hud()
    for _, b in ipairs(hud and hud._boxes or {}) do if b.kind == "hand" and b.which == which then return b end end
    return nil
end
function S.tagsCheck(rec, lab)
    local B = ZeD.Belt
    local fh = S.fh()
    local why, said = {}, {}
    for _, t in ipairs(S.BSLOTS) do
        local b, sd = S.box(t), B.SIDE and B.SIDE[t]
        if b and sd == "R" then
            local tag = S.tagAt(rec, b, fh, B.SIDE_WHITE)
            local edge = nil
            for _, d in ipairs(rec.list) do
                if d.fn == "drawRectBorder" and S.near(d.x + d.w, b.x + b.w, 1) and S.near(d.y, b.y, 1) and S.near(d.h, fh, 1)
                    and d.w < b.w / 2 + 1 and S.sameCol(d, B.SIDE_BLACK, 0.015) then edge = d end
            end
            said[#said + 1] = t .. " R tag " .. S.rt(tag) .. " edge " .. S.rt(edge)
            if not (tag and edge) then why[#why + 1] = t .. ": the R tag " .. (tag and "has no ink edge" or "is not drawn as the white box") end
        elseif b and sd == "L" then
            local tag = S.tagAt(rec, b, fh, B.SIDE_BLACK)
            said[#said + 1] = t .. " L tag " .. S.rt(tag)
            if not tag then why[#why + 1] = t .. ": the L tag is not drawn as the black box" end
        elseif not b then why[#why + 1] = t .. ": no box" end
    end
    Q.check(#why == 0, lab .. ": the L tags are black boxes, the R tags white boxes with their ink edge", S.list(said) .. ((#why > 0) and ("; WRONG: " .. S.list(why)) or ""))
end
function S.marksCheck(rec, lab, stage)
    local B, T = ZeD.Belt, ZeD.T
    local hud = S.hud()
    S.tagsCheck(rec, lab)
    -- an empty slot's name in the ink at 0.6
    local why, said = {}, {}
    for _, t in ipairs(S.EMPTY_T) do
        local b = S.box(t)
        local found = nil
        if b and b.s and b.s.item == nil then
            for _, d in ipairs(rec.list) do
                if d.fn == "drawText" and S.inBox(d, b) and S.sameCol(d, B.INK) and S.near(d.a, 0.6, 0.02) then found = d end
            end
            if found then said[#said + 1] = t .. " \"" .. tostring(found.str) .. "\"" else why[#why + 1] = t .. ": no name in the dim ink" end
        else why[#why + 1] = t .. ": " .. (b and "not empty" or "no box") end
    end
    Q.check(#why == 0, lab .. ": an empty slot's name reads in the ink at 0.6", S.list(said) .. ((#why > 0) and ("; WRONG: " .. S.list(why)) or ""))
    -- the knife's strip, the lamp
    local kb, lb = S.box(S.KNIFE_T), S.box(S.LAMP_T)
    local strip, lamp = nil, nil
    for _, d in ipairs(rec.bars) do if kb and S.inBox(d, kb) then strip = d end end
    for _, d in ipairs(rec.lamps) do if lb and S.inBox(d, lb) then lamp = d end end
    Q.check(strip ~= nil and S.texIn(rec, kb, S.bItems.knife), lab .. ": the knife's slot shows its picture and its condition strip", "strip " .. S.rt(strip))
    Q.check(lamp ~= nil, lab .. ": the lit flashlight's lamp draws in its box (" .. S.LAMP_T .. ")", "lamp " .. S.rt(lamp) .. ", box " .. S.rt(lb))
    -- the speed keys, one in use
    local nS, lit = 0, {}
    for _, b in ipairs(hud and hud._boxes or {}) do
        if b.kind == "speed" then
            nS = nS + 1
            if S.findRect(rec, "drawRect", b.x, b.y, b.w, b.h, 1, T.accent) then lit[#lit + 1] = tostring(b.n) end
        end
    end
    if nS == 0 then Q.skip(lab .. ": the speed keys", "no speed key on this belt (a server, or the belt hides them)")
    else Q.check(#lit == 1, lab .. ": the speed keys, exactly one in use (the accent block)", nS .. " keys, lit: " .. S.list(lit)) end
    -- the hands
    local mb, ob = S.handBox("p"), S.handBox("s")
    if stage == "peek" then
        Q.check(mb ~= nil and ob ~= nil and ob.peek == true and S.texIn(rec, mb, S.bItems.axe),
            lab .. ": one item in both hands: its picture in the main hand, the off hand peeking from under it",
            "main " .. S.rt(mb) .. ", off " .. S.rt(ob) .. " peek " .. tostring(ob and ob.peek))
    else
        local ammo = false
        for _, b in ipairs(hud and hud._boxes or {}) do if b.kind == "ammo" then ammo = true end end
        Q.check(mb ~= nil and ob ~= nil and not ob.peek and ammo and S.texIn(rec, mb, S.bItems.pistol) and S.texIn(rec, ob, S.bItems.hammer),
            lab .. ": a pistol in the main hand with its ammo tab, a hammer in the off hand, both pictures drawn",
            "ammo tab " .. tostring(ammo) .. ", off hand peek " .. tostring(ob and ob.peek))
    end
end
function S.dragCheck(rec)
    local hud, B, T = S.hud(), ZeD.Belt, ZeD.T
    local items = { S.bItems.sd }
    local nFit, nNo, bad, said = 0, 0, {}, {}
    for _, b in ipairs(hud and hud._boxes or {}) do
        if b.kind == "slot" or b.kind == "hand" or b.kind == "extra" then
            local st = nil
            pcall(function() st = hud:_dropState(b, items) end)
            local round = b.kind == "hand"
            local ok
            if st == "fit" then
                nFit = nFit + 1
                if round then ok = S.roundDraw(rec, b, b.x, T.accent, 0.14) ~= nil and S.roundDraw(rec, b, b.x, T.accent, 1) ~= nil
                else ok = S.findRect(rec, "drawRect", b.x, b.y, b.w, b.h, 0.14, T.accent) ~= nil and S.findRect(rec, "drawRectBorder", b.x, b.y, b.w, b.h, 1, T.accent) ~= nil end
            else
                nNo = nNo + 1
                if round then ok = S.roundDraw(rec, b, b.x, B.INK, 0.45) ~= nil
                else ok = S.findRect(rec, "drawRect", b.x, b.y, b.w, b.h, 0.45, B.INK) ~= nil end
            end
            said[#said + 1] = S.boxName(b) .. " " .. tostring(st)
            if not ok then bad[#bad + 1] = S.boxName(b) .. " (" .. tostring(st) .. ")" end
        end
    end
    Q.check(nFit > 0 and nNo > 0 and #bad == 0, "Belt drag: a screwdriver dragged over the belt: the boxes that take it wash and edge in the accent, the others go grey under the ink at 0.45",
        nFit .. " take it, " .. nNo .. " do not: " .. S.list(said) .. ((#bad > 0) and ("; WRONG: " .. S.list(bad)) or ""))
    local kept = {}
    for _, b in ipairs(hud and hud._boxes or {}) do
        if (b.kind == "bag" or b.kind == "speed") and not S.findRect(rec, "drawRect", b.x, b.y, b.w, b.h, 0.45, B.INK) then kept[#kept + 1] = S.boxName(b) end
    end
    if #kept > 0 then Q.say("NOTE Belt drag: the bag and speed keys take no drop and stay paper during the drag (not greyed): " .. table.concat(kept, ", ")) end
end
function S.dragOn()
    local DS = ZeD.Molecules and ZeD.Molecules.DragState
    local it = S.bItems.sd
    if not (DS and it) then return false end
    local d = DS:new()
    d:beginPending({ it }, it, 0, 0)
    d:checkThreshold(400, 400)
    S.drag = d
    return ISMouseDrag ~= nil and ISMouseDrag.dragging ~= nil
end
function S.dragOff()
    if S.drag then pcall(function() S.drag:cancel() end); S.drag = nil end
    if ISMouseDrag then ISMouseDrag.dragging = S.was.drag end
end

-- ===================================================================== part B staging
function S.bStart()
    if S.dead then return end
    local ready = ZeD.Belt ~= nil and ZeD.Belt.getHUD ~= nil and ZeD.Belt.attach ~= nil and ZeD.Belt.PAPER ~= nil and ZeD.Belt.INK ~= nil
        and ZeD_BeltHUD ~= nil and type(ZeD_BeltHUD._prerender) == "function" and ZeD.Atoms.drawLamp ~= nil and ZeD.Atoms.drawFillBar ~= nil
        and ZeD.Molecules ~= nil and ZeD.Molecules.DragState ~= nil and S.hb() ~= nil and S.hud() ~= nil
    if not Q.check(ready, "Belt: the belt with Build's white blocks (ZeD.Belt.PAPER, INK), its hotbar and the drag state are loaded (staging)") then return end
    S.bOk = true
    S.shutAll()
    S.gear = {}
    local it = S.give(S.GEAR)
    S.gear[#S.gear + 1] = S.GEAR .. " worn " .. tostring(it ~= nil and S.wear(it))
    S.refresh()
    if not (S.idxOf("SmallBeltLeft") and S.idxOf("SmallBeltRight")) then
        local bt = S.give(S.BELT)
        S.gear[#S.gear + 1] = S.BELT .. " worn " .. tostring(bt ~= nil and S.wear(bt))
        S.refresh()
    end
end
function S.bClear(ok)
    if not S.bOk then return end
    if not Q.check(ok, "Belt staging: the worn gear gives the four side slots, each with a box on the belt, both windows shut",
        table.concat(S.gear or {}, ", ") .. "; hotbar: " .. S.typesText() .. "; windows shut " .. tostring(S.none()) .. ", the belt drawn " .. tostring(S.drawnOk())) then
        S.bOk = false
        return
    end
    local hb = S.hb()
    for _, t in ipairs(S.BSLOTS) do
        local i = S.idxOf(t)
        local it = i and S.attached(i) or nil
        if it and not S.isGiven(it) then
            S.his[#S.his + 1] = S.itemShow(it) .. " on " .. t
            pcall(function() hb:removeItem(it, false) end)
        end
    end
    Q.say("NOTE belt staged: " .. table.concat(S.gear or {}, ", ") .. "; his items off the side slots for the run: " .. S.list(S.his))
end
function S.bAttachQ(key, ft, t)
    Q.step(2, function()
        if not S.bOk then return end
        local it = S.give(ft)
        S.bItems[key] = it
        local i = S.idxOf(t)
        local ok = false
        if it and i then
            local okA, r = pcall(ZeD.Belt.attach, S.pn, it, i)
            ok = okA and r == true
        end
        if ok then S.queued = true end
        S.k.attach[#S.k.attach + 1] = ft .. " to " .. t .. " " .. (ok and "queued" or "REFUSED")
    end)
    S.wait(15000, function()
        if not S.bOk then return true end
        local i = S.idxOf(t)
        return i ~= nil and S.bItems[key] ~= nil and S.attached(i) == S.bItems[key]
    end, function(ok)
        if S.bOk then Q.check(ok, "Belt staging: " .. ft .. " on " .. t .. " through ZeD.Belt.attach (the game's attach)", S.list(S.k.attach) .. "; hotbar: " .. S.typesText()) end
    end)
end
function S.bStage()
    if not S.bOk then return end
    local kn, fl = S.bItems.knife, S.bItems.lamp
    if kn then pcall(function() kn:setCondition(math.floor(kn:getConditionMax() * 0.6)) end) end
    if fl then pcall(function() fl:setActivated(true) end) end
    S.bItems.axe = S.give("Base.WoodAxe")
    S.bItems.pistol = S.give("Base.Pistol")
    S.bItems.hammer = S.give("Base.Hammer")
    S.bItems.sd = S.give("Base.Screwdriver")
    S.bPark(true)
    S.hands(S.bItems.axe, S.bItems.axe)
    local lit = false
    if fl then pcall(function() lit = fl:isActivated() end) end
    Q.say("NOTE belt items: knife " .. tostring(kn ~= nil) .. ", flashlight lit " .. tostring(lit) .. ", axe " .. tostring(S.bItems.axe ~= nil)
        .. ", pistol " .. tostring(S.bItems.pistol ~= nil) .. ", hammer " .. tostring(S.bItems.hammer ~= nil) .. ", screwdriver " .. tostring(S.bItems.sd ~= nil)
        .. "; Lite " .. tostring(ZeD.Belt.simple and ZeD.Belt.simple()))
end
function S.beltTheme(TH)
    local lab = "Belt in " .. TH.say
    local sz = S.sz()
    local off = function() return not S.bOk end
    Q.step(2, function()
        if not S.bOk then return end
        S.theme(TH.key, TH.accent and S.otherAccent() or S.was.accent)
        S.hands(S.bItems.axe, S.bItems.axe)
    end)
    Q.waitMs(900)
    S.bReadQ(lab .. " (one item in both hands)", function(rec)
        S.blocks(rec, lab .. " (one item in both hands)")
        S.marksCheck(rec, lab .. " (one item in both hands)", "peek")
    end)
    S.shotQ("dz_belt_" .. TH.tag .. "_peek_" .. sz, "the belt in " .. TH.say .. ": a wood axe in both hands (the off hand peeks), the knife, the empty Belt and Web slots, the lit flashlight, the speed keys", off)
    Q.step(2, function()
        if not S.bOk then return end
        S.hands(S.bItems.pistol, S.bItems.hammer)
    end)
    Q.waitMs(700)
    S.bReadQ(lab .. " (a gun in hand)", function(rec)
        S.blocks(rec, lab .. " (a gun in hand)")
        S.marksCheck(rec, lab .. " (a gun in hand)", "gun")
    end)
    S.shotQ("dz_belt_" .. TH.tag .. "_" .. sz, "the belt in " .. TH.say .. ": a pistol in the main hand (its ammo tab), a hammer in the off hand, the knife, the empty Belt and Web slots, the lit flashlight, the speed keys", off)
end
function S.buildBelt()
    S.k.attach = {}
    Q.step(3, S.bStart)
    S.settle(300, 8000, function() return not S.bOk or (S.none() and S.drawnOk() and S.allBoxes()) end, function(ok) S.bClear(ok) end)
    Q.waitMs(400)
    S.bAttachQ("knife", "Base.HuntingKnife", S.KNIFE_T)
    S.bAttachQ("lamp", "Base.FlashLight_AngleHead", S.LAMP_T)
    Q.step(2, S.bStage)
    Q.waitMs(600)
    for _, TH in ipairs(S.BTHEMES) do S.beltTheme(TH) end
    -- the drag, in Dark with the found accent
    Q.step(2, function()
        if not S.bOk then return end
        S.theme("dark", S.was.accent)
        S.k.dragOn = S.dragOn()
    end)
    Q.waitMs(400)
    S.bReadQ("Belt drag", function(rec)
        if not Q.check(S.k.dragOn == true, "Belt drag: a drag of the screwdriver started (ISMouseDrag.dragging set by ZeD's DragState)") then return end
        S.dragCheck(rec)
    end)
    S.shotQ("dz_belt_drag_" .. S.sz(), "the belt while a screwdriver is dragged over it: the boxes that take it in the accent, the rest grey",
        function() return not (S.bOk and S.k.dragOn) end)
    Q.step(2, function() S.dragOff() end)
end

-- ===================================================================== start
function S.start()
    S.err0 = S.errN()
    local MT = ZeD and ZeD.MechanicsTab
    local ready = ZeD ~= nil and ZeD.T ~= nil and ZeD.T.px ~= nil and MT ~= nil and MT.getState ~= nil and MT.openFromAction ~= nil
        and MT.onClick ~= nil and MT.endLooks ~= nil and ZeD.MechFigs ~= nil and ZeD.MechFigs.layers ~= nil and ZeD.MechFigs.unions ~= nil
        and ZeD.applyTheme ~= nil and ZeD.Atoms ~= nil and ZeD.Atoms.statusColor ~= nil and S.F ~= nil and S.F.focusWhere ~= nil
        and S.F.qaButton ~= nil and S.F.dispatchJoypadDown ~= nil and S.F.claimFocus ~= nil and S.F.releaseFocus ~= nil
        and ZeD_WorldWindow ~= nil and ZeD_CharacterWindow ~= nil and ISCarMechanicsOverlay ~= nil
    if not Q.check(ready, "the Vehicle tab, its figures, the theme, the focus and the windows are loaded (staging)") then
        S.dead = true
        for _, K in ipairs(S.KINDS) do K.off = true end
        return
    end
    local w = S.was
    w.base, w.accent, w.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    w.speed = S.gameSpeed()
    pcall(function() w.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() } end)
    w.char, w.world = S.charOpen(), S.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    w.geo = { c = w.char and S.geo(cw) or nil, w = w.world and S.geo(ww) or nil }
    w.tab = { c = (w.char and cw) and (cw._activeTab or "loot") or nil, w = (w.world and ww) and (ww._activeTab or "loot") or nil }
    local md = S.md()
    w.ws = { had = md.ZeD_WinState ~= nil, v = S.copy(md.ZeD_WinState) }
    w.mdh = { had = md.hotbar ~= nil, v = S.copy(md.hotbar) }
    pcall(function() w.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil end)
    w.pri, w.sec = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    w.slots = {}
    for i, sl in ipairs(S.slots()) do w.slots[#w.slots + 1] = { t = sl.slotType, item = S.attached(i) } end
    w.worn = S.wornList()
    w.drag = ISMouseDrag and ISMouseDrag.dragging or nil
    w.gmx, w.gmy = getMouseX, getMouseY
    w.preB = ZeD_BeltHUD and ZeD_BeltHUD._prerender
    w.lamp, w.bar = ZeD.Atoms.drawLamp, ZeD.Atoms.drawFillBar
    w.recorded = true
    S.k.ids = {}
    -- the biggest figure, which sets the tab's zoom (the handoff: still 147 x 169)
    local mw, mh = 0, 0
    for _, u in pairs(ZeD.MechFigs.unions) do
        if u.w > mw then mw = u.w end
        if u.h > mh then mh = u.h end
    end
    Q.check(mw == 147 and mh == 169, "MechFigs: the biggest figure is still 147 x 169 (the tab's zoom holds)", mw .. " x " .. mh)
    local hu = ZeD.MechFigs.unions["horsetrailer_"]
    Q.check(hu ~= nil and hu.w == 120 and hu.h == 152, "MechFigs: the horse trailer's figure is 120 x 152 (the handoff's)", hu and (hu.w .. " x " .. hu.h) or "none")
    S.lock("kbm")
    if ZEDQA_LAYOUT_DEFAULT then pcall(ZEDQA_LAYOUT_DEFAULT, "dz_look") end
    if w.speed ~= 1 then S.speed(1) end
    Q.say("found: theme " .. tostring(w.base) .. " / " .. tostring(w.accent) .. " / " .. tostring(w.size) .. ", screen " .. S.sz()
        .. ", UI scale " .. tostring(ZeD.T.scale) .. ", input lock " .. tostring(S.lockWas) .. ", game speed " .. tostring(w.speed)
        .. ", windows " .. tostring(w.char) .. " / " .. tostring(w.world) .. ", hotbar " .. S.typesText() .. ", Lua errors so far " .. tostring(S.err0))
end

-- ===================================================================== put back
function S.backA()
    if S.L then S.loopEnd(false) end
    S.recAllOff()
    if S.F then
        pcall(S.F.qaButton, "A", nil, S.pn)
        pcall(function() if S.F.getFocusedWindow(S.pn) then S.F.releaseFocus(S.pn) end end)
    end
    S.cardShut()
    for _, K in ipairs(S.KINDS) do
        local s = S.st()
        if s and K.coll then s.collapsed = K.coll; K.coll = nil end
        if K.kept and #K.kept > 0 and S.car and S.car.K == K then S.unstageCar(K) end
    end
    S.ptrOff()
    S.unholdAll()
    S.carAway()
    S.park(false)
end
function S.backB1()
    S.bDisarm()
    S.bPark(false)
    S.dragOff()
    for _, it in ipairs(S.given) do pcall(function() if it:isActivated() then it:setActivated(false) end end) end
    if S.queued then pcall(function() ISTimedActionQueue.clear(S.p) end) end
    local hb = S.hb()
    if hb then
        for _, it in ipairs(S.given) do pcall(function() if it:getAttachedSlot() > -1 then hb:removeItem(it, false) end end) end
    end
    S.shutAll()
end
function S.backB2()
    local w = S.was
    if not w.recorded then return end
    if not S.none() then S.shutAll() end
    for _, it in ipairs(S.given) do S.unwear(it) end
    for _, e in ipairs(w.worn) do
        local now = nil
        pcall(function() now = S.p:getWornItem(e.loc) end)
        if now ~= e.item then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
    S.refresh()
    pcall(RT.takeBack)
    S.hotbarBack()
    S.hands(w.pri, w.sec)
    local md = S.md()
    if w.mdh.had then md.hotbar = S.copy(w.mdh.v) else md.hotbar = nil end
    if w.ws.had then md.ZeD_WinState = S.copy(w.ws.v) else md.ZeD_WinState = nil end
    if ZeD.currentBase ~= w.base or ZeD.currentAccent ~= w.accent or ZeD.currentSize ~= w.size then
        pcall(ZeD.applyTheme, w.base, w.accent, w.size)
    end
    if w.speed ~= nil and S.gameSpeed() ~= w.speed then S.speed(w.speed) end
    S.lock(false)
    if w.char and w.world then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn)
    elseif w.char then pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif w.world then pcall(ZeD_WorldWindow.open, S.pn) end
end
function S.backB3()
    local w = S.was
    if not w.recorded then return end
    if w.char then
        S.placeBack(RT.cw(), w.geo.c)
        if w.tab.c then pcall(RT.charTab, w.tab.c) end
    end
    if w.world then
        S.placeBack(RT.ww(), w.geo.w)
        if w.tab.w then pcall(RT.worldTab, w.tab.w) end
    end
    if ZEDQA_LAYOUT_BACK and w.snap and (w.char or w.world) then pcall(ZEDQA_LAYOUT_BACK, w.snap, "dz_look") end
    local pos = w.pos
    if pos and (math.abs(S.p:getX() - pos.x) > 1 or math.abs(S.p:getY() - pos.y) > 1 or math.floor(S.p:getZ()) ~= math.floor(pos.z)) then
        S.tpTo(pos.x, pos.y, pos.z)
        Q.say("back where he stood: " .. math.floor(pos.x) .. "," .. math.floor(pos.y) .. "," .. math.floor(pos.z))
    end
end
function S.finalHotbar()
    local w = S.was
    local hbad = {}
    local sl = S.slots()
    if #sl ~= #w.slots then hbad[#hbad + 1] = #sl .. " slots, found " .. #w.slots end
    for i, f in ipairs(w.slots) do
        if not (sl[i] and sl[i].slotType == f.t) then hbad[#hbad + 1] = "slot " .. i .. " is " .. tostring(sl[i] and sl[i].slotType) .. ", found " .. f.t end
        if S.attached(i) ~= f.item then hbad[#hbad + 1] = "slot " .. i .. " holds " .. tostring(S.attached(i) and S.itemShow(S.attached(i))) .. ", found " .. tostring(f.item and S.itemShow(f.item)) end
    end
    Q.check(#hbad == 0, "put back: the hotbar's slots in the found order, his items on their found slots", "hotbar now: " .. S.typesText() .. "; reordered " .. tostring(S.reordered == true) .. ((#hbad > 0) and ("; WRONG: " .. S.list(hbad)) or ""))
    local bad = {}
    for _, e in ipairs(w.worn) do
        local now = nil
        pcall(function() now = S.p:getWornItem(e.loc) end)
        if now ~= e.item then bad[#bad + 1] = S.itemShow(e.item) .. " not back on" end
    end
    for _, it in ipairs(S.given) do
        if S.isWorn(it) then bad[#bad + 1] = S.itemShow(it) .. " (the run's) still worn" end
        if S.inInv(it) then bad[#bad + 1] = S.itemShow(it) .. " (the run's) still in his inventory" end
    end
    Q.check(#bad == 0 and #S.wornList() == #w.worn, "put back: every worn item as found, the run's gear and items taken away", S.list(bad))
    local pri, sec = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    Q.check(pri == w.pri and sec == w.sec, "put back: his hands as found", "main " .. S.itemShow(pri) .. ", off " .. S.itemShow(sec))
end
function S.final()
    local w = S.was
    if not w.recorded then Q.skip("put back", "nothing was staged (the modules were not loaded)"); return end
    local left = 0
    for _, v in ipairs(S.gone) do if S.carLive(v) then left = left + 1 end end
    Q.check(left == 0, "put back: every vehicle the run spawned is gone from the world", left .. " left of " .. #S.gone)
    Q.check(ZeD.currentBase == w.base and ZeD.currentAccent == w.accent and ZeD.currentSize == w.size, "put back: the theme as found",
        tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
    S.finalHotbar()
    local clean = S.recCount() == 0 and S.ptr == nil and S.parked == nil and S.bParked == nil and #S.held == 0 and S.L == nil
        and getMouseX == w.gmx and getMouseY == w.gmy and (w.preB == nil or ZeD_BeltHUD._prerender == w.preB)
        and ZeD.Atoms.drawLamp == w.lamp and ZeD.Atoms.drawFillBar == w.bar and (ISMouseDrag == nil or ISMouseDrag.dragging == w.drag)
    Q.check(clean, "put back: no recorder, pointer read, window hold, belt wrapper or drag left",
        "recorders " .. S.recCount() .. ", drawer pointer " .. tostring(S.ptr ~= nil) .. ", belt pointer " .. tostring(S.bParked ~= nil)
        .. ", held " .. #S.held .. ", belt _prerender " .. tostring(w.preB == nil or ZeD_BeltHUD._prerender == w.preB) .. ", drag " .. tostring(ISMouseDrag and ISMouseDrag.dragging ~= nil))
    local cwo, wwo = S.charOpen(), S.worldOpen()
    Q.check(cwo == (w.char == true) and wwo == (w.world == true) and S.gameSpeed() == w.speed, "put back: the windows open or shut as found, the game speed as found",
        "Character " .. tostring(cwo) .. " (found " .. tostring(w.char) .. "), World " .. tostring(wwo) .. " (found " .. tostring(w.world)
        .. "), speed " .. tostring(S.gameSpeed()) .. " (found " .. tostring(w.speed) .. ")")
    local e1 = S.errN()
    if S.err0 and e1 then Q.check(e1 == S.err0, "the run made no new Lua error", (e1 - S.err0) .. " new (" .. e1 .. " now)")
    else Q.skip("the run made no new Lua error", "the game gives no error count here") end
    Q.say("vehicles: " .. S.list(S.k.ids or {}) .. "; pictures taken (" .. #S.pic .. "): " .. S.list(S.pic))
end

-- ===================================================================== the run
Q.step(5, S.start)
for _, K in ipairs(S.KINDS) do S.buildCar(K) end
S.buildBelt()

Q.mark()
Q.step(2, function() S.backA() end)
S.wait(6000, function() return not (S.car and S.carLive(S.car.v)) end, function(ok)
    if S.car and not ok then Q.say("NOTE the last vehicle is still in the world 6 s after it was sent away") end
end)
Q.step(2, function() S.backB1() end)
S.wait(5000, function() return S.none() end, function() S.backB2() end)
S.settle(300, 5000, function() return S.charOpen() == (S.was.char == true) and S.worldOpen() == (S.was.world == true) end, function() S.backB3() end)
Q.step(10, function() S.final() end)
Q.start()
