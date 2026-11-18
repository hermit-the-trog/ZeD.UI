-- ZeDUI/tools/qa/rt_pad.lua  (Nov 18 2026, QA): the release test's controller row (qa/RELEASE_TEST.md, rt_pad.lua).
-- Built on rt_kit.lua (the global RT). grep "ZEDQA rt_pad". No pictures.
-- No controller is plugged into the QA PC: ZeD's input mode is locked to the controller (Detector.setLockedMode, as
-- zedqa_pad_tooltip.lua holds it) and the presses go through ZeD's own pad path (FocusManager's dispatchJoypadDir /
-- dispatchJoypadDown), the game's wheel openers (ISDPadWheels.onDisplay*, ISBackButtonWheel:addCommands) and the
-- game's controller press (JoypadControllerData:onPressButtonNoFocus, with QuickChords.qaBumper for the bumper held).
--   focus     the Character window opened for the pad lands on the list's first item; the D-pad moves it
--   card      the pad's item card follows the focused item: on the landed item by frame 2, never the item before, no
--             flicker (zedqa_pad_tooltip.lua's probe: ZeD.Balloon.draw read from the card's layer)
--   wheels    each D-pad wheel (Left, Right, Up, Down) and Select opens, and a pick acts: Character > Tabs > Health,
--             World > Tabs > Loot, Social > Shout (the game's shout stood in for, so no noise), Here and now > Zoom > in,
--             ZeD > Moodles > another place
--   chord     RB + R3 on Crouch: the character crouches, and again stands
--   put back  with Put things back on, a drink from a bottle in a bag: the bottle goes back into the bag
--   place     the game's Place Item cursor: A (Overrides/PlaceItemPad.lua) places the item
--   map       the Controller map draws the pad (ZeD_PadFigure.lua)
-- Every surface: RT.bounds. Puts back: the input mode, the focus, the windows, the options (inventory view, moodles'
-- place, Put things back, auto-drink), the chords file, the zoom, the stats, the pointer, the stand-ins.
local Q = RT.make("rt_pad")
local S = { p = RT.p, pn = RT.pn, back = {}, extra = {} }
local Z = ZeD
local F = RT.focus()
local Det = Z.Input and Z.Input.Detector
local D, W = Z.DpadWheels, Z.Wheel
local CW = ZeD_CharacterWindow

function S.opt(o) local v = nil; pcall(function() v = o:getValue() end); return v end
function S.setOpt(o, v) if o and v then pcall(function() o:setValue(v) end) end end
function S.nm(it) local n = nil; if it then pcall(function() n = it:getDisplayName() end) end; return tostring(n or "nothing") end
function S.zoneOf(w, name)
    for _, z in ipairs(w and w._focusRing or {}) do if z.zone == name then return z end end
    return nil
end
function S.firstItem(z)
    for i, e in ipairs(z and z.elements or {}) do if e.item then return i, e end end
    return nil, nil
end
function S.release() if F then pcall(F.releaseFocus, S.pn) end end
function S.closeWheels()
    local st = D.state[S.pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[S.pn] = nil
    for _, m in ipairs({ getPlayerRadialMenu(S.pn), getPlayerBackButtonWheel(S.pn) }) do
        if m and m:isReallyVisible() then pcall(m.undisplay, m) end
    end
    W.qaPoint = nil
end
-- a top-level wheel opened the way the game opens it
function S.openWheel(dir)
    if dir == "select" then
        local w = getPlayerBackButtonWheel(S.pn)
        w:addCommands()
        w:addToUIManager(true)
        w:setVisible(true)
    else
        local fn = ({ left = "onDisplayLeft", right = "onDisplayRight", up = "onDisplayUp", down = "onDisplayDown" })[dir]
        ISDPadWheels[fn]({ player = S.pn, id = nil })
    end
end
function S.entry(level, pred)
    local st = D.state[S.pn]
    local lv = st and st.path[level or #st.path]
    for _, e in ipairs(lv and lv.entries or {}) do if pred(e) then return e end end
    return nil
end
function S.byName(name) return function(e) return tostring(e.name):find(name, 1, true) == 1 end end

-- ===================================================================== start
Q.step(10, function()
    S.home = { x = S.p:getX(), y = S.p:getY() }
    S.pairWas = RT.isOpen()
    RT.pairShut()
    S.release()
    if getGameSpeed() ~= 1 then if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end end
    Q.check(F ~= nil and F.dispatchJoypadDir ~= nil and Det ~= nil and D ~= nil and Z.QuickChords ~= nil and Z.PutBack ~= nil
        and Z.InvTip ~= nil and Z.PadFigure ~= nil and Z.ControllerMap ~= nil, "every pad module is loaded")
    S.lockWas = S.p:getModData().ZeD_Gamepad and S.p:getModData().ZeD_Gamepad.inputModeLock
    S.back.mode = true
    Det.setLockedMode("gamepad")
    Q.check(Det.getMode(S.pn) == "gamepad", "the input mode is held on the controller")
    S.invView = S.opt(Z.Settings.inventoryViewOption)
    S.back.view = true
    S.setOpt(Z.Settings.inventoryViewOption, 1)
    for _, ft in ipairs({ "Base.Pencil", "Base.Pen", "Base.Battery", "Base.Spoon", "Base.Fork", "Base.Eraser", "Base.Paperclip", "Base.Apple" }) do
        RT.give(ft)
    end
    -- (the window keeps the row it was on last; a fresh window has none, so the list is cleared of it here)
    local w = RT.cw()
    local z = S.zoneOf(w, "charMainInv")
    if z then z.focusedElementIdx = nil end
end)

-- ===================================================================== focus lands and moves
Q.step(10, function() pcall(CW.ensureBothOpenForGamepad, S.pn) end)
Q.step(30, function()
    local w = RT.cw()
    if not Q.check(w ~= nil and w:isVisible(), "focus: the windows open for the pad") then return end
    if w._activeTab ~= "loot" then Q.say("focus: the window opened on " .. tostring(w._activeTab) .. "; Loot picked"); pcall(CW.openTab, S.pn, "loot") end
    if F.getFocusedWindow(S.pn) ~= w then
        Q.say("focus: the open left the pad elsewhere (" .. tostring(F.getFocusedWindow(S.pn)) .. "); claimed for the Character window")
        F.claimFocus(w)
    end
end)
Q.step(10, function()
    local w = RT.cw()
    local z, el = F.getFocusedZone(w), F.getFocusedElement(w)
    local fi = S.firstItem(z)
    Q.check(F.getFocusedWindow(S.pn) == w, "focus: the Character window has the pad")
    Q.check(z ~= nil and z.zone == "charMainInv" and el ~= nil and el.item ~= nil and z.focusedElementIdx == fi,
        "focus: it lands on the list's first item", tostring(z and z.zone) .. " " .. tostring(z and z.focusedElementIdx) .. " " .. S.nm(el and el.item))
    S.item0, S.idx0 = el and el.item, z and z.focusedElementIdx
    RT.padDir("down", w)
    local z2, el2 = F.getFocusedZone(w), F.getFocusedElement(w)
    Q.check(el2 ~= nil and el2.item ~= nil and el2.item ~= S.item0 and z2 ~= nil and z2.zone == "charMainInv"
        and z2.focusedElementIdx == (S.idx0 or 0) + 1, "focus: D-pad Down moves to the next item", S.nm(el2 and el2.item))
    RT.padDir("up", w)
    local el3 = F.getFocusedElement(w)
    Q.check(el3 ~= nil and S.item0 ~= nil and el3.item == S.item0, "focus: D-pad Up moves back", S.nm(el3 and el3.item))
    RT.bounds(Q, "windows on the pad")
end)

-- ===================================================================== the pad's item card follows the focus
-- (zedqa_pad_tooltip.lua's probe: what the card's layer draws, read the frame after; a move every 3 drawn frames)
S.cur, S.last = {}, {}
S.drawWas = Z.Balloon.draw
S.back.draw = true
Z.Balloon.draw = function(pp, c, a, pref, opts, ...)
    if pp ~= nil and pp == Z.InvTip._layer then S.cur.card = (opts and opts.key) or true end
    return S.drawWas(pp, c, a, pref, opts, ...)
end
function S.finishMove(m)
    if m.i == 0 then return end
    local ok
    if m.expect == nil then ok = (m.shownAt == nil or m.shownAt > 2) and not m.sawPrev
    else ok = m.shownAt ~= nil and m.shownAt <= 2 and not m.sawPrev and not m.lost end
    m.results[#m.results + 1] = ok
    if not ok then
        Q.say(string.format("card move %d to %s: shown at frame %s%s%s", m.i, S.nm(m.expect), tostring(m.shownAt or "-"),
            m.sawPrev and ", the item before showed" or "", m.lost and ", it vanished" or ""))
    end
end
function S.move(m)
    S.finishMove(m)
    if m.i >= m.n then m.done = true; return end
    m.i = m.i + 1
    F.dispatchJoypadDir(m.win, "down", nil)
    local z = F.getFocusedZone(m.win)
    if not (z and z.zone == "charMainInv") then F.focusWhere(m.win, "charMainInv", function(e) return e.item ~= nil end) end
    local el = F.getFocusedElement(m.win)
    m.prev, m.expect = m.expect, el and el.item or nil
    m.f, m.shownAt, m.sawPrev, m.lost = 0, nil, false, false
end
function S.watchCard(m, card)
    m.f = m.f + 1
    local item = (card ~= nil and card ~= true) and card or nil
    if item ~= nil and m.prev ~= nil and item == m.prev and m.prev ~= m.expect then m.sawPrev = true end
    if m.expect ~= nil then
        if item == m.expect then
            if not m.shownAt then m.shownAt = m.f end
        elseif m.shownAt then
            m.lost = true
        end
    elseif item ~= nil and not m.shownAt then
        m.shownAt = m.f
    end
end
function S.frame()
    S.last, S.cur = S.cur, {}
    local m = S.m
    if not m or m.done then return end
    if m.i > 0 then S.watchCard(m, S.last.card) end
    if m.i == 0 or m.f >= 3 then
        local ok, e = pcall(S.move, m)
        if not ok then Q.say("card move error: " .. tostring(e)); m.done = true end
    end
end
Events.OnPreUIDraw.Add(S.frame)
Q.step(5, function()
    local w = RT.cw()
    if not w then return end
    F.claimFocus(w)
    local e = F.focusWhere(w, "charMainInv", function(x) return x.item ~= nil end)
    if not Q.check(e ~= nil, "card: the pad is on the list") then return end
    S.m = { win = w, n = 8, i = 0, f = 0, results = {} }
end)
Q.waitFor(1, 300, function() return S.m == nil or S.m.done end, function(ok)
    local m = S.m
    if not m then return end
    local good = 0
    for _, r in ipairs(m.results) do if r then good = good + 1 end end
    Q.check(ok and #m.results > 0 and good == #m.results,
        "card: on the landed item by frame 2 on every move, never the item before, no flicker", good .. " of " .. #m.results)
    RT.bounds(Q, "the pad's item card")
    S.m = nil
end)
Q.step(2, function()
    S.putDraw()
    S.release()
    RT.pairShut()
end)
function S.putDraw()
    if not S.back.draw then return end
    S.back.draw = nil
    Z.Balloon.draw = S.drawWas
    pcall(function() Events.OnPreUIDraw.Remove(S.frame) end)
end

-- ===================================================================== the D-pad wheels
-- Left: Character > Tabs > Health
Q.step(10, function()
    S.closeWheels()
    S.openWheel("left")
end)
Q.step(5, function()
    local st = D.state[S.pn]
    if not Q.check(st ~= nil and st.dir == "left" and st.menu and st.menu:isReallyVisible(), "left: the Character wheel opens") then return end
    Q.check(#(st.menu.slices or {}) >= 8, "left: the wheel has its slices", #(st.menu.slices or {}))
    RT.bounds(Q, "Character wheel")
    local tabs = S.entry(1, S.byName(Z.tr("UI_ZeD_Wheel_Tabs")))
    if not Q.check(tabs ~= nil, "left: Tabs is there") then return end
    D.enter(S.pn, tabs)
    st = D.state[S.pn]
    local last = st and st.menu and st.menu.slices and st.menu.slices[#st.menu.slices]
    Q.check(st and #st.path == 2 and last and W.isBack(last), "left: Tabs opens its wheel, Back last")
    local health = S.entry(nil, function(e) return e.key == "health" end)
    if Q.check(health ~= nil and not health.off, "left: Tabs has Health") then D.take(S.pn, health) end
    S.closeWheels()
end)
Q.step(40, function()
    local w = RT.cw()
    Q.check(w and w:isVisible() and w._activeTab == "health", "left: Health opens the Character window on Health", w and w._activeTab)
    S.release()
    RT.pairShut()
end)
-- Right: World > Tabs > Loot
Q.step(20, function()
    S.closeWheels()
    S.openWheel("right")
end)
Q.step(5, function()
    local st = D.state[S.pn]
    if not Q.check(st ~= nil and st.dir == "right" and st.menu and st.menu:isReallyVisible(), "right: the World wheel opens") then return end
    RT.bounds(Q, "World wheel")
    local tabs = S.entry(1, S.byName(Z.tr("UI_ZeD_Wheel_Tabs")))
    if not Q.check(tabs ~= nil, "right: Tabs is there") then return end
    D.enter(S.pn, tabs)
    local loot = S.entry(nil, function(e) return e.key == "loot" end)
    if Q.check(loot ~= nil and not loot.off, "right: Tabs has Loot") then D.take(S.pn, loot) end
    S.closeWheels()
end)
Q.step(40, function()
    local w = RT.ww()
    Q.check(w and w:isVisible() and w._activeTab == "loot", "right: Loot opens the World window on Loot", w and w._activeTab)
    S.release()
    RT.pairShut()
end)
-- Up: Social > Shout (the game's shout stood in for: the slice reaches it, and nothing hears it)
Q.step(20, function()
    S.closeWheels()
    S.shoutWas = ISDPadWheels.onShout
    S.back.shout = true
    S.shouts = 0
    ISDPadWheels.onShout = function() S.shouts = S.shouts + 1 end
    S.openWheel("up")
end)
Q.step(5, function()
    local st = D.state[S.pn]
    if Q.check(st ~= nil and st.dir == "up" and st.menu and st.menu:isReallyVisible(), "up: the Social wheel opens") then
        RT.bounds(Q, "Social wheel")
        local e = S.entry(1, S.byName(getText("IGUI_Emote_Shout")))
        if Q.check(e ~= nil and not e.off, "up: Shout is live") then D.take(S.pn, e) end
    end
    Q.check(S.shouts == 1, "up: Shout runs the game's shout")
    S.closeWheels()
    S.putShout()
end)
function S.putShout()
    if not S.back.shout then return end
    S.back.shout = nil
    ISDPadWheels.onShout = S.shoutWas
end
-- Down: Here and now > Zoom > in
Q.step(10, function()
    S.closeWheels()
    S.zoomWas = getCore():getZoom(S.pn)
    S.openWheel("down")
end)
Q.step(5, function()
    local st = D.state[S.pn]
    if not Q.check(st ~= nil and st.dir == "down" and st.menu and st.menu:isReallyVisible(), "down: the Here and now wheel opens") then return end
    RT.bounds(Q, "Here and now wheel")
    local zoom = S.entry(1, S.byName(Z.tr("UI_ZeD_Wheel_Zoom")))
    if not Q.check(zoom ~= nil, "down: Zoom is there") then return end
    if zoom.off then Q.skip("down: Zoom > in", tostring(zoom.off)); S.closeWheels(); return end
    D.enter(S.pn, zoom)
    local zin = S.entry(nil, function(e) return e.run ~= nil end)
    if zin and zin.off then Q.skip("down: Zoom > in", tostring(zin.off)); S.closeWheels(); return end
    if Q.check(zin ~= nil, "down: Zoom has in") then D.take(S.pn, zin); S.zoomed = true end
    S.closeWheels()
end)
Q.step(60, function()
    if not S.zoomed then return end
    local z = getCore():getZoom(S.pn)
    Q.check(z ~= S.zoomWas, "down: Zoom > in changes the zoom", string.format("%.2f to %.2f", S.zoomWas or -1, z or -1))
    S.putZoom()
end)
function S.putZoom()
    if not S.zoomed then return end
    S.zoomed = nil
    pcall(function() getCore():doZoomScroll(S.pn, 1) end)
end
-- Select: ZeD > Moodles > another place
Q.step(20, function()
    S.closeWheels()
    S.moodWas = S.opt(Z.Settings.moodlePlaceOption)
    S.back.mood = true
    S.openWheel("select")
end)
Q.step(5, function()
    local st = D.state[S.pn]
    if not Q.check(st ~= nil and st.dir == "select" and st.menu and st.menu:isReallyVisible(), "select: the ZeD wheel opens") then return end
    RT.bounds(Q, "ZeD wheel")
    local mo = S.entry(1, S.byName(Z.tr("UI_ZeD_Settings_Moodles")))
    if not Q.check(mo ~= nil, "select: Moodles is there") then return end
    D.enter(S.pn, mo)
    S.moodWant = (S.moodWas == 2) and 1 or 2
    local lv = D.state[S.pn] and D.state[S.pn].path[2]
    local e = lv and lv.entries and lv.entries[S.moodWant]
    if Q.check(e ~= nil and e.run ~= nil, "select: Moodles lists the places") then D.take(S.pn, e) end
    S.closeWheels()
end)
Q.step(10, function()
    Q.check(S.opt(Z.Settings.moodlePlaceOption) == S.moodWant, "select: the pick moves the moodles", S.opt(Z.Settings.moodlePlaceOption))
    S.putMood()
end)
function S.putMood()
    if not S.back.mood then return end
    S.back.mood = nil
    S.setOpt(Z.Settings.moodlePlaceOption, S.moodWas or 1)
    if Z.Settings.save then pcall(Z.Settings.save) end
end

-- ===================================================================== a quick chord: RB + R3 on Crouch
S.CFILE, S.CSPARE = "ZeD_chords.txt", "ZeD_chords_spare.txt"
function S.readFile(name)
    local r = nil
    pcall(function() r = getFileReader(name, false) end)
    if not r then return nil end
    local t = {}
    pcall(function()
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
    end)
    pcall(function() r:close() end)
    return (#t > 0) and (table.concat(t, "\n") .. "\n") or ""
end
function S.writeFile(name, text)
    pcall(function() local w = getFileWriter(name, true, false); w:write(text or ""); w:close() end)
end
S.jd = { player = S.pn, id = 0, focus = nil }
S.ctl = setmetatable({ joypad = S.jd }, { __index = JoypadControllerData })
function S.press(bump, button)
    local C = Z.QuickChords
    C.qaBumper = bump
    local ok, err = pcall(JoypadControllerData.onPressButtonNoFocus, S.ctl, button)
    if not ok then Q.say("chord press: " .. tostring(err)) end
    pcall(JoypadControllerData.onReleaseButton, S.ctl, button)
    C.qaBumper = nil
end
Q.step(10, function()
    local C = Z.QuickChords
    S.chords = { file = S.readFile(S.CFILE), spare = S.readFile(S.CSPARE) }
    S.back.chords = true
    S.sneakWas = S.p:isSneaking()
    C.set("RB+R3", "now:2", { Z.tr("UI_ZeD_Wheel_HereNow"), Z.tr("UI_ZeD_Wheel_Crouch") })
    local e = C.resolve(S.p, S.pn, "now:2")
    Q.check(e ~= nil and e.name == Z.tr("UI_ZeD_Wheel_Crouch") and e.run ~= nil, "chord: RB + R3 is on Here and now > Crouch")
    Q.check(F.getFocusedWindow(S.pn) == nil, "chord: no window has the pad (the chord is the world's)")
    S.press("RB", Joypad.RStickButton)
end)
Q.step(10, function()
    Q.check(Z.QuickChords.lastChord == "RB+R3", "chord: the press is taken as RB + R3", Z.QuickChords.lastChord)
    Q.check(S.p:isSneaking() ~= S.sneakWas, "chord: the character crouches")
    S.press("RB", Joypad.RStickButton)
end)
Q.step(10, function()
    Q.check(S.p:isSneaking() == S.sneakWas, "chord: again, and it stands as it was")
    S.putChords()
end)
function S.putChords()
    if not S.back.chords then return end
    S.back.chords = nil
    if S.chords.file then S.writeFile(S.CFILE, S.chords.file) else S.writeFile(S.CFILE, "") end
    S.writeFile(S.CSPARE, S.chords.spare or "")
    pcall(Z.QuickChords.reload)
    pcall(function() S.p:setSneaking(S.sneakWas) end)
end

-- ===================================================================== put back after an action
Q.step(10, function()
    local PB = Z.PutBack
    S.pb = { opt = S.opt(Z.Settings.putBackOption), drink = getCore():getOptionAutoDrink() }
    pcall(function() S.pb.thirst = S.p:getStats():get(CharacterStat.THIRST) end)
    S.back.pb = true
    getCore():setOptionAutoDrink(false)
    S.setOpt(Z.Settings.putBackOption, 2)
    Q.check(PB.on(), "put back: the switch is on")
    pcall(function() S.p:StopAllActionQueue() end)
    S.bag = RT.give("Base.Bag_Schoolbag")
    S.bottle = S.bag and S.bag:getInventory():AddItem("Base.WaterBottle")
    if S.bottle then S.extra[#S.extra + 1] = S.bottle end
    local fc = S.bottle and S.bottle:getFluidContainer()
    if fc then pcall(function() fc:Empty(); fc:addFluid(FluidType.Water, fc:getCapacity() * 0.8) end) end
    pcall(function() S.p:getStats():set(CharacterStat.THIRST, 0.4) end)
    local g = Z.QuickWheel and Z.QuickWheel.group("drink")
    if Q.check(g ~= nil and S.bottle ~= nil, "put back: a bottle of water in a bag") then
        PB.last = nil
        g.act(S.p, S.bottle)
    end
end)
Q.waitFor(30, 2400, function()
    local q = ISTimedActionQueue.getTimedActionQueue(S.p)
    return not (q and q.queue and #q.queue > 0)
end, function(ok)
    local where = S.bottle and S.bottle:getContainer()
    Q.check(ok and S.bag ~= nil and where == S.bag:getInventory(), "put back: after the drink the bottle is back in the bag",
        where and tostring(where:getType()) or "nowhere")
    S.putPB()
end)
function S.putPB()
    if not S.back.pb then return end
    S.back.pb = nil
    pcall(function() S.p:StopAllActionQueue() end)
    S.setOpt(Z.Settings.putBackOption, S.pb.opt or 1)
    pcall(function() getCore():setOptionAutoDrink(S.pb.drink) end)
    if S.pb.thirst then pcall(function() S.p:getStats():set(CharacterStat.THIRST, S.pb.thirst) end) end
end

-- ===================================================================== placing an item by pad
Q.step(10, function()
    S.mug = RT.give("Base.Mug")
    if not S.mug then return end
    S.mouseWas = { getMouseX(), getMouseY() }
    S.back.place = true
    local x, y, z = S.p:getX(), S.p:getY(), S.p:getZ()
    pcall(function() Mouse.setXY(math.floor(isoToScreenX(S.pn, x + 1.5, y + 0.5, z)), math.floor(isoToScreenY(S.pn, x + 1.5, y + 0.5, z))) end)
    S.cursor = ISPlace3DItemCursor:new(S.p, { S.mug })
    getCell():setDrag(S.cursor, S.pn)
    Q.check(ISPlace3DItemCursor._zedPadA == true, "place: ZeD's A on the Place Item cursor is on")
end)
Q.waitFor(2, 180, function() return S.cursor ~= nil and S.cursor.canBeBuild == true end, function(ok)
    if not S.cursor then return end
    if not ok then
        Q.skip("place: A places the item", "the cursor found no free spot under the pointer next to the character")
        return
    end
    S.cursor:onJoypadPressButton(0, S.jd, Joypad.AButton)
    Q.check(S.cursor.build == true, "place: A on a valid spot sets the cursor to place")
    S.placing = true
end)
Q.waitFor(2, 1200, function() return not S.placing or (S.mug and S.mug:getWorldItem() ~= nil) end, function(ok)
    if not S.placing then return end
    Q.check(ok and S.mug:getWorldItem() ~= nil, "place: the item is placed in the world")
    S.putPlace()
end)
function S.putPlace()
    if not S.back.place then return end
    S.back.place = nil
    pcall(function() if getCell():getDrag(S.pn) then getCell():setDrag(nil, S.pn) end end)
    pcall(function()
        local wi = S.mug and S.mug:getWorldItem()
        if wi then
            local sq = wi:getSquare()
            if sq then sq:transmitRemoveItemFromSquare(wi) end
            pcall(function() wi:removeFromSquare() end)
            pcall(function() wi:removeFromWorld() end)
        end
    end)
    pcall(function() Mouse.setXY(S.mouseWas[1], S.mouseWas[2]) end)
end

-- ===================================================================== the Controller map draws the pad
Q.step(10, function()
    local PF = Z.PadFigure
    S.pfWas = PF.draw
    S.back.pf = true
    S.drawn = nil
    PF.draw = function(panel, x, y, k, set, st)
        local r = S.pfWas(panel, x, y, k, set, st)
        if panel == Z.ControllerMap.windows[S.pn] then S.drawn = { ok = r, x = x, y = y, k = k, set = set } end
        return r
    end
    Z.ControllerMap.open(S.pn)
end)
Q.step(20, function()
    local win = Z.ControllerMap.windows[S.pn]
    local d = S.drawn
    Q.check(win ~= nil and win:isReallyVisible(), "map: the Controller map opens")
    Q.check(d ~= nil and d.ok == true and (d.k or 0) >= 1, "map: it draws the pad from its textures", d and ("k " .. tostring(d.k) .. ", " .. tostring(d.set)))
    if d and win then
        local PF = Z.PadFigure
        Q.check(d.x >= 0 and d.x + PF.CW * d.k <= win:getWidth(), "map: the pad fits the window's width")
    end
    RT.bounds(Q, "Controller map")
    Z.ControllerMap.close(S.pn)
    S.putPF()
end)
function S.putPF()
    if not S.back.pf then return end
    S.back.pf = nil
    Z.PadFigure.draw = S.pfWas
    pcall(Z.ControllerMap.close, S.pn)
end

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.closeWheels()
    S.putDraw(); S.putShout(); S.putZoom(); S.putMood(); S.putChords(); S.putPB(); S.putPlace(); S.putPF()
    S.release()
    if S.back.view then S.back.view = nil; S.setOpt(Z.Settings.inventoryViewOption, S.invView) end
    if S.back.mode then
        S.back.mode = nil
        pcall(function()
            Det.setLockedMode(nil)
            if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
        end)
    end
    for _, it in ipairs(S.extra) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    if S.pairWas then RT.pairOpen() else RT.pairShut() end
end)
Q.step(10, function()
    Q.check(F.getFocusedWindow(S.pn) == nil or S.pairWas, "put back: the pad is the game's again")
    Q.check(Z.Balloon.draw == S.drawWas and ISDPadWheels.onShout == S.shoutWas, "put back: the stand-ins are gone")
    if S.moodWas then Q.check(S.opt(Z.Settings.moodlePlaceOption) == S.moodWas, "put back: the moodles' place") end
    Q.say("put back: the input mode lock is " .. tostring(S.lockWas) .. " again; the mode reads " .. tostring(Det.getMode(S.pn)))
end)
Q.start()
