-- ZeDUI/tools/qa/bxr_win.lua  (Nov 21 2026, QA beast day; tag bxrw): the beast day report's pictures of the window
-- fixes (git ed813a48a, b0e9fc66b, 9053bdef9). Built on the hotfix report's picture kit (hfr_common.lua, G1, the story
-- stage). Manifest beast_report_win.txt. Pictures to Zomboid/Screenshots/bxr_<name>.png (beast_report_run.ps1 moves
-- them to Screenshots/beast_day_report/). Each section guards itself and says SHOT or SKIP for each picture.
--   B5-2_rolled_up_no_rod            the Character window rolled up to its title bar while its inventory side was
--                                    rolled under its tab: no tab ("curtain rod") left on screen
--   B6-17_a_side_hidden_bar_current  the Character window on Skills, its inventory side rolled away; a pinned canteen
--                                    was part emptied while the side was hidden: the title bar's pin and load moved
--   B6-17_b_side_down_same_numbers   the side down again with the canteen's card out: the same numbers
--   B5-4_reset_both_on_loot          after Reset both windows with the World window on Maps and the Character window
--                                    on Skills: both back in the spread, both on Loot (the Loot tab lit)
--   B7-1_quick_click_side_down       the World window on Craft; a click on a crate on the update its inventory side
--                                    starts to roll: the side is down, showing that crate's things
--   B5-1_crate_click_side_down       the same with the side fully rolled away under its tab before the click
--   B5-7_2x_side_by_side             UI scale 1x, both windows right of center, then 2x: side by side, not piled
--                                    (zoom 1.75 for this one only: the 2x pair reaches over the character's box at
--                                    zoom 1; the other pictures are at zoom 1, as the other beast day parts)
-- What it puts back: the UI scale, the zoom, both windows' places, pins and accents (ZEDQA_LAYOUT_BACK), the title bar
-- pins, the two crates, the canteen, the stack it opened, the tabs, the pair open or shut. grep "ZEDQA bxrw".
local S = HFR and HFR.init and HFR.init("bxrw")
if not S then return end
S.DIR = "bxr_"
local Q, St, Sc = S.Q, ZeD.Settings, ZeD.Scale
local Hv, Cu, Pins = ZeD.Halves, ZeD.Curtain, ZeD.Pins
S.ok, S.why = {}, {}

-- ===================================================================== helpers
-- a picture taken, and what is in it; a picture not taken, and why
function S.take(name, what, keepMenu)
    local n0 = Q.nOk
    S.shot(name, keepMenu)
    -- (Q.shot counts a failed screenshot call in Q.nErr and says ERR: then this picture is not there)
    if Q.nOk > n0 then Q.say("SHOT " .. name .. " | " .. tostring(what))
    else Q.say("SKIP " .. name .. " | the screenshot call failed (" .. tostring(what) .. ")") end
end
function S.skip(name, why)
    Q.nErr = Q.nErr + 1
    Q.say("SKIP " .. name .. " | " .. tostring(why))
end
function S.win(k) if k == "c" then return S.CW() end; return S.WW() end
function S.geo(w)
    if not w then return "none" end
    return string.format("%d,%d %dx%d", w:getX(), w:getY(), w:getWidth(), w:getHeight())
end
-- every roll timer of both windows held (WindowHalves reads win._outSince: a time in the future holds the pointer's
-- timers, so nothing rolls up or comes down by where the real pointer happens to rest); off: the timers run again
function S.holdBoth(off)
    for _, k in ipairs({ "c", "w" }) do
        local w = S.win(k)
        if w then w._outSince = (not off) and (getTimestampMs() + 600000) or nil end
    end
end
function S.pinsOf(win)
    local s = win and win._halves
    if s then return { inv = s.inv.pinned and true or false, drawer = s.drawer.pinned and true or false } end
    local on = win ~= nil and win.pinned == true
    return { inv = on, drawer = on }
end
function S.setPins(win, inv, drawer)
    if not win then return end
    if win._halves and Hv and Hv.setPin then
        pcall(Hv.setPin, win, "inv", inv)
        pcall(Hv.setPin, win, "drawer", drawer)
    else
        win.pinned = (inv and drawer) and true or false
    end
end
-- everything down again: the shade, the halves, the curtain; both halves pinned (as the run started)
function S.down(win)
    if not win then return end
    pcall(function() if win.windowShaded then win._autoShaded = false; win:setWindowShaded(false) end end)
    pcall(function()
        local s = win._halves
        if s then s.inv.rolled, s.inv.hand, s.inv.out, s.drawer.rolled = false, false, nil, false end
    end)
    pcall(function() if win._rolled then Cu.finishUnroll(win) end end)
    S.setPins(win, true, true)
end
function S.titleH(win)
    local h = nil
    pcall(function() h = ZeD.T.titleBarH end)
    if not h then pcall(function() h = win:titleBarHeight() end) end
    return h or 0
end
function S.canRoll(win)
    local can = false
    pcall(function() can = win ~= nil and win._halves ~= nil and win._activeTab ~= "loot" and win._curtain.canRoll() end)
    return can and true or false
end
-- the inventory side rolled as the pointer's leaving rolls it (its 2 second timer run out, not rolled by hand)
function S.rollSide(win)
    if not S.canRoll(win) then return false end
    S.setPins(win, false, true)
    local s = win._halves
    s.inv.rolled, s.inv.hand, s.inv.out = true, false, nil
    return true
end
-- the side rolled and its tab drawn up to the title bar, as the player sees it at rest
function S.rolledAway(win)
    local rod = win and win._rod
    if not (win and win._rolled == true and rod and rod._h and rod._target) then return false end
    return rod._target <= S.titleH(win) and rod._h <= rod._target
end
function S.rodWords(win)
    local rod = win and win._rod
    if not rod then return "no tab made" end
    return string.format("side rolled %s, its tab %d px tall going to %d px, showing %s", tostring(win._rolled),
        math.floor(rod._h or -1), math.floor(rod._target or -1), tostring(rod:isVisible()))
end
-- a press the way the engine delivers one: inside the element's own update, followed by its onResize
-- (bx_windows.lua X.via; el._qaPressDone is false until the update ran it)
function S.via(el, fn)
    local own = rawget(el, "update")
    el._qaPressDone = false
    el.update = function(self)
        self.update = own
        self:update()
        local ok, e = pcall(fn, self)
        if not ok then Q.say("note: a press failed: " .. tostring(e)) end
        pcall(function() self:onResize() end)
        self._qaPressDone = true
    end
end
-- a double-click on a window's title bar
function S.dbl(w)
    local px, py = math.floor(w:getWidth() / 2), math.floor(w:titleBarHeight() / 2)
    w._lastTitleClick = nil
    w:onMouseDown(px, py); w:onMouseUp(px, py)
    w:onMouseDown(px, py); w:onMouseUp(px, py)
end
-- queue: window k ("c" Character, "w" World) on tab id with its inventory side rolled away under its tab.
-- S.ok[key] is false, with S.why[key], when it did not get there.
function S.qRolled(k, id, key)
    Q.step(10, function()
        S.openPair(); S.holdBoth()
        local okTab = false
        if k == "c" then okTab = S.charTab(id) else okTab = S.worldTab(id) end
        S.ok[key] = okTab
        if not okTab then S.why[key] = "no " .. id .. " tab on the strip here" end
    end)
    Q.waitFor(5, 400, function() return not S.ok[key] or S.canRoll(S.win(k)) end, function(ok)
        if not S.ok[key] then return end
        if not ok then S.ok[key] = false; S.why[key] = "the inventory side cannot roll here (the " .. id .. " drawer did not open beside the list)"; return end
        S.rollSide(S.win(k))
    end)
    Q.waitFor(2, 600, function() S.holdBoth(); return not S.ok[key] or S.rolledAway(S.win(k)) end, function(ok)
        if S.ok[key] and not ok then S.ok[key] = false; S.why[key] = "the inventory side did not roll under its tab (" .. S.rodWords(S.win(k)) .. ")" end
    end)
end
-- the two windows' own accent colors (a layout reset sets both to "Same as Accent color": put back after each reset)
function S.accKeep()
    local c, w = S.CW(), S.WW()
    local a = { c = c and c._accentKey, w = w and w._accentKey, pc = ZeD._pendingCharAccent, pw = ZeD._pendingWorldAccent, opt = {} }
    pcall(function()
        local ws = S.p:getModData().ZeD_WinState
        a.sc, a.sw = ws and ws.char and ws.char.accentKey, ws and ws.world and ws.world.accentKey
        a.hasC, a.hasW = (ws and ws.char) ~= nil, (ws and ws.world) ~= nil
    end)
    for _, id in ipairs({ "charAccent", "worldAccent" }) do
        local o = S.opt(id)
        if o then pcall(function() a.opt[id] = o:getValue() end) end
    end
    S.acc0 = a
end
function S.accBack()
    local a = S.acc0
    if not a then return end
    for _, id in ipairs({ "charAccent", "worldAccent" }) do
        local o = S.opt(id)
        if o and a.opt[id] ~= nil then pcall(function() if o:getValue() ~= a.opt[id] then o:setValue(a.opt[id]) end end) end
    end
    local c, w = S.CW(), S.WW()
    if c then c._accentKey = a.c end
    if w then w._accentKey = a.w end
    ZeD._pendingCharAccent, ZeD._pendingWorldAccent = a.pc, a.pw
    pcall(function()
        local ws = S.p:getModData().ZeD_WinState
        if ws and ws.char and a.hasC then ws.char.accentKey = a.sc end
        if ws and ws.world and a.hasW then ws.world.accentKey = a.sw end
    end)
end
function S.reset()
    local ok, e = pcall(ZeD_Window.resetLayout)
    if not ok then Q.say("note: the layout reset failed: " .. tostring(e)) end
    S.accBack()
    return ok
end
function S.bothUp()
    local c, w = S.CW(), S.WW()
    return c ~= nil and w ~= nil and c:isVisible() and w:isVisible() and S.cc() ~= nil
end
-- queue: the zoom to getZ() (0.25 a notch, as G1's Q.zoomTo; the target is read when the step runs)
function S.qZoom(getZ)
    local st = {}
    Q.waitFor(20, 1200, function()
        local z = getZ()
        if not z then return true end
        if st.left == nil then st.left = math.floor((S.core:getZoom(0) - z) / 0.25 + 0.5) end
        if st.left == 0 then return true end
        S.core:doZoomScroll(0, (st.left > 0) and -1 or 1)
        st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
        return st.left == 0
    end, function() end)
    Q.step(100, function() Q.say("zoom " .. tostring(S.core:getZoom(0))) end)
end

-- ----- the title bar (B6-17)
function S.loadNow()
    local t = nil
    pcall(function() t = ZeD.Atoms.loadText(S.p:getInventory():getCapacityWeight(), S.p:getMaxWeight()) end)
    return tostring(t)
end
-- the words the title bar holds now (pins first, then the load)
function S.barWords(win)
    local t = {}
    for _, st in ipairs((win and win.titleStats) or {}) do t[#t + 1] = tostring(st.text) end
    return table.concat(t, " ; ")
end
-- the words the inventory gives this frame: each pin's line, then the load
function S.wantWords()
    local t = {}
    pcall(function() for _, st in ipairs(Pins.stats(S.p)) do t[#t + 1] = tostring(st.text) end end)
    t[#t + 1] = S.loadNow()
    return table.concat(t, " ; ")
end
function S.fill(it, part)
    local ok = pcall(function()
        local fc = it:getFluidContainer()
        fc:Empty()
        fc:addFluid(Fluid.Water, fc:getCapacity() * part)
    end)
    pcall(function() S.p:getInventory():setDrawDirty(true) end)
    return ok
end
function S.litres(it)
    local s = "?"
    pcall(function() local fc = it:getFluidContainer(); s = string.format("%.1f of %.1f L", fc:getAmount(), fc:getCapacity()) end)
    return s
end
function S.pinsKeep()
    if S.pinsWas then return end
    local L = Pins.list(S.p)
    S.pinsWas = {}
    for i, e in ipairs(L) do S.pinsWas[i] = e end
end
function S.pinsBack()
    if not S.pinsWas then return end
    pcall(function()
        local L = Pins.list(S.p)
        for i = #L, 1, -1 do table.remove(L, i) end
        for i, e in ipairs(S.pinsWas) do L[i] = e end
    end)
    S.pinsWas = nil
end
-- an item's stack opened in the Character list, so the item has a row of its own (hfr_inv.lua's way); back: as found
function S.stackOpen(it)
    local c, ft = S.cc(), nil
    pcall(function() ft = it:getFullType() end)
    if not (c and ft) then return end
    c._expandedStacks = c._expandedStacks or {}
    S.stackWas = S.stackWas or {}
    if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
    c._expandedStacks[ft] = true
    for _, cs in ipairs(c._colStates or {}) do cs.expandedStacks = cs.expandedStacks or c._expandedStacks; cs.expandedStacks[ft] = true end
end
function S.stackBack()
    pcall(function()
        local c = S.cc()
        for ft, v in pairs(S.stackWas or {}) do
            if c and c._expandedStacks then
                if v == false then c._expandedStacks[ft] = nil else c._expandedStacks[ft] = v end
            end
        end
    end)
    S.stackWas = nil
end

-- ----- crates (B5-1, B7-1)
-- a free square beside the character and not in front of him (the camera looks from the south-east: west and north
-- of him are behind, the two side corners level with him); skip: a square already used
function S.crateSq(skip)
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, d in ipairs({ { -1, 0 }, { 0, -1 }, { -1, -1 }, { 1, -1 }, { -1, 1 } }) do
        local sq = getCell():getGridSquare(x + d[1], y + d[2], z)
        local free = false
        if sq and sq ~= skip then pcall(function() free = sq:isFree(false) end) end
        if free then return sq end
    end
    return nil
end
function S.mkCrate(sq, things)
    local c = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        local inv = o:getContainer()
        if inv then
            pcall(function() inv:setExplored(true) end)
            c = { obj = o, inv = inv, sq = sq, n = 0 }
        end
    end)
    if c then
        for _, ft in ipairs(things) do
            pcall(function() if c.inv:AddItem(ft) then c.n = c.n + 1 end end)
        end
        pcall(function() c.inv:setDrawDirty(true) end)
    end
    return c
end
function S.rmCrate(c)
    if not (c and c.obj) then return end
    pcall(function() c.inv:removeAllItems() end)
    pcall(function()
        local sq = c.obj:getSquare() or c.sq
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(c.obj) end); sq:RemoveTileObject(c.obj) end
    end)
    c.obj = nil
    pcall(function() S.WW()._containerTimer = 30 end)
end
function S.cratesBack()
    S.rmCrate(S.crA); S.rmCrate(S.crB)
    S.crA, S.crB = nil, nil
end
function S.listed(inv)
    local w = S.WW()
    for _, e in ipairs((w and w._containers) or {}) do if e.inventory == inv then return true end end
    return false
end
function S.shows(inv) local c = S.wc(); return c ~= nil and inv ~= nil and c._inventory == inv end
-- a left click on an object in the world, as the game hands it on: its click handler's press and release, on the
-- game's tick (bx_inventory.lua H.clickOn; a real click comes before the tick's watch and the frame's draw). The click
-- is recorded in S.wclk (QA review: never S.click, the kit's own list click in hfr_common.lua, which B6-17 uses).
-- before: run on the same tick just before the click (B7-1 rolls the side there)
function S.clickOn(cr, before)
    local c = { done = false }
    S.wclk = c
    S.clickN = (S.clickN or 0) + 1
    local n = S.clickN
    local ev = Events.OnTickEvenPaused or Events.OnTick
    local go
    go = function()
        ev.Remove(go)
        if before then
            local okB, eB = pcall(before)
            if not okB then c.beforeErr = tostring(eB) end
        end
        local w = S.WW()
        local rod = w and w._rod
        c.at = { h = rod and rod._h, winH = w and w:getHeight(), rolled = w and w._rolled }
        local vl = nil
        pcall(function() vl = getPlayerLoot(S.pn) end)
        local ok, err = pcall(function()
            local Hd = ISObjectClickHandler
            Hd.lastClickTime = nil   -- (never the second half of a double-click)
            Hd.onObjectLeftMouseButtonDown(cr.obj, 40 * n, 40)
            Hd.onObjectLeftMouseButtonUp(cr.obj, 40 * n, 40)
        end)
        local asked = false
        pcall(function() asked = vl:getIsVisible() and vl.inventory == cr.inv end)
        c.how = "the game's click handler"
        if not asked then
            c.how = "the loot page's own calls (the click handler did not ask" .. (ok and "" or (": " .. tostring(err))) .. ")"
            pcall(function() vl:setNewContainer(cr.inv); vl:setVisible(true) end)
        end
        c.done = true
    end
    ev.Add(go)
end

-- ----- the UI scale (B5-7)
function S.scaleIdx(v)
    for i, k in ipairs(St.scaleKeys or {}) do if type(k) == "number" and math.abs(k - v) < 0.001 then return i end end
    return nil
end
-- a pick as ZeD setup makes it: the value, the live preview, the Apply (bx_scale.lua H.set)
function S.setScale(i)
    local o = St.uiScaleOption
    o:setValue(i)
    if o.onChange then o.onChange(o, i) end
    if o.onChangeApply then o.onChangeApply(o, i) end
    S.scaleAt = getTimestampMs()
end
function S.scaleSettled()
    if getTimestampMs() - (S.scaleAt or 0) < 600 then return false end
    if Sc._reopenAt ~= nil then return false end
    local a = Sc._appliedRoot
    return a ~= nil and math.abs(a - Sc.compute()) < 0.001 and math.abs(Sc.root() - a) < 0.001
end
-- a window dragged by its title bar until its left edge is at x
function S.dragTo(w, x)
    local dx = x - w:getX()
    if dx == 0 then return end
    local px, py = math.floor(w:getWidth() / 2), math.floor(w:titleBarHeight() / 2)
    w._lastTitleClick = nil
    pcall(w.onMouseDown, w, px, py)
    local step = math.floor(dx / 4)
    for i = 1, 4 do
        local d = (i < 4) and step or (dx - step * 3)
        pcall(w.onMouseMove, w, d, 0)
    end
    pcall(w.onMouseUp, w, px, py)
    w._lastTitleClick = nil
end
-- (the drag did not land there: the window is put there)
function S.placeAt(w, x)
    local d = x - w:getX()
    if math.abs(d) <= 2 then return false end
    w:setX(x)
    w._lastSetX = w:getX()
    if w._anchorRightEdge then w._anchorRightEdge = w._anchorRightEdge + d end
    return true
end
function S.overlap()
    local c, w = S.CW(), S.WW()
    if not (c and w) then return false end
    local cx, cy, cW, cH = c:getX(), c:getY(), c:getWidth(), c:getHeight()
    local wx, wy, wW, wH = w:getX(), w:getY(), w:getWidth(), w:getHeight()
    return cx < wx + wW and wx < cx + cW and cy < wy + wH and wy < cy + cH
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    G1.tp(S.P.smoke, "SE")
    S.was.zoom = S.core:getZoom(0)
    pcall(function() S.was.scale = St.uiScaleOption:getValue() end)
    S.openPair()
end)
Q.waitFor(10, 300, function() return S.bothUp() end, function(ok)
    if not ok then Q.say("ERR the pair did not open") end
    if ZEDQA_LAYOUT_SNAP then S.snap = ZEDQA_LAYOUT_SNAP() end
    local c, w = S.CW(), S.WW()
    S.was.outC, S.was.outW = c and c._outSince, w and w._outSince
    -- (the places as found, read before the reset below)
    local g0c, g0w = S.geo(c), S.geo(w)
    S.accKeep()
    S.holdBoth()
    S.down(c); S.down(w)
    S.charTab("loot"); S.worldTab("loot")
    S.reset()
    Q.say(string.format("as found: UI scale step %s (root %s), zoom %s, Character %s pins %s/%s, World %s pins %s/%s",
        tostring(S.was.scale), tostring(Sc and Sc.root()), tostring(S.was.zoom), g0c, tostring(S.snap and S.snap.char and S.snap.char.pinInv),
        tostring(S.snap and S.snap.char and S.snap.char.pinDrawer), g0w, tostring(S.snap and S.snap.world and S.snap.world.pinInv),
        tostring(S.snap and S.snap.world and S.snap.world.pinDrawer)))
end)
-- (zoom 1, as the other beast day parts: at the smoke spot the default spread ends at y 735 and the character's box
-- starts at y 776 (hfr_inv / hfr_tabs logs, Nov 20), so nothing covers him and the crates are drawn full size. Only
-- B5-7's 2x pair reaches over that box: that picture zooms out on its own, below)
S.qZoom(function() return 1.0 end)

-- ===================================================================== B5-2: rolled up over a rolled side, no rod
S.qRolled("c", "skills", "b52")
Q.step(5, function() if S.ok.b52 then S.via(S.CW(), S.dbl) end end)
Q.waitFor(2, 300, function() local w = S.CW(); return not S.ok.b52 or (w ~= nil and w._qaPressDone == true and w.windowShaded == true) end, function(ok)
    if S.ok.b52 and not ok then S.ok.b52 = false; S.why.b52 = "the Character window did not roll up on the double-click" end
end)
-- (the tab hides itself on its next draw: waited for, and the picture is taken either way)
Q.waitFor(2, 120, function() local w = S.CW(); local rod = w and w._rod; return not S.ok.b52 or not (rod and rod:isVisible()) end, function() end)
Q.still(5, function()
    local name = "B5-2_rolled_up_no_rod"
    if not S.ok.b52 then S.skip(name, S.why.b52); return end
    local w = S.CW()
    local rod = w and w._rod
    local showing = rod ~= nil and rod:isVisible()
    S.take(name, "the Character window rolled up to its title bar (at " .. S.geo(w) .. ") by a double-click while its inventory side was rolled under its tab on Skills; "
        .. (showing and "FAULT: the side's tab is still on screen beside it" or "no tab left on screen beside it"))
end)
Q.step(5, function()
    S.down(S.CW())
    S.charTab("loot")
end)
Q.waitFor(5, 300, function() local w = S.CW(); return w ~= nil and not w.windowShaded and not w._rolled and w._activeTab == "loot" end, function() end)

-- ===================================================================== B6-17: the title bar while the side is hidden
Q.step(10, function()
    S.openPair(); S.holdBoth()
    S.ok.b617 = false
    if not (Pins and Pins.toggle and Pins.kindOf and Pins.list) then S.why.b617 = "no title bar pins in this build"; return end
    S.flask = S.add("Base.Canteen") or S.add("Base.WaterBottle")
    if not (S.flask and S.fill(S.flask, 1.0)) then S.why.b617 = "no canteen or water bottle could be made and filled"; return end
    local kind = Pins.kindOf(S.flask)
    if not kind then S.why.b617 = "the canteen cannot be pinned"; return end
    S.pinsKeep()
    -- (the canteen's pin alone while its pictures are taken: the bar of a window narrowed to its drawer drops the older
    -- pins first and may cut a pin's name, and a fourth pin would take the oldest off with a note over the character's
    -- head. The pins found are put back after, S.pinsBack)
    local L = Pins.list(S.p)
    for i = #L, 1, -1 do table.remove(L, i) end
    local id = nil
    pcall(function() id = S.flask:getID() end)
    local okPin = pcall(function() Pins.toggle(S.p, kind, id, S.flask:getDisplayName()) end)
    if not (okPin and Pins.isPinned(S.p, kind, id)) then S.why.b617 = "the pin did not take"; return end
    S.ok.b617 = true
    Q.say("B6-17: pinned " .. tostring(S.flask:getFullType()) .. " (" .. S.litres(S.flask) .. "), pins now " .. #L .. ", load " .. S.loadNow())
end)
Q.step(1, function() S.pre617 = S.ok.b617 end)
S.qRolled("c", "skills", "b617r")
-- (the bar first shows the full canteen while the side is hidden; then the change, made while it is hidden)
Q.waitFor(5, 300, function()
    if not (S.pre617 and S.ok.b617r) then return true end
    return S.barWords(S.CW()) == S.wantWords()
end, function(ok)
    S.ok.b617 = (S.pre617 and S.ok.b617r) and true or false
    if not S.ok.b617 then S.why.b617 = S.why.b617 or S.why.b617r; return end
    S.bar0 = S.barWords(S.CW())
    Q.say("B6-17: side hidden, before the change the bar reads [" .. S.bar0 .. "]" .. (ok and "" or " (it does not match the inventory: [" .. S.wantWords() .. "])"))
    S.fill(S.flask, 0.3)
end)
Q.waitFor(5, 400, function()
    if not S.ok.b617 then return true end
    local bar = S.barWords(S.CW())
    return bar ~= S.bar0 and bar == S.wantWords()
end, function(ok) S.match617 = ok end)
Q.still(5, function()
    local name = "B6-17_a_side_hidden_bar_current"
    if not S.ok.b617 then S.skip(name, S.why.b617); return end
    local w = S.CW()
    local bar, want = S.barWords(w), S.wantWords()
    S.bar1 = bar
    S.take(name, "the Character window on Skills, its inventory side rolled away under its tab (side hidden " .. tostring(w._rolled) .. "); the pinned canteen was poured down to "
        .. S.litres(S.flask) .. " while the side was hidden; the title bar read [" .. tostring(S.bar0) .. "] and now reads [" .. bar .. "]; the inventory says [" .. want .. "]"
        .. ((bar == want and bar ~= S.bar0) and ": they match" or ": FAULT, the bar did not follow the inventory"))
end)
Q.step(5, function()
    S.down(S.CW())
    S.charTab("loot")
    S.seekPos = nil
end)
Q.waitFor(5, 300, function() local w = S.CW(); return not S.ok.b617 or (w ~= nil and not w._rolled and w._activeTab == "loot") end, function()
    if S.ok.b617 then S.stackOpen(S.flask) end
end)
Q.waitFor(5, 600, function() return not S.ok.b617 or S.seekRow(S.cc(), S.flask) end, function(ok)
    if not S.ok.b617 then return end
    S.row617 = ok and S.click(S.cc(), S.zone(S.cc(), S.flask)) or false
    Q.say("B6-17: the canteen's row " .. tostring(ok) .. ", pressed " .. tostring(S.row617))
end)
Q.waitFor(10, 300, function() return not (S.ok.b617 and S.row617) or S.cardOn(S.flask) end, function()
    if S.ok.b617 then S.clearChar() end
end)
Q.still(10, function()
    local name = "B6-17_b_side_down_same_numbers"
    if not S.ok.b617 then S.skip(name, S.why.b617); return end
    -- (the card's litres are this picture's point: without the card it is not taken)
    if not S.cardOn(S.flask) then S.skip(name, "the canteen's card did not open (its row found " .. tostring(S.row617) .. ")"); return end
    local w = S.CW()
    S.take(name, "the side down again, on Loot, the canteen's card out (" .. S.litres(S.flask)
        .. "); the title bar reads [" .. S.barWords(w) .. "] (the load is in the list's heading while the side shows), the inventory says ["
        .. S.wantWords() .. "]; while hidden the bar read [" .. tostring(S.bar1) .. "]")
end)
Q.step(5, function()
    if S.flask and S.cardOn(S.flask) then S.click(S.cc(), S.zone(S.cc(), S.flask)) end
    S.stackBack()
    S.pinsBack()
    S.takeMade()
    S.flask = nil
    S.charTab("loot")
end)

-- ===================================================================== B5-4: Reset both windows from Maps
Q.step(20, function()
    S.openPair(); S.holdBoth()
    S.reset()
    S.ok.b54 = S.worldTab("maps")
    S.char54 = S.charTab("skills")
    if not S.ok.b54 then S.why.b54 = "no Maps tab on the World window's strip here" end
end)
Q.waitFor(10, 400, function()
    if not S.ok.b54 then return true end
    local c, w = S.CW(), S.WW()
    return w ~= nil and w._activeTab == "maps" and (not S.char54 or (c ~= nil and c._activeTab == "skills"))
end, function(ok)
    if S.ok.b54 and not ok then S.ok.b54 = false; S.why.b54 = "the Maps tab did not open" end
end)
Q.still(10, function()
    if not S.ok.b54 then return end
    local c, w = S.CW(), S.WW()
    S.pre54 = "World on " .. tostring(w._activeTab) .. " at " .. S.geo(w) .. ", Character on " .. tostring(c._activeTab) .. " at " .. S.geo(c)
    S.reset()   -- (ZeD_Window.resetLayout with no argument: what "Reset both windows" in a window box's menu runs)
end)
Q.waitFor(5, 400, function()
    if not S.ok.b54 then return true end
    local c, w = S.CW(), S.WW()
    return c ~= nil and w ~= nil and c._activeTab == "loot" and w._activeTab == "loot"
end, function(ok) S.loot54 = ok end)
Q.still(10, function()
    local name = "B5-4_reset_both_on_loot"
    if not S.ok.b54 then S.skip(name, S.why.b54); return end
    local c, w = S.CW(), S.WW()
    S.take(name, "after Reset both windows (before it: " .. tostring(S.pre54) .. "): the World window on " .. tostring(w._activeTab) .. " at " .. S.geo(w)
        .. ", the Character window on " .. tostring(c._activeTab) .. " at " .. S.geo(c)
        .. (S.loot54 and "; both back on Loot, so each strip lights its Loot tab" or "; FAULT: a window is not back on Loot"))
end)
Q.step(5, function() S.charTab("loot"); S.worldTab("loot") end)

-- ===================================================================== B7-1 and B5-1: a click on a crate
-- (the pair shut and opened: a fresh World window has made no tab for its side yet, which B7-1's quick click needs)
Q.step(10, function() S.closePair() end)
Q.waitFor(10, 300, function() return not (S.CWm.isOpen() or S.WWm.isOpen()) end, function() S.openPair() end)
Q.waitFor(10, 300, function() return S.bothUp() end, function(ok)
    S.holdBoth()
    S.charTab("loot"); S.worldTab("loot")
    S.ok.cr = false
    if not ok then S.why.cr = "the pair did not open again"; return end
    G1.tp(S.P.smoke, "SE")
    local sqA = S.crateSq(nil)
    local sqB = sqA and S.crateSq(sqA)
    if not (sqA and sqB) then S.why.cr = "no two free squares beside and behind the character for the crates"; return end
    S.crA = S.mkCrate(sqA, { "Base.Bandage", "Base.Bandage", "Base.Bandage", "Base.Twine", "Base.Hammer" })
    S.crB = S.mkCrate(sqB, { "Base.TinnedBeans", "Base.TinnedBeans", "Base.CannedCornedBeef", "Base.Plank", "Base.Plank", "Base.NailsBox" })
    if not (S.crA and S.crB) then S.why.cr = "the crates could not be made"; return end
    S.ok.cr = true
    pcall(function() S.WW()._containerTimer = 30 end)
    Q.say(string.format("crates: A at %d,%d with %d things, B at %d,%d with %d things; the character at %d,%d",
        sqA:getX(), sqA:getY(), S.crA.n, sqB:getX(), sqB:getY(), S.crB.n, math.floor(S.p:getX()), math.floor(S.p:getY())))
end)
Q.waitFor(5, 400, function() return not S.ok.cr or (S.listed(S.crA.inv) and S.listed(S.crB.inv)) end, function(ok)
    if S.ok.cr and not ok then S.ok.cr = false; S.why.cr = "the World window does not list the crates beside the character" end
end)
-- B7-1: the side rolls on the same update as a click on a crate, before its tab has drawn once (a quick click whose
-- release lands on the update the side's 2 second timer runs out). (QA review: the roll is made inside the click's own
-- tick, just before the click, S.clickOn's before. Left to the window's next update with the click a frame later, as
-- bx_inventory 6d does, the order is the frames' luck: its 16:33 run on Nov 21 found "its tab had drawn before the click
-- came (669.48 of 735 px)". Here a new tab only joins the game's UI list at the next UI update and draws after that,
-- and ZeD's watch sees the click on the same tick (OnTick fires after OnTickEvenPaused in IngameState.updateInternal)
-- or, paused, on the next tick before any draw: the side is always asked down before its tab has moved.)
Q.step(10, function()
    S.ok.b71 = S.ok.cr
    S.why.b71 = S.why.cr
    if not S.ok.b71 then return end
    S.holdBoth()
    if not S.worldTab("craft") then S.ok.b71 = false; S.why.b71 = "no Craft tab on the World window's strip here" end
end)
Q.waitFor(5, 400, function() return not S.ok.b71 or S.canRoll(S.WW()) end, function(ok)
    if S.ok.b71 and not ok then S.ok.b71 = false; S.why.b71 = "the inventory side cannot roll here (the Craft drawer did not open beside the list)" end
end)
-- (the Craft drawer done widening first: the halves roll a side only beside a drawer that has stopped)
Q.still(5, function()
    if not S.ok.b71 then return end
    local w = S.WW()
    S.new71 = w ~= nil and w._rod == nil
    S.rolled71, S.first71 = false, nil
    S.clickOn(S.crA, function()
        local ww = S.WW()
        if ww and S.rollSide(ww) then Hv.drive(ww) end
        S.rolled71 = ww ~= nil and ww._rolled == true
    end)
end)
Q.waitFor(1, 400, function()
    if not S.ok.b71 then return true end
    S.holdBoth()   -- (the click's own half-second hold replaced, so the side stays as the click left it for the picture)
    local w = S.WW()
    if not (S.wclk and S.wclk.done) then return false end
    -- (first look after the click's tick, before the next draw: the side already down means it never drew rolled)
    if S.first71 == nil then S.first71 = w ~= nil and not w._rolled end
    return w ~= nil and not w._rolled and S.shows(S.crA.inv)
end, function(ok)
    S.down71 = ok
    if not S.ok.b71 then return end
    if not S.rolled71 then
        S.ok.b71 = false
        S.why.b71 = "the inventory side did not roll on the click's tick (" .. S.rodWords(S.WW()) .. (S.wclk and S.wclk.beforeErr and (", error " .. S.wclk.beforeErr) or "") .. ")"
        S.down(S.WW())   -- (the roll it asked for stays asked: the side put down, so B5-1 starts from it down)
        return
    end
    S.worldClear()
end)
Q.still(10, function()
    local name = "B7-1_quick_click_side_down"
    if not S.ok.b71 then S.skip(name, S.why.b71); return end
    local w = S.WW()
    local at = (S.wclk and S.wclk.at) or {}
    local early = at.rolled == true and at.h ~= nil and at.winH ~= nil and at.h >= at.winH
    S.take(name, "the World window on " .. tostring(w._activeTab) .. "; its inventory side rolled on the same tick as a left click on crate A (bandages, twine, a hammer; by "
        .. tostring(S.wclk and S.wclk.how) .. "), its tab " .. tostring(at.h) .. " of " .. tostring(at.winH) .. " px tall at the click"
        .. ((early and S.first71) and " (not drawn yet) and the side down again before the next draw" or (", the side down before the next draw " .. tostring(S.first71)))
        .. (S.new71 and "" or " (its tab made before)") .. ": " .. (S.down71 and "the side is down and lists crate A's things"
            or ("FAULT, the side is not down on crate A (" .. S.rodWords(w) .. ", list on crate A " .. tostring(S.shows(S.crA.inv)) .. ")")))
end)
-- B5-1: the side fully rolled away under its tab, then the click on the other crate
Q.step(5, function()
    S.ok.b51 = S.ok.cr
    S.why.b51 = S.why.cr
    local w = S.WW()
    if w and w._rolled then pcall(Cu.finishUnroll, w) end
end)
Q.step(10, function() if S.ok.b51 then S.pre51 = true end end)
S.qRolled("w", "craft", "b51r")
Q.step(5, function()
    S.ok.b51 = (S.pre51 and S.ok.b51r) and true or false
    if not S.ok.b51 then S.why.b51 = S.why.b51 or S.why.b51r; return end
    Q.say("B5-1: before the click: " .. S.rodWords(S.WW()) .. ", list on crate B " .. tostring(S.shows(S.crB.inv)))
    S.clickOn(S.crB)
end)
Q.waitFor(2, 400, function()
    if not S.ok.b51 then return true end
    S.holdBoth()
    local w = S.WW()
    return S.wclk ~= nil and S.wclk.done and w ~= nil and not w._rolled and S.shows(S.crB.inv)
end, function(ok) S.down51 = ok; if S.ok.b51 then S.worldClear() end end)
Q.still(10, function()
    local name = "B5-1_crate_click_side_down"
    if not S.ok.b51 then S.skip(name, S.why.b51); return end
    local w = S.WW()
    S.take(name, "the World window on " .. tostring(w._activeTab) .. ", its inventory side was rolled away under its tab; a left click on crate B (tinned food, planks, nails; by "
        .. tostring(S.wclk and S.wclk.how) .. "): " .. (S.down51 and "the side is down and lists crate B's things"
            or ("FAULT, the side is not down on crate B (" .. S.rodWords(w) .. ", list on crate B " .. tostring(S.shows(S.crB.inv)) .. ")")))
end)
Q.step(5, function()
    S.down(S.WW())
    S.worldTab("loot")
    S.cratesBack()
    pcall(function() local vl = getPlayerLoot(S.pn); if vl and vl:getIsVisible() then vl:setVisible(false) end end)
end)

-- ===================================================================== B5-7: 1x to 2x with the windows right of center
-- (zoomed out for this picture only: at 2x the pair lands at about x 2044-3840, y 0-840, inside the character's box
-- at zoom 1 (1760-2080, 776-1196); at zoom 1.75 the box is about 1829-2011 wide and starts below y 870, clear. The
-- picture is about the windows' places, so they are not moved aside; the put-back zooms back to the zoom found)
S.qZoom(function() return 1.75 end)
Q.step(20, function()
    S.openPair(); S.holdBoth()
    S.charTab("loot"); S.worldTab("loot")
    S.i1, S.i2 = S.scaleIdx(1.0), S.scaleIdx(2.0)
    S.ok.b57 = (St.uiScaleOption ~= nil and Sc ~= nil and S.i1 ~= nil and S.i2 ~= nil and S.was.scale ~= nil) and true or false
    if not S.ok.b57 then S.why.b57 = "the UI scale option or its 1x and 2x steps are not there"; return end
    S.scaleDirty = true
    S.setScale(S.i1)
end)
Q.waitFor(5, 900, function() return not S.ok.b57 or S.scaleSettled() end, function(ok)
    if not S.ok.b57 then return end
    if not ok then Q.say("note: the 1x scale did not settle (reopening " .. tostring(Sc._reopenAt) .. ")") end
    S.openPair()
end)
Q.waitFor(5, 400, function() return not S.ok.b57 or S.bothUp() end, function(ok)
    if not S.ok.b57 then return end
    if not ok then S.ok.b57 = false; S.why.b57 = "the windows did not come back at 1x"; return end
    S.holdBoth()
    S.charTab("loot"); S.worldTab("loot")
    S.reset()
end)
Q.still(10, function()
    if not S.ok.b57 then return end
    local c = S.CW()
    S.cx57 = math.floor(S.core:getScreenWidth() / 2) + ZeD.T.px(20)
    S.dragTo(c, S.cx57)
end)
Q.step(10, function()
    if not S.ok.b57 then return end
    local c, w = S.CW(), S.WW()
    local forced = S.placeAt(c, S.cx57)
    S.wx57 = c:getX() + c:getWidth() + ZeD.T.px(10)
    S.dragTo(w, S.wx57)
    if forced then Q.say("note: the Character window's drag did not land; it was put at x " .. S.cx57) end
end)
Q.step(10, function()
    if not S.ok.b57 then return end
    local c, w = S.CW(), S.WW()
    if S.placeAt(w, S.wx57) then Q.say("note: the World window's drag did not land; it was put at x " .. S.wx57) end
    S.placeAt(c, S.cx57)
end)
-- (still for a while: the windows keep their places once a second, and the scale change's close keeps them too)
Q.still(60, function()
    if not S.ok.b57 then return end
    local c, w = S.CW(), S.WW()
    local half = S.core:getScreenWidth() / 2
    S.pre57 = "at 1x (root " .. tostring(Sc.root()) .. ") Character " .. S.geo(c) .. ", World " .. S.geo(w)
    Q.say("B5-7: " .. S.pre57)
    if not (c:getX() >= half and w:getX() >= half and w:getX() + w:getWidth() <= S.core:getScreenWidth() and not S.overlap()) then
        S.ok.b57 = false; S.why.b57 = "the windows could not be stood side by side right of center at 1x (" .. S.pre57 .. ")"; return
    end
    S.setScale(S.i2)
end)
Q.waitFor(5, 900, function() return not S.ok.b57 or (S.scaleSettled() and S.bothUp()) end, function(ok)
    if not S.ok.b57 then return end
    if not ok then S.ok.b57 = false; S.why.b57 = "the 2x scale did not settle with both windows open (reopening " .. tostring(Sc._reopenAt) .. ")"; return end
    S.holdBoth()
end)
Q.still(10, function()
    local name = "B5-7_2x_side_by_side"
    if not S.ok.b57 then S.skip(name, S.why.b57); return end
    local c, w = S.CW(), S.WW()
    local root = Sc.root()
    S.take(name, "UI scale picked 2x (root " .. tostring(root) .. ((root and root < 1.99) and ", NOTE: the screen caps it below 2x" or "") .. ") from 1x with both windows right of center ("
        .. tostring(S.pre57) .. "): now Character " .. S.geo(c) .. ", World " .. S.geo(w) .. "; "
        .. (S.overlap() and "FAULT: one lies on the other" or "side by side, neither on the other"))
end)
-- the scale back, then the default spread at that scale
function S.qScaleBack()
    Q.step(5, function()
        S.back57 = false
        if not S.scaleDirty then return end
        local cur = nil
        pcall(function() cur = St.uiScaleOption:getValue() end)
        if S.was.scale == nil then return end
        S.back57 = true
        if cur ~= S.was.scale then S.setScale(S.was.scale) else pcall(St.applyScale); S.scaleAt = getTimestampMs() end
    end)
    Q.waitFor(5, 900, function() return not S.back57 or S.scaleSettled() end, function(ok)
        if not S.back57 then return end
        if not ok then Q.say("ERR the UI scale did not settle on the way back (reopening " .. tostring(Sc._reopenAt) .. ")") end
        S.openPair()
    end)
    Q.waitFor(5, 400, function() return not S.back57 or S.bothUp() end, function()
        if not S.back57 then return end
        S.scaleDirty = false
        S.holdBoth()
        S.charTab("loot"); S.worldTab("loot")
        S.reset()
        Q.say("UI scale back: step " .. tostring(St.uiScaleOption:getValue()) .. " (was " .. tostring(S.was.scale) .. "), root " .. tostring(Sc.root()))
    end)
end
S.qScaleBack()

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(function() ISMouseDrag.dragging = nil; ISMouseDrag.draggingFocus = nil end)
    G1.closeMenus()
    S.cratesBack()
    S.stackBack()
    S.pinsBack()
    S.takeMade()
    G1.glassesBack(Q)
end)
S.qScaleBack()
S.qZoom(function() return S.was.zoom end)
Q.step(20, function()
    S.openPair()
    local c, w = S.CW(), S.WW()
    S.down(c); S.down(w)
    S.charTab("loot"); S.worldTab("loot")
    if ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "bxrw") else pcall(ZeD_Window.resetLayout) end
    S.accBack()
    if c then c._outSince = S.was.outC end
    if w then w._outSince = S.was.outW end
    S.back0()
end)
Q.step(30, function()
    -- the character alive and whole (nothing here hurts him; healed if anything did)
    local hp, dead = nil, nil
    pcall(function() dead = S.p:isDead(); hp = S.p:getBodyDamage():getOverallBodyHealth() end)
    if hp and hp < 99.5 and not dead then pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end) end
    local c, w = S.CW(), S.WW()
    Q.say("put back: character dead " .. tostring(dead) .. ", health " .. tostring(hp) .. "; UI scale step " .. tostring(St.uiScaleOption and St.uiScaleOption:getValue())
        .. " (was " .. tostring(S.was.scale) .. "); zoom " .. tostring(S.core:getZoom(0)) .. " (was " .. tostring(S.was.zoom) .. "); Character " .. S.geo(c)
        .. " pins " .. tostring(S.pinsOf(c).inv) .. "/" .. tostring(S.pinsOf(c).drawer) .. ", World " .. S.geo(w) .. " pins " .. tostring(S.pinsOf(w).inv) .. "/" .. tostring(S.pinsOf(w).drawer))
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
end)
Q.start()
