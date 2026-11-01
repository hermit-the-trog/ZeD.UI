-- ZeDUI/tools/qa/zedqa_scalecap.lua  (Oct 31 2026, QA; punch list 39, the UI scale stops at what fits)
-- At the run's screen, with Normal text and then Large text:
--   the cap (ZeD.Scale.fitCap) and which fixed steps are too big; ZeD setup's switch (Settings.scaleStepOff) and the
--   controller's scale wheel (DpadWheels.Z.scaleWheel: an entry with "off" and no run) agree; the help line's words
--   (Settings.scaleTooBigHelp); the cap read again 30 ticks after the text size changed.
--   A saved 2x (picked through the wheel's own path when it is offered, else set as a saved value): the stored pick
--   stays 2x, the drawn scale is the cap; the ZeD setup page opened for a shot of the row ("2x (0.75x here)").
-- Puts back the text size and the stored UI scale. Shots zqa_cap_<h>_<what>.png. grep "ZEDQA cap".
local S, Sc, St = ZeD.Settings, ZeD.Scale, ZeD.Settings
local Z = ZeD.DpadWheels and ZeD.DpadWheels.Z
local p = getPlayer(); local pn = p:getPlayerNum()
local H = tostring(getCore():getScreenHeight())
local function say(s) print("ZEDQA cap " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cap_" .. H .. "_" .. n .. ".png") end) end
local KEYS = St.scaleKeys or { "auto", 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 }
local opt = St.uiScaleOption
local sizeWas, storedWas = ZeD.currentSize, opt and opt:getValue()
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function report(label)
    local cap = Sc.fitCap()
    local big, setupOff, wheelOff = {}, {}, {}
    for i = 2, #KEYS do
        if Sc.stepTooBig(KEYS[i]) then big[#big + 1] = tostring(KEYS[i]) end
        if St.scaleStepOff(opt, i) then setupOff[#setupOff + 1] = tostring(KEYS[i]) end
    end
    local wheel = (Z and Z.scaleWheel and Z.scaleWheel()) or {}
    for _, e in ipairs(wheel) do if e.off then wheelOff[#wheelOff + 1] = tostring(e.name) .. (e.run and "(runs!)" or "") end end
    say(label .. ": drawn (no refresh forced) " .. tostring(Sc.root()))
    say(string.format("%s: screen %s, text %s, cap %s, too big %s; setup off %s; wheel off %s; help '%s'", label, tostring(Sc.screenSize and table.concat({ Sc.screenSize() }, "x")),
        tostring(ZeD.currentSize), tostring(cap), table.concat(big, " "), table.concat(setupOff, " "), table.concat(wheelOff, " | "), tostring(St.scaleTooBigHelp())))
    check(#big == #setupOff, label .. ": ZeD setup dims exactly the steps that are too big")
    check(#wheelOff == #big, label .. ": the wheel dims the same steps, and none of them runs")
    for _, e in ipairs(wheel) do if e.off and e.run then fails = fails + 1; say("FAIL " .. label .. ": a dimmed wheel step still runs") end end
    if #big > 0 then check(St.scaleTooBigHelp() ~= nil, label .. ": the help line says why") end
    return cap, #big
end
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, "small")
    say("stored UI scale at start " .. tostring(storedWas) .. " (" .. tostring(KEYS[storedWas or 1]) .. "), override " .. tostring(Sc.override))
end)
local capSmall
step(30, function() capSmall = report("Normal text") end)
step(2, function() ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, "large") end)
step(30, function()
    local capLarge = report("Large text")
    say("the cap moved with the text size: " .. tostring(capSmall) .. " -> " .. tostring(capLarge))
end)
-- a saved 2x
step(5, function()
    ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, sizeWas)
    local i2 = nil
    for i, v in ipairs(KEYS) do if v == 2.0 then i2 = i end end
    if Z and Z.option and not St.scaleStepOff(opt, i2) then Z.option(opt, i2, St.applyScale)
    else opt:setValue(i2); pcall(function() St.applyScale(i2) end) end
    say("2x stored as " .. tostring(opt:getValue()))
end)
step(40, function()
    local root = Sc.root and Sc.root()
    local cap = Sc.fitCap()
    say(string.format("saved 2x: stored %s, drawn %s, cap %s", tostring(KEYS[opt:getValue()]), tostring(root), tostring(cap)))
    check(KEYS[opt:getValue()] == 2.0, "a saved 2x stays saved as 2x")
    check(root and math.abs(root - math.min(2.0, cap)) < 0.01, "it draws at the cap here (" .. tostring(root) .. ")")
    pcall(function() ZeD.DpadWheels.H.openSetup(p, pn) end)
end)
step(90, function()
    local ow = ZeD.MainMenu and ZeD.MainMenu.pauseOpts
    if ow then ow.scroll = 0 end
    shot("setup_saved2x")
    pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end)
end)
step(30, function()
    opt:setValue(storedWas or 1); pcall(function() St.applyScale(storedWas or 1) end)
    pcall(ZeD_Window.resetLayout)
    say("put back: stored " .. tostring(opt:getValue()) .. ", drawn " .. tostring(Sc.root and Sc.root()))
end)
step(20, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
-- frames, not game ticks: the pause menu (ZeD setup) stops OnTick
Events.OnRenderTick.Add(tick)
say("start " .. H)
