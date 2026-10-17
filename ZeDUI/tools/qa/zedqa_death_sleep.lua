-- ZeDUI/tools/qa/zedqa_death_sleep.lua  (Oct 16 2026)
-- In game on the ZeD-QA save, without dying or sleeping: a test copy of
-- vanilla's sleep panel (its own update off, so it stays while awake) at 2:40
-- PM over a dark screen, then with an alarm clock set; then a test copy of
-- vanilla's death panel with the character's real record (ZeD.Death.capture),
-- its rules forced to "everyone dead" for the picture only (no button pressed
-- but Cancel), then Shut down's "Are you sure?" and Cancel. Takes it all back.
-- grep "ZEDQA ds"; Screenshots/zqa_ds_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA ds " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ds_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local dark, sleepUI, clock, death
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local w = ZeD_CharacterWindow.getWindow(); if w and w:isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    -- the engine's dark, stood in for
    dark = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    dark.backgroundColor = { r = 0, g = 0, b = 0, a = 0.93 }; dark.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    dark:initialise(); dark:addToUIManager()
    sleepUI = ISSleepingUI:new(pn)
    sleepUI.update = function() end
    sleepUI.hourOfDay = 14 + 40 / 60
    sleepUI:setVisible(true); sleepUI:addToUIManager()
end)
at(30, function() shot("01_sleep") end)
at(32, function()
    clock = p:getInventory():AddItem("Base.AlarmClock2")
    local ok, e = pcall(function() clock:setAlarmSet(true) end)
    say("alarm set " .. tostring(ok) .. " " .. tostring(e) .. " isAlarmSet " .. tostring(pcall(function() return clock:isAlarmSet() end)))
    sleepUI.hourOfDay = 6 + 58 / 60
    sleepUI._zedAlarmAt = nil
end)
at(70, function() say("alarm lamp " .. tostring(sleepUI._zedAlarm)); shot("02_sleep_alarm") end)
at(72, function()
    sleepUI:removeFromUIManager(); dark:removeFromUIManager()
    if clock then p:getInventory():Remove(clock) end
    ZeD.Death.capture(p)
    local rec = ZeD.Death.records[pn]
    say("record " .. tostring(rec.name) .. " | " .. tostring(rec.when) .. " | lines " .. #rec.lines .. " | kills " .. tostring(rec.kills) .. " | skills " .. tostring(rec.skills))
    death = ISPostDeathUI:new(pn)
    death.timeOfDeath = getTimestamp() - 10
    death.lines = rec.lines
    death.zedRules = function() return { quit = true, exit = true, respawn = true, respawnEnabled = true } end
    death:addToUIManager()
end)
at(100, function()
    local ids = {}
    for _, h in ipairs(death._hits or {}) do ids[#ids + 1] = h.id .. (h.fn and "" or "(off)") end
    say("death buttons " .. table.concat(ids, ","))
    shot("03_death")
end)
at(102, function() death:zedAsk() end)
at(130, function()
    local ids = {}
    for _, h in ipairs(death._hits or {}) do ids[#ids + 1] = h.id end
    say("asking " .. tostring(death._asking) .. " buttons " .. table.concat(ids, ","))
    shot("04_are_you_sure")
    for _, h in ipairs(death._hits or {}) do if h.id == "no" then h.fn() end end
end)
at(140, function() death.zedRules = nil end)
at(150, function()
    say("after cancel asking " .. tostring(death._asking))
    local ids = {}
    for _, h in ipairs(death._hits or {}) do ids[#ids + 1] = h.id .. (h.fn and "" or "(off)") end
    say("real rules (alive): " .. table.concat(ids, ","))
    shot("05_death_alive_rules")
end)
at(160, function()
    death:removeFromUIManager()
    ISPostDeathUI.instance[pn] = nil
    ZeD.Death.records[pn] = nil
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 165 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
