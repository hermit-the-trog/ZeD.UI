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
--     windows reset, each with a slice pointed (the bubble shows).
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
