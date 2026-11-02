-- ZeDUI/tools/qa/zedqa_screens.lua  (Nov 2 2026, QA; punch list 55, ZeD setup's screen switches under Safe mode)
-- In game. A watch worn (so the game's clock has something to show). For each of the seven switches
-- (ZeD.Settings.screenOptions: windows, belt, watch, dashboard, moodles, wheels, charinfo): tick it (On = the game's own),
-- check ZeD.Safe.on(name) and, where it can be seen without a car or a key press, that the game's screen is back and ZeD's
-- gone; untick it and check ZeD's is back. Then belt and watch ticked together; Safe mode On over them (every screen the
-- game's); Safe mode Off again (belt and watch stay the game's, the rest ZeD's); the switches saved to ModOptions.ini
-- (read back from the file). Everything is put back. The console's "[ZeD] Screens: ..." lines are read by QA.
-- grep "ZEDQA scr"; shots zqa_scr_*.png.
local function say(s) print("ZEDQA scr " .. tostring(s)) end
local p = getPlayer()
local SO = ZeD and ZeD.Settings and ZeD.Settings.screenOptions
local SAFE = ZeD and ZeD.Settings and ZeD.Settings.safeModeOption
if not (p and SO and SAFE and ZeD.Safe) then say("ERR the screen switches are not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_scr_" .. n .. ".png") end) end
local NAMES = { "windows", "belt", "watch", "dashboard", "moodles", "wheels", "charinfo" }
local was = {}
for _, n in ipairs(NAMES) do was[n] = SO[n] and SO[n]:getValue() end
local safeWas = SAFE:getValue()
local watchPlaceWas = ZeD.Settings.watchPlaceOption and ZeD.Settings.watchPlaceOption:getValue()
local CW = ZeD_CharacterWindow
local watchItem

-- what each screen shows now: true = the game's own, false = ZeD's, nil = not seen here
local function gameOwn(n)
    if n == "belt" then return ISHotbar and not ISHotbar._zedBelt end
    if n == "watch" then
        local w = ZeD.Watch and ZeD.Watch.getInstance and ZeD.Watch.getInstance()
        local clock = UIManager.getClock and UIManager.getClock()
        return (not (w and w:getIsVisible())) and clock ~= nil and clock:isVisible()
    end
    if n == "moodles" then
        local L = ZeD.Moodles and ZeD.Moodles.getLayer and ZeD.Moodles.getLayer(0)
        return L ~= nil and L._show == false
    end
    if n == "windows" then return not CW.isOpen() end
    return nil
end
local function look(n)
    local g = gameOwn(n)
    local extra = ""
    if n == "belt" then extra = " | hotbar " .. tostring(getPlayerHotbar and getPlayerHotbar(0) and getPlayerHotbar(0):isVisible())
    elseif n == "watch" then
        local clock = UIManager.getClock and UIManager.getClock()
        extra = " | clock " .. tostring(clock and (tostring(clock:isVisible()) .. " y " .. math.floor(clock:getY())))
    elseif n == "windows" then extra = " | ZeD windows open " .. tostring(CW.isOpen()) end
    return "Safe.on(" .. n .. ") " .. tostring(ZeD.Safe.on(n)) .. " | the game's own " .. tostring(g) .. extra
end
local function set(n, v) SO[n]:setValue(v) end

local Q = {}
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end
step(5, function()
    watchItem = p:getInventory():AddItem("Base.WristWatch_Left_DigitalBlack")
    p:setWornItem(watchItem:getBodyLocation(), watchItem)
    if ZeD.Settings.watchPlaceOption then ZeD.Settings.watchPlaceOption:setValue(2) end   -- (the corner watch: it replaces the game's clock)
    for _, n in ipairs(NAMES) do set(n, 1) end
    SAFE:setValue(1); pcall(ZeD.Safe.reread)
    if not CW.isOpen() then CW.toggleBothPaired(0) end
end)
step(60, function()
    for _, n in ipairs(NAMES) do
        check(ZeD.Safe.on(n) == false and gameOwn(n) ~= true, "start: " .. n .. " is ZeD's (" .. look(n) .. ")")
    end
    shot("start")
end)
for _, n in ipairs(NAMES) do
    step(5, function() set(n, 2) end)
    step(60, function()
        local g = gameOwn(n)
        say(n .. " ticked: " .. look(n))
        check(ZeD.Safe.on(n) == true, n .. " ticked: ZeD.Safe.on(" .. n .. ") is true")
        if g ~= nil then check(g == true, n .. " ticked: the game's own screen is back, ZeD's gone") end
        for _, o in ipairs(NAMES) do
            if o ~= n then check(ZeD.Safe.on(o) == false, n .. " ticked: " .. o .. " stays ZeD's") end
        end
        shot(n .. "_ticked")
    end)
    step(5, function()
        set(n, 1)
        if n == "windows" and not CW.isOpen() then CW.toggleBothPaired(0) end
    end)
    step(60, function()
        local g = gameOwn(n)
        say(n .. " unticked: " .. look(n))
        check(ZeD.Safe.on(n) == false, n .. " unticked: ZeD.Safe.on(" .. n .. ") is false")
        if g ~= nil then check(g == false, n .. " unticked: ZeD's screen is back") end
    end)
end
-- two together
step(5, function() set("belt", 2); set("watch", 2) end)
step(60, function()
    say("belt and watch ticked: " .. look("belt") .. " || " .. look("watch"))
    check(gameOwn("belt") == true and gameOwn("watch") == true, "belt and watch ticked together: both the game's")
    check(gameOwn("moodles") == false and CW.isOpen(), "belt and watch ticked: moodles and windows stay ZeD's")
    shot("belt_watch")
end)
-- Safe mode over mixed ticks
step(5, function() SAFE:setValue(2); pcall(ZeD.Safe.reread) end)
step(60, function()
    local all = true
    for _, n in ipairs(NAMES) do if not ZeD.Safe.on(n) then all = false end end
    check(ZeD.Safe.on() == true and all, "Safe mode on: every screen is the game's")
    check(gameOwn("moodles") == true and gameOwn("windows") == true, "Safe mode on: the moodles and windows are the game's too")
    shot("safe_on")
end)
step(5, function() SAFE:setValue(1); pcall(ZeD.Safe.reread); if not CW.isOpen() then CW.toggleBothPaired(0) end end)
step(60, function()
    say("Safe mode off: " .. look("belt") .. " || " .. look("watch") .. " || " .. look("moodles") .. " || " .. look("windows"))
    check(ZeD.Safe.on() == false, "Safe mode off again")
    check(gameOwn("belt") == true and gameOwn("watch") == true, "Safe mode off: belt and watch stay the game's (their ticks)")
    check(gameOwn("moodles") == false and CW.isOpen(), "Safe mode off: the moodles and windows are ZeD's again")
    shot("safe_off")
end)
-- saved: the file holds the ticks
step(5, function()
    pcall(function() PZAPI.ModOptions:save() end)
end)
step(20, function()
    local lines = {}
    local ok = pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        local l = r:readLine()
        while l do
            if string.find(l, "screen", 1, true) then lines[#lines + 1] = l end
            l = r:readLine()
        end
        r:close()
    end)
    say("ModOptions.ini screen lines: " .. table.concat(lines, " ; "))
    local belt, watch = false, false
    for _, l in ipairs(lines) do
        if string.find(l, "screenBelt|2", 1, true) then belt = true end
        if string.find(l, "screenWatch|2", 1, true) then watch = true end
    end
    check(ok and belt and watch, "the ticks are saved in ModOptions.ini (screenBelt and screenWatch On)")
end)
-- put back
step(5, function()
    for _, n in ipairs(NAMES) do if was[n] then set(n, was[n]) end end
    SAFE:setValue(safeWas or 1); pcall(ZeD.Safe.reread)
    if ZeD.Settings.watchPlaceOption and watchPlaceWas then ZeD.Settings.watchPlaceOption:setValue(watchPlaceWas) end
    if watchItem then pcall(function() p:removeWornItem(watchItem) end); pcall(function() p:getInventory():Remove(watchItem) end) end
    pcall(function() PZAPI.ModOptions:save() end)
end)
step(40, function()
    say("put back: belt " .. tostring(gameOwn("belt")) .. ", safe " .. tostring(ZeD.Safe.on()))
    say("summary: " .. passes .. " PASS, " .. fails .. " FAIL")
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
