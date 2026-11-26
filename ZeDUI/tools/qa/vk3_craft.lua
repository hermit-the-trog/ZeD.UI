-- ZeDUI/tools/qa/vk3_craft.lua  (Nov 22 2026, QA KISS batch K3; tag vk3_cft): the in-game proof of the director's K3
-- picks on crafting, building, the Journal, the cards, the Health tab, the moodles, the gun's jam and the stove
-- (ZeDUI/qa/audits/2026-11-22_kiss_calls_K3.md: #17, #29, #32, #35, #47, #48, #49, #54, #55, #57, #58). The old code
-- is 0b366177e; the new is 7b8ed6843 (the merge ae3f4a2b2 of branch k3: d2b29af91 Craft and Build, b11aa8388 cards,
-- health and stove, 2dd9cd3e7 the moodles and the belt, ff3cd87d1 the words). Built on rt_kit.lua (the global RT),
-- run after zedqa_prelude.lua. grep "ZEDQA vk3_cft". Manifest line: vk3_craft.lua | vk3_cft | timeout=420
--
-- Every check below FAILS on the old code and PASSES on the new, for the reason its label gives. A staging that does
-- not come off prints a FAIL line saying "staging" (never a PASS); a world that does not hold the case says SKIP and
-- why. The put-back checks at the end pass on both. Nothing is crafted, built, eaten, drunk, bandaged or repaired:
-- Craft, Build, Bandage, Repair and the quick list's rows are never pressed. The one world action is the stove's Turn
-- on (#58), and the stove is turned off and taken away after.
--
-- What each check reads, and what the old code does:
--   #48 (World window, Crafting tab; Show: All, every category, no search, no card, no station bound). The tab's
--     drawing watched for 0.8 s (CraftingCore.renderStaticHeader and renderTabTitle wrapped, counted, passed on):
--     * the header is drawn and no title row with it. Old code: a "Crafting" row on every header.
--     * with no station in reach (none bound, ZeD.Stations.nearby empty), no Station box (no stationDropdown zone).
--       Old code: "Station: Hand" always. SKIP when a station stands in reach.
--   #17 * (Craft) Show: Ready, each category in turn until one lists nothing: the line the empty list draws
--       (Molecules.drawEmptyLine, watched) names Show: Known, and a fresh Craft tab still opens on Ready. Old code:
--       "Nothing is ready to make with what is in reach." With every category listing something under Ready here the
--       line is read from CraftingCore.emptyListText on a fresh Craft state (said in the line: not drawn).
--   #47 (two recipe rows in the list's view, each pressed by the drawer's own onMouseDown where a click lands):
--     * a second click on the open row leaves its card open, and a click on another row opens that one instead.
--       Old code: the second click shuts the card.
--     * Escape (handed to the game's key handler, ToggleEscapeMenu, as vk2_mouse's K2-6) shuts the card and the game's
--       pause menu stays shut. Old code: the card stays and the pause menu opens (shut again at once).
--   #35 * a recipe made on any surface (entry.needSurface), its card open for a second: no "Surface" badge among the
--       badges the card draws (ZeD.Atoms.drawBadge inside CraftingCore.renderCraftCard, watched). Old code: an amber
--       Surface badge on every such card.
--   #32 * three boxes of nails given, Open Box (OpenBox100) opened from its row: a Max key on the band (zone
--       action_max), and its press sets the amount to the most the band knows (state._maxQty, more than 1). Old code:
--       no Max key. SKIP when the most is 1 here.
--     * (Build tab) a build recipe's card open from its row: the band has Build and no amount (no action_dec, inc,
--       qty or max zone). Old code: the grayed - 1 + beside Build.
--   #17 * (Build tab) the tab's state made fresh (the window's _buildState found is set aside and put back after) and
--       the tab opened by its own press: it is on Show: All (the director's call 6, Nov 25 2026, replaced Known).
--       Older code: Known, and Ready before that.
--   #55 * (Character window, Journal, Recipes page) Open Box's card opened on the page: the band has the Open in
--       Craft key (zone action_open), and its press (the drawer's own onMouseDown) puts the World window on Crafting
--       with Open Box's card open (RecipeIndex.open). Old code: no key on the band.
--   #29 (cards) a bandage, painkillers given, each card opened by a click on its row:
--     * the bandage's card has Bandage (the game's ContextMenu_Bandage) and the painkillers' card reads Take Pills
--       (ContextMenu_Take_pills) on its Use. Old code: no Bandage; Use.
--   #57 * a worn pistol and a second pistol given; the worn one's card opened by a click on its row: its Repair key's
--       help balloon (the care band's button, read where ZeD.Molecules.drawBand is handed it) names the fixer the game
--       would spend first (FixingManager's first fixer he has, named as the game's Fix menu names it). Old code:
--       "repair it with what you carry". (In this build only firearms repair through FixingManager; a bat's repair is
--       a craft recipe, so the pistol stands in for the pick's duct tape.)
--   #29 (Health tab; god mode off and invincible on for the run, a guard every tick; a scratch, infection off, on a
--     clean arm part; a bandage given; the game's debug cheat entries in the treatment menu off for the clicks):
--     * a left click (the drawer's own onMouseDown and onMouseUp) on the part's wound row opens the treatment menu,
--       with Bandage in it. Old code: nothing opens (only a right-click did).
--     * a left click on a clean part of the body figure: no menu, and the character says "<part>: nothing to treat."
--       (HealthTab.sayNothingFits, read by handing it a stand-in for the character). Old code: nothing.
--   #58 * a stove placed beside him, off; Turn on as the game's world menu runs it (ISWorldObjectContextMenu.
--       onToggleStove): once its ISToggleStoveAction has run and 1.2 s more, no panel opened for it (no FacePop.open
--       or Stations.open on the stove, no station bound to it, no face pop-out showing it). Old code: the marked oven
--       opened its face or the Craft tab on it.
--   #54 * a pistol in his hand, jammed: the belt's hover lines (ZeD.Belt.ammoLines on ZeD.Belt.ammo) start "Jammed,
--       press <his Rack Firearm key>". Old code: "Jammed: <gun>". SKIP when the key is not bound.
--   #49 (both windows shut for it, opened again after; hunger and thirst set to 0.3, an apple and a water bottle
--     given): a click (the moodle layer's onMouseDown and onMouseUp at the moodle's middle) on Hungry, then Thirsty:
--     * the press is taken and a menu opens whose rows are the pad wheel's Eat (Drink) list in its order, the best
--       first (ZeD.DpadWheels.H.quick). Old code: the click passes through, nothing opens. No row is pressed.
--       Thirsty is a SKIP when he carries nothing the wheel would drink.
--
-- The pointer is the one thing faked: getMouseX / getMouseY answer the point for each press only, and the moodle
-- layer's isMouseOver answers yes for its click. ZeD's input mode is locked to the mouse for the run (vx12_wheel.lua's
-- lock). Waits go by the clock; nothing in pixels is written in (points come from the zones ZeD stamps), so it runs as
-- it is at 4K (UI scale 1.75) and 1280x800. A press point under another ZeD window or the belt is a SKIP, said.
-- What it puts back (also when a step throws or the time runs out): the queue, every menu, the pause menu, every
-- wrapper; the stove off and gone; the wound healed, god mode, invincible, hunger, thirst and the Health tab's cheat
-- flag as found; everything given taken away, his hands as found; the Crafting tab's Show, Sort, category, search,
-- open card and scroll, a bound station; the Build tab's state object; the Journal's page and card; the lists' stacks,
-- folds and grid choices; both windows' tabs, open or shut, places and sizes; the input lock. No option is saved.

if not (RT and RT.make) then
    print("ZEDQA vk3_cft ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk3_cft VERDICT FAIL 1")
    print("ZEDQA vk3_cft DONE")
    return
end

local Q = RT.make("vk3_cft")
Q.maxMs = 300000   -- (five minutes, then the put-back; a run takes about two)
local S = { p = RT.p, pn = RT.pn, was = {}, made = {}, stacks = {}, seek = {}, grid = {}, folds = {}, wraps = {},
    c = {}, b = {}, j = {}, u = {}, d = {}, v = {}, m = {}, g = {} }
local H = {}    -- shared helpers
local M = {}    -- right-click menus and the pause screen
local C = {}    -- the Crafting and Building tabs
local J = {}    -- the Journal
local U = {}    -- the cards
local D = {}    -- the Health tab
local V = {}    -- the stove
local MO = {}   -- the moodles
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector

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
function H.list(t) local out = {}; for _, v in ipairs(t or {}) do out[#out + 1] = tostring(v) end; return table.concat(out, ", ") end
function H.has(s, part) return type(s) == "string" and type(part) == "string" and part ~= "" and s:find(part, 1, true) ~= nil end
function H.starts(s, pre) return type(s) == "string" and type(pre) == "string" and pre ~= "" and s:sub(1, #pre) == pre end
function H.low(s) if type(s) ~= "string" then return nil end; return s:lower() end

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
function H.give(ft)
    local it = RT.give(ft)
    if it then S.made[#S.made + 1] = it end
    return it
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
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
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
function H.pause(ms) H.wait(ms, function() return false end, function() end) end

-- ===================================================================== the windows
function H.charOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(S.pn) end); return o and true or false end
function H.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function H.both() return H.charOpen() and H.worldOpen() and RT.cw() ~= nil and RT.ww() ~= nil end
function H.openBoth() if not (H.charOpen() and H.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end end
function H.win(k) if k == "c" then return RT.cw() end; return RT.ww() end
function H.content(k) local w = H.win(k); return w and w._mainContent end
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
-- the windows held down for the run (the roll-up timers in the future, a window rolled up brought down)
function H.hold()
    if not S.outWas or S.holdOff then return end
    local t = getTimestampMs() + 600000
    for _, k in ipairs({ "c", "w" }) do
        local w = H.win(k)
        if w then
            w._outSince = t
            if w.windowShaded then
                w._autoShaded = false
                pcall(function() w:setWindowShaded(false) end)
            end
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
        local md = S.p:getModData()
        local v = md.ZeD_GridViews and md.ZeD_GridViews[key]
        if v == nil then S.grid[key] = "none" else S.grid[key] = v end
    end
    pcall(ZeD.InventoryRenderer.setGridKey, key, false, S.p)
    return key
end
function H.gridBack()
    local md = S.p:getModData()
    if not md.ZeD_GridViews then return end
    for key, v in pairs(S.grid) do
        if v == "none" then md.ZeD_GridViews[key] = nil else md.ZeD_GridViews[key] = v end
    end
end
function H.gridSame()
    local md = S.p:getModData()
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
function H.colsOf(w)
    local out = {}
    for _, j in ipairs((w and w._mcSelected) or {}) do
        local e = w._containers and w._containers[j]
        if e then out[#out + 1] = e.inventory end
    end
    return out
end

-- ===================================================================== the lists: view, scroll, stacks, rows
function H.idxOf(w, inv)
    if inv == nil then return nil end
    for i, e in ipairs((w and w._containers) or {}) do if e.inventory == inv then return i end end
    return nil
end
function H.viewOf(w)
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
function H.sameView(w, v)
    if not (w and v) then return false end
    local now = H.viewOf(w)
    return now.vInv == v.vInv and now.aInv == v.aInv and now.cInv == v.cInv
end
function H.viewTo(w, v)
    if not (w and v) or H.sameView(w, v) then return end
    w._viewedContainer = H.idxOf(w, v.vInv)
    w._activeContainer = H.idxOf(w, v.aInv) or 1
    if v.mainVis ~= nil then w._mainVisible = v.mainVis end
    local c = w._mainContent
    if c then
        local e = w._containers and w._containers[w._viewedContainer or w._activeContainer]
        c._inventory = (e and e.inventory) or v.cInv
        c._selectedItems = {}
        c._lastClickedItem = nil
    end
end
function H.scrollBar(k) local c = H.content(k); return c and c._scroll or nil end
function H.scrollOf(k) local sc, s = H.scrollBar(k), nil; if sc then pcall(function() s = sc.scrollPos end) end; return s end
function H.scrollTo(k, pos) local sc = H.scrollBar(k); if pos ~= nil and sc then pcall(function() sc:setScrollPos(pos) end) end end
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
    if not (cg and c._sortCol == "cat") then return end
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
function H.rowShown(c, item)
    if not (c and item) then return false end
    local vis = false
    pcall(function() vis = c:isReallyVisible() and c:getWidth() > 0 end)
    if not vis then return false end
    local z = H.rowZone(c, item)
    if not z then return false end
    local rv = c._rowView
    local grid = c._gv ~= nil and c._gv.on == true
    if not grid and not (rv and rv.top and rv.bottom and z.y >= rv.top and z.y + z.h <= rv.bottom) then return false end
    local hit = nil
    pcall(function() hit = c:hitZoneAt(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end)
    return hit == z
end
function H.seekRow(k, item)
    local c = H.content(k)
    if not c then return false end
    if H.rowShown(c, item) then return true end
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

-- ===================================================================== the pointer (the one thing faked)
function H.atPointer(gx, gy, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return gx end
    getMouseY = function() return gy end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = ox, oy
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
function H.belt() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
-- is the screen point under the other ZeD window or the belt, drawn over owner? (a real press there lands on that)
function H.covered(owner, gx, gy)
    local oi = H.zIndex(owner)
    if not oi then return false end
    for _, c in ipairs({ RT.cw() or false, RT.ww() or false, H.belt() or false }) do
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
-- a left click on a list's row: down and up at its middle, never the second of a double-click
function H.click(k, item)
    local c = H.content(k)
    local z = H.rowZone(c, item)
    if not (c and z) then return false, "no row" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ax, ay = c:getAbsoluteX() + x, c:getAbsoluteY() + y
    local cov, by = H.covered(H.ownerOf(c), ax, ay)
    if cov then return false, "the row's middle is under the " .. tostring(by) end
    c._zedLastClick = nil
    return H.atPointer(ax, ay, function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
end
-- a press on a window's drawer at (x, y), its own coordinates (the zones a tab stamps): the drawer's own onMouseDown
-- (and onMouseUp when up), the pointer there. Returns ok, how, and true as a third value when the point is under
-- another window or the belt (a real click there lands on that: the caller says SKIP)
function H.press(k, x, y, up)
    local w = H.win(k)
    local d = w and w._drawerPanel
    if not d then return false, "the window has no drawer" end
    local ax, ay = d:getAbsoluteX() + x, d:getAbsoluteY() + y
    local cov, by = H.covered(w, ax, ay)
    if cov then return false, "the point " .. H.num(ax) .. "," .. H.num(ay) .. " is under the " .. tostring(by), true end
    local ok, err = H.atPointer(ax, ay, function()
        d:onMouseDown(x, y)
        if up then d:onMouseUp(x, y) end
    end)
    if not ok then return false, "the press threw: " .. tostring(err) end
    return true, "pressed at " .. H.num(ax) .. "," .. H.num(ay)
end
function H.pressZone(k, z, up) return H.press(k, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2), up) end

-- ===================================================================== wrappers (watching what ZeD draws)
-- tbl[key] wrapped by maker(orig); the group's wrappers taken off together
function H.wrap(tbl, key, maker, group)
    local orig = tbl and tbl[key]
    if type(orig) ~= "function" then return false end
    local fn = maker(orig)
    S.wraps[#S.wraps + 1] = { tbl = tbl, key = key, orig = orig, fn = fn, on = true, group = group }
    tbl[key] = fn
    return true
end
function H.unwrap(group)
    for _, w in ipairs(S.wraps) do
        if w.on and (group == nil or w.group == group) then
            if w.tbl[w.key] == w.fn then w.tbl[w.key] = w.orig end
            w.on = false
        end
    end
end
function H.wrapsBack()
    local bad = {}
    for _, w in ipairs(S.wraps) do if w.tbl[w.key] ~= w.orig then bad[#bad + 1] = tostring(w.key) end end
    return #bad == 0, bad
end

-- ===================================================================== the input mode ZeD reads (vx12_wheel.lua)
function H.lockFound()
    local key = nil
    local api = PZAPI and PZAPI.ModOptions
    local zo = (api and api.getOptions) and api:getOptions("ZeD_UI") or nil
    local o = zo and zo.dict and zo.dict.inputModeLock
    local keys = ZeD and ZeD.Settings and ZeD.Settings.inputLockKeys
    if o and o.getValue and keys then key = keys[o:getValue() or 1] end
    if key == nil and S.p then
        local md = S.p:getModData()
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

-- ===================================================================== the body (god mode off for the run)
-- (a stat the game has no name for is never asked: a nil handed to Java throws)
function H.stat(name)
    local v = nil
    local key = CharacterStat and CharacterStat[name]
    if key == nil then return nil end
    pcall(function() v = S.p:getStats():get(key) end)
    return v
end
function H.setStat(name, v)
    local key = CharacterStat and CharacterStat[name]
    if v == nil or key == nil then return end
    pcall(function() S.p:getStats():set(key, v) end)
end

-- ===================================================================== right-click menus, the pause screen
function M.v() return getPlayerContextMenu and getPlayerContextMenu(S.pn) or nil end
function M.up()
    local v = M.v()
    if not v then return false end
    local zm = v._zedMenu
    if zm and zm._ctx and zm._ctx.open then return true end
    local up = false
    if v.javaObject ~= nil then pcall(function() up = v:isVisible() end) end
    return up == true
end
-- the rows the menu was given, in order (the game's menu object's own; ZeD's list as it draws them when that is empty)
function M.names()
    local out = {}
    local v = M.v()
    if not v then return out end
    for i = 1, (tonumber(v.numOptions) or 1) - 1 do
        local o = v.options and v.options[i]
        if type(o) == "table" and o.name ~= nil then out[#out + 1] = tostring(o.name) end
    end
    if #out > 0 then return out end
    local zm = v._zedMenu
    if zm and zm._ctx and zm._ctx.actions then
        for _, a in ipairs(zm._ctx.actions) do if type(a) == "table" then out[#out + 1] = tostring(a.name) end end
    end
    return out
end
function M.close()
    local v = M.v()
    if not v then return end
    local zm = v._zedMenu
    if zm and zm.close then pcall(zm.close, zm) end
    if not v._zedMenu and v.javaObject ~= nil and v.closeAll then
        local vis = false
        pcall(function() vis = v:isVisible() end)
        if vis then pcall(v.closeAll, v) end
    end
end
function M.pauseUp()
    local ms = MainScreen and MainScreen.instance
    local v = false
    if ms then pcall(function() v = ms:isVisible() end) end
    return v and true or false
end
function M.escape() return pcall(function() ToggleEscapeMenu(Keyboard.KEY_ESCAPE) end) end
function M.unpause()
    if not M.pauseUp() then return end
    pcall(function()
        local key = nil
        if KeybindId and KeybindId.MAIN_MENU then key = getCore():getKey(KeybindId.MAIN_MENU) end
        if key == nil or key == 0 then key = Keyboard.KEY_ESCAPE end
        ToggleEscapeMenu(key)
    end)
end

-- ===================================================================== the Crafting and Building tabs (k "b": Building)
function C.st(k) local w = RT.ww(); if not w then return nil end; if k == "b" then return w._buildState end; return w._craftState end
function C.data(k) local w = RT.ww(); if not w then return nil end; if k == "b" then return w._buildCache end; return w._craftCache end
function C.geo(k) local st = C.st(k); return st and st._listGeo or nil end
function C.row(name, k) local d = C.data(k); if not (d and d.byName and name) then return nil end; return d.byName[name] end
function C.showing(id) local s = false; pcall(function() s = ZeD_WorldWindow.isTabShowing(id, S.pn) end); return s and true or false end
function C.zone(name, k)
    local st = C.st(k)
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == "recipeRow" and z.id == name and z.w > 0 and z.h > 0 then return z end
    end
    return nil
end
function C.zoneOf(kind, k)
    local st = C.st(k)
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and (z.w or 0) > 0 and (z.h or 0) > 0 then return z end
    end
    return nil
end
-- the amount's zones on the band (the - n +, its one box, Max)
function C.amountZones(k)
    local out = {}
    local st = C.st(k)
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == "action_dec" or z.type == "action_inc" or z.type == "action_qty" or z.type == "action_max" then out[#out + 1] = z.type end
    end
    return out
end
function C.inView(z, k)
    local g = C.geo(k)
    return g ~= nil and z ~= nil and g.viewY ~= nil and z.y >= g.viewY and z.y + z.h <= g.viewY + g.viewH
end
function C.rowsInView(k)
    local out, seen = {}, {}
    local st = C.st(k)
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == "recipeRow" and z.w > 0 and z.h > 0 and not seen[z.id] and C.inView(z, k) then
            seen[z.id] = true
            out[#out + 1] = z
        end
    end
    return out
end
function C.rowH() local h = 24; pcall(function() h = ZeD.T.px(ZeD.CraftingCore.ROW_H) end); return h end
function C.place(name, relT, k)
    local st, g, z = C.st(k), C.geo(k), C.zone(name, k)
    if not (st and g and z and st.scroll and st.scroll.setScrollPos) then return false end
    local off = math.floor((st.scroll.scrollPos or 0) * math.max(0, (g.totalH or 0) - (g.viewH or 0)))
    local span = (g.totalH or 0) - (g.viewH or 0)
    if span <= 0 then return true end
    local want = (z.y - g.viewY) + off - relT
    if want < 0 then want = 0 end
    if want > span then want = span end
    st.scroll:setScrollPos((want + 0.5) / span)
    return true
end
function C.mid(k)
    local g = C.geo(k)
    if not g then return 0 end
    return math.max(0, math.floor(((g.viewH or 0) - C.rowH()) / 2))
end
function C.pressRow(name, k)
    local z = C.zone(name, k)
    if not (z and C.inView(z, k)) then return false, "its row is not in the list's view" end
    return H.pressZone("w", z, false)
end
function C.keepState(st)
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, req = st.reqCollapsed, out = st.outCollapsed,
        all = st.allCollapsed, pin = st.pinnedCollapsed, freq = st.freqCollapsed, owned = st.ownedOnly, search = st.search or "",
        sel = st.selected, picks = st.picks, qty = st.qty, scroll = (st.scroll and st.scroll.scrollPos) or 0 }
end
function C.setSearch(st, text)
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    if f and f.input then
        pcall(function() f.input:setText(text) end)
        f._lastText = text
    end
    st.search, st.filterDirty = text, true
end
function C.shut(k)
    local st = C.st(k)
    if not st then return end
    if st.altSlotName then pcall(ZeD.CraftingCore.exitAltMode, st) end
    if st.selected then pcall(ZeD.CraftingCore.closeCraft, st) end
end
function C.stateBack()
    local T = S.c
    local st, k = C.st(), T.keep
    if not (st and k and T.seen) then return end
    pcall(function()
        st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
        st.reqCollapsed, st.outCollapsed, st.allCollapsed = k.req and true or false, k.out and true or false, k.all and true or false
        st.pinnedCollapsed, st.freqCollapsed, st.ownedOnly = k.pin and true or false, k.freq and true or false, k.owned and true or false
        st.qty, st.filterDirty, st._sectionsStale = k.qty or 1, true, true
        st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
        if T.searchWas or (st.search or "") ~= (k.search or "") then C.setSearch(st, k.search or "") end
    end)
end
function C.cardBack()
    local T = S.c
    local st, k = C.st(), T.keep
    if not (st and k and T.seen) then return end
    pcall(function()
        if k.sel and st.selected ~= k.sel then ZeD.CraftingCore.openCraft(st, k.sel) end
        if not k.sel and st.selected then ZeD.CraftingCore.closeCraft(st) end
    end)
    pcall(function() st.picks = k.picks or {}; st.qty = k.qty or 1 end)
    pcall(function() st.scroll:setScrollPos(k.scroll or 0) end)
end
function C.stationBack()
    local T = S.c
    if T.stWas and not T.stBack then
        T.stBack = true
        pcall(function() ZeD.Stations.bind(S.p, T.stWas) end)
    end
end
-- a station in reach: one bound, or one the stations' scan finds near him
function C.stationInReach()
    local r = false
    pcall(function()
        if ZeD.Stations.current(S.p) ~= nil then r = true; return end
        local l = ZeD.Stations.nearby(S.p)
        r = type(l) == "table" and #l > 0
    end)
    return r
end
-- the Building tab's state object as found (set aside for #17, put back at the end)
function C.buildBack()
    local T = S.b
    if not T.taken or T.backDone then return end
    T.backDone = true
    local w = RT.ww()
    if w then w._buildState = T.was end
end

-- ===================================================================== the Journal's Recipes page
function J.st() local w = RT.cw(); return w and w._jrecipeState or nil end
function J.zoneOf(kind)
    local st = J.st()
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and (z.w or 0) > 0 and (z.h or 0) > 0 then return z end
    end
    return nil
end
-- the recipe for the page: Open Box (a hand craft he knows), else the first craft recipe the page holds
function J.pick()
    local w = RT.cw()
    local d = w and w._jrecipeCache
    local first = nil
    for _, rd in ipairs((d and d.recipes) or {}) do
        local e = rd.entry
        if e and e.recipe ~= nil and e.source ~= "build" then
            if e.name == "OpenBox100" then return e.name end
            if not first then first = e.name end
        end
    end
    return first
end
function J.putBack()
    local T = S.j
    if not T.taken or T.backDone then return end
    T.backDone = true
    local w = RT.cw()
    local st = J.st()
    if st then
        pcall(function()
            if T.selWas and st.selected ~= T.selWas then ZeD.CraftingCore.openCraft(st, T.selWas)
            elseif not T.selWas and st.selected then ZeD.CraftingCore.closeCraft(st) end
            st.filterDirty = true
        end)
    end
    if w and T.subWas and w._journalSubTab ~= T.subWas then pcall(ZeD.JournalTab.setPage, w, T.subWas) end
end

-- ===================================================================== the cards
U.KINDS = {
    { key = "band", ft = "Base.Bandage", word = "the bandage" },
    { key = "pills", ft = "Base.Pills", word = "the painkillers" },
    { key = "pa", ft = "Base.Pistol", word = "the worn pistol" },
}
function U.card() local w = RT.cw(); return w and w._itemCard end
function U.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function U.label(k, id)
    for _, v in ipairs(k.verbs or {}) do if v.id == id then return v.label end end
    return nil
end
function U.verbsText(k)
    if not k.read then return k.word .. "'s card not read (" .. tostring(k.why) .. ")" end
    local out = {}
    for _, v in ipairs(k.verbs or {}) do out[#out + 1] = v.id .. " \"" .. v.label .. "\"" end
    return k.word .. "'s card drew [" .. table.concat(out, ", ") .. "]"
end
-- the fixer a repair spends first: the first fixer of the first fixing he has, named as the game's Fix menu names it
-- (ISInventoryPaneContextMenu.addFixerSubOption: the module's name and the fixer's, the item's name when it has a picture)
function U.fixerName(item)
    local nm = nil
    pcall(function()
        local list = FixingManager.getFixes(item)
        if not list or list:isEmpty() then return end
        for fi = 0, list:size() - 1 do
            local fixing = list:get(fi)
            local fx = fixing:getFixers()
            for xi = 0, fx:size() - 1 do
                local fixer = fx:get(xi)
                if fixing:haveThisFixer(S.p, fixer, item) then
                    local raw = tostring(fixer:getFixerName())
                    local full = tostring(fixing:getModule():getName()) .. "." .. raw
                    nm = raw
                    if getItemTex(full) then
                        local dn = getItemNameFromFullType(full)
                        if dn and dn ~= "" then nm = tostring(dn) end
                    end
                    return
                end
            end
        end
    end)
    return nm
end
-- one card: its row found and clicked, the card opened on it, four frames drawn, its verbs (and the care band's
-- Repair help, when the watch saw it for this card) read
function U.queueRead(k)
    Q.step(2, function()
        local it = S.u[k.key]
        k.arm = S.u.go == true and it ~= nil
        k.read, k.why, k.rep = false, nil, nil
        S.seek.c = nil
        if not it then k.why = "it could not be given" end
        if not k.arm then return end
        local c = H.content("c")
        local vis = false
        if c then pcall(function() vis = c:isReallyVisible() and c:getWidth() > 0 end) end
        if not vis then H.shutCard("c") end
    end)
    H.wait(8000, function() return not k.arm or H.seekRow("c", S.u[k.key]) end, function(ok)
        if not k.arm then return end
        if not ok then k.arm = false; k.why = "its row is not on view in his list"; return end
        local okC, err = H.click("c", S.u[k.key])
        if not okC then k.arm = false; k.why = "the click on its row failed: " .. tostring(err) end
    end)
    H.wait(4000, function()
        if not k.arm then return true end
        local c = U.card()
        return U.cardOn(S.u[k.key]) and c._lastHeaderVerbs ~= nil
    end, function(ok)
        if not k.arm then return end
        if not ok then
            k.arm = false
            local w = RT.cw()
            k.why = "its card did not open on it (the card shows " .. H.nm(w and w._drawerItem) .. ")"
        end
    end)
    Q.step(4, function()
        if not k.arm then return end
        local c = U.card()
        local it = S.u[k.key]
        if not U.cardOn(it) then k.why = "its card closed before it was read"; return end
        k.verbs = {}
        for _, v in ipairs(c._lastHeaderVerbs or {}) do
            if type(v) == "table" then k.verbs[#k.verbs + 1] = { id = tostring(v.id), label = tostring(v.label) } end
        end
        local rep = S.u.rep
        if rep and rep.item == it and getTimestampMs() - (rep.t or 0) < 2000 then k.rep = rep end
        k.read = true
    end)
end

-- ===================================================================== the Health tab
D.PARTS = { { t = "ForeArm_L", name = "Left Forearm" }, { t = "ForeArm_R", name = "Right Forearm" },
            { t = "UpperArm_L", name = "Left Upper Arm" }, { t = "UpperArm_R", name = "Right Upper Arm" } }
function D.bpOf(tname)
    local b = nil
    pcall(function()
        local bd = S.p:getBodyDamage()
        local t = BodyPartType[tname]
        if bd and t then b = bd:getBodyPart(t) end
    end)
    return b
end
-- nothing to treat on it: no wound, bandage, stitches, splint, glass or bullet
function D.clean(e)
    local b = D.bpOf(e.t)
    local c = false
    if b then
        pcall(function()
            c = not b:HasInjury() and not b:bandaged() and not b:stitched() and b:getSplintFactor() <= 0 and b:getFractureTime() <= 0
                and not b:haveGlass() and not b:haveBullet()
        end)
    end
    return c
end
function D.pick(skip)
    for _, e in ipairs(D.PARTS) do
        if e ~= skip and D.clean(e) then return e end
    end
    return nil
end
function D.panel() local w = RT.cw(); return w and w._healthContentPanel end
function D.fig() local w = RT.cw(); return w and w._healthBodyFigure end
function D.tabUp()
    local w = RT.cw()
    local p = D.panel()
    local vis = false
    if p then pcall(function() vis = p:isReallyVisible() end) end
    return w ~= nil and w._drawerMode == "tab" and w._activeTab == "health" and (w._drawerEffW or 0) > 0 and vis and p == w._drawerPanel
end
function D.rowZone(name)
    local w = RT.cw()
    for _, z in ipairs((w and w._healthInjuryZones) or {}) do if z.bodyPartName == name then return z end end
    return nil
end
-- a point (the tab's own pixels) a press lands on: in the tab's view, under its pinned header, above its band, left of
-- its bar, not under the World window or the belt. True and the screen point, or false.
function D.okPoint(lx, ly)
    local w = RT.cw()
    local p = D.panel()
    if not (w and p) then return false end
    local v = w._healthView
    if v and not (lx >= v.x and lx < v.x + v.w and ly >= v.y and ly < v.y + v.h) then return false end
    if w._healthBandY and ly >= w._healthBandY then return false end
    local fz = w._healthFigureZone
    if fz and ly < fz.y + fz.h then return false end
    local sc = w._healthScroll
    if sc and sc.visible and lx >= sc.x then return false end
    if lx < 0 or ly < 0 or lx >= p:getWidth() or ly >= p:getHeight() then return false end
    local xs, ys = 0, 0
    local jo = p.javaObject
    if jo then pcall(function() xs, ys = jo:getXScroll(), jo:getYScroll() end) end
    local gx, gy = p:getAbsoluteX() + xs + lx, p:getAbsoluteY() + ys + ly
    if H.covered(w, gx, gy) then return false end
    return true, gx, gy
end
function D.figurePoint(name)
    local fig, w = D.fig(), RT.cw()
    if not (fig and w and w._healthFigureExpanded) then return nil, "the figure is folded or not drawn" end
    local rects = nil
    pcall(function() rects = fig:getPartRects() end)
    local r = nil
    for _, e in ipairs(rects or {}) do if e.name == name then r = e end end
    if not r then return nil, "the figure has no " .. tostring(name) .. " drawn" end
    local tries = { { 0.5, 0.5 } }
    for i = 1, 5 do for j = 1, 5 do tries[#tries + 1] = { (i - 0.5) / 5, (j - 0.5) / 5 } end end
    for _, t in ipairs(tries) do
        local lx, ly = r.x + math.floor(r.w * t[1]), r.y + math.floor(r.h * t[2])
        local hit = nil
        pcall(function() hit = fig:hitTestAt(lx, ly) end)
        if hit == name then
            local ok, gx, gy = D.okPoint(lx, ly)
            if ok then return { lx = lx, ly = ly, gx = gx, gy = gy } end
        end
    end
    return nil, "no point of the " .. tostring(name) .. " on the figure is in the tab's view and uncovered"
end
-- a point of the part's wound row, off the figure
function D.rowPoint(name)
    local z = D.rowZone(name)
    if not z then return nil, "no wound row for the " .. tostring(name) end
    local fig, w = D.fig(), RT.cw()
    for _, t in ipairs({ { 0.25, 0.5 }, { 0.5, 0.5 }, { 0.75, 0.5 }, { 0.5, 0.25 }, { 0.5, 0.75 } }) do
        local lx, ly = z.x + math.floor(z.w * t[1]), z.y + math.floor(z.h * t[2])
        local onFig = nil
        if fig and w and w._healthFigureExpanded then pcall(function() onFig = fig:hitTestAt(lx, ly) end) end
        if not onFig then
            local ok, gx, gy = D.okPoint(lx, ly)
            if ok then return { lx = lx, ly = ly, gx = gx, gy = gy } end
        end
    end
    return nil, "its wound row is not in the tab's view"
end
function D.seekRowView(name)
    if D.rowPoint(name) then return true end
    local w = RT.cw()
    local sc = w and w._healthScroll
    if sc and sc.visible and sc.setScrollPos then
        local at = S.d.seek
        if at == nil or at >= 1 then at = 0 else at = math.min(1, at + 0.1) end
        S.d.seek = at
        pcall(function() sc:setScrollPos(at) end)
    end
    return false
end
-- a left click where a click lands: the drawer's own onMouseDown and onMouseUp at the point, the pointer there
function D.press(pt)
    local w = RT.cw()
    local d = w and w._drawerPanel
    if not d then return false, "the Character window has no drawer" end
    M.close()
    local ok, err = H.atPointer(pt.gx, pt.gy, function() d:onMouseDown(pt.lx, pt.ly); d:onMouseUp(pt.lx, pt.ly) end)
    if not ok then return false, "the press threw: " .. tostring(err) end
    return true, "clicked at " .. H.num(pt.gx) .. "," .. H.num(pt.gy)
end
function D.noInfection(b)
    if b then
        pcall(function() if b:IsInfected() then b:SetInfected(false) end end)
        pcall(function() if b:IsFakeInfected() then b:SetFakeInfected(false) end end)
        pcall(function() b:setInfectedWound(false) end)
        pcall(function() b:setWoundInfectionLevel(0) end)
    end
    local bd = nil
    pcall(function() bd = S.p:getBodyDamage() end)
    if bd then
        pcall(function() if bd:isInfected() then bd:setInfected(false) end end)
        pcall(function() if bd:isIsFakeInfected() then bd:setIsFakeInfected(false) end end)
    end
end
function D.wound(b)
    if not b then return false end
    pcall(function() b:setScratched(true, true) end)
    pcall(function() b:setScratchTime(15) end)
    D.noInfection(b)
    local s = false
    pcall(function() s = b:scratched() end)
    return s and true or false
end
function D.heal(b)
    if b then
        pcall(function() b:setScratched(false, true) end)
        pcall(function() b:setScratchTime(0) end)
        pcall(function() b:setBleeding(false) end)
        pcall(function() b:setBleedingTime(0) end)
        pcall(function() if b:bandaged() then b:setBandaged(false, 0) end end)
        pcall(function() b:setAdditionalPain(0) end)
        pcall(function() b:RestoreToFullHealth() end)
    end
    D.noInfection(b)
end
function D.woundBp() return S.d.part and D.bpOf(S.d.part.t) or nil end
-- the guard, every game tick while god mode is off: no infection; health under 80 or the run's time out and the
-- part is healed and god mode put on (the game then heals the rest)
function D.guard()
    local T = S.d
    if not T.guardOn then pcall(function() Events.OnTick.Remove(D.guard) end); return end
    D.noInfection(D.woundBp())
    local h, dead = 100, false
    pcall(function() h = S.p:getBodyDamage():getOverallBodyHealth() end)
    pcall(function() dead = S.p:isDead() end)
    if dead or h < 80 or getTimestampMs() - (T.guardT0 or 0) > Q.maxMs + 60000 then
        T.tripped = dead and "dead" or ("health " .. H.num(h) .. " after " .. H.num((getTimestampMs() - (T.guardT0 or 0)) / 1000) .. " s")
        D.heal(D.woundBp())
        pcall(function() S.p:setGodMod(true) end)
        T.guardOn = false
        pcall(function() Events.OnTick.Remove(D.guard) end)
    end
end
function D.still()
    local w = RT.cw()
    local e = math.floor((w and w._drawerEffW) or 0)
    if e == S.d.lastW then S.d.same = (S.d.same or 0) + 1 else S.d.same, S.d.lastW = 0, e end
    return S.d.same >= 10
end
function D.putBack()
    local T = S.d
    if T.backDone or not T.staged then return end
    T.backDone = true
    M.close()
    D.heal(D.woundBp())
    if T.cheatSet then ISHealthPanel.cheat = S.was.cheat; T.cheatSet = false end
    local w = RT.cw()
    if w then
        if T.foldWas ~= nil then w._healthFigureExpanded = T.foldWas end
        if T.scrollWas ~= nil and w._healthScroll then pcall(function() w._healthScroll:setScrollPos(T.scrollWas) end) end
    end
end

-- ===================================================================== the stove
V.STOVES = { "appliances_cooking_01_0", "appliances_cooking_01_8" }
function V.freeSq()
    local cell = getCell()
    local here = S.p:getCurrentSquare()
    if not (cell and here) then return nil end
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = cell:getGridSquare(x + d[1], y + d[2], z)
        local ok = false
        if sq then
            pcall(function()
                ok = sq:isFree(false) and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0
                    and sq:getVehicleContainer() == nil and here:canReachTo(sq)
            end)
        end
        if ok then return sq end
    end
    return nil
end
-- a stove on a square (bxr_menus.lua S.placeStove): the object and its sprite's name, or nil
function V.place(sq)
    for _, name in ipairs(V.STOVES) do
        local spr = getSprite(name)
        if spr then
            local o = nil
            pcall(function()
                o = IsoStove.new(getCell(), sq, spr)
                pcall(function() o:createContainersFromSpriteProperties() end)
                sq:AddSpecialObject(o)
                if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
            end)
            local on = false
            pcall(function() on = o ~= nil and sq:getObjects():contains(o) end)
            if on then return o, name end
            if o then V.remove(o) end
        end
    end
    return nil
end
function V.remove(o)
    if not o then return end
    local sq = nil
    pcall(function() sq = o:getSquare() end)
    if sq then
        pcall(function() if sq:getObjects():contains(o) then sq:RemoveTileObject(o, false) end end)
        pcall(function() if sq:getObjects():contains(o) then sq:transmitRemoveItemFromSquare(o, false) end end)
    end
end
function V.stands(o)
    local up = false
    if o then pcall(function() up = o:getSquare() ~= nil and o:getSquare():getObjects():contains(o) end) end
    return up and true or false
end
function V.on(o) local on = false; if o then pcall(function() on = o:Activated() and true or false end) end; return on end
function V.bound(o)
    local b = false
    if o then pcall(function() local cur = ZeD.Stations.current(S.p); b = cur ~= nil and cur.obj == o end) end
    return b
end
function V.face(o)
    local f = false
    if o then pcall(function() f = ZeD.TwoWayFull.showingObj(S.pn, o) and true or false end) end
    return f
end
function V.putBack()
    local T = S.v
    if T.backDone then return end
    T.backDone = true
    H.unwrap("v58")
    local o = T.obj
    if not o then return end
    if V.on(o) then pcall(function() o:Toggle() end) end
    if V.face(o) then pcall(ZeD.TwoWayFull.close, S.pn) end
    if V.bound(o) then pcall(ZeD.Stations.unbind, S.p) end
    V.remove(o)
end

-- ===================================================================== the moodles
function MO.layer() local L = nil; pcall(function() L = ZeD.Moodles.getLayer(S.pn) end); return L end
function MO.idx(key)
    local L = MO.layer()
    for i, m in ipairs((L and L._list) or {}) do if m.key == key then return i end end
    return nil
end
-- a click on moodle key: the layer's own onMouseDown and onMouseUp at its middle, the pointer there and the layer
-- answering yes to isMouseOver (the engine's picking reads the real pointer). Returns ok, how, the press's answer;
-- a fourth value true when the moodle is under a window or the belt (SKIP)
function MO.click(key)
    local L = MO.layer()
    local i = MO.idx(key)
    if not (L and i) then return false, "no " .. key .. " moodle on the layer" end
    if not L._show then return false, "the moodles are not shown" end
    local sx, sy = L:_slotXY(i)
    local size = L._size or 32
    local lx, ly = sx + math.floor(size / 2), sy + math.floor(size / 2)
    local gx, gy = L:getAbsoluteX() + lx, L:getAbsoluteY() + ly
    local cov, by = H.covered(L, gx, gy)
    if cov then return false, "the moodle is under the " .. tostring(by), nil, true end
    M.close()
    local saved = rawget(L, "isMouseOver")
    L.isMouseOver = function() return true end
    local took = nil
    local ok, err = H.atPointer(gx, gy, function()
        took = L:onMouseDown(lx, ly)
        L:onMouseUp(lx, ly)
    end)
    L.isMouseOver = saved
    if not ok then return false, "the click threw: " .. tostring(err) end
    return true, "clicked at " .. H.num(gx) .. "," .. H.num(gy), took
end
-- the pad wheel's list for Eat or Drink (ZeD_DpadWheels H.quick), its names in order
function MO.wheel(gid)
    local out = {}
    pcall(function()
        for _, e in ipairs(ZeD.DpadWheels.H.quick(S.p, gid) or {}) do out[#out + 1] = tostring(e.name) end
    end)
    return out
end
-- one moodle's check: queued steps (the menu read 1 s at most after the click)
function MO.queueCheck(key, gid, word)
    local T = S.m
    local R = {}
    T[key] = R
    Q.step(2, function()
        if not T.go then return end
        R.list = MO.wheel(gid)
        R.label = "#49: a click on the " .. word .. " moodle opens the pad wheel's " .. gid .. " list as a menu, in its order, the best pick first"
            .. " (old code: the click passes through, nothing opens)"
        if not MO.idx(key) then R.skip = "no " .. word .. " moodle shows (the moodle list: " .. MO.keys() .. ")"; return end
        if #R.list == 0 then R.skip = "the wheel's " .. gid .. " list is empty: he carries nothing it would offer"; return end
        local ok, how, took, cov = MO.click(key)
        R.how, R.took = how, took
        if cov then R.skip = how; return end
        if not ok then R.why = how; return end
        R.go = true
    end)
    H.wait(1000, function() return not R.go or M.up() end, function(up)
        if not T.go then return end
        if R.skip then Q.skip(R.label or ("#49: " .. word), R.skip); return end
        if not R.go then Q.check(false, R.label, "not clicked: " .. tostring(R.why)); return end
        local names = M.names()
        local same = #names == #R.list
        for i, n in ipairs(R.list) do if not H.starts(names[i], n) then same = false end end
        Q.check(R.took == true and up and same,
            R.label,
            tostring(R.how) .. "; the press taken " .. tostring(R.took) .. "; a menu up " .. tostring(up) .. " with [" .. H.list(names)
            .. "]; the wheel's list [" .. H.list(R.list) .. "]")
        M.close()
    end)
end
function MO.keys()
    local L = MO.layer()
    local out = {}
    for _, m in ipairs((L and L._list) or {}) do out[#out + 1] = tostring(m.key) end
    return table.concat(out, " ")
end

-- ===================================================================== start: what was found
Q.step(3, function()
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then S.dead = true; Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    local ready = ZeD ~= nil and ZeD.CraftingCore ~= nil and ZeD.CraftingTab ~= nil and ZeD.BuildingTab ~= nil and ZeD.JournalTab ~= nil
        and ZeD.HealthTab ~= nil and ZeD.Moodles ~= nil and ZeD.Moodles.getLayer ~= nil and ZeD.Belt ~= nil and ZeD.Belt.ammo ~= nil
        and ZeD.Belt.ammoLines ~= nil and ZeD.Stations ~= nil and ZeD.Molecules ~= nil and ZeD.Atoms ~= nil and ZeD.DpadWheels ~= nil
        and ZeD.DpadWheels.H ~= nil and ZeD.TwoWayFull ~= nil and ZeD.InventoryRenderer ~= nil and ZeD_CharacterWindow ~= nil
        and ZeD_WorldWindow ~= nil and ISTimedActionQueue ~= nil and ToggleEscapeMenu ~= nil and ISWorldObjectContextMenu ~= nil
        and ISWorldObjectContextMenu.onToggleStove ~= nil and ISToggleStoveAction ~= nil and ISHealthPanel ~= nil and CharacterStat ~= nil
        and S.Det ~= nil and S.Det.setLockedMode ~= nil and S.Det.getMode ~= nil
    if not Q.check(ready, "ZeD's Crafting, Building, Journal and Health tabs, moodles, belt, stations, wheels, the game's key handler and the input lock are loaded") then
        S.dead = true
        return
    end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vk3_cft") end
    S.was.char, S.was.world = H.charOpen(), H.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = S.was.char and H.geo(cw) or nil, w = S.was.world and H.geo(ww) or nil }
    S.was.tab = { c = (S.was.char and cw) and (cw._activeTab or "loot") or nil, w = (S.was.world and ww) and (ww._activeTab or "loot") or nil }
    local md = S.p:getModData()
    S.was.ws = { had = md.ZeD_WinState ~= nil, v = H.copy(md.ZeD_WinState) }
    S.was.speed = getGameSpeed()
    S.was.hand = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
    pcall(function() S.was.god = S.p:isGodMod() and true or false end)
    pcall(function() S.was.inv = S.p:isInvincible() and true or false end)
    pcall(function() S.was.health = S.p:getBodyDamage():getOverallBodyHealth() end)
    S.was.hunger, S.was.thirst = H.stat("HUNGER"), H.stat("THIRST")
    S.was.cheat = ISHealthPanel.cheat
    S.was.pause = M.pauseUp()
    S.was.mode = H.mode()
    S.lockWas = H.lockFound()
    H.clearQueue()
    H.lock("kbm")
    -- god mode off for the run (with it the game heals a wound at once), invincible on, the guard every tick
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    S.d.guardT0, S.d.guardOn = getTimestampMs(), true
    Events.OnTick.Add(D.guard)
    S.bodySet = true
    H.openBoth()
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(ZeD.T and ZeD.T.scale)
        .. "; Character window open " .. tostring(S.was.char) .. " (" .. H.gs(S.was.geo.c) .. ", on " .. tostring(S.was.tab.c) .. "), World window open "
        .. tostring(S.was.world) .. " (" .. H.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w) .. "); game speed " .. H.num(S.was.speed)
        .. "; god mode " .. tostring(S.was.god) .. ", invincible " .. tostring(S.was.inv) .. ", health " .. H.num(S.was.health)
        .. ", hunger " .. H.num(S.was.hunger) .. ", thirst " .. H.num(S.was.thirst) .. "; the Health tab's cheat entries " .. tostring(S.was.cheat)
        .. "; Input lock " .. tostring(S.lockWas) .. ", ZeD reads " .. tostring(S.was.mode) .. "; in his hands " .. H.nm(S.was.hand.p) .. " / " .. H.nm(S.was.hand.s))
end)
H.wait(6000, function() return S.dead or H.both() end, function(ok)
    if S.dead then return end
    if not ok then
        S.dead = true
        Q.check(false, "the scene: both windows open (staging)", "Character " .. tostring(H.charOpen()) .. ", World " .. tostring(H.worldOpen()))
        return
    end
    local cw, ww = RT.cw(), RT.ww()
    S.outWas = { c = cw._outSince, w = ww._outSince }
    S.was.shaded = { c = cw.windowShaded and true or false, w = ww.windowShaded and true or false }
    S.was.rolled = { c = cw._rolled and true or false, w = ww._rolled and true or false }
    local CU = ZeD.Curtain
    if cw._rolled and CU and CU.finishUnroll then pcall(CU.finishUnroll, cw) end
    if ww._rolled and CU and CU.finishUnroll then pcall(CU.finishUnroll, ww) end
    H.hold()
    S.cols = { c = H.colsOf(cw), w = H.colsOf(ww) }
    if #S.cols.c > 0 then pcall(ZeD_CharacterWindow.closeColumns, cw) end
    if #S.cols.w > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
    S.view0 = { c = H.viewOf(cw), w = H.viewOf(ww) }
    S.scroll0 = { c = H.scrollOf("c"), w = H.scrollOf("w") }
    S.card0 = { c = cw._drawerItem, w = ww._drawerItem }
    H.viewTo(cw, { aInv = H.main(), cInv = H.main(), mainVis = true })
    H.listView(H.main())
    H.unfoldAll("c")
    S.ready = true
end)

-- ===================================================================== #54: Jammed names the Rack key (the belt's hover)
Q.step(3, function()
    local T = S.g
    if not S.ready then return end
    local label = "#54: a jammed gun in his hand: the belt's hover line reads \"Jammed, press <his Rack Firearm key>\" (old code: \"Jammed: <gun>\")"
    pcall(function()
        local code = getCore():getKey("Rack Firearm")
        if code and code ~= 0 then T.key = getKeyName(code) end
    end)
    if not (T.key and T.key ~= "") then Q.skip(label, "the Rack Firearm key is not bound here"); return end
    T.gun = H.give("Base.Pistol")
    if not T.gun then Q.check(false, "#54: a pistol is given (staging)"); return end
    pcall(function() S.p:setPrimaryHandItem(T.gun) end)
    pcall(function() T.gun:setJammed(true) end)
    local jam = false
    pcall(function() jam = T.gun:isJammed() and true or false end)
    local a, l1, l2 = nil, nil, nil
    pcall(function() a = ZeD.Belt.ammo(S.p) end)
    if a then pcall(function() l1, l2 = ZeD.Belt.ammoLines(a) end) end
    local want = ZeD.tr("UI_ZeD_JammedKey", tostring(T.key))
    Q.check(jam and a ~= nil and H.starts(l1, want) and H.has(l1, tostring(T.key)), label,
        "the gun " .. H.nm(T.gun) .. " in his hand " .. tostring(S.p:getPrimaryHandItem() == T.gun) .. ", jammed " .. tostring(jam)
        .. "; the belt reads it " .. tostring(a ~= nil) .. "; its hover lines \"" .. tostring(l1) .. "\" / \"" .. tostring(l2) .. "\"; want \"" .. tostring(want) .. "...\"")
    pcall(function() T.gun:setJammed(false) end)
    H.handsBack()
    H.removeItem(T.gun)
end)

-- ===================================================================== the Crafting tab, staged
Q.step(5, function()
    local T = S.c
    if not S.ready then return end
    local w = RT.ww()
    if not w then return end
    pcall(function()
        local cur = ZeD.Stations.current(S.p)
        if cur then
            T.stWas = cur
            ZeD.Stations.unbind(S.p)
            Q.say("NOTE: a station was bound: unbound for the run, bound again after")
        end
    end)
    if w._craftState then T.keep = C.keepState(w._craftState) end
    -- (the Character window on its list: a recipe card it draws on its Journal would be a second card for Escape)
    H.tab("c", "loot")
    H.tab("w", "craft")
    T.go = true
end)
H.wait(8000, function()
    local T = S.c
    if not T.go then return true end
    local st = C.st()
    return C.showing("craft") and st ~= nil and C.data() ~= nil and st.filteredCache ~= nil and C.geo() ~= nil
end, function(ok)
    local T = S.c
    if not T.go then return end
    local st = C.st()
    if not (ok and st) then
        T.go = false
        local w = RT.ww()
        Q.check(false, "the World window shows its Crafting tab with its list (staging)", "on " .. tostring(w and w._activeTab))
        return
    end
    T.seen = true
    T.keep = T.keep or C.keepState(st)
    C.shut()
    pcall(ZeD.CraftingCore.setShow, st, "all")
    st.activeCat, st.allCollapsed, st.pinnedCollapsed, st.freqCollapsed = "all", false, false, false
    st.filterDirty, st._sectionsStale = true, true
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    local typed = ""
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    if f then pcall(function() typed = f:getText() or "" end) end
    if typed ~= "" or (st.search or "") ~= "" then
        T.searchWas = true
        C.setSearch(st, "")
    end
end)
H.settle(1500, 9000, function()
    local st = C.st()
    return not S.c.go or (st ~= nil and st.filterDirty == false and #(st.filteredCache or {}) > 0)
end, function(ok)
    if S.c.go and not ok then Q.say("NOTE: the Crafting list did not settle in 9 s") end
end)

-- ===================================================================== #48: no title row; the Station box only with a station
Q.step(2, function()
    local T = S.c
    if not T.go then return end
    local W = { title = 0, titleH = 0, hdr = 0 }
    T.w48 = W
    H.wrap(ZeD.CraftingCore, "renderTabTitle", function(orig) return function(panel, x, y, w, config)
        local h = orig(panel, x, y, w, config)
        if type(config) == "table" and config.prefix == "craft" then
            W.title = W.title + 1
            if (tonumber(h) or 0) > 0 then W.titleH = W.titleH + 1 end
        end
        return h
    end end, "c48")
    H.wrap(ZeD.CraftingCore, "renderStaticHeader", function(orig) return function(panel, x, y, w, state, config, win)
        if type(config) == "table" and config.prefix == "craft" then W.hdr = W.hdr + 1 end
        return orig(panel, x, y, w, state, config, win)
    end end, "c48")
end)
H.pause(800)
Q.step(1, function()
    local T = S.c
    if not T.go then return end
    local W = T.w48
    H.unwrap("c48")
    Q.check(W.hdr > 0 and W.title == 0,
        "#48: the Crafting tab's header is drawn with no title row over it (old code: a \"Crafting\" row under the window's own title)",
        "headers drawn " .. W.hdr .. ", title rows asked " .. W.title .. " (" .. W.titleH .. " of them drawn tall)")
    local inReach = C.stationInReach()
    local box = C.zoneOf("stationDropdown")
    local label = "#48: with no station in reach the header has no Station box (old code: \"Station: Hand\" always)"
    if inReach then
        Q.skip(label, "a station stands in reach here (the box shows then, as before); the box drawn " .. tostring(box ~= nil))
    else
        Q.check(box == nil and W.hdr > 0, label, "a station in reach " .. tostring(inReach) .. "; the Station box's zone " .. tostring(box ~= nil)
            .. "; the Category box's zone " .. tostring(C.zoneOf("catDropdown") ~= nil))
    end
end)

-- ===================================================================== #17 (Craft): the empty Ready list names the way out
Q.step(2, function()
    local T = S.c
    if not T.go then return end
    local st = C.st()
    local E = { cats = {}, i = 0 }
    T.e17 = E
    local ww = RT.ww()
    E.panel = ww and ww._drawerPanel
    for _, c in ipairs(st.categoryList or {}) do
        if type(c) == "table" and c.id ~= nil and c.id ~= "all" then E.cats[#E.cats + 1] = c.id end
    end
    -- (only the line drawn on the World window's drawer, where the Crafting list draws)
    H.wrap(ZeD.Molecules, "drawEmptyLine", function(orig) return function(panel, x, y, w, text, ...)
        if E.armed and panel ~= nil and panel == E.panel then E.drawn = tostring(text) end
        return orig(panel, x, y, w, text, ...)
    end end, "c17")
    pcall(ZeD.CraftingCore.setShow, st, "ready")
    E.next = true
end)
H.wait(20000, function()
    local T = S.c
    local E = T.e17
    local st = C.st()
    if not (T.go and E and st) then return true end
    if E.next then
        E.i = E.i + 1
        local cat = E.cats[E.i]
        if not cat then E.out = true; return true end
        st.activeCat = cat
        st.filterDirty, st._sectionsStale = true, true
        E.next, E.drawn, E.armed, E.at = false, nil, true, getTimestampMs()
        return false
    end
    if st.filterDirty then return false end
    if #(st.filteredCache or {}) > 0 then E.next = true; return false end
    if E.drawn then E.found = st.activeCat; return true end
    if getTimestampMs() - E.at > 1500 then E.next = true end
    return false
end, function()
    local T = S.c
    local E = T.e17
    if not (T.go and E) then return end
    H.unwrap("c17")
    local CC = ZeD.CraftingCore
    local fresh = nil
    pcall(function() fresh = CC.showMode(CC.createState(), nil) end)
    local text, how = E.found and E.drawn or nil, nil
    if text then
        how = "drawn by the list under Show: Ready on category " .. tostring(E.found)
    else
        pcall(function()
            local s = CC.createState()
            text = CC.emptyListText(s, nil)
        end)
        how = "not drawn: every one of " .. #E.cats .. " categories lists something under Ready here; read from emptyListText on a fresh Craft state"
    end
    local known = ZeD.tr("UI_ZeD_Craft_Known")
    Q.check(fresh == "ready" and H.has(text, known),
        "#17: the Crafting tab still opens on Show: Ready, and its empty list's line names Show: Known (old code: \"Nothing is ready to make with what is in reach.\")",
        "a fresh Craft tab's Show " .. tostring(fresh) .. "; the line \"" .. tostring(text) .. "\" (" .. how .. "); names \"" .. tostring(known) .. "\" " .. tostring(H.has(text, known)))
    local st = C.st()
    if st then
        st.activeCat = "all"
        pcall(CC.setShow, st, "all")
        st.filterDirty, st._sectionsStale = true, true
    end
end)
H.settle(600, 6000, function()
    local st = C.st()
    return not S.c.go or (st ~= nil and st.filterDirty == false and #C.rowsInView() >= 2)
end, function() end)

-- ===================================================================== #47: a second click keeps the card; another row or Escape closes it
Q.step(2, function()
    local T = S.c
    if not T.go then return end
    local R = { label = "#47: a second click on the open recipe row leaves its card open, and a click on another row opens that one (old code: the second click shuts the card)" }
    T.r47 = R
    C.shut()
    local rows = C.rowsInView()
    if #rows < 2 then R.why = "fewer than two recipe rows in the list's view (" .. #rows .. ")"; return end
    R.a, R.b = rows[1].id, rows[2].id
    local ok, how, cov = C.pressRow(R.a)
    if cov then R.skip = how; return end
    if not ok then R.why = "the first click: " .. tostring(how); return end
    R.go = true
end)
H.wait(2000, function()
    local R = S.c.r47
    if not (R and R.go) then return true end
    local st = C.st()
    return st ~= nil and st.selected == R.a and (st.splitFrac or 0) >= 0.99
end, function(ok)
    local R = S.c.r47
    if not (R and R.go) then return end
    local st = C.st()
    R.sel1 = st and st.selected
    if R.sel1 ~= R.a then R.go = false; R.why = "the first click did not open " .. tostring(R.a) .. "'s card (open: " .. tostring(R.sel1) .. ")"; return end
    local okP, how, cov = C.pressRow(R.a)
    if cov then R.go = false; R.skip = how; return end
    if not okP then R.go = false; R.why = "the second click: " .. tostring(how) end
end)
H.pause(400)
Q.step(1, function()
    local R = S.c.r47
    if not (R and R.go) then return end
    local st = C.st()
    R.sel2 = st and st.selected
    local okP, how, cov = C.pressRow(R.b)
    if cov then R.go = false; R.skip = "the other row: " .. tostring(how); return end
    if not okP then R.go = false; R.why = "the click on the other row: " .. tostring(how) end
end)
H.wait(1500, function()
    local R = S.c.r47
    if not (R and R.go) then return true end
    local st = C.st()
    return st ~= nil and st.selected == R.b
end, function()
    local T = S.c
    local R = T.r47
    if not (T.go and R) then return end
    if R.skip then Q.skip(R.label, R.skip); return end
    if not R.go and R.sel2 == nil and R.why then Q.check(false, R.label, "not staged: " .. tostring(R.why)); return end
    local st = C.st()
    R.sel3 = st and st.selected
    Q.check(R.sel1 == R.a and R.sel2 == R.a and R.sel3 == R.b, R.label,
        "rows \"" .. tostring(R.a) .. "\" and \"" .. tostring(R.b) .. "\"; the card after the first click: " .. tostring(R.sel1) .. ", after the second on the same row: "
        .. tostring(R.sel2) .. ", after the click on the other row: " .. tostring(R.sel3) .. (R.why and ("; " .. tostring(R.why)) or ""))
end)
-- Escape with the card open
Q.step(3, function()
    local T = S.c
    local R = T.r47
    if not (T.go and R) then return end
    local st = C.st()
    R.esc = { label = "#47: Escape shuts the open recipe card and the game's pause menu stays shut (old code: the card stays and the pause menu opens)" }
    if st and not st.selected and (R.b or R.a) then
        pcall(ZeD.CraftingCore.openCraft, st, R.b or R.a)
        R.esc.note = "the card was opened from code for Escape"
    end
    R.esc.sel0 = st and st.selected
    R.esc.pause0 = M.pauseUp()
end)
H.pause(300)
Q.step(1, function()
    local R = S.c.r47
    if not (S.c.go and R and R.esc) then return end
    R.esc.ran = M.escape()
end)
H.pause(300)
Q.step(1, function()
    local T = S.c
    local R = T.r47
    if not (T.go and R and R.esc) then return end
    local E = R.esc
    local st = C.st()
    local sel, pause = st and st.selected, M.pauseUp()
    M.unpause()
    Q.check(E.sel0 ~= nil and E.ran == true and sel == nil and not pause and not E.pause0 and H.worldOpen(), E.label,
        "the card before " .. tostring(E.sel0) .. (E.note and (" (" .. E.note .. ")") or "") .. "; Escape handed on " .. tostring(E.ran) .. "; after it the card "
        .. tostring(sel) .. ", the pause menu up " .. tostring(pause) .. " (before " .. tostring(E.pause0) .. "), the World window open " .. tostring(H.worldOpen()))
    C.shut()
end)
H.wait(3000, function() return not M.pauseUp() end, function() end)

-- ===================================================================== #35: no amber Surface badge
Q.step(3, function()
    local T = S.c
    if not T.go then return end
    local st, d = C.st(), C.data()
    local listed = {}
    for _, rd in ipairs((st and st.filteredCache) or {}) do listed[rd] = true end
    local pick, pickAny = nil, nil
    for _, rd in ipairs((d and d.recipes) or {}) do
        if rd.entry and rd.entry.needSurface == true then
            pickAny = pickAny or rd
            if listed[rd] and not pick then pick = rd end
        end
    end
    pick = pick or pickAny
    local W = { cards = 0, badges = {}, seen = {} }
    T.w35 = W
    W.label = "#35: the card of a recipe made on any surface draws no amber Surface badge (old code: a Surface badge on every such card)"
    if not pick then W.skip = "the Crafting tab holds no recipe made on any surface"; return end
    W.name, W.title = pick.entry.name, tostring(pick.entry.displayName)
    -- (the Crafting tab's card only: its config's prefix is "craft")
    H.wrap(ZeD.CraftingCore, "renderCraftCard", function(orig) return function(panel, x, y, w, h, state, config, rd, playerObj, ...)
        local mine = type(config) == "table" and config.prefix == "craft"
        if mine then W.inCard = true; W.cards = W.cards + 1 end
        local r1, r2, r3 = orig(panel, x, y, w, h, state, config, rd, playerObj, ...)
        W.inCard = false
        return r1, r2, r3
    end end, "c35")
    H.wrap(ZeD.Atoms, "drawBadge", function(orig) return function(panel, label, ...)
        if W.inCard then
            local s = tostring(label)
            if not W.seen[s] then W.seen[s] = true; W.badges[#W.badges + 1] = s end
        end
        return orig(panel, label, ...)
    end end, "c35")
    C.shut()
    if not st then W.skip = "the Crafting tab has no state"; return end
    if not pcall(ZeD.CraftingCore.openCraft, st, W.name) then W.skip = "its card could not be opened" end
    st.filterDirty = true
end)
H.wait(4000, function()
    local W = S.c.w35
    if not (W and W.name) or W.skip then return true end
    local st = C.st()
    return W.cards >= 20 and st ~= nil and st.selected == W.name and (st.splitFrac or 0) >= 0.99
end, function()
    local T = S.c
    local W = T.w35
    if not (T.go and W) then return end
    H.unwrap("c35")
    if W.skip then Q.skip(W.label, W.skip); return end
    W.inCard = false
    local CC = ZeD.CraftingCore
    local surf1, surf2 = ZeD.tr("IGUI_CraftingWindow_Surface"), getText("IGUI_CraftingWindow_Surface")
    local hit = W.seen[tostring(surf1)] or W.seen[tostring(surf2)]
    local st = C.st()
    Q.check(W.cards > 0 and not hit, W.label,
        tostring(W.title) .. " (" .. tostring(W.name) .. "), its card open " .. tostring(st and st.selected == W.name) .. ", drawn " .. W.cards
        .. " times; the badges it drew [" .. H.list(W.badges) .. "]; \"" .. tostring(surf1) .. "\" among them " .. tostring(hit and true or false))
    C.shut()
end)

-- ===================================================================== #32: a Max key after +
Q.step(3, function()
    local T = S.c
    if not T.go then return end
    local R = { name = "OpenBox100", boxes = {} }
    T.r32 = R
    R.label = "#32: a recipe he can make three times: the band has a Max key, and its press sets the amount to the most (old code: no Max key)"
    for i = 1, 3 do R.boxes[i] = H.give("Base.NailsBox") end
    if not (R.boxes[1] and R.boxes[2] and R.boxes[3]) then R.why = "three boxes of nails could not be given"; return end
    if not C.row(R.name) then R.skip = "the Crafting tab holds no Open Box (OpenBox100)"; return end
    R.go = true
end)
H.wait(12000, function()
    local R = S.c.r32
    if not (R and R.go) then return true end
    local rd = C.row(R.name)
    return rd ~= nil and rd.status == "craftable"
end, function(ok)
    local R = S.c.r32
    if not (R and R.go) then return end
    local rd = C.row(R.name)
    R.title = rd and tostring(rd.entry.displayName)
    if not ok then R.go = false; R.why = "Open Box does not read craftable with three boxes of nails on him (status " .. tostring(rd and rd.status) .. ")"; return end
    C.place(R.name, C.mid())
end)
H.wait(3000, function()
    local R = S.c.r32
    if not (R and R.go) then return true end
    local z = C.zone(R.name)
    if z and not C.inView(z) then C.place(R.name, C.mid()) end
    return z ~= nil and C.inView(z)
end, function(ok)
    local R = S.c.r32
    if not (R and R.go) then return end
    local okP, how, cov = false, "its row is not in the list's view", false
    if ok then okP, how, cov = C.pressRow(R.name) end
    if cov then R.go = false; R.skip = how; return end
    if not okP then
        -- (the row out of reach: the card opened as its click opens it, said; the band is what is under test)
        local st = C.st()
        if st then pcall(ZeD.CraftingCore.openCraft, st, R.name) end
        R.note = "the card opened from code (" .. tostring(how) .. ")"
    end
end)
H.wait(8000, function()
    local R = S.c.r32
    if not (R and R.go) then return true end
    local st = C.st()
    return st ~= nil and st.selected == R.name and C.zoneOf("action_build") ~= nil and (st._maxQty or 0) > 1 and (st.splitFrac or 0) >= 0.99
end, function()
    local R = S.c.r32
    if not (R and R.go) then return end
    local st = C.st()
    R.max, R.qty0 = st and st._maxQty, st and st.qty
    if not (st and st.selected == R.name) then R.go = false; R.why = "its card did not open (open: " .. tostring(st and st.selected) .. ")"; return end
    if (R.max or 0) <= 1 then R.go = false; R.skip = "the band's most is " .. tostring(R.max) .. " here: nothing for Max to set"; return end
    local z = C.zoneOf("action_max")
    R.zones = C.amountZones()
    if not z then R.go = false; R.noMax = true; return end
    local okP, how, cov = H.pressZone("w", z, false)
    if cov then R.go = false; R.skip = "the Max key: " .. tostring(how); return end
    if not okP then R.go = false; R.why = "the press on Max: " .. tostring(how); return end
    R.pressed = true
end)
H.wait(1500, function()
    local R = S.c.r32
    if not (R and R.pressed) then return true end
    local st = C.st()
    return st ~= nil and st.qty == st._maxQty
end, function()
    local T = S.c
    local R = T.r32
    if not (T.go and R) then return end
    if R.skip then Q.skip(R.label, R.skip)
    else
        local st = C.st()
        local qty = st and st.qty
        Q.check(R.pressed == true and R.qty0 == 1 and qty == R.max and (R.max or 0) > 1, R.label,
            tostring(R.title) .. (R.note and (" (" .. R.note .. ")") or "") .. "; the band's most " .. tostring(R.max) .. ", the amount before " .. tostring(R.qty0)
            .. "; the amount keys [" .. H.list(R.zones) .. "]" .. (R.noMax and "; no Max key on the band" or "")
            .. (R.pressed and ("; after the press on Max the amount " .. tostring(qty)) or "") .. (R.why and ("; " .. tostring(R.why)) or ""))
    end
    C.shut()
    for _, it in ipairs(R.boxes or {}) do H.removeItem(it) end
end)

-- ===================================================================== #17 and #32 on the Building tab
Q.step(3, function()
    local T = S.b
    if not S.ready then return end
    local w = RT.ww()
    if not w then return end
    -- the tab's state set aside: the tab makes a fresh one on its first frame, as a new window does
    T.was, T.taken = w._buildState, true
    w._buildState = nil
    H.tab("w", "build")
    T.go = true
end)
H.wait(8000, function()
    local T = S.b
    if not T.go then return true end
    local st = C.st("b")
    return C.showing("build") and st ~= nil and C.geo("b") ~= nil and st.filteredCache ~= nil
end, function(ok)
    local T = S.b
    if not T.go then return end
    local st = C.st("b")
    if not (ok and st) then
        T.go = false
        local w = RT.ww()
        Q.check(false, "the World window shows its Building tab with its list (staging)", "on " .. tostring(w and w._activeTab))
        return
    end
    local mode = nil
    pcall(function() mode = ZeD.CraftingCore.showMode(st, nil) end)
    -- (the director's call 6, Nov 25 2026, replaces #17's Known for Build: the Building tab opens on Show: All, every
    -- recipe listed and a skill-short row tagged with its skill in red, as the game's build list shows them; the Craft
    -- tab's own default is untouched. BuildingTab.getState sets show = "all")
    Q.check(mode == "all", "#17 / call 6: the Building tab opens on Show: All (the director's call 6, Nov 25 2026; before it: Known, and Ready before that)",
        "a fresh Building tab's Show " .. tostring(mode) .. " (its state's own: " .. tostring(st.show) .. ")")
    -- (Show: All for the card below on either code, so the list has rows: the card's band is what is under test; the
    -- state is a fresh one, set aside at the end for the one found)
    pcall(ZeD.CraftingCore.setShow, st, "all")
    st.activeCat = "all"
    st.filterDirty, st._sectionsStale = true, true
end)
H.settle(1500, 8000, function()
    local st = C.st("b")
    return not S.b.go or (st ~= nil and st.filterDirty == false and #C.rowsInView("b") >= 1)
end, function()
    local T = S.b
    if not T.go then return end
    local R = { label = "#32: a build recipe's card has Build and no amount on its band (old code: a grayed - 1 + beside Build)" }
    T.r32 = R
    local rows = C.rowsInView("b")
    if #rows == 0 then R.why = "no build recipe row in the list's view"; return end
    R.name = rows[1].id
    local okP, how, cov = H.pressZone("w", rows[1], false)
    if cov then R.skip = how; return end
    if not okP then R.why = "the click on its row: " .. tostring(how); return end
    R.go = true
end)
H.wait(5000, function()
    local R = S.b.r32
    if not (R and R.go) then return true end
    local st = C.st("b")
    return st ~= nil and st.selected == R.name and C.zoneOf("action_build", "b") ~= nil and (st.splitFrac or 0) >= 0.99
end, function(ok)
    local T = S.b
    local R = T.r32
    if not (T.go and R) then return end
    if R.skip then Q.skip(R.label, R.skip)
    else
        local st = C.st("b")
        local amt = C.amountZones("b")
        Q.check(R.go == true and ok and #amt == 0, R.label,
            "the recipe " .. tostring(R.name) .. ", its card open " .. tostring(st and st.selected == R.name) .. ", Build's zone " .. tostring(C.zoneOf("action_build", "b") ~= nil)
            .. ", the band's most " .. tostring(st and st._maxQty) .. "; the amount's zones [" .. H.list(amt) .. "]" .. (R.why and ("; " .. tostring(R.why)) or ""))
    end
    C.shut("b")
end)

-- ===================================================================== #55: the Journal's Open in Craft
Q.step(3, function()
    local T = S.j
    if not S.ready then return end
    local cw = RT.cw()
    if not cw then return end
    T.subWas = cw._journalSubTab
    T.selWas = cw._jrecipeState and cw._jrecipeState.selected or nil
    -- (a page change clears the Journal's search fields, the game's way; said when one held words)
    local typed = tostring(cw._journalSearchText or "") .. tostring(cw._flyerSearchText or "") .. tostring((cw._jrecipeState and cw._jrecipeState.search) or "")
    if typed ~= "" and T.subWas ~= 4 then Q.say("NOTE #55: a Journal search held words (\"" .. typed .. "\"): the page change clears them, and they are not typed again") end
    T.taken = true
    H.tab("c", "journal")
    T.go = true
end)
H.wait(5000, function()
    local cw = RT.cw()
    return not S.j.go or (cw ~= nil and cw._activeTab == "journal" and cw._drawerMode == "tab")
end, function(ok)
    local T = S.j
    if not T.go then return end
    local cw = RT.cw()
    if not ok then T.go = false; Q.check(false, "the Character window shows its Journal tab (staging)", "on " .. tostring(cw and cw._activeTab)); return end
    pcall(ZeD.JournalTab.setPage, cw, 4)
end)
H.wait(8000, function()
    local cw = RT.cw()
    if not S.j.go then return true end
    return cw ~= nil and cw._journalSubTab == 4 and cw._jrecipeState ~= nil and cw._jrecipeCache ~= nil and cw._jrecipeCache.recipes ~= nil
end, function(ok)
    local T = S.j
    if not T.go then return end
    T.label = "#55: the Journal's recipe card has Open in Craft on its band, and its press opens that recipe on the World window's Crafting tab (old code: no key)"
    if not ok then T.go = false; Q.check(false, "the Journal's Recipes page lists its recipes (staging)"); return end
    T.name = J.pick()
    if not T.name then T.go = false; Q.skip(T.label, "the Journal lists no craft recipe"); return end
    local st = J.st()
    pcall(ZeD.CraftingCore.openCraft, st, T.name)
    st.filterDirty = true
end)
H.wait(5000, function()
    local T = S.j
    if not T.go then return true end
    local st = J.st()
    return st ~= nil and st.selected == T.name and J.zoneOf("action_open") ~= nil and (st.splitFrac or 0) >= 0.99
end, function()
    local T = S.j
    if not T.go then return end
    local z = J.zoneOf("action_open")
    local st = J.st()
    T.sel = st and st.selected
    if not z then T.go = false; T.noKey = true; return end
    local okP, how, cov = H.pressZone("c", z, true)
    if cov then T.go = false; T.skip = how; return end
    if not okP then T.go = false; T.why = how; return end
    T.pressed = true
end)
H.wait(4000, function()
    local T = S.j
    if not T.pressed then return true end
    local ww = RT.ww()
    local st = ww and ww._craftState
    return ww ~= nil and ww._activeTab == "craft" and st ~= nil and st.selected == T.name
end, function(ok)
    local T = S.j
    if not T.label then return end
    if T.skip then Q.skip(T.label, T.skip)
    elseif T.name then
        local ww = RT.ww()
        local st = ww and ww._craftState
        Q.check(T.pressed == true and ok, T.label,
            "the recipe " .. tostring(T.name) .. ", the Journal's card on " .. tostring(T.sel) .. (T.noKey and "; no Open in Craft zone on its band" or "")
            .. (T.pressed and ("; after the press the World window on " .. tostring(ww and ww._activeTab) .. ", its Crafting card on " .. tostring(st and st.selected)) or "")
            .. (T.why and ("; " .. tostring(T.why)) or ""))
    end
    J.putBack()
end)

-- ===================================================================== #29 (cards) and #57 (Repair names the fixer)
Q.step(5, function()
    local T = S.u
    if not S.ready then return end
    H.tab("c", "loot")
    H.clearQueue()
    T.band, T.pills = H.give("Base.Bandage"), H.give("Base.Pills")
    T.pa, T.pb = H.give("Base.Pistol"), H.give("Base.Pistol")
    if T.pa then pcall(function() T.pa:setCondition(math.max(1, T.pa:getConditionMax() - 3)) end) end
    for _, ft in ipairs({ "Base.Bandage", "Base.Pills", "Base.Pistol" }) do H.setStack("c", ft, true) end
    -- the care band's Repair button as the card hands it to the band (its help line is the balloon's words)
    H.wrap(ZeD.Molecules, "drawBand", function(orig) return function(panel, x, y, w, spec, ...)
        if type(spec) == "table" and type(spec.buttons) == "table" and type(panel) == "table" then
            for _, b in ipairs(spec.buttons) do
                if type(b) == "table" and b.id == "repair" then
                    T.rep = { help = b.help, label = b.label, item = panel.item, t = getTimestampMs() }
                end
            end
        end
        return orig(panel, x, y, w, spec, ...)
    end end, "u57")
    T.go = true
end)
for _, k in ipairs(U.KINDS) do U.queueRead(k) end
Q.step(2, function()
    local T = S.u
    if not T.go then return end
    H.unwrap("u57")
    local kb, kp, kr = U.KINDS[1], U.KINDS[2], U.KINDS[3]
    local bl, pl = U.label(kb, "BANDAGE"), U.label(kp, "USE")
    local wantB, wantP = getText("ContextMenu_Bandage"), getText("ContextMenu_Take_pills")
    Q.check(kb.read == true and kp.read == true and H.low(bl) == H.low(wantB) and H.low(pl) == H.low(wantP),
        "#29: the bandage's card has the game's Bandage, and the painkillers' card reads Take Pills (old code: no Bandage; Use)",
        U.verbsText(kb) .. "; " .. U.verbsText(kp) .. "; want \"" .. tostring(wantB) .. "\" and \"" .. tostring(wantP) .. "\"")
    local fixer = T.pa and U.fixerName(T.pa) or nil
    local rep = kr.rep
    local label = "#57: the worn pistol's Repair balloon names the fixer one click spends (old code: \"repair it with what you carry\")"
    if not fixer then
        Q.skip(label, "the game names no fixer he has for the pistol (FixingManager), so Repair names none on either code")
    else
        Q.check(kr.read == true and rep ~= nil and H.has(rep.help, fixer), label,
            U.verbsText(kr) .. "; its Repair button " .. tostring(rep and rep.label) .. " with the help \"" .. tostring(rep and rep.help) .. "\"; the fixer the game spends first: "
            .. tostring(fixer) .. "; the pistol's condition " .. H.num(T.pa and T.pa:getCondition()) .. " of " .. H.num(T.pa and T.pa:getConditionMax()))
    end
    H.shutCard("c")
    local c = H.content("c")
    if c then c._selectedItems = {}; c._lastClickedItem = nil; c._zedLastClick = nil end
    for _, it in ipairs({ T.band, T.pills, T.pa, T.pb }) do H.removeItem(it) end
end)

-- ===================================================================== #29 (Health tab): a click on a wound opens its treatments
Q.step(5, function()
    local T = S.d
    if not S.ready then return end
    H.clearQueue()
    T.part = D.pick(nil)
    if not T.part then Q.skip("#29: a click on a wound on the Health tab", "every arm part has a wound, a bandage or stitches already"); return end
    T.clean = D.pick(T.part)
    H.tab("c", "health")
    local cw = RT.cw()
    if cw then
        T.foldWas = cw._healthFigureExpanded
        cw._healthFigureExpanded = true
    end
    T.staged = true
    -- (the game's debug entries off for the clicks: with them the menu is never empty)
    ISHealthPanel.cheat = false
    T.cheatSet = true
    T.wounded = D.wound(D.woundBp())
    if not T.wounded then Q.check(false, "#29: a scratch is made on the " .. T.part.name .. " (staging)"); return end
    T.band = H.give("Base.Bandage")
    T.go = true
end)
H.wait(8000, function()
    local T = S.d
    if not T.go then return true end
    local fig = D.fig()
    return D.tabUp() and D.still() and D.rowZone(T.part.name) ~= nil and fig ~= nil
end, function(ok)
    local T = S.d
    if not T.go then return end
    local w = RT.cw()
    if not ok then
        T.go = false
        Q.check(false, "#29: the Health tab shows the scratch on the " .. T.part.name .. " (staging)", "the tab up " .. tostring(D.tabUp())
            .. ", its wound row " .. tostring(D.rowZone(T.part.name) ~= nil) .. "; the Character window on " .. tostring(w and w._activeTab))
        return
    end
    local sc = w._healthScroll
    if sc then pcall(function() T.scrollWas = sc.scrollPos; sc:setScrollPos(0) end) end
    T.seek = nil
    Q.say("#29: a scratch on the " .. T.part.name .. ", infection off; a bandage in his inventory; the clean part " .. tostring(T.clean and T.clean.name))
end)
H.wait(6000, function()
    local T = S.d
    if not T.go then return true end
    return D.seekRowView(T.part.name)
end, function()
    local T = S.d
    if not T.go then return end
    T.label1 = "#29: a left click on the wound's row on the Health tab opens the part's treatments, Bandage among them (old code: nothing opens)"
    local pt, why = D.rowPoint(T.part.name)
    if not pt then T.skip1 = why; return end
    local ok, how = D.press(pt)
    T.how1 = how
    if not ok then T.why1 = how; return end
    T.go1 = true
end)
H.wait(1500, function() local T = S.d; return not T.go1 or M.up() end, function(up)
    local T = S.d
    if not T.go then return end
    if T.skip1 then Q.skip(T.label1, T.skip1)
    else
        local names = M.names()
        local want = getText("ContextMenu_Bandage")
        local hasB = false
        for _, n in ipairs(names) do if n == want then hasB = true end end
        Q.check(T.go1 == true and up and hasB, T.label1,
            tostring(T.how1) .. "; a menu up " .. tostring(up) .. " with [" .. H.list(names) .. "]; \"" .. tostring(want) .. "\" in it " .. tostring(hasB)
            .. (T.why1 and ("; " .. tostring(T.why1)) or ""))
    end
    M.close()
    -- (the tab back at its top for the figure: the wound row's seek may have scrolled it away)
    local w = RT.cw()
    local sc = w and w._healthScroll
    if T.go and sc then pcall(function() sc:setScrollPos(0) end) end
end)
H.pause(400)
-- an empty menu names what is missing: a clean part pressed on the figure
Q.step(1, function()
    local T = S.d
    if not T.go then return end
    T.label2 = "#29: a left click on a part with nothing to treat opens no menu, and the character says \"<part>: nothing to treat.\" (old code: nothing)"
    if not T.clean then T.skip2 = "no clean arm part is left"; return end
    local pt, why = D.figurePoint(T.clean.name)
    if not pt then T.skip2 = why; return end
    local bp = D.bpOf(T.clean.t)
    pcall(function() T.want2 = ZeD.tr("UI_ZeD_Health_NothingToTreat", BodyPartType.getDisplayName(bp:getType())) end)
    T.note2 = nil
    H.wrap(ZeD.HealthTab, "sayNothingFits", function(orig) return function(patient, part, pn)
        -- the character handed on as a stand-in that keeps the words it is told to say (and says them)
        local stand = { setHaloNote = function(_, t) T.note2 = tostring(t); pcall(function() patient:setHaloNote(t) end) end }
        return orig(stand, part, pn)
    end end, "d29")
    local ok, how = D.press(pt)
    T.how2 = how
    if not ok then T.why2 = how; return end
    T.go2 = true
end)
H.wait(1500, function() local T = S.d; return not T.go2 or T.note2 ~= nil end, function()
    local T = S.d
    if not T.go then return end
    H.unwrap("d29")
    if T.skip2 then Q.skip(T.label2, T.skip2)
    else
        local up = M.up()
        Q.check(T.go2 == true and not up and T.note2 ~= nil and T.note2 == T.want2, T.label2,
            "the " .. tostring(T.clean and T.clean.name) .. " on the figure, " .. tostring(T.how2) .. "; a menu up " .. tostring(up) .. "; the character said \""
            .. tostring(T.note2) .. "\" (want \"" .. tostring(T.want2) .. "\")" .. (T.why2 and ("; " .. tostring(T.why2)) or ""))
    end
    M.close()
    D.putBack()
    H.removeItem(T.band)
    if T.tripped then Q.say("NOTE #29: the guard stopped the wound early (" .. tostring(T.tripped) .. ")") end
end)

-- ===================================================================== #58: Turn on only turns the stove on
Q.step(5, function()
    local T = S.v
    if not S.ready then return end
    T.label = "#58: Turn on from the stove's menu (the game's onToggleStove) turns it on and opens no panel: no face pop-out, no Craft tab on it"
        .. " (old code: the stove's face or the Crafting tab opened on it)"
    H.clearQueue()
    local sq = V.freeSq()
    if not sq then T.skip = "no free square beside him for a stove"; return end
    local o, spr = V.place(sq)
    if not o then T.skip = "no stove could be placed beside him"; return end
    T.obj, T.spr = o, spr
    T.on0 = V.on(o)
    if T.on0 then pcall(function() o:Toggle() end) end
    T.calls = {}
    H.wrap(ZeD.FacePop, "open", function(orig) return function(player, obj, ...)
        if obj ~= nil and obj == T.obj then T.calls[#T.calls + 1] = "FacePop.open" end
        return orig(player, obj, ...)
    end end, "v58")
    H.wrap(ZeD.Stations, "open", function(orig) return function(player, obj, ...)
        if obj ~= nil and obj == T.obj then T.calls[#T.calls + 1] = "Stations.open" end
        return orig(player, obj, ...)
    end end, "v58")
    H.wrap(ISToggleStoveAction, "perform", function(orig) return function(self, ...)
        if type(self) == "table" and self.object == T.obj then T.performed = getTimestampMs() end
        return orig(self, ...)
    end end, "v58")
    T.tab0 = H.tabOf("w")
    local ok, err = pcall(ISWorldObjectContextMenu.onToggleStove, nil, o, S.pn)
    if not ok then T.why = "onToggleStove threw: " .. tostring(err); return end
    T.q0 = H.queueText()
    T.go = true
end)
H.wait(8000, function() local T = S.v; return not T.go or T.performed ~= nil end, function(ok)
    local T = S.v
    if T.go and not ok then T.why = "the toggle never ran (the queue: " .. tostring(T.q0) .. " then " .. H.queueText() .. ")" end
end)
H.pause(1200)
Q.step(1, function()
    local T = S.v
    if not T.label then return end
    if T.skip then Q.skip(T.label, T.skip); V.putBack(); return end
    local o = T.obj
    local on, bound, face = V.on(o), V.bound(o), V.face(o)
    -- (the panels are the calls and the face; the Craft tab bound is said, not judged: a bind can come another way)
    Q.check(T.go == true and T.performed ~= nil and #T.calls == 0 and not face, T.label,
        "a stove (" .. tostring(T.spr) .. ") beside him, on before " .. tostring(T.on0) .. "; queued [" .. tostring(T.q0) .. "]; the toggle ran " .. tostring(T.performed ~= nil)
        .. "; on now " .. tostring(on) .. " (it needs power); panels asked for it [" .. H.list(T.calls) .. "]; the Craft tab bound to it " .. tostring(bound)
        .. ", its face showing " .. tostring(face) .. "; the World window on " .. tostring(H.tabOf("w")) .. " (was " .. tostring(T.tab0) .. ")"
        .. (T.why and ("; " .. tostring(T.why)) or ""))
    H.clearQueue()
    V.putBack()
end)

-- ===================================================================== #49: a click on Hungry or Thirsty opens the quick list
Q.step(3, function()
    local T = S.m
    if not S.ready then return end
    -- (both windows shut for the clicks: a real click on a moodle under a window lands on the window; opened after)
    T.shut = true
    if H.charOpen() and H.worldOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn)
    elseif H.charOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif H.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
    H.setStat("HUNGER", math.max(S.was.hunger or 0, 0.3))
    H.setStat("THIRST", math.max(S.was.thirst or 0, 0.3))
    T.statSet = true
    T.food, T.water = H.give("Base.Apple"), H.give("Base.WaterBottle")
    T.go = true
end)
H.wait(6000, function()
    local T = S.m
    if not T.go then return true end
    return not H.charOpen() and not H.worldOpen() and MO.idx("HUNGRY") ~= nil and MO.idx("THIRST") ~= nil
end, function(ok)
    local T = S.m
    if not T.go then return end
    local paused = getGameSpeed() <= 0
    Q.say("#49: the moodles shown [" .. MO.keys() .. "], all found " .. tostring(ok) .. "; game speed " .. H.num(getGameSpeed()) .. "; the windows shut "
        .. tostring(not H.charOpen() and not H.worldOpen()))
    if paused then T.go = false; Q.skip("#49: a click on a moodle opens the quick list", "the game is paused (the list does nothing while paused)") end
end)
MO.queueCheck("HUNGRY", "eat", "Hungry")
MO.queueCheck("THIRST", "drink", "Thirsty")
Q.step(2, function()
    local T = S.m
    if not T.statSet then return end
    M.close()
    H.setStat("HUNGER", S.was.hunger)
    H.setStat("THIRST", S.was.thirst)
    T.statSet = false
    H.removeItem(T.food)
    H.removeItem(T.water)
    H.openBoth()
end)
H.wait(6000, function() return not S.m.shut or H.both() end, function()
    if S.m.shut then H.hold() end
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.clearQueue()
    M.close()
    M.unpause()
    pcall(V.putBack)
    pcall(D.putBack)
    if S.m.statSet then H.setStat("HUNGER", S.was.hunger); H.setStat("THIRST", S.was.thirst); S.m.statSet = false end
    if S.bodySet then
        S.d.guardOn = false
        pcall(function() Events.OnTick.Remove(D.guard) end)
        D.heal(D.woundBp())
        pcall(function() S.p:setInvincible(S.was.inv and true or false) end)
        pcall(function() S.p:setGodMod(S.was.god and true or false) end)
        S.bodySet = false
    end
    if S.d.cheatSet then ISHealthPanel.cheat = S.was.cheat; S.d.cheatSet = false end
    H.unwrap(nil)
    pcall(RT.takeBack)
    for _, it in ipairs(S.made) do pcall(H.removeItem, it) end
    pcall(H.handsBack)
    pcall(H.stacksBack)
    pcall(H.foldsBack)
    pcall(H.gridBack)
    pcall(J.putBack)
    pcall(C.stateBack)
    if not H.both() then H.openBoth() end
end)
H.wait(5000, function() return not S.ready or H.both() end, function() end)
Q.step(3, function()
    if not S.ready then return end
    for _, k in ipairs({ "c", "w" }) do
        if S.card0 and S.card0[k] == nil then H.shutCard(k) end
        local c = H.content(k)
        if c then c._selectedItems = {}; c._lastClickedItem = nil; c._zedLastClick = nil; c._padMarks = nil end
    end
    H.tab("c", S.was.tab.c or "loot")
    H.tab("w", S.was.tab.w or "loot")
end)
H.wait(3000, function()
    if not S.ready then return true end
    return H.tabOf("c") == (S.was.tab.c or "loot") and H.tabOf("w") == (S.was.tab.w or "loot") and H.settled()
end, function()
    if not S.ready then return end
    pcall(C.buildBack)
    pcall(C.cardBack)
    pcall(C.stationBack)
    pcall(H.viewTo, RT.cw(), S.view0.c)
    local ww = RT.ww()
    local wv = S.view0.w
    if ww and wv and wv.aInv and not H.sameView(ww, wv) and H.idxOf(ww, wv.aInv) then pcall(ZeD_WorldWindow.selectContainer, wv.aInv, 60, S.pn) end
    H.scrollTo("c", S.scroll0.c)
    H.scrollTo("w", S.scroll0.w)
    for _, inv in ipairs(S.cols.c or {}) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
    for _, inv in ipairs(S.cols.w or {}) do pcall(ZeD_WorldWindow.toggleColumn, inv, S.pn) end
    H.modeBack()
end)
Q.waitMs(400)
Q.step(1, function()
    H.modeFree()
    if not S.ready then return end
    S.holdOff = true
    local cw, ww = RT.cw(), RT.ww()
    local CU = ZeD.Curtain
    if cw and S.was.rolled.c and not cw._rolled and CU and CU.roll then pcall(CU.roll, cw) end
    if ww and S.was.rolled.w and not ww._rolled and CU and CU.roll then pcall(CU.roll, ww) end
    if cw then cw._outSince = S.outWas.c end
    if ww then ww._outSince = S.outWas.w end
    if cw and S.was.shaded.c and not cw.windowShaded then pcall(function() cw:setWindowShaded(true) end) end
    if ww and S.was.shaded.w and not ww.windowShaded then pcall(function() ww:setWindowShaded(true) end) end
    if S.was.char == false and S.was.world == false then
        if H.charOpen() and H.worldOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
    end
    if S.was.char == false and H.charOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
    if S.was.world == false and H.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
end)
H.wait(4000, function()
    if not S.ready then return true end
    return H.charOpen() == S.was.char and H.worldOpen() == S.was.world and H.settled()
end, function()
    if not S.ready then return end
    if not (S.was.char and S.was.world) then
        pcall(function()
            local md = S.p:getModData()
            if S.was.ws.had then md.ZeD_WinState = H.copy(S.was.ws.v) else md.ZeD_WinState = nil end
        end)
    end
    local moved = {}
    if S.was.char and H.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and H.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
end)
Q.step(10, function()
    if not S.ready then return end
    -- the things, the stove, the hands, the queue, the menus
    local left, said, total = {}, {}, 0
    for _, it in ipairs(S.made) do
        total = total + 1
        if H.where(it) ~= nil or H.onFloor(it) then
            left[#left + 1] = it
            if #said < 4 then said[#said + 1] = H.nm(it) end
        end
    end
    local stove = V.stands(S.v.obj)
    local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    local hw = S.was.hand or {}
    local grid = H.gridSame()
    Q.check(#left == 0 and not stove and hp == hw.p and hs == hw.s and grid and #H.queue() == 0 and not M.up(),
        "put back: nothing the script gave is left, the stove is gone, his hands hold what they held, the grid choices as found, no action queued, no menu up",
        #left .. " of " .. total .. " things left" .. ((#said > 0) and (": " .. table.concat(said, "; ")) or "") .. "; the stove standing " .. tostring(stove)
        .. "; hands " .. H.nm(hp) .. " / " .. H.nm(hs) .. " (found " .. H.nm(hw.p) .. " / " .. H.nm(hw.s) .. "); the grid choices as found " .. tostring(grid)
        .. "; the queue [" .. H.queueText() .. "]; a menu up " .. tostring(M.up()))
    -- the body
    local dead, health = true, -1
    pcall(function() dead = S.p:isDead() end)
    pcall(function() health = S.p:getBodyDamage():getOverallBodyHealth() end)
    local bp = D.woundBp()
    local hurt = false
    if bp then pcall(function() hurt = bp:HasInjury() or bp:bandaged() or bp:scratched() end) end
    local god, inv = nil, nil
    pcall(function() god = S.p:isGodMod() and true or false end)
    pcall(function() inv = S.p:isInvincible() and true or false end)
    local hu, th = H.stat("HUNGER"), H.stat("THIRST")
    local statsOk = (S.was.hunger == nil or (hu ~= nil and math.abs(hu - S.was.hunger) < 0.05)) and (S.was.thirst == nil or (th ~= nil and math.abs(th - S.was.thirst) < 0.05))
    Q.check(not dead and not hurt and health >= math.min(99, (S.was.health or 100) - 1) and god == S.was.god and inv == S.was.inv and statsOk
        and not S.d.guardOn and ISHealthPanel.cheat == S.was.cheat,
        "put back: the character is alive and unhurt, god mode, invincible, hunger, thirst and the Health tab's cheat entries as found, the guard off",
        "dead " .. tostring(dead) .. ", health " .. H.num(health) .. " (found " .. H.num(S.was.health) .. "); the run's part (" .. tostring(S.d.part and S.d.part.name)
        .. ") hurt or bandaged " .. tostring(hurt) .. "; god mode " .. tostring(god) .. " (found " .. tostring(S.was.god) .. "), invincible " .. tostring(inv)
        .. " (found " .. tostring(S.was.inv) .. "); hunger " .. H.num(hu) .. " (found " .. H.num(S.was.hunger) .. "), thirst " .. H.num(th) .. " (found " .. H.num(S.was.thirst)
        .. "); the cheat entries " .. tostring(ISHealthPanel.cheat) .. " (found " .. tostring(S.was.cheat) .. ")" .. (S.d.tripped and ("; the guard tripped: " .. S.d.tripped) or ""))
    -- the wrappers, the pause menu, the speed
    local wOk, bad = H.wrapsBack()
    Q.check(wOk and M.pauseUp() == (S.was.pause and true or false) and getGameSpeed() == S.was.speed,
        "put back: every function the script watched is ZeD's own again, the pause menu as found, the game at the speed found",
        "left wrapped [" .. H.list(bad) .. "]; the pause menu up " .. tostring(M.pauseUp()) .. "; game speed " .. H.num(getGameSpeed()) .. " (found " .. H.num(S.was.speed) .. ")")
    -- the Crafting and Building tabs, the Journal
    local T = S.c
    if T.seen then
        local st, k = C.st(), T.keep
        local same = true
        if st and k then
            same = st.show == k.show and st.showAll == k.showAll and st.sort == k.sort and st.activeCat == k.cat and (st.search or "") == (k.search or "")
                and st.selected == k.sel
        end
        local station = T.stWas == nil or T.stBack == true
        local w = RT.ww()
        -- (a state found nil: the tab makes its own again whenever it draws, so any is as found)
        local build = not S.b.taken or S.b.was == nil or (w ~= nil and w._buildState == S.b.was)
        local cw = RT.cw()
        local journal = not S.j.taken or (cw ~= nil and (S.j.subWas == nil or cw._journalSubTab == S.j.subWas))
        Q.check(same and station and build and journal,
            "put back: the Crafting tab's Show, Sort, category, search and open card, a bound station, the Building tab's state and the Journal's page as found",
            "Show " .. tostring(st and st.show) .. "/" .. tostring(k and k.show) .. ", Sort " .. tostring(st and st.sort) .. "/" .. tostring(k and k.sort) .. ", category "
            .. tostring(st and st.activeCat) .. "/" .. tostring(k and k.cat) .. ", search \"" .. tostring(st and st.search) .. "\"/\"" .. tostring(k and k.search) .. "\", card "
            .. tostring(st and st.selected) .. "/" .. tostring(k and k.sel) .. " (now / found); a station bound again " .. tostring(station) .. "; the Building tab's state as found "
            .. tostring(build) .. "; the Journal's page " .. tostring(cw and cw._journalSubTab) .. " (found " .. tostring(S.j.subWas) .. ")")
    end
    -- the input lock
    if S.lockWas ~= nil and S.was.mode ~= nil then
        local now, mode = H.lockFound(), H.mode()
        local unknown = S.was.mode == "unknown" and mode == "kbm"
        Q.check(now == S.lockWas and (mode == S.was.mode or unknown) and S.modeHeld == nil and not S.locked,
            "put back: the input lock as found, and the mode ZeD reads",
            "ZeD setup's Input lock " .. tostring(now) .. " (found " .. tostring(S.lockWas) .. "); ZeD reads " .. tostring(mode) .. " (found " .. tostring(S.was.mode) .. ")"
            .. (unknown and "; found unknown, no input since the game started, which ZeD reads as the mouse" or ""))
    end
    -- the windows
    if S.was.char ~= nil then
        local cw, ww2 = RT.cw(), RT.ww()
        local c, w = H.charOpen(), H.worldOpen()
        local gc = c and H.geo(cw) or nil
        local gw = w and H.geo(ww2) or nil
        local tc = c and H.tabOf("c") or nil
        local tw = w and H.tabOf("w") or nil
        Q.check(c == S.was.char and w == S.was.world and H.sameGeo(gc, S.was.geo.c) and H.sameGeo(gw, S.was.geo.w)
            and tc == S.was.tab.c and tw == S.was.tab.w,
            "put back: the Character and World windows open or shut as found, where and as big as they were, on their tabs",
            "Character open " .. tostring(c) .. " " .. H.gs(gc) .. " on " .. tostring(tc) .. " (found " .. tostring(S.was.char) .. " " .. H.gs(S.was.geo.c)
            .. " on " .. tostring(S.was.tab.c) .. "); World open " .. tostring(w) .. " " .. H.gs(gw) .. " on " .. tostring(tw) .. " (found "
            .. tostring(S.was.world) .. " " .. H.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w) .. ")"
            .. (S.moved and ("; the tab presses left the " .. S.moved .. " elsewhere: set back by its own setters") or ""))
    end
end)
Q.start()
