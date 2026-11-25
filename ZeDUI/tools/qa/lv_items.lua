-- ZeDUI/tools/qa/lv_items.lua  (Nov 23 2026, QA; tag lv_items): Loot and inventory, the whole gamut, part two: special
-- things and the item menu. The director, Nov 23 2026, after the Health sweep: the same treatment for the loot and the
-- inventory. Run after zedqa_prelude.lua and rt_kit.lua (lv.txt), after lv_move.lua. grep "ZEDQA lv_items".
--
-- On the drag strip one crate (A, an IsoObject as rt_inventory makes it) stands beside the character; the things are
-- given to his main inventory (RT.give) or made in the crate, and taken away again. The item menu is the game's
-- ISInventoryPaneContextMenu.createMenu, as a right-click on a row calls it; ZeD's menu is built from it on its next
-- draw and its rows are picked by name (rt_inventory's pick, through submenus where a row sits in one). The game's
-- menu for the same right-click is read from the game's own ISContextMenu that createMenu filled and ZeD hides (every
-- row and submenu row, the game's Debug submenu aside): every one of its rows must be in ZeD's menu. (Nov 23 2026,
-- after the first run: a second build with ZeD set aside threw in the game's own handlers, three Lua errors a menu.)
-- Moves are counted by item id in every container they touch (S.census / S.audit). Timed actions run instant.
-- Already covered elsewhere and not repeated: rt_cards (the card's eat, rename, read, equip, drop), rt_inventory
-- (Move To, double-click take and equip), lv_move.lua (moves and containers).
-- Checks:
--   setup     both windows open, the Character window on the main inventory, crate A shown in the World window
--   16 kinds  for each kind: pills (Take pills), a lighter, a water bottle (Drink, Pour on ground), a sealed can (with
--             a tin opener), rotten food, a magazine (Insert bullets), a firearm (Insert magazine), a key, a book
--             (Read), a portable radio, a furniture piece (Place): (a) ZeD's item menu holds every row of the game's
--             menu for the right-click, debug rows aside (the missing ones named); (b) the kind's key
--             options are there; (c) one action runs and completes: the pills' uses drop, the water drops, the
--             magazine takes bullets, the firearm takes the magazine, the book is marked read, the radio's
--             double-click puts it in a hand, the rotten food's double-click does not eat it (picture
--             lv_items_menu_<w>x<h>: the firearm's menu); the furniture piece stays in its bag through Transfer all
--             to the floor (the game's rule: a piece that cannot lie on the floor stays)
--   17 menu   Rename on a bag (the game's box, the name taken), Unpack (a thing in a carried bag comes to the main
--             inventory), Favorite then Unfavorite, Unwanted then Wanted: each by its menu row, each counted
--   18 shift  Shift + double-click on a garment in crate A takes it and wears it in the game (ISInventoryPane
--             onMouseDoubleClick); a FAIL with the detail if ZeD does not (a gap vs the game)
--   19 ctrl a Ctrl+A picks every row of the list in the game (ISInventoryPane:update); a FAIL with the detail if ZeD
--             has no such key (a gap vs the game)
--   20 nails  a stack of 150 nails: dragged to crate A, Move To back to the inventory, Loot all from A: counted exactly
--             each time (his own nails, if any, ride with the stack and are counted too)
--   21 names  crate A renamed through the game's own path (ItemContainer:setCustomName, as ISInventoryPage's rename
--             does): ZeD's container button shows the custom name, as the game's does (a FAIL with the detail if not)
--   each case no Lua error over it
-- Puts back: every thing the bag held, where it was; every thing the test made removed (the containers, the floor, the
-- hands, the belt); crate A removed; his stats (hunger, thirst, boredom, unhappiness, stress, fatigue, endurance,
-- calories) and the book's read pages as found; the hands and the clothes as found; the instant cheat, the grid
-- choices, the World window's container, the columns, the tabs and the pair as found; the pointer, the Ctrl and key
-- readings and the menu the game's own again.
if not RT then print("ZEDQA lv_items ERR rt_kit.lua did not run first"); print("ZEDQA lv_items DONE"); return end
local Q = RT.make("lv_items")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, crates = {}, grid = {}, used = {},
            box = {}, held = {}, errs = 0, t0 = getTimestampMs() }

S.KEY_ID = 7712904
S.SMALL = { "Base.Thread", "Base.Twine", "Base.Screws", "Base.DuctTape", "Base.Glue", "Base.Woodglue", "Base.Scotchtape",
            "Base.Paperclip", "Base.RubberBand", "Base.Pencil", "Base.Pen", "Base.Eraser", "Base.Battery", "Base.Matches",
            "Base.Candle", "Base.Sponge", "Base.Comb", "Base.Toothbrush", "Base.Spoon", "Base.Fork", "Base.Button",
            "Base.Charcoal", "Base.Cork", "Base.Twigs", "Base.Dice", "Base.Earbuds", "Base.Teabag2", "Base.SugarPacket" }
S.BACKS = { "Base.Bag_Schoolbag", "Base.Bag_NormalHikingBag", "Base.Bag_DuffelBag", "Base.Bag_BigHikingBag" }
S.GARMENTS = { "Base.Hat_BaseballCapBlue", "Base.Hat_Beany", "Base.Glasses_Aviators", "Base.Necklace_Gold",
               "Base.Gloves_LeatherGloves", "Base.Hat_BaseballCap" }
S.PIECES = { "furniture_seating_indoor_01_0", "furniture_seating_indoor_02_0", "furniture_seating_indoor_03_0",
             "furniture_seating_outdoor_01_0", "furniture_tables_high_01_0", "furniture_storage_01_0" }

-- ===================================================================== small helpers
-- (QA, Nov 23 2026: once he has read a generic book the game offers Reread, not Read, and a reread moves no mark:
-- the run of the action to its end is then the proof)
-- (QA, Nov 24 2026, after the deck run: the game's menu says Reread when the book's literature title is read,
-- ISInventoryPaneContextMenu recentlyRead, so a run after another that read the same title meets Reread)
function S.bookWord(it)
    local read = false
    pcall(function() local l = S.p:getAlreadyReadBook(); read = l ~= nil and l:contains("Base.Book") end)
    if not read and it then
        pcall(function() local t = it:getModData().literatureTitle; read = t ~= nil and S.p:isLiteratureRead(t) end)
    end
    return getText(read and "ContextMenu_ReRead" or "ContextMenu_Read")
end
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
-- a def's children, the lazy ones filled as the menu's own drill-in fills them (ContextMenuRegistry.childrenOf)
function S.kids(m, d)
    if d and d.subOption and not (d.children and #d.children > 0) then
        local R = ZeD.ContextMenu and ZeD.ContextMenu.Registry
        if R and R.childrenOf then pcall(R.childrenOf, d, m and m._ctx and m._ctx.target) end
    end
    return d and d.children or nil
end
function S.menuNames(m)
    local out = {}
    local function walk(defs, depth)
        if depth > 6 then return end
        for _, d in ipairs(defs or {}) do
            out[#out + 1] = tostring(d.name)
            walk(S.kids(m, d), depth + 1)
        end
    end
    walk(m and m._ctx and m._ctx.actions, 0)
    return out
end
-- the row names from the top down to the first row named nm, at any depth (nil when there is none)
function S.pathTo(m, nm)
    local function find(defs, depth)
        if depth > 6 then return nil end
        for _, d in ipairs(defs or {}) do
            if S.same(d.name, nm) then return { tostring(d.name) } end
        end
        for _, d in ipairs(defs or {}) do
            local sub = find(S.kids(m, d), depth + 1)
            if sub then
                table.insert(sub, 1, tostring(d.name))
                return sub
            end
        end
        return nil
    end
    return find(m and m._ctx and m._ctx.actions, 0)
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

-- ===================================================================== stats and readings, as found
S.STATS = { "HUNGER", "THIRST", "UNHAPPINESS", "BOREDOM", "STRESS", "FATIGUE", "ENDURANCE" }
function S.statOf(k) local v = nil; if CharacterStat[k] then pcall(function() v = S.p:getStats():get(CharacterStat[k]) end) end; return v end
function S.setStat(k, v) if v ~= nil and CharacterStat[k] then pcall(function() S.p:getStats():set(CharacterStat[k], v) end) end end
function S.statsSnap()
    local s = {}
    for _, k in ipairs(S.STATS) do s[k] = S.statOf(k) end
    pcall(function()
        local n = S.p:getNutrition()
        s.cal, s.carb, s.prot, s.lip = n:getCalories(), n:getCarbohydrates(), n:getProteins(), n:getLipids()
    end)
    return s
end
function S.statsBack(s)
    if not s then return end
    for _, k in ipairs(S.STATS) do S.setStat(k, s[k]) end
    pcall(function()
        local n = S.p:getNutrition()
        if s.cal then n:setCalories(s.cal) end
        if s.carb then n:setCarbohydrates(s.carb) end
        if s.prot then n:setProteins(s.prot) end
        if s.lip then n:setLipids(s.lip) end
    end)
end
function S.readPages(ft) local n = nil; pcall(function() n = S.p:getAlreadyReadPages(ft) end); return n end
-- the keys the game reads while a key is held: Ctrl and one more, answered for a few frames
function S.keysOn(key)
    if S.kd then return end
    S.kd = { ctrl = isCtrlKeyDown, down = isKeyDown }
    local down = S.kd.down
    isCtrlKeyDown = function() return true end
    isKeyDown = function(k) if k == key then return true end; return down(k) end
end
function S.keysOff()
    if not S.kd then return end
    isCtrlKeyDown, isKeyDown = S.kd.ctrl, S.kd.down
    S.kd = nil
end

-- ===================================================================== the game's own menu for this right-click
-- (QA, Nov 23 2026, after the first run: building the game's menu a second time with ZeD set aside fed a hidden stand-in
-- to every mod's and the game's own menu handlers, and the game's ISRemoveItemTool asks the real ISContextMenu for a
-- submenu of it: three Lua errors per menu. The game's menu is read instead from the game's own ISContextMenu that the
-- right-click filled and that ZeD hides and builds its rows from: every option and submenu row, the game's debug rows
-- (its Debug submenu, -debug builds only) aside.)
function S.ctxNames()
    local out = {}
    local dbg = getText("ContextMenu_Debug")
    local function walk(c, depth)
        if depth > 6 or type(c) ~= "table" then return end
        for _, o in ipairs(c.options or {}) do
            if o.name ~= nil and o.name ~= dbg then
                out[#out + 1] = tostring(o.name)
                if o.subOption then
                    local sub = nil
                    pcall(function() sub = c:getSubMenu(o.subOption) end)
                    walk(sub, depth + 1)
                end
            end
        end
    end
    local ctx = nil
    pcall(function() ctx = getPlayerContextMenu(S.pn) end)
    walk(ctx, 0)
    return out
end
function S.isMore(nm)
    if nm == nil then return false end
    if nm == getText("ContextMenu_More") then return true end
    local s = string.gsub(string.lower(tostring(nm)), "[%s%.%?]+$", "")
    return s == "more"
end
function S.setOf(list)
    local s = {}
    for _, n in ipairs(list or {}) do if not S.isMore(n) then s[string.lower(n)] = n end end
    return s
end
function S.missing(gameNames, zedNames)
    local z, g = S.setOf(zedNames), S.setOf(gameNames)
    local miss, extra = {}, {}
    for k, n in pairs(g) do if z[k] == nil then miss[#miss + 1] = n end end
    for k, n in pairs(z) do if g[k] == nil then extra[#extra + 1] = n end end
    table.sort(miss)
    table.sort(extra)
    return miss, extra
end
function S.custom(it, key)
    local c = nil
    pcall(function() c = it:getCustomMenuOption() end)
    if c ~= nil and c ~= "" then return tostring(c) end
    return getText(key)
end
function S.uses(it)
    local u = nil
    pcall(function() u = it:getCurrentUsesFloat() end)
    if u == nil then pcall(function() u = it:getCurrentUses() end) end
    return u
end
function S.fluid(it) local a = nil; pcall(function() a = it:getFluidContainer():getAmount() end); return a end
function S.inHand(it) return it ~= nil and (S.p:getPrimaryHandItem() == it or S.p:getSecondaryHandItem() == it) end
function S.selCount(c)
    local n = 0
    for _ in pairs((c and c._selectedItems) or {}) do n = n + 1 end
    return n
end
function S.clearSel(c)
    if not c then return end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    c._lastClickedItem = nil
    c._padMarks = nil
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        S.e0 = S.err0
        f.pair = RT.isOpen()
        f.world = S.worldOpen()
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "lv_items") end
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.inst = S.p:isTimedActionInstantCheat() end)
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.worn = S.wornList()
        f.stats = S.statsSnap()
        f.pages = S.readPages("Base.Book")
        f.recorded = true
        S.back.on = true
        S.guard()
        if not (RT.isOpen() and S.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
        S.instant(true)
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. S.sizeTag())
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
        if not S.charShows(S.bag) then S.showBag(S.bag) end
        S.bagOrig = S.list(S.bag)
        local free = S.freeSquares()
        S.A = free[1] and S.mkCrate(free[1], "crate A")
        if not Q.check(S.A ~= nil, "setup: crate A stands beside the character", #free .. " free squares round him") then S.dead = true; return end
        S.box.bag = S.bx("bag", S.bag)
        S.box.A = S.bx("crate A", S.A.inv)
        for _, inv in ipairs({ S.bag, S.A.inv }) do S.listView(inv) end
        S.show(S.A.inv)
    end)
    S.wait(10, 600, function() return S.shows(S.A.inv) and S.charShows(S.bag) end, function(ok)
        if not Q.check(ok, "setup: the World window shows crate A and the Character window the main inventory",
            "World on " .. S.typeOf(S.wc() and S.wc()._inventory) .. ", Character on the main inventory " .. tostring(S.charShows(S.bag))) then S.dead = true end
    end)
end

-- ===================================================================== 16. the item menu for each special kind
function S.piece(T)
    local fb, fbSpr = nil, nil
    for _, spr in ipairs(S.PIECES) do
        local it = nil
        pcall(function()
            it = instanceItem("Moveables.Moveable")
            if it and not it:ReadFromWorldSprite(spr) then it = nil end
        end)
        if it then
            local can = true
            pcall(function() can = it:CanBeDroppedOnFloor() end)
            if not can then
                pcall(function() S.p:getInventory():AddItem(it) end)
                T.spr, T.canDrop = spr, false
                return S.mark(it)
            end
            if not fb then fb, fbSpr = it, spr end
        end
    end
    if fb then
        pcall(function() S.p:getInventory():AddItem(fb) end)
        T.spr, T.canDrop = fbSpr, true
        return S.mark(fb)
    end
    return nil
end
function S.noGrid(it) local g = nil; pcall(function() g = it:getSpriteGrid() end); return g == nil end
S.KINDS = {
    { id = "pills", ft = "Base.PillsVitamins",
      keys = function(T) return { S.custom(T.it, "ContextMenu_Take_pills") } end,
      act = { how = "menu", what = "Take pills runs: the pills' uses drop",
              path = function(T) return { S.custom(T.it, "ContextMenu_Take_pills") } end,
              before = function(T) return S.uses(T.it) end,
              after = function(T, b)
                  local u = S.uses(T.it)
                  local gone = S.where(T.it) == nil
                  return gone or (u ~= nil and b ~= nil and u < b), "uses " .. tostring(b) .. " -> " .. (gone and "used up" or tostring(u))
              end } },
    { id = "lighter", ft = "Base.Lighter",
      skip = "a lighter's own options light a fire or a smoke: its options are compared only" },
    { id = "water bottle", ft = "Base.WaterBottle",
      prep = function(T)
          pcall(function() local fc = T.it:getFluidContainer(); fc:Empty(); fc:addFluid(FluidType.Water, fc:getCapacity()) end)
          S.setStat("THIRST", 0.3)
      end,
      -- (the game offers Drink from a water source only while thirst is over 0.1: set again just before each menu)
      menuPrep = function(T) S.setStat("THIRST", 0.3) end,
      keys = function(T) return { S.custom(T.it, "ContextMenu_Drink") } end,
      act = { how = "menu", what = "Drink (a quarter) runs: the water in the bottle drops",
              path = function(T) return { S.custom(T.it, "ContextMenu_Drink"), getText("ContextMenu_Eat_Quarter") } end,
              before = function(T) S.setStat("THIRST", 0.3); return S.fluid(T.it) end,
              after = function(T, b)
                  local a = S.fluid(T.it)
                  return a ~= nil and b ~= nil and a < b - 0.001, "water " .. tostring(b) .. " -> " .. tostring(a)
              end } },
    { id = "sealed can", ft = "Base.TinnedBeans", extra = { { "Base.TinOpener", 1 } },
      skip = "opening runs a craft that makes a new item: the can's options are compared only" },
    { id = "rotten food", ft = "Base.Apple",
      prep = function(T)
          pcall(function() T.it:setAge(T.it:getOffAgeMax() + 10) end)
          pcall(function() T.it:updateAge() end)
      end,
      ready = function(T) local r = false; pcall(function() r = T.it:isRotten() end); return r end,
      act = { how = "dbl", what = "a double-click (the quick use) in the bag does not eat rotten food",
              before = function(T) return S.statOf("HUNGER") end,
              after = function(T, b)
                  local h = S.statOf("HUNGER")
                  local here = S.where(T.it) == S.bag
                  return here and (h == nil or b == nil or math.abs(h - b) < 0.01),
                      (here and "still in the bag" or S.whereText(T.it)) .. ", hunger " .. tostring(b) .. " -> " .. tostring(h)
              end } },
    { id = "magazine", ft = "Base.9mmClip", extra = { { "Base.Bullets9mm", 15 } },
      prep = function(T) pcall(function() T.it:setCurrentAmmoCount(0) end) end,
      act = { how = "menu", what = "Insert bullets in the magazine runs: the magazine takes them",
              path = function(T) return { getText("ContextMenu_InsertBulletsInMagazine", T.n) } end,
              before = function(T)
                  local cur, max, have = 0, 0, 0
                  pcall(function() cur = T.it:getCurrentAmmoCount(); max = T.it:getMaxAmmo() end)
                  pcall(function() have = S.p:getInventory():getItemCountRecurse("Base.Bullets9mm") end)
                  T.n = math.min(have, max - cur)
                  return cur
              end,
              after = function(T, b)
                  local c = nil
                  pcall(function() c = T.it:getCurrentAmmoCount() end)
                  return c ~= nil and b ~= nil and c > b, "rounds " .. tostring(b) .. " -> " .. tostring(c)
              end } },
    { id = "firearm", ft = "Base.Pistol", extra = { { "Base.9mmClip", 1 } }, shot = true,
      prep = function(T) pcall(function() T.it:setContainsClip(false) end) end,
      keys = function() return { getText("ContextMenu_InsertMagazine") } end,
      act = { how = "menu", what = "Insert magazine runs: the firearm holds the magazine",
              path = function() return { getText("ContextMenu_InsertMagazine") } end,
              before = function(T) local c = nil; pcall(function() c = T.it:isContainsClip() end); return c end,
              after = function(T, b)
                  local c = nil
                  pcall(function() c = T.it:isContainsClip() end)
                  return c == true, "holds a magazine " .. tostring(b) .. " -> " .. tostring(c)
              end } },
    { id = "key", ft = "Base.Key1",
      skip = "a key onto a key ring is lv_move's case 5: the key's options are compared only" },
    { id = "book", ft = "Base.Book",
      keys = function(T) return { S.bookWord(T and T.it) } end,
      -- (QA, Nov 23 2026, after the first run: a generic book has no pages (getNumberOfPages -1) and the character was
      -- not bored, so neither moved. The game's ISReadABook:complete sets the book's read pages to its page count, -1 for
      -- a generic book, and marks its literature title read when it has one: those are the marks of a finished read.)
      act = { how = "menu", what = "Read runs and completes: the game's ISReadABook:complete marks the book read (its read pages set to its page count, its title read)",
              path = function(T) return { S.bookWord(T and T.it) } end,
              before = function(T)
                  local r = { p = S.readPages(S.ft(T.it)), b = S.statOf("BOREDOM") }
                  r.reread = S.bookWord(T.it) == getText("ContextMenu_ReRead")
                  pcall(function() r.i = T.it:getAlreadyReadPages(); r.n = T.it:getNumberOfPages() end)
                  pcall(function() r.title = T.it:getModData().literatureTitle end)
                  if r.title then pcall(function() r.lit = S.p:isLiteratureRead(r.title) end) end
                  return r
              end,
              after = function(T, b)
                  local ip, lit = nil, nil
                  pcall(function() ip = T.it:getAlreadyReadPages() end)
                  if b.title then pcall(function() lit = S.p:isLiteratureRead(b.title) end) end
                  local p, bo = S.readPages(S.ft(T.it)), S.statOf("BOREDOM")
                  local done = (b.n ~= nil and ip == b.n and b.i ~= b.n) or (lit == true and b.lit ~= true)
                      or (b.reread == true)
                      or (p ~= nil and b.p ~= nil and p > b.p) or (bo ~= nil and b.b ~= nil and bo < b.b - 0.0001)
                  return done and S.queueEmpty(), "the book's read pages " .. tostring(b.i) .. " -> " .. tostring(ip) .. " (its page count "
                      .. tostring(b.n) .. "), title " .. tostring(b.title) .. " read " .. tostring(b.lit) .. " -> " .. tostring(lit)
                      .. ", his pages " .. tostring(b.p) .. " -> " .. tostring(p) .. ", boredom " .. tostring(b.b) .. " -> " .. tostring(bo)
              end } },
    { id = "portable radio", ft = "Base.RadioRed",
      act = { how = "dbl", what = "a double-click (the quick use) in the bag puts the radio in a hand",
              after = function(T) return S.inHand(T.it), "in a hand " .. tostring(S.inHand(T.it)) .. ", " .. S.whereText(T.it) end } },
    { id = "furniture", make = function(T) return S.piece(T) end,
      skip = "placing a piece runs the game's furniture cursor: its options are compared only, its Transfer all checked below",
      tail = function(T) S.furnTail(T) end },
}
function S.kindAct(K, T)
    local A = K.act
    if not A then
        S.step(1, function() if not T.off then Q.skip("16 " .. K.id .. ": an action runs", K.skip or "no action of its own") end end)
        return
    end
    S.step(2, function()
        if T.off then return end
        if K.ready and not K.ready(T) then T.noAct = true; Q.skip("16 " .. K.id .. ": " .. A.what, "the thing could not be staged so"); return end
        T.b = A.before and A.before(T)
        if A.how == "dbl" then
            local ok, err = pcall(ZeD.InventoryRenderer.quickUse, T.it, S.pn, nil)
            T.go = ok
            if not ok then S.errs = S.errs + 1; Q.check(false, "16 " .. K.id .. ": the quick use ran", tostring(err)) end
        else
            S.openMenu({ T.it }, true)
        end
    end)
    S.wait(2, 120, function() return T.off or T.noAct or A.how == "dbl" or S.menu() ~= nil end, function(ok)
        if T.off or T.noAct or A.how == "dbl" then return end
        local path = A.path(T)
        local okP, why = false, "no ZeD menu"
        if ok then
            local names = S.menuNames(S.menu())
            -- (a row inside a submenu, B42's Fluid among them: picked through its submenus)
            local lead = S.pathTo(S.menu(), path[1])
            if lead and #lead > 1 then
                for i = 2, #path do lead[#lead + 1] = path[i] end
                path = lead
            end
            okP, why = S.pick(S.menu(), path)
            if not okP then why = why .. "; the menu: " .. table.concat(names, ", ") end
        end
        T.go = Q.check(okP, "16 " .. K.id .. ": the menu's " .. table.concat(path, " > ") .. " runs", why)
        if not okP then S.closeMenu() end
    end)
    S.wait(4, 1800, S.settled(15), function()
        if T.off or T.noAct or not T.go then return end
        local ok, d = A.after(T, T.b)
        Q.check(ok, "16 " .. K.id .. ": " .. A.what, d)
    end)
end
function S.kindCase(K)
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if K.make then T.it = K.make(T) else T.it = S.give(K.ft) end
        if not T.it then T.off = true; Q.skip("16 " .. K.id, "the thing could not be made (" .. tostring(K.ft) .. ")"); return end
        for _, e in ipairs(K.extra or {}) do for _ = 1, e[2] do S.give(e[1]) end end
        if K.prep then pcall(K.prep, T) end
        S.dirty()
    end)
    S.step(4, function()
        if T.off then return end
        if K.menuPrep then pcall(K.menuPrep, T) end
        S.openMenu({ T.it }, true)
    end)
    S.wait(2, 120, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok, "16 " .. K.id .. ": the item menu opens (ZeD's menu)") then T.off = true; return end
        local zed = S.menuNames(S.menu())
        local game = S.ctxNames()
        local miss, extra = S.missing(game, zed)
        Q.check(#miss == 0 and #game > 0, "16 " .. K.id .. ": ZeD's item menu shows every option of the game's menu for this right-click (the game's own hidden menu, its debug rows aside)",
            "game " .. #game .. " names, ZeD " .. #zed .. ((#miss > 0) and ("; MISSING: " .. table.concat(miss, ", ")) or "")
            .. "; ZeD's rows the game's menu lacks: " .. ((#extra > 0) and table.concat(extra, ", ") or "none"))
        local keys = K.keys and K.keys(T) or {}
        if #keys > 0 then
            local z = S.setOf(zed)
            local lack = {}
            for _, k in ipairs(keys) do if z[string.lower(k)] == nil then lack[#lack + 1] = k end end
            Q.check(#lack == 0, "16 " .. K.id .. ": the key options are there (" .. table.concat(keys, ", ") .. ")",
                (#lack == 0) and "all there" or ("missing " .. table.concat(lack, ", ") .. "; the menu: " .. table.concat(zed, ", ")))
        end
    end)
    if K.shot then S.shot("lv_items_menu_" .. S.sizeTag(), "the item menu of a firearm, its magazine and rounds in the bag") end
    S.step(2, function() S.closeMenu() end)
    S.kindAct(K, T)
    if K.tail then K.tail(T) end
    Q.step(2, function()
        if S.dead then return end
        S.statsBack(S.found.stats)
        S.caseClean()
    end)
    S.caseEnd("16 " .. K.id)
end
-- the furniture piece through Transfer all to the floor, from a bag held in the hand
function S.furnTail(T)
    local F = {}
    S.step(2, function()
        if T.off then F.off = true; return end
        local bk, k = S.unique(S.BACKS), S.unique(S.SMALL)
        if not (bk and k) then F.off = true; Q.skip("16 furniture: Transfer all to the floor", "no bag or small kind left"); return end
        F.bag = S.give(bk)
        pcall(function() S.p:setSecondaryHandItem(F.bag) end)
        F.binv = F.bag:getInventory()
        S.put(T.it, F.binv)
        F.small = S.add(F.binv, k)
        pcall(function() F.floor = ZeD_WorldWindow.getFloorContainer(S.pn) end)
        if not F.floor then pcall(function() F.floor = ISInventoryPage.GetFloorContainer(S.pn) end) end
        F.stays = (not T.canDrop) and S.noGrid(T.it)
        F.c0 = S.census({ S.bx("the held bag", F.binv), S.floorBox(1) })
        local ok, err = pcall(ZeD.ContainerControls.transferAll, S.p, F.binv, F.floor)
        if not ok then S.errs = S.errs + 1; F.off = true; Q.check(false, "16 furniture: Transfer all to the floor ran", tostring(err)) end
    end)
    S.wait(4, 900, S.settled(10), function()
        if F.off then return end
        local ok, d = S.audit(F.c0, function(it)
            if it == F.small then return "floor" end
            if it == T.it and not F.stays then return "floor" end
        end)
        Q.check(ok and (S.where(T.it) == F.binv) == F.stays,
            "16 furniture: Transfer all to the floor " .. (F.stays and "leaves the piece in the bag (the game's rule: a piece that cannot lie on the floor stays)" or "drops the piece (it can lie on the floor)")
            .. " and drops the rest", "the piece " .. tostring(T.spr) .. ", CanBeDroppedOnFloor " .. tostring(T.canDrop) .. ", " .. S.whereText(T.it) .. "; " .. d)
    end)
end

-- ===================================================================== 17. Rename a bag, Unpack, Favorite, Wanted
function S.round(T, label, getItems, inInv, getPath, verify, between)
    local R = {}
    S.step(4, function()
        if T.off then R.off = true; return end
        R.items = getItems()
        if not (R.items and #R.items > 0) then R.off = true; Q.skip(label, "nothing to open the menu on"); return end
        S.openMenu(R.items, inInv)
    end)
    S.wait(2, 120, function() return R.off or S.menu() ~= nil end, function(ok)
        if R.off then return end
        local path = getPath()
        local okP, why = false, "no ZeD menu"
        if ok then
            local names = S.menuNames(S.menu())
            -- (a row inside a submenu, B42's Fluid among them: picked through its submenus)
            local lead = S.pathTo(S.menu(), path[1])
            if lead and #lead > 1 then
                for i = 2, #path do lead[#lead + 1] = path[i] end
                path = lead
            end
            okP, why = S.pick(S.menu(), path)
            if not okP then why = why .. "; the menu: " .. table.concat(names, ", ") end
        end
        R.go = Q.check(okP, label .. ": the item menu's " .. table.concat(path, " > ") .. " runs", why)
        if not okP then S.closeMenu() end
    end)
    if between then between(R) end
    S.wait(4, 900, S.settled(8), function()
        if R.off or not R.go then return end
        local ok, d = verify(R)
        Q.check(ok, label, d)
    end)
end
function S.renameBox()
    local t = RT.find(function(x) return x.entry ~= nil and x.yes ~= nil and x.onclick ~= nil end)
    return t
end
function S.case17()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        local bk, k = S.unique(S.BACKS), S.unique(S.SMALL)
        if not (bk and k) then T.off = true; Q.skip("17 menu rows", "no bag or small kind left"); return end
        T.bag = S.give(bk)
        T.binv = T.bag:getInventory()
        T.inner = S.add(T.binv, k)
        T.thing = S.give(S.unique(S.SMALL) or "Base.Twine")
        S.dirty()
    end)
    S.round(T, "17 Rename a bag: the game's box takes the new name", function() return { T.bag } end, true,
        function() return { getText("ContextMenu_RenameBag") } end,
        function() local n = S.ft(T.bag); pcall(function() n = T.bag:getName() end); return n == "LV Renamed", "the bag is named \"" .. tostring(n) .. "\"" end,
        function(R)
            S.wait(2, 180, function() return R.off or not R.go or S.renameBox() ~= nil end, function(ok)
                if R.off or not R.go then return end
                local box = S.renameBox()
                if not box then R.go = Q.check(false, "17 Rename a bag: the name box opens"); return end
                local okB, err = pcall(function() box.entry:setText("LV Renamed"); box:onClick(box.yes) end)
                if not okB then S.errs = S.errs + 1; R.go = Q.check(false, "17 Rename a bag: the name box takes the name and OK", tostring(err)) end
            end)
        end)
    S.step(2, function()
        if T.off then return end
        T.c0 = S.census({ S.box.bag, S.bx("the carried bag", T.binv) })
    end)
    S.round(T, "17 Unpack: the thing in the carried bag comes to the main inventory, nothing else moves", function() return { T.inner } end, true,
        function() return { getText("ContextMenu_Unpack") } end,
        function() return S.audit(T.c0, function(it) if it == T.inner then return "bag" end end) end)
    S.round(T, "17 Favorite: the thing is a favorite", function() return { T.thing } end, true,
        function() return { getText("IGUI_CraftUI_Favorite") } end,
        function() local f = false; pcall(function() f = T.thing:isFavorite() end); return f == true, "favorite " .. tostring(f) end)
    S.round(T, "17 Unfavorite: the thing is a favorite no more", function() return { T.thing } end, true,
        function() return { getText("ContextMenu_Unfavorite") } end,
        function() local f = true; pcall(function() f = T.thing:isFavorite() end); return f == false, "favorite " .. tostring(f) end)
    S.round(T, "17 Unwanted: the thing is unwanted", function() return { T.thing } end, true,
        function() return { getText("ContextMenu_Unwanted") } end,
        function() local u = false; pcall(function() u = T.thing:isUnwanted(S.p) end); return u == true, "unwanted " .. tostring(u) end)
    S.round(T, "17 Wanted: the thing is wanted again", function() return { T.thing } end, true,
        function() return { getText("ContextMenu_Wanted") } end,
        function() local u = true; pcall(function() u = T.thing:isUnwanted(S.p) end); return u == false, "unwanted " .. tostring(u) end)
    Q.step(2, function() if not S.dead then S.caseClean() end end)
    S.caseEnd("17 menu rows")
end

-- ===================================================================== 18. Shift + double-click on a garment in a crate
function S.dblMods(c, item, shift, ctrl)
    local z = S.zone(c, item)
    if not z then return false, "the row is not on screen" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil
    local ok, err = S.withGlobals({ isShiftKeyDown = function() return shift end, isCtrlKeyDown = function() return ctrl end }, function()
        c:onMouseDown(x, y)
        c:onMouseUp(x, y)
        c:onMouseDown(x, y)
        c:onMouseUp(x, y)
    end)
    if not ok then S.errs = S.errs + 1 end
    return ok, ok and "double-clicked" or tostring(err)
end
function S.case18()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        for _, ft in ipairs(S.GARMENTS) do
            if not T.g and S.known(ft) then
                local it = S.add(S.A.inv, ft)
                local free = false
                pcall(function() free = S.p:getWornItem(it:getBodyLocation()) == nil end)
                if free then T.g = it else S.removeItem(it) end
            end
        end
        if not T.g then T.off = true; Q.skip("18 Shift + double-click", "no garment whose place on him is free"); return end
        local wc = S.wc()
        S.clearSel(wc)
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(6, 300, function() return T.off or (S.shows(S.A.inv) and S.zone(S.wc(), T.g) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, "18 Shift + double-click: the garment's row is on crate A's list", S.ft(T.g)) then T.off = true; return end
        S.reveal(S.wc(), T.g)
    end)
    S.step(4, function()
        if T.off then return end
        T.c0 = S.census({ S.box.bag, S.box.A })
        local ok, why = S.dblMods(S.wc(), T.g, true, false)
        T.go = Q.check(ok, "18 Shift + double-click: the garment's row in the crate takes a Shift + double-click", why)
    end)
    Q.waitMs(1000)
    S.wait(4, 900, S.settled(15), function()
        if T.off or not T.go then return end
        local worn = false
        pcall(function() worn = S.p:isEquippedClothing(T.g) end)
        local picked = S.wc() ~= nil and S.wc()._selectedItems ~= nil and S.wc()._selectedItems[T.g] ~= nil
        Q.check(worn, "18 Shift + double-click on a garment in a crate takes it and wears it, as the game does (ISInventoryPane:onMouseDoubleClick)",
            S.ft(T.g) .. " worn " .. tostring(worn) .. ", " .. S.whereText(T.g) .. ", picked on the list " .. tostring(picked)
            .. (worn and "" or "; GAP vs the game: ZeD's lists skip the quick use while Shift is held (ZeD_WorldWindow.lua ~6078, ZeD_CharacterWindow.lua ~7318)"))
        S.clearSel(S.wc())
    end)
    Q.step(2, function() if not S.dead then S.caseClean() end end)
    S.caseEnd("18 Shift + double-click")
end

-- ===================================================================== 19. Ctrl+A
function S.case19()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        for _ = 1, 3 do
            local k = S.unique(S.SMALL)
            if k then S.add(S.A.inv, k) end
        end
        S.clearSel(S.wc())
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(6, 300, function() return S.shows(S.A.inv) and #(S.wc()._flatItems or {}) >= 3 end, function(ok)
        T.rows = #(S.wc() and S.wc()._flatItems or {})
        if not Q.check(ok, "19 Ctrl+A: crate A's list shows its rows", T.rows .. " rows") then T.off = true; return end
        S.clearSel(S.wc())
        -- (the director, Nov 23 2026, in Build's session: "Keep double-click": no Ctrl+A, as on Nov 10 (punch list 146);
        -- a double press on the list's empty space picks every row (ZeD_BoxSelect.doubleEmpty))
        local wc = S.wc()
        local px, py = nil, nil
        if wc then
            local h = wc:getHeight()
            for yy = h - 6, math.floor(h / 2), -8 do
                local z = nil
                pcall(function() z = wc:hitZoneAt(24, yy) end)
                if z == nil then px, py = 24, yy; break end
            end
        end
        T.at = px and (px .. "," .. py) or "no empty space found"
        if px then
            pcall(function() wc:onMouseDown(px, py) end)
            pcall(function() wc:onMouseUp(px, py) end)
            pcall(function() wc:onMouseDown(px, py) end)
            pcall(function() wc:onMouseUp(px, py) end)
        end
    end)
    Q.step(8, function()
        if S.dead or T.off then return end
        local n = S.selCount(S.wc())
        Q.check(n == T.rows and n > 0, "19 a double-click on the list's empty space picks every row (the director's choice over Ctrl+A)",
            n .. " of " .. T.rows .. " rows picked, the double press at " .. tostring(T.at))
        S.clearSel(S.wc())
    end)
    Q.step(2, function() if not S.dead then S.caseClean() end end)
    S.caseEnd("19 Ctrl+A")
end

-- ===================================================================== 20. a stack of 150 nails: drag, Move To, Loot all
function S.nailsIn(inv) return S.countKind(inv, "Base.Nails") end
function S.case20()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if not S.known("Base.Nails") then T.off = true; Q.skip("20 nails", "no Base.Nails"); return end
        T.own = S.nailsIn(S.bag)
        for _ = 1, 150 do S.give("Base.Nails") end
        local cc = S.cc()
        if cc and cc._expandedStacks then cc._expandedStacks["Base.Nails"] = nil end
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(6, 300, function() return T.off or (S.shows(S.A.inv) and S.rep(S.cc(), "Base.Nails") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok and S.nailsIn(S.bag) == 150 + T.own, "20 nails: the bag shows a closed stack of 150 nails (and his own " .. T.own .. ")",
            S.nailsIn(S.bag) .. " in the bag") then T.off = true; return end
        S.reveal(S.cc(), S.rep(S.cc(), "Base.Nails"))
    end)
    S.step(4, function()
        if T.off then return end
        local rep, st = S.rep(S.cc(), "Base.Nails")
        T.set = {}
        for _, x in ipairs((st and st.items) or {}) do T.set[x] = true end
        T.c0 = S.census({ S.box.bag, S.box.A })
        local ok, why = S.drag(S.cc(), rep, S.wc())
        T.d = Q.check(ok, "20 nails: the stack's row drags from the bag and drops on crate A", why)
    end)
    S.wait(4, 2400, S.settled(15), function()
        if T.off or not T.d then return end
        local ok, d = S.audit(T.c0, function(it, k0) if k0 == "bag" and T.set[it] then return "crate A" end end, true)
        Q.check(ok and S.nailsIn(S.A.inv) == 150 + T.own, "20 nails, by the drag: all " .. (150 + T.own) .. " in crate A, none left, none doubled, nothing else moved",
            S.nailsIn(S.A.inv) .. " in A, " .. S.nailsIn(S.bag) .. " in the bag; " .. d)
        T.inA = {}
        for _, it in ipairs(S.list(S.A.inv)) do if S.ft(it) == "Base.Nails" then T.inA[#T.inA + 1] = it end end
        T.c1 = S.census(T.c0.list)
        S.openMenu(T.inA, false)
    end)
    S.wait(2, 300, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local okP, why = false, "no ZeD menu"
        if ok then okP, why = S.pick(S.menu(), { getTextOrNull("ContextMenu_Move_To") or "Move To", getTextOrNull("ContextMenu_MoveToInventory") or "Inventory" }) end
        T.m = Q.check(okP, "20 nails: the " .. #T.inA .. " nails' menu has Move To > Inventory and it runs", why)
        if not okP then S.closeMenu() end
    end)
    S.wait(4, 2400, S.settled(15), function()
        if T.off or not T.m then return end
        local ok, d = S.audit(T.c1, function(it, k0) if k0 == "crate A" and S.ft(it) == "Base.Nails" then return "bag" end end, true)
        Q.check(ok and S.nailsIn(S.bag) == 150 + T.own, "20 nails, by Move To: all " .. (150 + T.own) .. " back in the bag, none left, none doubled",
            S.nailsIn(S.bag) .. " in the bag, " .. S.nailsIn(S.A.inv) .. " in A; " .. d)
        -- (into the crate by hand for Loot all)
        for _, it in ipairs(S.list(S.bag)) do if S.ft(it) == "Base.Nails" then S.put(it, S.A.inv) end end
        S.dirty()
        S.rebuild()
    end)
    S.wait(6, 300, function() return T.off or (S.shows(S.A.inv) and S.spec(S.wc(), "take") ~= nil and S.spec(S.wc(), "take").enabled) end, function(ok)
        if T.off then return end
        T.c2 = S.census(T.c0.list)
        local okP, why = false, "no Loot all on crate A: " .. S.specIds(S.wc())
        if ok then okP, why = S.press(S.wc(), "take") end
        T.l = Q.check(okP, "20 nails: Loot all presses on crate A (" .. S.nailsIn(S.A.inv) .. " nails put in by hand)", why)
    end)
    S.wait(4, 2400, S.settled(15), function()
        if T.off or not T.l then return end
        local ok, d = S.audit(T.c2, function(it, k0) if k0 == "crate A" then return "bag" end end, true)
        Q.check(ok and S.nailsIn(S.bag) == 150 + T.own, "20 nails, by Loot all: all " .. (150 + T.own) .. " in the bag, none left, none doubled",
            S.nailsIn(S.bag) .. " in the bag, " .. S.nailsIn(S.A.inv) .. " in A; " .. d)
    end)
    Q.step(2, function() if not S.dead then S.caseClean() end end)
    S.caseEnd("20 nails")
end

-- ===================================================================== 21. a container's own name
function S.case21()
    local T = {}
    S.step(2, function()
        local ok = pcall(function() S.A.inv:setCustomName("LV Named Crate") end)
        local cn = nil
        pcall(function() cn = S.A.inv:getCustomName() end)
        if not (ok and cn == "LV Named Crate") then T.off = true; Q.skip("21 names", "the container takes no custom name here (setCustomName)"); return end
        pcall(function() RT.ww()._containerTimer = 30 end)
    end)
    S.wait(6, 300, function()
        if T.off then return true end
        local e = S.entryOf(RT.ww(), S.A.inv)
        return e ~= nil and e.name == "LV Named Crate"
    end, function(ok)
        if T.off then return end
        local e = S.entryOf(RT.ww(), S.A.inv)
        Q.check(ok, "21 names: a crate renamed the game's way (setCustomName) shows its own name on ZeD's container button, as the game's does (ISInventoryPage)",
            "ZeD shows \"" .. tostring(e and e.name) .. "\", the game would show \"LV Named Crate\""
            .. (ok and "" or "; GAP vs the game: ZeD_WorldWindow.lua's container list titles an object's container by its name or its type's words, never getCustomName (~3035-3044)"))
        pcall(function() S.A.inv:setCustomName(nil) end)
        pcall(function() RT.ww()._containerTimer = 30 end)
    end)
    S.caseEnd("21 names")
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.park(false)
    S.keysOff()
    S.haloOff()
    S.qOff()
    S.cancelDrags()
    S.closeMenu()
    pcall(function() local b = S.renameBox(); if b then b:destroy() end end)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if S.A then pcall(function() S.A.inv:setCustomName(nil) end) end
    if S.bag then S.restoreBag() end
    for _, it in ipairs(S.made) do S.removeItem(it) end
    for _, c in ipairs(S.crates) do S.rmCrate(c) end
    S.handsBack()
    S.wornBack()
    S.statsBack(f.stats)
    if f.pages ~= nil then pcall(function() S.p:setAlreadyReadPages("Base.Book", f.pages) end) end
    local st = S.p:getModData().ZeD_GridViews
    if st then for key, v in pairs(S.grid) do if v == "NIL" then st[key] = nil else st[key] = v end end end
    S.dirty()
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        S.putBack()
        if not (RT.isOpen() and S.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
        local f = S.found
        if f.pos then
            local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
            if dx > 0.01 or dy > 0.01 then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        end
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
        Q.check(crates == 0, "put back: crate A is gone", crates .. " crates left")
        local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        Q.check(f.hands == nil or (hp == f.hands.p and hs == f.hands.s), "put back: the hands hold what they held")
        local worn, on = 0, S.wornSet()
        for _, e in ipairs(f.worn or {}) do if on[e.item] then worn = worn + 1 end end
        Q.check(worn == #(f.worn or {}), "put back: he wears what he wore", worn .. " of " .. #(f.worn or {}))
        local bad = {}
        for _, k in ipairs(S.STATS) do
            local v = S.statOf(k)
            if v ~= nil and f.stats and f.stats[k] ~= nil and math.abs(v - f.stats[k]) > 0.02 then bad[#bad + 1] = k .. " " .. string.format("%.3f", v) .. " (was " .. string.format("%.3f", f.stats[k]) .. ")" end
        end
        Q.check(#bad == 0, "put back: his stats as found (hunger, thirst, unhappiness, boredom, stress, fatigue, endurance)", (#bad == 0) and "as found" or table.concat(bad, "; "))
        Q.check(S.kd == nil and S.parked == nil and S.renameBox() == nil, "put back: the Ctrl and key readings, the pointer and the menus are the game's own again")
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the item run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the item run's Lua error count", "the game's Lua error count cannot be read here") end
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
    for _, K in ipairs(S.KINDS) do S.kindCase(K) end
    S.case17()
    S.case18()
    S.case19()
    S.case20()
    S.case21()
end
S.build()
S.buildPutBack()
Q.start()
