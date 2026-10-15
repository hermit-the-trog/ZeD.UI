-- ZeDUI/tools/qa/zedqa_prompts.lua  (S125)
-- The ZeD prompts (HOOK_MAP row 28): opens every kind through vanilla's own
-- constructors (ISModalDialog, ISModalRichText, ISTextBox, ISAlarmClockDialog,
-- ISBombTimerDialog, OnScreenKeyboard.Show) with vanilla's arguments, captures
-- each, answers each the way vanilla's buttons would, and prints what the
-- callbacks received. Copy to Zomboid/Lua/zedqa.lua and bump zedqa.go; grep
-- console.txt for "ZEDQA pr". Nothing in the save is changed: the alarm and the
-- trap are stand-ins, the kill question is answered No.

local p = getPlayer()
if ZeD.Keyboard and ZeD.Keyboard.instance and not ZeD.Keyboard.isVisible() then ZeD.Keyboard.instance = nil end   -- a fresh keyboard after a reload
local function say(s) print("ZEDQA pr " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_pr_" .. name .. ".png") end) end
local function cb(tag)
    return function(target, button, a1, a2)
        say("answer " .. tag .. " internal=" .. tostring(button and button.internal)
            .. " parentKind=" .. tostring(button and button.parent and button.parent.kind)
            .. " entry=" .. tostring(button and button.parent and button.parent.entry and button.parent.entry:getText()))
    end
end
local function info(o, tag)
    if not o then say(tag .. " nil"); return end
    say(string.format("%s Type=%s kind=%s x=%d y=%d w=%d h=%d visible=%s top=%s", tag, tostring(o.Type), tostring(o.kind),
        o.x or -1, o.y or -1, o.width or -1, o.height or -1, tostring(o:isReallyVisible()), tostring(ZeD.Prompt.top() == o)))
end
local cur

-- 1. a question (sleep), on the pointer
at(10, function()
    cur = ISModalDialog:new(0, 0, 250, 150, getText("IGUI_ConfirmSleep"), true, nil, cb("sleep"), 0, p, nil)
    cur:initialise(); cur:addToUIManager()
    info(cur, "sleep"); say("mouse " .. getMouseX() .. "," .. getMouseY())
end)
at(45, function() shot("01_sleep") end)
at(60, function() cur:answerCancel() end)

-- 2. a question that costs something (the kill question, answered No by vanilla's own button)
at(80, function()
    cur = ISModalDialog:new(0, 0, 350, 150, getText("IGUI_KillAnimal_Confirm", "Dolly"), true, nil, AnimalContextMenu.onKillAnimalConfirm)
    cur:initialise(); cur:addToUIManager()
    cur.animal = nil; cur.playerObj = p
    info(cur, "kill"); say("kill costly=" .. tostring(ZeD.Prompt.isCostly(cur.onclick)))
end)
at(115, function() shot("02_kill") end)
at(130, function() cur.no:forceClick(); info(cur, "kill after No") end)

-- 3. a note (the guide's reminder, vanilla's own box in the middle)
at(150, function()
    local w, h = 300, 120
    cur = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w, h, getText("IGUI_Tutorial_PressF1"), false, nil, cb("note"), nil)
    cur:initialise(); cur:addToUIManager()
    info(cur, "note")
end)
at(185, function() shot("03_note") end)
-- Escape answers the prompt on top (OK on a note) and the pause menu stays shut
at(200, function()
    triggerEvent("OnKeyPressed", Keyboard.KEY_ESCAPE)
    say("after Escape: note visible=" .. tostring(cur:isReallyVisible()) .. " pause=" .. tostring(MainScreen.instance and MainScreen.instance:isVisible()))
end)

-- 4. a text box (rename a bag): vanilla's onRenameBag with the first bag found, else a plain box
local bag
at(220, function()
    local items = p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "InventoryContainer") then bag = it; break end
    end
    if bag then
        ISInventoryPaneContextMenu.onRenameBag(bag, 0)
        cur = ZeD.Prompt.open[#ZeD.Prompt.open]   -- the newest (not drawn yet, so not "on top" until next frame)
        say("rename bag " .. tostring(bag:getName()))
    else
        cur = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_NameThisBag"), "Duffel Bag", nil, cb("rename"), 0)
        cur:initialise(); cur:addToUIManager()
        say("rename: no bag, plain box")
    end
    info(cur, "rename")
end)
at(255, function() shot("04_rename") end)
-- emptied, with noEmpty and a character limit: OK goes dim, the reason shows
at(270, function()
    cur.noEmpty = true; cur.maxChars = 12
    cur.entry:setText("")
end)
at(300, function()
    say("empty: yes.enable=" .. tostring(cur.yes.enable) .. " why=" .. tostring(cur._why))
    shot("05_rename_empty")
end)
at(315, function()
    cur.entry:setText("A very long bag name")
end)
at(340, function()
    say("long: yes.enable=" .. tostring(cur.yes.enable) .. " why=" .. tostring(cur._why))
    cur.entry:setText("Go Bag")
end)
-- 5. the keyboard on that field (typing goes straight into it)
at(360, function()
    local k = OnScreenKeyboard.Show(0, cur.entry, nil)
    say("keyboard Type=" .. tostring(k and k.Type) .. " zed=" .. tostring(k == ZeD.Keyboard.instance) .. " IsVisible=" .. tostring(OnScreenKeyboard.IsVisible()))
    info(k, "keyboard")
    info(cur, "rename under keyboard")
end)
at(380, function() local k = ZeD.Keyboard.instance; k:pressKey({ lo = "s", up = "S" }); k:pressKey({ lo = "!", up = "!" }) end)
at(400, function()
    say("typed: " .. tostring(cur.entry:getText()) .. " current=" .. tostring(OnScreenKeyboard.GetCurrentText()))
    shot("06_keyboard")
end)
at(420, function()
    ZeD.Keyboard.instance:cancel()
    say("after keyboard cancel: " .. tostring(cur.entry:getText()) .. " kbVisible=" .. tostring(OnScreenKeyboard.IsVisible()))
end)
at(435, function()
    cur.noEmpty = false; cur.maxChars = nil
    if bag then
        local before = bag:getName()
        cur.entry:setText(before)   -- answer OK with the same name: nothing changes in the save
        cur:pressPrimary()
        say("rename OK kept name=" .. tostring(bag:getName() == before))
    else
        cur:pressPrimary()
    end
end)

-- 6. Set Alarm (a stand-in alarm: vanilla's AlarmClock methods)
local alarm = { h = 6, m = 30, on = true }
function alarm:getHour() return self.h end
function alarm:getMinute() return self.m end
function alarm:isAlarmSet() return self.on end
function alarm:setHour(v) self.h = v end
function alarm:setMinute(v) self.m = v end
function alarm:setAlarmSet(v) self.on = v end
function alarm:syncAlarmClock() say("alarm synced " .. self.h .. ":" .. self.m .. " on=" .. tostring(self.on)) end
at(460, function()
    cur = ISAlarmClockDialog:new(0, 0, 230, 160, 0, alarm)
    cur:initialise(); cur:addToUIManager()
    info(cur, "alarm")
end)
at(495, function() shot("07_alarm") end)
at(505, function()
    -- the controller's steps: right on HOUR, down, left on MINUTE, down, A on the tick
    local jd = { id = -1, player = 0 }
    cur:onGainJoypadFocus(jd)
    cur:onJoypadDirRight(jd); cur:onJoypadDirDown(jd); cur:onJoypadDirLeft(jd); cur:onJoypadDirDown(jd); cur:onJoypadDown(Joypad.AButton, jd)
    say("alarm after pad: " .. cur.hours:getText() .. ":" .. cur.mins:getText() .. " on=" .. tostring(cur._alarmOn) .. " focus=" .. tostring(cur:focusId()))
    cur:onLoseJoypadFocus(jd)
end)
at(520, function() cur:press(cur.ok) end)

-- 7. Set Timer (a stand-in trap)
at(540, function()
    cur = ISBombTimerDialog:new(0, 0, 280, 180, getText("IGUI_TimerSecondsBeforeExplosion"), 30, p, nil,
        function(target, button, a1, a2) say("timer answer " .. tostring(button.internal) .. " time=" .. tostring(button.parent:getTime())) end, p, nil)
    cur:initialise(); cur:addToUIManager()
    info(cur, "timer")
end)
at(575, function() cur:activate("t+10"); cur:activate("t-5"); shot("08_timer") end)
at(590, function() cur:press(cur.yes) end)

-- 8. a long note: the help behind a window's ? (vanilla's ISCollapsableWindow:onInfo flow)
at(610, function()
    local o = ISModalRichText:new(getCore():getScreenWidth() / 2 - 400, getCore():getScreenHeight() / 2 - 300, 600, 600, getText("IGUI_DesignationZone_Info"), false)
    o:initialise()
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    o.alwaysOnTop = true
    o.chatText:paginate()
    o:setHeightToContents()
    o:ignoreHeightChange()
    o:setY(getCore():getScreenHeight() / 2 - (o:getHeight() / 2))
    o:setVisible(true)
    o:addToUIManager()
    cur = o
    info(cur, "help")
    say("help blocks=" .. tostring(cur._blocks and #cur._blocks) .. " contentH=" .. tostring(cur._contentH) .. " maxScroll=" .. tostring(cur._maxScroll))
end)
at(645, function() shot("09_help") end)
at(660, function() cur:press(cur.ok); say("help after OK visible=" .. tostring(cur:isReallyVisible())) end)

-- 9. a rich-text question with its own words (Yes / No kept)
at(680, function()
    cur = ISModalRichText:new(0, 0, 380, 120, getText("IGUI_WorldMap_ConfirmForget"), true, nil, cb("forget"), 0)
    cur:initialise(); cur:addToUIManager()
    info(cur, "forget"); say("forget costly=" .. tostring(ZeD.Prompt.isCostly(cur.onclick)))
end)
at(715, function() shot("10_rich_question") end)
at(730, function() cur:answerCancel() end)

-- 10. a subclass still builds vanilla's own (ISConfirmMonitorSettingsDialog derives ISModalDialog)
at(750, function()
    local ok, o = pcall(function() return ISModalDialog.new(ISConfirmMonitorSettingsDialog or {}, 0, 0, 300, 150, "x", true, nil, nil, 0) end)
    say("subclass build ok=" .. tostring(ok) .. " kind=" .. tostring(ok and o and o.kind) .. " Type=" .. tostring(ok and o and o.Type))
    say("open prompts left=" .. #ZeD.Prompt.open)
end)

-- 11. the controller look (ZeD.Prompt.qaJoy stands in for a pad: focus fills and the strip)
local fake = { id = -1, player = 0 }
at(770, function()
    ZeD.Prompt.qaJoy = fake
    cur = ISModalDialog:new(0, 0, 250, 150, getText("IGUI_ConfirmSleep"), true, nil, cb("gp sleep"), 0)
    cur:initialise(); cur:addToUIManager()
end)
at(800, function() say("gp focus=" .. tostring(cur:focusId())); shot("11_gp_question") end)
at(810, function() cur:onJoypadDirLeft(fake); say("gp after left focus=" .. tostring(cur:focusId())) end)
at(830, function() shot("12_gp_question_no"); cur:onJoypadDown(Joypad.BButton, fake) end)
at(850, function()
    cur = ISModalDialog:new(0, 0, 350, 150, getText("IGUI_KillAnimal_Confirm", "Dolly"), true, nil, AnimalContextMenu.onKillAnimalConfirm)
    cur:initialise(); cur:addToUIManager()
end)
at(880, function() shot("13_gp_kill"); cur:onJoypadDown(Joypad.BButton, fake) end)
at(900, function()
    cur = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_NameThisBag"), "Duffel Bag", nil, cb("gp rename"), 0)
    cur:initialise(); cur:addToUIManager()
end)
at(930, function() say("gp text focus=" .. tostring(cur:focusId())); shot("14_gp_text") end)
at(945, function()
    local k = OnScreenKeyboard.Show(0, cur.entry, nil)
    k.prevFocus = cur
    k.joyfocus = fake
    k:onJoypadDirRight(fake); k:onJoypadDirRight(fake)
end)
at(975, function() shot("15_gp_keyboard"); ZeD.Keyboard.instance:cancel() end)
at(990, function() cur:onJoypadDown(Joypad.BButton, fake) end)
at(1005, function()
    cur = ISAlarmClockDialog:new(0, 0, 230, 160, 0, alarm)
    cur:initialise(); cur:addToUIManager()
end)
at(1035, function() shot("16_gp_alarm"); cur:onJoypadDown(Joypad.BButton, fake) end)
at(1050, function()
    ZeD.Prompt.qaJoy = nil
    say("gp open prompts left=" .. #ZeD.Prompt.open)
    say("DONE")
end)

local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, err = pcall(s.fn)
            if not ok then say("ERR at " .. s.n .. ": " .. tostring(err)) end
        end
    end
    if tick > 1100 then Events.OnTick.Remove(onTick) end
end
if getGameSpeed and getGameSpeed() == 0 then setGameSpeed(1) end
Events.OnTick.Add(onTick)
say("start")
