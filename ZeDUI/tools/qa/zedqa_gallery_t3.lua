-- ZeDUI/tools/qa/zedqa_gallery_t3.lua  (Oct 24 2026)
-- Captures for the Workshop gallery, tester build 0.2.0-t3 (director: "take
-- new screens with the new updates"): the D-pad wheels with ZeD's button
-- pictures and a slice's quick action chord in its bubble, World > Vehicle >
-- Dashboard in the driver's seat, and ZeD setup's Quick actions rows, their
-- list and Put things back. Dark theme, orange accent (the gallery's), the
-- controller's mode held so the prompts show; all put back after.
-- Writes Screenshots/zqa_g3_*.png (copied into Screenshots/workshop_src by
-- hand after the run). Run on the deep-run character. grep "ZEDQA g3".
local p = getPlayer()
local pn = p:getPlayerNum()
local D, W = ZeD.DpadWheels, ZeD.Wheel
local Det = ZeD.Input.Detector
local function say(s) print("ZEDQA g3 " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_g3_" .. n .. ".png") end); say("shot " .. n) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local look = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }

local function closeWheel()
    local st = D.state[pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    local m = getPlayerRadialMenu(pn)
    if m and m:isReallyVisible() then pcall(m.undisplay, m) end
    W.qaPoint = nil
end

step(20, function()
    Det.setLockedMode("gamepad")
    D.Z.theme("dark", "orange", look.size)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    say("set: " .. tostring(ZeD.PadGlyphs.set()) .. ", look " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent))
end)
-- (the theme rebuilds the windows: closed after it, the pad nowhere, so the D-pad opens wheels)
local function noWindows()
    pcall(ZeD.Input.Focus.releaseFocus)
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(ZeD.Input.Focus.releaseFocus)
    pcall(function() Mouse.setXY(20, 20) end)   -- (the pointer off the windows and lists, so nothing shows hovered)
end
step(30, noWindows)
step(20, function() say("windows open " .. tostring(ZeD_CharacterWindow.isOpen()) .. ", the pad on " .. tostring(ZeD.Input.Focus.getFocusedWindow())) end)

-- the Character wheel, Eat pointed (its chord, LB + A, in the bubble)
step(10, function() ISDPadWheels.onDisplayLeft({ player = pn, id = nil }); W.qaPoint = 3 end)
step(30, function() shot("wheel_character_eat") end)
step(5, function() closeWheel() end)
-- Here and now, the light pointed (LB + X)
step(10, function() ISDPadWheels.onDisplayDown({ player = pn, id = nil }); W.qaPoint = 8 end)
step(30, function() shot("wheel_now_light") end)
step(5, function() closeWheel() end)
-- Character > Use, Smoke pointed (LB + Y)
step(10, function()
    ISDPadWheels.onDisplayLeft({ player = pn, id = nil })
    local st = D.state[pn]
    local e = st and st.path[1].entries[8]
    if e then D.enter(pn, e) end
    W.qaPoint = 1
end)
step(30, function() shot("wheel_use_smoke") end)
step(5, function() closeWheel() end)

-- the driver's seat: World > Vehicle, Dashboard pointed
local car
step(10, function()
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local t
        pcall(function() t = v:getModData().ZeDDeepRun end)
        if t == "near_car" and v:DistTo(p) < 10 then car = v end
    end
    if not car then say("no deep-run car within 10 tiles"); return end
    pcall(function() car:enter(0, p) end)
    pcall(function() triggerEvent("OnEnterVehicle", p) end)
end)
step(60, function()
    if not (car and p:getVehicle()) then return end
    noWindows()
    ISDPadWheels.onDisplayRight({ player = pn, id = nil })
    local st = D.state[pn]
    local e = st and st.path[1].entries[3]
    if e then D.enter(pn, e) end
    local m = D.state[pn] and D.state[pn].menu
    local name = getText("IGUI_VehiclePartCatdashboard")
    for i, s in ipairs(m and m.slices or {}) do if tostring(s.text):find(name, 1, true) == 1 then W.qaPoint = i end end
end)
step(30, function() if car and p:getVehicle() then shot("car_vehicle_dashboard") end end)
step(5, function()
    closeWheel()
    if car and p:getVehicle() then ZeD.Dashboard.takePad(p) end
end)
step(30, function() if car and p:getVehicle() then shot("car_dash_pad") end end)
step(5, function()
    pcall(ZeD.Input.Focus.releaseFocus)
    if car and p:getVehicle() then pcall(function() car:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end)

-- ZeD setup on the pause screen: the Quick actions rows, their list, Put things back
local opts, rows
local function rowIdx(pred)
    local idx, y, found, fy = 0, 0, nil, 0
    for _, r in ipairs(rows) do
        if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then idx = idx + 1 end
        if not found and pred(r) then found = idx; fy = y end
        y = y + (r._h or ZeD.T.px(30))
    end
    return found, fy
end
step(20, function() D.H.openSetup(p, pn) end)
step(40, function()
    opts = ZeD.MainMenu and ZeD.MainMenu.pauseOpts
    if not opts then say("no ZeD setup"); return end
    rows = opts:rowsFor(opts:pages()[opts.pageIdx or 1])
    local i = rowIdx(function(r) return r.kind == "chord" and r.chord == "LB+X" end)
    local _, y0 = rowIdx(function(r) return r.kind == "chord" end)
    opts.scroll = math.max(0, y0 - ZeD.T.px(40))
    opts.focusId = i and ("orow:" .. i) or nil
    -- (the help band reads this row, as for a row the controller is on)
    for _, x in ipairs(rows) do if x.kind == "chord" and x.chord == "LB+X" then opts._cellRow = x end end
    pcall(function() Mouse.setXY(20, 20) end)
end)
step(30, function() if opts then shot("setup_chords") end end)
step(5, function() if opts and opts._cellRow then local r = opts._cellRow; opts._cellRow = nil; opts:activateRow(r) end end)
step(30, function() if opts then shot("setup_list") end end)
step(5, function()
    local MM = ZeD.MainMenu
    if MM then MM.ctx.open = nil; MM.popup = nil end
    if not opts then return end
    local i = rowIdx(function(r) return r.labelKey == "UI_ZeD_Settings_PutBack" end)
    opts.focusId = i and ("orow:" .. i) or nil
    for _, x in ipairs(rows) do if x.labelKey == "UI_ZeD_Settings_PutBack" then opts._cellRow = x end end
end)
step(30, function() if opts then shot("setup_putback") end end)
step(5, function()
    if opts then opts._cellRow = nil; pcall(function() opts:finish() end) end
    if MainScreen and MainScreen.instance and MainScreen.instance:isVisible() then ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
end)

-- a window's footer with the buttons as pictures
step(20, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
step(25, function() local win = ZeD_CharacterWindow.getWindow(); if win then pcall(ZeD.Input.Focus.claimFocus, win) end end)
step(40, function() shot("footer_pad") end)

step(10, function()
    pcall(ZeD.Input.Focus.releaseFocus)
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    D.Z.theme(look.base, look.accent, look.size)
    Det.setLockedMode(nil)
    say("look back to " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent))
    say("DONE")
end)

-- (stepped on each drawn frame: the pause screen stops the game's tick)
local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
