-- ZeDUI/tools/qa/vx10_tab.lua  (Nov 21 2026, QA batch 10; tag vx10_tab): the in-game proof of Build's fix for B10-5,
-- the tucked-away inventory tab's count (commit 2cff8f8f3: ZeD.InventoryRenderer.liveCount, the Character window's
-- tab chip and drop target, the World window's tab chip). Finding: ZeDUI/qa/audits/2026-11-21_beast_batch10.md.
-- Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA vx10_tab".
--
-- The finding: the Character window's inventory side, rolled away under its tab, labeled the tab "Inventory  26"
-- (help line "26 items") while the list, rolled down, said "8 items": the tab counted inv:getItems():size(), what he
-- wears and his bags in; the heading counts what the rows show (InventoryRenderer.shownCount). And a bag picked with
-- the mouse on a tab other than Loot sets only _viewedContainer: the tab then said "Inventory" over the bag's count
-- while a drop on it went into the bag.
--
-- What each check proves (each line says what the old code showed):
--   A  His own inventory, the side rolled away beside a tab drawer (Skills, else the next tab whose drawer leaves the
--      list showing). The tab's label and its help line give the count of what the list shows: the script's own count
--      (not hidden, not worn, not held), the same as ZeD.InventoryRenderer.liveCount and as the heading's count just
--      before the roll. What he wears and holds is not counted (inv:getItems():size() is said beside it). A bandage
--      put in while rolled: the tab goes up by one at once; taken out: back down. Rolled down again: the list shows
--      what the tab named, its heading's "N items" (and shownCount) at the tab's number. Old code: the raw count on the
--      tab, so these fail while he wears anything (the first line and the bandage lines fail anyway: liveCount is not
--      there). With nothing worn, held or hidden, old and new agree: the help-line and rolled-down lines say SKIP.
--   B  A bag picked with the mouse on that tab (its strip button pressed and let go: the viewed container alone, the
--      active one still his inventory), the side rolled: the tab names that bag and counts its things, and its drop
--      target (the curtain's dropInv: what a drop let go on the tab goes into) is that same bag. Rolled down: the list
--      shows the bag the tab named, its heading at the tab's count. Old code: the tab said "Inventory" over the bag's
--      count while the drop went into the bag (and the list, rolled down, showed the bag, not the inventory).
--   C  The World window: a bandage, twine and a hammer made on the ground at his feet, and a gate registered for the
--      floor list alone that keeps the hammer back (ZeD.ContainerGates.add, what a gate mod such as Immersive
--      Searching does); the side rolled beside Maps (else the next tab whose drawer leaves the list showing). The
--      floor's tab and help line count what the list shows (liveCount), not the hammer; rolled down, the heading's
--      count is the tab's. Old code: the raw count, the hammer in.
-- How it stages: both windows open as a pair. A window rolled up to its title bar, or with Loot columns open, has its
-- parts skipped (a tab press closes the columns, and they could not be put back). The halves' roll timers are held
-- for the run (win._outSince in the future, as bxr_win.lua holds them), so where the real pointer rests rolls nothing;
-- the pins are not touched. Each tab opens by its own press, settles, and is passed over for the next when its drawer
-- covers the list (a full card on a small screen: nothing beside it to roll). The side rolls by the curtain's own roll
-- inside the window's update with its onResize after (bx_windows.lua X.curtain, vx_windows.lua W8); the tab's label
-- is read once it rests at the title bar and has drawn afresh (the rod's _label, the words it draws), its help line
-- from ZeD.Curtain.tabHelp (the words the help line shows while the pointer rests on it). The side comes down by its
-- tab's own press and release, inside the rod's update. A bag he wears is used (a real bag before a key ring, the
-- fullest first); with none, a school bag is given and worn (vx_windows.lua W8). Waits are by the clock (read at 60
-- frames a second), as vx_inventory.lua's.
-- What it puts back (also when a step throws or the time runs out): both sides down (a side found rolled is rolled
-- again, the way it was rolled), the gate taken off, everything made taken away (ground, inventory, back), the
-- Character list's view, both lists' scroll and every pressed tab's own scroll (a tab press sets it back to the top)
-- as found, both windows on the tabs they were on, at their places and sizes (set back by the windows' own setters
-- only if the tab presses did not bring them back; never ZEDQA_LAYOUT_BACK or ZeD.Settings.syncWindowAccent, which
-- save ModOptions.ini), the roll timers as found, the pair shut if it was (with the layout the character keeps). No
-- option is changed, nothing is applied or saved, no file is written.

if not (RT and RT.make) then
    print("ZEDQA vx10_tab ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx10_tab VERDICT FAIL 1")
    print("ZEDQA vx10_tab DONE")
    return
end

local Q = RT.make("vx10_tab")
Q.maxMs = 240000   -- (four minutes, then the put-back; a run takes well under one)
local C = ZeD.Curtain
local S = { p = RT.p, pn = RT.pn, ok = { A = true, B = true, C = true }, why = {}, made = {}, st = {}, drawn = 0,
            a = {}, b = {}, c = {}, tab = {}, tsc = {}, vias = {} }
S.PART = { A = "A (his inventory's tab)", B = "B (a bag picked on a tab)", C = "C (the World window's tab)" }
S.GATE = "ZeDQA_vx10_tab"
-- the tabs tried in turn, the first whose drawer leaves the list showing beside it (on a small screen a full-card
-- drawer covers the whole window, and a covered list has no side to roll). Not Equip: its pick is not put back.
S.TABS = { c = { "skills", "health", "journal", "thermal", "identity" }, w = { "maps", "forage", "craft", "build" } }
local X = {}

-- after n frames, a step (none once the scene failed)
local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
-- after n frames, until cond() holds, for at most max frames' worth of time at 60 frames a second (a frame count
-- alone is shorter at a higher frame rate); then fn(ok). always: it runs after a failed scene too (the put-back)
local function waitFor(n, max, cond, fn, always)
    local st = {}
    local ms = math.floor(max * 1000 / 60)
    Q.waitFor(n, max * 6 + 900, function()
        if S.dead and not always then return true end
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function()
        if S.dead and not always then return end
        fn(st.ok == true)
    end)
end

-- ===================================================================== windows
function X.win(k) if k == "c" then return RT.cw() end; return RT.ww() end
function X.wname(k) if k == "c" then return "Character" end; return "World" end
function X.content(k) local w = X.win(k); return w and w._mainContent end
function X.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function X.bothOpen()
    local c, w = RT.cw(), RT.ww()
    return RT.isOpen() and X.worldOpen() and c ~= nil and w ~= nil and c:isVisible() and w:isVisible()
end
function X.openBoth() if not (RT.isOpen() and X.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end end
function X.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function X.gs(g)
    if not g then return "none" end
    return math.floor(g.x) .. "," .. math.floor(g.y) .. " " .. math.floor(g.w) .. "x" .. math.floor(g.h)
end
function X.sameGeo(a, b)
    if not (a and b) then return false end
    return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1
end
function X.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for a, b in pairs(t) do o[a] = X.copy(b) end
    return o
end
function X.inRect(r, x, y) return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
-- the halves' roll timers held: a time in the future in win._outSince holds them all (WindowHalves H.update, "QA's
-- staging"); nothing is held before the found values are kept (S.out0), and those go back at the end
function X.hold()
    if not S.out0 then return end
    local t = getTimestampMs() + 600000
    local c, w = RT.cw(), RT.ww()
    if c then c._outSince = t end
    if w then w._outSince = t end
end
-- whether the halves count a rolled side as rolled by hand (one the pointer's timer rolled is not)
function X.handOf(w) local h = false; pcall(function() h = w._halves.inv.hand end); return h and true or false end
-- a press the way the engine delivers one: inside the element's own update, followed by its onResize
-- (bx_windows.lua X.via; el._qaPressDone is false until the update ran it)
function X.via(el, fn)
    local own = rawget(el, "update")
    S.vias[#S.vias + 1] = { el = el, own = own }
    el._qaPressDone = false
    S.pressErr = nil
    el.update = function(self)
        self.update = own
        self:update()
        local ok, e = pcall(fn, self)
        if not ok then S.pressErr = tostring(e) end
        pcall(function() self:onResize() end)
        self._qaPressDone = true
    end
end
-- (put-back) every press whose update never ran is taken off its element, the last one first
function X.unvia()
    for i = #S.vias, 1, -1 do
        local v = S.vias[i]
        if v.el._qaPressDone == false then pcall(function() v.el.update = v.own end) end
    end
    S.vias = {}
end
-- (put-back) a window set back at a place and size by its own setters, as a player's move and resize leave it (its
-- layout reads them at rest); only for a window the tab presses did not bring back
function X.placeBack(w, g)
    if not (w and g) then return end
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
end

-- ===================================================================== tabs
function X.tabIds(k) if k == "c" then return RT.tabs(RT.charStrip()) end; return RT.tabs(RT.worldStrip()) end
function X.press(k, id) if k == "c" then return RT.charTab(id) end; return RT.worldTab(id) end
-- true once window k is on tab id and its drawer has held one width for 15 frames (S.st cleared before a press)
function X.settled(k, id)
    local w = X.win(k)
    if not w then return false end
    local st = S.st[k]
    if not st then st = { same = 0 }; S.st[k] = st end
    local e = math.floor(w._drawerEffW or 0)
    if e == st.last then st.same = st.same + 1 else st.same, st.last = 0, e end
    return w._activeTab == id and st.same >= 15
end
function X.canRoll(w)
    local can = false
    pcall(function() can = w._curtain.canRoll() and true or false end)
    return can
end
-- a tab's own scroll, which a press on that tab sets back to the top (as the player's press does: getActiveScroll and
-- getWorldActiveScroll); Maps keeps none, the Journal's is its diary's (sub-tab 1). Equip and Animals only as a tab
-- found open (the put-back's press on it).
function X.tabScroll(k, id)
    local w = X.win(k)
    if not w then return nil end
    if k == "c" then
        if id == "skills" then return w._skillsScroll end
        if id == "health" then return w._healthScroll end
        if id == "thermal" then return w._thermalScroll end
        if id == "identity" then return w._identityScroll end
        if id == "journal" and (w._journalSubTab or 1) == 1 then return w._journalScroll end
        if id == "equip" then
            local s = nil
            pcall(function() s = ZeD.EquipLoadout.scrollFor(w) end)
            return s or w._equipScroll
        end
        return nil
    end
    if id == "forage" then return w._forageScroll end
    if id == "craft" then return w._craftState and w._craftState.scroll end
    if id == "build" then return w._buildState and w._buildState.scroll end
    if id == "animals" then return w._animalsScroll end
    return nil
end
-- kept once per tab, before the run's first press on it (the tab found open is kept at the start: the put-back's press
-- on it sets it back to the top too); every one put back at the end
function X.keepScroll(k, id)
    if id == nil or id == "loot" then return end
    local key = k .. ":" .. id
    if S.tsc[key] then return end
    local pos = nil
    pcall(function() pos = X.tabScroll(k, id).scrollPos end)
    S.tsc[key] = { k = k, id = id, pos = pos }
end
function X.tabScrollBack()
    for _, t in pairs(S.tsc) do
        if t.pos ~= nil then pcall(function() X.tabScroll(t.k, t.id):setScrollPos(t.pos) end) end
    end
end
-- the next tab of S.TABS[k] the strip offers, pressed (S.try.cur; nil when none is left; a press that throws ends the
-- search with S.try.err)
function X.nextTab(k)
    local t = S.try
    local have = {}
    for _, id in ipairs(X.tabIds(k)) do have[id] = true end
    t.cur = nil
    while t.i < #S.TABS[k] and not t.err do
        t.i = t.i + 1
        local id = S.TABS[k][t.i]
        if have[id] then
            X.keepScroll(k, id)
            S.st = {}
            local okP, pressed = pcall(X.press, k, id)
            if not okP then t.err = id .. ": " .. tostring(pressed)
            elseif pressed then t.cur = id; return end
        end
    end
end

-- ===================================================================== the tab
-- the side rolled away and its tab at rest at the title bar, its label drawn since the roll
function X.atRest(w)
    local rod = w and w._rod
    if not (w and w._rolled and rod and rod:isVisible() and rod._h and rod._target) then return false end
    return rod._target <= (ZeD.T.titleBarH or 0) and rod._h <= rod._target and rod._label ~= nil and rod._chip ~= nil
end
-- the words the tab draws: its name, two spaces, its count (WindowCurtain.lua ZeD_CurtainRod:chipRect)
function X.label(w) local rod = w and w._rod; return rod and rod._label or nil end
function X.parse(label)
    if type(label) ~= "string" then return nil, nil end
    local name, n = string.match(label, "^(.-)%s%s([%d%.]+)$")
    return name or "", tonumber(n)
end
function X.tabN(w) local _, n = X.parse(X.label(w)); return n end
function X.lab(name, n) return tostring(name) .. "  " .. tostring(n) end
-- the help line's words while the pointer rests on the tab (ZeD.Curtain.tabHelp), and the words wanted
function X.help(w) local h = nil; pcall(function() h = C.tabHelp(w) end); return h end
function X.wantHelp(name, n)
    local h = nil
    pcall(function() h = ZeD.tr(n == 1 and "UI_ZeD_Curtain_TabHelpOne" or "UI_ZeD_Curtain_TabHelp", tostring(name or ""), n) end)
    return h
end
-- what a drop let go on the tab goes into (ZeD.Curtain.dropTarget hands back the window's dropInv)
function X.drop(w) local d = nil; pcall(function() d = w._curtain.dropInv() end); return d end

-- ===================================================================== counts
-- the ids of what he wears and holds (his list leaves them out; the Equip tab shows them)
function X.heldIds()
    local set = {}
    pcall(function()
        local worn = S.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:get(i):getItem()
            if it then set[it:getID()] = true end
        end
    end)
    pcall(function() local h = S.p:getPrimaryHandItem(); if h then set[h:getID()] = true end end)
    pcall(function() local h = S.p:getSecondaryHandItem(); if h then set[h:getID()] = true end end)
    return set
end
-- a container's things counted by the script itself: raw (inv:getItems():size()), hidden (the game hides them),
-- worn (worn or held: his own inventory only), gated (a gate keeps them back: ZeD.ContainerGates, the mod hook),
-- own (the rest: what the list shows)
function X.counts(inv)
    local r = { raw = -1, own = 0, worn = 0, hidden = 0, gated = 0 }
    if not inv then return r end
    local G = ZeD.ContainerGates
    local held = (inv == S.main) and X.heldIds() or {}
    local gate = nil
    pcall(function() gate = G.get(inv, S.p) end)
    pcall(function()
        local items = inv:getItems()
        r.raw = items:size()
        for i = 0, r.raw - 1 do
            local it = items:get(i)
            if not it or it:isHidden() then r.hidden = r.hidden + 1
            elseif held[it:getID()] then r.worn = r.worn + 1
            elseif gate and not G.keeps(gate, it) then r.gated = r.gated + 1
            else r.own = r.own + 1 end
        end
    end)
    return r
end
function X.cs(r)
    return "inv:getItems():size() " .. r.raw .. ": " .. r.worn .. " worn or held, " .. r.hidden .. " hidden by the game, "
        .. r.gated .. " kept back by a gate, " .. r.own .. " for the list"
end
-- ZeD.InventoryRenderer.liveCount (nil before the fix: the function is not there)
function X.live(inv)
    local f = ZeD.InventoryRenderer and ZeD.InventoryRenderer.liveCount
    if type(f) ~= "function" then return nil end
    local ok, n = pcall(f, inv, S.p)
    return ok and n or nil
end
-- the heading's count as the list holds it (shownCount: the list's own model), its words ("8 items") and its name
function X.shown(k, inv)
    local n = nil
    pcall(function() n = ZeD.InventoryRenderer.shownCount(X.content(k), inv, S.p) end)
    return n
end
function X.head(k)
    local c = X.content(k)
    local info = c and c._containerInfo
    return info and info.count or nil
end
function X.headName(k)
    local c = X.content(k)
    local info = c and c._containerInfo
    return info and info.name or nil
end
function X.wantHead(k, n)
    if n == nil then return nil end
    if n == 0 then return "" end
    local one, many = "UI_ZeD_Char_ItemsOne", "UI_ZeD_Char_ItemsMany"
    if k == "w" then one, many = "UI_ZeD_Inv_ItemsOne", "UI_ZeD_Inv_ItemsMany" end
    local s = nil
    pcall(function() s = ZeD.tr(n == 1 and one or many, n) end)
    return s
end
-- the list shows inv with its side down, 20 frames in a row (S.drawn cleared first)
function X.listDrawn(k, inv)
    local w, c = X.win(k), X.content(k)
    local on = w ~= nil and not w._rolled and c ~= nil and c:isVisible() and inv ~= nil and c._inventory == inv
    if on then S.drawn = S.drawn + 1 else S.drawn = 0 end
    return S.drawn >= 20
end

-- ===================================================================== the Character list's view
function X.idxOf(w, inv)
    if inv == nil then return nil end
    for i, e in ipairs((w and w._containers) or {}) do if e.inventory == inv then return i end end
    return nil
end
function X.invName(w, inv)
    if inv == nil then return "nothing" end
    local i = X.idxOf(w, inv)
    return i and tostring(w._containers[i].name) or "a container off its strip"
end
-- the viewed and the active container (by their inventories) and the list's own inventory
function X.viewOf(w)
    local v = {}
    pcall(function()
        local L = w._containers or {}
        local vi = w._viewedContainer
        v.vInv = (vi and L[vi]) and L[vi].inventory or nil
        v.aInv = L[w._activeContainer] and L[w._activeContainer].inventory or nil
        v.cInv = w._mainContent and w._mainContent._inventory or nil
        v.mainVis = w._mainVisible
    end)
    return v
end
function X.sameView(w, v)
    if not (w and v) then return false end
    local now = X.viewOf(w)
    return now.vInv == v.vInv and now.aInv == v.aInv and now.cInv == v.cInv
end
-- the list put on view v (a bag found again by its inventory: the strip's list is rebuilt every half second);
-- nothing moves when it is there already
function X.viewTo(w, v)
    if not (w and v) or X.sameView(w, v) then return end
    w._viewedContainer = X.idxOf(w, v.vInv)
    w._activeContainer = X.idxOf(w, v.aInv) or 1
    if v.mainVis ~= nil then w._mainVisible = v.mainVis end
    local c = w._mainContent
    if c then
        local e = w._containers and w._containers[w._viewedContainer or w._activeContainer]
        c._inventory = (e and e.inventory) or v.cInv
        c._selectedItems = {}
        c._lastClickedItem = nil
    end
end
function X.viewMain(w)
    S.viewTouched = true
    X.viewTo(w, { aInv = S.main, cInv = S.main, mainVis = true })
end

-- ===================================================================== the bag (B)
-- the strip's bag to pick: a real bag before a key ring, the one with the most things in it
function X.bagIdx(w)
    local best, bestS = nil, -1
    for i, e in ipairs((w and w._containers) or {}) do
        if not e.isMain and e.inventory then
            local s = 0
            pcall(function() s = e.inventory:getItems():size() end)
            pcall(function()
                local it = e.inventory:getContainingItem()
                if it and it:getCategory() == "Container" then s = s + 1000 end
            end)
            if s > bestS then best, bestS = i, s end
        end
    end
    return best
end
-- a bag's button on the Character strip pressed and let go at its middle (the strip's own mouse handlers read the
-- zone from the x, y given: vx_windows.lua X.clickBag); not pressed when another zone is first under that point (a
-- button half scrolled under the sort row would press the sort)
function X.clickBag(w, idx)
    local strip = w and w._containerStrip
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == "cnt:" .. idx then
            local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
            local hit = nil
            pcall(function() hit = strip:hitZoneAt(x, y) end)
            if not (hit and hit.id == z.id) then return false end
            S.viewTouched = true
            pcall(strip.onMouseDown, strip, x, y)
            pcall(strip.onMouseUp, strip, x, y)
            return true
        end
    end
    return false
end
-- no bag on the strip: a school bag given and worn where that place is free, else held in a free second hand
-- (vx_windows.lua W8); says how
function X.giveBag()
    local bag = X.track(RT.give("Base.Bag_Schoolbag"))
    if not bag then return "a school bag could not be given" end
    S.b.given = bag
    local loc = nil
    pcall(function() loc = bag:getBodyLocation() end)
    if loc == nil or tostring(loc) == "" then pcall(function() loc = bag:canBeEquipped() end) end
    local free = false
    pcall(function() free = loc ~= nil and tostring(loc) ~= "" and S.p:getWornItem(loc) == nil end)
    if free then
        pcall(function() S.p:setWornItem(loc, bag) end)
        return "a school bag given and worn"
    end
    if S.p:getSecondaryHandItem() == nil then
        pcall(function() S.p:setSecondaryHandItem(bag) end)
        return "a school bag given and held in the second hand"
    end
    return "a school bag given, but his back and his second hand are taken"
end

-- ===================================================================== things made
function X.track(it)
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        S.made[#S.made + 1] = it
    end
    return it
end
function X.addFloor(sq, ft, ox, oy)
    local it = nil
    pcall(function() it = sq:AddWorldInventoryItem(ft, ox, oy, 0) end)
    return X.track(it)
end
-- the container a thing is really in: its link, when that container's own list holds it (vx_inventory.lua H.where)
function X.where(it)
    local c = nil
    pcall(function() c = it:getContainer() end)
    if c == nil then return nil end
    local inList = true
    pcall(function() inList = c:getItems():contains(it) end)
    if not inList then return nil end
    return c
end
-- on the ground: its ground object still on a square (vx_inventory.lua H.onFloor)
function X.onFloor(it)
    local on = false
    pcall(function()
        local wo = it:getWorldItem()
        local sq = wo and wo:getSquare()
        on = sq ~= nil and sq:getWorldObjects():contains(wo)
    end)
    return on and true or false
end
-- a thing off the character and out of the world, wherever it is (vx_inventory.lua H.removeItem)
function X.removeItem(it)
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
function X.nm(it) local n = nil; pcall(function() n = it:getDisplayName() end); return tostring(n or it) end
-- (A) the bandage taken out of his inventory again, and off the kit's list of things given
function X.takeOut(it)
    if not it then return end
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    pcall(function() if it:getContainer() ~= nil then it:setContainer(nil) end end)
    for i = #RT.given, 1, -1 do if RT.given[i] == it then table.remove(RT.given, i) end end
end

-- ===================================================================== the gate (C)
-- a gate for one container only, as a gate mod registers one (ZeD.ContainerGates.add): it keeps back the thing whose
-- id is hideId; every other container answers nil (no gate). Off: it answers nil and leaves the list of gates.
function X.gateOn(inv, hideId)
    local G = ZeD.ContainerGates
    if not (G and G.add) then return false end
    S.gateInv, S.gateHide, S.gateLive = inv, hideId, true
    S.gateT = { sig = 1, keep = function(item)
        local id = nil
        pcall(function() id = item:getID() end)
        return id ~= S.gateHide
    end }
    G.add(S.GATE, function(i, pl)
        if S.gateLive and i == S.gateInv then return S.gateT end
        return nil
    end)
    return true
end
function X.gateOff()
    S.gateLive = false
    local L = ZeD.ContainerGates and ZeD.ContainerGates.gates
    if not L then return end
    for i = #L, 1, -1 do if L[i] and L[i].id == S.GATE then table.remove(L, i) end end
end
function X.gateGone()
    for _, g in ipairs((ZeD.ContainerGates and ZeD.ContainerGates.gates) or {}) do if g.id == S.GATE then return false end end
    return true
end

-- ===================================================================== scroll, parts
function X.scrollOf(k) local s = nil; pcall(function() s = X.content(k)._scroll.scrollPos end); return s end
function X.scrollTo(k, pos) if pos ~= nil then pcall(function() X.content(k)._scroll:setScrollPos(pos) end) end end
-- a part that cannot go on: hard (a staging step that should work did not: a FAIL) or soft (this screen or this
-- character cannot stage it: a SKIP); said once, in place of the part's checks
function X.stop(key, why, hard)
    if not S.ok[key] then return end
    S.ok[key] = false
    S.why[key] = why
    if hard then Q.check(false, "staging, part " .. S.PART[key] .. ": " .. tostring(why))
    else Q.skip("part " .. S.PART[key], why) end
end

-- ===================================================================== the tab drawer, the roll, the tab's press (queued)
-- window k on a tab of S.TABS[k] beside whose drawer its side can roll: each tab its strip offers pressed in turn,
-- settled, and passed over when its drawer covers the list; the tab found kept in S.tab[k]; then the list drawn 20
-- frames on getInv()
function X.qTab(key, k, getInv)
    step(3, function()
        if not S.ok[key] then return end
        X.hold()
        S.try = { i = 0, cur = nil, tried = {} }
        X.nextTab(k)
        if S.try.err then X.stop(key, "the press on the " .. S.try.err, true)
        elseif not S.try.cur then X.stop(key, "the " .. X.wname(k) .. " strip offers none of " .. table.concat(S.TABS[k], ", "), false) end
    end)
    waitFor(3, 1800, function()
        if not S.ok[key] then return true end
        X.hold()
        local t = S.try
        if not (t and t.cur) then return true end
        if not X.settled(k, t.cur) then return false end
        if X.canRoll(X.win(k)) then return true end
        local c = X.content(k)
        t.tried[#t.tried + 1] = t.cur .. ((c and c:isVisible()) and " (the side cannot roll there)" or " (its drawer covers the list)")
        X.nextTab(k)
        return t.cur == nil
    end, function(ok)
        if not S.ok[key] then return end
        local t, w = S.try, X.win(k)
        if t.cur and w and w._activeTab == t.cur and X.canRoll(w) then
            S.tab[k] = t.cur
            S.drawn = 0
            return
        end
        if t.err then
            X.stop(key, "the press on the " .. t.err, true)
        elseif t.cur then
            X.stop(key, "the " .. t.cur .. " tab did not open and settle (the " .. X.wname(k) .. " window is on " .. tostring(w and w._activeTab) .. ")", true)
        else
            X.stop(key, "the " .. X.wname(k) .. " window's side cannot roll beside any of its tabs on this screen: " .. table.concat(t.tried, "; "), false)
        end
    end)
    waitFor(1, 300, function() return not S.ok[key] or X.listDrawn(k, getInv()) end, function(ok)
        if S.ok[key] and not ok then
            X.stop(key, "the " .. X.wname(k) .. " list did not show " .. X.invName(X.win(k), getInv()) .. " beside the " .. tostring(S.tab[k]) .. " drawer", true)
        end
    end)
end
-- window k's side rolled away under its tab: the curtain's own roll inside the window's update, then its tab at
-- rest at the title bar with its label drawn afresh (the label and the tab's rect cleared at the roll)
function X.qRoll(key, k)
    step(2, function()
        if not S.ok[key] then return end
        local w = X.win(k)
        if not X.canRoll(w) then
            X.stop(key, "the " .. X.wname(k) .. " window's side cannot roll beside its " .. tostring(w and w._activeTab) .. " drawer on this screen", false)
            return
        end
        X.hold()
        X.via(w, function(self)
            C.roll(self)
            local rod = self._rod
            if rod then rod._label, rod._chip = nil, nil end
        end)
    end)
    waitFor(2, 400, function()
        if not S.ok[key] then return true end
        X.hold()
        local w = X.win(k)
        return w ~= nil and w._qaPressDone == true and X.atRest(w)
    end, function(ok)
        if not S.ok[key] or ok then return end
        local w = X.win(k)
        local rod = w and w._rod
        X.stop(key, "the " .. X.wname(k) .. " window's side did not roll away under its tab (rolled " .. tostring(w and w._rolled)
            .. ", the tab " .. (rod and (math.floor(rod._h or -1) .. " px tall going to " .. math.floor(rod._target or -1) .. " px") or "not made")
            .. (S.pressErr and (", error " .. S.pressErr) or "") .. ")", true)
    end)
end
-- the side brought down by its tab: the rod's own press and release on the middle of its label, inside the rod's
-- update; then the list drawn 20 frames on getInv()
function X.qUnroll(key, k, getInv)
    step(3, function()
        if not S.ok[key] then return end
        local w = X.win(k)
        local rod = w and w._rod
        local r = rod and rod._chip
        S.unrollHow = "its tab pressed"
        if not (w and w._rolled and rod and r and rod:isVisible()) then
            S.unrollHow = "ZeD.Curtain.unroll (the tab was not on screen to press)"
            if w and w._rolled then pcall(C.unroll, w) end
            return
        end
        local x, y = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
        if X.inRect(rod._closeRect, x, y) or X.inRect(rod._pinRect, x, y) then
            S.unrollHow = "ZeD.Curtain.unroll (the label's middle is on the close box or the pin)"
            pcall(C.unroll, w)
            return
        end
        X.via(rod, function(self) self:onMouseDown(x, y); self:onMouseUp(x, y) end)
    end)
    waitFor(2, 600, function()
        if not S.ok[key] then return true end
        X.hold()
        local w = X.win(k)
        return w ~= nil and not w._rolled
    end, function(ok)
        if not S.ok[key] then return end
        if not ok then
            X.stop(key, "the " .. X.wname(k) .. " window's side did not come down (" .. tostring(S.unrollHow) .. (S.pressErr and (", error " .. S.pressErr) or "") .. ")", true)
            return
        end
        S.drawn = 0
    end)
    waitFor(1, 300, function() return not S.ok[key] or X.listDrawn(k, getInv()) end, function(ok)
        if S.ok[key] and not ok then X.stop(key, "the " .. X.wname(k) .. " list did not draw its container again after the side came down", true) end
    end)
end
-- (rolled down again) the list shows the container the tab named, its heading at what the tab said: the heading's
-- name, its words ("N items") and shownCount
function X.downCheck(k, inv, lab, what)
    local tn, n = X.parse(lab)
    local head, shown, hn = X.head(k), X.shown(k, inv), X.headName(k)
    local want = X.wantHead(k, n)
    Q.check(n ~= nil and shown == n and head ~= nil and head == want and hn ~= nil and hn == tn, what,
        "the tab said [" .. tostring(lab) .. "]; rolled down, the list shows [" .. tostring(hn) .. "], its heading [" .. tostring(head)
        .. "] (shownCount " .. tostring(shown) .. "), want [" .. tostring(want) .. "]; the side came down by " .. tostring(S.unrollHow))
end

-- ===================================================================== the scene
step(2, function()
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then S.dead = true; Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    S.main = S.p:getInventory()
    S.pairWas, S.worldWas = RT.isOpen(), X.worldOpen()
    local md = S.p:getModData()
    S.winState0 = { had = md.ZeD_WinState ~= nil, v = X.copy(md.ZeD_WinState) }
    S.r0 = X.counts(S.main)
    X.openBoth()
end)
waitFor(5, 300, X.bothOpen, function(ok)
    if not ok then
        S.dead = true
        Q.check(false, "the scene: both windows open", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(X.worldOpen()))
        return
    end
    local cw, ww = RT.cw(), RT.ww()
    S.tab0 = { c = cw._activeTab or "loot", w = ww._activeTab or "loot" }
    S.out0 = { c = cw._outSince, w = ww._outSince }
    S.rolled0 = { c = cw._rolled and true or false, w = ww._rolled and true or false }
    S.hand0 = { c = X.handOf(cw), w = X.handOf(ww) }
    S.geoF = { c = X.geo(cw), w = X.geo(ww) }
    S.view0 = X.viewOf(cw)
    S.scroll0 = { c = X.scrollOf("c"), w = X.scrollOf("w") }
    X.keepScroll("c", S.tab0.c)
    X.keepScroll("w", S.tab0.w)
    X.hold()
    -- (a side found rolled comes down for the checks; it is rolled again at the end, the way it was rolled)
    if S.rolled0.c then pcall(C.finishUnroll, cw) end
    if S.rolled0.w then pcall(C.finishUnroll, ww) end
    S.geo0 = { c = X.geo(cw), w = X.geo(ww) }
    -- (a window rolled up to its title bar shows no list; Loot columns would close at a tab press, and they could not
    -- be put back: that window's parts are not staged)
    local mcC, mcW = #(cw._mcSelected or {}), #(ww._mcSelected or {})
    if cw.windowShaded or mcC > 0 then
        local why = cw.windowShaded and "the Character window is rolled up to its title bar"
            or ("the Character window has " .. mcC .. " Loot column(s) open: a tab press would close them, and they could not be put back")
        X.stop("A", why, false)
        X.stop("B", why, false)
    end
    if ww.windowShaded or mcW > 0 then
        X.stop("C", ww.windowShaded and "the World window is rolled up to its title bar"
            or ("the World window has " .. mcW .. " Loot column(s) open: a tab press would close them, and they could not be put back"), false)
    end
    Q.say("scene: Character " .. X.gs(S.geoF.c) .. " on " .. tostring(S.tab0.c) .. ", World " .. X.gs(S.geoF.w) .. " on " .. tostring(S.tab0.w)
        .. ", screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", sides rolled " .. tostring(S.rolled0.c) .. "/" .. tostring(S.rolled0.w)
        .. "; his inventory, " .. X.cs(S.r0) .. "; the pair was " .. ((S.pairWas and S.worldWas) and "open" or "shut"))
end)

-- ===================================================================== A. his own inventory's tab
step(10, function()
    if not S.ok.A then return end
    X.hold()
    X.viewMain(RT.cw())   -- (his own inventory on the list; the view found goes back at the end)
end)
X.qTab("A", "c", function() return S.main end)
step(1, function()
    if not S.ok.A then return end
    S.a.head0, S.a.shown0, S.a.r0 = X.head("c"), X.shown("c", S.main), X.counts(S.main)
    Q.say("A: on " .. tostring(S.tab.c) .. ", the side down, the heading reads [" .. tostring(S.a.head0) .. "] (shownCount " .. tostring(S.a.shown0) .. "); "
        .. X.cs(S.a.r0) .. ((S.try and #S.try.tried > 0) and ("; passed over: " .. table.concat(S.try.tried, "; ")) or ""))
end)
X.qRoll("A", "c")
step(4, function()
    if not S.ok.A then return end
    local cw = RT.cw()
    local lab = X.label(cw)
    local n = X.tabN(cw)
    local r = X.counts(S.main)
    local live = X.live(S.main)
    -- (the name the tab gives his own inventory: the game's word, as the list's first entry has it)
    local nm = getText("IGUI_InventoryTooltip")
    S.a.n1, S.a.lab1 = n, lab
    -- (nothing worn, held, hidden or kept back: the raw count is the list's, and old and new read alike)
    S.a.diff = r.raw ~= r.own
    S.a.same = "nothing in his inventory is worn, held, hidden or kept back here (" .. X.cs(r) .. "): the old count and the new are the same"
    Q.check(lab == X.lab(nm, r.own) and live == r.own and S.a.shown0 == r.own,
        "A: his inventory rolled away on " .. tostring(S.tab.c) .. ": the tab reads the count the list shows (old code: the raw count, worn things and bags in)",
        "the tab [" .. tostring(lab) .. "], want [" .. X.lab(nm, r.own) .. "]; liveCount " .. tostring(live) .. "; before the roll the heading read ["
        .. tostring(S.a.head0) .. "] (shownCount " .. tostring(S.a.shown0) .. "); " .. X.cs(r))
    if S.a.diff then
        local help, want = X.help(cw), X.wantHelp(nm, r.own)
        Q.check(help ~= nil and help == want, "A: the tab's help line gives the same count (old code: the raw count)",
            "[" .. tostring(help) .. "], want [" .. tostring(want) .. "]")
    else
        Q.skip("A: the tab's help line gives the same count", S.a.same)
    end
    if r.worn > 0 then
        Q.check(n ~= nil and n < r.raw and n == r.raw - r.worn - r.hidden - r.gated,
            "A: what he wears and holds is left out of the tab's count (old code: the tab gave inv:getItems():size(), " .. r.raw .. ")",
            "the tab " .. tostring(n) .. "; inv:getItems():size() " .. r.raw .. ", of them " .. r.worn .. " worn or held, " .. r.hidden .. " hidden by the game")
    else
        Q.skip("A: what he wears and holds is left out of the tab's count",
            "he wears and holds nothing in his main inventory here (" .. X.cs(r) .. "): the old count and the new are the same")
    end
end)
-- a bandage put in while the side is rolled, then taken out: the tab follows at once (the list does not draw while
-- rolled, so a count read from its model would stand still)
step(2, function()
    if not S.ok.A then return end
    X.hold()
    S.a.one = X.track(RT.give("Base.Bandage"))
    S.a.want2 = X.counts(S.main).own
    if not S.a.one then X.stop("A", "a bandage could not be put in his inventory", true) end
end)
waitFor(1, 120, function() return not S.ok.A or X.tabN(RT.cw()) == S.a.want2 end, function(ok)
    if not S.ok.A then return end
    local cw = RT.cw()
    local n, r, live = X.tabN(cw), X.counts(S.main), X.live(S.main)
    Q.check(ok and cw._rolled == true and n == r.own and S.a.n1 ~= nil and n == S.a.n1 + 1 and live == r.own,
        "A: still rolled away, a bandage put in his inventory: the tab goes up by one at once, to the list's count (old code: up from the raw count)",
        "the tab " .. tostring(S.a.n1) .. " -> [" .. tostring(X.label(cw)) .. "]; liveCount " .. tostring(live) .. "; " .. X.cs(r))
    X.takeOut(S.a.one)
    S.a.want3 = X.counts(S.main).own
end)
waitFor(1, 120, function() return not S.ok.A or X.tabN(RT.cw()) == S.a.want3 end, function(ok)
    if not S.ok.A then return end
    local cw = RT.cw()
    local n, r, live = X.tabN(cw), X.counts(S.main), X.live(S.main)
    Q.check(ok and cw._rolled == true and n == r.own and n == S.a.n1 and live == r.own and X.where(S.a.one) == nil,
        "A: the bandage taken out again: the tab goes back down at once (old code: back to the raw count)",
        "the tab [" .. tostring(X.label(cw)) .. "], it read " .. tostring(S.a.n1) .. " before the bandage; liveCount " .. tostring(live) .. "; " .. X.cs(r))
end)
X.qUnroll("A", "c", function() return S.main end)
step(1, function()
    if not S.ok.A then return end
    if not S.a.diff then Q.skip("A: rolled down again, the list's heading counts what the tab said", S.a.same); return end
    X.downCheck("c", S.main, S.a.lab1,
        "A: rolled down again, the list shows his inventory and its heading counts what the tab said (old code: the tab said more than the heading)")
end)

-- ===================================================================== B. a bag picked with the mouse on a tab
step(5, function()
    if not S.ok.B then return end
    if not S.tab.c then X.stop("B", "no tab to stage it on (part A: " .. tostring(S.why.A) .. ")", false); return end
    X.hold()
    local cw = RT.cw()
    if cw._rolled then pcall(C.finishUnroll, cw) end
    if X.bagIdx(cw) then S.b.how = "a bag he carries"; return end
    S.b.how = X.giveBag()
    pcall(function() cw._containerTimer = 30 end)   -- (the strip reads its bags afresh on its next frame)
end)
waitFor(2, 240, function() return not S.ok.B or X.bagIdx(RT.cw()) ~= nil end, function(ok)
    if not S.ok.B then return end
    local cw = RT.cw()
    local i = X.bagIdx(cw)
    if not i then X.stop("B", "no bag could be put on the Character strip (" .. tostring(S.b.how) .. ")", false); return end
    S.b.inv, S.b.name = cw._containers[i].inventory, cw._containers[i].name
    -- (the list on his own inventory first: a press on the bag the list already shows would shut the list)
    X.viewMain(cw)
    S.st = {}
    X.press("c", S.tab.c)
end)
waitFor(2, 600, function() return not S.ok.B or X.settled("c", S.tab.c) end, function(ok)
    if not S.ok.B then return end
    local cw = RT.cw()
    if not ok then X.stop("B", "the " .. S.tab.c .. " tab did not open (the window is on " .. tostring(cw._activeTab) .. ")", true); return end
    if not X.canRoll(cw) then X.stop("B", "the inventory side cannot roll beside the " .. S.tab.c .. " drawer on this screen", false); return end
    -- (the strip's list is rebuilt every half second: the bag found again by its inventory)
    local i = X.idxOf(cw, S.b.inv)
    S.b.pressed = i ~= nil and X.clickBag(cw, i)
    if not S.b.pressed then
        X.stop("B", "the bag's button is not on the strip to press (" .. (i and "scrolled out of view" or "the bag left the strip") .. ")", false)
        return
    end
    S.drawn = 0
end)
waitFor(2, 300, function() return not S.ok.B or X.listDrawn("c", S.b.inv) end, function(ok)
    if not S.ok.B then return end
    local cw = RT.cw()
    if not ok then
        X.stop("B", "the list did not show " .. tostring(S.b.name) .. " after its button was pressed (viewed container " .. tostring(cw._viewedContainer) .. ")", true)
        return
    end
    -- (the finding's case: the press views the bag alone, the window's active container stays his inventory)
    local v = X.viewOf(cw)
    if not (v.vInv == S.b.inv and v.aInv == S.main) then
        X.stop("B", "the press on " .. tostring(S.b.name) .. "'s button did not view it alone (the viewed container " .. X.invName(cw, v.vInv)
            .. ", the active one " .. X.invName(cw, v.aInv) .. ")", true)
        return
    end
    S.b.head0, S.b.shown0 = X.head("c"), X.shown("c", S.b.inv)
    Q.say("B: " .. tostring(S.b.how) .. ", " .. tostring(S.b.name) .. ", its button pressed on the strip on " .. S.tab.c .. ": the list shows it, the heading reads ["
        .. tostring(S.b.head0) .. "]; the window's active container is still his inventory (the press set only the viewed one)")
end)
X.qRoll("B", "c")
step(4, function()
    if not S.ok.B then return end
    local cw = RT.cw()
    local lab = X.label(cw)
    local r = X.counts(S.b.inv)
    local live = X.live(S.b.inv)
    local drop = X.drop(cw)
    local same = drop ~= nil and drop == S.b.inv
    S.b.lab1 = lab
    Q.check(lab == X.lab(S.b.name, r.own) and live == r.own and S.b.shown0 == r.own and same,
        "B: " .. tostring(S.b.name) .. " picked with the mouse on " .. S.tab.c .. ", then rolled away: the tab names that bag and counts its things, and a drop on the tab goes into the same bag (old code: the tab said Inventory over the bag's count while a drop went into the bag)",
        "the tab [" .. tostring(lab) .. "], want [" .. X.lab(S.b.name, r.own) .. "]; liveCount " .. tostring(live) .. "; before the roll the heading read ["
        .. tostring(S.b.head0) .. "] (shownCount " .. tostring(S.b.shown0) .. "); " .. X.cs(r) .. "; a drop on the tab goes into "
        .. X.invName(cw, drop) .. (same and " (the bag)" or " (not the bag)"))
    local help, want = X.help(cw), X.wantHelp(S.b.name, r.own)
    Q.check(help ~= nil and help == want, "B: the tab's help line names the bag and gives its count (old code: Inventory)",
        "[" .. tostring(help) .. "], want [" .. tostring(want) .. "]")
end)
X.qUnroll("B", "c", function() return S.b.inv end)
step(1, function()
    if not S.ok.B then return end
    X.downCheck("c", S.b.inv, S.b.lab1,
        "B: rolled down again, the list shows the bag the tab named and its heading counts what the tab said (old code: the tab named Inventory over the bag)")
    pcall(X.viewTo, RT.cw(), S.view0)   -- (the list back on what it showed when the run began)
end)

-- ===================================================================== C. the World window's tab
-- (the list on the floor: the active container, no container viewed over it from another tab)
step(10, function()
    if not S.ok.C then return end
    X.hold()
    local ww = RT.ww()
    local e = ww._containers and ww._containers[ww._activeContainer]
    if not (e and e.isFloor) then
        X.stop("C", "the World window's list is on " .. tostring(e and e.name) .. ", not the floor, so the things at his feet are not its list", false)
        return
    end
    local vi = ww._viewedContainer
    if vi and vi ~= ww._activeContainer then
        X.stop("C", "the World window's list shows " .. tostring(ww._containers[vi] and ww._containers[vi].name) .. ", picked on another tab, not the floor", false)
        return
    end
    S.c.inv, S.c.name = e.inventory, e.name
end)
-- (the tab first: its strip, drawn beside the list, reads the ground the things are made on)
X.qTab("C", "w", function() return S.c.inv end)
step(2, function()
    if not S.ok.C then return end
    X.hold()
    local sq = S.p:getCurrentSquare()
    if not sq then X.stop("C", "he stands on no square", false); return end
    S.c.items = {}
    local kinds = { "Base.Bandage", "Base.Twine", "Base.Hammer" }
    for i = 1, 3 do
        local it = X.addFloor(sq, kinds[i], 0.2 + 0.25 * i, 0.5)
        if it then S.c.items[#S.c.items + 1] = it end
    end
    if #S.c.items < 3 then X.stop("C", "three things could not be made on the ground at his feet (" .. #S.c.items .. " made)", true); return end
    pcall(function() S.c.hideId = S.c.items[3]:getID() end)
    pcall(function() RT.ww()._containerTimer = 30 end)   -- (the World list reads the ground afresh on its next frame)
end)
waitFor(2, 300, function()
    if not S.ok.C then return true end
    X.hold()
    for _, it in ipairs(S.c.items) do
        local has = false
        pcall(function() has = S.c.inv:containsID(it:getID()) end)
        if not has then return false end
    end
    return true
end, function(ok)
    if not S.ok.C then return end
    if not ok then X.stop("C", "the floor list did not take in the three things at his feet", true); return end
    if not X.gateOn(S.c.inv, S.c.hideId) then X.stop("C", "ZeD.ContainerGates.add is not there", true); return end
    local g = nil
    pcall(function() g = ZeD.ContainerGates.get(S.c.inv, S.p) end)
    if g ~= S.gateT then X.stop("C", "another gate answers for the floor list before the test's", false); return end
    S.drawn = 0
end)
-- (the list drawn again with the gate: its model is built afresh when a gate's signature changes)
waitFor(1, 300, function() return not S.ok.C or X.listDrawn("w", S.c.inv) end, function(ok)
    if not S.ok.C then return end
    if not ok then X.stop("C", "the World list did not show the floor beside the " .. tostring(S.tab.w) .. " drawer", true); return end
    local r = X.counts(S.c.inv)
    S.c.head0, S.c.shown0 = X.head("w"), X.shown("w", S.c.inv)
    -- (the gate is the list's as well: its heading already leaves the hammer out, as a gate mod's list does)
    if not (r.gated == 1 and S.c.shown0 == r.own) then
        X.stop("C", "the gate did not take on the floor list: its heading counts " .. tostring(S.c.shown0) .. " (" .. X.cs(r) .. ")", true)
        return
    end
    Q.say("C: on " .. tostring(S.tab.w) .. ", the side down, the floor's heading reads [" .. tostring(S.c.head0) .. "]; " .. X.cs(r)
        .. ((S.try and #S.try.tried > 0) and ("; passed over: " .. table.concat(S.try.tried, "; ")) or ""))
end)
X.qRoll("C", "w")
step(4, function()
    if not S.ok.C then return end
    local ww = RT.ww()
    local lab = X.label(ww)
    local r = X.counts(S.c.inv)
    local live = X.live(S.c.inv)
    S.c.lab1 = lab
    Q.check(lab == X.lab(S.c.name, r.own) and live == r.own and S.c.shown0 == r.own and r.gated == 1,
        "C: the World window's side rolled away on " .. tostring(S.tab.w) .. ": the floor's tab counts what its list shows, not the thing a gate keeps back (old code: the raw count, that thing in)",
        "the tab [" .. tostring(lab) .. "], want [" .. X.lab(S.c.name, r.own) .. "]; liveCount " .. tostring(live) .. "; before the roll the heading read ["
        .. tostring(S.c.head0) .. "]; " .. X.cs(r))
    local help, want = X.help(ww), X.wantHelp(S.c.name, r.own)
    Q.check(help ~= nil and help == want, "C: the World tab's help line gives the same count (old code: the raw count)",
        "[" .. tostring(help) .. "], want [" .. tostring(want) .. "]")
end)
X.qUnroll("C", "w", function() return S.c.inv end)
step(1, function()
    if not S.ok.C then return end
    X.downCheck("w", S.c.inv, S.c.lab1, "C: rolled down again, the floor's heading counts what the tab said (old code: the tab said one more)")
end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    X.unvia()
    X.hold()
    for _, k in ipairs({ "c", "w" }) do
        local w = X.win(k)
        if w and w._rolled then pcall(C.finishUnroll, w) end
    end
    X.gateOff()
    -- the bag given for B (if one was) off his back and out of his hand; then everything made, wherever it is
    local bag = S.b.given
    if bag then
        pcall(function() S.p:removeWornItem(bag) end)
        pcall(function() if S.p:getSecondaryHandItem() == bag then S.p:setSecondaryHandItem(nil) end end)
    end
    for _, it in ipairs(S.made) do pcall(X.removeItem, it) end
    if S.view0 and S.viewTouched then pcall(X.viewTo, RT.cw(), S.view0) end
    pcall(function() local w = RT.cw(); if w then w._containerTimer = 30 end end)
    pcall(function() local w = RT.ww(); if w then w._containerTimer = 30 end end)
end)
Q.step(3, function()
    if not (S.tab0 and X.bothOpen()) then return end
    S.st = {}
    X.press("c", S.tab0.c)
    X.press("w", S.tab0.w)
end)
waitFor(3, 600, function()
    if not (S.tab0 and X.bothOpen()) then return true end
    X.hold()
    local okC = X.settled("c", S.tab0.c)   -- (both counted every frame)
    local okW = X.settled("w", S.tab0.w)
    return okC and okW
end, function(ok)
    if not (S.tab0 and X.bothOpen()) then return end
    -- the view again (a bag's place on the strip may have moved at its rebuild), the lists' and the tabs' scroll
    if S.viewTouched then pcall(X.viewTo, RT.cw(), S.view0) end
    X.scrollTo("c", S.scroll0 and S.scroll0.c)
    X.scrollTo("w", S.scroll0 and S.scroll0.w)
    X.tabScrollBack()
    -- the places and sizes, the sides down: the tab presses bring them back; a window they did not is set back by its
    -- own setters (never ZEDQA_LAYOUT_BACK here: its reset re-saves the windows' accents, and ModOptions.ini with them)
    for _, k in ipairs({ "c", "w" }) do
        local w = X.win(k)
        if w and S.geo0 and not X.sameGeo(X.geo(w), S.geo0[k]) then
            S.placed = (S.placed and (S.placed .. "; ") or "") .. X.wname(k) .. " at " .. X.gs(X.geo(w))
            X.placeBack(w, S.geo0[k])
        end
    end
    -- a side found rolled, rolled again (by the curtain's own roll inside the window's update)
    for _, k in ipairs({ "c", "w" }) do
        local w = X.win(k)
        if S.rolled0[k] and w and not w._rolled and X.canRoll(w) then X.via(w, function(self) C.roll(self) end) end
    end
end, true)
-- (a side rolled again rolls in its window's next update)
waitFor(2, 120, function()
    if not (S.rolled0 and X.bothOpen()) then return true end
    local cw, ww = RT.cw(), RT.ww()
    return (cw._rolled and true or false) == S.rolled0.c and (ww._rolled and true or false) == S.rolled0.w
end, function() end, true)
Q.step(10, function()
    X.unvia()
    local cw, ww = RT.cw(), RT.ww()
    -- a side rolled again: rolled the way it was found (the halves tell a hand roll from the pointer's timer); then the
    -- roll timers as found
    for _, k in ipairs({ "c", "w" }) do
        local w = X.win(k)
        if w and S.rolled0 and S.rolled0[k] and w._rolled then pcall(function() w._halves.inv.hand = S.hand0[k] and true or false end) end
    end
    if cw and S.out0 then cw._outSince = S.out0.c end
    if ww and S.out0 then ww._outSince = S.out0.w end
    RT.takeBack()
    if S.tab0 and cw and ww and X.bothOpen() then
        local view = X.sameView(cw, S.view0)
        Q.check(cw._activeTab == S.tab0.c and ww._activeTab == S.tab0.w and (cw._rolled and true or false) == S.rolled0.c
            and (ww._rolled and true or false) == S.rolled0.w and view,
            "put back: both windows on the tabs they were on, their sides as found, the Character list on what it showed",
            "Character on " .. tostring(cw._activeTab) .. " (was " .. tostring(S.tab0.c) .. "), side rolled " .. tostring(cw._rolled) .. "; World on "
            .. tostring(ww._activeTab) .. " (was " .. tostring(S.tab0.w) .. "), side rolled " .. tostring(ww._rolled) .. "; the list's view as found " .. tostring(view))
        Q.check(X.sameGeo(X.geo(cw), S.geoF.c) and X.sameGeo(X.geo(ww), S.geoF.w),
            "put back: both windows where and as big as they were",
            "Character " .. X.gs(S.geoF.c) .. " -> " .. X.gs(X.geo(cw)) .. ", World " .. X.gs(S.geoF.w) .. " -> " .. X.gs(X.geo(ww))
            .. (S.placed and (" (the tab presses left " .. S.placed .. ": set back by the window's own setters)") or ""))
    end
    local left = {}
    for _, it in ipairs(S.made) do
        local c, fl = X.where(it), X.onFloor(it)
        if c ~= nil or fl then left[#left + 1] = X.nm(it) .. (fl and " on the ground" or " in a container") end
    end
    if S.r0 then
        local r = X.counts(S.main)
        Q.check(#left == 0 and r.raw == S.r0.raw and r.worn == S.r0.worn and X.gateGone() and not S.gateLive,
            "put back: nothing the test made is left, he carries and wears what he did, the test's gate is gone",
            #left .. " of " .. #S.made .. " made things left" .. ((#left > 0) and (": " .. table.concat(left, "; ")) or "") .. "; his inventory "
            .. S.r0.raw .. " -> " .. r.raw .. " things, worn or held " .. S.r0.worn .. " -> " .. r.worn .. "; the gate gone " .. tostring(X.gateGone()))
    end
end)
Q.step(5, function()
    if S.pairWas == false and S.worldWas == false then
        if RT.isOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
        if X.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
    elseif S.pairWas == false then
        if RT.isOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
    elseif S.worldWas == false then
        if X.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
    end
end)
waitFor(5, 300, function()
    return (S.pairWas ~= false or not RT.isOpen()) and (S.worldWas ~= false or not X.worldOpen())
end, function(ok)
    if not (S.pairWas == false or S.worldWas == false) then return end
    -- shut as found: the layout the character keeps, as it was
    pcall(function()
        local md = S.p:getModData()
        if S.winState0 and S.winState0.had then md.ZeD_WinState = X.copy(S.winState0.v)
        elseif S.winState0 then md.ZeD_WinState = nil end
    end)
    Q.check(ok, "put back: the windows shut as found", "Character open " .. tostring(RT.isOpen()) .. ", World open " .. tostring(X.worldOpen()))
end, true)
Q.start()
