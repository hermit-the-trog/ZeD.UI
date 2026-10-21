-- ZeDUI/tools/qa/zedqa_exinfo.lua  (Oct 20 2026)
-- In game on the ZeD-QA save: the Health tab's exercise info (vanilla's fitness
-- window text brought back): description, stiffness lines, Regularity bar,
-- "(Requires X)" and the reason OK would be greyed.
--   data: exerciseInfo for every exercise against vanilla's keys; chest has no
--   stiffness line; a missing barbell warns, a barbell added clears it; a stand-up
--   reason shows while sitonground is set and is put back;
--   screen: the info block follows the pad's focused pill and keeps one
--   reserved height whichever exercise it shows.
-- Screenshots zqa_ex_*.png. grep "ZEDQA ex".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local H = ZeD.HealthTab
local function say(s) print("ZEDQA ex " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ex_" .. n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function ok(label, cond) say((cond and "ok   " or "FAIL ") .. label) end
local inv = p:getInventory()
local bar
local sitWas = p:getVariableBoolean("sitonground")
local function has(list, text)
    for _, s in ipairs(list) do if s == text then return true end end
    return false
end
local function focusExercise(id)
    local w = cw()
    for zi, z in ipairs(w._focusRing or {}) do
        for ei, el in ipairs(z.elements or {}) do
            if el.exerciseId == id then
                w._focusIdx = zi; z.focusedElementIdx = ei
                if el.onFocus then el.onFocus(w, el) end
                return true
            end
        end
    end
end
at(2, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
at(20, function()
    Focus.claimFocus(cw()); tab("health")
    cw()._healthFigureExpanded = true
end)
at(50, function()
    local E = FitnessExercises.exercisesType
    local sq = H.exerciseInfo(p, "squats")
    ok("squats desc is vanilla's tooltip", sq and sq.desc == E.squats.tooltip and sq.desc ~= "")
    ok("squats legs line", sq and #sq.stiff == 1 and sq.stiff[1] == getText("IGUI_Fitness_LegsStiffness"))
    local pu = H.exerciseInfo(p, "pushups")
    ok("pushups: arms line only (chest has none)", pu and #pu.stiff == 1 and pu.stiff[1] == getText("IGUI_Fitness_ArmsStiffness"))
    local bu = H.exerciseInfo(p, "burpees")
    ok("burpees: legs and arms", bu and #bu.stiff == 2 and bu.stiff[1] == getText("IGUI_Fitness_LegsStiffness") and bu.stiff[2] == getText("IGUI_Fitness_ArmsStiffness"))
    local su = H.exerciseInfo(p, "situp")
    ok("situp abs line", su and #su.stiff == 1 and su.stiff[1] == getText("IGUI_Fitness_AbsStiffness"))
    ok("regularity in 0..1", sq and type(sq.regularity) == "number" and sq.regularity >= 0 and sq.regularity <= 1)
    say("regularity squats " .. tostring(sq and sq.regularity))
    local bc = H.exerciseInfo(p, "barbellcurl")
    local need = getText("IGUI_FitnessNeedItem", getItemDisplayName("Base.BarBell"))
    local hadBar = inv:contains("Base.BarBell", true)   -- a barbell the save already holds stays
    if hadBar then
        ok("barbell curl with a barbell in the bag has no warning", bc and not has(bc.warn, need))
    else
        ok("barbell curl without a barbell warns '" .. need .. "'", bc and has(bc.warn, need))
        bar = inv:AddItem("Base.BarBell")
    end
    ok("squats has no item warning", sq and not has(sq.warn, need))
    bc = H.exerciseInfo(p, "barbellcurl")
    ok("with a barbell the warning clears", bc and not has(bc.warn, need))
    ok("unknown exercise gives nil", H.exerciseInfo(p, "nope") == nil)
    p:setVariable("sitonground", true)
    sq = H.exerciseInfo(p, "squats")
    ok("sitonground shows Stand up before exercising", sq and has(sq.warn, getText("Tooltip_StandStillFitness")))
    p:setVariable("sitonground", sitWas)
    sq = H.exerciseInfo(p, "squats")
    ok("reason gone after standing", sq and not has(sq.warn, getText("Tooltip_StandStillFitness")))
end)
-- on screen
at(60, function() focusExercise("squats") end)
local hSquats
local selWas = nil
at(90, function()
    local w = cw()
    say("tab health " .. tostring(w._activeTab == "health") .. " | shown " .. tostring(w._healthInfoShown) .. " | reserved " .. tostring(w._healthInfoH) .. " used " .. tostring(w._healthInfoUsedH) .. " w " .. tostring(w._healthInfoW))
    ok("block follows the focused pill (squats)", w._healthInfoShown == "squats")
    ok("room reserved", (w._healthInfoH or 0) > 0 and (w._healthInfoUsedH or 0) <= w._healthInfoH)
    hSquats = w._healthInfoH
    shot("squats")
    focusExercise("barbellcurl")
end)
at(120, function()
    local w = cw()
    ok("block follows the focused pill (barbell curl)", w._healthInfoShown == "barbellcurl")
    ok("same reserved height for another exercise", w._healthInfoH == hSquats)
    shot("barbellcurl")
    -- (the feature: pad-focused pill, else hovered, else the last exercise STARTED, else squats;
    -- merely focusing a pill is not starting it, so stand in for a started one)
    selWas = cw()._healthExerciseSel
    cw()._healthExerciseSel = "situp"
    focusExercise("time:inc")
end)
at(150, function()
    local w = cw()
    ok("time buttons keep the last started exercise", w._healthInfoShown == "situp")
    ok("time buttons start nothing and change no choice", w._healthExerciseSel == "situp")
    focusExercise("burpees")
end)
at(180, function()
    local w = cw()
    ok("block follows the focused pill (burpees)", w._healthInfoShown == "burpees")
    shot("burpees")
end)
at(190, function()
    if bar then inv:Remove(bar) end
    pcall(function() cw()._healthExerciseSel = selWas end)
    p:setVariable("sitonground", sitWas)
    tab("loot")
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    Focus.releaseFocus()
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok2, e = pcall(s.fn); if not ok2 then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 195 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
