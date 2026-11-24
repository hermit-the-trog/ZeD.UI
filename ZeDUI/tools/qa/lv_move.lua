-- ZeDUI/tools/qa/lv_move.lua  (Nov 23 2026, QA; tag lv_move): Loot and inventory, the whole gamut, part one: moving
-- things and containers. The director, Nov 23 2026, after the Health sweep: the same treatment for the loot and the
-- inventory. Run after zedqa_prelude.lua and rt_kit.lua (lv.txt). grep "ZEDQA lv_move".
--
-- On the drag strip two crates stand beside the character (A and B, IsoObjects as rt_inventory makes them); a third
-- free square takes a padlocked crate (an IsoThumpable) for case 9; a car is spawned for case 8 (the prelude's
-- ZEDQA_CAR_WAIT). Everything the test moves is counted by its item id in every container it touches, before and
-- after (S.census / S.audit): nothing lost, nothing doubled, each thing where it should be. Timed actions run instant
-- (the game's own cheat), but for the queued floor grabs of case 10.
-- Already covered elsewhere and not repeated: rt_inventory (sort, list and grid, filter, stacks, box select, a drag to a
-- crate, Move To, Ctrl and Shift picks, double-click, pad X, the band's Loot all, Transfer all, To floor),
-- bx_inventory (stack split, 50 drags, cut-short moves, a crate gone mid-drag, belt, doll, bags, the truck bed),
-- rt_cards (the item card's buttons).
-- Checks:
--   setup     both windows open, the Character window on the main inventory, crates A and B, the World window on A
--   1 same    the bag's Same type puts the bag's things of a kind crate A holds into A; the World band's Same type
--             takes A's things of a kind the bag holds; Same type nearby sends the bag's kind to crate B (which holds
--             it); each counted exactly. Lite: what both bands offer is recorded (a NOTE, never a FAIL: Lite leaves
--             Same type out, ContainerControls.lua liteTrim; the game has TransferSameType / TakeSameType)
--   2 grab    a closed stack of 12 in crate A: the item menu's Grab one, Grab half and Grab all (ZeD's wrapped
--             doGrabMenu): 1, then 5 of the 11 left, then the 6 left, counted
--   3 fav     a favorite stays out of Transfer all; a favorite dragged into crate A stays in the bag (the game's
--             transfer refuses it, ISInventoryTransferAction:transferItem), any message over the head recorded
--   4 held    the thing in the hand and the thing on the belt (the hotbar) stay out of Transfer all, still held
--   5 keyring a key goes onto a key ring by Move To; the key ring stays out of Transfer all, the key still on it;
--             Transfer all counted exactly (everything else moves or stays for want of room)
--   6 bags    a worn backpack and a fanny pack (worn or held): a stack of 5 dragged from one to the other's strip
--             button, then Move To back, counted
--   7 heavy   a generator in crate A: the double-click (quickUse) and Loot all with it alone lift it into the hands
--             with the game's ISEquipHeavyItem, never a plain transfer (the queue is watched)
--   8 car     a car: the trunk from outside (picture lv_move_car_<w>x<h>), then seated in the driver's seat the glove
--             box and a seat: Loot all into the held bag on show and Transfer all back, counted; seated, the World
--             window lists only the car's containers (no Floor); To floor from the World band with the door and window
--             shut: nothing leaves the car and nothing is lost (what happens is recorded)
--   9 locked  a padlocked crate (picture lv_move_locked_<w>x<h>): without the key it is locked in the World window and
--             its world menu has no Loot all; with the key the window opens it and the world menu offers Loot all as
--             the game opens it for the key holder (a FAIL if ZeD hides it: ItemMenu.lua padlocked())
--   10 floor  a drag released over the world drops on the floor; seven heavy things (over 50 kg) dropped spill to the
--             next squares (no square past 50 but a lone heavy thing); three floor grabs queued, then a walk of five
--             squares away and back: every thing in the bag or still on the floor, none lost
--   11 put in the item menu's "Put in <container>" (the game's, left in by ItemMenu.lua): with crate B then A shown,
--             which container it names and where the thing goes (a FAIL if anywhere but the container on show)
--   12 loot   Loot all with a worn backpack on show in the Character window: the check is "Loot all puts the things
--             in the main inventory, as the game does"; a FAIL is a design call for the director (ZeD sends them to
--             the bag on show)
--   13 shut   Transfer all on the player's side with the World window shut: on or off, checked against the game's
--             (a design call for the director)
--   14 refuse Move To on a held thing into a container that refuses it (a gate) and into a full crate: the thing
--             stays held or lands in the crate, never unequipped and left (ItemMenu.lua onMove)
--   15 back   Put things back after an action, on for this case only: an apple eaten from crate A while another
--             thing is picked up from A in the same tick: the other thing stays in the bag (ZeD_PutBack.lua finish)
--   each case no Lua error over it; put back exactly (the census restored, the case's things removed)
-- Puts back: every thing the bag held, where it was; every thing the test made removed (the containers, the floor, the
-- hands, the belt); crates A and B and the padlocked crate removed; the car away; the character where he stood, facing
-- as found, the hands and the clothes as found; Style, Put things back, the instant cheat, the game speed, the grid
-- choices, the World window's container, the columns, the tabs and the pair as found; the queue, gates, pointer and
-- the queue and halo watches the game's own again.
if not RT then print("ZEDQA lv_move ERR rt_kit.lua did not run first"); print("ZEDQA lv_move DONE"); return end
local Q = RT.make("lv_move")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, crates = {}, grid = {}, used = {},
            box = {}, held = {}, errs = 0, t0 = getTimestampMs() }

S.KEY_ID = 7712903
S.SMALL = { "Base.Thread", "Base.Twine", "Base.Screws", "Base.DuctTape", "Base.Glue", "Base.Woodglue", "Base.Scotchtape",
            "Base.Paperclip", "Base.RubberBand", "Base.Pencil", "Base.Pen", "Base.Eraser", "Base.Battery", "Base.Matches",
            "Base.Candle", "Base.Sponge", "Base.Comb", "Base.Toothbrush", "Base.Spoon", "Base.Fork", "Base.Button",
            "Base.Charcoal", "Base.Cork", "Base.Twigs", "Base.Dice", "Base.Earbuds", "Base.Teabag2", "Base.SugarPacket" }
S.TOOLS = { "Base.Hammer", "Base.Screwdriver", "Base.Wrench", "Base.Saw", "Base.Crowbar", "Base.HandAxe", "Base.Spatula",
            "Base.Ladle", "Base.Whisk", "Base.RollingPin" }
S.BACKS = { "Base.Bag_Schoolbag", "Base.Bag_NormalHikingBag", "Base.Bag_DuffelBag", "Base.Bag_BigHikingBag" }
S.FRONTS = { "Base.Bag_FannyPackFront", "Base.Bag_Satchel", "Base.Bag_DoctorBag" }
S.HEAVY = { "Base.Log", "Base.BucketConcreteFull", "Base.Plank" }

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.cc() local w = RT.cw(); return w and w._mainContent or nil end
function S.wc() local w = RT.ww(); return w and w._mainContent or nil end
function S.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function S.list(inv)
    local out = {}
    if inv == nil then return out end
    pcall(function()
        local it = inv:getItems()
        for i = 0, it:size() - 1 do out[#out + 1] = it:get(i) end
    end)
    return out
end
function S.size(inv) local n = -1; if inv then pcall(function() n = inv:getItems():size() end) end; return n end
function S.where(it) local c = nil; if it then pcall(function() c = it:getContainer() end) end; return c end
function S.ft(it) local s = "?"; if it then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function S.idOf(it) local id = nil; if it then pcall(function() id = it:getID() end) end; return id or tostring(it) end
function S.onFloor(it) local wo = nil; if it then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
function S.held(it)
    local h = false
    if it then pcall(function() h = it:isEquipped() or S.p:isEquipped(it) end) end
    return h and true or false
end
function S.queueLen()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue and #q.queue) or 0
end
function S.queueEmpty() return S.queueLen() == 0 end
-- a condition that holds once the queue stayed empty k frames in a row (a put-back or a walk may queue more)
function S.settled(k)
    local st = { n = 0 }
    return function()
        if S.queueEmpty() then st.n = st.n + 1 else st.n = 0 end
        return st.n >= (k or 8)
    end
end
function S.room(inv, it)
    local r = true
    if inv and it then pcall(function() r = inv:hasRoomFor(S.p, it) end) end
    return r and true or false
end
function S.typeOf(inv)
    if inv == nil then return "nothing" end
    local t = "nothing"; pcall(function() t = tostring(inv:getType()) end); return t
end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.has(s, sub) return type(s) == "string" and string.find(s, sub, 1, true) ~= nil end
function S.dirty()
    pcall(function() ZeD.InventoryRenderer.dirtyModels() end)
    pcall(function() ISInventoryPage.dirtyUI() end)
    pcall(function() local w = RT.cw(); if w then w._containersDirty = true; w._containerTimer = 30 end end)
    pcall(function() local w = RT.ww(); if w then w._containerTimer = 30 end end)
end
function S.instant(on) pcall(function() S.p:setTimedActionInstantCheat(on and true or false) end) end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.setOpt(o, v) if o and v ~= nil then pcall(function() o:setValue(v) end) end end
function S.guard()
    pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true) end end)
    pcall(function() if not S.p:isInvincible() then S.p:setInvincible(true) end end)
end
function S.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function S.withGlobals(over, fn)
    local was = {}
    for k, v in pairs(over) do was[k] = _G[k]; _G[k] = v end
    local ok, err = pcall(fn)
    for k, v in pairs(was) do _G[k] = v end
    return ok, err
end

-- ===================================================================== things: made, moved, taken away
function S.loose(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    pcall(function()
        if (it:getAttachedSlot() or -1) > -1 then
            S.p:removeAttachedItem(it)
            it:setAttachedSlot(-1)
            it:setAttachedSlotType(nil)
            it:setAttachedToModel(nil)
        end
    end)
end
function S.removeItem(it)
    if not it then return end
    S.loose(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
-- a thing set in a container by hand (worn and held things left alone when they are already there)
function S.put(it, inv)
    if not (it and inv) then return end
    if S.where(it) == inv and not S.onFloor(it) then return end
    S.removeItem(it)
    pcall(function() inv:AddItem(it) end)
end
function S.mark(it)
    if not it then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function S.give(ft) local it = RT.give(ft); return S.mark(it) end
function S.add(inv, ft)
    local it = nil
    pcall(function() it = inv:AddItem(ft) end)
    return S.mark(it)
end
function S.known(ft)
    local ok = false
    pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end)
    return ok
end
-- a kind the character carries none of and the test has not used yet
function S.unique(kinds)
    local own = S.p:getInventory()
    for _, ft in ipairs(kinds) do
        if not S.used[ft] and S.known(ft) then
            local have = 1
            pcall(function() have = own:getCountTypeRecurse(ft) end)
            if have == 0 then S.used[ft] = true; return ft end
        end
    end
    return nil
end
function S.caseClean()
    for _, it in ipairs(S.caseMade) do S.removeItem(it) end
    S.caseMade = {}
    S.restoreBag()
    S.handsBack()
    S.wornBack()
    S.dirty()
end
function S.restoreBag()
    local back = 0
    for _, it in ipairs(S.bagOrig or {}) do
        if S.where(it) ~= S.bag then
            S.removeItem(it)
            pcall(function() S.bag:AddItem(it) end)
            back = back + 1
        end
    end
    return back
end
function S.handsBack()
    local h = S.found.hands
    if not h then return end
    pcall(function() if S.p:getPrimaryHandItem() ~= h.p then S.p:setPrimaryHandItem(h.p) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= h.s then S.p:setSecondaryHandItem(h.s) end end)
end
function S.wornList()
    local out = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            out[#out + 1] = { loc = w:getLocation(), item = w:getItem() }
        end
    end)
    return out
end
function S.wornSet()
    local set = {}
    for _, e in ipairs(S.wornList()) do set[e.item] = true end
    return set
end
function S.wornBack()
    local on = S.wornSet()
    for _, e in ipairs(S.found.worn or {}) do
        if not on[e.item] and S.where(e.item) == S.p:getInventory() then
            pcall(function() S.p:setWornItem(e.loc, e.item) end)
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
end
-- worn where its place is free, else held in the second hand (both put its button on the strip); how it went
function S.wearOrHold(bag)
    local loc = nil
    pcall(function() loc = bag:getBodyLocation() end)
    local free = false
    pcall(function() free = loc ~= nil and tostring(loc) ~= "" and S.p:getWornItem(loc) == nil end)
    if free then pcall(function() S.p:setWornItem(loc, bag) end) end
    local how = "worn"
    local worn = false
    pcall(function() worn = S.p:isEquippedClothing(bag) end)
    if not worn then
        -- (the second hand, unless a bag of this test already took it: then the main hand)
        local s = S.p:getSecondaryHandItem()
        if s ~= nil and S.inList(S.caseMade, s) then
            pcall(function() S.p:setPrimaryHandItem(bag) end)
            how = "held in the main hand"
        else
            pcall(function() S.p:setSecondaryHandItem(bag) end)
            how = "held in the second hand"
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    S.dirty()
    return how
end

-- ===================================================================== the census: every thing by its id
-- list = { { key = "bag", inv = <ItemContainer> } or { key = "floor", floor = true, x, y, z, r } }
function S.floorItems(x, y, z, r)
    local out = {}
    for dy = -r, r do
        for dx = -r, r do
            local sq = getCell():getGridSquare(x + dx, y + dy, z)
            if sq then
                pcall(function()
                    local wobs = sq:getWorldObjects()
                    for i = 0, wobs:size() - 1 do
                        local it = wobs:get(i):getItem()
                        if it then out[#out + 1] = it end
                    end
                end)
            end
        end
    end
    return out
end
function S.itemsAt(e)
    if e.floor then return S.floorItems(e.x, e.y, e.z, e.r) end
    return S.list(e.inv)
end
function S.census(list)
    local c = { list = list, at = {}, item = {}, n = 0, dup = {}, key = {} }
    for _, e in ipairs(list) do
        c.key[e.key] = e
        for _, it in ipairs(S.itemsAt(e)) do
            local id = S.idOf(it)
            if c.at[id] then c.dup[#c.dup + 1] = S.ft(it) .. " " .. tostring(id) .. " in " .. c.at[id] .. " and " .. e.key
            else c.at[id] = e.key; c.item[id] = it; c.n = c.n + 1 end
        end
    end
    return c
end
function S.whereText(it)
    local c = S.where(it)
    if S.onFloor(it) then
        local s = "on the floor"
        pcall(function() local sq = it:getWorldItem():getSquare(); s = "on the floor at " .. sq:getX() .. "," .. sq:getY() end)
        return s
    end
    if c == nil then return "in no container and not on the floor (LOST)" end
    if c == S.bag then return "in the main inventory" end
    return "outside the counted containers (in " .. S.typeOf(c) .. ")"
end
-- every thing counted in c0, now: where want(item, wasKey) says (nil: where it was; "gone": used up); a thing that
-- stayed where it was because the target had no room is let be when noRoom is true. Returns ok and the detail.
function S.audit(c0, want, noRoom)
    local c1 = S.census(c0.list)
    local bad, moved, kept, roomy = {}, 0, 0, 0
    for _, d in ipairs(c1.dup) do bad[#bad + 1] = "TWICE: " .. d end
    for id, k0 in pairs(c0.at) do
        local it = c0.item[id]
        local w = (want and want(it, k0)) or k0
        local k1 = c1.at[id]
        if w == "gone" then
            if k1 ~= nil then bad[#bad + 1] = S.ft(it) .. " " .. tostring(id) .. " not used up (in " .. k1 .. ")" end
        elseif k1 == w then
            if w ~= k0 then moved = moved + 1 else kept = kept + 1 end
        elseif k1 == k0 and noRoom and c0.key[w] and c0.key[w].inv and not S.room(c0.key[w].inv, it) then
            roomy = roomy + 1
        elseif k1 == nil then
            bad[#bad + 1] = S.ft(it) .. " " .. tostring(id) .. " " .. S.whereText(it) .. " (was in " .. k0 .. ", wanted in " .. w .. ")"
        else
            bad[#bad + 1] = S.ft(it) .. " " .. tostring(id) .. " in " .. k1 .. " (was in " .. k0 .. ", wanted in " .. w .. ")"
        end
    end
    local extra = 0
    for id, k1 in pairs(c1.at) do
        if c0.at[id] == nil then
            extra = extra + 1
            if extra <= 3 then bad[#bad + 1] = "new in " .. k1 .. ": " .. S.ft(c1.item[id]) end
        end
    end
    local head = c0.n .. " things counted: " .. moved .. " moved as wanted, " .. kept .. " stayed as wanted"
        .. ((roomy > 0) and (", " .. roomy .. " stayed for want of room") or "") .. ((extra > 0) and (", " .. extra .. " new") or "")
    if #bad == 0 then return true, head end
    local shown = {}
    for i = 1, math.min(#bad, 6) do shown[i] = bad[i] end
    return false, head .. "; " .. #bad .. " wrong: " .. table.concat(shown, "; ")
end
-- every thing of a census back where it was (the floor's own things are left on the floor)
function S.restoreTo(c0)
    if not c0 then return end
    for id, k0 in pairs(c0.at) do
        local e = c0.key[k0]
        if e and e.inv and not e.floor then S.put(c0.item[id], e.inv) end
    end
    S.dirty()
end
function S.countKind(inv, ft)
    local n = 0
    for _, it in ipairs(S.list(inv)) do if S.ft(it) == ft then n = n + 1 end end
    return n
end
function S.bx(key, inv) return { key = key, inv = inv } end
function S.floorBox(r)
    return { key = "floor", floor = true, x = math.floor(S.p:getX()), y = math.floor(S.p:getY()), z = math.floor(S.p:getZ()), r = r or 1 }
end

-- ===================================================================== the lists, the bands, drags, the menu
function S.zone(c, id)
    for _, z in ipairs(c and c._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function S.reveal(c, item)
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
-- the row that stands for a kind's closed stack
function S.rep(c, key)
    for _, it in ipairs(c and c._flatItems or {}) do
        local st = c._stacks and c._stacks[it]
        if st and st.key == key and not (c._childParent and c._childParent[it]) then return it, st end
    end
    return nil, nil
end
function S.listed(win, inv)
    for _, e in ipairs((win and win._containers) or {}) do if e.inventory == inv then return true end end
    return false
end
function S.entryOf(win, inv)
    for _, e in ipairs((win and win._containers) or {}) do if e.inventory == inv then return e end end
    return nil
end
function S.show(inv) if inv then pcall(ZeD_WorldWindow.selectContainer, inv, 200, S.pn) end end
function S.shows(inv) local wc = S.wc(); return wc ~= nil and inv ~= nil and wc._inventory == inv end
function S.showBag(inv)
    if inv then pcall(ZeD_CharacterWindow.showBagAlone, S.pn, inv) end
end
function S.charShows(inv) local cc = S.cc(); return cc ~= nil and inv ~= nil and cc._inventory == inv end
-- the bands built again on their next draw
function S.rebuild()
    for _, c in ipairs({ S.cc(), S.wc() }) do
        if c and c._cc then c._cc.frame = -1000 end
    end
end
function S.spec(c, id)
    for _, m in ipairs((c and c._cc and c._cc.moves) or {}) do if m.id == id then return m end end
    return nil
end
function S.specIds(c)
    local t = {}
    for _, m in ipairs((c and c._cc and c._cc.moves) or {}) do t[#t + 1] = tostring(m.id) .. (m.enabled and "" or " (off)") end
    return #t > 0 and table.concat(t, ", ") or "none"
end
function S.specText(sp) if not sp then return "no such button" end; return tostring(sp.label) .. (sp.enabled and " (on)" or " (off)") end
-- a band button pressed as a click presses it (or as the pad's A when it is scrolled out of its ribbon)
function S.press(c, id)
    local cc = c and c._cc
    for i, h in ipairs(cc and cc.hits or {}) do
        if h.spec and h.spec.id == id then
            if not h.spec.enabled then return false, tostring(h.spec.label) .. " is off" end
            local z = S.zone(c, "cc:" .. i)
            local ok, err = pcall(function()
                if z and z.w > 0 then c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
                else ZeD.ContainerControls.press(c, i) end
            end)
            if not ok then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(err) end
            return true, tostring(h.spec.label)
        end
    end
    if id == "take" and c ~= nil and c._colStates ~= nil and #c._colStates > 0 then
        for _, z in ipairs(c._hitZones or {}) do
            if type(z.id) == "string" and z.id:sub(1, 13) == "view:lootall:" then
                local ok = pcall(function() ZeD.InventoryRenderer.onViewZone(z.id, c) end)
                return ok, "Loot all (the column's foot)"
            end
        end
    end
    return false, "no button " .. id
end
-- every drop target answers "the pointer is not over me" but target; extra: more answers { object, key, value }
function S.over(target, fn, extra)
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
    local hud = nil
    pcall(function() hud = ZeD.Belt.getHUD(S.pn) end)
    if hud and hud ~= target then set(hud, "getMouseX", function() return -1 end) end
    for _, e in ipairs(extra or {}) do set(e[1], e[2], e[3]) end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do local s = saved[i]; s[1][s[2]] = s[3] end
    return ok, err
end
function S.at(o, x, y)
    return { { o, "getMouseX", function() return x end }, { o, "getMouseY", function() return y end } }
end
function S.stripAt(win, inv)
    local strip = win and win._containerStrip
    if not strip then return nil end
    local idx, main = nil, false
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then idx = i; main = c.isMain and true or false end
    end
    if not idx then return nil end
    for _, z in ipairs(strip._hitZones or {}) do
        if z.id == idx or z.id == ("cnt:" .. idx) or (main and z.id == "main_toggle") then
            return strip, S.at(strip, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)), z
        end
    end
    return nil
end
function S.grab(src, item)
    local z = S.zone(src, item)
    if not z then return false, "the row is not on screen" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    src._zedLastClick = nil
    local okD, errD = pcall(function() src:onMouseDown(x, y) end)
    if not okD then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(errD) end
    local d = src._drag
    if not (d and d:isPending()) then return false, "the press began no drag" end
    d:checkThreshold(d.startX + 40, d.startY + 40)
    if not d:isActive() then pcall(function() d:cancel() end); return false, "the drag did not start" end
    S.grabAt = { x, y }
    return true, "in the air"
end
function S.let(src, target, extra)
    local g = S.grabAt or { 0, 0 }
    local ok, err = S.over(target, function() src:onMouseUpOutside(g[1], g[2]) end, extra)
    if not ok then S.errs = S.errs + 1 end
    return ok, ok and "dropped" or ("the release threw: " .. tostring(err))
end
function S.drag(src, item, target, extra)
    local ok, why = S.grab(src, item)
    if not ok then return false, why end
    return S.let(src, target, extra)
end
-- released over the world: nothing under the pointer, the pointer over no window
function S.dragToWorld(src, item)
    local ok, why = S.grab(src, item)
    if not ok then return false, why end
    local g = S.grabAt or { 0, 0 }
    local okR, err = S.withGlobals({ getMouseX = function() return -60 end, getMouseY = function() return -60 end }, function()
        local ok2, e2 = S.over(nil, function() src:onMouseUpOutside(g[1], g[2]) end)
        if not ok2 then error(e2) end
    end)
    if not okR then S.errs = S.errs + 1 end
    return okR, okR and "released over the world" or ("the release threw: " .. tostring(err))
end
function S.cancelDrags()
    for _, c in ipairs({ S.cc(), S.wc() }) do
        pcall(function() local d = c._drag; if d and (d:isActive() or d:isPending()) then d:cancel(); c:setCapture(false) end end)
    end
    pcall(function() ISMouseDrag.dragging = nil end)
end
-- the item menu: the game's createMenu (ZeD's menu is built from it on its next draw)
function S.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function S.closeMenu()
    local m = S.menu()
    if m then pcall(function() m:close() end) end
    pcall(function() local v = getPlayerContextMenu(S.pn); if v then v:hideAndChildren() end end)
end
function S.openMenu(items, inInv)
    S.closeMenu()
    local w, h = S.screen()
    local ok, err = pcall(function() ISInventoryPaneContextMenu.createMenu(S.pn, inInv, items, math.floor(w / 2), math.floor(h / 2)) end)
    if not ok then S.errs = S.errs + 1 end
    return ok, err
end
function S.same(a, b) return a == b or string.lower(tostring(a)) == string.lower(tostring(b)) end
function S.defNames(defs)
    local t = {}
    for _, d in ipairs(defs or {}) do t[#t + 1] = tostring(d and d.name) end
    return table.concat(t, ", ")
end
-- the vanilla option behind a ZeD menu's row path, or nil
function S.findDef(m, names)
    local defs = m and m._ctx and m._ctx.actions or {}
    local d = nil
    for _, nm in ipairs(names) do
        d = nil
        for _, x in ipairs(defs) do if not d and x and S.same(x.name, nm) then d = x end end
        if not d then return nil end
        defs = d.children or {}
    end
    return d
end
-- choose each name in turn (a submenu, then its row) and confirm it, as the menu's click does
function S.pick(m, names)
    if not m then return false, "no menu" end
    if m._levels then
        for depth, nm in ipairs(names) do
            local lv = m._levels[depth]
            if not lv then return false, "no level " .. depth end
            local ri, defs = nil, {}
            for k, r in ipairs(lv.rows or {}) do
                if r.def then defs[#defs + 1] = r.def; if not ri and S.same(r.def.name, nm) then ri = k end end
            end
            if not ri then return false, "no row " .. tostring(nm) .. " in: " .. S.defNames(defs) end
            lv.sel = ri
            m:confirm(depth)
        end
        return true, "picked"
    end
    for _, nm in ipairs(names) do
        local items = m._ctx.items or m:_currentItems()
        local idx = nil
        for i, d in ipairs(items) do if not idx and d and S.same(d.name, nm) then idx = i end end
        if not idx then return false, "no cell " .. tostring(nm) .. " in: " .. S.defNames(items) end
        m._ctx.selected = idx
        m:confirm()
    end
    return true, "picked"
end
function S.menuNames(m)
    local out = {}
    local function walk(defs)
        for _, d in ipairs(defs or {}) do
            out[#out + 1] = tostring(d.name)
            if d.children then walk(d.children) end
        end
    end
    walk(m and m._ctx and m._ctx.actions)
    return out
end
-- the game's own option behind a vanilla handler (its name), from the menu ZeD was built from
function S.ctxOptionBy(onSelect)
    local found = nil
    pcall(function()
        local c = getPlayerContextMenu(S.pn)
        for _, o in ipairs(c.options or {}) do if not found and o.onSelect == onSelect then found = o end end
    end)
    return found
end
function S.ctxTopNames()
    local t = {}
    pcall(function()
        local c = getPlayerContextMenu(S.pn)
        for _, o in ipairs(c.options or {}) do t[#t + 1] = tostring(o.name) end
    end)
    return t
end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end

-- ===================================================================== crates
function S.freeSquares()
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local free = {}
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x + d[1], y + d[2], z)
        local ok = sq ~= nil
        if sq then pcall(function() ok = sq:isFree(false) end) end
        if ok then free[#free + 1] = sq end
    end
    return free
end
function S.mkCrate(sq, label)
    local c = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        local inv = o:getContainer()
        if inv then
            pcall(function() inv:setExplored(true) end)
            c = { obj = o, inv = inv, sq = sq, label = label }
        end
    end)
    if c then S.crates[#S.crates + 1] = c end
    return c
end
-- a padlocked crate: an IsoThumpable, as the game's carpentry builds one, locked with its key id
function S.mkLocked(sq)
    local c, err = nil, nil
    local ok, e = pcall(function()
        local spr = "carpentry_01_16"
        local o = IsoThumpable.new(getCell(), sq, spr, false, ISSimpleFurniture:new("Crate", spr, spr))
        o:setIsContainer(true)
        o:getContainer():setType("crate")
        sq:AddTileObject(o)
        o:setCanBeLockByPadlock(true)
        o:setLockedByPadlock(true)
        o:setKeyId(S.KEY_ID)
        local inv = o:getContainer()
        pcall(function() inv:setExplored(true) end)
        c = { obj = o, inv = inv, sq = sq, label = "the padlocked crate" }
    end)
    if not ok then err = tostring(e) end
    if c then S.crates[#S.crates + 1] = c end
    return c, err
end
function S.rmCrate(c)
    if not (c and c.obj) then return end
    pcall(function()
        local sq = c.obj:getSquare() or c.sq
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(c.obj) end); sq:RemoveTileObject(c.obj) end
    end)
    c.obj = nil
    pcall(function() RT.ww()._containerTimer = 30 end)
end
function S.listView(inv)
    local st = S.p:getModData().ZeD_GridViews or {}
    S.p:getModData().ZeD_GridViews = st
    local key = nil
    pcall(function() key = ZeD.InventoryRenderer.containerKey(inv, S.p) end)
    if key and S.grid[key] == nil then
        if st[key] == nil then S.grid[key] = "NIL" else S.grid[key] = st[key] end
        pcall(function() ZeD.InventoryRenderer.setGridKey(key, false, S.p) end)
    end
end

-- ===================================================================== the queue and the head, watched
function S.qOn()
    if S.qOrig then return end
    S.qLog = {}
    S.qOrig = ISTimedActionQueue.add
    local orig = S.qOrig
    S.qMine = function(action, a2, a3, a4)
        local t, it = nil, nil
        pcall(function() t = action and action.Type; it = action and action.item end)
        S.qLog[#S.qLog + 1] = { t = tostring(t), item = it }
        return orig(action, a2, a3, a4)
    end
    ISTimedActionQueue.add = S.qMine
end
function S.qOff()
    if not S.qOrig then return end
    if ISTimedActionQueue.add == S.qMine then ISTimedActionQueue.add = S.qOrig end
    S.qOrig, S.qMine = nil, nil
end
function S.qHas(t, item)
    for _, e in ipairs(S.qLog or {}) do if e.t == t and (item == nil or e.item == item) then return true end end
    return false
end
function S.qText()
    local t = {}
    for i, e in ipairs(S.qLog or {}) do if i <= 8 then t[#t + 1] = e.t end end
    return #t > 0 and table.concat(t, ", ") or "nothing queued"
end
S.HALO_FNS = { "addText", "addBadText", "addGoodText", "addTextWithArrow" }
function S.haloOn()
    if S.halo or not HaloTextHelper then return end
    S.halo = { said = {}, own = {} }
    for _, fn in ipairs(S.HALO_FNS) do
        local orig = HaloTextHelper[fn]
        if orig then
            S.halo.own[fn] = orig
            HaloTextHelper[fn] = function(a1, a2, a3, a4, a5, a6)
                S.halo.said[#S.halo.said + 1] = fn .. " \"" .. tostring(a2) .. "\""
                return orig(a1, a2, a3, a4, a5, a6)
            end
        end
    end
end
function S.haloOff()
    if not S.halo then return end
    for fn, orig in pairs(S.halo.own) do HaloTextHelper[fn] = orig end
    S.halo = nil
end

-- ===================================================================== pictures
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
function S.caseEnd(label)
    Q.step(1, function()
        if S.dead then return end
        S.cancelDrags()
        S.closeMenu()
        local e1 = S.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        S.e0 = e1
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        S.e0 = S.err0
        f.pair = RT.isOpen()
        f.world = S.worldOpen()
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "lv_move") end
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat() end)
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.worn = S.wornList()
        f.style = S.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)
        f.putBack = S.optVal(ZeD.Settings and ZeD.Settings.putBackOption)
        pcall(function() f.speed = getGameSpeed() end)
        f.recorded = true
        S.back.on = true
        S.guard()
        if not (RT.isOpen() and S.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
        S.instant(true)
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", Style " .. tostring(f.style)
            .. ", Put things back " .. tostring(f.putBack) .. ", screen " .. S.sizeTag())
    end)
    S.step(30, function()
        local cw, ww = RT.cw(), RT.ww()
        if not Q.check(cw ~= nil and ww ~= nil, "setup: both windows are open") then S.dead = true; return end
        local f = S.found
        f.charTab, f.worldTab = cw._activeTab, ww._activeTab
        f.charCols, f.worldCols = {}, {}
        for _, j in ipairs(cw._mcSelected or {}) do local e = cw._containers[j]; if e then f.charCols[#f.charCols + 1] = e.inventory end end
        for _, j in ipairs(ww._mcSelected or {}) do local e = ww._containers[j]; if e then f.worldCols[#f.worldCols + 1] = e.inventory end end
        if #f.charCols > 0 then pcall(ZeD_CharacterWindow.closeColumns, cw) end
        if #f.worldCols > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
        RT.charTab("loot")
        if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
    end)
    S.step(20, function()
        S.bag = S.p:getInventory()
        local cc, wc = S.cc(), S.wc()
        S.found.worldInv = wc and wc._inventory
        S.found.charInv = cc and cc._inventory
        if not S.charShows(S.bag) then S.showBag(S.bag) end
        S.bagOrig = S.list(S.bag)
        local free = S.freeSquares()
        S.A = free[1] and S.mkCrate(free[1], "crate A")
        S.B = free[2] and S.mkCrate(free[2], "crate B")
        S.spare = { free[3], free[4], free[5] }
        if not Q.check(S.A ~= nil and S.B ~= nil, "setup: crates A and B stand beside the character", #free .. " free squares round him") then S.dead = true; return end
        S.box.bag = S.bx("bag", S.bag)
        S.box.A = S.bx("crate A", S.A.inv)
        S.box.B = S.bx("crate B", S.B.inv)
        for _, inv in ipairs({ S.bag, S.A.inv, S.B.inv }) do S.listView(inv) end
        S.show(S.A.inv)
    end)
    S.wait(10, 600, function() return S.shows(S.A.inv) and S.charShows(S.bag) end, function(ok)
        local e = S.entryOf(RT.ww(), S.A.inv)
        S.A.name = e and e.name
        if not Q.check(ok, "setup: the World window shows crate A and the Character window the main inventory",
            "World on " .. S.typeOf(S.wc() and S.wc()._inventory) .. ", Character on the main inventory " .. tostring(S.charShows(S.bag))) then S.dead = true end
    end)
end

-- ===================================================================== 1. Same type, Same type nearby; Lite
function S.case1()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        T.k1, T.k2, T.k3 = S.unique(S.SMALL), S.unique(S.SMALL), S.unique(S.SMALL)
        if not (T.k1 and T.k2 and T.k3) then T.off = true; Q.skip("1 Same type", "three small kinds he carries none of could not be found"); return end
        -- (a kind on both sides moves both ways: the bag's Same type takes every kind crate A holds, so each move gets
        -- a kind of its own, the World band's K2 staged only after the bag's move)
        for _ = 1, 3 do S.give(T.k1) end
        for _ = 1, 2 do S.give(T.k3) end
        S.add(S.A.inv, T.k1)
        S.add(S.B.inv, T.k3)
        S.dirty()
        S.show(S.A.inv)
        S.rebuild()
    end)
    S.wait(8, 300, function()
        return T.off or (S.shows(S.A.inv) and S.spec(S.cc(), "same") ~= nil and S.spec(S.cc(), "same").enabled and S.spec(S.wc(), "same") ~= nil)
    end, function(ok)
        if T.off then return end
        T.c0 = S.census({ S.box.bag, S.box.A, S.box.B, S.floorBox(1) })
        local sp = S.spec(S.cc(), "same")
        if not Q.check(ok, "1 Same type: the bag's band offers Same type, on, with crate A shown", S.specText(sp) .. "; band: " .. S.specIds(S.cc())) then T.off = true; return end
        local okP, why = S.press(S.cc(), "same")
        T.a = Q.check(okP, "1 Same type: the bag's Same type presses", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if T.off or not T.a then return end
        local ok, d = S.audit(T.c0, function(it, k0) if k0 == "bag" and S.ft(it) == T.k1 then return "crate A" end end, true)
        Q.check(ok, "1 Same type (the bag's band): the bag's " .. T.k1 .. " (3) go into crate A, which holds that kind; nothing else moves", d)
        S.give(T.k2)
        for _ = 1, 2 do S.add(S.A.inv, T.k2) end
        S.dirty()
        T.c1 = S.census(T.c0.list)
        S.rebuild()
    end)
    S.wait(6, 200, function() return T.off or (S.spec(S.wc(), "same") ~= nil and S.spec(S.wc(), "same").enabled) end, function(ok)
        if T.off then return end
        local okP, why = false, "the World band's Same type is off: " .. S.specText(S.spec(S.wc(), "same"))
        if ok then okP, why = S.press(S.wc(), "same") end
        T.b = Q.check(okP, "1 Same type: the World band's Same type presses (crate A holds the bag's " .. T.k2 .. ")", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if T.off or not T.b then return end
        local ok, d = S.audit(T.c1, function(it, k0) if k0 == "crate A" and S.ft(it) == T.k2 then return "bag" end end, true)
        Q.check(ok, "1 Same type (the World band): crate A's " .. T.k2 .. " (2) come to the bag, which holds that kind; nothing else moves", d)
        T.c2 = S.census(T.c0.list)
        S.rebuild()
    end)
    S.wait(6, 200, function() return T.off or (S.spec(S.cc(), "near") ~= nil and S.spec(S.cc(), "near").enabled) end, function(ok)
        if T.off then return end
        local okP, why = false, "Same type nearby is off or missing: " .. S.specText(S.spec(S.cc(), "near"))
        if ok then okP, why = S.press(S.cc(), "near") end
        T.c = Q.check(okP, "1 Same type nearby: the bag's band presses it (crate B holds " .. T.k3 .. ")", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if T.off or not T.c then return end
        local ok, d = S.audit(T.c2, function(it, k0) if k0 == "bag" and S.ft(it) == T.k3 then return "crate B" end end, true)
        Q.check(ok, "1 Same type nearby: the bag's " .. T.k3 .. " (2) go into crate B, the container nearby that holds that kind; nothing else moves", d)
        -- Lite: the value only (as rt_inventory's tile check does), both bands built again
        T.style = S.optVal(ZeD.Settings.lookStyleOption)
        S.setOpt(ZeD.Settings.lookStyleOption, 2)
        S.rebuild()
    end)
    Q.step(12, function()
        if S.dead or T.off then return end
        local lite = false
        pcall(function() lite = ZeD.Settings.lite() end)
        local cIds, wIds = S.specIds(S.cc()), S.specIds(S.wc())
        local sameC, sameW = S.spec(S.cc(), "same") ~= nil, S.spec(S.wc(), "same") ~= nil
        Q.check(lite and S.cc() ~= nil and S.cc()._cc ~= nil, "1 Lite: what the bands offer is recorded (a note for the director, not judged)",
            "NOTE in Lite the bag's band holds [" .. cIds .. "] and the World band [" .. wIds .. "]; Same type offered: bag "
            .. tostring(sameC) .. ", World " .. tostring(sameW) .. " (ContainerControls.lua liteTrim leaves Same type and Same type nearby out in Lite; the game's own windows have TransferSameType and TakeSameType)")
        S.setOpt(ZeD.Settings.lookStyleOption, T.style)
        S.rebuild()
    end)
    Q.step(4, function()
        if S.dead or T.off then return end
        Q.check(S.optVal(ZeD.Settings.lookStyleOption) == T.style, "1 Lite: Style is back as found", tostring(S.optVal(ZeD.Settings.lookStyleOption)))
        S.restoreTo(T.c0)
        S.caseClean()
    end)
    S.caseEnd("1 Same type")
end

-- ===================================================================== 2. Grab one, Grab half, Grab all (a stack of 12)
function S.grabStep(T, label, want, nameKey)
    S.step(6, function()
        if T.off then return end
        local wc = S.wc()
        local rep, st = S.rep(wc, T.k)
        if not (rep and st and st.items) then T.off = true; Q.check(false, "2 " .. label .. ": crate A shows the stack's closed row", "no stack row for " .. T.k); return end
        T.items = {}
        for _, x in ipairs(st.items) do T.items[#T.items + 1] = x end
        T.c0 = S.census({ S.box.bag, S.box.A })
        T.nA = S.countKind(S.A.inv, T.k)
        S.openMenu(T.items, false)
    end)
    S.wait(2, 120, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local names = S.menuNames(S.menu())
        if not ok then T.off = true; Q.check(false, "2 " .. label .. ": the stack's item menu opens", "no ZeD menu"); return end
        local nm = getText(nameKey)
        local okP, why = S.pick(S.menu(), { nm })
        T.go = Q.check(okP, "2 " .. label .. ": the stack's item menu has " .. nm .. " (ZeD's doGrabMenu) and it runs",
            why .. "; the menu: " .. table.concat(names, ", "))
        if not okP then S.closeMenu() end
    end)
    S.wait(4, 900, S.settled(6), function()
        if T.off or not T.go then return end
        local n = want(T.nA)
        local moved = {}
        local c1 = S.census(T.c0.list)
        for id, k0 in pairs(T.c0.at) do
            if k0 == "crate A" and S.ft(T.c0.item[id]) == T.k and c1.at[id] == "bag" then moved[id] = true end
        end
        local cnt = 0
        for _ in pairs(moved) do cnt = cnt + 1 end
        local ok, d = S.audit(T.c0, function(it, k0) if moved[S.idOf(it)] then return "bag" end end)
        local dest = "?"
        pcall(function() dest = (getPlayerInventory(S.pn).inventory == S.bag) and "the main inventory" or S.typeOf(getPlayerInventory(S.pn).inventory) end)
        Q.check(ok and cnt == n, "2 " .. label .. ": " .. n .. " of the " .. T.nA .. " in crate A come to the main inventory, the rest stay",
            cnt .. " came; " .. d .. "; the game's grab goes to " .. dest)
    end)
end
function S.case2()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        T.k = S.unique(S.SMALL)
        if not T.k then T.off = true; Q.skip("2 Grab one / half / all", "no small kind left that he carries none of"); return end
        for _ = 1, 12 do S.add(S.A.inv, T.k) end
        local wc = S.wc()
        if wc and wc._expandedStacks then wc._expandedStacks[T.k] = nil end
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(6, 300, function() return T.off or (S.shows(S.A.inv) and S.rep(S.wc(), T.k) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok and S.countKind(S.A.inv, T.k) == 12, "2 grab: crate A shows a closed stack of 12 " .. T.k, S.countKind(S.A.inv, T.k) .. " in A") then T.off = true end
    end)
    S.grabStep(T, "Grab one", function() return 1 end, "ContextMenu_Grab_one")
    S.grabStep(T, "Grab half", function(n) return math.floor(n / 2) end, "ContextMenu_Grab_half")
    S.grabStep(T, "Grab all", function(n) return n end, "ContextMenu_Grab_all")
    Q.step(2, function() if not S.dead then S.caseClean() end end)
    S.caseEnd("2 grab")
end

-- ===================================================================== 3, 4, 5. favorites, held things, the key ring; Transfer all
function S.hotAttach(it)
    local hb = nil
    pcall(function() hb = getPlayerHotbar(S.pn) end)
    if not (hb and hb.availableSlot) then return false, "no hotbar" end
    for i, slot in pairs(hb.availableSlot) do
        if not (hb.attachedItems and hb.attachedItems[i]) then
            local okA, can = pcall(function() return hb:canBeAttached(slot, it) end)
            if okA and can then
                local att = nil
                pcall(function() att = slot.def.attachments[it:getAttachmentType()] end)
                if att then
                    pcall(function() hb:attachItem(it, att, i, slot.def, false) end)
                    local on = false
                    pcall(function() on = hb:isInHotbar(it) end)
                    if on then return true, "slot " .. tostring(i) .. " (" .. tostring(slot.name) .. ")" end
                end
            end
        end
    end
    return false, "no free belt slot takes it"
end
function S.inHotbar(it)
    local on = false
    pcall(function() on = getPlayerHotbar(S.pn):isInHotbar(it) end)
    return on and true or false
end
function S.xferOk(it)
    local ok = true
    pcall(function()
        local hot = getPlayerHotbar(S.pn)
        local kr = it:isItemType(ItemType.KEY_RING) or it:hasTag(ItemTag.KEY_RING)
        ok = not it:isEquipped() and not kr and not it:isFavorite() and not (hot ~= nil and hot:isInHotbar(it))
    end)
    return ok
end
function S.case345()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        T.fav = S.give(S.unique(S.SMALL) or "Base.Twine")
        pcall(function() T.fav:setFavorite(true) end)
        T.tool = S.give(S.unique(S.TOOLS) or "Base.Hammer")
        pcall(function() S.p:setPrimaryHandItem(T.tool) end)
        T.hot = nil
        for _, ft in ipairs(S.TOOLS) do
            if not T.hot and not S.used[ft] and S.known(ft) then
                local it = S.give(ft)
                local ok, why = S.hotAttach(it)
                if ok then T.hot, T.hotWhy = it, why; S.used[ft] = true else S.removeItem(it) end
            end
        end
        T.ring = S.give("Base.KeyRing")
        pcall(function() T.ring:setName("LV Key Ring"); T.ring:setCustomName(true) end)
        T.key = S.give("Base.Key1")
        S.dirty()
        S.show(S.A.inv)
    end)
    -- 5a. a key onto the key ring by Move To
    S.step(10, function()
        if not (T.ring and T.key) then Q.skip("5 key ring", "no key ring or key could be made"); return end
        T.c0 = S.census({ S.box.bag, S.bx("key ring", T.ring:getInventory()) })
        S.openMenu({ T.key }, true)
    end)
    S.wait(2, 120, function() return not (T.ring and T.key) or S.menu() ~= nil end, function(ok)
        if not (T.ring and T.key) then return end
        local okP, why = false, "no ZeD menu"
        if ok then okP, why = S.pick(S.menu(), { getTextOrNull("ContextMenu_Move_To") or "Move To", "LV Key Ring" }) end
        T.kr = Q.check(okP, "5 key ring: the key's menu has Move To > LV Key Ring and it runs", why)
        if not okP then S.closeMenu() end
    end)
    S.wait(4, 600, S.settled(6), function()
        if not T.kr then return end
        local ok, d = S.audit(T.c0, function(it) if it == T.key then return "key ring" end end)
        Q.check(ok and S.where(T.key) == T.ring:getInventory(), "5 key ring: the key is on the key ring, nothing else moved", d)
    end)
    -- 3, 4, 5b. Transfer all from the main inventory into crate A
    S.step(6, function()
        T.elig = {}
        for _, it in ipairs(S.list(S.bag)) do if S.xferOk(it) then T.elig[it] = true end end
        T.tWas = { fav = S.where(T.fav), toolHeld = S.p:getPrimaryHandItem() == T.tool, hot = T.hot and S.inHotbar(T.hot) }
        T.c1 = S.census({ S.box.bag, S.box.A, S.bx("key ring", T.ring and T.ring:getInventory()) })
        S.rebuild()
    end)
    S.wait(6, 200, function() return S.spec(S.cc(), "xfer") ~= nil and S.spec(S.cc(), "xfer").enabled end, function(ok)
        local okP, why = false, "Transfer all is off or missing: " .. S.specText(S.spec(S.cc(), "xfer"))
        if ok then okP, why = S.press(S.cc(), "xfer") end
        T.x = Q.check(okP, "3-5 Transfer all: the bag's band presses it with crate A shown", why)
    end)
    S.wait(4, 2400, S.settled(10), function()
        if not T.x then return end
        local ok, d = S.audit(T.c1, function(it, k0) if k0 == "bag" and T.elig[it] then return "crate A" end end, true)
        Q.check(ok, "3-5 Transfer all: every thing it may take goes into crate A (or stays for want of room), nothing else moves, nothing lost or doubled", d)
        Q.check(T.fav ~= nil and S.where(T.fav) == S.bag and T.fav:isFavorite(), "3 favorites: the favorite stays in the main inventory through Transfer all",
            tostring(T.fav and S.ft(T.fav)) .. " " .. S.whereText(T.fav))
        local toolOk = S.p:getPrimaryHandItem() == T.tool and S.where(T.tool) == S.bag
        local hotOk = (not T.hot) or (S.inHotbar(T.hot) and S.where(T.hot) == S.bag)
        Q.check(toolOk and hotOk, "4 held things: the thing in the hand and the thing on the belt stay, still held and still on the belt",
            "hand " .. S.ft(T.tool) .. " " .. tostring(toolOk) .. "; belt " .. (T.hot and (S.ft(T.hot) .. " " .. tostring(hotOk) .. " " .. tostring(T.hotWhy)) or "no free belt slot took a tool (not staged)"))
        if not T.hot then Q.skip("4 the belt's thing through Transfer all", "no free belt slot on this character takes a tool") end
        if T.ring then
            Q.check(S.where(T.ring) == S.bag and S.where(T.key) == T.ring:getInventory(), "5 key ring: the key ring stays in the main inventory, the key still on it",
                "key ring " .. S.whereText(T.ring) .. ", key in " .. S.typeOf(S.where(T.key)))
        end
        S.restoreTo(T.c1)
    end)
    -- 3b. a favorite dragged into crate A
    S.step(6, function()
        S.show(S.A.inv)
        S.reveal(S.cc(), T.fav)
    end)
    S.step(4, function()
        T.c2 = S.census({ S.box.bag, S.box.A })
        S.haloOn()
        local ok, why = S.drag(S.cc(), T.fav, S.wc())
        T.d = Q.check(ok, "3 favorites: the favorite's row drags from the bag and drops on crate A's list", why)
    end)
    S.wait(10, 600, S.settled(10), function()
        local said = (S.halo and S.halo.said) or {}
        local saidT = #said > 0 and table.concat(said, "; ") or "no message over the head"
        S.haloOff()
        if not T.d then return end
        local ok, d = S.audit(T.c2, nil)
        Q.check(ok and S.where(T.fav) == S.bag, "3 favorites: a favorite dragged into a crate stays in the bag (the game's transfer refuses it), nothing else moves",
            d .. "; NOTE " .. saidT .. " (ZeD shows none of its own, InventoryRenderer.lua handleDrop)")
    end)
    Q.step(2, function() if not S.dead then S.caseClean() end end)
    S.caseEnd("3-5 favorites, held things, the key ring")
end

-- ===================================================================== 6. worn bag to worn bag
function S.case6()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        local bk, fr = S.unique(S.BACKS), S.unique(S.FRONTS)
        if not (bk and fr) then T.off = true; Q.skip("6 worn bag to worn bag", "a backpack and a front bag of kinds he does not carry could not be found"); return end
        T.back = S.give(bk)
        T.front = S.give(fr)
        pcall(function() T.back:setName("LV Back"); T.back:setCustomName(true) end)
        pcall(function() T.front:setName("LV Front"); T.front:setCustomName(true) end)
        T.howB = S.wearOrHold(T.back)
        T.howF = S.wearOrHold(T.front)
        T.binv, T.finv = T.back:getInventory(), T.front:getInventory()
        T.k = S.unique(S.SMALL)
        if not T.k then T.off = true; Q.skip("6 worn bag to worn bag", "no small kind left"); return end
        for _ = 1, 5 do S.add(T.binv, T.k) end
        S.listView(T.binv)
        S.listView(T.finv)
        S.dirty()
    end)
    S.wait(4, 300, function() return T.off or (S.listed(RT.cw(), T.binv) and S.listed(RT.cw(), T.finv)) end, function(ok)
        if T.off then return end
        if not Q.check(ok, "6 bags: both bags are on the Character window's buttons", "back " .. tostring(T.howB) .. ", front " .. tostring(T.howF)) then T.off = true; return end
        S.showBag(T.binv)
    end)
    S.wait(4, 300, function() return T.off or (S.charShows(T.binv) and S.rep(S.cc(), T.k) ~= nil) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, "6 bags: the Character window shows the back bag with its stack of 5"); return end
        local rep = S.rep(S.cc(), T.k)
        S.reveal(S.cc(), rep)
        T.c0 = S.census({ S.bx("back bag", T.binv), S.bx("front bag", T.finv), S.box.bag })
    end)
    S.step(4, function()
        if T.off then return end
        local rep = S.rep(S.cc(), T.k)
        local strip, extra = S.stripAt(RT.cw(), T.finv)
        if not (rep and strip) then T.off = true; Q.check(false, "6 bags: the stack's row and the front bag's button are on screen", "row " .. tostring(rep ~= nil) .. ", button " .. tostring(strip ~= nil)); return end
        local ok, why = S.drag(S.cc(), rep, strip, extra)
        T.d = Q.check(ok, "6 bags: the stack of 5 drags from the back bag and drops on the front bag's button", why)
    end)
    S.wait(4, 900, S.settled(6), function()
        if T.off or not T.d then return end
        local ok, d = S.audit(T.c0, function(it, k0) if k0 == "back bag" then return "front bag" end end)
        Q.check(ok and S.countKind(T.finv, T.k) == 5, "6 bags: by the drag, all 5 are in the front bag (" .. T.howF .. "), nothing else moved", d)
        T.five = {}
        for _, it in ipairs(S.list(T.finv)) do if S.ft(it) == T.k then T.five[#T.five + 1] = it end end
        T.c1 = S.census(T.c0.list)
        S.openMenu(T.five, true)
    end)
    S.wait(2, 120, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local okP, why = false, "no ZeD menu"
        if ok then okP, why = S.pick(S.menu(), { getTextOrNull("ContextMenu_Move_To") or "Move To", "LV Back" }) end
        T.m = Q.check(okP, "6 bags: the five's menu has Move To > LV Back and it runs", why)
        if not okP then S.closeMenu() end
    end)
    S.wait(4, 900, S.settled(6), function()
        if T.off or not T.m then return end
        local ok, d = S.audit(T.c1, function(it, k0) if k0 == "front bag" then return "back bag" end end)
        Q.check(ok and S.countKind(T.binv, T.k) == 5, "6 bags: by Move To, all 5 are back in the back bag (" .. T.howB .. "), nothing else moved", d)
    end)
    Q.step(2, function()
        if S.dead then return end
        S.showBag(S.bag)
        S.caseClean()
    end)
    S.caseEnd("6 bags")
end

-- ===================================================================== 7. a generator: lifted, never carried over
function S.heavyCheck(T, how)
    local primary = S.p:getPrimaryHandItem()
    local lifted = primary == T.gen and S.where(T.gen) == S.bag
    local plain = S.qHas("ISInventoryTransferAction", T.gen)
    local heavy = S.qHas("ISEquipHeavyItem", T.gen) or S.qHas("ISEquipHeavyItem")
    Q.check(lifted and heavy and not plain, "7 heavy: " .. how .. " lifts the generator into the hands with the game's ISEquipHeavyItem, never a plain transfer",
        "in the hands " .. tostring(lifted) .. " (" .. S.whereText(T.gen) .. "); queued: " .. S.qText())
end
function S.genBack(T)
    S.loose(T.gen)
    S.handsBack()
    S.put(T.gen, S.A.inv)
    S.dirty()
end
function S.case7()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        T.gen = S.add(S.A.inv, "Base.Generator")
        if not T.gen then T.off = true; Q.skip("7 heavy", "no generator could be made"); return end
        local heavy = false
        pcall(function() heavy = isForceDropHeavyItem(T.gen) end)
        T.heavy = heavy
        S.dirty()
        S.show(S.A.inv)
    end)
    S.step(10, function()
        if T.off then return end
        if not Q.check(T.heavy, "7 heavy: the game takes the generator for a heavy thing (isForceDropHeavyItem)") then T.off = true; return end
        S.qOn()
        local ok, err = pcall(ZeD.InventoryRenderer.quickUse, T.gen, S.pn, nil)
        if not ok then S.errs = S.errs + 1; Q.check(false, "7 heavy: quickUse ran", tostring(err)) end
    end)
    S.wait(4, 900, S.settled(8), function()
        if T.off then return end
        S.heavyCheck(T, "the double-click (quickUse) in crate A")
        S.qOff()
        S.genBack(T)
        S.rebuild()
    end)
    S.wait(6, 200, function() return T.off or (S.shows(S.A.inv) and S.size(S.A.inv) == 1 and S.spec(S.wc(), "take") ~= nil) end, function(ok)
        if T.off then return end
        S.qOn()
        local okP, why = false, "crate A does not hold the generator alone, or no Loot all: " .. S.size(S.A.inv) .. " things"
        if ok then okP, why = S.press(S.wc(), "take") end
        T.l = Q.check(okP, "7 heavy: Loot all presses with the generator alone in crate A", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if T.off then return end
        if T.l then S.heavyCheck(T, "Loot all with it alone in the container") end
        S.qOff()
        S.loose(T.gen)
        S.caseClean()
    end)
    S.step(1, function() Q.skip("7 heavy: a corpse lifted", "a corpse item needs a dead body behind it: only the generator is staged") end)
    S.caseEnd("7 heavy")
end

-- ===================================================================== 8. a car: trunk, glove box, a seat; seated; To floor
function S.carLive(v)
    if not v then return false end
    local live = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do if it:next() == v then live = true end end
    end)
    return live
end
function S.carInv(T, partId)
    local inv = nil
    pcall(function() inv = T.car:getPartById(partId):getItemContainer() end)
    return inv
end
-- Loot all from a car's container into the held bag on show, then Transfer all back
function S.carPair(T, partId, label)
    local L = {}
    S.step(4, function()
        L.inv = T.car and S.carInv(T, partId)
        if not L.inv then L.off = true; Q.skip(label .. ": Loot all and Transfer all", T.car and ("the car has no " .. partId) or "no car"); return end
        pcall(function() RT.ww()._containerTimer = 30 end)
    end)
    S.wait(6, 300, function() return L.off or S.listed(RT.ww(), L.inv) end, function(ok)
        if L.off then return end
        if not ok then L.off = true; Q.skip(label .. ": Loot all and Transfer all", "the World window does not list the " .. partId .. " from here (the game's canAccessContainer)"); return end
        L.made = {}
        for _ = 1, 3 do L.made[#L.made + 1] = S.add(L.inv, T.kCar) end
        S.listView(L.inv)
        S.show(L.inv)
        S.showBag(T.binv)
        S.dirty()
        S.rebuild()
    end)
    S.wait(6, 300, function()
        return L.off or (S.shows(L.inv) and S.charShows(T.binv) and S.spec(S.wc(), "take") ~= nil and S.spec(S.wc(), "take").enabled)
    end, function(ok)
        if L.off then return end
        if not Q.check(ok, label .. ": the World window shows it and the Character window the held bag",
            "World on " .. S.typeOf(S.wc() and S.wc()._inventory) .. ", Character on the bag " .. tostring(S.charShows(T.binv))) then L.off = true; return end
        L.c0 = S.census({ S.bx("held bag", T.binv), S.bx(partId, L.inv), S.box.bag })
        local okP, why = S.press(S.wc(), "take")
        L.a = Q.check(okP, label .. ": Loot all presses", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if L.off or not L.a then return end
        local ok, d = S.audit(L.c0, function(it, k0) if k0 == partId then return "held bag" end end, true)
        Q.check(ok, label .. ": Loot all brings everything in it to the bag on show (the held bag), nothing lost or doubled", d)
        L.c1 = S.census(L.c0.list)
        S.rebuild()
    end)
    S.wait(6, 200, function() return L.off or (S.spec(S.cc(), "xfer") ~= nil and S.spec(S.cc(), "xfer").enabled) end, function(ok)
        if L.off then return end
        local okP, why = false, "Transfer all is off or missing: " .. S.specText(S.spec(S.cc(), "xfer"))
        if ok then okP, why = S.press(S.cc(), "xfer") end
        L.b = Q.check(okP, label .. ": Transfer all from the held bag presses", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if L.off then return end
        if L.b then
            local ok, d = S.audit(L.c1, function(it, k0) if k0 == "held bag" then return partId end end, true)
            Q.check(ok, label .. ": Transfer all puts everything in the held bag into it, nothing lost or doubled", d)
        end
        S.restoreTo(L.c0)
        for _, it in ipairs(L.made or {}) do S.removeItem(it) end
    end)
end
function S.case8()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        T.kCar, T.kBag = S.unique(S.SMALL), S.unique(S.SMALL)
        local bk = S.unique(S.BACKS)
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY and ZEDQA_CAR_KEEP) then T.off = true; Q.skip("8 car", "the prelude's car helpers are not loaded"); return end
        if not (T.kCar and T.kBag and bk) then T.off = true; Q.skip("8 car", "the kinds for the car could not be found"); return end
        T.bag = S.give(bk)
        pcall(function() T.bag:setName("LV Car Bag"); T.bag:setCustomName(true) end)
        pcall(function() S.p:setSecondaryHandItem(T.bag) end)
        T.binv = T.bag:getInventory()
        for _ = 1, 3 do S.add(T.binv, T.kBag) end
        S.listView(T.binv)
        S.dirty()
        T.go = true
        T.t0 = getTimestampMs()
        ZEDQA_CAR_WAIT("Base.CarNormal", "lv_move", function(v)
            S.car = v
            ZEDQA_CAR_KEEP[v] = true
            T.ready = true
        end, function(why) T.why = why or "no ready car" end, 6000)
    end)
    S.wait(4, 30000, function() return T.off or T.ready or T.why ~= nil or getTimestampMs() - T.t0 > 60000 end, function()
        if T.off then return end
        if not T.ready then T.off = true; Q.skip("8 car", "no car could be staged: " .. tostring(T.why or "not ready in a minute")); return end
        T.car = S.car
        if ZEDQA_CAR_PREP then
            local ok, k = pcall(ZEDQA_CAR_PREP, T.car)
            if ok and k then S.carKey = k; S.mark(k) end
        end
        -- the trunk opened and unlocked, the character at it
        pcall(function()
            local d = T.car:getPartById("TrunkDoor"):getDoor()
            d:setLocked(false)
            d:setOpen(true)
        end)
        local c = nil
        pcall(function() c = T.car:getAreaCenter(T.car:getPartById("TruckBed"):getArea()) end)
        if c then pcall(function() S.p:teleportTo(c:getX(), c:getY(), 0) end) end
        T.atTrunk = c ~= nil
        pcall(function() RT.ww()._containerTimer = 30 end)
    end)
    S.wait(10, 400, function() return T.off or S.listed(RT.ww(), S.carInv(T, "TruckBed")) end, function(ok)
        if T.off then return end
        Q.check(ok, "8 car: standing at the open trunk, the trunk is on the World window's buttons", "at the trunk " .. tostring(T.atTrunk))
        if ok then S.show(S.carInv(T, "TruckBed")) end
    end)
    S.step(20, function() end)
    S.shot("lv_move_car_" .. S.sizeTag(), "the World window on the car's trunk, the held bag on show in the Character window")
    S.carPair(T, "TruckBed", "8 car, the trunk (from outside)")
    -- seated in the driver's seat
    S.step(4, function()
        if T.off then return end
        local okC, okE, why = pcall(ZEDQA_CAR_ENTER, T.car, 0)
        T.seated = okC and okE == true and S.p:getVehicle() == T.car
        if not T.seated then Q.skip("8 car, seated", "the character could not be seated: " .. tostring(why or okE)) return end
        pcall(function()
            local door = T.car:getPassengerDoor(T.car:getSeat(S.p))
            pcall(function() door:getDoor():setOpen(false) end)
            pcall(function() VehicleUtils.getChildWindow(door):getWindow():setOpen(false) end)
        end)
        pcall(function() RT.ww()._containerTimer = 30 end)
    end)
    S.wait(10, 400, function()
        if T.off or not T.seated then return true end
        local gb = S.carInv(T, "GloveBox")
        return gb ~= nil and S.listed(RT.ww(), gb)
    end, function(ok)
        if T.off or not T.seated then return end
        local ww = RT.ww()
        local floors, foreign, names = 0, {}, {}
        for _, e in ipairs((ww and ww._containers) or {}) do
            if e.isFloor then floors = floors + 1 end
            if not (e.sourceType == "vehicle" or e.sourceType == "vehicle_container") then foreign[#foreign + 1] = tostring(e.name) end
            if #names < 10 then names[#names + 1] = tostring(e.name) end
        end
        Q.check(ok and floors == 0 and #foreign == 0, "8 car, seated: the World window lists only the car's containers, no Floor",
            "[" .. table.concat(names, ", ") .. "]; Floors " .. floors .. ((#foreign > 0) and ("; not the car's: " .. table.concat(foreign, ", ")) or ""))
    end)
    S.carPair(T, "GloveBox", "8 car, the glove box (seated)")
    S.carPair(T, "SeatFrontRight", "8 car, the front passenger seat (seated)")
    -- To floor from the World band, seated, the door and the window shut
    S.step(4, function()
        if T.off or not T.seated then return end
        T.gb = S.carInv(T, "GloveBox")
        if not (T.gb and S.listed(RT.ww(), T.gb)) then T.noFloor = true; Q.skip("8 car, To floor seated", "the glove box is not listed"); return end
        T.fl = {}
        for _ = 1, 2 do T.fl[#T.fl + 1] = S.add(T.gb, T.kCar) end
        S.show(T.gb)
        S.rebuild()
    end)
    S.wait(6, 300, function()
        return T.off or not T.seated or T.noFloor or (S.shows(T.gb) and S.spec(S.wc(), "floor") ~= nil)
    end, function(ok)
        if T.off or not T.seated or T.noFloor then return end
        local shut = false
        pcall(function() shut = ZeD.InventoryRenderer.carWindowShut(S.p) end)
        T.shut = shut
        local cx, cy = math.floor(T.car:getX()), math.floor(T.car:getY())
        T.c0 = S.census({ S.bx("glove box", T.gb), S.box.bag, S.bx("held bag", T.binv), { key = "floor", floor = true, x = cx, y = cy, z = 0, r = 5 } })
        local sp = S.spec(S.wc(), "floor")
        local okP, why = false, "no To floor on the glove box's band: " .. S.specIds(S.wc())
        if ok and sp and sp.enabled then okP, why = S.press(S.wc(), "floor") end
        T.f = okP
        if not okP then Q.check(true, "8 car, To floor seated: the band offers no To floor here (nothing can leave the car this way)", why) end
    end)
    S.wait(4, 900, S.settled(10), function()
        if T.off or not T.seated or T.noFloor or not T.f then return end
        local ok, d = S.audit(T.c0, nil)
        Q.check(ok, "8 car, To floor seated with the door and window shut: nothing leaves the car and nothing is lost (what happens is recorded)",
            "the seat's door and window shut (carWindowShut) " .. tostring(T.shut) .. "; " .. d
            .. (ok and "" or " (ContainerControls.lua's To floor goes to onMoveItemsTo, around carWindowShut)"))
        S.restoreTo(T.c0)
    end)
    -- out of the car, the car away, the character back
    Q.step(4, function()
        if S.dead then return end
        if S.car then
            pcall(function() ZEDQA_CAR_KEEP[S.car] = nil end)
            pcall(ZEDQA_CAR_AWAY, S.car, S.carKey)
            S.carAway = true
        end
    end)
    S.wait(4, 600, function() return S.p:getVehicle() == nil and not S.carLive(S.car) end, function(ok)
        if not T.off then Q.check(ok, "8 car: out of the car and the car taken away", "in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", the car in the cell " .. tostring(S.carLive(S.car))) end
        S.car = nil
        S.goTo(S.found.pos.x, S.found.pos.y, S.found.pos.z)
        S.showBag(S.bag)
        S.caseClean()
    end)
    S.step(20, function() S.show(S.A.inv) end)
    S.caseEnd("8 car")
end

-- ===================================================================== 9. a padlocked crate, with and without the key
function S.worldMenuLoot(obj)
    S.closeMenu()
    local w, h = S.screen()
    local ok, err = pcall(function() ISWorldObjectContextMenu.createMenu(S.pn, { obj }, math.floor(w / 2), math.floor(h / 2), false) end)
    if not ok then S.errs = S.errs + 1 end
    local label = getText("IGUI_invpage_Loot_all")
    local names = S.ctxTopNames()
    return S.inList(names, label), names, ok, err
end
function S.case9()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        local sq = S.spare[1]
        if not sq then T.off = true; Q.skip("9 locked", "no third free square round him"); return end
        local c, err = S.mkLocked(sq)
        if not c then T.off = true; Q.skip("9 locked", "the padlocked crate could not be made: " .. tostring(err)); return end
        S.L = c
        for _ = 1, 2 do S.add(c.inv, S.unique(S.SMALL) or "Base.Twine") end
        S.dirty()
    end)
    S.wait(6, 300, function() return T.off or S.listed(RT.ww(), S.L.inv) end, function(ok)
        if T.off then return end
        local e = S.entryOf(RT.ww(), S.L.inv)
        local lockedChar = nil
        pcall(function() lockedChar = S.L.obj:isLockedToCharacter(S.p) end)
        Q.check(ok and e ~= nil and e.locked == true, "9 locked: without the key the World window lists the padlocked crate as locked",
            "listed " .. tostring(ok) .. ", locked " .. tostring(e and e.locked) .. " (isLockedToCharacter " .. tostring(lockedChar) .. ")")
    end)
    S.shot("lv_move_locked_" .. S.sizeTag(), "the World window with the padlocked crate on its buttons, locked (no key)")
    S.step(2, function()
        if T.off then return end
        T.has0, T.names0, T.ok0 = S.worldMenuLoot(S.L.obj)
    end)
    S.step(3, function()
        if T.off then return end
        S.closeMenu()
        Q.check(T.ok0 and not T.has0, "9 locked: without the key the crate's world menu offers no Loot all",
            "the menu: " .. table.concat(T.names0 or {}, ", "))
        T.key = S.give("Base.KeyPadlock")
        pcall(function() T.key:setKeyId(S.KEY_ID) end)
        S.dirty()
    end)
    S.wait(6, 300, function()
        if T.off then return true end
        local e = S.entryOf(RT.ww(), S.L.inv)
        return e ~= nil and not e.locked
    end, function(ok)
        if T.off then return end
        local e = S.entryOf(RT.ww(), S.L.inv)
        Q.check(ok, "9 locked: with the key the World window opens the padlocked crate (not locked)", "locked " .. tostring(e and e.locked))
        if ok then S.show(S.L.inv) end
        S.rebuild()
    end)
    S.wait(6, 300, function() return T.off or (S.shows(S.L.inv) and S.spec(S.wc(), "take") ~= nil) end, function(ok)
        if T.off then return end
        Q.check(ok and S.spec(S.wc(), "take").enabled, "9 locked: with the key the World window shows the crate and its band's Loot all is on", S.specText(S.spec(S.wc(), "take")))
        T.has1, T.names1, T.ok1 = S.worldMenuLoot(S.L.obj)
    end)
    S.step(3, function()
        if T.off then return end
        S.closeMenu()
        Q.check(T.ok1 and T.has1, "9 locked: with the key the crate's world menu offers Loot all, as the game opens the crate for the key holder",
            T.has1 and "offered" or ("GAP vs the game: ZeD's world menu hides Loot all on any padlocked object even with its key (ItemMenu.lua padlocked() in onFillWorld); the menu: "
                .. table.concat(T.names1 or {}, ", ")))
        S.show(S.A.inv)
        S.caseClean()
    end)
    S.caseEnd("9 locked")
end

-- ===================================================================== 10. the floor: a drop, an overflow, grabs walked away from
function S.case10()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        T.k = S.unique(S.SMALL)
        T.one = T.k and S.give(T.k)
        S.dirty()
    end)
    S.step(8, function()
        if not T.one then Q.skip("10 floor: a drag to the world", "no small kind left"); return end
        S.reveal(S.cc(), T.one)
    end)
    S.step(4, function()
        if not T.one then return end
        T.c0 = S.census({ S.box.bag, S.floorBox(1) })
        local ok, why = S.dragToWorld(S.cc(), T.one)
        T.d = Q.check(ok, "10 floor: a row dragged from the bag is released over the world", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if not T.d then return end
        local ok, d = S.audit(T.c0, function(it) if it == T.one then return "floor" end end)
        Q.check(ok and S.onFloor(T.one), "10 floor: released over the world, the thing is on the floor beside him, nothing else moved", d)
    end)
    -- seven heavy things dropped at once: more than 50 kg spills to the next squares
    S.step(2, function()
        T.hk = nil
        for _, ft in ipairs(S.HEAVY) do
            if not T.hk and S.known(ft) then
                local n = 0
                pcall(function() n = S.p:getInventory():getCountTypeRecurse(ft) end)
                if n == 0 then T.hk = ft end
            end
        end
        if not T.hk then Q.skip("10 floor: the overflow", "he carries some of every heavy kind"); return end
        T.heavy = {}
        local total = 0
        while total < 60 and #T.heavy < 30 do
            local it = S.give(T.hk)
            if not it then break end
            T.heavy[#T.heavy + 1] = it
            total = total + (it:getUnequippedWeight() or 0)
        end
        T.total = total
        local wc = S.cc()
        if wc and wc._expandedStacks then wc._expandedStacks[T.hk] = nil end
        S.dirty()
    end)
    S.step(8, function()
        if not T.hk then return end
        local rep = S.rep(S.cc(), T.hk)
        S.reveal(S.cc(), rep)
    end)
    S.step(4, function()
        if not T.hk then return end
        local rep = S.rep(S.cc(), T.hk)
        T.c1 = S.census({ S.box.bag, S.floorBox(2) })
        local ok, why = false, "no closed stack row for " .. T.hk
        if rep then ok, why = S.dragToWorld(S.cc(), rep) end
        T.o = Q.check(ok, "10 floor: the stack of " .. #T.heavy .. " " .. T.hk .. " (" .. math.floor(T.total) .. " kg) is dragged over the world", why)
    end)
    S.wait(4, 1800, S.settled(10), function()
        if not T.o then return end
        local onF, sqs, worst, set = 0, 0, 0, {}
        for _, it in ipairs(T.heavy) do
            if S.onFloor(it) then
                onF = onF + 1
                pcall(function()
                    local sq = it:getWorldItem():getSquare()
                    if not set[sq] then set[sq] = true; sqs = sqs + 1 end
                end)
            end
        end
        for sq in pairs(set) do
            local w = 0
            pcall(function() w = sq:getTotalWeightOfItemsOnFloor() end)
            if w > worst then worst = w end
        end
        local ok, d = S.audit(T.c1, function(it) for _, h in ipairs(T.heavy) do if h == it then return "floor" end end end)
        Q.check(ok and onF == #T.heavy and sqs >= 2, "10 floor: over 50 kg dropped spills to the next squares; every one is on the floor, nothing lost",
            onF .. " of " .. #T.heavy .. " on the floor over " .. sqs .. " squares, the heaviest square " .. math.floor(worst) .. " kg; " .. d)
    end)
    -- three floor grabs queued (the cheat off), then a walk of five squares away and back
    S.step(2, function()
        T.three = {}
        local sq = S.p:getCurrentSquare()
        local k = S.unique(S.SMALL)
        if not (sq and k) then Q.skip("10 floor: grabs walked away from", "no square or no kind"); return end
        for i = 1, 3 do
            local it = nil
            pcall(function() it = sq:AddWorldInventoryItem(k, 0.2 * i, 0.5, 0) end)
            if it then T.three[#T.three + 1] = S.mark(it) end
        end
        S.dirty()
    end)
    S.wait(6, 300, function()
        if #(T.three or {}) < 3 then return true end
        local fl = nil
        pcall(function() fl = ZeD_WorldWindow.getFloorContainer(S.pn) end)
        for _, it in ipairs(T.three) do if not (fl and S.where(it) == fl) then return false end end
        return true
    end, function(ok)
        if #(T.three or {}) < 3 then return end
        if not Q.check(ok, "10 floor: three things on the floor are in the World window's floor") then T.three = {}; return end
        S.instant(false)
        T.q = 0
        for _, it in ipairs(T.three) do
            local okT, went = pcall(ZeD_WorldWindow.transferFromFloor, S.p, it, S.bag)
            if okT and went then T.q = T.q + 1 end
        end
        T.from = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    end)
    S.step(3, function()
        if #(T.three or {}) < 3 then return end
        T.qLen = S.queueLen()
        S.goTo(T.from.x + 5, T.from.y, T.from.z)
    end)
    Q.waitMs(2500)
    S.step(2, function()
        if #(T.three or {}) < 3 then return end
        S.goTo(T.from.x, T.from.y, T.from.z)
        S.instant(true)
    end)
    S.wait(10, 1200, S.settled(20), function()
        if #(T.three or {}) < 3 then return end
        local inBag, onF, lost = 0, 0, {}
        for _, it in ipairs(T.three) do
            local b, f = S.where(it) == S.bag, S.onFloor(it)
            if b and not f then inBag = inBag + 1 elseif f and not b then onF = onF + 1 else lost[#lost + 1] = S.ft(it) .. " " .. S.whereText(it) end
        end
        Q.check(#lost == 0, "10 floor: three floor grabs queued, then five squares away and back: each thing is in the bag or still on the floor, none lost",
            T.q .. " grabs queued (queue " .. tostring(T.qLen) .. "); " .. inBag .. " in the bag, " .. onF .. " on the floor" .. ((#lost > 0) and ("; " .. table.concat(lost, "; ")) or ""))
        pcall(function() ISTimedActionQueue.clear(S.p) end)
        S.caseClean()
    end)
    S.caseEnd("10 floor")
end

-- ===================================================================== 11. "Put in <container>": which container
function S.case11()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        T.k = S.unique(S.SMALL)
        T.it = T.k and S.give(T.k)
        if not T.it then T.off = true; Q.skip("11 put in", "no small kind left"); return end
        S.show(S.B.inv)
    end)
    S.wait(4, 300, function() return T.off or S.shows(S.B.inv) end, function() if not T.off then S.show(S.A.inv) end end)
    S.wait(4, 300, function() return T.off or S.shows(S.A.inv) end, function(ok)
        if T.off then return end
        local lp = nil
        pcall(function() lp = getPlayerLoot(S.pn) end)
        T.lpInv = lp and lp.inventory
        T.lpTitle = lp and lp.title
        T.c0 = S.census({ S.box.bag, S.box.A, S.box.B })
        S.openMenu({ T.it }, true)
    end)
    S.wait(2, 120, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local o = S.ctxOptionBy(ISInventoryPaneContextMenu.onPutItems)
        local lpName = (T.lpInv == S.A.inv and "crate A") or (T.lpInv == S.B.inv and "crate B") or S.typeOf(T.lpInv)
        T.lpName = lpName
        if not o then
            S.closeMenu()
            Q.check(true, "11 put in: the item menu has no Put in option (the game's hidden loot page is on " .. lpName .. ")",
                "NOTE the game's option needs its loot page on a container other than the floor; ZeD's Move To covers the container on show")
            T.off = true
            return
        end
        T.name = tostring(o.name)
        local okP, why = S.pick(S.menu(), { T.name })
        T.p = Q.check(okP, "11 put in: the item menu's \"" .. T.name .. "\" runs", why)
        if not okP then S.closeMenu() end
    end)
    S.wait(4, 600, S.settled(6), function()
        if T.off or not T.p then return end
        local ok, d = S.audit(T.c0, function(it) if it == T.it then return "crate A" end end)
        Q.check(ok, "11 put in: \"" .. T.name .. "\" puts the thing in the container on show (crate A)",
            "the game's hidden loot page is on " .. T.lpName .. " (titled " .. tostring(T.lpTitle) .. "); " .. d)
    end)
    Q.step(2, function() if not S.dead then S.caseClean() end end)
    S.caseEnd("11 put in")
end

-- ===================================================================== 12. Loot all's destination with a bag on show
function S.case12()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        local bk = S.unique(S.BACKS)
        T.k = S.unique(S.SMALL)
        if not (bk and T.k) then T.off = true; Q.skip("12 loot all's destination", "no backpack or small kind left"); return end
        T.pack = S.give(bk)
        pcall(function() T.pack:setName("LV Pack"); T.pack:setCustomName(true) end)
        T.how = S.wearOrHold(T.pack)
        T.pinv = T.pack:getInventory()
        for _ = 1, 3 do S.add(S.A.inv, T.k) end
        S.listView(T.pinv)
        S.dirty()
    end)
    S.wait(4, 300, function() return T.off or S.listed(RT.cw(), T.pinv) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, "12 loot all: the backpack is on the Character window's buttons", T.how); return end
        S.showBag(T.pinv)
        S.show(S.A.inv)
        S.rebuild()
    end)
    S.wait(4, 300, function() return T.off or (S.charShows(T.pinv) and S.shows(S.A.inv) and S.spec(S.wc(), "take") ~= nil) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, "12 loot all: the backpack on show, crate A in the World window"); return end
        T.c0 = S.census({ S.box.bag, S.bx("backpack", T.pinv), S.box.A })
        local okP, why = S.press(S.wc(), "take")
        T.l = Q.check(okP, "12 loot all: Loot all presses with the backpack (" .. T.how .. ") on show", why)
    end)
    S.wait(4, 900, S.settled(8), function()
        if T.off or not T.l then return end
        local inMain, inPack = 0, 0
        for id, k0 in pairs(T.c0.at) do
            if k0 == "crate A" then
                local w = S.where(T.c0.item[id])
                if w == S.bag then inMain = inMain + 1 elseif w == T.pinv then inPack = inPack + 1 end
            end
        end
        local ok, d = S.audit(T.c0, function(it, k0) if k0 == "crate A" then local w = S.where(it); if w == S.bag then return "bag" end; return "backpack" end end)
        Q.check(ok, "12 loot all: every thing leaves crate A into one of his containers, nothing lost or doubled", d)
        Q.check(inMain == 3, "12 loot all: Loot all puts the things in the main inventory, as the game does",
            inMain .. " in the main inventory, " .. inPack .. " in the backpack on show"
            .. ((inMain == 3) and "" or "; DESIGN CALL for the director: ZeD sends Loot all to the bag on show (ContainerControls.lua buildWorld's take, otherInventory; lootAllFrom), the game to the main inventory (ISInventoryPane:lootAll)"))
    end)
    Q.step(2, function()
        if S.dead then return end
        S.showBag(S.bag)
        S.caseClean()
    end)
    S.caseEnd("12 loot all")
end

-- ===================================================================== 13. Transfer all with the World window shut
function S.case13()
    local T = {}
    S.step(2, function()
        pcall(ZeD_WorldWindow.close, S.pn)
    end)
    S.wait(4, 300, function() return not S.worldOpen() end, function(ok)
        if not Q.check(ok, "13 shut: the World window shuts, the Character window stays") then T.off = true end
        S.rebuild()
    end)
    S.step(12, function()
        if T.off then return end
        local sp = S.spec(S.cc(), "xfer")
        local lp = nil
        pcall(function() lp = getPlayerLoot(S.pn).inventory end)
        Q.check(sp ~= nil and sp.enabled, "13 shut: with the World window shut, Transfer all on the player's side is on, as the game's (it goes to the game's loot container)",
            S.specText(sp) .. "; the game's would go to " .. S.typeOf(lp)
            .. ((sp and sp.enabled) and "" or "; DESIGN CALL for the director: ZeD's Transfer all needs the World window open on a container (ContainerControls.lua buildChar: enabled = dest ~= nil)"))
        pcall(ZeD_WorldWindow.open, S.pn)
    end)
    S.wait(4, 300, function() return S.worldOpen() end, function(ok)
        Q.check(ok, "13 shut: the World window opens again")
        if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
        S.show(S.A.inv)
    end)
    S.wait(4, 300, function() return S.shows(S.A.inv) end, function() end)
    S.caseEnd("13 shut")
end

-- ===================================================================== 14. Move To on a held thing that is refused
function S.gateOn(inv)
    local G = ZeD.ContainerGates
    S.gateInv = inv
    S.gateT = S.gateT or { keep = function() return true end, refuse = true, sig = 1, mode = "lvqa" }
    G.add("ZeDQA_lv_move", function(i) if S.gateInv ~= nil and i == S.gateInv then return S.gateT end; return nil end)
end
function S.gateOff()
    S.gateInv = nil
    local G = ZeD.ContainerGates
    if not (G and G.gates) then return end
    for i = #G.gates, 1, -1 do if G.gates[i].id == "ZeDQA_lv_move" then table.remove(G.gates, i) end end
end
function S.refuseLeg(T, label, prep)
    S.step(4, function()
        if T.off then return end
        pcall(function() S.p:setPrimaryHandItem(T.tool) end)
        prep()
        S.show(S.B.inv)
    end)
    S.wait(4, 300, function() return T.off or S.shows(S.B.inv) end, function()
        if T.off then return end
        T.c0 = S.census({ S.box.bag, S.box.B })
        S.openMenu({ T.tool }, true)
    end)
    S.wait(2, 120, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local mv = getTextOrNull("ContextMenu_Move_To") or "Move To"
        local e = S.entryOf(RT.ww(), S.B.inv)
        local nm = e and e.name or "?"
        local def = S.findDef(S.menu(), { mv, nm })
        T.na = def and def.vanillaRef and def.vanillaRef.notAvailable
        T.offered = def ~= nil
        T.picked = false
        if def and not T.na then
            local okP = S.pick(S.menu(), { mv, nm })
            T.picked = okP
        end
        if not T.picked then S.closeMenu() end
    end)
    S.wait(4, 600, S.settled(8), function()
        if T.off then return end
        local held = S.p:getPrimaryHandItem() == T.tool
        local inB = S.where(T.tool) == S.B.inv
        local ok, d = S.audit(T.c0, function(it) if it == T.tool and inB then return "crate B" end end)
        Q.check(ok and (held or inB), label .. ": Move To leaves the held thing held or puts it in the crate, never unequipped and left",
            "offered " .. tostring(T.offered) .. ", greyed " .. tostring(T.na == true) .. ", picked " .. tostring(T.picked) .. "; held " .. tostring(held)
            .. ", in crate B " .. tostring(inB) .. "; " .. d .. ((held or inB) and "" or " (ItemMenu.lua onMove queues the unequip before the move is refused)"))
    end)
end
function S.case14()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        local tk = S.unique(S.TOOLS)
        if not tk then T.off = true; Q.skip("14 refused", "no tool kind left"); return end
        T.tool = S.give(tk)
        S.dirty()
    end)
    S.refuseLeg(T, "14 refused (a gate refuses crate B)", function() S.gateOn(S.B.inv) end)
    S.step(2, function()
        S.gateOff()
        if T.off then return end
        -- crate B filled to the brim
        T.fill = {}
        local probe = T.tool
        while #T.fill < 60 and S.room(S.B.inv, probe) do
            local it = S.add(S.B.inv, "Base.Plank")
            if not it then break end
            T.fill[#T.fill + 1] = it
        end
        T.full = not S.room(S.B.inv, probe)
        if not T.full then T.off = true; Q.skip("14 refused (a full crate)", "crate B still had room after " .. #T.fill .. " planks") end
    end)
    S.refuseLeg(T, "14 refused (crate B full)", function() end)
    Q.step(2, function()
        S.gateOff()
        if S.dead then return end
        S.caseClean()
        S.show(S.A.inv)
    end)
    S.caseEnd("14 refused")
end

-- ===================================================================== 15. Put things back: the unrelated thing stays
S.STATS = { "HUNGER", "THIRST", "UNHAPPINESS", "BOREDOM", "STRESS", "FATIGUE", "ENDURANCE" }
function S.statsSnap()
    local s = {}
    for _, k in ipairs(S.STATS) do
        if CharacterStat[k] then pcall(function() s[k] = S.p:getStats():get(CharacterStat[k]) end) end
    end
    pcall(function()
        local n = S.p:getNutrition()
        s.cal, s.carb, s.prot, s.lip, s.wt = n:getCalories(), n:getCarbohydrates(), n:getProteins(), n:getLipids(), n:getWeight()
    end)
    return s
end
function S.statsBack(s)
    if not s then return end
    for _, k in ipairs(S.STATS) do
        if s[k] ~= nil then pcall(function() S.p:getStats():set(CharacterStat[k], s[k]) end) end
    end
    pcall(function()
        local n = S.p:getNutrition()
        if s.cal then n:setCalories(s.cal) end
        if s.carb then n:setCarbohydrates(s.carb) end
        if s.prot then n:setProteins(s.prot) end
        if s.lip then n:setLipids(s.lip) end
    end)
end
function S.case15()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if not (ZeD.PutBack and ZeD.Settings and ZeD.Settings.putBackOption) then T.off = true; Q.skip("15 put back", "ZeD_PutBack is not loaded"); return end
        T.k = S.unique(S.SMALL)
        if not T.k then T.off = true; Q.skip("15 put back", "no small kind left"); return end
        T.food = S.add(S.A.inv, "Base.Apple")
        T.other = S.add(S.A.inv, T.k)
        T.stats = S.statsSnap()
        T.was = S.optVal(ZeD.Settings.putBackOption)
        S.setOpt(ZeD.Settings.putBackOption, 2)
        S.show(S.A.inv)
    end)
    S.step(10, function()
        if T.off then return end
        T.on = ZeD.PutBack.on and ZeD.PutBack.on()
        T.c0 = S.census({ S.box.bag, S.box.A })
        -- in one tick: the other thing picked up (ZeD's move), then the apple eaten from the crate (the game's eat)
        pcall(ZeD.ContainerControls.moveItems, S.p, { T.other }, S.bag)
        local ok, err = pcall(ISInventoryPaneContextMenu.onEatItems, { T.food }, 1, S.pn)
        if not ok then S.errs = S.errs + 1; Q.check(false, "15 put back: the eat was queued", tostring(err)) end
    end)
    S.wait(6, 1800, S.settled(30), function()
        if T.off then return end
        local ok, d = S.audit(T.c0, function(it) if it == T.food then return "gone" end; if it == T.other then return "bag" end end)
        Q.check(T.on and ok and S.where(T.other) == S.bag,
            "15 put back (on for this case): the apple eaten from crate A is used up and the thing picked up in the same tick stays in the bag",
            "Put things back on " .. tostring(T.on) .. "; " .. d .. "; the other thing " .. S.whereText(T.other)
            .. ((S.where(T.other) == S.A.inv) and " (ZeD_PutBack.lua finish counts it as the eat's run and sends it back)" or ""))
        S.setOpt(ZeD.Settings.putBackOption, T.was)
        S.statsBack(T.stats)
        Q.check(S.optVal(ZeD.Settings.putBackOption) == T.was, "15 put back: the setting is back as found", tostring(S.optVal(ZeD.Settings.putBackOption)))
        S.caseClean()
    end)
    S.caseEnd("15 put back")
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.park(false)
    S.haloOff()
    S.qOff()
    S.gateOff()
    S.cancelDrags()
    S.closeMenu()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if f.style ~= nil then S.setOpt(ZeD.Settings.lookStyleOption, f.style) end
    if f.putBack ~= nil then S.setOpt(ZeD.Settings.putBackOption, f.putBack) end
    if S.car then
        pcall(function() ZEDQA_CAR_KEEP[S.car] = nil end)
        if not S.carAway then pcall(ZEDQA_CAR_AWAY, S.car, S.carKey) end
        S.carAway = true
    end
    if S.bag then S.restoreBag() end
    for _, it in ipairs(S.made) do S.removeItem(it) end
    for _, c in ipairs(S.crates) do S.rmCrate(c) end
    S.handsBack()
    S.wornBack()
    local st = S.p:getModData().ZeD_GridViews
    if st then for key, v in pairs(S.grid) do if v == "NIL" then st[key] = nil else st[key] = v end end end
    S.dirty()
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        S.putBack()
        if not (RT.isOpen() and S.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
    end)
    Q.waitFor(4, 600, function() return S.p:getVehicle() == nil end, function()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
    end)
    Q.step(20, function()
        local f = S.found
        RT.charTab("loot")
        if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
        if S.bag and not S.charShows(S.bag) then S.showBag(S.bag) end
        if f.worldInv then pcall(ZeD_WorldWindow.selectContainer, f.worldInv, 60, S.pn) end
        for _, inv in ipairs(f.charCols or {}) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
        for _, inv in ipairs(f.worldCols or {}) do pcall(ZeD_WorldWindow.toggleColumn, inv, S.pn) end
        if f.charTab and f.charTab ~= "loot" then RT.charTab(f.charTab) end
        if f.worldTab and f.worldTab ~= "loot" then RT.worldTab(f.worldTab) end
        S.instant(f.inst)
        if f.speed ~= nil and ZEDQA_SPEED then pcall(ZEDQA_SPEED, f.speed) end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        if S.bagOrig then
            local back = 0
            for _, it in ipairs(S.bagOrig) do if S.where(it) == S.bag then back = back + 1 end end
            Q.check(back == #S.bagOrig, "put back: the bag holds all its own things again", back .. " of " .. #S.bagOrig)
        end
        local left, names = 0, {}
        for _, it in ipairs(S.made) do
            if S.where(it) ~= nil or S.onFloor(it) then
                left = left + 1
                if #names < 4 then names[#names + 1] = S.ft(it) .. " " .. S.whereText(it) end
            end
        end
        Q.check(left == 0, "put back: every thing the test made is gone (containers, floor, hands, belt)", left .. " of " .. #S.made .. " left" .. ((#names > 0) and ("; " .. table.concat(names, "; ")) or ""))
        local crates = 0
        for _, c in ipairs(S.crates) do if c.obj ~= nil then crates = crates + 1 end end
        Q.check(crates == 0 and S.car == nil and S.p:getVehicle() == nil, "put back: the crates are gone, the car is away and he is on foot", crates .. " crates left")
        local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        Q.check(f.hands == nil or (hp == f.hands.p and hs == f.hands.s), "put back: the hands hold what they held")
        local worn, on = 0, S.wornSet()
        for _, e in ipairs(f.worn or {}) do if on[e.item] then worn = worn + 1 end end
        Q.check(worn == #(f.worn or {}), "put back: he wears what he wore", worn .. " of " .. #(f.worn or {}))
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6, "put back: he stands where he stood", string.format("%.1f,%.1f off", dx, dy))
        Q.check(S.optVal(ZeD.Settings.lookStyleOption) == f.style and S.optVal(ZeD.Settings.putBackOption) == f.putBack,
            "put back: Style and Put things back as found", tostring(S.optVal(ZeD.Settings.lookStyleOption)) .. ", " .. tostring(S.optVal(ZeD.Settings.putBackOption)))
        Q.check(S.qOrig == nil and S.halo == nil and S.gateInv == nil and S.parked == nil, "put back: the queue, the halo, the gates and the pointer are the game's own again")
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the move run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the move run's Lua error count", "the game's Lua error count cannot be read here") end
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and f.world == false then
            if RT.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
        elseif f.pair == false and RT.isOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn)
        elseif f.world == false and S.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
    end)
end

-- ===================================================================== the run
function S.build()
    S.setup()
    S.case1()
    S.case2()
    S.case345()
    S.case6()
    S.case7()
    S.case8()
    S.case9()
    S.case10()
    S.case11()
    S.case12()
    S.case13()
    S.case14()
    S.case15()
end
S.build()
S.buildPutBack()
Q.start()
