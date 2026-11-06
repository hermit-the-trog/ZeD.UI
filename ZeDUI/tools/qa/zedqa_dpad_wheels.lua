-- ZeDUI/tools/qa/zedqa_dpad_wheels.lua  (Oct 23 2026)
-- The controller's D-pad wheels and the Select ZeD wheel (DPAD_WHEELS_SPEC.md,
-- ZeD_DpadWheels.lua). No physical pad: the four ISDPadWheels.onDisplay* and
-- the Select wheel's addCommands are called as the game calls them, inner
-- wheels through the wheel's own commands (D.enter / D.back / D.take).
--   * every wheel's slices, live or off with the reason, on foot, in the deep
--     run's car and beside a tame animal;
--   * one inner wheel per wheel, and Back from it;
--   * one safe take per wheel: Character > Tabs > Health, World > Map >
--     Mini-map (shown, hidden again), Social > Shout, Here and now > Zoom >
--     in (and out again), ZeD > Text size (the size in use);
--   * paused: only Here and now and ZeD open; a ZeD window holding the pad:
--     the D-pad stays the window's;
--   * screenshots of the five top levels and their inner wheels (foot), the
--     windows reset, each with a slice pointed (the bubble shows);
--   * the gesture (punch list 91, ZeD_WheelGesture.lua): tap, flick, cancels,
--     swap, timeout, A X Y, aim and attack, bumpers, inner wheels, Select,
--     Stick click, Hold, Toggle mode, the dead zone, with D.qaStick;
--   * the UI queue: a wheel stepped on the frame it opens, a game-filled wheel
--     entered a frame after the open, the UI hidden with a wheel up; a spring-
--     back frame, a pad at rest between the radii, the bumpers while paused.
-- Run on the deep-run character (zedqa_deep_run.lua). grep "ZEDQA dw".
local p = getPlayer()
local pn = p:getPlayerNum()
local D, W = ZeD.DpadWheels, ZeD.Wheel
local function say(s) print("ZEDQA dw " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_dw_" .. n .. ".png") end) end
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

if not D then say("ERR ZeD.DpadWheels is not loaded"); say("DONE"); return end

local DIRS = { "left", "right", "up", "down", "select" }
local OPEN = { left = "onDisplayLeft", right = "onDisplayRight", up = "onDisplayUp", down = "onDisplayDown" }
local function menuOf(dir) return (dir == "select") and getPlayerBackButtonWheel(pn) or getPlayerRadialMenu(pn) end

-- open a top level the way the game does
local function open(dir)
    if dir == "select" then
        local w = getPlayerBackButtonWheel(pn)
        w:addCommands()
        w:addToUIManager(true)
        w:setVisible(true)
    else
        ISDPadWheels[OPEN[dir]]({ player = pn, id = nil })
    end
end
local function closeAll()
    local st = D.state[pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    for _, m in ipairs({ getPlayerRadialMenu(pn), getPlayerBackButtonWheel(pn) }) do
        if m and m:isReallyVisible() then pcall(m.undisplay, m) end
    end
    W.qaPoint = nil
end

-- one line per slice: name / second line, [off], [>] (opens a wheel)
local function list(tag)
    local st = D.state[pn]
    local m = st and st.menu
    if not m then say(tag .. ": no wheel"); return nil end
    local parts = {}
    for i, s in ipairs(m.slices or {}) do
        local t = tostring(s.text or "(place)"):gsub("\n", " / ")
        parts[#parts + 1] = i .. ":" .. t .. (W.isOff(s) and " [off]" or "") .. (W.hasSub(s) and " [>]" or "")
    end
    say(string.format("%s: %d slices, crumb %s, visible %s | %s", tag, #(m.slices or {}), tostring(m._zedCrumb), tostring(m:isReallyVisible()), table.concat(parts, "  ")))
    return m
end

-- the entry behind a top-level slice, by its name's start
local function entry(namePart)
    local st = D.state[pn]
    for _, e in ipairs(st and st.path[1].entries or {}) do
        if tostring(e.name):find(namePart, 1, true) then return e end
    end
end

-- the scene: windows closed, the pad nowhere, the debug console out of the shots
step(30, function()
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.releaseFocus then pcall(F.releaseFocus) end
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    say(string.format("scene: at %d,%d, in a car %s, health %d", math.floor(p:getX()), math.floor(p:getY()), tostring(p:getVehicle() ~= nil),
        math.floor(p:getBodyDamage():getOverallBodyHealth())))
end)

-- each wheel on foot: its slices, a screenshot with slice 2 pointed, its inner wheel
local INNER = { left = "UI_ZeD_Wheel_Tabs", right = "UI_ZeD_Wheel_Map", up = "IGUI_Emote_Friendly", down = "UI_ZeD_Wheel_Zoom", select = "UI_ZeD_Settings_BaseTheme" }
for _, dir in ipairs(DIRS) do
    step(10, function()
        closeAll()
        open(dir)
        local m = list("foot " .. dir)
        check(m and #m.slices >= 8, dir .. ": the top level has its slices (8, 9 on ZeD)")
        W.qaPoint = 2
    end)
    step(25, function() shot("foot_" .. dir) end)
    step(5, function()
        W.qaPoint = nil
        local key = INNER[dir]
        local name = (key:sub(1, 6) == "UI_ZeD") and ZeD.tr(key) or getText(key)
        local e = entry(name)
        if not check(e ~= nil, dir .. ": the slice '" .. name .. "' is there") then return end
        D.enter(pn, e)
        local m = list("inner " .. dir)
        local last = m and m.slices[#m.slices]
        check(m and last and W.isBack(last), dir .. ": the inner wheel ends with Back")
        check(m and m._zedCrumb and m._zedCrumb:find(name, 1, true) ~= nil, dir .. ": the breadcrumb names the inner wheel")
        W.qaPoint = 1
    end)
    step(25, function() shot("inner_" .. dir) end)
    step(5, function()
        W.qaPoint = nil
        D.back(pn)
        local st = D.state[pn]
        check(st and #st.path == 1, dir .. ": B from the inner wheel is back on the top level")
        D.back(pn)
        check(D.state[pn] == nil, dir .. ": B on the top level closes the wheel")
        closeAll()
    end)
end

-- every theme at both text sizes: Here and now (a slice with a second line
-- pointed) and the ZeD wheel's accents, captured; the look in use put back after
local look = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
for _, base in ipairs({ "dark", "light", "hicon" }) do
    for _, size in ipairs({ "small", "large" }) do
        local tag = base .. "_" .. size
        step(5, function() closeAll(); D.Z.theme(base, nil, size) end)
        step(20, function() open("down"); W.qaPoint = 2 end)
        step(25, function() shot("look_" .. tag .. "_down") end)
        step(5, function()
            W.qaPoint = nil
            closeAll()
            open("select")
            D.enter(pn, entry(ZeD.tr("UI_ZeD_Settings_AccentColor")))
            W.qaPoint = 4
        end)
        step(25, function() shot("look_" .. tag .. "_accent") end)
    end
end
step(5, function()
    W.qaPoint = nil
    closeAll()
    D.Z.theme(look.base, look.accent, look.size)
    say("look back to " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
end)

-- the safe takes
step(10, function()
    open("left")
    local tabs = entry(ZeD.tr("UI_ZeD_Wheel_Tabs"))
    D.enter(pn, tabs)
    local st = D.state[pn]
    local health
    for _, e in ipairs(st.path[#st.path].entries) do if e.tab == "health-tab-white" then health = e end end
    if check(health ~= nil, "Character > Tabs has Health") then D.take(pn, health) end
    closeAll()
end)
step(60, function()
    local win = ZeD_CharacterWindow.getWindow()
    check(win and win:isVisible() and win._activeTab == "health", "Character > Tabs > Health opened the Character window on Health")
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.releaseFocus then pcall(F.releaseFocus) end
end)
local miniWas
step(20, function()
    local mm = getPlayerMiniMap(pn)
    miniWas = mm and mm:isReallyVisible()
    open("right")
    D.enter(pn, entry(ZeD.tr("UI_ZeD_Wheel_Map")))
    local st = D.state[pn]
    local e = st.path[#st.path].entries[2]
    if e.off then say("World > Map > Mini-map is off: " .. tostring(e.off)) else D.take(pn, e) end
    closeAll()
end)
step(20, function()
    local mm = getPlayerMiniMap(pn)
    if mm then
        check(mm:isReallyVisible() ~= miniWas, "World > Map > Mini-map turned the mini-map " .. (miniWas and "off" or "on"))
        ISMiniMap.ToggleMiniMap(pn)   -- (back as it was)
    else
        say("no mini-map in this game (sandbox): the slice is off, as it should be")
    end
end)
step(10, function()
    open("up")
    local e = entry(getText("IGUI_Emote_Shout"))
    if check(e ~= nil and not e.off, "Social > Shout is live") then D.take(pn, e) end
    closeAll()
end)
local zoomWas
step(30, function()
    zoomWas = getCore():getZoom(pn)
    open("down")
    D.enter(pn, entry(ZeD.tr("UI_ZeD_Wheel_Zoom")))
    local st = D.state[pn]
    local e = st.path[#st.path].entries[1]
    if e.off then say("Here and now > Zoom is off: " .. tostring(e.off)) else D.take(pn, e) end
    closeAll()
end)
step(60, function()
    local z = getCore():getZoom(pn)
    check(z ~= zoomWas or getCore():getAutoZoom(pn), string.format("Here and now > Zoom > in changed the zoom (%.2f -> %.2f)", zoomWas or -1, z or -1))
    getCore():doZoomScroll(pn, 1)   -- (back out)
end)
step(10, function()
    open("select")
    D.enter(pn, entry(ZeD.tr("UI_ZeD_Settings_TextSize")))
    local st = D.state[pn]
    local cur
    for _, e in ipairs(st.path[#st.path].entries) do if e.detail then cur = e end end
    local before = ZeD.currentSize
    if check(cur ~= nil, "ZeD > Text size marks the size in use") then D.take(pn, cur) end
    check(ZeD.currentSize == before, "ZeD > Text size > the size in use keeps it (" .. tostring(ZeD.currentSize) .. ")")
    closeAll()
end)

-- paused: Here and now and ZeD open, the others do not. All in one step: the
-- steps run on OnTick, which stops while the game is paused (Oct 23 2026: a
-- pause in one step and Play in the next left the run stuck)
step(10, function()
    local sc = UIManager.getSpeedControls()
    if not sc then say("no speed controls: the paused checks are skipped"); return end
    sc:ButtonClicked("Pause")
    local paused = sc:getCurrentGameSpeed() == 0
    if check(paused, "the game pauses for the paused checks") then
        for _, dir in ipairs(DIRS) do
            closeAll()
            open(dir)
            local opened = D.state[pn] ~= nil
            local want = (dir == "down" or dir == "select")
            check(opened == want, "paused: " .. dir .. (want and " opens" or " stays closed"))
        end
        closeAll()
    end
    sc:ButtonClicked("Play")
    check(sc:getCurrentGameSpeed() ~= 0, "the game runs again after the paused checks")
end)

-- a ZeD window holding the pad: the D-pad is the window's
step(20, function()
    ZeD_CharacterWindow.ensureBothOpenForGamepad(pn)
end)
step(30, function()
    local F = ZeD.Input.Focus
    local win = ZeD_CharacterWindow.getWindow()
    F.claimFocus(win)
    ISDPadWheels.onDisplayLeft({ player = pn, id = nil })
    check(D.state[pn] == nil and F.getFocusedWindow() == win, "with a window holding the pad, D-pad Left stays in the window (no wheel)")
    -- L3 / R3 in the window (Hard Rule #11 as amended): the list's sort steps, its view flips
    F.focusWhere(win, "charMainInv", function(e) return e.item ~= nil end)
    local cnt = win._mainContent
    local sort0, asc0 = cnt._sortCol, cnt._sortAsc
    F.dispatchJoypadDown(win, Joypad.LStickButton, { player = pn, id = nil })
    local sort1 = cnt._sortCol
    F.dispatchJoypadDown(win, Joypad.LStickButton, { player = pn, id = nil })
    local sort2 = cnt._sortCol
    check(sort1 ~= (sort0 or "name") and sort2 ~= sort1, string.format("L3 steps the sort (%s, %s, %s)", tostring(sort0), tostring(sort1), tostring(sort2)))
    cnt._sortCol, cnt._sortAsc = sort0, asc0
    local R = ZeD.InventoryRenderer
    local key = R.containerKey(p:getInventory(), p)
    local grid0 = R.isGridKey(key)
    F.dispatchJoypadDown(win, Joypad.RStickButton, { player = pn, id = nil })
    check(R.isGridKey(key) ~= grid0, "R3 flips the bag between List and Grid (" .. tostring(grid0) .. " -> " .. tostring(R.isGridKey(key)) .. ")")
    F.dispatchJoypadDown(win, Joypad.RStickButton, { player = pn, id = nil })
    check(R.isGridKey(key) == grid0, "R3 again flips it back")
    local pp = R.padPrompts(win)
    check(pp and #pp == 2, "the footer names L3 and R3 while the pad is on the list")
    ZeD_CharacterWindow.toggleBothPaired(pn)
    pcall(F.releaseFocus)
end)

-- in the deep run's car, then beside a tame animal: the top levels' slices
local car
step(20, function()
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local t
        pcall(function() t = v:getModData().ZeDDeepRun end)
        if t == "near_car" and v:DistTo(p) < 8 then car = v end
    end
    if not car then say("no deep-run car within 8 tiles: the car scene is skipped"); return end
    pcall(function() car:enter(0, p) end)
    pcall(function() triggerEvent("OnEnterVehicle", p) end)
end)
-- the driver's seat leaves the D-pad with the wheels (director, Oct 24 2026);
-- World > Vehicle > Dashboard hands it to the dash, B lets go
local dashAt
step(60, function()
    if not (car and p:getVehicle()) then return end
    local F = ZeD.Input.Focus
    local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    local fw = F.getFocusedWindow()
    say("in the car the pad is on: " .. tostring(fw and (fw._zedLabel or fw.Type) or "nothing"))
    check(dash and fw ~= dash, "in the driver's seat the dashboard does not take the D-pad")
    if fw then pcall(F.releaseFocus) end
    for _, dir in ipairs(DIRS) do closeAll(); open(dir); list("car " .. dir) end
    closeAll(); open("right")
    local w = entry(ZeD.tr("UI_ZeD_Wheel_Vehicle"))
    check(w and not w.off, "in the car: World > Vehicle is live")
    if not (w and not w.off) then return end
    D.enter(pn, w)
    local m = list("car vehicle wheel")
    local last = m and m.slices[#m.slices]
    check(last and W.isBack(last), "the vehicle wheel ends with Back")
    local name = getText("IGUI_VehiclePartCatdashboard")
    for i, s in ipairs(m and m.slices or {}) do if tostring(s.text):find(name, 1, true) == 1 then dashAt = i end end
    check(dashAt and not W.isOff(m.slices[dashAt]), "the vehicle wheel has Dashboard (driver's seat)")
    check(dashAt == #m.slices - 1, "Dashboard is the last slice before Back")
    W.qaPoint = dashAt
end)
step(25, function() if dashAt then shot("car_vehicle_dashboard") end end)
step(5, function()
    W.qaPoint = nil
    local m = D.state[pn] and D.state[pn].menu
    local cmd = dashAt and m and m:getSliceCommand(dashAt)
    if not (cmd and cmd[1]) then closeAll(); return end
    -- as A takes it (ZeD_DpadWheels: the wheel goes, then the slice's command)
    closeAll()
    cmd[1](cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7])
end)
step(10, function()
    if not dashAt then return end
    local F = ZeD.Input.Focus
    local dash = ZeD.Dashboard.getInstance()
    check(F.getFocusedWindow() == dash, "Dashboard puts the pad on the dash's controls")
    local el = F.getFocusedElement(dash)
    check(el ~= nil, "a dash control has the focus: " .. tostring(el and el.id))
    -- B, as the focus manager sends it: the focused control's onCancel
    if el and el.onCancel then el.onCancel(dash, el) end
end)
step(5, function()
    if not dashAt then return end
    local F = ZeD.Input.Focus
    check(F.getFocusedWindow() == nil, "B lets go of the dash")
    check(not ZeD.Dashboard.getInstance()._reg, "the dash leaves the window list on B")
    closeAll(); open("right")
    local m = list("car after B")
    check(D.state[pn] and m and #m.slices >= 8, "after B the D-pad opens the World wheel again")
    closeAll()
end)
step(30, function()
    if car and p:getVehicle() then pcall(function() car:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end)
local home, spawned
step(30, function()
    home = { x = p:getX(), y = p:getY() }
    local best, bd, seen = nil, nil, 0
    local list2 = getCell():getObjectListForLua()
    for i = 0, list2:size() - 1 do
        local o = list2:get(i)
        if instanceof(o, "IsoAnimal") then
            seen = seen + 1
            local dx, dy = o:getX() - p:getX(), o:getY() - p:getY()
            local d = math.sqrt(dx * dx + dy * dy)
            local wild = false
            pcall(function() wild = o:isWild() end)
            if d < 15 and not wild and (not bd or d < bd) then best, bd = o, d end
        end
    end
    -- none tame near (the deep run's wander off): a tame cow beside the character for the scene, taken away after
    if not best then
        local ok = pcall(function()
            local def = AnimalDefinitions.getDef("cow")
            local breed = def and def:getBreeds():get(0)
            best = addAnimal(getCell(), math.floor(p:getX()) + 2, math.floor(p:getY()), 0, "cow", breed)
            best:addToWorld()
            pcall(function() best:setWild(false) end)
        end)
        spawned = ok and best or nil
        say(string.format("%d animals in the cell, none tame within 15 tiles: a tame cow spawned beside the character (%s)", seen, tostring(spawned ~= nil)))
        if not spawned then return end
        bd = 2
    else
        pcall(function() p:teleportTo(best:getX() + 1, best:getY(), best:getZ()) end)
    end
    pcall(function() p:faceThisObject(best) end)
    say(string.format("beside a tame animal (%.1f tiles away before)", bd))
end)
step(40, function()
    -- (the game's usable animal is the one a pad player faces: none without a
    -- physical pad, so the animal next to the character stands in for it, for
    -- the slice's test and for the game's own animal wheel alike)
    local orig = AnimalContextMenu.getAnimalToInteractWith
    local real = orig(p)
    say("the game's usable animal: " .. tostring(real))
    local stand = real or spawned
    if not real and stand then AnimalContextMenu.getAnimalToInteractWith = function() return stand end end
    local ok, err = pcall(function()
        closeAll(); open("right"); list("animal right")
        local a = entry(ZeD.tr("UI_ZeD_Wheel_Animal"))
        check(a and not a.off, "beside a tame animal: World > Animal is live")
        if a and not a.off then
            D.enter(pn, a)
            local m = list("animal wheel")
            local last = m and m.slices[#m.slices]
            check(last and W.isBack(last), "the animal wheel ends with Back")
        end
        closeAll()
    end)
    AnimalContextMenu.getAnimalToInteractWith = orig
    if not ok then say("ERR animal scene: " .. tostring(err)) end
end)
step(20, function()
    if spawned then pcall(function() spawned:removeFromWorld() end); pcall(function() spawned:removeFromSquare() end) end
    if home then pcall(function() p:teleportTo(home.x, home.y, 0) end) end
end)

-- THE GESTURE (punch list 91, RADIAL_WHEELS_SPEC.md): every way of working a wheel, no pad needed. The stick is
-- D.qaStick, a frame is D.qaStep, the triggers are D.qaTrigger, and the buttons are sent to the wheel the way the
-- game sends them with the wheel holding the pad (onJoypadDown, onJoypadButtonReleased). D.qaSettings stands in for
-- ZeD setup, so nothing the player saved is touched. Here and now's Crouch is the slice taken: it shows at once.
local G = ZeD.WheelGesture
local JD = { player = pn }
local keepTune = {}
local function stick(x, y) D.qaStick(pn, x, y); D.qaStep(pn) end
local function press(button) local st = D.state[pn]; st.menu:onJoypadDown(button, JD) end
local function release(button) local st = D.state[pn]; st.menu:onJoypadButtonReleased(button, JD) end
-- the stick at slice i of n, at a magnitude, turned by degrees
local function at(i, n, mag, turn)
    local a = math.rad(-90 + (i - 1) * 360 / n + (turn or 0))
    return math.cos(a) * mag, math.sin(a) * mag
end
local function point(i, turn)
    local g = D.gesture(pn)
    local n = #D.state[pn].menu.slices
    local x, y = at(i, n, 0.9, turn)
    if g and g.needCenter then stick(0, 0) end
    stick(x, y)
end
local function fresh(settings)
    closeAll()
    D.qaSettings = settings
    D.qaTrigger(pn, false)
    D.qaStick(pn, 0, 0)
    p:setSneaking(false)
end
local function openDown() ISDPadWheels.onDisplayDown(JD) end

step(10, function()
    for k, v in pairs(D.tune) do keepTune[k] = v end
    D.tune.OPEN_DEBOUNCE_MS = 0
    closeAll()
end)

-- Tap and flick, the default
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
    local g = D.gesture(pn)
    check(g and g.mode == "tap" and g.commit == "flick" and g.held == false, "tap: the wheel opens and stays up (held is false)")
    check(D.state[pn].menu.hideWhenButtonReleased == nil, "tap: letting go of the D-pad does nothing")
    local n = #D.state[pn].menu.slices
    stick(0, 0)
    local x, y = at(2, n, 0.30)
    stick(x, y)
    check(D.gesture(pn).point == -1, "below engage nothing lights")
    for i = 1, n do
        x, y = at(i, n, 0.9)
        stick(x, y)
        check(D.gesture(pn).point == i, "slice " .. i .. " of " .. n .. " lights at its angle (" .. tostring(D.gesture(pn).point) .. ")")
    end
    -- resting on the boundary between 1 and 2: the 7 degrees hold it, past them it moves
    point(1)
    local half = 180 / n
    for _ = 1, 4 do
        stick(at(1, n, 0.9, half + 5))
        check(D.gesture(pn).point == 1, "past the boundary by 5 degrees: still slice 1")
        stick(at(1, n, 0.9, half - 5))
    end
    stick(at(1, n, 0.9, half + 9))
    check(D.gesture(pn).point == 2, "past it by 9: slice 2")
    stick(at(2, n, 0.9, -half - 5))
    check(D.gesture(pn).point == 2, "and back by 5: still slice 2, no flicker")
    -- a wheel of twenty: the hysteresis never over a quarter of a slice
    local many = { slices = {} }
    for i = 1, 20 do many.slices[i] = { text = "x" } end
    local ax, ay = at(1, 20, 0.9, 9 + 5)
    check(G.sector(many, { latch = 1 }, ax, ay) == 2, "twenty slices: 5 degrees past a boundary moves (a quarter of 18 is 4.5)")
    ax, ay = at(1, 20, 0.9, 9 + 4)
    check(G.sector(many, { latch = 1 }, ax, ay) == 1, "twenty slices: 4 degrees past holds")
    closeAll()
end)

-- commit: the latch, whichever way the stick comes home
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
    point(2)
    stick(0, 0)
    check(D.state[pn] == nil and p:isSneaking(), "a fast flick takes Crouch and the wheel closes")
    fresh(D.qaSettings)
    openDown()
    point(2)
    local n = #D.state[pn].menu.slices
    for _, m in ipairs({ 0.8, 0.6, 0.45, 0.3, 0.25 }) do
        stick(at(2, n, m))
        check(D.state[pn] ~= nil, "easing down at " .. m .. ": not yet")
    end
    stick(at(6, n, 0.15))    -- (the release frame: the stick through the center, reading the opposite way)
    check(D.state[pn] == nil and p:isSneaking(), "a slow ease takes the same slice, not the one the last frame read")
    p:setSneaking(false)
end)

-- cancels
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
    point(2)
    press(Joypad.DPadDown)
    check(D.state[pn] == nil and not p:isSneaking(), "the same direction closes it, nothing taken")
    fresh(D.qaSettings)
    openDown()
    point(2)
    press(Joypad.BButton)
    check(D.state[pn] == nil and not p:isSneaking(), "B closes it, nothing taken")
    fresh(D.qaSettings)
    openDown()
    point(2)
    press(Joypad.DPadLeft)
    local g = D.gesture(pn)
    check(g and g.dir == "left" and g.point == -1 and not p:isSneaking(), "another direction swaps, nothing taken")
    press(Joypad.Back)
    g = D.gesture(pn)
    check(g and g.dir == "select" and D.state[pn].menu == getPlayerBackButtonWheel(pn), "Select swaps to the ZeD wheel")
    press(Joypad.DPadRight)
    g = D.gesture(pn)
    check(g and g.dir == "right" and D.state[pn].menu == getPlayerRadialMenu(pn), "and a direction swaps back off it")
    fresh(D.qaSettings)
    D.tune.OPEN_DEBOUNCE_MS = 150
    openDown()
    press(Joypad.DPadDown)
    check(D.state[pn] ~= nil, "a second tap straight after opening is ignored")
    D.state[pn].openedAt = getTimestampMs() - 200
    press(Joypad.DPadDown)
    check(D.state[pn] == nil, "a tap after the debounce closes it")
    D.tune.OPEN_DEBOUNCE_MS = 0
    openDown()
    stick(0, 0)
    D.state[pn].lastActive = getTimestampMs() - 3100
    stick(0, 0)
    check(D.state[pn] == nil, "no engage for 3 seconds: it closes itself")
    openDown()
    point(2)
    D.state[pn].lastActive = getTimestampMs() - 3100
    D.qaStep(pn)
    check(D.state[pn] ~= nil, "a slice lit: the timer waits")
    closeAll()
end)

-- A, X, Y; aim and attack; the bumpers
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
    point(2)
    press(Joypad.AButton); press(Joypad.XButton); press(Joypad.YButton)
    check(D.state[pn] ~= nil and D.gesture(pn).point == 2 and not p:isSneaking(), "A, X and Y do nothing with a wheel up")
    D.qaTrigger(pn, true)
    D.qaStep(pn)
    check(D.state[pn] == nil and not p:isSneaking(), "a trigger closes the wheel, nothing taken")
    fresh(D.qaSettings)
    D.qaTrigger(pn, true)
    openDown()
    stick(0, 0)
    check(D.state[pn] ~= nil, "a trigger already down when it opened is no press")
    D.qaTrigger(pn, false)
    stick(0, 0)
    D.qaTrigger(pn, true)
    stick(0, 0)
    check(D.state[pn] == nil, "let go and pressed again, it is")
end)
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    local F = ZeD.Input.Focus
    openDown()
    press(Joypad.LBumper)
    check(D.state[pn] ~= nil, "a bumper down: nothing yet")
    release(Joypad.LBumper)
    check(D.state[pn] == nil and F.getFocusedWindow() == ZeD_CharacterWindow.getWindow(), "LB tapped: the wheel closes, the Character window has the pad")
end)
step(30, function()
    local F = ZeD.Input.Focus
    F.releaseFocus()
    openDown()
    press(Joypad.RBumper)
    release(Joypad.RBumper)
    check(D.state[pn] == nil and F.getFocusedWindow() == ZeD_WorldWindow.getWindow(), "RB tapped: the wheel closes, the World window has the pad")
end)
step(30, function()
    local F = ZeD.Input.Focus
    F.releaseFocus()
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    openDown()
    press(Joypad.LBumper); press(Joypad.RBumper)
    release(Joypad.RBumper); release(Joypad.LBumper)
    check(D.state[pn] ~= nil and F.getFocusedWindow() == nil, "both bumpers (the zoom): the wheel stays, no windows")
    closeAll()
end)

-- inner wheels by flick
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
    local name = ZeD.tr("UI_ZeD_Wheel_Zoom")
    local idx
    for i, e in ipairs(D.state[pn].path[1].entries) do if tostring(e.name):find(name, 1, true) then idx = i end end
    point(idx)
    stick(0, 0)
    local g = D.gesture(pn)
    check(g and g.level == 2, "a flick onto Zoom opens its ring in place")
    check(g and g.needCenter, "the new ring waits for the stick to come back")
    local n = #D.state[pn].menu.slices
    stick(at(n, n, 0.9))
    check(D.gesture(pn).point == -1, "not centered yet: nothing lights")
    point(n)
    stick(0, 0)
    g = D.gesture(pn)
    check(g and g.level == 1, "a flick onto Back is back on the top level")
    point(idx)
    stick(0, 0)
    press(Joypad.BButton)
    g = D.gesture(pn)
    check(g and g.level == 1, "B backs out one level")
    point(idx)
    stick(0, 0)
    check(D.gesture(pn).level == 2, "in again")
    press(Joypad.DPadDown)
    check(D.state[pn] == nil, "the same direction closes all of it")
    closeAll()
end)

-- the Select wheel: the engine shows it, then it is worked the same
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    open("select")
    local g = D.gesture(pn)
    check(g and g.mode == "tap" and g.held == false and D.state[pn].menu.hideWhenButtonReleased == nil, "the Select wheel opens by a tap too")
    point(1)
    stick(0, 0)
    check(D.gesture(pn).level == 2, "a flick on its Theme opens the ring")
    press(Joypad.Back)
    check(D.state[pn] == nil, "Select again closes all of it")
    closeAll()
end)

-- an off slice (Here and now's Light, with the lights taken away it may be live: the top level's own off slices are looked for)
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    ISDPadWheels.onDisplayLeft(JD)
    local off
    for i, s in ipairs(D.state[pn].menu.slices) do if W.isOff(s) then off = i; break end end
    if off then
        point(off)
        check(D.gesture(pn).point == off, "an off slice lights")
        stick(0, 0)
        check(D.state[pn] == nil, "letting go on it at the top level closes the wheel, as letting go always did")
    else
        say("no off slice on Character for this character: skipped")
    end
    closeAll()
end)

-- Stick click
step(5, function()
    fresh({ open = "tap", commit = "click", toggle = false, deadZone = 0.35 })
    openDown()
    local m = D.state[pn].menu
    point(2)
    stick(0, 0)
    check(D.state[pn] ~= nil and D.gesture(pn).point == 2, "Stick click: letting go keeps the slice lit")
    press(Joypad.RStickButton)
    check(D.state[pn] == nil and p:isSneaking(), "R3 takes the lit slice, stick at rest")
    p:setSneaking(false)
    fresh(D.qaSettings)
    openDown()
    press(Joypad.RStickButton)
    check(D.state[pn] ~= nil, "R3 with nothing lit does nothing")
    closeAll()
end)

-- Hold: today's path, plus letting the stick go
step(5, function()
    fresh({ open = "hold", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
    local g = D.gesture(pn)
    check(g and g.mode == "hold" and g.held and D.state[pn].menu.hideWhenButtonReleased == Joypad.DPadDown, "Hold: up while the direction is held")
    point(2)
    release(Joypad.DPadDown)
    D.qaStep(pn)
    check(D.state[pn] == nil and p:isSneaking(), "letting go of the D-pad takes the lit slice")
    p:setSneaking(false)
    fresh(D.qaSettings)
    openDown()
    point(2)
    stick(0, 0)
    check(D.state[pn] == nil and p:isSneaking(), "letting the stick go first takes it too")
    p:setSneaking(false)
    fresh({ open = "hold", commit = "click", toggle = false, deadZone = 0.35 })
    openDown()
    point(2)
    stick(0, 0)
    check(D.state[pn] ~= nil and not p:isSneaking(), "Hold with Stick click: letting the stick go does not take")
    press(Joypad.XButton)
    check(D.state[pn] == nil, "Hold: X closes, as it did")
    closeAll()
end)

-- Toggle mode
step(5, function()
    fresh({ open = "hold", commit = "click", toggle = true, deadZone = 0.35 })
    openDown()
    local g = D.gesture(pn)
    check(g and g.mode == "toggle" and g.held == false, "Toggle mode forces Tap and overrides the commit")
    stick(0, 0)
    press(Joypad.DPadUp)
    check(D.gesture(pn).point == 1, "D-pad Up lights the top slice")
    press(Joypad.DPadRight)
    check(D.gesture(pn).point == 2, "D-pad Right walks the ring to slice 2")
    D.state[pn].lastActive = getTimestampMs() - 60000
    stick(0, 0)
    check(D.state[pn] ~= nil and D.gesture(pn).point == 2, "no timer in Toggle mode, and the highlight stays")
    press(Joypad.AButton)
    check(D.state[pn] == nil and p:isSneaking(), "A takes it")
    p:setSneaking(false)
    fresh(D.qaSettings)
    openDown()
    point(2)
    stick(0, 0)
    check(D.state[pn] ~= nil and not p:isSneaking(), "the stick moves the highlight and letting go takes nothing")
    press(Joypad.BButton)
    check(D.state[pn] == nil, "B closes it")
    closeAll()
end)

-- the dead zone, live; the prompts; tune
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.50 })
    openDown()
    local n = #D.state[pn].menu.slices
    stick(0, 0)
    stick(at(2, n, 0.45))
    check(D.gesture(pn).point == -1, "dead zone 0.50: 0.45 lights nothing")
    D.qaSettings.deadZone = 0.40
    stick(at(2, n, 0.45))
    check(D.gesture(pn).point == 2, "the dead zone is read live: at 0.40 it lights")
    closeAll()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    D.tune.ENGAGE_RADIUS = 0.8
    openDown()
    stick(0, 0)
    stick(at(2, n, 0.7))
    check(D.gesture(pn).point == -1, "tune.ENGAGE_RADIUS wins over the setting")
    D.tune.ENGAGE_RADIUS = false
    closeAll()
    local count = {}
    for _, s in ipairs({ { "tap", "flick", false, 3 }, { "tap", "click", false, 3 }, { "hold", "flick", false, 4 }, { "hold", "click", false, 5 }, { "tap", "flick", true, 4 } }) do
        fresh({ open = s[1], commit = s[2], toggle = s[3], deadZone = 0.35 })
        openDown()
        local prompts = D.state[pn].menu._zedPrompts
        local parts = {}
        for _, q in ipairs(prompts) do parts[#parts + 1] = tostring(q.glyph) .. " " .. tostring(q.label) end
        say("prompts " .. s[1] .. " " .. s[2] .. " " .. tostring(s[3]) .. ": " .. table.concat(parts, " | "))
        check(#prompts == s[4], "prompts for " .. s[1] .. ", " .. s[2] .. (s[3] and ", toggle" or ""))
        closeAll()
    end
end)

-- the UI queue: a wheel opened from OnRenderTick is stepped on that same frame, before the game has it in its UI list
local coldTick
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    coldTick = function()
        Events.OnRenderTick.Remove(coldTick)
        ISDPadWheels.onDisplayLeft(JD)
        check(D.state[pn] ~= nil, "cold open: the state is up")
        check(not D.state[pn].menu:isReallyVisible(), "cold open: the wheel is still in the UI queue")
        D.qaStep(pn)
        check(D.state[pn] ~= nil, "cold open: a frame on the opening tick leaves it open")
    end
    Events.OnRenderTick.Add(coldTick)
end)
step(10, function()
    check(D.state[pn] ~= nil and D.state[pn].menu:isReallyVisible(), "cold open: a few frames on it is on the screen, still working")
    closeAll()
end)

-- a wheel on the screen for a frame or more, then a filler that behaves like the vehicle wheel's: it bails on a
-- wheel it finds visible, and a removal does not count until the game's next update
local filled = { name = "QA filled", fill = function(pl, n)
    local m = getPlayerRadialMenu(n)
    m:clear()
    if m:isReallyVisible() then m:undisplay(); return end
    m:addSlice("QA one", nil, function() end)
end }
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    ISDPadWheels.onDisplayRight(JD)
end)
step(5, function()
    D.enter(pn, filled)
    local m = D.state[pn] and D.state[pn].menu
    check(m and #m.slices == 2 and tostring(m.slices[1].text) == "QA one", "a filler a frame after the open fills the ring, Back after it")
    closeAll()
end)

-- the UI hidden with a wheel up (the pause menu, Esc): the wheel ends and comes off the saved focus
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
end)
step(5, function()
    local m = D.state[pn].menu
    D.qaStep(pn)
    m:setVisible(false)
    D.qaStep(pn)
    check(D.state[pn] == nil, "the UI hidden: the wheel's state ends")
    check(m:isVisible() and m._zedDpad == nil, "and the wheel is left visible for its next show, no dead state on it")
end)
step(5, function()
    check(not getPlayerRadialMenu(pn):isReallyVisible(), "and it is off the screen")
    closeAll()
end)

-- a spring-back frame above engage, far side of the highlight: the highlight stays, the slice taken is the one lit
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    openDown()
    local n = #D.state[pn].menu.slices
    point(2)
    stick(at(2, n, 0.95))
    stick(at(2, n, 0.40, 180))
    check(D.gesture(pn).point == 2, "a spring-back frame on the far side: the highlight stays")
    stick(at(2, n, 0.10, 180))
    check(D.state[pn] == nil and p:isSneaking(), "and the slice taken is the lit one, never the opposite one")
    p:setSneaking(false)
    fresh(D.qaSettings)
    openDown()
    point(2)
    stick(at(2, n, 0.9, 180))
    check(D.gesture(pn).point == 2, "the far side: the first frame waits")
    D.state[pn].farSince = getTimestampMs() - 100
    stick(at(2, n, 0.9, 180))
    check(D.gesture(pn).point ~= 2, "a stick that stays there moves it")
    closeAll()
end)

-- a pad at rest between the radii
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    D.qaStick(pn, 0.25, 0)
    openDown()
    local n = #D.state[pn].menu.slices
    stick(0.25, 0)
    stick(at(2, n, 0.9))
    check(D.gesture(pn).point == 2, "resting at 0.25 at the open: a push still picks")
    stick(0.25, 0)
    check(D.state[pn] ~= nil and D.gesture(pn).point == 2, "settling back at 0.25: not a let go, the slice stays lit")
    D.state[pn].lastActive = getTimestampMs() - 3100
    stick(0.25, 0)
    check(D.state[pn] == nil and not p:isSneaking(), "left there for 3 seconds: it closes, nothing taken")
    fresh(D.qaSettings)
    openDown()
    local idx
    local name = ZeD.tr("UI_ZeD_Wheel_Zoom")
    for i, e in ipairs(D.state[pn].path[1].entries) do if tostring(e.name):find(name, 1, true) then idx = i end end
    point(idx)
    stick(0, 0)
    stick(0.25, 0)
    stick(0.30, 0)
    check(D.gesture(pn).needCenter, "a new ring: passing through the band is not centered")
    D.state[pn].restSince = getTimestampMs() - 200
    stick(0.25, 0)
    check(not D.gesture(pn).needCenter, "sitting in it is")
    closeAll()
end)

-- Stick click: a lit slice waits for the click, past the timer
step(5, function()
    fresh({ open = "tap", commit = "click", toggle = false, deadZone = 0.35 })
    openDown()
    point(2)
    stick(0, 0)
    D.state[pn].lastActive = getTimestampMs() - 3100
    stick(0, 0)
    check(D.state[pn] ~= nil and D.gesture(pn).point == 2, "Stick click: the timer leaves a lit slice")
    closeAll()
end)

-- Toggle: the press that opens is not a move
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = true, deadZone = 0.35 })
    D.tune.OPEN_DEBOUNCE_MS = 150
    openDown()
    press(Joypad.DPadDown)
    check(D.gesture(pn).point == -1 or D.gesture(pn).point == nil, "Toggle: the opening press lights nothing")
    D.state[pn].openedAt = getTimestampMs() - 200
    press(Joypad.DPadDown)
    check((D.gesture(pn).point or -1) > 0, "the next press does")
    D.tune.OPEN_DEBOUNCE_MS = 0
    closeAll()
end)

-- a bumper tapped on a paused wheel: it closes, the windows stay shut and the pad stays free
step(5, function()
    fresh({ open = "tap", commit = "flick", toggle = false, deadZone = 0.35 })
    local F = ZeD.Input.Focus
    F.releaseFocus()
    UIManager.getSpeedControls():ButtonClicked("Pause")
    openDown()
    check(D.state[pn] ~= nil, "paused: Here and now opens")
    press(Joypad.LBumper)
    release(Joypad.LBumper)
    check(D.state[pn] == nil and F.getFocusedWindow() == nil, "paused: a bumper closes the wheel and no window takes the pad")
    UIManager.getSpeedControls():ButtonClicked("Play")
    closeAll()
end)
step(5, function()
    closeAll()
    D.qaStick(pn, nil)
    D.qaTrigger(pn, nil)
    D.qaSettings = nil
    for k, v in pairs(keepTune) do D.tune[k] = v end
    p:setSneaking(false)
    say("gesture settings put back")
end)
step(10, function()
    closeAll()
    say(fails .. " failed")
    say("DONE")
end)

-- step(n, fn): fn runs n ticks after the step before it
local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    local nxt = Q[qi + 1]
    waitT = nxt and nxt.n or 0
end
waitT = Q[1] and Q[1].n or 0
Events.OnTick.Add(onTick)
say("start")
