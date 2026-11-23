-- ZeDUI/tools/qa/hg_fit.lua  (Nov 23 2026, QA; tag hg_fit): every exercise started from ZeD's Health tab, muscle strain
-- on every muscle and fatigue at every step. The director, Nov 23 2026: "Do all the workouts. Get the muscle strain,
-- fatigue in every muscle." Run after zedqa_prelude.lua and rt_kit.lua (hg.txt). grep "ZEDQA hg_fit".
--
-- What the game does (42.22, read from the jar's Fitness class): each repetition of an exercise (Fitness.exerciseRepeat)
-- raises its regularity, takes endurance, gives Fitness and Strength XP and adds PENDING strain to each region the
-- exercise names ("legs", "arms", "chest", "abs": FitnessExercises.lua). The strain reaches the body 12 game hours
-- later (a timer of 72 ten-minute steps, HOURS_FOR_STIFFNESS = 12), when Fitness.increasePain lays it on: arms =
-- ForeArm_L, ForeArm_R, UpperArm_L, UpperArm_R (not the hands); legs = UpperLeg_L, UpperLeg_R, LowerLeg_L, LowerLeg_R
-- (not the feet); chest = Torso_Upper; abs = Torso_Lower. The pending strain is read with
-- Fitness.getCurrentExeStiffnessInc(region); a run cannot wait 12 hours, so the parts are then given the strain the
-- way the game will give it, and the Health tab is checked on them.
-- Checks:
--   start     god mode off (it keeps the moodles off) with the guard on; the Health tab open
--   exercise  for each of the 7 (squats, pushups, situp, burpees, barbellcurl, dumbbellpress, bicepscurl; a barbell and
--             a dumbbell given): picked in the Health tab's band (closeMenu), 10 minutes, Start allowed, started with
--             startSelected: the game's ISFitnessAction for it at the queue's head; repetitions done; its regularity up;
--             the pending strain up in exactly its regions (what rose is printed); stopped; then the strain laid on the
--             parts the game will lay it on: each listed as Minor Muscle Strain, tinted strainMinor, counted in the
--             summary and named in the Muscle Strain block
--   gear      vanilla's fitness window puts the weapon back in the hand and the bags back on after the exercise
--             (ISFitnessUI:update, ISFitnessUI.lua:213-229); ZeD's Start takes them off (HealthTab._startExercise):
--             after squats the hammer is back in the hand and the bag back on (a FAIL here is a gameplay loss)
--   strain    minor (10) and heavy (40) on each of the 17 parts, one at a time, held against the game's fade:
--             the list's word and severity, the figure's tint (strainMinor / strainHeavy, figureColor agrees), the
--             summary ("No injuries, Muscle Strain: 1", its dot in the tint), the Muscle Strain block's row; then
--             heavy on all 17: "Muscle Strain: 17", 17 rows, the block drawn, on screen (picture hg_fit_strain17_<w>x<h>)
--   fatigue   Endurance at each moodle step (0.74, 0.49, 0.24, 0.09) and Tired at each (0.61, 0.71, 0.81, 0.91): the
--             Moodles block names the moodle, Start follows vanilla's rule (Endurance level over 2 blocks, Tired does
--             not) and the block says why; heavy pain on every part (Pain level over 3 blocks) and a heavy load
--             (Heavy Load level over 2 blocks)
--   put back  stiffness, stats, regularity, pending strain, Fitness and Strength XP, the hands, the bags worn; no Lua error
-- Puts back: every part's stiffness, wetness and pain as found, the stats (endurance, fatigue, pain, hunger, thirst,
-- stress, boredom, unhappiness, panic, wetness), the regularity map (a copy taken at the start), the pending strain the
-- run added (Fitness.removeStiffnessValue on a region that had none), the Fitness and Strength XP, the hands, the bags
-- worn, god mode, invincible, the game speed, the picked exercise and its minutes, the figure's fold, the windows and
-- the tab; the barbell, dumbbell, hammer, bag and load given taken back.
if not RT then print("ZEDQA hg_fit ERR rt_kit.lua did not run first"); print("ZEDQA hg_fit DONE"); return end
local Q = RT.make("hg_fit")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, live = false, t0 = getTimestampMs(), held = {},
            want = nil, keeping = false }
local Z = ZeD

S.EXERCISES = { "squats", "pushups", "situp", "burpees", "barbellcurl", "dumbbellpress", "bicepscurl" }
S.REGIONS = { "arms", "legs", "chest", "abs" }
-- where Fitness.increasePain lays each region's strain (the jar's bytecode, 42.22)
S.REGION_PARTS = {
    arms = { "ForeArm_L", "ForeArm_R", "UpperArm_L", "UpperArm_R" },
    legs = { "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R" },
    chest = { "Torso_Upper" },
    abs = { "Torso_Lower" },
}
S.PARTS = {
    { bp = "Head", fig = "Head" }, { bp = "Neck", fig = "Neck" }, { bp = "Torso_Upper", fig = "Upper Torso" },
    { bp = "Torso_Lower", fig = "Lower Torso" }, { bp = "Groin", fig = "Groin" },
    { bp = "UpperArm_L", fig = "Left Upper Arm" }, { bp = "UpperArm_R", fig = "Right Upper Arm" },
    { bp = "ForeArm_L", fig = "Left Forearm" }, { bp = "ForeArm_R", fig = "Right Forearm" },
    { bp = "Hand_L", fig = "Left Hand" }, { bp = "Hand_R", fig = "Right Hand" },
    { bp = "UpperLeg_L", fig = "Left Upper Leg" }, { bp = "UpperLeg_R", fig = "Right Upper Leg" },
    { bp = "LowerLeg_L", fig = "Left Lower Leg" }, { bp = "LowerLeg_R", fig = "Right Lower Leg" },
    { bp = "Foot_L", fig = "Left Foot" }, { bp = "Foot_R", fig = "Right Foot" },
}
S.STATS = { "ENDURANCE", "FATIGUE", "PAIN", "HUNGER", "THIRST", "STRESS", "BOREDOM", "UNHAPPINESS", "PANIC", "WETNESS" }
-- the stats the put-back checks (pain and wetness follow the body parts, which are put back, and settle on their own)
S.CHECK_STATS = { "ENDURANCE", "FATIGUE", "HUNGER", "THIRST", "STRESS", "BOREDOM", "UNHAPPINESS", "PANIC" }

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.bd() local b = nil; pcall(function() b = S.p:getBodyDamage() end); return b end
function S.part(name)
    local bd, t = S.bd(), BodyPartType[name]
    if not (bd and t) then return nil end
    local bp = nil
    pcall(function() bp = bd:getBodyPart(t) end)
    return bp
end
function S.typeOf(bp) local s = nil; if bp then pcall(function() s = tostring(bp:getType()) end) end; return s end
function S.has(s, sub) return type(s) == "string" and string.find(s, sub, 1, true) ~= nil end
function S.n(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    return tostring(math.floor(x * 100 + 0.5) / 100)
end
function S.near(a, b, e) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (e or 0.002) end
-- (why a session ends with no repetition: the character's state and the things ISFitnessAction:update stops on)
function S.exeState(a)
    local o = {}
    local function add(k, f) local ok, v = pcall(f); o[#o + 1] = k .. " " .. (ok and tostring(v) or "?") end
    add("state", function() return S.p:getCurrentState() == FitnessState.instance() and "fitness" or tostring(S.p:getCurrentState()) end)
    add("endurance moodle", function() return S.p:getMoodles():getMoodleLevel(MoodleType.ENDURANCE) end)
    add("ms left", function() return a.endMS - getGameTime():getCalender():getTimeInMillis() end)
    add("aiming", function() return S.p:isAiming() end)
    add("climbing", function() return S.p:isClimbing() end)
    add("sitting", function() return S.p:isSittingOnFurniture() end)
    add("moving", function() return S.p:pressedMovement(true) end)
    add("ExerciseStarted", function() return S.p:getVariableString("ExerciseStarted") end)
    add("ExerciseEnded", function() return S.p:getVariableString("ExerciseEnded") end)
    add("ExerciseType", function() return S.p:getVariableString("ExerciseType") end)
    add("reps", function() return a.repnb end)
    return table.concat(o, ", ")
end
function S.speed(n)
    if n == nil then return end
    local f = ZEDQA_SPEED or setGameSpeed
    if f then pcall(f, n) end
end
function S.gameSpeed() local v = nil; pcall(function() v = getGameSpeed() end); return v end
function S.stat(k)
    local v = nil
    if CharacterStat[k] then pcall(function() v = S.p:getStats():get(CharacterStat[k]) end) end
    return v
end
function S.setStat(k, v)
    if v ~= nil and CharacterStat[k] then pcall(function() S.p:getStats():set(CharacterStat[k], v) end) end
end
function S.moodle(key)
    local n = 0
    if MoodleType[key] then pcall(function() n = S.p:getMoodles():getMoodleLevel(MoodleType[key]) end) end
    return n or 0
end
function S.moodleName(key)
    local s = nil
    if MoodleType[key] then pcall(function() s = S.p:getMoodles():getMoodleDisplayString(MoodleType[key]) end) end
    return s
end
function S.stiff(name) local v = nil; local bp = S.part(name); if bp then pcall(function() v = bp:getStiffness() end) end; return v end
function S.setStiff(name, v) local bp = S.part(name); if bp and v then pcall(function() bp:setStiffness(v) end) end end
function S.xp(perk) local v = nil; pcall(function() v = S.p:getXp():getXP(perk) end); return v end
function S.level(perk) local v = nil; pcall(function() v = S.p:getPerkLevel(perk) end); return v end
function S.putXp(perk, xp0, lvl0)
    if xp0 == nil or lvl0 == nil then return end
    pcall(function() S.p:getXp():setXPToLevel(perk, lvl0) end)
    local x = S.xp(perk)
    if x and xp0 > x + 0.001 then pcall(function() S.p:getXp():AddXPNoMultiplier(perk, xp0 - x) end) end
end
function S.cText(c) return c and string.format("%.2f,%.2f,%.2f", c.r or -1, c.g or -1, c.b or -1) or "none" end
function S.sameC(a, b) return a ~= nil and b ~= nil and S.near(a.r, b.r) and S.near(a.g, b.g) and S.near(a.b, b.b) end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
function S.screenTag()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w) .. "x" .. math.floor(h)
end
function S.fitness() local f = nil; pcall(function() f = S.p:getFitness() end); return f end
-- an exercise's regularity, read off the map (a missing key is 0, as Fitness.getRegularity answers)
function S.reg(id)
    local v = nil
    pcall(function()
        local m = S.fitness():getRegularityMap()
        if m then v = m:get(id) end
    end)
    return tonumber(v) or 0
end
function S.pending(region) local v = 0; pcall(function() v = S.fitness():getCurrentExeStiffnessInc(region) end); return tonumber(v) or 0 end
function S.pendingTimer(region) local v = 0; pcall(function() v = S.fitness():getCurrentExeStiffnessTimer(region) end); return tonumber(v) or 0 end
function S.head()
    local a = nil
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        a = q and q.queue and q.queue[1] or nil
    end)
    return a
end
function S.exercising()
    local a = S.head()
    return a ~= nil and a.Type == "ISFitnessAction"
end
function S.clearQueue() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function S.wornContainers()
    local out = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local it = wi:get(i):getItem()
            if it and instanceof(it, "InventoryContainer") then out[#out + 1] = it end
        end
    end)
    return out
end
function S.isWorn(it)
    for _, x in ipairs(S.wornContainers()) do if x == it then return true end end
    return false
end
function S.itemName(it) local s = "nothing"; if it then pcall(function() s = it:getFullType() end) end; return tostring(s) end

-- ===================================================================== the hold (held every player update)
-- S.want = { stats = { K = v }, stiff = { bp = v }, pain = { bp = v } }
function S.apply()
    local W = S.want
    if not W then return end
    for k, v in pairs(W.stats or {}) do S.setStat(k, v) end
    for n, v in pairs(W.stiff or {}) do S.setStiff(n, v) end
    for n, v in pairs(W.pain or {}) do
        local bp = S.part(n)
        if bp then pcall(function() bp:setAdditionalPain(v) end) end
    end
end
function S.keep(pl) if S.want and pl == S.p then pcall(S.apply) end end
function S.stage(W)
    S.want = W
    S.apply()
    if not S.keeping then Events.OnPlayerUpdate.Add(S.keep); S.keeping = true end
end
function S.unstage()
    local W = S.want
    S.want = nil
    if S.keeping then Events.OnPlayerUpdate.Remove(S.keep); S.keeping = false end
    for n in pairs(W and W.stiff or {}) do S.setStiff(n, 0) end
    for n in pairs(W and W.pain or {}) do
        local bp = S.part(n)
        if bp then pcall(function() bp:setAdditionalPain(0) end) end
    end
end

-- ===================================================================== the guard (vk8_wounds'): god mode is off for the moodles
function S.noInfection(bd)
    if not bd then return end
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:IsInfected() then b:SetInfected(false) end
        if b:IsFakeInfected() then b:SetFakeInfected(false) end
    end
    if bd:isInfected() then bd:setInfected(false) end
    if bd:isIsFakeInfected() then bd:setIsFakeInfected(false) end
end
function S.bail(why)
    if S.bailed then return end
    S.bailed = true
    S.dead = true
    Q.check(false, "the run went on to its end", "stopped, on to the put-back: " .. tostring(why))
    if Q.backAt and Q.qi < Q.backAt then Q.qi = Q.backAt; Q.wait = nil end
end
function S.guard()
    local p, bd = S.p, S.bd()
    if not bd then return end
    if p:isDead() then
        if not S.deadSaid then
            S.deadSaid = true
            Q.check(false, "the character is alive", "DEAD during the run: restore the QA save from its backup")
            S.bail("the character died")
        end
        return
    end
    if S.found.zInf == false then S.noInfection(bd) end
    local h = bd:getOverallBodyHealth()
    if h < 75 then
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do parts:get(i):SetHealth(100) end
        S.topUps = (S.topUps or 0) + 1
    end
    if h < 35 and not S.bailed then
        p:setGodMod(true)
        S.bail("health fell to " .. S.n(h) .. ": god mode ON")
    end
    if getTimestampMs() - S.t0 > Q.maxMs + 150000 then
        S.live = false
        pcall(S.putBack)
        Q.say("ERR the put-back did not come in time: the guard put the character back")
    end
end
function S.safety()
    if not S.live then return end
    local ok, err = pcall(S.guard)
    if not ok and not S.guardSaid then
        S.guardSaid = true
        Q.say("ERR the guard threw: " .. tostring(err))
        pcall(function() S.p:setGodMod(true) end)
        S.bail("the guard threw: god mode ON")
    end
end

-- ===================================================================== the Health tab's read
function S.data() local w = RT.cw(); return w and w._healthCache or nil end
function S.fill() local w = RT.cw(); return w and w._healthFill or nil end
function S.entryOf(data, bpName)
    for _, e in ipairs(data and data.entries or {}) do
        if S.typeOf(e.bodyPart) == bpName then return e end
    end
    return nil
end
function S.figName(bpName) for _, P in ipairs(S.PARTS) do if P.bp == bpName then return P.fig end end; return nil end
function S.refresh()
    local w = RT.cw()
    if not w then return end
    S.oldData, S.oldFill = w._healthCache, w._healthFill
    w._healthAt = nil
    w._healthFillAt = nil
end
function S.fresh()
    local w = RT.cw()
    return w ~= nil and w._healthCache ~= nil and w._healthCache ~= S.oldData and w._healthFill ~= nil and w._healthFill ~= S.oldFill
end
function S.word(level) return getText(level >= 2 and "IGUI_health_Stiffness" or "IGUI_health_MinorStiffness") end
function S.fillRow(fill, e)
    for _, s in ipairs(fill and fill.strain or {}) do if e and s.name == e.name then return s end end
    return nil
end
-- the parts strained at one level, read back: is each listed with its word and named in the block?
function S.strainReady(parts, level)
    if not S.fresh() then return false end
    local d, fill = S.data(), S.fill()
    for _, n in ipairs(parts) do
        local e = S.entryOf(d, n)
        if not e then return false end
        local found = false
        for _, c in ipairs(e.conditions or {}) do if c.label == S.word(level) then found = true end end
        if not found or not S.fillRow(fill, e) then return false end
    end
    return d.strainedCount == #parts
end
-- the Health tab on strained parts: one line per part (list, figure, block) and one for the summary
function S.strainCheck(lab, parts, level, ok)
    local HT = Z.HealthTab
    local w = RT.cw()
    local d, fill = S.data(), S.fill()
    local fig = w and w._healthBodyFigure
    local sev = level >= 2 and "danger" or "warning"
    local tint = HT.strainColor(level)
    local bad = {}
    if not ok then bad[1] = "the tab did not catch up in 300 frames" end
    for _, n in ipairs(parts) do
        local e = S.entryOf(d, n)
        local fn = S.figName(n)
        local why = {}
        local hit = false
        for _, c in ipairs(e and e.conditions or {}) do if c.label == S.word(level) and c.severity == sev then hit = true end end
        if not hit then why[#why + 1] = "list: " .. (e and "no \"" .. S.word(level) .. "\" (" .. sev .. ")" or "not listed") end
        local c = fig and fig.colorMap and fig.colorMap[fn] or nil
        local hp = d and d.partHealth and d.partHealth[fn] or 100
        local okF, fc = pcall(HT.figureColor, d, fn, hp)
        if not (S.sameC(c, tint) and okF and S.sameC(fc, tint)) then
            why[#why + 1] = "figure " .. S.cText(c) .. ", figureColor " .. (okF and S.cText(fc) or tostring(fc)) .. ", want " .. S.cText(tint)
        end
        local row = S.fillRow(fill, e)
        if not (row and row.minor == (level < 2)) then why[#why + 1] = "Muscle Strain block: " .. (row and ("minor " .. tostring(row.minor)) or "no row") end
        if #why > 0 then bad[#bad + 1] = n .. ": " .. table.concat(why, ", ") end
    end
    -- the summary
    local okL, lines = pcall(HT.summaryLines, d)
    local text = (okL and lines and lines[1]) and tostring(lines[1].text) or "?"
    local dot = (okL and lines and lines[#lines]) and lines[#lines].dot or nil
    local want = Z.tr("UI_ZeD_Health_NoInjuriesStrain", getText("IGUI_health_Stiffness"), #parts)
    if not (d and d.woundedCount == 0 and d.strainedCount == #parts and text == want and S.sameC(dot, tint)) then
        bad[#bad + 1] = "summary \"" .. text .. "\" (want \"" .. want .. "\"), wounded " .. tostring(d and d.woundedCount)
            .. ", strained " .. tostring(d and d.strainedCount) .. ", dot " .. S.cText(dot)
    end
    Q.check(#bad == 0, lab .. ": the list, the figure, the Muscle Strain block and the summary",
        #bad == 0 and (#parts .. " part(s), \"" .. text .. "\"") or table.concat(bad, "; "))
end
-- the vanilla rule for Start (ISFitnessUI:updateButtons; the last rule that applies names the reason)
function S.ruleBlock()
    local key = nil
    if S.moodle("ENDURANCE") > 2 then key = "Tooltip_TooExhaustedFitness" end
    if S.moodle("HEAVY_LOAD") > 2 then key = "Tooltip_TooHeavyFitness" end
    local sit = false
    pcall(function() sit = S.p:getVariableBoolean("sitonground") or S.p:isSittingOnFurniture() end)
    if sit then key = "Tooltip_StandStillFitness" end
    if S.p:getVehicle() then key = "Tooltip_CantDriveAndFitness" end
    if S.moodle("PAIN") > 3 then key = "Tooltip_TooMuchPainFitness" end
    return key
end
function S.startCheck(lab)
    local HT = Z.HealthTab
    local w = RT.cw()
    local key = S.ruleBlock()
    local okS, can = pcall(HT.canStart, w)
    local okI, info = pcall(HT.exerciseInfo, S.p, HT.selectedExercise(w))
    local warn = (okI and info) and table.concat(info.warn or {}, "; ") or "?"
    local saysWhy = key == nil or S.has(warn, getText(key))
    Q.check(okS and can == (key == nil) and saysWhy,
        lab .. ": Start follows vanilla's rule" .. (key and (" (blocked: " .. getText(key) .. ")") or " (allowed)"),
        "canStart " .. tostring(can) .. "; endurance " .. S.moodle("ENDURANCE") .. ", tired " .. S.moodle("TIRED") .. ", pain "
        .. S.moodle("PAIN") .. ", heavy load " .. S.moodle("HEAVY_LOAD") .. "; the block says: " .. warn)
end

-- ===================================================================== windows and pictures
function S.holdWin(w)
    if not w then return end
    for _, h in ipairs(S.held) do if h.w == w then return end end
    S.held[#S.held + 1] = { w = w, own = rawget(w, "pointerOn") }
    w.pointerOn = function() return true end
end
function S.unholdAll()
    for _, h in ipairs(S.held) do h.w.pointerOn = h.own end
    S.held = {}
end
function S.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function S.shot(name, what)
    Q.step(1, function() if not S.dead then S.park(true) end end)
    Q.step(4, function()
        if S.dead then S.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        S.park(false)
    end)
    Q.waitMs(1500)
end
function S.until1(n, max, cond, fn)
    Q.waitFor(n, max, function() return S.dead or cond() end, function(ok) if not S.dead then fn(ok) end end)
end
function S.errStep(lab)
    Q.step(1, function()
        if S.dead then return end
        local e1 = S.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, lab .. ": no Lua error", (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        S.e0 = e1
    end)
end

-- ===================================================================== start
-- (the game's own bug, Nov 23 2026, hg_fit_ctl: in this world the calendar's millisecond time jumps a year back and
-- forth between reads, so ISFitnessAction:new can take an end time a year in the past and its first update stops the
-- session with no repetition; the game's own fitness window start did it 5 times in 10, ZeD's 1 in 11. For the run
-- the session's end time is set again from the clock it is read against, and each time is counted in a NOTE.)
-- (the game's calendar in the QA world: it reads a year near 1 and jumps a year between reads, so the game's own
-- fitness action can take an end time in the past and stop at once: hg_fit_ctl, Nov 23 2026, the game's own window
-- start did it 5 times in 10 and ZeD's 1 in 11. The game's side of a session is then a SKIP with that reason.)
function S.calOdd()
    local y = nil
    pcall(function() y = tonumber(tostring(getGameTime():getCalender():getTime()):match("(%d+)%s*$")) end)
    if y and y < 1900 then return y end
    return nil
end
S.CAL_WHY = "the game's own bug in this test world: its calendar reads year %s and jumps a year between reads, so the game's fitness action can stop at once (hg_fit_ctl: the game's own start 5 times in 10, ZeD's 1 in 11)"
function S.gameCheck(ok, what, detail)
    local y = S.calOdd()
    if not ok and y then Q.skip(what .. " | " .. tostring(detail), string.format(S.CAL_WHY, tostring(y))); return end
    Q.check(ok, what, detail)
end
function S.calWrap()
    if S.upd0 or not ISFitnessAction then return end
    S.upd0 = ISFitnessAction.update
    S.calFix = 0
    ISFitnessAction.update = function(self)
        pcall(function()
            local now = getGameTime():getCalender():getTimeInMillis()
            local span = (tonumber(self.timeToExe) or 10) * 60000
            local left = (self.endMS or 0) - now
            if left < -60000 or left > span + 3600000 then self.endMS = now + span; S.calFix = S.calFix + 1 end
        end)
        return S.upd0(self)
    end
end
function S.calUnwrap()
    if S.upd0 and ISFitnessAction then ISFitnessAction.update = S.upd0 end
    S.upd0 = nil
end
function S.start()
    S.err0 = S.errN()
    S.e0 = S.err0
    local HT = Z.HealthTab
    local ready = HT ~= nil and HT.startSelected ~= nil and HT.canStart ~= nil and HT.closeMenu ~= nil and HT.stepMinutes ~= nil
        and HT.selectedExercise ~= nil and HT.exerciseInfo ~= nil and HT.summaryLines ~= nil and HT.strainColor ~= nil
        and HT.figureColor ~= nil and FitnessExercises ~= nil and FitnessExercises.exercisesType ~= nil and S.fitness() ~= nil
        and HashMap ~= nil
    if not Q.check(ready, "the Health tab's exercise band, its strain tint and the game's fitness are loaded") then
        S.dead = true
        return
    end
    local f = S.found
    f.pair = RT.isOpen()
    local w = RT.cw()
    f.tab = w and w._activeTab or nil
    f.god = S.p:isGodMod()
    pcall(function() f.inv = S.p:isInvincible() end)
    f.speed = S.gameSpeed()
    f.stats = {}
    for _, k in ipairs(S.STATS) do f.stats[k] = S.stat(k) end
    f.stiff, f.wet, f.pain = {}, {}, {}
    for _, P in ipairs(S.PARTS) do
        local bp = S.part(P.bp)
        f.stiff[P.bp] = S.stiff(P.bp)
        pcall(function() f.wet[P.bp] = bp:getWetness() end)
        pcall(function() f.pain[P.bp] = bp:getAdditionalPain() end)
    end
    f.reg = {}
    for _, id in ipairs(S.EXERCISES) do f.reg[id] = S.reg(id) end
    pcall(function()
        local m = S.fitness():getRegularityMap()
        local c = HashMap.new()
        if m then c:putAll(m) end
        f.regMap = c
    end)
    f.pend, f.timer = {}, {}
    for _, r in ipairs(S.REGIONS) do f.pend[r] = S.pending(r); f.timer[r] = S.pendingTimer(r) end
    f.fitXp, f.fitLv = S.xp(Perks.Fitness), S.level(Perks.Fitness)
    f.strXp, f.strLv = S.xp(Perks.Strength), S.level(Perks.Strength)
    f.prim, f.sec = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    f.worn = S.wornContainers()
    f.sel = w and w._healthExerciseSel or nil
    f.mins = w and w._healthExerciseMinutes or nil
    local bd = S.bd()
    f.zInf = false
    pcall(function() f.zInf = bd:isInfected() end)
    f.recorded = true
    S.back.on = true
    local pend = {}
    for _, r in ipairs(S.REGIONS) do pend[#pend + 1] = r .. " " .. S.n(f.pend[r]) end
    Q.say("found: god " .. tostring(f.god) .. ", speed " .. tostring(f.speed) .. ", Fitness " .. tostring(f.fitLv) .. ", Strength "
        .. tostring(f.strLv) .. ", in hand " .. S.itemName(f.prim) .. ", bags worn " .. #f.worn .. ", pending strain " .. table.concat(pend, ", ")
        .. ", screen " .. S.screenTag())
    S.speed(1)
    S.live = true
    Events.OnTick.Add(S.safety)
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    Q.check(S.p:isGodMod() == false, "god mode is off for the run (it keeps the moodles off), the guard is on", "was " .. tostring(f.god))
    S.clearQueue()
    for _, P in ipairs(S.PARTS) do
        S.setStiff(P.bp, 0)
        local bp = S.part(P.bp)
        if bp then pcall(function() bp:setAdditionalPain(0) end) end
    end
    RT.pairOpen()
end
function S.buildStart()
    Q.step(10, S.start)
    S.until1(10, 180, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._tabStripPanel ~= nil end, function(ok)
        local w = RT.cw()
        if w then
            if S.found.hfold == nil then S.found.hfold = w._healthFigureExpanded and true or false end
            w._healthFigureExpanded = true
            S.holdWin(w)
        end
        Q.check(ok and RT.charTab("health"), "the Character window opens on the Health tab")
    end)
end

-- ===================================================================== the gear: a hammer in the hand, a bag on the back
function S.buildGear()
    Q.step(2, function()
        if S.dead then return end
        S.hammer = RT.give("Base.Hammer")
        if S.hammer then pcall(function() S.p:setPrimaryHandItem(S.hammer) end) end
        local worn = S.wornContainers()
        if #worn > 0 then
            S.gearBag = worn[1]
        else
            S.gearBag = RT.give("Base.Bag_Schoolbag")
            S.ourBag = S.gearBag
            if S.gearBag then pcall(function() ISTimedActionQueue.add(ISWearClothing:new(S.p, S.gearBag)) end) end
        end
    end)
    S.until1(3, 900, function() return S.gearBag ~= nil and S.isWorn(S.gearBag) and S.head() == nil end, function(ok)
        Q.check(ok and S.hammer ~= nil and S.p:getPrimaryHandItem() == S.hammer,
            "gear: a hammer in the hand and a bag on the back before the first exercise",
            "hand " .. S.itemName(S.p:getPrimaryHandItem()) .. ", bag " .. S.itemName(S.gearBag) .. " worn " .. tostring(S.gearBag and S.isWorn(S.gearBag))
            .. (S.ourBag and " (given)" or " (the character's own)"))
    end)
end
function S.gearCheck()
    local inHand = S.p:getPrimaryHandItem() == S.hammer
    local worn = S.gearBag ~= nil and S.isWorn(S.gearBag)
    Q.check(inHand and worn,
        "gear: after the exercise the hammer is back in the hand and the bag back on, as vanilla's fitness window does",
        "hand " .. S.itemName(S.p:getPrimaryHandItem()) .. ", bag worn " .. tostring(worn)
        .. ((inHand and worn) and "" or "; vanilla's ISFitnessUI:update (ISFitnessUI.lua:213-229) puts them back when the exercise ends; ZeD's HealthTab._startExercise (HealthTab.lua:1448-1470) takes them off and nothing puts them back"))
end

-- ===================================================================== each exercise
function S.regionsOf(id)
    local out = {}
    local exe = FitnessExercises.exercisesType[id]
    for r in string.gmatch(exe and exe.stiffness or "", "[^,]+") do out[#out + 1] = r end
    return out
end
function S.partsOf(regions)
    local out = {}
    for _, r in ipairs(regions) do for _, n in ipairs(S.REGION_PARTS[r] or {}) do out[#out + 1] = n end end
    return out
end
function S.exercise(id, first)
    local t = {}
    local lab = "exercise " .. id
    Q.step(2, function()
        if S.dead then t.off = true; return end
        local HT = Z.HealthTab
        local w = RT.cw()
        -- rested and out of pain, as a player starts a session
        S.setStat("ENDURANCE", 1)
        S.setStat("FATIGUE", 0)
        S.setStat("PAIN", 0)
        local exe = FitnessExercises.exercisesType[id]
        if exe and exe.item and not S.p:getInventory():contains(exe.item, true) then
            local it = RT.give(exe.item)
            if not it then Q.say("NOTE " .. tostring(exe.item) .. " could not be given") end
        end
        HT.closeMenu(w, id)
        HT.stepMinutes(w, -60)
        t.reg0 = S.reg(id)
        t.pend0 = {}
        for _, r in ipairs(S.REGIONS) do t.pend0[r] = S.pending(r) end
        local okS, can = pcall(HT.canStart, w)
        local okI, info = pcall(HT.exerciseInfo, S.p, id)
        if not Q.check(HT.selectedExercise(w) == id and HT.getExerciseMinutes(w) == 10 and okS and can == true,
            lab .. ": picked in the Health tab's band, 10 minutes, Start allowed",
            "picked " .. tostring(HT.selectedExercise(w)) .. ", " .. tostring(HT.getExerciseMinutes(w)) .. " min, canStart " .. tostring(can)
            .. "; the block says: " .. ((okI and info) and table.concat(info.warn or {}, "; ") or "?")) then
            t.off = true
            return
        end
        local okR, started = pcall(HT.startSelected, w)
        if not Q.check(okR and started == true, lab .. ": Start runs the game's exercise", tostring(started)) then t.off = true end
    end)
    S.until1(2, 900, function()
        if t.off then return true end
        local a = S.head()
        return a ~= nil and a.Type == "ISFitnessAction"
    end, function(ok)
        if t.off then return end
        local a = S.head()
        local cur = nil
        pcall(function() cur = S.fitness():getCurrentExe() end)
        t.on = ok and a ~= nil and a.exercise == id
        if a ~= nil then t.first = S.exeState(a) end
        S.gameCheck(t.on and cur ~= nil, lab .. ": the game's ISFitnessAction for it is at the queue's head",
            "head " .. tostring(a and a.Type) .. " " .. tostring(a and a.exercise) .. ", current exercise " .. tostring(cur ~= nil))
        if not t.on then S.clearQueue() end
    end)
    S.until1(2, 2400, function()
        if t.off or not t.on then return true end
        local a = S.head()
        if a and a.Type == "ISFitnessAction" then t.reps = math.max(t.reps or 0, a.repnb or 0); t.last = S.exeState(a) end
        return a == nil or a.Type ~= "ISFitnessAction" or (a.repnb or 0) >= 3
    end, function(ok)
        if t.off or not t.on then return end
        local a = S.head()
        local reps = t.reps or 0
        local regs = S.regionsOf(id)
        local rose, wrong = {}, {}
        for _, r in ipairs(S.REGIONS) do
            local now = S.pending(r)
            local up = now > (t.pend0[r] or 0) + 0.0001
            rose[#rose + 1] = r .. " " .. S.n(t.pend0[r]) .. " to " .. S.n(now)
            if up ~= S.inList(regs, r) then wrong[#wrong + 1] = r .. (up and " rose" or " did not rise") end
        end
        local reg1 = S.reg(id)
        if reps < 1 then Q.say("NOTE " .. lab .. ": the session at its start | " .. tostring(t.first) .. " || its last look before it ended | " .. tostring(t.last)) end
        S.gameCheck(reps >= 1, lab .. ": repetitions done", reps .. " repetitions" .. ((a and a.Type == "ISFitnessAction") and "" or " (the session had ended on its own)"))
        S.gameCheck(reg1 > t.reg0, lab .. ": its regularity rose", S.n(t.reg0) .. " to " .. S.n(reg1))
        S.gameCheck(#wrong == 0, lab .. ": the pending strain rose in exactly its regions (" .. table.concat(regs, ", ") .. ")",
            table.concat(rose, "; ") .. (#wrong > 0 and (" | " .. table.concat(wrong, ", ")) or ""))
        if a and a.Type == "ISFitnessAction" then pcall(function() a:forceStop() end) end
    end)
    S.until1(2, 900, function()
        if t.off or not t.on then return true end
        local cur = nil
        pcall(function() cur = S.fitness():getCurrentExe() end)
        -- (and out of the game's fitness state: ISFitnessAction:start skips its set-up while the last exercise's
        -- state is still on, so the next exercise would end at once with no repetition)
        local inFit = false
        pcall(function() inFit = S.p:getCurrentState() == FitnessState.instance() end)
        return not S.exercising() and cur == nil and not inFit
    end, function(ok)
        if t.off or not t.on then return end
        Q.check(ok, lab .. ": stopped, the queue free", "head " .. tostring(S.head() and S.head().Type))
        S.speed(1)
    end)
    -- (the stopped session's way out of its animation ends with the game's "FitnessFinished" event, and
    -- ISFitnessAction:animEvent stops whatever exercise is running when it lands: a session started before it
    -- lands ends at once with no repetition. Seen on every second exercise, Nov 23 2026: the next waits it out.)
    Q.waitMs(8000)
    if first then
        Q.waitMs(2500)
        Q.step(1, function()
            if S.dead then return end
            if t.on then S.gearCheck() else Q.skip("gear: the hammer and the bag after the exercise", "squats did not start") end
        end)
    end
    -- the strain 12 game hours later, where the game lays it
    local parts = S.partsOf(S.regionsOf(id))
    Q.step(1, function()
        if S.dead then return end
        local stiff = {}
        for _, n in ipairs(parts) do stiff[n] = 10 end
        S.stage({ stiff = stiff, stats = { ENDURANCE = 1, FATIGUE = 0 } })
        S.refresh()
    end)
    S.until1(3, 300, function() return S.strainReady(parts, 1) end, function(ok)
        S.strainCheck(lab .. ": its strain laid on " .. table.concat(parts, ", ") .. " (as the game will, 12 game hours later)", parts, 1, ok)
        S.unstage()
    end)
    S.errStep(lab)
end
function S.buildExercises()
    S.buildGear()
    for i, id in ipairs(S.EXERCISES) do S.exercise(id, i == 1) end
    -- the pending strain the run added: off again where there was none (put back now, so the 17-part checks are clean)
    Q.step(2, function()
        if S.dead then return end
        local f = S.found
        local left = {}
        for _, r in ipairs(S.REGIONS) do
            if (f.pend[r] or 0) <= 0 and (f.timer[r] or 0) <= 0 then
                pcall(function() S.fitness():removeStiffnessValue(r) end)
            elseif S.pending(r) ~= f.pend[r] then
                left[#left + 1] = r .. " " .. S.n(f.pend[r]) .. " to " .. S.n(S.pending(r))
            end
        end
        if #left > 0 then Q.say("NOTE pending strain the character had before the run cannot be set back to its amount (no setter): " .. table.concat(left, "; ")) end
        local still = {}
        for _, r in ipairs(S.REGIONS) do
            if (f.pend[r] or 0) <= 0 and S.pending(r) > 0 then still[#still + 1] = r end
        end
        Q.check(#still == 0, "exercises: the pending strain they added is taken off again", #still == 0 and "none left" or table.concat(still, ", "))
    end)
end

-- ===================================================================== strain on every part
function S.buildStrain()
    for _, level in ipairs({ 1, 2 }) do
        local v = (level == 1) and 10 or 40
        for _, P in ipairs(S.PARTS) do
            local n = P.bp
            Q.step(1, function()
                if S.dead then return end
                S.stage({ stiff = { [n] = v }, stats = { ENDURANCE = 1, FATIGUE = 0 } })
                S.refresh()
            end)
            S.until1(3, 300, function() return S.strainReady({ n }, level) end, function(ok)
                S.strainCheck("strain " .. v .. " on " .. n, { n }, level, ok)
                S.unstage()
            end)
        end
        S.errStep("strain " .. v)
    end
    -- heavy on every part at once
    local all = {}
    for _, P in ipairs(S.PARTS) do all[#all + 1] = P.bp end
    Q.step(1, function()
        if S.dead then return end
        local stiff = {}
        for _, n in ipairs(all) do stiff[n] = 40 end
        S.stage({ stiff = stiff, stats = { ENDURANCE = 1, FATIGUE = 0 } })
        S.refresh()
    end)
    S.until1(3, 300, function() return S.strainReady(all, 2) end, function(ok)
        S.strainCheck("strain 40 on all 17", all, 2, ok)
        local w = RT.cw()
        local F = Z.TabFill
        if F and F.folded and F.folded(w, "health", "strain") then
            Q.skip("strain 40 on all 17: the Muscle Strain block's rows drawn", "the player folded the block")
        else
            local drawn = 0
            local b = w and w._fill and w._fill.health
            for _, list in ipairs({ b and b.last or {}, b and b.zones or {} }) do
                for _, z in ipairs(list) do if S.has(tostring(z.id), "fill:health:strain:") then drawn = drawn + 1 end end
            end
            Q.check(drawn > 0, "strain 40 on all 17: the Muscle Strain block's rows are drawn", drawn .. " row zones")
        end
        RT.bounds(Q, "strain on all 17, Health tab")
    end)
    S.shot("hg_fit_strain17_" .. S.screenTag(), "the Health tab with heavy muscle strain on every part")
    Q.step(1, function() if not S.dead then S.unstage() end end)
    S.errStep("strain on all 17")
end

-- ===================================================================== fatigue and the other rules for Start
function S.moodleCase(lab, key, W, wantLevel)
    Q.step(1, function()
        if S.dead then return end
        local w = RT.cw()
        Z.HealthTab.closeMenu(w, "squats")
        S.stage(W)
        S.reread = nil
        S.refresh()
    end)
    S.until1(3, 600, function()
        -- (the block is read again once the game's moodle has come on: the fill rebuilt before it would be stale)
        if S.moodle(key) < wantLevel then return false end
        if not S.reread then S.reread = true; S.refresh(); return false end
        return S.fresh()
    end, function(ok)
        local lvl = S.moodle(key)
        if not ok and lvl < 1 then
            Q.skip(lab, "the game's " .. key .. " moodle did not come on (level " .. lvl .. ")")
            S.unstage()
            return
        end
        local names = {}
        for _, m in ipairs(S.fill() and S.fill().moodles or {}) do names[#names + 1] = tostring(m.name) end
        local nm = S.moodleName(key)
        Q.check(nm ~= nil and S.inList(names, nm), lab .. ": the Moodles block names the game's " .. key .. " moodle (level " .. lvl .. ")",
            tostring(nm) .. " in [" .. table.concat(names, ", ") .. "]")
        S.startCheck(lab)
        S.unstage()
    end)
end
function S.buildFatigue()
    local endu = { 0.74, 0.49, 0.24, 0.09 }
    for i, v in ipairs(endu) do
        S.moodleCase("endurance " .. v, "ENDURANCE", { stats = { ENDURANCE = v, FATIGUE = 0 } }, i)
    end
    local tired = { 0.61, 0.71, 0.81, 0.91 }
    for i, v in ipairs(tired) do
        S.moodleCase("fatigue " .. v, "TIRED", { stats = { ENDURANCE = 1, FATIGUE = v } }, i)
    end
    Q.step(1, function() if not S.dead then S.setStat("ENDURANCE", 1); S.setStat("FATIGUE", 0) end end)
    -- heavy pain on every part: the Pain moodle over 3
    local pain = {}
    for _, P in ipairs(S.PARTS) do pain[P.bp] = 100 end
    S.moodleCase("heavy pain on every part", "PAIN", { pain = pain, stats = { ENDURANCE = 1, FATIGUE = 0 } }, 4)
    Q.step(1, function() if not S.dead then S.setStat("PAIN", 0) end end)
    Q.waitMs(1500)
    -- a heavy load: barbells until the Heavy Load moodle is over 2
    Q.step(1, function()
        if S.dead then return end
        S.load = {}
        for _ = 1, 10 do
            local it = nil
            pcall(function() it = S.p:getInventory():AddItem("Base.BarBell") end)
            if it then S.load[#S.load + 1] = it end
        end
        S.stage({ stats = { ENDURANCE = 1, FATIGUE = 0 } })
    end)
    S.until1(3, 600, function() return S.moodle("HEAVY_LOAD") > 2 end, function(ok)
        if not ok then
            Q.skip("a heavy load", "ten barbells did not bring the Heavy Load moodle over 2 (level " .. S.moodle("HEAVY_LOAD") .. ")")
        else
            S.startCheck("a heavy load (" .. #S.load .. " barbells)")
        end
        for _, it in ipairs(S.load or {}) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
        S.load = {}
        S.unstage()
    end)
    S.until1(3, 600, function() return S.moodle("HEAVY_LOAD") <= 2 end, function(ok)
        Q.check(ok, "the load taken back, Heavy Load is off", "level " .. S.moodle("HEAVY_LOAD"))
    end)
    S.errStep("fatigue")
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.unstage()
    S.park(false)
    S.unholdAll()
    local f = S.found
    if S.exercising() then pcall(function() S.head():forceStop() end) end
    S.clearQueue()
    for _, it in ipairs(S.load or {}) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.load = {}
    for _, P in ipairs(S.PARTS) do
        S.setStiff(P.bp, f.stiff[P.bp])
        local bp = S.part(P.bp)
        if bp then
            if f.wet[P.bp] then pcall(function() bp:setWetness(f.wet[P.bp]) end) end
            if f.pain[P.bp] then pcall(function() bp:setAdditionalPain(f.pain[P.bp]) end) end
        end
    end
    for _, r in ipairs(S.REGIONS) do
        if (f.pend[r] or 0) <= 0 and (f.timer[r] or 0) <= 0 then pcall(function() S.fitness():removeStiffnessValue(r) end) end
    end
    if f.regMap then pcall(function() S.fitness():setRegularityMap(f.regMap) end) end
    S.putXp(Perks.Fitness, f.fitXp, f.fitLv)
    S.putXp(Perks.Strength, f.strXp, f.strLv)
    for k, v in pairs(f.stats or {}) do S.setStat(k, v) end
    -- the hands and the bags as found (a bag the run gave comes off first)
    if S.ourBag then pcall(function() S.p:removeWornItem(S.ourBag) end) end
    pcall(function() S.p:setPrimaryHandItem(f.prim) end)
    pcall(function() S.p:setSecondaryHandItem(f.sec) end)
    S.rewear = {}
    for _, it in ipairs(f.worn or {}) do
        if not S.isWorn(it) then
            S.rewear[#S.rewear + 1] = it
            pcall(function() ISTimedActionQueue.add(ISWearClothing:new(S.p, it)) end)
        end
    end
    local w = RT.cw()
    if w then
        if f.hfold ~= nil then w._healthFigureExpanded = f.hfold end
        w._healthExerciseSel = f.sel
        w._healthExerciseMinutes = f.mins
        pcall(Z.HealthTab.closeMenu, w)
        w._healthReturnToMenu = nil
    end
    if S.bailed then pcall(function() S.p:setGodMod(true) end)
    else pcall(function() S.p:setGodMod(f.god and true or false) end) end
    if f.inv ~= nil then pcall(function() S.p:setInvincible(f.inv) end) end
    S.speed(f.speed)
    S.live = false
    pcall(function() Events.OnTick.Remove(S.safety) end)
end
function S.buildPutBack()
    Q.mark()
    Q.step(5, function()
        S.calUnwrap()
        Q.say("NOTE the game's calendar reads year " .. tostring(S.calOdd() or "normal") .. " in this world")
        if not S.back.on then return end
        S.putBack()
        if S.found.pair then RT.pairOpen() else RT.pairShut() end
    end)
    Q.waitFor(5, 900, function()
        local done = true
        for _, it in ipairs(S.rewear or {}) do if not S.isWorn(it) then done = false end end
        return done and S.head() == nil and RT.isOpen() == (S.found.pair == true)
    end, function(ok)
        if S.found.pair and S.found.tab and S.found.tab ~= "health" then RT.charTab(S.found.tab) end
        Q.check(ok, "put back: the bags worn as found and the window pair " .. (S.found.pair and "open" or "shut") .. " as found",
            #(S.rewear or {}) .. " bag(s) put back on")
    end)
    Q.step(20, function()
        local f = S.found
        local p = S.p
        if not f.recorded then
            Q.skip("put back", "nothing was staged (the modules were not loaded)")
            return
        end
        local w = RT.cw()
        if f.pair and f.tab then Q.check(w ~= nil and w._activeTab == f.tab, "put back: the Character window's tab", tostring(w and w._activeTab)) end
        local bad = {}
        for _, P in ipairs(S.PARTS) do
            local s = S.stiff(P.bp)
            if not S.near(s, f.stiff[P.bp], 0.01) then bad[#bad + 1] = P.bp .. " " .. S.n(s) .. " (was " .. S.n(f.stiff[P.bp]) .. ")" end
        end
        Q.check(#bad == 0, "put back: every part's stiffness as found", #bad == 0 and "17 parts" or table.concat(bad, "; "))
        local rb = {}
        for _, id in ipairs(S.EXERCISES) do
            if not S.near(S.reg(id), f.reg[id], 0.01) then rb[#rb + 1] = id .. " " .. S.n(S.reg(id)) .. " (was " .. S.n(f.reg[id]) .. ")" end
        end
        local pb = {}
        for _, r in ipairs(S.REGIONS) do
            if (f.pend[r] or 0) <= 0 and S.pending(r) > 0 then pb[#pb + 1] = r .. " " .. S.n(S.pending(r)) end
        end
        Q.check(#rb == 0 and #pb == 0, "put back: the regularity of every exercise and the pending strain as found",
            (#rb + #pb == 0) and "as found" or (table.concat(rb, "; ") .. " | " .. table.concat(pb, "; ")))
        local fx, sx = S.xp(Perks.Fitness), S.xp(Perks.Strength)
        Q.check(S.level(Perks.Fitness) == f.fitLv and S.level(Perks.Strength) == f.strLv and fx ~= nil and sx ~= nil and f.fitXp ~= nil
            and f.strXp ~= nil and math.abs(fx - f.fitXp) < 1 and math.abs(sx - f.strXp) < 1,
            "put back: Fitness and Strength, their levels and XP as found",
            "Fitness " .. tostring(S.level(Perks.Fitness)) .. " xp " .. S.n(fx) .. " (was " .. S.n(f.fitXp) .. "), Strength "
            .. tostring(S.level(Perks.Strength)) .. " xp " .. S.n(sx) .. " (was " .. S.n(f.strXp) .. ")")
        local sb = {}
        for _, k in ipairs(S.CHECK_STATS) do
            local v, now = f.stats[k], S.stat(k)
            if v ~= nil and not S.near(now, v, 0.03) then sb[#sb + 1] = k .. " " .. S.n(now) .. " (was " .. S.n(v) .. ")" end
        end
        Q.check(#sb == 0, "put back: the stats as found (endurance, fatigue, hunger, thirst, stress, boredom, unhappiness, panic)",
            #sb == 0 and "as found" or table.concat(sb, "; "))
        Q.check(p:getPrimaryHandItem() == f.prim and p:getSecondaryHandItem() == f.sec and #S.held == 0 and S.parked == nil,
            "put back: the hands as found, no window held, the pointer the game's",
            "hand " .. S.itemName(p:getPrimaryHandItem()) .. " (was " .. S.itemName(f.prim) .. ")")
        if S.bailed then
            Q.check(p:isGodMod() == true, "put back: the run stopped early, so god mode is left ON", tostring(p:isGodMod()))
        else
            Q.check(p:isGodMod() == (f.god and true or false), "put back: god mode as found", tostring(f.god))
        end
        Q.check(not p:isDead(), "put back: the character is alive", "health top-ups " .. tostring(S.topUps or 0))
        local e1 = S.errN()
        if S.err0 and e1 then
            Q.check(e1 == S.err0, "the fitness run ran with no Lua error", (e1 - S.err0) .. " new")
        else
            Q.skip("the fitness run's Lua error count", "the game's Lua error count cannot be read here")
        end
    end)
end

S.buildStart()
S.buildExercises()
S.buildStrain()
S.buildFatigue()
S.buildPutBack()
Q.start()
