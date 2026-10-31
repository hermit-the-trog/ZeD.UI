-- ZeDUI/tools/qa/zedqa_exinfo.lua  (Oct 20 2026)
-- In game on the ZeD-QA save: the Health tab's exercise info (vanilla's fitness
-- window text brought back): description, stiffness lines, Regularity bar,
-- "(Requires X)" and the reason OK would be greyed.
--   data: exerciseInfo for every exercise against vanilla's keys; chest has no
--   stiffness line; a missing barbell warns, a barbell added clears it; a stand-up
--   reason shows while sitonground is set and is put back;
--   screen: the info block follows the exercise picked in the footer band's pop-up
--   (Oct 30 2026: the seven buttons became that pop-up) and keeps one reserved height
--   whichever exercise it shows; the pop-up lists all seven, a pick shuts it and
--   changes the choice; the band's keys step the time and start nothing.
--   (Oct 30 2026, punch list 21 a-f) the list opens on the chosen row, outlives a 4K
--   screenshot, Up / Down stop at its ends (it stays open), Left / Right do nothing, B shuts
--   it unchanged with the focus back on the box.
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
-- pick an exercise as the pop-up's list does (the choice the info follows)
local function pickExercise(id)
    cw()._healthExerciseSel = id
end
-- the pad stop with this id (the footer band's box, - / +, Start; a list row)
local function stopById(id)
    local w = cw()
    for zi, z in ipairs(w._focusRing or {}) do
        for ei, el in ipairs(z.elements or {}) do
            if el.id == id then return w, z, zi, ei, el end
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
local selWas = nil
at(60, function() selWas = cw()._healthExerciseSel; pickExercise("squats") end)
local hSquats
at(90, function()
    local w = cw()
    say("tab health " .. tostring(w._activeTab == "health") .. " | shown " .. tostring(w._healthInfoShown) .. " | reserved " .. tostring(w._healthInfoH) .. " used " .. tostring(w._healthInfoUsedH) .. " w " .. tostring(w._healthInfoW))
    ok("block describes the picked exercise (squats)", w._healthInfoShown == "squats")
    ok("room reserved", (w._healthInfoH or 0) > 0 and (w._healthInfoUsedH or 0) <= w._healthInfoH)
    hSquats = w._healthInfoH
    shot("squats")
    pickExercise("barbellcurl")
end)
at(120, function()
    local w = cw()
    ok("block follows the pick (barbell curl)", w._healthInfoShown == "barbellcurl")
    ok("same reserved height for another exercise", w._healthInfoH == hSquats)
    shot("barbellcurl")
    -- the band's stops: the box, - and +, Start last
    ok("band stops: exercise box", stopById("health:exercise") ~= nil)
    ok("band stops: - and +", stopById("health:time:dec") ~= nil and stopById("health:time:inc") ~= nil)
    ok("band stops: Start", stopById("health:start") ~= nil)
    ok("no exercise-button stops left", stopById("exercise:squats") == nil and stopById("exercise:time:inc") == nil)
    -- the pop-up: A on the box opens it, the stops become the seven rows
    local _, z, zi, ei, el = stopById("health:exercise")
    -- (on the box first, as the pad is when A opens it)
    Focus.focusWhere(w, "charTabContent", function(e) return e.id == "health:exercise" end)
    if el then el.onActivate(w, el) end
end)
at(135, function()
    local w = cw()
    ok("pop-up open", w._healthMenuOpen == true)
    ok("pop-up lists the seven exercises", w._healthMenuZones ~= nil and #w._healthMenuZones == 7)
    local _, z, zi, ei, row = stopById("health:menuRow:burpees")
    ok("rows are the stops while open", row ~= nil and stopById("health:start") == nil)
    -- (Oct 30 2026, punch list 21 a-f) the list opens on the exercise chosen now
    local fe = Focus.getFocusedElement(w)
    ok("the list opens on the chosen row (barbell curl; on " .. tostring(fe and fe.id) .. ")", fe ~= nil and fe.id == "health:menuRow:barbellcurl")
    shot("menu")   -- (a 4K shot is a hitch of more than 300 ms: the list must outlive it)
end)
-- the list's ends: the rows top to bottom (by place), the focused one
local function rowsByY()
    local w = cw()
    local z = Focus.getFocusedZone(w)
    local list = {}
    for _, e in ipairs(z and z.elements or {}) do list[#list + 1] = e end
    table.sort(list, function(a, b) return a.y < b.y end)
    return list, z
end
local function focusedId() local e = Focus.getFocusedElement(cw()); return e and e.id or "nil" end
at(140, function()
    local w = cw()
    ok("the list outlives the screenshot", w._healthMenuOpen == true and stopById("health:menuRow:burpees") ~= nil)
    local list, z = rowsByY()
    ok("the open list is modal (its rows alone, marked)", z ~= nil and z.elements._menuRows == true and #list == 7)
    for _ = 1, 9 do Focus.dispatchJoypadDir(w, "up") end
    ok("Up stops on the first row (" .. focusedId() .. ")", list[1] ~= nil and focusedId() == list[1].id and w._healthMenuOpen == true)
    for _ = 1, 9 do Focus.dispatchJoypadDir(w, "down") end
    ok("Down stops on the last row, the list still open (" .. focusedId() .. ")", list[7] ~= nil and focusedId() == list[7].id and w._healthMenuOpen == true)
    local before = focusedId()
    Focus.dispatchJoypadDir(w, "left"); Focus.dispatchJoypadDir(w, "right")
    ok("Left and Right do nothing in the list", focusedId() == before and w._healthMenuOpen == true)
    local r = Focus.previewMove(w, "down")
    ok("nothing below the last row (the preview stays in the list)", r and r.zone == nil)
    -- B: the row's onCancel (what B fires): shut, the choice unchanged
    local fe = Focus.getFocusedElement(w)
    if fe and fe.onCancel then fe.onCancel(w, fe) end
end)
at(146, function()
    local w = cw()
    local _, z, zi, ei, el = stopById("health:exercise")
    ok("B shuts the list, the choice unchanged", w._healthMenuOpen == false and w._healthExerciseSel == "barbellcurl")
    ok("B: the focus is back on the box (" .. focusedId() .. ")", el ~= nil and focusedId() == "health:exercise")
    if el then el.onActivate(w, el) end   -- open it again for the pick
end)
at(150, function()
    local w = cw()
    local _, z, zi, ei, row = stopById("health:menuRow:burpees")
    ok("open again", w._healthMenuOpen == true and row ~= nil)
    if row then row.onActivate(w, row) end   -- a pick shuts the list
end)
at(165, function()
    local w = cw()
    ok("pick shut the list and changed the choice", w._healthMenuOpen == false and w._healthExerciseSel == "burpees")
    local _, z, zi, ei, el = stopById("health:exercise")
    ok("focus is back on the box", el ~= nil and z ~= nil and z.elements[z.focusedElementIdx or 1] == el)
    ok("block follows the pick (burpees)", w._healthInfoShown == "burpees")
    -- the time keys step it and start nothing, change no choice
    local mins = H.getExerciseMinutes(w)
    local _, _, _, _, inc = stopById("health:time:inc")
    if inc then inc.onActivate(w, inc) end
    ok("+ steps the time by 10", H.getExerciseMinutes(w) == math.min(60, mins + 10))
    local _, _, _, _, dec = stopById("health:time:dec")
    if dec then dec.onActivate(w, dec) end
    ok("- steps it back", H.getExerciseMinutes(w) == mins)
    ok("time keys change no choice", w._healthExerciseSel == "burpees")
    pickExercise("situp")
end)
at(180, function()
    local w = cw()
    ok("block follows the pick (situp)", w._healthInfoShown == "situp")
    shot("situp")
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
