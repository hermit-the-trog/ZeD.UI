-- ZeDUI/tools/qa/vx11_world_tab.lua  (Nov 21 2026, QA batch 11; tag vx11_wtab): the in-game proof of Build's fix for
-- B11-3, the World window's tucked-away tab (commit 0ae4ee2a1, ZeD_WorldWindow.lua's curtain spec: its chip and its
-- dropInv index win._containers[win._viewedContainer or win._activeContainer], and dropInv gives nil for a container
-- other than the floor that ZeD_WorldWindow.inReach no longer finds). Finding: ZeDUI/qa/audits/2026-11-21_beast_batch11.md.
-- The World window's twin of vx10_tab.lua part B, built from its staging and its put-back. Built on rt_kit.lua (the
-- global RT), run after zedqa_prelude.lua. grep "ZEDQA vx11_wtab". Manifest line: vx11_world_tab.lua | vx11_wtab | timeout=300
--
-- The finding: the World list on Ground, a tab pressed (Maps), the crate's button clicked on the World strip: the list,
-- its heading and the title switch to the crate (a mouse pick on a tab other than Loot sets only _viewedContainer), but
-- the side rolled away under its tab read "Ground  N" with the ground's count, its help line "Ground, N items", and a
-- drop on the tab went to the floor. The mirror (the crate the active container, Ground viewed) named, counted and
-- filled the crate. And with the index fixed, a drop on a tab naming a crate he walked away from would fill it from afar
-- (the rolled list is frozen; the game's transfer has no distance check), so the fix refuses that drop.
--
-- What each check proves (each line says what the old code, 0ae4ee2a1~1, showed):
--   B  A crate set beside him with three things in it, the World list on Ground (the active container), the window on
--      Maps (else the next tab whose drawer leaves the list showing), the crate's button on the World strip pressed
--      and let go by the strip's own mouse handlers (the crate viewed alone, the active container still the floor), the
--      side rolled away: the tab names the crate and counts its things (the script's own count, liveCount, and the
--      heading's count just before the roll); its help line (ZeD.Curtain.tabHelp, the words the help line shows while
--      the pointer rests on the tab) names the crate with that count; a drop on the tab (the curtain's dropInv, what a
--      drop let go on the tab goes into) goes into the crate. Rolled down by the tab's own press: the list shows the
--      crate the tab named, its heading at the tab's count. Old code: the tab "Ground  N" with the ground's count, the
--      help line Ground, the drop to the floor; rolled down, the list showed the crate under a tab that had said Ground.
--   R  The reach guard, the crate still viewed and the side still rolled: he is moved two or three squares off, out of
--      the World window's reach (the 3 x 3 squares round him; ZeD_WorldWindow.inReach must answer false there, else the
--      staging failed and says so): a drop on the tab, which still names the crate (the rolled list is frozen), goes
--      nowhere (dropInv answers nil; a throw is no answer), not into the crate from afar. Back where he stood: a drop
--      on the tab goes into the crate again. Old code: the drop went to the ground both times.
--   M  The mirror: the crate made the active container the way a click on it in the world makes it
--      (ZeD_WorldWindow.selectContainer, which the game's loot page hands such a click to), then Ground's button
--      pressed on the strip (Ground viewed alone over the crate), the side rolled: the tab names Ground and counts what
--      lies in reach (two things made at his feet among whatever else is there), its help line says the same, and a
--      drop on the tab goes to the ground. Rolled down: the list shows Ground at the tab's count. Old code: the tab
--      named the crate with the crate's count, the help line the crate, and a drop went into the crate.
-- On the old code all ten B, R and M checks FAIL and the put-back checks PASS; on the fix every check PASSES.
-- Run offline before the first game run (Nov 21 2026: KRun, rt_kit.lua and this script in the game's Kahlua against a
-- stub World window cut down from ZeD_WorldWindow.lua, with the real WindowCurtain.lua; the harness is not in the repo):
-- 0ae4ee2a1's chip and dropInv PASS 13; 0ae4ee2a1~1's FAIL 10 (B 4, R 2, M 4) with the put-back's 3 PASS; the same with
-- the crate's button scrolled out of the strip's view, with the game putting him on his square only every third frame,
-- and with other things on the ground in reach. (Reviewed Nov 22 2026: the fix is in the code these runs test, so
-- today's code should PASS every check; an open card in the World drawer skips every part; R asks inReach first and
-- counts dropInv's nil only as an answer, never a throw; a paused game skips R; a button press that should work FAILs.)
--
-- How it stages: both windows open as a pair. A World window rolled up to its title bar, with Loot columns or an item
-- or object card open (a tab press or a strip click puts them away, and they could not be put back), or him seated in a
-- car (the list is then the car's) has every part skipped. The halves' roll timers are held for the run (win._outSince in the future, as bxr_win.lua and vx10_tab.lua
-- hold them), so where the real pointer rests rolls nothing; the pins are not touched. The crate (carpentry_01_16, its
-- container set explored at once, so the game fills nothing in it) stands on a free square beside him that he can reach,
-- north and west first (the strip lists the squares north to south and west to east, so its button comes early; one
-- scrolled out of the strip's view is scrolled in by the strip's own offset). The World list is put on Ground
-- (selectContainer) when it showed something else. Each tab of S.TABS opens by its own press, settles, and is passed
-- over when its drawer covers the list (a full card on a small screen: nothing beside it to roll). The side rolls by the
-- curtain's own roll inside the window's update with its onResize after (vx10_tab.lua X.via); the tab's label is read
-- once it rests at the title bar and has drawn afresh (the rod's _label, the words it draws); the side comes down by its
-- tab's own press and release, inside the rod's update. He is moved by his own setters (X, Y, Z and their last values,
-- as zedqa_prelude.lua moves him), and each check waits until the game has put him on the square. Waits are by the
-- clock (read at 60 frames a second), as vx10_tab.lua's.
-- What it puts back (also when a step throws or the time runs out): the World side down (one found rolled is rolled
-- again, the way it was rolled), him where he stood (to a hundredth of a square), the things made and the crate taken
-- away (a crate found holding something the test did not put in it is left where it is and said), the World list's view
-- (its active and its viewed container, by the container), its scroll, the strip's scroll and every pressed tab's own
-- scroll as found, the World window on the tab it was on, both windows at their places and sizes (set back by the
-- window's own setters only if the tab press did not bring it back; never ZEDQA_LAYOUT_BACK or
-- ZeD.Settings.syncWindowAccent, which save ModOptions.ini), the roll timers as found, the pair shut if it was (with the
-- layout the character keeps). No option is changed, nothing is applied or saved, no file is written.

if not (RT and RT.make) then
    print("ZEDQA vx11_wtab ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx11_wtab VERDICT FAIL 1")
    print("ZEDQA vx11_wtab DONE")
    return
end

local Q = RT.make("vx11_wtab")
Q.maxMs = 240000   -- (four minutes, then the put-back; a run takes well under one)
local C = ZeD and ZeD.Curtain
local S = { p = RT.p, pn = RT.pn, ok = { B = true, R = true, M = true }, why = {}, made = {}, st = {}, drawn = 0,
            b = {}, m = {}, cr = {}, fl = { its = {} }, tab = {}, tsc = {}, vias = {} }
S.PART = { B = "B (the crate picked with the mouse on a tab)", R = "R (the reach guard: no drop from afar)",
           M = "M (the mirror: the crate picked in the world, Ground viewed)" }
-- the tabs tried in turn, the first whose drawer leaves the list showing beside it (on a small screen a full-card
-- drawer covers the whole window, and a covered list has no side to roll)
S.TABS = { "maps", "forage", "craft", "build" }
S.CRATE_THINGS = { "Base.Hammer", "Base.Twine", "Base.Bandage" }
S.GROUND_THINGS = { "Base.Bandage", "Base.Twine" }
-- the squares tried for the crate, beside him: north and west first (the World strip lists the squares north to south
-- and west to east, so the crate's button comes early)
S.NEAR = { { 0, -1 }, { -1, 0 }, { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }
-- the squares tried for the reach guard, from where he stands: each taken only two or more squares from the crate (the
-- World window reaches the 3 x 3 squares round him)
S.AWAY = { { 0, 2 }, { 2, 0 }, { -2, 0 }, { 0, -2 }, { 2, 2 }, { -2, 2 }, { 2, -2 }, { -2, -2 }, { 0, 3 }, { 3, 0 },
           { -3, 0 }, { 0, -3 } }
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
-- (every reading asks before it indexes: in -debug a throw caught by pcall still logs a Java exception, and the runner
-- counts it, Nov 21 run 1)
function X.content() local w = RT.ww(); return w and w._mainContent or nil end
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
function X.handOf(w)
    local s = w and w._halves
    return (s and s.inv and s.inv.hand) and true or false
end
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
-- (put-back) every press whose update never ran is taken off its element, the last one first; then the mark each
-- press left on its element goes too (after the loop: two presses never run on one element share the mark)
function X.unvia()
    for i = #S.vias, 1, -1 do
        local v = S.vias[i]
        if v.el._qaPressDone == false then v.el.update = v.own end
    end
    for _, v in ipairs(S.vias) do v.el._qaPressDone = nil end
    S.vias = {}
end
-- (put-back) a window set back at a place and size by its own setters, as a player's move and resize leave it (its
-- layout reads them at rest); only for a window the tab press did not bring back
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
function X.seated() local v = nil; pcall(function() v = S.p:getVehicle() end); return v ~= nil end

-- ===================================================================== the World window's tabs
-- true once the World window is on tab id and its drawer has held one width for 15 frames (S.st cleared before a press)
function X.settled(id)
    local w = RT.ww()
    if not w then return false end
    local st = S.st
    local e = math.floor(w._drawerEffW or 0)
    if e == st.last then st.same = (st.same or 0) + 1 else st.same, st.last = 0, e end
    return w._activeTab == id and st.same >= 15
end
function X.canRoll(w)
    local cur = w and w._curtain
    if not (cur and cur.canRoll) then return false end
    local can = false
    pcall(function() can = cur.canRoll() and true or false end)
    return can
end
-- a tab's own scroll, which a press on that tab sets back to the top (as the player's press does:
-- getWorldActiveScroll); Maps keeps none. Animals and a tab another file adds (Fishing, Admin: addTab's scroll) only
-- as a tab found open (the put-back's press on it).
function X.tabScroll(id)
    local w = RT.ww()
    if not w then return nil end
    if id == "forage" then return w._forageScroll end
    if id == "craft" then return w._craftState and w._craftState.scroll or nil end
    if id == "build" then return w._buildState and w._buildState.scroll or nil end
    if id == "animals" then return w._animalsScroll end
    local ext = ZeD_WorldWindow and ZeD_WorldWindow._extTabs and ZeD_WorldWindow._extTabs[id]
    if ext and type(ext.scroll) == "function" then
        local s = nil
        pcall(function() s = ext.scroll(w) end)
        return s
    end
    return nil
end
-- kept once per tab, before the run's first press on it (the tab found open is kept at the start: the put-back's press
-- on it sets it back to the top too); every one put back at the end
function X.keepScroll(id)
    if id == nil or id == "loot" or S.tsc[id] then return end
    local pos = nil
    local sc = X.tabScroll(id)
    if sc then pcall(function() pos = sc.scrollPos end) end
    S.tsc[id] = { id = id, pos = pos }
end
function X.tabScrollBack()
    for _, t in pairs(S.tsc) do
        local sc = nil
        if t.pos ~= nil then sc = X.tabScroll(t.id) end
        if sc then pcall(function() sc:setScrollPos(t.pos) end) end
    end
end
-- the next tab of S.TABS the strip offers, pressed (S.try.cur; nil when none is left; a press that throws ends the
-- search with S.try.err)
function X.nextTab()
    local t = S.try
    local have = {}
    for _, id in ipairs(RT.tabs(RT.worldStrip())) do have[id] = true end
    t.cur = nil
    while t.i < #S.TABS and not t.err do
        t.i = t.i + 1
        local id = S.TABS[t.i]
        if have[id] then
            X.keepScroll(id)
            S.st = {}
            local okP, pressed = pcall(RT.worldTab, id)
            if not okP then t.err = id .. ": " .. tostring(pressed)
            elseif pressed then t.cur = id; return end
        end
    end
end

-- ===================================================================== the tab (the rolled side's)
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
function X.lab(name, n) return tostring(name) .. "  " .. tostring(n) end
-- the help line's words while the pointer rests on the tab (ZeD.Curtain.tabHelp), and the words wanted
function X.help(w)
    if not (w and w._curtain and C and C.tabHelp) then return nil end
    local h = nil
    pcall(function() h = C.tabHelp(w) end)
    return h
end
function X.wantHelp(name, n)
    local h = nil
    pcall(function() h = ZeD.tr(n == 1 and "UI_ZeD_Curtain_TabHelpOne" or "UI_ZeD_Curtain_TabHelp", tostring(name or ""), n) end)
    return h
end
-- what a drop let go on the tab goes into (ZeD.Curtain.dropTarget hands back the window's dropInv), and whether
-- dropInv answered at all (a nil from a throw is no refusal: R's check asks for the answer)
function X.drop(w)
    local cur = w and w._curtain
    if not (cur and cur.dropInv) then return nil, false end
    local d = nil
    local ok = pcall(function() d = cur.dropInv() end)
    return d, ok and true or false
end

-- ===================================================================== counts
-- a world container's things counted by the script itself: raw (inv:getItems():size()), hidden (the game hides them),
-- gated (a mod's gate keeps them back: ZeD.ContainerGates), own (the rest: what the list shows)
function X.counts(inv)
    local r = { raw = -1, own = 0, hidden = 0, gated = 0 }
    if not inv then return r end
    local G = ZeD.ContainerGates
    local gate = nil
    if G and G.get then pcall(function() gate = G.get(inv, S.p) end) end
    pcall(function()
        local items = inv:getItems()
        r.raw = items:size()
        for i = 0, r.raw - 1 do
            local it = items:get(i)
            if not it or it:isHidden() then r.hidden = r.hidden + 1
            elseif gate and not G.keeps(gate, it) then r.gated = r.gated + 1
            else r.own = r.own + 1 end
        end
    end)
    return r
end
function X.cs(r)
    return "inv:getItems():size() " .. r.raw .. ": " .. r.hidden .. " hidden by the game, " .. r.gated
        .. " kept back by a gate, " .. r.own .. " for the list"
end
-- ZeD.InventoryRenderer.liveCount: what the tab counts with
function X.live(inv)
    local f = ZeD.InventoryRenderer and ZeD.InventoryRenderer.liveCount
    if type(f) ~= "function" or inv == nil then return nil end
    local ok, n = pcall(f, inv, S.p)
    return ok and n or nil
end
-- the heading's count as the list holds it (shownCount: the list's own model), its words ("3 items") and its name
function X.shown(inv)
    local n = nil
    local c = X.content()
    if c and inv then pcall(function() n = ZeD.InventoryRenderer.shownCount(c, inv, S.p) end) end
    return n
end
function X.head() local c = X.content(); local info = c and c._containerInfo; return info and info.count or nil end
function X.headName() local c = X.content(); local info = c and c._containerInfo; return info and info.name or nil end
function X.wantHead(n)
    if n == nil then return nil end
    if n == 0 then return "" end
    local s = nil
    pcall(function() s = ZeD.tr(n == 1 and "UI_ZeD_Inv_ItemsOne" or "UI_ZeD_Inv_ItemsMany", n) end)
    return s
end
-- the World list shows inv with its side down, 20 frames in a row (S.drawn cleared first)
function X.listDrawn(inv)
    local w, c = RT.ww(), X.content()
    local on = w ~= nil and not w._rolled and c ~= nil and c:isVisible() and inv ~= nil and c._inventory == inv
    if on then S.drawn = S.drawn + 1 else S.drawn = 0 end
    return S.drawn >= 20
end

-- ===================================================================== the World list's view
function X.idxOf(w, inv)
    if inv == nil then return nil end
    for i, e in ipairs((w and w._containers) or {}) do if e.inventory == inv then return i end end
    return nil
end
-- the floor's place on the strip's list (the window keeps it last; Ground's button is pinned at the strip's top)
function X.floorIdx(w)
    for i, e in ipairs((w and w._containers) or {}) do if e.isFloor then return i end end
    return nil
end
function X.invName(w, inv)
    if inv == nil then return "nothing" end
    local i = X.idxOf(w, inv)
    return i and tostring(w._containers[i].name) or "a container off the strip"
end
-- the viewed and the active container (by their inventories) and the list's own inventory
function X.viewOf(w)
    local v = {}
    if not w then return v end
    local L = w._containers or {}
    local vi, ai = w._viewedContainer, w._activeContainer
    v.vInv = (vi and L[vi]) and L[vi].inventory or nil
    v.aInv = (ai and L[ai]) and L[ai].inventory or nil
    v.cInv = w._mainContent and w._mainContent._inventory or nil
    v.mainVis = w._mainVisible
    return v
end
function X.sameView(w, v)
    if not (w and v) then return false end
    local now = X.viewOf(w)
    return now.vInv == v.vInv and now.aInv == v.aInv and now.cInv == v.cInv
end
function X.vs(w)
    local v = X.viewOf(w)
    return "the viewed container " .. X.invName(w, v.vInv) .. ", the active one " .. X.invName(w, v.aInv)
end
-- (put-back) the list put on view v, each container found again by its inventory (the strip's list is rebuilt every
-- half second; a container gone falls back to the floor, as the window's own rebuild does); nothing moves when it is
-- there already
function X.viewToW(w, v)
    if not (w and v) or X.sameView(w, v) then return end
    local L = w._containers or {}
    local ai = X.idxOf(w, v.aInv) or X.floorIdx(w) or #L
    local vi = X.idxOf(w, v.vInv)
    if vi == ai then vi = nil end
    w._activeContainer = ai
    w._viewedContainer = vi
    w._viewedOver = (vi and L[ai]) and L[ai].inventory or nil
    if v.mainVis ~= nil then w._mainVisible = v.mainVis end
    local c = w._mainContent
    if c then
        local e = L[vi or ai]
        c._inventory = (e and e.inventory) or v.cInv
        c._selectedItems = {}
        c._lastClickedItem = nil
    end
end

-- ===================================================================== the World strip's buttons
-- a container's button on the World strip: its hit zone carries the container's place on the list
function X.zoneOf(w, idx)
    local strip = w and w._containerStrip
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == idx then return z end
    end
    return nil
end
-- a button's middle inside the strip's list view (the strip's own layout, win._stripLay; Ground's button is pinned
-- above the list, always in view)
function X.midInView(w, z)
    if not z then return false end
    local L = w and w._stripLay
    if not (L and L.listY and L.listH) then return true end
    if L.floorIdx ~= nil and z.id == L.floorIdx then return true end
    local my = z.y + math.floor(z.h / 2)
    return my >= L.listY and my < L.listY + L.listH
end
-- a button scrolled out of the strip's view brought into it by the strip's own offset (what its wheel moves; the draw
-- keeps it inside the list); the offset found is kept at the start and goes back at the end. true when it moved.
function X.intoView(w, idx)
    local z = X.zoneOf(w, idx)
    local L = w and w._stripLay
    if not (z and L and L.listY and L.listH) or X.midInView(w, z) then return false end
    local my = z.y + math.floor(z.h / 2)
    w._stripScrollOffset = (w._stripScrollOffset or 0) + (my - (L.listY + math.floor(L.listH / 2)))
    return true
end
-- a button on the World strip pressed and let go at its middle (the strip's own mouse handlers read the zone from the
-- x, y given: vx10_tab.lua X.clickBag); not pressed when another zone is first under that point or the button is
-- scrolled out of the strip's view. true, or false and why.
function X.clickCnt(w, idx)
    local strip = w and w._containerStrip
    local z = X.zoneOf(w, idx)
    if not (strip and z) then return false, "its button is not on the strip" end
    if not X.midInView(w, z) then return false, "its button is scrolled out of the strip's view" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local hit = nil
    pcall(function() hit = strip:hitZoneAt(x, y) end)
    if not (hit and hit.id == z.id) then return false, "another zone is first under its middle (" .. tostring(hit and hit.id) .. ")" end
    S.viewTouched = true
    pcall(strip.onMouseDown, strip, x, y)
    pcall(strip.onMouseUp, strip, x, y)
    return true
end
-- where a container's button is among the strip's buttons, in words
function X.btnAt(w, idx)
    local L = w and w._stripLay
    local list = L and L.entries
    if type(list) ~= "table" then return "button ?" end
    for pos, ci in ipairs(list) do
        if ci == idx then return "button " .. pos .. " of " .. #list .. " below Ground's" end
    end
    return "a button not listed"
end

-- ===================================================================== things made, the crate
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
-- a square dx, dy from where he stood at the start (nil when it is not loaded)
function X.sqAt(dx, dy)
    if not S.pos0 then return nil end
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.pos0.x) + dx, math.floor(S.pos0.y) + dy, math.floor(S.pos0.z)) end)
    return sq
end
-- a square one can stand on: loaded, a floor, free, no tree, no car
function X.standable(sq)
    if not sq then return false end
    local good = false
    pcall(function()
        good = sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil
    end)
    return good and true or false
end
-- the crate on a free square beside him that he reaches (no other object on it, no wall between: the strip lists only
-- what he reaches), its container explored at once (the strip would fill an unexplored one with loot), three things
-- in it (vx10_craft.lua H.setCrate, rt_inventory.lua)
function X.setCrate()
    local here = nil
    pcall(function() here = S.p:getCurrentSquare() end)
    if not here then return false end
    for _, d in ipairs(S.NEAR) do
        local sq = (not S.cr.inv) and X.sqAt(d[1], d[2]) or nil
        local ok = X.standable(sq)
        if ok then pcall(function() ok = sq:getObjects():size() <= 1 and here:canReachTo(sq) and true or false end) end
        if ok then
            pcall(function()
                local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
                o:createContainersFromSpriteProperties()
                sq:AddTileObject(o)
                S.cr.obj, S.cr.sq = o, sq
                S.cr.inv = o:getContainer()
            end)
            if S.cr.obj and not S.cr.inv then X.removeObj(S.cr.obj); S.cr.obj = nil end
            if S.cr.inv then S.cr.dx, S.cr.dy = d[1], d[2] end
        end
    end
    if not S.cr.inv then return false end
    pcall(function() S.cr.inv:setExplored(true) end)
    S.cr.its = {}
    for _, ft in ipairs(S.CRATE_THINGS) do
        local it = nil
        pcall(function() it = S.cr.inv:AddItem(ft) end)
        if it then S.cr.its[#S.cr.its + 1] = X.track(it) end
    end
    return true
end
function X.removeObj(obj)
    if not obj then return end
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if not sq then return end
    pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
    pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
end
function X.stands(obj)
    if not obj then return false end
    local up = false
    pcall(function() up = obj:getSquare() ~= nil and obj:getObjectIndex() >= 0 end)
    return up and true or false
end
-- the ground's list (the floor container the strip fills) holds the things made at his feet
function X.floorHolds(w)
    local fi = X.floorIdx(w)
    local inv = fi and w._containers[fi].inventory or nil
    if not inv then return false end
    for _, it in ipairs(S.fl.its) do
        local has = false
        pcall(function() has = inv:containsID(it:getID()) end)
        if not has then return false end
    end
    return true
end

-- ===================================================================== where he stands
-- moved by his own setters, the last values with them (zedqa_prelude.lua's move); the game puts him on the square
-- at its next update
function X.moveTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
-- he stands on square t ({ x, y, z }) as the game counts it (his current square)
function X.onSq(t)
    if not t then return false end
    local sq = nil
    pcall(function() sq = S.p:getCurrentSquare() end)
    if not sq then return false end
    local on = false
    pcall(function() on = sq:getX() == t.x and sq:getY() == t.y and sq:getZ() == t.z end)
    return on
end
function X.atPos0()
    if not S.pos0 then return true end
    local at = false
    pcall(function()
        at = math.abs(S.p:getX() - S.pos0.x) < 0.01 and math.abs(S.p:getY() - S.pos0.y) < 0.01
            and math.abs(S.p:getZ() - S.pos0.z) < 0.01
    end)
    return at
end
function X.sqs(t) if not t then return "none" end; return tostring(t.x) .. "," .. tostring(t.y) .. "," .. tostring(t.z) end
function X.here()
    local s = "?"
    pcall(function() s = string.format("%.2f,%.2f,%.2f", S.p:getX(), S.p:getY(), S.p:getZ()) end)
    return s
end
-- a square to step to, out of the crate's reach: the first of S.AWAY one can stand on, two or more squares from the
-- crate; and how far from the crate it is
function X.awaySq()
    if not (S.pos0 and S.cr.dx) then return nil end
    for _, d in ipairs(S.AWAY) do
        local far = math.max(math.abs(d[1] - S.cr.dx), math.abs(d[2] - S.cr.dy))
        if far >= 2 then
            local sq = X.sqAt(d[1], d[2])
            if X.standable(sq) then return sq, far end
        end
    end
    return nil
end
-- the World window's own reach (ZeD_WorldWindow.inReach: the containers it lists from where he stands now); nil when
-- it cannot say
function X.inReach(inv)
    local f = ZeD_WorldWindow and ZeD_WorldWindow.inReach
    if type(f) ~= "function" or inv == nil then return nil end
    local ok, r = pcall(f, inv, S.pn)
    if not ok then return nil end
    return r and true or false
end

-- ===================================================================== scroll, parts
-- (asked step by step, so a missing list or scroll gives nil without a throw)
function X.scrollBar() local c = X.content(); return c and c._scroll or nil end
function X.scrollOf() local sc, s = X.scrollBar(), nil; if sc then pcall(function() s = sc.scrollPos end) end; return s end
function X.scrollTo(pos) local sc = X.scrollBar(); if pos ~= nil and sc then pcall(function() sc:setScrollPos(pos) end) end end
-- a part that cannot go on: hard (a staging step that should work did not: a FAIL) or soft (this screen or this
-- character cannot stage it: a SKIP); said once, in place of the part's checks
function X.stop(key, why, hard)
    if not S.ok[key] then return end
    S.ok[key] = false
    S.why[key] = why
    if hard then Q.check(false, "staging, part " .. S.PART[key] .. ": " .. tostring(why))
    else Q.skip("part " .. S.PART[key], why) end
end
function X.anyOk() return S.ok.B or S.ok.M end
-- the staging every part shares stopped: said once (a FAIL when hard), the other parts said as waiting on it
function X.stopAll(why, hard)
    local first = true
    for _, k in ipairs({ "B", "R", "M" }) do
        if S.ok[k] then
            if first then X.stop(k, why, hard); first = false
            else X.stop(k, "the staging the parts share stopped (" .. tostring(why) .. ")", false) end
        end
    end
end

-- ===================================================================== the tab drawer, the roll, the tab's press (queued)
-- the World window on a tab of S.TABS beside whose drawer its side can roll: each tab its strip offers pressed in turn,
-- settled, and passed over when its drawer covers the list; the tab found kept in S.tab.w; then the list drawn 20
-- frames on Ground
function X.qTab()
    step(3, function()
        if not X.anyOk() then return end
        X.hold()
        S.try = { i = 0, cur = nil, tried = {} }
        X.nextTab()
        if S.try.err then X.stopAll("the press on the " .. S.try.err, true)
        elseif not S.try.cur then X.stopAll("the World strip offers none of " .. table.concat(S.TABS, ", "), false) end
    end)
    waitFor(3, 1800, function()
        if not X.anyOk() then return true end
        X.hold()
        local t = S.try
        if not (t and t.cur) then return true end
        if not X.settled(t.cur) then return false end
        if X.canRoll(RT.ww()) then return true end
        local c = X.content()
        t.tried[#t.tried + 1] = t.cur .. ((c and c:isVisible()) and " (the side cannot roll there)" or " (its drawer covers the list)")
        X.nextTab()
        return t.cur == nil
    end, function(ok)
        if not X.anyOk() then return end
        local t, w = S.try, RT.ww()
        if t and t.cur and w and w._activeTab == t.cur and X.canRoll(w) then
            S.tab.w = t.cur
            S.drawn = 0
            return
        end
        if t and t.err then
            X.stopAll("the press on the " .. t.err, true)
        elseif t and t.cur then
            X.stopAll("the " .. t.cur .. " tab did not open and settle (the World window is on " .. tostring(w and w._activeTab) .. ")", true)
        else
            X.stopAll("the World window's side cannot roll beside any of its tabs on this screen: " .. table.concat((t and t.tried) or {}, "; "), false)
        end
    end)
    waitFor(1, 300, function() return not X.anyOk() or X.listDrawn(S.fl.inv) end, function(ok)
        if X.anyOk() and not ok then
            X.stopAll("the World list did not show Ground beside the " .. tostring(S.tab.w) .. " drawer (" .. X.vs(RT.ww()) .. ")", true)
        end
    end)
end
-- the World window's side rolled away under its tab: the curtain's own roll inside the window's update, then its tab
-- at rest at the title bar with its label drawn afresh (the label and the tab's rect cleared at the roll)
function X.qRoll(key)
    step(2, function()
        if not S.ok[key] then return end
        local w = RT.ww()
        if not X.canRoll(w) then
            X.stop(key, "the World window's side cannot roll beside its " .. tostring(w and w._activeTab) .. " drawer on this screen", false)
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
        local w = RT.ww()
        return w ~= nil and w._qaPressDone == true and X.atRest(w)
    end, function(ok)
        if not S.ok[key] or ok then return end
        local w = RT.ww()
        local rod = w and w._rod
        X.stop(key, "the World window's side did not roll away under its tab (rolled " .. tostring(w and w._rolled)
            .. ", the tab " .. (rod and (math.floor(rod._h or -1) .. " px tall going to " .. math.floor(rod._target or -1) .. " px") or "not made")
            .. (S.pressErr and (", error " .. S.pressErr) or "") .. ")", true)
    end)
end
-- the side brought down by its tab: the rod's own press and release on the middle of its label, inside the rod's
-- update; then the list drawn 20 frames on getInv()
function X.qUnroll(key, getInv)
    step(3, function()
        if not S.ok[key] then return end
        local w = RT.ww()
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
        local w = RT.ww()
        return w ~= nil and not w._rolled
    end, function(ok)
        if not S.ok[key] then return end
        if not ok then
            X.stop(key, "the World window's side did not come down (" .. tostring(S.unrollHow) .. (S.pressErr and (", error " .. S.pressErr) or "") .. ")", true)
            return
        end
        S.drawn = 0
    end)
    waitFor(1, 300, function() return not S.ok[key] or X.listDrawn(getInv()) end, function(ok)
        if S.ok[key] and not ok then X.stop(key, "the World list did not draw its container again after the side came down (" .. X.vs(RT.ww()) .. ")", true) end
    end)
end
-- (rolled down again) the list shows the container the tab named, its heading at what the tab said: the heading's
-- name, its words ("N items") and shownCount
function X.downCheck(inv, lab, what)
    local tn, n = X.parse(lab)
    local head, shown, hn = X.head(), X.shown(inv), X.headName()
    local want = X.wantHead(n)
    Q.check(n ~= nil and shown == n and head ~= nil and head == want and hn ~= nil and hn == tn, what,
        "the tab said [" .. tostring(lab) .. "]; rolled down, the list shows [" .. tostring(hn) .. "], its heading [" .. tostring(head)
        .. "] (shownCount " .. tostring(shown) .. "), want [" .. tostring(want) .. "]; the side came down by " .. tostring(S.unrollHow))
end

-- ===================================================================== the scene
step(2, function()
    if not (S.p and C and C.roll and C.unroll and C.finishUnroll and ZeD_WorldWindow and ZeD_WorldWindow.selectContainer) then
        S.dead = true
        Q.check(false, "the scene: the kit's player, ZeD's World window and its curtain are loaded")
        return
    end
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then S.dead = true; Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    S.main = S.p:getInventory()
    S.pairWas, S.worldWas = RT.isOpen(), X.worldOpen()
    local md = S.p:getModData()
    S.winState0 = { had = md.ZeD_WinState ~= nil, v = X.copy(md.ZeD_WinState) }
    S.r0 = X.counts(S.main)
    S.pos0 = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    local sq = S.p:getCurrentSquare()
    S.sq0 = sq and { x = sq:getX(), y = sq:getY(), z = sq:getZ() } or nil
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
    S.hand0 = { w = X.handOf(ww) }
    S.geoF = { c = X.geo(cw), w = X.geo(ww) }
    S.view0 = X.viewOf(ww)
    S.scroll0 = X.scrollOf()
    S.strip0 = ww._stripScrollOffset
    X.keepScroll(S.tab0.w)
    X.hold()
    -- (a World side found rolled comes down for the checks; it is rolled again at the end, the way it was rolled)
    if S.rolled0.w then pcall(C.finishUnroll, ww) end
    S.geo0 = { c = X.geo(cw), w = X.geo(ww) }
    -- (a window rolled up to its title bar shows no list; Loot columns would close at a tab press, and they could not be
    -- put back; nor could an item or object card in the drawer, which a tab press or a strip click puts away; seated in
    -- a car, the World list is the car's and lists no crate beside him)
    local mcW = #(ww._mcSelected or {})
    if ww.windowShaded then X.stopAll("the World window is rolled up to its title bar", false)
    elseif mcW > 0 then X.stopAll("the World window has " .. mcW .. " Loot column(s) open: a tab press would close them, and they could not be put back", false)
    elseif ww._drawerItem ~= nil or ww._drawerObject ~= nil then
        X.stopAll("the World window shows " .. (ww._drawerItem ~= nil and "an item card" or "an object card") .. " in its drawer: a tab press would put it away, and it could not be put back", false)
    elseif X.seated() then X.stopAll("he sits in a car: the World window lists that car's containers alone", false) end
    Q.say("scene: Character " .. X.gs(S.geoF.c) .. " on " .. tostring(S.tab0.c) .. ", World " .. X.gs(S.geoF.w) .. " on " .. tostring(S.tab0.w)
        .. ", screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", sides rolled " .. tostring(S.rolled0.c) .. "/" .. tostring(S.rolled0.w)
        .. "; the World list: " .. X.vs(ww) .. "; he stands at " .. X.here() .. "; the pair was " .. ((S.pairWas and S.worldWas) and "open" or "shut"))
end)

-- ===================================================================== the crate and the ground (all parts)
step(5, function()
    if not X.anyOk() then return end
    X.hold()
    if not X.setCrate() then
        X.stopAll("no square beside him takes a crate (each of the 8 is taken, walled off from him or not loaded)", false)
        return
    end
    -- two things at his feet: Ground's own (part M counts what lies in reach)
    local sq = nil
    pcall(function() sq = S.p:getCurrentSquare() end)
    if sq then
        for i, ft in ipairs(S.GROUND_THINGS) do
            local it = X.addFloor(sq, ft, 0.3 + 0.25 * i, 0.5)
            if it then S.fl.its[#S.fl.its + 1] = it end
        end
    end
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end   -- (the World list reads what is in reach afresh on its next frame)
end)
waitFor(2, 300, function()
    if not X.anyOk() then return true end
    X.hold()
    local ww = RT.ww()
    if not (ww and X.idxOf(ww, S.cr.inv)) then return false end
    return X.floorHolds(ww)
end, function(ok)
    if not X.anyOk() then return end
    local ww = RT.ww()
    local ci = ww and X.idxOf(ww, S.cr.inv)
    local fi = ww and X.floorIdx(ww)
    if not (ci and fi) then
        X.stopAll("the World strip did not list the crate set beside him (" .. (ci and "it lists no Ground" or "the crate is not on its list") .. ")", true)
        return
    end
    S.cr.name = ww._containers[ci].name
    S.fl.inv, S.fl.name = ww._containers[fi].inventory, ww._containers[fi].name
    local r = X.counts(S.cr.inv)
    Q.say("the crate set " .. tostring(S.cr.dx) .. "," .. tostring(S.cr.dy) .. " from him with " .. #(S.cr.its or {}) .. " things in it, listed on the World strip as ["
        .. tostring(S.cr.name) .. "] (" .. X.btnAt(ww, ci) .. "); " .. X.cs(r) .. "; " .. #S.fl.its .. " things made at his feet"
        .. (ok and "" or " (the ground's list had not taken them in yet: Ground counts what it holds)"))
end)
-- (the World list on Ground, the active container, no container viewed over it)
step(2, function()
    if not X.anyOk() then return end
    X.hold()
    local ww = RT.ww()
    if not ww then X.stopAll("the World window went away", true); return end
    local v = X.viewOf(ww)
    if v.aInv == S.fl.inv and v.vInv == nil then return end
    S.viewTouched = true
    Q.say("the World list showed " .. X.vs(ww) .. ": put on Ground first (ZeD_WorldWindow.selectContainer)")
    pcall(ZeD_WorldWindow.selectContainer, S.fl.inv, 60, S.pn)
end)
X.qTab()
step(1, function()
    if not X.anyOk() then return end
    Q.say("the World window on " .. tostring(S.tab.w) .. ", its list on Ground beside the drawer"
        .. ((S.try and #S.try.tried > 0) and ("; passed over: " .. table.concat(S.try.tried, "; ")) or ""))
end)

-- ===================================================================== B. the crate picked with the mouse on the tab
step(2, function()
    if not S.ok.B then return end
    X.hold()
    local ww = RT.ww()
    local ci = ww and X.idxOf(ww, S.cr.inv)
    if not ci then X.stop("B", "the crate left the World strip", true); return end
    S.b.scrolled = X.intoView(ww, ci)
end)
step(3, function()
    if not S.ok.B then return end
    local ww = RT.ww()
    local ci = ww and X.idxOf(ww, S.cr.inv)
    if not ci then X.stop("B", "the crate left the World strip", true); return end
    -- (a FAIL: the crate is on the strip and its button was scrolled into view, so the mouse reaches it)
    local pressed, why = X.clickCnt(ww, ci)
    if not pressed then X.stop("B", "the crate's button could not be pressed: " .. tostring(why), true); return end
    S.drawn = 0
end)
waitFor(2, 300, function() return not S.ok.B or X.listDrawn(S.cr.inv) end, function(ok)
    if not S.ok.B then return end
    local ww = RT.ww()
    if not (ok and ww) then
        X.stop("B", "the list did not show the crate after its button was pressed (" .. X.vs(ww) .. ")", true)
        return
    end
    -- (the finding's case: the press views the crate alone, the window's active container stays the floor)
    local v = X.viewOf(ww)
    if not (v.vInv == S.cr.inv and v.aInv == S.fl.inv) then
        X.stop("B", "the press on the crate's button did not view it alone over Ground (" .. X.vs(ww) .. ")", true)
        return
    end
    S.b.head0, S.b.shown0 = X.head(), X.shown(S.cr.inv)
    Q.say("B: the crate's button pressed on the World strip on " .. tostring(S.tab.w) .. (S.b.scrolled and " (scrolled into the strip's view first)" or "")
        .. ": the list shows it, its heading reads [" .. tostring(S.b.head0) .. "] (shownCount " .. tostring(S.b.shown0) .. "); " .. X.vs(ww)
        .. " (the press set only the viewed one)")
end)
X.qRoll("B")
step(4, function()
    if not S.ok.B then return end
    local ww = RT.ww()
    local lab = X.label(ww)
    local r = X.counts(S.cr.inv)
    local live = X.live(S.cr.inv)
    S.b.lab1 = lab
    Q.check(lab == X.lab(S.cr.name, r.own) and live == r.own and S.b.shown0 == r.own,
        "B: the crate picked with the mouse on " .. tostring(S.tab.w) .. ", then rolled away: the tab names the crate and counts its things (old code: Ground, with the ground's count)",
        "the tab [" .. tostring(lab) .. "], want [" .. X.lab(S.cr.name, r.own) .. "]; liveCount " .. tostring(live) .. "; before the roll the heading read ["
        .. tostring(S.b.head0) .. "] (shownCount " .. tostring(S.b.shown0) .. "); " .. X.cs(r))
    local help, want = X.help(ww), X.wantHelp(S.cr.name, r.own)
    Q.check(help ~= nil and help == want, "B: the tab's help line names the crate and gives its count (old code: Ground)",
        "[" .. tostring(help) .. "], want [" .. tostring(want) .. "]")
    local drop = X.drop(ww)
    Q.check(drop ~= nil and drop == S.cr.inv, "B: a drop on the tab goes into the crate it names (old code: to the ground)",
        "a drop on the tab goes into " .. X.invName(ww, drop) .. ((drop ~= nil and drop == S.cr.inv) and " (the crate)" or " (not the crate)"))
end)

-- ===================================================================== R. the reach guard (the crate viewed, the side still rolled)
step(2, function()
    if not S.ok.R then return end
    if not S.ok.B then X.stop("R", "part B did not leave the crate's tab rolled away (" .. tostring(S.why.B) .. ")", false); return end
    -- (the game puts him on a square he is moved to only while it plays: zedqa_prelude.lua sets the speed to 1)
    local speed = 1
    if getGameSpeed then speed = getGameSpeed() end
    if speed == 0 then X.stop("R", "the game is paused: he is put on the square he is moved to only while it plays", false); return end
    X.hold()
    local sq, far = X.awaySq()
    if not sq then X.stop("R", "no square two or three squares from him, out of the crate's reach, that he can stand on", false); return end
    S.away = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), far = far }
    S.moved, S.home = true, false
    X.moveTo(S.away.x + 0.5, S.away.y + 0.5, S.pos0.z)
end)
waitFor(2, 180, function()
    if not (S.ok.R and S.moved) then return true end
    X.hold()
    return X.onSq(S.away)
end, function(ok)
    if not (S.ok.R and S.moved) then return end
    local ww = RT.ww()
    if not ok then
        X.stop("R", "the game did not put him on the square he was moved to (" .. X.sqs(S.away) .. "; he is at " .. X.here() .. ")", true)
        return
    end
    local v = X.viewOf(ww)
    if not (ww and ww._rolled and v.vInv == S.cr.inv) then
        X.stop("R", "the side came down or its list left the crate while he stood away (rolled " .. tostring(ww and ww._rolled) .. ", " .. X.vs(ww) .. ")", true)
        return
    end
    -- (out of reach by the window's own measure first: a crate it still reaches is the staging's fault, not the fix's)
    local reach = X.inReach(S.cr.inv)
    if reach ~= false then
        X.stop("R", "he stands " .. tostring(S.away.far) .. " squares from the crate, but ZeD_WorldWindow.inReach answers " .. tostring(reach)
            .. " for it (he is at " .. X.here() .. ")", true)
        return
    end
    local lab = X.label(ww)
    local drop, answered = X.drop(ww)
    Q.check(answered and drop == nil,
        "R: moved " .. tostring(S.away.far) .. " squares from the crate, the side still rolled under the tab that names it: a drop on the tab goes nowhere, not into the crate from afar (old code: to the ground)",
        "he stands at " .. X.here() .. "; the crate in the World window's reach (ZeD_WorldWindow.inReach): " .. tostring(reach) .. "; the tab ["
        .. tostring(lab) .. "]; a drop on the tab goes into " .. X.invName(ww, drop) .. (answered and "" or " (dropInv threw)"))
end)
-- (back where he stood, whatever R found: any step that moved him)
Q.step(2, function()
    if S.moved and not S.home then X.moveTo(S.pos0.x, S.pos0.y, S.pos0.z) end
end)
waitFor(2, 180, function()
    if not (S.moved and not S.home) then return true end
    return X.atPos0() and (S.sq0 == nil or X.onSq(S.sq0))
end, function(ok)
    if not (S.moved and not S.home) then return end
    S.home = ok
    if not ok then
        X.stop("R", "the game did not put him back where he stood (" .. X.sqs(S.sq0) .. "; he is at " .. X.here() .. ")", true)
        return
    end
    if not S.ok.R then return end
    local ww = RT.ww()
    local reach = X.inReach(S.cr.inv)
    local drop = X.drop(ww)
    Q.check(drop ~= nil and drop == S.cr.inv, "R: back where he stood, beside the crate: a drop on the tab goes into the crate again (old code: to the ground)",
        "he stands at " .. X.here() .. "; the crate in reach: " .. tostring(reach) .. "; a drop on the tab goes into " .. X.invName(ww, drop))
end, true)
X.qUnroll("B", function() return S.cr.inv end)
step(1, function()
    if not S.ok.B then return end
    X.downCheck(S.cr.inv, S.b.lab1,
        "B: rolled down again, the list shows the crate the tab named and its heading counts what the tab said (old code: the tab had said Ground over the crate's list)")
end)

-- ===================================================================== M. the mirror: the crate active, Ground viewed
step(5, function()
    if not S.ok.M then return end
    if not S.tab.w then X.stop("M", "no tab to stage it on", false); return end
    if S.moved and not S.home then X.stop("M", "he is not back where he stood (part R), so the crate may be out of reach", true); return end
    X.hold()
    local ww = RT.ww()
    if not ww then X.stop("M", "the World window went away", true); return end
    if ww._rolled then pcall(C.finishUnroll, ww) end
    if ww._activeTab ~= S.tab.w then X.stop("M", "the World window left the " .. tostring(S.tab.w) .. " tab (it is on " .. tostring(ww._activeTab) .. ")", true); return end
    -- the crate the active container, as a click on it in the world makes it (the game's loot page hands the click to
    -- selectContainer); then the list read afresh (the ground at his feet again, after part R)
    S.viewTouched = true
    local okS = false
    pcall(function() okS = ZeD_WorldWindow.selectContainer(S.cr.inv, 60, S.pn) and true or false end)
    S.m.sel = okS
    ww._containerTimer = 30
    S.drawn = 0
end)
waitFor(2, 300, function()
    if not S.ok.M then return true end
    X.hold()
    local drawn = X.listDrawn(S.cr.inv)
    local ww = RT.ww()
    local v = X.viewOf(ww)
    return drawn and v.aInv == S.cr.inv and v.vInv == nil and X.floorHolds(ww)
end, function(ok)
    if not S.ok.M then return end
    local ww = RT.ww()
    local v = X.viewOf(ww)
    if not (ww and v.aInv == S.cr.inv and v.vInv == nil) then
        X.stop("M", "selectContainer did not make the crate the active container (it answered " .. tostring(S.m.sel) .. "; " .. X.vs(ww) .. ")", true)
        return
    end
    if not ok then Q.say("note M: the ground's list had not taken in the things at his feet again: Ground counts what it holds") end
end)
step(2, function()
    if not S.ok.M then return end
    X.hold()
    local ww = RT.ww()
    local fi = ww and X.floorIdx(ww)
    if not fi then X.stop("M", "the World strip has no Ground button", true); return end
    -- (a FAIL: Ground's button is pinned at the strip's top, always in view)
    local pressed, why = X.clickCnt(ww, fi)
    if not pressed then X.stop("M", "Ground's button could not be pressed: " .. tostring(why), true); return end
    S.drawn = 0
end)
waitFor(2, 300, function() return not S.ok.M or X.listDrawn(S.fl.inv) end, function(ok)
    if not S.ok.M then return end
    local ww = RT.ww()
    if not (ok and ww) then
        X.stop("M", "the list did not show Ground after its button was pressed (" .. X.vs(ww) .. ")", true)
        return
    end
    local v = X.viewOf(ww)
    if not (v.vInv == S.fl.inv and v.aInv == S.cr.inv) then
        X.stop("M", "the press on Ground's button did not view it alone over the crate (" .. X.vs(ww) .. ")", true)
        return
    end
    S.m.head0, S.m.shown0 = X.head(), X.shown(S.fl.inv)
    Q.say("M: the crate made the active container (selectContainer answered " .. tostring(S.m.sel) .. "), then Ground's button pressed on "
        .. tostring(S.tab.w) .. ": the list shows Ground, its heading reads [" .. tostring(S.m.head0) .. "] (shownCount " .. tostring(S.m.shown0) .. "); " .. X.vs(ww))
end)
X.qRoll("M")
step(4, function()
    if not S.ok.M then return end
    local ww = RT.ww()
    local lab = X.label(ww)
    local r = X.counts(S.fl.inv)
    local live = X.live(S.fl.inv)
    S.m.lab1 = lab
    Q.check(lab == X.lab(S.fl.name, r.own) and live == r.own and S.m.shown0 == r.own,
        "M: the crate the active container, Ground viewed on " .. tostring(S.tab.w) .. ", then rolled away: the tab names Ground and counts what lies there (old code: the crate, with its count)",
        "the tab [" .. tostring(lab) .. "], want [" .. X.lab(S.fl.name, r.own) .. "]; liveCount " .. tostring(live) .. "; before the roll the heading read ["
        .. tostring(S.m.head0) .. "] (shownCount " .. tostring(S.m.shown0) .. "); " .. X.cs(r))
    local help, want = X.help(ww), X.wantHelp(S.fl.name, r.own)
    Q.check(help ~= nil and help == want, "M: the tab's help line names Ground and gives its count (old code: the crate)",
        "[" .. tostring(help) .. "], want [" .. tostring(want) .. "]")
    local drop = X.drop(ww)
    Q.check(drop ~= nil and drop == S.fl.inv, "M: a drop on the tab goes to the ground it names (old code: into the crate)",
        "a drop on the tab goes into " .. X.invName(ww, drop) .. ((drop ~= nil and drop == S.fl.inv) and " (the ground)" or " (not the ground)"))
end)
X.qUnroll("M", function() return S.fl.inv end)
step(1, function()
    if not S.ok.M then return end
    X.downCheck(S.fl.inv, S.m.lab1,
        "M: rolled down again, the list shows Ground, the tab's name, and its heading counts what the tab said (old code: the tab had said the crate over Ground's list)")
end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    X.unvia()
    X.hold()
    local ww = RT.ww()
    -- (a side down for the put-back's tab press; only once the scene kept what it found: a run that stopped before
    -- that touched no side, and one found rolled stays so)
    if ww and ww._rolled and S.rolled0 and C and C.finishUnroll then pcall(C.finishUnroll, ww) end
    -- him where he stood (part R moves him back itself; a run cut short may not have)
    if S.moved and not X.atPos0() then X.moveTo(S.pos0.x, S.pos0.y, S.pos0.z) end
    -- everything made, wherever it is; then the crate (one holding something the test did not put in it stays, said)
    for _, it in ipairs(S.made) do pcall(X.removeItem, it) end
    if S.cr.obj then
        local left = 0
        pcall(function() left = S.cr.inv:getItems():size() end)
        if left > 0 then
            S.cr.kept = left
            Q.say("note: the crate holds " .. left .. " thing(s) the test did not put in it: it is left beside him, not emptied")
        else
            X.removeObj(S.cr.obj)
        end
    end
    -- the World list's view and the strip's scroll as found; the list read afresh (the crate gone from it)
    if ww and S.view0 and S.viewTouched then X.viewToW(ww, S.view0) end
    if ww and S.tab0 then ww._stripScrollOffset = S.strip0 end
    if ww then ww._containerTimer = 30 end
end)
Q.step(3, function()
    if not (S.tab0 and X.bothOpen()) then return end
    S.st = {}
    RT.worldTab(S.tab0.w)
end)
waitFor(3, 600, function()
    if not (S.tab0 and X.bothOpen()) then return true end
    X.hold()
    return X.settled(S.tab0.w)
end, function(ok)
    if not (S.tab0 and X.bothOpen()) then return end
    local ww = RT.ww()
    -- the view again (a container's place on the strip may have moved at its rebuild), the list's and the tabs' scroll
    if S.viewTouched then X.viewToW(ww, S.view0) end
    X.scrollTo(S.scroll0)
    X.tabScrollBack()
    -- the places and sizes: the tab press brings them back; a window it did not is set back by its own setters (never
    -- ZEDQA_LAYOUT_BACK here: its reset re-saves the windows' accents, and ModOptions.ini with them)
    local cw = RT.cw()
    if cw and S.geo0 and not X.sameGeo(X.geo(cw), S.geo0.c) then
        S.placed = "Character at " .. X.gs(X.geo(cw))
        X.placeBack(cw, S.geo0.c)
    end
    if ww and S.geo0 and not X.sameGeo(X.geo(ww), S.geo0.w) then
        S.placed = (S.placed and (S.placed .. "; ") or "") .. "World at " .. X.gs(X.geo(ww))
        X.placeBack(ww, S.geo0.w)
    end
    -- a side found rolled, rolled again (by the curtain's own roll inside the window's update)
    if S.rolled0 and S.rolled0.w and ww and not ww._rolled and X.canRoll(ww) then X.via(ww, function(self) C.roll(self) end) end
end, true)
-- (a side rolled again rolls in its window's next update)
waitFor(2, 120, function()
    if not (S.rolled0 and X.bothOpen()) then return true end
    local ww = RT.ww()
    return (ww._rolled and true or false) == S.rolled0.w
end, function() end, true)
Q.step(10, function()
    X.unvia()
    local cw, ww = RT.cw(), RT.ww()
    -- a side rolled again: rolled the way it was found (the halves tell a hand roll from the pointer's timer); then the
    -- roll timers as found
    if ww and S.rolled0 and S.rolled0.w and ww._rolled and ww._halves and ww._halves.inv then ww._halves.inv.hand = S.hand0.w and true or false end
    if cw and S.out0 then cw._outSince = S.out0.c end
    if ww and S.out0 then ww._outSince = S.out0.w end
    if S.tab0 and cw and ww and X.bothOpen() then
        local view = X.sameView(ww, S.view0)
        Q.check(cw._activeTab == S.tab0.c and ww._activeTab == S.tab0.w and (cw._rolled and true or false) == S.rolled0.c
            and (ww._rolled and true or false) == S.rolled0.w and view,
            "put back: both windows on the tabs they were on, their sides as found, the World list on what it showed",
            "Character on " .. tostring(cw._activeTab) .. " (was " .. tostring(S.tab0.c) .. "), side rolled " .. tostring(cw._rolled) .. "; World on "
            .. tostring(ww._activeTab) .. " (was " .. tostring(S.tab0.w) .. "), side rolled " .. tostring(ww._rolled) .. "; the World list's view as found "
            .. tostring(view) .. " (" .. X.vs(ww) .. ")")
        Q.check(X.sameGeo(X.geo(cw), S.geoF.c) and X.sameGeo(X.geo(ww), S.geoF.w),
            "put back: both windows where and as big as they were",
            "Character " .. X.gs(S.geoF.c) .. " -> " .. X.gs(X.geo(cw)) .. ", World " .. X.gs(S.geoF.w) .. " -> " .. X.gs(X.geo(ww))
            .. (S.placed and (" (the tab press left " .. S.placed .. ": set back by the window's own setters)") or ""))
    end
    if S.r0 then
        local left = {}
        for _, it in ipairs(S.made) do
            local c, fl = X.where(it), X.onFloor(it)
            if c ~= nil or fl then left[#left + 1] = X.nm(it) .. (fl and " on the ground" or " in a container") end
        end
        local crate = X.stands(S.cr.obj)
        local r = X.counts(S.main)
        Q.check(#left == 0 and not crate and X.atPos0() and r.raw == S.r0.raw,
            "put back: nothing the test made is left (the crate and its things, the things at his feet), he stands where he stood, he carries what he did",
            #left .. " of " .. #S.made .. " made things left" .. ((#left > 0) and (": " .. table.concat(left, "; ")) or "") .. "; the crate still stands "
            .. tostring(crate) .. (S.cr.kept and (" (it held " .. S.cr.kept .. " thing(s) the test did not put in it)") or "")
            .. "; he stands at " .. X.here() .. " (was " .. (S.pos0 and string.format("%.2f,%.2f,%.2f", S.pos0.x, S.pos0.y, S.pos0.z) or "?")
            .. "); his inventory " .. S.r0.raw .. " -> " .. r.raw .. " things")
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
