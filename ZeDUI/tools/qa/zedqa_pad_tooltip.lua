-- ZeDUI/tools/qa/zedqa_pad_tooltip.lua  (Nov 17 2026, QA): Build's 5923be905 in the running game: on the controller
-- the item card (ZeD's loot card, ZeD.InvTip's layer) shows on the frame the pad lands on an item; it waited 400 ms
-- before (InventoryRenderer padTip's PAD_TIP_MS is gone; EquipmentTab.itemTip asks only for the focus mark,
-- Focus.restedMs ~= nil, not Focus.padRested). The other pad balloons (help words) keep Focus.PAD_TIP_MS (400).
-- No controller here: ZeD's input mode is locked to the controller (Detector.setLockedMode("gamepad")), the window
-- takes the pad (Focus.claimFocus) and the D-pad moves are ZeD's own (Focus.dispatchJoypadDir), as a press reaches
-- them; the focus marks show from the first move (the cues) while the pointer stands still.
-- What is on screen is read from the drawing itself: ZeD.Balloon.draw is wrapped for the run (put back at the end);
-- a draw from the card's layer (ZeD.InvTip._layer) is the item card, with its item; any other is a balloon.
-- Surfaces, 12 moves each, one move every 3 drawn frames:
--   char list    the Character window's inventory list (charMainInv), D-pad down
--   char grid    the same as tiles (the Inventory option on grid), a snake: right x3, down, left x3, down
--   world list   the World window's Loot list (worldMainInv) with 12 light things put on the floor beside the character
--   world grid   the same as tiles
--   equip rows   the Character window's Equipment tab, list view (charTabContent), D-pad down
--   doll boxes   the Equipment tab's doll view (charTabContent), D-pad right / down
-- Per move: the frame the card first shows (frame 1 = the first frame drawn after the move) and its item.
-- PASS when it shows the landed item by frame 2, never shows the item before after the move, and does not vanish
-- once shown before the next move. A stop with nothing on it (an empty slot): PASS when no card shows by frame 2.
-- A picture at move 6 of each surface: Screenshots/zqa_ptt_<surface>.png.
-- Then: a help-words balloon on the pad (the Character window's tab strip, charTabBar) still waits about 400 ms
-- (frames and ms logged; PASS from 300 ms up); and the pointer's card: the pointer put on a list row
-- (Mouse.setXY) shows the card at once, as before (no pad wait); if the pointer does not hold there it is "not run".
-- Puts back: the floor things gone, the views (the Inventory option and every container's own list or grid choice),
-- the equipment view, the tabs, the focus let go, the input mode unlocked (as it was), Balloon.draw, the pointer.
-- grep "ZEDQA ptt".
local S = { Q = {}, qi = 1, pass = 0, fail = 0, floor = {}, cur = {}, last = {} }
S.p = getPlayer()
S.pn = S.p:getPlayerNum()
S.CW, S.WW = ZeD_CharacterWindow, ZeD_WorldWindow
S.Focus = ZeD.Input.Focus
S.Det = ZeD.Input.Detector
S.IT = ZeD.InvTip
S.St = ZeD.Settings
function S.say(s) print("ZEDQA ptt " .. tostring(s)) end
function S.check(ok, what) if ok then S.pass = S.pass + 1 else S.fail = S.fail + 1 end; S.say((ok and "PASS " or "FAIL ") .. what); return ok end
function S.step(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end
function S.call(o, name, ...)
    if o == nil then return nil end
    local f = o[name]
    if f == nil then return nil end
    return f(o, ...)
end
function S.cw() return S.CW.getWindow(S.pn) end
function S.ww() return S.WW.getWindow(S.pn) end
function S.nm(it)
    if it == nil then return "nothing" end
    local n = S.call(it, "getDisplayName")
    return tostring(n or it)
end
function S.shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ptt_" .. n .. ".png") end); S.say("shot zqa_ptt_" .. n) end
function S.console()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end
    end
end

-- ---------------------------------------------------------------- what is drawn (one frame's draws, read next frame)
S.drawWas = ZeD.Balloon.draw
ZeD.Balloon.draw = function(p, c, a, pref, opts, ...)
    if p ~= nil and p == S.IT._layer then
        S.cur.card = (opts and opts.key) or true
    else
        S.cur.balloon = true
    end
    return S.drawWas(p, c, a, pref, opts, ...)
end

-- ---------------------------------------------------------------- one surface's run
-- m: { name, win, zone, dirs, n, gap, i, f, expect, prev, shownAt, sawPrev, lost }
function S.target(w)
    local el = S.Focus.getFocusedElement(w)
    if not el then return nil, nil end
    local it = el.item
    if it == nil and el.slotType ~= nil and type(el.slotType) == "string" and string.sub(el.slotType, 1, 2) ~= "__" then
        it = S.call(S.p, "getWornItem", el.slotType)
    end
    return el, it
end
function S.finishMove(m)
    if m.i == 0 then return end
    local ok
    if m.expect == nil then
        ok = (m.shownAt == nil or m.shownAt > 2) and not m.sawPrev
    else
        ok = m.shownAt ~= nil and m.shownAt <= 2 and not m.sawPrev and not m.lost
    end
    m.results[#m.results + 1] = ok
    S.say(string.format("%s move %d (%s) to %s: card at frame %s showing %s%s%s%s", m.name, m.i, m.dir, tostring(m.stop),
        tostring(m.shownAt or "-"), S.nm(m.shownItem), m.expect == nil and " (an empty stop)" or (" (landed on " .. S.nm(m.expect) .. ")"),
        m.sawPrev and ", SHOWED THE ITEM BEFORE" or "", m.lost and ", VANISHED" or ""))
end
function S.move(m)
    S.finishMove(m)
    if m.i >= m.n then m.done = true; return end
    m.i = m.i + 1
    m.dir = m.dirs[((m.i - 1) - math.floor((m.i - 1) / #m.dirs) * #m.dirs) + 1]
    local before = S.Focus.getFocusedElement(m.win)
    S.Focus.dispatchJoypadDir(m.win, m.dir, nil)
    local el, it = S.target(m.win)
    local z = S.Focus.getFocusedZone(m.win)
    if el == before then S.say(m.name .. " move " .. m.i .. " (" .. m.dir .. "): the focus did not move") end
    if not (z and z.zone == m.zone) then
        S.say(m.name .. " move " .. m.i .. ": the focus left " .. m.zone .. " for " .. tostring(z and z.zone) .. "; back to its first stop")
        S.Focus.focusWhere(m.win, m.zone, m.pred)
        el, it = S.target(m.win)
    end
    m.prev, m.expect = m.expect, it
    m.stop = el and tostring(el.id or el.slotType or "?") or "?"
    m.f, m.shownAt, m.shownItem, m.sawPrev, m.lost = 0, nil, nil, false, false
    if m.i == 6 then m.shotDue = true end
end
-- each drawn frame, the frame before read back
function S.watch(m, card)
    m.f = m.f + 1
    local item = (card ~= nil and card ~= true) and card or nil
    if item ~= nil and m.prev ~= nil and item == m.prev and m.prev ~= m.expect then m.sawPrev = true end
    if m.expect ~= nil then
        if item == m.expect then
            if not m.shownAt then m.shownAt, m.shownItem = m.f, item end
        elseif m.shownAt then
            m.lost = true
        end
    elseif item ~= nil and not m.shownAt then
        m.shownAt, m.shownItem = m.f, item
    end
end
function S.surface(name, win, zone, dirs, pred, setup)
    S.step(20, function()
        if setup then setup() end
    end)
    S.step(40, function()
        local w = win()
        if not w then S.say("not run: " .. name .. " (no window)"); return end
        S.Focus.claimFocus(w)
        local e = S.Focus.focusWhere(w, zone, pred)
        if not e then S.say("not run: " .. name .. " (no stop in " .. zone .. ")"); return end
        S.m = { name = name, win = w, zone = zone, dirs = dirs, n = 12, i = 0, f = 0, pred = pred, results = {} }
        S.say(name .. ": the pad on " .. zone .. ", first stop " .. tostring(e.id or e.slotType or S.nm(e.item)))
    end)
    S.step(3, function()
        local m = S.m
        if not m or m.name ~= name then return end
        if m.done then return end
        return true   -- (the driver below moves it every 3 frames; this step waits until it is done)
    end)
    S.step(2, function()
        local m = S.m
        if not (m and m.name == name) then return end
        local all = #m.results > 0
        for _, r in ipairs(m.results) do if not r then all = false end end
        S.check(all, name .. ": the card on the landed item by frame 2 on every move, no item before, no flicker (" .. #m.results .. " moves)")
        S.m = nil
    end)
end
function S.isItem(e) return e.item ~= nil end
function S.isSlot(e) return e.slotType ~= nil and string.sub(tostring(e.slotType), 1, 2) ~= "__" end
S.SNAKE = { "right", "right", "right", "down", "left", "left", "left", "down" }

-- ---------------------------------------------------------------- set up
S.step(10, function()
    S.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.console()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "ptt") end
    S.optInv = S.St.inventoryViewOption and S.St.inventoryViewOption:getValue()
    S.optEq = S.St.equipViewOption and S.St.equipViewOption:getValue()
    local g = S.p:getModData().ZeD_GridViews
    S.gridWas = {}
    if g then for k, v in pairs(g) do S.gridWas[k] = v end end
    S.p:getModData().ZeD_GridViews = {}
    S.lockWas = S.p:getModData().ZeD_Gamepad and S.p:getModData().ZeD_Gamepad.inputModeLock
    S.tabWas = S.cw() and S.cw()._activeTab
    if not S.CW.isOpen(S.pn) then S.CW.toggleBothPaired(S.pn) end
    -- 12 light things on the floor beside the character, for the World window's Loot list
    local sq = S.p:getCurrentSquare()
    for _, ft in ipairs({ "Base.Pencil", "Base.Pen", "Base.Battery", "Base.Bandage", "Base.Apple", "Base.Banana", "Base.Matches",
                          "Base.Spoon", "Base.Fork", "Base.Paperclip", "Base.Rubberband", "Base.Eraser" }) do
        local it = sq and sq:AddWorldInventoryItem(ft, 0.5, 0.5, 0)
        if it then S.floor[#S.floor + 1] = it end
    end
    S.Det.setLockedMode("gamepad")
    S.say("start at " .. math.floor(S.p:getX()) .. "," .. math.floor(S.p:getY()) .. "; floor things " .. #S.floor
        .. "; input lock was " .. tostring(S.lockWas) .. "; pad bound " .. tostring(JoypadState.players[S.pn + 1] ~= nil)
        .. "; Focus.PAD_TIP_MS " .. tostring(S.Focus.PAD_TIP_MS))
end)

S.surface("char list", S.cw, "charMainInv", { "down" }, S.isItem, function()
    S.St.inventoryViewOption:setValue(1)
    S.CW.openTab(S.pn, "loot")
end)
S.surface("char grid", S.cw, "charMainInv", S.SNAKE, S.isItem, function() S.St.inventoryViewOption:setValue(2) end)
S.surface("world list", S.ww, "worldMainInv", { "down" }, S.isItem, function()
    S.St.inventoryViewOption:setValue(1)
    S.WW.openTab(S.pn, "loot")
end)
S.surface("world grid", S.ww, "worldMainInv", S.SNAKE, S.isItem, function() S.St.inventoryViewOption:setValue(2) end)
S.surface("equip rows", S.cw, "charTabContent", { "down" }, S.isSlot, function()
    S.St.inventoryViewOption:setValue(1)
    if S.St.equipViewOption then S.St.equipViewOption:setValue(1) end
    S.CW.openTab(S.pn, "equip")
end)
S.surface("doll boxes", S.cw, "charTabContent", { "right", "down", "right", "down" }, S.isSlot, function()
    if S.St.equipViewOption then S.St.equipViewOption:setValue(2) end
end)

-- ---------------------------------------------------------------- a help-words balloon on the pad still waits
S.step(20, function()
    if S.St.equipViewOption and S.optEq then S.St.equipViewOption:setValue(S.optEq) end
    S.CW.openTab(S.pn, "loot")
    local w = S.cw()
    S.Focus.claimFocus(w)
    local e = S.Focus.focusWhere(w, "charTabBar", nil)
    S.Focus.dispatchJoypadDir(w, "right", nil)
    e = S.Focus.getFocusedElement(w)
    S.help = { t0 = getTimestampMs(), f = 0, stop = e and tostring(e.id) or "?" }
    S.say("help: the pad on the tab strip's " .. S.help.stop)
end)
S.step(1, function()
    local h = S.help
    if h.at == nil and h.f < 120 then return true end
    if h.at == nil then
        S.say("not run: help balloon (none drawn on " .. h.stop .. " in 120 frames: that stop has no help words)")
        return
    end
    S.check(h.ms >= 300, string.format("help words on the pad still wait: the balloon at frame %d, %d ms after the move (Focus.PAD_TIP_MS %s)",
        h.at, h.ms, tostring(S.Focus.PAD_TIP_MS)))
end)

-- ---------------------------------------------------------------- the pointer's card, unchanged
S.step(10, function()
    S.Focus.releaseFocus(S.pn)
    S.Det.setLockedMode(nil)
    local w = S.cw()
    local z = nil
    for _, zz in ipairs(w._focusRing or {}) do if zz.zone == "charMainInv" then z = zz end end
    local e = z and z.elements and z.elements[3]
    local pnl = z and z.panel or (w._mainContent)
    if not (e and e.x and pnl) then S.say("not run: the pointer's card (no row to point at)"); return end
    S.mouse = { x = math.floor(pnl:getAbsoluteX() + e.x + e.w / 2), y = math.floor(pnl:getAbsoluteY() + e.y + e.h / 2), item = e.item, f = 0 }
    S.mouseWas = { getMouseX(), getMouseY() }
    Mouse.setXY(S.mouse.x, S.mouse.y)
end)
S.step(1, function()
    local m = S.mouse
    if not m then return end
    if m.f == 0 then
        m.f = 1
        if math.abs(getMouseX() - m.x) > 2 or math.abs(getMouseY() - m.y) > 2 then
            S.say("not run: the pointer's card (Mouse.setXY did not hold: the pointer reads " .. getMouseX() .. "," .. getMouseY() .. ", wanted " .. m.x .. "," .. m.y .. ")")
            S.mouse = nil
            return
        end
        m.t0 = getTimestampMs()
        return true
    end
    m.f = m.f + 1
    if m.at == nil and m.f < 90 then return true end
    S.check(m.at ~= nil and m.at <= 3, string.format("the pointer's card: shows at frame %s (%s ms) on %s, as before (no pad wait)",
        tostring(m.at or "-"), tostring(m.ms or "-"), S.nm(m.item)))
end)

-- ---------------------------------------------------------------- put back
S.step(10, function()
    pcall(S.Focus.releaseFocus, S.pn)
    pcall(function()
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
    for _, it in ipairs(S.floor) do
        pcall(function()
            local wi = it:getWorldItem()
            if wi then
                local sq = wi:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wi) end
                S.call(wi, "removeFromSquare")
                S.call(wi, "removeFromWorld")
            end
        end)
    end
    pcall(function() if S.optInv then S.St.inventoryViewOption:setValue(S.optInv) end end)
    pcall(function() if S.optEq and S.St.equipViewOption then S.St.equipViewOption:setValue(S.optEq) end end)
    pcall(function() PZAPI.ModOptions:save() end)
    S.p:getModData().ZeD_GridViews = S.gridWas
    pcall(S.CW.openTab, S.pn, S.tabWas or "loot")
    pcall(S.WW.openTab, S.pn, "loot")
    if S.mouseWas then pcall(function() Mouse.setXY(S.mouseWas[1], S.mouseWas[2]) end) end
    ZeD.Balloon.draw = S.drawWas
end)
S.step(10, function()
    S.say(S.fail == 0 and ("all " .. S.pass .. " checks passed") or (S.fail .. " failed, " .. S.pass .. " passed"))
    S.say("put back: floor things gone, views and equipment view, tabs, focus, input lock " .. tostring(S.lockWas) .. ", Balloon.draw, pointer")
    S.done = true
    S.say("DONE")
end)

-- ---------------------------------------------------------------- the tick (each drawn frame)
function S.tick()
    S.last, S.cur = S.cur, {}
    local card = S.last.card
    local m = S.m
    if m and not m.done then
        if m.i > 0 then S.watch(m, card) end
        if m.shotDue and m.f == 2 then m.shotDue = false; S.shot(string.gsub(m.name, " ", "_")) end
        if m.i == 0 or m.f >= 3 then
            local ok, e = pcall(S.move, m)
            if not ok then S.say("ERR " .. m.name .. " move: " .. tostring(e)); m.done = true end
        end
    end
    local h = S.help
    if h and h.at == nil then
        h.f = h.f + 1
        if S.last.balloon then h.at, h.ms = h.f, getTimestampMs() - h.t0 end
    end
    local mo = S.mouse
    if mo and mo.t0 and mo.at == nil and card ~= nil then mo.at, mo.ms = mo.f, getTimestampMs() - mo.t0 end
    local s = S.Q[S.qi]
    if not s then
        Events.OnPreUIDraw.Remove(S.tick)
        if ZeD.Balloon.draw ~= S.drawWas then ZeD.Balloon.draw = S.drawWas end
        if not S.done then S.say("DONE") end
        return
    end
    S.wait = (S.wait or s.n) - 1
    if S.wait > 0 then return end
    S.wait = nil
    local ok, r = pcall(s.fn)
    if not ok then S.say("ERR step " .. S.qi .. ": " .. tostring(r)) end
    if ok and r == true then return end
    S.qi = S.qi + 1
end
Events.OnPreUIDraw.Add(S.tick)
S.say("start")
