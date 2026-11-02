-- ZeDUI/tools/qa/zedqa_pad_marks.lua  (Nov 1 2026; punch list 44, for t16)
-- Controller marks in the inventory, both windows: the Character window's main list and a World
-- window column (crate B, opened as a column beside the main list showing crate A; both crates are
-- built beside the character for the run).
--
-- THE HOLD CANNOT BE DRIVEN TODAY. FocusManager keeps the A and X hold state in file locals
-- (_aHeld, _aStartMs, _aConsumed, _aWindow; _xHeld ... X_HOLD_MS), out of a script's reach, and its
-- OnTick poll (_onTick, sections C2 / C3) decides "held past 350 ms" and "let go" by reading the
-- real button every tick: JoypadButton.A:isDown(jid) / JoypadButton.X:isDown(jid). The poll also
-- stops before those sections when player 1 has no controller bound (getJoypadData(0) with no id),
-- which is how the QA character plays. So a press sent through Focus.dispatchJoypadDown(A or X)
-- either resolves as a tap on the next tick (a pad bound, its button up) or stays armed for good
-- (no pad bound). There is no field a script can set to say "A is held".
-- What this script does instead (the stand-in), each the exact call the manager would make:
--   hold A    = the focused row's onHoldActivate(w, el)        (_handleHoldConfirm's call: padMark)
--   held Down = Focus.dispatchJoypadDir(w, "down"), then the row landed on takes
--               el.onPaint(w, el, w._gpPaint)                  (the _handleSpatialNav wrapper's call)
--   let go A  = w._gpPaint = nil                               (the C2 release's line)
--   hold X    = the focused row's onHoldContext(w, el)         (C3's one-shot call: the quick use)
--   tap A / X = the focused element's onActivate / onContextMenu (a pad bound: dispatchJoypadDown)
--   B         = Focus.dispatchJoypadDown(w, Joypad.BButton)    (the real path: B is immediate)
-- Marks set up for a check that is not about marking (the menu, B, tap A, the band) are made with
-- InventoryRenderer.padMark straight on the row elements, focus kept; the lines say so.
-- The hook Build can add (FocusManager.lua) so the real hold runs: a stand-in for the two buttons'
-- state, read by C2 / C3 in place of the raw button, and C2 / C3 run before the "no controller
-- bound" return. This script looks for Focus.qaButton and, when it exists, drives the real hold:
--     dispatchJoypadDown(A); Focus.qaButton("A", true); wait 450 ms by the clock (the poll fires
--     onHoldActivate); dispatchJoypadDir Down (the wrapper paints); Focus.qaButton("A", false)
--     (the poll's release clears _gpPaint); Focus.qaButton("A", nil) (back to the real pad).
--
-- Checks ("ZEDQA pmk PASS/FAIL ..." with the values), in each window's list:
--   hold A marks the row (in its list's selection = the wash; padMarkCount 1); with one mark the
--   card is hidden; hold A again unmarks; a stack header marks its stack (count = the stack's
--   size); hold A + Down x3 marks the four rows (union of their stacks) and letting go ends the
--   stroke (the next Down leaves the marks as they were); with the marks the card is hidden; the
--   help line's words "N marked | X: menu for all | B: clear marks" are stamped, and drawn (not
--   replaced by the prompts); the footer's X and B prompts read "Menu for marked" and "Clear
--   marks"; X opens the game's menu and its Drop / Grab takes all N (the option's items printed);
--   B clears the marks and the focus stays on the row; tap A on a marked row opens its card and the
--   other marks go. World only: marks in the column and in the main list stay apart (selections
--   and X's items); hold X on a crate row brings it to the main inventory; the band's Take with two
--   of crate A's three rows marked takes the two and leaves the third.
-- Pictures: zqa_pmk_char_marks.png, zqa_pmk_world_marks.png (the marked run, the rect printed).
-- Puts back: marks cleared, the card closed, the column shut, the crates and the run's things
-- removed, the help-line wrapper taken off, input mode back to auto. grep "ZEDQA pmk".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det, R = ZeD.Input.Focus, ZeD.Input.Detector, ZeD.InventoryRenderer
local function say(s) print("ZEDQA pmk " .. tostring(s)) end
local S = { pass = 0, fail = 0, added = {}, crates = {}, helpLog = {} }
S.hook = type(Focus.qaButton) == "function"
local SW, SH = getCore():getScreenWidth(), getCore():getScreenHeight()
local function check(ok, what)
    if ok then S.pass = S.pass + 1; say("PASS " .. what) else S.fail = S.fail + 1; say("FAIL " .. what) end
    return ok
end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local function fw() return Focus.getFocusedWindow() end
local function wname(w) return (w == cw() and "Char") or (w == ww() and "World") or tostring(w) end
local function nm(item) return item and tostring(item:getName()) or "nil" end
local function rs(x, y, w, h) return string.format("%d,%d %dx%d", math.floor(x), math.floor(y), math.floor(w), math.floor(h)) end
local function nKeys(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end

-- ---- the step queue: each step runs, then waits n ticks; a step may queue more right after itself
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end
-- wait until both windows stop moving (as zedqa_preview_card.lua)
local STILL, STILL_MAX = 30, 600
local function shape()
    local out = {}
    for _, w in ipairs({ cw(), ww() }) do
        if w and w:isVisible() then
            out[#out + 1] = string.format("%d,%d,%d,%d,%d", math.floor(w:getX()), math.floor(w:getY()),
                math.floor(w:getWidth()), math.floor(w:getHeight()), math.floor(w._drawerEffW or 0))
        end
    end
    return table.concat(out, ";")
end
local function whenStill(fn)
    local last, same, waited = nil, 0, 0
    local function poll()
        local s = shape()
        if s == last then same = same + 1 else same, last = 0, s end
        waited = waited + 1
        if same >= STILL or waited >= STILL_MAX then
            if same < STILL then say("WARN the windows were still moving after " .. waited .. " ticks: checked anyway") end
            local ok, e = pcall(fn)
            if not ok then say("ERR " .. tostring(e)) end
        else
            insertNext(0, poll)
        end
    end
    insertNext(0, poll)
end

-- ---- lists: L = { w, zone, col (a column's slot, nil for the main list), name, stackType }
local function zoneOf(w, zn)
    for _, z in ipairs(w and w._focusRing or {}) do if z.zone == zn then return z end end
    return nil
end
local function elIn(w, zn, pred)
    local z = zoneOf(w, zn)
    for i, e in ipairs(z and z.elements or {}) do if pred(e, i) then return e end end
    return nil
end
local function rowsOf(L)
    local out = {}
    local z = L and zoneOf(L.w, L.zone)
    for _, e in ipairs(z and z.elements or {}) do if e.item then out[#out + 1] = e end end
    return out
end
-- the list's own selection table (the marks): a column's, or the main list's
local function selOf(L)
    local cnt = L and L.w and L.w._mainContent
    if not cnt then return {} end
    if L.col then
        local cs = cnt._colStates and cnt._colStates[L.col]
        return (cs and cs.selectedItems) or {}
    end
    return cnt._selectedItems or {}
end
-- the things a row stands for: a stack header's whole stack, else the one thing
local function stackItems(L, item)
    local cnt = L.w._mainContent
    local stacks
    if L.col then
        local cs = cnt and cnt._colStates and cnt._colStates[L.col]
        stacks = cs and cs.stacks
    else
        stacks = cnt and cnt._stacks
    end
    local s = stacks and stacks[item]
    if s and s.count > 1 and s.items then return s.items end
    return { item }
end
local function rowEl(L, item)
    for _, e in ipairs(rowsOf(L)) do if e.item == item then return e end end
    return nil
end
local function focusRow(L, item)
    Focus.claimFocus(L.w)
    return Focus.focusWhere(L.w, L.zone, function(e) return e.item == item end)
end
-- the item the list's focused row carries (nil when the focus is not in this list)
local function focusedItem(L)
    local z = Focus.getFocusedZone(L.w)
    local e = Focus.getFocusedElement(L.w)
    if z and z.zone == L.zone and e then return e.item, z, e end
    return nil, z, e
end
local function colOn(w, inv)
    for i, c in ipairs(w and w._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(w._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
local function stripTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end

-- ---- the buttons (see the header: the stand-in, or the hook when Build adds Focus.qaButton)
local HOLD_WAIT_MS = 450
local BTN = { A = Joypad.AButton, X = Joypad.XButton }
local function padBound()
    local jd = getJoypadData and getJoypadData(0)
    return jd ~= nil and jd.id ~= nil
end
local function tap(w, name)
    local e = Focus.getFocusedElement(w)
    if S.hook then
        Focus.dispatchJoypadDown(w, BTN[name]); Focus.qaButton(name, false)
        insertNext(3, function() Focus.qaButton(name, nil) end)
        return "dispatch + qaButton"
    elseif padBound() then
        Focus.dispatchJoypadDown(w, BTN[name])
        return "dispatch"
    end
    if name == "A" then
        if e and e.onActivate then e.onActivate(w, e) end
    elseif e and e.onContextMenu then
        e.onContextMenu(w, e)
    end
    return "direct"
end
-- hold: fn runs once the hold has fired (A still held)
local function hold(w, name, fn)
    if S.hook then
        Focus.dispatchJoypadDown(w, BTN[name]); Focus.qaButton(name, true)
        local t0 = getTimestampMs()
        local function waitHold()
            if getTimestampMs() - t0 >= HOLD_WAIT_MS then insertNext(2, fn) else insertNext(1, waitHold) end
        end
        insertNext(1, waitHold)
        return
    end
    local e = Focus.getFocusedElement(w)
    if name == "A" then
        if e and e.onHoldActivate then e.onHoldActivate(w, e) end
    elseif e and e.onHoldContext then
        e.onHoldContext(w, e)
    end
    insertNext(2, fn)
end
local function letGo(w, name)
    if S.hook then
        Focus.qaButton(name, false)
        insertNext(3, function() Focus.qaButton(name, nil) end)
        return
    end
    if name == "A" and w then w._gpPaint = nil end
end
-- a D-pad press; while a stroke is armed (A held past its hold), the row landed on takes its mark
local function down(w, dirn)
    Focus.dispatchJoypadDir(w, dirn or "down")
    if (not S.hook) and w and w._gpPaint then
        local e = Focus.getFocusedElement(w)
        if e and e.onPaint then e.onPaint(w, e, w._gpPaint) end
    end
end

-- ---- what the window shows: the footer's prompts, the help line's words, the menu
local function promptsOf(w)
    local ok, ps = pcall(function() return w:_footerPrompts() end)
    local parts, by = {}, {}
    if ok and type(ps) == "table" then
        for _, pr in ipairs(ps) do
            local g = tostring(pr.glyph)
            parts[#parts + 1] = g .. ": " .. tostring(pr.label)
            by[g] = by[g] or {}
            table.insert(by[g], tostring(pr.label))
        end
    end
    return table.concat(parts, " | "), by, #parts
end
local function has(list, s)
    for _, x in ipairs(list or {}) do if x == s then return true end end
    return false
end
local function join(list) return (list and #list > 0) and table.concat(list, " / ") or "none" end
local function menuRead()
    local vm = getPlayerContextMenu and getPlayerContextMenu(pn)
    local names, form, nT = {}, nil, nil
    local FORM = {}
    for _, k in ipairs({ "ContextMenu_Drop", "ContextMenu_Grab", "ContextMenu_Grab_all", "ContextMenu_Move_To" }) do FORM[getText(k)] = true end
    if vm and vm.options then
        for i = 1, (vm.numOptions or 1) - 1 do
            local o = vm.options[i]
            if o and o.name then
                local n = tostring(o.name)
                names[#names + 1] = n
                if (not form) and FORM[n] and type(o.target) == "table" then form = n; nT = #o.target end
            end
        end
    end
    return names, vm, form, nT
end
local function menuClose(vm)
    local zm = vm and vm._zedMenu
    if zm and zm.onJoypadDown then pcall(function() zm:onJoypadDown(Joypad.BButton) end)
    elseif vm then pcall(function() vm:setVisible(false) end) end
end
local function shot(what)
    local name = "zqa_pmk_" .. what .. ".png"
    pcall(function() getCore():TakeFullScreenshot(name) end)
    local L = S.L
    local w = L and L.w
    if not w then say("shot " .. name); return end
    local cnt = w._mainContent
    local e = Focus.getFocusedElement(w)
    say(string.format("shot %s (%dx%d): %s window %s | list panel %s | focus %s %s, row %s (panel) | %d marked",
        name, SW, SH, wname(w), rs(w:getX(), w:getY(), w:getWidth(), w:getHeight()),
        cnt and rs(cnt:getAbsoluteX(), cnt:getAbsoluteY(), cnt:getWidth(), cnt:getHeight()) or "?",
        tostring(L.zone), nm(e and e.item), e and rs(e.x or 0, e.y or 0, e.w or 0, e.h or 0) or "?", nKeys(selOf(L))))
end

-- ---- the crates (as zedqa_world_pad_take.lua builds one)
local MINE = { ["Base.Nails"] = true, ["Base.Bandage"] = true, ["Base.Hammer"] = true, ["Base.Apple"] = true,
    ["Base.TinnedBeans"] = true, ["Base.Eraser"] = true, ["Base.Tweezers"] = true, ["Base.Corkscrew"] = true }
local function onlyMine(c)
    local items = c:getItems()
    for i = 0, items:size() - 1 do if not MINE[items:get(i):getFullType()] then return false end end
    return true
end
local function sweepOldCrates()
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    local n = 0
    for dy = -2, 2 do for dx = -2, 2 do
        local sq = getCell():getGridSquare(px + dx, py + dy, 0)
        local objs = sq and sq:getObjects()
        for i = (objs and objs:size() or 0) - 1, 0, -1 do
            local o = objs:get(i)
            local md
            pcall(function() md = o:getModData() end)
            if instanceof(o, "IsoThumpable") and tostring(o:getName()) == "Wood_Crate_Lvl1" and o:getContainer()
               and not (md and md.ZeDDeepRun) and ((md and md.ZeDQA == "pmk") or onlyMine(o:getContainer()))
               and not o:isLockedByPadlock() and (o:getLockedByCode() or 0) == 0 then
                o:getContainer():removeAllItems()
                sq:transmitRemoveItemFromSquare(o)
                n = n + 1
            end
        end
    end end
    if n > 0 then say("swept " .. n .. " old test crate(s)") end
end
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
    return nil
end
local function buildCrate()
    local info = findInfo("Base.Wood_Crate_Lvl1")
    if not info then return nil end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for _, o in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(px + o[1], py + o[2], 0)
        if sq then
            p:setBuildCheat(true)
            local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
            b.buildCheat = true; b.player = pn; b.sq = sq
            local ok, valid = pcall(function() return b:isValid(sq) end)
            if ok and valid then pcall(function() b:create(px + o[1], py + o[2], 0, false, nil) end) end
            p:setBuildCheat(false)
            if ok and valid then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local c = objs:get(i)
                    if instanceof(c, "IsoThumpable") and c:getContainer() then
                        pcall(function() c:getModData().ZeDQA = "pmk" end)
                        S.crates[#S.crates + 1] = c
                        return c:getContainer()
                    end
                end
            end
        end
    end
    return nil
end
local function addTo(inv, list)
    for _, t in ipairs(list) do
        local it = inv:AddItem(t)
        if it then S.added[#S.added + 1] = it end
    end
end

-- ---- waits for the moves (the quick use, the band's Take)
local function waitQu()
    S.quWait = S.quWait + 1
    local c = S.qu:getContainer()
    local inBag = c == p:getInventory()
    if inBag or S.quWait > 60 then
        check(inBag, string.format("hold X on a row in the crate is the quick use: %s came to the main inventory (now in %s, %d ticks)",
            nm(S.qu), c and tostring(c:getType()) or "nothing", S.quWait * 10))
        return
    end
    insertNext(10, waitQu)
end
local function waitBand()
    S.bandWait = S.bandWait + 1
    local busy = false
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        busy = q ~= nil and q.queue ~= nil and #q.queue > 0
    end)
    if (busy or S.bandWait < 3) and S.bandWait <= 60 then insertNext(10, waitBand); return end
    local inv = p:getInventory()
    local got, names = 0, {}
    for _, it in ipairs(S.bandMarked) do
        if it:getContainer() == inv then got = got + 1 end
        names[#names + 1] = nm(it)
    end
    local leftIn = S.bandLeft:getContainer()
    check(got == #S.bandMarked and leftIn == S.crateA,
        string.format("the band's Take with marks takes the %d marked (%s) and leaves the rest: %d of them in the bag, the unmarked %s in %s",
            #S.bandMarked, table.concat(names, ", "), got, nm(S.bandLeft),
            (leftIn == S.crateA and "the crate") or (leftIn == inv and "the bag") or tostring(leftIn and leftIn:getType())))
end

-- ===================================================================== the run on one list (S.L)
local function queueMarks(tag, shotName)
    local T = tag .. ": "
    -- 1. the rows: four in a row (single things), and a stack
    step(10, function()
        local L = S.L
        S.skip, S.run, S.stack = true, {}, nil
        if not L then say(T .. "skipped (no list)"); return end
        R.padClearMarks(L.w)
        local z = zoneOf(L.w, L.zone)
        local els = z and z.elements or {}
        for i = 1, #els - 3 do
            local ok = true
            for j = i, i + 3 do
                local e = els[j]
                if not (e.item and #stackItems(L, e.item) == 1) then ok = false end
            end
            if ok then S.run = { els[i].item, els[i + 1].item, els[i + 2].item, els[i + 3].item }; break end
        end
        for _, e in ipairs(rowsOf(L)) do
            local n = #stackItems(L, e.item)
            if n > 1 and (not S.stack or e.item:getFullType() == L.stackType) then S.stack = e.item end
        end
        local runNames = {}
        for _, it in ipairs(S.run) do runNames[#runNames + 1] = nm(it) end
        say(string.format("%s%s, %d rows (%d stops); four in a row: %s; a stack: %s x%d; the hold: %s", T, L.name, #rowsOf(L), #els,
            (#runNames > 0 and table.concat(runNames, ", ") or "none"), nm(S.stack), S.stack and #stackItems(L, S.stack) or 0,
            S.hook and "Focus.qaButton (the real poll)" or "stand-in (the manager's own calls; the poll reads the real button)"))
        S.skip = not check(#S.run == 4, T .. "the list has four single rows in a row for the checks")
        if not S.skip then focusRow(L, S.run[1]) end
    end)
    -- 2. hold A marks the row
    step(10, function()
        if S.skip then return end
        local L = S.L
        say(T .. "hold A on " .. nm(focusedItem(L)))
        hold(L.w, "A", function()
            local sel = selOf(L)
            check(sel[S.run[1]] == true and nKeys(sel) == 1 and R.padMarkCount(L.w) == 1,
                string.format("%shold A marks the row: %s in its list's selection (the wash) %s, list count %d, padMarkCount %d",
                    T, nm(S.run[1]), tostring(sel[S.run[1]] == true), nKeys(sel), R.padMarkCount(L.w)))
            check(L.w._drawerItem == nil, T .. "with one mark the card is hidden (card on " .. nm(L.w._drawerItem) .. ")")
            letGo(L.w, "A")
        end)
    end)
    -- 3. hold A again unmarks it
    step(10, function()
        if S.skip then return end
        local L = S.L
        local it = focusedItem(L)
        if it ~= S.run[1] then say(T .. "the focus moved to " .. nm(it) .. " after the mark: back on " .. nm(S.run[1])); focusRow(L, S.run[1]) end
        hold(L.w, "A", function()
            local sel = selOf(L)
            check((not sel[S.run[1]]) and nKeys(sel) == 0 and R.padMarkCount(L.w) == 0,
                string.format("%shold A again unmarks it: in the selection %s, list count %d, padMarkCount %d",
                    T, tostring(sel[S.run[1]] == true), nKeys(sel), R.padMarkCount(L.w)))
            letGo(L.w, "A")
        end)
    end)
    -- 4. a stack header marks its stack
    step(10, function()
        if S.skip then return end
        local L = S.L
        R.padClearMarks(L.w)
        if not S.stack then say(T .. "no stack in the list: the stack check is skipped"); return end
        focusRow(L, S.stack)
    end)
    step(10, function()
        if S.skip or not S.stack then return end
        local L = S.L
        local want = stackItems(L, S.stack)
        hold(L.w, "A", function()
            local sel = selOf(L)
            local all = true
            for _, it in ipairs(want) do if not sel[it] then all = false end end
            check(all and nKeys(sel) == #want, string.format("%sa stack header marks its stack: %s x%d, %d marked, all of the stack %s (padMarkCount %d)",
                T, nm(S.stack), #want, nKeys(sel), tostring(all), R.padMarkCount(L.w)))
            letGo(L.w, "A")
            insertNext(5, function() R.padClearMarks(L.w) end)
        end)
    end)
    -- 5. the painted run: hold A, Down x3 with A held, let go, Down once more
    step(10, function()
        if S.skip then return end
        R.padClearMarks(S.L.w)
        focusRow(S.L, S.run[1])
    end)
    step(10, function()
        if S.skip then return end
        local L = S.L
        hold(L.w, "A", function()
            S.want, S.landed = {}, {}
            for _, x in ipairs(stackItems(L, S.run[1])) do S.want[x] = true end
            local function done()
                local sel = selOf(L)
                local nWant, missing = nKeys(S.want), 0
                for it in pairs(S.want) do if not sel[it] then missing = missing + 1 end end
                check(missing == 0 and nKeys(sel) == nWant and nWant >= 4,
                    string.format("%sheld A + Down x3 marks the rows passed: %d marked (want %d: %s, then %s), padMarkCount %d, card on %s",
                        T, nKeys(sel), nWant, nm(S.run[1]), table.concat(S.landed, ", "), R.padMarkCount(L.w), nm(L.w._drawerItem)))
                S.selBefore = {}
                for it in pairs(sel) do S.selBefore[it] = true end
                letGo(L.w, "A")
                insertNext(8, function()
                    down(L.w, "down")
                    local it = focusedItem(L)
                    local now = selOf(L)
                    local same = nKeys(now) == nKeys(S.selBefore)
                    for x in pairs(S.selBefore) do if not now[x] then same = false end end
                    check(same, string.format("%sletting go ends the stroke: the next Down (to %s) leaves the marks as they were (%d marked, was %d, %s)",
                        T, nm(it), nKeys(now), nKeys(S.selBefore), same and "the same rows" or "other rows"))
                end)
            end
            local function press(i)
                return function()
                    down(L.w, "down")
                    local it = focusedItem(L)
                    S.landed[#S.landed + 1] = nm(it)
                    if it then for _, x in ipairs(stackItems(L, it)) do S.want[x] = true end end
                    if i < 3 then insertNext(6, press(i + 1)) else insertNext(6, done) end
                end
            end
            insertNext(6, press(1))
        end)
    end)
    -- 6. the marks for the checks after (the run's four; padMark when the stroke left fewer than two)
    step(10, function()
        if S.skip then return end
        local L = S.L
        if nKeys(selOf(L)) < 2 then
            say(T .. "the stroke left " .. nKeys(selOf(L)) .. " marked: the four rows are marked by padMark for the checks after (focus kept)")
            R.padClearMarks(L.w)
            for _, it in ipairs(S.run) do
                local e = rowEl(L, it)
                if e and not selOf(L)[it] then R.padMark(L.w, e) end
            end
            L.w._gpPaint = nil
        end
        S.N = nKeys(selOf(L))
        focusRow(L, S.run[4])
        say(T .. S.N .. " marked; the focus on " .. nm(focusedItem(L)))
    end)
    -- 7. the card, the help line, the footer's prompts, the picture
    step(5, function()
        if S.skip then return end
        whenStill(function() S.helpLog = {}; insertNext(12, function() end) end)
    end)
    step(2, function()
        if S.skip then return end
        local L = S.L
        local w = L.w
        check(w._drawerItem == nil, string.format("%swith %d marked the card is hidden (card on %s)", T, S.N, nm(w._drawerItem)))
        local want = ZeD.tr("UI_ZeD_Inv_MarkedHelp", S.N)
        local seen, list = S.helpLog[w] or {}, {}
        for t in pairs(seen) do list[#list + 1] = "'" .. t .. "'" end
        check(seen[want] == true, T .. "the help line's words on the focused row are '" .. want .. "' (stamped: " .. (#list > 0 and table.concat(list, ", ") or "none") .. ")")
        local line, by, nP = promptsOf(w)
        check(nP == 0, T .. "and they are drawn: the footer shows the words, not prompts in their place (" .. nP .. " prompts)")
        local wantX, wantB = ZeD.tr("UI_ZeD_Inv_PromptMenuMarked"), ZeD.tr("UI_ZeD_Inv_PromptClearMarks")
        check(has(by.X, wantX), T .. "the footer's X prompt reads '" .. wantX .. "' (X: " .. join(by.X) .. ")")
        check(has(by.B, wantB), T .. "the footer's B prompt reads '" .. wantB .. "' (B: " .. join(by.B) .. ")")
        say(T .. "footer: " .. (line ~= "" and line or "no prompts"))
        local holdUse = ZeD.tr("UI_ZeD_Prompt_Hold", ZeD.tr("UI_ZeD_Prompt_Use"))
        if has(by.A, holdUse) then say(T .. "NOTE the hold-A prompt still reads '" .. holdUse .. "' (hold A marks a row now)") end
        local e = Focus.getFocusedElement(w)
        say(string.format("%sthe focused row's own fields: onCancel %s, promptX %s, promptB %s", T,
            tostring(e ~= nil and e.onCancel ~= nil), tostring(e and e.promptX), tostring(e and e.promptB)))
        shot(shotName)
    end)
    -- 8. X: the game's menu for every marked row
    step(5, function()
        if S.skip then return end
        local L = S.L
        local vm = getPlayerContextMenu and getPlayerContextMenu(pn)
        if vm and vm.clear then pcall(function() vm:clear() end) end
        local mi = R.padMarkedItems(L.w, Focus.getFocusedElement(L.w))
        S.menuN = mi and #mi or 0
        say(T .. "X on " .. nm(focusedItem(L)) .. " (" .. tap(L.w, "X") .. "); padMarkedItems gives " .. S.menuN)
    end)
    step(20, function()
        if S.skip then return end
        local names, vm, form, nT = menuRead()
        check(vm ~= nil and #names > 0, T .. "X opens the game's menu (" .. #names .. " options: " .. (#names > 0 and table.concat(names, ", ") or "none") .. ")")
        check(form ~= nil and nT == S.N, string.format("%sits %s takes all %d marked (the option's items: %s; padMarkedItems %d)",
            T, tostring(form or "Drop / Grab"), S.N, tostring(nT), S.menuN))
        menuClose(vm)
    end)
    -- 9. B clears the marks; the focus stays on the row
    step(15, function()
        if S.skip then return end
        local L = S.L
        say(T .. "marks after the menu closed: " .. nKeys(selOf(L)))
        Focus.claimFocus(L.w)
        local it = focusedItem(L)
        if it ~= S.run[4] then say(T .. "the focus after the menu: " .. nm(it) .. " (back on " .. nm(S.run[4]) .. ")"); focusRow(L, S.run[4]) end
        S.bAt = focusedItem(L)
        Focus.dispatchJoypadDown(L.w, Joypad.BButton)
    end)
    step(8, function()
        if S.skip then return end
        local L = S.L
        local n = nKeys(selOf(L))
        local it, z = focusedItem(L)
        check(n == 0 and R.padMarkCount(L.w) == 0, string.format("%sB clears the marks (%d left in the list, padMarkCount %d)", T, n, R.padMarkCount(L.w)))
        check(it ~= nil and it == S.bAt, string.format("%sand the focus stays on the same row (%s, now %s in %s)", T, nm(S.bAt), nm(it), tostring(z and z.zone)))
        if n > 0 then R.padClearMarks(L.w) end
    end)
    -- 10. tap A on a marked row: its card, and the marks go
    step(10, function()
        if S.skip then return end
        local L = S.L
        R.padClearMarks(L.w)
        for k = 1, 3 do
            local e = rowEl(L, S.run[k])
            if e and not selOf(L)[S.run[k]] then R.padMark(L.w, e) end
        end
        L.w._gpPaint = nil
        focusRow(L, S.run[2])
        say(T .. nKeys(selOf(L)) .. " marked (by padMark); tap A on " .. nm(focusedItem(L)) .. " (" .. tap(L.w, "A") .. ")")
    end)
    step(20, function()
        if S.skip then return end
        local L = S.L
        local w = L.w
        local sel = selOf(L)
        local others = nKeys(sel) - ((sel[S.run[2]] and 1) or 0)
        check(w._drawerItem == S.run[2], T .. "tap A on a marked row opens its card (card on " .. nm(w._drawerItem) .. ")")
        check(others == 0, string.format("%sand the marks go: %d other rows still marked (list count %d, padMarkCount %d)", T, others, nKeys(sel), R.padMarkCount(w)))
        local cnt = w._mainContent
        if cnt then cnt._selectedItems = {}; cnt._lastClickedItem = nil; pcall(w._updateDrawer, cnt) end
        R.padClearMarks(w)
    end)
end

-- ===================================================================== setup
step(20, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    local zl = getCell():getZombieList()
    local nz = zl:size()
    for i = nz - 1, 0, -1 do
        local z = zl:get(i)
        if z then pcall(function() z:removeFromWorld() end); pcall(function() z:removeFromSquare() end) end
    end
    p:setGodMod(true)
    say("scene: " .. nz .. " zombies removed; screen " .. SW .. "x" .. SH .. "; controller bound to player 1: " .. tostring(padBound()))
    say(S.hook and "the hold: Focus.qaButton found, the real hold is driven"
        or "the hold: NOT drivable (FocusManager reads JoypadButton.A / X:isDown each tick and keeps its hold state in locals); stand-in calls, see the header")
    sweepOldCrates()
    -- the help line's words: stamped during the draw and taken the same frame, so they are
    -- caught as they are stamped (the window's _helpText is gone by the next tick)
    S.helpSet = ZeD.Help.set
    ZeD.Help.set = function(panel, text)
        if text ~= nil then
            local ok, win = pcall(ZeD.Surface.windowOf, panel)
            if ok and win then
                local log = S.helpLog[win] or {}
                S.helpLog[win] = log
                log[tostring(text)] = true
            end
        end
        return S.helpSet(panel, text)
    end
end)
step(75, function()   -- (the World window's list looks for containers every 30 frames)
    S.crateA = buildCrate()
    S.crateB = buildCrate()
    check(S.crateA ~= nil and S.crateB ~= nil, "two crates were built beside the character (A " .. tostring(S.crateA ~= nil) .. ", B " .. tostring(S.crateB ~= nil) .. ")")
    if S.crateA then addTo(S.crateA, { "Base.Bandage", "Base.Hammer", "Base.Apple" }) end
    if S.crateB then
        addTo(S.crateB, { "Base.Apple", "Base.Bandage", "Base.Corkscrew", "Base.Eraser", "Base.Hammer", "Base.TinnedBeans",
            "Base.Tweezers", "Base.Nails", "Base.Nails", "Base.Nails" })
    end
    -- a stack of three in the main inventory (corkscrews: the QA character carries none)
    addTo(p:getInventory(), { "Base.Corkscrew", "Base.Corkscrew", "Base.Corkscrew" })
    stripTab(cw(), cw()._tabStripPanel, "loot"); stripTab(ww(), ww()._actionTabStrip, "loot")
end)

-- ===================================================================== the Character window's main list
step(30, function()
    local w = cw()
    local cur = w._containers and w._containers[w._activeContainer or 1]
    if not (cur and cur.isMain) then
        local main = elIn(w, "charContainerStrip", function(e) local c = w._containers and w._containers[e.containerIdx]; return c and c.isMain end)
        if main and main.onActivate then main.onActivate(w, main) end
        say("Character window: the main inventory put on show")
    end
    say("Character window: " .. #(w._mcSelected or {}) .. " columns open")
    S.L = { w = w, zone = "charMainInv", name = "Character main list", stackType = "Base.Corkscrew" }
    Focus.claimFocus(w)
end)
queueMarks("char", "char_marks")

-- ===================================================================== the World window: crate B as a column
step(10, function()
    S.L = nil
    local w = ww()
    if not (S.crateA and S.crateB) then say("World: the crates are missing: the World checks are skipped"); return end
    Focus.claimFocus(w)
    stripTab(w, w._actionTabStrip, "loot")
    local st = elIn(w, "worldContainerStrip", function(e) return e.inventory == S.crateA end)
    check(st ~= nil, "crate A has a stop on the World window's container strip")
    if st and st.onActivate then st.onActivate(w, st) end
end)
step(20, function()
    if not (S.crateA and S.crateB) then return end
    say("World: crate B as a column: " .. tostring(ZeD_WorldWindow.toggleColumn(S.crateB)))
end)
step(10, function() whenStill(function() end) end)
step(30, function()
    if not (S.crateA and S.crateB) then return end
    local w = ww()
    local cnt = w._mainContent
    local slot
    for k, ci in ipairs(w._mcSelected or {}) do
        local c = w._containers and w._containers[ci]
        if c and c.inventory == S.crateB then slot = k end
    end
    local cs = slot and cnt and cnt._colStates and cnt._colStates[slot]
    local colL = slot and { w = w, zone = "worldMC" .. slot, col = slot, name = "World column " .. slot .. " (crate B)", stackType = "Base.Nails" }
    if cs and cs.inventory == S.crateB and #rowsOf(colL) > 0 then
        S.col = colL
        S.main = { w = w, zone = "worldMainInv", name = "World main list" }
        local mr = rowsOf(S.main)
        local inA = 0
        for _, e in ipairs(mr) do if e.item:getContainer() == S.crateA then inA = inA + 1 end end
        say(string.format("World: column %d (crate B) %d rows; the main list %d rows, %d of them crate A's; %d column states",
            slot, #rowsOf(colL), #mr, inA, #(cnt._colStates or {})))
        S.L = S.col
    else
        say("World: no column for crate B (" .. #(w._mcSelected or {}) .. " columns): the run uses the main list with crate B on show; the column checks are skipped")
        if colOn(w, S.crateB) then ZeD_WorldWindow.toggleColumn(S.crateB) end
        local st = elIn(w, "worldContainerStrip", function(e) return e.inventory == S.crateB end)
        if st and st.onActivate then st.onActivate(w, st) end
        S.L = { w = w, zone = "worldMainInv", name = "World main list (crate B)", stackType = "Base.Nails" }
    end
    check(S.col ~= nil, "crate B opens as a column beside the main list")
    Focus.claimFocus(w)
end)
queueMarks("world", "world_marks")

-- marks in the column and in the main list stay apart
step(10, function()
    S.mi, S.ci = nil, nil
    if not (S.col and S.main) then say("apart: skipped (no column beside the main list)"); return end
    R.padClearMarks(ww())
    local mr = rowsOf(S.main)
    S.mi = mr[1] and mr[1].item
    S.ci = S.run and S.run[1]
    if not (S.mi and S.ci) then say("apart: skipped (a row is missing: main " .. nm(S.mi) .. ", column " .. nm(S.ci) .. ")"); S.mi = nil; return end
    focusRow(S.col, S.ci)
end)
step(10, function() if S.mi then hold(ww(), "A", function() letGo(ww(), "A") end) end end)
step(10, function() if S.mi then focusRow(S.main, S.mi) end end)
step(10, function() if S.mi then hold(ww(), "A", function() letGo(ww(), "A") end) end end)
step(10, function()
    if not S.mi then return end
    local w = ww()
    local csel, msel = selOf(S.col), selOf(S.main)
    check(csel[S.ci] == true and not csel[S.mi] and nKeys(csel) == 1,
        string.format("apart: the main list's mark (%s) does not show in the column (column marks %d, %s in it %s)", nm(S.mi), nKeys(csel), nm(S.ci), tostring(csel[S.ci] == true)))
    check(msel[S.mi] == true and not msel[S.ci] and nKeys(msel) == 1,
        string.format("apart: the column's mark (%s) does not show in the main list (main marks %d, %s in it %s)", nm(S.ci), nKeys(msel), nm(S.mi), tostring(msel[S.mi] == true)))
    local ca = R.padMarkedItems(w, rowEl(S.col, S.ci)) or {}
    local ma = R.padMarkedItems(w, rowEl(S.main, S.mi)) or {}
    check(#ca == 1 and ca[1] == S.ci and #ma == 1 and ma[1] == S.mi,
        string.format("apart: X's menu takes its own list's marks only (column: %d, %s; main: %d, %s)", #ca, nm(ca[1]), #ma, nm(ma[1])))
    say("apart: padMarkCount with one mark in each list: " .. R.padMarkCount(w) .. "; card on " .. nm(w._drawerItem))
    local cnt = w._mainContent
    if cnt then cnt._selectedItems = {}; cnt._lastClickedItem = nil; pcall(w._updateDrawer, cnt) end
    R.padClearMarks(w)
end)

-- hold X on a crate row: the quick use (it comes to the main inventory)
step(10, function()
    S.qu = nil
    local L = S.L
    if not L then return end
    for _, e in ipairs(rowsOf(L)) do if #stackItems(L, e.item) == 1 and e.item:getContainer() == S.crateB then S.qu = e.item end end
    if not S.qu then say("hold X: no single row of crate B: skipped"); return end
    focusRow(L, S.qu)
    say("hold X on " .. nm(focusedItem(L)) .. " in the " .. L.name)
end)
step(5, function()
    if not S.qu then return end
    local w = S.L.w
    hold(w, "X", function() letGo(w, "X"); S.quWait = 0; insertNext(10, waitQu) end)
end)

-- the band's Take with marks (single view: crate A on show, the column shut)
step(10, function()
    S.bandSkip = true
    if not (S.crateA and S.crateB) then return end
    local w = ww()
    if colOn(w, S.crateB) then ZeD_WorldWindow.toggleColumn(S.crateB) end
    local st = elIn(w, "worldContainerStrip", function(e) return e.inventory == S.crateA end)
    if st and st.onActivate then st.onActivate(w, st) end
end)
step(10, function() if S.crateA then whenStill(function() end) end end)
step(10, function()
    if not S.crateA then return end
    local w = ww()
    local M = { w = w, zone = "worldMainInv", name = "World main list (crate A)" }
    R.padClearMarks(w)
    S.bandMarked, S.bandLeft = {}, nil
    local els = {}
    for _, e in ipairs(rowsOf(M)) do
        if e.item:getContainer() == S.crateA then
            if e.item:getFullType() == "Base.Apple" then S.bandLeft = e.item else els[#els + 1] = e end
        end
    end
    if #els < 2 or not S.bandLeft then say("band: crate A's rows are not in the main list (" .. #rowsOf(M) .. " rows): skipped"); return end
    for k = 1, 2 do R.padMark(w, els[k]); S.bandMarked[k] = els[k].item end
    w._gpPaint = nil
    local stops, take = {}, nil
    local z = zoneOf(w, "worldCtl")
    for _, e in ipairs(z and z.elements or {}) do
        stops[#stops + 1] = tostring(e.id) .. " '" .. tostring(e.promptA) .. "'"
        if e.ccKey == "take" then take = e end
    end
    say("band: " .. nKeys(selOf(M)) .. " marked (by padMark: " .. nm(S.bandMarked[1]) .. ", " .. nm(S.bandMarked[2]) .. "), " .. nm(S.bandLeft) .. " not; the band's stops: " .. (#stops > 0 and table.concat(stops, ", ") or "none"))
    if not check(take ~= nil, "band: the World window's band has its Take stop (worldCtl:take)") then return end
    Focus.claimFocus(w)
    Focus.focusWhere(w, "worldCtl", function(e) return e == take end)
    say("band: A on " .. tostring(take.id) .. " (" .. tap(w, "A") .. ")")
    S.bandSkip, S.bandWait = false, 0
    insertNext(10, waitBand)
end)

-- ===================================================================== put back
step(10, function()
    if S.helpSet then ZeD.Help.set = S.helpSet; S.helpSet = nil end
    for _, w in ipairs({ cw(), ww() }) do
        if w then
            pcall(R.padClearMarks, w)
            w._gpPaint = nil
            local cnt = w._mainContent
            if cnt and w._drawerItem then cnt._selectedItems = {}; cnt._lastClickedItem = nil; pcall(w._updateDrawer, cnt) end
        end
    end
    if S.crateB and colOn(ww(), S.crateB) then ZeD_WorldWindow.toggleColumn(S.crateB) end
    for _, it in ipairs(S.added) do
        local c = it and it:getContainer()
        if c then pcall(function() c:Remove(it) end) end
        local wio = it and it.getWorldItem and it:getWorldItem()
        if wio and wio:getSquare() then pcall(function() wio:getSquare():transmitRemoveItemFromSquare(wio) end) end
    end
    for _, o in ipairs(S.crates) do
        if o:getSquare() then
            pcall(function() o:getContainer():removeAllItems() end)
            o:getSquare():transmitRemoveItemFromSquare(o)
        end
    end
    stripTab(cw(), cw()._tabStripPanel, "loot"); stripTab(ww(), ww()._actionTabStrip, "loot")
end)
step(15, function()
    local ok, e = pcall(function()
        local left = 0
        for _, it in ipairs(S.added) do if it:getContainer() then left = left + 1 end end
        local still = 0
        for _, o in ipairs(S.crates) do if o:getSquare() then still = still + 1 end end
        say(string.format("put back: crates left %d, the run's things left %d of %d, marks Char %d World %d, card Char %s World %s, World column for crate B %s, help wrapper off %s",
            still, left, #S.added, R.padMarkCount(cw()), R.padMarkCount(ww()), nm(cw()._drawerItem), nm(ww()._drawerItem),
            tostring(S.crateB ~= nil and colOn(ww(), S.crateB)), tostring(S.helpSet == nil)))
    end)
    if not ok then say("ERR put back " .. tostring(e)) end
    if S.helpSet then ZeD.Help.set = S.helpSet; S.helpSet = nil end
    if S.hook then pcall(Focus.qaButton, "A", nil); pcall(Focus.qaButton, "X", nil) end
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say(S.pass .. " passed, " .. S.fail .. " failed")
    say("DONE")
end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
say("start")
