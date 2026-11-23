-- ZeDUI/tools/qa/hg_fit_ctl_tab.lua  (Nov 23 2026, QA; tag hg_ctt): hg_fit_ctl with the Character window open on its
-- Health tab the whole time (hg_fit runs with it open and sees far more sessions end at once). From hg_fit_ctl: a control for hg_fit. Some exercises started from
-- the Health tab end at once with no repetition (hg_fit runs 2 to 5, a different exercise each time). This runs each
-- of the 7 exercises twice by ZeD's start (ZeD.HealthTab._startExercise) and twice by the game's own fitness window
-- start (ISFitnessUI:equipItems on a stand-in window, then ISFitnessAction:new + ISTimedActionQueue.addGetUpAndThen,
-- as ISFitnessUI:onClick does), in turn, with the same waits, and counts the sessions that end with no repetition on
-- each side. Each session logs its state at its start (the game's fitness state, the end time left, the endurance
-- moodle). The session is stopped after 2 repetitions, then 8 s of real time pass before the next.
-- Check: ZeD's start ends at once no more often than the game's own start does.
-- Puts back: nothing in game (the chain puts the save back from its start copy after this run); the queue is
-- cleared and the game speed set to 1 at the end; the items given are taken back.
local Q = RT.make("hg_ctt")
local S = { p = getPlayer(), runs = {}, zero = { zed = 0, game = 0 }, n = { zed = 0, game = 0 } }
S.IDS = { "squats", "pushups", "situp", "burpees", "barbellcurl", "dumbbellpress", "bicepscurl" }

function S.head()
    local a = nil
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        a = q and q.queue and q.queue[1] or nil
    end)
    return a
end
function S.fit() local a = S.head(); if a and a.Type == "ISFitnessAction" then return a end; return nil end
function S.look(a)
    local o = {}
    local function add(k, f) local ok, v = pcall(f); o[#o + 1] = k .. " " .. (ok and tostring(v) or "?") end
    add("state", function() return S.p:getCurrentState() == FitnessState.instance() and "fitness" or tostring(S.p:getCurrentState()) end)
    add("ms left", function() return a.endMS - getGameTime():getCalender():getTimeInMillis() end)
    add("endurance moodle", function() return S.p:getMoodles():getMoodleLevel(MoodleType.ENDURANCE) end)
    add("ExerciseType", function() return S.p:getVariableString("ExerciseType") end)
    return table.concat(o, ", ")
end
function S.rest()
    pcall(function() S.p:getStats():set(CharacterStat.ENDURANCE, 1) end)
    pcall(function() S.p:getStats():set(CharacterStat.FATIGUE, 0) end)
end
function S.startZed(id)
    ZeD.HealthTab._startExercise(S.p, id, 10)
end
function S.startGame(id)
    local exe = FitnessExercises.exercisesType[id]
    local ui = { player = S.p, exeData = exe, itemsToReequip = {} }
    if not ISFitnessUI.equipItems(ui) then return end
    local action = ISFitnessAction:new(S.p, id, 10, exe, exe.type)
    ISTimedActionQueue.addGetUpAndThen(S.p, action)
end

function S.run(id, side)
    local r = { id = id, side = side, reps = 0 }
    Q.step(1, function()
        S.rest()
        local exe = FitnessExercises.exercisesType[id]
        if exe and exe.item and not S.p:getInventory():contains(exe.item, true) then RT.give(exe.item) end
        local ok, err = pcall(side == "zed" and S.startZed or S.startGame, id)
        if not ok then Q.say("NOTE " .. id .. " by " .. side .. ": the start threw " .. tostring(err)) end
    end)
    Q.waitFor(2, 1200, function() return S.fit() ~= nil end, function(ok)
        local a = S.fit()
        r.on = ok and a ~= nil
        r.first = a and S.look(a) or "no session"
    end)
    Q.waitFor(2, 2400, function()
        if not r.on then return true end
        local a = S.fit()
        if a then r.reps = math.max(r.reps, a.repnb or 0); r.last = S.look(a) end
        return a == nil or (a.repnb or 0) >= 2
    end, function()
        if not r.on then
            Q.say("NOTE " .. id .. " by " .. side .. ": no session came to the queue's head")
            return
        end
        S.n[side] = S.n[side] + 1
        if r.reps < 1 then S.zero[side] = S.zero[side] + 1 end
        Q.say("NOTE " .. id .. " by " .. side .. ": " .. r.reps .. " repetitions | at its start: " .. tostring(r.first)
            .. " | last look: " .. tostring(r.last))
        local a = S.fit()
        if a then pcall(function() a:forceStop() end) end
    end)
    Q.waitFor(2, 900, function() return S.fit() == nil end, function() end)
    Q.waitMs(8000)
end

Q.step(1, function() RT.charTab("health") end)
Q.waitMs(1500)
Q.step(1, function()
    pcall(function() setGameSpeed(1) end)
    Q.say("NOTE the calendar now: " .. tostring(getGameTime():getCalender():getTime()))
end)
for round = 1, 2 do
    for _, id in ipairs(S.IDS) do
        if round == 1 then S.run(id, "zed"); S.run(id, "game") else S.run(id, "game"); S.run(id, "zed") end
    end
end
Q.mark()
Q.step(1, function()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    Q.say("NOTE the Health tab open at the end: " .. tostring(RT.cw() ~= nil and RT.cw():isVisible()))
    pcall(function() setGameSpeed(1) end)
    Q.say("NOTE sessions with no repetition: ZeD's start " .. S.zero.zed .. " of " .. S.n.zed .. ", the game's start "
        .. S.zero.game .. " of " .. S.n.game)
    Q.check(S.n.zed > 0 and S.n.game > 0 and S.zero.zed <= S.zero.game,
        "ZeD's exercise start ends at once no more often than the game's own start",
        "ZeD " .. S.zero.zed .. " of " .. S.n.zed .. ", the game " .. S.zero.game .. " of " .. S.n.game)
end)
Q.start()
