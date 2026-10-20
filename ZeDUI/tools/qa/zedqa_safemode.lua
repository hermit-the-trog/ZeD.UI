-- ZeDUI/tools/qa/zedqa_safemode.lua  (Oct 19 2026, reworked Oct 20)
-- In game on the ZeD-QA save: safe mode (SafeMode.lua).
--   a trip: the pair closes; vanilla's inventory page, hotbar, clock and moodle
--   column come back; the note shows through vanilla's dialog; the inventory
--   key goes to vanilla's own handler (pressed twice: the page hides, then
--   shows); a reset with the page showing brings ZeD back and hides it again;
--   the option: set On, then Off, with no forced re-read, so the half-second
--   poll has to pick each change up (within 700 ms);
--   the watchdog: a burst of a few frames (100 faults in the first) leaves ZeD
--   on; one place failing every frame trips it at two seconds, not before.
-- Every verdict is an "ok <name>" or "FAIL <name>" line.
-- Everything is put back at the end (the pair as it was, the option, and
-- ZeD_safe_trip.txt emptied so the next launch shows no note).
-- Steps run in order, each a number of ticks after the one before ended (the
-- timed ones wait on the clock, so the ticks below are at 60 fps):
--     2  open the pair if shut          40  baseline
--    45  trip                           75  tripped (shot 1)
--    80  the note closes                90  inventory key, first press
--   100  inventory key, second press   105  shot 2
--   110  reset                         140  reset, page hidden again
--   145  reopen the pair               175  reopened
--   180  option On, polled to ~210     240  option on (shot 3)
--   245  option Off, polled to ~275    305  option off
--   310  burst, five ticks to 314      ~465 burst left ZeD on (2.5 s later)
--  ~470  every-frame faults, ~590 trip ~620 watchdog note, reset
--  ~650  restore                      ~680 restored, DONE
-- Screenshots zqa_safe_*.png. grep "ZEDQA safe".
local function say(s) print("ZEDQA safe " .. tostring(s)) end
local function check(name, cond) say((cond and "ok " or "FAIL ") .. name); return cond end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_safe_" .. n .. ".png") end) end
local S = ZeD.Safe
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local opt = ZeD.Settings.safeModeOption
local was = opt:getValue()
local wasOpen = (CW.isOpen() and WW.isOpen()) and true or false
local INV_KEY = getCore():getKey("Toggle Inventory")

local function pair() return tostring(CW.isOpen()) .. "/" .. tostring(WW.isOpen()) end
local function bothShut() return not CW.isOpen() and not WW.isOpen() end
local function vanillaInv() local vi = getPlayerInventory(0); return vi and vi:isVisible() or false end
local function hotbar()
    local orig = S._originals.ISHotbar
    if not orig then return "no original kept" end
    return (ISHotbar.render == orig.render) and "vanilla" or "replaced"
end
local function clock()
    local c = UIManager.getClock()
    if not c then return "none" end
    return "y " .. tostring(c:getY()) .. " visible " .. tostring(c:isVisible())
end
local function speedY() local sc = UIManager.getSpeedControls(); return sc and tostring(sc:getY()) or "none" end
local function moodles() local l = ZeD.Moodles.getLayer(0); return l and tostring(l:isVisible()) or "none" end
local function note()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local el = ui:get(i)
        local t = el:getTable()
        if t and t.Type == "ISModalDialog" and el:isVisible() and tostring(t.text or ""):find("stepped aside", 1, true) then return t end
    end
    return nil
end
local function closeNote()
    local n = note()
    if not n then return false end
    if n.ok then n:onClick(n.ok) else n:destroy() end
    return true
end
local function state()
    return "on " .. tostring(S.on()) .. " | pair " .. pair() .. " | vanilla inv " .. tostring(vanillaInv())
        .. " | hotbar " .. hotbar() .. " | clock " .. clock() .. " | speed y " .. speedY() .. " | moodle layer " .. moodles()
end
local function tripFileEmpty()
    local line
    pcall(function()
        local r = getFileReader("ZeD_safe_trip.txt", false)
        if r then line = r:readLine(); r:close() end
    end)
    return line == nil or line == ""
end

-- ----------------------------------------------------------------------------
-- The sequence: step(after, fn) runs fn once, `after` ticks after the step
-- before it ended; poll(after, maxTicks, fn, onTimeout) runs fn every tick
-- until it returns true, or calls onTimeout once maxTicks have gone by
-- ----------------------------------------------------------------------------
local queue = {}
local function step(after, fn) queue[#queue + 1] = { after = after, fn = fn } end
local function poll(after, maxTicks, fn, onTimeout) queue[#queue + 1] = { after = after, fn = fn, max = maxTicks, timeout = onTimeout } end

local before1, after1, after2

step(2, function()
    if not (CW.isOpen() and WW.isOpen()) then CW.toggleBothPaired(0) end
end)
step(38, function()
    say("baseline: " .. state())
    check("baseline", S.on() == false and CW.isOpen() and WW.isOpen() and not vanillaInv() and hotbar() == "replaced")
end)
step(5, function() S.trip("qa trip") end)
step(30, function()
    local n = note()
    say("tripped: " .. state() .. " | note " .. tostring(n ~= nil))
    -- (the clock's visible flag is the engine's: it shows only with a watch or clock on you)
    local c = UIManager.getClock()
    check("tripped", S.on() and bothShut() and vanillaInv() and hotbar() == "vanilla"
        and (c == nil or c:getY() >= 0) and moodles() ~= "true" and n ~= nil)
    shot(1)
end)
step(5, function() check("the note shows and closes", closeNote()) end)
-- the inventory key twice: vanilla's page hides, then shows again, and the pair stays shut
step(10, function()
    before1 = vanillaInv()
    CW._onKeyPressed(INV_KEY)
    after1 = vanillaInv()
end)
step(10, function()
    CW._onKeyPressed(INV_KEY)
    after2 = vanillaInv()
    say("inventory key (" .. tostring(INV_KEY) .. "): vanilla page " .. tostring(before1) .. " -> " .. tostring(after1)
        .. " -> " .. tostring(after2) .. " | pair " .. pair())
    check("inventory key goes to vanilla", before1 and not after1 and after2 and bothShut())
end)
step(5, function() shot(2) end)
-- the reset runs with vanilla's page showing: the windows hook's enter hides it again
step(5, function()
    say("before reset: vanilla inv " .. tostring(vanillaInv()))
    S.reset()
end)
step(30, function()
    local c = UIManager.getClock()
    say("reset: " .. state())
    check("reset", S.on() == false and hotbar() == "replaced" and (c == nil or c:getY() < 0) and moodles() == "true")
    check("reset hides vanilla's page again", not vanillaInv())
end)
step(5, function() CW.toggleBothPaired(0) end)
step(30, function()
    say("reopened: pair " .. pair() .. " | vanilla inv " .. tostring(vanillaInv()))
    check("reopened", CW.isOpen() and WW.isOpen() and not vanillaInv())
end)

-- the option, with no forced re-read: the half-second poll has to pick it up
local function optionPoll(value, want, name)
    local t0
    step(5, function()
        opt:setValue(value)
        t0 = getTimestampMs()
    end)
    poll(0, 600, function()
        local ms = getTimestampMs() - t0
        if S.on() == want then
            say(name .. ": picked up after " .. tostring(ms) .. " ms")
            check(name, ms <= 700)
            return true
        end
        if ms > 700 then
            say(name .. ": not picked up after " .. tostring(ms) .. " ms")
            check(name, false)
            return true
        end
        return false
    end, function()
        say(name .. ": the tick budget ran out after " .. tostring(getTimestampMs() - t0) .. " ms")
        check(name, false)
    end)
end

optionPoll(2, true, "option On picked up by the poll")
step(30, function()
    say("option on: " .. state())
    check("option on", S.on() and bothShut() and vanillaInv() and hotbar() == "vanilla" and note() == nil)
    shot(3)
end)
optionPoll(1, false, "option Off picked up by the poll")
step(30, function()
    say("option off: " .. state())
    check("option off", S.on() == false and hotbar() == "replaced" and not vanillaInv())
end)

-- the watchdog: a burst of five frames (the first with 100 faults, which count
-- once) leaves ZeD on, 2.5 s later still
local tBurst, burstTicks = nil, 0
poll(5, 30, function()
    if not tBurst then
        tBurst = getTimestampMs()
        for i = 1, 100 do S.fault("qa burst", "burst " .. i) end
    else
        S.fault("qa burst", "burst tick " .. burstTicks)
    end
    burstTicks = burstTicks + 1
    return burstTicks >= 5
end, function() say("burst: ran out of ticks") end)
poll(0, 3000, function()
    local ms = getTimestampMs() - tBurst
    if S.on() then
        say("burst: tripped after " .. tostring(ms) .. " ms")
        check("watchdog: a five-frame burst leaves ZeD on", false)
        -- taken back, so the every-frame check below starts from ZeD on
        closeNote()
        S.reset()
        return true
    end
    if ms < 2500 then return false end
    say("burst: " .. tostring(burstTicks) .. " ticks, still off after " .. tostring(ms) .. " ms")
    check("watchdog: a five-frame burst leaves ZeD on", true)
    return true
end, function()
    say("burst: the tick budget ran out")
    check("watchdog: a five-frame burst leaves ZeD on", false)
end)

-- one place failing every frame: no trip before two seconds, a trip by 2.5 s
local tStreak, lastAt, maxGap, hits = nil, nil, 0, 0
poll(5, 3000, function()
    local now = getTimestampMs()
    if not tStreak then tStreak = now end
    if lastAt and now - lastAt > maxGap then maxGap = now - lastAt end
    lastAt = now
    if not S.on() then
        S.fault("qa streak", "streak " .. hits)
        hits = hits + 1
    end
    local ms = getTimestampMs() - tStreak
    if S.on() then
        say("streak: tripped after " .. tostring(ms) .. " ms, " .. tostring(hits) .. " frames, longest gap " .. tostring(maxGap) .. " ms")
        check("watchdog: below two seconds of failures ZeD stays on", ms >= 1990)
        check("watchdog: two seconds of failures every frame trip it", ms <= 2500)
        return true
    end
    if ms <= 2500 then return false end
    say("streak: no trip after " .. tostring(ms) .. " ms, " .. tostring(hits) .. " frames, longest gap " .. tostring(maxGap) .. " ms")
    check("watchdog: below two seconds of failures ZeD stays on", true)
    check("watchdog: two seconds of failures every frame trip it", false)
    return true
end, function()
    say("streak: the tick budget ran out")
    check("watchdog: two seconds of failures every frame trip it", false)
end)
step(30, function()
    check("watchdog note shows and closes", closeNote())
    S.reset()
end)

step(30, function()
    opt:setValue(was); S.reread()
    if wasOpen and not (CW.isOpen() and WW.isOpen()) then CW.toggleBothPaired(0)
    elseif not wasOpen and CW.isOpen() and WW.isOpen() then CW.toggleBothPaired(0) end
    -- ZeD keeps vanilla's pages hidden while it runs, pair open or not
    local vi, vl = getPlayerInventory(0), getPlayerLoot(0)
    if vi then vi:setVisible(false) end
    if vl then vl:setVisible(false) end
    pcall(function()
        local f = getFileWriter("ZeD_safe_trip.txt", true, false)
        f:write(""); f:close()
    end)
end)
step(30, function()
    say("restored: " .. state())
    local open = (CW.isOpen() and WW.isOpen()) and true or false
    local safeNow = (was == 2)
    check("restored", S.on() == safeNow and (safeNow or (open == wasOpen and not vanillaInv())) and tripFileEmpty())
    say("DONE")
end)

-- ----------------------------------------------------------------------------
-- Driving it
-- ----------------------------------------------------------------------------
local tick, qi, lastDone = 0, 1, 0
local MAX_TICKS = 12000   -- a stuck run stops here rather than ticking forever
local function onTick()
    tick = tick + 1
    local s = queue[qi]
    if not s or tick > MAX_TICKS then
        if s then say("FAIL the run stopped at tick " .. tick .. " on step " .. qi) end
        Events.OnTick.Remove(onTick)
        return
    end
    if not s.startTick then
        if tick - lastDone < s.after then return end
        s.startTick = tick
    end
    local done = true
    local ok, r = pcall(s.fn)
    if not ok then
        say("ERR step " .. qi .. " (tick " .. tick .. ") " .. tostring(r))
    elseif s.max then
        done = r == true
        if not done and tick - s.startTick >= s.max then
            local ok2, e2 = pcall(s.timeout)
            if not ok2 then say("ERR step " .. qi .. " timeout " .. tostring(e2)) end
            done = true
        end
    end
    if done then
        lastDone = tick
        qi = qi + 1
    end
end
Events.OnTick.Add(onTick)
say("start")
