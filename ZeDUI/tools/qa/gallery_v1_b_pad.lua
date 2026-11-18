-- ZeDUI/tools/qa/gallery_v1_b_pad.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's controller pictures, in a West
-- Point street (lived-in), with ZeD's input mode locked to the controller (ZeD.Input.Detector.setLockedMode("gamepad"),
-- unlocked again at the end). No controller is plugged in: the wheels open as zedqa_r1b_icons.lua opens them (the
-- windows put away first, then ISDPadWheels.onDisplay*({ player = pn, id = nil })) and a slice is pointed with
-- ZeD.Wheel.qaPoint. Needs gallery_v1_b_lib.lua first.
--   63 Part 6 opener (a full-bleed frame, no windows):
--     g1_63_now_wheel         the survivor mid-street, the Here and now wheel open (D-pad Down) at rest
--     g1_63_now_wheel_point   the same with its light slice pointed (as zqa_g3_wheel_now_light: slice 8)
--   65 On a Controller:
--     g1_65_wheel_belt        the Character wheel (D-pad Left) with the Belt slice pointed
--     g1_65_help_pad          the window pair at its default places, the Character window holding the pad: its help
--                             line shows the pad's prompts
-- The street: a square with street floor all round (GV1.findStreet), outdoors, no car or anyone on it, looked for by
-- the Fossoil at West Point first (the story's place), then West Point's east and centre; the QA home's drag strip last.
-- Puts back: the wheels shut, the pad's focus let go, the input mode as it was, the pair open, the place.
-- grep "ZEDQA g1bp".
local S = GV1 and GV1.new("g1bp")
if not S then print("ZEDQA g1bp ERR run gallery_v1_b_lib.lua first"); print("ZEDQA g1bp DONE"); return end
S.L = GV1
S.CW = ZeD_CharacterWindow
S.D, S.W = ZeD.DpadWheels, ZeD.Wheel
S.Focus = ZeD.Input and ZeD.Input.Focus
S.Det = ZeD.Input and ZeD.Input.Detector
S.PLACES = {
    { x = 12060, y = 7105, name = "West Point, by the Fossoil" },
    { x = 11940, y = 7010, name = "West Point, east" },
    { x = 11190, y = 6800, name = "West Point, centre" },
    { x = 11300, y = 6700, name = "West Point, north east streets" },
    { x = 925, y = 13040, name = "the QA home (the drag strip)" },
}
function S.pairOpen() if not S.CW.isOpen(S.pn) then pcall(S.CW.toggleBothPaired, S.pn) end end
function S.pairShut() if S.CW.isOpen(S.pn) then pcall(S.CW.toggleBothPaired, S.pn) end end
function S.lock(on)
    pcall(function()
        if on then S.Det.setLockedMode("gamepad"); return end
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
end
function S.closeWheel()
    pcall(function()
        local st = S.D.state and S.D.state[S.pn]
        if st and st.menu and st.menu.undisplay then st.menu:undisplay() end
        if S.D.state then S.D.state[S.pn] = nil end
        local m = getPlayerRadialMenu(S.pn)
        if m and m:isReallyVisible() then m:undisplay() end
    end)
    if S.W then S.W.qaPoint = nil end
end
function S.slices()
    local m = getPlayerRadialMenu(S.pn)
    local t = {}
    for i, s in ipairs((m and m.slices) or {}) do t[#t + 1] = i .. ":" .. string.gsub(tostring(s.text), "\n", " ") end
    return t
end
function S.sliceOf(word)
    local m = getPlayerRadialMenu(S.pn)
    for i, s in ipairs((m and m.slices) or {}) do if tostring(s.text or ""):find(word, 1, true) then return i end end
    return nil
end
function S.toWheel()
    S.closeWheel()
    pcall(S.Focus.releaseFocus, S.pn)
    S.pairShut()
    pcall(S.Focus.releaseFocus, S.pn)
    pcall(function() setJoypadFocus(S.pn, nil) end)
    if GAL_UNLOAD and GAL_UNLOAD.park then GAL_UNLOAD.park() end
end
-- what holds the pad now (a ZeD window that holds it keeps the D-pad: the wheel then never opens, zedqa_r1b_icons.lua)
function S.holder()
    local fw = S.Focus and S.Focus.getFocusedWindow and S.Focus.getFocusedWindow(S.pn)
    if not fw then return "nothing" end
    return tostring(fw.Type or fw._zedLabel or fw) .. " (visible " .. tostring(fw:isVisible()) .. ")"
end
-- a wheel opened as the D-pad press opens it; if the press's guards keep it shut (a window holding the pad, the
-- game's held-direction repeat), ZeD's own opener is called as the press would call it, and that is logged
function S.openWheel(dir, fn)
    S.say("before " .. dir .. ": the pad held by " .. S.holder())
    ISDPadWheels[fn]({ player = S.pn, id = nil })
    if #S.slices() > 0 then return end
    S.say("the D-pad's " .. dir .. " press did not open its wheel; ZeD.DpadWheels.open(" .. dir .. ") instead")
    local ok, e = pcall(S.D.open, dir, { player = S.pn, id = nil })
    if not ok then S.say("ERR open " .. dir .. ": " .. tostring(e)) end
end

S.step(10, function()
    S.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.L.keepCheats(S)
    pcall(function() S.lockWas = S.p:getModData().ZeD_Gamepad and S.p:getModData().ZeD_Gamepad.inputModeLock end)
    if ZEDQA_SPEED then ZEDQA_SPEED(1) elseif getGameSpeed() ~= 1 then setGameSpeed(1) end
    S.L.cheats(S); S.L.console()
    S.say("pad bound " .. tostring(JoypadState.players[S.pn + 1] ~= nil) .. ", input lock was " .. tostring(S.lockWas))
end)
S.L.tryPlaces(S, S.PLACES, S.L.findStreet, "street")
S.step(5, function()
    local f = S.street
    if not f then S.say("ERR no street found: the shots stay where the character is"); return end
    S.L.moveTo(S, f.x + 0.5, f.y + 0.5, 0)
    S.say("mid-street at " .. f.x .. "," .. f.y .. " (" .. f.place .. "), floor " .. tostring(f.floor))
end)
S.step(120, function()
    local n = 0
    pcall(function()
        local zs = getCell():getZombieList()
        for i = 0, zs:size() - 1 do
            local z = zs:get(i)
            if math.abs(z:getX() - S.p:getX()) < 15 and math.abs(z:getY() - S.p:getY()) < 15 then n = n + 1 end
        end
    end)
    S.say("zombies within 15 squares: " .. n)
    S.lock(true)
    S.toWheel()
end)
S.step(30, function() S.toWheel() end)   -- (again: the lock to the controller can hand the pad to a window a frame later)

-- ===================================================================== 63: Here and now (D-pad Down), no windows
S.step(20, function() S.openWheel("down", "onDisplayDown") end)
S.step(30, function()
    S.say("Here and now slices: " .. table.concat(S.slices(), "  "))
    if #S.slices() == 0 then S.L.notTaken(S, "g1_63_now_wheel", "the Here and now wheel did not open"); return end
    S.L.shot(S, "g1_63_now_wheel")
end)
S.step(10, function()
    if #S.slices() == 0 then return end
    S.W.qaPoint = math.min(8, #S.slices())
end)
S.step(30, function() if #S.slices() > 0 then S.L.shot(S, "g1_63_now_wheel_point") end end)
S.step(10, function() S.toWheel() end)

-- ===================================================================== 65: the Character wheel's Belt slice
S.step(20, function() S.openWheel("left", "onDisplayLeft") end)
S.step(20, function()
    S.say("Character wheel slices: " .. table.concat(S.slices(), "  "))
    S.belt = S.sliceOf(getText("UI_ClothingType_Belt"))
    if not S.belt then S.L.notTaken(S, "g1_65_wheel_belt", "no Belt slice on the Character wheel"); return end
    S.W.qaPoint = S.belt
    S.say("Belt slice " .. S.belt)
end)
S.step(30, function() if S.belt then S.L.shot(S, "g1_65_wheel_belt") end end)
S.step(10, function() S.toWheel() end)

-- ===================================================================== 65: a window's help line with the pad's prompts
S.step(20, function() S.pairOpen() end)
S.step(25, function()
    local w = S.CW.getWindow(S.pn)
    if w then pcall(S.Focus.claimFocus, w) end
    if GAL_UNLOAD and GAL_UNLOAD.park then GAL_UNLOAD.park() end
end)
S.step(40, function() S.L.shot(S, "g1_65_help_pad") end)

-- ===================================================================== put back
S.step(10, function()
    S.closeWheel()
    pcall(S.Focus.releaseFocus, S.pn)
    S.lock(false)
    S.pairOpen()
    S.L.moveTo(S, S.home.x, S.home.y, S.home.z)
end)
S.step(30, function()
    S.L.putCheats(S)
    S.L.summary(S)
    S.say("put back: wheels shut, focus let go, input lock " .. tostring(S.lockWas) .. ", the pair open, the place")
    S.L.done(S)
end)
S.L.run(S)
