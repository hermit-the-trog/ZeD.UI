-- ZeDUI/tools/qa/zedqa_faiv.lua  (Nov 6 2026, QA; FAIV's three reports): each bug's own reproduction in the game, by state.
local setGameSpeed = ZEDQA_SPEED or setGameSpeed   -- (Nov 13 2026: the prelude's speed sets the time multiplier too; see zedqa_prelude.lua)
-- It steps on OnTickEvenPaused, so it keeps going while the game is paused. grep "ZEDQA fav". Each check prints PASS or FAIL.
--   FLASH  the game's loot page must never reach a draw. Its draws are counted on the instance, never the ISInventoryPage
--          class: vl.prerender, which the engine looks up on every draw, set back to nil after. A control shows the page
--          after ZeD's last look, so the count is known to count. Then a real click (ISObjectClickHandler, as
--          zedqa_loot_click does) with the window on another container first:
--            a  speed 1, windows open          0 draws, the World window lists the container
--            b  paused, windows open           0 draws, listed while still paused
--            c  paused, both windows closed    0 draws, the World window opens on it while still paused
--            d  paused, both rolled up         0 draws, rolled down on it while still paused
--   ROLL   a rolled window under an item drag, the mouse faked (getMouseX, getMouseY, isMouseButtonDown, as zedqa_equipdrag).
--          Held over its title bar it rolls down, each window and an Equip row's drag; it stays down while the item is held
--          and rolls up after the usual wait once it is let go; a held button with no item (moving a rolled window) and a
--          pinned window leave it rolled. Those drags are cancelled. Then a real release (the list's own onMouseUp) on the
--          rolled World window's title bar, at once and after it has rolled down: the item lands in the container it lists.
--          The same release with that container left behind: nothing lands (the game's transfer checks no reach of its own).
--   STALE  the list shown against the container selected, by the object. Both windows are pinned for all of it (see its first
--          step), and it ends by checking they stayed down:
--            1  columns: a container walks out of reach: every column's rows are the container it is headed
--            2  a view picked on another tab, back to Loot, then selections: the list is the selection
--            3  the Character window: the pad shows a bag, a click on main lists main (a school bag lent if none is worn)
--            4  the World strip's Floor button lists the floor and lights it from a crate selection: after a real world click
--               (ISObjectClickHandler, as FLASH), a pad tap, a view come back to Loot; with a column open it takes the crate's
--               place; a crate leaving reach too
--            5  unpinned and rolled: a selection brings the window down on the container, the first frame down is not stale
-- Needs a container near the QA home (two within 2 squares of each other for the whole of STALE 1 and for 2); a step it can not
-- do says SKIP. Windows, pins, speed, the bag and the character's place are put back.
local function say(s) print("ZEDQA fav " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("fav") end
local p = getPlayer()
local md = p:getModData()
local keepPins = nil   -- (every pin key, the halves' too: charInv, charTabs, worldInv, worldTabs)
if md.ZeD_WinPinned then keepPins = {}; for k, v in pairs(md.ZeD_WinPinned) do keepPins[k] = v end end
-- the pins put back on the open windows, each half from its own key (WindowHalves; an older single key pins both)
local function putPinsBack(t)
    t = t or {}
    for _, pair in ipairs({ { ZeD_CharacterWindow.getWindow(), "char" }, { ZeD_WorldWindow.getWindow(), "world" } }) do
        local win, k = pair[1], pair[2]
        if win and win._halves and ZeD.Halves then
            local i, d = t[k .. "Inv"], t[k .. "Tabs"]
            if i == nil and d == nil then i, d = t[k] == true, t[k] == true end
            ZeD.Halves.setPin(win, "inv", i == true); ZeD.Halves.setPin(win, "drawer", d == true)
        elseif win then win.pinned = t[k] == true end
    end
end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local function shown() local w = WW(); return w and w._mainContent and w._mainContent._inventory end
local function selected() local w = WW(); local c = w and w._containers and w._containers[w._activeContainer or 0]; return c and c.inventory end
local function closeAll()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggle(0) end
    if ZeD_WorldWindow.isOpen() then ZeD_WorldWindow.close() end
end
local function openBoth() if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end
local function setSpeed(n) UIManager.getSpeedControls():SetCurrentGameSpeed(n) end

-- containers on the character's floor, each with a free square beside it
local cands = {}
do
    local cell = getCell()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for r = 1, 40 do
        for dx = -r, r do for dy = -r, r do
            if math.abs(dx) == r or math.abs(dy) == r then
                local sq = cell:getGridSquare(px + dx, py + dy, pz)
                local objs = sq and sq:getObjects()
                for i = 0, (objs and objs:size() or 0) - 1 do
                    local o = objs:get(i)
                    if o:getContainer() and not instanceof(o, "IsoDeadBody") and #cands < 8 then
                        local adj = AdjacentFreeTileFinder.Find(sq, p)
                        if adj then cands[#cands + 1] = { obj = o, adj = adj, inv = o:getContainer(), x = sq:getX(), y = sq:getY(), z = sq:getZ() } end
                    end
                end
            end
        end end
        if #cands >= 8 then break end
    end
end
say("containers found " .. #cands)
if #cands == 0 then say("ERR no container near the character"); say("DONE"); return end
local function standAt(x, y) p:setX(x + 0.5); p:setY(y + 0.5); p:setLastX(x + 0.5); p:setLastY(y + 0.5) end
local function standBy(c) standAt(c.adj:getX(), c.adj:getY()) end
local function click(c) ISObjectClickHandler.onObjectLeftMouseButtonDown(c.obj, 0, 0); ISObjectClickHandler.onObjectLeftMouseButtonUp(c.obj, 0, 0) end
local homeX, homeY = math.floor(p:getX()), math.floor(p:getY())
local function chebyshev(x1, y1, x2, y2) return math.max(math.abs(x1 - x2), math.abs(y1 - y2)) end

-- a pair in reach of one free square, and a free square in reach of the second but not the first
local pairA, pairB, both, leave
for _, a in ipairs(cands) do
    for _, b in ipairs(cands) do
        if a ~= b and not pairA and a.inv ~= b.inv and chebyshev(a.x, a.y, b.x, b.y) <= 2 then
            local fa, fl
            local aSq, bSq = getCell():getGridSquare(a.x, a.y, a.z), getCell():getGridSquare(b.x, b.y, b.z)
            -- (the list's own test beside the distance: a wall between a square and a crate takes it off the list)
            local function reaches(sq, to) return sq == to or sq:canReachTo(to) end
            for dx = -4, 4 do for dy = -4, 4 do
                local x, y = b.x + dx, b.y + dy
                local sq = getCell():getGridSquare(x, y, b.z)
                if sq and sq:isFree(false) then
                    local da, db = chebyshev(x, y, a.x, a.y), chebyshev(x, y, b.x, b.y)
                    if da <= 1 and db <= 1 and reaches(sq, aSq) and reaches(sq, bSq) then fa = fa or { x = x, y = y } end
                    if db <= 1 and da >= 3 and reaches(sq, bSq) then fl = fl or { x = x, y = y } end
                end
            end end
            if fa and fl then pairA, pairB, both, leave = a, b, fa, fl end
        end
    end
end
say("a pair for the columns: " .. tostring(pairA ~= nil))

-- the steps: wait ms, then fn; time in ms, so it runs the same paused or not
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

-- ---------------------------------------------------------------------------
-- FLASH
-- ---------------------------------------------------------------------------
local vl = getPlayerLoot(0)
local draws = 0
local origPre = vl.prerender
local function counting() vl.prerender = function(self) draws = draws + 1; return origPre(self) end end
local function uncounting() vl.prerender = nil end

add(300, function() setSpeed(1); openBoth(); standBy(cands[1]); counting() end)
-- the control: shown after ZeD's last look (this handler was added after that one), so it does draw
add(800, function()
    local function late() Events.OnPreUIDraw.Remove(late); vl:setVisible(true) end
    Events.OnPreUIDraw.Add(late)
end)
add(600, function()
    check(draws >= 1, "control: the count sees a draw of the page (" .. draws .. ")")
    check(not vl:getIsVisible(), "control: the page is hidden again")
end)
local function other() ZeD_WorldWindow.selectContainer(ZeD_WorldWindow.getFloorContainer(), 60) end
local function clickCase(tag, paused, setup)
    add(400, function() setSpeed(1); setup() end)
    add(1500, function()
        draws = 0
        if paused then setSpeed(0) end
    end)
    add(400, function()
        say(tag .. ": paused " .. tostring(getGameSpeed() == 0) .. ", click")
        click(cands[1])
    end)
    add(1500, function()
        check(draws == 0, tag .. ": the game's page drew " .. draws .. " times")
        check(not vl:getIsVisible(), tag .. ": the game's page is hidden")
        check(ZeD_WorldWindow.isOpen() and shown() == cands[1].inv, tag .. ": the World window lists the container"
            .. (paused and " while paused" or "") .. " (open " .. tostring(ZeD_WorldWindow.isOpen()) .. ", listed " .. tostring(shown() == cands[1].inv) .. ")")
        local w = WW()
        check(w ~= nil and w.windowShaded ~= true, tag .. ": the window is down")
        setSpeed(1)
    end)
end
clickCase("a speed 1, windows open", false, function() openBoth(); other() end)
clickCase("b paused, windows open", true, function() openBoth(); other() end)
clickCase("c paused, both closed", true, closeAll)
clickCase("d paused, both rolled up", true, function()
    openBoth()
    other()
    local c, w = CW(), WW()
    c:setPinned(false); w:setPinned(false)
    c._autoShaded = true; c:setWindowShaded(true)
    w._autoShaded = true; w:setWindowShaded(true)
end)
add(300, function() uncounting(); openBoth(); say("flash done") end)

-- ---------------------------------------------------------------------------
-- ROLL
-- ---------------------------------------------------------------------------
local realMX, realMY, realMB = getMouseX, getMouseY, isMouseButtonDown
local fx, fy, held = 0, 0, false
local function arm()
    getMouseX = function() return fx end
    getMouseY = function() return fy end
    isMouseButtonDown = function(b) if b == 0 then return held end return realMB(b) end
end
local function disarm() getMouseX, getMouseY, isMouseButtonDown = realMX, realMY, realMB; held = false end
local function onTitle(win) fx = win:getAbsoluteX() + win:getWidth() / 2; fy = win:getAbsoluteY() + win:titleBarHeight() / 2 end
local function away() fx, fy = getCore():getScreenWidth() - 10, getCore():getScreenHeight() - 10 end
local function anItem() local it = p:getInventory():getItems(); return it:size() > 0 and it:get(0) or nil end
local function roll(win) win:setPinned(false); win._autoShaded = true; win:setWindowShaded(true) end
-- target rolled, the drag dragOf() gives, the pointer on target's title bar
local function dragCase(tag, target, dragOf)
    local d
    add(300, function()
        local c, w = CW(), WW()
        c:setPinned(false); w:setPinned(false)
        c:setWindowShaded(false); w:setWindowShaded(false)
        arm(); away(); roll(target())
        d = dragOf()
        local item = anItem()
        if not (d and item) then say("SKIP " .. tag .. ": no drag or no item"); d = nil; return end
        held = true
        d:beginPending({ item }, item, 0, 0)
        d:activate()
        onTitle(target())
    end)
    add(600, function()
        if not d then return end
        check(target().windowShaded ~= true, tag .. ": held over the title bar it rolls down")
        away()
    end)
    add(3000, function()
        if not d then return end
        check(target().windowShaded ~= true, tag .. ": carried away it stays down while the item is held")
        d:cancel(); held = false
    end)
    add(3000, function()
        if not d then return end
        check(target().windowShaded == true, tag .. ": let go, it rolls up after the usual wait")
    end)
end
dragCase("World's item onto the rolled Character window", CW, function() return WW()._mainContent._drag end)
dragCase("Character's item onto the rolled World window", WW, function() return CW()._mainContent._drag end)
dragCase("an Equip row's drag onto the rolled World window", WW, function()
    local c = CW()
    c._equipDrag = c._equipDrag or ZeD.Molecules.DragState:new()
    return c._equipDrag
end)
add(300, function()
    local c, w = CW(), WW()
    c:setWindowShaded(false); w:setWindowShaded(false); roll(c)
    onTitle(c); held = true    -- the title bar pressed with no item: moving a rolled window
end)
add(600, function()
    check(CW().windowShaded == true, "a held button with no item leaves a rolled window rolled")
    held = false
end)
add(300, function()
    local c, w = CW(), WW()
    c:setWindowShaded(false); roll(c); c.pinned = true; away()
    local d, item = w._mainContent._drag, anItem()
    if not item then say("SKIP pinned: no item"); return end
    held = true
    d:beginPending({ item }, item, 0, 0); d:activate()
    onTitle(c)
end)
add(600, function()
    -- (Nov 8, dual pinning: a window rolled to its bar has no pinned half, so "pinned and rolled" no longer exists; an item held over any rolled bar brings it down, WindowHalves.update. Noted, not a check.)
    say("INFO pinned+rolled drag: window " .. (CW().windowShaded == true and "left rolled" or "brought down (dual pinning)"))
    local d = WW()._mainContent._drag
    if d:isActive() then d:cancel() end
    disarm()
    local c = CW()
    c.pinned = false
    c:setWindowShaded(false); WW():setWindowShaded(false)
    say("roll done")
end)

-- a real release on the World window's title bar: the Character list's own onMouseUp, the pointer faked
local function aLoose()
    local its = p:getInventory():getItems()
    for n = 0, its:size() - 1 do
        local it = its:get(n)
        if not p:isEquipped(it) and not p:isAttachedItem(it) and not it:isFavorite() and not instanceof(it, "InventoryContainer") then return it end
    end
    return nil
end
local function titleDrop(tag, settle, walkAway)
    local crate, item = cands[1].inv, nil
    local function release()
        local cc = CW()._mainContent
        cc:onMouseUp(0, 0)
        held = false
    end
    add(300, function()
        local c, w = CW(), WW()
        c:setPinned(false); w:setPinned(false)
        c:setWindowShaded(false); w:setWindowShaded(false)
        if c._activeTab ~= "loot" then ZeD_CharacterWindow.openTab(0, "loot") end
        standBy(cands[1])
    end)
    add(2000, function() ZeD_WorldWindow.selectContainer(crate, 60) end)
    add(800, function()
        local c, w = CW(), WW()
        item = aLoose()
        if not (item and shown() == crate and crate:isItemAllowed(item) and crate:hasRoomFor(p, item)) then
            say("SKIP " .. tag .. ": no loose item, or the container does not take it")
            item = nil
            return
        end
        if walkAway then standAt(cands[1].x + 8, cands[1].y + 8) end
        arm(); away(); roll(w); held = true
        local cc = c._mainContent
        cc._dragSourceInv = p:getInventory()
        cc._drag:beginPending({ item }, item, 0, 0)
        cc._drag:activate()
        onTitle(w)
        if not settle then
            check(w.windowShaded == true, tag .. ": released while it is still rolled")
            release()
        end
    end)
    add(600, function()
        if not item or not settle then return end
        check(WW().windowShaded ~= true, tag .. ": rolled down under the pointer")
        release()
    end)
    add(3500, function()
        disarm()
        if not item then return end
        if walkAway then
            check(item:getContainer() == p:getInventory(), tag .. ": a container left behind took nothing")
            standBy(cands[1])
            return
        end
        check(item:getContainer() == crate, tag .. ": the item is in the container the window lists")
        ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(p, item, crate, p:getInventory()))
    end)
    add(3000, function()
        if item and not walkAway then check(item:getContainer() == p:getInventory(), tag .. ": the item came back") end
        WW():setWindowShaded(false)
    end)
end
titleDrop("title bar, at once", false)
titleDrop("title bar, rolled down", true)
titleDrop("title bar, left behind", false, true)

-- ---------------------------------------------------------------------------
-- STALE
-- ---------------------------------------------------------------------------
local function colsAgree(w)
    local c = w._mainContent
    local st, sel = c._colStates, c._selectedContainers
    if not (st and sel) then return false, "no columns" end
    if #st ~= #sel then return false, #st .. " states, " .. #sel .. " selected" end
    for n = 1, #st do
        local cnt = w._containers[sel[n]]
        if not cnt or st[n].inventory ~= cnt.inventory or st[n].containerIdx ~= sel[n] then return false, "column " .. n end
    end
    return true, #st .. " columns"
end
local function inList(w, inv) for _, c in ipairs(w._containers or {}) do if c.inventory == inv then return true end end return false end

-- Both windows pinned and down for all of STALE. FLASH d, ROLL and the title bar drops leave them unpinned, and an unpinned window
-- with the pointer away rolls up after 2 s (ZeD_Window:_autoCollapse). A rolled window draws no strip and no list, so its
-- container list, its view and its columns stand still and every check here reads a list as old as the roll-up. The first run
-- (Nov 6 2026, qa/regression/2026-11-06_faiv.md) failed eight lines and skipped 4e that way, and passed 1b's last line on a stale
-- list; openTab rolls a window down, which is why the first half of 2 and all of 4c passed in that run.
add(300, function()
    local c, w = CW(), WW()
    c:setPinned(true); w:setPinned(true)
    c:setWindowShaded(false); w:setWindowShaded(false)
end)

-- 1a: columns A | B | floor, A walks out of reach, B stays
add(300, function()
    if not pairA then say("SKIP stale 1a: no two containers side by side"); return end
    if WW()._activeTab ~= "loot" then ZeD_WorldWindow.openTab(0, "loot") end
    other()
    standAt(both.x, both.y)
end)
add(2000, function()
    if not pairA then return end
    local w = WW()
    say("1a in the list: A " .. tostring(inList(w, pairA.inv)) .. ", B " .. tostring(inList(w, pairB.inv)))
    ZeD_WorldWindow.toggleColumn(pairA.inv)
    ZeD_WorldWindow.toggleColumn(pairB.inv)
end)
add(800, function()
    if not pairA then return end
    local ok, d = colsAgree(WW())
    check(ok, "1a columns before the walk agree (" .. tostring(d) .. ")")
    standAt(leave.x, leave.y)
end)
add(2500, function()
    if not pairA then return end
    local w = WW()
    check(not inList(w, pairA.inv), "1a A left the list")
    local ok, d = colsAgree(w)
    check(ok, "1a every column's rows are the container it is headed (" .. tostring(d) .. ")")
    local c = w._mainContent
    local rowsA = false
    for _, cs in ipairs(c._colStates or {}) do if cs.inventory == pairA.inv then rowsA = true end end
    check(not rowsA, "1a no column lists the container out of reach")
    other()
end)
-- 1b: a single column's container walks away: the columns end
local col1b = false
add(800, function()
    standBy(cands[1])
end)
add(2000, function()
    other()
    ZeD_WorldWindow.toggleColumn(cands[1].inv)
end)
add(800, function()
    col1b = WW()._mainContent._colStates ~= nil and #WW()._mcSelected == 1
    check(col1b, "1b one container and the floor in columns")
    standAt(cands[1].x + 6, cands[1].y + 6)
end)
add(2500, function()
    local w = WW()
    local gone = not inList(w, cands[1].inv)
    if not col1b then say("SKIP 1b: no column to lose")
    elseif gone then check(w._mainContent._colStates == nil and #w._mcSelected == 0, "1b the last column's container left reach: one list again")
    else say("SKIP 1b: the container stayed in reach") end
end)

-- 2: a view picked on another tab
local function stripClick(w, inv)
    local strip = w._containerStrip
    for n, c in ipairs(w._containers) do
        if c.inventory == inv then
            for _, z in ipairs(strip and strip._hitZones or {}) do
                if z.id == n then strip:onMouseDown(z.x + 2, z.y + 2); return true end
            end
        end
    end
    return false
end
local function needPair() if not pairA then say("SKIP stale 2: no two containers side by side"); return false end return true end
add(300, function()
    if needPair() then
        if #WW()._mcSelected > 0 then ZeD_WorldWindow.selectContainer(pairA.inv, 60) end
        standAt(both.x, both.y)
    end
end)
add(2000, function()
    if not pairA then return end
    ZeD_WorldWindow.selectContainer(pairA.inv, 60)
    ZeD_WorldWindow.openTab(0, "craft")
end)
add(1200, function()
    if not pairA then return end
    local w = WW()
    local hit = stripClick(w, pairB.inv)
    say("2 the strip click on another tab reached the strip: " .. tostring(hit) .. ", view " .. tostring(w._viewedContainer))
end)
add(800, function()
    if not pairA then return end
    check(shown() == pairB.inv, "2 the other tab's view lists the clicked container")
    ZeD_WorldWindow.openTab(0, "loot")
end)
add(800, function()
    if not pairA then return end
    local w = WW()
    check(shown() == pairB.inv and w._viewedContainer == nil and selected() == pairB.inv, "2 back on Loot the list stays and the view is now the selection (view " .. tostring(w._viewedContainer) .. ")")
    ZeD_WorldWindow.selectContainer(pairA.inv, 60)
end)
add(800, function()
    if not pairA then return end
    check(shown() == pairA.inv and selected() == pairA.inv, "2 a selection after it lists what was selected")
    ZeD_WorldWindow.openTab(0, "craft")
end)
add(1200, function()
    if not pairA then return end
    stripClick(WW(), pairB.inv)
end)
add(800, function()
    if not pairA then return end
    -- the world click's way in, on the same container the view was picked over
    ZeD_WorldWindow.selectContainer(pairA.inv, 60)
end)
add(800, function()
    if not pairA then return end
    check(shown() == pairA.inv and WW()._viewedContainer == nil, "2 a selection on the other tab ends the view")
    stripClick(WW(), pairB.inv)
end)
add(800, function()
    if not pairA then return end
    local w = WW()
    say("2 view again " .. tostring(w._viewedContainer))
    -- any way the selection moves that does not know about the view: the object it was picked over decides
    w._activeContainer = #w._containers
end)
add(800, function()
    if not pairA then return end
    local w = WW()
    check(shown() == w._containers[#w._containers].inventory and w._viewedContainer == nil, "2 a selection moved any other way ends the view, by the object")
    ZeD_WorldWindow.openTab(0, "loot")
end)

-- 3: the Character window, the pad's bag, then main by the mouse
local bagIdx, lentBag
add(1200, function()
    local w = CW()
    if w._activeTab ~= "loot" then ZeD_CharacterWindow.openTab(0, "loot") end
    local has = false
    for _, cnt in ipairs(w._containers or {}) do if not cnt.isMain then has = true end end
    if not has and not p:getClothingItem_Back() then
        -- (the QA character wears none: a school bag lent, the list only takes a bag worn or in hand; taken back after the step)
        lentBag = p:getInventory():AddItem("Base.Bag_Schoolbag")
        if lentBag then p:setClothingItem_Back(lentBag) end
    end
end)
add(1500, function()
    local w = CW()
    for n, cnt in ipairs(w._containers or {}) do if not cnt.isMain then bagIdx = bagIdx or n end end
    if not bagIdx then say("SKIP stale 3: no bag worn"); return end
    w._activeContainer, w._viewedContainer, w._mainVisible = bagIdx, bagIdx, false   -- what the pad's tap sets
end)
add(600, function()
    if not bagIdx then return end
    local w = CW()
    check(w._mainContent._inventory == w._containers[bagIdx].inventory, "3 the bag lists")
    local strip = w._containerStrip
    local hit = false
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "main_toggle" then strip:onMouseDown(z.x + 2, z.y + 2); hit = true; break end
    end
    say("3 main's button reached: " .. tostring(hit))
end)
add(600, function()
    if bagIdx then
        local w = CW()
        check(w._mainVisible == true and w._viewedContainer == nil and w._activeContainer == 1 and w._mainContent._inventory == p:getInventory(), "3 a click on main lists main")
    end
    if lentBag then p:removeWornItem(lentBag, false); p:getInventory():Remove(lentBag); lentBag = nil end
end)
add(300, function()
    local w = WW()
    if w._focusRing then check(w._lastInvRowInv == w._mainContent._inventory, "the pad's row zone follows the list shown, by the object") end
end)

-- 4: the World strip's Floor button, from a crate selection, whichever way the crate got there
local function floorLit(w)
    local fi = #w._containers
    return shown() == w._containers[fi].inventory and w._activeContainer == fi and w._mainVisible == true and w._viewedContainer == nil
end
local function padTap(inv)
    local w = WW()
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == "worldContainerStrip" then
            for _, e in ipairs(z.elements or {}) do
                if e.inventory == inv and e.onActivate then e.onActivate(w, e); return true end
            end
        end
    end
    return false
end
local function backToLoot() if WW()._activeTab ~= "loot" then ZeD_WorldWindow.openTab(0, "loot") end end
local function floorPress(tag)
    add(800, function()
        check(shown() == cands[1].inv, tag .. ": the crate lists")
        local hit = stripClick(WW(), ZeD_WorldWindow.getFloorContainer())
        say(tag .. " the Floor button reached: " .. tostring(hit))
    end)
    add(800, function()
        check(floorLit(WW()), tag .. ": the Floor button lists the floor and lights it")
    end)
end
add(300, function() backToLoot(); other(); standBy(cands[1]) end)
add(2000, function() click(cands[1]) end)
floorPress("4a a world click")
add(300, function()
    if not padTap(cands[1].inv) then say("SKIP 4b: no strip stop, the state set by hand"); ZeD_WorldWindow.selectContainer(cands[1].inv, 60) end
end)
floorPress("4b a pad tap")
add(300, function() ZeD_WorldWindow.openTab(0, "craft") end)
add(1200, function() stripClick(WW(), cands[1].inv) end)
add(800, function() backToLoot() end)
floorPress("4c a view come back to Loot")
-- a crate picked, a column added, the floor: the column and the floor, no crate that was not asked for
add(300, function()
    if not pairA then say("SKIP 4d: no two containers side by side"); return end
    standAt(both.x, both.y)
end)
add(2000, function()
    if not pairA then return end
    ZeD_WorldWindow.selectContainer(pairA.inv, 60)
end)
add(800, function()
    if not pairA then return end
    ZeD_WorldWindow.toggleColumn(pairB.inv)
end)
add(800, function()
    if not pairA then return end
    stripClick(WW(), ZeD_WorldWindow.getFloorContainer())
end)
add(800, function()
    if not pairA then return end
    local w = WW()
    local cols = {}
    for _, cs in ipairs(w._mainContent._colStates or {}) do cols[cs.inventory] = true end
    check(w._mainVisible == true and w._activeContainer == #w._containers and cols[pairB.inv] == true
        and cols[ZeD_WorldWindow.getFloorContainer()] == true and cols[pairA.inv] == nil, "4d the column and the floor, not the crate picked before")
    ZeD_WorldWindow.selectContainer(pairA.inv, 60)
end)
-- the selected crate leaves reach: the floor it falls back to is listed and lit
add(800, function() standBy(cands[1]) end)
add(2000, function() ZeD_WorldWindow.selectContainer(cands[1].inv, 60) end)
add(800, function() standAt(cands[1].x + 8, cands[1].y + 8) end)
add(2500, function()
    local w = WW()
    if inList(w, cands[1].inv) then say("SKIP 4e: the container stayed in reach")
    else check(floorLit(w), "4e the selected crate out of reach: the floor lists, lit") end
    check(CW().windowShaded ~= true and WW().windowShaded ~= true, "the windows stayed down through STALE, so the lists above were live")
end)

-- 5: a rolled window, unpinned as a player's is by default. Its list stands still, so a selection has to bring it down and what it
-- missed must not outlast the roll-down.
add(300, function()
    roll(WW())
    standBy(cands[1])
end)
add(1000, function()
    say("5 rolled " .. tostring(WW().windowShaded) .. ", the crate in the list it stopped on: " .. tostring(inList(WW(), cands[1].inv)))
    ZeD_WorldWindow.selectContainer(cands[1].inv, 60)
end)
add(800, function()
    local w = WW()
    check(w.windowShaded ~= true and shown() == cands[1].inv, "5 a selection on a rolled window brings it down on the container (rolled " .. tostring(w.windowShaded) .. ")")
    roll(w)
    standAt(cands[1].x + 8, cands[1].y + 8)
end)
add(1000, function()
    local w = WW()
    say("5 rolled again " .. tostring(w.windowShaded) .. ", the crate in the list it stopped on: " .. tostring(inList(w, cands[1].inv)))
    w:setWindowShaded(false)
end)
add(120, function()
    local w = WW()
    check(not inList(w, cands[1].inv) and shown() ~= cands[1].inv, "5 the first frame down reads the list afresh: the crate left behind is gone")
    w:setPinned(true)
end)

add(500, function()
    disarm()
    uncounting()
    setSpeed(1)
    md.ZeD_WinPinned = keepPins or { char = true, world = true }
    openBoth()
    local c, w = CW(), WW()
    putPinsBack(md.ZeD_WinPinned)
    if c then c:setWindowShaded(false) end
    if w then w:setWindowShaded(false) end
    standAt(homeX, homeY)
    if ZEDQA_HOME then ZEDQA_HOME("fav") end
    -- (Nov 12 2026, the window rule) rolled, unpinned and moved windows back to the run's default layout
    if ZEDQA_LAYOUT_BACK then ZEDQA_LAYOUT_BACK(ZEDQA_LAYOUT_DEF, "fav") end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)

local ev = Events.OnTickEvenPaused
local function drive()
    local st = plan[i]
    if not st then ev.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
ev.Add(drive)
say("start")
