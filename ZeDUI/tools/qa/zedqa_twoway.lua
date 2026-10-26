-- ZeDUI/tools/qa/zedqa_twoway.lua  (Oct 25 2026)
-- The two-way radios' faces in the radio tab and in full view (handoff
-- ZeDUI/HANDOFF_twoway_20261025.md, approved Oct 25 2026). With batteries in:
--   1. each portable set in the Character window (the five walkies and the
--      makeshift one in the hand, the ManPack on the back): its own face at the
--      plates' zoom, centred in its 220 panel at the content's left, the full
--      view button, power on lights the display; at the default window height
--      the body scrolls (the wheel scrolls it); the window then grown to show
--      the whole face for the picture
--   2. the controls on the ValuTech: VOL press and wheel, TUNE both halves and
--      a right-click, MEM (store; X names in the naming box), CH up / down
--      through the memories, push to talk (the TX lamp and TX OK / MIC OFF);
--      on the Tactical MUTE, SCAN and LAMP (5 s); the toy has no memories
--   3. full view: the header button opens it centre right, frameless, the
--      controls work in it, MEM held names, it drags and keeps its place
--      (modData), a click on the face away from the controls opens it, the
--      button, B and Escape close it, and so does the radio leaving the hands
--   4. the controller: in the tab (up on VOL turns it, right walks on, A on
--      CH up, X on MEM, A on the full view button) and in full view (its
--      prompt strip, the D-pad walks and turns, A presses, B closes)
--   5. the three ham sets placed beside the character in the World window:
--      each face centred across the drawer and whole in it, the dial's band
--      marker follows the frequency, RANGE, the army set's 1..6 memories, the
--      makeshift set's TALK / LISTEN toggle, AC on the grid (when the square
--      has power), full view of a ham and it closing when the set is taken away
--   6. an AM/FM radio still shows the chassis
-- Everything made is taken away; the hands, the back and the full view's
-- saved place are put back; both windows back on Loot.
-- Screenshots/zqa_tw_*.png; grep "ZEDQA tw".
local p = getPlayer()
local pn = p:getPlayerNum()
local TW, F, RT, O = ZeD.TwoWay, ZeD.TwoWayFull, ZeD.RadioTab, ZeD.RadioOps
local Focus, Det = ZeD.Input and ZeD.Input.Focus, ZeD.Input and ZeD.Input.Detector
local function say(s) print("ZEDQA tw " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what)
    if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_tw_" .. n .. ".png") end) end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() is true (at most max frames), then fn
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
if not (TW and F and RT and O) then say("ERR the two-way modules are not loaded"); say("DONE"); return end

local function root() return (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1 end
local K = ZeD.Px.k(root())
-- (a window can come back on a tab with its drawer shut: a click then opens it)
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and not win._drawerOpen) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return (w and goTab(w, w._tabStripPanel, id)) and true or false end
local function worldTab(id) local w = WW(); return (w and goTab(w, w._actionTabStrip, id)) and true or false end
-- the drawer has stopped growing (its width the same three frames running)
local settle = {}
local function settled(w)
    local e = math.floor(w and w._drawerEffW or -1)
    local s = settle[w] or { v = -2, n = 0 }
    settle[w] = s
    if e == s.v then s.n = s.n + 1 else s.v, s.n = e, 0 end
    return s.n >= 3 and e > 0
end

-- what the run changes, kept to put back
local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local back = p:getClothingItem_Back()
local popWas = p:getModData().ZeD_TwoWayFull
local winsWere = ZeD_CharacterWindow.isOpen()
local hWas = {}
local added, placed = {}, {}

local function newRadio(ft, charge)
    local it = p:getInventory():AddItem(ft)
    if not it then say("ERR could not make " .. ft); return nil end
    added[#added + 1] = it
    local dd = it:getDeviceData()
    if dd then
        dd:setHasBattery(true)
        dd:setPower(charge or 0.6)
        dd:setIsTurnedOn(false)
        dd:setMicIsMuted(true)
        dd:setDeviceVolume(0.5)                  -- room to turn it both ways
        local pc = dd:getDevicePresets()         -- (a new set comes with a memory of its own: start with none)
        if pc then pc:getPresets():clear() end
    end
    return it
end
local function hold(it, onBack)
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil); p:setClothingItem_Back(nil)
    if not it then return end
    if onBack then p:setClothingItem_Back(it) else p:setPrimaryHandItem(it) end
end

local function tw(w) return w and w._radioTw end
local function hitOf(t, id) for _, h in ipairs((t and t.hits) or {}) do if h.id == id then return h end end; return nil end
-- a click on a tab face's control (side "l" / "r": a knob's left / right half)
local function click(w, id, side)
    local h = hitOf(tw(w), id)
    if not h then say("ERR no control " .. id .. " on the face"); return false end
    local x = (side == "l" and h.x + 2) or (side == "r" and h.x + h.w - 3) or (h.x + math.floor(h.w / 2))
    RT.onClick(w, x, h.y + math.floor(h.h / 2))
    return true
end
local function vclick(v, id)
    for _, h in ipairs(v._hits or {}) do
        if h.id == id then
            v:onMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)); v:onMouseUp(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2))
            return true
        end
    end
    say("ERR no control " .. id .. " in full view")
    return false
end
local function dd(dev) return dev:getDeviceData() end
local function ps(dev, pid) return TW.plateState(TW.read(dev), pid) end
-- the naming box MEM opens (captured as it opens)
local lastBox = nil
local nameWas = TW.nameChannel
TW.nameChannel = function(...) local b = nameWas(...); lastBox = b; return b end
local function closeBox()
    if lastBox then pcall(function() lastBox:setVisible(false); lastBox:removeFromUIManager() end) end
    lastBox = nil
end

-- the checks on a face in the tab
local function faceChecks(w, pid, tag)
    local t = tw(w)
    check(t ~= nil and t.pid == pid, tag .. ": its own face, " .. pid .. " (got " .. tostring(t and t.pid) .. ")")
    if not t then return end
    local des = t.des
    check(t.k == K, tag .. ": drawn at the plates' whole zoom " .. K .. " (got " .. tostring(t.k) .. ")")
    if des.w < 220 then
        local x0 = math.floor((t.view.w - des.w * t.k) / 2)
        check(math.abs(t.face.x - x0) <= 1, tag .. ": centred in its panel (x " .. t.face.x .. ", want " .. x0 .. ")")
        local dw = math.floor(w._drawerEffW or 0)
        local pw = 220 * t.k + ZeD.T.sp.scrollbarW
        check(math.abs(dw - pw) <= 1, tag .. ": the tab is only as wide as the face's 220 panel (" .. dw .. " px; panel and scrollbar " .. pw .. ")")
    else
        local x0 = math.floor((t.view.w - des.w * t.k) / 2)
        check(math.abs(t.face.x - x0) <= 1, tag .. ": centred across the drawer (x " .. t.face.x .. ", want " .. x0 .. ")")
        check(t.view.w >= des.w * t.k, tag .. ": the drawer holds the whole set (" .. t.view.w .. " px for " .. des.w * t.k .. ")")
    end
    check(#t.hits == #des.hits, tag .. ": all " .. #des.hits .. " controls on the face (" .. #t.hits .. ")")
    check(w._radioFullZone ~= nil, tag .. ": the full view button in the header")
end

-- ===================================================================== setup
step(10, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    p:getModData().ZeD_TwoWayFull = nil          -- the first time: centre right
    F.close(pn)
    hold(nil)
    pcall(function() Mouse.setXY(20, 20) end)
    hWas.c, hWas.w = CW():getHeight(), WW():getHeight()
    say(string.format("screen %dx%d, root scale %.2f, plate zoom %d", getCore():getScreenWidth(), getCore():getScreenHeight(), root(), K))
end)

-- ===================================================================== 1. the portable sets
local PORTABLE = {
    { ft = "Base.WalkieTalkie2", pid = "walkie_valutech" }, { ft = "Base.WalkieTalkie1", pid = "walkie_toy" },
    { ft = "Base.WalkieTalkie3", pid = "walkie_premium" }, { ft = "Base.WalkieTalkie4", pid = "walkie_tactical" },
    { ft = "Base.WalkieTalkie5", pid = "walkie_army" }, { ft = "Base.WalkieTalkieMakeShift", pid = "walkie_makeshift" },
    { ft = "Base.ManPackRadio", pid = "walkie_manpack", back = true },
}
local cur = {}            -- the set in hand now: { it, pid, tag }
local valu, tac = nil, nil
local function bringUp(m)
    step(5, function()
        local it = newRadio(m.ft, 0.6)
        cur = { it = it, pid = m.pid, tag = m.pid }
        if m.pid == "walkie_valutech" then valu = it end
        if m.pid == "walkie_tactical" then tac = it end
        hold(it, m.back)
    end)
    waitFor(5, 150, function()
        local w = CW()
        local r = w and w._radios and w._radios[1]
        return r ~= nil and r.radioInstance == cur.it
    end, function() check(charTab("radio"), cur.tag .. ": the Character window's Radio tab opens") end)
    waitFor(5, 150, function() local t = tw(CW()); return t ~= nil and t.dev == cur.it and settled(CW()) end, function()
        faceChecks(CW(), cur.pid, cur.tag)
        click(CW(), "vol")                       -- VOL pressed: power
    end)
    step(15, function()
        local d = dd(cur.it)
        check(d:getIsTurnedOn(), cur.tag .. ": VOL pressed turns it on")
        local s = ps(cur.it, cur.pid)
        check(s.display ~= nil, cur.tag .. ": the display reads while on")
        local disp = s.display or {}
        say(cur.tag .. ": display " .. tostring(disp.big or disp.l1) .. " | " .. tostring(disp.line or disp.l2) .. " | " .. tostring(disp.batLabel) .. " " .. tostring(disp.batt))
        if disp.batLabel then check(disp.batLabel == ZeD.tr("UI_ZeD_Radio_Bat") and disp.batt == 3, cur.tag .. ": BAT with 3 bars at 60% charge") end
    end)
end

-- the ValuTech first, then the window's default height: the body scrolls
bringUp(PORTABLE[1])
step(5, function()
    local w, t = CW(), tw(CW())
    local sc = w._radioScroll
    local need = (2 * TW.PAD + t.des.h) * t.k + ZeD.T.px(22)
    say(string.format("valutech: body %d px tall, the face's body needs %d (window %d)", t.view.h, need, w:getHeight()))
    if need > t.view.h then
        check(sc and sc.visible, "valutech: at the default height the body scrolls")
        local x, y = t.face.x + 100 * t.k, t.view.y + 4
        local before = sc.scrollPos
        RT.onWheel(w, 1, x, y + 70 * t.k)                    -- not on a knob: the wheel scrolls
        check(sc.scrollPos > before, "valutech: the wheel off the knobs scrolls the body (" .. before .. " -> " .. sc.scrollPos .. ")")
        sc:setScrollPos(0)
    end
end)
step(10, function() shot("1a_valutech_default_height") end)
-- grow the windows so the whole face shows (for the pictures)
step(5, function()
    local w, t = CW(), tw(CW())
    local need = (2 * TW.PAD + t.des.h) * t.k + ZeD.T.px(22)
    if need > t.view.h then
        local add = need - t.view.h + 2
        CW():setHeight(CW():getHeight() + add); WW():setHeight(WW():getHeight() + add)
    end
end)
step(20, function()
    local w = CW()
    check(not (w._radioScroll and w._radioScroll.visible), "valutech: the grown window shows the whole face, no scrollbar")
    shot("1b_valutech_tab")
end)

-- ===================================================================== 2. the controls (ValuTech)
local chWas, volWas, f1, f2
step(5, function()
    local d = dd(valu)
    volWas = d:getDeviceVolume()
    local h = hitOf(tw(CW()), "vol")
    RT.onWheel(CW(), -1, h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2))   -- the wheel up over VOL
end)
step(5, function()
    local d = dd(valu)
    check(d:getDeviceVolume() > volWas + 0.05, string.format("VOL: the wheel turns the volume up (%.2f -> %.2f)", volWas, d:getDeviceVolume()))
    chWas = d:getChannel()
    click(CW(), "tune", "r")
end)
step(5, function()
    local d = dd(valu)
    check(d:getChannel() == chWas + O.STEP, "TUNE: a click on its right half tunes up a step (" .. chWas .. " -> " .. d:getChannel() .. ")")
    chWas = d:getChannel()
    click(CW(), "tune", "l")
end)
step(5, function()
    check(dd(valu):getChannel() == chWas - O.STEP, "TUNE: its left half tunes down a step")
    chWas = dd(valu):getChannel()
    local h = hitOf(tw(CW()), "tune")
    RT.onRightClick(CW(), h.x + 3, h.y + 3)
end)
step(5, function()
    check(dd(valu):getChannel() == chWas - O.STEP, "TUNE: a right-click turns it down")
    f1 = dd(valu):getChannel()
    click(CW(), "mem")                           -- MEM: acts on the release (the tab reads the mouse up)
end)
step(10, function()
    local pr = O.presetList(dd(valu))
    check(#pr == 1 and pr[1].freq == f1, "MEM: stores the frequency as channel 01 (" .. #pr .. " stored)")
    local s = ps(valu, "walkie_valutech")
    check(s.display and s.display.ch == "01", "the display shows CH 01 (" .. tostring(s.display and s.display.ch) .. ")")
    click(CW(), "tune", "r"); click(CW(), "tune", "r")
end)
step(5, function() f2 = dd(valu):getChannel(); click(CW(), "mem") end)
step(10, function()
    check(#O.presetList(dd(valu)) == 2, "MEM: a second channel stored")
    click(CW(), "chdn")
end)
step(5, function()
    check(dd(valu):getChannel() == f1, "CH down walks to channel 01")
    click(CW(), "chup")
end)
step(5, function()
    check(dd(valu):getChannel() == f2, "CH up walks to channel 02")
    check(dd(valu):getMicIsMuted(), "the mic starts muted")
    check(not ps(valu, "walkie_valutech").micLive, "the TX lamp is dark while the mic is muted")
    click(CW(), "mic")
end)
step(5, function()
    local s = ps(valu, "walkie_valutech")
    check(not dd(valu):getMicIsMuted(), "PUSH TO TALK latches the mic live")
    check(s.micLive and s.display and s.display.tx == O.word("txOk"), "the TX lamp lights and the display says " .. O.word("txOk") .. " (" .. tostring(s.display and s.display.tx) .. ")")
    click(CW(), "mic")
end)
step(5, function()
    check(dd(valu):getMicIsMuted() and ps(valu, "walkie_valutech").display.tx == O.word("micOff"), "pressed again it mutes the mic (" .. O.word("micOff") .. ")")
    RT.onRightClick(CW(), hitOf(tw(CW()), "mem").x + 2, hitOf(tw(CW()), "mem").y + 2)   -- MEM's second meaning: name it
end)
step(10, function()
    check(lastBox ~= nil and lastBox:isReallyVisible(), "MEM held (right-click): the naming box opens")
    closeBox()
    local idx = 2
    TW.onNamed({ chr = p, dev = valu }, { internal = "OK", parent = { entry = { getText = function() return "QA Farm" end } } }, idx)
    check(O.presetList(dd(valu))[2].name == "QA Farm", "naming it: channel 02 is QA Farm")
end)

-- ===================================================================== 3. full view (the ValuTech)
local v
step(5, function()
    local z = CW()._radioFullZone
    RT.onClick(CW(), z.x + 2, z.y + 2)
end)
step(20, function()
    v = F.get(pn)
    check(F.showing(pn) == valu and v and v:isReallyVisible(), "the header button opens full view on the radio")
    if not v then return end
    local des = ZeD.PhysPx.plates.walkie_valutech
    check(v.background == false and v.Type == "ZeD_TwoWayFull", "full view is the face alone, no window frame")
    check(v:getWidth() == des.w * K + 4 * K and v:getHeight() == des.h * K + 4 * K, "full view is the plate at the plate scale (" .. v:getWidth() .. "x" .. v:getHeight() .. ")")
    local sw = getPlayerScreenWidth(pn)
    local cx = v:getX() + v:getWidth() / 2
    check(math.abs(cx - (getPlayerScreenLeft(pn) + sw * 0.75)) <= 2, "the first time it sits centre right of the play area (centre x " .. cx .. ")")
    check(#v._hits == #des.hits, "every control is on it (" .. #v._hits .. ")")
    shot("3a_valutech_full_view")                -- (the picture is taken as the frame draws: nothing changes in this step)
end)
step(5, function()
    chWas = dd(valu):getChannel()
    vclick(v, "chdn")
end)
step(5, function()
    check(dd(valu):getChannel() ~= chWas, "a control in full view works (CH down)")
    local h
    for _, x in ipairs(v._hits) do if x.id == "mem" then h = x end end
    v:onMouseDown(h.x + 2, h.y + 2)              -- MEM held
end)
waitFor(5, 120, function() return lastBox ~= nil and lastBox:isReallyVisible() end, function()
    check(lastBox ~= nil and lastBox:isReallyVisible(), "MEM held in full view opens the naming box")
    closeBox()
    v:onMouseUp(0, 0)
end)
-- drag it by the face (a point that is no control)
-- (the pointer is played by standing in for getMouseX / getMouseY: in fullscreen the game reads the real one)
local dragFrom
local mouseX, mouseY = getMouseX, getMouseY
local fakeX, fakeY = 0, 0
local function fakeMouse(on)
    if on then getMouseX = function() return fakeX end; getMouseY = function() return fakeY end
    else getMouseX, getMouseY = mouseX, mouseY end
end
step(5, function()
    local x, y = 3 * K, math.floor(v:getHeight() / 2)
    check(TW.hitAt(v._hits, x, y) == nil, "the face's edge is not a control")
    dragFrom = { x = v:getX(), y = v:getY() }
    fakeX, fakeY = v:getX() + x, v:getY() + y
    fakeMouse(true)
    v:onMouseDown(x, y)
end)
step(3, function() fakeX, fakeY = fakeX - 400, fakeY - 120; v:onMouseMove(-400, -120) end)
step(3, function() v:onMouseUp(0, 0); fakeMouse(false) end)
step(5, function()
    local sv = p:getModData().ZeD_TwoWayFull
    check(v:getX() < dragFrom.x - 100, "dragging the face moves full view (" .. dragFrom.x .. " -> " .. v:getX() .. ")")
    check(sv ~= nil and sv.x ~= nil, "the place is kept on the character")
    local z = CW()._radioFullZone
    RT.onClick(CW(), z.x + 2, z.y + 2)           -- the button again: closed
end)
step(10, function()
    check(not F.showing(pn), "the header button closes full view")
    -- a click on the face away from its controls (between the knobs) opens it
    local t = tw(CW())
    local x, y = t.face.x + 100 * t.k, t.face.y + 70 * t.k
    check(TW.hitAt(t.hits, x, y) == nil, "the point between the knobs is no control")
    RT.onClick(CW(), x, y)
end)
step(10, function()
    check(F.showing(pn) == valu, "a click on the face away from the controls opens full view")
    local sv = p:getModData().ZeD_TwoWayFull
    local sc = ZeD.T.scale
    check(sv and math.abs(F.get(pn):getX() - sv.x * sc) <= 1 and math.abs(F.get(pn):getY() - sv.y * sc) <= 1, "it opens where it was dragged to")
    F.get(pn):onJoypadDown(Joypad.BButton)
end)
step(5, function()
    check(not F.showing(pn), "B closes full view")
    F.open(p, valu, CW())
end)
step(5, function()
    check(F.takeEscape() and not F.showing(pn), "Escape closes full view")
    F.open(p, valu, CW())
end)
step(5, function() hold(nil) end)                -- out of the hands
step(20, function()
    check(not F.showing(pn), "full view closes when the radio leaves the hands")
    hold(valu)
end)
waitFor(5, 150, function() local r = CW()._radios and CW()._radios[1]; return r ~= nil and r.radioInstance == valu end, function() charTab("radio") end)
waitFor(5, 150, function() local t = tw(CW()); return t ~= nil and t.dev == valu end, function() end)

-- ===================================================================== 4. the controller
local function el(w) return Focus.getFocusedElement(w) end
step(10, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.claimFocus(CW())
end)
step(10, function()
    local e = Focus.focusWhere(CW(), "charTabContent", function(x) return x.id == "radio:tw:vol" end)
    check(e ~= nil, "pad: the face's VOL is a stop in the tab")
    volWas = dd(valu):getDeviceVolume()
    Focus.dispatchJoypadDir(CW(), "up")
end)
step(5, function()
    check(dd(valu):getDeviceVolume() > volWas + 0.05, "pad: up on VOL turns it up")
    shot("4a_pad_tab_vol")
end)
step(5, function() Focus.dispatchJoypadDir(CW(), "right") end)
step(5, function()
    local e = el(CW())
    check(e and e.id == "radio:tw:tune", "pad: right from VOL walks to TUNE (" .. tostring(e and e.id) .. ")")
    local c = Focus.focusWhere(CW(), "charTabContent", function(x) return x.id == "radio:tw:chup" end)
    chWas = dd(valu):getChannel()
    if c and c.onActivate then c.onActivate(CW(), c) end
end)
step(5, function()
    check(dd(valu):getChannel() ~= chWas, "pad: A on CH up steps the channel")
    local m = Focus.focusWhere(CW(), "charTabContent", function(x) return x.id == "radio:tw:mem" end)
    if m and m.onContextMenu then m.onContextMenu(CW(), m) end
end)
step(10, function()
    check(lastBox ~= nil, "pad: X on MEM opens the naming box")
    closeBox()
    local f = Focus.focusWhere(CW(), "charTabContent", function(x) return x.id == "radio:full" end)
    if f and f.onActivate then f.onActivate(CW(), f) end
end)
step(10, function()
    v = F.get(pn)
    check(F.showing(pn) == valu, "pad: A on the full view button opens it")
    F.qaJoy = true                               -- as with a pad's focus: the prompt strip under the face
end)
waitFor(2, 90, function() return v:getHeight() > ZeD.PhysPx.plates.walkie_valutech.h * K + 4 * K and v.focusId ~= nil end, function()
    local des = ZeD.PhysPx.plates.walkie_valutech
    check(v:getHeight() > des.h * K + 4 * K, "pad: full view shows its controller strip")
    check(v.focusId ~= nil, "pad: full view lands on a control (" .. tostring(v.focusId) .. ")")
    v.focusId = "vol"
    volWas = dd(valu):getDeviceVolume()
    v:onJoypadDirDown()
end)
step(5, function()
    check(dd(valu):getDeviceVolume() < volWas - 0.05, "pad: down on VOL in full view turns it down")
    v:onJoypadDirRight()
end)
step(5, function()
    check(v.focusId == "tune", "pad: right walks to TUNE in full view (" .. tostring(v.focusId) .. ")")
    v.focusId = "mic"
    v:onJoypadDown(Joypad.AButton)
end)
step(5, function()
    check(not dd(valu):getMicIsMuted(), "pad: A on PUSH TO TALK in full view latches the mic")
    shot("4b_pad_full_view")
end)
step(5, function()
    v:onJoypadDown(Joypad.AButton)               -- muted again
    v:onJoypadDown(Joypad.BButton)
end)
step(5, function()
    check(not F.showing(pn), "pad: B closes full view")
    F.qaJoy = nil
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    Focus.releaseFocus()
end)

-- ===================================================================== 1b. the other portable sets
for i = 2, #PORTABLE do
    bringUp(PORTABLE[i])
    step(10, function() shot("1c_" .. cur.pid) end)
    if PORTABLE[i].pid == "walkie_toy" then
        step(2, function()
            local t = tw(CW())
            check(hitOf(t, "mem") == nil and hitOf(t, "chup") == nil and hitOf(t, "mic") ~= nil, "toy: no memories, its TALK button")
            check(ps(cur.it, "walkie_toy").display.big:find("MHZ") ~= nil, "toy: the drum shows the frequency")
        end)
    elseif PORTABLE[i].pid == "walkie_tactical" then
        step(2, function() O.mute(p, tac) end)
        step(5, function()
            check(dd(tac):getDeviceVolume() <= 0.001, "Tactical: MUTE silences it")
            click(CW(), "mute")
        end)
        step(5, function()
            check(dd(tac):getDeviceVolume() > 0.001, "Tactical: MUTE again gives the sound back")
            click(CW(), "scan")
        end)
        step(5, function()
            check(O._scan[O.keyOf(tac)] ~= nil, "Tactical: SCAN runs")
            click(CW(), "scan")
        end)
        step(5, function()
            check(O._scan[O.keyOf(tac)] == nil, "Tactical: SCAN again stops it")
            click(CW(), "lamp")
        end)
        local litAt
        step(5, function()
            litAt = getTimestampMs()
            check(ps(tac, "walkie_tactical").lampLit, "Tactical: LAMP lights the display")
            shot("2_tactical_lamp")
        end)
        waitFor(5, 1200, function() return getTimestampMs() - litAt > O.LAMP_MS + 300 end, function()
            check(not ps(tac, "walkie_tactical").lampLit, "Tactical: the lamp goes out after 5 s")
        end)
    elseif PORTABLE[i].pid == "walkie_makeshift" then
        step(2, function()
            local s = ps(cur.it, "walkie_makeshift")
            check(s.display and s.display.l1 and s.display.l1:sub(1, 2) == "CH", "makeshift: its character display reads CH.. (" .. tostring(s.display and s.display.l1) .. ")")
        end)
    elseif PORTABLE[i].pid == "walkie_manpack" then
        step(2, function()
            local r = CW()._radios[1]
            check(r and r.locationTag == "Back", "ManPack: on the back")
        end)
    end
end

-- ===================================================================== 6. an AM/FM radio keeps the chassis
step(5, function() hold(newRadio("Base.RadioRed", 0.6)) end)
waitFor(5, 150, function() local r = CW()._radios and CW()._radios[1]; return r and r.radioInstance == p:getPrimaryHandItem() end, function() end)
step(10, function()
    check(tw(CW()) == nil and CW()._radioPwrZone ~= nil, "an AM/FM radio still shows the chassis")
    hold(nil)
end)

-- ===================================================================== 5. the ham sets in the World window
local HAMS = { { ft = "Base.HamRadio1", pid = "ham_civilian", spr = "appliances_com_01_0" },
               { ft = "Base.HamRadio2", pid = "ham_army", spr = "appliances_com_01_8" },
               { ft = "Base.HamRadioMakeShift", pid = "ham_makeshift", spr = "appliances_com_01_56" } }
local hams = {}
local so = getSandboxOptions()
local elec = so and so:getOptionByName("ElecShutModifier")
local elecWas = elec and elec:getValue()
local hydroWas = getWorld():isHydroPowerOn()
step(5, function()
    -- free squares beside the character that the radio tab reaches (no wall between)
    local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local here = p:getCurrentSquare()
    local spots = {}
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x0 + d[1], y0 + d[2], z0)
        if sq and sq:isFree(false) and here and here:canReachTo(sq) then spots[#spots + 1] = sq end
    end
    say(#spots .. " free squares in reach")
    for i, h in ipairs(HAMS) do
        local sq = spots[i]
        local it = instanceItem(h.ft)
        if sq and it then
            local d = it:getDeviceData()
            d:setHasBattery(true); d:setPower(0.8); d:setIsTurnedOn(false); d:setMicIsMuted(true)
            local obj = IsoRadio.new(getCell(), sq, getSprite(h.spr))
            obj:setDeviceData(d)
            sq:AddTileObject(obj)
            placed[#placed + 1] = obj
            hams[h.pid] = obj
        end
    end
    say("placed " .. #placed .. " ham sets")
    if not WW():isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
waitFor(5, 150, function()
    local n = 0
    for _, r in ipairs(WW()._radios or {}) do for _, o in pairs(hams) do if r.radioInstance == o then n = n + 1 end end end
    return n == #placed
end, function() check(worldTab("radio"), "the World window's Radio tab opens on the placed sets") end)
local function showHam(pid)
    step(5, function()
        for i, r in ipairs(WW()._radios or {}) do if r.radioInstance == hams[pid] then WW()._radioIdx = i end end
    end)
    waitFor(5, 150, function() local t = tw(WW()); return t ~= nil and t.dev == hams[pid] and settled(WW()) end, function()
        faceChecks(WW(), pid, pid)
        if not dd(hams[pid]):getIsTurnedOn() then click(WW(), "vol") end
    end)
    step(15, function()
        check(dd(hams[pid]):getIsTurnedOn(), pid .. ": VOL pressed turns it on")
        local s = ps(hams[pid], pid)
        local disp = s.display or {}
        say(pid .. ": display " .. tostring(disp.big or disp.l1) .. " | " .. tostring(disp.line or disp.l2) .. " | range " .. tostring(s.range))
        check(s.display ~= nil, pid .. ": the display reads while on")
        shot("5_" .. pid .. "_tab")
    end)
end
showHam("ham_civilian")
-- the drawer's clip is a counter: every set has its clear, or what draws after the window (full view) is cut away
local clipCount, set0, clear0
step(2, function()
    local d = WW()._drawerPanel
    set0, clear0 = d.setStencilRect, d.clearStencilRect
    clipCount = { set = 0, clear = 0 }
    d.setStencilRect = function(self, ...) clipCount.set = clipCount.set + 1; return set0(self, ...) end
    d.clearStencilRect = function(self, ...) clipCount.clear = clipCount.clear + 1; return clear0(self, ...) end
end)
step(10, function()
    local d = WW()._drawerPanel
    d.setStencilRect, d.clearStencilRect = nil, nil
    check(clipCount.set > 0 and clipCount.set == clipCount.clear, "the drawer's clip is set and cleared in pairs with a ham showing ("
        .. clipCount.set .. " sets, " .. clipCount.clear .. " clears)")
end)
local bandWas
step(5, function()
    local s = ps(hams.ham_civilian, "ham_civilian")
    bandWas = s.bandF
    check(s.range == ZeD.tr("UI_ZeD_Radio_Range", "7.5"), "civilian ham: RANGE matches its transmit range (" .. tostring(s.range) .. ")")
    for _ = 1, 10 do TW.turn(p, hams.ham_civilian, "tune", 1, 25) end
end)
step(5, function()
    check(ps(hams.ham_civilian, "ham_civilian").bandF > bandWas, "civilian ham: the band marker follows the frequency up")
    local z = WW()._radioFullZone
    RT.onClick(WW(), z.x + 2, z.y + 2)
end)
step(20, function()
    check(F.showing(pn) == hams.ham_civilian, "civilian ham: full view opens")
    shot("5b_ham_civilian_full_view")
end)
step(5, function() F.close(pn) end)

-- ===================================================================== 5b. a small screen: the narrow ham faces
-- (mockup zed_ham_narrow_v1, approved Oct 25 2026) The World window held in as on a small screen: the drawer may
-- be no wider than 600 px beside the inventory, too narrow for a 400 set at 2x, so each set shows its narrow face in
-- a tab as narrow as a walkie's, every control still on it.
local maxWas, maxSet, liveWasN = nil, false, nil
step(5, function()
    local T = ZeD.T
    maxWas, maxSet = WW()._maxWinW, true
    WW()._maxWinW = T.px(36) * 2 + T.px(200) + 600
end)
local function narrowHam(pid)
    local npid = pid .. "_n"
    step(5, function()
        for i, r in ipairs(WW()._radios or {}) do if r.radioInstance == hams[pid] then WW()._radioIdx = i end end
    end)
    waitFor(5, 150, function() local t = tw(WW()); return t ~= nil and t.dev == hams[pid] and t.pid == npid and settled(WW()) end, function()
        local t = tw(WW())
        check(t and t.pid == npid, pid .. " on a small screen: its narrow face (" .. tostring(t and t.pid) .. ")")
        if not t then return end
        local dw = math.floor(WW()._drawerEffW or 0)
        local pw = 220 * K + ZeD.T.sp.scrollbarW
        check(math.abs(dw - pw) <= 1, pid .. ": the tab is a walkie's width (" .. dw .. " px, want " .. pw .. ")")
        check(t.k == K, pid .. ": the narrow face at the plates' whole zoom " .. K .. " (got " .. tostring(t.k) .. ")")
        local want = {}
        for _, h in ipairs(ZeD.PhysPx.plates[pid].hits) do want[h.id] = true end
        local n, same = 0, true
        for _, h in ipairs(t.hits) do n = n + 1; if not want[h.id] then same = false end end
        check(same and n == #ZeD.PhysPx.plates[pid].hits, pid .. ": every control of the wide set on the narrow face (" .. n .. ")")
        if not dd(hams[pid]):getIsTurnedOn() then click(WW(), "vol") end        -- VOL pressed on the narrow face: on
    end)
    step(10, function()
        check(dd(hams[pid]):getIsTurnedOn(), pid .. ": VOL on the narrow face turns it on")
        chWas = dd(hams[pid]):getChannel()
        click(WW(), "tune", "r")
    end)
    step(5, function()
        check(dd(hams[pid]):getChannel() == chWas + O.STEP, pid .. ": TUNE on the narrow face tunes up a step")
        local s = ps(hams[pid], npid)
        check(s.display ~= nil, pid .. ": the narrow face's display reads")
        shot("5n_" .. npid)
    end)
end
narrowHam("ham_civilian")
narrowHam("ham_army")
narrowHam("ham_makeshift")
step(2, function() liveWasN = ps(hams.ham_makeshift, "ham_makeshift_n").micLive; click(WW(), "mic") end)
step(5, function()
    check(ps(hams.ham_makeshift, "ham_makeshift_n").micLive ~= liveWasN, "narrow makeshift ham: TALK / LISTEN flips with the mic")
    click(WW(), "mic")                           -- back as it was
    WW()._maxWinW, maxSet = maxWas, false
    for i, r in ipairs(WW()._radios or {}) do if r.radioInstance == hams.ham_civilian then WW()._radioIdx = i end end
end)
waitFor(5, 150, function() local t = tw(WW()); return t ~= nil and t.pid == "ham_civilian" and settled(WW()) end, function()
    check(tw(WW()).pid == "ham_civilian", "with room again the wide set is back")
end)
showHam("ham_army")
local fa
step(5, function()
    fa = dd(hams.ham_army):getChannel()
    TW.secondary(p, hams.ham_army, "p1")         -- 1 held: stored
    for _ = 1, 3 do TW.turn(p, hams.ham_army, "tune", 1, 5) end
end)
step(5, function()
    check(dd(hams.ham_army):getChannel() ~= fa, "army ham: tuned away")
    click(WW(), "p1")
end)
step(5, function()
    check(dd(hams.ham_army):getChannel() == fa, "army ham: 1 goes straight to memory 1")
    -- on the grid: the world's power on for the check (the square must be in or beside a room)
    if elec then elec:setValue(99999); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(true)
end)
step(30, function()
    local d = dd(hams.ham_army)
    local disp = ps(hams.ham_army, "ham_army").display or {}
    if d:canBePoweredHere() then
        check(disp.batLabel == ZeD.tr("UI_ZeD_Radio_Ac") and disp.batt == 0, "army ham on the grid: AC, the bars dark (" .. tostring(disp.batLabel) .. ")")
    else
        say("army ham: no grid at this square (not in a room); AC not checked here, BAT shown: " .. tostring(disp.batLabel))
        check(disp.batLabel == ZeD.tr("UI_ZeD_Radio_Bat"), "army ham off the grid: BAT")
    end
    if elec and elecWas ~= nil then elec:setValue(elecWas); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(hydroWas)
    shot("5c_ham_army_tab")
end)
showHam("ham_makeshift")
local liveWas
step(5, function()
    liveWas = ps(hams.ham_makeshift, "ham_makeshift").micLive
    click(WW(), "mic")
end)
step(5, function()
    check(ps(hams.ham_makeshift, "ham_makeshift").micLive ~= liveWas, "makeshift ham: the TALK / LISTEN toggle flips with the mic")
    shot("5d_ham_makeshift_tab")
end)
step(5, function() F.open(p, hams.ham_makeshift, WW()) end)
step(10, function()
    check(F.showing(pn) == hams.ham_makeshift, "makeshift ham: full view opens")
    local obj = hams.ham_makeshift
    local sq = obj:getSquare()
    if sq then sq:transmitRemoveItemFromSquare(obj) end   -- taken away
end)
step(25, function() check(not F.showing(pn), "full view closes when the set is taken away") end)

-- ===================================================================== cleanup
step(10, function()
    getMouseX, getMouseY = mouseX, mouseY
    if maxSet then WW()._maxWinW = maxWas end
    F.close(pn)
    F.qaJoy = nil
    TW.nameChannel = nameWas
    closeBox()
    for _, obj in ipairs(placed) do
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    p:setPrimaryHandItem(prim); p:setSecondaryHandItem(sec); p:setClothingItem_Back(back)
    for _, it in ipairs(added) do
        local c = it:getContainer()
        if c then c:Remove(it) end
    end
    p:getModData().ZeD_TwoWayFull = popWas
    if hWas.c then CW():setHeight(hWas.c); WW():setHeight(hWas.w) end
    for _, w in ipairs({ CW(), WW() }) do
        local strip = (w == CW()) and w._tabStripPanel or w._actionTabStrip
        goTab(w, strip, "loot")
    end
    if winsWere ~= ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("cleanup: " .. #placed .. " sets and " .. #added .. " items taken away")
end)
step(10, function()
    say(string.format("%d passed, %d failed", nPass, nFail))
    say(nFail == 0 and "all checks passed" or (nFail .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then wait = 1; return end
        if not (ok and done) then say("ERR step " .. qi .. ": waited " .. s.max .. " frames") end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
