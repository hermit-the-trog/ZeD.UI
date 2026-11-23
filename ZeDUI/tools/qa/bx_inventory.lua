-- ZeDUI/tools/qa/bx_inventory.lua  (Nov 21 2026, QA beast day): the inventory under stress. Click, drag, drop and
-- move, fast and in odd orders, while both windows are on Loot: InventoryRenderer.handleDrop and the windows' own
-- press and release handlers, the container strips, WindowHalves / WindowCurtain (the roll-ups), the World window's
-- watch on the game's loot page (a click on a container in the world), EquipDoll.takeDrop, ZeD.Belt.takeDrop.
-- On the drag strip three crates stand beside the character (A: five bandages, three planks, one kitchen thing;
-- B: twine, rope, a saucepan; C: empty); a kitchen thing, a tool and a cap are given to the bag.
--   1. the lists draw what the containers hold (the base line);
--   2. a stack: one thing dragged out of the open stack (the split), then the closed stack's row (all of it);
--   3. two rows picked with Ctrl, dragged as one;
--   4. fifty drags in a row, bag to crate and back, every other frame, every fifth one twice in the same frame;
--   5. Loot all and Transfer all at their real length, cut short: both windows shut mid-transfer and opened again,
--      the World window rolled up, the queue cleared (nothing lost, the lists agree with the containers);
--   6. the player reports: a left click on a crate in the world (the game's own click handler) with both windows
--      shut, the World window rolled up, its inventory side rolled under its tab (as it starts to roll, and once it
--      has), the game paused, Loot columns open: ZeD opens on that crate and the game's own pages are never drawn;
--      two clicks two frames apart;
--   7. eighteen container switches two frames apart (the list never draws another container's things, the drop
--      target is the container shown), a late request that must not win over a newer one, eleven presses on the
--      strip's buttons (columns), the empty crate (zero, one, zero);
--   8. the roll-ups under a drag: a thing dragged from the crate over the rolled-up Character window (its title
--      bar, then its inventory side's tab) rolls it down and lands in the inventory; a drag released on the World
--      window in the frame it rolls up; a window rolled up under its own drag, then a right press;
--   9. a crate taken away mid-drag, as the drop's target and as its source;
--  10. the belt (the main hand, an empty slot) and the Equip tab's doll (worn by a drop, dragged off into a crate);
--  11. bags: a full bag takes nothing, a bag with a thing in it goes into the equipped bag, the equipped bag is
--      dropped with all of it and picked up again;
--  12. a pickup's bed: in and out, then the car taken away while its bed shows.
-- The pointer's place is the one thing faked (the target answers "the pointer is over me", or getMouseX / getMouseY
-- answer a spot for the call; a drag held over a rolled window keeps them faked for a second). Everything is put
-- back, and the last line says the character is whole (nothing here is meant to hurt him; god mode and invincible are
-- turned on at the start and left on). Copy to Zomboid/Lua/ after zedqa_prelude.lua and rt_kit.lua; grep "ZEDQA bx_inv".

local Q = RT.make("bx_inv")
Q.maxMs = 420000   -- (the budget is 8 minutes: past 7 the run jumps to the put-back)
local S = { p = RT.p, pn = RT.pn, made = {}, crates = {}, grid = {}, errs = 0, dead = false }
local H = {}
local NIL = {}

local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
local function waitFor(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end

-- ===================================================================== small helpers
function H.cc() local w = RT.cw(); return w and w._mainContent end
function H.wc() local w = RT.ww(); return w and w._mainContent end
function H.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function H.list(inv)
    local out = {}
    pcall(function()
        local it = inv:getItems()
        for i = 0, it:size() - 1 do out[#out + 1] = it:get(i) end
    end)
    return out
end
function H.size(inv) local n = -1; pcall(function() n = inv:getItems():size() end); return n end
function H.where(it) local c = nil; pcall(function() c = it:getContainer() end); return c end
function H.typeOf(inv)
    if inv == nil then return "nothing" end   -- (never an index of nil: with -debug the game logs even a caught one)
    local t = "nothing"; pcall(function() t = tostring(inv:getType()) end); return t
end
-- a container by the test's own name (every crate's type reads "crate": a line must say which one)
function H.nameOf(inv)
    if inv == nil then return "nothing" end
    if inv == S.bag then return "the bag" end
    for _, k in ipairs({ "A", "B", "C", "D" }) do
        local c = S[k]
        if c and c.inv == inv then return "crate " .. k end
    end
    return H.typeOf(inv)
end
function H.queueLen()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue and #q.queue) or 0
end
function H.queueEmpty() return H.queueLen() == 0 end
function H.held(it)
    local h = false
    pcall(function() h = it:isEquipped() or S.p:isEquipped(it) end)
    return h and true or false
end
function H.room(inv, it)
    local r = true
    pcall(function() r = inv:hasRoomFor(S.p, it) end)
    return r and true or false
end
function H.onFloor(it) local wo = nil; pcall(function() wo = it:getWorldItem() end); return wo ~= nil end
function H.count(inv, list)
    local n = 0
    for _, it in ipairs(list or {}) do if H.where(it) == inv then n = n + 1 end end
    return n
end
function H.zone(c, id)
    for _, z in ipairs(c and c._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function H.click(c, z)
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
end
-- ZeD's code under test: an error is a FAIL line and the script goes on
function H.try(what, fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; Q.check(false, what .. ": ran without an error", tostring(err)) end
    return ok
end
function H.dirty()
    pcall(function() ZeD.InventoryRenderer.dirtyModels() end)
    pcall(function() ISInventoryPage.dirtyUI() end)
end
-- a thing off the character and out of the world, wherever it is
function H.loose(it)
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    pcall(function()
        if (it:getAttachedSlot() or -1) > -1 then
            S.p:removeAttachedItem(it)
            it:setAttachedSlot(-1)
        end
    end)
end
function H.removeItem(it)
    H.loose(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            -- (the thing forgets its world object, as the game's own pickup does: ISGrabItemAction, ISTransferAction.
            -- Left set, a thing put back in the bag by hand still read as "on the floor" for the rest of the run)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
-- the character's state, for the put-back's last line: nil when he is whole, else what is wrong
function H.hurt()
    local why = {}
    local ok, err = pcall(function()
        if S.p:isDead() then why[#why + 1] = "dead" end
        local bd = S.p:getBodyDamage()
        local hp = bd:getOverallBodyHealth()
        if hp < 99.9 then why[#why + 1] = "health " .. string.format("%.1f", hp) end
        if bd:IsInfected() then why[#why + 1] = "infected" end
        local parts = bd:getBodyParts()
        local wounds, breaks = 0, 0
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            if bp:HasInjury() then wounds = wounds + 1 end
            if bp:getFractureTime() > 0 then breaks = breaks + 1 end
        end
        if wounds > 0 then why[#why + 1] = wounds .. " wounded parts" end
        if breaks > 0 then why[#why + 1] = breaks .. " fractures" end
    end)
    if not ok then why[#why + 1] = "his health could not be read: " .. tostring(err) end
    if #why == 0 then return nil end
    return table.concat(why, ", ")
end
-- nothing here is meant to hurt him; god mode and invincible are on all the same (left on: the prelude's rule)
function H.guard()
    pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true) end end)
    pcall(function() if not S.p:isInvincible() then S.p:setInvincible(true) end end)
end
-- staging by hand: a thing made in a container (remembered, taken away at the end), a thing set in a container
function H.add(inv, ft)
    local it = nil
    pcall(function() it = inv:AddItem(ft) end)
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        S.made[#S.made + 1] = it
    end
    return it
end
function H.put(it, inv)
    if not (it and inv) then return end
    if H.where(it) == inv and not H.onFloor(it) and not H.held(it) then return end
    H.removeItem(it)
    pcall(function() inv:AddItem(it) end)
    H.dirty()
end
-- the first kind of the list the character does not carry (so its row is its own), made in inv
function H.addUnique(inv, kinds)
    local own = S.p:getInventory()
    for _, ft in ipairs(kinds) do
        local have = true
        pcall(function() have = own:getCountTypeRecurse(ft) > 0 end)
        if not have and not S.usedKind[ft] then
            local it = H.add(inv, ft)
            if it then S.usedKind[ft] = true; return it end
        end
    end
    return nil
end
function H.pause(on)
    S.pausedByMe = on and true or nil
    local sp = on and 0 or 1
    pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(sp) end)
    if ZEDQA_SPEED then pcall(ZEDQA_SPEED, sp) else pcall(setGameSpeed, sp) end
end
function H.padBound()
    local jp = JoypadState and JoypadState.players and JoypadState.players[S.pn + 1]
    return jp ~= nil
end
function H.instant(on) pcall(function() S.p:setTimedActionInstantCheat(on and true or false) end) end

-- ===================================================================== what a list shows
-- the things a list of inv should show: not hidden, and in the character's own inventory not worn or held
function H.expected(inv)
    local set, n = {}, 0
    local isP = inv == S.p:getInventory()
    for _, it in ipairs(H.list(inv)) do
        local hidden = false
        pcall(function() hidden = it:isHidden() end)
        if not hidden and not (isP and H.held(it)) then set[it] = true; n = n + 1 end
    end
    return set, n
end
-- every shown thing has a drawn row or cell, a closed stack's row standing for its whole stack; nothing extra
function H.drawn(c)
    if not (c and c._inventory) then return false, "no list" end
    local exp, n = H.expected(c._inventory)
    local seen, covered, extra, unplaced, rows = {}, 0, 0, 0, 0
    local map = (c._gridCell ~= nil) and c._itemRenderXMap or c._itemRenderYMap
    for _, it in ipairs(c._flatItems or {}) do
        rows = rows + 1
        if not (map and map[it]) then unplaced = unplaced + 1 end
        local st = c._stacks and c._stacks[it]
        local list = (st and st.items) or { it }
        for _, x in ipairs(list) do
            if exp[x] and not seen[x] then seen[x] = true; covered = covered + 1 else extra = extra + 1 end
        end
    end
    local ok = unplaced == 0 and covered == n and extra == 0
    return ok, string.format("%d rows, %d of %d things drawn, %d rows with no place, %d extra", rows, covered, n, unplaced, extra)
end
-- rows that are not the shown container's own (a row left from another container); the rows counted
function H.stale(c)
    local inv = c and c._inventory
    if not inv then return 0, 0 end
    local floor = H.typeOf(inv) == "floor"
    local bad, n = 0, 0
    for _, it in ipairs(c._flatItems or {}) do
        n = n + 1
        local cont = H.where(it)
        local ok = cont == inv
        if not ok and floor and cont then ok = H.typeOf(cont) == "floor" end
        if not ok then bad = bad + 1 end
    end
    return bad, n
end
function H.inRows(c, item)
    for _, it in ipairs(c and c._flatItems or {}) do
        if it == item then return true end
        local st = c._stacks and c._stacks[it]
        for _, x in ipairs((st and st.items) or {}) do if x == item then return true end end
    end
    return false
end
-- the row that stands for a kind's stack
function H.rep(c, key)
    for _, it in ipairs(c and c._flatItems or {}) do
        local st = c._stacks and c._stacks[it]
        if st and st.key == key and not (c._childParent and c._childParent[it]) then return it end
    end
    return nil
end
function H.listed(win, inv)
    for _, e in ipairs((win and win._containers) or {}) do if e.inventory == inv then return true end end
    return false
end
-- the container the World window's one list stands for (no columns): what its title and rows are for
function H.viewInv()
    local ww = RT.ww()
    if not ww or #(ww._mcSelected or {}) > 0 then return nil end
    local e = ww._containers and ww._containers[ww._viewedContainer or ww._activeContainer]
    return e and e.inventory
end
-- scroll the list so item's row sits a third of the way down (rt_inventory.lua's reveal)
function H.reveal(c, item)
    local s = c and c._scroll
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not (s and y) then return end
    if not (s.visible and s.barSizeRatio and s.barSizeRatio > 0 and s.barSizeRatio < 1) then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    pcall(function() s:setScrollPos(math.max(0, math.min(1, (logical - math.floor(vis / 3)) / range))) end)
end
function H.clearSel(c)
    if not c then return end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    -- (every column's picks too, as ZeD's own clear does, InventoryRenderer.padClearMarksOf: the band reads them all)
    for _, cs in ipairs(c._colStates or {}) do
        local t = cs.selectedItems or {}
        for k in pairs(t) do t[k] = nil end
        cs.lastClickedItem = nil
    end
    c._lastClickedItem = nil
    c._padMarks = nil
end
-- picks a list keeps on things it no longer holds (the game's own list lets go of its picks on a release outside it,
-- ISInventoryPane:onMouseUpOutside, and its refresh keeps only the picks it still holds)
function H.strayPicks(c)
    local n = 0
    local inv = c and c._inventory
    for it in pairs((c and c._selectedItems) or {}) do
        if H.where(it) ~= inv then n = n + 1 end
    end
    return n
end
-- the word on a list's band button (id "take", "xfer"), as the band last laid it out
function H.bandWord(c, id)
    for _, h in ipairs((c and c._cc and c._cc.hits) or {}) do
        if h.spec and h.spec.id == id then return tostring(h.spec.label) end
    end
    -- (branch listgrid, Nov 22 2026: the World band holds Take all again; a Loot column's is in its own foot)
    if id == "take" and c ~= nil and c._colStates ~= nil and #c._colStates > 0 then return "no button (Loot columns: each column's foot)" end
    return "no button"
end

-- ===================================================================== the pointer (the one thing faked)
function H.withGlobals(over, fn)
    local was = {}
    for k, v in pairs(over) do was[k] = _G[k]; _G[k] = v end
    local ok, err = pcall(fn)
    for k, v in pairs(was) do _G[k] = v end
    return ok, err
end
-- getMouseX / getMouseY answer one spot until fakeOff (a drag held over a rolled-up window for a second)
function H.fakeOn(x, y)
    if not S.fake then S.fake = { getMouseX, getMouseY } end
    getMouseX = function() return x end
    getMouseY = function() return y end
end
function H.fakeOff()
    if S.fake then getMouseX, getMouseY = S.fake[1], S.fake[2]; S.fake = nil end
end
function H.hud()
    local h = nil
    pcall(function() h = ZeD.Belt.getHUD(S.pn) end)
    return h
end
-- run fn with every drop target answering "the pointer is not over me", but target (a list or a strip); the belt
-- answers "not over me" too unless it is the target. extra: more answers, { object, key, function }.
function H.over(target, fn, extra)
    local saved = {}
    local function set(o, k, v) saved[#saved + 1] = { o, k, rawget(o, k) }; o[k] = v end
    local cw, ww = RT.cw(), RT.ww()
    local panels = {}
    if cw and cw._mainContent then panels[#panels + 1] = cw._mainContent end
    if ww and ww._mainContent then panels[#panels + 1] = ww._mainContent end
    if cw and cw._containerStrip then panels[#panels + 1] = cw._containerStrip end
    if ww and ww._containerStrip then panels[#panels + 1] = ww._containerStrip end
    for _, o in ipairs(panels) do
        local on = o == target
        set(o, "isMouseOver", function() return on end)
    end
    local hud = H.hud()
    if hud and hud ~= target then set(hud, "getMouseX", function() return -1 end) end
    for _, e in ipairs(extra or {}) do set(e[1], e[2], e[3]) end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do local s = saved[i]; s[1][s[2]] = s[3] end
    return ok, err
end
function H.at(o, x, y)
    return { { o, "getMouseX", function() return x end }, { o, "getMouseY", function() return y end } }
end
-- a container's button on a window's strip: the strip, the answers that put the pointer on it, its zone
function H.stripAt(win, inv)
    local strip = win and win._containerStrip
    if not strip then return nil end
    local idx, main = nil, false
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then idx = i; main = c.isMain and true or false end
    end
    if not idx then return nil end
    for _, z in ipairs(strip._hitZones or {}) do
        if z.id == idx or z.id == ("cnt:" .. idx) or (main and z.id == "main_toggle") then
            return strip, H.at(strip, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)), z
        end
    end
    return nil
end
-- a spot on win's title bar that is not over the other window
function H.barPoint(win, other)
    if not win then return nil end
    local y = win:getAbsoluteY() + math.floor(win:titleBarHeight() / 2)
    for _, f in ipairs({ 0.5, 0.25, 0.75, 0.1, 0.9 }) do
        local x = win:getAbsoluteX() + math.floor(win:getWidth() * f)
        local hit = false
        if other then
            local dx, dy = x - other:getAbsoluteX(), y - other:getAbsoluteY()
            hit = dx >= 0 and dx <= other:getWidth() and dy >= 0 and dy <= other:shownHeight()
        end
        if not hit then return x, y end
    end
    return nil
end

-- ===================================================================== drag
-- the press on a row and the move past the drag threshold (the list's own handlers); the drag is then in the air
function H.grab(src, item)
    local z = H.zone(src, item)
    if not z then return false, "the row is not on screen" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    src._zedLastClick = nil   -- (never a double-click: that would be the quick use)
    local okD, errD = pcall(function() src:onMouseDown(x, y) end)
    if not okD then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(errD) end
    local d = src._drag
    if not (d and d:isPending()) then return false, "the press began no drag" end
    d:checkThreshold(d.startX + 40, d.startY + 40)
    if not d:isActive() then pcall(function() d:cancel() end); return false, "the drag did not start" end
    S.grabAt = { x, y }
    return true, "in the air"
end
-- the release away from the source list, with target answering "the pointer is over me"
function H.let(src, target, extra)
    local g = S.grabAt or { 0, 0 }
    local ok, err = H.over(target, function() src:onMouseUpOutside(g[1], g[2]) end, extra)
    if not ok then S.errs = S.errs + 1 end
    return ok, ok and "dropped" or ("the release threw: " .. tostring(err))
end
function H.drag(src, item, target, extra)
    local ok, why = H.grab(src, item)
    if not ok then return false, why end
    return H.let(src, target, extra)
end
function H.dragIdle(c)
    local d = c and c._drag
    return not d or not (d:isActive() or d:isPending())
end
function H.cancelDrags()
    for _, c in ipairs({ H.cc(), H.wc() }) do
        pcall(function() if not H.dragIdle(c) then c._drag:cancel(); c:setCapture(false) end end)
    end
    pcall(function() local cw = RT.cw(); if cw and cw._equipDrag then cw._equipDrag:cancel() end; if cw then cw._equipPress = nil end end)
    pcall(function() ISMouseDrag.dragging = nil end)
end
-- a click with Ctrl or Shift (the list's own press reads them from isCtrlKeyDown / isShiftKeyDown)
function H.clickMods(c, item, ctrl, shift)
    local z = H.zone(c, item)
    if not z then return false end
    c._zedLastClick = nil
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ok = H.withGlobals({ isCtrlKeyDown = function() return ctrl end, isShiftKeyDown = function() return shift end }, function()
        c:onMouseDown(x, y)
        c:onMouseUp(x, y)
    end)
    return ok
end

-- ===================================================================== the container buttons
function H.press(c, id)
    local cc = c and c._cc
    for i, h in ipairs(cc and cc.hits or {}) do
        if h.spec and h.spec.id == id then
            if not h.spec.enabled then return false, tostring(h.spec.label) .. " is off" end
            local z = H.zone(c, "cc:" .. i)
            local ok, err = pcall(function()
                if z and z.w > 0 then c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
                else ZeD.ContainerControls.press(c, i) end
            end)
            if not ok then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(err), true end
            return true, tostring(h.spec.label)
        end
    end
    -- (QA, Nov 22 2026, refit for branch listgrid 1916f88ab, the director's "Transfer buttons, always in the footer":
    -- the World band's Take all ("take") is back and pressed above. view:lootall:<key> is now a Loot column's own
    -- foot, so it stands in only while the list is in Loot columns (content._colStates); a single list with no band
    -- Take all is "no button take".)
    if id == "take" and c ~= nil and c._colStates ~= nil and #c._colStates > 0 then
        for _, z in ipairs((c and c._hitZones) or {}) do
            if type(z.id) == "string" and z.id:sub(1, 13) == "view:lootall:" then
                -- (off as the band's was off: nothing wanted to take)
                local on = true
                pcall(function() on = ZeD.ContainerControls.headLootEnabled(c) and true or false end)
                if not on then return false, "Loot all (the column's foot) is off" end
                local ok, err = pcall(function()
                    if z.w > 0 then c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
                    else ZeD.InventoryRenderer.onViewZone(z.id, c) end
                end)
                if not ok then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(err), true end
                return true, "Loot all (the column's foot)"
            end
        end
        return false, "no button take, no Loot all in the columns' feet"
    end
    return false, "no button " .. id
end
-- the bag's own things back in the bag (a Transfer all took them)
function H.restoreBag()
    local back = 0
    for _, it in ipairs(S.bagOrig or {}) do
        if H.where(it) ~= S.bag and not H.held(it) then
            H.removeItem(it)
            pcall(function() S.bag:AddItem(it) end)
            back = back + 1
        end
    end
    if back > 0 then H.dirty() end
    return back
end

-- ===================================================================== windows: pins, rolls, the pair
function H.pins(win)
    local s = win and win._halves
    if s then return { inv = s.inv.pinned and true or false, drawer = s.drawer.pinned and true or false } end
    local on = win ~= nil and win.pinned == true
    return { inv = on, drawer = on }
end
function H.setPins(win, inv, drawer)
    if not win then return end
    if win._halves and ZeD.Halves and ZeD.Halves.setPin then
        pcall(ZeD.Halves.setPin, win, "inv", inv)
        pcall(ZeD.Halves.setPin, win, "drawer", drawer)
    else
        win.pinned = (inv and drawer) and true or false
    end
end
function H.pinsBack()
    if not S.pins then return end
    local cw, ww = RT.cw(), RT.ww()
    if cw and S.pins.c then H.setPins(cw, S.pins.c.inv, S.pins.c.drawer) end
    if ww and S.pins.w then H.setPins(ww, S.pins.w.inv, S.pins.w.drawer) end
end
-- a window rolled up the way the pointer's leaving rolls it (unpinned first, or it would not count as its own roll)
function H.rollUp(win)
    H.setPins(win, false, false)
    win._autoShaded = true
    return H.try("the window rolls up to its title bar", function() win:setWindowShaded(true) end)
end
-- everything down again: the shade, the curtain, the halves
function H.down(win)
    if not win then return end
    pcall(function() if win.windowShaded then win._autoShaded = false; win:setWindowShaded(false) end end)
    pcall(function()
        local s = win._halves
        if s then s.inv.rolled, s.inv.hand, s.inv.out, s.drawer.rolled = false, false, nil, false end
    end)
    pcall(function() if win._rolled then ZeD.Curtain.finishUnroll(win) end end)
end
function H.shutBoth()
    if RT.isOpen() then H.try("the Character window shuts", function() ZeD_CharacterWindow.toggle(S.pn) end) end
    if H.worldOpen() then H.try("the World window shuts", function() ZeD_WorldWindow.close(S.pn) end) end
end
function H.openBoth()
    if not (RT.isOpen() and H.worldOpen()) then
        H.try("the pair opens", function() ZeD_CharacterWindow.toggleBothPaired(S.pn) end)
    end
end
function H.lootTabs()
    RT.charTab("loot")
    if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
end
function H.show(inv) if inv then pcall(ZeD_WorldWindow.selectContainer, inv, 200, S.pn) end end
function H.shows(inv) local wc = H.wc(); return wc ~= nil and wc._inventory == inv end
-- queue: the World window on a container, said only when it does not get there
function H.qShow(getInv, what)
    step(4, function() H.show(getInv()) end)
    waitFor(4, 300, function() local inv = getInv(); return inv == nil or H.shows(inv) end, function(ok)
        local inv = getInv()
        if inv and not ok then
            Q.check(false, "the World window shows " .. what .. " when asked (selectContainer)", "it shows " .. H.nameOf(H.wc() and H.wc()._inventory))
        end
    end)
end

-- ===================================================================== crates
function H.mkCrate(sq)
    local c = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        local inv = o:getContainer()
        if inv then
            pcall(function() inv:setExplored(true) end)
            c = { obj = o, inv = inv, sq = sq }
        end
    end)
    return c
end
function H.rmCrate(c)
    if not (c and c.obj) then return end
    pcall(function()
        local sq = c.obj:getSquare() or c.sq
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(c.obj) end); sq:RemoveTileObject(c.obj) end
    end)
    c.obj = nil
    c.gone = true
    pcall(function() RT.ww()._containerTimer = 30 end)
end

-- ===================================================================== the game's own pages, watched
-- (a draw of the game's loot or inventory page is the "vanilla flash": each page's prerender counted)
function H.vanHook()
    if S.van then return end
    S.van = { n = 0, list = {} }
    local function hook(pg)
        if not pg then return end
        local had = rawget(pg, "prerender")
        local base = pg.prerender
        if not base then return end
        pg.prerender = function(self) S.van.n = S.van.n + 1; return base(self) end
        S.van.list[#S.van.list + 1] = { pg, had }
    end
    pcall(function() hook(getPlayerLoot(S.pn)) end)
    pcall(function() hook(getPlayerInventory(S.pn)) end)
end
function H.vanUnhook()
    if not S.van then return end
    for _, e in ipairs(S.van.list) do e[1].prerender = e[2] end
    S.van = nil
end
function H.vanShowing()
    local v = false
    pcall(function() v = getPlayerLoot(S.pn):getIsVisible() or getPlayerInventory(S.pn):getIsVisible() end)
    return v and true or false
end
-- a left click on an object in the world, as the game hands it on: its click handler's press and release, on the
-- game's tick (a real click comes before the tick's watch and the frame's draw; a click from this script's own
-- frame hook would come after ZeD's last look and draw the page by the test's doing)
function H.clickOn(obj, inv)
    local c = { done = false }
    S.click = c
    S.clickN = (S.clickN or 0) + 1
    local n = S.clickN
    local ev = Events.OnTickEvenPaused or Events.OnTick
    local function go()
        ev.Remove(go)
        local vl = nil
        pcall(function() vl = getPlayerLoot(S.pn) end)
        local ok, err = pcall(function()
            local Hd = ISObjectClickHandler
            Hd.lastClickTime = nil   -- (never the second half of a double-click)
            Hd.onObjectLeftMouseButtonDown(obj, 40 * n, 40)
            Hd.onObjectLeftMouseButtonUp(obj, 40 * n, 40)
        end)
        local asked = false
        pcall(function() asked = vl:getIsVisible() and vl.inventory == inv end)
        c.how = "the game's click handler"
        if not asked then
            c.how = "the loot page's own calls (the click handler did not ask" .. (ok and "" or (": " .. tostring(err))) .. ")"
            pcall(function() vl:setNewContainer(inv); vl:setVisible(true) end)
        end
        c.done = true
    end
    ev.Add(go)
end

-- ===================================================================== the drawn list, looked at after every draw
-- S.st.want: the container asked for. Counted, after each frame's draw, while the one list is on show:
--   stale  frames the list is on that container and holds a row of another;
--   mis    frames the list's drop target is that container while the window's view is another;
--   back   frames the list left that container again after it had shown it.
function H.want(inv)
    S.st = S.st or { stale = 0, mis = 0, back = 0, frames = 0 }
    S.st.want = inv
    S.st.seen = false
end
function H.sample1()
    local st = S.st
    if not (st and st.want) then return end
    local ww = RT.ww()
    local wc = ww and ww._mainContent
    if not wc or ww.windowShaded or ww._rolled or #(ww._mcSelected or {}) > 0 then return end
    if not wc:isReallyVisible() then return end
    st.frames = st.frames + 1
    if wc._inventory == st.want then
        st.seen = true
        local bad = H.stale(wc)
        if bad > 0 then st.stale = st.stale + 1 end
        local view = H.viewInv()
        if view ~= nil and view ~= st.want then st.mis = st.mis + 1 end
    elseif st.seen then
        st.back = st.back + 1
    end
end
function H.sample() pcall(H.sample1) end
function H.stLine()
    local st = S.st or { stale = 0, mis = 0, back = 0, frames = 0 }
    return string.format("%d frames looked at: %d with another container's rows, %d with the drop target off the view, %d gone back",
        st.frames, st.stale, st.mis, st.back)
end

-- ===================================================================== setup
Q.step(1, function()
    S.pairWas = RT.isOpen()
    S.worldWas = H.worldOpen()
    S.usedKind = {}
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_inv") end
    local deadNow = true
    pcall(function() deadNow = S.p:isDead() end)
    if not Q.check(not deadNow, "the character is alive") then S.dead = true; return end
    H.guard()
    H.openBoth()
    pcall(function() S.instWas = S.p:isTimedActionInstantCheat() end)
    S.handWas = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
    S.worn = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            S.worn[#S.worn + 1] = { loc = w:getLocation(), item = w:getItem() }
        end
    end)
    H.instant(true)
    if Events.OnPostUIDraw then Events.OnPostUIDraw.Add(H.sample); S.sampling = true end
end)
step(30, function()
    local cw, ww = RT.cw(), RT.ww()
    if not Q.check(cw ~= nil and ww ~= nil, "both windows are open") then S.dead = true; return end
    S.pins = { c = H.pins(cw), w = H.pins(ww) }
    H.setPins(cw, true, true)
    H.setPins(ww, true, true)
    H.down(cw)
    H.down(ww)
    S.charTabWas, S.worldTabWas = cw._activeTab, ww._activeTab
    S.charCols, S.worldCols = {}, {}
    for _, j in ipairs(cw._mcSelected or {}) do local e = cw._containers[j]; if e then S.charCols[#S.charCols + 1] = e.inventory end end
    for _, j in ipairs(ww._mcSelected or {}) do local e = ww._containers[j]; if e then S.worldCols[#S.worldCols + 1] = e.inventory end end
    if #S.charCols > 0 then pcall(ZeD_CharacterWindow.closeColumns, cw) end
    if #S.worldCols > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
    H.lootTabs()
end)
-- the crates: the first free squares round the character (three crates, a fourth square kept for a late one)
function H.stageCrates()
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local free = {}
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x + d[1], y + d[2], z)
        local ok = sq ~= nil
        if sq then pcall(function() ok = sq:isFree(false) end) end
        if ok then free[#free + 1] = sq end
    end
    for i = 1, 3 do
        if free[i] then S.crates[#S.crates + 1] = H.mkCrate(free[i]) end
    end
    S.spareSq = free[4]
    S.A, S.B, S.C = S.crates[1], S.crates[2], S.crates[3]
    return #S.crates
end
function H.stageThings()
    S.band, S.planks = {}, {}
    for _ = 1, 5 do S.band[#S.band + 1] = H.add(S.A.inv, "Base.Bandage") end
    for _ = 1, 3 do S.planks[#S.planks + 1] = H.add(S.A.inv, "Base.Plank") end
    S.twine = H.add(S.B.inv, "Base.Twine")
    S.rope = H.add(S.B.inv, "Base.Rope")
    S.pan = H.add(S.B.inv, "Base.Saucepan")
    local kitchen = { "Base.Spoon", "Base.Fork", "Base.Spatula", "Base.Ladle", "Base.RollingPin", "Base.Kettle", "Base.Pan" }
    S.mover = H.addUnique(S.bag, kitchen)
    S.loot = H.addUnique(S.A.inv, kitchen)
    S.tool = H.addUnique(S.bag, { "Base.Hammer", "Base.Screwdriver", "Base.Wrench", "Base.Saw", "Base.Crowbar" })
    S.cap = H.addUnique(S.bag, { "Base.Hat_BaseballCapBlue", "Base.Hat_BaseballCapGreen", "Base.Hat_BaseballCapRed", "Base.Hat_Beany" })
    H.dirty()
    return #S.band == 5 and #S.planks == 3 and S.twine ~= nil and S.rope ~= nil and S.mover ~= nil and S.loot ~= nil
end
step(20, function()
    local cc, wc = H.cc(), H.wc()
    S.bag = cc and cc._inventory
    if not Q.check(S.bag ~= nil and S.bag == S.p:getInventory(), "the Character window lists the character's inventory",
        H.typeOf(S.bag)) then S.dead = true; return end
    S.worldInvWas = wc and wc._inventory
    S.bagOrig = H.list(S.bag)
    local n = 0
    pcall(function() n = H.stageCrates() end)
    if not Q.check(n == 3, "three crates stand beside the character", n .. " of 3 made") then S.dead = true; return end
    local okT = false
    pcall(function() okT = H.stageThings() end)
    if not Q.check(okT, "the things for the test were made",
        "bandages " .. #(S.band or {}) .. ", planks " .. #(S.planks or {}) .. ", mover " .. tostring(S.mover and S.mover:getFullType())
        .. ", loot " .. tostring(S.loot and S.loot:getFullType()) .. ", tool " .. tostring(S.tool and S.tool:getFullType())
        .. ", cap " .. tostring(S.cap and S.cap:getFullType())) then S.dead = true; return end
    -- every container of the test as a list (the grid choice of each kept as found)
    local st = S.p:getModData().ZeD_GridViews or {}
    S.p:getModData().ZeD_GridViews = st
    for _, inv in ipairs({ S.bag, S.A.inv, S.B.inv, S.C.inv }) do
        local key = nil
        pcall(function() key = ZeD.InventoryRenderer.containerKey(inv, S.p) end)
        if key and S.grid[key] == nil then
            S.grid[key] = (st[key] == nil) and NIL or st[key]
            pcall(function() ZeD.InventoryRenderer.setGridKey(key, false, S.p) end)
        end
    end
    H.show(S.A.inv)
end)
waitFor(10, 600, function()
    local wc = H.wc()
    return wc ~= nil and wc._inventory == S.A.inv and #(wc._flatItems or {}) > 0
end, function(ok)
    if not Q.check(ok, "the World window shows crate A (selectContainer)", H.nameOf(H.wc() and H.wc()._inventory)) then S.dead = true end
end)

-- ===================================================================== 1. the base line
step(6, function()
    local okC, whyC = H.drawn(H.cc())
    local okW, whyW = H.drawn(H.wc())
    Q.check(okC, "the bag's list draws every thing the inventory holds", whyC)
    Q.check(okW, "the crate's list draws every thing the crate holds", whyW)
    RT.bounds(Q, "both windows on Loot")
end)

-- ===================================================================== 2. a stack: one out of it, then all of it
S.bandKey = "Base.Bandage"
step(3, function()
    local wc = H.wc()
    if wc._expandedStacks then wc._expandedStacks[S.bandKey] = nil end
    H.reveal(wc, H.rep(wc, S.bandKey))
end)
step(5, function()
    local wc = H.wc()
    local z = H.zone(wc, "stack:" .. S.bandKey)
    S.split = z ~= nil
    if not Q.check(S.split, "the crate's five bandages stand as one stack with its triangle") then return end
    H.try("a press on the stack's triangle", function() H.click(wc, z) end)
end)
step(6, function()
    if not S.split then return end
    local wc = H.wc()
    local kid, kids = nil, 0
    for _, it in ipairs(wc._flatItems or {}) do
        local par = wc._childParent and wc._childParent[it]
        if par and par.key == S.bandKey then
            kids = kids + 1
            if H.zone(wc, it) then kid = it end
        end
    end
    if not Q.check(kid ~= nil and kids == 5, "the open stack shows a row for each of the five bandages", kids .. " rows") then S.split = false; return end
    if not H.room(S.bag, kid) then Q.skip("split a stack", "the character carries too much to take a bandage"); S.split = false; return end
    S.kid = kid
    local ok, why = H.drag(wc, kid, H.cc())
    Q.check(ok, "one bandage's own row drags out of the open stack and drops on the bag's list", why)
end)
waitFor(4, 600, H.queueEmpty, function()
    if not S.split then return end
    local inBag, inA = H.count(S.bag, S.band), H.count(S.A.inv, S.band)
    Q.check(inBag == 1 and inA == 4 and H.where(S.kid) == S.bag, "split: exactly that one bandage left the stack for the bag",
        inBag .. " in the bag, " .. inA .. " in the crate")
    local wc = H.wc()
    if wc._expandedStacks then wc._expandedStacks[S.bandKey] = nil end
end)
step(6, function()
    if not S.split then return end
    local wc = H.wc()
    local rep = H.rep(wc, S.bandKey)
    if not Q.check(rep ~= nil and H.zone(wc, rep) ~= nil, "the bandages left stand as one closed row again") then S.split = false; return end
    local ok, why = H.drag(wc, rep, H.cc())
    Q.check(ok, "the closed stack's row drags and drops on the bag's list", why)
end)
waitFor(4, 900, H.queueEmpty, function()
    if S.split then
        local left = 0
        for _, it in ipairs(S.band) do
            if H.where(it) ~= S.bag and H.room(S.bag, it) then left = left + 1 end
        end
        Q.check(left == 0 and H.count(S.bag, S.band) > 1, "a closed stack's row carries the whole stack (all the bag has room for)",
            H.count(S.bag, S.band) .. " of 5 in the bag, " .. left .. " left behind with room for them")
    end
    for _, it in ipairs(S.band) do H.put(it, S.A.inv) end
    H.clearSel(H.wc()); H.clearSel(H.cc())
end)

-- ===================================================================== 3. two rows picked with Ctrl, dragged as one
H.qShow(function() return S.B.inv end, "crate B")
step(6, function()
    local wc = H.wc()
    S.multi = false
    if not (H.shows(S.B.inv) and H.zone(wc, S.twine) and H.zone(wc, S.rope)) then
        Q.skip("drag two picked rows", "the twine and the rope are not both on view in crate B"); return
    end
    if not (H.room(S.bag, S.twine) and H.room(S.bag, S.rope)) then Q.skip("drag two picked rows", "the character carries too much"); return end
    local a = H.clickMods(wc, S.twine, false, false)
    local b = H.clickMods(wc, S.rope, true, false)
    local sel = wc._selectedItems or {}
    if not Q.check(a and b and sel[S.twine] and sel[S.rope], "a click and a Ctrl-click pick the twine and the rope") then return end
    local ok, why = H.drag(wc, S.rope, H.cc())
    S.multi = Q.check(ok, "a picked row drags and drops on the bag's list", why)
end)
waitFor(4, 900, H.queueEmpty, function()
    if S.multi then
        Q.check(H.where(S.twine) == S.bag and H.where(S.rope) == S.bag and H.where(S.pan) == S.B.inv,
            "both picked things went to the bag, the unpicked saucepan stayed",
            "twine " .. H.typeOf(H.where(S.twine)) .. ", rope " .. H.typeOf(H.where(S.rope)) .. ", saucepan " .. H.typeOf(H.where(S.pan)))
    end
    H.put(S.twine, S.B.inv); H.put(S.rope, S.B.inv); H.put(S.pan, S.B.inv)
    H.clearSel(H.wc()); H.clearSel(H.cc())
    pcall(function() RT.ww()._updateDrawer() end)
end)

-- ===================================================================== 4. fifty drags in a row
H.qShow(function() return S.A.inv end, "crate A")
step(4, function()
    S.rap = { n = 0, miss = 0, f = 0, trips = 0, twice = 0, last = H.where(S.mover), total = H.size(S.bag) + H.size(S.A.inv) }
    H.reveal(H.cc(), S.mover)
end)
function H.rapidOne()
    local r = S.rap
    local cc, wc = H.cc(), H.wc()
    local at = H.where(S.mover)
    if at ~= r.last then r.trips = r.trips + 1; r.last = at end
    local src, dst = nil, nil
    if at == S.bag and H.zone(cc, S.mover) then src, dst = cc, wc
    elseif at == S.A.inv and H.zone(wc, S.mover) then src, dst = wc, cc end
    if not src then
        r.miss = r.miss + 1
        if at == S.bag then H.reveal(cc, S.mover) elseif at == S.A.inv then H.reveal(wc, S.mover) end
        return
    end
    local ok, why = H.drag(src, S.mover, dst)
    r.n = r.n + 1
    if not ok and not r.err then r.err = why end
    -- (every fifth: the same row dragged again in the same frame, before the first transfer has run)
    if ok and r.n < 50 and r.n - math.floor(r.n / 5) * 5 == 0 and H.zone(src, S.mover) then
        local ok2, why2 = H.drag(src, S.mover, dst)
        r.n = r.n + 1
        r.twice = r.twice + 1
        if not ok2 and not r.err then r.err = why2 end
    end
end
waitFor(1, 1500, function()
    local r = S.rap
    r.f = r.f + 1
    if r.n >= 50 then return true end
    if r.f - math.floor(r.f / 2) * 2 == 0 then H.rapidOne() end
    return r.n >= 50
end, function(ok)
    local r = S.rap
    Q.check(ok and r.err == nil, "fifty drags in a row between the bag and the crate, every other frame: each press and release ran",
        r.n .. " drags in " .. r.f .. " frames (" .. r.twice .. " doubled in one frame, " .. r.miss .. " frames the row was in transit)"
        .. (r.err and ("; first fault: " .. tostring(r.err)) or ""))
end)
waitFor(6, 900, H.queueEmpty, function()
    local r = S.rap
    local at = H.where(S.mover)
    local total = H.size(S.bag) + H.size(S.A.inv)
    Q.check((at == S.bag or at == S.A.inv) and total == r.total, "after the fifty drags the thing is in one place and nothing was lost or doubled",
        "it is in " .. ((at == S.bag) and "the bag" or ((at == S.A.inv) and "the crate" or H.typeOf(at))) .. " after " .. r.trips
        .. " crossings; bag and crate hold " .. total .. " (were " .. r.total .. ")")
    if r.trips == 0 then Q.say("NOTE the thing never crossed (the character carries too much, or the crate is full): the drags still ran") end
    Q.check(H.dragIdle(H.cc()) and H.dragIdle(H.wc()), "no drag is left in the air after the fifty")
end)
step(8, function()
    local okC, whyC = H.drawn(H.cc())
    local okW, whyW = H.drawn(H.wc())
    local badC, badW = H.stale(H.cc()), H.stale(H.wc())
    Q.check(okC and badC == 0, "the bag's list agrees with the inventory after the fifty drags", whyC .. ", " .. badC .. " rows not its own")
    Q.check(okW and badW == 0, "the crate's list agrees with the crate after the fifty drags", whyW .. ", " .. badW .. " rows not its own")
    RT.bounds(Q, "after fifty drags")
    -- A row dragged out of a list: that list lets go of it (the game's own list does). Read here, before the test
    -- moves anything by hand: each drag's press picks the row in the list it leaves, and a pick left on a thing that
    -- is gone turns that list's band into Take marked / Move marked, whose first press moves nothing.
    local strayC, strayW = H.strayPicks(H.cc()), H.strayPicks(H.wc())
    Q.check(strayC == 0 and strayW == 0, "after the drags neither list keeps a pick on a thing it no longer holds (its band stays Loot all / Transfer all)",
        "the bag's list: " .. strayC .. " (its band reads " .. H.bandWord(H.cc(), "xfer") .. "); the crate's list: " .. strayW
        .. " (its band reads " .. H.bandWord(H.wc(), "take") .. "); the thing is in " .. H.nameOf(H.where(S.mover)))
    H.put(S.mover, S.bag)
    -- (no row left picked: with one picked the button is "Take marked", and the first run took the one picked
    -- row, which was back in the bag by then, so nothing was queued and nothing was cut short. The check above
    -- says whether ZeD left that pick; this clears it so section 5 presses the real Loot all)
    H.clearSel(H.wc()); H.clearSel(H.cc())
end)

-- ===================================================================== 5. Loot all and Transfer all cut short
step(6, function()
    S.aThings = H.list(S.A.inv)
    H.instant(false)
    -- (with a row picked the button is Take marked, not Loot all: the first run passed this line on Take marked)
    local picked = 0
    pcall(function() picked = ZeD.InventoryRenderer.padMarkCountOf(H.wc()) end)
    local ok, why, threw = H.press(H.wc(), "take")
    S.cut = ok
    if ok then Q.check(picked == 0, "Loot all pressed with the timed actions at their real length (no row picked: the real Loot all)", why .. ", " .. picked .. " rows picked")
    elseif threw then Q.check(false, "Loot all pressed with the timed actions at their real length", why)
    else Q.skip("Loot all cut short", tostring(why)) end
end)
step(3, function()
    if not S.cut then return end
    S.qMid = H.queueLen()
    local roomFor = 0
    for _, it in ipairs(S.aThings) do if H.room(S.bag, it) then roomFor = roomFor + 1 end end
    if roomFor == 0 then
        Q.skip("Loot all cut short", "the character carries too much to take any thing of the crate")
    else
        Q.check(S.qMid > 0, "Loot all queued its transfers (there is something to cut short)",
            "the queue holds " .. S.qMid .. " three frames after the press; the bag has room for " .. roomFor .. " of " .. #S.aThings)
    end
    H.shutBoth()
end)
step(12, function()
    if not S.cut then return end
    Q.check(not RT.isOpen() and not H.worldOpen(), "both windows shut while Loot all runs", "the queue held " .. S.qMid .. ", now " .. H.queueLen())
    H.openBoth()
end)
waitFor(6, 300, function() return not S.cut or (H.cc() ~= nil and H.wc() ~= nil) end, function(ok)
    if not S.cut then return end
    Q.check(ok, "the pair opens again while the transfers run")
    -- the player walks off: the queue is cleared
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    H.instant(true)
end)
step(12, function()
    H.instant(true)
    H.openBoth()
    H.lootTabs()
    H.show(S.A.inv)
end)
waitFor(6, 600, function() return H.queueEmpty() and H.shows(S.A.inv) and H.cc() ~= nil and H.cc()._inventory == S.bag end, function(ok)
    if not S.cut then return end
    local inA, inBag, lost = 0, 0, 0
    for _, it in ipairs(S.aThings) do
        local at = H.where(it)
        if at == S.A.inv then inA = inA + 1 elseif at == S.bag then inBag = inBag + 1 else lost = lost + 1 end
    end
    Q.check(ok and lost == 0, "Loot all cut short by closing the windows and clearing the queue: every thing is in the crate or the bag",
        inA .. " in the crate, " .. inBag .. " in the bag, " .. lost .. " elsewhere")
end)
step(8, function()
    if S.cut then
        local okC, whyC = H.drawn(H.cc())
        local okW, whyW = H.drawn(H.wc())
        Q.check(okC, "the reopened bag's list agrees with the inventory", whyC)
        Q.check(okW, "the reopened crate's list agrees with the crate", whyW)
    end
    for _, it in ipairs(S.aThings or {}) do H.put(it, S.A.inv) end
    H.put(S.mover, S.bag)
    H.clearSel(H.wc()); H.clearSel(H.cc())
end)
step(8, function()
    H.instant(false)
    local picked = 0
    pcall(function() picked = ZeD.InventoryRenderer.padMarkCountOf(H.cc()) end)
    local ok, why, threw = H.press(H.cc(), "xfer")
    S.cutX = ok
    if ok then Q.check(picked == 0, "Transfer all pressed with the timed actions at their real length (no row picked: the real Transfer all)", why .. ", " .. picked .. " rows picked")
    elseif threw then Q.check(false, "Transfer all pressed with the timed actions at their real length", why)
    else Q.skip("Transfer all cut short", tostring(why)) end
end)
step(2, function()
    if not S.cutX then return end
    local ww = RT.ww()
    S.qMidX = H.queueLen()
    H.try("the World window rolls up while Transfer all runs", function() ww:setWindowShaded(true) end)
end)
step(6, function()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    H.instant(true)
    H.down(RT.ww())
end)
waitFor(4, 900, H.queueEmpty, function()
    if S.cutX then
        local lost = 0
        for _, it in ipairs(S.bagOrig) do
            local at = H.where(it)
            if at ~= S.bag and at ~= S.A.inv then lost = lost + 1 end
        end
        Q.check(lost == 0, "Transfer all cut short by a roll-up and a cleared queue: every thing of the bag is in the bag or the crate",
            lost .. " elsewhere; the queue held " .. tostring(S.qMidX) .. " when the window rolled up")
    end
    local back = H.restoreBag()
    if back > 0 then Q.say("the bag's own things put back by hand: " .. back) end
    for _, it in ipairs(S.aThings or {}) do H.put(it, S.A.inv) end
    H.put(S.mover, S.bag); H.put(S.tool, S.bag); H.put(S.cap, S.bag)
end)
step(8, function()
    local okC, whyC = H.drawn(H.cc())
    Q.check(okC, "the bag's list agrees with the inventory after Transfer all was cut short", whyC)
end)

-- ===================================================================== 6. a left click on a container in the world
-- 6a. both windows shut
step(4, function()
    H.vanHook()
    H.shutBoth()
end)
waitFor(4, 120, function() return not RT.isOpen() and not H.worldOpen() end, function(ok)
    S.k6 = ok
    if not Q.check(ok, "both ZeD windows are shut for the click") then return end
    S.van.n = 0
    H.want(S.A.inv)
    H.clickOn(S.A.obj, S.A.inv)
end)
waitFor(2, 240, function() return not S.k6 or (S.click.done and H.worldOpen() and H.shows(S.A.inv)) end, function(ok)
    if not S.k6 then return end
    Q.check(ok, "a left click on a crate with both windows shut opens ZeD's World window on that crate",
        "by " .. tostring(S.click.how) .. "; World window open " .. tostring(H.worldOpen()) .. ", its list on " .. H.nameOf(H.wc() and H.wc()._inventory))
    Q.check(S.van.n == 0 and not H.vanShowing(), "the game's own loot and inventory pages are never drawn for that click (no flash)",
        S.van.n .. " draws; showing now " .. tostring(H.vanShowing()))
end)
step(8, function()
    if not S.k6 then return end
    local wc = H.wc()
    local bad, n = H.stale(wc)
    Q.check(wc ~= nil and bad == 0 and n > 0, "the list that opened holds the clicked crate's own things", n .. " rows, " .. bad .. " not its own")
    RT.bounds(Q, "the World window opened by a click in the world")
end)
-- 6b. the World window rolled up to its title bar
step(4, function()
    S.k6b = false
    local ww = RT.ww()
    if ww then H.rollUp(ww) end
end)
step(8, function()
    local ww = RT.ww()
    S.k6b = ww ~= nil and ww.windowShaded == true
    if not S.k6b then Q.skip("click on a crate with the World window rolled up", "the window would not stay rolled up (the pointer rests on it)"); return end
    S.van.n = 0
    H.want(S.B.inv)
    H.clickOn(S.B.obj, S.B.inv)
end)
waitFor(2, 240, function() local ww = RT.ww(); return not S.k6b or (S.click.done and ww ~= nil and not ww.windowShaded and H.shows(S.B.inv)) end, function(ok)
    local ww = RT.ww()
    if S.k6b then
        Q.check(ok, "a left click on a crate with the World window rolled up rolls it down on that crate",
            "by " .. tostring(S.click.how) .. "; rolled up " .. tostring(ww and ww.windowShaded) .. ", its list on " .. H.nameOf(H.wc() and H.wc()._inventory))
        Q.check(S.van.n == 0 and not H.vanShowing(), "the game's own pages are never drawn for the click on the rolled-up window", S.van.n .. " draws")
    end
    H.setPins(ww, true, true)
    H.down(ww)
end)
-- 6c. two clicks two frames apart: the second crate is the one shown, never the first one's things
step(6, function()
    S.st = nil
    H.want(S.A.inv)
    H.clickOn(S.A.obj, S.A.inv)
end)
step(2, function()
    H.want(S.B.inv)
    H.clickOn(S.B.obj, S.B.inv)
end)
waitFor(2, 240, function() return S.click.done and H.shows(S.B.inv) end, function(ok)
    Q.check(ok, "two crates clicked two frames apart: the list ends on the second", "its list on " .. H.nameOf(H.wc() and H.wc()._inventory))
end)
step(20, function()
    local st = S.st
    if not S.sampling then Q.skip("the list never draws another container's things after a click", "this build has no OnPostUIDraw event to look after each draw"); return end
    Q.check(st.stale == 0 and st.mis == 0 and st.back == 0 and st.frames > 0,
        "after the switch by a click the list never draws another container's things", H.stLine())
end)
-- 6d. the World window's inventory side rolled under its tab (a tab drawer open beside it)
step(4, function()
    S.k6d, S.k6x = false, false
    local ww = RT.ww()
    if not (ww and ww._halves and ww._curtain) then return end
    if not RT.worldTab("craft") then pcall(ZeD_WorldWindow.openTab, S.pn, "craft") end
end)
-- the side rolled as the pointer's leaving rolls it (its timer run out, not by hand); false when it cannot roll here
function H.rollSide(ww)
    local s = ww and ww._halves
    local can = false
    pcall(function() can = s ~= nil and ww._activeTab ~= "loot" and ww._curtain.canRoll() end)
    if not can then return false end
    H.setPins(ww, false, true)
    s.inv.rolled, s.inv.hand, s.inv.out = true, false, nil
    return true
end
function H.titleH(ww)
    local h = nil
    pcall(function() h = ZeD.T.titleBarH end)
    if not h then pcall(function() h = ww:titleBarHeight() end) end
    return h or 0
end
-- the tab's fabric (WindowCurtain's rod): how tall it is now, where it is going, the window's height
function H.tabWords(ww)
    local rod = ww and ww._rod
    if not rod then return "no tab" end
    local winH = -1
    pcall(function() winH = ww:getHeight() end)
    return string.format("its tab %d px tall, going to %d px (the window %d px, its title bar %d px)",
        math.floor(rod._h or -1), math.floor(rod._target or -1), math.floor(winH), math.floor(H.titleH(ww)))
end
-- 6d, first: the click lands just as the side starts to roll, before its tab has drawn once. A player's quick click
-- can land so (the side's timer runs out on the update the release comes in). Staged on the window's first roll (the
-- 6a click opened it afresh): its tab is new and only queued for the game's UI list, so a click on the next frame
-- comes before the tab's first draw. The second run (Nov 21) found the side stuck there: rolled, the tab at full
-- height and going nowhere, no tab to press, the hover no help (WindowCurtain C.unroll sets the tab's target to the
-- height it already has, and only a tab that moves ever ends the unroll). This check FAILS until that is fixed.
step(20, function()
    local ww = RT.ww()
    S.k6xNew = ww ~= nil and ww._rod == nil
    S.k6x = H.rollSide(ww)
    if not S.k6x then
        Q.skip("a click on a crate just as the inventory side starts to roll under its tab", "the side cannot roll here (no tab drawer beside the list)")
    end
end)
waitFor(1, 90, function() local ww = RT.ww(); return not S.k6x or (ww ~= nil and ww._rolled == true) end, function(ok)
    if not S.k6x then return end
    local why = nil
    if not ok then why = "the side would not roll (the pointer rests on it)"
    elseif not S.k6xNew then why = "the side rolled before in this window: its tab draws in the frame it rolls, before a click from here" end
    if why then S.k6x = false; Q.skip("a click on a crate just as the inventory side starts to roll under its tab", why); return end
    -- (the tab as the click finds it, read on the same tick just before the click)
    local ev = Events.OnTickEvenPaused or Events.OnTick
    local function probe()
        ev.Remove(probe)
        local w = RT.ww()
        local rod = w and w._rod
        S.k6xAt = { h = rod and rod._h, winH = w and w:getHeight(), rolled = w and w._rolled }
    end
    S.k6xAt = nil
    ev.Add(probe)
    H.clickOn(S.B.obj, S.B.inv)
end)
waitFor(2, 240, function() local ww = RT.ww(); return not S.k6x or (S.click.done and ww ~= nil and not ww._rolled) end, function(ok)
    local ww = RT.ww()
    if S.k6x then
        local at = S.k6xAt
        if not at then
            Q.skip("a click on a crate just as the inventory side starts to roll under its tab", "no tick ran the click")
        elseif not (at.rolled == true and at.h ~= nil and at.winH ~= nil and at.h >= at.winH) then
            Q.skip("a click on a crate just as the inventory side starts to roll under its tab",
                "its tab had drawn before the click came (" .. tostring(at.h) .. " of " .. tostring(at.winH) .. " px): that order did not come")
        else
            local rolled = ww ~= nil and ww._rolled == true
            local rod = rolled and ww._rod or nil
            local stuck = rod ~= nil and rod._h == rod._target and (rod._target or 0) > H.titleH(ww)
            Q.check(ok, "a left click on a crate just as the inventory side starts to roll under its tab (the tab not drawn yet) still brings the side down",
                "by " .. tostring(S.click.how) .. "; side rolled " .. tostring(rolled) .. (rolled and ("; " .. H.tabWords(ww)) or "")
                .. (stuck and ": asked down before it had drawn once, it never moves (WindowCurtain C.unroll)" or "")
                .. "; its list on " .. H.nameOf(H.wc() and H.wc()._inventory))
        end
    end
    H.setPins(ww, true, true)
    H.down(ww)
end)
-- 6d, second: a player's click once the side has rolled under its tab, the tab drawn up to its title bar as he sees it
-- before he clicks (QA B5-1: a click on a crate in the world brings down a side the pointer rolled away)
function H.sideRolledAway(ww)
    local rod = ww and ww._rod
    if not (ww and ww._rolled == true and rod and rod._h and rod._target) then return false end
    return rod._target <= H.titleH(ww) and rod._h <= rod._target
end
step(20, function()
    S.k6d = H.rollSide(RT.ww())
    if not S.k6d then
        Q.skip("click on a crate with the World window's inventory side rolled under its tab", "the side cannot roll here (no tab drawer beside the list)")
    end
end)
waitFor(2, 240, function() return not S.k6d or H.sideRolledAway(RT.ww()) end, function(ok)
    if not S.k6d then return end
    if not ok then
        S.k6d = false
        local ww = RT.ww()
        if ww and ww._rolled then
            Q.check(false, "the World window's inventory side rolls under its tab: the tab draws up to its title bar", H.tabWords(ww))
        else
            Q.skip("click on a crate with the World window's inventory side rolled under its tab", "the side would not roll here (the pointer rests on it)")
        end
        return
    end
    S.van.n = 0
    H.want(S.A.inv)
    H.clickOn(S.A.obj, S.A.inv)
end)
waitFor(2, 240, function() local ww = RT.ww(); return not S.k6d or (S.click.done and ww ~= nil and not ww._rolled and H.shows(S.A.inv)) end, function(ok)
    local ww = RT.ww()
    if S.k6d then
        local rolled = ww ~= nil and ww._rolled == true
        Q.check(ok, "a left click on a crate with the inventory side rolled under its tab rolls the side down on that crate",
            "by " .. tostring(S.click.how) .. "; side rolled " .. tostring(rolled) .. (rolled and ("; " .. H.tabWords(ww)) or "")
            .. ", its list on " .. H.nameOf(H.wc() and H.wc()._inventory))
        Q.check(S.van.n == 0 and not H.vanShowing(), "the game's own pages are never drawn for the click on the rolled side", S.van.n .. " draws")
    end
    H.setPins(ww, true, true)
    H.down(ww)
    H.want(nil)
    RT.worldTab("loot")
end)
-- 6e. the game paused, the World window rolled up
step(10, function()
    S.k6e = false
    local ww = RT.ww()
    if not ww then return end
    H.rollUp(ww)
    H.pause(true)
end)
step(8, function()
    local ww = RT.ww()
    S.k6e = ww ~= nil and ww.windowShaded == true and getGameSpeed() == 0
    if not S.k6e then Q.skip("click on a crate while paused", "the game would not pause or the window would not stay rolled up"); return end
    S.van.n = 0
    H.clickOn(S.B.obj, S.B.inv)
end)
waitFor(2, 240, function() local ww = RT.ww(); return not S.k6e or (S.click.done and ww ~= nil and not ww.windowShaded and H.shows(S.B.inv)) end, function(ok)
    local ww = RT.ww()
    if S.k6e then
        Q.check(ok, "paused: a left click on a crate rolls the World window down on that crate while the game stays paused",
            "by " .. tostring(S.click.how) .. "; rolled up " .. tostring(ww and ww.windowShaded) .. ", its list on " .. H.nameOf(H.wc() and H.wc()._inventory)
            .. ", game speed " .. tostring(getGameSpeed()))
        Q.check(S.van.n == 0 and not H.vanShowing(), "paused: the game's own pages are never drawn for the click", S.van.n .. " draws")
    end
    H.pause(false)
    H.setPins(ww, true, true)
    H.down(ww)
end)
-- 6f. Loot columns open
H.qShow(function() return S.A.inv end, "crate A")
step(6, function()
    S.k6f = false
    H.try("toggleColumn on crate A", function() ZeD_WorldWindow.toggleColumn(S.A.inv, S.pn) end)
end)
step(6, function()
    local ww = RT.ww()
    S.k6f = ww ~= nil and #(ww._mcSelected or {}) > 0
    if not S.k6f then Q.skip("click on a crate with Loot columns open", "no column opened here"); return end
    S.van.n = 0
    H.clickOn(S.B.obj, S.B.inv)
end)
waitFor(2, 240, function() local ww = RT.ww(); return not S.k6f or (S.click.done and ww ~= nil and #(ww._mcSelected or {}) == 0 and H.shows(S.B.inv)) end, function(ok)
    local ww = RT.ww()
    if S.k6f then
        Q.check(ok, "a left click on a crate with Loot columns open closes them on that crate's one list",
            #((ww and ww._mcSelected) or {}) .. " columns left, its list on " .. H.nameOf(H.wc() and H.wc()._inventory))
        Q.check(S.van.n == 0 and not H.vanShowing(), "the game's own pages are never drawn for the click over the columns", S.van.n .. " draws")
    end
    pcall(ZeD_WorldWindow.closeColumns, ww)
    H.vanUnhook()
    H.openBoth()
end)
step(20, function() H.lootTabs() end)

-- ===================================================================== 7. switching: never the last container's things
step(10, function()
    S.st = nil
    S.sw = { i = 0, f = 0 }
end)
waitFor(1, 400, function()
    local w = S.sw
    w.f = w.f + 1
    if w.i >= 18 then return true end
    if w.f - math.floor(w.f / 2) * 2 ~= 0 then return false end
    w.i = w.i + 1
    local c = S.crates[(w.i - 1) - math.floor((w.i - 1) / 3) * 3 + 1]
    H.want(c.inv)
    w.last = c.inv
    local ok, err = pcall(ZeD_WorldWindow.selectContainer, c.inv, 60, S.pn)
    if not ok and not w.err then w.err = tostring(err); S.errs = S.errs + 1 end
    return false
end, function() end)
step(12, function()
    local w, st = S.sw, S.st
    Q.check(w.err == nil and H.shows(w.last), "eighteen container switches two frames apart end on the last one asked for",
        (w.err and ("fault: " .. w.err .. "; ") or "") .. "its list on " .. H.nameOf(H.wc() and H.wc()._inventory))
    if S.sampling and st then
        Q.check(st.stale == 0 and st.mis == 0 and st.back == 0 and st.frames > 0,
            "through the eighteen switches the list never draws another container's things, and its drop target is the container shown", H.stLine())
    else
        Q.skip("the list never draws another container's things through the switches", "no OnPostUIDraw event to look after each draw")
    end
    local okW, whyW = H.drawn(H.wc())
    Q.check(okW, "the list agrees with its container after the switches", whyW)
end)
-- a request for a crate not yet on the strip (just made), then at once one for crate A: the later one must stand
step(4, function()
    S.late = nil
    if not S.spareSq then Q.skip("a late request does not win over a newer one", "no fourth free square for a new crate"); return end
    S.D = H.mkCrate(S.spareSq)
    if not S.D then Q.skip("a late request does not win over a newer one", "the new crate could not be made"); return end
    S.dThing = H.add(S.D.inv, "Base.Rope")
    S.st = nil
    local okD = pcall(ZeD_WorldWindow.selectContainer, S.D.inv, 60, S.pn)
    S.late = okD
end)
step(1, function()
    if not S.late then return end
    H.want(S.A.inv)
    H.show(S.A.inv)
end)
Q.waitMs(1800)
step(2, function()
    if not S.late then return end
    local st = S.st or { back = 0 }
    Q.check(H.shows(S.A.inv) and st.back == 0, "a crate asked for before it was in reach, then crate A asked for: the list stays on crate A (the newer request)",
        "its list on " .. ((H.wc() and H.wc()._inventory == S.D.inv) and "the crate asked for first" or H.nameOf(H.wc() and H.wc()._inventory))
        .. "; " .. H.stLine())
    H.want(nil)
end)
step(2, function()
    if S.D then
        if S.dThing then H.removeItem(S.dThing) end
        H.rmCrate(S.D)
    end
    H.show(S.A.inv)
end)
-- the strip's own buttons: on Loot a press opens or closes that container's column
step(30, function() S.col = { i = 0, f = 0, pressed = 0, noZone = 0 } end)
waitFor(1, 300, function()
    local w = S.col
    w.f = w.f + 1
    if w.i >= 11 then return true end
    if w.f - math.floor(w.f / 2) * 2 ~= 0 then return false end
    local c = S.crates[w.i - math.floor(w.i / 3) * 3 + 1]
    local strip, _, z = H.stripAt(RT.ww(), c.inv)
    if not z then w.noZone = w.noZone + 1; if w.noZone > 40 then w.i = 11 end; return false end
    w.i = w.i + 1
    local ok, err = pcall(function()
        strip:onMouseDown(z.x + 2, z.y + 2)
        if strip.onMouseUp then strip:onMouseUp(z.x + 2, z.y + 2) end
    end)
    if ok then w.pressed = w.pressed + 1 elseif not w.err then w.err = tostring(err); S.errs = S.errs + 1 end
    return false
end, function() end)
step(8, function()
    local w = S.col
    local ww, wc = RT.ww(), H.wc()
    if w.pressed == 0 and not w.err then Q.skip("presses on the crates' strip buttons", "the buttons were not found on the World window's strip"); return end
    local bad, cols, rows = 0, 0, 0
    for _, cs in ipairs(wc._colStates or {}) do
        cols = cols + 1
        local e = ww._containers[cs.containerIdx]
        if not (e and e.inventory == cs.inventory) then bad = bad + 1 end
        for _, it in ipairs(cs.flatItems or {}) do
            rows = rows + 1
            if H.where(it) ~= cs.inventory then bad = bad + 1 end
        end
    end
    Q.check(w.err == nil and bad == 0, "eleven presses on the crates' buttons two frames apart (columns opening and closing): every column is its own container's",
        w.pressed .. " presses, " .. cols .. " columns open with " .. rows .. " rows, " .. bad .. " wrong" .. (w.err and ("; fault: " .. w.err) or ""))
    RT.bounds(Q, "the Loot columns after eleven presses")
    S.st = nil
    H.try("the columns close", function() ZeD_WorldWindow.closeColumns(ww) end)
end)
step(3, function()
    if not S.col or (S.col.pressed == 0) then return end
    local wc = H.wc()
    local view = H.viewInv()
    local bad, n = H.stale(wc)
    Q.check(view ~= nil and view == wc._inventory and bad == 0,
        "the columns closed: three frames on, the one list's rows and its drop target are the container the window shows",
        "the window shows " .. H.typeOf(view) .. ((view == S.A.inv) and " (A)" or ((view == S.B.inv) and " (B)" or ((view == S.C.inv) and " (C)" or "")))
        .. ", a drop would land in " .. H.typeOf(wc._inventory) .. ((wc._inventory == S.A.inv) and " (A)" or ((wc._inventory == S.B.inv) and " (B)" or ((wc._inventory == S.C.inv) and " (C)" or "")))
        .. "; " .. n .. " rows, " .. bad .. " not its own")
end)
-- zero, one, zero: the empty crate
H.qShow(function() return S.C.inv end, "the empty crate")
step(6, function()
    local wc = H.wc()
    S.zero = H.shows(S.C.inv)
    if not S.zero then return end
    Q.check(#(wc._flatItems or {}) == 0, "the empty crate shows an empty list", #(wc._flatItems or {}) .. " rows")
    local ok, why, threw = H.press(wc, "take")
    Q.check(not threw and H.queueEmpty(), "Loot all on the empty crate does nothing", tostring(why) .. ", queue " .. H.queueLen())
    local ok2, why2, threw2 = H.press(wc, "floor")
    Q.check(not threw2 and H.queueEmpty(), "To floor on the empty crate does nothing", tostring(why2) .. ", queue " .. H.queueLen())
    RT.bounds(Q, "the empty crate")
    H.reveal(H.cc(), S.mover)
end)
step(5, function()
    if not S.zero then return end
    local ok, why = H.drag(H.cc(), S.mover, H.wc())
    Q.check(ok, "a thing drags from the bag onto the empty crate's list", why)
end)
waitFor(4, 600, function() return H.queueEmpty() and (not S.zero or H.where(S.mover) == S.C.inv) end, function(ok)
    if not S.zero then return end
    Q.check(ok, "the empty crate takes it", "it is in " .. H.typeOf(H.where(S.mover)))
end)
step(8, function()
    if not S.zero then return end
    local wc = H.wc()
    local okW, whyW = H.drawn(wc)
    Q.check(okW and #(wc._flatItems or {}) == 1, "the crate's list shows its one thing", whyW)
    if H.where(S.mover) == S.C.inv and H.zone(wc, S.mover) and H.room(S.bag, S.mover) then
        local ok, why = H.drag(wc, S.mover, H.cc())
        Q.check(ok, "the one thing drags back out", why)
    end
end)
waitFor(4, 600, H.queueEmpty, function()
    H.put(S.mover, S.bag)
end)
step(8, function()
    if not S.zero then return end
    local wc = H.wc()
    Q.check(H.shows(S.C.inv) and #(wc._flatItems or {}) == 0, "emptied again, the crate's list is empty (no row left behind)", #(wc._flatItems or {}) .. " rows")
end)

-- ===================================================================== 8. the roll-ups under a drag
H.qShow(function() return S.A.inv end, "crate A")
-- 8a. the whole Character window rolled up to its title bar
step(6, function()
    S.r8 = nil
    local cw = RT.cw()
    if not (cw and S.loot and H.where(S.loot) == S.A.inv and H.shows(S.A.inv)) then
        Q.skip("drag onto the rolled-up Character window", "the thing to drag is not in crate A, or the crate is not shown"); return
    end
    if H.padBound() then Q.skip("drag onto the rolled-up Character window", "a controller is bound: the pointer's rules are off"); return end
    H.reveal(H.wc(), S.loot)
    S.r8 = H.rollUp(cw)
end)
step(8, function()
    if not S.r8 then return end
    local cw, wc = RT.cw(), H.wc()
    local px, py = H.barPoint(cw, RT.ww())
    if not (cw.windowShaded and px) then
        S.r8 = nil
        Q.skip("drag onto the rolled-up Character window", "the window did not stay rolled up, or its title bar lies under the World window"); return
    end
    local ok, why = H.grab(wc, S.loot)
    if not Q.check(ok, "a thing in the looted crate is picked up for the drag", why) then S.r8 = nil; return end
    H.fakeOn(px, py)
    S.r8t = getTimestampMs()
end)
waitFor(1, 300, function() local cw = RT.cw(); return not S.r8 or (cw ~= nil and not cw.windowShaded) end, function(ok)
    if not S.r8 then return end
    Q.check(ok, "a thing dragged from a looted crate over the rolled-up Character window's title bar rolls the window down",
        "after " .. (getTimestampMs() - S.r8t) .. " ms; rolled up " .. tostring(RT.cw() and RT.cw().windowShaded))
    local okL, why = H.let(H.wc(), nil)
    H.fakeOff()
    Q.check(okL, "the thing is released on that title bar", why)
end)
waitFor(4, 600, H.queueEmpty, function()
    H.fakeOff()
    H.cancelDrags()
    if S.r8 then
        if H.room(S.bag, S.loot) then
            Q.check(H.where(S.loot) == S.bag, "released on the Character window's title bar, the thing lands in the inventory", "it is in " .. H.typeOf(H.where(S.loot)))
        else
            Q.skip("the thing lands in the inventory", "the character carries too much to take it")
        end
    end
    local cw = RT.cw()
    H.setPins(cw, true, true)
    H.down(cw)
    H.put(S.loot, S.A.inv)
end)
-- 8b. the Character window's inventory side rolled under its tab (a tab drawer open beside it)
step(6, function()
    S.r8b = nil
    local cw = RT.cw()
    if H.padBound() or not (cw and cw._halves and cw._curtain) then return end
    S.r8b = RT.charTab("skills") and 1 or nil
end)
step(20, function()
    if not S.r8b then Q.skip("drag onto the Character window's rolled inventory side", "no halves on this window, or a controller is bound"); return end
    local cw = RT.cw()
    local s = cw._halves
    local can = false
    pcall(function() can = cw._activeTab == "skills" and cw._curtain.canRoll() end)
    if not can then S.r8b = nil; Q.skip("drag onto the Character window's rolled inventory side", "the side cannot roll here (no tab drawer beside the list)"); return end
    H.setPins(cw, false, true)
    s.inv.rolled, s.inv.hand, s.inv.out = true, false, nil
end)
waitFor(2, 90, function() local cw = RT.cw(); return not S.r8b or (cw ~= nil and cw._rolled == true and cw._rod ~= nil) end, function(ok)
    if not S.r8b then return end
    local cw = RT.cw()
    if not ok then S.r8b = nil; Q.skip("drag onto the Character window's rolled inventory side", "the side would not roll (the pointer rests on it)"); return end
    H.reveal(H.wc(), S.loot)
    local okG, why = H.grab(H.wc(), S.loot)
    if not Q.check(okG, "a thing in the looted crate is picked up for the second drag", why) then S.r8b = nil; return end
    local rod = cw._rod
    H.fakeOn(rod:getX() + math.floor(rod:getWidth() / 2), rod:getY() + math.floor(cw:titleBarHeight() / 2))
    S.r8t = getTimestampMs()
end)
waitFor(1, 300, function() local cw = RT.cw(); return not S.r8b or (cw ~= nil and not cw._rolled) end, function(ok)
    if not S.r8b then return end
    Q.check(ok, "a thing dragged from a looted crate over the Character window's rolled-up inventory side rolls it down",
        "after " .. (getTimestampMs() - S.r8t) .. " ms; side rolled " .. tostring(RT.cw() and RT.cw()._rolled))
    H.fakeOff()
end)
step(5, function()
    H.fakeOff()
    if not S.r8b then return end
    local okL, why = H.let(H.wc(), H.cc())
    Q.check(okL, "the thing is released on the inventory list that came down", why)
end)
waitFor(4, 600, H.queueEmpty, function()
    H.cancelDrags()
    if S.r8b then
        if H.room(S.bag, S.loot) then
            Q.check(H.where(S.loot) == S.bag, "released on the list that came down, the thing lands in the inventory", "it is in " .. H.typeOf(H.where(S.loot)))
        else
            Q.skip("the thing lands in the inventory (second drag)", "the character carries too much to take it")
        end
        RT.bounds(Q, "the Character window rolled down under a drag")
    end
    local cw = RT.cw()
    H.setPins(cw, true, true)
    H.down(cw)
    RT.charTab("loot")
    H.put(S.loot, S.A.inv)
end)
-- 8c. released on the World window in the frame it rolls up (its title bar takes the drop for its list)
step(20, function() H.reveal(H.cc(), S.mover) end)
step(6, function()
    S.r8c = nil
    local cw, ww = RT.cw(), RT.ww()
    if H.padBound() or not (cw and ww and H.shows(S.A.inv) and H.where(S.mover) == S.bag) then
        Q.skip("drag released on the World window as it rolls up", "the windows are not staged for it"); return
    end
    local px, py = H.barPoint(ww, cw)
    if not px then Q.skip("drag released on the World window as it rolls up", "its title bar lies under the Character window"); return end
    local ok, why = H.grab(H.cc(), S.mover)
    if not Q.check(ok, "a thing in the bag is picked up for the drag", why) then return end
    H.try("the World window rolls up while the thing is in the air", function() ww:setWindowShaded(true) end)
    H.fakeOn(px, py)
    local okL, whyL = H.let(H.cc(), nil)
    H.fakeOff()
    S.r8c = Q.check(okL, "the thing is released on the World window's title bar in the frame it rolls up", whyL)
end)
waitFor(4, 600, H.queueEmpty, function()
    H.fakeOff()
    H.cancelDrags()
    if S.r8c then
        Q.check(H.where(S.mover) == S.A.inv, "released on the rolled-up World window's title bar, the thing lands in the crate that window shows",
            "it is in " .. ((H.where(S.mover) == S.bag) and "the bag still" or H.typeOf(H.where(S.mover))))
    end
    H.down(RT.ww())
    H.put(S.mover, S.bag)
end)
-- 8d. the window rolls up under a drag from its own list; a right press calls the drag off
step(10, function()
    S.r8d = nil
    local ww = RT.ww()
    if not (ww and H.shows(S.A.inv) and H.where(S.loot) == S.A.inv) then return end
    H.reveal(H.wc(), S.loot)
end)
step(5, function()
    local ww = RT.ww()
    if not (ww and H.shows(S.A.inv) and H.where(S.loot) == S.A.inv) then Q.skip("a window rolled up under its own drag", "crate A is not shown"); return end
    local ok, why = H.grab(H.wc(), S.loot)
    if not Q.check(ok, "a thing in the crate is picked up", why) then return end
    S.r8d = H.try("the World window rolls up under a drag from its own list", function() ww:setWindowShaded(true) end)
end)
step(4, function()
    if not S.r8d then H.cancelDrags(); return end
    local wc = H.wc()
    H.try("a right press during the drag", function() wc:onRightMouseDown(1, 1) end)
    Q.check(H.dragIdle(wc) and H.where(S.loot) == S.A.inv and H.queueEmpty(),
        "the window rolled up under its own drag, then a right press: the drag is called off and the thing stays in the crate",
        "drag idle " .. tostring(H.dragIdle(wc)) .. ", it is in " .. H.typeOf(H.where(S.loot)) .. ", queue " .. H.queueLen())
    H.cancelDrags()
    H.down(RT.ww())
end)
step(10, function() RT.bounds(Q, "both windows down again after the roll-ups") end)

-- ===================================================================== 9. a crate taken away mid-drag
-- 9a. the drop's target
H.qShow(function() return S.B.inv end, "crate B")
step(4, function() H.reveal(H.cc(), S.mover) end)
step(5, function()
    S.g9 = H.shows(S.B.inv) and H.where(S.mover) == S.bag
    if not S.g9 then Q.skip("a crate taken away as the drop's target", "crate B is not shown or the thing is not in the bag"); return end
    local ok, why = H.grab(H.cc(), S.mover)
    if not Q.check(ok, "a thing in the bag is picked up", why) then S.g9 = false; return end
    H.rmCrate(S.B)   -- (the crate is gone while the thing is in the air)
end)
step(20, function()
    if not S.g9 then return end
    local wc = H.wc()
    S.g9on = wc._inventory == S.B.inv
    local ok, why = H.let(H.cc(), wc)
    Q.check(ok, "released over the World window's list after its crate was taken away mid-drag: nothing throws",
        why .. "; the list was " .. (S.g9on and "still on the crate that is gone" or ("on " .. H.typeOf(wc._inventory))))
end)
waitFor(4, 600, H.queueEmpty, function()
    H.cancelDrags()
    if not S.g9 then return end
    -- (the list had moved to the floor, so the drop is the game's own drop: the thing lies on the ground. It reads
    -- "in the floor" only once the floor's list has been built again, and in no container until then (the game's
    -- IsoWorldInventoryObject sets the thing's container to nil as it lays it down); both are the ground. A thing in
    -- no container and not on the ground is lost, and so is one in the floor's list with nothing on the ground: fails)
    local at = H.where(S.mover)
    local ground = H.onFloor(S.mover)
    local floorList = at ~= nil and H.typeOf(at) == "floor"
    Q.check(at ~= S.B.inv and (ground or (at ~= nil and not floorList)), "a drop on the list of a crate taken away mid-drag does not put the thing into the crate that is gone",
        "it is " .. ((at == S.bag) and "in the bag" or ((at == S.B.inv) and "in the crate that is gone"
            or (ground and "on the ground" or (floorList and "in the floor's list but not on the ground"
            or ((at ~= nil) and ("in " .. H.typeOf(at)) or "in nothing and not on the ground"))))))
    H.put(S.mover, S.bag)
end)
waitFor(2, 300, function() return not S.g9 or (not H.listed(RT.ww(), S.B.inv) and not H.shows(S.B.inv)) end, function(ok)
    if not S.g9 then return end
    local wc = H.wc()
    local rowsOfB = 0
    for _, it in ipairs(wc._flatItems or {}) do if H.where(it) == S.B.inv then rowsOfB = rowsOfB + 1 end end
    Q.check(ok and rowsOfB == 0, "the World window lets go of the crate that is gone: off its buttons, its list on something else, none of its rows left",
        "on the buttons " .. tostring(H.listed(RT.ww(), S.B.inv)) .. ", list on it " .. tostring(H.shows(S.B.inv)) .. ", " .. rowsOfB .. " of its rows")
    RT.bounds(Q, "after a crate was taken away")
end)
-- 9b. the drag's source
step(4, function() H.put(S.loot, S.C.inv) end)
H.qShow(function() return S.C.inv end, "crate C")
step(6, function()
    S.g9b = H.shows(S.C.inv) and H.zone(H.wc(), S.loot) ~= nil
    if not S.g9b then Q.skip("a crate taken away as the drag's source", "crate C is not shown with the thing in it"); return end
    local ok, why = H.grab(H.wc(), S.loot)
    if not Q.check(ok, "a thing in crate C is picked up", why) then S.g9b = false; return end
    H.rmCrate(S.C)
end)
step(20, function()
    if not S.g9b then return end
    local ok, why = H.let(H.wc(), H.cc())
    Q.check(ok, "released over the bag's list after the crate it came from was taken away mid-drag: nothing throws", why)
end)
waitFor(4, 600, H.queueEmpty, function()
    H.cancelDrags()
    if not S.g9b then return end
    local at = H.where(S.loot)
    Q.check(H.dragIdle(H.wc()) and (at == S.bag or at == S.C.inv), "the thing is in one place after its crate went (the bag, or still in the crate's own container)",
        "it is in " .. ((at == S.bag) and "the bag" or ((at == S.C.inv) and "the gone crate's container" or H.typeOf(at))))
end)
waitFor(2, 300, function() return not S.g9b or (not H.listed(RT.ww(), S.C.inv) and not H.shows(S.C.inv)) end, function(ok)
    if S.g9b then
        Q.check(ok, "the World window lets go of the source crate that is gone",
            "on the buttons " .. tostring(H.listed(RT.ww(), S.C.inv)) .. ", list on it " .. tostring(H.shows(S.C.inv)))
    end
    H.put(S.loot, S.A.inv)
end)

-- ===================================================================== 10. the belt and the doll
H.qShow(function() return S.A.inv end, "crate A")
-- 10a. the belt's main hand
function H.beltBox(pred)
    local hud = H.hud()
    for _, b in ipairs((hud and hud._boxes) or {}) do if pred(b) then return b, hud end end
    return nil, hud
end
step(4, function() H.reveal(H.cc(), S.tool) end)
step(6, function()
    S.b10 = nil
    local box, hud = H.beltBox(function(b) return b.kind == "hand" and b.which == "p" end)
    if not (hud and hud._drawn and box) then Q.skip("drag onto the belt", "ZeD's belt is not on screen here"); return end
    if not (S.tool and H.where(S.tool) == S.bag and H.zone(H.cc(), S.tool)) then Q.skip("drag onto the belt", "no tool of its own kind could be made, or its row is not on view"); return end
    local ok, why = H.drag(H.cc(), S.tool, hud, H.at(hud, box.x + math.floor(box.w / 2), box.y + math.floor(box.h / 2)))
    S.b10 = Q.check(ok, "the tool's row drags from the bag and drops on the belt's main hand", why)
end)
waitFor(4, 900, function() return not S.b10 or (H.queueEmpty() and S.p:getPrimaryHandItem() == S.tool) end, function(ok)
    if not S.b10 then return end
    local hand = S.p:getPrimaryHandItem()
    Q.check(ok, "dropped on the belt's main hand, the tool is in the main hand (the game's equip)", "the hand holds " .. tostring(hand and hand:getFullType()))
end)
step(10, function()
    if not S.b10 then return end
    if S.p:getPrimaryHandItem() == S.tool then
        Q.check(not H.inRows(H.cc(), S.tool), "the tool in the hand leaves the bag's list")
    end
    pcall(function() ISTimedActionQueue.add(ISUnequipAction:new(S.p, S.tool, 50)) end)
end)
waitFor(4, 900, function() return not S.b10 or (H.queueEmpty() and S.p:getPrimaryHandItem() ~= S.tool and H.inRows(H.cc(), S.tool)) end, function(ok)
    if S.b10 then
        Q.check(ok, "unequipped by the game's own action, the tool's row is back in the bag's list",
            "in the hand " .. tostring(S.p:getPrimaryHandItem() == S.tool) .. ", in the list " .. tostring(H.inRows(H.cc(), S.tool)))
    end
    H.handsBack()
end)
function H.handsBack()
    if not S.handWas then return end
    pcall(function() if S.p:getPrimaryHandItem() ~= S.handWas.p then S.p:setPrimaryHandItem(S.handWas.p) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= S.handWas.s then S.p:setSecondaryHandItem(S.handWas.s) end end)
end
-- 10b. an empty belt slot that takes the tool
step(6, function()
    S.b10s = nil
    if not S.b10 then return end
    local hb = nil
    pcall(function() hb = ZeD.Belt.hotbar(S.pn) end)
    local box = H.beltBox(function(b) return b.kind == "slot" and not (b.s and b.s.item) and ZeD.Belt.fits(hb, b.i, S.tool) end)
    if not box then Q.skip("drag onto a belt slot", "no empty belt slot takes this tool on this character"); return end
    S.b10s = box.i
    H.reveal(H.cc(), S.tool)
end)
step(5, function()
    if not S.b10s then return end
    local box, hud = H.beltBox(function(b) return b.kind == "slot" and b.i == S.b10s end)
    if not (box and H.zone(H.cc(), S.tool)) then S.b10s = nil; Q.skip("drag onto a belt slot", "the slot or the tool's row is not on view"); return end
    local ok, why = H.drag(H.cc(), S.tool, hud, H.at(hud, box.x + math.floor(box.w / 2), box.y + math.floor(box.h / 2)))
    if not Q.check(ok, "the tool's row drags from the bag and drops on an empty belt slot", why) then S.b10s = nil end
end)
function H.slotOf(it) local n = -1; pcall(function() n = it:getAttachedSlot() or -1 end); return n end
waitFor(4, 900, function() return not S.b10s or (H.queueEmpty() and H.slotOf(S.tool) == S.b10s) end, function(ok)
    if not S.b10s then return end
    Q.check(ok, "dropped on the belt slot, the tool hangs on that slot (the game's attach)", "slot " .. H.slotOf(S.tool) .. ", wanted " .. S.b10s)
    H.try("ZeD.Belt.detach", function() ZeD.Belt.detach(S.pn, S.tool) end)
end)
waitFor(4, 900, function() return not S.b10s or (H.queueEmpty() and H.slotOf(S.tool) < 0) end, function(ok)
    if S.b10s then Q.check(ok, "taken off the belt again (the game's own action), the slot is empty", "slot " .. H.slotOf(S.tool)) end
    if S.tool then H.loose(S.tool) end
    H.handsBack()
end)
-- 10c. the Equip tab's doll: worn by a drop on its slot, dragged off into the crate
function H.normLoc(loc)
    local ls = string.lower(tostring(loc))
    local c = string.find(ls, ":", 1, true)
    if c then ls = string.sub(ls, c + 1) end
    return (string.gsub(ls, "_", ""))
end
function H.wornNow(it)
    local w = false
    pcall(function() w = S.p:isEquippedClothing(it) end)
    return w and true or false
end
-- the things worn now (a set), read as the setup read them
function H.wornSet()
    local set = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do set[wi:get(i):getItem()] = true end
    end)
    return set
end
function H.wornBack()
    local on = H.wornSet()
    for _, e in ipairs(S.worn or {}) do
        if not on[e.item] and H.where(e.item) == S.p:getInventory() then
            pcall(function() S.p:setWornItem(e.loc, e.item) end)
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
end
step(6, function()
    S.d10 = nil
    local D = ZeD.EquipDoll
    if not (D and D.takeDrop and S.cap and H.where(S.cap) == S.bag) then Q.skip("drag onto the doll", "no cap of its own kind could be made"); return end
    S.eqView = D.view()
    if S.eqView ~= "doll" then pcall(D.setView, "doll") end
    S.d10 = RT.charTab("equip") and 1 or nil
    if not S.d10 then Q.skip("drag onto the doll", "the Equip tab is not on the strip") end
end)
waitFor(6, 180, function()
    local cw = RT.cw()
    return not S.d10 or (cw ~= nil and cw._activeTab == "equip" and cw._equipDollShown and cw._equipDollAll ~= nil and cw._equipDollPanel ~= nil)
end, function(ok)
    if not S.d10 then return end
    if not ok then S.d10 = nil; Q.skip("drag onto the doll", "the Equip tab's doll does not show at this size"); return end
    H.reveal(H.cc(), S.cap)
end)
step(8, function()
    if not S.d10 then return end
    local cw = RT.cw()
    local loc = nil
    pcall(function() loc = S.cap:getBodyLocation() end)
    local id = nil
    pcall(function() id = ZeD.EquipDoll.slotForLoc(H.normLoc(loc), cw._equipDollBands) end)
    local hit = nil
    for _, r in ipairs(cw._equipDollAll or {}) do if r.id == id then hit = r end end
    local panel, clip = cw._equipDollPanel, cw._equipDollClip
    if not hit then S.d10 = nil; Q.skip("drag onto the doll", "the doll shows no slot for the cap (" .. tostring(id) .. ")"); return end
    local x, y = hit.x + math.floor(hit.w / 2), hit.y + math.floor(hit.h / 2)
    if cw._equipSelected or (clip and not (x >= clip.x and x < clip.x + clip.w and y >= clip.y and y < clip.y + clip.h)) then
        S.d10 = nil; Q.skip("drag onto the doll", "the cap's slot is scrolled out of the doll's view"); return
    end
    local extra = H.at(panel, x, y)
    local ax, ay = panel:getAbsoluteX() + x, panel:getAbsoluteY() + y
    local ok, why = false, "nothing ran"
    -- (the pointer's screen place answers the doll too, so a drop the doll refuses falls on the window, never the floor)
    H.withGlobals({ getMouseX = function() return ax end, getMouseY = function() return ay end }, function()
        if H.zone(H.cc(), S.cap) then
            S.d10how = "dragged from the bag's list"
            ok, why = H.drag(H.cc(), S.cap, nil, extra)
        else
            -- (no list beside the doll at this size: the doll's own drop taker, as the list's drop asks it)
            S.d10how = "handed to the doll's drop taker (the bag's list is not beside the doll here)"
            local took = false
            ok, why = H.over(nil, function() took = ZeD.EquipDoll.takeDrop(S.pn, { S.cap }) end, extra)
            if ok then ok = took and true or false; why = "takeDrop answered " .. tostring(took) end
        end
    end)
    if not Q.check(ok, "the cap is dropped on its slot of the doll", tostring(S.d10how) .. ": " .. tostring(why)) then S.d10 = nil end
end)
waitFor(4, 900, function() return not S.d10 or (H.queueEmpty() and H.wornNow(S.cap)) end, function(ok)
    if not S.d10 then return end
    S.d10w = Q.check(ok, "dropped on the doll's slot, the cap is worn (the game's wear)", "worn " .. tostring(H.wornNow(S.cap)) .. ", in " .. H.typeOf(H.where(S.cap)))
end)
step(12, function()
    S.d10u = nil
    if not S.d10w then return end
    local cw, wc = RT.cw(), H.wc()
    local z = nil
    for _, sz in ipairs(cw._equipSlotZones or {}) do if sz.item == S.cap then z = sz end end
    local drawer = cw._drawerPanel
    if not (z and drawer and wc and H.shows(S.A.inv)) then Q.skip("drag the cap off the doll", "the cap's slot or crate A's list is not on view"); return end
    local ET = ZeD.EquipmentTab
    local took, err = false, nil
    local okP, errP = pcall(function() took = ET.pressSlot(cw, drawer, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end)
    local d = cw._equipDrag
    if not Q.check(okP and took and d ~= nil and d:isPending(), "a press on the worn cap's slot of the doll begins a drag", tostring(errP or "")) then return end
    d:checkThreshold(d.startX + 40, d.startY + 40)
    cw._equipPress = nil
    if not Q.check(d:isActive() and ET.draggedItem(cw) == S.cap, "moved off its slot, the cap is in the air") then H.cancelDrags(); return end
    local px, py = wc:getAbsoluteX() + 20, wc:getAbsoluteY() + math.floor(wc:getHeight() / 2)
    local okR, errR = false, nil
    H.withGlobals({ getMouseX = function() return px end, getMouseY = function() return py end }, function()
        okR, errR = H.over(wc, function() ET.dragRelease(cw, drawer) end)
    end)
    if not okR then S.errs = S.errs + 1 end
    S.d10u = Q.check(okR, "the cap dragged off the doll is released over the crate's list", tostring(errR or ""))
end)
waitFor(4, 900, function() return not S.d10u or (H.queueEmpty() and H.where(S.cap) == S.A.inv) end, function(ok)
    if S.d10u then
        Q.check(ok and not H.wornNow(S.cap), "dragged off the doll into the crate, the cap is off the head and in the crate (the game's transfer)",
            "worn " .. tostring(H.wornNow(S.cap)) .. ", in " .. H.typeOf(H.where(S.cap)))
    end
    H.cancelDrags()
    if S.cap then H.removeItem(S.cap); S.cap = nil end
    H.wornBack()
    pcall(function() RT.cw()._equipSelected = nil end)
    if S.eqView and S.eqView ~= "doll" then pcall(ZeD.EquipDoll.setView, S.eqView) end
    RT.charTab("loot")
end)

-- ===================================================================== 11. bags
step(20, function()
    S.g11 = nil
    S.sbag = H.addUnique(S.bag, { "Base.Bag_Schoolbag", "Base.Bag_NormalHikingBag", "Base.Bag_DuffelBag", "Base.Bag_BigHikingBag" })
    S.inner = H.addUnique(S.bag, { "Base.Bag_FannyPackFront", "Base.Bag_Satchel", "Base.Bag_DoctorBag", "Base.Bag_ToolBag" })
    if not (S.sbag and S.inner) then Q.skip("bags", "two bags of kinds the character does not carry could not be made"); return end
    pcall(function() S.sinv = S.sbag:getInventory(); S.iinv = S.inner:getInventory() end)
    if not (S.sinv and S.iinv) then Q.skip("bags", "the bags have no containers"); return end
    S.innerThing = H.add(S.iinv, "Base.Twine")
    -- worn on the back when the back is free, else carried in the second hand (both are equipped: its button shows)
    local loc = nil
    pcall(function() loc = S.sbag:getBodyLocation() end)
    if loc == nil or tostring(loc) == "" then pcall(function() loc = S.sbag:canBeEquipped() end) end
    local free = false
    pcall(function() free = loc ~= nil and tostring(loc) ~= "" and S.p:getWornItem(loc) == nil end)
    if free then pcall(function() S.p:setWornItem(loc, S.sbag) end) end
    S.sbagHow = "worn"
    if not H.held(S.sbag) then
        pcall(function() S.p:setSecondaryHandItem(S.sbag) end)
        S.sbagHow = "carried in the second hand"
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    pcall(function() RT.cw()._containersDirty = true end)
    H.dirty()
    S.g11 = H.held(S.sbag)
    if not S.g11 then Q.skip("bags", "the bag could not be worn or carried") end
end)
waitFor(4, 300, function() return not S.g11 or H.listed(RT.cw(), S.sinv) end, function(ok)
    if not S.g11 then return end
    if not Q.check(ok, "the equipped bag (" .. tostring(S.sbagHow) .. ") is on the Character window's buttons") then S.g11 = nil end
end)
-- 11a. a full bag takes nothing
step(4, function()
    if not S.g11 then return end
    S.fillers = {}
    local probe = S.planks[1]
    while #S.fillers < 40 and H.room(S.sinv, probe) do
        local it = H.add(S.sinv, "Base.Plank")
        if not it then break end
        S.fillers[#S.fillers + 1] = it
    end
    S.full = not H.room(S.sinv, probe)
    H.dirty()
    H.reveal(H.wc(), H.rep(H.wc(), "Base.Plank"))
end)
step(8, function()
    S.fullGo = nil
    if not S.g11 then return end
    if not S.full then Q.skip("a full bag takes nothing", "the bag still had room after " .. #S.fillers .. " planks"); return end
    local wc, cw = H.wc(), RT.cw()
    local rep = H.rep(wc, "Base.Plank")
    local strip, extra = H.stripAt(cw, S.sinv)
    if not (H.shows(S.A.inv) and rep and H.zone(wc, rep) and strip) then
        Q.skip("a full bag takes nothing", "the planks' row or the bag's button is not on view (row " .. tostring(rep ~= nil) .. ", button " .. tostring(strip ~= nil) .. ")"); return
    end
    S.fullW = S.sinv:getCapacityWeight()
    local ok, why = H.drag(wc, rep, strip, extra)
    S.fullGo = Q.check(ok, "the crate's planks drag and drop on the full bag's button (filled with " .. #S.fillers .. " planks)", why)
end)
waitFor(4, 900, H.queueEmpty, function()
    if S.fullGo then
        local moved = H.count(S.sinv, S.planks)
        local w = S.sinv:getCapacityWeight()
        Q.check(moved == 0 and math.abs(w - S.fullW) < 0.01, "a full bag takes nothing: the planks stay in the crate and the bag's load is the same",
            moved .. " of 3 went in; the bag's load " .. string.format("%.1f", S.fullW) .. " -> " .. string.format("%.1f", w))
    end
    for _, it in ipairs(S.fillers or {}) do H.removeItem(it) end
    for _, it in ipairs(S.planks) do H.put(it, S.A.inv) end
    H.dirty()
    if S.g11 then H.reveal(H.cc(), S.inner) end
end)
-- 11b. a bag with a thing in it into the equipped bag
step(8, function()
    S.bib = nil
    if not S.g11 then return end
    local cc, cw = H.cc(), RT.cw()
    local strip, extra = H.stripAt(cw, S.sinv)
    if not (H.zone(cc, S.inner) and strip and H.room(S.sinv, S.inner)) then
        Q.skip("a bag inside a bag", "the small bag's row or the equipped bag's button is not on view, or there is no room"); return
    end
    local ok, why = H.drag(cc, S.inner, strip, extra)
    S.bib = Q.check(ok, "a bag with a thing in it drags from the list and drops on the equipped bag's button", why)
end)
waitFor(4, 900, function() return not S.bib or (H.queueEmpty() and H.where(S.inner) == S.sinv) end, function(ok)
    if not S.bib then return end
    Q.check(ok and H.where(S.innerThing) == S.iinv and H.size(S.iinv) == 1, "the bag is inside the equipped bag, its own thing still inside it",
        "the small bag is in " .. H.typeOf(H.where(S.inner)) .. ", it holds " .. H.size(S.iinv))
end)
step(8, function()
    if not S.bib then return end
    local okC, whyC = H.drawn(H.cc())
    Q.check(okC and not H.inRows(H.cc(), S.inner), "the bag's list agrees with the inventory once the small bag went inside", whyC)
end)
-- 11c. the equipped bag dropped with everything in it, its column open
step(6, function()
    if not S.g11 then return end
    H.put(S.mover, S.sinv)
    S.colOpen = false
    H.try("toggleColumn on the equipped bag", function() S.colOpen = ZeD_CharacterWindow.toggleColumn(S.sinv, S.pn) end)
end)
step(10, function()
    S.dropped = nil
    if not S.g11 then return end
    local cw = RT.cw()
    S.colN = #(cw._mcSelected or {})
    S.sN, S.iN = H.size(S.sinv), H.size(S.iinv)
    RT.bounds(Q, "the equipped bag's column open")
    -- (the game's own drop, as the menu's Drop and ZeD's drag to the floor call it)
    local ok, err = pcall(function() ISInventoryPaneContextMenu.dropItem(S.sbag, S.pn) end)
    S.dropped = ok
    if not ok then Q.skip("the equipped bag dropped", "the game's drop refused: " .. tostring(err)) end
end)
waitFor(4, 900, function() return not S.dropped or (H.queueEmpty() and H.onFloor(S.sbag)) end, function(ok)
    if not S.dropped then return end
    Q.check(ok and not H.held(S.sbag), "the equipped bag (" .. tostring(S.sbagHow) .. ", a column open on it) is dropped: on the floor, off the character",
        "on the floor " .. tostring(H.onFloor(S.sbag)) .. ", still equipped " .. tostring(H.held(S.sbag)))
    Q.check(H.size(S.sinv) == S.sN and H.size(S.iinv) == S.iN and (not S.bib or H.where(S.inner) == S.sinv),
        "everything inside went down with it (the small bag and its thing too)", "it holds " .. H.size(S.sinv) .. " (was " .. S.sN .. "), the small bag " .. H.size(S.iinv))
end)
waitFor(2, 300, function() return not S.dropped or not H.listed(RT.cw(), S.sinv) end, function(ok)
    if not S.dropped then return end
    local cc = H.cc()
    local cols = 0
    for _, cs in ipairs((cc and cc._colStates) or {}) do if cs.inventory == S.sinv then cols = cols + 1 end end
    Q.check(ok, "the dropped bag leaves the Character window's buttons")
    Q.check(cols == 0 and cc ~= nil and cc._inventory ~= S.sinv, "its open column goes with it: the Character window shows nothing of the bag on the floor",
        cols .. " columns still on it, the list on it " .. tostring(cc ~= nil and cc._inventory == S.sinv) .. " (columns before the drop: " .. tostring(S.colN) .. ")")
    RT.bounds(Q, "after the equipped bag was dropped")
end)
waitFor(2, 300, function() return not S.dropped or H.listed(RT.ww(), S.sinv) end, function(ok)
    if not S.dropped then return end
    Q.check(ok, "the bag on the floor is on the World window's buttons, a container to loot")
    S.pick = false
    if H.onFloor(S.sbag) and H.room(S.bag, S.sbag) then
        H.try("ZeD's floor pickup (transferFromFloor)", function() S.pick = ZeD_WorldWindow.transferFromFloor(S.p, S.sbag, S.bag) end)
    else
        Q.skip("the dropped bag picked up again", "the character carries too much, or the bag is not on the floor")
    end
end)
waitFor(4, 900, function() return not S.pick or (H.queueEmpty() and H.where(S.sbag) == S.bag and not H.onFloor(S.sbag)) end, function(ok)
    if S.pick then
        Q.check(ok and H.size(S.sinv) == S.sN and H.size(S.iinv) == S.iN, "picked up again through ZeD's floor pickup: in the inventory, everything still inside",
            "in " .. H.typeOf(H.where(S.sbag)) .. ", it holds " .. H.size(S.sinv) .. " (was " .. tostring(S.sN) .. ")")
    end
    H.bagsBack()
end)
function H.bagsBack()
    pcall(function() local cw = RT.cw(); if cw and #(cw._mcSelected or {}) > 0 then ZeD_CharacterWindow.closeColumns(cw) end end)
    if S.mover then H.put(S.mover, S.bag) end
    for _, it in ipairs(S.fillers or {}) do H.removeItem(it) end
    S.fillers = nil
    for _, it in ipairs({ S.innerThing or false, S.inner or false, S.sbag or false }) do if it then H.removeItem(it) end end
    S.innerThing, S.inner, S.sbag = nil, nil, nil
    H.handsBack()
    H.wornBack()
    pcall(function() RT.cw()._containersDirty = true end)
    H.dirty()
end
step(10, function()
    local okC, whyC = H.drawn(H.cc())
    Q.check(okC, "the bag's list agrees with the inventory after the bags", whyC)
end)

-- ===================================================================== 12. a pickup's bed, then the car gone
step(6, function()
    S.car, S.carWhy = nil, nil
    S.carT = getTimestampMs()
    if not ZEDQA_CAR_WAIT then S.carWhy = "the prelude's car helpers are not loaded"; return end
    local ok, err = pcall(ZEDQA_CAR_WAIT, "Base.PickUpTruck", "bx_inv", function(v) S.car = v end, function(why) S.carWhy = tostring(why) end)
    if not ok then S.carWhy = tostring(err) end
end)
waitFor(4, 30000, function() return S.car ~= nil or S.carWhy ~= nil or getTimestampMs() - S.carT > 60000 end, function()
    S.bed = nil
    if not S.car then Q.skip("a car's trunk", "no car could be staged: " .. tostring(S.carWhy or "not ready in a minute")); return end
    local c = nil
    pcall(function()
        local part = S.car:getPartById("TruckBed") or S.car:getPartById("TruckBedOpen")
        S.bed = part:getItemContainer()
        c = S.car:getAreaCenter(part:getArea())
    end)
    if not (S.bed and c) then S.bed = nil; Q.skip("a car's trunk", "the pickup has no bed to stand at"); return end
    pcall(function() S.p:teleportTo(c:getX(), c:getY(), 0) end)
    pcall(function() RT.ww()._containerTimer = 30 end)
end)
waitFor(10, 400, function() return not S.bed or H.listed(RT.ww(), S.bed) end, function(ok)
    if not S.bed then return end
    if not Q.check(ok, "standing at the pickup's bed, the bed is on the World window's buttons") then S.bed = nil; return end
    H.show(S.bed)
end)
waitFor(4, 300, function() return not S.bed or H.shows(S.bed) end, function(ok)
    if not S.bed then return end
    if not Q.check(ok, "the World window's list shows the bed") then S.bed = nil; return end
    H.reveal(H.cc(), S.mover)
end)
step(5, function()
    S.bedIn = nil
    if not S.bed then return end
    if not H.zone(H.cc(), S.mover) then Q.skip("drag into the bed", "the thing's row is not on view in the bag"); return end
    local ok, why = H.drag(H.cc(), S.mover, H.wc())
    S.bedIn = Q.check(ok, "a thing drags from the bag and drops on the bed's list", why)
end)
waitFor(4, 900, function() return not S.bedIn or (H.queueEmpty() and H.where(S.mover) == S.bed) end, function(ok)
    if not S.bedIn then return end
    Q.check(ok, "the bed takes it (the game's transfer)", "it is in " .. H.typeOf(H.where(S.mover)))
    H.reveal(H.wc(), S.mover)
end)
step(6, function()
    S.bedOut = nil
    if not (S.bedIn and H.where(S.mover) == S.bed and H.zone(H.wc(), S.mover) and H.room(S.bag, S.mover)) then return end
    local ok, why = H.drag(H.wc(), S.mover, H.cc())
    S.bedOut = Q.check(ok, "the thing drags back out of the bed onto the bag's list", why)
end)
waitFor(4, 900, function() return not S.bedOut or (H.queueEmpty() and H.where(S.mover) == S.bag) end, function(ok)
    if S.bedOut then Q.check(ok, "it is back in the bag", "it is in " .. H.typeOf(H.where(S.mover))) end
    if S.bed then
        local okW, whyW = H.drawn(H.wc())
        Q.check(okW, "the bed's list agrees with the bed", whyW)
        RT.bounds(Q, "at the pickup's bed")
    end
end)
step(6, function()
    S.carGone = nil
    if not (S.car and S.bed) then return end
    H.put(S.mover, S.bag)
    -- (the car is taken away while the World window shows its bed)
    S.bedShown = H.shows(S.bed)
    pcall(ZEDQA_CAR_AWAY, S.car)
    S.carGone = true
end)
waitFor(4, 600, function() return not S.carGone or (not H.listed(RT.ww(), S.bed) and not H.shows(S.bed)) end, function(ok)
    if not S.carGone then return end
    local wc = H.wc()
    local rows = 0
    for _, it in ipairs((wc and wc._flatItems) or {}) do if H.where(it) == S.bed then rows = rows + 1 end end
    Q.check(ok and rows == 0, "the car taken away while its bed showed: the bed is off the buttons, the list on something else, none of its rows left",
        "bed shown before " .. tostring(S.bedShown) .. "; on the buttons " .. tostring(H.listed(RT.ww(), S.bed)) .. ", list on it " .. tostring(H.shows(S.bed)) .. ", " .. rows .. " of its rows")
    RT.bounds(Q, "after the car was taken away")
    S.car = nil
end)
step(4, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_inv") end
    Q.check(S.errs == 0, "nothing ZeD ran for this script threw", S.errs .. " caught")
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.fakeOff()
    H.vanUnhook()
    if S.sampling then pcall(function() Events.OnPostUIDraw.Remove(H.sample) end); S.sampling = nil end
    S.st = nil
    H.cancelDrags()
    pcall(function() local m = getPlayerContextMenu(S.pn); if m and m._zedMenu then m._zedMenu:close() end end)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if S.pausedByMe then H.pause(false) end
    pcall(function() if getGameSpeed() ~= 1 then H.pause(false) end end)
    H.guard()
    H.instant(true)
    if S.car then pcall(ZEDQA_CAR_AWAY, S.car); S.car = nil end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_inv") end
    H.openBoth()
end)
Q.step(20, function()
    local cw, ww = RT.cw(), RT.ww()
    H.down(cw); H.down(ww)
    pcall(function() if cw and #(cw._mcSelected or {}) > 0 then ZeD_CharacterWindow.closeColumns(cw) end end)
    pcall(function() if ww and #(ww._mcSelected or {}) > 0 then ZeD_WorldWindow.closeColumns(ww) end end)
    pcall(function() if cw then cw._equipSelected = nil end end)
    if S.eqView then pcall(ZeD.EquipDoll.setView, S.eqView) end
    H.clearSel(H.cc()); H.clearSel(H.wc())
    pcall(function() local wc = H.wc(); if wc and wc._expandedStacks then wc._expandedStacks[S.bandKey] = nil end end)
    -- the bag's own things, then everything the test made, the crates, the hands and the clothes
    if S.bag and S.bagOrig then H.restoreBag() end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    if S.D then H.rmCrate(S.D) end
    for _, c in ipairs(S.crates) do H.rmCrate(c) end
    H.handsBack()
    H.wornBack()
    H.dirty()
    local st = S.p:getModData().ZeD_GridViews
    if st then for key, v in pairs(S.grid) do if v == NIL then st[key] = nil else st[key] = v end end end
    H.lootTabs()
end)
Q.step(20, function()
    local cw, ww = RT.cw(), RT.ww()
    if S.worldInvWas then pcall(ZeD_WorldWindow.selectContainer, S.worldInvWas, 60, S.pn) end
    for _, inv in ipairs(S.charCols or {}) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
    for _, inv in ipairs(S.worldCols or {}) do pcall(ZeD_WorldWindow.toggleColumn, inv, S.pn) end
    if S.charTabWas and S.charTabWas ~= "loot" then RT.charTab(S.charTabWas) end
    if S.worldTabWas and S.worldTabWas ~= "loot" then RT.worldTab(S.worldTabWas) end
    H.pinsBack()
    H.instant(S.instWas)
    if S.bagOrig then
        local back = 0
        for _, it in ipairs(S.bagOrig) do if H.where(it) == S.bag then back = back + 1 end end
        Q.check(back == #S.bagOrig, "the bag holds all its own things again", back .. " of " .. #S.bagOrig)
    end
    local left, names = 0, ""
    for _, it in ipairs(S.made) do
        local at, fl = H.where(it), H.onFloor(it)
        if at ~= nil or fl then
            left = left + 1
            local ft = "?"
            pcall(function() ft = tostring(it:getFullType()) end)
            if left <= 4 then
                names = names .. "; " .. ft .. " (" .. ((at == S.bag) and "in the bag" or (at and ("in " .. H.typeOf(at)) or "in no container"))
                    .. (fl and ", still has a world object" or "") .. ")"
            end
        end
    end
    Q.check(left == 0, "every thing the test made is gone", left .. " of " .. #S.made .. " left" .. names)
    local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    if S.handWas then Q.check(hp == S.handWas.p and hs == S.handWas.s, "the hands hold what they held") end
    local worn, onNow = 0, H.wornSet()
    for _, e in ipairs(S.worn or {}) do
        if onNow[e.item] then worn = worn + 1 end
    end
    Q.check(worn == #(S.worn or {}), "the character wears what they wore", worn .. " of " .. #(S.worn or {}))
    Q.check(getMouseX ~= nil and S.fake == nil and getGameSpeed() == 1, "the pointer's readings and the game speed are the game's own again", "speed " .. tostring(getGameSpeed()))
end)
Q.step(10, function()
    if S.pairWas == false and S.worldWas == false then
        H.shutBoth()
    elseif S.pairWas == false and RT.isOpen() then
        pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif S.worldWas == false and H.worldOpen() then
        pcall(ZeD_WorldWindow.close, S.pn)
    end
end)
-- the last line, in a step of its own (a fault in a step above cannot skip it): the character is whole
Q.step(4, function()
    H.guard()
    local why = H.hurt()
    local found = why
    if why then
        -- (the game's own full heal, no argument; only when he is hurt: it also resets every stat)
        pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
        why = H.hurt()
    end
    local god, inv = false, false
    pcall(function() god = S.p:isGodMod(); inv = S.p:isInvincible() end)
    Q.check(why == nil, "the character ends whole: alive, health 100, no wound, no fracture, not infected",
        (why or "whole") .. (found and ("; found hurt at the put-back (" .. found .. "), healed by BodyDamage:RestoreToFullHealth()")
            or "; whole when the put-back began, no heal needed") .. "; god mode " .. tostring(god) .. ", invincible " .. tostring(inv))
end)
Q.start()
