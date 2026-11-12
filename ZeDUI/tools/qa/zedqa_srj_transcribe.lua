-- ZeDUI/tools/qa/zedqa_srj_transcribe.lua  (Nov 11 2026, QA helper; punch list 172)
-- With Skill Recovery Journal on: the Transcribe keycap in the Skills tab's journal key line
-- (ModSupport/SkillRecoveryJournal.lua, stamped as the Skills stop "srj-transcribe").
--   1 NONE   no Bound Journal carried: no keycap on the tab
--   2 SHOWS  a Bound Journal in the main inventory: the keycap shows, enabled; in a carried bag: it shows
--   3 PRESS  the press (the drawer's own onMouseDown at the keycap, as a click) queues the mod's timed action
--            (SkillRecoveryJournalAction in the player's action queue)
--   4 GREY   no pen, asleep, too dark, someone else's journal: each greys the keycap with the mod's reason in
--            the help line (the pointer is held on the keycap by a stand-in for the mouse), and a press shows
--            the halo text and queues nothing. Someone else's journal needs a Steam ID: with none (no Steam,
--            ID 0) the mod's own menu never flags a journal either, so that case is INFO, not FAIL
--   5 PAD    the controller's focus walks to the keycap on the Skills tab (D-pad, from the first stop and from
--            the first skill row) and A presses it (Focus.dispatchJoypadDown + the qaButton hook)
-- Pictures zqa_srjt_<n>.png. Everything the script changed is put back at the end, after a failed step too
-- (the pens, the journal, the bag, the time, the place, sleep, the hooks). grep "ZEDQA srjt".
local function say(s) print("ZEDQA srjt " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what)
    if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end
end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local cursor = 0
local function after(dt, fn) cursor = cursor + dt; at(cursor, fn) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_srjt_" .. n .. ".png") end) end
local function strip(s, id) for _, z in ipairs(s._hitZones or {}) do if z.id == "tab:" .. id then s:onMouseDown(z.x + 2, z.y + 2) end end end

local M = ZeD.ModSupport and ZeD.ModSupport.SkillRecoveryJournal
local Focus = ZeD.Input and ZeD.Input.Focus
local P = getPlayer()
local STOP_ID = "srj-transcribe"
local JT = "SkillRecoveryBoundJournal"
local was = { tod = getGameTime():getTimeOfDay(), x = P:getX(), y = P:getY(), z = P:getZ() }
local added, removedPens, removedJournals = {}, {}, {}
local journal, bag, bagAdded = nil, nil, false
local sleepHold = false
local helpSeen, halos, forced = nil, {}, nil
local origMouseIn, origHelpSet, origHalo = nil, nil, nil
local hooked = false

-- ---- helpers --------------------------------------------------------------
local function stopNow()
    local W = cw()
    local list = W and W._skillsStops
    for i = 1, list and list.n or 0 do
        if list[i].id == STOP_ID then return list[i] end
    end
    return nil
end
local function goTo(x, y, z) P:setX(x); P:setY(y); P:setZ(z); P:setLastX(x); P:setLastY(y); P:setLastZ(z) end
local function queueInfo()
    local q = ISTimedActionQueue.getTimedActionQueue(P)
    local names, srj = {}, false
    for _, a in ipairs(q and q.queue or {}) do
        names[#names + 1] = tostring(a.Type)
        if a.Type == "SkillRecoveryJournalAction" then srj = true end
    end
    return srj, table.concat(names, ",")
end
local function clearQueue() pcall(function() ISTimedActionQueue.clear(P) end) end
local function press(s)
    local W = cw()
    local d = W._drawerPanel
    d.onMouseDown(d, s.x + math.floor(s.w / 2), s.y + math.floor(s.h / 2))
end
local function hold(s) forced = s and { x = s.x, y = s.y, w = s.w, h = s.h } or nil; helpSeen = nil end
local function expectedHelp(why)
    return ZeD.tr("UI_ZeD_Map_HelpCant", ZeD.btnCase(ZeD.tr("IGUI_TranscribeIntoJournal")), why)
end
local function hookUp()
    if hooked then return end
    hooked = true
    origMouseIn = ZeD.Atoms.mouseIn
    ZeD.Atoms.mouseIn = function(panel, x, y, w, h, view)
        if forced and x == forced.x and y == forced.y and w == forced.w and h == forced.h then return true end
        return origMouseIn(panel, x, y, w, h, view)
    end
    origHelpSet = ZeD.Help.set
    ZeD.Help.set = function(panel, text) helpSeen = text; return origHelpSet(panel, text) end
    if HaloTextHelper then
        origHalo = HaloTextHelper.addBadText
        HaloTextHelper.addBadText = function(ch, text, ...) halos[#halos + 1] = tostring(text); return origHalo(ch, text, ...) end
    end
end
local function hookDown()
    if not hooked then return end
    hooked = false
    pcall(function() ZeD.Atoms.mouseIn = origMouseIn end)
    pcall(function() ZeD.Help.set = origHelpSet end)
    pcall(function() if origHalo then HaloTextHelper.addBadText = origHalo end end)
end
local function takeJournals()   -- every Bound Journal off the character (put back at the end)
    for _ = 1, 10 do
        local it = P:getInventory():getFirstTypeRecurse(JT)
        if not it then break end
        local c = it:getContainer()
        removedJournals[#removedJournals + 1] = { it = it, c = c }
        c:Remove(it)
    end
end

-- one grey case: set the condition, wait, check keycap + help line + press, undo, wait, check it is live again
local function greyCase(tag, num, key, setf, undof, extraWait)
    local why
    after(5, function() setf() end)
    after(extraWait or 80, function()
        local s = stopNow()
        check(s ~= nil, num .. " " .. tag .. ": the keycap still shows (greyed, not hidden)")
        if not s then return end
        local j = M.journal(P)
        local w = M.transcribeWhy(P, j.item)
        why = getText(key)
        check(w == why, num .. " " .. tag .. ": the mod's reason is '" .. tostring(why) .. "' (support says '" .. tostring(w) .. "')")
        hold(s)   -- the pointer rests on the keycap: the footer's help line
    end)
    after(8, function()
        local s = stopNow()
        local want = why and expectedHelp(why)
        say(num .. " " .. tag .. ": help line '" .. tostring(helpSeen) .. "'")
        check(want ~= nil and helpSeen == want, num .. " " .. tag .. ": the help line gives the mod's reason")
        shot(num .. "_" .. tag)
        halos = {}; clearQueue()
        if s then press(s) end
    end)
    after(4, function()
        local srj, names = queueInfo()
        say(num .. " " .. tag .. ": halo " .. table.concat(halos, " | ") .. "; queue [" .. names .. "]")
        check(why ~= nil and halos[1] == why, num .. " " .. tag .. ": the press shows the halo text")
        check(srj == false, num .. " " .. tag .. ": the press queues no transcribe action")
        clearQueue()
        hold(nil)
        undof()
    end)
    after(80, function()
        local s = stopNow()
        local j = M.journal(P)
        local w = j and M.transcribeWhy(P, j.item)
        check(s ~= nil and w == nil, num .. " " .. tag .. " undone: the keycap is live again (reason " .. tostring(w) .. ")")
    end)
end

-- ---- the run ----------------------------------------------------------------
after(2, function()
    say("start; mod support " .. tostring(M ~= nil) .. "; SteamID " .. tostring(P.getSteamID and P:getSteamID()))
    if not M then check(false, "setup: ZeD's Skill Recovery Journal support is not loaded (is the mod on?)") end
    hookUp()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    P:getModData()   -- (touch)
    takeJournals()
    say("journals taken off the character: " .. #removedJournals)
    if not P:getInventory():getFirstTagRecurse(ItemTag.WRITE) then
        local pen = P:getInventory():AddItem("Base.Pen")
        if pen then added[#added + 1] = pen end
        say("no pen carried: one added")
    end
end)
after(20, function()
    strip(cw()._tabStripPanel, "skills")
    cw()._skillsGridExpanded = true
end)
-- 1 NONE
after(70, function()
    local s = stopNow()
    local carried = P:getInventory():getFirstTypeRecurse(JT) ~= nil
    say("1: journal carried " .. tostring(carried) .. ", Skills tab " .. tostring(cw()._activeTab) .. ", stops " .. tostring(cw()._skillsStops and cw()._skillsStops.n))
    check(cw()._activeTab == "skills" and carried == false and s == nil, "1 NONE: no Bound Journal carried, no keycap on the Skills tab")
    shot("1_none")
end)
-- 2 SHOWS
after(5, function()
    journal = P:getInventory():AddItem("Base." .. JT)
    say("journal added: " .. tostring(journal and journal:getDisplayName()))
end)
after(70, function()
    local s = stopNow()
    local j = M and M.journal(P)
    check(s ~= nil, "2 SHOWS (main inventory): the keycap shows" .. (s and string.format(" (%d,%d %dx%d)", s.x, s.y, s.w, s.h) or ""))
    local v = cw()._skillsHoverView
    check(s ~= nil and v ~= nil and s.y >= v.y and s.y + s.h <= v.y + v.h, "2 SHOWS: it is inside the tab's visible area")
    local w = j and M.transcribeWhy(P, j.item)
    check(j ~= nil and w == nil, "2 SHOWS: enabled (no reason from the mod)" .. (w and (": " .. w) or ""))
    if s then hold(s) end
end)
after(8, function()
    check(helpSeen == nil, "2 SHOWS: enabled keycap gives no 'cannot' help line (" .. tostring(helpSeen) .. ")")
    hold(nil)
    shot("2_main")
    -- into a carried bag: a worn one, else one added to the inventory
    local items = P:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "InventoryContainer") and it:isEquipped() then bag = it; break end
    end
    if not bag then
        bag = P:getInventory():AddItem("Base.Bag_DuffelBag")
        bagAdded = bag ~= nil
        if bag then added[#added + 1] = bag end
    end
    say("bag " .. tostring(bag and bag:getDisplayName()) .. (bagAdded and " (added)" or " (worn)"))
    if bag and journal then
        P:getInventory():Remove(journal); bag:getItemContainer():AddItem(journal)
    end
end)
after(70, function()
    local s = stopNow()
    local j = M and M.journal(P)
    say("2: journal in " .. tostring(j and j.where))
    check(bag ~= nil and j ~= nil and j.where ~= ZeD.trBare("IGUI_InventoryTooltip"), "2 SHOWS (bag): the journal is in a bag, '" .. tostring(j and j.where) .. "'")
    check(s ~= nil, "2 SHOWS (bag): the keycap shows")
    shot("2_bag")
    if bag and journal then bag:getItemContainer():Remove(journal); P:getInventory():AddItem(journal) end
end)
-- 3 PRESS
after(70, function()
    local s = stopNow()
    check(s ~= nil, "3 PRESS: the keycap is there again with the journal back in the inventory")
    clearQueue(); halos = {}
    if s then press(s) end
end)
after(3, function()
    local srj, names = queueInfo()
    say("3: queue [" .. names .. "], halo " .. table.concat(halos, " | "))
    check(srj, "3 PRESS: the mod's transcribe timed action (SkillRecoveryJournalAction) is in the queue")
    check(#halos == 0, "3 PRESS: no halo text on a live press")
end)
after(20, function() shot("3_press"); clearQueue() end)
after(40, function() end)
-- 4 GREY: no pen
greyCase("nopen", "4a", "Tooltip_Map_CantWrite", function()
    for _ = 1, 20 do
        local it = P:getInventory():getFirstTagRecurse(ItemTag.WRITE)
        if not it then break end
        local c = it:getContainer()
        removedPens[#removedPens + 1] = { it = it, c = c }
        c:Remove(it)
    end
    say("4a: pens taken: " .. #removedPens)
end, function()
    for _, r in ipairs(removedPens) do r.c:AddItem(r.it) end
    removedPens = {}
end)
-- 4 GREY: asleep
greyCase("asleep", "4b", "ContextMenu_NoOptionSleeping", function()
    sleepHold = true; P:setAsleep(true)
    say("4b: asleep " .. tostring(P:isAsleep()))
end, function()
    sleepHold = false; P:setAsleep(false)
    say("4b: asleep " .. tostring(P:isAsleep()))
end)
-- 4 GREY: dark (night; an unlit indoor spot when the open air is not dark enough)
after(5, function() getGameTime():setTimeOfDay(0) end)
after(120, function()
    local dark = P:tooDarkToRead()
    say("4c: dark at night where we stand: " .. tostring(dark))
    if dark then return end
    local bx, by, bz = math.floor(was.x), math.floor(was.y), math.floor(was.z)
    local best, bd
    for dy = -40, 40, 2 do for dx = -40, 40, 2 do
        local sq = getCell():getGridSquare(bx + dx, by + dy, bz)
        local okSq = sq and pcall(function() return sq:isOutside() end) and not sq:isOutside() and sq:isFree(false)
        if okSq and (not bd or math.abs(dx) + math.abs(dy) < bd) then best, bd = sq, math.abs(dx) + math.abs(dy) end
    end end
    if best then goTo(best:getX() + 0.5, best:getY() + 0.5, best:getZ()) end
    say("4c: indoor spot " .. (best and (best:getX() .. "," .. best:getY()) or "none"))
end)
after(120, function() say("4c: dark now: " .. tostring(P:tooDarkToRead())) end)
local darkOk = false
after(2, function() darkOk = P:tooDarkToRead() == true end)
after(2, function()
    if not darkOk then
        say("INFO 4c dark: it never got dark enough here (lights near the spot); the grey case is not shown")
        return
    end
end)
do
    local function gate(fn) return function() if darkOk then fn() end end end
    local why4c
    after(5, gate(function()
        local s = stopNow()
        check(s ~= nil, "4c dark: the keycap still shows (greyed, not hidden)")
        local j = M.journal(P)
        local w = j and M.transcribeWhy(P, j.item)
        why4c = getText("ContextMenu_TooDark")
        check(w == why4c, "4c dark: the mod's reason is '" .. why4c .. "' (support says '" .. tostring(w) .. "')")
        hold(s)
    end))
    after(8, gate(function()
        local s = stopNow()
        say("4c dark: help line '" .. tostring(helpSeen) .. "'")
        check(helpSeen == expectedHelp(why4c), "4c dark: the help line gives the mod's reason")
        shot("4c_dark")
        halos = {}; clearQueue()
        if s then press(s) end
    end))
    after(4, gate(function()
        local srj, names = queueInfo()
        say("4c dark: halo " .. table.concat(halos, " | ") .. "; queue [" .. names .. "]")
        check(halos[1] == why4c, "4c dark: the press shows the halo text")
        check(srj == false, "4c dark: the press queues no transcribe action")
        clearQueue(); hold(nil)
    end))
end
after(5, function()
    getGameTime():setTimeOfDay(was.tod)
    goTo(was.x, was.y, was.z)
end)
after(100, function() say("4c undone: dark " .. tostring(P:tooDarkToRead())) end)
-- 4 GREY: someone else's journal
local sid = nil
local oldSRJ, hadSRJ = nil, false
after(2, function()
    sid = P.getSteamID and P:getSteamID() or 0
    local md = journal:getModData()
    hadSRJ, oldSRJ = md["SRJ"] ~= nil, md["SRJ"]
    md["SRJ"] = { display = { author = "Someone Else", identity = { steamID = (sid or 0) + 4242 } } }
    say("4d: SteamID of the character " .. tostring(sid) .. "; journal stamped with another author's ID")
end)
after(80, function()
    local s = stopNow()
    local j = M.journal(P)
    local w = j and M.transcribeWhy(P, j.item)
    if sid == 0 then
        -- no Steam: the mod's own menu (Context.lua) only compares IDs when the character's ID is not 0, so it
        -- never greys here either; the keycap must agree with it (live)
        say("INFO 4d someone else's journal: the character has no Steam ID (0), so the mod itself never flags a journal as someone else's on this rig; covered by srj_transcribe_sim.lua")
        check(s ~= nil and w == nil, "4d someone else's journal, no Steam ID: the keycap agrees with the mod's menu (live), reason " .. tostring(w))
        shot("4d_otherjournal")
    else
        local why = getText("IGUI_PlayerText_DoesntFeelRightToWrite")
        check(s ~= nil and w == why, "4d someone else's journal: grey with the mod's reason '" .. why .. "' (support says '" .. tostring(w) .. "')")
        if s then hold(s) end
    end
end)
after(8, function()
    if sid == 0 then return end
    local s = stopNow()
    local why = getText("IGUI_PlayerText_DoesntFeelRightToWrite")
    say("4d: help line '" .. tostring(helpSeen) .. "'")
    check(helpSeen == expectedHelp(why), "4d someone else's journal: the help line gives the mod's reason")
    shot("4d_otherjournal")
    halos = {}; clearQueue()
    if s then press(s) end
end)
after(4, function()
    if sid == 0 then return end
    local srj, names = queueInfo()
    check(halos[1] == getText("IGUI_PlayerText_DoesntFeelRightToWrite"), "4d someone else's journal: the press shows the halo text")
    check(srj == false, "4d someone else's journal: the press queues no transcribe action")
    clearQueue(); hold(nil)
end)
after(3, function()
    local md = journal:getModData()
    md["SRJ"] = hadSRJ and oldSRJ or nil
    hold(nil)
end)
-- 5 PAD
local W5
after(60, function()
    W5 = cw()
    ZeD.Input.Detector.setLockedMode("gamepad")
    Focus.claimFocus(W5)
    local ok = Focus.focusWhere(W5, "charTabContent", function(e) return true end)
    local e = Focus.getFocusedElement(W5)
    say("5: start on the first stop: " .. tostring(e and e.id) .. " (" .. tostring(ok ~= nil) .. ")")
end)
local function walk(tag, order)
    local visited, path = {}, {}
    local found = false
    local function hop(n)
        local e = Focus.getFocusedElement(W5)
        path[#path + 1] = tostring(e and e.id or "?")
        if e and e.id == "skills:stop:" .. STOP_ID then found = true end
        if found or n >= 8 then
            say("5 " .. tag .. ": path " .. table.concat(path, " > "))
            check(found, "5 PAD (" .. tag .. "): the controller's focus reaches the keycap by the D-pad (" .. #path - 1 .. " moves)")
            return
        end
        visited[e and e.id or "?"] = true
        local pick
        for _, d in ipairs(order or { "down", "right", "up", "left" }) do
            local r = Focus.previewMove(W5, d)
            if r and r.id == "skills:stop:" .. STOP_ID then pick = d; break end
            if not pick and r and r.id and not visited[r.id] then pick = d end
        end
        if not pick then
            say("5 " .. tag .. ": path " .. table.concat(path, " > ") .. " (no way on)")
            check(false, "5 PAD (" .. tag .. "): the controller's focus reaches the keycap by the D-pad")
            return
        end
        Focus.dispatchJoypadDir(W5, pick)
        steps[#steps + 1] = { n = tick + 6, fn = function() hop(n + 1) end }
    end
    return hop
end
after(10, function() walk("from the first stop")(0) end)
after(80, function()
    shot("5_pad_focus")
    local e = Focus.getFocusedElement(W5)
    if not (e and e.id == "skills:stop:" .. STOP_ID) then
        Focus.focusWhere(W5, "charTabContent", function(x) return x.id == "skills:stop:" .. STOP_ID end)
        say("5: the walk did not arrive; focus put on the keycap by id")
    end
    clearQueue(); halos = {}
    Focus.dispatchJoypadDown(W5, Joypad.AButton); Focus.qaButton("A", false)
end)
after(10, function()
    Focus.qaButton("A", nil)
    local srj, names = queueInfo()
    say("5: after A: queue [" .. names .. "]")
    check(srj, "5 PAD: A on the keycap queues the mod's transcribe timed action")
    clearQueue()
end)
after(30, function()
    -- a second start, from the first skill row
    Focus.focusWhere(W5, "charTabContent", function(e) return e.skillName ~= nil end)
    local e = Focus.getFocusedElement(W5)
    say("5: second start on " .. tostring(e and (e.skillName or e.id)))
end)
after(10, function() walk("from the first skill row", { "up", "right", "left", "down" })(0) end)
-- put everything back
after(80, function()
    local function try(label, fn) local ok, e = pcall(fn); if not ok then say("ERR cleanup " .. label .. ": " .. tostring(e)) end end
    try("queue", clearQueue)
    try("pad", function() Focus.qaButton("A", nil); ZeD.Input.Detector.setLockedMode(nil) end)
    try("sleep", function() sleepHold = false; P:setAsleep(false) end)
    try("time", function() getGameTime():setTimeOfDay(was.tod); goTo(was.x, was.y, was.z) end)
    try("hold", function() hold(nil) end)
    try("pens", function() for _, r in ipairs(removedPens) do r.c:AddItem(r.it) end; removedPens = {} end)
    try("journal", function()
        if journal and journal:getContainer() then journal:getContainer():Remove(journal) end
    end)
    try("added", function() for _, it in ipairs(added) do if it:getContainer() then it:getContainer():Remove(it) end end end)
    try("journals back", function() for _, r in ipairs(removedJournals) do r.c:AddItem(r.it) end end)
    try("hooks", hookDown)
    say("put back: pens, journal, bag, time, place, sleep, hooks")
    say("RESULT " .. nPass .. " pass, " .. nFail .. " fail")
    say("DONE")
end)

local function onTick()
    tick = tick + 1
    if sleepHold then pcall(function() P:setAsleep(true) end) end
    local n = #steps
    for i = 1, n do
        local s = steps[i]
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR step " .. tostring(s.n) .. " " .. tostring(e)) end
        end
    end
    if tick > cursor + 400 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
