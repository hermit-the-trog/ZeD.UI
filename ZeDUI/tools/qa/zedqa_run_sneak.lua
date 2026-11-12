-- ZeDUI/tools/qa/zedqa_run_sneak.lua  (Nov 12 2026, punch list 121)
-- Run button also sneaks (42/media/lua/client/ZeD/Input/RunSneak.lua). Two parts.
--   A, by itself, no controller needed: the module is driven through ZeD.Input.RunSneak.qaInput on the QA character,
--      so its timing and its one call (setSneaking) are checked in the real game: switched off, a hold does nothing;
--      standing still, a hold crouches (not before 400 ms) and a second hold stands; a tap changes nothing; crouched
--      and moving, a hold stands up; standing and moving, a hold leaves the stance alone. The stand-in cannot make the
--      character really run (the game's run reads the real stick and trigger): that is part B.
--   B, by hand with the director's pad: the steps are printed ("ZEDQA rs HAND"), the switch stays on for three
--      minutes, and every change of crouch, run, sprint and the module's state on each local player is logged
--      ("ZEDQA rs live"), beside the module's own "[ZeD.Input] run-sneak" lines. Then the switch is put back.
-- Run through the bridge (-debug): copy to Zomboid/Lua/zedqa.lua and touch zedqa.go, on foot, game unpaused.
-- grep "ZEDQA rs" (and "run-sneak") in console.txt.
local p = getPlayer()
local function say(s) print("ZEDQA rs " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end

local RS = ZeD and ZeD.Input and ZeD.Input.RunSneak
local S = ZeD and ZeD.Settings
local opt = S and S.runSneakOption
if not (p and RS and opt) then say("ERR ZeD.Input.RunSneak or the runSneak option is not loaded"); say("DONE"); return end
if p:getVehicle() then say("ERR the character is in a car: get out first"); say("DONE"); return end
local pn = p:getPlayerNum()
if isGamePaused() then setGameSpeed(1) end

-- what the game's Run is on (the Original layout, the game's default, puts it on the right trigger)
local preset = getCore().getOptionGamepadBindingPreset and getCore():getOptionGamepadBindingPreset() or "?"
local kind = RS.runBindingKind()
say("the game's controller layout: " .. tostring(preset) .. "; Run is on a " .. tostring(kind))
local usable = (kind == "button" or kind == "trigger")
if not usable then say("WARN Run is not on a button or trigger: by design the module does nothing, part A's holds will FAIL") end

-- kept to put back
local wasVal = opt:getValue()
local wasSneak = p:isSneaking()

-- steps run on wall-clock time, checked on each drawn frame (the module itself ticks on OnTick)
local Q = {}
local function after(ms, fn) Q[#Q + 1] = { ms = ms, fn = fn } end
local function pad(run, moving) RS.qaInput(pn, { pad = true, run = run, moving = moving }) end
local function act() local a, t = RS.lastAction(pn); return a, t end

-- ----- A: by itself -----
after(0, function()
    p:setSneaking(false)
    opt:setValue(1)
    pad(false, false)
    say("A: the switch Off, the character standing")
end)
after(200, function() pad(true, false) end)
after(900, function()
    check(not p:isSneaking(), "switched off: a hold standing still does nothing")
    pad(false, false)
    opt:setValue(2)
    say("A: the switch On")
end)
after(300, function() pad(true, false) end)
after(250, function() check(not p:isSneaking(), "standing still: no crouch at about 250 ms") end)
after(350, function()
    check(p:isSneaking(), "standing still: a hold crouches by 600 ms")
    check(act() == "crouch", "lastAction: crouch")
end)
after(900, function()
    check(p:isSneaking(), "one thing per hold: held 1.5 s, still crouched")
    pad(false, false)
end)
after(300, function() pad(true, false) end)
after(700, function()
    check(not p:isSneaking(), "a second hold stands up")
    check(act() == "stand", "lastAction: stand")
    pad(false, false)
end)
after(300, function() pad(true, false) end)
after(150, function() pad(false, false) end)
after(700, function() check(not p:isSneaking(), "a tap standing still changes nothing") end)
local stamp
after(0, function()
    p:setSneaking(true)
    local _, t = act(); stamp = t
    pad(false, true)
end)
after(200, function() pad(true, true) end)
after(150, function() check(p:isSneaking(), "crouched and moving: still crouched at about 150 ms") end)
after(550, function()
    check(not p:isSneaking(), "crouched and moving: a hold stands up")
    check(act() == "stand-run", "lastAction: stand-run")
    pad(false, false)
end)
after(300, function() local _, t = act(); stamp = t; pad(false, true) end)
after(200, function() pad(true, true) end)
after(800, function()
    local _, t = act()
    check(not p:isSneaking() and t == stamp, "standing and moving: the stance is left alone")
    pad(false, false)
end)
after(200, function()
    RS.qaInput(pn, nil)
    p:setSneaking(wasSneak)
    say(fails == 0 and "A: all checks passed" or ("A: " .. fails .. " failed"))
end)

-- ----- B: by hand with the pad -----
local HAND = {
    "Run is the game's own binding: the right trigger (RT) in the Original layout. The switch is ON for 3 minutes.",
    "1. Stand still, hold RT about half a second: the character crouches. Hold it again: stands.",
    "2. Walk, hold RT: runs while held, walks again on release. Stamina drains as the game's run does.",
    "3. Crouched, walk and hold RT: a moment of crouched run, then stands up and runs. Release: stays standing.",
    "4. Quick taps of RT: walking, a short run as before; standing still, nothing.",
    "5. Options > Controls > Toggle to run on: a quick tap while walking still toggles the run; a hold still runs.",
    "6. Open a ZeD window with LB, hold RT: the character does nothing. Close it.",
    "7. Aim with the right stick and pull RT: the attack, no crouch.",
    "8. L3 still crouches as before; B (Original layout) still sprints while running.",
    "9. A gentle push inside the stick's dead zone counts as standing still: a hold crouches.",
    "10. Split screen, if a second pad is in: each player's hold is their own.",
}
local watchMs = 180000
after(0, function()
    for _, l in ipairs(HAND) do say("HAND " .. l) end
    opt:setValue(2)
end)
local last = {}
local started = nil
local function watch()
    local now = getTimestampMs()
    started = started or now
    local n = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, n - 1 do
        local q = getSpecificPlayer(i)
        if q then
            local bind = q:getJoypadBind()
            local runDown = bind >= 0 and CharacterJoypadButtonBinding.Run:isDown(bind) or false
            local moving = bind >= 0 and CharacterJoypadAxis2dBinding.Movement:isApplied(bind) or false
            local line = string.format("p%d sneaking=%s running=%s sprinting=%s | Run=%s stick=%s | %s", i,
                tostring(q:isSneaking()), tostring(q:isRunning()), tostring(q:isSprinting()),
                tostring(runDown), tostring(moving), RS.getState(i))
            if line ~= last[i] then
                last[i] = line
                say(string.format("live +%.1fs %s", (now - started) / 1000, line))
            end
        end
    end
    if now - started >= watchMs then
        Events.OnTick.Remove(watch)
        opt:setValue(wasVal)
        say("B: the watch ended; the switch is back to " .. (wasVal == 2 and "On" or "Off"))
        say(fails == 0 and "all checks passed" or (fails .. " failed"))
        say("DONE")
    end
end
after(0, function() Events.OnTick.Add(watch) end)

local qi, t0 = 1, nil
local function drive()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(drive); return end
    local now = getTimestampMs()
    t0 = t0 or now
    if now - t0 < s.ms then return end
    t0 = now
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(drive)
say("start")
