-- ZeDUI/tools/qa/vk3_win.lua  (Nov 22 2026, QA KISS batch K3; tag vk3_win): the in-game proof of the director's
-- K3 picks for the windows, lists and keys (ZeDUI/qa/audits/2026-11-22_kiss_calls_K3.md): #7, #9, #10, #11, #13,
-- #16, #19, #25, #31, #41, #44 and #45. The old code is 0b366177e; the new code is 7b8ed6843 (the merge ae3f4a2b2 of
-- branch k3: 32b6eb4a1 World window, 7e249bda2 lists, 6d5cbe8c8 windows, 2dd9cd3e7 belt, ff3cd87d1 settings).
-- Built on rt_kit.lua (the global RT) and the prelude's car helpers (ZEDQA_CAR_*), run after zedqa_prelude.lua.
-- grep "ZEDQA vk3_win". Manifest line (QA's): vk3_win.lua | vk3_win | timeout=600
--
-- How to read the log: the proofs are the lines whose words start "#<n>"; each FAILS on 0b366177e and PASSES on
-- 7b8ed6843. A part that cannot be staged is a FAIL whose words end "(staging)"; a press point a real click could not
-- reach on this screen (under the other window or the belt) is a SKIP, said plainly. "NOTE" lines are readings.
-- The put-back checks at the end pass on both: they say the run left him as it found him.
--
-- The scene: the run starts at the drag strip (ZEDQA_HOME), both windows shut. Two crates (carpentry_01_16) beside
-- him: crate A on the square he faces (turned to a free side square when the one he faces is taken), crate B on
-- another side square, holding a pencil, a pen, an eraser and 6 nails. Given to him: a key ring, a sledgehammer, a
-- hammer and a second pencil. ZeD's input mode is locked to the mouse for the run (vx12_wheel.lua's lock); the one
-- pad press (#25d) goes through FocusManager's own dispatch.
--
-- The pointer is the one thing faked: for each press, move and release the global getMouseX / getMouseY answer the
-- point for that call only (vk2_mouse.lua's H.atPointer), and ZeD's lists and strips answer their Java isMouseOver as
-- the point says (H.overOnly: the list the point is on says yes, the rest no). Ctrl held is faked the same way
-- (the global isCtrlKeyDown answers for one call). Points come from the zones ZeD stamps, never written in pixels,
-- so it runs at 4K (UI scale 1.75) and 1280x800. Waits go by the clock.
--
-- The checks, what each reads, and what the old code does:
--   #9   The tab side starts pinned. The pins of a new character: the save's pin tables (modData ZeD_WinPinned and
--        ZeD_WinPinnedK9) taken away, both windows opened by the inventory key (ZeD_CharacterWindow._onKeyPressed),
--        each window's halves read (win._halves): the tab side (drawer) pinned, the inventory side not. Then shut
--        and the tables put back. Old: both halves start unpinned -> FAIL.
--   #16  A bag button at the belt's left end opens both windows. With both shut, the belt drawn: its box of kind
--        "bag" pressed where a click lands (the belt's own onMouseDown and onMouseUp); within 3 s both windows are
--        open. Old: the belt has no bag box -> FAIL. (A belt not drawn here: SKIP.)
--   #13a The World window opens on the container he faces. Both opened by the inventory key with crates A (faced)
--        and B in reach: the container on show (win._containers[win._activeContainer]) is crate A, shown alone,
--        and the list draws crate A. Old: it opens on the Floor -> FAIL.
--   #44  The container on show is lit in the world per the game's outline option. Crate A on show alone (Loot):
--        crate A's object isHighlighted(player) and isOutlineHighlight(player) equals the game's container outline
--        option, crate B dark; then crate B shown by a plain click on its picture: B lit, A dark. Old: nothing is
--        lit -> FAIL.
--   #10a A plain click on a container's picture shows it alone (World window). Crate A on show; a press on crate
--        B's picture in the strip (its onMouseDown, Ctrl not held): crate B is the container on show, no columns,
--        the list draws crate B. Old: the click adds B as a column beside what was on show -> FAIL.
--   #10b Ctrl-click adds a column (World window). Then Ctrl held, a press on crate A's picture: the list shows
--        exactly crate A and crate B side by side (A a column, B still shown). Old: B and A were both added as
--        columns beside the Floor, three lists -> FAIL.
--   #10c The same in the Character window's bag strip (the director: "Yes, Character window bags too"). His list on
--        his inventory; a plain click on the key ring's picture (press and release on its "cnt:" zone): the key ring
--        alone (no columns, his inventory hidden, the list draws the key ring). Old: the key ring is added as a
--        column beside his inventory -> FAIL.
--   #10d Then Ctrl held, a press on his inventory's picture ("main_toggle"): his inventory added beside the key ring
--        (the key ring a column, his inventory shown). Old: after the old click the press hid his inventory -> FAIL.
--   #45  A Pick all button in the list's heading. Crate B on show; the heading's "view:all:" zone pressed: every
--        row of the list is picked (the list's own _selectedItems holds each of its _flatItems). Old: no such
--        button -> FAIL.
--   #31  A closed stack's right-click has Grab one, Grab half and Grab all. The 6 nails in crate B, their stack shut;
--        a right-click on the stack's row (the list's onRightMouseUp): the game's menu holds Grab one, Grab half and
--        Grab all (getOptionFromName with the game's words). Old: one Grab that takes all -> FAIL. (Menu closed.)
--   #7a  The right-click menu is the word list for a new player; the strip is still a ZeD setup choice. ZeD setup's
--        Context menu option read: its default (the item it starts on, zedDefault, what Defaults sets and the help
--        band names) set for this check (then put back); a right-click on the pencil's row opens ZeD_ContextList
--        (the word list); the option still has two items (the strip, the list) and stands in ZeD setup's groups.
--        Old: its default is the strip, the right-click opens ZeD_ContextMenu -> FAIL.
--   #7b  Loot all and Transfer all are word buttons. The band under crate B's list and under his own list, as laid
--        out (content._cc.bottom.rects): "take" (Loot all) and "xfer" (Transfer all) have no icon and read the
--        game's words. Old: both are pictures (tray_in, tray_out) -> FAIL. (Refit Nov 22 2026 for branch listgrid
--        1916f88ab, the director's "Transfer buttons, always in the footer": the World band's Take all is back, its
--        first button, and the single list's heading has none; strict again: no band Take all -> FAIL.)
--   #19  The drag chip reads No room over a container that cannot take the drag. Crate A's capacity set to 2 for
--        this check (the run's crate); a sledgehammer (6.0) dragged from his list (press and a 40 px move: the drag
--        is live) and held over crate A's list; the drag's chip drawn (ZeD_DragState:drawGhost, into a recorder that
--        keeps the words and border colours): the words "No room" (UI_ZeD_Drag_NoRoom) in the danger colour border;
--        held over his own list the same chip reads its weight, no No room. Old: the chip shows the weight over
--        crate A too, with the accent border -> FAIL. (The drag is let go without a drop.)
--   #11a Worn and held things in their own group at the top of his list, by default, and ZeD setup's choice exists.
--        The Worn and held option (wornInList) read: two items, starts on the first (the list), in ZeD setup's groups,
--        set to its default for the check. The hammer put in his hand: his list holds the hammer's row in the group
--        "zed:worn", and the worn and held rows lead the list (no worn row after another row). Old: no such option,
--        and what he holds or wears is not in the list -> FAIL.
--   #11b A double-click on a worn or held row takes it off. A double-click on the hammer's row (two clicks, the
--        list's own handlers): the game's ISUnequipAction for the hammer is queued (read at once, then the queue is
--        cleared: nothing is taken off). Old: no hammer row to click -> FAIL.
--   #41  Paused, a move between bags is allowed under the veil and runs on play; other actions stay grayed. Crate B
--        on show; the game paused (speed 0); the press on the second pencil's row is routed as the screen routes it:
--        first to ZeD's pause glass or veil over that point (it takes the press when it eats it or consumes mouse
--        events); not taken, the row is dragged and let go over crate B's list (the build note: a drag to the other
--        window's list, under the veil). Read: a glass or veil lies over the row; the press reaches the list; the
--        game's move of the pencil to crate B is queued and has not run while paused; a right-click on the pen's row
--        in crate B (routed the same way) opens no menu; once the game plays again the pencil reaches crate B within
--        10 s. Old: the glass over the list eats the press, nothing moves -> FAIL.
--   #25a The same key again closes what it opened: H. Both shut; the game's Health page asked for twice, as its
--        key does (getPlayerInfoPanel(n):toggleView(Health), which ZeD routes): the first opens both on Health, the
--        second shuts both. Old: the second only folds the tab, both stay -> FAIL.
--   #25b B (Building): the game's build window asked for twice (ISEntityUI.OpenBuildWindow(player, nil, "*"), what
--        the Build button and the game's wheel call; ZeD routes it): the first opens the World window on Build, the
--        second shuts it. Old: the second folds the tab, the window stays -> FAIL.
--   #25c M: the game's map toggle twice (ISWorldMap.ToggleWorldMap, what the Map key calls): the first opens ZeD's
--        map with the World window it opened, the second puts away both. Old: the World window stays -> FAIL.
--        (No map here, too dark to read: SKIP.)
--   #25d B on the map: the map opened again the same way, the pad on it (Focus.claimFocus on the map, its stops
--        built), B through FocusManager's own dispatch: the map and the World window it opened shut. Old: the map
--        folds into a World window that stays -> FAIL. (No stop with a B answer on the map here: SKIP.)
--   #13b Seated, the World window lands on the glove box, not the Floor. A Base.CarNormal by the prelude's helper,
--        him in the driver's seat (ZEDQA_CAR_ENTER), both opened by the inventory key: the container on show is the
--        car's glove box and the list holds no Floor. Old: the Floor, always empty, is on show -> FAIL.
--
-- Safety: nothing is eaten, drunk, read or worn; the one queued unequip (#11b) is cleared at once; the moves are of
-- the run's own things; the car is only sat in, the engine never starts. Every queue the run starts is cleared.
-- What it puts back (also when a step throws or the time runs out): any drag let go, menus closed, the game playing
-- at the speed found, the queue cleared, the pad's focus released if the run took it; ZeD setup's Context menu and
-- Worn and held as found (never saved); everything given or made taken away (his inventory, the crates, the ground),
-- both crates removed, his hands as found, the car removed and him back where he stood, facing as found; the lists'
-- grid choices, stack and group folds; the save's window state and pin tables as found; both windows open or shut,
-- placed, sized and on the tabs found; the input lock and the mode ZeD reads. No option is saved, no file written,
-- ZEDQA_LAYOUT_BACK is never called.
-- Not run offline; parse-checked with the game's Kahlua compiler (KCheck).
-- (Nov 23 2026, QA: ZeD's plug-in points (Build's fix/plugins) splice an add-on's rows into a ZeD setup group;
-- H.inGroups reads G.groupRows(g) where it exists, else the group's own list, g[2].)

if not (RT and RT.make) then
    print("ZEDQA vk3_win ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk3_win VERDICT FAIL 1")
    print("ZEDQA vk3_win DONE")
    return
end

local Q = RT.make("vk3_win")
Q.maxMs = 480000   -- (eight minutes, then the put-back; a run takes about three)
local S = { p = RT.p, pn = RT.pn, was = {}, made = {}, seek = {}, grid = {}, folds = {}, stacks = {}, menuDone = {},
    k7 = {}, k9 = {}, k10 = {}, k11 = {}, k13 = {}, k16 = {}, k19 = {}, k25 = {}, k31 = {}, k41 = {}, k44 = {}, k45 = {} }
local H = {}   -- shared helpers
local N = {}   -- the crates and the squares
local P = {}   -- the pause
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector
S.Focus = ZeD and ZeD.Input and ZeD.Input.Focus
S.WORN = "zed:worn"

-- ===================================================================== words, numbers, tables
function H.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function H.nm(it)
    if it == nil then return "nothing" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or "?")
end
function H.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    local out = {}
    for k, v in pairs(t) do out[k] = (depth < 6) and H.copy(v, depth + 1) or v end
    return out
end
function H.same(a, b, depth)
    depth = depth or 0
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    if depth > 6 then return true end
    for k, v in pairs(a) do if not H.same(v, b[k], depth + 1) then return false end end
    for k, v in pairs(b) do if a[k] == nil and v ~= nil then return false end end
    return true
end
function H.count(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
function H.list(t) local out = {}; for _, v in ipairs(t or {}) do out[#out + 1] = tostring(v) end; return table.concat(out, ", ") end
function H.md() return S.p:getModData() end

-- ===================================================================== things
function H.main() return S.p:getInventory() end
function H.where(it)
    if it == nil then return nil end
    local c = nil
    pcall(function() c = it:getContainer() end)
    if c == nil then return nil end
    local inList = true
    pcall(function() inList = c:getItems():contains(it) end)
    return inList and c or nil
end
function H.track(it)
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        S.made[#S.made + 1] = it
    end
    return it
end
function H.give(ft)
    local it = RT.give(ft)
    if it then S.made[#S.made + 1] = it end
    return it
end
function H.addTo(inv, ft)
    local it = nil
    if inv then pcall(function() it = inv:AddItem(ft) end) end
    return H.track(it)
end
function H.onFloor(it)
    local on = false
    pcall(function()
        local wo = it:getWorldItem()
        local sq = wo and wo:getSquare()
        on = sq ~= nil and sq:getWorldObjects():contains(wo)
    end)
    return on and true or false
end
function H.removeItem(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() wo:setSquare(nil) end)
        end
    end)
    pcall(function() if it:getWorldItem() then it:setWorldItem(nil) end end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    pcall(function() if it:getContainer() ~= nil then it:setContainer(nil) end end)
end
function H.handsBack()
    local hw = S.was.hand
    if not hw then return end
    pcall(function()
        if S.p:getPrimaryHandItem() ~= hw.p and (hw.p == nil or H.where(hw.p) ~= nil) then S.p:setPrimaryHandItem(hw.p) end
    end)
    pcall(function()
        if S.p:getSecondaryHandItem() ~= hw.s and (hw.s == nil or H.where(hw.s) ~= nil) then S.p:setSecondaryHandItem(hw.s) end
    end)
end

-- ===================================================================== the action queue
function H.queue()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue) or {}
end
function H.queueText()
    local out = {}
    for i, a in ipairs(H.queue()) do
        if i > 6 then out[#out + 1] = "..."; break end
        out[#out + 1] = tostring((type(a) == "table" and a.Type) or "?")
    end
    return (#out > 0) and table.concat(out, ", ") or "nothing"
end
function H.clearQueue() pcall(function() ISTimedActionQueue.clear(S.p) end) end
-- the queued action that carries item (and, when dest is given, goes to dest)
function H.actionFor(item, typ, dest)
    for _, a in ipairs(H.queue()) do
        if type(a) == "table" and a.item == item and (typ == nil or a.Type == typ)
            and (dest == nil or a.destContainer == nil or a.destContainer == dest) then return a end
    end
    return nil
end

-- ===================================================================== waits (by the clock)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        H.hold()
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
function H.settle(minMs, maxMs, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(maxMs / 3) + 900, function()
        H.hold()
        local now = getTimestampMs()
        st.t = st.t or now
        if now - st.t >= minMs then
            local okC, r = pcall(cond)
            if okC and r then st.ok = true; return true end
        end
        return now - st.t >= maxMs
    end, function() fn(st.ok == true) end)
end

-- ===================================================================== the windows
function H.charOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(S.pn) end); return o and true or false end
function H.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function H.both() return H.charOpen() and H.worldOpen() and RT.cw() ~= nil and RT.ww() ~= nil end
function H.none() return not H.charOpen() and not H.worldOpen() end
function H.win(k) if k == "c" then return RT.cw() end; return RT.ww() end
function H.content(k) local w = H.win(k); return w and w._mainContent end
-- the inventory key, through ZeD's own key handler (what the key reaches); the pair's toggle when it is unbound
function H.invKey()
    local k = nil
    pcall(function() k = getCore():getKey("Toggle Inventory") end)
    if k and k ~= 0 then
        local ok = pcall(ZeD_CharacterWindow._onKeyPressed, k)
        if ok then return "the inventory key" end
    end
    pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn)
    return "the pair's toggle"
end
-- both windows shut (the pair by the inventory key when both are up)
function H.shutAll()
    if H.charOpen() and H.worldOpen() then H.invKey(); return end
    if H.charOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
    if H.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
end
function H.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function H.gs(g)
    if not g then return "none" end
    return H.num(g.x) .. "," .. H.num(g.y) .. " " .. H.num(g.w) .. "x" .. H.num(g.h)
end
function H.sameGeo(a, b)
    if a == nil or b == nil then return a == nil and b == nil end
    return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1
end
function H.placeBack(w, g)
    if not (w and g) or H.sameGeo(H.geo(w), g) then return false end
    pcall(function()
        if math.abs(w:getWidth() - g.w) > 1 then
            w.minimumWidth = math.min(w.minimumWidth or g.w, g.w)
            w:setWidth(g.w)
        end
        if math.abs(w:getHeight() - g.h) > 1 then
            w.minimumHeight = math.min(w.minimumHeight or g.h, g.h)
            w:setHeight(g.h)
        end
        if w:getX() ~= g.x then w:setX(g.x) end
        if w:getY() ~= g.y then w:setY(g.y) end
    end)
    return true
end
-- the windows at rest: the same places and sizes for 300 ms
function H.settled()
    local cw = H.charOpen() and RT.cw() or nil
    local ww = H.worldOpen() and RT.ww() or nil
    local sig = H.gs(H.geo(cw)) .. " | " .. H.gs(H.geo(ww))
    local now = getTimestampMs()
    if sig ~= S.restSig then
        S.restSig, S.restAt = sig, now
        return false
    end
    return now - S.restAt >= 300
end
-- the windows held down while the run works in them: the roll-up timers in the future, a rolled window or side down
function H.hold()
    if not S.holdOn then return end
    local t = getTimestampMs() + 600000
    for _, k in ipairs({ "c", "w" }) do
        local w = H.win(k)
        if w then
            w._outSince = t
            if w.windowShaded then
                w._autoShaded = false
                pcall(function() w:setWindowShaded(false) end)
            end
            local CU = ZeD.Curtain
            if w._rolled and CU and CU.finishUnroll then pcall(CU.finishUnroll, w) end
        end
    end
end
function H.shutCard(k)
    local w = H.win(k)
    local card = w and w._itemCard
    if w and (w._drawerItem ~= nil or w._drawerMode == "item") and card and card.onBackClick then pcall(card.onBackClick) end
end
function H.listView(inv)
    local key = nil
    if inv then pcall(function() key = ZeD.InventoryRenderer.containerKey(inv, S.p) end) end
    if not key then return nil end
    if S.grid[key] == nil then
        local md = H.md()
        local v = md.ZeD_GridViews and md.ZeD_GridViews[key]
        if v == nil then S.grid[key] = "none" else S.grid[key] = v end
    end
    pcall(ZeD.InventoryRenderer.setGridKey, key, false, S.p)
    return key
end
function H.gridBack()
    local md = H.md()
    if not md.ZeD_GridViews then return end
    for key, v in pairs(S.grid) do
        if v == "none" then md.ZeD_GridViews[key] = nil else md.ZeD_GridViews[key] = v end
    end
end
function H.gridSame()
    local md = H.md()
    local g = md.ZeD_GridViews or {}
    for key, v in pairs(S.grid) do
        local want = v
        if v == "none" then want = nil end
        if g[key] ~= want then return false end
    end
    return true
end
function H.tab(k, id)
    local ok = false
    if k == "c" then ok = RT.charTab(id) else ok = RT.worldTab(id) end
    if ok then return true end
    if k == "c" then pcall(ZeD_CharacterWindow.openTab, S.pn, id) else pcall(ZeD_WorldWindow.openTab, S.pn, id) end
    return false
end
function H.tabOf(k) local w = H.win(k); return w and (w._activeTab or "loot") or nil end
function H.idxOf(w, inv)
    if inv == nil then return nil end
    for i, e in ipairs((w and w._containers) or {}) do if e.inventory == inv then return i end end
    return nil
end
-- the lists a window shows side by side now (inventories): its columns, and the one on show when it is shown
function H.shownSet(w)
    local out, seen = {}, {}
    if not w then return out end
    for _, j in ipairs(w._mcSelected or {}) do
        local e = w._containers and w._containers[j]
        if e and not seen[e.inventory] then seen[e.inventory] = true; out[#out + 1] = e.inventory end
    end
    if w._mainVisible then
        local j = w._viewedContainer or w._activeContainer
        local e = w._containers and w._containers[j]
        if e and not seen[e.inventory] then seen[e.inventory] = true; out[#out + 1] = e.inventory end
    end
    return out
end
function H.invName(inv)
    if inv == nil then return "none" end
    if S.ca and inv == S.ca.inv then return "crate A" end
    if S.cb and inv == S.cb.inv then return "crate B" end
    if inv == H.main() then return "his inventory" end
    if S.ring and S.ringInv and inv == S.ringInv then return "the key ring" end
    local t = nil
    pcall(function() t = inv:getType() end)
    return tostring(t or "?")
end
function H.setNames(set)
    local out = {}
    for _, inv in ipairs(set or {}) do out[#out + 1] = H.invName(inv) end
    return "[" .. table.concat(out, ", ") .. "]"
end
function H.closeCols()
    local cw, ww = RT.cw(), RT.ww()
    if cw and #(cw._mcSelected or {}) > 0 then pcall(ZeD_CharacterWindow.closeColumns, cw) end
    if ww and #(ww._mcSelected or {}) > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
end
-- the Character list on his own inventory (vk2_mouse.lua H.viewTo, main only)
function H.charMain()
    local w = RT.cw()
    if not w then return end
    w._viewedContainer = nil
    w._activeContainer = 1
    w._mainVisible = true
    local c = w._mainContent
    if c then
        c._inventory = H.main()
        c._selectedItems = {}
        c._lastClickedItem = nil
    end
end
function H.worldOn(inv)
    local ww = RT.ww()
    if not (ww and inv) then return end
    if #(ww._mcSelected or {}) > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
    local c = ww._containers and ww._containers[ww._activeContainer]
    if c and c.inventory == inv and ww._mainVisible and ww._mainContent and ww._mainContent._inventory == inv then return end
    pcall(ZeD_WorldWindow.selectContainer, inv, 60, S.pn)
end

-- ===================================================================== the lists: stacks, folds, rows
function H.setStack(k, ft, open)
    local c = H.content(k)
    if not c then return end
    c._expandedStacks = c._expandedStacks or {}
    local key = k .. "|" .. ft
    if S.stacks[key] == nil then S.stacks[key] = { k = k, ft = ft, was = c._expandedStacks[ft] or false } end
    if open then c._expandedStacks[ft] = true else c._expandedStacks[ft] = nil end
end
function H.stacksBack()
    for _, s in pairs(S.stacks) do
        local c = H.content(s.k)
        if c and c._expandedStacks then
            if s.was ~= false then c._expandedStacks[s.ft] = s.was else c._expandedStacks[s.ft] = nil end
        end
    end
end
function H.unfoldAll(k)
    local c = H.content(k)
    local cg = c and c._collapsedGroups
    if not cg then return end
    local folds = {}
    for g, v in pairs(cg) do if v then folds[#folds + 1] = g end end
    for _, g in ipairs(folds) do cg[g] = nil end
    if #folds > 0 then S.folds[#S.folds + 1] = { of = cg, list = folds } end
end
function H.foldsBack()
    for _, f in ipairs(S.folds) do
        for _, g in ipairs(f.list) do f.of[g] = true end
    end
    S.folds = {}
end
function H.rowZone(c, item)
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
-- a row whose thing passes pred (a closed stack's row is its first thing's)
function H.rowZoneBy(c, pred)
    for _, z in ipairs((c and c._hitZones) or {}) do
        if type(z.id) ~= "string" and z.id ~= nil and pred(z.id) then return z end
    end
    return nil
end
function H.zoneShown(c, z)
    if not (c and z) then return false end
    local vis = false
    pcall(function() vis = c:isReallyVisible() and c:getWidth() > 0 end)
    if not vis then return false end
    local rv = c._rowView
    local grid = c._gv ~= nil and c._gv.on == true
    if not grid and not (rv and rv.top and rv.bottom and z.y >= rv.top and z.y + z.h <= rv.bottom) then return false end
    local hit = nil
    pcall(function() hit = c:hitZoneAt(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end)
    return hit == z
end
-- (a condition, every frame: the row shown whole last frame, else the list one step further down; wraps at the end)
function H.seekBy(k, pred)
    local c = H.content(k)
    if not c then return false end
    local z = H.rowZoneBy(c, pred)
    if z and H.zoneShown(c, z) then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        local r = tonumber(sc.barSizeRatio) or 1
        local stepPos = 0.1
        if r > 0 and r < 1 then stepPos = math.max(0.01, math.min(0.1, 0.5 * r / (1 - r))) end
        local at = S.seek[k]
        if at == nil or at >= 1 then at = 0 else at = math.min(1, at + stepPos) end
        S.seek[k] = at
        pcall(function() sc:setScrollPos(at) end)
    end
    return false
end
function H.seekRow(k, item) return H.seekBy(k, function(x) return x == item end) end

-- ===================================================================== the pointer (the one thing faked)
function H.atPointer(gx, gy, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return gx end
    getMouseY = function() return gy end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, err
end
-- Ctrl held (or not) for fn's call: the global isCtrlKeyDown answers it
function H.withCtrl(down, fn)
    local o = isCtrlKeyDown
    isCtrlKeyDown = function() return down and true or false end
    local ok, err = pcall(fn)
    isCtrlKeyDown = o
    return ok, err
end
-- every ZeD list and container strip answers "the pointer is over me" only when it is target (nil: none)
function H.overOnly(target, fn)
    local saved = {}
    local yes = function() return true end
    local no = function() return false end
    for _, k in ipairs({ "c", "w" }) do
        local w = H.win(k)
        if w then
            for _, o in ipairs({ w._mainContent or false, w._containerStrip or false }) do
                if o then
                    saved[#saved + 1] = { o, rawget(o, "isMouseOver") }
                    if o == target then o.isMouseOver = yes else o.isMouseOver = no end
                end
            end
        end
    end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do saved[i][1].isMouseOver = saved[i][2] end
    return ok, err
end
function H.zIndex(el)
    local own = el and el.javaObject
    if not own then return nil end
    local i = 0
    for _, r in ipairs(RT.roots()) do
        i = i + 1
        if r.e == own then return i end
    end
    return nil
end
function H.inUI(el) return H.zIndex(el) ~= nil end
function H.hud() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
-- is the screen point under the other ZeD window or the belt, drawn over owner?
function H.covered(owner, gx, gy)
    local oi = H.zIndex(owner)
    if not oi then return false end
    for _, c in ipairs({ RT.cw() or false, RT.ww() or false, H.hud() or false }) do
        if c and c ~= owner then
            local ci = H.zIndex(c)
            local vis = false
            pcall(function() vis = c:isReallyVisible() end)
            if ci and ci > oi and vis then
                local x, y, w, h = c:getAbsoluteX(), c:getAbsoluteY(), c:getWidth(), c:getHeight()
                if c.shownHeight then pcall(function() h = c:shownHeight() end) end
                if gx >= x and gx < x + w and gy >= y and gy < y + h then return true, tostring(c._zedLabel or c.Type or "a window") end
            end
        end
    end
    return false
end
function H.ownerOf(c)
    if c ~= nil and c == H.content("c") then return RT.cw() end
    if c ~= nil and c == H.content("w") then return RT.ww() end
    return nil
end
-- a press (fn(lx, ly)) at the middle of zone z of element el, owned by window owner. ok, why, covered
function H.pressZone(el, z, owner, fn)
    if not (el and z) then return false, "no such zone drawn", false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ax, ay = el:getAbsoluteX() + x, el:getAbsoluteY() + y
    local cov, by = H.covered(owner, ax, ay)
    if cov then return false, "its middle is under the " .. tostring(by), true end
    local ok, err = H.atPointer(ax, ay, function() fn(x, y) end)
    if not ok then return false, "the press threw: " .. tostring(err), false end
    return true, "pressed at " .. H.num(ax) .. "," .. H.num(ay), false
end
-- a left click on a row (down and up at its middle); second: the second click of a double-click
function H.click(k, item, second)
    local c = H.content(k)
    local z = H.rowZone(c, item)
    if not (c and z) then return false, "no row", false end
    if not second then c._zedLastClick = nil end
    return H.pressZone(c, z, H.ownerOf(c), function(x, y) c:onMouseDown(x, y); c:onMouseUp(x, y) end)
end
-- a point inside element el (screen coordinates) that a real press could reach: not under the other window or the
-- belt; a 5 by 5 grid over its middle part, the middle first
function H.freePoint(el, owner)
    if not el then return nil end
    local vis = false
    pcall(function() vis = el:isReallyVisible() end)
    if not vis then return nil end
    local x0, y0, w, h = el:getAbsoluteX(), el:getAbsoluteY(), el:getWidth(), el:getHeight()
    local tries = { { 0.5, 0.5 } }
    for i = 1, 5 do for j = 1, 5 do tries[#tries + 1] = { 0.1 + 0.8 * (i - 0.5) / 5, 0.15 + 0.7 * (j - 0.5) / 5 } end end
    for _, t in ipairs(tries) do
        local gx, gy = math.floor(x0 + w * t[1]), math.floor(y0 + h * t[2])
        if not H.covered(owner, gx, gy) then return gx, gy end
    end
    return nil
end
-- the press of a drag (at the row's middle) and a 40 px move: the drag is live. d, ax, ay or nil, why, covered
function H.dragStart(src, item)
    local z = H.rowZone(src, item)
    if not (src and z) then return nil, "the row is not on screen", false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ax, ay = src:getAbsoluteX() + x, src:getAbsoluteY() + y
    local cov, by = H.covered(H.ownerOf(src), ax, ay)
    if cov then return nil, "the row's middle is under the " .. tostring(by), true end
    src._zedLastClick = nil
    local ok, err = H.atPointer(ax, ay, function() src:onMouseDown(x, y) end)
    if not ok then return nil, "the press threw: " .. tostring(err), false end
    local d = src._drag
    if not (d and d:isPending()) then return nil, "the press began no drag", false end
    ok, err = H.atPointer(ax + 40, ay + 40, function() src:onMouseMove(40, 40) end)
    if not (ok and d:isActive()) then
        pcall(function() d:cancel() end)
        pcall(function() src:setCapture(false) end)
        return nil, "the move did not start the drag" .. (ok and "" or (": " .. tostring(err))), false
    end
    return d, ax, ay
end
-- the release of a live drag from src with the pointer at (gx, gy), target the list that answers "over me"
function H.dragRelease(src, gx, gy, target)
    local lx, ly = gx - src:getAbsoluteX(), gy - src:getAbsoluteY()
    local okR, errR = true, nil
    H.atPointer(gx, gy, function()
        okR, errR = H.overOnly(target, function() src:onMouseUpOutside(lx, ly) end)
    end)
    return okR, errR
end
function H.cancelDrags()
    for _, k in ipairs({ "c", "w" }) do
        local c = H.content(k)
        pcall(function()
            local d = c and c._drag
            if d and (d:isActive() or d:isPending()) then d:cancel(); c:setCapture(false) end
        end)
    end
    pcall(function() ISMouseDrag.dragging = nil end)
end

-- ===================================================================== the right-click menu (rt_hud.lua's)
function H.ctx() local c = nil; pcall(function() c = getPlayerContextMenu(S.pn) end); return c end
function H.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function H.menuUp()
    local m = H.menu()
    local vis = false
    if m then pcall(function() vis = m:isReallyVisible() end) end
    if vis then return true end
    local c = H.ctx()
    local cv = false
    if c then pcall(function() cv = c:isAnyVisible() and not c:isEmpty() end) end
    return cv and true or false
end
function H.closeMenu()
    local m = H.menu()
    if m then pcall(function() m:close() end) end
    pcall(function() local c = H.ctx(); if c and c:isAnyVisible() then c:hideAndChildren() end end)
end
function H.hasOption(ctx, key)
    local o = nil
    if ctx then pcall(function() o = ctx:getOptionFromName(getText(key)) end) end
    return o ~= nil
end

-- ===================================================================== ZeD setup's options
function H.opt(id)
    local api = PZAPI and PZAPI.ModOptions
    local zo = (api and api.getOptions) and api:getOptions("ZeD_UI") or nil
    return zo and zo.dict and zo.dict[id] or nil
end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.inGroups(id)
    local G = ZeD and ZeD.MainMenu and ZeD.MainMenu.optionGroups
    for _, g in ipairs((G and G.ZED_GROUPS) or {}) do
        -- (Nov 23 2026: with the plug-in points, G.groupRows(g) is the group's rows with an add-on's spliced in)
        local rows = nil
        if type(g) == "table" then rows = (G.groupRows and G.groupRows(g)) or g[2] end
        for _, e in ipairs(rows or {}) do
            if type(e) == "table" and e[1] == id then return true end
        end
    end
    return false
end
-- an option set to v for a check (the value found kept once, put back by H.optBack; never saved)
function H.optSet(id, v)
    local o = H.opt(id)
    if not (o and v) then return end
    S.optWas = S.optWas or {}
    if S.optWas[id] == nil then S.optWas[id] = H.optVal(o) or false end
    if H.optVal(o) ~= v then pcall(function() o:setValue(v) end) end
end
function H.optBack()
    for id, v in pairs(S.optWas or {}) do
        local o = H.opt(id)
        if o and v and H.optVal(o) ~= v then pcall(function() o:setValue(v) end) end
    end
end

-- ===================================================================== the input mode ZeD reads (vx12_wheel.lua)
function H.lockFound()
    local key = nil
    local o = H.opt("inputModeLock")
    local keys = ZeD and ZeD.Settings and ZeD.Settings.inputLockKeys
    if o and o.getValue and keys then key = keys[o:getValue() or 1] end
    if key == nil and S.p then
        local md = H.md()
        local g = md and md.ZeD_Gamepad
        key = g and g.inputModeLock
    end
    return key or "auto"
end
function H.mode() return (S.Det and S.Det.getMode) and S.Det.getMode(S.pn) or nil end
function H.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    if mode then
        if S.lockWas == nil then S.lockWas = H.lockFound() end
        S.Det.setLockedMode(mode)
        S.locked = true
        return
    end
    if not S.locked then return end
    S.locked = false
    S.Det.setLockedMode(nil)
    if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
end
function H.modeBack()
    local held = S.locked
    H.lock(false)
    if not (held and S.lockWas == "auto" and S.was.mode ~= nil and S.Det and S.Det.setLockedMode) then return end
    local want = (S.was.mode == "gamepad") and "gamepad" or "kbm"
    if H.mode() == want then return end
    S.Det.setLockedMode(want)
    S.modeHeld = want
end
function H.modeFree()
    if not S.modeHeld then return end
    S.modeHeld = nil
    S.Det.setLockedMode(nil)
end

-- ===================================================================== the crates and the squares
function N.delta(dir)
    local dx, dy = 0, 0
    if dir == IsoDirections.NW or dir == IsoDirections.W or dir == IsoDirections.SW then dx = -1 end
    if dir == IsoDirections.NE or dir == IsoDirections.E or dir == IsoDirections.SE then dx = 1 end
    if dir == IsoDirections.NW or dir == IsoDirections.N or dir == IsoDirections.NE then dy = -1 end
    if dir == IsoDirections.SW or dir == IsoDirections.S or dir == IsoDirections.SE then dy = 1 end
    return dx, dy
end
function N.at(dx, dy)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end)
    return sq
end
-- a square beside him a crate can stand on and he can reach: loaded, free, nothing else on it
function N.sqOk(sq)
    local here = S.p:getCurrentSquare()
    if not (sq and here) then return false end
    local ok = false
    pcall(function()
        ok = sq:isFree(false) and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0
            and sq:getVehicleContainer() == nil and here:canReachTo(sq)
    end)
    return ok and true or false
end
function N.mkCrate(sq)
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
function N.rmCrate(c)
    if not (c and c.obj) then return end
    pcall(function()
        local sq = c.obj:getSquare() or c.sq
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(c.obj) end); sq:RemoveTileObject(c.obj) end
    end)
    c.obj = nil
    c.gone = true
end
function N.stands(c)
    local up = false
    pcall(function() up = c ~= nil and c.obj ~= nil and c.obj:getSquare() ~= nil and c.obj:getObjectIndex() >= 0 end)
    return up
end
-- the crate's object as lit for this player: highlighted, outlined
function N.lit(c)
    local hl, ol = nil, nil
    if c and c.obj then
        pcall(function() hl = c.obj:isHighlighted(S.pn) and true or false end)
        pcall(function() ol = c.obj:isOutlineHighlight(S.pn) and true or false end)
    end
    return hl, ol
end
function N.cleanup()
    if S.cleaned then return end
    S.cleaned = true
    if S.ca and S.k19.capWas ~= nil then pcall(function() S.ca.inv:setCapacity(S.k19.capWas) end) end
    for _, it in ipairs(S.made) do pcall(H.removeItem, it) end
    N.rmCrate(S.ca)
    N.rmCrate(S.cb)
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end
end

-- ===================================================================== the pause and ZeD's glass over the windows
-- the game's speed set as its speed keys set it (the speed controls, then the speed itself)
function P.speed(v)
    local sc = nil
    pcall(function() sc = UIManager.getSpeedControls() end)
    if sc then pcall(function() sc:SetCurrentGameSpeed(v) end) end
    if ZEDQA_SPEED then pcall(ZEDQA_SPEED, v) else pcall(setGameSpeed, v) end
end
function P.set(on)
    if on then
        S.paused = true
        P.speed(0)
        return
    end
    if not S.paused then return end
    S.paused = false
    P.speed(S.runSpeed or 1)
end
P.KEYS = { "_glass", "_glassList", "_wglass", "_wglassList" }
-- the glasses of ZeD_PausedLook lying visible over the screen point on window win (the last made first)
function P.over(win, gx, gy)
    local PL = ZeD.PausedLook
    local out = {}
    for i = #P.KEYS, 1, -1 do
        local g = PL and PL[P.KEYS[i]]
        local vis = false
        if g then pcall(function() vis = g.win == win and g:isReallyVisible() end) end
        if vis then
            local x, y = g:getAbsoluteX(), g:getAbsoluteY()
            if gx >= x and gx < x + g:getWidth() and gy >= y and gy < y + g:getHeight() then out[#out + 1] = { g = g, key = P.KEYS[i] } end
        end
    end
    return out
end
-- does a press (right: a right press) at the screen point land on a glass that takes it? The screen hands a press
-- to the element on top first: a glass that eats it (its handler answers true) or consumes mouse events keeps it.
function P.eats(win, gx, gy, right)
    for _, e in ipairs(P.over(win, gx, gy)) do
        local g = e.g
        local lx, ly = gx - g:getAbsoluteX(), gy - g:getAbsoluteY()
        local consume, took = false, false
        pcall(function() consume = g.javaObject:isConsumeMouseEvents() and true or false end)
        pcall(function()
            if right then took = g:onRightMouseDown(lx, ly) == true else took = g:onMouseDown(lx, ly) == true end
        end)
        if consume or took then return true, e.key .. (consume and " (consumes the mouse)" or " (eats the press)") end
    end
    return false, nil
end

-- ===================================================================== start: what was found
Q.step(3, function()
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then S.dead = true; Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    local ready = ZeD ~= nil and ZeD.Belt ~= nil and ZeD.Belt.getHUD ~= nil and ZeD.InventoryRenderer ~= nil and ZeD.MapsTab ~= nil
        and ZeD.PausedLook ~= nil and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil and ZeD_CharacterWindow._onKeyPressed ~= nil
        and ISTimedActionQueue ~= nil and S.Det ~= nil and S.Det.setLockedMode ~= nil and S.Focus ~= nil and S.Focus.claimFocus ~= nil
        and ISWorldMap ~= nil and ISEntityUI ~= nil and PZAPI ~= nil and IsoObject ~= nil
    if not Q.check(ready, "ZeD's windows, belt, lists, map, pause look, focus, the input lock and the game's map and build openers are loaded") then
        S.dead = true
        return
    end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vk3_win") end
    S.was.char, S.was.world = H.charOpen(), H.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = S.was.char and H.geo(cw) or nil, w = S.was.world and H.geo(ww) or nil }
    S.was.tab = { c = (S.was.char and cw) and (cw._activeTab or "loot") or nil, w = (S.was.world and ww) and (ww._activeTab or "loot") or nil }
    local md = H.md()
    S.was.ws = { had = md.ZeD_WinState ~= nil, v = H.copy(md.ZeD_WinState) }
    S.was.pins = { had = md.ZeD_WinPinned ~= nil, v = H.copy(md.ZeD_WinPinned) }
    S.was.k9 = { had = md.ZeD_WinPinnedK9 ~= nil, v = H.copy(md.ZeD_WinPinnedK9) }
    S.was.speed = getGameSpeed()
    S.runSpeed = (S.was.speed and S.was.speed > 0) and S.was.speed or 1
    if S.was.speed == 0 then P.speed(1) end
    S.was.hand = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
    pcall(function() S.was.health = S.p:getBodyDamage():getOverallBodyHealth() end)
    S.was.dir = S.p:getDir()
    S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.was.mode = H.mode()
    S.was.focus = S.Focus.getFocusedWindow and S.Focus.getFocusedWindow(S.pn) or nil
    S.was.ctxStyle = H.optVal(H.opt("contextStyle"))
    S.was.worn = H.optVal(H.opt("wornInList"))
    S.lockWas = H.lockFound()
    H.clearQueue()
    H.closeMenu()
    H.lock("kbm")
    H.shutAll()
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(ZeD.T and ZeD.T.scale)
        .. "; Character window open " .. tostring(S.was.char) .. " (" .. H.gs(S.was.geo.c) .. ", on " .. tostring(S.was.tab.c) .. "), World window open "
        .. tostring(S.was.world) .. " (" .. H.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w) .. "); game speed " .. H.num(S.was.speed)
        .. "; Input lock " .. tostring(S.lockWas) .. ", ZeD reads " .. tostring(S.was.mode) .. "; in his hands " .. H.nm(S.was.hand.p) .. " / "
        .. H.nm(S.was.hand.s) .. "; facing " .. tostring(S.was.dir) .. "; Context menu option " .. tostring(S.was.ctxStyle) .. ", Worn and held option "
        .. tostring(S.was.worn))
end)
H.wait(6000, function() return S.dead or H.none() end, function(ok)
    if S.dead then return end
    if not ok then
        S.dead = true
        Q.check(false, "both windows shut for the run (staging)", "Character " .. tostring(H.charOpen()) .. ", World " .. tostring(H.worldOpen()))
        return
    end
    -- the window state the first shut saved (the places and sizes found): the final reopen starts from it
    S.wsFirst = H.copy(H.md().ZeD_WinState)
    S.wsFirstHad = H.md().ZeD_WinState ~= nil
    S.ok = true
end)

-- ===================================================================== the crates and the things
Q.step(2, function()
    if not S.ok then return end
    local dir = S.p:getDir()
    local dx, dy = N.delta(dir)
    local faced = N.at(dx, dy)
    local want = nil
    if (dx ~= 0 or dy ~= 0) and N.sqOk(faced) then want = dir
    else
        for _, d in ipairs({ IsoDirections.N, IsoDirections.E, IsoDirections.S, IsoDirections.W }) do
            local ddx, ddy = N.delta(d)
            local sq = N.at(ddx, ddy)
            if not want and N.sqOk(sq) then want, faced = d, sq end
        end
    end
    local other = nil
    if want then
        for _, d in ipairs({ IsoDirections.N, IsoDirections.E, IsoDirections.S, IsoDirections.W, IsoDirections.NE, IsoDirections.SE,
                             IsoDirections.SW, IsoDirections.NW }) do
            local ddx, ddy = N.delta(d)
            local sq = N.at(ddx, ddy)
            if not other and sq ~= faced and N.sqOk(sq) then other = sq end
        end
    end
    if not (want and other) then
        S.noCrate = true
        Q.check(false, "two free squares beside him for the crates (staging)", "faced square free " .. tostring(want ~= nil) .. ", another " .. tostring(other ~= nil))
        return
    end
    if want ~= dir then pcall(function() S.p:faceDirection(want) end); S.turned = true end
    S.wantDir = want
    S.ca = N.mkCrate(faced)
    S.cb = N.mkCrate(other)
    if not (S.ca and S.cb) then
        S.noCrate = true
        Q.check(false, "two crates placed beside him (staging)", "crate A " .. tostring(S.ca ~= nil) .. ", crate B " .. tostring(S.cb ~= nil))
        return
    end
    S.pencil = H.addTo(S.cb.inv, "Base.Pencil")
    S.pen = H.addTo(S.cb.inv, "Base.Pen")
    S.eraser = H.addTo(S.cb.inv, "Base.Eraser")
    S.nails, S.nailSet = {}, {}
    for _ = 1, 6 do
        local n = H.addTo(S.cb.inv, "Base.Nails")
        if n then S.nails[#S.nails + 1] = n; S.nailSet[n] = true end
    end
    S.ring = H.give("Base.KeyRing")
    pcall(function() S.ringInv = S.ring and S.ring:getInventory() or nil end)
    S.sledge = H.give("Base.Sledgehammer")
    S.hammer = H.give("Base.Hammer")
    S.pencil2 = H.give("Base.Pencil")
    local made = S.pencil and S.pen and S.eraser and #S.nails == 6 and S.ring and S.ringInv and S.sledge and S.hammer and S.pencil2
    if not made then
        S.noCrate = true
        Q.check(false, "the run's things are made (staging)", "pencil " .. tostring(S.pencil ~= nil) .. ", pen " .. tostring(S.pen ~= nil)
            .. ", eraser " .. tostring(S.eraser ~= nil) .. ", nails " .. #S.nails .. ", key ring " .. tostring(S.ringInv ~= nil) .. ", sledgehammer "
            .. tostring(S.sledge ~= nil) .. ", hammer " .. tostring(S.hammer ~= nil) .. ", second pencil " .. tostring(S.pencil2 ~= nil))
        return
    end
    pcall(function() S.k19.capWas = S.ca.inv:getCapacity() end)
end)
H.wait(3000, function() return S.noCrate or not S.ok or S.p:getDir() == S.wantDir end, function(ok)
    if S.noCrate or not S.ok then return end
    if not ok then
        S.noCrate = true
        Q.check(false, "he faces crate A (staging)", "facing " .. tostring(S.p:getDir()) .. ", want " .. tostring(S.wantDir))
        return
    end
    Q.say("ok crates: crate A on the square he faces (" .. tostring(S.wantDir) .. (S.turned and ", turned to it" or "") .. "), crate B beside him; "
        .. "B holds a pencil, a pen, an eraser and 6 nails; given: a key ring, a sledgehammer, a hammer, a second pencil")
end)

-- ===================================================================== #9: the tab side starts pinned
Q.step(2, function()
    if not S.ok then return end
    local md = H.md()
    md.ZeD_WinPinned = nil
    md.ZeD_WinPinnedK9 = nil
    S.k9.how = H.invKey()
    S.k9.go = true
end)
H.wait(6000, function() return not S.k9.go or (H.both() and RT.cw()._halves ~= nil and RT.ww()._halves ~= nil and H.settled()) end, function(ok)
    local T = S.k9
    if not T.go then return end
    local cw, ww = RT.cw(), RT.ww()
    local function read(w)
        local h = w and w._halves
        if not h then return "no halves" , nil, nil end
        return nil, h.drawer and h.drawer.pinned, h.inv and h.inv.pinned
    end
    local e1, ct, ci = read(cw)
    local e2, wt, wi = read(ww)
    Q.check(ok and ct == true and ci == false and wt == true and wi == false,
        "#9: a new character's windows open with the tab side pinned and the inventory side free to roll (old: both sides start unpinned)",
        "opened by " .. tostring(T.how) .. " with no saved pins; both open " .. tostring(H.both()) .. "; Character: tab side pinned " .. tostring(ct)
        .. ", inventory side pinned " .. tostring(ci) .. (e1 and (" (" .. e1 .. ")") or "") .. "; World: tab side pinned " .. tostring(wt)
        .. ", inventory side pinned " .. tostring(wi) .. (e2 and (" (" .. e2 .. ")") or ""))
    H.shutAll()
end)
H.wait(5000, function() return not S.k9.go or H.none() end, function(ok)
    if not S.k9.go then return end
    -- the save's pin tables as found (the windows load them on their next open)
    local md = H.md()
    if S.was.pins.had then md.ZeD_WinPinned = H.copy(S.was.pins.v) else md.ZeD_WinPinned = nil end
    if S.was.k9.had then md.ZeD_WinPinnedK9 = H.copy(S.was.k9.v) else md.ZeD_WinPinnedK9 = nil end
    if not ok then Q.check(false, "#9: both windows shut again after the reading (staging)") end
end)

-- ===================================================================== #16: the belt's bag button
H.wait(3000, function()
    local hud = H.hud()
    return not S.ok or (H.none() and hud ~= nil and hud._drawn == true)
end, function(ok)
    local T = S.k16
    if not S.ok then return end
    local label = "#16: the bag button at the belt's left end opens both windows (old: no bag button on the belt)"
    local hud = H.hud()
    if not (ok and hud and hud._drawn) then Q.skip(label, "the belt is not drawn here (both windows shut " .. tostring(H.none()) .. ")"); return end
    local bag = nil
    for _, b in ipairs(hud._boxes or {}) do if b.kind == "bag" and not bag then bag = b end end
    if not bag then
        local kinds = {}
        for _, b in ipairs(hud._boxes or {}) do if #kinds < 8 then kinds[#kinds + 1] = tostring(b.kind) end end
        Q.check(false, label, "the belt's boxes, left to right: " .. table.concat(kinds, ", "))
        return
    end
    local lx, ly = bag.x + math.floor(bag.w / 2), bag.y + math.floor(bag.h / 2)
    local gx, gy = hud:getAbsoluteX() + lx, hud:getAbsoluteY() + ly
    T.okP, T.err = H.atPointer(gx, gy, function() hud:onMouseDown(lx, ly); hud:onMouseUp(lx, ly) end)
    -- (QA, Nov 22: the director's belt row) the bag button is the leftmost of the belt's own boxes: only the speed
    -- keys (with a watch on, 313d74d0e) may sit left of it
    T.first = true
    T.leftOf = {}
    for _, b in ipairs(hud._boxes or {}) do
        if b.x < bag.x and b.kind ~= "speed" then T.first = false; T.leftOf[#T.leftOf + 1] = tostring(b.kind) end
    end
    T.go = true
end)
H.wait(3000, function() return not S.k16.go or H.both() end, function(ok)
    local T = S.k16
    if not T.go then return end
    Q.check(ok and T.okP and T.first, "#16: the bag button at the belt's left end opens both windows (old: no bag button on the belt)",
        "pressed the bag box (the leftmost of the belt's own boxes, speed keys aside " .. tostring(T.first)
        .. ((#(T.leftOf or {}) > 0) and (", left of it: " .. table.concat(T.leftOf, ", ")) or "") .. "), the press ran " .. tostring(T.okP) .. (T.okP and "" or (": " .. tostring(T.err)))
        .. "; within 3 s both open " .. tostring(H.both()) .. " (Character " .. tostring(H.charOpen()) .. ", World " .. tostring(H.worldOpen()) .. ")")
    H.shutAll()
end)
H.wait(5000, function() return not S.ok or H.none() end, function(ok)
    if S.ok and not ok then
        Q.check(false, "both windows shut before the inventory key (staging)", "Character " .. tostring(H.charOpen()) .. ", World " .. tostring(H.worldOpen()))
        H.shutAll()
    end
end)

-- ===================================================================== #13a: the World window opens on the container he faces
Q.step(2, function()
    if not S.ok or S.noCrate then return end
    S.k13.how = H.invKey()
    S.k13.go = true
end)
H.wait(6000, function()
    local T = S.k13
    if not T.go then return true end
    local ww = RT.ww()
    return H.both() and ww._containers ~= nil and H.idxOf(ww, S.ca.inv) ~= nil and H.idxOf(ww, S.cb.inv) ~= nil and H.settled()
end, function(ok)
    local T = S.k13
    if not T.go then return end
    local ww = RT.ww()
    local label = "#13: the World window opens on the container he faces, shown alone (old: it opens on the Floor)"
    if not (ok and ww) then
        T.go = false
        Q.check(false, label, "both open " .. tostring(H.both()) .. ", the crates in its list: A " .. tostring(ww and H.idxOf(ww, S.ca.inv) ~= nil)
            .. ", B " .. tostring(ww and H.idxOf(ww, S.cb.inv) ~= nil))
        return
    end
    local act = ww._containers[ww._activeContainer]
    local listInv = ww._mainContent and ww._mainContent._inventory
    local alone = #(ww._mcSelected or {}) == 0 and ww._mainVisible == true
    Q.check(act ~= nil and act.inventory == S.ca.inv and alone, label,
        "opened by " .. tostring(T.how) .. " facing " .. tostring(S.p:getDir()) .. "; on show: " .. H.invName(act and act.inventory)
        .. (act and act.isFloor and " (the Floor)" or "") .. ", alone " .. tostring(alone) .. ", the list draws " .. H.invName(listInv))
    T.go = false
end)
-- the run's view: both on Loot, no columns, the lists as lists, his own inventory on the Character list
Q.step(2, function()
    if not S.ok or S.noCrate then return end
    if not H.both() then S.noWin = true; Q.check(false, "both windows open for the lists' checks (staging)"); return end
    S.holdOn = true
    H.hold()
    H.tab("c", "loot")
    H.tab("w", "loot")
    H.closeCols()
    H.listView(H.main())
    if S.ca then H.listView(S.ca.inv) end
    if S.cb then H.listView(S.cb.inv) end
    H.unfoldAll("c")
    H.unfoldAll("w")
    H.charMain()
    if S.ca and not S.noCrate then H.worldOn(S.ca.inv) end
end)
H.wait(3000, function() return S.noWin or (H.tabOf("c") == "loot" and H.tabOf("w") == "loot" and H.settled()) end, function() end)
Q.waitMs(400)

-- ===================================================================== #44 (first reading): crate A on show is lit
Q.step(1, function()
    if not S.ok or S.noCrate or S.noWin then return end
    local ww = RT.ww()
    local act = ww and ww._containers and ww._containers[ww._activeContainer]
    S.k44.r1 = { onA = act ~= nil and act.inventory == S.ca.inv and #(ww._mcSelected or {}) == 0 }
    S.k44.r1.aHl, S.k44.r1.aOl = N.lit(S.ca)
    S.k44.r1.bHl, S.k44.r1.bOl = N.lit(S.cb)
    local o = nil
    pcall(function() o = getCore():getOptionDoContainerOutline() and true or false end)
    S.k44.outline = o
end)

-- ===================================================================== #10a / #10b: the World window's strip
function H.stripZone(w, inv)
    local i = H.idxOf(w, inv)
    local strip = w and w._containerStrip
    for _, z in ipairs((strip and strip._hitZones) or {}) do if i and z.id == i then return z, strip end end
    return nil, strip
end
Q.step(1, function()
    local T = S.k10
    if not S.ok or S.noCrate or S.noWin then return end
    local ww = RT.ww()
    local z, strip = H.stripZone(ww, S.cb.inv)
    T.labelA = "#10: a plain click on a container's picture shows it alone (World window; old: it adds a column)"
    local okP, why, cov = H.pressZone(strip, z, ww, function(x, y)
        H.withCtrl(false, function() strip:onMouseDown(x, y) end)
    end)
    if cov then Q.skip(T.labelA, "crate B's picture: " .. tostring(why)); return end
    if not okP then Q.check(false, T.labelA, "crate B's picture not pressed: " .. tostring(why)); return end
    T.pressedB = true
end)
Q.step(3, function()
    local T = S.k10
    if not T.pressedB then return end
    local ww = RT.ww()
    local act = ww._containers[ww._activeContainer]
    local set = H.shownSet(ww)
    local listInv = ww._mainContent and ww._mainContent._inventory
    T.aloneB = act ~= nil and act.inventory == S.cb.inv and #(ww._mcSelected or {}) == 0 and #set == 1 and listInv == S.cb.inv
    Q.check(T.aloneB, T.labelA, "after the click: on show " .. H.invName(act and act.inventory) .. ", columns " .. #(ww._mcSelected or {})
        .. ", the lists drawn " .. H.setNames(set) .. ", the list draws " .. H.invName(listInv))
end)
-- #44: the light follows the container on show (crate B by the plain click above; when that click could not be made
-- here, by the window's own selectContainer, so #44 does not hang on #10's press)
Q.step(1, function()
    if not S.ok or S.noCrate or S.noWin then return end
    if not S.k10.aloneB then
        S.k44.how = "selectContainer"
        H.worldOn(S.cb.inv)
    else
        S.k44.how = "a plain click"
    end
end)
Q.waitMs(400)
Q.step(1, function()
    local T = S.k44
    if not S.ok or S.noCrate or S.noWin then return end
    local label = "#44: the container on show is lit in the world, outlined per the game's option, the other dark (old: nothing is lit)"
    local r1 = T.r1 or {}
    local ww = RT.ww()
    local act = ww and ww._containers and ww._containers[ww._activeContainer]
    local onB = act ~= nil and act.inventory == S.cb.inv and #(ww._mcSelected or {}) == 0
    local aHl, aOl = N.lit(S.ca)
    local bHl, bOl = N.lit(S.cb)
    local o = T.outline
    local firstOk = r1.onA == true and r1.aHl == true and r1.aOl == o and r1.bHl ~= true
    local secondOk = onB and bHl == true and bOl == o and aHl ~= true
    Q.check(firstOk and secondOk and o ~= nil, label,
        "the game's container outline option " .. tostring(o) .. "; crate A on show alone " .. tostring(r1.onA) .. ": A highlighted " .. tostring(r1.aHl)
        .. ", outlined " .. tostring(r1.aOl) .. ", B highlighted " .. tostring(r1.bHl) .. "; then crate B on show alone by " .. tostring(T.how) .. " ("
        .. tostring(onB) .. "): B highlighted " .. tostring(bHl) .. ", outlined " .. tostring(bOl) .. ", A highlighted " .. tostring(aHl))
end)
Q.step(1, function()
    local T = S.k10
    T.labelB = "#10: Ctrl-click on a container's picture adds it as a column beside the one on show (World window; old: three lists, the Floor too)"
    if not T.pressedB then
        if S.ok and not S.noCrate and not S.noWin then Q.skip(T.labelB, "the plain click before it could not be made here") end
        return
    end
    local ww = RT.ww()
    local z, strip = H.stripZone(ww, S.ca.inv)
    local okP, why, cov = H.pressZone(strip, z, ww, function(x, y)
        H.withCtrl(true, function() strip:onMouseDown(x, y) end)
    end)
    if cov then Q.skip(T.labelB, "crate A's picture: " .. tostring(why)); return end
    if not okP then Q.check(false, T.labelB, "crate A's picture not pressed: " .. tostring(why)); return end
    T.pressedA = true
end)
Q.step(3, function()
    local T = S.k10
    if not T.pressedA then return end
    local ww = RT.ww()
    local set = H.shownSet(ww)
    local hasA, hasB = false, false
    for _, inv in ipairs(set) do
        if inv == S.ca.inv then hasA = true end
        if inv == S.cb.inv then hasB = true end
    end
    local act = ww._containers[ww._activeContainer]
    Q.check(#set == 2 and hasA and hasB and act ~= nil and act.inventory == S.cb.inv, T.labelB,
        "after Ctrl-click on crate A: the lists drawn " .. H.setNames(set) .. ", columns " .. #(ww._mcSelected or {}) .. ", on show " .. H.invName(act and act.inventory))
end)
Q.step(2, function()
    if not S.ok or S.noWin then return end
    H.closeCols()
    if S.cb and not S.noCrate then H.worldOn(S.cb.inv) end
end)

-- ===================================================================== #10c / #10d: the Character window's bag strip
function H.charZone(w, id)
    local strip = w and w._containerStrip
    for _, z in ipairs((strip and strip._hitZones) or {}) do if z.id == id then return z, strip end end
    return nil, strip
end
H.wait(5000, function()
    if not S.ok or S.noCrate or S.noWin then return true end
    local cw = RT.cw()
    local i = H.idxOf(cw, S.ringInv)
    return i ~= nil and H.charZone(cw, "cnt:" .. tostring(i)) ~= nil and H.charZone(cw, "main_toggle") ~= nil
end, function(ok)
    local T = S.k10
    if not S.ok or S.noCrate or S.noWin then return end
    T.labelC = "#10: a plain click on a bag's picture in the Character window shows it alone (old: it adds a column beside his inventory)"
    local cw = RT.cw()
    local i = H.idxOf(cw, S.ringInv)
    if not ok then Q.check(false, T.labelC, "the key ring's picture is not on the Character window's strip (in its list " .. tostring(i ~= nil) .. ")"); return end
    T.ringIdx = i
    local z, strip = H.charZone(cw, "cnt:" .. tostring(i))
    local okP, why, cov = H.pressZone(strip, z, cw, function(x, y)
        H.withCtrl(false, function() strip:onMouseDown(x, y); strip:onMouseUp(x, y) end)
    end)
    if cov then Q.skip(T.labelC, "the key ring's picture: " .. tostring(why)); return end
    if not okP then Q.check(false, T.labelC, "the key ring's picture not pressed: " .. tostring(why)); return end
    T.pressedRing = true
end)
Q.step(3, function()
    local T = S.k10
    if not T.pressedRing then return end
    local cw = RT.cw()
    local listInv = cw._mainContent and cw._mainContent._inventory
    local set = H.shownSet(cw)
    local ok = #(cw._mcSelected or {}) == 0 and cw._viewedContainer == T.ringIdx and cw._mainVisible == false and listInv == S.ringInv
    Q.check(ok, T.labelC, "after the click: columns " .. #(cw._mcSelected or {}) .. ", the bag viewed " .. tostring(cw._viewedContainer) .. " (the key ring is "
        .. tostring(T.ringIdx) .. "), his inventory shown " .. tostring(cw._mainVisible) .. ", the list draws " .. H.invName(listInv) .. ", columns drawn " .. H.setNames(set))
    T.ringAlone = ok
end)
Q.step(1, function()
    local T = S.k10
    T.labelD = "#10: Ctrl-click on his inventory's picture adds it as a column beside the bag on show (Character window; old: it hides his inventory)"
    if not T.pressedRing then
        if S.ok and not S.noCrate and not S.noWin then Q.skip(T.labelD, "the plain click on the key ring before it could not be made here") end
        return
    end
    local cw = RT.cw()
    local z, strip = H.charZone(cw, "main_toggle")
    local okP, why, cov = H.pressZone(strip, z, cw, function(x, y)
        H.withCtrl(true, function() strip:onMouseDown(x, y); strip:onMouseUp(x, y) end)
    end)
    if cov then Q.skip(T.labelD, "his inventory's picture: " .. tostring(why)); return end
    if not okP then Q.check(false, T.labelD, "his inventory's picture not pressed: " .. tostring(why)); return end
    T.pressedMain = true
end)
Q.step(3, function()
    local T = S.k10
    if not T.pressedMain then return end
    local cw = RT.cw()
    local mc = cw._mcSelected or {}
    local ringCol = #mc == 1 and mc[1] == T.ringIdx
    Q.check(ringCol and cw._mainVisible == true, T.labelD,
        "after Ctrl-click: the columns " .. H.list(mc) .. " (the key ring is " .. tostring(T.ringIdx) .. "), his inventory shown " .. tostring(cw._mainVisible))
end)
Q.step(2, function()
    if not S.ok or S.noWin then return end
    H.closeCols()
    H.charMain()
end)

-- ===================================================================== #45: Pick all in the list's heading
H.wait(4000, function()
    if not S.ok or S.noCrate or S.noWin then return true end
    local c = H.content("w")
    if not (c and c._inventory == S.cb.inv and H.rowZone(c, S.pencil)) then return false end
    for _, z in ipairs(c._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 9) == "view:all:" then return true end
    end
    return false
end, function(ok)
    local T = S.k45
    if not S.ok or S.noCrate or S.noWin then return end
    local label = "#45: the Pick all button in the list's heading picks every row (old: no such button)"
    local c = H.content("w")
    local z = nil
    for _, hz in ipairs((c and c._hitZones) or {}) do
        if type(hz.id) == "string" and hz.id:sub(1, 9) == "view:all:" then z = hz end
    end
    if not z then
        Q.check(false, label, "crate B's list (on show " .. tostring(c and c._inventory == S.cb.inv) .. ", its rows drawn " .. tostring(c ~= nil and H.rowZone(c, S.pencil) ~= nil)
            .. ") has no view:all zone in its heading")
        return
    end
    c._selectedItems = {}
    local okP, why, cov = H.pressZone(c, z, RT.ww(), function(x, y) c:onMouseDown(x, y) end)
    if cov then Q.skip(label, "the button: " .. tostring(why)); return end
    if not okP then Q.check(false, label, "the button not pressed: " .. tostring(why)); return end
    T.go = true
end)
Q.step(2, function()
    local T = S.k45
    if not T.go then return end
    local c = H.content("w")
    local flat = c._flatItems or {}
    local sel = c._selectedItems or {}
    local miss = 0
    for _, it in ipairs(flat) do if not sel[it] then miss = miss + 1 end end
    Q.check(#flat >= 3 and miss == 0 and H.count(sel) >= #flat, "#45: the Pick all button in the list's heading picks every row (old: no such button)",
        "crate B's list: " .. #flat .. " rows, " .. H.count(sel) .. " picked, " .. miss .. " rows not picked")
    c._selectedItems = {}
    c._lastClickedItem = nil
    c._padMarks = nil
    H.shutCard("w")
end)

-- ===================================================================== #31: Grab one, half, all on a closed stack
Q.step(2, function()
    if not S.ok or S.noCrate or S.noWin then return end
    H.setStack("w", "Base.Nails", false)
    S.seek.w = nil
    H.closeMenu()
end)
H.wait(5000, function()
    if not S.ok or S.noCrate or S.noWin then return true end
    return H.seekBy("w", function(x) return S.nailSet[x] == true end)
end, function(ok)
    local T = S.k31
    if not S.ok or S.noCrate or S.noWin then return end
    T.label = "#31: a closed stack's right-click offers the game's Grab one, Grab half and Grab all (old: one Grab, which takes all)"
    local c = H.content("w")
    local z = H.rowZoneBy(c, function(x) return S.nailSet[x] == true end)
    if not (ok and z) then Q.check(false, T.label, "the nails' stack row is not on view in crate B's list (staging)"); return end
    local stk = c._stacks and c._stacks[z.id]
    T.stackN = stk and stk.count or 1
    local okP, why, cov = H.pressZone(c, z, RT.ww(), function(x, y) c:onRightMouseUp(x, y) end)
    if cov then Q.skip(T.label, "the stack's row: " .. tostring(why)); return end
    if not okP then Q.check(false, T.label, "no right-click on the row: " .. tostring(why)); return end
    local ctx = H.ctx()
    T.one, T.half, T.all = H.hasOption(ctx, "ContextMenu_Grab_one"), H.hasOption(ctx, "ContextMenu_Grab_half"), H.hasOption(ctx, "ContextMenu_Grab_all")
    T.grab = H.hasOption(ctx, "ContextMenu_Grab")
    Q.check(T.one and T.half and T.all, T.label, "the row is a closed stack of " .. tostring(T.stackN) .. " nails; its menu: Grab one " .. tostring(T.one)
        .. ", Grab half " .. tostring(T.half) .. ", Grab all " .. tostring(T.all) .. ", Grab " .. tostring(T.grab))
    T.go = true
end)
Q.step(4, function()
    H.closeMenu()
    local c = H.content("w")
    if c then c._selectedItems = {}; c._lastClickedItem = nil end
    H.shutCard("w")
end)

-- ===================================================================== #7a: the right-click word list by default
Q.step(2, function()
    local T = S.k7
    if not S.ok or S.noCrate or S.noWin then return end
    local o = H.opt("contextStyle")
    T.label = "#7: a new player's right-click opens the word list, and the icon strip is still a ZeD setup choice (old: the strip by default)"
    if not o then Q.check(false, T.label, "ZeD setup has no Context menu option"); return end
    T.def = o.zedDefault
    T.n = #(o.values or {})
    T.groups = H.inGroups("contextStyle")
    if T.def then H.optSet("contextStyle", T.def) end
    T.before = H.menu()
    S.seek.w = nil
    T.go = true
end)
H.wait(5000, function()
    local T = S.k7
    if not T.go then return true end
    return H.seekRow("w", S.pencil)
end, function(ok)
    local T = S.k7
    if not T.go then return end
    if not ok then T.go = false; Q.check(false, T.label, "the pencil's row is not on view in crate B's list (staging)"); return end
    local c = H.content("w")
    local okP, why, cov = H.pressZone(c, H.rowZone(c, S.pencil), RT.ww(), function(x, y) c:onRightMouseUp(x, y) end)
    if cov then T.go = false; Q.skip(T.label, "the pencil's row: " .. tostring(why)); return end
    if not okP then T.go = false; Q.check(false, T.label, "no right-click on the row: " .. tostring(why)); return end
end)
H.wait(2000, function()
    local T = S.k7
    if not T.go then return true end
    local m = H.menu()
    local vis = false
    if m and m ~= T.before then pcall(function() vis = m:isReallyVisible() end) end
    return vis
end, function(ok)
    local T = S.k7
    if not T.go then
        H.optBack()
        return
    end
    local m = H.menu()
    local ty = (ok and m) and tostring(m.Type) or "no ZeD menu"
    local o = H.opt("contextStyle")
    Q.check(ok and ty == "ZeD_ContextList" and T.n == 2 and T.groups, T.label,
        "ZeD setup's Context menu starts on item " .. tostring(T.def) .. " of " .. T.n .. " (" .. tostring(o and o.values and o.values[1]) .. " / "
        .. tostring(o and o.values and o.values[2]) .. "), in ZeD setup's groups " .. tostring(T.groups) .. "; set to it, a right-click on the pencil opened " .. ty)
    H.closeMenu()
    H.optBack()
    local c = H.content("w")
    if c then c._selectedItems = {}; c._lastClickedItem = nil end
    H.shutCard("w")
end)

-- ===================================================================== #7b: Loot all and Transfer all are word buttons
Q.step(2, function()
    if not S.ok or S.noCrate or S.noWin then return end
    H.charMain()
    H.worldOn(S.cb.inv)
    -- (nothing picked in either list: with rows picked the band's first button is Take or Move the picked ones)
    for _, k in ipairs({ "c", "w" }) do
        local c = H.content(k)
        if c then c._selectedItems = {}; c._lastClickedItem = nil; c._padMarks = nil end
        H.shutCard(k)
    end
end)
Q.waitMs(400)
Q.step(1, function()
    if not S.ok or S.noCrate or S.noWin then return end
    local function rectOf(k, key)
        local c = H.content(k)
        local b = c and c._cc and c._cc.bottom
        for _, r in ipairs((b and b.rects) or {}) do if r.key == key then return r end end
        return nil
    end
    local take, xfer = rectOf("w", "take"), rectOf("c", "xfer")
    -- (the band writes the game's words in sentence case in English, as they are in other languages: compared
    -- without case)
    local lootW, xferW = "?", "?"
    pcall(function() lootW, xferW = tostring(getText("IGUI_invpage_Loot_all")), tostring(getText("IGUI_invpage_Transfer_all")) end)
    local function said(r)
        if not r then return "not in the band" end
        return "icon " .. tostring(r.icon) .. ", words \"" .. tostring(r.label) .. "\", " .. H.num(r.w) .. " px wide"
    end
    local function word(r, w) return r ~= nil and tostring(r.label):lower() == w:lower() end
    -- (QA, Nov 22 2026, refit for branch listgrid 1916f88ab: "Transfer buttons, always in the footer. Selection
    -- buttons, always in the header." The World band's Take all is back, its first button; the single list's heading
    -- has no Take all (view:lootall:<key> is a Loot column's foot only). Strict: the band's Take all as a word button
    -- and first; no view:lootall: zone on the single list.)
    local headZ = nil
    local wc = H.content("w")
    for _, z in ipairs((wc and wc._hitZones) or {}) do
        if type(z.id) == "string" and z.id:sub(1, 13) == "view:lootall:" then headZ = z; break end
    end
    local wb = wc and wc._cc and wc._cc.bottom
    local firstKey = wb and wb.rects and wb.rects[1] and wb.rects[1].key or nil
    local bandOk = take ~= nil and take.icon == nil and word(take, lootW) and firstKey == "take"
    Q.check(xfer ~= nil and xfer.icon == nil and word(xfer, xferW) and bandOk and headZ == nil,
        "#7: Loot all and Transfer all are word buttons in the footer bands (Take all back in crate B's band, first; none in its heading; old: pictures only)",
        "crate B's band, Loot all: " .. said(take) .. ", the band's first button " .. tostring(firstKey) .. "; its heading's Loot all: "
        .. (headZ and tostring(headZ.id) or "none")
        .. "; his inventory's band, Transfer all: " .. said(xfer) .. " (the game's words: " .. lootW .. ", " .. xferW .. ")")
end)

-- ===================================================================== #19: No room on the drag chip
Q.step(2, function()
    if not S.ok or S.noCrate or S.noWin then return end
    H.worldOn(S.ca.inv)
    pcall(function() S.ca.inv:setCapacity(2) end)
    S.k19.capSet = true
    H.charMain()
    S.seek.c = nil
end)
H.wait(5000, function()
    if not S.ok or S.noCrate or S.noWin then return true end
    local wc = H.content("w")
    return wc ~= nil and wc._inventory == S.ca.inv and H.seekRow("c", S.sledge)
end, function(ok)
    local T = S.k19
    if not S.ok or S.noCrate or S.noWin then return end
    T.label = "#19: the drag chip turns the danger color and reads No room over a container that cannot take the drag (old: it shows the weight)"
    if not ok then Q.check(false, T.label, "the sledgehammer's row in his list, crate A on the World list (staging)"); return end
    local src, wc, ww = H.content("c"), H.content("w"), RT.ww()
    local gx, gy = H.freePoint(wc, ww)
    if not gx then Q.skip(T.label, "no point of crate A's list is uncovered on this screen"); return end
    local d, ax, ay = H.dragStart(src, S.sledge)
    if not d then
        if ay == true then Q.skip(T.label, "the drag's press: " .. tostring(ax)) else Q.check(false, T.label, "the drag did not start: " .. tostring(ax)) end
        return
    end
    -- the chip drawn into a recorder: its words and its border colours
    local function chipAt(px, py, target)
        local rec = { texts = {}, borders = {} }
        local fake = { _playerObj = S.p }
        function fake.getAbsoluteX() return 0 end
        function fake.getAbsoluteY() return 0 end
        function fake.drawRect() end
        function fake.drawTextureScaledAspect() end
        function fake.drawRectBorder(_, x, y, w, h, a, r, g, b) rec.borders[#rec.borders + 1] = { r = r, g = g, b = b } end
        function fake.drawText(_, s) rec.texts[#rec.texts + 1] = tostring(s) end
        rec.ok, rec.err = H.atPointer(px, py, function() H.overOnly(target, function() d:drawGhost(fake) end) end)
        return rec
    end
    T.over = chipAt(gx, gy, wc)
    T.home = chipAt(ax, ay, src)
    H.cancelDrags()
    pcall(function() S.ca.inv:setCapacity(T.capWas) end)
    T.capSet = false
    local word = ZeD.tr("UI_ZeD_Drag_NoRoom")
    local dz = ZeD.T and ZeD.T.danger
    local function has(rec, s) for _, t in ipairs(rec.texts) do if t == s then return true end end; return false end
    local function lastIsDanger(rec)
        local b = rec.borders[#rec.borders]
        return b ~= nil and dz ~= nil and math.abs(b.r - dz.r) < 0.01 and math.abs(b.g - dz.g) < 0.01 and math.abs(b.b - dz.b) < 0.01
    end
    local wordOk = type(word) == "string" and word ~= "" and word ~= "UI_ZeD_Drag_NoRoom"
    Q.check(wordOk and T.over.ok and T.home.ok and has(T.over, word) and lastIsDanger(T.over) and not has(T.home, word) and not lastIsDanger(T.home),
        T.label,
        "the sledgehammer (6.0) dragged over crate A (room 2): the chip read [" .. table.concat(T.over.texts, " | ") .. "], its border the danger color "
        .. tostring(lastIsDanger(T.over)) .. (T.over.ok and "" or (", drawing threw " .. tostring(T.over.err))) .. "; held over his own list: ["
        .. table.concat(T.home.texts, " | ") .. "], danger border " .. tostring(lastIsDanger(T.home)) .. "; the word: " .. tostring(word))
end)

-- ===================================================================== #11a / #11b: worn and held things in his list
Q.step(2, function()
    local T = S.k11
    if not S.ok or S.noCrate or S.noWin then return end
    local o = H.opt("wornInList")
    T.optHere = o ~= nil
    T.def = o and o.zedDefault or nil
    T.n = o and #(o.values or {}) or 0
    T.groups = H.inGroups("wornInList")
    if T.def then H.optSet("wornInList", T.def) end
    pcall(function() S.p:setPrimaryHandItem(S.hammer) end)
    T.inHand = S.p:getPrimaryHandItem() == S.hammer
    H.charMain()
    H.unfoldAll("c")
    S.seek.c = nil
    T.go = true
end)
H.wait(5000, function()
    local T = S.k11
    if not T.go then return true end
    local c = H.content("c")
    return c ~= nil and c._catOf ~= nil and c._catOf[S.hammer] == S.WORN and H.seekRow("c", S.hammer)
end, function(ok)
    local T = S.k11
    if not T.go then return end
    local c = H.content("c")
    local flat = (c and c._flatItems) or {}
    local catOf = (c and c._catOf) or {}
    local worn, lastWorn, firstOther = 0, 0, nil
    for i, it in ipairs(flat) do
        if catOf[it] == S.WORN then worn = worn + 1; lastWorn = i
        elseif firstOther == nil then firstOther = i end
    end
    local lead = worn > 0 and (firstOther == nil or lastWorn < firstOther)
    local wornN = 0
    pcall(function() wornN = S.p:getWornItems():size() end)
    T.rowOk = ok and catOf[S.hammer] == S.WORN and H.rowZone(c, S.hammer) ~= nil
    Q.check(T.optHere and T.n == 2 and T.def == 1 and T.groups and T.inHand and T.rowOk and lead,
        "#11: what he wears and holds is listed in its own group at the top of his inventory list by default, and ZeD setup has the choice (old: not listed, no choice)",
        "ZeD setup's Worn and held option here " .. tostring(T.optHere) .. ", " .. T.n .. " items, starts on " .. tostring(T.def) .. ", in ZeD setup's groups "
        .. tostring(T.groups) .. "; the hammer in his hand " .. tostring(T.inHand) .. ", its row drawn in the group " .. tostring(catOf[S.hammer]) .. " ("
        .. tostring(T.rowOk) .. "); " .. worn .. " worn or held rows (he wears " .. wornN .. " things), the last at row " .. lastWorn .. ", the first other row "
        .. tostring(firstOther))
end)
Q.step(2, function()
    local T = S.k11
    if not T.go then return end
    T.label = "#11: a double-click on a held thing's row in his list takes it off (old: no such row)"
    if not T.rowOk then Q.check(false, T.label, "the hammer's row is not in his list"); return end
    H.clearQueue()
    local ok1, why1, cov1 = H.click("c", S.hammer, false)
    if cov1 then Q.skip(T.label, "the hammer's row: " .. tostring(why1)); return end
    local ok2, why2 = false, "the first click failed"
    if ok1 then ok2, why2 = H.click("c", S.hammer, true) end
    local a = H.actionFor(S.hammer, "ISUnequipAction")
    T.q = H.queueText()
    H.clearQueue()
    Q.check(ok1 and ok2 and a ~= nil, T.label, "two clicks on the hammer's row (" .. tostring(why1) .. "; " .. tostring(why2) .. "): the queue held [" .. T.q
        .. "] (the game's ISUnequipAction for the hammer: " .. tostring(a ~= nil) .. "), cleared at once")
end)
Q.step(2, function()
    local T = S.k11
    if not T.go then return end
    H.clearQueue()
    pcall(H.handsBack)
    H.optBack()
    local c = H.content("c")
    if c then c._selectedItems = {}; c._lastClickedItem = nil; c._zedLastClick = nil end
    H.shutCard("c")
end)

-- ===================================================================== #41: paused, a move between bags under the veil
Q.step(2, function()
    if not S.ok or S.noCrate or S.noWin then return end
    H.worldOn(S.cb.inv)
    H.charMain()
    S.seek.c = nil
    S.k41.go = true
end)
H.wait(5000, function()
    local T = S.k41
    if not T.go then return true end
    local wc = H.content("w")
    return wc ~= nil and wc._inventory == S.cb.inv and H.rowZone(wc, S.pen) ~= nil and H.seekRow("c", S.pencil2)
end, function(ok)
    local T = S.k41
    if not T.go then return end
    T.label = "#41: paused, a drag of a thing to the other window's list is allowed under the veil and runs on play, while a right-click still opens nothing (old: the glass takes the press)"
    if not ok then T.go = false; Q.check(false, T.label, "the second pencil's row in his list, the pen's in crate B's (staging)"); return end
    H.clearQueue()
    P.set(true)
end)
H.wait(3000, function()
    local T = S.k41
    if not T.go then return true end
    local c = H.content("c")
    local z = H.rowZone(c, S.pencil2)
    if not (z and ZeD.PausedLook.on()) then return false end
    local ax, ay = c:getAbsoluteX() + z.x + math.floor(z.w / 2), c:getAbsoluteY() + z.y + math.floor(z.h / 2)
    return #P.over(RT.cw(), ax, ay) > 0
end, function(ok)
    local T = S.k41
    if not T.go then return end
    local c, wc = H.content("c"), H.content("w")
    local z = H.rowZone(c, S.pencil2)
    if not (ok and z) then
        T.go = false
        Q.check(false, T.label, "paused " .. tostring(ZeD.PausedLook.on()) .. ", a glass or veil over his list's row: " .. tostring(ok) .. " (staging)")
        P.set(false)
        return
    end
    local ax, ay = c:getAbsoluteX() + z.x + math.floor(z.w / 2), c:getAbsoluteY() + z.y + math.floor(z.h / 2)
    local over = {}
    for _, e in ipairs(P.over(RT.cw(), ax, ay)) do over[#over + 1] = e.key end
    T.over = table.concat(over, ", ")
    if H.covered(RT.cw(), ax, ay) then T.go = false; Q.skip(T.label, "the second pencil's row is under the other window or the belt"); P.set(false); return end
    local gx, gy = H.freePoint(wc, RT.ww())
    if not gx then T.go = false; Q.skip(T.label, "no point of crate B's list is uncovered on this screen"); P.set(false); return end
    T.eaten, T.by = P.eats(RT.cw(), ax, ay, false)
    if not T.eaten then
        local d, why = H.dragStart(c, S.pencil2)
        if d then
            T.okR, T.errR = H.dragRelease(c, gx, gy, wc)
            T.dragged = true
        else
            T.why = tostring(why)
        end
        H.cancelDrags()
    end
    T.act = H.actionFor(S.pencil2, nil, S.cb.inv)
    T.q = H.queueText()
    T.stillHis = H.where(S.pencil2) == H.main()
    -- a right-click on the pen's row in crate B, routed the same way
    local pz = H.rowZone(wc, S.pen)
    T.rmenu = nil
    if pz then
        local px, py = wc:getAbsoluteX() + pz.x + math.floor(pz.w / 2), wc:getAbsoluteY() + pz.y + math.floor(pz.h / 2)
        T.rEaten, T.rBy = P.eats(RT.ww(), px, py, true)
        H.closeMenu()
        T.menuBefore = H.menu()
        if not T.rEaten then
            H.atPointer(px, py, function() wc:onRightMouseUp(pz.x + math.floor(pz.w / 2), pz.y + math.floor(pz.h / 2)) end)
        end
        T.rTried = true
    end
end)
Q.step(4, function()
    local T = S.k41
    if not T.go then return end
    local m = H.menu()
    local newMenu = false
    if m and m ~= T.menuBefore then pcall(function() newMenu = m:isReallyVisible() end) end
    T.menuOpened = newMenu or H.menuUp()
    H.closeMenu()
    T.pausedAtRead = ZeD.PausedLook.on()
    P.set(false)
end)
H.wait(10000, function()
    local T = S.k41
    if not T.go then return true end
    return H.where(S.pencil2) == S.cb.inv
end, function(ok)
    local T = S.k41
    if not T.go then return end
    local arrived = H.where(S.pencil2) == S.cb.inv
    Q.check(not T.eaten and T.dragged == true and T.act ~= nil and T.stillHis and T.rTried == true and not T.menuOpened and arrived, T.label,
        "paused " .. tostring(T.pausedAtRead) .. "; over the row: [" .. tostring(T.over) .. "]; the press "
        .. (T.eaten and ("taken by " .. tostring(T.by)) or "reaches the list") .. "; dragged and let go over crate B's list " .. tostring(T.dragged)
        .. (T.why and (" (" .. T.why .. ")") or "") .. "; queued while paused: [" .. tostring(T.q) .. "] (the pencil's move to crate B: " .. tostring(T.act ~= nil)
        .. "), the pencil still his " .. tostring(T.stillHis) .. "; a right-click on the pen's row " .. (T.rEaten and ("taken by " .. tostring(T.rBy)) or "reached the list")
        .. ", a menu opened " .. tostring(T.menuOpened) .. "; playing again, the pencil in crate B within 10 s " .. tostring(arrived))
    H.clearQueue()
end)

-- ===================================================================== the crates away, both windows shut
Q.step(2, function()
    P.set(false)
    H.cancelDrags()
    H.closeMenu()
    H.clearQueue()
    if not S.ok then return end
    H.closeCols()
    local c = H.content("w")
    if c then c._selectedItems = {} end
    N.cleanup()
    H.shutAll()
end)
H.wait(5000, function() return not S.ok or H.none() end, function(ok)
    if S.ok and not ok then
        S.noKeys = true
        Q.check(false, "both windows shut before the key checks (staging)", "Character " .. tostring(H.charOpen()) .. ", World " .. tostring(H.worldOpen()))
    end
end)

-- ===================================================================== #25a: H twice
Q.step(2, function()
    local T = S.k25
    if not S.ok or S.noKeys then return end
    T.h = {}
    local ip = nil
    pcall(function() ip = getPlayerInfoPanel(S.pn) end)
    if not ip then T.h.why = "the game has no Character info panel to ask"; return end
    T.ip = ip
    T.healthWord = getText("IGUI_XP_Health")
    T.h.ok1 = pcall(function() ip:toggleView(T.healthWord) end)
    T.h.go = true
end)
H.wait(5000, function()
    local T = S.k25
    if not (T.h and T.h.go) then return true end
    local cw = RT.cw()
    return H.both() and cw._activeTab == "health" and cw._drawerOpen == true and cw._drawerMode == "tab" and H.settled()
end, function(ok)
    local T = S.k25
    local label = "#25: H again shuts the windows H opened (old: the second H only folds the tab)"
    if not (T.h and T.h.go) then
        if S.ok and not S.noKeys then Q.check(false, label, tostring(T.h and T.h.why)) end
        return
    end
    if not ok then
        T.h.go = false
        Q.check(false, label, "the first H did not open both on Health (Character " .. tostring(H.charOpen()) .. " on " .. tostring(H.tabOf("c")) .. ", World "
            .. tostring(H.worldOpen()) .. ") (staging)")
        H.shutAll()
        return
    end
    T.h.ok2 = pcall(function() T.ip:toggleView(T.healthWord) end)
end)
H.wait(1500, function()
    local T = S.k25
    if not (T.h and T.h.go) then return true end
    return H.none()
end, function(ok)
    local T = S.k25
    if not (T.h and T.h.go) then return end
    Q.check(ok and T.h.ok1 and T.h.ok2, "#25: H again shuts the windows H opened (old: the second H only folds the tab)",
        "the game's Health page asked for twice (ran " .. tostring(T.h.ok1) .. ", " .. tostring(T.h.ok2) .. "): after the first, both open on Health; within 1.5 s of the second: Character open "
        .. tostring(H.charOpen()) .. ", World open " .. tostring(H.worldOpen()))
    H.shutAll()
end)
H.wait(4000, function() return not S.ok or S.noKeys or H.none() end, function() end)

-- ===================================================================== #25b: B (Building) twice
Q.step(2, function()
    local T = S.k25
    if not S.ok or S.noKeys then return end
    T.b = {}
    if not H.none() then T.b.why = "a window stayed open from the step before"; return end
    T.b.ok1 = pcall(function() ISEntityUI.OpenBuildWindow(S.p, nil, "*") end)
    T.b.go = true
end)
H.wait(5000, function()
    local T = S.k25
    if not (T.b and T.b.go) then return true end
    local s = false
    pcall(function() s = ZeD_WorldWindow.isTabShowing("build", S.pn) end)
    return H.worldOpen() and s and H.settled()
end, function(ok)
    local T = S.k25
    local label = "#25: B (Building) again shuts the World window B opened (old: the second B only folds the tab)"
    if not (T.b and T.b.go) then
        if S.ok and not S.noKeys then Q.check(false, label, tostring(T.b and T.b.why) .. " (staging)") end
        return
    end
    if not ok then
        T.b.go = false
        Q.check(false, label, "the first B did not open the World window on Build (World open " .. tostring(H.worldOpen()) .. " on " .. tostring(H.tabOf("w")) .. ") (staging)")
        H.shutAll()
        return
    end
    T.b.ok2 = pcall(function() ISEntityUI.OpenBuildWindow(S.p, nil, "*") end)
end)
H.wait(1500, function()
    local T = S.k25
    if not (T.b and T.b.go) then return true end
    return not H.worldOpen()
end, function(ok)
    local T = S.k25
    if not (T.b and T.b.go) then return end
    Q.check(ok and T.b.ok1 and T.b.ok2, "#25: B (Building) again shuts the World window B opened (old: the second B only folds the tab)",
        "the game's build window asked for twice (ran " .. tostring(T.b.ok1) .. ", " .. tostring(T.b.ok2) .. "): after the first, the World window on Build; within 1.5 s of the second: World open "
        .. tostring(H.worldOpen()) .. " (on " .. tostring(H.worldOpen() and H.tabOf("w") or "-") .. ")")
    H.shutAll()
end)
H.wait(4000, function() return not S.ok or S.noKeys or H.none() end, function() end)

-- ===================================================================== #25c: M twice
function H.pop() local w = RT.ww(); return w and w._mapPopout end
function H.popUp()
    local pop = H.pop()
    if not pop then return false end
    local v = false
    pcall(function() v = pop:isReallyVisible() end)
    return v and pop._raiseOnce == nil and H.inUI(pop)
end
Q.step(2, function()
    local T = S.k25
    if not S.ok or S.noKeys then return end
    T.m = {}
    H.clearQueue()
    if not H.none() then T.m.why = "a window stayed open from the step before"; return end
    T.m.ok1 = pcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
    T.m.go = true
end)
H.wait(9000, function()
    local T = S.k25
    if not (T.m and T.m.go) then return true end
    return H.popUp()
end, function(ok)
    local T = S.k25
    local label = "#25: M again puts away the map and the World window M opened (old: the World window stays)"
    if not (T.m and T.m.go) then
        if S.ok and not S.noKeys then Q.check(false, label, tostring(T.m and T.m.why) .. " (staging)") end
        return
    end
    if not ok then
        T.m.go = false
        T.noMap = true
        Q.skip(label, "the map did not open within 9 s (too dark to read here, or no world map in this game); World open " .. tostring(H.worldOpen()))
        H.clearQueue()
        H.shutAll()
        return
    end
    T.m.ok2 = pcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
end)
H.wait(1500, function()
    local T = S.k25
    if not (T.m and T.m.go) then return true end
    return not H.worldOpen()
end, function(ok)
    local T = S.k25
    if not (T.m and T.m.go) then return end
    Q.check(ok and T.m.ok1 and T.m.ok2, "#25: M again puts away the map and the World window M opened (old: the World window stays)",
        "the game's map toggle twice (ran " .. tostring(T.m.ok1) .. ", " .. tostring(T.m.ok2) .. "): after the first, ZeD's map up with the World window; within 1.5 s of the second: the map up "
        .. tostring(H.pop() ~= nil) .. ", World open " .. tostring(H.worldOpen()))
    H.clearQueue()
    H.shutAll()
end)
H.wait(4000, function() return not S.ok or S.noKeys or H.none() end, function() end)

-- ===================================================================== #25d: the pad's B on the map
Q.step(2, function()
    local T = S.k25
    if not S.ok or S.noKeys or T.noMap then return end
    T.pb = {}
    H.clearQueue()
    if not H.none() then T.pb.why = "a window stayed open from the step before"; return end
    T.pb.ok1 = pcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
    T.pb.go = true
end)
H.wait(9000, function()
    local T = S.k25
    if not (T.pb and T.pb.go) then return true end
    return H.popUp()
end, function(ok)
    local T = S.k25
    local label = "#25: the pad's B on the map puts away the map and the World window it opened (old: B folds the map into a World window that stays)"
    if not (T.pb and T.pb.go) then
        if T.pb and T.pb.why then Q.check(false, label, T.pb.why .. " (staging)") end
        return
    end
    if not ok then T.pb.go = false; Q.skip(label, "the map did not open again within 9 s"); H.clearQueue(); H.shutAll(); return end
    local pop = H.pop()
    if pop and pop._focusFresh then pcall(pop._focusFresh, pop) end
    pcall(S.Focus.claimFocus, pop)
    S.tookFocus = true
end)
Q.step(3, function()
    local T = S.k25
    if not (T.pb and T.pb.go) then return end
    local label = "#25: the pad's B on the map puts away the map and the World window it opened (old: B folds the map into a World window that stays)"
    local pop = H.pop()
    if pop and pop._focusFresh then pcall(pop._focusFresh, pop) end
    local fw = S.Focus.getFocusedWindow(S.pn)
    local el = nil
    if pop and fw == pop then pcall(function() el = S.Focus.getFocusedElement(pop) end) end
    if not (el and el.onCancel) then
        T.pb.go = false
        Q.skip(label, "the pad does not stand on a stop of the map with a B answer here (the pad on the map " .. tostring(fw ~= nil and fw == pop)
            .. ", a stop " .. tostring(el ~= nil) .. ")")
        pcall(S.Focus.releaseFocus, S.pn)
        H.shutAll()
        return
    end
    T.pb.el = tostring(el.id)
    T.pb.okB = RT.padDown(Joypad.BButton, pop)
end)
H.wait(1500, function()
    local T = S.k25
    if not (T.pb and T.pb.go) then return true end
    return not H.worldOpen()
end, function(ok)
    local T = S.k25
    if not (T.pb and T.pb.go) then return end
    Q.check(ok and T.pb.okB, "#25: the pad's B on the map puts away the map and the World window it opened (old: B folds the map into a World window that stays)",
        "the map opened by the game's toggle, the pad on it (on " .. tostring(T.pb.el) .. "), B through FocusManager's dispatch (ran " .. tostring(T.pb.okB)
        .. "); within 1.5 s: the map up " .. tostring(H.pop() ~= nil) .. ", World open " .. tostring(H.worldOpen()))
    pcall(S.Focus.releaseFocus, S.pn)
    H.clearQueue()
    H.shutAll()
end)
H.wait(4000, function() return not S.ok or S.noKeys or H.none() end, function() end)

-- ===================================================================== #13b: seated, the glove box
Q.step(2, function()
    local T = S.k13
    if not S.ok or S.noKeys then return end
    T.label2 = "#13: seated, the World window opens on the glove box and lists no Floor (old: the empty Floor is on show)"
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_READY and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY and ZEDQA_CAR_KEEP) then
        Q.check(false, T.label2, "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first) (staging)")
        return
    end
    T.carGo = true
    ZEDQA_CAR_WAIT("Base.CarNormal", "vk3_win", function(v)
        S.car = v
        ZEDQA_CAR_KEEP[v] = true
        T.carReady = true
    end, function(why) T.carWhy = why or "no ready car" end, 6000)
end)
H.wait(45000, function()
    local T = S.k13
    return not T.carGo or T.carReady or T.carWhy ~= nil
end, function()
    local T = S.k13
    if not T.carGo then return end
    if not (S.car and T.carReady) then
        T.carGo = false
        Q.check(false, T.label2, "no car: " .. tostring(T.carWhy) .. " (staging)")
        return
    end
    local okC, okE, why = pcall(ZEDQA_CAR_ENTER, S.car, 0)
    if not (okC and okE == true) then
        T.carGo = false
        Q.check(false, T.label2, "not seated: " .. tostring(why or okE) .. " (staging)")
        return
    end
    T.how2 = H.invKey()
end)
H.wait(6000, function()
    local T = S.k13
    if not T.carGo then return true end
    local ww = RT.ww()
    return H.both() and ww._containers ~= nil and #ww._containers > 0 and H.settled()
end, function(ok)
    local T = S.k13
    if not T.carGo then return end
    local ww = RT.ww()
    local glove = nil
    pcall(function()
        local part = S.car:getPartById("GloveBox")
        glove = part and part:getItemContainer() or nil
    end)
    local floors, names = 0, {}
    for _, c in ipairs((ww and ww._containers) or {}) do
        if c.isFloor then floors = floors + 1 end
        if #names < 8 then names[#names + 1] = tostring(c.name) end
    end
    local act = ww and ww._containers and ww._containers[ww._activeContainer]
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    Q.check(ok and seated == S.car and glove ~= nil and act ~= nil and act.inventory == glove and floors == 0, T.label2,
        "seated " .. tostring(seated == S.car) .. ", opened by " .. tostring(T.how2) .. "; the list [" .. table.concat(names, ", ") .. "] (Floors " .. floors
        .. "); on show " .. tostring(act and act.name) .. (act and act.isFloor and " (the Floor)" or "") .. ", the glove box " .. tostring(act ~= nil and glove ~= nil and act.inventory == glove))
    H.shutAll()
end)
H.wait(5000, function() return not S.k13.carGo or H.none() end, function()
    local T = S.k13
    if not T.carGo then return end
    if S.car and not S.carAway then
        -- (once only: a second removal of the same car is a Java exception in the sweep)
        S.carAway = true
        if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[S.car] = nil end
        pcall(ZEDQA_CAR_AWAY, S.car, nil)
    end
end)
H.wait(3000, function()
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    return seated == nil
end, function() end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    P.set(false)
    pcall(H.cancelDrags)
    pcall(H.closeMenu)
    H.clearQueue()
    pcall(H.optBack)
    if S.tookFocus and S.was.focus == nil then pcall(S.Focus.releaseFocus, S.pn) end
    pcall(N.cleanup)
    pcall(RT.takeBack)
    for _, it in ipairs(S.made) do pcall(H.removeItem, it) end
    pcall(H.handsBack)
    pcall(H.stacksBack)
    pcall(H.foldsBack)
    pcall(H.gridBack)
    for _, k in ipairs({ "c", "w" }) do
        local c = H.content(k)
        if c then c._selectedItems = {}; c._lastClickedItem = nil; c._zedLastClick = nil; c._padMarks = nil end
        H.shutCard(k)
    end
    pcall(H.closeCols)
    -- the car (if a step threw before it went), him back where he stood, facing as found
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    if S.car and not S.carAway then
        S.carAway = true
        if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[S.car] = nil end
        if seated or N.carHere() then pcall(ZEDQA_CAR_AWAY, S.car, nil) end
    end
    if S.was.geo then H.shutAll() end
end)
function N.carHere()
    local here = false
    if not S.car then return false end
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do if it:next() == S.car then here = true end end
    end)
    return here
end
H.wait(5000, function()
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    return seated == nil and H.none()
end, function()
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    if seated == nil and S.was.pos then
        local dx, dy = S.p:getX() - S.was.pos.x, S.p:getY() - S.was.pos.y
        if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 or math.floor(S.p:getZ()) ~= math.floor(S.was.pos.z) then
            pcall(function()
                S.p:setX(S.was.pos.x); S.p:setY(S.was.pos.y); S.p:setZ(S.was.pos.z)
                S.p:setLastX(S.was.pos.x); S.p:setLastY(S.was.pos.y); S.p:setLastZ(S.was.pos.z)
            end)
        end
    end
    if S.was.dir and S.p:getDir() ~= S.was.dir then pcall(function() S.p:faceDirection(S.was.dir) end) end
    -- the save's window state from the first shut (the places and sizes found) and the pin tables as found: the
    -- windows found open come back from them
    local md = H.md()
    if S.wsFirstHad then md.ZeD_WinState = H.copy(S.wsFirst) elseif S.ok then md.ZeD_WinState = nil end
    if S.was.pins then
        if S.was.pins.had then md.ZeD_WinPinned = H.copy(S.was.pins.v) else md.ZeD_WinPinned = nil end
        if S.was.k9.had then md.ZeD_WinPinnedK9 = H.copy(S.was.k9.v) else md.ZeD_WinPinnedK9 = nil end
    end
    if not S.was.geo then return end
    if S.was.char and S.was.world then H.invKey()
    elseif S.was.char then pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif S.was.world then pcall(ZeD_WorldWindow.open, S.pn) end
end)
H.wait(5000, function()
    if not S.was.geo then return true end
    return H.charOpen() == S.was.char and H.worldOpen() == S.was.world and H.settled()
end, function()
    if not S.was.geo then return end
    if S.was.char then H.tab("c", S.was.tab.c or "loot") end
    if S.was.world then H.tab("w", S.was.tab.w or "loot") end
end)
H.wait(3000, function()
    if not S.was.geo then return true end
    return (not S.was.char or H.tabOf("c") == (S.was.tab.c or "loot")) and (not S.was.world or H.tabOf("w") == (S.was.tab.w or "loot")) and H.settled()
end, function()
    if not S.was.geo then return end
    local moved = {}
    if S.was.char and H.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and H.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
    H.modeBack()
end)
Q.waitMs(400)
Q.step(1, function()
    H.modeFree()
    local md = H.md()
    -- the save's window state as found when both were found shut (the run's shuts saved their own)
    if S.was.ws and not (S.was.char or S.was.world) then
        if S.was.ws.had then md.ZeD_WinState = H.copy(S.was.ws.v) else md.ZeD_WinState = nil end
    end
    -- the pin tables as found (a window's open loads and writes them)
    if S.was.pins then
        if S.was.pins.had then md.ZeD_WinPinned = H.copy(S.was.pins.v) else md.ZeD_WinPinned = nil end
        if S.was.k9.had then md.ZeD_WinPinnedK9 = H.copy(S.was.k9.v) else md.ZeD_WinPinnedK9 = nil end
    end
    if S.was.speed ~= nil and getGameSpeed() ~= S.was.speed then P.speed(S.was.speed) end
end)
Q.step(10, function()
    if not S.was.geo then return end
    -- the things, the crates, the car
    local left, said, total = {}, {}, 0
    for _, it in ipairs(S.made) do
        total = total + 1
        if H.where(it) ~= nil or H.onFloor(it) then
            left[#left + 1] = it
            if #said < 4 then said[#said + 1] = H.nm(it) .. (H.onFloor(it) and " on the ground" or " in a container") end
        end
    end
    local crates = N.stands(S.ca) or N.stands(S.cb)
    local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    local hw = S.was.hand or {}
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    local car = N.carHere()
    Q.check(#left == 0 and not crates and hp == hw.p and hs == hw.s and H.gridSame() and #H.queue() == 0 and seated == nil and not car,
        "put back: nothing the script gave or made is left, the crates and the car are gone, his hands hold what they held, the lists' grid choices as found, no action queued",
        #left .. " of " .. total .. " things left" .. ((#said > 0) and (": " .. table.concat(said, "; ")) or "") .. "; a crate standing " .. tostring(crates)
        .. "; hands " .. H.nm(hp) .. " / " .. H.nm(hs) .. " (found " .. H.nm(hw.p) .. " / " .. H.nm(hw.s) .. "); grid choices as found " .. tostring(H.gridSame())
        .. "; the queue [" .. H.queueText() .. "]; seated " .. tostring(seated ~= nil) .. ", the car still here " .. tostring(car))
    -- the body and where he stands
    local dead, health = true, -1
    pcall(function() dead = S.p:isDead() end)
    pcall(function() health = S.p:getBodyDamage():getOverallBodyHealth() end)
    local dx, dy = 0, 0
    if S.was.pos then dx, dy = math.abs(S.p:getX() - S.was.pos.x), math.abs(S.p:getY() - S.was.pos.y) end
    Q.check(not dead and health >= math.min(99, (S.was.health or 100) - 1) and dx < 0.6 and dy < 0.6,
        "put back: the character is alive and well, where he stood",
        "dead " .. tostring(dead) .. ", health " .. H.num(health) .. " (found " .. H.num(S.was.health) .. "); off where he stood by " .. H.num(dx) .. ", " .. H.num(dy)
        .. "; facing " .. tostring(S.p:getDir()) .. " (found " .. tostring(S.was.dir) .. ")")
    -- the options, the speed, the menus
    local cs, wo = H.optVal(H.opt("contextStyle")), H.optVal(H.opt("wornInList"))
    Q.check(cs == S.was.ctxStyle and wo == S.was.worn and getGameSpeed() == S.was.speed and not H.menuUp(),
        "put back: ZeD setup's Context menu and Worn and held as found (never saved), the game at the speed found, no menu open",
        "Context menu " .. tostring(cs) .. " (found " .. tostring(S.was.ctxStyle) .. "), Worn and held " .. tostring(wo) .. " (found " .. tostring(S.was.worn)
        .. "); game speed " .. H.num(getGameSpeed()) .. " (found " .. H.num(S.was.speed) .. "); a menu up " .. tostring(H.menuUp()))
    -- the input lock, the mode, the pad's focus
    if S.lockWas ~= nil and S.was.mode ~= nil then
        local now, mode = H.lockFound(), H.mode()
        local unknown = S.was.mode == "unknown" and mode == "kbm"
        local fw = S.Focus.getFocusedWindow and S.Focus.getFocusedWindow(S.pn) or nil
        Q.check(now == S.lockWas and (mode == S.was.mode or unknown) and S.modeHeld == nil and not S.locked and (S.was.focus ~= nil or fw == nil),
            "put back: the input lock as found, the mode ZeD reads, the pad's focus let go",
            "ZeD setup's Input lock " .. tostring(now) .. " (found " .. tostring(S.lockWas) .. "); ZeD reads " .. tostring(mode) .. " (found " .. tostring(S.was.mode) .. ")"
            .. "; the pad's focus on a window " .. tostring(fw ~= nil) .. " (found " .. tostring(S.was.focus ~= nil) .. ")")
    end
    -- the save's pin tables and window state
    local md = H.md()
    local pinsOk = (S.was.pins.had and H.same(md.ZeD_WinPinned, S.was.pins.v)) or (not S.was.pins.had and md.ZeD_WinPinned == nil)
    local k9Ok = (S.was.k9.had and H.same(md.ZeD_WinPinnedK9, S.was.k9.v)) or (not S.was.k9.had and md.ZeD_WinPinnedK9 == nil)
    Q.check(pinsOk and k9Ok, "put back: the save's window pin tables as found", "ZeD_WinPinned as found " .. tostring(pinsOk) .. ", ZeD_WinPinnedK9 as found " .. tostring(k9Ok))
    -- the windows
    local cw, ww = RT.cw(), RT.ww()
    local c, w = H.charOpen(), H.worldOpen()
    local gc = c and H.geo(cw) or nil
    local gw = w and H.geo(ww) or nil
    local tc = c and H.tabOf("c") or nil
    local tw = w and H.tabOf("w") or nil
    Q.check(c == S.was.char and w == S.was.world and H.sameGeo(gc, S.was.geo.c) and H.sameGeo(gw, S.was.geo.w) and tc == S.was.tab.c and tw == S.was.tab.w,
        "put back: the Character and World windows open or shut as found, where and as big as they were, on their tabs",
        "Character open " .. tostring(c) .. " " .. H.gs(gc) .. " on " .. tostring(tc) .. " (found " .. tostring(S.was.char) .. " " .. H.gs(S.was.geo.c)
        .. " on " .. tostring(S.was.tab.c) .. "); World open " .. tostring(w) .. " " .. H.gs(gw) .. " on " .. tostring(tw) .. " (found "
        .. tostring(S.was.world) .. " " .. H.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w) .. ")"
        .. (S.moved and ("; the reopen left the " .. S.moved .. " elsewhere: set back by its own setters") or ""))
end)
-- the windows let go: their roll-up timers count from now, as after any open
Q.step(1, function()
    S.holdOn = false
    local t = getTimestampMs()
    for _, k in ipairs({ "c", "w" }) do local w = H.win(k); if w then w._outSince = t end end
end)
Q.start()
