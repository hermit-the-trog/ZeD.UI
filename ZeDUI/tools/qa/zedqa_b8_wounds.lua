-- ZeDUI/tools/qa/zedqa_b8_wounds.lua  (Nov 7 2026, QA; tag b8wo): Wounds Overhaul (3775026731) support in ZeD's Health tab.
-- CHECK_wounds_overhaul_20261107.md, sections 1 to 4 (the sandbox settings of section 5 are by hand). Run after
-- zedqa_prelude.lua; the prelude's god mode HEALS a wound at once, so this script turns god mode OFF and invincible ON for the
-- length of the run and puts both back (and heals the body) at the end.
--   1. the tab before the look: a cut on the left forearm and a scratch on the right hand are held back (WO's own rule,
--      Wounds.body.needsExamFirst): their rows read "Something is wrong here." and name no cut, bleeding or scratch; a deep
--      wound on the neck is named (the mod never holds the neck back). Picture.
--   2. the part menu of the forearm (ZeD's own click on the figure): Examine and the mod's gray line, no treatment. Picture.
--      Examine run from that menu entry: the examination is queued, a second Examine while it runs adds nothing; the script
--      waits for it (First Aid 0: about 12 s) and the part is no longer held back.
--   3. after the look: the rows name the cut and the bleeding, "Something is wrong here." is gone; the menu is the game's
--      treatments with the mod's lines, no Examine; a bandage from the menu goes on; a deep wound with a needle and thread
--      offers Stitch, and picking it opens the mod's suture window (counted through the window's constructor), which the
--      script closes; the head with a fracture, examined, offers no menu at all (the mod's rule). Pictures.
--   4. healed, then cut again: the old look went with the old wound (held back again, Examine in the menu).
--   5. PUT BACK: god mode and invincible as they were, the whole body healed, the queue cleared, the context menu shut.
-- The sandbox settings are the mod's defaults; with another examination mode the held-back checks are SKIPPED, not failed.
-- grep "ZEDQA b8wo"; shots zqa_b8wo_*.png.
local function say(s) print("ZEDQA b8wo " .. tostring(s)) end
local p = getPlayer()
local fails = 0
local function check(ok, what)
    if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8wo_" .. n .. ".png") end) end
local CW, HT = ZeD_CharacterWindow, ZeD.HealthTab
if not (p and CW and HT and HT.gatherData) then say("ERR ZeD's Health tab is not loaded"); say("DONE"); return end
if type(Wounds) ~= "table" or type(Wounds.body) ~= "table" then
    say("SKIP Wounds Overhaul is not loaded (this script is for the WO run)")
    say("DONE")
    return
end

local Q, qi, waitT, tries = {}, 1, nil, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function untilDo(n, max, fn, what) Q[#Q + 1] = { n = n, fn = fn, tries = max, what = what } end

local bd = p:getBodyDamage()
local fa = bd:getBodyPart(BodyPartType.ForeArm_L)
local hand = bd:getBodyPart(BodyPartType.Hand_R)
local neck = bd:getBodyPart(BodyPartType.Neck)
local head = bd:getBodyPart(BodyPartType.Head)
local godWas, invWas = p:isGodMod(), nil
pcall(function() invWas = p:isInvincible() end)
local strict = false
local unexamined = getText("IGUI_Wounds_Unexamined")

local function keepDown()
    local w = CW.getWindow()
    if w then w._autoShaded = false; if w.windowShaded then w:setWindowShaded(false) end; w._outSince = getTimestampMs() + 600000 end
end
local function held(part)
    local ok, yes = pcall(Wounds.body.needsExamFirst, part)
    return ok and yes == true
end
local function entryFor(data, part)
    for _, e in ipairs(data.entries or {}) do
        if e.bodyPart == part then return e end
    end
    return nil
end
local function labels(e)
    local t = {}
    for _, c in ipairs(e and e.conditions or {}) do t[#t + 1] = tostring(c.label) end
    return t
end
local function has(list, text)
    for _, l in ipairs(list) do if l == text then return true end end
    return false
end
local function hasSub(list, sub)
    for _, l in ipairs(list) do if tostring(l):lower():find(sub:lower(), 1, true) then return true end end
    return false
end
local function menuNames()
    local m = getPlayerContextMenu(0)
    local t = {}
    for _, o in ipairs(m and m.options or {}) do t[#t + 1] = tostring(o.name) end
    return t, m
end
local function hasName(names, sub)
    for _, n in ipairs(names) do if n:lower():find(sub:lower(), 1, true) then return n end end
    return nil
end
local function pick(sub)
    local m = getPlayerContextMenu(0)
    for _, o in ipairs(m and m.options or {}) do
        if tostring(o.name):lower():find(sub:lower(), 1, true) then
            if o.onSelect then
                return pcall(o.onSelect, o.target, o.param1, o.param2, o.param3, o.param4, o.param5, o.param6, o.param7, o.param8, o.param9, o.param10)
            end
            -- (Nov 8 QA) the game's Bandage entry opens a sub menu (the bandage to use): take its first live entry
            if o.subOption then
                local sm = nil
                pcall(function() sm = m:getSubMenu(o.subOption) end)
                for _, so in ipairs(sm and sm.options or {}) do
                    if so.onSelect and not so.notAvailable then
                        return pcall(so.onSelect, so.target, so.param1, so.param2, so.param3, so.param4, so.param5, so.param6, so.param7, so.param8, so.param9, so.param10)
                    end
                end
                return false, "the sub menu has no live entry"
            end
        end
    end
    return false, "no such entry"
end
local function hideMenu()
    local m = getPlayerContextMenu(0)
    if m then pcall(function() m:hideAndChildren() end) end
end
local function click(figure)
    hideMenu()
    if not CW.getWindow() then
        -- (Nov 8 QA) the Character window was gone: say so, and open it so the click can run
        say("NOTE the Character window was not open at the click on " .. figure .. "; opening it")
        pcall(CW.toggle, 0)
    end
    return pcall(HT._onPartClicked, CW.getWindow(), figure, nil, 10, 10)
end
local function queued()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return q and q.queue and #q.queue or 0
end
local function clearQueue() pcall(ISTimedActionQueue.clear, p) end
local function heal(part)
    pcall(function() part:RestoreToFullHealth() end)
    pcall(function() part:setCut(false); part:setCutTime(0); part:setBleedingTime(0) end)
    pcall(function() part:setScratched(false, false); part:setScratchTime(0) end)
    pcall(function() part:setDeepWounded(false); part:setDeepWoundTime(0) end)
    pcall(function() part:setFractureTime(0) end)
    pcall(function() part:setBandaged(false, 0) end)
    pcall(function() part:setStitched(false) end)
end

-- 0. god mode off, invincible on; a clean body; the Health tab open
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    p:setGodMod(false)
    pcall(function() p:setInvincible(true) end)
    check(p:isGodMod() == false, "god mode is off for the run")
    pcall(function() bd:RestoreToFullHealth() end)
    clearQueue()
    local mode = nil
    pcall(function() mode = Wounds.examineMode() end)
    strict = (mode == 1)
    say("Wounds.examineMode() = " .. tostring(mode) .. (strict and " (strictest: the held-back checks run)" or " (not the strictest: the held-back checks are SKIPPED)"))
    for _, item in ipairs({ "Base.Bandage", "Base.Disinfectant", "Base.SutureNeedle", "Base.Needle", "Base.Thread" }) do
        local ok, it = pcall(function() return p:getInventory():AddItem(item) end)
        if not (ok and it) then say("note: " .. item .. " could not be added") end
    end
    if not CW.isOpen() then CW.toggleBothPaired(0) end
end)
step(30, function() keepDown(); CW.openTab(0, "health") end)

-- 1. the wounds, and the tab before the look
step(40, function()
    fa:setCut(true); fa:setCutTime(20); fa:setBleedingTime(10)
    hand:setScratched(true, true); hand:setScratchTime(15)
    neck:setDeepWounded(true); neck:setDeepWoundTime(15)
    keepDown()
end)
step(40, function() keepDown(); HT.gatherData(p) end)   -- (a first read lets the mod's record settle)
step(25, function()
    keepDown()
    local data = HT.gatherData(p)
    local ef, eh, en = entryFor(data, fa), entryFor(data, hand), entryFor(data, neck)
    local lf, lh, ln = labels(ef), labels(eh), labels(en)
    say("left forearm: held " .. tostring(held(fa)) .. " | " .. table.concat(lf, ", "))
    say("right hand: held " .. tostring(held(hand)) .. " | " .. table.concat(lh, ", "))
    say("neck: held " .. tostring(held(neck)) .. " | " .. table.concat(ln, ", "))
    if strict then
        check(held(fa) and held(hand), "WO holds the forearm cut and the hand scratch back until examined")
        check(has(lf, unexamined) and not hasSub(lf, "bleed") and not hasSub(lf, "cut"),
            "the forearm row reads '" .. tostring(unexamined) .. "' and names no cut or bleeding")
        check(has(lh, unexamined) and not hasSub(lh, "scratch"),
            "the hand row reads the mod's line and does not say Scratch")
        check(not held(neck) and #ln > 0 and not has(ln, unexamined), "the neck's deep wound is named (the mod never holds the neck back)")
    else
        say("SKIP held-back checks (examination mode is not the strictest)")
    end
    shot("tab_before")
end)

-- 2. the part menu before the look, then Examine from it
step(20, function()
    local ok, e = click("Left Forearm")
    local names = menuNames()
    say("the forearm's menu (ok " .. tostring(ok) .. (ok and "" or (", " .. tostring(e))) .. "): " .. table.concat(names, " | "))
    if strict then
        check(hasName(names, ZeD.tr("UI_ZeD_Health_Examine")) ~= nil, "the held-back forearm's menu has Examine")
        check(hasName(names, unexamined) ~= nil, "and the mod's gray line")
        check(hasName(names, "bandage") == nil and hasName(names, "stitch") == nil, "and no treatment before the look")
    end
end)
step(25, function() shot("menu_unexamined") end)
local q0
step(10, function()
    if not strict then return end
    q0 = queued()
    local ok, e = pick(ZeD.tr("UI_ZeD_Health_Examine"))
    check(ok, "Examine runs the mod's examination from the menu entry" .. (ok and "" or (": " .. tostring(e))))
    hideMenu()
end)
step(20, function()
    if not strict then return end
    local n = queued()
    check(n > q0, "the examination is queued (queue " .. tostring(q0) .. " -> " .. tostring(n) .. ")")
    -- a second look at the same part while the first runs
    pcall(ZeD.ModSupport.WoundsOverhaul.examine, p, fa)
    check(queued() == n, "a second Examine while it runs adds nothing (" .. tostring(queued()) .. ")")
end)
untilDo(30, 60, function()
    if not strict then return true end
    keepDown()
    HT.gatherData(p)
    return not held(fa)
end, "the examination finishes (the forearm is not held back any more; ~12 s at First Aid 0)")
step(10, function()
    if strict and held(fa) then clearQueue(); fa:setCut(true) end
end)

-- 3. after the look
step(30, function()
    keepDown()
    local data = HT.gatherData(p)
    local lf = labels(entryFor(data, fa))
    say("left forearm after the look: " .. table.concat(lf, ", "))
    if strict then
        check(not has(lf, unexamined) and #lf > 0, "'Something is wrong here.' is gone from the forearm row and the wound is named")
        check(hasSub(lf, "bleed") or hasSub(lf, "cut") or hasSub(lf, "bandage"), "the cut or its bleeding is named")
    end
    shot("tab_after")
end)
step(20, function()
    click("Left Forearm")
    local names = menuNames()
    say("the forearm's menu after the look: " .. table.concat(names, " | "))
    check(#names >= 1, "the examined forearm opens a menu (" .. #names .. " entries)")
    check(hasName(names, ZeD.tr("UI_ZeD_Health_Examine")) == nil, "and it has no Examine")
    check(hasName(names, "bandage") ~= nil, "and the game's Bandage is there (" .. tostring(hasName(names, "bandage")) .. ")")
end)
step(25, function() shot("menu_examined") end)
step(10, function()
    do -- (Nov 8 QA) what the Bandage entry is: the fields the menu gave it
        local m = getPlayerContextMenu(0)
        for _, o in ipairs(m and m.options or {}) do
            if tostring(o.name):lower():find("bandage", 1, true) then
                local f = {}
                for k, v in pairs(o) do f[#f + 1] = tostring(k) .. "=" .. type(v) end
                table.sort(f)
                say("Bandage entry fields: " .. table.concat(f, " ") .. "; notAvailable " .. tostring(o.notAvailable) .. "; subOption " .. tostring(o.subOption))
            end
        end
    end
    local ok, e = pick("bandage")
    hideMenu()
    say("Bandage picked from the menu: " .. tostring(ok) .. " " .. tostring(ok and "" or e))
end)
untilDo(30, 40, function()
    keepDown()
    return fa:bandaged() == true
end, "the bandage goes on the forearm (~10 s)")
step(10, function() shot("bandaged") end)

-- the deep wound and stitching on the examined forearm
local suture = 0
local sutureNew
step(10, function()
    if WoundsSutureGame and WoundsSutureGame.new then
        sutureNew = WoundsSutureGame.new
        WoundsSutureGame.new = function(self, ...) suture = suture + 1; return sutureNew(self, ...) end
    end
    fa:setBandaged(false, 0)
    fa:setDeepWounded(true); fa:setDeepWoundTime(15)
    keepDown()
end)
step(30, function() keepDown(); HT.gatherData(p) end)
step(20, function()
    click("Left Forearm")
    local names = menuNames()
    say("the forearm's menu with a deep wound: " .. table.concat(names, " | "))
    local st = hasName(names, getText("ContextMenu_Stitch"))
    if st then
        check(true, "Stitch is in the menu on the examined deep wound (" .. st .. ")")
        local ok, e = pick(getText("ContextMenu_Stitch"))
        say("Stitch picked: " .. tostring(ok) .. " " .. tostring(ok and "" or e))
    else
        say("SKIP Stitch is not offered (needs a needle and thread the character can use; entries above)")
    end
end)
step(40, function()
    if suture > 0 then check(true, "the mod's suture window opened over ZeD (constructor called " .. suture .. "x)") end
    shot("suture")
    -- close the mod's window: the game's windows list has it
    pcall(function()
        local ui = UIManager.getUI()
        for i = ui:size() - 1, 0, -1 do
            local e = ui:get(i)
            if WoundsSutureGame and instanceof(e, "UIElement") then
                local t = e.table or e
                if getmetatable(t) == WoundsSutureGame then
                    if t.close then t:close() else t:setVisible(false); t:removeFromUIManager() end
                end
            end
        end
    end)
    if sutureNew then WoundsSutureGame.new = sutureNew end
    clearQueue()
    hideMenu()
end)

-- the head with a fracture, examined: no menu at all
step(10, function()
    fa:setDeepWounded(false); fa:setDeepWoundTime(0)
    head:setFractureTime(30)
    keepDown()
end)
step(30, function() keepDown(); HT.gatherData(p) end)
step(10, function()
    if not strict then return end
    local ok, e = pcall(ZeD.ModSupport.WoundsOverhaul.examine, p, head)
    say("examining the head: " .. tostring(ok) .. " " .. tostring(ok and "" or e))
end)
untilDo(30, 60, function()
    if not strict then return true end
    keepDown()
    HT.gatherData(p)
    return not held(head)
end, "the head's examination finishes")
step(10, function()
    local bare = nil
    pcall(function() bare = Wounds.body.bareAxialFracture and Wounds.body.bareAxialFracture(head) end)
    say("bareAxialFracture(head) = " .. tostring(bare))
    click("Head")
    local names, m = menuNames()
    check(#names == 0 or not (m and m:isVisible()), "a skull fracture alone offers no menu (entries: " .. table.concat(names, " | ") .. ")")
    shot("head_fracture")
    hideMenu()
end)

-- 4. healed, then hurt again
step(10, function()
    heal(fa); heal(head); heal(hand); heal(neck)
    keepDown()
end)
step(40, function() keepDown(); HT.gatherData(p) end)
step(20, function()
    keepDown()
    local data = HT.gatherData(p)
    check(entryFor(data, fa) == nil, "the healed forearm leaves the injury list")
    fa:setCut(true); fa:setCutTime(20); fa:setBleedingTime(10)
end)
step(40, function()
    keepDown()
    local data = HT.gatherData(p)
    local lf = labels(entryFor(data, fa))
    say("forearm cut again: held " .. tostring(held(fa)) .. " | " .. table.concat(lf, ", "))
    if strict then
        check(held(fa) and has(lf, unexamined), "cut again: held back again (the old look went with the old wound)")
        click("Left Forearm")
        check(hasName(menuNames(), ZeD.tr("UI_ZeD_Health_Examine")) ~= nil, "and the menu offers Examine again")
    end
    hideMenu()
end)

-- 5. put back
step(10, function()
    hideMenu()
    clearQueue()
    heal(fa); heal(head); heal(hand); heal(neck)
    pcall(function() bd:RestoreToFullHealth() end)
    p:setGodMod(godWas and true or false)
    if invWas ~= nil then pcall(function() p:setInvincible(invWas) end) end
    for _, item in ipairs({ "Base.Bandage", "Base.Disinfectant", "Base.SutureNeedle", "Base.Needle", "Base.Thread" }) do
        pcall(function()
            local it = p:getInventory():FindAndReturn(item)
            if it then p:getInventory():Remove(it) end
        end)
    end
    check(p:isGodMod() == (godWas and true or false), "god mode is back to " .. tostring(godWas))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    waitT = waitT or (now + s.n * 1000 / 60)
    if now < waitT then return end
    waitT = nil
    local ok, res = pcall(s.fn)
    if not ok then
        fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(res)); qi = qi + 1; tries = 0
    elseif s.tries and res ~= true then
        tries = tries + 1
        if tries >= s.tries then fails = fails + 1; say("FAIL timed out: " .. tostring(s.what)); qi = qi + 1; tries = 0 end
    else
        if s.what then say("PASS " .. s.what) end
        qi = qi + 1; tries = 0
    end
end
Events.OnRenderTick.Add(tick)
say("start")
