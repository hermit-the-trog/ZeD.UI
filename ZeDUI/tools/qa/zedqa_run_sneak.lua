-- ZeDUI/tools/qa/zedqa_run_sneak.lua  (Nov 12 2026, punch list 121)
-- Run and sneak on one button (42/media/lua/client/ZeD/Input/RunSneak.lua). Two parts.
--   A, by itself, no controller needed: the module is driven through ZeD.Input.RunSneak.qaInput on the QA character,
--      in both of the game's layouts (the stand-in's mode: "run" is Original's Run button, "crouch" is Default's
--      Crouch button), so its timing and the two things it changes (the stance, and the game's run flag) are checked
--      inside the game's real frame:
--      * the game itself clears the run flag every frame while "Toggle to run" is off (the reason the module sets it
--        on OnPlayerUpdate, between the game's input step and its input read);
--      * Original: switched off nothing; a still hold crouches (not before 400 ms), a second stands; a tap nothing;
--        crouched and moving stands; standing and moving leaves the stance and the run flag alone;
--      * Default: a still hold crouches and stands; moving, the run flag is on from 400 ms for as long as the hold
--        lasts and off within two frames of the release; crouched and moving stands and runs; the switch turned off
--        mid-run drops the flag at once; L3's radial menu belongs to the module only in this mode.
--      The stand-in cannot make the character really move or run (that reads the real stick): that is part B.
--   B, by hand with the director's pad: the steps are printed ("ZEDQA rs HAND"), the switch stays on for four
--      minutes, and every change of crouch, run, sprint, the run flag and the module's state on each local player is
--      logged ("ZEDQA rs live"), beside the module's own "[ZeD.Input] run-sneak" lines. Then the switch is put back.
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

local preset = getCore().getOptionGamepadBindingPreset and getCore():getOptionGamepadBindingPreset() or "?"
local ttr = getCore().isToggleToRun and getCore():isToggleToRun() or false
local mode = RS.holdMode()
say("the game's controller layout: " .. tostring(preset) .. "; Run is on a " .. tostring(RS.runBindingKind())
    .. "; the hold button: " .. tostring(mode) .. "; Toggle to run: " .. tostring(ttr))

-- kept to put back
local wasVal = opt:getValue()
local wasSneak = p:isSneaking()
local wasForce = p:isForceRun()

-- steps on wall-clock time, checked on each drawn frame (the module itself runs on OnPlayerUpdate)
local Q = {}
local function after(ms, fn) Q[#Q + 1] = { ms = ms, fn = fn } end
local function pad(m, held, moving) RS.qaInput(pn, { pad = true, mode = m, held = held, moving = moving }) end
local function act() local a, t = RS.lastAction(pn); return a, t end
local stamp

-- ----- A0: the game clears the run flag every frame (Toggle to run off) -----
after(0, function()
    p:setForceRun(false)
    p:setForceRun(true)
end)
after(200, function()
    if ttr then
        say("A0: Toggle to run is on: the game keeps the flag (the module puts back what it found)")
        p:setForceRun(wasForce)
    else
        check(not p:isForceRun(), "A0: a run flag set once is cleared by the game within a frame (Toggle to run off)")
    end
end)

-- ----- A1: Original, the Run button -----
after(0, function()
    p:setSneaking(false)
    opt:setValue(1)
    pad("run", false, false)
    say("A1: Original layout (the Run button), the switch Off")
end)
after(200, function() pad("run", true, false) end)
after(900, function()
    check(not p:isSneaking(), "A1: switched off, a hold standing still does nothing")
    pad("run", false, false)
    opt:setValue(2)
    say("A1: the switch On")
end)
after(300, function() pad("run", true, false) end)
after(250, function() check(not p:isSneaking(), "A1: standing still, no crouch at about 250 ms") end)
after(350, function()
    check(p:isSneaking(), "A1: standing still, a hold crouches by 600 ms")
    check(act() == "crouch", "A1: lastAction crouch")
end)
after(900, function()
    check(p:isSneaking(), "A1: one thing per hold (held 1.5 s, still crouched)")
    pad("run", false, false)
end)
after(300, function() pad("run", true, false) end)
after(700, function()
    check(not p:isSneaking() and act() == "stand", "A1: a second hold stands up")
    pad("run", false, false)
end)
after(300, function() pad("run", true, false) end)
after(150, function() pad("run", false, false) end)
after(700, function() check(not p:isSneaking(), "A1: a tap standing still changes nothing") end)
after(0, function() p:setSneaking(true); pad("run", false, true) end)
after(200, function() pad("run", true, true) end)
after(150, function() check(p:isSneaking(), "A1: crouched and moving, still crouched at about 150 ms") end)
after(550, function()
    check(not p:isSneaking() and act() == "stand-run", "A1: crouched and moving, a hold stands up")
    check(not p:isForceRun() or ttr, "A1: the Run button leaves the run flag to the game")
    pad("run", false, false)
end)
after(300, function() local _, t = act(); stamp = t; pad("run", false, true) end)
after(200, function() pad("run", true, true) end)
after(800, function()
    local _, t = act()
    check(not p:isSneaking() and t == stamp, "A1: standing and moving, the stance is left alone")
    check(RS.ownsHold(pn, JoypadButton.LeftStick) == false, "A1: L3's radial menu stays the game's")
    pad("run", false, false)
end)

-- ----- A2: Default, the Crouch button -----
after(300, function()
    say("A2: Default layout (the Crouch button)")
    pad("crouch", false, false)
    check(RS._zedOrigRepeatLeft ~= nil and RS.ownsHold(pn, JoypadButton.LeftStick),
          "A2: L3's radial menu belongs to the hold (the game's menu step is wrapped)")
end)
after(200, function() pad("crouch", true, false) end)
after(600, function() check(p:isSneaking() and act() == "crouch", "A2: a still hold crouches"); pad("crouch", false, false) end)
after(300, function() pad("crouch", true, false) end)
after(600, function() check(not p:isSneaking() and act() == "stand", "A2: a second still hold stands"); pad("crouch", false, false) end)
after(300, function() pad("crouch", false, true) end)
after(200, function() pad("crouch", true, true) end)
after(250, function() check(not p:isForceRun() or ttr, "A2: moving, no run flag at about 250 ms") end)
after(350, function()
    check(p:isForceRun(), "A2: moving, the run flag is on by 600 ms (set on OnPlayerUpdate, still on at the frame's end)")
    check(RS.getState(pn) == "running" and act() == "run", "A2: state running, lastAction run")
end)
after(1500, function() check(p:isForceRun() and RS.getState(pn) == "running", "A2: still on after 1.5 s more held") end)
after(0, function() pad("crouch", false, true) end)
after(100, function() check(not p:isForceRun(), "A2: let go, the flag is off again") end)
after(200, function() p:setSneaking(true); pad("crouch", true, true) end)
after(700, function()
    check(not p:isSneaking() and p:isForceRun() and act() == "stand-run", "A2: crouched and moving, a hold stands and runs")
    opt:setValue(1)
end)
after(100, function()
    check(not p:isForceRun(), "A2: the switch turned off mid-run drops the flag at once")
    opt:setValue(2)
    pad("crouch", false, false)
end)
after(200, function()
    RS.qaInput(pn, nil)
    p:setSneaking(wasSneak)
    if ttr then p:setForceRun(wasForce) end
    say(fails == 0 and "A: all checks passed" or ("A: " .. fails .. " failed"))
end)

-- ----- B: by hand with the pad -----
local HAND = {
    "The switch is ON for 4 minutes. Original is the game's default layout (Options > Controller).",
    "ORIGINAL 1. Stand still, hold RT about half a second: crouches. Hold it again: stands.",
    "ORIGINAL 2. Walk, hold RT: runs while held (the game's run), walks on release. Stamina drains as the game's run.",
    "ORIGINAL 3. Crouched, walk and hold RT: a moment of crouched run, then stands up and runs.",
    "ORIGINAL 4. Quick taps of RT: walking, a short run as before; standing still, nothing.",
    "ORIGINAL 5. L3 as before: a tap crouches, a hold opens the left joystick radial menu.",
    "DEFAULT: switch the layout to Default in Options > Controller (put it back to Original after).",
    "DEFAULT 6. Stand still, hold L3 about half a second: crouches; again: stands. The radial menu does not open.",
    "DEFAULT 7. A quick tap of L3: the crouch toggles as before.",
    "DEFAULT 8. Walk with a gentle push, hold L3: after half a second runs, as long as L3 is held; release: walks.",
    "DEFAULT 9. Crouched and walking, hold L3: stands up and runs.",
    "DEFAULT 10. A full push without L3: the game's own run; R3 still sprints on a full push.",
    "DEFAULT 11. Running on L3, open a ZeD window (LB) or turn the switch off: the run stops at once and stays stopped.",
    "DEFAULT 12. Options > Controls > Toggle to run on: an L3 run still ends on release; a run you toggle on stays on.",
    "BOTH 13. Aim and pull RT: the attack as before, no crouch.",
    "BOTH 14. Split screen, if a second pad is in: each player's hold and run are their own.",
}
local watchMs = 240000
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
    local m, b = RS.holdMode()
    for i = 0, n - 1 do
        local q = getSpecificPlayer(i)
        if q then
            local bind = q:getJoypadBind()
            local held = bind >= 0 and b ~= nil and b:isDown(bind) or false
            local moving = bind >= 0 and CharacterJoypadAxis2dBinding.Movement:isApplied(bind) or false
            local line = string.format("p%d sneaking=%s running=%s sprinting=%s flag=%s | %s held=%s stick=%s | %s", i,
                tostring(q:isSneaking()), tostring(q:isRunning()), tostring(q:isSprinting()), tostring(q:isForceRun()),
                tostring(m), tostring(held), tostring(moving), RS.getState(i))
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
