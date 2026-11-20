-- ZeDUI/tools/qa/hfr_prompts.lua  (Nov 20 2026, QA; tag hfp): the beta 21 hotfix report, CUTS B in game (git 7441148a3):
-- Sandbox in game, the question windows with the mouse and with the controller look (ZeD.Prompt.qaJoy stands in for a pad),
-- the on-screen keyboard, the Keyboard map. Pictures to Screenshots/hfr_B_*.png. Manifest hotfix_prompts.txt.
-- Stand-ins only: the alarm and the question's callbacks do nothing; every prompt is closed without an answer; the
-- sandbox page's one change is undone and never applied. grep "ZEDQA hfp".
local S = HFR and HFR.init and HFR.init("hfp")
if not S then return end
local Q, MM, KM = S.Q, ZeD.MainMenu, ZeD.KeyboardMap
S.fake = { id = -1, player = 0 }
S.alarm = { h = 6, m = 30, on = false }
function S.alarm:getHour() return self.h end
function S.alarm:getMinute() return self.m end
function S.alarm:isAlarmSet() return self.on end
function S.alarm:setHour(v) self.h = v end
function S.alarm:setMinute(v) self.m = v end
function S.alarm:setAlarmSet(v) self.on = v end
function S.alarm:syncAlarmClock() end
function S.noop() end
function S.menuUp() local up = false; pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end); return up end
function S.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function S.sx() return math.floor(S.core:getScreenWidth() * 0.10) end
function S.sy() return math.floor(S.core:getScreenHeight() * 0.35) end
function S.kill()
    if S.cur then pcall(function() if S.cur.close then S.cur:close() else S.cur:setVisible(false); S.cur:removeFromUIManager() end end) end
    S.cur = nil
end

-- one prompt: make(fn) builds it; name the picture; pad true = the controller look
function S.prompt(name, pad, make)
    Q.step(10, function()
        S.kill()
        ZeD.Prompt.qaJoy = pad and S.fake or nil
        pcall(function() Mouse.setXY(S.sx(), S.sy()) end)
        pcall(function() S.cur = make() end)
        if S.cur then pcall(function() S.cur:initialise(); S.cur:addToUIManager() end) end
        Q.say(name .. " built " .. tostring(S.cur ~= nil) .. ", pad " .. tostring(pad))
    end)
    Q.step(50, function() end)
    Q.step(5, function()
        if S.cur and pad then pcall(function() Q.say(name .. " focus " .. tostring(S.cur:focusId())) end) end
        if S.cur then S.shot(name) else Q.notTaken(name, "the prompt did not build") end
    end)
    Q.step(5, function() ZeD.Prompt.qaJoy = nil; S.kill() end)
end
function S.mkQuestion() return ISModalDialog:new(S.sx(), S.sy(), 250, 150, getText("IGUI_ConfirmSleep"), true, nil, S.noop, 0, S.p, nil) end
function S.mkRename() return ISTextBox:new(S.sx(), S.sy(), 280, 180, getText("ContextMenu_NameThisBag"), "Go Bag", nil, S.noop, 0) end
function S.mkAlarm() return ISAlarmClockDialog:new(S.sx(), S.sy(), 230, 160, 0, S.alarm) end
function S.mkTimer() return ISBombTimerDialog:new(S.sx(), S.sy(), 280, 180, getText("IGUI_TimerSecondsBeforeExplosion"), 30, S.p, nil, S.noop, S.p, nil) end

Q.step(5, function()
    S.start0()
    S.was.sbx = ZeD.Settings.sandboxInGameOption and ZeD.Settings.sandboxInGameOption:getValue()
    S.was.zoom = nil
    S.so = getSandboxOptions()
    S.was.rot = S.so:getOptionByName("FoodRotSpeed"):getValueAsString()
    S.closePair()
end)
Q.zoomTo(1.0)

-- ===================================================================== question windows, mouse
S.prompt("B_prompt_rename_mouse", false, S.mkRename)
S.prompt("B_prompt_alarm_mouse", false, S.mkAlarm)
S.prompt("B_prompt_timer_mouse", false, S.mkTimer)
S.prompt("B_prompt_question_mouse", false, S.mkQuestion)
-- ===================================================================== the controller look
S.prompt("B_prompt_rename_pad", true, S.mkRename)
S.prompt("B_prompt_alarm_pad", true, S.mkAlarm)
S.prompt("B_prompt_timer_pad", true, S.mkTimer)
S.prompt("B_prompt_question_pad", true, S.mkQuestion)
-- ===================================================================== the on-screen keyboard (mouse, then pad)
Q.step(10, function()
    S.kill()
    pcall(function() Mouse.setXY(S.sx(), S.sy()) end)
    S.cur = S.mkRename(); S.cur:initialise(); S.cur:addToUIManager()
end)
Q.step(30, function()
    pcall(function() S.kb = OnScreenKeyboard.Show(0, S.cur.entry, nil) end)
    Q.say("keyboard up " .. tostring(S.kb ~= nil))
end)
Q.step(40, function() if S.kb then S.shot("B_keyboard_mouse") else Q.notTaken("B_keyboard_mouse", "no keyboard") end end)
Q.step(5, function() pcall(function() ZeD.Keyboard.instance:cancel() end); S.kb = nil end)
Q.step(20, function() S.kill() end)
Q.step(10, function()
    ZeD.Prompt.qaJoy = S.fake
    pcall(function() Mouse.setXY(S.sx(), S.sy()) end)
    S.cur = S.mkRename(); S.cur:initialise(); S.cur:addToUIManager()
end)
Q.step(30, function()
    pcall(function()
        local k = OnScreenKeyboard.Show(0, S.cur.entry, nil)
        k.prevFocus = S.cur; k.joyfocus = S.fake
        k:onJoypadDirRight(S.fake); k:onJoypadDirRight(S.fake)
        S.kb = k
    end)
end)
Q.step(40, function() if S.kb then S.shot("B_keyboard_pad") else Q.notTaken("B_keyboard_pad", "no keyboard") end end)
Q.step(5, function() pcall(function() ZeD.Keyboard.instance:cancel() end); S.kb = nil; ZeD.Prompt.qaJoy = nil end)
Q.step(20, function() S.kill() end)

-- ===================================================================== Keyboard map: the legend, then a key picked and listening
Q.step(10, function()
    S.closePair()
    S.kmOk = KM and pcall(KM.open, S.pn) or false
end)
Q.step(40, function()
    local w = KM and KM.windows and KM.windows[S.pn]
    S.kmWin = w
    if not w then Q.say("keyboard map window " .. tostring(S.kmOk)); return end
    G1.clear(Q, w, "left", "the Keyboard map")
end)
Q.still(10, function()
    if S.kmWin then S.shot("B_kbmap_legend") else Q.notTaken("B_kbmap_legend", "the Keyboard map did not open") end
end)
Q.step(10, function()
    local w = S.kmWin
    if not w then return end
    w.picked = Keyboard.KEY_E
    for _, b in ipairs(keyBinding or {}) do
        local v = b.value and tostring(b.value) or ""
        if v ~= "" and v:sub(1, 1) ~= "[" and getCore():getKey(v) == Keyboard.KEY_E then w.listening = v; break end
    end
    Q.say("picked E; listening " .. tostring(w.listening))
end)
Q.still(10, function()
    if S.kmWin then S.shot("B_kbmap_listening") else Q.notTaken("B_kbmap_listening", "the Keyboard map did not open") end
end)
Q.step(5, function()
    if S.kmWin then S.kmWin.listening = nil; S.kmWin.picked = nil end
    pcall(KM.close, S.pn)
    S.kmWin = nil
end)

-- ===================================================================== Sandbox in game
Q.step(10, function()
    S.sbxOpt = ZeD.Settings.sandboxInGameOption
    if S.sbxOpt then pcall(function() S.sbxOpt:setValue(2) end) end
    pcall(function() Mouse.setXY(5, 5) end)
    if not S.menuUp() then S.toggleMenu() end
end)
Q.waitFor(10, 300, function() return S.menuUp() and MM.pause and MM.pause:isVisible() end, function(ok) Q.say("pause window up " .. tostring(ok)) end)
Q.step(10, function() pcall(MM.openSandboxIG) end)
Q.step(40, function()
    local sw = MM.pauseSandbox
    S.sw = sw
    if not (sw and sw:isVisible()) then Q.say("sandbox window not open"); return end
    for i, pg in ipairs(sw:pages()) do if pg.raw == "World" or pg.title == "World" then sw.pageIdx = i; sw.scroll = 0; sw.focusId = nil end end
    -- one exception: the food rot speed a step off (never applied)
    local rows = sw.ctls and sw.ctls["FoodRotSpeed"]
    if rows then
        pcall(function() sw:nudge(rows, (rows.control.selected < #rows.control.options) and 1 or -1) end)
        pcall(function() sw:refreshDiff(true) end)
        sw.qaHelp = rows
    end
    Q.say("changed rows " .. tostring(sw.nDiff))
end)
Q.step(40, function()
    if S.sw and S.sw:isVisible() then S.shot("B_sandbox_ingame_changed", true) else Q.notTaken("B_sandbox_ingame_changed", "the window is not open") end
end)
Q.step(5, function()
    local sw = S.sw
    if not sw then return end
    pcall(function() sw:undoAll() end)
    for i, pg in ipairs(sw:pages()) do if pg.title == "Time" or pg.raw == "Time" then sw.pageIdx = i; sw.scroll = 0 end end
    sw.qaHelp = sw.ctls and sw.ctls["DayLength"] or nil
end)
Q.step(40, function()
    if S.sw and S.sw:isVisible() then S.shot("B_sandbox_ingame_time", true) else Q.notTaken("B_sandbox_ingame_time", "the window is not open") end
end)
Q.step(5, function()
    if S.sw then pcall(function() S.sw:undoAll() end); S.sw.qaHelp = nil end
    if S.menuUp() then S.toggleMenu() end
end)
Q.step(20, function()
    if S.sbxOpt and S.was.sbx then pcall(function() S.sbxOpt:setValue(S.was.sbx) end) end
    pcall(function() Mouse.setCursorVisible(true) end)
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    ZeD.Prompt.qaJoy = nil
    S.kill()
    if S.kmWin then S.kmWin.listening = nil; pcall(KM.close, S.pn) end
    if S.menuUp() then S.toggleMenu() end
    if S.sbxOpt and S.was.sbx then pcall(function() S.sbxOpt:setValue(S.was.sbx) end) end
    S.takeMade()
    G1.glassesBack(Q)
end)
Q.step(20, function()
    S.back0()
    Q.say("rot speed now " .. tostring(S.so:getOptionByName("FoodRotSpeed"):getValueAsString()) .. " (was " .. tostring(S.was.rot) .. ")")
    pcall(function() Mouse.setCursorVisible(true) end)
end)
Q.start()
