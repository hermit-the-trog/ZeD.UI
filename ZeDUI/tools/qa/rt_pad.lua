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
--             (Right and Down: every slice by name, Vehicle / Animal off with their reason)
--   reset     Select > Reset windows: the pair nudged, then back at the page spread
--   highlight Select > Controller highlight > hand, corners, wash, ants: each reads back, marks and draws
--   pointer   the mouse pointer: shown on the mouse, hidden on the pad, shown when the mouse moves, hidden by a press
--   routes    Designated zones and Investigate area open the World window's Animals and Foraging tabs
--   gesture   tap and flick, a trigger closing, Hold (A), Stick click (R3), Toggle mode (D-pad, A) on Crouch
--   chord     RB + R3 on Crouch: the character crouches, and again stands; a chord that cannot run says why
--   put back  with Put things back on, a drink from a bottle in a bag: the bottle goes back into the bag
--   place     the game's Place Item cursor: A (Overrides/PlaceItemPad.lua) places the item
--   map       Here and now > Help > Controller map opens it; it draws the pad (ZeD_PadFigure.lua) and its twelve rows
--   (Nov 18 2026, the ledger's proof pass, FEATURE_MAP.md) R3 grid view, Back in an inner wheel, the ZeD wheel's slices,
--             the mode read from a key press and the flip to the pad, a bumper tap on a wheel, a chord with a window
--             holding the pad, the D-pad going to that window, the moodles' hover balloon, the fishing rod's tension
-- Every surface: RT.bounds. Puts back: the input mode, the focus, the windows, the options (inventory view, moodles'
-- place, Put things back, auto-drink), the chords file, the zoom, the stats, the pointer, the stand-ins.
-- (Nov 23 2026, QA: the Loadouts split moves the "loadouts" option to the add-on ZeD-GUI: Loadouts, PZAPI.ModOptions
-- "ZeDLoadouts", its preset key "ZeDLoadouts.loadouts". The Lite pick's check reads it there where the add-on's
-- options are loaded, else ZeD's own; the add-on's combo boxes are kept and put back with ZeD's, S.keyOpt.)
local Q = RT.make("rt_pad")
local S = { p = RT.p, pn = RT.pn, back = {}, extra = {} }
-- an option by its keep key: "<id>" is ZeD's (ZeD_UI), "ZeDLoadouts.<id>" the add-on's (nil when it is not loaded)
function S.keyOpt(k)
    local own, oid = "ZeD_UI", k
    local a = string.match(k, "^ZeDLoadouts%.(.+)$")
    if a then own, oid = "ZeDLoadouts", a end
    local zo = nil
    pcall(function() zo = PZAPI.ModOptions:getOptions(own) end)
    return zo and zo.dict and zo.dict[oid] or nil
end
-- the Loadouts switch's preset key: the add-on's where its options are loaded, else ZeD's own from before the split
function S.loKey()
    local lo = nil
    pcall(function() lo = PZAPI.ModOptions:getOptions("ZeDLoadouts") end)
    return lo and "ZeDLoadouts.loadouts" or "loadouts"
end
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
-- the top level's names against a list (want[i] == false: any name); ok, and what was there
function S.namesAre(want)
    local st = D.state[S.pn]
    local list = st and st.path[1] and st.path[1].entries or {}
    local got, ok = {}, true
    for i, w in ipairs(want) do
        local e = list[i]
        got[#got + 1] = e and tostring(e.name) or "-"
        if not e or (w and tostring(e.name) ~= w) then ok = false end
    end
    return ok, table.concat(got, ", ")
end
-- a copy of a saved-state table (no Java objects in it; a few levels at most)
function S.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    local out = {}
    for k, v in pairs(t) do out[k] = (depth < 6) and S.copy(v, depth + 1) or v end
    return out
end

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
-- (Nov 18 2026, the ledger: Inventory grid view by pad) R3 on the list turns the container on show between List and
-- Grid (InventoryRenderer.padView); in the grid every item has its x in _itemRenderXMap. R3 again puts it back.
function S.gridState()
    local w = RT.cw()
    local c = w and w._mainContent
    if not c then return nil, false end
    local placed = true
    if c._gridCell ~= nil then
        for _, it in ipairs(c._flatItems or {}) do if not (c._itemRenderXMap and c._itemRenderXMap[it]) then placed = false end end
    end
    return c._gridCell ~= nil, placed
end
Q.step(2, function()
    S.gridWas = S.gridState()
    S.back.grid = true
    RT.padDown(Joypad.RStickButton, RT.cw())
end)
Q.step(6, function()
    local now, placed = S.gridState()
    Q.check(S.gridWas ~= nil and now ~= S.gridWas and (not now or placed),
        "grid view: R3 on the list turns its container between List and Grid", "grid " .. tostring(S.gridWas) .. " to " .. tostring(now) .. ", every item placed " .. tostring(placed))
    if now ~= S.gridWas then RT.padDown(Joypad.RStickButton, RT.cw()) end
end)
Q.step(6, function()
    S.back.grid = nil
    Q.check(S.gridState() == S.gridWas, "grid view: R3 again puts the container's view back", tostring(S.gridState()))
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
-- (Nov 18 2026, the ledger: inner wheel and Back) Character > Tabs, then D.back twice: one level up, then closed
Q.step(10, function()
    S.closeWheels()
    S.openWheel("left")
end)
Q.step(5, function()
    local tabs = S.entry(1, S.byName(Z.tr("UI_ZeD_Wheel_Tabs")))
    if not Q.check(tabs ~= nil, "inner wheel: Character has Tabs") then S.closeWheels(); return end
    D.enter(S.pn, tabs)
    local st = D.state[S.pn]
    local n1 = st and #st.path
    D.back(S.pn)
    st = D.state[S.pn]
    local n2 = st and #st.path
    D.back(S.pn)
    local gone = D.state[S.pn] == nil
    Q.check(n1 == 2 and n2 == 1 and gone, "inner wheel: Back goes up one level, then from the top closes the wheel",
        tostring(n1) .. ", " .. tostring(n2) .. ", closed " .. tostring(gone))
    S.closeWheels()
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
    -- (the eight slices in their order; Vehicle and Animal off with their reason when none is in reach)
    local okN, got = S.namesAre({ Z.tr("UI_ZeD_Wheel_Tabs"), Z.tr("UI_ZeD_Wheel_Map"), Z.tr("UI_ZeD_Wheel_Vehicle"),
        Z.tr("UI_ZeD_Wheel_Animal"), Z.tr("UI_ZeD_Wheel_CraftBuild"), Z.tr("UI_ZeD_Wheel_Search"),
        Z.tr("UI_ZeD_Wheel_LightsPower"), getText("IGUI_Zone_Name") })
    Q.check(okN and #st.path[1].entries == 8, "right: the eight slices, Tabs to Designated zones", got)
    local veh, ani = st.path[1].entries[3], st.path[1].entries[4]
    Q.check(veh ~= nil and (veh.off == nil or veh.off == Z.tr("UI_ZeD_Wheel_NoVehicle")),
        "right: Vehicle is live with a car in reach, else off with its reason", tostring(veh and veh.off or "live"))
    Q.check(ani ~= nil and (ani.off == nil or ani.off == Z.tr("UI_ZeD_Wheel_NoAnimal")),
        "right: Animal is live with an animal in reach, else off with its reason", tostring(ani and ani.off or "live"))
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
    -- (Sit to Help by name, then the light: its own name when one is in reach; Last Stand adds a ninth)
    local okN, got = S.namesAre({ Z.tr("UI_ZeD_Wheel_Sit"), Z.tr("UI_ZeD_Wheel_Crouch"), Z.tr("UI_ZeD_Wheel_AutoWalk"),
        Z.tr("UI_ZeD_Wheel_GameSpeed"), Z.tr("UI_ZeD_Wheel_Zoom"), Z.tr("UI_ZeD_Wheel_View"), Z.tr("UI_ZeD_Wheel_Help"), false })
    local n = #st.path[1].entries
    local light = st.path[1].entries[8]
    Q.check(okN and light ~= nil and light.icon == "bulb_on" and (n == 8 or n == 9), "down: Sit, Crouch, Auto walk, Game speed, Zoom, View, Help, Light", got)
    local inCar = Z.tr("UI_ZeD_Wheel_InVehicle")
    local footOk = true
    for i = 1, 3 do local e = st.path[1].entries[i]; if e and e.off == inCar then footOk = false end end
    Q.check(footOk, "down: on foot, Sit, Crouch and Auto walk are not off for a vehicle")
    Q.skip("down: Sit, Crouch and Auto walk off \"in vehicle\" in a car", "on foot here; rt_vehicles has the car")
    local zoom = S.entry(1, S.byName(Z.tr("UI_ZeD_Wheel_Zoom")))
    if not Q.check(zoom ~= nil, "down: Zoom is there") then return end
    if zoom.off then Q.skip("down: Zoom > in", tostring(zoom.off)); S.closeWheels(); return end
    D.enter(S.pn, zoom)
    local zin = S.entry(nil, function(e) return e.run ~= nil end)
    if zin and zin.off then Q.skip("down: Zoom > in", tostring(zin.off)); S.closeWheels(); return end
    if Q.check(zin ~= nil, "down: Zoom has in") then D.take(S.pn, zin); S.zoomed = true; S.zoomClosed = D.state[S.pn] == nil end
    S.closeWheels()
end)
Q.step(60, function()
    if not S.zoomed then return end
    local z = getCore():getZoom(S.pn)
    Q.check(z ~= S.zoomWas and S.zoomClosed == true, "down: Zoom > in changes the zoom and the wheel closes",
        string.format("%.2f to %.2f", S.zoomWas or -1, z or -1) .. ", closed " .. tostring(S.zoomClosed))
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
    -- (Nov 18 2026, the ledger: the thirteen slices by name, D.B.zed (beta 21: Style where Action bar was); the Lua console adds a fourteenth in -debug)
    local okZ, gotZ = S.namesAre({ Z.tr("UI_ZeD_Settings_BaseTheme"), Z.tr("UI_ZeD_Settings_AccentColor"), Z.tr("UI_ZeD_Settings_TextSize"),
        Z.tr("UI_ZeD_Settings_SeeThrough"), Z.tr("UI_ZeD_Settings_FocusStyle"), Z.tr("UI_ZeD_Settings_UiScale"),
        Z.tr("UI_ZeD_Settings_Moodles"), Z.tr("UI_ZeD_Settings_LookStyle"), Z.tr("UI_ZeD_Msg_Title"), Z.tr("UI_ZeD_Msg_BugReport"),
        Z.tr("UI_ZeD_Wheel_ResetWindows"), Z.tr("UI_ZeD_Options_GroupZed"), Z.tr("UI_ZeD_Settings_SafeMode") })
    local nZ = #st.path[1].entries
    Q.check(okZ and (nZ == 13 or nZ == 14), "select: the slices by name, Theme to Safe mode", gotZ)
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

-- Select: ZeD > Style > Lite sets the additions to Vanilla, as picking Lite on ZeD setup does (Nov 20 2026, the
-- complexity audit's BUG 1: the wheel set the Style and left the extras on, with no row left to turn them off).
-- Every ZeD combo box is kept first and put back after (the scripts after this one expect the additions on).
function S.putStyle()
    if not S.styleKeep then return end
    for k, v in pairs(S.styleKeep) do
        local o = S.keyOpt(k)
        if o and o.selected ~= v then pcall(function() o:setValue(v) end) end
    end
    S.styleKeep = nil
    if Z.Settings.reapplyFromOptions then pcall(Z.Settings.reapplyFromOptions) end
    if Z.Settings.save then pcall(Z.Settings.save) end
end
Q.step(10, function()
    S.closeWheels()
    S.styleKeep = {}
    local zo = nil
    pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end)
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.id then S.styleKeep[o.id] = o.selected end
    end
    -- (the add-on ZeD-GUI: Loadouts' combo boxes too: Lite sets its Loadouts switch to its preset's item, the split)
    local lo = nil
    pcall(function() lo = PZAPI.ModOptions:getOptions("ZeDLoadouts") end)
    for _, o in ipairs((lo and lo.data) or {}) do
        if o.type == "combobox" and o.id then S.styleKeep["ZeDLoadouts." .. tostring(o.id)] = o.selected end
    end
    S.styleFound = S.copy(S.styleKeep)   -- (as found, for the put-back check: the Light + Lite run starts in Lite)
    S.back.style = true
    S.setOpt(Z.Settings.lookStyleOption, 1)
    S.openWheel("select")
end)
Q.step(5, function()
    local sty = S.entry(1, S.byName(Z.tr("UI_ZeD_Settings_LookStyle")))
    if not Q.check(sty ~= nil, "select: Style is on the ZeD wheel") then return end
    D.enter(S.pn, sty)
    local lv = D.state[S.pn] and D.state[S.pn].path[2]
    local e = lv and lv.entries and lv.entries[2]
    if Q.check(e ~= nil and e.run ~= nil, "select: Style lists Full and Lite") then D.take(S.pn, e) end
    S.closeWheels()
end)
Q.step(10, function()
    local St = Z.Settings
    local on = {}
    -- (the Loadouts switch by its preset key: "ZeDLoadouts.loadouts" with the add-on since the split, else "loadouts")
    for _, id in ipairs({ "ammoBox", "readMarks", "readNext", "dimRead", "dashLamps", "moodleNotices", "messagesCatch", "messagesToast", "putBack", "sandboxInGame", S.loKey() }) do
        local o = S.keyOpt(id)
        if o and o.selected ~= 1 then on[#on + 1] = id .. "=" .. tostring(o.selected) end
    end
    Q.check(St.lite() == true, "select: the Style pick sets Lite", tostring(S.opt(St.lookStyleOption)))
    Q.check(#on == 0, "select: Lite picked on the wheel sets the additions to Vanilla, as ZeD setup does", table.concat(on, " "))
    S.back.style = nil
    S.putStyle()
end)
Q.step(10, function()
    -- (every kept combo box back as found, Style among them: Full or Lite, whichever the run is in, as rt_lite's put back checks)
    local bad = {}
    for id, v in pairs(S.styleFound or {}) do
        local o = S.keyOpt(id)   -- (ZeD's and, since the split, the add-on's)
        if o and o.selected ~= v then bad[#bad + 1] = id .. "=" .. tostring(o.selected) end
    end
    local was = S.styleFound and S.styleFound.lookStyle
    Q.check(was ~= nil and #bad == 0 and Z.Settings.lite() == (was == 2), "select: Style and the additions are put back",
        "Style " .. tostring(S.opt(Z.Settings.lookStyleOption)) .. ", as found " .. tostring(was) .. (#bad > 0 and (", off: " .. table.concat(bad, " ")) or ""))
end)

-- ===================================================================== Select > Reset windows
-- the pair nudged off its places, then the slice: both back at the page spread (Organisms.lua resetLayout: the
-- Character window's right edge a gap left of the screen's middle, the World window a gap right of it, both at the top).
-- Put back: each window's box, its accent and list width, and the saved places (resetLayout clears them).
S.RW_KEYS = { "minimumWidth", "_anchorRightEdge", "_lastSetX", "_baseInvW", "_invDrawerEffW", "_invDrawerTargetW",
    "_fitInvW", "_fitFromInvW", "_accentKey" }
function S.boxOf(w)
    local b = { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight(), f = {} }
    for _, k in ipairs(S.RW_KEYS) do b.f[k] = w[k] end
    return b
end
function S.putBox(w, b)
    if not (w and b) then return end
    for _, k in ipairs(S.RW_KEYS) do w[k] = b.f[k] end
    pcall(function() w:setWidth(b.w); w:setHeight(b.h); w:setX(b.x); w:setY(b.y) end)
    if Z.Settings.syncWindowAccent then pcall(Z.Settings.syncWindowAccent, w) end
end
Q.step(10, function()
    S.closeWheels()
    RT.pairOpen()
end)
Q.step(20, function()
    local cw, ww = RT.cw(), RT.ww()
    if not Q.check(cw ~= nil and ww ~= nil and cw:isVisible() and ww:isVisible(), "reset: the pair is open") then return end
    local md = S.p:getModData()
    local ws = md.ZeD_WinState
    S.rw = { c = S.boxOf(cw), w = S.boxOf(ww), had = ws ~= nil, cs = ws and S.copy(ws.char), ws = ws and S.copy(ws.world) }
    S.back.rw = true
    cw:setX(cw:getX() + 37); cw:setY(cw:getY() + 29)
    ww:setX(ww:getX() - 23); ww:setY(ww:getY() + 41)
    S.openWheel("select")
    local e = S.entry(1, S.byName(Z.tr("UI_ZeD_Wheel_ResetWindows")))
    if Q.check(e ~= nil and e.run ~= nil and not e.off, "reset: the ZeD wheel has Reset windows") then D.take(S.pn, e) end
    S.closeWheels()
    local sw, _, sl, stp = ZeD.screenOf(S.pn)
    local gap = Z.T.px(5)
    local mid = sl + math.floor(sw / 2)
    Q.check(cw:getY() == stp and ww:getY() == stp and cw:getX() + cw:getWidth() == mid - gap and ww:getX() == mid + gap,
        "reset: both windows back at their places, side by side at the top",
        "char " .. math.floor(cw:getX()) .. "," .. math.floor(cw:getY()) .. " " .. math.floor(cw:getWidth()) .. "x" .. math.floor(cw:getHeight())
        .. "; world " .. math.floor(ww:getX()) .. "," .. math.floor(ww:getY()) .. "; middle " .. math.floor(mid) .. ", gap " .. math.floor(gap))
end)
Q.step(10, function()
    RT.bounds(Q, "the pair after Reset windows")
    S.putRW()
end)
function S.putRW()
    if not S.back.rw then return end
    S.back.rw = nil
    S.putBox(RT.cw(), S.rw.c)
    S.putBox(RT.ww(), S.rw.w)
    S.release()
    RT.pairShut()
    -- (after the close, which saves what it shows: the places as they were saved before the reset)
    local md = S.p:getModData()
    if S.rw.had then
        md.ZeD_WinState = md.ZeD_WinState or {}
        md.ZeD_WinState.char = S.rw.cs
        md.ZeD_WinState.world = S.rw.ws
    end
end

-- ===================================================================== the controller highlight, each style
-- Picked as the pad picks it (Select > Controller highlight > the style), the pad on the Character window's list:
-- the style reads back, the window lays a mark and its overlay draws it with no error; wash turns the words to
-- textOnFocus on a stop that is not solid (mark returns true), the others never do; the hand stays on the screen
-- (its width left of the marked stop). ZeD.Focus.mark and drawOverlay are watched, not replaced.
S.HL = { "hand", "corners", "wash", "ants" }
S.HL_DRAWN = {
    hand = "highlight hand: picked, reads back, the focused stop marked and drawn with no error",
    corners = "highlight corners: picked, reads back, the focused stop marked and drawn with no error",
    wash = "highlight wash: picked, reads back, the focused stop marked and drawn with no error",
    ants = "highlight ants: picked, reads back, the focused stop marked and drawn with no error",
}
S.hl = { on = false }
function S.hlInstall()
    local FP = Z.Focus
    S.hlMarkWas, S.hlOvWas = FP.mark, FP.drawOverlay
    S.back.hl = true
    S.hlStyleWas = FP.style()
    FP.mark = function(panel, x, y, w, h, opts, rounded)
        local r = S.hlMarkWas(panel, x, y, w, h, opts, rounded)
        if S.hl.on then
            pcall(function()
                local win = (type(opts) == "table" and opts.win) or (Z.Atoms and Z.Atoms.windowOf and Z.Atoms.windowOf(panel)) or panel
                if win == RT.cw() and FP.isShowing(win, type(opts) == "table" and opts or nil) then
                    S.hl.marks = S.hl.marks + 1
                    if not (type(opts) == "table" and opts.solid) then
                        S.hl.plain = true
                        if r then S.hl.swap = true end
                    end
                    local ax = panel:getAbsoluteX() + x
                    if S.hl.ax == nil or ax < S.hl.ax then S.hl.ax = ax end
                end
            end)
        end
        return r
    end
    FP.drawOverlay = function(ov, win)
        if S.hl.on and (win or ov) == RT.cw() then S.hl.ov = S.hl.ov + 1 end
        local ok, err = pcall(S.hlOvWas, ov, win)
        if not ok then
            S.hl.err = tostring(err)
            error(err)
        end
    end
end
function S.putHL()
    if not S.back.hl then return end
    S.back.hl = nil
    S.hl.on = false
    Z.Focus.mark, Z.Focus.drawOverlay = S.hlMarkWas, S.hlOvWas
    if S.hlStyleWas and Z.Settings.setFocusStyle then pcall(Z.Settings.setFocusStyle, S.hlStyleWas) end
end
function S.hlPick(i)
    S.closeWheels()
    S.openWheel("select")
    local e = S.entry(1, S.byName(Z.tr("UI_ZeD_Settings_FocusStyle")))
    if not Q.check(e ~= nil and e.sub ~= nil, "highlight " .. S.HL[i] .. ": the ZeD wheel has Controller highlight") then S.closeWheels(); return end
    D.enter(S.pn, e)
    local lv = D.state[S.pn] and D.state[S.pn].path[2]
    local x = lv and lv.entries and lv.entries[i]
    if Q.check(x ~= nil and x.run ~= nil, "highlight " .. S.HL[i] .. ": the style is on its wheel") then D.take(S.pn, x) end
    S.closeWheels()
    local w = RT.cw()
    if w and F.getFocusedWindow(S.pn) ~= w then F.claimFocus(w) end
    RT.padDir("down", w)
    RT.padDir("up", w)
    S.hl = { on = true, marks = 0, ov = 0, plain = false, swap = false, ax = nil, err = nil }
end
function S.hlCheck(i)
    local key = S.HL[i]
    local h = S.hl
    h.on = false
    Q.check(Z.Focus.style() == key, "highlight " .. key .. ": the style reads back", Z.Focus.style())
    -- (one literal what-string per style, so the ledger can name each: FEATURE_MAP.md's Check column)
    Q.check(Z.Focus.style() == key and h.marks > 0 and h.ov > 0 and h.err == nil, S.HL_DRAWN[key],
        h.marks .. " marks, " .. h.ov .. " overlay passes" .. (h.err and (", " .. h.err) or ""))
    if h.plain then
        if key == "wash" then
            Q.check(h.swap == true, "highlight wash: the words turn to textOnFocus on a plain stop")
        else
            Q.check(h.swap == false, "highlight " .. key .. ": the words keep their color")
        end
    else
        Q.skip("highlight " .. key .. ": the words' color", "every marked stop was a solid one")
    end
    if key == "hand" then
        local hw = Z.Focus.handWidth()
        Q.check(h.ax ~= nil and h.ax - hw >= 0, "highlight hand: the hand stays on the screen", tostring(h.ax) .. " - " .. tostring(hw))
    end
    RT.bounds(Q, "highlight " .. key)
end
Q.step(10, function()
    pcall(CW.ensureBothOpenForGamepad, S.pn)
end)
Q.step(20, function()
    local w = RT.cw()
    if not Q.check(w ~= nil and w:isVisible(), "highlight: the pair is open for the pad") then return end
    if w._activeTab ~= "loot" then pcall(CW.openTab, S.pn, "loot") end
    F.claimFocus(w)
    S.hlInstall()
end)
for i = 1, #S.HL do
    local idx = i
    Q.step(5, function() if S.back.hl then S.hlPick(idx) end end)
    Q.step(6, function() if S.back.hl then S.hlCheck(idx) end end)
end
Q.step(2, function() S.putHL() end)

-- ===================================================================== the pointer hides on the pad
-- _watchPointer (FocusManager.lua) keeps its state local; what it does is Mouse.setCursorVisible, watched here:
-- the mode to the mouse shows the pointer (as the game's Display cursor has it), back to the pad hides it, the mouse
-- moved shows it, a pad press hides it again.
S.ptr = { calls = {} }
function S.ptrLast() return S.ptr.calls[#S.ptr.calls] end
function S.putPtr()
    if not S.back.ptr then return end
    S.back.ptr = nil
    S.ptrUnfake()
    pcall(function() Mouse.setCursorVisible = S.ptrWas end)
    if S.ptrMouse then pcall(function() Mouse.setXY(S.ptrMouse[1], S.ptrMouse[2]) end) end
end
Q.step(5, function()
    S.ptrWas = Mouse.setCursorVisible
    S.ptrFn = function(v)
        S.ptr.calls[#S.ptr.calls + 1] = (v == true)
        return S.ptrWas(v)
    end
    pcall(function() Mouse.setCursorVisible = S.ptrFn end)
    if not rawequal(Mouse.setCursorVisible, S.ptrFn) then
        Q.skip("pointer: hides on the pad", "Mouse.setCursorVisible cannot be watched from Lua here")
        return
    end
    S.back.ptr = true
    S.ptrMouse = { getMouseX(), getMouseY() }
    S.ptrShow = true
    pcall(function() S.ptrShow = getCore():isDisplayCursor() end)
    S.ptr.calls = {}
    Det.setLockedMode("kbm")
end)
-- (a pointer already shown, the mouse moved earlier, gets no call: then only "no hide" can be read)
Q.step(30, function()
    if not S.back.ptr then return end
    Q.check(#S.ptr.calls == 0 or S.ptrLast() == S.ptrShow, "pointer: on the mouse it shows (as Display cursor has it)",
        (#S.ptr.calls == 0) and "already shown" or tostring(S.ptrLast()))
    S.ptr.calls = {}
    Det.setLockedMode("gamepad")
end)
Q.waitFor(1, 90, function() return not S.back.ptr or #S.ptr.calls > 0 end, function(ok)
    if not S.back.ptr then return end
    Q.check(ok and S.ptrLast() == false, "pointer: back on the pad it hides", tostring(S.ptrLast()))
    S.ptr.calls = {}
    -- (Nov 18 2026, run r5: Mouse.setXY did not move the pointer (getMouseX read the old spot; rt_media saw the same),
    -- so the move is read back, and when it did not move the globals getMouseX / getMouseY that _watchPointer reads
    -- answer the moved spot until the check; put back by S.ptrUnfake / S.putPtr)
    local tx, ty = math.floor(S.ptrMouse[1] + Z.T.px(40)), math.floor(S.ptrMouse[2] + Z.T.px(20))
    pcall(function() Mouse.setXY(tx, ty) end)
    local mx = nil
    pcall(function() mx = getMouseX() end)
    if mx ~= tx then
        S.ptrFake = { getMouseX, getMouseY }
        getMouseX = function() return tx end
        getMouseY = function() return ty end
        if getMouseX() ~= tx then
            S.ptrUnfake()
            S.ptrNoMove = true
            Q.skip("pointer: the mouse moved shows it again", "Mouse.setXY did not move the pointer and getMouseX could not be stood in")
        end
    end
end)
function S.ptrUnfake()
    if not S.ptrFake then return end
    getMouseX, getMouseY = S.ptrFake[1], S.ptrFake[2]
    S.ptrFake = nil
end
Q.waitFor(1, 90, function() return not S.back.ptr or S.ptrNoMove or #S.ptr.calls > 0 end, function(ok)
    if not S.back.ptr then return end
    S.ptrUnfake()
    if S.ptrNoMove then return end
    Q.check(ok and S.ptrLast() == S.ptrShow, "pointer: the mouse moved shows it again", tostring(S.ptrLast()))
    S.ptr.calls = {}
    pcall(function() Mouse.setXY(S.ptrMouse[1], S.ptrMouse[2]) end)
end)
Q.step(3, function()
    if not S.back.ptr then return end
    S.ptr.calls = {}
    local w = RT.cw()
    if w and w:isVisible() then
        if F.getFocusedWindow(S.pn) ~= w then F.claimFocus(w) end
        RT.padDir("down", w)
    end
end)
Q.waitFor(1, 90, function() return not S.back.ptr or S.ptrNoMove or #S.ptr.calls > 0 end, function(ok)
    if not S.back.ptr then return end
    if S.ptrNoMove then
        Q.skip("pointer: a pad press on a ZeD window hides it again", "the pointer was never shown again (the mouse could not be moved)")
    else
        Q.check(ok and S.ptrLast() == false, "pointer: a pad press on a ZeD window hides it again", tostring(S.ptrLast()))
    end
    S.putPtr()
    S.release()
    RT.pairShut()
end)

-- ===================================================================== the input mode and the flip to the pad
-- (Nov 18 2026, the ledger) With no lock, a key press (OnKeyPressed with F15, a key nothing binds) reads "kbm";
-- players 2 to 4 always read "gamepad". From the pair shut, the lock to "gamepad" opens nothing (Nov 22 2026, KISS #14,
-- the director's pick: a touch or a key and then the stick popped both windows open mid-walk; until K3 (0b366177e)
-- FocusManager's _onModeChanged opened the pair and this checked it did); the pair is then opened as Y, LB or RB opens
-- it; a pad press shows the focus marks, and the flip to "kbm" hides them. The detector's switch waits 200 ms after
-- the last one, so each flip waits 300 ms. The auto flip to "gamepad" needs a real controller.
Q.step(5, function()
    S.closeWheels()
    S.release()
    RT.pairShut()
    S.back.mode = true
    Det.setLockedMode(nil)
end)
-- (Nov 18 2026, Deck run r5) the key press came ~5 frames after the last switch, under the detector's 200 ms at the
-- Deck window's frame rate, and was ignored: wait 300 ms of real time first, then press (again every 20 frames,
-- at most 6 presses, until the mode reads "kbm")
Q.waitMs(300)
Q.step(1, function()
    S.modeKeys = 1
    local ok, err = pcall(triggerEvent, "OnKeyPressed", 102)
    if not ok then Q.say("mode: the key press: " .. tostring(err)) end
end)
Q.waitFor(1, 120, function()
    if Det.getMode(S.pn) == "kbm" then return true end
    S.modeWait = (S.modeWait or 0) + 1
    if S.modeWait >= 20 and S.modeKeys < 6 then
        S.modeWait = 0
        S.modeKeys = S.modeKeys + 1
        pcall(triggerEvent, "OnKeyPressed", 102)
    end
    return false
end, function(ok)
    Q.check(ok and Det.getMode(1) == "gamepad" and Det.getMode(3) == "gamepad",
        "mode: with no lock a key press reads the mouse and keyboard; players 2 to 4 read the controller",
        tostring(Det.getMode(S.pn)) .. ", player 2 " .. tostring(Det.getMode(1)))
    Q.check(not RT.isOpen(), "flip: the pair is shut before the flip")
end)
Q.waitMs(300)
Q.step(1, function() Det.setLockedMode("gamepad") end)
-- (a second of frames for anything the flip would open; nothing should)
Q.waitFor(1, 60, function() return RT.isOpen() or (ZeD_WorldWindow.isOpen and ZeD_WorldWindow.isOpen(S.pn)) end, function(opened)
    Q.check(not opened and not RT.isOpen() and Det.getMode(S.pn) == "gamepad",
        "flip: locking the controller opens nothing, the pair stays shut (KISS #14)", "Character " .. tostring(RT.isOpen()) .. ", mode " .. tostring(Det.getMode(S.pn)))
    pcall(CW.ensureBothOpenForGamepad, S.pn)   -- (the pair opened as the pad's Y, LB or RB opens it)
end)
Q.waitFor(1, 120, function() local w = RT.ww(); return RT.isOpen() and w ~= nil and w:isVisible() end, function(ok)
    Q.check(ok, "flip: then the pad opens the Character and World windows (ensureBothOpenForGamepad, as Y, LB or RB)")
    local w = RT.cw()
    if w and w:isVisible() then
        if F.getFocusedWindow(S.pn) ~= w then F.claimFocus(w) end
        RT.padDir("down", w)
    end
end)
Q.waitMs(300)
Q.step(1, function()
    S.cuesOn = F.cuesVisible(S.pn)
    Det.setLockedMode("kbm")
end)
Q.waitFor(1, 120, function() return not F.cuesVisible(S.pn) end, function(ok)
    Q.check(ok and S.cuesOn == true, "flip: on the pad the focus marks show; back on the mouse they hide", "before " .. tostring(S.cuesOn))
    S.release()
    RT.pairShut()
end)

-- ===================================================================== the moodles' balloon under the pointer
-- (Nov 18 2026, the ledger) On the mouse (the lock still "kbm"), the pair shut: thirst and hunger raised so a moodle
-- shows, the pointer put on the first one; after the hover pause its balloon is up (ZeD.Balloon.up, keyed
-- "moodle:<key>") and fully on screen (the layer's _chip). Put back: the pointer, the stats, god mode.
function S.putMH()
    if not S.back.mh then return end
    S.back.mh = nil
    S.mhFake(false)
    pcall(function() Mouse.setXY(S.mh.mouse[1], S.mh.mouse[2]) end)
    pcall(function() local st = S.p:getStats(); st:set(CharacterStat.THIRST, S.mh.th); st:set(CharacterStat.HUNGER, S.mh.hu) end)
    pcall(function() S.p:setGodMod(S.mh.god) end)
end
Q.step(5, function()
    S.mh = { mouse = { getMouseX(), getMouseY() } }
    pcall(function() S.mh.god = S.p:isGodMod() end)
    pcall(function() local st = S.p:getStats(); S.mh.th = st:get(CharacterStat.THIRST); S.mh.hu = st:get(CharacterStat.HUNGER) end)
    if S.mh.th == nil or S.mh.hu == nil then Q.skip("moodles: hover balloon", "the stats cannot be read here"); return end
    S.back.mh = true
    pcall(function() S.p:setGodMod(false) end)
    pcall(function() local st = S.p:getStats(); st:set(CharacterStat.THIRST, 0.45); st:set(CharacterStat.HUNGER, 0.45) end)
end)
Q.waitFor(5, 240, function()
    if not S.back.mh then return true end
    local L = Z.Moodles and Z.Moodles.getLayer and Z.Moodles.getLayer(S.pn)
    return L ~= nil and L._show == true and L._list ~= nil and #L._list > 0
end, function(ok)
    if not S.back.mh then return end
    local L = Z.Moodles and Z.Moodles.getLayer and Z.Moodles.getLayer(S.pn)
    if not (ok and L) then Q.check(false, "moodles: a moodle shows to hover"); S.putMH(); return end
    local size = L._size or 32
    S.mh.key = "moodle:" .. tostring(L._list[1].key)
    S.mh.L = L
    local cx = math.floor(L:getAbsoluteX() + size / 2)
    local cy = math.floor(L:getAbsoluteY() + size / 2)
    pcall(function() Mouse.setXY(cx, cy) end)
    -- (Nov 18 2026, run r5: Mouse.setXY did not move the pointer, so the layer's own getMouseX / getMouseY /
    -- isMouseOver answer the first moodle's middle for the hover, as rt_addon's mdFake does; put back by S.putMH)
    S.mhFake(true, math.floor(size / 2))
end)
function S.mhFake(on, at)
    local L = S.mh and S.mh.L
    if not L then return end
    if on then
        if S.mh.had then return end
        S.mh.had = { rawget(L, "getMouseX"), rawget(L, "getMouseY"), rawget(L, "isMouseOver") }
        L.getMouseX = function() return at end
        L.getMouseY = function() return at end
        L.isMouseOver = function() return true end
    elseif S.mh.had then
        L.getMouseX, L.getMouseY, L.isMouseOver = S.mh.had[1], S.mh.had[2], S.mh.had[3]
        S.mh.had = nil
    end
end
Q.waitFor(2, 240, function()
    if not (S.back.mh and S.mh.key) then return true end
    return Z.Balloon.up() and Z.Balloon._slot ~= nil and Z.Balloon._slot.key == S.mh.key
end, function(ok)
    if not (S.back.mh and S.mh.key) then S.putMH(); return end
    local L, c = S.mh.L, S.mh.L and S.mh.L._chip
    local W, H = getCore():getScreenWidth(), getCore():getScreenHeight()
    local on = false
    local where = "no balloon"
    if c and c.balloon then
        local ax, ay = L:getAbsoluteX() + c.x, L:getAbsoluteY() + c.y
        on = ax >= -1 and ay >= -1 and ax + c.w <= W + 1 and ay + c.h <= H + 1
        where = string.format("%d,%d %dx%d", math.floor(ax), math.floor(ay), math.floor(c.w), math.floor(c.h))
    end
    Q.check(ok and on, "moodles: the pointer on a moodle brings up its balloon, fully on screen", tostring(S.mh.key) .. " " .. where)
    S.putMH()
end)

-- ===================================================================== the fishing line's tension as the rod in hand
-- (Nov 18 2026, the ledger) The game's tension meter (Fishing.ISTensionUI, which FishingManager makes with a fish on)
-- made here as the game makes it; its value set as the game sets it: Overrides/Fishing.lua keeps zedTension and draws
-- the rod (ZeD.FishRod.draw returns true: no vanilla dial). ZeD.FishRod.draw is watched, not replaced.
function S.putFish()
    if not S.back.fish then return end
    S.back.fish = nil
    Z.FishRod.draw = S.fish.drawWas
    pcall(function() S.fish.ui:removeFromUIManager() end)
end
Q.step(5, function()
    local TUI = Fishing and Fishing.ISTensionUI
    if not (TUI and Z.FishRod and Z.FishRod.draw) then Q.check(false, "fishing: the rod override is loaded"); return end
    S.fish = { drawWas = Z.FishRod.draw }
    S.back.fish = true
    Z.FishRod.draw = function(self, ox, oy, k, t)
        local r = S.fish.drawWas(self, ox, oy, k, t)
        if S.fish.ui ~= nil and self == S.fish.ui then S.fish.drawn, S.fish.t = r, t end
        return r
    end
    local ok, err = pcall(function()
        S.fish.ui = TUI:new(S.p)
        S.fish.ui:initialise()
        S.fish.ui:addToUIManager()
        S.fish.ui:updateValue(0.5)
    end)
    if not ok then Q.say("fishing: the meter: " .. tostring(err)) end
end)
Q.waitFor(2, 60, function() return not S.back.fish or S.fish.drawn ~= nil end, function(ok)
    if not S.back.fish then return end
    local ui = S.fish.ui
    Q.check(ok and S.fish.drawn == true and ui ~= nil and ui.zedTension == 0.5 and S.fish.t == 0.5,
        "fishing: the line's tension is kept and drawn as the rod in hand", "drawn " .. tostring(S.fish.drawn) .. ", tension " .. tostring(S.fish.t))
    S.putFish()
end)
-- back on the pad (the flip opens nothing since KISS #14; the pair is shut, whatever is up)
Q.waitMs(300)
Q.step(1, function() Det.setLockedMode("gamepad") end)
Q.step(10, function()
    S.release()
    RT.pairShut()
end)

-- ===================================================================== the wheels' routes to ZeD windows
-- the game's Designated zones and Investigate area (World wheel, the screen icons) open the World window's tab
Q.step(10, function()
    S.closeWheels()
    S.release()
    RT.pairShut()
    S.wwWas = ZeD_WorldWindow.isOpen and ZeD_WorldWindow.isOpen(S.pn)
    S.back.route = true
    ISDPadWheels.showAnimalZoneUI(S.pn)
end)
Q.waitFor(2, 60, function() local w = RT.ww(); return w ~= nil and w:isVisible() and w._activeTab == "animals" end, function(ok)
    local w = RT.ww()
    Q.check(ok, "routes: Designated zones opens the World window on Animals", w and w._activeTab)
    RT.bounds(Q, "World window on Animals")
    ISSearchWindow.toggleWindow(S.p)
end)
Q.waitFor(2, 60, function() local w = RT.ww(); return w ~= nil and w:isVisible() and w._activeTab == "forage" end, function(ok)
    local w = RT.ww()
    Q.check(ok, "routes: Investigate area opens the World window on Foraging", w and w._activeTab)
    RT.bounds(Q, "World window on Foraging")
    S.putRoute()
end)
-- the game's search window restored from Lua/layout.ini with visible=true stays hidden, at the saved place (Build
-- fix/searchwin, Overrides/Wheels.lua's ISSearchWindow.RestoreLayout wrap; the director, Nov 24 2026: "Both (1 and 2)").
-- Run through the game's own path (ISLayoutManager.CallRestoreLayout, as a load does), with a saved line of its own;
-- the window's place and visibility put back after.
Q.step(3, function()
    local sw = ISSearchWindow and ISSearchWindow.players and ISSearchWindow.players[S.p]
    if not sw then Q.skip("routes: the game's search window restored as open stays hidden", "no search window for the player"); return end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on("wheels") then Q.skip("routes: the game's search window restored as open stays hidden", "Safe mode has the wheels: the game's own restore"); return end
    local was = { v = sw:getIsVisible(), x = sw:getX(), y = sw:getY() }
    local ok, err = pcall(ISLayoutManager.CallRestoreLayout, "ISSearchWindow", { x = "121", y = "301", visible = "true", pin = "true" })
    local vis, x, y = sw:getIsVisible(), sw:getX(), sw:getY()
    Q.check(ok and not vis and math.floor(x + 0.5) == 121 and math.floor(y + 0.5) == 301,
        "routes: the game's search window restored as open (layout visible=true) stays hidden, at its saved place",
        "restore " .. tostring(ok) .. (ok and "" or (" " .. tostring(err))) .. ", visible " .. tostring(vis) .. ", at " .. tostring(x) .. "," .. tostring(y))
    pcall(function() sw:setX(was.x); sw:setY(was.y); sw:setVisible(was.v) end)
end)
function S.putRoute()
    if not S.back.route then return end
    S.back.route = nil
    S.release()
    if not S.wwWas then pcall(ZeD_WorldWindow.close, S.pn) end
    RT.pairShut()
end

-- ===================================================================== working a wheel (the gesture)
-- ZeD_WheelGesture.lua's own QA hooks: D.qaStick (a stick), D.qaStep (a frame), D.qaTrigger, D.qaSettings (stands in
-- for ZeD setup, nothing saved). The buttons go to the wheel as the game sends them with the wheel holding the pad.
-- Here and now's Crouch is the slice taken: it shows at once (p:isSneaking), and is put back.
S.gJD = { player = S.pn }
function S.gStick(x, y) D.qaStick(S.pn, x, y); D.qaStep(S.pn) end
function S.gAt(i, n, mag)
    local a = math.rad(-90 + (i - 1) * 360 / n)
    return math.cos(a) * mag, math.sin(a) * mag
end
function S.gPoint(i)
    local st = D.state[S.pn]
    if not st then return end
    local g = D.gesture(S.pn)
    if g and g.needCenter then S.gStick(0, 0) end
    local x, y = S.gAt(i, #st.menu.slices, 0.9)
    S.gStick(x, y)
end
function S.gPress(b) local st = D.state[S.pn]; if st and st.menu then st.menu:onJoypadDown(b, S.gJD) end end
function S.gFresh(settings)
    pcall(D.close, S.pn)
    S.closeWheels()
    D.qaSettings = settings
    D.qaTrigger(S.pn, false)
    D.qaStick(S.pn, 0, 0)
    pcall(function() S.p:setSneaking(false) end)
    ISDPadWheels.onDisplayDown(S.gJD)
    local st = D.state[S.pn]
    S.gi = nil
    for i, e in ipairs(st and st.path[1].entries or {}) do
        if e.name == Z.tr("UI_ZeD_Wheel_Crouch") and not e.off then S.gi = i end
    end
    return st ~= nil and S.gi ~= nil and #st.menu.slices >= S.gi
end
function S.sneak() local s = false; pcall(function() s = S.p:isSneaking() end); return s end
function S.putGesture()
    if not S.back.gest then return end
    S.back.gest = nil
    pcall(D.close, S.pn)
    S.closeWheels()
    D.qaSettings = nil
    D.qaStick(S.pn, nil)
    D.qaTrigger(S.pn, nil)
    D.tune.OPEN_DEBOUNCE_MS = S.gDebounce
    pcall(function() S.p:setSneaking(S.gSneakWas) end)
end
Q.step(10, function()
    S.closeWheels()
    S.release()
    S.gSneakWas = S.sneak()
    S.gDebounce = D.tune.OPEN_DEBOUNCE_MS
    S.back.gest = true
    D.tune.OPEN_DEBOUNCE_MS = 0
end)
-- tap opens, a flick takes
Q.step(3, function()
    if not Q.check(S.gFresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 }), "gesture: Here and now opens with Crouch on it") then return end
    local g = D.gesture(S.pn)
    Q.check(g ~= nil and g.mode == "tap" and g.commit == "flick" and not g.held, "gesture tap: the wheel opens and stays up", g and g.mode)
    S.gPoint(S.gi)
    g = D.gesture(S.pn)
    Q.check(g ~= nil and g.point == S.gi, "gesture tap: the stick lights Crouch", g and tostring(g.point))
    S.gStick(0, 0)
    Q.check(D.state[S.pn] == nil and S.sneak(), "gesture tap: letting the stick go takes Crouch and the wheel closes")
end)
-- a trigger closes it, nothing taken
Q.step(3, function()
    if not S.gFresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 }) then return end
    S.gPoint(S.gi)
    D.qaTrigger(S.pn, true)
    D.qaStep(S.pn)
    Q.check(D.state[S.pn] == nil and not S.sneak(), "gesture trigger: a trigger closes the wheel, nothing taken")
    D.qaTrigger(S.pn, false)
end)
-- Hold: A takes the lit slice
Q.step(3, function()
    if not S.gFresh({ open = "hold", commit = "flick", toggle = false, deadZone = 0.35 }) then return end
    local g = D.gesture(S.pn)
    Q.check(g ~= nil and g.mode == "hold" and g.held, "gesture hold: the wheel is held", g and g.mode)
    S.gPoint(S.gi)
    S.gPress(Joypad.AButton)
    Q.check(D.state[S.pn] == nil and S.sneak(), "gesture hold: A takes the lit slice")
end)
-- Stick click: letting go keeps the slice lit, R3 takes it
Q.step(3, function()
    if not S.gFresh({ open = "tap", commit = "click", toggle = false, deadZone = 0.35 }) then return end
    local g = D.gesture(S.pn)
    Q.check(g ~= nil and g.commit == "click", "gesture click: the wheel waits for the stick's click", g and g.commit)
    S.gPoint(S.gi)
    S.gStick(0, 0)
    g = D.gesture(S.pn)
    Q.check(g ~= nil and g.point == S.gi and not S.sneak(), "gesture click: letting the stick go keeps Crouch lit")
    S.gPress(Joypad.RStickButton)
    Q.check(D.state[S.pn] == nil and S.sneak(), "gesture click: R3 takes it")
end)
-- Toggle mode: the D-pad walks the ring, A takes
Q.step(3, function()
    if not S.gFresh({ toggle = true, deadZone = 0.35 }) then return end
    local g = D.gesture(S.pn)
    Q.check(g ~= nil and g.mode == "toggle" and not g.held, "gesture toggle: the wheel opens in Toggle mode", g and g.mode)
    S.gStick(0, 0)
    S.gPress(Joypad.DPadUp)
    local p1 = D.gesture(S.pn) and D.gesture(S.pn).point
    S.gPress(Joypad.DPadRight)
    local p2 = D.gesture(S.pn) and D.gesture(S.pn).point
    Q.check(p1 == 1 and p2 == 2, "gesture toggle: D-pad Up lights the top slice, Right walks to the next", tostring(p1) .. " then " .. tostring(p2))
    S.gPress(Joypad.AButton)
    Q.check(D.state[S.pn] == nil and (S.gi ~= 2 or S.sneak()), "gesture toggle: A takes the lit slice")
end)
-- (Nov 18 2026, the ledger) a bumper tapped with a wheel up: LB down and let go on the wheel (as the game sends them)
-- closes it and opens the pair with the pad on the Character window (G.onRelease -> F.openSide)
Q.step(3, function()
    S.release()
    RT.pairShut()
end)
Q.step(5, function()
    S.gBump = nil
    if not S.gFresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 }) then
        Q.check(false, "gesture bumper: Here and now opens")
        return
    end
    local m = D.state[S.pn].menu
    S.gBump = true
    m:onJoypadDown(Joypad.LBumper, S.gJD)
    m:onJoypadButtonReleased(Joypad.LBumper, S.gJD)
end)
Q.step(10, function()
    if not S.gBump then return end
    local cw, ww = RT.cw(), RT.ww()
    Q.check(D.state[S.pn] == nil and cw ~= nil and cw:isVisible() and ww ~= nil and ww:isVisible() and F.getFocusedWindow(S.pn) == cw,
        "gesture bumper: LB tapped on a wheel closes it and opens the pair, the pad on the Character window",
        "wheel " .. tostring(D.state[S.pn] ~= nil) .. ", focus " .. tostring(F.getFocusedWindow(S.pn)))
    S.release()
    RT.pairShut()
end)
Q.step(3, function() S.putGesture() end)

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
    -- (Q.onPress watched, not replaced: the game's press wrapper asks it by name and returns before the game's own
    -- press when it says true)
    local was = C.onPress
    S.took = nil
    C.onPress = function(jd, b) local r = was(jd, b); S.took = r; return r end
    local ok, err = pcall(JoypadControllerData.onPressButtonNoFocus, S.ctl, button)
    C.onPress = was
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
    Q.check(S.took == true, "chord: the press is the chord's, so the game's own press never runs", tostring(S.took))
    Q.check(S.p:isSneaking() ~= S.sneakWas, "chord: the character crouches")
    S.press("RB", Joypad.RStickButton)
end)
Q.step(10, function()
    Q.check(S.p:isSneaking() == S.sneakWas, "chord: again, and it stands as it was")
    RT.pairOpen()
end)
-- (Nov 18 2026, the ledger) A ZeD window holding the pad: the world's chord path (the game's press wrapper, Q.onPress)
-- says false, so nothing runs there, and the D-pad goes to that window, not a wheel (the onDisplay wrap's windowTakes:
-- no wheel, the focus moved). Q.onPress is asked straight, so the game's own R3 never runs.
-- (Nov 22 2026, KISS #34, the director's pick: in a window a bumper held with a face button runs the quick action and
-- never turns a tab. Until K3 (0b366177e) the chord did nothing in a window and this checked that; now the window's own
-- pad path, FocusManager's Focus.padChord, runs it: checked after the D-pad, RB held (qaButton) and R3 on the window.)
Q.step(20, function()
    local w = RT.cw()
    if not Q.check(w ~= nil and w:isVisible(), "chord: the Character window is open for the window checks") then return end
    if w._activeTab ~= "loot" then pcall(CW.openTab, S.pn, "loot") end
    F.claimFocus(w)
    F.focusWhere(w, "charMainInv", function(x) return x.item ~= nil end)
end)
Q.step(5, function()
    local w = RT.cw()
    if not (w and w:isVisible()) then return end
    local C = Z.QuickChords
    C.qaBumper = "RB"
    local okP, r = pcall(C.onPress, { player = S.pn, id = 0 }, Joypad.RStickButton)
    C.qaBumper = nil
    Q.check(F.getFocusedWindow(S.pn) == w and okP and r == false and S.p:isSneaking() == S.sneakWas,
        "chord: with a window holding the pad the world's chord path runs nothing (the window's own path has it, KISS #34)", tostring(r))
    S.closeWheels()
    local z = F.getFocusedZone(w)
    local i0 = z and z.focusedElementIdx
    pcall(ISDPadWheels.onDisplayDown, { player = S.pn })
    local z2 = F.getFocusedZone(w)
    local i1 = z2 and z2.focusedElementIdx
    Q.check(D.state[S.pn] == nil and i0 ~= nil and i1 ~= nil and i1 ~= i0,
        "D-pad on a focused window: no wheel opens, the window's focus moves", tostring(i0) .. " to " .. tostring(i1))
    S.closeWheels()
end)
-- (KISS #34) the window's own path: RB held (Focus.qaButton) and down on the window, then R3: the chord runs (the
-- character crouches), the focus stays, and the bumper's release turns no tab on either window
Q.step(3, function()
    local w = RT.cw()
    S.wc = nil
    if not (w and w:isVisible() and F.getFocusedWindow(S.pn) == w) then return end
    local ww = RT.ww()
    S.wc = { w = w, tabC = w._activeTab, tabW = ww and ww._activeTab, sneak = S.p:isSneaking() }
    S.back.wc = true
    Z.QuickChords.lastChord = nil
    RT.pad("RightBump", true)
    RT.padDown(Joypad.RBumper, w)
    RT.padDown(Joypad.RStickButton, w)
end)
Q.step(3, function()
    local c = S.wc
    if not c then Q.check(false, "chord in a window: the Character window holds the pad for it"); return end
    Q.check(Z.QuickChords.lastChord == "RB+R3" and S.p:isSneaking() ~= c.sneak and F.getFocusedWindow(S.pn) == c.w,
        "chord: in a window, RB held with R3 runs the quick action (the character crouches), the window keeps the pad (KISS #34)",
        "chord " .. tostring(Z.QuickChords.lastChord) .. ", crouched " .. tostring(S.p:isSneaking()))
    RT.pad("RightBump", false)
end)
Q.step(6, function()
    local c = S.wc
    if not c then return end
    local ww = RT.ww()
    Q.check(c.w._activeTab == c.tabC and (ww and ww._activeTab) == c.tabW,
        "chord: in a window the bumper's release after the chord turns no tab (KISS #34)",
        "Character " .. tostring(c.tabC) .. " -> " .. tostring(c.w._activeTab) .. ", World " .. tostring(c.tabW) .. " -> " .. tostring(ww and ww._activeTab))
    S.putWc()
    S.release()
    RT.pairShut()
end)
function S.putWc()
    if not S.back.wc then return end
    S.back.wc = nil
    RT.pad("RightBump", nil)
    if S.wc and S.p:isSneaking() ~= S.wc.sneak then pcall(function() S.p:setSneaking(S.wc.sneak) end) end
end
-- a chord that cannot run says why over the head (HaloTextHelper.addBadText, watched and kept quiet): on a slice
-- that is off, its reason; on a slice that is gone, "gone" with the chord's words
Q.step(5, function()
    local C = Z.QuickChords
    S.halo, S.haloWas = {}, HaloTextHelper.addBadText
    S.back.halo = true
    HaloTextHelper.addBadText = function(pl, text) S.halo[#S.halo + 1] = tostring(text) end
    local list = D.B.world(S.p, S.pn) or {}
    local oi, off = nil, nil
    for i, e in ipairs(list) do if e.off and not oi then oi, off = i, e.off end end
    if oi then
        C.set("RB+L3", "world:" .. oi, { Z.tr("UI_ZeD_Wheel_World"), tostring(list[oi].name) })
        local r = C.run(S.p, "RB+L3")
        Q.check(r == false and S.halo[#S.halo] == off, "chord: on a slice that is off it does nothing and says why", tostring(S.halo[#S.halo]))
    else
        Q.skip("chord: on a slice that is off it says why", "every World wheel slice is live here (a car, an animal and a light in reach)")
    end
    S.halo = {}
    C.set("RB+L3", "world:99", { Z.tr("UI_ZeD_Wheel_World"), "QA gone" })
    local r2 = C.run(S.p, "RB+L3")
    Q.check(r2 == false and S.halo[#S.halo] == Z.tr("UI_ZeD_Chord_Gone", "QA gone"), "chord: on a slice that is gone it says so", tostring(S.halo[#S.halo]))
    S.putHalo()
    S.putChords()
end)
function S.putHalo()
    if not S.back.halo then return end
    S.back.halo = nil
    HaloTextHelper.addBadText = S.haloWas
end
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
    -- (Nov 18 2026, run 11: the game's own ISDrinkFromBottle:drink line 82 calls syncPlayerStats(character,
    -- SyncPlayerStatsPacket.Stat_Thirst), and 42.21/42.22 have no Stat_Thirst, so a thirsty drink throws in -debug in
    -- the game without ZeD too. For this drink only, a call with that missing code is skipped; put back in S.putPB.)
    if syncPlayerStats and not S.syncWas then
        S.syncWas = syncPlayerStats
        syncPlayerStats = function(chr, stat, ...) if stat == nil then return end; return S.syncWas(chr, stat, ...) end
    end
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
    if S.syncWas then syncPlayerStats = S.syncWas; S.syncWas = nil end
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
    -- (the pad's way in: Here and now > Help > Controller map; there is no mouse way)
    S.closeWheels()
    S.release()
    S.openWheel("down")
    local help = S.entry(1, S.byName(Z.tr("UI_ZeD_Wheel_Help")))
    if Q.check(help ~= nil and help.sub ~= nil and not help.off, "map: Here and now has Help") then
        D.enter(S.pn, help)
        local cm = S.entry(nil, S.byName(Z.tr("UI_ZeD_Wheel_ControllerMap")))
        if Q.check(cm ~= nil and cm.run ~= nil and not cm.off, "map: Help has Controller map") then D.take(S.pn, cm) end
    end
    S.closeWheels()
end)
-- the twelve rows: each row's words drawn (the window's drawText watched on the window itself)
Q.step(2, function()
    local win = Z.ControllerMap.windows[S.pn]
    if not win then return end
    S.cmText = {}
    S.cmDrawWas = win.drawText
    S.cmRaw = rawget(win, "drawText")
    S.cmWin = win
    win.drawText = function(self, s, ...)
        if s ~= nil then S.cmText[#S.cmText + 1] = tostring(s) end
        return S.cmDrawWas(self, s, ...)
    end
end)
Q.step(20, function()
    local win = Z.ControllerMap.windows[S.pn]
    local d = S.drawn
    Q.check(win ~= nil and win:isReallyVisible(), "map: the Controller map opens")
    if S.cmWin then
        local rows, seen = Z.ControllerMap.ROWS or {}, 0
        for _, r in ipairs(rows) do
            local full = Z.tr(r[2])
            local hit = false
            for _, s in ipairs(S.cmText) do
                if not hit and #s > 2 and full:find(s, 1, true) then hit = true end
            end
            if hit then seen = seen + 1 end
        end
        Q.check(#rows == 12 and seen == 12, "map: its twelve rows are drawn", seen .. " of " .. #rows)
        S.cmWin.drawText = S.cmRaw
        S.cmWin = nil
    end
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
    if S.cmWin then S.cmWin.drawText = S.cmRaw; S.cmWin = nil end
    pcall(Z.ControllerMap.close, S.pn)
end

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.closeWheels()
    S.putDraw(); S.putShout(); S.putZoom(); S.putMood(); S.putStyle(); S.putChords(); S.putPB(); S.putPlace(); S.putPF()
    S.putRW(); S.putHL(); S.putPtr(); S.putRoute(); S.putGesture(); S.putHalo(); S.putMH(); S.putFish(); S.putWc()
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
    Q.check(Z.Balloon.draw == S.drawWas and ISDPadWheels.onShout == S.shoutWas
        and (S.hlMarkWas == nil or (Z.Focus.mark == S.hlMarkWas and Z.Focus.drawOverlay == S.hlOvWas))
        and (S.haloWas == nil or HaloTextHelper.addBadText == S.haloWas) and D.qaSettings == nil
        and (S.fish == nil or Z.FishRod.draw == S.fish.drawWas),
        "put back: the stand-ins are gone")
    if S.hlStyleWas then Q.check(Z.Focus.style() == S.hlStyleWas, "put back: the controller highlight", Z.Focus.style()) end
    if S.moodWas then Q.check(S.opt(Z.Settings.moodlePlaceOption) == S.moodWas, "put back: the moodles' place") end
    Q.say("put back: the input mode lock is " .. tostring(S.lockWas) .. " again; the mode reads " .. tostring(Det.getMode(S.pn)))
end)
Q.start()
